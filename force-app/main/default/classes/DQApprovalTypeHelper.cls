public without sharing class DQApprovalTypeHelper {

    // Approval types
    public static final String APPROVAL_TYPE_DISCOUNT = 'Discount';
    public static final String APPROVAL_TYPE_INITIAL_TERM = 'Initial Term';
    public static final String APPROVAL_TYPE_SPECIAL_TERM = 'Special Term';
    public static final String APPROVAL_TYPE_CC_SPECIAL_TERM = 'CC Special Term';
    public static final String APPROVAL_TYPE_ED_SPECIAL_TERM = 'ED Special Term';
    public static final String APPROVAL_TYPE_EV_SPECIAL_TERM = 'EV Special Term';
    public static final String APPROVAL_TYPE_PRODUCT_REMOVAL = 'Product Removal';
    public static final String APPROVAL_TYPE_CC_PRODUCT_REMOVAL = 'CC Product Removal';
    public static final String APPROVAL_TYPE_FREE_SHIPPING = 'Free Shipping';
    public static final String APPROVAL_TYPE_DISCRETION = 'Overall Discretion';
    public static final String APPROVAL_TYPE_EV_DISCRETION = 'EV Overall Discretion';
    public static final String APPROVAL_TYPE_ED_DISCRETION = 'ED Overall Discretion';
    public static final String APPROVAL_TYPE_CC_DISCRETION = 'CC Overall Discretion';
    public static final String APPROVAL_TYPE_PS_DISCRETION = 'PS Overall Discretion';
    public static final String APPROVAL_TYPE_AVERAGE_DISCOUNT = 'Average Discount';
    public static final String APPROVAL_TYPE_ED_AVERAGE_DISCOUNT = 'ED Average Discount';
    public static final String APPROVAL_TYPE_EV_AVERAGE_DISCOUNT = 'EV Average Discount';
    public static final String APPROVAL_TYPE_CC_AVERAGE_DISCOUNT = 'CC Average Discount';

    public static final String APPROVAL_TYPE_AUTO_RENEW_REMOVAL = 'Auto Renew Removal';

    public static final String DISCOUNT_APPROVAL_REASON_FORMAT = '{0} discount > {1}%;';
    public static final String SPECIAL_TERM_APPROVAL_REASON_FORMAT = '{0} for {1} exceeds the allowance for {2} Months';
    public static final String EES_PRODUCT_REMOVAL_APPROVAL_REASON = 'EES product removal requested by deal qualification';
    public static final String EES_CC_PRODUCT_REMOVAL_APPROVAL_REASON = 'EES-CC product removal requested by deal qualification';
    public static final String FREE_SHIPPING_APPROVAL_REASON = 'Free shipping approval';
    public static final String AVERAGE_DISCOUNT_APPROVAL_REASON_FORMAT = '{0} Average Discount is more than {1}%;';
    public static final String DISCRETION_APPROVAL_REASON_FORMAT = '{0} discretion of {1} > Overall Discretion {2}%;';
    public static final String AUTO_RENEW_REMOVAL_APPROVAL_REASON = 'Auto-renew removal requested by deal qualification';

    public class ApplicableApprovalTypes {
        public Map<Id, String> approvalTypeIdToReasonMap = new Map<Id, String>();
        public Boolean isFirstLevelApprovalRequired = true;
        public ApplicableApprovalTypes(Map<Id, String> approvalTypeIdToReasonMap, Boolean isFirstLevelApprovalRequired) {
            this.approvalTypeIdToReasonMap = approvalTypeIdToReasonMap;
            this.isFirstLevelApprovalRequired = isFirstLevelApprovalRequired;
        }
    }

    public interface IApprovalTypeHandler {
        Boolean isApprovalTypeApplicable(DQ_Approval_Type__c DQApprovalType, DQDataHelper.QuoteData quoteData);
        ApplicableApprovalTypes getApprovalReason(Map<String, List<DQ_Approval_Type__c>> approvalTypeMap, DQDataHelper.DealQualificationData dqData);
    }

    public abstract class ApprovalTypeProvider {
        String approvalType;
    }

    public class ApprovalTypeDiscountHandler implements IApprovalTypeHandler {
        public Boolean isApprovalTypeApplicable(DQ_Approval_Type__c dqApprovalType, DQDataHelper.QuoteData quoteData){
            return dqApprovalType.Approval_Type__c == APPROVAL_TYPE_DISCOUNT;
        }

        public ApplicableApprovalTypes getApprovalReason(
            Map<String, List<DQ_Approval_Type__c>> approvalTypeMap,
            DQDataHelper.DealQualificationData dqData)
        {
            if(approvalTypeMap != null && !approvalTypeMap.containsKey(APPROVAL_TYPE_DISCOUNT)){
                return null;
            }

            Map<Id, String> approvalTypeIdToReasonMap = new Map<Id, String>();
            Boolean isFirstLevelApprovalRequired = true;
            Map<String, String> productCategoryPickListValuesMap = getProductCategoryPicklistMap();

            for (DQ_Approval_Type__c dqApprovalType : approvalTypeMap.get(APPROVAL_TYPE_DISCOUNT)) {

                DQDataHelper.QuoteData quoteData = dqData.serviceNameToQuoteDataMap.get(dqApprovalType.ServiceName__c);
                DQDataHelper.DealQualificationHistoryData dqHistory = dqData.dqHistoryData;

                if(!isApprovalTypeApplicable(dqApprovalType, quoteData)) {
                    continue;
                }

                Boolean isNotApplicable = dqApprovalType.Initial_Term_Discount__c != null
                    && dqApprovalType.Initial_Term_To_Discount__c != null
                    && quoteData != null
                    && (quoteData?.initialTerm < dqApprovalType.Initial_Term_Discount__c || quoteData?.initialTerm > dqApprovalType.Initial_Term_To_Discount__c)
                    || !dqData.goaCategoryToProductDataMap.containsKey(dqApprovalType.Product_Category__c);


                if (isNotApplicable) {
                    continue;
                }

                Map<String, DQDataHelper.ProductData> productGroupToProductDataMap = dqData.goaCategoryToProductDataMap.get(dqApprovalType.Product_Category__c);
                Map<String, DQDataHelper.ProductData> productGroupToProductDataHistoryMap = dqData.goaCategoryToProductDataHistoryMap.get(dqApprovalType.Product_Category__c);


                for (String productGroupKey : productGroupToProductDataMap.keySet()) {
                    DQDataHelper.ProductData productInfo = productGroupToProductDataMap.get(productGroupKey);
                    if (productInfo.discount >= dqApprovalType.Threshold__c && !productInfo.hasPromotion) {

                        String approvalReason = String.format(
                            DISCOUNT_APPROVAL_REASON_FORMAT,
                            new List<Object>{productCategoryPickListValuesMap.get(dqApprovalType.Product_Category__c), dqApprovalType.Threshold__c.round(SYSTEM.RoundingMode.HALF_UP)}
                        );

                        Boolean isDiscountExceeded = isDiscountExceeded(
                            dqData,
                            productGroupKey,
                            productInfo,
                            dqApprovalType
                        );

                        Boolean isQuantityValidationFailed = validateQuantityChange(productGroupToProductDataHistoryMap, productGroupKey, productInfo, dqApprovalType, dqData);

                        if (isDiscountExceeded || isQuantityValidationFailed) {
                            approvalTypeIdToReasonMap.put(dqApprovalType.Id, approvalReason);
                            isFirstLevelApprovalRequired = true;
                        }

                        if (isQuantityValidationFailed) {
                            if(approvalTypeIdToReasonMap.containskey(dqApprovalType.Id)) {
                                String approvalReasonQuantity = approvalTypeIdToReasonMap.get(dqApprovalType.Id);
                                if (!approvalReasonQuantity.contains(DQDataHelper.CHANGE_IN_QUANTITY_MSG)) {
                                    approvalTypeIdToReasonMap.put(dqApprovalType.Id, DQDataHelper.CHANGE_IN_QUANTITY_MSG+approvalReasonQuantity);
                                }
                            }
                        }
                    }
                }
            }

            return new ApplicableApprovalTypes(approvalTypeIdToReasonMap, isFirstLevelApprovalRequired);
        }
    }

    public class ApprovalTypeSpecialTermHandler extends ApprovalTypeProvider implements IApprovalTypeHandler {
        public ApprovalTypeSpecialTermHandler(String approvalType) {
            this.approvalType = approvalType;
        }

        public Boolean isApprovalTypeApplicable(DQ_Approval_Type__c dqApprovalType, DQDataHelper.QuoteData quoteData) {
            return dqApprovalType.Approval_Type__c == this.approvalType
                && dqApprovalType.Special_Terms__c != null
                && quoteData != null
                && !String.isBlank(quoteData.specialTerms)
                && dqApprovalType.Special_Terms__c.split(';').contains(quoteData.specialTerms);
        }

        public ApplicableApprovalTypes getApprovalReason(
            Map<String, List<DQ_Approval_Type__c>> approvalTypeMap,
            DQDataHelper.DealQualificationData dqData)
        {
            if (approvalTypeMap != null && !approvalTypeMap.containsKey(this.approvalType)) {
                return null;
            }
            Map<Id, String> approvalTypeIdToReasonMap = new Map<Id, String>();
            Boolean isFirstLevelApprovalRequired = true;
            for (DQ_Approval_Type__c dqApprovalType : approvalTypeMap.get(this.approvalType)) {
                Map<String, DQ_Approval_Type__c> serviceNameToApprovalType = getServiceToDqApprovalTypeMap(dqApprovalType);
                DQDataHelper.QuoteData quoteData;
                DQDataHelper.DealQualificationHistoryData dqHistory;
                DQDataHelper.DQServiceDiscountHistoryData dqServiceDiscountHistory;
                DQ_Approval_Type__c dqApprovalTypeFromMap;

                for (String serviceName: serviceNameToApprovalType.keySet()) {
                    if (!dqData.serviceNameToQuoteDataMap.containsKey(serviceName)) {
                        continue;
                    }
                    quoteData = dqData.serviceNameToQuoteDataMap.get(serviceName);
                    dqHistory = dqData.dqHistoryData;
                    dqServiceDiscountHistory = dqHistory?.serviceNameToDQServiceDiscountHistoryDataMap.get(serviceName);
                    dqApprovalTypeFromMap = serviceNameToApprovalType.get(quoteData.serviceName);

                    if (!isApprovalTypeApplicable(dqApprovalTypeFromMap, quoteData)) {
                        continue;
                    }

                    Boolean isApprovedSpecialTermsChanged = !String.isBlank(dqServiceDiscountHistory?.specialTermsHistory)
                        && quoteData.specialTerms != dqServiceDiscountHistory?.specialTermsHistory;
                    if (String.isBlank(dqServiceDiscountHistory?.specialTermsHistory) || isApprovedSpecialTermsChanged) {
                        Boolean isNotApplicable = dqApprovalTypeFromMap.Initial_Term_Discount__c != null
                            && dqApprovalType.Initial_Term_To_Discount__c != null
                            && (quoteData.initialTerm < dqApprovalTypeFromMap.Initial_Term_Discount__c || quoteData.initialTerm > dqApprovalTypeFromMap.Initial_Term_To_Discount__c);

                        if (isNotApplicable) {
                            continue;
                        }

                        String approvalReason = String.format (
                            SPECIAL_TERM_APPROVAL_REASON_FORMAT,
                            new List<Object>{
                                quoteData.specialTerms, serviceName, quoteData.initialTerm
                            }
                        );
                        approvalTypeIdToReasonMap.put(dqApprovalType.Id, approvalReason);
                    }
                }
            }

            return new ApplicableApprovalTypes(approvalTypeIdToReasonMap, isFirstLevelApprovalRequired);
        }
    }

    public class ApprovalTypeFreeShippingHandler implements IApprovalTypeHandler {

        public Boolean isApprovalTypeApplicable(DQ_Approval_Type__c dqApprovalType, DQDataHelper.QuoteData quoteData){
            return dqApprovalType.Approval_Type__c == APPROVAL_TYPE_FREE_SHIPPING
                && dqApprovalType.Free_Shipping_Terms_Options__c != null
                && dqApprovalType.Free_Shipping_Terms_Options__c.toLowerCase().split(';').contains(DQServiceHelper.FREE_SHIPPING_OPTION.toLowerCase())
                && quoteData != null
                && quoteData.freeShippingTermsOption == DQServiceHelper.FREE_SHIPPING_OPTION
                && quoteData.shippingMethodRequiresApprove;
        }

        public ApplicableApprovalTypes getApprovalReason(
            Map<String, List<DQ_Approval_Type__c>> approvalTypeMap,
            DQDataHelper.DealQualificationData dqData)
        {
            if (approvalTypeMap != null && !approvalTypeMap.containsKey(APPROVAL_TYPE_FREE_SHIPPING)) {
                return null;
            }
            Map<Id, String> approvalTypeIdToReasonMap = new Map<Id, String>();
            Boolean isFirstLevelApprovalRequired = true;
            for (DQ_Approval_Type__c dqApprovalType : approvalTypeMap.get(APPROVAL_TYPE_FREE_SHIPPING)) {

                DQDataHelper.QuoteData quoteData = dqData.mainQuoteData;
                DQDataHelper.DealQualificationHistoryData dqHistory = dqData.dqHistoryData;

                if (!isApprovalTypeApplicable(dqApprovalType, quoteData)) {
                    continue;
                }

                Boolean isFreeShippingtermsOptionsChanged = dqHistory?.dqFreeShippingTermsOptionsHistory != DQServiceHelper.FREE_SHIPPING_OPTION;
                if (String.isBlank(dqHistory?.dqFreeShippingTermsOptionsHistory) || isFreeShippingtermsOptionsChanged) {
                    approvalTypeIdToReasonMap.put(dqApprovalType.Id, FREE_SHIPPING_APPROVAL_REASON);
                }
            }

            return new ApplicableApprovalTypes(approvalTypeIdToReasonMap, isFirstLevelApprovalRequired);
        }
    }

    public class ApprovalTypeDiscretionHandler extends ApprovalTypeProvider implements IApprovalTypeHandler {
        public ApprovalTypeDiscretionHandler(String approvalType) {
            this.approvalType = approvalType;
        }

        public Boolean isApprovalTypeApplicable(DQ_Approval_Type__c dqApprovalType, DQDataHelper.QuoteData quoteData){
            return dqApprovalType.Approval_Type__c == this.approvalType
                && quoteData != null
                && quoteData.discretion != null
                && dqApprovalType.Threshold__c <= quoteData.discretion;
        }

        public ApplicableApprovalTypes getApprovalReason(
            Map<String, List<DQ_Approval_Type__c>> approvalTypeMap,
            DQDataHelper.DealQualificationData dqData)
        {
            if (approvalTypeMap != null && !approvalTypeMap.containsKey(this.approvalType)){
                return null;
            }
            Map<Id, String> approvalTypeIdToReasonMap = new Map<Id, String>();
            Boolean isFirstLevelApprovalRequired = true;
            for (DQ_Approval_Type__c dqApprovalType : approvalTypeMap.get(this.approvalType)) {
                Map<String, DQ_Approval_Type__c> serviceNameToApprovalType = getServiceToDqApprovalTypeMap(dqApprovalType);
                DQDataHelper.QuoteData quoteData;
                DQDataHelper.DealQualificationHistoryData dqHistory;
                DQDataHelper.DQServiceDiscountHistoryData dqServiceDiscountHistory;
                DQ_Approval_Type__c dqApprovalTypeFromMap;

                for (String serviceName: serviceNameToApprovalType.keySet()) {
                    if (!dqData.serviceNameToQuoteDataMap.containsKey(serviceName)) {
                        continue;
                    }
                    quoteData = dqData.serviceNameToQuoteDataMap.get(serviceName);
                    dqHistory = dqData.dqHistoryData;
                    dqServiceDiscountHistory = dqHistory?.serviceNameToDQServiceDiscountHistoryDataMap.get(serviceName);
                    dqApprovalTypeFromMap = serviceNameToApprovalType.get(quoteData.serviceName);

                    if (!isApprovalTypeApplicable(dqApprovalTypeFromMap, quoteData)) {
                        continue;
                    }

                    Boolean isDiscretionChanged = dqServiceDiscountHistory?.discretionHistory != null
                        && quoteData.discretion > dqServiceDiscountHistory?.discretionHistory;
                    if (dqServiceDiscountHistory?.discretionHistory == null || isDiscretionChanged) {
                        String approvalReason = String.format (
                            DISCRETION_APPROVAL_REASON_FORMAT,
                            new List<Object>{
                                quoteData.serviceName, quoteData.discretion, dqApprovalTypeFromMap.Threshold__c.round(SYSTEM.RoundingMode.HALF_UP)
                            }
                        );
                        approvalTypeIdToReasonMap.put(dqApprovalTypeFromMap.Id, approvalReason);
                    }
                }
            }

            return new ApplicableApprovalTypes(approvalTypeIdToReasonMap, isFirstLevelApprovalRequired);
        }
    }

    public class ApprovalTypeAverageDiscountHandler extends ApprovalTypeProvider implements IApprovalTypeHandler {
        public ApprovalTypeAverageDiscountHandler(String approvalType) {
            this.approvalType = approvalType;
        }

        public Boolean isApprovalTypeApplicable(DQ_Approval_Type__c dqApprovalType, DQDataHelper.QuoteData quoteData){
            return dqApprovalType.Approval_Type__c == this.approvalType
                && quoteData != null
                && quoteData.averageDiscount != null
                && dqApprovalType.Threshold__c <= quoteData.averageDiscount;
        }

        public ApplicableApprovalTypes getApprovalReason(
            Map<String, List<DQ_Approval_Type__c>> approvalTypeMap,
            DQDataHelper.DealQualificationData dqData)
        {
            if (approvalTypeMap != null && !approvalTypeMap.containsKey(this.approvalType)){
                return null;
            }
            Map<Id, String> approvalTypeIdToReasonMap = new Map<Id, String>();
            Boolean isFirstLevelApprovalRequired = true;
            for (DQ_Approval_Type__c dqApprovalType : approvalTypeMap.get(this.approvalType)) {
                Map<String, DQ_Approval_Type__c> serviceNameToApprovalType = getServiceToDqApprovalTypeMap(dqApprovalType);
                DQDataHelper.QuoteData quoteData;
                DQDataHelper.DealQualificationHistoryData dqHistory;
                DQDataHelper.DQServiceDiscountHistoryData dqServiceDiscountHistory;
                DQ_Approval_Type__c dqApprovalTypeFromMap;

                for (String serviceName: serviceNameToApprovalType.keySet()) {
                    if (!dqData.serviceNameToQuoteDataMap.containsKey(serviceName)) {
                        continue;
                    }
                    quoteData = dqData.serviceNameToQuoteDataMap.get(serviceName);
                    dqHistory = dqData.dqHistoryData;
                    dqServiceDiscountHistory = dqHistory?.serviceNameToDQServiceDiscountHistoryDataMap.get(serviceName);
                    dqApprovalTypeFromMap = serviceNameToApprovalType.get(quoteData.serviceName);

                    if (!isApprovalTypeApplicable(dqApprovalTypeFromMap, quoteData)) {
                        continue;
                    }

                    Boolean isAverageDiscountChanged = dqServiceDiscountHistory?.averageDiscountHistory != null
                        && quoteData.averageDiscount > dqServiceDiscountHistory?.averageDiscountHistory;
                    if (dqServiceDiscountHistory?.averageDiscountHistory == null || isAverageDiscountChanged) {
                        String approvalReason = String.format (
                            AVERAGE_DISCOUNT_APPROVAL_REASON_FORMAT,
                            new List<Object>{
                                quoteData.serviceName,
                                dqApprovalTypeFromMap.Threshold__c.round(SYSTEM.RoundingMode.HALF_UP)
                            }
                        );
                        approvalTypeIdToReasonMap.put(dqApprovalTypeFromMap.Id, approvalReason);
                    }
                }
            }

            return new ApplicableApprovalTypes(approvalTypeIdToReasonMap, isFirstLevelApprovalRequired);
        }
    }

    public class ApprovalTypeAutoRenewRemovalHandler implements IApprovalTypeHandler {

        public Boolean isApprovalTypeApplicable(DQ_Approval_Type__c dqApprovalType, DQDataHelper.QuoteData quoteData) {
            return dqApprovalType.Approval_Type__c == APPROVAL_TYPE_AUTO_RENEW_REMOVAL
                && quoteData != null
                && quoteData.isAutoRenewal != null
                && !quoteData.isAutoRenewal
                && quoteData.packageInfoData?.hasContract != null
                && quoteData.packageInfoData?.hasContract;
        }

        public ApplicableApprovalTypes getApprovalReason(
            Map<String, List<DQ_Approval_Type__c>> approvalTypeMap,
            DQDataHelper.DealQualificationData dqData)
        {
            if (approvalTypeMap != null && !approvalTypeMap.containsKey(APPROVAL_TYPE_AUTO_RENEW_REMOVAL)) {
                return null;
            }
            Map<Id, String> approvalTypeIdToReasonMap = new Map<Id, String>();
            Boolean isFirstLevelApprovalRequired = true;
            for (DQ_Approval_Type__c dqApprovalType : approvalTypeMap.get(APPROVAL_TYPE_AUTO_RENEW_REMOVAL)) {

                DQDataHelper.QuoteData quoteData = dqData.mainQuoteData;
                DQDataHelper.DealQualificationHistoryData dqHistory = dqData.dqHistoryData;

                if (isApprovalTypeApplicable(dqApprovalType, quoteData)) {
                    Boolean isAutoRenewalChanged = dqHistory?.id == null
                        || quoteData.isAutoRenewal != dqHistory?.isAutoRenewalHistory;
                    if (!isAutoRenewalChanged) {
                        continue;
                    }
                    approvalTypeIdToReasonMap.put(dqApprovalType.Id, AUTO_RENEW_REMOVAL_APPROVAL_REASON);
                }
            }

            return new ApplicableApprovalTypes(approvalTypeIdToReasonMap, isFirstLevelApprovalRequired);
        }
    }

    public static ApplicableApprovalTypes getApplicableApprovalTypes(DQDataHelper.DealQualificationData dqData) {
        if (dqData == null) {
            return null;
        }

        List<DQ_Approval_Type__c> dqApprovalTypeList = new DQApprovalTypeSelector()
            .selectApprovalTypesForDqGOA()
            .setQueryCaching(true)
            .executeQuery();

        if (dqApprovalTypeList == null || dqApprovalTypeList.isEmpty()) {
            return null;
        }

        Map<Id, String> approvalTypeIdToReasonMap = new Map<Id, String>();

        Boolean isFirstLevelApprovalRequired = true;

        List<IApprovalTypeHandler> handlers = new List<IApprovalTypeHandler>{
            new ApprovalTypeDiscountHandler(),
            new ApprovalTypeSpecialTermHandler(APPROVAL_TYPE_SPECIAL_TERM),
            new ApprovalTypeSpecialTermHandler(APPROVAL_TYPE_ED_SPECIAL_TERM),
            new ApprovalTypeSpecialTermHandler(APPROVAL_TYPE_EV_SPECIAL_TERM),
            new ApprovalTypeSpecialTermHandler(APPROVAL_TYPE_CC_SPECIAL_TERM),
            new ApprovalTypeFreeShippingHandler(),
            new ApprovalTypeDiscretionHandler(APPROVAL_TYPE_DISCRETION),
            new ApprovalTypeDiscretionHandler(APPROVAL_TYPE_EV_DISCRETION),
            new ApprovalTypeDiscretionHandler(APPROVAL_TYPE_ED_DISCRETION),
            new ApprovalTypeDiscretionHandler(APPROVAL_TYPE_CC_DISCRETION),
            new ApprovalTypeDiscretionHandler(APPROVAL_TYPE_PS_DISCRETION),
            new ApprovalTypeAverageDiscountHandler(APPROVAL_TYPE_AVERAGE_DISCOUNT),
            new ApprovalTypeAverageDiscountHandler(APPROVAL_TYPE_ED_AVERAGE_DISCOUNT),
            new ApprovalTypeAverageDiscountHandler(APPROVAL_TYPE_EV_AVERAGE_DISCOUNT),
            new ApprovalTypeAverageDiscountHandler(APPROVAL_TYPE_CC_AVERAGE_DISCOUNT),
            new ApprovalTypeAutoRenewRemovalHandler()
        };

        Map<String, List<DQ_Approval_Type__c>> approvalTypeMap = new Map<String, List<DQ_Approval_Type__c>>();
        Set<Id> proServDiscretionApprovalTypeIds = new Set<Id>();
        for (DQ_Approval_Type__c dqApprovalType : dqApprovalTypeList) {
            if (dqApprovalType.Approval_Type__c == APPROVAL_TYPE_PS_DISCRETION) {
                proServDiscretionApprovalTypeIds.add(dqApprovalType.Id);
            }
            if(!approvalTypeMap.containsKey(dqApprovalType.Approval_Type__c)){
                approvalTypeMap.put(dqApprovalType.Approval_Type__c, new List<DQ_Approval_Type__c>());
            }
            approvalTypeMap.get(dqApprovalType.Approval_Type__c).add(dqApprovalType);
        }

        for(IApprovalTypeHandler handler: handlers){
            ApplicableApprovalTypes applicableApprovalTypes = handler.getApprovalReason(approvalTypeMap, dqData);
            if(applicableApprovalTypes != null) {
                approvalTypeIdToReasonMap.putAll(applicableApprovalTypes.approvalTypeIdToReasonMap);
                isFirstLevelApprovalRequired = applicableApprovalTypes.isFirstLevelApprovalRequired;
            }
        }
        Boolean isOnlyProServDiscretionApprovalType = getIsOnlyProServDiscretionApprovalType(approvalTypeIdToReasonMap.keySet(), proServDiscretionApprovalTypeIds);

        if (approvalTypeIdToReasonMap.isEmpty() && isFirstLevelApprovalRequired || isOnlyProServDiscretionApprovalType) {
            isFirstLevelApprovalRequired = false;
        }

        return new ApplicableApprovalTypes(approvalTypeIdToReasonMap, isFirstLevelApprovalRequired);
    }

    @TestVisible
    private static Boolean getIsOnlyProServDiscretionApprovalType(Set<Id> approvalTypeIds, Set<Id> proServDiscretionApprovalTypeIds) {
        Boolean isOnlyProServDiscretionApprovalType = false;
        if (approvalTypeIds.isEmpty() || proServDiscretionApprovalTypeIds.isEmpty()) {
            return isOnlyProServDiscretionApprovalType;
        }
        for (Id approvalTypeId : approvalTypeIds) {
            if (proServDiscretionApprovalTypeIds.contains(approvalTypeId)) {
                isOnlyProServDiscretionApprovalType = true;
            } else {
                isOnlyProServDiscretionApprovalType = false;
                break;
            }
        }
        return isOnlyProServDiscretionApprovalType;

    }

    @TestVisible
    private static Boolean validateQuantityChange(
        Map<String, DQDataHelper.ProductData> productGroupToProductDataHistoryMap,
        String productGroupKey,
        DQDataHelper.ProductData productInfo,
        DQ_Approval_Type__c dqApprovalType,
        DQDataHelper.DealQualificationData dqData
    ) {
        Boolean isValidationFailed = false;

        Decimal categoryProductHistoryQuantity = dqData.getCategoryProductHistoryData(
            dqApprovalType.Product_Category__c,
            productInfo,
            DQDataHelper.PRODUCT_DATA_QUANTITY
        );
        Boolean isCategoryProductHistoryQuantityExist = categoryProductHistoryQuantity > 0;

        Decimal packageCategoryHistoryQuantity = dqData.getPackageCategoryHistoryData(
            dqApprovalType.Product_Category__c,
            productInfo,
            DQDataHelper.PRODUCT_DATA_QUANTITY
        );
        Boolean isPackageCategoryHistoryQuantityExist = packageCategoryHistoryQuantity > 0;

        Decimal categoryHistoryQuantity = dqData.getCategoryHistoryData(
            dqApprovalType.Product_Category__c,
            DQDataHelper.PRODUCT_DATA_QUANTITY
        );
        Boolean isCategoryHistoryQuantityExist = categoryHistoryQuantity > 0;

        if (productGroupToProductDataHistoryMap != null && productGroupToProductDataHistoryMap.containsKey(productGroupKey)) {
            Decimal productQuantityHistory = productGroupToProductDataHistoryMap.get(productGroupKey).quantity;
            isValidationFailed = isQuantityChanged(productQuantityHistory, productInfo.quantity);
        } else if (isCategoryProductHistoryQuantityExist) {
            isValidationFailed = isQuantityChanged(categoryProductHistoryQuantity, productInfo.quantity);
        } else if (isPackageCategoryHistoryQuantityExist) {
            isValidationFailed = isQuantityChanged(packageCategoryHistoryQuantity, productInfo.quantity);
        } else if (isCategoryHistoryQuantityExist) {
            isValidationFailed = isQuantityChanged(categoryHistoryQuantity, productInfo.quantity);
        }

        return isValidationFailed;
    }

    private static Boolean isQuantityChanged( Decimal productQuantityHistory, Decimal currentProductQuantity) {
        Boolean isQuantityChanged = false;
        Decimal thresholdQuantity = DQGoa.getDiscountChangeThreshold();
        Decimal increaseQuanity = currentProductQuantity - productQuantityHistory;
        Decimal changeInQuantityPercent = productQuantityHistory == 0 ? 0 : math.abs(((increaseQuanity/productQuantityHistory) * 100));
        if (changeInQuantityPercent > thresholdQuantity) {
            isQuantityChanged = true;
        }

        return isQuantityChanged;
    }

    @TestVisible
    private static Map<String, String> getProductCategoryPicklistMap() {
        Map<String, String> valueToLabelMap = new Map<String, String>();
        List<Schema.PicklistEntry> picklistEntries = Schema.SObjectType.DQ_Approval_Type__c.fields.Product_Category__c.getPicklistValues();
        for(Schema.PicklistEntry entry : picklistEntries){
            valueToLabelMap.put(entry.getValue(), entry.getLabel());
        }
        return valueToLabelMap;
    }

    @TestVisible
    private static Boolean isDiscountExceeded(
        DQDataHelper.DealQualificationData dqData,
        String productGroupKey,
        DQDataHelper.ProductData productInfo,
        DQ_Approval_Type__c dqApprovalType
    ) {
        Boolean result = false;

        Boolean isRequiredDataEmpty = dqApprovalType == null
            || productInfo == null;

        if (isRequiredDataEmpty) {
            return result;
        }

        Map<String, DQDataHelper.ProductData> productGroupToProductDataHistoryMap = dqData.goaCategoryToProductDataHistoryMap.get(dqApprovalType.Product_Category__c);

        Decimal categoryProductDiscount = dqData.getCategoryProductHistoryData(
            dqApprovalType.Product_Category__c,
            productInfo,
            DQDataHelper.PRODUCT_DATA_DISCOUNT
        );
        Boolean isCategoryProductDiscountExist = categoryProductDiscount > 0;
        Boolean isCurrentDiscountExceededCategoryProduct = productInfo.discount > categoryProductDiscount;

        Decimal packageCategoryHistoryDiscount = dqData.getPackageCategoryHistoryData(
            dqApprovalType.Product_Category__c,
            productInfo,
            DQDataHelper.PRODUCT_DATA_DISCOUNT
        );

        Boolean isPackageCategoryDiscountExist = packageCategoryHistoryDiscount > 0;
        Boolean isCurrentDiscountExceededPackageCategory = productInfo.discount > packageCategoryHistoryDiscount;

        Decimal categoryHistoryDiscount = dqData.getCategoryHistoryData(
            dqApprovalType.Product_Category__c,
            DQDataHelper.PRODUCT_DATA_DISCOUNT
        );
        Boolean isCategoryDiscountExist = categoryHistoryDiscount > 0;
        Boolean isCurrentDiscountExceededCategory = productInfo.discount > categoryHistoryDiscount;

        DQDataHelper.ProductData productInfoHistory;

        if (productGroupToProductDataHistoryMap != null && productGroupToProductDataHistoryMap.containsKey(productGroupKey)) {
           productInfoHistory = productGroupToProductDataHistoryMap.get(productGroupKey);
        }

        if (productInfoHistory != null) {
            Boolean isCurrentDiscountExceededApproved = productInfo.discount > productInfoHistory.discount;
            if (isCurrentDiscountExceededApproved) {
                result = true;
            }
        } else {
            if (isCategoryProductDiscountExist) {
                if (isCurrentDiscountExceededCategoryProduct) {
                    result = true;
                }
            } else if (isPackageCategoryDiscountExist) {
                if (isCurrentDiscountExceededPackageCategory) {
                    result = true;
                }
            } else if (isCategoryDiscountExist) {
                if (isCurrentDiscountExceededCategory) {
                    result = true;
                }
            } else {
                result = true;
            }
        }

        return result;
    }

    private static Map<String, DQ_Approval_Type__c> getServiceToDqApprovalTypeMap(DQ_Approval_Type__c dqApprovalType) {
        Map<String, DQ_Approval_Type__c> serviceNameToApprovalType = new Map<String, DQ_Approval_Type__c>();
        if (dqApprovalType.ServiceName__c != null) {
            for (String serviceName : dqApprovalType.ServiceName__c.split(';')) {
                serviceNameToApprovalType.put(serviceName, dqApprovalType);
            }
        }
        return serviceNameToApprovalType;
    }
}