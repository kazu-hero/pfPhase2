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
├── PHASE2_5_COMPLETION_REPORT.md
├── PHASE2_5_LANGUAGE_ADJUSTMENT.md
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

### プロジェクトルート配下
```
pfPhase2/
├── specs/
│   └── userDevSupportAgent.yaml
├── force-app/
│   └── main/
│       └── default/
│           ├── bots/
│           │   └── UserDevSupportAgent/
│           │       ├── UserDevSupportAgent.bot-meta.xml
│           │       └── v1.botVersion-meta.xml
│           ├── genAiPlannerBundles/
│           │   └── UserDevSupportAgent/
│           │       └── UserDevSupportAgent.genAiPlannerBundle
│           └── genAiPlugins/
│               ├── p_16jdL000002lnFR_Custom_Object_Setup.genAiPlugin-meta.xml
│               ├── p_16jdL000002lnFR_Non_Code_Development_Guidance.genAiPlugin-meta.xml
│               ├── p_16jdL000002lnFR_Record_Data_Management.genAiPlugin-meta.xml
│               ├── p_16jdL000002lnFR_Requirement_Analysis_Support.genAiPlugin-meta.xml
│               └── p_16jdL000002lnFR_Validation_Rule_Assistance.genAiPlugin-meta.xml
└── userDevSupport_Agentforce_Docs/
    （上記ツリー参照）
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

### Phase 2.5（CLI調査）
| チェック項目 | 根拠 | 判定 |
|---|---|---|
| CLI調査完了報告 | `PHASE2_5_COMPLETION_REPORT.md` 存在 | OK |
| Agent Spec生成 | `specs/userDevSupportAgent.yaml` 存在 | OK |
| Agent Metadata生成 | `force-app/main/default/bots/UserDevSupportAgent/` 存在（2ファイル） | OK |
| Planner Bundle生成 | `force-app/main/default/genAiPlannerBundles/UserDevSupportAgent/` 存在 | OK |
| Plugins生成 | `force-app/main/default/genAiPlugins/` 5ファイル存在 | OK |
| 変更ログ連携 | `03_change_log.md` にPhase 2.5完了エントリあり（2026-03-08） | OK |

### Phase 2.5 拡張1（言語対応調整）
| チェック項目 | 根拠 | 判定 |
|---|---|---|
| 言語対応テスト文書 | `PHASE2_5_LANGUAGE_ADJUSTMENT.md` 存在 | OK |
| GenAiPlugins更新 | 5トピック全てに language_support 指示追加 | OK |
| Bot Version更新 | v1.botVersion-meta.xmlのroleに多言語対応記載 | OK |
| Agent Spec更新 | specs/userDevSupportAgent.yamlのrole/topic描写に日本語対応記載 | OK |
| 変更ログ連携 | `03_change_log.md` に言語対応調整エントリあり（2026-03-08） | OK |

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
- 対象: `03_change_log.md`, `PHASE2_COMPLETION_REPORT.md`, `PHASE2_5_COMPLETION_REPORT.md`, `PHASE2_5_LANGUAGE_ADJUSTMENT.md`
- 判定: OK（存在・配置一致）
- 備考: PHASE2_5_LANGUAGE_ADJUSTMENT.md追加（2026-03-08、言語対応テスト）

### ブロックF: 補助
- 対象: `github_config/`, `Salesforce_DevDocs/`
- 判定: OK（存在・配置一致）

### ブロックG: Phase 2.5 Agent Metadata（Salesforce成果物）
- 対象: `../../specs/`, `../../force-app/main/default/bots/`, `../../force-app/main/default/genAiPlannerBundles/`, `../../force-app/main/default/genAiPlugins/`
- 判定: OK（存在・配置一致）
- 備考: sf agent CLI で生成したAgent metadata（specs 1件、Bot 2件、PlannerBundle 1件、Plugins 5件）
- 備考: プロジェクトルート（pfPhase2/）配下に配置（userDevSupport_Agentforce_Docs/ の外）

---

## 差分と是正結果

### 旧版との差分（過去是正）
- `design/` 配下の存在が未記載だった → 是正済み
- `PHASE2_COMPLETION_REPORT.md` が未記載だった → 是正済み
- `Salesforce_DevDocs/` が未記載だった → 是正済み

### 今回追加（Phase 2.5）
- `PHASE2_5_COMPLETION_REPORT.md` を履歴・報告（ブロックE）に追加
- `specs/userDevSupportAgent.yaml` をプロジェクトルート配下に追加
- `force-app/main/default/bots/UserDevSupportAgent/` を追加（2ファイル）
- `force-app/main/default/genAiPlannerBundles/UserDevSupportAgent/` を追加（1ファイル）
- `force-app/main/default/genAiPlugins/` を追加（5ファイル）
- Agent Metadata構造をブロックGとして定義

### 今回追加（Phase 3.1-3a）
- `userDevSupport_Agentforce_Docs/guides/` を新設
- `guides/README.md` を追加（ガイド一覧・Topicマッピング）
- `guides/ObjectDesign/G-101_CreateCustomObject.md` を追加
- `guides/FieldDesign/G-201_CreateCustomField.md` を追加

### 今回追加（Phase 3.1-3a 自動テスト）
- `specs/UserDevSupportAgent-smoke-testSpec.yaml` を追加（4ケースのスモークテスト）
- `force-app/main/default/aiEvaluationDefinitions/UserDevSupportAgent_SmokeTest.aiEvaluationDefinition-meta.xml` を追加

### 今回追加（Phase 3.1-3a Agent Test公式ドキュメント統合）
- `Salesforce_DevDocs/agentforce-cli-reference/agent-test-best-practices.md` を追加（780行、実践ガイド）
  - 4つの公式ドキュメント（Generate/Customize/Create/Run Agent Tests）から抽出
  - Metrics機能、--verboseフラグ、Custom Evaluations等の重要機能を網羅
  - Topic選択精度改善のためのトラブルシューティング手順を含む

### 是正結果
- 本ファイルを最新実在構成へ更新済み（2026-03-08 - 2026-03-09）
- 段階別・ブロック別の整合性判定を追加済み（Phase 2.5対応）

---

## 運用ルール（以後）
- 新規成果物追加時は、このファイルの「現在の状態」を更新する
- フェーズ完了時は `03_change_log.md` と `PHASE*_COMPLETION_REPORT.md` の整合を確認する
- `00_master_prompt.md` を基準に、段階別・ブロック別チェックを実施する

---

## 変更履歴
| 日付 | 変更者 | 変更内容 |
|---|---|---|
| 2026-03-09 | AgentAI | Phase 3.1-3a Agent Test公式ドキュメント統合に伴い agent-test-best-practices.md を追加記録 |
| 2026-03-08 | AgentAI | Phase 3.1-3a自動テストに伴い spec と aiEvaluationDefinitions を追加記録 |
| 2026-03-08 | AgentAI | Phase 3.1-3aに伴い guides/ 配下（README, G-101, G-201）を追加記録 |
| 2026-03-08 | AgentAI | 段階別・ブロック別整合性チェック結果を追加し、最新構成へ更新 |
| 2026-03-08 | AgentAI | Phase 2.5完了に伴い、PHASE2_5_COMPLETION_REPORT.md、specs/、force-app Agent metadata をブロックE・G に追加 |
| 2026-03-08 | AgentAI | Phase 2.5言語対応調整に伴い、PHASE2_5_LANGUAGE_ADJUSTMENT.md を新規追加、GenAiPlugins更新を記録 |
