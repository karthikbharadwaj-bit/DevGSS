({
    processdatafunc : function(component, event, helper, rcnotify)
    {
        var recId = component.get("v.recordId");
        var action1=component.get("c.processData");
        action1.setParams({
            "approvalId":recId
            
        });
        action1.setCallback(this, function(response){
            var state = response.getState();
            if(state == "SUCCESS"){
                console.log("INSIDE SUCCESS");
                var appobj = response.getReturnValue();
                var result = JSON.parse(appobj);
                if (result.length > 0) {
                    result.forEach(function(item) {
                        var toastEvent = $A.get("e.force:showToast");
                        toastEvent.setParams({
                            "type": "error",
                            "title": item.header,
                            "message": item.message,
                            "mode":'dismissible'
                        });
                        toastEvent.fire();
                        // rcnotify.addToast({ theme: 'error', header: item.header, details: item.message });
                    });
                }
                else{
                    //Navigating to vf page logic added
                    var vfpageurl;
                    var featureToggle = component.get("v.newPSRFlag");
                    console.log(featureToggle);
                    if(featureToggle){
                        
                        vfpageurl = "/apex/PostSaleRefunds?id=";
                    }else{
                        console.log("FFFFalse");
                         vfpageurl = "/apex/RefundManagement?id=";
                    }
                    
                    var device = $A.get("$Browser.formFactor");
                    
                    if(device == 'DESKTOP')
                    {
                        var win = window.open(vfpageurl+recId,"_blank");
                    }
                    else{
                        
                        var urlEvent = $A.get("e.force:navigateToURL");
                        urlEvent.setParams({
                            'url': vfpageurl+recId
                        });
                        urlEvent.fire();
                        
                    }                                
                }
                rcnotify.hideSpinner();
                $A.get("e.force:closeQuickAction").fire();
            }
            else{
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "type": "error",
                    "title": "Error!",
                    "message": "Refund Management is not available",
                    "mode":'dismissible'
                });
                toastEvent.fire();
                
            }
        });
        $A.enqueueAction(action1);
    },
    
      getCustomSettingValue : function(component, event, helper){
        
        var action2 = component.get('c.getFeatureToggleValue');
        
        action2.setCallback(this, function(response) {
            var state = response.getState();
            if (state == "SUCCESS") {
                var newpsrpageflag = response.getReturnValue();
                component.set("v.newPSRFlag", newpsrpageflag.New_PSR_Page__c );
                console.log("newpsrpageflag.New_PSR_Page__c " +newpsrpageflag.New_PSR_Page__c );
                
            } else{
                component.set("v.newPSRFlag" , "CUSTOMERROR");
                
            }
        });
        $A.enqueueAction(action2);
    }
    
   
})