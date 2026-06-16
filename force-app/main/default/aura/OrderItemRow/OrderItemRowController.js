({
    init: function (component, event, helper) {
        if (component.get('v.parentData.sobjectType') === RC.CONSTANTS.ASSET.SOBJECT_TYPE){
            helper.setDisplayAssetData(component);
        } else {
            helper.setDisplayEntitlementData(component);
        }
    }
});