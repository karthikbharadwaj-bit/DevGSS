({
    init : function(component, event, helper) {
        try
        {
            /*console.log('ShowSpinnerOpp - ' + component.get("v.ShowSpinnerOpp"));
            console.log('ShowValidateEmail - ' + component.get("v.ShowValidateEmail"));
            console.log('showContactForm - ' + component.get("v.showContactForm"));
            console.log('showNewDealReg - ' + component.get("v.showNewDealReg"));*/
        }
        catch(e)
        {
            console.log('error - ' + e);
        }
    },
    GuestLogin : function(component, event, helper) {
        try
        {
            console.log('Email isValid - ' + component.find('GuestEmail').checkValidity());
            component.find('GuestEmail').setCustomValidity('');
            let baseURL = component.get("v.baseURL");  
            var GuestEmail = component.find('GuestEmail').get('v.value');
            component.set('v.GuestEmail', GuestEmail);            
            if(!component.find('GuestEmail').checkValidity())
            {
                component.find('GuestEmail').reportValidity();
                return;
            }
            var action = component.get("c.checkContactEmail");
            action.setParams({
                "GuestEmail": GuestEmail
            });
            action.setCallback(this, function (result) {
                var state = result.getState();
                var toastEvent = $A.get("e.force:showToast");                
                var navService = component.find("navService");
                if (component.isValid() && state === "SUCCESS") {
                    var resultData = result.getReturnValue();
                    console.log('PartnerContactExist - ' + resultData.PartnerContactExist);
                    console.log('PartnerUserExist - ' + resultData.PartnerUserExist);
                    console.log('PartnerDomainExist - ' + resultData.PartnerDomainExist); 
                    console.log('PartnersReltoDomain - ' + JSON.stringify(resultData.PartnersReltoDomain)); 
                    if(resultData.PartnerReltoDomain != undefined)
                        console.log('PartnerReltoDomain - ' + resultData.PartnerReltoDomain.Name);
                    console.log('!resultData.PartnerDomainExist - ' + !resultData.PartnerDomainExist);
                    
                    if(resultData.PartnerUserExist)
                    {
                        component.find('GuestEmail').setCustomValidity('You have Portal Access, Please login as Partner.');
                        component.find('GuestEmail').reportValidity();
                        return;
                    }
                    if(!resultData.PartnerDomainExist)
                    {
                        component.find('GuestEmail').setCustomValidity('Partner with provided email domain does not exist');
                        component.find('GuestEmail').reportValidity();
                        return;
                    }
                    if(resultData.PartnerContactExist)
                    {                        
                        component.set("v.contactReltoEmail", resultData.PartnerContactReltoEmail);
                        let partnerContact = component.get("v.partnerContact");
                        partnerContact['Id'] = resultData.PartnerContactReltoEmail.Id;
                        partnerContact['Permitted_Brands__c'] = resultData.PartnerContactReltoEmail.Account.Permitted_Brands__c;
                        component.set("v.partnerContact", partnerContact);
                        component.set('v.ShowValidateEmail', false);
                        component.set("v.showNewDealReg", true);
                    }
                    else
                    {
                        component.set("v.PartnerReltoDomain", resultData.PartnerReltoDomain);
                        component.set("v.contactReltoDomain", resultData.PartnerReltoDomain);
                        let partnerContact = component.get("v.partnerContact");
                        partnerContact['Permitted_Brands__c'] = resultData.PartnerReltoDomain.Permitted_Brands__c;
                        component.set("v.partnerContact", partnerContact);
                        component.set('v.ShowValidateEmail', false);
                        component.set('v.verifyEmail', true);
                    }
                }
            });
            $A.enqueueAction(action);
        }
        catch(e)
        {
            console.log('error - ' + e);
        }
    },
    createContact: function(component, event, helper) {
        try
        {
            var phoneField = component.find('phoneNumberforContact');
            var phoneValue = phoneField.get('v.value');  
            var emailValue = component.get('v.GuestEmail');
            
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
                    helper.insertContact(component, event, helper);
                }                                    
            }
        }
        catch(e)
        {
            console.log('error - ' + e);
        }
    },
    cancelContact : function (component, event, helper) {
        component.set('v.ShowValidateEmail', true);
        component.set('v.showContactForm', false);  
        component.set("v.GeneratedCode",'');
        component.set("v.enteredCode",'');
        component.set("v.contact", {
                             'SObjectType': 'Contact',
                             'FirstName': '',
                             'LastName': '',
                             'Email': '',
                             'Phone': '',
                             'Partner_Portal_View__c': 'Limited'
                             });
        component.set("v.disableVerify" ,true);
    },
    showSpinner: function (component, event, helper) {
        var spinner = component.find("loadingSpinner");
        $A.util.removeClass(spinner, "slds-hide");
    },
    hideSpinner: function (component, event, helper) {
        var spinner = component.find("loadingSpinner");
        $A.util.addClass(spinner, "slds-hide");
    },
    GoBacktoLogin : function (component, event, helper) {
        try
        {
            var navService = component.find("navService");
            var pageReference = {
                type : "comm__loginPage",
                attributes : {
                    actionName : "login"
                }
            };
            navService.navigate(pageReference);
        }
        catch(e)
        {
            console.error('error - ' + e);
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
                "GuestEmail": component.get("v.GuestEmail"),
                "verificationCode" : verificationCode,
                "emailBody" : emailBody
            });
            action.setCallback(this, function (result) {
                var state = result.getState();
                var toastEvent = $A.get("e.force:showToast");                
                var navService = component.find("navService");
                if (component.isValid() && state === "SUCCESS") {
                    
                }
            })
            $A.enqueueAction(action);
        }
        catch(e)
        {
            console.error('error - ' + e);
        }
    },
    GoBacktoGuestLogin : function (component, event, helper) {
        component.set('v.verifyEmail', false);
        component.set('v.ShowValidateEmail', true);
        component.set("v.GeneratedCode",'');
        component.set("v.enteredCode",'');
        component.set("v.disableVerify" ,true);
    },
    verifyEmail : function (component, event, helper) {
        try
        {
        let GeneratedCode = component.get("v.GeneratedCode");
        let enteredCode = Number.parseInt(component.get("v.enteredCode"));
        console.log('email verify ' + (GeneratedCode == enteredCode));
        
        /*var action = component.get("c.verifyCode");
        action.setParams({
            "enteredCode" : enteredCode
        });
        action.setCallback(this, function (result) {
            var state = result.getState();
            if (component.isValid() && state === "SUCCESS") {
               console.log('verify code - ' + result.getReturnValue()); 
                if(result.getReturnValue())
                {
                    component.set('v.showContactForm', true);
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
        })
        $A.enqueueAction(action);
        */
        if(GeneratedCode === enteredCode)
        {
            component.set('v.showContactForm', true);
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
    }
})