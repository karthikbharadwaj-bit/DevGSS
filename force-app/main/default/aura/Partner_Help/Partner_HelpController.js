({
	doInit : function(component, event, helper) {
        var url = new URL(location.href);            
        var baseURL = url.href.substring(0, url.href.indexOf("/s"));   
         if(baseURL.includes('RCPartnerProgram')){
             component.set('v.title',"Send Email to Partner Support");
         }
         else{
              component.set('v.title',"Send Email");
         }
     },
    
    sendEmail : function(component, event, helper) {
		var subject = component.get('v.Subject');
        var body = component.get('v.EmailBody');
        if(subject == null || subject == undefined || body == null || body == undefined)
        {
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                "type": "error",
                "title": "Error!",
                "message": "Please enter the Subject and Email Body to send email",
                "mode":'dismissible'
            });
            toastEvent.fire();
        }
        else
        {                        
           // body = body.replace("/partner/servlet","https://e2euat-rc-portal.cs4.force.com/partner/servlet");            
            //console.log('body-->'+body);
            var action = component.get("c.sendEmailController");  
            action.setParams({
                'emailSubject': subject,
                'emailBody': body
            });
            action.setCallback(this, function(result) {  
                if(result.getState() == 'SUCCESS')
                {
                    component.set('v.EmailSent',true);
                }
                else
                {
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "type": "error",
                        "title": "Error!",
                        "message": "There was some error during sending email",
                        "mode":'dismissible'
                    });
                    toastEvent.fire();
                }
            });        
        	$A.enqueueAction(action);
        }
	},
    //METHODS TO DISPLAY SPINNER
    showSpinner: function(component, event, helper) {        
        var spinner = component.find("loadingSpinner");
        $A.util.removeClass(spinner, "slds-hide");
    },
    //METHODS TO HIDE SPINNER
    hideSpinner : function(component,event,helper){           
        var spinner = component.find("loadingSpinner");
        $A.util.addClass(spinner, "slds-hide");
    },
})