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
    is_main_office ? "基本" : "追加"
  end

  # 納品先名を表示用に変換（（本社）を（基本）に置き換え）
  def delivery_location_display_name(name)
    name.to_s.gsub("\uFF08\u672C\u793E\uFF09", "\uFF08\u57FA\u672C\uFF09")
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

  # ソート可能なカラムヘッダーを生成するヘルパーメソッド
  def sortable_column(title, column, current_sort, current_direction, params_hash)
    # 現在のソートカラムと一致する場合、方向を切り替える
    if current_sort == column
      new_direction = current_direction == "asc" ? "desc" : "asc"
      icon_class = current_direction == "asc" ? "bi-arrow-up" : "bi-arrow-down"
    else
      new_direction = "asc"
      icon_class = nil
    end

    # パラメータを保持しながらソートパラメータを更新
    # ActionController::Parametersの場合はpermitしてからto_hでハッシュに変換
    if params_hash.respond_to?(:permit)
      link_params = params_hash.permit(:sort, :direction, :page, :customer_code, :company_name).to_h.symbolize_keys
    else
      link_params = params_hash.dup
    end

    link_params[:sort] = column
    link_params[:direction] = new_direction
    link_params.delete(:page) # ページネーションをリセット

    link_to customers_path(link_params), class: "text-decoration-none text-dark d-flex align-items-center" do
      content_tag(:span, title) +
      (icon_class ? content_tag(:i, "", class: "bi #{icon_class} ms-1") : content_tag(:i, "", class: "bi bi-arrow-down-up ms-1 text-muted", style: "opacity: 0.3"))
    end
  end
end
