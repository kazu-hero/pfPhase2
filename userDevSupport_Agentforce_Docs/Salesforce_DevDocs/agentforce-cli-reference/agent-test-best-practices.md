# Agent Test実践ガイド - ベストプラクティス

## 📌 目的
このドキュメントは、Salesforce公式ドキュメント4点から抽出した、Agent Testingの実践的なベストプラクティスをまとめたものです。

### 参照元ドキュメント
1. Generate an Agent Test Spec
2. Customize the Agent Test Spec
3. Create an Agent Test from the Spec File
4. Run Agent Tests

### 最終更新
- 日付: 2026-03-08
- プロジェクト: pfPhase2 / UserDevSupportAgent Phase 3.1-3a
- 検証環境: @salesforce/plugin-agent 1.20.11

---

## 1️⃣ テストスペック生成の基本

### コマンド
```bash
sf agent generate test-spec --target-org {org-alias}
```

### 生成されるYAMLの基本構造
```yaml
name: Agent Test Name
description: Test description
subjectType: AGENT
subjectName: YourAgentApiName
subjectVersion: v1
testCases:
  - utterance: "ユーザーの発話"
    expectedTopic: p_xxx_Topic_Name
    expectedActions: []
    expectedOutcome: "期待される結果の説明"
    customEvaluations: []
    conversationHistory: []
    metrics: []
```

### 重要な注意点
- ❌ `agentApiName` / `masterLabel` は**使用不可**（旧スキーマ）
- ✅ `subjectName` / `subjectVersion` を使用する
- `subjectType` は `AGENT` 固定

---

## 2️⃣ テストスペックのカスタマイズオプション

### A. Metrics（品質評価指標）⭐ 重要

#### 利用可能なMetrics
```yaml
metrics:
  - coherence              # 一貫性・文法エラーなし
  - completeness           # 必要情報が全て含まれているか
  - conciseness            # 簡潔性（短い方が良い）
  - output_latency_milliseconds  # レスポンス速度
  - instruction_following  # Topic instructionへの順守度 ⭐
  - factuality             # 事実性の評価
```

#### Metricsの効果
- テスト実行時に各指標のスコアと閾値（threshold）が表示される
- `instruction_following` は **Topic選択精度の診断に直接役立つ**
- 閾値デフォルトは 0.6（60%）

#### 出力例
```text
❯ METRICS (Value/Threshold)
────────────────────────────────────────────────────────────────────────
✅ : COHERENCE (4/0.6) : The answer is easy to understand
❌ : COMPLETENESS (1/0.6) : Missing essential information
✅ : CONCISENESS (5/0.6)
❌ : INSTRUCTION FOLLOWING (0.4/0.6) : Does not follow topic instructions
⏱️ : OUTPUT LATENCY (3564ms)
```

#### 適用方法
既存のテストスペックにmetricsセクションを追加：
```yaml
testCases:
  - utterance: カスタムオブジェクト作成手順を教えて
    expectedTopic: p_16jdL000002lnH3_Custom_Object_Setup
    expectedActions: []
    expectedOutcome: G-101に沿って作成手順を案内する
    metrics:
      - instruction_following
      - coherence
      - completeness
      - output_latency_milliseconds
```

---

### B. Custom Evaluations（カスタム評価）

#### 概要
- JSONPath式を使用してエージェントの出力を詳細検証
- アクション呼び出しのパラメータや結果を検証可能

#### 基本構文
```yaml
customEvaluations:
  - label: Check for correct date
    name: string_comparison
    parameters:
      - name: operator
        value: equals
        isReference: false
      - name: actual
        value: $.generatedData.invokedActions[*][?(@.function.name == 'ActionName')].function.input.paramName
        isReference: true  # JSONPath式の場合はtrue
      - name: expected
        value: "2025-09-12"
        isReference: false
```

#### 利用可能な比較演算子
- `equals` - 等価
- `not_equals` - 非等価
- `greater_than` - より大きい
- `greater_than_or_equal` - 以上
- `less_than` - より小さい
- `less_than_or_equal` - 以下

#### JSONPath式の構築方法
1. **`--verbose`フラグでテスト実行**して生成データを取得
   ```bash
   sf agent test run --api-name TestName --verbose
   ```

2. **Generated Dataセクション**からJSONを確認
   ```json
   {
     "function": {
       "name": "Check_Weather",
       "input": {
         "dateToCheck": "2025-09-12"
       },
       "output": {}
     },
     "executionLatency": 804
   }
   ```

3. JSONPath式を作成
   ```
   $.generatedData.invokedActions[*][?(@.function.name == 'Check_Weather')].function.input.dateToCheck
   ```

#### UserDevSupportAgentへの適用例
```yaml
customEvaluations:
  - label: Verify Guide Reference
    name: string_comparison
    parameters:
      - name: actual
        value: $.generatedData.knowledgeReferences[*].title
        isReference: true
      - name: operator
        value: contains
        isReference: false
      - name: expected
        value: "G-101"
        isReference: false
```

---

### C. Context Variables（Service Agent用）

#### 概要
- Service Agentでメッセージングチャネルを使用する場合に有効
- MessagingSessionオブジェクトのフィールドをテストコンテキストとして設定

#### 構文
```yaml
contextVariables:
  - name: EndUserLanguage
    value: Spanish
  - name: EndUserFirstName
    value: Jun
```

#### API名の確認方法
- Agent Builder UI → Context タブ
- または MessagingSession オブジェクトのフィールド名を参照

#### UserDevSupportAgentでの適用
現在のUserDevSupportAgentはService Agentではないため、context variablesは不要。

---

### D. Conversation History（会話履歴）

#### 概要
- 複数ターンの会話をシミュレート
- 過去の会話を踏まえた応答をテスト

#### 構文
```yaml
conversationHistory:
  - role: user
    message: "前回の質問"
  - role: assistant
    message: "エージェントの前回の回答"
```

#### UserDevSupportAgentでの適用例
```yaml
testCases:
  - utterance: その項目のデータ型はどうすればいい？
    expectedTopic: p_16jdL000002lnH3_Custom_Object_Setup
    conversationHistory:
      - role: user
        message: カスタムオブジェクトに項目を追加したい
      - role: assistant
        message: G-201のガイドに従って項目を追加してください
    expectedOutcome: データ型選択のガイダンスを提供する
```

---

## 3️⃣ テスト作成のワークフロー

### Step 1: プレビュー生成（推奨）
```bash
sf agent test create --preview --target-org pfPhase2Org
```

#### 効果
- Orgにデプロイせずに、ローカルでXMLメタデータを確認
- ファイル名: `{TestApiName}-preview-{timestamp}.xml`
- スキーマエラーの事前検出が可能

### Step 2: テスト作成（Orgへデプロイ）
```bash
sf agent test create --target-org pfPhase2Org --spec specs/test-spec.yaml --api-name TestName
```

または対話モード:
```bash
sf agent test create --target-org pfPhase2Org
# プロンプトでAPI名とspecファイルを選択
```

#### 動作
1. ローカルメタデータ作成
2. Orgへデプロイ
3. DXプロジェクトと同期（force-app/main/default/aiEvaluationDefinitions/）

### Step 3: 上書き更新
```bash
sf agent test create --force-overwrite --spec specs/test-spec.yaml --api-name TestName --target-org pfPhase2Org
```

---

## 4️⃣ テスト実行のオプション

### 基本実行
```bash
sf agent test run --api-name TestName --target-org pfPhase2Org
```

### 重要なフラグ

#### `--verbose` ⭐ トラブルシューティングに必須
```bash
sf agent test run --api-name TestName --verbose --target-org pfPhase2Org
```

**出力される情報:**
- Generated Data（エージェントが呼び出したアクションの詳細）
- Topic選択プロセス
- Knowledge Base参照状況
- Action実行の入出力

**デバッグ用途:**
- なぜOff_Topicになったのか診断
- 期待したアクションが呼ばれなかった理由の特定
- Knowledge Baseが参照されたか確認

#### `--result-format`
```bash
sf agent test run --api-name TestName --result-format human
```

オプション:
- `human` - 人間が読みやすいテーブル形式
- `json` - JSON形式（CI/CD統合用）

#### `--wait`
```bash
sf agent test run --api-name TestName --wait 10
```
- テスト完了を待つ時間（分）
- デフォルト: 5分
- 大規模テストの場合は延長推奨

### Testing Center UIでの確認
```bash
sf org open --path /lightning/setup/TestingCenter/home --target-org pfPhase2Org
```

---

## 5️⃣ 現在の実装への適用ロードマップ

### Phase 1: Metricsの追加（即座に実施可能）

#### 対象ファイル
`specs/UserDevSupportAgent-smoke-testSpec.yaml`

#### 変更内容
各testCaseにmetricsセクションを追加:
```yaml
testCases:
  - utterance: カスタムオブジェクト作成手順を教えて
    expectedTopic: p_16jdL000002lnH3_Custom_Object_Setup
    expectedActions: []
    expectedOutcome: G-101に沿って作成手順を案内する
    metrics:
      - instruction_following  # Topic精度診断用
      - coherence
      - completeness
      - output_latency_milliseconds
```

#### 効果
- Topic選択精度の定量評価
- instruction_followingスコアでinstruction改善の判断基準が得られる

---

### Phase 2: --verboseによる詳細診断

#### 実行コマンド
```bash
sf agent test run --api-name UserDevSupportAgent_SmokeTest --verbose --target-org pfPhase2Org --wait 10
```

#### 診断ポイント
1. **Topic選択プロセス**
   - どのTopicが候補に挙がったか
   - なぜCustom_Object_Setupが選ばれなかったか

2. **Knowledge Base参照**
   - G-101 / G-201が検索されたか
   - 検索キーワードと一致度

3. **Instruction解釈**
   - Topic instructionがどう解釈されたか

---

### Phase 3: Topic Instruction改善

#### 現状の問題
- TC1: カスタムオブジェクト作成手順 → Off_Topic
- TC2: カスタム項目追加手順 → Record_Data_Management
- TC4: 選択リスト項目の作り方 → Off_Topic

#### 改善方針
`force-app/main/default/genAiPlonPlugins/p_16jdL000002lnH3_Custom_Object_Setup.genAiPlugin-meta.xml`

**現在のinstruction:**
```
あなたは、オブジェクト設計やカスタマイズに関する質問に答えます。
```

**改善案（キーワード強化）:**
```
あなたは、以下のトピックに関する質問に答えます：
- カスタムオブジェクトの作成・設定・編集
- カスタム項目の追加・変更（テキスト、数値、選択リスト、数式など）
- 項目のデータ型選択
- バリデーションルール
- ページレイアウトの調整

以下のキーワードを含む質問に対応してください：
「オブジェクト作成」「項目追加」「カスタム項目」「選択リスト」「数式項目」「データ型」
```

---

### Phase 4: Custom Evaluationsの追加（オプション）

#### 将来実装時の例
G-101ガイドへの言及を検証:
```yaml
customEvaluations:
  - label: Verify G-101 Reference
    name: string_comparison
    parameters:
      - name: actual
        value: $.response.message
        isReference: true
      - name: operator
        value: contains
        isReference: false
      - name: expected
        value: "G-101"
        isReference: false
```

---

## 6️⃣ トラブルシューティングガイド

### 問題: Topic選択精度が低い（Off_Topic多発）

#### Step 1: --verboseで診断
```bash
sf agent test run --api-name UserDevSupportAgent_SmokeTest --verbose
```

確認項目:
- [ ] Topic候補リストにCustom_Object_Setupが含まれているか
- [ ] utteranceからどのキーワードが抽出されているか
- [ ] Knowledge Base検索が実行されているか

#### Step 2: metricsでinstruction_followingスコア確認
- スコア < 0.6 → instruction改善が必要
- スコア >= 0.6 → utteranceが曖昧な可能性

#### Step 3: Topic instruction強化
- キーワードの明示的列挙
- より具体的なトピック説明
- 例示の追加

---

### 問題: テストがタイムアウトする

#### 原因
- 複雑なアクションチェーン
- Knowledge Base検索が遅い

#### 対策
```bash
sf agent test run --api-name TestName --wait 15  # 15分に延長
```

---

### 問題: Generated Dataが空

#### 原因
- アクションが実行されていない
- Knowledge Baseのみ参照された

#### 対策
- `--verbose`で実行プロセス全体を確認
- expectedActionsを明示的に設定してアクション呼び出しを誘発

---

## 7️⃣ CI/CD統合のベストプラクティス

### JSON形式でのテスト実行
```bash
sf agent test run --api-name TestName --result-format json > test-results.json
```

### 失敗時の終了コード
- 終了コード 0: すべて成功
- 終了コード 1: テスト失敗あり

### GitHub Actions例
```yaml
- name: Run Agent Test
  run: |
    sf agent test run \
      --api-name UserDevSupportAgent_SmokeTest \
      --target-org ${{ secrets.ORG_ALIAS }} \
      --wait 10 \
      --result-format json \
      > test-results.json
  
- name: Check Results
  run: |
    if [ $? -ne 0 ]; then
      echo "Agent test failed"
      exit 1
    fi
```

---

## 8️⃣ チェックリスト

### テストスペック作成時
- [ ] `subjectType: AGENT`を使用（BOT_VERSIONではない）
- [ ] `subjectName`にエージェントAPI名を設定
- [ ] `subjectVersion`を指定（例: v1）
- [ ] 各testCaseに`expectedTopic`を設定
- [ ] `metrics`セクションを追加（特にinstruction_following）
- [ ] utteranceは実際のユーザー発話に近い形で記述

### テスト実行時
- [ ] 初回は`--verbose`で実行して詳細確認
- [ ] タイムアウトが心配な場合は`--wait`を延長
- [ ] 失敗したtestCaseはverbose出力で原因を診断

### デプロイ前
- [ ] `--preview`でメタデータを事前確認
- [ ] スキーマエラーがないことを確認

### 定期実行時
- [ ] Pass率を記録（Topic精度の継続モニタリング）
- [ ] instruction_followingスコアをトラッキング
- [ ] 新しいガイド追加時にテストケースも追加

---

## 9️⃣ 参考リンク

### Salesforce公式ドキュメント
- [Agentforce DX - Test an Agent](https://developer.salesforce.com/docs/ai/agentforce/guide/agent-dx-test.html)
- [Agentforce Testing API](https://developer.salesforce.com/docs/ai/agentforce/guide/testing-api.html)
- [Use Test Results to Improve Your Agent](https://developer.salesforce.com/docs/ai/agentforce/guide/testing-api-use-results.html)

### CLI リファレンス
- [sf agent Commands](https://developer.salesforce.com/docs/atlas.en-us.sfdx_cli_reference.meta/sfdx_cli_reference/cli_reference_agent_commands_unified.htm)

---

## 🔟 バージョン履歴

| 日付 | バージョン | 変更内容 |
|------|----------|---------|
| 2026-03-08 | 1.0.0 | 初版作成。4つの公式ドキュメントから重要情報を抽出・統合 |

---

## まとめ

このガイドの**最重要ポイント**:

1. **Metricsの活用** - 特に`instruction_following`でTopic精度を定量評価
2. **--verboseフラグ** - トラブルシューティングの必須ツール
3. **Custom Evaluations** - アクション出力の詳細検証が可能
4. **Topic Instruction改善** - キーワードの明示的列挙が効果的

現在のPhase 3.1-3aでの次のステップ:
1. ✅ **即座に実施**: Metricsをテストスペックに追加
2. ✅ **直後に実施**: --verboseで失敗理由を詳細診断
3. ⏭️ **結果を基に**: Topic instructionを改善
4. 🔄 **改善後**: テスト再実行で効果を検証
