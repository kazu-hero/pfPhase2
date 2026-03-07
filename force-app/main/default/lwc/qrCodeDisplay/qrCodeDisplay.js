import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import URL_FIELD from '@salesforce/schema/Campaign.URL__c';

export default class QrCodeDisplay extends LightningElement {
    @api recordId;
    @api qrSize = 300;

    @wire(getRecord, { recordId: '$recordId', fields: [URL_FIELD] })
    campaign;

    get qrUrl() {
        return getFieldValue(this.campaign.data, URL_FIELD);
    }

    get qrCodeImageUrl() {
        if (!this.qrUrl) return null;
        return `https://api.qrserver.com/v1/create-qr-code/?size=${this.qrSize}x${this.qrSize}&data=${encodeURIComponent(this.qrUrl)}`;
    }

    get hasUrl() {
        return this.qrUrl && this.qrUrl.trim().length > 0;
    }
}
