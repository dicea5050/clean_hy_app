require "test_helper"

class UnitsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @unit = units(:one)
    @administrator = administrators(:one)
    post authenticate_path, params: { email: @administrator.email, password: "secret" }
  end

  test "should get index" do
    get units_url
    assert_response :success
  end

  test "should get new" do
    get new_unit_url
    assert_response :success
  end

  test "should create unit" do
    assert_difference("Unit.count") do
      post units_url, params: { unit: { name: "New Unit" } }
    end

    assert_redirected_to units_url
  end

  test "should show unit" do
    get unit_url(@unit)
    assert_response :success
  end

  test "should get edit" do
    get edit_unit_url(@unit)
    assert_response :success
  end

  test "should update unit" do
    patch unit_url(@unit), params: { unit: { name: "Updated Unit" } }
    assert_redirected_to units_url
  end

  test "should destroy unit" do
    deletable_unit = Unit.create!(name: "削除対象")

    assert_difference("Unit.count", -1) do
      delete unit_url(deletable_unit)
    end

    assert_redirected_to units_url
  end
end
