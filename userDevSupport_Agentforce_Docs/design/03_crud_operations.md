# Phase 2 設計書：CRUD操作設計とSOQL最適化

## 設計日
2026年3月8日

## 設計者
AgentAI (Phase 2 設計フェーズ)

## 参照定義
- `01_overall_architecture.md` - 全体アーキテクチャ
- `02_response_patterns.md` - 応答パターン
- `04_existing_data_model.md` - データモデル定義

---

## 1. CRUD操作設計の目的

### 1.1 目標
- レコードの検索、参照、作成、更新、削除を安全かつ効率的に実行
- SOQL最適化によるパフォーマンス確保
- Governor Limits遵守
- ユーザー権限の尊重

### 1.2 設計方針
- Agent Actionsとして実装
- Apexコントローラーで実行（with sharing必須）
- 操作ログの記録
- エラーハンドリングの徹底

---

## 2. CRUD操作一覧

### 2.1 操作定義
| 操作ID | 操作名 | 説明 | Agent Action名 |
|-------|-------|------|---------------|
| C-001 | Create | レコード作成 | createRecord |
| R-001 | Read (Search) | レコード検索 | searchRecords |
| R-002 | Read (Detail) | レコード詳細取得 | getRecordDetails |
| U-001 | Update | レコード更新 | updateRecord |
| D-001 | Delete | レコード削除 | deleteRecord |
| R-003 | Read (Related) | 関連レコード取得 | getRelatedRecords |

---

## 3. C-001: Create（レコード作成）

### 3.1 概要
指定されたオブジェクトに新規レコードを作成

### 3.2 入力パラメータ
| パラメータ名 | 型 | 必須 | 説明 |
|-----------|---|-----|------|
| objectApiName | String | ✓ | オブジェクトAPI名（例: Issue__c） |
| fieldValues | Map<String, Object> | ✓ | 項目名と値のマップ |
| userId | String | ✓ | 実行ユーザーID |

### 3.3 処理フロー
```
[入力受信]
    ↓
[オブジェクト名検証] ← 04_existing_data_model.md参照
    ↓
[必須項目チェック]
    ↓
[ユーザー確認] ← P-001パターン適用
    ↓（承認後）
[権限チェック]（with sharing）
    ↓
[レコード作成実行]
    ↓
[操作ログ記録]
    ↓
[結果返却] ← P-006パターン適用
```

### 3.4 SOQL/DML
```apex
// 必須項目チェック用SOQL
List<FieldDefinition> fields = [
    SELECT QualifiedApiName, IsNillable
    FROM FieldDefinition
    WHERE EntityDefinition.QualifiedApiName = :objectApiName
        AND IsNillable = false
    LIMIT 100
];

// レコード作成DML
SObject record = Schema.getGlobalDescribe().get(objectApiName).newSObject();
for (String field : fieldValues.keySet()) {
    record.put(field, fieldValues.get(field));
}
insert record;
```

### 3.5 エラーハンドリング
| エラータイプ | 条件 | 処理 |
|------------|------|------|
| 必須項目未入力 | 必須項目がfieldValuesに含まれない | P-003適用、再入力促す |
| オブジェクト存在しない | objectApiNameが無効 | P-003適用、正しいオブジェ| 権限不足 | 作成権限がない | P-003適用、権限不足通知 |
| 重複エラー | ユニーク制約違反 | P-003適用、重複レコード通知 |
| DML例外 | その他のDMLエラー | P-003適用、システムエラー通知 |

### 3.6 パフォーマンス考慮
- 1回のトランザクションで1レコードのみ作成
- 大量作成は非対応（Governor Limits考慮）

---

## 4. R-001: Read (Search)（レコード検索）

### 4.1 概要
指定された条件でレコードを検索

### 4.2 入力パラメータ
| パラメータ名 | 型 | 必須 | 説明 |
|-----------|---|-----|------|
| objectApiName | String | ✓ | オブジェクトAPI名 |
| searchConditions | Map<String, Object> | | 検索条件（項目名と値のマップ） |
| orderBy | String | | ソート条件（例: Name ASC） |
| limitCount | Integer | | 取得件数上限（デフォルト: 100） |
| offset | Integer | | オフセット（ページネーション用） |
| userId | String | ✓ | 実行ユーザーID |

### 4.3 処理フロー
```
[入力受信]
    ↓
[オブジェクト名検証]
    ↓
[検索条件構築]
    ↓
[SOQL生成]
    ↓
[権限チェック]（with sharing）
    ↓
[SOQL実行]
    ↓
[結果整形]
    ↓
[結果返却] ← P-002パターン適用
```

### 4.4 SOQL最適化

#### 4.4.1 基本SOQL構造
```apex
String soql = 'SELECT Id, Name, {主要項目} ' +
              'FROM ' + objectApiName + ' ' +
              'WHERE {検索条件} ' +
              'ORDER BY ' + orderBy + ' ' +
              'LIMIT ' + limitCount + ' ' +
              'OFFSET ' + offset;
```

#### 4.4.2 WHERE句の最適化
| 最適化項目 | 方針 | 例 |
|----------|------|---|
| インデックス項目優先 | Id, Name, OwnerId, CreatedDate等を優先 | `WHERE OwnerId = :userId` |
| 範囲検索の効率化 | 日付範囲は具体的に指定 | `WHERE CreatedDate >= :startDate AND CreatedDate <= :endDate` |
| LIKE句の最適化 | 前方一致を使用（`keyword%`） | `WHERE Name LIKE :keyword + '%'` |
| NULL判定 | `= NULL`ではなく`IS NULL`を使用 | `WHERE Description__c IS NULL` |

#### 4.4.3 SELECT句の最適化
- 必要な項目のみ取得（`SELECT *`禁止）
- 主要項目の優先順位:
  1. Id（必須）
  2. Name（必須）
  3. OwnerId（必須）
  4. Status__c（ステータス項目）
  5. その他のカスタム項目

#### 4.4.4 LIMIT句の使用
| シナリオ | LIMIT値 | 理由 |
|---------|--------|------|
| 通常検索 | 100 | 表示上限として適切 |
| 詳細検索 | 1000 | 非機能要件（NFR-001）に準拠 |
| 存在チェック | 1 | 最小限のデータ取得 |

#### 4.4.5 インデックス活用
- カスタムインデックス推奨項目:
  - Status__c（頻繁にフィルタリング）
  - OwnerId（担当者検索）
  - CreatedDate（作成日範囲検索）
  - カテゴリ項目（Issue__c.category__c等）

### 4.5 検索パターン

#### パターン1: 全件検索
```apex
SELECT Id, Name, OwnerId, Status__c, CreatedDate
FROM Issue__c
ORDER BY CreatedDate DESC
LIMIT 100
```

#### パターン2: ステータス検索
```apex
SELECT Id, Name, OwnerId, Status__c, CreatedDate
FROM Issue__c
WHERE Status__c = 'WIP'
ORDER BY CreatedDate DESC
LIMIT 100
```

#### パターン3: キーワード検索
```apex
SELECT Id, Name, OwnerId, Status__c, CreatedDate
FROM Issue__c
WHERE Name LIKE :keyword + '%'
ORDER BY CreatedDate DESC
LIMIT 100
```

#### パターン4: 複合条件検索
```apex
SELECT Id, Name, OwnerId, Status__c, category__c, CreatedDate
FROM Issue__c
WHERE Status__c = 'WIP'
    AND OwnerId = :userId
    AND CreatedDate >= :startDate
ORDER BY CreatedDate DESC
LIMIT 100
```

#### パターン5: ページネーション検索
```apex
SELECT Id, Name, OwnerId, Status__c, CreatedDate
FROM Issue__c
ORDER BY CreatedDate DESC
LIMIT 100
OFFSET 100  -- 2ページ目
```

### 4.6 エラーハンドリング
| エラータイプ | 条件 | 処理 |
|------------|------|------|
| オブジェクト存在しない | objectApiNameが無効 | P-003適用 |
| 権限不足 | 参照権限がない | P-003適用 |
| 不正な検索条件 | 項目名が存在しない | P-003適用 |
| SOQL例外 | その他のエラー | P-003適用 |

---

## 5. R-002: Read (Detail)（レコード詳細取得）

### 5.1 概要
指定されたレコードIDの詳細情報を取得

### 5.2 入力パラメータ
| パラメータ名 | 型 | 必須 | 説明 |
|-----------|---|-----|------|
| recordId | String | ✓ | レコードID |
| objectApiName | String | ✓ | オブジェクトAPI名 |
| includeRelated | Boolean | | 関連レコードを含めるか（デフォルト: false） |
| userId | String | ✓ | 実行ユーザーID |

### 5.3 処理フロー
```
[入力受信]
    ↓
[レコードID検証]
    ↓
[オブジェクト名検証]
    ↓
[SOQL生成]
    ↓
[権限チェック]（with sharing）
    ↓
[SOQL実行]
    ↓
[関連レコード取得]（includeRelated = trueの場合）
    ↓
[結果整形]
    ↓
[結果返却] ← P-002パターン適用
```

### 5.4 SOQL設計

#### 5.4.1 基本詳細取得
```apex
SELECT Id, Name, OwnerId, Status__c, category__c, content__c,
       CreatedDate, LastModifiedDate,
       countSupport__c, countPlan__c
FROM Issue__c
WHERE Id = :recordId
LIMIT 1
```

#### 5.4.2 関連レコード含む（サブクエリ使用）
```apex
SELECT Id, Name, OwnerId, Status__c, category__c, content__c,
       CreatedDate, LastModifiedDate,
       (SELECT Id, Name, Dev_Service__c
        FROM Relation_Support2Issue__r
        ORDER BY CreatedDate DESC
        LIMIT 10)
FROM Issue__c
WHERE Id = :recordId
LIMIT 1
```

### 5.5 エラーハンドリング
| エラータイプ | 条件 | 処理 |
|------------|------|------|
| レコード存在しない | 該当レコードなし | P-003適用 |
| 権限不足 | 参照権限がない | P-003適用 |
| 不正なID | recordId形式が不正 | P-003適用 |

---

## 6. U-001: Update（レコード更新）

### 6.1 概要
指定されたレコードの項目を更新

### 6.2 入力パラメータ
| パラメータ名 | 型 | 必須 | 説明 |
|-----------|---|-----|------|
| recordId | String | ✓ | レコードID |
| objectApiName | String | ✓ | オブジェクトAPI名 |
| fieldValues | Map<String, Object> | ✓ | 更新する項目名と値のマップ |
| userId | String | ✓ | 実行ユーザーID |

### 6.3 処理フロー
```
[入力受信]
    ↓
[レコードID検証]
    ↓
[既存レコード取得]
    ↓
[変更内容確認] ← P-001パターン適用（更新前後の差分表示）
    ↓（承認後）
[権限チェック]（with sharing）
    ↓
[レコード更新実行]
    ↓
[操作ログ記録]
    ↓
[結果返却] ← P-006パターン適用
```

### 6.4 SOQL/DML
```apex
// 既存レコード取得
SObject record = Database.query(
    'SELECT Id, Name, ' + String.join(fieldValues.keySet(), ', ') + ' ' +
    'FROM ' + objectApiName + ' ' +
    'WHERE Id = :recordId ' +
    'LIMIT 1'
)[0];

// 項目更新
for (String field : fieldValues.keySet()) {
    record.put(field, fieldValues.get(field));
}

// DML実行
update record;
```

### 6.5 エラーハンドリング
| エラータイプ | 条件 | 処理 |
|------------|------|------|
| レコード存在しない | 該当レコードなし | P-003適用 |
| 権限不足 | 更新権限がない | P-003適用 |
| 必須項目欠落 | 必須項目をNULLに更新 | P-003適用、変更不可通知 |
| DML例外 | その他のDMLエラー | P-003適用 |

---

## 7. D-001: Delete（レコード削除）

### 7.1 概要
指定されたレコードを削除

### 7.2 入力パラメータ
| パラメータ名 | 型 | 必須 | 説明 |
|-----------|---|-----|------|
| recordId | String | ✓ | レコードID |
| objectApiName | String | ✓ | オブジェクトAPI名 |
| userId | String | ✓ | 実行ユーザーID |

### 7.3 処理フロー
```
[入力受信]
    ↓
[レコードID検証]
    ↓
[既存レコード取得]
    ↓
[関連レコード確認]
    ↓
[削除確認] ← P-001パターン適用（影響範囲警告含む）
    ↓（承認後）
[権限チェック]（with sharing）
    ↓
[レコード削除実行]
    ↓
[操作ログ記録]
    ↓
[結果返却] ← P-006パターン適用
```

### 7.4 関連レコード確認SOQL

#### 例: Issue__cの関連レコード確認
```apex
// Dev_Service__cとのリレーション確認
Integer supportCount = [
    SELECT COUNT()
    FROM Relation_Support2Issue__c
    WHERE Issue__c = :recordId
];

// TechActionPlan__cとのリレーション確認
Integer planCount = [
    SELECT COUNT()
    FROM Relation_Issue2Plan__c
    WHERE Issue__c = :recordId
];
```

### 7.5 DML
```apex
SObject record = Schema.getGlobalDescribe().get(objectApiName).newSObject(recordId);
delete record;
```

### 7.6 エラーハンドリング
| エラータイプ | 条件 | 処理 |
|------------|------|------|
| レコード存在しない | 該当レコードなし | P-003適用 |
| 権限不足 | 削除権限がない | P-003適用 |
| 参照制約違反 | 主従関係で参照されている | P-003適用、削除不可通知 |
| DML例外 | その他のDMLエラー | P-003適用 |

---

## 8. R-003: Read (Related)（関連レコード取得）

### 8.1 概要
指定されたレコードに関連するレコードを取得

### 8.2 入力パラメータ
| パラメータ名 | 型 | 必須 | 説明 |
|-----------|---|-----|------|
| recordId | String | ✓ | 起点レコードID |
| objectApiName | String | ✓ | 起点オブジェクトAPI名 |
| relatedObjectApiName | String | ✓ | 関連オブジェクトAPI名 |
| relationshipName | String | ✓ | リレーションシップ名 |
| userId | String | ✓ | 実行ユーザーID |

### 8.3 処理フロー
```
[入力受信]
    ↓
[レコードID検証]
    ↓
[リレーションシップ検証]
    ↓
[SOQL生成]
    ↓
[権限チェック]（with sharing）
    ↓
[SOQL実行]
    ↓
[結果整形]
    ↓
[結果返却] ← P-002パターン適用
```

### 8.4 SOQL設計

#### パターン1: Dev_Service__c → Issue__c
```apex
SELECT Id, Name,
       (SELECT Id, Name, Issue__c, Issue__r.Name, Issue__r.Status__c
        FROM Relation_Support2Issue__r
        ORDER BY CreatedDate DESC
        LIMIT 50)
FROM Dev_Service__c
WHERE Id = :recordId
LIMIT 1
```

#### パターン2: Issue__c → TechActionPlan__c
```apex
SELECT Id, Name,
       (SELECT Id, Name, TechActionPlan__c, TechActionPlan__r.Name, TechActionPlan__r.Status__c
        FROM Relation_Issue2Plan__r
        ORDER BY CreatedDate DESC
        LIMIT 50)
FROM Issue__c
WHERE Id = :recordId
LIMIT 1
```

---

## 9. Governor Limits対策

### 9.1 SOQL Limits
| 制限項目 | 同期コンテキスト | 対策 |
|---------|---------------|------|
| SOQL実行数 | 100回 | バルク化、サブクエリ活用 |
| 取得レコード数 | 50,000件 | LIMIT句使用、ページネーション |

### 9.2 DML Limits
| 制限項目 | 同期コンテキスト | 対策 |
|---------|---------------|------|
| DML実行数 | 150回 | バルク化 |
| DMLレコード数 | 10,000件 | LIMIT設定、バッチ処理検討 |

### 9.3 実装方針
- 1トランザクション1レコード操作を基本とする
- 大量操作は非対応（ユーザー向けAgentのため）
- リトライ時もGovernor Limits考慮

---

## 10. 操作ログ設計

### 10.1 ログオブジェクト
Phase 3で作成予定: `Agent_Operation_Log__c`

### 10.2 ログ項目
| 項目名 | API名 | 型 | 説明 |
|-------|-------|---|------|
| ログID | Name | 自動採番 | ログ識別子 |
| ユーザーID | UserId__c | 参照(User) | 実行ユーザー |
| 操作タイプ | OperationType__c | 選択リスト | CREATE/READ/UPDATE/DELETE |
| 対象オブジェクト | TargetObject__c | テキスト | オブジェクトAPI名 |
| 対象レコードID | TargetRecordId__c | テキスト | レコードID |
| タイムスタンプ | OperationTimestamp__c | 日時 | 操作日時 |
| ステータス | Status__c | 選択リスト | SUCCESS/FAILURE |
| エラーメッセージ | ErrorMessage__c | ロングテキスト | エラー内容 |

---

## 11. パフォーマンス目標

### 11.1 応答時間目標
| 操作 | 目標時間 | 条件 |
|------|---------|------|
| レコード検索 | 3秒以内 | 1000件以下 |
| レコード詳細取得 | 2秒以内 | - |
| レコード作成 | 2秒以内 | - |
| レコード更新 | 2秒以内 | - |
| レコード削除 | 2秒以内 | - |

### 11.2 最適化チェックリスト
- [ ] SOQL WHERE句でインデックス項目使用
- [ ] SOQL SELECT句で必要最小限の項目のみ取得
- [ ] SOQL LIMIT句で取得件数制限
- [ ] with sharing使用
- [ ] バルク化（複数レコード操作時）
- [ ] サブクエリで関連レコード取得効率化

---

## 12. 次のステップ

### Phase 2 残タスク
- Task 4: エラーハンドリング詳細設計
- Task 5: UC-1詳細設計（要望分析→施策提案）
- Task 6: UC-2詳細設計（レコードCRUD操作）
- Task 7: UC-3詳細設計（ノンコード開発ガイド）
- Task 8: ノンコード開発ガイド構成設計
- Task 9: 設計レビューと整合性確認
- Task 10: フェーズ2完了報告作成

---

## 13. 変更履歴

| 日付 | 変更者 | 変更内容 |
|-----|-------|---------|
| 2026-03-08 | AgentAI | 初版作成（Phase 2 Task 3） |
