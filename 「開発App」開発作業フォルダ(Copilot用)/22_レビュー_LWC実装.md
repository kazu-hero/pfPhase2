# レビュー: LWC実装の確認

## **⚠️ 重要: このプロジェクトは既に実装済みです**

## **このレビューの目的**

既存のLWC実装が仕様書通りに実装されているかを確認します。差異があれば報告します。

---

## **🤖 AIへの指示: レビューの実施方法**

### **レビューの進め方**

1. 各チェック項目を**順番に**確認する
2. 差異を発見したら、**報告する（勝手に修正しない）**
3. 全ての差異を記録する
4. 全てのチェックが完了するまで確認を続ける

### **レビュー結果の記録**

```
📊 レビュー結果: LWC実装確認

【チェック項目数】 全X項目
【確認完了項目】 X件
【仕様との一致】 Y件
【差異発見】 Z件

【発見した差異】
1. 差異: Cytoscape.jsがCDNから読み込まれている
   仕様: Static Resourceから読み込むべき
   実装: CDN (`https://unpkg.com/...`) から読み込み
   判断: 仕様違反、修正が必要

2. 差異: [内容]
   仕様: [仕様書の記載]
   実装: [実際の実装]
   判断: [ユーザー確認が必要 / 仕様通り / 実装ミス]
```

---

## **✅ チェックリスト: コンポーネントの存在確認**

### **親コンポーネント**

- [ ] `relationGraphApp` コンポーネントが存在する
  - [ ] `relationGraphApp.html`
  - [ ] `relationGraphApp.js`
  - [ ] `relationGraphApp.js-meta.xml`
  - [ ] `relationGraphApp.css`（オプション）

### **子コンポーネント**

- [ ] `filterPanel` コンポーネントが存在する
  - [ ] HTML, JS, JS-META が全て揃っている

- [ ] `graphDisplay` コンポーネントが存在する
  - [ ] HTML, JS, JS-META が全て揃っている

- [ ] `detailPanel` コンポーネントが存在する
  - [ ] HTML, JS, JS-META が全て揃っている

**確認方法:**
```
force-app/main/default/lwc/ 以下を確認
```

---

## **✅ チェックリスト: Static Resourceの確認**

### **Cytoscape.jsのStatic Resource**

- [ ] Static Resourceとしてアップロードされている
- [ ] リソース名: `cytoscape`
- [ ] ファイル: `cytoscape.min.js`
- [ ] ❌ CDNから読み込んでいない

**確認方法:**
```
Setup → Static Resources → cytoscape で検索
```

### **インポート文の確認**

```javascript
import CYTOSCAPE from '@salesforce/resourceUrl/cytoscape';
```

- [ ] このインポート文が存在する
- [ ] リソース名が正確（`cytoscape`）

---

## **✅ チェックリスト: Apexメソッドのインポート**

### **graphDisplay コンポーネント**

- [ ] `getFilteredGraph` がインポートされている

**正しいインポート例:**
```javascript
import getFilteredGraph from '@salesforce/apex/RelationGraphController.getFilteredGraph';
```

### **detailPanel コンポーネント**

- [ ] `getRelatedRecords` がインポートされている

**正しいインポート例:**
```javascript
import getRelatedRecords from '@salesforce/apex/RelationGraphController.getRelatedRecords';
```

### **ハルシネーション（幻覚）のチェック**

- [ ] クラス名が `RelationGraphController` である
- [ ] ❌ `GraphController` ではない
- [ ] ❌ `RelationController` ではない

**確認方法:**
`21_レビュー_Apex実装.md` で確認したクラス名と一致するか確認してください。

---

## **✅ チェックリスト: Cytoscape.jsの初期化**

### **loadScriptの使用**

- [ ] `loadScript` がインポートされている

```javascript
import { loadScript } from 'lightning/platformResourceLoader';
```

### **初期化タイミング**

- [ ] `renderedCallback()` または `connectedCallback()` で初期化
- [ ] 二重初期化を防ぐフラグがある

**正しい実装例:**
```javascript
renderedCallback() {
    if (this.cytoscapeInitialized) {
        return;
    }
    this.cytoscapeInitialized = true;
    
    loadScript(this, CYTOSCAPE)
        .then(() => {
            this.initializeGraph();
        });
}
```

### **Cytoscapeインスタンスの作成**

- [ ] `cytoscape()` の呼び出しが存在する
- [ ] コンテナ要素が正しく指定されている

**実装例:**
```javascript
this.cy = cytoscape({
    container: this.template.querySelector('.graph-container'),
    elements: graphData,
    style: [...],
    layout: { name: 'dagre' }
});
```

---

## **✅ チェックリスト: ノードとエッジのスタイル**

### **ノードの形状**

`04_グラフ可視化仕様.md` 通りに実装されているか確認：

- [ ] `Dev_Service__c`: 六角形（hexagon）
- [ ] `Issue__c`: 円形（ellipse）
- [ ] `TechActionPlan__c`: 四角形（rectangle）
- [ ] `FunctionRequirements__c`: 菱形（diamond）
- [ ] `Dev_Ticket__c`: 楕円形（ellipse）

**実装例:**
```javascript
{
    selector: 'node[objectType="Dev_Service__c"]',
    style: {
        'shape': 'hexagon',
        // ...
    }
}
```

### **ステータスの色**

- [ ] `TODO`: グレー (#999999)
- [ ] `WIP`: 黄色 (#FFC107)
- [ ] `DONE`: 緑 (#4CAF50)
- [ ] `OPEN`: 青 (#2196F3)
- [ ] `CLOSE`: 緑 (#4CAF50)

### **エッジのスタイル**

- [ ] 矢印が表示される（`'target-arrow-shape': 'triangle'`）
- [ ] 線の色が適切

---

## **✅ チェックリスト: フィルター機能**

### **ステータスフィルター**

- [ ] チェックボックスが5つある（TODO, WIP, DONE, OPEN, CLOSE）
- [ ] チェック状態の管理が実装されている
- [ ] イベントハンドラが動作する

### **オブジェクトタイプフィルター**

- [ ] チェックボックスが5つある（各オブジェクトタイプ）
- [ ] チェック状態の管理が実装されている
- [ ] イベントハンドラが動作する

### **起点レコードフィルター**

- [ ] オブジェクト選択（ラジオボタン）が実装されている
- [ ] レコード検索が実装されている
- [ ] 適用ボタンが存在する
- [ ] クリアボタンが存在する

### **フィルター適用順序**

`05_フィルター機能仕様.md` 通りに実装されているか確認：

1. [ ] 起点レコードフィルター
2. [ ] オブジェクトタイプフィルター
3. [ ] ステータスフィルター
4. [ ] 孤立ノードの除外

---

## **✅ チェックリスト: 詳細パネル**

### **レコード詳細表示**

- [ ] ノードクリックで詳細パネルが開く
- [ ] レコード名が表示される
- [ ] ステータスが表示される
- [ ] 説明が表示される

### **ハイパーリンク**

- [ ] `NavigationMixin` がインポートされている

```javascript
import { NavigationMixin } from 'lightning/navigation';
export default class DetailPanel extends NavigationMixin(LightningElement) {
    // ...
}
```

- [ ] レコード名がリンクになっている
- [ ] クリックでレコードページに遷移する
- [ ] URL形式が正しい（`/lightning/r/{ObjectApiName}/{RecordId}/view`）

### **フィルター外レコードの表示**

- [ ] 関連レコード一覧が表示される
- [ ] フィルター外レコードがグレーアウトされている
- [ ] アイコンが表示される（`utility:hide`）

**CSS例:**
```css
.filtered-out {
    opacity: 0.5;
    font-style: italic;
}
```

---

## **✅ チェックリスト: インタラクション**

### **ノードのインタラクション**

- [ ] クリックイベントが動作する
- [ ] ホバーでツールチップが表示される
- [ ] パスハイライトが実装されている

**実装例:**
```javascript
this.cy.on('tap', 'node', (event) => {
    const nodeData = event.target.data();
    this.showDetailPanel(nodeData);
});

this.cy.on('mouseover', 'node', (event) => {
    // ツールチップ表示
});
```

### **ズーム・パン**

- [ ] ズームインボタンが動作する
- [ ] ズームアウトボタンが動作する
- [ ] フィットボタンが動作する
- [ ] マウスホイールでズームできる
- [ ] ドラッグでパンできる

---

## **✅ チェックリスト: レイアウト**

### **Dagreレイアウト**

- [ ] レイアウト名が `dagre` である
- [ ] 左から右への配置（`rankDir: 'LR'`）
- [ ] ノード間隔が適切

**実装例:**
```javascript
layout: {
    name: 'dagre',
    rankDir: 'LR',
    nodeSep: 50,
    rankSep: 100
}
```

### **代替レイアウト**

- [ ] Dagreが動作しない場合、Breadthfirstに切り替える実装がある

---

## **✅ チェックリスト: Lightning Design System（SLDS）**

### **SLDSクラスの使用**

- [ ] ボタンに `slds-button` クラスが使用されている
- [ ] カードに `slds-card` クラスが使用されている
- [ ] チェックボックスに `slds-checkbox` が使用されている

**例:**
```html
<button class="slds-button slds-button_brand">適用</button>
<div class="slds-card">...</div>
```

### **レスポンシブデザイン**

- [ ] `slds-grid` を使用したレイアウト
- [ ] `slds-col` でカラム分割

---

## **✅ チェックリスト: エラーハンドリング**

### **Apex呼び出しのエラーハンドリング**

- [ ] `.catch()` でエラーをキャッチしている
- [ ] エラーメッセージをユーザーに表示している

**実装例:**
```javascript
getFilteredGraph({ originRecordId: this.recordId })
    .then(result => {
        // 処理
    })
    .catch(error => {
        this.showError('データ取得エラー: ' + error.body.message);
    });
```

### **Cytoscape.js読み込みエラー**

- [ ] `loadScript` の `.catch()` が実装されている

---

## **🔍 コード品質のチェック**

### **コメント**

- [ ] コンポーネントにコメントがある
- [ ] メソッドにコメントがある
- [ ] コメントが日本語で書かれている

### **変数名**

- [ ] 変数名が意味的に明確
- [ ] マジックナンバーがない

### **thisの参照**

- [ ] アロー関数を使用して `this` を正しく参照している
- [ ] ❌ `function() {}` で `this` を失っていない

---

## **📊 全体プロセスとの整合性チェック**

### **前フェーズとの整合性**

- [ ] Apexメソッド名がフェーズ2で実装したものと一致するか？
- [ ] パラメータの型が一致するか？
- [ ] 戻り値の型が一致するか？

### **仕様書との整合性**

- [ ] `08_LWC実装ガイド.md` の全コンポーネントが実装されているか？
- [ ] `04_グラフ可視化仕様.md` のノード形状・色が一致しているか？
- [ ] `05_フィルター機能仕様.md` のフィルター種類が全て実装されているか？
- [ ] `06_詳細パネル仕様.md` のハイパーリンクが実装されているか？

---

## **🎯 レビュー完了の判定**

以下の全てが満たされていれば、このフェーズは完了です：

- [ ] 全てのチェック項目にチェックが入っている
- [ ] 発見した問題が全て修正されている
- [ ] ハルシネーションが0件
- [ ] 全体プロセスとの整合性が確認できている

---

## **📝 レビュー完了報告**

```
✅ LWC実装フェーズ レビュー完了

【作成したコンポーネント】 4個
【実装した機能】 フィルター、グラフ表示、詳細パネル
【発見した問題】 X件
【修正した問題】 X件
【未解決問題】 0件

【次のアクション】
フェーズ4（統合テスト）に進む準備が整いました。
次は `13_留意点_統合テスト.md` を読み込みます。
```

---

**📌 レビューで問題が見つかった場合、必ず修正してから次のフェーズに進んでください。**
