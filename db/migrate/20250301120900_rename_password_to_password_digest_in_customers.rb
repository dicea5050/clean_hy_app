class RenamePasswordToPasswordDigestInCustomers < ActiveRecord::Migration[7.1]
  def up
    # 既に適用済みであるため、何もしません
    puts "このマイグレーションはスキップされました：password_digestカラムは既に存在します"
  end

  def down
    # ダウンマイグレーションも何もしません
  end
end
