import { LightningElement,wire } from 'lwc';
import getImplementationStatus from '@salesforce/apex/ImplementationStatus2LWCController.getImplementationStatus';

const columns = [
    {label:'Status',fieldName:'MasterLabel',type:'text',hideDefaultActions:true},
    {label:'Definition',fieldName:'Definition__c',type:'text',hideDefaultActions:true,wrapText:true}
];

export default class HelloWorldLWC extends LightningElement {

    columns = columns;
    records;
    error;

    @wire(getImplementationStatus)
    statusRecords(value){

        const {data,error} = value;
        
        if(data){
            this.records = data;
        }
        else if(error){
            console.log('Error in loading custom metadatatype records' + error);
            this.error = error;
        }
    }

}