require_relative "boot"

require "rails/all"
require "propshaft"
require "bcrypt"
require "csv"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module CleanHyApp
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.0

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # デフォルトのロケールを日本語(:ja)に設定
    config.i18n.default_locale = :ja

    # タイムゾーンを東京(JST +9:00)に設定
    config.time_zone = "Tokyo"
    # ActiveRecordのデフォルトタイムゾーンをUTCに設定（Railsが自動的にTokyoタイムゾーンに変換）
    config.active_record.default_timezone = :utc

    # Bootstrapのアセット設定
    config.assets.paths << Rails.root.join("node_modules")
  end
end
