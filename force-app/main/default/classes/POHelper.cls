public with sharing class POHelper {
    private static Boolean isMultiProductTeamMember =
        FeatureManagement.checkPermission(CustomPermissionHelper.PERMISSION_ENABLE_MULTI_PRODUCT);
    public static Boolean isAllowProcessOrderWithoutShipping =
        FeatureManagement.checkPermission(CustomPermissionHelper.PERMISSION_SKIP_SHIPPING_VALIDATION);

    public static Boolean isMultiproductEnabled = SettingsHelper.FEATURE_TOGGLE.EnableMultiProduct__c
        || isMultiProductTeamMember;
    public static Boolean isSimplifiedLboDownsellEnabled = SettingsHelper.FEATURE_TOGGLE.EnableSimplifiedLBODownsell__c;
    public static Boolean isEngageUILessSettingsOn = SettingsHelper.FEATURE_TOGGLE.EnableUILessProcessOrderEngage__c
        && isMultiproductEnabled;

    @TestVisible
    private final static String SIGNUP_RUNNER_NOT_FOUND = 'There is no SignUp flow specified for QuoteId = {0}';

    public static final Set<String> UNSUPPORTED_BRANDS = new Set<String> {
        RingCentralHelper.BRAND_VODAFONE,
        RingCentralHelper.BRAND_ATTOFFICE,
        RingCentralHelper.BRAND_VERIZON,
        RingCentralHelper.BRAND_BIZDUMMY
    };

    public static Response queryData(List<String> targetIds) {
        Set<Id> targetIdSet = new Set<Id>();
        for (String targetId : targetIds) {
            targetIdSet.add(targetId);
        }

        PODataCollector dataCollector = isMPUBFlow(targetIdSet)
            ? new PODataCollector.OrderBasedDC(targetIdSet).collectData()
            : new PODataCollector.QuoteBasedDC(targetIdSet).collectData();

        Response result = new Response();
        result.setData('services', dataCollector.transformData());

        return result;
    }

    public static Response validateData(POWrappers.SignUpParams[] dataArr) {
        return ProcessOrderValidator.validate(dataArr);
    }

    public static Response createDealDeskCaseDescriptions(POWrappers.SignUpParams[] dataArr) {
        Response res = new Response();

        try {
            List<DealDeskCaseDescription__c> dealDeskDescriptionsToInsert = new List<DealDeskCaseDescription__c>();

            for (POWrappers.SignUpParams data : dataArr) {
                Quote qt = (Quote) data.targetQuote;
                dealDeskDescriptionsToInsert.addAll(DealDeskCaseDescriptionHelper.handleDealDeskCaseDescriptionsForSignUp(qt));
            }

            if (!dealDeskDescriptionsToInsert.isEmpty()) {
                insert dealDeskDescriptionsToInsert;
            }
        } catch (Exception e) {
            res.error(
                Label.Opportunity_SignUp_Validation_SignUp_failed,
                e.getMessage() + ': ' + e.getStackTraceString()
            );
        }

        return res;
    }

    public static Response executePreSignUpActions(POWrappers.SignUpParams[] dataArr) {
        Response resp = new Response();
        Id oppId;
        try {
            List<Account> accsToUpdate = new List<Account>();
            set<id> targetIds = new set<id>();
            for (POWrappers.SignUpParams data : dataArr) {
                if (QuoteHelper.isOffice(data.targetQuote)
                    || QuoteHelper.isMeetings(data.targetQuote)
                    || !SettingsHelper.FEATURE_TOGGLE.EnableUILessProcessOrderEngage__c
                    || QuoteHelper.isProServService(data.targetQuote)
                    || QuoteHelper.isEvents(data.targetQuote)
                ) {
                    oppId = data.opportunity.Id;
                    targetIds.add(data.targetQuote.Id);
                    targetIds.add(data.targetQuote.MasterQuote__c);
                }
                Account account = PresignUpActions.prepopulateAccountFields(data);
                data.opportunity.Account.Funnel_not_supported__c = account.Funnel_not_supported__c;
                if (account.Internal_Enterprise_Account_ID__c != null) {
                    data.opportunity.Account.Internal_Enterprise_Account_ID__c = account.Internal_Enterprise_Account_ID__c;
                }

                if (!HelperUtils.isSObjectInList(account, accsToUpdate)) {
                    accsToUpdate.add(account);
                }
            }
            update accsToUpdate;

            List<Approval__c> techTaxExemptApprovals = PresignUpActions.getTaxExemptsOnProcessOrder(dataArr);
            insert techTaxExemptApprovals;

            if (oppId != null) {
                PresignUpActions.upsertFunnelStatus(targetIds, oppId);
            }

            resp.setData('updatedData', dataArr);
        } catch (Exception e) {
            if (oppId != null) {
                PresignUpActions.deleteSalesFunnelStatusRecord(oppId);
            }
            resp.addMessage(
                Label.Opportunity_SignUp_Validation_SignUp_failed,
                e.getMessage() + ' ** ' + e.getStackTraceString(),
                Response.SEVERITY_ERROR
            );
        }

        return resp;
    }

    public static Response signUpNGBS(POWrappers.SignUpParams data) {
        POSignUp.SignUpRunner runner = createSignUpRunner(data);
        Response resp = runner.signUp();

        //TODO: Create new action = 'executePostSignUpActions' for ProcessOrder.handleSignUp method
        // and call NGBS_Discount.syncDiscountsForELA(data.targetQuote) there
        NGBS_Discount.syncDiscountsForELA(data.targetQuote);
        return resp;
    }

    public static Response previewSignUpBody(POWrappers.SignUpParams data) {
        POSignUp.SignUpRunner runner = createSignUpRunner(data);
        Response resp = new Response();
        resp.setData('signupBody', runner.getRequestBody());
        return resp;
    }

    public static Response validateProcessOrder(POWrappers.SignUpParams data) {
        Response resp = new Response();
        Validator signUpProfileValidator = new QuoteValidator.SignUp_ProfileValidator(data?.targetQuote);
        Validator syncWithNGBSProfileValidator = new QuoteValidator.SyncWithNGBS_ProfileValidator(data?.targetQuote);
        Validator proServeProfileValidator = new QuoteValidator.SignUp_ProserveProfileValidator(data?.targetQuote,true);
        List<Validator> validators = new List<Validator> {
            QuoteHelper.isNewBusinessPO(data?.targetQuote) ? signUpProfileValidator : syncWithNGBSProfileValidator,
            proServeProfileValidator
        };
        resp = new HelperUtils.BaseValidator(validators).validate(resp);

        return resp;
    }

    public static Response updateMasterOpportunityRCCCSyncStatus(POWrappers.ActionRequestParams params) {
        Triggers.switchOff();
        Response resp = new Response();

        try {
            Opportunity opp = params.data.opportunity;
            update new Opportunity(
                Id = opp.MasterOpportunity__c ?? opp.Id,
                RCCCSyncStatus__c = params.rcccSyncStatus
            );
        } catch (Exception e) {
            resp.error(e.getMessage(), e.getStackTraceString());
        }

        Triggers.switchOn();
        return resp;
    }

    public static List<QuoteLineItem> getQuoteLineItemsWithAddressAssignment(Quote qt) {
        List<QuoteLineItem> qlisForShipping = new List<QuoteLineItem>();
        Boolean hasShippableDevice = false;
        for (QuoteLineItem qli : qt.QuoteLineItems) {
            Boolean isShippingAvailableForLicense = Product2Helper.isShippingTypeAuto(qli.Product2);
            if (!qli.Zero_Quantity__c && qli.Quantity > 0 && isShippingAvailableForLicense) {
                hasShippableDevice = true;
                break;
            }
        }

        if (hasShippableDevice) {
            qlisForShipping = (List<QuoteLineItem>) new QuoteLineItemSelector()
                .selectQuoteLineItemsByQuoteIdsForShipping(new List<Object>{new Set<Id>{qt.Id}})
                .executeQuery();
        }

        return qlisForShipping;
    }
    public static String getQuotePaymentMethodType(String paymentMethod) {
        String paymentMethodType = '';

        if (QuoteHelper.PAYMENT_METHOD_INVOICE.equalsIgnoreCase(paymentMethod)) {
            paymentMethodType = POWrappers.PAYMENT_METHOD_INV_FUNNEL;
        } else if (QuoteHelper.PAYMENT_METHOD_INVOICE_ON_BEHALF.equalsIgnoreCase(paymentMethod)) {
            paymentMethodType = POWrappers.PAYMENT_METHOD_INV_BOB_FUNNEL;
        } else if (QuoteHelper.PAYMENT_METHOD_CREDIT_CARD.equalsIgnoreCase(paymentMethod)) {
            paymentMethodType = POWrappers.PAYMENT_METHOD_CC_FUNNEL;
        } else if (QuoteHelper.PAYMENT_METHOD_WHOLESALE.equalsIgnoreCase(paymentMethod)) {
            paymentMethodType = POWrappers.PAYMENT_METHOD_WHOLESALE_FUNNEL;
        } else if (QuoteHelper.PAYMENT_METHOD_DIRECT_DEBIT.equalsIgnoreCase(paymentMethod) &&
            SettingsHelper.FEATURE_TOGGLE.Enable_Direct_Debit_as_a_payment_method__c) {
            paymentMethodType = POWrappers.PAYMENT_METHOD_DD_FUNNEL;
        }

        return paymentMethodType;
    }
    public static String getAccountPaymentMethodType(String paymentMethod, Opportunity opp) {
        if (AccountHelper.PAYMENT_METHOD_INVOICE.equalsIgnoreCase(paymentMethod)) {
            return POWrappers.PAYMENT_METHOD_INV_FUNNEL;
        }
        if (AccountHelper.PAYMENT_METHOD_INVOICE_ON_BEHALF.equalsIgnoreCase(paymentMethod)) {
            return POWrappers.PAYMENT_METHOD_INV_BOB_FUNNEL;
        }
        if (AccountHelper.PAYMENT_METHOD_WHOLESALE.equalsIgnoreCase(paymentMethod)) {
            return POWrappers.PAYMENT_METHOD_WHOLESALE_FUNNEL;
        }
        if (AccountHelper.PAYMENT_METHOD_DIRECT_DEBIT.equalsIgnoreCase(paymentMethod)) {
            return AccountHelper.PAYMENT_METHOD_NONE;
        }

        if (OpportunityHelper.isAvaya(opp) ||
            OpportunityHelper.isAtos(opp) ||
            OpportunityHelper.isRainbow(opp) ||
            OpportunityHelper.isRcEuropeBrand(opp)
        ) {
            return AccountHelper.PAYMENT_METHOD_NONE;
        }

        return POWrappers.PAYMENT_METHOD_CC_FUNNEL;
    }
    public static Response validateBillingAddress(BillingWrappers.RequestSubmitParams params) {
        Response resp = new Response();

        if (OpportunityHelper.TIER_RC_CONTACT_CENTER.equalsIgnoreCase(params.tier)) {
            resp.setData(ICBAPI.validateBillingAddress(params.data.billingAddress));
        }

        if (OpportunityHelper.ENGAGE_TIERS.contains(params.tier)) {
            resp.setData(CCBAPI.validateBillingAddress(params.data.billingAddress));
        }

        return resp;
    }

    public static Map<Id, POWrappers.SyncableWrapper> buildQtIdToSyncInfo(POWrappers.OppDetailWrapper oppWrapper) {
        Map<Id, POWrappers.SyncableWrapper> qtIdToSyncInfo = new Map<Id, POWrappers.SyncableWrapper>();
        for (Quote qt : oppWrapper.masterAndTechQuotes) {
            if (QuoteHelper.isQuotePackageInfoHasMultipleProducts(qt) || QuoteHelper.isProServOrCCProServ(qt)) {
                continue;
            }
            NGBSSyncables.ISyncable syncable = NGBSSyncables.getSyncable(oppWrapper.isMPUB, qt.Id);
            POWrappers.SyncableWrapper syncableWrapper = new POWrappers.SyncableWrapper();
            syncableWrapper.syncInfo = syncable.getSyncInfoField();
            syncableWrapper.isSyncedToICB = syncable.isSyncedToICB();
            syncableWrapper.isICBProvisioningComplete = syncable.isICBProvisioningComplete();
            qtIdToSyncInfo.put(qt.Id, syncableWrapper);
        }

        return qtIdToSyncInfo;
    }

    public static Map<String, Object> buildProductNameToPackageIsActiveStatusMap(
        POWrappers.OppDetailWrapper oppWrapper,
        BillingWrappers.NGBSAccount accountInfo
    ) {
        Map<String, Object> productNameToPackageIsActiveStatusMap = new Map<String, Object>();

        if (accountInfo?.packages == null) {
            return productNameToPackageIsActiveStatusMap;
        }

        Map<String, Map<String, Object>> productToQuoteTypeStatus = new Map<String, Map<String, Object>>();

        for (Quote qt : oppWrapper.masterAndTechQuotes) {
            if (QuoteHelper.isProServOrCCProServ(qt)) {
                continue;
            }

            if (
                qt.ServiceName__c == QuoteHelper.NGBS_PROFESSIONAL_SERVICES_PRODUCT
                    && qt.IsMultiProductTechnicalQuote__c
                    && String.isBlank(qt.BillingPackage__c)
            ) {
                continue;
            }

            BillingWrappers.QuotePackageInfoWrapper pInfoWrapper = new BillingWrappers.QuotePackageInfoWrapper(qt.Package_Info__c);
            if (pInfoWrapper.isMP()) {
                continue;
            }

            String productName = pInfoWrapper.getPackageInfo().productName;
            String offerType = pInfoWrapper.getPackageInfo().offerType;
            String quoteType = (offerType == 'POC' || offerType == QuoteHelper.PACKAGE_OFFER_TYPE_POC) ? POWrappers.QUOTE_TYPE_POC_SIGNED_UP : POWrappers.QUOTE_TYPE_SALES_SIGNED_UP;
            if (!productToQuoteTypeStatus.containsKey(productName)) {
                productToQuoteTypeStatus.put(productName, new Map<String, Object>{
                    POWrappers.QUOTE_TYPE_SALES_SIGNED_UP => false,
                    POWrappers.QUOTE_TYPE_POC_SIGNED_UP => false,
                    POWrappers.QUOTE_TYPE_SALES_STATUS => null,      
                    POWrappers.QUOTE_TYPE_POC_STATUS => null        
                });
            }
            Boolean isSignedUp = false;
            String packageStatus = null;
            
            if (oppWrapper.isMPUB) {
                String statusResult = checkMPUBSignUpStatusDetailed(pInfoWrapper.getPackageInfo(), accountInfo.packages);
                isSignedUp = statusResult.equals(POWrappers.PACKAGE_STATUS_ACTIVE); 
                packageStatus = statusResult.equals(POWrappers.PACKAGE_STATUS_NOT_SIGNED_UP) ? null : statusResult; 
            } else {
                isSignedUp = checkMPLSignUpStatus(qt);
                packageStatus = isSignedUp ? POWrappers.PACKAGE_STATUS_ACTIVE : null; 
            }
            
            productToQuoteTypeStatus.get(productName).put(quoteType, isSignedUp);
            
            String statusKey = quoteType.replace(POWrappers.SIGNED_UP_SUFFIX, POWrappers.STATUS_SUFFIX); 
            productToQuoteTypeStatus.get(productName).put(statusKey, packageStatus);
        }

        for (String productName : productToQuoteTypeStatus.keySet()) {
            Map<String, Object> quoteTypeStatus = productToQuoteTypeStatus.get(productName);
            productNameToPackageIsActiveStatusMap.put(productName, quoteTypeStatus);
        }

        System.debug(' @Final productNameToPackageIsActiveStatusMap: ' + productNameToPackageIsActiveStatusMap);
        return productNameToPackageIsActiveStatusMap;
    }

    private static void hanldeMPLFlow(Quote qt, Map<String, Boolean> productNameToPackageIsActiveStatusMap) {
        productNameToPackageIsActiveStatusMap.put(qt.Opportunity.Tier_Name__c, String.isNotBlank(qt.Account.Billing_ID__c));
    }

    @TestVisible
    private static void handleMPUBFlow(
        BillingWrappers.QuotePackageInfo pInfo,
        List<BillingWrappers.NGBSAccountPackage> packages,
        Map<String, Boolean> productNameToPackageIsActiveStatusMap
    ) {
        for (BillingWrappers.NGBSAccountPackage accPackage : packages) {
            String tierName = pInfo.productName;
            Boolean isNewProductNameMatchWithAccPkgName = accPackage.product.equalsIgnoreCase(tierName);
            // If the product name is changed, we need to check the old product name as well for cross-upgrade/downgrade cases
            Boolean isOldProductNameMatchWithAccPkgName = accPackage.product.equalsIgnoreCase(pInfo.existingPackageInfo?.productName);
            Boolean isOfferTypeMatch = accPackage.offerType.equalsIgnoreCase(pInfo.offerType);
            Boolean isPOCToPaid = QuoteHelper.PACKAGE_OFFER_TYPE_POC.equalsIgnoreCase(accPackage.offerType) && isNewProductNameMatchWithAccPkgName;
           
            if ((isNewProductNameMatchWithAccPkgName || isOldProductNameMatchWithAccPkgName)
                && (isOfferTypeMatch || isPOCToPaid)
            ) {
                productNameToPackageIsActiveStatusMap.put(tierName, isPackageActive(accPackage, tierName));
            }
        }
    }

    @TestVisible
    private static Boolean isPackageActive(BillingWrappers.NGBSAccountPackage accPackage, String tierName) {
        // For RingCentral Contact Center we should check if package is active
        // For other services presence of relevant package in NGBS is enough
        Boolean isRCCC = OpportunityHelper.TIER_RC_CONTACT_CENTER.equalsIgnoreCase(tierName);
        return !isRCCC || accPackage.isActive();
    }

    // Helper method to check MPUB sign-up status for a specific quote type (detailed - returns actual status)
    private static String checkMPUBSignUpStatusDetailed(BillingWrappers.QuotePackageInfo pInfo, List<BillingWrappers.NGBSAccountPackage> packages) {
        for (BillingWrappers.NGBSAccountPackage accPackage : packages) {
            String tierName = pInfo.productName;
            Boolean isNewProductNameMatchWithAccPkgName = accPackage.product.equalsIgnoreCase(tierName);
            Boolean isOldProductNameMatchWithAccPkgName = accPackage.product.equalsIgnoreCase(pInfo.existingPackageInfo?.productName);
            Boolean isOfferTypeMatch = accPackage.offerType.equalsIgnoreCase(pInfo.offerType) ||
                (isPOCOfferType(accPackage.offerType) && isPOCOfferType(pInfo.offerType));
            System.debug('@AccountPackage--> '+JSON.serialize(accPackage));
            if ((isNewProductNameMatchWithAccPkgName || isOldProductNameMatchWithAccPkgName) && isOfferTypeMatch) {
                if (POWrappers.PACKAGE_STATUS_ACTIVE.equalsIgnoreCase(accPackage.status)) {
                    return POWrappers.PACKAGE_STATUS_ACTIVE;
                } else if (POWrappers.PACKAGE_STATUS_INITIAL.equalsIgnoreCase(accPackage.status)) {
                    return POWrappers.PACKAGE_STATUS_INITIAL;
                }
            }
        }
        return POWrappers.PACKAGE_STATUS_NOT_SIGNED_UP;
    }
    
    // Helper method to check if an offer type represents POC
    private static Boolean isPOCOfferType(String offerType) {
        return offerType == 'POC' || offerType == QuoteHelper.PACKAGE_OFFER_TYPE_POC;
    }

    // Helper method to check MPL sign-up status for a specific quote type
    private static Boolean checkMPLSignUpStatus(Quote qt) {
        return String.isNotBlank(qt.Account.Billing_ID__c);
    }

    @TestVisible
    private static POSignUp.SignUpRunner createSignUpRunner(POWrappers.SignUpParams data) {
        Quote qt = data?.targetQuote;

        POSignUp.SignUpRunner runner;
        if (QuoteHelper.isOffice(qt) || QuoteHelper.isMeetings(qt)) {
            runner = new POSignUp.MVPSignUpRunner(data);
        } else if (QuoteHelper.isProServService(qt)) {
            runner = new POSignUp.ProServSignUpRunner(data);
        } else if (QuoteHelper.isEngage(qt)) {
            runner = new POSignUp.EngageSignUpRunner(data);
        } else if (QuoteHelper.isRCCC(qt)) {
            if (data.isExistingBusiness) {
                runner = new POSignUp.RCCCSyncRunner(data);
            } else {
                runner = new POSignUp.RCCCSignUpRunner(data);
            }
        } else if (QuoteHelper.isFax(qt)) {
            runner = new POSignUp.FaxSignUpRunner(data);
        } else if (QuoteHelper.isEvents(qt)) {
            runner = new POSignUp.EventsSignUpRunner(data);
        } else {
            AquivaHelper.throwAquivaException(String.format(SIGNUP_RUNNER_NOT_FOUND, new List<Object> { qt.Id }));
        }

        return runner;
    }
    @TestVisible
    private static Boolean isMPUBFlow(Set<Id> targetIdSet) {
        for (Quote qt : (List<Quote>) new QuoteSelector()
            .selectQuotesForMultiSignUp(targetIdSet)
            .executeQuery()
        ) {
            if (!qt.ServiceInfo__r.isEmpty()) {
                return true;
            }
        }
        return false;
    }

    public static SubscriberInfoBuilder.AssignmentData[] filterProductsForManualOrderType(String businessIdentity, SubscriberInfoBuilder.AssignmentData[] assignmentData) {
        List<SubscriberInfoBuilder.AssignmentData> filteredList = new List<SubscriberInfoBuilder.AssignmentData>();
        List<LicensesLabelsOverride__c> licensesLabelsOverrideSettings = Product2Helper.getLicensesLabelsOverridesForBusinessIdentity(businessIdentity);

        for (SubscriberInfoBuilder.AssignmentData ad : assignmentData) {
            if (!Product2Helper.isInitialOrderTypeManual(ad.parent.Product2, licensesLabelsOverrideSettings)) {
                if (Product2Helper.isInitialOrderTypeManual(ad.child.Product2, licensesLabelsOverrideSettings)) {
                    ad.child = null;
                }
                filteredList.add(ad);
            }
        }
        return filteredList;
    }

    public static String buildLimitParam(String mark, String limitType, Integer index, String propertyName) {
        return index != null
            ? String.format('{0}{1}[{2}][{3}]=', new List<Object> { mark, limitType, index, propertyName })
            : String.format('{0}{1}[{2}]=', new List<String> { mark, limitType, propertyName });
    }

    public static Response checkIsMainCostCenterExist(String billingId) {
        Response resp = new Response();
        HttpResponse costCentersResponse = NGBSAPI.checkIsMainCostCenterExist(billingId);
        String costCentersResponseBody = '';
        costCentersResponseBody = costCentersResponse.getBody();
        List<BillingWrappers.CostCenter> costCenters = (List<BillingWrappers.CostCenter>) JSON.deserialize(costCentersResponseBody, List<BillingWrappers.CostCenter>.class);
        Boolean isMainCostCenterExist = !costCenters.isEmpty();
        resp.setData('isMainCostCenterExist', isMainCostCenterExist);
        return resp;
    }

    public static Response createMainCostCenter(String billingId) {
        Response resp = new Response();
        HttpResponse costCentersResponse = NGBSAPI.createMainCostCenter(billingId);
        Boolean isMainCostCenterCreated = costCentersResponse.getStatus() == 'Created';
        resp.setData('isMainCostCenterCreated', isMainCostCenterCreated);
        return resp;
    }
}