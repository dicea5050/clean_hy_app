document.addEventListener('DOMContentLoaded', function() {
  console.log('DOM fully loaded');

  // 入金行を追加するボタンのイベントリスナー
  const addButton = document.getElementById('add-payment-record');
  if (addButton) {
    console.log('Add button found');
    addButton.addEventListener('click', function() {
      console.log('Add button clicked');
      addPaymentRow();
    });
  } else {
    console.log('Add button not found');
  }

  // 初期設定
  attachRemoveButtonListeners();
  attachAmountInputListeners();
  updateTotals();

  // 入金行を追加する関数
  function addPaymentRow() {
    const container = document.getElementById('payment-records-container');
    // 新しい行のインデックスを取得（ユニークなタイムスタンプ）
    const newIndex = new Date().getTime();

    // HTML文字列で新しい行を作成
    const newRowHtml = `
      <tr class="payment-record-row">
        <td>
          <input type="date" class="form-control payment-date"
                 name="invoice[payment_records_attributes][${newIndex}][payment_date]"
                 id="invoice_payment_records_attributes_${newIndex}_payment_date">
        </td>
        <td>
          <select class="form-control payment-type"
                  name="invoice[payment_records_attributes][${newIndex}][payment_type]"
                  id="invoice_payment_records_attributes_${newIndex}_payment_type">
            <option value="">選択してください</option>
            ${getPaymentTypeOptions()}
          </select>
        </td>
        <td>
          <div class="input-group">
            <span class="input-group-text">¥</span>
            <input type="number" class="form-control payment-amount" min="0" step="1"
                   name="invoice[payment_records_attributes][${newIndex}][amount]"
                   id="invoice_payment_records_attributes_${newIndex}_amount">
          </div>
        </td>
        <td>
          <input type="text" class="form-control payment-memo"
                 name="invoice[payment_records_attributes][${newIndex}][memo]"
                 id="invoice_payment_records_attributes_${newIndex}_memo">
        </td>
        <td class="text-center">
          <button type="button" class="btn btn-danger remove-payment-record">
            <i class="bi bi-trash"></i> 削除
          </button>
          <input type="hidden" class="destroy-flag" value="false"
                 name="invoice[payment_records_attributes][${newIndex}][_destroy]"
                 id="invoice_payment_records_attributes_${newIndex}_destroy">
        </td>
      </tr>
    `;

    // コンテナに新しい行を追加
    container.insertAdjacentHTML('beforeend', newRowHtml);

    // 新しく追加した行のイベントリスナーを設定
    attachRemoveButtonListeners();
    attachAmountInputListeners();
    updateTotals();
  }

  // 科目オプションのHTMLを生成する関数
  function getPaymentTypeOptions() {
    let options = '';
    const paymentTypes = document.querySelector('.payment-type').options;
    for (let i = 0; i < paymentTypes.length; i++) {
      if (paymentTypes[i].value) {
        options += `<option value="${paymentTypes[i].value}">${paymentTypes[i].text}</option>`;
      }
    }
    return options;
  }

  // 削除ボタンのイベントリスナーを設定する関数
  function attachRemoveButtonListeners() {
    document.querySelectorAll('.remove-payment-record').forEach(button => {
      // 既存のイベントリスナーを削除
      button.removeEventListener('click', handleRemoveButtonClick);
      // 新しいイベントリスナーを追加
      button.addEventListener('click', handleRemoveButtonClick);
    });
  }

  // 削除ボタンのクリックハンドラ
  function handleRemoveButtonClick() {
    console.log('Remove button clicked');
    const row = this.closest('.payment-record-row');
    const destroyField = row.querySelector('.destroy-flag');

    if (destroyField.value === 'false' || destroyField.value === '') {
      destroyField.value = 'true';
      row.style.display = 'none';
    } else {
      destroyField.value = 'false';
      row.style.display = '';
    }

    updateTotals();
  }

  // 金額入力のイベントリスナーを設定する関数
  function attachAmountInputListeners() {
    document.querySelectorAll('.payment-amount').forEach(input => {
      // 既存のイベントリスナーを削除
      input.removeEventListener('input', updateTotals);
      // 新しいイベントリスナーを追加
      input.addEventListener('input', updateTotals);
    });
  }

  // 合計金額を更新する関数
  function updateTotals() {
    let totalPaid = 0;
    const invoiceAmount = getInvoiceAmount();

    // 表示されている行の入金額を合計
    document.querySelectorAll('.payment-record-row').forEach(row => {
      // 非表示（削除マークされた）行はスキップ
      if (row.style.display === 'none') return;

      const amountField = row.querySelector('.payment-amount');
      if (amountField && amountField.value) {
        totalPaid += parseFloat(amountField.value);
      }
    });

    // 入金済み金額を更新
    const totalPaidElement = document.querySelector('.total-paid-amount');
    if (totalPaidElement) {
      totalPaidElement.textContent = formatCurrency(totalPaid);
    }

    // 未入金金額を更新
    const unpaidElement = document.querySelector('.unpaid-amount');
    if (unpaidElement) {
      const unpaidAmount = invoiceAmount - totalPaid;
      unpaidElement.textContent = formatCurrency(unpaidAmount);

      // 未入金金額が負の場合は赤くする
      if (unpaidAmount < 0) {
        unpaidElement.classList.add('text-danger');
      } else {
        unpaidElement.classList.remove('text-danger');
      }
    }
  }

  // 請求金額を取得
  function getInvoiceAmount() {
    const totalElement = document.querySelector('.total-invoice-amount-display');
    if (totalElement) {
      const amountText = totalElement.textContent.trim().replace(/[^\d.-]/g, '');
      return parseFloat(amountText) || 0;
    }
    return 0;
  }

  // 通貨フォーマット
  function formatCurrency(amount) {
    return new Intl.NumberFormat('ja-JP', {
      style: 'currency',
      currency: 'JPY',
      minimumFractionDigits: 0
    }).format(amount);
  }
});