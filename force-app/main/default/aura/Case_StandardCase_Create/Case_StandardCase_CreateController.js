({
	/*createCase : function(component, event, helper) {
		var myPageRef = component.get("v.pageReference");
        var accId = myPageRef.state.c__accId;
        var rectypeId = myPageRef.state.c__recTypeId;
       var conId = myPageRef.state.c__conId;
		console.log("rec and acc ids*" +accId+","+rectypeId);        
         var createRecordEvent = $A.get("e.force:createRecord");
                                
                createRecordEvent.setParams({
                    "entityApiName": "Case",
                    "recordTypeId": rectypeId,
                    'defaultFieldValues': {
                        'AccountId' : accId,
                        'ContactId' : conId
                        
                    }
                    
                });
                createRecordEvent.fire();

                
	},*/
    createCase : function(component, event, helper){
        
        var ref = component.get("v.pageReference");
        var accid;
        var recid;
        var contactid;
        var inconid;
        var state = ref.state; 
        var context;
        if (!component.get('v.base64context') && state.inContextOfRef) {
            component.set('v.base64context', state.inContextOfRef);
            context = state.inContextOfRef;
        } else if (component.get('v.base64context')) {
            context = component.get('v.base64context');
        }
        if (context && context.startsWith("1\.")) {
            context = context.substring(2);
            var addressableContext = JSON.parse(window.atob(context));
            if(addressableContext.attributes.recordId != undefined)
            {
                if(addressableContext.attributes.recordId.startsWith("001")){
                    accid = addressableContext.attributes.recordId; 
                }
                
                if(addressableContext.attributes.recordId.startsWith("003")){
                    contactid = addressableContext.attributes.recordId; 
                }
            }            
        }
        var recordTypeId = component.get("v.pageReference").state.recordTypeId;
        var userId = $A.get("$SObjectType.CurrentUser.Id");
        //Invoking method
        var action = component.get("c.fetchRecordDetailsCase");
        action.setParams({ accId : accid,
                          rectypeId : recordTypeId,
                          contactId : contactid,
                          userId : userId                          
                         })
        action.setCallback(this, function(response) {
            $A.get("e.force:closeQuickAction").fire();
            var state = response.getState();
            if (state === "SUCCESS") {
                var retResponse = response.getReturnValue();
                
                if(retResponse.Url == "STANDARD PAGE" ){
                    
                    var caseRecord = {};
                    if(retResponse.accountId_access){
                            caseRecord.AccountId = retResponse.accountIdComp ? retResponse.accountIdComp : null ;
                        }
                        
                        if(retResponse.contactId_access){
                            caseRecord.ContactId =  retResponse.contactIdComp  ? retResponse.contactIdComp : null;
                        }
                    
                     var createRecordEvent = $A.get("e.force:createRecord");
                    createRecordEvent.setParams({
                        "entityApiName": "Case",
                        "recordTypeId": recordTypeId,
                        'defaultFieldValues': caseRecord
                    });
                    createRecordEvent.fire();
                                 
                }else{
                    
                     var urlEvent = $A.get("e.force:navigateToURL");
                    urlEvent.setParams({
                        'url': retResponse.baseUrl+'/'+retResponse.Url,
                        "isredirect": "true"
                    });
                    urlEvent.fire();  
                }
                
            }
            else {
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