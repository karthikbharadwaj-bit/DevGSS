/* globals QW, console */
({
    deleteQli: function(component) {
        component.getEvent('QuotingToolCartListEntryEvent').setParams({
            action: 'delete',
            params: { qli: component.get("v.document") }
        }).fire();
    },
    /**
     * Discard user changes in fields
     * @param component
     */
    discardValues: function(component) {
        var qli = component.get("v.document");
        if (!qli) return;
        // Quantity
        var initialQuantity = component.get("v.initialQuantity");
        var initialNewQuantity = component.get("v.initialNewQuantity");
        var existingQuantity = component.get("v.existingQuantity");

        component.set("v.quantity", initialQuantity);
        component.set("v.newQuantity", initialNewQuantity);

        // Discount
        var initialDiscount = component.get("v.initialDiscount");
        if (initialDiscount != null) {
            component.set("v.discount", initialDiscount);
        } else {
            component.set("v.discount", "");
        }

        var initialDiscountType = component.get("v.initialDiscountType");
        component.set("v.discountType", initialDiscountType);

        qli.Quantity = initialNewQuantity - existingQuantity; // initialQuantity;
        qli.NewQuantity__c = initialNewQuantity;
        qli.Discount_number__c = initialDiscount;
        qli.Discount_type__c = initialDiscountType;

        var initialProvisionedByInContact = component.get('v.initialProvisionedByInContact');
        qli.Provisioned_by_inContact__c = initialProvisionedByInContact;
        component.set('v.provisionedByInContact', initialProvisionedByInContact);

        component.set("v.document", qli);
        this.checkQLIDisabling(component);
        this.validateQLI(component);
    },

    /**
     * Disable/Enable Inputs
     */
    checkInputsDisabling: function (component) {
        try {
            var qli = component.get("v.document");
            var cartItem = component.get('v.cartItem');

            // QLI may have disabled QLI attribute;
            this.checkQLIDisabling(component);
            if (qli && qli.Disabled__c && qli.Product2.Charge_Term__c !== QW.CONSTANTS.PRODUCT2.CHARGE_TERM.ONE_TIME) {
                component.set("v.isCurrencyDiscountType", true);
                component.set("v.isPercentageDiscountType", true);

                return;
            }

            var busy = component.get("v.busy");
            var settings = component.get('v.settings');

            var featureForEES = settings && settings.featureForEES ? settings.featureForEES : 38;

            var state = component.get('v.state');
            var quote = component.get('v.quote');
            var deletingItems = component.get('v.deletingItems');
            var isItemDeleting = deletingItems && qli && deletingItems.has(qli.Id);
            var Wizard = component.get('v.Wizard');
            var hasAreaCodes = component.get('v.hasAreaCodes');

            var quantityInputDisabled,
                existingQuantityInputDisabled,
                discountInputDisabled,
                discountTypeInputDisabled,
                deleteButtonHidden,
                newQuantityInputDisabled,
                isDetailsEnabled,
                addAreaCodeItemButtonHidden,
                isProvisionedByInContactDisabled;

            //Check if product is Discountable according to QuoteLineItemRestrictionSettings__c custom setting
            var rsMap = settings.quoteLineItemRestriction;

            var featureProduct    = (qli && qli.Product2.Feature__c     != null) ? qli.Product2.Feature__c : '';
            var subFeatureProduct = (qli && qli.Product2.Sub_Feature__c != null) ? qli.Product2.Sub_Feature__c  : '';

            var keyFull   = '' + featureProduct + 'k' + subFeatureProduct;
            var keyShort  = '' + featureProduct + 'k';

            var qliRestriction = rsMap[keyFull] || rsMap[keyShort];

            var discountTypesAvailable = (qliRestriction) ? qliRestriction.DiscountTypesAvailable__c : '';
            var pType = (qliRestriction) ? qliRestriction.Product_Type__c : '';

            //Check if Discount Type should be displayed
            var notDiscountable = false;
            var isCurrencyDiscountType = false;
            var isPercentageDiscountType = false;

            if (discountTypesAvailable) {
                isCurrencyDiscountType = this.checkDiscountType(qli, discountTypesAvailable, 'Currency');
                isPercentageDiscountType = this.checkDiscountType(qli, discountTypesAvailable, 'Percentage');
            } else if (qliRestriction) {
                notDiscountable = true;
            }

            var enableInputsByPermissions = this.checkForCustomPermissionSet(component, qli, Wizard);

            if (isCurrencyDiscountType && !isPercentageDiscountType) {
              component.set("v.isCurrencyDiscountType", true);
            }
            else if (isPercentageDiscountType && !isCurrencyDiscountType) {
              component.set("v.isPercentageDiscountType", true);
            }
            else {
              component.set("v.isCurrencyDiscountType", true);
              component.set("v.isPercentageDiscountType", true);
            }

            /* Check Product type */
            if(rsMap[qli.Product2.Product_Type__c]) {
                notDiscountable = true;
            }

            if (isItemDeleting) {
                $A.util.addClass(component.find("delete-button"), "slds-hide");
                $A.util.removeClass(component.find("spinner"), "slds-hide");
            }

            var isBillingOpportunity = Wizard.opportunity.record.Is_Billing_Opportunity__c;
            var isPrimaryQuoteOnApproval = Wizard.primaryQuote && Wizard.primaryQuote.isOnApproval;
            var isPrimaryQuoteAgreement = Wizard.primaryQuote && Wizard.primaryQuote.isAgreement;
            var isContactCenterQuote = Wizard.currentQuote.isCC;

            if (!Wizard.currentQuote
                || !qli
                || !state
                || Wizard.opportunity.isClosed
                || Wizard.currentQuote.isAgreement
                || Wizard.currentQuote.isOnApproval
                || !state.isUserHavePermissionToEditQuote
                // Dependent on Feature
                || qli.Product2.Dependent_on_Feature__c
                // Dependent on Common Phone
                || qli.Product2.Feature__c === 50
                // Taxes
                || qli.Product2.Family === 'Taxes'
                // ProServ
                || (!Wizard.currentQuote.isProServ && qli.Product2.Sub_Category__c === settings.PROSERV_PRODUCT_SUBCATEGORY)
                // CC ProServ
                || (!Wizard.currentQuote.isCCProServ && qli.Product2.Sub_Category__c === settings.CC_PROSERV_PRODUCT_SUBCATEGORY)
                // Cart is busy
                || busy
                || isItemDeleting
                || Wizard.currentQuote.isCancelled
                || Wizard.currentQuote.isSoldOrOutForSignature
                || Wizard.currentQuote.isInvalid
                || !enableInputsByPermissions
                || Wizard.opportunity.isPendingConfirmAndClose
                || (isContactCenterQuote && (isBillingOpportunity && (isPrimaryQuoteOnApproval || isPrimaryQuoteAgreement)))) {

                quantityInputDisabled = true;
                newQuantityInputDisabled = true;
                existingQuantityInputDisabled = true;
                discountInputDisabled = true;
                discountTypeInputDisabled = true;
                deleteButtonHidden = true;
                addAreaCodeItemButtonHidden = true;
                isProvisionedByInContactDisabled = true;

            } else {
                quantityInputDisabled = false;
                existingQuantityInputDisabled = false;

                // Restrict changes of discounts for free products
                if ((qli.UnitPrice === 0) ||
                    notDiscountable ||
                    //B-474
                    (qli.Product2.Sub_Category__c === 'Professional Services' && !state.isProServQuote)
                    // Cart item created from asset (Change Order) (B-3806)
                    || qli.Asset__c) {
                    discountInputDisabled = true;
                    discountTypeInputDisabled = true;
                } else {
                    discountInputDisabled = false;
                    discountTypeInputDisabled = false;
                }

                if (qli.newQuantity === 0 && qli.Product2 && qli.Product2.Family != 'Overage') {
                    discountInputDisabled = true;
                    discountTypeInputDisabled = true;
                }

                //
                if (qli.Product2.Family == "Fee" ||
                    ((qli.Product2.Family == "Service" || qli.Product2.Family == "Tier") &&
                        quote && quote.Upsell_Status__c != "Upsell")) {
                    deleteButtonHidden = true;
                } else {
                    deleteButtonHidden = false;
                }

                // If Deactivated
                if (qli.Deactivated__c) {
                    quantityInputDisabled = true;
                    existingQuantityInputDisabled = true;
                    discountInputDisabled = true;
                    discountTypeInputDisabled = true;
                }

                var eqty = 0;
                var iqty = component.get("v.initialQuantity");
                if (qli.Entitlement__c && qli.Entitlement__r.Quantity__c) eqty = qli.Entitlement__r.Quantity__c;
                if (
                    (iqty + eqty) === 0
                    && qli.Product2.Family != 'Overage'
                    && qli.Product_Type__c
                    && qli.Product_Type__c.toLowerCase() == 'seat'
                ) {
                    deleteButtonHidden = true;
                }

                // B-2097
                if (qli.Product2 && qli.Product2.Family === 'Overage') {
                    quantityInputDisabled = true;
                    existingQuantityInputDisabled = true;
                    newQuantityInputDisabled = true;
                    deleteButtonHidden = true;
                }

                // Some types ones are out of scope of CRM-434, but are left in this comment
                // to not mess the logic when finally adding them:
                // 'IVN'
                // 'International'
                // 'Outbound Calls to Premium Mobile Numbers UK'
                // DON'T FORGET toLowerCase() !!!
                var ptypes = [
                    'Seat'.toLowerCase()
                ];

                if (qli.Product_Type__c
                    && ptypes.includes(qli.Product_Type__c.toLowerCase())
                    && qli.Product2.Family == "Overage") {

                    var isAllowed = component.get('v.isAllowedEditDiscount');
					if(!isAllowed){
						discountInputDisabled = true;
						discountTypeInputDisabled = true;
						quantityInputDisabled = true;
						existingQuantityInputDisabled = true;
					}
					else if (isAllowed && qli.Product2.Name == 'Seat Overage'){
						discountInputDisabled = false;
						discountTypeInputDisabled = false;
						quantityInputDisabled = false;
						existingQuantityInputDisabled = false;
					}

					deleteButtonHidden = true;
                    newQuantityInputDisabled = true;

                }

                //B-6697
                if(qli.Unmatched && qli.Product2.Charge_Term__c === QW.CONSTANTS.PRODUCT2.CHARGE_TERM.ONE_TIME) {
                    newQuantityInputDisabled = false;
                    discountInputDisabled = true;
                    discountTypeInputDisabled = true;
                }

                // For Exist, Active entitelment we show new quantity and exist quantity should be disabled.
                if (qli.Entitlement__r && qli.Entitlement__r.Active__c) {
                    existingQuantityInputDisabled = true;
                    deleteButtonHidden = true;
                }

                // qli with asset cannot be deleted
                if(qli.Asset__r) {
                    deleteButtonHidden = true;
                }

                var isExtendedEnterpriseSupport = QW.Product2Helper.checkIsExtendedEnterpriseSupport(qli.Product2, featureForEES);

                if (isExtendedEnterpriseSupport || QW.Product2Helper.isAmeliaTTS(qli.Product2)) {
                    quantityInputDisabled = true;
                    newQuantityInputDisabled = true;
                }

                if (qli.Product_Type__c === 'AI' || qli.Product2.IsLimitedToQtyOne__c) {
                    quantityInputDisabled = true;
                }

                if (hasAreaCodes) {
                    newQuantityInputDisabled = true;
                }

                const brandName = Wizard.currentQuote && Wizard.currentQuote.record
                  && Wizard.currentQuote.record.Pricebook2
                  && Wizard.currentQuote.record.Pricebook2.Brand__r
                  && Wizard.currentQuote.record.Pricebook2.Brand__r.Name;

                if (brandName == QW.CONSTANTS.OPPORTUNITY.BRAND_NAME.BT_BUSINESS) {
                    var isAllowedProServProfile = state.isUserProServWithoutSupportDirector;
                    
                    if (!isAllowedProServProfile) {
                        discountInputDisabled = true;
                        discountTypeInputDisabled = true;
                    }

                }
            }

            //Area Code Assignment
            if (Wizard.currentQuote.isAreaCodesAllowed && qli && settings &&
                (settings.areaCodesFeatures.includes(qli.Product2.Feature__c) ||
                    settings.areaCodesFamilies.includes(qli.Product2.Family))) {
                if(qli.Unmatched && qli.Product2.Charge_Term__c === QW.CONSTANTS.PRODUCT2.CHARGE_TERM.ONE_TIME) {
                    isDetailsEnabled = false;
                } else {
                    isDetailsEnabled = true;
                }
            }

            var sp = component.find("spinner");

            component.find("quantityInput").set("v.disabled", quantityInputDisabled);
            component.find("existingQuantityInput").set("v.disabled", existingQuantityInputDisabled);
            component.find("newQuantityInput").set("v.disabled", newQuantityInputDisabled);

            component.find("discountInput").set("v.disabled", discountInputDisabled);
            component.find("discountTypeInput").set("v.disabled", discountTypeInputDisabled);
            if (deleteButtonHidden) {
                $A.util.addClass(component.find("delete-button"), "slds-hide");
            } else if (sp != null && sp != undefined && $A.util.hasClass(sp, "slds-hide")) {
                $A.util.removeClass(component.find("delete-button"), "slds-hide");
            }
            QW.cssUtils.toggleClass(component, 'table-row', isDetailsEnabled, 'qli--details-enabled');
            QW.cssUtils.toggleShow(component, 'addAreaCodeItemButton', !addAreaCodeItemButtonHidden);

            component.set('v.isDetailsEnabled', isDetailsEnabled);

            var provisionedByInContact = component.find('provisionedByInContact');
            provisionedByInContact && provisionedByInContact.set("v.disabled", isProvisionedByInContactDisabled);
        } catch (e) {
            console.error('checkInputsDisabling', e);
        }
    },

    checkDiscountType: function(qli, dTypesAvailable, type) {
        var entDType = qli.Entitlement__r && qli.Entitlement__r.Discount_Type__c;
        var qliDtype = qli.Discount_type__c;

        return dTypesAvailable.includes(type) || (entDType === type && qliDtype === 'Currency');
    },

    /**
     * Show Hide elements
     * @param component
     */
    checkVisibility: function(component) {
        var Wizard = component.get('v.Wizard');
        var state = component.get('v.state');
        var qli = component.get("v.document");
        var isHasActiveEntitlement = qli && qli.Entitlement__r && qli.Entitlement__r.Active__c;

        var isAddAreaCodesVisible = true;
        if (state
            && (Wizard.opportunity.isClosed
                || state.isAgreement
                || state.isQuoteOnApproval
                || (state.isUserProServ && !state.isProServQuote)
                || (state.isUserCCProServ && !state.isCCProServQuote))) {
            isAddAreaCodesVisible = false;
        }
        QW.cssUtils.toggleShow(component, 'addAreaCodeItemButton', isAddAreaCodesVisible);

        // B-2599 Hide products unavailable for this quote
        var isQLIVisible = qli
            && qli.Product2.Cart_Tab_Availability__c
            && qli.Product2.Cart_Tab_Availability__c
                .split(';')
                .map(function(item){ return item.trim(); })
                .includes(component.get('v.quoteRecordTypeName'));
        QW.cssUtils.toggleShow(component, 'table-row', isQLIVisible);

        // Provisioned by InContact
        var isProvisionedByInContactVisible = state && qli
            && state.isCCProServQuote
            && !!qli.Product2.CatID__c;
        QW.cssUtils.toggleShow(component, 'provisionedByInContact', isProvisionedByInContactVisible);

        // Existing Quantity Input (using Entitlement)
        var isExistingQuantityInputVisible = isHasActiveEntitlement;
        QW.cssUtils.toggleShow(component, 'existingQuantityInput', isExistingQuantityInputVisible);

        // Existing Quantity Input (Using Asset)
        var isAssetExistingQuantityInputVisible = qli.Asset__r
            && !isHasActiveEntitlement;
        QW.cssUtils.toggleShow(component, 'assetExistingQuantityInput', isAssetExistingQuantityInputVisible);

        // Delivered Quantity Input (Using Asset)
        var isDeliveredQuantityInputVisible = !isHasActiveEntitlement
            && qli.Asset__r;
        QW.cssUtils.toggleShow(component, 'deliveredQuantityInput', isDeliveredQuantityInputVisible);
    },

    checkForCustomPermissionSet: function(component, qli, Wizard){
        if(qli && qli.Product2.Custom_Permission_Set__c) {
            for (let permission of qli.Product2.Custom_Permission_Set__c.split(';')) {
                if (!Wizard.settings.userPermissions[permission]) {
                    return false;
                }
            }
        }
        return true;
    },

    isNumeric: function(n) {
      return !isNaN(parseFloat(n)) && isFinite(n);
    },

    setQuantity: function(component) {
        var qli = component.get('v.document');

        var quantity = QW.QLIHelper.getQuantity(qli);
        var existingQuantity = QW.QLIHelper.getExistingQuantity(qli);

        if( QW.Product2Helper.isOverage(qli.Product2) && qli.Product2.Name != 'Seat Overage' ) {
            existingQuantity = 0;
            quantity = 0;
        }

        component.set("v.quantity", quantity);
        if(qli.Product2.Family == 'Overage') {
            component.set("v.newQuantity", 0);
        } else {
            component.set("v.newQuantity", (qli.NewQuantity__c ? qli.NewQuantity__c : 0));
        }
        component.set('v.existingQuantity', existingQuantity);
        component.set("v.initialQuantity", quantity);
        component.set("v.initialNewQuantity", (qli.NewQuantity__c ? qli.NewQuantity__c : 0));
    },

    setDiscount: function(component, qli) {
      qli.Discount_number__c = qli.Discount_number__c || 0;

      component.set("v.discount", qli.Discount_number__c);
      component.set("v.initialDiscount", qli.Discount_number__c);
      component.set("v.discountType", qli.Discount_type__c);
      component.set("v.initialDiscountType", qli.Discount_type__c);
    },

    setPrecision: function(component, qli) {
      component.set('v.currencyPrecision', this.calcPrecision(qli.UnitPrice) );
    },

    setProvisionedByInContact: function(component, qli){
        component.set('v.initialProvisionedByInContact', qli.Provisioned_by_inContact__c );
        component.set('v.provisionedByInContact', qli.Provisioned_by_inContact__c );
    },

    checkDeactivation: function(component) {
        var qli = component.get('v.document');
        var qty = Number(component.get("v.newQuantity"));

        if(!qty || qty < 0) {
            qty = 0;
        }

        var rowToShade = component.find("table-row");

        if(qli.Product2.Family !== QW.CONSTANTS.PRODUCT2.FAMILY.OVERAGE
            && qli.Product2.Charge_Term__c !== QW.CONSTANTS.PRODUCT2.CHARGE_TERM.ONE_TIME){
            if(qty === 0) {
                $A.util.addClass(rowToShade, 'disabledRow');
                qli.Deactivated__c = true;
            } else {
                $A.util.removeClass(rowToShade, 'disabledRow');
                qli.Deactivated__c = false;
            }
        }

        component.find("discountInput").set("v.disabled", qli.Deactivated__c);
        component.find("discountTypeInput").set("v.disabled", qli.Deactivated__c);
    },

    checkSeatDeactivation: function(component, quantity) {
      try {
        var result = false;
        var params = component.get('v.params');
        var qli = component.get('v.document');
        var initialQli = component.get('v.initialQuantity');

        if(qli.Product2 && qli.Product2.Family && qli.Product_Type__c &&
           qli.Product2.Family.toLowerCase() === 'CC Service'.toLowerCase() &&
           qli.Product_Type__c.toLowerCase() === 'Seat'.toLowerCase() &&
           quantity === 0) {

          result = true;
          if( (qli.Entitlement__r && (qli.Entitlement__r.Quantity__c + initialQli === 0)) ||
              (!qli.Entitlement__r && initialQli === 0) ) result = false;
          if(result) params.Seat.name = qli.Product2.Name;
        }

        params.Seat.isSeatDeactivation = result;
        component.set('v.params', params);
      } catch (e) {
        console.error(e);
      }
    },

    checkAllowDownsell: function(component, qty, field) {
      var Wizard = component.get('v.Wizard');
      var qli = component.get("v.document");
      var result = true;
      var minValue = Wizard.opportunity.isChangeOrderOpportunity ? 0 : 1;

      // Check on New Product;
      if((!qty || qty < minValue) && !qli.Entitlement__r && !qli.Asset__r) {
        result = false;
      }

      var isOneTime = (qli.Product2.Charge_Term__c === 'One - Time' ||
        new Set(Wizard.settings.OneTimeFeatureSet).has(qli.Product2.Feature__c));

      // Check on One time Product with Entitlement;
      if(qli.Entitlement__r && isOneTime) {
        const isUpsell = Wizard.primaryQuote && Wizard.primaryQuote.isUpsell;
        if(isUpsell) {
            minValue = 0;
            this.checkIsQLIChanged(component);
        }
        if(qty <= qli.Entitlement__r.DisplayQuantity__c) {
          result = false;
          minValue = qli.Entitlement__r.DisplayQuantity__c + minValue;
        }
      }

      // Set min value;
      if(!result) {
        // set min value in field
        component.set('v.'+field, minValue);

        // set min value in qli Quantity
        qli.Quantity = minValue;
        qli.NewQuantity__c = minValue;
        component.set("v.document", qli);
      }

      return result;
    },

    calcPrecision: function(value) {
      try {
        var val = value ? String(value).split('.')[1] : null;
        return val ? val.length : 2;
      } catch (e) {
        console.error(e);
      }

      return 2;
    },

    /**
     * Creates unsaved Area Code Item
     */
    addAreaCodeItem:function(component){
        var helper = this;
        var document = component.get('v.document');
        var areaCodeItemsInOperation = component.get('v.areaCodeItemsInOperation');
        var quantity = component.get('v.quantity');
        var initialQuantity = component.get('v.initialQuantity');
        component.set('v.quantity',initialQuantity);
        var newAreaCode = {
            sobjectType:        'Area_Code_Line_Item__c',
            guid:               QW.uuidv4(),
            Quantity__c:        helper.setAreaCodeQuantity(component),
            Quote_Line_Item__c: document.Id
        };
        areaCodeItemsInOperation.push(newAreaCode);
        component.set('v.areaCodeItemsInOperation',areaCodeItemsInOperation);
    },

    /**
     * Preselects quantity on area code addition
     */
    setAreaCodeQuantity: function(component) {
        var quantity = component.get('v.quantity');
        var hasAreaCodes = component.get('v.hasAreaCodes');

        var areaCodeQuantity;
        if (hasAreaCodes) {
            areaCodeQuantity = 1;
        } else {
            areaCodeQuantity = quantity;
        }
        return areaCodeQuantity;
    },

    /**
     * Get sum of Quantity of all Area Codes
     */
    calcAreaCodesQuantity: function (component) {
        try {
            var document = component.get('v.document');
            let qliQuantity = component.get('v.quantity');
            if (document) {
                var areaCodeItemsInOperation = component.get('v.areaCodeItemsInOperation') || [];
                var areaCodesTotalQty = 0;
                var areaCodeItemsOnQlIqty = 0;
                var hasAreaCodes = false;
                areaCodeItemsInOperation.forEach(function (item) {
                    if (item.Quote_Line_Item__c === document.Id) {
                        areaCodesTotalQty += item.Quantity__c ? Number(item.Quantity__c) : 0;
                        hasAreaCodes = true;
                        if (item.Id) {
                            areaCodeItemsOnQlIqty++;
                        }
                    }
                });
                component.set('v.quantityByAreaCodes', areaCodesTotalQty);
                component.set('v.hasAreaCodes', hasAreaCodes);
                component.set('v.areaCodeItemsOnQlIqty', areaCodeItemsOnQlIqty);
                // this line is used to change displayed QLI's new quantity on ACLI quantity change
                if(areaCodesTotalQty > 0) {
                    component.set('v.newQuantity', component.get('v.initialNewQuantity') + areaCodesTotalQty - qliQuantity);
                }
            }
        } catch (e) {
            console.error('calcAreaCodesQuantity', e);
        }
    },
    /**
     * Shows default area code message
     * @see {@link https://rc.my.salesforce.com/a2034000003NOOP} B-2342 UX Improvements for Area Codes population
     */
    checkMessages: function(component){
        var quote = component.get('v.quote');
        var activePriceBookEntry = component.get('v.activePriceBookEntry');
        var settings = component.get('v.settings');
        var qli = component.get('v.document');
        var hasAreaCodes = component.get('v.hasAreaCodes');
        var showDefaultAreaCodeMessage = false;

        if (quote && activePriceBookEntry && qli){
            if (quote.Upsell_Status__c === 'New' && !hasAreaCodes &&
                activePriceBookEntry.Pricebook2.Service__c === 'Office' &&
                quote.AreaCode__r && quote.AreaCode__r.Type__c === 'Local' &&
                (settings.areaCodesFamilies.includes(qli.Product2.Family) ||
                 qli.Product2.Feature__c === 3 )) {
                showDefaultAreaCodeMessage = true;
            }
        }

        QW.cssUtils.toggleShow(component, 'defaultAreaCodeMessage', showDefaultAreaCodeMessage);
    },

    checkQLIDisabling: function (component) {
        try {
            var qli = component.get('v.document');
            var disabled = qli && qli.Disabled__c;

            if (disabled) {

                var tableRow = component.find("table-row");
                $A.util.addClass(tableRow, 'disabledRow');

                var inputs = ['quantityInput', 'existingQuantityInput', 'newQuantityInput', 'discountInput', 'discountTypeInput'];
                for (var i = 0; i < inputs.length; i++) {
                    component.find(inputs[i]).set("v.disabled", true);
                }

                $A.util.addClass(component.find("delete-button"), "slds-hide");

                var unmatched = component.get('v.unmatched');
                if (unmatched) {
                    let newQty = qli.Entitlement__r
                    ? qli.Entitlement__r.Quantity__c + qli.Quantity
                    : qli.Quantity;

                    component.set("v.newQuantity", newQty);
                }

            }

        } catch (e) {
            console.log(e);
        }
    },

    setColumnWidth: function (component) {
        if (!component.get('v.calcCellWidth')) return;

        var columns = component.get('v.columns');
        var group = component.get('v.group');
        var offset;

        for (var key in columns) {
            if (columns.hasOwnProperty(key)) {
                offset = 0;
                if (group.name && key === 'nameCol') offset = -32;

                var val = (columns[key] + offset) + 'px';
                var el = component.find(key);
                if (!el) continue;

                el.getElement().style.minWidth = val;
                el.getElement().style.maxWidth = val;
            }
        }
    },
    /**
     * Prepare tooltip text
     */
    prepareTooltips: function(component){
        var quote = component.get('v.quote');
        var areaCodeItemsOnQlIqty = component.get('v.areaCodeItemsOnQlIqty');
        var settings = component.get('v.settings');
        var qli = component.get('v.document');
        var brandName = component.get('v.activePriceBookEntry.Pricebook2.Brand__r.Name');
        var unmatched = component.get('v.unmatched');
        var qty = component.get('v.areaCodeItemsOnQlIqty');
        var state = component.get('v.state');

        var warningArray = [];
        var infoArray = [];
        var areaCodesText = '';

        if(qli && quote){
            // Warnings
            // ========

            // Please Assign Area Codes Warning
            if (quote.Required_Area_Codes_are_empty__c && areaCodeItemsOnQlIqty === 0 && quote.AreaCode__r &&
                ( (quote.AreaCode__r.Type__c === 'Toll-Free' &&
                    ( settings.areaCodesFamilies.includes(qli.Product2.Family) ||
                        settings.areaCodesFeatures.includes(qli.Product2.Feature__c) ) ) ||
                    (quote.AreaCode__r.Type__c === 'Local' && qli.Product2.Feature__c == 2) )) {

                warningArray.push('<b>Please assign Area Codes for all devices and additional phone numbers</b>' +
                    '<br>Click on the ">" button to see more');

            }

            // B-2408
            if (state.isNewCustomer
                && quote.Initial_Term_months__c < 24
                && qli.Discount_Value__c > 50
                && qli.Product2.Family
                && qli.Product2.Family.toLowerCase().indexOf('phones') > -1
                && qli.Product2.Sub_Category__c === 'Main') {

                var discountDetails_text = $A.get("$Label.c.QW_Notification_discountDetails_text");
                var currencySign = { USD: '$', CAD: '$', AUD: '$', EUR: '€', GBP: '£' }[qli.CurrencyIsoCode];
                var preparedMessage = discountDetails_text.replace('${quoteCurrencySign}', currencySign);

                warningArray.push(preparedMessage);

            }

            // Infos
            // =====

            // Supported Countries
            if(qli.Product2.Supported_Countries__c && brandName === 'RingCentral EU'){
                var countries = qli.Product2.Supported_Countries__c.replace(/;/gi, ', ');
                var countriesText = "<b>The phone is available only in:</b><br>"+ countries;
                if (countriesText) infoArray.push(countriesText);
            }
            //Check if product is not available for SignUp according to QuoteLineItemRestrictionSettings__c custom setting
            var quoteLineItemRestrictionSettingsMap = settings.quoteLineItemRestriction;
            var featureProduct  = qli.Product2.Feature__c != null ? qli.Product2.Feature__c.toString() : '';
            var subFeatureProduct  = qli.Product2.Sub_Feature__c != null ? qli.Product2.Sub_Feature__c.toString() : '';
            var notAvailableOnSignUp = false;
            if (quoteLineItemRestrictionSettingsMap[featureProduct + 'k' + subFeatureProduct]) {
              notAvailableOnSignUp = quoteLineItemRestrictionSettingsMap[featureProduct + 'k' +subFeatureProduct].NotAvailableOnSignUp__c;
            }
            //
            if (quote.Upsell_Status__c === "New" && notAvailableOnSignUp){
                infoArray.push('This product needs to be added separately in Service Web after Sign&nbsp;Up');
            }

            if (qli.Deactivated__c){
                infoArray.push('This product will be canceled for the client');
            }

            if (qli.Unmatched || unmatched) {
                infoArray.push('Item not available in current Service Plan');
            }

            // Area Codes Counter
            // ==================

            // Area Codes Text
            if (qty > 0){
                var s = qty !== 1 ? 's' : '';
                areaCodesText = '<b>This product has '+ qty +' area code'+ s +' assigned.</b>';
                areaCodesText += '<br>Click on the ">" button to see more';
            }
        }

        var warningText = warningArray.join('<br><br>');
        var infoText = infoArray.join('<br><br>');

        var cartListEntryIcons = component.find('QuotingToolCartListEntryIcons');
        if (cartListEntryIcons){
            cartListEntryIcons.set('v.warningText',warningText);
            cartListEntryIcons.set('v.infoText',infoText);
            cartListEntryIcons.set('v.areaCodesText',areaCodesText);
        }
    },
    checkShowDetails: function(component){
        QW.cssUtils.toggleClass(component,'table-row',component.get('v.document.isShowDetails'), 'qli--show-details');
    },

    /**
     * Check if QLI has any changes in fields
     * @param component
     */
    checkIsQLIChanged: function(component){
        var qli = component.get('v.document');

        var fields = [
            { userValue:'v.quantity',               initialValue: 'v.initialQuantity',               auraId: 'qtyCol'          },
            { userValue:'v.newQuantity',            initialValue: 'v.initialNewQuantity',            auraId: 'newTotalQtyCol'  },
            { userValue:'v.discount',               initialValue: 'v.initialDiscount',               auraId: 'discountCol'     },
            { userValue:'v.discountType',           initialValue: 'v.initialDiscountType',           auraId: 'discountTypeCol' },
            { userValue:'v.provisionedByInContact', initialValue: 'v.initialProvisionedByInContact', auraId: 'provisionedByInContactCol' }
        ];
        qli.isChanged = false;
        qli.isQuantityChanged = false;
        qli.isOtherChanged = false;
        fields.forEach(function(field){
            var isFieldChanged = component.get(field.userValue) != component.get(field.initialValue);

            // Mark QLI as changed
            if (isFieldChanged) {
                 qli.isChanged = true;
                 if(field.userValue == 'v.quantity') {
                    qli.isQuantityChanged = true;
                 } else {
                     qli.isOtherChanged = true;
                 }
            }

            // Style changed fields
            QW.cssUtils.toggleClass(component, field.auraId, isFieldChanged, 'col_is-changed');

        });

        component.set('v.document', qli);

        this.fireOnUpdateEvent(component);
    },

    /**
     * Change dummy variable so the parent component could catch event
     * @param component
     */
    fireOnUpdateEvent: function(component){
        component.set('v.updateTrigger', component.get('v.updateTrigger') + 1);
    },

    /**
     * Match current Quote Line Item with Cart Item Instance from v.Wizard object
     * Cart Item object in v.Wizard contains many useful checks.
     * records in v.Wizard are saved in SF.
     * @param component
     */
    setCartItem: function(component){
        var qli = component.get('v.document');
        var Wizard = component.get('v.Wizard');

        if (!Wizard || !Wizard.currentQuote || !qli)
            return;

        var cartItem = Wizard.currentQuote.getCartItem(qli.Id);

        component.set('v.cartItem', cartItem);
    },
    setYourPrice: function(component, qli){
        //B-1387 Sergienko
        var yourPrice = 0;
        if (qli.Quantity != 0) {
            yourPrice = qli.TotalPrice / qli.Quantity;
        } else {
            var discountNumber = qli.Discount_number__c;
            if (discountNumber == undefined) discountNumber = 0;
            if (qli.Discount_type__c == "Percentage") {
                yourPrice = qli.UnitPrice * (1 - discountNumber / 100);
            } else {
                yourPrice = qli.UnitPrice - discountNumber;
            }
        }
        component.set("v.yourPrice", yourPrice);
        //B-1387 Sergienko

    },
    setDeactivated: function(component, qli){
        qli.Deactivated__c = (qli.Deactivated__c === undefined) ? false : qli.Deactivated__c;
        var tableRow = component.find("table-row");
        var eqty = 0;
        if (qli.Entitlement__c && qli.Entitlement__r.Quantity__c)
            eqty = qli.Entitlement__r.Quantity__c;
        if (qli.Deactivated__c === true || (qli.Quantity + eqty) === 0 && qli.Product2.Family != 'Overage') {
            $A.util.addClass(tableRow, 'disabledRow');
        }
    },
    validateQLI: function(component){
        var qli = component.get('v.document');
        var hasErrors = this.validateNewQuantity(component);

        qli.hasErrors = hasErrors;
        component.set('v.document', qli);
    },
    validateNewQuantity: function(component){
        var qli = component.get('v.document');
        var newQuantity = Number(component.get("v.newQuantity"));
        if (!newQuantity) newQuantity = 0;

        var hasQuantityLessThanDelivered = qli.Asset__r && qli.Asset__r.Delivered_Quantity__c > newQuantity;
        var hasExistingQTYforInactiveProduct = qli.Asset__r && qli.Asset__r.Quantity < newQuantity && qli.Product2.IsActive != true;
        var isQtyExcessiveForLimitedToQtyOneProduct = qli.Product2 && qli.Product2.IsLimitedToQtyOne__c && newQuantity > 1;

        var hasError = hasQuantityLessThanDelivered || hasExistingQTYforInactiveProduct || isQtyExcessiveForLimitedToQtyOneProduct;

        var tooltipText = '';
        if (hasQuantityLessThanDelivered) {
            tooltipText = 'New Total Quantity should be at least the Quantity Delivered (' + qli.Asset__r.Delivered_Quantity__c + ')';
        } else if (hasExistingQTYforInactiveProduct) {
            tooltipText = 'This Product became unavailable, you can’t sell more than was sold on original Order - ' + qli.Asset__r.Quantity;
        } else if (isQtyExcessiveForLimitedToQtyOneProduct) {
            tooltipText = 'Only one of this product per account is supported';
        }

        QW.cssUtils.toggleClass(component, 'newTotalQtyCol', hasError, 'col_has-error');
        component.find('newQuantityTooltip').set('v.text', tooltipText);
        return hasError;
    },
	allowToEditDiscount: function(component){

		var action = component.get('c.isAllowedtoEditDiscount');
		action.setCallback(this, function (response) {
			var state = response.getState();
			if (state == "SUCCESS") {
				component.set('v.isAllowedEditDiscount', response.getReturnValue());
			}
		});
		$A.enqueueAction(action);

	}
});