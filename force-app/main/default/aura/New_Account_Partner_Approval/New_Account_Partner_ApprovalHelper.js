({
    showToast : function(type, message) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "type": type,
            "message": message,
            "duration": 10000
        });
        toastEvent.fire();
    },

    showSpinner: function(component) {
        component.set("v.spinner", true);
    },

    hideSpinner : function(component) {
        component.set("v.spinner", false);

    },

    openInNewTab : function(component, approvalId) {
        var navService = component.find("navService");

        var pageReference = {    
            "type": "standard__recordPage",
            "attributes": {
                "recordId": approvalId,
                "actionName": "view"
            }
        };

        navService.generateUrl(pageReference)
            .then($A.getCallback(function(url) {
                window.open(url,'_blank');
            }), 
            $A.getCallback(function(error) {
                console.log('error: ' + error);
            })
        );
    },

    closeVFWindow : function (component, helper, message, type) {
        var vfMethod = component.get("v.vfCloseWindow");
        vfMethod(message, type, function(){});
    },

    showToastVF : function (component, helper, message, type) {
        var vfMethod = component.get("v.vfShowToast");
        vfMethod(message, type, function(){});
    }
})