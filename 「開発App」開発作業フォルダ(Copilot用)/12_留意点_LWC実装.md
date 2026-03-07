# 留意点: LWC実装の確認と拡張

## **⚠️ 重要: このプロジェクトは既に実装済みです**

このフェーズでは**新規作成ではなく、既存LWCコンポーネントの確認と必要に応じた拡張**を行います。

## **このフェーズで行うこと**

既存のLightning Web Components（LWC）とグラフ可視化機能が仕様通りに実装されているかを確認し、不足している機能があれば追加します。

---

## **🤖 AIへの指示: 作業前に必ず確認すること**

### **1. 前フェーズの完了確認**

- [ ] Apex実装の確認フェーズが完了している
- [ ] `21_レビュー_Apex実装.md` のレビューに合格している
- [ ] テストカバレッジが80%以上であることを確認した

**未完了の場合、このフェーズを開始しないでください。**

### **2. 必須プロンプトの読み込み（3段階）**

**第1段階（基礎理解）** - 以下2ファイルを必ず読み込んでください：

- [ ] `12_留意点_LWC実装.md` - このファイル（約350行）
- [ ] `09_画面構成とUI設計.md` - レイアウトとSLDS（約350行）

**第2段階（実装準備）** - 以下1ファイルを読み込んでください：

- [ ] `08_LWC実装ガイド.md` - LWC実装方法とコード例（約660行）

**第3段階（コンポーネント実装時）** - 各コンポーネント実装時に該当ファイルを個別参照：

- [ ] `04_グラフ可視化仕様.md` - graphDisplay実装時に参照（約550行）
- [ ] `05_フィルター機能仕様.md` - filterPanel実装時に参照（約460行）
- [ ] `06_詳細パネル仕様.md` - detailPanel実装時に参照（約440行）

**Ὂ1 重要**: 第1段階と第2段階を分けることで、コンテキスト長を約700行以内に抑えています。

### **3. LWC開発の基本ルール**

以下のルールを理解していますか？

- ✅ **Static Resourceを使用**（CDNからの読み込みは禁止）
- ✅ `@wire` でデータ取得する場合はキャッシュ可能なメソッドのみ
- ✅ `import` でApexメソッドをインポートする
- ✅ `NavigationMixin` でレコードページに遷移する
- ✅ Lightning Design System（SLDS）を使用する

これらを理解していない場合、**LWC開発ガイドを参照**してください。

---

## **⚠️ よくあるミス**

### **ミス1: CDNからのライブラリ読み込み**

❌ **NG例:**
```html
<script src="https://unpkg.com/cytoscape@3.x/dist/cytoscape.min.js"></script>
```

✅ **正しい例:**
```javascript
import { loadScript } from 'lightning/platformResourceLoader';
import CYTOSCAPE from '@salesforce/resourceUrl/cytoscape';

connectedCallback() {
    loadScript(this, CYTOSCAPE)
        .then(() => {
            this.initializeGraph();
        });
}
```

### **ミス2: Apexメソッドのインポートミス**

❌ **NG例:**
```javascript
// クラス名が間違っている
import getFilteredGraph from '@salesforce/apex/GraphController.getFilteredGraph';
```

✅ **正しい例:**
```javascript
// 正確なクラス名とメソッド名
import getFilteredGraph from '@salesforce/apex/RelationGraphController.getFilteredGraph';
```

**必ず `21_レビュー_Apex実装.md` で確認したクラス名を使用してください。**

### **ミス3: this の参照ミス**

❌ **NG例:**
```javascript
connectedCallback() {
    loadScript(this, CYTOSCAPE)
        .then(function() {
            this.initializeGraph(); // thisが正しく参照できない
        });
}
```

✅ **正しい例:**
```javascript
connectedCallback() {
    loadScript(this, CYTOSCAPE)
        .then(() => {
            this.initializeGraph(); // アロー関数でthisを保持
        });
}
```

---

## **🚨 作業中断が必要な状況**

以下の状況では**必ず作業を中断**し、ユーザーに報告してください：

### **状況1: Static Resourceが見つからない**

```
🚨 作業中断: LWC実装

【発生した問題】
- Cytoscape.jsのStatic Resourceが見つかりません
- エラー: Cannot find '@salesforce/resourceUrl/cytoscape'

【次に必要なアクション】
- Static Resourceをアップロードする必要があります
- ファイル名: cytoscape.js
- リソース名: cytoscape
```

### **状況2: Apexメソッドの呼び出しエラー**

```
🚨 作業中断: LWC実装

【発生した問題】
- Apexメソッド呼び出し時にエラー
- エラー内容: [具体的なエラー]

【試した解決策】
- メソッド名を確認したが正しい
- パラメータも仕様書通り

【次に必要なアクション】
- Apexクラスの再デプロイが必要か？
- それともLWC側の問題か？
```

### **状況3: Cytoscape.jsの初期化エラー**

```
🚨 作業中断: LWC実装

【発生した問題】
- Cytoscape.jsが初期化できない
- エラー: Cannot read property 'cytoscape' of undefined

【試した解決策】
- loadScriptの完了を待ってから初期化
- window.cytoscapeが存在するか確認

【次に必要なアクション】
- Cytoscape.jsのバージョン確認が必要
- それとも別のライブラリが必要か？
```

---

## **✅ 作業開始前のチェックリスト**

- [ ] 前フェーズ（Apex実装）が完了している
- [ ] 必須プロンプト5つを読んだ
- [ ] LWCの基本ルールを理解した
- [ ] VS Codeが開いている
- [ ] SFDX CLIがインストールされている
- [ ] Salesforce組織に接続できている

**全てチェックできない場合、作業を開始しないでください。**

---

## **📝 作業手順**

### **手順1: Static Resourceの確認**

1. Cytoscape.js 3.x系のStatic Resourceが存在するか確認
2. `cytoscape` という名前のリソースがあるか確認
3. バージョンが適切か確認

❌ **絶対にやってはいけないこと**:
- 既存Static Resourceの削除
- 動作中のリソースの置き換え（バージョンダウングレード等）

✅ **やるべきこと**:
- リソースの存在確認
- 不足リソースがあれば報告

### **手順2: 親コンポーネントの確認**

1. `relationGraphApp` コンポーネントが存在するか確認
2. 3カラムレイアウトが実装されているか確認
   - 左: フィルターパネル
   - 中央: グラフ表示
   - 右: 詳細パネル

### **手順3: フィルターパネルの確認**

1. `filterPanel` コンポーネントが存在するか確認
2. 3種類のフィルターが実装されているか確認
   - ステータスフィルター（チェックボックス）
   - オブジェクトタイプフィルター（チェックボックス）
   - 起点レコードフィルター（検索 + オプション）

### **手順4: グラフ表示の確認**

1. `graphDisplay` コンポーネントが存在するか確認
2. Cytoscape.jsの初期化コードがあるか確認
3. ノードとエッジの描画ロジックがあるか確認
4. インタラクション（クリック、ホバー、ズーム）が実装されているか確認

### **手順5: 詳細パネルの確認**

1. `detailPanel` コンポーネントが存在するか確認
2. レコード詳細表示機能があるか確認
3. ハイパーリンク実装があるか確認
4. 関連レコード一覧表示機能があるか確認

**不足コンポーネントや機能があれば報告してください（勝手に追加しない）**

---

## **🔍 実装中の確認ポイント**

### **コンポーネント構造のチェック**

各コンポーネント作成後、以下を確認してください：

```
✅ .html ファイルが存在するか？
✅ .js ファイルが存在するか？
✅ .css ファイルが存在するか？（必要な場合）
✅ .js-meta.xml ファイルが存在するか？
```

### **Apexインポートのチェック**

```javascript
// ✅ 正しいクラス名か？
import getFilteredGraph from '@salesforce/apex/RelationGraphController.getFilteredGraph';
import getRelatedRecords from '@salesforce/apex/RelationGraphController.getRelatedRecords';
```

### **イベント処理のチェック**

```
✅ イベントハンドラが登録されているか？
✅ イベントが正しく発火するか？
✅ イベントリスナーが正しく動作するか？
```

---

## **🎯 このフェーズのゴール**

以下の状態になれば、このフェーズは完了です：

- ✅ 仕様書記載の全LWCコンポーネントの存在確認完了
- ✅ Apexメソッドが正しく呼び出されていることを確認
- ✅ Cytoscape.jsが正常に動作していることを確認
- ✅ フィルターが機能していることを確認
- ✅ 詳細パネルが表示されることを確認
- ✅ 仕様との差異を全て報告（あれば）
- ✅ **既存コンポーネントを破壊していない**
- ✅ `22_レビュー_LWC実装.md` の実行準備完了

**ゴール達成後、レビュープロンプトを実行してください。**

---

**📌 重要: 不足機能を発見しても勝手に実装せず、必ずユーザーに報告してください。**
**既存のLWCコンポーネントを削除・変更することは絶対に避けてください。**

---

## **📚 参照すべき仕様書**

実装中に参照すべきファイル：

| 確認事項 | 参照ファイル |
|---------|------------|
| コンポーネント構成 | `08_LWC実装ガイド.md` |
| Cytoscape.js設定 | `04_グラフ可視化仕様.md` |
| フィルターUI | `05_フィルター機能仕様.md` |
| 詳細パネルUI | `06_詳細パネル仕様.md` |
| レイアウト | `09_画面構成とUI設計.md` |
| Apexメソッド名 | `07_Apex実装ガイド.md` |

---

## **💡 実装のヒント**

### **ヒント1: Cytoscape.jsの初期化タイミング**

```javascript
renderedCallback() {
    if (this.cytoscapeInitialized) {
        return;
    }
    this.cytoscapeInitialized = true;
    
    loadScript(this, CYTOSCAPE)
        .then(() => {
            this.initializeGraph();
        })
        .catch(error => {
            console.error('Cytoscape読み込みエラー:', error);
        });
}
```

### **ヒント2: フィルター条件の管理**

```javascript
handleStatusChange(event) {
    const value = event.target.value;
    const checked = event.target.checked;
    
    if (checked) {
        this.selectedStatuses.push(value);
    } else {
        this.selectedStatuses = this.selectedStatuses.filter(s => s !== value);
    }
    
    this.applyFilters();
}
```

### **ヒント3: NavigationMixinの使用**

```javascript
import { LightningElement } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

export default class DetailPanel extends NavigationMixin(LightningElement) {
    navigateToRecord(recordId, objectApiName) {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: recordId,
                objectApiName: objectApiName,
                actionName: 'view'
            }
        });
    }
}
```

---

**📌 不明点があれば、作業を進めずにユーザーに質問してください。推測で実装しないでください。**
