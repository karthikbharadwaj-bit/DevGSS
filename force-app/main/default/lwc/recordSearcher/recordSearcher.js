import { LightningElement , track} from 'lwc';
import getAccountsByName  from '@salesforce/apex/recordSearchController.getAccountsByName' ;
import getContactsByName  from '@salesforce/apex/recordSearchController.getContactsByName' ;
import getOpportunitiesByName  from '@salesforce/apex/recordSearchController.getOpportunitiesByName' ;


const CONTACT_COL = [
    {
        label: 'Name',
        fieldName: 'Name',
        type: 'text',
        sortable: true
    },
    {
        label: 'Account Name',
        fieldName: 'AccountName',
        type: 'text',
        sortable: false
    },

    ]
const ACCOUNT_COL = [
    {
    label: 'Account Name',
    fieldName: 'Name',
    type: 'text',
    sortable: true
    },
    {
    label: 'Service Name',
    fieldName: 'RC_Service_name__c',
    type: 'text',
    sortable: false
    },
    {
    label: 'Account Owner',
    fieldName: 'OwnerName',
    type: 'text',
    sortable: false
    },
    {
    label: 'Current Owner',
    fieldName: 'CurrentOwner',
    type: 'text',
    sortable: false
    },
    {
    label: 'Account Status',
    fieldName: 'RC_Account_Status__c',
    type: 'text',
    sortable: false
    },
    {
    label: 'Account Record Type',
    fieldName: 'AccountRecordType',
    type: 'text',
    sortable: false
    },
    
    {
        label: 'Partner Account',
        fieldName: 'PartnerAccount',
        type: 'text',
        sortable: false
    },
    {
        label: 'Number of DLs',
        fieldName: 'Number_of_DL_s__c',
        type: 'number',
        sortable: false
    },
    {	
        type: 'action',
        typeAttributes: { rowActions: [{ label: 'View Account Hierarchy', name: 'Account Hierarchy' }]},
    },
];
const OPPORTUNITY_COL = [
    {
        label: 'Opportunity Name',
        fieldName: 'Name',
        type: 'text',
        sortable: true
    },
    {
        label: 'Account Name',
        fieldName: 'AccountName',
        type: 'text',
        sortable: false
    },
    {
        label: 'Opportunity Owner',
        fieldName: 'OwnerName',
        type: 'text',
        sortable: false
    },
    {
        label: 'Account Owner',
        fieldName: 'AccountOwnerName',
        type: 'text',
        sortable: false
    },
    {
        label: 'Close Date',
        fieldName: 'CloseDate',
        type: 'Date',
        sortable: false
    },
    {
        label: 'Stage',
        fieldName: 'StageName',
        type: 'Text',
        sortable: false
    },

    
];
export default class RecordSearcher extends LightningElement {

    @track accountRecords = {columnName : 'Accounts', columns : ACCOUNT_COL, data :[], isloading : false, };
    @track contactRecords = {columnName : 'Contacts',columns : CONTACT_COL, data :[],isloading : false, };
    @track opportunityRecords = {columnName : 'Opportunity', columns : OPPORTUNITY_COL, data :[],isloading : false, };
    @track error;
    searchTerm = '';
    isLoading = false;
    onChangeInput =null;

    currentRecordId = '';
    isModalOpen = false;

    get disableButton(){
        return (this.onChangeInput==null ||this.onChangeInput=='' || this.onChangeInput.length <3 || this.isLoading );
    }


   
    handleChangeSearchTerm(event){
        this.onChangeInput =event.target.value;
    }
   
    handleClick(){
        this.error = '';
        const searchTermElement = this.template.querySelector("lightning-input") ? this.template.querySelector("lightning-input").value :'';
        if(searchTermElement!='' && searchTermElement!=this.searchTerm){
            this.searchTerm = this.escapeSpecialCharacters(searchTermElement);
            console.log('searchTermElement :'+searchTermElement);
            console.log('this.searchTerm :'+this.searchTerm);
            /*Set Loading Label */
            this.contactRecords.data=[];this.contactRecords.columnName = 'Contacts (loading)';
            this.accountRecords.data=[];this.accountRecords.columnName = 'Accounts (loading)';
            this.opportunityRecords.data=[];this.opportunityRecords.columnName = 'Opportunity (loading)';
            /*Apex call for accounts, contacts, opportunities */
            this.getAccountResults();
            this.getContactResults();
            this.getOpportunityResults();

            this.onChangeInput == '';
        }
    }
    handleRowAction(event){
        this.currentRecordId = event.detail.data;
        this.isModalOpen = true;
    }
    closeModal(){
         this.isModalOpen = false;
    }

    getAccountResults(){
        this.accountRecords.isloading = true;
        getAccountsByName({ searchTerm: this.searchTerm })
            .then(data => {
                let accounts = { data: [] };
                for (let val of data) {
                    accounts.data.push({
                        OwnerName: (val.Owner && val.Owner.Name) ? val.Owner.Name : '',
                        AccountRecordType: (val.RecordType && val.RecordType.Name) ? val.RecordType.Name : '',
                        PartnerAccount: (val && val.Partner_Account__r && val.Partner_Account__r.Name) ? val.Partner_Account__r.Name : '',
                        CurrentOwner: (val && val.Current_Owner__r && val.Current_Owner__r.Name) ? val.Current_Owner__r.Name : '', ...val
                    });
                }
                accounts.columns = ACCOUNT_COL;
                accounts.columnName = 'Accounts (' + accounts.data.length + ')';
                this.accountRecords = accounts;
                this.accountRecords.isloading = false;
            })
            .catch(error => {
                this.accountRecords.error = error;
                this.accountRecords.isloading = false;
                console.log(error);
            })
        
    }
    getContactResults(){
        this.contactRecords.isloading = true;
        
        getContactsByName({ searchTerm: this.searchTerm })
            .then(data => {
                let contacts = { data: [] };
                for (let val of data) {
                    contacts.data.push({  AccountName: (val.Account && val.Account.Name) ? val.Account.Name : '', OwnerName: (val.Owner && val.Owner.Name) ? val.Owner.Name : '', AccountOwnerName: (val.Account && val.Account.Owner_Name__c) ? val.Account.Owner_Name__c : '', ...val });
                   
                }
                contacts.columns = CONTACT_COL;
                contacts.columnName = 'Contacts (' + contacts.data.length + ')';
                this.contactRecords = contacts;
                this.contactRecords.isloading = false;
            })
            .catch(error => {
                this.contactRecords.error = error;
                this.contactRecords.isloading = false;
                console.log(error);
            })
        
    }
    getOpportunityResults(){
        this.opportunityRecords.isloading = true;
        getOpportunitiesByName({ searchTerm: this.searchTerm })
            .then(data => {
                try{
                let opportunities = { data: [] };
                for (let val of data) {
                    opportunities.data.push({  AccountName: (val.Account && val.Account.Name) ? val.Account.Name : '', OwnerName: (val.Owner && val.Owner.Name) ? val.Owner.Name : '', AccountOwnerName: (val.Account && val.Account.Owner_Name__c) ? val.Account.Owner_Name__c : '', ...val });
                    
                }
                opportunities.columns = OPPORTUNITY_COL;
                opportunities.columnName = 'Opportunity (' + opportunities.data.length + ')';
                this.opportunityRecords = opportunities;
                this.opportunityRecords.isloading = false;
                }catch(ex){console.log('Opportunity',ex)};
            })
            .catch(error => {
                this.opportunityRecords.error = error;
                this.opportunityRecords.isloading = false;
                console.log(error);
            })
    }
    escapeSpecialCharacters(s) {
        s = s.replace(/[/]/g, '\\$&');
	    return s.replace(/[-[\]{}()*+?&!~:"'\\^|]/g, '\\$&');
    }

}