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
Administrator.create!(
  email: 'admin@example.com',
  password: 'password123',
  password_confirmation: 'password123',
  role: 'admin'
) if Administrator.count.zero?

puts "管理者ユーザーが作成されました。メールアドレス: admin@example.com, パスワード: password123"

# 支払い方法のデータを追加
PaymentMethod.create([
  { name: '銀行振込' },
  { name: '口座引き落とし' },
  { name: '代金引換' }
])
