class Shop::SessionsController < ApplicationController
  layout "shop_login"

  def new
    # ログイン画面表示
    @customer = Customer.new
  end

  def create
    email = params[:customer][:email]
    password = params[:customer][:password]
    @customer = Customer.find_by(email: email)

    # ログイン失敗時のエラーメッセージを詳細化
    error_message = if @customer.nil?
      "入力されたメールアドレスは登録されていません"
    elsif !@customer.password_set?
      "このアカウントにはパスワードが設定されていません。管理者にお問い合わせください"
    elsif !@customer.authenticate(password)
      "パスワードが正しくありません"
    end

    if error_message.nil?
      # ログイン成功
      session[:customer_id] = @customer.id
      redirect_to shop_products_path, notice: "ログインしました"
    else
      # ログイン失敗
      # ビューでform_withを使用するため、@customerを初期化する（メールアドレスのみ保持）
      @customer = Customer.new(email: email)
      flash.now[:alert] = error_message
      render :new
    end
  end

  def destroy
    session[:customer_id] = nil
    redirect_to shop_products_path, notice: "ログアウトしました"
  end
end
