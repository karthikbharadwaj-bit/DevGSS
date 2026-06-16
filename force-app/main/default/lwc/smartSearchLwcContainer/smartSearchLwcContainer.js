import { LightningElement, api, track, wire } from 'lwc';
import getCampaign from '@salesforce/apex/SmartSearchForLwc.getCampaign';
import search from '@salesforce/apex/SmartSearchForLwc.search';
import mergeToContact from '@salesforce/apex/SmartSearchForLwc.mergeToContact';
import mergeToLead from '@salesforce/apex/SmartSearchForLwc.mergeToLead';
import claimUnprotectedLeadOwnership from '@salesforce/apex/SmartSearchForLwc.claimUnprotectedLeadOwnership';
import createNew from '@salesforce/apex/SmartSearchForLwc.createNew';
import { subscribe, unsubscribe, APPLICATION_SCOPE, MessageContext } from 'lightning/messageService';
import smartSearchMessage from '@salesforce/messageChannel/SmartSearchMessage__c';
import WebsiteWarningMessage from '@salesforce/label/c.Website_Warning_Message';

const hostname = window.location.hostname;

export default class SmartSearchLwcContainer extends LightningElement {
    @track showSpinner = false;
    @api paramsFromVFPage;
    params = {};
    getCampaignInvoked = false;
    newLead = {};
    chatParams;
    leadQualificationObj;
    campaign;
    searched = false;
    valuesSearched = {
        searchedEmail : '',
        searchedPhone : '',
        searchedCompany : '',
        searchedFirstName : '',
        searchedLastName : '',
        searchedLeadSource : '',
    };
    strSalesGenerated;
    @track showMsg = false;
    @wire(MessageContext)
    messageContext;
    subscription = null;

    getLeadInfo() {
        let smartSearchCustomInfo = this.template.querySelector('c-smart-search-custom-info');
        let smartSearchCustomerProfileCmp = this.template.querySelector('c-smart-search-customer-profile');
        this.newLead.FirstName = smartSearchCustomInfo.firstName;
        this.newLead.LastName = smartSearchCustomInfo.lastName;
        this.newLead.Title = smartSearchCustomInfo.title;
        this.newLead.Company = smartSearchCustomInfo.companyName;
        this.newLead.Email = smartSearchCustomInfo.email;
        this.newLead.Phone = smartSearchCustomInfo.contactPhoneNumber;
        this.newLead.LeadSource = smartSearchCustomInfo.leadSource;
        this.newLead.Agent_Email_Address__c = smartSearchCustomInfo.supportAgentEmailAddress;
        this.newLead.Five9_DNIS__c = smartSearchCustomInfo.DNIS;
        this.newLead.inContact_Contact_ID__c = smartSearchCustomInfo.cid;
        this.newLead.inContact_Skill__c = smartSearchCustomInfo.skill;
        this.strSalesGenerated = smartSearchCustomInfo.salesGeneratedSource;
        this.newLead.Employees_Override__c = smartSearchCustomerProfileCmp.noOfEmployeesRange;
        this.newLead.NumberOfEmployees = smartSearchCustomerProfileCmp.noOfEmployees;
        this.newLead.No_of_Employees_needing_phones__c = smartSearchCustomerProfileCmp.noOfEmployeesNeedingPhones;
        this.newLead.Number_of_Locations__c = smartSearchCustomerProfileCmp.noOfLocations;
        this.newLead.Industry = smartSearchCustomerProfileCmp.industry;
        this.newLead.Website = smartSearchCustomerProfileCmp.website;
        this.newLead.Partner_Request_Source__c = smartSearchCustomerProfileCmp.partnerRequestSource;
    }

    getLeadQualificationInfo() {
        this.leadQualificationObj = this.template.querySelector('c-smart-search-lead-qualification').getLeadQualificationObj();
        console.log(JSON.stringify(this.leadQualificationObj));
    }


    renderedCallback() {
        if(this.getCampaignInvoked === false) {
            Object.keys(this.paramsFromVFPage).forEach(key => {
                let keyToLower = key.toLowerCase();
                this.params[keyToLower] = this.paramsFromVFPage[key];
            });
                this.populateCustomInfoSection();
        }
        this.getCampaignInvoked = true;
    }


    populateEcommerceSection() {
        if (this.params.source === 'invoca' && this.params.invocaid && this.params.invocaid !== '') {
            this.template.querySelector('c-smart-search-ecommerce-info').newLead = this.newLead;
            let userId;
            if (this.newLead && this.newLead.User_ID__c !== '') {
                userId = this.newLead.User_ID__c;
            } else if (this.params.userid && this.params.userid !== '') {
                userId = this.params.userid;
            }
            this.template.querySelector('c-smart-search-ecommerce-info').populateEcommerceValues(userId);
            this.template.querySelector('c-smart-search-ecommerce-info').showEcommerceSection();
        }
    }

    async populateCustomInfoSection() {
        let messageCmp = this.template.querySelector('c-smart-search-messages-panel');
        let smartSearchCustomInfoCmp = this.template.querySelector('c-smart-search-custom-info');
        let rcAccount = this.template.querySelector('c-smart-search-ecommerce-info').rcAccount;
        let classObject = {
            params: this.params,
            newLead : this.newLead,
            rcAccount : rcAccount,
            url : window.location.href,
        };    
        let searchNeeded = false;
        let fnameNotEmpty = false;
        messageCmp.setShowMsg(false);
        getCampaign({jsonParams : JSON.stringify(classObject)})
            .then(result => {
                let key;
                for (key in result) {
                    switch (key) {
                        case "Campaign" :
                            this.campaign = result[key];
                            smartSearchCustomInfoCmp.setCampaignName(result[key].Name);
                            smartSearchCustomInfoCmp.setCampaignProduct(result[key].Intended_Product__c);
                            smartSearchCustomInfoCmp.setCampaignDescription(result[key].Description);
                            break;
                        case "Lead" :
                            this.newLead = result[key];
                            if (this.newLead.LeadSource && this.newLead.LeadSource !== '') {
                                smartSearchCustomInfoCmp.setLeadSource(this.newLead.LeadSource);
                            }
                            if ((this.params.source && this.params.source.toLowerCase() !== 'drift' || (typeof this.params.source === 'undefined'))
                            && (this.newLead.Phone && this.newLead.Phone !== '') ) {
                                smartSearchCustomInfoCmp.setPhoneNumber(this.newLead.Phone);
                                if (result.Account && typeof result.Account !== 'undefined'){
                                    this.template.querySelector('c-smart-search-ecommerce-info').rcAccount = result.Account;
                                }                                    
                                searchNeeded = true;
                            } else if (this.params.source && this.params.source.toLowerCase() === 'drift') {
                                if (typeof this.newLead.Phone !== 'undefined' && this.newLead.Phone !== ''){
                                    smartSearchCustomInfoCmp.setPhoneNumber(this.newLead.Phone);
                                    searchNeeded = true;
                                }
                                if (typeof this.newLead.FirstName !== 'undefined' && this.newLead.FirstName !== ''){
                                    smartSearchCustomInfoCmp.setFirstName(this.newLead.FirstName);
                                    fnameNotEmpty = true;
                                }
                                if (typeof this.newLead.LastName !== 'undefined' && this.newLead.LastName !== ''){
                                    smartSearchCustomInfoCmp.setLastName(this.newLead.LastName);
                                    searchNeeded = searchNeeded || fnameNotEmpty;
                                }
                                if (typeof this.newLead.Email !== 'undefined' && this.newLead.Email !== ''){
                                    smartSearchCustomInfoCmp.setEmail(this.newLead.Email);
                                    searchNeeded = true;
                                }
                                smartSearchCustomInfoCmp.setLeadSource(this.newLead.LeadSource);
                            }
                            if (searchNeeded) {
                                this.handleSearch();
                            }
                            break;
                        case "Account" : 
                            this.template.querySelector('c-smart-search-ecommerce-info').rcAccount = result[key];
                            break;
                    }
                } 
                if (!this.campaign) {
                    smartSearchCustomInfoCmp.setCampaignName('Campaign not found.');
                }
                this.populateEcommerceSection();
            })
            .catch(error => {
                let msg = error.body.message;
                if (msg.includes('ERROR')) {
                    messageCmp.setMessage({
                        toastMsg : msg.substring(6, msg.length),
                        toastType :'Error:',
                        toastcss : 'slds-notify slds-notify_toast slds-theme_error'
                    });
                } else {
                    if (msg.includes('INFO')) {
                        messageCmp.setMessage({
                            toastMsg : msg.substring(6, msg.length),
                            toastType :'Message:',
                            toastcss : 'slds-notify slds-notify_toast slds-theme_info'
                        });
                    } else {
                        messageCmp.setMessage({
                            toastMsg : msg,
                            toastType :'Error:',
                            toastcss : 'slds-notify slds-notify_toast slds-theme_error'
                        });
                    } 
                }
                messageCmp.setShowMsg(true);
                this.showSpinner = false;
            });
        if (this.params.dnis !== '') {
            smartSearchCustomInfoCmp.setdnis(this.params.dnis);
        }
        if (this.params.cid !== '') {
            smartSearchCustomInfoCmp.setcid(this.params.cid);
        }
        if (this.params.skill !== '') {
            smartSearchCustomInfoCmp.setskill(this.params.skill);
        }
        if (this.params.range !== '') {
            this.template.querySelector('c-smart-search-customer-profile').setSelectedRange(this.params.range);
        }

    }

    handleSearch() {
        let messageCmp = this.template.querySelector('c-smart-search-messages-panel');
        let smartSearchListPanelCmp = this.template.querySelector('c-smart-search-list-panel');
        let rcAccount = this.template.querySelector('c-smart-search-ecommerce-info').rcAccount;
        this.getLeadInfo();
        let classObject = {
            params: this.params,
            newLead : this.newLead,
            rcAccount : rcAccount,
        };
        messageCmp.setShowMsg(false);
        smartSearchListPanelCmp.unprotectedLeadsData = [];
        smartSearchListPanelCmp.protectedLeadData = [];
        smartSearchListPanelCmp.unprotectedOppsData = [];
        smartSearchListPanelCmp.protectedOppsActivePipeData = [];
        smartSearchListPanelCmp.protectedOppsCurrentOwnersData = [];                    
        smartSearchListPanelCmp.matchedContactData = [];
        console.log(JSON.stringify(classObject));
        this.showSpinner = true;
        search({jsonParams : JSON.stringify(classObject)})
            .then(result => {
                let key;
                let newValuesSearched = {
                    searchedEmail : this.newLead.Email,
                    searchedPhone : this.newLead.Phone,
                    searchedCompany : this.newLead.Company,
                    searchedFirstName : this.newLead.FirstName,
                    searchedLastName : this.newLead.LastName,
                    searchedLeadSource : this.newLead.LeadSource,
                };
                this.showSpinner = false;
                this.searched = true;
                this.valuesSearched = newValuesSearched;
                for (key in result) {
                    smartSearchListPanelCmp[key] = result[key];
                } 
                if (!this.websiteWarningShownAlready && (!this.newLead.Website || this.newLead.Website.trim() === '')) {
                    this.scrollToTop();
                    messageCmp.setMessage({
                        toastMsg: WebsiteWarningMessage,
                        toastType: 'Message:',
                        toastcss: 'slds-notify slds-notify_toast slds-theme_info'
                    });
                    messageCmp.setShowMsg(true);
                    this.websiteWarningShownAlready = true;
                } else {
                    this.template.querySelector('c-smart-search-results').handleSearchResults(result);
                }  
            })
            .catch(error => {
                this.scrollToTop();
                let msg = error.body.message;
                if (msg.includes('ERROR')) {
                    messageCmp.setMessage({
                        toastMsg : msg.substring(6, msg.length),
                        toastType :'Error:',
                        toastcss : 'slds-notify slds-notify_toast slds-theme_error'
                    });
                    this.template.querySelector('c-smart-search-results').clearSearchValuesOnError();
                } else {
                    if (msg.includes('INFO')) {
                        messageCmp.setMessage({
                            toastMsg : msg.substring(6, msg.length),
                            toastType :'Message:',
                            toastcss : 'slds-notify slds-notify_toast slds-theme_info'
                        });
                    } else {
                        messageCmp.setMessage({
                            toastMsg : msg,
                            toastType :'Error:',
                            toastcss : 'slds-notify slds-notify_toast slds-theme_error'
                        });
                    } 
                }
                messageCmp.setShowMsg(true);
                this.showSpinner = false;
            });
    }

    handleMergeToContact(event) {
        let messageCmp = this.template.querySelector('c-smart-search-messages-panel');
        let rcAccount = this.template.querySelector('c-smart-search-ecommerce-info').rcAccount;
        this.getLeadInfo();
        let classObject = {
            params: this.params,
            newLead : this.newLead,
            rcAccount : rcAccount,
        };
        messageCmp.setShowMsg(false);
        this.showSpinner = true;
        mergeToContact({contactId: event.detail, jsonParams : JSON.stringify(classObject)})
        .then(result => {
            console.log(result);
            console.log(event);
            let url = `https://${hostname}/` + event.detail ;
            window.open(url, "_self");
        })
        .catch(error => {
            this.scrollToTop();
            let msg = error.body.message;
            if (msg.includes('ERROR')) {
                messageCmp.setMessage({
                    toastMsg : msg.substring(6, msg.length),
                    toastType :'Error:',
                    toastcss : 'slds-notify slds-notify_toast slds-theme_error'
                });
            } else {
                if (msg.includes('INFO')) {
                    messageCmp.setMessage({
                        toastMsg : msg.substring(6, msg.length),
                        toastType :'Message:',
                        toastcss : 'slds-notify slds-notify_toast slds-theme_info'
                    });
                } else {
                    messageCmp.setMessage({
                        toastMsg : msg,
                        toastType :'Error:',
                        toastcss : 'slds-notify slds-notify_toast slds-theme_error'
                    });
                } 
            }
            messageCmp.setShowMsg(true);
            this.showSpinner = false;
            console.log(JSON.stringify(error));
        });
    }

    handleTakeOwnership(event) {
        let messageCmp = this.template.querySelector('c-smart-search-messages-panel');
        let rcAccount = this.template.querySelector('c-smart-search-ecommerce-info').rcAccount;
        this.getLeadInfo();
        let classObject = {
            params: this.params,
            newLead : this.newLead,
            rcAccount : rcAccount,
        };
        console.log(JSON.stringify(event));
        messageCmp.setShowMsg(false);
        this.showSpinner = true;
        claimUnprotectedLeadOwnership({leadId: event.detail, jsonParams : JSON.stringify(classObject)})
        .then(result => {
            console.log(result);
            console.log(event);
            let url = `https://${hostname}/` + event.detail ;
            window.open(url, "_self");
        })
        .catch(error => {
            this.scrollToTop();
            let msg = error.body.message;
            if (msg.includes('ERROR')) {
                messageCmp.setMessage({
                    toastMsg : msg.substring(6, msg.length),
                    toastType :'Error:',
                    toastcss : 'slds-notify slds-notify_toast slds-theme_error'
                });
            } else {
                if (msg.includes('INFO')) {
                    messageCmp.setMessage({
                        toastMsg : msg.substring(6, msg.length),
                        toastType :'Message:',
                        toastcss : 'slds-notify slds-notify_toast slds-theme_info'
                    });
                } else {
                    messageCmp.setMessage({
                        toastMsg : msg,
                        toastType :'Error:',
                        toastcss : 'slds-notify slds-notify_toast slds-theme_error'
                    });
                } 
            }
            messageCmp.setShowMsg(true);
            this.showSpinner = false;
        });
    }

    handleCreateNewLead() {
        let messageCmp = this.template.querySelector('c-smart-search-messages-panel');
        let rcAccount = this.template.querySelector('c-smart-search-ecommerce-info').rcAccount;
        this.getLeadInfo();
        this.getLeadQualificationInfo();
        messageCmp.setShowMsg(false);
        let jsonParams = {
            params : this.params,
            newLead : this.newLead,
            salesGeneratedStr : this.strSalesGenerated,
            leadQualificationObj : this.leadQualificationObj, 
            rcAccount : rcAccount,
            searched : this.searched,
            searchedem : this.valuesSearched.searchedEmail,
            searchedph : this.valuesSearched.searchedPhone,
            searchedcomp : this.valuesSearched.searchedCompany,
            searchedfirst : this.valuesSearched.searchedFirstName,
            searchedlast : this.valuesSearched.searchedLastName,
            searchedLeadSource : this.valuesSearched.searchedLeadSource,
        };
        this.showSpinner = true;
        createNew({jsonParams : JSON.stringify(jsonParams)})
        .then(result => {
            this.showSpinner = false;
            let url = `https://${hostname}/` + result;
            this.template.querySelector('[data-id="submitButton"]').click();
            window.location.href = url;
        })
        .catch(error =>{
            this.scrollToTop();
            let msg = error.body.message;
            if (msg.includes('ERROR')) {
                messageCmp.setMessage({
                    toastMsg : msg.substring(6, msg.length),
                    toastType :'Error:',
                    toastcss : 'slds-notify slds-notify_toast slds-theme_error'
                });
                if (msg.includes('Please fill all')) {
                    this.template.querySelector('c-smart-search-custom-info').handleErrorBoxes();
                    this.template.querySelector('c-smart-search-customer-profile').handleErrorBoxes();

                }
            } else {
                if (msg.includes('INFO')) {
                    messageCmp.setMessage({
                        toastMsg : msg.substring(6, msg.length),
                        toastType :'Message:',
                        toastcss : 'slds-notify slds-notify_toast slds-theme_info'
                    });
                } else {
                    messageCmp.setMessage({
                        toastMsg : msg,
                        toastType :'Error:',
                        toastcss : 'slds-notify slds-notify_toast slds-theme_error'
                    });
                } 
            }
            messageCmp.setShowMsg(true);
            this.showSpinner = false;
        })
    }

    
    handleMergeToLead(event) {
        let messageCmp = this.template.querySelector("c-smart-search-messages-panel");
        this.getLeadInfo();
        console.log(JSON.stringify(event));
        let classObject = {
            params: this.params,
            newLead: this.newLead,
        };
        messageCmp.setShowMsg(false);
        this.showSpinner = true;
        mergeToLead({
            leadToUpdateId: event.detail.leadId,
            jsonParams: JSON.stringify(classObject),
            takeOwnership: event.detail.takeOwnership,
        })
            .then((result) => {
                console.log(result);
                let url = `https://${hostname}/` + event.detail.leadId;
                window.open(url, "_self");
            })
            .catch((error) => {
                this.scrollToTop();
                let msg = error.body.message;
                if (msg.includes("ERROR")) {
                    messageCmp.setMessage({
                        toastMsg: msg.substring(6, msg.length),
                        toastType: "Error:",
                        toastcss: "slds-notify slds-notify_toast slds-theme_error",
                    });
                } else {
                    if (msg.includes("INFO")) {
                        messageCmp.setMessage({
                            toastMsg: msg.substring(6, msg.length),
                            toastType: "Message:",
                            toastcss: "slds-notify slds-notify_toast slds-theme_info",
                        });
                    } else {
                        messageCmp.setMessage({
                            toastMsg: msg,
                            toastType: "Error:",
                            toastcss: "slds-notify slds-notify_toast slds-theme_error",
                        });
                    }
                }
                messageCmp.setShowMsg(true);
                this.showSpinner = false;
            });
    }

    handleCancel() {
        let url = `https://${hostname}/` + '/lightning/o/Lead/home' ;
        window.open(url, "_self");
    }

    subscribeToMessageChannel() {
        if (!this.subscription) {
            this.subscription = subscribe(
                this.messageContext,
                smartSearchMessage,
                (message) => this.handleMessage(message),
                { scope: APPLICATION_SCOPE }
            );
        }
    }

    handleMessage(message) {
        this.template.querySelector('c-smart-search-customer-profile').handleScrollToDiv(message);
        this.template.querySelector('c-smart-search-custom-info').handleScrollToDiv(message);
        this.template.querySelector('c-smart-search-list-panel').handleScrollToDiv(message);
    }

    connectedCallback() {
        this.subscribeToMessageChannel();
    }

    disconnectedCallback() {
        this.unsubscribeToMessageChannel();
    }

    unsubscribeToMessageChannel() {
        unsubscribe(this.subscription);
        this.subscription = null;
    }

    scrollToTop() {
        const toButton = this.template.querySelector('[data-id="submitButton"]');
        toButton?.scrollIntoView({behavior: "smooth", block: "start", inline: "nearest"});
    }
}