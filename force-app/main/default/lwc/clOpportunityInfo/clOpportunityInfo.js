/* globals CL */
import { LightningElement, track, api } from 'lwc';
import { clAppReady, getOpportunities, handleError, showToast } from 'c/clService';
import partnerLeadTemplate from './partnerLeadTemplate.html';
import salesLeadTemplate from './salesLeadTemplate.html';
import OnlyOneOpportunitywasfound from '@salesforce/label/c.clOpportunityInfoOnlyOneOpportunitywasfound';
import Opportunitysection from '@salesforce/label/c.clOpportunityInfoOpportunitysection';
import OpportunityName from '@salesforce/label/c.clOpportunityInfoOpportunityName';
import BusinessIdentity from '@salesforce/label/c.clOpportunityInfoBusinessIdentity';
import Currency from '@salesforce/label/c.clOpportunityInfoCurrency';
import None from '@salesforce/label/c.clOpportunityInfoNone';
import Brand from '@salesforce/label/c.clOpportunityInfoBrand';
import Country from '@salesforce/label/c.clOpportunityInfoCountry';
import SelectedServicePlan from '@salesforce/label/c.clOpportunityInfoSelectedServicePlan';
import BillingSystem from '@salesforce/label/c.clOpportunityInfoBillingSystem';
import Legacy from '@salesforce/label/c.clOpportunityInfoLegacy';
import NGBS from '@salesforce/label/c.clOpportunityInfoNGBS';
import Opportunitynameisrequired from '@salesforce/label/c.clOpportunityInfoOpportunitynameisrequired';
import Pleasespecifyanopportunityname from '@salesforce/label/c.clOpportunityInfoPleasespecifyanopportunityname';
import ServicePlanisrequired from '@salesforce/label/c.clOpportunityInfoServicePlanisrequired';
import PleaseselectServicePlan from '@salesforce/label/c.clOpportunityInfoPleaseselectServicePlan';
import ChargeTermisrequired from '@salesforce/label/c.clOpportunityInfoChargeTermisrequired';
import PleaseselectChargeTerm from '@salesforce/label/c.clOpportunityInfoPleaseselectChargeTerm';
import Choosefrommatchedopportunities from '@salesforce/label/c.clOpportunityInfoChoosefrommatchedopportunities';
import Stage from '@salesforce/label/c.clOpportunityInfoStage';
import OpportunityOwnerAlias from '@salesforce/label/c.clOpportunityInfoOpportunityOwnerAlias';
import Estimated12MonthBooking from '@salesforce/label/c.clOpportunityInfoEstimated12MonthBooking';
import LastModifiedDate from '@salesforce/label/c.clOpportunityInfoLastModifiedDate';
import OpportunityRecordType from '@salesforce/label/c.clOpportunityInfoOpportunityRecordType';
import Loadmore from '@salesforce/label/c.clOpportunityInfoLoadmore';
import NoOpportunitywillbecreated from '@salesforce/label/c.clOpportunityInfoNoOpportunitywillbecreated';
import NoOpportunitiesmatchthechosenAccountAnewOpportunitywillbecreated from '@salesforce/label/c.clOpportunityInfoNoOpportunitiesmatchthechosenAccountAnewOpportunity';
import NewOpportunitywillnotbecreated from '@salesforce/label/c.clOpportunityInfoNewOpportunitywillnotbecreated';
import LeadwillbeconvertedintonewAccountandContact from '@salesforce/label/c.clOpportunityInfoLeadwillbeconvertedintonewAccountandContact';
import LeadwillbeconvertedasaContactunderexistingAccount from '@salesforce/label/c.clOpportunityInfoLeadwillbeconvertedasaContactunderexistingAccount';
import NoOpportunitywasSelected from '@salesforce/label/c.clOpportunityInfoNoOpportunitywasSelected';
import PleaseselectanOpportunityfromthelist from '@salesforce/label/c.clOpportunityInfoPleaseselectanOpportunityfromthelist';
import DonotcreateOpportunity from '@salesforce/label/c.clOpportunityInfoDonotcreateOpportunity';
import CreatenewOpportunity from '@salesforce/label/c.clOpportunityInfoCreatenewOpportunity';
import SelectexistingOpportunity from '@salesforce/label/c.clOpportunityInfoSelectexistingOpportunity';
import TryingtoconnectwithNGBS from '@salesforce/label/c.clOpportunityInfoTryingtoconnectwithNGBS';
import Ifconnectionisnotreachedpleaserefresh from '@salesforce/label/c.clOpportunityInfoIfconnectionisnotreachedpleaserefresh';
import terminatedAccError from '@salesforce/label/c.clOpportunityInfoTerminatedAcc';
import TerminatedMasterAccError from '@salesforce/label/c.clOpportunityInfoTerminatedMasterAcc';
import CloseDateIsRequired from '@salesforce/label/c.clCloseDateIsRequired';
import SelectCloseDate from '@salesforce/label/c.clSelectCloseDate';
import infoMessage from '@salesforce/label/c.SC_information';

export default class ClOpportunityInfo extends LightningElement {
    @track value = 'selectExistingOpp';
    @track options = [];
    @track countries = [];
    @track country;
    @track doNotCreateOpp = false;
    @track selectExistingOpp = true;
    @track createNewOpp = false;
    @track isCreateNewOpportunity = true;
    @api isLeadRecordTypeSales = false;
    @track accountHasAppliedChanges = false;
    @track noQuoteForThisFilters = false;
    @track noQuoteForThisFiltersNGBS = false;
    @track noQuoteForThisLead = false;
    @track showRadioGroup = true;
    @track tableTitle;
    @track isExpanded = false;
    @track notIsExpanded = true;

    @track opportunityName = '';
    @track selectedAccount;
    @track selectedMatchedAccount = null;
    @track selectedServiceName;
    @track selectedServicePrice;
    @track selectedServiceId
    @track selectedBrand;
    @track selectedBusinessIdentity;
    @track selectedCurrency;
    @track selectedServiceIsLegacy;
    @track selectedServiceChargeTerm;
    @track selectedServicePriceCurrencyCode;
    @track selectedAreaCode = '';
    @track selectedAreaCodeRequired = false;
    selectedCloseDate;

    @track selectedOpportunity = null;
    @track matchedOpportunities = [];
    @track hasMoreOpportunities = false;
    @track hasMoreOpportunitiesDisabled = false;
    @track isLoading;
    @track isLoaded;
    @track isPreselectLoading;
    @track isSelectPackagesByBusinessIdentity = false;

    @track isLegacy;

    @track showIsServicePlanMissingError = false;
    @track showIsConnectingWithNgbsError = false;
    @track showIsOpportunityNameMissingError = false;
    @track showIsNgbsChargeTermMissingError = false;
    @track showIsNgbsDefaultAreaCodeMissingError = false;
    isCloseDateMissing;

    @track showNoOpportunityNewAccountMessage = false;
    @track showNoOpportunityExistingAccountMessage = false;
    @track accountHasOpportunities = true;

    @track isTerminatedAcc = false;
    @track isTerminatedMasterAcc = false;

    @track label = {
        TryingtoconnectwithNGBS,
        Ifconnectionisnotreachedpleaserefresh,
        DonotcreateOpportunity,
        CreatenewOpportunity,
        SelectexistingOpportunity,
        NoOpportunitywasSelected,
        PleaseselectanOpportunityfromthelist,
        NewOpportunitywillnotbecreated,
        LeadwillbeconvertedintonewAccountandContact,
        LeadwillbeconvertedasaContactunderexistingAccount,
        Opportunitysection,
        OpportunityName,
        BusinessIdentity,
        Currency,
        None,
        Brand,
        Country,
        SelectedServicePlan,
        BillingSystem,
        Legacy,
        NGBS,
        Opportunitynameisrequired,
        Pleasespecifyanopportunityname,
        ServicePlanisrequired,
        PleaseselectServicePlan,
        ChargeTermisrequired,
        PleaseselectChargeTerm,
        Choosefrommatchedopportunities,
        Stage,
        OpportunityOwnerAlias,
        Estimated12MonthBooking,
        LastModifiedDate,
        OpportunityRecordType,
        Loadmore,
        NoOpportunitywillbecreated,
        NoOpportunitiesmatchthechosenAccountAnewOpportunitywillbecreated,
        OnlyOneOpportunitywasfound,
        terminatedAccError,
        TerminatedMasterAccError,
        CloseDateIsRequired,
        SelectCloseDate,
        infoMessage
    };

    render() {
        return this.isLeadRecordTypeSales ? salesLeadTemplate : partnerLeadTemplate;
    }

    @track notifications = [];

    get isNotLoaded() {
        return !this.isLoaded;
    }

    get isExpandedView() {
        return this.isExpanded && this.createNewOpp && this.isLoaded;
    }

    get isCollapsedView() {
        return !this.isExpanded && this.isLoaded;
    }

    get isOpportunityInfoHasErrors() {
        return this.showIsServicePlanMissingError
            || this.showIsOpportunityNameMissingError
            || this.showIsNgbsChargeTermMissingError
            || this.isCloseDateMissing
            || this.showIsNgbsDefaultAreaCodeMissingError;
    }

    get containerClasses() {
        return [
            'slds-card slds-p-around_medium slds-m-bottom_medium',
            'slds-m-top_medium',
            this.isOpportunityInfoHasErrors && 'card_has-errors'
        ].filter(Boolean).join(' ');
    }

    get showSelectedServicePlan() {
        return !this.noQuoteForThisLead
          && this.isLegacy
            ? !this.noQuoteForThisFilters
            : !this.noQuoteForThisFiltersNGBS;
      }

    get isCollapsedAndCreateNew() {
        return this.isCollapsedView && this.createNewOpp;
    }

    connectedCallback() {
        clAppReady(this.onClAppReady.bind(this));
        this.options.push(
            { label: this.label.DonotcreateOpportunity, value: 'doNotCreateOpp' },
            { label: this.label.CreatenewOpportunity, value: 'createNewOpp' },
            { label: this.label.SelectexistingOpportunity, value: 'selectExistingOpp' }
        );
        window.addEventListener('onSelectExistingAccountForOpportunity', this.loadOpportunityComponent.bind(this));
        window.addEventListener('onEditIsOkay', this.resetOpportunityComponent.bind(this));
        window.addEventListener('onCancel', this.accountEditWasCanceled.bind(this));
        window.addEventListener('onCreateNewAcc', this.createNewAccount.bind(this));
    }

    createNewAccount() {
        this.isExpanded = false;
        this.selectExistingOpp = false;
        this.accountHasAppliedChanges = true;
        this.showRadioGroup = false;
        this.createNewOpp = true;
        CL.app.setOpportunityOption('createNewOpp');
        CL.app.setIsCreateNewOpportunity(this.createNewOpp);
        this.toggleOpportunityHasApplied(true);
    }

    resetOpportunityComponent() {
        if (!CL.app.isCreateNewAccount) {
            this.setOpportunityCreationOption('selectExistingOpp');
        }
        this.accountHasAppliedChanges = false;
        this.selectedOpportunity = null;
        CL.app.selectedOpportunity = null;
        this.showRadioGroup = true;
        this.createNewOpp = false;
        this.selectedMatchedAccount = null;
        window.dispatchEvent(new CustomEvent('onResetOpportunityFinished'));
    }

    accountEditWasCanceled() {
        this.accountHasAppliedChanges = true;
    }

    get showSelectedServicePlan() {
        return !this.noQuoteForThisFilters && !this.noQuoteForThisLead;
    }

    onClAppReady() {
        CL.app.rx.opportunityName.subscribe(opportunityName => {
            this.opportunityName = opportunityName;
        });

        CL.app.rx.country.subscribe(country => {
            this.country = country;
        });

        CL.app.rx.countries.subscribe(countries => {
            this.countries = countries;
        });

        CL.app.rx.matchedOpportunities.subscribe(matchedOpportunities => {
            this.matchedOpportunities = matchedOpportunities;
            this.hasMoreOpportunities = CL.app.hasMoreOpportunities;
        });
        CL.app.rx.selectedOpportunity.subscribe(selectedOpportunity => {
            this.selectedOpportunity = selectedOpportunity;
            this.matchedOpportunities = [...this.matchedOpportunities];
            window.dispatchEvent(new CustomEvent('getSelectedOpportunity', {detail: this.selectedOpportunity?.id}));
        });

        CL.app.serviceSelector.rx.filters.subscribe(filters => {
            this.selectedBrand = filters.brand.value;
            this.selectedBusinessIdentity = CL.app.serviceSelector.getBusinessIdentityLabel(filters.businessIdentity.value);
            this.selectedCurrency = filters.currency.value;
            this.noQuoteForThisFilters = CL.app.serviceSelector.noQuoteForThisFilters;
            this.noQuoteForThisFiltersNGBS = CL.app.serviceSelector.noQuoteForThisFiltersNGBS;
            //this.selectedCloseDate = filters.closeDate.value;
            if(filters.closeDate.value != null){
                this.selectedCloseDate = filters.closeDate.value;
            }
            else if(CL.app.serviceSelector.lead.record && CL.app.serviceSelector.lead.record.Estimated_Close_Date__c != null){
                this.selectedCloseDate = CL.app.serviceSelector.lead.record.Estimated_Close_Date__c;
            }
        });
        CL.app.serviceSelector.rx.selectedService.subscribe(selectedService => {
            this.selectedServiceName = selectedService && selectedService.name || '--None--';
            this.selectedServicePrice = selectedService && selectedService.price;
            this.selectedServiceId = selectedService && selectedService.id;
            this.selectedServiceIsLegacy = selectedService && selectedService.isLegacy;
            this.selectedServiceChargeTerm = selectedService && selectedService.chargeTerm;
            this.selectedServicePriceCurrencyCode = selectedService && selectedService.currencyCode;
            this.selectedBrand = selectedService && selectedService.brandName
                || CL.app.serviceSelector.filters.brand.value;
        });
        CL.app.rx.loadingStatus.subscribe(loadingStatus => {
            this.isLoading = loadingStatus.isLegacyServicesLoading || loadingStatus.isNgbsInitializing;
            this.isLoaded = loadingStatus.isLegacyServicesLoaded && !loadingStatus.isNgbsInitializing;
            this.isPreselectLoading = loadingStatus.isEntitlementsLoading || loadingStatus.isNgbsAccountLoading;
        });
        CL.app.rx.errorsToShow.subscribe(errorsToShow => {
            this.showIsServicePlanMissingError = errorsToShow.isServicePlanMissing;
            this.showIsOpportunityNameMissingError = errorsToShow.isOpportunityNameMissing;
            this.showIsNgbsChargeTermMissingError = errorsToShow.isNgbsChargeTermMissing;
            this.showIsNgbsDefaultAreaCodeMissingError = errorsToShow.isNgbsDefaultAreaCodeMissingError;
            this.isCloseDateMissing = errorsToShow.isCloseDateMissing;
        });
        CL.app.rx.targetAccount.subscribe(() => {
            this.showNoOpportunityNewAccountMessage = CL.app.isCreateNewAccount;
            this.showNoOpportunityExistingAccountMessage = CL.app.selectedAccount && !CL.app.isCreateNewAccount;

            this.isTerminatedAcc = false;
            this.isTerminatedMasterAcc = false;
            if (!CL.app.isCreateNewAccount
                && CL.app.selectedAccount) {
                this.selectedAccount = CL.app.selectedAccount.record;
                if (CL.app.selectedAccount.isTerminated) {
                    this.isTerminatedAcc = true;
                }

                if (CL.app.selectedAccount.isMasterAccountTerminated
                    && CL.app.selectedAccount.isEngageVoice) {
                    this.isTerminatedMasterAcc = true;
                }
            }
        });
        CL.app.rx.settings.subscribe(settings => {
            this.noQuoteForThisLead = !settings.featuresEnabled.createNewQuote;
            this.isSelectPackagesByBusinessIdentity = settings.featuresEnabled.isSelectPackagesByBusinessIdentity;
        });
        CL.app.rx.isTryingToConnectWithNgbs.subscribe(isTryingToConnectWithNgbs => {
            this.showIsConnectingWithNgbsError = isTryingToConnectWithNgbs;
        });
        CL.app.rx.defaultAreaCode.subscribe((value) => {
            this.selectedAreaCode = value && value.areaCode ? value : null;
        });
        CL.app.rx.defaultAreaCodeRequired.subscribe((value) => {
            this.selectedAreaCodeRequired = value && !this.noQuoteForThisLead && !(this.noQuoteForThisFilters || this.noQuoteForThisFiltersNGBS);
        });
        CL.app.serviceSelector.rx.isLegacy.subscribe(isLegacy => {
            this.isLegacy = isLegacy;
        });
        CL.app.rx.notifications.subscribe(notifications => {
            this.notifications = notifications.opportunityInfo;
        });
    }

    setOpportunityCreationOption(creationOption) {
        this.doNotCreateOpp = false;
        this.createNewOpp = false;
        this.selectExistingOpp = false;
        creationOption  == 'doNotCreateOpp'? this.doNotCreateOpp = true
                            : creationOption == 'createNewOpp' ? this.createNewOpp = true
                            : this.selectExistingOpp = true;
        this.selectExistingOpp ? (this.isExpanded = true, this.notIsExpanded = false)
                      : (this.isExpanded = false, this.notIsExpanded = true);
        this.value = creationOption;
        CL.app.setOpportunityOption(creationOption);
        CL.app.setIsCreateNewOpportunity(this.createNewOpp);
        this.isExpanded ? window.dispatchEvent(new CustomEvent('onContactOpportunityEdited'))
                        : window.dispatchEvent(new CustomEvent('onContactOpportunityApplied'));
        window.dispatchEvent(new CustomEvent('onRadioGroupChangeToNoOppCreated', { detail: !this.doNotCreateOpp }));
    }

    get isCloseDateEmpty() {
        return (this.createNewOpp || this.selectExistingOpp && !this.accountHasOpportunities)
            && !this.doNotCreateOpp
            && !this.selectedCloseDate && this.isExpanded;
    }

    get isCloseDateIsInPast() {
        return this.selectedCloseDate < this.today;
    }

    get today() {
        return CL.app.serviceSelector.today;
    }

    toggleIsExpanded() {
        if (this.isCloseDateEmpty || this.isCloseDateIsInPast) {
          return window.dispatchEvent(new CustomEvent('onCloseDateInvalid'));
        }
        this.isExpanded && this.selectExistingOpp ? this.validateOpportunityHasBeenSelected() : this.toggleView();
        this.toggleOpportunityHasApplied(!this.isExpanded);
    }

    validateOpportunityHasBeenSelected() {
        this.matchedOpportunities.length && !this.selectedOpportunity ? showToast({title: this.label.NoOpportunitywasSelected,
                                                                            message: this.label.PleaseselectanOpportunityfromthelist,
                                                                            type: 'error',
                                                                            duration: 5000})
                                                               : this.toggleView();

    }

    toggleOpportunityHasApplied(hasApplied){
        CL.app.opportunityHasApplied = hasApplied;
        this.selectedMatchedAccount && this.isLeadRecordTypeSales && CL.app.contactHasApplied && CL.app.opportunityHasApplied && CL.app.opportunityCreationOption != 'doNotCreateOpp' ?
                            window.dispatchEvent(new CustomEvent('onContactOpportunityApplied'))
                            : window.dispatchEvent(new CustomEvent('onContactOpportunityEdited'));

    }

    toggleView() {
        this.isExpanded = !this.isExpanded;
        this.notIsExpanded = !this.notIsExpanded;
    }

    onOpportunityNameChange(event) {
        CL.app.setOpportunityName(event.target.value);
    }

    onCountryChange(event) {
        if(this.isCountryPicklistShown) {
            CL.app.serviceSelector.setCountry(event.detail.target.value);
            CL.app.updateCountry(event.detail.target.value);
        }
    }

    handleOppCreation(event) {
        this.setOpportunityCreationOption(event.detail.value);
        let showOpportunityContactRoleSection = true;
        this.doNotCreateOpp ? showOpportunityContactRoleSection = false
                            : true;
        if (event.detail.value != 'selectExistingOpp') {
            CL.app.selectMatchedOpportunity(null);
            this.selectedOpportunity = CL.app.selectedOpportunity;
        }
    }

    loadOpportunityComponent() {
        !this.isTerminated && CL.app.setLoadingStatus({isOpportunitiesLoading: true});

        this.setOpportunityCreationOption(this.isTerminated ? 'doNotCreateOpp' : 'selectExistingOpp');
        this.accountHasAppliedChanges = true;
        if (this.isTerminated) {
            return;
        }
        this.hasMoreOpportunitiesDisabled = true;
        getOpportunities(CL.app.rx.selectedAccount._value.id, 0)
                .then(r => {
                    CL.app.setLoadingStatus({isOpportunitiesLoading: false});
                    CL.app.setHasMoreOpportunities(r.data.hasMoreOpportunities);
                    CL.app.setMatchedOpportunities(r.data.opportunities, false);
                    this.hasMoreOpportunities = CL.app.hasMoreOpportunities;
                    this.matchedOpportunities = CL.app.matchedOpportunities;
                    this.matchedOpportunities.length ? (this.accountHasOpportunities = true,
                                                         CL.app.isCreateNewOpportunity = false)
                                                      : (this.accountHasOpportunities = false,
                                                         CL.app.isCreateNewOpportunity = true);
                    this.hasMoreOpportunitiesDisabled = false;
                    this.selectedMatchedAccount = CL.app.rx.selectedAccount._value;

                    if (this.accountHasOpportunities) {
                        this.isExpanded = true;
                        this.notIsExpanded = false;
                    } else {
                        this.isExpanded = false;
                        this.notIsExpanded = true;
                    }

                    if (this.matchedOpportunities.length == 1) {
                        CL.app.selectMatchedOpportunity(r.data.opportunities[0].Id);
                        this.selectedOpportunity = CL.app.selectedOpportunity;
                        this.tableTitle = this.label.OnlyOneOpportunitywasfound;
                        this.toggleIsExpanded();
                    } else {
                        this.tableTitle = this.label.Choosefrommatchedopportunities;
                    }
                    this.toggleOpportunityHasApplied(this.notIsExpanded);
                })
                .catch(handleError)
        window.addEventListener('onEditIsOkay', this.toggleViewOfOpportunityComponent.bind(this));
    }

    toggleViewOfOpportunityComponent(){
        this.accountHasAppliedChanges = false;
    }


    loadMoreOpportunities() {
        CL.app.setLoadingStatus({isOpportunitiesLoading: true});
        this.hasMoreOpportunitiesDisabled = true;
        this.accountHasAppliedChanges = true;
        getOpportunities(CL.app.rx.selectedAccount._value.id, this.matchedOpportunities.length)
                .then(r => {
                    CL.app.setLoadingStatus({isOpportunitiesLoading: false});
                    CL.app.setHasMoreOpportunities(r.data.hasMoreOpportunities);
                    CL.app.setMatchedOpportunities(r.data.opportunities, true);
                    this.hasMoreOpportunities = CL.app.hasMoreOpportunities;
                    this.matchedOpportunities = CL.app.matchedOpportunities;
                    this.hasMoreOpportunitiesDisabled = false;
                })
                .catch(handleError)
    }

    onMatchedOpportunitySelected(event) {
        CL.app.selectMatchedOpportunity(event.target.value);
        this.selectedOpportunity = CL.app.selectedOpportunity;
    }

    onModalOk() {
        window.addEventListener('onCreateNewAcc', function(){
            this.accountHasAppliedChanges = false;
        });

    }

    get isTerminated() {
        return this.isTerminatedAcc || this.isTerminatedMasterAcc;
    }

    get formattedCloseDate() {
        // Original date in the format YYYY-MM-DD
        // Rearrange data into MM/DD/YYYY format
        const dateParts = this.selectedCloseDate?.split("-");
        return dateParts?.length === 3
          ? `${dateParts[1]}/${dateParts[2]}/${dateParts[0]}`
          : '--None--';
    }

    get isCountryPicklistShown() {
        return this.isSelectPackagesByBusinessIdentity
                && CL.app.isEnableBIMapping
                && CL.app.isCreateNewAccount
                && !CL.app.isExistingBusiness;
    }
}