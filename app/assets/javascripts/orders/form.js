document.addEventListener('DOMContentLoaded', function() {
  // 顧客コード・取引先名連動機能を初期化
  if (window.CustomerCodeSearch) {
    window.CustomerCodeSearch.init({
      customerCodeSelector: '#order_customer_code',
      customerSelectSelector: '#order_customer_select',
      customerIdSelector: '#order_customer_id',
      findCustomerApiUrl: '/orders/find_customer_by_code',
      enableSelect2: true,
      onCustomerChange: function(customerId, customerData) {
        // 納品先の選択肢を更新
        const deliverySelect = document.getElementById('order_delivery_location_id');
        if (deliverySelect && customerId) {
          fetch(`/customers/${customerId}/delivery_locations`)
            .then(response => response.json())
            .then(data => {
              deliverySelect.innerHTML = '';
              if (data && data.length > 0) {
                let mainOfficeId = null;
                data.forEach(location => {
                  const option = document.createElement('option');
                  option.value = location.id;
                  option.textContent = location.name;
                  if (location.is_main_office) {
                    option.selected = true;
                    mainOfficeId = location.id;
                  }
                  deliverySelect.appendChild(option);
                });
                // 本社がなければ最初の納品先を選択
                if (!mainOfficeId && data.length > 0) {
                  deliverySelect.options[0].selected = true;
                }
                deliverySelect.disabled = false;
              } else {
                deliverySelect.disabled = true;
              }
            })
            .catch(error => {
              console.error('Delivery locations fetch error:', error);
            });
        }

        // 支払い方法を自動設定（顧客情報に支払い方法が登録されている場合）
        if (customerData && customerData.payment_method_id) {
          const paymentMethodSelect = document.getElementById('order_payment_method_id');
          if (paymentMethodSelect) {
            // 支払い方法の選択肢が存在するか確認
            const option = paymentMethodSelect.querySelector(`option[value="${customerData.payment_method_id}"]`);
            if (option) {
              paymentMethodSelect.value = customerData.payment_method_id;
              // select2を使用している場合は更新
              if (typeof $ !== 'undefined' && $(paymentMethodSelect).data('select2')) {
                $(paymentMethodSelect).trigger('change');
              }
            }
          }
        }
      },
      onCustomerClear: function() {
        const deliverySelect = document.getElementById('order_delivery_location_id');
        if (deliverySelect) {
          deliverySelect.innerHTML = '';
          deliverySelect.disabled = true;
        }
        // 支払い方法はクリアしない（デフォルト値として残す）
      }
    });
  }

  // 顧客名のセレクトボックスが直接変更されたときの処理
  const customerSelectField = document.getElementById('order_customer_select');
  if (customerSelectField) {
    // select2を使用している場合
    if (typeof $ !== 'undefined' && $(customerSelectField).data('select2')) {
      $(customerSelectField).on('select2:select', function() {
        const customerId = $(this).val();
        if (customerId) {
          updatePaymentMethodFromCustomer(customerId);
        }
      });
    } else {
      // 通常のselectの場合
      customerSelectField.addEventListener('change', function() {
        const customerId = this.value;
        if (customerId) {
          updatePaymentMethodFromCustomer(customerId);
        }
      });
    }
  }

  // 顧客IDから支払い方法を取得して設定する関数
  function updatePaymentMethodFromCustomer(customerId) {
    // 顧客IDから顧客情報を取得（支払い方法IDを含む）
    fetch(`/orders/find_customer_by_code?customer_id=${encodeURIComponent(customerId)}`)
      .then(response => response.json())
      .then(data => {
        if (data.success && data.customer && data.customer.payment_method_id) {
          const paymentMethodSelect = document.getElementById('order_payment_method_id');
          if (paymentMethodSelect) {
            const option = paymentMethodSelect.querySelector(`option[value="${data.customer.payment_method_id}"]`);
            if (option) {
              paymentMethodSelect.value = data.customer.payment_method_id;
              // select2を使用している場合は更新
              if (typeof $ !== 'undefined' && $(paymentMethodSelect).data('select2')) {
                $(paymentMethodSelect).trigger('change');
              }
            }
          }
        }
      })
      .catch(error => {
        console.error('Payment method fetch error:', error);
      });
  }

  // 編集時の初期化処理（納品先の選択肢を更新）
  const customerIdField = document.getElementById('order_customer_id');
  const deliverySelect = document.getElementById('order_delivery_location_id');
  if (customerIdField && customerIdField.value && deliverySelect && deliverySelect.options.length <= 1) {
    // 既に顧客が選択されている場合、納品先の選択肢を更新
    fetch(`/customers/${customerIdField.value}/delivery_locations`)
      .then(response => response.json())
      .then(data => {
        if (data && data.length > 0) {
          deliverySelect.innerHTML = '';
          let mainOfficeId = null;
          data.forEach(location => {
            const option = document.createElement('option');
            option.value = location.id;
            option.textContent = location.name;
            if (location.is_main_office) {
              option.selected = true;
              mainOfficeId = location.id;
            }
            deliverySelect.appendChild(option);
          });
          // 本社がなければ最初の納品先を選択
          if (!mainOfficeId && data.length > 0) {
            deliverySelect.options[0].selected = true;
          }
          deliverySelect.disabled = false;
        }
      })
      .catch(error => {
        console.error('Delivery locations fetch error:', error);
      });
  }

  // インクリメンタルサーチ機能は一時的に無効化
  /*
  // 顧客名入力時の自動補完
  if (customerSearchField) {
    customerSearchField.addEventListener('input', function() {
      // 一時的に無効化
    });
  }
  */

  // 商品コード入力時の自動補完（委譲）
  document.addEventListener('focusout', function(event) {
    const productCodeField = event.target;
    if (!productCodeField.classList || !productCodeField.classList.contains('product-code-input')) {
      return;
    }

    const code = productCodeField.value.trim();
    const row = productCodeField.closest('tr');
    console.log('Product code entered:', code); // デバッグ用

    if (!code || !row) {
      return;
    }

    fetch(`/orders/find_product_by_code?code=${encodeURIComponent(code)}`)
      .then(response => {
        console.log('Product code response status:', response.status); // デバッグ用
        return response.json();
      })
      .then(data => {
        console.log('Product code data:', data); // デバッグ用
        if (data.success && data.product) {
          const productSearchField = row.querySelector('.product-search');
          const productIdField = row.querySelector('input[name*="[product_id]"]');
          const productNameOverrideField = row.querySelector('input[name*="[product_name_override]"]');

          if (productSearchField) {
            productSearchField.value = data.product.name;
          }
          if (productIdField) {
            productIdField.value = data.product.id;
          }
          if (productNameOverrideField) {
            productNameOverrideField.value = '';
          }

          const unitPriceDisplay = row.querySelector('.unit-price-display');
          const unitPriceInput = row.querySelector('.unit-price-input');
          const taxRateDisplay = row.querySelector('.tax-rate-display');
          const taxRateInput = row.querySelector('input[name*="[tax_rate]"]');

          if (unitPriceDisplay && data.product.price) {
            unitPriceDisplay.value = data.product.price;
            // 商品コード入力時は編集可能にする
            unitPriceDisplay.removeAttribute('readonly');
          }
          if (unitPriceInput && data.product.price) {
            unitPriceInput.value = data.product.price;
          }
          if (taxRateDisplay && data.product.tax_rate !== undefined && data.product.tax_rate !== null) {
            taxRateDisplay.textContent = data.product.tax_rate + '%';
          }
          if (taxRateInput && data.product.tax_rate !== undefined && data.product.tax_rate !== null) {
            taxRateInput.value = data.product.tax_rate;
          }

          const quantityInput = row.querySelector('.quantity-input');
          if (quantityInput) {
            quantityInput.dispatchEvent(new Event('change'));
          }

          showMessage('商品情報を取得しました', 'success');
        } else {
          showMessage('商品コードが見つかりません', 'error');
        }
      })
      .catch(error => {
        console.error('Product code error:', error);
        showMessage('商品情報の取得に失敗しました', 'error');
      });
  });

  // 商品名フィールドの変更を監視して手動変更を保存（委譲）
  document.addEventListener('input', function(event) {
    const productSearchField = event.target;
    if (!productSearchField.classList || !productSearchField.classList.contains('product-search')) {
      return;
    }

    const row = productSearchField.closest('tr');
    if (!row) {
      return;
    }

    const productNameOverrideField = row.querySelector('input[name*="[product_name_override]"]');
    if (productNameOverrideField) {
      productNameOverrideField.value = productSearchField.value;
      console.log('Product name manually changed to:', productSearchField.value); // デバッグ用
    }
  });

  // メッセージ表示関数
  function showMessage(message, type) {
    // 既存のメッセージを削除
    const existingMessage = document.querySelector('.auto-complete-message');
    if (existingMessage) {
      existingMessage.remove();
    }

    // 新しいメッセージを作成
    const messageDiv = document.createElement('div');
    messageDiv.className = `alert auto-complete-message ${type === 'success' ? 'alert-success' : 'alert-danger'}`;
    messageDiv.textContent = message;
    messageDiv.style.position = 'fixed';
    messageDiv.style.top = '20px';
    messageDiv.style.right = '20px';
    messageDiv.style.zIndex = '9999';
    messageDiv.style.minWidth = '300px';

    document.body.appendChild(messageDiv);

    // 3秒後に自動削除
    setTimeout(() => {
      if (messageDiv.parentNode) {
        messageDiv.parentNode.removeChild(messageDiv);
      }
    }, 3000);
  }
});

