({
	loadQuoteLines : function(component, event, helper) {
        var url = new URL(location.href);
        var id = url.searchParams.get('id');
        console.log('id=quoteLines=' + id);
        if(!id){
        	id = url.href.split('/')[6];
        }
        if(id){
            console.log('Calling aciton in quote lines...',id);
            var getQuoteLinesAction = component.get("c.getQuoteLinesWithCalculation");
            getQuoteLinesAction.setParams({  
                quoteId : id  
            });
            getQuoteLinesAction.setCallback(this, function(response){
                console.log('response.getState()=', response.getState());
                if(response.getState() == "SUCCESS"){
                    var oneTimeTotal = 0;
                    var reccurringTotal = 0;
                    var listOfQuoteLines = response.getReturnValue();
                    console.log('listOfQuoteLines=', listOfQuoteLines);
                    component.set("v.QuoteLineWrapper", listOfQuoteLines);
                    helper.doCalculation(component, event, helper);
                }
                else{
                    helper.showToast('Error', 'There is some error in loading Quote Line Items. Please contact your Admin.', 'error');
                }
            });
            $A.enqueueAction(getQuoteLinesAction);	
        }
	},
    
    saveQuoteLines : function(component, event, helper) {
		var saveQuoteLinesAction = component.get("c.updateQuoteLines");
        var quoteLines = component.get("v.QuoteLines");
        var quoteLinesJSON = JSON.stringify(quoteLines);
      	saveQuoteLinesAction.setParams({  
            quoteLines : quoteLinesJSON  
        });
        saveQuoteLinesAction.setCallback(this, function(response){
        	console.log('response.getState()=', response.getState());
            if(response.getState() == "SUCCESS"){
            	var result = response.getReturnValue();
            	helper.showToast('Success', 'Quote lines are saved successfully.', 'info');
            }
            else{
            	helper.showToast('Error', 'There is some error in saving Quote Line Items. Please contact your Admin.', 'error');
            }
      	});
        $A.enqueueAction(saveQuoteLinesAction);	
	},
    
    doCalculation : function(component, event, helper) {
        console.log('doing calculations');
		var listOfQuoteLines = component.get("v.QuoteLines");
        var totalPriceTotal = 0;
        listOfQuoteLines.forEach(function(eachLine){
        	var listPrice = eachLine.List_Price__c;
       		//var discount = eachLine.Discount__c;
            var discount = eachLine.Discount_Number__c;
            var discountType = eachLine.Discount_Type__c;
            var quantity = eachLine.Quantity__c;
            var effectivePrice = eachLine.Effective_Price__c;
            var totalPrice = eachLine.Total_Price__c;
            if(discount && discountType == '%'){
            	effectivePrice = listPrice - ((listPrice * discount) / 100);
            }else if(discount && discountType == 'Amt'){
                effectivePrice = listPrice - discount;
            }
            else{
                effectivePrice = listPrice;
            }
            totalPrice = effectivePrice * quantity;
            eachLine.Effective_Price__c = effectivePrice;
            eachLine.Total_Price__c = totalPrice;
            totalPriceTotal += totalPrice;
        });
        component.set("v.QuoteLines", listOfQuoteLines);
        component.set("v.TotalPrice", totalPriceTotal);
        console.log('calculations done');
        console.log('listOfQuoteLines',listOfQuoteLines);
	},
    
    deleteQuoteProduct : function(component, event, helper) {
        /*try{
            var index = event.currentTarget.id;
            var url = new URL(location.href);
        	var id = url.searchParams.get('id');
            var deleteQuoteLinesAction = component.get("c.deleteQuoteLine");
            var quoteLines = component.get("v.QuoteLines");
            console.log('quoteLines=', quoteLines);
            deleteQuoteLinesAction.setParams({ 
                quoteId : id,
                quoteLineId : quoteLines[index].Id
            });
            deleteQuoteLinesAction.setCallback(this, function(response){
                console.log('response.getState()=', response.getState());
                if(response.getState() == "SUCCESS"){
                    component.set("v.QuoteLines", response.getReturnValue());
                    helper.doCalculation(component, event, helper);
                    helper.showToast('Sucess', 'Quote line delete successfully !', 'info');
                }
                else{
                    helper.showToast('Error', 'There is some error in loading Quote Line Items. Please contact your Admin.', 'error');
                }
            });
            $A.enqueueAction(deleteQuoteLinesAction);
        }
        catch(e){
            console.log('Error = ', e);
        }*/
	},
	getTranslations : function (component, event, helper) 
    {
        try
        {
            var action = component.get("c.getTranslations");
                        console.log('Inside Translation');
            action.setParams({
                "objNames" : 'Deal_Support__c'
            });
            action.setCallback(this, function (result) {
                var state = result.getState();
                if (component.isValid() && state === "SUCCESS") {
                    console.log('AllObjFields - ' + JSON.stringify(result.getReturnValue()));
                   console.log('Inside call back' + JSON.stringify(result.getReturnValue()));
                    var resultData = result.getReturnValue();
                    if(resultData != undefined && resultData != null && resultData != '')
                    {
                        if(resultData.allObjFieldsMap != undefined && resultData.allObjFieldsMap != null && 
                           resultData.allObjFieldsMap != '')
                        {
                            component.set("v.dealSupportFieldsMap", resultData.allObjFieldsMap.Deal_Support__c);
                        } 
                        component.set("v.translationsMap", resultData.prmLabelsMap);
                        component.set("v.PRMSpecificTranslationsMap", resultData.prmSpecificLabelsMap);
                    }
                }
            });
            $A.enqueueAction(action);
        }
        catch(e)
        {
            console.log('err - ' + e);
        } 
    }
})