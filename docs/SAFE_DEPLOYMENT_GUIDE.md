# 🔒 本番データ保護 - 安全デプロイガイド

## 📋 デプロイ前チェックリスト

### ✅ 必須確認事項
- [ ] 新機能のローカルテスト完了
- [ ] 新しいマイグレーションの安全性確認
- [ ] 本番データベースバックアップ実行
- [ ] 緊急ロールバック手順の確認

## 🛡️ 安全デプロイ手順

### 1. バックアップ実行（必須）
```bash
./scripts/backup_production.sh
```

### 2. 安全デプロイ実行
```bash
./scripts/safe_deploy.sh
```

### 3. 緊急時ロールバック
```bash
./scripts/emergency_rollback.sh
```

## ⚠️ 危険なマイグレーション例

### 🚨 データ消失の危険
```ruby
# ❌ 危険: データが消える
remove_column :products, :old_column
drop_table :unused_table

# ✅ 安全: 段階的削除
# Step 1: アプリケーションコードから参照を削除
# Step 2: 数日後にマイグレーションでカラム削除
```

### 🚨 制約追加の危険
```ruby
# ❌ 危険: 既存nullデータでエラー
change_column_null :products, :category_id, false

# ✅ 安全: nullデータを事前処理
def change
  # 既存nullデータにデフォルト値設定
  Product.where(category_id: nil).update_all(category_id: default_category.id)
  # その後制約追加
  change_column_null :products, :category_id, false
end
```

## 📝 推奨開発フロー

### 1. 新機能開発
```bash
git checkout main
git pull origin main
git checkout -b feature/new-feature

# 開発・テスト
rails server # ローカル確認
```

### 2. デプロイ準備
```bash
git checkout main
git merge feature/new-feature
git push origin main
```

### 3. 本番デプロイ
```bash
./scripts/safe_deploy.sh
```

## 🆘 トラブル時の対応

### デプロイ失敗時
1. **ログ確認**: `bundle exec cap production deploy`のエラーメッセージ確認
2. **即座にロールバック**: `./scripts/emergency_rollback.sh`
3. **原因調査**: ローカル環境で問題再現・修正

### データベース問題時
1. **バックアップから復元**: スクリプトの指示に従って復元
2. **マイグレーション確認**: 危険な操作がないか再チェック
3. **段階的デプロイ**: 問題のあるマイグレーションを分割

## 📞 緊急連絡先
- システム管理者: [連絡先]
- バックアップ保存場所: `/tmp/clean_hy_app_backup_*.sql`
- 本番サーバー: `133.167.120.189`
