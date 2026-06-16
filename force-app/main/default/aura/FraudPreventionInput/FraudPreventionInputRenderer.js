({
    unrender: function (component) {
        var name = component.get("v.fieldName");
        var value = null;
        var fieldType = component.get("v.inputType");

        if (fieldType == "checkbox") value = false;

        $A.get("e.c:FraudPreventionNullFieldEvent").setParams({
            name: name,
            value: value
        }).fire();
    }
});