class Shop::CartsController < ApplicationController
  layout "shop"
  before_action :authenticate_customer!

  def show
    @cart = current_cart
  end

  def update
    @cart = current_cart

    # 単一商品の場合
    if params[:product_id].present?
      product = Product.find(params[:product_id])
      quantity = params[:quantity].to_i

      if quantity > 0
        if product.in_stock?(quantity)
          @cart.add_item(product, quantity)
          flash[:notice] = "商品をカートに追加しました"
        else
          flash[:alert] = "商品の在庫が不足しています"
        end
      end
    # 複数商品の一括追加の場合
    elsif params[:product_quantities].present?
      all_available = true
      items_to_add = []

      params[:product_quantities].each do |product_id, quantity|
        quantity = quantity.to_i
        if quantity > 0
          product = Product.find(product_id)
          unless product.in_stock?(quantity)
            all_available = false
            flash[:alert] = "#{product.name}の在庫が不足しています"
            break
          end
          items_to_add << [ product, quantity ]
        end
      end

      if all_available && items_to_add.any?
        items_to_add.each do |product, quantity|
          @cart.add_item(product, quantity)
        end
        flash[:notice] = "商品をカートに追加しました"
      end
    end

    session[:cart] = @cart.serialize

    redirect_to shop_cart_path
  end

  def destroy
    session[:cart] = nil
    redirect_to shop_products_path, notice: "カートを空にしました"
  end

  def update_item
    @cart = current_cart
    product_id = params[:product_id]
    quantity = params[:quantity].to_i

    product = Product.find(product_id)
    
    if quantity > 0
      if product.in_stock?(quantity)
        if @cart.update_item_quantity(product_id, quantity)
          session[:cart] = @cart.serialize
          flash[:notice] = "数量を更新しました"
        else
          flash[:alert] = "商品が見つかりませんでした"
        end
      else
        flash[:alert] = "商品の在庫が不足しています"
      end
    else
      flash[:alert] = "数量は1以上である必要があります"
    end

    redirect_to shop_cart_path
  end

  def remove_item
    @cart = current_cart
    product_id = params[:product_id]

    if @cart.remove_item(product_id)
      session[:cart] = @cart.serialize
      flash[:notice] = "商品をカートから削除しました"
    else
      flash[:alert] = "商品が見つかりませんでした"
    end

    redirect_to shop_cart_path
  end

  private

  def current_cart
    Cart.from_hash(session[:cart] || {})
  end
end
