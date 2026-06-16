({
    init: function (component, event, helper) {
        helper.setValue(component);
        // helper.validate(component);
    },
    changeField: function (component, event, helper) {
        var fieldName = component.get('v.fieldName');
        var value = component.get('v.value').toString();

        var formObject = component.get('v.formObject');
            formObject[helper.getKey(formObject, fieldName)] = value;
        component.set('v.formObject', formObject);
        helper.validate(component);

        $A.get('e.c:FraudPreventionEvent').setParams({
            action: 'changeValue',
            data: {
                fieldName: fieldName,
            },
        }).fire();
    },
    changeFormObject: function(component, event, helper) {
        helper.setValue(component);
        // helper.validate(component);
    },
    changeErrors: function(component, event, helper) {

        var fieldName = component.get('v.fieldName');
        var settings = component.get('v.settings');

        if(component.get('v.errorMessage') !== settings.errors[fieldName]) {
            helper.setError(component, settings.errors[fieldName]);
        }
    },
});