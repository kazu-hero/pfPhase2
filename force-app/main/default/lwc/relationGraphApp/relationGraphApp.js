import { LightningElement, track } from 'lwc';

export default class RelationGraphApp extends LightningElement {
    @track filterConditions = {
        selectedStatuses: ['TODO', 'WIP', 'DONE', 'OPEN', 'CLOSE'],
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
