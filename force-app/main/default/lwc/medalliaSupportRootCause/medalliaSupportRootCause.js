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

export default class MedalliaSupportRootCause extends LightningElement {

    isRenderedCallBackInitialized = false;

    @api selectedValues() {
        console.log ('Selected Values Function');
        const selectedEvent = new CustomEvent("selectedvalues",{detail:this.template.querySelector('[data-id="medalliaTreeSupportInputBox"]').value});
        this.dispatchEvent(selectedEvent);
    }

    initializeMedalliaTree() {
        var medalliaDataJSON =  [
            { id : 'KNOWLEDGE' , title : 'Technical Support - Knowledge'},
            { id : 'TIMETORESOLVE' , title : 'Technical Support - Time to Resolve'},
            { id : 'POORFOLLOWUP' , title : 'Technical Support - Poor Follow-Up'},
            { id : 'PROFESSIONALISM' , title : 'Technical Support - Professionalism'},
            { id : 'PORTING' , title : 'Technical Support - Porting'},
            { id : 'SELFSERVICEFAQ' , title : 'Technical Support - Self Service / FAQ'},
            { id : 'UNRESPONSIVEHOLDWAITTIME' , title : 'Technical Support Unresponsive - Hold/Wait Time'},
            { id : 'CLOSEDNORESOLUTION' , title : 'Technical Support - Closed/No Resolution'},
            { id : 'COMMUNICATIONSKILLS' , title : 'Technical Support - Communication Skills'},
            { id : 'MISSEDCOMMITTMENT' , title : 'Technical Support - Missed Committment'},
            { id : 'PRODUCTKNOWLEDGE' , title : 'Technical Support - Product Knowledge'},
            { id : 'RECURRINGISSUE' , title : 'Technical Support - Reoccuring Issue'},
            { id : 'GENERAL' , title : 'Technical Support - General'},
            ];

        this.component = $(this.template.querySelector('[data-id="medalliaTreeSupport"]'));
        this.component.medalliaTree({
            name: 'medalliaTreeSupport',
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