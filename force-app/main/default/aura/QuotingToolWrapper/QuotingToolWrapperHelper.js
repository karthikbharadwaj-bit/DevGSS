/* globals QW, console */
({
    /**
     * @fires QuotingToolModalResponseEvent
     * @param component {object}  Aura Component
     * @param result    {boolean} user clicks ok or cancel
     */
    hideModal: function(component, result) {
        var sourceId = component.get("v.modalSource");
        var action = component.get("v.modalAction");
        var params = component.get("v.modalParams");
        var prms = {
            sourceId: sourceId,
            action: action,
            modalResult: result,
            params: params
        };

        $A.util.removeClass(component.find('modalBg'), 'slds-backdrop--open');
        $A.util.removeClass(component.find('modal'), 'slds-fade-in-open');
        $A.util.addClass(component.find('modal'), 'slds-hide');

        component.set("v.modalAction", null);
        component.set("v.modalSource", null);
        component.set("v.modalText", null);

        $A.get("e.c:QuotingToolModalResponseEvent").setParams(prms).fire();
    },
    /**
     * DO NOT USE
     * @deprecated use v.Wizard attribute instead
     */
    quoteState: function(component){
        var Wizard = component.get('v.Wizard');
        var isCC = component.get('v.isCC');
        var settings = component.get('v.settings');
        var quote = component.get('v.quote');
        var stageName = component.get('v.stageName');
        var products = component.get('v.products');
        var user = component.get('v.user');
        var cartItems = component.get('v.cartItems');
        var quotes = component.get('v.quotes');
        var activePriceBookEntry = component.get('v.activePriceBookEntry');
        var selectedPriceBookEntry = component.get('v.selectedPriceBookEntry');
        var addingToCartProds = component.get('v.addingToCartProds');
        var upsellStatus = component.get('v.upsellStatus');
        var isBilling = component.get('v.config.wizard.isBilling');

        var state = component.get('v.state');

        var ccQuote = null;

        if (Wizard.quotes) {
            ccQuote = Wizard.quotes.find(function(quote) {
                return quote.isCC;
            });
        }

        state.isUserProServ = false;
        state.isUserCCProServ = false;
        state.isUserSysAdmin = false;
        state.isUserRelayware = false;
        state.isUserSHouldNotSeeCCProServEngage = false;
        state.isUserProServWithoutSupportDirector = false;

        if(user) {
            if (settings.sysAdminProfileId && settings.sysAdminProfileId === user.ProfileId) {

                // User is SysAdmin
                state.isUserSysAdmin = true;

            }
            if (settings.PROSERV_PROFILES && settings.PROSERV_PROFILES.indexOf(user.Profile.Name) > -1) {

                // User is ProServ
                state.isUserProServ = true;

            }
            if (settings.CC_PROSERV_PROFILES && settings.CC_PROSERV_PROFILES.indexOf(user.Profile.Name) > -1){

                // User is CC ProServ
                state.isUserCCProServ = true;

            }
            if (settings.PROSERV_PROFILES_WITHOUT_SUPPORT_DIRECTOR && settings.PROSERV_PROFILES_WITHOUT_SUPPORT_DIRECTOR.indexOf(user.Profile.Name) > -1){

                // User is ProServ without Support Director
                state.isUserProServWithoutSupportDirector = true;

            }

            if (user.Profile && user.Profile.Name === settings.relaywareProfileName){

                // User is Relayware user
                state.isUserRelayware = true;

            }

            if (settings.CC_PROSERV_NOT_SHOW_PROFILES && settings.CC_PROSERV_NOT_SHOW_PROFILES.indexOf(user.Profile.Name) > -1) {

                // User is Relayware user
                state.isUserSHouldNotSeeCCProServEngage = true;

            }
        }

        // Opportunity stage is Downgraded
        state.isDowngraded = stageName === '0. Downgraded';

        // Vanity Numbers allowed
        var vanityBrands = ['RingCentral', 'RingCentral Canada'];
        state.isVanityNumbersAllowed =  activePriceBookEntry &&
                                        vanityBrands.indexOf(activePriceBookEntry.Pricebook2.Brand__r.Name) > -1;

        state.isUserSelectedDifferentServicePlan = selectedPriceBookEntry
            && (!quote || quote.Pricebook2Id !== selectedPriceBookEntry.Pricebook2Id);

        state.isQuoteOnApproval = false;
        state.isQuoteRequiresApproval = false;
        state.isProServQuote = false;
        state.isCCProServQuote = false;
        state.isCCQuote = false;
        state.isActiveAgreement = false;
        state.isAgreement = false;
        state.isPrimaryQuotePriceBookPlanDiffers = false;
        state.isProServInCart = false;
        state.isCCProServInCart = false;
        state.isAreaCodesAvailableInCart = false;
        state.isTaxesInCart = false;
        state.isActiveSeatOnAccountOrQuote = false;
        state.isCatIdInCart = false;
        state.isCommonPhoneIsAddingToCart = false;
        state.isCcEEsProductIsAddingToCart = false;
        state.isMonthlyPlan = false;
        state.isPrimaryQuoteHaveContactCenter = false;
        state.isProServCancelled = false;
        state.isCCProServCancelled = false;
        state.isEngagementCancelled = false;
        state.isProServSyncRequired = false;
        state.isCCProServSyncRequired = false;
        state.isCCProServEngagementRequired = false;
        state.isUserHavePermissionToEditQuote = false;
        state.isQuoteHaveContactCenter = false;
        state.isQuoteHasTaxes = false;
        state.isIvinexUnifiedUserExperienceProductAddedToCart = false;

        // Quote Upsell Status
        state.isNewCustomer = upsellStatus === settings.QUOTE_NEW_CUSTOMER_STATUS;
        state.isUpsell = upsellStatus === settings.QUOTE_UPSELL_STATUS;
        state.isUpgrade = upsellStatus === settings.QUOTE_UPGRADE_STATUS;

        if (quote) {
            //User is Opportunity Owner
            state.isUserOpportunityOwner = quote.Opportunity_Owner__c === user.Id.substring(0, 15);

            //User is Quote Creator
            state.isUserQuoteCreator = quote.CreatedBy.Id === user.Id;

            // Quote is on Approval
            if(settings.PENDING_APPROVAL_STATUSES.indexOf(quote.Approved_Status__c) > -1){
                state.isQuoteOnApproval = true;

                // Primary Quote is on Approval
                if (quote.isPrimary__c) {
                    state.isPrimaryQuoteOnApproval = true;
                }
            } else {
                if (quote.isPrimary__c) {
                    state.isPrimaryQuoteOnApproval = false;
                }
            }

            // Quote Requires Approval
            state.isQuoteRequiresApproval = settings.PRE_APPROVAL_STATUSES.indexOf(quote.Approved_Status__c) > -1;

            // Quote Record Type
            state.isProServQuote =
                quote.RecordTypeId === settings.QUOTE_RT_INFO_BY_NAME[settings.PROSERV_QUOTE_RT_NAME].recordTypeId;
            state.isCCProServQuote =
                quote.RecordTypeId === settings.QUOTE_RT_INFO_BY_NAME[settings.CC_PROSERV_QUOTE_RT_NAME].recordTypeId;
            state.isSalesQuote = !quote.RecordType ||
                quote.RecordTypeId === settings.QUOTE_RT_INFO_BY_NAME[settings.SALES_QUOTE_RT_NAME].recordTypeId;
            state.isCCQuote =
                quote.RecordTypeId === settings.QUOTE_RT_INFO_BY_NAME[settings.CC_QUOTE_RT_NAME].recordTypeId;

            // Quote is on Active Agreement
            state.isActiveAgreement = quote.QuoteType__c === 'Agreement' && quote.Status === 'Active';

            state.isAgreement = quote.QuoteType__c === 'Agreement';

            state.isQuoteHasMonthlyServicePlan = quote.Pricebook2.Plan__c === "Monthly";
            state.isQuoteHasGoogleServicePlan = quote.Pricebook2.Edition__c === settings.GOOGLE_APPS_EDITION;

            const brandName = quote.Pricebook2.Brand__r && quote.Pricebook2.Brand__r.Name;
            state.isQuoteHasRingCentralOrCanadaServicePlan = [
                settings.RINGCENTRAL_BRAND_NAME,
                settings.RINGCENTRAL_CANADA_BRAND_NAME
            ].includes(brandName);

            // Permissions
            state.isUserHavePermissionToEditQuote =
                // User have permission to edit Sales Quote
                (state.isSalesQuote && settings.userPermissions.EditSalesQuote) ||
                // User have permission to edit ProServ Sales Quote
                (state.isProServQuote && settings.userPermissions.EditProServQuote) ||
                // User have permission to edit ProServ Sales Quote
                (state.isCCProServQuote && settings.userPermissions.EditCCProServQuote) ||
                // User have permission to edit Contact Center Quote
                (state.isCCQuote && settings.userPermissions.EditSalesQuote);

            state.isUserHasPermissionToGeneratePDF =
                // User have permission to Generate PDF on Sales Quote
                (state.isSalesQuote && settings.userPermissions.GeneratePDFSales) ||
                // User have permission to Generate PDF on ProServ Sales Quote
                (state.isProServQuote && settings.userPermissions.GeneratePDFProServ) ||
                // User have permission to Generate PDF on CC ProServ Sales Quote
                (state.isCCProServQuote && settings.userPermissions.GeneratePDFCCProServ) ||
                // User have permission to Generate PDF on Contact Center Quote
                (state.isCCQuote && settings.userPermissions.GeneratePDFSales);

            // have Contact Center in cart
            state.isQuoteHaveContactCenter = quote.Products__c && settings.CC_CATEGORIES.some(category => quote.Products__c.includes(category));

            // Checks on product list
            if (Array.isArray(products)) {

                if(quote.isPrimary__c){
                    state.isProServProductsOnPrimaryQuote = false;
                    state.isCCProServProductsOnPrimaryQuote = false;
                }
                 else if (Wizard.currentQuote && Wizard.currentQuote.isCC) {
                    state.isCCProServProductsOnCCQuote = false;
                }

                products.forEach(function(product){
                    // Primary Quote has ProServ Products
                    if(quote.isPrimary__c && product.Product2.Sub_Category__c === settings.PROSERV_PRODUCT_SUBCATEGORY){
                        state.isProServProductsOnPrimaryQuote = true;
                    }

                    /* Primary Quote has CC ProServ Products */
                    if(quote.isPrimary__c && settings.CC_CATEGORIES.indexOf(product.Product2.Sub_Category__c) !== -1) {
                        state.isCCProServProductsOnPrimaryQuote = true;
                    }

                    if(Wizard.currentQuote && ccQuote && settings.CC_CATEGORIES.indexOf(product.Product2.Sub_Category__c) !== -1) {
                        state.isCCProServProductsOnCCQuote = true;
                    }

                    // Common Phone is in process of adding to cart
                    if (addingToCartProds && addingToCartProds.has(product.Product2Id)
                        && product.Product2.Family === 'Common Phones'){
                        state.isCommonPhoneIsAddingToCart = true;
                    }

                    if (addingToCartProds && addingToCartProds.has(product.Product2Id)
                        && product.Product2.Feature__c === 69){
                        state.isCcEEsProductIsAddingToCart = true;
                    }

                    if (addingToCartProds && addingToCartProds.has(product.Product2Id)
                        && (product.Product2.CatID__c == QW.CONSTANTS.PRODUCT2.CAT_ID.IVINEX_UNIFIED_USER_EXPERIENCE_PER_CONCURRENT_USER
                        || product.Product2.CatID__c == QW.CONSTANTS.PRODUCT2.CAT_ID.IVINEX_UNIFIED_USER_EXPERIENCE_PER_CONFIGURED_USER)) {
                            state.isIvinexUnifiedUserExperienceProductAddedToCart = true;
                    }
                });
            }

            // Checks on Cart List
            if(Array.isArray(cartItems)){
                cartItems.forEach(function(cartItem){

                    //There is at least one ProServ product in cart
                    if (cartItem.Product2.Sub_Category__c === settings.PROSERV_PRODUCT_SUBCATEGORY) {
                        state.isProServInCart = true;
                    }

                    //There is at least one CC ProServ product in cart
                    if (cartItem.Product2.Sub_Category__c === settings.CC_PROSERV_PRODUCT_SUBCATEGORY) {
                        state.isCCProServInCart = true;
                    }

                    // Is there is at least one product in cart that can have Area Codes
                    if (settings.areaCodesFeatures.includes(cartItem.Product2.Feature__c) ||
                        settings.areaCodesFamilies.includes(cartItem.Product2.Family)){
                        state.isAreaCodesAvailableInCart = true;
                    }

                    // Taxes in cart
                    if (cartItem.Product2.Family === "Taxes"){
                        state.isTaxesInCart = true;
                    }

                    // Active seats on the Account or Quote
                    if (cartItem.Product_Type__c
                        && cartItem.Product_Type__c === "seat"
                        && cartItem.Product2.Family !== "Overage"
                        && cartItem.Deactivated__c){
                        state.isActiveSeatOnAccountOrQuote = true;
                    }

                    // There is at least one product with populated CatID in cart
                    if(cartItem.Product2.CatID__c){
                        state.isCatIdInCart = true;
                    }
                    //There is at least one product with taxes family in the cart
                    if(cartItem.Product2.Family === 'Taxes') {
                        state.isQuoteHasTaxes = true;
                    }

                    if (cartItem.Product2.CatID__c == QW.CONSTANTS.PRODUCT2.CAT_ID.IVINEX_UNIFIED_USER_EXPERIENCE_PER_CONCURRENT_USER
                        || cartItem.Product2.CatID__c == QW.CONSTANTS.PRODUCT2.CAT_ID.IVINEX_UNIFIED_USER_EXPERIENCE_PER_CONFIGURED_USER) {
                            state.isIvinexUnifiedUserExperienceProductAddedToCart = true;
                    }
                });
            }

            // Checks On Quotes
            var ccPrimaryQuoteExist = false;
            if(Array.isArray(quotes)){
                quotes.forEach(function(q){

                    // ProServ Quote
                    if (q.RecordTypeId === settings.QUOTE_RT_INFO_BY_NAME[settings.PROSERV_QUOTE_RT_NAME].recordTypeId){

                        // is ProServ Quote has been cancelled
                        state.isProServCancelled = q.ProServ_Status__c === 'Cancelled';

                        // if it is required to sync ProServ Quote
                        state.isProServSyncRequired = !state.isProServCancelled
                            && q.ProServ_Status__c !== 'Synced';

                    }
                    if (q.RecordTypeId === settings.QUOTE_RT_INFO_BY_NAME[settings.CC_PROSERV_QUOTE_RT_NAME].recordTypeId){
                        ccPrimaryQuoteExist = true;

                        // is CC ProServ Quote has been cancelled
                        state.isCCProServCancelled = q.ProServ_Status__c === 'Cancelled';

                        // if it is required to sync CC ProServ Quote
                        state.isCCProServSyncRequired = settings.featureToggle.Engage_CC_ProServ__c &&
                            !state.isCCProServCancelled && q.ProServ_Status__c !== 'Synced';
                    }

                    // Primary Quote
                    if (q.isPrimary__c){

                        // have Contact Center in cart
                        state.isPrimaryQuoteHaveContactCenter = q.Products__c && q.Products__c.includes(settings.CONTACT_CENTER);

                        // Status is Draft?
                        state.isPrimaryIsDraft = q.Status == 'Draft';

                        // In Agreement stage
                        state.isPrimaryIsAgreement = q.QuoteType__c === 'Agreement';
                    }
                });
            }

            // Only applicable for proServ Quotes if it was cancelled
            state.isEngagementCancelled = (state.isProServQuote && state.isProServCancelled)
                || (state.isCCProServQuote && state.isCCProServCancelled);


            // If (CC) ProServ Engagement is required to sign up or change to agreement status
            state.isCCProServEngagementRequired = settings.featureToggle.Engage_CC_ProServ__c
                && state.isPrimaryQuoteHaveContactCenter && !ccPrimaryQuoteExist;

        }

        if(!isBilling && Wizard.primaryQuote) {
            Wizard.primaryQuote.cartItems.forEach(item => {
                let subCategory = item.record.Product2.Sub_Category__c;

                /* Primary Quote has CC ProServ Products */
                if(settings.CC_CATEGORIES.indexOf(subCategory) !== -1) {
                    state.isCCProServProductsOnPrimaryQuote = true;
                }
            });
        }
        if (isBilling && ccQuote) {
            ccQuote.cartItems.forEach(item => {
                let subCategory = item.record.Product2.Sub_Category__c;

                /* CC Quote has CC Products in Cart */
                if(settings.CC_CATEGORIES.indexOf(subCategory) !== -1) {
                    state.isCCProServProductsOnCCQuote = true;
                }
            });
        }

        component.set('v.state',state);
    },
    /**
     * Get ProServ and CC ProServ Quotes
     */
    getProServQuote: function(component){
        var quotes = component.get('v.quotes');
        var settings = component.get('v.settings');
        var proServQuote = null,
            ccProServQuote = null,
            primaryQuote = null;

        if (Array.isArray(quotes)) {
            quotes.forEach(function(quote){
                if (quote.RecordTypeId === settings.QUOTE_RT_INFO_BY_NAME[settings.PROSERV_QUOTE_RT_NAME].recordTypeId) {
                    proServQuote = quote;
                }
                if (quote.RecordTypeId === settings.QUOTE_RT_INFO_BY_NAME[settings.CC_PROSERV_QUOTE_RT_NAME].recordTypeId) {
                    ccProServQuote = quote;
                }
                if (quote.RecordTypeId === settings.QUOTE_RT_INFO_BY_NAME[settings.SALES_QUOTE_RT_NAME].recordTypeId
                    && quote.isPrimary__c) {
                    primaryQuote = quote;
                }
            });
        }

        component.set('v.proServQuote', proServQuote);
        component.set('v.ccProServQuote', ccProServQuote);
        component.set('v.primaryQuote', primaryQuote);
    },
    /**
     * Detect upsell Status
     * Take into account if Upgrade button was pressed
     */
    setUpsellStatus: function(component){
        const defaultUpsellStatus = component.get('v.defaultUpsellStatus');
        const quote = component.get('v.quote');
        const isUpgradeClicked = component.get('v.isUpgradeClicked');
        const accountServicePlanEnt = component.get('v.accountServicePlanEnt');
        const isEntitlementUpsellInabled =
          component.get('v.Wizard.settings.featureToggle.Opportunity_Creation_Entitlement_Based__c');
        const entitlements = component.get('v.entitlements');
        const isCC = component.get('v.isCC');
        var upsellStatus;

        const isUpsellRequired = !isCC && accountServicePlanEnt && isEntitlementUpsellInabled
            || isCC && this.isCCEntitlementsExist(entitlements);

        if (isUpgradeClicked) {
            upsellStatus = QW.CONSTANTS.QUOTE.UPSELL_STATUS.UPGRADE.VALUE;
        } else if (quote) {
            upsellStatus = quote.Upsell_Status__c;
        } else if (isUpsellRequired) {
            upsellStatus = QW.CONSTANTS.QUOTE.UPSELL_STATUS.UPSELL.VALUE;
        } else {
            upsellStatus = defaultUpsellStatus;
        }

        component.set('v.upsellStatus', upsellStatus);
    },
    /**
     * Detect Quote Record Type Name
     * We assume that old quotes with Record Type = null are Sales Quotes
     */
    setQuoteRecordTypeName: function(component){
        var quote = component.get('v.quote');
        var settings = component.get('v.settings');

        var quoteRecordTypeName = null;
        if (quote){
            quoteRecordTypeName = !quote.RecordType ? settings.SALES_QUOTE_RT_NAME : quote.RecordType.Name;
        }
        component.set('v.quoteRecordTypeName',quoteRecordTypeName);
    },
        /**
     * Set filtered special terms values for selected quote depends on Upsell_status__c
     */
    setQuoteSpecialTerms: function(component) {
        const quote = component.get('v.quote');
        const Wizard = component.get('v.Wizard');

        if (quote) {
            _.forEach(Wizard.quotes, (q) => {
               if (q.record.Id === quote.Id) {
                   component.set('v.specialTermsValues', q.specialTermsValues);
               }
            });
            if(
                Wizard.currentQuote
                && Wizard.currentQuote.record.isPrimary__c
                && component.find('QuotingToolQuoteSummary')
            ) {
                component.find('QuotingToolQuoteSummary').set('v.specialTerms', '');
                component.find('QuotingToolQuoteSummary').refreshQuoteSummaryTabInputValues();
            };
        }
    },

    /**
     * Show banner on top of the quoting wizard about coming catalog changes
     */
    pricingChanges: function(component){
        var Wizard = component.get('v.Wizard');

        var isPricingChangesBannerShown = Wizard.currentQuote
            &&  Wizard.currentQuote.isNewCustomer
            && !(Wizard.primaryQuote
                && Wizard.primaryQuote.isUpsell
                && Wizard.currentQuote.isCCorProServ)
            &&  Wizard.currentQuote.record.Pricebook2.Service__c === RC.CONSTANTS.PRICEBOOK2.SERVICE.OFFICE
            && !Wizard.settings.tierId[Wizard.currentQuote.record.Pricebook2.Tier_ID__c];

        RC.cssUtils.toggleShow(component, 'pricingChanges', isPricingChangesBannerShown);
    },

    servicePlanDeactivated: function(component){
        var Wizard = component.get('v.Wizard');

        var isServicePlanDeactivatedBannerShown = Wizard.currentQuote
            &&  Wizard.currentQuote.isUpgrade
            && !(Wizard.primaryQuote
                && Wizard.primaryQuote.isUpsell
                && Wizard.currentQuote.isCCorProServ)
            && !Wizard.currentQuote.record.Pricebook2.IsActive
            &&  Wizard.currentQuote.record.Pricebook2.Service__c === RC.CONSTANTS.PRICEBOOK2.SERVICE.OFFICE
            && !Wizard.settings.tierId[Wizard.currentQuote.record.Pricebook2.Tier_ID__c]
            && Wizard.billingPackage != null 
            && Wizard.currentQuote.record.Pricebook2.Tier_ID__c != Wizard.billingPackage.RC_Tier_ID__c;

        RC.cssUtils.toggleShow(component, 'servicePlanDeactivated', isServicePlanDeactivatedBannerShown);
    },

    /**
     * Show banner on top of the quoting wizard that quote is invalid
     */
    quoteIsInvalid: function(component){
        var Wizard = component.get('v.Wizard');
        var quote = component.get('v.quote');

        const quoteCheckboxInvalid = Wizard.currentQuote && Wizard.currentQuote.isInvalid;
        var isQuoteInvalid = quoteCheckboxInvalid
            || quote
                && quote.Account
                && quote.Account.RC_User_ID__c
                && quote.isNewCustomer;
        const isNeedToMigrate = quoteCheckboxInvalid
                && quote.Account
                && quote.Account.Billing_ID__c
                && quote.Account.Billing_System__c == 'NBS';

        RC.cssUtils.toggleShow(component, 'quoteIsInvalid', isQuoteInvalid);

        if (isNeedToMigrate) {
            $A.util.addClass(component.find('backdrop'), 'slds-backdrop_open');
            const position = `position: absolute;`;
            const opacity = `opacity: 0.6;`;
            const style = `${position}${opacity}`;
            component.set('v.migrateBackdropStyle', style);
            component.set('v.invalidQuoteInfo', QW.CONSTANTS.OPPORTUNITY.INVALID_INFO.INVALID_WIZARD);
        } else {
            component.set('v.invalidQuoteInfo', QW.CONSTANTS.OPPORTUNITY.INVALID_INFO.INVALID_QUOTE);
        }
    },

    checkCriticalNotifications: function(component) {
        var settings = component.get('v.settings');
        var quote = component.get('v.quote');
        var criticalNotifications = [];
        var isShow = quote && !quote.Account.RC_User_ID__c && this.isSignUpRestricted(quote, settings.customSettings.ngbsSignUpRestrictions);

        RC.cssUtils.toggleShow(component, 'critical-notifications', isShow);
        if (isShow) {
            var text = `Sign Up of ${quote.Pricebook2.Brand__r.Name} ${quote.Pricebook2.Service__c} Service into Legacy billing system is not allowed. Please Create New NGBS Opportunity to sign this customer up into NGBS.`;
            criticalNotifications.push(text);
        }

        component.set('v.criticalNotifications', criticalNotifications);
    },

    isSignUpRestricted: function(quote, ngbsSignUpRestrictions) {
        if (!quote || !ngbsSignUpRestrictions) return;
        var result = false;

        try {
            var brand = quote.Pricebook2 && quote.Pricebook2.Brand__r && quote.Pricebook2.Brand__r.Name;
                brand = brand && brand.toLowerCase();
            var service = quote.Pricebook2 && quote.Pricebook2.Service__c;
                service = service && service.toLowerCase();
            result = _.some(ngbsSignUpRestrictions, (setting) => {
                // setting.Brand__c is required field
                var isMatchBrand = setting.Brand__c.toLowerCase() === brand;
                var isMatchService = setting.Services__c && setting.Services__c
                    .split(';')
                    .map(item => item.trim())
                    .map(item => item.toLowerCase())
                    .includes(service);
                return isMatchBrand && isMatchService;
            });
        } catch (e) {
            console.error(e);
        }

        return result;
    },

    /**
     * Show global Spinner
     * @param [text] {string} caption to show under spinner
     */
    showSpinner: function(text){
        var params = { value: true };
        if(text) params.text = text;
        $A.get('e.c:SpinnerEvent')
            .setParams(params)
            .fire();
    },
    /**
     * Hide global Spinner
     */
    hideSpinner: function(){
        $A.get('e.c:SpinnerEvent')
            .setParams({ value: false })
            .fire();
    },

    navigate: function(component, targetTabName){
        let Tabs = component.get('v.Tabs');

        Tabs.openByName(targetTabName);

        component.set('v.Tabs', Tabs);
    },
    /**
     * 1) Delete Phases
     * 2) Switch Service Plan
     */
    switchServicePlan: function(component, pricebook2Id){
        this.deleteAllPhases(component)
            .then($A.getCallback(function () {
                return component.find('QuotingToolTierList').switchServicePlan(pricebook2Id);
            }));
    },

    /**
     * Delete All phases from quote
     * @returns {Promise}
     */
    deleteAllPhases: function(component){
        var phases = component.get('v.Wizard.currentQuote.phases');
        if (phases.length === 0) return Promise.resolve();

        var phaseIdsToDelete = phases.map(function (phase) {
            return phase.record.Id;
        });
        return component.find('QuotingToolPhaseManagement').deletePhases(phaseIdsToDelete);
    },

    /**
     * 1) Delete Phase Line Item
     * 2) Delete Cart Item
     */
    deletePLIsBeforeCartItemDelete: function(component, phaseLineItemIdsToDelete, quoteLineItemToDelete){
        var promise = component.find('QuotingToolPhaseManagement').deletePhaseLineItems(phaseLineItemIdsToDelete);
        if (promise) {
            promise.then($A.getCallback(function () {
                component.find('QuotingToolCartList').deleteCartItem(quoteLineItemToDelete);
            }))
        }
    },

    /**
     * 1) Delete Phase Line Items
     * 2) Save Cart
     */
    deletePLIsBeforeCartSave: function(component, phaseLineItemIdsToDelete){
        var promise = component.find('QuotingToolPhaseManagement').deletePhaseLineItems(phaseLineItemIdsToDelete);
        if (promise) {
            promise.then($A.getCallback(function () {
                return component.find('QuotingToolCartList').save();
            }))
        }
    },

    /**
     * 1) Delete Phases
     * 2) Delete Quote
     */
    deleteQuote: function(component, quoteId){
        this.deleteAllPhases(component)
            .then($A.getCallback(function () {
                $A.get("e.c:QuotingToolDeleteQuoteEvent").setParams({ quoteId: quoteId }).fire();
            }));
    },

    createTabs: function(component){
        let Tabs = new QW.Tabs();
        let helper = this;
        let modalSaveChangesButtons = [{
            name: 'discard',
            label: 'Discard',
            variant: 'neutral'
        }, {
            name: 'save',
            label: 'Save changes',
            variant: 'brand'
        }];

        //Service Plans
        Tabs.addTab('servicePlans');
        Tabs.servicePlans.label = 'Service Plans';
        Tabs.servicePlans.onOpenCallback = function () {
            component.find('QuotingToolTierList').tabIsActive();
        };

        // Products
        Tabs.addTab('products');
        Tabs.products.label = 'Products';
        Tabs.products.onOpenCallback = function () {
            component.find('QuotingToolProductList').tabIsActive();
        };

        // Cart
        Tabs.addTab('cart');
        Tabs.cart.label = 'Cart (0)';
        Tabs.cart.onLeaveCallback = function(targetTab) {
            if (component.get("v.isCartChanged")){
                $A.get("e.c:ModalRequestEvent").setParams({
                    guid: 'goFromCart',
                    header: 'Save Cart?',
                    content: 'You have unsaved items in the Cart. Do you want to save them?',
                    buttons: modalSaveChangesButtons
                }).fire();
                helper.targetTabName = targetTab.name;
                return false;
            }
        };

        // Phases
        Tabs.addTab('phases');
        Tabs.phases.label = 'Phases (0)';
        Tabs.phases.onLeaveCallback = function(targetTab){
            if (component.get("v.isPhasesChanged")){
                $A.get("e.c:ModalRequestEvent").setParams({
                    guid: 'goFromPhases',
                    header: 'Save Phases?',
                    content: 'You have unsaved changes in Phases and/or Phase Line Items. Do you want to save them?',
                    buttons: modalSaveChangesButtons
                }).fire();
                helper.targetTabName = targetTab.name;
                return false;
            }
        };

        //Summary
        Tabs.addTab('summary');
        Tabs.summary.label = 'Quote';
        Tabs.summary.onLeaveCallback = function(targetTab){
            if (component.get("v.isSummaryChanged")){
                $A.get("e.c:ModalRequestEvent").setParams({
                    guid: 'goFromSummary',
                    header: 'Save Quote?',
                    content: 'You have unsaved changes in the Quote. Do you want to save them?',
                    buttons: modalSaveChangesButtons
                }).fire();
                helper.targetTabName = targetTab.name;
                return false;
            }
        };

        component.set('v.Tabs', Tabs);
    },

    updateTabs: function(component){
        var Tabs = component.get('v.Tabs');
        var Wizard = component.get('v.Wizard');
        var isCC = component.get('v.isCC');

        // Service Plans
        Tabs.servicePlans.isVisible = !(Wizard.currentQuote && Wizard.currentQuote.isCCorProServ);
        Tabs.servicePlans.isDisabled = false;

        // Products
        Tabs.products.isVisible = true;
        Tabs.products.isDisabled = !Wizard.currentQuote;

        // Cart
        Tabs.cart.isVisible = true;
        Tabs.cart.isDisabled = !Wizard.currentQuote;

        // Phases
        Tabs.phases.isVisible = Wizard.currentQuote && Wizard.currentQuote.isPhaseManagementEnabled;
        Tabs.phases.isDisabled = false;
        Tabs.phases.label = Tabs.phases.isVisible && `Phase (${Wizard.currentQuote.phases.length})`;

        //Summary
        Tabs.summary.isVisible = !isCC;
        Tabs.summary.isDisabled = !Wizard.currentQuote;
        Tabs.summary.label = Wizard.currentQuote && Wizard.currentQuote.record.QuoteType__c
            ? Wizard.currentQuote.record.QuoteType__c
            : QW.CONSTANTS.QUOTE.QUOTE_TYPE.QUOTE;


        component.set('v.Tabs', Tabs);
    },

    checkAvailability: function(component) {
        var Wizard = component.get('v.Wizard');

        var quotes = component.get('v.Wizard').quotes;
        var settings = component.get('v.settings');
        var isBilling = component.get('v.config.wizard.isBilling');
        var isProserv = component.get('v.isProserv');
        var isCC = component.get('v.isCC');
        var isTelus = settings.isTelus;
        const isBtCC = settings.isBTBusiness && isCC;

        var proserv = quotes.find(qt => this.checkProServCondition(component, qt));

        var isCCQuoteAvailable = isBtCC || isTelus || this.checkContactCenterCondition(quotes);

        var isPrimaryQuoteOnApproval = Wizard.primaryQuote && Wizard.primaryQuote.isOnApproval ? Wizard.primaryQuote.isOnApproval : false;
        var isPrimaryQuoteAgreement = Wizard.primaryQuote && Wizard.primaryQuote.isAgreement ? Wizard.primaryQuote.isAgreement : false;

        var isCCQuoteExist = Boolean(Wizard && Wizard.ccQuote);

        var message = null;
        if(isProserv && !proserv) {
            message = 'No ProServ Quotes found';
        } else if(!isBtCC && !isProserv && quotes.length === 1 && proserv) {
            message = 'No Quotes found';
        } else if (isCC && !isCCQuoteAvailable && !isPrimaryQuoteAgreement) {
            message = 'Contact Center is not available for the package selected on your primary quote';
        } else if (isCC && !isCCQuoteAvailable && isPrimaryQuoteAgreement && !isCCQuoteExist) {
            message = 'Contact Center Quote cannot be created when Primary Quote in Agreement Stage';
        } else if((isBilling && isCC && isPrimaryQuoteOnApproval) && !isCCQuoteExist) {
            message = 'Contact Center Quote cannot be created when Primary Quote is in Approval Process';
        }

        component.set('v.wizardMessage', message);
    },

    checkProServCondition: function(component, quoteItem) {
        var isBilling = component.get('v.config.wizard.isBilling');

        var isProServ = quoteItem._isProServ();
        var isCCProServ = quoteItem._isCCProServ();

        return isProServ || isCCProServ;
    },

    checkContactCenterCondition: function(quotes) {
        let cc = false;
        quotes.forEach(function(quote){
            if (quote.isContactCenterQuoteAvailable) {
                cc = true;
            }
        });
        return cc;

    },

    discardPhaseManagement: function(component){
        var QuotingToolPhaseManagement = component.find('QuotingToolPhaseManagement');
        if (QuotingToolPhaseManagement)
            QuotingToolPhaseManagement.discard();
    },

    syncAndUpdateEntitlements: function(component) {

        if (!component.get('v.rcUserId')) return Promise.resolve();
        QW.spinner.show('Entitlements sync');

        return QW.salesforce.request(component, 'c.getEntitlementsSync', {
                accId: component.get('v.accountId')
            })
            .then($A.getCallback(function () {
                return QW.salesforce.request(component, 'c.getEntitlements', {
                    accountId: component.get('v.accountId')
                })
            }))
            .then($A.getCallback(function (entitlements) {
                component.set('v.entitlements', entitlements);
            }))
            .catch($A.getCallback(error => RC.salesforce.displayError('Failed to update Entitlements', error)))
    },

    setAccountServicePlan: function (component) {
        var entitlements = component.get('v.entitlements');
        var tiers = component.get('v.tiers');

        var accountServicePlanEnt = entitlements.find(ent => RC.Product2Helper.isServicePlan(ent.Product__r));
        var accountServicePlanPbe = accountServicePlanEnt
            && tiers.find(pbe => accountServicePlanEnt.Product__r.Id === pbe.Product2Id);

        component.set('v.accountServicePlanEnt', accountServicePlanEnt);
        component.set('v.accountServicePlanPbe', accountServicePlanPbe);
    },

    cancelChangeOrderQuote:function(component){

        return QW.salesforce.request(component, 'c.unlockOrderAndPhases', {
            oppToDowngrade: component.get('v.opportunityId')
        })
        .catch($A.getCallback(error => RC.salesforce.displayError('Failed to Unlock Parent Order and related Phases', error)))

    },

    isCCEntitlementsExist: function(entitlements) {
        return _.some(entitlements, ent =>
            ent.Product__r.Sub_Category__c === QW.CONSTANTS.PRODUCT2.SUB_CATEGORY.CONTACT_CENTER);
    }

});