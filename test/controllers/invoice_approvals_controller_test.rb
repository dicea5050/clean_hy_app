require "test_helper"

class InvoiceApprovalsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @administrator = administrators(:one)
    @invoice = invoices(:one)
    InvoiceApproval.delete_all
    post authenticate_path, params: { email: @administrator.email, password: "secret" }
  end

  test "should get index" do
    get invoice_approvals_url
    assert_response :success
  end

  test "should bulk create" do
    post bulk_create_invoice_approvals_url, params: { invoice_ids: @invoice.id }
    assert_response :redirect
  end

  test "should approve" do
    invoice_approval = InvoiceApproval.create!(invoice: @invoice, status: InvoiceApproval::STATUSES[:pending], approver: @administrator)

    post approve_invoice_approval_url(invoice_approval)
    assert_response :redirect
  end

  test "should reject" do
    invoice_approval = InvoiceApproval.create!(invoice: @invoice, status: InvoiceApproval::STATUSES[:pending], approver: @administrator)

    post reject_invoice_approval_url(invoice_approval)
    assert_response :redirect
  end
end
