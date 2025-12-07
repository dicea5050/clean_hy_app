require "prawn"
require "prawn/table"

class SalesReportPdf < Prawn::Document
  def initialize(fiscal_year, categories, grouped_data)
    super(page_size: "A4", margin: 30, page_layout: :landscape, embed_fonts: true)
    @fiscal_year = fiscal_year
    @categories = categories
    @grouped_data = grouped_data

    font_path = Rails.root.join("app", "assets", "fonts", "ipaexg.ttf")
    if File.exist?(font_path)
      # フォントを完全に埋め込むために、subset: falseを指定
      font_families.update("IPAGothic" => {
        normal: { file: font_path.to_s, subset: false },
        bold: { file: font_path.to_s, subset: false }
      })
      font "IPAGothic"
    else
      Rails.logger.warn "フォントファイルが見つかりません: #{font_path}"
      font "Helvetica"
    end

    header
    sales_table
  end

  def header
    text "売上集計", size: 18, align: :center, style: :bold
    text "#{@fiscal_year}年度", size: 14, align: :center
    move_down 10
  end

  def sales_table
    # テーブルデータを準備
    table_data = []

    # ヘッダー行1
    header_row1 = [ "No.", "商品名", "予算" ]
    (1..12).each do |month|
      month_name = case month
      when 1 then "5月"
      when 2 then "6月"
      when 3 then "7月"
      when 4 then "8月"
      when 5 then "9月"
      when 6 then "10月"
      when 7 then "11月"
      when 8 then "12月"
      when 9 then "1月"
      when 10 then "2月"
      when 11 then "3月"
      when 12 then "4月"
      end
      header_row1 << month_name
    end
    header_row1 << "小計"
    header_row1 << "予算残高"
    table_data << header_row1

    # データ行
    @categories.each do |category|
      grouped_items = @grouped_data[category.id] || []
      category_total_budget = 0
      category_monthly_sales = Array.new(12, 0)
      category_total_sales = 0
      has_category_budget = false

      # 事業部ヘッダー行（1列目を空にして、2列目に事業部名を配置、3列目以降を空にする）
      category_header = [ "" ]
      category_header << "#{category.name}（#{category.code}）"
      (1..15).each { category_header << "" }
      table_data << category_header

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

          row = [ (item[:group_code] || "-").to_s, "#{group_name}（#{product_names}）", number_with_delimiter(budget_amount) ]
          (1..12).each do |month|
            row << number_with_delimiter(monthly_sales[month - 1])
          end
          row << number_with_delimiter(total_sales)
          row << number_with_delimiter(budget_balance)
          table_data << row
        end
      end

      # 事業部合計行
      category_budget_balance = category_total_budget - category_total_sales
      total_row = [ "", "合計", number_with_delimiter(category_total_budget) ]
      (1..12).each do |month|
        total_row << number_with_delimiter(category_monthly_sales[month - 1])
      end
      total_row << number_with_delimiter(category_total_sales)
      total_row << number_with_delimiter(category_budget_balance)
      table_data << total_row

      # 空行
      empty_row = []
      (1..17).each { empty_row << "" }
      table_data << empty_row
    end

    # 総合計
    grand_total_budget = 0
    grand_monthly_sales = Array.new(12, 0)
    grand_total_sales = 0

    table_data << [ "", "総合計", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "" ]

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
      category_total_row = [ "", "#{category.name}（#{category.code}）合計", number_with_delimiter(category_total_budget) ]
      (1..12).each do |month|
        category_total_row << number_with_delimiter(category_monthly_sales[month - 1])
      end
      category_total_row << number_with_delimiter(category_total_sales)
      category_total_row << number_with_delimiter(category_budget_balance)
      table_data << category_total_row
    end

    grand_budget_balance = grand_total_budget - grand_total_sales
    grand_total_row = [ "", "総合計", number_with_delimiter(grand_total_budget) ]
    (1..12).each do |month|
      grand_total_row << number_with_delimiter(grand_monthly_sales[month - 1])
    end
    grand_total_row << number_with_delimiter(grand_total_sales)
    grand_total_row << number_with_delimiter(grand_budget_balance)
    table_data << grand_total_row

    # 列幅を計算（1列目（No./事業部名）を25ポイント、2列目（商品名）を広く、残りを均等に）
    # 事業部名が長い場合でも折り返さずに表示できるように、1列目の幅を広げることも検討可能
    total_width = bounds.width
    first_column_width = 25  # 1列目の幅を25ポイントに設定（No.カラム用、事業部名ははみ出してもOK）
    product_name_width = 150  # 商品名カラムの幅を150ポイントに設定
    remaining_width = total_width - first_column_width - product_name_width
    other_columns_count = 15  # 1列目と2列目以外のカラム数
    other_column_width = remaining_width / other_columns_count

    column_widths = [ first_column_width, product_name_width ] + ([ other_column_width ] * other_columns_count)

    # テーブルを描画
    table table_data, width: bounds.width, column_widths: column_widths, cell_style: { size: 7, padding: [ 3, 3 ] } do
      # ヘッダー行のスタイル
      row(0).font_style = :bold
      row(0).background_color = "DDDDDD"
      columns(2..16).align = :right

      # 各行のスタイルを設定
      table_data.each_with_index do |row, index|
        next if index == 0 # ヘッダー行は既に設定済み

        # 事業部ヘッダー行のスタイル（2列目に事業部名がある）
        if row[0].blank? && row[1] && row[1].include?("（") && row[1].include?("）") && row[2].blank?
          row(index).font_style = :bold
          row(index).background_color = "E6F3FF"
          # 3列目以降のセルの左右の境界線を消して結合したように見せる（ただし、一番右の外枠は残す）
          (3..15).each do |col|
            cell = cells[index, col]
            if cell
              # 上下の境界線だけを残し、左右の境界線を消す
              cell.borders = [ :top, :bottom ]
            end
          end
          # 1列目のセルの右の境界線を消す
          cell_0 = cells[index, 0]
          if cell_0
            cell_0.borders = [ :top, :bottom, :left ]
          end
          # 2列目のセル（事業部名）の左右の境界線を消し、テキストを折り返さずに1行で表示（隣のセルにはみ出してもOK）
          cell_1 = cells[index, 1]
          if cell_1
            cell_1.borders = [ :top, :bottom ]
            # テキストを折り返さないようにする（overflowオプションは削除）
            # Prawnのテーブルでは、セル幅を超えるテキストは自動的に折り返されるため、
            # はみ出して表示するには、列幅の設定を変更する必要がある
            # ただし、列幅はテーブル全体で統一されているため、個別の行で変更することはできない
            # そのため、事業部名が長い場合は折り返されるが、境界線を消すことで結合したように見せる
          end
          # 3列目のセルの左の境界線を消す
          cell_2 = cells[index, 2]
          if cell_2
            cell_2.borders = [ :top, :bottom ]
          end
          # 一番右のセル（16列目）の右の境界線を残す（外枠を保持）
          cell_16 = cells[index, 16]
          if cell_16
            cell_16.borders = [ :top, :bottom, :right ]
          end
        end

        # 合計行のスタイル
        if row[1] == "合計"
          row(index).font_style = :bold
          row(index).background_color = "F0F0F0"
        end
        # 事業部合計行（総合計セクション内）のスタイル（2列目に「合計」が含まれている行）
        if row[1] && row[1].include?("合計") && row[1] != "総合計" && row[1] != "合計"
          row(index).font_style = :bold
          row(index).background_color = "F0F0F0"
        end
        # 総合計行のスタイル（2列目に「総合計」がある行）
        if row[0].blank? && row[1] == "総合計" && row[2].blank?
          row(index).font_style = :bold
          row(index).background_color = "FFFF99"  # 黄色系の背景色
        end
        # 総合計のデータ行のスタイル（2列目に「総合計」がある行）
        if row[1] == "総合計"
          row(index).font_style = :bold
          row(index).background_color = "FFFF99"  # 黄色系の背景色
        end

        # 数値列を右揃え
        columns(2..16).align = :right
      end
    end
  end

  def number_with_delimiter(number)
    return "0" if number.nil? || number == 0
    number.to_i.to_s.gsub(/(\d)(?=(\d{3})+(?!\d))/, '\1,')
  end
end
