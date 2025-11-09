// 受注一覧ページ用のJavaScript（jQuery不使用）

document.addEventListener('DOMContentLoaded', function() {
  const checkboxes = document.querySelectorAll('.order-checkbox');
  const createInvoiceBtn = document.getElementById('create-invoice-btn');
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

  checkboxes.forEach(checkbox => {
    checkbox.addEventListener('change', function() {
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

      // 選択されている受注があるか確認し、請求書発行ボタンの有効/無効を設定
      if (createInvoiceBtn) {
        createInvoiceBtn.disabled = !anyChecked;
      }

      // 選択された受注IDを隠しフィールドに設定
      if (selectedOrderIdsInput) {
        selectedOrderIdsInput.value = selectedOrderIds.join(',');
      }
    });
  });
  
  // 取引先名のインクリメンタルサーチを初期化
  if (window.CompanyNameSearch) {
    window.CompanyNameSearch.setup(document, {
      inputSelector: '#customer_name_search',
      suggestionsSelector: '#customer_name_suggestions',
      apiUrl: '/customers/company_name_search',
      autoSubmit: true
    });
  }
});

