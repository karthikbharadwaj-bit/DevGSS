import { LightningElement, track, wire, api } from "lwc";  
 import findRecords from "@salesforce/apex/LwcLookupController.findRecords";  
 export default class LwcLookup extends LightningElement {  
  @track recordsList;  
  @track searchKey = "";  
  @track selectedRecord = "";
  @api fields="";
  @api selectedValue;  
  @api selectedRecordId;  
  @api objectApiName;  
  @api iconName;  
  @api lookupLabel;  
  @track message;  
    
  onLeave(event) {  
   setTimeout(() => {  
    this.searchKey = "";  
    this.recordsList = null;  
   }, 300);  
  }  
    
  onRecordSelection(event) {  
   const current = this;
   current.selectedRecordId = event.target.dataset.key;  
   current.selectedValue = event.target.dataset.name;
   const selectedRecord = current.recordsList.filter(function(record,index) {
		if (record.Id === current.selectedRecordId) {
			return record;
		}
   });
   if (selectedRecord && selectedRecord.length > 0) {
	current.selectedRecord = selectedRecord[0];
   }
   this.searchKey = "";  
   this.onSeletedRecordUpdate();  
  }  
   
  handleKeyChange(event) {  
   const searchKey = event.target.value;  
   this.searchKey = searchKey;  
   this.getLookupResult();  
  }  
   
  removeRecordOnLookup(event) {  
   this.searchKey = "";  
   this.selectedValue = null;  
   this.selectedRecordId = null;  
   this.recordsList = null;  
   this.onSeletedRecordUpdate();  
 }  
 getLookupResult() {  
	findRecords({ searchKey: this.searchKey, objectName : this.objectApiName, fields: this.fields })  
	 .then((result) => {  
	  if (result.length===0) {  
		this.recordsList = [];  
		this.message = "No Records Found";  
	   } else {  
		this.recordsList = result;  
		this.message = "";  
	   }  
	   this.error = undefined;  
	 })  
	 .catch((error) => {  
	  this.error = error;  
	  this.recordsList = undefined;  
	 });  
   }  
	
   onSeletedRecordUpdate(){  
	const passEventr = new CustomEvent('recordselection', {  
	  detail: { 
		  selectedRecordId: this.selectedRecordId, 
		  selectedValue: this.selectedValue,
		  selectedRecord: this.selectedRecord

		}  
	 });  
	 this.dispatchEvent(passEventr);  
   }  
  }