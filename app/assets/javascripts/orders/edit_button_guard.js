// 請求書発行済みの受注情報の編集ボタンをガードする
document.addEventListener('DOMContentLoaded', function() {
  const editOrderBtns = document.querySelectorAll('.edit-order-btn');
  editOrderBtns.forEach(btn => {
    btn.addEventListener('click', function(event) {
      const hasPendingOrApprovedInvoice = this.dataset.hasPendingOrApprovedInvoice === 'true';

      if (hasPendingOrApprovedInvoice) {
        event.preventDefault();
        alert('請求済みのため編集できません。先に請求書を削除してください');
        return false;
      }
    });
  });
});

