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

export default class MedalliaProductRootCause extends LightningElement {

    isRenderedCallBackInitialized = false;

    @api selectedValues() {
        console.log ('Selected Values Function');
        const selectedEvent = new CustomEvent("selectedvalues",{detail:this.template.querySelector('[data-id="medalliaTreeProductInputBox"]').value});
        this.dispatchEvent(selectedEvent);
    }

    initializeMedalliaTree() {
        var medalliaDataJSON =  [
            { id : 'TOOCOMPLICATED' , title : 'Product - Too complicated/ease of use'},
            { id : 'MOBILEAPP' , title : 'Product - Mobile App'},
            { id : 'RCMEETINGS' , title : 'Product - RCV/Meetings'},
            { id : 'CONTACTCENTER' , title : 'Product - Contact Center'},
            { id : 'INTEGRATIONS' , title : 'Product - Integrations'},
            { id : 'AUDIOQUALITY' , title : 'Product - Audio Quality'},
            { id : 'VIDEOQUALITY' , title : 'Product - Video Quality'},
            { id : 'FAXISSUES' , title : 'Product - Fax Issues'},
            { id : 'FAXCOST' , title : 'Product - Fax Cost'},
            { id : 'COST' , title : 'Product - Cost'},
            { id : 'FEATUREREQUEST' , title : 'Product - Feature Request'},
            { id : 'PHONEISSUES' , title : 'Product - Phone - Issue'},
            { id : 'HEADSETISSUES' , title : 'Product - Headset - Issue'},
            { id : 'CONNECTIVITY' , title : 'Product - Connectivity / WIFI'},
            { id : 'OUTAGEKNOWNISSUE' , title : 'Product - Outage/Known Issue'},
            { id : 'DISSATISFACTION' , title : 'Product - Dissatisfaction'},
            { id : 'AI' , title : 'Product - AI'},
            { id : 'SPAM' , title : 'Product - SPAM'},
            { id : 'RELIABILITY' , title : 'Product - Reliability'},
            ];
        this.component = $(this.template.querySelector('[data-id="medalliaTreeProduct"]'));
        this.component.medalliaTree({
            name: 'medalliaTreeProduct',
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