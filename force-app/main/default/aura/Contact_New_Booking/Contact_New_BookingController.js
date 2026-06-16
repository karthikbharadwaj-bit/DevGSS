({
    doInit : function(component, event, helper) {
        var action=component.get("c.getContact");
        var recId = component.get("v.recordId");
        action.setParams({
            "recordId":recId
        });
        action.setCallback(this, function(response){
            $A.get("e.force:closeQuickAction").fire();
            var state = response.getState();
            
            if(state == "SUCCESS"){
                var caseRec = response.getReturnValue();
                
                var phoneNo = caseRec.Phone;
                console.log('phoneNo'+phoneNo);
                //var regxPhn =   phoneNo.replace(/[^a-zA-Z0-9]/g, '');
                
                /*console.log('BB_Service_ID__C' +caseRec.BB_Service_ID__c);
                    if(caseRec.BB_Service_ID__c ==''|| caseRec.BB_Service_ID__c == undefined)
                    {
                        
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "type": "error",
                        "title": "Error!",
                        "message": 'The request cannot be processed until a service id has been added to the contact.',
                        "mode":'dismissible'
                    });
                    toastEvent.fire();  
                    }
                    else{*/
                    var serviceId;
                    if(caseRec.BB_Service_ID__c ==''|| caseRec.BB_Service_ID__c == undefined){
                        serviceId = '';
                    }else{
                        serviceId = caseRec.BB_Service_ID__c;
                    }
                    var device = $A.get("$Browser.formFactor");
                    
                    if(device == 'DESKTOP')
                    {
                        var win = window.open("http://bespoke.bookingbug.com/ringcentral/new_booking.html?service_id="+serviceId+"&first_name="+caseRec.FirstName+"&last_name="+caseRec.LastName+"&email="+caseRec.Email+"&phone="+phoneNo+"&ref="+caseRec.Id+"&userid="+caseRec.User_Id__c+"#/calendar","New Booking","height=900,width=900");
                        
                        
                        
                    }
                    else{
                        
                        var urlEvent = $A.get("e.force:navigateToURL");
                        urlEvent.setParams({
                            'url': 'http://bespoke.bookingbug.com/ringcentral/new_booking.html?service_id='+serviceId+'&first_name='+caseRec.FirstName+'&last_name='+caseRec.LastName+'&email='+caseRec.Email+'&phone='+phoneNo+'&ref='+caseRec.Id+'&userid='+caseRec.User_Id__c+'#/calendar'
                        });
                        urlEvent.fire();
                        
                    }
                    
                    // }
                }
                    
                    else {
                        var toastEvent = $A.get("e.force:showToast");
                        toastEvent.setParams({
                            "type": "error",
                            "title": "Error!",
                            "message": 'There is a error while Processing',
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