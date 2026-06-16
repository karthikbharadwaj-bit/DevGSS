({
    doInit : function(component) {        
        var action=component.get("c.validateContact");
        var recId = component.get("v.recordId");
        action.setParams({
            "ContactId":recId
        });
        action.setCallback(this, function(response){            
            var state = response.getState();            
            if(state=='SUCCESS'){                
                var retMap = JSON.parse(response.getReturnValue());

                for(var key in retMap){
                    if(key == 'RECORD'){
                        var con = JSON.parse(retMap[key]);
                        component.set("v.contactRecord", con);
                        component.set("v.contactCenterUsers", con.Forecasted_Contact_Center_Users__c);
                        component.set("v.engageDigitalUsers", con.Forecasted_Engage_Digital_Users__c);
                        component.set("v.engageVoiceUsers", con.Forecasted_Engage_Voice_Users__c);
                        component.set("v.globalOfficeUsers", con.Forecasted_Global_Office_Users__c);
                        component.set("v.officeUsers", con.Forecasted_Office_Users__c);
                        component.set("v.rcVideoUsers", con.Forecasted_RingCentral_Video_Users__c);
                    }
                    if(key == 'WARNING'){
                        var toastEvent = $A.get("e.force:showToast");
                        toastEvent.setParams({
                            "type": "warning",
                            "title": "Warning",
                            "message": retMap[key],
                            "mode":"sticky"
                            });
                            toastEvent.fire();
                    }
                    if(key == 'ERROR'){
                        $A.get("e.force:closeQuickAction").fire();
                        var msg = response.getReturnValue();
                        msg = msg.replace(" - MSG","\n");
                        var toastEvent = $A.get("e.force:showToast");
                        toastEvent.setParams({
                            "type": "error",
                            "title": "Unable to Create Opportunity",
                            "message": retMap[key],
                            "mode":"sticky"
                            });
                            toastEvent.fire();
                    }
                }
            }else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {                        
                        var toastEvent = $A.get("e.force:showToast");
                        toastEvent.setParams({
                            "type": "error",
                            "title": "Error",
                            "message": errors[0].message,
                            "mode":"sticky"
                            });
                        toastEvent.fire();
                    }
                } else {
                    console.log("Unknown error");
                }
            }                            
        });
        $A.enqueueAction(action);
    },
    showSpinner : function(component) {        
        var spinner = component.find("loadingSpinner");
        $A.util.removeClass(spinner, "slds-hide");
    },   
    
    hideSpinner : function(component){           
        var spinner = component.find("loadingSpinner");
        $A.util.addClass(spinner, "slds-hide");
    },
    
    handleCancel: function(){
        $A.get("e.force:closeQuickAction").fire();
    },

    handleSubmit : function(component){
        debugger;
        var accId = component.get("v.contactRecord").AccountId;
        var conId = component.get("v.contactRecord").Id;
        var action = component.get("c.checkAcctContactRole");
        action.setParams({
            "acctId":accId,            
            "contactId":conId,
        });
        action.setCallback(this, function(response){                   
            if (response.getState() === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {                        
                        var toastEvent = $A.get("e.force:showToast");
                        toastEvent.setParams({
                            "type": "error",
                            "title": "Error",
                            "message": errors[0].message,
                            "mode":"sticky"
                            });
                        toastEvent.fire();
                    }
                } else {
                    console.log("Unknown error");
                }
            }
        });
        $A.enqueueAction(action);

        component.set("v.showLoading", true);
        $A.get("e.force:closeQuickAction").fire();
        
        var contactCenterUsers = component.get("v.contactCenterUsers");
        var engageDigitalUsers = component.get("v.engageDigitalUsers");
        var engageVoiceUsers = component.get("v.engageVoiceUsers");
        var globalOfficeUsers = component.get("v.globalOfficeUsers");
        var officeUsers = component.get("v.officeUsers");
        var rcVideoUsers = component.get("v.rcVideoUsers");
        
        var url = '/lightning/o/Opportunity/new?saveNewUrl=%2F006%2Fe%3Flookupcmpgn%3D1%26fromContact%3D1%26fromContactId%3D' + conId;
        if(contactCenterUsers){
            url += '%26contactCenterUsers%3D' + contactCenterUsers;
        }
        if(engageDigitalUsers){
          url += '%26engageDigitalUsers%3D' + engageDigitalUsers;
        } 
        if(engageVoiceUsers){ 
            url += '%26engageVoiceUsers%3D' + engageVoiceUsers;
        } 
        if(globalOfficeUsers){ 
            url += '%26globalOfficeUsers%3D' + globalOfficeUsers;
        } 
        if(officeUsers){ 
            url += '%26officeUsers%3D' + officeUsers;
        } 
        if(rcVideoUsers){ 
            url += '%26rcVideoUsers%3D' + rcVideoUsers;
        }
        
        url += '%26accid%3D' + accId + '%26conid%3D' + conId + '%26opp6%3DService%2BProvider&nooverride=true&useRecordTypeCheck=true&retURL=%2F' + conId;
        var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
            'url': url
        });
        urlEvent.fire();
    }

})