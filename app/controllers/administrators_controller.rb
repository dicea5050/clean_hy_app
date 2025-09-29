class AdministratorsController < ApplicationController
  before_action :require_admin, except: [ :login, :authenticate, :logout ]
  before_action :set_administrator, only: [ :show, :edit, :update, :destroy ]

  def index
    @administrators = Administrator.all.order(:email)
  end

  def show
  end

  def new
    @administrator = Administrator.new
  end

  def create
    @administrator = Administrator.new(administrator_params)

    if @administrator.save
      redirect_to administrators_path, notice: "管理者が正常に作成されました。"
    else
      render :new
    end
  end

  def edit
  end

  def update
    # パスワードが空の場合は更新しない
    if params[:administrator][:password].blank?
      params[:administrator].delete(:password)
      params[:administrator].delete(:password_confirmation)
    end

    if @administrator.update(administrator_params)
      redirect_to administrators_path, notice: "管理者が正常に更新されました。"
    else
      render :edit
    end
  end

  def destroy
    @administrator.destroy
    redirect_to administrators_path, notice: "管理者が正常に削除されました。"
  end

  def login
    # ログイン画面表示用
  end

  def authenticate
    administrator = Administrator.find_by(email: params[:email])

    if administrator&.authenticate(params[:password])
      session[:administrator_id] = administrator.id
      redirect_to masters_path, notice: "ログインしました。"
    else
      flash.now[:alert] = "メールアドレスまたはパスワードが正しくありません。"
      render :login
    end
  end

  def logout
    session[:administrator_id] = nil
    redirect_to login_path, notice: "ログアウトしました。"
  end

  private

  def set_administrator
    @administrator = Administrator.find(params[:id])
  end

  def administrator_params
    params.require(:administrator).permit(:email, :password, :password_confirmation, :role)
  end

  def require_admin
    unless session[:administrator_id].present?
      redirect_to login_path, alert: "ログインしてください。"
      return
    end

    admin = Administrator.find_by(id: session[:administrator_id])

    unless admin&.admin?
      redirect_to masters_path, alert: "この操作を行う権限がありません。"
    end
  end
end
