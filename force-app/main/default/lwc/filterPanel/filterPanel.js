import { LightningElement, track } from 'lwc';
import searchOriginRecords from '@salesforce/apex/RelationGraphController.searchOriginRecords';

export default class FilterPanel extends LightningElement {
    // ステータスオプション
    statusOptions = [
        { label: '未着手 (TODO)', value: 'TODO' },
        { label: '作業中 (WIP)', value: 'WIP' },
        { label: '保留 (PENDING)', value: 'PENDING' },
        { label: '完了 (DONE)', value: 'DONE' },
        { label: '対応中 (OPEN)', value: 'OPEN' },
        { label: 'クローズ (CLOSE)', value: 'CLOSE' },
        { label: '中止 (DROP)', value: 'DROP' }
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
        { label: 'ユーザサービス', value: 'Dev_Service__c' },
        { label: '課題・要望', value: 'Issue__c' },
        { label: '対応施策', value: 'TechActionPlan__c' },
        { label: '機能要件', value: 'FunctionRequirements__c' },
        { label: '開発チケット', value: 'Dev_Ticket__c' }
    ];
    
    @track selectedStatuses = ['TODO', 'WIP', 'PENDING', 'DONE', 'OPEN', 'CLOSE', 'DROP'];
    @track selectedObjectTypes = ['Dev_Service__c', 'Issue__c', 'TechActionPlan__c',
                                   'FunctionRequirements__c', 'Dev_Ticket__c'];
    @track originObjectType = null;
    @track searchTerm = '';
    @track originRecordOptions = [];
    @track selectedOriginRecordId = null;
    
    handleStatusChange(event) {
        this.selectedStatuses = event.detail.value;
    }
    
    handleObjectTypeChange(event) {
        this.selectedObjectTypes = event.detail.value;
    }
    

    handleOriginObjectChange(event) {
        this.originObjectType = event.detail.value;
        this.originRecordOptions = [];
        this.selectedOriginRecordId = null;
        this.searchTerm = '';
    }

    async handleSearchChange(event) {
        this.searchTerm = event.target.value;
        this.selectedOriginRecordId = null;
        if (this.originObjectType && this.searchTerm && this.searchTerm.length > 1) {
            try {
                const results = await searchOriginRecords({
                    objectType: this.originObjectType,
                    searchTerm: `%${this.searchTerm}%`
                });
                // objectTypeもoptionに持たせる
                this.originRecordOptions = results.map(r => ({ label: r.Name, value: r.Id, objectType: this.originObjectType }));
            } catch (e) {
                this.originRecordOptions = [];
            }
        } else {
            this.originRecordOptions = [];
        }
    }

    handleOriginRecordSelect(event) {
        this.selectedOriginRecordId = event.detail.value;
        // 選択したoptionからobjectTypeもセット
        const selectedOption = this.originRecordOptions.find(opt => opt.value === event.detail.value);
        if (selectedOption && selectedOption.objectType) {
            this.originObjectType = selectedOption.objectType;
        }
    }
    
    handleApply() {
        // フィルター条件を親コンポーネントに通知
        const detail = {
            selectedStatuses: this.selectedStatuses,
            selectedObjectTypes: this.selectedObjectTypes,
            originRecordId: this.selectedOriginRecordId,
            originObjectType: this.originObjectType
        };
        const filterEvent = new CustomEvent('filterchange', {
            detail
        });
        this.dispatchEvent(filterEvent);
    }
    
    handleClear() {
        // 全てリセット
        this.selectedStatuses = ['TODO', 'WIP', 'PENDING', 'DONE', 'OPEN', 'CLOSE', 'DROP'];
        this.selectedObjectTypes = ['Dev_Service__c', 'Issue__c', 'TechActionPlan__c',
                                     'FunctionRequirements__c', 'Dev_Ticket__c'];
        this.originObjectType = null;
        this.searchTerm = '';
        this.handleApply();
    }
}