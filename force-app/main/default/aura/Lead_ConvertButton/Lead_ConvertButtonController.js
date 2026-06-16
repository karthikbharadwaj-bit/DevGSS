({
	setup:function(component, event, helper) {
        
        console.log('getLeadrecord'+ component);
		var action= component.get("c.getLeadrecord");
        
        var recId = component.get("v.recordId");
             
        action.setParams({
              "LeadId":recId
        });
        action.setCallback(this, function(response){
           var state = response.getState(); 
            console.log(state);
            if(state=='SUCCESS'){
               // var reqz = response.getReturnValue(); 
                var LeadObj = response.getReturnValue();
                console.log('test' + JSON.stringify(LeadObj));
                var LeadId=LeadObj[0];
                console.log(JSON.stringify(LeadId));
                var LeadOwnerId=LeadObj[1];
                console.log(JSON.stringify(LeadOwnerId));
                var rcnotify= this._rcnotify;
                var cs = LeadObj[3];
                console.log(JSON.stringify(cs));
                var s = LeadObj[2];
                console.log(JSON.stringify(s));
                helper.convert(component,event,helper,cs,s,LeadId,LeadOwnerId,rcnotify);
			}
           
            else{
                var toastEvent = $A.get("e.force:showToast");
                	toastEvent.setParams({
                    "type": "error",
                    "title": "Error!",
                    "message": "There is some error while processing",
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