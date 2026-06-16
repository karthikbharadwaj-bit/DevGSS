import { LightningElement, track, api , wire} from 'lwc';
import getHierarchy  from '@salesforce/apex/recordSearchController.findHierarchyData' ;

const ACCOUNT_COL = [
    {
    label: 'Name',
    initialWidth: 300,
    fieldName: 'AccountName',
    type: 'text',
    sortable: false,
    },  
    {
    label: 'Service Name',
    fieldName: 'RC_Service_name__c',
    type: 'text',
    sortable: false
    },
    {
    label: 'Account Owner Name',
    fieldName: 'OwnerName',
    type: 'text',
    
    sortable: false
    },
    {
    label: 'Account Status',
    fieldName: 'RC_Account_Status__c',
    type: 'text',
    initialWidth: 100,
    sortable: false
    },
    {
    label: 'Record Type',
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
];
export default class AccountHierarchyTable extends LightningElement {
@track gridColumns =ACCOUNT_COL;
@track gridExpandedRows = [];
@track gridData = [];
@api recid;
@track isLoading = true;
@wire (getHierarchy, { recId: '$recid' })
wiredAccountHierarchyData({ error, data }) {
    if (data) {
        var expandedRows = [];
        var apexResponse = this.refactorResult(data);
        var roles = {};
        console.log('*******apexResponse:'+JSON.stringify(apexResponse));
        var results = apexResponse;
        roles[undefined] = { Name: "Root", _children: [] };
        apexResponse.forEach((v)=> {
            expandedRows.push(v.Id);
            roles[v.Id] = { 
                AccountName:  v.Id==this.recid ?v.Name + '  **( Current )**' :v.Name ,
                name: v.Id,
                RC_Service_name__c: v.RC_Service_name__c, 
                RC_Account_Status__c:v.RC_Account_Status__c,
                OwnerName : v.OwnerName,
                AccountRecordType : v.AccountRecordType,
                PartnerAccount : v.PartnerAccount,
                colorClass : 'slds-text-link',
                 };
        });
        console.log(roles);
        apexResponse.forEach(function(v) {
            //expandedRows.push(v.ParentId);
            //if(roles[v.ParentId]._children)
            if(roles[v.ParentId]._children==undefined){
                roles[v.ParentId]._children = [];
            }
            roles[v.ParentId]._children.push(roles[v.Id]);  
        });                
        this.gridData =  roles[undefined]._children;
        this.gridExpandedRows = expandedRows;
        //console.log('*******treegrid data:'+JSON.stringify(roles[undefined]._children));
        console.log('GRID')
        console.log(this.gridData);
        var delayInMilliseconds = 1000; //1 second

        setTimeout(()=> {
            const grid =  this.template.querySelector('lightning-tree-grid');
            grid.expandAll();

        }, delayInMilliseconds);
        this.isLoading = false;
    } else if (error) {
        this.error = error;
        this.isLoading =false;
        console.log(error);
    }
}

refactorResult(result){
    let finalRes = [];
    for(let val of result){
        finalRes.push({ OwnerName :  (val.Owner && val.Owner.Name)? val.Owner.Name : '', AccountRecordType : (val.RecordType && val.RecordType.Name)  ? val.RecordType.Name : '', PartnerAccount : (val && val.Partner_Account__r && val.Partner_Account__r.Name) ? val.Partner_Account__r.Name: '', ...val });
    }
    return finalRes;
}
}