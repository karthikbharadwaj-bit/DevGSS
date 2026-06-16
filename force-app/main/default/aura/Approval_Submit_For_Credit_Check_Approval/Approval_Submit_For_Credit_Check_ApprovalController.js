({
    doInit : function(component, event, helper) {
        var action=component.get("c.validatesubmitforcreditcheck");
        var recId = component.get("v.recordId");
        action.setParams({
            "recordId":recId
        });
        action.setCallback(this, function(response){
            $A.get("e.force:closeQuickAction").fire();
            var state = response.getState();  
            if(state=='SUCCESS'){
                var retResponse = response.getReturnValue();
                if(!retResponse.errormessageList || retResponse.errormessageList.length == 0)
                {
                    
                    var device = $A.get("$Browser.formFactor");
                    var dnbrecordid = retResponse.dnbrecordid;
                    if(dnbrecordid != "ERROR"){
                        if(device == 'DESKTOP')
                        {   
                            var windowWidth = document.documentElement.clientWidth;
                            
                            var windowHeight = document.documentElement.clientHeight;
                            
                            var width=windowWidth*.5-400;
                            
                            var height=windowHeight*.5-250;
                            var win = window.open("/apex/DNBI__companyMatchPage?id=" + dnbrecordid +"&isCustomObj=true", "_new","width=800,height=500,top=" + height + ",left=" + width +"scrollbars=yes");
                            
                        }
                        else
                        {
                            var urlEvent = $A.get("e.force:navigateToURL");
                            urlEvent.setParams({
                                'url': '/apex/DNBI__companyMatchPage?id='+dnbrecordid+"&isCustomObj=true"
                            });
                            urlEvent.fire();
                        }
                    }else{
                        var toastEvent = $A.get("e.force:showToast");
                        toastEvent.setParams({
                            "type": "error",
                            "title": "Credit Approval Error",
                            "message": "Some error occured while processing",
                            "mode":'dismissible'
                        });
                        toastEvent.fire(); 
                        
                    }
                    
                }
                else
                {
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "type": "error",
                        "title": "Credit Approval Error",
                        "message": retResponse.errormessageList[0],
                        "mode":'dismissible'
                    });
                    toastEvent.fire();
                }
            }
            else if (state === "ERROR"){
                var errors = response.getError();
                var toastEvent = $A.get("e.force:showToast");
                var errormessage;
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        
                        errormessage =  errors[0].message;
                    }
                } else {
                    errormessage = "Unknown error";
                }
                toastEvent.setParams({
                    "type": "error",
                    "title": "Credit Approval Error",
                    "message": errormessage,
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