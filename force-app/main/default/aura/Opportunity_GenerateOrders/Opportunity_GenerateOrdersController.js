({
    doInit : function(component, event, helper){
        console.log("Setup in controller");
        console.log('Fromclose = ' + component.get("v.Fromclose"));
        console.log('oppId = ' + component.get("v.oppId"));
        
        if(component.get("v.Fromclose") == false) {
            var recId = component.get("v.recordId");
            component.set("v.oppId", recId);
        }

        var oppid = component.get("v.oppId");
        var action = component.get("c.getOppBillingDetail");
        action.setParams({
            "OppId" : oppid
        });
        helper.showSpinner(component);
        action.setCallback(this, function(response){
            var state = response.getState();
            if(state == "SUCCESS"){
                var oppObj = response.getReturnValue();

                component.set('v.isBillingOpportunity', oppObj.Is_Billing_Opportunity__c);
                helper.generateOrders(component, event, helper);
            } else {
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "type": "error",
                    "title": "Error!",
                    "message": "There is some error while processing",
                    "mode":'dismissible'
                });
                toastEvent.fire();
            }
        });
        $A.enqueueAction(action);  
    },

    checkRC : function (component, event, helper) {
        var rcNumberAcc = component.get("v.rcNumber");
        component.set("v.isGenerateorderprompt", false);
        if (rcNumberAcc == 'undefined' || rcNumberAcc == null) {
            component.set("v.isRCnumberprompt", true);
        } else {
            component.set('v.rcNumberInput', component.get('v.rcNumber'));
            component.set("v.isCCnumberprompt", true);
        }
    },

    provideRCNumber : function (component, event, helper) {
        component.set("v.isGenerateorderprompt", false);
        component.set("v.isRCnumberprompt", true);
    },

    provideCCNumber : function (component, event, helper) {
        component.set("v.isGenerateorderprompt", false);
        component.set("v.isRCnumberprompt", false);
        component.set("v.isCCnumberprompt", true);
    },

    generateOrders : function (component, event, helper) {
        component.set("v.isGenerateorderprompt", false);
        component.set("v.isRCnumberprompt", false);
        component.set("v.isCCnumberprompt", false);
        helper.showSpinner(component);
        helper.generateOrders(component, event, helper);
    },

    closeModel : function (component, event, helper) {
        if (component.get("v.isGenerateorderprompt")) {
            // Set isModalOpen attribute to false
            component.set("v.isGenerateorderprompt", false);
        } else if (component.get("v.isRCnumberprompt")) {
            component.set("v.isRCnumberprompt", false);
        } else if (component.get("v.isCCnumberprompt")) {
            component.set("v.isCCnumberprompt", false);
        }
    }
})