class PaymentManagementController < ApplicationController
  before_action :require_editor_limited_access
  before_action :require_editor, only: [ :create, :edit, :update, :destroy ]
  before_action :set_payment_record, only: [ :edit, :update, :destroy ]

  def index
    @customers = Customer.order(:company_name)
  end

  def unpaid_invoices
    begin
      @customer = Customer.find(params[:customer_id]) if params[:customer_id].present?

      if @customer
        Rails.logger.debug "=== PaymentManagementController#unpaid_invoices 開始 ==="
        Rails.logger.debug "顧客ID: #{@customer.id}, 顧客名: #{@customer.company_name}"

        # デバッグ: この顧客の全請求書を確認
        total_invoices = Invoice.where(customer: @customer).count
        Rails.logger.debug "全請求書数: #{total_invoices}"

        # 承認状態別の請求書数を確認
        approval_statuses = Invoice.where(customer: @customer).group(:approval_status).count
        Rails.logger.debug "承認状態別請求書数: #{approval_statuses}"

        # 承認済み請求書の詳細情報をログに出力
        approved_invoices = Invoice.where(customer: @customer, approval_status: "\u627F\u8A8D\u6E08\u307F")
                                  .includes(orders: :order_items)
        Rails.logger.debug "承認済み請求書数: #{approved_invoices.count}"

        approved_invoices.each do |invoice|
          total_amount = invoice.total_amount
          total_paid_amount = invoice.total_paid_amount
          unpaid_amount = invoice.unpaid_amount

          Rails.logger.debug "承認済み請求書詳細 - ID: #{invoice.id}, 番号: #{invoice.invoice_number}, " \
                            "承認状態: #{invoice.approval_status}, " \
                            "合計金額: #{total_amount}, " \
                            "入金済み額: #{total_paid_amount}, " \
                            "未入金額: #{unpaid_amount}, " \
                            "受注数: #{invoice.orders.count}"
        end

        # PaymentManagementServiceを明示的に読み込む
        begin
          @service = PaymentManagementService.new(@customer)
        rescue NameError => e
          Rails.logger.error "PaymentManagementService not found, trying to load: #{e.message}"
          # ファイルを直接読み込む
          load Rails.root.join("app", "services", "payment_management_service.rb")
          @service = PaymentManagementService.new(@customer)
        end
        
        begin
          @unpaid_invoices = @service.unpaid_invoices
          @unpaid_invoices = [] if @unpaid_invoices.nil?
        rescue => e
          Rails.logger.error "Error in unpaid_invoices service: #{e.message}"
          Rails.logger.error e.backtrace.join("\n")
          @unpaid_invoices = []
        end

        Rails.logger.debug "未入金請求書数（サービスから取得）: #{@unpaid_invoices.count}"

        # 全額入金済みの場合、空の配列を返す（正常な状態）
        invoices_data = if @unpaid_invoices.empty?
          []
        else
          @unpaid_invoices.map do |invoice|
            begin
              # payment_recordsが正しく読み込まれていることを確認
              payment_records = invoice.payment_records.to_a
              
              # 元入金IDを取得（充当記録のnotesから抽出）
              original_payment_ids = payment_records.map do |pr|
                extract_original_payment_id(pr.notes) if pr.notes.present?
              end.compact.uniq

              {
                id: invoice.id,
                invoice_number: invoice.invoice_number,
                invoice_date: invoice.invoice_date&.strftime("%Y-%m-%d"),
                total_amount: invoice.total_amount.to_i,
                paid_amount: invoice.total_paid_amount.to_i,
                remaining_amount: invoice.remaining_amount.to_i,
                payment_ids: payment_records.map(&:id),
                original_payment_ids: original_payment_ids
              }
            rescue => e
              Rails.logger.error "Error processing invoice #{invoice.id}: #{e.message}"
              Rails.logger.error e.backtrace.join("\n")
              nil
            end
          end.compact
        end

        Rails.logger.debug "=== PaymentManagementController#unpaid_invoices 終了 ==="

        render json: {
          success: true,
          title: "\u5165\u91D1\u672A\u5B8C\u4E86\u8ACB\u6C42\u66F8\u4E00\u89A7",
          invoices: invoices_data || [],
          debug: {
            total_invoices: total_invoices,
            approval_statuses: approval_statuses,
            approved_count: approved_invoices.count,
            unpaid_count: @unpaid_invoices.count
          }
        }
      else
        render json: { success: false, error: "\u53D6\u5F15\u5148\u304C\u9078\u629E\u3055\u308C\u3066\u3044\u307E\u305B\u3093" }
      end
    rescue => e
      Rails.logger.error "Error in unpaid_invoices: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      render json: { success: false, error: e.message, backtrace: e.backtrace.first(5) }
    end
  end

  def paid_invoices
    @customer = Customer.find(params[:customer_id]) if params[:customer_id].present?

    if @customer
      begin
        @service = ::PaymentManagementService.new(@customer)
        @paid_invoices = @service.paid_invoices

        render json: {
          success: true,
          title: "\u5165\u91D1\u6E08\u307F\uFF08\u4E00\u90E8\u5165\u91D1\u6E08\u307F\u3092\u542B\u3080\uFF09\u8ACB\u6C42\u66F8\u4E00\u89A7",
          invoices: @paid_invoices.map do |invoice|
            # 元入金IDを取得（充当記録のnotesから抽出）
            original_payment_ids = invoice.payment_records.map do |pr|
              extract_original_payment_id(pr.notes)
            end.compact.uniq

            {
              id: invoice.id,
              invoice_number: invoice.invoice_number,
              invoice_date: invoice.invoice_date&.strftime("%Y-%m-%d"),
              total_amount: invoice.total_amount.to_i,
              paid_amount: invoice.total_paid_amount.to_i,
              remaining_amount: invoice.remaining_amount.to_i,
              payment_ids: invoice.payment_records.pluck(:id),
              original_payment_ids: original_payment_ids
            }
          end
        }
      rescue => e
        Rails.logger.error "Error in paid_invoices: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
        render json: { success: false, error: e.message }
      end
    else
      render json: { success: false, error: "\u53D6\u5F15\u5148\u304C\u9078\u629E\u3055\u308C\u3066\u3044\u307E\u305B\u3093" }
    end
  end

  def payment_history
    @customer = Customer.find(params[:customer_id]) if params[:customer_id].present?

    if @customer
      begin
        @service = ::PaymentManagementService.new(@customer)
        @payment_history = @service.payment_history_grouped

        render json: {
          success: true,
          title: "\u5165\u91D1\u5C65\u6B74\u4E00\u89A7",
          payment_history: @payment_history
        }
      rescue => e
        Rails.logger.error "Error in payment_history: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
        render json: { success: false, error: e.message }
      end
    else
      render json: { success: false, error: "\u53D6\u5F15\u5148\u304C\u9078\u629E\u3055\u308C\u3066\u3044\u307E\u305B\u3093" }
    end
  end

  def create
    @customer = Customer.find(payment_params[:customer_id]) if payment_params[:customer_id].present?

    unless @customer
      if request.format.json?
        render json: { success: false, error: "取引先が選択されていません" }, status: :unprocessable_entity
      else
        redirect_to payment_management_index_path,
                    alert: "取引先が選択されていません"
      end
      return
    end

    @service = ::PaymentManagementService.new(@customer)

    begin
      payment_record = @service.create_payment(
        payment_params[:payment_date],
        payment_params[:category],
        payment_params[:amount].to_i,
        payment_params[:notes]
      )

      if request.format.json?
        render json: { success: true, payment_id: payment_record.id, message: "入金を登録しました。入金ID: #{payment_record.id}" }
      else
        redirect_to payment_management_index_path,
                    notice: "入金を登録しました。入金ID: #{payment_record.id}"
      end
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.error "Validation errors: #{e.record.errors.full_messages}"
      if request.format.json?
        render json: { success: false, error: "入金の登録に失敗しました: #{e.record.errors.full_messages.join(', ')}" }, status: :unprocessable_entity
      else
        redirect_to payment_management_index_path,
                    alert: "入金の登録に失敗しました: #{e.record.errors.full_messages.join(', ')}"
      end
    rescue => e
      Rails.logger.error "Payment creation error: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      if request.format.json?
        render json: { success: false, error: "入金の登録に失敗しました: #{e.message}" }, status: :internal_server_error
      else
        redirect_to payment_management_index_path,
                    alert: "入金の登録に失敗しました: #{e.message}"
      end
    end
  end

  def edit
    @customer = @payment_record.customer
  end

  def update
    @customer = @payment_record.customer
    @service = ::PaymentManagementService.new(@customer)

    begin
      # 金額が変更された場合の処理
      if payment_params[:amount].to_i != @payment_record.amount
        @service.update_payment_with_invoice_adjustment(@payment_record, payment_params)
        redirect_to payment_management_index_path,
                    notice: "入金を更新しました。入金ID: #{@payment_record.id}"
      else
        # 金額以外の更新
        @payment_record.update!(payment_params.except(:amount))
        redirect_to payment_management_index_path,
                    notice: "入金を更新しました。入金ID: #{@payment_record.id}"
      end
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.error "Validation errors: #{e.record.errors.full_messages}"
      redirect_to edit_payment_management_path(@payment_record),
                  alert: "入金の更新に失敗しました: #{e.record.errors.full_messages.join(', ')}"
    rescue => e
      Rails.logger.error "Payment update error: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      redirect_to edit_payment_management_path(@payment_record),
                  alert: "入金の更新に失敗しました: #{e.message}"
    end
  end

  def destroy
    @customer = @payment_record.customer
    @service = ::PaymentManagementService.new(@customer)

    begin
      @service.delete_payment_with_invoice_adjustment(@payment_record)
      redirect_to payment_management_index_path,
                  notice: "入金を削除しました。入金ID: #{@payment_record.id}"
    rescue => e
      Rails.logger.error "Payment deletion error: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      redirect_to payment_management_index_path,
                  alert: "入金の削除に失敗しました: #{e.message}"
    end
  end

  # 顧客コードから顧客情報を取得するAPI（orders_controllerから再利用）
  def find_customer_by_code
    customer = Customer.find_by(customer_code: params[:code])
    if customer
      render json: {
        success: true,
        customer: {
          id: customer.id,
          company_name: customer.company_name,
          customer_code: customer.customer_code
        }
      }
    else
      render json: { success: false, message: "顧客が見つかりません" }
    end
  end

  private

  def set_payment_record
    @payment_record = PaymentRecord.find(params[:id])
  end

  def payment_params
    params.require(:payment).permit(:payment_date, :category, :amount, :notes, :customer_id)
  end

  def extract_original_payment_id(notes)
    return nil unless notes.present?

    match = notes.match(/消し込み（元入金ID: (\d+)）/)
    match ? match[1].to_i : nil
  end
end
