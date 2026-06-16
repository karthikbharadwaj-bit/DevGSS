({
    handleLogInClick: function (component, event, helper) {
        let userName = component.find("userName").get("v.value");
        let passWord = component.find("passWord").get("v.value");
        
        var url = new URL(location.href);
        var startURL = url.searchParams.get('startURL');
        console.log('startURL ' + startURL);
        
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
    keyCheck: function (component, event, helper) {
        try
        {
        let userName = component.find("userName").get("v.value");
        let passWord = component.find("passWord").get("v.value");
        
        var url = new URL(location.href);
        var startURL = url.searchParams.get('startURL');
        console.log('startURL ' + startURL);
        
        component.set('v.loginErrorMessage', "");
        component.set('v.resetErrorMessage', "");
		if (event.which == 13){
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
        }
            }
                catch(e)
                {
                console.log('err - ' + e);
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
    }
})