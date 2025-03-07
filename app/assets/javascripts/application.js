// 商品選択時にAjaxで情報を取得
$(document).ready(function() {
  console.log("Document ready, setting up product selects");

  // 単価表示フィールドの入力を監視し、隠しフィールドに反映する
  $(document).on('input', '.unit-price-display', function() {
    var displayField = $(this);
    var row = displayField.closest('tr');
    var hiddenField = row.find('.unit-price-input');
    hiddenField.val(displayField.val());
    console.log("Manual price entered:", displayField.val(), "-> hidden field updated");
    calculateLineTotal(row);
  });

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
        // 単価が null の場合は空にしておき、手動入力可能にする
        if (data.unit_price !== null) {
          unitPriceInput.val(data.unit_price);
          unitPriceDisplay.val(data.unit_price);
          unitPriceDisplay.prop('readonly', true);
          console.log("Set unit price to:", data.unit_price);
        } else {
          // 単価がnullの場合は空にして編集可能にする
          unitPriceInput.val('');
          unitPriceDisplay.val('');
          unitPriceDisplay.prop('readonly', false);
          console.log("Unit price is null, allowing manual input");
        }
      }

      // 税率を設定
      var taxRateInput = row.find('input[name*="[tax_rate]"]');
      var taxRateDisplay = row.find('.tax-rate-display');

      if (taxRateInput.length > 0 && taxRateDisplay.length > 0) {
        // 税率が明示的に0でも正しく処理
        var taxRate = data.tax_rate !== undefined ? data.tax_rate : (data.tax_rate_id === 1 ? 10 : 8);
        taxRateInput.val(taxRate);
        taxRateDisplay.text(taxRate);
        console.log("Set tax rate to:", taxRate, "type:", typeof taxRate);
      } else {
        console.log("Tax rate elements not found: input=", taxRateInput.length, "display=", taxRateDisplay.length);
        // すべての要素のデバッグ表示
        row.find('*').each(function() {
          if ($(this).attr('class')) {
            console.log("Element with class:", $(this).attr('class'));
          }
        });
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

    // 受注フォームのHTML全体をリロードして新しい行を取得
    $.ajax({
      url: '/orders/new',
      dataType: 'html',
      success: function(data) {
        console.log("Got order form HTML");

        // 新しい行をテンプレートから抽出
        var newRowHtml = $(data).find('tr.nested-fields').first().prop('outerHTML');
        if (newRowHtml) {
          // タイムスタンプを付与して一意のIDにする
          var time = new Date().getTime();
          var regexp = new RegExp('order_items_attributes_\\d+', 'g');
          newRowHtml = newRowHtml.replace(regexp, 'order_items_attributes_' + time);

          // 値をクリア（hiddenは維持）
          var $newRow = $(newRowHtml);
          $newRow.find('input:not([type="hidden"]), select').each(function() {
            if ($(this).is('select')) {
              $(this).prop('selectedIndex', 0);
            } else {
              $(this).val('');
            }
          });

          // 行を追加
          $('table#order-items tbody').append($newRow);
          console.log("New row added");
        } else {
          console.error("Could not find nested-fields row in template");
        }
      },
      error: function(xhr, status, error) {
        console.error("Error loading template: ", error);
      }
    });

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
    // 表示用入力フィールドから直接値を取得（手動入力値を優先）
    var unitPriceDisplayValue = row.find('.unit-price-display').val();
    var unitPrice = 0;

    if (unitPriceDisplayValue !== undefined && unitPriceDisplayValue !== '') {
      unitPrice = parseFloat(unitPriceDisplayValue) || 0;
    } else {
      // フォールバックとして隠しフィールドを使用
      unitPrice = parseFloat(row.find('.unit-price-input').val()) || 0;
    }

    var quantity = parseInt(row.find('.quantity-select').val()) || 0;

    // 税率は明示的に0も処理
    var taxRateText = row.find('.tax-rate-display').text().trim();
    var taxRate = taxRateText === '' ? 0 : parseFloat(taxRateText);

    console.log("Calculating totals: unitPrice=", unitPrice, "displayValue=", unitPriceDisplayValue, "quantity=", quantity, "taxRate=", taxRate, "taxRateText=", taxRateText);

    // 値が正しいか確認
    if (isNaN(unitPrice) || isNaN(quantity) || isNaN(taxRate)) {
      console.error("Invalid values for calculation: unitPrice=", unitPrice, "quantity=", quantity, "taxRate=", taxRate);
      return;
    }

    // 税抜金額
    var totalWithoutTax = unitPrice * quantity;
    // 税込金額（税率が0の場合も正しく計算）
    var totalWithTax = totalWithoutTax * (1 + (taxRate / 100));

    console.log("Calculated totals: withoutTax=", totalWithoutTax, "withTax=", totalWithTax);

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

      // 削除マークされた行はスキップ
      var destroyField = row.find('input[name*="[_destroy]"]');
      if (destroyField.length > 0 && destroyField.val() === "1") {
        console.log("Skipping deleted row in total calculation");
        return true; // continueと同じ
      }

      // 非表示の行もスキップ（CSSでdisplay:noneが設定されている場合）
      if (row.css('display') === 'none') {
        console.log("Skipping hidden row in total calculation");
        return true;
      }

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