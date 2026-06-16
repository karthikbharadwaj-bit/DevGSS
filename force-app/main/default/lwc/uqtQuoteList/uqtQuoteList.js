import { LightningElement, api, track  } from 'lwc';
import { showToast, showSpinner, hideSpinner } from 'c/clService';
import getBillingAccount from '@salesforce/apex/UQTQuoteListController.getBillingAccount';
import getQuotesData from '@salesforce/apex/UQTQuoteListController.getQuotesData';
import cloneQuote from '@salesforce/apex/UQTQuoteListController.cloneQuote';
import makeQuotePrimary from '@salesforce/apex/UQTQuoteListController.makeQuotePrimary';
import recalculateApprovals from '@salesforce/apex/UQTQuoteListController.recalculateApprovals';
import deleteCCAndCancelProServsIfRequired from '@salesforce/apex/UQTQuoteListController.deleteCCAndCancelProServsIfRequired';
import getRequestFormLink from '@salesforce/apex/IcbHelper.getRequestFormLink';
import engageProServ from '@salesforce/apex/QuotingToolQuoteApexController.engageProServ';
import createPSCase from '@salesforce/apex/QuotingToolQuoteApexController.createPSCase';
import { MIGRATION_IN_PROGRESS, MIGRATION_IN_PROGRESS_TITLE, ACCOUNT_MIGRATION_STATUSES } from "c/snUtils";

import checkAccountBillingCountry from '@salesforce/apex/UQTQuoteListController.checkAccountBillingCountry';
import dropQuote from '@salesforce/apex/UQTQuoteListController.dropQuote';

export default class UQTQuoteList extends LightningElement {

    @api opportunity;
    @api userPermissions;
    @api isPortalFlow;
    @api user;
    @api featureToggle;
    @track quotesGroups = [];
    @track isModalOpen;
    @track isCCProServProcess = false;
    selectedCaseReasons = [];
    recordTypeNameToQuotesMap;
    accBillingInfo;
    accountUnblockRequestLink;
    isWrongAccountBillingCountry;
    isPOCtoPaid;
    isProServOnly;

    QUOTE_ACTION_BUTTONS = {
        MAKE_PRIMARY: 'Make Primary',
        COPY: 'Copy',
        DELETE: 'Delete',
    };
    ADD_NEW_BUTTON = 'Add New';
    INITIATE_PROSERV_BUTTON = 'Initiate ProServ';
    INITIATE_CC_PROSERV_BUTTON = 'Initiate CC ProServ';
    QUOTE_RT_NAMES = {
        RT_NAME_SALES: 'Sales Quote',
        RT_NAME_POC_QUOTE: 'POC Quote',
        RT_NAME_PROSERV: 'ProServ Quote',
        RT_NAME_CCPROSERV: 'CC ProServ Quote'
    };
    OPPTY_STAGE_CLOSED_WON = '7. Closed Won';
    OPPTY_CUSTOMER_CONFIRMATION_PENDING = 'Pending';
    BILLING_ACCOUNT_STATUS = {
        DISABLED: 'Disabled',
        DELETED: 'Deleted',
        ACTIVE_DUNNING: 'ActiveDunning',
        ACTIVE_SUSPENDED: 'ActiveSuspend',
    };
    SEVERITY = {
        INFO: 'info',
        SUCCESS: 'success',
        ERROR: 'error',
        WARNING: 'warning',
    };
    MESSAGE_TYPES_BY_ACCOUNT_STATUS = {
        'error' : [this.BILLING_ACCOUNT_STATUS.DISABLED, this.BILLING_ACCOUNT_STATUS.DELETED],
        'warning' : [this.BILLING_ACCOUNT_STATUS.ACTIVE_DUNNING, this.BILLING_ACCOUNT_STATUS.ACTIVE_SUSPENDED],
    };
    TOOLTIP_MESSAGES = {
        READ_ONLY: 'Opportunity is Read-Only',
        QUOTE_IS_PRIMARY: 'Quote is already Primary',
        CANT_DELETE_PRIMARY: 'Primary Quote can\'t be deleted',
        QUOTE_IS_ACTIVE_AGREEMENT: 'Quote is already in Active Agreement status',
        PRIMARY_QUOTE_IS_ACTIVE_AGREEMENT: 'Primary Quote is already in Active Agreement status',
        CANT_DELETE_AGREEMENT: 'Quote with type Agreement can\'t be deleted',
        POC_WITH_APPROVED_APPROVAL: 'Approval has already been received for this POC Quote',
        ACCOUNT_BILLING_COUNTRY: 'Billing Country on Account does not match current Business Identity. Please make sure Billing Country on Account is populated correctly',
        POC_TO_PAID: 'POC quote was signed up',
        PS_SELECTED_DISABLED_QUOTE: 'You don\'t have permissions to copy when ProServ NGBS is selected',
        DISABLE_BTNS_PS_USER: 'Not available for PS users',
        DISABLE_BTNS_PS_CHANGE_ORDER: 'Not available for PS Change Order Opportunities',
    };
    GROUP_DATA_UI_AUTO = {
        [this.QUOTE_RT_NAMES.RT_NAME_SALES]: 'sales-quotes',
        [this.QUOTE_RT_NAMES.RT_NAME_POC_QUOTE]: 'poc-quotes',
        [this.QUOTE_RT_NAMES.RT_NAME_PROSERV]: 'proserv-quotes',
        [this.QUOTE_RT_NAMES.RT_NAME_CCPROSERV]: 'proserv-quotes'
    };
    PROFESSIONAL_SERVICES = 'Professional Services';
    PROSERV_STATUS_CANCELLED = 'Cancelled';

    PROSERV_PROFILES = [
        'Professional Services Lightning',
        'Professional Services Lightning - EU Restricted',
        'ProServ -Lightning',
        'ProServ -Lightning - EU Restricted'
    ];

    connectedCallback() {
        this.checkBillingAccountStatus()
            .then(() => this.checkValidAccountBillingCountry())
            .then(() => {
                this.refreshQuoteList();
            })
            .then(() => {
                this.handleAccountMigrationValidation();
            });
    }

    checkBillingAccountStatus() {
        if (!this.opportunity.Account?.Billing_ID__c) {
            return Promise.resolve();
        }
        return getBillingAccount({ 'accString': JSON.stringify(this.opportunity.Account) })
            .then(this.handleResponse)
            .then (res => {
                this.accBillingInfo = JSON.parse(res.accBillingInfo);
                this.isPOCtoPaid = res.isPOCtoPaid;
                this.handleAccountStatusInNGBS(this.accBillingInfo.status);
            })
            .catch(error => {
                console.error('handleErrors: ', error);
                const title = 'Service Unavailable';
                const message = error.body.message;
                showToast({
                    title,
                    message,
                    type: 'error',
                    duration: 0
                });
                hideSpinner();
            });
    }

    checkAccountMigrationFlag() {
        if (!this.doesMigrationBlockQuoteCreation && !this.isMigrationInProgress) {
            return;
        }

        showToast({
            title: MIGRATION_IN_PROGRESS_TITLE,
            message: MIGRATION_IN_PROGRESS,
            type: this.SEVERITY[this.doesMigrationBlockQuoteCreation ? 'ERROR' : 'WARNING'],
            link: {
                label: "form",
                url: this.accountUnblockRequestLink
            },
            duration: 0
        });
    }

    handleAccountMigrationValidation() {
        getRequestFormLink()
            .then(this.handleResponse)
            .then(res => {
                this.accountUnblockRequestLink = res.formLink
            })
            .then(() => {
                this.checkAccountMigrationFlag();
            });
    }

    refreshQuoteList() {
        return getQuotesData({ 'oppString': JSON.stringify(this.opportunity), 'isPortalFlow': this.isPortalFlow || false })
            .then(this.handleResponse)
            .then(res => {
                this.recordTypeNameToQuotesMap = res.recordTypeNameToQuotesMap;
                this.isProServOnly = res.isProServOnly;
                this.populateQuotesGroups(res.recordTypeNameToQuotesMap);
            })
    }

    checkValidAccountBillingCountry() {
        return checkAccountBillingCountry({'oppString': JSON.stringify(this.opportunity)})
            .then(this.handleResponse)
            .then(res => {
                if (!!res) {
                    this.isWrongAccountBillingCountry = res.isWrongAccountBillingCountry;
                }
            })
            .catch(error => {
                this.handleErrors(error);
            });
    }

    onCreate(event) {
        if (this.isPortalFlow) {
            window.open(`QuoteWizard?id=${this.opportunity.Id}&newQuoteType=${event.currentTarget.dataset.recordtype}&isPortalFlow=${this.isPortalFlow}`, '_blank');
        } else {
            window.open(`QuoteWizard?id=${this.opportunity.Id}&newQuoteType=${event.currentTarget.dataset.recordtype}`, '_blank');
        }
    }

    onMakePrimary(event) { 
        showSpinner('Updating selected quote');
        let eventDataset = event.currentTarget.dataset;
        this.refreshQuoteList()
            .then(() => {
                const quote = this.findQuoteByIdAndRecordType(eventDataset);
                if (quote && !quote.buttonsDisabled.primary) {
                    return this.makeQuotePrimaryProcess(eventDataset);
                } else {
                    this.showActionDisabledNotification();
                }
            })
            .catch(error => {
                this.handleErrors(error);
            })
            .finally(() => {
                hideSpinner();
            });
      }

    makeQuotePrimaryProcess(eventDataset) {
        return makeQuotePrimary({
            quoteId: eventDataset.quoteid,
            oppString: JSON.stringify(this.opportunity),
            recordType: eventDataset.recordtype,
            recordTypeNameToQuotesMap: this.recordTypeNameToQuotesMap,
        })
            .then(this.handleResponse)
            .then(res => {
                return deleteCCAndCancelProServsIfRequired({
                    recordType: eventDataset.recordtype,
                    recordTypeNameToQuotesMap: res.recordTypeNameToQuotesMap
                })
            })
            .then(this.handleResponse)
            .then(res => {
                return this.handleContactCenterAndProservsStatuses(res);
            })
            .then(res => {
                return recalculateApprovals({quoteId: eventDataset.quoteid, recordType: eventDataset.recordtype, recordTypeNameToQuotesMap: this.recordTypeNameToQuotesMap});
            })
            .then(this.handleResponse)
            .then(() => {
                this.refreshQuoteList();
            })
    }

    onCopy(event) {
        showSpinner('Cloning Quote');
        let eventDataset = event.currentTarget.dataset;
        this.refreshQuoteList()
            .then(() => {
                const quote = this.findQuoteByIdAndRecordType(eventDataset);
                if (quote && !quote.buttonsDisabled.copy) {
                    return this.copyQuoteProcess(eventDataset);
                } else {
                    this.showActionDisabledNotification();
                }
            })
            .catch(error => {
                this.handleErrors(error);
            })
            .finally(() => {
                hideSpinner();
            });
      }

    copyQuoteProcess(eventDataset) {
        return cloneQuote({ quoteId: eventDataset.quoteid, masterQuoteId: null })
            .then(this.handleResponse)
            .then(res => {
                let technicalQuotes = this.recordTypeNameToQuotesMap[eventDataset.recordtype]
                    .filter(quote => quote.MasterQuote__c === eventDataset.quoteid);
                return technicalQuotes.reduce((promise, techQuote) => {
                    return promise.then(() =>
                        cloneQuote({ quoteId: techQuote.Id, masterQuoteId: res.clonedQuote.Id })
                    );
                }, Promise.resolve());
            })
            .then(() => {
                return this.refreshQuoteList();
            })
    }

    onDelete(event) {
        showSpinner('Deleting Quote');
        let eventDataset = event.currentTarget.dataset;
        this.refreshQuoteList()
            .then(() => {
                const quote = this.findQuoteByIdAndRecordType(eventDataset);
                if (quote && !quote?.buttonsDisabled.delete) {
                    return this.deleteQuoteProcess(eventDataset);
                } else {
                    this.showActionDisabledNotification();
                }
            })
            .catch(error => {
                this.handleErrors(error);
            })
            .finally(() => {
                hideSpinner();
            });
      }

    deleteQuoteProcess(eventDataset) {
        return dropQuote({'quoteId' : eventDataset.quoteid})
            .then(() => {
                return this.refreshQuoteList();
            });
    }

    engageProServProcess(event) {
        let quoteType = '';
      if(this.isCCProServProcess) {
        quoteType = 'CCProServ';
      } else {
        quoteType = 'ProServ';
      }
      showSpinner('Engage ' +quoteType+ ' Quote');
      return engageProServ({ 'opportunityId': this.opportunity.Id, 'details': '', type: quoteType, isNewBilling: true })
        .then(() => {
          return this.refreshQuoteList();
        }).then(() => {
            showSpinner('Creating ' +quoteType+ ' Case');
            createPSCase({ params: this.prepareCaseParams() })
        }).catch(error => {
            this.handleErrors(error);
        })
        .finally(() => {
            this.closeModal();
            hideSpinner();
        });;
    }

    populateQuotesGroups(recordTypeNameToQuotesMap) {
        this.recordTypeNameToQuotesMap = recordTypeNameToQuotesMap;
        this.quotesGroups = [];
        let psOrCCPSQuotesList = [];
        let showProServButton = false;
        let showCCProServButton = false; 
        for (let recordTypeName in recordTypeNameToQuotesMap) {
            if (Object.values(this.QUOTE_RT_NAMES).includes(recordTypeName)) {
                if (this.skipQuoteGroup(recordTypeName)) {
                   continue;
                }
                const quotes = recordTypeNameToQuotesMap[recordTypeName];
                if(recordTypeName === this.QUOTE_RT_NAMES.RT_NAME_CCPROSERV || recordTypeName === this.QUOTE_RT_NAMES.RT_NAME_PROSERV) {
                    let quotesList = [];
                    if(quotes !== null && quotes.length > 0) {
                        quotesList = recordTypeName === this.QUOTE_RT_NAMES.RT_NAME_CCPROSERV ? this.removeCancelledQuotes(quotes) : quotes;
                        psOrCCPSQuotesList = psOrCCPSQuotesList.length > 0 ? [...psOrCCPSQuotesList, ...quotesList] : quotesList;
                    }
                    showProServButton = recordTypeName === this.QUOTE_RT_NAMES.RT_NAME_PROSERV ? this.isInitiateProServButtonVisible(recordTypeName, quotesList) : showProServButton;
                    showCCProServButton = recordTypeName === this.QUOTE_RT_NAMES.RT_NAME_CCPROSERV ? this.isInitiateCCProServButtonVisible(recordTypeName, quotesList) : showCCProServButton;
                } else {
                    let isProServButtonVisible = this.isInitiateProServButtonVisible(recordTypeName, quotes);
                    let isCCProServButtonVisible = this.isInitiateCCProServButtonVisible(recordTypeName, quotes);
                    this.addValuesToQuotesGroups(recordTypeName, quotes, isProServButtonVisible, isCCProServButtonVisible);
                }
            }
        }
        if(psOrCCPSQuotesList.length > 0 || showProServButton || showCCProServButton) {
            this.addValuesToQuotesGroups(this.QUOTE_RT_NAMES.RT_NAME_PROSERV, psOrCCPSQuotesList, showProServButton, showCCProServButton);
        }
    }

    removeCancelledQuotes(quotesList) {
        return quotesList.filter(quote => quote.ProServ_Status__c !== this.PROSERV_STATUS_CANCELLED);
    }

    addValuesToQuotesGroups(recordTypeName, quoteList, showProServButton, showCCProServButton) {
        this.quotesGroups.push({
            recordTypeName: recordTypeName,
            quotes: this.enrichAndSortQuotes(quoteList),
            groupName: this.getQuotesGroupName(recordTypeName),
            groupDataUiAuto: this.getGroupDataUIAuto(recordTypeName),
            isAddNewButtonVisible: this.isAddNewButtonVisible(recordTypeName),
            isAddNewButtonDisabled: this.isAddNewButtonDisabled(recordTypeName),
            isInitiateProServButtonVisible: showProServButton,
            isInitiateCCProServButtonVisible: showCCProServButton,
            isPOCsectionInPOCtoPaid: this.isPOCsectionInPOCtoPaid(recordTypeName),
            isQuoteLinkBlocked: this.isQuoteLinkBlocked(recordTypeName),
            showNoQuotesFound: this.showNoQuotesFound(recordTypeName, quoteList)
        });
    }

    skipQuoteGroup(recordTypeName) {
        const addOnlyProServ = this.isProServOnly && !(this.isProServ(recordTypeName) || this.isCCProServ(recordTypeName));
        const skipProServ = !this.isProServOnly && (this.isProServ(recordTypeName) || this.isCCProServ(recordTypeName));

        return [
          addOnlyProServ,
          skipProServ
        ].some(Boolean);
    }

    enrichAndSortQuotes(quotes) {
        return quotes
            .filter(quote => !quote.IsMultiProductTechnicalQuote__c)
            .map(quote => this.getQuoteWithExtraProps(quote))
            .sort((a, b) => a.QuotePosition__c < b.QuotePosition__c ? -1 : 1)
            .sort((a, b) => a.isPrimary__c > b.isPrimary__c ? -1 : 1);
    }

    getQuotesGroupName(recordTypeName) {
        return (this.isProServ(recordTypeName) || this.isCCProServ(recordTypeName))
            ? this.PROFESSIONAL_SERVICES
            : recordTypeName;
    }

    getQuoteWithExtraProps(quote) {
        return {
            ...quote,
            url: this.getQuoteUrl(quote.Id),
            buttonsDisabled: this.getQuoteActionsDisable(quote)
        }
    }

    getQuoteActionsDisable(quote) {
        const ACTIONS = [
            'primary',
            'copy',
            'delete'
        ];
        let actionsDisabled = {};
        for (let action of ACTIONS) {
            actionsDisabled[action] = this.isActionDisabled(action, quote);
        }
        return actionsDisabled;
    }

    isActionDisabled(action, quote) {
        switch (action) {
            case 'primary':
                return this.readOnly
                    || this.isPocQuoteInPOCtoPaid(quote)
                    || this.isPrimary(quote, action)
                    || this.isProServInitiatedForGSP(quote.RecordType.Name)
                    || this.isSalesQuoteAndPrimaryIsActiveAgreement(quote);
            case 'copy':
                return this.readOnly
                    || this.isPocQuoteInPOCtoPaid(quote)
                    || this.isProServInitiatedForGSP(quote.RecordType.Name)
                    || this.isSalesQuoteAndPrimaryIsActiveAgreement(quote)
                    || this.isQuotePSNgbsDisabled(quote);
            case 'delete':
                return this.readOnly
                    || this.isPocQuoteInPOCtoPaid(quote)
                    || this.isAgreement(quote)
                    || this.isPrimary(quote, action)
                    || this.isProServInitiatedForGSP(quote.RecordType.Name)
                    || this.isPOCWithApprovedApproval(quote);
        }
    }

    get readOnly() {
        const opportunityStageClosedWon = this.opportunity.StageName === this.OPPTY_STAGE_CLOSED_WON;
        const isCustomerConfirmationPending = this.opportunity.CustomerConfirmation__c === this.OPPTY_CUSTOMER_CONFIRMATION_PENDING;
        const noPermissionsToEditQuote = !this.userPermissions.EditSalesQuote;
        const isReadOnly = opportunityStageClosedWon
            || noPermissionsToEditQuote
            || isCustomerConfirmationPending
            || this.doesMigrationBlockQuoteCreation
            || this.isBillingAccountDeletedOrDisabled
            || this.isWrongAccountBillingCountry
            || this.isProServUser()
            || this.isProServChangeOrderOpp();
        if (isReadOnly) {
            if (this.isProServChangeOrderOpp()) {
                return this.TOOLTIP_MESSAGES.DISABLE_BTNS_PS_CHANGE_ORDER;
            } else if (this.isProServUser()) {
                return this.TOOLTIP_MESSAGES.DISABLE_BTNS_PS_USER;
            } else if (this.isWrongAccountBillingCountry) {
                return this.TOOLTIP_MESSAGES.ACCOUNT_BILLING_COUNTRY
            } else {
                return this.TOOLTIP_MESSAGES.READ_ONLY;
            }
        }
    }

    get containerClass() {
        return this.isPortalFlow ? 'container-prm slds-grid' : 'container slds-p-around_x-small slds-grid';
    }

    get articleClass() {
        return this.isPortalFlow ? 'slds-tabs_card slds-scrollable' : 'slds-tabs_card slds-m-around_x-small';
    }

    isAddNewButtonVisible(recordTypeName) {
        return !(this.isProServ(recordTypeName) || this.isCCProServ(recordTypeName));
    }

    isAddNewButtonDisabled(recordTypeName) {
        return this.readOnly || this.isPOCsectionInPOCtoPaid(recordTypeName);
    }

    isProServInitiatedForGSP(recordTypeName) {
        return (this.isProServ(recordTypeName) || this.isCCProServ(recordTypeName))
          && this.isProServOnly
          && (this.recordTypeNameToQuotesMap[this.QUOTE_RT_NAMES.RT_NAME_PROSERV]?.length > 0
            || this.recordTypeNameToQuotesMap[this.QUOTE_RT_NAMES.RT_NAME_CCPROSERV]?.length > 0);
    }

    isQuoteLinkBlocked(recordTypeName) {
      return this.isPOCsectionInPOCtoPaid(recordTypeName) || this.isProServInitiatedForGSP(recordTypeName);
    }

    isPrimary(quote, action) {
        if (!quote.isPrimary__c) {
            return;
        }
        switch (action) {
            case 'primary':
                return this.TOOLTIP_MESSAGES.QUOTE_IS_PRIMARY;
            case 'delete':
                return this.TOOLTIP_MESSAGES.CANT_DELETE_PRIMARY;

        }
    }

    isSalesQuoteAndPrimaryIsActiveAgreement(quote) {
        if (!this.isSalesQuote(quote)) {
            return;
        }
        if (this.isPrimaryQuoteSalesActiveAgreement?.Id == quote.Id) {
            return this.TOOLTIP_MESSAGES.QUOTE_IS_ACTIVE_AGREEMENT;
        } else if (this.isPrimaryQuoteSalesActiveAgreement) {
            return this.TOOLTIP_MESSAGES.PRIMARY_QUOTE_IS_ACTIVE_AGREEMENT;
        }
    }

    isQuotePSNgbsDisabled(quote) {
        const pkgInfos = JSON.parse(quote.Package_Info__c);
        const isProServServiceSelected = (pkgInfos.some(info => info.productName == this.PROFESSIONAL_SERVICES)) && !this.featureToggle.ProServInNGBS__c;
        return isProServServiceSelected? this.TOOLTIP_MESSAGES.PS_SELECTED_DISABLED_QUOTE : false;
    }

    isProServUser() {
        return this.PROSERV_PROFILES.includes(JSON.parse(this.user).Profile.Name);
    }

    isProServChangeOrderOpp() {
        return this.opportunity.Parent_Order__c != null && this.opportunity.Tier_Name__c == this.PROFESSIONAL_SERVICES;
    }

    isSalesQuote(quote) {
        return this.recordTypeNameToQuotesMap[this.QUOTE_RT_NAMES.RT_NAME_SALES]?.find(qt => qt.Id == quote.Id);
    }

    isPocQuote(quote) {
        return this.recordTypeNameToQuotesMap[this.QUOTE_RT_NAMES.RT_NAME_POC_QUOTE]?.find(qt => qt.Id == quote.Id);
    }

    get isPrimaryQuoteSalesActiveAgreement() {
        return this.recordTypeNameToQuotesMap[this.QUOTE_RT_NAMES.RT_NAME_SALES]?.find(quote => quote.QuoteType__c == 'Agreement' && quote.Status == 'Active' && quote.isPrimary__c);
    }

    isAgreement(quote) {
        if (quote.QuoteType__c == 'Agreement') {
            return this.TOOLTIP_MESSAGES.CANT_DELETE_AGREEMENT;
        }
    }

    isPocQuoteInPOCtoPaid(quote) {
        if(this.isPocQuote(quote) && this.isPOCtoPaid) {
            return this.TOOLTIP_MESSAGES.POC_TO_PAID;
        };
    }

    isPOCsectionInPOCtoPaid(recordTypeName) {
        if (recordTypeName == this.QUOTE_RT_NAMES.RT_NAME_POC_QUOTE && this.isPOCtoPaid) {
            return this.TOOLTIP_MESSAGES.POC_TO_PAID;
        }
    }

    // Approvals__r returned only for Approved POC approvals related to POC quote
    isPOCWithApprovedApproval(quote) {
        if (Boolean(quote?.Approvals__r)) {
            return this.TOOLTIP_MESSAGES.POC_WITH_APPROVED_APPROVAL;
        }
    }

    isProServ(recordTypeName) {
        return recordTypeName === this.QUOTE_RT_NAMES.RT_NAME_PROSERV;
    }

    isInitiateProServButtonVisible(recordTypeName, quotes) {
        return this.isProServ(recordTypeName) && quotes.length === 0;
    }

    isCCProServ(recordTypeName) {
        return recordTypeName === this.QUOTE_RT_NAMES.RT_NAME_CCPROSERV;
    }

    isInitiateCCProServButtonVisible(recordTypeName, quotes) {
        return this.isCCProServ(recordTypeName) && quotes.length === 0;
    }

    showNoQuotesFound(recordTypeName, quotes) {
      return (this.isProServ(recordTypeName) || this.isCCProServ(recordTypeName))
          ? false
          : quotes.length === 0;
    }

    get isBillingAccountDeletedOrDisabled() {
        return this.opportunity?.Account?.Billing_ID__c && !this.accBillingInfo
            || this.MESSAGE_TYPES_BY_ACCOUNT_STATUS.error.includes(this.accBillingInfo?.status);
    }

    isBillingAccountDisabledStatus(status) {
        return this.MESSAGE_TYPES_BY_ACCOUNT_STATUS.error.includes(status);
    }

    isBillingAccountActiveSuspended(status) {
        return this.MESSAGE_TYPES_BY_ACCOUNT_STATUS.warning.includes(status);
    }

    get doesMigrationBlockQuoteCreation() {
        return ACCOUNT_MIGRATION_STATUSES.BLOCKING_ACCOUNT_MIGRATION_STATUSES.includes(this.opportunity.Account?.AccMigrationFlag__c);
    }

    get isMigrationInProgress() {
        return ACCOUNT_MIGRATION_STATUSES.IN_PROGRESS_ACCOUNT_MIGRATION_STATUSES.includes(this.opportunity.Account?.AccMigrationFlag__c);
    }

    getQuoteUrl(quoteId) {
        return this.isPortalFlow
            ? `QuoteWizard?quoteId=${quoteId}&id=${this.opportunity.Id}&isPortalFlow=${this.isPortalFlow}`
            : `QuoteWizard?quoteId=${quoteId}&id=${this.opportunity.Id}`;
    }

    getGroupDataUIAuto(type) {
        return this.GROUP_DATA_UI_AUTO[type];
    }

    findQuoteByIdAndRecordType(eventData) {
        return this.findQuotesByRecordType(eventData.recordtype).find(quote => quote.Id === eventData.quoteid);
    }

    findQuotesByRecordType(recordtype) {
        return this.quotesGroups.find(quoteGroup => quoteGroup.recordTypeName === recordtype)?.quotes || [];
    }

    showActionDisabledNotification() {
        showToast({
            title: 'Quoting list is refreshing',
            type: this.SEVERITY.INFO,
            duration: 4000
        });
    }

    handleAccountStatusInNGBS(status) {
        const statusWithSpaces = status.replace(/[A-Z]/g, ' $&').trim();
        if (this.isBillingAccountDisabledStatus(status)) {
            showToast({
                title: `This Account is ${statusWithSpaces}. You can't do any operations with this account.`,
                type: this.SEVERITY.ERROR,
                duration: 0
            });
        }
        if (this.isBillingAccountActiveSuspended(status)) {
            showToast({
                title: `This Account status is ${statusWithSpaces}`,
                type: this.SEVERITY.WARNING,
                duration: 0
            });
        }
    }

    handleContactCenterAndProservsStatuses(res) {
        if (!res.isContactCenterDeleted && !res.isProServCancelled && !res.isCCProServCancelled) {
            return;
        }
        const notifications = [];
        if (res.isContactCenterDeleted) {
            notifications.push('Contact Center Quote deleted');
        }
        if (res.isProServCancelled) {
            notifications.push('ProServ cancelled');
        }
        if (res.isCCProServCancelled) {
            notifications.push('Contact Center ProServ cancelled');
        }
        const title = notifications.join(', ');
        showToast({
            title: title,
            type: this.SEVERITY.SUCCESS,
            duration: 4000
        });
    }

    handleResponse(res) {
        if (res.status !== 'success') {
             throw res;
        }
        return res.data;
    }

    handleErrors(res) {
        console.error('handleErrors: ', res);
        if (res?.body && res?.errorType && res.body.message) {
            const maxMessageLength = 300;
            const title = `Unexpected exception occurred (${res.errorType})`;
            const message = res.body.message.length > maxMessageLength
            ? res.body.message.substring(0, maxMessageLength).concat('...')
            : res.body.message;
            showToast({
                title,
                message,
                type: this.SEVERITY.ERROR,
                duration: 0
            });
        } else if (res?.messages) {
            res.messages.forEach(m => {
                showToast(m.message, m.messageDetails, m.severity || m.status);
            });
        }
    }

    openModal(event) {
        this.isCCProServProcess = (event.target.dataset.id === 'initiate-cc-proserv');
        this.isModalOpen = true;
    }

    closeModal() {
        this.isModalOpen = false;
        this.selectedCaseReasons = [];
    }

    get backdrop() {
        return `slds-backdrop${this.isModalOpen ? " slds-backdrop_open" : ""}`;
    }

    get caseReasons() {
        return [
            {
                 label: 'Implementation Services Quote / SOW',
                 value: 'Implementation Services Quote / SOW'
             },
             {
                 label: 'Managed Services, Recurring Services, Advanced Support',
                 value: 'Managed Services, Recurring Services, Advanced Support'
             },
             ...(this.isCCProServProcess === false ? [{
                 label: 'Video / Rooms in a Box',
                 value: 'Video / Rooms in a Box'
             }] : []),
             {
                 label: 'Aftermarket PS Support',
                 value: 'Aftermarket PS Support'
             }
         ];
     }   

    selectCaseReason(e) {
        this.selectedCaseReasons = e.detail.value;
    }

    prepareCaseParams() {
        const description = 'Please contact customer for requested quote';
        const category = this.selectedCaseReasons.join(';');
        const recordTypeName = this.isCCProServProcess ? this.QUOTE_RT_NAMES.RT_NAME_CCPROSERV : this.QUOTE_RT_NAMES.RT_NAME_PROSERV;
        const quoteRecord = this.recordTypeNameToQuotesMap[recordTypeName][0];

        let caseParams = {
            accountId: this.opportunity.Account?.Id,
            opportunityId: this.opportunity.Id,
            origin: 'Quoting Page',
            status: 'New',
            description: description,
            isFromProServ: true,
            subject: this.isCCProServProcess ? 'CC Quote requested for ' + this.opportunity.Account?.Name : 'UC Quote requested for ' + this.opportunity.Account?.Name,
            category: category,
            quoteApprovalId: quoteRecord?.Id,
            opportunityOwnerEmail: this.opportunity.Owner.Email,
            partnerContact: this.opportunity?.Account.Partner_Contact__c,
            caseCategory: 'ProServ Quote Request',
            segment: this.opportunity.Owner.SegmentPicklist__c
        };

        return JSON.stringify(caseParams);
    }
}