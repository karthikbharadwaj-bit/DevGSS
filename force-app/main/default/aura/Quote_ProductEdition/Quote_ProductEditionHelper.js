({
	createPartnerQuoteFromTemplate : function(component, event, helper) {
        	var selectedTemplateId = component.get("v.selectedTemplateId");
			var getQuoteAction = component.get("c.cloneQuote");
            getQuoteAction.setParams({  "quoteId" : selectedTemplateId
                                     });
            getQuoteAction.setCallback(this, function(response){
               	if(response.getState() == "SUCCESS"){
                    helper.redirectTo('/quotetool' +'?id=' + response.getReturnValue() + '&editionId=' +component.get("v.ProductEdition").Id+'&step=4');
                    
                }
                else{
                    helper.showToast('Error', 'There is some error in cloing Quote.', 'error');
                }
            });
            $A.enqueueAction(getQuoteAction);	
        
	},
    //Added for Wholesale
    displaySubPackages : function(component, event, helper) {
        var parentPackageID = component.get("v.ProductEdition").Id;
        component.set('v.parentPackageId',parentPackageID);
        console.log("parentPackageID "+component.get('v.parentPackageId'));
        var url = new URL(location.href);
        var Id = url.searchParams.get('oppId');
        var opportunityId;
        if(Id) {
            opportunityId = Id;
        } else {
            opportunityId = url.searchParams.get('id');
        }
        var getsubPackagesAction = component.get("c.getProductEditions");
        getsubPackagesAction.setParams({  "oppId" : opportunityId,
                                          "parentPackageId" : parentPackageID
                                     });
        getsubPackagesAction.setCallback(this, function(response){
            if(response.getState() == "SUCCESS"){
                console.log("subpackages "+JSON.stringify(response.getReturnValue()));
                component.set('v.subPackages',response.getReturnValue());
                var Editions = response.getReturnValue();
                var NoOfSeats = component.get('v.NoOfSeats');
                var pricingYearlyOrMonthly = component.get("v.PricingYearly");
                var isContract = component.get("v.isContract");
                for(var thisRecord of Editions)
                {
                    var listPriceMonthly = 0;
                    var listPriceYearly = 0;
                    var contractDiscount = null;
                    var tierList = thisRecord.editionRec.Product_Tier_Prices__r;
                    
                    if(tierList && tierList.length > 0){
                        for(var eachTier of tierList){
                            if(NoOfSeats <= eachTier.No_of_Licenses__c ){
                                listPriceMonthly = eachTier.Monthly_Price__c;
                                listPriceYearly = eachTier.Yearly_Price__c;
                                contractDiscount = eachTier.Contract_Discount__c;
                                break;
                            }
                        }
                        if(listPriceMonthly == 0)
                            listPriceMonthly = tierList[tierList.length-1].Monthly_Price__c;  
                        if(listPriceYearly == 0)
                            listPriceYearly = tierList[tierList.length-1].Yearly_Price__c;
                        
                        if(pricingYearlyOrMonthly){
                            thisRecord.editionRec.Price__c = listPriceYearly;
                        }
                        else if(isContract && !pricingYearlyOrMonthly){
                            if(contractDiscount != null){
                                thisRecord.editionRec.Price__c = listPriceMonthly - contractDiscount;
                            }
                            else if(thisRecord.editionRec.Contract_Discount__c != 0 && thisRecord.editionRec.Contract_Discount__c != null) {
                                thisRecord.editionRec.Price__c = listPriceMonthly - thisRecord.editionRec.Contract_Discount__c;
                            } else {
                                thisRecord.editionRec.Price__c  = listPriceMonthly;
                            }
                        }
                            else
                                thisRecord.editionRec.Price__c = listPriceMonthly;
                        
                    }
                }
                component.set('v.subPackages',Editions);
            }
        });
        $A.enqueueAction(getsubPackagesAction);
    }
})