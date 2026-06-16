/* globals CL */
import {LightningElement, track, api} from 'lwc';
import {clAppReady} from "c/clService";
import Name from '@salesforce/label/c.clLegacyServicePlanSelectorName';
import Service from '@salesforce/label/c.clLegacyServicePlanSelectorService';
import Edition from '@salesforce/label/c.clLegacyServicePlanSelectorEdition';
import Linerange from '@salesforce/label/c.clLegacyServicePlanSelectorLinerange';
import Plan from '@salesforce/label/c.clLegacyServicePlanSelectorPlan';
import Price from '@salesforce/label/c.clLegacyServicePlanSelectorPrice';


export default class ClLegacyServicePlanSelector extends LightningElement {
    @track filteredServices = [];
    @track isLegacy = null;
    @api isShown;
    @track label = {
        Name,
        Service,
        Edition,
        Linerange,
        Plan,
        Price
    };

    get isMarkupShown() {
        return this.isLegacy && this.isShown;
    }

    connectedCallback() {
        clAppReady(this.onClAppReady.bind(this));
    }

    onClAppReady() {
        CL.app.serviceSelector.rx.selectedService.subscribe(selectedLegacyService => {
            this.filteredServices = [...this.filteredServices];
        });
        CL.app.serviceSelector.rx.isLegacy.subscribe(isLegacy => {
            this.isLegacy = isLegacy;
        });
        CL.app.serviceSelector.legacyServiceSelector.rx.filteredServices.subscribe(filteredServices => {
            this.filteredServices = [...filteredServices];
        });
    }

    selectService(event) {
        CL.app.serviceSelector.legacyServiceSelector.setSelectedServiceById(event.currentTarget.dataset.id);
    }
}