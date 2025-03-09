# clean_hy_app

## プロジェクトルール

### アセット管理

このプロジェクトでは、Propshaftをアセットパイプラインとして使用しています。以下のルールに従ってください：

1. **JavaScriptファイル**
   - すべてのJavaScriptファイルは `app/assets/javascripts` ディレクトリに保存してください
   - 推奨される構造:
     ```
     app/assets/javascripts/
     ├── application.js
     ├── components/
     │   └── user_form.js
     ├── controllers/
     │   └── home_controller.js
     └── utilities/
         └── helpers.js
     ```

2. **CSSファイル**
   - すべてのCSSファイルは `app/assets/stylesheets` ディレクトリに保存してください

3. **画像ファイル**
   - すべての画像ファイルは `app/assets/images` ディレクトリに保存してください

この標準に従うことで、アセットの管理が一貫して行え、チーム全体での開発効率が向上します。
