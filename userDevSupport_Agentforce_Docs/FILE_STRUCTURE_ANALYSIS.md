# pj dir ファイル構造分析と推奨配置

## 現在の状態

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
├── github_config/
│   ├── branch_rules.md
│   ├── ci_status.md
│   ├── pr_template.md
│   └── project_defaults.md
└── agentAI_pronpts/
    ├── 00_preload_process.md
    ├── 01_phase_definition.md
    ├── 02_data_model_constraints.md
    ├── 03_prompt_file_review_process.md
    ├── 04_context_constraints.md
    ├── 05_work_review_process.md
    ├── 06_work_review_prompt.md
    ├── 07_default_work_prompt.md
    ├── 08_stop_criteria.md
    ├── 09_error_reporting.md
    ├── 10_hallucination_guard.md
    ├── 11_phase_completion_report.md
    ├── 12_phase_consistency_check.md
    ├── 13_phase_rollback_rules.md
    ├── 14_progress_management.md
    ├── 15_start_declaration.md
    ├── 16_initialization_guard.md
    ├── 17_approval_before_deploy.md
    ├── 18_error_stop_protocol.md
    ├── 19_vcs_and_github_workflow.md
    └── 20_pre_commit_checklist.md
```

## 必須手順

### PJ初期に実施すること
- 00〜05のコアファイルを初期に整備し、初期化フローで参照可能な状態を維持すること。
- Git/GitHub運用を使う場合は github_config/ の初期値をプロジェクト方針に合わせて更新すること。
- 16_initialization_guard.md の必須読み込み条件を満たすため、初期作成が完了するまで作業を進めないこと。

## 推奨構造（現状維持+内容補完）

ファイル名の整合性は既に取れているため、構造は維持し、内容補完のみ実施する。

```
pj dir/
├── 00_master_prompt.md                ← 参照順の起点（最優先）
├── 01_overview_prompt.md              ← 全体概要を記載
├── 02_solution_definition.md          ← スコープと制約の単一正
├── 03_change_log.md                   ← ユーザー対話/決定方針の記録
├── 04_existing_data_model.md          ← データモデルの実在定義
├── 05_requirement_definition.md       ← 要件定義と未確定事項
├── github_config/                     ← GitHub運用のプロジェクト設定
└── agentAI_pronpts/                   ← ガイド群（00〜20）
```

## 次に実施すべき補完内容

### 00_master_prompt.md
- 参照順の起点として、読むべきファイルの優先順位を明記

### 01_overview_prompt.md
- プロジェクト概要、目的、対象範囲、非対象範囲の要約

### 02_solution_definition.md
- 単一の正としてのスコープ/非スコープ、禁止事項、既存資産、変更許可範囲

### 03_change_log.md
- ユーザー指示、AI提案、決定方針、決定理由、保留事項の記録フォーマット

### 04_existing_data_model.md
- force-app/main/default/objects の実在定義を転記

### 05_requirement_definition.md
- 要件一覧、未確定事項、受け入れ基準、テスト方針

## 補足
- agentAI_pronpts 配下は内容整合性が確保されているため変更不要。
- まず 02_solution_definition.md を確定し、16_initialization_guard.md の必須条件を満たすのが最優先。
