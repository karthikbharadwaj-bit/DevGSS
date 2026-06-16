({
	helperMethod : function() {
		
	},
    
    showToast: function (title, message, type) {
        var toastEvent = $A.get("e.force:showToast");
        if (toastEvent) {
            toastEvent.setParams({
                title: title,
                message: message,
                duration: ' 5000',
                key: 'info_alt',
                type: type,
                mode: 'dismissible'
            });
            toastEvent.fire();
        }
        else {
            alert(message);
        }
    },
	  //Translation Start
      getTranslations: function (component, event, helper) {
        try {
            function setTranslations(result) {
                var state = result.getState();
                if (component.isValid() && state === "SUCCESS") {
                    console.log('AllObjFields - ' + JSON.stringify(result.getReturnValue()));
                    var resultData = result.getReturnValue();
                    if (resultData != undefined && resultData != null && resultData != '') {
                        if (resultData.allObjFieldsMap != undefined && resultData.allObjFieldsMap != null &&
                            resultData.allObjFieldsMap != '') {
                            component.set("v.DealRegFieldsMap", resultData.allObjFieldsMap.Deal_Registration__c);
                        }
                        component.set("v.translationsMap", resultData.prmLabelsMap);
                        component.set("v.PRMSpecificTranslationsMap", resultData.prmSpecificLabelsMap);
                    }
                }
            };
            var getTranslations = component.get("c.getTranslations");
            getTranslations.setParams({
                "objNames": 'Deal_Registration__c'
            });
            getTranslations.setCallback(this, setTranslations);
            $A.enqueueAction(getTranslations);
        }
        catch (e) {
            console.log('err - ' + e);
        }
    }
    //Translation End
    
    
})