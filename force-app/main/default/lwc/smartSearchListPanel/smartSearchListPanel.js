import { api, LightningElement, track } from 'lwc';
import UserId from '@salesforce/user/Id';

const matchedContactColumns = [
    { label: '', type: "button", initialWidth: 156, typeAttributes: {
        label: 'Merge to Contact', name: 'merge', title: 'Merge to Contact',  
        disabled: false,  value: 'Merge to Contact',  iconPosition: 'left'  
    }},
    { label: 'CONTACT NAME', fieldName: 'urlToRedirect', type: "url", typeAttributes: {
        tooltip: { fieldName: 'name' }, label: { fieldName: 'name' }, target: "_blank"
        }, hideDefaultActions: "true" },
    { label: 'ACCOUNT NAME', fieldName: 'accountName', hideDefaultActions: "true" },
    { label: 'ACCOUNT RECORD TYPE', fieldName: 'accountRecordType', hideDefaultActions: "true" },
    { label: 'EMAIL', fieldName: 'email', type: 'email', hideDefaultActions: "true" },
    { label: 'PHONE', fieldName: 'phone', type: 'phone', hideDefaultActions: "true" },
    { label: 'STATUS', fieldName: 'stage', hideDefaultActions: "true" },
    { label: 'CREATED DATE', fieldName: 'dateCreated', hideDefaultActions: "true" },
    { label: 'LAST MODIFIED DATE', fieldName: 'dateModified', hideDefaultActions: "true" },
];

const leadColumns = [
    { label: 'LEAD NAME', fieldName: 'urlToRedirect', type: "url", typeAttributes: {
        tooltip: { fieldName: 'name' }, label: { fieldName: 'name' }, target: "_blank"
        }, hideDefaultActions: "true" },
    { label: 'ACCOUNT NAME', fieldName: 'accountName', hideDefaultActions: "true" },
    { label: 'ACCOUNT RECORD TYPE', fieldName: 'accountRecordType', hideDefaultActions: "true" },
    { label: 'EMAIL', fieldName: 'email', type: 'email', hideDefaultActions: "true" },
    { label: 'PHONE', fieldName: 'phone', type: 'phone', hideDefaultActions: "true" },
    { label: 'EMPLOYEE SIZE', fieldName: 'companySize', hideDefaultActions: "true" },
    { label: 'LEAD STATUS', fieldName: 'stage', hideDefaultActions: "true" },
    { label: 'CREATED DATE', fieldName: 'dateCreated',hideDefaultActions: "true" },
    { label: 'LAST MODIFIED DATE', fieldName: 'dateModified', hideDefaultActions: "true" },
    { label: 'LEAD OWNER', fieldName: 'ownerName', hideDefaultActions: "true" },
    { label: 'LEAD SOURCE', fieldName: 'leadSource', hideDefaultActions: "true" },
];

const protectedOppsColumns = [
    { label: 'CONTACT NAME', fieldName: 'urlToRedirect', type: "url", typeAttributes: {
        tooltip: { fieldName: 'name' }, label: { fieldName: 'name' }, target: "_blank"
        }, hideDefaultActions: "true" },
    { label: 'ACCOUNT NAME', fieldName: 'accountName', hideDefaultActions: "true" },
    { label: 'ACCOUNT RECORD TYPE', fieldName: 'accountRecordType', hideDefaultActions: "true" },
    { label: 'EMAIL', fieldName: 'email', type: 'email', hideDefaultActions: "true" },
    { label: 'PHONE', fieldName: 'phone', type: 'phone', hideDefaultActions: "true" },
    { label: 'STAGE', fieldName: 'stage', hideDefaultActions: "true" },
    { label: 'CREATED DATE', fieldName: 'dateCreated', hideDefaultActions: "true" },
    { label: 'CLOSED DATE', fieldName: 'closedDate', hideDefaultActions: "true" },
    { label: 'LAST MODIFIED DATE', fieldName: 'dateModified', hideDefaultActions: "true" },
    { label: 'CURRENT OWNER', fieldName: 'ownerName', hideDefaultActions: "true" },
];

const unprotectedOppsColumns = [
    { label: 'CONTACT NAME', fieldName: 'urlToRedirect', type: "url", typeAttributes: {
        tooltip: { fieldName: 'name' }, label: { fieldName: 'name' }, target: "_blank"
        }, hideDefaultActions: "true" },
    { label: 'ACCOUNT NAME', fieldName: 'accountName', hideDefaultActions: "true" },
    { label: 'ACCOUNT RECORD TYPE', fieldName: 'accountRecordType', hideDefaultActions: "true" },
    { label: 'EMAIL', fieldName: 'email', type: 'email', hideDefaultActions: "true" },
    { label: 'PHONE', fieldName: 'phone', type: 'phone', hideDefaultActions: "true" },
    { label: 'STAGE', fieldName: 'stage', hideDefaultActions: "true" },
    { label: 'CREATED DATE', fieldName: 'dateCreated', hideDefaultActions: "true" },
    { label: 'LAST MODIFIED DATE', fieldName: 'dateModified', hideDefaultActions: "true" },
    { label: 'CURRENT OWNER', fieldName: 'ownerName', hideDefaultActions: "true" },
];
const takeOwnerShipAction = [
    { label: '', type: "button", initialWidth: 144, typeAttributes: {
            label: 'Take Ownership', name: 'takeOwnership',  title: 'Take Ownership',  
            disabled: false,  value: 'Take Ownership',  iconPosition: 'left'  
        }
    }
];

const mergeToLeadActionProtectedLeads = [
    { label: '', type: "button", initialWidth: 90, typeAttributes: {
            label: 'Merge', name: 'mergeToLeadProtected',  title: 'Merge',  
            disabled: false,  value: 'Merge',  iconPosition: 'left'  
        }
    }
];

const mergeToLeadActionUnprotectedLeads = [
    { label: '', type: "button", initialWidth: 90, typeAttributes: {
            label: 'Merge', name: 'mergeToLeadUnprotected',  title: 'Merge',  
            disabled: false,  value: 'Merge',  iconPosition: 'left'  
        }
    }
];

export default class SmartSearchListPanel extends LightningElement {

    @api urlParameters;
    lowerCaseParams = {};
    matchedContactColumns = matchedContactColumns;
    @api matchedContactData;
    leadColumns = leadColumns;
    @api protectedLeadData;
    protectedOppsColumns = protectedOppsColumns;
    @api protectedOppsCurrentOwnersData;
    @api protectedOppsActivePipeData;
    unprotectedOppsColumns = unprotectedOppsColumns;
    @api unprotectedOppsData;
    @api unprotectedLeadsData;
    @api partnerOppsData;
    @track isDialogVisible = false;
    @track originalMessage;
    @track displayMessage;
    @track params;
    @track messageConfirmationDialog;
    @track cancelLabel;

    get unprotectedLeadColumns() {
        Object.keys(this.urlParameters).forEach(key => {
            let keyToLower = key.toLowerCase();
            this.lowerCaseParams[keyToLower] = this.urlParameters[key];
        });
        if (this.lowerCaseParams && ((typeof this.lowerCaseParams.dnis !== "undefined" && this.lowerCaseParams.dnis !== '') ||
            (typeof this.lowerCaseParams.source !== "undefined" && this.lowerCaseParams.source?.toUpperCase() === 'INVOCA')))  {
            return [ ...takeOwnerShipAction, ... this.leadColumns];
        } else if (this.lowerCaseParams && 
            (typeof this.lowerCaseParams.source !== "undefined" && this.lowerCaseParams.source?.toUpperCase() === 'DRIFT')) {
                return [ ...mergeToLeadActionUnprotectedLeads, ... this.leadColumns];
        }
        return this.leadColumns;
    }

    get protectedLeadColumns() {
        Object.keys(this.urlParameters).forEach(key => {
            let keyToLower = key.toLowerCase();
            this.lowerCaseParams[keyToLower] = this.urlParameters[key];
        });
        if (this.lowerCaseParams && 
            (typeof this.lowerCaseParams.source !== "undefined" && this.lowerCaseParams.source?.toUpperCase() === 'DRIFT')) {
                return [ ...mergeToLeadActionProtectedLeads, ... this.leadColumns];
        }
        return this.leadColumns;
    }

    handleMergeToContactAction(event) {
        if(event.detail.action.name === 'merge'){
            //parameter needed to merge 
            this.params = event.detail.row.id;
            this.originalMessage = 'mergeToContact';
            this.cancelLabel = null
            this.messageConfirmationDialog = 'Are you sure you want to update this contact?';
            //shows the component
            this.isDialogVisible = true;
        }
    }

    handleLeadAction(event) {
        if(event.detail.action.name === 'takeOwnership'){
            //parameter needed to merge 
            this.params = event.detail.row.id;
            this.originalMessage = 'takeOwnership';
            this.cancelLabel = null;
            this.messageConfirmationDialog = 'Are you sure that this is the lead you want to claim?';
            //shows the component
            this.isDialogVisible = true;
        } else if (event.detail.action.name === 'mergeToLeadProtected') {
            //parameter needed to merge 
            this.params = event.detail.row.id;
            this.originalMessage = 'mergeToLeadProtected';
            this.cancelLabel = null;
            this.messageConfirmationDialog = 'Are you sure you want to merge this lead?';
            //shows the message component
            this.isDialogVisible = true;
        } else if (event.detail.action.name === 'mergeToLeadUnprotected') {
            if(event.detail.row.ownerId === UserId){
                this.params = event.detail.row.id;
                this.originalMessage = 'mergeToLeadUnprotectedSameOwner';
                this.cancelLabel = null;
                this.messageConfirmationDialog = 'Are you sure you want to merge this lead?';
                //shows the message component
                this.isDialogVisible = true;
            //parameter needed to merge 
            }else{
                this.params = event.detail.row.id;
                this.originalMessage = 'mergeToLeadUnprotected';
                this.cancelLabel = 'Cancel';
                this.messageConfirmationDialog = 'Do you also want to take ownership of this lead?';
                //shows the message component
                this.isDialogVisible = true;
            }
        }
    }

    handleButtonClick(event) {
        if (event.detail.originalMessage === 'mergeToContact') {
            if (event.detail.status === 'confirm') {
                this.dispatchEvent(new CustomEvent('merge', {detail: event.detail.params}));
            }
        } else if (event.detail.originalMessage === 'takeOwnership') {
            if(event.detail.status === 'confirm') {
                this.dispatchEvent(new CustomEvent('takeownership', {detail: event.detail.params}));
            }
        } else if (event.detail.originalMessage === 'mergeToLeadUnprotectedSameOwner') {
            if(event.detail.status === 'confirm') {
                this.dispatchEvent(new CustomEvent('mergetolead', {
                    detail: {
                        leadId : event.detail.params,
                        takeOwnership: false
                        }
                    })
                );
            }
        } else if (event.detail.originalMessage === 'mergeToLeadUnprotected') {
            console.log(event.detail.status);
            if (event.detail.status === 'confirm') {
                this.dispatchEvent(new CustomEvent('mergetolead', {
                    detail: {
                        leadId : event.detail.params,
                        takeOwnership: true
                        }
                    })
                );
            } else if (event.detail.status === 'reject') {
                this.dispatchEvent(new CustomEvent('mergetolead', {
                    detail: {
                        leadId : event.detail.params,
                        takeOwnership: false
                        }
                    })
                );
            }
        } else if (event.detail.originalMessage === 'mergeToLeadProtected') {
            if (event.detail.status === 'confirm') {
                this.dispatchEvent(new CustomEvent('mergetolead', {
                    detail: {
                        leadId : event.detail.params,
                        takeOwnership: false
                        }
                    })
                );
            }
        }
        this.isDialogVisible = false;
    }

    @api
    handleScrollToDiv(message) {
        const toDiv = this.template.querySelector('[data-id="' + message.data + '"]');
        toDiv?.scrollIntoView({behavior: "smooth", block: "start", inline: "nearest"});
    }

}