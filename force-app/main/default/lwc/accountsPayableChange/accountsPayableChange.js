import { LightningElement, wire, track } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import { CurrentPageReference, NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import getApprovalInfo from '@salesforce/apex/AccountsPayableChangeController.getApprovalInfo';
import unlockRecord from '@salesforce/apex/AccountsPayableChangeController.unlockRecord';
import updateApproval from '@salesforce/apex/AccountsPayableChangeController.updateApproval';
import submitRecord from '@salesforce/apex/AccountsPayableChangeController.submitRecord';

export default class AccountsPayableChange extends NavigationMixin(LightningElement) {
  @wire(CurrentPageReference)
  getStateParameters(currentPageReference) {
    if (currentPageReference?.state?.recordId) {
      this.recordId = currentPageReference.state.recordId;
    }
  }

  @track
  isSpinnerShown;
  @track
  spinnerText;

  recordId;
  approvalInfo;
  selectedAccountPayableId;
  selectedPartnerPayableId;

  connectedCallback() {
    this.init();
  }

  init() {
    this.spinnerText = 'Loading Approval Info';
    this.showSpinner();
    getApprovalInfo({ recordId: this.recordId })
    .then(this.handleResponse)
    .then(data => {
      this.approvalInfo = data.approvalInfo;
      this.hideSpinner();
    })
    .catch(res => {
      this.handleErrors(res);
      this.closeModal();
    });
  }

  onSelectedAccountPayableChange(event) {
    this.selectedAccountPayableId = event?.detail?.valueObj?.id || null;
  }

  onSelectedPartnerPayableChange(event) {
    this.selectedPartnerPayableId = event?.detail?.valueObj?.id || null;
  }

  onSave() {
    const updateParams = {
      recordId: this.recordId,
    };

    if (this.selectedAccountPayableId) {
      updateParams.selectedAccountPayableId = this.selectedAccountPayableId;
    }
    if (this.selectedPartnerPayableId) {
      updateParams.selectedPartnerPayableId = this.selectedPartnerPayableId;
    }

    const submitParams = {
      recordId: this.recordId,
      ownerId: this.approvalInfo?.ownerId,
    };

    const spinnerPromise = new Promise((resolve, reject) => {
      setTimeout(() => {
        this.spinnerText = 'Saving new Accounts Payable Contact on Approval';
        this.showSpinner();
        resolve();
      }, 200);
    });

    spinnerPromise
      .then(() => unlockRecord({ recordId: this.recordId }))
      .then(this.handleResponse)
      .then(() => updateApproval({ params: JSON.stringify(updateParams) }))
      .then(this.handleResponse)
      .then(() => submitRecord({ params: JSON.stringify(submitParams) }))
      .then(this.handleResponse)
      .then(() => {
        if (!this.approvalInfo?.accountId) {
          this.closeModal();
          return;
        }
        this.dispatchEvent(
          new ShowToastEvent({
            title: 'Success',
            message: 'Approval is updated and submitted. Navigating to Account.',
            variant: 'success',
            mode: 'dismissable',
          })
        );
        this[NavigationMixin.Navigate]({
          type: 'standard__recordPage',
          attributes: {
            objectApiName: 'Account',
            recordId: this.approvalInfo?.accountId,
            actionName: 'view',
          },
        });
      })
      .catch(error => {
        this.handleErrors(error);
      })
      .finally(() => this.hideSpinner());
  }

  onClose() {
    this.closeModal();
  }

  handleResponse(res) {
    console.log('handleResponse: ', res);
    if (res.status !== 'success') {
      throw res;
    }
    return res.data;
  }

  handleErrors(res) {
    console.error('handleErrors: ', res);
    if (res?.body && res.body.exceptionType && res.body.message) {

      const maxMessageLength = 300;

      const title = `Unexpected exception occurred (${res.body.exceptionType})`;

      const message = res.body.message.length > maxMessageLength
        ? res.body.message.substring(0, maxMessageLength).concat('...')
        : res.body.message;

      this.dispatchEvent(new ShowToastEvent({
        title,
        message,
        variant: 'error',
        mode: 'dismissable'
      }));

    } else if (res?.messages) {
      res.messages.forEach(m => {
        this.dispatchEvent(new ShowToastEvent({
          title: m.message,
          message: m.messageDetails,
          variant: m.severity || m.status,
          mode: 'dismissable'
        }));
      });
    }
  }

  closeModal() {
    this.dispatchEvent(new CloseActionScreenEvent());
  }

  showSpinner() {
    this.isSpinnerShown = true;
  }

  hideSpinner() {
    this.isSpinnerShown = false;
  }

  get accountPayableParams() {
    return {
      isPayableOnly: true,
      applyContactRoleFilter: true,
      accountId: this.approvalInfo?.accountId,
      existingContact: this.approvalInfo?.existingAccountPayableId,
    };
  }

  get partnerPayableParams() {
    return {
      isPayableOnly: true,
      applyContactRoleFilter: true,
      accountId: this.approvalInfo?.partnerAccountId,
      existingContact: this.approvalInfo?.existingPartnerPayableId,
    };
  }

  get updateApprovalParams() {
    return {
      recordId: this.recordId,
      newAccountPayableId: this.selectedAccountPayableId,
      selectedPartnerPayableId: this.selectedPartnerPayableId,
    };
  }

  get isPartnerPayableShown() {
    return Boolean(this.approvalInfo?.partnerAccountId);
  }

  get isSaveDisabled() {
    return !this.selectedAccountPayableId && !this.selectedPartnerPayableId;
  }

  // temporary solution until reserch of dropdown on separated modal
  get forcedDropdownAttributes() {
    return {
      left: '16px',
    };
  }
}