document.addEventListener('DOMContentLoaded', function() {
  // 顧客コード・取引先名連動機能を初期化
  if (window.CustomerCodeSearch) {
    window.CustomerCodeSearch.init({
      customerCodeSelector: '#delivery_location_customer_code',
      customerSelectSelector: '#delivery_location_customer_select',
      customerIdSelector: '#delivery_location_customer_id',
      findCustomerApiUrl: '/orders/find_customer_by_code',
      enableSelect2: true,
      onCustomerChange: function(customerId, customerData) {
        // 納品先フォームでは特に追加処理は不要
      },
      onCustomerClear: function() {
        // 納品先フォームでは特に追加処理は不要
      }
    });
  }
});


