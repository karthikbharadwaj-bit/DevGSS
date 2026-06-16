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

export default class MedalliaPolicyRootCause extends LightningElement {

    isRenderedCallBackInitialized = false;

    @api selectedValues() {
        console.log ('Selected Values Function');
        const selectedEvent = new CustomEvent("selectedvalues",{detail:this.template.querySelector('[data-id="medalliaTreePolicyInputBox"]').value});
        this.dispatchEvent(selectedEvent);
    }

    initializeMedalliaTree() {
        console.log('Initialize Medallia Tree');
        var medalliaDataJSON =  [
            { id : 'AUTORENEWAL' , title : 'Policy - Auto-Renewal'},
            { id : 'CONTRACTTERMS' , title : 'Policy - Contract Terms & Conditions'},
            { id : 'EQUIPMENTCHARGES' , title : 'Policy - Equipment Charges'},
            { id : 'CANCELLATIONETF' , title : 'Policy - Cancellation/ETF'},
            { id : 'DOWNGRADE' , title : 'Policy - Downgrade'},
            { id : 'ACCOUNTVERIFICATION' , title : 'Policy - Account Verification (Incoming Caller/Email)'},
            { id : 'PRICEINCREASES' , title : 'Policy - Price Increases'},
            ];

        this.component = $(this.template.querySelector('[data-id="medalliaTreePolicy"]'));
        this.component.medalliaTree({
            name: 'medalliaTreePolicy',
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