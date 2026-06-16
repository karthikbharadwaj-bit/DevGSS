/* eslint-disable no-debugger */
/* eslint-disable no-undef */
/* eslint-disable no-console */
import { LightningElement, wire, track,api  } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { loadScript } from "lightning/platformResourceLoader";
import XLSXRES from "@salesforce/resourceUrl/xlsx";
import { updateRecord } from 'lightning/uiRecordApi';

const ERROREXCELDATACOLS = [  
    { label: 'Id', fieldName: 'Id',  initialWidth: 300 },
    { label: 'Segment', fieldName: 'Marketo_Segment_Name__c' ,  sortable:true , initialWidth: 150 },
];

export default class CdaMarketoQueue extends LightningElement {



    @track selectedFile;
    @track excelDataErrors = [];
    @track excelDataErrors2 = [];
    @track exceldataerrorcolums = ERROREXCELDATACOLS;
    @track numberOfRows = 0;
    @track progress = 0;

    isProgressing = false;

    processMarketoQueue () {


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
                JSON.parse(jsonObject).forEach (item => {
                    // console.log(item);
                    
                    const fields = {};
                    fields['Id'] = item.Id;
                    console.log('Marketo_Sync_Disabled__c ' + item.Marketo_Sync_Disabled__c);
                    if (item.Marketo_Sync_Disabled__c != undefined)
                      fields['Marketo_Sync_Disabled__c'] = item.Marketo_Sync_Disabled__c;

                    
                    const recordInput = {fields };

                    
                   console.log(JSON.stringify(recordInput));

                    updateRecord(recordInput)
                            .then(requestItem => {
                                 this.progress = this.progress === this.numberOfRows ? 0 : this.progress + 1;  
                                 console.log('Record Processed Successfully');                        
                            })
                            .catch(error => {
                              console.log('Record Processed in Error'); 
                              this.progress = this.progress === this.numberOfRows ? 0 : this.progress + 1;
                          });
                       
                });


              });
  
          });
  
            this.fileReader.readAsBinaryString(this.selectedFile);

            this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Success!!',
                            message: 'The Excel File you provided has been successfully queued and awaiting processing. Please wait until the number of records processed are refreshed.',
                            variant: 'success',
                        }),
                    );
           
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