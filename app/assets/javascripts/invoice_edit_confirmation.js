// 承認済み請求書の編集確認ダイアログ
document.addEventListener('DOMContentLoaded', function() {
  // 一覧画面・詳細画面の「編集」ボタンクリック時の確認ダイアログ
  // イベント委譲を使用して動的に追加される要素にも対応
  document.addEventListener('click', function(e) {
    const editButton = e.target.closest('.edit-approved-invoice');
    if (editButton) {
      if (!confirm('承認済み請求書ですが、本当に編集しますか？')) {
        e.preventDefault();
        return false;
      }
    }
  });

  // 編集画面のフォーム送信時の確認ダイアログ
  // 検索フォーム（id="search-form"）を除外し、編集画面のフォームのみを対象とする
  const invoiceForm = document.querySelector('form[action*="/invoices"]:not(#search-form)');
  if (invoiceForm) {
    // フォームが編集画面のものかどうかを確認（承認済み請求書の場合のみ）
    const approvalStatusBadge = document.querySelector('.badge.bg-success');
    if (approvalStatusBadge && approvalStatusBadge.textContent.trim() === '承認済み') {
      invoiceForm.addEventListener('submit', function(event) {
        event.preventDefault();
        if (confirm('承認済み請求書ですが、本当に編集しますか？')) {
          this.submit();
        }
      });
    }
  }
});

