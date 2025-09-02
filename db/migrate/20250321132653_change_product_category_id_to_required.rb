class ChangeProductCategoryIdToRequired < ActiveRecord::Migration[8.0]
  def change
    # 既存のnullデータがある場合に備えて、まずデフォルト値を設定する
    # この部分は商品がすでに登録されていて、カテゴリーがnullの場合に対応するためのものです
    # 実運用では適切なカテゴリーIDを設定する必要があります
    default_category = ProductCategory.first

    if default_category.present?
      # nullのproduct_category_idを持つ商品に、デフォルトカテゴリーを設定
      Product.where(product_category_id: nil).update_all(product_category_id: default_category.id)

      # カラムを必須に変更
      change_column_null :products, :product_category_id, false
    else
      puts "警告: デフォルトカテゴリーが見つかりません。マイグレーションを実行する前にカテゴリーを作成してください。"
      puts "マイグレーションは中断されました。"
      raise ActiveRecord::IrreversibleMigration
    end
  end
end
