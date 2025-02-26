class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
  
  helper_method :current_administrator, :administrator_signed_in?
  
  private
  
  def current_administrator
    @current_administrator ||= Administrator.find_by(id: session[:administrator_id]) if session[:administrator_id]
  end
  
  def administrator_signed_in?
    current_administrator.present?
  end
  
  def require_login
    unless administrator_signed_in?
      redirect_to login_path, alert: 'ログインしてください。'
    end
  end
  
  def require_editor
    unless administrator_signed_in? && (current_administrator.editor? || current_administrator.admin?)
      redirect_to masters_path, alert: 'この操作を行う権限がありません。'
    end
  end
end
