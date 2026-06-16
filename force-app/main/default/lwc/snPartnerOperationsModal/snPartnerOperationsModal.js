import { LightningElement,  track, api } from 'lwc';

import createCaseAboutProblem from '@salesforce/apex/PartnerOperationsController.createCaseAboutProblem';
import getAccountNameById from '@salesforce/apex/PartnerOperationsController.getAccountNameById';

export default class SnPartnerOperationsModal extends LightningElement {

    @track isModalOpen = false;

    @track isError = false;

    @api
    account;

    subject= 'Wholesale_Partner_Operations';

    accName;

    descriptionText;

    openModal(){
        this.isModalOpen = true;
        this.isError = false;
        getAccountNameById({accId: this.account})
            .then(res => this.handleResponse(res))
            .then(data => {
            this.accName = data.Name;
        });
    }

    closeModal(){
        this.isModalOpen = false;
    }

    errorShown(){
        this.descriptionText = this.template.querySelector('textarea').value;
        if (this.descriptionText !== '') {
            this.isError = false;
            this.template.querySelector('.slds-textarea').style='border-color:gray'
        } else {
            this.isError = true;
            this.template.querySelector('.slds-textarea:invalid').style='border-color:red';
        }
    }

    submitDetails(){
        this.descriptionText = this.template.querySelector('textarea').value;
        if (this.descriptionText !== '') {
            createCaseAboutProblem({accId: this.account, description: this.descriptionText})
            .then(res => this.handleResponse(res))
            .then(this.isModalOpen = false);
        } else {
            this.isError = true;
            this.template.querySelector('.slds-textarea:invalid').style='border-color:red';
        }

    }

    handleResponse(res) {
        console.log('handleResponse: ', res);
        if (res.status !== 'success') {
          throw res;
        }

        if (res.data.redirectUrl) {
          window.open(res.data.redirectUrl, '_blank');
        }
        this.handleMessages(res);
        return res.data;
      }

      showToast({title, message, type = 'info', duration}) {
        window.dispatchEvent(new CustomEvent('ShowToastEvent', {
          detail: {title, message, type, duration}
        }));
      }

      handleMessages(res) {
        console.log('handleMessages: ', res);

        const isUnhandledApexException = res?.body?.exceptionType && res.body.message;

        if (isUnhandledApexException) {

          const maxMessageLength = 300;

          const title = `Unexpected exception occurred (${res.body.exceptionType})`;

          const errorMessage = res.body.message.length > maxMessageLength
            ? res.body.message.substring(0, maxMessageLength).concat('...')
            : res.body.message;

          this.showToast({
            title: title,
            message: errorMessage,
            type: 'error',
            duration: false
          });

        } else if (res && res.messages) {
          res.messages.forEach(m => {
            this.showToast({
              title: m.message,
              message: m.messageDetails,
              type: m.severity || m.status,
              duration: false
            });
          });
        }
      }
}