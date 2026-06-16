({
        doInit : function(component, event, helper) {
            var action=component.get("c.getContact");
            var recId = component.get("v.recordId");
           	action.setParams({
              	"recordId":recId
        			});
           
               	action.setCallback(this, function(response){
                 $A.get("e.force:closeQuickAction").fire();
                var state = response.getState();
               
            	if(state == "SUCCESS"){
                    
                         var Contact = response.getReturnValue();
                            var contactId=Contact.ContactID18Digit__c;
                            var emailId=Contact.Email;
                            var url="/apex/MarketoLeadActivities?contactId="+contactId+'&email='+emailId;
                           
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
                                'url':'/apex/MarketoLeadActivities?contactId='+contactId+'&email='+emailId+params
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