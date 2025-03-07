document.addEventListener('DOMContentLoaded', function() {
  function setupOrderForm() {
    // 既存データの表示を初期化
    initializeExistingItems();

    // 商品選択時の処理
    setupProductSelects();

    // 数量選択時の処理
    setupQuantitySelects();

    // 単価入力時の処理
    setupUnitPriceInputs();

    // 商品追加ボタンの処理
    setupAddItemButton();

    // 削除ボタンの処理
    setupRemoveButtons();

    // 初期計算
    document.querySelectorAll('#order-items tbody tr:not(.empty-row)').forEach(row => {
      calculateSubtotal(row);
    });

    // 合計金額の更新
    updateOrderTotal();
  }

  function initializeExistingItems() {
    document.querySelectorAll('#order-items tbody tr').forEach(row => {
      const productSelect = row.querySelector('.product-select');
      if (productSelect && productSelect.value) {
        const selectedOption = productSelect.selectedOptions[0];
        const priceDisplay = row.querySelector('.unit-price-display');
        const priceInput = row.querySelector('.unit-price-input');
        const taxRateDisplay = row.querySelector('.tax-rate-display');
        const taxRateInput = row.querySelector('[name*="[tax_rate]"]');

        const price = selectedOption.dataset.price;
        const taxRate = selectedOption.dataset.taxRate;

        if (price && price !== 'null' && price !== '') {
          // 商品に単価が設定されている場合
          priceDisplay.value = price;
          priceInput.value = price;
          priceDisplay.readOnly = true;
        } else {
          // 商品に単価が設定されていない場合
          const currentPrice = priceInput.value;
          priceDisplay.value = currentPrice;
          priceDisplay.readOnly = false;
        }

        if (taxRate) {
          taxRateDisplay.textContent = taxRate;
          taxRateInput.value = taxRate;
        }
      }
    });
  }

  function setupUnitPriceInputs() {
    document.querySelectorAll('.unit-price-display').forEach(input => {
      if (!input.readOnly) {
        input.addEventListener('input', function() {
          const row = this.closest('tr');
          const priceInput = row.querySelector('.unit-price-input');
          // 数値以外の文字を削除
          this.value = this.value.replace(/[^\d]/g, '');
          // hidden inputに値を設定
          priceInput.value = this.value;
          calculateSubtotal(row);
          updateOrderTotal();
        });
      }
    });
  }

  function setupProductSelects() {
    document.querySelectorAll('.product-select').forEach(select => {
      select.addEventListener('change', function() {
        const row = this.closest('tr');
        const selectedOption = this.selectedOptions[0];
        const priceDisplay = row.querySelector('.unit-price-display');
        const priceInput = row.querySelector('.unit-price-input');
        const taxRateDisplay = row.querySelector('.tax-rate-display');
        const taxRateInput = row.querySelector('[name*="[tax_rate]"]');

        if (this.value) {
          // デバッグ情報を出力
          console.log('Selected option HTML:', selectedOption.outerHTML);
          console.log('Selected option value:', selectedOption.value);
          console.log('Selected option text:', selectedOption.textContent);

          const price = selectedOption.getAttribute('data-price');
          const taxRate = selectedOption.getAttribute('data-tax-rate');

          console.log('Price (raw):', price);
          console.log('Tax rate (raw):', taxRate);

          if (price !== null && price !== '') {
            // 商品に単価が設定されている場合
            console.log('Setting fixed price:', price);
            priceDisplay.value = price;
            priceInput.value = price;
            priceDisplay.readOnly = true;
          } else {
            // 商品に単価が設定されていない場合
            console.log('No fixed price, making editable');
            priceDisplay.value = '';
            priceInput.value = '';
            priceDisplay.readOnly = false;
          }

          if (taxRate) {
            taxRateDisplay.textContent = taxRate;
            taxRateInput.value = taxRate;
          }
        } else {
          // 商品が選択されていない場合
          priceDisplay.value = '';
          priceInput.value = '';
          taxRateDisplay.textContent = '';
          taxRateInput.value = '';
          priceDisplay.readOnly = true;
        }

        calculateSubtotal(row);
        updateOrderTotal();
      });
    });
  }

  function setupQuantitySelects() {
    document.querySelectorAll('.quantity-select').forEach(select => {
      select.addEventListener('change', function() {
        const row = this.closest('tr');
        const productSelect = row.querySelector('.product-select');
        if (productSelect && productSelect.value) {
          calculateSubtotal(row);
          updateOrderTotal();
        }
      });
    });
  }

  function calculateSubtotal(row) {
    const productSelect = row.querySelector('.product-select');
    if (!productSelect || !productSelect.value) {
      row.querySelector('.subtotal-without-tax').textContent = '';
      row.querySelector('.subtotal-with-tax').textContent = '';
      return;
    }

    const quantity = parseInt(row.querySelector('.quantity-select').value) || 0;
    const unitPrice = parseFloat(row.querySelector('.unit-price-display').value) || 0;
    const taxRate = parseFloat(row.querySelector('[name*="[tax_rate]"]').value) || 0;

    const subtotalWithoutTax = quantity * unitPrice;
    const subtotalWithTax = subtotalWithoutTax * (1 + taxRate / 100);

    row.querySelector('.subtotal-without-tax').textContent = Math.round(subtotalWithoutTax);
    row.querySelector('.subtotal-with-tax').textContent = Math.round(subtotalWithTax);
  }

  function updateOrderTotal() {
    let totalWithoutTax = 0;
    let totalWithTax = 0;

    document.querySelectorAll('#order-items tbody tr').forEach(row => {
      const productSelect = row.querySelector('.product-select');
      if (productSelect && productSelect.value) {
        totalWithoutTax += parseInt(row.querySelector('.subtotal-without-tax').textContent) || 0;
        totalWithTax += parseInt(row.querySelector('.subtotal-with-tax').textContent) || 0;
      }
    });

    document.getElementById('order-total-without-tax').textContent = totalWithoutTax;
    document.getElementById('order-total-with-tax').textContent = totalWithTax;
  }

  function setupAddItemButton() {
    document.querySelector('.add-item').addEventListener('click', function(e) {
      e.preventDefault();
      const time = new Date().getTime();
      const template = document.querySelector('#order-items tbody tr:last-child').outerHTML;
      const newRow = template.replace(/\d+(?=\])/g, time);

      document.querySelector('#order-items tbody').insertAdjacentHTML('beforeend', newRow);

      const addedRow = document.querySelector('#order-items tbody tr:last-child');
      addedRow.querySelectorAll('select, input').forEach(element => {
        element.value = '';
      });
      addedRow.querySelectorAll('.unit-price-display, .tax-rate-display, .subtotal-without-tax, .subtotal-with-tax').forEach(element => {
        element.textContent = '0';
      });

      setupProductSelects();
      setupQuantitySelects();
      setupRemoveButtons();
    });
  }

  function setupRemoveButtons() {
    document.querySelectorAll('.remove-item').forEach(button => {
      button.addEventListener('click', function(e) {
        e.preventDefault();
        const row = this.closest('tr');
        row.querySelector('[name*="_destroy"]').value = '1';
        row.style.display = 'none';
        updateOrderTotal();
      });
    });
  }

  setupOrderForm();
});