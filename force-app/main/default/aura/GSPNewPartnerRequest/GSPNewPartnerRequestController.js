({
	doInit : function(component, event, helper) {
       
	},
    createContact: function(component, event, helper) {
        try
        {
            var phoneField = component.find('phoneNumberforContact');
            var phoneValue = phoneField.get('v.value');  
            var emailValue = component.get('v.guestEmail');
            console.log("phoneValue "+phoneValue+" emailValue "+emailValue);
            
            if(phoneValue == null || phoneValue == undefined || phoneValue == '' ||
               emailValue == null || emailValue == undefined || emailValue == ''){
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "type": "error",
                    "title": "Error!",
                    "message": "Please enter all the required details!",
                    "mode":'dismissible'
                });
                toastEvent.fire();
            }else{
                //if(isNaN(phoneValue)){
                var regex1  = new RegExp("^[0-9 ,+()-]*$");
                var isValidPhone = regex1.test(phoneValue);
                
                if(!isValidPhone){
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "type": "error",
                        "title": "Error!",
                        "message": "Please enter only numeric values in Phone Number field!",
                        "mode":'dismissible'
                    });
                    toastEvent.fire();
                }else {
                    console.log("calling insert contact");
                    helper.insertContact(component, event, helper);
                }                                    
            }
        }
        catch(e)
        {
            console.log('error - ' + e);
        }
    },
    showSpinner: function (component, event, helper) {
        var spinner = component.find("loadingSpinner");
        $A.util.removeClass(spinner, "slds-hide");
    },
    hideSpinner: function (component, event, helper) {
        var spinner = component.find("loadingSpinner");
        $A.util.addClass(spinner, "slds-hide");
    },
    validateEmail: function(component, event, helper){
        var RequestPartnerEmail = component.find('requestPartnerEmail').get('v.value');
        component.find('requestPartnerEmail').setCustomValidity('');
        component.set('v.ShowSpinnerOpp',true);
        console.log("inside validate email "+RequestPartnerEmail);
        if(!component.find('requestPartnerEmail').checkValidity())
            {
                component.find('requestPartnerEmail').reportValidity();
                return;
            }
        try{
            var action = component.get("c.checkContactEmail");
            action.setParams({
                "GuestEmail": RequestPartnerEmail
            });
            action.setCallback(this, function (result) {
                var state = result.getState();
                if (component.isValid() && state === "SUCCESS") {
                    var resultData = result.getReturnValue();
                    console.log('PartnerContactExist - ' + resultData.PartnerContactExist);
                    console.log('PartnerUserExist - ' + resultData.PartnerUserExist);
                    console.log('PartnerDomainExist - ' + resultData.PartnerDomainExist); 
                    //console.log('PartnerReltoDomain1 - ' + resultData.PartnerReltoDomain.Permitted_Brands__c);
                    //console.log('PartnerReltoDomain - ' + JSON.stringify(resultData.PartnerContactReltoEmail));
                    if(resultData.PartnerUserExist){
                        component.find('requestPartnerEmail').setCustomValidity('You have Portal Access, Please login as Partner.');
                        component.find('requestPartnerEmail').reportValidity();
                        return;
                    }
                    if(resultData.PartnerContactExist&&!resultData.PartnerUserExist){
                        component.set("v.showConfirmRequestModal",true);
                        component.set('v.showContactFields',false);
                        
                    }
                    if(resultData.PartnerDomainExist&&!resultData.PartnerContactExist){
                        component.set("v.PartnerReltoDomain", resultData.PartnerReltoDomain);
                        component.set("v.verifyEmail",true);
                        //component.set('v.showContactFields',true);
                        component.set('v.showEmailField',false);
                        
                    }
                    if(!resultData.PartnerDomainExist){
                        console.log("inside PartnerDomainExist false");
                        component.find('requestPartnerEmail').setCustomValidity('Partner with provided email domain does not exist');
                        component.find('requestPartnerEmail').reportValidity();
                        return;
                         /*var toastEvent = $A.get("e.force:showToast");
                        toastEvent.setParams({
                            'title': 'Info',
                            'type': 'error',
                            "mode":'dismissible',
                            'message': 'Please enter a email with a valid domain'
                        });                    
                        toastEvent.fire();*/
                    }
                } else if(state === "ERROR"){
                    console.log("Errors"+JSON.stringify(result.getError()));
                }
             });
        	$A.enqueueAction(action);
        }catch(e){
            console.error(e);
        }
    },
    goToValidateEmail: function(component,event,helper){
        component.set('v.verifyEmail',false);
        component.set('v.guestEmail','');
        component.set('v.enteredCode','');
        component.set('v.showContactFields',false);
        component.set('v.showEmailField',true);
    },
    requestForUserAccess: function(component,event,helper){
        component.set('v.ShowSpinnerOpp',true);
        console.log('inside requets method');
        helper.requestForPartnerUserAccess(component,event,helper);
    },
    closeModel : function(component, event, helper) {
        component.set("v.showConfirmRequestModal",false);
        component.set('v.showEmailField',true);
    },
    goToLogin : function(component, event, helper){
        var url = new URL(location.href);
        let baseURL = url.href.substring(0, url.href.indexOf("/s"));
        console.log('basurl - ' + baseURL);
        var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
            'url': baseURL + '/s/login'
        });
        urlEvent.fire();
    },
     enableVerify : function (component, event, helper) {
        let enteredCodeLen = component.get("v.enteredCode").length;
        if(enteredCodeLen == 6)
        {
            component.set("v.disableVerify" ,false);
        }
        else
        {
            component.find('VerificationCode').setCustomValidity('');
            component.find('VerificationCode').reportValidity();
            component.set("v.disableVerify" ,true);
        }
    },
    sendEmail : function (component, event, helper) {
        try
        {
            let verificationCode = Math.floor(100000 + Math.random() * 900000);
            component.set("v.GeneratedCode", verificationCode);
            let url = new URL(location.href);
            let baseURL = url.href.substring(0, url.href.indexOf("/s"));
            let imgURL = `${baseURL}/resource/GSP_Logo`;
            let emailBody = `<img src='${imgURL}' width="141" style="width:141px;margin-bottom:20px" />
                <p>GSP Portal Verification code : ${verificationCode}</p>
            <div style="margin-top:50px">
                <div>Regards,</div>
            <div>GSP Team</div>
            </div>`;
            var action = component.get("c.sendVerificationCode");
            action.setParams({
                "GuestEmail": component.get("v.guestEmail"),
                "verificationCode" : verificationCode,
                "emailBody" : emailBody
            });
            action.setCallback(this, function (result) {
                var state = result.getState();
                console.log('email state'+result.getState());
                var toastEvent = $A.get("e.force:showToast");                
                var navService = component.find("navService");
                if (component.isValid() && state === "SUCCESS") {
                    console.log('email sent successfully');
                }
            })
            $A.enqueueAction(action);
        }
        catch(e)
        {
            console.error('error - ' + e);
        }
    },
    verifyEmail : function (component, event, helper) {
        try
        {
        let GeneratedCode = component.get("v.GeneratedCode");
        let enteredCode = Number.parseInt(component.get("v.enteredCode"));
        console.log('email verify ' + (GeneratedCode == enteredCode));
        if(GeneratedCode === enteredCode)
        {
            component.set('v.showContactFields', true);
            component.set('v.verifyEmail', false);
            component.find('VerificationCode').setCustomValidity('');
            component.find('VerificationCode').reportValidity();
        }
        else
        {
            component.find('VerificationCode').setCustomValidity('Please enter valid verification code');
            component.find('VerificationCode').reportValidity();
        }
        }
        catch(e)
        {
            console.log('error - ' + e);
        }
    }
})