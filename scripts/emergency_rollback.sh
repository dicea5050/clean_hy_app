#!/bin/bash
# 緊急ロールバックスクリプト

set -e

echo "🚨 緊急ロールバックを開始します..."

# 1. Capistranoロールバック
echo "↩️  前回のリリースにロールバック中..."
bundle exec cap production deploy:rollback

# 2. データベースロールバック（必要な場合）
echo "⚠️  データベースもロールバックが必要ですか？ (y/N)"
echo "   注意: データベースロールバックは慎重に行ってください！"
read -r response

if [[ "$response" =~ ^[Yy]$ ]]; then
    echo "📋 利用可能なバックアップファイル:"
    ssh -i ~/.ssh/id_ed25519 ubuntu@133.167.120.189 'ls -lah /tmp/clean_hy_app_backup_*.sql' || echo "バックアップが見つかりません"
    
    echo "復元するバックアップファイル名を入力してください（例: clean_hy_app_backup_20231201_120000.sql）:"
    read -r backup_file
    
    if [ -n "$backup_file" ]; then
        echo "🔄 データベース復元中... ($backup_file)"
        ssh -i ~/.ssh/id_ed25519 ubuntu@133.167.120.189 \
          "cd /var/www/clean_hy_app/current && \
           RAILS_ENV=production PGPASSWORD=\$CLEAN_HY_APP_DATABASE_PASSWORD \
           psql -h localhost -p 5433 -U postgres clean_hy_app_production < /tmp/$backup_file"
        
        echo "✅ データベース復元完了"
    fi
fi

echo "🎯 ロールバック完了。アプリケーションを確認してください:"
echo "   http://133.167.120.189"
