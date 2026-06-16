public without sharing class DQ_ApprovalEngine1 {
    private static final String DISCOUNT_APPROVAL_TYPE = 'Discount';
    private static final String RENEWAL_TERM_APPROVAL_TYPE = 'Renewal Term';
    private static final String INITIAL_TERM_APPROVAL_TYPE = 'Initial Term';
    private static final String SPECIAL_TERM_APPROVAL_TYPE = 'Special Term';
    private static final String CC_SPECIAL_TERM_APPROVAL_TYPE = 'CC Special Term';
    private static final String DEAL_TYPE_APPROVAL_TYPE = 'Deal Size';
    private static final String ELA_STANDARD = 'ELA Standard';
    private static final String ELA_NON_STANDARD = 'ELA Non-Standard';
    private static final String ELA_VALUE_FOR_APPROVAL = 'Yes';
    private static final String TOTAL_DISCOUNT_APPROVAL_TYPE = 'Total Discount';
    public static final String DQ_APPROVED_STATUS = 'Approved';
    private static final String DQ_PENDING_STATUS = 'Pending Approval';
    private static final String DQ_NOTIFICATION_STATUS = 'Notification';
    private static final String DQ_REJECTED_STATUS = 'Rejected';
    public static final String DQ_DISCOUNT_KEYWORD = 'DISCOUNT';
    public static final String DQ_QUANTITY_KEYWORD = 'QUANTITY';
    public static final String DQ_PRODUCT_PACKAGE_KEYWORD = 'PRODUCT PACKAGE';
    public static final String DQ_PRODUCT_KEY_SEPERATOR = '-';
    public static final String DQ_CURRENT_PRODUCT = 'CURRENT';
    public static final String DQ_HISTORY_PRODUCT = 'HISTORY';
    public static final String DQ_MAX_DISCOUNT = 'MAX_DISCOUNT';
    public static final String DQ_MIN_QUANTITY = 'MIN_QUANTITY';
    public static final String DQ_MAX_QUANTITY = 'MAX_QUANTITY';
    private static Boolean IS_QUANTITY_CHANGED = false;
    private static final String CHANGE_IN_QUANTITY_MSG = 'Change in Quantity, ';
    public static final String OVERALL_DISCOUNT_ONETIME_CATEGORY = 'Overall Discount One-Time';
    public static final String OVERALL_DISCOUNT_RECURRING_CATEGORY = 'Overall Discount Recurring';
    public static final String OVERALL_DISCOUNT_CONTACTCENTER_CATEGORY = 'Overall Discount Contact Center';
    public static final String EES_CATEGORY = 'EES';
    public static final String EES_CC_CATEGORY = 'EES-CC';
    public static final String PRODUCT_REMOVAL_APPROVAL_TYPE = 'Product Removal';
    public static final String FREE_SHIPPING_APPROVAL_TYPE = 'Free Shipping';


    public static List<ApproverWrapper> getApproversForDQ(Id dqId) {
        Map<Id, ApproverWrapper> mapOfApproverStepIdVsApproverWrapper = new Map<Id, ApproverWrapper>();
        Map<Id, String> mapOfApprovalTypeIdVsReason = new Map<Id, String>();
        DQ_Deal_Qualification__c dealQualificationRecord = getDealQualificationByIds(new Set<Id> {dqId}).get(0);
        List<DQ_Deal_Qualification_Discounts__c> listOfDQDiscounts = dealQualificationRecord.Deal_Qualification_Discounts__r;

        Map<String, Map<String, Map<String, Object>>> mapOfCurrentProductCategoryIdVsMapOfData =
            new Map<String, Map<String, Map<String, Object>>>();

        for(DQ_Deal_Qualification_Discounts__c eachDiscount : dealQualificationRecord.Deal_Qualification_Discounts__r){

            Map<String, Map<String, Object>> mapOfCurrentCategoryProductVsMapOfData =
                mapOfCurrentProductCategoryIdVsMapOfData.get(eachDiscount.Product_Category__c);

            if (mapOfCurrentCategoryProductVsMapOfData == null) {
                mapOfCurrentCategoryProductVsMapOfData = new Map<String, Map<String, Object>>();
            }

            String key = eachDiscount.Product_Category__c + DQ_PRODUCT_KEY_SEPERATOR + eachDiscount.Product__c;

            Map<String, Object> mapOfDataAndValue = mapOfCurrentCategoryProductVsMapOfData.get(key);
            if (mapOfDataAndValue == null) {
                mapOfDataAndValue = new Map<String, Object>();
            }

            Decimal discount = eachDiscount.Discount__c;
            Decimal quantity = eachDiscount.Quantity__c;

            if (mapOfDataAndValue.keySet().isEmpty()) {
                mapOfDataAndValue.put(DQ_DISCOUNT_KEYWORD, discount);
                mapOfDataAndValue.put(DQ_QUANTITY_KEYWORD, quantity);
            }

            Decimal discountValueFromMap = (Decimal) mapOfDataAndValue.get(DQ_DISCOUNT_KEYWORD);
            Decimal quantityValueFromMap = (Decimal) mapOfDataAndValue.get(DQ_QUANTITY_KEYWORD);

            if (discount > discountValueFromMap) {
                discountValueFromMap = discount;
            }

            if (quantity > quantityValueFromMap) {
                quantityValueFromMap = quantity;
            }

            mapOfDataAndValue.put(DQ_DISCOUNT_KEYWORD, discountValueFromMap);
            mapOfDataAndValue.put(DQ_QUANTITY_KEYWORD, quantityValueFromMap);
            mapOfDataAndValue.put(DQ_PRODUCT_PACKAGE_KEYWORD, eachDiscount.Product_Package__c);

            mapOfCurrentCategoryProductVsMapOfData.put(key, mapOfDataAndValue);

            mapOfCurrentProductCategoryIdVsMapOfData.put(eachDiscount.Product_Category__c, mapOfCurrentCategoryProductVsMapOfData);
        }


        // Consider approval history value with history approved for skip already approved level from core approval logic
        Decimal dqMaxRenewalHistory = 0.0;
        Decimal dqMaxInitialHistory = 0.0;

        Map<String, Map<String, Map<String, Object>>> mapOfHistoryProductCategoryIdVsMapOfData =
      new Map<String, Map<String, Map<String, Object>>>();


        List<DQ_Deal_Qualification_History__c> listOfDQHistory = getApprovedDealQualificationHistoryByIds(new Set<Id> {dqId}, DQ_APPROVED_STATUS);
    DQ_Deal_Qualification_History__c dealQualHistoryRecord;
    for (DQ_Deal_Qualification_History__c eachDQHistoryRecord : listOfDQHistory) {
      dealQualHistoryRecord = eachDQHistoryRecord;
            Decimal historyRenewalTerm =  eachDQHistoryRecord.Renewal_Term__c == null ? 0 : Decimal.valueOf(eachDQHistoryRecord.Renewal_Term__c);
            Decimal historyInitialTerm =  eachDQHistoryRecord.Initial_Term__c == null ? 0 : Decimal.valueOf(eachDQHistoryRecord.Initial_Term__c);
            if (historyRenewalTerm > dqMaxRenewalHistory) {
                dqMaxRenewalHistory = historyRenewalTerm;
            }

            if (historyInitialTerm > dqMaxInitialHistory) {
                dqMaxInitialHistory = historyInitialTerm;
            }

            // create map from history record which already approved as per logic for skip level if already approved
            for (DQ_Deal_Qualification_Discount_History__c eachProductHistory : eachDQHistoryRecord.DQ_Deal_Qualification_Discounts_History__r) {

                Map<String, Map<String, Object>> mapOfHistoryCategoryProductVsMapOfData =
                    mapOfHistoryProductCategoryIdVsMapOfData.get(eachProductHistory.Product_Category__c);

                if (mapOfHistoryCategoryProductVsMapOfData == null) {
                    mapOfHistoryCategoryProductVsMapOfData = new Map<String, Map<String, Object>>();
                }

                String key = eachProductHistory.Product_Category__c + DQ_PRODUCT_KEY_SEPERATOR + eachProductHistory.Product__c;

                Map<String, Object> mapOfDataAndValue = mapOfHistoryCategoryProductVsMapOfData.get(key);
                if (mapOfDataAndValue == null) {
                    mapOfDataAndValue = new Map<String, Object>();
                }

                Decimal discount = eachProductHistory.Discount__c;
                Decimal quantity = eachProductHistory.Quantity__c;

                if (mapOfDataAndValue.keySet().isEmpty()) {
                    mapOfDataAndValue.put(DQ_DISCOUNT_KEYWORD, discount);
                    mapOfDataAndValue.put(DQ_QUANTITY_KEYWORD, quantity);
                }

                Decimal discountValueFromMap = (Decimal) mapOfDataAndValue.get(DQ_DISCOUNT_KEYWORD);
                Decimal quantityValueFromMap = (Decimal) mapOfDataAndValue.get(DQ_QUANTITY_KEYWORD);

                if (discount > discountValueFromMap) {
                    discountValueFromMap = discount;
                }

                if (quantity > quantityValueFromMap) {
                    quantityValueFromMap = quantity;
                }

                mapOfDataAndValue.put(DQ_DISCOUNT_KEYWORD, discountValueFromMap);
                mapOfDataAndValue.put(DQ_QUANTITY_KEYWORD, quantityValueFromMap);
                mapOfDataAndValue.put(DQ_PRODUCT_PACKAGE_KEYWORD, eachProductHistory.Product_Package__c);

                mapOfHistoryCategoryProductVsMapOfData.put(key, mapOfDataAndValue);
                mapOfHistoryProductCategoryIdVsMapOfData.put(eachProductHistory.Product_Category__c, mapOfHistoryCategoryProductVsMapOfData);
            }
        }

        // update wrapper attribute with calculated parameters
        DQWrapperDetail dqRecordParam = createDQWrapperObject(
            dealQualificationRecord, mapOfCurrentProductCategoryIdVsMapOfData, dqMaxInitialHistory, dqMaxRenewalHistory);
        if (needToConsiderApprovalHistoryWithDQComparision(dealQualificationRecord, dealQualHistoryRecord)) {
            Boolean isneedToConsiderApproveHistory = needToConsiderApproveHistory(mapOfCurrentProductCategoryIdVsMapOfData, mapOfHistoryProductCategoryIdVsMapOfData);
            Boolean isNeedToConsiderQuantityApproverHistory = isNeedToConsiderApproveDueToQuantity(
                    mapOfCurrentProductCategoryIdVsMapOfData, mapOfHistoryProductCategoryIdVsMapOfData, isneedToConsiderApproveHistory);

            if (isneedToConsiderApproveHistory && isNeedToConsiderQuantityApproverHistory) {
                dqRecordParam.mapOfHistoryProductCategoryIdVsMapOfData = mapOfHistoryProductCategoryIdVsMapOfData;
                dqRecordParam.dealQualRecordHistory = dealQualHistoryRecord;
            } else {
                dqRecordParam.mapOfHistoryProductCategoryIdVsMapOfData = includeNonUpdatebleDiscountRecords(
                    mapOfCurrentProductCategoryIdVsMapOfData, mapOfHistoryProductCategoryIdVsMapOfData);
                dqRecordParam.dealQualRecordHistory = dealQualHistoryRecord;
            }
        }


        //fetch approval list as per parameter
        List<ApproverWrapper> listOfApproverWrapper = fetchApproverListByWrapper(dqRecordParam);
        // Consider previous value if DQ is Rejected
        if (dealQualificationRecord.Status__c == DQ_REJECTED_STATUS) {
            List<DQ_Deal_Qualification_History__c> listOfPendingDQHistory =
                getApprovedDealQualificationHistoryByIds(new Set<Id> {dqId}, DQ_PENDING_STATUS);

            // If pending record exist only then consider previous value expected pending should be 1 record only
            if(!listOfPendingDQHistory.isEmpty() && listOfPendingDQHistory.size() == 1) {

                // Need to consider on behalf of discount
                Boolean isNeedToConsiderPrevious = isPreviousHistoryNeedToConsiderForApproval(
                    dealQualificationRecord, listOfPendingDQHistory, mapOfCurrentProductCategoryIdVsMapOfData);

                // if need to be consider true as per discount/Quanity range, recreate approver list on as per removing
                // already approved value.
                if(isNeedToConsiderPrevious) {
                    listOfApproverWrapper = getApproverListBasedOnPreviousAction(
                        new Set<Id> {dqId}, listOfApproverWrapper, mapOfCurrentProductCategoryIdVsMapOfData);
                }
            }
        }
        return listOfApproverWrapper;
    }

    private static Boolean isELAStandardAppliedOnDQ(
        DQ_Deal_Qualification__c dealQualificationRecord,
        Decimal approvalMaxPotentialThreshold, String approvalInitialTerms) {
        Boolean isStandardELA = null;
        if (dealQualificationRecord.Is_ELA__c == 'Yes') {
           if (dealQualificationRecord.Maximum_Potential__c > approvalMaxPotentialThreshold &&
                dealQualificationRecord.Charge_Term__c == 'Annual' &&
                dealQualificationRecord.ELA_Initial_Terms__c == approvalInitialTerms) {
                    isStandardELA = true;
            } else {
                isStandardELA = false;
            }
        }
        return isStandardELA;
    }

    private static Boolean  isELAStandardAppliedOnDQHistory(
        DQ_Deal_Qualification_History__c dealQualificationRecordHistory,
        Decimal approvalMaxPotentialThreshold, String approvalInitialTerms) {
        Boolean isStandardELAHistory = null;
        if (dealQualificationRecordHistory.Is_ELA__c == 'Yes') {
            if (dealQualificationRecordHistory.Maximum_Potential__c > approvalMaxPotentialThreshold &&
            dealQualificationRecordHistory.Charge_Term__c == 'Annual' &&
            dealQualificationRecordHistory.ELA_Initial_Terms__c == approvalInitialTerms) {
                isStandardELAHistory = true;
            } else {
                isStandardELAHistory = false;
            }
        }
        return isStandardELAHistory;
    }

    public static Map<String, Map<String, Map<String, Object>>> includeNonUpdatebleDiscountRecords(
        Map<String, Map<String, Map<String, Object>>> mapOfCurrentProductCategoryIdVsMapOfData,
        Map<String, Map<String, Map<String, Object>>>  mapOfHistoryProductCategoryIdVsMapOfData ){

            Map<String, Map<String, Map<String, Decimal>>> mapOfCurrAndHistoryProductPackageDiscountQuantity =
            getDiscountMapAgainstProductPackageCategoryId1( mapOfCurrentProductCategoryIdVsMapOfData, mapOfHistoryProductCategoryIdVsMapOfData);

            Map<String, Map<String, Decimal>> mapOfHistoryProductPackageVsDiscount = mapOfCurrAndHistoryProductPackageDiscountQuantity.get(DQ_HISTORY_PRODUCT);
            for (String productPackageKey : mapOfCurrAndHistoryProductPackageDiscountQuantity.get(DQ_CURRENT_PRODUCT).keySet()) {
                Map<String, Decimal> mapOfHistoryQuantityDetail = mapOfHistoryProductPackageVsDiscount.get(productPackageKey);

                if (mapOfHistoryQuantityDetail == null) {
                    List<String> keySegArray = productPackageKey.split(DQ_PRODUCT_KEY_SEPERATOR);
                    String categoryProductKey = keySegArray[0] + DQ_PRODUCT_KEY_SEPERATOR + keySegArray[1] + DQ_PRODUCT_KEY_SEPERATOR + null;
                    mapOfHistoryQuantityDetail = mapOfHistoryProductPackageVsDiscount.get(categoryProductKey);

                    if (mapOfHistoryQuantityDetail == null) {
                        categoryProductKey = keySegArray[0] + DQ_PRODUCT_KEY_SEPERATOR + null + DQ_PRODUCT_KEY_SEPERATOR + null;
                        mapOfHistoryQuantityDetail = mapOfHistoryProductPackageVsDiscount.get(categoryProductKey);
                    }

                    if (mapOfHistoryQuantityDetail == null) {
                        categoryProductKey = keySegArray[0] + DQ_PRODUCT_KEY_SEPERATOR + null + DQ_PRODUCT_KEY_SEPERATOR + keySegArray[2];
                        mapOfHistoryQuantityDetail = mapOfHistoryProductPackageVsDiscount.get(categoryProductKey);
                    }
                }

                if (mapOfHistoryQuantityDetail != null && !mapOfHistoryQuantityDetail.keySet().isEmpty()) {
                    Decimal currentDiscount = mapOfCurrAndHistoryProductPackageDiscountQuantity.get(DQ_CURRENT_PRODUCT).get(productPackageKey).get(DQ_MAX_DISCOUNT);
                    Decimal historyDiscount = mapOfHistoryQuantityDetail.get(DQ_MAX_DISCOUNT);
                    Decimal currentMaxProductQuantity = mapOfCurrAndHistoryProductPackageDiscountQuantity.get(DQ_CURRENT_PRODUCT).get(productPackageKey).get(DQ_MAX_QUANTITY);
                    Decimal currentMinProductQuantity = mapOfCurrAndHistoryProductPackageDiscountQuantity.get(DQ_CURRENT_PRODUCT).get(productPackageKey).get(DQ_MIN_QUANTITY);
                    List<String> keySegArray = productPackageKey.split(DQ_PRODUCT_KEY_SEPERATOR);
                    String categoryProductKey = keySegArray[0] + DQ_PRODUCT_KEY_SEPERATOR + keySegArray[1];

                    if (currentDiscount > historyDiscount) {
                        if (mapOfHistoryProductCategoryIdVsMapOfData.containsKey(keySegArray[0]) &&
                            mapOfHistoryProductCategoryIdVsMapOfData.get(keySegArray[0]).containsKey(categoryProductKey)) {
              mapOfHistoryProductCategoryIdVsMapOfData.get(keySegArray[0]).remove(categoryProductKey);
                        }
                    }

                    Decimal changeInQuantityPercent = calculateQuanityChangePercent(currentMaxProductQuantity, mapOfHistoryQuantityDetail.get(DQ_MAX_QUANTITY));
                    changeInQuantityPercent = changeInQuantityPercent < 0 ? (-1 * changeInQuantityPercent) : changeInQuantityPercent;

                    if (changeInQuantityPercent > 20) {

                        if (mapOfHistoryProductCategoryIdVsMapOfData.containsKey(keySegArray[0])) {
                            if(mapOfHistoryProductCategoryIdVsMapOfData.get(keySegArray[0]).containsKey(categoryProductKey)) {
                                mapOfHistoryProductCategoryIdVsMapOfData.get(keySegArray[0]).remove(categoryProductKey);
                            }

                            categoryProductKey = keySegArray[0] + DQ_PRODUCT_KEY_SEPERATOR + null;
                            if(mapOfHistoryProductCategoryIdVsMapOfData.get(keySegArray[0]).containsKey(categoryProductKey)) {
                                mapOfHistoryProductCategoryIdVsMapOfData.get(keySegArray[0]).remove(categoryProductKey);
                            }
                        }
                    }


                    if (currentMaxProductQuantity != currentMinProductQuantity) {
                        changeInQuantityPercent = calculateQuanityChangePercent(currentMinProductQuantity, mapOfHistoryQuantityDetail.get(DQ_MAX_QUANTITY));
                        changeInQuantityPercent = changeInQuantityPercent < 0 ? (-1 * changeInQuantityPercent) : changeInQuantityPercent;

                        if (changeInQuantityPercent > 20) {
                            if (mapOfHistoryProductCategoryIdVsMapOfData.containsKey(keySegArray[0])) {
                                if (mapOfHistoryProductCategoryIdVsMapOfData.get(keySegArray[0]).containsKey(categoryProductKey)) {
                                  mapOfHistoryProductCategoryIdVsMapOfData.get(keySegArray[0]).remove(categoryProductKey);
                                }

                                categoryProductKey = keySegArray[0] + DQ_PRODUCT_KEY_SEPERATOR + null;
                                if(mapOfHistoryProductCategoryIdVsMapOfData.get(keySegArray[0]).containsKey(categoryProductKey)) {
                                    mapOfHistoryProductCategoryIdVsMapOfData.get(keySegArray[0]).remove(categoryProductKey);
                                }
                            }
                        }
                    }
                }
            }

            return mapOfHistoryProductCategoryIdVsMapOfData;
    }


    public static Boolean needToConsiderApprovalHistoryWithDQComparision(DQ_Deal_Qualification__c dqRecord, DQ_Deal_Qualification_History__c dqHistoryRecord) {
        Boolean isNeedToConsider = true;
        if (dqHistoryRecord != null && dqHistoryRecord.Initial_Term__c != dqRecord.Initial_Term__c) {
            isNeedToConsider = false;
        }
        return isNeedToConsider;
    }

  private static Map<String, Map<String, Map<String,Decimal>>> getDiscountMapAgainstProductPackageCategoryId1(
        Map<String, Map<String, Map<String, Object>>> mapOfCurrentProductCategoryIdVsMapOfData,
        Map<String, Map<String, Map<String, Object>>> mapOfHistoryProductCategoryIdVsMapOfData) {

            Map<String, Map<String, Map<String,Decimal>>> mapOfCurrAndHistoryProductPackageQuantityDiscount = new Map<String, Map<String, Map<String,Decimal>>>();
            Map<String, Map<String, Decimal>> mapOfCurrentProductPackageDiscountQuantity = new Map<String, Map<String, Decimal>>();

            for (String productCategory : mapOfCurrentProductCategoryIdVsMapOfData.keySet()) {
                if (mapOfCurrentProductCategoryIdVsMapOfData.get(productCategory) != null) {
                    for (String productCategoryIdKey : mapOfCurrentProductCategoryIdVsMapOfData.get(productCategory).keySet()) {
                        Map<String, Object> discountDetails = mapOfCurrentProductCategoryIdVsMapOfData.get(productCategory).get(productCategoryIdKey);

                        if (discountDetails != null && !discountDetails.keySet().isEmpty()) {
                            String key = productCategoryIdKey + DQ_PRODUCT_KEY_SEPERATOR + (String) discountDetails.get(DQ_PRODUCT_PACKAGE_KEYWORD);

                            Map<String, Decimal> mapOfDiscountQuantity = mapOfCurrentProductPackageDiscountQuantity.get(key);
                            if (mapOfDiscountQuantity == null) {
                                mapOfDiscountQuantity = new Map<String, Decimal>();
                            }

                            Decimal discountValue = mapOfDiscountQuantity.get(DQ_MAX_DISCOUNT);
                            if (discountValue == null) {
                                discountValue = (Decimal) discountDetails.get(DQ_DISCOUNT_KEYWORD);
                            }

                            if (discountValue < (Decimal) discountDetails.get(DQ_DISCOUNT_KEYWORD)) {
                                discountValue = (Decimal) discountDetails.get(DQ_DISCOUNT_KEYWORD);
                            }

                            mapOfDiscountQuantity.put(DQ_MAX_DISCOUNT, discountValue);

              Decimal maxQuantityValue =  mapOfDiscountQuantity.get(DQ_MAX_QUANTITY);
                            if (maxQuantityValue == null) {
                                maxQuantityValue = (Decimal) discountDetails.get(DQ_QUANTITY_KEYWORD);
                            }

                            if (maxQuantityValue < (Decimal) discountDetails.get(DQ_QUANTITY_KEYWORD)) {
                                maxQuantityValue = (Decimal) discountDetails.get(DQ_QUANTITY_KEYWORD);
                            }
                            mapOfDiscountQuantity.put(DQ_MAX_QUANTITY, maxQuantityValue);

                            Decimal minQuantityValue =  mapOfDiscountQuantity.get(DQ_MIN_QUANTITY);
                            if (minQuantityValue == null) {
                                minQuantityValue = (Decimal) discountDetails.get(DQ_QUANTITY_KEYWORD);
                            }

                            if (minQuantityValue > (Decimal) discountDetails.get(DQ_QUANTITY_KEYWORD)) {
                                minQuantityValue = (Decimal) discountDetails.get(DQ_QUANTITY_KEYWORD);
                            }
                            mapOfDiscountQuantity.put(DQ_MIN_QUANTITY, minQuantityValue);

                            mapOfCurrentProductPackageDiscountQuantity.put(key, mapOfDiscountQuantity);
                        }
                    }
                }
            }

            mapOfCurrAndHistoryProductPackageQuantityDiscount.put(DQ_CURRENT_PRODUCT, mapOfCurrentProductPackageDiscountQuantity);

            Map<String, Decimal> mapOfHistoryProductPackageDiscount = new Map<String, Decimal>();
            Map<String, Map<String, Decimal>> mapOfHistoryProductPackageDiscountQuantity = new Map<String, Map<String, Decimal>>();

            for (String productCategory : mapOfHistoryProductCategoryIdVsMapOfData.keySet()) {
                if (mapOfHistoryProductCategoryIdVsMapOfData.get(productCategory) != null) {
                    for (String productCategoryIdKey : mapOfHistoryProductCategoryIdVsMapOfData.get(productCategory).keySet()) {
                        Map<String, Object> discountDetails = mapOfHistoryProductCategoryIdVsMapOfData.get(productCategory).get(productCategoryIdKey);

                        if (discountDetails != null && !discountDetails.keySet().isEmpty()) {
                            String key = productCategoryIdKey + DQ_PRODUCT_KEY_SEPERATOR + (String) discountDetails.get(DQ_PRODUCT_PACKAGE_KEYWORD);

                            Map<String, Decimal> mapOfDiscountQuantity = mapOfHistoryProductPackageDiscountQuantity.get(key);
                            if (mapOfDiscountQuantity == null) {
                                mapOfDiscountQuantity = new Map<String, Decimal>();
                            }

                            Decimal discountValue = mapOfDiscountQuantity.get(DQ_MAX_DISCOUNT);
                            if (discountValue == null) {
                                discountValue = (Decimal) discountDetails.get(DQ_DISCOUNT_KEYWORD);
                            }

                            if (discountValue < (Decimal) discountDetails.get(DQ_DISCOUNT_KEYWORD)) {
                                discountValue = (Decimal) discountDetails.get(DQ_DISCOUNT_KEYWORD);
                            }

                            mapOfDiscountQuantity.put(DQ_MAX_DISCOUNT, discountValue);

              Decimal maxQuantityValue =  mapOfDiscountQuantity.get(DQ_MAX_QUANTITY);
                            if (maxQuantityValue == null) {
                                maxQuantityValue = (Decimal) discountDetails.get(DQ_QUANTITY_KEYWORD);
                            }

                            if (maxQuantityValue < (Decimal) discountDetails.get(DQ_QUANTITY_KEYWORD)) {
                                maxQuantityValue = (Decimal) discountDetails.get(DQ_QUANTITY_KEYWORD);
                            }
                            mapOfDiscountQuantity.put(DQ_MAX_QUANTITY, maxQuantityValue);

                            Decimal minQuantityValue =  mapOfDiscountQuantity.get(DQ_MIN_QUANTITY);
                            if (minQuantityValue == null) {
                                minQuantityValue = (Decimal) discountDetails.get(DQ_QUANTITY_KEYWORD);
                            }

                            if (minQuantityValue > (Decimal) discountDetails.get(DQ_QUANTITY_KEYWORD)) {
                                minQuantityValue = (Decimal) discountDetails.get(DQ_QUANTITY_KEYWORD);
                            }
                            mapOfDiscountQuantity.put(DQ_MIN_QUANTITY, minQuantityValue);

                            mapOfHistoryProductPackageDiscountQuantity.put(key, mapOfDiscountQuantity);
                        }

                    }
                }
            }

            mapOfCurrAndHistoryProductPackageQuantityDiscount.put(DQ_HISTORY_PRODUCT, mapOfHistoryProductPackageDiscountQuantity);
            return mapOfCurrAndHistoryProductPackageQuantityDiscount;
    }

    public static boolean needToConsiderApproveHistory(
        Map<String, Map<String, Map<String, Object>>> mapOfCurrentProductCategoryIdVsMapOfData,
        Map<String, Map<String, Map<String, Object>>> mapOfHistoryProductCategoryIdVsMapOfData) {
            Boolean isNeedToConsiderApproveHistory = true;

        Map<String, Map<String, Map<String, Decimal>>> mapOfCurrAndHistoryProductPackageDiscountQuantity =
            getDiscountMapAgainstProductPackageCategoryId1( mapOfCurrentProductCategoryIdVsMapOfData, mapOfHistoryProductCategoryIdVsMapOfData);

        Map<String, Map<String, Decimal>> mapOfHistoryProductPackageVsDiscount = mapOfCurrAndHistoryProductPackageDiscountQuantity.get(DQ_HISTORY_PRODUCT);
        for (String productPackageKey : mapOfCurrAndHistoryProductPackageDiscountQuantity.get(DQ_CURRENT_PRODUCT).keySet()) {
            Map<String, Decimal> mapOfHistoryQuantityDetail = mapOfHistoryProductPackageVsDiscount.get(productPackageKey);

            if (mapOfHistoryQuantityDetail == null || mapOfHistoryQuantityDetail.keySet().isEmpty()) {

                List<String> productPackageKeySplitArray = productPackageKey.split(DQ_PRODUCT_KEY_SEPERATOR);

                String productPackageKeyWithNoProduct = productPackageKeySplitArray.get(0) + DQ_PRODUCT_KEY_SEPERATOR + null + DQ_PRODUCT_KEY_SEPERATOR +  productPackageKeySplitArray.get(2);
                mapOfHistoryQuantityDetail = mapOfHistoryProductPackageVsDiscount.get(productPackageKeyWithNoProduct);

                if (mapOfHistoryQuantityDetail == null || mapOfHistoryQuantityDetail.keySet().isEmpty()) {

                    String keyWithNoProductPackageAndId = productPackageKeySplitArray.get(0) + DQ_PRODUCT_KEY_SEPERATOR + null + DQ_PRODUCT_KEY_SEPERATOR +  null;
                    mapOfHistoryQuantityDetail = mapOfHistoryProductPackageVsDiscount.get(keyWithNoProductPackageAndId);

                    if (mapOfHistoryQuantityDetail == null || mapOfHistoryQuantityDetail.keySet().isEmpty()) {
                        isNeedToConsiderApproveHistory = false;
                        break;
                    }
                }
            }

            if (mapOfHistoryQuantityDetail != null && !mapOfHistoryQuantityDetail.keySet().isEmpty()) {
                Decimal currentDiscount = mapOfCurrAndHistoryProductPackageDiscountQuantity.get(DQ_CURRENT_PRODUCT).get(productPackageKey).get(DQ_MAX_DISCOUNT);
                Decimal historyDiscount = mapOfHistoryQuantityDetail.get(DQ_MAX_DISCOUNT);

                if (currentDiscount > historyDiscount) {
                    isNeedToConsiderApproveHistory = false;
                    break;
                }
            }
        }

          if (isNeedToConsiderApproveHistory) {
                for (String productCategory : mapOfCurrentProductCategoryIdVsMapOfData.keySet()) {

                    Map<String, Map<String, Object>>  mapOfProductIdVsDiscount =
                        mapOfCurrentProductCategoryIdVsMapOfData.get(productCategory);
                    Map<String, Map<String, Object>>  mapOfProductIdVsDiscountHistory =
                        mapOfHistoryProductCategoryIdVsMapOfData.get(productCategory);

                    if (mapOfProductIdVsDiscountHistory == null || mapOfProductIdVsDiscountHistory.keySet().isEmpty()) {
                        isNeedToConsiderApproveHistory = false;
                        break;
                    }

                    if (mapOfProductIdVsDiscountHistory != null) {
                        for (String categoryProductId : mapOfProductIdVsDiscount.keySet()) {

                            Decimal productDiscount = (Decimal) mapOfProductIdVsDiscount.get(categoryProductId).get(DQ_DISCOUNT_KEYWORD);
                            Decimal productDiscountHistory = 0;
                            if (mapOfProductIdVsDiscountHistory.get(categoryProductId) != null) {
                                productDiscountHistory = (Decimal) mapOfProductIdVsDiscountHistory.get(categoryProductId).get(DQ_DISCOUNT_KEYWORD);
                            }

                            String withoutProductCategoryKey = productCategory + DQ_PRODUCT_KEY_SEPERATOR + null;
                            if (productDiscountHistory == 0 && mapOfProductIdVsDiscountHistory.get(withoutProductCategoryKey) != null) {
                                productDiscountHistory = (Decimal) mapOfProductIdVsDiscountHistory.get(withoutProductCategoryKey).get(DQ_DISCOUNT_KEYWORD);
                            }

                            if (productDiscountHistory == null) {
                                isNeedToConsiderApproveHistory = false;
                                break;
                            }

                            if (productDiscount > productDiscountHistory) {
                                isNeedToConsiderApproveHistory = false;
                                break;
                            }

                            String productPackageId = productCategory + DQ_PRODUCT_KEY_SEPERATOR +
                                categoryProductId + DQ_PRODUCT_KEY_SEPERATOR +
                                (String) mapOfProductIdVsDiscount.get(categoryProductId).get(DQ_PRODUCT_PACKAGE_KEYWORD);
                        }
                    }
                }
            }
            return isNeedToConsiderApproveHistory;
    }

    public static Boolean isNeedToConsiderApproveDueToQuantity(
        Map<String, Map<String, Map<String, Object>>> mapOfCurrentProductCategoryIdVsMapOfData,
        Map<String, Map<String, Map<String, Object>>> mapOfHistoryProductCategoryIdVsMapOfData,
        Boolean isNeedToConsiderApproveHistory) {

            Map<String, Map<String, Map<String, Decimal>>> mapOfCurrAndHistoryProductPackageDiscountQuantity =
                getDiscountMapAgainstProductPackageCategoryId1( mapOfCurrentProductCategoryIdVsMapOfData, mapOfHistoryProductCategoryIdVsMapOfData);

            Map<String, Map<String, Decimal>> mapOfHistoryProductPackageVsDiscount = mapOfCurrAndHistoryProductPackageDiscountQuantity.get(DQ_HISTORY_PRODUCT);
            for (String productPackageKey : mapOfCurrAndHistoryProductPackageDiscountQuantity.get(DQ_CURRENT_PRODUCT).keySet()) {
                Map<String, Decimal> mapOfHistoryQuantityDetail = mapOfHistoryProductPackageVsDiscount.get(productPackageKey);

                if (mapOfHistoryQuantityDetail == null || mapOfHistoryQuantityDetail.keySet().isEmpty()) {

                    List<String> productPackageKeySplitArray = productPackageKey.split(DQ_PRODUCT_KEY_SEPERATOR);

                    String productPackageKeyWithNoProduct = productPackageKeySplitArray.get(0) + DQ_PRODUCT_KEY_SEPERATOR + null + DQ_PRODUCT_KEY_SEPERATOR +  productPackageKeySplitArray.get(2);
                    mapOfHistoryQuantityDetail = mapOfHistoryProductPackageVsDiscount.get(productPackageKeyWithNoProduct);

                    if (mapOfHistoryQuantityDetail == null || mapOfHistoryQuantityDetail.keySet().isEmpty()) {

                        String keyWithNoProductPackageAndId = productPackageKeySplitArray.get(0) + DQ_PRODUCT_KEY_SEPERATOR + null + DQ_PRODUCT_KEY_SEPERATOR +  null;
                        mapOfHistoryQuantityDetail = mapOfHistoryProductPackageVsDiscount.get(keyWithNoProductPackageAndId);

                        if (mapOfHistoryQuantityDetail == null || mapOfHistoryQuantityDetail.keySet().isEmpty()) {
                            isNeedToConsiderApproveHistory = false;
                            break;
                        }
                    }
                }

                if (mapOfHistoryQuantityDetail != null && !mapOfHistoryQuantityDetail.keySet().isEmpty()) {
                    Decimal currentMaxProductQuantity = mapOfCurrAndHistoryProductPackageDiscountQuantity.get(DQ_CURRENT_PRODUCT).get(productPackageKey).get(DQ_MAX_QUANTITY);
                    Decimal currentMinProductQuantity = mapOfCurrAndHistoryProductPackageDiscountQuantity.get(DQ_CURRENT_PRODUCT).get(productPackageKey).get(DQ_MIN_QUANTITY);

                    Decimal changeInQuantityPercent = calculateQuanityChangePercent(currentMaxProductQuantity, mapOfHistoryQuantityDetail.get(DQ_MAX_QUANTITY));
                    changeInQuantityPercent = changeInQuantityPercent < 0 ? (-1 * changeInQuantityPercent) : changeInQuantityPercent;

                    if (changeInQuantityPercent > 20) {
                        IS_QUANTITY_CHANGED = true;
                        isNeedToConsiderApproveHistory = false;
                        break;
                    }

                    if (currentMaxProductQuantity != currentMinProductQuantity) {
                        changeInQuantityPercent = calculateQuanityChangePercent(currentMinProductQuantity, mapOfHistoryQuantityDetail.get(DQ_MAX_QUANTITY));
                        changeInQuantityPercent = changeInQuantityPercent < 0 ? (-1 * changeInQuantityPercent) : changeInQuantityPercent;
                        if (changeInQuantityPercent > 20) {
                            IS_QUANTITY_CHANGED = true;
                            isNeedToConsiderApproveHistory = false;
                            break;
                        }
                    }
                }
            }





            if (isNeedToConsiderApproveHistory) {

                for (String productCategory : mapOfCurrentProductCategoryIdVsMapOfData.keySet()) {

                    Map<String, Map<String, Object>>  mapOfProductIdVsQuantity =
                        mapOfCurrentProductCategoryIdVsMapOfData.get(productCategory);
                    Map<String, Map<String, Object>>  mapOfProductIdVsQuantityHistory =
                        mapOfHistoryProductCategoryIdVsMapOfData.get(productCategory);

                    for (String categoryProductId : mapOfProductIdVsQuantity.keySet()) {
                        Decimal productQuantity = (Decimal) mapOfProductIdVsQuantity.get(categoryProductId).get(DQ_QUANTITY_KEYWORD);
                        Decimal productQuantityHistory = 0;
                        if (mapOfProductIdVsQuantityHistory.get(categoryProductId) != null) {
                            productQuantityHistory = (Decimal) mapOfProductIdVsQuantityHistory.get(categoryProductId).get(DQ_QUANTITY_KEYWORD);
                        }

                        Decimal changeInQuantityPercent = calculateQuanityChangePercent(productQuantity, productQuantityHistory);
                        changeInQuantityPercent = changeInQuantityPercent < 0 ? (-1 * changeInQuantityPercent) : changeInQuantityPercent;
                        if (changeInQuantityPercent > 20) {
                            IS_QUANTITY_CHANGED = true;
                            isNeedToConsiderApproveHistory = false;
                            break;
                        }
                    }
                }
            }
            return isNeedToConsiderApproveHistory;
    }

    /**
    * Validate if previous approval history record need to be consider
    */
    private static boolean isPreviousHistoryNeedToConsiderForApproval(
        DQ_Deal_Qualification__c dealQualificationRecord, List<DQ_Deal_Qualification_History__c> listOfPendingDQHistory,
        Map<String, Map<String, Map<String, Object>>> mapOfCurrentProductCategoryIdVsMapOfData)
    {
        String initialTerm = listOfPendingDQHistory.get(0).Initial_Term__c;
        boolean needToConsiderPendingValue = dealQualificationRecord.Initial_Term__c > initialTerm ? true : false;
        Map<String, Map<String, DQ_Deal_Qualification_Discount_History__c>> mapOfProductCategoryProductDiscountHistory =
            new Map<String, Map<String, DQ_Deal_Qualification_Discount_History__c>>();
            for (DQ_Deal_Qualification_Discount_History__c eachProductHistory :
                 listOfPendingDQHistory.get(0).DQ_Deal_Qualification_Discounts_History__r)
            {
              Map<String, DQ_Deal_Qualification_Discount_History__c> mapOfProductKeyVsDealQualHistory =
                mapOfProductCategoryProductDiscountHistory.get(eachProductHistory.Product_Category__c);

                if (mapOfProductKeyVsDealQualHistory == null) {
                    mapOfProductKeyVsDealQualHistory = new Map<String, DQ_Deal_Qualification_Discount_History__c>();
                }

                String productKey = eachProductHistory.Product_Category__c + DQ_PRODUCT_KEY_SEPERATOR + eachProductHistory.Product__c;
                if (mapOfProductKeyVsDealQualHistory.get(productKey) == null) {
                    mapOfProductKeyVsDealQualHistory.put(productKey, eachProductHistory);
                }

                mapOfProductCategoryProductDiscountHistory.put(eachProductHistory.Product_Category__c, mapOfProductKeyVsDealQualHistory);
            }

        if (!needToConsiderPendingValue) {
            needToConsiderPendingValue = true;
                 for(String productCategory : mapOfCurrentProductCategoryIdVsMapOfData.keySet()) {
                     Map<String, Map<String, Object>> mapOfProductKeyVsDiscount = mapOfCurrentProductCategoryIdVsMapOfData.get(productCategory);
                     Map<String, DQ_Deal_Qualification_Discount_History__c> mapOfProductKeyVsDiscountHistory =
                        mapOfProductCategoryProductDiscountHistory.get(productCategory);

                    if (mapOfProductKeyVsDiscountHistory == null) {
                        needToConsiderPendingValue = false;
                        break;
                    }

                    for (String productKey : mapOfProductKeyVsDiscount.keySet()) {
                        Map<String, Object> mapOfCurrentProductData = mapOfProductKeyVsDiscount.get(productKey);
                        DQ_Deal_Qualification_Discount_History__c dealQualDiscountHistory = mapOfProductKeyVsDiscountHistory.get(productKey);

                        if (dealQualDiscountHistory == null) {
                            needToConsiderPendingValue = false;
                            break;
                        }

                         if (mapOfCurrentProductData.get(DQ_DISCOUNT_KEYWORD) != dealQualDiscountHistory.Discount__c) {
                             needToConsiderPendingValue = false;
                             break;
                         }

                         Decimal changeInQuanityPercent = calculateQuanityChangePercent((Decimal)mapOfCurrentProductData.get(DQ_QUANTITY_KEYWORD), (Decimal)dealQualDiscountHistory.Quantity__c);
                         changeInQuanityPercent = changeInQuanityPercent < 0 ? (-1 * changeInQuanityPercent) : changeInQuanityPercent;

                         if (changeInQuanityPercent > 20) {
                            needToConsiderPendingValue = false;
                            break;
                         }
                    }
                 }
        }
        return needToConsiderPendingValue;
    }


    private static List<ApproverWrapper> getApproverListBasedOnPreviousAction(
        Set<Id> setOfDqId, List<ApproverWrapper> listOfApproverWrapper,
        Map<String, Map<String, Map<String, Object>>> mapOfCurrentProductCategoryIdVsMapOfData)
    {
        List<ApproverWrapper> listOfUpdatedApproverWrapper = new List<ApproverWrapper>();

        List<DQ_Deal_Qualification_Approver__c> listOfDQQualApprover = getDQQualificationApproverByDQId(setOfDqId);

        Map<Id, DQ_Deal_Qualification_Approver__c> mapOfApproverStepApproverVsDealQualApprover =
            getMapOfApproverStepApproverVsDealQualApprover(listOfDQQualApprover);

        for (ApproverWrapper eachRecord : listOfApproverWrapper) {
            Boolean isNeedToConsider = false;

            for(DQ_Approval_Step_Approver__c eachApproverStep : eachRecord.listOfStepApprover) {
                if (eachApproverStep == null) {
                    continue;
                }
                DQ_Deal_Qualification_Approver__c dealQualApproverRec = mapOfApproverStepApproverVsDealQualApprover.get(eachApproverStep.Id);

                if (dealQualApproverRec == null) {
                    isNeedToConsider = true;
                    break;
                }

                if (dealQualApproverRec != null
                    && (dealQualApproverRec.Status__c != DQ_APPROVED_STATUS && dealQualApproverRec.Status__c != DQ_NOTIFICATION_STATUS)) {
                        isNeedToConsider = true;
                        break;
                    }
            }

            if (isNeedToConsider) {
                listOfUpdatedApproverWrapper.add(eachRecord);
            }
        }
        return listOfUpdatedApproverWrapper;
    }

    private static DQWrapperDetail createDQWrapperObject(
        DQ_Deal_Qualification__c dealQualificationRecord,
        Map<String, Map<String, Map<String, Object>>> mapOfCurrentProductCategoryIdVsMapOfData,
    Decimal dqMaxInitialHistory, Decimal dqMaxRenewalHistory) {
            DQWrapperDetail dqRecordParam = new DQWrapperDetail();
            dqRecordParam.opportunityId = dealQualificationRecord.Opportunity__c;
            dqRecordParam.dqInitialTerm = dealQualificationRecord.Initial_Term__c == null ? 0 : Decimal.valueOf(dealQualificationRecord.Initial_Term__c);
            dqRecordParam.dqRenewalTerm = dealQualificationRecord.Renewal_Term__c == null ? 0 : Decimal.valueOf(dealQualificationRecord.Renewal_Term__c);
            dqRecordParam.dqRegion = dealQualificationRecord.Region__c;
            dqRecordParam.dqSubRegion = dealQualificationRecord.Sub_Region__c;
            if(dealQualificationRecord.Region__c == null) {
                dqRecordParam = assignDefaultRegionSubregion(dqRecordParam);
            }
            dqRecordParam.dqSegment = dealQualificationRecord.Segment__c;
            dqRecordParam.dqDealType = dealQualificationRecord.Deal_Type__c;
            dqRecordParam.dqBrand  = dealQualificationRecord.Brand__c;
            dqRecordParam.overAllDiscount = dealQualificationRecord.Overall_Discount__c;
            dqRecordParam.overAllDiscountOneTime = dealQualificationRecord.Overall_Discount_One_Time__c;
            dqRecordParam.overAllDiscountRecurring =dealQualificationRecord.Overall_Discount_Recurring__c;
            dqRecordParam.overAllDiscountContactCenter =dealQualificationRecord.Overall_Discount_Contact_Center__c;
            dqRecordParam.dealSize = dealQualificationRecord.Deal_Size__c;
            dqRecordParam.dealQualificationId = dealQualificationRecord.Id;
            dqRecordParam.dqMaxInitialHistory = dqMaxInitialHistory;
            dqRecordParam.dqMaxRenewalHistory = dqMaxRenewalHistory;
            if(dealQualificationRecord != null && dealQualificationRecord.IsDQCreatedFromCPQOpp__c)
            {
                dqRecordParam.isCPQDQ = true;
            }
            else
            {
                dqRecordParam.isCPQDQ = false;
            }
            dqRecordParam.mapOfCurrentProductCategoryIdVsMapOfData = mapOfCurrentProductCategoryIdVsMapOfData;
            dqRecordParam.mapOfHistoryProductCategoryIdVsMapOfData = new Map<String, Map<String, Map<String, Object>>>();
      dqRecordParam.dealQualRecord = dealQualificationRecord;
            return dqRecordParam;
    }

    private static List<ApproverWrapper> fetchApproverListByWrapper(DQWrapperDetail dqRecordParam) {
        Map<Id, ApproverWrapper> mapOfApproverStepIdVsApproverWrapper = new Map<Id, ApproverWrapper>();
        Map<String, String> mapOfProductCategoryValueVsLabel = getProductCategoryAPIPickListMap();
        Map<Id, String> mapOfApprovalTypeIdVsReason = new Map<Id, String>();
        List<DQ_Approval_Type__c> listOfDQApprovalType = new List<DQ_Approval_Type__c>();
        if(dqRecordParam.isCPQDQ != null && dqRecordParam.isCPQDQ)
        {
            listOfDQApprovalType = getActiveCPQDQApprovalType();
        }
        else
        {
            listOfDQApprovalType = getActiveDQApprovalType();
        }
        Boolean isFirstLevelApprovalRequire = true;
        Boolean isDiscountApprovalApplicableCPQ = false;
        if (!listOfDQApprovalType.isEmpty()) {
            Set<Id> setOfApprovalTypeId = new Set<Id>();
            Map<Id, Decimal> mapOfApproverTypeIdVsDiscount = new Map<Id, Decimal>();
            Decimal dealQualInitialTerm = dqRecordParam.dealQualRecord.Initial_Term__c != null ? Decimal.valueOf(dqRecordParam.dealQualRecord.Initial_Term__c) : null;
            Decimal ccDealQualInitialTerm = 0;
            if(dqRecordParam.isCPQDQ != null && dqRecordParam.isCPQDQ)
            {
                ccDealQualInitialTerm  = dealQualInitialTerm;
            }
            else
            {
                ccDealQualInitialTerm = dqRecordParam.dealQualRecord.CC_Initial_Term__c != null ? Decimal.valueOf(dqRecordParam.dealQualRecord.CC_Initial_Term__c) : null;
            }
            if (dealQualInitialTerm == null) {
                if (dqRecordParam.dqInitialTerm != null) {
                    dealQualInitialTerm = dqRecordParam.dqInitialTerm;
                }
            }

            if (dealQualInitialTerm == null) {
                dealQualInitialTerm = 0;
            }
            if (ccDealQualInitialTerm == null) {
                ccDealQualInitialTerm = 0;
            }


            for (DQ_Approval_Type__c eachApprovalType : listOfDQApprovalType) {
                String approvalReason = '';

        system.debug('dqRecordParam.mapOfCurrentProductCategoryIdVsMapOfData>>'+dqRecordParam.mapOfCurrentProductCategoryIdVsMapOfData);
                system.debug('eachApprovalType.Product_Category__c>>'+eachApprovalType.Product_Category__c);
                if (eachApprovalType.Approval_Type__c.equals(DISCOUNT_APPROVAL_TYPE)
                    && dqRecordParam.mapOfCurrentProductCategoryIdVsMapOfData.containsKey(eachApprovalType.Product_Category__c)){
                        if (eachApprovalType.Initial_Term_Discount__c != null  && eachApprovalType.Initial_Term_To_Discount__c != null
              && (dealQualInitialTerm < eachApprovalType.Initial_Term_Discount__c
              || dealQualInitialTerm > eachApprovalType.Initial_Term_To_Discount__c)) {
                            continue;
                        }

                        Map<String, Map<String, Object>> mapOfCurrentProductIdsVsDiscount =
                            dqRecordParam.mapOfCurrentProductCategoryIdVsMapOfData.get(eachApprovalType.Product_Category__c);

                        Map<String, Map<String, Object>> mapOfHistoryProductIdsVsDiscount =
                            dqRecordParam.mapOfHistoryProductCategoryIdVsMapOfData.get(eachApprovalType.Product_Category__c);

                        if(!mapOfCurrentProductIdsVsDiscount.keySet().isEmpty()) {
                            Decimal categoryHistoryDiscount = 0;

                            // checking for category if present without product in map
                            String withoutProductCategoryKey = eachApprovalType.Product_Category__c + DQ_PRODUCT_KEY_SEPERATOR + null;
                            if (mapOfHistoryProductIdsVsDiscount != null &&
                                mapOfHistoryProductIdsVsDiscount.get(withoutProductCategoryKey) != null) {
                                Map<String, Object> mapOfDiscountAndQuantityHistory =
                                    mapOfHistoryProductIdsVsDiscount.get(withoutProductCategoryKey);
                                categoryHistoryDiscount = (Decimal) mapOfDiscountAndQuantityHistory.get(DQ_DISCOUNT_KEYWORD);
                            }

                            for(String currentProductId : mapOfCurrentProductIdsVsDiscount.keySet()) {
                                String key = currentProductId;
                                Decimal currentProductDiscount = (Decimal) mapOfCurrentProductIdsVsDiscount.get(currentProductId).get(DQ_DISCOUNT_KEYWORD);

                                if (currentProductDiscount >= eachApprovalType.Threshold__c) {
                                    approvalReason = mapOfProductCategoryValueVsLabel.get(eachApprovalType.Product_Category__c) + ' discount is more than or equal to ' + eachApprovalType.Threshold__c + '%';

                                    if(mapOfHistoryProductIdsVsDiscount != null && mapOfHistoryProductIdsVsDiscount.containsKey(key)) {
                                        Decimal historyProductDiscount = (Decimal) mapOfHistoryProductIdsVsDiscount.get(currentProductId).get(DQ_DISCOUNT_KEYWORD);
                                        if(currentProductDiscount > categoryHistoryDiscount && currentProductDiscount > historyProductDiscount
                                           && historyProductDiscount < eachApprovalType.Threshold__c)
                                        {
                                            setOfApprovalTypeId.add(eachApprovalType.Id);
                                            mapOfApprovalTypeIdVsReason.put(eachApprovalType.Id, approvalReason);
                                            mapOfApproverTypeIdVsDiscount.put(eachApprovalType.Id, currentProductDiscount);
                                            if(!eachApprovalType.IsCPQApprovalType__c) {
                                                isFirstLevelApprovalRequire = true;
                                            } else {
                                                isDiscountApprovalApplicableCPQ = true;
                                            }
                                        }
                                    } else {
                                        if (currentProductDiscount > categoryHistoryDiscount) {
                                            setOfApprovalTypeId.add(eachApprovalType.Id);
                                            mapOfApprovalTypeIdVsReason.put(eachApprovalType.Id, approvalReason);
                                            mapOfApproverTypeIdVsDiscount.put(eachApprovalType.Id, currentProductDiscount);
                                            if(!eachApprovalType.IsCPQApprovalType__c) {
                                                isFirstLevelApprovalRequire = true;
                                            } else {
                                                isDiscountApprovalApplicableCPQ = true;
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    else if (eachApprovalType.Approval_Type__c.equals(INITIAL_TERM_APPROVAL_TYPE)
                        && eachApprovalType.Threshold__c == dqRecordParam.dqInitialTerm
                        && (dqRecordParam.dqMaxInitialHistory == 0 || eachApprovalType.Threshold__c != dqRecordParam.dqMaxInitialHistory)) {
                            setOfApprovalTypeId.add(eachApprovalType.Id);
                            approvalReason = 'Initial term is equal to ' + eachApprovalType.Threshold__c;
                            mapOfApprovalTypeIdVsReason.put(eachApprovalType.Id, approvalReason);
                        }

                    else if (eachApprovalType.Approval_Type__c.equals(RENEWAL_TERM_APPROVAL_TYPE)
                        && eachApprovalType.Threshold__c == dqRecordParam.dqRenewalTerm
                        && (dqRecordParam.dqMaxRenewalHistory == 0 || eachApprovalType.Threshold__c != dqRecordParam.dqMaxRenewalHistory)) {
                            setOfApprovalTypeId.add(eachApprovalType.Id);
                            approvalReason = 'Renewal term is equal to ' + eachApprovalType.Threshold__c;
                            mapOfApprovalTypeIdVsReason.put(eachApprovalType.Id, approvalReason);
                        }

                    else if(eachApprovalType.Approval_Type__c.equals(SPECIAL_TERM_APPROVAL_TYPE)
                        && dqRecordParam.dealQualRecord != null && dqRecordParam.dealQualRecord.Special_Terms__c != null && eachApprovalType.Special_Terms__c != null
                        && eachApprovalType.Special_Terms__c.split(';').contains(dqRecordParam.dealQualRecord.Special_Terms__c)) {
                            if (dqRecordParam.dealQualRecordHistory == null ||
                                (dqRecordParam.dealQualRecordHistory != null && dqRecordParam.dealQualRecordHistory.Special_Terms__c != dqRecordParam.dealQualRecord.Special_Terms__c)) {

                                    if (eachApprovalType.Initial_Term_Discount__c != null  && eachApprovalType.Initial_Term_To_Discount__c != null
                                        && (dealQualInitialTerm < eachApprovalType.Initial_Term_Discount__c
                                            || dealQualInitialTerm > eachApprovalType.Initial_Term_To_Discount__c)) {
                                                continue;
                                            }

                                setOfApprovalTypeId.add(eachApprovalType.Id);
                                approvalReason = dqRecordParam.dealQualRecord.Special_Terms__c + ' special terms contained by deal qualification';
                                mapOfApprovalTypeIdVsReason.put(eachApprovalType.Id, approvalReason);
                            }
                    }
                    else if(eachApprovalType.Approval_Type__c.equals(CC_SPECIAL_TERM_APPROVAL_TYPE)
                        && dqRecordParam.dealQualRecord != null && dqRecordParam.dealQualRecord.CC_Special_Terms__c != null && eachApprovalType.CC_Special_Terms__c != null
                        && eachApprovalType.CC_Special_Terms__c.split(';').contains(dqRecordParam.dealQualRecord.CC_Special_Terms__c)) {
                            if (dqRecordParam.dealQualRecordHistory == null ||
                                (dqRecordParam.dealQualRecordHistory != null && dqRecordParam.dealQualRecordHistory.CC_Special_Terms__c != dqRecordParam.dealQualRecord.CC_Special_Terms__c)) {

                                    if (eachApprovalType.Initial_Term_Discount__c != null  && eachApprovalType.Initial_Term_To_Discount__c != null
                                        && (ccDealQualInitialTerm < eachApprovalType.Initial_Term_Discount__c
                                            || ccDealQualInitialTerm > eachApprovalType.Initial_Term_To_Discount__c)) {
                                                continue;
                                            }

                                setOfApprovalTypeId.add(eachApprovalType.Id);
                                approvalReason = dqRecordParam.dealQualRecord.CC_Special_Terms__c + ' contact center special terms contained by deal qualification';
                                mapOfApprovalTypeIdVsReason.put(eachApprovalType.Id, approvalReason);
                            }
                    }
                    else if(eachApprovalType.Approval_Type__c.equals(FREE_SHIPPING_APPROVAL_TYPE)
                        && dqRecordParam.dealQualRecord != null && dqRecordParam.dealQualRecord.Free_Shipping_Terms_Options__c != null && eachApprovalType.Free_Shipping_Terms_Options__c != null
                        && eachApprovalType.Free_Shipping_Terms_Options__c.split(';').contains(dqRecordParam.dealQualRecord.Free_Shipping_Terms_Options__c)) {
                            if (dqRecordParam.dealQualRecordHistory == null ||
                                (dqRecordParam.dealQualRecordHistory != null && dqRecordParam.dealQualRecordHistory.Free_Shipping_Terms_Options__c != dqRecordParam.dealQualRecord.Free_Shipping_Terms_Options__c)) {
                                setOfApprovalTypeId.add(eachApprovalType.Id);
                                approvalReason = dqRecordParam.dealQualRecord.Free_Shipping_Terms_Options__c + ' free shipping option contained by deal qualification';
                                mapOfApprovalTypeIdVsReason.put(eachApprovalType.Id, approvalReason);
                            }
                    }
                    else if(eachApprovalType.Approval_Type__c.equals(TOTAL_DISCOUNT_APPROVAL_TYPE)
                        && dqRecordParam.overAllDiscount != null && dqRecordParam.overAllDiscount != null && eachApprovalType.Product_Category__c == null
                        && eachApprovalType.Threshold__c <= dqRecordParam.overAllDiscount) {
                            if(dqRecordParam.dealQualRecordHistory == null ||
                            (dqRecordParam.dealQualRecordHistory.Overall_Discount__c != dqRecordParam.dealQualRecord.Overall_Discount__c)) {
                                setOfApprovalTypeId.add(eachApprovalType.Id);
                                approvalReason = 'Total Discount is more than ' + eachApprovalType.Threshold__c;
                                mapOfApprovalTypeIdVsReason.put(eachApprovalType.Id, approvalReason);
                            }
                    }
                    else if((!eachApprovalType.IsCPQApprovalType__c) || (eachApprovalType.IsCPQApprovalType__c && !isDiscountApprovalApplicableCPQ))
                    {
                       if(eachApprovalType.Approval_Type__c.equals(TOTAL_DISCOUNT_APPROVAL_TYPE)
                            && dqRecordParam.overAllDiscountOneTime != null && eachApprovalType.Product_Category__c == OVERALL_DISCOUNT_ONETIME_CATEGORY
                            && eachApprovalType.Threshold__c <= dqRecordParam.overAllDiscountOneTime) {
                                if(dqRecordParam.dealQualRecordHistory == null ||
                                (dqRecordParam.dealQualRecordHistory.Overall_Discount_One_Time__c != dqRecordParam.dealQualRecord.Overall_Discount_One_Time__c)) {
                                    setOfApprovalTypeId.add(eachApprovalType.Id);
                                    approvalReason = 'Overall One-Time Discretion is more than or equal to ' + eachApprovalType.Threshold__c +'%';
                                    mapOfApprovalTypeIdVsReason.put(eachApprovalType.Id, approvalReason);
                                    isFirstLevelApprovalRequire = true;
                                }
                        }
                        else if(eachApprovalType.Approval_Type__c.equals(TOTAL_DISCOUNT_APPROVAL_TYPE)
                            && dqRecordParam.overAllDiscountRecurring != null && eachApprovalType.Product_Category__c == OVERALL_DISCOUNT_RECURRING_CATEGORY
                            && eachApprovalType.Threshold__c <= dqRecordParam.overAllDiscountRecurring) {
                                if(dqRecordParam.dealQualRecordHistory == null ||
                                (dqRecordParam.dealQualRecordHistory.Overall_Discount_Recurring__c != dqRecordParam.dealQualRecord.Overall_Discount_Recurring__c)) {
                                    setOfApprovalTypeId.add(eachApprovalType.Id);
                                    approvalReason = 'Overall Recurring Discretion is more than or equal to ' + eachApprovalType.Threshold__c+'%';
                                    mapOfApprovalTypeIdVsReason.put(eachApprovalType.Id, approvalReason);
                                    isFirstLevelApprovalRequire = true;
                                }
                        }
                        else if(eachApprovalType.Approval_Type__c.equals(TOTAL_DISCOUNT_APPROVAL_TYPE)
                            && dqRecordParam.overAllDiscountContactCenter != null && eachApprovalType.Product_Category__c == OVERALL_DISCOUNT_CONTACTCENTER_CATEGORY
                            && eachApprovalType.Threshold__c <= dqRecordParam.overAllDiscountContactCenter) {
                                if(dqRecordParam.dealQualRecordHistory == null ||
                                (dqRecordParam.dealQualRecordHistory.Overall_Discount_Contact_Center__c != dqRecordParam.dealQualRecord.Overall_Discount_Contact_Center__c)) {
                                    setOfApprovalTypeId.add(eachApprovalType.Id);
                                    approvalReason = 'Overall Contact Center Discretion is more than or equal to ' + eachApprovalType.Threshold__c+'%';
                                    mapOfApprovalTypeIdVsReason.put(eachApprovalType.Id, approvalReason);
                                    isFirstLevelApprovalRequire = true;
                                }
                        }
                    }
                    else if(eachApprovalType.Approval_Type__c.equals(ELA_STANDARD)
                        && dqRecordParam.dealQualRecord != null && dqRecordParam.dealQualRecord.is_ELA__c == ELA_VALUE_FOR_APPROVAL) {

                            Boolean isCurrentDealQualificationStandard = isELAStandardAppliedOnDQ(dqRecordParam.dealQualRecord, eachApprovalType.Threshold__c, String.valueOf(eachApprovalType.Initial_Term_Discount__c));
                            Boolean isHistoryDealQualificationStandard = null;

                            if (dqRecordParam.dealQualRecordHistory != null) {
                                isHistoryDealQualificationStandard = isELAStandardAppliedOnDQHistory(dqRecordParam.dealQualRecordHistory, eachApprovalType.Threshold__c,  String.valueOf(eachApprovalType.Initial_Term_Discount__c));
                            }

                            if(isCurrentDealQualificationStandard != null && isCurrentDealQualificationStandard && (isHistoryDealQualificationStandard == null || isHistoryDealQualificationStandard != isCurrentDealQualificationStandard)) {
                                setOfApprovalTypeId.add(eachApprovalType.Id);
                                approvalReason = 'ELA is ' + ELA_STANDARD;
                                mapOfApprovalTypeIdVsReason.put(eachApprovalType.Id, approvalReason);
                            }
                    }

                    else if(eachApprovalType.Approval_Type__c.equals(ELA_NON_STANDARD) && dqRecordParam.dealQualRecord != null
                            && dqRecordParam.dealQualRecord.is_ELA__c == ELA_VALUE_FOR_APPROVAL) {

                            Boolean isCurrentDealQualificationStandard = isELAStandardAppliedOnDQ(dqRecordParam.dealQualRecord, eachApprovalType.Threshold__c,  String.valueOf(eachApprovalType.Initial_Term_Discount__c));
                            Boolean isHistoryDealQualificationStandard = null;

                            if (dqRecordParam.dealQualRecordHistory != null) {
                                isHistoryDealQualificationStandard = isELAStandardAppliedOnDQHistory(dqRecordParam.dealQualRecordHistory, eachApprovalType.Threshold__c,  String.valueOf(eachApprovalType.Initial_Term_Discount__c));
                            }

                            if(isCurrentDealQualificationStandard != null && !isCurrentDealQualificationStandard && (isHistoryDealQualificationStandard == null || isHistoryDealQualificationStandard != isCurrentDealQualificationStandard)) {
                                setOfApprovalTypeId.add(eachApprovalType.Id);
                                approvalReason = 'ELA is ' + ELA_NON_STANDARD;
                                mapOfApprovalTypeIdVsReason.put(eachApprovalType.Id, approvalReason);
                            }
                    }

                    else if(eachApprovalType.Approval_Type__c.equals(DEAL_TYPE_APPROVAL_TYPE)
                        && dqRecordParam.dealSize != null && eachApprovalType.Threshold__c != null && eachApprovalType.Threshold__c <= dqRecordParam.dealSize) {
                            if(dqRecordParam.dealQualRecordHistory == null ||
                            (dqRecordParam.dealQualRecordHistory.Deal_Size__c != dqRecordParam.dealQualRecord.Deal_Size__c)) {
                                setOfApprovalTypeId.add(eachApprovalType.Id);
                                approvalReason = 'Deal Size is more than ' + eachApprovalType.Threshold__c;
                                mapOfApprovalTypeIdVsReason.put(eachApprovalType.Id, approvalReason);
                            }
                    }
            }

            List<DQ_Approval_Type_Step__c> listOfApprovalTypeStep =
                getDQApprovalTypeStep(setOfApprovalTypeId, dqRecordParam.dqRegion, dqRecordParam.dqSegment,
                                      dqRecordParam.dqDealType, dqRecordParam.dqBrand, dqRecordParam.dqSubRegion);

            if (!listOfApprovalTypeStep.isEmpty()) {
                Set<Id> setOfApprovalStep = new Set<Id>();
                Map<String, DQ_Approval_Type_Step__c> mapOfApprovalTypeStepVsStep = new Map<String, DQ_Approval_Type_Step__c>();
                Map<String, List<DQ_Approval_Type_Step__c>> mapOfApprovalTypeStepVsListStep = new Map<String, List<DQ_Approval_Type_Step__c>>();
                Map<String, String> mapOfApprovalStepVsReason = new Map<String, String>();

                for(DQ_Approval_Type_Step__c eachApprovalTypeStep : listOfApprovalTypeStep) {
                    String stepName = eachApprovalTypeStep.DQ_Approval_Step__r.Name;
                    setOfApprovalStep.add(eachApprovalTypeStep.DQ_Approval_Step__c);
                    mapOfApprovalTypeStepVsStep.put(stepName, eachApprovalTypeStep);

                    // added logic for handling same level name with multiple Id
                    List<DQ_Approval_Type_Step__c> listOfTypeStepRecord = mapOfApprovalTypeStepVsListStep.get(stepName);
                    if ( listOfTypeStepRecord == null) {
                        listOfTypeStepRecord = new List<DQ_Approval_Type_Step__c> ();
                    }
                    listOfTypeStepRecord.add(eachApprovalTypeStep);
                    mapOfApprovalTypeStepVsListStep.put(stepName, listOfTypeStepRecord);

                    String stepReason = mapOfApprovalTypeIdVsReason.get(eachApprovalTypeStep.DQ_Approval_Type__c);
                    System.debug('stepReason>>> ' + stepReason);
                    String conCatReason = '';

                    if(mapOfApprovalStepVsReason.containsKey(stepName)){
                        conCatReason += mapOfApprovalStepVsReason.get(stepName);
                        if (!conCatReason.contains(stepReason)) {
                            conCatReason += ', ' + stepReason;
                        }
                    }
                    else {
                        System.debug('>>>>>>>>>>>>>>>>> ' + stepReason);
                        if (IS_QUANTITY_CHANGED) {
                            if (!stepReason.contains(CHANGE_IN_QUANTITY_MSG)) {
                                conCatReason = CHANGE_IN_QUANTITY_MSG;
                            }
                        }
                       conCatReason += stepReason;
                    }


                    mapOfApprovalStepVsReason.put(stepName, conCatReason);
                }

                Map<Id, DQ_Approval_Step__c> mapOfDQApprovalStep =
                    new Map<Id, DQ_Approval_Step__c>( getListOfDQApprovalStep(setOfApprovalStep));




                for(String eachStepLevel : mapOfApprovalTypeStepVsStep.keySet()) {
                    List<DQ_Approval_Type_Step__c> listOfDQTypeStepRecord = mapOfApprovalTypeStepVsListStep.get(eachStepLevel);

                    if (!listOfDQTypeStepRecord.isEmpty()) {
                        DQ_Approval_Step__c dqApprovalStepRecord = mapOfDQApprovalStep.get(listOfDQTypeStepRecord.get(0).DQ_Approval_Step__c);
                        ApproverWrapper wrapper = new ApproverWrapper(dqApprovalStepRecord);
                        if((dqRecordParam.isCPQDQ == null || (dqRecordParam.isCPQDQ != null && dqRecordParam.isCPQDQ == false)) && (dqApprovalStepRecord.Deal_Size__c != null || dqApprovalStepRecord.Overall_Discount__c != null)) {
                            if ((dqRecordParam.dealSize  != null &&  dqApprovalStepRecord.Deal_Size__c <= dqRecordParam.dealSize) ||
                                (dqRecordParam.overAllDiscount != null  && dqApprovalStepRecord.Overall_Discount__c <= dqRecordParam.overAllDiscount)) {

                                    if(mapOfApprovalTypeIdVsReason.containsKey(listOfDQTypeStepRecord.get(0).DQ_Approval_Type__c)) {
                                        wrapper.approvalReason = mapOfApprovalStepVsReason.get(listOfDQTypeStepRecord.get(0).DQ_Approval_Step__r.Name);
                                    }

                                    wrapper.listOfApprovalStepType = listOfDQTypeStepRecord;
                                    mapOfApproverStepIdVsApproverWrapper.put(listOfDQTypeStepRecord.get(0).Id, wrapper);
                                }
                        } else {
                            if(mapOfApprovalTypeIdVsReason.containsKey(listOfDQTypeStepRecord.get(0).DQ_Approval_Type__c)) {
                                wrapper.approvalReason = mapOfApprovalStepVsReason.get(listOfDQTypeStepRecord.get(0).DQ_Approval_Step__r.Name);
                            }
                            wrapper.listOfApprovalStepType = listOfDQTypeStepRecord;
                            mapOfApproverStepIdVsApproverWrapper.put(listOfDQTypeStepRecord.get(0).Id, wrapper);
                        }
                        List<ApproverStepTypeReasonWrapper> listOfApproverTypeReason = new List<ApproverStepTypeReasonWrapper>();
                        for (DQ_Approval_Type_Step__c eachTypeStep : listOfDQTypeStepRecord) {
              ApproverStepTypeReasonWrapper eachApproverStepReasonRec = new ApproverStepTypeReasonWrapper();

              String approvalReasonForEach = '';
              if (IS_QUANTITY_CHANGED) {
                if (!approvalReasonForEach.contains(CHANGE_IN_QUANTITY_MSG)) {
                  approvalReasonForEach = CHANGE_IN_QUANTITY_MSG;
                }
              }

              approvalReasonForEach = approvalReasonForEach + mapOfApprovalTypeIdVsReason.get(eachTypeStep.DQ_Approval_Type__c);
                             eachApproverStepReasonRec.dqApprovalTypeStep = eachTypeStep;

                            eachApproverStepReasonRec.approvalReason = approvalReasonForEach;
                            listOfApproverTypeReason.add(eachApproverStepReasonRec);
                        }
                        wrapper.listOfApprovalStepTypeWithReason = listOfApproverTypeReason;
                    }
                }

                List<DQ_Approval_Step_Approver__c> listOfApprovalStepApprover =
                    getListOfDQApprovalStepApprover(setOfApprovalStep, dqRecordParam.dqRegion, dqRecordParam.dqSegment,
                                                    dqRecordParam.dqDealType, dqRecordParam.dqBrand, dqRecordParam.dqSubRegion);

                System.debug('listOfApprovalStepApprover>> ' + listOfApprovalStepApprover);
                Map<Id, List<DQ_Approval_Step_Approver__c>> mapOfStepIdVsStepApprover = new Map<Id, List<DQ_Approval_Step_Approver__c>> ();

                for (DQ_Approval_Step_Approver__c eachStepApprover : listOfApprovalStepApprover) {
                     List<DQ_Approval_Step_Approver__c> listOfStepApprovers = mapOfStepIdVsStepApprover.get(eachStepApprover.DQ_Approval_Step__c);

                    if (listOfStepApprovers == null) {
                        listOfStepApprovers = new List<DQ_Approval_Step_Approver__c>();
                    }

                    // add condition

                    if (eachStepApprover.Overall_Discount__c != null || eachStepApprover.Deal_Size__c != null) {
                        if ((eachStepApprover.Overall_Discount__c != null && dqRecordParam.dealQualRecord.Overall_Discount__c >= eachStepApprover.Overall_Discount__c)
                            || (eachStepApprover.Deal_Size__c != null && dqRecordParam.dealQualRecord.Deal_Size__c >= eachStepApprover.Deal_Size__c)) {
                            listOfStepApprovers.add(eachStepApprover);
                         }
                    }
                    else {
                        listOfStepApprovers.add(eachStepApprover);
                    }



                    mapOfStepIdVsStepApprover.put(eachStepApprover.DQ_Approval_Step__c, listOfStepApprovers);
                }

                System.debug('mapOfApproverStepIdVsApproverWrapper>>> ' + mapOfApproverStepIdVsApproverWrapper);
                System.debug('mapOfStepIdVsStepApprover>>> ' + mapOfStepIdVsStepApprover);

                for (Id eachApprovalStepTypeRecordId : mapOfApproverStepIdVsApproverWrapper.keySet()) {
                    ApproverWrapper wrapper = mapOfApproverStepIdVsApproverWrapper.get(eachApprovalStepTypeRecordId);

                    if (wrapper == null) {
                        wrapper = getApproverWrapperByMatchingStepId(eachApprovalStepTypeRecordId, mapOfApproverStepIdVsApproverWrapper);
                    }
                    System.debug('wrapper >> ' + wrapper);
                    List<DQ_Approval_Step_Approver__c> listOfStepApprovers = wrapper.listOfStepApprover;
                    if (listOfStepApprovers == null) {
                        listOfStepApprovers = new List<DQ_Approval_Step_Approver__c>();
                    }

                    if (wrapper.listOfApprovalStepType != null && !wrapper.listOfApprovalStepType.isEmpty()) {
                        List<Id> listOfStepApproverIds = new List<Id>();
                        for (DQ_Approval_Type_Step__c eachTypeStep : wrapper.listOfApprovalStepType) {
                            if (!listOfStepApproverIds.contains(eachTypeStep.DQ_Approval_Step__c) && mapOfStepIdVsStepApprover.get(eachTypeStep.DQ_Approval_Step__c) != null) {
                                listOfStepApproverIds.add(eachTypeStep.DQ_Approval_Step__c);
                                listOfStepApprovers.addAll(mapOfStepIdVsStepApprover.get(eachTypeStep.DQ_Approval_Step__c));
                            }
                        }
                    }

                    wrapper.listOfStepApprover = listOfStepApprovers;
                    mapOfApproverStepIdVsApproverWrapper.put(eachApprovalStepTypeRecordId, wrapper);
                }
            }
        }

        mapOfApproverStepIdVsApproverWrapper = CheckForDefaultLevelRequire(mapOfApproverStepIdVsApproverWrapper);
        return isFirstLevelApprovalRequire ? createCurrentOppOwnerApprovalForLevelOne( dqRecordParam.opportunityId, mapOfApproverStepIdVsApproverWrapper.values()) : mapOfApproverStepIdVsApproverWrapper.values();
    }


    private static Map<Id, ApproverWrapper> CheckForDefaultLevelRequire( Map<Id, ApproverWrapper> mapOfApprovers) {
        Set<Id> setOfStepIds = new Set<Id>();
        for (ApproverWrapper eachApprover : mapOfApprovers.values()) {
            if (eachApprover.listOfStepApprover.isEmpty()) {
                setOfStepIds.add(eachApprover.approvalStepRecord.Id);
            }

            Boolean isDefaultApproverRequire = true;
            for (DQ_Approval_Step_Approver__c eachApproverRecord : eachApprover.listOfStepApprover) {
                if (eachApproverRecord != null && eachApproverRecord.Approval_Type__c != 'Notification') {
                    isDefaultApproverRequire = false;
                    break;
                }
            }

            if (isDefaultApproverRequire) {
                setOfStepIds.add(eachApprover.approvalStepRecord.Id);
            }

        }


        List<DQ_Approval_Step_Approver__c> listOfDefaultStepApprovers = getDefaultApproversByStepId(setOfStepIds);
        Map<Id, DQ_Approval_Step_Approver__c> mapOfStepIdVsApprovers = new Map<Id, DQ_Approval_Step_Approver__c> ();

        for (DQ_Approval_Step_Approver__c eachApproverRecord : listOfDefaultStepApprovers) {
            mapOfStepIdVsApprovers.put(eachApproverRecord.DQ_Approval_Step__c, eachApproverRecord);
        }

        for (ApproverWrapper eachApprover : mapOfApprovers.values()) {
            if (eachApprover.listOfStepApprover.isEmpty()) {
                eachApprover.listOfStepApprover.add(mapOfStepIdVsApprovers.get(eachApprover.approvalStepRecord.Id));
            }

            Boolean isDefaultApproverRequire = true;
            for (DQ_Approval_Step_Approver__c eachApproverRecord : eachApprover.listOfStepApprover) {

                if (eachApproverRecord != null && eachApproverRecord.Approval_Type__c != 'Notification') {
                    isDefaultApproverRequire = false;
                    break;
                 }
            }

            if (isDefaultApproverRequire) {
                System.debug('isDefaultApproverRequire>> ' + isDefaultApproverRequire);
                System.debug('mapOfStepIdVsApprovers>> ' + mapOfStepIdVsApprovers);
                if (mapOfStepIdVsApprovers.get(eachApprover.approvalStepRecord.Id) != null) {
                    eachApprover.listOfStepApprover.add(mapOfStepIdVsApprovers.get(eachApprover.approvalStepRecord.Id));
                }

            }
        }
        return mapOfApprovers;
    }



    private static List<DQ_Approval_Step_Approver__c> getDefaultApproversByStepId (Set<Id> setOfStepIds) {
        return [SELECT Id, Name, DQ_Approval_Step__c, OwnerId, Owner.Name, Approval_Type__c, Sub_Region__c
                 FROM DQ_Approval_Step_Approver__c
                 WHERE DQ_Approval_Step__c =:setOfStepIds AND Default__c = true];
    }

    private static ApproverWrapper getApproverWrapperByMatchingStepId (Id approvalStepTypeId, Map<Id, ApproverWrapper> mapOfApproverWrapper) {
        for (ApproverWrapper eachWrapperRecord : mapOfApproverWrapper.values()) {
            Set<Id> setOfApprovalStepsTypeIds = (new Map<Id, DQ_Approval_Type_Step__c> (eachWrapperRecord.listOfApprovalStepType)).keySet();
            if (setOfApprovalStepsTypeIds.contains(approvalStepTypeId)) {
                return eachWrapperRecord;
            }
        }
        return null;
    }

    public static Decimal calculateQuanityChangePercent(Decimal currentQuantityValue, Decimal lastQuantityValue) {
        Decimal increaseQuanity = currentQuantityValue - lastQuantityValue;
        return lastQuantityValue == 0 ? 0 : ((increaseQuanity/lastQuantityValue) * 100);
    }

    public static List<ApproverWrapper> getApproversForQuoteDQ(DQWrapperDetail dqRecordParam) {
        return fetchApproverListByWrapper(dqRecordParam);
    }

    private static Map<Id, DQ_Deal_Qualification_Approver__c> getMapOfApproverStepApproverVsDealQualApprover(
        List<DQ_Deal_Qualification_Approver__c> listOfDealQualApprover) {
            Map<Id, DQ_Deal_Qualification_Approver__c> mapOfApproverStepApproverVsDealQualApprover = new Map<Id, DQ_Deal_Qualification_Approver__c>();
            Decimal latestSubmittedOrder = listOfDealQualApprover.get(0).Submitted_Order__c;
            for (DQ_Deal_Qualification_Approver__c eachRecord : listOfDealQualApprover) {
                if (eachRecord.Submitted_Order__c == latestSubmittedOrder) {
                    mapOfApproverStepApproverVsDealQualApprover.put(eachRecord.Approval_Step_Approver__c, eachRecord);
                }
            }
            return mapOfApproverStepApproverVsDealQualApprover;
        }

    private static List<DQ_Approval_Type__c> getActiveDQApprovalType() {
        return [SELECT Id, Name, Approval_Type__c,Free_Shipping_Terms_Options__c,CC_Special_Terms__c,IsCPQApprovalType__c, IsActive__c, Threshold__c, Product_Category__c,
                Special_Terms__c, Initial_Term_Discount__c, Initial_Term_To_Discount__c
                FROM DQ_Approval_Type__c
                WHERE IsActive__c = true and isCPQApprovalType__c = false and isUnifiedQuotingApprovalType__c = false];
    }
    private static List<DQ_Approval_Type__c> getActiveCPQDQApprovalType() {
        return [SELECT Id, Name, IsCPQApprovalType__c,Free_Shipping_Terms_Options__c,CC_Special_Terms__c,Approval_Type__c, IsActive__c, Threshold__c, Product_Category__c,
                Special_Terms__c, Initial_Term_Discount__c, Initial_Term_To_Discount__c
                FROM DQ_Approval_Type__c
                WHERE IsActive__c = true and IsCPQApprovalType__c = true order by Approval_Type__c];
    }
    private static List<DQ_Approval_Type_Step__c> getDQApprovalTypeStep(
        Set<Id> setOfApprovalTypeId, String dqRegion, String dqSegment, String dqDealType, String dqBrand, String subRegion)
    {
        if (!String.isBlank(subRegion)) {
            return [SELECT Id, Name, DQ_Approval_Step__c, DQ_Approval_Step__r.Name, DQ_Approval_Type__c,
            DQ_Approval_Type__r.Approval_Type__c, DQ_Approval_Step__r.Step_Order__c,
            Discount_Threshold__c, Quantity_Threshold__c, DQ_Approval_Type__r.Product_Category__c
            FROM DQ_Approval_Type_Step__c
            WHERE DQ_Approval_Type__c =: setOfApprovalTypeId AND Region__c INCLUDES(:dqRegion) AND
            Segment__c INCLUDES(:dqSegment) AND Deal_Type__c INCLUDES(:dqDealType) AND Brand__c INCLUDES(:dqBrand) AND Sub_Region__c INCLUDES (:subRegion)
            ORDER BY DQ_Approval_Step__r.Step_Order__c DESC];
        }

        return [SELECT Id, Name, DQ_Approval_Step__c, DQ_Approval_Step__r.Name, DQ_Approval_Type__c,
                DQ_Approval_Type__r.Approval_Type__c, DQ_Approval_Step__r.Step_Order__c,
                Discount_Threshold__c, Quantity_Threshold__c, DQ_Approval_Type__r.Product_Category__c
                FROM DQ_Approval_Type_Step__c
                WHERE DQ_Approval_Type__c =: setOfApprovalTypeId AND Region__c INCLUDES(:dqRegion) AND
                Segment__c INCLUDES(:dqSegment) AND Deal_Type__c INCLUDES(:dqDealType) AND Brand__c INCLUDES(:dqBrand)
                ORDER BY DQ_Approval_Step__r.Step_Order__c DESC];
    }

    private static List<DQ_Approval_Step__c> getListOfDQApprovalStep(Set<Id> setOfApprovalStepId) {
        return [SELECT Id, Name, Step_Order__c, Overall_Discount__c, Deal_Size__c
                FROM DQ_Approval_Step__c
                WHERE Id IN :setOfApprovalStepId
                ORDER BY Step_Order__c DESC];
    }

    private static List<DQ_Approval_Step_Approver__c> getListOfDQApprovalStepApprover(
        Set<Id> setOfApprovalStepId, String dqRegion, String dqSegment, String dqDealType, String dqBrand, String subRegion)
    {
        System.debug('setOfApprovalStepId >> ' +  setOfApprovalStepId);
        System.debug('dqRegion >> ' +  dqRegion);
        System.debug('dqSegment >> ' +  dqSegment);
        System.debug('dqDealType >> ' +  dqDealType);
        System.debug('dqBrand >> ' +  dqBrand);
        System.debug('subRegion >> ' +  subRegion);

        if (!String.isBlank(subRegion)) {
            return  [SELECT Id, Name, DQ_Approval_Step__c, OwnerId, Owner.Name, Approval_Type__c, Sub_Region__c, Overall_Discount__c,
                Deal_Size__c
                 FROM DQ_Approval_Step_Approver__c
                 WHERE DQ_Approval_Step__c =:setOfApprovalStepId AND Region__c INCLUDES(:dqRegion)
                 AND Segment__c INCLUDES(:dqSegment) AND Deal_Type__c INCLUDES(:dqDealType) AND Brand__c INCLUDES(:dqBrand) AND Sub_Region__c INCLUDES(:subRegion)];
        }

        return  [SELECT Id, Name, DQ_Approval_Step__c, OwnerId, Owner.Name, Approval_Type__c, Sub_Region__c,
                Overall_Discount__c, Deal_Size__c
            FROM DQ_Approval_Step_Approver__c
            WHERE DQ_Approval_Step__c =:setOfApprovalStepId AND Region__c INCLUDES(:dqRegion)
            AND Segment__c INCLUDES(:dqSegment) AND Deal_Type__c INCLUDES(:dqDealType) AND Brand__c INCLUDES(:dqBrand) ];

    }

    private static List<DQ_Deal_Qualification__c> getDealQualificationByIds(Set<Id> setOfIds) {
        return [SELECT Id, Name, IsDQCreatedFromCPQOpp__c,Free_Shipping_Terms_Options__c,Max_Discount__c,Overall_Discount_Contact_Center__c,Overall_Discount_One_Time__c,CC_Special_Terms__c,CC_Initial_Term__c,Overall_Discount_Recurring__c,Locked__c, Number_of_DLs__c, Minimum_Package_s__c,
                Status__c, Opportunity__c, Type__c, Renewal_Term__c, Initial_Term__c, Special_Terms__c,
                Region__c, Segment__c, Deal_Type__c, Brand__c, Deal_Size__c, Overall_Discount__c, Is_ELA__c, Sub_Region__c,
                Charge_Term__c, ELA_Initial_Terms__c, Maximum_Potential__c, Minimum_Baseline__c, Start_Date__c,
                (SELECT Product_Category__c, Discount__c, Quantity__c, Product__c, Product_Package__c FROM Deal_Qualification_Discounts__r)
                FROM DQ_Deal_Qualification__c WHERE Id =: setOfIds];
    }

    public static List<DQ_Deal_Qualification_History__c> getApprovedDealQualificationHistoryByIds(
        Set<Id> setOfDealQualificationIds, String status) {
            return [SELECT Id, Status__c,Free_Shipping_Terms_Options__c,Overall_Discount_Contact_Center__c,Overall_Discount_One_Time__c,CC_Special_Terms__c,CC_Initial_Term__c,Overall_Discount_Recurring__c,Brand__c, Charge_Term__c, Deal_Size__c, Deal_Type__c,
                    Initial_Term__c, Minimum_Package_s__c, Number_of_DLs__c, Overall_Discount__c, Sub_Region__c,
                    Renewal_Term__c, Region__c, Segment__c, Deal_Qualification__c, Special_Terms__c, Is_ELA__c,
                    Maximum_Potential__c, True_Up_Terms__c, Minimum_Baseline__c, ELA_Initial_Terms__c,
                    (SELECT Id, Discount__c, Product__c, Discount_Type__c, Product_Family__c,
                     Product_Category__c, Product_Sub_Categories__c,
                     Quantity__c , Product_Package__c
                     FROM DQ_Deal_Qualification_Discounts_History__r)
                    FROM DQ_Deal_Qualification_History__c
                    WHERE Status__c = :status AND Deal_Qualification__c IN :setOfDealQualificationIds];
        }

    private static List<DQ_Deal_Qualification_Approver__c> getDQQualificationApproverByDQId(Set<Id> setOfDealQualificationIds) {
        return [SELECT Id, Name, Deal_Qualification__c, Approval_Step__c, Approval_Step_Approver__c, Approval_Reason__c,
                Step_Order__c, Approved_By__c, Approve_Reject_Date__c, Status__c, Comments__c, Submitted_Date__c, Submitted_Order__c
                FROM DQ_Deal_Qualification_Approver__c
                WHERE Deal_Qualification__c = :setOfDealQualificationIds Order By Submitted_Order__c DESC];
    }

    private static List<ApproverWrapper> createCurrentOppOwnerApprovalForLevelOne(String opportunityId, List<ApproverWrapper> listOfApproverWrapper) {
        for (ApproverWrapper eachRecord : listOfApproverWrapper) {
            if (eachRecord.approvalStepRecord.Name == 'Level 1') {
                Opportunity oppRecord = [SELECT Id, OwnerId, Owner.ManagerId, Owner.Manager.Name, Brand_Name__c, Segment_Name__c, RecordType.Name, CurrencyIsoCode
                                         FROM Opportunity
                                         WHERE Id =: opportunityId];

                if (oppRecord != null) {
                    if (oppRecord.Owner.ManagerId != null) {

                        DQ_Approval_Step_Approver__c approverRecord = new DQ_Approval_Step_Approver__c();
                        approverRecord.Brand__c = oppRecord.Brand_Name__c;
                        approverRecord.Segment__c = oppRecord.Segment_Name__c == null ? DQ_SubmitQuoteForApproval1.DQ_SEGMENT : oppRecord.Segment_Name__c;
                        approverRecord.DQ_Approval_Step__c = eachRecord.approvalStepRecord.Id;
                        approverRecord.Deal_Type__c = DQ_SubmitQuoteForApproval1.getDealType(oppRecord.RecordType.Name);
                        approverRecord.Approval_Type__c  = 'Approval';
                        approverRecord.Region__c = DQ_SubmitQuoteForApproval1.getRegionValueByOppCurrencyISO(oppRecord.CurrencyIsoCode);
                        approverRecord.OwnerId = oppRecord.Owner.ManagerId;
                        eachRecord.managerDetail = getManagerDetail(oppRecord);
                        if (eachRecord.listOfStepApprover == null) {
                            eachRecord.listOfStepApprover = new List<DQ_Approval_Step_Approver__c>();
                        }
                        eachRecord.listOfStepApprover.add(approverRecord);
                        break;
                    }
                }
            }
        }
        return listOfApproverWrapper;
    }


    private static Map<String, String> getProductCategoryAPIPickListMap() {
        Map<String, String> mapOfValueVsLabel = new Map<String, String>();
        List<Schema.PicklistEntry> picklistEntries = Schema.SObjectType.DQ_Approval_Type__c.fields.Product_Category__c.getPicklistValues();

        for(Schema.PicklistEntry ple :picklistEntries){
            mapOfValueVsLabel.put(ple.getValue(), ple.getLabel());
        }

        return mapOfValueVsLabel;
    }

    private static User getManagerDetail(Opportunity oppRecord) {
        User managerDetail = new User();
        managerDetail.Id = oppRecord.Owner.ManagerId;
        managerDetail.FirstName = oppRecord.Owner.Manager.Name;
        return managerDetail;
    }

    public static DQWrapperDetail assignDefaultRegionSubregion(DQWrapperDetail dqWrapper)  {
        List<String> regionSubregionStrList = system.label.DQRegionSubRegion.split(';');
        dqWrapper.dqRegion = regionSubregionStrList[0];
        dqWrapper.dqSubRegion = regionSubregionStrList[1];
        return dqWrapper;
    }

    public class ApproverStepTypeReasonWrapper {
        @AuraEnabled
        public String approvalReason {get;set;}
        @AuraEnabled
        public DQ_Approval_Type_Step__c dqApprovalTypeStep {get;set;}
    }

    public class ApproverWrapper
    {
        @AuraEnabled
        public DQ_Approval_Step__c approvalStepRecord{get; set;}
        @AuraEnabled
        public List<DQ_Approval_Step_Approver__c> listOfStepApprover{get; set;}
        @AuraEnabled
        public String approvalReason{get; set;}
        @AuraEnabled
        public User managerDetail {get;set;}
        @AuraEnabled
        public List<DQ_Approval_Type_Step__c> listOfApprovalStepType {get; set;}

        @AuraEnabled
        public List<ApproverStepTypeReasonWrapper> listOfApprovalStepTypeWithReason {get; set;}

        public ApproverWrapper() {}

        public ApproverWrapper(DQ_Approval_Step__c approvalStepRecord) {
            this.approvalStepRecord = approvalStepRecord;
            this.listOfStepApprover = new List<DQ_Approval_Step_Approver__c>();
        }

        public ApproverWrapper(DQ_Approval_Step__c approvalStepRecord, List<DQ_Approval_Step_Approver__c> listOfStepApprover) {
            this.approvalStepRecord = approvalStepRecord;
            this.listOfStepApprover = listOfStepApprover;
        }
    }


    public class DQWrapperDetail {
        public Id opportunityId {get;set;}
        public Decimal dqInitialTerm {get;set;}
        public Decimal dqRenewalTerm {get;set;}
        public Decimal dqMaxInitialHistory {get;set;}
        public Decimal dqMaxRenewalHistory {get;set;}
        public String dqRegion {get;set;}
        public String dqSegment {get;set;}
        public String dqDealType {get;set;}
        public String dqBrand {get;set;}
        public String dqSubRegion {get;set;}
        public Decimal overAllDiscount {get;set;}
        public Decimal overAllDiscountOneTime {get;set;}
        public Decimal overAllDiscountRecurring {get;set;}
        public Decimal overAllDiscountContactCenter {get;set;}
        public Boolean isCPQDQ {get;set;}
        public Boolean isCurrentELAStandard {get; set;}
        public Boolean isHistoryELAStandard {get; set;}
        public Decimal dealSize {get;set;}
        public Map<String, Map<String, Map<String, Object>>> mapOfCurrentProductCategoryIdVsMapOfData {get; set;}
        public Map<String, Map<String, Map<String, Object>>> mapOfHistoryProductCategoryIdVsMapOfData {get; set;}
        public String dealQualificationId {get;set;}
    public DQ_Deal_Qualification__c dealQualRecord {get;set;}
        public DQ_Deal_Qualification_History__c dealQualRecordHistory {get;set;}
        public String historyDQElaValue {get;set;}
    }
}