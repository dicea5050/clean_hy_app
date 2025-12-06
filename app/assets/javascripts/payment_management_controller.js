// Stimulusコントローラー: 入金管理
// 通常のJavaScript形式で記述（ES6モジュール形式から変換）

(function() {
  'use strict';

  let controllerRegistered = false;

  // Stimulusが読み込まれるまで待機
  function registerController() {
    // 既に登録済みの場合はスキップ
    if (controllerRegistered) {
      return;
    }

    if (typeof window.Stimulus === 'undefined' || !window.StimulusLoaded) {
      console.log('Waiting for Stimulus...');
      setTimeout(registerController, 100);
      return;
    }

    console.log('Stimulus found, registering controller...');
    const Application = window.Stimulus;
    const Controller = window.StimulusController;

    if (!Controller) {
      console.error('StimulusController is not available');
      return;
    }

    class PaymentManagementController extends Controller {
      static targets = [
        "customerSelect", "customerCodeInput", "invoicesCard", "paymentCard", "invoicesTableBody",
        "amountInput", "customerIdField", "confirmButton", "allocationSummary",
        "loadingSpinner", "paymentForm", "invoiceButtons", "invoicesTitle",
        "unpaidButton", "paidButton", "historyButton", "tableHeader",
        "paymentRowsContainer", "paymentRow", "totalAmount"
      ];

      connect() {
        console.log('PaymentManagementController connected');
        this.unpaidInvoices = [];
        this.allocationResults = [];
        this.paymentHistory = [];
        
        // 顧客コード・取引先名連動機能を初期化（共通コードを使用）
        if (window.CustomerCodeSearch) {
          const controller = this;
          window.CustomerCodeSearch.init({
            customerCodeSelector: '#' + this.customerCodeInputTarget.id,
            customerSelectSelector: '#' + this.customerSelectTarget.id,
            customerIdSelector: this.hasCustomerIdFieldTarget ? '#' + this.customerIdFieldTarget.id : null,
            findCustomerApiUrl: '/payment_management/find_customer_by_code',
            enableSelect2: true,
            onCustomerChange: function(customerId, customerData) {
              // Stimulusのchangeイベントを発火
              const event = new Event('change', { bubbles: true });
              controller.customerSelectTarget.dispatchEvent(event);
            },
            onCustomerClear: function() {
              // Stimulusのchangeイベントを発火
              const event = new Event('change', { bubbles: true });
              controller.customerSelectTarget.dispatchEvent(event);
            }
          });
        }
      }

      disconnect() {
        // select2を破棄
        if (this.customerSelectTarget && typeof $ !== 'undefined' && $.fn.select2) {
          if ($(this.customerSelectTarget).hasClass('select2-hidden-accessible')) {
            $(this.customerSelectTarget).select2('destroy');
          }
        }
      }

      onCustomerChange() {
        console.log('onCustomerChange called');
        const customerId = this.customerSelectTarget.value;
        console.log('Customer ID:', customerId);

        if (customerId) {
          console.log('Enabling buttons');
          this.enableButtons();
          if (this.hasCustomerIdFieldTarget) {
            this.customerIdFieldTarget.value = customerId;
          }
          // 顧客コードフィールドも更新（選択された顧客のコードを表示）
          this.updateCustomerCodeFromSelect(customerId);
        } else {
          console.log('Disabling buttons');
          this.disableButtons();
          this.hideInvoicesCard();
          this.hidePaymentCard();
          // 取引先名がクリアされたら顧客コードもクリア
          if (this.hasCustomerCodeInputTarget) {
            this.customerCodeInputTarget.value = '';
          }
          if (this.hasCustomerIdFieldTarget) {
            this.customerIdFieldTarget.value = '';
          }
        }
      }

      // 顧客コード入力時の処理（共通コードで処理されるため、このメソッドは不要だが後方互換性のため残す）
      onCustomerCodeBlur() {
        // 共通コードで処理されるため、ここでは何もしない
        // 必要に応じて追加の処理を記述可能
      }

      // selectから顧客コードを更新（共通コードで処理されるため、このメソッドは不要だが後方互換性のため残す）
      updateCustomerCodeFromSelect(customerId) {
        // 共通コードで処理されるため、ここでは何もしない
        // 必要に応じて追加の処理を記述可能
      }

      // メッセージ表示用のヘルパーメソッド
      showMessage(message, type) {
        // 簡単なアラートで表示（必要に応じてBootstrapのトーストなどに変更可能）
        if (type === 'success') {
          console.log('Success:', message);
          // 必要に応じてBootstrapのアラートを表示
        } else {
          console.error('Error:', message);
          alert(message);
        }
      }

      async loadUnpaidInvoices() {
        const customerId = this.customerSelectTarget.value;

        if (!customerId) {
          this.hideInvoicesCard();
          this.hidePaymentCard();
          return;
        }

        this.showLoading();

        try {
          const response = await fetch(`/payment_management/unpaid_invoices?customer_id=${customerId}`);
          
          // レスポンスのステータスコードをチェック
          if (!response.ok) {
            const errorText = await response.text();
            console.error('HTTP error response:', response.status, errorText);
            throw new Error(`HTTP error! status: ${response.status}`);
          }

          // Content-Typeをチェック
          const contentType = response.headers.get('content-type');
          if (!contentType || !contentType.includes('application/json')) {
            const text = await response.text();
            console.error('Response is not JSON:', contentType, text);
            throw new Error('Response is not JSON');
          }

          let data;
          try {
            data = await response.json();
          } catch (parseError) {
            const text = await response.text();
            console.error('JSON parse error:', parseError, 'Response text:', text);
            throw new Error('Failed to parse JSON response');
          }

          if (data.success) {
            this.unpaidInvoices = data.invoices || [];
            this.invoicesTitleTarget.textContent = data.title || '未入金請求書一覧';
            this.displayInvoices(true); // 未入金請求書なので充当カラムを表示
            this.showInvoicesCard();
            this.showPaymentCard();
          } else {
            // サーバー側でエラーが返された場合でも、空の配列として表示（正常な状態）
            console.warn('Server returned error:', data.error);
            this.unpaidInvoices = [];
            this.invoicesTitleTarget.textContent = '未入金請求書一覧';
            this.displayInvoices(true); // 未入金請求書なので充当カラムを表示
            this.showInvoicesCard();
            this.showPaymentCard();
          }
        } catch (error) {
          // ネットワークエラーやJSONパースエラーの場合のみアラートを表示
          console.error('Error loading unpaid invoices:', error);
          this.unpaidInvoices = [];
          this.invoicesTitleTarget.textContent = '未入金請求書一覧';
          this.displayInvoices(true); // 未入金請求書なので充当カラムを表示
          this.showInvoicesCard();
          this.hidePaymentCard();
          // ネットワークエラーやパースエラーの場合のみアラートを表示
          // ただし、空の配列が返された場合は正常な状態なのでアラートを表示しない
          if (error instanceof TypeError || error.message.includes('HTTP error') || error.message.includes('JSON')) {
            console.error('Critical error occurred:', error);
            // 実際のエラーの場合のみアラートを表示
            alert('未入金請求書の取得中にエラーが発生しました');
          }
        } finally {
          this.hideLoading();
        }
      }

      async loadPaidInvoices() {
        const customerId = this.customerSelectTarget.value;

        if (!customerId) {
          this.hideInvoicesCard();
          this.hidePaymentCard();
          return;
        }

        this.showLoading();

        try {
          const response = await fetch(`/payment_management/paid_invoices?customer_id=${customerId}`);
          const data = await response.json();

          if (data.success) {
            this.unpaidInvoices = data.invoices;
            this.invoicesTitleTarget.textContent = data.title;
            this.displayInvoices(false); // 入金済み請求書なので充当カラムを非表示
            this.showInvoicesCard();
            this.hidePaymentCard();
          } else {
            console.error('Server error:', data.error);
            this.unpaidInvoices = [];
            this.invoicesTitleTarget.textContent = '入金済み請求書一覧';
            this.displayInvoices(false); // 入金済み請求書なので充当カラムを非表示
            this.showInvoicesCard();
            this.hidePaymentCard();
          }
        } catch (error) {
          console.error('Error loading paid invoices:', error);
          this.unpaidInvoices = [];
          this.invoicesTitleTarget.textContent = '入金済み請求書一覧';
          this.displayInvoices(false); // 入金済み請求書なので充当カラムを非表示
          this.showInvoicesCard();
          this.hidePaymentCard();
          alert('入金済み請求書の取得中にエラーが発生しました');
        } finally {
          this.hideLoading();
        }
      }

      async loadPaymentHistory() {
        const customerId = this.customerSelectTarget.value;

        if (!customerId) {
          this.hideInvoicesCard();
          this.hidePaymentCard();
          return;
        }

        this.showLoading();

        try {
          const response = await fetch(`/payment_management/payment_history?customer_id=${customerId}`);
          const data = await response.json();

          if (data.success) {
            this.paymentHistory = data.payment_history;
            this.invoicesTitleTarget.textContent = data.title;
            this.displayPaymentHistory();
            this.showInvoicesCard();
            this.hidePaymentCard();
          } else {
            console.error('Server error:', data.error);
            this.paymentHistory = [];
            this.invoicesTitleTarget.textContent = '入金履歴一覧';
            this.displayPaymentHistory();
            this.showInvoicesCard();
            this.hidePaymentCard();
          }
        } catch (error) {
          console.error('Error loading payment history:', error);
          this.paymentHistory = [];
          this.invoicesTitleTarget.textContent = '入金履歴一覧';
          this.displayPaymentHistory();
          this.showInvoicesCard();
          this.hidePaymentCard();
          alert('入金履歴の取得中にエラーが発生しました');
        } finally {
          this.hideLoading();
        }
      }

      displayInvoices(showAllocationColumns = false) {
        // 未入金請求書の場合は充当カラムを表示、入金済み請求書の場合は非表示
        const headerHTML = showAllocationColumns ? `
          <tr>
            <th>入金ID</th>
            <th>請求書番号</th>
            <th>請求日</th>
            <th>請求金額（税込）</th>
            <th>入金済み額</th>
            <th>未入金額</th>
            <th>充当予定額</th>
            <th>充当後残高</th>
            <th>元入金ID</th>
          </tr>
        ` : `
          <tr>
            <th>入金ID</th>
            <th>請求書番号</th>
            <th>請求日</th>
            <th>請求金額（税込）</th>
            <th>入金済み額</th>
            <th>未入金額</th>
            <th>元入金ID</th>
          </tr>
        `;

        this.tableHeaderTarget.innerHTML = headerHTML;

        const tbody = this.invoicesTableBodyTarget;
        tbody.innerHTML = '';

        if (this.unpaidInvoices.length === 0) {
          const colspan = showAllocationColumns ? 9 : 7;
          const row = document.createElement('tr');
          row.innerHTML = `
            <td colspan="${colspan}" class="text-center text-muted py-4">
              未入金の請求書はありません
            </td>
          `;
          tbody.appendChild(row);
          return;
        }

        this.unpaidInvoices.forEach(invoice => {
          const row = document.createElement('tr');
          const invoiceLink = `<a href="/invoices/${invoice.id}" class="text-decoration-none">${invoice.invoice_number}</a>`;
          const paymentIds = invoice.payment_ids ? invoice.payment_ids.join(', ') : '-';
          const originalPaymentIds = invoice.original_payment_ids && invoice.original_payment_ids.length > 0
            ? invoice.original_payment_ids.join(', ')
            : '-';

          const rowHTML = showAllocationColumns ? `
            <td class="text-center">${paymentIds}</td>
            <td>${invoiceLink}</td>
            <td>${this.formatDate(invoice.invoice_date)}</td>
            <td class="text-end">¥${this.formatNumber(invoice.total_amount)}</td>
            <td class="text-end">¥${this.formatNumber(invoice.paid_amount)}</td>
            <td class="text-end">¥${this.formatNumber(invoice.remaining_amount)}</td>
            <td class="text-end" data-allocation-amount="0">¥0</td>
            <td class="text-end" data-remaining-after="0">¥${this.formatNumber(invoice.remaining_amount)}</td>
            <td class="text-center">${originalPaymentIds}</td>
          ` : `
            <td class="text-center">${paymentIds}</td>
            <td>${invoiceLink}</td>
            <td>${this.formatDate(invoice.invoice_date)}</td>
            <td class="text-end">¥${this.formatNumber(invoice.total_amount)}</td>
            <td class="text-end">¥${this.formatNumber(invoice.paid_amount)}</td>
            <td class="text-end">¥${this.formatNumber(invoice.remaining_amount)}</td>
            <td class="text-center">${originalPaymentIds}</td>
          `;

          row.innerHTML = rowHTML;
          tbody.appendChild(row);
        });
      }

      displayPaymentHistory() {
        this.tableHeaderTarget.innerHTML = `
          <tr>
            <th>入金ID</th>
            <th>入金日</th>
            <th>入金種別</th>
            <th>入金額</th>
            <th>消し込み先請求書番号</th>
            <th>備考</th>
            <th>操作</th>
          </tr>
        `;

        const tbody = this.invoicesTableBodyTarget;
        tbody.innerHTML = '';

        if (this.paymentHistory.length === 0) {
          const row = document.createElement('tr');
          row.innerHTML = `
            <td colspan="7" class="text-center text-muted py-4">
              入金履歴はありません
            </td>
          `;
          tbody.appendChild(row);
          return;
        }

        this.paymentHistory.forEach(payment => {
          const row = document.createElement('tr');

          const invoiceLinks = payment.invoice_numbers.map(inv =>
            `<a href="/invoices/${inv.id}" class="text-decoration-none">${inv.number}</a>`
          ).join(', ');

          row.innerHTML = `
            <td class="text-center">${payment.payment_id}</td>
            <td>${this.formatDate(payment.payment_date)}</td>
            <td>${payment.category}</td>
            <td class="text-end">¥${this.formatNumber(payment.amount)}</td>
            <td>${invoiceLinks}</td>
            <td>${payment.notes || '-'}</td>
            <td class="text-center">
              <div class="btn-group btn-group-sm" role="group">
                <a href="/payment_management/${payment.payment_id}/edit" class="btn btn-primary btn-sm">
                  編集
                </a>
                <button type="button" class="btn btn-danger btn-sm"
                        onclick="window.deletePayment(${payment.payment_id})">
                  削除
                </button>
              </div>
            </td>
          `;
          tbody.appendChild(row);
        });
      }

      calculateAllocation() {
        // 全行の入金額を合算
        const totalAmount = this.getTotalPaymentAmount();

        if (totalAmount <= 0) {
          this.clearAllocation();
          this.confirmButtonTarget.disabled = true;
          this.updateTotalAmountDisplay(0);
          return;
        }

        // 未入金請求書がない場合は、充当表示を更新しない
        if (!this.unpaidInvoices || this.unpaidInvoices.length === 0) {
          this.updateTotalAmountDisplay(totalAmount);
          this.confirmButtonTarget.disabled = true;
          return;
        }

        this.updateTotalAmountDisplay(totalAmount);

        this.allocationResults = [];
        let remainingAmount = totalAmount;

        this.unpaidInvoices.forEach((invoice, index) => {
          if (remainingAmount <= 0) return;

          const invoiceTotalAmount = invoice.total_amount;
          const alreadyPaidAmount = invoice.paid_amount;
          const unpaidAmount = invoiceTotalAmount - alreadyPaidAmount;

          if (unpaidAmount <= 0) return;

          const paidAmount = Math.min(remainingAmount, unpaidAmount);
          const newRemaining = unpaidAmount - paidAmount;

          this.allocationResults.push({
            index: index,
            paidAmount: paidAmount,
            newRemaining: newRemaining
          });

          remainingAmount -= paidAmount;
        });

        this.updateAllocationDisplay();
        this.updateAllocationSummary(totalAmount, remainingAmount);

        // 全行が有効な場合のみ登録ボタンを有効化
        this.confirmButtonTarget.disabled = !this.validatePaymentRows();
      }

      updateAllocationDisplay() {
        const rows = this.invoicesTableBodyTarget.querySelectorAll('tr');

        rows.forEach((row, index) => {
          const allocationCell = row.querySelector('[data-allocation-amount]');
          const remainingCell = row.querySelector('[data-remaining-after]');

          // 要素が存在しない場合はスキップ（未入金請求書がない場合など）
          if (!allocationCell || !remainingCell) {
            return;
          }

          if (this.allocationResults[index]) {
            const result = this.allocationResults[index];
            allocationCell.textContent = `¥${this.formatNumber(result.paidAmount)}`;
            remainingCell.textContent = `¥${this.formatNumber(result.newRemaining)}`;

            if (result.paidAmount > 0) {
              allocationCell.classList.add('text-success', 'fw-bold');
              remainingCell.classList.add(result.newRemaining === 0 ? 'text-success' : 'text-warning');
            } else {
              allocationCell.classList.remove('text-success', 'fw-bold');
              remainingCell.classList.remove('text-success', 'text-warning');
            }
          } else {
            allocationCell.textContent = '¥0';
            allocationCell.classList.remove('text-success', 'fw-bold');
            remainingCell.classList.remove('text-success', 'text-warning');
          }
        });
      }

      updateAllocationSummary(totalAmount, remainingAmount) {
        const summary = this.allocationSummaryTarget;
        const allocatedAmount = totalAmount - remainingAmount;

        summary.innerHTML = `
          <strong>充当結果:</strong>
          総入金額: ¥${this.formatNumber(totalAmount)} |
          充当額: ¥${this.formatNumber(allocatedAmount)} |
          未充当: ¥${this.formatNumber(remainingAmount)}
        `;
        summary.classList.remove('d-none');
      }

      clearAllocation() {
        this.allocationResults = [];
        this.updateAllocationDisplay();
        this.allocationSummaryTarget.classList.add('d-none');
      }

      addPaymentRow() {
        const container = this.paymentRowsContainerTarget;
        const firstRow = container.querySelector('.payment-row');
        const newRow = firstRow.cloneNode(true);

        // 新しい行の入力値をクリア
        newRow.querySelector('.payment-date').value = new Date().toISOString().split('T')[0];
        newRow.querySelector('.payment-category').value = '';
        newRow.querySelector('.payment-amount').value = '';
        newRow.querySelector('.payment-notes').value = '';

        // 削除ボタンを表示
        const removeBtn = newRow.querySelector('.remove-row-btn');
        if (removeBtn) {
          removeBtn.style.display = 'block';
        }

        // 削除ボタンにイベントリスナーを追加
        removeBtn.addEventListener('click', () => {
          this.removePaymentRow(event);
        });

        // 入力フィールドにイベントリスナーを追加
        newRow.querySelector('.payment-amount').addEventListener('input', () => {
          this.calculateAllocation();
        });
        newRow.querySelector('.payment-date').addEventListener('change', () => {
          this.calculateAllocation();
        });
        newRow.querySelector('.payment-category').addEventListener('change', () => {
          this.calculateAllocation();
        });

        container.appendChild(newRow);

        // 最初の行の削除ボタンも表示
        const firstRemoveBtn = firstRow.querySelector('.remove-row-btn');
        if (firstRemoveBtn && container.querySelectorAll('.payment-row').length > 1) {
          firstRemoveBtn.style.display = 'block';
        }

        this.calculateAllocation();
      }

      removePaymentRow(event) {
        const row = event.currentTarget.closest('.payment-row');
        const container = this.paymentRowsContainerTarget;
        const rows = container.querySelectorAll('.payment-row');

        // 最後の1行は削除できない
        if (rows.length <= 1) {
          alert('最低1行は必要です');
          return;
        }

        row.remove();

        // 残りの行が1行になったら削除ボタンを非表示
        const remainingRows = container.querySelectorAll('.payment-row');
        if (remainingRows.length === 1) {
          const removeBtn = remainingRows[0].querySelector('.remove-row-btn');
          if (removeBtn) {
            removeBtn.style.display = 'none';
          }
        }

        this.calculateAllocation();
      }

      getTotalPaymentAmount() {
        const rows = this.paymentRowsContainerTarget.querySelectorAll('.payment-row');
        let total = 0;

        rows.forEach(row => {
          const amountInput = row.querySelector('.payment-amount');
          const amount = parseInt(amountInput.value) || 0;
          total += amount;
        });

        return total;
      }

      updateTotalAmountDisplay(totalAmount) {
        if (this.hasTotalAmountTarget) {
          this.totalAmountTarget.textContent = `¥${this.formatNumber(totalAmount)}`;
        }
      }

      validatePaymentRows() {
        const rows = this.paymentRowsContainerTarget.querySelectorAll('.payment-row');
        
        for (let row of rows) {
          const date = row.querySelector('.payment-date').value;
          const category = row.querySelector('.payment-category').value;
          const amount = parseInt(row.querySelector('.payment-amount').value) || 0;

          // 入金額が入力されている行は、日付と種別も必須
          if (amount > 0) {
            if (!date || !category) {
              return false;
            }
          }
        }

        return this.getTotalPaymentAmount() > 0;
      }

      confirmPayment() {
        if (!this.confirmButtonTarget.disabled) {
          const totalAmount = this.getTotalPaymentAmount();
          if (totalAmount <= 0) {
            alert('入金額を正しく入力してください');
            return;
          }

          if (!this.validatePaymentRows()) {
            alert('入金額が入力されている行は、入金日と入金種別も入力してください');
            return;
          }

          // 複数の入金を一度に送信するため、フォームを動的に構築
          this.submitMultiplePayments();
        }
      }

      submitMultiplePayments() {
        const rows = this.paymentRowsContainerTarget.querySelectorAll('.payment-row');
        const customerId = this.customerIdFieldTarget.value;

        if (!customerId) {
          alert('取引先が選択されていません');
          return;
        }

        // 入金額が入力されている行のみを取得
        const paymentRows = Array.from(rows).filter(row => {
          const amount = parseInt(row.querySelector('.payment-amount').value) || 0;
          return amount > 0;
        });

        if (paymentRows.length === 0) {
          alert('入金額を入力してください');
          return;
        }

        // 確認ダイアログ
        const totalAmount = this.getTotalPaymentAmount();
        if (!confirm(`${paymentRows.length}件の入金を登録しますか？\n合計金額: ¥${this.formatNumber(totalAmount)}`)) {
          return;
        }

        // 各入金を順次送信
        this.submitPaymentsSequentially(paymentRows, customerId, 0);
      }

      async submitPaymentsSequentially(paymentRows, customerId, index) {
        if (index >= paymentRows.length) {
          // 全ての入金が完了したらリロード
          window.location.reload();
          return;
        }

        const row = paymentRows[index];
        const paymentDate = row.querySelector('.payment-date').value;
        const category = row.querySelector('.payment-category').value;
        const amount = parseInt(row.querySelector('.payment-amount').value) || 0;
        const notes = row.querySelector('.payment-notes').value || '';

        // フォームデータを作成
        const formData = new FormData();
        formData.append('payment[payment_date]', paymentDate);
        formData.append('payment[category]', category);
        formData.append('payment[amount]', amount);
        formData.append('payment[notes]', notes);
        formData.append('payment[customer_id]', customerId);

        // CSRFトークンを取得
        const token = document.querySelector('meta[name="csrf-token"]').getAttribute('content');

        try {
          const response = await fetch(this.paymentFormTarget.action, {
            method: 'POST',
            headers: {
              'X-CSRF-Token': token,
              'Accept': 'application/json'
            },
            body: formData
          });

          const data = await response.json();

          if (response.ok && data.success) {
            console.log(`入金 ${index + 1}/${paymentRows.length} を登録しました: ${data.message}`);
            // 次の入金を送信
            this.submitPaymentsSequentially(paymentRows, customerId, index + 1);
          } else {
            throw new Error(data.error || '入金の登録に失敗しました');
          }
        } catch (error) {
          console.error('Payment submission error:', error);
          alert(`入金 ${index + 1}/${paymentRows.length} の登録中にエラーが発生しました: ${error.message}`);
        }
      }

      showInvoicesCard() {
        this.invoicesCardTarget.classList.remove('d-none');
      }

      hideInvoicesCard() {
        this.invoicesCardTarget.classList.add('d-none');
      }

      showPaymentCard() {
        this.paymentCardTarget.classList.remove('d-none');
        // 最初の行の削除ボタンを非表示
        const firstRow = this.paymentRowsContainerTarget.querySelector('.payment-row');
        if (firstRow) {
          const removeBtn = firstRow.querySelector('.remove-row-btn');
          if (removeBtn) {
            removeBtn.style.display = 'none';
          }
        }
        // 合計金額をリセット
        this.calculateAllocation();
      }

      hidePaymentCard() {
        this.paymentCardTarget.classList.add('d-none');
      }

      showLoading() {
        this.loadingSpinnerTarget.classList.remove('d-none');
      }

      hideLoading() {
        this.loadingSpinnerTarget.classList.add('d-none');
      }

      enableButtons() {
        if (this.hasUnpaidButtonTarget) {
          this.unpaidButtonTarget.disabled = false;
        }
        if (this.hasPaidButtonTarget) {
          this.paidButtonTarget.disabled = false;
        }
        if (this.hasHistoryButtonTarget) {
          this.historyButtonTarget.disabled = false;
        }
      }

      disableButtons() {
        if (this.hasUnpaidButtonTarget) {
          this.unpaidButtonTarget.disabled = true;
        }
        if (this.hasPaidButtonTarget) {
          this.paidButtonTarget.disabled = true;
        }
        if (this.hasHistoryButtonTarget) {
          this.historyButtonTarget.disabled = true;
        }
      }

      formatNumber(num) {
        return new Intl.NumberFormat('ja-JP').format(num);
      }

      formatDate(dateString) {
        if (!dateString) return '-';
        const date = new Date(dateString);
        return date.toLocaleDateString('ja-JP');
      }
    }

    // コントローラーを登録
    try {
      Application.register("payment-management", PaymentManagementController);
      controllerRegistered = true;
      console.log('PaymentManagementController registered successfully');
    } catch (error) {
      console.error('Error registering PaymentManagementController:', error);
    }
  }

  // Stimulus読み込み完了イベントをリッスン
  window.addEventListener('stimulus:loaded', registerController);

  // ページ読み込み時にコントローラーを登録（Stimulusが既に読み込まれている場合）
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', function() {
      // DOMContentLoaded後も少し待ってから登録を試みる
      setTimeout(registerController, 100);
    });
  } else {
    // 既にDOMが読み込まれている場合
    setTimeout(registerController, 100);
  }

  // グローバル関数として削除確認ダイアログを定義
  window.deletePayment = function(paymentId) {
    if (confirm('この入金記録を削除しますか？\n\n削除すると、関連する請求書への充当も取り消されます。\nこの操作は元に戻せません。')) {
      const form = document.createElement('form');
      form.method = 'POST';
      form.action = `/payment_management/${paymentId}`;

      const methodInput = document.createElement('input');
      methodInput.type = 'hidden';
      methodInput.name = '_method';
      methodInput.value = 'DELETE';

      const tokenInput = document.createElement('input');
      tokenInput.type = 'hidden';
      tokenInput.name = 'authenticity_token';
      tokenInput.value = document.querySelector('meta[name="csrf-token"]').getAttribute('content');

      form.appendChild(methodInput);
      form.appendChild(tokenInput);

      document.body.appendChild(form);
      form.submit();
    }
  };
})();

