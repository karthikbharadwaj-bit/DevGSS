import { LightningElement,api,track,wire } from 'lwc';
import canGenerateSuccessPlan from '@salesforce/apex/SuccessPlanController.canGenerateSuccessPlan';
import getSuccessPlanActivityRecords from '@salesforce/apex/SuccessPlanController.getSuccessPlanActivityRecords';
import canDisplayGenerateButton from '@salesforce/apex/SuccessPlanController.canDisplayGenerateButton';
import isEditable from '@salesforce/apex/SuccessPlanController.isEditable';
import hasSuccessPlanProfiles from '@salesforce/apex/SuccessPlanController.hasSuccessPlanProfiles';
import getSuccessPlan from '@salesforce/apex/SuccessPlanController.getSuccessPlan';
import insertPlanActivities from '@salesforce/apex/SuccessPlanController.insertSucessPlanAndActivities';
import ReadinessScore from '@salesforce/label/c.RedinessScore';
import checkNegativeScenario from '@salesforce/apex/SuccessPlanController.checkNegativeScenario';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';

const columns = [ { label: 'Activity Name', fieldName: 'ActivityName__c', type: 'text' },
{ label: 'Stage', fieldName: 'Stage__c', type: 'text' } ,
{ label: 'What do you need to do?', fieldName: 'What_do_you_need_to_do__c', type: 'text' },
{ label: 'Status', fieldName: 'Status__c', type: 'picklist',editable: true} ,
];

export default class SuccessPlan90Days extends LightningElement { 
    @track page = 1; //this will initialize 1st page
    @track items = []; //it contains all the records.
    @track recData = []; //data to be displayed in the table
    @track columns; //holds column info.
    @track startingRecord = 1; //start record position per page
    @track endingRecord = 0; //end record position per page
    @track pageSize = 1; //default value we are assigning
    @track totalRecountCount = 0; //total record count received from all retrieved records
    @track totalPage = 0; //total number of page is needed to display all records
    
   
    rediScoreDefined=ReadinessScore;
    @track currentUserReadinessScore;
    @api currentUserReadinessScoreWithComments;
    enableTabs;
    generateSuccessPlan;
    errorMessage;
    hideGenerateButton;
    displayButtonSection;
    conditionLoaded = false;
    displayTable;
    @api recordId;
    @api successPlanId;
    @track records30ToDisplay;
    @api canEdit;
    displayErrorWhenNoSuccessPlanRecordsForViewProfiles;
    profileConditionsChecked = false;
    buttonDisplayChecked = false;
    partnerAccountChecked = false;
    isSPProfile = false;
    subSplit1;
    subSplit2;
    subSplit3;
    refreshDone;
    
    showErrorToast() {
        const evt = new ShowToastEvent({
            title: 'Toast Error',
            message: 'Some unexpected error',
            variant: 'error',
            mode: 'dismissable'
        });
        this.dispatchEvent(evt);
    }


    constructor() {
        super() 
                
    }

    connectedCallback(){  
        this.checkSuccessPlanProfiles(); 
        var split = this.rediScoreDefined.split('●');        
        var split1 = split[1];       
        var split2 = split[2];
        var split3 = split[3];
        this.subSplit1 = split1.substring(split1.indexOf('% ') + 1);     
        this.subSplit2 = split2.substring(split2.indexOf('% ') + 1);        
        this.subSplit3 = split3.substring(split3.indexOf('% ') + 1);                                  
    }

    handle30ValueChange(event){
        this.getsuccessPlanRecord();       
    }
    handle60ValueChange(event){
        this.getsuccessPlanRecord();       
    }
    handle90ValueChange(event){    
        this.getsuccessPlanRecord();       
    }

    handleGenerateSuccessPlanClick(event) {
        insertPlanActivities({accId: this.recordId})
        .then(data => {   
                
            if (data == null || data.length == 0 || data == '') {     
                //No records                            
            }   
            this.getsuccessPlanRecord();       
        })
        .catch(error => {
        })  
        this.enableTabs = true;  
        if(this.enableTabs == true || this.hideGenerateButton == true){
            this.hideGenerateButton=true;
            this.displayTable = true;
        }
    }

   

    getsuccessPlanRecord(){
        getSuccessPlan({accId: this.recordId}) 
        .then(data => {   
                
            if (data == null || data.length == 0 || data == '') {  
                //No Records                              
            }  
            else {                               
                this.responsedata=data;               
                refreshApex(this.responsedata);             
                this.successPlanId=this.responsedata.Id;              
                this.currentUserReadinessScore = this.responsedata.Partner_Readiness_Score__c;
                if(this.currentUserReadinessScore >= 0 && this.currentUserReadinessScore <= 59.99) {
                    this.currentUserReadinessScoreWithComments = this.currentUserReadinessScore +'%'+' '+ '  (' + this.subSplit3 +' )';                   
                }else if(this.currentUserReadinessScore >= 60 && this.currentUserReadinessScore <= 79.99) {
                    this.currentUserReadinessScoreWithComments = this.currentUserReadinessScore +'%'+' '+ '  (' + this.subSplit2 +' )';                  
                }else if(this.currentUserReadinessScore >= 80 && this.currentUserReadinessScore <= 100) {
                    this.currentUserReadinessScoreWithComments = this.currentUserReadinessScore +'%'+' '+ '  (' + this.subSplit1 +' )';                   
                }  
            }     
        })
        .catch(error => {
        })  
    }

    checkSuccessPlanProfiles(){
        hasSuccessPlanProfiles()         
            .then(data => {   
                
                if (data == null || data.length == 0 || data == '') {  
                   //No records                          
                }  
                if(data == true){                  
                    this.isSPProfile = true;
                }else {
                    this.isSPProfile = false; 
                }  
    
                if(this.isSPProfile == false){
                    this.conditionLoaded = true;
                    this.displayErrorWhenNoSuccessPlanRecordsForViewProfiles = true;
                    this.displayTable = false;
                }
                else if(this.isSPProfile == true){
                    this.handleNegativeScenario();
                    }          
            })
            .catch(error => {
            })     
    }


    checkProfileAccess(){
        isEditable()         
            .then(data => {   
                
                if (data == null || data.length == 0 || data == '') {  
                   //No data                          
                }  
                if(data == true){                  
                    this.canEdit = true;
                }else {
                    this.canEdit = false; 
                }  

                this.profileConditionsChecked = true;
                if(this.profileConditionsChecked == true){
                    this.getPartnerAccount();
                    }          
            })
            .catch(error => {
            })     
    }

    handleNegativeScenario(){
        checkNegativeScenario({accId: this.recordId})         
            .then(data => {   
                
                if (data == null || data.length == 0 || data == '') {  
                   //No data                               
                }  
                if(data == true){                  
                    this.isNegSce = true;
                }else {
                    this.isNegSce = false; 
                }   
                
                if(this.isNegSce == true){                
                    this.conditionLoaded = true;
                    this.displayErrorWhenNoSuccessPlanRecordsForViewProfiles = true;
                    this.displayTable = false;
                }
                   else if(this.isNegSce == false){
                    this.checkProfileAccess();
                   }     
            })
            .catch(error => {
            })     
    }


    getPartnerAccount() {      
        canGenerateSuccessPlan({accId: this.recordId})         
            .then(data => {   
                
                if (data == null || data.length == 0 || data == '') {  
                    //No data                           
                }  
                if(data == true) {                  
                    this.generateSuccessPlan = true;
                }else {
                    this.generateSuccessPlan = false; 
                }    
                this.partnerAccountChecked = true;
                if(this.partnerAccountChecked == true){
                    this.checkGenerateButton();
                    }         
            })
            .catch(error => {
            })      
    }

    checkGenerateButton() {      
        canDisplayGenerateButton({accId: this.recordId})         
            .then(data => {   
                
                if (data == null || data.length == 0 || data == '') {  
                    //No data                             
                }   
               
                if(data == true) {               
                    this.hideGenerateButton = false;
                }else {
                    this.hideGenerateButton = true; 
                    this.getsuccessPlanRecord();
                } 
                               
                this.conditionLoaded = true;  
              
                if((this.canEdit == true) && (this.enableTabs == true || this.hideGenerateButton == true)) {                   
                    this.displayTable = true;  
                    this.displayErrorWhenNoSuccessPlanRecordsForViewProfiles = false;                
                }     
                 else if((this.canEdit == false && this.hideGenerateButton == true && this.generateSuccessPlan == true)) {               
                    this.displayErrorWhenNoSuccessPlanRecordsForViewProfiles = true;
                    this.displayTable = false;                      
                }   else if((this.canEdit == false && this.hideGenerateButton == true && this.generateSuccessPlan == false)) {                       
                    this.displayErrorWhenNoSuccessPlanRecordsForViewProfiles = false;
                    this.displayTable = true;                      
                }   else if((this.canEdit == false  && this.generateSuccessPlan == true)) {                         
                    this.displayErrorWhenNoSuccessPlanRecordsForViewProfiles = true;
                    this.displayTable = false;
                }                                         
            })
            .catch(error => {
               
            })      
    } 

    
    getSuccessPlanActivity() {      
        getSuccessPlanActivityRecords({accId: this.recordId,activityDays: 30})         
            .then(data => {   
                
                if (data == null || data.length == 0 || data == '') {  
                   // No data                           
                }  
                if (data) {
                    this.records30ToDisplay = data; 
                    this.items = data;
                    this.totalRecountCount = data.length; //here it is 23
                    this.totalPage = Math.ceil(this.totalRecountCount / this.pageSize); //here it is 5
                    this.recData = this.items.slice(0,this.pageSize);                    
                    this.endingRecord = this.pageSize;
                    this.columns = columns;
                }                      
                                    
            })
            .catch(error => {
               
            })      
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

    displayRecordPerPage(page){     
        this.startingRecord = ((page -1) * this.pageSize) ;
        this.endingRecord = (this.pageSize * page);
        this.endingRecord = (this.endingRecord > this.totalRecountCount) 
                            ? this.totalRecountCount : this.endingRecord; 
        this.recData = this.items.slice(this.startingRecord, this.endingRecord);
        this.startingRecord = this.startingRecord + 1;
    }    
}