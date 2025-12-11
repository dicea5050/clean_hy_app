# PostgreSQL接続時にタイムゾーンを日本時間（Asia/Tokyo）に設定
# 各接続が確立された際にタイムゾーンを設定する
ActiveSupport.on_load(:active_record) do
  ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.class_eval do
    alias_method :original_configure_connection, :configure_connection

    def configure_connection
      original_configure_connection
      execute("SET timezone = 'Asia/Tokyo'")
    end
  end
end
