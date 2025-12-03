// 顧客コード・取引先名連動機能の共通モジュール
// 使用方法:
// CustomerCodeSearch.init({
//   customerCodeSelector: '#customer-code-input',
//   customerSelectSelector: '#customer-select',
//   customerIdSelector: '#customer_id',
//   findCustomerApiUrl: '/orders/find_customer_by_code',
//   onCustomerChange: function(customerId, customerData) { ... },
//   onCustomerClear: function() { ... }
// });

(function() {
  'use strict';

  window.CustomerCodeSearch = {
    // 初期化関数
    init: function(options) {
      const config = {
        customerCodeSelector: options.customerCodeSelector || null,
        customerSelectSelector: options.customerSelectSelector || null,
        customerIdSelector: options.customerIdSelector || null,
        findCustomerApiUrl: options.findCustomerApiUrl || '/orders/find_customer_by_code',
        onCustomerChange: options.onCustomerChange || null,
        onCustomerClear: options.onCustomerClear || null,
        enableSelect2: options.enableSelect2 !== false, // デフォルトで有効
        select2Options: options.select2Options || {}
      };

      // DOM要素を取得
      const customerCodeField = config.customerCodeSelector 
        ? document.querySelector(config.customerCodeSelector) 
        : null;
      const customerSelectField = config.customerSelectSelector 
        ? document.querySelector(config.customerSelectSelector) 
        : null;
      const customerIdField = config.customerIdSelector 
        ? document.querySelector(config.customerIdSelector) 
        : null;

      if (!customerCodeField || !customerSelectField) {
        console.warn('CustomerCodeSearch: Required fields not found');
        return;
      }

      // select2を初期化（有効な場合）
      if (config.enableSelect2 && typeof $ !== 'undefined' && $.fn.select2) {
        this.initializeSelect2(customerSelectField, config.select2Options);
      }

      // 顧客コード入力時の処理
      customerCodeField.addEventListener('blur', function() {
        handleCustomerCodeBlur(this, customerSelectField, customerIdField, config);
      });

      // 取引先名（select2）変更時の処理
      if (config.enableSelect2 && typeof $ !== 'undefined' && $.fn.select2) {
        $(customerSelectField).on('select2:select select2:clear', function() {
          handleCustomerSelectChange(this, customerCodeField, customerIdField, config);
        });
      } else {
        customerSelectField.addEventListener('change', function() {
          handleCustomerSelectChange(this, customerCodeField, customerIdField, config);
        });
      }

      // 取引先名がテキストフィールドの場合（検索フォーム用）
      if (customerSelectField.tagName === 'INPUT') {
        customerSelectField.addEventListener('input', function() {
          if (!this.value.trim() && customerCodeField) {
            customerCodeField.value = '';
            if (config.onCustomerClear) {
              config.onCustomerClear();
            }
          }
        });

        customerSelectField.addEventListener('blur', function() {
          if (!this.value.trim() && customerCodeField) {
            customerCodeField.value = '';
            if (config.onCustomerClear) {
              config.onCustomerClear();
            }
          }
        });
      }
    },

    // select2を初期化
    initializeSelect2: function(selectElement, customOptions) {
      if (typeof $ === 'undefined' || typeof $.fn.select2 === 'undefined') {
        console.warn('jQuery or select2 is not loaded, retrying...');
        setTimeout(() => {
          this.initializeSelect2(selectElement, customOptions);
        }, 100);
        return;
      }

      const defaultOptions = {
        theme: 'bootstrap-5',
        placeholder: '選択してください',
        allowClear: true,
        language: 'ja',
        width: '100%'
        // 顧客名のみで検索（顧客コードでの検索は不要）
        // matcherはデフォルトの動作（顧客名のみで検索）を使用
      };

      const options = Object.assign({}, defaultOptions, customOptions);
      $(selectElement).select2(options);
    }
  };

  // 顧客コード入力時の処理
  function handleCustomerCodeBlur(customerCodeField, customerSelectField, customerIdField, config) {
    const code = customerCodeField.value.trim();
    
    // 顧客コードが空の場合は、取引先名もクリア
    if (!code) {
      clearCustomerFields(customerSelectField, customerIdField, config);
      return;
    }
    
    // 顧客コードから顧客情報を取得
    fetch(`${config.findCustomerApiUrl}?code=${encodeURIComponent(code)}`)
      .then(response => response.json())
      .then(data => {
        if (data.success && data.customer) {
          // selectのoptionのvalueが顧客IDか顧客名かを判定
          // data-customer-id属性があるoptionを探す
          const optionWithCustomerId = customerSelectField.querySelector('option[data-customer-id]');
          const isValueCustomerName = optionWithCustomerId && 
                                     optionWithCustomerId.value !== '' && 
                                     optionWithCustomerId.value !== data.customer.id.toString();
          
          // select2を使用している場合
          if (config.enableSelect2 && typeof $ !== 'undefined' && $.fn.select2) {
            if (isValueCustomerName) {
              // 検索フォームの場合：valueが顧客名なので、顧客名で選択
              $(customerSelectField).val(data.customer.company_name).trigger('change');
            } else {
              // 通常の場合：valueが顧客IDなので、顧客IDで選択
              $(customerSelectField).val(data.customer.id).trigger('change');
            }
          } else if (customerSelectField.tagName === 'SELECT') {
            // 通常のselectの場合
            if (isValueCustomerName) {
              // 検索フォームの場合：valueが顧客名
              customerSelectField.value = data.customer.company_name;
            } else {
              // 通常の場合：valueが顧客ID
              customerSelectField.value = data.customer.id;
            }
            const event = new Event('change', { bubbles: true });
            customerSelectField.dispatchEvent(event);
          } else {
            // テキストフィールドの場合（検索フォーム用）
            customerSelectField.value = data.customer.company_name;
          }
          
          // 顧客IDフィールドも更新
          if (customerIdField) {
            customerIdField.value = data.customer.id;
          }
          
          // コールバック実行
          if (config.onCustomerChange) {
            config.onCustomerChange(data.customer.id, data.customer);
          }
        } else {
          // 顧客が見つからない場合はクリア
          clearCustomerFields(customerSelectField, customerIdField, config);
        }
      })
      .catch(error => {
        console.error('Customer code error:', error);
        clearCustomerFields(customerSelectField, customerIdField, config);
      });
  }

  // 取引先名選択時の処理
  function handleCustomerSelectChange(customerSelectField, customerCodeField, customerIdField, config) {
    const customerId = customerSelectField.value;
    
    if (customerId) {
      // 選択された顧客のコードを取得
      if (customerCodeField && customerSelectField.tagName === 'SELECT') {
        const option = customerSelectField.querySelector(`option[value="${customerId}"]`);
        if (option && option.dataset.customerCode) {
          customerCodeField.value = option.dataset.customerCode;
        }
      }
      
      // 顧客IDフィールドも更新
      if (customerIdField) {
        customerIdField.value = customerId;
      }
      
      // コールバック実行
      if (config.onCustomerChange) {
        // 顧客データを取得（必要に応じて）
        const option = customerSelectField.querySelector(`option[value="${customerId}"]`);
        const customerData = {
          id: customerId,
          company_name: option ? option.textContent : '',
          customer_code: option && option.dataset.customerCode ? option.dataset.customerCode : ''
        };
        config.onCustomerChange(customerId, customerData);
      }
    } else {
      // クリアされた場合
      clearCustomerFields(customerSelectField, customerIdField, config);
      if (customerCodeField) {
        customerCodeField.value = '';
      }
      if (config.onCustomerClear) {
        config.onCustomerClear();
      }
    }
  }

  // 顧客フィールドをクリア
  function clearCustomerFields(customerSelectField, customerIdField, config) {
    if (config.enableSelect2 && typeof $ !== 'undefined' && $.fn.select2) {
      $(customerSelectField).val(null).trigger('change');
    } else if (customerSelectField.tagName === 'SELECT') {
      customerSelectField.value = '';
      const event = new Event('change', { bubbles: true });
      customerSelectField.dispatchEvent(event);
    } else {
      customerSelectField.value = '';
    }
    
    if (customerIdField) {
      customerIdField.value = '';
    }
  }
})();

