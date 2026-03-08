# Phase 2.5 多言語対応調整（言語対応テスト）

## 目的
Agentforceが日本語での問い合わせに対して適切に日本語で応答できるようにするため、CLI生成されたAgentのすべてのトピックおよび設定に多言語対応（特に日本語対応）の指示を追加する。

---

## 実施内容

### 1. GenAiPlugins（トピック）への言語対応指示追加

#### 対象: 5つのトピック定義ファイル
- `p_16jdL000002lnFR_Requirement_Analysis_Support.genAiPlugin-meta.xml`
- `p_16jdL000002lnFR_Record_Data_Management.genAiPlugin-meta.xml`
- `p_16jdL000002lnFR_Non_Code_Development_Guidance.genAiPlugin-meta.xml`
- `p_16jdL000002lnFR_Custom_Object_Setup.genAiPlugin-meta.xml`
- `p_16jdL000002lnFR_Validation_Rule_Assistance.genAiPlugin-meta.xml`

#### 実施内容

**1.1 genAiPluginInstructions に language_support指示を追加**

各トピックに以下の新しい指示を追加：

```xml
<genAiPluginInstructions>
    <description>If the user communicates in a language other than English (especially Japanese), respond in that language to the best of your ability. Maintain the context and intent of the query while providing responses in the user's preferred language.</description>
    <developerName>language_support</developerName>
    <language xsi:nil="true"/>
    <masterLabel>language_support</masterLabel>
    <sortOrder>1</sortOrder>
</genAiPluginInstructions>
```

**指示内容**:
- ユーザーが英語以外の言語（特に日本語）で通信した場合、その言語で応答する
- クエリの文脈と意図を維持する
- ユーザーの優先言語での応答を提供する

**1.2 各トピックの scope（スコープ）を多言語対応を含む形に拡張**

各トピックのscopeに以下のような多言語対応の説明を追加：

| トピック | scope追加説明 |
|---------|-------------|
| Requirement Analysis Support | When users communicate in languages other than English (including Japanese), provide guidance in their preferred language while maintaining technical accuracy and context. |
| Record Data Management | When users communicate in languages other than English (including Japanese), conduct all operations and provide confirmations in their preferred language while maintaining data integrity. |
| Non Code Development Guidance | When users communicate in languages other than English (including Japanese), provide detailed implementation guidance in their preferred language, ensuring all instructions and recommendations are clearly understood. |
| Custom Object Setup | When users communicate in languages other than English (including Japanese), provide custom object creation and configuration guidance in their preferred language, clarifying all technical terms and field definitions. |
| Validation Rule Assistance | When users communicate in languages other than English (including Japanese), provide validation rule configuration assistance in their preferred language, explaining formula syntax and logic clearly. |

---

### 2. Bot Version Metadata への言語対応反映

#### ファイル: `v1.botVersion-meta.xml`

**修正内容**:
role フィールドに多言語対応宣言を追加

**修正前**:
```xml
<role>Salesforce開発支援Agent。ノンコード開発者の相談に応じ、要望分析施策提案、レコードCRUD操作、ノンコード開発ガイド提供を行います。</role>
```

**修正後**:
```xml
<role>Salesforce開発支援Agent。ノンコード開発者の相談に応じ、要望分析・施策提案、レコードCRUD操作、ノンコード開発ガイド提供を行います。**マルチランゲージ対応: ユーザーが日本語や英語以外の言語で質問を行った場合、可能な限りその言語で応答します。ユーザーの言語選択を尊重し、質問の文脈と意図を維持しながら、ユーザーの利便性を最優先とします。**</role>
```

---

### 3. Agent Spec YAML への言語対応反映

#### ファイル: `specs/userDevSupportAgent.yaml`

**修正内容**:

**3.1 role フィールドに多言語対応を追加**

```yaml
role: Salesforce開発支援Agent。ノンコード開発者の相談に応じ、要望分析・施策提案、レコードCRUD操作、ノンコード開発ガイド提供を行います。マルチランゲージ対応：ユーザーが日本語や英語以外の言語で質問を行った場合、可能な限りその言語で応答します。
```

**3.2 各 topic の description に多言語対応を明記**

| トピック | description追加 |
|---------|-----------------|
| Requirement Analysis Support | Respond in the user's preferred language, including Japanese if requested. |
| Record Data Management | Conduct all operations and provide confirmations in the user's preferred language, including Japanese. |
| Non Code Development Guidance | Provide implementation guidance in the user's preferred language, including Japanese if requested. |
| Custom Object Setup | Clarify all technical terms and field definitions in the user's preferred language, including Japanese. |
| Validation Rule Assistance | Explain formula syntax and logic in the user's preferred language, including Japanese if requested. |

---

## 設計方針

### マルチランゲージ対応の3層構造

1. **Agent Level（role）**: Agentの全体的な言語能力を宣言
   - 多言語対応能力の有無を明記
   - ユーザー優先言語尊重の方針を宣言

2. **Topic Level（scope + description）**: 各トピックの言語対応を明記
   - トピック固有の業務内容を多言語で提供することを明記
   - 文脈の維持とアキュラシーの両立を宣言

3. **Instruction Level（genAiPluginInstructions）**: 具体的な動作指示
   - 言語検出と応答言語の選択に関する明示的な指示
   - ユーザー言語での応答優先度を指示

### 想定される効果

1. **日本語対応の向上**:
   - 各レイヤーでの多言語対応指示により、LLMが日本語応答の優先度を認識
   - 言語検出と応答言語選択がより確実になる

2. **コンテキスト維持**:
   - 「文脈と意図を維持」の指示により、翻訳による情報損失を最小化
   - ユーザーの質問意図の理解精度向上

3. **ユーザー体験向上**:
   - 日本語ユーザーが母国語で支援を受けられる
   - 技術用語の日本語説明により理解精度向上

---

## テスト手順（Phase 2.5での検証）

### テスト1: 日本語での要件分析支援
**実施内容**:
```
ユーザー: 「営業部の要望として、顧客プロフィール情報の統一管理ツールが必要です。どのような対応が考えられますか？」
期待動作: Agentが日本語で要件分析内容を提示
```

**検証ポイント**:
- [ ] 日本語での入力を認識
- [ ] 日本語で要件分析ガイダンスを回答
- [ ] 技術用語の適切な日本語表現

### テスト2: 日本語でのレコードCRUD操作
**実施内容**:
```
ユーザー: 「新しい営業案件を作成してください。案件名：プロジェクトA、金額：500万円、期限：2026年3月31日」
期待動作: Agentが日本語で操作内容を確認し、レコード作成
```

**検証ポイント**:
- [ ] 日本語での入力を認識
- [ ] 操作確認を日本語で実施
- [ ] 操作結果報告を日本語で提供
- [ ] データ整合性の維持

### テスト3: 日本語でのノンコード開発ガイド
**実施内容**:
```
ユーザー: 「顧客ステータスが『有望』の場合、フォローアップ日を30日後に自動設定したいです。」
期待動作: Agentが日本語でフロー実装手順をガイド
```

**検証ポイント**:
- [ ] 日本語での入力を認識
- [ ] ステップバイステップのガイドを日本語で提供
- [ ] Salesforceコンポーネント（フロー等）の日本語説明

### テスト4: 日本語でのカスタムオブジェクト設定
**実施内容**:
```
ユーザー: 「プロジェクト管理用のカスタムオブジェクトを作成したいです。以下のフィールドが必要です：プロジェクト名、予算、進捗率」
期待動作: Agentが日本語でカスタムオブジェクト作成手順をガイド
```

**検証ポイント**:
- [ ] 日本語での入力を認識
- [ ] 技術用語（フィールド型等）を日本語で説明
- [ ] 関連設定手順を日本語でガイド

### テスト5: 日本語でのバリデーションルール設定
**実施内容**:
```
ユーザー: 「金額フィールドは0より大きい値に限定したいです。バリデーションルールの設定方法を教えてください」
期待動作: Agentが日本語でバリデーション設定手順をガイド
```

**検証ポイント**:
- [ ] 日本語での入力を認識
- [ ] フォーミュラ構文を日本語で説明
- [ ] エラーメッセージの日本語カスタマイズ方法をガイド

---

## 実装上の注意事項

### 多言語対応の制限事項

1. **LLMの言語能力に依存**:
   - Agentの言語能力は、基盤となるLLMの能力に依存
   - 言語対応指示は、LLMが言語と意図を正しく認識していることが前提

2. **技術用語統一の課題**:
   - Salesforce用語の日本語化には標準がない場合もある
   - 用語の一貫性をKnowledge Baseで管理することが重要

3. **文脈の複雑さ**:
   - 多言語環境では、プログラミング言語等の混在が発生
   - 適切な言語切り替え処理が必要な場合がある

### Phase 2.5での検証結果

- ✅ **実装完了**: 言語対応指示を全5トピックに追加
- ✅ **Metadata更新**: Bot Version、Agent Spec も多言語対応を反映
- ⏳ **Org デプロイ**: 準備待機中（テスト実施前）
- ⏳ **テスト実施**: 上記5つのテストケースで検証予定

---

## 次フェーズへの引き継ぎ

### Phase 3での対応

1. **Knowledge Base の日本語化**:
   - 28件のガイドを日本語で整備
   - 技術用語の統一的な日本語訳を決定

2. **エラーメッセージの多言語対応**:
   - Bot Dialog のエラーメッセージを多言語化
   - ユーザー入力言語に応じた エラー応答

3. **テスト結果に基づく改善**:
   - テスト実施結果を基に、指示文の微調整
   - ユーザーフィードバックの反映

---

## 更新履歴
| 日付 | 変更者 | 内容 |
|-----|-------|------|
| 2026-03-08 | AgentAI | Phase 2.5 多言語対応調整の実装・記録 |
