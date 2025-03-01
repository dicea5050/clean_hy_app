class Shop::OrdersController < ApplicationController
  layout 'shop'
  
  def new
    @cart = current_cart
    @order = Order.new
    @payment_methods = PaymentMethod.all
  end
  
  def create
    @cart = current_cart
    @order = Order.new(order_params)
    
    if @order.save
      # カートの内容を注文に変換し、在庫を減らす
      ActiveRecord::Base.transaction do
        @cart.items.each do |item|
          @order.order_items.create(
            product_id: item.product_id,
            quantity: item.quantity,
            price: item.product.price
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
      @payment_methods = PaymentMethod.all
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
  
  def order_params
    params.require(:order).permit(:name, :email, :address, :payment_method_id, :desired_delivery_date)
  end
end 