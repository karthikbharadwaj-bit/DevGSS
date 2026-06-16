({
    modalOpen: function (component, event, helper) {
        $A.get("e.c:QuotingToolLegalEngagedSpecialTOS").fire();
    },

    selectLegalEngagement: function(component, event, helper) {
        var selection = event.detail.menuItem;
        console.log('detail.menuItem >> ', selection);

        sToSOpen(component, event, helper);
    },

    modalClose: function(component, event, helper) {
        helper.modalClose(component);
    },

    openLegalMenu: function(component, event, helper) {
        var legalMenu = component.find('legalMenu');
        legalMenu.click();
    },

    quoteChange: function(component, event, helper) {
        helper.setValues(component);
        helper.checkDisplaying(component);
    },

    wizardChange: function(component, event, helper) {
        helper.setValues(component);
        helper.checkDisplaying(component);
    },

    primaryQuoteChange: function (component) {
        component.set('v.isChangeOrder', component.get('v.primaryQuote')['Upsell_Status__c'] !== 'New');
    },

    newLegalApproval: function(component, event, helper) {
        var legalApprovalId = event.getParam('legalApprovalId');
        component.set('v.legalApprovalId', legalApprovalId);
    },

    isBusyChange: function(component, event) {
        var isBusy = event.getParam("value");

        var enterpriseDealRequestButton = component.find('enterpriseDealRequestButton');
        var submitButton = component.find('submitButton');
        var recallButton = component.find('recallButton');
        if (isBusy) {
            $A.util.addClass(recallButton, "button--busy");
            $A.util.addClass(submitButton, "button--busy");
            $A.util.addClass(enterpriseDealRequestButton, "button--busy");
        } else {
            $A.util.removeClass(recallButton, "button--busy");
            $A.util.removeClass(submitButton, "button--busy");
            $A.util.removeClass(enterpriseDealRequestButton, "button--busy");
        }
    },

    showLegalEngagementManagementTooltip: function(component, event) {
        $A.get("e.c:PopoverEvent").setParams({
            target: event.target,
            showIcon: true,
            iconTheme: 'info',
            show: true,
            text: 'Go to Legal Engagement'
        }).fire();
    },

    hideTooltip: function() {
        $A.get("e.c:PopoverEvent").setParams({
            show: false
        }).fire();
    },

    redirectToLegalEngagement: function(component) {
        try {
            window.open('/' + component.get('v.legalApprovalId'), '_parent');
        } catch (err) {
            // ignore due to 'Same-origin policy'
        }
    }
});