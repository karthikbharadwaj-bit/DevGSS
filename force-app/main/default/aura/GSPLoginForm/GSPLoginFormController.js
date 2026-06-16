({
    handleLogInClick: function (component, event, helper) {
        let userName = component.find("userName").get("v.value");
        let passWord = component.find("passWord").get("v.value");
        
        var url = new URL(location.href);
        var startURL = url.searchParams.get('startURL');
        console.log('startURL ' + startURL);
        
        let baseURL = url.href.substring(0, url.href.indexOf("/s"));
        component.set("v.baseURL" , baseURL);
        
        component.set('v.loginErrorMessage', "");
        component.set('v.resetErrorMessage', "");

        if (userName && passWord) {
            component.set('v.showSpinner', true);
            let loginAction = component.get("c.doLogin");
            loginAction.setParams({
                userName,
                passWord,
                startURL
            });
            loginAction.setCallback(this, (result) => {
                var state = result.getState();
                if (component.isValid() && state === "SUCCESS") {
                    let response = result.getReturnValue();
                    if (response.status === 'failure') {
                        component.set('v.loginErrorMessage', response.url);
                    }
                    else {
                        window.location.assign(response.url);
                    }
                    component.set('v.showSpinner', false);
                }
            });
            $A.enqueueAction(loginAction);
        }
    },
    handleForgotPasswordClick: function (component, event, helper) {
        component.set('v.loginErrorMessage', "");
        component.set('v.resetErrorMessage', "");
        component.set('v.showResetForm', true);
    },
    handleResetClick: function (component, event, helper) {
        let userName = component.find("resetUserName").get("v.value");

        component.set('v.loginErrorMessage', "");
        component.set('v.resetErrorMessage', "");

        if(userName) {
            component.set('v.showSpinner', true);
            let resetAction = component.get("c.doResetPassword");
            resetAction.setParams({
                userName,
            });
            resetAction.setCallback(this, (result) => {
                var state = result.getState();
                if (component.isValid() && state === "SUCCESS") {
                    let response = result.getReturnValue();
                    component.set('v.resetErrorMessage', response.url);
                    component.set('v.showSpinner', false);
                }
            });
            $A.enqueueAction(resetAction);
        }
    },
    handleGoBackClick: function (component, event, helper) {
        component.set('v.loginErrorMessage', "");
        component.set('v.resetErrorMessage', "");
        component.set('v.showResetForm', false);
    },
                loginAsGuest : function (component, event, helper) {
                    try
                    {
                        var url = new URL(location.href);
                        let baseURL = url.href.substring(0, url.href.indexOf("/s"));
                        console.log('basurl - ' + baseURL);
                        var urlEvent = $A.get("e.force:navigateToURL");
                        urlEvent.setParams({
                            'url': baseURL + '/s/gspguestlogin'
                        });
                        urlEvent.fire(); 
                        
                        /*var navService = component.find("navService");
                    var pageReference = {
    type: "comm__namedPage",
    attributes: {
        name: "gspguestlogin"
    }
                    };
                    navService.navigate(pageReference);
                    */
                    }
                    catch(e)
                    {
                        console.log('err - ' + e)
                    }
                },
                /*showSpinner: function (component, event, helper) {
                    var spinner = component.find("loadingSpinner");
                    $A.util.removeClass(spinner, "slds-hide");
                },
                hideSpinner: function (component, event, helper) {
                    var spinner = component.find("loadingSpinner");
                    $A.util.addClass(spinner, "slds-hide");
                },*/
                requestPortalAccess: function(component,event,helper){
                    try{
                        var url = new URL(location.href);
                        let baseURL = url.href.substring(0, url.href.indexOf("/s"));
                        console.log('basurl - ' + baseURL); 
                        var urlEvent = $A.get("e.force:navigateToURL");
                        urlEvent.setParams({
                            'url': baseURL + '/s/gspnewpartnerrequest'
                        });
                        urlEvent.fire();
                    }catch(e){
                        console.log('error '+e);
                    }
                }
                
})