({
    syncProducts: function(component){
        var Wizard = component.get('v.Wizard');
        var productsFor = component.get('v.productsFor');

        var isQuoteTheSame = Wizard.currentQuote.record.Id === productsFor.quoteId;
        var isPricebookTheSame = Wizard.currentQuote.record.Pricebook2Id === productsFor.Pricebook2Id;

        if (!isQuoteTheSame || !isPricebookTheSame){
            this.getProductList(component);
        }

    },
    /**
     * Get List of products available for this quote
     */
    getProductList: function (component) {
        var helper = this;
        var Wizard = component.get('v.Wizard');

        const currentQuote = Wizard.currentQuote && Wizard.currentQuote.record;
        const currentQuoteId = currentQuote && currentQuote.Id;
        const currentQuotePbId = currentQuote && currentQuote.Pricebook2Id;
        const packageInfo = Wizard.primaryQuote && Wizard.primaryQuote.record && Wizard.primaryQuote.record.Package_Info__c;

        component.set("v.products", null);
        component.set('v.productsFor', {
            quoteId: currentQuoteId,
            Pricebook2Id: currentQuotePbId
        });

        RC.salesforce.request(component, 'c.getProducts', {
                quoteId: currentQuoteId,
                packageInfo: packageInfo
            })
            .then($A.getCallback(
                function (products) {
                    products = helper.sortProducts(products);
                    component.set("v.products", products);

                    // drop filters
                    helper.dropFilters(component);

                    // exclude products that user should not see
                    helper.excludeProds(component);

                    // hide products by User filters
                    helper.userFilterProds(component);

                    // scroll to top of the list
                    helper.scrollToTop(component);

                    // render product list
                    helper.renderProducts(component);

                }
            ))
            .catch($A.getCallback((error) => RC.salesforce.displayError('Failed to get products', error)));
    },
    /**
     * Exclude products that user should not see on the quote
     */
    excludeProds: function(component){
        var products = component.get('v.products');
        var quoteRecordTypeName = component.get('v.quoteRecordTypeName');
        var Wizard = component.get('v.Wizard');

        var userAvailableProducts = products.filter(function(prod){
            // B-2599 filter products by quote record type
            return prod.Product2.Product_Tab_Availability__c
                && prod.Product2.Product_Tab_Availability__c
                    .split(';')
                    .map(function(item){ return item.trim(); })
                    .includes(quoteRecordTypeName);
        });

        if ((quoteRecordTypeName == 'CC ProServ Quote' || quoteRecordTypeName == 'ProServ Quote')
            && (Wizard.currentQuote.record.Brand__c == 'RingCentral' || Wizard.currentQuote.record.Brand__c == 'RingCentral Canada')) {
            userAvailableProducts = userAvailableProducts.filter(function(prod){
                return !(prod.Product2.ExtID__c.endsWith('false_ccproserv')
                    && userAvailableProducts.find((p) => prod.Product2.Name == p.Product2.Name
                        && p.Product2.ExtID__c.endsWith('false_NA_ccproserv')));
            });
        };

        component.set('v.userAvailableProducts',userAvailableProducts);

    },
    /*
     *  User filters products
     */
    userFilterProds: function(component) {
        var userAvailableProducts = component.get("v.userAvailableProducts");
        var filterLevel = component.get("v.filterLevel");
        var Wizard = component.get('v.Wizard');

        // Filters
        var productNameFilter = component.get("v.productNameFilter");      // Product Name
        var typeFilter        = component.get("v.typeFilter");             // Type
        var categoryFilter    = component.get("v.categoryFilter");         // Category
        var planFilter        = component.get("v.planFilter");             // Charge Term
        var editionFilter     = component.get("v.editionFilter");          // Edition
        var seatsFilter = Number.parseInt(component.get("v.seatsFilter")); // Number Of Seats

        if(Wizard.currentQuote
            && !Wizard.opportunity.isClosed
            && !Wizard.currentQuote.isAgreement
            && !Wizard.currentQuote.isOnApproval
            && !Wizard.currentQuote.isCancelled
            && !Wizard.currentQuote.isSoldOrOutForSignature
            && (!Wizard.currentQuote || !Wizard.currentQuote.isInvalid)
            && !Wizard.opportunity.isPendingConfirmAndClose) {

            var typeOpts     = new Set(),
                categoryOpts = new Set(),
                planOpts     = new Set(),
                editionOpts  = new Set();

            var filteredProducts = [];
            userAvailableProducts.forEach(function(prod) {
                var add = true;

                // Filter by Name
                if (productNameFilter) {
                    var nm = prod.Product2.Name;
                    nm = nm.toLowerCase();
                    if (!nm.includes(productNameFilter.toLowerCase())) { add = false; }
                }

                // Filter By Type
                if (typeFilter && prod.Product2.Sub_Category__c !== typeFilter) {
                    add = false;
                }

                // Filter By Family
                if (categoryFilter && prod.Product2.Family !== categoryFilter) {
                    add = false;
                }

                // Filter by Plan
                if (planFilter && prod.Product2.Charge_Term__c !== planFilter) {
                    add = false;
                }

                // Filter by Edition
                if (editionFilter && prod.Product2.Edition__c !== editionFilter) {
                    add = false;
                }

                // Filter by Number Of Seats
                if (Number.isInteger(seatsFilter)) {
                    if (seatsFilter < prod.Product2.Seat_Range_Min__c ||
                        seatsFilter > prod.Product2.Seat_Range_Max__c) {
                        add = false;
                    }
                }

                if (add) {
                    filteredProducts.push(prod);

                    // Add filter options
                    if (prod.Product2.Sub_Category__c) {
                        typeOpts.add(prod.Product2.Sub_Category__c);
                    }
                    if (prod.Product2.Family) {
                        categoryOpts.add(prod.Product2.Family);
                    }
                    if (prod.Product2.Charge_Term__c) {
                        planOpts.add(prod.Product2.Charge_Term__c);
                    }
                    if (prod.Product2.Edition__c) {
                        editionOpts.add(prod.Product2.Edition__c);
                    }
                }
            });

            // Set filter Opts
            if (filterLevel === 0) {
                component.set('v.typeOpts',     this.createOpts(Array.from(typeOpts), true));
            }
            if (filterLevel === 1) {
                component.set('v.categoryOpts', this.createOpts(Array.from(categoryOpts)));
            }
            if (filterLevel === 2) {
                component.set('v.planOpts',     this.createOpts(Array.from(planOpts)));
            }
            if (filterLevel === 3) {
                component.set('v.editionOpts',  this.createOpts(Array.from(editionOpts)));
            }

            component.set("v.filteredProducts", filteredProducts);
        }
        this.renderProducts(component);
    },
    sortProducts: function(products) {
        products.sort(function(a, b) {
            return (b.Product2.Family === "Service") - (a.Product2.Family === "Service") || // service products first
                (b.Product2.Family < a.Product2.Family) - (a.Product2.Family < b.Product2.Family) || // by category
                (b.Product2.Name < a.Product2.Name) - (a.Product2.Name < b.Product2.Name) || // by name
                (b.Product2.Charge_Term__c < a.Product2.Charge_Term__c) - (a.Product2.Charge_Term__c < b.Product2.Charge_Term__c); // by plan
        });
        return products;
    },

    /**
     * Display message on
     *     - Closed Won
     *     - Active Agreement
     *     - Approval
     *     - Tab is disabled
     */
    displayMessages: function(component) {
        var Wizard = component.get('v.Wizard');
        // Closed Won
        component.set('v.messages.closedWon.active', Wizard.opportunity.isClosed);

        var isBillingOpportunity = Wizard.opportunity && Wizard.opportunity.record.Is_Billing_Opportunity__c;
        var isPrimaryQuoteOnApproval = Wizard.primaryQuote && Wizard.primaryQuote.isOnApproval ? Wizard.primaryQuote.isOnApproval : false;
        var isContactCenterQuote = Wizard.currentQuote && Wizard.currentQuote.isCC ? Wizard.currentQuote.isCC : false;

        // On Approval
        component.set(
            'v.messages.onApprove.active',
            (Wizard.currentQuote.isOnApproval || (isBillingOpportunity && isPrimaryQuoteOnApproval && isContactCenterQuote))
        );
        // Active Agreement
        component.set('v.messages.activeAgreement.active', Wizard.currentQuote.isAgreement);
        // (CC) ProServ Quote Canceled
        component.set('v.messages.engagementCancelled.active', Wizard.currentQuote.isCancelled);
        // (CC) ProServ Quote sold (Out Of Signature)
        component.set('v.messages.proServIsSold.active', Wizard.currentQuote.isSoldOrOutForSignature);
        // User don't have enough permissions
        component.set('v.messages.tabIsDisabled.active', !Wizard.currentQuote.isUserHasPermissionToEditQuote);
        // Quote is invalid
        component.set('v.messages.quoteInvalid.active', Wizard.currentQuote.isInvalid);
        // Pending Confirm&Close
        component.set('v.messages.pendingConfirmAndClose.active', Wizard.opportunity.isPendingConfirmAndClose);
    },
    /**
     * Creates array of maps for use in Select input options
     * Example helper.createOpts(['','one', {value: '2', label="two"}])
     * return [
     *        {value: '', label="--None--"},
     *        {value: 'one', label="one"},
     *        {value: '2', label="two"}
     *    ]
     *
     *  @param  opts       -- Values to create
     *  @param  substMain  -- Substitute 'Main' with 'RingCentral' in label
     *                        Required for Type filter
     */
    createOpts: function(opts, substMain){
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
                if (substMain && label === 'Main') {
                    label = 'RingCentral';
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
     * Empty All filters
     */
    dropFilters: function(component){
        component.set("v.productNameFilter","");// Product Name
        component.set("v.seatsFilter","");      // Number Of Seats
        component.set("v.editionFilter","");
        component.set("v.planFilter","");
        component.set("v.categoryFilter","");
        component.set("v.typeFilter","");
        component.set("v.filterLevel", 0);
    },
    /**
     * Set Filter Level
     */
    setFilterLevel: function(component){
        var typeFilter = component.get('v.typeFilter');
        var categoryFilter = component.get('v.categoryFilter');
        var planFilter = component.get('v.planFilter');
        var editionFilter = component.get('v.editionFilter');

        var newFilterLevel = editionFilter ? 4 : 3;
        newFilterLevel = planFilter ? newFilterLevel : 2;
        newFilterLevel = categoryFilter  ? newFilterLevel : 1;
        newFilterLevel = typeFilter ? newFilterLevel : 0;

        component.set('v.filterLevel', newFilterLevel);
    },
    /**
     * Check if elements should be displayed or Hidden
     */
    checkDisplaying: function(component){
        var typeFilter = component.get("v.typeFilter");
        var categoryFilter = component.get("v.categoryFilter");
        var Wizard = component.get('v.Wizard');

        var editionFilterHidden = true;
        var seatsFilterHidden = true;
        var productListHidden = false;

        var isBillingOpportunity = Wizard.opportunity.record.Is_Billing_Opportunity__c;
        var isPrimaryQuoteOnApproval = Wizard.primaryQuote && Wizard.primaryQuote.isOnApproval;
        var isContactCenterQuote = Wizard.currentQuote.isCC;

        if (!Wizard.currentQuote
            || Wizard.currentQuote.isAgreement
            || Wizard.currentQuote.isOnApproval
            || Wizard.opportunity.isClosed
            || !Wizard.currentQuote.isUserHasPermissionToEditQuote
            || Wizard.currentQuote.isCancelled
            || Wizard.currentQuote.isSoldOrOutForSignature
            || Wizard.currentQuote.isInvalid
            || Wizard.opportunity.isPendingConfirmAndClose
            || (isContactCenterQuote && (isBillingOpportunity && isPrimaryQuoteOnApproval))) {
            productListHidden = true;
        } else {
            if (typeFilter === 'Contact Center' && categoryFilter === 'CC Service') {
                editionFilterHidden = false;
                seatsFilterHidden = false;
            }
        }

        RC.cssUtils.toggleShow(component,'editionFilterContainer',!editionFilterHidden,'product-filter--hidden');
        RC.cssUtils.toggleShow(component,'seatsFilterContainer',!seatsFilterHidden,'product-filter--hidden');
        RC.cssUtils.toggleShow(component,'productList',!productListHidden);
        RC.cssUtils.toggleShow(component,'filters',!productListHidden);
    },
    /**
     * Scroll Service Plan List to Top
     */
    scrollToTop: function(component) {
        const tierListEl = component.find('productList') && component.find('productList').getElement();
        if (tierListEl) {
            tierListEl.scrollTop = 0;
            // this.renderProducts(component);
        }
    },
    /**
     *  Make Products in cart set with Product2Ids for use by Product Entries
     */
    makeCartItemsSet: function(component){
        var cartItems = component.get('v.cartItems');
        // Create set of cart items IDs
        var cartItemsSet = new Set();
        cartItems.forEach(function(item){
            cartItemsSet.add(item.Product2Id);
        });
        component.set('v.cartItemsSet',cartItemsSet);
    },

    renderProducts: function (component) {
        const el = component.find('productList') && component.find('productList').getElement();
        if (!el || !component.get('v.Tabs.products.isOpen')) {
            return;
        }
        const pHeight = 39;
        const itemsOnScreen = Math.ceil(el.clientHeight / pHeight);
        const additionalItemsCount = parseInt(itemsOnScreen / 2);
        const filteredProducts = component.get('v.filteredProducts');
        const currentIndex = parseInt(el.scrollTop / pHeight);
        let start = currentIndex - additionalItemsCount;
        start = start < 0 ? 0 : start;
        const end = currentIndex + itemsOnScreen + additionalItemsCount;
        const scrollProducts = filteredProducts.slice(start, end);
        let listBuffer = component.get('v.listBuffer');
        listBuffer.scrollBufferTop = filteredProducts.slice(0, start).length * pHeight;
        listBuffer.scrollBufferBottom = filteredProducts.slice(end, filteredProducts.length).length * pHeight;
        component.set('v.listBuffer', listBuffer);
        component.set('v.scrollProducts', scrollProducts);
        this.setTableWidth(component);
    },

    addEventListeners: function (component) {
        let helper = this;
        this.onResize = $A.getCallback(() => {
            clearTimeout(helper.scrollTimer);
            helper.scrollTimer = setTimeout($A.getCallback(() => {
                helper.renderProducts(component);
            }), 500);
        });
        window.addEventListener('resize', this.onResize);
    },

    removeEventListeners: function () {
        window.removeEventListener('resize', this.onResize);
    },

    setListBufferData: function(component){
        let lb = component.get('v.listBuffer');
        lb.name = '';
        (component.get('v.filteredProducts') || []).forEach(p => {
            if (lb.name.length < p.Product2.Name.length) {
                lb.name = p.Product2.Name;
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
            if (!component.find('productsTable')) {
                return;
            }
            listBuffer.tableWidth = component.find('productsTable').getElement().clientWidth;
            component.set('v.listBuffer', listBuffer);
        }), 200);
    }
});