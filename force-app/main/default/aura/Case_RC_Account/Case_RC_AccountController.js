({
    handleConfirmation : function(component, event, helper) {
        var action=component.get("c.launchRCAccount");
        action.setParams({
            "objectId" : component.get("v.recordId")
        });
        action.setCallback(this, function(response){
            $A.get("e.force:closeQuickAction").fire(); 
            var addStr = '';
            var state = response.getState();
            if(state == "SUCCESS"){
                var userId = response.getReturnValue();
                if(userId != null && userId.includes('Error'))
                {
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "type": "error",
                        "title": "Error!",
                        "message": response.getReturnValue(),
                        "mode":'dismissible'
                    });
                    toastEvent.fire();
                }
                else if(userId != null && userId != '' && userId != undefined)
                {
                    var includePlusSigns = 20 - userId.length;
                    for(var i = 0; i < includePlusSigns; i++) {
                        addStr +='+';
                    }
                    //window.open('https://admin.ringcentral.com/userinfo/csaccount.asp?user=XPDBID'+addStr+userId+'User','','width=1000,height=800');
                    //window.open('https://ringcentral.okta.com/app/ringcentralinc_adminweb20_1/exk1fmdmo1zkmQxpg1d8/sso/saml?RelayState=https://admin.ringcentral.com/userinfo/csaccount.asp?user=XPDBID'+addStr+userId+'User');
                    var urlEvent = $A.get("e.force:navigateToURL");
                    urlEvent.setParams({
                        'url': 'https://ringcentral.okta.com/app/ringcentralinc_adminweb20_1/exk1fmdmo1zkmQxpg1d8/sso/saml?RelayState=https://admin.ringcentral.com/userinfo/csaccount.asp?user=XPDBID'+addStr+userId+'User'
                    });
                    urlEvent.fire();
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
    handleConfirmationSCP : function(component, event, helper) {
        var urlActoion = component.get("c.getUrlForSCPNavigation");
        urlActoion.setParams({
            "objectId":component.get("v.recordId")

        });
        urlActoion.setCallback(this, function(response){
            $A.get("e.force:closeQuickAction").fire();
            var state = response.getState();
            if(state == "SUCCESS"){
                var result = null;
                try {
                    result = response.getReturnValue();
                    var accUserId = result.data.accUserId;
                    var urlTemplate = result.data.urlTemplate;
                    if (accUserId && urlTemplate) {
                        var urlEvent = $A.get("e.force:navigateToURL");
                        urlEvent.setParams({
                            'url': urlTemplate.replace("${accountId}", accUserId)
                        });
                        urlEvent.fire();
                    } else {
                        throw 'RC User Id is either null or redirect link is undefined';
                    }
                }
                catch (e) {
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "type": "error",
                        "title": "Error!",
                        "message": e || "There is some error while processing",
                        "mode":'dismissible'
                    });
                    toastEvent.fire();
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
        $A.enqueueAction(urlActoion);
    },
    
    doInit: function(component, event, helper) {
        var action = component.get("c.shouldHideYesButton");
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                component.set("v.hideYesButton", response.getReturnValue());
            }
            else {
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "type": "error",
                    "title": "Error!",
                    "message": "Unable to determine button visibility. Please try again.",
                    "mode": "dismissible"
                });
                toastEvent.fire();
            }
        });
        $A.enqueueAction(action);
    },

    showToastEvent: function(params) {
        var event = $A.get("e.force:showToast");
        event.setParams({
            "type": params.type,
            "title": params.title,
            "message": params.message,
            "mode": params.mode || 'dismissible'
        });
        event.fire();
    },
    showSpinner: function(component, event, helper) {        
        var spinner = component.find("loadingSpinner");
        $A.util.removeClass(spinner, "slds-hide");
        component.set('v.displayConfirmMessage',false);
    },   
    hideSpinner : function(component,event,helper){           
        var spinner = component.find("loadingSpinner");
        $A.util.addClass(spinner, "slds-hide");
        component.set('v.displayConfirmMessage',true);
    },
    closeModal : function(component, event, helper) {
        $A.get('e.force:refreshView').fire();    },
})