class Shop::MypageController < ApplicationController
  layout "shop"
  before_action :authenticate_customer!

  def show
    @customer = current_customer
    # ネットショップからの注文のみを取得
    @orders = @customer.orders.where(is_shop_order: true).order(created_at: :desc).page(params[:page]).per(10)
    # 納品先情報を取得
    @delivery_locations = @customer.delivery_locations.order(is_main_office: :desc, created_at: :asc)
  end
end

