require "test_helper"

class ProductSpecificationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @product_specification = product_specifications(:one)
    @administrator = administrators(:one)
    post authenticate_path, params: { email: @administrator.email, password: "secret" }
  end

  test "should get index" do
    get product_specifications_url
    assert_response :success
  end

  test "should get new" do
    get new_product_specification_url
    assert_response :success
  end

  test "should create product specification" do
    assert_difference("ProductSpecification.count") do
      post product_specifications_url, params: { product_specification: { name: "New Spec", is_active: true } }
    end

    assert_redirected_to product_specifications_url
  end

  test "should show product specification" do
    get product_specification_url(@product_specification)
    assert_response :success
  end

  test "should get edit" do
    get edit_product_specification_url(@product_specification)
    assert_response :success
  end

  test "should update product specification" do
    patch product_specification_url(@product_specification), params: { product_specification: { name: "Updated", is_active: @product_specification.is_active } }
    assert_redirected_to product_specifications_url
  end

  test "should destroy product specification" do
    assert_difference("ProductSpecification.count", -1) do
      delete product_specification_url(@product_specification)
    end

    assert_redirected_to product_specifications_url
  end
end
