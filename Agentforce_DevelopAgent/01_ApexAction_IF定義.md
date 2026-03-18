# Apex Action I/F定義: getProgressByDevService

> **ステータス**: ✅ 確定（2026-03-14）
> DTO・ I/F・正規化・ nextActions優先ロジック・ counts返却ポリシー（全キー0埋め）はこのドキュメントを正とし、次工程（Apex実装）へ進む。

## 1. インターフェースサマリ

| 項目               | 内容                                                          |
| ------------------ | ------------------------------------------------------------- |
| クラス名           | `DevServiceProgressAction`                                    |
| メソッド名         | `getProgress`                                                 |
| Agentforce呼び出し | `@InvocableMethod`                                            |
| 入力型             | `List<Request>`                                               |
| 出力型             | `List<ProgressResult>`                                        |
| 権限モード         | `WITH SECURITY_ENFORCED`                                      |
| 副作用             | なし（読取専用）                                              |
| 配置先             | `force-app/main/default/classes/DevServiceProgressAction.cls` |

---

## 2. Apex DTOクラス構造

```apex
public class DevServiceProgressAction {

    @InvocableMethod(
        label='Get Dev Service Progress'
        description='Dev_Service__c を起点に5階層の進捗を集計して返す'
    )
    public static List<ProgressResult> getProgress(List<Request> requests) { ... }

    // ── 入力 ──────────────────────────────────────────
    public class Request {
        @InvocableVariable(label='Dev Service ID' required=true)
        public Id devServiceId;
    }

    // ── 出力ルート ────────────────────────────────────
    public class ProgressResult {
        @InvocableVariable public Summary   summary;
        @InvocableVariable public Counts    counts;
        @InvocableVariable public List<NextActionItem> nextActions;
        @InvocableVariable public List<Notice>         notices;
    }

    // ── 概要ブロック ──────────────────────────────────
    public class Summary {
        @InvocableVariable public Id           devServiceId;
        @InvocableVariable public String       devServiceName;
        @InvocableVariable public String       devServiceStatus;  // OPEN | CLOSE
        @InvocableVariable public Integer      totalItems;        // = ticket.total
        @InvocableVariable public Decimal      progressRate;      // 0–100, scale=1, 0割 → 0.0
        // 丸め実装規定: total=0 の場合は 0.0 を返す。それ以外は
        //   Decimal rate = (done * 100.0) / total;
        //   progressRate = rate.setScale(1, RoundingMode.HALF_UP);
        @InvocableVariable public List<String> highlights;        // 最大3要点リスト（区切り文字はテンプレ側で処理）
    }

    // ── ステータス件数ブロック ─────────────────────────
    public class Counts {
        @InvocableVariable public ObjectCounts issue;
        @InvocableVariable public ObjectCounts plan;
        @InvocableVariable public ObjectCounts requirements;
        @InvocableVariable public ObjectCounts ticket;
        @InvocableVariable public ObjectCounts overall;     // 4階層合算
    }

    public class ObjectCounts {
        @InvocableVariable public Integer notStarted;  // TODO + PENDING → NotStarted
        @InvocableVariable public Integer inProgress;  // WIP              → InProgress
        @InvocableVariable public Integer done;        // DONE             → Done
        @InvocableVariable public Integer blocked;     // DROP             → Blocked
        @InvocableVariable public Integer total;
    }

    // ── 次に確認すべき対象ブロック ────────────────────
    public class NextActionItem {
        @InvocableVariable public String  level;       // Issue | Plan | Requirements | Ticket
        @InvocableVariable public Id      recordId;    // null = 件数ベース推奨
        @InvocableVariable public String  recordName;
        @InvocableVariable public Integer countHint;  // 件数ベース時のサマリ件数（optional, PoC据え置き可）
        @InvocableVariable public String  reason;     // BlockedExists | HighNotStartedRatio | LowProgress | Other
        @InvocableVariable public String  detail;     // 会話用の具体文
    }

    // ── 文字列定数（level / reason / notice.type を集中管理してスペル誤差を防ぐ） ──
    private static final String LEVEL_ISSUE        = 'Issue';
    private static final String LEVEL_PLAN         = 'Plan';
    private static final String LEVEL_REQ          = 'Requirements';
    private static final String LEVEL_TICKET       = 'Ticket';
    private static final String REASON_BLOCKED     = 'BlockedExists';
    private static final String REASON_HIGH_NS     = 'HighNotStartedRatio';
    private static final String REASON_LOW_PROG    = 'LowProgress';
    private static final String NOTICE_DATA_GAP    = 'DataGap';
    private static final String NOTICE_VISIBILITY  = 'VisibilityWarning';

    // ── 補足通知 ──────────────────────────────────────
    public class Notice {
        @InvocableVariable public String type;        // DataGap | VisibilityWarning
        @InvocableVariable public String level;       // Issue | Plan | Requirements | Ticket | All
        @InvocableVariable public String description;
    }
}
```

---

## 3. ステータス正規化仕様

| 入力値（TicketStatus GVSet） | 正規化後     | 備考                                          |
| ---------------------------- | ------------ | --------------------------------------------- |
| `TODO`                       | `NotStarted` | GVSetデフォルト値                             |
| `PENDING`                    | `NotStarted` | 保留中は未着手扱い                            |
| `WIP`                        | `InProgress` |                                               |
| `DONE`                       | `Done`       |                                               |
| `DROP`                       | `Blocked`    | 棄却・中断                                    |
| 未知値（将来追加値等）       | `NotStarted` | フォールバック + `notices.dataGaps` に1行記録 |

`Dev_Service__c.Status__c`（`OPEN/CLOSE`）は正規化対象外。`summary.devServiceStatus` にそのまま格納し、集計ロジックには影響させない。

**`Dev_Service__c = CLOSE` 時の挙動**:

- `progressRate` 算出は常に `ticket.done / ticket.total` で統一（CLOSE でも例外なし）
- `nextActions` は `BlockedExists` に該当する場合のみ `Ticket` レベルで提示し、それ以外は空配列（`[]`）を返す
- `summary.highlights` の先頭要素に `"このサービスはCLOSE状態です"` を含める

---

## 4. SOQL集計経路設計

すべてのオブジェクト間関係は Junction Object（MasterDetail × 2）経由のため、4段階のクエリで取得する。ループ内SOQL・DMLは禁止。

```
Dev_Service__c
  └─[Relation_Support2Issue__c.Dev_Service__c]─ Issue__c
       └─[Relation_Issue2Plan__c.Issue__c]─ TechActionPlan__c
            └─[Relation_Plan2Requirements__c.TechActionPlan__c]─ FunctionRequirements__c
                 └─[Relation_Requirements2Dev__c.FunctionRequirements__c]─ Dev_Ticket__c
```

```apex
// 0. Dev_Service__c 自体を取得（名前・ステータス）
Dev_Service__c svc = [
    SELECT Id, Name, Status__c
    FROM Dev_Service__c
    WHERE Id = :devServiceId
    WITH SECURITY_ENFORCED
    LIMIT 1
];

// 1. Issue 取得（Junction経由）
List<Relation_Support2Issue__c> si = [
    SELECT Issue__c, Issue__r.Name, Issue__r.Status__c
    FROM Relation_Support2Issue__c
    WHERE Dev_Service__c = :devServiceId
    WITH SECURITY_ENFORCED
];
Set<Id> issueIds = /* si から Issue__c を抽出 */;

// 2. TechActionPlan 取得
List<Relation_Issue2Plan__c> ip = [
    SELECT TechActionPlan__c, TechActionPlan__r.Name, TechActionPlan__r.Status__c
    FROM Relation_Issue2Plan__c
    WHERE Issue__c IN :issueIds
    WITH SECURITY_ENFORCED
];
Set<Id> planIds = /* ip から TechActionPlan__c を抽出 */;

// 3. FunctionRequirements 取得
List<Relation_Plan2Requirements__c> pr = [
    SELECT FunctionRequirements__c, FunctionRequirements__r.Name, FunctionRequirements__r.Status__c
    FROM Relation_Plan2Requirements__c
    WHERE TechActionPlan__c IN :planIds
    WITH SECURITY_ENFORCED
];
Set<Id> reqIds = /* pr から FunctionRequirements__c を抽出 */;

// 4. Dev_Ticket 取得
List<Relation_Requirements2Dev__c> rd = [
    SELECT Dev_Ticket__c, Dev_Ticket__r.Name, Dev_Ticket__r.Status__c
    FROM Relation_Requirements2Dev__c
    WHERE FunctionRequirements__c IN :reqIds
    WITH SECURITY_ENFORCED
];
```

**合計クエリ数**: 5（ガバナ制限 100 に対して余裕あり）

---

## 5. nextActions 決定ロジック

優先順位ルール（上位から評価し、最大3件で打ち切り）:

| 優先度 | 条件                                      | reason                | detail例                                                                |
| ------ | ----------------------------------------- | --------------------- | ----------------------------------------------------------------------- |
| 1      | いずれかの階層で `blocked > 0`            | `BlockedExists`       | `「Plan」階層にBlocked状態が2件あります。優先確認してください。`        |
| 2      | `notStarted / total > 0.5` の階層が存在   | `HighNotStartedRatio` | `「Ticket」の50%以上が未着手です。進め方を確認してください。`           |
| 3      | `progressRate < 30` かつ `inProgress > 0` | `LowProgress`         | `全体進捗が30%未満です。進行中Ticketのボトルネックを確認してください。` |
| —     | 上記に該当なし                            | 空配列（`[]`）を返す  | —                                                                      |

- 同一優先度で複数階層が該当する場合は `Issue → Plan → Requirements → Ticket` の順に上位から選出
- `recordId / recordName` は**最初の1件**のみセット。複数存在する場合は `detail` に件数を追記（例: `他2件`）

---

## 6. 出力JSON例

### 6-1. 正常系（OPEN, 全階層にデータあり）

```json
{
  "summary": {
    "devServiceId": "a01xx000000AAAA",
    "devServiceName": "CRM刷新PJ Phase1",
    "devServiceStatus": "OPEN",
    "totalItems": 10,
    "progressRate": 60.0,
    "highlights": ["6件完了", "2件進行中", "Blocked 1件あり"]
  },
  "counts": {
    "issue": {
      "notStarted": 1,
      "inProgress": 2,
      "done": 3,
      "blocked": 0,
      "total": 6
    },
    "plan": {
      "notStarted": 2,
      "inProgress": 3,
      "done": 4,
      "blocked": 1,
      "total": 10
    },
    "requirements": {
      "notStarted": 3,
      "inProgress": 2,
      "done": 8,
      "blocked": 0,
      "total": 13
    },
    "ticket": {
      "notStarted": 1,
      "inProgress": 2,
      "done": 6,
      "blocked": 1,
      "total": 10
    },
    "overall": {
      "notStarted": 7,
      "inProgress": 9,
      "done": 21,
      "blocked": 2,
      "total": 39
    }
  },
  "nextActions": [
    {
      "level": "Plan",
      "recordId": "a02xx000000BBBB",
      "recordName": "Plan-00003",
      "reason": "BlockedExists",
      "detail": "「Plan」階層にBlocked状態が1件あります。優先的に確認してください。"
    }
  ],
  "notices": []
}
```

### 6-2. CLOSE状態（集計は通常通り）

```json
{
  "summary": {
    "devServiceId": "a01xx000000CCCC",
    "devServiceName": "旧システム移行PJ",
    "devServiceStatus": "CLOSE",
    "totalItems": 15,
    "progressRate": 93.3,
    "highlights": ["このサービスはCLOSE状態です", "14件完了", "Blocked 1件残存"]
  },
  "counts": {
    "issue": {
      "notStarted": 0,
      "inProgress": 0,
      "done": 5,
      "blocked": 0,
      "total": 5
    },
    "plan": {
      "notStarted": 0,
      "inProgress": 0,
      "done": 8,
      "blocked": 0,
      "total": 8
    },
    "requirements": {
      "notStarted": 0,
      "inProgress": 0,
      "done": 12,
      "blocked": 0,
      "total": 12
    },
    "ticket": {
      "notStarted": 0,
      "inProgress": 0,
      "done": 14,
      "blocked": 1,
      "total": 15
    },
    "overall": {
      "notStarted": 0,
      "inProgress": 0,
      "done": 39,
      "blocked": 1,
      "total": 40
    }
  },
  "nextActions": [
    {
      "level": "Ticket",
      "recordId": "a04xx000000DDDD",
      "recordName": "Dev-00099",
      "reason": "BlockedExists",
      "detail": "CLOSEサービスにBlocked Ticketが残存しています。対応または棄却を確認してください。"
    }
  ],
  "notices": []
}
```

### 6-3. 欠損系（中間階層に孤立データあり）

```json
{
  "summary": {
    "devServiceId": "a01xx000000EEEE",
    "devServiceName": "新規受発注機能",
    "devServiceStatus": "OPEN",
    "totalItems": 8,
    "progressRate": 50.0,
    "highlights": ["4件完了", "データ欠損あり（詳細はnoticesを確認）"]
  },
  "counts": {
    "issue": {
      "notStarted": 2,
      "inProgress": 1,
      "done": 2,
      "blocked": 0,
      "total": 5
    },
    "plan": {
      "notStarted": 1,
      "inProgress": 1,
      "done": 2,
      "blocked": 0,
      "total": 4
    },
    "requirements": {
      "notStarted": 0,
      "inProgress": 2,
      "done": 4,
      "blocked": 0,
      "total": 6
    },
    "ticket": {
      "notStarted": 2,
      "inProgress": 2,
      "done": 4,
      "blocked": 0,
      "total": 8
    },
    "overall": {
      "notStarted": 5,
      "inProgress": 6,
      "done": 12,
      "blocked": 0,
      "total": 23
    }
  },
  "nextActions": [
    {
      "level": "Ticket",
      "recordId": null,
      "recordName": null,
      "countHint": 2,
      "reason": "HighNotStartedRatio",
      "detail": "「Ticket」の25%以上が未着手です。着手判断を確認してください。"
    }
  ],
  "notices": [
    {
      "type": "DataGap",
      "level": "Issue",
      "description": "Plan未設定のIssueが2件あります。これらのIssue配下は集計から除外しました。"
    }
  ]
}
```

---

## 7. 制約・前提

| 項目                     | 制約値                                                     | 備考                                                                                   |
| ------------------------ | ---------------------------------------------------------- | -------------------------------------------------------------------------------------- |
| nextActions 上限         | 最大3件                                                    | 安定した会話応答のため                                                                 |
| SOQL発行数               | 5クエリ固定                                                | 0除算 → progressRate = 0 で返す                                                        |
| ガバナ上限行数           | 各Junctionクエリで最大 50,000行                            | PoCでは問題なし                                                                        |
| `WITH SECURITY_ENFORCED` | 全クエリに必須                                             | FLS不足は例外終了（PoC範囲）。graceful degrade は将来検討。PermSet付与を前提運用とする |
| 権限で不可視のレコード   | 合計から自動除外（SECURITY_ENFORCED動作）                  | `notices.visibilityWarnings` に概要を記録                                              |
| `counts` の返却キー      | 常に全キー（issue/plan/requirements/ticket/overall）を返す | データなし時は 0 埋め。テンプレがキー存在を前提にできるようにする                      |
| `counts.overall` 整合    | `byObject` 4階層の合算と一致すること                       | ユニットテストで byObject 合算 = overall を必ず検証する                                |

---

## 8. 実装ガイド（次工程参照用）

> ℹ️ このセクションは実装時の指针であり、本ドキュメントの確定とは別管理です。実装ファイルは `force-app/main/default/classes/DevServiceProgressAction.cls`。

### 8-1. 正規化関数

```apex
private static String normalize(String raw) {
    if (raw == 'WIP')                          return 'InProgress';
    if (raw == 'DONE')                         return 'Done';
    if (raw == 'DROP')                         return 'Blocked';
    if (raw == 'TODO' || raw == 'PENDING')     return 'NotStarted';
    // 未知値: NotStartフォールバック + DataGap通知フラグを呈返値側で記録
    unknownStatuses.add(raw);
    return 'NotStarted';
}
```

未知値が発生した場合は `notices`（type=DataGap）に 1 行追加する。

### 8-2. 集計フロー

```
1. [SOQLクエリ 0] Dev_Service__c を取得（Id, Name, Status__c）
2. [SOQLクエリ 1] Relation_Support2Issue__c → Issue Idセットと Status Map<Id,String> を構築
3. [SOQLクエリ 2] Relation_Issue2Plan__c → Plan Idセットと Status Map を構築
4. [SOQLクエリ 3] Relation_Plan2Requirements__c → Req Idセットと Status Map を構築
5. [SOQLクエリ 4] Relation_Requirements2Dev__c → Ticket Idセットと Status Map を構築
6. 各 Map から ObjectCounts に集計（normalize() 進めてカウントアップ）
7. overall = 4階層の ObjectCounts を加算
8. progressRate 算出: total=0 なら 0.0, それ以外は setScale(1, HALF_UP)
9. highlights 生成（最大3要素リスト）
10. nextActions 判定（Blocked → HighNotStartedRatio → LowProgress 順）
11. notices に DataGap / VisibilityWarning を当てはめる
```

**ループ内SOQL・ DML禁止**。クエリ数は 5 固定。

### 8-3. 欠据検知

| ケース                           | 処理                                                   |
| -------------------------------- | ------------------------------------------------------ |
| `issueIds` が空セット            | クエリ 2以降をスキップ　1行目の notices に DataGap記録 |
| Junction不在で子が 0 件          | counts 0埋めで返す。notices の DataGap に記録          |
| Junction譌で同一子レコードが重複 | Set<Id> で dedup してから集計                          |

### 8-4. nextActions 実装骨子

```
 List<NextActionItem> result = new List<NextActionItem>();

 // 優先度 1: Blocked存在
 for (String level : new List<String>{LEVEL_ISSUE, LEVEL_PLAN, LEVEL_REQ, LEVEL_TICKET}) {
     ObjectCounts c = countsMap.get(level);
     if (c.blocked > 0 && result.size() < 3) {
         result.add(buildItem(level, REASON_BLOCKED, c.blocked));
     }
 }

 // 優先度 2: NotStarted割合 > 50%
 if (result.size() < 3) { ... }

 // 優先度 3: progressRate < 30 かつ inProgress > 0
 if (result.size() < 3) { ... }
```

### 8-5. highlights 生成ルール

1. `devServiceStatus == 'CLOSE'` の場合: 先頭要素に `'このサービスはCLOSE状態です'` を必ず入れる
2. `ticket.done + '件完了'`
3. `ticket.inProgress > 0` なら `inProgress + '件進行中'`、`ticket.blocked > 0` なら `'Blocked ' + blocked + '件あり'`（計 3 要素まで）
