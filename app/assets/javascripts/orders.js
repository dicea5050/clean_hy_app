console.log('Orders.js loaded');

// 最小限のJavaScriptに修正
document.addEventListener('DOMContentLoaded', function() {
  console.log('DOM fully loaded');
  setupOrderForm();
});

document.addEventListener('turbolinks:load', function() {
  console.log('Turbolinks loaded');
  setupOrderForm();
});

// メイン処理をまとめた関数
function setupOrderForm() {
  console.log('Setting up order form');
  
  // 既存データの表示を初期化
  initializeExistingItems();
  
  // 商品選択時の処理
  setupProductSelects();
  
  // 数量選択時の処理
  setupQuantitySelects();
  
  // 商品追加ボタンの処理
  setupAddItemButton();
  
  // 削除ボタンの処理
  setupRemoveButtons();
  
  // 初期計算
  document.querySelectorAll('#order-items tbody tr').forEach(function(row) {
    calculateSubtotal(row);
  });
  
  // 合計金額の更新
  updateOrderTotal();
}

// 既存データの表示を初期化する関数
function initializeExistingItems() {
  console.log('Initializing existing items');
  
  document.querySelectorAll('#order-items tbody tr').forEach(function(row) {
    // 単価の表示を設定
    const unitPriceInput = row.querySelector('input[name*="[unit_price]"]');
    const unitPriceDisplay = row.querySelector('.unit-price-display');
    if (unitPriceInput && unitPriceInput.value && unitPriceDisplay) {
      unitPriceDisplay.textContent = parseFloat(unitPriceInput.value).toLocaleString();
    }
    
    // 税率の表示を設定
    const taxRateInput = row.querySelector('input[name*="[tax_rate]"]');
    const taxRateDisplay = row.querySelector('.tax-rate-display');
    if (taxRateInput && taxRateInput.value && taxRateDisplay) {
      taxRateDisplay.textContent = taxRateInput.value;
    }
    
    // 商品が選択されている場合、data属性を設定
    const productSelect = row.querySelector('.product-select');
    if (productSelect && productSelect.value) {
      const selectedOption = productSelect.options[productSelect.selectedIndex];
      if (!selectedOption.getAttribute('data-price') && unitPriceInput) {
        selectedOption.setAttribute('data-price', unitPriceInput.value);
      }
      if (!selectedOption.getAttribute('data-tax-rate') && taxRateInput) {
        selectedOption.setAttribute('data-tax-rate', taxRateInput.value);
      }
    }
    
    // 小計の計算と表示
    calculateSubtotal(row);
  });
}

// 商品選択時の処理
function setupProductSelects() {
  console.log('Setting up product selects');
  document.querySelectorAll('.product-select').forEach(function(select) {
    select.addEventListener('change', function() {
      console.log('Product select changed:', this.value);
      const row = this.closest('tr');
      const selectedOption = this.options[this.selectedIndex];
      
      if (selectedOption.value) {
        const price = selectedOption.getAttribute('data-price');
        const taxRate = selectedOption.getAttribute('data-tax-rate');
        console.log('Selected product with price:', price, 'tax rate:', taxRate);
        
        // 単価と税率をフォームに設定
        row.querySelector('input[name*="[unit_price]"]').value = price;
        row.querySelector('.unit-price-display').textContent = price;
        
        row.querySelector('input[name*="[tax_rate]"]').value = taxRate;
        row.querySelector('.tax-rate-display').textContent = taxRate;
        
        // 数量があれば小計を計算
        calculateSubtotal(row);
      } else {
        // 未選択時はクリア
        row.querySelector('input[name*="[unit_price]"]').value = '';
        row.querySelector('.unit-price-display').textContent = '0';
        
        row.querySelector('input[name*="[tax_rate]"]').value = '';
        row.querySelector('.tax-rate-display').textContent = '0';
        
        row.querySelector('.subtotal-without-tax').textContent = '0';
        row.querySelector('.subtotal-with-tax').textContent = '0';
      }
      
      // 注文合計を更新
      updateOrderTotal();
    });
  });
}

// 数量選択時の処理
function setupQuantitySelects() {
  document.querySelectorAll('.quantity-select').forEach(function(select) {
    select.addEventListener('change', function() {
      console.log('Quantity changed');
      const row = this.closest('tr');
      calculateSubtotal(row);
      updateOrderTotal();
    });
  });
}

// 小計の計算
function calculateSubtotal(row) {
  const unitPrice = parseFloat(row.querySelector('input[name*="[unit_price]"]').value) || 0;
  const quantity = parseInt(row.querySelector('.quantity-select').value) || 0;
  const taxRate = parseFloat(row.querySelector('input[name*="[tax_rate]"]').value) || 0;
  
  // 税抜小計
  const subtotalWithoutTax = unitPrice * quantity;
  // 税込小計
  const subtotalWithTax = subtotalWithoutTax * (1 + taxRate / 100);
  
  console.log('Calculating subtotal:', unitPrice, 'x', quantity, '=', subtotalWithoutTax, '(税抜), 税込:', subtotalWithTax);
  
  row.querySelector('.subtotal-without-tax').textContent = subtotalWithoutTax.toLocaleString();
  row.querySelector('.subtotal-with-tax').textContent = subtotalWithTax.toLocaleString();
}

// 注文合計の更新
function updateOrderTotal() {
  let totalWithoutTax = 0;
  let totalWithTax = 0;
  
  document.querySelectorAll('#order-items tbody tr').forEach(function(row) {
    // 表示されている行（削除されていない行）のみを合計対象とする
    if (row.style.display !== 'none') {
      const subtotalWithoutTaxElement = row.querySelector('.subtotal-without-tax');
      const subtotalWithTaxElement = row.querySelector('.subtotal-with-tax');
      
      const subtotalWithoutTax = parseInt(subtotalWithoutTaxElement.textContent.replace(/,/g, '')) || 0;
      const subtotalWithTax = parseInt(subtotalWithTaxElement.textContent.replace(/,/g, '')) || 0;
      
      totalWithoutTax += subtotalWithoutTax;
      totalWithTax += subtotalWithTax;
    }
  });
  
  console.log('Updating order total - 税抜:', totalWithoutTax, '税込:', totalWithTax);
  
  const orderTotalWithoutTax = document.getElementById('order-total-without-tax');
  const orderTotalWithTax = document.getElementById('order-total-with-tax');
  
  if (orderTotalWithoutTax) {
    orderTotalWithoutTax.textContent = totalWithoutTax.toLocaleString();
  }
  
  if (orderTotalWithTax) {
    orderTotalWithTax.textContent = totalWithTax.toLocaleString();
  }
}

// 商品追加ボタンの処理
function setupAddItemButton() {
  const addItemButton = document.querySelector('.add-item');
  if (addItemButton) {
    addItemButton.addEventListener('click', function(e) {
      e.preventDefault();
      console.log('Add item button clicked');
      
      // テーブルボディを取得
      const tbody = document.querySelector('#order-items tbody');
      
      // 表示されている行がない場合のチェック
      const visibleRows = Array.from(tbody.querySelectorAll('tr')).filter(function(row) {
        return row.style.display !== 'none';
      });
      
      if (visibleRows.length === 0) {
        console.log('No visible rows, creating new row from template');
        
        // テンプレート行を使用するか、新しい行を作成
        const hiddenRow = tbody.querySelector('tr');
        if (hiddenRow) {
          // 非表示になっている行があればそれをコピー
          const newRow = hiddenRow.cloneNode(true);
          // 表示に変更
          newRow.style.display = '';
          
          // 入力値をクリア
          newRow.querySelectorAll('select, input').forEach(function(input) {
            if (input.name && !input.name.includes('_destroy')) {
              // IDを新しく設定
              const newId = new Date().getTime();
              input.name = input.name.replace(/\d+/, newId);
              input.id = input.id ? input.id.replace(/\d+/, newId) : '';
              
              // 値をクリア
              if (input.tagName === 'SELECT') {
                input.selectedIndex = 0;
              } else {
                input.value = '';
              }
            }
          });
          
          // 表示値もクリア
          newRow.querySelector('.unit-price-display').textContent = '0';
          newRow.querySelector('.tax-rate-display').textContent = '0';
          newRow.querySelector('.subtotal-without-tax').textContent = '0';
          newRow.querySelector('.subtotal-with-tax').textContent = '0';
          
          // 削除フラグをリセット
          const destroyField = newRow.querySelector('input[name*="[_destroy]"]');
          if (destroyField) {
            destroyField.value = 'false';
          }
          
          // 行を追加
          tbody.appendChild(newRow);
          
          // 新しい行のイベントを設定
          setupRowEvents(newRow);
        } else {
          // 非表示行もない場合は、新規行のHTMLを直接作成（最終手段）
          createNewRowFromScratch(tbody);
        }
      } else {
        // 既存の行がある場合は従来通りコピー
        const firstRow = visibleRows[0];
        const newRow = firstRow.cloneNode(true);
        
        // 入力値をクリア
        newRow.querySelectorAll('select, input').forEach(function(input) {
          if (input.name && !input.name.includes('_destroy')) {
            // IDを新しく設定
            const newId = new Date().getTime();
            input.name = input.name.replace(/\d+/, newId);
            input.id = input.id ? input.id.replace(/\d+/, newId) : '';
            
            // 値をクリア
            if (input.tagName === 'SELECT') {
              input.selectedIndex = 0;
            } else {
              input.value = '';
            }
          }
        });
        
        // 表示値もクリア
        newRow.querySelector('.unit-price-display').textContent = '0';
        newRow.querySelector('.tax-rate-display').textContent = '0';
        newRow.querySelector('.subtotal-without-tax').textContent = '0';
        newRow.querySelector('.subtotal-with-tax').textContent = '0';
        
        // 行を追加
        tbody.appendChild(newRow);
        
        // 新しい行のイベントを設定
        setupRowEvents(newRow);
      }
    });
  }
}

// 最悪の場合用：行を手動で作成する関数
function createNewRowFromScratch(tbody) {
  console.log('Creating brand new row from scratch');
  
  // 現在の時刻をIDとして使用
  const newId = new Date().getTime();
  
  // 行のHTML
  const rowHtml = `
    <tr class="nested-fields">
      <td>
        <select name="order[order_items_attributes][${newId}][product_id]" id="order_order_items_attributes_${newId}_product_id" class="form-control product-select" style="width: 100%;" required>
          <option value="">商品を選択してください</option>
          ${generateProductOptions()}
        </select>
      </td>
      <td>
        <input type="hidden" name="order[order_items_attributes][${newId}][unit_price]" id="order_order_items_attributes_${newId}_unit_price">
        <span class="unit-price-display" style="display: inline-block; min-width: 80px; text-align: right;">0</span>円
      </td>
      <td>
        <input type="hidden" name="order[order_items_attributes][${newId}][tax_rate]" id="order_order_items_attributes_${newId}_tax_rate">
        <span class="tax-rate-display" style="text-align: right; display: inline-block; min-width: 30px;">0</span>%
      </td>
      <td>
        <select name="order[order_items_attributes][${newId}][quantity]" id="order_order_items_attributes_${newId}_quantity" class="form-control quantity-select" style="width: 100%;" required>
          <option value="">数量</option>
          ${generateQuantityOptions()}
        </select>
      </td>
      <td>
        <span class="subtotal-without-tax" style="display: inline-block; min-width: 120px; text-align: right;">0</span>円
      </td>
      <td>
        <span class="subtotal-with-tax" style="display: inline-block; min-width: 120px; text-align: right;">0</span>円
      </td>
      <td class="text-center">
        <input type="hidden" name="order[order_items_attributes][${newId}][_destroy]" id="order_order_items_attributes_${newId}__destroy" value="false">
        <a href="#" class="btn btn-sm btn-danger remove-item">削除</a>
      </td>
    </tr>
  `;
  
  // 行を追加
  tbody.insertAdjacentHTML('beforeend', rowHtml);
  
  // 新しい行にイベントを設定
  const newRow = tbody.lastElementChild;
  setupRowEvents(newRow);
}

// 商品選択肢を生成
function generateProductOptions() {
  // この部分はサーバーサイドで生成するのが理想的ですが、
  // クライアント側で簡易的に対応
  return '';
}

// 数量選択肢を生成
function generateQuantityOptions() {
  let options = '';
  for (let i = 1; i <= 10; i++) {
    options += `<option value="${i}">${i}</option>`;
  }
  return options;
}

// 行に各種イベント設定
function setupRowEvents(row) {
  // 商品選択イベント
  const productSelect = row.querySelector('.product-select');
  if (productSelect) {
    productSelect.addEventListener('change', function() {
      const selectedOption = this.options[this.selectedIndex];
      if (selectedOption.value) {
        const price = selectedOption.getAttribute('data-price');
        const taxRate = selectedOption.getAttribute('data-tax-rate');
        
        row.querySelector('input[name*="[unit_price]"]').value = price;
        row.querySelector('.unit-price-display').textContent = price;
        
        row.querySelector('input[name*="[tax_rate]"]').value = taxRate;
        row.querySelector('.tax-rate-display').textContent = taxRate;
        
        calculateSubtotal(row);
        updateOrderTotal();
      }
    });
  }
  
  // 数量選択イベント
  const quantitySelect = row.querySelector('.quantity-select');
  if (quantitySelect) {
    quantitySelect.addEventListener('change', function() {
      calculateSubtotal(row);
      updateOrderTotal();
    });
  }
  
  // 削除ボタンイベント
  const removeButton = row.querySelector('.remove-item');
  if (removeButton) {
    removeButton.addEventListener('click', function(e) {
      e.preventDefault();
      const destroyField = row.querySelector('input[name*="[_destroy]"]');
      destroyField.value = '1';
      row.style.display = 'none';
      updateOrderTotal();
    });
  }
}

// 削除ボタンの処理
function setupRemoveButtons() {
  document.querySelectorAll('.remove-item').forEach(function(button) {
    button.addEventListener('click', function(e) {
      e.preventDefault();
      console.log('Remove button clicked');
      const row = this.closest('tr');
      
      // 削除フラグを設定
      const destroyField = row.querySelector('input[name*="[_destroy]"]');
      destroyField.value = '1';
      
      // 行を非表示
      row.style.display = 'none';
      
      // 注文合計を更新
      updateOrderTotal();
    });
  });
} 