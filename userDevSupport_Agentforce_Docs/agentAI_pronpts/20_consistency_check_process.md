# 20 Consistency Check Process

## 目的
- プロジェクト文書間の整合性を継続的に維持する
- Git コミット前に必須チェックを実施し、不整合の混入を防ぐ
- `FILE_STRUCTURE_ANALYSIS.md` を最新状態に保つ

---

## チェック実施タイミング

### 必須実施（Gitコミット前）
以下のいずれかの変更を行った場合、コミット前に整合性チェックを実施する：

1. **コア文書の更新**（00-05）
   - `00_master_prompt.md`
   - `01_overview_prompt.md`
   - `02_solution_definition.md`
   - `03_change_log.md`
   - `04_existing_data_model.md`
   - `05_requirement_definition.md`

2. **設計文書の追加・更新**（design/）
   - `design/01` ～ `design/09`
   - `design/00_design_index.md`
   - `design/99_design_history_log.md`

3. **ガバナンスルールの変更**（agentAI_pronpts/）
   - `agentAI_pronpts/00` ～ `agentAI_pronpts/20`

4. **フェーズ完了・開始時**
   - フェーズ完了報告作成時
   - 新フェーズ開始宣言時

### 推奨実施
- 大規模な複数ファイル更新後
- PR作成前
- フェーズマイルストーン時

---

## 整合性チェック項目

### 1. コア定義文書群の整合性

#### チェック内容
- [ ] `01_overview_prompt.md` と `02_solution_definition.md` のスコープ定義が一致しているか
- [ ] `02_solution_definition.md` の「確定済み項目」セクションが最新か
- [ ] `02_solution_definition.md` の「未確定事項」セクションに解決済み項目が残っていないか
- [ ] `04_existing_data_model.md` が実環境スキーマと同期しているか
- [ ] `05_requirement_definition.md` のリスク項目にフェーズ完了状態が反映されているか

#### 確認コマンド例
```powershell
# スコープ定義の確認
grep -E "スコープ|範囲|対象" userDevSupport_Agentforce_Docs/01_overview_prompt.md
grep -E "スコープ|範囲|対象" userDevSupport_Agentforce_Docs/02_solution_definition.md

# 未確定事項の確認
grep -A 20 "未確定事項" userDevSupport_Agentforce_Docs/02_solution_definition.md
```

---

### 2. フェーズ進行記録の整合性

#### チェック内容
- [ ] `03_change_log.md` に最新の変更が記録されているか
- [ ] フェーズ完了報告が `03_change_log.md` に記載されているか
- [ ] `PHASE*_COMPLETION_REPORT.md` が存在し、内容が `03_change_log.md` と一致しているか
- [ ] フェーズ完了時の「未解決事項」が次フェーズで引き継がれているか

#### 確認コマンド例
```powershell
# 最新のフェーズ記録確認
grep -E "Phase [0-9]|フェーズ[0-9]|完了報告" userDevSupport_Agentforce_Docs/03_change_log.md | Select -Last 10

# 完了報告ファイルの存在確認
Get-ChildItem userDevSupport_Agentforce_Docs/PHASE*_COMPLETION_REPORT.md
```

---

### 3. 設計成果物との整合性

#### チェック内容
- [ ] `design/00_design_index.md` に全設計文書がリストされているか
- [ ] `design/01` ～ `design/09` が `02_solution_definition.md` の制約に準拠しているか
- [ ] 設計文書内で参照している他文書（例: `02_solution_definition.md`）が正しく存在するか
- [ ] 設計文書で定義したパターン（例: P-001～P-008）が一貫して使用されているか
- [ ] `design/09_design_review.md` のレビュー結果が反映されているか

#### 確認コマンド例
```powershell
# 設計文書の相互参照確認
grep -r "02_solution_definition" userDevSupport_Agentforce_Docs/design/

# パターン使用の確認
grep -r "P-00[1-8]" userDevSupport_Agentforce_Docs/design/
```

---

### 4. ガバナンス・運用ルールの整合性

#### チェック内容
- [ ] `00_master_prompt.md` のフェーズ定義が `agentAI_pronpts/01_phase_definition.md` と一致しているか
- [ ] `00_master_prompt.md` のガバナンスルールが `agentAI_pronpts/` 内の各ルールと矛盾していないか
- [ ] `10_hallucination_guard.md` の「推測禁止」ルールが設計文書で遵守されているか
- [ ] `19_vcs_and_github_workflow.md` のルールが実際の運用と一致しているか

#### 確認コマンド例
```powershell
# フェーズ定義の確認
grep -A 30 "フェーズ定義" userDevSupport_Agentforce_Docs/00_master_prompt.md
grep -A 30 "フェーズ定義" userDevSupport_Agentforce_Docs/agentAI_pronpts/01_phase_definition.md
```

---

### 5. 用語・表記の一貫性

#### チェック内容
- [ ] ログファイル名が `03_change_log.md` で統一されているか（`change_log.md` の混在なし）
- [ ] ユースケース表記が `UC-1`、`UC-2`、`UC-3` で統一されているか
- [ ] フェーズ表記が適切か（`Phase 1`、`フェーズ1` など文脈に応じた使い分け）
- [ ] オブジェクト名が `__c` サフィックス付きで統一されているか
- [ ] Apex/LWC/SOQL などの技術用語の表記ゆれがないか

#### 確認コマンド例
```powershell
# ログファイル名の表記確認
grep -r "change_log\.md" userDevSupport_Agentforce_Docs/ --include="*.md"

# UC表記の確認
grep -r "UC[- ][0-9]|UC[0-9]" userDevSupport_Agentforce_Docs/ --include="*.md"
```

---

## FILE_STRUCTURE_ANALYSIS.md の更新手順

### 更新が必要なケース
1. 新しいディレクトリを追加した
2. 新しいドキュメントを追加した（特にコア文書、設計文書）
3. ファイルを移動・削除した
4. フェーズが完了した
5. ブロック構成に変更があった

### 更新手順

#### ステップ1: ファイル構造の確認
```powershell
# 現在のディレクトリ構造を確認
Get-ChildItem -Path userDevSupport_Agentforce_Docs/ -Recurse -Name | Sort-Object
```

#### ステップ2: FILE_STRUCTURE_ANALYSIS.md の該当セクション特定
更新対象のセクション：
- **「現在の状態（実在ベース）」**: ファイル追加・削除時
- **「段階別整合性チェック」**: フェーズ完了時
- **「ブロック別整合性チェック」**: ブロック構成変更時

#### ステップ3: 更新実施
以下の原則に従って更新：
- **実在ファイルのみ記載**（推測や計画を含めない）
- **相対パスで記載**（`userDevSupport_Agentforce_Docs/` を基準）
- **判定は OK/NG/⚠️ で明記**
- **更新日時を末尾に記録**

#### ステップ4: 整合性チェック表の更新
変更内容に応じて該当するチェック表を更新：

```markdown
### Phase X（フェーズ名）
| チェック項目 | 根拠 | 判定 |
|---|---|---|
| [項目名] | [根拠となるファイルや記述] | OK/NG/⚠️ |
```

---

## チェックリスト実施フロー

```
[変更作業完了]
    ↓
[整合性チェック実施]
    ↓
[不整合発見？]
    ├─ YES → [修正実施] → [再チェック]
    └─ NO  → [FILE_STRUCTURE_ANALYSIS更新（必要時）]
             ↓
        [03_change_log.mdに記録]
             ↓
        [Gitコミット準備OK]
             ↓
        [19_vcs_and_github_workflow.md に従いコミット]
```

---

## チェック実施例（コマンド実行）

### 簡易チェック（5分）
```powershell
# 1. コア文書のスコープ確認
Select-String -Path "userDevSupport_Agentforce_Docs/01_overview_prompt.md","userDevSupport_Agentforce_Docs/02_solution_definition.md" -Pattern "スコープ|対象範囲|非対象"

# 2. ログファイル名の統一確認
Select-String -Path "userDevSupport_Agentforce_Docs/**/*.md" -Pattern "change_log\.md" -Exclude "03_change_log.md"

# 3. 設計文書の存在確認
Test-Path "userDevSupport_Agentforce_Docs/design/0[1-9]*.md"
```

### 完全チェック（15-20分）
上記5つのチェック項目を順次実施し、全ての「確認コマンド例」を実行する。

---

## 不整合発見時の対応

### 重大度判定
- **HIGH**: スコープ定義の矛盾、フェーズ記録の欠落
- **MEDIUM**: 設計文書の相互参照不整合、ステータス未更新
- **LOW**: 表記ゆれ、軽微な参照ミス

### 対応優先度
1. **HIGH**: 即座に修正し、コミット前に解決必須
2. **MEDIUM**: 修正を推奨、リスク評価後にコミット判断
3. **LOW**: 次回更新時に修正（IssueやTODOとして記録）

### 修正後の再チェック
修正後は該当チェック項目を再度実施し、整合性を確認する。

---

## 記録ルール

### 03_change_log.md への記録
整合性チェック実施と不整合修正を記録：

```markdown
### [日付] 整合性チェック実施

**実施内容**: [簡易チェック/完全チェック]

**チェック結果**:
- コア定義文書群: [OK/修正あり]
- フェーズ進行記録: [OK/修正あり]
- 設計成果物: [OK/修正あり]
- ガバナンスルール: [OK/修正あり]
- 用語・表記: [OK/修正あり]

**修正内容**（発見時のみ）:
- [修正項目1]: [修正内容]
- [修正項目2]: [修正内容]

**FILE_STRUCTURE_ANALYSIS更新**: [実施/不要]
```

---

## 運用ルール

### agentAI への指示
1. **コミット前チェック必須**
   - コア文書・設計文書・ガバナンス文書の変更時は必ず実施
   
2. **チェック結果報告**
   - チェック実施状況をユーザーに報告
   - 不整合発見時は重大度と修正案を提示
   
3. **FILE_STRUCTURE_ANALYSIS の能動的更新**
   - ファイル構造変更時は自動的に更新を提案
   - フェーズ完了時は必ず更新
   
4. **記録の徹底**
   - チェック実施は 03_change_log.md に記録
   - 重要な不整合修正は詳細に記録

### ユーザーへの推奨
- フェーズ完了時には完全チェック（15-20分）を実施
- 日常的な変更時には簡易チェック（5分）で十分
- PR作成前には必ずチェックを実施

---

## 更新履歴
| 日付 | 更新者 | 内容 |
|---|---|---|
| 2026-03-08 | AgentAI | 初版作成、整合性チェックプロセス定義 |
