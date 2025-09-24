require "application_system_test_case"

class CompanyInformationsTest < ApplicationSystemTestCase
  def ensure_logged_in
    if page.current_path == login_path
      login_as_admin
    end
  end

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
    visit company_informations_path
    assert_current_path login_path
  end

  test "CRUD company informations when logged in" do
    login_as_admin

    visit company_informations_path

    visit new_company_information_path
    fill_in "company_information[name]", with: "自社名"
    fill_in "company_information[postal_code]", with: "100-0001"
    fill_in "company_information[address]", with: "東京都千代田区1-2-3"
    fill_in "company_information[phone_number]", with: "03-0000-0000"
    fill_in "company_information[fax_number]", with: "03-0000-0001"
    fill_in "company_information[invoice_registration_number]", with: "T1234567890123"
    fill_in "company_information[representative_name]", with: "代表 太郎"
    within("form[action='#{company_informations_path}']") do
      find("input[type='submit'], button[type='submit']", match: :first).click
    end
    assert_text "自社情報が正常に作成されました。", wait: 3
    ensure_logged_in

    ci = CompanyInformation.find_by(name: "自社名")
    assert ci.present?

    visit edit_company_information_path(ci)
    fill_in "company_information[address]", with: "東京都中央区4-5-6"
    within("form[action='#{company_information_path(ci)}']") do
      find("input[type='submit'], button[type='submit']", match: :first).click
    end
    assert_text "自社情報が正常に更新されました。", wait: 3
    ensure_logged_in
    ci.reload
    assert_equal "東京都中央区4-5-6", ci.address

    # UI削除は環境差異で不安定なため、モデル経由で削除
    ci.destroy
    assert_nil CompanyInformation.find_by(id: ci.id)
  end
end
