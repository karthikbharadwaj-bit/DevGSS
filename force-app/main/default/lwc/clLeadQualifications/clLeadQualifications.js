/* globals CL */
import {LightningElement, track} from 'lwc';
import {clAppReady, getLeadQualifications, handleError} from "c/clService";
import AvailableLeadQualifications from '@salesforce/label/c.clLeadQualificationsAvailableLeadQualifications';
import LeadQualification from '@salesforce/label/c.clLeadQualificationsLeadQualification';
import Lead from '@salesforce/label/c.clLeadQualificationsLead';
import Account from '@salesforce/label/c.clLeadQualificationsAccount';
import Opportunity from '@salesforce/label/c.clLeadQualificationsOpportunity';
import LastModifiedDate from '@salesforce/label/c.clLeadQualificationsLastModifiedDate';
import Loadmore from '@salesforce/label/c.clLeadQualificationsLoadmore';


export default class ClLeadQualifications extends LightningElement {
    @track leadQualifications = [];
    @track selectedLeadQualification = null;
    @track hasMoreQualifications = false;
    @track hasMoreQualificationsDisabled = false;
    @track label = {
        AvailableLeadQualifications,
        LeadQualification,
        Lead,
        Account,
        Opportunity,
        LastModifiedDate,
        Loadmore
    };

    connectedCallback() {
        clAppReady(this.onClAppReady.bind(this));
    }

    onClAppReady() {
        CL.app.rx.leadQualifications.subscribe(leadQualifications => {
            this.hasMoreQualifications = CL.app.hasMoreQualifications;
            this.leadQualifications = [...leadQualifications];
            this.selectedLeadQualification = CL.app.selectedLeadQualification;
        });
    }

    onSelectLeadQualification(event) {
        CL.app.selectLeadQualification(event.target.value);
    }

    loadMoreQualifications() {
        this.hasMoreQualificationsDisabled = true;
        getLeadQualifications(CL.app.leadId, this.leadQualifications.length)
            .then(r => {
                CL.app.setHasMoreQualifications(r.data.hasMoreQualifications);
                CL.app.setLeadQualifications(r.data.leadQualifications, true);
                this.hasMoreQualificationsDisabled = false;
            })
            .catch(handleError)
    }
}