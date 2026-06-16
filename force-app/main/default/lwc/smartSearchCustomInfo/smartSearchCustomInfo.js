import { LightningElement, track, api, wire } from 'lwc'; 
import getLeadSourceValuesForNewLead from '@salesforce/apex/SmartSearchForLwc.getLeadSourceValuesForNewLead';

const showRedBox = "slds-m-top_small slds-has-error";
const hideRedBox = "slds-m-top_small";

export default class SmartSearchCustomInfo extends LightningElement {
    @track textValues = {
        inContactDNIS: "", 
        inContactContactId: "",
        inContactSkill: "",
        campaignName: "",
        campaignProduct: "",
        campaignDescription: "",
        requiredFieldMessage: "This field is required, please enter a value.",
        leadSourcePlaceHolder: ""
    };
    @track
    textBoxValues = {
        firstName: "",
        lastName: "",
        titleN: "", 
        companyName: "",
        email: "",
        contactPhoneNumber: "", 
        leadSource: "",
        salesGeneratedSource: "",
        supportAgentEmailAddress: "", 
        leadStatus: ""
    };
    @track leadSourceIsSalesGenerated = false;
    @api recordTypeId;
    @track items = [];
    lastNameRedBox = hideRedBox;
    showLastNameErrorMsg = false;
    companyNameRedBox = hideRedBox;
    showCompanyNameErrorMsg = false;
    emailRedBox = hideRedBox;
    showEmailErrorMsg = false;
    leadSourceRedBox = hideRedBox;
    showLeadSourceErrorMsg = false;
    isLoadingPicklist = false;

    @wire(getLeadSourceValuesForNewLead)
    wiredLeadSourceValues({ error, data }) {
        let itemsTemp  = [];
        let key;
        if (data) {
            itemsTemp.push({
                label: '--None--',
                value: '',
                selected: true
            });
            for (key in data) {
                itemsTemp.push({
                    label: data[key],
                    value: data[key]
                });                         
            } 
            this.items = itemsTemp ;               
            this.error = undefined;
        } else if (error) {
            this.error = error;
        }
    }
    get leadSourceValues() {
        return this.items;
    }

    handleInputChange(event) {
        this.textBoxValues[event.target.name] = event.target.value;
    }

    get saleGeneratedSources() {
        let itemsTemp  = [];
        itemsTemp.push({
            label: '--None--',
            value: 'None'
        });
        itemsTemp.push({
            label: 'Data.com',
            value: 'Data.com'
        });
        itemsTemp.push({
            label: 'Facebook',
            value: 'Facebook'
        });
        itemsTemp.push({
            label: 'Field Event',
            value: 'Field Event'
        });
        itemsTemp.push({
            label: 'LeadSpace',
            value: 'LeadSpace'
        });
        itemsTemp.push({
            label: 'LinkedIn',
            value: 'LinkedIn'
        });
        itemsTemp.push({
            label: 'RainKing',
            value: 'RainKing'
        });
        itemsTemp.push({
            label: 'Rolodex',
            value: 'Rolodex'
        });
        itemsTemp.push({
            label: 'Tradeshow',
            value: 'Tradeshow'
        });
        itemsTemp.push({
            label: 'Twitter',
            value: 'Twitter'
        });
        itemsTemp.push({
            label: 'Website',
            value: 'Website'
        });
        return itemsTemp;
    }

    handleChangePicklistSalesGenerated(event) {
        this.textBoxValues.salesGeneratedSource = event.detail.value;
    }

    handleChangePicklist(event) {
        this.textValues.leadSourcePlaceHolder = event.detail.value;
        this.textBoxValues.leadSource = event.detail.value;
        this.leadSourceRedBox = hideRedBox;
        this.showLeadSourceErrorMsg = false;
        if (event.detail.value === 'Sales Generated') {
            this.leadSourceIsSalesGenerated = true;
        } else {
            this.leadSourceIsSalesGenerated = false;
            this.textBoxValues.salesGeneratedSource = ''
        }
    }

    handleLastName(event) {
        if (event.target.value !== "") {
            this.lastNameRedBox = hideRedBox;
            this.showLastNameErrorMsg = false;
        }
        this.textBoxValues.lastName = event.target.value;
    }

    handleCompanyName(event) {
        if (event.target.value !== "") {
            this.companyNameRedBox = hideRedBox;
            this.showCompanyNameErrorMsg = false;
        }
        this.textBoxValues.companyName = event.target.value;
    }

    handleEmail(event) {
        if (event.target.value !== "") {
            this.emailRedBox = hideRedBox;
            this.showEmailErrorMsg = false;
        }
        this.textBoxValues.email = event.target.value;
    }
    
    @api 
    get firstName() {
        return this.textBoxValues.firstName;
    }

    @api 
    get lastName() {
        return this.textBoxValues.lastName;
    }

    @api 
    get title() {
        return this.textBoxValues.titleN;
    }

    @api 
    get companyName() {
        return this.textBoxValues.companyName;
    }
    
    @api 
    get email() {
        return this.textBoxValues.email;
    }
    
    @api 
    get contactPhoneNumber() {
        return this.textBoxValues.contactPhoneNumber;
    }
    
    @api 
    get leadSource() {
        return this.textBoxValues.leadSource;
    }

    @api 
    get inContactDNIS() {
        return this.textValues.inContactDNIS;
    }

    @api 
    get inContactContactId() {
        return this.textValues.inContactContactId;
    }

    @api 
    get inContactSkill() {
        return this.textValues.inContactSkill;
    }

    @api 
    get campaignName() {
        return this.textValues.inContactSkill;
    }
    
    @api 
    get campaignProduct() {
        return this.textValues.campaignProduct;
    }
    
    @api 
    get campaignDescription() {
        return this.textValues.campaignDescription;
    }
    
    @api 
    get supportAgentEmailAddress() {
        return this.textBoxValues.supportAgentEmailAddress;
    }

    @api 
    get dnis() {
        return this.textValues.inContactDNIS;
    }

    @api 
    setdnis(value) {
        this.textValues.inContactDNIS = value;
    }

    @api 
    setcid(value) {
        this.textValues.inContactContactId = value;
    }

    @api 
    get cid() {
        return this.textValues.inContactContactId;
    }

    @api 
    setskill(value) {
        this.textValues.inContactSkill = value;
    }

    @api 
    get skill() {
        return this.textValues.inContactSkill;
    }

    @api
    setCampaignName(value) {
        this.textValues.campaignName = value;
    }

    @api
    setCampaignProduct(value) {
        this.textValues.campaignProduct = value;
    }

    @api
    setCampaignDescription(value) {
        this.textValues.campaignDescription = value;
    }

    @api
    setLeadSource(value) {
        let newTextBoxValues = {
            firstName: this.textBoxValues.firstName,
            lastName: this.textBoxValues.lastName,
            titleN: this.textBoxValues.titleN, 
            companyName: this.textBoxValues.companyName,
            email: this.textBoxValues.email,
            contactPhoneNumber: this.textBoxValues.contactPhoneNumber, 
            leadSource: value,
            salesGeneratedSource: this.textBoxValues.salesGeneratedSource,
            supportAgentEmailAddress: this.textBoxValues.supportAgentEmailAddress, 
            leadStatus: this.textBoxValues.leadStatus
        };
        const leadSourceSelect = this.template.querySelector('[data-id="lead-select"]');
        if (leadSourceSelect) {
            leadSourceSelect.value = value;
            this.textBoxValues = newTextBoxValues;
        }    
        if (value === 'Sales Generated') {
            this.leadSourceIsSalesGenerated = true;
        }
    }

    @api 
    setPhoneNumber(value) {
        let newTextBoxValues = {
            firstName: this.textBoxValues.firstName,
            lastName: this.textBoxValues.lastName,
            titleN: this.textBoxValues.titleN, 
            companyName: this.textBoxValues.companyName,
            email: this.textBoxValues.email,
            contactPhoneNumber: value, 
            leadSource: this.textBoxValues.leadSource,
            salesGeneratedSource: this.textBoxValues.salesGeneratedSource,
            supportAgentEmailAddress: this.textBoxValues.supportAgentEmailAddress, 
            leadStatus: this.textBoxValues.leadStatus
        };
        this.textBoxValues = newTextBoxValues;
    }
    @api
    setLastName(value){
        let newTextBoxValues = {
            firstName: this.textBoxValues.firstName,
            lastName: value,
            titleN: this.textBoxValues.titleN, 
            companyName: this.textBoxValues.companyName,
            email: this.textBoxValues.email,
            contactPhoneNumber: this.textBoxValues.contactPhoneNumber, 
            leadSource: this.textBoxValues.leadSource,
            salesGeneratedSource: this.textBoxValues.salesGeneratedSource,
            supportAgentEmailAddress: this.textBoxValues.supportAgentEmailAddress, 
            leadStatus: this.textBoxValues.leadStatus
        };
        this.textBoxValues = newTextBoxValues;
    }

    @api
    setFirstName(value){
        let newTextBoxValues = {
            firstName: value,
            lastName: this.textBoxValues.lastName,
            titleN: this.textBoxValues.titleN, 
            companyName: this.textBoxValues.companyName,
            email: this.textBoxValues.email,
            contactPhoneNumber: this.textBoxValues.contactPhoneNumber, 
            leadSource: this.textBoxValues.leadSource,
            salesGeneratedSource: this.textBoxValues.salesGeneratedSource,
            supportAgentEmailAddress: this.textBoxValues.supportAgentEmailAddress, 
            leadStatus: this.textBoxValues.leadStatus
        };
        this.textBoxValues = newTextBoxValues;
    }

    @api
    setEmail(value){
        let newTextBoxValues = {
            firstName: this.textBoxValues.firstName,
            lastName: this.textBoxValues.lastName,
            titleN: this.textBoxValues.titleN, 
            companyName: this.textBoxValues.companyName,
            email: value,
            contactPhoneNumber: this.textBoxValues.contactPhoneNumber, 
            leadSource: this.textBoxValues.leadSource,
            salesGeneratedSource: this.textBoxValues.salesGeneratedSource,
            supportAgentEmailAddress: this.textBoxValues.supportAgentEmailAddress, 
            leadStatus: this.textBoxValues.leadStatus
        };
        this.textBoxValues = newTextBoxValues;
    }

    @api
    get salesGeneratedSource() {
        return this.textBoxValues.salesGeneratedSource;
    }

    @api
    handleScrollToDiv(message) {
        const toDiv = this.template.querySelector('[data-id="' + message.data + '"]');
        toDiv?.scrollIntoView({behavior: "smooth", block: "start", inline: "nearest"});
    }

    @api
    handleErrorBoxes() {
        if (this.textBoxValues.lastName === "") {
            this.lastNameRedBox = showRedBox;
            this.showLastNameErrorMsg = true;
        } else {
            this.lastNameRedBox = hideRedBox;
            this.showLastNameErrorMsg = false;
        }
        if (this.textBoxValues.companyName === "") {
            this.companyNameRedBox = showRedBox;
            this.showCompanyNameErrorMsg = true;
        } else {
            this.companyNameRedBox = hideRedBox;
            this.showCompanyNameErrorMsg = false;
        }
        if (this.textBoxValues.email === "") {
            this.emailRedBox = showRedBox;
            this.showEmailErrorMsg = true;
        } else {
            this.emailRedBox = hideRedBox;
            this.showEmailErrorMsg = false;
        }
        if (this.textBoxValues.leadSource === "") {
            this.leadSourceRedBox = showRedBox;
            this.showLeadSourceErrorMsg = true;
        } else {
            this.leadSourceRedBox = hideRedBox;
            this.showLeadSourceErrorMsg = false;
        }
    }
}