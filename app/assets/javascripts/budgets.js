// 予算管理画面の合計自動計算と3桁区切り表示
document.addEventListener('DOMContentLoaded', function() {
  // 数値を3桁区切りにフォーマット
  function formatNumber(value) {
    const num = parseFloat(value) || 0;
    return num.toLocaleString('ja-JP');
  }
  
  // カンマを除去して数値のみを取得
  function parseNumber(value) {
    if (!value || value === '') return '';
    return value.toString().replace(/,/g, '');
  }
  
  // 各事業部の合計を計算する関数
  function calculateTotal(categoryId) {
    const inputs = document.querySelectorAll(`input.budget-input[data-category-id="${categoryId}"]`);
    let total = 0;
    
    inputs.forEach(function(input) {
      const rawValue = parseNumber(input.value);
      const numValue = parseFloat(rawValue);
      if (!isNaN(numValue) && numValue > 0) {
        total += numValue;
      }
    });
    
    // 合計を表示
    const totalElement = document.querySelector(`span.budget-total[data-category-id="${categoryId}"]`);
    if (totalElement) {
      totalElement.textContent = formatNumber(total);
    }
  }
  
  // 初期計算とフォーマット（ページ読み込み時）
  document.querySelectorAll('tbody[data-category-id]').forEach(function(tbody) {
    const categoryId = tbody.getAttribute('data-category-id');
    
    // 各入力フィールドを初期化
    const inputs = tbody.querySelectorAll('input.budget-input');
    inputs.forEach(function(input) {
      const initialValue = parseNumber(input.value);
      const numValue = parseFloat(initialValue);
      
      // 初期値が有効な数値で0より大きい場合のみフォーマット
      if (!isNaN(numValue) && numValue > 0) {
        input.value = formatNumber(numValue);
      } else {
        // 0または空の場合は空にする
        input.value = '';
      }
    });
    
    calculateTotal(categoryId);
  });
  
  // 各入力フィールドにイベントリスナーを個別に設定
  document.querySelectorAll('input.budget-input').forEach(function(input) {
    // フォーカス時：カンマを除去して数値のみ表示
    input.addEventListener('focus', function() {
      const rawValue = parseNumber(this.value);
      if (rawValue !== '' && rawValue !== '0') {
        this.value = rawValue;
      } else {
        this.value = '';
      }
    });
    
    // フォーカスアウト時：3桁区切りを適用（値は必ず保持）
    input.addEventListener('blur', function() {
      // 無効化されている場合は処理しない
      if (this.disabled) return;
      
      // 現在の入力値を取得
      let currentValue = this.value;
      
      // 半角数字以外を除去
      currentValue = currentValue.replace(/[^\d]/g, '');
      
      // 数値に変換
      const numValue = parseFloat(currentValue);
      
      // 有効な数値で0より大きい場合のみフォーマットして保持
      if (!isNaN(numValue) && numValue > 0) {
        this.value = formatNumber(numValue);
      } else {
        // 0または無効な値の場合は空にする
        this.value = '';
      }
      
      const categoryId = this.getAttribute('data-category-id');
      calculateTotal(categoryId);
    });
    
    // 入力値変更時：半角数字のみ許可し、合計を再計算
    input.addEventListener('input', function() {
      // 無効化されている場合は処理しない
      if (this.disabled) return;
      
      // 入力中は半角数字以外の文字を除去
      const currentValue = this.value;
      const cleanedValue = currentValue.replace(/[^\d]/g, '');
      
      // 値が変更された場合のみ更新（無限ループを防ぐ）
      if (cleanedValue !== currentValue) {
        this.value = cleanedValue;
      }
      
      const categoryId = this.getAttribute('data-category-id');
      calculateTotal(categoryId);
    });
    
    // キー入力時：半角数字のみ許可
    input.addEventListener('keypress', function(event) {
      // 無効化されている場合は処理しない
      if (this.disabled) return;
      
      // 半角数字以外のキー入力を無効化
      const char = String.fromCharCode(event.which || event.keyCode);
      if (!/[\d]/.test(char)) {
        event.preventDefault();
      }
    });
  });
  
  // 保存ボタンに直接イベントリスナーを追加
  document.querySelectorAll('form input[type="submit"]').forEach(function(submitButton) {
    submitButton.addEventListener('click', function(event) {
      const form = this.closest('form');
      if (!form) return;
      
      // すべての予算入力フィールドを取得
      const budgetInputs = form.querySelectorAll('input.budget-input');
      
      // まずすべての入力フィールドからフォーカスを外す
      if (document.activeElement && document.activeElement.classList.contains('budget-input')) {
        document.activeElement.blur();
      }
      
      // 値をクリーンアップ
      budgetInputs.forEach(function(input) {
        const rawValue = parseNumber(input.value);
        const numValue = parseFloat(rawValue);
        
        // 有効な数値の場合のみ値を設定（カンマなし）
        if (!isNaN(numValue) && numValue > 0) {
          input.value = rawValue;
        } else {
          input.value = '';
        }
      });
      
      // フォーム送信を続行（デフォルトの動作を許可）
      // イベントを停止しないので、通常のフォーム送信が実行される
    }, false);
  });
});
