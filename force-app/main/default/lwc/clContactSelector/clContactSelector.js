import { LightningElement, track, api } from 'lwc';
import { clAppReady, getContacts, handleError, showToast } from "c/clService";
import defaultTitle from '@salesforce/label/c.ClContactSelectorDefaultTitle';
import onlyOneContactTitle from '@salesforce/label/c.ClContactSelectorOneContact';
import accountPrimaryContactTitle from '@salesforce/label/c.ClContactSelectorContactRole';
import Contactsection from '@salesforce/label/c.ClContactSelectorContactsection';
import Selectedcontact from '@salesforce/label/c.ClContactSelectorSelectedcontact';
import None from '@salesforce/label/c.ClContactSelectorNone';
import Choosearowtoselect from '@salesforce/label/c.ClContactSelectorChoosearowtoselect';
import ContactName from '@salesforce/label/c.ClContactSelectorContactName';
import Company from '@salesforce/label/c.ClContactSelectorCompany';
import Title from '@salesforce/label/c.ClContactSelectorTitle';
import Email from '@salesforce/label/c.ClContactSelectorEmail';
import Phone from '@salesforce/label/c.ClContactSelectorPhone';
import AccountStatus from '@salesforce/label/c.ClContactSelectorAccountStatus';
import LastModifiedDate from '@salesforce/label/c.ClContactSelectorLastModifiedDate';
import Loadmore from '@salesforce/label/c.ClContactSelectorLoadmore';
import NoContactsmatchthechosenAccount from '@salesforce/label/c.ClContactSelectorNoContactsmatchthechosenAccount';
import AnewContactwillbecreated from '@salesforce/label/c.ClContactSelectorAnewContactwillbecreated';
import NoContactwasSelected from '@salesforce/label/c.ClContactSelectorNoContactwasSelected';
import PleaseselectanContactfromthelist from '@salesforce/label/c.ClContactSelectorPleaseselectanContactfromthelist';

export default class ClContactSelector extends LightningElement {
    @api accountHasBeenSelected = false;
    @track matchedContacts = [];
    @track selectedContact;
    @track isExpanded = true;
    @track showApplyEditButton = true;
    @track isExpandedView = true;
    @track isCollapsedView = true;
    @track showIsContactMissingError = false;
    @track hasMoreContacts = false;
    @track hasMoreContactsDisabled = false;
    @track isLoading = true;
    @track isLoaded = false;
    @track tableTitle = defaultTitle;
    @track opportunityHasApplied = false;
    @track contactHasApplied = false;
    @track label = {
        Contactsection,
        Selectedcontact,
        None,
        Choosearowtoselect,
        ContactName,
        Company,
        Title,
        Email,
        Phone,
        AccountStatus,
        LastModifiedDate,
        Loadmore,
        NoContactsmatchthechosenAccount,
        AnewContactwillbecreated,
        NoContactwasSelected,
        PleaseselectanContactfromthelist
    };


    get isHasMatchedContacts() {
        return this.matchedContacts.length > 0;
    }

    onMatchedContactSelected(event) {
        CL.app.selectMatchedContact(event.target.value);
        this.selectedContact = CL.app.selectedMatchedContact;
        this.selectedMatchedContact = CL.app.selectedMatchedContact;
    }

    get isCreateNewContact() {
        return false;
    }


    connectedCallback() {
        window.addEventListener('onSelectExistingAccountForContact', this.loadContactComponent.bind(this));
        window.addEventListener('onEditIsOkay', this.hideContactComponent.bind(this));
        window.addEventListener('onCancel', this.showContactComponent.bind(this));
        window.addEventListener('onCreateNewAcc', this.removeSelectedContact.bind(this));
    }

    removeSelectedContact() {
        this.selectedContact = null;
        CL.app.selectedContact = null;
        CL.app.setMatchedContacts([], false);
    }

    showContactComponent() {
        this.accountHasBeenSelected = true;
    }

    hideContactComponent() {
        this.accountHasBeenSelected = false;
    }

    loadContactComponent(){
        this.accountHasBeenSelected = true;
        this.refreshComponent();
        this.onClAppReady();
        this.loadContacts();
    }

    toggleApply(){
        this.isExpanded && !this.selectedContact ? showToast({title: this.label.NoContactwasSelected,
                                                            message: this.label.PleaseselectanContactfromthelist,
                                                            type: 'error',
                                                            duration: 5000})
                                                 : this.toggleViewOfEditAndContactRole();
        this.toggleContactHasApplied(!this.isExpanded);
    }


    toggleContactHasApplied(hasApplied){
        CL.app.contactHasApplied = hasApplied;
        CL.app.contactHasApplied && CL.app.opportunityHasApplied && CL.app.opportunityCreationOption != 'doNotCreateOpp' ? window.dispatchEvent(new CustomEvent('onContactOpportunityApplied')) : window.dispatchEvent(new CustomEvent('onContactOpportunityEdited'));
    }


    toggleViewOfEditAndContactRole() {
        this.isExpanded = !this.isExpanded;
    }

    get disableCheckboxes() {
        return !this.isExpanded;
    }

    onClAppReady() {
        CL.app.rx.matchedContacts.subscribe(matchedContacts => {
            this.matchedContacts = matchedContacts;
            this.hasMoreContacts = CL.app.hasMoreContacts;
        });

        CL.app.rx.selectedContact.subscribe(selectedContact => {
            this.selectedContact = selectedContact;

            // Rerender list to display selected
            this.matchedContacts = [...this.matchedContacts];

        });

        CL.app.rx.errorsToShow.subscribe(errorsToShow => {
            this.showIsContactMissingError = errorsToShow.isContactMissing;
        });
    }

    loadContacts() {
        this.hasMoreContactsDisabled = true;
        CL.app.contactHasApplied = false;
        this.selectedContact = null;
        CL.app.selectedContact = null;
        this.tableTitle = defaultTitle;
        console.log('Lead Id: ' + CL.app.leadId + ' Acc id: ' + CL.app.rx.selectedAccount._value.id);
        getContacts(CL.app.leadId, CL.app.rx.selectedAccount._value.id, 0)
            .then(r => {
                console.log(r.data.contacts);
                CL.app.setHasMoreContacts(r.data.hasMoreContacts);
                CL.app.setMatchedContacts(r.data.contacts, false);
                this.matchedContacts = CL.app.matchedContacts;
                this.matchedContacts.length == 0 ? this.showApplyEditButton = false : this.showApplyEditButton = true;
                if (this.matchedContacts.length == 1) {
                    CL.app.selectMatchedContact(r.data.contacts[0].Id);
                    this.selectedMatchedContact = CL.app.selectedMatchedContact;
                    this.showApplyEditButton = false;
                    this.tableTitle = onlyOneContactTitle;
                    this.toggleApply();
                } else if (this.matchedContacts.length == 0) {
                    CL.app.contactHasApplied = true;
                    window.dispatchEvent(new CustomEvent('onContactOpportunityApplied'));
                }
                this.hasMoreContactsDisabled = false;
                this.isLoading = false;
            })
            .catch(handleError)
        this.isExpanded = true;
    }

    loadMoreContacts() {
        this.hasMoreContactsDisabled = true;
        getContacts(CL.app.leadId, CL.app.rx.selectedAccount._value.id, this.matchedContacts.length)
            .then(r => {
                CL.app.setHasMoreContacts(r.data.hasMoreContacts);
                CL.app.setMatchedContacts(r.data.contacts, true);
                this.matchedContacts = CL.app.matchedContacts;
                this.hasMoreContactsDisabled = false;
            })
            .catch(handleError)
    }

    refreshComponent () {
        CL.app.setMatchedContacts([], false);
        this.matchedContacts = CL.app.matchedContacts;
        CL.app.selectMatchedContact(null);
        this.selectedMatchedContact = CL.app.selectedMatchedContact;
    }
}