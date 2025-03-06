require "prawn"
require "prawn/table"

class InvoicePdf < Prawn::Document
  def initialize(invoice, company_info)
    super(page_size: "A4", margin: 50)
    @invoice = invoice
    @company_info = company_info

    font_families.update("IPAGothic" => {
      normal: "#{Rails.root}/app/assets/fonts/ipaexg.ttf",
      bold: "#{Rails.root}/app/assets/fonts/ipaexg.ttf"
    })
    font "IPAGothic"

    header
    customer_info
    order_details
    total_amount
    footer
  end

  def header
    # タイトル
    text "請求書", size: 24, align: :center, style: :bold
    move_down 10

    # 発行日と支払期限
    issue_date = @invoice.invoice_date
    due_date = @invoice.due_date

    text "請求日: #{issue_date.strftime('%Y年%m月%d日')}", align: :right
    if due_date.present?
      text "支払期限: #{due_date.strftime('%Y年%m月%d日')}", align: :right
    end
    text "請求書番号: #{@invoice.invoice_number}", align: :right
    move_down 20
  end

  def customer_info
    # 顧客情報
    text "#{@invoice.customer.company_name} 御中", size: 14, style: :bold
    move_down 5
    text "〒#{@invoice.customer.postal_code}", size: 10
    text @invoice.customer.address, size: 10
    move_down 20

    # 自社情報
    stroke_horizontal_rule
    move_down 10
    text "#{@company_info.name}", size: 12, style: :bold
    text "〒#{@company_info.postal_code}", size: 10
    text @company_info.address, size: 10
    text "TEL: #{@company_info.phone_number}", size: 10
    text "インボイス登録番号: #{@company_info.invoice_registration_number}", size: 10 if @company_info.invoice_registration_number.present?
    move_down 20
  end

  def order_details
    # 請求対象の受注一覧
    text "【請求対象】", size: 14, style: :bold
    move_down 10

    orders_data = [ [ "受注番号", "受注日", "納品日", "小計（税抜）", "小計（税込）" ] ]

    @invoice.orders.each do |order|
      orders_data << [
        order.order_number,
        order.order_date.strftime("%Y年%m月%d日"),
        order.actual_delivery_date&.strftime("%Y年%m月%d日") || "未定",
        "¥#{number_with_delimiter(order.order_items.sum { |item| item.subtotal_without_tax })}",
        "¥#{number_with_delimiter(order.order_items.sum { |item| item.subtotal })}"
      ]
    end

    table orders_data, width: bounds.width, cell_style: { size: 10, padding: [ 5, 5 ] } do
      row(0).font_style = :bold
      row(0).background_color = "DDDDDD"
      columns(3..4).align = :right
    end

    move_down 20

    # 各受注の明細
    @invoice.orders.each_with_index do |order, index|
      text "【受注詳細 #{index + 1}】 受注番号: #{order.order_number}", size: 12, style: :bold
      move_down 5

      items_data = [ [ "商品名", "単価", "数量", "税率", "小計（税抜）", "小計（税込）" ] ]

      order.order_items.each do |item|
        items_data << [
          item.product.name,
          "¥#{number_with_delimiter(item.unit_price)}",
          item.quantity.to_s,
          "#{item.tax_rate}%",
          "¥#{number_with_delimiter(item.subtotal_without_tax)}",
          "¥#{number_with_delimiter(item.subtotal)}"
        ]
      end

      table items_data, width: bounds.width, cell_style: { size: 9, padding: [ 4, 4 ] } do
        row(0).font_style = :bold
        row(0).background_color = "EEEEEE"
        columns(1..5).align = :right
      end

      move_down 15
    end
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
