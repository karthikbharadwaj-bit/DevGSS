import { LightningElement, wire ,track,api} from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecordNotifyChange } from 'lightning/uiRecordApi';
import getSuccessPlanActivityRecords from '@salesforce/apex/SuccessPlanController.getSuccessPlanActivityRecords';
import saveDraftValues from '@salesforce/apex/SuccessPlanController.saveDraftValues';
import TIME_ZONE from "@salesforce/i18n/timeZone";
import SuccessPlanRecordsPerPage from '@salesforce/label/c.SuccessPlanRecordsPerPage';

const VIEW_COLUMNS = [ { label: 'Activity Name', fieldName: 'ActivityName__c', type: 'text' },
    { label: 'What do you need to do?', fieldName: 'What_do_you_need_to_do__c', type: 'text' } ,
    { label: 'Partner Readiness Score', fieldName: 'PartnerReadinessScore__c', type: 'text'} ,
    { label: 'Status', fieldName: 'Status__c', type: 'text' },
    { label: 'Comments', fieldName: 'Comments__c', type: 'text'},
    { label: 'Time Stamp', fieldName: 'Time_Stamp__c', type: 'date',
        typeAttributes: {
            day: 'numeric',
            month: 'numeric',
            year: 'numeric',
            hour: '2-digit',
            minute: '2-digit',         
            timeZone:TIME_ZONE,
            hour12: true
        },
        sortable: false        
    }
];

const EDIT_COLUMNS = [
    { label: 'Activity Name', fieldName: 'ActivityName__c', type: 'text'},
    { label: 'What do you need to?', fieldName: 'What_do_you_need_to_do__c', type: 'text'}, 
    { label: 'Partner Readiness Score', fieldName: 'PartnerReadinessScore__c', type: 'text'},
    { label: 'Status', fieldName: 'Status__c', type: 'picklist',       
        typeAttributes: {
            placeholder: 'Choose Status',
            options: [
                { label: 'Not Started', value: 'Not Started' },
                { label: 'In Progress', value: 'In Progress' },
                { label: 'Completed', value: 'Completed' },
                { label: 'Completed by Previous PM', value: 'Completed by Previous PM' },
                { label: 'Not Done', value: 'Not Done' }
            ],
            value: { fieldName: 'Status__c' },
            context: { fieldName: 'Id' },
            variant: 'label-hidden',
            name: 'Status',
            label: 'Status'
        },
        cellAttributes: {
            class: { fieldName: 'stageClass' }
        }
    },
    { label: 'Comments', fieldName: 'Comments__c', type: 'text', editable: true},
    { label: 'Time Stamp', fieldName: 'Time_Stamp__c', type: 'date',
        typeAttributes: {
            day: 'numeric',
            month: 'numeric',
            year: 'numeric',
            hour: '2-digit',
            minute: '2-digit',         
            timeZone:TIME_ZONE,
            hour12: true
          },
          sortable: false        
    }
];

export default class CustomDatatableDemo extends LightningElement {
    columns;
    records;
    lastSavedData;
    error;
    accountId;
    wiredRecords;
    showSpinner = false;
    @api recordId;
    @api recordid;
    @api successPlanId;
    draftValues = [];
    privateChildren = {}; //used to get the datatable picklist as private childern of customDatatable
    @track page = 1; //this will initialize 1st page
    @track items = []; //it contains all the records.
    @track recData = []; //data to be displayed in the table
   // @track columns; //holds column info.
    @track startingRecord = 1; //start record position per page
    @track endingRecord = 0; //end record position per page
    @track pageSize = SuccessPlanRecordsPerPage; //default value we are assigning
    @track totalRecountCount = 0; //total record count received from all retrieved records
    @track totalPage = 0; //total number of page is needed to display all records
    @api currentPage;
    @api lastPage;
    records30ToDisplay;
    @api canEdit;
    @api readinessScoreWithComments; //By Hareesh
    @api redinessScore;
    hidePagination = false;
    

    connectedCallback(){
        if(this.canEdit == true){
            this.columns = EDIT_COLUMNS;
        } else {
            this.columns = VIEW_COLUMNS; 
        }
    }
 
    renderedCallback() {
        if (!this.isComponentLoaded) {
            /* Add Click event listener to listen to window click to reset the picklist selection 
            to text view if context is out of sync*/
            window.addEventListener('click', (evt) => {
                this.handleWindowOnclick(evt);
            });
            this.isComponentLoaded = true;
        }
    }

    disconnectedCallback() {
        window.removeEventListener('click', () => { });
    }

    handleWindowOnclick(context) {
        this.resetPopups('c-datatable-picklist', context);
    }

    //create object value of datatable picklist markup to allow to call callback function with window click event listener
    resetPopups(markup, context) {
        let elementMarkup = this.privateChildren[markup];
        if (elementMarkup) {
            Object.values(elementMarkup).forEach((element) => {
                element.callbacks.reset(context);
            });
        }
    }

    //wire function to get the related SPA records of account selected
    @wire(getSuccessPlanActivityRecords, {accId:'$recordId',activityDays: 90})
    wiredSuccessPlanActivityRecords(result) {
        this.wiredRecords = result;
        const { data, error } = result;
        if (data) {
            this.records30ToDisplay = JSON.parse(JSON.stringify(data));; 
            this.items = data;
            this.totalRecountCount = data.length; 
            this.totalPage = Math.ceil(this.totalRecountCount / this.pageSize); 
            this.recData = this.items.slice(0,this.pageSize);                    
            this.endingRecord = this.pageSize;  
            if(this.totalPage == 1) {
                this.hidePagination = true; 
            }      

            this.records = JSON.parse(JSON.stringify(data)); 

            this.records.forEach(record => {
                record.linkName = '/' + record.Id;
                if (record.AccountId) {
                    record.linkAccount = '/' + record.AccountId;
                    record.accountName = record.Account.Name;
                }
                record.stageClass = 'slds-cell-edit';
            });
            this.items = this.records;	
            this.totalRecountCount = this.records.length; 
            this.totalPage = Math.ceil(this.totalRecountCount / this.pageSize);	
            this.records = this.items.slice(0, this.pageSize);	
            this.endingRecord = this.pageSize;
            this.error = undefined;
        } else if (error) {
            this.records = undefined;
            this.error = error;
        } else {
            this.error = undefined;
            this.records = undefined;
        }
        this.lastSavedData = this.records;
        this.showSpinner = false;
    }

    // Event to register the datatable picklist mark up.
    handleItemRegister(event) {
        event.stopPropagation(); //stops the window click to propagate to allow to register of markup.
        const item = event.detail;
        if (!this.privateChildren.hasOwnProperty(item.name))
            this.privateChildren[item.name] = {};
        this.privateChildren[item.name][item.guid] = item;
    }

    handleChange(event) {
        event.preventDefault();
        this.accountId = event.target.value;
        this.showSpinner = true;
    }

    handleCancel(event) {
        event.preventDefault();
        this.records = JSON.parse(JSON.stringify(this.lastSavedData));
        this.handleWindowOnclick('reset');
        this.draftValues = [];
    }
	
	handleCellChange(event) {
        event.preventDefault();
        this.updateDraftValues(event.detail.draftValues[0]);
    }

    //Captures the changed picklist value and updates the records list variable.
    handleValueChange(event) {
        event.stopPropagation();
        let dataRecieved = event.detail.data;
        let updatedItem;
        switch (dataRecieved.label) {
            case 'Status':
                updatedItem = {
                    Id: dataRecieved.context,
                    Status__c: dataRecieved.value
                    
                };
                // Set the cell edit class to edited to mark it as value changed.
                this.setClassesOnData(
                    dataRecieved.context,
                    'stageClass',
                    'slds-cell-edit slds-is-edited'
                );
                break;
            default:
                this.setClassesOnData(dataRecieved.context, '', '');
                break;
        }
        this.updateDraftValues(updatedItem);
        this.updateDataValues(updatedItem);
    }

    updateDataValues(updateItem) {
        let copyData = JSON.parse(JSON.stringify(this.records));
        copyData.forEach((item) => {
            if (item.Id === updateItem.Id) {
                for (let field in updateItem) {
                    item[field] = updateItem[field];
                }
            }
        });
        this.records = [...copyData];
    }

    updateDraftValues(updateItem) {
        let draftValueChanged = false;
        let copyDraftValues = JSON.parse(JSON.stringify(this.draftValues));
        copyDraftValues.forEach((item) => {
            if (item.Id === updateItem.Id) {               
                item.Time_Stamp__c = this.currentUserDateTime;                
                for (let field in updateItem) {
                    item[field] = updateItem[field];
                }
                draftValueChanged = true;
            }
        });
        if (draftValueChanged) {
            this.draftValues = [...copyDraftValues];
        } else {
            this.draftValues = [...copyDraftValues, updateItem];
        }
    }

    handleEdit(event) {
        event.preventDefault();
        let dataRecieved = event.detail.data;
        this.handleWindowOnclick(dataRecieved.context);
        switch (dataRecieved.label) {
            case 'Status':
                this.setClassesOnData(
                    dataRecieved.context,
                    'stageClass',
                    'slds-cell-edit'
                );
                break;
            default:
                this.setClassesOnData(dataRecieved.context, '', '');
                break;
        };
    }

    setClassesOnData(id, fieldName, fieldValue) {
        this.records = JSON.parse(JSON.stringify(this.records));
        this.records.forEach((detail) => {
            if (detail.Id === id) {
                detail[fieldName] = fieldValue;
            }
        });
    }

    handleSave(event) {
        event.preventDefault();
        this.showSpinner = true;
        var draftValuesToSave = event.detail.draftValues;
        var checkBool = true;        
        for(var i = 0; i < draftValuesToSave.length; i++ ) {   
            if(JSON.stringify(draftValuesToSave[i]).includes('Comments__c')) {      
            if(draftValuesToSave[i].Comments__c.length > 255 ) {
                    const evt = new ShowToastEvent({
                        title: 'Error',
                        message: 'Comments are limited to 255 characters.',
                        variant: 'error',
                        mode: 'dismissable'
                    });
                    this.dispatchEvent( evt );
                    checkBool = false;
                    this.showSpinner = false;
                    break;
                }           
            }
        }

        if(checkBool == true ) {
        saveDraftValues({ data: this.draftValues })
            .then(result => {
                if(result === 'SUCCESS') {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Success',
                            message: 'SuccessPlanActivities updated successfully',
                            variant: 'success'
                        })
                    );
                }else {
                    this.dispatchEvent (
                        new ShowToastEvent({
                            title: 'Error',
                            message: 'Something went wrong. Please reach out to your Admin for assistance.',
                            variant: 'error'
                        })
                    );
                 }
                //Get the updated list with refreshApex.
                refreshApex(this.wiredRecords).then(() => {
                    this.records.forEach(record => {
                        record.accountNameClass = 'slds-cell-edit';
                        record.stageClass = 'slds-cell-edit';
                    });
                    this.draftValues = [];
                });
                this.page =1;
                this.nextHandler();
                this.previousHandler();
                //added by Hareesh
                getRecordNotifyChange([{recordId: this.successPlanId}]);
                // Creates the event with the data.
                const selectedEvent = new CustomEvent("day90value"); 
                // Dispatches the event.
                this.dispatchEvent(selectedEvent);  
            })
            .catch(error => {
                this.showSpinner = false;
            });
        }
    }

    previousHandler() {
        if (this.page > 1) {
            this.page = this.page - 1; //decrease page by 1
            this.displayRecordPerPage(this.page);
        }      
    }

    //clicking on next button this method will be called
    nextHandler() {      
        if((this.page<this.totalPage) && this.page !== this.totalPage){
            this.page = this.page + 1; //increase page by 1       
            this.displayRecordPerPage(this.page);            
        }                   
    }

    displayRecordPerPage(page) { 
        this.currentPage = this.page; 
        this.lastPage =  this.totalPage;            
        this.startingRecord = ((page -1) * this.pageSize) ;
        this.endingRecord = (this.pageSize * page);
        this.endingRecord = (this.endingRecord > this.totalRecountCount)? this.totalRecountCount : this.endingRecord; 
        this.records = this.items.slice(this.startingRecord, this.endingRecord);      
        this.startingRecord = this.startingRecord + 1;
    }       
}