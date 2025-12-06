class ProductsController < ApplicationController
  before_action :require_login
  before_action :require_editor_limited_access
  # 破壊的操作のみ管理者/編集者に限定
  before_action :require_editor, only: [ :destroy ]
  before_action :set_product, only: [ :show, :edit, :update, :destroy ]
  before_action :set_categories, only: [ :new, :edit, :create, :update ]

  def index
    @products = Product.all.includes(:tax_rate, :product_category).page(params[:page]).per(30)
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
    begin
      if @product.destroy
        redirect_to products_path, notice: "商品が正常に削除されました。"
      else
        # バリデーション等で削除できない場合
        redirect_to products_path, alert: (@product.errors.full_messages.to_sentence.presence || "商品を削除できませんでした。")
      end
    rescue ActiveRecord::InvalidForeignKey
      # 外部キー制約違反（例：受注明細に紐づいている）
      redirect_to products_path, alert: "この商品は受注明細に使用されているため削除できません。先に関連データを削除してください。"
    end
  end

  private

  def set_product
    @product = Product.find(params[:id])
  end

  def set_categories
    @product_categories = ProductCategory.all
  end

  def product_params
    params.require(:product).permit(
      :product_code,
      :name,
      :product_category_id,
      :tax_rate_id,
      :price,
      :stock,
      :is_public,
      :is_discount_target
    )
  end
end
