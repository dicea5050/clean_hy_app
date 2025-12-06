class Shop::DeliveryLocationsController < ApplicationController
  layout "shop"
  before_action :authenticate_customer!
  before_action :set_delivery_location, only: [ :show ]

  def new
    @delivery_location = DeliveryLocation.new
    @delivery_location.customer_id = current_customer.id
  end

  def create
    @delivery_location = DeliveryLocation.new(delivery_location_params)
    @delivery_location.customer_id = current_customer.id

    if @delivery_location.save
      redirect_to shop_mypage_path, notice: "納品先を登録しました。"
    else
      render :new
    end
  end

  def show
    # 現在の顧客の納品先のみアクセス可能
    if @delivery_location.customer_id != current_customer.id
      head :forbidden
      return
    end

    respond_to do |format|
      format.json { render json: @delivery_location }
    end
  end

  private

  def set_delivery_location
    @delivery_location = DeliveryLocation.find(params[:id])
  end

  def delivery_location_params
    params.require(:delivery_location).permit(:name, :postal_code, :address, :phone, :contact_person)
  end
end
