class Shop::SessionsController < ApplicationController
  layout "shop"

  def new
    # ログイン画面表示
    @customer = Customer.new
  end

  def create
    @customer = Customer.find_by(customer_code: params[:customer][:customer_code])

    if @customer && @customer.password_set? && @customer.authenticate(params[:customer][:password])
      # ログイン成功
      session[:customer_id] = @customer.id
      redirect_to new_shop_order_path, notice: "ログインしました"
    else
      # ログイン失敗
      flash.now[:alert] = "ログインIDまたはパスワードが正しくありません"
      render :new
    end
  end

  def destroy
    session[:customer_id] = nil
    redirect_to shop_products_path, notice: "ログアウトしました"
  end
end
