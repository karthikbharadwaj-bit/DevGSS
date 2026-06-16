({
    confirmPrompt: function (component, event, helper) {
        helper.showPrompt(component, false);
        helper.getEntsFromController(component);
    },

    closePrompt: function (component, event, helper) {
        helper.showPrompt(component, false);
    },

    handleExport: function(component, event, helper) {
        helper.exportToExcel(component);
    },

    afterScriptsLoaded: function(component, event, helper){
        helper.getAccountFromController(component)
            .then($A.getCallback(function () {
                component.set('v.isLoadingAccount', false);
            }));

        helper.getAssetsFromController(component)
            .then($A.getCallback(function () {
                component.set('v.isLoadingAssets', false);
                helper.buildCategories(component);
            }));


            helper.getActiveSalesAgreement(component)
                .then($A.getCallback(function () {
                    component.set('v.getActiveSalesAgreement', false);
                }));

        helper.getNGBSSettings(component)
            .then($A.getCallback(function () {
                return helper.getEntsFromController(component);
            }))
            .then($A.getCallback(function () {
                return helper.getGroupedBillingInfoFromController(component);
            }))
            .catch($A.getCallback(function (error) {
                console.error(RC.salesforce.getResponseError(error));
                helper.showToast('error', '', RC.salesforce.getResponseError(error));
            }))
            .then($A.getCallback(function () {
                component.set('v.isLoadingEntitlements', false);
                helper.buildCategories(component);
                helper.fixedHeader(component);
            }))
    },

    doneRendering: function(component, event, helper){
        helper.fixedHeader(component);
    }
});