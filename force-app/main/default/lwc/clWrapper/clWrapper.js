/* globals CL */
import {LightningElement, track, api} from "lwc";
import {
    getDataWave1,
    getDataWave2,
    convertLead,
    clAppReady,
    handleError,
    showSpinner,
    hideSpinner,
    hasSomeApprovals,
    rejectSomeTaxExemptionApprovals,
    checkAvailableVATNumber,
    getCountriesForSalesLead,
    getDataForSalesLead,
    getDataForSelectedAccount,
} from "c/clService";
import BaseService from "c/lwcBaseService";
import Preparing from '@salesforce/label/c.clWrapperPreparing';
import LeadSuccessfullyConverted from '@salesforce/label/c.clWrapperLeadSuccessfullyConverted';
import Redirecting from '@salesforce/label/c.clWrapperRedirecting';

export default class ClWrapper extends LightningElement {
    @track isLeadConverting = false;
    @track showConversionInfo = false;
    @track showConvertedLeadInfo = false;
    @track accUrl;
    @track conUrl;
    @track oppUrl;
    @api isLeadRecordTypeSales = false;
    @track label = {
        Preparing,
        LeadSuccessfullyConverted,
        Redirecting
    }

    brandFilter = null;
    packageId = null;

    @track businessIdentityOptions = [];
    @track leadHasBOBorWholesaleAccount = false;
    @track leadBusinessIdentity;
    @api isPrmFlow;
    isDataWaveLoaded = false;

    connectedCallback() {
        clAppReady(this.onClAppReady.bind(this));
        new Promise(resolve => setTimeout(() => resolve(), 1000))
            .then(() => this.createApp());
    }

    createApp() {
        CL.app = new CL.classes.App();
        CL.app.setPRMFlow(this.isPrmFlow);
        CL.app.setLeadId(new URL(window.location).searchParams.get("id"));
        window.dispatchEvent(new CustomEvent('clAppInit'));

        CL.app.serviceSelector.rx.filters.subscribe(filters => {
            this.brandFilter = filters.brand.value;
        });

        CL.app.serviceSelector.rx.selectedService.subscribe(selectedService => {
            this.packageId = selectedService && selectedService.packageId;
        });
    }

    onClAppReady() {
        const getDataWave1Process = new Promise((resolve, reject) => {
            this.getDataWave1()
                .then(() => resolve())
                .catch(() => reject());
        });

        CL.app.serviceSelector.rx.filters.subscribe(filters => {
            this.businessIdentityOptions = filters.businessIdentity.options;
        });

        this.getDataWave2(getDataWave1Process);
        CL.app.rx.loadingStatus.subscribe(loadingStatus => {
            this.isLeadConverting = loadingStatus.isLeadConverting;
        });

        CL.app.rx.settings.subscribe(settings => {
            this.showConversionInfo = settings.featuresEnabled.leadQualification && !isPrmFlow;
        });

        CL.app.rx.selectedAccount.subscribe(selectedAccount  => {
            if ((selectedAccount?.isWholesale || selectedAccount?.isBillOnBehalf) && selectedAccount?.businessIdentity) {
                this.setBusinessIdentity(selectedAccount.businessIdentity);
            }
            checkAvailableVATNumber(selectedAccount && selectedAccount.id, CL.app.leadId)
                .then(res => {
                    if (res && res.messages[0] && res.messages[0].message) {
                        window.dispatchEvent(new CustomEvent('ShowToastEvent', {
                            detail: {
                                title: 'VAT Number warning',
                                message: res.messages[0] && res.messages[0].message,
                                type: 'warning',
                                duration: 15000,
                            },
                        }));
                    }
                });
            if (CL.app.settings.featureToggle.EnableBusinessIdentityMapping__c
                && CL.app.lead.recordType === 'Sales Leads'
                && Boolean(selectedAccount)
            ) {
                getDataForSelectedAccount(CL.app.leadId, selectedAccount?.id)
                    .then(res => {
                        this.setBrandAndBIData(res);
                    });
            }
        });

        CL.app.rx.country.subscribe((country) => {
            if(CL.app.lead) {
                getDataForSalesLead(CL.app.leadId, country, CL.app.lead?.record?.Lead_Brand_Name__c)
                    .then(r => {
                        this.setBrandAndBIData(r);
                    });
            }
        });

        CL.app.rx.isCreateNewAccount.subscribe(isCreateNewAccount => {
            if(
                CL.app.settings.featureToggle.EnableBusinessIdentityMapping__c
                && this.isLeadRecordTypeSales
                && isCreateNewAccount
                && !CL.app.lead.record.Account__r?.Billing_ID__c
            ) {
                getCountriesForSalesLead(CL.app.lead.country)
                    .then(r => {
                        CL.app.setCountries(JSON.parse(r.data.countries).sort());
                        CL.app.serviceSelector.setCountry(r.data.country);
                        CL.app.updateCountry(r.data.country);
                    })
            }
        });
    }

    getDataWave1() {
        CL.app.setLoadingStatus({
            isLeadLoading: true,
            isAccountsLoading: true
        });
        return getDataWave1(CL.app.leadId)
            .then(r => {
                CL.app.setOwnerId(r.data.currentUserId);
                CL.app.setLead(r.data.lead);
                const appLead = CL.app.lead;

                if (appLead.isConverted) {
                    this.showConvertedLeadInfo = true;
                    this.accUrl = this.isPrmFlow ? window.location.host+"/RCPartnerProgram/s/partnercustomers?id=" + appLead.convertedAccountId : "/" + appLead.convertedAccountId;
                    this.conUrl = this.isPrmFlow ? window.location.host+"/RCPartnerProgram/s/partnercustomers?id=" + appLead.convertedAccountId : "/" + appLead.convertedContactId;
                    this.oppUrl = this.isPrmFlow ? window.location.host+"/RCPartnerProgram/s/partneropportunities?id=" + appLead.convertedOpportunityId : "/" + appLead.convertedOpportunityId;
                    return;
                }
                const getBrandOptions = () => {
                    let partnerBrandOptions = ['Avaya Cloud Office', 'Unify Office', 'Rainbow Office'];
                    let brandOptions = JSON.parse(r.data.brandOptionsSerialized).map(v => v.value);
                    brandOptions = Array.isArray(brandOptions) ? brandOptions : [];

                    return appLead.recordType === 'Sales Leads'
                        ? brandOptions.filter((option) =>  !partnerBrandOptions.includes(option))
                        : brandOptions;
                };
                CL.app.setHasMoreAccounts(r.data.hasMoreAccounts);
                CL.app.setMatchedAccounts(r.data.accounts);
                CL.app.setFeatureToggle(r.data.featureToggle);
                CL.app.setBillingParams({
                    origin: r.data.origin,
                    herokuEndpoint: r.data.herokuEndpoint,
                    sessionId: r.data.sessionId,
                });
                CL.app.preselectAccount();
                CL.app.setLoadingStatus({
                    isLeadLoaded: true,
                    isAccountsLoaded: true,
                    isBillingParamsLoaded: true
                });
                CL.app.serviceSelector.setUserProfileName(r.data?.userProfileName);
                CL.app.serviceSelector.setBrandConfiguration(r.data.brandConfiguration);
                CL.app.serviceSelector.setUserCustomPermissions(r.data.userCustomPermissions);
                CL.app.serviceSelector.setUserTimezoneOffset(r.data.userTimezoneOffset);
                CL.app.serviceSelector.setBrandOptions(getBrandOptions());
                CL.app.serviceSelector.setSubBrand(r.data.subBrand);
                CL.app.serviceSelector.setAvailableBusinessIdentities(JSON.parse(r.data.availableBIs));
                CL.app.serviceSelector.setBusinessIdentities(JSON.parse(r.data.businessIdentities), r.data?.defaultBI);

                if (CL.app.lead) {
                    this.leadHasBOBorWholesaleAccount = CL.app.lead.hasBOBorWholesaleAccount;
                    this.leadBusinessIdentity = CL.app.lead.businessIdentity;
                }

                CL.app.serviceSelector.setPackageLabels(JSON.parse(r.data.packageLabels));

                CL.app.serviceSelector.setServiceOptions({
                    options: JSON.parse(r.data.serviceOptionsSerialized),
                    dependencies: JSON.parse(r.data.serviceDependenciesSerialized)
                });
                this.isLeadRecordTypeSales = appLead.recordType === 'Sales Leads';
                CL.app.serviceSelector.ngbsServiceSelector.setLeadRecordTypeSales(this.isLeadRecordTypeSales);                

                try {
                    CL.app.setPhoenixSettings(JSON.parse(r.data.PhoenixSettings));
                } catch (e) {
                    console.error('Phoenix Settings is invalid::', e);
                }
                this.isDataWaveLoaded = true;
            })
            .catch(handleError)
            .then(() => {
                CL.app.setLoadingStatus({
                    isLeadLoading: false,
                    isAccountsLoading: false,
                });
            });
    }

    getDataWave2(getDataWave1Process) {
        CL.app.setLoadingStatus({
            isLegacyServicesLoading: true,
            isOpportunitiesLoading: true
        });
        Promise.all([
            getDataWave2(CL.app.leadId),
            getDataWave1Process
        ])
            .then(([r]) => {
                if (CL.app.lead.isConverted) return;
                CL.app.serviceSelector.legacyServiceSelector.setServices(r.data.legacyServices);
                CL.app.serviceSelector.setBrand(CL.app.lead.brand || 'RingCentral');

                if (this.leadBusinessIdentity && this.leadHasBOBorWholesaleAccount) {
                    this.setBusinessIdentity(this.leadBusinessIdentity);
                }

                CL.app.setHasMoreQualifications(r.data.hasMoreQualifications);
                CL.app.setLeadQualifications(r.data.leadQualifications);
                CL.app.setLoadingStatus({
                    isLegacyServicesLoaded: true,
                    isOpportunitiesLoaded: true,
                });
            })
            .catch(handleError)
            .then(() => {
                CL.app.setLoadingStatus({
                    isLegacyServicesLoading: false,
                    isOpportunitiesLoading: false
                });
            });
    }

    onSubmit(event) {
        event.preventDefault();

        const handleErrorCallback = (error) => {

            if (error && error.data &&
                error.data.AccountId &&
                error.data.ContactId &&
                error.data.OpportunityId
            ) {
                this.showConvertedLeadInfo = true;
                this.accUrl = this.isPrmFlow ? window.location.host+"/RCPartnerProgram/s/partnercustomers?id=" + error.data.AccountId : "/" + error.data.AccountId;
                this.conUrl = this.isPrmFlow ? window.location.host+"/RCPartnerProgram/s/partnercustomers?id=" + error.data.AccountId : "/" + error.data.ContactId;
                this.oppUrl = this.isPrmFlow ? window.location.host+"/RCPartnerProgram/s/partneropportunities?id=" + error.data.OpportunityId : "/" + error.data.OpportunityId;
                hideSpinner();
                return;
            } else {
                handleError(error, '', CL.app.lead);
            }

            if (CL.app.lead && CL.app.lead.isConverted) {
                this.showConvertedLeadInfo = true;
                this.accUrl = this.isPrmFlow ? window.location.host+"/RCPartnerProgram/s/partnercustomers?id="+ CL.app.lead.convertedAccountId : "/" + CL.app.lead.convertedAccountId;
                this.conUrl = this.isPrmFlow ? window.location.host+"/RCPartnerProgram/s/partnercustomers?id="+ CL.app.lead.convertedAccountId : "/" + CL.app.lead.convertedContactId;
                this.oppUrl = this.isPrmFlow ? window.location.host+"/RCPartnerProgram/s/partneropportunities?id=" + CL.app.lead.convertedOpportunityId : "/" + CL.app.lead.convertedOpportunityId;
            }

            CL.app.setLoadingStatus({
                isLeadConverting: false,
            });
            hideSpinner();
        };

        const callLeadConversion = () => {
            const convertParams = CL.app.handleConvert();
            if (convertParams) {
                showSpinner('Preparing');
                CL.app.setLoadingStatus({
                    isLeadConverting: true,
                });
                convertLead(convertParams)
                    .then(idToRedirect => {
                        window.dispatchEvent(new CustomEvent('ShowToastEvent', {
                            detail: {
                                title: this.label.LeadSuccessfullyConverted,
                                message: this.label.Redirecting,
                                type: 'success',
                                duration: 15000,
                            },
                        }));
                       if(this.isPrmFlow){
                            window.open(window.location.origin+"/RCPartnerProgram/s/partneropportunities?id="+idToRedirect, '_parent');
                        }else{
                            window.open('/' + idToRedirect, '_self');
                        }

                        showSpinner(this.label.Redirecting);
                    })
                    .catch(handleErrorCallback);
            }
        };

        const accountId = CL.app.targetAccount && CL.app.targetAccount.id;
        showSpinner('Checking Tax Exemption Approvals');
        hasSomeApprovals(accountId, this.brandFilter).then((val) => {
            hideSpinner();
            if (val && val.data && val.data.approvals) {
                BaseService.showModal('Approval will be rejected', 'ACTION REQUIRED! This account has a Tax Exemption.  The opportunity you are trying to create is being created for a different Brand or Currency than the original Tax Exemption. If you proceed, the Tax Exemption will be removed and you will have to advise the customer to re-apply for Tax Exemption.', [
                    {
                        name: 'ok',
                        label: 'Ok',
                        callback: () =>
                        {
                            showSpinner('Rejecting Tax Exemption Approvals');
                            rejectSomeTaxExemptionApprovals(accountId, this.brandFilter)
                                .then(() => {
                                    hideSpinner();
                                    callLeadConversion();
                                })
                                .catch(handleErrorCallback);
                        },
                    },
                    {
                        name: 'cancel',
                        label: 'Cancel',
                        variant: 'neutral',
                        callback: () => {
                        },
                    },
                ]);
            } else {
                callLeadConversion();
            }
        })
            .catch(handleErrorCallback);
    }

    setBusinessIdentity(value) {
        for (let option of this.businessIdentityOptions) {
            if (option.label === value) {
                this.businessIdentityFilter = option.value;
                break;
            }
        }
        CL.app.serviceSelector.setBusinessIdentity(this.businessIdentityFilter);
    }

    setBrandAndBIData(response) {
        CL.app.serviceSelector.setBrand(response.data?.brand, { setBusinessIdentity: false });
        CL.app.serviceSelector.setSubBrand(response.data?.subBrand);
        CL.app.serviceSelector.setAvailableBusinessIdentities(JSON.parse(response.data?.availableBIs));
        CL.app.serviceSelector.setBusinessIdentities(JSON.parse(response.data?.businessIdentities), response.data?.defaultBI);
    }
}