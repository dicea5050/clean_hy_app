// 納品先選択機能 - シンプルなjQuery実装
console.log('納品先選択機能のスクリプトが読み込まれました');

$(document).ready(function() {
  console.log('納品先選択機能の初期化を開始します');

  // 顧客選択時のイベント処理
  $('#order_customer_id').on('change', function() {
    var customerId = $(this).val();
    console.log('顧客が選択されました - ID:', customerId);

    var select = $('#order_delivery_location_id');
    console.log('納品先セレクトボックスを取得:', select.length ? '成功' : '失敗');

    if (customerId) {
      // 納品先を取得するAPIリクエスト
      var url = '/customers/' + customerId + '/delivery_locations';
      console.log('APIリクエストを送信します:', url);

      // リクエスト中は選択できないようにする
      select.prop('disabled', true).empty().append('<option value="">読み込み中...</option>');

      $.ajax({
        url: url,
        type: 'GET',
        dataType: 'json',
        success: function(data) {
          console.log('納品先データを取得しました:', data);

          // セレクトボックスをクリアして再構築
          select.empty().append('<option value="">納品先を選択してください</option>');

          if (data && data.length > 0) {
            // 納品先オプションを追加
            $.each(data, function(index, location) {
              select.append('<option value="' + location.id + '">' + location.name + '</option>');
            });

            // 選択可能にする
            select.prop('disabled', false);
            console.log('納品先オプションを追加しました');
          } else {
            // 納品先がない場合
            select.append('<option value="">納品先がありません</option>');
            select.prop('disabled', true);
            console.log('納品先データが空でした');
          }
        },
        error: function(xhr, status, error) {
          console.error('納品先の取得に失敗しました');
          console.error('ステータス:', status);
          console.error('エラー:', error);
          console.error('レスポンス:', xhr.responseText);

          // エラー時の処理
          select.empty().append('<option value="">取得できませんでした</option>');
          select.prop('disabled', true);
        }
      });
    } else {
      // 顧客が選択されていない場合、納品先選択肢をクリア
      select.empty().append('<option value="">納品先を選択してください</option>');
      select.prop('disabled', true);
      console.log('顧客が選択されていないため、納品先をクリアしました');
    }
  });

  console.log('納品先選択機能の初期化が完了しました');
});