class CompanyInformationsController < ApplicationController
  before_action :set_company_information, only: [ :show, :edit, :update, :destroy ]

  def index
    @company_informations = CompanyInformation.all
  end

  def show
  end

  def new
    @company_information = CompanyInformation.new
  end

  def edit
  end

  def create
    @company_information = CompanyInformation.new(company_information_params)

    if @company_information.save
      redirect_to @company_information, notice: "自社情報が正常に作成されました。"
    else
      render :new
    end
  end

  def update
    if @company_information.update(company_information_params)
      redirect_to @company_information, notice: "自社情報が正常に更新されました。"
    else
      render :edit
    end
  end

  def destroy
    @company_information.destroy
    redirect_to company_informations_url, notice: "自社情報が正常に削除されました。"
  end

  private
    def set_company_information
      @company_information = CompanyInformation.find(params[:id])
    end

    def company_information_params
      params.require(:company_information).permit(:name, :postal_code, :address, :phone_number, :fax_number, :invoice_registration_number, :company_seal)
    end
end
