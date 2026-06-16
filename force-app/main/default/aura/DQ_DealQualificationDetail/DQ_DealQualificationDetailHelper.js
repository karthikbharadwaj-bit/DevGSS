({
	addTrueUpDateRecord : function(component, event, helper) {
        //alert('start');
         var addTrueUpAction = component.get("c.addTrueDateRec");
        addTrueUpAction.setParams({
            DQTrueUpDate: component.get("v.DQTrueUpDateList")
        });

        addTrueUpAction.setCallback(this, function (response) {
            if (response.getState() == "SUCCESS") {
                component.set("v.DQTrueUpDateList", response.getReturnValue());
                //alert('Save Successfully');
            }
        });
        $A.enqueueAction(addTrueUpAction);
        //alert('end');
   },

   validateField: function(component) {
        const fieldsToValidate = ['maximumPotential', 'minimumBaseline', 'startDate', 'initialTerm', 'chargeTerm', 'addInfo'];
        let isValid = true;
        fieldsToValidate.forEach(function (field) {
            const comp = component.find(field);
            if (comp && comp !== null) {
                if (!comp.checkValidity()) {
                    comp.reportValidity();
                    isValid = false;
                    return;
                }
            }
        });
        return isValid;
   },

   handleValueChangeAction: function (component) {
        const record = component.get("v.objDealQualificationWrap");

        let minPotentialLimit = 0;
        if (record && record.DQRec) {
            if ((record.DQRec.ELA_Initial_Terms__c && record.DQRec.ELA_Initial_Terms__c === '36') && 
            (record.DQRec.Charge_Term__c && record.DQRec.Charge_Term__c === 'Annual') ) {
                minPotentialLimit = 1000;
            }
        }
        component.set("v.minPotentailLimit", minPotentialLimit);

        Promise.resolve().then(() => {
            const cmp = component.find('maximumPotential');
            if (cmp) {
                cmp.reportValidity();
            }
        });
   }
})