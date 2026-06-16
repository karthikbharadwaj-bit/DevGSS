public without sharing class DQServiceHelper {

    public static final String REVISION_PENDING_STATUS = 'Revision Pending';
    public static final String PENDING_APPROVAL_STATUS = 'Pending Approval';
    public static final String APPROVED_STATUS = 'Approved';

    private static final Map<String, Schema.RecordTypeInfo> RT_INFO_BY_NAME = DQ_Deal_Qualification_Discounts__c.SObjectType
        .getDescribe()
        .getRecordTypeInfosByName();
    public static final Id DQ_CC_RECORD_TYPE_ID = RT_INFO_BY_NAME.get('Contact Center').RecordTypeId;
    public static final Id DQ_SALES_RECORD_TYPE_ID = RT_INFO_BY_NAME.get('Sales Quote').RecordTypeId;
    public static final String DEFAULT_CC_CATEGORY = 'Default Contact Center';

    public static final String FREE_SHIPPING_OPTION = 'Free Shipping';
    public static final String OVERNIGHT_OPTION = 'Overnight';
    public static final String TWO_DAY_OPTION = '2 Day';

    public static final List<String> SHIPPING_OPTIONS = new List<String>{
        QuoteHelper.SHIPPING_OPTION_OVERNIGHT,
        QuoteHelper.SHIPPING_OPTION_2_DAY
    };

    @TestVisible
    private class DQResponse {
        public BillingWrappers.DealQualification dqRecord;
        public List<BillingWrappers.DealQualificationDiscount> dqDiscounts = new List<BillingWrappers.DealQualificationDiscount>();
        public List<BillingWrappers.DealQualificationServiceDiscount> dqServiceDiscounts = new List<BillingWrappers.DealQualificationServiceDiscount>();

        public DQResponse() {}
        public DQResponse(
            DQ_Deal_Qualification__c dqRecordSf,
            List<DQ_Deal_Qualification_Discounts__c> dqDiscountsSf,
            List<DQ_Deal_Qualification_Service_Discount__c> dqServiceDiscountSf
        ) {
            if (dqRecordSf != null) {
                this.dqRecord = new BillingWrappers.DealQualification(dqRecordSf);
            }
            if (dqDiscountsSf != null || !dqDiscountsSf.isEmpty()) {
                List<BillingWrappers.DealQualificationDiscount> discountsList = new List<BillingWrappers.DealQualificationDiscount>();
                for (DQ_Deal_Qualification_Discounts__c dqDiscount : dqDiscountsSf) {
                    discountsList.add(new BillingWrappers.DealQualificationDiscount(dqDiscount));
                }
                this.dqDiscounts.addAll(discountsList);
            }
            if (dqServiceDiscountSf != null || !dqServiceDiscountSf.isEmpty()) {
                List<BillingWrappers.DealQualificationServiceDiscount> serviceDiscountsList = new List<BillingWrappers.DealQualificationServiceDiscount>();
                for (DQ_Deal_Qualification_Service_Discount__c dqServiceDiscount : dqServiceDiscountSf) {
                    serviceDiscountsList.add(new BillingWrappers.DealQualificationServiceDiscount(dqServiceDiscount));
                }
                this.dqServiceDiscounts.addAll(serviceDiscountsList);
            }
        }
    }

    public static String getDealQualificationJson(Id opportunityId) {
        DQResponse dqResp = new DQResponse();
        if (opportunityId == null) {
            return JSON.serialize(dqResp);
        }

        DQ_Deal_Qualification__c dqRecord = OpportunityHelper.getDealQualification(opportunityId);
        if (dqRecord != null) {
            dqResp = new DQResponse(
                dqRecord,
                dqRecord.Deal_Qualification_Discounts__r,
                dqRecord.DQ_Deal_Qualification_Service_Discounts__r
            );
            return JSON.serialize(dqResp);
        }
        return JSON.serialize(dqResp);
    }

    public static String updateDQStatus(BillingWrappers.DQParams params) {
        DQResponse dqResp = new DQResponse();
        if (params == null || params.dqRecord == null || params.dqRecord.dqId == null) {
            return JSON.serialize(dqResp);
        }
        String status = params.status;
        if (String.isBlank(status)) {
            status = 'New';
        }
        DQ_Deal_Qualification__c dqRecord = OpportunityHelper.getDealQualification(params.dqRecord.dqId);
        if (dqRecord != null) {
            dqRecord.Status__c = status;
            update dqRecord;
            dqResp = new DQResponse(
                dqRecord,
                dqRecord.Deal_Qualification_Discounts__r,
                dqRecord.DQ_Deal_Qualification_Service_Discounts__r
            );
        }
        return JSON.serialize(dqResp);
    }

    public static String saveDqRecord(BillingWrappers.DQParams params) {
        DQResponse dqResp = new DQResponse();
        if (params == null || params.dqRecord == null) {
            return JSON.serialize(dqResp);
        }
        BillingWrappers.DealQualification dqRecord = params.dqRecord;
        DQ_Deal_Qualification__c dq = dqRecord.buildSobject();
        if (dq == null) {
            return JSON.serialize(dqResp);
        }
        update dq;

        DQ_Deal_Qualification__c reselectedDq = OpportunityHelper.getDealQualification(dq.Id);
        List<DQ_Deal_Qualification_Discounts__c> existingDiscounts = new List<DQ_Deal_Qualification_Discounts__c>();
        List<DQ_Deal_Qualification_Service_Discount__c> existingServiceDiscounts = new List<DQ_Deal_Qualification_Service_Discount__c>();
        if (reselectedDq != null) {
            existingDiscounts = reselectedDq.Deal_Qualification_Discounts__r;
            existingServiceDiscounts = reselectedDq.DQ_Deal_Qualification_Service_Discounts__r;
        }
        List<DQ_Deal_Qualification_Discounts__c> updatedDiscounts = saveDqDiscounts(dq.Id, params.dqDiscounts, existingDiscounts);
        List<DQ_Deal_Qualification_Service_Discount__c> updatedServiceDiscounts = saveDqServiceDiscounts(params.dqServiceDiscounts, existingServiceDiscounts);

        dqResp = new DQResponse(reselectedDq, updatedDiscounts, updatedServiceDiscounts);
        return JSON.serialize(dqResp);
    }

    public static String createDealQualificationApprover(Id dqId, String status) {
        DQResponse dqResp = new DQResponse();
        if (dqId == null) {
            return JSON.serialize(dqResp);
        }
        DQ_Deal_Qualification__c dqRecord = OpportunityHelper.getDealQualification(dqId);
        if (dqRecord != null && status == PENDING_APPROVAL_STATUS) {
            DQApproverHelper.createDealQualificationApprover(dqRecord);
            dqResp = new DQResponse(
                dqRecord,
                dqRecord.Deal_Qualification_Discounts__r,
                dqRecord.DQ_Deal_Qualification_Service_Discounts__r
            );
        }
        return JSON.serialize(dqResp);
    }

    public static String reviseDealQualification(Id dqId, String status) {
        DQResponse dqResp = new DQResponse();
        if (dqId == null) {
            return JSON.serialize(dqResp);
        }
        DQ_Deal_Qualification__c dqRecord = OpportunityHelper.getDealQualification(dqId);
        if (dqRecord != null && status == REVISION_PENDING_STATUS) {
            DQApproverHelper.reviseDealQualification(dqRecord);
            dqResp = new DQResponse(
                dqRecord,
                dqRecord.Deal_Qualification_Discounts__r,
                dqRecord.DQ_Deal_Qualification_Service_Discounts__r
            );
        }
        return JSON.serialize(dqResp);
    }

    public static String syncDealQualificationJson(Id quoteId, String status, Boolean isPrmFlow) {
        DQResponse dqResp = syncDealQualification(quoteId, status, isPrmFlow);
        if (dqResp == null) {
            dqResp = new DQResponse();
        }
        return JSON.serialize(dqResp);
    }

    private static DQResponse syncDealQualification(Id quoteId, String status, Boolean isPrmFlow) {
        if (quoteId == null) {
            return null;
        }

        if (String.isBlank(status)) {
            status = 'New';
        }

        List<Quote> quotesList = new QuoteSelector()
            .selectQuotesForDQSync(new Set<Id> { quoteId })
            .executeQuery();

        if (quotesList.isEmpty()) {
            return null;
        }

        QuoteHelper.QuotesStorage quotesStorage = new QuoteHelper.QuotesStorage(quotesList);

        List<Quote> technicalQuotes = quotesStorage.technicalQuotes;
        Quote qt = quotesStorage.masterQuote;
        Quote qtCC = (Quote) new ListOptional(new QuoteSelector()
            .selectCCQuoteForDQSync(qt.OpportunityId)
            .executeQuery()
        ).getFirst();

        DQ_Deal_Qualification__c dqRecord = OpportunityHelper.getDealQualification(qt.OpportunityId);
        if (isPrmFlow && dqRecord != null) {
            DQServiceHelper.reviseDealQualification(dqRecord.Id, DQServiceHelper.REVISION_PENDING_STATUS);
        }
        if (dqRecord == null) {
            dqRecord = new DQ_Deal_Qualification__c();
        }

        BillingWrappers.QuotePackageInfo pInfo;
        if (!String.isBlank(qt.Package_Info__c)) {
            pInfo = new BillingWrappers.QuotePackageInfoWrapper(qt.Package_Info__c)
                .getPackageInfo();
        }

        dqRecord.Quote__c = quoteId;
        dqRecord.Status__c = status;
        dqRecord.Opportunity__c = qt.OpportunityId;
        dqRecord.Charge_Term__c = qt.Payment_Plan__c;
        dqRecord.Renewal_Term__c = qt.Term_months__c;
        dqRecord.Initial_Term__c = qt.Initial_Term_months__c;
        dqRecord.Special_Terms__c = qt.Special_Terms__c;
        dqRecord.Deal_Size__c = qt.Total_MRR_New__c != null ? qt.Total_MRR_New__c.setScale(2) : 0;
        dqRecord.New_Annual_Recurring_Charges__c = qt.Monthly_Recurring_Revenue__c;
        dqRecord.IsDQCreatedFromCPQOpp__c = false;
        dqRecord.Cost_of_One_Time_items__c = qt.Total_One_Time__c;
        dqRecord.Auto_Renewal__c = qt.Auto_Renewal__c;
        dqRecord.Opportunity_Owner_s_Email__c = qt.Opportunity.Owner.Email;
        dqRecord.Overall_Discount__c = QuoteLineItemHelper.getOverallDiscount(qt.QuoteLineItems);
        dqRecord.Family_Discount__c = qt.AverageDiscount__c;
        dqRecord.Overall_Discount_Recurring__c = qt.OverallDiscretion__c;
        dqRecord.Justification_Description__c = qt.JustificationAndDescription__c;
        if (qtCC != null) {
            dqRecord.CC_Special_Terms__c = qtCC.Special_Terms__c;
            dqRecord.CC_Initial_Term__c = qtCC.Initial_Term_months__c;
        }
        if (qt.FreeShippingTerms__c == QuoteHelper.FREESHIPPING) {
            dqRecord.Free_Shipping_Terms_Options__c = getFreeShippingOption(qt);
        } else {
            dqRecord.Free_Shipping_Terms_Options__c = null;
        }

        upsert dqRecord;

        List<QuoteLineItem> qliList = getQuoteLineItems(qt, technicalQuotes, qtCC);
        Map<Id, BillingWrappers.QuotePackageInfo> quoteIdToPackageInfoMap = getQuoteIdToPInfoMap(qt, technicalQuotes, pInfo);

        List<DQ_Deal_Qualification_Discounts__c> dqDiscountsList = syncDqDiscounts(
            dqRecord.Id,
            dqRecord.Deal_Qualification_Discounts__r,
            qliList,
            quoteIdToPackageInfoMap
        );
        upsert dqDiscountsList;

        Set<Id> dqDiscountIdSet = new Set<Id>();
        for (DQ_Deal_Qualification_Discounts__c dqDiscount : dqDiscountsList) {
            dqDiscountIdSet.add(dqDiscount.Id);
        }
        for (DQ_Deal_Qualification_Discounts__c dqDiscount : dqRecord.Deal_Qualification_Discounts__r) {
            if (!dqDiscountIdSet.contains(dqDiscount.Id)) {
                dqDiscountsList.add(dqDiscount);
            }
        }

        List<Quote> quotes = !technicalQuotes.isEmpty()
            ? technicalQuotes
            : new List<Quote>{ qt };
        List<DQ_Deal_Qualification_Service_Discount__c> dqServiceDiscounts = syncDqServiceDiscounts(
            dqRecord.DQ_Deal_Qualification_Service_Discounts__r,
            dqRecord.Id,
            quotes
        );
        upsert dqServiceDiscounts;

        return new DQResponse(dqRecord, dqDiscountsList, dqServiceDiscounts);
    }

    private static String getFreeShippingOption(Quote qt) {
        String shippingOption;
        if (Feature_Toggle__c.getInstance().Shipping_Tab_New_Business__c) {
            List<CustomAddressAssignments__c> customAddressAssignments = new CustomAddressAssignmentsSelector()
                .selectCustomAddressAssignments()
                .selectFields(new List<String>{ 'Id' })
                .setCondition('QuoteLineItem__r.QuoteId = :bind0 AND Type__c IN :bind1')
                .setQueryBindings(new List<Object>{ qt.Id, SHIPPING_OPTIONS })
                .setLimit(1)
                .executeQuery();
            shippingOption = customAddressAssignments.size() > 0 ? FREE_SHIPPING_OPTION : null;
        } else {
            shippingOption = SHIPPING_OPTIONS.contains(qt.Shipping_Option__c) ? FREE_SHIPPING_OPTION : null;
        }
        return shippingOption;
    }

    public static Boolean isFreeShippingOption(Quote qt) {
        return getFreeShippingOption(qt) == FREE_SHIPPING_OPTION;
    }

    @TestVisible
    private static List<DQ_Deal_Qualification_Discounts__c> syncDqDiscounts(
        Id dqId,
        List<DQ_Deal_Qualification_Discounts__c> dqDiscounts,
        List<QuoteLineItem> qliList,
        Map<Id, BillingWrappers.QuotePackageInfo> quoteIdToPackageInfoMap
    ) {
        List<DQ_Deal_Qualification_Discounts__c> result = new List<DQ_Deal_Qualification_Discounts__c>();
        if (qliList == null || qliList.isEmpty()) {
            return result;
        }

        Map<String, DQ_Deal_Qualification_Discounts__c> dqDiscountsMap = buildDqDiscountsMap(dqDiscounts, false);
        String packageId;
        String packageVersion = '';
        String packageName = '';

        for (QuoteLineItem qli : qliList) {
            if (qli.Discount == null || qli.Discount == 0) {
                continue;
            }

            if (quoteIdToPackageInfoMap.containsKey(qli.QuoteId) && quoteIdToPackageInfoMap.get(qli.QuoteId) != null) {
                BillingWrappers.QuotePackageInfo pInfo = quoteIdToPackageInfoMap.get(qli.QuoteId);
                if (pInfo.packageInfo != null && pInfo.packageInfo.catalogId != null) {
                    packageId = pInfo.packageInfo.catalogId;
                }
                if (pInfo.packageInfo != null && pInfo.packageInfo.version != null) {
                    packageVersion = pInfo.packageInfo.version;
                }
                if (pInfo.packageInfo != null && pInfo.packageInfo.displayName != null) {
                    packageName = pInfo.packageInfo.displayName;
                }
            }
            String key;
            String productCategory;
            if (qli.Quote.RecordTypeId == QuoteHelper.RT_ID_BILLING) {
                productCategory = Product2Helper.getGoaGroup(qli.Product2.GOA_Group_V3__c);
                key =  packageId +  packageVersion + productCategory + qli.Product2Id;
            } else if (qli.Quote.RecordTypeId == QuoteHelper.RT_ID_CC) {
                Boolean isDefaultCategory = String.isBlank(qli.Product2.Goa_Group_V2__c)
                    && qli.Product2.Sub_Category__c == Product2Helper.SUBCATEGORY_CONTACT_CENTER;
                productCategory = isDefaultCategory ? DEFAULT_CC_CATEGORY : qli.Product2.Goa_Group_V2__c;
                key = productCategory + qli.Product2Id; // for Contact Center quotes we have no billing packages
            }

            DQ_Deal_Qualification_Discounts__c dqDiscount;
            if (dqDiscountsMap.containsKey(key)) {
                dqDiscount = dqDiscountsMap.get(key);
            } else {
                dqDiscount = new DQ_Deal_Qualification_Discounts__c(
                    Deal_Qualification__c = dqId
                );
            }

            dqDiscount = populateDQDiscountFields(dqDiscount, qli.Product2.Sub_Category__c, qli);
            dqDiscount.Product_Category__c = productCategory;
            if (qli.Quote.RecordTypeId == QuoteHelper.RT_ID_BILLING) {
                dqDiscount.OriginalPackageId__c = packageId;
                dqDiscount.OriginalPackageVersion__c = packageVersion;
                dqDiscount.OriginalPackageName__c = packageName;
                dqDiscount.PackageName__c = packageName;
            }

            result.add(dqDiscount);
        }

        return result;
    }

    @TestVisible
    private static DQ_Deal_Qualification_Discounts__c populateDQDiscountFields(DQ_Deal_Qualification_Discounts__c dqDiscount, String productSubCategory, QuoteLineItem qli) {
        if (dqDiscount == null || qli == null) {
            return dqDiscount;
        }
        dqDiscount.RecordTypeId = productSubCategory == Product2Helper.SUBCATEGORY_CONTACT_CENTER
            ? DQ_CC_RECORD_TYPE_ID
            : DQ_SALES_RECORD_TYPE_ID;
        dqDiscount.Product__c = qli.Product2Id;
        dqDiscount.Quantity__c = AccountHelper.isPocToPaid(qli.Quote.Account) ? qli.NewQuantity__c : qli.Quantity;
        dqDiscount.Discount__c = qli.Discount.setScale(2, RoundingMode.CEILING);
        dqDiscount.Discount_Type__c = qli.Discount_type__c;
        dqDiscount.Promo_Code__c = qli.Promotion__c;
        dqDiscount.Service__c = qli.ServiceName__c;
        dqDiscount.Group__c = qli.Product2.Group__c;
        dqDiscount.Subgroup__c = qli.Product2.Subgroup__c;
        return dqDiscount;
    }

    @TestVisible
    private static List<DQ_Deal_Qualification_Discounts__c> saveDqDiscounts(Id dqId, List<BillingWrappers.DealQualificationDiscount> dqDiscounts, List<DQ_Deal_Qualification_Discounts__c> existingDiscounts) {
        if ((dqDiscounts == null || dqDiscounts.isEmpty()) && (existingDiscounts == null || existingDiscounts.isEmpty())) {
            return new List<DQ_Deal_Qualification_Discounts__c>();
        }

        Map<String, DQ_Deal_Qualification_Discounts__c> existingDiscountsMap = buildDqDiscountsMap(existingDiscounts, true);

        Map<String, BillingWrappers.DealQualificationDiscount> discountsForSyncMap = new Map<String, BillingWrappers.DealQualificationDiscount>();
        for (BillingWrappers.DealQualificationDiscount discount : dqDiscounts) {
            String packageIdKey =  discount.packageName == null ? '' : discount.originalPackageId + discount.originalPackageVersion;
            String key = packageIdKey + discount.productCategory + discount.product2Id + discount.dqDiscountId;
            if (discountsForSyncMap.containsKey(key)) {
                BillingWrappers.DealQualificationDiscount previousDiscount = discountsForSyncMap.get(key);
                if (previousDiscount.dqDiscountId != null && discount.dqDiscountId == null) {
                    previousDiscount.discountType = discount.discountType;
                    previousDiscount.discount = discount.discount;
                    previousDiscount.quantity = discount.quantity;
                    previousDiscount.service = discount.service;
                    previousDiscount.groupName = discount.groupName;
                    previousDiscount.subgroup = discount.subgroup;
                } else if (previousDiscount.dqDiscountId == null && discount.dqDiscountId != null) {
                    previousDiscount.dqDiscountId = discount.dqDiscountId;
                }
            } else {
                discountsForSyncMap.put(key, discount);
            }
        }

        List<DQ_Deal_Qualification_Discounts__c> discountsForDelete = getDiscountsForDelete(dqDiscounts, existingDiscounts);
        delete discountsForDelete;

        Map<String, DQ_Deal_Qualification_Discounts__c> discountsForUpsertMap = new Map<String, DQ_Deal_Qualification_Discounts__c>();
        for (String discountForSyncKey : discountsForSyncMap.keySet()) {
            DQ_Deal_Qualification_Discounts__c dqDiscount;
            if (existingDiscountsMap.containsKey(discountForSyncKey)) {
                dqDiscount = existingDiscountsMap.get(discountForSyncKey);
            } else {
                dqDiscount = new DQ_Deal_Qualification_Discounts__c(
                    Deal_Qualification__c = dqId
                );
            }
            BillingWrappers.DealQualificationDiscount discountForSync = discountsForSyncMap.get(discountForSyncKey);
            dqDiscount = discountForSync.updateSobjectFields(dqDiscount, dqId);
            discountsForUpsertMap.put(discountForSyncKey, dqDiscount);
        }

        upsert discountsForUpsertMap.values();

        return discountsForUpsertMap.values();
    }

    private static List<DQ_Deal_Qualification_Discounts__c> getDiscountsForDelete(
        List<BillingWrappers.DealQualificationDiscount> discountsForSyncList,
        List<DQ_Deal_Qualification_Discounts__c> existingDiscountsList
    ) {
        List<DQ_Deal_Qualification_Discounts__c> discountsForDelete = new List<DQ_Deal_Qualification_Discounts__c>();
        if (existingDiscountsList == null || existingDiscountsList.isEmpty()) {
            return discountsForDelete;
        }
        Map<Id, BillingWrappers.DealQualificationDiscount> discountsForSyncMap = new Map<Id, BillingWrappers.DealQualificationDiscount>();
        if (discountsForSyncList != null) {
            for (BillingWrappers.DealQualificationDiscount discountForSync : discountsForSyncList) {
                discountsForSyncMap.put(discountForSync.dqDiscountId, discountForSync);
            }
        }
        for (DQ_Deal_Qualification_Discounts__c existingDiscount : existingDiscountsList) {
            if (!discountsForSyncMap.containsKey(existingDiscount.Id)) {
                discountsForDelete.add(existingDiscount);
            }
        }
        return discountsForDelete;
    }

    @TestVisible
    private static Map<String, DQ_Deal_Qualification_Discounts__c> buildDqDiscountsMap(List<DQ_Deal_Qualification_Discounts__c> dqDiscounts, Boolean isSaveAction) {
        Map<String, DQ_Deal_Qualification_Discounts__c> dqDiscountsMap = new Map<String, DQ_Deal_Qualification_Discounts__c>();
        if (dqDiscounts == null || dqDiscounts.isEmpty()) {
            return dqDiscountsMap;
        }
        for (DQ_Deal_Qualification_Discounts__c discount : dqDiscounts) {
            String packageIdKey =  discount.PackageName__c == null ? '' : discount.OriginalPackageId__c + discount.OriginalPackageVersion__c;
            String key = isSaveAction ? packageIdKey + discount.Product_Category__c + discount.Product__c + discount.Id : packageIdKey + discount.Product_Category__c + discount.Product__c;
            dqDiscountsMap.put(key, discount);
        }
        return dqDiscountsMap;
    }

    @TestVisible
    private static List<DQ_Deal_Qualification_Service_Discount__c> saveDqServiceDiscounts(
        List<BillingWrappers.DealQualificationServiceDiscount> dqServiceDiscounts,
        List<DQ_Deal_Qualification_Service_Discount__c> existingDiscounts
    ) {
        if ((dqServiceDiscounts == null || dqServiceDiscounts.isEmpty()) && (existingDiscounts == null || existingDiscounts.isEmpty())) {
            return new List<DQ_Deal_Qualification_Service_Discount__c>();
        }

        Map<Id, DQ_Deal_Qualification_Service_Discount__c> idToDqServiceDiscountMap = new Map<Id, DQ_Deal_Qualification_Service_Discount__c>();
        for(DQ_Deal_Qualification_Service_Discount__c existingDiscount : existingDiscounts) {
            idToDqServiceDiscountMap.put(existingDiscount.Id, existingDiscount);
        }
        List<DQ_Deal_Qualification_Service_Discount__c> updatedServiceDiscount = new List<DQ_Deal_Qualification_Service_Discount__c>();
        for(BillingWrappers.DealQualificationServiceDiscount wrapperDiscount: dqServiceDiscounts) {
            DQ_Deal_Qualification_Service_Discount__c serviceDiscount = idToDqServiceDiscountMap.get(wrapperDiscount.dqServiceDiscountId);
            if (serviceDiscount != null) {
                serviceDiscount.FreeServiceCredit__c = wrapperDiscount.freeServiceCredit;
                serviceDiscount.Discretion__c = wrapperDiscount.discretion;
                serviceDiscount.WeightedDiscount__c = wrapperDiscount.weightedDiscount;
                updatedServiceDiscount.add(serviceDiscount);
            }
        }

        update updatedServiceDiscount;

        return updatedServiceDiscount;
    }

    @TestVisible
    private static List<DQ_Deal_Qualification_Service_Discount__c> syncDqServiceDiscounts(
        List<DQ_Deal_Qualification_Service_Discount__c> dqServicesDiscounts,
        Id dqRecordId,
        List<Quote> existingQuotes
    ) {
        List<DQ_Deal_Qualification_Service_Discount__c> dqServiceDiscountsToSync = new List<DQ_Deal_Qualification_Service_Discount__c>();
        if (existingQuotes.isEmpty()) {
            return dqServiceDiscountsToSync;
        }

        dqServiceDiscountsToSync = getDqDealQualificationServiceDiscounts(dqServicesDiscounts, existingQuotes, dqRecordId);

        return dqServiceDiscountsToSync;
    }

    @TestVisible
    public static List<DQ_Deal_Qualification_Service_Discount__c> getDqDealQualificationServiceDiscounts(
        List<DQ_Deal_Qualification_Service_Discount__c> dqServiceDiscounts,
        List<Quote> existingQuotes,
        Id dqRecordId
    ) {
        Map<String, DQ_Deal_Qualification_Service_Discount__c> serviceNameToDQServiceDiscountMap = new Map<String, DQ_Deal_Qualification_Service_Discount__c>();
        List<DQ_Deal_Qualification_Service_Discount__c> dqServiceDiscountsToSync = new List<DQ_Deal_Qualification_Service_Discount__c>();
        for (DQ_Deal_Qualification_Service_Discount__c dqServiceDiscount : dqServiceDiscounts) {
            serviceNameToDQServiceDiscountMap.put(dqServiceDiscount.Service__c, dqServiceDiscount);
        }
        for (Quote existingQuote: existingQuotes) {
            String serviceName = existingQuote.ServiceName__c != null
                ? existingQuote.ServiceName__c
                : existingQuote.Opportunity.Tier_Name__c;
            dqServiceDiscountsToSync.add(
                getDqServiceDiscountRecord(
                    dqRecordId,
                    existingQuote,
                    serviceNameToDQServiceDiscountMap.get(serviceName)
                )
            );
        }

        return dqServiceDiscountsToSync;
    }

    private static DQ_Deal_Qualification_Service_Discount__c getDqServiceDiscountRecord(
        Id dqRecordId,
        Quote quote,
        DQ_Deal_Qualification_Service_Discount__c dqServiceDiscount
    ) {
        if (dqServiceDiscount == null) {
            dqServiceDiscount = new DQ_Deal_Qualification_Service_Discount__c();
        }
        BillingWrappers.QuotePackageInfo pInfo = new BillingWrappers.QuotePackageInfoWrapper(quote.Package_Info__c).getPackageInfo();
        dqServiceDiscount.Service__c = quote.ServiceName__c != null
            ? quote.ServiceName__c
            : quote.Opportunity.Tier_Name__c;
        dqServiceDiscount.FreeServiceCredit__c = quote.Special_Terms__c;
        dqServiceDiscount.Discretion__c = quote.OverallDiscretion__c != null
            ? quote.OverallDiscretion__c
            : 0;
        dqServiceDiscount.WeightedDiscount__c = quote.AverageDiscount__c != null
            ? quote.AverageDiscount__c
            : 0;
        if (dqServiceDiscount.Deal_Qualification__c == null) {
            dqServiceDiscount.Deal_Qualification__c = dqRecordId;
        }

        return dqServiceDiscount;
    }

    private static List<QuoteLineItem> getQuoteLineItems(
        Quote masterQuote,
        List<Quote> technicalQuotes,
        Quote contactCenterQuote
    ) {
        List<QuoteLineItem> qliList = new List<QuoteLineItem>();
        if (!technicalQuotes.isEmpty()) {
            for (Quote technicalQuote: technicalQuotes) {
                qliList.addAll(technicalQuote.QuoteLineItems);
            }
        } else {
            qliList.addAll(masterQuote.QuoteLineItems);
        }

        if (contactCenterQuote != null) {
            qliList.addAll(contactCenterQuote.QuoteLineItems);
        }

        return qliList;
    }

    private static Map<Id, BillingWrappers.QuotePackageInfo> getQuoteIdToPInfoMap(
        Quote masterQuote,
        List<Quote> technicalQuotes,
        BillingWrappers.QuotePackageInfo masterPackageInfo
    ) {
        Map<Id, BillingWrappers.QuotePackageInfo> quoteIdToPackageInfoMap = new Map<Id, BillingWrappers.QuotePackageInfo>();
        if (!technicalQuotes.isEmpty()) {
            for (Quote technicalQuote: technicalQuotes) {
                quoteIdToPackageInfoMap.put(
                    technicalQuote.Id,
                    new BillingWrappers.QuotePackageInfoWrapper(technicalQuote.Package_Info__c).getPackageInfo()
                );
            }
        } else {
            quoteIdToPackageInfoMap.put(
                masterQuote.Id,
                masterPackageInfo
            );
        }

        return quoteIdToPackageInfoMap;
    }
}