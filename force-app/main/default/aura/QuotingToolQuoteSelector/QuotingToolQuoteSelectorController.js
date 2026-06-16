({
    loadOptions: function(component, event) {
        var opportunityId = event.getParam("opportunityId");
        component.set('v.opportunityId', opportunityId);
        var effectiveNoOfEmployeesRange = event.getParam('effectiveNoOfEmployeesRange');
        component.set('v.effectiveNoOfEmployeesRange', effectiveNoOfEmployeesRange);
    },
    initSelector: function(component, event, helper) {
        helper.initSelector(component);
    },
    changeQuote: function(component, event, helper) {
        var quoteId = component.find("quoteSelector").get("v.value");
        if (component.get('v.cartIsChanged')) {
            $A.get("e.c:QuotingToolModalRequestEvent").setParams({
                action: "SaveCartChanges",
                sourceId: "changeQuote"
            }).fire();
            component.set("v.targetAction", 'changeQuote');
            component.set("v.targetQuoteId", quoteId);
        } else if (component.get('v.isSummaryChanged')) {
            $A.get("e.c:QuotingToolModalRequestEvent").setParams({
                action: "SaveQuoteChanges",
                sourceId: "newQuote"
            }).fire();
            component.set("v.targetAction", 'changeQuote');
            component.set("v.targetQuoteId", quoteId);
        } else {
            helper.changeQuote(component, quoteId);
            component.set("v.targetAction", null);
            component.set("v.targetQuoteId", null);
        }
    },
    makePrimary: function(component, event, helper) {
        var quoteId = component.find("quoteSelector").get("v.value");
        helper.setQuotePrimary(component, quoteId);
    },
    newQuote: function(component, event, helper) {
        if (component.get('v.cartIsChanged')) {
            $A.get("e.c:QuotingToolModalRequestEvent").setParams({
                action: "SaveCartChanges",
                sourceId: "newQuote"
            }).fire();
            component.set("v.targetAction", 'newQuote');
        } else if (component.get('v.isSummaryChanged')) {
            $A.get("e.c:QuotingToolModalRequestEvent").setParams({
                action: "SaveQuoteChanges",
                sourceId: "newQuote"
            }).fire();
            component.set("v.targetAction", 'newQuote');
        } else {
            helper.selectQuoteInQuoteSelector(component, null, true);
            $A.get("e.c:QuotingToolNewQuoteEvent").setParams().fire();

            component.set("v.targetAction", null);
        }
    },

    removeQuote: function(component) {
        var Wizard = component.get('v.Wizard');
        $A.get("e.c:ModalRequestEvent").setParams({
            guid: 'deleteQuote',
            header: 'Delete Quote?',
            content: 'Are you sure you want to delete <b>' + Wizard.currentQuote.name + '</b> Quote?',
            params: {
                quoteId: Wizard.currentQuote.record.Id
            },
            buttons: [{
                name: 'yes',
                variant: 'brand',
                label: 'Delete Quote'
            }]
        }).fire();
    },

    cancelQuote: function(component) {
        var Wizard = component.get('v.Wizard');
        $A.get("e.c:ModalRequestEvent").setParams({
            guid: 'cancelQuote',
            header: 'Cancel Quote?',
            content: 'Are you sure you want to cancel this Change order Quote? All the information from this quote will be lost: <b>' + Wizard.currentQuote.name,
            params: {
                quoteId: Wizard.currentQuote.record.Id
            },
            buttons: [{
                name: 'yes',
                variant: 'brand',
                label: 'Yes'
            }]
        }).fire();
    },
    
    modalResponse: function(component, event) {
        var action = event.getParam('action');
        var modalResult = event.getParam('modalResult');
        if (modalResult === false && (action === 'SaveCartChanges' || action === 'SaveQuoteChanges')) {
            var quoteId = component.get("v.currentQuoteId");
            component.find("quoteSelector").set("v.value", quoteId);
        }
        if (action === 'DropLineItemsErrors') {
            component.set("v.targetAction", null);
            component.set("v.targetQuoteId", null);
        }
        if ((modalResult === false)) {
            component.set("v.targetAction", null);
            component.set("v.targetQuoteId", null);
        }
    },

    //Cart Actions
    discardCart: function(component, event, helper) {
        component.set("v.cartIsChanged", false);
        helper.completeAction(component);
    },
    cartSaved: function(component, event, helper) {
        component.set("v.cartIsChanged", false);
        helper.completeAction(component);
    },
    // Quote Actions
    discardQuote: function(component, event, helper) {
        helper.completeAction(component);
    },
    quoteSaved: function(component, event, helper) {
        helper.completeAction(component);
    },
    quoteDeleted: function(component, event, helper) {
        helper.finishDeleting(component);
    },
    propagateUser: function(component, event, helper) {
        var user = event.getParam('user');
        component.set('v.user', user);

        helper.checkUserAccess(component);
    },

    wizardChanged: function(component, event, helper) {
        var quotes = component.get('v.Wizard').getQuoteRecords();
        component.set('v.quotes', quotes);

        helper.updateQuoteSelectorOptions(component);
        helper.checkDisabling(component);
        helper.checkDisplaying(component);
    },

    showPopover: function(component, event, helper){
        var auraId = event.currentTarget.dataset.buttonauraid;
        var target = event.currentTarget;
        helper.showPopover(component, auraId, target);
    },

    hidePopover: function(){
        QW.popover.hide();
    },

    sendWithDocuSign: function (component, event, helper) {
        var docuSignComponent = null;
        helper.createDocuSignComponent(component)
            .then($A.getCallback(newCmp => {
                docuSignComponent = newCmp;
                return docuSignComponent.validate();
            }))
            .then($A.getCallback(isAllValid => {
                if (isAllValid) {
                    docuSignComponent.show();
                    component.set('v.docuSignComponent', docuSignComponent);
                }
            }));
    }
});