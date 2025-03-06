class OrdersController < ApplicationController
  before_action :set_order, only: [ :show, :edit, :update, :destroy ]
  before_action :set_payment_methods, only: [ :new, :edit, :create, :update ]

  def index
    @orders = Order.includes(:customer, :order_items, :payment_method)
                   .order(order_date: :desc)
                   .search(search_params)
                   .page(params[:page]).per(25)
    # 検索条件をビューで再表示するために保持
    @search_params = search_params
    @payment_methods = PaymentMethod.all
  end

  def show
  end

  def new
    @order = Order.new
    @order.order_items.build
    @customers = Customer.all.order(:company_name)
  end

  def edit
    @order.order_items.build if @order.order_items.empty?
    @customers = Customer.all.order(:company_name)
  end

  def create
    @order = Order.new(order_params)

    # 単価と税率を商品から設定
    set_price_and_tax_rate(@order.order_items)

    if @order.save
      redirect_to @order, notice: "受注情報が正常に作成されました。"
    else
      @customers = Customer.all.order(:company_name)
      render :new
    end
  end

  def update
    if @order.update(order_params)
      # 単価と税率を商品から設定
      set_price_and_tax_rate(@order.order_items)
      @order.save

      redirect_to @order, notice: "受注情報が正常に更新されました。"
    else
      @customers = Customer.all.order(:company_name)
      render :edit
    end
  end

  def destroy
    @order.destroy
    redirect_to orders_path, notice: "受注情報が正常に削除されました。"
  end

  def delivery_slip
    @order = Order.includes(:order_items, :customer, :payment_method).find(params[:id])
    @company_info = CompanyInformation.first

    respond_to do |format|
      format.pdf do
        pdf = ::DeliverySlipPdf.new(@order, @company_info)
        send_data pdf.render,
                  filename: "納品書_#{@order.order_number}.pdf",
                  type: "application/pdf",
                  disposition: "inline"
      end
    end
  end

  # CSVアップロード画面を表示
  def import_csv
    @customers = Customer.all.order(:company_name)
    @payment_methods = PaymentMethod.all
  end
  
  # CSVファイルを処理して一括登録
  def process_csv
    # デバッグ用ロギング
    Rails.logger.info "CSVアップロードのパラメータ: #{params.inspect}"
    Rails.logger.info "ファイルパラメータ: #{params[:file].inspect}" if params[:file].present?
    
    if params[:file].blank?
      redirect_to import_csv_orders_path, alert: "CSVファイルを選択してください。"
      return
    end
    
    # Content-Typeチェックを緩和して様々なCSV形式に対応
    content_type = params[:file].content_type
    unless content_type.include?('csv') || content_type == 'application/octet-stream' || content_type == 'text/plain'
      redirect_to import_csv_orders_path, alert: "CSVファイル形式でアップロードしてください。現在の形式: #{content_type}"
      return
    end
    
    # CSVファイルの処理
    begin
      success_count = 0
      error_messages = []
      
      # CSVファイルに含まれる受注情報をグループ化するためのハッシュ
      orders_data = {}
      order_number = 1
      
      # エンコーディングの問題に対処するため、ファイルの内容を一旦読み込み
      csv_content = File.read(params[:file].path)
      # BOMを削除してエンコーディングを適切に処理
      csv_content = csv_content.force_encoding('UTF-8').gsub("\xEF\xBB\xBF", '')
      
      require 'csv'
      
      # デバッグ用：CSVの内容を出力
      Rails.logger.info "CSVの内容:\n#{csv_content}"
      
      # CSVの行数をカウント
      row_count = 0
      validation_errors = []
      
      # CSVデータをパース（区切り文字とエンコーディングを明示的に指定）
      csv_data = CSV.parse(csv_content, 
                          headers: true,
                          encoding: 'UTF-8',
                          col_sep: ',',
                          quote_char: '"',
                          force_quotes: true)
      
      # デバッグ用：読み込まれたヘッダーを出力
      Rails.logger.info "読み込まれたヘッダー: #{csv_data.headers.inspect}"
      if csv_data.headers.nil? || csv_data.headers.empty?
        redirect_to import_csv_orders_path, alert: "CSVファイルのヘッダーを読み取れませんでした。ファイルの形式を確認してください。"
        return
      end
      
      # ヘッダーの検証（一度だけ実行）
      required_headers = ['商品コード', '商品名', '数量']
      missing_headers = required_headers.select { |h| !csv_data.headers.include?(h) }
      if missing_headers.any?
        validation_errors << "必須のヘッダーが不足しています: #{missing_headers.join(', ')}\n"\
                           "読み込まれたヘッダー: #{csv_data.headers.join(', ')}"
        redirect_to import_csv_orders_path, alert: "CSVデータの検証でエラーが発生しました:\n#{validation_errors.join("\n")}"
        return
      end
      
      csv_data.each do |row|
        row_count += 1
        
        # データの存在確認
        if row.fields.compact.empty?
          validation_errors << "#{row_count}行目: データが空です"
          next
        end
        
        # 受注基本情報の取得
        customer_code = row['取引先コード']
        customer_name = row['取引先名']
        payment_method_name = row['支払方法']
        order_date = row['受注日']
        expected_delivery_date = row['予定納品日']
        actual_delivery_date = row['確定納品日']
        
        # 受注グループを特定するキー
        # 同じ取引先・受注日・支払方法の商品は同じ受注としてグループ化
        order_key = nil
        
        # フォームの値を使用するケース
        if params[:use_form_values] == "1"
          # フォームの値を使用
          customer_id = params[:customer_id]
          payment_method_id = params[:payment_method_id]
          form_order_date = params[:order_date]
          form_expected_delivery_date = params[:expected_delivery_date]
          form_actual_delivery_date = params[:actual_delivery_date]
          
          if customer_id.blank?
            redirect_to import_csv_orders_path, alert: "取引先を選択してください。"
            return
          end
          
          if form_order_date.blank?
            redirect_to import_csv_orders_path, alert: "受注日を入力してください。"
            return
          end
          
          # フォームの値でキーを作成
          order_key = "form_values"
        else
          # CSVの値を使用
          # 取引先の特定
          customer = nil
          if customer_code.present?
            customer = Customer.find_by(customer_code: customer_code)
          elsif customer_name.present?
            customer = Customer.find_by(company_name: customer_name)
          end
          
          if customer.nil?
            error_messages << "取引先が見つかりません: #{customer_code || customer_name}"
            next
          end
          
          customer_id = customer.id
          
          # 支払方法の特定
          payment_method_id = nil
          if payment_method_name.present?
            payment_method = PaymentMethod.find_by(name: payment_method_name)
            payment_method_id = payment_method.id if payment_method.present?
          end
          
          # 日付の確認
          if order_date.blank?
            error_messages << "受注日が指定されていません"
            next
          end
          
          # 受注グループを特定するキーを作成
          order_key = "#{customer_id}_#{order_date}_#{payment_method_id}"
        end
        
        # キーに対応する受注データがなければ新規作成
        unless orders_data.key?(order_key)
          orders_data[order_key] = {
            customer_id: customer_id,
            payment_method_id: payment_method_id,
            order_date: params[:use_form_values] == "1" ? form_order_date : order_date,
            expected_delivery_date: params[:use_form_values] == "1" ? form_expected_delivery_date : expected_delivery_date,
            actual_delivery_date: params[:use_form_values] == "1" ? form_actual_delivery_date : actual_delivery_date,
            order_items: []
          }
        end
        
        # 商品情報の取得と検証
        product = nil
        if row['商品コード'].present?
          product = Product.find_by(product_code: row['商品コード'])
        elsif row['商品名'].present?
          product = Product.find_by(name: row['商品名'])
        end
        
        if product.nil?
          error_messages << "商品が見つかりません: #{row['商品コード'] || row['商品名']}"
          next
        end
        
        # 数量チェック
        quantity = row['数量'].to_i
        if quantity <= 0
          error_messages << "数量は1以上である必要があります: #{product.name}"
          next
        end
        
        # 単位を検索（指定されている場合）
        unit_id = nil
        if row['単位'].present?
          unit = Unit.find_by(name: row['単位'])
          unit_id = unit.id if unit.present?
        end
        
        # 税率とデフォルト値の設定
        tax_rate = row['税率'].present? ? row['税率'].to_f : (product.tax_rate&.rate || 10.0)
        unit_price = row['単価'].present? ? row['単価'].to_f : product.price
        
        # 受注項目を追加
        orders_data[order_key][:order_items] << {
          product_id: product.id,
          quantity: quantity,
          unit_price: unit_price,
          tax_rate: tax_rate,
          unit_id: unit_id,
          notes: row['備考']
        }
      end
      
      if validation_errors.present?
        redirect_to import_csv_orders_path, alert: "CSVデータの検証でエラーが発生しました:\n#{validation_errors.join("\n")}"
        return
      end
      
      if orders_data.empty?
        redirect_to import_csv_orders_path, alert: "CSVファイルに有効な注文データが含まれていません。以下を確認してください：\n"\
                                                 "・必須項目（商品コード/商品名、数量）が入力されているか\n"\
                                                 "・取引先情報が正しいか\n"\
                                                 "・商品情報が正しいか"
        return
      end
      
      # トランザクションを開始して受注を作成
      ActiveRecord::Base.transaction do
        orders_data.each do |key, data|
          order = Order.new(
            customer_id: data[:customer_id],
            payment_method_id: data[:payment_method_id],
            order_date: data[:order_date],
            expected_delivery_date: data[:expected_delivery_date],
            actual_delivery_date: data[:actual_delivery_date]
          )
          
          # 注文項目を作成
          data[:order_items].each do |item_data|
            order.order_items.build(item_data)
          end
          
          # 受注を保存
          if order.save
            success_count += 1
          else
            error_messages << "受注の保存中にエラーが発生しました: #{order.errors.full_messages.join(', ')}"
            raise ActiveRecord::Rollback
          end
        end
      end
      
      if error_messages.present?
        redirect_to import_csv_orders_path, alert: "エラーが発生しました: #{error_messages.join(', ')}"
      else
        redirect_to orders_path, notice: "CSVから#{success_count}件の受注を作成しました。"
      end
    rescue CSV::MalformedCSVError => e
      redirect_to import_csv_orders_path, alert: "CSVファイルの形式が不正です: #{e.message}"
    rescue => e
      # 詳細なエラー情報を管理者向けに表示
      error_message = "エラーが発生しました: #{e.message}\n"
      error_message += "エラー発生場所: #{e.backtrace.first(5).join("\n")}" if Rails.env.development?
      redirect_to import_csv_orders_path, alert: error_message
    end
  end

  private
    def set_order
      @order = Order.includes(:order_items, :customer, :payment_method).find(params[:id])
    end

    def order_params
      params.require(:order).permit(
        :customer_id, :order_date, :expected_delivery_date,
        :actual_delivery_date, :payment_method_id,
        order_items_attributes: [ :id, :product_id, :quantity, :unit_price, :tax_rate, :notes, :unit_id, :_destroy ]
      )
    end

    # 単価と税率を商品マスタから設定するヘルパーメソッド
    def set_price_and_tax_rate(order_items)
      order_items.each do |item|
        if item.product_id.present?
          product = Product.find(item.product_id)
          
          # 単価が未入力かつ商品マスタに単価がある場合のみセット
          if item.unit_price.blank? && product.price.present?
            item.unit_price = product.price
          end
          
          # 税率が未入力の場合のみセット
          if item.tax_rate.blank?
            item.tax_rate = product.tax_rate.rate if product.tax_rate.present?
          end
        end
      end
    end

    def set_payment_methods
      @payment_methods = PaymentMethod.all
    end

    def search_params
      params.fetch(:search, {}).permit(
        :customer_name,
        :order_date_from, :order_date_to,
        :expected_delivery_date_from, :expected_delivery_date_to,
        :actual_delivery_date_from, :actual_delivery_date_to,
        :total_without_tax,
        :payment_method_id,
        :invoice_status
      )
    end
end
