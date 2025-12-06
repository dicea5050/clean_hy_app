class EmailTemplatesController < ApplicationController
  before_action :require_viewer_or_editor_access
  before_action :require_editor, except: [ :index, :show ]
  before_action :set_email_template, only: [ :show, :edit, :update, :destroy ]

  def index
    @email_templates = EmailTemplate.order(:name).page(params[:page]).per(20)
  end

  def show
  end

  def new
    @email_template = EmailTemplate.new
  end

  def create
    @email_template = EmailTemplate.new(email_template_params)

    if @email_template.save
      redirect_to email_templates_path, notice: "メールテンプレートを作成しました。"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @email_template.update(email_template_params)
      redirect_to email_templates_path, notice: "メールテンプレートを更新しました。"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @email_template.destroy
    redirect_to email_templates_path, notice: "メールテンプレートを削除しました。"
  end

  private

  def set_email_template
    @email_template = EmailTemplate.find(params[:id])
  end

  def email_template_params
    params.require(:email_template).permit(:name, :subject, :body, :is_active)
  end
end
