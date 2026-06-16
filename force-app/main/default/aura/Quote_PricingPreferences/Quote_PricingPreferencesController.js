({
    onInit : function(component, event, helper) {
        try {
            var url = new URL(location.href);
            var id;
            if(url.searchParams.get('id'))
                id = url.searchParams.get('id');
            else
                id = url.searchParams.get('oppId');
            if(id){
                var serverAction = component.get("c.getBrandNameFromOppOrQuote");
                serverAction.setParams({
                    OppIdOrQuoteId : id
                });
                
                serverAction.setCallback(this, function(response){
                    if(response.getState() == "SUCCESS"){
                        var BrandName = response.getReturnValue();
                        component.set("v.BrandName", BrandName);
                        console.log('BrandName - ' + BrandName);
                        let maxLicense = 10000;
                        if(BrandName === 'RingCentral' || BrandName === 'RingCentral Canada' || BrandName === 'RingCentral AU') {
                            maxLicense = 399;
                        }
                        else if(BrandName === 'RingCentral UK' || BrandName === 'RingCentral EU') {
                            maxLicense = 499;
                        }
                            else {
                                maxLicense = 10000; 
                            }
                        component.set("v.maxLicense", maxLicense);
                        
                    }  
                });
                $A.enqueueAction(serverAction);
            }
        }
        catch(e) {
            console.error('error',e);
        }
		helper.getTranslations(component, event, helper);
        
    },
    
	onSeatChange : function(component, event, helper) {
        const NumberOfLicense = component.get("v.NoOfSeats");
        const updatedLicense = component.get("v.Quote.Number_of_Licenses__c");
        const isQuoteExist = component.get("v.Quote.Id");
        if(!isQuoteExist) {
            const brandName = component.get("v.BrandName");
            const igniteBrands = ['RingCentral', 'RingCentral UK', 'RingCentral AU', 'RingCentral Canada', 'RingCentral EU'];
            if(igniteBrands.includes(brandName)) {
                let maxLicense = 399;
                if(['RingCentral UK', 'RingCentral EU'].includes(brandName)) {
                    maxLicense = 499;
                }
                if(updatedLicense > maxLicense) {
                    component.set("v.Quote.Number_of_Licenses__c", maxLicense);
                    helper.showToast('Error',"Please make sure Number of Licenses not exceeds " + maxLicense ,'Error');
                    return;
                }
            }
        }
		component.set("v.NoOfSeats", component.get("v.Quote.Number_of_Licenses__c"));	
	},
    
    onPaymentTermChange : function(component, event, helper) {
        var isPricingYearly = component.get("v.PricingYearly");
        var objQuote = component.get("v.Quote");
        if(isPricingYearly)
        	objQuote.Payment_Term__c = 'Yearly';
        else{
            objQuote.Payment_Term__c = 'Monthly';
            objQuote.Contract__c = true;
            component.set("v.isContract", objQuote.Contract__c);
        }
        component.set("v.Quote", objQuote);
	},
    
    oncontractChange : function(component, event, helper) {
        //alert('test');
        var objQuote = component.get("v.Quote");
        var isPricingYearly = component.get("v.PricingYearly");
        var BrandName = component.get("v.BrandName");
        if(BrandName && BrandName != 'RingCentral' && BrandName != 'RingCentral Canada' 
           	&& BrandName != 'RingCentral UK' && BrandName != 'RingCentral EU' && BrandName != 'RingCentral AU'
            && BrandName != 'Unify Office') {
            if(!isPricingYearly){
                objQuote.Contract__c = true;
                component.set("v.Quote", objQuote);
            }
        }
        //Special case for ale..
        if(BrandName && (BrandName == 'Rainbow Office')) {
            if(isPricingYearly){
                objQuote.Contract__c = true;
                component.set("v.Quote", objQuote);
            }
        }
        component.set("v.isContract", objQuote.Contract__c);
	},
})