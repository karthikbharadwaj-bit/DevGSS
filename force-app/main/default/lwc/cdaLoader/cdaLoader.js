/* eslint-disable no-debugger */
/* eslint-disable no-undef */
/* eslint-disable no-console */
import { LightningElement, wire, track,api  } from 'lwc';
// import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { loadScript } from "lightning/platformResourceLoader";
import XLSXRES from "@salesforce/resourceUrl/xlsx";
import { updateRecord } from 'lightning/uiRecordApi';
import {refreshApex} from '@salesforce/apex';

const ERROREXCELDATACOLS = [  
    { label: 'Id', fieldName: 'Id',  initialWidth: 300 },
    { label: 'Segment', fieldName: 'Marketo_Segment_Name__c' ,  sortable:true , initialWidth: 150 },
];

export default class CdaLoader extends LightningElement {



    @track selectedFile;
    @track excelDataErrors = [];
    @track excelDataErrors2 = [];
    @track exceldataerrorcolums = ERROREXCELDATACOLS;
    @track numberOfRows = 0;
    @track progress = 0;

    isProgressing = false;

    processAccountSegmnentation () {


        var data;
        var workbook;

        
        if (this.selectedFile) {
          
          this.fileReader= new FileReader();
  
          // set onload function of FileReader object  
          this.fileReader.onload = (() => {
              this.fileContents = this.fileReader.result;
  
              data = this.fileReader.result;
    
              workbook = XLSX.read(data, {
                type: "binary"
              });
  
  
              workbook.SheetNames.forEach(sheet => {
                let rowObject = XLSX.utils.sheet_to_row_object_array(
                  workbook.Sheets[sheet]
                );
                let jsonObject = JSON.stringify(rowObject);
                // console.log(JSON.stringify(jsonObject));

                // console.log('Excel Data (In Loop): ' + JSON.stringify(this.excelData));
                JSON.parse(jsonObject).forEach (item => {
                     this.numberOfRows = this.numberOfRows + 1;
                });
                
                console.log ('Number of Records : ' + this.numberOfRows);
                // var d = Date.now();
                // console.log( d.toLocaleString() ); 
									
								let processed = 0; 

                // let recordInputs = [];
							  let promises = [];
                let promiseMaster = [];
                JSON.parse(jsonObject).forEach (item => {
                    // console.log(item);
                    processed = processed + 1 ;
                    const fields = {};
                    fields['Id'] = item.Id;
                    // fields['Emp_Range_Sales_Override__c']  = item.Emp_Range_Sales_Override__c;
                    // fields['Account_Grade__c']  = item.Account_Grade__c;
                    // fields['BillingCountry']  = item.BillingCountry;
                    // fields['Emp_Range_Sales_Override__c']  = item.Emp_Range_Sales_Override__c;
                    // fields['Ideal_Customer_Profile__c']  = item.Ideal_Customer_Profile__c;
                    // fields['Industry']  = item.Industry;
                    fields['Marketo_Queue_ID__c']  = item.Marketo_Queue_ID__c;
                    // fields['Marketo_Segment_Name__c']  = item.Marketo_Segment_Name__c;
                    // fields['Multinational_Ultimate__c']  = item.Multinational_Ultimate__c;
                    // fields['NumberOfEmployees']  = item.NumberOfEmployees;
                    // fields['Owner']  = item.Owner;
                    // fields['Sector__c']  = item.Sector__c;
                    // fields['Sub_Industry__c']  = item.Sub_Industry__c;
                    // fields['Technology_Stack_Cloud__c']  = item.Technology_Stack_Cloud__c;
                    // fields['Technology_Stack_Collaboration__c ']  = item.Technology_Stack_Collaboration__c ;
                    // fields['Technology_Stack_Conference__c']  = item.Technology_Stack_Conference__c;
                    // fields['Technology_Stack_Contact_Center__c']  = item.Technology_Stack_Contact_Center__c;
                    // fields['Technology_Stack_Telco__c']  = item.Technology_Stack_Telco__c;
                    // fields['Top_Target__c']  = item.Top_Target__c;
                    // fields['Ultimate_Account__c']  = item.Ultimate_Account__c;
                    // fields['Ultimate_Parent_Territory__c']  = item.Ultimate_Parent_Territory__c;
                    // fields['ZI_CDP_Account_Id__c']  = item.ZI_CDP_Account_Id__c;
                    // fields['ZI_Family_URL__c']  = item.ZI_Family_URL__c;
                    // fields['ShippingCountry']  = item.ShippingCountry;
                    // fields['ZI_Country__c']  = item.ZI_Country__c;
                    // fields['LS_Country__c']  = item.LS_Country__c;
                    // fields['Domestic_HQ_Country__c']  = item.Domestic_HQ_Country__c;
                    // fields['Customer_Country__c']  = item.Customer_Country__c;
                    // fields['Tax_Exempt__c']  = item.Tax_Exempt__c;
										fields['Ultimate_Account__c'] = item.Ultimate_Account__c;
                    
										let recordInput = {fields };
										promises.push(updateRecord(recordInput));
										if (processed%1===0 ) {
										//promiseMaster.push([...promises]);
										let tempPromises = [...promises];
										Promise.all([tempPromises])
										.then((results) => {
										// console.log(JSON.stringify(results));
												this.progress = this.progress === this.numberOfRows ? 0 : this.progress + 1;  
										console.log ('Record Processed');
										tempPromises = [];
										})
										.catch((e) => {
												this.progress = this.progress === this.numberOfRows ? 0 : this.progress + 1;  
										console.log("Record Errored", JSON.stringify(e));
										});
										promises=[];
										}
										// 
										// 
                    // console.log('Record Input : ' + JSON.stringify(recordInput)); 
                    // recordInputs = [];
                    // recordInputs.push(recordInput);
                    
                    // Calling the imperative Apex method with the JSON
                    // object as parameter.
                    // console.log('Account ID : ' + item.Id);
                    
                   console.log('Reading Records');

                  //  const promises = recordInputs.map(recordInput => updateRecord(recordInput));
                  //   Promise.all(promises).then(results => {
                  //       this.progress = this.progress === this.numberOfRows ? 0 : this.progress + 1;  
                  //       // console.log('Updated Account : ' + requestItem.id);  
                  //       console.log( `Created ${results.length} new release${results.length === 1 ? '' : 's'}.`);
                        
                  //   }).catch(error => {
                  //     console.log ('Error');
                  //     console.log((error));
                  //     this.progress = this.progress === this.numberOfRows ? 0 : this.progress + 1;   
                  //   });

//                     updateRecord(recordInput)
//                             .then(requestItem => {
//                                 //  console.log('Updated Account : ' + requestItem.id);  
//                                  this.progress = this.progress === this.numberOfRows ? 0 : this.progress + 1;  
//                                  console.log('Record Processed Successfully');                        
//                             })
//                             .catch(error => {
//                               console.log('Record Processed in Error'); 
//                               this.progress = this.progress === this.numberOfRows ? 0 : this.progress + 1;
//                               
//                           });
                       
                    // this.toggleProgress();
                    });

//                     const promises = recordInputs.map(recordInput => updateRecord(recordInput));
//                     Promise.all(promises).then(results => {
//                         this.progress = this.progress === this.numberOfRows ? 0 : this.progress + 1;  
//                         // console.log('Updated Account : ' + requestItem.id);  
//                         console.log( `Created ${results.length} new release${results.length === 1 ? '' : 's'}.`);
//                         
//                     }).catch(error => {
//                       console.log ('Error');
//                       console.log((error));
//                       this.progress = this.progress === this.numberOfRows ? 0 : this.progress + 1;   
//                     });

              });
  
          });
  
            this.fileReader.readAsBinaryString(this.selectedFile);

            // this.dispatchEvent(
            //             new ShowToastEvent({
            //                 title: 'Success!!',
            //                 message: 'The Excel File you provided has been successfully queued and awaiting processing. Please wait until the number of records processed are refreshed.',
            //                 variant: 'success',
            //             }),
            //         );
           
        }


    }

    handleFilesChange(event) { 
        // console.log ('File Changed ');
        this.selectedFile = event.target.files[0];
      }

    renderedCallback() {

        // console.log("renderedCallback xlsx");
        if (this.librariesLoaded) return;
        this.librariesLoaded = true;
        Promise.all([loadScript(this, XLSXRES)])
          .then(() => {
            // console.log("success");
          })
          .catch(error => {
            // console.log("failure");
          });


    }

    disconnectedCallback() {
      // it's needed for the case the component gets disconnected
      // and the progress is being increased
      // this code doesn't show in the example
      clearInterval(this._interval);
  }

}