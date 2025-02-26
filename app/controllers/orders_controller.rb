class OrdersController < ApplicationController
  before_action :set_order, only: [:show, :edit, :update, :destroy]

  def index
    @orders = Order.includes(:customer).order(order_date: :desc)
    # ページネーションなしのシンプルな取得
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
      @order = Order.includes(:order_items, :customer).find(params[:id])
    end

    def order_params
      params.require(:order).permit(
        :customer_id, :order_date, :expected_delivery_date, :actual_delivery_date, :payment_method,
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
end 