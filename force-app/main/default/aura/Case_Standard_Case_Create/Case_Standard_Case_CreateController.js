({
    doInit : function(component, event, helper) {
        let reference = component.get("v.pageReference");
        let state = reference.state;
        let base64Context;
        if (!component.get('v.base64context') && state.inContextOfRef) {
            component.set('v.base64context', state.inContextOfRef);
            base64Context = state.inContextOfRef;
        } else if (component.get('v.base64context')) {
            base64Context = component.get('v.base64context');
        }
        if (base64Context) {
            if (base64Context.startsWith("1\.")) {
                base64Context = base64Context.substring(2);
            }
            let addressableContext = JSON.parse(window.atob(base64Context));
            component.set("v.recordId", addressableContext.attributes.recordId);
            component.set("v.parentObject", addressableContext.attributes.objectApiName);
        }
        
        let recordId = component.get('v.recordId');
        
        if(recordId !== undefined ){
            component.set('v.isFromAccount',true);
        }
        let action = component.get('c.getInitialData');
        action.setParams({ recordId : recordId});
        action.setCallback(this, function(response) {
            let state = response.getState();
            if (state === 'SUCCESS') {
                let data = response.getReturnValue();
                let recordTypes =  data;
                component.set('v.recordTypes', recordTypes);
            } else {
                console.log('>>>Can\'t get data');
            }
        });
        $A.enqueueAction(action);
    },  
    recordProf : function(component, event, helper) {
        const profileName = component.get('v.CurrentUser')['Profile'].Name;
        var allowedProfiles = $A.get("$Label.c.Profile_to_Create_Support_Billing_Case_ACO");
        let recordTypes = component.get('v.recordTypes');
        let action = component.get('c.getBrandName');
        action.setParams({ recordId : component.get("v.recordId")});
        action.setCallback(this, function(response) {
            let state = response.getState();
            if (state === 'SUCCESS') {
                let data = response.getReturnValue();
                console.log('Accnt Data --> '+JSON.stringify(data));
                for (let option of recordTypes) {
                    option.Disabled = false;
                    option.Notification = '';
                    if(data === 'Avaya Cloud Office'){
                        if ((allowedProfiles.includes(profileName.trim()))
                            && option.Name === 'Support - Billing') {
                            option.Disabled = false;
                        }else if(option.Name === 'Support - Billing'){
                            option.Disabled = true;
                            option.Notification = 'Please submit a case by emailing acobilling@avaya.com.';
                        }
                    }else{
                        
                    }
                }
                component.set('v.recordTypes', recordTypes);
            } else {
                console.log('>>>Can\'t get data');
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
    cancelCaseCreation: function(component) {
        var showSpinAct = component.get('c.showSpinner');
        $A.enqueueAction(showSpinAct);
        
        const recordId = component.get("v.recordId");
        if (recordId != null) {
            let navigationEvent = $A.get("e.force:navigateToSObject");
            navigationEvent.setParams({
                "recordId": recordId
            });
            navigationEvent.fire();
        } else {
            let navigateLightning = component.find("navigate");
            const targetObject = component.get("v.parentObject");
            let targetPage = {
                type: "standard__objectPage",
                attributes: {
                    objectApiName: targetObject,
                    actionName: "list"
                },
                state: {
                    filterName: "Recent"
                }
            };
            
            navigateLightning.navigate(targetPage);
        }
        
        $A.get('e.force:refreshView').fire();
        component.destroy();
        
    },
    createCase : function(component, event, helper) {
        var showSpinAct = component.get('c.showSpinner');
        $A.enqueueAction(showSpinAct);
        let recordTypeId;
        if (document.querySelector('input[name="recordTypeRadio"]:checked')) {
            var hideSpinAct = component.get('c.hideSpinner');
            $A.enqueueAction(hideSpinAct);
            recordTypeId = document.querySelector('input[name="recordTypeRadio"]:checked').id;
            
            var accid;
            var recid;
            var oppid;
            var conid;
            let recordId = component.get("v.recordId");
            if (recordTypeId) {
                if (recordId !== undefined) {
                    if (recordId.startsWith("001")) {
                        accid = recordId;
                        recid = accid;
                    }
                    if (recordId.startsWith("006")) {
                    	oppid = recordId;
                    	recid = oppid;
                	}
                    if (recordId.startsWith("003")) {
                    	conid = recordId;
                    	recid = conid;
                	}
                    
                }
                let action = component.get('c.checkfieldAccess');
                action.setCallback(this, function(response) {
                    let state = response.getState();
                    if (state === 'SUCCESS') {
                        let retResponse = response.getReturnValue();
                        
                        if (retResponse != null) {
                            if (!retResponse.accountId_accessible) {
                                let toastEvent = $A.get("e.force:showToast");
                                toastEvent.setParams({
                                    "type": "error",
                                    "title": "Error!",
                                    "message": "Don't have access to create Case",
                                    "mode": 'dismissible'
                                });
                                toastEvent.fire();
                            } else if (!retResponse.contactId_accessible){
                                let toastEvent = $A.get("e.force:showToast");
                                
                                toastEvent.setParams({
                                    "type": "error",
                                    "title": "Error!",
                                    "message": "Don't have access to create Case",
                                    "mode": 'dismissible'
                                });
                                toastEvent.fire();
                            }else if(retResponse.contactId_accessible 
                                     && retResponse.accountId_accessible){
                                
                                var userId = $A.get("$SObjectType.CurrentUser.Id");
                                var caseRecord = {};
                                
                                if(accid !== undefined){
                                    caseRecord.AccountId = accid;
                                }                                
                                if(conid !== undefined){
                                    caseRecord.ContactId = conid;
                                }
                                
                                var createRecordEvent = $A.get("e.force:createRecord");
                                
                                createRecordEvent.setParams({
                                    "entityApiName": "Case",
                                    "recordTypeId": recordTypeId,
                                    'defaultFieldValues': caseRecord
                                });
                                createRecordEvent.fire();
                            }
                        }
                    } else {
                        console.log('>>>Can\'t get data');
                    }
                    $A.get('e.force:refreshView').fire();
                });
                $A.enqueueAction(action);
                
                
            } else {
                var hideSpinAct = component.get('c.hideSpinner');
                $A.enqueueAction(hideSpinAct);
                let toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "type": "error",
                    "title": "Record Type is not selected!",
                    "message": "Please, select Record Type",
                    "mode": 'dismissible'
                });
                toastEvent.fire();
            }
        }else{
            var hideSpinAct = component.get('c.hideSpinner');
            $A.enqueueAction(hideSpinAct);
            let toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                "type": "error",
                "title": "Record Type is not selected!",
                "message": "Please, select Record Type",
                "mode": 'dismissible'
            });
            toastEvent.fire();
        }
    }
})