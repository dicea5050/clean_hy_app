#!/bin/bash
# 本番データベースバックアップスクリプト

TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="/tmp/clean_hy_app_backup_${TIMESTAMP}.sql"

echo "🔒 本番データベースバックアップを開始..."

# PostgreSQLバックアップ実行
ssh -i ~/.ssh/id_ed25519 ubuntu@133.167.120.189 \
  "cd /var/www/clean_hy_app/current && \
   RAILS_ENV=production PGPASSWORD=\$CLEAN_HY_APP_DATABASE_PASSWORD \
   pg_dump -h localhost -p 5433 -U postgres clean_hy_app_production > $BACKUP_FILE && \
   ls -lh $BACKUP_FILE"

if [ $? -eq 0 ]; then
    echo "✅ バックアップ完了: $BACKUP_FILE"
else
    echo "❌ バックアップ失敗！デプロイを中止してください。"
    exit 1
fi
