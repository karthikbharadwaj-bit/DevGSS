({	
    modalOpen: function(component, event, helper) {
        helper.modalOpen(component);
    },
    modalClose: function(component, event, helper) {
        helper.modalClose(component);
    },
    submit: function(component, event, helper) {
        if (helper.validate(component, event, helper)) {
            helper.submitForApproval(component);
        }
    },
    quoteChange: function(component, event, helper) {
        helper.setValues(component);
        helper.checkButtonsDisabling(component);
    },
    askByCustomerChange: function(component) {
        var askByCustomer = component.get('v.askByCustomer');
        var askByCustomerContainer = component.find('askByCustomerContainer');
        var askByCustomerEl = component.find('askByCustomer');
        if (askByCustomer) {
            askByCustomerEl.set('v.errors', null);
            $A.util.removeClass(askByCustomerContainer, "slds-has-error");
        }
    },
    legalEngagementTypeChange: function(component) {
        var legalEngagementType = component.get('v.legalEngagementType');
        var legalEngagementTypeContainer = component.find('legalEngagementTypeContainer');
        var legalEngagementTypeEl = component.find('legalEngagementType');
        if (legalEngagementType) {
            legalEngagementTypeEl.set('v.errors', null);
            $A.util.removeClass(legalEngagementTypeContainer, "slds-has-error");
        }
    },
    legalAccountNameChange: function(component){
        var legalAccountName = component.get('v.legalAccountName');
        var legalAccountNameContainer = component.find('legalAccountNameContainer');
        var legalAccountNameEl = component.find('legalAccountName');
        if (legalAccountName) {
            legalAccountNameEl.set('v.errors', null);
           $A.util.removeClass(legalAccountNameContainer, "slds-has-error");
        }
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
    discard: function(component, event, helper) {
    	console.log('discard');
        helper.discardValues(component);
    },
    recall: function(component, event, helper) {
        helper.recall(component);
    },
    initQuote: function(component, event, helper) {
        component.set('v.effectiveNoOfEmployeesRange', event.getParam('effectiveNoOfEmployeesRange'));
        component.set('v.stageName', event.getParam('stageName'));
        helper.checkButtonsDisabling(component);
    },
    propagateUser: function(component, event, helper){
        var user = event.getParam('user');
        component.set('v.user',user);

        helper.checkButtonsDisabling(component);
        helper.checkUserAccess(component);
    },
})