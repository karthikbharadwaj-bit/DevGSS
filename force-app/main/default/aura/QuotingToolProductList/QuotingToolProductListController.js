({
    doInit: function(component, event, helper) {
        helper.scrollTimer = null;
        component.set('v.messages', {
            onApprove: {
                priority: 2,
                active: false,
                message: 'Products tab is disabled while on Approval'
            },
            closedWon: {
                priority: 1,
                active: false,
                message: 'Products tab is disabled on Closed Won'
            },
            activeAgreement: {
                priority: 3,
                active: false,
                message: 'Products tab is disabled in Agreement Stage'
            },
            engagementCancelled: {
                priority: 4,
                active: false,
                message: 'Products tab is disabled if engagement has been cancelled'
            },
            proServIsSold: {
                priority: 5,
                active: false,
                message: 'Products tab is disabled when ProServ is Sold or Out for Signature'
            },
            tabIsDisabled: {
                priority: 6,
                active: false,
                message: 'Products tab is disabled'
            },
            quoteInvalid: {
                priority: 7,
                active: false,
                message: 'Products tab is disabled on invalid Quote'
            },
            primaryQuoteInvalid: {
                priority: 8,
                active: false,
                message: 'Products tab is disabled, primary quote is invalid'
            },
            pendingConfirmAndClose: {
                priority: 9,
                active: false,
                message: 'Products tab is disabled when pending for Confirm & Close'
            },
        });
        helper.makeCartItemsSet(component);

        if (component.get('v.Wizard.currentQuote')) {
            helper.syncProducts(component);
            helper.displayMessages(component);
            helper.checkDisplaying(component);
            helper.userFilterProds(component);
        }
    },
    messagesChanged: function(component) {
        var messages = component.get('v.messages');
        var activeMessage = {};
        for (var prop in messages) {
            if (messages[prop].active &&
                (!Object.keys(activeMessage).length || messages[prop].priority < activeMessage.priority)) {
                activeMessage = messages[prop];
            }
        }
        component.set('v.activeMessage', activeMessage.message);
    },
    /**
     * v.Wizard attribute Changed
     */
    wizardChanged: function(component, event, helper) {
        if (!component.get('v.Wizard.currentQuote')) {
            return;
        }

        helper.syncProducts(component);
        helper.displayMessages(component);
        helper.checkDisplaying(component);
        helper.userFilterProds(component);
    },
    /**
     * Product Name Filter Changed
     */
    productNameFilterChanged: function(component, event, helper) {
        helper.userFilterProds(component);
        helper.scrollToTop(component);
    },
    /**
     * Type Filter Changed
     */
    typeFilterChanged: function(component, event, helper) {
        helper.setFilterLevel(component);
        helper.userFilterProds(component);
        helper.checkDisplaying(component);
        helper.scrollToTop(component);
    },
    /**
     * Category Filter Changed
     */
    categoryFilterChanged: function(component, event, helper) {
        helper.setFilterLevel(component);
        helper.userFilterProds(component);
        helper.checkDisplaying(component);
        helper.scrollToTop(component);
    },
    /**
     * Plan Filter Changed
     */
    planFilterChanged: function(component, event, helper) {
        helper.setFilterLevel(component);
        helper.userFilterProds(component);
        helper.scrollToTop(component);
    },
    /**
     * Edition Filter Changed
     */
    editionFilterChanged: function(component, event, helper) {
        helper.setFilterLevel(component);
        helper.userFilterProds(component);
        helper.scrollToTop(component);
    },
    /**
     * Number Of Seats Filter Changed
     */
    seatsFilterChanged: function(component, event, helper) {
        helper.setFilterLevel(component);
        helper.userFilterProds(component);
        helper.scrollToTop(component);
    },
    /**
     * User changed Service filter on UI
     */
    uiTypeFilterChanged: function(component){
        component.set('v.editionFilter',"");
        component.set('v.planFilter',"");
        component.set('v.categoryFilter',"");
    },
    /**
     * User changed Service filter on UI
     */
    uiCategoryFilterChanged: function(component){
        component.set('v.editionFilter',"");
        component.set('v.planFilter',"");
    },
    /**
     * User changed Service filter on UI
     */
    uiPlanFilterChanged: function(component){
        component.set('v.editionFilter',"");
    },
    /**
     * Products in cart changed
     */
    cartItemsChanged: function(component, event, helper){
        helper.makeCartItemsSet(component);
    },
    /**
     * User selected another quote with selector
     */
    quoteSwitch: function(component, event, helper){
        helper.dropFilters(component);
        component.set('v.addingToCartProds',new Set());
    },

    tabIsActive: function (component, event, helper) {
        setTimeout($A.getCallback(() => helper.renderProducts(component)));
    },

    onTableScroll: function (component, event, helper) {
        helper.renderProducts(component);
    },

    onTableWheel: function (component, event) {
        RC.htmlUtils.trapScroll(event);
    },

    filteredProductsChanged: function (component, event, helper) {
        helper.setListBufferData(component);
    }
});