class InvoicesController < ApplicationController
  before_action :set_invoice, only: [ :show, :edit, :update, :destroy ]

  def index
    @invoices = Invoice.all.order(created_at: :desc).page(params[:page]).per(25)
  end

  def show
  end

  def new
    @invoice = Invoice.new
    @invoice.invoice_date = Date.today

    if params[:order_ids].present?
      @order_ids = params[:order_ids].split(",")
      @orders = Order.includes(:customer, :order_items).where(id: @order_ids)

      # 最初の受注の顧客IDを設定
      if @orders.present? && @orders.first.customer.present?
        @customer = @orders.first.customer
        @invoice.customer_id = @customer.id
        Rails.logger.info "顧客情報を設定: #{@customer.company_name} (ID: #{@customer.id})"
      else
        Rails.logger.warn "顧客情報が取得できませんでした"
      end
    end

    @customers = Customer.all.order(:company_name)
  end

  def edit
    @customers = Customer.all.order(:company_name)
    @orders = @invoice.orders
    @order_ids = @orders.pluck(:id)
  end

  def create
    @invoice = Invoice.new(invoice_params)

    # 取引先IDがない場合は選択された受注から取得
    if @invoice.customer_id.blank? && params[:order_ids].present?
      order_ids = params[:order_ids].split(",")
      first_order = Order.find_by(id: order_ids.first)
      @invoice.customer_id = first_order.customer_id if first_order
    end

    # 選択された受注を関連付け
    if params[:order_ids].present?
      params[:order_ids].split(",").each do |order_id|
        @invoice.invoice_orders.build(order_id: order_id)
      end
    end

    if @invoice.save
      redirect_to @invoice, notice: "請求書が正常に作成されました。"
    else
      @customers = Customer.all.order(:company_name)
      @order_ids = params[:order_ids].split(",") if params[:order_ids].present?
      @orders = Order.eager_load(:customer, :order_items).where(id: @order_ids)
      render :new
    end
  end

  def update
    if @invoice.update(invoice_params)
      # 関連する受注を更新
      @invoice.invoice_orders.destroy_all
      if params[:order_ids].present?
        params[:order_ids].split(",").each do |order_id|
          @invoice.invoice_orders.create(order_id: order_id)
        end
      end

      redirect_to @invoice, notice: "請求書が正常に更新されました。"
    else
      @customers = Customer.all.order(:company_name)
      @order_ids = params[:order_ids].split(",") if params[:order_ids].present?
      @orders = Order.eager_load(:customer, :order_items).where(id: @order_ids)
      render :edit
    end
  end

  def destroy
    @invoice.destroy
    redirect_to invoices_path, notice: "請求書が正常に削除されました。"
  end

  # 一括承認申請アクションを追加
  def bulk_request_approval
    invoice_ids = params[:invoice_ids]&.split(",")

    if invoice_ids.present?
      invoices = Invoice.where(id: invoice_ids, approval_status: ["未申請", "差し戻し"])

      Invoice.transaction do
        invoices.each do |invoice|
          invoice.update!(approval_status: "承認待ち")
        end
      end

      flash[:notice] = "#{invoices.count}件の請求書を承認申請しました。"
    else
      flash[:alert] = "請求書が選択されていません。"
    end

    redirect_to invoices_path
  rescue => e
    flash[:error] = "承認申請に失敗しました: #{e.message}"
    redirect_to invoices_path
  end

  def pdf
    @invoice = Invoice.includes(orders: [ :customer, :order_items ]).find(params[:id])
    company_info = CompanyInformation.first

    respond_to do |format|
      format.pdf do
        pdf = InvoicePdf.new(@invoice, company_info)
        send_data pdf.render,
          filename: "請求書_#{@invoice.invoice_number}.pdf",
          type: "application/pdf",
          disposition: "inline"
      end
    end
  end

  private
    def set_invoice
      @invoice = Invoice.includes(:orders).find(params[:id])
    end

    def invoice_params
      params.require(:invoice).permit(:customer_id, :invoice_date, :due_date, :notes)
    end
end
