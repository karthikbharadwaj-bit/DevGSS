({
    getNGBSSettings: function(component) {
        return RC.salesforce.request(component, 'c.getNGBSLicenseSettings', {})
            .then($A.getCallback(function (res) {
                let settings = component.get('v.hiddenNGBSLicenses');
                settings = JSON.parse(res).hiddenLicenseSettings;
                component.set('v.hiddenNGBSLicenses', settings);
            }));
    },

    getBInfo: function(component, entitlements, bId, pkg) {
        var helper = this;
        const pName = pkg.description;
        const pId = pkg.id;
        const pkgCatalogId = pkg.catalogId;
        const pkgCurrency = pkg.currency;
        let billingInfo = {};

        // Process package licenses to build quantity structure
        const billingInfoQuantity = helper.processPkgLicensesQuantity(pkg);

        return RC.salesforce.request(component, 'c.getBillingInfo', {billingId: bId, packageId: pId})
            .then($A.getCallback(function (res) {
                billingInfo = JSON.parse(res);
                const settings = component.get('v.hiddenNGBSLicenses');
                entitlements.active[pName] = entitlements.active[pName] ? entitlements.active[pName] : [];

                _.forEach(Object.keys(billingInfo), k => {
                    if (!helper.isHiddenLicense(settings, pkgCatalogId, billingInfo[k].catalogId)) {
                        const entitlement = helper.getBillingEntitlement(billingInfo[k], billingInfoQuantity[billingInfo[k].catalogId] || {}, pkgCurrency);
                        if (entitlement.DisplayQuantity__c > 0) {
                            entitlements.active[pName].push(entitlement);
                        }
                    }
                });
            }));

    },

    getGroupedBillingInfoFromController: function (component) {
        var helper = this;
        var billingId = component.get('v.billingId');
        var accId = component.get('v.accId');
        var entitlements = component.get('v.entitlements');
        entitlements = entitlements ? entitlements : {};
        entitlements.active = entitlements.active ? entitlements.active : {};

        if (!billingId || !accId) {
            return Promise.resolve();
        }

        return RC.salesforce.request(component, 'c.getPackagesFromBilling', {accId: accId, billingId: billingId})
            .then($A.getCallback(function (res) {
                if (!component.isValid()) return;

                var result = JSON.parse(res);
                var promiseList = [];

                // Make list of promise (get BillingInfo for each package)
                _.forEach(result, function (pkg) {
                    var promise = helper.getGroupedBInfoForPackage(component, entitlements, pkg, pkg.currency);
                    promiseList.push(promise);
                });

                // Resolve all promises
                return Promise.all(promiseList)
                    .then($A.getCallback(function (res) {
                        component.set('v.entitlements', entitlements);
                        return Promise.resolve(res);
                    }))
                    .catch($A.getCallback(function (error) {
                        console.error(RC.salesforce.getResponseError(error));
                        return Promise.reject(error);
                    }));

            }))
            .catch($A.getCallback(function (error) {
                console.error(RC.salesforce.getResponseError(error));
                return Promise.reject(error);
            }));
    },

    getGroupedBInfoForPackage: function(component, entitlements, pkg, currency) {
        var helper = this;
        const pName = pkg.description || pkg.name || 'Package ' + pkg.id;
        const pId = pkg.id;
        var settings = component.get('v.hiddenNGBSLicenses');

        return RC.salesforce.request(component, 'c.getBillingInfo', { billingId: pkg.billingId, packageId: pId})
            .then($A.getCallback(function (res) {
                var groupedLicenses = JSON.parse(res);

                // Process grouped licenses and filter out scheduledForRemoval
                var processedLicenses = helper.processGroupedLicensesForPackage(groupedLicenses, settings, currency);

                // Add to entitlements under package name
                if (processedLicenses && processedLicenses.length > 0) {
                    entitlements.active[pName] = entitlements.active[pName] ? entitlements.active[pName] : [];
                    entitlements.active[pName] = entitlements.active[pName].concat(processedLicenses);
                }
            }));
    },

    processGroupedLicensesForPackage: function(groupedLicenses, settings, currency) {
        var helper = this;
        var result = [];

        _.forEach(groupedLicenses, function(license) {
            // Skip licenses with scheduledForRemoval: true
            if (license.scheduledForRemoval) {
                return;
            }

            // Skip hidden licenses based on settings
            if (helper.isHiddenLicense(settings, null, license.catalogId)) {
                return;
            }

            // Convert grouped license to display format
            var displayLicense = helper.convertGroupedLicenseToDisplayFormat(license, currency);

            if (displayLicense) {
                result.push(displayLicense);
            }
        });

        return result;
    },

    convertGroupedLicenseToDisplayFormat: function(license, currency) {
        // Convert the grouped license structure to match existing entitlement format
        if (!$A.util.isEmpty(license.childLicenses)) {
            license.childLicenses = license.childLicenses.map(child => this.convertGroupedLicenseToDisplayFormat(child, currency));
        }
        const dVal = license.discountValue;
        const unit = this.getDiscountUnit(dVal);

        return {
            description: license.description,
            billingCycleDuration: license.billingCycleDuration,
            price: license.price,
            discountAmount: license.discountAmount,
            qty: license.qty,
            dateRangeStart: license.dateRangeStart,
            dateRangeEnd: license.dateRangeEnd,
            isGrouped: license.isGrouped,
            childLicenses: license.childLicenses || [],

            // Convert to display format similar to existing entitlements
            DisplayQuantity__c: license.qty || 0,
            CurrencyIsoCode: currency ? currency : 'USD',
            Product__r: {
                Name: license.description,
                Charge_Term__c: license.billingCycleDuration
            },
            Start_Date__c: license.dateRangeStart,
            End_Date__c: license.dateRangeEnd,
            Price__c: license.price,
            Discount_Type__c: unit,
            Discount__c: dVal && dVal.value,
        };
    },

    getEntsFromController: function(component) {
        var helper = this;

        return RC.salesforce.request(component, 'c.getEntitlements', {
            accId: component.get('v.accId'),
            billingId: component.get('v.billingId')
        })
            .then($A.getCallback(function(res) {
                if(!component.isValid()) return;

                // If exist any message
                if(Array.isArray(res.messages) && res.messages.length) {
                    var messagesToShow = [];
                    var severity;
                    res.messages.forEach((message) => {
                        messagesToShow.push(message.message);
                        severity = message.severity;
                    });
                    helper.showToast(severity, '', messagesToShow);
                }

                // entitlement has sorting by start date and name
                // Sort Entitlements
                var result = helper.sortBy(
                    res.data.entitlementsFromDWHSync,
                    {type: 'date', value: 'Start_Date__c', order: 'desc'},
                    {type: '', value: 'Name', order: 'desc'}
                );
                for(var i = 0; i < result.length; i++) {
                    if(res.data.entitlementDetails
                        && res.data.entitlementDetails.hasOwnProperty(result[i].Id)
                        && result[i].Product__r.Charge_Term__c !== 'One - Time') {
                        result[i].rampUps = res.data.entitlementDetails[result[i].Id].filter(function(item) {
                            return item.RampUp__c ? item.RampUp__c * 1 > 0 : false;
                        }).map(function(item) {
                            const endDate = new Date(item.RampUpStartDate__c);
                            endDate.setDate(endDate.getDate() + item.RampUp__c * 1);
                            return {
                               Id: item.Id,
                               RampUp__c: item.RampUp__c + ' Days',
                               QuantityOrThreshold__c: item.QuantityOrThreshold__c,
                               RampUpStartDate__c: item.RampUpStartDate__c,
                               RampUpEndDate__c: helper.ISODateString(endDate)
                           };
                        });
                    } else {
                        result[i].rampUps = [];
                    }
                }

                for (var i = 0; i < result.length; i++) {
                    result[i].Order_Products__r = helper.sortBy(result[i].Order_Products__r, {
                        type: 'date',
                        value: 'Order.Submitted_Date__c',
                        order: 'desc'
                    });
                }

                // Create active/inactive list
                var entitlements = {};

                entitlements.active = _.where(result, {Active__c: true});
                entitlements.inactive = _.where(result, {Active__c: false});

                entitlements.active = _.groupBy(entitlements.active, function(item){
                    return item.Product__r.Sub_Category__c;
                });
                entitlements.inactive = _.groupBy(entitlements.inactive, function(item){
                    return item.Product__r.Sub_Category__c;
                });

                component.set('v.entitlements', entitlements);
            }));
    },

    getAssetsFromController: function(component){
        var helper = this;
        return RC.salesforce.request(component, 'c.getAssets', {accId: component.get('v.accId')})
            .then($A.getCallback(function(getAssetsResult) {
                var assetsData = getAssetsResult.data.assets.map(function (asset) {
                    asset.sobjectType = RC.CONSTANTS.ASSET.SOBJECT_TYPE;
                    return asset;
                });

                var assets = {};
                assets.active = _.where(assetsData, {Active__c: true});
                assets.inactive = _.where(assetsData, {Active__c: false});

                assets.active = _.groupBy(assets.active, function(item){
                    return item.Product2.Sub_Category__c;
                });
                assets.inactive = _.groupBy(assets.inactive, function(item){
                    return item.Product2.Sub_Category__c;
                });

                var result = helper.sortBy(
                    getAssetsResult.data.assets,
                    {type: 'date', value: 'Start_Date__c', order: 'desc'},
                    {type: '', value: 'Name', order: 'desc'}
                );

                for (var i = 0; i < result.length; i++) {
                    result[i].Order_Products__r = helper.sortBy(result[i].Order_Products__r, {
                        type: 'date',
                        value: 'Order.Submitted_Date__c',
                        order: 'desc'
                    });
                }

                component.set('v.assets', assets);
            }))
            .catch($A.getCallback(function (error) {
                console.error(RC.salesforce.getResponseError(error));
                helper.showToast('error', 'Failed to get Assets', RC.salesforce.getResponseError(error));
            }));
    },

    showToast: function(theme, header, message) {
        $A.get("e.c:ToastEvent").setParams({
                theme: theme.toLowerCase(),
                header: header,
                details: message,
                defaultTimeout: false
        }).fire();
    },

    sortBy: function(array, field1, field2, field3) {
        var helper = this;
        if(!array || !Array.isArray(array)) return array;

        return array.sort(function (a, b) {
            var r;
            var result1 = r = helper.getSortValueByType(a, b, field1);

            if(field2) {
                var result2 = helper.getSortValueByType(a, b, field2);
                r = result1 || result2;
            }

            if(field3) {
                var result3 = helper.getSortValueByType(a, b, field3);
                r = result1 || result2 || result3;
            }

            return r;
        });
    },

    getSortValueByType: function(a, b, field) {
        var f = field.value.split('.');
        var _a = f.length === 1 ? a[field.value] : a[f[0]][f[1]];
        var _b = f.length === 1 ? b[field.value] : b[f[0]][f[1]];

        // Date
        if(field.type === 'date') {
            if(field.order === 'asc') {
                return new Date(_a).getTime() - new Date(_b).getTime()
            } else {
                return new Date(_b).getTime() - new Date(_a).getTime()
            }
        }
        // Boolean
        else if(field.type === 'boolean') {
            if(field.order === 'asc') {
                // false values first
                return (_a === _b)? 0 : _a? 1 : -1;
            } else {
                // true values first
                return (_a === _b)? 0 : _a? -1 : 1;
            }
        }
        // Other
        else {
            if(field.order === 'asc') {
                return _a < _b;
            } else {
                return _b < _a;
            }
        }
    },

    showPrompt: function(component, value, text) {
        component.set('v.isLoadingEntitlements', false);
        component.set('v.prompt.text', '');

        var modal = component.find('modal');
        var modalBg = component.find('modal-bg');

        if(value) {
            $A.util.addClass(modalBg, 'slds-backdrop--open');
            $A.util.addClass(modal, 'slds-fade-in-open');
            $A.util.removeClass(modal, 'slds-hide');
            component.set('v.prompt.text', text);
        } else {
            $A.util.removeClass(modalBg, 'slds-backdrop--open');
            $A.util.removeClass(modal, 'slds-fade-in-open');
            $A.util.addClass(modal, 'slds-hide');
        }

    },

    getBillingEntitlement: function(license, billingInfoQuantity, currency) {
        const dVal = license.discountAmount && license.discountValue;
        const unit = this.getDiscountUnit(dVal);
        const price = license.amount / license.qty;
        const qty = billingInfoQuantity
            ? billingInfoQuantity.active || 0
            : license.qty;

        return {
            CurrencyIsoCode: currency ? currency : 'USD',

            Discount_Type__c: unit,
            Discount__c: dVal && dVal.value,

            DisplayQuantity__c: qty,
            Order_Products__r: [],
            Price__c: price,
            Product__r: {
                Charge_Term__c: license.billingCycleDuration,
                Name: license.description,
            },
            Start_Date__c: $A.localizationService.formatDate(license.dateRangeStart),
            End_Date__c: $A.localizationService.formatDate(license.dateRangeEnd)
        };
    },

    getAccountFromController: function(component){
        var helper = this;
        return RC.salesforce.request(component, 'c.getAccount', {accId: component.get('v.accId')})
            .then($A.getCallback(function (account) {
                component.set('v.account', account);
                component.set('v.currency', account.CurrencyIsoCode);
            }))
            .catch($A.getCallback(function (error) {
                console.error(RC.salesforce.getResponseError(error));
                helper.showToast('error', 'Failed to get Account', RC.salesforce.getResponseError(error));
            }));
    },

    getActiveSalesAgreement: function(component) {
        var helper = this;
        return RC.salesforce.request(component, 'c.getActiveSalesAgreement', {accountId: component.get('v.accId')})
            .then($A.getCallback(function (quote) {
                component.set('v.activeSalesAgreement', quote);
            }))
            .catch($A.getCallback(function (error) {
                console.error(RC.salesforce.getResponseError(error));
                helper.showToast('error', 'Failed to get Active Sales Agreement', RC.salesforce.getResponseError(error));
            }));
    },

    buildCategories: function(component){
        var categories = [
            {
                header: {
                    name: 'Active Entitlements',
                    startDate: 'Start Date',
                    endDate: 'End Date',
                    chargeTerm: 'Charge Term',
                    quantity: 'Quantity',
                    listPrice: 'List Price',
                    discount: 'Discount',
                    yourPrice: 'Your Price',
                    total: 'Total'
                },
                items: component.get('v.entitlements.active')
            },
            {
                header: {
                    name: 'Inactive Entitlements',
                    startDate: 'Start Date',
                    endDate: 'End Date',
                    chargeTerm: 'Charge Term',
                    quantity: 'Quantity',
                    listPrice: 'List Price',
                    discount: 'Discount',
                    yourPrice: 'Your Price',
                    total: 'Total'
                },
                items: component.get('v.entitlements.inactive')
            },
            {
                header: {
                    name: 'Active Assets',
                    startDate: 'Start Date',
                    endDate: ' ',
                    chargeTerm: 'Charge Term',
                    quantity: 'Quantity Delivered/Total',
                    quantityColspan: 2,
                    listPrice: ' ',
                    isListPriceHidden: true,
                    discount: ' ',
                    yourPrice: ' ',
                    total: ' '
                },
                items: component.get('v.assets.active')
            },
            {
                header: {
                    name: 'Inactive Assets',
                    startDate: 'Start Date',
                    endDate: ' ',
                    chargeTerm: 'Charge Term',
                    quantity: 'Quantity Delivered/Total',
                    quantityColspan: 2,
                    listPrice: ' ',
                    isListPriceHidden: true,
                    discount: ' ',
                    yourPrice: ' ',
                    total: ' '
                },
                items: component.get('v.assets.inactive')
            }
        ];

        var nonEmptyCategories = categories.filter(function (category) {
            return !_.isEmpty(category.items);
        });

        component.set('v.categories', nonEmptyCategories);
    },

    addEventListeners: function(component) {
        var helper = this;

        component.find('entitlementsView').getElement().addEventListener('scroll', $A.getCallback(function() {
            helper.fixedHeader(component);
        }));

        window.addEventListener('scroll', $A.getCallback(function() {
            helper.fixedHeader(component);
        }));

        window.addEventListener('resize', $A.getCallback(function() {
            helper.fixedHeader(component);
        }));
    },

    fixedHeader: function(component){
        try {
            var entitlementsViewEl = component.find('entitlementsView').getElement();
            var entitlementsViewRect = entitlementsViewEl.getBoundingClientRect();

            var headerRowArr = component.find('header-row');
            if (!headerRowArr){
                component.set('v.fixedheader', null);
                return;
            }
            headerRowArr = Array.isArray(headerRowArr) ? headerRowArr : [headerRowArr];

            var headerHeightRem = 2;
            var headerHeightPx = headerHeightRem * parseFloat(getComputedStyle(document.documentElement).fontSize);

            var currentCategoryIndex = null;
            var pushedOutPx = 0;
            headerRowArr.reverse().forEach(function(headerRowCmp, index){
                var headerEl = headerRowCmp.getElement();
                var headerTop = headerEl ? headerEl.getBoundingClientRect().top : 0;
                var topOffset = entitlementsViewRect.top - headerTop;
                var isScrolledOver = topOffset >= 0;
                var isFixed = isScrolledOver && currentCategoryIndex === null;
                var isPushingOut = - headerHeightPx < topOffset && topOffset < 0;

                if (isFixed){
                    currentCategoryIndex = component.get('v.categories').length - index - 1;
                }

                if (isPushingOut){
                    pushedOutPx = headerHeightPx + topOffset;
                }

            });

            var newCategory = component.get('v.categories')[currentCategoryIndex];
            if (!newCategory)
                return;

            if (component.get('v.fixedheader.name') !== newCategory.header.name){
                var categories = component.get('v.categories');
                var hasActiveEntitlements = component.get('v.entitlements.active');
                var targetCategoryName = hasActiveEntitlements ? 'Active Entitlements' : 'Inactive Entitlements';
                var matchedCategory = categories.find((category)=>{
                     return category.header.name == targetCategoryName;
                });

                if(matchedCategory){
                    component.set('v.fixedheader', matchedCategory.header);
                }else{
                    component.set('v.fixedheader', null);
                }
            }

            var isPushed = pushedOutPx !== 0;
            if (isPushed){
                component.find('fixed-header').getElement().classList.add('fixed-header__pushed');
                var absolutePositionTop = entitlementsViewEl.scrollTop - pushedOutPx;
                component.find('fixed-header').getElement().style.top = absolutePositionTop + 'px';
            } else {
                component.find('fixed-header').getElement().classList.remove('fixed-header__pushed');
                var fixedPositionTop = entitlementsViewRect.top;
                component.find('fixed-header').getElement().style.top = fixedPositionTop + 'px';
            }
            this.setFixedHeaderWidth(component);
        } catch(e) {
            console.error('fixedHeader()', e);
        }
    },

    setFixedHeaderWidth: function(component){
        var auraIds = [
            'name',
            'startDate',
            'endDate',
            'chargeTerm',
            'quantity',
            'listPrice',
            'discount',
            'yourPrice',
            'total'
        ];

        auraIds.forEach(function(id) {
            var tableCell = component.find(id + '-header');
            tableCell = Array.isArray(tableCell) ? tableCell[0] : tableCell;
            if(tableCell){
                var tableCellElement = tableCell.getElement();
                var tableCellWidth = tableCellElement ? tableCellElement.getBoundingClientRect().width : 0;
                component.find(id + '-fixed-header').getElement().style.width = tableCellWidth + 'px';
            }
        });
    },

    isHiddenLicense: function(settings, pkgId, licenseId) {
        const searchKey = settings[pkgId] ? pkgId : 'All';
            return _.includes(settings[searchKey], licenseId);
    },

    processLicensesRecursive: function(licenses, result) {
        const helper = this;
        if (!licenses || !licenses.length) {
            return;
        }

        _.forEach(licenses, function(license) {
            if (!result[license.catalogId]) {
                result[license.catalogId] = {
                    pendingRemoval: 0,
                    active: 0
                };
            }

            const key = license.scheduledForRemoval ? 'pendingRemoval' : 'active';
            result[license.catalogId][key] += license.qty || 0;

            // Process sublicenses recursively
            if (license.subLicenses && license.subLicenses.length) {
                helper.processLicensesRecursive(license.subLicenses, result);
            }
        });
    },

    processPkgLicensesQuantity: function(pkg) {
        const helper = this;
        const result = {};

        // Start processing from package licenses
        if (pkg.licenses) {
            helper.processLicensesRecursive(pkg.licenses, result);
        }

        return result;
    },

    getDiscountUnit: function(discount) {
        return discount ? discount.unit === 'Percent' ? 'Percentage' : discount.unit : null;
    },
    ISODateString: function(d) {
        function pad(n) {return n<10 ? '0'+n : n}
        return d.getUTCFullYear()+'-'
            + pad(d.getUTCMonth()+1)+'-'
            + pad(d.getUTCDate());
    },

    escapeXml: function(unsafe) {
        if (!unsafe) return '';
        return unsafe.toString()
            .replace('&', '&amp;')
            .replace('<', '&lt;')
            .replace('>', '&gt;')
            .replace('"', '&quot;')
            .replace("'", '&apos;');
    },

    generateDynamicTable: function(component, entitlements) {
        var helper = this;
        var rows = [];
        var currentRow = 7; // Start after the header rows
        var mergeCells = []; // Array to store merge cell definitions

        // Maintaining rowNumberCount for specific cases
        let subTotalRowNumberCount = currentRow;
        let fscTableFirstRowNumberCount = currentRow;
        let fscTableLastRowNumberCount = currentRow;

        // Process active entitlements
        try {
            if (entitlements && entitlements.active) {
                Object.keys(entitlements.active).forEach(function(key) {
                    // Add category header
                    rows.push(
                        '<row r="' + currentRow + '">' +
                            '<c r="A' + currentRow + '" t="inlineStr" s="8"><is><t>' + key + '</t></is></c>' +
                            '<c r="B' + currentRow + '" s="3"/>' +
                            '<c r="C' + currentRow + '" s="3"/>' +
                            '<c r="D' + currentRow + '" s="3"/>' +
                            '<c r="E' + currentRow + '" s="3"/>' +
                            '<c r="F' + currentRow + '" s="3"/>' +
                            '<c r="G' + currentRow + '" s="3"/>' +
                            '<c r="H' + currentRow + '" s="3"/>' +
                            '<c r="I' + currentRow + '" s="3"/>' +
                            '<c r="J' + currentRow + '" t="inlineStr" s="16"><is><t>' + key + '</t></is></c>' +
                            '<c r="K' + currentRow + '" s="16"/>' +
                            '<c r="L' + currentRow + '" s="16"/>' +
                            '<c r="M' + currentRow + '" s="16"/>' +
                            '<c r="N' + currentRow + '" s="16"/>' +
                            '<c r="O' + currentRow + '" t="inlineStr" s="18"><is><t>' + key + '</t></is></c>' +
                            '<c r="P' + currentRow + '" s="18"/>' +
                            '<c r="Q' + currentRow + '" s="18"/>' +
                            '<c r="R' + currentRow + '" s="18"/>' +
                            '<c r="S' + currentRow + '" s="16"/>' +
                            '<c r="T' + currentRow + '" t="inlineStr" s="7"><is><t>' + key + '</t></is></c>' +
                            '<c r="U' + currentRow + '" s="7"/>' +
                            '<c r="V' + currentRow + '" s="7"/>' +
                            '<c r="W' + currentRow + '" s="7"/>' +
                            '<c r="X' + currentRow + '" s="16"/>' +
                            '<c r="Y' + currentRow + '" t="inlineStr" s="23"><is><t>' + key + '</t></is></c>' +
                            '<c r="Z' + currentRow + '" s="23"/>' +
                            '<c r="AA' + currentRow + '" s="23"/>' +
                            '<c r="AB' + currentRow + '" s="23"/>' +
                            '<c r="AC' + currentRow + '" s="16"/>' +
                            '<c r="AD' + currentRow + '" t="inlineStr" s="26"><is><t>' + key + '</t></is></c>' +
                            '<c r="AE' + currentRow + '" s="26"/>' +
                            '<c r="AF' + currentRow + '" s="26"/>' +
                            '<c r="AG' + currentRow + '" s="26"/>' +
                            '<c r="AH' + currentRow + '" s="16"/>' +
                            '<c r="AI' + currentRow + '" t="inlineStr" s="29"><is><t>' + key + '</t></is></c>' +
                            '<c r="AJ' + currentRow + '" s="29"/>' +
                            '<c r="AK' + currentRow + '" s="29"/>' +
                            '<c r="AL' + currentRow + '" s="29"/>' +
                            '<c r="AM' + currentRow + '" s="16"/>' +
                        '</row>'
                    );
                    // Add merge cell for this category header
                    mergeCells.push('<mergeCell ref="A' + currentRow + ':I' + currentRow + '"/>');//Current Table
                    mergeCells.push('<mergeCell ref="J' + currentRow + ':M' + currentRow + '"/>');//Proposal Table
                    mergeCells.push('<mergeCell ref="O' + currentRow + ':R' + currentRow + '"/>');//12 Month Table
                    mergeCells.push('<mergeCell ref="T' + currentRow + ':W' + currentRow + '"/>');//24 Month Table
                    mergeCells.push('<mergeCell ref="Y' + currentRow + ':AB' + currentRow + '"/>');//36 Month Table
                    mergeCells.push('<mergeCell ref="AD' + currentRow + ':AG' + currentRow + '"/>');//48 Month Table
                    mergeCells.push('<mergeCell ref="AI' + currentRow + ':AL' + currentRow + '"/>');//60 Month Table
                    currentRow++;

                    // Add items for this category
                    entitlements.active[key].forEach(function(item) {
                        // Calculate current price based on discount
                        var calculatedPrice = 0;
                        try {
                            calculatedPrice = item.Price__c || 0;
                            if (item.Discount_Type__c === 'Percentage') {
                                calculatedPrice = item.Price__c * (1 - (item.Discount__c || 0) / 100);
                            } else if (item.Discount_Type__c === 'Currency' || item.Discount_Type__c === 'Money') {
                                calculatedPrice = item.Price__c - (item.Discount__c || 0);
                            }
                        } catch (error) {
                            console.error('Error calculating price for item:', error);
                            calculatedPrice = 0;
                        }
                        // List Price Monthly (export) - if ChargeTerm__c annual then divide by 12 otherwise same value
                        // 
                        var listPriceMonthly = item.Product__r.Charge_Term__c === 'Annual' ? (item.Price__c || 0) / 12 : (item.Price__c || 0);
                        var calculatedPriceMonthly = item.Product__r.Charge_Term__c === 'Annual' ? (calculatedPrice || 0) / 12 : (calculatedPrice || 0);

                        rows.push(
                            '<row r="' + currentRow + '">' +
                                '<c r="A' + currentRow + '" t="inlineStr" s="3"><is><t>' + helper.escapeXml(item.Product__r.Name || '') + '</t></is></c>' +
                                '<c r="B' + currentRow + '" t="n" s="6"><v>' + (item.DisplayQuantity__c || 0) + '</v></c>' +
                                '<c r="C' + currentRow + '" t="n" s="13"><v>' + listPriceMonthly + '</v></c>' +
                                '<c r="D' + currentRow + '" t="n" s="13"><v>' + calculatedPriceMonthly + '</v></c>' +
                                '<c r="E' + currentRow + '" t="n" s="13"><f>D' + currentRow + '*12</f></c>' +
                                '<c r="F' + currentRow + '" t="n" s="13"><f>B' + currentRow + '*C' + currentRow + '</f></c>' +
                                '<c r="G' + currentRow + '" t="n" s="10"><f>1-(D' + currentRow + '/C' + currentRow + ')</f></c>' +
                                '<c r="H' + currentRow + '" t="n" s="13"><f>D' + currentRow + '*B' + currentRow + '</f></c>' +
                                '<c r="I' + currentRow + '" t="n" s="13"><f>H' + currentRow + '*12</f></c>' +
                                '<c r="J' + currentRow + '" t="n" s="97"><v>0</v></c>' +
                                '<c r="K' + currentRow + '" t="n" s="6"><f>B' + currentRow + '+J' + currentRow + '</f></c>' +
                                '<c r="L' + currentRow + '" t="n" s="13"><f>C' + currentRow + '</f></c>' +
                                '<c r="M' + currentRow + '" t="n" s="13"><f>L' + currentRow + '*K' + currentRow + '</f></c>' +
                                '<c r="N' + currentRow + '" s="16"/>' +
                                '<c r="O' + currentRow + '" t="n" s="13"><f>D' + currentRow + '</f></c>' +
                                '<c r="P' + currentRow + '" t="n" s="10"><f>1-(O' + currentRow + '/L' + currentRow + ')</f></c>' +
                                '<c r="Q' + currentRow + '" t="n" s="13"><f>K' + currentRow + '*O' + currentRow + '</f></c>' +
                                '<c r="R' + currentRow + '" t="n" s="13"><f>Q' + currentRow + '*12</f></c>' +
                                '<c r="S' + currentRow + '" s="16"/>' +
                                '<c r="T' + currentRow + '" t="n" s="13"><f>D' + currentRow + '</f></c>' +
                                '<c r="U' + currentRow + '" t="n" s="10"><f>1-(T' + currentRow + '/L' + currentRow + ')</f></c>' +
                                '<c r="V' + currentRow + '" t="n" s="13"><f>K' + currentRow + '*T' + currentRow + '</f></c>' +
                                '<c r="W' + currentRow + '" t="n" s="13"><f>V' + currentRow + '*12</f></c>' +
                                '<c r="X' + currentRow + '" s="16"/>' +
                                '<c r="Y' + currentRow + '" t="n" s="13"><f>D' + currentRow + '</f></c>' +
                                '<c r="Z' + currentRow + '" t="n" s="10"><f>1-(Y' + currentRow + '/L' + currentRow + ')</f></c>' +
                                '<c r="AA' + currentRow + '" t="n" s="13"><f>Y' + currentRow + '*K' + currentRow + '</f></c>' +
                                '<c r="AB' + currentRow + '" t="n" s="13"><f>AA' + currentRow + '*12</f></c>' +
                                '<c r="AC' + currentRow + '" s="16"/>' +
                                '<c r="AD' + currentRow + '" t="n" s="13"><f>D' + currentRow + '</f></c>' +
                                '<c r="AE' + currentRow + '" t="n" s="10"><f>1-(AD' + currentRow + '/L' + currentRow + ')</f></c>' +
                                '<c r="AF' + currentRow + '" t="n" s="13"><f>AD' + currentRow + '*K' + currentRow + '</f></c>' +
                                '<c r="AG' + currentRow + '" t="n" s="13"><f>AF' + currentRow + '*12</f></c>' +
                                '<c r="AH' + currentRow + '" s="16"/>' +
                                '<c r="AI' + currentRow + '" t="n" s="13"><f>D' + currentRow + '</f></c>' +
                                '<c r="AJ' + currentRow + '" t="n" s="10"><f>1-(AI' + currentRow + '/L' + currentRow + ')</f></c>' +
                                '<c r="AK' + currentRow + '" t="n" s="13"><f>AI' + currentRow + '*K' + currentRow + '</f></c>' +
                                '<c r="AL' + currentRow + '" t="n" s="13"><f>AK' + currentRow + '*12</f></c>' +
                                '<c r="AM' + currentRow + '" s="16"/>' +
                            '</row>'
                        );
                        currentRow++;
                    });
                });

                rows.push(
                    '<row r="' + currentRow + '">' +
                        '<c r="A' + currentRow + '" s="5"/>' +
                        '<c r="B' + currentRow + '" s="5"/>' +
                        '<c r="C' + currentRow + '" s="5"/>' +
                        '<c r="D' + currentRow + '" s="5"/>' +
                        '<c r="E' + currentRow + '" t="inlineStr" s="11"><is><t>Subtotal</t></is></c>' +
                        '<c r="F' + currentRow + '" t="n" s="14"><f>SUM(F8:F' + (currentRow-1) + ')</f></c>' +
                        '<c r="G' + currentRow + '" t="n" s="12"><f>1-(H' + (currentRow) + '/F' + (currentRow) + ')</f></c>' +
                        '<c r="H' + currentRow + '" t="n" s="14"><f>SUM(H8:H' + (currentRow-1) + ')</f></c>' +
                        '<c r="I' + currentRow + '" t="n" s="14"><f>SUM(I8:I' + (currentRow-1) + ')</f></c>' +
                        '<c r="J' + currentRow + '" s="16"/>' +
                        '<c r="K' + currentRow + '" s="16"/>' +
                        '<c r="L' + currentRow + '" t="inlineStr" s="16"><is><t>Subtotal</t></is></c>' +
                        '<c r="M' + currentRow + '" t="n" s="17"><f>SUM(M8:M' + (currentRow-1) + ')</f></c>' +
                        '<c r="N' + currentRow + '" s="16"/>' +
                        '<c r="O' + currentRow + '" t="inlineStr" s="18"><is><t>Subtotal</t></is></c>' +
                        '<c r="P' + currentRow + '" t="n" s="20"><f>($M$' + (currentRow) + '-Q' + (currentRow) + ')/$M$' + (currentRow) + '</f></c>' +
                        '<c r="Q' + currentRow + '" t="n" s="19"><f>SUM(Q8:Q' + (currentRow-1) + ')</f></c>' +
                        '<c r="R' + currentRow + '" t="n" s="19"><f>SUM(R8:R' + (currentRow-1) + ')</f></c>' +
                        '<c r="S' + currentRow + '" s="16"/>' +
                        '<c r="T' + currentRow + '" t="inlineStr" s="7"><is><t>Subtotal</t></is></c>' +
                        '<c r="U' + currentRow + '" t="n" s="22"><f>($M$' + (currentRow) + '-V' + (currentRow) + ')/$M$' + (currentRow) + '</f></c>' +
                        '<c r="V' + currentRow + '" t="n" s="21"><f>SUM(V8:V' + (currentRow-1) + ')</f></c>' +
                        '<c r="W' + currentRow + '" t="n" s="21"><f>SUM(W8:W' + (currentRow-1) + ')</f></c>' +
                        '<c r="X' + currentRow + '" s="16"/>' +
                        '<c r="Y' + currentRow + '" t="inlineStr" s="23"><is><t>Subtotal</t></is></c>' +
                        '<c r="Z' + currentRow + '" t="n" s="25"><f>($M$' + (currentRow) + '-AA' + (currentRow) + ')/$M$' + (currentRow) + '</f></c>' +
                        '<c r="AA' + currentRow + '" t="n" s="24"><f>SUM(AA8:AA' + (currentRow-1) + ')</f></c>' +
                        '<c r="AB' + currentRow + '" t="n" s="24"><f>SUM(AB8:AB' + (currentRow-1) + ')</f></c>' +
                        '<c r="AC' + currentRow + '" s="16"/>' +
                        '<c r="AD' + currentRow + '" t="inlineStr" s="26"><is><t>Subtotal</t></is></c>' +
                        '<c r="AE' + currentRow + '" t="n" s="28"><f>($M$' + (currentRow) + '-AF' + (currentRow) + ')/$M$' + (currentRow) + '</f></c>' +
                        '<c r="AF' + currentRow + '" t="n" s="27"><f>SUM(AF8:AF' + (currentRow-1) + ')</f></c>' +
                        '<c r="AG' + currentRow + '" t="n" s="27"><f>SUM(AG8:AG' + (currentRow-1) + ')</f></c>' +
                        '<c r="AH' + currentRow + '" s="16"/>' +
                        '<c r="AI' + currentRow + '" t="inlineStr" s="29"><is><t>Subtotal</t></is></c>' +
                        '<c r="AJ' + currentRow + '" t="n" s="31"><f>($M$' + (currentRow) + '-AK' + (currentRow) + ')/$M$' + (currentRow) + '</f></c>' +
                        '<c r="AK' + currentRow + '" t="n" s="30"><f>SUM(AK8:AK' + (currentRow-1) + ')</f></c>' +
                        '<c r="AL' + currentRow + '" t="n" s="30"><f>SUM(AL8:AL' + (currentRow-1) + ')</f></c>' +
                        '<c r="AM' + currentRow + '" s="16"/>' +
                    '</row>'
                );
                subTotalRowNumberCount = currentRow;
                currentRow++;
                fscTableFirstRowNumberCount = currentRow;
                // Heading for all the FSC Month table
                rows.push(
                    '<row r="' + currentRow + '">' +
                        '<c r="A' + currentRow + '" s="5"/>' +
                        '<c r="B' + currentRow + '" s="5"/>' +
                        '<c r="C' + currentRow + '" s="5"/>' +
                        '<c r="D' + currentRow + '" s="5"/>' +
                        '<c r="E' + currentRow + '" s="5"/>' +
                        '<c r="F' + currentRow + '" s="5"/>' +
                        '<c r="G' + currentRow + '" s="5"/>' +
                        '<c r="H' + currentRow + '" s="5"/>' +
                        '<c r="I' + currentRow + '" s="5"/>' +
                        '<c r="J' + currentRow + '" s="5"/>' +
                        '<c r="K' + currentRow + '" s="5"/>' +
                        '<c r="L' + currentRow + '" s="5"/>' +
                        '<c r="M' + currentRow + '" s="5"/>' +
                        '<c r="N' + currentRow + '" s="5"/>' +
                        '<c r="O' + currentRow + '" t="inlineStr" s="75"><is><t>FSC Months:</t></is></c>' +
                        '<c r="P' + currentRow + '" t="n" s="76"><v>0</v></c>' +
                        '<c r="Q' + currentRow + '" s="76"/>' +
                        '<c r="R' + currentRow + '" t="n" s="77"><f>B' + (currentRow + 7) + '*P' + (currentRow) + '</f></c>' +
                        '<c r="S' + currentRow + '" s="5"/>' +
                        '<c r="T' + currentRow + '" t="inlineStr" s="75"><is><t>FSC Months:</t></is></c>' +
                        '<c r="U' + currentRow + '" t="n" s="76"><v>0</v></c>' +
                        '<c r="V' + currentRow + '" s="76"/>' +
                        '<c r="W' + currentRow + '" t="n" s="77"><f>B' + (currentRow + 8) + '*U' + (currentRow) + '</f></c>' +
                        '<c r="X' + currentRow + '" s="5"/>' +
                        '<c r="Y' + currentRow + '" t="inlineStr" s="75"><is><t>FSC Months:</t></is></c>' +
                        '<c r="Z' + currentRow + '" t="n" s="76"><v>0</v></c>' +
                        '<c r="AA' + currentRow + '" s="76"/>' +
                        '<c r="AB' + currentRow + '" t="n" s="77"><f>B' + (currentRow + 9) + '*Z' + (currentRow) + '</f></c>' +
                        '<c r="AC' + currentRow + '" s="5"/>' +
                        '<c r="AD' + currentRow + '" t="inlineStr" s="75"><is><t>FSC Months:</t></is></c>' +
                        '<c r="AE' + currentRow + '" t="n" s="76"><v>0</v></c>' +
                        '<c r="AF' + currentRow + '" s="76"/>' +
                        '<c r="AG' + currentRow + '" t="n" s="77"><f>B' + (currentRow + 10) + '*AE' + (currentRow) + '</f></c>' +
                        '<c r="AH' + currentRow + '" s="5"/>' +
                        '<c r="AI' + currentRow + '" t="inlineStr" s="75"><is><t>FSC Months:</t></is></c>' +
                        '<c r="AJ' + currentRow + '" t="n" s="76"><v>0</v></c>' +
                        '<c r="AK' + currentRow + '" s="76"/>' +
                        '<c r="AL' + currentRow + '" t="n" s="77"><f>B' + (currentRow + 11) + '*AJ' + (currentRow) + '</f></c>' +
                    '</row>'
                );
                mergeCells.push('<mergeCell ref="P' + currentRow + ':Q' + currentRow + '"/>');//FSC 12 Month Table
                mergeCells.push('<mergeCell ref="U' + currentRow + ':V' + currentRow + '"/>');//FSC 24 Month Table
                mergeCells.push('<mergeCell ref="Z' + currentRow + ':AA' + currentRow + '"/>');//FSC 36 Month Table
                mergeCells.push('<mergeCell ref="AE' + currentRow + ':AF' + currentRow + '"/>');//FSC 48 Month Table
                mergeCells.push('<mergeCell ref="AJ' + currentRow + ':AK' + currentRow + '"/>');//FSC 60 Month Table
                currentRow++;
                // MRR Data whole row
                const currency = component.get('v.currency');
                let columnAData = '<c r="A' + currentRow + '" s="5"/>';
                if (currency !== 'USD') {
                    const noteText = 'NOTE: Although it is in ' + currency + ', the $ symbol was used.';
                    columnAData ='<c r="A' + currentRow + '" t="inlineStr" s="7"><is><t>' + noteText + '</t></is></c>';
                }
                rows.push(
                    '<row r="' + currentRow + '">' + 
                        columnAData +
                        '<c r="B' + currentRow + '" s="5"/>' +
                        '<c r="C' + currentRow + '" s="5"/>' +
                        '<c r="D' + currentRow + '" s="5"/>' +
                        '<c r="E' + currentRow + '" s="5"/>' +
                        '<c r="F' + currentRow + '" s="5"/>' +
                        '<c r="G' + currentRow + '" s="5"/>' +
                        '<c r="H' + currentRow + '" s="5"/>' +
                        '<c r="I' + currentRow + '" s="5"/>' +
                        '<c r="J' + currentRow + '" s="5"/>' +
                        '<c r="K' + currentRow + '" s="5"/>' +
                        '<c r="L' + currentRow + '" t="inlineStr" s="66"><is><t>MRR delta</t></is><border style="thin"/></c>' +
                        '<c r="M' + currentRow + '" s="5"/>' +
                        '<c r="N' + currentRow + '" s="5"/>' +
                        '<c r="O' + currentRow + '" t="inlineStr" s="78"><is><t>FSC mo Amortized</t></is><border style="thin"/></c>' +
                        '<c r="P' + currentRow + '" s="78"/>' +
                        '<c r="Q' + currentRow + '" s="79"/>' +
                        '<c r="R' + currentRow + '" t="inlineStr" s="80"><is><t>Adjusted MRR</t></is><border style="thin"/></c>' +
                        '<c r="S' + currentRow + '" s="5"/>' +
                        '<c r="T' + currentRow + '" t="inlineStr" s="78"><is><t>FSC mo Amortized</t></is><border style="thin"/></c>' +
                        '<c r="U' + currentRow + '" s="78"/>' +
                        '<c r="V' + currentRow + '" s="79"/>' +
                        '<c r="W' + currentRow + '" t="inlineStr" s="80"><is><t>Adjusted MRR</t></is><border style="thin"/></c>' +
                        '<c r="X' + currentRow + '" s="5"/>' +
                        '<c r="Y' + currentRow + '" t="inlineStr" s="78"><is><t>FSC mo Amortized</t></is><border style="thin"/></c>' +
                        '<c r="Z' + currentRow + '" s="78"/>' +
                        '<c r="AA' + currentRow + '" s="79"/>' +
                        '<c r="AB' + currentRow + '" t="inlineStr" s="80"><is><t>Adjusted MRR</t></is><border style="thin"/></c>' +
                        '<c r="AC' + currentRow + '" s="5"/>' +
                        '<c r="AD' + currentRow + '" t="inlineStr" s="78"><is><t>FSC mo Amortized</t></is><border style="thin"/></c>' +
                        '<c r="AE' + currentRow + '" s="78"/>' +
                        '<c r="AF' + currentRow + '" s="79"/>' +
                        '<c r="AG' + currentRow + '" t="inlineStr" s="80"><is><t>Adjusted MRR</t></is><border style="thin"/></c>' +
                        '<c r="AH' + currentRow + '" s="5"/>' +
                        '<c r="AI' + currentRow + '" t="inlineStr" s="78"><is><t>FSC mo Amortized</t></is><border style="thin"/></c>' +
                        '<c r="AJ' + currentRow + '" s="78"/>' +
                        '<c r="AK' + currentRow + '" s="79"/>' +
                        '<c r="AL' + currentRow + '" t="inlineStr" s="80"><is><t>Adjusted MRR</t></is><border style="thin"/></c>' +
                        '<c r="AM' + currentRow + '" s="5"/>' +
                    '</row>'
                );
                mergeCells.push('<mergeCell ref="O' + currentRow + ':P' + currentRow + '"/>');//FSC mo Amortized 12 Month Table
                mergeCells.push('<mergeCell ref="T' + currentRow + ':U' + currentRow + '"/>');//FSC mo Amortized 24 Month Table
                mergeCells.push('<mergeCell ref="Y' + currentRow + ':Z' + currentRow + '"/>');//FSC mo Amortized 36 Month Table
                mergeCells.push('<mergeCell ref="AD' + currentRow + ':AE' + currentRow + '"/>');//FSC mo Amortized 48 Month Table
                mergeCells.push('<mergeCell ref="AI' + currentRow + ':AJ' + currentRow + '"/>');//FSC mo Amortized 60 Month Table

                currentRow++;

                rows.push(
                    '<row r="' + currentRow + '">' + 
                        '<c r="L' + currentRow + '" t="n" s="70"><f>H' + subTotalRowNumberCount + '-Q' + subTotalRowNumberCount + '</f></c>' +
                        '<c r="O' + currentRow + '" s="47"/>' +
                        '<c r="R' + currentRow + '" s="48"/>' +
                        '<c r="T' + currentRow + '" s="47"/>' +
                        '<c r="W' + currentRow + '" s="48"/>' +
                        '<c r="Y' + currentRow + '" s="47"/>' +
                        '<c r="AB' + currentRow + '" s="48"/>' +
                        '<c r="AD' + currentRow + '" s="47"/>' +
                        '<c r="AG' + currentRow + '" s="48"/>' +
                        '<c r="AI' + currentRow + '" s="47"/>' +
                        '<c r="AL' + currentRow + '" s="48"/>' +
                    '</row>'
                );

                currentRow ++;
                rows.push(
                    '<row r="' + currentRow + '">' +
                        '<c r="O' + currentRow + '" s="47"/>' +
                        '<c r="R' + currentRow + '" s="48"/>' +
                        '<c r="T' + currentRow + '" s="47"/>' +
                        '<c r="W' + currentRow + '" s="48"/>' +
                        '<c r="Y' + currentRow + '" s="47"/>' +
                        '<c r="AB' + currentRow + '" s="48"/>' +
                        '<c r="AD' + currentRow + '" s="47"/>' +
                        '<c r="AG' + currentRow + '" s="48"/>' +
                        '<c r="AI' + currentRow + '" s="47"/>' +
                        '<c r="AL' + currentRow + '" s="48"/>' +
                    '</row>'
                );

                currentRow ++;
                fscTableLastRowNumberCount = currentRow;
                // FSC Table Last row entries
                rows.push(
                    '<row r="' + currentRow + '">' + 
                        // 12 month
                        '<c r="O' + currentRow + '" t="n" s="81"><f>R' + fscTableFirstRowNumberCount + '/12</f></c>' +
                        '<c r="P' + currentRow + '" t="inlineStr" s="82"><is><t>12 mo</t></is></c>' +
                        '<c r="Q' + currentRow + '" s="82"/>' +
                        '<c r="R' + currentRow + '" t="n" s="83"><f>B' + (currentRow + 3) + '-O' + currentRow + '</f></c>' +
                        '<c r="S' + currentRow + '" s="5"/>' +
                        // 24 month
                        '<c r="T' + currentRow + '" t="n" s="81"><f>W' + fscTableFirstRowNumberCount + '/24</f></c>' +
                        '<c r="U' + currentRow + '" t="inlineStr" s="82"><is><t>24 mo</t></is></c>' +
                        '<c r="V' + currentRow + '" s="82"/>' +
                        '<c r="W' + currentRow + '" t="n" s="83"><f>B' + (currentRow + 4) + '-T' + currentRow + '</f></c>' +
                        '<c r="X' + currentRow + '" s="5"/>' +
                        // 36 month
                        '<c r="Y' + currentRow + '" t="n" s="81"><f>AB' + fscTableFirstRowNumberCount + '/36</f></c>' +
                        '<c r="Z' + currentRow + '" t="inlineStr" s="82"><is><t>36 mo</t></is></c>' +
                        '<c r="AA' + currentRow + '" s="82"/>' +
                        '<c r="AB' + currentRow + '" t="n" s="83"><f>B' + (currentRow + 5) + '-Y' + currentRow + '</f></c>' +
                        '<c r="AC' + currentRow + '" s="5"/>' +
                        // 48 month
                        '<c r="AD' + currentRow + '" t="n" s="81"><f>AG' + fscTableFirstRowNumberCount + '/48</f></c>' +
                        '<c r="AE' + currentRow + '" t="inlineStr" s="82"><is><t>48 mo</t></is></c>' +
                        '<c r="AF' + currentRow + '" s="82"/>' +
                        '<c r="AG' + currentRow + '" t="n" s="83"><f>B' + (currentRow + 6) + '-AD' + currentRow + '</f></c>' +
                        '<c r="AH' + currentRow + '" s="5"/>' +
                        // 60 month
                        '<c r="AI' + currentRow + '" t="n" s="81"><f>AL' + fscTableFirstRowNumberCount + '/60</f></c>' +
                        '<c r="AJ' + currentRow + '" t="inlineStr" s="82"><is><t>60 mo</t></is></c>' +
                        '<c r="AK' + currentRow + '" s="82"/>' +
                        '<c r="AL' + currentRow + '" t="n" s="83"><f>B' + (currentRow + 7) + '-AI' + currentRow + '</f></c>' +
                        '<c r="AM' + currentRow + '" s="5"/>' +
                    '</row>'
                );

                currentRow++;

                rows.push(
                    '<row r="' + currentRow + '">' +
                        '<c r="A' + currentRow + '" s="5"/>' +
                        '<c r="B' + currentRow + '" t="inlineStr" s="67"><is><t>Monthly</t></is></c>' +
                        '<c r="C' + currentRow + '" t="inlineStr" s="68"><is><t>Annual</t></is></c>' +
                        '<c r="D' + currentRow + '" t="inlineStr" s="69"><is><t>Term (Months)</t></is></c>' +
                        '<c r="E' + currentRow + '" t="inlineStr" s="69"><is><t>Monthly Savings</t></is></c>' +
                        '<c r="F' + currentRow + '" t="inlineStr" s="69"><is><t>Annual Savings</t></is></c>' +
                        '<c r="G' + currentRow + '" t="inlineStr" s="69"><is><t>TCV</t></is></c>' +
                        '<c r="H' + currentRow + '" t="inlineStr" s="69"><is><t>Rate with FSC</t></is></c>' +
                        '<c r="I' + currentRow + '" t="inlineStr" s="68"><is><t>Downsell MRR %</t></is></c>' +
                        '<c r="J' + currentRow + '" s="5"/>' +
                        '<c r="K' + currentRow + '" s="5"/>' +
                        '<c r="L' + currentRow + '" s="5"/>' +
                        '<c r="M' + currentRow + '" s="5"/>' +
                        '<c r="N' + currentRow + '" s="5"/>' +
                        '<c r="O' + currentRow + '" t="inlineStr" s="86"><is><t>Monthly &amp; Annual Savings</t></is></c>' +
                        '<c r="P' + currentRow + '" t="n" s="85"><f>$B$' + (currentRow + 1) + '-R' + (currentRow - 1) + '</f></c>' +
                        '<c r="Q' + currentRow + '" s="85"/>' +
                        '<c r="R' + currentRow + '" t="n" s="87"><f>P' + currentRow + '*12</f></c>' +
                        '<c r="S' + currentRow + '" s="5"/>' +
                        '<c r="T' + currentRow + '" t="inlineStr" s="86"><is><t>Monthly &amp; Annual Savings</t></is></c>' +
                        '<c r="U' + currentRow + '" t="n" s="85"><f>$B$' + (currentRow + 1) + '-W' + (currentRow - 1) + '</f></c>' +
                        '<c r="V' + currentRow + '" s="85"/>' +
                        '<c r="W' + currentRow + '" t="n" s="87"><f>U' + currentRow + '*12</f></c>' +
                        '<c r="X' + currentRow + '" s="5"/>' +
                        '<c r="Y' + currentRow + '" t="inlineStr" s="86"><is><t>Monthly &amp; Annual Savings</t></is></c>' +
                        '<c r="Z' + currentRow + '" t="n" s="85"><f>$B$' + (currentRow + 1) + '-AB' + (currentRow - 1) + '</f></c>' +
                        '<c r="AA' + currentRow + '" s="85"/>' +
                        '<c r="AB' + currentRow + '" t="n" s="87"><f>Z' + currentRow + '*12</f></c>' +
                        '<c r="AC' + currentRow + '" s="5"/>' +
                        '<c r="AD' + currentRow + '" t="inlineStr" s="86"><is><t>Monthly &amp; Annual Savings</t></is></c>' +
                        '<c r="AE' + currentRow + '" t="n" s="85"><f>$B$' + (currentRow + 1) + '-AG' + (currentRow - 1) + '</f></c>' +
                        '<c r="AF' + currentRow + '" s="85"/>' +
                        '<c r="AG' + currentRow + '" t="n" s="87"><f>AE' + currentRow + '*12</f></c>' +
                        '<c r="AH' + currentRow + '" s="5"/>' +
                        '<c r="AI' + currentRow + '" t="inlineStr" s="86"><is><t>Monthly &amp; Annual Savings</t></is></c>' +
                        '<c r="AJ' + currentRow + '" t="n" s="85"><f>$B$' + (currentRow + 1) + '-AL' + (currentRow - 1) + '</f></c>' +
                        '<c r="AK' + currentRow + '" s="85"/>' +
                        '<c r="AL' + currentRow + '" t="n" s="87"><f>AJ' + currentRow + '*12</f></c>' +
                        '<c r="AM' + currentRow + '" s="5"/>' +
                    '</row>'
                );

                currentRow++;
                rows.push(
                    '<row r="' + currentRow + '">' +
                        '<c r="A' + currentRow + '" t="inlineStr" s="46"><is><t>Total Spend Today</t></is></c>' +
                        '<c r="B' + currentRow + '" t="n" s="56"><f>C' + currentRow + '/12</f></c>' +
                        '<c r="C' + currentRow + '" t="n" s="65"><f>I' + subTotalRowNumberCount + '</f></c>' +
                        '<c r="D' + currentRow + '" s="35"/>' +
                        '<c r="E' + currentRow + '" s="35"/>' +
                        '<c r="F' + currentRow + '" s="35"/>' +
                        '<c r="G' + currentRow + '" s="35"/>' +
                        '<c r="H' + currentRow + '" s="35"/>' +
                        '<c r="I' + currentRow + '" s="35"/>' +
                    '</row>'
                );

                currentRow++;
                rows.push(
                    '<row r="' + currentRow + '">' +
                        '<c r="A' + currentRow + '" t="inlineStr" s="40"><is><t>12 Month Renewal</t></is></c>' +
                        '<c r="B' + currentRow + '" t="n" s="56"><f>C' + currentRow + '/12</f></c>' +
                        '<c r="C' + currentRow + '" t="n" s="63"><f>R' + subTotalRowNumberCount + '</f></c>' +
                        '<c r="D' + currentRow + '" t="n" s="38"><v>12</v></c>' +
                        '<c r="E' + currentRow + '" t="n" s="63"><f>B$' + (currentRow - 1) + '-B' + currentRow + '</f></c>' +
                        '<c r="F' + currentRow + '" t="n" s="63"><f>C$' + (currentRow - 1) + '-C' + currentRow + '</f></c>' +
                        '<c r="G' + currentRow + '" t="n" s="63"><f>B' + currentRow + '*D' + currentRow + '</f></c>' +
                        '<c r="H' + currentRow + '" t="n" s="63"><f>R' + fscTableLastRowNumberCount + '</f></c>' +
                        '<c r="I' + currentRow + '" t="n" s="64"><f>1-(B' + currentRow + '/$B$' + (currentRow - 1) + ')</f></c>' +

                        // Early renewal savings Tables
                        // 12 month renewal table
                        '<c r="O' + currentRow + '" t="inlineStr" s="88"><is><t>Early renewal savings</t></is></c>' +
                        '<c r="P' + currentRow + '" s="88"/>' +
                        '<c r="Q' + currentRow + '" s="88"/>' +
                        '<c r="R' + currentRow + '" t="inlineStr" s="89"><is><t>Total Downsell</t></is></c>' +
                        '<c r="S' + currentRow + '" s="5"/>' +
                        // 24 month renewal table
                        '<c r="T' + currentRow + '" t="inlineStr" s="88"><is><t>Early renewal savings</t></is></c>' +
                        '<c r="U' + currentRow + '" s="88"/>' +
                        '<c r="V' + currentRow + '" s="88"/>' +
                        '<c r="W' + currentRow + '" t="inlineStr" s="89"><is><t>Total Downsell</t></is></c>' +
                        '<c r="X' + currentRow + '" s="5"/>' +
                        // 36 month renewal table
                        '<c r="Y' + currentRow + '" t="inlineStr" s="88"><is><t>Early renewal savings</t></is></c>' +
                        '<c r="Z' + currentRow + '" s="88"/>' +
                        '<c r="AA' + currentRow + '" s="88"/>' +
                        '<c r="AB' + currentRow + '" t="inlineStr" s="89"><is><t>Total Downsell</t></is></c>' +
                        '<c r="AC' + currentRow + '" s="5"/>' +
                        // 48 month renewal table
                        '<c r="AD' + currentRow + '" t="inlineStr" s="88"><is><t>Early renewal savings</t></is></c>' +
                        '<c r="AE' + currentRow + '" s="88"/>' +
                        '<c r="AF' + currentRow + '" s="88"/>' +
                        '<c r="AG' + currentRow + '" t="inlineStr" s="89"><is><t>Total Downsell</t></is></c>' +
                        '<c r="AH' + currentRow + '" s="5"/>' +
                        // 60 month renewal table
                        '<c r="AI' + currentRow + '" t="inlineStr" s="88"><is><t>Early renewal savings</t></is></c>' +
                        '<c r="AJ' + currentRow + '" s="88"/>' +
                        '<c r="AK' + currentRow + '" s="88"/>' +
                        '<c r="AL' + currentRow + '" t="inlineStr" s="89"><is><t>Total Downsell</t></is></c>' +
                        '<c r="AM' + currentRow + '" s="5"/>' +
                    '</row>'
                );
                mergeCells.push('<mergeCell ref="O' + currentRow + ':Q' + currentRow + '"/>');
                mergeCells.push('<mergeCell ref="T' + currentRow + ':V' + currentRow + '"/>');
                mergeCells.push('<mergeCell ref="Y' + currentRow + ':AA' + currentRow + '"/>');
                mergeCells.push('<mergeCell ref="AD' + currentRow + ':AF' + currentRow + '"/>');
                mergeCells.push('<mergeCell ref="AI' + currentRow + ':AK' + currentRow + '"/>');

                currentRow++;
                rows.push(
                    '<row r="' + currentRow + '">' +
                        '<c r="A' + currentRow + '" t="inlineStr" s="41"><is><t>24 Month Renewal</t></is></c>' +
                        '<c r="B' + currentRow + '" t="n" s="66"><f>C' + currentRow + '/12</f></c>' +
                        '<c r="C' + currentRow + '" t="n" s="66"><f>W' + subTotalRowNumberCount + '</f></c>' +
                        '<c r="D' + currentRow + '" t="n" s="38"><v>24</v></c>' +
                        '<c r="E' + currentRow + '" t="n" s="66"><f>B$' + (currentRow - 2) + '-B' + currentRow + '</f></c>' +
                        '<c r="F' + currentRow + '" t="n" s="66"><f>C$' + (currentRow - 2) + '-C' + currentRow + '</f></c>' +
                        '<c r="G' + currentRow + '" t="n" s="66"><f>B' + currentRow + '*D' + currentRow + '</f></c>' +
                        '<c r="H' + currentRow + '" t="n" s="66"><f>W' + fscTableLastRowNumberCount + '</f></c>' +
                        '<c r="I' + currentRow + '" t="n" s="64"><f>1-(B' + currentRow + '/$B$' + (currentRow - 2) + ')</f></c>' +
                        // 12 month renewal table
                        '<c r="O' + currentRow + '" t="inlineStr" s="90"><is><t>Months</t></is></c>' +
                        '<c r="P' + currentRow + '" s="91"><f>$I$3</f></c>' +
                        '<c r="Q' + currentRow + '" s="91"/>' +
                        '<c r="R' + currentRow + '" t="n" s="92"><f>IF($I$2="Y",($I$3*$H$' + subTotalRowNumberCount + ')-(Q' + subTotalRowNumberCount + '*$I$3),0)</f></c>' +
                        '<c r="S' + currentRow + '" s="5"/>' +
                        // 24 month renewal table
                        '<c r="T' + currentRow + '" t="inlineStr" s="90"><is><t>Months</t></is></c>' +
                        '<c r="U' + currentRow + '" s="91"><f>$I$3</f></c>' +
                        '<c r="V' + currentRow + '" s="91"/>' +
                        '<c r="W' + currentRow + '" t="n" s="92"><f>IF($I$2="Y",($I$3*$H$' + subTotalRowNumberCount + ')-(V' + subTotalRowNumberCount + '*$I$3),0)</f></c>' +
                        '<c r="X' + currentRow + '" s="5"/>' +
                        // 36 month renewal table
                        '<c r="Y' + currentRow + '" t="inlineStr" s="90"><is><t>Months</t></is></c>' +
                        '<c r="Z' + currentRow + '" s="91"><f>$I$3</f></c>' +
                        '<c r="AA' + currentRow + '" s="91"/>' +
                        '<c r="AB' + currentRow + '" t="n" s="92"><f>IF($I$2="Y",($I$3*$H$' + subTotalRowNumberCount + ')-(AA' + subTotalRowNumberCount + '*$I$3),0)</f></c>' +
                        '<c r="AC' + currentRow + '" s="5"/>' +
                        // 48 month renewal table
                        '<c r="AD' + currentRow + '" t="inlineStr" s="90"><is><t>Months</t></is></c>' +
                        '<c r="AE' + currentRow + '" s="91"><f>$I$3</f></c>' +
                        '<c r="AF' + currentRow + '" s="91"/>' +
                        '<c r="AG' + currentRow + '" t="n" s="92"><f>IF($I$2="Y",($I$3*$H$' + subTotalRowNumberCount + ')-(AF' + subTotalRowNumberCount + '*$I$3),0)</f></c>' +
                        // 60 month renewal table
                        '<c r="AI' + currentRow + '" t="inlineStr" s="90"><is><t>Months</t></is></c>' +
                        '<c r="AJ' + currentRow + '" s="91"><f>$I$3</f></c>' +
                        '<c r="AK' + currentRow + '" s="91"/>' +
                        '<c r="AL' + currentRow + '" t="n" s="92"><f>IF($I$2="Y",($I$3*$H$' + subTotalRowNumberCount + ')-(AK' + subTotalRowNumberCount + '*$I$3),0)</f></c>' +
                        '<c r="AM' + currentRow + '" s="5"/>' +
                    '</row>'
                );
                mergeCells.push('<mergeCell ref="P' + currentRow + ':Q' + currentRow + '"/>');
                mergeCells.push('<mergeCell ref="U' + currentRow + ':V' + currentRow + '"/>');
                mergeCells.push('<mergeCell ref="Z' + currentRow + ':AA' + currentRow + '"/>');
                mergeCells.push('<mergeCell ref="AE' + currentRow + ':AF' + currentRow + '"/>');
                mergeCells.push('<mergeCell ref="AJ' + currentRow + ':AK' + currentRow + '"/>');

                currentRow++;
                rows.push(
                    '<row r="' + currentRow + '">' +
                        '<c r="A' + currentRow + '" t="inlineStr" s="42"><is><t>36 Month Renewal</t></is></c>' +
                        '<c r="B' + currentRow + '" t="n" s="66"><f>C' + currentRow + '/12</f></c>' +
                        '<c r="C' + currentRow + '" t="n" s="66"><f>AB' + subTotalRowNumberCount + '</f></c>' +
                        '<c r="D' + currentRow + '" t="n" s="38"><v>36</v></c>' +
                        '<c r="E' + currentRow + '" t="n" s="66"><f>B$' + (currentRow - 3) + '-B' + currentRow + '</f></c>' +
                        '<c r="F' + currentRow + '" t="n" s="66"><f>C$' + (currentRow - 3) + '-C' + currentRow + '</f></c>' +
                        '<c r="G' + currentRow + '" t="n" s="66"><f>B' + currentRow + '*D' + currentRow + '</f></c>' +
                        '<c r="H' + currentRow + '" t="n" s="66"><f>AB' + fscTableLastRowNumberCount + '</f></c>' +
                        '<c r="I' + currentRow + '" t="n" s="64"><f>1-(B' + currentRow + '/$B$' + (currentRow - 3) + ')</f></c>' +
                        // 12 month renewal table
                        '<c r="O' + currentRow + '" t="inlineStr" s="93"><is><t>Monthly Downsell</t></is></c>' +
                        '<c r="P' + currentRow + '" s="93"/>' +
                        '<c r="Q' + currentRow + '" s="94"><f>Q' + subTotalRowNumberCount + '-$H$' + subTotalRowNumberCount + '</f></c>' +
                        '<c r="R' + currentRow + '" s="94"/>' +
                        '<c r="S' + currentRow + '" s="5"/>' +
                        // 24 month renewal table
                        '<c r="T' + currentRow + '" t="inlineStr" s="93"><is><t>Monthly Downsell</t></is></c>' +
                        '<c r="U' + currentRow + '" s="93"/>' +
                        '<c r="V' + currentRow + '" s="94"><f>V' + subTotalRowNumberCount + '-$H$' + subTotalRowNumberCount + '</f></c>' +
                        '<c r="W' + currentRow + '" s="94"/>' +
                        '<c r="X' + currentRow + '" s="5"/>' +
                        // 36 month renewal table
                        '<c r="Y' + currentRow + '" t="inlineStr" s="93"><is><t>Monthly Downsell</t></is></c>' +
                        '<c r="Z' + currentRow + '" s="93"/>' +
                        '<c r="AA' + currentRow + '" s="94"><f>AA' + subTotalRowNumberCount + '-$H$' + subTotalRowNumberCount + '</f></c>' +
                        '<c r="AB' + currentRow + '" s="94"/>' +
                        '<c r="AC' + currentRow + '" s="5"/>' +
                        // 48 month renewal table
                        '<c r="AD' + currentRow + '" t="inlineStr" s="93"><is><t>Monthly Downsell</t></is></c>' +
                        '<c r="AE' + currentRow + '" s="93"/>' +
                        '<c r="AF' + currentRow + '" s="94"><f>AF' + subTotalRowNumberCount + '-$H$' + subTotalRowNumberCount + '</f></c>' +
                        '<c r="AG' + currentRow + '" s="94"/>' +
                        '<c r="AH' + currentRow + '" s="5"/>' +
                        // 60 month renewal table
                        '<c r="AI' + currentRow + '" t="inlineStr" s="93"><is><t>Monthly Downsell</t></is></c>' +
                        '<c r="AJ' + currentRow + '" s="93"/>' +
                        '<c r="AK' + currentRow + '" s="94"><f>AK' + subTotalRowNumberCount + '-$H$' + subTotalRowNumberCount + '</f></c>' +
                        '<c r="AL' + currentRow + '" s="94"/>' +
                        '<c r="AM' + currentRow + '" s="5"/>' +
                    '</row>'
                );

                mergeCells.push('<mergeCell ref="O' + currentRow + ':P' + currentRow + '"/>');
                mergeCells.push('<mergeCell ref="Q' + currentRow + ':R' + currentRow + '"/>');
                mergeCells.push('<mergeCell ref="T' + currentRow + ':U' + currentRow + '"/>');
                mergeCells.push('<mergeCell ref="V' + currentRow + ':W' + currentRow + '"/>');
                mergeCells.push('<mergeCell ref="Y' + currentRow + ':Z' + currentRow + '"/>');
                mergeCells.push('<mergeCell ref="AA' + currentRow + ':AB' + currentRow + '"/>');
                mergeCells.push('<mergeCell ref="AD' + currentRow + ':AE' + currentRow + '"/>');
                mergeCells.push('<mergeCell ref="AF' + currentRow + ':AG' + currentRow + '"/>');
                mergeCells.push('<mergeCell ref="AI' + currentRow + ':AJ' + currentRow + '"/>');
                mergeCells.push('<mergeCell ref="AK' + currentRow + ':AL' + currentRow + '"/>');

                currentRow++;
                rows.push(
                    '<row r="' + currentRow + '">' +
                        '<c r="A' + currentRow + '" t="inlineStr" s="43"><is><t>48 Month Renewal</t></is></c>' +
                        '<c r="B' + currentRow + '" t="n" s="66"><f>C' + currentRow + '/12</f></c>' +
                        '<c r="C' + currentRow + '" t="n" s="66"><f>AG' + subTotalRowNumberCount + '</f></c>' +
                        '<c r="D' + currentRow + '" t="n" s="38"><v>48</v></c>' +
                        '<c r="E' + currentRow + '" t="n" s="66"><f>B$' + (currentRow - 4) + '-B' + currentRow + '</f></c>' +
                        '<c r="F' + currentRow + '" t="n" s="66"><f>C$' + (currentRow - 4) + '-C' + currentRow + '</f></c>' +
                        '<c r="G' + currentRow + '" t="n" s="66"><f>B' + currentRow + '*D' + currentRow + '</f></c>' +
                        '<c r="H' + currentRow + '" t="n" s="66"><f>AG' + fscTableLastRowNumberCount + '</f></c>' +
                        '<c r="I' + currentRow + '" t="n" s="64"><f>1-(B' + currentRow + '/$B$' + (currentRow - 4) + ')</f></c>' +
                        // 12 month renewal table
                        '<c r="O' + currentRow + '" t="inlineStr" s="95"><is><t>Annual Downsell</t></is></c>' +
                        '<c r="P' + currentRow + '" s="95"/>' +
                        '<c r="Q' + currentRow + '" s="96"><f>R' + subTotalRowNumberCount + '-$I$' + subTotalRowNumberCount + '</f></c>' +
                        '<c r="R' + currentRow + '" s="96"/>' +
                        '<c r="S' + currentRow + '" s="5"/>' +
                        // 24 month renewal table
                        '<c r="T' + currentRow + '" t="inlineStr" s="95"><is><t>Annual Downsell</t></is></c>' +
                        '<c r="U' + currentRow + '" s="95"/>' +
                        '<c r="V' + currentRow + '" s="96"><f>W' + subTotalRowNumberCount + '-$I$' + subTotalRowNumberCount + '</f></c>' +
                        '<c r="W' + currentRow + '" s="96"/>' +
                        '<c r="X' + currentRow + '" s="5"/>' +
                        // 36 month renewal table
                        '<c r="Y' + currentRow + '" t="inlineStr" s="95"><is><t>Annual Downsell</t></is></c>' +
                        '<c r="Z' + currentRow + '" s="95"/>' +
                        '<c r="AA' + currentRow + '" s="96"><f>AB' + subTotalRowNumberCount + '-$I$' + subTotalRowNumberCount + '</f></c>' +
                        '<c r="AB' + currentRow + '" s="96"/>' +
                        '<c r="AC' + currentRow + '" s="5"/>' +
                        // 48 month renewal table
                        '<c r="AD' + currentRow + '" t="inlineStr" s="95"><is><t>Annual Downsell</t></is></c>' +
                        '<c r="AE' + currentRow + '" s="95"/>' +
                        '<c r="AF' + currentRow + '" s="96"><f>AG' + subTotalRowNumberCount + '-$I$' + subTotalRowNumberCount + '</f></c>' +
                        '<c r="AG' + currentRow + '" s="96"/>' +
                        '<c r="AH' + currentRow + '" s="5"/>' +
                        // 60 month renewal table
                        '<c r="AI' + currentRow + '" t="inlineStr" s="95"><is><t>Annual Downsell</t></is></c>' +
                        '<c r="AJ' + currentRow + '" s="95"/>' +
                        '<c r="AK' + currentRow + '" s="96"><f>AL' + subTotalRowNumberCount + '-$I$' + subTotalRowNumberCount + '</f></c>' +
                        '<c r="AL' + currentRow + '" s="96"/>' +
                        '<c r="AM' + currentRow + '" s="5"/>' +
                    '</row>'
                );

                mergeCells.push('<mergeCell ref="O' + currentRow + ':P' + currentRow + '"/>');
                mergeCells.push('<mergeCell ref="Q' + currentRow + ':R' + currentRow + '"/>');
                mergeCells.push('<mergeCell ref="T' + currentRow + ':U' + currentRow + '"/>');
                mergeCells.push('<mergeCell ref="V' + currentRow + ':W' + currentRow + '"/>');
                mergeCells.push('<mergeCell ref="Y' + currentRow + ':Z' + currentRow + '"/>');
                mergeCells.push('<mergeCell ref="AA' + currentRow + ':AB' + currentRow + '"/>');
                mergeCells.push('<mergeCell ref="AD' + currentRow + ':AE' + currentRow + '"/>');
                mergeCells.push('<mergeCell ref="AF' + currentRow + ':AG' + currentRow + '"/>');
                mergeCells.push('<mergeCell ref="AI' + currentRow + ':AJ' + currentRow + '"/>');
                mergeCells.push('<mergeCell ref="AK' + currentRow + ':AL' + currentRow + '"/>');

                currentRow++;
                rows.push(
                    '<row r="' + currentRow + '">' +
                        '<c r="A' + currentRow + '" t="inlineStr" s="44"><is><t>60 Month Renewal</t></is></c>' +
                        '<c r="B' + currentRow + '" t="n" s="66"><f>C' + currentRow + '/12</f></c>' +
                        '<c r="C' + currentRow + '" t="n" s="66"><f>AL' + subTotalRowNumberCount + '</f></c>' +
                        '<c r="D' + currentRow + '" t="n" s="38"><v>60</v></c>' +
                        '<c r="E' + currentRow + '" t="n" s="66"><f>B$' + (currentRow - 5) + '-B' + currentRow + '</f></c>' +
                        '<c r="F' + currentRow + '" t="n" s="66"><f>C$' + (currentRow - 5) + '-C' + currentRow + '</f></c>' +
                        '<c r="G' + currentRow + '" t="n" s="66"><f>B' + currentRow + '*D' + currentRow + '</f></c>' +
                        '<c r="H' + currentRow + '" t="n" s="66"><f>AL' + fscTableLastRowNumberCount + '</f></c>' +
                        '<c r="I' + currentRow + '" t="n" s="64"><f>1-(B' + currentRow + '/$B$' + (currentRow - 5) + ')</f></c>' +
                    '</row>'
                );

                currentRow++;
                rows.push(
                    '<row r="' + currentRow + '">' +
                        '<c r="A' + currentRow + '" t="inlineStr" s="54"><is><t>95% of current MRR</t></is></c>' +
                        '<c r="B' + currentRow + '" t="n" s="59"><f>B$' + (currentRow - 6) + '*0.95</f></c>' +
                        '<c r="C' + currentRow + '" t="n" s="61"><f>B' + currentRow + '*12</f></c>' +
                        '<c r="D' + currentRow + '" s="35"/>' +
                        '<c r="E' + currentRow + '" t="n" s="59"><f>B$' + (currentRow - 6) + '-B' + currentRow + '</f></c>' +
                        '<c r="F' + currentRow + '" t="n" s="61"><f>C$' + (currentRow - 6) + '-C' + currentRow + '</f></c>' +
                        '<c r="G' + currentRow + '" s="35"/>' +
                        '<c r="H' + currentRow + '" s="35"/>' +
                        '<c r="I' + currentRow + '" s="35"/>' +
                    '</row>'
                );
                currentRow++;
                rows.push(
                    '<row r="' + currentRow + '">' +
                        '<c r="A' + currentRow + '" t="inlineStr" s="53"><is><t>91% of current MRR</t></is></c>' +
                        '<c r="B' + currentRow + '" t="n" s="60"><f>B$' + (currentRow - 7) + '*0.91</f></c>' +
                        '<c r="C' + currentRow + '" t="n" s="62"><f>B' + currentRow + '*12</f></c>' +
                        '<c r="D' + currentRow + '" s="35"/>' +
                        '<c r="E' + currentRow + '" t="n" s="60"><f>B$' + (currentRow - 7) + '-B' + currentRow + '</f></c>' +
                        '<c r="F' + currentRow + '" t="n" s="62"><f>C$' + (currentRow - 7) + '-C' + currentRow + '</f></c>' +
                        '<c r="G' + currentRow + '" s="35"/>' +
                        '<c r="H' + currentRow + '" s="35"/>' +
                        '<c r="I' + currentRow + '" s="35"/>' +
                    '</row>'
                );
            }
        }  catch (error) {
            console.error('Error in generateDynamicTable:', error);
            return { rows: [], mergeCells: [] };
        }

        return {
            rows: rows.join(''),
            mergeCells: mergeCells
        };
    },

    exportToExcel: function(component) {
        try {
            var helper = this;
            
            // Get data from component attributes
            var account = component.get("v.account");
            var activeSalesAgreement = component.get("v.activeSalesAgreement");
            var entitlements = component.get("v.entitlements");
            
            // Validate data
            if (!account || !entitlements) {
                console.error('Missing required data:', {account: !!account, entitlements: !!entitlements});
                helper.showToast('error', 'Error', 'Missing required data for export');
                return;
            }
            
            if (!window.Blob || !window.URL || !window.atob) {
                helper.showToast('error', 'Error', 'Your browser does not support    file downloads. Please use a modern browser.');
                return;
            }

            // Check for JSZip
            if (typeof JSZip === 'undefined') {
                helper.showToast('error', 'Error', 'JSZip library not loaded');
                return;
            }

            // Initialize JSZip
            var zip = new JSZip();
            
            // Create [Content_Types].xml
            zip.file("[Content_Types].xml", 
                '<?xml version="1.0" encoding="UTF-8"?>' +
                '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">' +
                    '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>' +
                    '<Default Extension="xml" ContentType="application/xml"/>' +
                    '<Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>' +
                    '<Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>' +
                    '<Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>' +
                '</Types>'
            );
            
            // Create _rels/.rels
            zip.folder("_rels").file(".rels",
                '<?xml version="1.0" encoding="UTF-8"?>' +
                '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">' +
                    '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>' +
                '</Relationships>'
            );
            
            // Create xl/_rels/workbook.xml.rels
            zip.folder("xl/_rels").file("workbook.xml.rels",
                '<?xml version="1.0" encoding="UTF-8"?>' +
                '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">' +
                    '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/>' +
                    '<Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>' +
                '</Relationships>'
            );
            
            // Create xl/workbook.xml
            zip.folder("xl").file("workbook.xml",
                '<?xml version="1.0" encoding="UTF-8"?>' +
                '<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">' +
                    '<sheets>' +
                        '<sheet name="Price Sheet" sheetId="1" r:id="rId1"/>' +
                    '</sheets>' +
                '</workbook>'
            );
            
            // Create xl/styles.xml
            zip.folder("xl").file("styles.xml",
                '<?xml version="1.0" encoding="UTF-8"?>' +
                '<styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">' +
                    '<numFmts count="4">' +
                        '<numFmt numFmtId="1" formatCode="#,##0.00"/>' +
                        '<numFmt numFmtId="2" formatCode="#,##0.00_);[Red](#,##0.00)"/>' +
                        '<numFmt numFmtId="3" formatCode="0.00%"/>' +
                        '<numFmt numFmtId="4" formatCode="$#,##0.00"/>' +
                    '</numFmts>' +
                    '<fonts count="3">' +
                        '<font><sz val="11"/><color rgb="FF000000"/><name val="Calibri"/></font>' +
                        '<font><sz val="11"/><color rgb="FF000000"/><name val="Calibri"/><b/></font>' +
                        '<font><sz val="11"/><color rgb="FFffffff"/><name val="Calibri"/><b/></font>' +
                    '</fonts>' +
                    '<fills count="12">' +
                        '<fill><patternFill patternType="none"/></fill>' +
                        '<fill><patternFill patternType="solid"><fgColor rgb="FFDDDDDD"/><bgColor indexed="64"/></patternFill></fill>' +
                        '<fill><patternFill patternType="solid"><fgColor rgb="FF9fdfbf"/><bgColor indexed="64"/></patternFill></fill>' +
                        '<fill><patternFill patternType="solid"><fgColor rgb="FFff9999"/><bgColor indexed="64"/></patternFill></fill>' +
                        '<fill><patternFill patternType="solid"><fgColor rgb="FFffa64d"/><bgColor indexed="64"/></patternFill></fill>' +
                        '<fill><patternFill patternType="solid"><fgColor rgb="FF003366"/><bgColor indexed="64"/></patternFill></fill>' +
                        '<fill><patternFill patternType="solid"><fgColor rgb="FFbfbfbf"/><bgColor indexed="64"/></patternFill></fill>' +
                        '<fill><patternFill patternType="solid"><fgColor rgb="FF66a3ff"/><bgColor indexed="64"/></patternFill></fill>' +
                        '<fill><patternFill patternType="solid"><fgColor rgb="FF40bf40"/><bgColor indexed="64"/></patternFill></fill>' +
                        '<fill><patternFill patternType="solid"><fgColor rgb="FF4ddbff"/><bgColor indexed="64"/></patternFill></fill>' +
                        '<fill><patternFill patternType="solid"><fgColor rgb="FFffb3b3"/><bgColor indexed="64"/></patternFill></fill>' +
                        '<fill><patternFill patternType="solid"><fgColor rgb="FF000000"/><bgColor indexed="64"/></patternFill></fill>' +
                    '</fills>' +
                    '<borders count="28">' +
                        '<border><left/><right/><top/><bottom/><diagonal/></border>' +
                        '<border><left style="medium"/><right style="medium"/><top style="medium"/><bottom style="medium"/></border>' +
                        '<border><left style="medium"/></border>' +
                        '<border><right style="medium"/></border>' +
                        '<border><left style="medium"/><right style="thin"/><top style="medium"/><bottom style="thin"/></border>' + // Thick border top and left
                        '<border><left style="thin"/><right style="thin"/><top style="medium"/><bottom style="medium"/></border>' + // Thick border top and bottom
                        '<border><left style="thin"/><right style="thin"/><top style="medium"/><bottom style="thin"/></border>' + // Thick border only top
                        '<border><left style="thin"/><right style="thin"/><top style="thin"/><bottom style="medium"/></border>' + // Thick border only bottom
                        '<border><left style="thin"/><right style="medium"/><top style="thin"/><bottom style="medium"/></border>' + // Thick border right and bottom
                        '<border><left style="thin"/><right style="medium"/><top style="medium"/><bottom style="thin"/></border>' + // Thick border top and right
                        '<border><left style="thin"/><right style="medium"/><top style="thin"/><bottom style="thin"/></border>' + // Thick border only right
                        '<border><left style="medium"/><right style="thin"/><top style="thin"/><bottom style="thin"/></border>' + // Thick border only left
                        '<border><left style="medium"/><right style="thin"/><top style="thin"/><bottom style="medium"/></border>' + // Thick border left and bottom
                        '<border><left style="thin"/><right style="thin"/><top style="thin"/><bottom style="thin"/></border>' + // All side thin border
                        '<border><left style="medium"/><right style="none"/><top style="medium"/><bottom style="none"/></border>' + // Only top and left border
                        '<border><left style="none"/><right style="medium"/><top style="medium"/><bottom style="none"/></border>' + // Only top and right border
                        '<border><left style="medium"/><right style="none"/><top style="none"/><bottom style="medium"/></border>' + // Only bottom and left border
                        '<border><left style="none"/><right style="medium"/><top style="none"/><bottom style="medium"/></border>' + // Only bottom and right border
                        '<border><left style="none"/><right style="none"/><top style="medium"/><bottom style="none"/></border>' + // Only Top border
                        '<border><left style="none"/><right style="none"/><top style="none"/><bottom style="medium"/></border>' + // Only Botton border
                        '<border><left style="medium"/><right style="none"/><top style="none"/><bottom style="none"/></border>' + // Only Left border
                        '<border><left style="none"/><right style="medium"/><top style="none"/><bottom style="none"/></border>' + // Only Right border
                        '<border><left style="none"/><right style="none"/><top style="none"/><bottom style="none"/></border>' + // No borders
                        '<border><left style="none"/><right style="none"/><top style="medium"/><bottom style="medium"/></border>' + // Only Top Bottom Thick
                        '<border><left style="medium"/><right style="none"/><top style="medium"/><bottom style="medium"/></border>' + // Only Top, Left and Bottom Thick
                        '<border><left style="none"/><right style="medium"/><top style="medium"/><bottom style="medium"/></border>' + // Only Top, Right and Bottom Thick
                        '<border><left style="medium"/><right style="medium"/><top style="medium"/><bottom style="none"/></border>' + // Only Top, left and right Thick
                        '<border><left style="medium"/><right style="medium"/><top style="none"/><bottom style="medium"/></border>' + // Only Top, left and right Thick
                    '</borders>' +
                    '<cellStyleXfs count="1">' +
                        '<xf numFmtId="0" fontId="0" fillId="0" borderId="0"/>' +
                    '</cellStyleXfs>' +
                    '<cellXfs count="98">' +
                        '<xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0"/>' + // Row - 0
                        '<xf numFmtId="40" fontId="1" fillId="1" borderId="0" xfId="0" applyFont="1" applyFill="1"/>' + // Row - 1
                        '<xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0"/>' + // Row - 2
                        '<xf numFmtId="0" fontId="0" fillId="2" borderId="0" xfId="0" applyFill="1"/>' +
                        '<xf numFmtId="0" fontId="0" fillId="3" borderId="1" xfId="0" applyFill="1" applyBorder="1"/>' +
                        '<xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0"/>' +
                        '<xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0" applyNumberFormat="1"/>' +
                        '<xf numFmtId="0" fontId="1" fillId="4" borderId="0" xfId="0" applyFill="1"><alignment horizontal="center"/></xf>' +
                        '<xf numFmtId="2" fontId="2" fillId="5" borderId="0" xfId="0" applyFill="1" applyFont="1" applyNumberFormat="1"><alignment horizontal="center"/></xf>' +
                        '<xf numFmtId="1" fontId="0" fillId="0" borderId="0" xfId="0" applyNumberFormat="1" applyFont="1"/>' +
                        '<xf numFmtId="3" fontId="0" fillId="0" borderId="0" xfId="0" applyNumberFormat="1" applyFont="1"/>' +
                        '<xf numFmtId="1" fontId="1" fillId="0" borderId="0" xfId="0" applyNumberFormat="1" applyFont="1"/>' +
                        '<xf numFmtId="3" fontId="1" fillId="0" borderId="0" xfId="0" applyNumberFormat="1" applyFont="1"/>' +
                        '<xf numFmtId="4" fontId="0" fillId="0" borderId="0" xfId="0" applyNumberFormat="1" applyFont="1"/>' +
                        '<xf numFmtId="4" fontId="1" fillId="0" borderId="0" xfId="0" applyNumberFormat="1" applyFont="1"/>' +
                        '<xf numFmtId="1" fontId="0" fillId="2" borderId="0" xfId="0" applyNumberFormat="1"/>' +
                        '<xf numFmtId="0" fontId="1" fillId="6" borderId="0" xfId="0" applyFill="1"><alignment horizontal="center"/></xf>' +
                        '<xf numFmtId="4" fontId="1" fillId="6" borderId="0" xfId="0" applyNumberFormat="1" applyFont="1"/>' +
                        '<xf numFmtId="0" fontId="1" fillId="7" borderId="0" xfId="0" applyFill="1"><alignment horizontal="center"/></xf>' +
                        '<xf numFmtId="4" fontId="1" fillId="7" borderId="0" xfId="0" applyNumberFormat="1" applyFont="1"/>' +
                        '<xf numFmtId="3" fontId="1" fillId="7" borderId="0" xfId="0" applyNumberFormat="1" applyFont="1"/>' +
                        '<xf numFmtId="4" fontId="1" fillId="4" borderId="0" xfId="0" applyNumberFormat="1" applyFont="1"/>' +
                        '<xf numFmtId="3" fontId="1" fillId="4" borderId="0" xfId="0" applyNumberFormat="1" applyFont="1"/>' +
                        '<xf numFmtId="0" fontId="1" fillId="8" borderId="0" xfId="0" applyFill="1"><alignment horizontal="center"/></xf>' +
                        '<xf numFmtId="4" fontId="1" fillId="8" borderId="0" xfId="0" applyNumberFormat="1" applyFont="1"/>' +
                        '<xf numFmtId="3" fontId="1" fillId="8" borderId="0" xfId="0" applyNumberFormat="1" applyFont="1"/>' +
                        '<xf numFmtId="0" fontId="1" fillId="9" borderId="0" xfId="0" applyFill="1"><alignment horizontal="center"/></xf>' +
                        '<xf numFmtId="4" fontId="1" fillId="9" borderId="0" xfId="0" applyNumberFormat="1" applyFont="1"/>' +
                        '<xf numFmtId="3" fontId="1" fillId="9" borderId="0" xfId="0" applyNumberFormat="1" applyFont="1"/>' +
                        '<xf numFmtId="0" fontId="1" fillId="10" borderId="0" xfId="0" applyFill="1"><alignment horizontal="center"/></xf>' +
                        '<xf numFmtId="4" fontId="1" fillId="10" borderId="0" xfId="0" applyNumberFormat="1" applyFont="1"/>' +
                        '<xf numFmtId="3" fontId="1" fillId="10" borderId="0" xfId="0" applyNumberFormat="1" applyFont="1"/>' +
                        '<xf numFmtId="0" fontId="0" fillId="2" borderId="1" xfId="0" applyFill="1" applyBorder="1"><alignment horizontal="center"/></xf>' +
                        '<xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0" applyFill="1"><alignment horizontal="center"/></xf>' +
                        '<xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0" applyFill="1"><alignment horizontal="right"/></xf>' +
                        '<xf numFmtId="0" fontId="0" fillId="11" borderId="1" xfId="0"/>' +
                        '<xf numFmtId="0" fontId="0" fillId="0" borderId="1" xfId="0" applyBorder="1"><alignment horizontal="center"/></xf>' +
                        '<xf numFmtId="4" fontId="0" fillId="0" borderId="1" xfId="0" applyNumberFormat="1" applyFont="1" applyBorder="1"><alignment horizontal="center"/></xf>' +
                        '<xf numFmtId="1" fontId="0" fillId="0" borderId="13" xfId="0" applyNumberFormat="1" applyBorder="1"/>' +
                        '<xf numFmtId="3" fontId="0" fillId="0" borderId="1" xfId="0" applyNumberFormat="1" applyFont="1" applyBorder="1"/>' +
                        '<xf numFmtId="0" fontId="1" fillId="7" borderId="9" xfId="0" applyFill="1" applyBorder="1"><alignment horizontal="right"/></xf>' +
                        '<xf numFmtId="0" fontId="1" fillId="4" borderId="10" xfId="0" applyFill="1" applyBorder="1"><alignment horizontal="right"/></xf>' +
                        '<xf numFmtId="0" fontId="1" fillId="8" borderId="10" xfId="0" applyFill="1" applyBorder="1"><alignment horizontal="right"/></xf>' +
                        '<xf numFmtId="0" fontId="1" fillId="9" borderId="10" xfId="0" applyFill="1" applyBorder="1"><alignment horizontal="right"/></xf>' +
                        '<xf numFmtId="0" fontId="1" fillId="10" borderId="8" xfId="0" applyFill="1" applyBorder="1"><alignment horizontal="right"/></xf>' +
                        '<xf numFmtId="0" fontId="1" fillId="6" borderId="1" xfId="0" applyFill="1" applyBorder="1"><alignment horizontal="right"/></xf>' +
                        '<xf numFmtId="0" fontId="1" fillId="0" borderId="1" xfId="0" applyBorder="1"><alignment horizontal="right"/></xf>' +
                        '<xf numFmtId="0" fontId="0" fillId="0" borderId="2" xfId="0" applyBorder="1"/>' +
                        '<xf numFmtId="0" fontId="0" fillId="0" borderId="3" xfId="0" applyBorder="1"/>' +
                        '<xf numFmtId="0" fontId="0" fillId="6" borderId="4" xfId="0" applyFill="1" applyBorder="1"><alignment horizontal="right"/></xf>' + // Thick border top and left
                        '<xf numFmtId="0" fontId="0" fillId="6" borderId="5" xfId="0" applyFill="1" applyBorder="1"><alignment horizontal="right"/></xf>' + // Thick border top and bottom
                        '<xf numFmtId="0" fontId="0" fillId="6" borderId="6" xfId="0" applyFill="1" applyBorder="1"><alignment horizontal="right"/></xf>' + // Thick border only top
                        '<xf numFmtId="0" fontId="0" fillId="6" borderId="7" xfId="0" applyFill="1" applyBorder="1"><alignment horizontal="right"/></xf>' + // Thick border only bottom
                        '<xf numFmtId="0" fontId="1" fillId="6" borderId="8" xfId="0" applyFill="1" applyBorder="1"><alignment horizontal="right"/></xf>' + // Thick border right and bottom
                        '<xf numFmtId="0" fontId="1" fillId="6" borderId="9" xfId="0" applyFill="1" applyBorder="1"><alignment horizontal="right"/></xf>' + // Thick border top and right
                        '<xf numFmtId="0" fontId="0" fillId="6" borderId="10" xfId="0" applyFill="1" applyBorder="1"><alignment horizontal="right"/></xf>' + // Thick border only right
                        '<xf numFmtId="4" fontId="0" fillId="0" borderId="4" xfId="0" applyNumberFormat="1" applyFont="1" applyBorder="1"><alignment horizontal="center"/></xf>' +
                        '<xf numFmtId="4" fontId="0" fillId="0" borderId="11" xfId="0" applyNumberFormat="1" applyFont="1" applyBorder="1"><alignment horizontal="center"/></xf>' +
                        '<xf numFmtId="0" fontId="0" fillId="6" borderId="8" xfId="0" applyFill="1" applyBorder="1"><alignment horizontal="right"/></xf>' + // Thick border right and bottom
                        '<xf numFmtId="4" fontId="0" fillId="6" borderId="4" xfId="0" applyNumberFormat="1" applyFont="1" applyBorder="1"><alignment horizontal="center"/></xf>' +
                        '<xf numFmtId="4" fontId="0" fillId="6" borderId="12" xfId="0" applyNumberFormat="1" applyFont="1" applyBorder="1"><alignment horizontal="center"/></xf>' +
                        '<xf numFmtId="4" fontId="0" fillId="6" borderId="9" xfId="0" applyNumberFormat="1" applyFont="1" applyBorder="1"><alignment horizontal="center"/></xf>' +
                        '<xf numFmtId="4" fontId="0" fillId="6" borderId="8" xfId="0" applyNumberFormat="1" applyFont="1" applyBorder="1"><alignment horizontal="center"/></xf>' +
                        '<xf numFmtId="4" fontId="0" fillId="0" borderId="6" xfId="0" applyNumberFormat="1" applyFont="1" applyBorder="1"><alignment horizontal="center"/></xf>' +
                        '<xf numFmtId="3" fontId="0" fillId="0" borderId="10" xfId="0" applyNumberFormat="1" applyFont="1" applyBorder="1"/>' +
                        '<xf numFmtId="4" fontId="0" fillId="0" borderId="9" xfId="0" applyNumberFormat="1" applyFont="1" applyBorder="1"><alignment horizontal="center"/></xf>' +
                        '<xf numFmtId="4" fontId="0" fillId="0" borderId="13" xfId="0" applyNumberFormat="1" applyFont="1" applyBorder="1"><alignment horizontal="center"/></xf>' +
                        '<xf numFmtId="0" fontId="0" fillId="0" borderId="4" xfId="0" applyBorder="1"><alignment horizontal="center"/></xf>' + // Top Left text
                        '<xf numFmtId="0" fontId="0" fillId="0" borderId="9" xfId="0" applyBorder="1"><alignment horizontal="center"/></xf>' + // Top Right text
                        '<xf numFmtId="4" fontId="0" fillId="0" borderId="6" xfId="0" applyNumberFormat="1" applyFont="1" applyBorder="1"><alignment horizontal="center"/></xf>' +  // Only Top text
                        '<xf numFmtId="0" fontId="0" fillId="0" borderId="13" xfId="0" applyNumberFormat="1" applyFont="1" applyBorder="1"><alignment horizontal="center"/></xf>' +
                        '<xf numFmtId="0" fontId="0" fillId="3" borderId="4" xfId="0" applyFill="1" applyBorder="1"/>' +
                        '<xf numFmtId="0" fontId="0" fillId="0" borderId="9" xfId="0" applyBorder="1"><alignment horizontal="center"/></xf>' +
                        '<xf numFmtId="0" fontId="0" fillId="3" borderId="12" xfId="0" applyFill="1" applyBorder="1"/>' +
                        '<xf numFmtId="0" fontId="0" fillId="0" borderId="8" xfId="0" applyBorder="1"><alignment horizontal="center"/></xf>' +
                        '<xf numFmtId="0" fontId="0" fillId="0" borderId="14" xfId="0" applyBorder="1"><alignment horizontal="center"/></xf>' +
                        '<xf numFmtId="0" fontId="0" fillId="2" borderId="18" xfId="0" applyFill="1" applyBorder="1"><alignment horizontal="center"/></xf>' +
                        '<xf numFmtId="4" fontId="0" fillId="0" borderId="15" xfId="0" applyNumberFormat="1" applyFont="1" applyBorder="1"><alignment horizontal="center"/></xf>' +
                        '<xf numFmtId="0" fontId="0" fillId="0" borderId="20" xfId="0" applyBorder="1"><alignment horizontal="center"/></xf>' +
                        '<xf numFmtId="0" fontId="0" fillId="0" borderId="22" xfId="0"/>' +
                        '<xf numFmtId="0" fontId="0" fillId="0" borderId="21" xfId="0" applyBorder="1"><alignment horizontal="center"/></xf>' +
                        '<xf numFmtId="4" fontId="0" fillId="0" borderId="16" xfId="0" applyNumberFormat="1" applyFont="1" applyBorder="1"><alignment horizontal="center"/></xf>' +
                        '<xf numFmtId="0" fontId="0" fillId="0" borderId="22" xfId="0"/><alignment horizontal="center"/>' +
                        '<xf numFmtId="4" fontId="0" fillId="0" borderId="17" xfId="0" applyBorder="1"><alignment horizontal="center"/></xf>' +
                        '<xf numFmtId="0" fontId="0" fillId="11" borderId="16" xfId="0"/>' +
                        '<xf numFmtId="4" fontId="0" fillId="0" borderId="23" xfId="0" applyNumberFormat="1" applyFont="1" applyBorder="1"><alignment horizontal="center"/></xf>' +
                        '<xf numFmtId="4" fontId="0" fillId="0" borderId="24" xfId="0" applyBorder="1"><alignment horizontal="center"/></xf>' +
                        '<xf numFmtId="4" fontId="0" fillId="0" borderId="25" xfId="0" applyNumberFormat="1" applyFont="1" applyBorder="1"><alignment horizontal="center"/></xf>' +
                        '<xf numFmtId="0" fontId="0" fillId="0" borderId="14" xfId="0" applyBorder="1"></xf>' +
                        '<xf numFmtId="0" fontId="0" fillId="0" borderId="26" xfId="0" applyBorder="1"><alignment horizontal="center"/></xf>' +
                        '<xf numFmtId="0" fontId="0" fillId="0" borderId="16" xfId="0" applyBorder="1"><alignment horizontal="center"/></xf>' +
                        '<xf numFmtId="0" fontId="1" fillId="10" borderId="19" xfId="0" applyFill="1"><alignment horizontal="center"/></xf>' +
                        '<xf numFmtId="4" fontId="0" fillId="0" borderId="27" xfId="0" applyNumberFormat="1" applyFont="1" applyBorder="1"><alignment horizontal="center"/></xf>' +
                        '<xf numFmtId="0" fontId="0" fillId="0" borderId="20" xfId="0" applyBorder="1"><alignment horizontal="right"/></xf>' +
                        '<xf numFmtId="4" fontId="0" fillId="0" borderId="21" xfId="0" applyNumberFormat="1" applyFont="1" applyBorder="1"><alignment horizontal="left"/></xf>' +
                        '<xf numFmtId="4" fontId="0" fillId="0" borderId="16" xfId="0" applyBorder="1"><alignment horizontal="right"/></xf>' +
                        '<xf numFmtId="4" fontId="0" fillId="0" borderId="17" xfId="0" applyNumberFormat="1" applyFont="1" applyBorder="1"><alignment horizontal="left"/></xf>' +
                        '<xf numFmtId="0" fontId="0" fillId="2" borderId="22" xfId="0" applyFill="1"/>' +
                    '</cellXfs>' +
                '</styleSheet>'
            );
            
            // Build worksheet data
            var rows = [];
            
            // Add header rows (1-4)
            rows.push(
                '<row r="1">' +
                    '<c r="A1" t="inlineStr" s="5"><is><t>Customer Name:</t></is></c>' +
                    '<c r="B1" t="inlineStr" s="3"><is><t>' + helper.escapeXml(account.Name || '') + '</t></is></c>' +
                    '<c r="C1" s="3"/><c r="D1" s="3"/><c r="E1" s="3"/>' +
                '</row>'
            );
            const contractStartDate = account.Sales_Agreement_Start_Date__c ? 
                (() => {
                    const parts = account.Sales_Agreement_Start_Date__c.split('-');
                    console.log('Contract Start Date parts:', parts);
                    return parts.length === 3 ? `${parts[1]}/${parts[2]}/${parts[0]}` : activeSalesAgreement.Contract_Start_Date__c;
                })() : '';
            const contractEndDate = account.Sales_Agreement_End_Date__c ? 
                (() => {
                    const parts = account.Sales_Agreement_End_Date__c.split('-');
                    console.log('Contract End Date parts:', parts);
                    return parts.length === 3 ? `${parts[1]}/${parts[2]}/${parts[0]}` : activeSalesAgreement.Contract_End_Date__c;
                })() : '';

            var autoRenewalValue = activeSalesAgreement.Auto_Renewal__c === true ? 'YES' : 'NO';
            rows.push(
                '<row r="2">' +
                    '<c r="A2" t="inlineStr" s="5"><is><t>Contract Start Date:</t></is></c>' +
                    '<c r="B2" t="inlineStr" s="3"><is><t>' + (contractStartDate) + '</t></is></c>' +
                    '<c r="C2" s="3"/>' +
                    '<c r="D2" t="inlineStr" s="5"><is><t>Auto-Renewal:</t></is></c>' +
                    '<c r="E2" s="3"/>' +
                    '<c r="F2" t="inlineStr" s="3"><is><t>' + autoRenewalValue + '</t></is></c>' +
                    '<c r="G2" t="inlineStr" s="71"><is><t>Early Renewal?</t></is></c>' +
                    '<c r="H2" s="71"/>' +
                    '<c r="I2" t="inlineStr" s="72"><is><t>Y/N</t></is></c>' +
                '</row>'
            );
            
            rows.push(
                '<row r="3">' +
                    '<c r="A3" t="inlineStr" s="5"><is><t>Contract End Date:</t></is></c>' +
                    '<c r="B3" t="inlineStr" s="3"><is><t>' + (contractEndDate) + '</t></is></c>' +
                    '<c r="C3" s="3"/>' +
                    '<c r="D3" t="inlineStr" s="5"><is><t>Initial Term:</t></is></c>' +
                    '<c r="E3" s="3"/>' +
                    '<c r="F3" s="15"><v>' + (account.Term_months__c || 0) + '</v></c>' +
                    '<c r="G3" t="inlineStr" s="73"><is><t>Number of Months:</t></is></c>' +
                    '<c r="H3" s="73"/>' +
                    '<c r="I3" s="74"/>' +
                '</row>'
            );
            
            rows.push(
                '<row r="4">' +
                    '<c r="A4" t="inlineStr" s="5"><is><t>Payment Plan:</t></is></c>' +
                    '<c r="B4" t="inlineStr" s="3"><is><t>' + (activeSalesAgreement.Payment_Plan__c || '') + '</t></is></c>' +
                    '<c r="C4" s="3"/>' +
                    '<c r="D4" t="inlineStr" s="5"><is><t>Renewal Term:</t></is></c>' +
                    '<c r="E4" s="3"/>' +
                    '<c r="F4" s="15"><v>' + (activeSalesAgreement.Term_months__c || 0) + '</v></c>' +
                '</row>'
            );

            // Add Billable Services header
            rows.push(
                '<row r="5">' +
                    '<c r="A5" s="5"/>' +
                    '<c r="B5" t="inlineStr" s="7"><is><t>Billable Services - CURRENT</t></is><alignment horizontal="center"/></c>' +
                    '<c r="C5" s="3"/>' +
                    '<c r="D5" s="3"/>' +
                    '<c r="E5" s="3"/>' +
                    '<c r="F5" s="3"/>' +
                    '<c r="G5" s="3"/>' +
                    '<c r="H5" s="3"/>' +
                    '<c r="I5" s="3"/>' +
                    '<c r="J5" t="inlineStr" s="16"><is><t>Billable Services - PROPOSAL</t></is><alignment horizontal="center"/></c>' +
                    '<c r="K5" s="3"/>' +
                    '<c r="L5" s="3"/>' +
                    '<c r="M5" s="3"/>' +
                    '<c r="N5" s="16"/>' +
                    '<c r="O5" t="inlineStr" s="18"><is><t>12 Month Renewal</t></is><alignment horizontal="center"/></c>' +
                    '<c r="P5" s="3"/>' +
                    '<c r="Q5" s="3"/>' +
                    '<c r="R5" s="3"/>' +
                    '<c r="S5" s="16"/>' +
                    '<c r="T5" t="inlineStr" s="7"><is><t>24 Month Renewal</t></is><alignment horizontal="center"/></c>' +
                    '<c r="U5" s="7"/>' +
                    '<c r="V5" s="7"/>' +
                    '<c r="W5" s="7"/>' +
                    '<c r="X5" s="16"/>' +
                    '<c r="Y5" t="inlineStr" s="23"><is><t>36 Month Renewal</t></is><alignment horizontal="center"/></c>' +
                    '<c r="Z5" s="7"/>' +
                    '<c r="AA5" s="7"/>' +
                    '<c r="AB5" s="7"/>' +
                    '<c r="AC5" s="16"/>' +
                    '<c r="AD5" t="inlineStr" s="26"><is><t>48 Month Renewal</t></is><alignment horizontal="center"/></c>' +
                    '<c r="AE" s="7"/>' +
                    '<c r="AF5" s="7"/>' +
                    '<c r="AG5" s="7"/>' +
                    '<c r="AH5" s="16"/>' +
                    '<c r="AI5" t="inlineStr" s="29"><is><t>60 Month Renewal</t></is><alignment horizontal="center"/></c>' +
                    '<c r="AJ" s="7"/>' +
                    '<c r="AK5" s="7"/>' +
                    '<c r="AL5" s="7"/>' +
                    '<c r="AM5" s="16"/>' +
                '</row>'
            );
    
            rows.push(
                '<row r="6">' +
                    '<c r="A6" s="0"/>' +
                    '<c r="B6" t="inlineStr" s="7"><is><t>QTY</t></is></c>' +
                    '<c r="C6" t="inlineStr" s="7"><is><t>List Price Monthly</t></is></c>' +
                    '<c r="D6" t="inlineStr" s="7"><is><t>Current Price</t></is></c>' +
                    '<c r="E6" t="inlineStr" s="7"><is><t>Current Annual Price</t></is></c>' +
                    '<c r="F6" t="inlineStr" s="7"><is><t>List Price Subtotal</t></is></c>' +
                    '<c r="G6" t="inlineStr" s="7"><is><t>Effective Discount</t></is></c>' +
                    '<c r="H6" t="inlineStr" s="7"><is><t>Monthly Subtotal</t></is></c>' +
                    '<c r="I6" t="inlineStr" s="7"><is><t>Annual Subtotal</t></is></c>' +
                    '<c r="J6" t="inlineStr" s="16"><is><t>D</t></is></c>' +
                    '<c r="K6" t="inlineStr" s="16"><is><t>New QTY</t></is></c>' +
                    '<c r="L6" t="inlineStr" s="16"><is><t>List Price Monthly</t></is></c>' +
                    '<c r="M6" t="inlineStr" s="16"><is><t>List Price Subtotal</t></is></c>' +
                    '<c r="N6" s="16"/>' +
                    '<c r="O6" t="inlineStr" s="18"><is><t>Price</t></is></c>' +
                    '<c r="P6" t="inlineStr" s="18"><is><t>Effective Discount</t></is></c>' +
                    '<c r="Q6" t="inlineStr" s="18"><is><t>Monthly Subtotal</t></is></c>' +
                    '<c r="R6" t="inlineStr" s="18"><is><t>Annual Subtotal</t></is></c>' +
                    '<c r="S6" s="16"/>' +
                    '<c r="T6" t="inlineStr" s="7"><is><t>Price</t></is></c>' +
                    '<c r="U6" t="inlineStr" s="7"><is><t>Effective Discount</t></is></c>' +
                    '<c r="V6" t="inlineStr" s="7"><is><t>Monthly Subtotal</t></is></c>' +
                    '<c r="W6" t="inlineStr" s="7"><is><t>Annual Subtotal</t></is></c>' +
                    '<c r="X6" s="16"/>' +
                    '<c r="Y6" t="inlineStr" s="23"><is><t>Price</t></is></c>' +
                    '<c r="Z6" t="inlineStr" s="23"><is><t>Effective Discount</t></is></c>' +
                    '<c r="AA6" t="inlineStr" s="23"><is><t>Monthly Subtotal</t></is></c>' +
                    '<c r="AB6" t="inlineStr" s="23"><is><t>Annual Subtotal</t></is></c>' +
                    '<c r="AC6" s="16"/>' +
                    '<c r="AD6" t="inlineStr" s="26"><is><t>Price</t></is></c>' +
                    '<c r="AE6" t="inlineStr" s="26"><is><t>Effective Discount</t></is></c>' +
                    '<c r="AF6" t="inlineStr" s="26"><is><t>Monthly Subtotal</t></is></c>' +
                    '<c r="AG6" t="inlineStr" s="26"><is><t>Annual Subtotal</t></is></c>' +
                    '<c r="AH6" s="16"/>' +
                    '<c r="AI6" t="inlineStr" s="29"><is><t>Price</t></is></c>' +
                    '<c r="AJ6" t="inlineStr" s="29"><is><t>Effective Discount</t></is></c>' +
                    '<c r="AK6" t="inlineStr" s="29"><is><t>Monthly Subtotal</t></is></c>' +
                    '<c r="AL6" t="inlineStr" s="29"><is><t>Annual Subtotal</t></is></c>' +
                    '<c r="AM6" s="16"/>' +
                '</row>'
            );

            // Get dynamic table content
            var dynamicContent = helper.generateDynamicTable(component, entitlements);
            rows.push(dynamicContent.rows);

            // Create worksheet XML with merged cells
            var sheetXml = '<?xml version="1.0" encoding="UTF-8"?>' +
                '<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">' +
                    '<cols>' +
                        '<col min="1" max="1" width="42" customWidth="1"/>' +
                        '<col min="2" max="9" width="15" customWidth="1"/>' +
                        '<col min="10" max="13" width="15" customWidth="1"/>' +
                        '<col min="14" max="14" width="1" customWidth="1"/>' +
                        '<col min="19" max="19" width="1" customWidth="1"/>' +
                        '<col min="24" max="24" width="1" customWidth="1"/>' +
                        '<col min="29" max="29" width="1" customWidth="1"/>' +
                        '<col min="34" max="34" width="1" customWidth="1"/>' +
                        '<col min="39" max="39" width="1" customWidth="1"/>' +
                    '</cols>' +
                    '<sheetData>' + rows.join('') + '</sheetData>' +
                    '<mergeCells count="' + (7 + dynamicContent.mergeCells.length) + '">' +
                        '<mergeCell ref="B1:E1"/>' +
                        '<mergeCell ref="D2:E2"/>' +
                        '<mergeCell ref="G2:H2"/>' +
                        '<mergeCell ref="D3:E3"/>' +
                        '<mergeCell ref="G3:H3"/>' +
                        '<mergeCell ref="D4:E4"/>' +
                        '<mergeCell ref="B5:I5"/>' +
                        '<mergeCell ref="J5:M5"/>' +
                        '<mergeCell ref="O5:R5"/>' +
                        '<mergeCell ref="T5:W5"/>' +
                        '<mergeCell ref="Y5:AB5"/>' +
                        '<mergeCell ref="AD5:AG5"/>' +
                        '<mergeCell ref="AI5:AL5"/>' +
                        dynamicContent.mergeCells.join('') +
                    '</mergeCells>' +
                '</worksheet>';

            // Add worksheet to zip
            zip.folder("xl/worksheets").file("sheet1.xml", sheetXml);
            
            // Generate Excel file as base64
            zip.generateAsync({type:"base64"})
                .then(function(base64Content) {
                    try {
                        // Get filename from component or use default
                        var fileName = component.get('v.fileName') || 'Renewal price sheet.xlsx';
                        var dataUrl = 'data:application/vnd.openxmlformats-officedocument.spreadsheetml.sheet;base64,' + base64Content;
                        var tempLink = document.createElement('a');
                        tempLink.href = dataUrl;
                        tempLink.download = "Renewal_price_sheet.xlsx";
                        tempLink.style.display = 'none';
                        
                        document.body.appendChild(tempLink);
                        tempLink.click();
                        document.body.removeChild(tempLink);
                    } catch (error) {
                        console.error('Error in download process:', error);
                        // Show error to user
                        helper.showToast('error', 'Error', 'Failed to generate Excel file. Please try again.');
                    }
                })
                .catch(function(error) {
                    console.error('Error generating Excel file:', error);
                    // Show error to user
                    helper.showToast('error', 'Error', 'Failed to generate Excel file. Please try again.');
                });
                
        } catch (error) {
            console.error('Error in exportToExcel:', error);
            helper.showToast('error', 'Error', 'Failed to generate Excel file. Please try again.');
        }
    }
});