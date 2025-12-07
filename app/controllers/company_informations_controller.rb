class CompanyInformationsController < ApplicationController
  before_action :require_editor_limited_access
  before_action :require_viewer_show_only
  before_action :set_company_information, only: [ :show, :edit, :update, :destroy ]

  def index
    @company_informations = CompanyInformation.all.page(params[:page]).per(30)
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
    if @company_information.destroy
      redirect_to company_informations_url, notice: "自社情報が正常に削除されました。"
    else
      # モデル側の before_destroy で削除禁止の場合にエラーが乗る
      message = @company_information.errors.full_messages.to_sentence.presence ||
                "受注情報が存在するため自社情報を削除できません。受注がない状態で削除してください。"
      redirect_to company_informations_url, alert: message
    end
  end

  private
    def set_company_information
      @company_information = CompanyInformation.find(params[:id])
    end

    def company_information_params
      params.require(:company_information).permit(:name, :postal_code, :address, :phone_number, :fax_number, :invoice_registration_number, :representative_name, :company_seal)
    end
end
