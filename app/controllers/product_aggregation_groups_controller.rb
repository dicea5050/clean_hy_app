class ProductAggregationGroupsController < ApplicationController
  before_action :require_login
  before_action :require_editor_limited_access
  before_action :require_editor, only: [ :update_all ]
  before_action :set_fiscal_year
  before_action :set_categories

  def index
    # 事業部ごとに商品を取得
    @groups_by_category = {}

    @categories.each do |category|
      products = category.products.order(:product_code)
      groups = []

      products.each do |product|
        # 既存のグループ設定を取得
        existing_group = ProductAggregationGroup.find_by(
          fiscal_year: @fiscal_year,
          product_category_id: category.id,
          product_id: product.id
        )

        groups << {
          product: product,
          group_code: existing_group&.group_code || "",
          group_name: existing_group&.group_name || ""
        }
      end

      @groups_by_category[category] = groups
    end
  end

  def update_all
    # パラメータから一括更新
    if params[:groups].present?
      ProductAggregationGroup.transaction do
        params[:groups].each do |key, group_params|
          category_id, product_id = key.split("_").map(&:to_i)

          next unless category_id.present? && product_id.present?

          group = ProductAggregationGroup.find_or_initialize_by(
            fiscal_year: @fiscal_year,
            product_category_id: category_id,
            product_id: product_id
          )

          group.group_code = group_params[:group_code].presence
          group.group_name = group_params[:group_name].presence

          if group.group_name.blank?
            # グループ名が空白の場合は削除
            group.destroy if group.persisted?
          else
            group.save!
          end
        end
      end

      redirect_to product_aggregation_groups_path(fiscal_year: @fiscal_year), notice: "集計グループ設定を更新しました。"
    else
      redirect_to product_aggregation_groups_path(fiscal_year: @fiscal_year), alert: "更新するデータがありません。"
    end
  end

  private

  def set_fiscal_year
    @fiscal_year = params[:fiscal_year].present? ? params[:fiscal_year].to_i : Date.today.year
    @fiscal_year = Date.today.year if @fiscal_year < 2000 || @fiscal_year > 3000
  end

  def set_categories
    @product_categories = ProductCategory.order(:code)
    @categories = @product_categories.includes(:products)
  end
end
