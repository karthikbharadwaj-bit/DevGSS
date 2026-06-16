import { LightningElement, api, wire } from 'lwc';
import { getRelatedListRecords } from 'lightning/uiRelatedListApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent'
import { CloseActionScreenEvent } from 'lightning/actions';
import { NavigationMixin } from 'lightning/navigation';
import { encodeDefaultFieldValues } from 'lightning/pageReferenceUtils';
export default class NewBigWin extends NavigationMixin(LightningElement) {
    // _recordId;
    // error;
    records;
    @api recordId;
    showSpinner = true;
    primaryQuote = {};
    errorMessage = {};
    key_facts;
    solutions_components;
    acquisition_or_growth;
    partner_involved;
    negative_impact_on_business;
    
    @wire(getRelatedListRecords, {
        parentRecordId: '$recordId',
        relatedListId: 'Quotes',
        fields: ['Quote.Initial_Term_months__c','Quote.Special_Terms__c','Quote.Opportunity.StageName','Quote.Opportunity.Total_MRR__c','Quote.Opportunity.Forecasted_Users__c','Quote.Opportunity.Forecast_Contact_Center_Users__c','Quote.Opportunity.AccountId','Quote.Opportunity.Account.Industry','Quote.Opportunity.Account.Potential_CC_Users__c','Quote.Opportunity.Account.Total_Potential_Users__c','Quote.Opportunity.Account.Description','Quote.Opportunity.Account.SM_Employees__c','Quote.Opportunity.Account.Fortune_Classification__c','Quote.Opportunity.Account.Partner_Account__c','Quote.Opportunity.Account.Partner_Account__r.Name','Quote.Opportunity.Account.RC_Upgrade_Date__c','Quote.Opportunity.CW_Primary_Win_Reason__c','Quote.Opportunity.Why_did_we_win__c','Quote.Opportunity.CW_Who_did_we_replace__c','Quote.Opportunity.Inside_Sales_Rep__c','Quote.Opportunity.Partner_Account__c','Quote.Opportunity.SDR_Agents__c','Quote.Opportunity.Sales_Engineer__c','Quote.Opportunity.STC_Current_Situation__c','Quote.Opportunity.STC_Ideal_Situation__c','Quote.Opportunity.STC_Problems__c','Quote.Opportunity.Glip_AE_Headshot__c','Quote.isPrimary__c','Quote.RecordType.Name','Quote.Opportunity.Is_Billing_Opportunity__c','Quote.Opportunity.Segment_Name__c','Quote.Opportunity.UCaaS_Incumbent_s__c','Quote.Opportunity.CC_Incumbent_s__c','Quote.Opportunity.UCaaS_Competitor_s__c','Quote.Opportunity.CC_Competitor_s__c','Quote.Opportunity.Video_Competition__c','Quote.Opportunity.White_Space__r.Key_Deal_Integration__c','Quote.Opportunity.White_Space__r.Phone__c','Quote.Opportunity.White_Space__r.Contact_Center__c','Quote.Opportunity.White_Space__r.Meetings__c','Quote.Opportunity.White_Space__r.Message__c','Quote.Opportunity.Currency_Symbol__c','Quote.Opportunity.Total_Contract_Value__c','Quote.Opportunity.Estimated_12M_Total_Pipeline__c','Quote.Opportunity.Initial_Contract_Term__c']
    })listInfo({ error, data }) {
        if (data) {
            this.records = data.records;
            // this.error = undefined;
            this.setPrimaryQuote();
            this.validateBigWinCreation();
            this.redirectToBigWin();
        } else if (error) {
            // this.error = error;
            this.records = undefined;
            // let errorMessage;
            this.errorMessage.header = "Error";
            if(error?.message){
                this.errorMessage.details = error?.message;
            }
            else if(error?.body?.message){
                this.errorMessage.details = error?.body?.message;
            }
            this.dispatchEvent(
                new ShowToastEvent({
                    title: this.errorMessage.header,
                    message: this.errorMessage.details,
                    variant: 'error',
                    mode : 'sticky'
                })
            );
        }
        this.dispatchEvent(new CloseActionScreenEvent());
        this.showSpinner = false;
    }

    setPrimaryQuote(){
        for(let index in this.records){
             if  (
                    this.records[index].apiName == 'Quote' 
                    &&
                    this.records[index].fields?.isPrimary__c?.value 
                    &&
                    (
                        (
                        this.records[index].fields?.RecordType?.value?.fields?.Name?.value == 'Sales Quote v2' 
                        && 
                        this.records[index].fields?.Opportunity?.value?.fields?.Is_Billing_Opportunity__c?.value
                        ) 
                        || 
                        (
                        this.records[index].fields?.RecordType?.value?.fields?.Name?.value != 'Sales Quote v2' 
                        && 
                        !this.records[index].fields?.Opportunity?.value?.fields?.Is_Billing_Opportunity__c?.value
                        )
                    )
                )
                {
                    this.primaryQuote = this.records[index];
                    break;
                }
        }
      }
    
    validateBigWinCreation(){
        // let errorMessage = {};
        // let errorMessage.header;
        // let errorMessage.details;
       if(Object.keys(this.primaryQuote).length === 0){
            this.errorMessage.header = "Required Data Missing";
            this.errorMessage.details = "Big Win Form can only be created when the opportunity has a primary quote";   
        }
        else if(!this.primaryQuote.fields?.Opportunity?.value?.fields?.AccountId?.value){
            this.errorMessage.header = "Opportunity must have an Account";
            this.errorMessage.details = "Big Wins Form can only be created from opportunities attached to an Account";
        }
        else if(this.primaryQuote.fields?.Opportunity?.value?.fields?.StageName?.value != "7. Closed Won"){
            this.errorMessage.header = "Invalid Opportunity Stage";
            this.errorMessage.details = "Big Win Form can only be created for Closed Won Opportunities";
        }
        else {
            let missingFieldsLabelList = [];
            if(!this.primaryQuote.fields?.Initial_Term_months__c?.value){
                missingFieldsLabelList.push("Initial Term");
            }
            if(!this.primaryQuote.fields?.Opportunity?.value?.fields?.Total_MRR__c?.value){
                missingFieldsLabelList.push("Total MRR");
            }
            if(!this.primaryQuote.fields?.Opportunity?.value?.fields?.Forecasted_Users__c?.value){
                missingFieldsLabelList.push("Forecasted Users");
            }
            if(!this.primaryQuote.fields?.Opportunity?.value?.fields?.Account?.value?.fields?.Total_Potential_Users__c?.value){
                missingFieldsLabelList.push("Total Potential Users on Account");
            }
            if(!this.primaryQuote.fields?.Opportunity?.value?.fields?.CW_Who_did_we_replace__c?.value){
                missingFieldsLabelList.push("Who did we replace?");
            }
            if(!this.primaryQuote.fields?.Opportunity?.value?.fields?.Account?.value?.fields?.Industry?.value){
                missingFieldsLabelList.push("Industry on Account");
            }
            if(!this.primaryQuote.fields?.Opportunity?.value?.fields?.CW_Primary_Win_Reason__c?.value){
                missingFieldsLabelList.push("Primary Win Reason");
            }
            if(missingFieldsLabelList?.length){
                this.errorMessage.header = "Required Fields Are Missing";
                this.errorMessage.details = "Please fill in "+missingFieldsLabelList.toString();
            }
           }
        
        if(this.errorMessage?.header && this.errorMessage?.details){
            this.dispatchEvent(
                new ShowToastEvent({
                    title: this.errorMessage.header,
                    message: this.errorMessage.details,
                    variant: 'error',
                    mode : 'sticky'
                }),
            );
            return;
        }
        
    }

    redirectToBigWin(){
        if(!this.errorMessage?.header && !this.errorMessage?.details){
            this.setConditionalFieldsOnBigWin();
            const defaultValues = encodeDefaultFieldValues({
                Term__c: parseInt(this.primaryQuote.fields?.Initial_Term_months__c?.value),
                Special_Terms__c: this.primaryQuote.fields?.Special_Terms__c?.value?.toString(),
                Inside_Channel_Manager__c: this.primaryQuote.fields?.Opportunity?.value?.fields?.Inside_Sales_Rep__c?.value,
                Partner_Account__c: this.primaryQuote.fields?.Opportunity?.value?.fields?.Partner_Account__c?.value,
                SDR_BDR__c: this.primaryQuote.fields?.Opportunity?.value?.fields?.SDR_Agents__c?.value,
                SE__c: this.primaryQuote.fields?.Opportunity?.value?.fields?.Sales_Engineer__c?.value,
               // Current_Situation__c: this.primaryQuote.fields?.Opportunity?.value?.fields?.STC_Current_Situation__c?.value,
                Current_Situation__c: this.Current_Situation__c,
                Benefits__c: this.primaryQuote.fields?.Opportunity?.value?.fields?.STC_Ideal_Situation__c?.value,
                Customer_Ideal_Situation__c: this.primaryQuote.fields?.Opportunity?.value?.fields?.STC_Ideal_Situation__c?.value,
                Problems__c: this.primaryQuote.fields?.Opportunity?.value?.fields?.STC_Problems__c?.value,
                BigWinWhyWeWon__c: this.primaryQuote.fields?.Opportunity?.value?.fields?.CW_Primary_Win_Reason__c?.value,
                Account_Description__c: this.primaryQuote.fields?.Opportunity?.value?.fields?.Account?.value?.fields?.Description?.value,
                Previous_Service__c: this.primaryQuote.fields?.Opportunity?.value?.fields?.CW_Who_did_we_replace__c?.value,
                Headshot_for_Glip__c: this.primaryQuote.fields?.Opportunity?.value?.fields?.Glip_AE_Headshot__c?.value,
                CurrencyIsoCode: this.primaryQuote.fields?.Opportunity?.value?.fields?.CurrencyIsoCode?.value,
                Account_Name__c: this.primaryQuote.fields?.Opportunity?.value?.fields?.AccountId?.value,
                Opportunity__c: this.primaryQuote.fields?.Opportunity?.value?.id,
                Competitors__c: this.primaryQuote.fields?.Opportunity?.value?.fields?.UCaaS_Competitor_s__c?.value +', '+this.primaryQuote.fields?.Opportunity?.value?.fields?.CC_Competitor_s__c?.value +', '+this.primaryQuote.fields?.Opportunity?.value?.fields?.Video_Competition__c?.value,
                Legacy_Solution__c: this.primaryQuote.fields?.Opportunity?.value?.fields?.White_Space__r?.value?.fields?.Phone__c?.value + '; ' +this.primaryQuote.fields?.Opportunity?.value?.fields?.White_Space__r?.value?.fields?.Contact_Center__c?.value + '; ' +this.primaryQuote.fields?.Opportunity?.value?.fields?.White_Space__r?.value?.fields?.Meetings__c?.value +', ' + this.primaryQuote.fields?.Opportunity?.value?.fields?.White_Space__r?.value?.fields?.Message__c?.value,
                Size__c: this.primaryQuote.fields?.Opportunity?.value?.fields?.Account?.value?.fields?.SM_Employees__c?.value + ' Employees / $ Revenue',
                Value_to_RingCentral__c: this.primaryQuote.fields?.Opportunity?.value?.fields?.Currency_Symbol__c?.value + this.primaryQuote.fields?.Opportunity?.value?.fields?.Total_Contract_Value__c?.value +' TCV, '+ this.primaryQuote.fields?.Opportunity?.value?.fields?.Estimated_12M_Total_Pipeline__c?.value  + ' ARR, ' + this.primaryQuote.fields?.Opportunity?.value?.fields?.Initial_Contract_Term__c?.value + ' Months',
                Key_Facts__c: this.key_facts,
                Solutions_Components__c: this.solutions_components,
                Acquisition_or_Growth__c: this.acquisition_or_growth,
                Partner_Involved__c: this.partner_involved,
                Negative_Impact_on_Business__c: this.primaryQuote.fields?.Opportunity?.value?.fields?.STC_Problems__c?.value
            });
            this[NavigationMixin.GenerateUrl]({
                type: 'standard__objectPage',
                attributes: {
                    objectApiName: 'BigWins_Form__c',
                    actionName: 'new'
                },
                state: {
                    defaultFieldValues: defaultValues
                }
                
            }).then(url => {
                window.open(url, "_blank");
            });
        }
    }

    setConditionalFieldsOnBigWin(){
        if(this.primaryQuote.fields?.Opportunity?.value?.fields?.Account?.value?.fields?.Fortune_Classification__c?.value && this.primaryQuote.fields?.Opportunity?.value?.fields?.Segment_Name__c?.value){
            this.key_facts = this.primaryQuote.fields?.Opportunity?.value?.fields?.Account?.value?.fields?.Fortune_Classification__c?.value + ' / ' +this.primaryQuote.fields?.Opportunity?.value?.fields?.Segment_Name__c?.value;
        }
        else if(this.primaryQuote.fields?.Opportunity?.value?.fields?.Account?.value?.fields?.Fortune_Classification__c?.value){
            this.key_facts = this.primaryQuote.fields?.Opportunity?.value?.fields?.Account?.value?.fields?.Fortune_Classification__c?.value;
        }
        else if(this.primaryQuote.fields?.Opportunity?.value?.fields?.Segment_Name__c?.value){
            this.key_facts = this.primaryQuote.fields?.Opportunity?.value?.fields?.Segment_Name__c?.value;
        }
       
        console.log('cc'+this.primaryQuote.fields?.Opportunity?.value?.fields?.Forecast_Contact_Center_Users__c?.value);
         console.log('users?'+this.primaryQuote.fields?.Opportunity?.value?.fields?.Forecasted_Users__c?.value);
         if(((this.primaryQuote.fields?.Opportunity?.value?.fields?.Forecasted_Users__c?.value)> 1) && ((this.primaryQuote.fields?.Opportunity?.value?.fields?.Forecast_Contact_Center_Users__c?.value)>1) ){
            this.solutions_components = 'UCaaS and CCaaS from RingCentral';
       }
        else if((this.primaryQuote.fields?.Opportunity?.value?.fields?.Forecasted_Users__c?.value)> 1 )
        {
            this.solutions_components = 'UCaaS from RingCentral';
        }
        else if((this.primaryQuote.fields?.Opportunity?.value?.fields?.Forecast_Contact_Center_Users__c?.value)> 1 )
        {
            this.solutions_components = 'CCaaS from RingCentral';
        }
      
        console.log('solutions_components'+this.solutions_components);
        this.acquisition_or_growth = 'Acquisition';
        if(this.primaryQuote.fields?.Opportunity?.value?.fields?.Account?.value?.fields?.RC_Upgrade_Date__c?.value){
            let dateDiffInMilliSeconds = new Date() - new Date(this.primaryQuote.fields?.Opportunity?.value?.fields?.Account?.value?.fields?.RC_Upgrade_Date__c?.value);
            let daysSinceAccountPaid = parseInt(dateDiffInMilliSeconds / (1000*60*60*24));
            if(daysSinceAccountPaid > 90){
                this.acquisition_or_growth = 'Growth';
            }
        }
        if(this.primaryQuote.fields?.Opportunity?.value?.fields?.Account?.value?.fields?.Partner_Account__c?.value){
            this.partner_involved = this.primaryQuote.fields?.Opportunity?.value?.fields?.Account?.value?.fields?.Partner_Account__r?.Name?.value;
        }
        else{
            this.partner_involved = 'No';
        }
        
    }

}