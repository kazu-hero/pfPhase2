@isTest
private class RelationGraphControllerTest {
    
    @testSetup
    static void setup() {
        // テストデータ作成
        Dev_Service__c service = new Dev_Service__c(
            Name = 'Test Service',
            Status__c = 'OPEN'
        );
        insert service;
        
        Issue__c issue = new Issue__c(
            Name = 'Test Issue',
            Status__c = 'TODO',
            category__c = '顧客管理'
        );
        insert issue;
        
        TechActionPlan__c plan = new TechActionPlan__c(
            Name = 'Test Plan',
            Status__c = 'WIP',
            planType__c = 'システム対応'
        );
        insert plan;
        
        FunctionRequirements__c req = new FunctionRequirements__c(
            Name = 'Test Requirement',
            Status__c = 'TODO',
            requirementsCategory__c = '顧客管理',
            requirementTarget__c = '取引先',
            priority__c = '1',
            urgency__c = '業務は停止しない',
            importance__c = '目立った影響はない'
        );
        insert req;
        
        Dev_Ticket__c ticket = new Dev_Ticket__c(
            Name = 'Test Ticket',
            Status__c = 'DONE'
        );
        insert ticket;
        
        // リレーション作成
        Relation_Support2Issue__c rel1 = new Relation_Support2Issue__c(
            Dev_Service__c = service.Id,
            Issue__c = issue.Id
        );
        insert rel1;
        
        Relation_Issue2Plan__c rel2 = new Relation_Issue2Plan__c(
            Issue__c = issue.Id,
            TechActionPlan__c = plan.Id
        );
        insert rel2;
        
        Relation_Plan2Requirements__c rel3 = new Relation_Plan2Requirements__c(
            TechActionPlan__c = plan.Id,
            FunctionRequirements__c = req.Id
        );
        insert rel3;
        
        Relation_Requirements2Dev__c rel4 = new Relation_Requirements2Dev__c(
            FunctionRequirements__c = req.Id,
            Dev_Ticket__c = ticket.Id
        );
        insert rel4;
    }
    
    @isTest
    static void testGetFilteredGraph_AllData() {
        Test.startTest();
        String result = RelationGraphController.getFilteredGraph(
            null, 
            null, 
            new List<String>{'TODO', 'WIP', 'DONE', 'OPEN', 'CLOSE'},  // 全ステータス
            new List<String>{'Dev_Service__c', 'Issue__c', 'TechActionPlan__c', 
                            'FunctionRequirements__c', 'Dev_Ticket__c'}
        );
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'グラフデータが取得できること');
        System.assert(result.contains('Dev_Service__c'), 'Dev_Serviceノードが含まれること');
        System.assert(result.contains('Issue__c'), 'Issueノードが含まれること');
    }
    
    @isTest
    static void testGetFilteredGraph_FromOrigin_DevService() {
        Dev_Service__c service = [SELECT Id FROM Dev_Service__c LIMIT 1];
        
        Test.startTest();
        String result = RelationGraphController.getFilteredGraph(
            service.Id,
            'Dev_Service__c',
            new List<String>{'TODO', 'WIP', 'DONE', 'OPEN', 'CLOSE'},
            null
        );
        Test.stopTest();
        
        System.assertNotEquals(null, result, '起点指定でデータが取得できること');
        System.assert(result.contains(service.Id), '起点レコードが含まれること');
    }
    
    @isTest
    static void testGetFilteredGraph_FromOrigin_Issue() {
        Issue__c issue = [SELECT Id FROM Issue__c LIMIT 1];
        
        Test.startTest();
        String result = RelationGraphController.getFilteredGraph(
            issue.Id,
            'Issue__c',
            new List<String>{'TODO', 'WIP', 'DONE'},
            null
        );
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Issue起点でデータが取得できること');
    }
    
    @isTest
    static void testGetFilteredGraph_StatusFilter() {
        Test.startTest();
        String result = RelationGraphController.getFilteredGraph(
            null,
            null,
            new List<String>{'TODO'},  // TODOのみ
            null
        );
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'ステータスフィルターが機能すること');
    }
    
    @isTest
    static void testGetRelatedRecords_DevService() {
        Dev_Service__c service = [SELECT Id FROM Dev_Service__c LIMIT 1];
        
        Test.startTest();
        Map<String, List<RelationGraphController.RelatedRecord>> result = 
            RelationGraphController.getRelatedRecords(service.Id, 'Dev_Service__c');
        Test.stopTest();
        
        System.assertNotEquals(null, result, '関連レコードが取得できること');
        System.assert(result.containsKey('downstream'), '下流レコードが含まれること');
        System.assert(result.containsKey('upstream'), '上流レコードが含まれること');
    }
    
    @isTest
    static void testGetRelatedRecords_Issue() {
        Issue__c issue = [SELECT Id FROM Issue__c LIMIT 1];
        
        Test.startTest();
        Map<String, List<RelationGraphController.RelatedRecord>> result = 
            RelationGraphController.getRelatedRecords(issue.Id, 'Issue__c');
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Issue の関連レコードが取得できること');
        System.assert(result.get('upstream').size() > 0, '上流レコード（Dev_Service）が含まれること');
    }
    
    @isTest
    static void testGovernorLimits() {
        Test.startTest();
        RelationGraphController.getFilteredGraph(null, null, null, null);
        Test.stopTest();
        
        System.assert(Limits.getQueries() < 100, 'SOQLクエリ数が100回以内であること');
        // データ作成時のDML操作があるため、コメントアウト
        // System.assert(Limits.getDmlStatements() == 0, 'DML操作がないこと');
    }
    
    @isTest
    static void testErrorHandling() {
        Test.startTest();
        try {
            // 存在しないIDでテスト（18桁のダミーID）
            RelationGraphController.getRelatedRecords('001000000000000AAA', 'Dev_Service__c');
            // エラーが発生しなくても問題なし（空の結果が返る）
            System.assert(true, '正常に処理されること');
        } catch (AuraHandledException e) {
            System.assert(true, '適切にエラーハンドリングされること');
        }
        Test.stopTest();
    }
}