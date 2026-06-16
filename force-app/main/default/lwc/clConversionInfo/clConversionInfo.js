/* globals CL */
import {LightningElement, track, api} from "lwc";
import {clAppReady} from "c/clService";
import LeadQualificationsection from '@salesforce/label/c.ClConversionInfoLeadQualificationsection';
import SelectedQualification from '@salesforce/label/c.ClConversionInfoSelectedQualification';
import None from '@salesforce/label/c.ClConversionInfoNone';

export default class ClConversionInfo extends LightningElement {
    @track isExpanded = false;
    @track selectedLeadQualification = null;
    @track opportunitiesCount = 0;
    @track isLoaded = false;
    @track isLoading = false;
    @api isLeadRecordTypeSales = false;
    @track label = {
        LeadQualificationsection,
        SelectedQualification,
        None
    };

    get isExpandedView() {
        return this.isExpanded && this.isLoaded;
    }

    get isCollapsedView() {
        return !this.isExpanded && this.isLoaded;
    }

    connectedCallback() {
        clAppReady(this.onClAppReady.bind(this));
    }

    onClAppReady() {
        CL.app.rx.leadQualifications.subscribe(leadQualifications => {
            this.selectedLeadQualification = CL.app.selectedLeadQualification;
        });
        CL.app.rx.loadingStatus.subscribe(loadingStatus => {
            this.isLoading = loadingStatus.isLeadLoading || loadingStatus.isOpportunitiesLoading;
            this.isLoaded = loadingStatus.isLeadLoaded && loadingStatus.isOpportunitiesLoaded;
        });
    }

    toggleIsExpanded() {
        this.isExpanded = !this.isExpanded;
    }
}