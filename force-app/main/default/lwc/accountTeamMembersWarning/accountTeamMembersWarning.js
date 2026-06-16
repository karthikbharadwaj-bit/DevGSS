import { api, LightningElement, track, wire } from 'lwc';
import determineRecentOwnerChange from '@salesforce/apex/accountTeamsCustomController.determineOwnerChange';
import { subscribe, unsubscribe } from 'lightning/empApi';

export default class AccountTeamMembersWarning extends LightningElement {
    @track isDisplayed = false;
    @track isOwnerUpdatedRecently = false;
    @api recordId;
    subscription = {};
    channelName = '/event/Account_Update__e'
    parameters = {};

    connectedCallback() {
        this.handleSubscribe();
        this.checkIfOwnerRecentlyUpdated();
    }

    messageCallback = (response) => {
        console.log('Subscription data account', JSON.stringify(response.data.payload.Account_ID__c));
        if (response.data.payload.Account_ID__c === this.recordId) {
            this.checkIfOwnerRecentlyUpdated();
        }
    };

    handleSubscribe() {
        subscribe(this.channelName, -1, this.messageCallback).then((response) => {
            console.log(
                'Subscription request sent to: ',
                JSON.stringify(response.channel)
            );
            this.subscription = response;
        });
    }

    checkIfOwnerRecentlyUpdated() {
        determineRecentOwnerChange({ recId: this.recordId})
            .then(data => {
                if (data) { 
                    console.log('data result ', data);
                    this.isOwnerUpdatedRecently = true;
                    this.openBanner();
                } else this.closeBanner();
            })
            .catch(error => {
                console.log(error);
                this.closeBanner();
            })
    }

    openBanner() {
        this.isDisplayed = true;
    }

    closeBanner() {
        this.isDisplayed = false;
    }

    unsubscribeToAccEvent() {
        unsubscribe(this.subscription);
        this.subscription = null;
    }

    disconnectedCallback() {
        this.unsubscribeToAccEvent();
    }
}