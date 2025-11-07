// 入金管理機能のjQuery実装
$(document).ready(function() {
  let unpaidInvoices = [];
  let allocationResults = [];
  let paymentHistory = [];

  // 未入金請求書を読み込む
  function loadUnpaidInvoices(customerId) {
    if (!customerId) {
      $('[data-payment-management-target="invoicesCard"]').hide();
      $('[data-payment-management-target="paymentCard"]').hide();
      return;
    }

    $('[data-payment-management-target="loadingSpinner"]').show();

    $.ajax({
      url: '/payment_management/unpaid_invoices',
      method: 'GET',
      data: { customer_id: customerId },
      dataType: 'json',
      success: function(data) {
        if (data.success) {
          unpaidInvoices = data.invoices;
          $('[data-payment-management-target="invoicesTitle"]').text(data.title);
          displayInvoices();
          $('[data-payment-management-target="invoicesCard"]').show();
          $('[data-payment-management-target="paymentCard"]').show();
        } else {
          console.error('Server error:', data.error);
          unpaidInvoices = [];
          $('[data-payment-management-target="invoicesTitle"]').text('未入金請求書一覧');
          displayInvoices();
          $('[data-payment-management-target="invoicesCard"]').show();
          $('[data-payment-management-target="paymentCard"]').show();
        }
      },
      error: function(xhr, status, error) {
        console.error('Error loading unpaid invoices:', error);
        unpaidInvoices = [];
        $('[data-payment-management-target="invoicesTitle"]').text('未入金請求書一覧');
        displayInvoices();
        $('[data-payment-management-target="invoicesCard"]').show();
        $('[data-payment-management-target="paymentCard"]').hide();
        alert('未入金請求書の取得中にエラーが発生しました');
      },
      complete: function() {
        $('[data-payment-management-target="loadingSpinner"]').hide();
      }
    });
  }

  // 入金済み請求書を読み込む
  function loadPaidInvoices(customerId) {
    if (!customerId) {
      $('[data-payment-management-target="invoicesCard"]').hide();
      $('[data-payment-management-target="paymentCard"]').hide();
      return;
    }

    $('[data-payment-management-target="loadingSpinner"]').show();

    $.ajax({
      url: '/payment_management/paid_invoices',
      method: 'GET',
      data: { customer_id: customerId },
      dataType: 'json',
      success: function(data) {
        if (data.success) {
          unpaidInvoices = data.invoices;
          $('[data-payment-management-target="invoicesTitle"]').text(data.title);
          displayInvoices();
          $('[data-payment-management-target="invoicesCard"]').show();
          $('[data-payment-management-target="paymentCard"]').hide();
        } else {
          console.error('Server error:', data.error);
          unpaidInvoices = [];
          $('[data-payment-management-target="invoicesTitle"]').text('入金済み請求書一覧');
          displayInvoices();
          $('[data-payment-management-target="invoicesCard"]').show();
          $('[data-payment-management-target="paymentCard"]').hide();
        }
      },
      error: function(xhr, status, error) {
        console.error('Error loading paid invoices:', error);
        unpaidInvoices = [];
        $('[data-payment-management-target="invoicesTitle"]').text('入金済み請求書一覧');
        displayInvoices();
        $('[data-payment-management-target="invoicesCard"]').show();
        $('[data-payment-management-target="paymentCard"]').hide();
        alert('入金済み請求書の取得中にエラーが発生しました');
      },
      complete: function() {
        $('[data-payment-management-target="loadingSpinner"]').hide();
      }
    });
  }

  // 入金履歴を読み込む
  function loadPaymentHistory(customerId) {
    if (!customerId) {
      $('[data-payment-management-target="invoicesCard"]').hide();
      $('[data-payment-management-target="paymentCard"]').hide();
      return;
    }

    $('[data-payment-management-target="loadingSpinner"]').show();

    $.ajax({
      url: '/payment_management/payment_history',
      method: 'GET',
      data: { customer_id: customerId },
      dataType: 'json',
      success: function(data) {
        if (data.success) {
          paymentHistory = data.payment_history;
          $('[data-payment-management-target="invoicesTitle"]').text(data.title);
          displayPaymentHistory();
          $('[data-payment-management-target="invoicesCard"]').show();
          $('[data-payment-management-target="paymentCard"]').hide();
        } else {
          console.error('Server error:', data.error);
          paymentHistory = [];
          $('[data-payment-management-target="invoicesTitle"]').text('入金履歴一覧');
          displayPaymentHistory();
          $('[data-payment-management-target="invoicesCard"]').show();
          $('[data-payment-management-target="paymentCard"]').hide();
        }
      },
      error: function(xhr, status, error) {
        console.error('Error loading payment history:', error);
        paymentHistory = [];
        $('[data-payment-management-target="invoicesTitle"]').text('入金履歴一覧');
        displayPaymentHistory();
        $('[data-payment-management-target="invoicesCard"]').show();
        $('[data-payment-management-target="paymentCard"]').hide();
        alert('入金履歴の取得中にエラーが発生しました');
      },
      complete: function() {
        $('[data-payment-management-target="loadingSpinner"]').hide();
      }
    });
  }

  // 請求書一覧を表示
  function displayInvoices() {
    const $tableHeader = $('[data-payment-management-target="tableHeader"]');
    const $tbody = $('[data-payment-management-target="invoicesTableBody"]');

    $tableHeader.html(`
      <tr>
        <th>請求書番号</th>
        <th>請求日</th>
        <th>請求金額（税込）</th>
        <th>入金済み額</th>
        <th>未入金額</th>
        <th>充当予定額</th>
        <th>充当後残高</th>
        <th>入金ID</th>
      </tr>
    `);

    $tbody.empty();

    if (unpaidInvoices.length === 0) {
      $tbody.append(`
        <tr>
          <td colspan="8" class="text-center text-muted py-4">
            未入金の請求書はありません
          </td>
        </tr>
      `);
      return;
    }

    unpaidInvoices.forEach(function(invoice) {
      const invoiceLink = `<a href="/invoices/${invoice.id}" class="text-decoration-none">${invoice.invoice_number}</a>`;
      const paymentIds = invoice.payment_ids ? invoice.payment_ids.join(', ') : '-';
      
      $tbody.append(`
        <tr>
          <td>${invoiceLink}</td>
          <td>${formatDate(invoice.invoice_date)}</td>
          <td class="text-end">¥${formatNumber(invoice.total_amount)}</td>
          <td class="text-end">¥${formatNumber(invoice.paid_amount)}</td>
          <td class="text-end">¥${formatNumber(invoice.remaining_amount)}</td>
          <td class="text-end" data-allocation-amount="0">¥0</td>
          <td class="text-end" data-remaining-after="0">¥${formatNumber(invoice.remaining_amount)}</td>
          <td class="text-center">${paymentIds}</td>
        </tr>
      `);
    });
  }

  // 入金履歴を表示
  function displayPaymentHistory() {
    const $tableHeader = $('[data-payment-management-target="tableHeader"]');
    const $tbody = $('[data-payment-management-target="invoicesTableBody"]');

    $tableHeader.html(`
      <tr>
        <th>入金ID</th>
        <th>入金日</th>
        <th>入金種別</th>
        <th>入金額</th>
        <th>消し込み先請求書番号</th>
        <th>備考</th>
        <th>操作</th>
      </tr>
    `);

    $tbody.empty();

    if (paymentHistory.length === 0) {
      $tbody.append(`
        <tr>
          <td colspan="7" class="text-center text-muted py-4">
            入金履歴はありません
          </td>
        </tr>
      `);
      return;
    }

    paymentHistory.forEach(function(payment) {
      const invoiceLinks = payment.invoice_numbers.map(function(inv) {
        return `<a href="/invoices/${inv.id}" class="text-decoration-none">${inv.number}</a>`;
      }).join(', ');
      
      $tbody.append(`
        <tr>
          <td class="text-center">${payment.payment_id}</td>
          <td>${formatDate(payment.payment_date)}</td>
          <td>${payment.category}</td>
          <td class="text-end">¥${formatNumber(payment.amount)}</td>
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
        </tr>
      `);
    });
  }

  // 数値フォーマット
  function formatNumber(num) {
    return new Intl.NumberFormat('ja-JP').format(num);
  }

  // 日付フォーマット
  function formatDate(dateString) {
    if (!dateString) return '-';
    const date = new Date(dateString);
    return date.toLocaleDateString('ja-JP');
  }

  // ボタンクリックイベント
  $(document).on('click', '[data-payment-management-target="unpaidButton"]', function() {
    const customerId = $('#customer-select').val();
    if (customerId) {
      loadUnpaidInvoices(customerId);
    }
  });

  $(document).on('click', '[data-payment-management-target="paidButton"]', function() {
    const customerId = $('#customer-select').val();
    if (customerId) {
      loadPaidInvoices(customerId);
    }
  });

  $(document).on('click', '[data-payment-management-target="historyButton"]', function() {
    const customerId = $('#customer-select').val();
    if (customerId) {
      loadPaymentHistory(customerId);
    }
  });

  // 入金額入力時の充当計算
  $(document).on('input', '[data-payment-management-target="amountInput"]', function() {
    const amount = parseInt($(this).val()) || 0;
    
    if (amount <= 0) {
      clearAllocation();
      $('[data-payment-management-target="confirmButton"]').prop('disabled', true);
      return;
    }

    allocationResults = [];
    let remainingAmount = amount;

    unpaidInvoices.forEach(function(invoice, index) {
      if (remainingAmount <= 0) return;

      const totalAmount = invoice.total_amount;
      const alreadyPaidAmount = invoice.paid_amount;
      const unpaidAmount = totalAmount - alreadyPaidAmount;
      
      if (unpaidAmount <= 0) return;

      const paidAmount = Math.min(remainingAmount, unpaidAmount);
      const newRemaining = unpaidAmount - paidAmount;

      allocationResults.push({
        index: index,
        paidAmount: paidAmount,
        newRemaining: newRemaining
      });

      remainingAmount -= paidAmount;
    });

    updateAllocationDisplay();
    updateAllocationSummary(amount, remainingAmount);
    
    $('[data-payment-management-target="confirmButton"]').prop('disabled', false);
  });

  // 充当表示を更新
  function updateAllocationDisplay() {
    const $rows = $('[data-payment-management-target="invoicesTableBody"] tr');
    
    $rows.each(function(index) {
      const $row = $(this);
      const $allocationCell = $row.find('[data-allocation-amount]');
      const $remainingCell = $row.find('[data-remaining-after]');
      
      if (allocationResults[index]) {
        const result = allocationResults[index];
        $allocationCell.text('¥' + formatNumber(result.paidAmount));
        $remainingCell.text('¥' + formatNumber(result.newRemaining));
        
        if (result.paidAmount > 0) {
          $allocationCell.addClass('text-success fw-bold');
          $remainingCell.addClass(result.newRemaining === 0 ? 'text-success' : 'text-warning');
        } else {
          $allocationCell.removeClass('text-success fw-bold');
          $remainingCell.removeClass('text-success text-warning');
        }
      } else {
        $allocationCell.text('¥0');
        $allocationCell.removeClass('text-success fw-bold');
        $remainingCell.removeClass('text-success text-warning');
      }
    });
  }

  // 充当サマリーを更新
  function updateAllocationSummary(totalAmount, remainingAmount) {
    const $summary = $('[data-payment-management-target="allocationSummary"]');
    const allocatedAmount = totalAmount - remainingAmount;
    
    $summary.html(`
      <strong>充当結果:</strong> 
      総入金額: ¥${formatNumber(totalAmount)} | 
      充当額: ¥${formatNumber(allocatedAmount)} | 
      未充当: ¥${formatNumber(remainingAmount)}
    `).show();
  }

  // 充当表示をクリア
  function clearAllocation() {
    allocationResults = [];
    updateAllocationDisplay();
    $('[data-payment-management-target="allocationSummary"]').hide();
  }

  // 消し込み登録ボタンのクリックイベント
  $(document).on('click', '[data-payment-management-target="confirmButton"]', function(e) {
    e.preventDefault();
    e.stopPropagation();
    
    const $button = $(this);
    if ($button.prop('disabled')) {
      return false;
    }
    
    // バリデーション
    const amount = parseInt($('[data-payment-management-target="amountInput"]').val()) || 0;
    if (amount <= 0) {
      alert('入金額を正しく入力してください');
      return false;
    }
    
    // フォームを送信
    const $form = $('[data-payment-management-target="paymentForm"]');
    if ($form.length) {
      // フォームの送信を確実にするため、直接submit()を呼び出す
      $form[0].submit();
    } else {
      console.error('Payment form not found');
      alert('フォームが見つかりませんでした');
    }
    
    return false;
  });

  // グローバル関数として削除確認ダイアログを定義
  window.deletePayment = function(paymentId) {
    if (confirm('この入金記録を削除しますか？\n\n削除すると、関連する請求書への充当も取り消されます。\nこの操作は元に戻せません。')) {
      // 削除処理を実行
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
});

