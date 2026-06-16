({
    doInit : function(component, event, helper) {
        var action=component.get("c.getUrlForSCPNavigation");
        action.setParams({
            "objectId" : component.get("v.recordId")
        });
        action.setCallback(this, function(response){
            $A.get("e.force:closeQuickAction").fire(); 
            var addStr = '';
            var state = response.getState();
            if(state == "SUCCESS"){
               var result = null;
               try {
                   result = response.getReturnValue();
                   var accUserId = result.data.accUserId;
                   var urlTemplate = result.data.urlTemplate;
                   if (accUserId && urlTemplate) {
                       var urlEvent = $A.get("e.force:navigateToURL");
                       urlEvent.setParams({
                           'url': urlTemplate.replace("${accountId}", accUserId)
                       });
                       urlEvent.fire();
                   } else {
                       throw 'RC User Id is either null or redirect link is undefined';
                   }
               } catch (e) {
                   var toastEvent = $A.get("e.force:showToast");
                   toastEvent.setParams({
                       "type": "error",
                       "title": "Error!",
                       "message": e || "There is some error while processing",
                       "mode":'dismissible'
                   });
                   toastEvent.fire();
               }
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
    
    showSpinner: function(component, event, helper) {        
        var spinner = component.find("loadingSpinner");
        $A.util.removeClass(spinner, "slds-hide");
    },   
    hideSpinner : function(component,event,helper){           
        var spinner = component.find("loadingSpinner");
        $A.util.addClass(spinner, "slds-hide");
    }
})