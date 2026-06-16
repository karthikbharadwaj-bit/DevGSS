({
    createPartnerQuote : function(component, event, helper) {
        var action = component.get("c.createPartnerQuoteForUpsell");
        action.setParams({
            accID : component.get("v.accountId")
        });
        action.setCallback(this, function(response){
            if(response.getState() == "SUCCESS"){
                window.open('https://e2euat-rc-portal.cs4.force.com/partner/s/quotetool?id='+ response.getReturnValue().Id+'&editionId='+response.getReturnValue().Product_Edition__c,'_top');
            }
        });
        $A.enqueueAction(action);
    },
    checkPartnerQuoteExist : function(component, event, helper) {
        var areaCodeList = component.get("v.areaCodeList");
        var action = component.get("c.checkPartnerQuoteExistFORAccount");
        console.log('accountid>'+component.get("v.accountId"));
        action.setParams({
            accID : component.get("v.accountId")
        });
        action.setCallback(this, function(result) {
            var state = result.getState();
            if (component.isValid() && state === "SUCCESS"){
                var accountCheckListRec = result.getReturnValue();
                console.log('accountCheckListRec'+JSON.stringify(accountCheckListRec));
                if(accountCheckListRec != null) {
                    component.set("v.objAccountCheckList",accountCheckListRec.objACR);
                    component.set("v.addressList",accountCheckListRec.listOfACR);
                    console.log('accountCheckListRec.listOfACRWrapp>>>',accountCheckListRec.listOfACRWrapp);
                    component.set("v.ShippingAddressList",accountCheckListRec.listOfACRWrapp);
                    component.set("v.showChecklistCMP",true);
                }
                else {
                    component.set("v.showChecklistCMP",true);
                }
            }
        });

        $A.enqueueAction(action);
    },
     //Translation Start

    getTranslations : function (component, event, helper)
    {
        try
        {
            var action = component.get("c.getTranslations");
            action.setParams({
                "objNames": 'Opportunity,Account,Deal_Support__c,Partner_Quote__c'
            });
            action.setCallback(this, function (result) {
                var state = result.getState();
                if (component.isValid() && state === "SUCCESS") {
                    console.log('AllObjFields - ' + JSON.stringify(result.getReturnValue()));
                    var resultData = result.getReturnValue();
                    if(resultData != undefined && resultData != null && resultData != '')
                    {
                        if(resultData.allObjFieldsMap != undefined && resultData.allObjFieldsMap != null &&
                           resultData.allObjFieldsMap != '')
                        {
                            component.set("v.oppFieldsMap", resultData.allObjFieldsMap.Opportunity);
                            component.set("v.accFieldsMap", resultData.allObjFieldsMap.Account);
                            component.set("v.dealSupportFieldsMap", resultData.allObjFieldsMap.Deal_Support__c);
                            component.set("v.quoteFieldsMap", resultData.allObjFieldsMap.Partner_Quote__c);
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
    },
     //Translation End
insertDealSupport : function(component, event, helper) {
    	var id_str = component.get("v.recordID");
    	var optyname = component.get("v.OpportunityRecord.Name");
    	var custId = component.get("v.OpportunityRecord.AccountId");
        var dealsuppcomment=component.get("v.comment");
    	var dsType=component.get("v.DSType");
		var action = component.get("c.insertDealSupportNew");
        action.setParams({
            "comments":dealsuppcomment,
            "typeDS":dsType,
            "optyID":id_str,
            "custId":custId,
            "oppName":optyname
        });
        action.setCallback(this, function(result) {
            var state = result.getState();
            if (state === "SUCCESS"){
                var resultData = result.getReturnValue();
                var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "type": "success",
                        "title": "Success!",
                        "message": "The record has been Submitted successfully.",
                        "mode":'dismissible'
                    });
                toastEvent.fire();
                var dsID = resultData.Id;
                component.set("v.showCreateDealStatus", false);

                var urlEvent = $A.get("e.force:navigateToURL");
                urlEvent.setParams({
                   'url': '/partner/s/dealsupport?id='+dsID
                });
                urlEvent.fire();
            }
        });
        $A.enqueueAction(action);
	},
    getEmployees: function (component, event, helper) {
        try
        {
        console.log('employee on load>');
        var country = component.get("v.OpportunityRecord.Account.BillingCountry");
        var employee = [];
        if (country == 'United States' || country == 'Canada' || country == 'UNITED STATES' || country == 'united states' || country == 'canada') {
            employee = ["1-19", "20-99", "100-399", "400-4999", "5000+"];
            component.set("v.employeeListDisplayed", employee);
            //component.set("v.selectedEmployeeValue", employee[0]);
            console.log('employee>', component.get("v.employeeListDisplayed"));
        } else {
            employee = ["1-19", "20-99", "100-4999", "5000+"];
            component.set("v.employeeListDisplayed", employee);
            //component.set("v.selectedEmployeeValue", employee[0]);
            console.log('employee>', component.get("v.employeeListDisplayed"));
        }
        }
        catch(e)
        {
            console.log('exception - ' + e);
        }
    },
     checkAccountList : function(component, event, helper) {
        var action = component.get("c.checkPartnerQuoteExistFORAccount");
        action.setParams({accountId : component.get("v.accountId") });
        action.setCallback(this, function(response){
            console.log('response.getState()=', response.getState());
            if(response.getState() == "SUCCESS"){
                component.set("v.showPartnerChecklistCMP",true);
                if(response.getReturnValue() != null) {
                   	var objCheckList = response.getReturnValue();
                   // alert(objCheckList.listOfACR.length);
                	component.set("v.objAccountCheckList", objCheckList.objACR);
                    if(objCheckList.listOfACR != null){
                		component.set("v.addressList", objCheckList.listOfACR);
                        component.set("v.ShippingAddressList",objCheckList.listOfACRWrapp);
                    }
                }
            }
        });
        $A.enqueueAction(action);
    },
    checkSalesQuote : function(component, result) {
        if (!component.get("v.ShowOnlyRC")) return;
        var salesQuote = result.getReturnValue().salesQuote;
        var DealSupport = result.getReturnValue().dealSupportRec;
        if (!salesQuote) {
            component.set("v.processOrdercontext",'No Quote Available');
            return;
        }
        if((salesQuote.Approved_Status__c == 'Not Required' || salesQuote.Approved_Status__c == 'Approved') && !result.getReturnValue().isProcessOrderRequestExist){
        	component.set("v.showProcessOrder",false);
            return;
        }                
        if( result.getReturnValue().salesQuote.Approved_Status__c != 'Not Required' && result.getReturnValue().salesQuote.Approved_Status__c != 'Approved'){
        	component.set("v.processOrdercontext",'Please wait until the quote is approved');
        	return;
        } 
        if(!!result.getReturnValue().isProcessOrderRequestExist && !!DealSupport){
            component.set("v.processOrdercontext",'Process order has already been requested. Status: '+DealSupport.Status__c);
            return;
        }
    },
    getIsIgniteUQTFlow: function (component, event, helper) {
        try {
            var action = component.get("c.isIgniteUQTFlow");
            action.setCallback(this, function(result) {
                var state = result.getState();
                if (state === "SUCCESS") {
                    var isIgniteUQTFlow = result.getReturnValue();
                    component.set("v.isIgniteUQTFlow", isIgniteUQTFlow);
                }
            });
            $A.enqueueAction(action);
        }
        catch(e) {
            console.log('exception - ' + e);
        }
    },
    toggleToolTip : function(component, tooltipId, action) {
        let tooltip = component.find(tooltipId);
        if(action == 'show'){
            $A.util.addClass(tooltip, "slds-hide");
        }else{
            $A.util.removeClass(tooltip, "slds-hide");
        }
    }
})