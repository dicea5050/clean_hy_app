var initializeCustomerPostalAutoFill = function(root) {
  var container = root || document;
  var postalHiddenField = container.querySelector('#customer_postal_code');
  var postalInput = container.querySelector('#customer_postal_code_display');
  var lookupButton = container.querySelector('#customer_postal_lookup_button');
  var addressField = container.querySelector('#customer_address');
  var prefectureField = container.querySelector('#customer_prefecture');
  var cityField = container.querySelector('#customer_city');
  var streetField = container.querySelector('#customer_street');
  var helperText = container.querySelector('#postal-code-helper');
  var currentRequest = null;
  var lastRequestedPostalCode = null;
  var isComposing = false;

  if (!postalHiddenField || (!addressField && !prefectureField && !cityField && !streetField)) {
    return;
  }

  if (postalHiddenField.dataset.autoPostalInitialized === 'true') {
    return;
  }
  postalHiddenField.dataset.autoPostalInitialized = 'true';

  var clearHelper = function() {
    if (helperText) {
      helperText.innerText = '郵便番号を入力し「住所取得」を押すと住所が自動入力されます。';
      helperText.classList.remove('text-danger');
      helperText.classList.add('text-muted');
    }
  };

  var showError = function(message) {
    if (helperText) {
      helperText.innerText = message;
      helperText.classList.remove('text-muted');
      helperText.classList.add('text-danger');
    }
  };

  var normalizePostalInput = function(value) {
    if (!value) {
      return '';
    }

    var halfWidth = value.replace(/[０-９]/g, function(ch) {
      return String.fromCharCode(ch.charCodeAt(0) - 0xFEE0);
    });

    return halfWidth.replace(/[^0-9]/g, '').slice(0, 7);
  };

  var formatPostalDisplay = function(value) {
    if (!value) {
      return '';
    }
    if (value.length < 7) {
      return value;
    }
    return value.replace(/(\d{3})(\d{4})/, '$1-$2');
  };

  var syncPostalValues = function(normalizedValue) {
    var formatted = formatPostalDisplay(normalizedValue);
    postalHiddenField.value = normalizedValue;
    if (postalInput) {
      postalInput.value = normalizedValue.length > 0 ? formatted : '';
    }
  };

  var clearAddressFields = function() {
    if (prefectureField) {
      prefectureField.value = '';
    }
    if (cityField) {
      cityField.value = '';
    }
    if (streetField) {
      streetField.value = '';
    }
    if (addressField && !prefectureField && !cityField && !streetField) {
      addressField.value = '';
      addressField.dispatchEvent(new Event('input', { bubbles: true }));
      addressField.dispatchEvent(new Event('change', { bubbles: true }));
    }
  };

  var fetchAddress = function(value) {
    if (!value || value.length !== 7) {
      showError('郵便番号は7桁で入力してください。');
      return;
    }

    if (currentRequest) {
      currentRequest.abort();
    }
    lastRequestedPostalCode = value;

    clearHelper();

    if (helperText) {
      helperText.innerText = '住所を取得しています...';
      helperText.classList.remove('text-danger');
      helperText.classList.add('text-muted');
    }

    currentRequest = $.ajax({
      url: 'https://zipcloud.ibsnet.co.jp/api/search',
      dataType: 'json',
      data: { zipcode: value },
      timeout: 10000
    }).done(function(data) {
      if (lastRequestedPostalCode !== value) {
        return;
      }
      if (data.status !== 200 || !data.results || data.results.length === 0) {
        showError('住所を取得できませんでした。郵便番号を確認してください。');
        clearAddressFields();
        return;
      }

      var result = data.results[0];

      if (prefectureField) {
        prefectureField.value = result.address1;
        prefectureField.dispatchEvent(new Event('input', { bubbles: true }));
        prefectureField.dispatchEvent(new Event('change', { bubbles: true }));
      }
      if (cityField) {
        cityField.value = result.address2;
        cityField.dispatchEvent(new Event('input', { bubbles: true }));
        cityField.dispatchEvent(new Event('change', { bubbles: true }));
      }
      if (streetField) {
        streetField.value = result.address3;
        streetField.dispatchEvent(new Event('input', { bubbles: true }));
        streetField.dispatchEvent(new Event('change', { bubbles: true }));
      }

      if (addressField && !prefectureField && !cityField && !streetField) {
        var address = [ result.address1, result.address2, result.address3 ].join('');
        addressField.value = address;
        addressField.dispatchEvent(new Event('input', { bubbles: true }));
        addressField.dispatchEvent(new Event('change', { bubbles: true }));
      }

      clearHelper();
    }).fail(function(_jqXHR, textStatus) {
      if (textStatus === 'abort') {
        return;
      }
      showError('住所の取得中にエラーが発生しました。時間をおいて再度お試しください。');
    }).always(function() {
      currentRequest = null;
    });
  };

  var initialValue = normalizePostalInput(postalHiddenField.value);
  syncPostalValues(initialValue);

  if (postalInput) {
    postalInput.addEventListener('compositionstart', function() {
      isComposing = true;
    });

    postalInput.addEventListener('compositionend', function(event) {
      isComposing = false;
      var normalized = normalizePostalInput(event.target.value);
      syncPostalValues(normalized);
      clearHelper();
    });
  }

  var inputTarget = postalInput || postalHiddenField;

  inputTarget.addEventListener('input', function(event) {
    if (event.isComposing || isComposing) {
      return;
    }

    var normalized = normalizePostalInput(event.target.value);
    syncPostalValues(normalized);
    clearHelper();
  });

  inputTarget.addEventListener('blur', function(event) {
    var normalized = normalizePostalInput(event.target.value);
    syncPostalValues(normalized);
  });

  var triggerLookup = function() {
    var normalized = normalizePostalInput(postalInput ? postalInput.value : postalHiddenField.value);
    syncPostalValues(normalized);
    fetchAddress(normalized);
  };

  if (lookupButton) {
    lookupButton.addEventListener('click', function() {
      triggerLookup();
    });
  }

  inputTarget.addEventListener('keydown', function(event) {
    if (event.key === 'Enter') {
      event.preventDefault();
      triggerLookup();
    }
  });
};

var setupCustomerPostalAutoFill = function(root) {
  initializeCustomerPostalAutoFill(root);
};

$(function() {
  setupCustomerPostalAutoFill();
});

document.addEventListener('turbo:load', function() {
  setupCustomerPostalAutoFill();
});

document.addEventListener('turbolinks:load', function() {
  setupCustomerPostalAutoFill();
});

document.addEventListener('turbo:frame-load', function(event) {
  setupCustomerPostalAutoFill(event.target);
});

document.addEventListener('turbo:render', function() {
  setupCustomerPostalAutoFill();
});

document.addEventListener('DOMContentLoaded', function() {
  var observer = new MutationObserver(function(mutations) {
    mutations.forEach(function(mutation) {
      mutation.addedNodes.forEach(function(node) {
        if (!(node instanceof HTMLElement)) {
          return;
        }
        if (node.querySelector && node.querySelector('#customer_postal_code_display')) {
          setupCustomerPostalAutoFill(node);
        } else if (node.id === 'customer_postal_code_display') {
          setupCustomerPostalAutoFill(node.parentElement || document);
        }
      });
    });
  });

  observer.observe(document.body, { childList: true, subtree: true });
});

// 顧客名のインクリメンタルサーチ機能
var initializeCustomerNameSearch = function(root) {
  var container = root || document;
  var searchInput = container.querySelector('#company_name_search');
  var suggestionsDiv = container.querySelector('#company_name_suggestions');
  var currentRequest = null;
  var debounceTimer = null;

  if (!searchInput || !suggestionsDiv) {
    return;
  }

  if (searchInput.dataset.autoSearchInitialized === 'true') {
    return;
  }
  searchInput.dataset.autoSearchInitialized = 'true';

  var hideSuggestions = function() {
    suggestionsDiv.style.display = 'none';
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
    suggestionsDiv.style.display = 'block';

    // 候補クリックイベントを追加
    suggestionsDiv.querySelectorAll('.suggestion-item').forEach(function(item) {
      item.addEventListener('click', function() {
        searchInput.value = this.dataset.name;
        hideSuggestions();
        // フォームを自動送信
        var form = searchInput.closest('form');
        if (form) {
          form.submit();
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
        url: '/customers/company_name_search',
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
      var url = new URL('/customers/company_name_search', window.location.origin);
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

var setupCustomerNameSearch = function(root) {
  initializeCustomerNameSearch(root);
};

// jQueryが利用可能な場合のみ実行
if (typeof $ !== 'undefined') {
  $(function() {
    setupCustomerNameSearch();
  });
} else {
  document.addEventListener('DOMContentLoaded', function() {
    setupCustomerNameSearch();
  });
}

document.addEventListener('turbo:load', function() {
  setupCustomerNameSearch();
});

document.addEventListener('turbolinks:load', function() {
  setupCustomerNameSearch();
});

document.addEventListener('turbo:frame-load', function(event) {
  setupCustomerNameSearch(event.target);
});

document.addEventListener('turbo:render', function() {
  setupCustomerNameSearch();
});

document.addEventListener('DOMContentLoaded', function() {
  var observer = new MutationObserver(function(mutations) {
    mutations.forEach(function(mutation) {
      mutation.addedNodes.forEach(function(node) {
        if (!(node instanceof HTMLElement)) {
          return;
        }
        if (node.querySelector && node.querySelector('#company_name_search')) {
          setupCustomerNameSearch(node);
        } else if (node.id === 'company_name_search') {
          setupCustomerNameSearch(node.parentElement || document);
        }
      });
    });
  });

  observer.observe(document.body, { childList: true, subtree: true });
});
