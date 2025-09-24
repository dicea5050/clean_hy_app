class CustomersController < ApplicationController
  before_action :require_login
  before_action :require_editor_limited_access
  before_action :require_editor, only: [ :new, :create, :update, :destroy ]
  before_action :set_customer, only: [ :show, :edit, :update, :destroy ]

  def index
    @customers = Customer.order(:company_name).page(params[:page]).per(25)
  end

  def show
    @delivery_locations = @customer.delivery_locations.order(is_main_office: :desc, name: :asc)
  end

  def new
    @customer = Customer.new
  end

  def edit
  end

  def create
    @customer = Customer.new(customer_params)

    if @customer.save
      redirect_to customers_path, notice: "顧客が正常に作成されました。"
    else
      render :new
    end
  end

  def update
    # パスワードが空欄の場合、パラメータから削除して更新しない
    if params[:customer][:password].blank?
      params[:customer].delete(:password)
    end

    if @customer.update(customer_params)
      redirect_to customers_path, notice: "顧客が正常に更新されました。"
    else
      render :edit
    end
  end

  def destroy
    @customer.destroy
    redirect_to customers_path, notice: "顧客が正常に削除されました。"
  end

  def search
    @customers = Customer.where("company_name LIKE ?", "%#{params[:q]}%").limit(10)
    render json: @customers.map { |c| { id: c.id, text: c.company_name } }
  end

  # 顧客に紐づく納品先を取得するAPIエンドポイント
  def delivery_locations
    @customer = Customer.find(params[:id])
    @delivery_locations = @customer.delivery_locations.order(is_main_office: :desc, name: :asc)

    # デバッグ用にログ出力
    Rails.logger.debug "納品先データ取得: 顧客ID=#{@customer.id}, 納品先数=#{@delivery_locations.size}"
    @delivery_locations.each do |loc|
      Rails.logger.debug "  - ID:#{loc.id}, 名前:#{loc.name}, 本社:#{loc.is_main_office}"
    end

    render json: @delivery_locations.map { |loc| { id: loc.id, name: loc.name } }
  end

  private

  def set_customer
    @customer = Customer.find(params[:id])
  end

  def customer_params
    params.require(:customer).permit(
      :customer_code, :company_name, :postal_code, :address,
      :department, :contact_name, :phone_number, :email, :fax_number,
      :password, :password_confirmation, :invoice_delivery_method, :billing_closing_day
    )
  end
end
