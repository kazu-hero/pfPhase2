import { LightningElement, api } from 'lwc';
import { loadScript } from 'lightning/platformResourceLoader';
import CYTOSCAPE from '@salesforce/resourceUrl/cytoscape';
import DAGRE from '@salesforce/resourceUrl/dagre';
import CYTOSCAPE_DAGRE from '@salesforce/resourceUrl/cytoscapeDagre';
import getFilteredGraph from '@salesforce/apex/RelationGraphController.getFilteredGraph';

export default class MiniGraphDisplay extends LightningElement {
    @api recordId;
    @api objectApiName;
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
                // Cytoscapeとdagreプラグインの有効化
                if (window.cytoscape && window.cytoscapeDagre) {
                    window.cytoscape.use(window.cytoscapeDagre);
                } else {
                }
                this.fetchAndRenderGraph();
            })
            .catch(error => {
                // ...
            });
    }

    disconnectedCallback() {
        // イベントリスナーのクリーンアップ
        // 何もしない（リスナー・オブザーバー削除）
    }

    async fetchAndRenderGraph() {
        try {
            const params = {
                originRecordId: this.recordId,
                originObjectType: this.objectApiName,
                selectedStatuses: null,
                selectedObjectTypes: null
            };
            const data = await getFilteredGraph(params);
            let elements = [];
            elements = JSON.parse(data);
            // 起点ノードにisOrigin属性を付与
            // isOrigin属性付与は不要（id直接指定でstyleを当てる）
            this.initializeGraph(elements);
        } catch (error) {
            // ...
        }
    }

    initializeGraph(elements) {
        const container = this.template.querySelector('.mini-graph-container');
        if (!container) {
            return;
        }
        // containerのサイズ・状態を出力

        // Cytoscape初期化
        this.cy = cytoscape({
            container: container,
            elements: elements,
            style: [
                // ノードの基本スタイル
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
                // ステータス色分け
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
                },
                // ★起点ノード用style（id直接指定・一番最後で強制上書き、枠のみ赤）
                {
                    selector: `node[id="${this.recordId}"]`,
                    style: {
                        'border-color': 'red',
                        'border-width': 10,
                        'border-style': 'solid',
                        'border-opacity': 1,
                        'z-index': 9999
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
        // ...
    }

    // ズームボタン削除のため不要
}
