({
		doInit : function(component, event, helper) {
            var action=component.get("c.getCaseId");
            var recId = component.get("v.recordId");
           	action.setParams({
              	"recordId":recId
        	});
        	action.setCallback(this, function(response){
                 $A.get("e.force:closeQuickAction").fire();
                var state = response.getState();
            	if(state == "SUCCESS"){
					var caseRec = response.getReturnValue();
					// Added for ITPMO-2515
                    var recordtypename = response.getReturnValue().RecordType.DeveloperName;
                    if(recordtypename== 'GSP_Escalation'){
                        component.set("v.isGSP_Escalation",true);
                    }
                    if(caseRec.Jeopardy_Code__c!= "Completed" && caseRec.Jeopardy_Code__c!="Cancelled" && caseRec.Jeopardy_Code__c!= null && caseRec.Jeopardy_Code__c!= "" )
                    {
                    component.set("v.displayFormFlag", false);
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "type": "error",
                        "title": "Error!",
                        "message": 'You must first close the jeopardy',
                        "mode":'dismissible'
                    });
                    toastEvent.fire();
                    }
                    else {
                        
                    /*var editRecordEvent = $A.get("e.force:editRecord");
    				editRecordEvent.setParams({
        			 "recordId": recId
       					});
   					 editRecordEvent.fire();
  						//window.location.replace("/" + caseRec.Id + "/s?retURL=/" + caseRec.Id);*/
                        
						component.set("v.displayFormFlag", true);
             
           			 }
   
                }
                
                else
                {
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "type": "error",
                        "title": "Error!",
                        "message": 'There is some error while processing',
                        "mode":'dismissible'
                    });
                    toastEvent.fire();
                }
            });  
		 	$A.enqueueAction(action);
            // Added for ITPMO-2515
            helper.checkPermissionSetAccess(component, event, helper);
             // Added for ITPMO-2515
        },

    
  
    showSpinner: function(component, event, helper) {        
        var spinner = component.find("loadingSpinner");
        $A.util.removeClass(spinner, "slds-hide");
      },   
    hideSpinner : function(component,event,helper){           
        var spinner = component.find("loadingSpinner");
        $A.util.addClass(spinner, "slds-hide");
    },
    
    handleSubmit: function(component,event,helper){
        event.preventDefault(); // Prevent default submit
        var fields = event.getParam("fields");
        
        component.find('closeCaseForm').submit(fields); // Submit form
		console.log('handle handleSubmit');
        
        var soltitle = component.get("v.solTitle");
        var solDetails = component.get("v.solDetails");
        if((soltitle != null || solDetails != null) && component.get("v.submittopublicsol")==true){
            
            helper.createSolRecord(component, event, helper,soltitle, solDetails);
        }
                 
    },
    
    navbacktoCase : function(component, event, helper) {
        var recordId = component.get("v.recordId");
        console.log('record updated successfully');
       
        var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
            "url": "/"+recordId
        });
        urlEvent.fire();
        
	},
    
    togglepublicsubmit: function(component, event, helper){
        console.log("toggle==>" +component.get("v.submittopublicsol"));
        if(component.get("v.submittopublicsol") == false){
             var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "type": "warning",
                        "title": "Warning",
                        "message": "This solution will not be saved unless Submit to public solutions is checked."
                    });
                    toastEvent.fire();
        }
        
    }
})