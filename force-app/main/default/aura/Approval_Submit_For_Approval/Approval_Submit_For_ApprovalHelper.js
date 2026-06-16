({
    getInitialData : function(component, helper){
        helper.showSpinner(component);
        let action = component.get('c.getInitialData');
        let recordId = component.get('v.recordId');
        action.setParams({ recordId : recordId});
        action.setCallback(this, function(response) {
            let state = response.getState();
            helper.hideSpinner(component);
            if (state === 'SUCCESS') {
                let data = response.getReturnValue();
                component.set('v.recordTypeDeveloperName', data.recordTypeDeveloperName);
                component.set('v.isDisableSubmitButton', data.isDisableSubmitButton);
                component.set('v.isExistAmountToIncrease', data.isExistAmountToIncrease);
                component.set('v.isExistAttachment', data.isExistAttachment);
                helper.showMessage(component, data);
            } else {
                console.log('>>>Can\'t get data');
            }
            component.set('v.onLoad', true);
        });
        $A.enqueueAction(action);
    },
	showSpinner: function(component, event, helper) {        
        var spinner = component.find("mySpinner");
        $A.util.removeClass(spinner, "slds-hide");
    },   
    hideSpinner : function(component,event,helper){           
        var spinner = component.find("mySpinner");
        $A.util.addClass(spinner, "slds-hide");
    },
    showMessage : function(component, data) {
        if(data != null && data.recordTypeDeveloperName == 'Credit_Limit_Increase'){
            let messages = [];
            if (!data.isExistAmountToIncrease) {
                messages.push('NGBS Amount to Increase Spending Limit must be set...');
            }
            if (!data.isExistAttachment) {
                messages.push("You must attach the file to the attachment.");
            }
            messages.forEach(message => {
                let toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "type": "Error",
                    "message": message,
                    "mode":'dismissible'
                });
                toastEvent.fire();
            })

        }

    }
})