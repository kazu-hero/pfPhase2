# Design Index

## 目的
- 追加した設計資料を見失わないための一覧管理
- 設計フェーズ成果物の参照順を固定化

## 参照順（推奨）
1. `01_overall_architecture.md`
2. `02_response_patterns.md`
3. `03_crud_operations.md`
4. `04_error_handling.md`
5. `05_usecase_uc1_detail.md`
6. `06_usecase_uc2_detail.md`
7. `07_usecase_uc3_detail.md`
8. `08_guide_structure.md`
9. `09_design_review.md`
10. `10_knowledge_integration_plan.md`
11. `11_knowledge_metadata_diff_proposal.md`

## ファイル一覧
| No | ファイル | 用途 |
|---|---|---|
| 01 | `01_overall_architecture.md` | Agentforce全体設計（Topic/Action/Knowledge） |
| 02 | `02_response_patterns.md` | Agent応答テンプレート標準化 |
| 03 | `03_crud_operations.md` | CRUD操作とSOQL最適化方針 |
| 04 | `04_error_handling.md` | エラー分類、リトライ、例外設計 |
| 05 | `05_usecase_uc1_detail.md` | UC-1詳細（要望分析→施策提案） |
| 06 | `06_usecase_uc2_detail.md` | UC-2詳細（レコードCRUD） |
| 07 | `07_usecase_uc3_detail.md` | UC-3詳細（ノンコード開発ガイド） |
| 08 | `08_guide_structure.md` | ガイド体系（28ガイド） |
| 09 | `09_design_review.md` | 要件カバレッジ・整合性レビュー |
| 10 | `10_knowledge_integration_plan.md` | Phase 3.1-2 Knowledge連携の実装計画 |
| 11 | `11_knowledge_metadata_diff_proposal.md` | Knowledge有効化のメタデータ差分案 |

## 関連ファイル
- `../PHASE2_COMPLETION_REPORT.md`: Phase 2完了報告
- `99_design_history_log.md`: 設計履歴の台帳

## 運用ルール
- 新しい設計ドキュメントを追加したら、この一覧に必ず追記する。
- 既存設計を更新したら、`99_design_history_log.md` に更新履歴を記録する。
- フェーズ完了時に `03_change_log.md` へサマリを転記する。

## 更新履歴
| 日付 | 更新者 | 内容 |
|---|---|---|
| 2026-03-08 | AgentAI | 初版作成 |
| 2026-03-08 | AgentAI | 10_knowledge_integration_plan.md を追加 |
| 2026-03-08 | AgentAI | 11_knowledge_metadata_diff_proposal.md を追加 |
