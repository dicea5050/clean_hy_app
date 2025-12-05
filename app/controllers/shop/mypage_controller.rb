class Shop::MypageController < ApplicationController
  layout "shop"
  before_action :authenticate_customer!

  def show
    @customer = current_customer
    # ネットショップからの注文のみを取得
    @orders = @customer.orders.where(is_shop_order: true).order(created_at: :desc).page(params[:page]).per(10)
    # 納品先情報を取得
    @delivery_locations = @customer.delivery_locations.order(is_main_office: :desc, created_at: :asc)
  end

  def update_password
    @customer = current_customer

    # 現在のパスワードが設定されている場合は確認
    if @customer.password_set?
      current_password = params[:current_password]
      if current_password.blank?
        render json: { status: 'error', message: "現在のパスワードを入力してください。" }, status: :unprocessable_entity
        return
      end
      unless @customer.authenticate(current_password)
        render json: { status: 'error', message: "現在のパスワードが正しくありません。" }, status: :unprocessable_entity
        return
      end
    end

    # 新しいパスワードの検証
    new_password = params[:new_password]
    password_confirmation = params[:password_confirmation]

    if new_password.blank?
      render json: { status: 'error', message: "新しいパスワードを入力してください。" }, status: :unprocessable_entity
      return
    end

    # パスワードの最小長さを検証（6文字以上）
    if new_password.length < 6
      render json: { status: 'error', message: "新しいパスワードは6文字以上で入力してください。" }, status: :unprocessable_entity
      return
    end

    # 半角スペースを検出
    if new_password.include?(' ')
      render json: { status: 'error', message: "パスワードに半角スペースは使用できません。半角英数字と記号のみ使用してください。" }, status: :unprocessable_entity
      return
    end

    # 半角文字のみを許可（!から~まで、スペース(0x20)は除外）
    # 全角英数字、全角カタカナ、全角ひらがな、全角漢字などはすべて検出
    unless new_password.match?(/\A[\x21-\x7E]+\z/)
      render json: { status: 'error', message: "パスワードに全角文字は使用できません。半角英数字と記号のみ使用してください。" }, status: :unprocessable_entity
      return
    end

    # 追加チェック: 全角英数字を明示的に検出（より確実な検出のため）
    # 全角英字: U+FF21-FF3A (Ａ-Ｚ), U+FF41-FF5A (ａ-ｚ)
    # 全角数字: U+FF10-FF19 (０-９)
    # 全角記号: U+FF01-FF5E
    if new_password.match?(/[\uFF01-\uFF5E\u3000-\u303F\u3040-\u309F\u30A0-\u30FF\u4E00-\u9FAF]/)
      render json: { status: 'error', message: "パスワードに全角文字は使用できません。半角英数字と記号のみ使用してください。" }, status: :unprocessable_entity
      return
    end

    if new_password != password_confirmation
      render json: { status: 'error', message: "新しいパスワードと確認用パスワードが一致しません。" }, status: :unprocessable_entity
      return
    end

    # パスワードを更新（Customerモデルのpassword_digestカラムに保存される）
    if @customer.update(password: new_password, password_confirmation: password_confirmation)
      render json: { status: 'success', message: "パスワードが正常に更新されました。" }
    else
      # バリデーションエラーがある場合
      error_message = @customer.errors.full_messages.join("、")
      render json: { status: 'error', message: "パスワードの更新に失敗しました。#{error_message.present? ? error_message : ''}" }, status: :unprocessable_entity
    end
  end
end

