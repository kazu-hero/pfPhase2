# LWC実装ガイド

## **このファイルの目的**

Lightning Web Componentsの具体的な実装方法とコード例を提供します。

---

## **📋 実装するコンポーネント**

### **コンポーネント構成**

```
force-app/
  main/
    default/
      lwc/
        relationGraphApp/          # 親コンポーネント
        filterPanel/               # フィルターパネル
        graphDisplay/              # グラフ表示
        detailPanel/               # 詳細パネル
```

---

## **🔧 1. 親コンポーネント（relationGraphApp）**

### **relationGraphApp.html**

```html
<template>
    <lightning-card title="開発プロセス可視化">
        <div class="slds-grid slds-wrap">
            <!-- 左: フィルターパネル -->
            <div class="slds-col slds-size_1-of-4 slds-p-around_small">
                <c-filter-panel 
                    onfilterchange={handleFilterChange}>
                </c-filter-panel>
            </div>
            
            <!-- 中央: グラフ表示 -->
            <div class="slds-col slds-size_1-of-2">
                <c-graph-display 
                    filter-conditions={filterConditions}
                    onnodeselect={handleNodeSelect}>
                </c-graph-display>
            </div>
            
            <!-- 右: 詳細パネル -->
            <div class="slds-col slds-size_1-of-4 slds-p-around_small">
                <c-detail-panel 
                    selected-node={selectedNode}
                    filter-conditions={filterConditions}>
                </c-detail-panel>
            </div>
        </div>
    </lightning-card>
</template>
```

### **relationGraphApp.js**

```javascript
import { LightningElement, track } from 'lwc';

export default class RelationGraphApp extends LightningElement {
    @track filterConditions = {
        selectedStatuses: ['TODO', 'WIP', 'DONE', 'OPEN', 'CLOSE'], // 全ステータス（開発チケット系 + 問い合わせ系）
        selectedObjectTypes: ['Dev_Service__c', 'Issue__c', 'TechActionPlan__c', 
                             'FunctionRequirements__c', 'Dev_Ticket__c'],
        originRecordId: null,
        originObjectType: null
    };
    
    @track selectedNode = null;
    
    /**
     * フィルター変更イベントのハンドラ
     */
    handleFilterChange(event) {
        this.filterConditions = { ...event.detail };
    }
    
    /**
     * ノード選択イベントのハンドラ
     */
    handleNodeSelect(event) {
        this.selectedNode = event.detail;
    }
}
```

### **relationGraphApp.js-meta.xml**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<LightningComponentBundle xmlns="http://soap.sforce.com/2006/04/metadata">
    <apiVersion>60.0</apiVersion>
    <isExposed>true</isExposed>
    <targets>
        <target>lightning__AppPage</target>
    </targets>
</LightningComponentBundle>
```

---

## **🔧 2. フィルターパネル（filterPanel）**

### **filterPanel.html**

```html
<template>
    <lightning-card title="フィルター">
        <!-- ステータスフィルター -->
        <div class="slds-p-around_small">
            <h3 class="slds-text-heading_small slds-m-bottom_x-small">ステータス</h3>
            <lightning-checkbox-group
                name="statusFilter"
                options={statusOptions}
                value={selectedStatuses}
                onchange={handleStatusChange}>
            </lightning-checkbox-group>
        </div>
        
        <!-- オブジェクトタイプフィルター -->
        <div class="slds-p-around_small">
            <h3 class="slds-text-heading_small slds-m-bottom_x-small">オブジェクトタイプ</h3>
            <lightning-checkbox-group
                name="objectTypeFilter"
                options={objectTypeOptions}
                value={selectedObjectTypes}
                onchange={handleObjectTypeChange}>
            </lightning-checkbox-group>
        </div>
        
        <!-- 起点レコードフィルター -->
        <div class="slds-p-around_small">
            <h3 class="slds-text-heading_small slds-m-bottom_x-small">起点レコード</h3>
            <lightning-radio-group
                name="originObjectType"
                options={originObjectOptions}
                value={originObjectType}
                onchange={handleOriginObjectChange}>
            </lightning-radio-group>
            
            <template if:true={originObjectType}>
                <lightning-input
                    type="search"
                    label="レコード検索"
                    placeholder="レコード名で検索..."
                    value={searchTerm}
                    onchange={handleSearchChange}>
                </lightning-input>
            </template>
        </div>
        
        <!-- ボタン -->
        <div class="slds-p-around_small slds-text-align_center">
            <lightning-button
                label="適用"
                variant="brand"
                onclick={handleApply}
                class="slds-m-right_x-small">
            </lightning-button>
            <lightning-button
                label="クリア"
                variant="neutral"
                onclick={handleClear}>
            </lightning-button>
        </div>
    </lightning-card>
</template>
```

### **filterPanel.js**

```javascript
import { LightningElement, track } from 'lwc';

export default class FilterPanel extends LightningElement {
    // ステータスオプション
    statusOptions = [
        { label: '未着手 (TODO)', value: 'TODO' },
        { label: '作業中 (WIP)', value: 'WIP' },
        { label: '完了 (DONE)', value: 'DONE' },
        { label: '対応中 (OPEN)', value: 'OPEN' },
        { label: 'クローズ (CLOSE)', value: 'CLOSE' }
    ];
    
    // オブジェクトタイプオプション
    objectTypeOptions = [
        { label: 'ユーザサービス', value: 'Dev_Service__c' },
        { label: '課題・要望', value: 'Issue__c' },
        { label: '対応施策', value: 'TechActionPlan__c' },
        { label: '機能要件', value: 'FunctionRequirements__c' },
        { label: '開発チケット', value: 'Dev_Ticket__c' }
    ];
    
    // 起点オブジェクトオプション
    originObjectOptions = [
        { label: 'Dev_Service', value: 'Dev_Service__c' },
        { label: 'Issue', value: 'Issue__c' },
        { label: 'TechActionPlan', value: 'TechActionPlan__c' },
        { label: 'FunctionRequirements', value: 'FunctionRequirements__c' },
        { label: 'Dev_Ticket', value: 'Dev_Ticket__c' }
    ];
    
    @track selectedStatuses = ['TODO', 'WIP', 'DONE', 'OPEN', 'CLOSE']; // 全ステータス
    @track selectedObjectTypes = ['Dev_Service__c', 'Issue__c', 'TechActionPlan__c',
                                   'FunctionRequirements__c', 'Dev_Ticket__c'];
    @track originObjectType = null;
    @track searchTerm = '';
    
    handleStatusChange(event) {
        this.selectedStatuses = event.detail.value;
    }
    
    handleObjectTypeChange(event) {
        this.selectedObjectTypes = event.detail.value;
    }
    
    handleOriginObjectChange(event) {
        this.originObjectType = event.detail.value;
    }
    
    handleSearchChange(event) {
        this.searchTerm = event.target.value;
    }
    
    handleApply() {
        // フィルター条件を親コンポーネントに通知
        const filterEvent = new CustomEvent('filterchange', {
            detail: {
                selectedStatuses: this.selectedStatuses,
                selectedObjectTypes: this.selectedObjectTypes,
                originRecordId: this.selectedRecordId, // 検索結果から取得
                originObjectType: this.originObjectType
            }
        });
        this.dispatchEvent(filterEvent);
    }
    
    handleClear() {
        // 全てリセット
        this.selectedStatuses = ['TODO', 'WIP', 'DONE', 'OPEN', 'CLOSE']; // 全ステータス
        this.selectedObjectTypes = ['Dev_Service__c', 'Issue__c', 'TechActionPlan__c',
                                     'FunctionRequirements__c', 'Dev_Ticket__c'];
        this.originObjectType = null;
        this.searchTerm = '';
        this.handleApply();
    }
}
```

---

## **🔧 3. グラフ表示（graphDisplay）**

### **graphDisplay.html**

```html
<template>
    <lightning-card title="グラフ">
        <!-- ツールバー -->
        <div slot="actions">
            <lightning-button-icon
                icon-name="utility:zoomin"
                alternative-text="ズームイン"
                onclick={handleZoomIn}>
            </lightning-button-icon>
            <lightning-button-icon
                icon-name="utility:zoomout"
                alternative-text="ズームアウト"
                onclick={handleZoomOut}>
            </lightning-button-icon>
            <lightning-button-icon
                icon-name="utility:expand_alt"
                alternative-text="フィット"
                onclick={handleFit}>
            </lightning-button-icon>
            <lightning-button-icon
                icon-name="utility:refresh"
                alternative-text="リセット"
                onclick={handleReset}>
            </lightning-button-icon>
        </div>
        
        <!-- グラフコンテナ -->
        <div class="graph-container" lwc:dom="manual"></div>
        
        <!-- 凡例 -->
        <div class="slds-p-around_small">
            <div class="legend">
                <h4 class="slds-text-heading_small">オブジェクトタイプ</h4>
                <div class="legend-item">
                    <span class="legend-icon hexagon"></span> Dev_Service
                </div>
                <div class="legend-item">
                    <span class="legend-icon circle"></span> Issue
                </div>
                <!-- 他の凡例... -->
            </div>
        </div>
    </lightning-card>
</template>
```

### **graphDisplay.js**

```javascript
import { LightningElement, api, wire } from 'lwc';
import { loadScript } from 'lightning/platformResourceLoader';
import CYTOSCAPE from '@salesforce/resourceUrl/cytoscape';
import getFilteredGraph from '@salesforce/apex/RelationGraphController.getFilteredGraph';

export default class GraphDisplay extends LightningElement {
    @api filterConditions;
    
    cy; // Cytoscapeインスタンス
    cytoscapeInitialized = false;
    
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
    
    initializeGraph() {
        const container = this.template.querySelector('.graph-container');
        
        this.cy = cytoscape({
            container: container,
            elements: [],
            style: [
                // Dev_Service__c: 六角形
                {
                    selector: 'node[objectType="Dev_Service__c"]',
                    style: {
                        'shape': 'hexagon',
                        'background-color': '#1589EE',
                        'label': 'data(label)'
                    }
                },
                // Issue__c: 円形
                {
                    selector: 'node[objectType="Issue__c"]',
                    style: {
                        'shape': 'ellipse',
                        'background-color': '#F59B00',
                        'label': 'data(label)'
                    }
                },
                // ステータス色（開発チケット系: TODO/WIP/DONE）
                {
                    selector: 'node[status="TODO"]',
                    style: {
                        'border-color': '#999999',
                        'border-width': 3
                    }
                },
                {
                    selector: 'node[status="WIP"]',
                    style: {
                        'border-color': '#FFC107',
                        'border-width': 3
                    }
                },
                {
                    selector: 'node[status="DONE"]',
                    style: {
                        'border-color': '#4CAF50',
                        'border-width': 3
                    }
                },
                // ステータス色（問い合わせ系: OPEN/CLOSE - Dev_Service__c用）
                {
                    selector: 'node[status="OPEN"]',
                    style: {
                        'border-color': '#FF9800',
                        'border-width': 3
                    }
                },
                {
                    selector: 'node[status="CLOSE"]',
                    style: {
                        'border-color': '#2196F3',
                        'border-width': 3
                    }
                },
                // エッジ
                {
                    selector: 'edge',
                    style: {
                        'width': 2,
                        'line-color': '#ccc',
                        'target-arrow-color': '#ccc',
                        'target-arrow-shape': 'triangle',
                        'curve-style': 'bezier'
                    }
                }
            ],
            layout: {
                name: 'dagre',
                rankDir: 'LR',
                nodeSep: 50,
                rankSep: 100
            }
        });
        
        // イベントリスナー
        this.cy.on('tap', 'node', (event) => {
            const nodeData = event.target.data();
            this.handleNodeClick(nodeData);
        });
        
        // データ取得
        this.loadGraphData();
    }
    
    @wire(getFilteredGraph, {
        originRecordId: '$filterConditions.originRecordId',
        originObjectType: '$filterConditions.originObjectType',
        selectedStatuses: '$filterConditions.selectedStatuses',
        selectedObjectTypes: '$filterConditions.selectedObjectTypes'
    })
    wiredGraphData({ error, data }) {
        if (data) {
            const elements = JSON.parse(data);
            this.cy.elements().remove();
            this.cy.add(elements);
            this.cy.layout({ name: 'dagre', rankDir: 'LR' }).run();
        } else if (error) {
            console.error('データ取得エラー:', error);
        }
    }
    
    handleNodeClick(nodeData) {
        const selectEvent = new CustomEvent('nodeselect', {
            detail: nodeData
        });
        this.dispatchEvent(selectEvent);
    }
    
    handleZoomIn() {
        this.cy.zoom(this.cy.zoom() * 1.2);
    }
    
    handleZoomOut() {
        this.cy.zoom(this.cy.zoom() * 0.8);
    }
    
    handleFit() {
        this.cy.fit();
    }
    
    handleReset() {
        this.cy.reset();
    }
}
```

### **graphDisplay.css**

```css
.graph-container {
    width: 100%;
    height: 600px;
    border: 1px solid #ddd;
}

.legend {
    display: flex;
    flex-wrap: wrap;
    gap: 10px;
}

.legend-item {
    display: flex;
    align-items: center;
    gap: 5px;
}

.legend-icon {
    width: 20px;
    height: 20px;
    display: inline-block;
}

.legend-icon.hexagon {
    background-color: #1589EE;
    clip-path: polygon(50% 0%, 100% 25%, 100% 75%, 50% 100%, 0% 75%, 0% 25%);
}

.legend-icon.circle {
    background-color: #F59B00;
    border-radius: 50%;
}
```

---

## **🔧 4. 詳細パネル（detailPanel）**

### **detailPanel.html**

```html
<template>
    <lightning-card title="詳細">
        <template if:true={selectedNode}>
            <!-- レコード名（ハイパーリンク） -->
            <div class="slds-p-around_small">
                <h3 class="slds-text-heading_small">
                    <a href={recordUrl} target="_blank">{selectedNode.label}</a>
                </h3>
                <p>ステータス: <lightning-badge label={selectedNode.status}></lightning-badge></p>
            </div>
            
            <!-- 関連レコード -->
            <div class="slds-p-around_small">
                <h4 class="slds-text-heading_small">上流レコード</h4>
                <template for:each={upstreamRecords} for:item="record">
                    <div key={record.id} class={record.cssClass}>
                        <lightning-icon 
                            if:true={record.isFilteredOut} 
                            icon-name="utility:hide" 
                            size="x-small">
                        </lightning-icon>
                        <a href={record.url} target="_blank">{record.name}</a>
                    </div>
                </template>
            </div>
            
            <div class="slds-p-around_small">
                <h4 class="slds-text-heading_small">下流レコード</h4>
                <template for:each={downstreamRecords} for:item="record">
                    <div key={record.id} class={record.cssClass}>
                        <lightning-icon 
                            if:true={record.isFilteredOut} 
                            icon-name="utility:hide" 
                            size="x-small">
                        </lightning-icon>
                        <a href={record.url} target="_blank">{record.name}</a>
                    </div>
                </template>
            </div>
        </template>
        
        <template if:false={selectedNode}>
            <div class="slds-p-around_small slds-text-align_center">
                <p>ノードを選択してください</p>
            </div>
        </template>
    </lightning-card>
</template>
```

### **detailPanel.js**

```javascript
import { LightningElement, api, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getRelatedRecords from '@salesforce/apex/RelationGraphController.getRelatedRecords';

export default class DetailPanel extends NavigationMixin(LightningElement) {
    @api selectedNode;
    @api filterConditions;
    
    upstreamRecords = [];
    downstreamRecords = [];
    
    @wire(getRelatedRecords, {
        recordId: '$selectedNode.id',
        objectType: '$selectedNode.objectType'
    })
    wiredRelatedRecords({ error, data }) {
        if (data) {
            this.upstreamRecords = this.markFilteredRecords(data.upstream);
            this.downstreamRecords = this.markFilteredRecords(data.downstream);
        } else if (error) {
            console.error('関連レコード取得エラー:', error);
        }
    }
    
    get recordUrl() {
        if (!this.selectedNode) return '';
        return `/lightning/r/${this.selectedNode.objectType}/${this.selectedNode.id}/view`;
    }
    
    markFilteredRecords(records) {
        return records.map(record => {
            const isStatusMatch = this.filterConditions.selectedStatuses.includes(record.status);
            const isTypeMatch = this.filterConditions.selectedObjectTypes.includes(record.objectType);
            const isFilteredOut = !(isStatusMatch && isTypeMatch);
            
            return {
                ...record,
                isFilteredOut: isFilteredOut,
                cssClass: isFilteredOut ? 'record-item filtered-out' : 'record-item',
                url: `/lightning/r/${record.objectType}/${record.id}/view`
            };
        });
    }
}
```

### **detailPanel.css**

```css
.filtered-out {
    opacity: 0.5;
    font-style: italic;
}

.record-item {
    padding: 5px;
    margin: 3px 0;
}
```

---

## **📌 実装のポイント**

### **1. Static Resourceの使用**
- ✅ CDNからの読み込みは禁止
- ✅ `loadScript` でCytoscape.jsを読み込む

### **2. イベント駆動**
- ✅ CustomEventで親子間通信
- ✅ `@api` でプロパティを公開

### **3. NavigationMixin**
- ✅ レコードページへのナビゲーション
- ✅ 新しいタブで開く（`target="_blank"`）

### **4. エラーハンドリング**
- ✅ `@wire` の error ハンドリング
- ✅ コンソールにエラーログ出力

---

## **🔍 実装チェックリスト**

- [ ] 全コンポーネントが作成されている
- [ ] Apexメソッドのインポートが正確である
- [ ] `NavigationMixin` が適切に使用されている
- [ ] Cytoscape.jsがStatic Resourceから読み込まれている
- [ ] イベントハンドラが正しく動作する
- [ ] CSSがSLDSに準拠している

---

**📌 このガイドに従って実装すれば、仕様通りのLWCが完成します。**
