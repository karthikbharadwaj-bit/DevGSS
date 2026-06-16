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

export default class MedalliaManagementRootCause extends LightningElement {

    isRenderedCallBackInitialized = false;

    @api selectedValues() {
        console.log ('Selected Values Function');
        const selectedEvent = new CustomEvent("selectedvalues",{detail:this.template.querySelector('[data-id="medalliaTreeManagementInputBox"]').value});
        this.dispatchEvent(selectedEvent);
    }

    initializeMedalliaTree() {
        var medalliaDataJSON =  [
            { id : 'DROPPEDCALL' , title : 'CSS - Dropped Call, No Call Back'},
            { id : 'CLOSEDRESOLUTION' , title : 'CSS - Closed/No Resolution'},
            { id : 'COMMUNICATIONSKILLS' , title : 'CSS - Communication Skills'},
            { id : 'MISSEDCOMMITTMENT' , title : 'CSS - Missed Committment'},
            { id : 'BILLINGDISCREPANCIES' , title : 'CSS - Billing - Discrepancies/Disputes'},
            { id : 'CANCELATIONREQUEST' , title : 'CSS - Cancelation Request'},
            { id : 'DOCUMENTREQUEST' , title : 'CSS - Document Request'},
            { id : 'LACKKNOWLEDGE' , title : 'CSS - Lack of Knowledge'},
            { id : 'SUPPORTUNRESPONSIVE' , title : 'CSS Support Unresponsive'},
            { id : 'TIMETORESOLVE' , title : 'CSS - Time to resolve'},
            ];

        this.component = $(this.template.querySelector('[data-id="medalliaTreeManagement"]'));
        this.component.medalliaTree({
            name: 'medalliaTreeManagement',
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