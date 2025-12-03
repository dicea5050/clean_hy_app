class PaymentManagementService
  def initialize(customer)
    @customer = customer
  end

  # 取引先の未入金請求書一覧を取得（古い順）
  def unpaid_invoices
    Rails.logger.debug "=== PaymentManagementService#unpaid_invoices 開始 ==="
    Rails.logger.debug "顧客ID: #{@customer.id}, 顧客名: #{@customer.company_name}"

    # 承認済みの請求書を取得
    # 注意: approval_statusは文字列で比較するため、定数を使用
    invoices = Invoice.where(customer: @customer, approval_status: Invoice::APPROVAL_STATUSES[:approved])
                     .includes(orders: :order_items, payment_records: :invoice)
                     .order(:invoice_date, :id)

    Rails.logger.debug "承認済み請求書数（フィルタリング前）: #{invoices.count}"

    # 各請求書の詳細情報をログに出力
    invoices.each do |invoice|
      total_amount = invoice.total_amount
      total_paid_amount = invoice.total_paid_amount
      unpaid_amount = invoice.unpaid_amount

      Rails.logger.debug "請求書ID: #{invoice.id}, 番号: #{invoice.invoice_number}, " \
                        "承認状態: #{invoice.approval_status}, " \
                        "合計金額: #{total_amount}, " \
                        "入金済み額: #{total_paid_amount}, " \
                        "未入金額: #{unpaid_amount}"
    end

    # 未入金の請求書をフィルタリング
    unpaid_list = invoices.select do |invoice|
      begin
        unpaid_amount = invoice.unpaid_amount
        unpaid_amount > 0
      rescue => e
        Rails.logger.error "Error calculating unpaid_amount for invoice #{invoice.id}: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
        false
      end
    end

    Rails.logger.debug "未入金請求書数（フィルタリング後）: #{unpaid_list.count}"
    Rails.logger.debug "=== PaymentManagementService#unpaid_invoices 終了 ==="

    unpaid_list
  end

  # 取引先の入金済み請求書一覧を取得（古い順）
  def paid_invoices
    # 入金済みの請求書を取得
    invoices = Invoice.where(customer: @customer)
                     .includes(:orders, :payment_records)
                     .order(:invoice_date, :id)

    # 入金済み（一部入金済みを含む）の請求書をフィルタリング
    invoices.select { |invoice| invoice.total_paid_amount > 0 }
  end

  # 入金額の充当プレビューを計算
  def calculate_allocation_preview(invoices, payment_amount)
    remaining_amount = payment_amount
    allocation_results = []

    invoices.each do |invoice|
      break if remaining_amount <= 0

      total_amount = invoice.total_amount
      already_paid_amount = invoice.total_paid_amount
      unpaid_amount = total_amount - already_paid_amount

      next if unpaid_amount <= 0

      paid_amount = [ remaining_amount, unpaid_amount ].min
      new_remaining = unpaid_amount - paid_amount

      allocation_results << {
        invoice_id: invoice.id,
        invoice_number: invoice.invoice_number,
        invoice_date: invoice.invoice_date,
        total_amount: total_amount,
        current_paid_amount: invoice.total_paid_amount,
        paid_amount: paid_amount,
        new_remaining: new_remaining
      }

      remaining_amount -= paid_amount
    end

    {
      allocation_results: allocation_results,
      remaining_payment: remaining_amount
    }
  end

  # 実際の入金登録処理
  def create_payment(payment_date, category, amount, notes = nil)
    ActiveRecord::Base.transaction do
      # 数値変換を確実に行う
      amount = amount.to_i

      # 入金記録を作成（最初はinvoice_idなし）
      payment_record = PaymentRecord.new(
        customer: @customer,
        payment_date: payment_date,
        category: category,
        amount: amount,
        paid_amount: 0, # 初期値は0、後で充当処理で更新
        notes: notes
      )

      unless payment_record.save
        Rails.logger.error "Payment record validation failed: #{payment_record.errors.full_messages}"
        raise ActiveRecord::RecordInvalid.new(payment_record)
      end

      # 未入金請求書を取得
      unpaid_invoices_list = unpaid_invoices

      # 充当処理
      remaining_amount = amount
      unpaid_invoices_list.each do |invoice|
        break if remaining_amount <= 0

        total_amount = invoice.total_amount
        already_paid_amount = invoice.total_paid_amount
        unpaid_amount = total_amount - already_paid_amount

        next if unpaid_amount <= 0

        paid_amount = [ remaining_amount, unpaid_amount ].min

        # この請求書への充当記録を作成
        allocation_record = PaymentRecord.new(
          invoice: invoice,
          customer: @customer,
          payment_date: payment_date,
          category: category,
          amount: paid_amount,
          paid_amount: paid_amount,
          notes: "消し込み（元入金ID: #{payment_record.id}）"
        )

        unless allocation_record.save
          Rails.logger.error "Allocation record validation failed: #{allocation_record.errors.full_messages}"
          raise ActiveRecord::RecordInvalid.new(allocation_record)
        end

        remaining_amount -= paid_amount
      end

      # 元の入金記録のpaid_amountを更新
      payment_record.update!(paid_amount: amount - remaining_amount)

      payment_record
    end
  rescue => e
    Rails.logger.error "Payment creation failed: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    raise e
  end

  # 取引先の入金履歴を取得
  def payment_history
    PaymentRecord.where(customer: @customer)
                 .where.not(invoice_id: nil)
                 .includes(:invoice)
                 .order(payment_date: :desc, created_at: :desc)
  end

  # 入金履歴を元入金IDでグループ化して取得
  def payment_history_grouped
    # 消し込み記録（invoice_idがNULLでない）を取得
    allocation_records = PaymentRecord.where(customer: @customer)
                                      .where.not(invoice_id: nil)
                                      .includes(:invoice)
                                      .order(payment_date: :desc, created_at: :desc)

    # 元入金IDでグループ化
    grouped_records = {}

    allocation_records.each do |record|
      # notesから元入金IDを抽出
      original_payment_id = extract_original_payment_id(record.notes)
      next unless original_payment_id

      if grouped_records[original_payment_id]
        grouped_records[original_payment_id][:invoice_numbers] << {
          number: record.invoice.invoice_number,
          id: record.invoice.id
        }
      else
        # 元入金記録を取得
        original_payment = PaymentRecord.find_by(id: original_payment_id, customer: @customer)
        next unless original_payment

        grouped_records[original_payment_id] = {
          payment_id: original_payment_id,
          payment_date: original_payment.payment_date,
          category: original_payment.category,
          amount: original_payment.amount,
          notes: original_payment.notes,
          invoice_numbers: [ {
            number: record.invoice.invoice_number,
            id: record.invoice.id
          } ]
        }
      end
    end

    # 配列に変換してソート
    grouped_records.values.sort_by { |record| [ record[:payment_date], record[:payment_id] ] }.reverse
  end

  # 入金記録の更新（金額変更時の請求書調整含む）
  def update_payment_with_invoice_adjustment(payment_record, params)
    ActiveRecord::Base.transaction do
      new_amount = params[:amount].to_i

      # 既存の充当記録を削除
      delete_allocation_records(payment_record)

      # 入金記録を更新
      payment_record.update!(
        payment_date: params[:payment_date],
        category: params[:category],
        amount: new_amount,
        notes: params[:notes],
        paid_amount: 0 # 一旦0にリセット
      )

      # 新しい金額で充当処理を実行
      if new_amount > 0
        remaining_amount = new_amount
        unpaid_invoices_list = unpaid_invoices

        unpaid_invoices_list.each do |invoice|
          break if remaining_amount <= 0

          total_amount = invoice.total_amount
          already_paid_amount = invoice.total_paid_amount
          unpaid_amount = total_amount - already_paid_amount

          next if unpaid_amount <= 0

          paid_amount = [ remaining_amount, unpaid_amount ].min

          # この請求書への充当記録を作成
          allocation_record = PaymentRecord.new(
            invoice: invoice,
            customer: @customer,
            payment_date: params[:payment_date],
            category: params[:category],
            amount: paid_amount,
            paid_amount: paid_amount,
            notes: "消し込み（元入金ID: #{payment_record.id}）"
          )

          unless allocation_record.save
            Rails.logger.error "Allocation record validation failed: #{allocation_record.errors.full_messages}"
            raise ActiveRecord::RecordInvalid.new(allocation_record)
          end

          remaining_amount -= paid_amount
        end

        # 元の入金記録のpaid_amountを更新
        payment_record.update!(paid_amount: new_amount - remaining_amount)
      end
    end
  end

  # 入金記録の削除（請求書調整含む）
  def delete_payment_with_invoice_adjustment(payment_record)
    ActiveRecord::Base.transaction do
      # 既存の充当記録を削除
      delete_allocation_records(payment_record)

      # 元の入金記録を削除
      payment_record.destroy!
    end
  end

  private

  def extract_original_payment_id(notes)
    return nil unless notes.present?

    match = notes.match(/消し込み（元入金ID: (\d+)）/)
    match ? match[1].to_i : nil
  end

  def delete_allocation_records(payment_record)
    # この入金記録に関連する充当記録を削除
    PaymentRecord.where(customer: @customer)
                 .where("notes LIKE ?", "%消し込み（元入金ID: #{payment_record.id}）%")
                 .destroy_all
  end
end
