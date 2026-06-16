({
    insertContact: function(component, event, helper) { 
        try
        {
        component.set("v.spinner", true);
        let PartnerReltoDomain = component.get("v.PartnerReltoDomain");
        var contact = component.get("v.contact"); 
        contact.AccountId = PartnerReltoDomain.Id;   
        contact.Email = component.get("v.GuestEmail");
        console.log('contact - ' + JSON.stringify(contact));
        // Initializing the toast event to show toast
        var toastEvent = $A.get('e.force:showToast');
        var createAction = component.get('c.createContactRecord');
        createAction.setParams({
            newContact: contact,
            dealSupportType:'New Contact Request'
        });
        createAction.setCallback(this, function(response) {
            try
            {
            // Getting the state from response
            var state = response.getState();
            component.set("v.spinner", false);            
            if(state === 'SUCCESS') {
                
                // Getting the response from server
                var dataMap = response.getReturnValue();
                 if(dataMap.status== undefined || dataMap.status == '' || dataMap.status== null){
                component.set('v.ShowSpinnerOpp',false);
                 }
                // Checking if the status is success
                if(dataMap.status=='success') {                    
                    toastEvent.setParams({
                        'title': 'Success!',
                        'type': 'success',
                        'mode': 'dismissable',
                        'message': dataMap.message
                    });                    
                    toastEvent.fire(); 
                    let partnerContact = component.get("v.partnerContact");
                    partnerContact['Id'] = dataMap.contactId;
                    component.set("v.partnerContact", partnerContact);
                    //component.set("v.partnerContact.Id",dataMap.contactId);
                    component.set("v.showContactForm", false);
                    component.set("v.showNewDealReg", true);
                    component.set("v.spinner", false);
                    component.set("v.isNewContact", false);
                    component.set('v.showContactListView',true);
                    this.ContactList(component,component.get("v.AccountId"));
                } else if(dataMap.status=='error') {
                    let message = '';
                    if(dataMap.message.includes('Contact with provided Email already exist on Account'))
                    {
                        message = 'Contact with provided Email already exist on Account';
                    }
                    else
                    {
                        message = dataMap.message;
                    }
                    toastEvent.setParams({
                        'title': 'Error!',
                        'type': 'error',
                        'mode': 'dismissable',
                        'message': message
                    });                    
                    toastEvent.fire();                
                }
            } else {
                alert('Error in getting data');
                component.set("v.spinner", false);
                component.set('v.ShowSpinnerOpp',false);
            }
            }
            catch(e)
            {
                console.log('error - ' + e);
            }
        });      
        $A.enqueueAction(createAction);
        }
        catch(e)
        {
            console.log('error - ' + e);
        }
    }
})