({
    doInit: function(component, event, helper) {
        component.set("v.deletingItems", new Set());
        component.set("v.deletingAreaCodeItems", new Set());
        helper.allowToEditDiscount(component);
    },

    /**
     * Save Cart Items to SF
     */
    saveCart: function(component, event, helper) {
        if (!helper.checkCartItems(component) ||
            !helper.validateAreaCodes(component) ||
            !helper.checkServicePlanRange(component) ||
            !helper.checkPhaseLineItemsOnChange(component) ||
            !helper.checkForQLIErrors(component)) return;

        return Promise.resolve()
            .then($A.getCallback(() => {
                return helper.deleteOneTimePhoneQli(component)
            }))
            .then($A.getCallback(() => {
                return helper.createQliFromOneTimeEntitlements(component)
            }))
            .then($A.getCallback(() => {
                return helper.checkQuantityApprovedRange(component)
            }))
            .then($A.getCallback(() => {
                return helper.saveCartItems(component)
            }))
    },
    modalResponse: function(component, event, helper) {
        var action = event.getParam("action");
        var modalResult = event.getParam("modalResult");
        var sourceId = event.getParam("sourceId");

        if (action == "SaveCartChanges" && modalResult) {
            if (sourceId === "getTaxesButton") {
                component.set('v.completeAction', 'getTaxes');
            } else if (sourceId === "removeTaxesButton") {
                component.set('v.completeAction', 'removeTaxes');
            }

            if (helper.checkServicePlanRange(component)
                && helper.checkPhaseLineItemsOnChange(component))
                return helper.saveCartItems(component);

        }
        if (action === 'SaveSeatWithZeroQuantity'
            && modalResult
            && helper.checkServicePlanRange(component)
            && helper.checkPhaseLineItemsOnChange(component)) {
            return helper.saveCartItems(component);
        }
    },
    emptyCart: function(component, event, helper) {
        // Bypass on cartItemsChange
        component.set('v.isBypassGetQuoteTotalValues1',true);
        component.set('v.isBypassGetQuoteTotalValues2',true);

        component.set("v.cartItems", []);
        component.set("v.quote", null);
    },
    updateMonthlyContract: function(component, event, helper) {
        var monthlyContractDiscount = event.getParam("monthlyContractDiscount");
        component.set("v.monthlyContractDiscount", monthlyContractDiscount);
    },
    /**
     * QuotingToolGetTaxesEvent Event handler
     * Add or Remove Taxes
     */
    onGetTaxesEvent: function(component, event, helper) {
        var action = event.getParam('action');
        if (action === "getTaxes") {
            helper.getTaxesToCart(component);
        } else if (action === "removeTaxes") {
            helper.removeTaxesFromCart(component);
        }
    },

    notificationAction: function(component, event) {
        let actionName = event.getParam("name");
        if (actionName === "signUpRestrict") {
            let Tabs = component.get('v.Tabs');

            Tabs.open(Tabs.cart);

            component.set('v.Tabs',Tabs);
        }
    },

    /**
     * Discard Cart Event fired
     */
    discardCart: function(component, event, helper){
        helper.discardAreaCodes(component);
        helper.setIsCartChanged(component);
    },

    deleteCartItem: function (component, event, helper) {
        var args = event.getParam('arguments');

        if (helper.checkPhaseLineItemsOnDelete(component, args.quoteLineItemToDelete)) {
            helper.deleteQli(component, args.quoteLineItemToDelete);
        }
    },
    /**
     *
     * @param component
     * @param event
     * @param helper
     */
    onCartListEntryEventHandler: function (component, event, helper) {
        var action = event.getParam('action');
        var params = event.getParam('params');
        // delete qli
        if (action === 'delete' && helper.checkPhaseLineItemsOnDelete(component, params.qli)) {
            helper.deleteQli(component, params.qli);
        }
    },

    /**
     * QuotingToolRefreshCartEvent handler
     */
    onRefreshCartEvent: function(component, event, helper){
        helper.refreshCart(component);
    },

    /**
     * Add new product to cart
     */
    onAddToCartEvent: function (component, event, helper) {
        let product = event.getParam('Product');
        if (helper.validateBeforeAddToCart(component, product)) {
            if (!component.get('v.addToCartQueue')) {
                component.set('v.addToCartQueue', new QW.AddToCartQueue({
                    addToCartMethod: $A.getCallback(products => helper.createQuoteLineItems(component, products)),
                    finalizeMethod: $A.getCallback(products => helper.finalizeAddToCart(component, products))
                }));
            }
            helper.markProductsAsAddingToCart(component, [product]);
            component.get('v.addToCartQueue').addItemToQueue(product);
            if(component.get('v.state').isTaxesInCart) {
                helper.removeTaxesFromCart(component);
            }
        }
    },

    doneRendering: function(component, event, helper) {
      helper.calcTableHead(component);
    },

    /**
     * Show Provisioned by inContact tooltip
     * @param component
     * @param event
     * @fires PopoverEvent
     */
    mouseOverProvisionedIcon: function(component, event){
        $A.get("e.c:PopoverEvent").setParams({
            target: event.currentTarget,
            show: true,
            showIcon: true,
            iconTheme: 'info',
            text: 'If checked, Line Item will be provisioned by inContact'
        }).fire();
    },
    /**
     * Hide popover
     * @fires PopoverEvent
     */
    hidePopover: function(){
        $A.get("e.c:PopoverEvent").setParams({
            show: false
        }).fire();
    },
    /**
     * QuotingToolAreaCodeListEntry Event handler
     */
    onAreaCodeListEntryEvent: function(component, event, helper){
        var action = event.getParam('action');

        switch (action){

            // Delete Area Code Line Item
            case 'delete':
                helper.deleteAreaCodeListEntry(component, event.getParam('params').areaCodeItem);
                break;
        }

    },
    discard: function(){
        $A.get("e.c:QuotingToolDiscardCardEvent").fire();
    },

    // ================================================================================
    //  On attribute changed event handlers
    // ================================================================================

    /**
     * v.state attribute changed
     * @param component
     * @param event
     * @param helper
     */
    stateChanged: function(component, event, helper){
        helper.checkDisplayColumns(component);
    },

    /**
     * v.Wizard attribute changed
     * @param component
     * @param event
     * @param helper
     */
    wizardChanged: function(component, event, helper){
        helper.checkDisplayColumns(component);
    },

    /**
     * v.updateTrigger changed
     * Enable save button if there are unsaved changes in cart items or area codes
     */
    updateTriggerChanged: function(component, event, helper){
        helper.setIsCartChanged(component);
    },

    /**
     * v.cartItems attribute changed
     * @param component
     * @param event
     * @param helper
     */
    cartItemsChanged: function(component, event, helper) {
        helper.checkEntitlements(component);
        helper.updateItems(component, ['change']);
        helper.updateUserCartItems(component);
        helper.getServiceProduct(component);
        // TODO refactoring needed here
        // do not make unnecessary operations on every cartItems change
        if (component.get('v.isBypassGetQuoteTotalValues1')){
            component.set('v.isBypassGetQuoteTotalValues1',false);
            return;
        }
        if (component.get('v.isBypassGetQuoteTotalValues2')){
            component.set('v.isBypassGetQuoteTotalValues2',false);
            return;
        }
        helper.getQuoteTotalValuesForItems(component, component.get('v.quote'), helper.getCartItems(component, false) );
    },

    /**
     * v.quote attribute changed
     * @param component
     * @param event
     * @param helper
     */
    quoteChange: function(component, event, helper) {
        var oldQuote = component.get('v.oldQuote');
        var quote = component.get('v.quote');

        if (oldQuote && quote && ((oldQuote.Id !== quote.Id) || (oldQuote.Pricebook2Id !== quote.Pricebook2Id))) {
            component.set('v.cartItems', []);
            component.set('v.unmatchedCartItems', []);
            component.set('v.currentCartItems', []);
        }

        if (quote) {
            helper.getEntitlementsFromCtrl(component, quote.AccountId);
            component.set('v.oldQuote', JSON.parse(JSON.stringify(quote)));
        }
    },

    addingToCartProdsChanged: function(component, event, helper){
        if(component.get('v.Wizard')){
            var isEmpty = helper.isSetEmpty(component.get('v.addingToCartProds'));
            var Wizard = component.get('v.Wizard');
            Wizard.isCartItemAddedDeleted = !isEmpty;
            component.set('v.Wizard', Wizard);
        }
    },
    deletingItemsChanged: function(component, event, helper){
        if(component.get('v.Wizard')){
            var isEmpty = helper.isSetEmpty(component.get('v.deletingItems'));
            var Wizard = component.get('v.Wizard');
            Wizard.isCartItemAddedDeleted = !isEmpty;
            component.set('v.Wizard', Wizard);
        }
    },

    tabsChanged: function(component){
        var Tabs = component.get('v.Tabs');

        RC.cssUtils.toggleShow(component, 'cart', Tabs.cart.isOpen, 'hidden');
    },

    onTableWheel: function (component, event) {
        RC.htmlUtils.trapScroll(event);
    }
});