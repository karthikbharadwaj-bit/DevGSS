({
    init: function (component, event, helper) {
        if (component.get('v.data.sobjectType') === RC.CONSTANTS.ASSET.SOBJECT_TYPE){
            helper.setDisplayAssetData(component);
        } else {
            helper.setDisplayEntitlementData(component);
        }
    },

    showOrders: function (component) {
        var isShowOrders = component.get('v.isShowOrders');
        isShowOrders = !isShowOrders;
        component.set('v.isShowOrders', isShowOrders);
    },

    preventShow: function (component, event) {
        event.stopPropagation();
    }
});