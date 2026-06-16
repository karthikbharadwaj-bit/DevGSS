({
    doInit : function(component, event, helper) {
        var state,errors,type,title,message = '';
        var isClicked = component.get("V.isClicked");        
        var eventString = String(event.getSource());
        var res = eventString.match(/flexipage/);
        console.log('event '+ res);
        console.log('bool '+isClicked);
        if(res == 'flexipage'){
            isClicked = "false";
            console.log('bool 1 '+isClicked);
        }
        console.log('bool 1 '+isClicked);
        var DS_id = component.get("v.recordId");
        var action = component.get("c.changeownerpartnerqueue");
        action.setParams({
            DS_id : DS_id,
            brandName : 'Avaya Cloud Office',
            isClicked : isClicked
        });
        
        action.setCallback(this, function(response) {
            console.log('inside callback');
            console.log('response '+response.getReturnValue());
            if(isClicked === true){
                console.log('inside isclick');
                console.log('bool 2 '+isClicked)
                state = response.getState();
                console.log('state'+state);
                //console.log('response '+response.getReturnValue());
                if(state == "SUCCESS") {
                    console.log('inside if');
                    var resultsToast = $A.get("e.force:showToast");
                    type = "success";
                    title = "Success!";
                    message = response.getReturnValue();    
                }
                else if (state == "ERROR") {
                    console.log('inside elif');
                    errors = response.getError();
                    if (errors) {
                        if (errors[0] && errors[0].message) {
                            console.log("Error message: " + 
                                        errors[0].message);
                            type = "error";
                            title = "Error";
                            message = errors[0].message;
                            $A.get("e.force:closeQuickAction").fire();
                            resultsToast.fire();
                            $A.get("e.force:refreshView").fire();  
                        }
                    } else {
                        console.log("Unknown error");
                    }
                }
                resultsToast.setParams({
                    "type":	type,
                    "title": title,
                    "message": message,
                    "mode":'dismissible'
                });
                $A.get("e.force:closeQuickAction").fire();
                resultsToast.fire();
                $A.get("e.force:refreshView").fire();           
                var dismissActionPanel = $A.get("e.force:closeQuickAction");
                dismissActionPanel.fire();
            }
            //}
            var dismissActionPanel = $A.get("e.force:closeQuickAction");
            dismissActionPanel.fire();
        });   
        $A.enqueueAction(action);
        $A.get('e.force:refreshView').fire();             
    }
})