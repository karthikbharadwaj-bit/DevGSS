({
  doInit : function(component, event, helper) {
    var action=component.get("c.getOpprecord");
        var recId = component.get("v.recordId");
        action.setParams({
              "recordId":recId
        });
        action.setCallback(this, function(response){
            
            var state = response.getState();  
            console.log('State'+state);
            if(state=='SUCCESS'){
                var Oppresponse = response.getReturnValue();
                console.log(JSON.stringify(Oppresponse));
                console.log('SM Employees'+Oppresponse.Account.SM_Employees__c);
                
                if(Oppresponse.Account.SM_Employees__c == undefined)
                {
                    var toastEvent = $A.get("e.force:showToast");
                  toastEvent.setParams({
                    "type": "error",
                    "title": "Error!",
                    "message": "SM Employees field on the Account is mandatory before involving Reseller - please contact tamhelp@ringcentral.com",
                    "mode":'dismissible'
                    });
                    toastEvent.fire();
                    $A.get("e.force:closeQuickAction").fire();
              }
                
                else{
                    console.log('sm emp success');
                    var action2 = component.get("c.getIsAllForecastedUsersZero");
                    action2.setParams({
                      "recordId":recId
                     });
                    action2.setCallback(this, function(response){ 
                      var state = response.getState(); 
                      console.log('STATE'+state);
                      if (state == 'SUCCESS'){
                        var isAllForecastedUsersZero = response.getReturnValue();
                        console.log(isAllForecastedUsersZero);
                        if(JSON.stringify(isAllForecastedUsersZero) == 'true'){
                            var toastEvent = $A.get("e.force:showToast");
                            toastEvent.setParams({
                            "type": "error",
                            "title": "Error!",
                            "message": "Fill in at least one of the Forecasted Users fields on the Opportunity before involving Reseller. ",
                            "mode":'dismissible'
                            });
                            toastEvent.fire();
                            $A.get("e.force:closeQuickAction").fire();
                        }
                        else{
                            var action3=component.get("c.getApprovalrecordtype");
                            action3.setParams({
                                "recordId":recId
                                   });
                            action3.setCallback(this, function(response){
                                  var state = response.getState();  
                                    console.log('State-app'+state);
                                  if(state=='SUCCESS'){
                                    var Appresponse = response.getReturnValue();
                                    console.log(JSON.stringify(Appresponse));
                                    if(JSON.stringify(Appresponse) =='true')
                                    {
                                        var toastEvent = $A.get("e.force:showToast");
                                        toastEvent.setParams({
                                        "type": "error",
                                        "title": "Error!",
                                        "message": "Approval record with 'Channel Cross Sell' Record Type already exists for this opportunity.",
                                        "mode":'dismissible'
                                                });
                                            toastEvent.fire();
                                        $A.get("e.force:closeQuickAction").fire();
                                    }   
                                    else{
                                        var device = $A.get("$Browser.formFactor");
                                        if(device == 'DESKTOP')
                                        {
                                          console.log('REDIRECT');
                                          var win = window.location.href = '/apex/ApprovalBeforeCreateForm?OpportunityId='+recId;
                               
                                        }
                                        else
                                        {
                                            var urlEvent = $A.get("e.force:navigateToURL");
                                            urlEvent.setParams({
                                                'url': '/apex/ApprovalBeforeCreateForm?OpportunityId='+recId
                                            });
                                            urlEvent.fire();
                                        } 
                                      
                                  
                                    } 
                            }
                            });
                            $A.enqueueAction(action3);
                        }
                      }
                      
                    });
                    $A.enqueueAction(action2);
                }
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
    }
})