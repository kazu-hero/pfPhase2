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
            this.upstreamRecords = this.markFilteredRecords(data.upstream || []);
            this.downstreamRecords = this.markFilteredRecords(data.downstream || []);
        } else if (error) {
            this.upstreamRecords = [];
            this.downstreamRecords = [];
        }
    }
    
    get recordUrl() {
        if (!this.selectedNode) return '';
        return `/lightning/r/${this.selectedNode.objectType}/${this.selectedNode.id}/view`;
    }
    
    get hasUpstream() {
        return this.upstreamRecords && this.upstreamRecords.length > 0;
    }
    
    get hasDownstream() {
        return this.downstreamRecords && this.downstreamRecords.length > 0;
    }
    
    markFilteredRecords(records) {
        if (!records || !this.filterConditions) {
            return [];
        }
        
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