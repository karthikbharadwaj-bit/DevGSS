import { api, wire, LightningElement, track } from 'lwc'; 
import smartSearchMessage from '@salesforce/messageChannel/SmartSearchMessage__c';
import { publish, MessageContext } from 'lightning/messageService';

export default class SmartSearchResults extends LightningElement {

    @wire(MessageContext)
    messageContext;
    @track
    values = {
        protectedLeadNumber: '',
        protectedOppsCurrentOwnersNumber: '',
        protectedOppsActivePipeNumber: '',
        matchedContactNumber: '',
        unprotectedLeadsNumber: '',
        unprotectedOppsNumber: '',
    };
    

    @api
    handleSearchResults(values) {
        if (values) {
            this.values.protectedLeadNumber = values.protectedLeadData.length > 0 ? values.protectedLeadData.length + ' found' : '0 found';
            this.values.protectedOppsCurrentOwnersNumber = values.protectedOppsCurrentOwnersData.length > 0 ? values.protectedOppsCurrentOwnersData.length + ' found' : '0 found';
            this.values.protectedOppsActivePipeNumber = values.protectedOppsActivePipeData.length > 0 ? values.protectedOppsActivePipeData.length + ' found' : '0 found';
            this.values.matchedContactNumber = values.matchedContactData.length > 0 ? values.matchedContactData.length + ' found' : '0 found';
            this.values.unprotectedLeadsNumber = values.unprotectedLeadsData.length > 0 ? values.unprotectedLeadsData.length + ' found' : '0 found';
            this.values.unprotectedOppsNumber = values.unprotectedOppsData.length > 0 ? values.unprotectedOppsData.length + ' found' : '0 found';
        }
        
    }

    @api
    clearSearchValuesOnError() {
        this.values.protectedLeadNumber = '';
        this.values.protectedOppsCurrentOwnersNumber = '';
        this.values.protectedOppsActivePipeNumber = '';
        this.values.matchedContactNumber = '';
        this.values.unprotectedLeadsNumber = '';
        this.values.unprotectedOppsNumber = '';
    }

    handleScrollToList(event) {
        const selectedList = { data: event.target.name};
        console.log(selectedList);
        publish(this.messageContext, smartSearchMessage, selectedList);
    }

}