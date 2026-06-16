({
    doInit: function (component) {
        var action = component.get("c.validateLeadConvertAccess");
        var recId = component.get("v.recordId");

        action.setParams({
            "recordId": recId
        });

        action.setCallback(this, function (response) {
            var state = response.getState();

            if (state === "SUCCESS") {
                if (response.getReturnValue()) {
                    $A.enqueueAction(component.get('c.convert'));
                } else {
                    var toastEvent = $A.get("e.force:showToast");

                    toastEvent.setParams({
                        "type": "error",
                        "mode": "dismissible",
                        "title": "Error",
                        "message": $A.get("$Label.c.LeadConvertErrorNoPermission"),
                    });
                    toastEvent.fire();
                    $A.get("e.force:closeQuickAction").fire();
                }
            } else if (state === "ERROR") {
                console.error('Error (onInit)', response.getError());
                $A.get("e.force:closeQuickAction").fire();
            }
        });

        $A.enqueueAction(action);
    },

	convert: function (component) {
		var action = component.get("c.convertLead");
        var recId = component.get("v.recordId");

        action.setParams({
              "recordId": recId
        });

        action.setCallback(this, function (response) {
            var state = response.getState();
            var toastEvent = $A.get("e.force:showToast");
            var urlEvent = $A.get("e.force:navigateToURL");

            if(state === 'SUCCESS') {
                var retResponse = response.getReturnValue().response;

                if (retResponse === 'Success') {
                	if (response.getReturnValue().isUseNewConvertLeadPage) {
                         var urllink = new URL(location.href);
                         var dtpid = urllink.searchParams.get('isdtp');
                         var url='/apex/convertLead?id=' + recId;

                         if (dtpid != null) {
                             url +='&isdtp=' +dtpid;
                         }

                         urlEvent.setParams({
                            'url': url
                         });
                         urlEvent.fire();
                    } else {
                        var url = '/apex/convertLeadVFPage?id=' + recId + '&newmodel=1';

                        urlEvent.setParams({
                            'url': url
                        });
                        urlEvent.fire();
                    }
                } else {
                	toastEvent.setParams({
                        "type": "error",
                        "title": "Error!",
                        "message": retResponse,
                        "mode":'dismissible'
                	});
                	toastEvent.fire();
                }
            } else {
                toastEvent.setParams({
                    "type": "error",
                    "title": "Error!",
                    "message": "There is some error while processing",
                    "mode":'dismissible'
                });
                toastEvent.fire();
            }

            $A.get('e.force:refreshView').fire();
        });

        $A.enqueueAction(action);
	},

    showSpinner: function (component) {
        var spinner = component.find("loadingSpinner");
        $A.util.removeClass(spinner, "slds-hide");
    },

    hideSpinner : function (component) {
        var spinner = component.find("loadingSpinner");
        $A.util.addClass(spinner, "slds-hide");
    }
})