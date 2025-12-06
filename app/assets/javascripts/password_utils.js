// パスワード関連の共通ユーティリティ関数

// パスワード表示/非表示を切り替える関数
function togglePasswordVisibility(inputId, toggleId) {
  const input = document.getElementById(inputId);
  const toggle = document.getElementById(toggleId);
  
  if (input && toggle) {
    if (input.type === 'password') {
      input.type = 'text';
      toggle.querySelector('.password-toggle-icon').textContent = '🙈';
    } else {
      input.type = 'password';
      toggle.querySelector('.password-toggle-icon').textContent = '👁️';
    }
  }
}

// パスワードの無効な文字を検出する関数（全角文字、半角スペースなど）
function hasFullWidthCharacters(str) {
  if (!str) return false;
  
  // 半角スペースを検出
  if (str.includes(' ')) {
    return true;
  }
  
  // 方法1: 半角文字のみを許可（!から~まで、スペース(0x20)は除外）
  // これ以外の文字が含まれていれば全角文字と判定
  if (!str.match(/^[\x21-\x7E]*$/)) {
    return true;
  }
  
  // 方法2: 全角英数字を明示的に検出（より確実な検出のため）
  // 全角英字大文字: U+FF21-FF3A (Ａ-Ｚ)
  // 全角英字小文字: U+FF41-FF5A (ａ-ｚ)
  // 全角数字: U+FF10-FF19 (０-９)
  // 全角記号: U+FF01-FF0F, U+FF1A-FF1F, U+FF3B-FF40, U+FF5B-FF5E など
  const fullWidthPattern = /[\uFF01-\uFF5E\u3000-\u303F\u3040-\u309F\u30A0-\u30FF\u4E00-\u9FAF]/;
  if (fullWidthPattern.test(str)) {
    return true;
  }
  
  return false;
}

// パスワードフィールドに全角文字検出機能を追加する関数
// options: { warningElement, warningMessage, warningClass }
function setupPasswordFormatValidation(inputElement, options) {
  if (!inputElement) return;
  
  const defaultOptions = {
    warningMessage: '⚠️ 全角文字または半角スペースが検出されました。半角英数字と記号のみ使用してください（スペースは使用できません）。',
    warningClass: 'text-danger mt-1 password-format-warning'
  };
  
  const opts = Object.assign({}, defaultOptions, options);
  
  inputElement.addEventListener('input', function() {
    const value = this.value;
    if (hasFullWidthCharacters(value)) {
      this.classList.add('is-invalid');
      
      // 警告メッセージを表示
      if (opts.warningElement) {
        // 既存の要素を使用する場合（マイページなど）
        opts.warningElement.textContent = opts.warningMessage;
        opts.warningElement.style.display = 'block';
      } else {
        // 動的に要素を作成する場合（顧客フォームなど）
        let warning = this.parentElement.querySelector('.password-format-warning');
        if (!warning) {
          warning = document.createElement('div');
          warning.className = opts.warningClass;
          warning.textContent = opts.warningMessage;
          this.parentElement.appendChild(warning);
        }
      }
    } else {
      this.classList.remove('is-invalid');
      
      if (opts.warningElement) {
        opts.warningElement.style.display = 'none';
      } else {
        const warning = inputElement.parentElement.querySelector('.password-format-warning');
        if (warning) {
          warning.remove();
        }
      }
    }
  });
}

// グローバルスコープに公開
window.togglePasswordVisibility = togglePasswordVisibility;
window.hasFullWidthCharacters = hasFullWidthCharacters;
window.setupPasswordFormatValidation = setupPasswordFormatValidation;

