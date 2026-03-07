# Salesforce 開発ドキュメント

このディレクトリには、Salesforce 開発全般で再利用可能なドキュメントとツールを格納します。

## ディレクトリ構成

### org-schema/
Salesforce Org のスキーマメタデータスナップショットを管理します。

**用途:**
- オブジェクト定義の履歴管理
- カスタムオブジェクト/カスタム項目の変更追跡
- 開発時のスキーマリファレンス

**使用方法:**
```powershell
# プロジェクト固有の Org に対して実行
npm run schema:export

# または任意の Org エイリアスを指定
powershell -ExecutionPolicy Bypass -File .\scripts\schema\export-org-schema.ps1 -OrgAlias "YourOrgAlias"
```

詳細は [org-schema/README.md](org-schema/README.md) を参照してください。

## 汎用性について

このディレクトリ配下のツールとドキュメントは、特定のプロジェクトに依存せず、任意の Salesforce プロジェクトで再利用できるように設計されています。
