({
    getDealSupportComments : function(component, event, helper) {
        var action = component.get("c.getSupportComments");        
        action.setParams({
            "dealSupportId": component.get("v.DealSupportRecordId")            
        });
        action.setCallback(this, function(result) {            
            var state = result.getState();
            if (component.isValid() && state === "SUCCESS"){
                var resultData = result.getReturnValue();
                var data = resultData.partnerDealSupportCommentsList;
                component.set("v.dealSupportCommentsList", resultData.partnerDealSupportCommentsList);
                
                // if storeResponse size is 0 ,display no record found message on screen.
                if (data == '' || data == undefined ||data == null) {
                    component.set("v.displayErrorMessage", true);
                    component.set('v.errorMessage','No Records found...');
                }
                else{
                    component.set("v.displayErrorMessage", false);
                } 
            }else{
                component.set('v.ShowSpinnerCom',false);//Added for ALE safari issue
            }
        });        
        $A.enqueueAction(action);        
    },
    
    //Translation Start
    getTranslations : function (component, event, helper) 
    {
        try
        {
            var action = component.get("c.getTranslations");
            action.setParams({
                "objNames": 'Deal_Support__c'
            });
            action.setCallback(this, function (result) {
                var state = result.getState();
                if (component.isValid() && state === "SUCCESS") {
                    console.log('AllObjFields - ' + JSON.stringify(result.getReturnValue()));
                    var resultData = result.getReturnValue();
                    if(resultData != undefined && resultData != null && resultData != '')
                    {
                        if(resultData.allObjFieldsMap != undefined && resultData.allObjFieldsMap != null && 
                           resultData.allObjFieldsMap != '')
                        {
                            component.set("v.dealSupportFieldsMap", resultData.allObjFieldsMap.Deal_Support__c);
                        }
                        component.set("v.translationsMap", resultData.prmLabelsMap);
                        component.set("v.PRMSpecificTranslationsMap", resultData.prmSpecificLabelsMap);
                    }
                }
            });
            $A.enqueueAction(action);
        }
        catch(e)
        {
            console.log('err - ' + e);
        } 
    },
     //Translation End
    
    insertNewComment: function(component, event, helper) {
        
        var action=component.get("c.getNewDealComments");
        
        action.setParams({
            "dealSupportId": component.get("v.DealSupportRecordId") ,
            "comments": component.get("v.comment")
        });
        action.setCallback(this, function(result){
            var state = result.getState();
            
            if (state === "SUCCESS"){
                var resultData = result.getReturnValue();
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "type": "success",
                    "title": "Success!",
                    "message": "New Comment has been added successfully.",
                    "mode":'dismissible'
                });
                toastEvent.fire();
                component.set('v.isActive', false);
                //component.destroy();
            }else{
                component.set('v.ShowSpinnerCom',false);//Added for ALE safari issue
            }
        });
        component.set('v.ShowRecordDetail', true);
        component.set('v.ShowNewComment', false);
        
        $A.enqueueAction(action); 
        helper.getDealSupportComments(component, event, helper);
    }
})