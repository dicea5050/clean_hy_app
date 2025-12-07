class CustomersController < ApplicationController
  before_action :require_login, except: [ :company_name_search ]
  before_action :require_editor_limited_access, except: [ :company_name_search ]
  before_action :require_viewer_show_only, except: [ :company_name_search ]
  before_action :require_editor, only: [ :new, :create, :update, :destroy, :import_csv, :process_csv ]
  before_action :block_shop_user_access
  before_action :set_customer, only: [ :show, :edit, :update, :destroy ]

  def index
    @customers = Customer.order(:company_name)

    # 顧客コードで検索
    if params[:customer_code].present?
      @customers = @customers.where("customer_code LIKE ?", "%#{params[:customer_code]}%")
    end

    # 顧客名で検索
    if params[:company_name].present?
      @customers = @customers.where("company_name LIKE ?", "%#{params[:company_name]}%")
    end

    @customers = @customers.page(params[:page]).per(25)
  end

  def show
    @delivery_locations = @customer.delivery_locations.order(is_main_office: :desc, name: :asc)
  end

  def new
    @customer = Customer.new
  end

  def edit
  end

  def create
    @customer = Customer.new(customer_params)

    # 半角文字のみを許可（!から~まで、スペース(0x20)は除外）
    # 全角英数字、全角カタカナ、全角ひらがな、全角漢字などはすべて検出
    if params[:customer][:password].present?
      password = params[:customer][:password]

      # 半角スペースを検出
      if password.include?(" ")
        @customer.errors.add(:password, "パスワードに半角スペースは使用できません。半角英数字と記号のみ使用してください。")
        render :new
        return
      end

      unless password.match?(/\A[\x21-\x7E]+\z/)
        @customer.errors.add(:password, "パスワードに全角文字は使用できません。半角英数字と記号のみ使用してください。")
        render :new
        return
      end

      # 追加チェック: 全角英数字を明示的に検出（より確実な検出のため）
      if password.match?(/[\uFF01-\uFF5E\u3000-\u303F\u3040-\u309F\u30A0-\u30FF\u4E00-\u9FAF]/)
        @customer.errors.add(:password, "パスワードに全角文字は使用できません。半角英数字と記号のみ使用してください。")
        render :new
        return
      end
    end

    if @customer.save
      redirect_to customers_path, notice: "顧客が正常に作成されました。"
    else
      render :new
    end
  end

  def update
    # パスワードが空欄の場合、パラメータから削除して更新しない
    if params[:customer][:password].blank?
      params[:customer].delete(:password)
    else
      # 半角文字のみを許可（!から~まで、スペース(0x20)は除外）
      # 全角英数字、全角カタカナ、全角ひらがな、全角漢字などはすべて検出
      password = params[:customer][:password]

      # 半角スペースを検出
      if password.include?(" ")
        @customer.errors.add(:password, "パスワードに半角スペースは使用できません。半角英数字と記号のみ使用してください。")
        render :edit
        return
      end

      unless password.match?(/\A[\x21-\x7E]+\z/)
        @customer.errors.add(:password, "パスワードに全角文字は使用できません。半角英数字と記号のみ使用してください。")
        render :edit
        return
      end

      # 追加チェック: 全角英数字を明示的に検出（より確実な検出のため）
      if password.match?(/[\uFF01-\uFF5E\u3000-\u303F\u3040-\u309F\u30A0-\u30FF\u4E00-\u9FAF]/)
        @customer.errors.add(:password, "パスワードに全角文字は使用できません。半角英数字と記号のみ使用してください。")
        render :edit
        return
      end
    end

    if @customer.update(customer_params)
      redirect_to customers_path, notice: "顧客が正常に更新されました。"
    else
      render :edit
    end
  end

  def destroy
    begin
      if @customer.destroy
        redirect_to customers_path, notice: "顧客が正常に削除されました。"
      else
        redirect_to customers_path, alert: (@customer.errors.full_messages.to_sentence.presence || "顧客を削除できませんでした。")
      end
    rescue ActiveRecord::InvalidForeignKey
      redirect_to customers_path, alert: "この顧客には関連データが存在するため削除できません。先に関連データを削除してください。"
    end
  end

  def search
    @customers = Customer.where("company_name LIKE ?", "%#{params[:q]}%").limit(10)
    render json: @customers.map { |c| { id: c.id, text: c.company_name } }
  end

  # 顧客名のインクリメンタルサーチ用API
  def company_name_search
    query = params[:q]
    if query.present?
      @customers = Customer.where("company_name LIKE ?", "%#{query}%")
                          .order(:company_name)
                          .limit(10)
      render json: @customers.map { |c| { id: c.id, name: c.company_name } }
    else
      render json: []
    end
  end

  # 顧客に紐づく納品先を取得するAPIエンドポイント
  def delivery_locations
    @customer = Customer.find(params[:id])
    @delivery_locations = @customer.delivery_locations.order(is_main_office: :desc, name: :asc)

    # デバッグ用にログ出力
    Rails.logger.debug "納品先データ取得: 顧客ID=#{@customer.id}, 納品先数=#{@delivery_locations.size}"
    @delivery_locations.each do |loc|
      Rails.logger.debug "  - ID:#{loc.id}, 名前:#{loc.name}, 本社:#{loc.is_main_office}"
    end

    render json: @delivery_locations.map { |loc| { id: loc.id, name: loc.name, is_main_office: loc.is_main_office } }
  end

  # CSVアップロード画面を表示
  def import_csv
  end

  # CSVファイルを処理して一括登録
  def process_csv
    Rails.logger.info "CSVアップロードのパラメータ: #{params.inspect}"
    Rails.logger.info "ファイルパラメータ: #{params[:file].inspect}" if params[:file].present?

    if params[:file].blank?
      redirect_to import_csv_customers_path, alert: "CSVファイルを選択してください。"
      return
    end

    # Content-Typeチェックを緩和して様々なCSV形式に対応
    content_type = params[:file].content_type
    unless content_type.include?("csv") || content_type == "application/octet-stream" || content_type == "text/plain"
      redirect_to import_csv_customers_path, alert: "CSVファイル形式でアップロードしてください。現在の形式: #{content_type}"
      return
    end

    # CSVファイルの処理
    begin
      success_count = 0
      error_count = 0
      error_messages = []

      # エンコーディングの問題に対処するため、ファイルの内容を一旦読み込み
      csv_content = File.read(params[:file].path)
      # BOMを削除してエンコーディングを適切に処理
      csv_content = csv_content.force_encoding("UTF-8").gsub("\xEF\xBB\xBF", "")

      require "csv"

      # デバッグ用：CSVの内容を出力
      Rails.logger.info "CSVの内容:\n#{csv_content}"

      # CSVの行数をカウント
      row_count = 0
      validation_errors = []

      # CSVデータをパース（区切り文字とエンコーディングを明示的に指定）
      csv_data = CSV.parse(csv_content,
                          headers: true,
                          encoding: "UTF-8",
                          col_sep: ",",
                          quote_char: '"',
                          force_quotes: true)

      # デバッグ用：読み込まれたヘッダーを出力
      Rails.logger.info "読み込まれたヘッダー: #{csv_data.headers.inspect}"
      if csv_data.headers.nil? || csv_data.headers.empty?
        redirect_to import_csv_customers_path, alert: "CSVファイルのヘッダーを読み取れませんでした。ファイルの形式を確認してください。"
        return
      end

      # ヘッダーの検証（必須ヘッダーの確認）
      required_headers = [ "顧客コード", "顧客名", "郵便番号", "住所", "請求書送付方法", "請求締日" ]
      missing_headers = required_headers.select { |h| !csv_data.headers.include?(h) }
      if missing_headers.any?
        validation_errors << "必須のヘッダーが不足しています: #{missing_headers.join(', ')}\n"\
                           "読み込まれたヘッダー: #{csv_data.headers.join(', ')}"
        redirect_to import_csv_customers_path, alert: "CSVデータの検証でエラーが発生しました:\n#{validation_errors.join("\n")}"
        return
      end

      # トランザクションを開始して顧客を作成
      ActiveRecord::Base.transaction do
        csv_data.each do |row|
          row_count += 1

          # データの存在確認
          if row.fields.compact.empty?
            validation_errors << "#{row_count}行目: データが空です"
            next
          end

          # CSVから顧客情報を取得
          customer_code = row["顧客コード"]&.strip
          company_name = row["顧客名"]&.strip
          postal_code = row["郵便番号"]&.strip
          address = row["住所"]&.strip
          department = row["部署名"]&.strip
          contact_name = row["担当者名"]&.strip
          phone_number = row["電話番号"]&.strip
          fax_number = row["FAX番号"]&.strip
          email = row["メールアドレス"]&.strip
          invoice_delivery_method_text = row["請求書送付方法"]&.strip
          billing_closing_day = row["請求締日"]&.strip

          # 必須項目の検証
          if customer_code.blank?
            validation_errors << "#{row_count}行目: 顧客コードが空です"
            error_count += 1
            next
          end

          if company_name.blank?
            validation_errors << "#{row_count}行目: 顧客名が空です"
            error_count += 1
            next
          end

          if postal_code.blank?
            validation_errors << "#{row_count}行目: 郵便番号が空です"
            error_count += 1
            next
          end

          if address.blank?
            validation_errors << "#{row_count}行目: 住所が空です"
            error_count += 1
            next
          end

          if invoice_delivery_method_text.blank?
            validation_errors << "#{row_count}行目: 請求書送付方法が空です"
            error_count += 1
            next
          end

          if billing_closing_day.blank?
            validation_errors << "#{row_count}行目: 請求締日が空です"
            error_count += 1
            next
          end

          # 請求書送付方法の変換
          invoice_delivery_method = nil
          if invoice_delivery_method_text == "電子請求"
            invoice_delivery_method = "electronic"
          elsif invoice_delivery_method_text == "郵送"
            invoice_delivery_method = "postal"
          else
            validation_errors << "#{row_count}行目: 請求書送付方法が不正です（電子請求または郵送を指定してください）"
            error_count += 1
            next
          end

          # 請求締日の検証と変換
          valid_billing_closing_days = Customer::BILLING_CLOSING_DAYS.map(&:last)
          # 月末の表記を変換
          if billing_closing_day == "月末"
            billing_closing_day = "month_end"
          end
          # 有効な請求締日かチェック
          unless valid_billing_closing_days.include?(billing_closing_day)
            validation_errors << "#{row_count}行目: 請求締日が不正です（5/10/15/20/25/月末を指定してください）"
            error_count += 1
            next
          end

          # 電子請求の場合、メールアドレスが必須
          if invoice_delivery_method == "electronic" && email.blank?
            validation_errors << "#{row_count}行目: 電子請求を選択した場合、メールアドレスが必須です"
            error_count += 1
            next
          end

          # 既存の顧客コードが存在するかチェック
          existing_customer = Customer.find_by(customer_code: customer_code)
          if existing_customer
            # 既存の顧客を更新
            customer = existing_customer
            customer.assign_attributes(
              company_name: company_name,
              postal_code: postal_code,
              address: address,
              department: department,
              contact_name: contact_name,
              phone_number: phone_number,
              fax_number: fax_number,
              email: email,
              invoice_delivery_method: invoice_delivery_method,
              billing_closing_day: billing_closing_day
            )
          else
            # 新規顧客を作成
            customer = Customer.new(
              customer_code: customer_code,
              company_name: company_name,
              postal_code: postal_code,
              address: address,
              department: department,
              contact_name: contact_name,
              phone_number: phone_number,
              fax_number: fax_number,
              email: email,
              invoice_delivery_method: invoice_delivery_method,
              billing_closing_day: billing_closing_day
            )
          end

          # 顧客を保存
          if customer.save
            success_count += 1
          else
            error_messages << "#{row_count}行目（顧客コード: #{customer_code}）: #{customer.errors.full_messages.join(', ')}"
            error_count += 1
          end
        end
      end

      if validation_errors.present?
        redirect_to import_csv_customers_path, alert: "CSVデータの検証でエラーが発生しました:\n#{validation_errors.join("\n")}"
      elsif error_messages.present?
        redirect_to import_csv_customers_path, alert: "エラーが発生しました:\n#{error_messages.join("\n")}"
      else
        redirect_to customers_path, notice: "CSVから#{success_count}件の顧客を登録しました。"
      end
    rescue CSV::MalformedCSVError => e
      redirect_to import_csv_customers_path, alert: "CSVファイルの形式が正しくありません: #{e.message}"
    rescue StandardError => e
      Rails.logger.error "CSVアップロードエラー: #{e.class} - #{e.message}\n#{e.backtrace.join("\n")}"
      redirect_to import_csv_customers_path, alert: "CSVファイルの処理中にエラーが発生しました: #{e.message}"
    end
  end

  private

  # shop-user権限の顧客からのアクセスをブロック
  def block_shop_user_access
    if customer_signed_in? && !administrator_signed_in?
      redirect_to shop_products_path, alert: "このページにアクセスする権限がありません"
    end
  end

  def set_customer
    @customer = Customer.find(params[:id])
  end

  def customer_params
    params.require(:customer).permit(
      :customer_code, :company_name, :postal_code, :address,
      :department, :contact_name, :phone_number, :email, :fax_number,
      :password, :password_confirmation, :payment_method_id, :invoice_delivery_method, :billing_closing_day
    )
  end
end
