// 郵便番号自動入力機能はyubinbangoを使用するため、このファイルは空にしました
// yubinbangoの設定は app/views/customers/_form.html.erb と app/views/layouts/application.html.erb にあります

// 請求書送付方法に応じてメールアドレスの必須マークを表示/非表示
document.addEventListener('DOMContentLoaded', function() {
  const invoiceDeliveryMethodSelect = document.getElementById('customer_invoice_delivery_method');
  const emailRequiredMark = document.getElementById('email_required_mark');
  const emailField = document.getElementById('customer_email');
  
  if (invoiceDeliveryMethodSelect && emailRequiredMark) {
    // 初期状態を設定
    function updateEmailRequiredMark() {
      if (invoiceDeliveryMethodSelect.value === 'electronic') {
        emailRequiredMark.style.display = 'inline';
        if (emailField) {
          emailField.setAttribute('required', 'required');
        }
      } else {
        emailRequiredMark.style.display = 'none';
        if (emailField) {
          emailField.removeAttribute('required');
        }
      }
    }
    
    // 初期状態を設定
    updateEmailRequiredMark();
    
    // 請求書送付方法が変更されたときに更新
    invoiceDeliveryMethodSelect.addEventListener('change', function() {
      updateEmailRequiredMark();
      
      // 電子請求に変更した場合でメールアドレスが空の場合、アラートを表示
      if (this.value === 'electronic' && emailField && !emailField.value.trim()) {
        alert('電子請求を選択した場合はメールアドレスが必須です。メールアドレスを入力してください。');
      }
    });
    
    // フォーム送信時のバリデーション
    const form = invoiceDeliveryMethodSelect.closest('form');
    if (form) {
      form.addEventListener('submit', function(event) {
        if (invoiceDeliveryMethodSelect.value === 'electronic' && emailField && !emailField.value.trim()) {
          event.preventDefault();
          alert('電子請求を選択した場合はメールアドレスが必須です。メールアドレスを入力してください。');
          emailField.focus();
          return false;
        }
      });
    }
  }
});
