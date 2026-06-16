({
    chooseTier: function (component, event, helper) {
        var servicePlanEntry = component.get("v.servicePlanEntry");
        var activePriceBookEntry = component.get('v.activePriceBookEntry');
        var newSelectedPriceBookEntry = null;
        if (!activePriceBookEntry || (activePriceBookEntry && activePriceBookEntry.Id !== servicePlanEntry.Id)) {
            newSelectedPriceBookEntry = servicePlanEntry;
        }
        component.set('v.selectedPriceBookEntry', newSelectedPriceBookEntry);
    },

    showTierId: function (component, event, helper) {
        helper.show(event.currentTarget, 'info', component.get('v.servicePlanEntry.Pricebook2.Tier_ID__c'));
    },

    hideTierId: function (component, event, helper) {
        helper.hide(component, event, helper);
    },

    doInit: function(component, event, helper) {
        console.log('doInit', component.get('v.servicePlanEntry.Pricebook2.Name'));
    },
})