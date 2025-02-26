class TaxRatesController < ApplicationController
  before_action :require_login
  before_action :require_editor, only: [:new, :create, :edit, :update, :destroy]
  before_action :set_tax_rate, only: [:show, :edit, :update, :destroy]

  def index
    @tax_rates = TaxRate.all.order(start_date: :desc)
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
      redirect_to tax_rates_path, notice: '税率が正常に作成されました。'
    else
      render :new
    end
  end

  def update
    if @tax_rate.update(tax_rate_params)
      redirect_to tax_rates_path, notice: '税率が正常に更新されました。'
    else
      render :edit
    end
  end

  def destroy
    @tax_rate.destroy
    redirect_to tax_rates_path, notice: '税率が正常に削除されました。'
  end

  private

  def set_tax_rate
    @tax_rate = TaxRate.find(params[:id])
  end

  def tax_rate_params
    params.require(:tax_rate).permit(:name, :rate, :start_date, :end_date)
  end
end 