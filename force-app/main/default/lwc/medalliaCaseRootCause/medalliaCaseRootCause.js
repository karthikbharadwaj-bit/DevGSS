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

export default class MediaTree extends LightningElement {

    isRenderedCallBackInitialized = false;

    @api selectedValues() {
        const selectedEvent = new CustomEvent("selectedvalues",{detail:this.template.querySelector('[data-id="medalliaTreeInputBox"]').value});
        this.dispatchEvent(selectedEvent);
    }

    initializeMedalliaTree() {
        var medalliaDataJSON =  [
            { id : 'PRODCAPABILITY' , title : 'Missed Expectations - Product Capability'},
            { id : 'UNRESPONSIVE' ,title : 'Sales - Unresponsive/Timeliness of Response'},
            { id : 'KNOWLEDGE' ,title : 'Sales - Poor Product Knowledge'},
            { id : 'MISSEDCOMMITMENT' ,title : 'Sales - Missed Commitment'},
            { id : 'OVERSOLD' ,title : 'Sales - Oversold'},
            { id : 'PROFESSIONALISM' ,title : 'Sales - Professionalism'},
            { id : 'CREDITNOTAPPLIED' ,title : 'Sales - Credit Promised - Not Applied'},
            { id : 'TAXEXEMPT' ,title : 'Sales - Tax Exempt'},
            { id : 'PARTNEREXPERIENCE' ,title : 'Sales - Partner Experience'},
            { id : 'ACCTREPCHANGES' ,title : 'Sales - Too many acct rep changes'},
           ];

        this.component = $(this.template.querySelector('[data-id="medalliaTreeMissedExpectations"]'));
        this.component.medalliaTree({
            name: 'medalliaTree',
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