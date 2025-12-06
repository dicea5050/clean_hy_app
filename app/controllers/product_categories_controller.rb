class ProductCategoriesController < ApplicationController
  before_action :require_login
  before_action :require_editor_limited_access
  before_action :set_product_category, only: [ :show, :edit, :update, :destroy ]

  def index
    @product_categories = ProductCategory.all.page(params[:page]).per(30)
  end

  def show
  end

  def new
    @product_category = ProductCategory.new
  end

  def edit
  end

  def create
    @product_category = ProductCategory.new(product_category_params)

    if @product_category.save
      redirect_to product_categories_path, notice: "カテゴリーが正常に作成されました。"
    else
      render :new
    end
  end

  def update
    if @product_category.update(product_category_params)
      redirect_to product_categories_path, notice: "カテゴリーが正常に更新されました。"
    else
      render :edit
    end
  end

  def destroy
    if @product_category.destroy
      redirect_to product_categories_path, notice: "カテゴリーが正常に削除されました。"
    else
      # dependent: :restrict_with_error により関連があると削除は失敗
      # ActiveRecordの英語メッセージ（"products"など）を出さず、日本語固定文言を表示する
      redirect_to product_categories_path, alert: "このカテゴリーに属する商品が存在するため削除できません。先に関連商品を変更または削除してください。"
    end
  end

  private
    def set_product_category
      @product_category = ProductCategory.find(params[:id])
    end

    def product_category_params
      params.require(:product_category).permit(:code, :name)
    end
end
