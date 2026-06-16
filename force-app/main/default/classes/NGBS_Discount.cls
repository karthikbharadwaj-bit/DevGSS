public class NGBS_Discount {

    public NGBS_Discount() { }

    public static final String PRIORITY_KEY = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    public static final String NGBS_UTC_FORMAT = 'yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z[UTC]\'';
    public static final Integer DISCOUNT_START_DATE_OFFSET = -2;

    public static final String BILLING_DISCOUNT_TYPE_PERCENTAGE = 'Percent';
    public static final String BILLING_DISCOUNT_TYPE_CURRENCY = 'Money';

    public static Map<String, String> discountMappingToBilling = new Map<String, String>{
        QuoteLineItemHelper.DISCOUNT_TYPE_PERCENTAGE => BILLING_DISCOUNT_TYPE_PERCENTAGE,
        QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY => BILLING_DISCOUNT_TYPE_CURRENCY
    };

    public static Map<String, String> discountMappingToSFDC = new Map<String, String>{
        BILLING_DISCOUNT_TYPE_PERCENTAGE => QuoteLineItemHelper.DISCOUNT_TYPE_PERCENTAGE,
        BILLING_DISCOUNT_TYPE_CURRENCY => QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY
    };

    public static final String BILLING_CATEGORY_ID_TYPE = 'CategoryId';
    public static final String BILLING_CATALOG_ID_TYPE = 'CatalogId';

    public static Map<String, String> durationMapping = new Map<String, String>{
        Product2Helper.CHARGE_TERM_ONE_TIME => 'OneTime',
        'OneTime' => 'OneTime',
        Product2Helper.CHARGE_TERM_ANNUAL => 'Annual',
        Product2Helper.CHARGE_TERM_MONTHLY => 'Monthly',
        Product2Helper.CHARGE_TERM_QUATERLY => 'Quarterly',
        Product2Helper.CHARGE_TERM_SEMI_ANNUAL => 'SemiAnnual'
    };

    public static final String DIGITAL_LINE_UNLIMITED = 'LC_DL-UNL_50';
    public static final String DIGITAL_LINE_UNLIMITED_CATEGORY = 'DL-UNL';

    public static final String MOBILE_USER_NAME = 'Mobile User';
    public static final String MOBILE_USER_CATEGORY = 'MU';

    public static final String PACKAGE_MASTER_DURATION = 'PackageMasterDuration';
    public static final String LICENSE_DURATION = 'LicenseDuration';
    public static final String SHIPPING_CATEGORY = 'SHIPT';

    public static final String MU_ELA = 'MU ELA';

    public static final String ASCENDING = 'ASC';
    public static final String DESCENDING = 'DESC';
    public static String orderBy = ASCENDING;

    /*
        Use for build DiscountTemplateGroup for SignUp
        (without binding to billing account)
    */
    public static RootDiscountTemplateGroup createRootDiscountTemplateGroup(
        Quote qt,
        BillingWrappers.QuotePackageInfo quotePackageInfo,
        Contract__c accountContract,
        String priority
    ) {
        RootDiscountTemplateGroup result;

        List<DiscountItemWrapper> discountItemsList = getDiscountItemWrappersList(
            qt,
            accountContract,
            false,
            new List<DiscountTemplateGroup>(),
            true
        );
        Map<String, String> externalIdToBillingTypeMap = getExternalIdToBillingTypeMap(qt);

        /* create if exist */
        if (!discountItemsList.isEmpty()) {
            result = new RootDiscountTemplateGroup(
                qt,
                quotePackageInfo,
                discountItemsList,
                priority,
                externalIdToBillingTypeMap
            );
        }

        return result;
    }

    public static List<DiscountTemplateGroup> getUpdatedDtgList(
        Quote primaryQuote,
        BillingWrappers.QuotePackageInfo pInfo,
        Contract__c accountContract,
        List<BillingWrappers.BillingContract> billingContracts,
        List<DiscountTemplateGroup> filteredDTG,
        List<DiscountTemplateGroup> allDTG
    ) {

        List<DiscountTemplateGroup> dGroups = filteredDTG != null
            ? (List<NGBS_Discount.DiscountTemplateGroup>) JSON.deserialize(JSON.serialize(filteredDTG), List<NGBS_Discount.DiscountTemplateGroup>.class)
            : new List<DiscountTemplateGroup>();
        for (DiscountTemplateGroup dtg : dGroups) {
            dtg.id = null;
        }

        orderBy = ASCENDING;
        dGroups.sort();
        Boolean isNeedToCreateNewDTG = dGroups.isEmpty() || !isGroupAvailableForUpdate(dGroups.get(dGroups.size() - 1));
        List<String> priorities = getNextPriorities(allDTG, isNeedToCreateNewDTG ? dGroups.size() + 1 : dGroups.size());

        DiscountTemplateGroup discount = getMostPriorityDiscountTemplateGroup(
            primaryQuote,
            pInfo,
            accountContract,
            billingContracts,
            priorities.get(priorities.size()-1),
            dGroups,
            isNeedToCreateNewDTG
        );

        orderBy = ASCENDING;
        dGroups.sort();
        // add received most priority DTG to the existing DTG list
        if (discount != null) {
            if (!isNeedToCreateNewDTG) {
                dGroups.remove(dGroups.size() - 1);
            }
            dGroups.add(discount);
        }

        // set next priorities
        for (Integer i = 0; i < dGroups.size(); i++) {
            dGroups.get(i).priority = priorities.get(i);
        }

        return dGroups;
    }

    /*
        Use for build DiscountTemplateGroup for package
        (Prepare discounts with contract discounts)
    */
    @TestVisible
    private static DiscountTemplateGroup getMostPriorityDiscountTemplateGroup(
        Quote qt,
        BillingWrappers.QuotePackageInfo quotePackageInfo,
        Contract__c accountContract,
        List<BillingWrappers.BillingContract> billingContracts,
        String priority,
        List<DiscountTemplateGroup> dGroups,
        Boolean isNeedToCreateNewDTG
    ) {
        DiscountTemplateGroup result;
        List<DiscountItemWrapper> discountItemsList = getDiscountItemWrappersList(
            qt,
            accountContract,
            true,
            dGroups,
            isNeedToCreateNewDTG
        );
        Map<String, String> externalIdToBillingTypeMap = getExternalIdToBillingTypeMap(qt);

        /* create if exist */
        if (!discountItemsList.isEmpty()) {
            result = new DiscountTemplateGroup(
                qt.QuoteNumber,
                quotePackageInfo,
                discountItemsList,
                priority,
                billingContracts,
                externalIdToBillingTypeMap
            );
        }

        return result;
    }

    public static List<DiscountItemWrapper> getDiscountItemWrappersList(
        Quote qt,
        Contract__c accountContract,
        Boolean isValueTermRequired,
        List<DiscountTemplateGroup> dGroups,
        Boolean isNeedToCreateNewDTG
    ) {

        Map<String, DiscountItemWrapper> catalogToDiscountValue = new Map<String, DiscountItemWrapper>();

        orderBy = DESCENDING;
        dGroups.sort();

        BillingWrappers.QuotePackageInfo pInfo = QuoteHelper.getPackageInfo(qt);
        String chargeTerm = pInfo.duration;
        Boolean isNGBSPartnerPackageChange = QuoteHelper.isNGBSPartnerPackageChange(qt, qt.QuoteLineItems);

        Map<String, String> removingDiscountsCatalogToCategory = new Map<String, String>();

        catalogToDiscountValue.putAll(getShippingDiscountItems(qt));

        if (!isNeedToCreateNewDTG) {
            for(DiscountTemplate dt : dGroups.get(dGroups.size() - 1).discountTemplates ) {
                if (dt.applicableTo.type == BILLING_CATEGORY_ID_TYPE) {
                    continue;
                }
                DiscountItemWrapper item = new DiscountItemWrapper(
                    dt,
                    dt.applicableTo.type,
                    dt.applicableTo.id
                );
                catalogToDiscountValue.put(dt.applicableTo.id, item);
            }
        }

        for (QuoteLineItem qli : qt.QuoteLineItems) {
            BillingWrappers.QLIPackageInfo packageInfo = new BillingWrappers.QLIPackageInfo(qli.PackageInfo__c);
            String categoryId = packageInfo.categoryCode;
            String catalogId = qli.Product_Lic_Id__c;
            if (categoryId == null || catalogId == null || qli.ChargeTerm__c == null) {
                AquivaHelper.throwAquivaException(
                'An error occurred during synchronization: invalid quote line item' +
                ' Please contact administrator');
            }

            if (Product2Helper.isMobileUser(qli)
                || qli.Promotion__c != null
                || AccountHelper.isElaService(qt.Account) && qli.Product2.ExtID__c == DIGITAL_LINE_UNLIMITED) {
                continue;
            }

            Decimal value = applyContract(qli, accountContract);

            if (AccountHelper.isWholesaleAccount(qt.Account) || isNGBSPartnerPackageChange || isItemRemovedByUpgrade(qli, qt.Upsell_Status__c)) {
                value = qli.Discount_Number__c;
            }

            if (value == 0) {
                removeCatalogEntry(catalogToDiscountValue, removingDiscountsCatalogToCategory, catalogId, categoryId);
                continue;
            }

            DiscountTemplate activeDiscount;
            for (DiscountTemplateGroup dtg : dGroups) {
                if (activeDiscount != null) {
                    break;
                }
                for (DiscountTemplate dt : dtg.discountTemplates) {
                    DiscountValue mainApplication = dt.values.get(chargeTerm);
                    if (mainApplication != null && mainApplication.value != null
                        && (dt.applicableTo.id == catalogId || dt.applicableTo.id == categoryId)
                    ) {
                        activeDiscount = dt;
                        break;
                    }
                }
            }

            if (shouldNewDiscountBeCreatedFromQLI(qli, value, activeDiscount, chargeTerm, new List<String>(), false)) {
                Map<String, DiscountItemWrapper> discountItemsMap = createDiscountItemsFromQLI(qt, qli, value, pInfo, isValueTermRequired);
                catalogToDiscountValue.putAll(discountItemsMap);
            }
        }

        /* remove current discounts due to the reset of discounts on qli */
        for (DiscountTemplateGroup dtg : dGroups) {
            List<DiscountTemplate> updatedDiscountTemplates = new List<DiscountTemplate>();
            for (DiscountTemplate dt : dtg.discountTemplates) {
                DiscountValue mainApplication = dt.values.get(chargeTerm);
                if (mainApplication == null || mainApplication.value == null) {
                    updatedDiscountTemplates.add(dt);
                    continue;
                }
                if (!removingDiscountsCatalogToCategory.containsKey(dt.applicableTo.id)
                    && !removingDiscountsCatalogToCategory.values().contains(dt.applicableTo.id)
                ) {
                    updatedDiscountTemplates.add(dt);
                    continue;
                } else if (dt.applicableTo.type == BILLING_CATEGORY_ID_TYPE) {
                    for (QuoteLineItem qli : qt.QuoteLineItems) {
                        BillingWrappers.QLIPackageInfo packageInfo = new BillingWrappers.QLIPackageInfo(qli.PackageInfo__c);
                        String categoryId = packageInfo.categoryCode;
                        String catalogId = qli.Product_Lic_Id__c;

                        if (dt.applicableTo.id == categoryId
                            && !catalogToDiscountValue.containsKey(catalogId)
                            && !removingDiscountsCatalogToCategory.containsKey(catalogId)
                        ) {
                            DiscountItemWrapper item = new DiscountItemWrapper(
                                dt,
                                BILLING_CATALOG_ID_TYPE,
                                catalogId
                            );
                            catalogToDiscountValue.put(catalogId, item);
                        }
                    }
                }
            }
            dtg.discountTemplates = updatedDiscountTemplates;
        }

        return catalogToDiscountValue.values();
    }

    public static List<DiscountTemplateGroup> getMergedDtgList(
        Quote primaryQuote,
        Contract__c accountContract,
        List<BillingWrappers.BillingContract> billingContracts,
        List<DiscountTemplateGroup> filteredDTG,
        List<DiscountTemplateGroup> allDTG
    ) {
        List<DiscountTemplateGroup> mergedDiscountTemplateGroups = new List<DiscountTemplateGroup>();

        Map<String, List<DiscountTemplate>> newPriorityToDiscountsList = mergeDiscountTemplatesIntoNewPriorities(
            allDTG,
            filteredDTG,
            primaryQuote,
            accountContract,
            billingContracts
        );

        for (String priority : newPriorityToDiscountsList.keySet()) {
            if (newPriorityToDiscountsList.get(priority).isEmpty()) {
                continue;
            }
            DiscountTemplateGroup dtg = new DiscountTemplateGroup(
                primaryQuote.QuoteNumber,
                QuoteHelper.getPackageInfo(primaryQuote),
                newPriorityToDiscountsList.get(priority),
                priority,
                billingContracts,
                getExternalIdToBillingTypeMap(primaryQuote)
            );
            mergedDiscountTemplateGroups.add(dtg);
        }

        return mergedDiscountTemplateGroups;
    }

    private static Map<String, List<DiscountTemplate>> mergeDiscountTemplatesIntoNewPriorities(
        List<DiscountTemplateGroup> allDTG,
        List<DiscountTemplateGroup> filteredDTG,
        Quote primaryQuote,
        Contract__c accountContract,
        List<BillingWrappers.BillingContract> billingContracts
    ) {
        Map<String, List<DiscountTemplate>> newPriorityToDiscountsList = new Map<String, List<DiscountTemplate>>();

        /**
         * Current NGBS discounts should be merged into 3 new Discount Template Groups in the following way:
         * 1. If there are discounts with the same application id and different priorities,
         *    only the highest priority discount is saved in the 3rd (highest) priority DTG.
         * 2. If there is a catalog discount and no category discount for this catalog id,
         *    the discount goes to the 3rd priority DTG.
         * 3. If a category discount exists, all related catalog discounts are separated into the 1st (lowest) and 3rd (highest)
         *    priority DTGs based on their initial priority relative to the category's priority.
         *    The category discount goes to the 2nd priority DTG.
         */
        List<String> relativePriorities = new List<String>{'1', '2', '3'};
        List<DiscountTemplateFlatWrapper> flatDiscounts = getFlatDiscountsList(filteredDTG);
        Map<String, DiscountTemplateFlatWrapper> applicationIdToNewFlatDiscount = mergeDiscountsWithinThreePriorities(
            relativePriorities,
            flatDiscounts
        );

        /**
         * Put updated discounts from quote line items into the 3rd (highest) priority.
         * Remove catalog discounts if needed.
         */
        updateDiscountsMapWithQLIsChanges(
            applicationIdToNewFlatDiscount,
            relativePriorities,
            primaryQuote,
            accountContract,
            billingContracts
        );

        // Transform relative priorities into new alphabetical vacant priorities
        List<String> actualRelativePriorities = getActualRelativePriorities(applicationIdToNewFlatDiscount.values());
        List<String> newPriorities = getNextPriorities(allDTG, actualRelativePriorities.size());
        Map<String, String> relativeToNewPriorityMap = matchRelativePrioritiesToNewPriorities(actualRelativePriorities, newPriorities);

        for (DiscountTemplateFlatWrapper flatDT : applicationIdToNewFlatDiscount.values()) {
            String newPriority = relativeToNewPriorityMap.get(flatDT.priority);
            if(newPriorityToDiscountsList.get(newPriority) == null) {
                newPriorityToDiscountsList.put(newPriority, new List<DiscountTemplate>());
            }
            newPriorityToDiscountsList.get(newPriority).add(flatDT.discountTemplate);
        }

        return newPriorityToDiscountsList;
    }

    private static List<DiscountTemplateFlatWrapper> getFlatDiscountsList(List<DiscountTemplateGroup> dtgList) {
        List<DiscountTemplateFlatWrapper> flatDiscounts = new List<DiscountTemplateFlatWrapper>();
        for (DiscountTemplateGroup dtg : dtgList) {
            for (DiscountTemplate dt : dtg.discountTemplates) {
                flatDiscounts.add(new DiscountTemplateFlatWrapper(dt, dtg.priority));
            }
        }
        return flatDiscounts;
    }

    public static String getCategoryFromCatalogId(String catalogId) {
        Integer firstUnderscore = catalogId.indexOf('_');
        Integer secondUnderscore = catalogId.indexOf('_', firstUnderscore + 1);
        if (firstUnderscore != -1 && secondUnderscore != -1) {
            return catalogId.substring(firstUnderscore + 1, secondUnderscore);
        } else {
            return '';
        }
    }

    private static void updateDiscountsMapWithQLIsChanges(
        Map<String, DiscountTemplateFlatWrapper> applicationIdToNewFlatDiscount,
        List<String> relativePriorities,
        Quote qt,
        Contract__c accountContract,
        List<BillingWrappers.BillingContract> billingContracts
    ) {
        Map<String, String> externalIdToBillingTypeMap = getExternalIdToBillingTypeMap(qt);
        BillingWrappers.QuotePackageInfo pInfo = QuoteHelper.getPackageInfo(qt);
        String chargeTerm = pInfo.duration;
        Boolean isNGBSPartnerPackageChange = QuoteHelper.isNGBSPartnerPackageChange(qt, qt.QuoteLineItems);

        List<String> categoryIdsForRemoval = new List<String>();
        List<DiscountTemplateFlatWrapper> flatDiscounts = new List<DiscountTemplateFlatWrapper>();
        flatDiscounts.addAll(applicationIdToNewFlatDiscount.values());

        orderBy = DESCENDING;
        flatDiscounts.sort();

        Map<String, DiscountItemWrapper> qliCatalogIdToDiscountValue = new Map<String, DiscountItemWrapper>();
        qliCatalogIdToDiscountValue.putAll(getShippingDiscountItems(qt));

        for (QuoteLineItem qli : qt.QuoteLineItems) {
            BillingWrappers.QLIPackageInfo packageInfo = new BillingWrappers.QLIPackageInfo(qli.PackageInfo__c);
            String categoryId = packageInfo.categoryCode;
            String catalogId = qli.Product2.ExtID__c;
            if (categoryId == null || catalogId == null || qli.ChargeTerm__c == null) {
                AquivaHelper.throwAquivaException(
                'An error occurred during synchronization: invalid quote line item' +
                ' Please contact administrator');
            }

            if (Product2Helper.isMobileUser(qli)
                || AccountHelper.isElaService(qt.Account) && qli.Product2.ExtID__c == DIGITAL_LINE_UNLIMITED) {
                continue;
            }

            Decimal qliDiscountValue = applyContract(qli, accountContract);

            if (AccountHelper.isWholesaleAccount(qt.Account) || isNGBSPartnerPackageChange || isItemRemovedByUpgrade(qli, qt.Upsell_Status__c)) {
                qliDiscountValue = qli.Discount_Number__c;
            }

            if (qliDiscountValue == 0) {
                if (applicationIdToNewFlatDiscount.containsKey(categoryId)) {
                    categoryIdsForRemoval.add(categoryId);
                    applicationIdToNewFlatDiscount.remove(categoryId);
                }
                applicationIdToNewFlatDiscount.remove(catalogId);
                continue;
            }

            DiscountTemplate activeDiscount;

            for (DiscountTemplateFlatWrapper flatDiscount : flatDiscounts) {
                DiscountTemplate dt = flatDiscount.discountTemplate;
                DiscountValue mainApplication = dt.values.get(durationMapping.get(qli.ChargeTerm__c));
                if (mainApplication != null && mainApplication.value != null
                        && (dt.applicableTo.id == catalogId || dt.applicableTo.id == categoryId)
                ) {
                    activeDiscount = dt;
                    break;
                }
            }

            if (shouldNewDiscountBeCreatedFromQLI(qli, qliDiscountValue, activeDiscount, durationMapping.get(qli.ChargeTerm__c), categoryIdsForRemoval, true)) {
                /* remove category discount */
                if (activeDiscount != null && applicationIdToNewFlatDiscount.containsKey(categoryId)) {
                    categoryIdsForRemoval.add(categoryId);
                    applicationIdToNewFlatDiscount.remove(categoryId);
                }

                Map<String, DiscountItemWrapper> discountItemsMap = createDiscountItemsFromQLI(qt, qli, qliDiscountValue, pInfo, true);
                qliCatalogIdToDiscountValue.putAll(discountItemsMap);
            }
        }

        for (String catalogId : qliCatalogIdToDiscountValue.keySet()) {
            DiscountTemplate dt = new DiscountTemplate(
                qliCatalogIdToDiscountValue.get(catalogId),
                System.now().dateGMT(),
                billingContracts,
                false,
                externalIdToBillingTypeMap
            );

            applicationIdToNewFlatDiscount.put(catalogId, new DiscountTemplateFlatWrapper(dt, relativePriorities[2]));
        }

        applicationIdToNewFlatDiscount.putAll(
            createQliDiscountsForRemovedCategories(
                applicationIdToNewFlatDiscount,
                relativePriorities,
                categoryIdsForRemoval,
                qt,
                accountContract,
                billingContracts
            )
        );

        // move existing catalog discounts for removing categories from 1st to the 3rd priority
        for (DiscountTemplateFlatWrapper flatdiscount : applicationIdToNewFlatDiscount.values()) {
            if (flatdiscount.priority != relativePriorities[0]) {
                continue;
            }
            String categoryId = getCategoryFromCatalogId(flatdiscount.discountTemplate.applicableTo.id);
            if (categoryIdsForRemoval.contains(categoryId)) {
                flatdiscount.priority = relativePriorities[2];
            }
        }
    }

    private static Map<String, DiscountTemplateFlatWrapper> createQliDiscountsForRemovedCategories(
        Map<String, DiscountTemplateFlatWrapper> applicationIdToNewFlatDiscount,
        List<String> relativePriorities,
        List<String> categoryIdsForRemoval,
        Quote qt,
        Contract__c accountContract,
        List<BillingWrappers.BillingContract> billingContracts
    ) {
        Map<String, DiscountTemplateFlatWrapper> qliDiscountsMap = new Map<String, DiscountTemplateFlatWrapper>();
        Map<String, String> externalIdToBillingTypeMap = getExternalIdToBillingTypeMap(qt);
        Boolean isNGBSPartnerPackageChange = QuoteHelper.isNGBSPartnerPackageChange(qt, qt.QuoteLineItems);

        for (QuoteLineItem qli : qt.QuoteLineItems) {
            BillingWrappers.QLIPackageInfo packageInfo = new BillingWrappers.QLIPackageInfo(qli.PackageInfo__c);
            String categoryId = packageInfo.categoryCode;
            String catalogId = qli.Product2.ExtID__c;

            if (categoryIdsForRemoval.contains(categoryId)
                && (applicationIdToNewFlatDiscount.get(catalogId) == null
                    || applicationIdToNewFlatDiscount.get(catalogId).priority == relativePriorities[0])
            ) {
                Decimal qliDiscountValue = applyContract(qli, accountContract);

                if (AccountHelper.isWholesaleAccount(qt.Account) || isNGBSPartnerPackageChange || isItemRemovedByUpgrade(qli, qt.Upsell_Status__c)) {
                    qliDiscountValue = qli.Discount_Number__c;
                }

                if (qliDiscountValue == 0) {
                    continue;
                }

                DiscountItemWrapper item = new DiscountItemWrapper(
                    qli,
                    new DiscountValue(qliDiscountValue, qli.Discount_type__c, true)
                );

                DiscountTemplate dt = new DiscountTemplate(
                    item,
                    System.now().dateGMT(),
                    billingContracts,
                    false,
                    externalIdToBillingTypeMap
                );

                qliDiscountsMap.put(catalogId, new DiscountTemplateFlatWrapper(dt, relativePriorities[2]));
            }
        }
        return qliDiscountsMap;
    }

    private static Map<String, DiscountTemplateFlatWrapper> mergeDiscountsWithinThreePriorities(
        List<String> newPriorities,
        List<DiscountTemplateFlatWrapper> flatDiscountsFromDTGs
    ) {
        Map<String, DiscountTemplateFlatWrapper> applicationIdToNewFlatDiscount = new Map<String, DiscountTemplateFlatWrapper>();

        orderBy = DESCENDING;
        flatDiscountsFromDTGs.sort();

        for (DiscountTemplateFlatWrapper flatDiscount : flatDiscountsFromDTGs) {
            DiscountTemplate dt = flatDiscount.discountTemplate;

            // put category discounts into the middle (2nd) DTG
            if (dt.applicableTo.type == BILLING_CATEGORY_ID_TYPE
                && !applicationIdToNewFlatDiscount.containsKey(dt.applicableTo.id)
            ) {
                DiscountTemplateFlatWrapper copiedFlatDiscount = (DiscountTemplateFlatWrapper) JSON.deserialize(JSON.serialize(flatDiscount), DiscountTemplateFlatWrapper.class);
                copiedFlatDiscount.priority = newPriorities[1];
                applicationIdToNewFlatDiscount.put(flatDiscount.discountTemplate.applicableTo.id, copiedFlatDiscount);
            }

            // put catalog discounts into the 1st or 3rd priority DTGs
            if (dt.applicableTo.type == BILLING_CATALOG_ID_TYPE) {
                String categoryId = getCategoryFromCatalogId(dt.applicableTo.id);
                if (!applicationIdToNewFlatDiscount.containsKey(dt.applicableTo.id)) {
                    DiscountTemplateFlatWrapper copiedFlatDiscount = (DiscountTemplateFlatWrapper) JSON.deserialize(JSON.serialize(flatDiscount), DiscountTemplateFlatWrapper.class);
                    copiedFlatDiscount.priority = applicationIdToNewFlatDiscount.get(categoryId) != null ? newPriorities[0] : newPriorities[2];
                    applicationIdToNewFlatDiscount.put(flatDiscount.discountTemplate.applicableTo.id, copiedFlatDiscount);
                }
            }
        }
        return applicationIdToNewFlatDiscount;
    }

    @TestVisible
    private static Boolean shouldNewDiscountBeCreatedFromQLI(
        QuoteLineItem qli,
        Decimal qliDiscountValue,
        DiscountTemplate activeDiscount,
        String duration,
        List<String> categoryIdsForRemoval,
        Boolean isMergeDiscountLogicApplied
    ) {
        if (activeDiscount == null || categoryIdsForRemoval.contains(activeDiscount.applicableTo.id)) {
            return true;
        }

        if (isMergeDiscountLogicApplied
            && (!QuoteLineItemHelper.isHasEntitlement(qli)
                || !qli.Zero_Quantity__c)
        ) {
            return true;
        }

        Boolean createNewDiscountFromQLI = true;
        if (isMergeDiscountLogicApplied || activeDiscount.applicableTo.type == BILLING_CATEGORY_ID_TYPE) {
            DiscountValue mainApplication = activeDiscount.values.get(duration);

            Boolean isCurrency = mainApplication.unit == BILLING_DISCOUNT_TYPE_CURRENCY;
            String expectedDiscountType = isCurrency ? QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY : QuoteLineItemHelper.DISCOUNT_TYPE_PERCENTAGE;

            createNewDiscountFromQLI = qli.Discount_type__c != expectedDiscountType || mainApplication.value != qliDiscountValue;
        }
        return createNewDiscountFromQLI;
    }

    private static Map<String, DiscountItemWrapper> createDiscountItemsFromQLI(
        Quote qt,
        QuoteLineItem qli,
        Decimal qliDiscountValue,
        BillingWrappers.QuotePackageInfo pInfo,
        Boolean isValueTermRequired
    ) {
        Map<String, DiscountItemWrapper> catalogToDiscountValue = new Map<String, DiscountItemWrapper>();

        String catalogId = qli.Product2.ExtID__c;

        /* discounts that have no especial creation flow */
        if (!QuoteLineItemHelper.isUsageLicense(qli)) {
            DiscountItemWrapper item = new DiscountItemWrapper(
                qli,
                new DiscountValue(qliDiscountValue, qli.Discount_type__c, true)
            );
            catalogToDiscountValue.put(catalogId, item);
        }

        String usageDuration = isValueTermRequired || Feature_Toggle__c.getInstance().Use_valueTerm_in_NGBS_Sign_Up_discount__c
                    ? pInfo.duration
                    : Product2Helper.CHARGE_TERM_MONTHLY;

        /* case for mobile user */
        if (qli.Product2.ExtID__c == DIGITAL_LINE_UNLIMITED) {
            DiscountItemWrapper mobileUserItem = createMobileUserDiscountItem(qli, qliDiscountValue, usageDuration);
            if (mobileUserItem != null) {
                catalogToDiscountValue.put(Product2Helper.MOBILE_USER_ELEMENT_ID, mobileUserItem);
            }
        }

        /* case for usage */
        if ((QuoteHelper.isEngage(qt) || QuoteHelper.isRCCC(qt)) && QuoteLineItemHelper.isUsageLicense(qli)) {
            DiscountItemWrapper usageItem = createUsageDiscountItem(qli, qliDiscountValue, usageDuration);
            if (usageItem != null) {
                catalogToDiscountValue.put(catalogId, usageItem);
            }
        }

        return catalogToDiscountValue;
    }

    private static Map<String, DiscountItemWrapper> getShippingDiscountItems(Quote qt) {
        Map<String, DiscountItemWrapper> catalogToDiscountValue = new Map<String, DiscountItemWrapper>();

        BillingWrappers.QuotePackageInfo pInfo = QuoteHelper.getPackageInfo(qt);
        if (qt != null &&
            qt.FreeShippingTerms__c == QuoteHelper.FREESHIPPING &&
            pInfo != null && pInfo.id != null && pInfo.version != null) {

            Set<String> shippingLicenses = new Set<String>();
            Boolean hasDevice = false;
            for (QuoteLineItem qli : qt.QuoteLineItems) {
                BillingWrappers.QLIPackageInfo qliPackage = new BillingWrappers.QLIPackageInfo(qli.PackageInfo__c);
                if (Product2Helper.SHIPPING_PHONES.contains(qliPackage.categoryCode)) {
                    hasDevice = true;
                    break;
                }
            }
            if (qt != null && (
                SWNHelper.isLBOOrOfficeProductSelected(qt) && QuoteHelper.isExistingBusiness(qt)
                || QuoteHelper.isNewBusiness(qt) && Feature_Toggle__c.getInstance().Shipping_Tab_New_Business__c
            )) {
                shippingLicenses = getShippingLicenses(qt);
            }

            Map<String,BillingWrappers.NGBSShippingLicense> shippingLicenseMap = NGBSAPI.getShippingLicenses(pInfo.id,pInfo.version);
            if (!shippingLicenseMap.isEmpty()) {
                if (!shippingLicenses.isEmpty()) {
                    for (String shippingLic : shippingLicenses) {
                        if (shippingLicenseMap.get(shippingLic) != null) {
                            DiscountItemWrapper diw = getShippingDiscountItemWrapper(shippingLicenseMap.get(shippingLic).elementID, shippingLicenseMap.get(shippingLic).displayName);
                            catalogToDiscountValue.put(shippingLicenseMap.get(shippingLic).elementID, diw);
                        }
                    }

                } else {
                    if (hasDevice && qt.Shipping_Option__c != null) {
                        for (BillingWrappers.NGBSShippingLicense shippingLicense : shippingLicenseMap.values()) {
                            String shippingCategory = shippingLicense.searchCategories[0].value != '2DAY' ? shippingLicense.searchCategories[0].value : QuoteHelper.SHIPPING_OPTION_2_DAY;
                            if (qt.Shipping_Option__c.toLowerCase() == shippingCategory.toLowerCase()) {
                                DiscountItemWrapper diw = getShippingDiscountItemWrapper(shippingLicense.elementID, shippingLicense.displayName);
                                catalogToDiscountValue.put(shippingLicense.elementID, diw);
                            }
                        }
                    }
                }
            }
        }
        return catalogToDiscountValue;
    }

    public static DiscountItemWrapper createMobileUserDiscountItem(QuoteLineItem dlUnlimited, Decimal value, String duration) {
        DiscountItemWrapper item;

        if (value > 0) {
            /* Mobile user is always monthly */
            if (dlUnlimited.Discount_type__c == QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY &&
                dlUnlimited.ChargeTerm__c == Product2Helper.CHARGE_TERM_ANNUAL) {
                value = value / 12;
            }

            item = new DiscountItemWrapper(
                MOBILE_USER_NAME,
                Product2Helper.MOBILE_USER_ELEMENT_ID,
                duration,
                new DiscountValue(value, dlUnlimited.Discount_type__c, true)
            );
        }

        return item;
    }

    public static DiscountItemWrapper createUsageDiscountItem(QuoteLineItem usage, Decimal value, String duration) {
        /* Usage license is always monthly. Value shouldn't be recalculated from annual to monthly */
        DiscountItemWrapper item = new DiscountItemWrapper(
            usage.Display_Name__c,
            usage.Product2.ExtID__c,
            duration,
            new DiscountValue(value, usage.Discount_type__c, true)
        );

        return item;
    }

    public static DiscountTemplate[] getDiscountTemplates(
        List<DiscountItemWrapper> discountItemsList,
        Date quoteStartDate,
        List<BillingWrappers.BillingContract> billingContracts,
        Map<String, String> externalIdToBillingTypeMap
    ) {
        return getDiscountTemplates(discountItemsList, quoteStartDate, billingContracts, false, externalIdToBillingTypeMap);
    }

    public static DiscountTemplate[] getDiscountTemplates(
        List<DiscountItemWrapper> discountItemsList,
        Date quoteStartDate,
        List<BillingWrappers.BillingContract> billingContracts,
        Boolean isRoot,
        Map<String, String> externalIdToBillingTypeMap
    ) {
        DiscountTemplate[] result = new List<DiscountTemplate>();

        for (DiscountItemWrapper item : discountItemsList) {
            result.add(
                new DiscountTemplate(
                    item,
                    quoteStartDate,
                    billingContracts,
                    isRoot,
                    externalIdToBillingTypeMap
                )
            );
        }

        return result;
    }

    public static OldDiscountTemplate[] getOldDiscountTemplate(
        List<DiscountItemWrapper> discountItemsList,
        Date quoteStartDate,
        List<BillingWrappers.BillingContract> billingContracts,
        Boolean isRoot,
        Map<String, String> externalIdToBillingTypeMap
    ) {
        OldDiscountTemplate[] result = new List<OldDiscountTemplate>();

        for (DiscountItemWrapper item : discountItemsList) {
            result.add(
                new OldDiscountTemplate(
                    item,
                    quoteStartDate,
                    billingContracts,
                    isRoot,
                    externalIdToBillingTypeMap
                )
            );
        }

        return result;
    }

    public class RootDiscountTemplateGroup {
        public String id;
        public String name; // required
        public String description;
        public String startDate;
        public String endDate;
        public String status; // required [Actual, Draft, Expired]
        public String priority;
        public String goa;
        public DiscountAvailabilityTerms[] availability;
        public String promoCode;
        public OldDiscountTemplate[] discountTemplates;
        public PromoType promoType; //	PromoType	optional	-	1 - Regular Promo, 2 - One-Time Promo

        public rootDiscountTemplateGroup() {}

        public rootDiscountTemplateGroup(
            Quote qt,
            BillingWrappers.QuotePackageInfo quotePackageInfo,
            List<DiscountItemWrapper> discountItemsList,
            String priority,
            Map<String, String> externalIdToBillingTypeMap
        ) {
            this.name = qt.Name;
            this.description = qt.Name;
            this.priority = String.isNotBlank(priority) ? priority : 'A';

            Datetime dt = Datetime.now().addDays(DISCOUNT_START_DATE_OFFSET);
            this.startDate = getUTCDateTimeStr(dt);
            this.endDate = getUTCDateTimeStr(dt.addYears(300));
            this.promoCode = getPromoCode(qt.opportunityId, dt);

            Boolean isUsageAllowed = Feature_Toggle__c.getInstance().Use_valueTerm_in_NGBS_Sign_Up_discount__c;
            if (isUsageAllowed) {
                this.discountTemplates = getDiscountTemplates(
                    discountItemsList,
                    qt.Start_Date__c,
                    null,
                    true,
                    externalIdToBillingTypeMap
                );
            } else {
                this.discountTemplates = getOldDiscountTemplate(
                    discountItemsList,
                    qt.Start_Date__c,
                    null,
                    true,
                    externalIdToBillingTypeMap
                );
            }
            this.availability = new DiscountAvailabilityTerms[] { new DiscountAvailabilityTerms(qt.opportunityId) };
            this.promoType = new PromoType();
        }

        private String getUTCDateTimeStr(Datetime dt) {
            return dt.format('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'', 'GMT');
        }

        private String getPromoCode(String oppId, Datetime dt) {
            return String.valueOf(oppId) + dt.format('yyyyMMddhhmmss');
        }
    }

    public class DiscountAvailabilityTerms {
        public String id;
        public String type; // [Product Line, Product, Edition, Package, Opportunity]
        public String availableTo;

        public DiscountAvailabilityTerms(String oppId) {
            type = 'Opportunity';
            availableTo = String.valueOf(oppId);
        }
    }

    public class PromoType {
        public Integer id;
        public String name;

        public PromoType() {
            id = 2;
        }
    }

    public class DiscountTemplateGroup implements Comparable {
        public String id; // 119884001
        public String packageId; // 1389379001,
        public String contractId; // null,
        public String description; // "discount description",
        public String priority; // "A",
        public String addedAt; // "2019-04-17T14:16:47.119Z[UTC]",
        public String promoCode; // null,
        public String promoType; // null,
        public BillingWrappers.PackageInfo target; // null,
        public DiscountTemplate[] discountTemplates;
        public boolean visible;

        public discountTemplateGroup() {}

        public discountTemplateGroup(
            String quoteNumber,
            BillingWrappers.QuotePackageInfo quotePackageInfo,
            List<DiscountItemWrapper> discountItemsList,
            String priority,
            List<BillingWrappers.BillingContract> billingContracts,
            Map<String, String> externalIdToBillingTypeMap
        ) {
            this(
                quoteNumber,
                quotePackageInfo,
                getDiscountTemplates(discountItemsList, System.now().dateGMT(), billingContracts, externalIdToBillingTypeMap),
                priority,
                billingContracts,
                externalIdToBillingTypeMap
            );
        }

        public discountTemplateGroup(
            String quoteNumber,
            BillingWrappers.QuotePackageInfo quotePackageInfo,
            List<DiscountTemplate> discountTemplateList,
            String priority,
            List<BillingWrappers.BillingContract> billingContracts,
            Map<String, String> externalIdToBillingTypeMap
        ) {
            this.description = quoteNumber;
            this.priority = String.isNotBlank(priority) ? priority : 'A';
            this.addedAt = System.now().formatGmt(NGBS_UTC_FORMAT);
            this.target = getTarget(quotePackageInfo);
            this.discountTemplates = discountTemplateList;
            this.visible = true;
        }

        private BillingWrappers.PackageInfo getTarget(BillingWrappers.QuotePackageInfo quotePackageInfo) {
            BillingWrappers.PackageInfo result = new BillingWrappers.PackageInfo();
                                        result.catalogId = quotePackageInfo.packageInfo.catalogId;
                                        result.version = quotePackageInfo.packageInfo.version;
            return result;
        }

        public Integer compareTo(Object groupToCompare) {
            Integer res = orderBy == ASCENDING
                ? priority.compareTo(((DiscountTemplateGroup) groupToCompare).priority)
                : (- priority.compareTo(((DiscountTemplateGroup) groupToCompare).priority));
            return res;
        }
    }

    /* temporary old version of Discount Template without value term */
    public virtual class OldDiscountTemplate {
        public String id;
        public String name;
        public String description;
        public DiscountApplicationTarget applicableTo;
        public DiscountApplicationTerms applicationTerms;
        public Map<String, DiscountValue> values;

        OldDiscountTemplate(
            DiscountItemWrapper discountItem,
            Date quoteStartDate,
            List<BillingWrappers.BillingContract> billingContracts,
            Boolean isRoot,
            Map<String, String> externalIdToBillingTypeMap
        ) {
            this.name = isRoot ? discountItem.displayName : null;
            this.description = discountItem.displayName;
            this.applicableTo = new DiscountApplicationTarget(discountItem);
            this.applicationTerms = new DiscountApplicationTerms(quoteStartDate, billingContracts);
            if (this.applicableTo.id.contains(SHIPPING_CATEGORY)) {
                this.applicationTerms.startDate = System.now().formatGmt(NGBS_UTC_FORMAT);
                this.applicationTerms.endDate = System.now().addDays(1).formatGmt(NGBS_UTC_FORMAT);
            }
            this.values = discountItem.discountValues;
        }
    }

    /*
        isRoot:
            DiscountTemplate requires name for RootDiscountTemplateGroup
            while DiscountTemplate for DiscountTemplateGroup do not expect it at all
    */
    public class DiscountTemplate extends OldDiscountTemplate {
        public String valueTerm;

        DiscountTemplate(
            DiscountItemWrapper discountItem,
            Date quoteStartDate,
            List<BillingWrappers.BillingContract> billingContracts,
            Boolean isRoot,
            Map<String, String> externalIdToBillingTypeMap
        ) {
            super(discountItem, quoteStartDate, billingContracts, isRoot, externalIdToBillingTypeMap);

            //LC_MU_281 for case, when mobile user not exist as qli on sign up on New Business
            if (externalIdToBillingTypeMap.get(discountItem.externalId) == 'Usage'
                || discountItem.externalId == Product2Helper.MOBILE_USER_ELEMENT_ID) {
                this.valueTerm = PACKAGE_MASTER_DURATION;
            } else {
                this.valueTerm = LICENSE_DURATION;
            }
        }
    }

    public class DiscountApplicationTarget {
        public String type;
        public String id;

        discountApplicationTarget(DiscountItemWrapper item) {
            this.type = item.applicableType;
            this.id = item.externalId;
        }
    }

    public class DiscountApplicationTerms {
        public String startDate; // "2019-04-15T14:16:46.856Z[UTC]"
        public String endDate;
        public Integer maxLicenses;
        public String licenseScope;

        public DiscountApplicationTerms(){}

        public DiscountApplicationTerms(Date quoteStartDate, List<BillingWrappers.BillingContract> billingContracts) {

            List<BillingWrappers.BillingContract> activeContractsList = BillingWrappers.findActiveContracts(billingContracts);

            BillingWrappers.BillingContract currentContract = BillingWrappers.findClosestContractToDate(activeContractsList, quoteStartDate);

            DateTime sDate;
            if (currentContract != null) {
                if (currentContract.isDateInContract(quoteStartDate)) {
                    sDate = (Datetime) quoteStartDate;
                } else {
                    sDate = (Datetime) currentContract.startDate;
                }
            } else {
                sDate = System.now().addDays(BillingWrappers.DISCOUNT_START_DATE_OFFSET);
            }
            this.startDate = sDate.formatGmt(NGBS_UTC_FORMAT);
            this.endDate = null;
            this.licenseScope = 'All';
        }
    }

    public class DiscountValue {
        public String unit;
        public Decimal value;
        public DiscountRecurringTerms recurringTerms;

        public DiscountValue(Decimal value, String discountType, Boolean isOverrideType) {
            this.value = value;
            this.unit = isOverrideType ? discountMappingToBilling.get(discountType) : discountType;
            //recurringTerms = new DiscountRecurringTerms();
        }
    }

    public class DiscountRecurringTerms {
        public String unit;
        public Decimal value;
    }

    public class DiscountItemWrapper {
        public String displayName;
        public String externalId;
        public String applicableType;
        public Map<String, DiscountValue> discountValues;

        public DiscountItemWrapper() {}

        public DiscountItemWrapper(
            String displayName,
            String externalId,
            String chargeTerm,
            DiscountValue discountValue
        ) {
            this.displayName = displayName;
            this.externalId = externalId;
            this.discountValues = new Map<String, DiscountValue>();
            this.discountValues.put(durationMapping.get(chargeTerm), discountValue);
            this.applicableType = BILLING_CATALOG_ID_TYPE;
        }

        public DiscountItemWrapper(QuoteLineItem qli, DiscountValue discountValue) {
            this.displayName = qli.Display_Name__c;
            this.externalId = qli.Product2.ExtID__c;
            this.discountValues = new Map<String, DiscountValue>();
            this.discountValues.put(durationMapping.get(qli.ChargeTerm__c), discountValue);
            this.applicableType = BILLING_CATALOG_ID_TYPE;
        }

        public DiscountItemWrapper(DiscountTemplate dt, String type, String externalId) {
            this.displayName = dt.description;
            this.applicableType = type;
            this.externalId = externalId;
            this.discountValues = dt.values;
        }
    }

    public class Target {
        public String catalogId;
        public String version;

        public Target() {}

        public Target(String catalogId, String version) {
            this.catalogId = catalogId;
            this.version = version;
        }
    }

    public class DiscountTemplateFlatWrapper implements Comparable {
        public DiscountTemplate discountTemplate;
        public String priority;

        public DiscountTemplateFlatWrapper() {}

        public DiscountTemplateFlatWrapper(
            DiscountTemplate discountTemplate,
            String priority
        ) {
            this.discountTemplate = discountTemplate;
            this.priority = priority;
        }

        public Integer compareTo(Object flatDiscountToCompare) {
            Integer res = orderBy == ASCENDING
                ? priority.compareTo(((DiscountTemplateFlatWrapper) flatDiscountToCompare).priority)
                : (- priority.compareTo(((DiscountTemplateFlatWrapper) flatDiscountToCompare).priority));
            return res;
        }
    }

    /* Helpers */
    public static List<String> getPriorityList(List<DiscountTemplateGroup> dtgList, Target target) {
        List<String> priorityList = new List<String>();
        for(DiscountTemplateGroup dtg : dtgList) {
            if(target == null || target.catalogId == dtg.target.catalogId && target.version == dtg.target.version) {
                if (PRIORITY_KEY.contains(dtg.priority)) {
                    priorityList.add(dtg.priority);
                }
            }
        }
        return priorityList;
    }

    public static String getMaxPriority(List<DiscountTemplateGroup> dtgList) {
        return getMaxPriority(dtgList, null);
    }

    public static String getMaxPriority(List<DiscountTemplateGroup> dtgList, Target target) {
        List<String> priorityList = getPriorityList(dtgList, target);
        if (priorityList.size() == 0) {
            return null;
        }
        priorityList.sort();
        Integer lastIdx = priorityList.size() - 1;
        return priorityList[lastIdx];
    }

    public static String getMinVacantPriority(List<String> priorityList) {
        String result;
        if (priorityList.size() == 0) {
            return null;
        }
        priorityList.sort();
        for (Integer idx = 0; idx < PRIORITY_KEY.length(); idx++) {
            if (idx >= priorityList.size() || priorityList.get(idx) != PRIORITY_KEY.substring(idx, idx + 1)) {
                result = PRIORITY_KEY.substring(idx, idx + 1);
                break;
            }
        }
        return result;
    }

    public static List<String> getNextPriorities(List<DiscountTemplateGroup> dtgList, Integer newDtgListSize) {
        List<String> result = new List<String>();
        List<String> dtgListPriorities = getPriorityList(dtgList, null);
        dtgListPriorities.sort();
        if (dtgListPriorities.isEmpty()) {
            if (newDtgListSize > 0 && newDtgListSize <= PRIORITY_KEY.length()) {
                for (Integer i = 0; i < newDtgListSize; i++) {
                    result.add(PRIORITY_KEY.substring(i, i + 1));
                }
            }
            return result;
        }
        if (PRIORITY_KEY.length() - dtgListPriorities.size() < newDtgListSize) {
            AquivaHelper.throwAquivaException(
                'Too many Discount Template Groups in NGBS.' +
                ' There must be at least the same quantity of vacant priorities for Discount Groups.');
        }

        String maxPriority = dtgListPriorities.get(dtgListPriorities.size() - 1);
        Integer maxPriorityIdx = PRIORITY_KEY.indexOfChar(maxPriority.charAt(0));

        if (PRIORITY_KEY.length() - (maxPriorityIdx + 1) >= newDtgListSize) {
            for (Integer i = 1; i <= newDtgListSize; i++) {
                result.add(PRIORITY_KEY.substring(maxPriorityIdx + i, maxPriorityIdx + i + 1));
            }
        } else {
            List<String> mergedPriorityList = dtgListPriorities;
            for (Integer i = 1; i <= newDtgListSize; i++) {
                String vacantChar = getMinVacantPriority(mergedPriorityList);
                mergedPriorityList.add(vacantChar);
                result.add(vacantChar);
            }
        }

        return result;
    }

    public static String getNextChar(String oldChar, List<DiscountTemplateGroup> dtgList) {
        Integer idx = PRIORITY_KEY.indexOfChar(oldChar.charAt(0));

        switch on idx {
            when -1 {
                return null;
            }
            when 25 {
                return getMinVacantPriority(getPriorityList(dtgList, null));
            }
            when else {
                return PRIORITY_KEY.substring(idx + 1, idx + 2);
            }
        }
    }

    @TestVisible
    private static Map<String, String> getExternalIdToBillingTypeMap(Quote qt) {
        Map<String, String> resultMap = new Map<String, String>();
        for (QuoteLineItem qli : qt.QuoteLineItems) {
            if (String.isNotBlank(qli.Product2.ExtID__c)) {
                resultMap.put(qli.Product2.ExtID__c, qli.Product2.Billing_Type__c);
            }
        }
        return resultMap;
    }

    public static Set<String> getShippingLicenses(Quote qt) {
        Set<String> shippingLicenses = new Set<String>();
        Map<Id,QuoteLineItem> qlis = new Map<Id, QuoteLineItem>(qt.QuoteLineItems);
        List<CustomAddressAssignments__c> addressAssignments = (List<CustomAddressAssignments__c>) new CustomAddressAssignmentsSelector()
                .selectCAAForShipping(new List<Object>{qlis.keySet()})
                .executeQuery();
        if (!addressAssignments.isEmpty()) {
            for (CustomAddressAssignments__c caa : addressAssignments) {
                if (caa.ShippingLicenseTree__c != null) {
                    shippingLicenses.add(caa.ShippingLicenseTree__c.split(':')[2]);
                }
            }
        }
        return shippingLicenses;
    }

    public static DiscountItemWrapper getShippingDiscountItemWrapper(String externalId, String displayName) {
        DiscountItemWrapper diw = new DiscountItemWrapper();
        diw.displayName = displayName;
        diw.externalId = externalId;
        diw.applicableType = BILLING_CATALOG_ID_TYPE;
        diw.discountValues = new Map<String, DiscountValue>{durationMapping.get(Product2Helper.CHARGE_TERM_ONE_TIME) => new DiscountValue(100, QuoteLineItemHelper.DISCOUNT_TYPE_PERCENTAGE, true)};
        return diw;
    }

    public static void syncDiscountsForELA(Quote qt) {

        if (qt == null) {
            return;
        }

        if (qt.AccountId == null) {
            return;
        }

        BillingWrappers.QuotePackageInfo pInfo = QuoteHelper.getPackageInfo(qt);
        // TODO move 1 level up (it is already used by previous process of discounts)
        Contract__c accountContract = ContractRestAPI.selectContract(pInfo);

        DiscountItemWrapper mobileUser = NGBS_Discount.getMobileUser(qt, qt.QuoteLineItems, pInfo.duration, accountContract);

        if (mobileUser == null) {
            return;
        }

        List<AccountRelation__c> accRelationList = (List<AccountRelation__c>) new AccountRelationSelector()
            .selectAccountRelationByParentId(qt.AccountId)
            .selectFields(new List<String>{
                'Child_Account__r.Billing_ID__c'
            })
            .executeQuery();

        Set<String> serviceAccountBillingIdSet = new Set<String>();
        for (AccountRelation__c accRel : accRelationList) {
            serviceAccountBillingIdSet.add(accRel.Child_Account__r.Billing_ID__c);
        }
        serviceAccountBillingIdSet.remove(null);
        if (serviceAccountBillingIdSet.isEmpty()) {
            return;
        }

        List<SyncMobileUserDiscounts.SyncDiscountsParam> paramsList = new List<SyncMobileUserDiscounts.SyncDiscountsParam>();
        Integer counter = 0;
        for (String billingId : serviceAccountBillingIdSet) {
            counter++;
            paramsList.add(
                new SyncMobileUserDiscounts.SyncDiscountsParam(billingId, mobileUser)
            );
            if (counter == 20) {
                System.enqueueJob(
                    new SyncMobileUserDiscounts(
                        new List<SyncMobileUserDiscounts.SyncDiscountsParam>(paramsList)
                    )
                );
                paramsList.clear();
                counter = 0;
            }
        }
        if (!paramsList.isEmpty()) {
            System.enqueueJob(
                new SyncMobileUserDiscounts(
                    new List<SyncMobileUserDiscounts.SyncDiscountsParam>(paramsList)
                )
            );
        }
    }

    @TestVisible
    private static DiscountItemWrapper getMobileUser(Quote qt, List<QuoteLineItem> qliList, String pkgDuration, Contract__c accountContract) {
        DiscountItemWrapper result;
        Boolean isNGBSPartnerPackageChange = QuoteHelper.isNGBSPartnerPackageChange(qt, qliList);

        for (QuoteLineItem qli : qliList) {
            if (qli.Product2.ExtID__c == Product2Helper.DL_UNL_ELEMENT_ID) {
                Decimal value = qt != null && !AccountHelper.isWholesaleAccount(qt.Account) && !isNGBSPartnerPackageChange
                    ? applyContract(qli, accountContract)
                    : qli.Discount_Number__c;
                result = createMobileUserDiscountItem(qli, value, pkgDuration);
            }
        }

        return result;
    }

    @TestVisible
    private static Boolean isGroupAvailableForUpdate(NGBS_Discount.DiscountTemplateGroup dGroup) {
        if (dGroup.description == MU_ELA) {
            return false;
        }
        for (NGBS_Discount.DiscountTemplate dt : dGroup.discountTemplates) {
            if (dt.applicableTo.type == NGBS_Discount.BILLING_CATEGORY_ID_TYPE) {
                return false;
            }
        }
        return true;
    }

    @TestVisible
    private static Boolean isItemRemovedByUpgrade(QuoteLineItem qli, String upsellStatus) {
        return upsellStatus == QuoteHelper.STATUS_UPGRADE && qli.NewQuantity__c == 0 && qli.Quantity < 0;
    }

    @TestVisible
    private static void removeCatalogEntry(Map<String, DiscountItemWrapper> catalogToDiscountValueMap, Map<String, String> removingDiscountsCatalogToCategoryMap, String catalogId, String categoryId) {
        catalogToDiscountValueMap.remove(catalogId);
        removingDiscountsCatalogToCategoryMap.put(catalogId, categoryId);

        if (catalogId == DIGITAL_LINE_UNLIMITED) {
            catalogToDiscountValueMap.remove(Product2Helper.MOBILE_USER_ELEMENT_ID);
            removingDiscountsCatalogToCategoryMap.put(Product2Helper.MOBILE_USER_ELEMENT_ID, MOBILE_USER_CATEGORY);
        }
    }

    public static Boolean hasNonSFDCPromoCode(String promoCode) {
        if (promoCode == null) {
            return false;
        }
        String opportunityIdPattern = '006[A-Za-z0-9]{12,15}';
        Pattern pattern = Pattern.compile(opportunityIdPattern);
        Matcher matcher = pattern.matcher(promoCode);
        return !matcher.find();
    }

    private static List<String> getActualRelativePriorities(List<DiscountTemplateFlatWrapper> flatDiscounts) {
        Set<String> uniquePriorities = new Set<String>();
        for (DiscountTemplateFlatWrapper flatDiscount : flatDiscounts) {
            uniquePriorities.add(flatDiscount.priority);
        }
        List<String> resultList = new List<String>(uniquePriorities);
        resultList.sort();
        return resultList;
    }

    public static Map<String, String> matchRelativePrioritiesToNewPriorities(List<String> actualRelativePriorities, List<String> newPriorities) {
        actualRelativePriorities.sort();
        newPriorities.sort();
        if (actualRelativePriorities.size() != newPriorities.size()) {
            AquivaHelper.throwAquivaException('The sizes of the actualRelativePriorities and newPriorities lists must be the same.');
        }
        Map<String, String> relativeToNewPriorityMap = new Map<String, String>();
        for (Integer i = 0; i < actualRelativePriorities.size(); i++) {
            relativeToNewPriorityMap.put(actualRelativePriorities[i], newPriorities[i]);
        }

        return relativeToNewPriorityMap;
    }

    @TestVisible
    private static Decimal applyContract(QuoteLineItem qli, Contract__c contract) {
        if (qli.Discount_Number__c == null) {
            qli.Discount_Number__c = 0;
        }

        if (contract == null) {
            return qli.Discount_Number__c;
        }
        if (qli.Discount_Type__c == QuoteLineItemHelper.DISCOUNT_TYPE_PERCENTAGE && qli.Discount_Number__c == 0) {
            qli.Discount_Type__c = QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY;
        }

        for (Contract_Discount__c cd : contract.Contract_Discounts__r) {
            if (cd.ApplicableTo__c == qli.Product2.ExtID__c && cd.Duration__c == qli.ChargeTerm__c) {
                if (qli.Discount_Type__c == QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY) {
                    return qli.Discount_Number__c + cd.Discount__c;
                } else {
                    Decimal dPrice = qli.UnitPrice + cd.Discount__c;
                    return ((1 - qli.EffectivePriceNew__c / dPrice) * 100).setScale(2);
                }
            }
        }

        return qli.Discount_Number__c;
    }
}