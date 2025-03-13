# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = "1.0"

# Add additional assets to the asset load path.
Rails.application.config.assets.paths << Rails.root.join("app/assets/javascripts")
Rails.application.config.assets.paths << Rails.root.join("node_modules")

# Precompile additional assets.
Rails.application.config.assets.precompile += %w[ application.js orders.js order_calculations.js search_form.js payment_records.js ]

# Propshaftの設定
Rails.application.config.assets.paths << Rails.root.join("app/assets/javascripts")
Rails.application.config.assets.paths << Rails.root.join("node_modules")

# Propshaftの標準ルールに従い、JSファイルはapp/assets/javascriptsディレクトリに保存する
# このルールを守ることでアセットの管理が一貫して行えます
#
# 例: app/assets/javascripts/application.js
#     app/assets/javascripts/components/user_form.js
#     app/assets/javascripts/controllers/home_controller.js
