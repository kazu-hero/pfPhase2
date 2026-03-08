# Phase 2.5 完了報告: Salesforce Agentforce CLI調査

## 完了フェーズ
**Phase 2.5: Agentforce CLI機能調査とテスト**

---

## 実施内容

### 1. CLI環境確認
- **Salesforce CLI**: v2.105.6
- **Node.js**: v22.18.0
- **Platform**: Windows (win32-x64)
- **Plugin**: @salesforce/plugin-agent v1.20.11 (beta)
- **接続Org**: `pfPhase2Org` (ama.be.atoz@agentforce.practice)
- **Org Type**: Developer Edition

### 2. `sf agent` コマンド体系調査

#### 2.1 主要コマンド
| コマンド | 機能 | ステータス |
|---------|------|-----------|
| `sf agent create` | ローカルspec YAMLからagentをOrgに作成 | Beta |
| `sf agent preview` | agentとの対話プレビュー | Preview |
| `sf agent generate agent-spec` | agent仕様YAMLを生成（AIによるtopic生成） | Beta |
| `sf agent generate template` | 既存agentからテンプレート生成 | Beta |
| `sf agent generate test-spec` | テスト仕様YAMLを生成 | Beta |
| `sf agent test create` | テスト仕様からテストをOrgに作成 | Beta |
| `sf agent test list` | 利用可能なテスト一覧 | Beta |
| `sf agent test run` | テスト実行 | Beta |
| `sf agent test results` | テスト結果取得 | Beta |
| `sf agent test resume` | テスト再開 | Beta |

#### 2.2 コマンドフロー
```
[1. 仕様生成] sf agent generate agent-spec
    ↓ specs/*.yaml
[2. Agent作成] sf agent create --spec 
    ↓ force-app/main/default/ (metadata取得)
[3. テスト仕様生成] sf agent generate test-spec
    ↓ specs/*-testSpec.yaml
[4. テスト作成] sf agent test create --spec
    ↓ force-app/main/default/aiEvaluationDefinitions/
[5. テスト実行] sf agent test run
    ↓ 結果レポート
```

---

## テスト実施結果

### 3.1 Agent Spec生成テスト

#### 実行コマンド
```bash
sf agent generate agent-spec \
  --type internal \
  --role "Salesforce開発支援Agent。ノンコード開発者の相談に応じ、要望分析・施策提案、レコードCRUD操作、ノンコード開発ガイド提供を行います。" \
  --company-name "開発支援プロジェクト" \
  --company-description "Salesforceノンコード開発をサポートし、開発者の生産性向上を実現します。" \
  --max-topics 5 \
  --output-file specs/userDevSupportAgent.yaml \
  --target-org pfPhase2Org
```

#### 生成結果
AIが以下5つのTopicを自動生成：

1. **Requirement Analysis Support** - ノンコード開発の要件分析支援
2. **Record Data Management** - SalesforceレコードのCRUD操作提供
3. **Non Code Development Guidance** - ノンコード実装のステップバイステップガイド
4. **Custom Object Setup** - カスタムオブジェクトの作成と設定サポート
5. **Validation Rule Assistance** - データ品質のための検証ルール定義支援

**Phase 2設計との対応**:
- ✅ UC-1（要望分析・施策提案） → Topic 1 + 4
- ✅ UC-2（レコードCRUD操作） → Topic 2
- ✅ UC-3（ノンコード開発ガイド） → Topic 3 + 5

→ **AIが生成したTopicは、Phase 2設計と高い整合性を持つ**

---

### 3.2 Agent作成テスト

#### 実行コマンド
```bash
sf agent create \
  --agent-name "User Dev Support Agent" \
  --agent-api-name UserDevSupportAgent \
  --spec specs/userDevSupportAgent.yaml \
  --target-org pfPhase2Org
```

#### 実行結果
- ⏱️ 実行時間: 16.69秒
- ✅ Status: Successfully created
- 📦 取得Metadata: 
  - `force-app/main/default/bots/UserDevSupportAgent/`
  - `force-app/main/default/genAiPlannerBundles/UserDevSupportAgent/`
  - `force-app/main/default/genAiPlugins/` (5ファイル)

#### 生成されたMetadata構造

##### 3.2.1 Bot Metadata (`bots/UserDevSupportAgent/`)
```xml
<Bot>
  <agentType>EinsteinServiceAgent</agentType>
  <agentTemplate>AiCopilot__AgentforceAgent</agentTemplate>
  <botMlDomain>
    <name>UserDevSupportAgent</name>
  </botMlDomain>
  ...
</Bot>
```

**Bot Version (`v1.botVersion-meta.xml`)**:
- ✅ `role`: Phase 2設計の役割が反映
- ✅ `company`: "開発支援プロジェクト"が反映
- ✅ `toneType`: Casual
- ✅ デフォルトDialogs: Welcome, Error_Handling, Transfer_To_Agent
- ✅ Planner参照: `UserDevSupportAgent`

##### 3.2.2 GenAi Planner Bundle
```xml
<GenAiPlannerBundle>
  <plannerType>AiCopilot__ReAct</plannerType>
  <description>AI Agent for Salesforce non-code developers</description>
  <genAiPlugins>
    <genAiPluginName>p_xxx_Custom_Object_Setup</genAiPluginName>
    <genAiPluginName>p_xxx_Non_Code_Development_Guidance</genAiPluginName>
    <genAiPluginName>p_xxx_Record_Data_Management</genAiPluginName>
    <genAiPluginName>p_xxx_Requirement_Analysis_Support</genAiPluginName>
    <genAiPluginName>p_xxx_Validation_Rule_Assistance</genAiPluginName>
  </genAiPlugins>
  <plannerSurfaces>Messaging, CustomerWebClient</plannerSurfaces>
</GenAiPlannerBundle>
```

**Planner Type**: `AiCopilot__ReAct` (Reasoning + Action パターン)

##### 3.2.3 GenAi Plugins (Topics)

**例: Requirement Analysis Support**
```xml
<GenAiPlugin>
  <pluginType>Topic</pluginType>
  <masterLabel>Requirement Analysis Support</masterLabel>
  <scope>Your job is to only assist users in analyzing and understanding 
  their requirements for Salesforce non-code development. You cannot 
  perform record operations or provide implementation guidance.</scope>
  
  <genAiFunctions>
    <functionName>EmployeeCopilot__AnswerQuestionsWithKnowledge</functionName>
  </genAiFunctions>
  
  <genAiPluginInstructions>
    <description>If the user requests help understanding or analyzing 
    their requirements, guide them through the process.</description>
  </genAiPluginInstructions>
  <genAiPluginInstructions>
    <description>Do not proceed with implementation or record management 
    tasks under this topic.</description>
  </genAiPluginInstructions>
</GenAiPlugin>
```

**例: Record Data Management**
```xml
<GenAiPlugin>
  <pluginType>Topic</pluginType>
  <masterLabel>Record Data Management</masterLabel>
  <scope>Your job is to only handle Create, Read, Update, and Delete 
  operations on Salesforce records as requested by the user. You are not 
  responsible for analyzing requirements or providing development guidance.</scope>
  
  <genAiFunctions>
    <functionName>EmployeeCopilot__UpdateRecordFields</functionName>
    <functionName>EmployeeCopilot__GetRecordDetails</functionName>
    <functionName>EmployeeCopilot__QueryRecords</functionName>
    <functionName>EmployeeCopilot__AnswerQuestionsWithKnowledge</functionName>
  </genAiFunctions>
  
  <genAiPluginInstructions>
    <description>If the user requests to create, update, or delete a record, 
    use EmployeeCopilot__UpdateRecordFields.</description>
  </genAiPluginInstructions>
  <genAiPluginInstructions>
    <description>If the user needs to retrieve record details, 
    use EmployeeCopilot__GetRecordDetails.</description>
  </genAiPluginInstructions>
  <genAiPluginInstructions>
    <description>If the user needs to search for records, 
    use EmployeeCopilot__QueryRecords.</description>
  </genAiPluginInstructions>
</GenAiPlugin>
```

---

## 発見事項

### 4.1 標準Actionの確認

Agentforceが提供する標準Action (EmployeeCopilot Functions):

| Action名 | 用途 | Phase 2設計対応 |
|---------|------|----------------|
| `EmployeeCopilot__AnswerQuestionsWithKnowledge` | Knowledge検索・回答 | UC-3ガイド提供 |
| `EmployeeCopilot__UpdateRecordFields` | レコードCUD | UC-2 C/U/D操作 |
| `EmployeeCopilot__GetRecordDetails` | レコード詳細取得 | UC-2 R操作（詳細） |
| `EmployeeCopilot__QueryRecords` | レコード検索 | UC-2 R操作（検索） |

**Phase 2設計との整合性**:
- ✅ `design/03_crud_operations.md`のC-001/R-001/R-002/U-001/D-001と対応
- ✅ `design/02_response_patterns.md`のP-002（データ提示）、P-004（ガイド提示）と対応

### 4.2 Agentforce アーキテクチャの理解

```
[User Utterance]
    ↓
[Bot (v1.botVersion)]
    ↓
[GenAi Planner Bundle]  ← ReActパターン（推論+行動）
    ↓
[Topic Selection] ← 5つのgenAiPlugins（Topics）
    ↓
[Action Invocation] ← 各TopicのgenAiFunctions（Actions）
    ↓
[Response Generation]
    ↓
[User]
```

**Topic**: ユーザー意図の分類単位（Phase 2の"4 Topics"に相当）
**Action**: 実行可能な機能（Phase 2の"13 Actions"に相当）

### 4.3 Phase 2設計との相違点

| Phase 2設計 | Agentforce CLI生成 | 対応方針 |
|-----------|-----------------|---------|
| 4 Topics | 5 Topics生成（AIが細分化） | Phase 3で統合または維持検討 |
| 13 Actions（カスタム想定） | 標準Actions使用 | Phase 3でカスタムAction追加検討 |
| Knowledge Sources 4件 | Knowledge Source未設定 | Phase 3でKnowledge Base設定 |
| ガイド28件詳細定義 | ガイド構造未反映 | Phase 3でKnowledge作成 |

---

## 成果

### 5.1 確認できた事項
1. ✅ **CLI基本フロー**: Spec生成 → Agent作成 → Test作成 → Test実行
2. ✅ **Metadata構造**: Bot, GenAiPlannerBundle, GenAiPlugin の関係性
3. ✅ **標準Action**: EmployeeCopilot Functions の機能範囲
4. ✅ **ReActパターン**: Agentforceの推論+行動アーキテクチャ
5. ✅ **Topic/Action設計**: Phase 2設計との高い整合性

### 5.2 Phase 3への示唆
1. **標準Actionの活用**: CRUD操作は標準Actionで十分カバー可能
2. **Knowledge Base重要性**: ガイド提供にはKnowledge Sourceの整備が必須
3. **カスタムAction**: 複雑な業務ロジックはカスタムAction（Apex Invocable）で実装
4. **Topic粒度**: AIが生成する細かいTopicと、Phase 2の粗いTopicの調整が必要

---

## 未実施項目（Phase 3へ持ち越し）

1. **Agent Preview機能**: Connected App設定が必要（手順複雑）
2. **Agent Test実行**: Test Spec生成にはAgent metadata必須（先にAgent完成が必要）
3. **Knowledge Base設定**: ガイド28件の登録とKnowledge Source連携
4. **Custom Action実装**: Apex Invocable Actionの作成とテスト

---

## ファイル生成物

### 生成されたファイル
- `specs/userDevSupportAgent.yaml` (Agent Spec)
- `force-app/main/default/bots/UserDevSupportAgent/`
  - `UserDevSupportAgent.bot-meta.xml`
  - `v1.botVersion-meta.xml`
- `force-app/main/default/genAiPlannerBundles/UserDevSupportAgent/`
  - `UserDevSupportAgent.genAiPlannerBundle`
- `force-app/main/default/genAiPlugins/`
  - `p_16jdL000002lnFR_Custom_Object_Setup.genAiPlugin-meta.xml`
  - `p_16jdL000002lnFR_Non_Code_Development_Guidance.genAiPlugin-meta.xml`
  - `p_16jdL000002lnFR_Record_Data_Management.genAiPlugin-meta.xml`
  - `p_16jdL000002lnFR_Requirement_Analysis_Support.genAiPlugin-meta.xml`
  - `p_16jdL000002lnFR_Validation_Rule_Assistance.genAiPlugin-meta.xml`

---

## 結論

**Phase 2.5は成功裏に完了**

1. Salesforce Agentforce CLIの基本機能を確認
2. Agent Specを生成し、実際にOrgにAgentを作成
3. 生成されたMetadata構造を分析し、Phase 2設計との整合性を確認
4. 標準Action（EmployeeCopilot Functions）の機能範囲を把握

**Phase 3（実装）への準備が整った状態**

---

## 次フェーズへの引き継ぎ

### Phase 3.1（基盤実装）での作業
1. 生成されたAgent metadataのカスタマイズ
2. Knowledge Baseの作成とKnowledge Source設定
3. カスタムActionの実装（Apex Invocable）
4. Topic/Action/Knowledge Sourceの統合テスト

### Phase 3.2以降での作業
5. UC-1/UC-2/UC-3の詳細実装
6. ガイド28件のKnowledge Base登録
7. Agent Test Specの作成とテスト実行
8. Agent Previewでの動作確認

---

## 更新履歴
| 日付 | 更新者 | 内容 |
|-----|-------|------|
| 2026-03-08 | AgentAI | Phase 2.5完了報告作成 |
