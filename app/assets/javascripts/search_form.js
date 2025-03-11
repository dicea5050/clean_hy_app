// 検索フォームの共通機能
document.addEventListener('DOMContentLoaded', function() {
  // 検索フォームの表示制御（URLにsearchパラメータがある場合はフォームを開く）
  const searchCollapse = document.getElementById('searchCollapse');
  if (searchCollapse) {
    const searchParams = new URLSearchParams(window.location.search);

    // URLに検索パラメータがある場合は検索フォームを開く
    if (searchParams.has('search') || searchParams.has('customer_name') ||
        searchParams.has('invoice_number') || searchParams.has('order_number')) {
      const searchCollapseInstance = new bootstrap.Collapse(searchCollapse, {
        toggle: true
      });
    }
  }

  // 日付範囲入力のバリデーション
  const dateFromInputs = document.querySelectorAll('[name$="_from"], [name$="_date_from"]');

  dateFromInputs.forEach(input => {
    const name = input.name;
    let toInputName = name.replace('_from', '_to');

    // order_date_from -> order_date_to のような命名規則に対応
    if (!toInputName.match(/_to$/)) {
      toInputName = name.replace('_date_from', '_date_to');
    }

    const toInput = document.querySelector(`[name="${toInputName}"]`);

    if (toInput) {
      // 開始日が終了日より後の場合はエラー
      input.addEventListener('change', function() {
        if (this.value && toInput.value && this.value > toInput.value) {
          alert('開始日は終了日よりも前の日付を選択してください');
          this.value = '';
        }
      });

      // 終了日が開始日より前の場合はエラー
      toInput.addEventListener('change', function() {
        if (this.value && input.value && input.value > this.value) {
          alert('終了日は開始日よりも後の日付を選択してください');
          this.value = '';
        }
      });
    }
  });
});