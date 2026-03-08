# Phase 2 設計書：エラーハンドリング詳細設計

## 設計日
2026年3月8日

## 設計者
AgentAI (Phase 2 設計フェーズ)

## 参照定義
- `01_overall_architecture.md` - 全体アーキテクチャ
- `02_response_patterns.md` - 応答パターン（P-003）
- `03_crud_operations.md` - CRUD操作設計
- `18_error_stop_protocol.md` - エラー停止プロトコル

---

## 1. エラーハンドリング設計の目的

### 1.1 目標
- エラー発生時の安全な停止
- ユーザーへの分かりやすいエラー通知
- エラー原因の特定と対処法の提示
- システムエラーの適切なログ記録
- リトライによる自動復旧

### 1.2 設計方針
- **安全第一**: エラー時は推測せず停止
- **ユーザーフレンドリー**: 平易な言葉でエラー説明
- **トレーサビリティ**: 全エラーをログ記録
- **自動復旧**: 可能な場合はリトライ実行

---

## 2. エラー分類体系

### 2.1 エラー分類一覧
| エラーコード | エラータイプ | 重要度 | リトライ | 説明 |
|-----------|------------|-------|---------|------|
| E-001 | ユーザー入力エラー | Low | ✗ | 必須項目未入力、不正な値 |
| E-002 | データ検証エラー | Low | ✗ | 重複、形式不正、範囲外 |
| E-003 | データ不整合エラー | Medium | ✗ | 参照先不存在、リレーション矛盾 |
| E-004 | 権限エラー | Medium | ✗ | CRUD権限不足、FLS制限 |
| E-005 | スコープ外要求 | Low | ✗ | Apex提案、複雑フロー提案 |
| E-006 | ビジネスロジックエラー | Medium | ✗ | ビジネスルール違反 |
| E-007 | システムエラー（一時的） | High | ✓ | タイムアウト、ロック競合 |
| E-008 | システムエラー（恒久的） | High | ✗ | Governor Limits超過、内部エラー |
| E-009 | 外部エラー | High | ✓ | ネットワークエラー、外部API障害 |

---

## 3. エラータイプ別詳細設計

### 3.1 E-001: ユーザー入力エラー

#### 発生条件
- 必須項目が未入力
- 項目の値が不正な型（文字列に数値を期待など）
- 項目の値が不正な形式（メールアドレス形式不正など）

#### 検出タイミング
- レコード作成・更新前のバリデーション
- ユーザー入力受付時

#### 処理フロー
```
[エラー検出]
    ↓
[エラー詳細取得]（どの項目がエラーか）
    ↓
[P-003パターン適用]
    ↓
[再入力促進]
    ↓
[ユーザー入力待機]
```

#### 応答例
```
【エラー】必須項目未入力

レコードを作成できませんでした。

【原因】
以下の必須項目が入力されていません：
- 課題名（Name）
- ステータス（Status__c）

【対処法】
必須項目を入力してから、再度レコード作成を試してください。

もう一度、課題名とステータスを教えてください。
```

#### Apex実装イメージ
```apex
public class InputValidator {
    public static void validateRequiredFields(
        String objectApiName,
        Map<String, Object> fieldValues
    ) {
        List<String> missingFields = new List<String>();
        
        // 必須項目チェック
        List<FieldDefinition> requiredFields = [
            SELECT QualifiedApiName, Label
            FROM FieldDefinition
            WHERE EntityDefinition.QualifiedApiName = :objectApiName
                AND IsNillable = false
            LIMIT 100
        ];
        
        for (FieldDefinition field : requiredFields) {
            if (!fieldValues.containsKey(field.QualifiedApiName) ||
                fieldValues.get(field.QualifiedApiName) == null) {
                missingFields.add(field.Label + ' (' + field.QualifiedApiName + ')');
            }
        }
        
        if (!missingFields.isEmpty()) {
            throw new InputValidationException(
                'E-001',
                '必須項目未入力',
                missingFields
            );
        }
    }
}
```

---

### 3.2 E-002: データ検証エラー

#### 発生条件
- 重複レコード検出
- ユニーク制約違反
- 値の範囲外（数値の最大・最小値超過）
- 日付の論理的矛盾（終了日 < 開始日）

#### 検出タイミング
- レコード作成・更新前のバリデーション
- DML実行時

#### 処理フロー
```
[エラー検出]
    ↓
[エラー詳細取得]（重複レコード情報、制約条件など）
    ↓
[P-003パターン適用]
    ↓
[代替案提示]（既存レコード確認、別名で作成など）
    ↓
[ユーザー選択待機]
```

#### 応答例
```
【エラー】重複レコード検出

レコードを作成できませんでした。

【原因】
同じ名前のレコードがすでに存在します：
- レコード名: 売上レポートの改善
- レコードID: a0X1234567890
- 作成日: 2026年3月1日

【対処法】
以下のいずれかを選択してください：
1. 既存レコードを確認する
2. 別の名前でレコードを作成する（例: 売上レポートの改善_v2）
3. 既存レコードを更新する

どうしますか？
```

#### Apex実装イメージ
```apex
public class DuplicateChecker {
    public static void checkDuplicate(
        String objectApiName,
        String recordName
    ) {
        String soql = 'SELECT Id, Name, CreatedDate FROM ' + 
                      objectApiName + 
                      ' WHERE Name = :recordName LIMIT 1';
        List<SObject> existingRecords = Database.query(soql);
        
        if (!existingRecords.isEmpty()) {
            throw new DataValidationException(
                'E-002',
                '重複レコード検出',
                existingRecords[0]
            );
        }
    }
}
```

---

### 3.3 E-003: データ不整合エラー

#### 発生条件
- 参照先レコードが存在しない
- リレーション先レコードが削除済み
- 親子関係の矛盾
- 循環参照

#### 検出タイミング
- レコード作成・更新前のバリデーション
- リレーション作成時

#### 処理フロー
```
[エラー検出]
    ↓
[不整合内容の特定]
    ↓
[P-003パターン適用]
    ↓
[修正方法提示]
    ↓
[ユーザー判断待機]
```

#### 応答例
```
【エラー】参照先レコードが存在しません

リレーションを作成できませんでした。

【原因】
指定されたレコードが見つかりません：
- オブジェクト: 課題・要望（Issue__c）
- レコードID: a0X9999999999

このレコードは削除されたか、アクセス権限がない可能性があります。

【対処法】
1. レコードIDが正しいか確認してください
2. レコードが削除されていないか確認してください
3. レコードへのアクセス権限があるか確認してください

どうしますか？
```

---

### 3.4 E-004: 権限エラー

#### 発生条件
- オブジェクトのCRUD権限不足
- 項目レベルセキュリティ（FLS）制限
- レコードレベルの共有設定による制限

#### 検出タイミング
- SOQL実行時（`with sharing`により検出）
- DML実行時

#### 処理フロー
```
[エラー検出]
    ↓
[権限不足の詳細特定]
    ↓
[P-003パターン適用]
    ↓
[管理者連絡促進]
    ↓
[処理終了]
```

#### 応答例
```
【エラー】権限不足

レコードを削除できませんでした。

【原因】
このオブジェクト（課題・要望）のレコード削除権限がありません。

【対処法】
レコード削除が必要な場合は、Salesforce管理者に以下を依頼してください：
- オブジェクト: 課題・要望（Issue__c）
- 必要な権限: 削除権限

管理者に連絡しますか？または別の操作を行いますか？
```

#### Apex実装イメージ
```apex
public with sharing class PermissionChecker {
    public static void checkCRUDPermission(
        String objectApiName,
        String operation  // 'create', 'read', 'update', 'delete'
    ) {
        Schema.DescribeSObjectResult describe = 
            Schema.getGlobalDescribe().get(objectApiName).getDescribe();
        
        Boolean hasPermission = false;
        switch on operation {
            when 'create' { hasPermission = describe.isCreateable(); }
            when 'read' { hasPermission = describe.isAccessible(); }
            when 'update' { hasPermission = describe.isUpdateable(); }
            when 'delete' { hasPermission = describe.isDeletable(); }
        }
        
        if (!hasPermission) {
            throw new PermissionException(
                'E-004',
                '権限不足',
                objectApiName,
                operation
            );
        }
    }
}
```

---

### 3.5 E-005: スコープ外要求

#### 発生条件
- ユーザーがApex/LWC実装を依頼
- ユーザーが複雑フロー（承認、外部連携等）を依頼
- ユーザーがシステム管理機能を依頼

#### 検出タイミング
- ユーザー入力分析時
- Agent意図理解時

#### 処理フロー
```
[スコープ外判定]
    ↓
[P-005パターン適用]
    ↓
[代替案提示]（ノンコード/ローコード手法）
    ↓
[ユーザー対話継続]
```

#### 応答例
```
【スコープ外】Apexクラスの作成

申し訳ございませんが、Apexクラスの作成や実装方法の提示は、私のサポート範囲外となっております。

【代替案】
ご要望の内容によっては、ノンコード開発の方法で実現できる可能性があります。

具体的に実現したいことを教えていただけますか？
例えば：
- どのような処理を自動化したいですか？
- どのタイミングで処理を実行したいですか？
- どのデータを操作したいですか？

これらの情報をもとに、画面フローやレコードトリガーフローでの実現方法をご提案できます。

他にお手伝いできることはありますか？
```

---

### 3.6 E-006: ビジネスロジックエラー

#### 発生条件
- ビジネスルール違反（例: ステータス遷移が不正）
- 業務フロー違反（例: 承認前レコードの更新）
- データ整合性違反（例: 親レコードなしで子レコード作成）

#### 検出タイミング
- ビジネスロジック実行時
- トリガー実行時

#### 処理フロー
```
[エラー検出]
    ↓
[ビジネスルール違反内容特定]
    ↓
[P-003パターン適用]
    ↓
[正しい手順提示]
    ↓
[ユーザー対話継続]
```

#### 応答例
```
【エラー】ステータス遷移が不正です

レコードを更新できませんでした。

【原因】
ステータスを「DONE（完了）」から「TODO（未着手）」に戻すことはできません。

現在のステータス: DONE（完了）
指定されたステータス: TODO（未着手）

【対処法】
完了したレコードを再度未着手に戻す場合は、以下のいずれかを行ってください：
1. 新しいレコードを作成する
2. ステータスを「PENDING（保留）」に変更する

どうしますか？
```

---

### 3.7 E-007: システムエラー（一時的）

#### 発生条件
- タイムアウト（SOQL/DML）
- ロック競合（`UNABLE_TO_LOCK_ROW`）
- ネットワーク一時的障害

#### 検出タイミング
- SOQL/DML実行時
- 外部API呼び出し時

#### 処理フロー
```
[エラー検出]
    ↓
[エラータイプ判定]（リトライ可能か）
    ↓
[リトライ実行]（最大3回、指数バックオフ）
    ↓
├─ [成功] → 処理継続
└─ [失敗] → [P-003パターン適用] → [ユーザー通知] → [ログ記録]
```

#### リトライ戦略
| リトライ回数 | 待機時間 | 累積時間 |
|-----------|---------|---------|
| 1回目 | 1秒 | 1秒 |
| 2回目 | 2秒 | 3秒 |
| 3回目 | 4秒 | 7秒 |

#### 応答例（リトライ失敗時）
```
【エラー】システムエラー

処理を完了できませんでした。

【原因】
一時的なシステムエラーが発生しました。
（エラーコード: UNABLE_TO_LOCK_ROW）

3回リトライしましたが、エラーが解消されませんでした。

【対処法】
しばらく待ってから、もう一度お試しください。

数分待っても解決しない場合は、Salesforce管理者に連絡してください。

もう一度試しますか？
```

#### Apex実装イメージ
```apex
public class RetryHandler {
    private static final Integer MAX_RETRY = 3;
    private static final Integer[] RETRY_DELAYS = new Integer[]{1000, 2000, 4000};
    
    public static Object executeWithRetry(RetryableOperation operation) {
        Integer retryCount = 0;
        Exception lastException;
        
        while (retryCount <= MAX_RETRY) {
            try {
                return operation.execute();
            } catch (Exception e) {
                lastException = e;
                
                if (!isRetryable(e) || retryCount == MAX_RETRY) {
                    throw new SystemException('E-007', 'リトライ失敗', e);
                }
                
                // 待機
                Long startTime = System.currentTimeMillis();
                while (System.currentTimeMillis() - startTime < RETRY_DELAYS[retryCount]) {
                    // 待機処理
                }
                
                retryCount++;
            }
        }
        
        throw lastException;
    }
    
    private static Boolean isRetryable(Exception e) {
        String message = e.getMessage();
        return message.contains('UNABLE_TO_LOCK_ROW') ||
               message.contains('Timeout') ||
               message.contains('Network');
    }
}

public interface RetryableOperation {
    Object execute();
}
```

---

### 3.8 E-008: システムエラー（恒久的）

#### 発生条件
- Governor Limits超過（SOQL数、DML数、CPU時間など）
- Apex内部エラー
- 設定エラー

#### 検出タイミング
- Apex実行時

#### 処理フロー
```
[エラー検出]
    ↓
[エラー詳細取得]
    ↓
[ログ記録]（詳細情報）
    ↓
[P-003パターン適用]
    ↓
[管理者連絡促進]
    ↓
[処理終了]
```

#### 応答例
```
【エラー】システムエラー

申し訳ございません。システムエラーが発生しました。

【原因】
システムの処理制限に到達しました。
（エラーコード: SOQL_LIMIT_EXCEEDED）

【対処法】
このエラーはシステム設定の問題です。
Salesforce管理者に以下の情報を伝えてください：

- エラーコード: SOQL_LIMIT_EXCEEDED
- 発生日時: 2026年3月8日 14:30:00
- エラーID: ERR-20260308-143000-001

管理者に連絡しますか？
```

---

### 3.9 E-009: 外部エラー

#### 発生条件
- 外部API呼び出し失敗（Phase 3以降で該当する場合）
- ネットワークエラー

#### 検出タイミング
- 外部API呼び出し時

#### 処理フロー
```
[エラー検出]
    ↓
[リトライ実行]（最大3回）
    ↓
├─ [成功] → 処理継続
└─ [失敗] → [P-003パターン適用] → [ユーザー通知] → [ログ記録]
```

---

## 4. エラーログ設計

### 4.1 ログオブジェクト
Phase 3で作成予定: `Agent_Error_Log__c`

### 4.2 ログ項目
| 項目名 | API名 | 型 | 説明 |
|-------|-------|---|------|
| ログID | Name | 自動採番 | ログ識別子 |
| エラーコード | ErrorCode__c | テキスト | E-001～E-009 |
| エラータイプ | ErrorType__c | 選択リスト | エラー分類 |
| ユーザーID | UserId__c | 参照(User) | エラー発生ユーザー |
| 対象オブジェクト | TargetObject__c | テキスト | オブジェクトAPI名 |
| 対象レコードID | TargetRecordId__c | テキスト | レコードID |
| エラーメッセージ | ErrorMessage__c | ロングテキスト | エラー内容 |
| スタックトレース | StackTrace__c | ロングテキスト | エラー詳細 |
| タイムスタンプ | ErrorTimestamp__c | 日時 | エラー発生日時 |
| リトライ回数 | RetryCount__c | 数値 | リトライした回数 |
| 解決ステータス | ResolutionStatus__c | 選択リスト | 未解決/解決済み/対応中 |

### 4.3 ログ記録タイミング
| エラータイプ | 記録タイミング |
|------------|--------------|
| E-001～E-006 | エラー発生時即座に記録 |
| E-007 | リトライ失敗時に記録 |
| E-008 | エラー発生時即座に記録（高優先度） |
| E-009 | リトライ失敗時に記録 |

### 4.4 ログ保持期間
- 標準: 90日間
- 重要エラー（E-007, E-008, E-009）: 1年間

---

## 5. エラー通知設計

### 5.1 通知方法
| エラータイプ | ユーザー通知 | 管理者通知 |
|------------|-----------|----------|
| E-001～E-003 | チャット応答 | なし |
| E-004 | チャット応答 | なし |
| E-005 | チャット応答 | なし |
| E-006 | チャット応答 | なし |
| E-007 | チャット応答 | メール（連続発生時） |
| E-008 | チャット応答 | メール（即座） |
| E-009 | チャット応答 | メール（連続発生時） |

### 5.2 管理者通知メールフォーマット
```
件名: [Agentforce] システムエラー発生通知

本文:
Agentforceでシステムエラーが発生しました。

【エラー情報】
- エラーコード: E-008
- エラータイプ: システムエラー（恒久的）
- エラーメッセージ: SOQL_LIMIT_EXCEEDED
- 発生日時: 2026年3月8日 14:30:00
- ユーザー: 山田太郎
- エラーID: ERR-20260308-143000-001

【対応】
Agent_Error_Log__cレコードを確認し、必要な対応を行ってください。

レコードURL: https://...
```

---

## 6. エラーハンドリングフロー統合図

### 6.1 全体フロー
```
[処理実行]
    ↓
[エラー発生？]
    ↓（Yes）
[エラータイプ判定]
    ↓
├─ [E-001～E-006] → [P-003適用] → [ログ記録] → [ユーザー応答]
├─ [E-007] → [リトライ実行]
│               ↓（成功）
│             [処理継続]
│               ↓（失敗）
│             [P-003適用] → [ログ記録] → [管理者通知] → [ユーザー応答]
├─ [E-008] → [ログ記録] → [P-003適用] → [管理者通知] → [ユーザー応答]
└─ [E-009] → [リトライ実行] → （E-007と同様）
```

---

## 7. カスタム例外クラス設計

### 7.1 基底例外クラス
```apex
public virtual class AgentException extends Exception {
    public String errorCode { get; set; }
    public String errorType { get; set; }
    public Map<String, Object> additionalInfo { get; set; }
    
    public AgentException(String code, String type, String message) {
        this(message);
        this.errorCode = code;
        this.errorType = type;
        this.additionalInfo = new Map<String, Object>();
    }
    
    public void addInfo(String key, Object value) {
        this.additionalInfo.put(key, value);
    }
}
```

### 7.2 個別例外クラス
```apex
public class InputValidationException extends AgentException {
    public InputValidationException(
        String code,
        String type,
        List<String> missingFields
    ) {
        super(code, type, '必須項目未入力');
        this.addInfo('missingFields', missingFields);
    }
}

public class DataValidationException extends AgentException {
    public DataValidationException(
        String code,
        String type,
        SObject duplicateRecord
    ) {
        super(code, type, '重複レコード検出');
        this.addInfo('duplicateRecord', duplicateRecord);
    }
}

public class PermissionException extends AgentException {
    public PermissionException(
        String code,
        String type,
        String objectName,
        String operation
    ) {
        super(code, type, '権限不足');
        this.addInfo('objectName', objectName);
        this.addInfo('operation', operation);
    }
}

public class SystemException extends AgentException {
    public SystemException(String code, String type, Exception innerException) {
        super(code, type, innerException.getMessage());
        this.addInfo('stackTrace', innerException.getStackTraceString());
    }
}
```

---

## 8. エラーハンドリングベストプラクティス

### 8.1 実装ガイドライン
1. **try-catchの適切な使用**
   - 予測可能なエラーはtry-catchで捕捉
   - 予測不可能なエラーは上位にスロー

2. **with sharingの徹底**
   - 全てのApexクラスで`with sharing`を使用
   - 権限チェックを自動化

3. **ログ記録の徹底**
   - 全てのエラーをログ記録
   - スタックトレースを含める

4. **ユーザーフレンドリーなメッセージ**
   - 技術的詳細はログに記録
   - ユーザーには平易な言葉で説明

5. **リトライの適切な使用**
   - 一時的エラーのみリトライ
   - リトライ回数と間隔を適切に設定

---

## 9. テスト戦略

### 9.1 テストケース
| テストID | テスト内容 | 期待結果 |
|---------|----------|---------|
| ET-001 | 必須項目未入力でレコード作成 | E-001エラー、再入力促進 |
| ET-002 | 重複レコード作成 | E-002エラー、代替案提示 |
| ET-003 | 存在しないレコードへの参照 | E-003エラー、原因説明 |
| ET-004 | 権限なしでレコード削除 | E-004エラー、権限説明 |
| ET-005 | Apex実装依頼 | E-005エラー、代替案提示 |
| ET-006 | 不正なステータス遷移 | E-006エラー、正しい手順提示 |
| ET-007 | ロック競合発生 | E-007エラー、リトライ実行 |
| ET-008 | Governor Limits超過 | E-008エラー、ログ記録、管理者通知 |

### 9.2 テストデータ
- 必須項目を持つテストオブジェクト
- 重複チェック用の既存レコード
- 権限のないテストユーザー

---

## 10. 次のステップ

### Phase 2 残タスク
- Task 5: UC-1詳細設計（要望分析→施策提案）
- Task 6: UC-2詳細設計（レコードCRUD操作）
- Task 7: UC-3詳細設計（ノンコード開発ガイド）
- Task 8: ノンコード開発ガイド構成設計
- Task 9: 設計レビューと整合性確認
- Task 10: フェーズ2完了報告作成

---

## 11. 変更履歴

| 日付 | 変更者 | 変更内容 |
|-----|-------|---------|
| 2026-03-08 | AgentAI | 初版作成（Phase 2 Task 4） |
