import { LightningElement, track, wire, api } from 'lwc';
import { getPicklistValues, getObjectInfo } from 'lightning/uiObjectInfoApi';
import NOOFEMPLOYEESRANGE from '@salesforce/schema/Lead.NumberOfEmployees__c';
import NOOLOCATIONS from '@salesforce/schema/Lead.Number_of_Locations__c';
import INDUSTRY from '@salesforce/schema/Lead.Industry';
import LEAD_OBJECT from '@salesforce/schema/Lead';
import PARTNERREQUESTSOURCE from '@salesforce/schema/Lead.Partner_Request_Source__c';


const hostname = window.location.hostname;
const showRedBox = 'slds-has-error';

export default class smartSearchEcommerceInfo extends LightningElement {
    @track textBoxValues = {
        noOfEmployeesRange : '',
        noOfEmployees : '',
        noOfEmployeesNeedingPhones : '',
        noOfLocations : '',
        industry : '',
        website : '',
        requiredFieldMessage: "This field is required, please enter a value.",
        partnerRequestSource :''
    };

    @track industryValues = [];
    @track noOfEmployeesRangeValues = [];
    @track noOfLocationsValues = [];
    @track partnerRequestSourceValues = [];
    industryRedBox = '';
    showIndustryErrorMsg = false;
    employeeRangeRedBox
    showEmployeeRangeErrorMsg = false;
    rangeUrlParam;

    @track placeholders = {
        websitePlaceholder : "Website",
        NoOfEmployeesPlaceholder : "No. of Employees"
    };


    @wire(getObjectInfo, { objectApiName: LEAD_OBJECT })
    leadInfo;

    @wire(getPicklistValues,
        {
            recordTypeId: '$leadInfo.data.defaultRecordTypeId', 
            fieldApiName: NOOFEMPLOYEESRANGE
        }
    )
    getNoOfEmployeesRangeValues(result) {
        var rangeValues = [];
        var key;
        if (result.data) {
            rangeValues.push({ label: '--None--', value: '', selected: true });
            for (key in result.data.values) {
                if (result.data.values[key].label.localeCompare('100-4999') !== 0 ) {
                    rangeValues.push({ 
                        label: result.data.values[key].label,
                        value: result.data.values[key].value
                    });
                }
            }
            this.noOfEmployeesRangeValues = rangeValues;
            if (this.noOfEmployeesRangeValues.filter(e => e.value === this.rangeUrlParam).length > 0) {
                const startSelect = this.template.querySelector('[data-id="combobox-range"]');
                startSelect.value = this.rangeUrlParam;
                this.textBoxValues.noOfEmployeesRange = this.rangeUrlParam;
            }           
        } else if (result.error) {
            this.error = result.error;
        }
    }
    
    @wire(getPicklistValues,
        {
            recordTypeId: '$leadInfo.data.defaultRecordTypeId', 
            fieldApiName: NOOLOCATIONS
        }
    )
    getNoOfLocationsValues(result) {
        if (result.data) {
            this.noOfLocationsValues = [ { label: '--None--', value: '', selected: true }, ...result.data.values ];
        } else if (result.error) {
            this.error = result.error;
        }
    }
@wire(getPicklistValues,
        {
            recordTypeId: '$leadInfo.data.defaultRecordTypeId', 
            fieldApiName: PARTNERREQUESTSOURCE
        }
    )
    getPartnerRequestSourceValues(result) {
        if (result.data) {
            this.partnerRequestSourceValues = [ { label: '--None--', value: '', selected: true }, ...result.data.values ];
        } else if (result.error) {
            this.error = result.error;
        }
    }


    @wire(getPicklistValues,
        {
            recordTypeId: '$leadInfo.data.defaultRecordTypeId', 
            fieldApiName: INDUSTRY
        }
    )
    getIndustryValues(result) {
        if (result.data) {
            this.industryValues = [ { label: '--None--', value: '', selected: true }, ...result.data.values ];
        } else if (result.error) {
            this.error = result.error;
        }
    }

    handleChangePicklistNoOfEmployeesRange(event) {
        this.textBoxValues.noOfEmployeesRange = event.detail.value;
        this.employeeRangeRedBox = '';
        this.showEmployeeRangeErrorMsg = false;
    }

    handleChangePicklistNoOfLocations(event) {
        this.textBoxValues.noOfLocations = event.detail.value;
    }
    handleChangePicklistPartnerRequestSource(event) {
        this.textBoxValues.partnerRequestSource = event.detail.value;
    }
    handleChangePicklistIndustry(event) {
        this.textBoxValues.industry = event.detail.value;
        this.industryRedBox = '';
        this.showIndustryErrorMsg = false;
    }

    handleInputChange(event) {
        this.textBoxValues[event.target.name] = event.target.value;
        console.log(JSON.stringify(this.textBoxValues));
    }

    handleFocusOnWebsite() {
        var newPlaceholder = {
            websitePlaceholder : "",
            NoOfEmployeesPlaceholder : this.placeholders.NoOfEmployeesPlaceholder
        };
        this.placeholders = newPlaceholder;
    }
    
    handleFocusOnNoOfEmployees() {
        var newPlaceholder = {
            websitePlaceholder : this.placeholders.websitePlaceholder,
            NoOfEmployeesPlaceholder : ""
        };
        this.placeholders = newPlaceholder;
    }

    handleBlurOnNoOfEmployees() {
        var newPlaceholder = {
            websitePlaceholder : this.placeholders.websitePlaceholder,
            NoOfEmployeesPlaceholder : "No. of Employees"
        };
        this.placeholders = newPlaceholder;
    }
    
    handleBlurOnWebsite() {
        var newPlaceholder = {
            websitePlaceholder : "Website",
            NoOfEmployeesPlaceholder : this.placeholders.NoOfEmployeesPlaceholder
        };
        this.placeholders = newPlaceholder;
    }

    navigateToLinkedInPage(evt) {
        evt.preventDefault();
        evt.stopPropagation();
        let url = `https://${hostname}/apex/linkedInPage`;
        window.open(url);
    }

    navigateToDataDotCom(evt) {
        evt.preventDefault();
        evt.stopPropagation();
        this.urlDataDotComSearch = `https://${hostname}/DataDotComSearch`;
        let url = `https://${hostname}/DataDotComSearch`;
        window.open(url);
    }

    connectedCallback() {
        this.urlDataDotComSearch = `https://${hostname}/DataDotComSearch`;
    }

    @api
    setSelectedRange(val) {
        this.rangeUrlParam = val;
    }

    @api 
    get noOfEmployeesRange() {
        return this.textBoxValues.noOfEmployeesRange;
    }

    @api 
    get noOfEmployees() {
        return this.textBoxValues.noOfEmployees;
    }
    
    @api 
    get noOfEmployeesNeedingPhones() {
        return this.textBoxValues.noOfEmployeesNeedingPhones;
    }
    
    @api 
    get noOfLocations() {
        return this.textBoxValues.noOfLocations;
    }
    @api
    get partnerRequestSource(){
        return this.textBoxValues.partnerRequestSource;
    }
    @api 
    get industry() {
        return this.textBoxValues.industry;
    }
    
    @api 
    get website() {
        return this.textBoxValues.website;
    }

    @api
    handleScrollToDiv(message) {
        const toDiv = this.template.querySelector('[data-id="' + message.data + '"]');
        toDiv?.scrollIntoView({behavior: "smooth", block: "start", inline: "nearest"});
    }

    @api
    handleErrorBoxes() {
        if (this.textBoxValues.industry === "") {
            this.industryRedBox = showRedBox;
            this.showIndustryErrorMsg = true;
        } else {
            this.lastNameRedBox = '';
            this.showIndustryErrorMsg = false;
        }
        if (this.textBoxValues.noOfEmployeesRange === "") {
            this.employeeRangeRedBox = showRedBox;
            this.showEmployeeRangeErrorMsg = true;
        } else {
            this.employeeRangeRedBox = '';
            this.showEmployeeRangeErrorMsg = false;
        }
    }
}