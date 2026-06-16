({
    doInit: function(component, event, helper) {  
        
         var action=component.get("c.getCount");
            var recId = component.get("v.recordId");
           	action.setParams({
              	"recordId":recId
        			});
               	action.setCallback(this, function(response){
                var state = response.getState();
               
            	if(state == "SUCCESS"){
					var Agrec = response.getReturnValue();
                    console.log('Agrec'+Agrec);
                    if(Agrec==1)
                    {
                         var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "type": "error",
                        "title": "Error!",
                        "message": 'The agent credit transfer period has passed, you cannot make this request. Please send an email to salesopshelp@ringcentral.com',
                        "mode":'dismissible'
                    });
                    toastEvent.fire();
                    }
                    else
                    {
                         var action1=component.get("c.getrecord");
                        var recId = component.get("v.recordId");
                        action1.setParams({
                            "recordId":recId
                                });
                            action1.setCallback(this, function(response){
                            var state = response.getState();
               
            	    if(state == "SUCCESS"){
                        var Ag = response.getReturnValue();
                        console.log('Agcerdit'+JSON.stringify(Ag));
                        console.log('rid'+Ag[0]);
                        var rid = Ag[0];
                        var userId = $A.get("$SObjectType.CurrentUser.Id");
                        
                        var createAcountContactEvent = $A.get("e.force:createRecord");
                            createAcountContactEvent.setParams({
                                "entityApiName": "Approval__c",
                                "defaultFieldValues": {
                                    'Account__c' : Ag[1],
                                    'Name' : 'Agent'+'Credit'+'Transfers'+'-'+ Ag[2],
                                    "RecordTypeId":rid,
                                    "Credit_Transfer_To_Agent__c":userId,
                                    "Agent_Credit__c":recId
                                    
                                }
                            });
                            createAcountContactEvent.fire();
                        
                    }
                            });
                        
                        
                    $A.enqueueAction(action1);     
                        
                        
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