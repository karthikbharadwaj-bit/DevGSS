({
    checkVisibility: function(component){
        var action=component.get("c.getStageValidationMessage");
        action.setParams({
            "oppId":component.get("v.recordId")
        });
        action.setCallback(this, function(response){
            if(response.getState()=='SUCCESS'){
                var result = JSON.parse(response.getReturnValue());
                component.set('v.message', result.message);
                component.set('v.nextStage', result.nextStage);
                console.log(result.message);
                if (result.message != '') {
                    component.set('v.showComponent', true);
                }
            }
        });
    $A.enqueueAction(action);
    }
})