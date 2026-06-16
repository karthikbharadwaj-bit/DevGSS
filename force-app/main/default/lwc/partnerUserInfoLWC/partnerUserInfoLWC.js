import { LightningElement, wire, track} from 'lwc';
import getUserInfo from '@salesforce/apex/partnerUserInfoLWCController.getUserInfo';
import Id from '@salesforce/user/Id';
export default class PartnerUserInfoLWC extends LightningElement {
    //<T1>*******************
    @track result = [];
    
    tableReload;    
    @wire(getUserInfo, { Id: Id }) 
    partnerUser({data}){
        if(data){            
            this.result = data;
            console.log('data - ' + JSON.stringify(data));
            console.log('data home result - ' + data);
        }
    }

    get pageWrap() {
        return this.result.isIgnite ? 'partneruserinfowrap' : '';
    } 
}