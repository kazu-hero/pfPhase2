# pj dir ファイル構造分析と整合性チェック

## 目的
- ファイルの存在と配置を明記する
- `00_master_prompt.md` を基準に、段階別・ブロック別の整合性を確認する
- フェーズ2成果物を含む最新の構成を固定化する

---

## 現在の状態（実在ベース）

### ルート配下（pj dir/）
```
pj dir/
├── 00_master_prompt.md
├── 01_overview_prompt.md
├── 02_solution_definition.md
├── 03_change_log.md
├── 04_existing_data_model.md
├── 05_requirement_definition.md
├── FILE_STRUCTURE_ANALYSIS.md
├── PHASE2_COMPLETION_REPORT.md
├── github_config/
│   ├── branch_rules.md
│   ├── ci_status.md
│   ├── pr_template.md
│   └── project_defaults.md
├── agentAI_pronpts/
│   ├── 00_preload_process.md
│   ├── 01_phase_definition.md
│   ├── 02_data_model_constraints.md
│   ├── 03_prompt_file_review_process.md
│   ├── 04_context_constraints.md
│   ├── 05_work_review_process.md
│   ├── 06_work_review_prompt.md
│   ├── 07_default_work_prompt.md
│   ├── 08_stop_criteria.md
│   ├── 09_error_reporting.md
│   ├── 10_hallucination_guard.md
│   ├── 11_phase_completion_report.md
│   ├── 12_phase_consistency_check.md
│   ├── 13_phase_rollback_rules.md
│   ├── 14_progress_management.md
│   ├── 15_start_declaration.md
│   ├── 16_initialization_guard.md
│   ├── 17_approval_before_deploy.md
│   ├── 18_error_stop_protocol.md
│   ├── 19_vcs_and_github_workflow.md
│   └── 20_consistency_check_process.md
├── design/
│   ├── 00_design_index.md
│   ├── 01_overall_architecture.md
│   ├── 02_response_patterns.md
│   ├── 03_crud_operations.md
│   ├── 04_error_handling.md
│   ├── 05_usecase_uc1_detail.md
│   ├── 06_usecase_uc2_detail.md
│   ├── 07_usecase_uc3_detail.md
│   ├── 08_guide_structure.md
│   ├── 09_design_review.md
│   └── 99_design_history_log.md
└── Salesforce_DevDocs/
```

---

## タスク

### タスク1: 整合性チェック（段階とブロックを分ける）
- 段階別: フェーズ1・フェーズ2の完了記録整合
- ブロック別: コア文書群、運用ガイド群、設計成果群、履歴群、補助群

### タスク2: FILE_STRUCTURE_ANALYSISの更新
- 実在するファイルと配置へ更新
- フェーズ2成果物の配置を明記

---

## 段階別整合性チェック

### Phase 1（要件整理）
| チェック項目 | 根拠 | 判定 |
|---|---|---|
| フェーズ1完了記録 | `03_change_log.md` に完了報告あり | OK |
| コア文書00-05整備 | ルートに00-05存在 | OK |
| 初期化前提の整備 | `16_initialization_guard.md` 要件に対して主要群あり | OK |

### Phase 2（設計）
| チェック項目 | 根拠 | 判定 |
|---|---|---|
| フェーズ2成果物01-09 | `design/` に01-09存在 | OK |
| 設計索引・履歴 | `design/00_design_index.md`, `design/99_design_history_log.md` 存在 | OK |
| フェーズ2完了報告 | `PHASE2_COMPLETION_REPORT.md` 存在 | OK |
| 変更ログ連携 | `03_change_log.md` にフェーズ2完了エントリあり（2026-03-08） | OK |

---

## ブロック別整合性チェック

### ブロックA: コア文書（00-05）
- 対象: `00_master_prompt.md` ～ `05_requirement_definition.md`
- 判定: OK（存在・配置一致）

### ブロックB: 運用ガイド（agentAI_pronpts 00-20）
- 対象: `agentAI_pronpts/` 一式
- 判定: OK（存在・配置一致）
- 備考: 20_consistency_check_process.md 追加（2026-03-08）

### ブロックC: フェーズ2設計成果
- 対象: `design/01` ～ `design/09`
- 判定: OK（存在・配置一致）

### ブロックD: 設計管理
- 対象: `design/00_design_index.md`, `design/99_design_history_log.md`
- 判定: OK（存在・配置一致）

### ブロックE: 履歴・報告
- 対象: `03_change_log.md`, `PHASE2_COMPLETION_REPORT.md`
- 判定: OK（存在・配置一致）

### ブロックF: 補助
- 対象: `github_config/`, `Salesforce_DevDocs/`
- 判定: OK（存在・配置一致）

---

## 差分と是正結果

### 旧版との差分（今回是正）
- `design/` 配下の存在が未記載だった
- `PHASE2_COMPLETION_REPORT.md` が未記載だった
- `Salesforce_DevDocs/` が未記載だった

### 是正結果
- 本ファイルを最新実在構成へ更新済み
- 段階別・ブロック別の整合性判定を追加済み

---

## 運用ルール（以後）
- 新規成果物追加時は、このファイルの「現在の状態」を更新する
- フェーズ完了時は `03_change_log.md` と `PHASE*_COMPLETION_REPORT.md` の整合を確認する
- `00_master_prompt.md` を基準に、段階別・ブロック別チェックを実施する

---

## 変更履歴
| 日付 | 変更者 | 変更内容 |
|---|---|---|
| 2026-03-08 | AgentAI | 段階別・ブロック別整合性チェック結果を追加し、最新構成へ更新 |
