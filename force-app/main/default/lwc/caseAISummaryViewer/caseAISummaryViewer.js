import { LightningElement, api } from 'lwc';

export default class CaseAISummaryViewer extends LightningElement {
    @api recordId;

    connectedCallback() {
        // Read recordId from VF page URL
        const params = new URLSearchParams(window.location.search);
        this.recordId = params.get('recordId');
    }
}