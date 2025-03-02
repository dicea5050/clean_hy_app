class OrdersController < ApplicationController
  before_action :set_order, only: [:show, :edit, :update, :destroy]
  before_action :set_payment_methods, only: [:new, :edit, :create, :update]

  def index
    @orders = Order.includes(:customer, :order_items, :payment_method)
                   .order(order_date: :desc)
                   .search(search_params)
    # 検索条件をビューで再表示するために保持
    @search_params = search_params
    @payment_methods = PaymentMethod.all
  end

  def show
  end

  def new
    @order = Order.new
    @order.order_items.build
    @customers = Customer.all.order(:company_name)
  end

  def edit
    @order.order_items.build if @order.order_items.empty?
    @customers = Customer.all.order(:company_name)
  end

  def create
    @order = Order.new(order_params)
    
    # 単価と税率を商品から設定
    set_price_and_tax_rate(@order.order_items)
    
    if @order.save
      redirect_to @order, notice: '受注情報が正常に作成されました。'
    else
      @customers = Customer.all.order(:company_name)
      render :new
    end
  end

  def update
    if @order.update(order_params)
      # 単価と税率を商品から設定
      set_price_and_tax_rate(@order.order_items)
      @order.save
      
      redirect_to @order, notice: '受注情報が正常に更新されました。'
    else
      @customers = Customer.all.order(:company_name)
      render :edit
    end
  end

  def destroy
    @order.destroy
    redirect_to orders_path, notice: '受注情報が正常に削除されました。'
  end

  private
    def set_order
      @order = Order.includes(:order_items, :customer, :payment_method).find(params[:id])
    end

    def order_params
      params.require(:order).permit(
        :customer_id, :order_date, :expected_delivery_date, 
        :actual_delivery_date, :payment_method_id,
        order_items_attributes: [:id, :product_id, :quantity, :unit_price, :tax_rate, :_destroy]
      )
    end
    
    # 単価と税率を商品マスタから設定するヘルパーメソッド
    def set_price_and_tax_rate(order_items)
      order_items.each do |item|
        if item.product_id.present? && (item.unit_price.blank? || item.tax_rate.blank?)
          product = Product.find(item.product_id)
          item.unit_price = product.price if item.unit_price.blank?
          item.tax_rate = product.tax_rate if item.tax_rate.blank?
        end
      end
    end

    def set_payment_methods
      @payment_methods = PaymentMethod.all
    end

    def search_params
      params.fetch(:search, {}).permit(
        :customer_name,
        :order_date_from, :order_date_to,
        :expected_delivery_date_from, :expected_delivery_date_to,
        :actual_delivery_date_from, :actual_delivery_date_to,
        :total_without_tax,
        :payment_method_id,
        :invoice_status
      )
    end
end 