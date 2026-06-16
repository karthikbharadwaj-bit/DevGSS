import { LightningElement, api, track } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecordNotifyChange } from 'lightning/uiRecordApi';
import getJiraAccessContext from '@salesforce/apex/CreateJiraController.getJiraAccessContext';

const WARNING_MESSAGE = 'You can use the Link Jira button to link the Jira. You can still save manual updates if needed.';

export default class JiraProductDefectEditor extends LightningElement {
    _recordId;

    @track isLoadingAccess = true;
    @track isSaving = false;
    @track showWarning = false;
    @track warningMessage = WARNING_MESSAGE;

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

    async loadAccessContext() {
        if (!this.recordId) {
            return;
        }

        this.isLoadingAccess = true;
        this.showWarning = false;

        try {
            const accessContext = await getJiraAccessContext({ caseId: this.recordId });
            this.showWarning = accessContext?.isProfileRecordTypeInScope === true;
        } catch (error) {
            // Do not block manual edit if access context fails.
            // eslint-disable-next-line no-console
            console.warn('Unable to load Jira access context for Product Defect editor:', error);
            this.showWarning = false;
        } finally {
            this.isLoadingAccess = false;
        }
    }

    get isBusy() {
        return this.isLoadingAccess || this.isSaving;
    }

    handleCancel() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    handleSubmit() {
        this.isSaving = true;
    }

    handleSuccess() {
        this.isSaving = false;
        getRecordNotifyChange([{ recordId: this.recordId }]);
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Success',
                message: 'Jira fields updated successfully.',
                variant: 'success'
            })
        );
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    handleError(event) {
        this.isSaving = false;
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Error',
                message: event?.detail?.message || 'Unable to update Jira fields.',
                variant: 'error'
            })
        );
    }
}