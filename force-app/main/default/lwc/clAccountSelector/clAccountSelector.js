/* globals CL */
import {LightningElement, track, api} from 'lwc';
import {clAppReady, getAccounts, handleError, getServiceEntitlement, showToast} from "c/clService";
import AccountIsRequired from '@salesforce/label/c.clAccountSelectorAccountIsRequired';
import AccountName from '@salesforce/label/c.clAccountSelectorAccountName';
import ChooseFromMatchedAccounts from '@salesforce/label/c.clAccountSelectorChooseFromMatchedAccounts';
import CurrentOwner from '@salesforce/label/c.clAccountSelectorCurrentOwner';
import LastModifiedDate from '@salesforce/label/c.clAccountSelectorLastModifiedDate';
import LoadMore from '@salesforce/label/c.clAccountSelectorLoadMore';
import NewAccountWillBeCreated from '@salesforce/label/c.clAccountSelectorNewAccountWillBeCreated';
import NoAccountWasSelected from '@salesforce/label/c.clAccountSelectorNoAccountWasSelected';
import None from '@salesforce/label/c.clAccountSelectorNone';
import PleaseSelectAnAccount from '@salesforce/label/c.clAccountSelectorPleaseSelectAnAccount';
import PleaseSpecifyAnExistingAccountOrCreateANewOne from '@salesforce/label/c.clAccountSelectorPleaseSpecifyAnExistingAccountOrCreateANewOne';
import RcAccountNumber from '@salesforce/label/c.clAccountSelectorRcAccountNumber';
import RcAccountStatus from '@salesforce/label/c.clAccountSelectorRcAccountStatus';
import RcUserId from '@salesforce/label/c.clAccountSelectorRcUserId';
import SelectAnExistingAccount from '@salesforce/label/c.clAccountSelectorSelectAnExistingAccount';
import SelectedAccount from '@salesforce/label/c.clAccountSelectorSelectedAccount';
import Type from '@salesforce/label/c.clAccountSelectorType';
import AccountSection from '@salesforce/label/c.clAccountSelectorAccountSection';

export default class ClAccountSelector extends LightningElement {
    @api isPrmFlow;
    @track _isDataWaveLoaded = false;
    @api isLeadRecordTypeSales = false;
    @track matchedAccounts = [];
    @track isCreateNewAccount = null;
    @api selectedAccount;
    @track selectedLookupAccount;
    @track showExistingAccountSelector = false;
    @track targetAccount;
    @track isExpanded = true;
    @track showIsAccountMissingError = false;
    @track hasMoreAccounts = false;
    @track hasMoreAccountsDisabled = false;
    @track toggleEdit = false;
    @track disableSwitch = false;
    @track disableEla = false;
    @track disableNumberOfELAServiceAccountsInput = true;
    @track previousAccount = null;
    @track isElaAccount = false;
    @track isElaFlowFeatureEnabled = false;
    @track isShowElaCheckbox = false;
    @track numberOfELAServiceAccounts = 1;
    @track numberFlag = false;
    @track leadToConvert = false;
    @track label = {
    AccountSection,
    AccountIsRequired,
    AccountName,
    ChooseFromMatchedAccounts,
    CurrentOwner,
    LastModifiedDate,
    LoadMore,
    NewAccountWillBeCreated,
    NoAccountWasSelected,
    None,
    PleaseSelectAnAccount,
    PleaseSpecifyAnExistingAccountOrCreateANewOne,
    RcAccountNumber,
    RcAccountStatus,
    RcUserId,
    SelectAnExistingAccount,
    SelectedAccount,
    Type
    };

    defaultMinELAAccounts = 1;
    defaultMaxELAAccounts = 100;

    get isAccountHasErrors() {
        return this.showIsAccountMissingError;
    };

    get isHasMatchedAccounts() {
        return this.matchedAccounts.length > 0;
    }

    get isUseExistingAccount() {
        return !this.isCreateNewAccount;
    }

    get isExistingWithNoMatchedAccounts(){
        return this.matchedAccounts.length == 0 && !this.isCreateNewAccount;
    }

    get selectedLookupAccountId() {
        return this.selectedLookupAccount && this.selectedLookupAccount.id;
    }

    get lookupAccountParams() {
         return {filterOutPartnerAccounts: true, leadId: CL.app.leadId, partnerLead: true};
    }

    get isExpandedView() {
        return this.isExpanded && this.showExistingAccountSelector && this.isLoaded;
    }

    get isCollapsedView() {
        return (!this.isExpanded || !this.showExistingAccountSelector) && this.isLoaded;
    }

    get showExistingAccountSelectorForPrmFlow() {
        return (this.showExistingAccountSelector && !this.isPrmFlow);
    }

    get containerClasses() {
        return [
            'slds-card slds-p-around_medium',
            this.isAccountHasErrors && 'card_has-errors'
        ].filter(Boolean).join(' ');
    }

    set isEla(isElaAccount) {
        this.isElaAccount = isElaAccount;
        CL.app.setElaAccount(this.isElaAccount);
    }

    get isShowNumberOfELAServiceAccountsField() {
        return this.isElaAccount && this.isCreateNewAccount;
    }

    @api
    get isDataWaveLoaded() {
        return this._isDataWaveLoaded;
    }

    set isDataWaveLoaded(value) {
        this._isDataWaveLoaded = value;
        if(value && isPrmFlow){
        this.setPrmNewAccount();
        }
    }

    @track isLoading = false;
    @track isLoaded = false;

    connectedCallback() {
        clAppReady(this.onClAppReady.bind(this));
    }

    onClAppReady() {
        CL.app.rx.lead.subscribe(lead => {
            this.leadToConvert = lead;
             if (this.leadToConvert && this.leadToConvert.hasBOBorWholesaleAccount) {
                window.dispatchEvent(new CustomEvent('onCreateNewAcc'));
             }
        });
        CL.app.rx.showElaCheckbox.subscribe(showElaCheckbox => {
            this.isShowElaCheckbox = showElaCheckbox && !isPrmFlow;
        })
        CL.app.rx.matchedAccounts.subscribe(matchedAccounts => {
            this.matchedAccounts = matchedAccounts;
            this.hasMoreAccounts = CL.app.hasMoreAccounts;
        });
        CL.app.rx.isCreateNewAccount.subscribe(isCreateNewAccount => {
            this.isCreateNewAccount = isCreateNewAccount;
            this.disableEla = !this.isCreateNewAccount;
            if (this.isCreateNewAccount){
                window.dispatchEvent(new CustomEvent('onCreateNewAcc'));
            }
        });
        CL.app.rx.selectedAccount.subscribe(selectedAccount => {
            this.selectedAccount = selectedAccount;

            // Rerender list to display selected
            this.matchedAccounts = [...this.matchedAccounts];

            window.dispatchEvent(new CustomEvent('getSelectedAccount', {detail: this.selectedAccount?.id}));

            this.getServiceEntitlement();
        });
        CL.app.rx.selectedLookupAccount.subscribe(selectedLookupAccount => {
            this.selectedLookupAccount = selectedLookupAccount;
        });
        CL.app.rx.targetAccount.subscribe(targetAccount => {
            this.targetAccount = targetAccount;
        });
        CL.app.rx.loadingStatus.subscribe(loadingStatus => {
            this.isLoading = loadingStatus.isAccountsLoading;
            this.isLoaded = loadingStatus.isAccountsLoaded;
        });
        CL.app.rx.errorsToShow.subscribe(errorsToShow => {
            this.showIsAccountMissingError = errorsToShow.isAccountMissing;
        });
        CL.app.rx.settings.subscribe(settings => {
            // && !isPrmFlow
            this.showExistingAccountSelector = settings.featuresEnabled.selectExistingAccount;
            this.isExpanded = this.showExistingAccountSelector;
            this.isElaFlowFeatureEnabled = settings.featuresEnabled.elaFlow;
        });
        CL.app.rx.isElaAccount.subscribe(isElaAccount => {
            this.isElaAccount = isElaAccount;
        });
        CL.app.rx.numberOfELAServiceAccounts.subscribe(numberOfELAServiceAccounts => {
            this.numberOfELAServiceAccounts = numberOfELAServiceAccounts;
        });
        
    }

    onIsCreateNewAccountChange(event) {
        this.isEla = false;
        CL.app.selectCreateNewAccount(!event.target.checked);
        if (!event.target.checked) {
            this.createNewAccount();
        } else {
            this.disableNumberOfELAServiceAccountsInput = true;
            CL.app.contactHasApplied = false;
            CL.app.opportunityContactRoleHasApplied = false;
        }
    }

    createNewAccount() {
        this.disableNumberOfELAServiceAccountsInput = false;
        this.apply();
        CL.app.contactHasApplied = true;
        CL.app.opportunityContactRoleHasApplied = true;
        window.dispatchEvent(new CustomEvent('getSelectedAccount'));
    }

    setPrmNewAccount() {
        this.isEla = false;
        CL.app.selectCreateNewAccount(true);
        this.createNewAccount();
    }

    onIsCreateElaAccountChange(event) {
        this.isEla = event.target.checked;
        this.disableNumberOfELAServiceAccountsInput = !this.isElaAccount;
    }

    onSelectedLookupAccountChange(event) {
        CL.app.selectLookupAccount(event.detail.valueObj);
        if (this.isElaFlowFeatureEnabled) {
            this.isEla = event.detail.valueObj.recordObj.ELA_Account_Type__c;
        }
    }

    onMatchedAccountSelected(event) {
        const accId = event.target.value;
        CL.app.selectMatchedAccount(accId);
        if (this.isElaFlowFeatureEnabled) {
            this.setElaFlag(accId);
        }
    }

    edit() {
        window.addEventListener('onCancel', this.onEditCancel.bind(this));
        window.addEventListener('onEditIsOkay', this.onEditOk.bind(this));
        window.dispatchEvent(new CustomEvent('onEditSelectedAccount', { bubbles: true, composed: true }));
        this.previousAccount = this.selectedAccount;
        CL.app.serviceSelector.setCloseDate(null);
    }

    loadMoreAccounts() {
        this.hasMoreAccountsDisabled = true;
        getAccounts(CL.app.leadId, this.matchedAccounts.length)
            .then(r => {
                CL.app.setHasMoreAccounts(r.data.hasMoreAccounts);
                CL.app.setMatchedAccounts(r.data.accounts, true);
                this.matchedAccounts = CL.app.matchedAccounts;
                this.hasMoreAccountsDisabled = false;
            })
            .catch(handleError)
    }

    getServiceEntitlement() {
        if (!this.selectedAccount
            || !this.selectedAccount.isExistingBusiness
            || this.selectedAccount.isNgbs
            || this.selectedAccount.service.loaded) {
            return;
        }

        const accountEntsToLoadFor = CL.app.selectedAccount;
        const isAccountIsTheSame = () => {
            const selectedAccId = CL.app.selectedAccount && CL.app.selectedAccount.id;
            return accountEntsToLoadFor.id === selectedAccId;
        };
        CL.app.setLoadingStatus({isEntitlementsLoading: true});
        getServiceEntitlement(this.selectedAccount.id)
            .then(r => {
                accountEntsToLoadFor.setService({
                    serviceEntitlement: r.data.serviceEntitlement,
                    servicePricebookEntry: r.data.servicePricebookEntry
                });

                if (isAccountIsTheSame()) {
                    CL.app.serviceSelector.legacyServiceSelector.initAccountTypeAndFields('Upsell');
                }
            })
            .catch(handleError)
            .then(() => CL.app.setLoadingStatus({isEntitlementsLoading: false}));
    }

    apply() {
        this.disableSwitch = true;
        this.toggleEdit = true;
        this.disableEla = true;
        this.disableNumberOfELAServiceAccountsInput = true;
        if (this.selectedAccount) {
            window.dispatchEvent(new CustomEvent('onSelectExistingAccountForContact'));
            window.dispatchEvent(new CustomEvent('onSelectExistingAccountForOpportunity'));
            window.dispatchEvent(new CustomEvent('onSelectExistingAccountForContactRole'));
        } else if (this.isCreateNewAccount) {
            window.dispatchEvent(new CustomEvent('onCreateNewAcc'));
        } else {
            showToast({title: this.label.NoAccountWasSelected, message: this.label.PleaseSelectAnAccount, type: 'error', duration: 5000});
            this.toggleEdit = false;
            this.disableSwitch = false;
            this.disableEla = !this.isCreateNewAccount;
        }
         this.toggleAccountHasApplied(this.toggleEdit);
    }

    toggleAccountHasApplied(hasApplied) {
        CL.app.accountHasApplied = hasApplied;
    }

    onEditCancel() {
        this.toggleEdit = true;
        this.disableSwitch = true;
        this.disableNumberOfELAServiceAccountsInput = true;
    }

    onEditOk() {
        CL.app.setAccountSelected(null);
        CL.app.setElaAccount(this.isElaAccount);
        this.toggleEdit = false;
        this.disableSwitch = false;
        this.disableEla = !this.isCreateNewAccount;
        this.disableNumberOfELAServiceAccountsInput = false;
        this.toggleAccountHasApplied(this.toggleEdit);
    }

    setElaFlag(accId) {
        let account = this.matchedAccounts.find(account => account.id === accId);
        this.isEla = account.isElaAccount;
    }

    onChangeNumberOfELAServiceAccounts(event) {
        this.numberOfELAServiceAccounts = event.target.value;
    }

    onBlurNumberOfELAServiceAccounts(event) {
        if (this.isCreateNewAccount) {
            CL.app.setNumberOfELAServiceAccounts(Number(event.target.value));
        }
        this.numberOfELAServiceAccounts = CL.app.numberOfELAServiceAccounts;
    }
}