({
    doInit: function (component, event, helper) {
        let wizardType = component.get('v.wizardType');
        wizardType = wizardType.toLowerCase();
        let wizardName = wizardType;

        if (!wizardType) {
            helper.showError(helper.ERROR_MESSAGES.empty_wizard_type);
            return;
        }
 
        var requiredFields = JSON.parse(component.get('v.requiredFields'));
        helper.showSpinner(true);

        if(requiredFields){
            component.set('v.requiredFields', requiredFields);
            if(requiredFields.includes('Key_Deal_Integration__c')){
                component.set('v.showKeyDealFields', true);
                requiredFields.splice(requiredFields.indexOf('Key_Deal_Integration__c'), 1);
                component.set('v.requiredFields', requiredFields)
            }
            if(component.get('v.validationType') == 'GSP_VALIDATION'){
                component.set('v.isFieldsMandatory', false);
            }
        }
        else{
            component.set('v.showAccountLockWarning', true);
        }              
        
        if (helper.nameMapping[wizardType]) {
            wizardName = helper.nameMapping[wizardType]
        }

        component.set('v.wizardType', wizardType);
        component.set('v.wizardName', wizardName);

        if(!component.get('v.oppId')){
            component.set('v.oppId', JSON.parse(component.get('v.oppInfo')).opportunityId);
        }

        helper.loadOppCloseInfo(component);
        
    },

    submitWithoutFields: function (component, event, helper) {
        helper.modalActionOk(component);
    },

    handleKeyDealIntegrationField: function (component, event, helper) {
        
        var keyDealIntegratinValue = event.getParam("value");
        if(keyDealIntegratinValue.includes('Not Listed')){
            component.set('v.showKeyDealOther', true);
        }
        else{
            component.set('v.showKeyDealOther', false);
        }
    },

    submit: function (component, event, helper) {
        event.preventDefault();
        component.set('v.fieldValues', event.getParam('fields'));

        const oppInfo = component.get('v.oppInfo');

        if (oppInfo) {
            helper.processOppInfo(component);
        } else {
            helper.modalActionOk(component);
        }
    },

    cancel: function (component,event, helper) {
        event.preventDefault();
        helper.redirectToOpportunity(component);
    }

});