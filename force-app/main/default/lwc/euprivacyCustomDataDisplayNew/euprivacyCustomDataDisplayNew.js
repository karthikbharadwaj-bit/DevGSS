import { LightningElement, track, api, wire} from 'lwc';
import getFieldSetMetadata from '@salesforce/apex/EuprivacyFieldsetControllerNew.getFieldSetMetadata';
//import saveFieldUpdate from '@salesforce/apex/EuprivacyFieldsetControllerNew.saveRecordChange';
import saveFieldUpdate from '@salesforce/apex/EuprivacyFieldsetControllerNew.savePIIUpdates';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import {showSpinner, hideSpinner} from "c/clService";
import { refreshApex } from '@salesforce/apex';


export default class EuprivacyCustomDataDisplayNew extends LightningElement {
    // Config
    @api showTitle;
    @api strTitle;
    @api iconName;
    @api columnsLarge = 2;
    @api columnsMedium;
    @api columnsSmall;
    @api fieldSetName;
    @api isEditable;
    @api alwaysEditing;
    @api saveMessageTitle;
    @api saveMessage;
    @api recordId;
    @api recordTypeId;


    // Record props
    @track sObjectName;
    @track recordFields = [];
    @track metadataError;
    @track closePicklists = [];
    @track showStatus = false;
    @track closePickVal;

    // Track changes to our main properties that will need to be binded to HTML
    @track isLoading = true;
    @track isEditing = false;
    @track hasChanged = false;
    @track isSaving = false;
    @track layoutSizeLarge;
    @track layoutSizeMedium;
    @track layoutSizeSmall;

    @track mapkeyvaluestore=[];
    @track mapFieldValues=[];
    @track showComponent=false;
    @track showNoData = false;
    @track showEdit = false;

    @track fieldData = [];
    // CRM-5859 - Introduction of click to dial option in the customer info section for EU profile users
    @track fieldDataFinal=[];
    @track phoneField;
    @track copyData;

    @track resultData;

    @track resultFieldsetData;

    // Web Component Init
    connectedCallback() {
        // Setup the layout sizes
        if (this.columnsLarge) this.layoutSizeLarge = 12 / this.columnsLarge;
        // Handle always editing state
        if (this.alwaysEditing) this.isEditing = true;
        console.log('::: Column Size = '+this.columnsLarge);

        //Make Implicit Apex call to Get Details
        /*
        getFieldSetMetadata({recordId: this.recordId})
        .then(data => {
            this.isLoading = true;
            // Get the FieldSet Name if we have no custom title
            if (!this.strTitle) this.strTitle = data.fieldSetLabel;
            this.showComponent = data.showComponent;
            this.fieldData = data.fieldDefinitionsLst;
            console.log('::: fieldData 1 - '+JSON.stringify(this.fieldData));
            console.log('::: showComponent - '+this.showComponent);
        })
        .catch(error => {
            this.error = error;
            console.log('::: Error - '+error);
        })
        */
    }


     // Get the SObjectType and the Fields
    @wire(getFieldSetMetadata, {
        recordId: '$recordId'
    })
    wiredFieldSetMetadata(result) {
        this.isLoading = true;
        this.resultFieldsetData = result;
        if (result.data) {
            this.isLoading = true;
            this.resultData = result.data;
            // Get the FieldSet Name if we have no custom title
            if (!this.strTitle) this.strTitle = this.resultData.fieldSetLabel;
            this.showComponent = this.resultData.showComponent;
            this.fieldData = this.resultData.fieldDefinitionsLst;
            console.log('::: fieldData 1 - '+JSON.stringify(this.fieldData));
            console.log('::: showComponent - '+this.showComponent);
            // CRM-5859 - Introduction of click to dial option in the customer info section for EU profile users
            for(let val of this.fieldData){
                this.copyData=JSON.parse(JSON.stringify(val));
                this.copyData["phoneField"]=(this.copyData.fieldType=='Phone')?true:false;
                this.fieldDataFinal.push(this.copyData);
                
            }
            // CRM-5859 - END
        } else if (result.error) {
           console.error(':::getMetadata error', this.error);
        }
    } 

    toggleEdit(event) {
        this.showComponent = false;
        this.showNoData = false;
        this.showEdit = true;
    }

    handleCancel() {
        this.showComponent = true;
        this.showNoData = false;
        this.showEdit = false;
    }

    @track mapFieldData = [];
    handleSave(event) {
        showSpinner('Saving...');
        console.log('::: Event Label - '+event.target.label);
        var inputFields = this.template.querySelectorAll("lightning-input");
        this.mapFieldData = [];
        inputFields.forEach(inputField => {
            console.log('::: inputFields - '+inputField.value+' and '+inputField.name);
            this.mapFieldData.push({value:inputField.value, key:inputField.name});
        });
				var inputHTMLFields = this.template.querySelectorAll("lightning-input-rich-text");
        inputHTMLFields.forEach(inputHTMLField => {
            console.log('::: inputHTMLFields - '+inputHTMLFields.value+' and '+inputHTMLFields.name);
            this.mapFieldData.push({value:inputHTMLField.value, key:inputHTMLField.name});
        });
        console.log('::: this.mapFieldData - '+JSON.stringify(this.mapFieldData));

        saveFieldUpdate({recordId: this.recordId, inputString:JSON.stringify(this.mapFieldData)})
        .then(result => {
            console.log('::: Result - '+JSON.stringify(result));
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Records Updated Successfully!!',
                    variant: 'success'
                })
            );
            hideSpinner();
            this.inputFields = [];
            this.fieldDataFinal=[];
            return this.refresh();
        })
        .catch(error => {
            console.log('::: Error - '+JSON.stringify(error));
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Something went wrong',
                    message: error.body.message,
                    variant: 'error'
                })
            );
            hideSpinner();
        })
        .finally(() => {
            this.inputFields = [];
            this.fieldData=[];
        });
    }

    async refresh() {
        console.log('::: refresh called');
        //refreshApex(this.resultData);
        await refreshApex(this.resultFieldsetData);
        this.showComponent = true;
        this.showNoData = false;
        this.showEdit = false;
        //window.location.reload();
    }

    // Show spinner error property
/*
    get showSpinner() {
        //return this.isLoading || this.isSaving;
        return false;
    }
*/
    // Show a UI Message
    showToastEvent(title, message, variant) {
        const event = new ShowToastEvent({
            title,
            message,
            variant
        });
        this.dispatchEvent(event);
    }


    // Handle the form Submit callback
    handleFormSubmit(event) {
        event.preventDefault();       // stop the form from submitting
        // Show spinner
        this.isSaving = true;
        console.log('::: handleFormSubmit()');
        
        const fields = event.detail.fields;
        this.template.querySelector('lightning-record-edit-form').submit(fields);
    };
}