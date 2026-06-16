({
    filterTiers: function(component, filterType, params) {
        var tiers = component.get("v.tiers");
        var ftiers = [];
        var recordTypeName = component.get("v.recordTypeName");
        var filterLevel = component.get("v.filterLevel");
        var quote = component.get('v.quote');
        var state = component.get('v.state');
        var settings = component.get('v.settings');
        var Wizard = component.get('v.Wizard');
        var isCC = component.get('v.isCC');
        var ccOption = this.getCCOption(Wizard, settings);
        var tireName = Wizard.opportunity.record.Tier_Name__c;

        // Info From Account
        var rcTier = component.get("v.rcTier");
        var accountPlan = component.get("v.accountPlan");
        var accountLines = component.get("v.accountLines");
        var upsellStatus = component.get("v.upsellStatus");
        var accountServicePlanPbe = component.get("v.accountServicePlanPbe");
        var isTelus = settings.isTelus;

        if(accountServicePlanPbe){
            accountPlan = accountServicePlanPbe.Product2.Charge_Term__c;
            rcTier = accountServicePlanPbe.Pricebook2.Tier_ID__c
        }

        // Filters
        var serviceFilter = component.get("v.serviceFilter");
        var editionFilter = component.get("v.editionFilter");
        var planFilter = component.get("v.planFilter");
        var linesFilter = Number.parseInt(component.get("v.linesFilter"));

        var serviceOpts = new Set(),
            editionOpts = new Set(),
            planOpts    = new Set();
        var pbIds = {};
        tiers.forEach(function(tier) {
            var add = true;

            var activeTierOnQuote = false;
            if (quote && quote.Pricebook2Id && tier.Pricebook2.Id === quote.Pricebook2Id){
                activeTierOnQuote = true;
            }

            //CC Pricebook logic
            var isCCPricebook = (tier.Pricebook2.Service__c === QW.CONSTANTS.PRODUCT2.SUB_CATEGORY.CONTACT_CENTER && !isTelus);

            // exclude all and show only active
            if (
                ((Wizard.opportunity.isClosed
                    || state.isAgreement
                    || state.isQuoteOnApproval
                    // Permission checks for Already created quotes
                    || ( quote && !state.isUserHavePermissionToEditQuote )
                    || Wizard.currentQuote && Wizard.currentQuote.isInvalid
                    // Permission checks for not yet created quotes
                    || ( !quote && !settings.userPermissions.EditSalesQuote )
                    || state.isEngagementCancelled)
                &&
                !activeTierOnQuote)
                ||
                (!isCC && isCCPricebook)
                ) {
                add = false;
            }

            if (isCC) {
                try {
                    add = isCCPricebook && ccOption && tier.Product2.Charge_Term__c === ccOption
                            || tier.Pricebook2.Brand__r.Name === QW.CONSTANTS.OPPORTUNITY.BRAND_NAME.TELUS && settings.isTelus;
                } catch(e) {
                    console.error(e);
                }
            }


            if (upsellStatus == "Upsell") {
                // Filter by Tier ID
                if (!isCC && tier.Pricebook2.Tier_ID__c !== rcTier) {
                    add = false;
                }

                // Filter by Plan on Account
                if (accountPlan && tier.Product2.Charge_Term__c !== accountPlan) {
                    add = false;
                }

                // Filter by Number of Lines on Account
                if (Number.isInteger(accountLines)) {
                    if ((tier.Pricebook2.Line_Range_Min__c > accountLines ||
                        tier.Pricebook2.Line_Range_Max__c < accountLines)) {
                        add = false;
                    }
                }

                // During Upsell, if quote have active plan but it is differ from preselected, show active one.
                if (quote && quote.Pricebook2Id && tier.Pricebook2.Id === quote.Pricebook2Id) {
                    add = true;
                }

                // B-1494: Service Plan pre-selection: not all users provisioned
                // If Account have less Number of lines than Preselected Service Plan Show it anyway
                if (tier.Pricebook2.Tier_ID__c === rcTier &&
                    tier.Product2.Charge_Term__c === accountPlan &&
                    accountLines < tier.Pricebook2.Line_Range_Max__c) {
                    if (quote && quote.Pricebook2Id && tier.Pricebook2.Id !== quote.Pricebook2Id) add = false;
                    else add = true;
                }

            } else {

                if (upsellStatus === "Upgrade") {

                    //Allow Upgrade to Service Plan with the same Tier ID (B-353)
                    if (!tier.Pricebook2.IsActive && tier.Pricebook2.Tier_ID__c !== rcTier) {
                        add = false;
                    }

                } else { // New Customer

                    // Hide Inactive
                    if (!tier.Pricebook2.IsActive && !activeTierOnQuote) {
                        add = false;
                    }
                }

                // UI FILTERS

                // Filter by Service Filter
                if (serviceFilter && tier.Pricebook2.Service__c !== serviceFilter) {
                    add = false;
                }

                // Filter by Edition Filter
                if (editionFilter && tier.Pricebook2.Edition__c !== editionFilter) {
                    add = false;
                }

                // Filter by Plan Filter
                if (planFilter && tier.Product2.Charge_Term__c !== planFilter) {
                    add = false;
                }

                // Filter by Number of Lines Filter
                if (Number.isInteger(linesFilter)) {
                    if (tier.Pricebook2.Line_Range_Min__c > linesFilter ||
                        tier.Pricebook2.Line_Range_Max__c < linesFilter) {
                        add = false;
                    }
                }
            }

            // Do not include Service Plan with duplicate Pricebook2Ids
            // ???
            if (pbIds[tier.Pricebook2Id] == null) {
                pbIds[tier.Pricebook2Id] = tier.Pricebook2Id;
            } else {
                add = false;
            }

            if (add) {
                ftiers.push(tier);

                // Add filter options
                if (tier.Pricebook2.Service__c && upsellStatus !== 'New') {
                    serviceOpts.add(tier.Pricebook2.Service__c);
                }
                if (tier.Pricebook2.Edition__c) {
                    editionOpts.add(tier.Pricebook2.Edition__c);
                }
                if (tier.Product2.Charge_Term__c) {
                    planOpts.add(tier.Product2.Charge_Term__c);
                }
            }
        });

        /**
         * Return only unique and not empty values of array
         */
        function onlyUnique(value, index, self) {
            return value && self.indexOf(value) === index;
        }
        // Set filter options to dependant filters
        if(filterLevel === 0){
            if (upsellStatus === 'New') {
                component.set('v.serviceFilter', tireName);
                component.find("serviceFilter").set('v.disabled', true);
            } else {
                component.set('v.serviceOpts', this.createOpts(Array.from(serviceOpts)));
            }
        } else if (filterLevel === 1) {
            component.set('v.editionOpts', this.createOpts(Array.from(editionOpts)));
        } else if (filterLevel === 2) {
            component.set('v.planOpts', this.createOpts(Array.from(planOpts)));
        }

        // Sort and display
        ftiers = this.sortProducts(ftiers);
        component.set("v.filteredTiers", ftiers);

        // Service Plan Preselection on Upsell
        if (!quote
            && (upsellStatus === "Upsell" || isCC)
            && ftiers.length === 1
            && component.get('v.selectedPriceBookEntry.Id') !== ftiers[0].Id) {
            component.set('v.selectedPriceBookEntry',ftiers[0]);
        }
        this.renderTiers(component);
    },

    sortProducts: function(products) {
        products.sort(function(a, b) {
            return (b.Pricebook2.Service__c < a.Pricebook2.Service__c) - (a.Pricebook2.Service__c < b.Pricebook2.Service__c) || //  by service
                (b.Pricebook2.Edition__c < a.Pricebook2.Edition__c) - (a.Pricebook2.Edition__c < b.Pricebook2.Edition__c) || // by edition
                (a.Pricebook2.Line_Range_Min__c - b.Pricebook2.Line_Range_Min__c) || // by line range
                (b.Product2.Charge_Term__c < a.Product2.Charge_Term__c) - (a.Product2.Charge_Term__c < b.Product2.Charge_Term__c); // by plan
        });
        return products;
    },
    /**
     * Scroll Service Plan List to Active Service Plan
     */
    scrollToSelectedTier: function(component) {
        const index = (component.get('v.filteredTiers') || []).findIndex(t => t.Id === component.get('v.activePriceBookEntry.Id'));
        const isFound = index !== -1;
        if (isFound) {
            const pHeight = 38;
            component.find('tierList').getElement().scrollTop = pHeight * index + 1;
        }
    },
    /**
     * Scroll Service Plan List to Top
     */
    scrollToTop: function(component) {
        var tierListEl = component.find('tierList').getElement();
        if (tierListEl) {
            tierListEl.scrollTop = 0;
        }
    },
    /*
     * Get price difference between Monthly and Monthly - Contract service plans
     */
    getMCPriceDiff: function(component) {
        var activePriceBookEntry = component.get('v.activePriceBookEntry');
        var quote = component.get('v.quote');

        if (activePriceBookEntry) {
            var action = component.get("c.getMonthlyContractDiscounts");
            var prms = {};
            prms["currency"] = activePriceBookEntry.CurrencyIsoCode;
            prms["quoteId"] = quote.Id;

            action.setParams({
                params: prms
            });

            action.setCallback(this, function(actionResult) {
                if (component.isValid() && actionResult.getState() === "SUCCESS") {
                    var res = actionResult.getReturnValue();
                    $A.get("e.c:QuotingToolMonthlyContractDiscountEvent").setParams({ monthlyContractDiscount: res }).fire();
                }
            });

            $A.enqueueAction(action);
        }
    },
    /**
     * Find Service Plan with the same parameters but appropriate Number of lines
     */
    findSimilarTier: function(component, qli, type, lines) {
        var qt = component.get('v.quote');
        if (qli) {
            var tiers = component.get('v.tiers');
            // find tier to compare
            var tierToCompare = null;
            for (var i = 0; i < tiers.length; i++) {
                if (tiers[i].Pricebook2Id === qli.PricebookEntry.Pricebook2Id) {
                    tierToCompare = tiers[i];
                    break;
                }
            }
            // compare tiers to find
            if (tierToCompare) {
                var foundTier = null;

                for (var i = 0; i < tiers.length; i++) {
                    var tier = tiers[i];
                    if (tier.Pricebook2.Service__c === "Office" && tier.Pricebook2.IsActive === true &&
                        (tier.Pricebook2.Line_Range_Max__c >= lines) &&
                        (tier.Pricebook2.Line_Range_Min__c <= lines) &&
                        (tier.Pricebook2.Edition__c === tierToCompare.Pricebook2.Edition__c) &&
                        (tier.Product2.Charge_Term__c === tierToCompare.Product2.Charge_Term__c) &&
                        (tier.Product2.CurrencyIsoCode === tierToCompare.Product2.CurrencyIsoCode)) {
                        foundTier = tier;
                        break;
                    }
                }
                if (foundTier) {
                    $A.get("e.c:QuotingToolModalRequestEvent").setParams({
                        action: "SwitchTier" + type,
                        sourceId: 'tierList',
                        params: { tier: foundTier, lines: lines }
                    }).fire();
                } else {
                    $A.get("e.c:ToastEvent").setParams({
                        theme: 'warning',
                        header: 'Service Plan to switch to not found',
                        details: 'There is no service plan to support ' + QW.pluralize('Digital Lines', lines, true),
                        defaultTimeout: true
                    }).fire();
                }
            } else {
                console.error('qli from cart not found on tier list');
            }
        }
    },
    /**
     * Save to shared variable current PriceBookEntry on Quote
     */
    setActivePriceBookEntry: function(component){
        var quote = component.get('v.quote');
        var tiers = component.get('v.tiers');
        var activePriceBookEntry = null;
        if (quote && Array.isArray(tiers)){
            for (var i = 0; i < tiers.length; i++) {
                if(tiers[i].Pricebook2Id === quote.Pricebook2Id){
                    activePriceBookEntry = tiers[i];
                    break;
                }
            }
        }
        component.set('v.activePriceBookEntry', activePriceBookEntry);
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
    createOpts: function(opts){
        var result = [];
        if (Array.isArray(opts)) {
            opts.forEach(function(opt){
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
    /**
     * Disable/Inable inputs
     */
    checkInputsDisabling: function(component){
        var filterLevel = component.get('v.filterLevel');
        var editionFilterDisabled = true;
        var planFilterDisabled = true;
        if (filterLevel > 0) {
            editionFilterDisabled = false;
        }
        if (filterLevel > 1) {
            planFilterDisabled = false;
        }
        component.find("editionFilter").set('v.disabled', editionFilterDisabled);
        component.find("planFilter").set('v.disabled', planFilterDisabled);
    },
    /**
     * PreSelect default values in filters
     */
    setDefaultFilters: function(component){
        var activePriceBookEntry = component.get('v.activePriceBookEntry');
        var quote = component.get('v.quote');
        if (activePriceBookEntry && activePriceBookEntry.Pricebook2.Service__c) {
            component.set('v.serviceFilter',activePriceBookEntry.Pricebook2.Service__c);
        } else if (!quote){
            var opportunityPlan = component.get('v.opportunityPlan');
            component.set('v.serviceFilter',opportunityPlan);
        }
    },
    /**
     * Set Filter Level
     */
    setFilterLevel: function(component){
        var serviceFilter = component.get('v.serviceFilter');
        var editionFilter = component.get('v.editionFilter');
        var planFilter = component.get('v.planFilter');

        var newFilterLevel = planFilter ? 3 : 2;
        newFilterLevel = editionFilter  ? newFilterLevel : 1;
        newFilterLevel = serviceFilter ? newFilterLevel : 0;

        component.set('v.filterLevel', newFilterLevel);
    },
    /**
     * Empty All filters
     */
    dropFilters: function(component){
        component.set("v.linesFilter","");
        component.set("v.planFilter","");
        component.set("v.editionFilter","");
        component.set("v.serviceFilter","");
    },
    /**
     * Check if elements should be displayed or Hidden
     */
    checkDisplaying: function(component){
        var state = component.get('v.state');
        var settings = component.get('v.settings');
        var quote = component.get('v.settings');
        var Wizard = component.get('v.Wizard');

        QW.cssUtils.toggleShow(component,'filters', !state.isAgreement
                                                 && !state.isQuoteOnApproval
                                                 && !Wizard.opportunity.isClosed
                                                 && !state.isUpsell
                                                 // User Custom Permission checks
                                                 && (
                                                    // Permission checks for Already created quotes
                                                    !( quote && !state.isUserHavePermissionToEditQuote )
                                                    // Permission checks for not yet created quotes
                                                 || !( !quote && !settings.userPermissions.EditSalesQuote ))
                                                 && (!Wizard.currentQuote || !Wizard.currentQuote.isInvalid));
    },

    /**
     * Search Price Book Entry by PriceBook Id and save Quote with new Service Plan
     * @param component     {object} Aura component
     * @param pricebook2Id  {string} PriceBook Id
     * @returns {Promise|undefined}
     */
    switchServicePlan: function(component, pricebook2Id){
        var tiers = component.get('v.tiers');
        var foundTier = tiers.find(tier => tier.Pricebook2Id === pricebook2Id)

        if(foundTier){
            return this.saveServicePlanOnQuote(component, foundTier);
        } else {
            $A.get("e.c:ToastEvent").setParams({
                theme: 'error',
                header: 'Failed to switch service plan',
                details: 'Tier with Pricebook2Id='+pricebook2Id+' not found',
                defaultTimeout: false
            }).fire();
        }
    },
    /**
     * Save Service Plan on quote
     * @param component              {object} Aura component
     * @param selectedPriceBookEntry {object} Service plan PriceBookEntry to change to
     * @param [lines]                {number} Number of lines to set on Service Plan.
     *                                        If not set minimum range will be used
     * @return {Promise|undefined}
     */
    saveServicePlanOnQuote: function(component, selectedPriceBookEntry, lines){
        if (!selectedPriceBookEntry) {
            console.error('price book entry to change is not set');
            return;
        }

        var helper = this;
        var quote = component.get("v.quote");
        var upsellStatus = component.get("v.upsellStatus") || component.get("v.quote.Upsell_Status__c");
        var Wizard = component.get('v.Wizard');
        var isCC = component.get('v.isCC');

        //B-2153 Update Type for New Opp Creation Wizard & Quotes
        if (upsellStatus == "Upgrade") {
            var entls = component.get("v.entitlements");
            var entlTierId;
            var entlChargeTerm;
            for (var idx in entls) {
                var entl = entls[idx];
                if (entl.Product__r.Family == "Service") {
                    var extid = entl.Product__r.ExtID__c.split("_");
                    if (extid) {
                        entlTierId = extid[0];
                        entlChargeTerm = extid[4];
                    }
                }
            }

            if (entlTierId == selectedPriceBookEntry.Pricebook2.Tier_ID__c
                && entlChargeTerm == selectedPriceBookEntry.Product2.Charge_Term__c) {
                upsellStatus = "Upsell";
            }
        }
        //B-2153

        // Prepare c.saveQuote parameters
        var saveQuoteParams = {
            opportunityId: component.get("v.opportunityId"),
            pricebook2Id: selectedPriceBookEntry.Pricebook2Id
        };
        if (quote) saveQuoteParams.quoteId = quote.Id;
        if (Number.isInteger(lines)) saveQuoteParams.lines = lines.toString(10);
        if (upsellStatus) saveQuoteParams.upsellStatus = upsellStatus;
        if (isCC) {
            saveQuoteParams.isCC = 'Contact Center';
        }

        // Start Save Quote / Change Service Plan Process
        var saveServicePlanProcess = Promise.resolve();
        var createdQuoteId = null;

        // Delete old Products From Quote
        if (quote){
            saveServicePlanProcess = saveServicePlanProcess.then($A.getCallback(function () {
                    QW.spinner.show('Deleting products from cart');
                    return QW.salesforce.request(component, 'c.deleteQuoteQlis', { quoteId: quote.Id })
                }))
        }
        // Save Quote
        saveServicePlanProcess = saveServicePlanProcess
            .then($A.getCallback(function () {
                QW.spinner.show('Saving Quote');
                return QW.salesforce.request(component, 'c.saveQuote', { params: saveQuoteParams })
            }))
            // Refresh Quote
            .then($A.getCallback(quoteId => {
                createdQuoteId = quoteId;
                return QW.refreshQuote(component, quoteId);
            }))
            // Add Entitlements if needed
            .then($A.getCallback(function () {
                if (component.get('v.quote') && !component.get('v.state.isNewCustomer')) {
                     QW.spinner.show('Adding Entitlements');
                     return helper.addEntitlementsAsLineItems(component)
                         // Check Extended Enterprise Support Products
                         .then($A.getCallback(function () {
                             QW.spinner.show('Checking Dependent items');
                             return QW.salesforce.request(component, 'c.handleExtendedEnterpriseSupport', {
                                 quoteId: createdQuoteId
                             });
                         }))
                }
            }))
            // Finalize process
            .then($A.getCallback(function () {

                // refresh product list
                $A.get("e.c:QuotingToolUpdateProductListEvent").fire();

                // refresh cart
                $A.get("e.c:QuotingToolRefreshCartEvent").fire();

            }))
            .catch($A.getCallback(function (error) {
                console.error(error);
                $A.get("e.c:ToastEvent").setParams({
                    theme: 'error',
                    header: 'Failed to save Quote',
                    details: QW.salesforce.getResponseError(error),
                    defaultTimeout: false
                }).fire();
                return Promise.reject();
            }))
            .then($A.getCallback(function (error) {
                QW.spinner.hide();
            }))
            // Refresh Wizard
            .then($A.getCallback(function () {
                return QW.salesforce.request(component, 'c.getQuotes', {
                    opportunityId: Wizard.opportunity.record.Id
                });
            }))
            .then($A.getCallback(function (quotes) {
                Wizard.setQuotes(quotes);
                Wizard.setCurrentQuote( component.get('v.quote.Id') );
                Wizard.update();
                component.set('v.Wizard', Wizard);
                $A.get("e.c:QuotingToolRefreshCartEvent").fire();
            }));

        return saveServicePlanProcess;
    },
    addEntitlementsAsLineItems: function(component) {
        var quote = component.get("v.quote");

        return QW.salesforce.request(component,'c.addEntitlementsAsLineItems', { quoteId: quote.Id } )
            .catch($A.getCallback(function (error) {
                console.error(error);
                $A.get("e.c:ToastEvent").setParams({
                    theme: "error",
                    header: "Creation quote line items from entitlements failed",
                    details: QW.salesforce.getResponseError(error),
                    defaultTimeout: false
                }).fire();
            }))

    },
    warnUserAboutServicePlanChange: function(component){
        var selectedPriceBookEntry = component.get("v.selectedPriceBookEntry");
        var quote = component.get('v.quote');

        var isShouldWarnUser = quote && quote.Pricebook2Id !== selectedPriceBookEntry.Pricebook2Id;
        if (isShouldWarnUser){
            $A.get("e.c:QuotingToolModalRequestEvent").setParams({
                action: "SwitchServicePlan",
                sourceId: "TierList"
            }).fire();
        }
        return isShouldWarnUser;
    },
    getCCOption: function(wizard, settings) {
        if (settings.isBTBusiness) {
            return QW.CONSTANTS.PRICEBOOK2.PLAN.MONTHLY;
        }
        let ccOption = null;
        wizard.quotes.forEach( function(quote) {
            if (quote.isContactCenterQuoteAvailable) {
                ccOption = JSON.parse(quote.record.Package_Info__c)[0].duration;
            }
        });
        return ccOption;
    },

    renderTiers: function (component) {
        const el = component.find('tierList').getElement();
        if (!el || !component.get('v.Tabs.servicePlans.isOpen')) {
            return;
        }
        const pHeight = 38;
        const itemsOnScreen = Math.ceil(el.clientHeight / pHeight);
        const additionalItemsCount = parseInt(itemsOnScreen / 2);
        const filteredTiers = component.get('v.filteredTiers');
        const currentIndex = parseInt(el.scrollTop / pHeight);
        let start = currentIndex - additionalItemsCount;
        start = start < 0 ? 0 : start;
        const end = currentIndex + itemsOnScreen + additionalItemsCount;
        const scrollTiers = filteredTiers.slice(start, end);
        const scrollBufferTop = filteredTiers.slice(0, start).length * pHeight;
        const scrollBufferBottom = filteredTiers.slice(end, filteredTiers.length).length * pHeight;
        let listBuffer = component.get('v.listBuffer');
        listBuffer.scrollBufferTop = scrollBufferTop;
        listBuffer.scrollBufferBottom = scrollBufferBottom;
        component.set('v.listBuffer', listBuffer);
        component.set('v.scrollTiers', scrollTiers);
        this.setTableWidth(component);
    },

    addEventListeners: function (component) {
        let helper = this;
        this.onResize = $A.getCallback(() => {
            clearTimeout(helper.scrollTimer);
            helper.scrollTimer = setTimeout($A.getCallback(() => {
                helper.renderTiers(component);
            }), 500);
        });
        window.addEventListener('resize', this.onResize);
    },

    removeEventListeners: function () {
        window.removeEventListener('resize', this.onResize);
    },

    setListBufferData: function (component) {
        let lb = component.get('v.listBuffer');
        lb.name = '';
        (component.get('v.filteredTiers') || []).forEach(t => {
            if (lb.name.length < t.Pricebook2.Name.length) {
                lb.name = t.Pricebook2.Name;
            }
        });
        component.set('v.listBuffer', lb);
    },

    setTableWidth: function(component) {
        clearTimeout(this.tableWidthTimer);
        const listBuffer = component.get('v.listBuffer');
        listBuffer.tableWidth = null;
        component.set('v.listBuffer', listBuffer);
        this.tableWidthTimer = setTimeout($A.getCallback(() => {
            listBuffer.tableWidth = component.find('serviceTable').getElement().clientWidth;
            component.set('v.listBuffer', listBuffer);
        }), 200);
    }
});