// 請求書承認機能用のJavaScript

document.addEventListener('DOMContentLoaded', function() {
  // モーダルが閉じられたときにフォームをリセット（Bootstrap 5のイベント）
  document.querySelectorAll('.modal').forEach(function(modalElement) {
    modalElement.addEventListener('hidden.bs.modal', function() {
      var form = this.querySelector('form');
      if (form) {
        form.reset();
      }
    });
  });

  // 一括差し戻しモーダルが開かれたときに選択されたIDを設定
  var bulkRejectModal = document.getElementById('bulkRejectModal');
  if (bulkRejectModal) {
    bulkRejectModal.addEventListener('show.bs.modal', function() {
      var selectedIds = [];
      document.querySelectorAll('.approval-checkbox:checked').forEach(function(checkbox) {
        selectedIds.push(checkbox.value);
      });
      var approvalIdsField = document.getElementById('bulkRejectApprovalIds');
      if (approvalIdsField) {
        approvalIdsField.value = selectedIds.join(',');
      }
    });
  }
});

