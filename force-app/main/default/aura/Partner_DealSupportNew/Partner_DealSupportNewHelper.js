({
	insertDealSupport : function(component, event, helper) {
        var dealsuppid=component.get("v.dsname");
        var dealsuppcomment=component.get("v.comment");
		var action = component.get("c.insertDealSupportNew");        
        action.setParams({
            "dealname":dealsuppid,
            "comments":dealsuppcomment
        });
        action.setCallback(this, function(result) {            
            var state = result.getState();
            if (state === "SUCCESS"){
                var resultData = result.getReturnValue(); 
                component.set("v.newDealRecordID",resultData.Id);
                var id_str=component.get("v.newDealRecordID");
                var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "type": "success",
                        "title": "Success!",
                        "message": "The record has been Submitted successfully.",
                        "mode":'dismissible'
                    });
                toastEvent.fire();
                //component.set("v.ShowRecordDetail", true);
                component.set("v.ShowListView", false);
                  component.set("v.ShowNewRecord", false);
                component.set("v.SavedRecord",true); 
                var urlEvent = $A.get("e.force:navigateToURL");
                urlEvent.setParams({
                   //'url': '/partner/s/dealsupport?id='+id_str
                   'url':window.location.pathname +'?id=' +id_str
                });
                urlEvent.fire();
            }
        });        
        $A.enqueueAction(action);   
	}
})