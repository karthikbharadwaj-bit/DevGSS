({
    validateSubmitOrder : function(component, event, helper) {
        let orderId = component.get('v.recordId');
        let action = component.get('c.checkSubmitOrderValidity');
        action.setParams({
            orderIdStr: orderId
        });
        action.setCallback(this, function(result) {
            if (component.isValid() && result.getState() === 'SUCCESS') {
                let res = result.getReturnValue();
                
                console.log('Theme : ' + res.theme + '\n Header : ' + res.header + '\n Details : ' + res.Details);                
                
                if(res.theme == '') {
                    
                    window.open('/apex/submit_order_popup?id=' + orderId);
                    /*let urlEvent = $A.get("e.force:navigateToURL");
                    urlEvent.setParams({
                        'url': '/apex/submit_order_popup?id=' + orderId
                    });
                    urlEvent.fire();*/
                }
                else {
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        type: res.theme,
                        title : res.header,
                        message: res.details,
                    });
                    toastEvent.fire();                    
                }                
                
                var dismissActionPanel = $A.get("e.force:closeQuickAction");
        		dismissActionPanel.fire();
            }
        });
        $A.enqueueAction(action);
    },
    showSpinner: function(component, event, helper) {  
        var spinner = component.find("loadingSpinner");
        $A.util.removeClass(spinner, "slds-hide");
    },   
    hideSpinner : function(component,event,helper){   
        var spinner = component.find("loadingSpinner");
        $A.util.addClass(spinner, "slds-hide");    
    }
})