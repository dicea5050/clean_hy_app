class MastersController < ApplicationController
  before_action :require_login
  before_action :require_editor_limited_access

  def index
  end
end
