# 19 VCS And GitHub Workflow

## 目的
- GitとGitHub運用を標準化し、変更の追跡性と安全性を確保する。
- agentAIの暴走リスクを抑えるため、危険操作を明示的に禁止する。

## 基本方針（安全最優先）
- ブランチ戦略は `main + feature/*` を採用する。
- `main` への直接pushは禁止し、PR経由のみ許可する。
- マージ方式は `Squash merge` に固定する。
- 通常運用では rebase を使わない。
- 例外的に rebase が必要な場合は、ユーザー承認を得た場合のみ実施する。
- `force push` は禁止する。
- 不具合時は `revert` を第一選択にする。

## ブランチ運用
- ブランチ作成タイミング: 要件確定後、実装着手前
- 命名規則: `feature/<scope>-<short-desc>`
- 緊急対応（必要時のみ）: `hotfix/<scope>-<short-desc>`

## コミット運用
- 1コミット1意図を原則とする。
- 大きな変更は複数コミットに分割し、レビュー可能性を優先する。
- コミット候補の目安:
  - 実装反映完了
  - テスト反映完了
  - ドキュメント更新完了

## PR運用
- PRは必須。
- PRタイトルは prefix 必須（`feat:`, `fix:`, `docs:`）。
- PR本文に最低限以下を記載:
  - 目的
  - 変更内容
  - 影響範囲
  - 確認手順
  - ロールバック方針
- ソロ開発時の承認は self-review のみで可とする。

## マージ条件（DoD）
- 変更要約・影響範囲・ロールバック方針が記載済み
- self-review 完了
- CIは現時点で未導入のため、導入を検討中であることを明記
- 条件を満たした後、Squash mergeを実施

## agentAI向け禁止事項
- `main` へ直接push
- `git push --force`
- `git reset --hard`
- 承認前のマージ
- コンフリクトを推測で自動解決

## 実行前承認ルール（agentAI）
- Git操作の前に、実行予定コマンドを提示する。
- ユーザーの承認後に実行する。

## 記録ルール
- `03_change_log.md` に Branch/PR/Commit の情報を残す（任意項目）。
- `11_phase_completion_report.md` に Branch/PR/Commit/マージ結果を記録する。

## コミット前チェックリスト（必須）

### チェック実施義務
以下のいずれかの変更を含むコミットでは、コミット前に整合性チェックを実施する：

- [ ] **コア文書（00-05）の更新**
  - `00_master_prompt.md`
  - `01_overview_prompt.md`
  - `02_solution_definition.md`
  - `03_change_log.md`
  - `04_existing_data_model.md`
  - `05_requirement_definition.md`

- [ ] **設計文書（design/）の追加・更新**

- [ ] **ガバナンスルール（agentAI_pronpts/）の変更**

- [ ] **フェーズ完了・開始の記録**

### チェック実施手順
詳細は **`20_consistency_check_process.md`** を参照

#### 簡易チェック（推奨: 日常コミット時）
```powershell
# 1. ログファイル名の統一確認
Select-String -Path "userDevSupport_Agentforce_Docs/**/*.md" -Pattern "change_log\.md" -Exclude "03_change_log.md"

# 2. スコープ定義の確認
Select-String -Path "userDevSupport_Agentforce_Docs/01_overview_prompt.md","userDevSupport_Agentforce_Docs/02_solution_definition.md" -Pattern "スコープ|対象範囲"

# 3. 変更ログ記録確認
Get-Content userDevSupport_Agentforce_Docs/03_change_log.md | Select -Last 20
```

#### 完全チェック（必須: フェーズ完了時・PR作成前）
1. コア定義文書群の整合性チェック
2. フェーズ進行記録の整合性チェック
3. 設計成果物との整合性チェック
4. ガバナンス・運用ルールの整合性チェック
5. 用語・表記の一貫性チェック

### FILE_STRUCTURE_ANALYSIS.md の更新
以下の場合は `FILE_STRUCTURE_ANALYSIS.md` を更新する：

- [ ] 新しいディレクトリを追加した
- [ ] 新しいドキュメント（コア文書・設計文書）を追加した
- [ ] ファイルを移動・削除した
- [ ] フェーズが完了した

更新手順の詳細は **`20_consistency_check_process.md`** を参照

### 不整合発見時の対応
1. **HIGH（重大）**: 即座に修正、コミット前に解決必須
   - スコープ定義の矛盾
   - フェーズ記録の欠落
   
2. **MEDIUM（中程度）**: 修正を推奨、リスク評価後にコミット判断
   - 設計文書の相互参照不整合
   - ステータス未更新
   
3. **LOW（軽微）**: 次回更新時に修正可
   - 表記ゆれ
   - 軽微な参照ミス

### チェック実施の記録
整合性チェックを実施した場合は、`03_change_log.md` に記録する：

```markdown
### [日付] 整合性チェック実施

**チェック種別**: [簡易/完全]
**チェック結果**: [OK/修正あり]
**修正内容**（該当時）: [修正項目と内容]
**FILE_STRUCTURE_ANALYSIS更新**: [実施/不要]
```

### agentAI への指示
- コミット前に該当チェックを自動実行し、結果をユーザーに報告する
- 不整合発見時は重大度と修正案を提示する
- FILE_STRUCTURE_ANALYSIS 更新が必要な場合は更新内容を提示する
