/**
 * Created by Makhmud.Shafeev on 10/30/2020.
 */

({

    handleSubmit: function(component, event, helper) {
        var action = component.get("c.getCountryCode");
        action.setParams({
            'VATNumber': accVATNumber,
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if(state === 'SUCCESS'){
                component.set('v.isValid', true);
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "type": "success",
                    "title": "Success!",
                    "message": "VAT Number is Valid",
                    "mode":'dismissible'
                });
                toastEvent.fire();
            } else {
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "type": "error",
                    "title": "Error!",
                    "message": "VAT number is not valid",
                    "mode":'dismissible'
                });
                toastEvent.fire();
            }
        });

        $A.enqueueAction(action);
    }
});