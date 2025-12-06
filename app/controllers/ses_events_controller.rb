class SesEventsController < ApplicationController
  # CSRF保護を無効化（SNSからのWebhookのため）
  skip_before_action :verify_authenticity_token
  before_action :verify_sns_message

  # SNSからのSESイベント通知を受信
  def webhook
    # SNSメッセージのタイプを確認
    case request.headers["x-amz-sns-message-type"]
    when "SubscriptionConfirmation"
      # SNSサブスクリプション確認
      confirm_subscription
    when "Notification"
      # SESイベント通知を処理
      process_ses_event
    else
      head :bad_request
    end
  end

  private

  def verify_sns_message
    # SNSメッセージの検証（本番環境では実装推奨）
    # 開発環境ではスキップ可能
    nil if Rails.env.development?

    # TODO: SNSメッセージの署名検証を実装
    # AWS SDKを使用してメッセージの署名を検証
  end

  def confirm_subscription
    # SNSサブスクリプション確認URLにアクセス
    subscribe_url = JSON.parse(request.body.read)["SubscribeURL"]
    if subscribe_url.present?
      require "net/http"
      uri = URI(subscribe_url)
      Net::HTTP.get(uri)
      head :ok
    else
      head :bad_request
    end
  end

  def process_ses_event
    body = JSON.parse(request.body.read)
    message = JSON.parse(body["Message"])

    # SESイベントタイプを取得
    event_type = message["eventType"]
    mail = message["mail"]

    # カスタムヘッダーからdelivery_idを取得
    headers = mail["headers"] || []
    delivery_id_header = headers.find { |h| h["name"] == "X-Invoice-Delivery-ID" }

    unless delivery_id_header
      Rails.logger.warn "SESイベントにX-Invoice-Delivery-IDヘッダーが見つかりません: #{message.inspect}"
      head :ok
      return
    end

    delivery_id = delivery_id_header["value"]
    delivery = InvoiceDelivery.find_by(id: delivery_id)

    unless delivery
      Rails.logger.warn "InvoiceDeliveryが見つかりません: delivery_id=#{delivery_id}"
      head :ok
      return
    end

    # イベントタイムスタンプを取得
    event_timestamp = Time.at(message["timestamp"].to_i / 1000.0) rescue Time.current

    # エラーメッセージを取得（Bounce/Rejectの場合）
    error_message = nil
    if message["bounce"]
      error_message = "Bounce: #{message['bounce']['bounceType']} - #{message['bounce']['bounceSubType']}"
    elsif message["reject"]
      error_message = "Reject: #{message['reject']['reason']}"
    end

    # SESメッセージIDを保存
    delivery.ses_message_id = mail["messageId"]

    # イベントを処理
    delivery.process_ses_event(event_type, event_timestamp, error_message)

    head :ok
  rescue => e
    Rails.logger.error "SESイベント処理エラー: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    head :ok # SNSには常に200を返す
  end
end
