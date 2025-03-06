require "prawn"
require "prawn/table"

class DeliverySlipPdf < Prawn::Document
  def initialize(order, company_info)
    super(page_size: "A4", margin: 50)
    @order = order
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
    text "納品書", size: 24, align: :center, style: :bold
    move_down 10

    # 発行日と納品日
    issue_date = Date.today
    delivery_date = @order.actual_delivery_date

    if delivery_date.present?
      text "納品日: #{delivery_date.strftime('%Y年%m月%d日')}", align: :right
    else
      text "納品日: 未定", align: :right
    end
    text "発行日: #{issue_date.strftime('%Y年%m月%d日')}", align: :right
    text "受注番号: #{@order.order_number}", align: :right
    move_down 20
  end

  def customer_info
    # 顧客情報
    text "#{@order.customer.company_name} 御中", size: 14, style: :bold
    move_down 5
    text "〒#{@order.customer.postal_code}", size: 10
    text @order.customer.address, size: 10
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
    # 注文明細
    text "【商品明細】", size: 14, style: :bold
    move_down 10

    order_items_data = [ [ "商品名", "単価", "数量", "税率", "小計（税抜）", "小計（税込）" ] ]

    @order.order_items.each do |item|
      order_items_data << [
        item.product.name,
        "¥#{number_with_delimiter(item.unit_price)}",
        item.quantity.to_s,
        "#{item.tax_rate}%",
        "¥#{number_with_delimiter(item.subtotal_without_tax)}",
        "¥#{number_with_delimiter(item.subtotal)}"
      ]
    end

    table order_items_data, width: bounds.width, cell_style: { size: 10, padding: [ 5, 5 ] } do
      row(0).font_style = :bold
      row(0).background_color = "DDDDDD"
      columns(1..5).align = :right
    end

    move_down 20
  end

  def total_amount
    # 合計金額
    total_without_tax = @order.order_items.sum { |item| item.subtotal_without_tax }
    total_with_tax = @order.order_items.sum { |item| item.subtotal }

    text_box "小計: ¥#{number_with_delimiter(total_without_tax)}", at: [ bounds.width - 150, cursor ], width: 150, align: :right
    move_down 15
    text_box "消費税: ¥#{number_with_delimiter(total_with_tax - total_without_tax)}", at: [ bounds.width - 150, cursor ], width: 150, align: :right
    move_down 15
    text_box "合計金額: ¥#{number_with_delimiter(total_with_tax)}", at: [ bounds.width - 150, cursor ], width: 150, align: :right, style: :bold

    move_down 30
  end

  def footer
    # フッター
    stroke_horizontal_rule
    move_down 10
    text "本納品書は、商品の納品を証明するものです。", align: :center, size: 10
    text "何かご不明な点がございましたら、お気軽にお問い合わせください。", align: :center, size: 10
  end

  def number_with_delimiter(number)
    return "0" if number.nil?
    number.to_s.gsub(/(\d)(?=(\d{3})+(?!\d))/, '\1,')
  end
end
