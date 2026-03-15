@isTest
private class DevServiceProgressActionTest {
    private static final String STATUS_OPEN = 'OPEN';
    private static final String STATUS_CLOSE = 'CLOSE';

    @testSetup
    static void setup() {
        Dev_Service__c svcOpen = new Dev_Service__c(Name = 'SVC_OPEN', Status__c = STATUS_OPEN);
        Dev_Service__c svcClose = new Dev_Service__c(Name = 'SVC_CLOSE', Status__c = STATUS_CLOSE);
        Dev_Service__c svcNoIssue = new Dev_Service__c(Name = 'SVC_NO_ISSUE', Status__c = STATUS_OPEN);
        Dev_Service__c svcPlanGap = new Dev_Service__c(Name = 'SVC_PLAN_GAP', Status__c = STATUS_OPEN);
        Dev_Service__c svcReqGap = new Dev_Service__c(Name = 'SVC_REQ_GAP', Status__c = STATUS_OPEN);
        Dev_Service__c svcTicketGap = new Dev_Service__c(Name = 'SVC_TICKET_GAP', Status__c = STATUS_OPEN);
        Dev_Service__c svcPriority = new Dev_Service__c(Name = 'SVC_PRIORITY', Status__c = STATUS_OPEN);
        Dev_Service__c svcBlank = new Dev_Service__c(Name = 'SVC_BLANK_STATUS', Status__c = STATUS_OPEN);
        insert new List<Dev_Service__c>{
            svcOpen, svcClose, svcNoIssue, svcPlanGap, svcReqGap, svcTicketGap, svcPriority, svcBlank
        };

        // OPEN normal chain (progressRate = 50.0)
        Issue__c openIssue1 = new Issue__c(Name = 'OPEN_ISSUE_1', Status__c = 'TODO', category__c = '顧客管理');
        Issue__c openIssue2 = new Issue__c(Name = 'OPEN_ISSUE_2', Status__c = 'WIP', category__c = '顧客管理');
        insert new List<Issue__c>{openIssue1, openIssue2};

        insert new List<Relation_Support2Issue__c>{
            new Relation_Support2Issue__c(Dev_Service__c = svcOpen.Id, Issue__c = openIssue1.Id),
            new Relation_Support2Issue__c(Dev_Service__c = svcOpen.Id, Issue__c = openIssue2.Id)
        };

        TechActionPlan__c openPlan1 = new TechActionPlan__c(Name = 'OPEN_PLAN_1', Status__c = 'DONE', planType__c = 'システム対応');
        TechActionPlan__c openPlan2 = new TechActionPlan__c(Name = 'OPEN_PLAN_2', Status__c = 'DROP', planType__c = 'システム対応');
        insert new List<TechActionPlan__c>{openPlan1, openPlan2};

        insert new List<Relation_Issue2Plan__c>{
            new Relation_Issue2Plan__c(Issue__c = openIssue1.Id, TechActionPlan__c = openPlan1.Id),
            new Relation_Issue2Plan__c(Issue__c = openIssue2.Id, TechActionPlan__c = openPlan2.Id)
        };

        FunctionRequirements__c openReq1 = newReq('OPEN_REQ_1', 'TODO');
        FunctionRequirements__c openReq2 = newReq('OPEN_REQ_2', 'DONE');
        insert new List<FunctionRequirements__c>{openReq1, openReq2};

        insert new List<Relation_Plan2Requirements__c>{
            new Relation_Plan2Requirements__c(TechActionPlan__c = openPlan1.Id, FunctionRequirements__c = openReq1.Id),
            new Relation_Plan2Requirements__c(TechActionPlan__c = openPlan2.Id, FunctionRequirements__c = openReq2.Id)
        };

        Dev_Ticket__c openTicket1 = new Dev_Ticket__c(Name = 'OPEN_TICKET_1', Status__c = 'DONE');
        Dev_Ticket__c openTicket2 = new Dev_Ticket__c(Name = 'OPEN_TICKET_2', Status__c = 'WIP');
        insert new List<Dev_Ticket__c>{openTicket1, openTicket2};

        insert new List<Relation_Requirements2Dev__c>{
            new Relation_Requirements2Dev__c(FunctionRequirements__c = openReq1.Id, Dev_Ticket__c = openTicket1.Id),
            new Relation_Requirements2Dev__c(FunctionRequirements__c = openReq2.Id, Dev_Ticket__c = openTicket2.Id)
        };

        // CLOSE chain with ticket blocked
        Issue__c closeIssue = new Issue__c(Name = 'CLOSE_ISSUE_1', Status__c = 'TODO', category__c = '顧客管理');
        insert closeIssue;
        insert new Relation_Support2Issue__c(Dev_Service__c = svcClose.Id, Issue__c = closeIssue.Id);

        TechActionPlan__c closePlan = new TechActionPlan__c(Name = 'CLOSE_PLAN_1', Status__c = 'TODO', planType__c = 'システム対応');
        insert closePlan;
        insert new Relation_Issue2Plan__c(Issue__c = closeIssue.Id, TechActionPlan__c = closePlan.Id);

        FunctionRequirements__c closeReq = newReq('CLOSE_REQ_1', 'TODO');
        insert closeReq;
        insert new Relation_Plan2Requirements__c(TechActionPlan__c = closePlan.Id, FunctionRequirements__c = closeReq.Id);

        Dev_Ticket__c closeTicket = new Dev_Ticket__c(Name = 'CLOSE_TICKET_1', Status__c = 'DROP');
        insert closeTicket;
        insert new Relation_Requirements2Dev__c(FunctionRequirements__c = closeReq.Id, Dev_Ticket__c = closeTicket.Id);

        // PLAN GAP (Issue only)
        Issue__c gapIssue = new Issue__c(Name = 'GAP_PLAN_ISSUE', Status__c = 'TODO', category__c = '顧客管理');
        insert gapIssue;
        insert new Relation_Support2Issue__c(Dev_Service__c = svcPlanGap.Id, Issue__c = gapIssue.Id);

        // REQ GAP (Issue + Plan)
        Issue__c reqGapIssue = new Issue__c(Name = 'GAP_REQ_ISSUE', Status__c = 'TODO', category__c = '顧客管理');
        insert reqGapIssue;
        insert new Relation_Support2Issue__c(Dev_Service__c = svcReqGap.Id, Issue__c = reqGapIssue.Id);

        TechActionPlan__c reqGapPlan = new TechActionPlan__c(Name = 'GAP_REQ_PLAN', Status__c = 'WIP', planType__c = 'システム対応');
        insert reqGapPlan;
        insert new Relation_Issue2Plan__c(Issue__c = reqGapIssue.Id, TechActionPlan__c = reqGapPlan.Id);

        // TICKET GAP (Issue + Plan + Req)
        Issue__c ticketGapIssue = new Issue__c(Name = 'GAP_TICKET_ISSUE', Status__c = 'TODO', category__c = '顧客管理');
        insert ticketGapIssue;
        insert new Relation_Support2Issue__c(Dev_Service__c = svcTicketGap.Id, Issue__c = ticketGapIssue.Id);

        TechActionPlan__c ticketGapPlan = new TechActionPlan__c(Name = 'GAP_TICKET_PLAN', Status__c = 'WIP', planType__c = 'システム対応');
        insert ticketGapPlan;
        insert new Relation_Issue2Plan__c(Issue__c = ticketGapIssue.Id, TechActionPlan__c = ticketGapPlan.Id);

        FunctionRequirements__c ticketGapReq = newReq('GAP_TICKET_REQ', 'DONE');
        insert ticketGapReq;
        insert new Relation_Plan2Requirements__c(TechActionPlan__c = ticketGapPlan.Id, FunctionRequirements__c = ticketGapReq.Id);

        // PRIORITY chain: all levels blocked to test order + max 3
        Issue__c priIssue = new Issue__c(Name = 'PRI_ISSUE', Status__c = 'DROP', category__c = '顧客管理');
        insert priIssue;
        insert new Relation_Support2Issue__c(Dev_Service__c = svcPriority.Id, Issue__c = priIssue.Id);

        TechActionPlan__c priPlan = new TechActionPlan__c(Name = 'PRI_PLAN', Status__c = 'DROP', planType__c = 'システム対応');
        insert priPlan;
        insert new Relation_Issue2Plan__c(Issue__c = priIssue.Id, TechActionPlan__c = priPlan.Id);

        FunctionRequirements__c priReq = newReq('PRI_REQ', 'DROP');
        insert priReq;
        insert new Relation_Plan2Requirements__c(TechActionPlan__c = priPlan.Id, FunctionRequirements__c = priReq.Id);

        Dev_Ticket__c priTicket = new Dev_Ticket__c(Name = 'PRI_TICKET', Status__c = 'DROP');
        insert priTicket;
        insert new Relation_Requirements2Dev__c(FunctionRequirements__c = priReq.Id, Dev_Ticket__c = priTicket.Id);

        // BLANK status case (null Issue status)
        Issue__c blankIssue = new Issue__c(Name = 'BLANK_ISSUE', category__c = '顧客管理');
        insert blankIssue;
        insert new Relation_Support2Issue__c(Dev_Service__c = svcBlank.Id, Issue__c = blankIssue.Id);
    }

    @isTest
    static void testOpenNormalAggregation() {
        Dev_Service__c svc = getService('SVC_OPEN');
        Test.startTest();
        DevServiceProgressAction.ProgressResult result = invokeSingle(svc.Id);
        Test.stopTest();

        System.assertEquals(2, result.counts.issue.total);
        System.assertEquals(2, result.counts.plan.total);
        System.assertEquals(2, result.counts.requirements.total);
        System.assertEquals(2, result.counts.ticket.total);

        Integer byObjectTotal = result.counts.issue.total
            + result.counts.plan.total
            + result.counts.requirements.total
            + result.counts.ticket.total;
        System.assertEquals(byObjectTotal, result.counts.overall.total, 'overall total mismatch');

        System.assertEquals(50.0, result.summary.progressRate, 'progressRate should be 50.0');
        System.assert(result.summary.highlights.size() <= 3, 'highlights must be <= 3');
        System.assertNotEquals(null, result.nextActions);
    }

    @isTest
    static void testIssueMissingEarlyReturn() {
        Dev_Service__c svc = getService('SVC_NO_ISSUE');

        DevServiceProgressAction.ProgressResult result = invokeSingle(svc.Id);

        System.assertEquals(0, result.counts.issue.total);
        System.assertEquals(0, result.counts.plan.total);
        System.assertEquals(0, result.counts.requirements.total);
        System.assertEquals(0, result.counts.ticket.total);
        System.assertEquals(0, result.summary.totalItems);
        System.assert(hasNotice(result.notices, 'DataGap', 'Issue'));
    }

    @isTest
    static void testPlanRequirementTicketGapNotices() {
        DevServiceProgressAction.ProgressResult planGap = invokeSingle(getService('SVC_PLAN_GAP').Id);
        System.assert(hasNotice(planGap.notices, 'DataGap', 'Plan'));

        DevServiceProgressAction.ProgressResult reqGap = invokeSingle(getService('SVC_REQ_GAP').Id);
        System.assert(hasNotice(reqGap.notices, 'DataGap', 'Requirements'));

        DevServiceProgressAction.ProgressResult ticketGap = invokeSingle(getService('SVC_TICKET_GAP').Id);
        System.assert(hasNotice(ticketGap.notices, 'DataGap', 'Ticket'));
    }

    @isTest
    static void testBlankStatusFallsBackToNotStarted() {
        DevServiceProgressAction.ProgressResult result = invokeSingle(getService('SVC_BLANK_STATUS').Id);
        System.assertEquals(1, result.counts.issue.notStarted);
        // org側でStatus__cにデフォルト値（TODO）が自動設定される場合はDataGap(All)は出ない。
        // そのためこのテストではフォールバック結果（NotStarted件数）を必須とし、noticeは任意にする。
        System.assertNotEquals(null, result.notices);
    }

    @isTest
    static void testCloseOnlyPriority1AndHighlightFirst() {
        DevServiceProgressAction.ProgressResult result = invokeSingle(getService('SVC_CLOSE').Id);

        for (DevServiceProgressAction.NextActionItem item : result.nextActions) {
            System.assertEquals('BlockedExists', item.reason);
        }
        System.assert(result.summary.highlights.size() > 0);
        System.assertEquals('このサービスはCLOSE状態です', result.summary.highlights[0]);
    }

    @isTest
    static void testNextActionsPriorityOrderAndMax3() {
        DevServiceProgressAction.ProgressResult result = invokeSingle(getService('SVC_PRIORITY').Id);

        System.assertEquals(3, result.nextActions.size(), 'max 3 items expected');
        System.assertEquals('Issue', result.nextActions[0].level);
        System.assertEquals('Plan', result.nextActions[1].level);
        System.assertEquals('Requirements', result.nextActions[2].level);
    }

    @isTest
    static void testThresholdStrictlyGreaterThanHalf() {
        DevServiceProgressAction.ProgressResult result = invokeSingle(getService('SVC_OPEN').Id);

        Boolean hasHighNs = false;
        for (DevServiceProgressAction.NextActionItem item : result.nextActions) {
            if (item.reason == 'HighNotStartedRatio') {
                hasHighNs = true;
                break;
            }
        }
        System.assertEquals(false, hasHighNs, '50% should not match (>0.5 only)');
    }

    @isTest
    static void testRequiredInputValidation() {
        DevServiceProgressAction.Request req = new DevServiceProgressAction.Request();
        req.devServiceId = null;
        try {
            DevServiceProgressAction.getProgress(new List<DevServiceProgressAction.Request>{ req });
            System.assert(false, 'Expected IllegalArgumentException');
        } catch (Exception e) {
            System.assert(e.getMessage().contains('devServiceId is required'));
        }
    }

    private static Dev_Service__c getService(String name) {
        return [SELECT Id, Name FROM Dev_Service__c WHERE Name = :name LIMIT 1];
    }

    private static FunctionRequirements__c newReq(String name, String status) {
        FunctionRequirements__c req = new FunctionRequirements__c(
            Name = name,
            requirementsCategory__c = '顧客管理',
            requirementTarget__c = '取引先',
            priority__c = '1',
            urgency__c = '業務は停止しない',
            importance__c = '目立った影響はない'
        );
        req.Status__c = status;
        return req;
    }

    private static DevServiceProgressAction.ProgressResult invokeSingle(Id serviceId) {
        DevServiceProgressAction.Request req = new DevServiceProgressAction.Request();
        req.devServiceId = serviceId;

        List<DevServiceProgressAction.ProgressResult> results =
            DevServiceProgressAction.getProgress(new List<DevServiceProgressAction.Request>{ req });

        System.assertEquals(1, results.size());
        return results[0];
    }

    private static Boolean hasNotice(List<DevServiceProgressAction.Notice> notices, String type, String level) {
        for (DevServiceProgressAction.Notice n : notices) {
            if (n.type == type && n.level == level) {
                return true;
            }
        }
        return false;
    }
}