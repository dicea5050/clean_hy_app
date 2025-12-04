class TaxRatesController < ApplicationController
  before_action :require_login
  before_action :require_editor_limited_access
  before_action :require_editor, only: [ :new, :create, :edit, :update, :destroy ]
  before_action :set_tax_rate, only: [ :show, :edit, :update, :destroy ]

  def index
    @tax_rates = TaxRate.all.order(start_date: :desc).page(params[:page]).per(30)
  end

  def show
  end

  def new
    @tax_rate = TaxRate.new
  end

  def edit
  end

  def create
    @tax_rate = TaxRate.new(tax_rate_params)

    if @tax_rate.save
      redirect_to tax_rates_path, notice: "税率が正常に作成されました。"
    else
      render :new
    end
  end

  def update
    if @tax_rate.update(tax_rate_params)
      redirect_to tax_rates_path, notice: "税率が正常に更新されました。"
    else
      render :edit
    end
  end

  def destroy
    begin
      if @tax_rate.destroy
        redirect_to tax_rates_path, notice: "税率が正常に削除されました。"
      else
        redirect_to tax_rates_path, alert: "この税率を参照している商品が存在するため削除できません。先に関連商品を変更または削除してください。"
      end
    rescue ActiveRecord::InvalidForeignKey
      redirect_to tax_rates_path, alert: "この税率を参照している商品が存在するため削除できません。先に関連商品を変更または削除してください。"
    end
  end

  private

  def set_tax_rate
    @tax_rate = TaxRate.find(params[:id])
  end

  def tax_rate_params
    params.require(:tax_rate).permit(:name, :rate, :start_date, :end_date)
  end
end
