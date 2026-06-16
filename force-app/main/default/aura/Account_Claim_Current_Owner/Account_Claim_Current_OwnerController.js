({
	doInit : function(component, event, helper) {
		var action=component.get("c.claimCurrentOwner");
        var recId = component.get("v.recordId");
        action.setParams({
              "recordId":recId
        });
        action.setCallback(this, function(response){
            $A.get("e.force:closeQuickAction").fire();
            var state = response.getState();  
            if(state=='SUCCESS'){
                var retResponse = response.getReturnValue().response;
                if(retResponse == 'Success')
                {
                	var wrapper = response.getReturnValue();
                    var recordType;
                    var approvalrecord = {};
                    if(wrapper.recordType_access){
                            recordType = wrapper.recordTypeId ? wrapper.recordTypeId : null ;
                        }
                        
                        if(wrapper.account_access){
                            approvalrecord.Account__c =  wrapper.acc.Id  ? wrapper.acc.Id : null;
                        }
                    if(wrapper.claimingRequestor_access){
                            approvalrecord.Claiming_Requestor__c = wrapper.usr.Id ? wrapper.usr.Id : null ;
                        }
                        
                        if(wrapper.level1Approver_access){
                            approvalrecord.Level1Approver__c =  wrapper.usr.Id  ? wrapper.usr.Id : null;
                        }
                    if(wrapper.CurrentOwner_access){
                            approvalrecord.Current_Owner__c =  wrapper.acc.OwnerId  ? wrapper.acc.OwnerId : null;
                        }
                    console.log(JSON.stringify(wrapper));
                    var createRecordEvent = $A.get("e.force:createRecord");
                    createRecordEvent.setParams({
                        "entityApiName": 'Approval__c',
                        "recordTypeId": recordType,
                        "defaultFieldValues":approvalrecord
                        
                    });
                    createRecordEvent.fire();
                }
                else
                {
                    var toastEvent = $A.get("e.force:showToast");
                	toastEvent.setParams({
                    "type": "error",
                    "title": "Error!",
                    "message": retResponse,
                    "mode":'dismissible'
                	});
                	toastEvent.fire();
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