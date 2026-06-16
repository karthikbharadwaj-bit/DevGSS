public without sharing class DQDataHelper {
    public static Boolean IS_QUANTITY_CHANGED = false;
    public static final String CHANGE_IN_QUANTITY_MSG = 'Change in Quantity, ';
    public static final String CONTACT_CENTER_KEY = 'RingCentral Contact Center';
    public static final String STATUS_APPROVED = 'Approved';
    public static final String STATUS_REQUIRED = 'Required';
    public static final String STATUS_REJECTED = 'Rejected';
    public static final String STATUS_NOT_REQUIRED = 'Not Required';
    public static final String EES_REMOVAL_FIELD_APINAME = 'EESRemoval__c';
    public static final String PRODUCT_DATA_DISCOUNT = 'discount';
    public static final String PRODUCT_DATA_QUANTITY = 'quantity';

    public class ProductData {
        public Decimal discount = 0;
        public Boolean hasPromotion;
        public Decimal quantity = 0;
        public String packageId;
        public String packageVersion;
        public String goaGroup = '';
        public String productGroupKey = '';
        public Id product2Id;
        private Map<String, Object> fieldToValueMap;

        public ProductData() {}

        public ProductData(String packageId, String packageVersion, QuoteLineItem qli) {
            if (qli != null) {
                this.quantity = AccountHelper.isPocToPaid(qli.Quote.Account) ? qli.NewQuantity__c : qli.Quantity;
                this.product2Id = qli.Product2Id;
                this.discount = getDiscount(qli);
                this.hasPromotion = qli.Promotion__c != null;
                if (qli.Quote.RecordTypeId == QuoteHelper.RT_ID_BILLING) {
                    this.goaGroup = Product2Helper.getGoaGroup(qli.Product2.GOA_Group_V3__c);
                } else if (qli.Quote.RecordTypeId == QuoteHelper.RT_ID_CC) {
                    String goaGroup = 'Default Contact Center';
                    if (!String.isBlank(qli.Product2.GOA_Group_V2__c)) {
                        goaGroup = qli.Product2.GOA_Group_V2__c;
                    }
                    this.goaGroup = goaGroup;
                }
                this.packageId = packageId;
                this.packageVersion = packageVersion;
                this.productGroupKey = buildProductGroupKey(
                    this.goaGroup,
                    this.packageId,
                    this.packageVersion,
                    this.product2Id
                );
            }
        }
        public ProductData(DQ_Deal_Qualification_Discounts__c dqDiscount) {
            if (dqDiscount != null) {
                this.quantity = dqDiscount.Quantity__c;
                this.product2Id = dqDiscount.Product__c;
                this.discount = dqDiscount.Discount__c;
                this.hasPromotion = dqDiscount.Promo_Code__c != null;
                this.goaGroup = dqDiscount.Product_Category__c;
                if (!String.isBlank(dqDiscount.PackageName__c)) {
                    this.packageId = dqDiscount.OriginalPackageId__c;
                    this.packageVersion = dqDiscount.OriginalPackageVersion__c;
                }
                this.productGroupKey = buildProductGroupKey(
                    this.goaGroup,
                    this.packageId,
                    this.packageVersion,
                    this.product2Id
                );
            }
        }
        public ProductData(DQ_Deal_Qualification_Discount_History__c dqHistoryDiscount) {
            if (dqHistoryDiscount != null) {
                this.quantity = dqHistoryDiscount.Quantity__c;
                this.product2Id = dqHistoryDiscount.Product__c;
                this.discount = dqHistoryDiscount.Discount__c;
                this.goaGroup = dqHistoryDiscount.Product_Category__c;
                this.packageId = dqHistoryDiscount.PackageId__c;
                this.packageVersion = dqHistoryDiscount.PackageVersion__c;
                this.productGroupKey = buildProductGroupKey(
                    this.goaGroup,
                    this.packageId,
                    this.packageVersion,
                    this.product2Id
                );
            }
        }

        @TestVisible
        private Decimal getDiscount(QuoteLineItem qli) {
            Decimal result = 0;
            if (qli == null) {
                return result;
            }
            return qli.Discount == null ? 0 : qli.Discount;
        }

        public Object get(String fieldName) {
            if (fieldToValueMap == null) {
                fieldToValueMap = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(this));
            }
            return fieldToValueMap.get(fieldName);
        }
    }

    public class PackageInfoData {
        public String packageId = '';
        public String packageVersion = '';
        public Boolean isFaxService = false;
        public Boolean hasContract = false;

        public PackageInfoData(String packageInfoJson) {
            if (String.isBlank(packageInfoJson)) {
                return;
            }
            BillingWrappers.QuotePackageInfo pInfo = new BillingWrappers.QuotePackageInfoWrapper(packageInfoJson).getPackageInfo();
            if (pInfo.packageInfo != null && pInfo.packageInfo.catalogId != null) {
                this.packageId = pInfo.packageInfo.catalogId;
            }
            if (pInfo.packageInfo != null && pInfo.packageInfo.version != null) {
                this.packageVersion = pInfo.packageInfo.version;
            }
            if (pInfo.contract != null) {
                this.hasContract = true;
            }
            this.isFaxService = Product2Helper.PRODUCT_FAX.equalsIgnoreCase(pInfo.productName);
        }
    }

    public class QuoteData {
        public Decimal initialTerm = 0;
        public Decimal renewalTerm = 0;
        public Decimal averageDiscount = 0;
        public Decimal discretion = 0;
        public String freeShippingTermsOption = '';
        public String specialTerms = '';
        public String serviceName = '';
        public Boolean isAutoRenewal;
        public Boolean shippingMethodRequiresApprove;
        public Boolean isPrmQuote = false;
        public PackageInfoData packageInfoData;
        public List<QuoteLineItem> quoteLineItems;

        public QuoteData(Quote qt) {
            this.initialTerm = qt.Initial_Term_months__c != null ? Decimal.valueOf(qt.Initial_Term_months__c) : 0;
            this.renewalTerm = qt.Term_months__c != null ? Decimal.valueOf(qt.Term_months__c) : 0;
            this.shippingMethodRequiresApprove = DQServiceHelper.isFreeShippingOption(qt);
            this.freeShippingTermsOption = qt.FreeShippingTerms__c != null ? qt.FreeShippingTerms__c : '';
            this.specialTerms = qt.Special_Terms__c != null ? qt.Special_Terms__c : '';
            this.averageDiscount = qt.AverageDiscount__c != null ? qt.AverageDiscount__c : 0;
            this.discretion = qt.OverallDiscretion__c != null ? qt.OverallDiscretion__c : 0;
            this.serviceName = qt.ServiceName__c != null ? qt.ServiceName__c : qt.Opportunity.Tier_Name__c;
            this.packageInfoData = new PackageInfoData(qt.Package_Info__c);
            this.isAutoRenewal = this.packageInfoData?.isFaxService ? null : qt.Auto_Renewal__c;
            this.quoteLineItems = qt.QuoteLineItems;
            this.isPrmQuote = qt.IsPRMQuote__c;
        }

        public QuoteData(Quote qt, PackageInfoData mainQuotePackageInfoData ) {
            this.initialTerm = qt.Initial_Term_months__c != null ? Decimal.valueOf(qt.Initial_Term_months__c) : 0;
            this.renewalTerm = qt.Term_months__c != null ? Decimal.valueOf(qt.Term_months__c) : 0;
            this.shippingMethodRequiresApprove = DQServiceHelper.isFreeShippingOption(qt);
            this.freeShippingTermsOption = qt.FreeShippingTerms__c != null ? qt.FreeShippingTerms__c : '';
            this.specialTerms = qt.Special_Terms__c != null ? qt.Special_Terms__c : '';
            this.serviceName = CONTACT_CENTER_KEY;
            this.packageInfoData = mainQuotePackageInfoData;
            this.quoteLineItems = qt.QuoteLineItems;
            this.isPrmQuote = qt.IsPRMQuote__c;
        }
    }

    public class OpportunityData {
        public String oppId = '';
        public String opportunityOwnerRegion = '';
        public String opportunitySegment = '';
        public String opportunityBrand = '';
        public String oppTierName = '';
        public String subRegion = '';
        public String dealType = '';
        public Decimal masterQuoteDealSize = 0;

        @TestVisible
        private OpportunityData() {}

        public OpportunityData(Opportunity opp, Decimal dealSize) {
            this.oppId = opp.Id;
            this.opportunityOwnerRegion = opp.Owner.Region__c != null ? opp.Owner.Region__c : 'Default';
            this.dealType = getDealType(opp.RecordType.Name);
            this.opportunityBrand = opp.Brand_Name__c != null ? opp.Brand_Name__c : 'Default';
            this.subRegion = opp.Owner.Sub_Region__c != null ? opp.Owner.Sub_Region__c : 'Default';
            String segment = opp.Brand_Name__c == 'Avaya Cloud Office' ? opp.Segment_Name__c : opp.Owner.SegmentPicklist__c;
            this.opportunitySegment = segment != null ? segment : 'Default';
            this.oppTierName = opp.Tier_Name__c != null ? opp.Tier_Name__c : '';
            this.masterQuoteDealSize = dealSize;
        }

        private String getDealType(String oppRecordTypeName) {
            String dealType = 'Direct';
            if(String.isBlank(oppRecordTypeName)) {
                return dealType;
            }
            if (oppRecordTypeName.contains('VAR')) {
                dealType = 'Indirect';
            }
            return dealType;
        }
    }

    public class DealQualificationHistoryData {
        public String id;
        public String dqFreeShippingTermsOptionsHistory = '';
        public Boolean isAutoRenewalHistory;

        public Map<String, DQServiceDiscountHistoryData> serviceNameToDQServiceDiscountHistoryDataMap = new Map<String, DQServiceDiscountHistoryData>();

        public DealQualificationHistoryData(DQ_Deal_Qualification_History__c dqHistory) {
            if (dqHistory == null) {
                return;
            }

            if (!dqHistory.DQ_Service_Discounts_History__r.isEmpty()) {
                Map<String, DQServiceDiscountHistoryData> serviceNameToDqServiceDiscountMap = new Map<String, DQServiceDiscountHistoryData>();
                for (DQ_Service_Discount_History__c dqServiceDiscount : dqHistory.DQ_Service_Discounts_History__r) {
                    serviceNameToDqServiceDiscountMap.put(dqServiceDiscount.Service__c, new DQServiceDiscountHistoryData(dqServiceDiscount));
                }
                this.serviceNameToDQServiceDiscountHistoryDataMap = serviceNameToDqServiceDiscountMap;
            }

            this.id = dqHistory.Id;
            this.dqFreeShippingTermsOptionsHistory = dqHistory.Free_Shipping_Terms_Options__c != null ? dqHistory.Free_Shipping_Terms_Options__c : '';
            this.isAutoRenewalHistory = dqHistory.Auto_Renewal__c;
        }
    }

    public class DQServiceDiscountHistoryData {
        public String serviceName = '';
        public String specialTermsHistory = '';
        public Decimal discretionHistory = 0;
        public Decimal averageDiscountHistory = 0;

        public DQServiceDiscountHistoryData(DQ_Service_Discount_History__c dqServiceDiscountHistory) {
            this.serviceName = dqServiceDiscountHistory.Service__c;
            this.specialTermsHistory = dqServiceDiscountHistory.FreeServiceCredit__c;
            this.discretionHistory = dqServiceDiscountHistory.Discretion__c;
            this.averageDiscountHistory = dqServiceDiscountHistory.WeightedDiscount__c;
        }

        public DQServiceDiscountHistoryData(DQ_Deal_Qualification_History__c dqHistory) {
            this.serviceName = CONTACT_CENTER_KEY;
            this.specialTermsHistory = dqHistory.CC_Special_Terms__c != null ? dqHistory.CC_Special_Terms__c : '';
        }
    }

    public class DealQualificationData {
        public OpportunityData opportunityData;
        public DealQualificationHistoryData dqHistoryData;
        public QuoteData mainQuoteData;

        public Map<String, Map<String, ProductData>> goaCategoryToProductDataMap = new Map<String, Map<String, ProductData>>();
        public Map<String, Map<String, ProductData>> goaCategoryToProductDataHistoryMap = new Map<String, Map<String, ProductData>>();
        public Map<String, QuoteData> serviceNameToQuoteDataMap = new Map<String, QuoteData>();

        @TestVisible
        private DealQualificationData() {
            this.opportunityData = new OpportunityData();
        }

        public DealQualificationData(DQ_Deal_Qualification__c dqRecord, DQ_Deal_Qualification_History__c dqHistory) {
            if (dqRecord != null) {
                this.opportunityData = new OpportunityData(dqRecord.Opportunity__r, dqRecord.Deal_Size__c);

                QuoteHelper.QuotesStorage quotesStorage;
                List<Quote> quotesList = new QuoteSelector()
                    .selectQuotesForDQSync(new Set<Id> { dqRecord.Quote__c })
                    .executeQuery();
                if (!quotesList.isEmpty()) {
                    quotesStorage = new QuoteHelper.QuotesStorage(quotesList);
                }
                Map<String, QuoteData> serviceNameToQuoteDataMap = getServiceNameToQuoteDataMap(quotesStorage);
                this.mainQuoteData = new QuoteData(quotesStorage.masterQuote);
                this.serviceNameToQuoteDataMap = serviceNameToQuoteDataMap;

                if (!dqRecord.Deal_Qualification_Discounts__r.isEmpty()) {
                    this.goaCategoryToProductDataMap = buildGoaCategoryToProductDataMap(dqRecord.Deal_Qualification_Discounts__r);
                }
            }

            this.dqHistoryData = new DealQualificationHistoryData(dqHistory);
        }

        public DealQualificationData(QuoteHelper.QuotesStorage quotesStorage, Opportunity opp, DQ_Deal_Qualification__c dqRecord, DQ_Deal_Qualification_History__c dqHistory) {
            Map<String, QuoteData> serviceNameToQuoteDataMap = getServiceNameToQuoteDataMap(quotesStorage);
            this.mainQuoteData = new QuoteData(quotesStorage.masterQuote);
            this.serviceNameToQuoteDataMap = serviceNameToQuoteDataMap;
            this.opportunityData = new OpportunityData(opp, quotesStorage.masterQuote?.Total_MRR_New__c);
            this.goaCategoryToProductDataMap = buildGoaCategoryToProductDataMap(this.serviceNameToQuoteDataMap);

            if (dqHistory != null) {
                this.dqHistoryData = new DealQualificationHistoryData(dqHistory);
                this.goaCategoryToProductDataHistoryMap = buildGoaCategoryToProductDataHistoryMap(dqHistory);
            }
        }

        @TestVisible
        private Map<String, QuoteData> getServiceNameToQuoteDataMap(QuoteHelper.QuotesStorage quotesStorage) {
            Map<String, QuoteData> serviceNameToQuoteDataMap = new Map<String, QuoteData>();
            if (!quotesStorage.technicalQuotes.isEmpty()) {
                for (Quote technicalQuote : quotesStorage.technicalQuotes) {
                    serviceNameToQuoteDataMap.put(technicalQuote.ServiceName__c, new QuoteData(technicalQuote));
                }
            } else {
                Quote masterQuote = quotesStorage.masterQuote;
                QuoteData qtData = new QuoteData(masterQuote);
                serviceNameToQuoteDataMap.put(qtData.serviceName, qtData);
                if (quotesStorage.masterQuote?.OpportunityId != null && quotesStorage.masterQuote?.RecordTypeId != QuoteHelper.RT_ID_CC) {
                    Quote ccQuote = (Quote) new ListOptional(new QuoteSelector()
                        .selectCCQuoteForDQSync(quotesStorage.masterQuote.OpportunityId)
                        .executeQuery()
                    ).getFirst();
                    if (ccQuote != null) {
                        QuoteData ccQuoteData = new QuoteData(ccQuote, new PackageInfoData(quotesStorage.masterQuote?.Package_Info__c));
                        serviceNameToQuoteDataMap.put(CONTACT_CENTER_KEY, ccQuoteData);
                    }
                }
            }

            return serviceNameToQuoteDataMap;
        }

        @TestVisible
        private Map<String, Map<String, ProductData>> buildGoaCategoryToProductDataMap(Map<String, QuoteData> serviceNameToQuoteDataMap) {
            Map<String, Map<String, ProductData>> result = new Map<String, Map<String, ProductData>>();

            List<ProductData> productDataList = new List<ProductData>();
            for (QuoteData qData : serviceNameToQuoteDataMap.values()) {
                for (QuoteLineItem qli : qData.quoteLineItems) {
                    productDataList.add(
                        new ProductData(qData.packageInfoData.packageId, qData.packageInfoData.packageVersion, qli)
                    );
                }
            }
            return buildGoaCategoryToProductDataMap(productDataList);
        }

        private Map<String, Map<String, ProductData>> buildGoaCategoryToProductDataMap(List<DQ_Deal_Qualification_Discounts__c> dqDiscountsList) {
            Map<String, Map<String, ProductData>> result = new Map<String, Map<String, ProductData>>();
            if (dqDiscountsList == null || dqDiscountsList.isEmpty()) {
                return result;
            }
            List<ProductData> productDataList = new List<ProductData>();
            for (DQ_Deal_Qualification_Discounts__c dqDiscount : dqDiscountsList) {
                productDataList.add(
                    new ProductData(dqDiscount)
                );
            }
            return buildGoaCategoryToProductDataMap(productDataList);
        }

        @TestVisible
        private Map<String, Map<String, ProductData>> buildGoaCategoryToProductDataHistoryMap(DQ_Deal_Qualification_History__c dqHistory) {
            Map<String, Map<String, ProductData>> result = new Map<String, Map<String, ProductData>>();
            if (dqHistory == null) {
                return result;
            }
            List<ProductData> productDataList = new List<ProductData>();
            for (DQ_Deal_Qualification_Discount_History__c dqHistoryDiscount : dqHistory.DQ_Deal_Qualification_Discounts_History__r) {
                productDataList.add(
                    new ProductData(dqHistoryDiscount)
                );
            }
            return buildGoaCategoryToProductDataMap(productDataList);
        }
        private Map<String, Map<String, ProductData>> buildGoaCategoryToProductDataMap(List<ProductData> productDataList) {
            Map<String, Map<String, ProductData>> result = new Map<String, Map<String, ProductData>>();
            if (productDataList == null || productDataList.isEmpty()) {
                return result;
            }
            for (ProductData productInfo : productDataList) {
                if (productInfo.discount == 0) {
                    continue;
                }
                Map<String, ProductData> productGroupToProductDataMap = new Map<String, ProductData>();
                if (result.containsKey(productInfo.goaGroup)) {
                    productGroupToProductDataMap = result.get(productInfo.goaGroup);
                }
                if (!productGroupToProductDataMap.containsKey(productInfo.productGroupKey)) {
                    productGroupToProductDataMap.put(productInfo.productGroupKey, productInfo);
                } else {
                    ProductData existingProductInfo = productGroupToProductDataMap.get(productInfo.productGroupKey);
                    if (productInfo.discount > existingProductInfo.discount || productInfo.quantity > existingProductInfo.quantity) {
                        productGroupToProductDataMap.put(productInfo.productGroupKey, productInfo);
                    }
                }
                result.put(productInfo.goaGroup, productGroupToProductDataMap);
            }
            return result;
        }

        public Decimal getPackageCategoryHistoryData(String goaCategory, ProductData productInfo, String field) {
            Decimal packageCategoryHistoryData = 0;
            Boolean isRequiredDataEmpty = (this.goaCategoryToProductDataHistoryMap == null || this.goaCategoryToProductDataHistoryMap.isEmpty())
                || productInfo == null
                || productInfo.packageId == null
                || productInfo.packageVersion == null;

            if (isRequiredDataEmpty) {
                return packageCategoryHistoryData;
            }
            String packageCategoryKey = buildProductGroupKey(goaCategory, productInfo.packageId, productInfo.packageVersion, null);
            if (this.goaCategoryToProductDataHistoryMap.containsKey(goaCategory) && this.goaCategoryToProductDataHistoryMap.get(goaCategory).containsKey(packageCategoryKey)) {
                ProductData productDataHistory = this.goaCategoryToProductDataHistoryMap.get(goaCategory).get(packageCategoryKey);
                packageCategoryHistoryData = (Decimal) productDataHistory.get(field);
            }
            return packageCategoryHistoryData;
        }

        public Decimal getCategoryProductHistoryData(String goaCategory, ProductData productInfo, String field) {
            Decimal productCategoryHistoryData = 0;
            Boolean isRequiredDataEmpty = (this.goaCategoryToProductDataHistoryMap == null || this.goaCategoryToProductDataHistoryMap.isEmpty())
                || productInfo == null
                || productInfo.product2Id == null;

            if (isRequiredDataEmpty) {
                return productCategoryHistoryData;
            }
            String packageCategoryKey = buildProductGroupKey(goaCategory, null, null, productInfo.product2Id);
            if (this.goaCategoryToProductDataHistoryMap.containsKey(goaCategory) && this.goaCategoryToProductDataHistoryMap.get(goaCategory).containsKey(packageCategoryKey) ) {
                ProductData productDataHistory = this.goaCategoryToProductDataHistoryMap.get(goaCategory).get(packageCategoryKey);
                productCategoryHistoryData = (Decimal) productDataHistory.get(field);
            }
            return productCategoryHistoryData;
        }

        public Decimal getCategoryHistoryData(String goaCategory, String field) {
            Decimal categoryHistoryData = 0;
            if (this.goaCategoryToProductDataHistoryMap == null || this.goaCategoryToProductDataHistoryMap.isEmpty()) {
                return categoryHistoryData;
            }
            String categoryKey = buildProductGroupKey(goaCategory, null, null, null);
            if (this.goaCategoryToProductDataHistoryMap.containsKey(goaCategory) && this.goaCategoryToProductDataHistoryMap.get(goaCategory).containsKey(categoryKey)) {
                ProductData productDataHistory = this.goaCategoryToProductDataHistoryMap.get(goaCategory).get(categoryKey);
                categoryHistoryData = (Decimal) productDataHistory.get(field);
            }
            return categoryHistoryData;
        }
    }

    public static DealQualificationData getDealQualificationDataForQuote(Id quoteId) {
        if (quoteId == null) {
            return null;
        }

        List<Quote> quoteList = new QuoteSelector()
            .selectQuoteForDqGoa(quoteId)
            .executeQuery();

        QuoteHelper.QuotesStorage quotesStorage = new QuoteHelper.QuotesStorage(quoteList);
        Quote masterQuote = quotesStorage.masterQuote;

        DQ_Deal_Qualification__c dqRecord = (DQ_Deal_Qualification__c) new ListOptional(new DealQualificationSelector()
            .selectDQForDQGOA(masterQuote.OpportunityId)
            .executeQuery()
        ).getFirst();

        DQ_Deal_Qualification_History__c dqHistory = new DQ_Deal_Qualification_History__c();
        if (dqRecord != null) {
            dqHistory = (DQ_Deal_Qualification_History__c) new ListOptional(new DealQualificationHistorySelector()
                .selectApprovedDQHistory(dqRecord.Id)
                .executeQuery()
            ).getFirst();
        }

        DealQualificationData dqData = new DealQualificationData(quotesStorage, masterQuote.Opportunity, dqRecord, dqHistory);

        return dqData;
    }

    public static DealQualificationData getDealQualificationDataForDQ(Id dqOrOppId) {
        if (dqOrOppId == null) {
            return null;
        }

        DQ_Deal_Qualification__c dqRecord = (DQ_Deal_Qualification__c) new ListOptional(new DealQualificationSelector()
            .selectDQForDQGOA(dqOrOppId)
            .executeQuery()
        ).getFirst();

        DQ_Deal_Qualification_History__c dqHistory;
        if (dqRecord != null) {
            dqHistory = (DQ_Deal_Qualification_History__c) new ListOptional(new DealQualificationHistorySelector()
                .selectApprovedDQHistory(dqRecord.Id)
                .executeQuery()
            ).getFirst();
        }

        DealQualificationData dqData = new DealQualificationData(dqRecord, dqHistory);

        return dqData;
    }

    public static List<DQ_Approval_Type_Step__c> getApprovalTypeSteps(Set<Id> approvalTypeIdSet, DealQualificationData dqData) {
        List<DQ_Approval_Type_Step__c> result = new List<DQ_Approval_Type_Step__c>();
        if (approvalTypeIdSet == null || approvalTypeIdSet.isEmpty() || dqData == null) {
            return result;
        }
        if (!String.isBlank(dqData.opportunityData.subRegion)) {
            result = new List<DQ_Approval_Type_Step__c>([
                SELECT Id, DQ_Approval_Step__c, DQ_Approval_Step__r.Name, DQ_Approval_Type__c, DQ_Approval_Type__r.ServiceName__c
                FROM DQ_Approval_Type_Step__c
                WHERE DQ_Approval_Type__c IN :approvalTypeIdSet
                    AND Region__c INCLUDES(:dqData.opportunityData.opportunityOwnerRegion)
                    AND Segment__c INCLUDES(:dqData.opportunityData.opportunitySegment)
                    AND Deal_Type__c INCLUDES(:dqData.opportunityData.dealType)
                    AND Brand__c INCLUDES(:dqData.opportunityData.opportunityBrand)
                    AND Sub_Region__c INCLUDES(:dqData.opportunityData.subRegion)
                    AND (Deal_Size__c = null OR (Deal_Size__c != null AND Deal_Size__c < :dqData.opportunityData.masterQuoteDealSize))
                ORDER BY DQ_Approval_Step__r.Step_Order__c DESC
            ]);
        } else {
            result = new List<DQ_Approval_Type_Step__c>([
                SELECT Id, DQ_Approval_Step__c, DQ_Approval_Step__r.Name, DQ_Approval_Type__c, DQ_Approval_Type__r.ServiceName__c
                FROM DQ_Approval_Type_Step__c
                WHERE DQ_Approval_Type__c IN :approvalTypeIdSet
                    AND Region__c INCLUDES(:dqData.opportunityData.opportunityOwnerRegion)
                    AND Segment__c INCLUDES(:dqData.opportunityData.opportunitySegment)
                    AND Deal_Type__c INCLUDES(:dqData.opportunityData.dealType)
                    AND Brand__c INCLUDES(:dqData.opportunityData.opportunityBrand)
                    AND (Deal_Size__c = null OR (Deal_Size__c != null AND Deal_Size__c < :dqData.opportunityData.masterQuoteDealSize))
                ORDER BY DQ_Approval_Step__r.Step_Order__c DESC
            ]);
        }
        return result;
    }

    public static List<DQ_Approval_Step_Approver__c> getApprovalStepApprovers(Set<Id> approvalStepIdSet, DealQualificationData dqData) {
        List<DQ_Approval_Step_Approver__c> result = new List<DQ_Approval_Step_Approver__c>();
        if (approvalStepIdSet == null || approvalStepIdSet.isEmpty() || dqData == null) {
            return result;
        }
        if (!String.isBlank(dqData.opportunityData.subRegion)) {
            result = new List<DQ_Approval_Step_Approver__c>([
                SELECT Id, Name, DQ_Approval_Step__c, OwnerId, Owner.Name, Approval_Type__c, Sub_Region__c, Overall_Discount__c, Deal_Size__c
                FROM DQ_Approval_Step_Approver__c
                WHERE DQ_Approval_Step__c IN :approvalStepIdSet
                    AND Region__c INCLUDES(:dqData.opportunityData.opportunityOwnerRegion)
                    AND Segment__c INCLUDES(:dqData.opportunityData.opportunitySegment)
                    AND Deal_Type__c INCLUDES(:dqData.opportunityData.dealType)
                    AND Brand__c INCLUDES(:dqData.opportunityData.opportunityBrand)
                    AND Sub_Region__c INCLUDES(:dqData.opportunityData.subRegion)
                    AND IsStepApproverForPRM__c =: dqData.mainQuoteData.isPrmQuote
            ]);
        } else {
            result = new List<DQ_Approval_Step_Approver__c>([
                SELECT Id, Name, DQ_Approval_Step__c, OwnerId, Owner.Name, Approval_Type__c, Sub_Region__c, Overall_Discount__c, Deal_Size__c
                FROM DQ_Approval_Step_Approver__c
                WHERE DQ_Approval_Step__c IN :approvalStepIdSet
                    AND Region__c INCLUDES(:dqData.opportunityData.opportunityOwnerRegion)
                    AND Segment__c INCLUDES(:dqData.opportunityData.opportunitySegment)
                    AND Deal_Type__c INCLUDES(:dqData.opportunityData.dealType)
                    AND Brand__c INCLUDES(:dqData.opportunityData.opportunityBrand)
                    AND IsStepApproverForPRM__c =: dqData.mainQuoteData.isPrmQuote
            ]);
        }
        return result;
    }

    private static String buildProductGroupKey(String productCategory, String packageId, String packageVersion, String productId) {
        return String.format('{0}-{1}-{2}-{3}', new List<String>{productCategory, packageId, packageVersion, productId});
    }
}