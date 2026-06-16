({
    onAfterScriptsLoaded: function (component, event, helper) {
        helper.initApp(component);
        helper.getDataOnInit(component)
            .then($A.getCallback(() => {
                var app = component.get('v.app');
                app.renderMarkup();
                component.set('v.app', app);
            }))
            .then($A.getCallback(() => {
                helper.initAttributes(component);
                helper.initOpportunityInfoSectionNotifications(component);
                helper.initServicePlanSectionNotifications(component);
                helper.preselectFromUrl(component);
            }));
    },
    /**
     * Save button pressed
     */
    saveForm: function (component, event, helper) {
        event.preventDefault();
        if (helper.validateContinueToOpportunity(component)) {
            helper.createOpportunityProcess(component);
        }
    },
    /**
     * Plan field changed
     */
    typeChanged: function (component, event, helper) {
        var app = component.get('v.app');
        var type = component.get('v.type');
        var selectedAccount = component.get('v.selectedAccount');
        var isBtBusinessUpsell = helper.checkForBTUpsell(selectedAccount);
        var isTelusUpsell = helper.checkForTelusUpsell(selectedAccount);
        var selectedTier = component.get('v.selectedTier');
        var selectedService = component.get('v.service');

        app.setType(type);
        component.set('v.app', app);

        if (helper.isUpsell(type)) {

            if (!isBtBusinessUpsell && !isTelusUpsell) {
                component.set('v.newTotalUsers', component.get('v.numberOfLines'));

                helper.showInputField(component, false, 'forecastedUsers');
                helper.showInputField(component, true, 'accountDLs');
                if (!(selectedTier && (selectedTier.Pricebook2.Edition__c === 'Fax' || selectedTier.Pricebook2.Edition__c === 'Professional'))
                    && !(selectedService !== null && (selectedService === 'Fax' || selectedService === 'Professional'))) {
                    helper.showInputField(component, true, 'newTotalUsers');
                }
            }

            helper.proceedUpsell(component);
        }
        else if (type === 'Upgrade') {
            if (!isBtBusinessUpsell && !isTelusUpsell) {
                helper.showInputField(component, false, 'forecastedUsers');
                helper.showInputField(component, true, 'accountDLs');
                helper.showInputField(component, true, 'newTotalUsers');
            }

            helper.proceedUpgrade(component);
            helper.selectTierByFields(component);
        }
        else {
            helper.showInputField(component, true, 'forecastedUsers');
            helper.showInputField(component, false, 'accountDLs');
            helper.showInputField(component, false, 'newTotalUsers');
        }

        helper.proceedFields(component);
        helper.checkNotifications(component);
    },
    /**
     * Brand field changed
     * Level 0
     */
    brandChanged: function (component, event, helper) {
        var app = component.get('v.app');
        var type = component.get('v.type');
        var brand = component.get('v.brand');
        const brandConfiguration = app.getEnabledServicesByBrand(component.get('v.brandConfiguration'));

        if (component.get('v.isTriggerSwitch')) {
            helper.switchToNgbs(component);
        }

        if (!helper.isUpsell(type)) {
            var serviceOpts = helper.getServiceOpts(component, brand);
            component.set('v.serviceOpts', helper.createOpts(serviceOpts));

            if (brand === OC.CONSTANTS.OPPORTUNITY.BRAND_NAME.AT_T) {
                component.set('v.service', OC.CONSTANTS.OPPORTUNITY.TIER_NAME.OFFICE);
            } else if (helper.isNGBSServiceEnabled(brandConfiguration[brand])) {
                component.set('v.service', OC.CONSTANTS.OPPORTUNITY.TIER_NAME.RC_OFFICE);
            } else {
                component.set('v.service', '');
            }
            component.set('v.edition', '');
            component.set('v.plan', '');

            var noQuoteForBrands = component.get('v.noQuoteForBrands');

            if (
                noQuoteForBrands.indexOf(brand) === -1
                || brand !== OC.CONSTANTS.OPPORTUNITY.BRAND_NAME.BT_BUSINESS
                || brand !== OC.CONSTANTS.OPPORTUNITY.BRAND_NAME.TELUS
            ) {
                helper.selectTierByFields(component);
            }
        }

        app.setBrand(brand);
        component.set('v.app', app);
        helper.setLookupParams(component);
        helper.proceedFields(component);
        helper.clearErrors(component);
        helper.checkNotifications(component);
    },
    /**
     * Service field changed
     * Level 1
     */
    serviceChanged: function (component, event, helper) {
        var brand = component.get('v.brand');
        var service = component.get('v.service');
        var noQuoteForServices = component.get('v.noQuoteForServices');
        var type = component.get('v.type');
        var app = component.get('v.app');
        app.setService(service);
        component.set('v.app', app);

        if (component.get('v.isTriggerSwitch')) {
            helper.switchToNgbs(component);
        }

        if (!helper.isUpsell(type)) {
            component.set('v.edition', '');
            component.set('v.plan', '');
            if (noQuoteForServices.indexOf(service) === -1
                || service !== RC.CONSTANTS.OPPORTUNITY.TIER_NAME.RC_MEETINGS
            ) {
                helper.selectTierByFields(component);
            }
        }
        if (noQuoteForServices.indexOf(service) > -1
            || service === RC.CONSTANTS.OPPORTUNITY.TIER_NAME.RC_MEETINGS
        ) {
            component.set('v.forecastedUsers', '1');
        }
        helper.proceedFields(component);
        helper.clearErrors(component);
        helper.checkNotifications(component);

        if (helper.isSelectedAccountBillOnBehalf(component) || helper.isSelectedAccountWholesale(component)) {
            helper.filterOptionsForBOBorWholesaleAccount(component);
        }
    },
    /**
     * Edition field changed
     * Level 2
     */
    editionChanged: function (component, event, helper) {
        var type = component.get('v.type');
        var edition = component.get('v.edition');

        var app = component.get('v.app');
        app.setEdition(edition);
        component.set('v.app', app);

        if (!helper.isUpsell(type)) {
            component.set('v.plan', '');
            helper.selectTierByFields(component);
        }
        helper.proceedFields(component);
        helper.clearErrors(component);
        helper.checkNotifications(component);
    },
    /**
     * Plan field changed
     * Level 3
     */
    planChanged: function (component, event, helper) {
        var type = component.get('v.type');
        var plan = component.get('v.plan');

        var app = component.get('v.app');
        app.setPlan(plan);
        component.set('v.app', app);

        if (!helper.isUpsell(type)) {
            helper.selectTierByFields(component);
        }
        helper.proceedFields(component);
        helper.clearErrors(component);
        helper.checkNotifications(component);
    },
    /**
     * Forecasted Users field changed
     */
    newTotalUsersChanged: function (component, event, helper) {
        clearTimeout(helper.newTotalUsersKeyUpTimeout);
        helper.newTotalUserskeyUpTimeout = setTimeout($A.getCallback(() => {
            let newTotalUsers = component.get('v.newTotalUsers');
            let type = component.get('v.type');

            let app = component.get('v.app');
            app.setNewTotalUsers(newTotalUsers);
            app.validateNewTotalUsers();
            component.set('v.app', app);
            helper.showInputErrors(component);
            if (!helper.isUpsell(type)) {
                helper.selectTierByFields(component, newTotalUsers);
            }
            helper.proceedFields(component);
            helper.checkNotifications(component);
        }), 300);
    },

    forecastedUsersChanged: function (component, event, helper) {
        clearTimeout(helper.forecastedUsersKeyUpTimeout);
        helper.forecastedUsersKeyUpTimeout = setTimeout($A.getCallback(() => {
            let app = component.get('v.app');
            app.setForecastedUsers(component.get('v.forecastedUsers'));
            component.set('v.app', app);

            let type = component.get('v.type');
            if (!helper.isUpsell(type)) {
                helper.selectTierByFields(component);
            }
            helper.proceedFields(component);
            helper.checkNotifications(component);
        }), 300);
    },

    selectedAccountLookupChanged: function (component) {
        component.set('v.selectedAccount', component.get('v.selectedAccountLookup.RecordObj'));
    },

    selectedAccountChanged: function (component, event, helper) {
        var selectedAccount = component.get('v.selectedAccount');

        helper.switchToNgbs(component);

        var app = component.get('v.app');
        app.setAccount(selectedAccount);
        component.set('v.app', app);

        var opportunityName = component.get('v.opportunityName');
        helper.setPrimaryContactLookupParams(component);
        helper.setConversionContactLookupParams(component);
        if (selectedAccount) {
            // update opportunity name
            if (!opportunityName) {
                component.set('v.opportunityName', selectedAccount.Name);
            }

            if (helper.contactPreselectionFromURL) {
                helper.contactPreselectionFromURL = false;
                helper.preselectContactFromURL(component);
            }

            helper.proceedAccount(component);
        } else {
            // No account, discard everything
            helper.discardAccount(component);
        }

        helper.proceedFields(component);
        helper.checkNotifications(component);
    },

    biChanged: function(component) {
        const biMapping = component.get('v.biMapping');
        const biKey = component.get('v.selectedBusinessIdentity');
        const defaultBrand = biMapping && biMapping[biKey] && biMapping[biKey].defaultBrand;
        component.set('v.brand', defaultBrand);
    },

    selectedContactLookupChanged: function (component) {
        component.set('v.selectedContact', component.get('v.selectedContactLookup.RecordObj'));
    },

    selectedConvConLookupChanged: function (component) {
        component.set('v.selectedConversionContact', component.get('v.selectedConversionContactLookup.RecordObj'));
    },

    selectedContactChanged: function (component, event, helper) {
        var selectedContact = component.get('v.selectedContact');
        var app = component.get('v.app');
        app.setContact(selectedContact);
        component.set('v.app', app);
    },

    selectedConversionContactChanged: function (component, event, helper) {
        var selectedConversionContact = component.get('v.selectedConversionContact');
        var app = component.get('v.app');
        app.setContact(selectedConversionContact);
        component.set('v.app', app);
    },

    selectedTierChanged: function (component, event, helper) {
        var app = component.get('v.app');
        app.setSelectedServicePlan(component.get('v.selectedTier'));
        component.set('v.app', app);
    },

    /**
     * Discard button pressed
     */
    discardForm: function (component, event, helper) {
        helper.discardForm(component);
        helper.proceedFields(component);
    },

    leadSourceChanged: function(component, event, helper) {
    },

    closeDateChanged: function (component, event, helper) {
        var app = component.get('v.app');
        var date = component.get('v.closeDate')
        app.setCloseDate(date);
        component.set('v.app', app);
    },

    opportunityNameChanged: function (component, event, helper) {
        var app = component.get('v.app');
        app.setOpportunityName(component.get('v.opportunityName'));
        component.set('v.app', app);
    },

    /**
     * User selects tier from dropdown
     */
    pickTier: function (component, event, helper) {
        var index = event.currentTarget.dataset.index;
        var tiersToPick = component.get('v.tiersToPick');
        var selectedTier = tiersToPick[index];

        component.set('v.selectedTier', selectedTier);
        component.set('v.selectedTierLabel', selectedTier.Pricebook2.Name || '');

        helper.closeTierPicker(component);
    },
    /**
     * Open/Close dropdown to select tier
     */
    toggleTierPicker: function (component, event, helper) {
        var tiersToPick = component.get('v.tiersToPick');
        if (tiersToPick.length > 0) {
            var tierPicker = component.find('tierPicker');
            $A.util.toggleClass(tierPicker, 'slds-hide');
        }
    },
    /**
     * Changed values in Select Service Plan Picklist
     */
    tiersToPickChanged: function (component, event, helper) {
        var tiersToPick = component.get('v.tiersToPick');
        if (tiersToPick.length > 0) {
            helper.tierPickerActive(component);
            helper.openTierPicker(component);
        } else {
            helper.tierPickerInactive(component);
            helper.closeTierPicker(component);
        }
    },
    /*
     * Cancel Button Clicked
     */
    cancel: function (component, event, helper) {
        var retURL = component.get('v.retURL');
        if (retURL) {
            window.open(retURL, '_parent');
        } else {
            history.back();
        }
    },

    mainAreaCodeObjChanged: function (component, event, helper) {
        var app = component.get('v.app');

        app.setMainAreaCode(component.get('v.mainAreaCodeObj.RecordObj'));

        helper.proceedFields(component);
        component.set('v.app', app);
    },

    confirmAndClose: function (component, event, helper) {
        if (helper.validateConfirmAndClose(component)) {
            helper.createOpportunityProcess(component, true);
        }
    },

    isMainPhoneVanityChanged: function (component, event, helper) {
        var app = component.get('v.app');
        if (!app) return;
        app.setMainAreaCodeIsVanity(component.get('v.isMainPhoneVanity'));
        component.set('v.app', app);
    },

    selectedAccountTierChanged: function (component) {
        var app = component.get('v.app');
        app.setSelectedAccountTier(component.get('v.selectedAccountTier'));
        component.set('v.app', app);
    },

    numberOfLinesChanged: function (component) {
        var app = component.get('v.app');
        app.setNumberOfLines(component.get('v.numberOfLines'));
        component.set('v.app', app);
    },

    shippingLocationChanged: function (component, event, helper) {
        var shippingLocation = component.get('v.shippingLocation');
        var app = component.get('v.app');
        app.setShippingLocation(shippingLocation);
        component.set('v.app', app);
    },

    onShippingLocationClick: function (component, event, helper) {
        let app = component.get('v.app');
        app.clearShippingAddressErrors();
        component.set('v.app', app);
    },

    provisioningDetailsChanged: function (component, event, helper) {
        let app = component.get('v.app');
        app.setProvisioningDetails(component.get('v.provisioningDetails'));
        component.set('v.app', app);
    },

    inputParamsChanged: function(component, event, helper) {
        component.set('v.isTriggerSwitch', false);

        const fields = event.getParam('value');
        component.set('v.selectedAccountId', fields.accountSfId);
        component.set('v.selectedContactId', fields.contactSfId);
        component.set('v.selectedConversionContactId', fields.conversionContactSfId);
        component.set('v.opportunityName', fields.opportunityName);
        component.set('v.closeDate', fields.closeDate);
        component.set('v.leadSource', fields.leadSource);
        component.set('v.shippingLocation', fields.shippingLocation);
        component.set('v.provisioningDetails', fields.provisioningDetails);
        component.set('v.brand', fields.brand);
        component.set('v.service', fields.service);

        if (fields.businessIdentity) {
            const biKey = helper.buildBusinessIdentityKey(fields.businessIdentity);
            component.set('v.selectedBusinessIdentity', biKey);
        }

        component.set('v.isTriggerSwitch', true);
        // helper.switchToNgbs(component);
    }
});