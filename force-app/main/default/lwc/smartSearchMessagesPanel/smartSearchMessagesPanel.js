import { api, LightningElement, track, wire } from 'lwc';
import smartSearchMessage from '@salesforce/messageChannel/SmartSearchMessage__c';
import { publish, MessageContext } from 'lightning/messageService';

export default class SmartSearchMessagesPanel extends LightningElement {

    @wire(MessageContext)
    messageContext;
    @track showMsg = false;
    @track
    toastInfo = {
        toastMsg : '',
        toastType :'',
        toastcss : 'slds-notify slds-notify_toast slds-theme_error'
    }
    decodedMsg;
    showAtLeastOneMsg = false;
    showAllFieldsMsg = false;
    showPlainText = false;
    @track 
    isError = false;
    @track 
    isInfoMessage = false;
    

    @api 
    setMessage(message) {
        this.toastInfo = message;
        this.showAtLeastOneMsg = this.toastInfo.toastMsg.includes('You must enter at least one');
        this.showAllFieldsMsg = this.toastInfo.toastMsg.includes('Please fill all');
        this.showPlainText = !this.showAtLeastOneMsg && !this.showAllFieldsMsg;
        this.updateIsErrorFlag();
        this.updateIsInfoMessageFlag();
    }

    @api
    setShowMsg(value) {
        this.showMsg = value;
    }

    updateIsErrorFlag() {
        this.isError = this.toastInfo.toastType === 'Error:' && this.toastInfo.toastMsg !== '';
    }

    updateIsInfoMessageFlag() {
        this.isInfoMessage = this.toastInfo.toastType === 'Message:' && this.toastInfo.toastMsg !== '';
    }
    
    handleScroll(event) {
        const selectedList = { data: event.target.name};
        publish(this.messageContext, smartSearchMessage, selectedList);
    }
}