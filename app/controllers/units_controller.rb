class UnitsController < ApplicationController
  before_action :require_editor_limited_access
  before_action :require_viewer_show_only
  before_action :set_unit, only: [ :show, :edit, :update, :destroy ]

  def index
    @units = Unit.all.page(params[:page]).per(30)
  end

  def show
  end

  def new
    @unit = Unit.new
  end

  def edit
  end

  def create
    @unit = Unit.new(unit_params)

    if @unit.save
      redirect_to units_path, notice: "単位を登録しました。"
    else
      render :new
    end
  end

  def update
    if @unit.update(unit_params)
      redirect_to units_path, notice: "単位を更新しました。"
    else
      render :edit
    end
  end

  def destroy
    if @unit.can_be_destroyed?
      @unit.destroy
      redirect_to units_path, notice: "単位を削除しました。"
    else
      redirect_to units_path, alert: "この単位は受注情報で使用されているため削除できません。"
    end
  end

  private

  def set_unit
    @unit = Unit.find(params[:id])
  end

  def unit_params
    params.require(:unit).permit(:name)
  end
end
