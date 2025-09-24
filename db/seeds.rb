# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# 初期管理者ユーザーの作成
admin = Administrator.find_or_initialize_by(email: 'admin@example.com')
admin.assign_attributes(
  password: 'password123',
  password_confirmation: 'password123',
  role: 'admin'
)
admin.save!

# 制限付き編集者ユーザーの作成
editor_limited = Administrator.find_or_initialize_by(email: 'editor_limited@example.com')
editor_limited.assign_attributes(
  password: 'password123',
  password_confirmation: 'password123',
  role: 'editor_limited'
)
editor_limited.save!

puts "管理者ユーザーが作成されました。メールアドレス: admin@example.com, パスワード: password123"
puts "制限付き編集者ユーザーが作成されました。メールアドレス: editor_limited@example.com, パスワード: password123"

# 支払い方法のデータを追加
[ '銀行振込', '口座引き落とし', '代金引換' ].each do |name|
  PaymentMethod.find_or_create_by(name: name)
end
