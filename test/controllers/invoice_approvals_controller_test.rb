require "test_helper"

class InvoiceApprovalsControllerTest < ActionDispatch::IntegrationTest
  test "should get create" do
    get invoice_approvals_create_url
    assert_response :success
  end
end
