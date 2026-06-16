({
    doInit : function(component, event, helper) {
        var action=component.get("c.launchRCAccount");
        action.setParams({
            "objectId":component.get("v.recordId")
            
        });
        action.setCallback(this, function(response){
            $A.get("e.force:closeQuickAction").fire(); 
            var addStr = '';
            var state = response.getState();
            if(state == "SUCCESS"){
                var accObj = response.getReturnValue();
                if(accObj.rcUserid != null && accObj.errorMessage != null)
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
                else
                {
                    if(accObj.rcUserid != null && accObj.rcUserid != '' && accObj.rcUserid != undefined && accObj.rcUserid.length < 20)
                    {
                        var includePlusSigns = 20 - accObj.rcUserid.length;
                        for(var i = 0; i < includePlusSigns; i++) {
                            addStr +='+';
                            
                        }
                       /*window.open('https://admin.ringcentral.com/userinfo/csaccount.asp?user=XPDBID'+addStr+userId+'User');
                        var urlEvent = $A.get("e.force:navigateToURL");
                        urlEvent.setParams({
                            'url': 'https://admin.ringcentral.com/userinfo/csaccount.asp?user=XPDBID'+addStr+userId+'User'
                        });
                        urlEvent.fire();*/
                        //window.open('https://ringcentral.okta.com/app/ringcentralinc_adminweb20_1/exk1fmdmo1zkmQxpg1d8/sso/saml?RelayState=https://admin.ringcentral.com/userinfo/csaccount.asp?user=XPDBID'+addStr+userId+'User');
                        //window.open('https://sso.ringcentral.com/sp/startSSO.ping?PartnerIdpId=http%3A%2F%2Fwww.okta.com%2Fexk1fmdmo1zkmQxpg1d8&TargetResource=https://admin.ringcentral.com/home?cmd=login');
                        var urlEvent = $A.get("e.force:navigateToURL");
                        if(accObj.brandName != 'AT&T Office@Hand'){
                            urlEvent.setParams({
                                'url': 'https://ringcentral.okta.com/app/ringcentralinc_adminweb20_1/exk1fmdmo1zkmQxpg1d8/sso/saml?RelayState=https://admin.ringcentral.com/userinfo/csaccount.asp?user=XPDBID'+addStr+accObj.rcUserid+'User'
                            });
                            urlEvent.fire();    
                        } else {
                            urlEvent.setParams({
                                'url': 'https://ringcentral.okta.com/app/ringcentralinc_adminweb20_1/exk1fmdmo1zkmQxpg1d8/sso/saml?RelayState=https://admin.ringcentral.biz/userinfo/csaccount.asp?user=XPDBID'+addStr+accObj.rcUserid+'User'
                            });
                            urlEvent.fire();
                        }
                    }
                    else if(accObj.rcUserid == null || accObj.rcUserid == '' || accObj.rcUserid == undefined || (accObj.rcUserid != null && accObj.rcUserid.length > 20))
                    {
                        var toastEvent = $A.get("e.force:showToast");
                        toastEvent.setParams({
                            "type": "error",
                            "title": "Error!",
                            "message": "UserId is either Null or greater than 20",
                            "mode":'dismissible'
                        });
                        toastEvent.fire();
                    }
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