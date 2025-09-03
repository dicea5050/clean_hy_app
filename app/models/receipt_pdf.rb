require "prawn"
require "prawn/table"

class ReceiptPdf < Prawn::Document
  def initialize(invoice, company_info, issue_date = nil)
    super(page_size: "A4", margin: 30)
    @invoice = invoice
    @company_info = company_info
    @issue_date = issue_date || Date.current

    font_families.update("IPAGothic" => {
      normal: "#{Rails.root}/app/assets/fonts/ipaexg.ttf",
      bold: "#{Rails.root}/app/assets/fonts/ipaexg.ttf"
    })
    font "IPAGothic"

    # お客様お渡し用
    receipt_section("お客様お渡し用")
    
    # 点線区切り
    dotted_line
    
    # 自社控え用
    receipt_section("自社控え")
  end

  private

  def receipt_section(section_title)
    # セクションタイトル
    text section_title, size: 10, align: :right
    move_down 10

    # 領収書タイトル
    text "領収書", size: 24, align: :center, style: :bold
    move_down 20

    # 顧客情報と金額を左右に配置
    bounding_box([0, cursor], width: bounds.width, height: 100) do
      # 左側：顧客情報
      bounding_box([0, cursor], width: bounds.width * 0.6, height: 100) do
        text "#{@invoice.customer.company_name} 様", size: 14, style: :bold
        move_down 5
        if @invoice.customer.customer_code.present?
          text "顧客コード: #{@invoice.customer.customer_code}", size: 10
        end
      end

      # 右側：金額
      bounding_box([bounds.width * 0.6, cursor + 100], width: bounds.width * 0.4, height: 100) do
        stroke_bounds
        move_down 10
        text "金額", size: 12, align: :center, style: :bold
        move_down 5
        text "¥ #{number_with_delimiter(@invoice.total_amount)}", 
             size: 18, align: :center, style: :bold
        text "（税込）", size: 10, align: :center
      end
    end

    move_down 20

    # 但書
    text "但し", size: 12, style: :bold
    move_down 5
    
    # 但書欄（手書き用の空欄）
    stroke do
      horizontal_line 0, bounds.width * 0.8, at: cursor - 5
    end
    move_down 15
    stroke do
      horizontal_line 0, bounds.width * 0.8, at: cursor - 5
    end
    move_down 20

    # 発行日と会社情報を左右に配置
    bounding_box([0, cursor], width: bounds.width, height: 80) do
      # 左側：発行日
      bounding_box([0, cursor], width: bounds.width * 0.5, height: 80) do
        text "発行日: #{@issue_date.strftime('%Y年%m月%d日')}", size: 12
      end

      # 右側：会社情報
      bounding_box([bounds.width * 0.5, cursor + 80], width: bounds.width * 0.5, height: 80) do
        text @company_info.name, size: 12, style: :bold, align: :right
        move_down 3
        text "〒#{@company_info.postal_code}", size: 10, align: :right
        text @company_info.address, size: 10, align: :right
        text "TEL: #{@company_info.phone_number}", size: 10, align: :right
        if @company_info.invoice_registration_number.present?
          text "登録番号: #{@company_info.invoice_registration_number}", size: 9, align: :right
        end
      end
    end

    move_down 30
  end

  def dotted_line
    # 点線を描画
    stroke_color "999999"
    dash(3, space: 3)
    stroke do
      horizontal_line 0, bounds.width, at: cursor - 10
    end
    undash
    stroke_color "000000"
    move_down 20
  end

  def number_with_delimiter(number)
    return "0" if number.nil?
    number.to_s.gsub(/(\d)(?=(\d{3})+(?!\d))/, '\1,')
  end
end
