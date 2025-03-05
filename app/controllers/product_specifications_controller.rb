class ProductSpecificationsController < ApplicationController
  before_action :require_login
  before_action :require_editor
  before_action :set_product_specification, only: [:show, :edit, :update, :destroy]

  def index
    @product_specifications = ProductSpecification.all
  end

  def show
  end

  def new
    @product_specification = ProductSpecification.new
  end

  def edit
  end

  def create
    @product_specification = ProductSpecification.new(product_specification_params)

    if @product_specification.save
      redirect_to product_specifications_path, notice: '商品規格が正常に作成されました。'
    else
      render :new
    end
  end

  def update
    if @product_specification.update(product_specification_params)
      redirect_to product_specifications_path, notice: '商品規格が正常に更新されました。'
    else
      render :edit
    end
  end

  def destroy
    @product_specification.destroy
    redirect_to product_specifications_path, notice: '商品規格が正常に削除されました。'
  end

  private

  def set_product_specification
    @product_specification = ProductSpecification.find(params[:id])
  end

  def product_specification_params
    params.require(:product_specification).permit(:name, :is_active)
  end
end
