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

export default class MedalliaOtherRootCause extends LightningElement {

    isRenderedCallBackInitialized = false;

    @api selectedValues() {
        console.log ('Selected Values Function');
        const selectedEvent = new CustomEvent("selectedvalues",{detail:this.template.querySelector('[data-id="medalliaTreeOtherInputBox"]').value});
        this.dispatchEvent(selectedEvent);
    }

    initializeMedalliaTree() {
        console.log('Initialize Medallia Tree');
        var medalliaDataJSON =  [
            { id : 'SHIPPING' , title : 'Shipping'},
            { id : 'DUPLICATECASE' , title : 'Duplicate Case'},
            { id : 'NOTUSINGSERVICE' , title : 'Not Using Service'},
            { id : 'NOSURVEYFEEDBACK' , title : 'No Survey Feedback Provided'},
            { id : 'POSITIVEFEEDBACK' , title : 'Positive Feedback'},
            { id : 'SOLDBUSINESS' , title : 'Sold Business'},
            { id : 'CHANGECONTACTINFO' , title : 'Change Contact Info'},
            { id : 'TOOMUCHCOMMUNICATION' , title : 'Too Much Communication'},
            { id : 'GENERALSUPPORTCOMPLAINT' , title : 'General support complaint'},
            { id : 'PARTNERREFERRALCREDIT' , title : 'Partner - Referral Credit issue'},
            { id : 'LACKOFCOMMUNICATION' , title : 'Lack of communication'},
            { id : 'ONLYCALLTOSELL' , title : 'Only call to sell/upsell'},
            ];
        this.component = $(this.template.querySelector('[data-id="medalliaTreeOther"]'));
        this.component.medalliaTree({
            name: 'medalliaTreeOther',
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