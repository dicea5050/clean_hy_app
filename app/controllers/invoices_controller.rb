class InvoicesController < ApplicationController
  before_action :require_editor_limited_access
  before_action :set_invoice, only: [ :show, :edit, :update, :destroy ]

  def index
    @q = Invoice.includes(:customer).order(created_at: :desc)

    # 検索パラメータが存在する場合に検索
    if params[:search].present?
      search_params = params[:search]

      # 顧客コードでの検索
      @q = @q.by_customer_code(search_params[:customer_code]) if search_params[:customer_code].present?

      # 取引先名での検索
      @q = @q.joins(:customer).where("customers.company_name LIKE ?", "%#{search_params[:company_name]}%") if search_params[:company_name].present?

      # 請求書番号での検索
      @q = @q.where("invoice_number LIKE ?", "%#{search_params[:invoice_number]}%") if search_params[:invoice_number].present?

      # 請求日の期間検索
      @q = @q.where("invoice_date >= ?", search_params[:invoice_date_from]) if search_params[:invoice_date_from].present?
      @q = @q.where("invoice_date <= ?", search_params[:invoice_date_to]) if search_params[:invoice_date_to].present?

      # 請求金額の範囲検索
      # 注: 実際のプロジェクトでは、total_amountをDBに保存するか、
      # サブクエリやJOINを使用して効率的に検索する実装を検討してください
      if search_params[:amount_from].present? || search_params[:amount_to].present?
        # ここではパフォーマンスのため、インメモリでのフィルタリングを避け、
        # 先に他の条件で絞り込んでから、必要なデータを取得する
        invoice_ids = @q.pluck(:id)
        total_amounts = {}

        if invoice_ids.present?
          # 該当する請求書の合計金額を計算
          Invoice.includes(orders: :order_items).where(id: invoice_ids).each do |inv|
            total_amounts[inv.id] = inv.total_amount
          end

          # 金額でフィルタリング
          filtered_ids = invoice_ids

          if search_params[:amount_from].present?
            min_amount = search_params[:amount_from].to_i
            filtered_ids = filtered_ids.select { |id| total_amounts[id] && total_amounts[id] >= min_amount }
          end

          if search_params[:amount_to].present?
            max_amount = search_params[:amount_to].to_i
            filtered_ids = filtered_ids.select { |id| total_amounts[id] && total_amounts[id] <= max_amount }
          end

          @q = @q.where(id: filtered_ids)
        end
      end

      # 支払期限の期間検索
      @q = @q.where("due_date >= ?", search_params[:due_date_from]) if search_params[:due_date_from].present?
      @q = @q.where("due_date <= ?", search_params[:due_date_to]) if search_params[:due_date_to].present?

      # 請求書送付方法による検索
      if search_params[:delivery_method].present?
        electronic = search_params[:delivery_method] == "electronic"
        @q = @q.joins(:customer).where(customers: { electronic: electronic })
      end

      # 承認状態による検索
      if search_params[:approval_statuses].present?
        @q = @q.where(approval_status: search_params[:approval_statuses])
      end
    else
      # 検索していない場合はデフォルトで今月の請求書を表示
      @q = @q.where([ "created_at >= ?", Date.today.beginning_of_month ])
    end

    @invoices = @q.page(params[:page]).per(25)
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
    @payment_records = @invoice.payment_records.order(:payment_date)
    # 既存の入金記録がない場合は、空の入金記録を1つ追加
    @payment_records.build if @payment_records.empty?
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
      @payment_records = @invoice.payment_records.order(:payment_date)
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
      invoices = Invoice.where(id: invoice_ids, approval_status: [ "未申請", "差し戻し" ])

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

  def receipt
    @invoice = Invoice.includes(:customer).find(params[:id])
    company_info = CompanyInformation.first
    issue_date = params[:issue_date].present? ? Date.parse(params[:issue_date]) : Date.current

    respond_to do |format|
      format.pdf do
        pdf = ReceiptPdf.new(@invoice, company_info, issue_date)
        send_data pdf.render,
          filename: "領収書_#{@invoice.customer.company_name}_#{@invoice.invoice_number}.pdf",
          type: "application/pdf",
          disposition: "inline"
      end
    end
  end

  private
    def set_invoice
      @invoice = Invoice.includes(:orders, :payment_records).find(params[:id])
    end

    def invoice_params
      params.require(:invoice).permit(
        :customer_id, :invoice_date, :due_date, :notes,
        payment_records_attributes: [ :id, :payment_date, :payment_type, :amount, :memo, :_destroy ]
      )
    end
end
