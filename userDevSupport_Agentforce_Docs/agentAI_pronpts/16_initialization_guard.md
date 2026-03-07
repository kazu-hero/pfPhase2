# 16 Initialization Guard

## 目的
- 全ての作業前に必須の初期化フロー を強制実行する。

## 毎回の作業直前に実行（必須）

### ステップ1：このファイルを音読
- 「16_initialization_guard.md を読み込みました」と宣言する。

### ステップ2：ユーザー指示と02_solution_definition.mdの対比
- ユーザーの指示内容を確認
- 02_solution_definition.md の「スコープ」「非スコープ」に叩き合わせる
- **スコープ外なら即座に「スコープ外です」と明示して停止する**

### ステップ3：必須ファイル読込確認

以下の15ファイルを読み込み完了するまで先に進まない（00_preload_process.md準拠）：
- ✓ 00_master_prompt.md
- ✓ 01_overview_prompt.md
- ✓ 02_solution_definition.md
- ✓ 16_initialization_guard.md（このファイル）
- ✓ 01_phase_definition.md
- ✓ 02_data_model_constraints.md
- ✓ 03_prompt_file_review_process.md
- ✓ 04_context_constraints.md
- ✓ 07_default_work_prompt.md
- ✓ 06_work_review_prompt.md
- ✓ 08_stop_criteria.md
- ✓ 09_error_reporting.md
- ✓ 18_error_stop_protocol.md
- ✓ 17_approval_before_deploy.md
- ✓ 19_vcs_and_github_workflow.md

### ステップ4：実装対象の明確化

以下をユーザーに確認する形式で提示：
```
【初期化フロー完了確認】

読み込み完了ファイル（15ファイル）：
- 00_master_prompt.md: ✓
- 01_overview_prompt.md: ✓
- 02_solution_definition.md: ✓
- 16_initialization_guard.md: ✓
- 01_phase_definition.md: ✓
- 02_data_model_constraints.md: ✓
- 03_prompt_file_review_process.md: ✓
- 04_context_constraints.md: ✓
- 07_default_work_prompt.md: ✓
- 06_work_review_prompt.md: ✓
- 08_stop_criteria.md: ✓
- 09_error_reporting.md: ✓
- 18_error_stop_protocol.md: ✓
- 17_approval_before_deploy.md: ✓
- 19_vcs_and_github_workflow.md: ✓

【指示内容の整理】
ユーザー指示: [具体的な指示内容]

実装対象:
- [修正対象1]
- [修正対象2]
- ...

非スコープ（禁止）:
- [スコープ外]
- [禁止操作]

【確認】
上記で間違いないでしょうか？
進めてもいいですか？
```

## スコープ外の自動判定（即座に停止）

以下に該当するユーザー指示は必ず「スコープ外」として停止：

### 1. 非許可コンポーネントの新規作成・変更
- 02_solution_definition.md の「既存利用」「作成不要」「変更禁止」に反する指示
- **→ 非許可コンポーネントの作成/変更指示 = 停止**

### 2. 対象外オブジェクト/モジュールの対応
- 02_solution_definition.md の対象範囲に含まれないオブジェクト/モジュールへの変更指示
- **→ 対象外への変更指示 = 停止**

### 3. UI/UX要件に反する実装
- 02_solution_definition.md で規定された表示方式・通知方式に反する実装指示
- **→ 規定外UI実装指示 = 停止**

### 4. テスト実装ポリシーに反する自動生成
- 02_solution_definition.md のテスト方針（手動指示のみ等）に反する自動生成指示
- **→ テスト自動生成指示 = 停止**

### 5. 上記以外でも非スコープ定義に該当
- 02_solution_definition.md の「非スコープ」「禁止事項」「変更禁止」に該当
- **→ 非スコープ指示 = 停止**

## 停止時のフォーマット

```
【スコープ外】

ユーザー指示: [指示内容]
理由: 02_solution_definition.md の「非スコープ」に該当
参照箇所: [definition内の明示箇所]

対応: この指示は実行できません。
修正案: [別の方法があれば提示]

ユーザーの判断をお待ちします。
```

## 例外ケース

**例外ケースは存在しません。**

もし 02_solution_definition.md の定義を変更したい場合：
1. 02_solution_definition.md を先に修正する
2. 修正内容をユーザーに確認してもらう
3. その後、16_initialization_guard.md を再実行して判定を開始する
