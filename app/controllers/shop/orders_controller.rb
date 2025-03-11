class Shop::OrdersController < ApplicationController
  layout "shop"
  before_action :authenticate_customer!
  before_action :set_payment_methods, only: [ :new, :create ]
  before_action :set_delivery_locations, only: [ :new, :create ]

  def new
    @cart = current_cart
    @order = Order.new

    # 顧客情報は現在ログイン中の顧客から取得
    @order.customer_id = current_customer.id
    # 注文日を本日に設定
    @order.order_date = Date.today
  end

  def create
    @cart = current_cart
    @order = Order.new

    # 現在のログインユーザーを顧客として設定
    @order.customer_id = current_customer.id
    # 注文日を本日に設定
    @order.order_date = Date.today
    # 希望お届け日を納品予定日として設定
    @order.expected_delivery_date = params[:order][:desired_delivery_date]
    # 支払い方法を設定
    @order.payment_method_id = params[:order][:payment_method_id]
    # 配送先を設定
    @order.delivery_location_id = params[:order][:delivery_location_id]

    if @order.save
      # カートの内容を注文に変換し、在庫を減らす
      ActiveRecord::Base.transaction do
        @cart.items.each do |item|
          @order.order_items.create(
            product_id: item.product_id,
            quantity: item.quantity,
            unit_price: item.product.price,
            tax_rate: item.product.tax_rate.try(:rate) || 10
          )

          # 在庫を減らす（在庫がnilの場合は減らさない）
          product = item.product
          if product.stock.present?
            product.update!(stock: product.stock - item.quantity)
          end
        end
      end

      # カートを空にする
      session[:cart] = nil

      # 完了ページへリダイレクト
      redirect_to shop_order_complete_path
    else
      render :new
    end
  end

  def complete
    # 注文完了ページを表示
  end

  private

  def current_cart
    Cart.from_hash(session[:cart] || {})
  end

  def set_payment_methods
    @payment_methods = PaymentMethod.all
  end

  def set_delivery_locations
    @delivery_locations = current_customer.delivery_locations
  end
end
