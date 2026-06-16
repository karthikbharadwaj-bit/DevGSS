/* globals console, QW */
({
    getCartItems: function(component, all) {
        var result = [];
        var list = component.get('v.currentCartItems');
        var _list = [];

        list.forEach(function(listItem) {
            _list = _list.concat(listItem.items);
        });

        if(all) return _list;

        _list.forEach(function(item) {
            !item.DisplayOnly && result.push(item);
        });

        return result;
    },

    updateCurrentItems: function(component, currentItems, newItems) {
        // delete
        for (var k = currentItems.length-1; k >= 0; k--) {

            // Check on existing group;
            if(!newItems[k]) {
                currentItems.splice(k,1);
                continue;
            }

            // Check on group;
            if(newItems[k].name !== currentItems[k].name) {
                currentItems.splice(k,1);
                continue;
            }

            // Check by item in group;
            if(newItems[k].name === currentItems[k].name) {
                var _newItems = newItems[k] && newItems[k].items;
                var _currentItems = currentItems[k] && currentItems[k].items;

                for (var i = _currentItems.length-1; i >= 0; i--) {
                    var currentId = _currentItems[i] && (_currentItems[i].Id || _currentItems[i].Product2.Id);
                    var foundItem = _.find(_newItems, function(_newItem) { return currentId === (_newItem.Id || _newItem.Product2.Id) });

                    if(!foundItem) _currentItems.splice(i, 1);
                }
            }
        }

        // upsert
        for (var k = 0; k <= newItems.length-1; k++) {

            // Check on existing group;
            if(!currentItems[k]) {
                currentItems[k] = newItems[k];
                continue;
            }

            // Check on group;
            if(currentItems[k].name !== newItems[k].name) {
                currentItems[k] = newItems[k];
                continue;
            }

            // Check by item in group;
            if(currentItems[k].name === newItems[k].name) {
                var _newItems = newItems[k] && newItems[k].items;
                var _currentItems = currentItems[k] && currentItems[k].items;

                for (var i = 0; i <= _newItems.length-1; i++) {

                    var currentId = _currentItems[i] && _currentItems[i].Id;
                    var newId = _newItems[i] && _newItems[i].Id;

                    if(!currentId && !newId) {
                        var currentId = _currentItems[i] && _currentItems[i].Product2.Id;
                        var newId = _newItems[i] && _newItems[i].Product2.Id;
                    }

                    // add
                    if(currentId !== newId) {
                        _currentItems.splice(i, 0, _newItems[i]);
                    }

                    // update
                    if( currentId === newId && !this.isEqual(_newItems[i], _currentItems[i]) ) {
                        _currentItems[i] = _newItems[i];
                    }
                }
            }

        }

        return currentItems;
    },

    updateUserCartItems: function(component) {
        // console.groupCollapsed('updateUserCartItems()');
        var quoteRecordTypeName = component.get('v.quoteRecordTypeName');
        var helper = this;
        var settings = component.get('v.settings');
        var items = component.get('v.cartItems');

        var unmatchedCartItems = component.get('v.unmatchedCartItems')
            .filter(i => i.Product2
                        && i.Product2.Cart_Tab_Availability__c
                        && i.Product2.Cart_Tab_Availability__c.includes(quoteRecordTypeName)
            );
        var unmatchedOneTimeItems = unmatchedCartItems
            .filter(i => i.Product2.Charge_Term__c === QW.CONSTANTS.PRODUCT2.CHARGE_TERM.ONE_TIME);
        items = items.concat(unmatchedCartItems
            .filter(i => i.Product2.Charge_Term__c !== QW.CONSTANTS.PRODUCT2.CHARGE_TERM.ONE_TIME));

        // Keep show Details checkbox in the same state after update
        var oldItems = this.getCartItems(component);
        items = items.map(function(item){
            for (var i = oldItems.length-1; i >= 0; i--) {
                if (oldItems[i].Id === item.Id){
                    item.isShowDetails = oldItems[i].isShowDetails;
                }
            }
            return item;
        });

        var groupingList = [];
        // Create grouping list based on custom settings;
        if(settings.cartItemsGrouping) {
            for(var key in settings.cartItemsGrouping) {
                if(settings.cartItemsGrouping.hasOwnProperty(key)) {

                    if(settings.cartItemsGrouping[key].Allow_Grouping__c) {
                        groupingList.push({
                            field: settings.cartItemsGrouping[key].FieldName__c,
                            value: settings.cartItemsGrouping[key].FieldValue__c,
                            label: settings.cartItemsGrouping[key].Group_Label__c,
                            expanded: settings.cartItemsGrouping[key].Expanded__c,
                        });
                    }

                }
            }
        }

        // Temp solutions;
        var options = {
            params: component.get('v.params'),
            Ent: component.get('v.Ent'),
            columns: component.get('v.columns')
        };
        // Grouping & Sorting
        var newUnmatchedOneTimeItems = helper.groupUnmatchedCartItems(component, unmatchedOneTimeItems, groupingList, options);
        var newCartItems = helper.groupCartItems(component, items, groupingList, options);

        // Unmatched always in the end
        [newUnmatchedOneTimeItems, newCartItems].forEach(function (group) {
            group.forEach(function (groupItem) {
                groupItem.items = helper.sortProducts(groupItem.items);
            });
        });

        // Groups sorted by label
        newCartItems = _.sortBy(newCartItems, 'label');

        var currentCartItems = component.get('v.currentCartItems');
        newCartItems = helper.updateCurrentItems(component, currentCartItems, newCartItems);

        component.set('v.currentCartItems', newUnmatchedOneTimeItems.concat(newCartItems));

        console.groupEnd('updateUserCartItems()');
    },

    isEqual: function(obj1, obj2) {
        var _obj1 = _.clone(obj1);
        var _obj2 = _.clone(obj2);
        var customFields = ['Unmatched', 'DisplayOnly', 'sobjectType', 'isShowDetails', 'isChanged', 'hasErrors'];

        customFields.map(function(key) {
            delete _obj1[key];
            delete _obj2[key];
        });


        return _.isEqual(_obj1, _obj2);
    },

    searchQliInCart: function(component, predicate) {
        const items = component.get('v.currentCartItems');

        return items
            .reduce((acc, cur) => acc.concat(cur.items), [])
            .filter(predicate);
    },

    searchPricebookEntries: function(component, predicate) {
        const products = component.get('v.products');

        return products.filter(predicate);
    },

    createQliFromOneTimeEntitlements: function(component) {
        const qlisToCreateByProduct2Ids = this
            .searchQliInCart(component, (x) => {
                return x.Unmatched
                    && x.Quantity > 0
                    && x.Product2.Charge_Term__c === QW.CONSTANTS.PRODUCT2.CHARGE_TERM.ONE_TIME
            })
            .reduce((acc, cur) => {
                const product2Id = cur.Product2.Id;

                acc[product2Id] = cur;

                return acc;
            }, {});

        if(Object.keys(qlisToCreateByProduct2Ids).length === 0) return Promise.resolve();

        const pricebookEntries = this
            .searchPricebookEntries(component, (x) => {
                return qlisToCreateByProduct2Ids[x.Product2Id]
            });
        const quantityByPricebookEntryId = pricebookEntries
            .reduce((acc, cur) => {
                const pricebookEntryId = cur.Id;
                const product2Id = cur.Product2Id;

                if(qlisToCreateByProduct2Ids[product2Id]) {
                    acc[pricebookEntryId] = qlisToCreateByProduct2Ids[product2Id].Quantity;
                }

                return acc;
            }, {});

        QW.spinner.show('creating quote line items from entitlements');
        return this.createQuoteLineItems(component, pricebookEntries, quantityByPricebookEntryId)
            .then($A.getCallback(() => {
                    const Wizard = component.get("v.Wizard");
                    if(Wizard.currentQuote && Wizard.currentQuote.isTaxesInCart) {
                        QW.spinner.show('Removing taxes');
                        QW.salesforce.request(component, 'c.removeTaxes', { quoteId: component.get('v.quote.Id') });
                    }
                }
            ))
            .then($A.getCallback(() => this.refreshCart(component)));
    },

    deleteOneTimePhoneQli: function(component) {
        const qlisToDelete = this.searchQliInCart(component, (x) => {
            return !x.Unmatched
                && x.Quantity === 0
                && x.Product2.Charge_Term__c === QW.CONSTANTS.PRODUCT2.CHARGE_TERM.ONE_TIME;
        });

        QW.spinner.show('deleting quote line items');
        if(qlisToDelete.length === 0) return Promise.resolve();

        let promises = [];
        for(let i = 0; i < qlisToDelete.length; i++) {
            const qli = qlisToDelete[i];

            promises.push(this.removeQli(component, qli));
        }

        return Promise.all(promises)
    },

    checkQuantityApprovedRange: function(component) {
        const currentQuote = component.get("v.Wizard.currentQuote");

        if(currentQuote.record.Approved_Status__c !== "Approved" &&
            currentQuote.record.Approved_Status__c !== "Not Required") {
            return Promise.resolve();
        }

        const items = this.getCartItems(component);

        // quantity can be stored in AreaCodeLineItems
        const qliIdToAreaCodesListMap = this.buildQliIdToAreaCodesListMap(component);

        const changedItems = items.filter((item) => {
                if(currentQuote.isAreaCodesAllowed
                    && qliIdToAreaCodesListMap && qliIdToAreaCodesListMap[item.Id]) {
                    return (qliIdToAreaCodesListMap && qliIdToAreaCodesListMap[item.Id]);
                }else{
                    return item.isChanged;
                }
            })
            .map((item) => {
                var itemQuantity = item.Quantity;
                // get quantity from AreaCodeLineItem if it exist
                if(currentQuote.isAreaCodesAllowed
                    && qliIdToAreaCodesListMap && qliIdToAreaCodesListMap[item.Id]) {
                    var computedQuantity = qliIdToAreaCodesListMap[item.Id].reduce((acc, el) => {
                        return acc + Number(el.Quantity__c);
                    }, 0);
                    itemQuantity = computedQuantity;
                }

                var itemPercentageDiscount = 0;
                if(item.Discount_type__c === 'Currency') {
                    itemPercentageDiscount = Math.abs((((item.UnitPrice - item.Discount_number__c) - item.UnitPrice) / item.UnitPrice) * 100);
                }else{
                    itemPercentageDiscount = item.Discount_number__c;
                }

                // i do not know _WHY_ but all discount without dependencies which discountType is - stored in Discount_number__c field
                return {
                    Id: item.Id,
                    QuoteId: item.QuoteId,
                    Quote: item.Quote,
                    Quantity: itemQuantity,
                    NewQuantity__c: item.NewQuantity__c,
                    Approved_Quantity__c: item.Approved_Quantity__c,
                    Approved_Discount__c: item.Approved_Discount__c,
                    Approved_Discount_Type__c: item.Approved_Discount_Type__c,
                    Discount: itemPercentageDiscount,
                    Discount_Value__c: item.Discount_number__c,
                    Discount_type__c: item.Discount_type__c,
                    Entitlement__c: item.Entitlement__c,
                    Entitlement__r: item.Entitlement__r,
                    Asset__c: item.Asset__c,
                    Asset__r: item.Asset__r,
                    Product2: item.Product2
                };
            })
            .reduce((acc, item) => {
                var tmp = JSON.parse(JSON.stringify(acc));
                tmp[item.Id] = item;
                return tmp;
            }, {});

        if(!changedItems) {
            return Promise.resolve();
        }

        QW.spinner.show('validate quantity change');

        const helper = this;

        return RC.salesforce.request(component, 'c.checkNeedForApproval', { changedItems: changedItems })
            .then($A.getCallback(quantityChangeMessages => {
                QW.spinner.hide();

                const showReApprovalNotification = (currentQuote.record.Approved_Status__c === "Approved" ||
                    currentQuote.record.Approved_Status__c === "Not Required") &&
                    quantityChangeMessages.length > 0;

                if (showReApprovalNotification) {
                    const isMultipleChanges = quantityChangeMessages.length > 1;
                    const quantityChangeMessageTableArr = quantityChangeMessages.map(m => [
                        m.productName,
                        m.quantity,
                        m.approvedQuantityRange,
                        m.additionalMessage
                    ]);

                    const header = `${ isMultipleChanges ? 'These changes' : 'This change' } will require new Approval or will update Approvers List`;

                    const table = RC.htmlUtils.createTable({
                        header: {
                            content: ['Product Name', 'New Quantity', 'Approved Quantity Range', 'Reason'],
                            class: 'slds-text-title_caps'
                        },
                        body: quantityChangeMessageTableArr,
                        class: 'slds-table slds-table_bordered slds-no-row-hover slds-m-bottom_small',
                    }).outerHTML;

                    const confirmationMsg = `
                            <div class="slds-text-align_center">
                                Do you want to save ${ isMultipleChanges ? 'these changes' : 'this change'}?
                            </div>
                    `;

                    return new Promise($A.getCallback(resolve => {
                        $A.get("e.c:ModalRequestEvent").setParams({
                            header: header,
                            content: table + confirmationMsg,
                            layout: 'large',
                            buttons: [{
                                label: 'Save changes anyway',
                                variant: 'brand',
                                callback: () => {
                                    resolve();
                                }
                            }]
                        }).fire();
                    }));
                }
            }))
            .catch($A.getCallback(function (error) {
                RC.salesforce.displayError('Failed to validate changes', error);
                return Promise.reject();
            }));
    },
    buildQliIdToAreaCodesListMap: function(component) {
        var currentQuote = component.get('v.Wizard.currentQuote');
        var areaCodesToSave = this.getUnsavedAreaCodes(component);

        var qliIdToAreaCodesListMap = {};
        if(currentQuote.isAreaCodesAllowed && areaCodesToSave && areaCodesToSave.length > 0) {
            var changedAreaCodesMap = areaCodesToSave.reduce((acc, item) => {
                var tmp = _.clone(acc);
                tmp[item.guid] = _.clone(item);
                return tmp;
            }, {});

            var areaCodeItems = component.get("v.areaCodeItems");
            var existingAreaCodesMap = areaCodeItems.reduce((acc, item) => {
                var tmp = _.clone(acc);
                tmp[item.guid] = _.clone(item);
                return tmp;
            }, {});

            var mergedAreaCodesMap = _.uniq(_.flatten([
                _.keys(changedAreaCodesMap),
                _.keys(existingAreaCodesMap)])
            ).map((itemGuid) => {
                if(changedAreaCodesMap[itemGuid]) {
                    return JSON.parse(JSON.stringify(changedAreaCodesMap[itemGuid]));
                }else{
                    return JSON.parse(JSON.stringify(existingAreaCodesMap[itemGuid]));
                }
            });

            qliIdToAreaCodesListMap = mergedAreaCodesMap.reduce((acc, item) => {
                var tmp = JSON.parse(JSON.stringify(acc));
                if (!tmp[item.Quote_Line_Item__c]) {
                    tmp[item.Quote_Line_Item__c] = [];
                }

                tmp[item.Quote_Line_Item__c].push(item);

                return tmp;
            }, {});
        }

        return qliIdToAreaCodesListMap;
    },
    checkServicePlanRange: function(component) {
        // Maintain Line # change that causes tier update in the wizard B-57
        var qt = component.get('v.quote');
        var items = this.getCartItems(component);
        var outOfRangeItem = null;
        if (qt && (qt.Pricebook2.Service__c === "Office")) {

            if (qt.Upsell_Status__c == "Upgrade" || qt.Upsell_Status__c == "New") {
                for (var i = 0; i < items.length; i++) {
                    var item = items[i];

                    var dlQuantity = Number(item.NewQuantity__c);

                    if (item.Product2.Feature__c === 17
                        && ((dlQuantity > qt.Pricebook2.Line_Range_Max__c) || (dlQuantity < qt.Pricebook2.Line_Range_Min__c))) {
                        outOfRangeItem = item;
                        break;
                    }
                }
                if (outOfRangeItem) {
                    $A.get("e.c:QuotingToolSwitchServicePlanEvent").setParams({
                        requestTier: outOfRangeItem,
                        type: 'UpgradeAndSignUp',
                        lines: dlQuantity
                    }).fire();
                    var spinner = component.find("save-spinner");
                    $A.util.addClass(spinner, "hide");
                } else {
                    return true;
                }
            } else if (qt.Upsell_Status__c == "Upsell") {
                for (var i = 0; i < items.length; i++) {
                    var item = items[i];

                    var accountLines = component.get('v.accountLines');
                    accountLines = accountLines ? Number(accountLines) : 0;

                    var dlQuantity = Number(item.NewQuantity__c);

                    // B-1494: Service Plan pre-selection: not all users provisioned
                    // Deleted next statement from condition:
                    // || (dlQuantity < qt.Pricebook2.Line_Range_Min__c)
                    var accountDL = accountLines;
                    var tierMinDL = qt.Pricebook2.Line_Range_Min__c;

                    var lineRangeMin = (accountDL > tierMinDL) ? tierMinDL : accountDL;
                    var lineRangeMax = qt.Pricebook2.Line_Range_Max__c;

                    if (item.Product2.Feature__c === 17
                        && (dlQuantity > lineRangeMax || dlQuantity < lineRangeMin)) {
                        outOfRangeItem = item;
                        break;
                    }
                }
                if (outOfRangeItem) {
                    $A.get("e.c:QuotingToolSwitchServicePlanEvent").setParams({
                        requestTier: outOfRangeItem,
                        type: 'Upsell',
                        lines: dlQuantity
                    }).fire();
                    var spinner = component.find("save-spinner");
                    $A.util.addClass(spinner, "hide");
                } else {
                    return true;
                }
                //
            }
            else {
                return true;
            }
        } else {
            return true;
        }
    },

    /**
     * Save Cart
     * 1) Quote line items
     * 2) Area Code Line Items
     */
    saveCartItems: function(component) {
        var Wizard = component.get('v.Wizard');
        var helper = this;
        QW.spinner.show();
        var items = this.getCartItems(component);
        var state = component.get('v.state');
        var currentQuote = component.get('v.Wizard.currentQuote');
        var quote = component.get('v.quote');
        var areaCodeItemsInOperation = component.get('v.areaCodeItemsInOperation');
        let ccOveragePremiumDiscount = quote.Account.CCOveragePremiumDiscount__c;
        let overagePremiumDiscountToggle = Wizard.settings.featureToggle.AccountPremiumOverageCharge__c;
        var params = {};
        //B-1495
        var thresholdDependentTypes = [
            QW.CONSTANTS.PRODUCT2.PRODUCT_TYPE.SEAT.toLowerCase(),
            QW.CONSTANTS.PRODUCT2.PRODUCT_TYPE.PORT.toLowerCase()
        ];
        var discountDependentTypes = [QW.CONSTANTS.PRODUCT2.PRODUCT_TYPE.SEAT.toLowerCase()];
        var overages = {};
        var seatItem;
        items.forEach(function (item) {
            if (item.Product_Type__c && item.Product2.Family === QW.CONSTANTS.PRODUCT2.FAMILY.OVERAGE && !item.Deactivated__c) {
                // Old functionality 'isAllowedEditDiscount' was set here, which caused threshold values of Seat Overage to be 0 if the user had that permission (Sales 4.0 inContact Order Lightning profile)
                overages[item.Product_Type__c.toLowerCase()] = item;
            } else {
                if (item.Product_Type__c && item.Product_Type__c.toLowerCase() == "seat" && !item.Deactivated__c) {
                    seatItem = item;
                }
            }
        });

        var extIdProdMap = {};

        items.forEach(function(item) {
            if (item.Product2.Family != QW.CONSTANTS.PRODUCT2.FAMILY.OVERAGE && !item.Deactivated__c) {
                var dsc = item.Discount_number__c;
                if (!dsc) { dsc = 0; }
                var dtype = item.Discount_type__c;
                var qty = item.Quantity;
                if (!isNaN(dsc)) { params[item.Id + "%%discount"] = String(dsc); }
                if (qty != null && !isNaN(qty)) {
                    params[item.Id + "%%quantity"] = String(qty);
                }
                params[item.Id + "%%discountType"] = dtype;

                if(item.Deactivated__c !== undefined) {
                    params[item.Id + "%%isDeactivated"] = String(item.Deactivated__c);
                }

                if (state.isCCProServQuote && item.Product2.CatID__c){
                    params[item.Id + "%%provisionedByInContact"] = item.Provisioned_by_inContact__c ? 'true' : 'false';
                }

                //B-4677
                if (item.Product2.ExtID__c) {
                    var extIdSplitted = item.Product2.ExtID__c.split("_");
                    extIdSplitted[0] = QW.CONSTANTS.PRODUCT2.FAMILY.OVERAGE;
                    // extIdSplitted[3] = "Monthly";
                    extIdProdMap[extIdSplitted.join("_")] =
                    {
                        "qty" : item.Quantity ? item.Quantity : 0,
                        "dscType" : item.Discount_type__c ? item.Discount_type__c : QW.CONSTANTS.QUOTE_LINE_ITEM.DISCOUNT_TYPE.CURRENCY,
                        "dsc" : (item.Discount_number__c ? item.Discount_number__c : 0) /
                        (item.Product2.Charge_Term__c === QW.CONSTANTS.PRODUCT2.CHARGE_TERM.ANNUAL
                            && item.Discount_type__c === QW.CONSTANTS.QUOTE_LINE_ITEM.DISCOUNT_TYPE.CURRENCY ? 12 : 1)
                    };
                }

                // B-1495, 1497
                if (item.Product_Type__c && thresholdDependentTypes.includes(item.Product_Type__c.toLowerCase())) {
                    var oitem = overages[item.Product_Type__c.toLowerCase()];
                    if (oitem != undefined) {
                        if (qty != null && !isNaN(qty)) {
                            params[oitem.Id + "%%quantity"] = String(qty);
                        }
                        if (item.Deactivated__c !== undefined) {
                            params[oitem.Id + "%%isDeactivated"] = String(item.Deactivated__c);
                        }

                        if (discountDependentTypes.includes(item.Product_Type__c.toLowerCase())) {
                            if (dtype == QW.CONSTANTS.QUOTE_LINE_ITEM.DISCOUNT_TYPE.CURRENCY) {
                                if (!isNaN(dsc)) {
                                    if (overagePremiumDiscountToggle && ccOveragePremiumDiscount) {
                                        let up = Number(item.UnitPrice);
                                        if (item.Product2.Charge_Term__c === QW.CONSTANTS.PRODUCT2.CHARGE_TERM.ANNUAL) {
                                            up = up / 12;
                                        }
                                        let priceDiff = Number(oitem.UnitPrice) - Number(up);
                                        dsc = Number(dsc) + priceDiff;
                                    }
                                    if (item.Product2.Charge_Term__c === QW.CONSTANTS.PRODUCT2.CHARGE_TERM.ANNUAL) {
                                        dsc = dsc / 12;
                                    }
                                    params[oitem.Id + "%%discount"] = String(dsc);
                                }
                            } else {
                                if (!isNaN(dsc)) {
                                    let up = Number(item.UnitPrice);
                                    if (item.Product2.Charge_Term__c === QW.CONSTANTS.PRODUCT2.CHARGE_TERM.ANNUAL) {
                                        up = up / 12;
                                    }
                                    //B-1495
                                    let dsc2 = String(dsc * up / Number(oitem.UnitPrice));
                                    if (overagePremiumDiscountToggle && ccOveragePremiumDiscount) {
                                        let priceDiff = Number(oitem.UnitPrice) - up;
                                        dsc2 = String((up * dsc + priceDiff * 100) / (up + priceDiff));
                                    }
                                    params[oitem.Id + "%%discount"] = dsc2;
                                }
                            }
                            params[oitem.Id + "%%discountType"] = dtype;
                        } else {
                            params[oitem.Id + "%%discount"] = oitem.Discount_number__c;
                            params[oitem.Id + "%%discountType"] = oitem.Discount_type__c;
                        }
                    }
                }
                //B-1495, 1497
            }
        });

        items.forEach(function(item) {
            if(item.Entitlement__c && item.NewQuantity__c !== item.Entitlement__r.Quantity__c) {
                params[item.Id + "%%quantityForThreshold"] = String(item.Quantity);
            }
            if (!params[item.Id+"%%quantity"]) {
                //var dsc = item.Discount_number__c;
                //if (!dsc) {dsc = 0;}
                //var dtype = item.Discount_type__c;
                //var qty = extIdProdMap[item.Product2.ExtID__c] ? extIdProdMap[item.Product2.ExtID__c] : item.Quantity;
                // updated logic with discounts
                var dsc = item.Discount_number__c?item.Discount_number__c:0;
                var dtype = item.Discount_type__c?item.Discount_type__c:QW.CONSTANTS.QUOTE_LINE_ITEM.DISCOUNT_TYPE.CURRENCY;
                var qty = item.Quantity?item.Quantity:0;
                if(item.Product2.Family === QW.CONSTANTS.PRODUCT2.FAMILY.OVERAGE)
                {
                    if(extIdProdMap[item.Product2.ExtID__c])
                    {
                        const isItemDiscountDependent = item.Product_Type__c && discountDependentTypes.includes(item.Product_Type__c.toLowerCase());
                        dsc = isItemDiscountDependent
                            ? extIdProdMap[item.Product2.ExtID__c].dsc
                            : item.Discount_number__c;
                        dtype = isItemDiscountDependent
                            ? extIdProdMap[item.Product2.ExtID__c].dscType
                            : item.Discount_type__c;
                        qty = extIdProdMap[item.Product2.ExtID__c].qty;
                    }
                }
                //end of updated logic with discounts
                if (!isNaN(dsc)) { params[item.Id + "%%discount"] = String(dsc); }
                if (qty != null && !isNaN(qty)) {
                    params[item.Id + "%%quantity"] = String(qty);
                }
                params[item.Id + "%%discountType"] = dtype;

                if(item.Deactivated__c !== undefined) {
                    params[item.Id + "%%isDeactivated"] = String(item.Deactivated__c);
                }
            }
        });

        if (seatItem) {
            items.forEach(function (item) {
                if (
                    item.Product2.Family == QW.CONSTANTS.PRODUCT2.FAMILY.OVERAGE
                    || item.Product2.Sub_Category__c == QW.CONSTANTS.PRODUCT2.SUB_CATEGORY.CONTACT_CENTER
                ) {
                    if (seatItem.Deactivated__c) {
                        params[item.Id + "%%isDeactivated"] = String(seatItem.Deactivated__c);
                        params[item.Id + "%%quantity"] = "0";
                    }
                }
            });
        }

        var targetPriceContactCenterARR = 0;
        items.forEach((item) => {
            if (item.NewQuantity__c != 0 && this.isContactCenter(item)) {
                targetPriceContactCenterARR += this.computeTargetPriceContactCenterARR(item);
            }
        });

        var saveCartProcess = Promise.resolve();

        // Remove Taxes

        var areaCodesMap = {};
        if(areaCodeItemsInOperation.length > 0) {
            areaCodeItemsInOperation.forEach(function(areaCode) {
                areaCodesMap[areaCode.Quote_Line_Item__c] = areaCodesMap[areaCode.Quote_Line_Item__c] || [];
                areaCodesMap[areaCode.Quote_Line_Item__c].push(areaCode);
            });
        }

        const isOtherChanged = items.some(item => item.isOtherChanged);

        const isQuantityChangedByAreaCodes = items.some((item) => {
            const areaCodes = areaCodesMap[item.Id] || [];
            if(areaCodes.length > 0) {
                const areaCodesQuantitySum = areaCodes.reduce((sum, current) => {
                    return sum + Number(current.Quantity__c);
                }, 0);

                return areaCodesQuantitySum != item.Quantity;
            }
            return false;
        });

        const shouldRemoveTaxes = isQuantityChangedByAreaCodes || isOtherChanged;

        if(isQuantityChangedByAreaCodes) {
            this.updateQLIQuantityFromAreaCodes(params, items, areaCodesMap);
        }

        if(state.isTaxesInCart && shouldRemoveTaxes) {
            QW.spinner.show('Removing taxes');
            saveCartProcess = saveCartProcess.then($A.getCallback(function(){
                return QW.salesforce.request(component, 'c.removeTaxes', { quoteId: quote.Id });
            }));
        }

        // Quote Line Items
        saveCartProcess = saveCartProcess.then($A.getCallback(function(){
            QW.spinner.show('Saving Cart');
            return QW.salesforce.request(component, 'c.updateCartItems', { quoteId: quote.Id, params: params })
                .then($A.getCallback(function(){
                    const quoteParams = {
                        id: String(quote.Id),
                        opportunityId: String(quote.OpportunityId),
                        targetPriceContactCenterARR: Number(targetPriceContactCenterARR)
                    };
                    return QW.salesforce.request(
                            component,
                            'c.updateTargetPriceContactCenterARR',
                            { ccQuoteParams: quoteParams }
                        )
                }));
        }));

        // Area Codes
        if (currentQuote.isAreaCodesAllowed){
            var areaCodesToSave = this.getUnsavedAreaCodes(component);
            if(areaCodesToSave.length > 0) {
                QW.spinner.show('Saving Area Codes');
                saveCartProcess = saveCartProcess.then($A.getCallback(function () {
                    return QW.salesforce.request(component, 'c.saveAreaCodeItems', {areaCodesToSave: areaCodesToSave});
                }));
            }
        }

        saveCartProcess = saveCartProcess.then($A.getCallback(function(){
                // Update dependent items for Common Phones B-2177
                return QW.salesforce.request(component, 'c.commonPhonesDependencyUpdate', {
                    quoteId: quote.Id
                });

            }))
            // B-3578 Extended enterprise support to match # of DLs
            .then($A.getCallback(function(){
                return helper.fixExtendedEnterpriseSupport(component);
            }));

        // Get Taxes
        if (component.get('v.completeAction') === 'getTaxes' && (!shouldRemoveTaxes || !state.isTaxesInCart)) {
            component.get('v.completeAction', '');
            QW.spinner.show('Getting taxes into the Cart');
            saveCartProcess = saveCartProcess.then($A.getCallback(function(){
                return QW.salesforce.request(component, 'c.getTaxes', { quoteId: quote.Id });
            }));
        }
        // Catch Errors
        saveCartProcess = saveCartProcess.catch($A.getCallback(function(error){
            helper.handleErrorResponse(error, true);
        }));
        // Update Cart and Quote
        saveCartProcess = saveCartProcess.then($A.getCallback(function(res){
            helper.handleFailedResponse(res);
                // refresh quote
                $A.get("e.c:QuotingToolRefreshQuoteEvent").fire();
                // refresh cart
                return helper.refreshCart(component);
            }))
            .then($A.getCallback(function(){
                QW.spinner.hide();
            }));

        return saveCartProcess;
    },

    updateQLIQuantityFromAreaCodes: function(params, items, areaCodesMap) {

        const paramsKeys = Object.keys(params);

        items.forEach((item) => {
            const areaCodes = areaCodesMap[item.Id] || [];

            if(areaCodes.length > 0) {
                const areaCodesQuantitySum = areaCodes.reduce((sum, current) => {
                    return sum + Number(current.Quantity__c);
                }, 0);

                if(areaCodesQuantitySum != item.Quantity) {

                    // update QLI quantity in params
                    const quantityPropName = paramsKeys.filter((propName) => {
                        return propName.indexOf(item.Id) > -1;
                    }).find((propName) => {
                        return propName.indexOf('quantity') > -1;
                    });

                    if(params[quantityPropName] != areaCodesQuantitySum) {
                        params[quantityPropName] = areaCodesQuantitySum;
                    }
                }
            }
        });
    },

    removeQli: function(component, qliToDelete) {
        var helper = this;
        var state = component.get('v.state');
        var quote = component.get('v.quote');

        const isSeat = this.isSeat(qliToDelete);

        var deleteQliProcess = Promise.resolve();
        // Remove Taxes
        if (state.isTaxesInCart) {
            QW.spinner.show('Removing taxes');
            deleteQliProcess = deleteQliProcess.then($A.getCallback(function () {
                return QW.salesforce.request(component, 'c.removeTaxes', {quoteId: component.get('v.quote.Id')})
                    .then($A.getCallback(() => QW.spinner.hide()));
            }));
        }
        // Delete qli
        return deleteQliProcess.then($A.getCallback(function () {
            return QW.salesforce.request(component, 'c.deleteQuoteLineItem', {deletingQli: qliToDelete});
        }))
        // step which need to move in apex?
            .then($A.getCallback(function () {
                return helper.updateItems(component, ['deleted'], {qli: qliToDelete});
            }))
            .then($A.getCallback(function () {
                // fire which item was deleted
                component.getEvent('QuotingToolCartListEntryEvent').setParams({
                    action: 'deleted',
                    params: {qli: qliToDelete}
                }).fire();
            }))

            // Update dependent items for Common Phones B-2177
            .then($A.getCallback(function () {
                return QW.salesforce.request(component, 'c.commonPhonesDependencyUpdate', {
                    quoteId: quote.Id
                });

            }))
            .then($A.getCallback(function() {
                const quoteParams = {
                    id: String(quote.Id),
                    opportunityId: String(quote.OpportunityId),
                    targetPriceContactCenterARR: 0
                };
                return QW.salesforce.request(
                        component,
                        'c.updateTargetPriceContactCenterARR',
                        { ccQuoteParams: quoteParams }
                    )
            }))
            .catch($A.getCallback(function (error) {
                //Execution Error
                console.error(error);
                if (qliToDelete.Product2.CatID__c == QW.CONSTANTS.PRODUCT2.CAT_ID.IVINEX_UNIFIED_USER_EXPERIENCE_ADDITIONAL_STORAGE
                    || qliToDelete.Product2.CatID__c == QW.CONSTANTS.PRODUCT2.CAT_ID.IVINEX_UNIFIED_USER_EXPERIENCE_BU_CHARGE) {
                        helper.showToast('Failed to delete ' + qliToDelete.Product2.Name,
                            'You can\'t delete this item when \'Ivinex Unified User Experience\' product is in the cart', 'error', false);
                        var deletingItems = component.get('v.deletingItems');
                        deletingItems.delete(qliToDelete.Id);
                        component.set('v.deletingItems', deletingItems);
                } else {
                    helper.showToast('Failed to delete ' + qliToDelete.Product2.Name, QW.salesforce.getResponseError(error), 'error', false);
                }
            }))
    },
    /**
     * Delete QuoteLineItem
     * If there is taxes in the cart they will be removed first
     * @param component     {object} Aura Component
     * @param qliToDelete  {object} QuoteLineItem To Delete
     */
    deleteQli: function (component, qliToDelete) {
        var helper = this;
        var deletingItems = component.get("v.deletingItems");
        deletingItems.add(qliToDelete.Id);
        component.set("v.deletingItems", deletingItems);

        return this.removeQli(component, qliToDelete)
            // Refresh
            .then($A.getCallback(function () {
                // refresh quote
                $A.get("e.c:QuotingToolRefreshQuoteEvent").fire();

                var isSkipAreaCodesRefresh = true;
                // refresh cart
                return helper.refreshCart(component, isSkipAreaCodesRefresh);
            }))

            // Product no longer deleting
            .then($A.getCallback(function () {
                var deletingItems = component.get('v.deletingItems');
                deletingItems.delete(qliToDelete.Id);
                component.set('v.deletingItems', deletingItems);
            }));
    },

    validateBeforeAddToCart: function (component, product) {
        return [
            this.validateSimilarProducts(component, product),
            this.validateSubCategory(component, product),
            this.validateCCAndActiveSeats(component, product)
        ].every(v => v);
    },

    validateSimilarProducts: function(component, product){
        let result = true;
        let addingToCartProds = component.get('v.addingToCartProds');
        const restrictedProductTypes = ['Seat', 'Transport', 'Port'];
        if (addingToCartProds.size > 0 && restrictedProductTypes.indexOf(product.Product2.Product_Type__c) !== -1) {
            let getSimilarProduct = this.checkForSimilarProducts(component, product);
            if (getSimilarProduct) {
                const errorMessage = "Only one product with this family is allowed to be in the cart";
                this.showToast(
                    'Failed to add product to cart',
                    errorMessage,
                    'error',
                    false
                );

                result = false;
            }
        }
        return result;
    },

    validateSubCategory: function (component, product) {
        let result = true;
        const settings = component.get('v.settings');
        if (settings.CC_CATEGORIES.indexOf(product.Product2.Sub_Category__c) !== -1) {
            const prodSub = product.Product2.Sub_Category__c;
            const cartItems = component.get('v.cartItems');
            let qliWithAnotherSubCategory = this.getQLIWithDifferentSubCategory(cartItems, prodSub, settings.CC_CATEGORIES);
            if (qliWithAnotherSubCategory) {
                const qliSub = qliWithAnotherSubCategory.Product2.Sub_Category__c;
                const errorMessage = "Can't add " + prodSub + " item to Cart with " + qliSub + " items";
                this.showToast(
                    'Failed adding Product to Cart',
                    errorMessage,
                    'error',
                    false
                );

                result = false;
            }
        }
        return result;
    },

    validateCCAndActiveSeats: function(component, product){
        let result = true;
        // B-1871
        if (product.Product2.Sub_Category__c === "Contact Center") {
            // TODO Disable "add to cart" button for such products
            if (component.get("v.state.isActiveSeatOnAccountOrQuote")) {
                this.showToast(
                    `Failed to add ${product.Product2.Name}`,
                    "Can't add Contact Center Products unless there are active seats on the Account or Quote",
                    'error',
                    false
                );

                result = false;
            }
        }
        return result;
    },

    markProductsAsAddingToCart: function(component, products) {
        let addingToCartProds = component.get('v.addingToCartProds');
        let addingToCartProductsList = component.get('v.addingToCartProductsList');
        products.forEach(product => {
            addingToCartProds.add(product.Product2Id);
            addingToCartProductsList.push(product);
        });
        component.set('v.addingToCartProds', addingToCartProds);
        component.set('v.addingToCartProductsList', addingToCartProductsList);
        component.set('v.addingToCartProdsUpdated', Date.now());
    },

    removeAddingToCartMarkFromProducts: function(component, products) {
        let addingToCartProds = component.get('v.addingToCartProds');
        let addingToCartProductsList = component.get('v.addingToCartProductsList');
        products.forEach(product => {
            addingToCartProds.delete(product.Product2Id);
            addingToCartProductsList.pop(product.Product2Id);
        });
        component.set('v.addingToCartProds', addingToCartProds);
        component.set('v.addingToCartProductsList', addingToCartProductsList);
    },

    createQuoteLineItems: function (component, products, pbeToQtyMap) {
        let pricebookEntryIdToQuantity = {};
        products.forEach(p => {
            pricebookEntryIdToQuantity[p.Id] = pbeToQtyMap && !!pbeToQtyMap[p.Id] ? pbeToQtyMap[p.Id] : 1;
        });

        return RC.salesforce.request(component, 'c.createQuoteLineItems', {
                quoteId: component.get('v.Wizard.currentQuote.record.Id'),
                pricebookEntryIdToQuantity
            })
            .then($A.getCallback(newQLIs => {
                let freshItems = component.get('v.freshItems');
                freshItems.push(...newQLIs);
                component.set('v.freshItems', freshItems);
            }))
            // Catch errors
            .catch($A.getCallback(error => {
                const prodNames = products.map(p => p.Product2.Name).join(', ');
                RC.salesforce.displayError(`Failed to add to the cart: ${prodNames}`, error);
            }))
    },

    finalizeAddToCart: function(component, products){
        let helper = this;
            const settings = component.get('v.settings');
            const featureForEES = settings.featureForEES ? settings.featureForEES : 38;
            const isEESWasAdded = products.some(p => QW.Product2Helper.checkIsExtendedEnterpriseSupport(p.Product2, featureForEES));

            const seatItem = products.find(item => this.isSeat(item));
            var targetPriceContactCenterARR = 0;
            if (seatItem) {
                targetPriceContactCenterARR = this.computeTargetPriceContactCenterARR(seatItem);
            }

            // Update dependent items for Common Phones B-2177
            return RC.salesforce.request(component, 'c.commonPhonesDependencyUpdate', {
                quoteId: component.get('v.Wizard.currentQuote.record.Id')
            })
            // B-6092: Quote.ProServ_Type__c update on existing CC_Proserv quote depending on what type of product was added - CC or RC CC
            // Also method sends email to proservsow@ringcentral.com.
            .then($A.getCallback(() => {
                let wizard = component.get('v.Wizard');
                let found = wizard.quotes.find( item => item.isCCProServ);
                let subCategory = products.find(p => settings.CC_CATEGORIES.indexOf(p.Product2.Sub_Category__c) !== -1);
                if (found && subCategory) {
                    return QW.salesforce.request(component, 'c.changeProservType', {
                        quote: found.record,
                        proservType: subCategory.Product2.Sub_Category__c
                    });
                }
            }))
            .then($A.getCallback(function(result){
                if(result){
                    result.messages.map(m => helper.showToast(m.message, m.messageDetails, m.severity , false));
                }
            }))
            // Check if Extended Enterprise Support Product is in range
            .then($A.getCallback(function(){
                if (isEESWasAdded){
                    return helper.fixExtendedEnterpriseSupport(component, true);
                }
            }))
            // Create areaCodes for phones and additional numbers
            .then($A.getCallback(function(){
                $A.get("e.c:QuotingToolRefreshQuoteEvent").fire();
                return helper.precreateAreaCode(component);
            }))
            .then($A.getCallback(function(){
                const quote = component.get('v.Wizard.currentQuote.record');
                const quoteParams = {
                    id: String(quote.Id),
                    opportunityId: String(quote.OpportunityId),
                    targetPriceContactCenterARR: Number(targetPriceContactCenterARR)
                };
                return QW.salesforce.request(component, 'c.updateTargetPriceContactCenterARR', {ccQuoteParams: quoteParams});

            }))
            // Catch errors
            .catch($A.getCallback(error => {
                const prodNames = products.map(p => p.Product2.Name).join(', ');
                RC.salesforce.displayError(`Failed to finalize adding to the cart: ${prodNames}`, error);
            }))
            // Refresh Cart and quote
            .then($A.getCallback(function(){
                const isSkipAreaCodesRefresh = false;
                return helper.refreshCart(component, isSkipAreaCodesRefresh);
            }))
            .then($A.getCallback(() => {
                this.removeAddingToCartMarkFromProducts(component, products);
            }));
    },

    sortProducts: function(products) {
        products.sort(function(a, b) {
            return (b.Product2.Family === "Service") - (a.Product2.Family === "Service") || // service products first
                (Number.isInteger(b.Product2.Dependent_on_Feature__c)) - (Number.isInteger(a.Product2.Dependent_on_Feature__c)) || // then dependent on feature
                (b.Product2.Family < a.Product2.Family) - (a.Product2.Family < b.Product2.Family) || // by category
                (b.Product2.Name < a.Product2.Name) - (a.Product2.Name < b.Product2.Name) || // by name
                (b.Product2.Charge_Term__c < a.Product2.Charge_Term__c) - (a.Product2.Charge_Term__c < b.Product2.Charge_Term__c) // by plan
        });
        return products;
    },

    /**
     * Loads Tax items to cart from external system
     */
    getTaxesToCart: function(component) {
        var helper = this;
        QW.spinner.show('Adding Taxes');
        QW.salesforce.request(component, 'c.getTaxes', { quoteId: component.get('v.quote.Id') })
            .catch($A.getCallback(function(error){
                helper.handleErrorResponse(error, false);
            }))
            .then($A.getCallback(function(res){
                helper.handleFailedResponse(res);

                // refresh quote
                $A.get("e.c:QuotingToolRefreshQuoteEvent").fire();
                // refresh cart
                var isSkipAreaCodesRefresh = true;

                helper.updateQuoteBillingAddress(component);
                return helper.refreshCart(component, isSkipAreaCodesRefresh);
            }))
            .then($A.getCallback(function(){
                QW.spinner.hide();
            }));
    },

    updateQuoteBillingAddress: function(component) {
        var quote = component.get("v.quote");

        QW.salesforce.request(component,
            'c.updateQuoteBillingAddress',
            {quoteId: quote.Id, accountId: quote.AccountId});
    },

    /**
     * Delete all items with Taxes family from cart
     */
    removeTaxesFromCart: function(component) {
        var helper = this;
        QW.spinner.show('Removing taxes from the Cart');
        QW.salesforce.request(component, 'c.removeTaxes', { quoteId: component.get('v.quote.Id') })
            .catch($A.getCallback(function(error){
                console.error(error);
                helper.showToast('Failed to remove taxes', QW.salesforce.getResponseError(error), 'error', false);
            }))
            .then($A.getCallback(function(res){
                // refresh quote
                $A.get("e.c:QuotingToolRefreshQuoteEvent").fire();
                // refresh cart
                var isSkipAreaCodesRefresh = true;
                return helper.refreshCart(component, isSkipAreaCodesRefresh);
            }))
            .then($A.getCallback(function(){
                QW.spinner.hide();
            }));
    },

    /**
     * Refresh Cart
     * 1) Get Quote Line Items
     * 2) Get Area Code Line Items
     */
    refreshCart: function(component, isSkipAreaCodesRefresh) {
        var helper = this;

        var quoteId = component.get('v.Wizard.currentQuote.record.Id');
        if (!quoteId) {
            component.set("v.cartItems", []);
            return;
        }

        return RC.salesforce.request(component, 'c.getQuoteLineItems', {quoteId: quoteId})
            .then($A.getCallback(cartItems => {
                component.set("v.cartItems", helper.sortProducts(cartItems));
                helper.checkDisplayColumns(component);

                if (component.get('v.Wizard.currentQuote.isAreaCodesAllowed') && !isSkipAreaCodesRefresh) {
                    return QW.salesforce.request(component, 'c.getAreaCodeItems', { qlis: component.get('v.cartItems') })
                        .then($A.getCallback(areaCodeItems => {

                            helper.setAreaCodeItems(component, areaCodeItems);
                            helper.discardAreaCodes(component);
                        }))
                        .catch($A.getCallback(error => RC.salesforce.displayError('Failed to get Area Code Items', error)));
                }
            }))
            .catch($A.getCallback(error => RC.salesforce.displayError('Failed to refresh cart', error)))
            .then($A.getCallback(() => {
                helper.setIsCartChanged(component);
            }));
    },

    /**
     *	Update Total Cost outputs
     */
    updateTotals: function(component, quote) {

        if (quote) {
            var isQuoteHasQlisWithoutEffectivePrice =
                this.getCartItems(component).some(cartItem => cartItem.EffectivePriceNew__c === undefined);
            var isNewTotalsToBeShown = !isQuoteHasQlisWithoutEffectivePrice;
            var FYCS = isNewTotalsToBeShown
                       ? quote.Total_First_Year_Cost__c || 0
                       : quote.First_Year_Cost_of_Service__c || 0;

            var FYTCET = quote.First_Year_Total_Cost_excluding_Taxes__c || 0;

            var FYD = isNewTotalsToBeShown
                      ? quote.Total_First_Year_Discount__c || 0
                      : quote.First_Year_Discount__c || 0;

            var InitPaym = isNewTotalsToBeShown
                           ? quote.Total_Initial_Payment__c || 0
                           : quote.Initial_Payment__c + (FYCS - FYTCET);

            var InitDisc = isNewTotalsToBeShown
                           ? quote.Total_Initial_Payment_Discount__c || 0
                           : quote.Initial_Discount__c || 0;

            var MRR = isNewTotalsToBeShown
                      ? quote.Total_MRR_New__c || 0
                      : quote.Monthly_Recurring_Revenue__c || 0;

            component.set("v.YearCost", FYCS);
            component.set("v.YearDiscount", FYD);
            component.set("v.InitialPayment", InitPaym);
            component.set("v.InitialDiscount", InitDisc);
            component.set("v.RecurringRevenue", MRR);
        } else {
            component.set("v.YearCost", 0);
            component.set("v.YearDiscount", 0);
            component.set("v.InitialPayment", 0);
            component.set("v.InitialDiscount", 0);
            component.set("v.RecurringRevenue", 0);
        }
    },

    getEntitlementsFromCtrl: function(component) {
        var helper = this;
        var quote = component.get('v.quote');
        var Wizard = component.get('v.Wizard');

        if(!quote || !quote.AccountId) return;

        if(Wizard.opportunity.isClosed) return;

        QW.salesforce.request(component, 'c.getEntitlements', {accountId: quote.AccountId})
            .then($A.getCallback(function(res) {
                if(!component.isValid()) return;
                component.set('v.entitlements', res);
                helper.checkEntitlements(component);
            }))
            .catch($A.getCallback(function(error) {
                console.error(error);
                helper.showToast('Get Entitlements Error', QW.salesforce.getResponseError(error), 'error');
            }));
    },

    checkEntitlements: function(component) {
        var helper = this;
        var qli = component.get('v.cartItems');
        var ents = component.get('v.entitlements');

        helper.createItemsForEntitlements(component, qli, ents);
        helper.updateUserCartItems(component);
        helper.isAtLeastOneActiveEnt(component);
        helper.checkDisplayColumns(component);

        helper.checkEntTypes(component);
    },

    checkEntTypes: function(component) {
        var Wizard = component.get('v.Wizard');
        var ents = component.get('v.entitlements');

        if(ents.length > 0) {
            for(var i=0; i<ents.length; ++i) {
                if(ents[i].Product__r.Sub_Category__c === QW.CONSTANTS.QUOTE.PRODUCTS.CONTACT_CENTER
                    || ents[i].Product__r.Sub_Category__c === QW.CONSTANTS.QUOTE.PRODUCTS.RC_CONTACT_CENTER) {
                    Wizard.isAccHasCcEntls = true;
                    component.set('v.Wizard', Wizard);
                    break;
                }
                if(ents[i].Product__r.Feature__c == QW.CONSTANTS.PRODUCT2.FEATURE.INCONTACT_INTERCONNECT) {
                    Wizard.isAccHasIcEntls = true;
                    component.set('v.Wizard', Wizard);
                    break;
                }
            }
        }
    },

    isAtLeastOneActiveEnt: function(component) {
        var isAtLeastOneActiveEnt = false;
        var Ent = component.get('v.Ent');
        var currentCartItems = component.get('v.currentCartItems');

        currentCartItems.forEach(function(groupItems) {
            groupItems.items.forEach(function(item) {
                if(item.Entitlement__r && item.Entitlement__r.Active__c) isAtLeastOneActiveEnt = true;
            });
        });

        Ent.isAtLeastOneActiveEnt = isAtLeastOneActiveEnt;
        component.set('v.Ent', Ent);
    },

    /**
     * Show/hide table columns
     */
    checkDisplayColumns: function (component) {
        var isAtLeastOneActiveEnt = component.get('v.Ent.isAtLeastOneActiveEnt');
        var Wizard = component.get('v.Wizard');
        var state = component.get('v.state');

        if (!Wizard.currentQuote)
            return;

        // Quantity
        var isQuantityColumnVisible = !(Wizard.opportunity.isChangeOrderOpportunity
            && Wizard.currentQuote.isAtLeastOneCartItemWithAsset)
            && !isAtLeastOneActiveEnt;
        QW.cssUtils.toggleShow(component, 'cart', isQuantityColumnVisible, 'cart-hide--qty');

        // Existing Quantity
        var isExistingQTYvisible = (Wizard.opportunity.isChangeOrderOpportunity
            && Wizard.currentQuote.isAtLeastOneCartItemWithAsset)
            || isAtLeastOneActiveEnt;
        QW.cssUtils.toggleShow(component, 'cart',  isExistingQTYvisible, 'cart-hide--existing-qty');

        // Delivered Quantity
        var isDeliveredQTYvisible = (Wizard.opportunity.isChangeOrderOpportunity
            && Wizard.currentQuote.isAtLeastOneCartItemWithAsset);
        QW.cssUtils.toggleShow(component, 'cart',  isDeliveredQTYvisible, 'cart-hide--delivered-qty');

        // New Quantity
        var isNewTotalQTYvisible = (Wizard.opportunity.isChangeOrderOpportunity
            && Wizard.currentQuote.isAtLeastOneCartItemWithAsset) || isAtLeastOneActiveEnt;
        QW.cssUtils.toggleShow(component, 'cart',  isNewTotalQTYvisible, 'cart-hide--new-total-qty');

        // Discount columns
        QW.cssUtils.toggleShow(component, 'cart', !state.isUserRelayware, 'cart-hide--discount');
        QW.cssUtils.toggleShow(component, 'cart', !state.isUserRelayware, 'cart-hide--discount-type');

        // Provisioned by InContact field
        //Temporary disable InContact checkBox from front end
        //var isProvByInContactVisible = state.isCCProServQuote && state.isCatIdInCart;
        var isProvByInContactVisible = false;
        QW.cssUtils.toggleShow(component, 'cart', isProvByInContactVisible, 'cart-hide--provisioned-by-incontact');

    },

    checkCartItems: function(component) {
        var helper = this;
        var result = true;
        var params = component.get('v.params');

        // Check if Seat try to deactivate (qty set 0)
        if(params.Seat.isSeatDeactivation) {
            helper.showSeatWarning(component, params.Seat.name);
            result = false;
        }

        var items = this.getCartItems(component);
        let isHasError = items.some(qli => {
            if(qli.Asset__r) {
                // B-3806 New Total Quantity is less than value in Delivered Quantity field
                var isHasDeliveredQTYError = qli.Asset__r.Delivered_Quantity__c > qli.NewQuantity__c;
                // B-5539 New Total Quantity on QLI with disabled Product is more then value in Quantity field on Asset
                var isHasExistingQTYforInactiveProductError = qli.Asset__r.Quantity < qli.NewQuantity__c && qli.Product2.IsActive != true;

                return isHasDeliveredQTYError || isHasExistingQTYforInactiveProductError;
            }
        });

        isHasError = isHasError || items.some(qli => {
            // B-9421 Discount has to be no greater than the price (if Currency) or no greater than 100 (if %)
            if (
                qli.Discount_type__c === QW.CONSTANTS.QUOTE_LINE_ITEM.DISCOUNT_TYPE.CURRENCY
                && !isNaN(qli.UnitPrice) && !isNaN(qli.Discount_number__c)
                && Number(qli.UnitPrice) < Number(qli.Discount_number__c)
            ) {
                this.showError('On product \'' + qli.Product2.Name + '\'', 'Discount can not be higher than the List Price of the Product');
                return true;
            }
            if (qli.Discount_type__c === "Percentage" && 100 < qli.Discount_number__c) {
                this.showError('On product \'' + qli.Product2.Name + '\'', 'Discount can not be higher than 100%');
                return true;
            }
        });

        if(isHasError){
            result = false;
        }

        return result;

    },

    showError: function(header, detail) {
        $A.get("e.c:ToastEvent").setParams({
            theme: 'error',
            header: header,
            details: detail,
            defaultTimeout: false
        }).fire();
    },

    showSeatWarning: function(component, itemName) {
        $A.get("e.c:QuotingToolModalRequestEvent").setParams({
            sourceId: 'QuotingToolCartList',
            action: 'SaveSeatWithZeroQuantity',
            params: {
                message: 'By saving '+itemName+' with 0 quantity, you will remove all existing Contact Center ' +
                'subscriptions for this Account. Сlick Ok to proceed.'
            }
        }).fire();
    },

    /**
     * Get List of Area Code Line items for all cart items
     */
    getAreaCodeItems: function(component){
        var action = component.get("c.getAreaCodeItems");
        action.setParams({ qlis: component.get('v.cartItems') });
        action.setCallback(this, function(actionResult) {
            if (component.isValid() && actionResult.getState() === "SUCCESS") {
                component.set('v.areaCodeItems',actionResult.getReturnValue());
                this.discardAreaCodes(component);
            } else {
                var errmsg = actionResult.getError()[0].message;
                $A.get("e.c:ToastEvent").setParams({
                    theme: 'error',
                    header: 'Failed to get Area Code Items',
                    details: errmsg,
                    defaultTimeout: false
                }).fire();
            }
        });
        $A.enqueueAction(action);
    },

    /**
     * Get unsaved changes in area codes
     * @returns {Array}
     */
    getUnsavedAreaCodes: function(component){
        var areaCodeItems = component.get('v.areaCodeItems');
        var areaCodeItemsInOperation = component.get('v.areaCodeItemsInOperation');

        var oldAreaCodeItemsMap = {};
        areaCodeItems.forEach(function(item){
            oldAreaCodeItemsMap[item.Id] = item;
        });

        return areaCodeItemsInOperation.filter(function(item){
            if (!item.Id){
                return true;
            }
            var oldItem = oldAreaCodeItemsMap[item.Id];
            if (Number(item.Quantity__c) !== oldItem.Quantity__c ||
                item.Area_Code__c !== oldItem.Area_Code__c){
                return true;
            }
        });
    },

    validateAreaCodes: function(component){
        var areaCodeItemsInOperation = component.get('v.areaCodeItemsInOperation');
        var valid = true;
        for (var i = 0; i < areaCodeItemsInOperation.length; i++) {
            // Quantity should be more than 0
            if(areaCodeItemsInOperation[i].Quantity__c < 1 ||
                // Area Code should be populated
                !areaCodeItemsInOperation[i].Area_Code__c){
                valid = false;
                break;
            }
        }
        return valid;
    },

    /**
     * Revert all unsaved changes in Area Codes
     */
    discardAreaCodes: function(component){
        var areaCodeItems = component.get('v.areaCodeItems');
        component.set('v.areaCodeItemsInOperation',JSON.parse(JSON.stringify(areaCodeItems)));
    },

    calcTableHead: function(component) {
        var list = ['detailsAction-col',
            'name-col',
            'icons-col',
            'plan-col',
            'qty-col',
            'existingQty-col',
            'deliveredQty-col',
            'newTotalQty-col',
            'listPrice-col',
            'yourPrice-col',
            'discount-Col',
            'discountType-col',
            'totalPrice-col',
            'provisionedByInContact-col',
            'actions-col'
        ];

        var internal, external, summ = 0;
        for (var i = 0; i < list.length; i++) {
            internal = component.find(list[i]).getElement();
            external = component.find(list[i]+'-external').getElement();

            if (!external || !internal) return;

            external.style.width = internal.offsetWidth + 'px';

            summ += internal.offsetWidth;
        }

        component.find('cart-table-head').getElement().style.minWidth = summ + 'px';
        component.find('cart-table-body').getElement().style.minWidth = summ + 'px';
    },

    createItemsForEntitlements: function(component, qli, ents) {
        var quote = component.get('v.quote');

        if(!quote) return;

        if(ents.length) {
            var unmatchedCartItems = [];
            for (var i = 0; i < ents.length; i++) {

                var isFound = false;
                var deactivated = false;
                for (var k = 0; k < qli.length; k++) {

                    if( qli[k].Entitlement__r && qli[k].Entitlement__r.Id === ents[i].Id) {
                        isFound = true;
                    }
                }
                if( !isFound && ents[i].Active__c ) {
                    deactivated = ents[i].Product__r.Charge_Term__c !== QW.CONSTANTS.PRODUCT2.CHARGE_TERM.ONE_TIME;
                    unmatchedCartItems.push( this.getQLIforEnt(quote, ents[i], deactivated) );
                }
            }

            component.set('v.unmatchedCartItems', unmatchedCartItems);
        }
    },

    isFee: function(ent) {
        var result = false;

        if( ent &&
            ent.Product__r &&
            ent.Product__r.Family &&
            ent.Product__r.Family.toLowerCase() === 'fee' ) {
            result = true;
        }

        return result;
    },

    isService: function(ent) {
        var result = false;

        if( ent &&
            ent.Product__r &&
            ent.Product__r.Family &&
            ent.Product__r.Family.toLowerCase() === 'service' ) {
            result = true;
        }

        return result;
    },

    getQLIforEnt: function(quote, ent, deactivated) {
        var qty = deactivated && ent.DisplayQuantity__c !== 0 ? -ent.DisplayQuantity__c : ent.DisplayQuantity__c;
        var isOneTimePhone = ent.Product__r.Charge_Term__c === QW.CONSTANTS.PRODUCT2.CHARGE_TERM.ONE_TIME;

        return {
            UnitPrice: ent.Price__c,
            Quantity: qty,
            ExistingQuantity: isOneTimePhone ? 0 : undefined,
            Subtotal: this.getSubtotal(ent, qty),
            TotalPrice: this.getTotalPrice(ent, qty),
            CurrencyIsoCode: ent.CurrencyIsoCode,
            Discount_number__c: ent.Discount__c || 0,
            Discount_type__c: ent.Discount_Type__c,
            Deactivated__c: deactivated,
            QuoteId: quote.Id,
            Quote: {
                Id: quote.Id,
                RecordTypeId: quote.RecordTypeId,
            },
            Entitlement__r: {
                Id: ent.Id,
                Active__c: true,
                Quantity__c: ent.Quantity__c
            },
            Product2: {
                Id: ent.Product__r.Id,
                Name: ent.Product__r.Name,
                Family: ent.Product__r.Family,
                Charge_Term__c: ent.Product__r.Charge_Term__c,
                Cart_Tab_Availability__c: ent.Product__r.Cart_Tab_Availability__c
            },
            Disabled__c: isOneTimePhone ? false : true,
            Unmatched: true,
            DisplayOnly: isOneTimePhone ? false : true,
            sobjectType: 'QuoteLineItem'
        };
    },

    getYourPrice: function(unitPrice, discount, discountType) {
        var result = unitPrice;
        if(discount) {
            if (discountType === 'Percentage') {
                result = result * (1 - discount/100);
            } else {
                result = result - discount;
            }
        }
        return result;
    },

    getTotalPrice: function(ent, qty) {
        var yourPrice = this.getYourPrice(ent.Price__c, ent.Discount__c, ent.Discount_Type__c);
        return qty * yourPrice;
    },

    getSubtotal: function(ent, qty) {
        return qty * ent.Price__c;
    },

    updateListQli: function(component, listQli) {
        var helper = this;

        return QW.salesforce.request(component, 'c.updateListQli', {listQli: listQli})
            .catch($A.getCallback(function(error) {
                helper.showToast('Update Quote Line Items Error', QW.salesforce.getResponseError(error), 'error');
            }));
    },

    getCCAmeliaVoiceAddOnVolume: function(item) {
        const regex = /[0-9][0-9,]+/g;
        if (item.Product2.Product_Type__c === 'Calls Bundle' && item.Product2.Family != 'Overage') {
            var volumeStr = item.Product2.Name.toString().match(regex)[0];
            return Number(volumeStr.replaceAll(",",""));
        }
        return null;
    },

    isCCUpgradableBundle: function(item1, item2) {
        const item1ProductName = item1.Product2.Name.substring(0, item1.Product2.Name.indexOf(' ('));
        const item2ProductName = item2.Product2.Name.substring(0, item2.Product2.Name.indexOf(' ('));
        if (!item2) {
            return this.isCCUpgradableBundleItem(item1);
        } else {
            return this.isCCUpgradableBundleItem(item1)
                && this.isCCUpgradableBundleItem(item2)
                && item1.Product2.Family === item2.Product2.Family
                && item1.Product2.Product_Type__c === item2.Product2.Product_Type__c
                && item1ProductName == item2ProductName;
        }
    },

    isCCUpgradableBundleItem: function(item) {
        if (!this.isContactCenter(item)) {
            return false;
        }
        return item.Product2.Family && item.Product2.Family.indexOf(QW.CONSTANTS.PRODUCT2.FAMILY.MINUTES_BUNDLE) > -1
            || QW.CONSTANTS.PRODUCT2.PRODUCT_TYPE.SESSIONS_BUNDLE === item.Product2.Product_Type__c
            || QW.CONSTANTS.PRODUCT2.PRODUCT_TYPE.CALLS_BUNDLE === item.Product2.Product_Type__c
            || QW.CONSTANTS.PRODUCT2.PRODUCT_TYPE.ENGAGEMENT_BUNDLE === item.Product2.Product_Type__c
            || QW.CONSTANTS.PRODUCT2.PRODUCT_TYPE.MESSAGES_BUNDLE === item.Product2.Product_Type__c;
    },

    isRCMinutesBundle24: function(item) {
        return item.Product2.Feature__c === 24;
    },

    isRCMinutesBundle52: function(item) {
        return item.Product2.Feature__c === 52;
    },

    isRCMinutesBundle56: function(item) {
        return item.Product2.Feature__c === 56;
    },

    isRCMinutesBundle59: function(item) {
        return item.Product2.Feature__c === 59;
    },

    isRCMinutesBundle36: function(item) {
        return item.Product2.Feature__c === 36;
    },

    isSeat: function(item) {
        return item.Product2.Product_Type__c === QW.CONSTANTS.PRODUCT2.PRODUCT_TYPE.SEAT
            && item.Product2.Family === QW.CONSTANTS.PRODUCT2.FAMILY.CC_SERVICE;
    },

    isOverage: function(item) {
        return (item.Product2.Family === QW.CONSTANTS.PRODUCT2.FAMILY.OVERAGE);
    },

    isOverageWithTheSameName: function(item, item2) {
        var result = this.isOverage(item);

        if(item2) result = (result && item.Product2.Name === item2.Product2.Name && item.Product2.Id !== item2.Product2.Id);

        return result;
    },

    isContactCenter: function(item) {
        return item.Product2.Sub_Category__c === QW.CONSTANTS.QUOTE.PRODUCTS.CONTACT_CENTER
            || item.Product2.Sub_Category__c === QW.CONSTANTS.QUOTE.PRODUCTS.RC_CONTACT_CENTER;
    },

    isActive: function(item) {
        return !item.Deactivated__c;
    },

    /*
     * Activate or deactivate CC items
     */
    checkContactCenter: function(cartItems, itemsForUpdate) {
        var helper = this;
        var activeSeat;

        // Determine status of Seat
        var hasActiveSeat = false;
        cartItems.forEach(function(item) {
            if( helper.isSeat(item) && helper.isActive(item) ) {
                activeSeat = item;
                hasActiveSeat = true;
            }
        });

        // Find all CC items with entitlements exclude Seat
        cartItems.forEach(function(item) {
            if( helper.isContactCenter(item) && !helper.isSeat(item) && item.Entitlement__r) {

                // Activate
                if(hasActiveSeat && item.BillingStatus__c === 'Cancelled' && item.Product2.Sub_Category__c === activeSeat.Product2.Sub_Category__c) {
                    item.Disabled__c = false;
                    item.Deactivated__c = false;
                    item.Zero_Quantity__c = true;
                    item.BillingStatus__c = 'Active';
                    item.Quantity = 1;

                    itemsForUpdate[item.Id] = item;
                }
                // Deactivate
                else if(!hasActiveSeat && item.BillingStatus__c !== 'Cancelled') {

                    item.Disabled__c = true;
                    item.Deactivated__c = true;
                    item.Zero_Quantity__c = false;
                    item.Quantity = -item.Entitlement__r.Quantity__c;
                    item.BillingStatus__c = 'Cancelled';

                    if(helper.isOverage(item)) {
                        item.Quantity = 1;
                        item.Zero_Quantity__c = true;
                    }

                    itemsForUpdate[item.Id] = item;
                }

            }
        });

        return itemsForUpdate;
    },

    deactivateEntitlement: function(itemC1, itemC2, itemsForUpdate) {
        var deactivator;

        itemC2.Disabled__c = true;
        itemC2.Deactivated__c = true;
        itemC2.Quantity = -itemC2.Entitlement__r.Quantity__c;
        itemC2.BillingStatus__c='Replaced';
        itemC2.NewQuantity__c = 0;
        itemC2.Zero_Quantity__c = false;

        var ent = {
            Price__c: itemC2.UnitPrice,
            Discount__c: itemC2.Discount_number__c,
            Discount_Type__c: itemC2.Discount_Type__c
        };
        var qty = itemC2.Quantity;

        itemC2.Subtotal = this.getSubtotal(ent, qty);
        itemC2.TotalPrice = this.getTotalPrice(ent, qty);

        if (this.isOverage(itemC2)) {
            itemC2.Quantity = 1;
            itemC2.Zero_Quantity__c = true;

            deactivator = itemsForUpdate['deactivator'];
        } else {
            deactivator = itemsForUpdate['deactivator'] || itemC1;
        }

        if (deactivator) {
            deactivator.DeactivatedItemsByQli__c = deactivator.DeactivatedItemsByQli__c ? (deactivator.DeactivatedItemsByQli__c += ','+itemC2.Id) : (itemC2.Id);
            itemsForUpdate['deactivator'] = deactivator;
        }

        itemsForUpdate[itemC2.Id] = itemC2;
    },

    handleCCUpgradableBundle: function(cartItems, itemsForUpdate) {
        var helper = this;

        cartItems.forEach(function(itemC1) {
            if (!itemC1.Entitlement__r && helper.isCCUpgradableBundleItem(itemC1)) {
                cartItems.forEach(function(itemC2) {
                    // Active Item with Entitlement
                    if ((itemC1.Id !== itemC2.Id && !itemC2.Disabled__c || !itemC2.Deactivated__c) && itemC2.Entitlement__r && helper.isCCUpgradableBundle(itemC2, itemC1)) {
                        helper.deactivateEntitlement(itemC1, itemC2, itemsForUpdate);
                    }
                })
            }
        });
        cartItems.forEach(function(item) {
            if (item.Entitlement__r && helper.getCCAmeliaVoiceAddOnVolume(item) && item.Product2.Family !== 'Overage' && item.NewQuantity__c === 0 && item.BillingStatus__c !== 'Cancelled') {
                item.Deactivated__c = true;
                item.BillingStatus__c = 'Cancelled';
                item.Quantity = -item.Entitlement__r.DisplayQuantity__c;
                item.Zero_Quantity__c = item.Quantity === 0;
                item.TotalPrice = item.Quantity * item.UnitPrice;
                cartItems.forEach(function(item) {
                    if (item.Entitlement__r && item.Product2.Product_Type__c === 'Calls Bundle' && item.Product2.Family === 'Overage' && item.BillingStatus__c !== 'Cancelled') {
                        item.Deactivated__c = true;
                        item.BillingStatus__c = 'Cancelled';
                        item.Threshold__c = -item.Entitlement__r.DisplayQuantity__c;
                        item.TotalPrice = item.Threshold__c * item.UnitPrice;
                    }
                });
            }
        });
        helper.updateAmeliaTTSNewQuantity(cartItems);
    },

    updateAmeliaTTSNewQuantity: function(cartItems) {

        var helper = this;
        var ameliaTTS;
        var ameliaTTSOverage;
        var ameliaCallsExistingQty = 0;
        var ameliaCallsNewQuantity = 0;
        cartItems.forEach(function(item) {
            if (helper.getCCAmeliaVoiceAddOnVolume(item)) {
                if (!item.Deactivated__c) {
                    ameliaCallsNewQuantity = helper.getCCAmeliaVoiceAddOnVolume(item);
                }
            }
            if (QW.Product2Helper.isAmeliaTTS(item.Product2)) {
                if (item.Product2.Family === 'Overage') {
                    ameliaTTSOverage = item;
                } else {
                    ameliaTTS = item;
                    ameliaCallsExistingQty = item.Entitlement__r ? item.Entitlement__r.DisplayQuantity__c : 0;
                }
            }
        });
        if (ameliaTTS && ameliaTTSOverage) {
            cartItems.forEach(function(item) {
                if (item.Id === ameliaTTS.Id) {
                    item.NewQuantity__c = ameliaCallsNewQuantity;
                    item.Quantity = ameliaCallsNewQuantity - ameliaCallsExistingQty;
                    item.Zero_Quantity__c = false;
                    item.TotalPrice = item.Quantity * item.UnitPrice;
                    if (item.Quantity === 0) {
                        helper.returnDeactivatedItem(item);
                    }
                    if (ameliaCallsNewQuantity === 0) {
                        item.Deactivated__c = true;
                        item.BillingStatus__c = 'Cancelled';
                        item.TotalPrice = item.Quantity * item.UnitPrice;
                    }
                } else if (item.Id === ameliaTTSOverage.Id) {
                    item.Threshold__c = ameliaCallsNewQuantity - ameliaCallsExistingQty;
                    item.TotalPrice = item.Threshold__c * item.UnitPrice;
                    if (item.Threshold__c === 0) {
                        helper.returnDeactivatedItem(item);
                    }
                    if (ameliaCallsNewQuantity === 0) {
                        item.Deactivated__c = true;
                        item.BillingStatus__c = 'Cancelled';
                        item.TotalPrice = item.Threshold__c * item.UnitPrice;
                    }
                }
            });
        }
    },

    handleSeat: function(cartItems, itemsForUpdate) {
        var helper = this;

        cartItems.forEach(function(itemC1) {
            if (!itemC1.Entitlement__r && helper.isSeat(itemC1)) {
                cartItems.forEach(function(itemC2) {
                    // Active Item with Entitlement
                    if ((itemC1.Id !== itemC2.Id && !itemC2.Disabled__c || !itemC2.Deactivated__c) && itemC2.Entitlement__r && helper.isSeat(itemC2)) {
                        helper.deactivateEntitlement(itemC1, itemC2, itemsForUpdate);
                    }
                })
            }
        });
        return itemsForUpdate;
    },

    handleOverageWithTheSameName: function(cartItems, itemsForUpdate) {
        var helper = this;

        cartItems.forEach(function(itemC1) {
            if (!itemC1.Entitlement__r && helper.isOverageWithTheSameName(itemC1)) {
                cartItems.forEach(function(itemC2) {
                    // Active Item with Entitlement
                    if ((itemC1.Id !== itemC2.Id && !itemC2.Disabled__c || !itemC2.Deactivated__c) && itemC2.Entitlement__r && helper.isOverageWithTheSameName(itemC2, itemC1)) {
                        helper.deactivateEntitlement(itemC1, itemC2, itemsForUpdate);
                    }
                })
            }
        });
        return itemsForUpdate;
    },

    handleRCMinutesBundle24: function(cartItems, itemsForUpdate) {
        var helper = this;

        cartItems.forEach(function(itemC1) {
            if (!itemC1.Entitlement__r && helper.isRCMinutesBundle24(itemC1)) {
                cartItems.forEach(function(itemC2) {
                    // Active Item with Entitlement
                    if ((itemC1.Id !== itemC2.Id && !itemC2.Disabled__c || !itemC2.Deactivated__c) && itemC2.Entitlement__r && helper.isRCMinutesBundle24(itemC2)) {
                        helper.deactivateEntitlement(itemC1, itemC2, itemsForUpdate);
                    }
                })
            }
        });
        return itemsForUpdate;
    },

    handleRCMinutesBundle59: function(cartItems, itemsForUpdate) {
        var helper = this;

        cartItems.forEach(function(itemC1) {
            if (!itemC1.Entitlement__r && helper.isRCMinutesBundle59(itemC1)) {
                cartItems.forEach(function(itemC2) {
                    // Active Item with Entitlement
                    if ((itemC1.Id !== itemC2.Id && !itemC2.Disabled__c || !itemC2.Deactivated__c) && itemC2.Entitlement__r && helper.isRCMinutesBundle59(itemC2)) {
                        helper.deactivateEntitlement(itemC1, itemC2, itemsForUpdate);
                    }
                })
            }
        });
        return itemsForUpdate;
    },

    handleRCMinutesBundle36: function(cartItems, itemsForUpdate) {
        var helper = this;

        cartItems.forEach(function(itemC1) {
            if (!itemC1.Entitlement__r && helper.isRCMinutesBundle36(itemC1)) {
                cartItems.forEach(function(itemC2) {
                    // Active Item with Entitlement
                    if ((itemC1.Id !== itemC2.Id && !itemC2.Disabled__c || !itemC2.Deactivated__c) && itemC2.Entitlement__r && helper.isRCMinutesBundle36(itemC2)) {
                        helper.deactivateEntitlement(itemC1, itemC2, itemsForUpdate);
                    }
                })
            }
        });
        return itemsForUpdate;
    },

    returnDeactivatedItem: function(deactivatedItem){
        deactivatedItem.Disabled__c = false;
        deactivatedItem.Deactivated__c = false;
        deactivatedItem.Zero_Quantity__c = true;
        deactivatedItem.BillingStatus__c = 'Active';
        deactivatedItem.Quantity = 1;
        deactivatedItem.NewQuantity__c = deactivatedItem.Entitlement__r ? deactivatedItem.Entitlement__r.DisplayQuantity__c : 1;
        return deactivatedItem;
    },

    handleCCUpgradableBundleDeletion: function(cartItems, params) {
        var helper = this;
        var itemsForUpdate = {};
        if (!params.qli.Deactivated__c && this.isCCUpgradableBundleItem(params.qli)) {
            var deactivatedItem;
            var deactivatedItemsIdList = [];
            if (params && params.qli && params.qli.DeactivatedItemsByQli__c) deactivatedItemsIdList = params.qli.DeactivatedItemsByQli__c.split(',');
            for (var i = deactivatedItemsIdList.length-1; i >= 0; i--) {
                deactivatedItem = _.find(cartItems, function(cartItem) { return (cartItem.Id === deactivatedItemsIdList[i]) });
                if (deactivatedItem.Entitlement__r &&
                    // Check for activate items satisfying conditions;
                    (this.isCCUpgradableBundleItem(deactivatedItem) ||
                    // Check for activate overages
                    (this.isOverage(deactivatedItem) && this.isSeat(params.qli)))
                ) {
                    itemsForUpdate[deactivatedItem.Id] = this.returnDeactivatedItem(deactivatedItem);
                }
            }
        }
        helper.updateAmeliaTTSNewQuantity(cartItems);
        return itemsForUpdate;
    },

    handleSeatDeletion: function(cartItems, params) {
        var itemsForUpdate = {};
        if (!params.qli.Deactivated__c && this.isSeat(params.qli)) {
            var deactivatedItem;
            var deactivatedItemsIdList = [];
            if (params && params.qli && params.qli.DeactivatedItemsByQli__c) deactivatedItemsIdList = params.qli.DeactivatedItemsByQli__c.split(',');
            for (var i = deactivatedItemsIdList.length-1; i >= 0; i--) {
                deactivatedItem = _.find(cartItems, function(cartItem) { return (cartItem.Id === deactivatedItemsIdList[i]) });
                if (deactivatedItem.Entitlement__r &&
                    // Check for activate items satisfying conditions;
                    (this.isSeat(deactivatedItem) ||
                    // Check for activate overages
                    (this.isOverage(deactivatedItem) && this.isSeat(params.qli)))
                ) {
                    itemsForUpdate[deactivatedItem.Id] = returnDeactivatedItem(deactivatedItem);
                }
            }
        }
        return itemsForUpdate;
    },

    handleOverageWithTheSameNameDeletion: function(cartItems, params) {
        var itemsForUpdate = {};
        if (!params.qli.Deactivated__c && this.isOverageWithTheSameName(params.qli)) {
            var deactivatedItem;
            var deactivatedItemsIdList = [];
            if (params && params.qli && params.qli.DeactivatedItemsByQli__c) deactivatedItemsIdList = params.qli.DeactivatedItemsByQli__c.split(',');
            for (var i = deactivatedItemsIdList.length-1; i >= 0; i--) {
                deactivatedItem = _.find(cartItems, function(cartItem) { return (cartItem.Id === deactivatedItemsIdList[i]) });
                if (deactivatedItem.Entitlement__r &&
                    // Check for activate items satisfying conditions;
                    (this.isOverageWithTheSameName(deactivatedItem) ||
                    // Check for activate overages
                    (this.isOverage(deactivatedItem) && this.isSeat(params.qli)))
                ) {
                    itemsForUpdate[deactivatedItem.Id] = returnDeactivatedItem(deactivatedItem);
                }
            }
        }
        return itemsForUpdate;
    },

    handleRCMinutesBundle24Deletion: function(cartItems, params) {
        var itemsForUpdate = {};
        if (!params.qli.Deactivated__c && this.isRCMinutesBundle24(params.qli)) {
            var deactivatedItem;
            var deactivatedItemsIdList = [];
            if (params && params.qli && params.qli.DeactivatedItemsByQli__c) deactivatedItemsIdList = params.qli.DeactivatedItemsByQli__c.split(',');
            for (var i = deactivatedItemsIdList.length-1; i >= 0; i--) {
                deactivatedItem = _.find(cartItems, function(cartItem) { return (cartItem.Id === deactivatedItemsIdList[i]) });
                if (deactivatedItem.Entitlement__r &&
                    // Check for activate items satisfying conditions;
                    (this.isRCMinutesBundle24(deactivatedItem) ||
                    // Check for activate overages
                    (this.isOverage(deactivatedItem) && this.isSeat(params.qli)))
                ) {
                    itemsForUpdate[deactivatedItem.Id] = this.returnDeactivatedItem(deactivatedItem);
                }
            }
        }
        return itemsForUpdate;
    },

    handleRCMinutesBundle36Deletion: function(cartItems, params) {
        var itemsForUpdate = {};
        if (!params.qli.Deactivated__c && this.isRCMinutesBundle36(params.qli)) {
            var deactivatedItem;
            var deactivatedItemsIdList = [];
            if (params && params.qli && params.qli.DeactivatedItemsByQli__c) deactivatedItemsIdList = params.qli.DeactivatedItemsByQli__c.split(',');
            for (var i = deactivatedItemsIdList.length-1; i >= 0; i--) {
                deactivatedItem = _.find(cartItems, function(cartItem) { return (cartItem.Id === deactivatedItemsIdList[i]) });
                if (deactivatedItem.Entitlement__r &&
                    // Check for activate items satisfying conditions;
                    (this.isRCMinutesBundle36(deactivatedItem) ||
                    // Check for activate overages
                    (this.isOverage(deactivatedItem) && this.isSeat(params.qli)))
                ) {
                    itemsForUpdate[deactivatedItem.Id] = this.returnDeactivatedItem(deactivatedItem);
                }
            }
        }
        return itemsForUpdate;
    },

    handleRCMinutesBundle59Deletion: function(cartItems, params) {
        var itemsForUpdate = {};
        if (!params.qli.Deactivated__c && this.isRCMinutesBundle59(params.qli)) {
            var deactivatedItem;
            var deactivatedItemsIdList = [];
            if (params && params.qli && params.qli.DeactivatedItemsByQli__c) deactivatedItemsIdList = params.qli.DeactivatedItemsByQli__c.split(',');
            for (var i = deactivatedItemsIdList.length-1; i >= 0; i--) {
                deactivatedItem = _.find(cartItems, function(cartItem) { return (cartItem.Id === deactivatedItemsIdList[i]) });
                if (deactivatedItem.Entitlement__r &&
                    // Check for activate items satisfying conditions;
                    (this.isRCMinutesBundle59(deactivatedItem) ||
                    // Check for activate overages
                    (this.isOverage(deactivatedItem) && this.isSeat(params.qli)))
                ) {
                    itemsForUpdate[deactivatedItem.Id] = this.returnDeactivatedItem(deactivatedItem);
                }
            }
        }
        return itemsForUpdate;
    },

    updateItems: function(component, actions, params) {
        var cartItems = component.get('v.cartItems');
        if (!cartItems || !cartItems.length) return;

        var helper = this;
        var itemsForUpdate = {};

        // CHANGE ITEM
        if (actions.indexOf('change') > -1) {
            itemsForUpdate = helper.checkContactCenter(cartItems, itemsForUpdate);
            this.handleCCUpgradableBundle(cartItems, itemsForUpdate);
            this.handleSeat(cartItems, itemsForUpdate);
            this.handleOverageWithTheSameName(cartItems, itemsForUpdate);
            this.handleRCMinutesBundle24(cartItems, itemsForUpdate);
            this.handleRCMinutesBundle59(cartItems, itemsForUpdate);
            this.handleRCMinutesBundle36(cartItems, itemsForUpdate);
        }
        // END CHANGE ITEM

        // DELETE ITEM
        if (actions.indexOf('deleted') > -1) {
            Object.assign(itemsForUpdate,
                this.handleCCUpgradableBundleDeletion(cartItems, params),
                this.handleSeatDeletion(cartItems, params),
                this.handleOverageWithTheSameNameDeletion(cartItems, params),
                this.handleRCMinutesBundle24Deletion(cartItems, params),
                this.handleRCMinutesBundle59Deletion(cartItems, params),
                this.handleRCMinutesBundle36Deletion(cartItems, params)
            );
        }
        // END DELETE ITEM

        // Update List of QLI
        itemsForUpdate = _.values(itemsForUpdate);
        if (itemsForUpdate.length) {
            return helper.updateListQli(component, itemsForUpdate);
        }

        return Promise.resolve();
    },

    /**
     * Show toast notification
     * @param {string} headerText
     * @param {string} message
     * @param {string} theme
     * @param {boolean} [defaultTimeout]
     */
    showToast: function(headerText, message, theme, defaultTimeout) {
        $A.get("e.c:ToastEvent").setParams({
            theme: theme,
            header: headerText,
            details: message,
            defaultTimeout: defaultTimeout
        }).fire();
    },

    // Validation on Charge Term Plan
    isMonthly: function(qli) {
        var chargeTerm = qli.Product2.Charge_Term__c.toLowerCase();
        return (chargeTerm === 'monthly');
    },

    isMonthlyContract: function(qli) {
        var chargeTerm = qli.Product2.Charge_Term__c.toLowerCase();
        return (chargeTerm === 'monthly - contract');
    },

    isAnnual: function(qli) {
        var chargeTerm = qli.Product2.Charge_Term__c.toLowerCase();
        return (chargeTerm === 'annual');
    },

    isOneTime: function(qli) {
        var chargeTerm = qli.Product2.Charge_Term__c.toLowerCase();
        return (chargeTerm === 'one - time');
    },

    isProServ: function(qli) {
        var family = qli.Product2.Family.toLowerCase();
        return (family === 'proserv');
    },

    isTaxes: function(qli) {
        var family = qli.Product2.Family.toLowerCase();
        return (family === 'taxes');
    },

    // Get Values for Quote
    getProServOneTime: function(qli) {
        var result = 0;
        var totalInitialPrice = Number(qli.TotalPrice); //TotalInitialPrice__c

        if (this.isProServ(qli) && this.isOneTime(qli)) {
            result = totalInitialPrice;
        }

        return result;
    },

    getMonthlyRecurringRevenue: function(qli) {
        var result = 0;
        var totalPrice = Number(qli.TotalPrice);

        if(!qli.Zero_Quantity__c) {
            // For Monthly / Monthly Contract
            if( (this.isMonthly(qli) || this.isMonthlyContract(qli)) && !this.isTaxes(qli) ) {
                result = totalPrice;
            }

            // For Annual
            if(this.isAnnual(qli) && !this.isTaxes(qli)) {
                result = totalPrice / 12;
            }
        }

        return result;
    },

    getFirstYearTotalCost: function(qli) {
        var result = 0;
        var totalPrice = Number(qli.TotalPrice);

        if(!qli.Zero_Quantity__c) {
            // For Monthly
            if(this.isMonthly(qli) || this.isMonthlyContract(qli)) {
                result = totalPrice * 12;
            } else {
                // For Other
                result = totalPrice;
            }
        }

        return result;
    },

    getFirstYearTotalCostExcludingTaxes: function(qli) {
        var result = 0;
        var totalPrice = Number(qli.TotalPrice);

        if(!this.isTaxes(qli) && !qli.Zero_Quantity__c) {
            if(this.isMonthly(qli) || this.isMonthlyContract(qli)) {
                result = totalPrice * 12;
            } else {
                result = totalPrice;
            }
        }

        return result;
    },

    getFirstYearDiscount: function(qli) {
        var result = 0;
        var totalPrice = Number(qli.TotalPrice);
        var subtotal = Number(qli.Subtotal);

        if(!qli.Zero_Quantity__c) {
            if(this.isMonthly(qli) || this.isMonthlyContract(qli)) {
                result = (subtotal - totalPrice) * 12;
            } else {
                result = subtotal - totalPrice;
            }
        }

        return result;
    },

    getQuoteTotalValuesForItems: function(component, quote, items) {
        var helper = this;

        if(quote && items && items.length === 0) {
            // if we have not QuoteLineItems in cart - set 0's in totals
            helper.updateTotals(component, null);
        }
        if( !quote || !items || !items.length ) {
            return;
        }

        var params = {
            quoteId: quote.Id,
            items: items
        };

        return QW.salesforce.request(component, 'c.getQuoteTotalValues', params)
            .then($A.getCallback(function(quoteWithUpdatedTotals) {

                helper.updateTotals(component, quoteWithUpdatedTotals);

            }))
            .catch($A.getCallback(function(error) {
                console.error(error);
                helper.showToast('Update Quote Error', QW.salesforce.getResponseError(error), 'error');
            }));
    },

    groupUnmatchedCartItems: function(component, items, groupingList, options) {
        var helper = this;
        var newUnmatchedItems = [];

        var group = helper.getItemsWithoutGroup('previouslySold', items, groupingList, options);
        if(group.items.length) {
            group.label = 'Previously Sold One-Time Phones';
            group.isGrouped = true;

            newUnmatchedItems.push(group);
        }

        return newUnmatchedItems;
    },

    groupCartItems: function(component, items, groupingList, options) {
        var helper = this;
        var newItems = [];

        // Without grouping;
        var group = helper.getItemsWithoutGroup('all', items, groupingList, options);
        if( group.items.length ) newItems.push( group );

        // Grouped Items;
        groupingList.forEach(function(group) {
            var group = helper.getItemsWithGroup(items, group, options);
            if( group.items.length ) newItems.push( group );
        });

        return newItems;
    },

    getItemsWithoutGroup: function(groupName, items, groupingList, options) {
        var result = {
            name: groupName,
            label: null,
            items: [],
            isGrouped: false,
            expanded: null,
            options: options
        };
        var isGroupedItem;

        items.forEach(function(item) {
            isGroupedItem = false;
            groupingList.forEach(function(group) {
                if(item.Product2[group.field] === group.value) isGroupedItem = true;
            });

            if(!isGroupedItem) result.items.push(item);
        });

        return result;
    },

    getItemsWithGroup: function(items, group, options) {
        var result = {
            name: group.value,
            label: group.label,
            items: [],
            isGrouped: true,
            expanded: group.expanded,
            options: options
        };

        items.forEach(function(item) {
            if(item.Product2[group.field] === group.value) result.items.push(item);
        });

        return result;
    },

    /**
     * Delete Area Code List Entry from SF
     * @param component
     * @param areaCodeItem
     */
    deleteAreaCodeListEntry: function(component, areaCodeItem){

        var helper = this;
        var state = component.get('v.state');
        var deletingAreaCodeItems = component.get('v.deletingAreaCodeItems');
        var isItemHasId = !!areaCodeItem.Id;
        deletingAreaCodeItems.add(areaCodeItem.guid);
        component.set('v.deletingAreaCodeItems', deletingAreaCodeItems);

        var deleteACLIProcess = Promise.resolve();

        if (isItemHasId) {
            var areaCodes = component.get('v.areaCodeItems');
            var numberOfAreaCodes = areaCodes.filter(ac => ac.Quote_Line_Item__c === areaCodeItem.Quote_Line_Item__c).length;

            var shouldRemoveTaxes = (numberOfAreaCodes > 1) || (areaCodeItem.Quantity__c > 1);

            // Remove Taxes
            if (state.isTaxesInCart && shouldRemoveTaxes) {
                QW.spinner.show('Removing taxes');
                deleteACLIProcess = deleteACLIProcess.then($A.getCallback(function () {
                    return QW.salesforce.request(component, 'c.removeTaxes', {quoteId: component.get('v.quote.Id')});
                }));
            }

            QW.spinner.hide();
            deleteACLIProcess = deleteACLIProcess.then($A.getCallback(function () {
                    return QW.salesforce.request(component, 'c.deleteAreaCodeItem', { areaCodeItemId: areaCodeItem.Id });
                }));
        }
        deleteACLIProcess = deleteACLIProcess.then($A.getCallback(function () {
                helper.destroyAreaCodeListEntry(component, areaCodeItem);
            }))
            // Catch Errors
            .catch($A.getCallback(function (error) {

                console.error(error);
                helper.showToast('Failed to delete Area Code List Entry', QW.salesforce.getResponseError(error), 'error', false);

            }));
        // Refresh cart if item was saved in salesforce
        if (isItemHasId) {
            deleteACLIProcess = deleteACLIProcess.then($A.getCallback(function () {
                    var isSkipAreaCodesRefresh = true;
                    return helper.refreshCart(component, isSkipAreaCodesRefresh);
                }));
        }
        // Item is no longer deleting
        deleteACLIProcess = deleteACLIProcess.then($A.getCallback(function () {
                var deletingAreaCodeItems = component.get('v.deletingAreaCodeItems');
                deletingAreaCodeItems.delete(areaCodeItem.guid);
                component.set('v.deletingAreaCodeItems', deletingAreaCodeItems);
                if (isItemHasId && deletingAreaCodeItems.size === 0){
                    // refresh quote
                    $A.get("e.c:QuotingToolRefreshQuoteEvent").fire();
                }
            }));

        return deleteACLIProcess;
    },
    /**
     * Remove Area Code List Entry from layout
     */
    destroyAreaCodeListEntry: function(component, areaCodeItem){
        function returnGuid(item){
            return item.guid;
        }

        var areaCodeItemsInOperation = component.get('v.areaCodeItemsInOperation');

        var areaCodeItemInOperationIndex = areaCodeItemsInOperation.map(returnGuid).indexOf(areaCodeItem.guid);

        areaCodeItemsInOperation.splice(areaCodeItemInOperationIndex, 1);

        if (areaCodeItem.Id){
            var areaCodeItems = component.get('v.areaCodeItems');
            var areaCodeItemIndex = areaCodeItems.map(returnGuid).indexOf(areaCodeItem.guid);
            areaCodeItems.splice(areaCodeItemIndex, 1);
            component.set('v.areaCodeItems',areaCodeItems);
        }

        component.set('v.areaCodeItemsInOperation',areaCodeItemsInOperation);
    },
    /**
     *
     * @param component
     * @param areaCodeItems
     */
    setAreaCodeItems: function(component, areaCodeItems){
        var areaCodeItemsWGUID = areaCodeItems.map(function(item){
            item.guid = QW.uuidv4();
            return item;
        });
        component.set('v.areaCodeItems', areaCodeItemsWGUID);
    },
    /**
     * Check if user tries to change quantity of Quote Line Items that are assigned to Phases
     * Shows modal window if any assignments are going to be deleted
     * @param component
     */
    checkPhaseLineItemsOnChange: function(component){
        const Wizard = component.get('v.Wizard');
        const quoteLineItems = this.getCartItems(component);
        if (!Wizard.currentQuote
            || !Wizard.currentQuote.isPhaseManagementEnabled)
            return true;

        let showMessage = false;

        const tableArr = [];
        const phaseLineItemIdsToDelete = [];

        // Check Assignment and build Table array
        quoteLineItems.forEach(quoteLineItem => {
            const cartItem = Wizard.currentQuote.getCartItem(quoteLineItem.Id);
            if (!cartItem) return;

            if (cartItem.record.Quantity > quoteLineItem.Quantity
                && cartItem.phases.length > 0
                && cartItem.assignedToPhaseQuantity > quoteLineItem.Quantity){
                showMessage = true;

                // Build table array
                tableArr.push([ cartItem.record.Product2.Name, QW.pluralize('Phase', cartItem.phases.length, true) ]);

                // Add phaseLine Items To Delete
                cartItem.phases.forEach(function (phase) {
                    phase.phaseLineItems.forEach(function (phaseLineItem) {
                        phaseLineItemIdsToDelete.push(phaseLineItem.record.Id);
                    })
                });
            }
        });

        // Create HTML table from array
        const tableHTML = QW.htmlUtils.createTable(tableArr);
        tableHTML.setAttribute("class", "slds-table slds-table--bordered slds-no-row-hover");

        if (!showMessage)
            return true;

        const text = '<p class="slds-m-bottom--small">You are about to decrease quantity of items that are assigned to phases.</p>';

        $A.get("e.c:ModalRequestEvent").setParams({
            guid: 'deletePLIsBeforeCartSave',
            header: 'Following Phase assignments will be deleted',
            content: text + tableHTML.outerHTML,
            params: {
                phaseLineItemIdsToDelete
            },
            buttons: [{
                label: 'Ok',
                name: 'ok',
                variant: 'brand'
            }]
        }).fire();
    },
    /**
     * Check if deleted item is assigned to Phases
     * @param component              {object}
     * @param quoteLineItemToDelete  {object} QuoteLineItem
     */
    checkPhaseLineItemsOnDelete: function(component, quoteLineItemToDelete){
        var Wizard = component.get('v.Wizard');
        if (!Wizard.currentQuote
            || !Wizard.currentQuote.isPhaseManagementEnabled)
            return true;

        var showMessage = false;
        var phaseLineItemIdsToDelete = [];
        var tableArr = [];

        var cartItem = Wizard.currentQuote.getCartItem(quoteLineItemToDelete.Id);

        // If cart Item assigned to phases
        if (cartItem.phases.length > 0){
            showMessage = true;
            tableArr.push([
                cartItem.record.Product2.Name,
                QW.pluralize('Phase', cartItem.phases.length, true)
            ]);

            // Add phaseLine Items To Delete
            cartItem.phases.forEach(function (phase) {
                phase.phaseLineItems.forEach(function (phaseLineItem) {
                    phaseLineItemIdsToDelete.push(phaseLineItem.record.Id);
                })
            });
        }
        var tableHTML = QW.htmlUtils.createTable(tableArr);
        tableHTML.setAttribute("class", "slds-table slds-table--bordered slds-no-row-hover");

        if (!showMessage)
            return true;

        var text = '<p class="slds-m-bottom--small">You are about to delete item that is assigned to phases</p>';

        $A.get("e.c:ModalRequestEvent").setParams({
            guid: 'deletePLIsBeforeCartItemDelete',
            header: 'Following Phase assignments will be deleted',
            content: text + tableHTML.outerHTML,
            params: {
                phaseLineItemIdsToDelete: phaseLineItemIdsToDelete,
                quoteLineItemToDelete: quoteLineItemToDelete
            },
            buttons: [{
                label: 'Ok',
                name: 'ok',
                variant: 'brand'
            }]
        }).fire();
    },

    /**
     * B-3578 https://rc.my.salesforce.com/a203400000464Gi Extended enterprise support to match # of DLs
     * Check if Extended Enterprise Support product is in range of Account Service plan and
     * Add/Delete product automatically if it is not
     * @param component
     * @param isEnforceCheck
     * @returns {Promise|void}
     */
    fixExtendedEnterpriseSupport: function(component, isEnforceCheck) {

        var helper = this;
        var items = helper.getCartItems(component);
        var Wizard = component.get('v.Wizard');

        var settings = component.get('v.settings');
        var featureForEES = settings.featureForEES ? settings.featureForEES : 38;

        // Get Extended Enterprise Support (EES) QLI
        var EEScartItemsWithEnt = items.filter(function (qli) {
            return QW.Product2Helper.checkIsExtendedEnterpriseSupport(qli.Product2, featureForEES) &&
                !!qli.Entitlement__c;
        })[0];

        var EEScartItemsWithoutEnt = items.filter(function (qli) {
            return QW.Product2Helper.checkIsExtendedEnterpriseSupport(qli.Product2, featureForEES) &&
                !qli.Entitlement__c;
        })[0];

        if (!EEScartItemsWithEnt && !EEScartItemsWithoutEnt && !isEnforceCheck)
            return;

        if (!isEnforceCheck)
            QW.spinner.show('Checking Extended Enterprise Support');

        return QW.salesforce.request(component, 'c.handleExtendedEnterpriseSupport', {
            quoteId: Wizard.currentQuote.record.Id
        });
    },
    /**
     * Find and save for later use Service Plan QuoteLine Item
     * @param component
     */
    getServiceProduct: function(component){
        var cartItems = component.get('v.cartItems');

        var serviceCartItem = cartItems.filter(function(qli){
            return QW.Product2Helper.isServicePlan(qli.Product2);
        })[0];
        component.set('v.serviceCartItem',serviceCartItem);
    },
    /**
     * set v.isCartChanged attribute
     * @param component
     */
    setIsCartChanged: function(component){
        var isAreaCodesChanged = this.getUnsavedAreaCodes(component).length > 0;
        var isCartItemChanged = this.isCartItemChanged(component);
        component.set('v.isCartChanged', isAreaCodesChanged || isCartItemChanged);
    },
    /**
     * Check if there are any unsaved changes in the user cart items
     * @param component
     * @returns {boolean}
     */
    isCartItemChanged: function(component){
        var items = this.getCartItems(component);
        var isCartItemChanged = false;
        items.forEach(function(item){
            if (item.isChanged)
                isCartItemChanged = true;
        });
        return isCartItemChanged;
    },
    checkForQLIErrors: function(component){
        var items = this.getCartItems(component);
        var noErrors = true;
        items.forEach(function(item){
            if (item.hasErrors)
                noErrors = false;
        });
        return noErrors;
    },

    isSetEmpty: function(setToCheck) {
        return !setToCheck.size > 0;
    },
    getQLIWithDifferentSubCategory: function(items, prodSubCategory, CC_CATEGORIES){
        return items.find(item => {
            const itemSubCategory = item.Product2.Sub_Category__c;
            const isCCSubCategory = CC_CATEGORIES.indexOf(itemSubCategory) !== -1;
            const isOtherSubCategoryInCart = itemSubCategory !== prodSubCategory;
            return isCCSubCategory && isOtherSubCategoryInCart && !item.Deactivated__c;
        });
    },
    checkForSimilarProducts: function(component, newProduct) {
        var addingToCartProductsList = component.get('v.addingToCartProductsList');
        return addingToCartProductsList.find(product => {
            return product.Product2.Product_Type__c === newProduct.Product2.Product_Type__c;
        });
    },

    precreateAreaCode: function(component) {
        var freshItems = component.get('v.freshItems');
        var areacode = component.get('v.Wizard.currentQuote.record.AreaCode__r');
        var areaCodeId = component.get('v.Wizard.currentQuote.record.AreaCode__c');
        var areaCodeItemsInOperation = component.get('v.areaCodeItemsInOperation');

        freshItems.forEach(function(item) {

            var isPhoneRequireLocalAreaCode  = RC.Product2Helper.isDiscountedPhone(item.Product2)
                || RC.Product2Helper.isRentalPhone(item.Product2)
                || RC.Product2Helper.isRefurbishedPhone(item.Product2)
                || RC.Product2Helper.isAdditionaLocalNumber(item.Product2);
            var isPhoneRequireTollFreeAreaCode = RC.Product2Helper.isAdditionalTollFreeNumber(item.Product2);

            var isGlobalOfficeLimitedExtensionProduct = RC.Product2Helper.isGlobalOfficeLimitedExtensionProduct(item.Product2);

            var isMainAreaCodeLocal = RC.Product2Helper.isAreaCodeLocal(areacode);
            var isMainAreaCodeTollFree = RC.Product2Helper.isAreaCodeTollFree(areacode);

            if (!isGlobalOfficeLimitedExtensionProduct && (isMainAreaCodeLocal && isPhoneRequireLocalAreaCode
                || isMainAreaCodeTollFree && isPhoneRequireTollFreeAreaCode)) {
                var newAreaCode = {
                    sobjectType:        'Area_Code_Line_Item__c',
                    guid:               QW.uuidv4(),
                    Quantity__c:        item.Quantity,
                    Quote_Line_Item__c: item.Id,
                    Area_Code__c:        areaCodeId
                };
                areaCodeItemsInOperation.push(newAreaCode);
            }
        });
        component.set('v.areaCodeItemsInOperation', areaCodeItemsInOperation);

        return QW.salesforce.request(component, 'c.saveAreaCodeItems', {
                areaCodesToSave: component.get('v.areaCodeItemsInOperation')
            }).then(() => component.set('v.freshItems', []));
    },

    // Handle successful taxes request with unsuccessful statuses
    handleFailedResponse: function(res) {
        if (res) {
            const isTotalRespFailed = res.data.status !== 200;
            const isExistingRespFailed = res.data.existingTaxesStatus !== 200;
            const errorTitle =
                isTotalRespFailed
                ? 'Failed to add taxes'
                : 'Tax estimation might be incorrect';
            const errorMessage = res.data.message;
            const messageText =
                isTotalRespFailed
                ? errorMessage
                : (isExistingRespFailed
                    ?  `Taxes are calculated based on full new
                        Quantities of the items on the Quote.`
                    : null);
            const messageType =
                isExistingRespFailed
                ? 'warning'
                : (errorMessage === 'No taxes need to be added'
                    ? 'info'
                    : 'error');

            if (isTotalRespFailed || isExistingRespFailed) {
                this.showToast(
                    errorTitle,
                    messageText,
                    messageType
                );
            }
        }
    },

    // Handle successful taxes response
    handleErrorResponse: function(error, isSaveCart) {
        console.error(error);
        const errorMsg = QW.salesforce.getResponseError(error);
        const errorTitle =
            isSaveCart
            ? 'Failed to save Cart'
            : 'Failed to add taxes'
        const messageType =
            errorMsg === 'No taxes need to be added'
            ? 'info'
            : 'error';
        let messageBody = null;

        if (isSaveCart) {
            let errMessages = errorMsg.split("%%");

            errMessages.forEach(msg => {
                if (msg != '') {
                    const splitedMessage = msg.split("$$");
                    messageBody =
                        splitedMessage.length > 1
                        ? splitedMessage[1]
                        : splitedMessage[0];
                }
            });
        }

        this.showToast(
            errorTitle,
            (isSaveCart && messageBody
                ? messageBody
                : errorMsg),
            messageType,
            messageType !== 'error'
        );
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

	},

    computeTargetPriceContactCenterARR: function(item) {
        return this.roundToHundredth(
            item.UnitPrice
            * (item.NewQuantity__c || 1)
            * ((this.isMonthly(item) || this.isMonthlyContract(item))
                ? 12 : 1)
        );
    },

    roundToHundredth: function(number) {
        return number && Math.round(number * 100) / 100;
    }
});