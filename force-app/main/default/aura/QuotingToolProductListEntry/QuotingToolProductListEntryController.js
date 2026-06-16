({
    doInit: function(component, event, helper) {
        helper.updateProductsState(component);
    },
    /**
     * User clicked on "Add to Cart" button
     */
    addToCart: function(component) {
        var pricebookEntry = component.get('v.pricebookEntry');
        var Wizard = component.get('v.Wizard');

        var settings = component.get('v.settings');
        var featureForEES = settings.featureForEES ? settings.featureForEES : 38;

        if(QW.Product2Helper.isContactCenter(pricebookEntry.Product2)) {
            Wizard.currentQuote.isCcProductInCart = true;
            component.set('v.Wizard', Wizard);
        }

        if(QW.Product2Helper.isInContact(pricebookEntry.Product2)) {
            Wizard.currentQuote.isInContactProductInCart = true;
            component.set('v.Wizard', Wizard);
        }

        if(QW.Product2Helper.checkIsExtendedEnterpriseSupport(pricebookEntry.Product2, featureForEES)) {
            Wizard.currentQuote.isExtendedEnterpriseProdInCart = true;
            component.set('v.Wizard', Wizard);
        }

        $A.get("e.c:QuotingToolAddToCartEvent").setParams({
            Product: component.get("v.pricebookEntry")
        }).fire();
    },
    cartItemsSetChanged: function(component, event, helper){
        helper.updateProductsState(component);
    },
    addingToCartProdsChanged: function(component, event, helper){
        helper.updateProductsState(component);
    },
    wizardChanged: function(component, event, helper){
        if (!component.get('v.Wizard.currentQuote'))
            return;

        helper.updateProductsState(component);
    },
    isCommonPhoneIsAddingToCartChanged: function(component, event, helper){
        helper.updateProductsState(component);
    },
    onMouseOverAddToCart: function(component, event, helper){
        var pricebookEntry = component.get('v.pricebookEntry');
        var Wizard = component.get('v.Wizard');

        var settings = component.get('v.settings');
        var featureForEES = settings.featureForEES ? settings.featureForEES : 38;

        if(QW.Product2Helper.isContactCenter(pricebookEntry.Product2)) {
            if(Wizard.currentQuote.isInContactProductInCart) {
                $A.get("e.c:PopoverEvent").setParams({
                    target: event.currentTarget,
                    show: true,
                    showIcon: true,
                    iconTheme: 'info',
                    text: '<b>You can\'t add ' + pricebookEntry.Product2.Sub_Category__c + ' products</b><br/>' +
                            pricebookEntry.Product2.Sub_Category__c + ' products can\'t be added to the Cart if there are any inContact Interconnect products in it.'
                }).fire();
            }
            else if(Wizard.isAccHasIcEntls) {
                $A.get("e.c:PopoverEvent").setParams({
                    target: event.currentTarget,
                    show: true,
                    showIcon: true,
                    iconTheme: 'info',
                    text: '<b>You can\'t add ' + pricebookEntry.Product2.Sub_Category__c + ' products</b><br/>' +
                          'Can\'t add ' + pricebookEntry.Product2.Sub_Category__c + ' products to the Cart if there are any inContact Interconnect entitlements on current Account.'
                }).fire();
            }
        }

        if(QW.Product2Helper.isInContact(pricebookEntry.Product2)) {
            if(Wizard.isAccHasCcEntls) {
                var mainCCCategory = helper.getMainCCCategory(Wizard.currentQuote);
                $A.get("e.c:PopoverEvent").setParams({
                    target: event.currentTarget,
                    show: true,
                    showIcon: true,
                    iconTheme: 'info',
                    text: '<b>You can\'t add Contact Center products</b><br/>' +
                          'Can\'t add inContact Interconnect products to the Cart if there are any ' + mainCCCategory + ' entitlements on current Account.'
                }).fire();
            }
            else if(Wizard.currentQuote.isCcProductInCart) {
                var mainCCCategory = helper.getMainCCCategory(Wizard.currentQuote);
                console.log('INCONTACT TOOLTIP');
                $A.get("e.c:PopoverEvent").setParams({
                    target: event.currentTarget,
                    show: true,
                    showIcon: true,
                    iconTheme: 'info',
                    text: '<b>You can\'t add inContact products</b><br/>' +
                    'inContact Interconnect products can\'t be added to the Cart if there are any ' + mainCCCategory + ' products in it.'
                }).fire();
            }
        }

        var isEES = QW.Product2Helper.checkIsExtendedEnterpriseSupport(pricebookEntry.Product2, featureForEES);
        if ( !(!isEES || (isEES && QW.Product2Helper.isExtendedEnterpriseSupportInRange(pricebookEntry.Product2, component.get('v.serviceCartItem')))) ) {
            $A.get("e.c:PopoverEvent").setParams({
                target: event.currentTarget,
                show: true,
                showIcon: true,
                iconTheme: 'info',
                text: '<b>You can\'t add Extended Enterprise Support</b><br/>'
                + 'This tier of Extended Enterprise Support is available if Account has from '
                + '<b>' + pricebookEntry.Product2.Seat_Range_Min__c + '</b> to '
                + '<b>' + pricebookEntry.Product2.Seat_Range_Max__c + '</b> Digital Lines.'
            }).fire();
        }

        if(QW.Product2Helper.isContactCenterExtendedEnterpriseSupport(pricebookEntry.Product2)) {
            if(!Wizard.currentQuote.isCcSeatProductInCart) {
                $A.get("e.c:PopoverEvent").setParams({
                    target: event.currentTarget,
                    show: true,
                    showIcon: true,
                    iconTheme: 'info',
                    text: '<b>You can\'t add Contact Center Extended Enterprise Support</b><br/>' +
                          'Contact Center Extended Enterprise Support is available only if there is Contact Center Seat in the Cart.'
                }).fire();
            }else if(Wizard.currentQuote.isCcExtendedEnterpriseProdInCart) {
                $A.get("e.c:PopoverEvent").setParams({
                    target: event.currentTarget,
                    show: true,
                    showIcon: true,
                    iconTheme: 'info',
                    text: '<b>You can\'t add Contact Center Extended Enterprise Support</b><br/>' +
                          'Only one Tier of Contact Center Extended Enterprise Support should be active.'
                }).fire();
            }
        }
    },
    hidePopover: function(){
        $A.get("e.c:PopoverEvent").setParams({
            show: false
        }).fire();
    }
});