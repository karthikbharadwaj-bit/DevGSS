({
    doInit : function(component,event,helper,packageChange) {
       //alert(component.get("v.changeEdition"));
       var action = component.get("c.getProductCategories");
        var changeAddition = component.get("v.changeEdition");
       action.setParams({
            packageName : component.get("v.changeEdition"),
            dqId : component.get("v.dqId"),
            changeOrderId : component.get("v.changeOrderId"),
            isPackageChange : packageChange,
           recordtypeName : component.get("v.dqDiscountRecordTypeName")
	   });
        action.setCallback(this, function(result) {            
            var state = result.getState();
          
            if (state === "SUCCESS"){
                console.log('result>>',result.getReturnValue());
                component.set("v.listofEditionWrapper",result.getReturnValue().listofEditionWrapper);
                if(component.get("v.ExistingChangeOrder")) {
                    var objpartnerQuote = result.getReturnValue().objPartnerQuoteRec;
                    if(objpartnerQuote.Payment_Method__c == 'Invoice') {
                       component.set("v.paymentMethod",true); 
                    }
                    
                    if(objpartnerQuote.Payment_Term__c == 'Yearly')
                       component.set("v.PricingYearly",true);
                    
                    if(!packageChange)
                    	component.set("v.changeEdition",objpartnerQuote.Product_Edition__c);
                    
                    	component.set("v.objPartnerQuote",objpartnerQuote);
                }
                else {
                    component.set("v.objPartnerQuote",result.getReturnValue().objPartnerQuoteRec);
                }
                //component.set("v.objPartnerQuote",result.getReturnValue().objPartnerQuoteRec);
                component.set("v.CategoryWrapperList",result.getReturnValue().parentCategoryWrapperList);
            }
        });    
        
        $A.enqueueAction(action); 
    },
    
	helperFun : function(component,event,secId) {
	  var acc = component.find(secId);
        	for(var cmp in acc) {
        	$A.util.toggleClass(acc[cmp], 'slds-show');  
        	$A.util.toggleClass(acc[cmp], 'slds-hide');  
       }
	},
    submitDetails : function(component, event, helper,Status) {
        //alert(component.get("v.accountId"));
        console.log('component.get("v.CategoryWrapperList")>>',component.get("v.CategoryWrapperList"));
        var action = component.get("c.createDQDiscount");
       	action.setParams({
            categoryWrapperStr : JSON.stringify(component.get("v.CategoryWrapperList")),
            dqId : component.get("v.dqId"),
            recordtypeName : component.get("v.dqDiscountRecordTypeName")
        });
        action.setCallback(this, function(result) {            
            var state = result.getState();
            //alert(state);
            if (component.isValid() && state === "SUCCESS"){
                if(Status == 'Pending Order') {
                    component.set("v.isChangeOrderSubmitted", true);
                    //helper.showToast('Success','Change requested submitted successfully.','success');
                }
                else{
                	//helper.showToast('Success','Added Successfully.','success');
                }
                const p = component.get("v.parent");
    			p.refreshApproverList();
               component.set("v.showAddProducts",false);
            }
        });    
        
        $A.enqueueAction(action); 
	},
})