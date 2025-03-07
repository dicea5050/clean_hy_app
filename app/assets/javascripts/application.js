// 商品選択時にAjaxで情報を取得
$(document).ready(function() {
  console.log("Document ready, setting up product selects");

  // 商品選択時の処理
  $(document).on('change', '.product-select', function() {
    var select = $(this);
    console.log("Product selected:", select.val());
    var productId = select.val();
    if (!productId) return;

    var row = select.closest('tr');
    console.log("Found row:", row);

    // Ajaxリクエスト
    $.getJSON("/products/" + productId + ".json", function(data) {
      console.log("Product data:", data);

      // 単価を設定
      var unitPriceInput = row.find('.unit-price-input');
      var unitPriceDisplay = row.find('.unit-price-display');

      if (unitPriceInput.length > 0 && unitPriceDisplay.length > 0) {
        unitPriceInput.val(data.unit_price);
        unitPriceDisplay.val(data.unit_price);
        console.log("Set unit price to:", data.unit_price);
      }

      // 税率を設定
      var taxRateSelect = row.find('select[name*="[tax_rate]"]');
      if (taxRateSelect.length > 0) {
        taxRateSelect.val(data.tax_rate_id);
        console.log("Set tax rate to:", taxRateSelect.find("option:selected").text());
      }

      // デバッグ用：全フィールドの名前を表示
      var allFieldNames = [];
      row.find('input, select').each(function() {
        if ($(this).attr('name')) {
          allFieldNames.push($(this).attr('name'));
        } else if ($(this).attr('class')) {
          allFieldNames.push($(this).attr('class'));
        }
      });
      console.log("All fields in row:", allFieldNames);

      // 数量が既に入力されていれば、小計を計算する
      calculateLineTotal(row);
    });
  });

  // 数量または単価変更時に小計を計算
  $(document).on('input change', '.unit-price-display, .quantity-select', function() {
    var row = $(this).closest('tr');
    calculateLineTotal(row);
  });

  // 税率変更時に小計を再計算
  $(document).on('change', 'select[name*="[tax_rate]"]', function() {
    var row = $(this).closest('tr');
    calculateLineTotal(row);
  });

  // 商品を追加ボタン
  $('.add-item').on('click', function(e) {
    e.preventDefault();
    console.log("Add item button clicked");

    var time = new Date().getTime();
    var regexp = new RegExp('\\d+', 'g');
    var newRow = $('tr.nested-fields:last').clone();

    // クローンした行のIDと名前を更新
    newRow.find('input, select').each(function() {
      var elem = $(this);
      var name = elem.attr('name');
      var id = elem.attr('id');

      if (name) {
        elem.attr('name', name.replace(regexp, time));
      }
      if (id) {
        elem.attr('id', id.replace(regexp, time));
      }

      // 値をクリア
      if (elem.is('input:not([type="hidden"])')){
        elem.val('');
      } else if (elem.is('select')) {
        elem.prop('selectedIndex', 0);
      }
    });

    // 行を追加
    $('tbody').append(newRow);
    console.log("New row added");

    return false;
  });

  // 行の削除ボタン
  $(document).on('click', '.remove-item', function(e) {
    e.preventDefault();
    console.log("Remove item button clicked");

    var row = $(this).closest('tr');
    var destroyField = row.find('input[name*="[_destroy]"]');

    if (destroyField.length) {
      // 既存レコードの場合は非表示にして_destroyフラグを立てる
      destroyField.val("1");
      row.hide();
    } else {
      // 新規追加レコードの場合は行を削除
      row.remove();
    }

    // 合計を再計算
    calculateOrderTotal();

    return false;
  });

  // 小計と合計の計算関数
  function calculateLineTotal(row) {
    var unitPrice = parseFloat(row.find('.unit-price-input').val()) || 0;
    var quantity = parseInt(row.find('.quantity-select').val()) || 0;
    var taxRateValue = row.find('input[name*="[tax_rate]"]').val();
    var taxRate = parseFloat(taxRateValue) || 0;

    console.log("Calculating totals: unitPrice=", unitPrice, "quantity=", quantity, "taxRate=", taxRate);

    // 税抜金額
    var totalWithoutTax = unitPrice * quantity;
    // 税込金額
    var totalWithTax = totalWithoutTax * (1 + (taxRate / 100));

    // 表示を更新
    row.find('.subtotal-without-tax').text(Math.round(totalWithoutTax).toLocaleString());
    row.find('.subtotal-with-tax').text(Math.round(totalWithTax).toLocaleString());

    // 全ての行の合計を計算
    calculateOrderTotal();
  }

  // 注文合計の計算
  function calculateOrderTotal() {
    var orderTotalWithoutTax = 0;
    var orderTotalWithTax = 0;

    $('tbody tr').each(function() {
      var row = $(this);
      var lineWithoutTax = parseFloat(row.find('.subtotal-without-tax').text().replace(/,/g, '')) || 0;
      var lineWithTax = parseFloat(row.find('.subtotal-with-tax').text().replace(/,/g, '')) || 0;

      orderTotalWithoutTax += lineWithoutTax;
      orderTotalWithTax += lineWithTax;
    });

    // 合計を表示
    $('#order-total-without-tax').text(orderTotalWithoutTax.toLocaleString());
    $('#order-total-with-tax').text(orderTotalWithTax.toLocaleString());
  }

  console.log("Product selects setup complete");
});