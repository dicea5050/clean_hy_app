require "test_helper"

class ProductSpecificationsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get product_specifications_index_url
    assert_response :success
  end

  test "should get show" do
    get product_specifications_show_url
    assert_response :success
  end

  test "should get new" do
    get product_specifications_new_url
    assert_response :success
  end

  test "should get edit" do
    get product_specifications_edit_url
    assert_response :success
  end

  test "should get create" do
    get product_specifications_create_url
    assert_response :success
  end

  test "should get update" do
    get product_specifications_update_url
    assert_response :success
  end

  test "should get destroy" do
    get product_specifications_destroy_url
    assert_response :success
  end
end
