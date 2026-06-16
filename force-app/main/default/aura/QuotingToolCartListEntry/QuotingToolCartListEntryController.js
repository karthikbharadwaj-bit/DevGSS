/* globals QW, console  */
({
    doInit: function (component, event, helper) {
        try {

            var qli = component.get("v.document");
            if (!qli) return;
            if (!component.get('v.calcMode')) {
                console.log('%c(=) Init qli: ' + (qli && qli.Product2 && qli.Product2.Name), 'color: #8b95a5');
            }

            // Set
            helper.setCartItem(component);
            helper.setQuantity(component);
            helper.setDiscount(component, qli);
            helper.setPrecision(component, qli);
            helper.setProvisionedByInContact(component, qli);
            helper.calcAreaCodesQuantity(component);

            // Check
            helper.checkDeactivation(component, qli);

            // Old code need to refactor it;
            if (component.get('v.unmatched')) qli.Unmatched = true;


            helper.setYourPrice(component, qli);
            helper.setDeactivated(component, qli);

            helper.checkQLIDisabling(component);
            helper.checkInputsDisabling(component);
            helper.prepareTooltips(component);
            helper.allowToEditDiscount(component);
        } catch (e) {
            console.log(e);
        }
    },

    // ================================================================================
    //  On External Events
    // ================================================================================

    /**
     * On QuotingToolDiscardCardEvent
     * @param component
     * @param event
     * @param helper
     */
    discardCart: function(component, event, helper) {
        if (!component.get("v.document") || !component.get("v.Wizard")) return;

        helper.discardValues(component);
        helper.checkIsQLIChanged(component);
        helper.checkDeactivation(component);
    },

    // ================================================================================
    //  On User make actions with cart item
    // ================================================================================

    /**
     * User Clicked "Add Area Code" Button
     */
    createAreaCodeItem: function(component, event, helper){
        helper.addAreaCodeItem(component);
    },

    /**
     * User click on delete cart item button
     */
    deleteItem: function(component, event, helper) {
        helper.deleteQli(component);
    },

    // ================================================================================
    //  On User make UI actions
    // ================================================================================

    /**
     * User click expand/collapse (">") button
     * Show hide QLI details
     */
    toggleDetails:function(component, event, helper){

        if (component.get('v.isDetailsEnabled')) {
            var qli = component.get('v.document');
            qli.isShowDetails = !qli.isShowDetails;
            component.set('v.document', qli);

            helper.checkMessages(component);
        }

    },

    /**
     * User hover cursor above Area Codes Quantity field
     * @param component
     * @param event
     */
    mouseOverAreaCodesQty: function(component, event){
        $A.get("e.c:PopoverEvent").setParams({
            target: event.currentTarget,
            show: true,
            showIcon: false,
            theme: 'tooltip',
            preferredPosition: 'top',
            text: 'You can specify quantity by assigning Area Codes. Click on arrow near the product name to see more'
        }).fire();
    },

    /**
     * User move cursor out of Area Codes quantity field
     */
    mouseOutAreaCodesQty: function(){
        $A.get("e.c:PopoverEvent").setParams({
            show: false
        }).fire();
    },

    // ================================================================================
    //  On user make change to an input
    // ================================================================================

    /**
     * User changed Discount value field
     * Apply discount changes to product in cart
     */
    updateDiscount: function(component, event, helper) {
        var dsc = component.get("v.discount");
        if(!dsc || dsc < 0) dsc = 0;
        if (dsc >= 0) {
            var qli = component.get("v.document");
            qli.Discount_number__c = dsc;
            component.set("v.document", qli);
        }
        component.set("v.discount", dsc);
        helper.checkIsQLIChanged(component);
    },

    /**
     * User changed Discount type selector
     * Apply discount type changes to product in cart
     */
    updateDiscountType: function(component, event, helper) {
        var qli = component.get("v.document");
        qli.Discount_type__c = component.get("v.discountType");
        component.set("v.document", qli);
        helper.checkIsQLIChanged(component);
    },

    /**
     * User changed Quantity field
     * Apply quantity changes to product in cart
     */
    updateQuantity: function(component, event, helper) {
        if(component.get('v.isEntChanging')) return;
        var qli = component.get('v.document');
        var qty = Number(component.get('v.quantity'));
        var Wizard = component.get('v.Wizard');

        if(!qty || qty < 0) qty = 0;

        if(!helper.checkAllowDownsell(component, qty, 'quantity'))  {
            helper.checkIsQLIChanged(component);
            return;
        }

        helper.checkSeatDeactivation(component, qty);

        qli.Quantity = qty;
        qli.NewQuantity__c = qty;
        if (QW.QLIHelper.isHasActiveEntitlement(qli)){
            qli.NewQuantity__c = qli.Entitlement__r.DisplayQuantity__c + qty;

        } else if (Wizard.opportunity.isChangeOrderOpportunity && qli.Id && qli.Asset__r){
            qli.NewQuantity__c = qli.Asset__r.Delivered_Quantity__c + qty;

        }

        component.set("v.quantity", qty);
        component.set("v.document", qli);
        helper.checkIsQLIChanged(component);
    },

    /**
     * User changed New Quantity (Entitlem) field
     * @param component
     * @param event
     * @param helper
     */
    updateNewQuantity: function(component, event, helper) {
        if(component.get('v.isEntChanging')) return;
        var qli = component.get("v.document");
        var existingQuantity = component.get("v.existingQuantity");
        var qty = Number(component.get("v.newQuantity"));
        var Wizard = component.get('v.Wizard');

        if(!qty || qty < 0) qty = 0;

        // validation
        if(!helper.checkAllowDownsell(component, qty, 'newQuantity'))
            return;

        // Deactivation
        helper.checkSeatDeactivation(component, qty);
        helper.checkDeactivation(component);

        qli.Quantity = qty;
        if (QW.QLIHelper.isHasActiveEntitlement(qli)){
            qli.Quantity = qty - (existingQuantity || 0);

        } else if (Wizard.opportunity.isChangeOrderOpportunity && qli.Id && qli.Asset__r){
            qli.Quantity = qty - qli.Asset__r.Delivered_Quantity__c;
        }

        qli.NewQuantity__c = qty;
        component.set("v.newQuantity", qty);
        component.set("v.document", qli);

        helper.validateQLI(component);
        helper.checkIsQLIChanged(component);
    },

    /**
     *  User clicked "Should Go To CC Order 'Details'" checkbox
     *  B-2076
     * @param component
     * @param event
     * @param helper
     */
    updateProvisionedByInContact: function(component, event, helper){
        var qli = component.get("v.document");
        qli.Provisioned_by_inContact__c = component.get('v.provisionedByInContact');
        component.set("v.document", qli);
        helper.checkIsQLIChanged(component);
    },

    // ================================================================================
    //  On attribute changed event handlers
    // ================================================================================

    /**
     * v.activePriceBookEntry attribute changed
     * @param component
     * @param event
     * @param helper
     */
    activePriceBookEntryChanged: function(component, event, helper){
        helper.prepareTooltips(component);
    },
    /**
     * v.deletingItems attribute changed
     * @param component
     * @param event
     * @param helper
     */
    deletingItemsChanged: function(component, event, helper){
        helper.checkInputsDisabling(component);
    },
    /**
     * v.document (QuoteLineItem) attribute changed
     * @param component
     * @param event
     * @param helper
     */
    qliChanged: function(component, event, helper){
        if (!component.get("v.document")) return;
        helper.checkShowDetails(component);
        helper.checkVisibility(component);
    },
    /**
     * v.Wizard attribute changed
     */
    wizardChanged: function(component, event, helper){
        if (!component.get('v.Wizard.currentQuote') || !component.get('v.document')) return;
        try {
            helper.setCartItem(component);
            helper.checkVisibility(component);
            helper.checkInputsDisabling(component);
        } catch (e) {
            console.log(e);
        }
    },
    /**
     * v.updateTrigger attribute changed
     */
    updateTriggerChanged: function(component, event, helper){
        helper.calcAreaCodesQuantity(component);
    },
    /**
     * v.areaCodeItemsOnQlIqty attribute changed
     */
    areaCodeItemsOnQlIqtyChanged: function(component, event, helper){
        helper.prepareTooltips(component);
    },
    /**
     * v.areaCodeItemsInOperation attribute changed
     */
    areaCodeItemsInOperationChanged: function(component, event, helper){
        helper.calcAreaCodesQuantity(component);
        helper.checkMessages(component);
    },
    /**
     * v.quote attribute changed
     */
    quoteChanged: function(component, event, helper) {
        if(!component.get('v.document')) return;

        helper.checkInputsDisabling(component);
        helper.prepareTooltips(component);
    },
    /**
     * v.state attribute changed
     */
    stateChanged: function(component, event, helper) {
        if (!component.get('v.document')) return;
        helper.checkInputsDisabling(component);
        helper.checkVisibility(component);
        helper.prepareTooltips(component);
    }
});