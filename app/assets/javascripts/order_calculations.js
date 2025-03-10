// 注文明細の小計と合計を計算するための関数
(function(window) {
  // 小計の計算関数 - 各行の小計を計算
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

  // ページ読み込み時に各行の計算と合計を実行する初期化関数
  function initializeOrderCalculations() {
    console.log('注文計算機能の初期化を開始します');
    // セレクタを修正: テーブル内の全ての行に対して処理
    $('#order-items tbody tr').each(function() {
      var row = $(this);
      // 商品選択や数量が既に入力されている場合のみ計算する
      if (row.find('.product-select').val() && row.find('.quantity-select').val()) {
        calculateLineTotal(row);
      }
    });
    calculateOrderTotal();
    console.log('注文計算機能の初期化が完了しました');
  }

  // グローバルスコープに関数を公開
  window.calculateLineTotal = calculateLineTotal;
  window.calculateOrderTotal = calculateOrderTotal;
  window.initializeOrderCalculations = initializeOrderCalculations;

  // DOM読み込み完了時に初期化関数を実行
  $(document).ready(function() {
    initializeOrderCalculations();

    // Turbolinksでのページ読み込み時にも対応
    $(document).on('turbolinks:load page:load', function() {
      initializeOrderCalculations();
    });

    // 数量変更時に計算実行
    $(document).on('change', '.quantity-select', function() {
      calculateLineTotal($(this).closest('tr'));
    });

    // 単価変更時に計算実行
    $(document).on('input', '.unit-price-display', function() {
      var displayField = $(this);
      var row = displayField.closest('tr');
      var hiddenField = row.find('.unit-price-input');
      hiddenField.val(displayField.val());
      console.log("Manual price entered:", displayField.val(), "-> hidden field updated");
      calculateLineTotal(row);
    });

    // 数量または単価変更時に小計を計算（統合イベントハンドラ）
    $(document).on('input change', '.unit-price-display, .quantity-select', function() {
      var row = $(this).closest('tr');
      calculateLineTotal(row);
    });

    // 税率変更時に小計を再計算
    $(document).on('change', 'select[name*="[tax_rate]"]', function() {
      var row = $(this).closest('tr');
      calculateLineTotal(row);
    });
  });
})(window);
