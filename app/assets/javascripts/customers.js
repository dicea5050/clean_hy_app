// 顧客フォーム用のJavaScript
// password_utils.js に依存（パスワード表示/非表示、全角文字検出の機能）

document.addEventListener('DOMContentLoaded', function() {
  const passwordInput = document.getElementById('customer_password');
  const passwordConfirmationInput = document.getElementById('customer_password_confirmation');
  
  // 共通の全角文字検出機能を使用
  if (passwordInput) {
    setupPasswordFormatValidation(passwordInput);
  }
  
  if (passwordConfirmationInput) {
    setupPasswordFormatValidation(passwordConfirmationInput);
  }
});
