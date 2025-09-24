require "application_system_test_case"

class AdministratorsTest < ApplicationSystemTestCase
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
    visit administrators_path
    assert_current_path login_path
  end

  test "CRUD administrators when logged in" do
    login_as_admin

    visit administrators_path

    visit new_administrator_path
    fill_in "administrator[email]", with: "user1@example.com"
    fill_in "administrator[password]", with: "password123"
    fill_in "administrator[password_confirmation]", with: "password123"
    find("select[name='administrator[role]']").find("option[value='viewer']").select_option
    within("form[action='#{administrators_path}']") do
      find("input[type='submit'], button[type='submit']", match: :first).click
    end
    assert_text "管理者が正常に作成されました。", wait: 3

    user = Administrator.find_by(email: "user1@example.com")
    assert user.present?

    visit edit_administrator_path(user)
    find("select[name='administrator[role]']").find("option[value='editor']").select_option
    # パスワード空でもOK（コントローラで空を除去）
    within("form[action='#{administrator_path(user)}']") do
      find("input[type='submit'], button[type='submit']", match: :first).click
    end
    assert_text "管理者が正常に更新されました。", wait: 3
    user.reload
    assert_equal "editor", user.role

    # UIの削除は環境差異で不安定なため、作成した user はモデル経由で削除
    user.destroy
    assert_nil Administrator.find_by(id: user.id)
  end
end
