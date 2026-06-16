({
	loadData : function(component, event, helper){
   		helper.doTotal(component, event, helper);
       	
	},
    
    doTotal : function(component, event, helper) {
        helper.doTotal(component, event, helper);
	},
    
    
    deleteQuoteProduct : function(component, event, helper) {
       // helper.deleteQuoteProduct(component, event, helper);
	},
    
    addMoreProducts : function(component, event, helper){
        if(!component.get("v.isProductSelectedFROMPYNTab") && component.get("v.Step") == "2") {
            component.set("v.Step","2");
            helper.showToast('Error', 'Please select Main Number.', 'error');
        }
        else {
            var url = new URL(location.href);
            var id = url.searchParams.get('id');
            if(id) {
                component.set("v.selectedCategory", "Service");
                component.set("v.Step", "3");
            } 
        }
	},
    
    quoteLoadActions: function(component, event, helper){
    	helper.quoteLoadActions(component, event, helper);
	},
    
    updatePaymentTermAndPricing: function(component, event, helper){
        try{
           	var objQuote = component.get("v.Quote");
            var paymentTerm = component.get("v.PricingYearly") ? 'Yearly' : 'Monthly';
            var numberOfLicenses = objQuote.Number_of_Licenses__c;
            objQuote.Payment_Term__c = paymentTerm;
            component.set("v.Quote", objQuote);
            var brandName = component.get("v.BrandName");
            console.log('SelectedProductList before discount 0 - ' + JSON.stringify(component.get("v.SelectedProductList")));
            var selectedProductList = component.get("v.SelectedProductList");
            console.log('BrandName - ' + component.get("v.BrandName"));
            if(brandName && (brandName == 'Rainbow Office')) {
                if(paymentTerm == 'Yearly'){
                    objQuote.Contract__c = true;
                    component.set("v.Quote", objQuote);
                }
            }
            //BZS-5115
            if(objQuote.Contract__c == false && objQuote.Id && brandName!=undefined && brandName.includes("RingCentral")) {

                selectedProductList.forEach(function(eachProduct){
                    if(eachProduct.partnerDiscount){
                        eachProduct.partnerDiscount = 0;

                    }
                       
                });
                
            }
            component.set("v.SelectedProductList", selectedProductList);
            console.log('SelectedProductList after discount 0 - ' + JSON.stringify(component.get("v.SelectedProductList")));
            if(component.get("v.callUpdatePricingEvent")){
                var evtUpdatePricing = component.getEvent("evtUpdatePricing");
                
                evtUpdatePricing.setParams({
                    "evtParam_NoOfLicenses" : numberOfLicenses,
                    "evtParam_PricingTerm" : paymentTerm
                });
                evtUpdatePricing.fire();
            }
            helper.updatePrice(component, event, helper, component.get("v.SelectedProductList"), true);
            helper.createUpdateQuote(component, event, helper, null, null, null, null, true, false);
            helper.setReloadFlag(component, event, helper);
        }
        catch(e){
            console.log('Error = ', e);
        }
    }
})