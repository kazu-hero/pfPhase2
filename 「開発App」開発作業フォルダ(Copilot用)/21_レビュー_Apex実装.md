# レビュー: Apex実装の確認

## **⚠️ 重要: このプロジェクトは既に実装済みです**

## **このレビューの目的**

既存のApex実装が仕様書通りに実装されているかを確認します。差異があれば報告します。

---

## **🤖 AIへの指示: レビューの実施方法**

### **レビューの進め方**

1. 各チェック項目を**順番に**確認する
2. 差異を発見したら、**報告する（勝手に修正しない）**
3. 全ての差異を記録する
4. 全てのチェックが完了するまで確認を続ける

### **レビュー結果の記録**

```
📊 レビュー結果: Apex実装確認

【チェック項目数】 全X項目
【確認完了項目】 X件
【仕様との一致】 Y件
【差異発見】 Z件

【発見した差異】
1. 差異: RelationGraphControllerに`with sharing`がない
   仕様: `public with sharing class`であるべき
   実装: `public class`のみ
   判断: ユーザー確認が必要

2. 差異: [内容]
   仕様: [仕様書の記載]
   実装: [実際の実装]
   判断: [ユーザー確認が必要 / 仕様通り / 実装ミス]
```

---

## **✅ チェックリスト: クラスの存在確認**

### **メインクラス**

- [ ] `RelationGraphController.cls` が存在する
- [ ] `with sharing` キーワードが付いている

**確認方法:**
```apex
public with sharing class RelationGraphController {
    // ...
}
```

### **テストクラス**

- [ ] `RelationGraphControllerTest.cls` が存在する
- [ ] `@isTest` アノテーションが付いている

---

## **✅ チェックリスト: メソッドの存在確認**

### **getFilteredGraph メソッド**

- [ ] メソッドが存在する
- [ ] `@AuraEnabled(cacheable=true)` が付いている
- [ ] 戻り値の型が `String` または `Map<String, Object>`

**シグネチャ例:**
```apex
@AuraEnabled(cacheable=true)
public static String getFilteredGraph(
    String originRecordId,
    String originObjectType,
    List<String> selectedStatuses,
    List<String> selectedObjectTypes
) {
    // ...
}
```

### **getRelatedRecords メソッド**

- [ ] メソッドが存在する
- [ ] `@AuraEnabled` が付いている
- [ ] パラメータに `recordId` と `objectType` がある

**シグネチャ例:**
```apex
@AuraEnabled
public static Map<String, List<Map<String, Object>>> getRelatedRecords(
    String recordId,
    String objectType
) {
    // ...
}
```

---

## **✅ チェックリスト: セキュリティ実装**

### **`with sharing` の確認**

- [ ] 全てのクラスに `with sharing` が付いている
- [ ] ❌ `without sharing` は使用していない

### **CRUD/FLSチェック**

- [ ] オブジェクトへのアクセス権チェックが実装されている
- [ ] 項目レベルセキュリティのチェックが実装されている

**実装例:**
```apex
if (!Schema.sObjectType.Dev_Service__c.isAccessible()) {
    throw new AuraHandledException('アクセス権限がありません');
}
```

---

## **✅ チェックリスト: N+1問題の防止**

### **SOQL in ループのチェック**

以下のパターンがコード内に**存在しない**ことを確認：

```apex
// ❌NG: ループ内でSOQL
for (Dev_Service__c service : services) {
    List<Relation_Support2Issue__c> relations = [
        SELECT Id FROM Relation_Support2Issue__c 
        WHERE Dev_Service__c = :service.Id
    ];
}
```

- [ ] ループ内にSOQLが**存在しない**
- [ ] 一括クエリパターンを使用している

**正しい実装例:**
```apex
// ✅OK: 一括クエリ
Set<Id> serviceIds = new Set<Id>();
for (Dev_Service__c service : services) {
    serviceIds.add(service.Id);
}
List<Relation_Support2Issue__c> relations = [
    SELECT Id, Dev_Service__c, Issue__c 
    FROM Relation_Support2Issue__c 
    WHERE Dev_Service__c IN :serviceIds
];
```

---

## **✅ チェックリスト: フィルター実装（5パターン）**

### **パターン1: Dev_Service起点**

- [ ] Dev_Service__cを起点として、下流方向に辿れる
- [ ] Relation_Support2Issue__c を経由してIssue__cを取得できる

### **パターン2: Issue起点**

- [ ] Issue__cを起点として、上流・下流に辿れる
- [ ] 上流: Dev_Service__c
- [ ] 下流: TechActionPlan__c

### **パターン3: TechActionPlan起点**

- [ ] TechActionPlan__cを起点として、上流・下流に辿れる
- [ ] 上流: Issue__c
- [ ] 下流: FunctionRequirements__c

### **パターン4: FunctionRequirements起点**

- [ ] FunctionRequirements__cを起点として、上流・下流に辿れる
- [ ] 上流: TechActionPlan__c
- [ ] 下流: Dev_Ticket__c

### **パターン5: Dev_Ticket起点**

- [ ] Dev_Ticket__cを起点として、上流方向に辿れる
- [ ] FunctionRequirements__cを取得できる

---

## **✅ チェックリスト: エラーハンドリング**

### **try-catch の実装**

- [ ] 全ての `@AuraEnabled` メソッドに try-catch がある

**実装例:**
```apex
@AuraEnabled
public static String getFilteredGraph(...) {
    try {
        // ロジック
    } catch (Exception e) {
        throw new AuraHandledException('エラー: ' + e.getMessage());
    }
}
```

### **エラーメッセージ**

- [ ] エラーメッセージが日本語で記述されている
- [ ] ユーザーにとって意味のあるメッセージになっている

---

## **✅ チェックリスト: オブジェクト名・項目名の正確性**

### **ハルシネーション（幻覚）のチェック**

以下のオブジェクト名が**正確**に使用されているか確認：

- [ ] `Dev_Service__c` ✅（❌ `Service__c`, `DevService__c` ではない）
- [ ] `Issue__c` ✅
- [ ] `TechActionPlan__c` ✅（❌ `ActionPlan__c` ではない）
- [ ] `FunctionRequirements__c` ✅（❌ `Requirements__c` ではない）
- [ ] `Dev_Ticket__c` ✅（❌ `Ticket__c` ではない）

### **中間オブジェクト名**

- [ ] `Relation_Support2Issue__c` ✅
- [ ] `Relation_Issue2Plan__c` ✅
- [ ] `Relation_Plan2Requirements__c` ✅
- [ ] `Relation_Requirements2Dev__c` ✅

### **項目名**

- [ ] `Status__c` ✅（❌ `Status`, `State__c` ではない）
- [ ] `Due_Date__c` ✅（❌ `DueDate__c`, `Due_Date` ではない）
- [ ] `Description__c` ✅

**確認方法:**
`02_データモデル定義.md` と完全に一致するか確認してください。

---

## **✅ チェックリスト: パフォーマンス**

### **Governor Limitsの遵守**

- [ ] SOQLクエリが100回以内
- [ ] DML操作が150回以内
- [ ] ヒープサイズが6MB以内

**確認方法:**
テストクラスで Limits クラスを使用して確認：

```apex
@isTest
static void testGovernorLimits() {
    Test.startTest();
    RelationGraphController.getFilteredGraph(...);
    Test.stopTest();
    
    System.assert(Limits.getQueries() < 100, 'SOQL回数超過');
}
```

### **最大深度の制限**

- [ ] 再帰的な処理に深度制限（10階層）が実装されている

**実装例:**
```apex
private static final Integer MAX_DEPTH = 10;

private void traverse(Set<Id> ids, Integer depth) {
    if (depth > MAX_DEPTH) {
        return; // 深度制限
    }
    // ...
}
```

---

## **✅ チェックリスト: テストカバレッジ**

### **テストクラスの実装**

- [ ] テストクラスが存在する
- [ ] 全てのメソッドにテストがある
- [ ] テストデータが作成されている

### **カバレッジ**

- [ ] カバレッジが80%以上
- [ ] ❌ 未カバーのメソッドがない

**確認方法:**
```
Developer Console → Tests → Run Tests → Code Coverage
```

### **テストケース**

- [ ] 正常系のテスト
- [ ] 異常系のテスト（エラーハンドリング）
- [ ] 境界値のテスト（空データ、大量データ）

---

## **🔍 コード品質のチェック**

### **コメント**

- [ ] クラスにコメントがある
- [ ] メソッドにコメントがある
- [ ] コメントが日本語で書かれている

**例:**
```apex
/**
 * グラフ可視化用のデータを取得する
 * @param originRecordId 起点レコードID
 * @return Cytoscape.js用のJSON文字列
 */
@AuraEnabled
public static String getFilteredGraph(String originRecordId) {
    // ...
}
```

### **変数名**

- [ ] 変数名が意味的に明確
- [ ] マジックナンバーがない（定数化されている）

**例:**
```apex
// ✅OK
private static final Integer MAX_NODES = 500;

// ❌NG
if (nodes.size() > 500) { ... }
```

---

## **📊 全体プロセスとの整合性チェック**

### **前フェーズとの整合性**

- [ ] オブジェクト設計フェーズで作成したオブジェクトを正しく参照しているか？
- [ ] 項目名が一致しているか？

### **次フェーズへの準備**

- [ ] LWCから呼び出せる形式になっているか？
- [ ] `@AuraEnabled` が付いているか？
- [ ] 戻り値がLWCで処理可能な型か？

### **仕様書との整合性**

- [ ] `07_Apex実装ガイド.md` の全メソッドが実装されているか？
- [ ] `05_フィルター機能仕様.md` の5パターンが全て実装されているか？
- [ ] `12_矛盾点確認シート.md` で指摘されている矛盾が解消されているか？

---

## **🎯 レビュー完了の判定**

以下の全てが満たされていれば、このフェーズは完了です：

- [ ] 全てのチェック項目にチェックが入っている
- [ ] 発見した問題が全て修正されている
- [ ] テストカバレッジが80%以上
- [ ] ハルシネーションが0件
- [ ] 全体プロセスとの整合性が確認できている

---

## **📝 レビュー完了報告**

```
✅ Apex実装フェーズ レビュー完了

【作成したクラス】 2個（本体、テスト）
【実装したメソッド】 X個
【テストカバレッジ】 Y%
【発見した問題】 Z件
【修正した問題】 Z件
【未解決問題】 0件

【次のアクション】
フェーズ3（LWC実装）に進む準備が整いました。
次は `12_留意点_LWC実装.md` を読み込みます。
```

---

**📌 レビューで問題が見つかった場合、必ず修正してから次のフェーズに進んでください。**
