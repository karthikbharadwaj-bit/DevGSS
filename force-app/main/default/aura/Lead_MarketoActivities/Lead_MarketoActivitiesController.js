({
        doInit : function(component, event, helper) {
            var action=component.get("c.getLead");
            var recId = component.get("v.recordId");
           	action.setParams({
              	"recordId":recId
        	});
           
            action.setCallback(this, function(response){
            $A.get("e.force:closeQuickAction").fire();
            var state = response.getState();
               
            if(state == "SUCCESS"){
              var Lead = response.getReturnValue();
              var sfdcId=Lead.LeadID18Digit__c;
              var emailId=Lead.Email;
              var url="/apex/MarketoLeadActivities?sfdcId="+sfdcId+'&email='+emailId;
              var params ='' ;
              params = 'width='+(screen.width-5);
              params += ', height='+(screen.height-100);
              params += ', top=0, left=0'
              params += ', fullscreen=yes';
              params += ', scrollbars=yes';
              params += ', resizable=yes';
                            
                               
              var device = $A.get("$Browser.formFactor");
                            
              if(device == 'DESKTOP')
              {
                 var myWindow=window.open(url,'mywin', params);
                 myWindow.focus();
              }
              else{
                var urlEvent = $A.get("e.force:navigateToURL");
                 urlEvent.setParams({
                          'url':'/apex/MarketoLeadActivities?sfdcId='+sfdcId+'&email='+emailId+params
                 });
                 urlEvent.fire();
                                
              }
			}
            else {
              var toastEvent = $A.get("e.force:showToast");
              toastEvent.setParams({
                            "type": "error",
                            "title": "Error!",
                            "message": 'There is a error while Processing',
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