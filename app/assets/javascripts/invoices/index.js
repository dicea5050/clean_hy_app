// 請求書一覧ページ用のJavaScript（jQuery不使用）

document.addEventListener('DOMContentLoaded', function() {
  // 一括承認申請ボタンとパスを取得
  const bulkRequestApprovalBtn = document.getElementById('bulk-request-approval-btn');
  const bulkRequestApprovalPath = bulkRequestApprovalBtn ? bulkRequestApprovalBtn.dataset.bulkRequestApprovalPath : null;

  // 全選択チェックボックス（差し戻しステータスの請求書のみ選択）
  const selectAllCheckbox = document.getElementById('select-all');
  if (selectAllCheckbox) {
    selectAllCheckbox.addEventListener('change', function() {
      const enabledCheckboxes = document.querySelectorAll('.invoice-checkbox:not(:disabled)');
      enabledCheckboxes.forEach(function(checkbox) {
        checkbox.checked = this.checked;
      }, this);
      updateBulkButtonState();
    });
  }

  // 個別チェックボックスの変更
  document.addEventListener('change', function(event) {
    if (event.target.classList.contains('invoice-checkbox')) {
      // 全選択チェックボックスの状態を更新（差し戻しステータスの請求書のみをカウント）
      const totalCheckboxes = document.querySelectorAll('.invoice-checkbox:not(:disabled)').length;
      const checkedCheckboxes = document.querySelectorAll('.invoice-checkbox:checked').length;
      if (selectAllCheckbox) {
        selectAllCheckbox.checked = totalCheckboxes > 0 && totalCheckboxes === checkedCheckboxes;
      }
      updateBulkButtonState();
    }
  });

  // 一括承認申請ボタンのクリック
  if (bulkRequestApprovalBtn && bulkRequestApprovalPath) {
    bulkRequestApprovalBtn.addEventListener('click', function() {
      const selectedCheckboxes = document.querySelectorAll('.invoice-checkbox:checked');
      const selectedIds = Array.from(selectedCheckboxes).map(function(checkbox) {
        return checkbox.value;
      });

      if (selectedIds.length === 0) {
        alert('請求書を選択してください。');
        return;
      }

      if (!confirm('選択した請求書を承認申請しますか？')) {
        return;
      }

      // フォームを作成して送信
      const form = document.createElement('form');
      form.method = 'POST';
      form.action = bulkRequestApprovalPath;

      const tokenInput = document.createElement('input');
      tokenInput.type = 'hidden';
      tokenInput.name = 'authenticity_token';
      const csrfToken = document.querySelector('meta[name="csrf-token"]');
      if (csrfToken) {
        tokenInput.value = csrfToken.getAttribute('content');
      }
      form.appendChild(tokenInput);

      const invoiceIdsInput = document.createElement('input');
      invoiceIdsInput.type = 'hidden';
      invoiceIdsInput.name = 'invoice_ids';
      invoiceIdsInput.value = selectedIds.join(',');
      form.appendChild(invoiceIdsInput);

      document.body.appendChild(form);
      form.submit();
    });
  }

  // ボタンの有効/無効を更新
  function updateBulkButtonState() {
    const checkedCheckboxes = document.querySelectorAll('.invoice-checkbox:checked');
    const hasChecked = checkedCheckboxes.length > 0;
    if (bulkRequestApprovalBtn) {
      bulkRequestApprovalBtn.disabled = !hasChecked;
    }
  }

  // 初期状態を設定
  updateBulkButtonState();

  // 顧客コード・取引先名連動機能を初期化
  if (window.CustomerCodeSearch) {
    window.CustomerCodeSearch.init({
      customerCodeSelector: 'input[name="search[customer_code]"]',
      customerSelectSelector: '#invoice_company_name_search',
      customerIdSelector: null,
      findCustomerApiUrl: '/orders/find_customer_by_code',
      enableSelect2: true,
      onCustomerChange: function(customerId, customerData) {
        // 検索フォームなので特に追加処理は不要
      },
      onCustomerClear: function() {
        // 検索フォームなので特に追加処理は不要
      }
    });
  }
});

