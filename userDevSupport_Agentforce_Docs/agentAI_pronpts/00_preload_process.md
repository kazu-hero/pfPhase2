# 00 Preload Process

## 目的
- 作業開始前に agent AI が読み込むべきファイルと順序を定義する。

## 手順
1. 00_master_prompt.md を最初に読む。
2. 01_overview_prompt.md を読む。
3. 02_solution_definition.md を読む。
4. **16_initialization_guard.md を読む。** ← ★NEW
5. 01_phase_definition.md を読む。
6. 02_data_model_constraints.md を読む。
7. 03_prompt_file_review_process.md を読む。
8. 04_context_constraints.md を読む。
9. 07_default_work_prompt.md を読む。
10. 06_work_review_prompt.md を読む。
11. 08_stop_criteria.md と 09_error_reporting.md を読む。
12. **18_error_stop_protocol.md を読む。** ← ★NEW
13. **17_approval_before_deploy.md を読む。** ← ★NEW
14. **19_vcs_and_github_workflow.md を読む。** ← ★NEW

## タスク単位の再読込フロー（コンテキスト制限対応）
1. タスク開始前に 00_master_prompt.md、01_overview_prompt.md、02_solution_definition.md を再読込する。
2. タスク種別に応じて必要最小限のプロンプトだけ読む。
	- 要件整理: 01_phase_definition.md, 02_data_model_constraints.md
	- 設計: 01_phase_definition.md, 02_data_model_constraints.md
	- 実装: 01_phase_definition.md, 02_data_model_constraints.md, 07_default_work_prompt.md
	- Git/GitHub運用: 19_vcs_and_github_workflow.md
	- テスト: 01_phase_definition.md, 09_error_reporting.md
	- レビュー: 05_work_review_process.md, 06_work_review_prompt.md
3. 同一タスク内で情報が不足した場合のみ追加読込する。
4. タスク完了時は 11_phase_completion_report.md を参照して記録する。

## 未確定時の扱い
- 読み込み対象が不足している場合は作業を開始せず、質問する。
