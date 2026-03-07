# 04 Existing Data Model

## 位置づけ
- 本ファイルは実環境のデータモデル（唯一の正）を記録する
- 「開発App」開発作業フォルダのデータモデル定義を基準とするが、実環境が最優先
- 定期的に実環境からスキーマを取得し、このファイルを更新する

## スキーマ取得方法
```powershell
# プロジェクトルートで実行
npm run schema:export
```
- 出力先: `docs/org-schema/pfPhase2Org/latest/`
- 履歴: `docs/org-schema/pfPhase2Org/history/<yyyyMMdd-HHmmss>/`
- 注意: EntityDefinition + `sf sobject describe` を使用

---

## **⚠️ 重要：実環境のデータモデルが唯一の正です**

このファイルに記載されたオブジェクト名、項目名、リレーション名を**厳密に使用**してください。
既存資料は参考情報として扱い、矛盾がある場合は実環境を優先します。

**最終更新日**: 2026年3月7日
**データソース**: 「開発App」開発作業フォルダ\02_データモデル定義.md（初期値）

---

## **1. 主要オブジェクト（5種類）**

### **1.1 Dev_Service__c（ユーザサービス）**

**用途**: ユーザーからの問い合わせやサポート要求を管理（ケースオブジェクト的な役割）

**API Name**: `Dev_Service__c`
**Label**: ユーザサービス

**主要項目**:
| 項目ラベル | API Name | データ型 | 必須 | 説明 |
|--------|----------|----------|------|------|
| サービス名 | Name | テキスト(80) | ✓ | サービスの名称（自動採番可） |
| ステータス | Status__c | 選択リスト | ✓ | OPEN / CLOSE |
| 担当者 | OwnerId | 参照(User) | ✓ | Salesforce標準項目 |
| ログ番号 | logNo__c | テキスト | | ログ管理用番号 |
| 内容 | body__c | リッチテキスト | | ご要望・ご質問の内容（HTML形式） |
| 課題数 | countIssue__c | 集計(COUNT) | | 関連課題数（自動集計） |
| ステータスシグナル | StatusSignal__c | 数式(Text) | | ステータス画像表示用数式 |

**選択リスト値（Status__c）**:
- `OPEN` - 対応中（デフォルト）
- `CLOSE` - 完了・クローズ

**Agent CRUD権限**: ✅ 全操作可能（作成・参照・更新・削除）

**リレーション**:
- Relation_Support2Issue__c を経由して Issue__c と多対多

---

### **1.2 Issue__c（課題・要望）**

**用途**: サービスに関連する課題や要望を表現

**API Name**: `Issue__c`
**Label**: 課題・要望

**主要項目**:
| 項目ラベル | API Name | データ型 | 必須 | 説明 |
|--------|----------|----------|------|------|
| 課題名 | Name | テキスト(80) | ✓ | 課題の名称 |
| ステータス | Status__c | 選択リスト | ✓ | TODO / WIP / DONE / PENDING / DROP |
| 担当者 | OwnerId | 参照(User) | ✓ | Salesforce標準項目 |
| カテゴリ | category__c | 選択リスト | | 課題のカテゴリ |
| 内容 | content__c | リッチテキスト(HTML) | | 課題の詳細内容 |
| サポート数 | countSupport__c | 集計(COUNT) | | 関連サービス数（自動集計） |
| 施策数 | countPlan__c | 集計(COUNT) | | 関連施策数（自動集計） |
| 単発開発 | fastTicket__c | 参照(Dev_Ticket__c) | | 単発の開発・設定チケット |

**選択リスト値（Status__c）**: TicketStatusグローバル値セット使用
- `TODO` - 未着手（デフォルト）
- `WIP` - 作業中（Work In Progress）
- `DONE` - 完了
- `PENDING` - 保留
- `DROP` - 中止

**Agent CRUD権限**: ✅ 全操作可能（作成・参照・更新・削除）

**リレーション**:
- 上流: Relation_Support2Issue__c を経由して Dev_Service__c と多対多
- 下流: Relation_Issue2Plan__c を経由して TechActionPlan__c と多対多

---

### **1.3 TechActionPlan__c（対応施策）**

**用途**: 課題を解決するための技術的施策を表現

**API Name**: `TechActionPlan__c`
**Label**: 対応施策

**主要項目**:
| 項目ラベル | API Name | データ型 | 必須 | 説明 |
|--------|----------|----------|------|------|
| 施策名 | Name | テキスト(80) | ✓ | 施策の名称 |
| ステータス | Status__c | 選択リスト | ✓ | TODO / WIP / DONE / PENDING / DROP |
| 担当者 | OwnerId | 参照(User) | ✓ | Salesforce標準項目 |
| 施策タイプ | planType__c | 選択リスト | | 施策の種別 |
| 内容 | content__c | リッチテキスト(HTML) | | 施策の詳細内容 |
| 施策番号 | planNum__c | テキスト | | 施策管理番号 |
| 関連課題数 | countIssue__c | 集計(COUNT) | | 関連課題数（自動集計） |
| 機能要件数 | countRequirement__c | 集計(COUNT) | | 関連機能要件数（自動集計） |

**Agent CRUD権限**: ✅ 全操作可能（作成・参照・更新・削除）

**リレーション**:
- 上流: Relation_Issue2Plan__c を経由して Issue__c と多対多
- 下流: Relation_Plan2Requirements__c を経由して FunctionRequirements__c と多対多

---

### **1.4 FunctionRequirements__c（機能要件）**

**用途**: 施策を実現するための機能要件を表現

**API Name**: `FunctionRequirements__c`
**Label**: 機能要件

**主要項目**:
| 項目ラベル | API Name | データ型 | 必須 | 説明 |
|--------|----------|----------|------|------|
| 要件名 | Name | テキスト(80) | ✓ | 要件の名称 |
| ステータス | Status__c | 選択リスト | ✓ | TODO / WIP / DONE / PENDING / DROP |
| 担当者 | OwnerId | 参照(User) | ✓ | Salesforce標準項目 |
| カテゴリ | requirementsCategory__c | 選択リスト | | 要件のカテゴリ |
| 内容 | content__c | リッチテキスト(HTML) | | 要件の詳細内容 |
| 対応施策数 | cntPlan__c | 集計(COUNT) | | 関連施策数（自動集計） |
| 開発チケット数 | cntDevTicket__c | 集計(COUNT) | | 関連開発チケット数（自動集計） |

**Agent CRUD権限**: ✅ 全操作可能（作成・参照・更新・削除）

**リレーション**:
- 上流: Relation_Plan2Requirements__c を経由して TechActionPlan__c と多対多
- 下流: Relation_Requirements2Dev__c を経由して Dev_Ticket__c と多対多

---

### **1.5 Dev_Ticket__c（開発チケット）**

**用途**: 実際の開発タスクを表現

**API Name**: `Dev_Ticket__c`
**Label**: 開発チケット

**主要項目**:
| 項目ラベル | API Name | データ型 | 必須 | 説明 |
|--------|----------|----------|------|------|
| チケット番号 | Name | 自動採番 | ✓ | DEV-{0000} 形式 |
| ステータス | Status__c | 選択リスト | ✓ | TODO / WIP / DONE / PENDING / DROP |
| 担当者 | OwnerId | 参照(User) | ✓ | Salesforce標準項目 |
| ログ番号 | logNo__c | テキスト | | ログ管理用番号 |
| 機能要件数 | functionRequirement__c | 集計(COUNT) | | 関連する機能要件の数 |

**Agent CRUD権限**: ✅ 全操作可能（作成・参照・更新・削除）

**リレーション**:
- 上流: Relation_Requirements2Dev__c を経由して FunctionRequirements__c と多対多

---

## **2. 中間オブジェクト（リレーションシップ）**

多対多関係を実現するための中間オブジェクト

### **2.1 Relation_Support2Issue__c**
**接続**: Dev_Service__c ⇔ Issue__c
**API Name**: `Relation_Support2Issue__c`
**Agent CRUD権限**: ✅ 全操作可能

### **2.2 Relation_Issue2Plan__c**
**接続**: Issue__c ⇔ TechActionPlan__c
**API Name**: `Relation_Issue2Plan__c`
**Agent CRUD権限**: ✅ 全操作可能

### **2.3 Relation_Plan2Requirements__c**
**接続**: TechActionPlan__c ⇔ FunctionRequirements__c
**API Name**: `Relation_Plan2Requirements__c`
**Agent CRUD権限**: ✅ 全操作可能

### **2.4 Relation_Requirements2Dev__c**
**接続**: FunctionRequirements__c ⇔ Dev_Ticket__c
**API Name**: `Relation_Requirements2Dev__c`
**Agent CRUD権限**: ✅ 全操作可能

---

## **3. その他のカスタムオブジェクト（実環境に存在）**

以下は実環境に存在するカスタムオブジェクトですが、Agentの主要対象外です。
必要に応じて参照可能ですが、構造変更は対象外です。

### 分類: 要件・設計関連
- `EventRequirements__c` - イベント要件
- `ObjectRequirement__c` - オブジェクト要件
- `PermissionRequirement__c` - 権限要件
- `ReportRequirement__c` - レポート要件
- `DesignDiagram__c` - 設計図
- `OperationFlow__c` - オペレーションフロー

### 分類: テスト関連
- `Testcase__c` - テストケース
- `TestSuite__c` - テストスイート
- `PracticeTest__c` - 練習テスト

### 分類: 予算・実績関連
- `Budget__c` - 予算
- `BudgetCategory__c` - 予算カテゴリ
- `BudgetAndActuals__c` - 予算と実績
- `ActualAmount__c` - 実績金額

### 分類: タグ・中間リレーション
- `Tag__c` - タグ
- 多数の `Relation_*__c` パターンのオブジェクト

**Agent CRUD権限**: ⚠️ 要確認（現時点では参照のみ推奨）

---

## **4. データフロー図（主要オブジェクト）**

```
[Dev_Service__c] ユーザサービス
	│
	│ Relation_Support2Issue__c
	↓
    [Issue__c] 課題・要望
	│
	│ Relation_Issue2Plan__c
	↓
[TechActionPlan__c] 対応施策
	│
	│ Relation_Plan2Requirements__c
	↓
[FunctionRequirements__c] 機能要件
	│
	│ Relation_Requirements2Dev__c
	↓
  [Dev_Ticket__c] 開発チケット
```

---

## **5. SOQLクエリのサンプル**

### **5.1 全ての課題とその関連サービスを取得**
```sql
SELECT Id, Name, Status__c,
    (SELECT Dev_Service__c, Dev_Service__r.Name 
     FROM Relation_Support2Issues__r)
FROM Issue__c
```

### **5.2 特定サービスの下流を全て取得**
```sql
SELECT Id, Issue__c, Issue__r.Name, Issue__r.Status__c
FROM Relation_Support2Issue__c
WHERE Dev_Service__c = :serviceId
```

### **5.3 ステータス別の課題数を取得**
```sql
SELECT Status__c, COUNT(Id) cnt
FROM Issue__c
GROUP BY Status__c
```

---

## **6. グローバル値セット**

### **TicketStatus（共通ステータス）**
**使用オブジェクト**: Issue__c, TechActionPlan__c, FunctionRequirements__c, Dev_Ticket__c

**選択リスト値**:
- `TODO` - 未着手
- `WIP` - 作業中（Work In Progress）
- `DONE` - 完了
- `PENDING` - 保留
- `DROP` - 中止

**注意**: Dev_Service__c は独自のステータス（OPEN/CLOSE）を使用

---

## **7. 命名規則**

### オブジェクトAPI名
- カスタムオブジェクト: `CamelCase__c`
- 中間オブジェクト: `Relation_<接続先略称>__c`

### 項目API名
- カスタム項目: `camelCase__c` または `snake_case__c`
- リレーション項目: オブジェクト名そのまま（例: `Dev_Service__c`, `Issue__c`）

### リレーション名（SOQL用）
- `__c` を `__r` に置き換え
- 例: `Dev_Service__c` → `Dev_Service__r`
- 子リレーション: `Relation_Support2Issues__r` （複数形 `s` が付く）

---

## **8. 更新履歴**

| 日付 | 更新者 | 更新内容 |
|------|--------|----------|
| 2026-03-07 | Agent | 初期作成（「開発App」\02_データモデル定義.mdをベースに作成） |

---

## **9. 次回更新時の確認事項**

- [ ] 実環境からスキーマエクスポートを実行（`npm run schema:export`）
- [ ] 新規追加されたカスタム項目の確認
- [ ] 選択リスト値の変更確認
- [ ] リレーションシップの変更確認
- [ ] Agent CRUD権限の実際の範囲を確認
- [ ] 標準オブジェクトへの参照権限の確認

## 運用ルール
- 実環境の変更があった場合は、必ずこのファイルを更新する
- 更新時は更新履歴に記録する
- 矛盾がある場合は実環境を優先し、このファイルを修正する
- 定期的に `npm run schema:export` を実行してスキーマを取得する
