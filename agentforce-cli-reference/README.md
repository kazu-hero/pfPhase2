# Agentforce CLI Reference - 検索ガイド

このドキュメントは、`official-reference_Files/`配下の公式リファレンスを効率的に検索するための目次とキーワードマッピングです。

> **重要**: AIのコンテキストウィンドウ制約（約750KB）に対し、全リファレンス合計は30.3MBです。  
> **運用方針**: 必要な情報を`grep_search`で検索し、該当ファイルの必要箇所のみ読み込んでください。

## ディレクトリ構造

```
agentforce-cli-reference/
├── README.md (このファイル - 目次・検索ガイド)
├── agentforce_cli_command_coverage.md (コマンド一覧)
└── official-reference_Files/
    ├── Agent Script.md (1,953行 - Agent言語仕様)
    ├── Agentforce Actions.md (1,796行 - カスタムAction作成)
    ├── Agentforce APIs and SDKs.md (2,952行 - API統合)
    ├── Agentforce DX.md (1,080行 - CLI/VS Code開発)
    ├── Get Started.md (127行 - セットアップ)
    ├── MCP Solutions for Developers.md (31行 - MCP連携)
    └── Models and Prompts.md (1,382行 - LLMモデル・Prompt Builder)
```

---

## 📋 ファイル別詳細目次

### 1. Agent Script.md (Agent言語仕様)

**主要セクション**:
- Get Started with Agent Script
- Agent Script Language Characteristics (コンパイル、決定論、宣言型)
- Agent Script Blocks (topic, action, instruction, variable, etc.)
- Agent Script Expressions (演算子、関数、条件分岐)
- Agent Script Variables (型、スコープ、初期化)
- Agent Script Functions (built-in関数、カスタム関数)
- Agent Script Metadata (デプロイ、バージョン管理)

**検索キーワード**:
- `topic` `action` `instruction` - ブロック構文
- `if` `else` `transition` - 制御フロー
- `variable` `set` `get` - 変数操作
- `expression` `function` - 式と関数
- `metadata` `deploy` - メタデータ

**検索例**:
```
# Agent Script内でtopicブロックの書き方を調べる
grep_search "topic block" includePattern="Salesforce_DevDocs/agentforce-cli-reference/official-reference_Files/Agent Script.md" isRegexp=false

# 変数の型定義を調べる
grep_search "variable type|variable declaration" includePattern="Salesforce_DevDocs/agentforce-cli-reference/official-reference_Files/Agent Script.md" isRegexp=true
```

---

### 2. Agentforce Actions.md (カスタムAction作成)

**主要セクション**:
- Build Custom Agent Actions using Apex REST
  - Generate OpenAPI Specification (OAS)
  - Prerequisites and Requirements
- Create Actions from Apex Controller Methods (AuraEnabled)
- Create Actions from Named Query APIs (SOQL)
- Create Custom Actions Using Apex Invocable Method
- Enhance Actions with Lightning Types (カスタムLWC)
- Provide Global Copy to Action Responses
- Cite Agent Responses with Apex (引用)

**検索キーワード**:
- `Apex REST` `OpenAPI` - REST API Action
- `AuraEnabled` `@AuraEnabled` - LWC統合
- `Named Query` `SOQL` - クエリAction
- `InvocableMethod` - Apex Invocable
- `Lightning Types` `LWC` - UI拡張
- `citation` `cite` - 引用機能

**検索例**:
```
# Apex RESTからActionを作成する方法
grep_search "Generate OpenAPI|Apex REST" includePattern="Salesforce_DevDocs/agentforce-cli-reference/official-reference_Files/Agentforce Actions.md" isRegexp=true

# InvocableMethodの使い方
grep_search "@InvocableMethod|InvocableMethod" includePattern="Salesforce_DevDocs/agentforce-cli-reference/official-reference_Files/Agentforce Actions.md" isRegexp=true
```

---

### 3. Agentforce APIs and SDKs.md (API統合)

**主要セクション**:
- Get Started with Agentforce APIs and SDKs
- Agent API Developer Guide
  - Get Started with the Agent API
  - Agent API Resources (sessions, messages, external messages)
  - Agent API Capabilities (file uploads, streaming)
- Testing API
  - Build Tests
  - Custom Evaluation Criteria
  - Run Tests
- Agentforce Mobile SDK (iOS/Android)
- Enhanced Chat v2 (Web Chat)
- Enhanced In-App Chat SDK
- Agentforce Python SDK

**検索キーワード**:
- `Agent API` `session` `message` - チャットAPI
- `Testing API` `test` `evaluation` - テストAPI
- `Mobile SDK` `iOS` `Android` - モバイル統合
- `Enhanced Chat` `web chat` - Web Chat
- `Python SDK` - Python統合
- `streaming` `SSE` - ストリーミング
- `file upload` - ファイルアップロード

**検索例**:
```
# Agent APIでセッション開始する方法
grep_search "create session|start session" includePattern="Salesforce_DevDocs/agentforce-cli-reference/official-reference_Files/Agentforce APIs and SDKs.md" isRegexp=true

# Testing APIでカスタム評価基準を設定
grep_search "custom evaluation|evaluation criteria" includePattern="Salesforce_DevDocs/agentforce-cli-reference/official-reference_Files/Agentforce APIs and SDKs.md" isRegexp=true
```

---

### 4. Agentforce DX.md (CLI/VS Code開発)

**主要セクション**:
- Set Up Your Development Environment
  - Install Pro-Code Tools (VS Code, CLI)
  - Sandbox vs Scratch Org
  - Create Salesforce DX Project
- Author an Agent with Agentforce DX
- Test Agents with Agentforce DX
  - Create Agent Test Specification (YAML)
  - Run Agent Tests
  - Custom Evaluation Functions
- Deploy Agents
- Agent Metadata: A Shallow Dive
- Salesforce CLI Commands
  - `sf agent generate` - コード生成
  - `sf agent test` - テスト実行
  - `sf org` - Org管理

**検索キーワード**:
- `sf agent generate` - コード生成
- `sf agent test` - テスト実行
- `scratch org` `sandbox` - 開発環境
- `YAML` `test specification` - テスト定義
- `deploy` `retrieve` - デプロイ
- `metadata` - メタデータ構造

**検索例**:
```
# sf agent testコマンドの使い方
grep_search "sf agent test" includePattern="Salesforce_DevDocs/agentforce-cli-reference/official-reference_Files/Agentforce DX.md" isRegexp=false

# スクラッチOrgの作成方法
grep_search "create scratch|scratch org definition" includePattern="Salesforce_DevDocs/agentforce-cli-reference/official-reference_Files/Agentforce DX.md" isRegexp=true
```

---

### 5. Get Started.md (セットアップ)

**主要セクション**:
- Set Up Einstein Generative AI and Agentforce
  - Provision Data 360
  - Turn on Einstein
  - Configure the Trust Layer
- Scratch Org Access (scratch org定義ファイル)
- Trust Layer
  - Zero Data Retention
  - Trusted Generative AI (5原則)
  - Reviewing Generative AI Outputs

**検索キーワード**:
- `setup` `provision` - セットアップ
- `Data 360` `Data Cloud` - Data 360
- `Trust Layer` `zero retention` - Trust Layer
- `scratch org` `EnableSetPasswordInApi` - スクラッチOrg
- `Einstein1AIPlatform` - 機能有効化

**検索例**:
```
# Trust Layerの設定方法
grep_search "Trust Layer|Configure the Trust" includePattern="Salesforce_DevDocs/agentforce-cli-reference/official-reference_Files/Get Started.md" isRegexp=true

# スクラッチOrg定義ファイルのサンプル
grep_search "scratch.*definition|Einstein1AIPlatform" includePattern="Salesforce_DevDocs/agentforce-cli-reference/official-reference_Files/Get Started.md" isRegexp=true
```

---

### 6. MCP Solutions for Developers.md (MCP連携)

**主要セクション**:
- Model Context Protocol (MCP) Overview
- Salesforce Solutions
  - Heroku MCP Server
  - Anypoint Connector for MCP (MuleSoft)
  - MuleSoft MCP Server
  - Salesforce DX MCP Server (Beta)
  - Agentforce Vibes Extension MCP Client
  - Salesforce Hosted MCP Servers (Beta)

**検索キーワード**:
- `MCP` `Model Context Protocol` - MCP全般
- `Heroku MCP` - Heroku連携
- `MuleSoft MCP` `Anypoint` - MuleSoft連携
- `Salesforce DX MCP` - SFDX MCP
- `Vibes Extension` - VS Code拡張

**検索例**:
```
# Salesforce DX MCP Serverの使い方
grep_search "Salesforce DX MCP|SFDX MCP" includePattern="Salesforce_DevDocs/agentforce-cli-reference/official-reference_Files/MCP Solutions for Developers.md" isRegexp=true
```

---

### 7. Models and Prompts.md (LLMモデル・Prompt Builder)

**主要セクション**:
- Get Started with Models and Prompts
  - Configure Your Models (Einstein Studio)
  - Use Models API
  - Design and Run Prompt Templates (Prompt Builder)
- Supported Models
  - Salesforce-Managed Models (モデル一覧とAPI名)
  - Bring Your Own LLM (BYOLLM)
  - LLM Open Connector
  - Model Criteria (ベンチマーク、コンテキストウィンドウ)
  - Geo-aware Models
- Prompt Builder
  - Create Prompt Templates
  - Merge Fields and Variables
  - Test Prompts
- Models API
  - Generate Text
  - Generate Conversations
  - Generate Embeddings
  - Toxicity Detection
  - Data Masking

**検索キーワード**:
- `Models API` `generate text` - テキスト生成
- `Prompt Builder` `prompt template` - Prompt Builder
- `sfdc_ai__` - モデルAPI名
- `GPT` `Claude` `Gemini` `Bedrock` - モデル名
- `BYOLLM` `bring your own` - 外部モデル
- `embedding` `vector` - 埋め込みベクトル
- `toxicity` `data masking` - セキュリティ
- `merge field` - マージフィールド

**検索例**:
```
# 利用可能なモデル一覧とAPI名を調べる
grep_search "sfdc_ai__|Model.*API Name" includePattern="Salesforce_DevDocs/agentforce-cli-reference/official-reference_Files/Models and Prompts.md" isRegexp=true

# Models APIでテキスト生成する方法
grep_search "generate text|Models API.*Apex|Models API.*REST" includePattern="Salesforce_DevDocs/agentforce-cli-reference/official-reference_Files/Models and Prompts.md" isRegexp=true

# Prompt Builderでマージフィールドを使う
grep_search "merge field|Prompt Builder.*variable" includePattern="Salesforce_DevDocs/agentforce-cli-reference/official-reference_Files/Models and Prompts.md" isRegexp=true
```

---

## 🔍 タスク別検索ガイド

### Agent開発

**1. Agent Script作成**
```
# まず agentforce_cli_command_coverage.md でコマンド確認
grep_search "sf agent" includePattern="Salesforce_DevDocs/agentforce-cli-reference/agentforce_cli_command_coverage.md" isRegexp=false

# Agent Scriptの基本構文
grep_search "topic|action|instruction" includePattern="Salesforce_DevDocs/agentforce-cli-reference/official-reference_Files/Agent Script.md" isRegexp=true
```

**2. カスタムAction作成**
```
# Apex RESTからAction作成
grep_search "Apex REST|OpenAPI" includePattern="Salesforce_DevDocs/agentforce-cli-reference/official-reference_Files/Agentforce Actions.md" isRegexp=true

# InvocableMethodでAction作成
grep_search "InvocableMethod" includePattern="Salesforce_DevDocs/agentforce-cli-reference/official-reference_Files/Agentforce Actions.md" isRegexp=false
```

**3. Agentのデプロイ**
```
grep_search "deploy|retrieve|metadata" includePattern="Salesforce_DevDocs/agentforce-cli-reference/official-reference_Files/Agentforce DX.md" isRegexp=true
```

### Agent テスト

**1. テスト定義作成**
```
# YAML形式のテスト定義
grep_search "test specification|YAML" includePattern="Salesforce_DevDocs/agentforce-cli-reference/official-reference_Files/Agentforce DX.md" isRegexp=true

# カスタム評価関数
grep_search "custom evaluation|evaluation function" includePattern="Salesforce_DevDocs/agentforce-cli-reference/official-reference_Files/Agentforce APIs and SDKs.md" isRegexp=true
```

**2. テスト実行**
```
grep_search "sf agent test run" includePattern="Salesforce_DevDocs/agentforce-cli-reference/official-reference_Files/Agentforce DX.md" isRegexp=false
```

### API統合

**1. Agent APIでチャット実装**
```
# セッション管理
grep_search "session|Agent API.*resources" includePattern="Salesforce_DevDocs/agentforce-cli-reference/official-reference_Files/Agentforce APIs and SDKs.md" isRegexp=true

# メッセージ送受信
grep_search "send message|receive message" includePattern="Salesforce_DevDocs/agentforce-cli-reference/official-reference_Files/Agentforce APIs and SDKs.md" isRegexp=true
```

**2. モバイルアプリ統合**
```
grep_search "Mobile SDK|iOS|Android" includePattern="Salesforce_DevDocs/agentforce-cli-reference/official-reference_Files/Agentforce APIs and SDKs.md" isRegexp=true
```

### Models API / Prompt Builder

**1. Models APIでテキスト生成**
```
# Apexでの利用
grep_search "Models API.*Apex|ConnectApi.EinsteinLLM" includePattern="Salesforce_DevDocs/agentforce-cli-reference/official-reference_Files/Models and Prompts.md" isRegexp=true

# RESTでの利用
grep_search "Models API.*REST|/einstein/llm" includePattern="Salesforce_DevDocs/agentforce-cli-reference/official-reference_Files/Models and Prompts.md" isRegexp=true
```

**2. 利用可能なモデル確認**
```
grep_search "sfdc_ai__|Salesforce-Managed Models" includePattern="Salesforce_DevDocs/agentforce-cli-reference/official-reference_Files/Models and Prompts.md" isRegexp=true
```

**3. Prompt Template作成**
```
grep_search "Prompt Builder|prompt template|merge field" includePattern="Salesforce_DevDocs/agentforce-cli-reference/official-reference_Files/Models and Prompts.md" isRegexp=true
```

### 開発環境セットアップ

**1. スクラッチOrg作成**
```
grep_search "scratch org|Einstein1AIPlatform" includePattern="Salesforce_DevDocs/agentforce-cli-reference/official-reference_Files/Get Started.md" isRegexp=true
```

**2. Trust Layer設定**
```
grep_search "Trust Layer|zero retention|data masking" includePattern="Salesforce_DevDocs/agentforce-cli-reference/official-reference_Files/Get Started.md" isRegexp=true
```

---

## 💡 検索のベストプラクティス

### 1. キーワード選定
- **正規表現を活用**: `grep_search "sf agent test|test run" isRegexp=true`
- **複数の表記を考慮**: `Agent API|AgentAPI|agent-api`
- **コマンド名は正確に**: `sf agent generate` (スペースも含めて検索)

### 2. includePatternの使い方
```
# 特定ファイル内を検索
includePattern="Salesforce_DevDocs/agentforce-cli-reference/official-reference_Files/Agent Script.md"

# 全ファイルから検索
includePattern="Salesforce_DevDocs/agentforce-cli-reference/official-reference_Files/**"

# コマンド一覧のみ検索
includePattern="Salesforce_DevDocs/agentforce-cli-reference/agentforce_cli_command_coverage.md"
```

### 3. 段階的絞り込み
1. **広く検索**: キーワードで全ファイルを検索
2. **ファイル特定**: 該当ファイルを絞り込み
3. **詳細検索**: 特定ファイル内でより詳細なキーワードで再検索

---

## 📚 参照リンク

- [Salesforce Agentforce公式ドキュメント](https://developer.salesforce.com/docs/ai/agentforce/)
- [Agentforce CLI Reference](https://developer.salesforce.com/docs/atlas.en-us.sfdx_cli_reference.meta/sfdx_cli_reference/cli_reference_agentforce.htm)
- [Salesforce CLI Plugin-Agent GitHub](https://github.com/salesforcecli/plugin-agent)
