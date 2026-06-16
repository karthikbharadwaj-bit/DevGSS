import { LightningElement, track, wire } from 'lwc';
import { MessageContext, publish } from 'lightning/messageService';
import SMARTSEARCHMC from '@salesforce/messageChannel/SmartSearchMessage__c';

export default class SmartSearchButtons extends LightningElement {

    showMsg = true;
    data = 'Hello';

    search() {
        const searchEvent = new CustomEvent("search");
        this.dispatchEvent(searchEvent);
    }

    createNewLead() { 
        const createNewLeadEvent = new CustomEvent("createnewlead");
        this.dispatchEvent(createNewLeadEvent);
    }

    cancel() {
        const cancelEvent = new CustomEvent("cancel");
        this.dispatchEvent(cancelEvent);        
    }

    @wire(MessageContext)
    context;

    subscription = null;

    @track receivedMessage = '';

    publishMC() {
        console.log(this.data);
        let message = {

            Data: { value: this.data,

            channel: 'SmartSearchMessage',

            source: 'LWC' }

        };

        publish(this.context, SMARTSEARCHMC, message);

    }

    // subscribeMC() {

    //     if (this.subscription) {

    //         return;

    //     }

    //     this.subscription = subscribe(this.context, SAMPLEMC, (message) => {

    //         this.handleMessage(message);

    //     });

    //  }

    //      unsubscribeMC() {

    //      unsubscribe(this.subscription);

    //      this.subscription = null;

    //  }

    //    handleMessage(message) {

    //      this.receivedMessage = message ? JSON.stringify(message, null, '\t') : 'no message payload';

    //  }

    // disconnectedCallback() {

    //     releaseMessageContext(this.context);

    // }
}