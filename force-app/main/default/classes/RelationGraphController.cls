/**
 * グラフ可視化用のデータを取得するコントローラ
 * @author Salesforce Developer
 * @date 2025-11-26
 */
public with sharing class RelationGraphController {
    
    // 最大深度（循環参照防止）
    private static final Integer MAX_DEPTH = 10;
    
    // 最大ノード数（パフォーマンス制限）
    private static final Integer MAX_NODES = 500;
    
    /**
     * フィルター条件に基づいてグラフデータを取得
     * @param originRecordId 起点レコードID（オプション）
     * @param originObjectType 起点オブジェクトタイプ（オプション）
     * @param selectedStatuses 選択されたステータス一覧
     * @param selectedObjectTypes 選択されたオブジェクトタイプ一覧
     * @return Cytoscape.js用のJSON文字列
     */
    @AuraEnabled(cacheable=true)
    public static String getFilteredGraph(
        String originRecordId,
        String originObjectType,
        List<String> selectedStatuses,
        List<String> selectedObjectTypes
    ) {
        try {
            System.debug('getFilteredGraph called: originRecordId=' + originRecordId + ', originObjectType=' + originObjectType + ', selectedStatuses=' + String.valueOf(selectedStatuses) + ', selectedObjectTypes=' + String.valueOf(selectedObjectTypes));
            // フィルター条件の検証とデフォルト値設定
            if (selectedStatuses == null || selectedStatuses.isEmpty()) {
                selectedStatuses = new List<String>{'TODO', 'WIP', 'PENDING', 'DONE', 'OPEN', 'CLOSE', 'DROP'};
            }
            if (selectedObjectTypes == null || selectedObjectTypes.isEmpty()) {
                selectedObjectTypes = new List<String>{
                    'Dev_Service__c', 'Issue__c', 'TechActionPlan__c',
                    'FunctionRequirements__c', 'Dev_Ticket__c'
                };
            }

            GraphData graphData = new GraphData();

            if (String.isNotBlank(originRecordId) && String.isNotBlank(originObjectType)) {
                // 起点レコード検索時はstatusesフィルタを全ステータスに強制
                List<String> allStatuses = new List<String>{'TODO', 'WIP', 'PENDING', 'DONE', 'OPEN', 'CLOSE', 'DROP'};
                graphData = getGraphFromOrigin(
                    originRecordId,
                    originObjectType,
                    allStatuses,
                    selectedObjectTypes
                );
            } else {
                // 全データ取得
                graphData = getAllGraphData(selectedStatuses, selectedObjectTypes);
            }

            // JSON形式に変換
            return buildCytoscapeJson(graphData);

        } catch (Exception e) {
            System.debug('getFilteredGraph error: ' + e);
            throw new AuraHandledException('データ取得エラー: ' + e.getMessage());
        }
    }
    
    /**
     * 関連レコードを取得（詳細パネル用）
     * @param recordId レコードID
     * @param objectType オブジェクトタイプ
     * @return 上流・下流レコードのマップ
     */
    @AuraEnabled(cacheable=true)
    public static Map<String, List<RelatedRecord>> getRelatedRecords(
        String recordId,
        String objectType
    ) {
        try {
            Map<String, List<RelatedRecord>> result = new Map<String, List<RelatedRecord>>();
            result.put('upstream', getUpstreamRecords(recordId, objectType));
            result.put('downstream', getDownstreamRecords(recordId, objectType));
            return result;
        } catch (Exception e) {
            System.debug('getRelatedRecords error: ' + e);
            throw new AuraHandledException('関連レコード取得エラー: ' + e.getMessage());
        }
    }
    
    // ===== プライベートメソッド =====
    
    /**
     * 起点レコードから辿ってグラフデータを取得
     */
    private static GraphData getGraphFromOrigin(
        String originRecordId,
        String originObjectType,
        List<String> selectedStatuses,
        List<String> selectedObjectTypes
    ) {

        GraphData graphData = new GraphData();
        Set<Id> visitedIdsUp = new Set<Id>();
        Set<Id> visitedIdsDown = new Set<Id>();

        // --- 起点レコード自身のノードを必ず追加 ---
        if (originObjectType == 'Dev_Service__c') {
            Dev_Service__c rec = [SELECT Id, Name, Status__c FROM Dev_Service__c WHERE Id = :originRecordId LIMIT 1];
            graphData.addNode(rec.Id, rec.Name, 'Dev_Service__c', rec.Status__c);
        } else if (originObjectType == 'Issue__c') {
            Issue__c rec = [SELECT Id, Name, Status__c FROM Issue__c WHERE Id = :originRecordId LIMIT 1];
            graphData.addNode(rec.Id, rec.Name, 'Issue__c', rec.Status__c);
        } else if (originObjectType == 'TechActionPlan__c') {
            TechActionPlan__c rec = [SELECT Id, Name, Status__c FROM TechActionPlan__c WHERE Id = :originRecordId LIMIT 1];
            graphData.addNode(rec.Id, rec.Name, 'TechActionPlan__c', rec.Status__c);
        } else if (originObjectType == 'FunctionRequirements__c') {
            FunctionRequirements__c rec = [SELECT Id, Name, Status__c FROM FunctionRequirements__c WHERE Id = :originRecordId LIMIT 1];
            graphData.addNode(rec.Id, rec.Name, 'FunctionRequirements__c', rec.Status__c);
        } else if (originObjectType == 'Dev_Ticket__c') {
            Dev_Ticket__c rec = [SELECT Id, Name, Status__c FROM Dev_Ticket__c WHERE Id = :originRecordId LIMIT 1];
            graphData.addNode(rec.Id, rec.Name, 'Dev_Ticket__c', rec.Status__c);
        }


        // ユーザサービスは下流のみ探索
        if (originObjectType == 'Dev_Service__c') {
            traverseFromDevService(originRecordId, graphData, visitedIdsDown, 0, selectedStatuses);
            return graphData;
        }
        // 開発チケットは上流のみ探索
        if (originObjectType == 'Dev_Ticket__c') {
            traverseUpstream(originRecordId, originObjectType, graphData, visitedIdsUp, 0, selectedStatuses);
            return graphData;
        }

        // 中間オブジェクトは両方向探索・合成
        List<RelatedRecord> upstreams = getUpstreamRecords(originRecordId, originObjectType);
        List<RelatedRecord> downstreams = getDownstreamRecords(originRecordId, originObjectType);
        Boolean hasUpstream = (upstreams != null && !upstreams.isEmpty());
        Boolean hasDownstream = (downstreams != null && !downstreams.isEmpty());

        if (!hasUpstream && hasDownstream) {
            // 上流なし・下流あり（最上流 or 孤立ノード）
            if (originObjectType == 'Issue__c') {
                traverseFromIssue(originRecordId, graphData, visitedIdsDown, 0, selectedStatuses);
            } else if (originObjectType == 'TechActionPlan__c') {
                traverseFromPlan(originRecordId, graphData, visitedIdsDown, 0, selectedStatuses);
            } else if (originObjectType == 'FunctionRequirements__c') {
                traverseFromRequirements(originRecordId, graphData, visitedIdsDown, 0, selectedStatuses);
            }
            return graphData;
        }
        if (hasUpstream && !hasDownstream) {
            // 下流なし・上流あり（最下流 or 孤立ノード）
            traverseUpstream(originRecordId, originObjectType, graphData, visitedIdsUp, 0, selectedStatuses);
            return graphData;
        }
        if (!hasUpstream && !hasDownstream) {
            // 完全な孤立ノード
            if (originObjectType == 'Issue__c') {
                traverseFromIssue(originRecordId, graphData, visitedIdsDown, 0, selectedStatuses);
            } else if (originObjectType == 'TechActionPlan__c') {
                traverseFromPlan(originRecordId, graphData, visitedIdsDown, 0, selectedStatuses);
            } else if (originObjectType == 'FunctionRequirements__c') {
                traverseFromRequirements(originRecordId, graphData, visitedIdsDown, 0, selectedStatuses);
            }
            return graphData;
        }
        // 両方向に親・子がいる場合のみ両方向探索
        traverseUpstream(originRecordId, originObjectType, graphData, visitedIdsUp, 0, selectedStatuses);
        if (originObjectType == 'Issue__c') {
            traverseFromIssue(originRecordId, graphData, visitedIdsDown, 0, selectedStatuses);
        } else if (originObjectType == 'TechActionPlan__c') {
            traverseFromPlan(originRecordId, graphData, visitedIdsDown, 0, selectedStatuses);
        } else if (originObjectType == 'FunctionRequirements__c') {
            traverseFromRequirements(originRecordId, graphData, visitedIdsDown, 0, selectedStatuses);
        }
        return graphData;
    }

    // 上流方向の再帰探索
    private static void traverseUpstream(String recordId, String objectType, GraphData graphData, Set<Id> visitedIds, Integer depth, List<String> statuses) {
        if (depth > MAX_DEPTH || visitedIds.contains(recordId)) {
            return;
        }
        visitedIds.add(recordId);
        // 上流ノードを取得
        List<RelatedRecord> upstreams = getUpstreamRecords(recordId, objectType);
        for (RelatedRecord parent : upstreams) {
            System.debug('【traverseUpstream】for分岐: recordId=' + recordId + ' ← parentId=' + parent.id + ' (' + parent.objectType + ')');
            if (statuses.contains(parent.status)) {
                System.debug('【traverseUpstream】ノード追加: ' + parent.id + ' (' + parent.objectType + ')');
                graphData.addNode(parent.id, parent.name, parent.objectType, parent.status);
            }
            System.debug('【traverseUpstream】エッジ追加: ' + parent.id + ' → ' + recordId);
            graphData.addEdge(parent.id, recordId);
            System.debug('【traverseUpstream】再帰呼び出し: traverseUpstream(' + parent.id + ', ' + parent.objectType + ')');
            traverseUpstream(parent.id, parent.objectType, graphData, visitedIds, depth + 1, statuses);
        }
    }
    
    /**
     * 全データを取得
     */
    private static GraphData getAllGraphData(
        List<String> selectedStatuses,
        List<String> selectedObjectTypes
    ) {
        GraphData graphData = new GraphData();
        
        // 各オブジェクトのデータを取得
        if (selectedObjectTypes.contains('Dev_Service__c')) {
            addDevServiceNodes(graphData, selectedStatuses);
        }
        if (selectedObjectTypes.contains('Issue__c')) {
            addIssueNodes(graphData, selectedStatuses);
        }
        if (selectedObjectTypes.contains('TechActionPlan__c')) {
            addPlanNodes(graphData, selectedStatuses);
        }
        if (selectedObjectTypes.contains('FunctionRequirements__c')) {
            addRequirementsNodes(graphData, selectedStatuses);
        }
        if (selectedObjectTypes.contains('Dev_Ticket__c')) {
            addTicketNodes(graphData, selectedStatuses);
        }
        
        // リレーションを追加
        addAllRelations(graphData);
        
        // ノードまたはエッジが0件なら必ず例外をthrow（デバッグ用）
        if (graphData.nodes.isEmpty() || graphData.edges.isEmpty()) {
            throw new AuraHandledException('グラフデータが不足しています。nodes=' + graphData.nodes.size() + ', edges=' + graphData.edges.size() + '。SOQL条件やデータ件数を確認してください。');
        }
        return graphData;
    }
    
    /**
     * Dev_Service__cのノードを追加
     */
    private static void addDevServiceNodes(GraphData graphData, List<String> statuses) {
        List<Dev_Service__c> records = [
            SELECT Id, Name, Status__c
            FROM Dev_Service__c
            WHERE Status__c IN :statuses
            LIMIT 500
        ];
        
        for (Dev_Service__c record : records) {
            graphData.addNode(record.Id, record.Name, 'Dev_Service__c', record.Status__c);
        }
    }
    
    /**
     * Issue__cのノードを追加
     */
    private static void addIssueNodes(GraphData graphData, List<String> statuses) {
        List<Issue__c> records = [
            SELECT Id, Name, Status__c
            FROM Issue__c
            WHERE Status__c IN :statuses
            LIMIT 500
        ];
        
        for (Issue__c record : records) {
            graphData.addNode(record.Id, record.Name, 'Issue__c', record.Status__c);
        }
    }
    
    /**
     * TechActionPlan__cのノードを追加
     */
    private static void addPlanNodes(GraphData graphData, List<String> statuses) {
        List<TechActionPlan__c> records = [
            SELECT Id, Name, Status__c
            FROM TechActionPlan__c
            WHERE Status__c IN :statuses
            LIMIT 500
        ];
        
        for (TechActionPlan__c record : records) {
            graphData.addNode(record.Id, record.Name, 'TechActionPlan__c', record.Status__c);
        }
    }
    
    /**
     * FunctionRequirements__cのノードを追加
     */
    private static void addRequirementsNodes(GraphData graphData, List<String> statuses) {
        List<FunctionRequirements__c> records = [
            SELECT Id, Name, Status__c
            FROM FunctionRequirements__c
            WHERE Status__c IN :statuses
            LIMIT 500
        ];
        
        for (FunctionRequirements__c record : records) {
            graphData.addNode(record.Id, record.Name, 'FunctionRequirements__c', record.Status__c);
        }
    }
    
    /**
     * Dev_Ticket__cのノードを追加
     */
    private static void addTicketNodes(GraphData graphData, List<String> statuses) {
        List<Dev_Ticket__c> records = [
            SELECT Id, Name, Status__c
            FROM Dev_Ticket__c
            WHERE Status__c IN :statuses
            LIMIT 500
        ];
        
        for (Dev_Ticket__c record : records) {
            graphData.addNode(record.Id, record.Name, 'Dev_Ticket__c', record.Status__c);
        }
    }
    
    /**
     * 全リレーションを追加
     */
    private static void addAllRelations(GraphData graphData) {
        // Dev_Service → Issue
        for (Relation_Support2Issue__c rel : [
            SELECT Dev_Service__c, Issue__c 
            FROM Relation_Support2Issue__c
            LIMIT 1000
        ]) {
            if (graphData.nodes.containsKey(rel.Dev_Service__c) && 
                graphData.nodes.containsKey(rel.Issue__c)) {
                graphData.addEdge(rel.Dev_Service__c, rel.Issue__c);
            }
        }
        
        // Issue → TechActionPlan
        for (Relation_Issue2Plan__c rel : [
            SELECT Issue__c, TechActionPlan__c
            FROM Relation_Issue2Plan__c
            LIMIT 1000
        ]) {
            if (graphData.nodes.containsKey(rel.Issue__c) && 
                graphData.nodes.containsKey(rel.TechActionPlan__c)) {
                graphData.addEdge(rel.Issue__c, rel.TechActionPlan__c);
            }
        }
        
        // Issue → Dev_Ticket（直接参照）
        for (Issue__c issue : [
            SELECT Id, fastTicket__c 
            FROM Issue__c 
            WHERE fastTicket__c != null 
            LIMIT 1000
        ]) {
            if (graphData.nodes.containsKey(issue.Id) && 
                graphData.nodes.containsKey(issue.fastTicket__c)) {
                graphData.addEdge(issue.Id, issue.fastTicket__c);
            }
        }
        
        // TechActionPlan → FunctionRequirements
        for (Relation_Plan2Requirements__c rel : [
            SELECT TechActionPlan__c, FunctionRequirements__c
            FROM Relation_Plan2Requirements__c
            LIMIT 1000
        ]) {
            if (graphData.nodes.containsKey(rel.TechActionPlan__c) && 
                graphData.nodes.containsKey(rel.FunctionRequirements__c)) {
                graphData.addEdge(rel.TechActionPlan__c, rel.FunctionRequirements__c);
            }
        }
        
        // FunctionRequirements → Dev_Ticket
        for (Relation_Requirements2Dev__c rel : [
            SELECT FunctionRequirements__c, Dev_Ticket__c
            FROM Relation_Requirements2Dev__c
            LIMIT 1000
        ]) {
            if (graphData.nodes.containsKey(rel.FunctionRequirements__c) && 
                graphData.nodes.containsKey(rel.Dev_Ticket__c)) {
                graphData.addEdge(rel.FunctionRequirements__c, rel.Dev_Ticket__c);
            }
        }
    }
    
    /**
     * Dev_Service起点でのトラバース
     */
    private static void traverseFromDevService(
        String recordId,
        GraphData graphData,
        Set<Id> visitedIds,
        Integer depth,
        List<String> statuses
    ) {
        if (depth > MAX_DEPTH || visitedIds.contains(recordId)) {
            return;
        }
        visitedIds.add(recordId);
        
        // Dev_Service自身を追加
        Dev_Service__c service = [SELECT Id, Name, Status__c FROM Dev_Service__c WHERE Id = :recordId];
        if (statuses.contains(service.Status__c)) {
            graphData.addNode(service.Id, service.Name, 'Dev_Service__c', service.Status__c);
        }

        // 下流のIssueを取得しログ出力
        List<Id> downstreamIssueIds = new List<Id>();
        for (Relation_Support2Issue__c rel : [
            SELECT Issue__c FROM Relation_Support2Issue__c WHERE Dev_Service__c = :recordId
        ]) {
            downstreamIssueIds.add(rel.Issue__c);
        }
        System.debug('【traverseFromDevService】下流Issue数=' + downstreamIssueIds.size() + ' : ' + downstreamIssueIds);

        // 下流のIssueを辿る
        for (Id issueId : downstreamIssueIds) {
            System.debug('【traverseFromDevService】for分岐: recordId=' + recordId + ' → issueId=' + issueId);
            System.debug('【traverseFromDevService】エッジ追加: ' + recordId + ' → ' + issueId);
            graphData.addEdge(recordId, issueId);
            System.debug('【traverseFromDevService】再帰呼び出し: traverseFromIssue(' + issueId + ')');
            traverseFromIssue(issueId, graphData, visitedIds, depth + 1, statuses);
        }
    }
    
    /**
     * Issue起点でのトラバース
     */
    private static void traverseFromIssue(
        String recordId,
        GraphData graphData,
        Set<Id> visitedIds,
        Integer depth,
        List<String> statuses
    ) {
        if (depth > MAX_DEPTH || visitedIds.contains(recordId)) {
            return;
        }
        visitedIds.add(recordId);
        
        Issue__c issue = [SELECT Id, Name, Status__c, fastTicket__c FROM Issue__c WHERE Id = :recordId];
        if (statuses.contains(issue.Status__c)) {
            graphData.addNode(issue.Id, issue.Name, 'Issue__c', issue.Status__c);
        }
        
        // 下流のPlanを辿る
        for (Relation_Issue2Plan__c rel : [
            SELECT TechActionPlan__c FROM Relation_Issue2Plan__c WHERE Issue__c = :recordId
        ]) {
            graphData.addEdge(recordId, rel.TechActionPlan__c);
            traverseFromPlan(rel.TechActionPlan__c, graphData, visitedIds, depth + 1, statuses);
        }
        
        // 直接の開発チケット参照を辿る
        if (issue.fastTicket__c != null) {
            graphData.addEdge(recordId, issue.fastTicket__c);
            traverseFromTicket(issue.fastTicket__c, graphData, visitedIds, depth + 1, statuses);
        }
    }
    
    /**
     * TechActionPlan起点でのトラバース
     */
    private static void traverseFromPlan(
        String recordId,
        GraphData graphData,
        Set<Id> visitedIds,
        Integer depth,
        List<String> statuses
    ) {
        if (depth > MAX_DEPTH || visitedIds.contains(recordId)) {
            return;
        }
        visitedIds.add(recordId);
        
        TechActionPlan__c plan = [SELECT Id, Name, Status__c FROM TechActionPlan__c WHERE Id = :recordId];
        if (statuses.contains(plan.Status__c)) {
            graphData.addNode(plan.Id, plan.Name, 'TechActionPlan__c', plan.Status__c);
        }
        
        // 下流のRequirementsを辿る
        for (Relation_Plan2Requirements__c rel : [
            SELECT FunctionRequirements__c FROM Relation_Plan2Requirements__c WHERE TechActionPlan__c = :recordId
        ]) {
            graphData.addEdge(recordId, rel.FunctionRequirements__c);
            traverseFromRequirements(rel.FunctionRequirements__c, graphData, visitedIds, depth + 1, statuses);
        }
    }
    
    /**
     * FunctionRequirements起点でのトラバース
     */
    private static void traverseFromRequirements(
        String recordId,
        GraphData graphData,
        Set<Id> visitedIds,
        Integer depth,
        List<String> statuses
    ) {
        if (depth > MAX_DEPTH || visitedIds.contains(recordId)) {
            return;
        }
        visitedIds.add(recordId);
        
        FunctionRequirements__c req = [SELECT Id, Name, Status__c FROM FunctionRequirements__c WHERE Id = :recordId];
        if (statuses.contains(req.Status__c)) {
            graphData.addNode(req.Id, req.Name, 'FunctionRequirements__c', req.Status__c);
        }
        
        // 下流のDev_Ticketを辿る
        for (Relation_Requirements2Dev__c rel : [
            SELECT Dev_Ticket__c FROM Relation_Requirements2Dev__c WHERE FunctionRequirements__c = :recordId
        ]) {
            graphData.addEdge(recordId, rel.Dev_Ticket__c);
            traverseFromTicket(rel.Dev_Ticket__c, graphData, visitedIds, depth + 1, statuses);
        }
    }
    
    /**
     * Dev_Ticket起点でのトラバース
     */
    private static void traverseFromTicket(
        String recordId,
        GraphData graphData,
        Set<Id> visitedIds,
        Integer depth,
        List<String> statuses
    ) {
        if (depth > MAX_DEPTH || visitedIds.contains(recordId)) {
            return;
        }
        visitedIds.add(recordId);
        
        Dev_Ticket__c ticket = [SELECT Id, Name, Status__c FROM Dev_Ticket__c WHERE Id = :recordId];
        if (statuses.contains(ticket.Status__c)) {
            graphData.addNode(ticket.Id, ticket.Name, 'Dev_Ticket__c', ticket.Status__c);
        }
    }
    
    /**
     * 上流レコードを取得
     */
    private static List<RelatedRecord> getUpstreamRecords(String recordId, String objectType) {
        List<RelatedRecord> result = new List<RelatedRecord>();

        if (objectType == 'Issue__c') {
            // 上流: Dev_Service__c
            for (Relation_Support2Issue__c rel : [
                SELECT Dev_Service__c, Dev_Service__r.Name, Dev_Service__r.Status__c
                FROM Relation_Support2Issue__c
                WHERE Issue__c = :recordId
            ]) {
                result.add(new RelatedRecord(rel.Dev_Service__c, rel.Dev_Service__r.Name, 
                    'Dev_Service__c', rel.Dev_Service__r.Status__c));
            }
        } else if (objectType == 'TechActionPlan__c') {
            // 上流: Issue__c
            for (Relation_Issue2Plan__c rel : [
                SELECT Issue__c, Issue__r.Name, Issue__r.Status__c
                FROM Relation_Issue2Plan__c
                WHERE TechActionPlan__c = :recordId
            ]) {
                result.add(new RelatedRecord(rel.Issue__c, rel.Issue__r.Name,
                    'Issue__c', rel.Issue__r.Status__c));
            }
        } else if (objectType == 'FunctionRequirements__c') {
            // 上流: TechActionPlan__c
            for (Relation_Plan2Requirements__c rel : [
                SELECT TechActionPlan__c, TechActionPlan__r.Name, TechActionPlan__r.Status__c
                FROM Relation_Plan2Requirements__c
                WHERE FunctionRequirements__c = :recordId
            ]) {
                result.add(new RelatedRecord(rel.TechActionPlan__c, rel.TechActionPlan__r.Name,
                    'TechActionPlan__c', rel.TechActionPlan__r.Status__c));
            }
        } else if (objectType == 'Dev_Ticket__c') {
            // 上流: FunctionRequirements__c
            for (Relation_Requirements2Dev__c rel : [
                SELECT FunctionRequirements__c, FunctionRequirements__r.Name, FunctionRequirements__r.Status__c
                FROM Relation_Requirements2Dev__c
                WHERE Dev_Ticket__c = :recordId
            ]) {
                result.add(new RelatedRecord(rel.FunctionRequirements__c, rel.FunctionRequirements__r.Name,
                    'FunctionRequirements__c', rel.FunctionRequirements__r.Status__c));
            }
            // 上流: Issue__c（直接参照）
            for (Issue__c issue : [
                SELECT Id, Name, Status__c 
                FROM Issue__c 
                WHERE fastTicket__c = :recordId
            ]) {
                result.add(new RelatedRecord(issue.Id, issue.Name, 'Issue__c', issue.Status__c));
            }
        }
        return result;
    }
    
    /**
     * 下流レコードを取得
     */
    private static List<RelatedRecord> getDownstreamRecords(String recordId, String objectType) {
        List<RelatedRecord> result = new List<RelatedRecord>();

        if (objectType == 'Dev_Service__c') {
            // 下流: Issue__c
            for (Relation_Support2Issue__c rel : [
                SELECT Issue__c, Issue__r.Name, Issue__r.Status__c
                FROM Relation_Support2Issue__c
                WHERE Dev_Service__c = :recordId
            ]) {
                result.add(new RelatedRecord(rel.Issue__c, rel.Issue__r.Name, 
                    'Issue__c', rel.Issue__r.Status__c));
            }
        } else if (objectType == 'Issue__c') {
            // 下流: TechActionPlan__c
            for (Relation_Issue2Plan__c rel : [
                SELECT TechActionPlan__c, TechActionPlan__r.Name, TechActionPlan__r.Status__c
                FROM Relation_Issue2Plan__c
                WHERE Issue__c = :recordId
            ]) {
                result.add(new RelatedRecord(rel.TechActionPlan__c, rel.TechActionPlan__r.Name,
                    'TechActionPlan__c', rel.TechActionPlan__r.Status__c));
            }
            // 下流: Dev_Ticket__c（直接参照）
            List<Issue__c> issues = [
                SELECT Id, fastTicket__c, fastTicket__r.Name, fastTicket__r.Status__c 
                FROM Issue__c 
                WHERE Id = :recordId AND fastTicket__c != null
            ];
            if (!issues.isEmpty() && issues[0].fastTicket__c != null) {
                result.add(new RelatedRecord(issues[0].fastTicket__c, issues[0].fastTicket__r.Name,
                    'Dev_Ticket__c', issues[0].fastTicket__r.Status__c));
            }
        } else if (objectType == 'TechActionPlan__c') {
            // 下流: FunctionRequirements__c
            for (Relation_Plan2Requirements__c rel : [
                SELECT FunctionRequirements__c, FunctionRequirements__r.Name, FunctionRequirements__r.Status__c
                FROM Relation_Plan2Requirements__c
                WHERE TechActionPlan__c = :recordId
            ]) {
                result.add(new RelatedRecord(rel.FunctionRequirements__c, rel.FunctionRequirements__r.Name,
                    'FunctionRequirements__c', rel.FunctionRequirements__r.Status__c));
            }
        } else if (objectType == 'FunctionRequirements__c') {
            // 下流: Dev_Ticket__c
            for (Relation_Requirements2Dev__c rel : [
                SELECT Dev_Ticket__c, Dev_Ticket__r.Name, Dev_Ticket__r.Status__c
                FROM Relation_Requirements2Dev__c
                WHERE FunctionRequirements__c = :recordId
            ]) {
                result.add(new RelatedRecord(rel.Dev_Ticket__c, rel.Dev_Ticket__r.Name,
                    'Dev_Ticket__c', rel.Dev_Ticket__r.Status__c));
            }
        }
        return result;
    }
    
    /**
     * Cytoscape.js用のJSON文字列を構築
     */
    private static String buildCytoscapeJson(GraphData graphData) {
        List<Map<String, Object>> elements = new List<Map<String, Object>>();
        
        // ノードを追加
        for (GraphNode node : graphData.nodes.values()) {
            Map<String, Object> element = new Map<String, Object>{
                'group' => 'nodes',
                'data' => new Map<String, Object>{
                    'id' => node.id,
                    'label' => node.label,
                    'objectType' => node.objectType,
                    'status' => node.status
                }
            };
            elements.add(element);
        }
        
        // エッジを追加
        for (GraphEdge edge : graphData.edges) {
            Map<String, Object> element = new Map<String, Object>{
                'group' => 'edges',
                'data' => new Map<String, Object>{
                    'id' => edge.id,
                    'source' => edge.source,
                    'target' => edge.target
                }
            };
            elements.add(element);
        }
        
        return JSON.serialize(elements);
    }
    
    // ===== 内部クラス =====
    
    /**
     * グラフデータを保持するクラス
     */
    private class GraphData {
        public Map<String, GraphNode> nodes = new Map<String, GraphNode>();
        public List<GraphEdge> edges = new List<GraphEdge>();
        
        public void addNode(String id, String label, String objectType, String status) {
            if (!nodes.containsKey(id)) {
                nodes.put(id, new GraphNode(id, label, objectType, status));
            }
        }
        
        public void addEdge(String source, String target) {
            String edgeId = source + '-' + target;
            edges.add(new GraphEdge(edgeId, source, target));
        }
    }
    
    /**
     * ノード情報
     */
    private class GraphNode {
        public String id;
        public String label;
        public String objectType;
        public String status;
        
        public GraphNode(String id, String label, String objectType, String status) {
            this.id = id;
            this.label = label;
            this.objectType = objectType;
            this.status = status;
        }
    }
    
    /**
     * エッジ情報
     */
    private class GraphEdge {
        public String id;
        public String source;
        public String target;
        
        public GraphEdge(String id, String source, String target) {
            this.id = id;
            this.source = source;
            this.target = target;
        }
    }
    
    /**
     * 関連レコード情報（詳細パネル用）
     */
    public class RelatedRecord {
        @AuraEnabled public String id;
        @AuraEnabled public String name;
        @AuraEnabled public String objectType;
        @AuraEnabled public String status;
        @AuraEnabled public Boolean isFilteredOut;
        
        public RelatedRecord(String id, String name, String objectType, String status) {
            this.id = id;
            this.name = name;
            this.objectType = objectType;
            this.status = status;
            this.isFilteredOut = false;
        }
    }
    /**
     * 起点レコード検索（LWCサジェスト用）
     */
    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> searchOriginRecords(String objectType, String searchTerm) {
        try {
            List<Map<String, String>> results = new List<Map<String, String>>();
            if (String.isBlank(objectType) || String.isBlank(searchTerm)) {
                return results;
            }
            String soql;
            String likeTerm = '%' + searchTerm + '%';
            if (objectType == 'Dev_Service__c') {
                soql = 'SELECT Id, Name FROM Dev_Service__c WHERE Name LIKE :likeTerm LIMIT 20';
                for (Dev_Service__c rec : Database.query(soql)) {
                    results.add(new Map<String, String>{'Id'=>rec.Id, 'Name'=>rec.Name});
                }
            } else if (objectType == 'Issue__c') {
                soql = 'SELECT Id, Name FROM Issue__c WHERE Name LIKE :likeTerm LIMIT 20';
                for (Issue__c rec : Database.query(soql)) {
                    results.add(new Map<String, String>{'Id'=>rec.Id, 'Name'=>rec.Name});
                }
            } else if (objectType == 'TechActionPlan__c') {
                soql = 'SELECT Id, Name FROM TechActionPlan__c WHERE Name LIKE :likeTerm LIMIT 20';
                for (TechActionPlan__c rec : Database.query(soql)) {
                    results.add(new Map<String, String>{'Id'=>rec.Id, 'Name'=>rec.Name});
                }
            } else if (objectType == 'FunctionRequirements__c') {
                soql = 'SELECT Id, Name FROM FunctionRequirements__c WHERE Name LIKE :likeTerm LIMIT 20';
                for (FunctionRequirements__c rec : Database.query(soql)) {
                    results.add(new Map<String, String>{'Id'=>rec.Id, 'Name'=>rec.Name});
                }
            } else if (objectType == 'Dev_Ticket__c') {
                soql = 'SELECT Id, Name FROM Dev_Ticket__c WHERE Name LIKE :likeTerm LIMIT 20';
                for (Dev_Ticket__c rec : Database.query(soql)) {
                    results.add(new Map<String, String>{'Id'=>rec.Id, 'Name'=>rec.Name});
                }
            }
            return results;
        } catch (Exception e) {
            System.debug('searchOriginRecords error: ' + e);
            throw new AuraHandledException('起点レコード検索エラー: ' + e.getMessage());
        }
    }
}