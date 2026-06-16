({
    doInit: function (component, event, helper) {
        // Added for PBC-11030
        var action = component.get("c.checkPartnerQuoteExistFORAccount");
        console.log('accountidPOC>' + component.get("v.accountId"));
        action.setParams({
            accID: component.get("v.accountId")
        });
        action.setCallback(this, function (result) {
            var state = result.getState();
            if (component.isValid() && state === "SUCCESS") {
                var accountCheckListRec = result.getReturnValue();
                console.log('accountCheckListRec' + JSON.stringify(accountCheckListRec));
                if (accountCheckListRec != null) {
                    component.set("v.objAccountCheckList", accountCheckListRec.objACR);
                    var objAccCheckList = component.get("v.objAccountCheckList");
                    console.log('objAccountCheckListPOC' + JSON.stringify(objAccCheckList));
                    if (objAccCheckList !== undefined && objAccCheckList.VAT_Number__c !== undefined && objAccCheckList.VAT_Number__c !== "") {
                        component.set('v.isVATNumber', true);
                    }
                    else {
                        component.set('v.isVATNumber', false);
                    }
                    var isVATNumber = component.get("v.isVATNumber");
                    console.log('isVATNumber-' + isVATNumber);
                }
            }   
        });
        $A.enqueueAction(action);
    },

	closeModel : function(component, event, helper) {
        component.set("v.showPOCRequest",false);
    },
    
    submitPOCRequest : function(component,event,helper) {
        component.set("v.Spinner",true);
       helper.submitPOCRequest(component,event,helper);
    },
})