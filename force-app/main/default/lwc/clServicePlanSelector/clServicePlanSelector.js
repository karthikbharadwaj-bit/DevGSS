/* globals CL */
import { LightningElement, track, api } from 'lwc';
import { clAppReady, showToast } from 'c/clService';
import Selectserviceplan from '@salesforce/label/c.clServicePlanSelectorSelectserviceplan';
import BillingSystem from '@salesforce/label/c.clServicePlanSelectorBillingSystem';
import Legacy from '@salesforce/label/c.clServicePlanSelectorLegacy';
import NGBS from '@salesforce/label/c.clServicePlanSelectorNGBS';
import CloseDateIsRequired from '@salesforce/label/c.clCloseDateIsRequired';
import CloseDateCannotBeInThePast from '@salesforce/label/c.clCloseDateCannotBeInThePast';
import NumberofExistingUsers from '@salesforce/label/c.clServicePlanSelectorNumberofExistingUsers';
import Thisbrandcancausesomeerrors from '@salesforce/label/c.clServicePlanSelectorThisbrandcancausesomeerrors';
import LeadwillbeconvertedintoLegacyBillingSystem from '@salesforce/label/c.clServicePlanSelectorLeadwillbeconvertedintoLegacyBillingSystem';

export default class clServicePlanSelector extends LightningElement {
    @track isLoading = true;
    @track isLegacy;
    @track brandFilter;
    @track brandFilterOptions = [];
    @track businessIdentityFilter;
    @track businessIdentityOptions = [];
    @track isBusinessIdentityDisabled = false;
    @track currencyFilter;
    @track currencyOptions = [];
    @track isCurrencyDisabled = false;
    @track isBrandFilterDisabled = false;
    @track serviceFilter;
    @track serviceFilterOptions = [];
    @track isServiceFilterDisabled = true;
    @track label = {
        Selectserviceplan,
        BillingSystem,
        Legacy,
        NGBS,
        NumberofExistingUsers,
        Thisbrandcancausesomeerrors,
        CloseDateIsRequired,
        CloseDateCannotBeInThePast,
        LeadwillbeconvertedintoLegacyBillingSystem
    }

    get isServiceFilterShown() {
        return CL.app.serviceSelector.isServiceFilterShown;
    };

    @track editionFilter;
    @track editionFilterOptions = [];
    @track isEditionFilterDisabled = true;
    get isEditionFilterShown() {
        return (this.isLegacy || this.isSelectPackagesByBusinessIdentity) && !this.isUpsell && !this.noQuote;
    };

    @track chargeTermFilter;
    @track chargeTermFilterOptions = [];
    @track isChargeTermFilterDisabled = true;

    get isChargeTermFilterShown () {
        return this.isLegacy && !this.isUpsell && !this.noQuote;
    };

    get isNumberOfExistingUsersShown() {
        return this.account && this.account.isExistingBusiness;
    }

    @track type;
    @track typeOptions = [];
    @track isTypeFilterDisabled = false;

    get isTypeDisabled() {
        return this.isPreselectLoading || this.isTypeFilterDisabled;
    }

    get noQuote() {
        return this.noQuoteForThisFilters || this.noQuoteForThisLead;
    }

    @track forecastedUsersFilter = 1;
    @track forecastedCCUsersFilter = 1;
    @track forecastedDigitalUsers = 1;
    @track forecastedVoiceUsers = 1;
    @track forecastedGlobalUsers = 0;
    @track forecastedRCVideoUsers = 1;
    @track forecastedEventUsers = 1;
    closeDate;
    initialLeadValuesLoaded = false;

    @api isShown;
    @track selectedAccount;

    @track isPreselectLoading;
    @track noQuoteForThisLead = false;
    @track noQuoteForThisFilters = false;
    @track noQuoteForThisFiltersNGBS = false;
    @track noQuoteForThisBrand = false;

    @track account;

    @track isSelectPackagesByBusinessIdentity = false;

    @track leadHasBOBorWholesaleAccount = false;

    @track isRequiredOffice = false;
    @track isRequiredCC = false;
    @track isRequiredEV = false;
    @track isRequiredED = false;

    @api isPrmFlow = false;

    get isUpsell() {
        return this.type === 'Upsell';
    }

    get isTelus() {
        return CL.app.serviceSelector.filters.brand.value === 'TELUS Business Connect';
    }

    get showServicePlanSelector() {
        return this.isShown && !this.noQuoteForThisFilters;
    }

    get showServicePlanSelectorNBGS() {
        return this.isShown && !this.noQuoteForThisFiltersNGBS;
    }

    get classPlanSelector() {
        return `slds-is-relative ${this.noQuoteForThisLead ? 'slds-hide' : ''}`;
    }

    get showNoQuoteMessage() {
        return this.isShown && this.isLegacy ? this.noQuoteForThisFilters : this.noQuoteForThisFiltersNGBS;
    }

    get noQuoteMessage() {
        return CL && CL.app && CL.app.serviceSelector.DO_NOT_CREATE_MESSAGE || '';
    }

    get isUpgrade() {
        return this.type === 'Upgrade';
    };

    get isBillOnBehalfAccount() {
        return CL.app.selectedAccount && CL.app.selectedAccount.isBillOnBehalf;
    }

     get isWholesaleAccount() {
        return CL.app.selectedAccount && CL.app.selectedAccount.isWholesale;
    }

    get isBOBorWholesaleAccount() {
        return this.isBillOnBehalfAccount || this.isWholesaleAccount;
    }

    selectedService = {};
    accountPackage = {};
    phoenixSettings = {};
    @track forecastedUsersLabel = '';

    setForecastedUsersLabel() {
        this.forecastedUsersLabel = this.serviceFilter && this.serviceFilter.toLowerCase().includes('fax')
            ? 'Forecasted Fax Users'
            : 'Forecasted Office Users';
    }

    changesForUpgrade() {
        if (this.selectedService && this.accountPackage
            && this.isPhoenix(
                this.selectedService.brandName && this.selectedService.brandName.toLowerCase(),
                this.accountPackage.product && this.accountPackage.product.toLowerCase(),
                this.accountPackage.catalogId && this.accountPackage.catalogId.toLowerCase(),
            )
            && this.isUpgrade
        ) {
            this.isServiceFilterDisabled = false;
        }
    };


    isPhoenix(brand, productName, packageId) {
        return this.selectedService
            && (this.phoenixSettings.NGBSPhoenixAvailableBrands__c || '').toLowerCase().split(';').map(x => x.trim())
                .includes(brand)
            && (this.phoenixSettings.NGBSPhoenixAvailableProducts__c || '').toLowerCase().split(';').map(x => x.trim())
                .includes(productName)
            && (this.phoenixSettings.NGBSPhoenixAvailablePackageIDs__c || '').toLowerCase().split(';').map(x => x.trim())
                .includes(packageId);
    }

    get selectedPackageIsPhoenix() {
        return this.selectedService
            && this.isPhoenix(
                this.selectedService.brandName && this.selectedService.brandName.toLowerCase(),
                this.selectedService.service && this.selectedService.service.toLowerCase(),
                this.selectedService.packageId && this.selectedService.packageId.toLowerCase(),
            );
    }

    availableServiceOptions = [];

    setServiceOptionsWithAvailableOptions() {

        if (this.availableServiceOptions?.length) {
            this.serviceFilterOptions = this.isSelectPackagesByBusinessIdentity && !this.isLegacy
                ? this.availableServiceOptions
                : this.serviceFilterOptions.filter(x => this.availableServiceOptions.includes(x) && x)

            this.isServiceFilterDisabled = this.serviceFilterOptions.length <= 1;
        }
        if (this.isBOBorWholesaleAccount || this.leadHasBOBorWholesaleAccount) {
            this.filterOptionsForBoBorWholesaleAccount();
        }
    }

    connectedCallback() {
        clAppReady(this.onClAppReady.bind(this));
        if (this.isBOBorWholesaleAccount || this.leadHasBOBorWholesaleAccount) {
           this.filterOptionsForBoBorWholesaleAccount();
        }

        window.addEventListener('onCloseDateInvalid', this.doValidation.bind(this));
    }

    doValidation() {
        this.template.querySelector('[data-id="closeDate"]').reportValidity();
    }

    onClAppReady() {
        CL.app.rx.targetAccount.subscribe(() => {
            if (!CL.app.isCreateNewAccount && CL.app.selectedAccount) {
                this.selectedAccount = CL.app.selectedAccount.record;
            }
        });
        if (CL.app.lead) {
            this.leadHasBOBorWholesaleAccount = CL.app.lead.hasBOBorWholesaleAccount;
        }
        CL.app.rx.lead
        this.brandFilterOptions = CL.app.serviceSelector.filters.brand.options;

        CL.app.serviceSelector.rx.filters.subscribe(filters => {
            this.brandFilter = filters.brand.value;
            this.brandFilterOptions = filters.brand.options;
            this.isBrandFilterDisabled = filters.brand.disabled;

            this.type = filters.type.value;
            this.typeOptions = filters.type.options;
            this.isTypeFilterDisabled = filters.type.disabled;

            this.businessIdentityFilter = filters.businessIdentity.value;
            this.businessIdentityOptions = filters.businessIdentity.options;

            this.isBusinessIdentityDisabled = this.isBOBorWholesaleAccount || this.leadHasBOBorWholesaleAccount || filters.businessIdentity.disabled;

            this.currencyFilter = filters.currency.value;
            this.currencyOptions = filters.currency.options;
            this.isCurrencyDisabled = filters.currency.disabled;

            this.serviceFilter = filters.service.value;
            this.serviceFilterOptions = filters.service.options;
            this.isServiceFilterDisabled = filters.service.disabled;

            if(filters.closeDate.value != null){
                this.closeDate = filters.closeDate.value;
            }
            else if(CL.app.serviceSelector.lead.record && CL.app.serviceSelector.lead.record.Estimated_Close_Date__c != null){
                this.closeDate = CL.app.serviceSelector.lead.record.Estimated_Close_Date__c;
            }

            this.displayRelevantForecastFields();
            this.setRequiredForecastedUsers();
            this.forecastedUsersFilter = filters.lines.value >= (this.showOfficeForecast ? 1 : 0)
              ? filters.lines.value
              : (filters.lines.active && this.isRequiredOffice ? 1 : 0);
            this.forecastedDigitalUsers = filters.forecastedDigitalUsers.value >= (this.showDigitalForecast ? 1 : 0)
              ? filters.forecastedDigitalUsers.value
              : (filters.forecastedDigitalUsers.active && this.isRequiredED ? 1 : 0);
            this.forecastedVoiceUsers = filters.forecastedVoiceUsers.value >= (this.showVoiceForecast ? 1 : 0)
              ? filters.forecastedVoiceUsers.value
              : (filters.forecastedVoiceUsers.active && this.isRequiredEV ? 1 : 0);
            this.forecastedCCUsersFilter = filters.ccLines.value >= (this.showCCForecast ? 1 : 0)
              ? filters.ccLines.value
              : (filters.ccLines.active && this.isRequiredCC ? 1 : 0);
            this.forecastedEventUsers = filters.forecastedEventUsers.value >= (this.showEventForecast ? 1 : 0) 
              ? filters.forecastedEventUsers.value: (filters.forecastedEventUsers.active && !filters.lines.active? 1 : 0);
            CL.app.serviceSelector.setLineByName('lines', this.forecastedUsersFilter);
            CL.app.serviceSelector.setLineByName('forecastedDigitalUsers', this.forecastedDigitalUsers);
            CL.app.serviceSelector.setLineByName('forecastedVoiceUsers', this.forecastedVoiceUsers);
            CL.app.serviceSelector.setLineByName('ccLines', this.forecastedCCUsersFilter);

            if (!this.initialLeadValuesLoaded && CL.app.serviceSelector.lead && CL.app.serviceSelector.lead.record) {
                const lead = CL.app.lead;
                this.initialLeadValuesLoaded = true;

                this.forecastedUsersFilter = lead.forecastedOfficeUsers
                  ? lead.forecastedOfficeUsers
                  : this.showOfficeForecast ? filters.lines.value : 0;

                this.forecastedDigitalUsers = lead.forecastedEngageDigitalUsers
                  ? lead.forecastedEngageDigitalUsers
                  : this.showDigitalForecast ? filters.forecastedDigitalUsers.value : 0;

                this.forecastedVoiceUsers = lead.forecastedEngageVoiceUsers
                  ? lead.forecastedEngageVoiceUsers
                  : this.showVoiceForecast ? filters.forecastedVoiceUsers.value : 0;

                this.setForecastedContactCenterUsers();
                this.forecastedGlobalUsers = lead.forecastedGlobalOfficeUsers;
                if (!this.account || !this.account?.isExistingBusiness) {
                    this.forecastedRCVideoUsers = lead.forecastedRingcentralVideoUsers > 0 ? lead.forecastedRingcentralVideoUsers : 1;
                } else {
                    this.forecastedRCVideoUsers = lead.forecastedRingcentralVideoUsers;
                }
                
                if (lead.forecastedEventUsers !== undefined && lead.forecastedEventUsers !== null) {
                    this.forecastedEventUsers = lead.forecastedEventUsers;
                } else {
                    const eventService = 'events';
                    this.forecastedEventUsers = this.serviceFilter?.toLowerCase() === eventService ? 1 : 0;
                }
                CL.app.serviceSelector.setLineByName('lines', this.forecastedUsersFilter);
                CL.app.serviceSelector.setLineByName('ccLines', this.forecastedCCUsersFilter);
                CL.app.serviceSelector.setLineByName('forecastedDigitalUsers', this.forecastedDigitalUsers);
                CL.app.serviceSelector.setLineByName('forecastedVoiceUsers', this.forecastedVoiceUsers);
                CL.app.serviceSelector.setLineByName('forecastedGlobalUsers', this.forecastedGlobalUsers);
                CL.app.serviceSelector.setLineByName('forecastedRCVideoUsers', this.forecastedRCVideoUsers);
                CL.app.serviceSelector.setCloseDate(this.closeDate);
            }

            this.editionFilter = filters.edition.value;
            this.editionFilterOptions = filters.edition.options;
            this.isEditionFilterDisabled = filters.edition.disabled;

            this.chargeTermFilter = filters.chargeTerm.value;
            this.chargeTermFilterOptions = filters.chargeTerm.options;
            this.isChargeTermFilterDisabled = filters.chargeTerm.disabled;

            this.setServiceOptionsWithAvailableOptions();

            this.noQuoteForThisFilters = CL.app.serviceSelector.noQuoteForThisFilters;
            this.noQuoteForThisFiltersNGBS = CL.app.serviceSelector.noQuoteForThisFiltersNGBS;
            this.noQuoteForThisBrand = CL.app.serviceSelector.noQuoteForThisBrand;

            this.changesForUpgrade();
            
        });

        CL.app.serviceSelector.rx.isLegacy.subscribe(isLegacy => {
            this.isLegacy = isLegacy;
        });
        CL.app.rx.loadingStatus.subscribe(loadingStatus => {
            this.isPreselectLoading = loadingStatus.isEntitlementsLoading || loadingStatus.isNgbsAccountLoading || loadingStatus.isPackageSearching;
        });
        CL.app.rx.selectedAccount.subscribe(account => {
            this.account = account;
            this.isTrialPackage = false;

            this.changesForUpgrade();
        });
        CL.app.rx.settings.subscribe(settings => {
            this.noQuoteForThisLead = !settings.featuresEnabled.createNewQuote;
            this.featuresEnabledForecastedUsers = settings.featuresEnabled.ccForecastedUsers;
            this.isSelectPackagesByBusinessIdentity = settings.featuresEnabled.isSelectPackagesByBusinessIdentity;

            this.phoenixSettings = settings.phoenixSettings;
            this.setForecastedUsersLabel();

            if (Object.entries(settings.featuresEnabled).length !== 0) {
                this.isLoading = false;
            }
        });
        CL.rxjs.combineLatest(
            CL.app.rx.settings,
            CL.app.serviceSelector.rx.selectedService
        ).subscribe(() => {
            this.setForecastedUsersLabel();
            this.displayRelevantForecastFields();
            this.setRequiredForecastedUsers();
            this.changesForUpgrade();
        });

        CL.app.rx.availableServiceOptions.subscribe(availableServiceOptions => {
            this.availableServiceOptions = availableServiceOptions;
            this.setServiceOptionsWithAvailableOptions();
        });

        CL.app.serviceSelector.ngbsServiceSelector.rx.accountPackage.subscribe(accountPackage => {
            this.accountPackage = accountPackage;
        });

        CL.app.rx.availableEditionOptions.subscribe(() => {
            this.setServiceOptionsWithAvailableOptions();
        });

        CL.app.rx.isCreateNewAccount.subscribe(() => {
            let officeOption = CL.app.serviceSelector.filters.service.options.find(option => option === 'Office');

            if (!officeOption && CL.app.serviceSelector.filters.service.options.length > 0) {
                officeOption = CL.app.serviceSelector.filters.service.options[0];
            }

            if (officeOption) {
                CL.app.serviceSelector.setService(officeOption);
            }
        });
    }

    @track showOfficeForecast;
    @track showCCForecast;
    @track showGlobalForecast;
    @track showVideoForecast;
    @track showVoiceForecast;
    @track showDigitalForecast;
    @track showEventForecast;

    isBusinessIdentitySingapore() {
        let bi = this.businessIdentityOptions.find(({label}) => label.toLowerCase().includes('singapore'));

        return bi && this.businessIdentityFilter === bi.value;
    }

    isPartnerBrand() {
        const brands = [
            'unify office',
            'avaya cloud office',
            'rainbow office',
            'unify office',
            'ringcentral with verizon',
            'rise america',
            'rise international'
        ];

        return brands.some(brand => this.brandFilter.toLowerCase().includes(brand))
    }

    setForecastedContactCenterUsers() {
        const lead = CL.app.lead;
        this.forecastedCCUsersFilter = lead.forecastedContactCenterUsers
            ? lead.forecastedContactCenterUsers
            : this.serviceFilter?.toLowerCase().includes('ringcentral contact center') ? 1 : 0;
    }

    displayRelevantForecastFields() {
        if (this.serviceFilter && this.brandFilter) {
            this.showOfficeForecast = CL.app.serviceSelector.isForecastFieldVisible(
              this.brandFilter,
              this.serviceFilter,
              'forecastedOfficeUsers',
              this.availableServiceOptions,
            );
            this.showCCForecast = CL.app.serviceSelector.isForecastFieldVisible(
              this.brandFilter,
              this.serviceFilter,
              'forecastedContactCenterUsers',
              this.availableServiceOptions,
            );
            this.showGlobalForecast = CL.app.serviceSelector.isForecastFieldVisible(
              this.brandFilter,
              this.serviceFilter,
              'forecastedGlobalOfficeUsers',
              this.availableServiceOptions
            );
            this.showVideoForecast = CL.app.serviceSelector.isForecastFieldVisible(
              this.brandFilter,
              this.serviceFilter,
              'forecastedRingcentralVideoUsers',
              this.availableServiceOptions,
            );
            this.showVoiceForecast = CL.app.serviceSelector.isForecastFieldVisible(
              this.brandFilter,
              this.serviceFilter,
              'forecastedEngageVoiceUsers',
              this.availableServiceOptions,
            );
            this.showDigitalForecast = CL.app.serviceSelector.isForecastFieldVisible(
              this.brandFilter,
              this.serviceFilter,
              'forecastedEngageDigitalUsers',
              this.availableServiceOptions,
            );
            this.showEventForecast = CL.app.serviceSelector.isForecastFieldVisible(
              this.brandFilter,
              this.serviceFilter,
              'forecastedEventUsers',
              this.availableServiceOptions,
            );
            console.log('showEventForecast='+this.showEventForecast);
            const lcService = this.serviceFilter.toLowerCase();
            const lcBrand = this.brandFilter.toLowerCase();

            if (lcService.includes('office')) {
                this.showCCForecast = (this.showCCForecast || this.account?.inContactAccountId) &&
                    !this.isPartnerBrand() &&
                    !this.isBusinessIdentitySingapore()
                    && CL.app.serviceSelector.isForecastFieldVisibleForIdentity(this.businessIdentityFilter, 'forecastedContactCenterUsers');
            }

            if (this.businessIdentityFilter) {
                if(this.serviceFilter.toLowerCase().includes('office')) {
                    this.showCCForecast &= !CL.app.serviceSelector.INDIA_BI.includes(this.businessIdentityFilter.toLowerCase()) &&
                    !CL.app.serviceSelector.TAIWAN_BI.includes(this.businessIdentityFilter.toLowerCase());
                    this.showGlobalForecast &= !CL.app.serviceSelector.INDIA_BI.includes(this.businessIdentityFilter.toLowerCase())&&
                    !CL.app.serviceSelector.TAIWAN_BI.includes(this.businessIdentityFilter.toLowerCase());
                }
            }

            CL.app.serviceSelector.setLineUsage('lines', this.showOfficeForecast && this.isRequiredOffice);
            CL.app.serviceSelector.setLineUsage('ccLines', this.showCCForecast);
            CL.app.serviceSelector.setLineUsage('forecastedGlobalUsers', this.showGlobalForecast);
            CL.app.serviceSelector.setLineUsage('forecastedRCVideoUsers', this.showVideoForecast);
            CL.app.serviceSelector.setLineUsage('forecastedVoiceUsers', this.showVoiceForecast);
            CL.app.serviceSelector.setLineUsage('forecastedDigitalUsers', this.showDigitalForecast);
            CL.app.serviceSelector.setLineUsage('forecastedEventUsers', this.showEventForecast);
        }
    }

    showBrandToastError(brand) {
        if (!(CL.app.serviceSelector.brandConfiguration
            && CL.app.serviceSelector.brandConfiguration.some( el => el.Name === brand))) {
            showToast({title: this.label.Thisbrandcancausesomeerrors, message:  this.label.LeadwillbeconvertedintoLegacyBillingSystem, type: 'warning', duration: 10000});
        }
        if (this.isBOBorWholesaleAccount || this.leadHasBOBorWholesaleAccount) {
            this.filterOptionsForBoBorWholesaleAccount();
        }
    }

    onBrandFilterChange(event) {
        CL.app.serviceSelector.setBrand(event.detail.target.value);
        this.showBrandToastError(event.detail.target.value);
    }

    onBusinessIdentityFilterChange(event) {
        this.availableServiceOptions = [];

        CL.app.serviceSelector.setBusinessIdentity(event.detail.target.value);
        CL.app.serviceSelector.setEdition('');
        this.setRequiredForecastedUsers();
        this.showBrandToastError(CL.app.serviceSelector.filters.brand.value);
    }

    onCurrencyFilterChange(event) {
        CL.app.serviceSelector.setCurrency(event.detail.target.value);
    }

    onServiceFilterChange(event) {
        CL.app.serviceSelector.setService(event.detail.target.value);
        this.serviceFilter = event.detail.target.value;
        this.displayRelevantForecastFields();

        if (this.isSelectPackagesByBusinessIdentity) {
            CL.app.serviceSelector.setEdition('');
        }

        this.setForecastedContactCenterUsers();
this.setRequiredForecastedUsers();
        if (this.isBOBorWholesaleAccount || this.leadHasBOBorWholesaleAccount) {
            this.filterOptionsForBoBorWholesaleAccount();
        }
    }

    onEditionFilterChange(event) {
        CL.app.serviceSelector.setEdition(event.detail.target.value);
    }

    onChargeTermFilterChange(event) {
        CL.app.serviceSelector.setChargeTerm(event.detail.target.value);
    }

    onForecastedUsersFilterChange(event) {
        if ((!this.account || !this.account?.isExistingBusiness) && event.target.value < 1 && this.isRequiredOffice) {
            event.target.value = 1;
        } else if (event.target.value < 0 && !this.isRequiredOffice) {
            event.target.value = 0;
        }
        if (this.isRequiredED && Number(event.target.value) < 1) {
            this.forecastedCCUsersFilter = 0;
            this.forecastedVoiceUsers = 0;
            CL.app.serviceSelector.setLineByName('ccLines', this.forecastedCCUsersFilter);
            CL.app.serviceSelector.setLineByName('forecastedVoiceUsers', this.forecastedVoiceUsers);
        }

        CL.app.serviceSelector.setLines(Number(event.target.value));
        this.forecastedUsersFilter = event.target.value;
    }

    onForecastedCCUsersFilterChange(event) {
        if((!this.account || !this.account?.isExistingBusiness) && event.target.value < 1 && this.isRequiredCC) {
            event.target.value = 1;
        } else if (event.target.value < 0 && !this.isRequiredCC) {
            event.target.value = 0;
        }
        CL.app.serviceSelector.setCCLines(Number(event.target.value));
        this.forecastedCCUsersFilter = event.target.value;
    }

    onFieldFilterChange(event) {
        switch(event.target.name) {
            case 'forecastedDigitalUsers':
                event.target.value = this.isRequiredED && event.target.value < 1
                    ? 1
                    : !this.isRequiredED && event.target.value < 0
                        ? 0
                        : event.target.value;
                this.forecastedDigitalUsers = event.target.value;
            break;
            case 'forecastedVoiceUsers':
                event.target.value = this.isRequiredEV && event.target.value < 1
                    ? 1
                    : !this.isRequiredEV && event.target.value < 0
                        ? 0
                        : event.target.value;
                this.forecastedVoiceUsers = event.target.value;
            break;
            case 'forecastedGlobalUsers':
                if((!this.account || !this.account?.isExistingBusiness) && event.target.value < 0) {
                    event.target.value = 0;
                }
                this.forecastedGlobalUsers = event.target.value;
            break;
            case 'forecastedRCVideoUsers':
                if((!this.account || !this.account?.isExistingBusiness) && event.target.value < 1) {
                    event.target.value = 1;
                }
                this.forecastedRCVideoUsers = event.target.value;
            break;
            case 'forecastedEventUsers':
                if((!this.account || !this.account?.isExistingBusiness) && event.target.value < 1) {
                    event.target.value = 1;
                }
                this.forecastedEventUsers = event.target.value;
            break;
        }
        CL.app.serviceSelector.setLineByName(event.target.name, Number(event.target.value));
    }

    onCloseDateChanged(event) {
        this.closeDate = event.target.value;
        CL.app.serviceSelector.setCloseDate(this.closeDate);
    }

    onTypeChange(event) {
        if (this.isSelectPackagesByBusinessIdentity) {
            CL.app.serviceSelector.setEdition('');
        }

        CL.app.serviceSelector.setType(event.detail.target.value);
        this.type = event.detail.target.value;
        this.setServiceOptionsWithAvailableOptions();
        this.displayRelevantForecastFields();
        this.changesForUpgrade();
    }

    filterOptionsForBoBorWholesaleAccount() {
        let index = 0;
        while (index < this.serviceFilterOptions.length) {
            if (this.serviceFilterOptions[index] === CL.app.serviceSelector.faxProductName ||
                this.serviceFilterOptions[index] === CL.app.serviceSelector.rcMeetingsProductName)
            {
                this.serviceFilterOptions.splice(index, 1);
            } else {
                index++;
            }
        }
    }

    setRequiredForecastedUsers() {
        const officeService = 'office';
        const ccService = 'ringcentral contact center';
        const evService = 'engage voice standalone';
        const edService = 'engage digital standalone';
        const servicesForRequiredOffice = [officeService, ccService, evService];
        this.isRequiredOffice = servicesForRequiredOffice?.includes(this.serviceFilter?.toLowerCase());
        this.isRequiredCC = this.serviceFilter?.toLowerCase().includes(ccService);
        this.isRequiredEV = this.serviceFilter?.toLowerCase().includes(evService);
        this.isRequiredED = this.serviceFilter?.toLowerCase().includes(edService);
    }

    get isDisabledInput() {
        return this.isPreselectLoading || (this.isRequiredED && this.forecastedUsersFilter < 1);
    }

    get today() {
        return CL.app.serviceSelector.today;
    }

    displayHelpText(event) {
        var divblock = this.template.querySelector('[data-id="help"]');
        if(divblock){
            this.template.querySelector('[data-id="help"]').classList.remove('slds-fall-into-ground');
            this.template.querySelector('[data-id="help"]').classList.add('slds-rise-from-ground');
        }
    }
    displayOutHelpText(event) {
        var divblock = this.template.querySelector('[data-id="help"]');
        if(divblock){
            this.template.querySelector('[data-id="help"]').classList.remove('slds-rise-from-ground');
            this.template.querySelector('[data-id="help"]').classList.add('slds-fall-into-ground');
        }
    }
}