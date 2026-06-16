({
    doInit : function(component, event, helper){
        console.log("doInit");
        component.set("v.isDisableSubmitButton", true);
        helper.getInitialData(component, helper);
    },

	submitApproval : function(component, event, helper) {
        helper.showSpinner(component);
        var action = component.get('c.submitforApproval');
        action.setParams({
            recId : component.get('v.recordId'),
            comment : component.get('v.comments')
        });
        action.setCallback(this,function(response){
         var state = response.getState();

		 if (state === "SUCCESS")
            {
                let recordTypeName = component.get('v.recordTypeDeveloperName');
                let message = recordTypeName == 'Credit_Limit_Increase'
                    ? "Credit Limit Increase Submitted for Approval. Refreshing the page..."
                    : "Legal Engagement Submitted for Approval. Refreshing the page...";
                helper.hideSpinner(component);
                var responseReceived = response.getReturnValue();
                if(responseReceived == null ){
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                    "type": "success",
                    "message": message,
                    "mode":'dismissible'
                });
                toastEvent.fire();
                $A.get("e.force:closeQuickAction").fire()
                    window.setTimeout(
                        $A.getCallback(function() {
					    $A.get('e.force:refreshView').fire();

                        }), 3000
                    );

                }else{
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "type": "error",
                    "title": "Unable to Submit record for Approval",
                    "message": responseReceived,

                });
                toastEvent.fire();

               $A.get("e.force:closeQuickAction").fire()
                }

            }
            else
            {
                helper.hideSpinner(component);
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "type": "error",
                    "message": "Unable to Submit record for Approval",
                    "mode":'dismissible'
                });
                toastEvent.fire();
                $A.get("e.force:closeQuickAction").fire();
            }
            },'SUCCESS');

        $A.enqueueAction(action,false);
	
	},
    
    closeModal : function(component, event, helper) {
		$A.get("e.force:closeQuickAction").fire();
	},
    
    
})