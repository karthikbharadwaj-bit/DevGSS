import {api, LightningElement, track} from 'lwc';
import KycDetailsStyles from '@salesforce/resourceUrl/KycDetailsStyles';
import { loadStyle } from 'lightning/platformResourceLoader';

export default class KycSectionDetails extends LightningElement {
    @api isOpen = false;
    @api files = [];
    @api sectionName;
    @api acceptedFileFormats = '';
    @api sectionId = '';
    @api isFormLocked;

    renderedCallback() {
        Promise.all([
            loadStyle(this, KycDetailsStyles)
        ]);        
    }

    get modalCls() {
        return `slds-modal${this.isOpen ? " slds-fade-in-open" : ""}`;
    }
    get backdropCls() {
        return `slds-backdrop${this.isOpen ? " slds-backdrop_open" : ""}`;
    }
    get filesToShow() {
        return this.files && this.files.filter(f => !f.isDeleted);
    }
    get hasFilesToShow() {
        return this.files && Object.values(this.files).filter(f => !f.isDeleted).length;
    }

    handleFileSelection(event) {
        if (event.target.files.length > 0) {
            window.app.setFile(this.sectionId.substring(1), event.target.files);
            /* To be able to reselect same file */
            event.target.value = '';
        }
    }

    onSubmit() {
        window.app.toggleSectionDetails();
    }
}