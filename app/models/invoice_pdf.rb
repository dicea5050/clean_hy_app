require "prawn"
require "prawn/table"

class InvoicePdf < Prawn::Document
  def initialize(invoice, company_info, reissue: false)
    super(page_size: "A4", margin: 30)
    @invoice = invoice
    @company_info = company_info
    @reissue = reissue

    font_families.update("IPAGothic" => {
      normal: "#{Rails.root}/app/assets/fonts/ipaexg.ttf",
      bold: "#{Rails.root}/app/assets/fonts/ipaexg.ttf"
    })
    font "IPAGothic"

    header
    customer_info
    summary_table
    order_details
    bank_accounts_and_tax_summary
    notes
  end

  def header
    # 発行日と支払期限
    issue_date = @invoice.invoice_date
    due_date = @invoice.due_date

    text "請求書番号: #{@invoice.invoice_number}", size: 10, align: :right
    text "請求日: #{issue_date.strftime('%Y年%m月%d日')}", size: 10, align: :right
    if due_date.present?
      text "支払期限: #{due_date.strftime('%Y年%m月%d日')}", size: 10, align: :right
    end
    move_down 20

    # タイトル
    text "請求書", size: 24, align: :center, style: :bold
    move_down 10
  end

  def customer_info
    # 顧客情報と自社情報を並べて表示するため、bounding_boxを使用

    # 顧客情報（左側配置）
    bounding_box([ 0, cursor ], width: bounds.width / 2 - 10, height: 80) do
      text "#{@invoice.customer.company_name} 御中", size: 14, style: :bold
      move_down 5
      text "〒#{@invoice.customer.postal_code}", size: 10
      text @invoice.customer.address, size: 10
    end

    # 自社情報（右側配置）
    bounding_box([ bounds.width / 2 + 10, cursor + 80 ], width: bounds.width / 2 - 10, height: 80) do
      # 社印の表示（company_sealが実装されている場合）
      begin
        if @company_info.respond_to?(:company_seal) &&
           @company_info.company_seal.present? &&
           @company_info.company_seal.attached?

          # Active Storageから画像ファイルを一時ファイルとして保存
          seal_path = Rails.root.join("tmp", "company_seal_#{@company_info.id}.png")

          File.open(seal_path, "wb") do |file|
            file.write(@company_info.company_seal.download)
          end

          # 透過度を設定して画像を描画（右側に配置）
          image_width = 70  # 画像の幅（適宜調整）
          image_height = 70  # 画像の高さ（適宜調整）
          x_position = bounds.width - image_width - 5  # 右寄せ（マージン5pt）

          transparent(0.8) do  # 透明度を設定（0.2 = 20%の不透明度）
            image seal_path, at: [ x_position, cursor - 5 ], width: image_width, height: image_height
          end

          # 一時ファイルを削除
          File.delete(seal_path) if File.exist?(seal_path)
        end
      rescue => e
        # エラーをログに記録するだけで、PDFの生成は継続する
        Rails.logger.error "社印の表示中にエラーが発生しました: #{e.message}"
      end

      # テキスト情報（変更なし）
      text "#{@company_info.name}", size: 12, style: :bold, align: :right
      move_down 5
      text "〒#{@company_info.postal_code}", size: 10, align: :right
      text @company_info.address, size: 10, align: :right
      text "TEL: #{@company_info.phone_number}", size: 10, align: :right
      if @company_info.invoice_registration_number.present?
        text "インボイス登録番号: #{@company_info.invoice_registration_number}", size: 10, align: :right
      end
    end

    # カーソルを適切な位置に移動
    move_down 1

    # 区切り線
    stroke_horizontal_rule
    move_down 10
  end

  def summary_table
    # 繰越金額、小計（税抜）、消費税、請求合計額（税込）の表
    total_without_tax = @invoice.total_amount_without_tax
    total_with_tax = @invoice.total_amount
    tax_amount = total_with_tax - total_without_tax
    carryover_amount = Invoice.carryover_amount_for_customer(@invoice.customer_id, exclude_invoice_id: @invoice.id)
    total_request_amount = total_with_tax + carryover_amount

    summary_data = [
      [ "繰越金額", "請求額（税抜）", "消費税", "請求合計額（税込）" ],
      [
        "¥#{number_with_delimiter(carryover_amount)}",
        "¥#{number_with_delimiter(total_without_tax)}",
        "¥#{number_with_delimiter(tax_amount)}",
        "¥#{number_with_delimiter(total_request_amount)}"
      ]
    ]

    table summary_data, width: bounds.width, cell_style: { size: 10, padding: [ 5, 5 ] } do
      row(0).font_style = :bold
      row(0).background_color = "DDDDDD"
      columns(0..3).align = :right
    end

    move_down 20
  end

  def bank_accounts(include_title: false)
    # 銀行口座情報をカラムを半角スペースで詰めて表示
    # 初回発行時は有効口座のみ、再発行時は全口座を表示
    accounts = if @reissue
                 BankAccount.all
    else
                 BankAccount.where(disabled: false)
    end

    if accounts.present?
      accounts.each do |account|
        account_text = "#{account.bank_name} #{account.branch_name} #{account.account_type} #{account.account_number} #{account.account_holder}"
        text account_text, size: 9
      end
    else
      # 銀行口座情報がない場合のメッセージ
      text "銀行口座情報が登録されていません。", size: 10, style: :italic
    end

    move_down 3
    text "※お振込手数料はお客様負担でお願いいたします。", size: 8
  end

  def order_details
    # 請求対象の受注一覧（統合テーブル）
    text "【請求明細】", size: 14, style: :bold
    move_down 10

    # 全ての受注と商品項目を1つの表にまとめる（納品日を削除）
    items_data = [ [ "受注番号", "商品名", "単価", "数量", "小計（税抜）", "税率", "小計（税込）" ] ]

    last_order_id = nil
    row_count = 0
    span_rows = {}

    @invoice.orders.each do |order|
      # 受注ごとの最初の行と最後の行をトラッキング
      first_item_row = items_data.size
      items_count = order.order_items.size

      order.order_items.each_with_index do |item, index|
        row = [
          order.order_number,
          item.display_product_name,
          "¥#{number_with_delimiter(item.unit_price)}",
          item.quantity.to_s,
          "¥#{number_with_delimiter(item.subtotal_without_tax)}",
          "#{item.tax_rate}%",
          "¥#{number_with_delimiter(item.subtotal)}"
        ]
        items_data << row

        # 最初の商品以外は受注番号を空にして後でセル結合する
        if index > 0
          # 受注番号のカラムの位置を記録
          span_rows[items_data.size - 1] = { columns: [ 0 ] }
        end
      end
    end

    # テーブルを描画（文字サイズを大きく）
    table items_data, width: bounds.width, cell_style: { size: 10, padding: [ 4, 4 ] } do
      row(0).font_style = :bold
      row(0).background_color = "DDDDDD"
      columns(2..6).align = :right

      # 同一受注番号の商品行で受注番号のセルを結合
      span_rows.each do |row_index, options|
        if options[:columns].is_a?(Array)
          options[:columns].each do |col_index|
            # 前の行と結合して空セルにする
            cell = cells[row_index, col_index]
            cell.content = ""
          end
        end
      end
    end

    move_down 20
  end

  def tax_summary
    # 税率別の合計額を計算
    standard_tax_rate_items = [] # 標準税率10.0%
    tax_free_items = []         # 非課税0.0%

    @invoice.orders.each do |order|
      order.order_items.each do |item|
        if item.tax_rate == 10.0
          standard_tax_rate_items << item
        elsif item.tax_rate == 0.0
          tax_free_items << item
        end
      end
    end

    # 標準税率対象（10.0%）の合計
    standard_tax_subtotal = standard_tax_rate_items.sum(&:subtotal_without_tax)
    standard_tax_amount = standard_tax_rate_items.sum { |item| item.subtotal - item.subtotal_without_tax }
    standard_tax_total = standard_tax_rate_items.sum(&:subtotal)

    # 非課税対象（0.0%）の合計
    tax_free_subtotal = tax_free_items.sum(&:subtotal_without_tax)
    tax_free_tax_amount = 0 # 非課税なので消費税は0
    tax_free_total = tax_free_items.sum(&:subtotal)

    # 税率別合計テーブルの表示（幅を広げて改行を防ぐ）
    tax_summary_data = [
      [ "区分", "税抜額", "消費税額", "請求金額（税込）" ],
      [ "標準税率対象（10.0%）", "¥#{number_with_delimiter(standard_tax_subtotal)}", "¥#{number_with_delimiter(standard_tax_amount)}", "¥#{number_with_delimiter(standard_tax_total)}" ],
      [ "非課税対象（0.0%）", "¥#{number_with_delimiter(tax_free_subtotal)}", "¥#{number_with_delimiter(tax_free_tax_amount)}", "¥#{number_with_delimiter(tax_free_total)}" ]
    ]

    # カラム幅を指定して改行を防ぐ（区分カラムを広げる）
    column_widths = [ bounds.width * 0.45, bounds.width * 0.18, bounds.width * 0.18, bounds.width * 0.19 ]
    table tax_summary_data, width: bounds.width, cell_style: { size: 9, padding: [ 4, 4 ] }, column_widths: column_widths do
      row(0).font_style = :bold
      row(0).background_color = "DDDDDD"
      columns(1..3).align = :right
      # 区分カラムのテキストを改行しないように設定
      columns(0).overflow = :shrink_to_fit
    end
  end

  def bank_accounts_and_tax_summary
    # 左側にお振込先、右側で税率別請求金額を並べて表示
    current_y = cursor
    bank_accounts_height = 0
    tax_summary_height = 0

    # 左側：お振込先
    bounding_box([ 0, current_y ], width: bounds.width / 2 - 10) do
      text "【お振込先】", size: 12, style: :bold
      move_down 10
      start_y = cursor
      bank_accounts
      bank_accounts_height = start_y - cursor
    end

    # 右側：税率別請求金額
    bounding_box([ bounds.width / 2 + 10, current_y ], width: bounds.width / 2 - 10) do
      text "【税率別請求金額】", size: 12, style: :bold
      move_down 10
      start_y = cursor
      # 税率別請求金額テーブルを表示
      tax_summary
      tax_summary_height = start_y - cursor
    end

    # カーソルを適切な位置に移動（より高い方の高さを使用）
    max_height = [ bank_accounts_height, tax_summary_height ].max
    move_to(0, current_y - max_height - 20)
  end

  def tax_summary_right_aligned
    # 税率別の合計額を計算
    standard_tax_rate_items = [] # 標準税率10.0%
    tax_free_items = []         # 非課税0.0%

    @invoice.orders.each do |order|
      order.order_items.each do |item|
        if item.tax_rate == 10.0
          standard_tax_rate_items << item
        elsif item.tax_rate == 0.0
          tax_free_items << item
        end
      end
    end

    # 標準税率対象（10.0%）の合計
    standard_tax_subtotal = standard_tax_rate_items.sum(&:subtotal_without_tax)
    standard_tax_amount = standard_tax_rate_items.sum { |item| item.subtotal - item.subtotal_without_tax }
    standard_tax_total = standard_tax_rate_items.sum(&:subtotal)

    # 非課税対象（0.0%）の合計
    tax_free_subtotal = tax_free_items.sum(&:subtotal_without_tax)
    tax_free_tax_amount = 0 # 非課税なので消費税は0
    tax_free_total = tax_free_items.sum(&:subtotal)

    # 税率別合計テーブルの表示（幅を狭く、右揃え）
    tax_summary_data = [
      [ "区分", "税抜額", "消費税額", "請求金額（税込）" ],
      [ "標準税率対象（10.0%）", "¥#{number_with_delimiter(standard_tax_subtotal)}", "¥#{number_with_delimiter(standard_tax_amount)}", "¥#{number_with_delimiter(standard_tax_total)}" ],
      [ "非課税対象（0.0%）", "¥#{number_with_delimiter(tax_free_subtotal)}", "¥#{number_with_delimiter(tax_free_tax_amount)}", "¥#{number_with_delimiter(tax_free_total)}" ]
    ]

    # テーブル幅を狭く設定（約90%の幅）
    table_width = bounds.width * 0.9
    # 右側に配置するためのx位置を計算
    table_x = bounds.width - table_width
    current_y = cursor

    # 右側に移動してからテーブルを描画
    move_to(table_x, current_y)
    table tax_summary_data, width: table_width, cell_style: { size: 9, padding: [ 4, 4 ] } do
      row(0).font_style = :bold
      row(0).background_color = "DDDDDD"
      columns(1..3).align = :right
    end
  end

  def notes
    # 備考欄
    if @invoice.notes.present?
      move_down 20
      text "【備考】", size: 12, style: :bold
      move_down 5
      text @invoice.notes, size: 10
    end
  end

  def number_with_delimiter(number)
    return "0" if number.nil?
    number.to_s.gsub(/(\d)(?=(\d{3})+(?!\d))/, '\1,')
  end
end
