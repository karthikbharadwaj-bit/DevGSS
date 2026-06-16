import { LightningElement, track, wire, api } from 'lwc';
import getCurrentUserDetailsForLWC from "@salesforce/apex/DSENTPrediction.getCurrentUserDetailsForLWC";
import getCurrentCaseDSENTRecordsForLWC from "@salesforce/apex/DSENTPrediction.getCurrentCaseDSENTRecordsForLWC";
import { NavigationMixin } from 'lightning/navigation';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
export default class DSENTPrediction extends NavigationMixin( LightningElement ) {
    @api objectApiName ;
    @api recordId;
    @track objectApiNameChild = '';
    @track fields = [];
    @track shouldRenderComponent = false;
    @track componentTitle = '';
    @track data = [];
    @track shouldDisplayViewForm = false;
    @track currentRecordId = '';
    @track shouldDisplayEditForm = true;
    @track caseRecordUrl = '';
    @track existingDSENTRecords=[];
    @track title='';
    @track isMasterField=false;
    @track currentReferenceField='';
    @track currentReferenceFieldList=[];
    @track isReadOnly = false;
    @track isAppPresent = false;
    @track isProfilePresent = false;
    @track isRecordTypePresent = false ; 
    @track lookupRecordId = '';
    @track lookupRecordTypeName = '';
    
    /**
     * @method DSENTObjectInfo 
     * @description To get to get the current lookup field when record is created 
                    from case record and get list of lookup fields when record is 
                    created from new button on the object level
     * @param {String} objectApiName Child object name whose reference fields are obtained
     */
    @wire(getObjectInfo, { 
        objectApiName: '$objectApiNameChild' 
    })
    DSENTObjectInfo({data, error}) {
        if(data) 
        {
            var dataFields=data.fields;
            Object.entries(dataFields).forEach(i=>
                {
                    var currentRefField=i[1]['referenceToInfos'][0];
                    if(currentRefField!=null)
                    {
                        if(i[1]['dataType'].toUpperCase()=='REFERENCE' && i[1]['referenceToInfos']!=[] && currentRefField.apiName == this.objectApiName)
                        {
                            this.currentReferenceField=i[0];    //Contains the current reference field
                        }
                    }
                }
            );
        }
        else if(error)
        {
            console.log(error);
        }
    }

    /**
     * @method getCurrentUserDetailsForLWC
     * @description To display or hide the LWC component 
                    based on record type,profile and application on case record
     * @param {String} recordId record ID of the current record where the component is displayed 
     */

    @wire(getCurrentUserDetailsForLWC, {
        recordId: '$recordId'
    })
    getCurrentUserDetailsForLWC(result)
    {
        if(result.data){
            this.objectApiNameChild=result.data.objectApiName;
            this.fields=result.data.fieldsToDisplay.trim().split(',');
            this.componentTitle=result.data.componentTitle.trim();
            if(result.data.isProfilePresent=='true' && result.data.isAppPresent=='true' && result.data.isRecordTypePresent=='true')
            {
                this.shouldRenderComponent=true;   
            }
        }
        else if(result.error)
        {
            console.log(result.error);
        }
    }
     /* getCurrentCaseDSENTRecordsForLWC - to get the DSENT prediction 
    for the current case record*/
    /**
     * @method getCurrentCaseDSENTRecordsForLWC
     * @description To get the DSENT prediction 
                    for the current case record
     * @param {String} recordId record ID of the current record where the component is displayed
     */
    @wire(getCurrentCaseDSENTRecordsForLWC, {
        recordId: '$recordId'
    })
    getCurrentCaseDSENTRecordsForLWC(result){
        if(result)
        {
            if(result.data)
            {
                this.data=result.data;
                if(this.data.length>0){
                    this.currentRecordId=this.data[0].Id;
                    this.shouldDisplayViewForm=true;
                    this.shouldDisplayEditForm=false;
                }else if(this.data.length==0){
                    this.shouldDisplayViewForm=false;
                    this.shouldDisplayEditForm=true;
                }
            }
            else if(result.error)
            {
                console.log(result.error);
            }
        }
    }
     /* handleRowAction - */
    /**
     * @method handleRowAction 
     * @description Functionality for the View and Edit buttons on
                    the component for existing DSENT prediction record for case
     */
    handleRowAction( event ) {
        if(event.target)
        {
            const actionName=event.target.label;
            switch ( actionName ) 
            {
                case 'View':
                    this[NavigationMixin.Navigate]({
                        type: 'standard__recordPage',
                        attributes: {
                            recordId:this.currentRecordId,
                            actionName: 'view'
                        }
                    });
                    break;
                case 'Edit':
                    this[NavigationMixin.Navigate]({
                        type: 'standard__recordPage',
                        attributes: {
                            recordId:this.currentRecordId,
                            actionName: 'edit'
                        }
                    });
                    break;
            }
        }
    }
    
    /**
     * 
     * @method handleSuccess
     * @description to reload the page on successful creation of DSENT Record
     */
    handleSuccess(event)
    {
            window.location.reload();
    }
    /**
     * 
     * @method handleRecordSave
     * @description displays error messages when user tries to create DSENT Prediction Records for out of scope applications and RTs 
                    on the DSENT Prediction object level and clears the field on clicking the cancel button while trying to create DSENT Prediction record
                    from an existing case record
     */
    handleRecordSave(event){
        const actionName=event.target.label;
        var inputFields=this.template.querySelectorAll("lightning-input-field");
        switch( actionName ) 
        {
            case 'Cancel' :
                inputFields.forEach(i=>{
                    if(i.fieldName!=this.currentReferenceField){
                        i.reset();
                    }
                });
        }
    }
    /**
     * 
     * @method handleOnLoad
     * @description to prepopulate and disable the lookup field value
     */
    handleOnLoad(event){
        var inputFields=this.template.querySelectorAll("lightning-input-field");
        inputFields.forEach(i=>{
            if(i.fieldName==this.currentReferenceField){
                i.value=this.recordId;
                i.disabled=true;
            }else{
                i.disabled=false;
            }
        })
    }
}