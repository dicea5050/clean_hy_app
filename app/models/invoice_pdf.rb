require "prawn"
require "prawn/table"

class InvoicePdf < Prawn::Document
  def initialize(invoice, company_info)
    super(page_size: "A4", margin: 30)
    @invoice = invoice
    @company_info = company_info

    font_families.update("IPAGothic" => {
      normal: "#{Rails.root}/app/assets/fonts/ipaexg.ttf",
      bold: "#{Rails.root}/app/assets/fonts/ipaexg.ttf"
    })
    font "IPAGothic"

    header
    customer_info
    tax_summary
    bank_accounts
    order_details
    total_amount
    footer
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
    bounding_box([0, cursor], width: bounds.width / 2 - 10, height: 80) do
      text "#{@invoice.customer.company_name} 御中", size: 14, style: :bold
      move_down 5
      text "〒#{@invoice.customer.postal_code}", size: 10
      text @invoice.customer.address, size: 10
    end

    # 自社情報（右側配置）
    bounding_box([bounds.width / 2 + 10, cursor + 80], width: bounds.width / 2 - 10, height: 80) do
      # 社印の表示（company_sealが実装されている場合）
      begin
        if @company_info.respond_to?(:company_seal) &&
           @company_info.company_seal.present? &&
           @company_info.company_seal.attached?

          # Active Storageから画像ファイルを一時ファイルとして保存
          seal_path = Rails.root.join('tmp', "company_seal_#{@company_info.id}.png")

          File.open(seal_path, 'wb') do |file|
            file.write(@company_info.company_seal.download)
          end

          # 透過度を設定して画像を描画（右側に配置）
          image_width = 70  # 画像の幅（適宜調整）
          image_height = 70  # 画像の高さ（適宜調整）
          x_position = bounds.width - image_width - 5  # 右寄せ（マージン5pt）

          transparent(0.8) do  # 透明度を設定（0.2 = 20%の不透明度）
            image seal_path, at: [x_position, cursor - 5], width: image_width, height: image_height
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

  def bank_accounts
    text "【お振込先】", size: 12, style: :bold
    move_down 10

    # 銀行口座情報をテーブルで表示
    accounts = BankAccount.all

    if accounts.present?
      accounts_data = [["金融機関名", "支店名", "種別", "口座番号", "口座名義"]]

      accounts.each do |account|
        accounts_data << [
          account.bank_name,
          account.branch_name,
          account.account_type,
          account.account_number,
          account.account_holder
        ]
      end

      table accounts_data, width: bounds.width, cell_style: { size: 9, padding: [4, 4] } do
        row(0).font_style = :bold
        row(0).background_color = "EEEEEE"
      end
    else
      # 銀行口座情報がない場合のダミーデータまたはメッセージ
      text "銀行口座情報が登録されていません。", size: 10, style: :italic
    end

    move_down 3
    text "※お振込手数料はお客様負担でお願いいたします。", size: 8
    move_down 10
  end

  def order_details
    # 請求対象の受注一覧（統合テーブル）
    text "【請求明細】", size: 14, style: :bold
    move_down 10

    # 全ての受注と商品項目を1つの表にまとめる
    items_data = [["受注番号", "納品日", "商品名", "単価", "数量", "小計（税抜）", "税率", "小計（税込）"]]

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
          order.actual_delivery_date&.strftime("%Y年%m月%d日") || "未定",
          item.product.name,
          "¥#{number_with_delimiter(item.unit_price)}",
          item.quantity.to_s,
          "¥#{number_with_delimiter(item.subtotal_without_tax)}",
          "#{item.tax_rate}%",
          "¥#{number_with_delimiter(item.subtotal)}"
        ]
        items_data << row

        # 最初の商品以外は受注番号と納品日を空にして後でセル結合する
        if index > 0
          # 受注番号と納品日のカラムの位置を記録
          span_rows[items_data.size - 1] = { columns: [0, 1] }
        end
      end

      # 受注ごとに区切り線を入れる（最後の受注以外）
      unless order == @invoice.orders.last
        items_data << ["", "", "", "", "", "", "", ""]
        span_rows[items_data.size - 1] = { columns: (0..7).to_a, background: "EEEEEE" }
      end
    end

    # テーブルを描画
    table items_data, width: bounds.width, cell_style: { size: 8, padding: [3, 3] } do
      row(0).font_style = :bold
      row(0).background_color = "DDDDDD"
      columns(3..7).align = :right

      # 同一受注番号の商品行で受注番号と納品日のセルを結合
      span_rows.each do |row_index, options|
        if options[:columns].is_a?(Array)
          options[:columns].each do |col_index|
            if options[:background]
              # 区切り行の背景色設定
              row(row_index).background_color = options[:background]
              row(row_index).height = 5
            else
              # 前の行と結合して空セルにする
              cell = cells[row_index, col_index]
              cell.content = ""
            end
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

    # 税率別合計テーブルの表示
    text "【税率別請求金額】", size: 14, style: :bold
    move_down 10

    tax_summary_data = [
      ["区分", "税抜額", "消費税額", "請求金額（税込）"],
      ["標準税率対象（10.0%）", "¥#{number_with_delimiter(standard_tax_subtotal)}", "¥#{number_with_delimiter(standard_tax_amount)}", "¥#{number_with_delimiter(standard_tax_total)}"],
      ["非課税対象（0.0%）", "¥#{number_with_delimiter(tax_free_subtotal)}", "¥#{number_with_delimiter(tax_free_tax_amount)}", "¥#{number_with_delimiter(tax_free_total)}"]
    ]

    table tax_summary_data, width: bounds.width, cell_style: { size: 9, padding: [4, 4] } do
      row(0).font_style = :bold
      row(0).background_color = "DDDDDD"
      columns(1..3).align = :right
    end

    move_down 20
  end

  def total_amount
    # 合計金額
    total_without_tax = @invoice.total_amount_without_tax
    total_with_tax = @invoice.total_amount

    text_box "小計: ¥#{number_with_delimiter(total_without_tax)}", at: [ bounds.width - 150, cursor ], width: 150, align: :right
    move_down 15
    text_box "消費税: ¥#{number_with_delimiter(total_with_tax - total_without_tax)}", at: [ bounds.width - 150, cursor ], width: 150, align: :right
    move_down 15
    text_box "合計金額: ¥#{number_with_delimiter(total_with_tax)}", at: [ bounds.width - 150, cursor ], width: 150, align: :right, style: :bold

    move_down 30

    # 備考欄
    if @invoice.notes.present?
      text "【備考】", size: 12, style: :bold
      move_down 5
      text @invoice.notes, size: 10
    end
  end

  def footer
    # フッター
    move_down 20
    stroke_horizontal_rule
    move_down 10
    text "本請求書に関するお問い合わせは上記までご連絡ください。", align: :center, size: 10
    if @invoice.approval_status == "承認済み"
      text "この請求書は承認済みです。", align: :center, size: 10, style: :bold
    end
  end

  def number_with_delimiter(number)
    return "0" if number.nil?
    number.to_s.gsub(/(\d)(?=(\d{3})+(?!\d))/, '\1,')
  end
end
