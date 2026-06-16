/* eslint-disable no-debugger */
/* eslint-disable no-undef */
/* eslint-disable no-console */
import { LightningElement, api } from 'lwc';

// importing Static Resources
import medalliaComboTree from '@salesforce/resourceUrl/RCCOMBO';
import medalliaJQuery from '@salesforce/resourceUrl/RCJQUERY';
import medalliaComboCSS from '@salesforce/resourceUrl/RCCOMBOCSS';
import iContains from '@salesforce/resourceUrl/iContains';

// importing resource loader
import { loadScript, loadStyle } from 'lightning/platformResourceLoader';

export default class MedalliaCSMRootCause extends LightningElement {

    isRenderedCallBackInitialized = false;

    @api selectedValues() {
        console.log ('Selected Values Function');
        const selectedEvent = new CustomEvent("selectedvalues",{detail:this.template.querySelector('[data-id="medalliaTreeBillingInputBox"]').value});
        this.dispatchEvent(selectedEvent);
    }

    initializeMedalliaTree() {
        var medalliaDataJSON =  [
            { id : 'CONFUSING' ,title : 'Billing - Confusing'},
            { id : 'DISPUTES' ,title : 'Billing - Discrepancies/Disputes'},
            { id : 'TAXES' ,title : 'Billing - Taxes and Fees'},
            { id : 'PSBLFRAUD' ,title : 'Billing - Possible Fraud'},
            { id : 'GENERAL' ,title : 'Billing - General'},
            { id : 'ACCDISABLED' , title : 'Billing - Account Disabled'},
            ];
        this.component = $(this.template.querySelector('[data-id="medalliaTreeBilling"]'));
        this.component.medalliaTree({
            name: 'medalliaTreeBilling',
			source : medalliaDataJSON,
			isMultiple: true,
            cascadeSelect: true,
        });
        

    }

    renderedCallback() { 

        if (this.isRenderedCallBackInitialized) {
            return;
        }

            loadScript(this, medalliaJQuery).then(() => {
                loadScript(this, medalliaComboTree).then(() => {
                    loadStyle(this, medalliaComboCSS).then(() => {
                        loadScript(this, iContains).then(() => {
                            this.initializeMedalliaTree();
                            this.isRenderedCallBackInitialized = true;
                        });
                    });
                });
            });
    }

}