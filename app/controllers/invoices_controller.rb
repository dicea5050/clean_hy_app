class InvoicesController < ApplicationController
  before_action :require_viewer_or_editor_access
  before_action :require_editor, only: [ :new, :create, :edit, :update, :destroy, :bulk_request_approval, :pdf, :receipt ]
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

      # 入金状況による検索
      if search_params[:payment_statuses].present?
        # payment_statusは計算される値のため、先に他の条件で絞り込んでからフィルタリング
        invoice_ids = @q.pluck(:id)

        if invoice_ids.present?
          # 各請求書の入金状況を計算してフィルタリング
          filtered_ids = Invoice.includes(orders: :order_items).includes(:payment_records)
                                .where(id: invoice_ids)
                                .select { |inv| search_params[:payment_statuses].include?(inv.payment_status) }
                                .map(&:id)

          @q = @q.where(id: filtered_ids)
        else
          @q = @q.none
        end
      end
    end
    # 検索パラメータがない場合も全ての請求書を表示（承認待ち、承認済み、差し戻しを含む）
    # 削除済みの請求書はdestroyで物理削除されるため自動的に除外される

    @invoices = @q.page(params[:page]).per(25)
  end

  def show
    # 繰越金額を計算（現在の請求書を除外）
    @carryover_amount = @invoice.customer_id.present? ? Invoice.carryover_amount_for_customer(@invoice.customer_id, exclude_invoice_id: @invoice.id) : 0
    # この請求書に関連する入金履歴を取得（入金日降順）
    @payment_records = @invoice.payment_records.order(payment_date: :desc, created_at: :desc)
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

    # 繰越金額を計算（顧客IDが設定されている場合）
    @carryover_amount = @invoice.customer_id.present? ? Invoice.carryover_amount_for_customer(@invoice.customer_id) : 0

    @customers = Customer.all.order(:company_name)
  end

  def edit
    @customers = Customer.all.order(:company_name)
    @orders = @invoice.orders
    @order_ids = @orders.pluck(:id)
    # 繰越金額を計算（現在の請求書を除外）
    @carryover_amount = @invoice.customer_id.present? ? Invoice.carryover_amount_for_customer(@invoice.customer_id, exclude_invoice_id: @invoice.id) : 0
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
    # 更新前の承認ステータスを保存
    previous_approval_status = @invoice.approval_status

    if @invoice.update(invoice_params)
      # 関連する受注を更新
      @invoice.invoice_orders.destroy_all
      if params[:order_ids].present?
        params[:order_ids].split(",").each do |order_id|
          @invoice.invoice_orders.create(order_id: order_id)
        end
      end

      # 承認済みまたは差し戻しステータスの請求書が更新された場合、ステータスを「承認待ち」に戻す
      if previous_approval_status == Invoice::APPROVAL_STATUSES[:approved] ||
         previous_approval_status == Invoice::APPROVAL_STATUSES[:rejected]
        @invoice.update(approval_status: Invoice::APPROVAL_STATUSES[:waiting])
        # 新しい承認申請レコードを作成
        @invoice.invoice_approvals.create!(
          status: InvoiceApproval::STATUSES[:pending]
        )
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

  def bulk_request_approval
    invoice_ids = params[:invoice_ids]&.split(",")

    if invoice_ids.blank?
      return redirect_to invoices_path, alert: "請求書が選択されていません。"
    end

    Rails.logger.debug "=== 一括承認申請処理開始 ==="
    Rails.logger.debug "請求書ID数: #{invoice_ids.size}"
    Rails.logger.debug "請求書IDs: #{invoice_ids.join(', ')}"

    success_count = 0
    error_count = 0

    ActiveRecord::Base.transaction do
      invoice_ids.each do |invoice_id|
        Rails.logger.debug "--- 請求書ID: #{invoice_id} の処理開始 ---"
        invoice = Invoice.find(invoice_id)
        Rails.logger.debug "更新前のInvoice approval_status: #{invoice.approval_status}"

        # 差し戻しステータスの請求書のみが選択可能なため、ここでは必ず差し戻しステータスのはず
        # 念のためチェック
        unless invoice.approval_status == Invoice::APPROVAL_STATUSES[:rejected]
          Rails.logger.warn "請求書ID: #{invoice_id} は差し戻しステータスではありません（現在のステータス: #{invoice.approval_status}）"
          error_count += 1
          next
        end

        # 新しいInvoiceApprovalレコードを作成
        approval = InvoiceApproval.create!(
          invoice_id: invoice_id,
          status: InvoiceApproval::STATUSES[:pending]
          # approverは承認時点で設定されるため、作成時は設定しない
        )
        Rails.logger.debug "InvoiceApproval作成結果: ID=#{approval.id}, status=#{approval.status}"

        # 請求書の状態を「承認待ち」に更新
        result = invoice.update!(approval_status: Invoice::APPROVAL_STATUSES[:waiting])
        Rails.logger.debug "Invoice更新結果: #{result}"
        Rails.logger.debug "更新後のInvoice approval_status: #{invoice.reload.approval_status}"

        if invoice.errors.any?
          Rails.logger.error "Invoiceバリデーションエラー: #{invoice.errors.full_messages.join(', ')}"
          error_count += 1
        else
          success_count += 1
        end
        Rails.logger.debug "--- 請求書ID: #{invoice_id} の処理完了 ---"
      end
    end

    Rails.logger.debug "=== 一括承認申請処理完了 ==="
    Rails.logger.debug "成功: #{success_count}, エラー: #{error_count}"

    if success_count > 0
      redirect_to invoices_path, notice: "#{success_count}件の請求書を承認申請しました。"
    else
      redirect_to invoices_path, alert: "承認申請に失敗しました。"
    end
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error "=== 一括承認申請処理エラー ==="
    Rails.logger.error "エラーメッセージ: #{e.message}"
    Rails.logger.error "エラークラス: #{e.class}"
    Rails.logger.error "バックトレース:"
    Rails.logger.error e.backtrace.join("\n")
    redirect_to invoices_path, alert: "承認申請に失敗しました: #{e.message}"
  end

  def pdf
    @invoice = Invoice.includes(orders: [ :customer, :order_items ]).find(params[:id])
    company_info = CompanyInformation.first

    # 初回発行と再発行を判定
    reissue = @invoice.first_issued_at.present? || @invoice.issued_count.to_i > 0

    # 発行履歴を更新（バリデーション影響を避けるため update_columns を使用）
    now = Time.current
    if reissue
      @invoice.update_columns(last_issued_at: now, issued_count: @invoice.issued_count.to_i + 1, updated_at: now)
    else
      @invoice.update_columns(first_issued_at: now, last_issued_at: now, issued_count: 1, updated_at: now)
    end

    respond_to do |format|
      format.pdf do
        pdf = InvoicePdf.new(@invoice, company_info, reissue: reissue)
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
      @invoice = Invoice.includes(:orders).find(params[:id])
    end

    def invoice_params
      params.require(:invoice).permit(
        :customer_id, :invoice_date, :due_date, :notes
      )
    end
end
