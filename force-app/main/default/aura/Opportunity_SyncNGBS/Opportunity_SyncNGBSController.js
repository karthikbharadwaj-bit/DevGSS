({

    setup:function(component,event,helper){
        console.log("Setup in controller");
		var recId = component.get("v.recordId");
        var action=component.get("c.getOppBillingDetail");
        action.setParams({
            "OppId":recId
            
        });
        action.setCallback(this, function(response){
            var state = response.getState();
            if(state == "SUCCESS"){
                console.log("INSIDE SUCCESS");
                var OppObj = response.getReturnValue();
                var opportunityId=OppObj.Id;
                var isBillingOpportunity=OppObj.Is_Billing_Opportunity__c;
                var rcnotify= this._rcnotify;
                console.log("rcnotify>>"+this._rcnotify);
                //console.log("buttons>>"+buttons);
                //console.log("this.button>>"+this.buttons);
                helper.sync(component,event,helper,opportunityId,isBillingOpportunity,rcnotify);
             }
            else{
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
    },
  
 })