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

export default class MedalliaImplementationRootCause extends LightningElement {

    isRenderedCallBackInitialized = false;

    @api selectedValues() {
        console.log ('Selected Values Function');
        const selectedEvent = new CustomEvent("selectedvalues",{detail:this.template.querySelector('[data-id="medalliaTreeImplementationInputBox"]').value});
        this.dispatchEvent(selectedEvent);
    }

    initializeMedalliaTree() {
       var medalliaDataJSON =  [
            { id : 'ONBOARDING' , title : 'Implementation - Onboarding Thoroughness'},
            { id : 'SCHEDULING' , title : 'Implementation - Scheduling Issues'},
            { id : 'COMMUNICATION' , title : 'Implementation - Communication Skills'},
            { id : 'MISSEDAPPOINTMENT' , title : 'Implementation - Missed Appointment'},
            ];

        this.component = $(this.template.querySelector('[data-id="medalliaTreeImplementation"]'));
        this.component.medalliaTree({
            name: 'medalliaTreeImplementation',
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