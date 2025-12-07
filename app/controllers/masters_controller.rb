class MastersController < ApplicationController
  before_action :require_login
  before_action :require_editor_limited_access
  before_action :require_viewer_show_only

  def index
  end
end
