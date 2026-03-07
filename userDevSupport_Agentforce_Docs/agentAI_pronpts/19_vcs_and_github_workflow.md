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
