import { LightningElement, api } from 'lwc';
import { loadScript } from 'lightning/platformResourceLoader';
import CYTOSCAPE from '@salesforce/resourceUrl/cytoscape';
import DAGRE from '@salesforce/resourceUrl/dagre';
import CYTOSCAPE_DAGRE from '@salesforce/resourceUrl/cytoscapeDagre';
import getFilteredGraph from '@salesforce/apex/RelationGraphController.getFilteredGraph';

export default class GraphDisplay extends LightningElement {
    _filterConditions;
    _lastGraphData;
    @api
    get filterConditions() {
        return this._filterConditions;
    }
    set filterConditions(value) {
        this._filterConditions = value;
        // ...existing code...
        if (this.cy) {
            this.fetchAndRenderGraph();
        }
    }
    
    cy;
    cytoscapeInitialized = false;
    
    renderedCallback() {
        if (this.cytoscapeInitialized) {
            return;
        }
        this.cytoscapeInitialized = true;
        
        Promise.all([
            loadScript(this, CYTOSCAPE),
            loadScript(this, DAGRE),
            loadScript(this, CYTOSCAPE_DAGRE)
        ])
            .then(() => {
                this.initializeGraph();
            })
            .catch(error => {
                // ...existing code...
            });
    }
    
    initializeGraph() {
        const container = this.template.querySelector('.graph-container');
        
        this.cy = cytoscape({
            container: container,
            elements: [],
            style: [
                // ノードの基本スタイル（全タイプ黒枠・白塗り、ラベルはノード下に表示）
                {
                    selector: 'node',
                    style: {
                        'label': 'data(label)',
                        'text-valign': 'center',
                        'text-halign': 'center',
                        'text-margin-y': 40,
                        'text-justification': 'under',
                        'text-wrap': 'wrap',
                        'text-max-width': 60,
                        'font-size': '12px',
                        'width': 60,
                        'height': 60,
                        'border-width': 3,
                        'border-color': '#222',
                        'background-color': '#fff'
                    }
                },
                // ユーザサービス:三角形（#1976D2）
                {
                    selector: 'node[objectType="Dev_Service__c"]',
                    style: {
                        'shape': 'triangle',
                        'background-color': '#1976D2'
                    }
                },
                // 課題・要望:四角形（#388E3C）
                {
                    selector: 'node[objectType="Issue__c"]',
                    style: {
                        'shape': 'rectangle',
                        'background-color': '#388E3C'
                    }
                },
                // 対応施策:ひし形（#D32F2F）
                {
                    selector: 'node[objectType="TechActionPlan__c"]',
                    style: {
                        'shape': 'diamond',
                        'background-color': '#D32F2F'
                    }
                },
                // 機能要件:六角形（#FBC02D）
                {
                    selector: 'node[objectType="FunctionRequirements__c"]',
                    style: {
                        'shape': 'hexagon',
                        'background-color': '#FBC02D'
                    }
                },
                // 開発チケット:丸（#512DA8）
                {
                    selector: 'node[objectType="Dev_Ticket__c"]',
                    style: {
                        'shape': 'ellipse',
                        'background-color': '#512DA8'
                    }
                },
                // ステータス色分け（塗り色のみ変化）
                {
                    selector: 'node[status="TODO"]',
                    style: {
                        'background-color': '#FFFFFF'
                    }
                },
                {
                    selector: 'node[status="WIP"]',
                    style: {
                        'background-color': '#FFB300'
                    }
                },
                {
                    selector: 'node[status="DONE"]',
                    style: {
                        'background-color': '#388E3C'
                    }
                },
                {
                    selector: 'node[status="OPEN"]',
                    style: {
                        'background-color': '#D84315'
                    }
                },
                {
                    selector: 'node[status="CLOSE"]',
                    style: {
                        'background-color': '#1976D2'
                    }
                },
                {
                    selector: 'node[status="PENDING"]',
                    style: {
                        'background-color': '#B3E5FC'
                    }
                },
                {
                    selector: 'node[status="DROP"]',
                    style: {
                        'background-color': '#BDBDBD'
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
            },
            minZoom: 0.5,
            maxZoom: 2,
            wheelSensitivity: 0.2
        });
        
        // イベントリスナー
        this.cy.on('tap', 'node', (event) => {
            const nodeData = event.target.data();
            this.handleNodeClick(nodeData);
        });
        
        // データ取得
        this.loadGraphData();
    }
    

    async fetchAndRenderGraph() {
        try {
            const params = {
                originRecordId: this._filterConditions?.originRecordId,
                originObjectType: this._filterConditions?.originObjectType,
                selectedStatuses: this._filterConditions?.selectedStatuses,
                selectedObjectTypes: this._filterConditions?.selectedObjectTypes
            };
            const data = await getFilteredGraph(params);
            this._lastGraphData = data;
            if (this.cy) {
                let elements;
                try {
                    elements = JSON.parse(data);
                } catch (e) {
                    elements = [];
                }
                // ...existing code...
                this.cy.elements().remove();
                this.cy.add(elements);
                this.cy.layout({ name: 'dagre', rankDir: 'LR' }).run();
                // グラフ全体が見えるようにfitとcenterを呼ぶ
                // 全体が見えるようにfitのみ呼ぶ（padding=10）
                this.cy.fit(undefined, 10);
            }
        } catch (error) {
            // ...existing code...
        }
    }
    
    handleNodeClick(nodeData) {
        const selectEvent = new CustomEvent('nodeselect', {
            detail: nodeData
        });
        this.dispatchEvent(selectEvent);
    }
    
    handleZoomIn() {
        if (this.cy) {
            this.cy.zoom(this.cy.zoom() * 1.2);
        }
    }
    
    handleZoomOut() {
        if (this.cy) {
            this.cy.zoom(this.cy.zoom() * 0.8);
        }
    }
    
    handleFit() {
        if (this.cy) {
            this.cy.fit();
        }
    }
    
    handleReset() {
        if (this.cy) {
            this.cy.reset();
        }
    }
    
    loadGraphData() {
        if (this.cy && this._lastGraphData) {
            const elements = JSON.parse(this._lastGraphData);
            this.cy.elements().remove();
            this.cy.add(elements);
            this.cy.layout({ name: 'dagre', rankDir: 'LR' }).run();
            // グラフ全体が見えるようにfitとcenterを呼ぶ
            // 全体が見えるようにfitのみ呼ぶ（padding=10）
            this.cy.fit(undefined, 10);
        }
    }
}
