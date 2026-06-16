({
    saveQuote: function () {
        $A.get("e.c:QuotingToolSaveClickEvent").fire();
    },

    discardQuote: function () {
        $A.get("e.c:QuotingToolDiscardQuoteEvent").fire();
    },

    saveCart: function () {
        $A.get("e.c:QuotingToolCartSaveEvent").fire();
    },

    discardCart: function () {
        $A.get("e.c:QuotingToolDiscardCardEvent").fire();
    },

    tierUpgrade: function (component) {
        component.set("v.selectedPriceBookEntry", null);
        $A.get("e.c:QuotingToolTierUpgradeEvent").setParams({upgrade: true}).fire();
    },

    cancelUpgrade: function (component) {
        component.set("v.selectedPriceBookEntry", null);
        $A.get("e.c:QuotingToolTierUpgradeEvent").setParams({upgrade: false}).fire();
    },

    getTaxes: function (component, event, helper) {
        if (component.get("v.isCartChanged")) {
            $A.get("e.c:QuotingToolModalRequestEvent").setParams({
                action: "SaveCartChanges",
                sourceId: "getTaxesButton"
            }).fire();
        } else {
            helper.getTaxes(component);
        }
    },

    quoteChanged: function (component, event, helper) {
        helper.checkButtons(component);
    },

    removeTaxes: function (component, event, helper) {
        if (component.get("v.isCartChanged")) {
            $A.get("e.c:QuotingToolModalRequestEvent").setParams({
                action: "SaveCartChanges",
                sourceId: "removeTaxesButton"
            }).fire();
        } else {
            helper.removeTaxes(component);
        }
    },

    stateChanged: function (component, event, helper) {
        helper.checkButtons(component);
        helper.buttonsVisibility(component);
    },

    selectedPriceBookEntryChanged: function (component, event, helper) {
        helper.checkButtons(component);
    },

    upsellStatusChanged: function (component, event, helper) {
        helper.checkButtons(component);
    },

    saveServicePlan: function () {
        $A.get("e.c:QuotingToolButtonEvent")
            .setParams({name: 'saveServicePlanButton'})
            .fire();
    },

    discardServicePlan: function () {
        $A.get("e.c:QuotingToolButtonEvent")
            .setParams({name: 'discardServicePlanButton'})
            .fire();
    },

    onButtonClick: function (component, event) {
        var buttonId = event.getSource().getLocalId();
        $A.get("e.c:QuotingToolButtonEvent")
            .setParams({name: buttonId})
            .fire();
    },

    isPhasesChangedChanged: function (component, event, helper) {
        helper.checkButtons(component);
    },

    isCartChangedChanged: function (component, event, helper) {
        helper.checkButtons(component);
    },

    tabsChanged: function (component, event, helper) {
        helper.buttonsVisibility(component);
    }
});