// 外部JavaScriptファイルを明示的に読み込み
//= require delivery_locations_form
//= require order_calculations

// 商品選択時にAjaxで情報を取得
$(document).ready(function() {
  console.log("Document ready, setting up product selects");

  // 注：単価表示フィールドの入力監視はorder_calculations.jsに移動しました

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

      // 数量セレクトボックスをリセット
      var quantitySelect = row.find('.quantity-select');
      if (quantitySelect.length > 0) {
        // 既存の注文かどうか判断（URL内に/edit がある場合は編集モード）
        var isEditMode = window.location.pathname.indexOf('/edit') > -1;

        // 編集モードで既存の数量がある場合のみ値を保持
        if (isEditMode && quantitySelect.val() !== '') {
          console.log("Edit mode - keeping quantity value:", quantitySelect.val());
          // 既存の数量があれば、その値で小計を計算する
          calculateLineTotal(row);
        } else {
          // それ以外の場合は空にリセット
          quantitySelect.val('');
          console.log("Reset quantity select to empty");
        }
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
      // 注：計算関数はorder_calculations.jsに移動しました
    });
  });

  // 注：以下のイベントハンドラはorder_calculations.jsに移動しました

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

  console.log("Product selects setup complete");
});