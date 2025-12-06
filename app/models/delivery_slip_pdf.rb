require "prawn"
require "prawn/table"

class DeliverySlipPdf < Prawn::Document
  def initialize(order, company_info)
    super(page_size: "A4", margin: 50, embed_fonts: true)
    @order = order
    @company_info = company_info

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

    # ページを上下に分割して同じ内容を表示
    # 上半分：お客様用
    draw_content(is_top_half: true)

    # 中央に区切り線
    stroke_horizontal_line 0, bounds.width, at: bounds.height / 2

    # 下半分：自社控え
    draw_content(is_top_half: false)
  end

  def draw_content(is_top_half:)
    # 上半分または下半分の開始位置を設定
    if is_top_half
      # 上半分：通常の位置から開始（マージンを考慮）
      start_y = bounds.height
    else
      # 下半分：ページ中央から少し下に開始（マージンを考慮）
      start_y = bounds.height / 2 - 30
    end

    # 開始位置に移動
    move_cursor_to start_y

    header(is_top_half: is_top_half)
    customer_info(is_top_half: is_top_half)
    order_details(is_top_half: is_top_half)
    total_amount(is_top_half: is_top_half)
    receipt_stamp(is_top_half: is_top_half) unless is_top_half
  end

  def header(is_top_half:)
    # 発行日と納品日
    issue_date = Date.today
    delivery_date = @order.actual_delivery_date

    font_size(is_top_half ? 8 : 7) do
      text "発行日: #{issue_date.strftime('%Y年%m月%d日')}", align: :right
      if delivery_date.present?
        text "納品日: #{delivery_date.strftime('%Y年%m月%d日')}", align: :right
      else
        text "納品日: 未定", align: :right
      end
      text "受注番号: #{@order.order_number}", align: :right
    end
    move_down(is_top_half ? 8 : 6)

    # タイトル
    title_text = is_top_half ? "納品書" : "納品書（控）"
    text title_text, size: (is_top_half ? 18 : 14), align: :center, style: :bold
    move_down(is_top_half ? 15 : 10)
  end

  def customer_info(is_top_half:)
    # 現在のカーソル位置を保存
    start_y = cursor

    # 左側：顧客情報と納品先情報
    left_width = bounds.width * 0.5

    # 左側の行数を計算
    left_lines = 1 # 顧客名
    left_lines += 1 # 空行
    if @order.delivery_location.present?
      left_lines += 1 # 【納品先】
      left_lines += 1 # 名前
      left_lines += 1 # 郵便番号
      left_lines += 1 # 住所
      left_lines += 1 if @order.delivery_location.phone.present? # TEL
      left_lines += 1 if @order.delivery_location.contact_person.present? # 担当
    else
      left_lines += 1 # 郵便番号
      left_lines += 1 # 住所
    end

    # 右側の行数を計算
    right_lines = 1 # 郵便番号
    right_lines += 1 # 住所
    right_lines += 1 # 会社名
    right_lines += 1 if @company_info.representative_name.present? # 代表取締役
    right_lines += 1 # TEL
    right_lines += 1 if @company_info.invoice_registration_number.present? # インボイス登録番号

    # フォントサイズと行間から高さを計算
    font_size = is_top_half ? 9 : 7
    line_height = font_size * 1.2
    left_height = left_lines * line_height + (is_top_half ? 20 : 15)
    right_height = right_lines * line_height + (is_top_half ? 20 : 15)
    max_height = [ left_height, right_height ].max

    # 左側を描画
    bounding_box([ 0, start_y ], width: left_width) do
      text "#{@order.customer.company_name} 御中", size: (is_top_half ? 12 : 9), style: :bold
      move_down(is_top_half ? 4 : 3)

      if @order.delivery_location.present?
        text "【納品先】", size: (is_top_half ? 9 : 7), style: :bold
        text "#{@order.delivery_location.name}", size: (is_top_half ? 9 : 7)
        text "〒#{@order.delivery_location.postal_code}", size: (is_top_half ? 9 : 7)
        text @order.delivery_location.address, size: (is_top_half ? 9 : 7)
        text "TEL: #{@order.delivery_location.phone}", size: (is_top_half ? 9 : 7) if @order.delivery_location.phone.present?
        text "担当: #{@order.delivery_location.contact_person}", size: (is_top_half ? 9 : 7) if @order.delivery_location.contact_person.present?
      else
        text "〒#{@order.customer.postal_code}", size: (is_top_half ? 9 : 7)
        text @order.customer.address, size: (is_top_half ? 9 : 7)
      end
    end

    # 右側：自社情報（納品先情報と同じ高さに配置）
    right_width = bounds.width * 0.5
    right_x = bounds.width * 0.5

    bounding_box([ right_x, start_y ], width: right_width) do
      text "〒#{@company_info.postal_code}", size: (is_top_half ? 9 : 7), align: :right
      text @company_info.address, size: (is_top_half ? 9 : 7), align: :right
      text "#{@company_info.name}", size: (is_top_half ? 11 : 8), style: :bold, align: :right
      text "代表取締役 #{@company_info.representative_name}", size: (is_top_half ? 9 : 7), align: :right if @company_info.representative_name.present?
      text "TEL: #{@company_info.phone_number}", size: (is_top_half ? 9 : 7), align: :right
      text "インボイス登録番号: #{@company_info.invoice_registration_number}", size: (is_top_half ? 9 : 7), align: :right if @company_info.invoice_registration_number.present?
    end

    # カーソル位置を適切に調整（左右のうち高い方に合わせる）
    move_cursor_to(start_y - max_height)
    move_down(is_top_half ? 15 : 10)
  end

  def order_details(is_top_half:)
    # フッターメッセージ（商品明細の上に移動）
    text "下記の通り、納品いたしました。", align: :center, size: (is_top_half ? 9 : 7)
    text "何かご不明な点がございましたら、お気軽にお問い合わせください。", align: :center, size: (is_top_half ? 9 : 7)
    move_down(is_top_half ? 15 : 10)

    # 注文明細
    text "【商品明細】", size: (is_top_half ? 12 : 9), style: :bold
    move_down(is_top_half ? 8 : 6)

    order_items_data = [ [ "商品名", "単価", "数量", "税率", "小計（税抜）", "小計（税込）" ] ]

    @order.order_items.each do |item|
      order_items_data << [
        item.display_product_name,
        "¥#{number_with_delimiter(item.unit_price)}",
        item.quantity.to_s,
        "#{item.tax_rate}%",
        "¥#{number_with_delimiter(item.subtotal_without_tax)}",
        "¥#{number_with_delimiter(item.subtotal)}"
      ]
    end

    table order_items_data, width: bounds.width, cell_style: { size: (is_top_half ? 8 : 6), padding: [ (is_top_half ? 4 : 3), (is_top_half ? 4 : 3) ] } do
      row(0).font_style = :bold
      row(0).background_color = "DDDDDD"
      columns(1..5).align = :right
    end

    move_down(is_top_half ? 15 : 10)
  end

  def total_amount(is_top_half:)
    # 合計金額
    total_without_tax = @order.order_items.sum { |item| item.subtotal_without_tax }
    total_with_tax = @order.order_items.sum { |item| item.subtotal }

    text_size = is_top_half ? 9 : 7
    box_width = is_top_half ? 150 : 120
    right_margin = is_top_half ? 0 : -15

    text_box "小計: ¥#{number_with_delimiter(total_without_tax)}", at: [ bounds.width - box_width + right_margin, cursor ], width: box_width, align: :right, size: text_size
    move_down(is_top_half ? 12 : 8)
    text_box "消費税: ¥#{number_with_delimiter(total_with_tax - total_without_tax)}", at: [ bounds.width - box_width + right_margin, cursor ], width: box_width, align: :right, size: text_size
    move_down(is_top_half ? 12 : 8)
    text_box "合計金額: ¥#{number_with_delimiter(total_with_tax)}", at: [ bounds.width - box_width + right_margin, cursor ], width: box_width, align: :right, style: :bold, size: text_size

    move_down(is_top_half ? 20 : 15)
  end

  def receipt_stamp(is_top_half:)
    # 受領印欄（控え側のみ）
    move_down(15)

    # 受領印欄の枠を描画
    stamp_width = 120
    stamp_height = 60
    stamp_x = bounds.width - stamp_width - 50
    stamp_y = cursor

    # 枠線
    stroke_rectangle [ stamp_x, stamp_y ], stamp_width, stamp_height

    # 「受領印」のテキスト
    text_box "受領印",
             at: [ stamp_x, stamp_y - 5 ],
             width: stamp_width,
             height: 15,
             size: 7,
             align: :center,
             valign: :top

    # 日付欄
    text_box "年    月    日",
             at: [ stamp_x, stamp_y - 20 ],
             width: stamp_width,
             height: 15,
             size: 6,
             align: :center,
             valign: :top

    move_down(15)
  end

  def number_with_delimiter(number)
    return "0" if number.nil?
    number.to_s.gsub(/(\d)(?=(\d{3})+(?!\d))/, '\1,')
  end
end
