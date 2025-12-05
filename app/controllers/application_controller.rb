class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  # allow_browser versions: :modern  # 一時的に無効化（422エラー対策）

  protect_from_forgery with: :null_session

  # 404エラーハンドリング：存在しないアクションへのアクセス
  rescue_from AbstractController::ActionNotFound, with: :not_found

  # shop-user権限チェック：shopコントローラー以外へのアクセスを制限
  # shop/sessions、home、administrators#loginは公開ページなので除外
  before_action :require_shop_user_access, unless: -> {
    controller_path.start_with?("shop/") ||
    controller_path == "home" ||
    (controller_path == "administrators" && action_name == "login")
  }

  helper_method :current_administrator, :administrator_signed_in?, :current_customer, :customer_signed_in?, :shop_user?

  # 404エラーハンドリング：存在しないページへのアクセス
  def not_found
    render file: Rails.root.join("public", "404.html"), status: :not_found, layout: false
  end

  private

  def current_administrator
    @current_administrator ||= Administrator.find_by(id: session[:administrator_id]) if session[:administrator_id]
  end

  def administrator_signed_in?
    current_administrator.present?
  end

  def require_login
    unless administrator_signed_in?
      redirect_to login_path, alert: "ログインしてください。"
    end
  end

  def require_editor
    unless administrator_signed_in? && (current_administrator.editor? || current_administrator.admin? || current_administrator.editor_limited?)
      redirect_to masters_path, alert: "この操作を行う権限がありません。"
    end
  end

  def require_editor_limited_access
    # admin と editor は制限なし
    return if administrator_signed_in? && (current_administrator.admin? || current_administrator.editor?)

    # editor_limited はホワイトリスト化されたコントローラのみ許可（ネームスペースも考慮）
    if administrator_signed_in? && current_administrator.editor_limited?
      allowed_controller_paths = %w[
        bank_accounts
        budgets
        company_informations
        customers
        delivery_locations
        masters
        orders
        invoices
        payment_management
        payment_methods
        product_categories
        product_specifications
        products
        sales_reports
        tax_rates
        units
      ]
      return if allowed_controller_paths.include?(controller_path)
    end

    # viewer は orders と invoices にアクセス可能（閲覧のみ）
    if administrator_signed_in? && current_administrator.viewer?
      allowed_controller_paths = %w[orders invoices]
      return if allowed_controller_paths.include?(controller_path)
    end

    redirect_to masters_path, alert: "このページにアクセスする権限がありません。"
  end

  def require_viewer_or_editor_access
    # ログイン必須
    unless administrator_signed_in?
      redirect_to login_path, alert: "ログインしてください。"
      return
    end

    # admin と editor は制限なし
    return if current_administrator.admin? || current_administrator.editor?

    # editor_limited は orders と invoices にアクセス可能
    if current_administrator.editor_limited?
      allowed_controller_paths = %w[orders invoices]
      return if allowed_controller_paths.include?(controller_path)
    end

    # viewer は orders と invoices にアクセス可能（閲覧のみ）
    if current_administrator.viewer?
      allowed_controller_paths = %w[orders invoices]
      return if allowed_controller_paths.include?(controller_path)
    end

    redirect_to masters_path, alert: "このページにアクセスする権限がありません。"
  end

  def require_admin_only
    unless administrator_signed_in?
      redirect_to login_path, alert: "ログインしてください。"
      return
    end

    unless current_administrator.admin?
      redirect_to masters_path, alert: "この操作を行う権限がありません。管理者権限が必要です。"
    end
  end

  private

  def current_customer
    @current_customer ||= Customer.find_by(id: session[:customer_id]) if session[:customer_id]
  end

  def customer_signed_in?
    current_customer.present?
  end

  def authenticate_customer!
    unless customer_signed_in?
      redirect_to shop_login_path, alert: "ログインしてください"
    end
  end

  # shop-user権限チェック（shopにログインしている顧客はshop-user権限を持つ）
  def shop_user?
    customer_signed_in?
  end

  # shop-user権限が必要なアクションを保護（shopコントローラー以外へのアクセスを制限）
  def require_shop_user_access
    # 管理者がログインしている場合は制限しない
    return if administrator_signed_in?

    # shopコントローラー以外へのアクセスは、shop-user権限では許可しない
    if customer_signed_in?
      redirect_to shop_products_path, alert: "このページにアクセスする権限がありません"
    end
  end
end
