class DeliveryLocationsController < ApplicationController
  before_action :set_delivery_location, only: [ :show, :edit, :update, :destroy ]

  def index
    @delivery_locations = DeliveryLocation.all
  end

  def show
  end

  def new
    @delivery_location = DeliveryLocation.new
  end

  def edit
  end

  def create
    @delivery_location = DeliveryLocation.new(delivery_location_params)

    if @delivery_location.save
      redirect_to @delivery_location, notice: "納品先を登録しました。"
    else
      render :new
    end
  end

  def update
    if @delivery_location.update(delivery_location_params)
      redirect_to @delivery_location, notice: "納品先を更新しました。"
    else
      render :edit
    end
  end

  def destroy
    @delivery_location.destroy
    redirect_to delivery_locations_url, notice: "納品先を削除しました。"
  end

  private

  def set_delivery_location
    @delivery_location = DeliveryLocation.find(params[:id])
  end

  def delivery_location_params
    params.require(:delivery_location).permit(:customer_id, :name, :postal_code, :address, :phone, :contact_person)
  end
end
