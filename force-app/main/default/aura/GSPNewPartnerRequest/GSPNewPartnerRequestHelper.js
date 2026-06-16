({
    insertContact : function(component,event,helper) {
        try
        {
            
            //component.set("v.spinner", true);
            let PartnerReltoDomain = component.get("v.PartnerReltoDomain");
            var contact = component.get("v.newcontact");   
            contact.Email = component.get("v.guestEmail");
            contact.AccountId = PartnerReltoDomain.Id;
            console.log('contact - ' + JSON.stringify(contact));
            // Initializing the toast event to show toast
            //var toastEvent = $A.get('e.force:showToast');
            var createAction = component.get('c.createContactRecord');
            createAction.setParams({
                newContact: contact,
                dealSupportType:'New Partner User Request'
            });
            createAction.setCallback(this, function(response) {           
                // Getting the state from response
                var state = response.getState();
                //component.set("v.spinner", false);            
                if(state === 'SUCCESS') {
                    
                    // Getting the response from server
                    var dataMap = response.getReturnValue();
                    if(dataMap.status== undefined || dataMap.status == '' || dataMap.status== null){
                        //component.set('v.ShowSpinnerOpp',false);
                    }
                    // Checking if the status is success
                    if(dataMap.status=='success') {  
                        component.set('v.showSuccessMsg',false);
                        component.set('v.showContactFields',false);
                        component.set('v.showEmailField',true);
                        var toastEvent = $A.get("e.force:showToast");
                        toastEvent.setParams({
                            'title': 'Contact created successfully',
                            'type': 'success',
                            'mode': 'dismissable',
                            'message': dataMap.message
                        });                    
                        toastEvent.fire();
                        
                    }
                }
            });
            $A.enqueueAction(createAction);
        }catch(e)
        {
            console.log('error - ' + e);
        }
    },
    
    requestForPartnerUserAccess: function(component,event,helper) {
        try{
            var RequestPartnerEmail = component.get('v.guestEmail');
            console.log("inside validate email "+RequestPartnerEmail);
            console.log('inside requets method');
            component.set('v.ShowSpinnerOpp',true);
            var action = component.get("c.requestForUserAccessPortal");
            action.setParams({
                "partnerUserRequestEmail": RequestPartnerEmail
            });
            action.setCallback(this, function (result) {
                var state = result.getState();
                console.log('state>>'+state);
                if (component.isValid() && state === "SUCCESS") {
                    var resultData = result.getReturnValue();
                    console.log('resultData'+resultData);
                    component.set("v.showConfirmRequestModal",false);
                    if(resultData=='SUCCESS'){
                        component.set('v.showSuccessMsg',true);
                        component.set('v.showEmailField',false);
                        console.log('showSuccessMsg>'+ component.get('v.showSuccessMsg'));
                        
                    }else if(resultData=='User Activation Request Sent Already!!'){
                        var toastEvent = $A.get("e.force:showToast");
                        toastEvent.setParams({
                            'title': 'Info',
                            'type': 'info',
                            "mode":'dismissible',
                            'message': resultData
                        });                    
                        toastEvent.fire();
                        component.set('v.showEmailField',true);
                    }
                }
            });
            $A.enqueueAction(action);
        }catch(e)
        {
            console.log('error - ' + e);
        }
    }
})