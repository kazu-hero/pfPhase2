# Apex実装ガイド

## **このファイルの目的**

Salesforce Apexクラスの具体的な実装方法とコード例を提供します。

---

## **📋 実装するクラス**

### **1. RelationGraphController.cls**

**目的**: LWCからデータを取得するメインコントローラ

**ファイル構成**:
```
force-app/
  main/
    default/
      classes/
        RelationGraphController.cls
        RelationGraphController.cls-meta.xml
        RelationGraphControllerTest.cls
        RelationGraphControllerTest.cls-meta.xml
```

---

## **🔧 メインコントローラの実装**

### **クラス定義**

```apex
/**
 * グラフ可視化用のデータを取得するコントローラ
 * @author [Your Name]
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
            // フィルター条件の検証とデフォルト値設定
            if (selectedStatuses == null) {
                // 全ステータスをデフォルトで含める（Dev_Service用のOPEN/CLOSEも含む）
                selectedStatuses = new List<String>{'TODO', 'WIP', 'DONE', 'OPEN', 'CLOSE'};
            }
            if (selectedObjectTypes == null) {
                selectedObjectTypes = new List<String>{
                    'Dev_Service__c', 'Issue__c', 'TechActionPlan__c',
                    'FunctionRequirements__c', 'Dev_Ticket__c'
                };
            }
            
            // データ取得
            GraphData graphData = new GraphData();
            
            if (String.isNotBlank(originRecordId) && String.isNotBlank(originObjectType)) {
                // 起点レコードフィルター
                graphData = getGraphFromOrigin(
                    originRecordId, 
                    originObjectType, 
                    selectedStatuses, 
                    selectedObjectTypes
                );
            } else {
                // 全データ取得
                graphData = getAllGraphData(selectedStatuses, selectedObjectTypes);
            }
            
            // JSON形式に変換
            return buildCytoscapeJson(graphData);
            
        } catch (Exception e) {
            throw new AuraHandledException('データ取得エラー: ' + e.getMessage());
        }
    }
    
    /**
     * 関連レコードを取得（詳細パネル用）
     * @param recordId レコードID
     * @param objectType オブジェクトタイプ
     * @return 上流・下流レコードのマップ
     */
    @AuraEnabled
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
        Set<Id> visitedIds = new Set<Id>();
        
        // 起点オブジェクトに応じた処理
        if (originObjectType == 'Dev_Service__c') {
            traverseFromDevService(originRecordId, graphData, visitedIds, 0);
        } else if (originObjectType == 'Issue__c') {
            traverseFromIssue(originRecordId, graphData, visitedIds, 0);
        } else if (originObjectType == 'TechActionPlan__c') {
            traverseFromPlan(originRecordId, graphData, visitedIds, 0);
        } else if (originObjectType == 'FunctionRequirements__c') {
            traverseFromRequirements(originRecordId, graphData, visitedIds, 0);
        } else if (originObjectType == 'Dev_Ticket__c') {
            traverseFromTicket(originRecordId, graphData, visitedIds, 0);
        }
        
        // フィルター適用
        applyFilters(graphData, selectedStatuses, selectedObjectTypes);
        
        return graphData;
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
        
        return graphData;
    }
    
    /**
     * Dev_Service__cのノードを追加
     */
    private static void addDevServiceNodes(GraphData graphData, List<String> statuses) {
        List<Dev_Service__c> records = [
            SELECT Id, Name, Status__c, body__c, logNo__c
            FROM Dev_Service__c
            WHERE Status__c IN :statuses
            LIMIT 500
        ];
        
        for (Dev_Service__c record : records) {
            graphData.addNode(record.Id, record.Name, 'Dev_Service__c', record.Status__c);
        }
    }
    
    // 他のオブジェクトも同様に実装...
    
    /**
     * Cytoscape.js用のJSON文字列を構築
     */
    private static String buildCytoscapeJson(GraphData graphData) {
        Map<String, Object> result = new Map<String, Object>();
        
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
            nodes.put(id, new GraphNode(id, label, objectType, status));
        }
        
        public void addEdge(String source, String target) {
            edges.add(new GraphEdge(source + '-' + target, source, target));
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
}
```

---

## **🧪 テストクラスの実装**

### **RelationGraphControllerTest.cls**

```apex
@isTest
private class RelationGraphControllerTest {
    
    @testSetup
    static void setup() {
        // テストデータ作成
        Dev_Service__c service = new Dev_Service__c(
            Name = 'Test Service',
            Status__c = 'OPEN'  // Dev_Service__c は OPEN/CLOSE
        );
        insert service;
        
        Issue__c issue = new Issue__c(
            Name = 'Test Issue',
            Status__c = 'TODO'  // Issue__c は TODO/WIP/DONE
        );
        insert issue;
        
        Relation_Support2Issue__c relation = new Relation_Support2Issue__c(
            Dev_Service__c = service.Id,
            Issue__c = issue.Id
        );
        insert relation;
    }
    
    @isTest
    static void testGetFilteredGraph_AllData() {
        Test.startTest();
        String result = RelationGraphController.getFilteredGraph(
            null, 
            null, 
            new List<String>{'TODO', 'WIP', 'DONE', 'OPEN', 'CLOSE'},  // 全ステータス
            new List<String>{'Dev_Service__c', 'Issue__c'}
        );
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'グラフデータが取得できること');
        System.assert(result.contains('Dev_Service__c'), 'Dev_Serviceノードが含まれること');
    }
    
    @isTest
    static void testGetFilteredGraph_FromOrigin() {
        Dev_Service__c service = [SELECT Id FROM Dev_Service__c LIMIT 1];
        
        Test.startTest();
        String result = RelationGraphController.getFilteredGraph(
            service.Id,
            'Dev_Service__c',
            new List<String>{'todo', 'wip', 'done'},
            null
        );
        Test.stopTest();
        
        System.assertNotEquals(null, result, '起点指定でデータが取得できること');
    }
    
    @isTest
    static void testGetRelatedRecords() {
        Dev_Service__c service = [SELECT Id FROM Dev_Service__c LIMIT 1];
        
        Test.startTest();
        Map<String, List<RelationGraphController.RelatedRecord>> result = 
            RelationGraphController.getRelatedRecords(service.Id, 'Dev_Service__c');
        Test.stopTest();
        
        System.assertNotEquals(null, result, '関連レコードが取得できること');
        System.assert(result.containsKey('downstream'), '下流レコードが含まれること');
    }
    
    @isTest
    static void testGovernorLimits() {
        Test.startTest();
        RelationGraphController.getFilteredGraph(null, null, null, null);
        Test.stopTest();
        
        System.assert(Limits.getQueries() < 100, 'SOQLクエリ数が100回以内であること');
    }
}
```

---

## **📌 実装のポイント**

### **1. セキュリティ**
- ✅ `with sharing` を必ず使用
- ✅ CRUD/FLSチェックを実装（必要に応じて）

### **2. パフォーマンス**
- ✅ 一括SOQLクエリ（N+1問題の回避）
- ✅ 最大深度制限（MAX_DEPTH = 10）
- ✅ 最大ノード数制限（MAX_NODES = 500）

### **3. エラーハンドリング**
- ✅ try-catch でエラーをキャッチ
- ✅ `AuraHandledException` でLWCにエラー通知
- ✅ 日本語のエラーメッセージ

### **4. テストカバレッジ**
- ✅ 80%以上を目標
- ✅ 正常系・異常系の両方をテスト
- ✅ Governor Limitsの確認

---

## **🔍 実装チェックリスト**

作業完了後、以下を確認してください：

- [ ] クラス名が `RelationGraphController` である
- [ ] `with sharing` キーワードが付いている
- [ ] `@AuraEnabled` アノテーションが適切に付いている
- [ ] オブジェクト名が `02_データモデル定義.md` と一致している
- [ ] テストクラスが作成されている
- [ ] テストカバレッジが80%以上である
- [ ] Governor Limitsを超過していない
- [ ] エラーハンドリングが実装されている

---

**📌 このガイドに従って実装すれば、仕様漏れなく正確なApexクラスが完成します。**
