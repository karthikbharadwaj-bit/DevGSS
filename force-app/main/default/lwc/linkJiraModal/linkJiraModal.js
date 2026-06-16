import { LightningElement, api, track } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecordNotifyChange } from 'lightning/uiRecordApi';
import linkJira from '@salesforce/apex/CreateJiraController.linkJira';
import getJiraAccessContext from '@salesforce/apex/CreateJiraController.getJiraAccessContext';

export default class LinkJiraButton extends LightningElement {
    _recordId;
    @track isLoading = false;
    @track loadingMessage = '';
    @track errorMessage = '';
    @track jiraNumber = '';
    @track isSubmitDisabled = true;
    @track canLink = true;

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

    get isDisabled() {
        return this.isSubmitDisabled || this.isLoading || !this.canLink;
    }

    get isAccessDenied() {
        return !this.canLink;
    }

    async loadAccessContext() {
        if (!this.recordId) {
            return;
        }

        try {
            const accessContext = await getJiraAccessContext({ caseId: this.recordId });
            this.canLink = accessContext?.canLink === true;
            if (!this.canLink) {
                this.errorMessage = accessContext?.deniedLinkMessage || '';
                this.isSubmitDisabled = true;
            } else {
                this.errorMessage = '';
            }
        } catch (error) {
            this.canLink = false;
            this.errorMessage = 'Link Jira is not accessible for your profile/recordtype.';
            this.isSubmitDisabled = true;
        }
    }

    handleJiraNumberChange(event) {
        if (!this.canLink) {
            return;
        }
        this.jiraNumber = event.target.value.trim();
        this.isSubmitDisabled = !this.jiraNumber;
        this.errorMessage = '';
    }

    async handleSubmit() {
        if (!this.canLink) {
            this.errorMessage = this.errorMessage || 'Link Jira is not valid for your profile/recordtype.';
            return;
        }

        if (!this.jiraNumber) {
            this.errorMessage = 'Please enter a valid Jira ticket number';
            return;
        }

        this.isLoading = true;
        this.loadingMessage = 'Please wait. Linking Jira ticket...';
        this.isSubmitDisabled = true;

        try {
            const result = await linkJira({
                caseId: this.recordId, 
                jiraNumber: this.jiraNumber
            });
            
            if (!result.startsWith('Success:')) {
                throw new Error(result.replace('Error: ', ''));
            }

            const parts = result.replace('Success: ', '').split('|');
            const jiraKey = parts[0];
            const jiraUrl = parts[1];
            
            // Refresh just the case record
            getRecordNotifyChange([{recordId: this.recordId}]);
            
            this.showSuccessToast('Jira ticket identified! Successfully linked Jira ticket:', jiraKey, jiraUrl);
            this.closeQuickAction();

        } catch (error) {
            this.errorMessage = error.message;
        } finally {
            this.isLoading = false;
            this.loadingMessage = '';
            this.isSubmitDisabled = !this.jiraNumber;
        }
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

    handleCancel() {
        this.closeQuickAction();
    }

    closeQuickAction() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }
}