class ProductCategoriesController < ApplicationController
  before_action :require_login
  before_action :require_editor_limited_access
  before_action :set_product_category, only: [ :show, :edit, :update, :destroy ]

  def index
    @product_categories = ProductCategory.all
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
    @product_category.destroy
    redirect_to product_categories_path, notice: "カテゴリーが正常に削除されました。"
  end

  private
    def set_product_category
      @product_category = ProductCategory.find(params[:id])
    end

    def product_category_params
      params.require(:product_category).permit(:code, :name)
    end
end
