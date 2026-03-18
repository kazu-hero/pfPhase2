# Apex集計ロジック設計: DevServiceProgressAction

> **ステータス**: 確定（2026-03-14）
> 本ドキュメントは `01_ApexAction_IF定義.md` のDTOを前提とし、`DevServiceProgressAction.cls` の実装に直接対応する。

---

## 1. privateメソッド分割設計

| メソッド                                                 | 可視性           | 役割                                                                   |
| -------------------------------------------------------- | ---------------- | ---------------------------------------------------------------------- |
| `getProgress(List<Request>)`                             | `public static`  | @InvocableMethod エントリ。requests をループして `processOne()` を呼ぶ |
| `processOne(Id, List<Notice>)`                           | `private static` | 1レコード分の集計処理本体                                              |
| `buildEmptyResult(Dev_Service__c, List<Notice>)`         | `private static` | Issue未接続時のゼロ埋め結果を構築して早期返却                          |
| `normalize(String, List<Notice>)`                        | `private static` | ステータス正規化。未知値はNotStartedフォールバック + DataGap通知       |
| `buildObjectCounts(Map<Id,String>)`                      | `private static` | 正規化済みstatusMapからObjectCountsを生成                              |
| `addCounts(ObjectCounts, ObjectCounts)`                  | `private static` | 2つのObjectCountsを加算してoverallを構築                               |
| `calcProgressRate(ObjectCounts)`                         | `private static` | progressRate算出（0割ガード、scale=1 HALF_UP）                         |
| `buildNextActions(Map, Map, Decimal, String)`            | `private static` | 3優先度ルールでNextActionItemリストを生成（最大3件）                   |
| `buildHighlights(ObjectCounts, String)`                  | `private static` | highlightsリスト生成（最大3要素）                                      |
| `buildItem(String, String, Integer, Id, String, String)` | `private static` | NextActionItemファクトリ                                               |
| `buildNotice(String, String, String)`                    | `private static` | Noticeファクトリ                                                       |

---

## 2. 内部データ型

```apex
private class RecordRef {
  Id recordId;
  String recordName;
  RecordRef(Id i, String n) {
    this.recordId = i;
    this.recordName = n;
  }
}
```

### 2-1. 定数定義（実装時はハードコード禁止）

`DevServiceProgressAction.cls` 内で以下を `private static final String` として実体定義し、`normalize()` / `buildNextActions()` / `buildNotice()` で共通利用する。

```apex
private static final String LEVEL_ISSUE = 'Issue';
private static final String LEVEL_PLAN = 'Plan';
private static final String LEVEL_REQ = 'Requirements';
private static final String LEVEL_TICKET = 'Ticket';
private static final String NOTICE_LEVEL_ALL = 'All';
private static final String STATUS_OPEN = 'OPEN';
private static final String STATUS_CLOSE = 'CLOSE';

private static final String REASON_BLOCKED = 'BlockedExists';
private static final String REASON_HIGH_NS = 'HighNotStartedRatio';
private static final String REASON_LOW_PROG = 'LowProgress';

private static final String NOTICE_DATA_GAP = 'DataGap';
private static final String NOTICE_VISIBILITY = 'VisibilityWarning';

private static final String NORM_NOT_STARTED = 'NotStarted';
private static final String NORM_IN_PROGRESS = 'InProgress';
private static final String NORM_DONE = 'Done';
private static final String NORM_BLOCKED = 'Blocked';
```

---

## 3. getProgress() エントリポイント

```apex
@InvocableMethod(
    label='Get Dev Service Progress',
    description='Dev_Service__c を起点に5階層の進捗を集計して返す'
)
public static List<ProgressResult> getProgress(List<Request> requests) {
    List<ProgressResult> results = new List<ProgressResult>();
    for (Request req : requests) {
        List<Notice> notices = new List<Notice>();
        results.add(processOne(req.devServiceId, notices));
    }
    return results;
}
```

---

## 4. processOne() 集計処理本体

### 4-1. SOQL 0: Dev_Service\_\_c 取得

```apex
Dev_Service__c svc = [
    SELECT Id, Name, Status__c
    FROM Dev_Service__c
    WHERE Id = :devServiceId
    WITH SECURITY_ENFORCED
    LIMIT 1
];
```

`Dev_Service__c` が存在しない場合は `System.QueryException` をそのままスロー（PoC範囲）。

### 4-2. SOQL 1: Issue収集（dedup + firstBlocked追跡）

```apex
Map<Id, String> issueStatusMap = new Map<Id, String>();
RecordRef firstBlockedIssue = null;

List<Relation_Support2Issue__c> si = [
    SELECT Issue__c, Issue__r.Name, Issue__r.Status__c
    FROM Relation_Support2Issue__c
    WHERE Dev_Service__c = :devServiceId
    WITH SECURITY_ENFORCED
];
for (Relation_Support2Issue__c r : si) {
    Id issueId = r.Issue__c;
    if (issueId == null || issueStatusMap.containsKey(issueId)) continue;

    String normalized = normalize(r.Issue__r.Status__c, notices);
    issueStatusMap.put(issueId, normalized);

    if (normalized == NORM_BLOCKED && firstBlockedIssue == null) {
        firstBlockedIssue = new RecordRef(issueId, r.Issue__r.Name);
    }
}
Set<Id> issueIds = issueStatusMap.keySet();
```

### 4-3. 欠損チェック（Issueなし）

```apex
if (issueIds.isEmpty()) {
    notices.add(buildNotice(NOTICE_DATA_GAP, LEVEL_ISSUE,
        'このDev_Serviceに関連するIssueが存在しません。集計は全件0で返します。'));
    return buildEmptyResult(svc, notices);
}
```

### 4-4. SOQL 2-4: Plan / Requirements / Ticket収集

- 前段のIdセットが空なら後段SOQLをスキップ
- 各段で dedup（`containsKey`）
- 各段で firstBlocked を1件だけ保持

```apex
Map<Id, String> planStatusMap = new Map<Id, String>();
RecordRef firstBlockedPlan = null;

List<Relation_Issue2Plan__c> ip = [
    SELECT TechActionPlan__c, TechActionPlan__r.Name, TechActionPlan__r.Status__c
    FROM Relation_Issue2Plan__c
    WHERE Issue__c IN :issueIds
    WITH SECURITY_ENFORCED
];
for (Relation_Issue2Plan__c r : ip) {
    Id planId = r.TechActionPlan__c;
    if (planId == null || planStatusMap.containsKey(planId)) continue;

    String normalized = normalize(r.TechActionPlan__r.Status__c, notices);
    planStatusMap.put(planId, normalized);
    if (normalized == NORM_BLOCKED && firstBlockedPlan == null) {
        firstBlockedPlan = new RecordRef(planId, r.TechActionPlan__r.Name);
    }
}
Set<Id> planIds = planStatusMap.keySet();
if (planIds.isEmpty()) {
    notices.add(buildNotice(NOTICE_DATA_GAP, LEVEL_PLAN,
        'Plan未接続のIssueがあります。Plan以下の集計は0件で処理します。'));
}

Map<Id, String> reqStatusMap = new Map<Id, String>();
RecordRef firstBlockedReq = null;
if (!planIds.isEmpty()) {
    List<Relation_Plan2Requirements__c> pr = [
        SELECT FunctionRequirements__c, FunctionRequirements__r.Name, FunctionRequirements__r.Status__c
        FROM Relation_Plan2Requirements__c
        WHERE TechActionPlan__c IN :planIds
        WITH SECURITY_ENFORCED
    ];
    for (Relation_Plan2Requirements__c r : pr) {
        Id reqId = r.FunctionRequirements__c;
        if (reqId == null || reqStatusMap.containsKey(reqId)) continue;

        String normalized = normalize(r.FunctionRequirements__r.Status__c, notices);
        reqStatusMap.put(reqId, normalized);
        if (normalized == NORM_BLOCKED && firstBlockedReq == null) {
            firstBlockedReq = new RecordRef(reqId, r.FunctionRequirements__r.Name);
        }
    }
    if (reqStatusMap.isEmpty()) {
        notices.add(buildNotice(NOTICE_DATA_GAP, LEVEL_REQ,
            'Requirements未接続のPlanがあります。Requirements以下の集計は0件で処理します。'));
    }
}
Set<Id> reqIds = reqStatusMap.keySet();

Map<Id, String> ticketStatusMap = new Map<Id, String>();
RecordRef firstBlockedTicket = null;
if (!reqIds.isEmpty()) {
    List<Relation_Requirements2Dev__c> rd = [
        SELECT Dev_Ticket__c, Dev_Ticket__r.Name, Dev_Ticket__r.Status__c
        FROM Relation_Requirements2Dev__c
        WHERE FunctionRequirements__c IN :reqIds
        WITH SECURITY_ENFORCED
    ];
    for (Relation_Requirements2Dev__c r : rd) {
        Id ticketId = r.Dev_Ticket__c;
        if (ticketId == null || ticketStatusMap.containsKey(ticketId)) continue;

        String normalized = normalize(r.Dev_Ticket__r.Status__c, notices);
        ticketStatusMap.put(ticketId, normalized);
        if (normalized == NORM_BLOCKED && firstBlockedTicket == null) {
            firstBlockedTicket = new RecordRef(ticketId, r.Dev_Ticket__r.Name);
        }
    }
    if (ticketStatusMap.isEmpty()) {
        notices.add(buildNotice(NOTICE_DATA_GAP, LEVEL_TICKET,
            'Ticket未接続のRequirementsがあります。Ticket集計は0件で処理します。'));
    }
}
```

### 4-5. DTO組み立て

```apex
ObjectCounts issueCounts = buildObjectCounts(issueStatusMap);
ObjectCounts planCounts = buildObjectCounts(planStatusMap);
ObjectCounts reqCounts = buildObjectCounts(reqStatusMap);
ObjectCounts ticketCounts = buildObjectCounts(ticketStatusMap);
ObjectCounts overallCounts = addCounts(addCounts(addCounts(issueCounts, planCounts), reqCounts), ticketCounts);

Decimal progressRate = calcProgressRate(ticketCounts);

Summary summary = new Summary();
summary.devServiceId = svc.Id;
summary.devServiceName = svc.Name;
summary.devServiceStatus = svc.Status__c;
summary.totalItems = ticketCounts.total;
summary.progressRate = progressRate;
summary.highlights = buildHighlights(ticketCounts, svc.Status__c);

Counts counts = new Counts();
counts.issue = issueCounts;
counts.plan = planCounts;
counts.requirements = reqCounts;
counts.ticket = ticketCounts;
counts.overall = overallCounts;

Map<String, ObjectCounts> countsMap = new Map<String, ObjectCounts>{
    LEVEL_ISSUE => issueCounts,
    LEVEL_PLAN => planCounts,
    LEVEL_REQ => reqCounts,
    LEVEL_TICKET => ticketCounts
};
Map<String, RecordRef> blockedMap = new Map<String, RecordRef>{
    LEVEL_ISSUE => firstBlockedIssue,
    LEVEL_PLAN => firstBlockedPlan,
    LEVEL_REQ => firstBlockedReq,
    LEVEL_TICKET => firstBlockedTicket
};

ProgressResult result = new ProgressResult();
result.summary = summary;
result.counts = counts;
result.nextActions = buildNextActions(countsMap, blockedMap, progressRate, svc.Status__c);
result.notices = notices;
return result;
```

---

## 5. buildEmptyResult()（全件0埋め）

```apex
private static ProgressResult buildEmptyResult(Dev_Service__c svc, List<Notice> notices) {
    ObjectCounts zero = buildObjectCounts(new Map<Id, String>());

    Summary summary = new Summary();
    summary.devServiceId = svc.Id;
    summary.devServiceName = svc.Name;
    summary.devServiceStatus = svc.Status__c;
    summary.totalItems = 0;
    summary.progressRate = 0.0;
    summary.highlights = new List<String>{'0件完了'};

    Counts counts = new Counts();
    counts.issue = zero;
    counts.plan = zero;
    counts.requirements = zero;
    counts.ticket = zero;
    counts.overall = zero;

    ProgressResult result = new ProgressResult();
    result.summary = summary;
    result.counts = counts;
    result.nextActions = new List<NextActionItem>();
    result.notices = notices;
    return result;
}
```

---

## 6. normalize()（正規化 + 未知値通知）

```apex
private static String normalize(String raw, List<Notice> notices) {
    if (String.isBlank(raw)) {
        notices.add(buildNotice(NOTICE_DATA_GAP, NOTICE_LEVEL_ALL,
            '空のステータス値を検出しました。NotStartedとして集計します。'));
        return NORM_NOT_STARTED;
    }

    if (raw == 'WIP') return NORM_IN_PROGRESS;
    if (raw == 'DONE') return NORM_DONE;
    if (raw == 'DROP') return NORM_BLOCKED;
    if (raw == 'TODO' || raw == 'PENDING') return NORM_NOT_STARTED;

    notices.add(buildNotice(NOTICE_DATA_GAP, NOTICE_LEVEL_ALL,
        '未知のステータス値を検出しました: ' + raw + '。NotStartedとして集計します。'));
    return NORM_NOT_STARTED;
}
```

---

## 7. 件数計算ユーティリティ

```apex
private static ObjectCounts buildObjectCounts(Map<Id, String> statusById) {
    ObjectCounts c = new ObjectCounts();
    c.notStarted = 0;
    c.inProgress = 0;
    c.done = 0;
    c.blocked = 0;
    c.total = 0;

    for (String normalized : statusById.values()) {
        c.total++;
        if (normalized == NORM_NOT_STARTED) c.notStarted++;
        else if (normalized == NORM_IN_PROGRESS) c.inProgress++;
        else if (normalized == NORM_DONE) c.done++;
        else if (normalized == NORM_BLOCKED) c.blocked++;
    }
    return c;
}

private static ObjectCounts addCounts(ObjectCounts a, ObjectCounts b) {
    ObjectCounts c = new ObjectCounts();
    c.notStarted = a.notStarted + b.notStarted;
    c.inProgress = a.inProgress + b.inProgress;
    c.done = a.done + b.done;
    c.blocked = a.blocked + b.blocked;
    c.total = a.total + b.total;
    return c;
}

private static Decimal calcProgressRate(ObjectCounts ticketCounts) {
    if (ticketCounts.total == 0) return 0.0;
    Decimal rate = (ticketCounts.done * 100.0) / ticketCounts.total;
    return rate.setScale(1, System.RoundingMode.HALF_UP);
}
```

---

## 8. buildNextActions()（推奨抽出）

```apex
private static List<NextActionItem> buildNextActions(
    Map<String, ObjectCounts> countsMap,
    Map<String, RecordRef> blockedMap,
    Decimal progressRate,
    String devServiceStatus
) {
    List<NextActionItem> out = new List<NextActionItem>();
    List<String> levelOrder = new List<String>{
        LEVEL_ISSUE, LEVEL_PLAN, LEVEL_REQ, LEVEL_TICKET
    };

    // 優先度1: blocked > 0（OPEN/CLOSE共通）
    for (String level : levelOrder) {
        if (out.size() >= 3) break;
        ObjectCounts c = countsMap.get(level);
        if (c == null) continue;
        if (c.blocked > 0) {
            RecordRef ref = blockedMap.get(level);
            Id rid = ref != null ? ref.recordId : null;
            String rname = ref != null ? ref.recordName : null;
            String detail = '「' + level + '」階層にBlocked状態が' + c.blocked + '件あります。優先的に確認してください。';
            out.add(buildItem(level, REASON_BLOCKED, c.blocked, rid, rname, detail));
        }
    }

    // CLOSE時は優先度1のみ
    if (devServiceStatus == STATUS_CLOSE) return out;

    // 優先度2: notStarted/total > 0.5
    if (out.size() < 3) {
        for (String level : levelOrder) {
            if (out.size() >= 3) break;
            ObjectCounts c = countsMap.get(level);
            if (c == null) continue;
            if (c.total > 0 && ((Decimal)c.notStarted / c.total) > 0.5) {
                Integer pct = Integer.valueOf(c.notStarted * 100 / c.total);
                String detail = '「' + level + '」階層の' + pct + '%が未着手です。進め方を確認してください。';
                out.add(buildItem(level, REASON_HIGH_NS, c.notStarted, null, null, detail));
            }
        }
    }

    // 優先度3: progressRate < 30 かつ ticket.inProgress > 0
    if (out.size() < 3) {
        ObjectCounts tc = countsMap.get(LEVEL_TICKET);
        if (tc != null && progressRate < 30 && tc.inProgress > 0) {
            String detail = '全体進捗が' + progressRate + '%未満です。進行中Ticketのボトルネックを確認してください。';
            out.add(buildItem(LEVEL_TICKET, REASON_LOW_PROG, tc.inProgress, null, null, detail));
        }
    }

    return out;
}
```

---

## 9. buildHighlights()（3要素まで）

```apex
private static List<String> buildHighlights(ObjectCounts ticketCounts, String devServiceStatus) {
    List<String> h = new List<String>();

    if (devServiceStatus == STATUS_CLOSE) {
        h.add('このサービスはCLOSE状態です');
    }
    if (h.size() < 3) h.add(ticketCounts.done + '件完了');
    if (h.size() < 3 && ticketCounts.inProgress > 0) h.add(ticketCounts.inProgress + '件進行中');
    if (h.size() < 3 && ticketCounts.blocked > 0) h.add('Blocked ' + ticketCounts.blocked + '件あり');
    if (h.size() < 3 && ticketCounts.notStarted > 0) h.add(ticketCounts.notStarted + '件未着手');

    return h;
}
```

---

## 10. buildItem() / buildNotice()

```apex
private static NextActionItem buildItem(
    String level,
    String reason,
    Integer countHint,
    Id recordId,
    String recordName,
    String detail
) {
    NextActionItem item = new NextActionItem();
    item.level = level;
    item.reason = reason;
    item.countHint = countHint;
    item.recordId = recordId;
    item.recordName = recordName;
    item.detail = detail;
    return item;
}

private static Notice buildNotice(String type, String level, String description) {
    Notice n = new Notice();
    n.type = type;
    n.level = level;
    n.description = description;
    return n;
}
```

---

## 11. 欠損検知フロー完全定義

| シチュエーション   | 検知タイミング | 処理                                      | notices.type | notices.level |
| ------------------ | -------------- | ----------------------------------------- | ------------ | ------------- |
| Dev_Service不存在  | SOQL 0         | QueryExceptionをそのままスロー（PoC範囲） | -            | -             |
| Issue未接続        | SOQL 1後       | `buildEmptyResult()` で即返却             | DataGap      | Issue         |
| Plan未接続         | SOQL 2後       | SOQL 3-4スキップ、0埋め                   | DataGap      | Plan          |
| Requirements未接続 | SOQL 3後       | SOQL 4スキップ、0埋め                     | DataGap      | Requirements  |
| Ticket未接続       | SOQL 4後       | ticketを0埋め                             | DataGap      | Ticket        |
| Junction重複       | 各段ループ     | `containsKey()` でdedup                   | -            | -             |
| 未知ステータス     | `normalize()`  | NotStartedフォールバック + notice追記     | DataGap      | All           |
| FLS不足            | 各SOQL         | QueryExceptionをそのままスロー（PoC範囲） | -            | -             |

---

## 12. 実装チェックリスト

- [ ] ループ内SOQL・DMLなし
- [ ] SOQLクエリは5本固定、全て `WITH SECURITY_ENFORCED`
- [ ] ObjectCountsのInteger項目を必ず0初期化
- [ ] dedup (`containsKey`) をIssue/Plan/Req/Ticketで実施
- [ ] `issueIds` 空で早期返却
- [ ] `planIds`/`reqIds` 空なら後段SOQLをスキップ
- [ ] `progressRate`: `total=0` なら `0.0`
- [ ] `progressRate`: `scale=1`, `HALF_UP`
- [ ] `highlights` は最大3要素
- [ ] `nextActions` は最大3件
- [ ] CLOSE時は優先度1のみ（優先度2/3を実行しない）
- [ ] `counts.overall` が4階層合算と一致する（テストで検証）

---

## 13. ユニットテスト観点（推奨）

### 13-1. 正常系

- 代表データで `issue/plan/requirements/ticket/overall` の件数整合を検証
- `progressRate = ticket.done / ticket.total` の丸め（scale=1, HALF_UP）を検証
- `highlights` が3要素以内であることを検証

### 13-2. 欠損系

- Issueなし: 早期ゼロ返却 + `Notice(DataGap, Issue)`
- Plan未接続: Plan/Req/Ticket が0件 + `Notice(DataGap, Plan)`
- Requirements未接続: Req/Ticket が0件 + `Notice(DataGap, Requirements)`
- Ticket未接続: Ticketが0件 + `Notice(DataGap, Ticket)`
- 未知/空ステータス: `NotStarted` カウント増 + `Notice(DataGap, All)`

### 13-3. CLOSE系

- `nextActions` は `BlockedExists` のみ評価（優先度2・3は実行しない）
- `highlights` 先頭に `このサービスはCLOSE状態です` が入る

### 13-4. nextActions優先度

- 優先度1: `blocked > 0` を `Issue -> Plan -> Requirements -> Ticket` 順で最大3件
- 優先度2: `notStarted / total > 0.5` のみ該当（`>= 0.5` ではない）
- 優先度3: `progressRate < 30` かつ `ticket.inProgress > 0`
- `recordId/recordName` は代表1件、複数は `countHint/detail` で補足

### 13-5. overall整合

- `overall == issue + plan + requirements + ticket` を厳密一致で検証

### 13-6. セキュリティ

- `WITH SECURITY_ENFORCED` 前提で可視レコードのみ母数に入るケースを検証
- FLS不足例外はPoC範囲外（例外終了前提）
