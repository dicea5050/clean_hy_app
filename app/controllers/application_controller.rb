class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  helper_method :current_administrator, :administrator_signed_in?, :current_customer, :customer_signed_in?

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
        company_informations
        customers
        delivery_locations
        masters
        payment_methods
        product_categories
        product_specifications
        products
        tax_rates
        units
      ]
      return if allowed_controller_paths.include?(controller_path)
    end

    redirect_to masters_path, alert: "このページにアクセスする権限がありません。"
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
end
