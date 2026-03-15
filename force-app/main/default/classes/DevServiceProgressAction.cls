public with sharing class DevServiceProgressAction {
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

    private class RecordRef {
        Id recordId;
        String recordName;

        RecordRef(Id i, String n) {
            this.recordId = i;
            this.recordName = n;
        }
    }

    @InvocableMethod(
        label='Get Dev Service Progress'
        description='Dev_Service__c を起点に5階層の進捗を集計して返す'
    )
    public static List<ProgressResult> getProgress(List<Request> requests) {
        List<ProgressResult> results = new List<ProgressResult>();
        if (requests == null) {
            return results;
        }

        for (Request req : requests) {
            if (req == null || req.devServiceId == null) {
                throw new IllegalArgumentException('devServiceId is required.');
            }
            List<Notice> notices = new List<Notice>();
            results.add(processOne(req.devServiceId, notices));
        }

        return results;
    }

    private static ProgressResult processOne(Id devServiceId, List<Notice> notices) {
        Set<String> unknownStatusNoticeKeys = new Set<String>();

        Dev_Service__c svc = [
            SELECT Id, Name, Status__c
            FROM Dev_Service__c
            WHERE Id = :devServiceId
            WITH SECURITY_ENFORCED
            LIMIT 1
        ];

        Map<Id, String> issueStatusMap = new Map<Id, String>();
        RecordRef firstBlockedIssue = null;

        List<Relation_Support2Issue__c> issueRelations = [
            SELECT Issue__c, Issue__r.Name, Issue__r.Status__c
            FROM Relation_Support2Issue__c
            WHERE Dev_Service__c = :devServiceId
            WITH SECURITY_ENFORCED
        ];

        for (Relation_Support2Issue__c rel : issueRelations) {
            Id issueId = rel.Issue__c;
            if (issueId == null || issueStatusMap.containsKey(issueId)) {
                continue;
            }
            String normalized = normalize(rel.Issue__r.Status__c, notices, unknownStatusNoticeKeys);
            issueStatusMap.put(issueId, normalized);
            if (normalized == NORM_BLOCKED && firstBlockedIssue == null) {
                firstBlockedIssue = new RecordRef(issueId, rel.Issue__r.Name);
            }
        }

        Set<Id> issueIds = issueStatusMap.keySet();
        if (issueIds.isEmpty()) {
            notices.add(buildNotice(
                NOTICE_DATA_GAP,
                LEVEL_ISSUE,
                'このDev_Serviceに関連するIssueが存在しません。集計は全件0で返します。'
            ));
            return buildEmptyResult(svc, notices);
        }

        Map<Id, String> planStatusMap = new Map<Id, String>();
        RecordRef firstBlockedPlan = null;

        List<Relation_Issue2Plan__c> planRelations = [
            SELECT TechActionPlan__c, TechActionPlan__r.Name, TechActionPlan__r.Status__c
            FROM Relation_Issue2Plan__c
            WHERE Issue__c IN :issueIds
            WITH SECURITY_ENFORCED
        ];

        for (Relation_Issue2Plan__c rel : planRelations) {
            Id planId = rel.TechActionPlan__c;
            if (planId == null || planStatusMap.containsKey(planId)) {
                continue;
            }
            String normalized = normalize(rel.TechActionPlan__r.Status__c, notices, unknownStatusNoticeKeys);
            planStatusMap.put(planId, normalized);
            if (normalized == NORM_BLOCKED && firstBlockedPlan == null) {
                firstBlockedPlan = new RecordRef(planId, rel.TechActionPlan__r.Name);
            }
        }

        Set<Id> planIds = planStatusMap.keySet();
        if (planIds.isEmpty()) {
            notices.add(buildNotice(
                NOTICE_DATA_GAP,
                LEVEL_PLAN,
                'Plan未接続のIssueがあります。Plan以下の集計は0件で処理します。'
            ));
        }

        Map<Id, String> reqStatusMap = new Map<Id, String>();
        RecordRef firstBlockedReq = null;

        if (!planIds.isEmpty()) {
            List<Relation_Plan2Requirements__c> reqRelations = [
                SELECT FunctionRequirements__c, FunctionRequirements__r.Name, FunctionRequirements__r.Status__c
                FROM Relation_Plan2Requirements__c
                WHERE TechActionPlan__c IN :planIds
                WITH SECURITY_ENFORCED
            ];

            for (Relation_Plan2Requirements__c rel : reqRelations) {
                Id reqId = rel.FunctionRequirements__c;
                if (reqId == null || reqStatusMap.containsKey(reqId)) {
                    continue;
                }
                String normalized = normalize(rel.FunctionRequirements__r.Status__c, notices, unknownStatusNoticeKeys);
                reqStatusMap.put(reqId, normalized);
                if (normalized == NORM_BLOCKED && firstBlockedReq == null) {
                    firstBlockedReq = new RecordRef(reqId, rel.FunctionRequirements__r.Name);
                }
            }

            if (reqStatusMap.isEmpty()) {
                notices.add(buildNotice(
                    NOTICE_DATA_GAP,
                    LEVEL_REQ,
                    'Requirements未接続のPlanがあります。Requirements以下の集計は0件で処理します。'
                ));
            }
        }

        Set<Id> reqIds = reqStatusMap.keySet();

        Map<Id, String> ticketStatusMap = new Map<Id, String>();
        RecordRef firstBlockedTicket = null;

        if (!reqIds.isEmpty()) {
            List<Relation_Requirements2Dev__c> ticketRelations = [
                SELECT Dev_Ticket__c, Dev_Ticket__r.Name, Dev_Ticket__r.Status__c
                FROM Relation_Requirements2Dev__c
                WHERE FunctionRequirements__c IN :reqIds
                WITH SECURITY_ENFORCED
            ];

            for (Relation_Requirements2Dev__c rel : ticketRelations) {
                Id ticketId = rel.Dev_Ticket__c;
                if (ticketId == null || ticketStatusMap.containsKey(ticketId)) {
                    continue;
                }
                String normalized = normalize(rel.Dev_Ticket__r.Status__c, notices, unknownStatusNoticeKeys);
                ticketStatusMap.put(ticketId, normalized);
                if (normalized == NORM_BLOCKED && firstBlockedTicket == null) {
                    firstBlockedTicket = new RecordRef(ticketId, rel.Dev_Ticket__r.Name);
                }
            }

            if (ticketStatusMap.isEmpty()) {
                notices.add(buildNotice(
                    NOTICE_DATA_GAP,
                    LEVEL_TICKET,
                    'Ticket未接続のRequirementsがあります。Ticket集計は0件で処理します。'
                ));
            }
        }

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
    }

    private static ProgressResult buildEmptyResult(Dev_Service__c svc, List<Notice> notices) {
        Summary summary = new Summary();
        summary.devServiceId = svc.Id;
        summary.devServiceName = svc.Name;
        summary.devServiceStatus = svc.Status__c;
        summary.totalItems = 0;
        summary.progressRate = 0.0;
        summary.highlights = buildHighlights(zeroCounts(), svc.Status__c);

        Counts counts = new Counts();
        counts.issue = zeroCounts();
        counts.plan = zeroCounts();
        counts.requirements = zeroCounts();
        counts.ticket = zeroCounts();
        counts.overall = zeroCounts();

        ProgressResult result = new ProgressResult();
        result.summary = summary;
        result.counts = counts;
        result.nextActions = new List<NextActionItem>();
        result.notices = notices;
        return result;
    }

    private static String normalize(String raw, List<Notice> notices, Set<String> unknownStatusNoticeKeys) {
        if (String.isBlank(raw)) {
            if (!unknownStatusNoticeKeys.contains('BLANK')) {
                notices.add(buildNotice(
                    NOTICE_DATA_GAP,
                    NOTICE_LEVEL_ALL,
                    '空のステータス値を検出しました。NotStartedとして集計します。'
                ));
                unknownStatusNoticeKeys.add('BLANK');
            }
            return NORM_NOT_STARTED;
        }

        String value = raw.trim().toUpperCase();

        if (value == 'WIP') {
            return NORM_IN_PROGRESS;
        }
        if (value == 'DONE') {
            return NORM_DONE;
        }
        if (value == 'DROP') {
            return NORM_BLOCKED;
        }
        if (value == 'TODO' || value == 'PENDING') {
            return NORM_NOT_STARTED;
        }

        if (!unknownStatusNoticeKeys.contains(value)) {
            notices.add(buildNotice(
                NOTICE_DATA_GAP,
                NOTICE_LEVEL_ALL,
                '未知のステータス値を検出しました: ' + raw + '。NotStartedとして集計します。'
            ));
            unknownStatusNoticeKeys.add(value);
        }
        return NORM_NOT_STARTED;
    }

    private static ObjectCounts buildObjectCounts(Map<Id, String> statusById) {
        ObjectCounts counts = zeroCounts();

        for (String normalized : statusById.values()) {
            counts.total++;
            if (normalized == NORM_NOT_STARTED) {
                counts.notStarted++;
            } else if (normalized == NORM_IN_PROGRESS) {
                counts.inProgress++;
            } else if (normalized == NORM_DONE) {
                counts.done++;
            } else if (normalized == NORM_BLOCKED) {
                counts.blocked++;
            }
        }

        return counts;
    }

    private static ObjectCounts addCounts(ObjectCounts a, ObjectCounts b) {
        ObjectCounts merged = zeroCounts();
        merged.notStarted = a.notStarted + b.notStarted;
        merged.inProgress = a.inProgress + b.inProgress;
        merged.done = a.done + b.done;
        merged.blocked = a.blocked + b.blocked;
        merged.total = a.total + b.total;
        return merged;
    }

    private static Decimal calcProgressRate(ObjectCounts ticketCounts) {
        if (ticketCounts.total == 0) {
            return 0.0;
        }
        Decimal rate = (ticketCounts.done * 100.0) / ticketCounts.total;
        return rate.setScale(1, System.RoundingMode.HALF_UP);
    }

    private static List<NextActionItem> buildNextActions(
        Map<String, ObjectCounts> countsMap,
        Map<String, RecordRef> blockedMap,
        Decimal progressRate,
        String devServiceStatus
    ) {
        List<NextActionItem> out = new List<NextActionItem>();
        List<String> levelOrder = new List<String>{ LEVEL_ISSUE, LEVEL_PLAN, LEVEL_REQ, LEVEL_TICKET };

        for (String level : levelOrder) {
            if (out.size() >= 3) {
                break;
            }
            ObjectCounts c = countsMap.get(level);
            if (c == null || c.blocked <= 0) {
                continue;
            }

            RecordRef ref = blockedMap.get(level);
            Id recordId = ref != null ? ref.recordId : null;
            String recordName = ref != null ? ref.recordName : null;
            String detail = '「' + level + '」階層にBlocked状態が' + c.blocked + '件あります。優先的に確認してください。';
            out.add(buildItem(level, REASON_BLOCKED, c.blocked, recordId, recordName, detail));
        }

        if (devServiceStatus == STATUS_CLOSE) {
            return out;
        }

        if (out.size() < 3) {
            for (String level : levelOrder) {
                if (out.size() >= 3) {
                    break;
                }
                ObjectCounts c = countsMap.get(level);
                if (c == null || c.total == 0) {
                    continue;
                }
                Decimal ratio = ((Decimal) c.notStarted) / c.total;
                if (ratio > 0.5) {
                    Integer pct = Integer.valueOf(c.notStarted * 100 / c.total);
                    String detail = '「' + level + '」階層の' + pct + '%が未着手です。進め方を確認してください。';
                    out.add(buildItem(level, REASON_HIGH_NS, c.notStarted, null, null, detail));
                }
            }
        }

        if (out.size() < 3) {
            ObjectCounts ticket = countsMap.get(LEVEL_TICKET);
            if (ticket != null && progressRate < 30 && ticket.inProgress > 0) {
                String detail = '全体進捗が' + String.valueOf(progressRate)
                    + '%未満です。進行中Ticketのボトルネックを確認してください。';
                out.add(buildItem(LEVEL_TICKET, REASON_LOW_PROG, ticket.inProgress, null, null, detail));
            }
        }

        return out;
    }

    private static List<String> buildHighlights(ObjectCounts ticketCounts, String devServiceStatus) {
        List<String> highlights = new List<String>();

        if (devServiceStatus == STATUS_CLOSE) {
            highlights.add('このサービスはCLOSE状態です');
        }

        if (highlights.size() < 3) {
            highlights.add(String.valueOf(ticketCounts.done) + '件完了');
        }
        if (highlights.size() < 3 && ticketCounts.inProgress > 0) {
            highlights.add(String.valueOf(ticketCounts.inProgress) + '件進行中');
        }
        if (highlights.size() < 3 && ticketCounts.blocked > 0) {
            highlights.add('Blocked ' + String.valueOf(ticketCounts.blocked) + '件あり');
        }
        if (highlights.size() < 3 && ticketCounts.notStarted > 0) {
            highlights.add(String.valueOf(ticketCounts.notStarted) + '件未着手');
        }

        return highlights;
    }

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
        Notice notice = new Notice();
        notice.type = type;
        notice.level = level;
        notice.description = description;
        return notice;
    }

    private static ObjectCounts zeroCounts() {
        ObjectCounts c = new ObjectCounts();
        c.notStarted = 0;
        c.inProgress = 0;
        c.done = 0;
        c.blocked = 0;
        c.total = 0;
        return c;
    }

    public class Request {
        @InvocableVariable(label='Dev Service ID' required=true)
        public Id devServiceId;
    }

    public class ProgressResult {
        @InvocableVariable
        public Summary summary;

        @InvocableVariable
        public Counts counts;

        @InvocableVariable
        public List<NextActionItem> nextActions;

        @InvocableVariable
        public List<Notice> notices;
    }

    public class Summary {
        @InvocableVariable
        public Id devServiceId;

        @InvocableVariable
        public String devServiceName;

        @InvocableVariable
        public String devServiceStatus;

        @InvocableVariable
        public Integer totalItems;

        @InvocableVariable
        public Decimal progressRate;

        @InvocableVariable
        public List<String> highlights;
    }

    public class Counts {
        @InvocableVariable
        public ObjectCounts issue;

        @InvocableVariable
        public ObjectCounts plan;

        @InvocableVariable
        public ObjectCounts requirements;

        @InvocableVariable
        public ObjectCounts ticket;

        @InvocableVariable
        public ObjectCounts overall;
    }

    public class ObjectCounts {
        @InvocableVariable
        public Integer notStarted;

        @InvocableVariable
        public Integer inProgress;

        @InvocableVariable
        public Integer done;

        @InvocableVariable
        public Integer blocked;

        @InvocableVariable
        public Integer total;
    }

    public class NextActionItem {
        @InvocableVariable
        public String level;

        @InvocableVariable
        public Id recordId;

        @InvocableVariable
        public String recordName;

        @InvocableVariable
        public Integer countHint;

        @InvocableVariable
        public String reason;

        @InvocableVariable
        public String detail;
    }

    public class Notice {
        @InvocableVariable
        public String type;

        @InvocableVariable
        public String level;

        @InvocableVariable
        public String description;
    }
}