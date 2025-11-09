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
        "customerSelect", "invoicesCard", "paymentCard", "invoicesTableBody",
        "amountInput", "customerIdField", "confirmButton", "allocationSummary",
        "loadingSpinner", "paymentForm", "invoiceButtons", "invoicesTitle",
        "unpaidButton", "paidButton", "historyButton", "tableHeader"
      ];

      connect() {
        console.log('PaymentManagementController connected');
        this.unpaidInvoices = [];
        this.allocationResults = [];
        this.paymentHistory = [];
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
        } else {
          console.log('Disabling buttons');
          this.disableButtons();
          this.hideInvoicesCard();
          this.hidePaymentCard();
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
          const data = await response.json();

          if (data.success) {
            this.unpaidInvoices = data.invoices;
            this.invoicesTitleTarget.textContent = data.title;
            this.displayInvoices(true); // 未入金請求書なので充当カラムを表示
            this.showInvoicesCard();
            this.showPaymentCard();
          } else {
            console.error('Server error:', data.error);
            this.unpaidInvoices = [];
            this.invoicesTitleTarget.textContent = '未入金請求書一覧';
            this.displayInvoices(true); // 未入金請求書なので充当カラムを表示
            this.showInvoicesCard();
            this.showPaymentCard();
          }
        } catch (error) {
          console.error('Error loading unpaid invoices:', error);
          this.unpaidInvoices = [];
          this.invoicesTitleTarget.textContent = '未入金請求書一覧';
          this.displayInvoices(true); // 未入金請求書なので充当カラムを表示
          this.showInvoicesCard();
          this.hidePaymentCard();
          alert('未入金請求書の取得中にエラーが発生しました');
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
        const amount = parseInt(this.amountInputTarget.value) || 0;

        if (amount <= 0) {
          this.clearAllocation();
          this.confirmButtonTarget.disabled = true;
          return;
        }

        this.allocationResults = [];
        let remainingAmount = amount;

        this.unpaidInvoices.forEach((invoice, index) => {
          if (remainingAmount <= 0) return;

          const totalAmount = invoice.total_amount;
          const alreadyPaidAmount = invoice.paid_amount;
          const unpaidAmount = totalAmount - alreadyPaidAmount;

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
        this.updateAllocationSummary(amount, remainingAmount);

        this.confirmButtonTarget.disabled = false;
      }

      updateAllocationDisplay() {
        const rows = this.invoicesTableBodyTarget.querySelectorAll('tr');

        rows.forEach((row, index) => {
          const allocationCell = row.querySelector('[data-allocation-amount]');
          const remainingCell = row.querySelector('[data-remaining-after]');

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

      confirmPayment() {
        if (!this.confirmButtonTarget.disabled) {
          const amount = parseInt(this.amountInputTarget.value) || 0;
          if (amount <= 0) {
            alert('入金額を正しく入力してください');
            return;
          }

          this.paymentFormTarget.submit();
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

