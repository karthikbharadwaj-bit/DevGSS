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
        const selectedEvent = new CustomEvent("selectedvalues",{detail:this.template.querySelector('[data-id="medalliaTreeCSMInputBox"]').value});
        this.dispatchEvent(selectedEvent);
    }

    initializeMedalliaTree() {
       var medalliaDataJSON =  [
            { id : 'UNRESPONSIVE' ,title : 'CSM - Unresponsive/Timeliness of Response'},
            { id : 'LACKEXPERIENCE' ,title : 'CSM - Lack of Experience'},
            { id : 'MISSEDCOMMITMENT' ,title : 'CSM - Missed Commitment'},
            { id : 'PROFESSIONALISM' ,title : 'CSM - Professionalism'},
            { id : 'KNOWLEDGE' ,title : 'CSM - Poor Product Knowledge'},
            { id : 'OFTENCHANGES' ,title : 'CSM - Changes Often'},
            ];

        this.component = $(this.template.querySelector('[data-id="medalliaTreeCSM"]'));
        this.component.medalliaTree({
            name: 'medalliaTreeCSM',
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