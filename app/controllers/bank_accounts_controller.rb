class BankAccountsController < ApplicationController
  before_action :require_editor_limited_access
  before_action :require_viewer_show_only
  before_action :set_bank_account, only: [ :show, :edit, :update, :destroy ]

  def index
    @bank_accounts = BankAccount.all.page(params[:page]).per(30)
  end

  def show
  end

  def new
    @bank_account = BankAccount.new
  end

  def edit
  end

  def create
    @bank_account = BankAccount.new(bank_account_params)

    if @bank_account.save
      redirect_to @bank_account, notice: "銀行口座情報が正常に作成されました。"
    else
      render :new
    end
  end

  def update
    if @bank_account.update(bank_account_params)
      redirect_to @bank_account, notice: "銀行口座情報が正常に更新されました。"
    else
      render :edit
    end
  end

  def destroy
    if @bank_account.destroy
      redirect_to bank_accounts_url, notice: "銀行口座情報が正常に削除されました。"
    else
      message = @bank_account.errors.full_messages.to_sentence.presence ||
                "請求書が存在するため銀行口座を削除できません。請求書がない状態で削除してください。"
      redirect_to bank_accounts_url, alert: message
    end
  end

  private
    def set_bank_account
      @bank_account = BankAccount.find(params[:id])
    end

    def bank_account_params
      params.require(:bank_account).permit(:bank_name, :branch_name, :account_type, :account_number, :account_holder, :disabled)
    end
end
