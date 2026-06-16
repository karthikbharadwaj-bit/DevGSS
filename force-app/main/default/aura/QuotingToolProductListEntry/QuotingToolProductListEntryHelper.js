({
    /**
     *   Check if product is in cart and update its status
     */
    updateProductsState: function(component) {
        var Wizard = component.get('v.Wizard');

        var cartItemsSet = component.get('v.cartItemsSet');
        var addingToCartProds = component.get('v.addingToCartProds');
        var pricebookEntry = component.get('v.pricebookEntry');

        var settings = component.get('v.settings');
        var featureForEES = settings.featureForEES ? settings.featureForEES : 38;

        if (!pricebookEntry) return;

        var isCommonPhoneIsAddingToCart = pricebookEntry.Product2.Family === 'Common Phones'
            && component.get('v.isCommonPhoneIsAddingToCart');

        var isCcEEsProductIsAddingToCart = QW.Product2Helper.isContactCenterExtendedEnterpriseSupport(pricebookEntry.Product2)
            && component.get('v.isCcEEsProductIsAddingToCart');

        var isIvinexUnifiedUserExperienceProductAddedToCart = (pricebookEntry.Product2.CatID__c == QW.CONSTANTS.PRODUCT2.CAT_ID.IVINEX_UNIFIED_USER_EXPERIENCE_PER_CONCURRENT_USER
            || pricebookEntry.Product2.CatID__c == QW.CONSTANTS.PRODUCT2.CAT_ID.IVINEX_UNIFIED_USER_EXPERIENCE_PER_CONFIGURED_USER)
            && component.get('v.isIvinexUnifiedUserExperienceProductAddedToCart');

        var isExtendendEnterpriseSupportUnavailable = QW.Product2Helper.checkIsExtendedEnterpriseSupport(pricebookEntry.Product2, featureForEES)
            && !QW.Product2Helper.isExtendedEnterpriseSupportInRange(
                pricebookEntry.Product2,
                component.get('v.serviceCartItem'));

        var isCCExtendendEnterpriseSupportUnavailable = QW.Product2Helper.isContactCenterExtendedEnterpriseSupport(pricebookEntry.Product2) &&
            (!Wizard.currentQuote.isCcSeatProductInCart || Wizard.currentQuote.isCcExtendedEnterpriseProdInCart);

        var isCurrentProductCc = QW.Product2Helper.isContactCenter(pricebookEntry.Product2);
        var isCurrentProductInContact = QW.Product2Helper.isInContact(pricebookEntry.Product2);

        var isContactCenterQuote = Wizard.currentQuote && Wizard.currentQuote.isCC;

        var isBillingOpportunity = Wizard.opportunity &&
                Wizard.opportunity.record &&
                Wizard.opportunity.record.Is_Billing_Opportunity__c ? Wizard.opportunity.record.Is_Billing_Opportunity__c : false;

        const isPrimaryQuoteOnApproval = Wizard.primaryQuote && Wizard.primaryQuote.isOnApproval;
        const isPrimaryQuoteAgreement = Wizard.primaryQuote && Wizard.primaryQuote.isAgreement;
        const isCcProductInCart = Wizard.primaryQuote && Wizard.primaryQuote.isCcProductInCart;
        const isInContactProductInCart = Wizard.primaryQuote && Wizard.primaryQuote.isInContactProductInCart;

        var isCantAddProduct = isExtendendEnterpriseSupportUnavailable
            || isCCExtendendEnterpriseSupportUnavailable
            || (isCcProductInCart || Wizard.isAccHasCcEntls) && isCurrentProductInContact
            || (isInContactProductInCart || Wizard.isAccHasIcEntls) && isCurrentProductCc
            || (isContactCenterQuote && (isBillingOpportunity && (isPrimaryQuoteOnApproval || isPrimaryQuoteAgreement)));

        var productDisabled = isCommonPhoneIsAddingToCart
            || isCcEEsProductIsAddingToCart
            || isCantAddProduct
            || isIvinexUnifiedUserExperienceProductAddedToCart;

        if (component.get('v.isIvinexUnifiedUserExperienceProductAddedToCart')
            && (pricebookEntry.Product2.CatID__c == QW.CONSTANTS.PRODUCT2.CAT_ID.IVINEX_UNIFIED_USER_EXPERIENCE_ADDITIONAL_STORAGE
            || pricebookEntry.Product2.CatID__c == QW.CONSTANTS.PRODUCT2.CAT_ID.IVINEX_UNIFIED_USER_EXPERIENCE_BU_CHARGE)
            && component.get('v.prodState') == 'default' && !component.get('v.prodDisabled')) {
                var addToCartAction = component.get('c.addToCart');
                $A.enqueueAction(addToCartAction);
        }

        var newState = 'default';
        if (pricebookEntry) {
            if (cartItemsSet && cartItemsSet.has(pricebookEntry.Product2Id)) {
                newState = 'cart';
            } else if ( addingToCartProds && addingToCartProds.has(pricebookEntry.Product2Id) ) {
                newState = 'busy';
            } else if (isCantAddProduct){
                newState = 'unavailable';
            }
        }

        this.showTooltip(component);

        var addToCartLabel = {
            default: 'Add To Cart',
            cart: 'Added to cart',
            busy: 'Adding To Cart',
            unavailable: 'Unavailable'
        };
        component.set('v.addToCartLabel', addToCartLabel[newState]);
        component.set('v.prodState', newState);
        component.set('v.prodDisabled',productDisabled);
    },
    showTooltip: function(component){
        var pricebookEntry = component.get('v.pricebookEntry');
        let warningMessage = pricebookEntry.Product2.Warning_Message__c;

        var settings = component.get('v.settings');
        var featureForEES = settings.featureForEES ? settings.featureForEES : 38;

        var isExtendedEnterpriseSupport = QW.Product2Helper.checkIsExtendedEnterpriseSupport(pricebookEntry.Product2, featureForEES);
        var isInContactProduct = QW.Product2Helper.isInContact(pricebookEntry.Product2);
        var isContactCenterProduct = QW.Product2Helper.isContactCenter(pricebookEntry.Product2);

        var currentQuote = component.get('v.Wizard.currentQuote');
        var Wizard = component.get('v.Wizard') ;

        if(isExtendedEnterpriseSupport) {
            QW.cssUtils.toggleShow(component, 'tooltipContainer', isExtendedEnterpriseSupport);
            component.find('tooltip').set('v.text', 'This tier of Extended Enterprise Support is available if Account has '
            + 'from <b>' + pricebookEntry.Product2.Seat_Range_Min__c + '</b>'
            +' to <b>' + pricebookEntry.Product2.Seat_Range_Max__c + '</b> Digital Lines.');
        }

        if(isInContactProduct) {
            if(currentQuote.isCcProductInCart) {
                QW.cssUtils.toggleShow(component, 'tooltipContainer', true);

                let tooltipText = 'Can\'t add inContact Interconnect products to the Cart if there are any Contact Center products in it.';
                component.find('tooltip').set('v.text', tooltipText);
            } else if(Wizard.isAccHasCcEntls) {
                QW.cssUtils.toggleShow(component, 'tooltipContainer', true);

                let tooltipText = 'Can\'t add inContact Interconnect products to the Cart if there are any Contact Center entitlements on current Account.';
                component.find('tooltip').set('v.text', tooltipText);
            } else {
                QW.cssUtils.toggleShow(component, 'tooltipContainer', false);
            }
        }

        if(isContactCenterProduct){
            if(currentQuote.isInContactProductInCart) {
                QW.cssUtils.toggleShow(component, 'tooltipContainer', true);

                let tooltipText = 'Can\'t add Contact Center products to the Cart if there are any inContact products in it.';
                component.find('tooltip').set('v.text', tooltipText);
            } else if(Wizard.isAccHasIcEntls) {
                QW.cssUtils.toggleShow(component, 'tooltipContainer', true);

                let tooltipText = 'Can\'t add Contact Center products to the Cart if there are any inContact Interconnect entitlements on current Account.';
                component.find('tooltip').set('v.text', tooltipText);
            } else {
                QW.cssUtils.toggleShow(component, 'tooltipContainer', false);
            }
        }

        if (warningMessage) {
            QW.cssUtils.toggleShow(component, 'tooltipContainer', true);
            component.find('tooltip').set('v.text', warningMessage);
        }
    },

    getMainCCCategory: function(currentQuote){
        var quoteLineItems = currentQuote.cartItems.map(item => item.record);
        return QW.QuoteHelper.getCCCategory(quoteLineItems);
    }
});