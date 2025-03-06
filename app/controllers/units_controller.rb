class UnitsController < ApplicationController
  before_action :set_unit, only: [ :show, :edit, :update, :destroy ]

  def index
    @units = Unit.all
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
    @unit.destroy
    redirect_to units_path, notice: "単位を削除しました。"
  end

  private

  def set_unit
    @unit = Unit.find(params[:id])
  end

  def unit_params
    params.require(:unit).permit(:name)
  end
end
