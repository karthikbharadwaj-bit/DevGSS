import { LightningElement, api, wire } from 'lwc';
import getOpenChildModRecords from '@salesforce/apex/ModController.getOpenModRecords';
import { getRecord } from 'lightning/uiRecordApi';

export default class CaseWarningBanner extends LightningElement {
    @api recordId; // The Case record Id passed to the component

    hasOpenChild = false;
    modName = '';
    modRecordCreator = '';
    modRecordUrl = '';

    @wire(getOpenChildModRecords, { caseId: '$recordId' })
    wiredOpenChildRecords({ error, data }) {
        if (data && data.length > 0) {
            this.hasOpenChild = true;
            const modRecord = data[0];
            this.modName = modRecord.Name;
            this.modRecordCreator = modRecord.CreatedBy.Name; 
            this.modRecordUrl = '/' + modRecord.Id;
        } else {
            this.hasOpenChild = false;
            this.modRecordCreator = '';
            this.modRecordUrl = '';
        }
    }
}