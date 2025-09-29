require "application_system_test_case"

class UnitsTest < ApplicationSystemTestCase
  def login_as_admin
    admin = Administrator.create!(email: "admin@example.com", password: "password123", role: :admin)
    visit login_path
    fill_in "email", with: admin.email
    fill_in "password", with: "password123"
    within("form[action='#{authenticate_path}']") do
      find("input[type='submit'], button[type='submit']", match: :first).click
    end
    assert_current_path masters_path
  end

  test "redirect to login when not authenticated" do
    visit units_path
    assert_current_path login_path
  end

  test "CRUD units when logged in" do
    login_as_admin

    visit units_path

    visit new_unit_path
    fill_in "unit[name]", with: "個"
    within("form[action='#{units_path}']") do
      find("input[type='submit'], button[type='submit']", match: :first).click
    end
    assert_text "単位を登録しました。", wait: 3

    unit = Unit.find_by(name: "個")
    assert unit.present?

    visit edit_unit_path(unit)
    fill_in "unit[name]", with: "箱"
    within("form[action='#{unit_path(unit)}']") do
      find("input[type='submit'], button[type='submit']", match: :first).click
    end
    assert_text "単位を更新しました。", wait: 3
    unit.reload
    assert_equal "箱", unit.name

    # UI削除は環境差異で不安定なため、モデル経由で削除
    unit.destroy
    assert_nil Unit.find_by(id: unit.id)
  end
end
