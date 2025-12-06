// マイページのパスワード変更フォーム用のJavaScript
// password_utils.js に依存（パスワード表示/非表示、全角文字検出の機能）

document.addEventListener('DOMContentLoaded', function() {
  const form = document.getElementById('password-change-form');
  const submitBtn = document.getElementById('password-submit-btn');
  const loading = document.getElementById('password-loading');
  const messageContainer = document.getElementById('password-message-container');
  const newPasswordInput = document.getElementById('new_password');
  const passwordFormatWarning = document.getElementById('password-format-warning');
  
  if (!form || !submitBtn || !loading || !messageContainer) {
    return;
  }

  // 共通の全角文字検出機能を使用
  if (newPasswordInput && passwordFormatWarning) {
    setupPasswordFormatValidation(newPasswordInput, {
      warningElement: passwordFormatWarning
    });
  }

  // メッセージを表示する関数
  function showMessage(message, type) {
    const alertClass = type === 'success' ? 'alert-success' : 'alert-danger';
    const alertHTML = `
      <div class="alert ${alertClass} alert-dismissible fade show" role="alert">
        ${message}
        <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="閉じる"></button>
      </div>
    `;
    messageContainer.innerHTML = alertHTML;
    
    // メッセージを表示位置にスクロール（必要に応じて）
    messageContainer.scrollIntoView({ behavior: 'smooth', block: 'nearest' });
  }

  // ボタンの状態をリセットする関数
  function resetButton() {
    submitBtn.disabled = false;
    submitBtn.style.opacity = '1';
    submitBtn.innerHTML = 'パスワードを変更';
    loading.style.display = 'none';
  }

  // フォーム送信時の処理（Ajax送信）
  form.addEventListener('submit', function(e) {
    e.preventDefault(); // デフォルトのフォーム送信を防ぐ
    
    // ボタンを無効化し、ローディングを表示
    submitBtn.disabled = true;
    submitBtn.style.opacity = '0.6';
    submitBtn.innerHTML = '<span class="spinner-border spinner-border-sm me-2" role="status" aria-hidden="true"></span>処理中...';
    loading.style.display = 'block';
    
    // 既存のメッセージをクリア
    messageContainer.innerHTML = '';
    
    // FormDataを作成
    const formData = new FormData(form);
    
    // CSRFトークンを取得
    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.getAttribute('content');
    
    // Ajax送信
    fetch(form.action, {
      method: 'PATCH',
      body: formData,
      headers: {
        'X-CSRF-Token': csrfToken,
        'Accept': 'application/json'
      },
      credentials: 'same-origin'
    })
    .then(function(response) {
      return response.json().then(function(data) {
        return { response: response, data: data };
      });
    })
    .then(function(result) {
      resetButton();
      
      if (result.response.ok && result.data.status === 'success') {
        showMessage(result.data.message, 'success');
        // 成功時はフォームをクリア
        form.reset();
      } else {
        showMessage(result.data.message || 'エラーが発生しました。', 'error');
      }
    })
    .catch(function(error) {
      resetButton();
      console.error('Error:', error);
      showMessage('エラーが発生しました。', 'error');
    });
  });
});

