document.addEventListener('DOMContentLoaded', function() {
  // 共通変数の宣言
  const customerCodeField = document.getElementById('order_customer_code');
  const customerSearchField = document.getElementById('customer_search_input');
  const customerIdField = document.getElementById('order_customer_id');
  
  // 編集時の初期化処理
  if (customerIdField && customerIdField.value) {
    // 既に顧客が選択されている場合、納品先の選択肢を更新
    const deliverySelect = document.getElementById('order_delivery_location_id');
    if (deliverySelect && deliverySelect.options.length <= 1) {
      // 納品先の選択肢が空の場合、顧客情報を取得して更新
      const customerCode = customerCodeField ? customerCodeField.value : '';
      if (customerCode) {
        fetch(`/orders/find_customer_by_code?code=${encodeURIComponent(customerCode)}`)
          .then(response => response.json())
          .then(data => {
            if (data.success && data.customer) {
              deliverySelect.innerHTML = '<option value="">納品先を選択してください</option>';
              data.customer.delivery_locations.forEach(location => {
                const option = document.createElement('option');
                option.value = location.id;
                option.textContent = location.name;
                deliverySelect.appendChild(option);
              });
              deliverySelect.disabled = false;
            }
          })
          .catch(error => {
            console.error('Customer info fetch error:', error);
          });
      }
    }
  } else if (customerCodeField && customerCodeField.value) {
    // 顧客コードが入力されているが、顧客IDが設定されていない場合（エラー時など）
    const deliverySelect = document.getElementById('order_delivery_location_id');
    if (deliverySelect && deliverySelect.options.length <= 1) {
      const customerCode = customerCodeField.value.trim();
      if (customerCode) {
        fetch(`/orders/find_customer_by_code?code=${encodeURIComponent(customerCode)}`)
          .then(response => response.json())
          .then(data => {
            if (data.success && data.customer) {
              // 顧客名を設定
              if (customerSearchField) {
                customerSearchField.value = data.customer.company_name;
              }
              if (customerIdField) {
                customerIdField.value = data.customer.id;
              }
              
              // 納品先の選択肢を更新
              deliverySelect.innerHTML = '<option value="">納品先を選択してください</option>';
              data.customer.delivery_locations.forEach(location => {
                const option = document.createElement('option');
                option.value = location.id;
                option.textContent = location.name;
                deliverySelect.appendChild(option);
              });
              deliverySelect.disabled = false;
            }
          })
          .catch(error => {
            console.error('Customer info fetch error:', error);
          });
      }
    }
  }

  // 顧客コード入力時の自動補完
  if (customerCodeField) {
    customerCodeField.addEventListener('blur', function() {
      const code = this.value.trim();
      console.log('Customer code entered:', code); // デバッグ用
      if (code) {
        fetch(`/orders/find_customer_by_code?code=${encodeURIComponent(code)}`)
          .then(response => {
            console.log('Customer code response status:', response.status); // デバッグ用
            return response.json();
          })
          .then(data => {
            console.log('Customer code data:', data); // デバッグ用
            if (data.success && data.customer) {
              // 顧客名を設定
              if (customerSearchField) {
                customerSearchField.value = data.customer.company_name;
              }
              if (customerIdField) {
                customerIdField.value = data.customer.id;
              }
              
              // 納品先の選択肢を更新
              const deliverySelect = document.getElementById('order_delivery_location_id');
              if (deliverySelect) {
                deliverySelect.innerHTML = '<option value="">納品先を選択してください</option>';
                data.customer.delivery_locations.forEach(location => {
                  const option = document.createElement('option');
                  option.value = location.id;
                  option.textContent = location.name;
                  deliverySelect.appendChild(option);
                });
                deliverySelect.disabled = false;
              }
              
              showMessage('顧客情報を取得しました', 'success');
            } else {
              showMessage('顧客コードが見つかりません', 'error');
            }
          })
          .catch(error => {
            console.error('Customer code error:', error);
            showMessage('顧客情報の取得に失敗しました', 'error');
          });
      }
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
          if (taxRateDisplay && data.product.tax_rate) {
            taxRateDisplay.textContent = data.product.tax_rate;
          }
          if (taxRateInput && data.product.tax_rate) {
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

