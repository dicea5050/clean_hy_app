class SalesReportsController < ApplicationController
  before_action :require_login
  before_action :require_editor_limited_access
  before_action :require_viewer_show_only

  def index
    # 年度の設定（デフォルトは現在の年度）
    @fiscal_year = params[:fiscal_year].present? ? params[:fiscal_year].to_i : current_fiscal_year
    @fiscal_year = current_fiscal_year if @fiscal_year < 2000 || @fiscal_year > 3000

    # 年度の開始日と終了日を計算（5月1日〜翌年4月30日）
    @fiscal_start_date = Date.new(@fiscal_year, 5, 1)
    @fiscal_end_date = Date.new(@fiscal_year + 1, 4, 30)

    # 事業部一覧を取得
    @categories = ProductCategory.order(:code).includes(:products)

    # 売上データを集計
    @sales_data = calculate_sales_data(@fiscal_start_date, @fiscal_end_date)

    # 予算データを取得（グループごと）
    @budgets = Budget.by_fiscal_year(@fiscal_year)
                     .where(product_id: nil)
                     .includes(:product_category)
                     .index_by { |b| [ b.product_category_id, b.aggregation_group_name ] }

    # 集計グループ設定を取得
    @aggregation_groups = ProductAggregationGroup
      .by_fiscal_year(@fiscal_year)
      .includes(:product, :product_category)
      .group_by { |g| [ g.product_category_id, g.group_name ] }

    # 集計グループごとのデータを準備
    @grouped_data = prepare_grouped_data
  end

  def export_pdf
    # 年度の設定（デフォルトは現在の年度）
    @fiscal_year = params[:fiscal_year].present? ? params[:fiscal_year].to_i : current_fiscal_year
    @fiscal_year = current_fiscal_year if @fiscal_year < 2000 || @fiscal_year > 3000

    # 年度の開始日と終了日を計算（5月1日〜翌年4月30日）
    @fiscal_start_date = Date.new(@fiscal_year, 5, 1)
    @fiscal_end_date = Date.new(@fiscal_year + 1, 4, 30)

    # 事業部一覧を取得
    @categories = ProductCategory.order(:code).includes(:products)

    # 売上データを集計
    @sales_data = calculate_sales_data(@fiscal_start_date, @fiscal_end_date)

    # 予算データを取得（グループごと）
    @budgets = Budget.by_fiscal_year(@fiscal_year)
                     .where(product_id: nil)
                     .includes(:product_category)
                     .index_by { |b| [ b.product_category_id, b.aggregation_group_name ] }

    # 集計グループ設定を取得
    @aggregation_groups = ProductAggregationGroup
      .by_fiscal_year(@fiscal_year)
      .includes(:product, :product_category)
      .group_by { |g| [ g.product_category_id, g.group_name ] }

    # 集計グループごとのデータを準備
    @grouped_data = prepare_grouped_data

    pdf = SalesReportPdf.new(@fiscal_year, @categories, @grouped_data)
    send_data pdf.render,
      filename: "売上集計_#{@fiscal_year}年度.pdf",
      type: "application/pdf",
      disposition: "inline"
  end

  def export_csv
    # 年度の設定（デフォルトは現在の年度）
    @fiscal_year = params[:fiscal_year].present? ? params[:fiscal_year].to_i : current_fiscal_year
    @fiscal_year = current_fiscal_year if @fiscal_year < 2000 || @fiscal_year > 3000

    # 年度の開始日と終了日を計算（5月1日〜翌年4月30日）
    @fiscal_start_date = Date.new(@fiscal_year, 5, 1)
    @fiscal_end_date = Date.new(@fiscal_year + 1, 4, 30)

    # 事業部一覧を取得
    @categories = ProductCategory.order(:code).includes(:products)

    # 売上データを集計
    @sales_data = calculate_sales_data(@fiscal_start_date, @fiscal_end_date)

    # 予算データを取得（グループごと）
    @budgets = Budget.by_fiscal_year(@fiscal_year)
                     .where(product_id: nil)
                     .includes(:product_category)
                     .index_by { |b| [ b.product_category_id, b.aggregation_group_name ] }

    # 集計グループ設定を取得
    @aggregation_groups = ProductAggregationGroup
      .by_fiscal_year(@fiscal_year)
      .includes(:product, :product_category)
      .group_by { |g| [ g.product_category_id, g.group_name ] }

    # 集計グループごとのデータを準備
    @grouped_data = prepare_grouped_data

    require "csv"

    # CSVデータを生成
    csv_data = CSV.generate(force_quotes: true) do |csv|
      # ヘッダー行
      csv << [ "No.", "商品名", "予算", "5月", "6月", "7月", "8月", "9月", "10月", "11月", "12月", "1月", "2月", "3月", "4月", "小計", "予算残高" ]

      # データ行
      @categories.each do |category|
        grouped_items = @grouped_data[category.id] || []
        category_total_budget = 0
        category_monthly_sales = Array.new(12, 0)
        category_total_sales = 0
        has_category_budget = false

        # 事業部ヘッダー行
        csv << [ "#{category.name}（#{category.code}）", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "" ]

        # グループごとの行
        grouped_items.each do |item|
          if item[:type] == :category
            category_total_budget = item[:budget_amount]
            has_category_budget = true
          elsif item[:type] == :group
            group_name = item[:group_name]
            budget_amount = item[:budget_amount]
            monthly_sales = item[:monthly_sales]
            total_sales = item[:total_sales]
            budget_balance = budget_amount - total_sales
            product_names = item[:products].map { |p| "#{p.name}（#{p.product_code}）" }.join("\u3001")

            category_total_budget += budget_amount unless has_category_budget
            category_total_sales += total_sales
            (1..12).each do |month|
              category_monthly_sales[month - 1] += monthly_sales[month - 1]
            end

            row = [
              (item[:group_code] || "-").to_s,
              "#{group_name}（#{product_names}）",
              budget_amount.to_s,
              monthly_sales[0].to_s,
              monthly_sales[1].to_s,
              monthly_sales[2].to_s,
              monthly_sales[3].to_s,
              monthly_sales[4].to_s,
              monthly_sales[5].to_s,
              monthly_sales[6].to_s,
              monthly_sales[7].to_s,
              monthly_sales[8].to_s,
              monthly_sales[9].to_s,
              monthly_sales[10].to_s,
              monthly_sales[11].to_s,
              total_sales.to_s,
              budget_balance.to_s
            ]
            csv << row
          end
        end

        # 事業部合計行
        category_budget_balance = category_total_budget - category_total_sales
        csv << [
          "",
          "合計",
          category_total_budget.to_s,
          category_monthly_sales[0].to_s,
          category_monthly_sales[1].to_s,
          category_monthly_sales[2].to_s,
          category_monthly_sales[3].to_s,
          category_monthly_sales[4].to_s,
          category_monthly_sales[5].to_s,
          category_monthly_sales[6].to_s,
          category_monthly_sales[7].to_s,
          category_monthly_sales[8].to_s,
          category_monthly_sales[9].to_s,
          category_monthly_sales[10].to_s,
          category_monthly_sales[11].to_s,
          category_total_sales.to_s,
          category_budget_balance.to_s
        ]
        csv << [] # 空行
      end

      # 総合計
      grand_total_budget = 0
      grand_monthly_sales = Array.new(12, 0)
      grand_total_sales = 0

      csv << [ "総合計", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "" ]

      @categories.each do |category|
        grouped_items = @grouped_data[category.id] || []
        category_total_budget = 0
        category_monthly_sales = Array.new(12, 0)
        category_total_sales = 0
        has_category_budget = false

        grouped_items.each do |item|
          if item[:type] == :category
            category_total_budget = item[:budget_amount]
            has_category_budget = true
            grand_total_budget += item[:budget_amount]
          elsif item[:type] == :group
            category_total_budget += item[:budget_amount] unless has_category_budget
            (1..12).each do |month|
              month_sales = item[:monthly_sales][month - 1] || 0
              category_monthly_sales[month - 1] += month_sales
              grand_monthly_sales[month - 1] += month_sales
            end
            category_total_sales += item[:total_sales]
          end
        end

        grand_total_budget += category_total_budget unless has_category_budget
        grand_total_sales += category_total_sales
        category_budget_balance = category_total_budget - category_total_sales

        # 事業部合計（総合計セクション内）
        csv << [
          "",
          "#{category.name}（#{category.code}）合計",
          category_total_budget.to_s,
          category_monthly_sales[0].to_s,
          category_monthly_sales[1].to_s,
          category_monthly_sales[2].to_s,
          category_monthly_sales[3].to_s,
          category_monthly_sales[4].to_s,
          category_monthly_sales[5].to_s,
          category_monthly_sales[6].to_s,
          category_monthly_sales[7].to_s,
          category_monthly_sales[8].to_s,
          category_monthly_sales[9].to_s,
          category_monthly_sales[10].to_s,
          category_monthly_sales[11].to_s,
          category_total_sales.to_s,
          category_budget_balance.to_s
        ]
      end

      grand_budget_balance = grand_total_budget - grand_total_sales
      csv << [
        "",
        "総合計",
        grand_total_budget.to_s,
        grand_monthly_sales[0].to_s,
        grand_monthly_sales[1].to_s,
        grand_monthly_sales[2].to_s,
        grand_monthly_sales[3].to_s,
        grand_monthly_sales[4].to_s,
        grand_monthly_sales[5].to_s,
        grand_monthly_sales[6].to_s,
        grand_monthly_sales[7].to_s,
        grand_monthly_sales[8].to_s,
        grand_monthly_sales[9].to_s,
        grand_monthly_sales[10].to_s,
        grand_monthly_sales[11].to_s,
        grand_total_sales.to_s,
        grand_budget_balance.to_s
      ]
    end

    # UTF-8 BOMを追加（Excelで文字化けしないように）
    bom = "\xEF\xBB\xBF"
    csv_with_bom = bom + csv_data

    # レスポンスを設定
    send_data csv_with_bom,
      filename: "売上集計_#{@fiscal_year}年度.csv",
      type: "text/csv; charset=utf-8",
      disposition: "attachment"
  end

  private

  def current_fiscal_year
    today = Date.today
    today.month >= 5 ? today.year : today.year - 1
  end

  def calculate_sales_data(start_date, end_date)
    # OrderItemから売上データを取得（税抜き金額）
    order_items = OrderItem.joins(:order, :product)
                           .where(orders: { order_date: start_date..end_date })
                           .where.not(products: { id: nil })

    # 商品ごと、月ごとに集計
    sales_by_product_month = {}

    order_items.each do |item|
      next unless item.product_id && item.order&.order_date

      product_id = item.product_id
      category_id = item.product.product_category_id
      order_date = item.order.order_date
      month = order_date.month

      # 年度の月番号に変換（5月=1, 6月=2, ..., 4月=12）
      fiscal_month = month >= 5 ? month - 4 : month + 8

      key = [ category_id, product_id ]
      sales_by_product_month[key] ||= {}
      sales_by_product_month[key][fiscal_month] ||= 0

      # subtotal_without_taxメソッドを使用（税抜き金額）
      amount = item.subtotal_without_tax || 0
      sales_by_product_month[key][fiscal_month] += amount
    end

    sales_by_product_month
  end

  def prepare_grouped_data
    # 事業部ごとに、集計グループごとに分類
    grouped_by_category = {}

    @categories.each do |category|
      grouped_items = []

      # 事業部全体の予算
      category_budget = @budgets[[ category.id, nil ]]
      if category_budget
        grouped_items << {
          type: :category,
          group_name: nil,
          budget_amount: category_budget.budget_amount,
          monthly_sales: Array.new(12, 0),
          total_sales: 0
        }
      end

      # 集計グループ設定からグループ名の一覧を取得
      group_names = @aggregation_groups
        .select { |key, _| key[0] == category.id }
        .map { |key, _| key[1] }
        .uniq
        .compact

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

      group_data_list.each do |group_data|
        group_name = group_data[:group_name]
        group_code = group_data[:group_code]

        # このグループに属する商品を取得
        group_products = @aggregation_groups[[ category.id, group_name ]] || []
        next if group_products.empty?

        # グループの予算を取得
        group_budget = @budgets[[ category.id, group_name ]]
        next unless group_budget # 予算が設定されているグループのみ表示

        monthly_sales = Array.new(12, 0)
        total_sales = 0

        # グループに属する商品の売上を集計
        group_products.each do |group|
          product = group.product
          (1..12).each do |month|
            sales_key = [ category.id, product.id ]
            month_sales = @sales_data[sales_key]&.dig(month) || 0
            monthly_sales[month - 1] += month_sales
            total_sales += month_sales
          end
        end

        grouped_items << {
          type: :group,
          group_name: group_name,
          group_code: group_code,
          products: group_products.map(&:product),
          budget_amount: group_budget.budget_amount,
          monthly_sales: monthly_sales,
          total_sales: total_sales
        }
      end

      grouped_by_category[category.id] = grouped_items
    end

    grouped_by_category
  end
end