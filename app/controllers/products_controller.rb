class ProductsController < ApplicationController
  before_action :require_login
  before_action :require_editor, only: [ :new, :create, :edit, :update, :destroy ]
  before_action :set_product, only: [ :show, :edit, :update, :destroy ]

  def index
    @products = Product.all.includes(:tax_rate)
  end

  def show
    respond_to do |format|
      format.html
      format.json {
        begin
          Rails.logger.info "Product ID: #{params[:id]}"
          if @product
            Rails.logger.info "Found product: #{@product.inspect}"
            # 実際のモデルデータを使用
            tax_rate_value = @product.tax_rate&.rate || 0
            Rails.logger.info "Tax rate for product: #{tax_rate_value}"

            render json: {
              product_id: @product.id,
              unit_price: @product.price,  # priceフィールドを使用
              tax_rate_id: @product.tax_rate_id,
              tax_rate: tax_rate_value,  # 実際の税率の値（0%の場合も含む）
              unit_id: 1  # unit_idフィールドがないため、デフォルト値を使用
            }
          else
            Rails.logger.error "Product not found with ID: #{params[:id]}"
            render json: { error: "Product not found" }, status: :not_found
          end
        rescue => e
          Rails.logger.error "Error in ProductsController#show: #{e.message}"
          Rails.logger.error e.backtrace.join("\n")
          render json: { error: e.message }, status: :internal_server_error
        end
      }
    end
  end

  def new
    @product = Product.new(is_public: false)
  end

  def edit
  end

  def create
    @product = Product.new(product_params)

    if @product.save
      redirect_to products_path, notice: "商品が正常に作成されました。"
    else
      render :new
    end
  end

  def update
    if @product.update(product_params)
      redirect_to products_path, notice: "商品が正常に更新されました。"
    else
      render :edit
    end
  end

  def destroy
    @product.destroy
    redirect_to products_path, notice: "商品が正常に削除されました。"
  end

  private

  def set_product
    @product = Product.find(params[:id])
  end

  def product_params
    params.require(:product).permit(
      :product_code,
      :name,
      :tax_rate_id,
      :price,
      :stock,
      :is_public
    )
  end
end
