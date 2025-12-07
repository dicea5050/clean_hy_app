class BudgetsController < ApplicationController
  before_action :require_login
  before_action :require_editor_limited_access
  # editorはBudgetの登録・編集・削除不可のため、adminのみ許可
  before_action :require_admin_only, only: [ :new, :create, :edit, :update ]
  before_action :require_viewer_show_only
  before_action :set_fiscal_year, only: [ :index, :new, :create, :edit, :update ]
  before_action :set_categories, only: [ :index, :new, :create, :edit, :update ]
  before_action :set_budget, only: [ :edit, :update ]

  def index
    # 事業部ごとにグループを取得（一覧表示用）
    @groups_by_category = {}

    @product_categories.each do |category|
      # 集計グループ設定からグループ情報を取得（group_nameごとに最初のgroup_codeを取得）
      group_names = ProductAggregationGroup
        .where(fiscal_year: @fiscal_year, product_category_id: category.id)
        .where.not(group_name: [ nil, "" ])
        .distinct
        .pluck(:group_name)

      # 各group_nameに対して最初のgroup_codeを取得
      group_data_list = group_names.map do |group_name|
        first_group = ProductAggregationGroup
          .where(fiscal_year: @fiscal_year, product_category_id: category.id, group_name: group_name)
          .order(:group_code)
          .first
        {
          group_name: group_name,
          group_code: first_group&.group_code
        }
      end

      # group_codeでソート（数値として扱う、1が上）
      group_data_list.sort_by! do |g|
        # group_codeが数値の場合は数値として、文字列の場合は文字列としてソート
        code = g[:group_code].to_s
        if code.blank?
          [ 2, "" ] # nilまたは空の場合は最後に
        elsif code.match?(/^\d+$/)
          [ 0, code.to_i ] # 数値の場合は先に
        else
          [ 1, code ] # 文字列の場合は後に
        end
      end

      # グループごとの予算
      groups = []
      group_data_list.each do |group_data|
        group_name = group_data[:group_name]
        group_code = group_data[:group_code]

        group_budget = Budget.find_by(
          fiscal_year: @fiscal_year,
          product_category_id: category.id,
          product_id: nil,
          aggregation_group_name: group_name
        )

        # 予算が登録されているグループのみ表示
        next unless group_budget

        # このグループに属する商品を取得
        group_products = ProductAggregationGroup
          .where(fiscal_year: @fiscal_year, product_category_id: category.id, group_name: group_name)
          .includes(:product)
          .map(&:product)

        groups << {
          type: :group,
          group_name: group_name,
          group_code: group_code,
          budget: group_budget,
          products: group_products
        }
      end

      @groups_by_category[category] = groups if groups.any?
    end
  end

  def new
    # 事業部ごとにグループを取得（入力フォーム用）
    @groups_by_category = {}

    @product_categories.each do |category|
      # 集計グループ設定からグループ情報を取得（group_nameごとに最初のgroup_codeを取得）
      group_names = ProductAggregationGroup
        .where(fiscal_year: @fiscal_year, product_category_id: category.id)
        .where.not(group_name: [ nil, "" ])
        .distinct
        .pluck(:group_name)

      # 各group_nameに対して最初のgroup_codeを取得
      group_data_list = group_names.map do |group_name|
        first_group = ProductAggregationGroup
          .where(fiscal_year: @fiscal_year, product_category_id: category.id, group_name: group_name)
          .order(:group_code)
          .first
        {
          group_name: group_name,
          group_code: first_group&.group_code
        }
      end

      # group_codeでソート（数値として扱う、1が上）
      group_data_list.sort_by! do |g|
        # group_codeが数値の場合は数値として、文字列の場合は文字列としてソート
        code = g[:group_code].to_s
        if code.blank?
          [ 2, "" ] # nilまたは空の場合は最後に
        elsif code.match?(/^\d+$/)
          [ 0, code.to_i ] # 数値の場合は先に
        else
          [ 1, code ] # 文字列の場合は後に
        end
      end

      # グループごとの予算
      groups = []
      group_data_list.each do |group_data|
        group_name = group_data[:group_name]
        group_code = group_data[:group_code]

        group_budget = Budget.find_by(
          fiscal_year: @fiscal_year,
          product_category_id: category.id,
          product_id: nil,
          aggregation_group_name: group_name
        )

        # このグループに属する商品を取得
        group_products = ProductAggregationGroup
          .where(fiscal_year: @fiscal_year, product_category_id: category.id, group_name: group_name)
          .includes(:product)
          .map(&:product)

        groups << {
          type: :group,
          group_name: group_name,
          group_code: group_code,
          budget: group_budget,
          products: group_products
        }
      end

      @groups_by_category[category] = groups
    end
  end

  def create
    # 一括更新処理
    if params[:budgets].present?
      saved_count = 0
      error_messages = []

      Budget.transaction do
        params[:budgets].each do |key, budget_params|
          category_id, group_name = key.split("|")
          category_id = category_id.to_i

          next unless category_id.present?

          # グループ名が空の場合は事業部全体の予算
          if group_name.blank? || group_name == "category"
            budget = Budget.find_or_initialize_by(
              fiscal_year: @fiscal_year,
              product_category_id: category_id,
              product_id: nil,
              aggregation_group_name: nil
            )
          else
            budget = Budget.find_or_initialize_by(
              fiscal_year: @fiscal_year,
              product_category_id: category_id,
              product_id: nil,
              aggregation_group_name: group_name
            )
          end

          # 空文字列やnilの場合は0として扱う（カンマも除去）
          budget_amount_str = budget_params[:budget_amount].to_s.strip
          budget_amount = budget_amount_str.empty? ? 0 : budget_amount_str.gsub(/,/, "").gsub(/[^\d]/, "").to_i

          if budget_amount > 0
            budget.budget_amount = budget_amount
            if budget.save
              saved_count += 1
            else
              error_messages << budget.errors.full_messages.join(", ")
            end
          elsif budget.persisted?
            budget.destroy
          end
        end
      end

      if error_messages.any?
        redirect_to new_budget_path(fiscal_year: @fiscal_year), alert: "予算の登録中にエラーが発生しました: #{error_messages.join('; ')}"
      elsif saved_count > 0
        redirect_to budgets_path(fiscal_year: @fiscal_year), notice: "予算を#{saved_count}件登録しました。"
      else
        redirect_to budgets_path(fiscal_year: @fiscal_year), notice: "予算を更新しました。"
      end
    else
      redirect_to new_budget_path(fiscal_year: @fiscal_year), alert: "更新するデータがありません。"
    end
  rescue => e
    Rails.logger.error "Budget creation error: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    redirect_to new_budget_path(fiscal_year: @fiscal_year), alert: "予算の登録中にエラーが発生しました: #{e.message}"
  end

  def edit
    # editページ用のデータ準備（newページと同じ構造）
    @groups_by_category = {}

    @product_categories.each do |category|
      # 集計グループ設定からグループ情報を取得（group_nameごとに最初のgroup_codeを取得）
      group_names = ProductAggregationGroup
        .where(fiscal_year: @fiscal_year, product_category_id: category.id)
        .where.not(group_name: [ nil, "" ])
        .distinct
        .pluck(:group_name)

      # 各group_nameに対して最初のgroup_codeを取得
      group_data_list = group_names.map do |group_name|
        first_group = ProductAggregationGroup
          .where(fiscal_year: @fiscal_year, product_category_id: category.id, group_name: group_name)
          .order(:group_code)
          .first
        {
          group_name: group_name,
          group_code: first_group&.group_code
        }
      end

      # group_codeでソート（数値として扱う、1が上）
      group_data_list.sort_by! do |g|
        code = g[:group_code].to_s
        if code.blank?
          [ 2, "" ]
        elsif code.match?(/^\d+$/)
          [ 0, code.to_i ]
        else
          [ 1, code ]
        end
      end

      # グループごとの予算
      groups = []
      group_data_list.each do |group_data|
        group_name = group_data[:group_name]
        group_code = group_data[:group_code]

        group_budget = Budget.find_by(
          fiscal_year: @fiscal_year,
          product_category_id: category.id,
          product_id: nil,
          aggregation_group_name: group_name
        )

        # このグループに属する商品を取得
        group_products = ProductAggregationGroup
          .where(fiscal_year: @fiscal_year, product_category_id: category.id, group_name: group_name)
          .includes(:product)
          .map(&:product)

        groups << {
          type: :group,
          group_name: group_name,
          group_code: group_code,
          budget: group_budget,
          products: group_products
        }
      end

      @groups_by_category[category] = groups
    end
  end

  def update
    # 一括更新処理（createと同じ）
    if params[:budgets].present?
      saved_count = 0
      error_messages = []

      Budget.transaction do
        params[:budgets].each do |key, budget_params|
          category_id, group_name = key.split("|")
          category_id = category_id.to_i

          next unless category_id.present?

          if group_name.blank? || group_name == "category"
            budget = Budget.find_or_initialize_by(
              fiscal_year: @fiscal_year,
              product_category_id: category_id,
              product_id: nil,
              aggregation_group_name: nil
            )
          else
            budget = Budget.find_or_initialize_by(
              fiscal_year: @fiscal_year,
              product_category_id: category_id,
              product_id: nil,
              aggregation_group_name: group_name
            )
          end

          budget_amount_str = budget_params[:budget_amount].to_s.strip
          budget_amount = budget_amount_str.empty? ? 0 : budget_amount_str.gsub(/,/, "").gsub(/[^\d]/, "").to_i

          if budget_amount > 0
            budget.budget_amount = budget_amount
            if budget.save
              saved_count += 1
            else
              error_messages << budget.errors.full_messages.join(", ")
            end
          elsif budget.persisted?
            budget.destroy
          end
        end
      end

      if error_messages.any?
        redirect_to edit_budgets_path(fiscal_year: @fiscal_year), alert: "予算の更新中にエラーが発生しました: #{error_messages.join('; ')}"
      elsif saved_count > 0
        redirect_to budgets_path(fiscal_year: @fiscal_year), notice: "予算を#{saved_count}件更新しました。"
      else
        redirect_to budgets_path(fiscal_year: @fiscal_year), notice: "予算を更新しました。"
      end
    else
      redirect_to edit_budgets_path(fiscal_year: @fiscal_year), alert: "更新するデータがありません。"
    end
  rescue => e
    Rails.logger.error "Budget update error: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    redirect_to edit_budgets_path(fiscal_year: @fiscal_year), alert: "予算の更新中にエラーが発生しました: #{e.message}"
  end

  private

  def set_fiscal_year
    @fiscal_year = params[:fiscal_year].present? ? params[:fiscal_year].to_i : Date.today.year
    @fiscal_year = Date.today.year if @fiscal_year < 2000 || @fiscal_year > 3000
  end

  def set_categories
    @product_categories = ProductCategory.order(:code)
  end

  def set_budget
    # editページでは、年度全体を編集するため、budget_idは使用しない
    # パラメータのidは無視し、年度をパラメータから取得
    @budget = Budget.new(fiscal_year: @fiscal_year)
  end
end
