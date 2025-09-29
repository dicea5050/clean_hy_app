#!/bin/bash
# 安全な本番デプロイスクリプト

set -e

echo "🚀 安全な本番デプロイを開始します..."

# 1. 事前チェック
echo "📋 事前チェック中..."
if ! git diff --quiet origin/main..HEAD; then
    echo "✅ デプロイ対象のコミットが存在します"
    git log --oneline origin/main..HEAD
else
    echo "⚠️  新しいコミットがありません。デプロイを続行しますか？ (y/N)"
    read -r response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        echo "デプロイを中止しました。"
        exit 1
    fi
fi

# 2. 危険なマイグレーションチェック
echo "🔍 危険なマイグレーション確認中..."
DANGEROUS_MIGRATIONS=$(find db/migrate -name "*.rb" -newer db/migrate/20250925030429_add_product_specification_to_order_items.rb -exec grep -l "remove_column\|drop_table\|drop_index\|change_column.*null.*false" {} \; 2>/dev/null || true)

if [ -n "$DANGEROUS_MIGRATIONS" ]; then
    echo "⚠️  危険なマイグレーションが検出されました:"
    echo "$DANGEROUS_MIGRATIONS"
    echo "これらのマイグレーションを実行しますか？事前にバックアップを強く推奨します。(y/N)"
    read -r response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        echo "デプロイを中止しました。マイグレーションを確認してください。"
        exit 1
    fi
fi

# 3. バックアップ実行
echo "💾 本番データベースバックアップ実行中..."
./scripts/backup_production.sh

# 4. デプロイ実行
echo "🚀 Capistranoデプロイを開始..."
bundle exec cap production deploy

# 5. デプロイ後確認
echo "✅ デプロイ完了。動作確認をしてください:"
echo "   http://133.167.120.189"

echo "🎉 安全デプロイが正常に完了しました！"
