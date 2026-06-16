({
    afterScriptLoad : function(component, event, helper) {
        var recId = component.get("v.recordId");
        var action=component.get("c.getOrderDetailforDeactivate");
        action.setParams({
            "orderId":recId            
        });
        action.setCallback(this, function(response){
            var state = response.getState();  
            if(state=='SUCCESS'){
                var res = response.getReturnValue();
                if ( res.order.Status !== 'Completed' && res.order.Status !== 'Project Completed' ) {
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "type": "error",
                        "title": "Deactivate the Order",
                        "message": 'The order is already deactivated',
                        "mode":'dismissible'
                    });
                    toastEvent.fire();
                }
                else
                {
                    var regex = /admin/gi;                    
                    if (!regex.test(res.profileName)) 
                    {                        
                        var toastEvent = $A.get("e.force:showToast");
                        toastEvent.setParams({
                            "type": "error",
                            "title": "Deactivate the Order",
                            "message": "You don't have enough permissions to Deactivate the Order",
                            "mode":'dismissible'
                        });
                        toastEvent.fire();
                    }
                    else
                    {
                        var action1=component.get("c.activateOrderWithChildren");
                        action1.setParams({
                            "orderId":recId,
                            "lock":false
                        });
                        action1.setCallback(this, function(response){
                            var state = response.getState();  
                            if(state=='SUCCESS'){
                                var res = response.getReturnValue();
                                if(res==true)
                                {
                                    var toastEvent = $A.get("e.force:showToast");
                                    toastEvent.setParams({
                                        "type": "success",
                                        "title": "Deactivate the Order",
                                        "message": "The Order was deactivated. The page will be reloaded",
                                        "mode":'dismissible'
                                    });
                                    toastEvent.fire();
                                    window.setTimeout(
                                        $A.getCallback(function() {
                                            
                                            $A.get('e.force:refreshView').fire();
                                        }), 2000
                                    );
                                }
                                else
                                {
                                    var toastEvent = $A.get("e.force:showToast");
                                    toastEvent.setParams({
                                        "type": "error",
                                        "title": "Locking Order was fallen",
                                        "message": "Locking Order was fallen",
                                        "mode":'dismissible'
                                    });
                                    toastEvent.fire();
                                }
                            }
                        })
                        $A.enqueueAction(action1);
                    }
                }
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