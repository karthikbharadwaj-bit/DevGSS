({
    initApp: function (component) {
        var app = new OC.classes.App();
        app.brandConfigurations = component.get('v.brandConfiguration');
        app.setOpportunityRecordType({
            Name: component.get('v.recordTypeName'),
            Id: component.get('v.recordTypeId')
        });

        component.set('v.app', app);

    },

    initAttributes: function (component) {
        //added new attribute for Selected Tier Label and moved logic from layout to class
        component.set('v.selectedTierLabel', '--None--');

        // Picklist options for Lead Source
        component.set('v.leadSourceOpts', this.createOpts(component.get('v.leadSourceValues')));

        // Picklist options and default value for Contact Role Values
        component.set('v.contactRoleOpts', this.createOpts(component.get('v.contactRoleValues')));
        component.set('v.contactRole', 'Signatory');

        component.set('v.noQuoteForBrands', ['AT&T Office@Hand']);
        component.set('v.noQuoteForServices', ['Professional', 'Fax']);

        component.set('v.biOptions', this.buildBusinessIdentityOptions(component.get('v.biValues')));
        component.set('v.biMapping', this.initBiMapping(component.get('v.biValues')));
    },

    buildBusinessIdentityOptions: function(biValues) {
        const biOptions = biValues && biValues.length && biValues.map((bi) => {
            const biValue = this.buildBusinessIdentityKey(bi);
            return {value: biValue, label: bi.biName};
        });
        return biOptions || [];
    },

    initBiMapping: function(biValues) {
        const biIdKeyToBrandMap = biValues && biValues.length && biValues.reduce((result, el) => {
            const key = this.buildBusinessIdentityKey(el);
            result[key] = el;
            return result;
        }, {});
        return biIdKeyToBrandMap || {};
    },

    buildBusinessIdentityKey: function(biData) {
        const cur = biData && biData.cur || biData.currency;
        return `${biData.biName}_${cur}_${biData.biId}`;
    },

    buildBusinessIdentityInfo: function(biKey) {
        if (biKey && biKey.length) {
            const [biName, currency, biId] = biKey.split('_');
            return {
                biName,
                currency,
                biId,
            };
        }
        return null;
    },

    initServicePlanSectionNotifications: function (component) {
        let notificationsServicePlan = [
            {
                text: () => {
                    let rcTier = component.get('v.selectedAccount.RC_Tier__c');
                    let wasnt = "wasn't"; // Unterminated string 't found...
                    return `Service Plan "${rcTier}" ${wasnt} found. Please switch from Up-Sell to Upgrade to create an Opportunity`
                },
                type: 'error',
                check: () => this.isUpsell(component.get('v.type')) && component.get('v.accountServicePlanNotFound')
            },
            {
                text: () => {
                    var min = component.get('v.selectedAccountTier.Pricebook2.Line_Range_Min__c');
                    var max = component.get('v.selectedAccountTier.Pricebook2.Line_Range_Max__c');

                    return `You need to do an Upgrade to support this number of users. Service Plan on this Account supports between ${min} and ${max} number of Users`;
                },
                type: 'info',
                check: () => component.get('v.app').isUpgradeRequired(component)
            },
            {
                text: () => component.get('v.app.noQuoteMessage'),
                type: 'error',
                check: () => !component.get('v.app').isQuoteAutoCreationSupported(component)
            }
        ];
        this.setComponentValue(component.find('notificationsServicePlan'), 'v.notifications', notificationsServicePlan)
    },

    initOpportunityInfoSectionNotifications: function (component) {
        let notificationsOpportunityInfo = [
            {
                text: () => 'You can\'t proceed with Opportunity Creation. There are no Primary or Signatory Contacts under selected Account.',
                type: 'error',
                check: () => component.get('v.selectedAccount')
                    && !this.getContactIdToPreselect(component)
                    && component.get('v.app.featureToggle.OpptyContactRoleSelectorUpdate__c')
            },
        ];
        this.setComponentValue(component.find('notificationsOpportunityInfo'), 'v.notifications', notificationsOpportunityInfo)
    },

    getOpportunityCreationParams: function (component) {
        // Set Params
        var selectedAccount = component.get('v.selectedAccount');
        var selectedAccountId = selectedAccount ? selectedAccount.Id : null;
        var selectedContact = component.get('v.selectedContact');
        var selectedContactId = selectedContact ? selectedContact.Id : null;
        var selectedConversionContact = component.get('v.selectedConversionContact');
        var selectedConversionContactId = selectedConversionContact ? selectedConversionContact.Id : null;
        var opportunityName = component.get('v.opportunityName');
        var upsellType = component.get('v.type');
        var leadSource = component.get('v.leadSource');
        var brand = component.get('v.brand');
        var service = component.get('v.service');
        var closeDate = component.get('v.closeDate');
        var forecastedUsers = component.get('v.forecastedUsers') || '0';
        var newTotalUsers = component.get('v.newTotalUsers') || 0;
        var recordTypeId = component.get('v.recordTypeId');
        var isBillingOpty = service === RC.CONSTANTS.OPPORTUNITY.TIER_NAME.RC_MEETINGS;
        var currentDLsFromEntitlements = component.get('v.numberOfLines');
        var contactRole = component.get('v.contactRole');
        var retention = component.get('v.retention');
        var provisioningDetails = component.get('v.provisioningDetails');
        var fromContact = component.get('v.fromContact');
        var fromContactId = component.get('v.fromContactId');
        var fromConversionContact = component.get('v.fromConversionContact');
        var fromConversionContactId = component.get('v.fromConversionContactId');
        var contactCenterUsers = component.get('v.contactCenterUsers');
        var engageDigitalUsers = component.get('v.engageDigitalUsers');
        var engageVoiceUsers = component.get('v.engageVoiceUsers');
        var globalOfficeUsers = component.get('v.globalOfficeUsers');
        var officeUsers = component.get('v.officeUsers');
        var rcVideoUsers = component.get('v.rcVideoUsers');
        var oppCreationFlow = component.get('v.oppCreationFlow');
        var buddyOpportunityId = component.get('v.buddyOpportunityId');
        var campaignId = component.get('v.campaignId');

        forecastedUsers = this.getForecastedUsers({
            forecastedUsers: forecastedUsers,
            type: upsellType,
            newTotalUsers: newTotalUsers,
            currentDL: currentDLsFromEntitlements || selectedAccount.Number_of_DL_s__c || 0
        });

        var params = {
            name: opportunityName,
            accountId: selectedAccountId,
            contactId: selectedContactId,
            conversionContactId: selectedConversionContactId,
            brandName: brand,
            service: service,
            closeDate: closeDate,
            stageName: RC.CONSTANTS.OPPORTUNITY.STAGE_NAME.QUALIFY,
            recordTypeId: recordTypeId,
            leadSource: leadSource,
            forecastedUsers: String(forecastedUsers),
            isBillingOpportunity: isBillingOpty,
            contactRole: contactRole,
            retention: retention,
            provisioningDetails: provisioningDetails,
            fromContact: fromContact,
            fromContactId: fromContactId,
            fromConversionContact: fromConversionContact,
            fromConversionContactId: fromConversionContactId,
            contactCenterUsers: contactCenterUsers,
            engageDigitalUsers: engageDigitalUsers,
            engageVoiceUsers: engageVoiceUsers,
            globalOfficeUsers: globalOfficeUsers,
            officeUsers: officeUsers,
            rcVideoUsers: rcVideoUsers,
            oppCreationFlow: oppCreationFlow,
            buddyOpportunityId: buddyOpportunityId,
            campaignId: campaignId,
        };

        if (this.isUpsell(upsellType) || this.isUpgrade(upsellType)) {
            params.type = 'Existing Business';
        } else {
            params.type = 'New Business';
        }

        return params;
    },
    getCreateQuoteParams: function (component, opportunityId) {
        // Set Params
        var selectedTier = component.get('v.selectedTier');
        var selectedAccount = component.get('v.selectedAccount');
        var isBtBusinessUpsell = this.checkForBTUpsell(selectedAccount);
        var isTelusUpsell = this.checkForTelusUpsell(selectedAccount);
        var upsellType = component.get('v.type');
        var forecastedUsers = component.get('v.forecastedUsers') || '0';
        var newTotalUsers = component.get('v.newTotalUsers') || 0;
        var selectedAccountTier = component.get('v.selectedAccountTier');
        var currentDLsFromEntitlements = component.get('v.numberOfLines');
        var app = component.get('v.app');

        if (!isBtBusinessUpsell && !isTelusUpsell) {
            forecastedUsers = this.getForecastedUsers({
                forecastedUsers: forecastedUsers,
                type: upsellType,
                newTotalUsers: newTotalUsers,
                currentDL: currentDLsFromEntitlements || selectedAccount.Number_of_DL_s__c || 0,
            });
        }

        var params = {
            opportunityId: opportunityId,
            mainAreaCodeId: component.get('v.selectedMainAreaCodeId') || null,
            isMainPhoneVanity: '' + !!component.get('v.isMainPhoneVanity'),
            shippingCountry:                app.shippingLocation.country,
            shippingCity:                   app.shippingLocation.city,
            shippingState:                  app.shippingLocation.state,
            shippingAddressLine:            app.shippingLocation.addressLine,
            shippingPostalCode:             app.shippingLocation.postalCode,
            shippingShippingOption:         app.shippingLocation.shippingOption,
            shippingShipAttentionTo:        app.shippingLocation.shipAttentionTo,
            shippingAdditionalAddressLine:  app.shippingLocation.additionalAddressLine,
            shippingCustomerName:           app.shippingLocation.customerName,
            shippingMultipleLocations:      '' + !!app.shippingLocation.multipleLocations,
            isCC:                           selectedTier.Pricebook2.Service__c === OC.CONSTANTS.OPPORTUNITY.TIER_NAME.CC
        };

        if (this.isUpsell(upsellType)) {
            params.tierId = selectedAccountTier.Pricebook2.Id;
        } else {
            params.tierId = selectedTier.Pricebook2.Id;
        }

        if (this.isUpsell(upsellType) || this.isUpgrade(upsellType)) {
            params.type = 'Existing Business';
            params.lines = String(newTotalUsers);
            params.upsellStatus = this.normalizeUpsellType(upsellType);

            if (this.isUpsell(upsellType) && Number(forecastedUsers) > 0) {
                params.additionalForecastedUsers = String(forecastedUsers);

                // params to add Service plan to cart
                params.UnitPrice = String(selectedTier.UnitPrice);
                params.pbeId = selectedTier.Id;
                params.productId = selectedTier.Product2Id;
            }

            if (selectedTier && selectedAccountTier && this.isUpgrade(upsellType) && (selectedTier.Pricebook2.Id == selectedAccountTier.Pricebook2.Id)) {
                params.upsellStatus = "Upsell";
            }

        } else {
            params.type = 'New Business';
            params.lines = String(forecastedUsers);
        }

        params._forecastedUsers = String(forecastedUsers);
        return params;
    },

    createOpportunityProcess: function (component, isConfirmAndClose) {
        var app = component.get('v.app');
        var opportunityId = null;
        var quoteId = null;
        var helper = this;
        var createQuoteParams = null;
        var isOpportunityCreationError = false;
        var isOpportunityCreatedWithError = false;
        var qlisFromEntitlements = {};

        var existingCustomerProcess = function (component, createQuoteResult) {
            var qliParams = {
                accountId: component.get("v.selectedAccount.Id"),
                opportunityId: opportunityId,
                quoteId: createQuoteResult.quoteId,
                type: createQuoteParams.upsellStatus,
                quantity: String(app.addedSoftphonesQty),
            };

            if(app.mainAreaCode) {
                qliParams.mainAreaCodeId = RC.Product2Helper.isAreaCodeValidForSoftphone(app.mainAreaCode)
                                            ? app.mainAreaCode.Id
                                            : '';
            }

            // Upsell
            if (helper.isUpsell(createQuoteParams.upsellStatus)) {
                qliParams.additionalForecastedUsers = createQuoteParams._forecastedUsers;
                qliParams.pricebook2Id = app.selectedServicePlan.record.Pricebook2Id;
            }

            // Upgrade
            else if (helper.isUpgrade(createQuoteParams.upsellStatus)) {
                qliParams.pricebook2Id = app.selectedServicePlan.record.Pricebook2Id;
            }

            OC.spinner.show('Creating Quote Line Items from Entitlements');
            return OC.salesforce.request(component, 'c.addEntitlementsAsLineItems', {
                params: qliParams
            })
                .then($A.getCallback(function (qlis) {
                    qlis.forEach(function (qli) {
                        qlisFromEntitlements[qli.PricebookEntryId] = qli.Id;
                    });
                }))
                .then($A.getCallback(function () {
                    OC.spinner.show('Checking dependend Items');
                    return OC.salesforce.request(component, 'c.handleExtendedEnterpriseSupport', {
                        quoteId: createQuoteResult.quoteId
                    })
                }))
                .then($A.getCallback(function () {
                    if(app.selectedSoftphonesTotalQty == 0) {
                        OC.spinner.show('Adding Softphones');
                        return OC.salesforce.request(component, 'c.createAdditionalSoftphoneQLIs', {
                            params: qliParams
                        });
                    }
                }));
        };

        var newCustomerProcess = function (component, createQuoteResult) {

            var qliParams = {
                quoteId: createQuoteResult.quoteId,
                quantity: String(app.addedSoftphonesQty),
                pricebook2Id: createQuoteResult.pricebook2Id,
            };

            if(app.mainAreaCode) {
                qliParams.mainAreaCodeId = RC.Product2Helper.isAreaCodeValidForSoftphone(app.mainAreaCode)
                                            ? app.mainAreaCode.Id
                                            : '';
            }

            OC.spinner.show('Adding Softphones');
            if(app.selectedSoftphonesTotalQty == 0) {
                return OC.salesforce.request(component, 'c.createAdditionalSoftphoneQLIs', {
                    params: qliParams
                });
            }
        };

        OC.spinner.show('Creating Opportunity');
        this.setComponentValue(component.find('saveButton'), 'v.disabled', isConfirmAndClose);
        this.setComponentValue(component.find('saveButton'), 'v.isBusy', !isConfirmAndClose);
        this.setComponentValue(component.find('confirmAndCloseButton'), 'v.disabled', !isConfirmAndClose);
        this.setComponentValue(component.find('confirmAndCloseButton'), 'v.isBusy', isConfirmAndClose);
        var opportunityCreationParams = helper.getOpportunityCreationParams(component);

        var createOpportunityPromise = OC.salesforce.request(component, 'c.createOppty', {
                params: opportunityCreationParams
            })
            .then($A.getCallback(function (createOpptyResult) {
                opportunityId = createOpptyResult.opportunityId;
            }));

        // Create Quote
        if (app.isQuoteShouldBeCreated()) {
            createOpportunityPromise = createOpportunityPromise
                .then($A.getCallback(function () {
                    OC.spinner.show('Creating Quote');
                    createQuoteParams = helper.getCreateQuoteParams(component, opportunityId);

                    return OC.salesforce.request(component, 'c.createQuote', {
                        params: createQuoteParams
                    });
                }))
                .then($A.getCallback(function (createQuoteResult) {
                    quoteId = createQuoteResult.quoteId;
                    if (helper.isUpsell(createQuoteParams.upsellStatus)
                        || helper.isUpgrade(createQuoteParams.upsellStatus)) {
                        return existingCustomerProcess(component, createQuoteResult);

                    } else {
                        return newCustomerProcess(component, createQuoteResult);

                    }

                }));

            if (app.getProductsToAdd().length > 0 || app.getfeatureToQuantityMapToAdd()) {
                createOpportunityPromise = createOpportunityPromise
                    .then($A.getCallback(() => {
                        OC.spinner.show('Adding selected products');
                        app.increaseSoftphonesQty();
                        return RC.salesforce.request(component, 'c.addProductsWrapper', {
                            p: JSON.stringify({
                                featureToQuantityMap: app.getfeatureToQuantityMapToAdd(),
                                quoteId: quoteId,
                                productsToAdd: app.getProductsToAdd(),
                                qlisFromEntitlements: qlisFromEntitlements
                            })
                        })
                    }))
            }

            if (isConfirmAndClose) {
                createOpportunityPromise = createOpportunityPromise
                    .then($A.getCallback(() => {
                        OC.spinner.show('Confirm & Close');
                        return RC.salesforce.request(component, 'c.confirmAndCloseOppty', {
                            opportunityId: opportunityId,
                            quoteId: quoteId
                        });
                    }));
            }
        }

        createOpportunityPromise
        // Update Task
            .then($A.getCallback(function () {
                var updateTaskParams = {
                    taskId: component.get("v.taskId"),
                    opportunityId: opportunityId
                };
                OC.salesforce.request(component, 'c.updateTask', {
                    params: updateTaskParams
                });
            }))
            // Catch Errors
            .catch($A.getCallback(function (error) {
                RC.salesforce.displayError('Error during opportunity creation', error);
                OC.spinner.hide();
                this.setComponentValue(component.find('saveButton'), 'v.disabled', false);
                this.setComponentValue(component.find('saveButton'), 'v.isBusy', false);
                this.setComponentValue(component.find('confirmAndCloseButton'), 'v.disabled', false);
                this.setComponentValue(component.find('confirmAndCloseButton'), 'v.isBusy', false);
                isOpportunityCreatedWithError = true;
            }))
            // Redirect User
            .then($A.getCallback(function () {
                if (opportunityId) {
                    window.open("/" + opportunityId, '_parent');

                    OC.spinner.show('Opportunity created. Redirecting...');

                    $A.get("e.c:ToastEvent").setParams({
                        theme: isOpportunityCreatedWithError ? 'warning' : 'success',
                        header: 'Opportunity created. Redirecting...'
                    }).fire();
                } else {
                    console.error('Opportunity Id is ' + opportunityId);
                }
            }));
    },

    getForecastedUsers: function (params) {
        var result = params.forecastedUsers; // forecastedUsers;
        var type = params.type; // component.get('v.type');
        var newTotalUsers = params.newTotalUsers; // component.get('v.newTotalUsers');
        var currentDL = params.currentDL; // component.get('v.selectedAccount').Number_of_DL_s__c;

        if (this.isUpsell(type) || this.isUpgrade(type)) {
            result = Number(newTotalUsers) - Number(currentDL);
        }

        return result;
    },

    isUpsell: function (upsellType) {
        // return upsellType === 'Up-Sell';
        return this.normalizeUpsellType(upsellType) === 'Upsell';
    },
    isUpgrade: function (upsellType) {
        return upsellType === 'Upgrade';
    },

    normalizeUpsellType: function (string) {
        var string = String(string) || '';
        var str = string.replace('-', '');
        str = str.toLowerCase();
        return this.capitalizeFirstLetter(str);
    },

    capitalizeFirstLetter: function (string) {
        return string.charAt(0).toUpperCase() + string.slice(1);
    },
    /**
     * Get values from fields and find Service Plan using them
     */
    selectTierByFields: function (component, lines) {
        var brand = component.get('v.brand');
        var service = component.get('v.service');
        var type = component.get('v.type');
        var forecastedUsers = component.get('v.forecastedUsers');
        var newTotalUsers = component.get('v.newTotalUsers');
        var noQuoteForBrands = component.get('v.noQuoteForBrands');
        var noQuoteForServices = component.get('v.noQuoteForServices');
        var selectedAccount = component.get('v.selectedAccount');
        var isBtBusinessUpsell = this.checkForBTUpsell(selectedAccount);
        var isTelusUpsell = this.checkForTelusUpsell(selectedAccount);
        var billingPackage = component.get('v.app.billingPackage');
        var lines = forecastedUsers;
        var tierId;

        if ((this.isUpsell(type) || this.isUpgrade(type)) && !isBtBusinessUpsell && !isTelusUpsell) {
            lines = newTotalUsers;
        }

        if (noQuoteForBrands.indexOf(brand) === -1 && noQuoteForServices.indexOf(service) === -1) {
            if (this.isUpsell(type) || this.isUpgrade(type)) {

                if (selectedAccount) {
                    if (billingPackage != null) {
                        tierId = billingPackage.RC_Tier_ID__c;
                    }
                    if (this.isUpsell(type)) {
                        lines = Number(forecastedUsers || 0) + Number(selectedAccount.Number_of_DL_s__c || 0);
                    }
                }
            }
            var params = {
                type: type,
                brand: brand,
                service: service,
                edition: component.get('v.edition'),
                plan: component.get('v.plan'),
                tierId: tierId
            };
            if (lines || lines === 0) {
                params.lines = lines;
            }
            this.selectTier(component, params);
        } else {
            component.set('v.selectedTier', null);
            component.set('v.selectedTierLabel', '--None--');
        }
    },
    preSelectBillingTier: function (component, params) {
        const brand = component.get('v.brand');
        component.set('v.brandOpts', this.createOpts(component.get('v.brandValues')));
        const brands = this.getBrandValues([
            ...component.get('v.brandOpts'),
            { value: OC.CONSTANTS.OPPORTUNITY.BRAND_NAME.AVAYA }
        ]);
        const selectedAccount = component.get('v.selectedAccount');
        const isBtBusinessUpsell = this.checkForBTUpsell(selectedAccount);
        const isTelusUpsell = this.checkForTelusUpsell(selectedAccount);
        const telusServiceValues = ['Contact Center', 'TELUS Office'];

        if (!selectedAccount.RC_Brand__c) {
            selectedAccount.RC_Brand__c = OC.CONSTANTS.OPPORTUNITY.BRAND_NAME.RC_US;
            component.set('v.brand', selectedAccount.RC_Brand__c);
            }
            else{
                component.set('v.brand', selectedAccount.RC_Brand__c);
            }

        if (isBtBusinessUpsell || isTelusUpsell) {
            component.set('v.type', 'Up-Sell');
            component.set('v.typeOpts', this.createOpts(['Up-Sell', 'Upgrade']));
            component.set('v.brand', selectedAccount.RC_Brand__c);

            if (selectedAccount.RC_Service_name__c && selectedAccount.RC_Service_name__c !== null) {
                component.set('v.service', !isTelusUpsell
                                             ? selectedAccount.RC_Service_name__c
                                             : telusServiceValues.includes(selectedAccount.RC_Service_name__c)
                                                    ? selectedAccount.RC_Service_name__c
                                                    : 'Contact Center');
                component.set('v.serviceOpts', !isTelusUpsell ? this.createOpts([selectedAccount.RC_Service_name__c]) : this.createOpts(telusServiceValues));
                component.set('v.edition', selectedAccount.RC_Service_name__c);
                component.set('v.editionOpts', this.createOpts([selectedAccount.RC_Service_name__c]));
            }

            if (selectedAccount.Payment_Plan__c && selectedAccount.Payment_Plan__c !== null) {
                component.set('v.plan', selectedAccount.Payment_Plan__c);
                component.set('v.planOpts', this.createOpts([selectedAccount.Payment_Plan__c]));
            }

            var params = {
                brand: selectedAccount.RC_Brand__c,
                service: selectedAccount.RC_Service_name__c,
                plan: isTelusUpsell ? selectedAccount.Payment_Plan__c : null
            };
            this.selectTier(component, params);
            component.set('v.selectedAccountTier', component.get('v.selectedTier'));
            component.set('v.selectedTierLabel', selectedAccount.RC_Brand__c);
            return true;
        }
        return false;
    },

    checkForBTUpsell: function (selectedAccount) {
        return selectedAccount
                && selectedAccount.RC_Brand__c
                && selectedAccount.RC_Brand__c === OC.CONSTANTS.OPPORTUNITY.BRAND_NAME.BT_BUSINESS
                && selectedAccount.RC_User_ID__c;
    },

    checkForTelusUpsell: function (selectedAccount) {
        let res = selectedAccount
                && selectedAccount.RC_Brand__c
                && selectedAccount.RC_Brand__c === OC.CONSTANTS.OPPORTUNITY.BRAND_NAME.TELUS;

        return res;
    },
    /**
     * Filter tiers with selected parameters
     */
    selectTier: function (component, params) {
        var tiers = component.get('v.tiers');
        var brand = params.brand;
        var service = params.service;
        var edition = params.edition;
        var plan = params.plan;
        var lines = params.lines && Number(params.lines);
        var tierId = params.tierId;
        var type = params.type;
        var serviceType = params.serviceType;

        var servicesWithoutCheckingDLs = ['Professional', 'Fax'];

        var filterLevel = 0;
        var serviceOpts = [];
        var editionOpts = [];
        var planOpts = [];
        var fTiers = [];

        if (brand) {
            filterLevel = 1;
            if (service) {
                filterLevel = 2;
                if (edition) {
                    filterLevel = 3;
                    if (plan) {
                        filterLevel = 4;
                    }
                }
            }
        }

        /* New Logic */
        var foundTiers = tiers;

        // Filters by plan if it exists
        foundTiers = foundTiers.filter(function (tier) {
            return !plan || tier.Product2.Charge_Term__c === plan
        });

        if (this.isUpsell(type)) {
            // Filter by the same tier
            foundTiers = foundTiers.filter(function (tier) {
                return tier.Pricebook2.Tier_ID__c === tierId
            });

            // Filter by lines
            if (servicesWithoutCheckingDLs.indexOf(serviceType) === -1) {
                foundTiers = foundTiers.filter(function (tier) { return lines <= tier.Pricebook2.Line_Range_Max__c });
            }

        }
        else {
            // filters by brand, service, edition if they exist
            foundTiers = foundTiers.filter(function (tier) {
                return !brand || tier.Pricebook2.Brand__r && tier.Pricebook2.Brand__r.Name === brand
            });
            foundTiers = foundTiers.filter(function (tier) {
                return !service || tier.Pricebook2.Brand__r && tier.Pricebook2.Service__c === service
            });
            foundTiers = foundTiers.filter(function (tier) {
                return !edition || tier.Pricebook2.Brand__r && tier.Pricebook2.Edition__c === edition
            });

            // Filter by the same tier or by active
            foundTiers = foundTiers.filter(function (tier) {
                return (tier.Pricebook2.Tier_ID__c === tierId) || (tier.Pricebook2.IsActive)
            });

            // Filter by lines in tier range
            foundTiers = foundTiers.filter(function (tier) {
                return !lines || (lines >= tier.Pricebook2.Line_Range_Min__c && lines <= tier.Pricebook2.Line_Range_Max__c)
            });

        }


        // add values to picklists
        foundTiers.forEach(function (tier) {
            if (tier.Pricebook2.Service__c) serviceOpts.push(tier.Pricebook2.Service__c);
            if (tier.Pricebook2.Edition__c) editionOpts.push(tier.Pricebook2.Edition__c);
            if (tier.Product2.Charge_Term__c && !planOpts.includes(tier.Product2.Charge_Term__c)) {
                planOpts.push(tier.Product2.Charge_Term__c);
                planOpts.sort();
            }
        });

        fTiers = foundTiers;

        // For Fax and Pro tiers when we can't select tier
        // additionally filter with Account.Service_Type__c field

        if (fTiers.length > 1 && serviceType) {
            fTiers = fTiers.filter(function (tier) {
                if (tier.Pricebook2.Service__c === serviceType) {
                    return true;
                }
            });
        }
        var selectedTier = null;
        if (fTiers.length === 1) {
            selectedTier = fTiers[0];
            component.set('v.tiersToPick', []);

        } else {
            // Select Service Plan picklist
            // Allow upgrade to tier with the same tier id
            if (filterLevel === 4 && lines) {
                component.set('v.tiersToPick', fTiers);
            } else {
                component.set('v.tiersToPick', []);
            }

        }
        component.set('v.selectedTier', selectedTier);
        if (selectedTier && selectedTier.Pricebook2 && selectedTier.Pricebook2.Name !== null) {
            component.set('v.selectedTierLabel', selectedTier.Pricebook2.Name);
        } else if (service === RC.CONSTANTS.OPPORTUNITY.TIER_NAME.RC_MEETINGS) {
            component.set('v.selectedTierLabel', service);
        } else {
            component.set('v.selectedTierLabel', '--None--');
        }


        // only unique options
        function onlyUnique(value, index, self) {
            return self.indexOf(value) === index;
        }

        serviceOpts = serviceOpts.filter(onlyUnique);
        editionOpts = editionOpts.filter(onlyUnique);
        planOpts = planOpts.filter(onlyUnique);

        // set fields Opts
        // depending on filter level
        switch (filterLevel) {
            case 1:
                //component.set('v.serviceOpts',this.createOpts(serviceOpts));
                break;
            case 2:

                component.set('v.editionOpts', this.createOpts(editionOpts));
                break;
            case 3:

                component.set('v.planOpts', this.createOpts(planOpts));
                break;
        }
    },
    /**
     * Enable/disable fields on form
     */
    proceedFields: function (component) {
        var retention = component.get('v.retention');
        var selectedAccount = component.get('v.selectedAccount');
        var type = component.get('v.type');
        var brand = component.get('v.brand');
        var service = component.get('v.service');
        var edition = component.get('v.edition');
        var editionOpts = component.get('v.editionOpts');
        var mainAreaCodeObjRecord = component.get('v.mainAreaCodeObj.RecordObj');
        var app = component.get('v.app');

        // disable/enable vars
        var contactFieldDisabled = true;
        var conversionContactFieldDisabled = true;
        var typeFieldDisabled = true;
        var brandFieldDisabled = true;
        var businessIdentityFieldDisabled = true;
        var serviceFieldDisabled = true;
        var editionFieldDisabled = true;
        var planFieldDisabled = true;
        var closeDateFieldDisabled = false;
        var forecastedUsersFieldDisabled = true;
        var isMainAreaCodeDisabled = true;
        var isEditionFieldShown = true;
        var isPlanFieldShown = true;
        var isExistingUsersFieldShown = true;
        var isNewTotalUsersFieldShown = true;
        var forecastedUsersFieldIsShown = true;
        var isMainPhoneVanityDisabled = true;

        // required vars
        var typeFieldRequired = false;
        var brandFieldRequired = false;
        var businessIdentityFieldRequired = false;
        var serviceFieldRequired = false;
        var editionFieldRequired = false;
        var planFieldRequired = false;
        var forecastedUsersFieldRequired = false;

        var noQuoteForBrands = component.get('v.noQuoteForBrands');
        var noQuoteForServices = component.get('v.noQuoteForServices');

        if (retention) {
            this.setComponentValue(component.find('accountField'),'v.disabled', true);
        }
        if (selectedAccount) {
            contactFieldDisabled = false;
            conversionContactFieldDisabled = false;

            // Type field
            if (this.isUpsell(type) || this.isUpgrade(type)) {
                typeFieldDisabled = false;
                typeFieldRequired = true;
            }

            // Brand field
            if (type && !(this.isUpsell(type) || this.isUpgrade(type))) {
                brandFieldDisabled = false;
                brandFieldRequired = true;

                businessIdentityFieldDisabled = false;
                businessIdentityFieldRequired = true;
            }
            //B-4486 RC Meetings disable Notifications
            // Forecasted users
            if (
                brand !== RC.CONSTANTS.OPPORTUNITY.BRAND_NAME.BT_BUSINESS
                && brand !== RC.CONSTANTS.OPPORTUNITY.BRAND_NAME.TELUS
            ) {
                if (!service || noQuoteForServices.indexOf(service) === -1) {
                    if (service !== RC.CONSTANTS.OPPORTUNITY.TIER_NAME.RC_MEETINGS) {
                        forecastedUsersFieldDisabled = false;
                        if (!this.isUpsell(type)) {
                            forecastedUsersFieldRequired = true;
                        }
                    }
                }
            }

            if (
                brand === RC.CONSTANTS.OPPORTUNITY.BRAND_NAME.BT_BUSINESS
                || brand === RC.CONSTANTS.OPPORTUNITY.BRAND_NAME.TELUS
                || service === RC.CONSTANTS.OPPORTUNITY.TIER_NAME.RC_MEETINGS
            ) {
                forecastedUsersFieldIsShown = false;
            }


            if (brand) {
                isMainAreaCodeDisabled = false;
                if (noQuoteForBrands.indexOf(brand) === -1 && !this.isUpsell(type)) {
                    if (!this.isUpgrade(type)) {
                        serviceFieldDisabled = false;
                        serviceFieldRequired = true;
                    }
                    if (service) {
                        if (noQuoteForServices.indexOf(service) === -1 && !this.isUpsell(type)) {
                            if (
                                service !== RC.CONSTANTS.OPPORTUNITY.TIER_NAME.RC_MEETINGS
                                && brand !== RC.CONSTANTS.OPPORTUNITY.BRAND_NAME.BT_BUSINESS
                                && brand !== RC.CONSTANTS.OPPORTUNITY.BRAND_NAME.TELUS
                                && !component.get('v.isQuoteCreationLocked')
                            ) {
                                if (editionOpts.length !== 0) {
                                    editionFieldRequired = true;
                                }
                                    editionFieldDisabled = false;
                                if (edition) {
                                    planFieldDisabled = false;
                                    planFieldRequired = true;
                                }
                            }
                        }
                    }
                }

                if (mainAreaCodeObjRecord && mainAreaCodeObjRecord.Type__c === 'Toll-Free') {
                    isMainPhoneVanityDisabled = false;
                }

                if (this.checkForTelusUpsell(selectedAccount)) {
                    serviceFieldDisabled = false;
                }
            }
        }

        this.setComponentValue(component.find('contactField'), 'v.disabled', contactFieldDisabled);
        this.setComponentValue(component.find('conversionContactField'), 'v.disabled', conversionContactFieldDisabled);

        if (!app.featureToggle.OpptyContactRoleSelectorUpdate__c && component.find('contactRole')) {
            this.setComponentValue(component.find('contactRole'), 'v.disabled', contactFieldDisabled);
        }
        this.setComponentValue(component.find('typeField'), 'v.disabled', typeFieldDisabled);
        this.setComponentValue(component.find('brandField'), 'v.disabled', brandFieldDisabled);
        this.setComponentValue(component.find('serviceField'), 'v.disabled', serviceFieldDisabled);
        this.setComponentValue(component.find('editionField'), 'v.disabled', editionFieldDisabled);
        this.setComponentValue(component.find('planField'), 'v.disabled', planFieldDisabled);
        this.setComponentValue(component.find('closeDateField'), 'v.disabled', closeDateFieldDisabled);
        this.setComponentValue(component.find('forecastedUsersField'), 'v.disabled', forecastedUsersFieldDisabled);
        this.setComponentValue(component.find('mainAreaCode'), 'v.disabled', isMainAreaCodeDisabled);
        this.setComponentValue(component.find('isMainPhoneVanity'), 'v.disabled', isMainPhoneVanityDisabled);
        this.setComponentValue(component.find('biField'), 'v.disabled', businessIdentityFieldDisabled);

        if (isMainPhoneVanityDisabled) {
            component.set('v.isMainPhoneVanity', false);
        }
        if (isMainAreaCodeDisabled) {
            component.set('v.selectedMainAreaCodeId', '');
        }

        if (typeof RC === 'undefined') return;
        RC.cssUtils.toggleClass(component, 'typeField', typeFieldRequired, 'field-required');
        RC.cssUtils.toggleClass(component, 'brandField', brandFieldRequired, 'field-required');
        RC.cssUtils.toggleClass(component, 'serviceField', serviceFieldRequired, 'field-required');
        RC.cssUtils.toggleClass(component, 'editionField', editionFieldRequired, 'field-required');
        RC.cssUtils.toggleClass(component, 'planField', planFieldRequired, 'field-required');
        RC.cssUtils.toggleClass(component, 'forecastedUsersField', forecastedUsersFieldRequired, 'field-required');
        RC.cssUtils.toggleShow(component, 'forecastedUsersField', forecastedUsersFieldIsShown);
        RC.cssUtils.toggleShow(component, 'editionField', isEditionFieldShown);
        RC.cssUtils.toggleShow(component, 'planField', isPlanFieldShown);
        RC.cssUtils.toggleShow(component, 'existingUsersField', isExistingUsersFieldShown);
        RC.cssUtils.toggleShow(component, 'newTotalUsersField', isNewTotalUsersFieldShown);
        RC.cssUtils.toggleClass(component, 'biField', businessIdentityFieldRequired, 'field-required');
    },

    getServicePlanDetails: function (accountId, entitlements, component) {
        return OC.salesforce.request(component, 'c.getServicePricebookEntryByAccountEnts', {
            accountId: accountId
        })
        .then($A.getCallback(pricebookEntries => {
            if (!pricebookEntries || pricebookEntries.length === 0) {
                return;
            }
            let helper = this;
            let numberOfLines = 0;
            entitlements.forEach(function (entitlement) {
                if (pricebookEntries[0].Product2.Id === entitlement.Product__c) {
                    numberOfLines = entitlement.Quantity__c;
                }
            });

            component.set('v.selectedAccountTier', pricebookEntries[0]);
            component.set('v.selectedTier', pricebookEntries[0]);
            component.set('v.selectedTierLabel', pricebookEntries[0].Pricebook2.Name);
            component.set('v.brand', pricebookEntries[0].Pricebook2.Brand__r.Name);
            component.set('v.service', pricebookEntries[0].Pricebook2.Service__c);
            component.set('v.edition', pricebookEntries[0].Pricebook2.Edition__c);
            component.set('v.plan', pricebookEntries[0].Pricebook2.Plan__c);
            component.set('v.numberOfLines', numberOfLines);
            component.set('v.accountServicePlanNotFound', false);
            component.set('v.typeOpts', helper.createOpts(['Up-Sell', 'Upgrade']));
            component.set('v.type', 'Up-Sell');
        }));
    },

    getPaymentPlan: function (acc) {
        let accPlan = acc.Payment_Plan__c;
        if (
            accPlan === OC.CONSTANTS.ACCOUNT.PLAN.MONTHLY
            && acc.Sales_Agreement_Start_Date__c
            && acc.Sales_Agreement_End_Date__c
        ) {
            var oneDay = 24 * 60 * 60 * 1000; // hours*miinutes*seconds*milliseconds
            var startDate = new Date(acc.Sales_Agreement_End_Date__c);
            var endDate = new Date(acc.Sales_Agreement_Start_Date__c);
            var contractDays = Math.abs((startDate.getTime() - endDate.getTime()) / oneDay);

            if (contractDays && contractDays > 363) {
                return OC.CONSTANTS.ACCOUNT.PLAN.MONTHLY_CONTRACT;
            } else {
                return OC.CONSTANTS.ACCOUNT.PLAN.MONTHLY;
            }
        } else {
            return acc.Payment_Plan__c;
        }
    },

    accInfoProcess: function (component) {
        var selectedAccount = component.get('v.selectedAccount');
        var billingPackage = component.get('v.app.billingPackage');
        var isBtBusinessUpsell = this.checkForBTUpsell(selectedAccount);
        var isTelusUpsell = this.checkForTelusUpsell(selectedAccount);

        var typeOpts = [];
        var type = '';
        var brand = '';
        var service = '';
        var edition = '';
        var plan = '';
        var tierParams = {};
        var selectedTier;

        if (
            selectedAccount
            && selectedAccount.hasOwnProperty('RC_User_ID__c')
            && billingPackage != null
            && billingPackage.hasOwnProperty('RC_Tier_ID__c')
            && selectedAccount.hasOwnProperty('Payment_Plan__c')
            && (selectedAccount.hasOwnProperty('Number_of_DL_s__c') || billingPackage.hasOwnProperty('Service_Type__c'))
            && !isBtBusinessUpsell
            && !isTelusUpsell
        ) {
            //type field
            typeOpts = ['Up-Sell', 'Upgrade'];
            type = typeOpts[0]; // Up-Sell

            var setPlan = this.getPaymentPlan(selectedAccount);
            tierParams = {
                type: type,
                tierId: billingPackage.RC_Tier_ID__c,
                plan: setPlan,
                lines: selectedAccount.Number_of_DL_s__c,
            };
            if (billingPackage.Service_Type__c === 'Professional' || billingPackage.Service_Type__c === 'Fax') {
                tierParams.serviceType = billingPackage.Service_Type__c;
            }

            this.selectTier(component, tierParams);
            selectedTier = component.get('v.selectedTier');
            component.set('v.selectedAccountTier', selectedTier);
            component.set('v.accountServicePlanNotFound', selectedTier ? false : true);
            component.set('v.numberOfLines', selectedAccount.Number_of_DL_s__c);

            component.set('v.typeOpts', this.createOpts(typeOpts));
            component.set('v.type', type);
        } else if (!this.preSelectBillingTier(component, tierParams)) {

            // Type field
            typeOpts = ['New Business'];
            type = typeOpts[0];
            component.set('v.typeOpts', this.createOpts(typeOpts));
            component.set('v.type', type);

            this.proceedNewCustomer(component);
        }
    },

    /**
     * Get info from selected account, choose type
     */
    proceedAccount: function (component) {
        var selectedAccount = component.get('v.selectedAccount');
        var helper = this;
        let contactIdToPreselect = this.getContactIdToPreselect(component);
        if (contactIdToPreselect && !component.get('v.selectedContactId')) {
            component.set('v.selectedContactId', contactIdToPreselect);
        }

        const isShouldSync = selectedAccount
            && selectedAccount.RC_User_ID__c
            && selectedAccount.RC_Brand__c !== OC.CONSTANTS.OPPORTUNITY.BRAND_NAME.BT_BUSINESS
            && selectedAccount.RC_Brand__c !== OC.CONSTANTS.OPPORTUNITY.BRAND_NAME.TELUS
            && !selectedAccount.Billing_ID__c;
        const isEntitlementBased = component.get('v.app.featureToggle.Opportunity_Creation_Entitlement_Based__c') && !selectedAccount.Billing_ID__c;

        let proceedAccount = Promise.resolve();

        if (selectedAccount.Billing_ID__c || !isEntitlementBased) {
            proceedAccount = proceedAccount.then($A.getCallback(() => {
                helper.accInfoProcess(component);
            }))
        }

        if (!selectedAccount.Billing_ID__c && isShouldSync) {
            proceedAccount = proceedAccount.then($A.getCallback(() => {
                    helper.setEntitlementsBusy(component, true, isEntitlementBased);
                    return RC.salesforce.request(component, 'c.getEntitlementsSync', {
                        accId: selectedAccount.Id
                    })
                        .then(response => {
                            const app = component.get('v.app');

                            app.entitlements = response;

                            component.set('v.app', app);

                            return response;
                        })
                }))
                .catch($A.getCallback(error => {
                    $A.get("e.c:ToastEvent").setParams({
                        theme: "warning",
                        header: "Error during sync from Data Warehouse. Using Existing Entitlements.",
                        defaultTimeout: false
                    }).fire();
                    if (isEntitlementBased) {
                        return Promise.reject(error);
                    }
                }));
        }

        if (!selectedAccount.Billing_ID__c && isEntitlementBased) {
            proceedAccount = proceedAccount.then($A.getCallback(entitlements => {
                    if (entitlements && entitlements.length > 0) {
                        return helper.getServicePlanDetails(selectedAccount.Id, entitlements, component);
                    } else {
                        helper.accInfoProcess(component);
                    }
                }))
                .catch($A.getCallback(resp => {
                    console.log('error entitlements sync', resp);
                    helper.accInfoProcess(component);
                }))
        }

        if (isShouldSync) {
            proceedAccount.then($A.getCallback(() => this.setEntitlementsBusy(component, false)));
        }
    },

    setEntitlementsBusy: function(component, isBusy, isEntitlementBased){
        this.setComponentValue(component.find('accountField'),'v.showSpinner', isBusy);
        const prodSelector = component.find('productSelector');
        const servicePlanSpinner = component.find('servicePlanSpinner');
        if (isBusy && isEntitlementBased) {
            let text = 'Updating Entitlements';
            if (prodSelector) {
                prodSelector.showSpinner(text);
            }
            if (servicePlanSpinner) {
                servicePlanSpinner.show(text)
            }
        } else {
            if (prodSelector) {
                prodSelector.hideSpinner();
            }
            if (servicePlanSpinner) {
                servicePlanSpinner.hide()
            }
        }

        this.setComponentValue(component.find('discardButton'),'v.disabled', isBusy);
        this.setComponentValue(component.find('accountField'),'v.disabled', isBusy);
        this.setComponentValue(component.find('saveButton'),'v.disabled', isBusy);
        this.setComponentValue(component.find('confirmAndCloseButton'),'v.disabled', isBusy);
        this.setComponentValue(component.find('discardButton'),'v.disabled', isBusy);
    },

    checkNotifications: function (component) {
        this.updateComponent(component.find('notificationsOpportunityInfo'));
        this.updateComponent(component.find('notificationsServicePlan'));
    },

    /**
     * Show New Total Users
     */
    showInputField: function (component, show, name, size) {
        var auraId = name + 'Container';
        var container = component.find(auraId);

        if (show) {
            $A.util.removeClass(container, "slds-hide");
        } else {
            $A.util.addClass(container, "slds-hide");
        }

    },

    /**
     * Show Account number of lines field
     */
    showAccountDLs: function (component) {
        this.showInputField(component, true, 'accountDLs');
    },
    /**
     * Hide Account number of lines field
     */
    hideAccountDLs: function (component) {
        this.showInputField(component, false, 'accountDLs');

    },
    /**
     * Creates array of maps for use in Select input options
     * Example helper.createOpts(['','one', {value: '2', label="two"}])
     * return [
     *        {value: '', label="--None--"},
     *        {value: 'one', label="one"},
     *        {value: '2', label="two"}
     *    ]
     */
    createOpts: function (opts) {
        var result = [];
        if (Array.isArray(opts)) {
            opts.forEach(function (opt) {
                if(!opt) {
                    return;
                }
                var value;
                var label;
                if (typeof opt === 'string') {
                    value = opt;
                    label = opt === '' ? '--None--' : opt;
                } else {
                    value = opt.value;
                    label = opt.label;
                }
                result.push({
                    value: value,
                    label: label
                });
            });
        }
        return result;
    },
    discardForm: function (component) {
        this.hideAccountDLs(component);

        component.set('v.selectedAccountId', null);
        component.set('v.selectedAccountTier', null);
        component.set('v.selectedContactId', null);
        component.set('v.selectedTierLabel', '--None--');
        component.set('v.typeOpts', this.createOpts(['']));
        component.set('v.type', '');
        component.set('v.brand', '');
        component.set('v.service', '');
        component.set('v.edition', '');
        component.set('v.plan', '');
        component.set('v.forecastedUsers', '0');
        component.set('v.forecastedUsers', undefined);
        component.set('v.opportunityName', '');
        component.set('v.closeDate', '');
        component.set('v.selectedMainAreaCodeId', '');
        this.clearErrors();
        this.preselectFromUrl(component);
    },
    /**
     * Account unselected
     * Drop fields
     */
    discardAccount: function (component) {
        this.hideAccountDLs(component);

        component.set('v.tiersToPick', []);
        component.set('v.selectedAccountTier', null);
        component.set('v.selectedTierLabel', '--None--');
        component.set('v.typeOpts', this.createOpts(['']));
        component.set('v.type', '');
        component.set('v.brand', '');
        component.set('v.service', '');
        component.set('v.edition', '');
        component.set('v.plan', '');
        component.set('v.forecastedUsers', '0');
        component.set('v.forecastedUsers', undefined);
        component.set('v.selectedContactId', null);
        component.set('v.opportunityName', '');
        component.set('v.selectedMainAreaCodeId', '');
        const app = component.get('v.app');
        app.clearPreviouslySoldProducts();
    },
    /**
     * Default actions for Upsell type
     * Set fields value same as Selected Account Tier (Service Plan)
     */
    proceedUpsell: function (component) {
        var selectedAccountTier = component.get('v.selectedAccountTier');
        var selectedTier = component.get('v.selectedTier');

        var brand = '';
        var service = '';
        var edition = '';
        var plan = '';
        if (selectedAccountTier) {
            brand = selectedAccountTier.Pricebook2.Brand__r.Name;
            service = selectedAccountTier.Pricebook2.Service__c;
            edition = selectedAccountTier.Pricebook2.Edition__c;
            plan = selectedAccountTier.Product2.Charge_Term__c;

            if (!selectedTier || (selectedTier && selectedAccountTier.Id !== selectedTier)) {
                component.set('v.selectedTier', selectedAccountTier);
                component.set('v.selectedTierLabel', selectedAccountTier.Pricebook2.Name);
            }
        }

        // Brand field
        component.set('v.brand', brand);

        // Service
        component.set('v.service', service);
        component.set('v.serviceOpts', this.createOpts([service]));

        // Edition
        component.set('v.edition', edition);
        component.set('v.editionOpts', this.createOpts([edition]));

        // Plan
        component.set('v.plan', plan);
        component.set('v.planOpts', this.createOpts([plan]));

        // Additional Forecasted Users
        component.set('v.forecastedUsers', '0');
    },
    /**
     * Default actions for Upgrade type
     * Set fields value same as Selected Account Tier (Service Plan)
     * but with filtering on each step
     * if Selected Service Plan inactive it will stop
     */
    proceedUpgrade: function (component) {
        var selectedAccountTier = component.get('v.selectedAccountTier');
        var selectedTier;
        var currentForecastedUsers = component.get('v.forecastedUsers');
        var selectedAccount = component.get('v.selectedAccount');

        component.set('v.brand', '');
        component.set('v.service', '');
        component.set('v.edition', '');
        component.set('v.plan', '');
        component.set('v.forecastedUsers', undefined);

        if (selectedAccountTier) {
            // Brand field
            component.set('v.brand', selectedAccountTier.Pricebook2.Brand__r.Name);

            // Service
            component.set('v.service', selectedAccountTier.Pricebook2.Service__c);

            // Edition
            component.set('v.edition', selectedAccountTier.Pricebook2.Edition__c);

            // Plan
            component.set('v.plan', selectedAccountTier.Product2.Charge_Term__c);
        }

        // Forecasted Users
        var forecastedUsers = selectedAccount.Number_of_DL_s__c ? String(selectedAccount.Number_of_DL_s__c) : '1';

        component.set('v.forecastedUsers', forecastedUsers);
    },
    /**
     * Default actions for New Customer type
     */
    proceedNewCustomer: function (component) {
        const brand = component.get('v.brand');
        const selectedAccount = component.get('v.selectedAccount');
        // Brand field
        if (brand) {
            return;
        }
        if (selectedAccount.RC_Brand__c) {
            component.set('v.brand', selectedAccount.RC_Brand__c);
        } else {
            component.set('v.brand', 'RingCentral');

            // Service
            component.set('v.service', 'Office');

            // Edition
            component.set('v.edition', 'Standard');

            // Plan
            component.set('v.plan', 'Monthly');
        }

        // Forecasted Users
        component.set('v.forecastedUsers', '1');
    },
    closeTierPicker: function (component) {
        var tierPicker = component.find('tierPicker');
        $A.util.addClass(tierPicker, 'slds-hide');
    },
    openTierPicker: function (component) {
        var tierPicker = component.find('tierPicker');
        $A.util.removeClass(tierPicker, 'slds-hide');
    },
    tierPickerActive: function (component) {
        var selectedTierField = component.find('selectedTierField');
        $A.util.addClass(selectedTierField, 'tier-picker--active');
    },
    tierPickerInactive: function (component) {
        var selectedTierField = component.find('selectedTierField');
        $A.util.removeClass(selectedTierField, 'tier-picker--active');
    },

    getServiceOpts: function (component, brand) {
        return component.get('v.app').getServiceOptions({
            serviceDependencies: component.get('v.serviceDependencies'),
            serviceOptions: component.get('v.serviceValues'),
            brandConfiguration: component.get('v.brandConfiguration'),
            brand
        });
    },

    preselectFromUrl: function (component) {
        // preselect Account
        var searchParams = new URL(window.location).searchParams;
        var accountIdToPreselect = searchParams.get("accid");
        var fromContact = searchParams.get("fromContact");
        var fromConversionContact = searchParams.get("fromConversionContact");
        var leadSource = searchParams.get("leadSource");
        var opportunityName = searchParams.get("oppName");
        var closeDate = searchParams.get("closeDate");
        var buddyOpportunityId = searchParams.get("buddyOpportunityId");
        var newDLs = searchParams.get("newDLs");
        var campaignId = searchParams.get("campaignId");
        var numberOfForecastedUsers = searchParams.get("numberOfForecastedUsers");
        var contactId = searchParams.get("contactId");
        var conversionContactId = searchParams.get("conversionContactId");
        var oppCreationFlow = searchParams.get("oppCreationFlow");

        if (accountIdToPreselect) {
            component.set('v.selectedAccountId', accountIdToPreselect);

            this.contactPreselectionFromURL = true;
        }

        if (fromContact) {
            component.set('v.fromContact', fromContact);
            component.set('v.fromContactId', fromContactId);
            component.set('v.fromConversionContact', fromConversionContact);
            component.set('v.contactCenterUsers', contactCenterUsers);
            component.set('v.engageDigitalUsers', engageDigitalUsers);
            component.set('v.engageVoiceUsers', engageVoiceUsers);
            component.set('v.globalOfficeUsers', globalOfficeUsers);
            component.set('v.officeUsers', officeUsers);
            component.set('v.rcVideoUsers', rcVideoUsers);
        }

        if (oppCreationFlow) {
            component.set('v.oppCreationFlow', oppCreationFlow);
        }

        if (leadSource) {
            component.set('v.leadSource', leadSource);
        }

        if (opportunityName) {
            component.set('v.opportunityName', opportunityName);
        }

        if (closeDate) {
            component.set('v.closeDate', closeDate);
        }

        if (buddyOpportunityId) {
            component.set('v.buddyOpportunityId', buddyOpportunityId);
        }

        if (newDLs) {
            component.set('v.newDLs', Number(newDLs));
        }

        if (campaignId) {
            component.set('v.campaignId', campaignId);
        }

        if (numberOfForecastedUsers) {
            component.set('v.numberOfForecastedUsers', Number(numberOfForecastedUsers));
        }

        if (contactId) {
            component.set('v.selectedContactId', contactId.split(',')[0]);
        }

        if (conversionContactId) {
            component.set('v.selectedConversionContactId', conversionContactId.split(',')[0]);
         }
    },

    preselectContactFromURL: function (component) {
        var contactIdToPreselect = new URL(window.location).searchParams.get("conid");
        if (contactIdToPreselect) {
            var roles = component.get('v.selectedAccount.AccountContactRoles') || [];
            var primaryRole = roles.find(cr => cr.IsPrimary);
            if (primaryRole) {
                component.set('v.selectedContactId', primaryRole.ContactId);
            }
            if (contactIdToPreselect && contactIdToPreselect != primaryRole.ContactId) {
                component.set('v.selectedConversionContactId', contactIdToPreselect);
            }
        }
    },

    setPrimaryContactLookupParams: function (component) {
        component.find('contactField').set('v.params', {
            accountId: component.get('v.selectedAccount.Id'),
            applyContactRoleFilter: component.get('v.app.featureToggle.OpptyContactRoleSelectorUpdate__c')
                ? 'true'
                : 'false',
            isPrimary: 'true'
        });
    },

    setConversionContactLookupParams: function (component) {
        component.find('conversionContactField').set('v.params', {
            accountId: component.get('v.selectedAccount.Id'),
            applyContactRoleFilter: component.get('v.app.featureToggle.OpptyContactRoleSelectorUpdate__c')
                ? 'true'
                : 'false',
            isPrimary: 'false'
        });
    },

    getContactIdToPreselect: function (component) {
        var roles = component.get('v.selectedAccount.AccountContactRoles') || [];
        if (roles.length > 0) {
            var roleToPreselect = roles.find(cr => cr.IsPrimary);
            if (!roleToPreselect) {
                roleToPreselect = roles.find(cr => cr.Role === 'Signatory');
            }
            return roleToPreselect && roleToPreselect.ContactId;
        } else {
            return null; 
        }
    },

    /**
     *  Initialize lookup filtering
     */
    setLookupParams: function (component) {
        var brandName = component.get('v.brand');
        this.setComponentValue(component.find('mainAreaCode'), 'v.params', {
            brand: brandName,
            type: 'main'
        });
    },

    getDataOnInit: function (component) {
        return RC.salesforce.request(component, 'c.getDataOnInit', {})
            .then($A.getCallback(result => {
                var app = component.get('v.app');

                app.setFeatureToggle(result.data.Feature_Toggle__c);
                app.setUserPermissions(result.data.userCustomPermissions);

                component.set('v.app', app);
            }));
    },

    validateConfirmAndClose: function (component) {
        var app = component.get('v.app');
        let isCanProceed = app.validateConfirmAndClose();

        component.set('v.app', app);
        this.showInputErrors(component);
        return isCanProceed;
    },

    validateContinueToOpportunity: function (component) {
        var app = component.get('v.app');
        let isCanProceed = app.validateContinueToOpportunity();

        component.set('v.app', app);
        this.showInputErrors(component);
        return isCanProceed;
    },

    showInputErrors: function (component) {
        this.clearErrors(component);
        var app = component.get('v.app');
        if (app.showNewTotalUsersError) {
            $A.util.addClass(component.find('newTotalUsersContainer'), "slds-has-error");
        } else {
            $A.util.removeClass(component.find('newTotalUsersContainer'), "slds-has-error");
        }

        if(!app.validateServicePlan()) {

            var fieldNames = [
                {
                    attrName: 'v.brand',
                    auraId: 'brandField'
                },
                {
                attrName: 'v.service',
                auraId: 'serviceField'
                },
                {
                attrName: 'v.edition',
                auraId: 'editionField'
                },
                {
                attrName: 'v.plan',
                auraId: 'planField'
                }
            ];

            fieldNames.forEach( item => {
                if(!component.get(item.attrName).trim()) {
                    if(!component.find(item.auraId).get('v.disabled')) {
                        $A.util.addClass(component.find(item.auraId), "slds-has-error");
                    }
                }
            });
        }
    },

    clearErrors: function (component) {
        $A.util.removeClass(component.find('newTotalUsersContainer'), "slds-has-error");

        // Service Plan fields
        $A.util.removeClass(component.find('brandField'), "slds-has-error");
        $A.util.removeClass(component.find('serviceField'), "slds-has-error");
        $A.util.removeClass(component.find('editionField'), "slds-has-error");
        $A.util.removeClass(component.find('planField'), "slds-has-error");
    },

    setComponentValue: function (component, attribute, value) {
        if (component) {
            component.set(attribute, value);
        }
    },

    updateComponent: function (component) {
        if (component) {
            component.update();
        }
    },

    getBrandValues: function (brands) {
        return brands.reduce((result, brand) => {
            result.push(brand.value);
            return result;
        }, []);
    },

    isNGBSServiceEnabled: function (brandConfig) {
        return brandConfig && brandConfig.length > 0 && brandConfig.includes(OC.CONSTANTS.OPPORTUNITY.TIER_NAME.RC_OFFICE)
    },

    isQuotingAvailable: function(component, brandConfig, brand) {
        const app = component.get('v.app');
        return app.isQuotingAvailable(brandConfig, brand);
    },

    isSelectedAccountBillOnBehalf: function (component) {
        const selectedAccount = component.get('v.selectedAccount');
        return selectedAccount && selectedAccount.Partner_ID__c && RC.BILL_ON_BEHALF_PARTNERS.includes(selectedAccount.Partner_Type__c);
    },

    isSelectedAccountWholesale: function (component) {
        const selectedAccount = component.get('v.selectedAccount');
        return selectedAccount && selectedAccount.Partner_ID__c && RC.WHOLESALE_PARTNERS.includes(selectedAccount.Partner_Type__c);
    },

    filterOptionsForBOBorWholesaleAccount: function (component) {
        let index = 0;
        const serviceOptions = component.get('v.serviceOpts');
        while (index < serviceOptions.length) {
            if (RC.ENGAGE_SERVICES.includes(serviceOptions[index].value) ||
                serviceOptions[index].value === RC.CONSTANTS.OPPORTUNITY.TIER_NAME.FAX ||
                serviceOptions[index].value === RC.CONSTANTS.OPPORTUNITY.TIER_NAME.RC_MEETINGS)
            {
                serviceOptions.splice(index, 1);
            } else {
                index++;
            }
        }
        component.set('v.serviceOpts', serviceOptions);
    },

    switchToNgbs: function(component) {
        if (component.get('v.selectedAccount.Id')
            && component.get('v.selectedAccountId')
            && component.get('v.selectedAccountId').slice(0,14) !== component.get('v.selectedAccount.Id').slice(0,14)
            && !component.get('v.brand')
            && !component.get('v.service')
        ) {
            return;
        }
        const biInfo = this.buildBusinessIdentityInfo(component.get('v.selectedBusinessIdentity'));
        const params = {
            fields: {
                accountSfId: component.get('v.selectedAccount.Id'),
                accountBillingId: component.get('v.selectedAccount.Billing_ID__c'),
                accountRcUserId: component.get('v.selectedAccount.RC_User_ID__c'),
                contactSfId: component.get('v.selectedContact.Id'),
                conversionContactSfId: component.get('v.selectedConversionContact.Id'),
                opportunityName: component.get('v.opportunityName'),
                closeDate: component.get('v.closeDate'),
                leadSource: component.get('v.leadSource'),
                shippingLocation: component.get('v.shippingLocation'),
                provisioningDetails: component.get('v.provisioningDetails'),
                brand: component.get('v.brand'),
                service: component.get('v.service'),
                biInfo,
                fromContact: component.get('v.fromContact'),
                fromContactId: component.get('v.fromContactId'),
                fromConversionContact: component.get('v.fromConversionContact'),
                fromConversionContactId: component.get('v.fromConversionContactId'),
                contactCenterUsers: component.get('v.contactCenterUsers'),
                engageDigitalUsers: component.get('v.engageDigitalUsers'),
                engageVoiceUsers: component.get('v.engageVoiceUsers'),
                globalOfficeUsers: component.get('v.globalOfficeUsers'),
                officeUsers: component.get('v.officeUsers'),
                rcVideoUsers: component.get('v.rcVideoUsers'),
                oppCreationFlow: component.get('v.oppCreationFlow'),
                newDLs: component.get('v.newDLs'),
                buddyOpportunityId: component.get('v.buddyOpportunityId'),
                campaignId: component.get('v.campaignId'),
                numberOfForecastedUsers: component.get('v.numberOfForecastedUsers'),
                selectedAccount: component.get('v.selectedAccount'),
            },
            brandConfiguration: component.get('v.brandConfiguration'),
            userPermissions: component.get('v.app.userPermissions'),
        };
        if (OC.toggle.isNgbs(params)) {
            OC.toggle.switchToNgbs(params);
        }
    },
    fetchPartnerSettings : function(component) {
        return RC.salesforce.request(component, 'c.getPartnerSettings', {
               }).then($A.getCallback(response => {
                component.set("v.partnerSettings", response);
                console.log('partnerSettings==',response);
                this.updateEditionLockStatus(component); // Initial check on load
            }))
        },

    updateEditionLockStatus : function(component) {
        const selectedAccount = component.get('v.selectedAccount');
        var brandName = selectedAccount.RC_Brand__c;
        var partnerSettings = component.get("v.partnerSettings");
        var isLocked = false;

        if (partnerSettings && Array.isArray(partnerSettings) && brandName) {
            for (var setting of partnerSettings) {
                if (setting.Validation_name__c === brandName) { 
                    const biValues = component.get('v.biValues');
                    const brandKey = selectedAccount.RC_Brand__c;
                    const biOption = biValues.find(item => item.defaultBrand === brandKey);
                    const biValuesForOptions = biOption ? [biOption] : [];
                    component.set('v.biOptions',this.buildBusinessIdentityOptions(biValuesForOptions));
                    console.log('biValuesForOptions==',biValuesForOptions);

                    if(setting.QuoteCreationLocked__c){
                    isLocked = setting.QuoteCreationLocked__c;
                    break;
                }
            }
        }
        }
        component.set("v.isQuoteCreationLocked", isLocked);
    }
});