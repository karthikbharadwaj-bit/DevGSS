({
	recallingApproval : function(component, event, helper) {
        helper.showSpinner(component);
        var action = component.get('c.recallApproval');
        action.setParams({"recId" : component.get('v.recordId')});
        action.setCallback(this,function(response){
         var state = response.getState();
            
		 if (state === "SUCCESS")
            {
                helper.hideSpinner(component);
                var responseReceived = response.getReturnValue();
                console.log(responseReceived);
                if(responseReceived == null){
                    console.log("entered if");
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "type": "Success",
                        "message": "Engage Legal Approval Recalled. Refreshing the page...",
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
                    console.log( "else");
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "type": "Error",
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
                    "message": "Unable to Recall record",
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