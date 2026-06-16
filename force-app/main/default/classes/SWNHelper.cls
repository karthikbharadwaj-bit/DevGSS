public with sharing class SWNHelper {
    public static final SWNMessageHelper.InfoMessagesBuilder INFO_MESSAGES_BUILDER = new SWNMessageHelper.InfoMessagesBuilder();
    public static final SWNMessageHelper.SuccessMessagesBuilder SUCCESS_MESSAGES_BUILDER = new SWNMessageHelper.SuccessMessagesBuilder();
    public static final SWNMessageHelper.ErrorMessagesBuilder ERROR_MESSAGES_BUILDER = new SWNMessageHelper.ErrorMessagesBuilder();
    public static final String PACKAGE_IS_NOT_ALLOWED_FOR_SYNC_ERROR = 'Selected package is not allowed for "Process Order"';
    public static final String CASE_REASON = 'caseReason';
    public static final String STOP_AUTO_SYNC = 'stopAutoSync';
    public static final String DOWNSELL_TYPE_AUTO = 'auto';
    public static final String DOWNSELL_TYPE_AUTO_WITH_CASE = 'autoWithCase';
    public static final String DOWNSELL_TYPE_MANUAL = 'manual';
    public static final String DOWNSELL_TYPE_EXCEPTION = 'exception';
    public static final String SIMPLIFIED_LBO_DOWN_SELL_LABEL_MANUAL = 'Down-sell (in external system)';
    public static final String SIMPLIFIED_LBO_DOWN_SELL_LABEL_AUTO = 'Down-sell order sync';
    public static final String SIMPLIFIED_LBO_DOWN_SELL_LABEL_AUTO_AND_MANUAL = 'Down-sell';
    public static final String CONTRACT_STATUS_UPDATED = 'updated';
    public static final String CONTRACT_STATUS_NEW = 'new';
    public static final String CONTRACT_STATUS_RESYNCED = 'resynced';
    public static final String NOT_SYNCED = 'NOT_SYNCED';
    public static final String SYNCED = 'SYNCED';
    public static final String SKIPPED = 'SKIPPED';
    public static final String RESYNC = 'RESYNC';
    public static final String SYNC_MANUALLY = 'MANUALLY';
    public static final String SYNC_AUTO = 'AUTO';
    public static final String MAX = 'Max';
    public static final String STATUS_PROP = 'status';
    public static final String RESULT = 'result';

    public static final Map<String, String> SIMPLIFIED_LBO_DOWN_SELL = new Map<String, String> {
        SIMPLIFIED_LBO_DOWN_SELL_LABEL_MANUAL => 'Licenses should be deprovisioned as per instructions in deprovisioning Case(s)',
        SIMPLIFIED_LBO_DOWN_SELL_LABEL_AUTO => 'Order will be synced into NGBS',
        SIMPLIFIED_LBO_DOWN_SELL_LABEL_AUTO_AND_MANUAL => 'Order will be synced into NGBS \n Some licenses should be deprovisioned as per instructions in deprovisioning Case(s)'
    };

    private static final String LICENSE_COUNTER = 'licenseCounter';
    private static final Set<String> HIDDEN_CATEGORIES = new Set<String> {Product2Helper.FAMILY_FEE, Product2Helper.FAMILY_TAXES, Product2Helper.FAMILY_TECHNICAL_LICENSE};

    public static SWNActionRunner getRunner(Id quoteId, String action) {
        SWNActionRunner runner;
        switch on SWNStep.SYNC_STEP.valueOf(action) {
            when SYNC_TO_CCB_DOWNSELL, SYNC_TO_CCB_UPSELL, SYNC_TO_NGBS_DOWNSELL, SYNC_TO_NGBS_UPSELL {
                runner = new SWNUpsellDownsellRunner(quoteId, action);
            }
            when SYNC_TO_CCB_UPGRADE {
                runner = new SWNSyncToCCBUpgradeRunner(quoteId, action);
            }
            when SYNC_TO_NGBS_UPGRADE {
                runner = new SWNSyncToNGBSUpgradeRunner(quoteId, action);
            }
            when SYNC_TO_ICB, SYNC_TO_INCONTACT {
                runner = new SWNSyncToICBOrInContactRunner(quoteId, action);
            }
            when CONVERT_TO_PAID, CONVERT_TO_PAID_WHOLESALE {
                runner = new SWNConvertToPaidRunner(quoteId, action);
            }
            when UP_SELL {
                runner = new SWNUpsellRunner(quoteId, action);
            }
            when ORDER {
                runner = new SWNOrderRunner(quoteId, action);
            }
            when DOWN_SELL {
                runner = new SWNDownsellRunner(quoteId, action);
            }
            when UPGRADE {
                runner = new SWNUpgradeRunner(quoteId, action);
            }
            when DISCOUNT_SYNC {
                runner = new SWNSyncDiscountRunner(quoteId, action);
            }
            when CONTRACT_SYNC {
                runner = new SWNSyncContractRunner(quoteId, action);
            }
            when REPRICE_SYNC {
                runner = new SWNSyncRepriceRunner(quoteId, action);
            }
            when UPDATE_LICENSE_LIMITS {
                runner = new SWNUpdateLicenseLimitsRunner(quoteId, action);
            }
            when CONTRACT_CANCELLATION {
                runner = new SWNContractCancellationRunner(quoteId, action);
            }
            when SYNC_INVOICE {
                runner = new SWNSyncInvoiceRunner(quoteId, action);
            }
            when ENGAGE_ACCOUNT_TERMINATION {
                runner = new SWNEngageAccountTerminationRunner(quoteId, action);
            }
            when CHARGE_TERM_SYNC {
                runner = new SWNSyncChargeTermRunner(quoteId, action);
            }
            when SYNC_SPENDING_LIMIT_RETRIEVE {
                runner = new SWNSyncSpendingLimitRunner(quoteId, action);
            }
        }
        return runner;
    }

    public static String validateSyncWithNGBS(Id quoteId, Boolean isAuto) {
        SWNDataCollector sdc = new SWNDataCollector(quoteId);
        return SWNValidator.validateSyncWithNGBS(sdc, isAuto);
    }

    public static Response getStopSync(String action, Quote qt, String billingId, BillingWrappers.NGBSAccount ngbsAcc) {
        Response res = new Response();
        String packageId = QuoteHelper.getPackageId(qt.Package_Info__c);
        List<BillingWrappers.BillingInfoSummaryLicense> licenses;

        if (action != SWNStep.DOWN_SELL) {
            licenses = NGBSAPI.getNGBSBillingInfoSummaryLicenses(
                billingId,
                packageId
            );
        }

        switch on SWNStep.SYNC_STEP.valueOf(action) {
            when DOWN_SELL {
                stopSyncDownsell(qt, billingId, packageId, res);
            }

            when UPGRADE {
                stopSyncUpgrade(qt, packageId, licenses, res, ngbsAcc);
            }

            when UP_SELL {
                stopSyncUpsell(qt, licenses, res);
            }
        }

        return res;
    }

    public static List<NGBS_Discount.DiscountTemplateGroup> filterDiscountTemplates_new(
        List<NGBS_Discount.DiscountTemplateGroup> dGroups,
        String targetCatalogId,
        String targetVersion,
        String targetChargeTerm
    ) {
        List<NGBS_Discount.DiscountTemplateGroup> filteredDiscountTemplates = new List<NGBS_Discount.DiscountTemplateGroup>();
        for (NGBS_Discount.DiscountTemplateGroup dg : dGroups) {
            if (!NGBS_Discount.PRIORITY_KEY.contains(dg.priority)) {
                continue;
            }
            if (dg.target == null || dg.target.catalogId == null || dg.target.version == null) {
                continue;
            }
            if (dg.target.catalogId != targetCatalogId || dg.target.version != targetVersion) {
                continue;
            }
            if (SettingsHelper.FEATURE_TOGGLE.EnableSimplifiedLBODownsell__c && NGBS_Discount.hasNonSFDCPromoCode(dg.promoCode)) {
                continue;
            }
            if (String.isBlank(targetChargeTerm)) {
                // specific logic - if no charge term specified, then we need to add all the discounts
                filteredDiscountTemplates.add(dg);
                continue;
            }
            // charge term was specified - need to add only template groups with the spcified chargeterm or one-times in them
            Boolean hasTargetChargeTerm = false;
            Boolean hasOnlyOneTime = true;
            for (NGBS_Discount.DiscountTemplate dt : dg.discountTemplates) {
                if (dt.values.containsKey(targetChargeTerm)) {
                    hasTargetChargeTerm = true;
                } else if (!dt.values.containsKey(BillingWrappers.BILLING_CHARGE_TERM_ONE_TIME)) {
                    hasOnlyOneTime = false;
                }
            }
            if (hasTargetChargeTerm || hasOnlyOneTime) {
                filteredDiscountTemplates.add(dg);
            }
        }
        return filteredDiscountTemplates;
    }

    public static List<QuoteLineItem> getDownsellQliList(List<QuoteLineItem> qlis) {
        List<QuoteLineItem> result = new List<QuoteLineItem>();
        for (QuoteLineItem qli : qlis) {
            Decimal entQty = qli.Entitlement__r?.Quantity__c ?? 0;
            Decimal qliQty = qli.NewQuantity__c;

            if (entQty > qliQty) {
                result.add(qli);
            }
        }
        return result;
    }

    public static void filterRepriceStep(SWNScenarioHelper.Scenario sc, Quote qt, List<BillingWrappers.BillingContract> billingContracts) {
        Boolean shouldRemoveReprice = validateRepriceStep(qt, billingContracts);

        if (shouldRemoveReprice) {
            removeRepriceStep(sc);
        }
    }

    public static void updateSimplifiedDownsellStep(SWNScenarioHelper.Scenario sc, Quote qt) {
        if (sc.stepsMap == null || sc.stepsMap.get(SWNStep.DOWN_SELL) == null) {
            return;
        }

        List<QuoteLineItem> downsellQliList = filterQuoteLineItems(getDownsellQliList(qt.QuoteLineItems));
        Map<String, List<QuoteLineItem>> qliTypesMap = getQliTypesForSimplifiedLBODownsell(qt, downsellQliList, selectCostCenters(qt));

        Boolean onlyAutoDownsell = !qliTypesMap.get(DOWNSELL_TYPE_AUTO).isEmpty()
                                    && qliTypesMap.get(DOWNSELL_TYPE_AUTO_WITH_CASE).isEmpty()
                                    && qliTypesMap.get(DOWNSELL_TYPE_MANUAL).isEmpty()
                                    && qliTypesMap.get(DOWNSELL_TYPE_EXCEPTION).isEmpty();

        Boolean hasNoAutoDownsell = qliTypesMap.get(DOWNSELL_TYPE_AUTO).isEmpty()
                                && qliTypesMap.get(DOWNSELL_TYPE_AUTO_WITH_CASE).isEmpty();

        SWNStep downSellStep = sc.stepsMap.get(SWNStep.DOWN_SELL);
        if (onlyAutoDownsell) {
            downSellStep.label = SIMPLIFIED_LBO_DOWN_SELL_LABEL_AUTO;
            downSellStep.description = SIMPLIFIED_LBO_DOWN_SELL.get(SIMPLIFIED_LBO_DOWN_SELL_LABEL_AUTO);
            downSellStep.isNeedToLogTimeStamp = true;
        } else if (hasNoAutoDownsell) {
            downSellStep.label = SIMPLIFIED_LBO_DOWN_SELL_LABEL_MANUAL;
            downSellStep.description = SIMPLIFIED_LBO_DOWN_SELL.get(SIMPLIFIED_LBO_DOWN_SELL_LABEL_MANUAL);
        } else {
            downSellStep.label = SIMPLIFIED_LBO_DOWN_SELL_LABEL_AUTO_AND_MANUAL;
            downSellStep.description = SIMPLIFIED_LBO_DOWN_SELL.get(SIMPLIFIED_LBO_DOWN_SELL_LABEL_AUTO_AND_MANUAL);
            downSellStep.isNeedToLogTimeStamp = true;
        }
    }

    @TestVisible
    private static Boolean validateRepriceStep(Quote qt, List<BillingWrappers.BillingContract> billingContracts) {
        BillingWrappers.QuotePackageInfo pInfo = QuoteHelper.getPackageInfo(qt);
        String contractSFDCExtId = pInfo?.contract?.extId;
        String packageId = pInfo?.packageInfo?.id;

        Boolean isUnitPriceOrEffectivePriceChanged = QuoteHelper.isUnitPriceOrEffectivePriceChanged(qt);
        Boolean isContractChanged = isContractChanged(billingContracts, contractSFDCExtId, packageId);
        Boolean hasContract = ContractRestAPI.hasActiveContract(billingContracts) || String.isNotBlank(contractSFDCExtId);

        return !canApplyReprice() || !hasContract || !isUnitPriceOrEffectivePriceChanged && !isContractChanged;
    }

    @TestVisible
    private static Boolean isContractChanged(
        List<BillingWrappers.BillingContract> billingContracts,
        String contractSFDCExtId,
        String packageId
    ) {
        List<BillingWrappers.BillingContract> activeBillingContracts = BillingWrappers.findActiveContracts(billingContracts);
        if (activeBillingContracts?.isEmpty() != false) {
            return !String.isBlank(contractSFDCExtId);
        }

        String contractDescription = getContractDescription(activeBillingContracts.get(0), packageId);
        return String.isNotBlank(contractDescription) ? isContractChanged(contractDescription, contractSFDCExtId) : false;
    }

    private static Boolean isContractChanged(String contractDescription, String contractSFDCExtId) {
        Map<String, Object> contractDescriptionParsed = (Map<String, Object>) JSON.deserializeUntyped(contractDescription);
        String activeBillingContractExtId = (String) contractDescriptionParsed.get('contractExtId');

        return activeBillingContractExtId != contractSFDCExtId;
    }

    private static String getContractDescription(BillingWrappers.BillingContract billingContract, String packageId) {
        if (billingContract.packages == null) {
            return billingContract.description;
        }

        for (BillingWrappers.FunnelPackage pkg : billingContract.packages) {
            if (pkg.packageId == packageId) {
                return pkg.description;
            }
        }

        return billingContract.description;
    }

    private static Boolean canApplyReprice() {
        return FeatureManagement.checkPermission(CustomPermissionHelper.PERMISSION_CAN_TRIGGER_NGBS_REPRICE);
    }

    private static void removeRepriceStep(SWNScenarioHelper.Scenario sc) {
        sc.stepNames.remove(sc.stepNames.indexOf(SWNStep.REPRICE_SYNC));
        sc.steps.remove(sc.steps.indexOf(SWNStep.STEPS.get(SWNStep.REPRICE_SYNC)));
        sc.stepsMap.remove(SWNStep.REPRICE_SYNC);
    }

    public static List<QuoteLineItem> getUpsellQliList(List<QuoteLineItem> qlis) {
        List<QuoteLineItem> result = new List<QuoteLineItem>();
        for (QuoteLineItem qli : qlis) {
            Decimal entQty = qli.Entitlement__r?.Quantity__c ?? 0;
            Decimal qliQty = qli.NewQuantity__c;

            if (entQty < qliQty) {
                result.add(qli);
            }
        }
        return result;
    }

    public static Boolean checkSyncQtyStatus(String billingId, String packageId, List<QuoteLineItem> qlis) {
        /*
            we can not check sync status for one time only and return false
            in the next step we set sync status as passed if link was received
            and we won`t get here again
          */
        if (!qlis.isEmpty() && QuoteLineItemHelper.isOnlyOneTime(qlis)) {
            return false;
        }

		String summaryPostBody = '{"fields":{"scheduledForRemoval":true,"price":true,"dateRange":true,"discountValue":["Unit","Value"]}}';
        List<BillingWrappers.BillingInfoSummaryLicense> licenses = NGBSAPI.getNGBSBillingInfoSummaryLicenses(
            billingId,
			packageId,
			null,
			summaryPostBody
        );

        List<String> categories = new List<String>();
        for (QuoteLineItem qli : qlis) {
            BillingWrappers.QLIPackageInfo qliPackage = new BillingWrappers.QLIPackageInfo(qli.PackageInfo__c);
            categories.add(qliPackage.CategoryCode);
        }

        List<BillingWrappers.NGBSLicense> licenseInfoCategories = NGBSAPI.getNGBSAccountLicenseInfoCategories(
            billingId,
            packageId,
            categories
        );

        Map<String, BillingWrappers.NGBSLicense[]> licenseInfoCategoriesMap = new Map<String, BillingWrappers.NGBSLicense[]>();
        for (BillingWrappers.NGBSLicense l: licenseInfoCategories) {
            if (!licenseInfoCategoriesMap.containsKey(l.catalogId)) {
                licenseInfoCategoriesMap.put(l.catalogId, new List<BillingWrappers.NGBSLicense>());
            }
            licenseInfoCategoriesMap.get(l.catalogId).add(l);
        }

        Map<String, BillingWrappers.BillingInfoSummaryLicense> licenseMap = getLicenseMap(licenses);
        for (QuoteLineItem qli : qlis) {
            if (isSkipQli(qli)) {
                continue;
            }

            String elementID = qli.Product2.ExtID__c;
            BillingWrappers.BillingInfoSummaryLicense license = licenseMap.get(elementID);

            // case delayed terminate
            Integer syncedQuantity = NumberHelper.toNumber(license?.qty);
            BillingWrappers.NGBSLicense[] licenseInfos = licenseInfoCategoriesMap.get(elementID);
            if (licenseInfos != null) {
                for (BillingWrappers.NGBSLicense info : licenseInfos) {
                    if (BooleanHelper.toBoolean(info.scheduledForRemoval)) {
                        syncedQuantity -= info.qty;
                    }
                }
            }

            Boolean isLicenseQtyNotSynced = qli.NewQuantity__c != syncedQuantity;
            if (isLicenseQtyNotSynced) {
                return false;
            }
        }

        return true;
    }

    @TestVisible
    private static Boolean isSkipQli(QuoteLineItem qli) {
        return QuoteLineItemHelper.isOneTime(qli)
            || Product2Helper.isTaxes(qli.Product2)
            || Product2Helper.isTechnical(qli.Product2)
            || qli.IsHiddenLicense__c;
    }

    public static Map<String, BillingWrappers.BillingInfoSummaryLicense> getLicenseMap(
        List<BillingWrappers.BillingInfoSummaryLicense> licenses
    ) {
        Map<String, BillingWrappers.BillingInfoSummaryLicense> licenseMap = new Map<String, BillingWrappers.BillingInfoSummaryLicense>();
        for (BillingWrappers.BillingInfoSummaryLicense license : licenses) {
            licenseMap.put(license.catalogId, license);
        }
        return licenseMap;
    }

    public static Boolean checkUpgradeCCBStatus(Quote qt, BillingWrappers.NGBSAccount ngbsAccount) {
        String packageId = QuoteHelper.getPackageId(qt.Package_Info__c);
        return checkUpgradeStatus(ngbsAccount.getPackageById(packageId), qt);
    }

    public static Boolean checkUpgradeStatus(BillingWrappers.NGBSAccountPackage ngbsPackage, Quote qt) {
        BillingWrappers.QuotePackageInfo pInfo = QuoteHelper.getPackageInfo(qt);
        if (ngbsPackage == null || pInfo?.packageInfo?.catalogId == null) {
            AquivaHelper.throwAquivaException('Failed to check upgrade status');
        }
        Boolean isPackageEqual = pInfo.packageInfo.catalogId == ngbsPackage.catalogId && pInfo.packageInfo.version == ngbsPackage.version;
        Boolean isPackagePlanEqual = pInfo.duration == ngbsPackage.masterDuration;

        return isPackageEqual && isPackagePlanEqual;
    }

    public static Boolean isPackageEqual(BillingWrappers.NGBSAccount ngbsAccount, Quote qt) {
        String packageId = QuoteHelper.getPackageId(qt.Package_Info__c);
        BillingWrappers.NGBSAccountPackage ngbsPackage = ngbsAccount.getPackageById(packageId);
        BillingWrappers.QuotePackageInfo pInfo = QuoteHelper.getPackageInfo(qt);
        if (ngbsPackage == null || pInfo?.packageInfo?.catalogId == null) {
            AquivaHelper.throwAquivaException('Failed to check upgrade status');
        }
        return pInfo.packageInfo.catalogId == ngbsPackage.catalogId && pInfo.packageInfo.version == ngbsPackage.version;
    }

    public static Boolean checkPaidStatus(BillingWrappers.NGBSAccountPackage ngbsPackage) {
        return ngbsPackage.isRegular();
    }

    public static Map<String, String> getLBOBillingExceptions(List<QuoteLineItem> qlis, List<String> bypassLicenses) {
        Map <String, String> exceptionMap = new Map<String, String>();
        List<String> exceptions = new List<String>();

        for (NGBSLBOBillingLimits__c lbl : NGBSLBOBillingLimits__c.getAll().values()) {
            if (lbl.Only_LBO__c) {
                exceptions.addAll(lbl.Categories__c.split(' '));
            }
        }

        for (QuoteLineItem qli : qlis) {
            if (bypassLicenses.contains(qli.Product_Lic_Id__c)) {
                continue;
            }
            BillingWrappers.QLIPackageInfo qliPackage = new BillingWrappers.QLIPackageInfo(qli.PackageInfo__c);
            for (String except : exceptions) {
                if (qliPackage.CategoryCode == except) {
                    exceptionMap.put(qli.Product_Lic_Id__c, except);
                }
            }
        }
        return exceptionMap;
    }

    public static Quote selectQuoteByIdWithExactField(Id quoteId, Schema.SObjectField field) {
        return (Quote) new ListOptional(new QuoteSelector()
            .selectQuoteForSyncWithNGBSByQuoteId(quoteId)
            .withoutSelectorFieldsIncluded()
            .selectField(field)
            .executeQuery()
        ).getFirst();
    }

    public static Quote selectQuoteById(Id quoteId) {
        return (Quote) new ListOptional(new QuoteSelector()
            .selectQuoteForSyncWithNGBSByQuoteId(quoteId)
            .subselect(new ServiceInfoSelector().selectServiceInfo())
            .executeQuery()
        ).getFirst();
    }

    public static void createDownsellCase(SWNDataCollector sdc) {
        if (sdc.syncable.isDownsellCaseCreated()) {
            return;
        }
        List<QuoteLineItem> downsellQliList = filterQuoteLineItems(getDownsellQliList(sdc.qlis));
        Map<String, List<QuoteLineItem>> qliTypesMap = getQliTypesForSimplifiedLBODownsell(sdc.qt, downsellQliList, sdc.costCenters);
        createDownsellCase(sdc.qt, qliTypesMap, sdc.syncable);
    }

    public static void createDownsellCase(Quote qt, Map<String, List<QuoteLineItem>> qliTypesMap, NGBSSyncables.ISyncable syncable) {
        try {
            DealDeskCaseGenerator.createSimplifiedLBODownsellCaseFromQuote(qt, qliTypesMap);
        } catch(Exception e) {
            Platformlog.logException('SyncWithNGBS > createSimplifiedLBODownsellCaseFromQuote: ' + qt.Id, e);
        } finally {
            syncable.setIsDownsellCaseCreated();
        }
    }

    public static Map<String, List<QuoteLineItem>> getQliTypesForSimplifiedLBODownsell(Quote qt, List<QuoteLineItem> downsellQliList, List<Cost_Center__c> costCenters) {
        Map<String, List<QuoteLineItem>> qliTypesMap = new Map<String, List<QuoteLineItem>> {
            DOWNSELL_TYPE_AUTO => new List<QuoteLineItem>(),
            DOWNSELL_TYPE_AUTO_WITH_CASE => new List<QuoteLineItem>(),
            DOWNSELL_TYPE_MANUAL => new List<QuoteLineItem>(),
            DOWNSELL_TYPE_EXCEPTION => new List<QuoteLineItem>()
        };

        if (costCenters != null && !costCenters.isEmpty()) {
            qliTypesMap.get(DOWNSELL_TYPE_EXCEPTION).addAll(downsellQliList);

        } else {
            String billingId = qt.Account.Billing_ID__c;
            String packageId = QuoteHelper.getPackageId(qt.Package_Info__c);

            List<BillingWrappers.BillingInfoSummaryLicense> licenses = NGBSAPI.getNGBSBillingInfoSummaryLicenses(
                billingId,
                packageId,
                false
            );
            Map<String, List<BillingWrappers.BillingInfoSummaryLicense>> licensesMap = getAllLicensesMap(licenses);

            for (QuoteLineItem qli : downsellQliList) {
                List<BillingWrappers.BillingInfoSummaryLicense> licenseList = licensesMap.get(qli.Product2.ExtID__c);

                if (qli.Product2.downsellType__c == product2helper.PRODUCT_DOWNSELL_TYPE_AUTO) {
                    qliTypesMap.get(DOWNSELL_TYPE_AUTO).add(qli);
                } else if (qli.Product2.downsellType__c == product2helper.PRODUCT_DOWNSELL_TYPE_AUTO_WITH_CASE) {
                    qliTypesMap.get(DOWNSELL_TYPE_AUTO_WITH_CASE).add(qli);
                } else if (licenseList != null && licenseList.size() > 1) {
                    qliTypesMap.get(DOWNSELL_TYPE_EXCEPTION).add(qli);
                } else {
                    qliTypesMap.get(DOWNSELL_TYPE_MANUAL).add(qli);
                }
            }
        }

        return qliTypesMap;
    }

    public static List<QuoteLineItem> filterQuoteLineItems(List<QuoteLineItem> quoteLineItems) {
        List<QuoteLineItem> filteredList = new List<QuoteLineItem>();
        for (QuoteLineItem qli : quoteLineItems) {
            if (qli.IsHiddenLicense__c) {
                continue;
            }
            if (HIDDEN_CATEGORIES.contains(qli.Product2.Family)) {
                continue;
            }
            filteredList.add(qli);
        }
        return filteredList;
    }

    public static void syncEntitlements(Id quoteId) {
        SWNDataCollector sdc = new SWNDataCollector(quoteId);
        Map<String, Entitlement__c> entsMap = new Map<String, Entitlement__c>();
        for (QuoteLineItem qli : sdc.qlis) {
            if (qli.Entitlement__c != null) {
                entsMap.put(qli.Product2.ExtID__c, qli.Entitlement__r);
            }
        }

        EntitlementHelper.createEntitlements(entsMap, sdc.qt);

        /* update qlis */
        List<QuoteLineItem> qlis = new List<QuoteLineItem>();
        for (QuoteLineItem qli : sdc.qlis) {
            if (entsMap.get(qli.Product2.ExtID__c) == null) {
                continue;
            }

            qli.Entitlement__c = entsMap.get(qli.Product2.ExtID__c).Id;

            Decimal qty = qli.NewQuantity__c - entsMap.get(qli.Product2.ExtID__c).Quantity__c;
            if (qty == 0) {
                qli.Quantity = 1;
                qli.Zero_Quantity__c = true;
            } else {
                qli.Quantity = qty;
            }

            qlis.add(qli);
        }

        Triggers.switchOff();
        update qlis;
        Triggers.switchOn();
    }

    public static String getCustomValidationMessage(String errorMessage) {
        String message = '';
        if (errorMessage.contains('FIELD_CUSTOM_VALIDATION_EXCEPTION, ')) {
            message = ' Reason for the error: "' + errorMessage.split('FIELD_CUSTOM_VALIDATION_EXCEPTION, ')[1];
            if (message.contains(': [')) {
                message = message.split(': \\[')[0];
            }
            message += '"';
        }
        return message;
    }

    @TestVisible
    private static Map<String, List<BillingWrappers.BillingInfoSummaryLicense>> getAllLicensesMap(
        List<BillingWrappers.BillingInfoSummaryLicense> licenses
    ) {
        Map<String, List<BillingWrappers.BillingInfoSummaryLicense>> licenseMap = new Map<String, List<BillingWrappers.BillingInfoSummaryLicense>>();
        for (BillingWrappers.BillingInfoSummaryLicense license : licenses) {
            if (!licenseMap.containsKey(license.catalogId)) {
                licenseMap.put(license.catalogId, new List<BillingWrappers.BillingInfoSummaryLicense>());
            }
            licenseMap.get(license.catalogId).add(license);
        }

        return licenseMap;
    }

    public static Response getDiscountTemplateGroups(String accountId, String packageId) {
        Response res = new Response();

        String endpoint = NGBSAPI.getDiscountTemplateGroupEndpoint(accountId, packageId);
        HttpResponse response = NGBSAPI.requestNGBS(endpoint, HttpHelper.METHOD_GET);

        if (HttpHelper.isSuccess(response)) {
            try {
                List<NGBS_Discount.DiscountTemplateGroup> dGroups =
                    (List<NGBS_Discount.DiscountTemplateGroup>)
                        JSON.deserialize(response.getBody(), List<NGBS_Discount.DiscountTemplateGroup>.class);
                res.setData('result', dGroups);
            } catch(Exception e) {
                res.error(e);
            }
        } else {
            res.error('Error', 'An error occurred during getting discount template groups');
        }

        return res;
    }

    public static String getContractSyncStatus(NGBSSyncables.ISyncable syncable, Quote qt) {
        String result = NOT_SYNCED;

        List<BillingWrappers.QuotePackageInfo> pInfos =
            (List<BillingWrappers.QuotePackageInfo>)
                JSON.deserialize(qt.Package_Info__c, List<BillingWrappers.QuotePackageInfo>.class);
        BillingWrappers.QuotePackageInfo pInfo = pInfos[0];

        if (pInfo.contract == null || String.isBlank(pInfo.contract.extId)) {
            result = SKIPPED;
        }

        if (syncable.isContractsSynced()) {
            result = SYNCED;
        }

        if (syncable.isContractsSynced() && syncable.isResyncContractAllowed()) {
            result = RESYNC;
        }
        return result;
    }

    public static Boolean isContractWasDeselected(Quote qt, List<BillingWrappers.BillingContract> billingContracts) {
        return !isContractExistInSF(qt) && isContractExistInBilling(billingContracts);
    }

    public static Boolean isContractExistInSF(Quote quote) {
        return QuoteHelper.getNGBSContract(quote) != null;
    }

    public static Boolean isPackagePlanEqual(BillingWrappers.NGBSAccount ngbsAccount, Quote qt) {
        String packageId = QuoteHelper.getPackageId(qt.Package_Info__c);
        BillingWrappers.NGBSAccountPackage ngbsPackage = ngbsAccount.getPackageById(packageId);
        BillingWrappers.QuotePackageInfo pInfo = QuoteHelper.getPackageInfo(qt);
        if (ngbsPackage == null || pInfo == null) {
            AquivaHelper.throwAquivaException('Failed to check change plan status');
        }
        return pInfo.duration == ngbsPackage.masterDuration;
    }

    public static Boolean isLBOOrOfficeProductSelected(Quote qt) {
        return  BooleanHelper.toBoolean(qt?.Enabled_LBO__c) || QuoteHelper.isOffice(qt)  || QuoteHelper.isEventsService(qt);
    }

    public static List<QuoteLineItem> getQlisForAutoDownsell(Map<String, List<QuoteLineItem>> qliTypesMap) {
        List<QuoteLineItem> qlisForAutoDownsell = new List<QuoteLineItem>();
        if (qliTypesMap.containsKey(DOWNSELL_TYPE_AUTO)) {
            qlisForAutoDownsell.addAll(qliTypesMap.get(DOWNSELL_TYPE_AUTO));
        }
        if (qliTypesMap.containsKey(DOWNSELL_TYPE_AUTO_WITH_CASE)) {
            qlisForAutoDownsell.addAll(qliTypesMap.get(DOWNSELL_TYPE_AUTO_WITH_CASE));
        }
        return qlisForAutoDownsell;
    }

    @TestVisible
    private static Boolean isContractExistInBilling(List<BillingWrappers.BillingContract> billingContracts) {
        if (billingContracts == null || billingContracts.isEmpty()) {
            return false;
        }

        for (BillingWrappers.BillingContract contract : billingContracts) {
            if (contract.isActiveContract()) {
                return true;
            }
        }

        return false;
    }

    @TestVisible
    private static void stopSyncUpsell(Quote qt, List<BillingWrappers.BillingInfoSummaryLicense> licenses, Response res) {
        for (BillingWrappers.BillingInfoSummaryLicense license : licenses) {
            for (QuoteLineItem qli : qt.QuoteLineItems) {
                if (qli.Product_Lic_Id__c != license.catalogId || !(qli.NewQuantity__c > license.qty)) {
                    continue;
                }

                handleError(res, CaseHelper.CASE_REASON_UPSELL, 'Licenses are not synced with Service Web. Licenses should be added manually in Service Web.');
                return;
            }
        }
    }

    @TestVisible
    private static void stopSyncDownsell(Quote qt, String billingId, String packageId, Response res) {
        Map <String, Integer> aggregatedLicensesCounter = new Map <String, Integer>();

        if (qt.QuoteLineItems.isEmpty() || !(qt.CountOfDownsellQLI__c > 0)) {
            return;
        }

		// Build existing license catalogId set from summary/license
		String summaryPostBody = '{"fields":{"scheduledForRemoval":true,"price":true,"dateRange":true,"discountValue":["Unit","Value"]}}';
		List<BillingWrappers.BillingInfoSummaryLicense> summaryLicenses = NGBSAPI.getNGBSBillingInfoSummaryLicenses(
			billingId,
			packageId,
			null,
			summaryPostBody
		);
        Map<String,BillingWrappers.BillingInfoSummaryLicense> summaryLicenseByCatalogId = new Map<String,BillingWrappers.BillingInfoSummaryLicense>();
		for (BillingWrappers.BillingInfoSummaryLicense l : summaryLicenses) {
            summaryLicenseByCatalogId.put(l.catalogId,l);
        }

        List<BillingWrappers.LicensesCounterResponse> licensesCounter =
            (List<BillingWrappers.LicensesCounterResponse>) NGBSAPI.getLicenseCounters(
                billingId,
                packageId,
                getLicensesRequestBody(qt.QuoteLineItems)
            ).data.get(LICENSE_COUNTER);

        if (licensesCounter.isEmpty()) {
            return;
        }

        for(BillingWrappers.LicensesCounterResponse lcr : licensesCounter) {
            if (!aggregatedLicensesCounter.containsKey(lcr.catalogId)) {
                aggregatedLicensesCounter.put(lcr.catalogId, lcr.batchQty + lcr.instanceQty);
            } else {
                aggregatedLicensesCounter.put(lcr.catalogId, lcr.batchQty + lcr.instanceQty + aggregatedLicensesCounter.get(lcr.catalogId));
            }
        }
        for (BillingWrappers.LicensesCounterResponse lcr : licensesCounter) {
            for (QuoteLineItem qli : qt.QuoteLineItems) {
				if (isStopSync(qli, summaryLicenseByCatalogId, lcr, aggregatedLicensesCounter) && qli.ServiceName__c!=Constants.CONST_RC_EVENT) {
                    handleError(res, CaseHelper.CASE_REASON_DOWNSELL, Label.Licenses_Should_Be_Removed_Manually);
                    return;
                }else if(qli.ServiceName__c==Constants.CONST_RC_EVENT){
                    res.setData(STOP_AUTO_SYNC, true);
                    return;
                }
            }
        }
    }

    @TestVisible
    private static List<BillingWrappers.LicensesRequestBody> getLicensesRequestBody(List<QuoteLineItem> qlis) {
        List<BillingWrappers.LicensesRequestBody> licensesRequestBody = new List<BillingWrappers.LicensesRequestBody>();
        if (qlis.isEmpty()) {
            return licensesRequestBody;
        }

        for (QuoteLineItem qli : qlis) {
            BillingWrappers.LicensesRequestBody lrb = new BillingWrappers.LicensesRequestBody(qli.Product_Lic_Id__c);
            licensesRequestBody.add(lrb);
        }
        return licensesRequestBody;
    }

    private static void stopSyncUpgrade(
        Quote qt,
        String packageId,
        List<BillingWrappers.BillingInfoSummaryLicense> licenses,
        Response res,
        BillingWrappers.NGBSAccount ngbsAcc
    ) {
        BillingWrappers.NGBSAccountPackage ngbsPackage = ngbsAcc.getPackageById(packageId);
        BillingWrappers.QuotePackageInfo packageInfo = BillingWrappers.parseQuotePackageInfo(qt.Package_Info__c);
        if (QuoteHelper.isNGBSPlanChange(qt, qt.QuoteLineItems)
            && licenses != null
            && !licenses.isEmpty()
        ) {
            for (BillingWrappers.BillingInfoSummaryLicense license : licenses) {
                if (license.billingCycleDuration == packageInfo.duration || license.catalogId != Product2Helper.SUBSCRIPTION_LICENSE) {
                    continue;
                }

                handleError(res, CaseHelper.CASE_REASON_PLAN_CHANGED, 'Package is not upgraded. Upgrade account before proceeding');
                break;
            }
        }

        if (!QuoteHelper.isNGBSPackageChange(qt, qt.QuoteLineItems) || packageInfo.id == ngbsPackage?.catalogId) {
            return;
        }

        handleError(res, CaseHelper.CASE_REASON_PACKAGE_CHANGED, 'Package is not upgraded. Upgrade account before proceeding');
    }

    private static void handleError(Response res, String caseReason, String message) {
        res.setData(CASE_REASON, caseReason);
        res.setData(STOP_AUTO_SYNC, true);
        res.error('Error', message);
    }

    private static Boolean isStopSync(
        QuoteLineItem qli,
		Map<String, BillingWrappers.BillingInfoSummaryLicense> summaryLicenseByCatalogId,
        BillingWrappers.LicensesCounterResponse lcr,
        Map <String, Integer> aggregatedLicensesCounter
    ) {
        return qli.isDownsell__c && qli.Product_Lic_Id__c == lcr.catalogId
            && !NGBSOrderRequest.TECHNICAL_SUBLICENSES.contains(lcr.catalogId)
            && !NGBSOrderRequest.isTechnicalLicense(qli)
            && !getLicenseIdsToSkipForCheckQuantity().contains(qli.Product_Lic_Id__c)
            && qli.Product_Lic_Id__c != Product2Helper.ELEMENT_ID_GLOBAL_OFFICE
			&& summaryLicenseByCatalogId.get(qli.Product_Lic_Id__c) != null
			&& (summaryLicenseByCatalogId.get(qli.Product_Lic_Id__c).scheduledForRemoval == null || !summaryLicenseByCatalogId.get(qli.Product_Lic_Id__c).scheduledForRemoval)
            && Integer.valueOf(qli.NewQuantity__c) != aggregatedLicensesCounter.get(lcr.catalogId);
    }

    @TestVisible
    private static List<String> getLicenseIdsToSkipForCheckQuantity() {
        List<String> licenseIdsToSkipForCheckQuantity = new List<String>();
        for (NGBSHiddenLicenses__c configRecord : NGBSHiddenLicenses__c.getAll().values()) {
            if (!configRecord.SkipQuantityValidationInSync__c || configRecord.LicenseElementId__c == null) {
                continue;
            }

            List<String> splitValues = configRecord.LicenseElementId__c.split(SettingsService.ITEM_DELIMITER);
            for (String value : splitValues) {
                licenseIdsToSkipForCheckQuantity.add(value.trim());
            }
        }

        return licenseIdsToSkipForCheckQuantity;
    }

    private static List<Cost_Center__c> selectCostCenters(Quote qt) {
        if (qt == null) {
            return new List<Cost_Center__c>();
        }

        Id quoteIdForCostCenters = qt.IsMultiProductTechnicalQuote__c ? qt.MasterQuote__c : qt.Id;
        return new CostCenterSelector().selectCostCentersForSyncWithNGBSByQuoteId(quoteIdForCostCenters).executeQuery();
    }


    public static Response processDiscounts_new(
        Quote qt,
        List<BillingWrappers.BillingContract> billingContracts,
        String billingId,
        String billingPackageId
    ) {
        Response discountResp = new Response();
        Response dtgRes = SWNHelper.getDiscountTemplateGroups(billingId, billingPackageId);
        if (!dtgRes.isSuccess()) {
            return dtgRes;
        }

        List<NGBS_Discount.DiscountTemplateGroup> dGroups = (List<NGBS_Discount.DiscountTemplateGroup>) dtgRes.data.get(RESULT);
        BillingWrappers.QuotePackageInfo pInfo = QuoteHelper.getPackageInfo(qt);
        String targetCatalogId = pInfo.packageInfo.catalogId;
        String targetVersion = pInfo.packageInfo.version;
        String chargeTerm = pInfo.duration;

        List<NGBS_Discount.DiscountTemplateGroup> filteredDTG = SWNHelper.filterDiscountTemplates_new(
            dGroups,
            targetCatalogId,
            targetVersion,
            chargeTerm
        );

        /* recreate current DTGs and create new one or update current highest DTG */
        SWNMessageHelper.CompositeResult applyResult = SWNSyncDiscountRunner.applyNewDiscounts(
            qt,
            pInfo,
            ContractRestAPI.selectContract(pInfo),
            billingContracts,
            billingPackageId,
            filteredDTG,
            dGroups
        );
        String status = applyResult.baseMessage.status;
        String header = applyResult.baseMessage.header;
        String message = applyResult.baseMessage.message;

        if (status == Response.STATUS_ERROR) {
            discountResp.error(header, message);
            return discountResp;
        }
        if (status == Response.STATUS_INFO) {
            discountResp.info(header, message);
        }
        if (status == Response.STATUS_SUCCESS) {
            discountResp.addMessage(header, message, Response.STATUS_SUCCESS);
        }

        SWNMessageHelper.CompositeResult deleteResult = SWNSyncDiscountRunner.deleteDiscounts_new(filteredDTG, billingId, billingPackageId, null);

        if (deleteResult.baseMessage.status == Response.STATUS_ERROR) {
            discountResp.warning(deleteResult.baseMessage.header, deleteResult.baseMessage.message);
        }

        return discountResp;
    }
}