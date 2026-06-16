import { LightningElement, api, track, wire } from 'lwc';
import { getRecord, getRecordNotifyChange } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import createJira from '@salesforce/apex/CreateJiraController.createJira';
import getJiraAccessContext from '@salesforce/apex/CreateJiraController.getJiraAccessContext';
import JIRA_FIELD from '@salesforce/schema/Case.Jira__c';

export default class CreateJiraButton extends LightningElement {
    _recordId;
    @track isLoading = false;
    @track jiraExists = false;
    @track isConfirmDisabled = false;
    @track canCreate = true;
    @track accessMessage = '';

    @api
    get recordId() {
        return this._recordId;
    }

    set recordId(value) {
        if (this._recordId === value) {
            return;
        }
        this._recordId = value;
        this.loadAccessContext();
    }

    @wire(getRecord, { recordId: '$recordId', fields: [JIRA_FIELD] })
    wiredCase({ error, data }) {
        if (data) {
            this.jiraExists = !!data.fields.Jira__c.value;
        } else if (error) {
            this.jiraExists = false;
        }
    }

    async loadAccessContext() {
        if (!this.recordId) {
            return;
        }

        try {
            const accessContext = await getJiraAccessContext({ caseId: this.recordId });
            this.canCreate = accessContext?.canCreate === true;
            this.accessMessage = this.canCreate
                ? ''
                : (accessContext?.deniedCreateMessage || '');

            if (!this.canCreate) {
                this.isConfirmDisabled = true;
            }
        } catch (error) {
            this.canCreate = false;
            this.accessMessage = 'Create Jira is not accessible for your profile/recordtype.';
            this.isConfirmDisabled = true;
        }
    }

    get showAccessDenied() {
        return !this.canCreate && !!this.accessMessage;
    }

    async confirmCreation() {
        if (!this.canCreate) {
            this.showToast('Access Restricted', this.accessMessage || 'Create Jira is not valid for your profile/recordtype.', 'warning');
            return;
        }

        this.isLoading = true;
        this.isConfirmDisabled = true;
    
        try {
            const result = await createJira({ caseId: this.recordId });
            
            if (result.startsWith('Success:')) {
                const parts = result.replace('Success: ', '').split('|');
                const jiraNum = parts[0];
                const jiraUrl = parts[1];
                
                this.showSuccessToast(
                    'Success! The Jira ticket has been generated. Click here to view:',
                    jiraNum,
                    jiraUrl
                );
                
                // Refresh just the case record
                getRecordNotifyChange([{recordId: this.recordId}]);
                
                this.closeQuickAction();
            } else {
                this.showToast('Error', result.replace('Error: ', ''), 'error');
                this.isConfirmDisabled = false;
            }
        } catch (error) {
            this.showToast('Error', error.body?.message || error.message, 'error');
            this.isConfirmDisabled = false;
        } finally {
            this.isLoading = false;
        }
    }

    handleCancel() {
        this.closeQuickAction();
    }

    closeQuickAction() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    showSuccessToast(message, jiraKey, jiraUrl) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Success',
                message: `${message} {0}`,
                messageData: [{
                    url: jiraUrl,
                    label: jiraKey
                }],
                variant: 'success',
                mode: 'dismissable'
            })
        );
    }

    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title,
                message,
                variant
            })
        );
    }
}