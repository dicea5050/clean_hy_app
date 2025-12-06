module ApplicationHelper
  # 承認状態に応じたバッジのクラスを返す
  def approval_status_badge_class(approval_status)
    case approval_status
    when "承認待ち"
      "badge bg-warning"
    when "承認済み"
      "badge bg-success"
    when "差し戻し"
      "badge bg-danger"
    when "送付済み"
      "badge bg-primary"
    when "DL済み"
      "badge bg-primary"
    when "エラー"
      "badge bg-danger"
    else
      "badge bg-secondary"
    end
  end

  # 入金状況に応じたバッジのクラスを返す
  def payment_status_badge_class(payment_status)
    case payment_status
    when "未入金"
      "badge bg-danger"
    when "入金済"
      "badge bg-success"
    when "一部未入金"
      "badge bg-warning"
    else
      "badge bg-secondary"
    end
  end

  # 請求書送付方法に応じたバッジのクラスを返す
  def invoice_delivery_method_badge_class(customer)
    customer.electronic? ? "badge bg-info" : "badge bg-invoiced"
  end

  # 注文元に応じたバッジのクラスとテキストを返す
  def order_source_badge_class(is_shop_order)
    is_shop_order ? "badge bg-success" : "badge bg-secondary"
  end

  def order_source_badge_text(is_shop_order)
    is_shop_order ? "shop" : "自社"
  end

  # 請求書ステータスに応じたバッジのクラスとテキストを返す
  def invoice_status_badge_class(invoiced)
    invoiced ? "badge bg-success" : "badge bg-secondary"
  end

  def invoice_status_badge_text(invoiced)
    invoiced ? "発行済" : "未発行"
  end

  # パスワード設定状況に応じたバッジのクラスとテキストを返す
  def password_set_status_badge_class(password_set)
    password_set ? "badge bg-success" : "badge bg-warning"
  end

  def password_set_status_badge_text(password_set)
    password_set ? "パスワード設定済み" : "パスワード未設定"
  end

  # 納品先種別に応じたバッジのクラスとテキストを返す
  def delivery_location_type_badge_class(is_main_office)
    is_main_office ? "badge bg-primary" : "badge bg-secondary"
  end

  def delivery_location_type_badge_text(is_main_office)
    is_main_office ? "本社" : "支店"
  end

  # 有効/無効ステータスに応じたバッジのクラスとテキストを返す（汎用）
  def active_status_badge_class(is_active)
    is_active ? "badge bg-success" : "badge bg-danger"
  end

  def active_status_badge_text(is_active)
    is_active ? "有効" : "無効"
  end

  # 銀行口座の有効/無効状態に応じたバッジのクラスとテキストを返す
  def bank_account_status_badge_class(disabled)
    disabled ? "badge bg-secondary" : "badge bg-success"
  end

  def bank_account_status_badge_text(disabled)
    disabled ? "無効" : "有効"
  end
end
