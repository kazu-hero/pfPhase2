# Org Schema Snapshot

このフォルダはSalesforceオブジェクトスキーマメタデータの再利用可能なスナップショットを保存します。

## 目的

- 日常的な参照用に `latest/` に最新スナップショットを保持
- 各更新後のポイントインタイムスナップショットを `history/<timestamp>/` に保存
- Org メタデータが変更された際にいつでも同じプロセスを再実行可能

## 出力構造

各 Org エイリアスに対して、以下の構造でファイルが生成されます（前提：org-schema/を起点とした相対パス）:

- `<OrgAlias>/latest/`
- `<OrgAlias>/history/<yyyyMMdd-HHmmss>/`

生成されるファイル：

- `entity-definitions.csv`: すべてのエンティティ定義（オブジェクトレベルの概要）
- `custom-objects.csv`: カスタムオブジェクトとカスタムメタデータオブジェクト（`__c`, `__mdt`）
- `custom-field-summary.csv`: `describe` から取得したカスタムオブジェクトの項目サマリー
- `describes/custom/<ObjectApiName>.json`: 完全なオブジェクト describe ペイロード
- `manifest.json`: 生成メタデータとファイルリスト

## 実行方法

## 実行方法

ワークスペースルートから実行：

```powershell
npm run schema:export
```

Org エイリアスを指定して実行：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\schema\export-org-schema.ps1 -OrgAlias "<YourOrgAlias>"
```

## 注意事項

- Salesforce CLI（`sf`）と認証済み Org が必要
- `-OrgAlias` パラメータで対象 Org を指定
- スクリプトは実行ごとに `latest/` を更新し、`history/` に1つのスナップショットを追加

## Salesforce 開発全般での利用

このドキュメント構造は任意の Salesforce プロジェクトで再利用可能です。Org エイリアスを指定するだけで、任意の接続済み Org のスキーマスナップショットを取得できます。
