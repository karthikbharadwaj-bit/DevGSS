({
    doInit : function(component, event, helper) {
        var currentUser = $A.get( "$SObjectType.CurrentUser.Id" );
        var action = component.get("c.saveTodoRecord");
        action.setCallback(this,function(response){
            var state = response.getState();
            alert('User Record has been activated');
            if(state == "SUCCESS"){
                if(response.getReturnValue()) {
                    var urlEvent = $A.get("e.force:navigateToURL");
                    urlEvent.setParams({
                        "url": "https://rc.my.salesforce.com/lightning/page/home"
                    });
                    urlEvent.fire();
                }
                
            }
            else{
                //To handle server error
                console.log('Error occured while init of data '+state);
            }
        });
        $A.enqueueAction(action);
    }
})