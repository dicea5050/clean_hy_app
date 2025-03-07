# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = "1.0"

# Add additional assets to the asset load path.
Rails.application.config.assets.paths << Rails.root.join("app/assets/javascripts")
Rails.application.config.assets.paths << Rails.root.join("node_modules")

# Precompile additional assets.
Rails.application.config.assets.precompile += %w[ application.js orders.js ]

# Propshaftのためのアセット設定 (このファイルがない場合は作成)
Rails.application.config.assets.paths << Rails.root.join("node_modules")

# Rails 8でPropshaftを使用する場合の設定
Rails.application.config.assets.paths << Rails.root.join("app/assets/javascripts")
