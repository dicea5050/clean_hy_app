// 受注一覧ページ用のJavaScript（jQuery不使用）

document.addEventListener('DOMContentLoaded', function() {
  const checkboxes = document.querySelectorAll('.order-checkbox');
  const selectAllCheckbox = document.getElementById('select-all-orders');
  const createInvoiceBtn = document.getElementById('create-invoice-btn');
  const bulkCreateIndividualBtn = document.getElementById('bulk-create-individual-invoice-btn');
  const selectedOrderIdsInput = document.getElementById('selected-order-ids');
  const form = document.getElementById('selected-orders-form');

  // 納品書ボタンのクリックイベント
  const deliverySlipBtns = document.querySelectorAll('.delivery-slip-btn');
  deliverySlipBtns.forEach(btn => {
    btn.addEventListener('click', function(event) {
      const hasDeliveryDate = this.dataset.hasDeliveryDate === 'true';

      if (!hasDeliveryDate) {
        event.preventDefault();
        alert('確定納品日を入力してください');
        return false;
      }
    });
  });

  // 請求書発行ボタンのクリックイベント
  if (createInvoiceBtn) {
    createInvoiceBtn.addEventListener('click', function(e) {
      const selectedOrders = Array.from(checkboxes)
        .filter(cb => cb.checked)
        .map(cb => ({
          id: cb.dataset.orderId,
          customerId: cb.dataset.customerId,
          paymentMethod: cb.dataset.paymentMethod,
          hasActualDeliveryDate: cb.dataset.actualDeliveryDate === 'true'
        }));

      // 確定納品日が未入力の受注がないかチェック
      const hasUnconfirmedDelivery = selectedOrders.some(order => !order.hasActualDeliveryDate);
      if (hasUnconfirmedDelivery) {
        e.preventDefault();
        alert('納品日が確定していない取引が含まれています');
        return false;
      }

      // 支払い方法の一意性をチェック
      const uniquePaymentMethods = new Set(selectedOrders.map(order => order.paymentMethod));

      if (uniquePaymentMethods.size > 1) {
        e.preventDefault();
        alert('複数の支払い方法の取引が選択されているため、発行できません');
        return false;
      }

      if (selectedOrders.length > 0 && selectedOrderIdsInput && form) {
        selectedOrderIdsInput.value = selectedOrders.map(order => order.id).join(',');
        form.submit();
      }
    });
  }

  // 一括選択中かどうかを示すフラグ
  let isSelectingAll = false;

  // 一括選択チェックボックスのイベントハンドラ
  if (selectAllCheckbox) {
    selectAllCheckbox.addEventListener('change', function() {
      const isChecked = this.checked;
      isSelectingAll = true;
      
      // 有効なチェックボックスのみを選択/解除
      checkboxes.forEach(cb => {
        if (!cb.disabled) {
          cb.checked = isChecked;
        }
      });

      // 一括選択完了後、changeイベントを一度だけ処理
      if (isChecked) {
        // すべてのチェックボックスを選択した状態で処理
        let anyChecked = true;
        let selectedOrderIds = [];
        
        checkboxes.forEach(cb => {
          if (cb.checked && !cb.disabled) {
            selectedOrderIds.push(cb.dataset.orderId);
          }
        });

        // 一括選択時は顧客IDによる無効化を行わない
        // ボタンの有効/無効を設定
        if (createInvoiceBtn) {
          createInvoiceBtn.disabled = !anyChecked || selectedOrderIds.length === 0;
        }

        if (bulkCreateIndividualBtn) {
          bulkCreateIndividualBtn.disabled = !anyChecked || selectedOrderIds.length === 0;
        }

        // 選択された受注IDを隠しフィールドに設定
        if (selectedOrderIdsInput) {
          selectedOrderIdsInput.value = selectedOrderIds.join(',');
        }
      } else {
        // すべてのチェックボックスを解除
        if (createInvoiceBtn) {
          createInvoiceBtn.disabled = true;
        }

        if (bulkCreateIndividualBtn) {
          bulkCreateIndividualBtn.disabled = true;
        }

        if (selectedOrderIdsInput) {
          selectedOrderIdsInput.value = '';
        }

        // すべてのチェックボックスを有効化（請求書発行済みを除く）
        checkboxes.forEach(cb => {
          if (cb.dataset.invoiced !== 'true') {
            cb.disabled = false;
          }
        });
      }

      // 一括選択チェックボックスの状態を更新
      updateSelectAllCheckbox();
      
      isSelectingAll = false;
    });
  }

  // 個別チェックボックスの状態を更新する関数
  function updateSelectAllCheckbox() {
    if (!selectAllCheckbox) return;
    
    const enabledCheckboxes = Array.from(checkboxes).filter(cb => !cb.disabled);
    const checkedCount = enabledCheckboxes.filter(cb => cb.checked).length;
    
    // すべての有効なチェックボックスが選択されている場合のみ一括選択をチェック
    selectAllCheckbox.checked = enabledCheckboxes.length > 0 && checkedCount === enabledCheckboxes.length;
    selectAllCheckbox.indeterminate = checkedCount > 0 && checkedCount < enabledCheckboxes.length;
  }

  checkboxes.forEach(checkbox => {
    checkbox.addEventListener('change', function() {
      // 一括選択中は個別のchangeイベント処理をスキップ
      if (isSelectingAll) {
        return;
      }

      const customerId = this.dataset.customerId;
      let anyChecked = false;
      let selectedCustomerId = null;
      const selectedOrderIds = [];

      // どのチェックボックスがチェックされているか確認
      checkboxes.forEach(cb => {
        if (cb.checked) {
          anyChecked = true;
          selectedCustomerId = cb.dataset.customerId;
          selectedOrderIds.push(cb.dataset.orderId);
        }
      });

      // チェックボックスがチェックされている場合、異なる取引先のチェックボックスを無効化
      if (anyChecked) {
        checkboxes.forEach(cb => {
          if (cb.dataset.customerId !== selectedCustomerId) {
            cb.disabled = true;
          }
        });
      } else {
        // チェックされていない場合、元々請求書発行済みで無効化されていないチェックボックスのみを有効化
        checkboxes.forEach(cb => {
          // 元々請求書発行済みで無効化されているチェックボックスは有効化しない
          if (cb.dataset.invoiced !== 'true') {
            cb.disabled = false;
          }
        });
      }

      // 一括選択チェックボックスの状態を更新
      updateSelectAllCheckbox();

      // 選択されている受注があるか確認し、請求書発行ボタンの有効/無効を設定
      if (createInvoiceBtn) {
        createInvoiceBtn.disabled = !anyChecked;
      }

      // 個別一括発行ボタンの有効/無効を設定
      if (bulkCreateIndividualBtn) {
        bulkCreateIndividualBtn.disabled = !anyChecked;
      }

      // 選択された受注IDを隠しフィールドに設定
      if (selectedOrderIdsInput) {
        selectedOrderIdsInput.value = selectedOrderIds.join(',');
      }
    });
  });

  // 個別請求書一括発行ボタンのクリックイベント
  if (bulkCreateIndividualBtn) {
    bulkCreateIndividualBtn.addEventListener('click', function(e) {
      const selectedOrders = Array.from(checkboxes)
        .filter(cb => cb.checked)
        .map(cb => ({
          id: cb.dataset.orderId,
          hasActualDeliveryDate: cb.dataset.actualDeliveryDate === 'true'
        }));

      if (selectedOrders.length === 0) {
        e.preventDefault();
        alert('受注が選択されていません');
        return false;
      }

      // 確定納品日が未入力の受注がないかチェック
      const hasUnconfirmedDelivery = selectedOrders.some(order => !order.hasActualDeliveryDate);
      if (hasUnconfirmedDelivery) {
        if (!confirm('確定納品日が未入力の受注が含まれています。確定納品日が未入力の受注はスキップされますが、続行しますか？')) {
          e.preventDefault();
          return false;
        }
      }

      // CSRFトークンを取得
      const csrfToken = document.querySelector('meta[name="csrf-token"]').getAttribute('content');

      // フォームを作成してPOST送信
      const form = document.createElement('form');
      form.method = 'POST';
      form.action = '/invoices/bulk_create_individual';

      // method override（RailsのPOST）
      const methodInput = document.createElement('input');
      methodInput.type = 'hidden';
      methodInput.name = '_method';
      methodInput.value = 'POST';
      form.appendChild(methodInput);

      // CSRFトークン
      const tokenInput = document.createElement('input');
      tokenInput.type = 'hidden';
      tokenInput.name = 'authenticity_token';
      tokenInput.value = csrfToken;
      form.appendChild(tokenInput);

      // 受注ID
      const orderIdsInput = document.createElement('input');
      orderIdsInput.type = 'hidden';
      orderIdsInput.name = 'order_ids';
      orderIdsInput.value = selectedOrders.map(order => order.id).join(',');
      form.appendChild(orderIdsInput);

      // フォームを送信
      document.body.appendChild(form);
      form.submit();
    });
  }

  // 顧客コード・取引先名連動機能を初期化
  if (window.CustomerCodeSearch) {
    window.CustomerCodeSearch.init({
      customerCodeSelector: 'input[name="customer_code"]',
      customerSelectSelector: '#customer_name_search',
      customerIdSelector: null,
      findCustomerApiUrl: '/orders/find_customer_by_code',
      enableSelect2: true,
      onCustomerChange: function(customerId, customerData) {
        // 検索フォームなので特に追加処理は不要
      },
      onCustomerClear: function() {
        // 検索フォームなので特に追加処理は不要
      }
    });
  }

  // 削除ボタンのクリックイベント
  const deleteOrderBtns = document.querySelectorAll('.delete-order-btn');
  deleteOrderBtns.forEach(btn => {
    btn.addEventListener('click', function(event) {
      event.preventDefault();
      event.stopPropagation();

      const orderId = this.dataset.orderId;
      const isInvoiced = this.dataset.invoiced === 'true';

      if (isInvoiced) {
        // 請求書発行済みの場合は警告を表示
        alert('請求書発行済みのため削除できません。先に請求書を削除してください');
        return false;
      } else {
        // 請求書未発行の場合は確認ダイアログを表示
        if (confirm('本当に削除しますか？')) {
          // CSRFトークンを取得
          const csrfToken = document.querySelector('meta[name="csrf-token"]').getAttribute('content');

          // 削除用のフォームを作成
          const form = document.createElement('form');
          form.method = 'POST';
          form.action = `/orders/${orderId}`;

          // method override
          const methodInput = document.createElement('input');
          methodInput.type = 'hidden';
          methodInput.name = '_method';
          methodInput.value = 'DELETE';
          form.appendChild(methodInput);

          // CSRFトークン
          const tokenInput = document.createElement('input');
          tokenInput.type = 'hidden';
          tokenInput.name = 'authenticity_token';
          tokenInput.value = csrfToken;
          form.appendChild(tokenInput);

          // フォームを送信
          document.body.appendChild(form);
          form.submit();
        }
      }
    });
  });
});

