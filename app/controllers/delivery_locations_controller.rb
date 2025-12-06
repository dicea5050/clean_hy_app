class DeliveryLocationsController < ApplicationController
  before_action :require_editor_limited_access
  before_action :set_delivery_location, only: [ :show, :edit, :update, :destroy ]

  def index
    @delivery_locations = DeliveryLocation.all.page(params[:page]).per(30)
  end

  def show
    respond_to do |format|
      format.html
      format.json { render json: @delivery_location }
    end
  end

  def new
    @delivery_location = DeliveryLocation.new
    @delivery_location.customer_id = params[:customer_id] if params[:customer_id].present?
    @customers = Customer.all.order(:company_name)
  end

  def edit
    @customers = Customer.all.order(:company_name)
    @customer_code = @delivery_location.customer&.customer_code
  end

  def create
    @delivery_location = DeliveryLocation.new(delivery_location_params)
    @customers = Customer.all.order(:company_name)

    if @delivery_location.save
      redirect_to @delivery_location, notice: "納品先を登録しました。"
    else
      render :new
    end
  end

  def update
    @customers = Customer.all.order(:company_name)

    if @delivery_location.update(delivery_location_params)
      redirect_to @delivery_location, notice: "納品先を更新しました。"
    else
      render :edit
    end
  end

  def destroy
    if @delivery_location.destroy
      redirect_to delivery_locations_url, notice: "納品先を削除しました。"
    else
      redirect_to delivery_locations_url, alert: "この納品先は既に使用されているため削除できません。"
    end
  end

  private

  def set_delivery_location
    @delivery_location = DeliveryLocation.find(params[:id])
  end

  def delivery_location_params
    params.require(:delivery_location).permit(:customer_id, :name, :postal_code, :address, :phone, :contact_person)
  end
end
