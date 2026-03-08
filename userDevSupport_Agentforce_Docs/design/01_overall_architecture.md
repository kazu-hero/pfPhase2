# Phase 2 設計書：全体アーキテクチャ

## 設計日
2026年3月8日

## 設計者
AgentAI (Phase 2 設計フェーズ)

## 参照定義
- `02_solution_definition.md` - スコープと制約の正
- `05_requirement_definition.md` - 要件定義
- `04_existing_data_model.md` - データモデル定義

---

## 1. システム概要

### 1.1 目的
Salesforceノンコード開発をサポートするAgentforceカスタムエージェントを構築し、開発知識のないユーザーが以下を実行できるようにする：
1. 要望・課題の分析と構造化
2. 施策案の作成と要件定義サポート
3. レコードCRUD操作（「開発App」オブジェクト群）
4. ノンコード開発ガイドの提供

### 1.2 スコープ制約
- **ユーザー向け回答**: ノンコード/ローコード案のみ提示
- **Agent内部実装**: Apex/LWC利用可（ユーザー確認後）
- **禁止事項**: ユーザー回答でのApex/LWC提案、複雑フロー提案

---

## 2. システム構成図

```
┌─────────────────────────────────────────────────────────────┐
│                      ユーザー（UI）                          │
│         Salesforce UI / Agentforce Chat Interface           │
└─────────────────────────────────────────────────────────────┘
                              ↕
┌─────────────────────────────────────────────────────────────┐
│               Agentforce Custom Agent Layer                 │
│  ┌───────────────────────────────────────────────────────┐  │
│  │  Topics（トピック分類）                               │  │
│  │  - 要望分析・施策提案                                 │  │
│  │  - レコードCRUD操作                                   │  │
│  │  - ノンコード開発ガイド                               │  │
│  │  - システム情報・ヘルプ                               │  │
│  └───────────────────────────────────────────────────────┘  │
│  ┌───────────────────────────────────────────────────────┐  │
│  │  Actions（実行可能操作）                              │  │
│  │  - レコード検索（SOQL実行）                           │  │
│  │  - レコード作成・更新・削除                           │  │
│  │  - リレーション作成                                   │  │
│  │  - ガイド資料取得                                     │  │
│  └───────────────────────────────────────────────────────┘  │
│  ┌───────────────────────────────────────────────────────┐  │
│  │  Knowledge Base（参照知識）                           │  │
│  │  - データモデル定義（04_existing_data_model.md）      │  │
│  │  - ノンコード開発ガイド                               │  │
│  │  - ベストプラクティス                                 │  │
│  │  - スコープ制約（02_solution_definition.md）          │  │
│  └───────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                              ↕
┌─────────────────────────────────────────────────────────────┐
│                   Business Logic Layer                      │
│  ┌───────────────────────────────────────────────────────┐  │
│  │  Apex Controllers（Agent内部処理）                    │  │
│  │  - AgentRecordController.cls（レコードCRUD）          │  │
│  │  - AgentRelationController.cls（リレーション管理）    │  │
│  │  - AgentGuideController.cls（ガイド取得）             │  │
│  └───────────────────────────────────────────────────────┘  │
│  ┌───────────────────────────────────────────────────────┐  │
│  │  Service Classes（ビジネスロジック）                  │  │
│  │  - RecordSearchService.cls（SOQL最適化）              │  │
│  │  - RelationCreationService.cls（リレーション作成）    │  │
│  │  - ErrorHandlingService.cls（エラー処理）             │  │
│  └───────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                              ↕
┌─────────────────────────────────────────────────────────────┐
│                      Data Layer                             │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐        │
│  │Dev_Service  │  │   Issue     │  │TechAction   │        │
│  │    __c      │  │    __c      │  │  Plan__c    │        │
│  └─────────────┘  └─────────────┘  └─────────────┘        │
│  ┌─────────────┐  ┌─────────────┐                          │
│  │  Function   │  │     Dev     │                          │
│  │Requirements │  │  Ticket__c  │                          │
│  └─────────────┘  └─────────────┘                          │
│  + 4 Junction Objects (Relation_*)                         │
└─────────────────────────────────────────────────────────────┘
```

---

## 3. 技術スタック

### 3.1 プラットフォーム
| コンポーネント | 技術 | 用途 |
|-------------|------|------|
| Agent Platform | Salesforce Agentforce | カスタムエージェント実行環境 |
| UI | Agentforce Chat Interface | ユーザー対話インターフェイス |
| Data Store | Salesforce Custom Objects | データ永続化 |

### 3.2 開発技術
| 技術 | 用途 | 利用範囲 |
|------|------|---------|
| Agentforce Agent Spec | Agent定義 | Topics/Actions/Knowledge設定 |
| SOQL | データ検索 | レコード検索・フィルタリング |
| Apex | ビジネスロジック | Agent内部処理（ユーザー確認後） |
| LWC | UI拡張 | Agent内部処理（ユーザー確認後、必要時のみ） |
| 宣言的開発ツール | 設定 | オブジェクト、項目、レイアウト、フロー |

### 3.3 技術制約
- **許可**: SOQL、宣言的開発、Apex/LWC（Agent内部処理、ユーザー確認後）
- **禁止**: ユーザー回答でのApex/LWC提案、複雑フロー提案、Visualforce、External Services

---

## 4. Agentforce構成設計

### 4.1 Agent定義
- **Agent名**: UserDevSupportAgent
- **説明**: Salesforceノンコード開発をサポートするエージェント
- **対象ユーザー**: 開発知識のない社内ユーザー（ITリテラシー: Excel操作程度）
- **対話言語**: 日本語

### 4.2 Topics（トピック分類）

#### Topic 1: 要望分析・施策提案 (Requirement Analysis Support)
- **目的**: ユーザー要望を受付、分析、構造化し、施策案を提案
- **対象オブジェクト**: Dev_Service__c、Issue__c、TechActionPlan__c
- **主要Actions**:
  - ユーザー要望の受付と構造化
  - Dev_Service__c レコード作成
  - Issue__c レコード作成とリレーション設定
  - 施策案の提案と FunctionRequirements__c 作成

#### Topic 2: レコードCRUD操作 (Record Data Management)
- **目的**: レコードの検索、参照、作成、更新、削除
- **対象オブジェクト**: 「開発App」カスタムオブジェクト全般
- **主要Actions**:
  - レコード検索（SOQL実行） ← EmployeeCopilot__QueryRecords
  - レコード詳細表示
  - レコード作成（必須項目確認） ← EmployeeCopilot__ExtractFieldsAndValuesFromUserInput, EmployeeCopilot__UpdateRecordFields
  - レコード更新（影響確認） ← EmployeeCopilot__UpdateRecordFields
  - レコード削除（警告表示）

#### Topic 3: ノンコード開発ガイダンス (Non Code Development Guidance)
- **目的**: ノンコード開発の全般的な手順とベストプラクティスを提供
- **対象**: オブジェクト、項目、レイアウト、レコードタイプ、簡易フロー
- **主要Actions**:
  - ノンコード開発ガイド全般提供
  - 複数分野にわたるアドバイス提供
  - 関連リソース（Knowledge）参照 ← AdminCopilot__AnswerQuestionsWithSalesforceDocumentation

#### Topic 4: カスタムオブジェクト設定 (Custom Object Setup)
- **目的**: カスタムオブジェクト・カスタム項目の設計・設定を専門にサポート
- **対象**: 「開発App」オブジェクト群のオブジェクト・項目設計
- **主要Actions**:
  - オブジェクト名・APIネーム特定 ← schema_ai__IdentifyObjectByName
  - フィールド名・型判定 ← schema_ai__IdentifyFieldByName
  - オブジェクト設計ガイド提供
  - 項目設定ガイド提供
  - リレーションシップ設定ガイド提供

#### Topic 5: 検証ルール支援 (Validation Rule Assistance)
- **目的**: Salesforce検証ルール（Validation Rule）の設定をサポート
- **対象**: 「開発App」オブジェクト群の検証ルール定義
- **主要Actions**:
  - 検証ルール設計ガイド提供
  - ルール構文チェック支援
  - エラーメッセージ設計ガイド提供
  - リレーション検証のベストプラクティス提供

#### Topic 4 (後続)</u: システム情報・ヘルプ (未実装)
- **目的**: Agent機能の説明、スコープ確認、ヘルプ提供
- **ステータス**: Phase 2.5テスト実装では未着手
- **主要Actions**:
  - Agent機能の説明
  - スコープ内/外の判定と説明
  - 使い方ガイドの提供
- **注記**: Phase 3以降での実装検討対象

### 4.3 Actions（実行可能操作）

#### Category A: レコード操作
1. **searchRecords**: レコード検索（SOQL実行）
2. **getRecordDetails**: レコード詳細取得
3. **createRecord**: レコード作成
4. **updateRecord**: レコード更新
5. **deleteRecord**: レコード削除

#### Category B: リレーション操作
1. **createRelation**: Junction Objectレコード作成
2. **getRelatedRecords**: 関連レコード取得
3. **deleteRelation**: リレーション削除

#### Category C: ガイド提供
1. **getObjectGuide**: オブジェクト設計ガイド取得
2. **getFieldGuide**: 項目設定ガイド取得
3. **getLayoutGuide**: ページレイアウトガイド取得
4. **getFlowGuide**: フロー設計ガイド取得

#### Category D: システム情報
1. **getAgentCapabilities**: Agent機能一覧取得
2. **checkScope**: スコープ内/外判定

### 4.4 Knowledge Base（参照知識）

#### Knowledge 1: データモデル定義
- **ソース**: `04_existing_data_model.md`
- **内容**: 「開発App」オブジェクト群の構造、項目、リレーション定義
- **更新頻度**: 実環境からスキーマ取得時

#### Knowledge 2: スコープ制約
- **ソース**: `02_solution_definition.md`
- **内容**: 対象範囲、非対象範囲、許可/禁止事項
- **更新頻度**: 要件変更時

#### Knowledge 3: ノンコード開発ガイド
- **ソース**: 今後作成予定（Task 8で設計）
- **内容**: オブジェクト、項目、レイアウト、フロー設計のベストプラクティス
- **更新頻度**: ガイド改善時

#### Knowledge 4: 要件定義
- **ソース**: `05_requirement_definition.md`
- **内容**: 機能要件、非機能要件、受け入れ条件
- **更新頻度**: 要件変更時

---

## 5. データフロー設計

### 5.1 基本フロー
```
[ユーザー入力]
    ↓
[Agent受信]
    ↓
[トピック判定] ← Knowledge Base参照
    ↓
[アクション選定]
    ↓
[アクション実行]
    ├─ SOQL実行（レコード検索）
    ├─ Apex呼び出し（レコード作成・更新・削除）
    └─ Knowledge Base参照（ガイド取得）
    ↓
[応答生成] ← プロンプト設計に基づく
    ↓
[ユーザーへ返答]
```

### 5.2 優先ユースケースフロー

#### UC-1: 要望分析から施策提案まで
```
[ユーザー: 要望入力]
    ↓
[Agent: 要望構造化・確認]
    ↓
[Agent: Dev_Service__c作成] ← createRecord Action
    ↓
[Agent: Issue__c作成] ← createRecord Action
    ↓
[Agent: Relation_Support2Issue__c作成] ← createRelation Action
    ↓
[Agent: 施策案提示]
    ↓
[ユーザー: 施策選択]
    ↓
[Agent: TechActionPlan__c作成] ← createRecord Action
    ↓
[Agent: Relation_Issue2Plan__c作成] ← createRelation Action
    ↓
[Agent: 機能要件サジェスト]
    ↓
[ユーザー: 要件選択]
    ↓
[Agent: FunctionRequirements__c作成] ← createRecord Action
    ↓
[Agent: Relation_Plan2Requirements__c作成] ← createRelation Action
```

#### UC-2: レコードCRUD操作
```
[ユーザー: レコード検索依頼]
    ↓
[Agent: 検索条件確認]
    ↓
[Agent: SOQL実行] ← searchRecords Action
    ↓
[Agent: 検索結果表示]
    ↓
[ユーザー: レコード選択・操作指示]
    ↓
[Agent: 操作内容確認（作成/更新/削除）]
    ↓
[Agent: レコード操作実行] ← createRecord/updateRecord/deleteRecord Action
    ↓
[Agent: 結果報告]
```

#### UC-3: ノンコード開発ガイド
```
[ユーザー: 開発質問]
    ↓
[Agent: 質問内容分析]
    ↓
[Agent: ガイド取得] ← getObjectGuide/getFieldGuide/etc. Action
    ↓
[Agent: ガイド提示（ノンコード手法のみ）]
    ↓
[ユーザー: 追加質問]
    ↓
[Agent: 詳細ガイド提示]
```

---

## 6. エラーハンドリング設計

### 6.1 エラー分類
| エラータイプ | 例 | 処理方針 |
|------------|----|----|
| ユーザー入力エラー | 必須項目未入力、不正な値 | 再入力を促す |
| データ不整合 | 重複レコード、参照先なし | 原因説明と対処法提示 |
| 権限エラー | CRUD権限不足 | 権限不足を説明、管理者へ連絡促す |
| システムエラー | Governor Limits、タイムアウト | ログ記録、リトライまたは停止 |
| スコープ外要求 | Apex提案依頼、複雑フロー依頼 | スコープ外を説明、代替案提示 |

### 6.2 エラーハンドリングフロー
```
[エラー発生]
    ↓
[エラータイプ判定]
    ↓
├─ [ユーザー入力エラー] → 再入力促進
├─ [データ不整合] → 原因説明と対処法提示
├─ [権限エラー] → 権限不足説明
├─ [システムエラー] → リトライ（最大3回）
│                      ↓（リトライ失敗）
│                    ログ記録
│                      ↓
│                    ユーザー通知（管理者へ連絡促す）
└─ [スコープ外要求] → スコープ外説明、代替案提示
```

### 6.3 リトライ戦略
- **対象**: システムエラー（タイムアウト、一時的な接続エラー）
- **最大リトライ回数**: 3回
- **リトライ間隔**: 1秒、2秒、4秒（指数バックオフ）
- **リトライ失敗時**: ログ記録後、ユーザーに管理者連絡を促す

---

## 7. 応答パターン設計（概要）

### 7.1 応答の基本原則
1. **平易な言葉**: 専門用語を避け、業務寄りの表現を使用
2. **段階的提示**: 複雑な手順はステップバイステップで説明
3. **確認プロセス**: データ変更前に必ず確認を取る
4. **ノンコード優先**: 実装提案はノンコード手法を第一候補とする

### 7.2 応答テンプレート（詳細はTask 2で設計）
- ユーザー確認パターン
- データ提示パターン
- エラー通知パターン
- ガイド提示パターン

---

## 8. パフォーマンス設計

### 8.1 SOQL最適化方針（詳細はTask 3で設計）
- WHERE句による絞り込み
- LIMIT句の使用（検索結果上限: 1000件）
- インデックス活用（カスタムインデックス検討）
- バッチサイズ制御

### 8.2 応答時間目標
- 通常操作: 5秒以内
- レコード検索（1000件以下）: 3秒以内
- レコード作成・更新: 2秒以内

---

## 9. セキュリティ設計

### 9.1 権限制御
- ユーザーのCRUD権限範囲内でのみ操作を許可
- 権限チェック: Apex内で `with sharing` を使用
- 権限不足時は明確にエラー通知

### 9.2 操作ログ
- 全てのレコード変更操作をログ記録
- ログ項目: ユーザーID、操作タイプ、対象オブジェクト、対象レコードID、タイムスタンプ
- ログ保存先: カスタムオブジェクト `Agent_Operation_Log__c`（Phase 3で作成）

### 9.3 データ削除保護
- データ削除前に必ず確認プロンプト表示
- 関連レコードへの影響を警告
- 削除履歴をログ記録

---

## 10. 拡張性設計

### 10.1 新規トピック追加
- Agent Specに新規トピック定義を追加
- 関連Actionsを追加
- Knowledge Baseに必要な知識を追加

### 10.2 新規オブジェクト対応
- `04_existing_data_model.md` にオブジェクト定義を追加
- 必要に応じてApex Controllerを追加
- Agent ActionsにCRUD操作を追加

### 10.3 ガイド拡充
- Knowledge Baseに新規ガイドを追加
- 既存ガイドの改善・更新

---

## 11. 運用設計

### 11.1 データモデル同期
- 定期的に実環境からスキーマをエクスポート（`npm run schema:export`）
- `04_existing_data_model.md` を更新
- Agent Knowledge Baseを再同期

### 11.2 モニタリング
- Agent応答時間の監視
- エラー発生率の監視
- ユーザーフィードバックの収集

### 11.3 改善サイクル
- ユーザーフィードバックに基づくガイド改善
- 応答パターンの最適化
- Knowledge Baseの拡充

---

## 12. 次のステップ

### Phase 2 残タスク
- Task 2: Agent応答パターン標準化の設計
- Task 3: CRUD操作設計（SOQL検索最適化）
- Task 4: エラーハンドリング詳細設計
- Task 5: UC-1詳細設計（要望分析→施策提案）
- Task 6: UC-2詳細設計（レコードCRUD操作）
- Task 7: UC-3詳細設計（ノンコード開発ガイド）
- Task 8: ノンコード開発ガイド構成設計
- Task 9: 設計レビューと整合性確認
- Task 10: フェーズ2完了報告作成

### Phase 3以降
- Agent Spec YAMLの作成
- Apex Controllerの実装
- Agent Actionsの実装
- Knowledge Baseの構築
- テスト実装

---

## 13. 変更履歴

| 日付 | 変更者 | 変更内容 |
|-----|-------|---------|
| 2026-03-08 | AgentAI | 初版作成（Phase 2 Task 1） |
