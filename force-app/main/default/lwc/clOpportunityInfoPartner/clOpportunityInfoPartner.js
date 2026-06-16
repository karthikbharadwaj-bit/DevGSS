/* globals CL */
import { LightningElement, track, api } from 'lwc';
import { clAppReady } from 'c/clService';

import OpportunityName from '@salesforce/label/c.clOpportunityInfoOpportunityName';
import BusinessIdentity from '@salesforce/label/c.clOpportunityInfoBusinessIdentity';
import Currency from '@salesforce/label/c.clOpportunityInfoCurrency';
import None from '@salesforce/label/c.clOpportunityInfoNone';
import Brand from '@salesforce/label/c.clOpportunityInfoBrand';
import SelectedServicePlan from '@salesforce/label/c.clOpportunityInfoSelectedServicePlan';
import BillingSystem from '@salesforce/label/c.clOpportunityInfoBillingSystem';
import Legacy from '@salesforce/label/c.clOpportunityInfoLegacy';
import NGBS from '@salesforce/label/c.clOpportunityInfoNGBS';
import CloseDateIsRequired from '@salesforce/label/c.clCloseDateIsRequired';
import SelectCloseDate from '@salesforce/label/c.clSelectCloseDate';

export default class ClOpportunityInfo extends LightningElement {
    @track isCreateNewOpportunity = true;
    @track showNewOpportunityCheckbox = false;
    @track noQuoteForThisFilters = false;
    @track noQuoteForThisLead = false;
    @track isExpanded = false;

    @track opportunityName = '';
    @track selectedServiceName;
    @track selectedServicePrice;
    @track selectedBrand;
    @track selectedBusinessIdentity;
    @track selectedCurrency;
    @track selectedServiceIsLegacy;
    @track selectedServiceChargeTerm;
    @track selectedServicePriceCurrencyCode;
    @track selectedAreaCode = '';
    @track selectedAreaCodeRequired = false;
    selectedCloseDate;

    @track isLoading;
    @track isLoaded;
    @track isPreselectLoading;
    @track isSelectPackagesByBusinessIdentity;

    @track isLegacy;

    @track showOpportunitySection = false;

    @track showIsServicePlanMissingError = false;
    @track showIsOpportunityNameMissingError = false;
    @track showIsNgbsChargeTermMissingError = false;
    @track showIsNgbsDefaultAreaCodeMissingError = false;
    isCloseDateMissing;

    @track showNoOpportunityNewAccountMessage = false;
    @track showNoOpportunityExistingAccountMessage = false;

    @track label = {
        OpportunityName,
        BusinessIdentity,
        Currency,
        None,
        Brand,
        SelectedServicePlan,
        BillingSystem,
        Legacy,
        CloseDateIsRequired,
        SelectCloseDate,
        NGBS
    };

    @api
    isPrmFlow = false;

    get isNotLoaded() {
        return !this.isLoaded;
    }

    get isExpandedView() {
        return this.isExpanded && this.isLoaded;
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
            this.showNewOpportunityCheckbox ?
                'slds-m-top_none' :
                'slds-m-top_medium',
            this.isOpportunityInfoHasErrors && 'card_has-errors'
        ].filter(Boolean).join(' ');
    }

    get showSelectedServicePlan() {
        return !this.noQuoteForThisFilters && !this.noQuoteForThisLead;
    }

    connectedCallback() {
        clAppReady(this.onClAppReady.bind(this));
        window.addEventListener('onCreateNewAcc', this.showOpportunity.bind(this));
        window.addEventListener('onSelectExistingAccountForOpportunity', this.showOpportunity.bind(this));
        window.addEventListener('onEditIsOkay', this.hideOpportunity.bind(this));
        window.addEventListener('onCancel', this.showOpportunity.bind(this));
    }

    onClAppReady() {
        CL.app.rx.settings.subscribe(settings => {
            this.showNewOpportunityCheckbox = settings.featuresEnabled.createNewOpportunityOptional;
            this.noQuoteForThisLead = !settings.featuresEnabled.createNewQuote;
            this.isSelectPackagesByBusinessIdentity = settings.featuresEnabled.isSelectPackagesByBusinessIdentity;
        });
        CL.app.rx.isCreateNewOpportunity.subscribe(isCreateNewOpportunity => {
            this.isCreateNewOpportunity = isCreateNewOpportunity;
            if (!this.isCreateNewOpportunity) {
                this.isExpanded = false;
            }
        });
        CL.app.rx.opportunityName.subscribe(opportunityName => {
            this.opportunityName = opportunityName;
        });
        CL.app.serviceSelector.rx.filters.subscribe(filters => {
            this.selectedBrand = filters.brand.value;
            this.selectedBusinessIdentity = CL.app.serviceSelector.getBusinessIdentityLabel(filters.businessIdentity.value);
            this.selectedCurrency = filters.currency.value;
            this.noQuoteForThisFilters = CL.app.serviceSelector.noQuoteForThisFilters;
            this.selectedCloseDate = filters.closeDate.value;
        });
        CL.app.serviceSelector.rx.isLegacy.subscribe(isLegacy => {
            this.selectedServiceIsLegacy = isLegacy;
        });
        CL.app.serviceSelector.rx.selectedService.subscribe(selectedService => {
            this.selectedServiceName = selectedService && selectedService.name || '--None--';
            this.selectedServicePrice = selectedService && selectedService.price;
            this.selectedServiceId = selectedService && selectedService.id;
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
        });

        CL.app.rx.defaultAreaCode.subscribe((value) => {
            this.selectedAreaCode = value && value.areaCode ? value : null;
        });

        CL.app.rx.defaultAreaCodeRequired.subscribe((value) => {
            this.selectedAreaCodeRequired = value;
        });
        CL.app.serviceSelector.rx.isLegacy.subscribe(isLegacy => {
            this.isLegacy = isLegacy;
        });
    }

    onIsCreateNewOpportunityChange(event) {
        CL.app.setIsCreateNewOpportunity(event.target.checked);
    }

    get isCloseDateEmpty() {
        return this.isCreateNewOpportunity && !this.selectedCloseDate && this.isExpanded;
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
        this.isExpanded = !this.isExpanded;
    }

    onOpportunityNameChange(event) {
        CL.app.setOpportunityName(event.target.value);
    }

    showOpportunity() {
        this.showOpportunitySection = true;
    }

    hideOpportunity() {
        this.showOpportunitySection = false;
    }

    get formattedCloseDate() {
        // Original date in the format YYYY-MM-DD
        // Rearrange data into MM/DD/YYYY format

        const dateParts = this.selectedCloseDate?.split("-");
        return dateParts?.length === 3
          ? `${dateParts[1]}/${dateParts[2]}/${dateParts[0]}`
          : '--None--';
    }
}