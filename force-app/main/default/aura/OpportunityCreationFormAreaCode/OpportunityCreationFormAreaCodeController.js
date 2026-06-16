({
    removeAreaCode: function (component) {
        component.getEvent("removeAreaCode").setParams({
            params: {
                index: component.get('v.index')
            }
        }).fire();
    },

    userChangedAreaCode: function (component) {
        var areaCode = component.get('v.areaCode');
        areaCode.clearAreaCodeErrors();
        component.set('v.areaCode', areaCode);
    },

    onQuantityInputBlur: function (component) {
        var areaCode = component.get('v.areaCode');

        areaCode.normaliseQuantity();
        areaCode.saveQuantity();
        component.getEvent("areaCodeQuantityChange").fire();

        component.set('v.areaCode', areaCode);
    },

    onQuantityInputChange: function (component) {
        var areaCode = component.get('v.areaCode');
        var app = component.get('v.app');
        areaCode.saveQuantity();
        component.getEvent("areaCodeQuantityChange").fire();

        component.set('v.areaCode', areaCode);
        component.set('v.app', app);
    },
});