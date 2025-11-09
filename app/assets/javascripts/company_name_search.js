// 取引先名のインクリメンタルサーチ機能（共通化）
// 設定可能なIDやセレクタに対応
var initializeCompanyNameSearch = function(root, options) {
  var container = root || document;
  options = options || {};
  
  // デフォルトのID/セレクタ
  var inputSelector = options.inputSelector || '#company_name_search';
  var suggestionsSelector = options.suggestionsSelector || '#company_name_suggestions';
  var apiUrl = options.apiUrl || '/customers/company_name_search';
  var autoSubmit = options.autoSubmit !== false; // デフォルトはtrue
  
  var searchInput = container.querySelector(inputSelector);
  var suggestionsDiv = container.querySelector(suggestionsSelector);
  var currentRequest = null;
  var debounceTimer = null;

  if (!searchInput || !suggestionsDiv) {
    return;
  }

  // 初期化済みチェック用の属性名を動的に生成
  var initAttr = 'data-auto-search-initialized-' + inputSelector.replace(/[^a-zA-Z0-9]/g, '-');
  if (searchInput.getAttribute(initAttr) === 'true') {
    return;
  }
  searchInput.setAttribute(initAttr, 'true');

  var hideSuggestions = function() {
    suggestionsDiv.classList.add('d-none');
    suggestionsDiv.innerHTML = '';
  };

  var showSuggestions = function(suggestions) {
    if (suggestions.length === 0) {
      hideSuggestions();
      return;
    }

    var html = '';
    suggestions.forEach(function(suggestion) {
      html += '<div class="suggestion-item p-2 border-bottom cursor-pointer" data-name="' + 
              suggestion.name + '">' + suggestion.name + '</div>';
    });
    
    suggestionsDiv.innerHTML = html;
    suggestionsDiv.classList.remove('d-none');

    // 候補クリックイベントを追加
    suggestionsDiv.querySelectorAll('.suggestion-item').forEach(function(item) {
      item.addEventListener('click', function() {
        searchInput.value = this.dataset.name;
        hideSuggestions();
        // フォームを自動送信（オプションで制御可能）
        if (autoSubmit) {
          var form = searchInput.closest('form');
          if (form) {
            form.submit();
          }
        }
      });
    });
  };

  var searchCustomers = function(query) {
    if (currentRequest) {
      currentRequest.abort();
    }

    if (!query || query.length < 1) {
      hideSuggestions();
      return;
    }

    // jQueryが利用可能かチェック
    if (typeof $ !== 'undefined') {
      currentRequest = $.ajax({
        url: apiUrl,
        method: 'GET',
        data: { q: query },
        dataType: 'json'
      }).done(function(data) {
        showSuggestions(data);
      }).fail(function(xhr, status, error) {
        hideSuggestions();
      }).always(function() {
        currentRequest = null;
      });
    } else {
      // fetch APIを使用
      var url = new URL(apiUrl, window.location.origin);
      url.searchParams.append('q', query);
      
      fetch(url)
        .then(function(response) {
          if (!response.ok) {
            throw new Error('Network response was not ok');
          }
          return response.json();
        })
        .then(function(data) {
          showSuggestions(data);
        })
        .catch(function(error) {
          hideSuggestions();
        });
    }
  };

  // 入力イベント
  searchInput.addEventListener('input', function(event) {
    var query = event.target.value.trim();
    
    clearTimeout(debounceTimer);
    debounceTimer = setTimeout(function() {
      searchCustomers(query);
    }, 300); // 300msのデバウンス
  });

  // フォーカスアウト時に候補を非表示
  searchInput.addEventListener('blur', function() {
    setTimeout(function() {
      hideSuggestions();
    }, 200); // クリックイベントが発火するまで少し待つ
  });

  // フォーカス時に候補を再表示
  searchInput.addEventListener('focus', function() {
    var query = this.value.trim();
    if (query.length >= 1) {
      searchCustomers(query);
    }
  });

  // ESCキーで候補を非表示
  searchInput.addEventListener('keydown', function(event) {
    if (event.key === 'Escape') {
      hideSuggestions();
    }
  });
};

// 複数の設定で初期化するためのヘルパー関数
var setupCompanyNameSearch = function(root, options) {
  initializeCompanyNameSearch(root, options);
};

// グローバルに公開（他のスクリプトからも利用可能）
window.CompanyNameSearch = {
  initialize: initializeCompanyNameSearch,
  setup: setupCompanyNameSearch
};

// デフォルトの設定で初期化（顧客マスター用）
// 既存のcustomers.jsとの互換性のため
document.addEventListener('DOMContentLoaded', function() {
  // 顧客マスター用のデフォルト設定
  setupCompanyNameSearch(document, {
    inputSelector: '#company_name_search',
    suggestionsSelector: '#company_name_suggestions',
    apiUrl: '/customers/company_name_search',
    autoSubmit: true
  });
});

document.addEventListener('turbo:load', function() {
  setupCompanyNameSearch(document, {
    inputSelector: '#company_name_search',
    suggestionsSelector: '#company_name_suggestions',
    apiUrl: '/customers/company_name_search',
    autoSubmit: true
  });
});

document.addEventListener('turbolinks:load', function() {
  setupCompanyNameSearch(document, {
    inputSelector: '#company_name_search',
    suggestionsSelector: '#company_name_suggestions',
    apiUrl: '/customers/company_name_search',
    autoSubmit: true
  });
});

document.addEventListener('turbo:frame-load', function(event) {
  setupCompanyNameSearch(event.target, {
    inputSelector: '#company_name_search',
    suggestionsSelector: '#company_name_suggestions',
    apiUrl: '/customers/company_name_search',
    autoSubmit: true
  });
});

document.addEventListener('turbo:render', function() {
  setupCompanyNameSearch(document, {
    inputSelector: '#company_name_search',
    suggestionsSelector: '#company_name_suggestions',
    apiUrl: '/customers/company_name_search',
    autoSubmit: true
  });
});

// MutationObserverで動的に追加された要素にも対応
document.addEventListener('DOMContentLoaded', function() {
  var observer = new MutationObserver(function(mutations) {
    mutations.forEach(function(mutation) {
      mutation.addedNodes.forEach(function(node) {
        if (!(node instanceof HTMLElement)) {
          return;
        }
        
        // 顧客マスター用
        if (node.querySelector && node.querySelector('#company_name_search')) {
          setupCompanyNameSearch(node, {
            inputSelector: '#company_name_search',
            suggestionsSelector: '#company_name_suggestions',
            apiUrl: '/customers/company_name_search',
            autoSubmit: true
          });
        } else if (node.id === 'company_name_search') {
          setupCompanyNameSearch(node.parentElement || document, {
            inputSelector: '#company_name_search',
            suggestionsSelector: '#company_name_suggestions',
            apiUrl: '/customers/company_name_search',
            autoSubmit: true
          });
        }
        
        // 受注一覧用
        if (node.querySelector && node.querySelector('#customer_name_search')) {
          setupCompanyNameSearch(node, {
            inputSelector: '#customer_name_search',
            suggestionsSelector: '#customer_name_suggestions',
            apiUrl: '/customers/company_name_search',
            autoSubmit: true
          });
        } else if (node.id === 'customer_name_search') {
          setupCompanyNameSearch(node.parentElement || document, {
            inputSelector: '#customer_name_search',
            suggestionsSelector: '#customer_name_suggestions',
            apiUrl: '/customers/company_name_search',
            autoSubmit: true
          });
        }
        
        // 請求書一覧用
        if (node.querySelector && node.querySelector('#invoice_company_name_search')) {
          setupCompanyNameSearch(node, {
            inputSelector: '#invoice_company_name_search',
            suggestionsSelector: '#invoice_company_name_suggestions',
            apiUrl: '/customers/company_name_search',
            autoSubmit: true
          });
        } else if (node.id === 'invoice_company_name_search') {
          setupCompanyNameSearch(node.parentElement || document, {
            inputSelector: '#invoice_company_name_search',
            suggestionsSelector: '#invoice_company_name_suggestions',
            apiUrl: '/customers/company_name_search',
            autoSubmit: true
          });
        }
      });
    });
  });

  observer.observe(document.body, { childList: true, subtree: true });
});

