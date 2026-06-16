import { api, LightningElement, track } from 'lwc';
const hostname = window.location.hostname; 

export default class smartSearchEcommerceInfo extends LightningElement {
    @api rcAccount;
    @api newLead;
    @track accFound = false;
    accUrl;
    
    textBoxValues = {
        rcAccountName: 'No account found',
        rcAccountUserId: '',
        rcAccountStatus: '',
        userType: '',
        tier: '',
        plan: '',
        signupType: '',
        trial: '',
        numberOfLines: '',
        totSalesPrice: '',
        recSalesPrice: '',
        product: '',
        ltv: ''
    };
    showSection = false;
    icon = 'utility:right';

    @api
    showEcommerceSection() {
        this.showSection = !this.showSection;
        if (this.showSection) {
            this.icon = 'utility:down';
        } else {
            this.icon = 'utility:right';
        }
    }

    handleInputChange(event) {
        this.textBoxValues[event.target.name] = event.target.value;
        console.log(this.textBoxValues);
    }

    redirectToAcc() {
        if (this.rcAccount && this.rcAccount.Id) {
            let url = `https://${hostname}/` + this.rcAccount.Id ;
            window.open(url, "_self");
        }
    }

    @api
    populateEcommerceValues(userId) {
        if (this.newLead) {
            this.textBoxValues.userType = this.newLead.User_Type__c;
            this.textBoxValues.tier = this.newLead.Tier__c;
            this.textBoxValues.plan = this.newLead.Plan__c;
            this.textBoxValues.signupType = this.newLead.Signup_Type__c;
            this.textBoxValues.trial = this.newLead.Trial__c;
            this.textBoxValues.numberOfLines = this.newLead.Number_of_Lines__c;
            this.textBoxValues.totSalesPrice = this.newLead.Total_Sales_Price__c;
            this.textBoxValues.recSalesPrice = this.newLead.Recurring_Sales_Price__c;
            this.textBoxValues.product = this.newLead.Product_Ecomm__c;
            this.textBoxValues.ltv = this.newLead.LTV__c;
        }
        if (this.rcAccount && this.rcAccount != '') {
            this.accFound = true;
            this.accUrl = `https://${hostname}/` + this.rcAccount.Id ;
            this.textBoxValues.rcAccountName = this.rcAccount.Name;
            this.textBoxValues.rcAccountUserId = this.rcAccount.RC_User_ID__c;
            this.textBoxValues.rcAccountStatus = this.rcAccount.RC_Account_Status__c;
        } else {
            this.textBoxValues.rcAccountUserId = userId;
        }
    }

    set newLead(value) {
        this.newLead = value;
    }
}