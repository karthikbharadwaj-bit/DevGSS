({       
    doDelete : function(component, event, acr, type){
        var action = component.get('c.deleteAttachment');
        action.setParams({
            'attachId' : acr,
            'type' : type
        })
        action.setCallback(this,function(response) {
            var state = response.getState();  
            if(state === 'SUCCESS'){
                if(response.getReturnValue() == 'success')
                {
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "type": "success",
                        "title": "Success!",
                        "message": "Record has been deleted successfully.",
                        "mode":'dismissible'
                    });
                    toastEvent.fire();  
                     window.location.reload();
               }
                else
                {
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "type": "error",
                        "title": "Error",
                        "message": 'There is some error while processing',
                        "mode":'dismissible'
                    });
                    toastEvent.fire();
                }
            }
        });
        $A.enqueueAction(action);
    }
})