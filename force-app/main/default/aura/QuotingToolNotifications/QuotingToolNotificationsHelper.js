({
    addEventListeners: function(component){
        this.documentClickHandlerWrapper = $A.getCallback(this.documentClickHandler.bind(this, component));
        document.addEventListener('click', this.documentClickHandlerWrapper, false);
    },

    removeEventListeners: function(){
        document.removeEventListener('click', this.documentClickHandlerWrapper, false);
    },

    documentClickHandler: function(component){
        if (component.get('v.preventNotificationsClose'))
            component.set('v.preventNotificationsClose', false);
        else
            this.closeNotifications(component);
    },

    /**
     * Collapse notifications. Only the top one will be visible
     */
    closeNotifications: function(component) {
        var activeNotifications = component.get('v.activeNotifications');

        activeNotifications.forEach(function(notification){
            notification.isHelpTextShown = false;
        });
        component.set('v.activeNotifications', activeNotifications);

        $A.util.removeClass(component.find('notificationsContainer'), 'notifications--open');
    },
    /**
     * Show all notifications
     */
    openNotifications: function(component) {
        $A.util.addClass(component.find('notificationsContainer'), 'notifications--open');
    },

    findNotification: function(notificationList, notificationName){
        var foundNotification = null;
        notificationList.forEach(function(notification){
            if (notification.name === notificationName){
                foundNotification = notification;
            }
        });
        return foundNotification
    },

    /**
     * Go through all notification checker methods with name checkNotification_%notification name%
     */
    checkNotifications: function(component) {
        let Tabs = component.get('v.Tabs');
        var allNotifications = component.get("v.allNotifications");
        var activeNotifications = component.get("v.activeNotifications");
        var newNotifications = [];
        allNotifications.forEach(function(notification) {
            var checkFn = this['checkNotification_' + notification.name];
            if (typeof checkFn === 'function') {
                var showNotification = checkFn(component);
                if (showNotification) {
                    newNotifications.push(this.prepareNotification(component, notification));
                }
            }
        }, this);

        // Sort notifications according to current stage and priority
        newNotifications.sort(this.sortNotifications(Tabs.openTabIndex));

        var searchActiveNotifications = activeNotifications.map(function (n) {
            return n.name;
        });
        var bottomNotifications = newNotifications.filter(function (n) {
            return searchActiveNotifications.indexOf(n.name) > -1;
        });
        var topNotifications = newNotifications.filter(function (n) {
            return searchActiveNotifications.indexOf(n.name) === -1;
        });
        component.set("v.activeNotifications", newNotifications);
        var domActions = [];
        if (newNotifications.length === 0) {
            domActions.push('hide');
        } else {
            if (newNotifications.length === 1) {
                domActions.push('one');
            } else {
                domActions.push('multiple');
            }

            if (topNotifications.length > 0) {
                domActions.push('add');
            } else if (bottomNotifications.length < activeNotifications.length) {
                domActions.push('remove');
            }
        }
        if (domActions.length > 0) {
            this.animate(component, domActions);
        }
    },
    /**
     * Sort notifications based on their priority
     */
    sortNotifications: function(stage) {
        return function(a, b) {
            return (b.priority[stage] < a.priority[stage]) - (a.priority[stage] < b.priority[stage]);
        };
    },
    /**
     * Fill placeholders in notification
     */
    prepareNotification: function(component, notification) {
        var preparedNotification = Object.assign({}, notification);
        if (notification && (notification.name === 'upsell' || notification.name === 'upsellDigitalLines')) {
            preparedNotification.text = preparedNotification.text.replace('${numberDLs}', component.get("v.numberDLs"));
        }
        if (notification && (notification.name === 'proServDetails')) {
            var quote = component.get("v.quote");
            var text = '';
            if (quote && quote.ProServ_Details__c) {
                text = quote.ProServ_Details__c;
            }
            preparedNotification.text = preparedNotification.text.replace('${proServDetails}', text);
        }
        return preparedNotification;
    },
    /**
     * Apply styles to notification bar
     */
    animate: function(component, domActions) {
        if (Array.isArray(domActions)) {
            var notificationsContainer = component.find('notificationsContainer');
            var removeClass = [];
            var addClass = [];
            var addClassRevert = false;
            var removeClassRevert = false;
            domActions.forEach(function(action) {
                switch (action) {
                    case 'add':
                        removeClass.push('slds-hide');
                        addClass.push('notifications--add');
                        addClassRevert = true;
                        break;
                    case 'remove':
                        addClass.push('notifications--remove');
                        removeClassRevert = true;
                        break;
                    case 'hide':
                        addClass.push('slds-hide');
                        break;
                    case 'one':
                        removeClass.push('notifications--multiple');
                        break;
                    case 'multiple':
                        addClass.push('notifications--multiple');
                        break;
                }
            });

            removeClass.forEach(function(cssClass) {
                $A.util.removeClass(notificationsContainer, cssClass);
            });
            addClass.forEach(function(cssClass) {
                $A.util.addClass(notificationsContainer, cssClass);
            });
            if (addClassRevert) {
                setTimeout($A.getCallback(function() {
                    if (component.isValid()) {
                        $A.util.removeClass(notificationsContainer, "notifications--add");
                    }
                }), 1000);
            }
            if (removeClassRevert) {
                setTimeout($A.getCallback(function() {
                    if (component.isValid()) {
                        $A.util.removeClass(notificationsContainer, "notifications--remove");
                    }
                }), 1000);
            }
        }
    },

    checkNotification_pendingForApproval: function(component) {
        var result = false;
        var quote = component.get("v.quote");
        if (quote && (quote.Approved_Status__c === 'Pending L1 Approval' ||
                quote.Approved_Status__c === 'Pending L2 Approval' ||
                quote.Approved_Status__c === 'Pending L3 Approval' ||
                quote.Approved_Status__c === 'Pending L4 Approval' ||
                quote.Approved_Status__c === 'Pending L5 Approval')) {
            result = true;
        }
        return result;
    },
    checkNotification_invalidDiscountedPhonesQuantity: function(component) {
        var result = false;
        var quote = component.get("v.quote");
        if (quote && quote.InvalidDiscountedPhonesQuantity__c === true && quote.Errors__c !== 'InvalidDiscountedPhonesQuantityForUpsell') {
            result = true;
        }
        return result;
    },
    checkNotification_invalidDiscountedPhonesQuantityForUpsell: function(component) {
        var result = false;
        var quote = component.get("v.quote");
        if (quote && quote.InvalidDiscountedPhonesQuantity__c === true && quote.Errors__c === 'InvalidDiscountedPhonesQuantityForUpsell') {
            result = true;
        }
        return result;
    },
    checkNotification_invalidGlobalOfficePhonesQuantity: function(component) {
        var result = false;
        var quote = component.get("v.quote");
        if (quote && quote.InvalidGlobalOfficePhonesQuantity__c === true) {
            result = true;
        }
        return result;
    },
    checkNotification_invalidLimitedExtensionPhonesQuantity: function(component) {
        var result = false;
        var quote = component.get("v.quote");
        if (quote && quote.InvalidLimitedExtensionPhonesQuantity__c === true) {
            result = true;
        }
        return result;
    },
    checkNotification_fixErrors: function(component) {
        var quote = component.get("v.quote");
        return quote && (quote.InvalidDiscountedPhonesQuantity__c ||
                         quote.InvalidGlobalOfficePhonesQuantity__c ||
                         quote.InvalidLimitedExtensionPhonesQuantity__c ||
                         quote.Invalid_Number_of_800_Setups__c ||
                         quote.Invalid_Number_of_Int_TF_Setups__c ||
                         quote.Invalid_Number_of_Vanity_Setups__c ||
                         quote.Required_Area_Codes_are_empty__c ||
                         quote.Invalid_GO_LE_Phones_Quantity__c);
    },
    checkNotification_rentalPhonesAvailability: function(component) {
        var result = false;
        var cartItems = component.get("v.cartItems");
        var quote = component.get("v.quote");
        var showRentalPhonesAvailability = false;
        if (quote && Array.isArray(cartItems)) {
            for (var i = 0; i < cartItems.length; i++) {
                var family = (cartItems[i].Product2.Family).replace(/\s/g, '');
                if ((family === ("Rental Phones").replace(/\s/g, '') ||
                        family === ("Global Office Rental Phones").replace(/\s/g, '') ||
                        family === ("Limited Extension Rental Phones").replace(/\s/g, '') ||
                        family === ("Common Rental Phones").replace(/\s/g, '') ||
                        family === ("Global Office - Limited Extension Rental Phones").replace(/\s/g, '')) &&
                    (!quote.Initial_Term_months__c || Number(quote.Initial_Term_months__c) < 24)) {
                    result = true;
                    break;
                }
            }
        }
        return result;
    },
    checkNotification_specialTerms: function(component) {
        var result = false;
        var quote = component.get("v.quote");
        var showSpecialTerms = component.get("v.showSpecialTerms");
        if ((quote && (typeof quote.Special_Terms__c === 'string') && (quote.Special_Terms__c.toLowerCase().indexOf('shipping') !== -1)) || showSpecialTerms) {
            result = true;
        }
        return result;
    },
    checkNotification_activeAgreementSpecialTerms: function(component) {
        var result = false;
        var quote = component.get("v.quote");
        if (quote && (quote.Special_Terms__c && quote.RecordType.Name !== 'Contact Center Quote' && (quote.Status !== 'Active' || quote.QuoteType__c !== 'Agreement'))) {
            result = true;
        }
        return result;
    },
    checkNotification_upsellDigitalLines: function(component) {
        var result = false;
        var quote = component.get('v.quote');
        var cartItems = component.get("v.cartItems");
        if (quote && quote.Upsell_Status__c === "Upsell" && Array.isArray(cartItems)) {
            for (var i = 0; i < cartItems.length; i++) {
                if (cartItems[i].Product2.Family == "Tier" || cartItems[i].Product2.Family == "Service") {
                    result = true;
                }
            }
        }
        return result;
    },
    /**
     * Show Pro Service Details message
     */
    checkNotification_proServDetails: function(component) {
        var quote = component.get('v.quote');
        return quote && quote.ProServ_Details__c;
    },
    /**
     * Show message when ProServ Quote has "In Progress" or "Created" status
     */
    checkNotification_proServInProgress: function(component) {
        var result = false;
        var quote = component.get('v.quote');
        var gspPartner = component.get('v.Wizard.config.old.settings.gspPartnerSetup');
        if (
            quote && !component.get('v.Wizard.opportunity.isChangeOrderOpportunity') &&
            (quote.ProServ_Status__c === QW.CONSTANTS.QUOTE.PROSERV_STATUS.IN_PROGRESS
                || quote.ProServ_Status__c === QW.CONSTANTS.QUOTE.PROSERV_STATUS.CREATED)
            && !(gspPartner !== null && gspPartner.isDisableCommercialQuoting === true)
        ) {
            result = true;
        }
        return result;
    },
    /**
     * Show  different vanity phone numbers and setup fees message
     */
    checkNotification_vanityPhonesQuantity: function(component){
        var quote = component.get('v.quote');
        return quote && quote.Invalid_Number_of_Vanity_Setups__c;
    },
    /**
     * Show different 800 toll-free phone numbers and setup fees message
     */
    checkNotification_800TollFreePhonesQuantity: function(component){
        var quote = component.get('v.quote');
        return quote && quote.Invalid_Number_of_800_Setups__c;
    },
    /**
     * Show  different international toll-free phone numbers and setup fees message
     */
    checkNotification_internationalTollFreePhonesQuantity: function(component){
        var quote = component.get('v.quote');
        return quote && quote.Invalid_Number_of_Int_TF_Setups__c;
    },
    /**
     * Show message that selected service plan will expire soon, tiers are no longer available for Upgrade
     */
    checkNotification_tiersUnavailable: function(component){
        var result = false;
        var quote = component.get('v.quote');
        var state = component.get('v.state');
        var settings = component.get('v.settings');
        if (quote
            && state.isSalesQuote
            && state.isNewCustomer
            && !quote.Pricebook2.IsActive
            && quote.Pricebook2.Service__c === "Office"
            && settings.tierId[quote.Pricebook2.Tier_ID__c]){
            result = true;
        }
        return result;
    },
    checkNotification_proServDifferentPB: function(component){
        var state = component.get('v.state');
        var quote = component.get('v.quote');
        return quote && state.isPrimaryQuotePriceBookPlanDiffers;
    },
    checkNotification_changesAreNotAllowedInAgreementStage: function(component){
        var result = false;
        var quote = component.get('v.quote');
        if(quote && quote.QuoteType__c === 'Agreement') {
            result = true;
        }
        return result;
    },
    checkNotification_discountDetails: function(component){
        var result = false;
        var quote = component.get("v.quote");
        var cartItems = component.get("v.cartItems");
        if (quote && Array.isArray(cartItems)) {
            for (var i = 0; i < cartItems.length; i++) {
                if(cartItems[i].Product2.Family.toLowerCase().indexOf('phones') !== -1 &&
                    cartItems[i].Product2.Sub_Category__c == 'Main' &&
                    cartItems[i].Discount_Value__c > 50 &&
                    Number(quote.Initial_Term_months__c) &&
                    quote.Upsell_Status__c === "New") {
                    result = true;
                    break;
                }
            }
        }
        return result;
    },
    /**
     * @see https://rc.my.salesforce.com/a2034000003VxxC B-3278 Fax Area code is not available in Google Service Plans
     */
    checkNotification_areaCodesNull: function(component){
        var quote = component.get('v.quote');
        var state = component.get('v.state');

        return quote
            && state.isNewCustomer
            && (!quote.AreaCode__c || !quote.FaxAreaCode__c )
            // Do not show on ProServ Quotes
            && !state.isCCProServQuote
            && !state.isProServQuote
            && !state.isCCQuote
            //
            && (!state.isQuoteHasGoogleServicePlan ||
                (state.isQuoteHasGoogleServicePlan && !state.isQuoteHasRingCentralOrCanadaServicePlan));
    },
    /**
     * @see https://rc.my.salesforce.com/a2034000003VxxC B-3278 Fax Area code is not available in Google Service Plans
     */
    checkNotification_mainAreaCodeIsNull: function(component){
    var quote = component.get('v.quote');
    var state = component.get('v.state');

    return quote
        && state.isNewCustomer
        && !quote.AreaCode__c
        // Do not show on ProServ Quotes
        && !state.isCCProServQuote
        && !state.isProServQuote
        //
        && state.isQuoteHasGoogleServicePlan && state.isQuoteHasRingCentralOrCanadaServicePlan;
    },
    /**
     * @see https://rc.my.salesforce.com/a2034000003VZkj B-3202 Info Messages for Contact Center Seats
     */
    checkNotification_ccSeatsAdvanced: function(component){
        var CONTACT_CENTER = component.get('v.settings.CONTACT_CENTER');
        var quote = component.get('v.quote');
        var cartItems = component.get("v.cartItems");

        return quote && cartItems.some(function(cartItem){
            return cartItem.Product2.Sub_Category__c === CONTACT_CENTER
                &&  cartItem.Product2.Edition__c === 'Advanced-Plus';
        })
    },
    /**
     * @see https://rc.my.salesforce.com/a2034000003VZkj B-3202 Info Messages for Contact Center Seats
     */
    checkNotification_ccSeatsUltimate: function(component){
        var CONTACT_CENTER = component.get('v.settings.CONTACT_CENTER');
        var quote = component.get('v.quote');
        var cartItems = component.get("v.cartItems");

        return quote && cartItems.some(function(cartItem){
            return cartItem.Product2.Sub_Category__c === CONTACT_CENTER
                &&  cartItem.Product2.Edition__c === 'Ultimate-Plus';
        })
    },
    checkNotification_ccAmeliaVoiceNoTTS: function(component){
        var CONTACT_CENTER = component.get('v.settings.CONTACT_CENTER');
        var quote = component.get('v.quote');
        var cartItems = component.get("v.cartItems");
        var hasAmeliaVoiceBundle = cartItems.some(function(cartItem) {
            return cartItem.Product2.Sub_Category__c === CONTACT_CENTER
                && cartItem.Product2.Product_Type__c === 'Calls Bundle'
                && cartItem.Product2.Family == 'Add - Ons'
                && cartItem.Product2.Name.includes('Amelia Voice')
        });
        var hasAmeliaTTS = cartItems.some(function(cartItem) {
            return cartItem.Product2.Sub_Category__c === CONTACT_CENTER
                && cartItem.Product2.Family == 'Add - Ons'
                && cartItem.Product2.Name.includes('Amelia Transcription & TTS Service');
        });
        return quote && hasAmeliaVoiceBundle && !hasAmeliaTTS;
    },
    checkNotification_ccAmeliaTTSNoVoice: function(component){
        var CONTACT_CENTER = component.get('v.settings.CONTACT_CENTER');
        var quote = component.get('v.quote');
        var cartItems = component.get("v.cartItems");
        var hasAmeliaVoiceBundle = cartItems.some(function(cartItem) {
            return cartItem.Product2.Sub_Category__c === CONTACT_CENTER
                && cartItem.Product2.Product_Type__c === 'Calls Bundle'
                && cartItem.Product2.Family == 'Add - Ons'
                && cartItem.Product2.Name.includes('Amelia Voice')
        });
        var hasAmeliaTTS = cartItems.some(function(cartItem) {
            return cartItem.Product2.Sub_Category__c === CONTACT_CENTER
                && cartItem.Product2.Family == 'Add - Ons'
                && cartItem.Product2.Name.includes('Amelia Transcription & TTS Service');
        });
        return quote && !hasAmeliaVoiceBundle && hasAmeliaTTS;
    },
    checkNotification_ccTextelShortCodeNoMonthly: function(component){
        var CONTACT_CENTER = component.get('v.settings.CONTACT_CENTER');
        var quote = component.get('v.quote');
        var cartItems = component.get("v.cartItems");
        var hasShortCode = cartItems.some(function(cartItem) {
            return cartItem.Product2.Sub_Category__c === CONTACT_CENTER
                && cartItem.Product2.Family == 'Add - Ons'
                && cartItem.Product2.Name.includes('Textel - Short Code - ');
        });
        var hasShortCodeMonthly = cartItems.some(function(cartItem) {
            return cartItem.Product2.Sub_Category__c === CONTACT_CENTER
                && cartItem.Product2.Family == 'Add - Ons'
                && cartItem.Product2.Name.includes('Textel - Short Code Monthly');
        });
        return quote && ((hasShortCode && !hasShortCodeMonthly) || (!hasShortCode && hasShortCodeMonthly));
    },
    checkNotification_ccTextelLongCodeNoTierInternational: function(component){
        var CONTACT_CENTER = component.get('v.settings.CONTACT_CENTER');
        var quote = component.get('v.quote');
        var cartItems = component.get("v.cartItems");
        var hasLongCode = cartItems.some(function(cartItem) {
            return cartItem.Product2.Sub_Category__c === CONTACT_CENTER
                && cartItem.Product2.Family == 'Add - Ons'
                && cartItem.Product2.Name === 'Contact Center: Textel - Long Code';
        });
        var hasLongCodeTier = cartItems.some(function(cartItem) {
            return cartItem.Product2.Sub_Category__c === CONTACT_CENTER
                && cartItem.Product2.Family == 'Add - Ons'
                && cartItem.Product2.Name.includes('Textel - Long Code - Tier');
        });
        return quote && ((hasLongCode && !hasLongCodeTier) || (!hasLongCode && hasLongCodeTier));
    },
    checkNotification_engagementCancelled: function(component){
        return component.get('v.state.isEngagementCancelled');
    },
    checkNotification_invalidGlobalOfficeLimiteExtensionPhonesQuantity: function(component) {
        var result = false;
        var quote = component.get("v.quote");
        if (quote && quote.Invalid_GO_LE_Phones_Quantity__c === true) {
            result = true;
        }
        return result;
    },

    /**
     * B-3758 ProServ Phase management on Quote Enhancements
     * https://rc.my.salesforce.com/a20340000047LSz
     */
    checkNotification_emptyPhases: function( component ){
        return component.get('v.Wizard.currentQuote.isHasEmptyPhases');
    },

    /**
     * B-3758 ProServ Phase management on Quote Enhancements
     * https://rc.my.salesforce.com/a20340000047LSz
     */
    checkNotification_assignAllPhaseLineItems: function( component ){
        return component.get('v.Wizard.currentQuote.isPhaseLineItemsUnassigned');
    },
    /**
     *On chenge order opportunity, to generate orders need to mark quote as sold
     * */
    checkNotification_proservSoldRequired: function( component ){
        return (!component.get('v.Wizard.currentQuote.isSold') && component.get('v.Wizard.opportunity.isChangeOrderOpportunity'));
    },
    /**
     *Need to match account and quote billing addresses
     * */
    checkNotification_wrongBillingAddress: function( component ){
        var state = component.get('v.state');
        return (component.get('v.Wizard.currentQuote.isWrongBillingAddress')
                && !state.isCCProServQuote
                && !state.isProServQuote);
    },
});