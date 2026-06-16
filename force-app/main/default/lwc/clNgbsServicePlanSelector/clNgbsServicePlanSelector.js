/* global CL */
import {LightningElement, api} from 'lwc';
import {clAppReady} from "c/clService";

export default class ClNgbsServicePlanSelector extends LightningElement {
    isRendered = false;
    isLegacy = false;
    _isShown = false;

    @api isPrmFlow = false;

    @api
    set isShown(isShown) {
        this._isShown = isShown;
        this.setBillingSelectorIsShown();
    }

    get isShown() {
        return this._isShown;
    }

    renderedCallback() {
        if (this.isRendered) {
            return;
        }
        this.isRendered = true;
        clAppReady(this.createNgbsPackageSelector.bind(this));
    }

    angular;

    createNgbsPackageSelector() {
        this.angular = document.createElement('app-root');
        this.angular.setAttribute(
            'route-params-json',
            JSON.stringify({
                name: 'lead-conversion'
            })
        );
        this.template.querySelector('.billing-package-selector').appendChild(this.angular);

        this.angular.addEventListener('rootEvent', event => {
            const eventData = event.detail.data;
            switch(event.detail.name) {
                case 'packageSelect':
                    CL.app.serviceSelector.ngbsServiceSelector.setSelectedService(eventData);
                    break;
                case 'accountPackage':
                    CL.app.serviceSelector.ngbsServiceSelector.setFiltersByAccountPackage(eventData);
                    break;
                case 'packagesUpdate':
                    CL.app.serviceSelector.ngbsServiceSelector.setServices(eventData);
                    break;
                case 'chargeTermSelect':
                    CL.app.serviceSelector.setChargeTerm(eventData);
                    break;
                case 'loadingStatusUpdate':
                    CL.app.setLoadingStatus({
                        isNgbsInitializing: eventData.isInitializing,
                        isNgbsAccountLoading: eventData.isAccountLoading,
                        isPackageSearching: eventData.isPackageSearching,
                    });
                    break;
                case 'accountNumberOfLinesUpdate':
                    CL.app.setNgbsExistingNumberOfLines(eventData);
                    break;
                case 'defaultAreaCodeUpdate':
                    CL.app.setDefaultAreaCode({...eventData});
                    break;
                case 'defaultAreaCodeRequired':
                    CL.app.setDefaultAreaCodeRequired(eventData);
                    break;
                case 'availableServiceOptions':
                    CL.app.setAvailableServiceOptions(eventData);
                    break;
                case 'availableEditionOptions':
                    CL.app.setAvailableEditionOptions(eventData);
                    break;
                case 'selectedBusinessIdentity':
                    if (eventData.id && eventData.currency) {
                        CL.app.serviceSelector.setBusinessIdentity(eventData.id);
                        CL.app.serviceSelector.setCurrency(eventData.currency);
                    }
                    break;
                default:
                    console.group('Lead Conversion: Unknown event');
                    console.log(event);
                    console.groupEnd();
            }
        });

        CL.app.rx.billingParams.subscribe(billingParams => {
            this.addRouteData('dataBillingParams', billingParams);
            this.addRouteData('dataIsPrmFlow', this.isPrmFlow);
        });
        CL.app.rx.lead.subscribe(lead => {
            this.addRouteData('dataLead', lead?.record);
        });
        CL.app.serviceSelector.rx.isLegacy.subscribe(isLegacy => {
            this.isLegacy = isLegacy;
            this.setBillingSelectorIsShown();
        });
        CL.app.serviceSelector.rx.filters.subscribe(filters => {
            this.addRouteData('dataBrand', filters.brand.value);
            this.addRouteData('dataService', filters.service.value);
            this.addRouteData('dataEdition', filters.edition.value);
            this.addRouteData('dataType', filters.type.value);

            if (!this.isLegacy) {
                let params = {
                    id: filters.businessIdentity.value,
                    currency: filters.currency.value,
                };
                this.addRouteData('dataBusinessIdentity', params);
            }
        });
        CL.app.rx.selectedAccount.subscribe(selectedAccount => {
            const selectedAccountData = {
                sfId: selectedAccount?.id,
                billingId: selectedAccount?.billingId,
                rcUserId: selectedAccount?.rcUserId,
                enabledLBO: selectedAccount?.enabledLBO,
                isFedRamp: selectedAccount?.isFedRamp,
                elaAccountType: CL.app.isElaAccount ? 'ELA' : null,
                isWholesale: selectedAccount?.isWholesale,
                isBillOnBehalf: selectedAccount?.isBillOnBehalf,
                ngbsPartnerId: selectedAccount?.ngbsPartnerId
            };
            this.addRouteData('selectedAccount', selectedAccountData);
        });

        CL.app.rx.convertBtnTouched.subscribe(touched => {
            this.addRouteData('convertBtnTouched', touched);
        });

        CL.app.rx.settings.subscribe(settings => {
            if (settings.featuresEnabled.isSelectPackagesByBusinessIdentity) {
                // Set BI options and as a result Brand (re-set the value)
                CL.app.serviceSelector.setBusinessIdentityOptions();
            }
        });
    }

    setBillingSelectorIsShown() {
        if (!this.isRendered) {
            return;
        }
        const dataIsShown = !this.isLegacy && this.isShown;
        this.addRouteData('dataIsShown', dataIsShown);
    }

    addRouteData(name, data) {
        this.angular.setAttribute(
            'add-route-data-json',
            JSON.stringify({
                [name] : data
            })
        );
    }
}

function str(v) {
    return v || '';
}