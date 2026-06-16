public with sharing class QuoteTotals {

    @TestVisible
    private Map<Id, Quote> quoteIdToQuoteMap;

    public static Set<String> monthlyOrMonthlyContractSet = new Set<String>{
        Product2Helper.CHARGE_TERM_MONTHLY,
        Product2Helper.CHARGE_TERM_MONTHLY_CONTRACT
    };

    public static List<Quote> populateTotals(Map<Id, List<QuoteLineItem>> quoteIdToQliListMap) {

        if(quoteIdToQliListMap == null || quoteIdToQliListMap.isEmpty()) {
            return new List<Quote>();
        }

        QuoteTotals quoteTotals = new QuoteTotals();

        List<Quote> updatedQuotes = quoteTotals.populateQuoteTotals(quoteIdToQliListMap);

        return updatedQuotes;
    }

    public List<Quote> populateQuoteTotals(Map<Id, List<QuoteLineItem>> quoteIdToQliListMap) {

        /*
        * Required fields for QuoteLineItem:
        *   Id, DiscountValueNew__c, Quantity, NewQuantity__c, Product2.Family, EffectivePriceNew__c,
        *   Fixed_Taxes_Amount__c, Variable_Taxes_Amount__c, Product2.Sub_Category__c, Delta_MRR__c, Delta_ARR__c,
        *   Total_Annual__c, Total_Monthly__c, Total_One_Time__c, Product2.Charge_Term__c, PackageInfo__c,
        *   Entitlement__c, Entitlement__r.DisplayQuantity__c, Entitlement__r.EffectivePrice__c,
        *   Entitlement__r.Product__r.Charge_Term__c, Entitlement__r.Price__c,
        *   QuoteId, Quote.Total_One_Time__c, Quote.Total_MRR_New__c, Quote.Total_ARR__c,
        *   Quote.Total_Initial_Payment__c, Quote.Total_First_Year_Cost__c, Quote.Total_One_Time_Discount__c,
        *   Quote.Total_MRR_Discount__c, Quote.Total_ARR_Discount__c, Quote.Total_Initial_Payment_Discount__c,
        *   Quote.Total_First_Year_Discount__c, Quote.Total_One_Time_with_Taxes__c, Quote.Total_MRR_with_Taxes__c,
        *   Quote.Total_ARR_with_Taxes__c, Quote.Total_Initial_Payment_with_Taxes__c, Quote.Total_First_Year_Cost_with_Taxes__c,
        *   Quote.Contact_Center_Total_One_Time__c, Quote.Contact_Center_Total_MRR__c, Quote.Contact_Center_Total_ARR__c,
        *   Quote.Contact_Center_Total_Initial_Payment__c, Quote.Contact_Center_Total_First_Year_Cost__c,
        *   Quote.Contact_Center_Total_One_Time_Discount__c, Quote.Contact_Center_Total_MRR_Discount__c,
        *   Quote.Contact_Center_Total_ARR_Discount__c, Quote.ContactCenterTotalInitialPaymentDiscount__c,
        *   Quote.Contact_Center_Total_First_Year_Discount__c, Quote.Estimated_Hardware__c,
        *   Quote.Delta_MRR__c, Quote.Delta_ARR__c, Quote.Delta_CC_MRR__c, Quote.Delta_CC_ARR__c
        *   Quote.Entitlement_Total_ARR__c, Quote.Entitlement_Total_MRR__c, Quote.Upsell_Status__c,
        *   Quote.Contact_Center_Entitlement_Total_ARR__c, Quote.Contact_Center_Entitlement_Total_MRR__c,
        *   QuoteRecordType__c, ServiceName__c, Zero_Quantity__c
        */

        if (quoteIdToQliListMap == null || quoteIdToQliListMap.isEmpty()) {
            return new List<Quote>();
        }

        Set<Id> quoteIds = quoteIdToQliListMap.keySet();
        this.quoteIdToQuoteMap = new Map<Id, Quote>(
            (List<Quote>) new QuoteSelector()
                .selectQuotesByIds(new List<Object> { quoteIds })
                .executeQuery()
        );

        List<Quote> processedQuotes = new List<Quote>();

        for (Id quoteId : quoteIds) {
            List<QuoteLineItem> qliForCurrentQuote = quoteIdToQliListMap.get(quoteId);
            List<QuoteLineItem> filteredQlis = filterOutUsages(qliForCurrentQuote);
            Quote processedQuote = populateTotalsForQuote(quoteId, filteredQlis);

            if (processedQuote != null) {
                processedQuotes.add(processedQuote);
            }
        }

        return processedQuotes;
    }

    private Quote populateTotalsForQuote(Id quoteId, List<QuoteLineItem> qliForCurrentQuote) {

        if(quoteId == null) {
            return null;
        }

        // Total_One_Time__c
        Decimal totalOneTimeValue = computeTotalOneTime(qliForCurrentQuote);

        // Estimated_Hardware__c
        Decimal estimatedHardwareValue = computeEstimatedHardware(qliForCurrentQuote);

        // Total_MRR_New__c
        Decimal totalMRR = computeTotalMRR(qliForCurrentQuote);

        // Total_ARR__c
        Decimal totalARR = computeTotalARR(qliForCurrentQuote);

        // Total_Initial_Payment__c
        Decimal totalInitialPayment = computeTotalInitialPayment(qliForCurrentQuote, false);

        // CLM_Total_Initial_Payment__c
        Decimal clmTotalInitialPayment = computeCLMTotalInitialPayment(qliForCurrentQuote, false);

        // TotalInitialPaymentWithoutProServ__c
        Decimal totalInitialPaymentWithoutProServ = computeTotalInitialPayment(qliForCurrentQuote, true);

        // Total_First_Year_Cost__c
        Decimal totalFirstYearCost = totalOneTimeValue + totalARR;

        // Total_One_Time_Discount__c
        Decimal totalOneTimeDiscount = computeTotalOneTimeDiscount(qliForCurrentQuote);

        // Total_MRR_Discount__c
        Decimal totalMRRDiscount = computeTotalMRRDiscount(qliForCurrentQuote);

        // Total_ARR_Discount__c
        Decimal totalARRDiscount = computeTotalARRDiscount(qliForCurrentQuote);

        // Total_Initial_Payment_Discount__c
        Decimal totalInitialPaymentDiscount = computeTotalInitialPaymentDiscount(qliForCurrentQuote, totalOneTimeDiscount);

        // Total_First_Year_Discount__c
        Decimal totalFirstYearDiscount = totalOneTimeDiscount + totalARRDiscount;


        // Total_One_Time_with_Taxes__c
        Decimal totalOneTimeWithTaxes = computeTotalOneTimeWithTaxes(qliForCurrentQuote, computeTotalOneTime(qliForCurrentQuote, true));

        // Total_MRR_with_Taxes__c, Total_ARR_with_Taxes__c
        Decimal totalMRRWithTaxes = computeTotalMRRWithTaxes(qliForCurrentQuote, computeTotalMRR(qliForCurrentQuote, true));
        Decimal totalARRWithTaxes = computeTotalARRWithTaxes(qliForCurrentQuote, computeTotalARR(qliForCurrentQuote, true));

        // Total_Initial_Payment_with_Taxes__c
        Decimal totalInitialPaymentWithTaxes = computeTotalInitialPaymentWithTaxes(qliForCurrentQuote, computeTotalInitialPayment(qliForCurrentQuote, true, false));

        // Total_First_Year_Cost_with_Taxes__c
        Decimal totalFirstYearCostWithTaxes = totalOneTimeWithTaxes + totalARRWithTaxes;

        // TotalQuoteSummary__c
        Decimal totalQuoteSummary = computeTotalQuoteSummary(qliForCurrentQuote);

        // Contact_Center_Total_One_Time__c
        Decimal contactCenterTotalOneTime = computeContactCenterTotalOneTime(qliForCurrentQuote);

        // Contact_Center_Total_MRR__c, Contact_Center_Total_ARR__c
        Decimal contactCenterTotalMRR = computeContactCenterTotalMRR(qliForCurrentQuote);
        Decimal contactCenterTotalARR = computeContactCenterTotalARR(qliForCurrentQuote);

        // Contact_Center_Total_Initial_Payment__c
        Decimal contactCenterTotalInitialPayment = computeContactCenterTotalInitialPayment(qliForCurrentQuote);

        // Contact_Center_Total_First_Year_Cost__c
        Decimal contactCenterTotalFirstYearCost = contactCenterTotalOneTime + contactCenterTotalARR;


        // Contact_Center_Total_One_Time_Discount__c
        Decimal contactCenterTotalOneTimeDiscount = computeContactCenterTotalOneTimeDiscount(qliForCurrentQuote);

        // Contact_Center_Total_MRR_Discount__c
        Decimal contactCenterTotalMRRDiscount = computeContactCenterTotalMRRDiscount(qliForCurrentQuote);

        // Contact_Center_Total_ARR_Discount__c
        Decimal contactCenterTotalARRDiscount = computeContactCenterTotalARRDiscount(qliForCurrentQuote);

        // ContactCenterTotalInitialPaymentDiscount__c
        Decimal contactCenterTotalInitialPaymentDiscount = computeContactCenterTotalInitialPaymentDiscount(qliForCurrentQuote, contactCenterTotalOneTimeDiscount);

        // Contact_Center_Total_First_Year_Discount__c
        Decimal contactCenterTotalFirstYearDiscount = contactCenterTotalOneTimeDiscount + contactCenterTotalARRDiscount;

        // Delta_MRR__c
        Decimal deltaMrr = computeDeltaMrr(qliForCurrentQuote);

        // Delta_ARR__c
        Decimal deltaArr = computeDeltaArr(qliForCurrentQuote);

        // Delta_CC_MRR__c
        Decimal deltaCCMrr = computeDeltaCCMrr(qliForCurrentQuote);

        // Delta_CC_ARR__c
        Decimal deltaCCArr = computeDeltaCCArr(qliForCurrentQuote, quoteId);

        // ProServListPrice__c
        Decimal proServListPrice = computeProServListPrice(qliForCurrentQuote, quoteId);

        // ProServDiscount__c
        Decimal proServDiscount = computeProServDiscount(qliForCurrentQuote, quoteId);

        // if totals changed - return updated quote, otherwise - return null(if quote totals not changed - we do not need update it)

        Quote qt = new Quote(Id = quoteId);
        Set<String> changedFields = new Set<String>();

        Map<String, Decimal> fieldsMap = new Map<String, Decimal> {
            'Total_One_Time__c' => totalOneTimeValue,
            'Total_MRR_New__c' => totalMRR,
            'Total_ARR__c' => totalARR,
            'Total_Initial_Payment__c' => totalInitialPayment,
            'Total_First_Year_Cost__c' => totalFirstYearCost,
            'Total_One_Time_Discount__c' => totalOneTimeDiscount,
            'Total_MRR_Discount__c' => totalMRRDiscount,
            'Total_ARR_Discount__c' => totalARRDiscount,
            'Total_Initial_Payment_Discount__c' => totalInitialPaymentDiscount,
            'Total_First_Year_Discount__c' => totalFirstYearDiscount,
            'Total_One_Time_with_Taxes__c' => totalOneTimeWithTaxes,
            'Total_MRR_with_Taxes__c' => totalMRRWithTaxes,
            'Total_ARR_with_Taxes__c' => totalARRWithTaxes,
            'Total_Initial_Payment_with_Taxes__c' => totalInitialPaymentWithTaxes,
            'Total_First_Year_Cost_with_Taxes__c' => totalFirstYearCostWithTaxes,
            'TotalQuoteSummary__c' => totalQuoteSummary,
            'Contact_Center_Total_One_Time__c' => contactCenterTotalOneTime,
            'Contact_Center_Total_MRR__c' => contactCenterTotalMRR,
            'Contact_Center_Total_ARR__c' => contactCenterTotalARR,
            'Contact_Center_Total_Initial_Payment__c' => contactCenterTotalInitialPayment,
            'Contact_Center_Total_First_Year_Cost__c' => contactCenterTotalFirstYearCost,
            'Contact_Center_Total_One_Time_Discount__c' => contactCenterTotalOneTimeDiscount,
            'Contact_Center_Total_MRR_Discount__c' => contactCenterTotalMRRDiscount,
            'Contact_Center_Total_ARR_Discount__c' => contactCenterTotalARRDiscount,
            'ContactCenterTotalInitialPaymentDiscount__c' => contactCenterTotalInitialPaymentDiscount,
            'Contact_Center_Total_First_Year_Discount__c' => contactCenterTotalFirstYearDiscount,
            'Estimated_Hardware__c' => estimatedHardwareValue,
            'Delta_MRR__c' => deltaMrr,
            'Delta_ARR__c' => deltaArr,
            'Delta_CC_MRR__c' => deltaCCMrr,
            'CLM_Total_Initial_Payment__c' => clmTotalInitialPayment,
            'Delta_CC_ARR__c' => deltaCCArr,
            'TotalInitialPaymentWithoutProServ__c' => totalInitialPaymentWithoutProServ,
            'ProServListPrice__c' => proServListPrice,
            'ProServDiscount__c' => proServDiscount
        };


        if(qliForCurrentQuote.isEmpty()) {
            changedFields.addAll(fieldsMap.keySet());
        } else {
            Quote oldQuote = qliForCurrentQuote.get(0).Quote;

            for (String fieldName : fieldsMap.keySet()) {
                Decimal fieldValue = fieldsMap.get(fieldName);
                if (fieldValue != oldQuote.get(fieldName)) {
                    changedFields.add(fieldName);
                }
            }
        }

        if(changedFields.isEmpty()) {
            return null;
        }

        for (String fieldName : changedFields) {
            qt.put(fieldName, fieldsMap.get(fieldName));
        }

        return qt;
    }

    @TestVisible
    private Decimal computeTotalOneTime(List<QuoteLineItem> qliList) {
        return computeTotalOneTime(qliList, false);
    }

    @TestVisible
    private Decimal computeTotalOneTime(List<QuoteLineItem> qliList, Boolean isCalculateWithTaxes) {
        Decimal result = 0;

        if(qliList == null || qliList.isEmpty()) {
            return result;
        }

        for(QuoteLineItem qli : qliList) {

            String qliChargeTerm = QuoteLineItemHelper.getChargeTerm(qli);

            Boolean isTaxes = !isCalculateWithTaxes && Product2Helper.isTaxes(qli.Product2);

            if(!Product2Helper.CHARGE_TERM_ONE_TIME.equalsIgnoreCase(qliChargeTerm) || isTaxes) {
                continue;
            }

            Decimal quantity = AccountHelper.isTrial(qli.Quote.Account)
                        ? (Decimal) NumberHelper.getNumberNullSafe(qli.NewQuantity__c)
                        : QuoteLineItemHelper.getQuantity(qli);
            Decimal qliEffectivePriceNewValue = qli.EffectivePriceNew__c == null ? 0 : qli.EffectivePriceNew__c;

            result += (quantity * qliEffectivePriceNewValue);
        }

        return result;
    }

    @TestVisible
    private Decimal computeEstimatedHardware(List<QuoteLineItem> qliList) {

        Decimal result = 0;

        if(qliList == null || qliList.isEmpty()) {
            return result;
        }

        for(QuoteLineItem qli : qliList) {
            String qliChargeTerm = QuoteLineItemHelper.getChargeTerm(qli);
            String productFamily = qli.Product2.Family == null ? '' : qli.Product2.Family;
            if (qliChargeTerm == Product2Helper.CHARGE_TERM_ONE_TIME &&
                productFamily.containsIgnoreCase('phone')) {

                Decimal quantity = QuoteLineItemHelper.getQuantity(qli);
                Decimal qliEffectivePriceNewValue = qli.EffectivePriceNew__c == null ? 0 : qli.EffectivePriceNew__c;

                result += (quantity * qliEffectivePriceNewValue);
            }
        }

        return result;
    }

    @TestVisible
    private Decimal computeTotalMRR(List<QuoteLineItem> qliList) {
        return computeTotalMRR(qliList, false);
    }

    @TestVisible
    private Decimal computeTotalMRR(List<QuoteLineItem> qliList, Boolean isCalculateWithTaxes) {
        Decimal result = 0;

        if(qliList == null || qliList.isEmpty()) {
            return result;
        }

        Decimal quoteEntlTotalMrrValue = 0;

        for(QuoteLineItem qli : qliList) {

            String qliChargeTerm = QuoteLineItemHelper.getChargeTerm(qli);

            Boolean isTaxes = !isCalculateWithTaxes && Product2Helper.isTaxes(qli.Product2);

            if(isTaxes || qliChargeTerm == Product2Helper.CHARGE_TERM_ONE_TIME) {
                continue;
            }

            Decimal quantity = QuoteLineItemHelper.getQuantity(qli);

            Decimal entlDisplayQuantityValue = (Decimal) getRelatedData(qli.QuoteRecordType__c, qli, Entitlement__c.DisplayQuantity__c);

            Decimal qliEffectivePriceNewValue = qli.EffectivePriceNew__c == null ? 0 : qli.EffectivePriceNew__c;

            if(qliChargeTerm == Product2Helper.CHARGE_TERM_ANNUAL) {
                result += ((quantity + entlDisplayQuantityValue) * qliEffectivePriceNewValue) / 12;
            }else{
                result += (quantity + entlDisplayQuantityValue) * qliEffectivePriceNewValue;
            }

            quoteEntlTotalMrrValue = qli.Quote == null || qli.Quote.Entitlement_Total_MRR__c == null ? 0 : qli.Quote.Entitlement_Total_MRR__c;

            if(qli.QuoteRecordType__c == QuoteHelper.RT_NAME_BILLING &&
                qli.Quote.Upsell_Status__c != QuoteHelper.STATUS_NEW_CUSTOMER) {

                result -= computeNGBSEntitlementTotalMRR(qli);
            }
        }

        if(!qliList.isEmpty() && qliList.get(0).QuoteRecordType__c != QuoteHelper.RT_NAME_BILLING) {
            result -= quoteEntlTotalMrrValue;
        }

        return result;
    }

    @TestVisible
    private Decimal computeTotalARR(List<QuoteLineItem> qliList) {
        return computeTotalARR(qliList, false);
    }

    @TestVisible
    private Decimal computeTotalARR(List<QuoteLineItem> qliList, Boolean isCalculateWithTaxes) {

        Decimal result = 0;

        if(qliList == null || qliList.isEmpty()) {
            return result;
        }

        Decimal quoteEntlTotalArrValue = 0;

        for(QuoteLineItem qli : qliList) {

            String qliChargeTerm = QuoteLineItemHelper.getChargeTerm(qli);

            Boolean isTaxes = !isCalculateWithTaxes && Product2Helper.isTaxes(qli.Product2);

            if(isTaxes || qliChargeTerm == Product2Helper.CHARGE_TERM_ONE_TIME) {
                continue;
            }

            Decimal quantity = QuoteLineItemHelper.getQuantity(qli);

            Decimal entlDisplayQuantityValue = (Decimal) getRelatedData(qli.QuoteRecordType__c, qli, Entitlement__c.DisplayQuantity__c);

            Decimal qliEffectivePriceNewValue = qli.EffectivePriceNew__c == null ? 0 : qli.EffectivePriceNew__c;

            if(monthlyOrMonthlyContractSet.contains(qliChargeTerm)) {
                result += ((quantity + entlDisplayQuantityValue) * qliEffectivePriceNewValue) * 12;
            }else{
                result += ((quantity + entlDisplayQuantityValue) * qliEffectivePriceNewValue);
            }

            quoteEntlTotalArrValue = qli.Quote == null || qli.Quote.Entitlement_Total_ARR__c == null ? 0 : qli.Quote.Entitlement_Total_ARR__c;

            if(qli.QuoteRecordType__c == QuoteHelper.RT_NAME_BILLING &&
                qli.Quote.Upsell_Status__c != QuoteHelper.STATUS_NEW_CUSTOMER) {

                result -= computeNGBSEntitlementTotalARR(qli);
            }
        }

        if(!qliList.isEmpty() && qliList.get(0).QuoteRecordType__c != QuoteHelper.RT_NAME_BILLING) {
            result -= quoteEntlTotalArrValue;
        }

        return result;
    }

    @TestVisible
    private Decimal computeTotalInitialPayment(List<QuoteLineItem> qliList, Boolean isCalculateWithoutProServ) {
        return computeTotalInitialPayment(qliList, false, isCalculateWithoutProServ);
    }

    @TestVisible
    private Decimal computeTotalInitialPayment(List<QuoteLineItem> qliList, Boolean isCalculateWithTaxes, Boolean isCalculateWithoutProServ) {

        Decimal result = 0;

        if(qliList == null || qliList.isEmpty()) {
            return result;
        }

        for(QuoteLineItem qli : qliList) {

            Boolean isTaxes = !isCalculateWithTaxes && Product2Helper.isTaxes(qli.Product2);
            Boolean isProServ = isCalculateWithoutProServ && (qli.ServiceName__c == Product2Helper.SUBCATEGORY_PROSERV || (QuoteLineItemHelper.isOfficeQli(qli) && Product2Helper.isProfessionalServiceProduct(qli.Product2)));
            Boolean isEvents = QuoteLineItemHelper.isEventsQli(qli);
            if(isTaxes || isProServ || isEvents) {
                continue;
            }

            String qliChargeTerm = QuoteLineItemHelper.getChargeTerm(qli);
            Decimal quantity = QuoteLineItemHelper.getQuantity(qli);
            Decimal qliEffectivePriceNewValue = qli.EffectivePriceNew__c == null ? 0 : qli.EffectivePriceNew__c;

            if (qli.Entitlement__c == null || qliChargeTerm == Product2Helper.CHARGE_TERM_ONE_TIME ) {
                result += (quantity * qliEffectivePriceNewValue);
            } else {
                String entlChargeTerm = (String) getRelatedData(qli.QuoteRecordType__c, qli, Product2.Charge_Term__c);
                Decimal entlDisplayQuantity = (Decimal) getRelatedData(qli.QuoteRecordType__c, qli, Entitlement__c.DisplayQuantity__c);
                Decimal entlEffectivePrice = NumberHelper.toNumber(qli.Entitlement__r.EffectivePricePrecise__c);

                if((qliChargeTerm == Product2Helper.CHARGE_TERM_ANNUAL && entlChargeTerm == Product2Helper.CHARGE_TERM_ANNUAL) ||
                    (monthlyOrMonthlyContractSet.contains(qliChargeTerm) && monthlyOrMonthlyContractSet.contains(entlChargeTerm))) {

                    result += ((quantity + entlDisplayQuantity) * qliEffectivePriceNewValue) - (entlDisplayQuantity * entlEffectivePrice);

                }else if(qliChargeTerm == Product2Helper.CHARGE_TERM_ANNUAL && monthlyOrMonthlyContractSet.contains(entlChargeTerm)) {

                    result += ((quantity + entlDisplayQuantity) * qliEffectivePriceNewValue) - ((entlDisplayQuantity * entlEffectivePrice) * 12);

                }else if(monthlyOrMonthlyContractSet.contains(qliChargeTerm) && entlChargeTerm == Product2Helper.CHARGE_TERM_ANNUAL) {

                    result += ((quantity + entlDisplayQuantity) * qliEffectivePriceNewValue) - ((entlDisplayQuantity * entlEffectivePrice) / 12);
                }
            }
        }
        return result;
    }

    @TestVisible
    private Decimal computeCLMTotalInitialPayment(List<QuoteLineItem> qliList, Boolean isCalculateWithTaxes) {

        Decimal result = 0;

        if(qliList == null || qliList.isEmpty()) {
            return result;
        }

        for(QuoteLineItem qli : qliList) {

            Boolean isTaxes = !isCalculateWithTaxes && Product2Helper.isTaxes(qli.Product2);
            Boolean isProServ = (qli.ServiceName__c == Product2Helper.SUBCATEGORY_PROSERV || (QuoteLineItemHelper.isOfficeQli(qli) && Product2Helper.isProfessionalServiceProduct(qli.Product2)));
            Boolean isEvents = QuoteLineItemHelper.isEventsQli(qli);

            if (isTaxes || isProServ || isEvents) {
                continue;
            }

            Decimal newQuantity = (Decimal) NumberHelper.getNumberNullSafe(qli.NewQuantity__c);
            Decimal qliEffectivePriceNewValue = qli.EffectivePriceNew__c == null ? 0 : qli.EffectivePriceNew__c;
            result += (newQuantity * qliEffectivePriceNewValue);
        }
        return result;
    }


    @TestVisible
    private Decimal computeTotalOneTimeDiscount(List<QuoteLineItem> qliList) {

        Decimal result = 0;

        if(qliList == null || qliList.isEmpty()) {
            return result;
        }

        for(QuoteLineItem qli : qliList) {

            String qliChargeTerm = QuoteLineItemHelper.getChargeTerm(qli);

            Boolean isTaxes = Product2Helper.isTaxes(qli.Product2);

            if(isTaxes || qliChargeTerm != Product2Helper.CHARGE_TERM_ONE_TIME) {
                continue;
            }

            Decimal qliDiscountValueNew = qli.DiscountValueNew__c == null ? 0 : qli.DiscountValueNew__c;

            Decimal quantity = QuoteLineItemHelper.getQuantity(qli);

            result += qliDiscountValueNew * quantity;
        }

        return result;
    }

    @TestVisible
    private Decimal computeTotalMRRDiscount(List<QuoteLineItem> qliList) {

        Decimal result = 0;

        if(qliList == null || qliList.isEmpty()) {
            return result;
        }

        for(QuoteLineItem qli : qliList) {

            String qliChargeTerm = QuoteLineItemHelper.getChargeTerm(qli);

            Boolean isTaxes = Product2Helper.isTaxes(qli.Product2);

            if(qliChargeTerm == Product2Helper.CHARGE_TERM_ONE_TIME || isTaxes) {
                continue;
            }

            Decimal quantity = QuoteLineItemHelper.getQuantity(qli);
            Decimal qliDiscountValueNew = qli.DiscountValueNew__c == null ? 0 : qli.DiscountValueNew__c;

            if (qli.Entitlement__c == null) {
                if (qliChargeTerm == Product2Helper.CHARGE_TERM_ANNUAL) {
                    result += (qliDiscountValueNew * quantity) / 12;
                } else {
                    result += qliDiscountValueNew * quantity;
                }
            } else {
                String entlChargeTerm = (String) getRelatedData(qli.QuoteRecordType__c, qli, Product2.Charge_Term__c);
                Decimal entlDisplayQuantity = (Decimal) getRelatedData(qli.QuoteRecordType__c, qli, Entitlement__c.DisplayQuantity__c);
                Decimal entlEffectivePrice = (Decimal) getRelatedData(qli.QuoteRecordType__c, qli, Entitlement__c.EffectivePrice__c);
                Decimal entlPrice = (Decimal) getRelatedData(qli.QuoteRecordType__c, qli, Entitlement__c.Price__c);

                Decimal qliResult = 0;
                Decimal entlResult = 0;

                if(qliChargeTerm == Product2Helper.CHARGE_TERM_ANNUAL) {
                    qliResult += (((quantity + entlDisplayQuantity) * qliDiscountValueNew) / 12);
                }else{
                    qliResult += (quantity + entlDisplayQuantity) * qliDiscountValueNew;
                }

                if(entlChargeTerm == Product2Helper.CHARGE_TERM_ANNUAL) {
                    entlResult += ((entlPrice - entlEffectivePrice) * entlDisplayQuantity) / 12;
                }else{
                    entlResult += (entlPrice - entlEffectivePrice) * entlDisplayQuantity;
                }

                result += (qliResult - entlResult);
            }
        }

        return result;
    }

    @TestVisible
    private Decimal computeTotalARRDiscount(List<QuoteLineItem> qliList) {

        Decimal result = 0;

        if(qliList == null || qliList.isEmpty()) {
            return result;
        }

        for(QuoteLineItem qli : qliList) {

            String qliChargeTerm = QuoteLineItemHelper.getChargeTerm(qli);

            Boolean isTaxes = Product2Helper.isTaxes(qli.Product2);

            if(qliChargeTerm == Product2Helper.CHARGE_TERM_ONE_TIME || isTaxes) {
                continue;
            }

            Decimal qliDiscountValueNew = qli.DiscountValueNew__c == null ? 0 : qli.DiscountValueNew__c;
            Decimal quantity = QuoteLineItemHelper.getQuantity(qli);

            if(qli.Entitlement__c == null) {
                if(monthlyOrMonthlyContractSet.contains(qliChargeTerm)) {
                    result += (qliDiscountValueNew * quantity) * 12;
                }else{
                    result += qliDiscountValueNew * quantity;
                }
            }else{

                String entlChargeTerm = (String) getRelatedData(qli.QuoteRecordType__c, qli, Product2.Charge_Term__c);
                Decimal entlDisplayQuantity = (Decimal) getRelatedData(qli.QuoteRecordType__c, qli, Entitlement__c.DisplayQuantity__c);
                Decimal entlEffectivePrice = (Decimal) getRelatedData(qli.QuoteRecordType__c, qli, Entitlement__c.EffectivePrice__c);
                Decimal entlPrice = (Decimal) getRelatedData(qli.QuoteRecordType__c, qli, Entitlement__c.Price__c);

                Decimal qliResult = 0;
                Decimal entlResult = 0;

                if(monthlyOrMonthlyContractSet.contains(qliChargeTerm)) {
                    qliResult += (((quantity + entlDisplayQuantity) * qliDiscountValueNew) * 12);
                }else{
                    qliResult += (quantity + entlDisplayQuantity) * qliDiscountValueNew;
                }

                if(monthlyOrMonthlyContractSet.contains(entlChargeTerm)) {
                    entlResult += (((entlPrice - entlEffectivePrice) * entlDisplayQuantity) * 12);
                }else{
                    entlResult += ((entlPrice - entlEffectivePrice) * entlDisplayQuantity);
                }

                result += (qliResult - entlResult);
            }
        }

        return result;
    }

    @TestVisible
    private Decimal computeTotalInitialPaymentDiscount(List<QuoteLineItem> qliList, Decimal totalOneTimeDiscount) {

        Decimal result = 0;

        if(qliList == null || qliList.isEmpty()) {
            return result;
        }

        result += (totalOneTimeDiscount == null ? 0 : totalOneTimeDiscount);

        for(QuoteLineItem qli : qliList) {

            String qliChargeTerm = QuoteLineItemHelper.getChargeTerm(qli);

            Boolean isTaxes = Product2Helper.isTaxes(qli.Product2);

            if(Product2Helper.CHARGE_TERM_ONE_TIME.equalsIgnoreCase(qliChargeTerm) || isTaxes) {
                continue;
            }

            Decimal qliDiscountValueNew = qli.DiscountValueNew__c == null ? 0 : qli.DiscountValueNew__c;
            Decimal quantity = QuoteLineItemHelper.getQuantity(qli);

            if (qli.Entitlement__c == null) {
                result += qliDiscountValueNew * quantity;
            } else {
                String entlChargeTerm = (String) getRelatedData(qli.QuoteRecordType__c, qli, Product2.Charge_Term__c);
                Decimal entlDisplayQuantity = (Decimal) getRelatedData(qli.QuoteRecordType__c, qli, Entitlement__c.DisplayQuantity__c);
                Decimal entlEffectivePrice = (Decimal) getRelatedData(qli.QuoteRecordType__c, qli, Entitlement__c.EffectivePrice__c);
                Decimal entlPrice = (Decimal) getRelatedData(qli.QuoteRecordType__c, qli, Entitlement__c.Price__c);

                if((qliChargeTerm == Product2Helper.CHARGE_TERM_ANNUAL && entlChargeTerm == Product2Helper.CHARGE_TERM_ANNUAL) ||
                    (monthlyOrMonthlyContractSet.contains(qliChargeTerm) && monthlyOrMonthlyContractSet.contains(entlChargeTerm))) {

                    result += (((quantity + entlDisplayQuantity) * qliDiscountValueNew) - ((entlPrice - entlEffectivePrice) * entlDisplayQuantity));

                }else if(qliChargeTerm == Product2Helper.CHARGE_TERM_ANNUAL && monthlyOrMonthlyContractSet.contains(entlChargeTerm)) {

                    result += (((quantity + entlDisplayQuantity) * qliDiscountValueNew) - (((entlPrice - entlEffectivePrice) * entlDisplayQuantity) * 12));

                }else if(monthlyOrMonthlyContractSet.contains(qliChargeTerm) && entlChargeTerm == Product2Helper.CHARGE_TERM_ANNUAL) {

                    result += (((quantity + entlDisplayQuantity) * qliDiscountValueNew) - (((entlPrice - entlEffectivePrice) * entlDisplayQuantity) / 12));
                }
            }
        }

        return result;
    }

    @TestVisible
    private Decimal computeTotalOneTimeWithTaxes(List<QuoteLineItem> qliList, Decimal quoteTotalOneTimeValue) {

        Decimal result = 0;

        if(qliList == null || qliList.isEmpty()) {
            return result;
        }

        result += (quoteTotalOneTimeValue == null ? 0 : quoteTotalOneTimeValue);

        for(QuoteLineItem qli : qliList) {

            String qliChargeTerm = QuoteLineItemHelper.getChargeTerm(qli);

            Boolean isTaxes = Product2Helper.isTaxes(qli.Product2);

            if(isTaxes || qliChargeTerm != Product2Helper.CHARGE_TERM_ONE_TIME) {
                continue;
            }

            Decimal fixedTaxesAmount = qli.Fixed_Taxes_Amount__c == null ? 0 : qli.Fixed_Taxes_Amount__c;
            Decimal variableTaxesAmount = qli.Variable_Taxes_Amount__c == null ? 0 : qli.Variable_Taxes_Amount__c;

            result += fixedTaxesAmount + variableTaxesAmount;
        }

        return result;
    }

    @TestVisible
    private Decimal computeTotalMRRWithTaxes(List<QuoteLineItem> qliList, Decimal quoteTotalMrrValue) {

        Decimal result = 0;

        if(qliList == null || qliList.isEmpty()) {
            return result;
        }

        result += (quoteTotalMrrValue == null ? 0 : quoteTotalMrrValue);

        for(QuoteLineItem qli : qliList) {

            String qliChargeTerm = QuoteLineItemHelper.getChargeTerm(qli);

            Boolean isTaxes = Product2Helper.isTaxes(qli.Product2);

            if(isTaxes || (qliChargeTerm == Product2Helper.CHARGE_TERM_ONE_TIME)) {
                continue;
            }

            Decimal fixedTaxesAmount = qli.Fixed_Taxes_Amount__c == null ? 0 : qli.Fixed_Taxes_Amount__c;
            Decimal variableTaxesAmount = qli.Variable_Taxes_Amount__c == null ? 0 : qli.Variable_Taxes_Amount__c;

            if(qliChargeTerm == Product2Helper.CHARGE_TERM_ANNUAL) {
                result += (fixedTaxesAmount + variableTaxesAmount) / 12;
            }else{
                result += (fixedTaxesAmount + variableTaxesAmount);
            }
        }

        return result;
    }

    @TestVisible
    private Decimal computeTotalARRWithTaxes(List<QuoteLineItem> qliList, Decimal quoteTotalArrValue) {

        Decimal result = 0;

        if(qliList == null || qliList.isEmpty()) {
            return result;
        }

        result += (quoteTotalArrValue == null ? 0 : quoteTotalArrValue);

        for(QuoteLineItem qli : qliList) {

            String qliChargeTerm = QuoteLineItemHelper.getChargeTerm(qli);

            Boolean isTaxes = Product2Helper.isTaxes(qli.Product2);

            if(isTaxes || (qliChargeTerm == Product2Helper.CHARGE_TERM_ONE_TIME)) {
                continue;
            }

            Decimal fixedTaxesAmount = qli.Fixed_Taxes_Amount__c == null ? 0 : qli.Fixed_Taxes_Amount__c;
            Decimal variableTaxesAmount = qli.Variable_Taxes_Amount__c == null ? 0 : qli.Variable_Taxes_Amount__c;

            if(new Set<String>{
                Product2Helper.CHARGE_TERM_MONTHLY,
                Product2Helper.CHARGE_TERM_MONTHLY_CONTRACT
            }.contains(qliChargeTerm)) {
                result += (fixedTaxesAmount + variableTaxesAmount) * 12;
            }else{
                result += (fixedTaxesAmount + variableTaxesAmount);
            }
        }

        return result;
    }

    @TestVisible
    private Decimal computeTotalInitialPaymentWithTaxes(List<QuoteLineItem> qliList, Decimal quoteTotalInitialPayment) {

        Decimal result = 0;

        if(qliList == null || qliList.isEmpty()) {
            return result;
        }

        result += (quoteTotalInitialPayment == null ? 0 : quoteTotalInitialPayment);

        for(QuoteLineItem qli : qliList) {

            Boolean isTaxes = Product2Helper.isTaxes(qli.Product2);
            if(isTaxes) {
                continue;
            }

            Decimal fixedTaxesAmount = qli.Fixed_Taxes_Amount__c == null ? 0 : qli.Fixed_Taxes_Amount__c;
            Decimal variableTaxesAmount = qli.Variable_Taxes_Amount__c == null ? 0 : qli.Variable_Taxes_Amount__c;

            result += (fixedTaxesAmount + variableTaxesAmount);
        }

        return result;
    }

    @TestVisible
    private Decimal computeTotalQuoteSummary(List<QuoteLineItem> qliList) {
        Decimal result = 0;

        if (qliList == null || qliList.isEmpty()) {
            return result;
        }

        for (QuoteLineItem qli : qliList) {
            String qliChargeTerm = QuoteLineItemHelper.getChargeTerm(qli);

            Boolean isTaxes = Product2Helper.isTaxes(qli.Product2);

            if (isTaxes || qliChargeTerm == Product2Helper.CHARGE_TERM_ONE_TIME) {
                continue;
            }

            result += (qli.TotalSummary__c != null ? qli.TotalSummary__c : 0);
        }

        return result;
    }

    @TestVisible
    private Decimal computeContactCenterTotalOneTime(List<QuoteLineItem> qliList) {

        Decimal result = 0;

        if(qliList == null || qliList.isEmpty()) {
            return result;
        }

        for(QuoteLineItem qli : qliList) {

            Boolean isTaxes = Product2Helper.isTaxes(qli.Product2);
            if(isTaxes) {
                continue;
            }

            String qliChargeTerm = QuoteLineItemHelper.getChargeTerm(qli);

            if(qliChargeTerm == Product2Helper.CHARGE_TERM_ONE_TIME &&
                qli.Product2.Sub_Category__c == Product2Helper.SUBCATEGORY_CONTACT_CENTER) {

                Decimal quantity = QuoteLineItemHelper.getQuantity(qli);
                Decimal qliEffectivePriceNewValue = qli.EffectivePriceNew__c == null ? 0 : qli.EffectivePriceNew__c;

                result += (quantity * qliEffectivePriceNewValue);
            }
        }

        return result;
    }

    @TestVisible
    private Decimal computeContactCenterTotalMRR(List<QuoteLineItem> qliList) {

        Decimal result = 0;

        if(qliList == null || qliList.isEmpty()) {
            return result;
        }

        Decimal quoteEntlCCTotalMrrValue = 0;

        for(QuoteLineItem qli : qliList) {

            Boolean isTaxes = Product2Helper.isTaxes(qli.Product2);
            if(isTaxes) {
                continue;
            }

            String qliChargeTerm = QuoteLineItemHelper.getChargeTerm(qli);

            if(qliChargeTerm != Product2Helper.CHARGE_TERM_ONE_TIME && qli.Product2.Sub_Category__c == Product2Helper.SUBCATEGORY_CONTACT_CENTER) {

                Decimal quantity = QuoteLineItemHelper.getQuantity(qli);

                Decimal entlDisplayQuantityValue = (Decimal) getRelatedData(qli.QuoteRecordType__c, qli, Entitlement__c.DisplayQuantity__c);

                Decimal qliEffectivePriceNewValue = qli.EffectivePriceNew__c == null ?
                    0 : qli.EffectivePriceNew__c;

                if(qliChargeTerm == Product2Helper.CHARGE_TERM_ANNUAL) {
                    result += ((quantity + entlDisplayQuantityValue) * qliEffectivePriceNewValue) / 12;
                }else{
                    result += ((quantity + entlDisplayQuantityValue) * qliEffectivePriceNewValue);
                }

                quoteEntlCCTotalMrrValue = (qli.Quote == null || qli.Quote.Contact_Center_Entitlement_Total_MRR__c == null) ? 0 : qli.Quote.Contact_Center_Entitlement_Total_MRR__c;
            }
        }

        result -= quoteEntlCCTotalMrrValue;

        return result;
    }

    @TestVisible
    private Decimal computeContactCenterTotalARR(List<QuoteLineItem> qliList) {

        Decimal result = 0;

        if(qliList == null || qliList.isEmpty()) {
            return result;
        }

        Decimal quoteCCEntlTotalArrValue = 0;

        for(QuoteLineItem qli : qliList) {

            Boolean isTaxes = Product2Helper.isTaxes(qli.Product2);
            if(isTaxes) {
                continue;
            }

            String qliChargeTerm = QuoteLineItemHelper.getChargeTerm(qli);

            if(qliChargeTerm != Product2Helper.CHARGE_TERM_ONE_TIME && qli.Product2.Sub_Category__c == Product2Helper.SUBCATEGORY_CONTACT_CENTER) {

                Decimal quantity = QuoteLineItemHelper.getQuantity(qli);

                Decimal entlDisplayQuantityValue = (Decimal) getRelatedData(qli.QuoteRecordType__c, qli, Entitlement__c.DisplayQuantity__c);

                Decimal qliEffectivePriceNewValue = qli.EffectivePriceNew__c == null ?
                    0 : qli.EffectivePriceNew__c;

                if(new Set<String>{
                    Product2Helper.CHARGE_TERM_MONTHLY,
                    Product2Helper.CHARGE_TERM_MONTHLY_CONTRACT
                }.contains(qliChargeTerm)) {
                    result += ((quantity + entlDisplayQuantityValue) * qliEffectivePriceNewValue) * 12;
                }else{
                    result += ((quantity + entlDisplayQuantityValue) * qliEffectivePriceNewValue);
                }

                quoteCCEntlTotalArrValue = qli.Quote == null || qli.Quote.Contact_Center_Entitlement_Total_ARR__c == null ? 0 : qli.Quote.Contact_Center_Entitlement_Total_ARR__c;
            }
        }

        result -= quoteCCEntlTotalArrValue;

        return result;
    }

    @TestVisible
    private Decimal computeContactCenterTotalInitialPayment(List<QuoteLineItem> qliList) {

        Decimal result = 0;

        if(qliList == null || qliList.isEmpty()) {
            return result;
        }

        for(QuoteLineItem qli : qliList) {

            Boolean isTaxes = Product2Helper.isTaxes(qli.Product2);

            if(isTaxes || (qli.Product2.Sub_Category__c != Product2Helper.SUBCATEGORY_CONTACT_CENTER)) {
                continue;
            }

            String qliChargeTerm = QuoteLineItemHelper.getChargeTerm(qli);

            Decimal qliEffectivePriceNewValue = qli.EffectivePriceNew__c == null ? 0 : qli.EffectivePriceNew__c;
            Decimal quantity = QuoteLineItemHelper.getQuantity(qli);

            if(qli.Entitlement__c == null || qliChargeTerm == Product2Helper.CHARGE_TERM_ONE_TIME) {
                result += quantity * qliEffectivePriceNewValue;
            }else{

                String entlChargeTerm = (String) getRelatedData(qli.QuoteRecordType__c, qli, Product2.Charge_Term__c);
                Decimal entlDisplayQuantity = (Decimal) getRelatedData(qli.QuoteRecordType__c, qli, Entitlement__c.DisplayQuantity__c);
                Decimal entlEffectivePrice = (Decimal) getRelatedData(qli.QuoteRecordType__c, qli, Entitlement__c.EffectivePrice__c);

                if((qliChargeTerm == Product2Helper.CHARGE_TERM_ANNUAL && entlChargeTerm == Product2Helper.CHARGE_TERM_ANNUAL) ||
                    (monthlyOrMonthlyContractSet.contains(qliChargeTerm) && monthlyOrMonthlyContractSet.contains(entlChargeTerm))) {

                    result += ((quantity + entlDisplayQuantity) * qliEffectivePriceNewValue) - (entlDisplayQuantity * entlEffectivePrice);

                }else if(qliChargeTerm == Product2Helper.CHARGE_TERM_ANNUAL && monthlyOrMonthlyContractSet.contains(entlChargeTerm)) {

                    result += ((quantity + entlDisplayQuantity) * qliEffectivePriceNewValue) - ((entlDisplayQuantity * entlEffectivePrice) * 12);

                }else if(monthlyOrMonthlyContractSet.contains(qliChargeTerm) && entlChargeTerm == Product2Helper.CHARGE_TERM_ANNUAL) {

                    result += ((quantity + entlDisplayQuantity) * qliEffectivePriceNewValue) - ((entlDisplayQuantity * entlEffectivePrice) / 12);
                }
            }
        }

        return result;
    }

    @TestVisible
    private Decimal computeContactCenterTotalOneTimeDiscount(List<QuoteLineItem> qliList) {

        Decimal result = 0;

        if(qliList == null || qliList.isEmpty()) {
            return result;
        }

        for(QuoteLineItem qli : qliList) {

            Boolean isTaxes = Product2Helper.isTaxes(qli.Product2);

            if(isTaxes) {
                continue;
            }

            String qliChargeTerm = QuoteLineItemHelper.getChargeTerm(qli);

            if(qliChargeTerm == Product2Helper.CHARGE_TERM_ONE_TIME && qli.Product2.Sub_Category__c == Product2Helper.SUBCATEGORY_CONTACT_CENTER) {
                Decimal qliDiscountValueNew = qli.DiscountValueNew__c == null ? 0 : qli.DiscountValueNew__c;
                Decimal quantity = QuoteLineItemHelper.getQuantity(qli);

                result += qliDiscountValueNew * quantity;
            }
        }

        return result;
    }

    @TestVisible
    private Decimal computeContactCenterTotalMRRDiscount(List<QuoteLineItem> qliList) {

        Decimal result = 0;

        if(qliList == null || qliList.isEmpty()) {
            return result;
        }

        for(QuoteLineItem qli : qliList) {

            String qliChargeTerm = QuoteLineItemHelper.getChargeTerm(qli);

            Boolean isTaxes = Product2Helper.isTaxes(qli.Product2);

            if(isTaxes) {
                continue;
            }

            if(qliChargeTerm != Product2Helper.CHARGE_TERM_ONE_TIME && qli.Product2.Sub_Category__c == Product2Helper.SUBCATEGORY_CONTACT_CENTER) {

                Decimal qliDiscountValueNew = qli.DiscountValueNew__c == null ? 0 : qli.DiscountValueNew__c;
                Decimal quantity = QuoteLineItemHelper.getQuantity(qli);

                if(qli.Entitlement__c == null) {

                    if(qliChargeTerm == Product2Helper.CHARGE_TERM_ANNUAL) {
                        result += ((quantity * qliDiscountValueNew) / 12);
                    }else{
                        result += quantity * qliDiscountValueNew;
                    }
                }else{

                    String entlChargeTerm = (String) getRelatedData(qli.QuoteRecordType__c, qli, Product2.Charge_Term__c);
                    Decimal entlDisplayQuantity = (Decimal) getRelatedData(qli.QuoteRecordType__c, qli, Entitlement__c.DisplayQuantity__c);
                    Decimal entlEffectivePrice = (Decimal) getRelatedData(qli.QuoteRecordType__c, qli, Entitlement__c.EffectivePrice__c);
                    Decimal entlPrice = (Decimal) getRelatedData(qli.QuoteRecordType__c, qli, Entitlement__c.Price__c);

                    Decimal qliResult = 0;
                    Decimal entlResult = 0;

                    if(qliChargeTerm == Product2Helper.CHARGE_TERM_ANNUAL) {
                        qliResult += (((quantity + entlDisplayQuantity) * qliDiscountValueNew) / 12);
                    }else{
                        qliResult += ((quantity + entlDisplayQuantity) * qliDiscountValueNew);
                    }

                    if(entlChargeTerm == Product2Helper.CHARGE_TERM_ANNUAL) {
                        entlResult += (((entlPrice - entlEffectivePrice) * entlDisplayQuantity) / 12);
                    }else{
                        entlResult += ((entlPrice - entlEffectivePrice) * entlDisplayQuantity);
                    }

                    result += (qliResult - entlResult);
                }
            }
        }

        return result;
    }

    @TestVisible
    private Decimal computeContactCenterTotalARRDiscount(List<QuoteLineItem> qliList) {

        Decimal result = 0;

        if(qliList == null || qliList.isEmpty()) {
            return result;
        }

        for(QuoteLineItem qli : qliList) {

            String qliChargeTerm = QuoteLineItemHelper.getChargeTerm(qli);

            Boolean isTaxes = Product2Helper.isTaxes(qli.Product2);

            if(isTaxes) {
                continue;
            }

            if(qliChargeTerm != Product2Helper.CHARGE_TERM_ONE_TIME && qli.Product2.Sub_Category__c == Product2Helper.SUBCATEGORY_CONTACT_CENTER) {

                Decimal quantity = QuoteLineItemHelper.getQuantity(qli);
                Decimal qliDiscountValueNew = qli.DiscountValueNew__c == null ? 0 : qli.DiscountValueNew__c;

                if(qli.Entitlement__c == null) {


                    if(monthlyOrMonthlyContractSet.contains(qliChargeTerm)) {
                        result += ((quantity * qliDiscountValueNew) * 12);
                    }else{
                        result += quantity * qliDiscountValueNew;
                    }
                }else{

                    String entlChargeTerm = (String) getRelatedData(qli.QuoteRecordType__c, qli, Product2.Charge_Term__c);
                    Decimal entlDisplayQuantity = (Decimal) getRelatedData(qli.QuoteRecordType__c, qli, Entitlement__c.DisplayQuantity__c);
                    Decimal entlEffectivePrice = (Decimal) getRelatedData(qli.QuoteRecordType__c, qli, Entitlement__c.EffectivePrice__c);
                    Decimal entlPrice = (Decimal) getRelatedData(qli.QuoteRecordType__c, qli, Entitlement__c.Price__c);

                    Decimal qliResult = 0;
                    Decimal entlResult = 0;

                    if(monthlyOrMonthlyContractSet.contains(qliChargeTerm)) {
                        qliResult += (((quantity + entlDisplayQuantity) * qliDiscountValueNew) * 12);
                    }else{
                        qliResult += ((quantity + entlDisplayQuantity) * qliDiscountValueNew);
                    }

                    if(monthlyOrMonthlyContractSet.contains(entlChargeTerm)) {
                        entlResult += (((entlPrice - entlEffectivePrice) * entlDisplayQuantity) * 12);
                    }else{
                        entlResult += ((entlPrice - entlEffectivePrice) * entlDisplayQuantity);
                    }

                    result += (qliResult - entlResult);
                }
            }
        }

        return result;
    }

    @TestVisible
    private Decimal computeContactCenterTotalInitialPaymentDiscount(List<QuoteLineItem> qliList, Decimal contactCenterTotalOneTimeDiscount) {

        Decimal result = 0;

        result += (contactCenterTotalOneTimeDiscount == null ? 0 : contactCenterTotalOneTimeDiscount);

        if(qliList == null || qliList.isEmpty()) {
            return result;
        }

        for(QuoteLineItem qli : qliList) {

            String qliChargeTerm = QuoteLineItemHelper.getChargeTerm(qli);

            Boolean isTaxes = Product2Helper.isTaxes(qli.Product2);

            if(isTaxes) {
                continue;
            }

            if(qli.Product2.Sub_Category__c == Product2Helper.SUBCATEGORY_CONTACT_CENTER && qliChargeTerm != Product2Helper.CHARGE_TERM_ONE_TIME) {

                Decimal qliDiscountValueNew = qli.DiscountValueNew__c == null ? 0 : qli.DiscountValueNew__c;
                Decimal quantity = QuoteLineItemHelper.getQuantity(qli);

                if(qli.Entitlement__c == null) {
                    result += (quantity * qliDiscountValueNew);
                }else{

                    String entlChargeTerm = (String) getRelatedData(qli.QuoteRecordType__c, qli, Product2.Charge_Term__c);
                    Decimal entlDisplayQuantity = (Decimal) getRelatedData(qli.QuoteRecordType__c, qli, Entitlement__c.DisplayQuantity__c);
                    Decimal entlEffectivePrice = (Decimal) getRelatedData(qli.QuoteRecordType__c, qli, Entitlement__c.EffectivePrice__c);
                    Decimal entlPrice = (Decimal) getRelatedData(qli.QuoteRecordType__c, qli, Entitlement__c.Price__c);

                    if((qliChargeTerm == Product2Helper.CHARGE_TERM_ANNUAL && entlChargeTerm == Product2Helper.CHARGE_TERM_ANNUAL) ||
                        (monthlyOrMonthlyContractSet.contains(qliChargeTerm) && monthlyOrMonthlyContractSet.contains(entlChargeTerm))) {

                        result += (((quantity + entlDisplayQuantity) * qliDiscountValueNew) - ((entlPrice - entlEffectivePrice) * entlDisplayQuantity));

                    }else if(qliChargeTerm == Product2Helper.CHARGE_TERM_ANNUAL && monthlyOrMonthlyContractSet.contains(entlChargeTerm)) {

                        result += (((quantity + entlDisplayQuantity) * qliDiscountValueNew) - (((entlPrice - entlEffectivePrice) * entlDisplayQuantity) * 12));

                    }else if(monthlyOrMonthlyContractSet.contains(qliChargeTerm) && entlChargeTerm == Product2Helper.CHARGE_TERM_ANNUAL) {

                        result += (((quantity + entlDisplayQuantity) * qliDiscountValueNew) - (((entlPrice - entlEffectivePrice) * entlDisplayQuantity) / 12));
                    }
                }
            }
        }

        return result;
    }

    @TestVisible
    private Decimal computeDeltaMrr(List<QuoteLineItem> qliList) {

        Decimal result = 0;
        String qliChargeTerm;

        if(qliList == null || qliList.isEmpty()) {
            return result;
        }

        for(QuoteLineItem qli : qliList) {

            qliChargeTerm = QuoteLineItemHelper.getChargeTerm(qli);

            if(qliChargeTerm == Product2Helper.CHARGE_TERM_ONE_TIME) {
                continue;
            }

            Decimal deltaMrrValue = qli.Delta_MRR__c == null ? 0 : qli.Delta_MRR__c;

            result += deltaMrrValue;
        }

        return result;
    }

    @TestVisible
    private Decimal computeDeltaArr(List<QuoteLineItem> qliList) {

        Decimal result = 0;
        String qliChargeTerm;

        if(qliList == null || qliList.isEmpty()) {
            return result;
        }

        for(QuoteLineItem qli : qliList) {

            qliChargeTerm = QuoteLineItemHelper.getChargeTerm(qli);

            if(qliChargeTerm == Product2Helper.CHARGE_TERM_ONE_TIME) {
                continue;
            }

            Decimal deltaArrValue = qli.Delta_ARR__c == null ? 0 : qli.Delta_ARR__c;

            result += deltaArrValue;
        }

        return result;
    }

    @TestVisible
    private Decimal computeDeltaCCMrr(List<QuoteLineItem> qliList) {

        Decimal result = 0;
        String qliChargeTerm;

        if(qliList == null || qliList.isEmpty()) {
            return result;
        }

        for(QuoteLineItem qli : qliList) {

            qliChargeTerm = QuoteLineItemHelper.getChargeTerm(qli);

            if(qliChargeTerm == Product2Helper.CHARGE_TERM_ONE_TIME) {
                continue;
            }

            if(qli.Product2.Sub_Category__c != Product2Helper.SUBCATEGORY_CONTACT_CENTER) {
                continue;
            }

            Decimal deltaMrrValue = qli.Delta_MRR__c == null ? 0 : qli.Delta_MRR__c;

            result += deltaMrrValue;
        }

        return result;
    }

    @TestVisible
    private Decimal computeDeltaCCArr(List<QuoteLineItem> qliList, Id quoteId) {

        Quote quote = this.quoteIdToQuoteMap.get(quoteId);

        Decimal result = 0;
        String qliChargeTerm;

        if(qliList == null || qliList.isEmpty()) {
            return result;
        }

        for(QuoteLineItem qli : qliList) {

            qliChargeTerm = QuoteLineItemHelper.getChargeTerm(qli);

            if(qliChargeTerm == Product2Helper.CHARGE_TERM_ONE_TIME) {
                continue;
            }

            if (qli.Product2.Sub_Category__c == Product2Helper.SUBCATEGORY_CONTACT_CENTER || QuoteHelper.isRCCC(quote)) {
                Decimal deltaArrValue = qli.Delta_ARR__c == null ? 0 : qli.Delta_ARR__c;

                result += deltaArrValue;
            } else {
                continue;
            }
        }

        return result;
    }

    @TestVisible
    private Decimal computeProServListPrice(List<QuoteLineItem> qliList, Id quoteId) {
        Quote quote = this.quoteIdToQuoteMap.get(quoteId);
        Decimal currentProServListPrice = 0;

        if (qliList == null || qliList.isEmpty()) {
            return currentProServListPrice;
        }

        for (QuoteLineItem qli : qliList) {
            if (Product2Helper.isTaxes(qli.Product2)) {
                continue;
            }

            if (QuoteHelper.NGBS_PROFESSIONAL_SERVICES_PRODUCT.equalsIgnoreCase(qli.ServiceName__c)) {
                currentProServListPrice += NumberHelper.toNumber(qli.UnitPrice) * qli.NewQuantity__c;
            }
        }

        Decimal initialOrderPrice = OpportunityHelper.isProServChangeOrderOpportunity(quote.Opportunity.Parent_Order__c, quote.Opportunity.Tier_Name__c)
            ? NumberHelper.toNumber(quote.Opportunity.Parent_Order__r?.Quote?.ProServListPrice__c)
            : 0;

        return currentProServListPrice - initialOrderPrice;
    }

    @TestVisible
    private Decimal computeProServDiscount(List<QuoteLineItem> qliList, Id quoteId) {
        Quote quote = this.quoteIdToQuoteMap.get(quoteId);
        Decimal currentProServDiscount = 0;

        if (qliList == null || qliList.isEmpty()) {
            return currentProServDiscount;
        }

        for (QuoteLineItem qli : qliList) {
            if (Product2Helper.isTaxes(qli.Product2)) {
                continue;
            }

            if (QuoteHelper.NGBS_PROFESSIONAL_SERVICES_PRODUCT.equalsIgnoreCase(qli.ServiceName__c)) {
                currentProServDiscount += NumberHelper.toNumber(qli.Discount_Value__c) * qli.NewQuantity__c;
            }
        }

        Decimal initialProServDiscount = OpportunityHelper.isProServChangeOrderOpportunity(quote.Opportunity.Parent_Order__c, quote.Opportunity.Tier_Name__c)
            ? NumberHelper.toNumber(quote.Opportunity.Parent_Order__r?.Quote?.ProServDiscount__c)
            : 0;

        return currentProServDiscount - initialProServDiscount;
    }

    public class PopulateEntlTotalsOnInsert extends Triggers.TriggerHandlerBase {
        override public void handle() {
            List<Quote> quoteToProcessList = new List<Quote>();

            for(Quote qt : (List<Quote>) Trigger.new) {
                quoteToProcessList.add(qt);
            }

            if(quoteToProcessList.isEmpty()) {
                return;
            }

            List<Quote> updatedQuotesList = populateEntitlementTotalsOnQuote(quoteToProcessList);
        }
    }

    public static List<Quote> populateEntitlementTotalsOnQuote(List<Quote> insertedQuotes) {

        if (insertedQuotes == null || insertedQuotes.isEmpty()) {
            return new List<Quote>();
        }

        List<Quote> updatedQuotes = new List<Quote>();

        List<Quote> nonNewCustomerQuotes = new List<Quote>();

        for(Quote qt : insertedQuotes) {

            if (qt.Upsell_Status__c == QuoteHelper.STATUS_NEW_CUSTOMER) {
                // for NewCustomer quotes entitlement totals always should be 0
                qt.Entitlement_Total_ARR__c = 0;
                qt.Entitlement_Total_MRR__c = 0;
                qt.Contact_Center_Entitlement_Total_ARR__c = 0;
                qt.Contact_Center_Entitlement_Total_MRR__c = 0;

                updatedQuotes.add(qt);
            }else{
                nonNewCustomerQuotes.add(qt);
            }
        }

        if (insertedQuotes.size() == updatedQuotes.size()) {
            return updatedQuotes;
        }

        Map<Id, List<Quote>> accountIdToQuoteListMap = new Map<Id, List<Quote>>();

        for (Quote q : nonNewCustomerQuotes) {

            if (q.RecordTypeId == QuoteHelper.RT_ID_PROSERV || q.RecordTypeId == QuoteHelper.RT_ID_CC_PROSERV) {
                continue;
            }

            if (QuoteTriggerHelper.opportunityMapStatic.containsKey(q.OpportunityId)) {
                Opportunity opp = QuoteTriggerHelper.opportunityMapStatic.get(q.OpportunityId);

                if (!accountIdToQuoteListMap.containsKey(opp.AccountId)) {
                    accountIdToQuoteListMap.put(opp.AccountId, new List<Quote>());
                }
                accountIdToQuoteListMap.get(opp.AccountId).add(q);
            } else if (q.AccountId != null) {
                if(!accountIdToQuoteListMap.containsKey(q.AccountId)) {
                    accountIdToQuoteListMap.put(q.AccountId, new List<Quote>());
                }
                accountIdToQuoteListMap.get(q.AccountId).add(q);
            }
        }

        if (accountIdToQuoteListMap.keySet().isEmpty()) {
            return updatedQuotes;
        }

        List<Account> accs = [SELECT Id,
                (SELECT Id, DisplayQuantity__c,
                    EffectivePrice__c, Quote__r.Id, Quote__r.RecordTypeId,
                    Product__c, Product__r.Charge_Term__c,
                    Product__r.Sub_Category__c
                FROM SupportEntitlements__r
                WHERE Product__r.Charge_Term__c != :Product2Helper.CHARGE_TERM_ONE_TIME
                AND Active__c = true)
            FROM Account
            WHERE Id IN :accountIdToQuoteListMap.keySet()];

        for (Account acc : accs) {

            if (accountIdToQuoteListMap.get(acc.Id).isEmpty()) {
                continue;
            }

            for (Quote qt : accountIdToQuoteListMap.get(acc.Id)) {

                Decimal calculatedEntlTotalArr = 0;
                Decimal calculatedEntlTotalMrr = 0;

                Decimal calculatedCCEntlTotalMrr = 0;
                Decimal calculatedCCEntlTotalArr = 0;
                for (Entitlement__c entl : acc.SupportEntitlements__r) {

                    Decimal displayQuantityValue = (Decimal) getRelatedData(QuoteHelper.RT_NAME_SALES, entl, Entitlement__c.DisplayQuantity__c);
                    Decimal effectivePriceValue = (Decimal) getRelatedData(QuoteHelper.RT_NAME_SALES, entl, Entitlement__c.EffectivePrice__c);

                    if (isEntitlementMatchingWithQuote(qt, entl)) {
                        if (entl.Product__r.Charge_Term__c == Product2Helper.CHARGE_TERM_ANNUAL) {
                            calculatedEntlTotalMrr += ((displayQuantityValue * effectivePriceValue) / 12);
                        } else {
                            calculatedEntlTotalMrr += (displayQuantityValue * effectivePriceValue);
                        }

                        if(monthlyOrMonthlyContractSet.contains(entl.Product__r.Charge_Term__c)) {
                            calculatedEntlTotalArr += ((displayQuantityValue * effectivePriceValue) * 12);
                        } else {
                            calculatedEntlTotalArr += (displayQuantityValue * effectivePriceValue);
                        }
                    }


                    if (entl.Product__r.Sub_Category__c != Product2Helper.SUBCATEGORY_CONTACT_CENTER) {
                        continue;
                    }

                    if (entl.Product__r.Charge_Term__c == Product2Helper.CHARGE_TERM_ANNUAL) {
                        calculatedCCEntlTotalMrr += ((displayQuantityValue * effectivePriceValue) / 12);
                    } else {
                        calculatedCCEntlTotalMrr += (displayQuantityValue * effectivePriceValue);
                    }

                    if (monthlyOrMonthlyContractSet.contains(entl.Product__r.Charge_Term__c)) {
                        calculatedCCEntlTotalArr += ((displayQuantityValue * effectivePriceValue) * 12);
                    } else {
                        calculatedCCEntlTotalArr += (displayQuantityValue * effectivePriceValue);
                    }
                }

                qt.Entitlement_Total_ARR__c = calculatedEntlTotalArr;
                qt.Entitlement_Total_MRR__c = calculatedEntlTotalMrr;
                qt.Contact_Center_Entitlement_Total_ARR__c = calculatedCCEntlTotalArr;
                qt.Contact_Center_Entitlement_Total_MRR__c = calculatedCCEntlTotalMrr;

                updatedQuotes.add(qt);
            }
        }

        return updatedQuotes;
    }

    public static Decimal computeNGBSEntitlementTotalARR(QuoteLineItem qli) {
        Decimal result = 0;

        Decimal displayQuantityValue = (Decimal) getRelatedData(qli.QuoteRecordType__c, qli, Entitlement__c.DisplayQuantity__c);
        Decimal effectivePriceValue = (Decimal) getRelatedData(qli.QuoteRecordType__c, qli, Entitlement__c.EffectivePrice__c);
        String chargeTermValue = (String) getRelatedData(qli.QuoteRecordType__c, qli, Product2.Charge_Term__c);

        if (monthlyOrMonthlyContractSet.contains(chargeTermValue)) {
            result += ((displayQuantityValue * effectivePriceValue) * 12);
        } else {
            result += (displayQuantityValue * effectivePriceValue);
        }

        return result;
    }

    public static Decimal computeNGBSEntitlementTotalMRR(QuoteLineItem qli) {
        Decimal result = 0;

        Decimal displayQuantityValue = (Decimal) getRelatedData(qli.QuoteRecordType__c, qli, Entitlement__c.DisplayQuantity__c);
        Decimal effectivePriceValue = (Decimal) getRelatedData(qli.QuoteRecordType__c, qli, Entitlement__c.EffectivePrice__c);
        String chargeTermValue = (String) getRelatedData(qli.QuoteRecordType__c, qli, Product2.Charge_Term__c);

        if (chargeTermValue == Product2Helper.CHARGE_TERM_ANNUAL) {
            result += ((displayQuantityValue * effectivePriceValue) / 12);
        } else {
            result += (displayQuantityValue * effectivePriceValue);
        }

        return result;
    }

    public static Quote populateNGBSEntitlementTotals(Quote quote) {
        QuoteLineItem[] qliList = [
            SELECT Id, PackageInfo__c, QuoteRecordType__c,
                   Entitlement__r.ChargeTerm__c,
                   Entitlement__r.DisplayQuantity__c,
                   Entitlement__r.EffectivePrice__c,
                   Package_Info__c, Package_Info_QLI__c
            FROM QuoteLineItem
            WHERE QuoteId = :quote.Id
        ];

        Decimal calculatedEntlTotalArr = 0;
        Decimal calculatedEntlTotalMrr = 0;

        if(quote.Upsell_Status__c == QuoteHelper.STATUS_NEW_CUSTOMER) {
            // for NewCustomer quotes entitlement totals always should be 0
            quote.Entitlement_Total_ARR__c = 0;
            quote.Entitlement_Total_MRR__c = 0;

            return quote;
        }

        for(QuoteLineItem qli : qliList) {

            if (qli.Entitlement__c == null) { continue; }

            Decimal displayQuantityValue = qli.Entitlement__r.DisplayQuantity__c;
            Decimal effectivePriceValue = qli.Entitlement__r.EffectivePrice__c;
            String chargeTermValue = qli.Entitlement__r.ChargeTerm__c;

            if (chargeTermValue == Product2Helper.CHARGE_TERM_ANNUAL) {
                calculatedEntlTotalMrr += ((displayQuantityValue * effectivePriceValue) / 12);
            } else{
                calculatedEntlTotalMrr += (displayQuantityValue * effectivePriceValue);
            }

            if (monthlyOrMonthlyContractSet.contains(chargeTermValue)) {
                calculatedEntlTotalArr += ((displayQuantityValue * effectivePriceValue) * 12);
            } else{
                calculatedEntlTotalArr += (displayQuantityValue * effectivePriceValue);
            }
        }

        quote.Entitlement_Total_ARR__c = calculatedEntlTotalArr;
        quote.Entitlement_Total_MRR__c = calculatedEntlTotalMrr;

        return quote;
    }

    class RequiredParameterMissingException extends Exception {}
    class UnsupportedSobjectTypeException extends Exception {}

    private static Map<String, Schema.SObjectType> supportedSobjectTypesMap = new Map<String, Schema.SObjectType>{
        QuoteLineItem.getSobjectType().getDescribe().getName() => QuoteLineItem.getSobjectType(),
        Entitlement__c.getSobjectType().getDescribe().getName() => Entitlement__c.getSobjectType()
    };
    // method return entitlement`s data depending on the quote record type / obj type and field type
    // quoteRecordTypeName value identify in the Quote is new wizard quote or old wizard quote
    // obj variuants: QuoteLineItem OR Entitlement__c. When obj is QuoteLineItem, data returned from QuoteLineItem Entitlement
    // field variants: Product2.Charge_Term__c (product change term returned) / Entitlement__c.DisplayQuantity__c / Entitlement__c.EffectivePrice__c / Entitlement__c.Price__c
    public static Object getRelatedData(String quoteRecordTypeName, SObject obj, Schema.SObjectField field) {

        Object result = null;

        if(obj == null) {
            throw new RequiredParameterMissingException('required parameter "obj" is null.');
        }

        if(field == null) {
            throw new RequiredParameterMissingException('required parameter "field" is null.');
        }

        if(!supportedSobjectTypesMap.values().contains(obj.getSObjectType())) {
            String errorMessage = 'Current SObject type not supported: ' + obj.getSObjectType()
                                + '. Supported sobject types: ['
                                    + String.join(new List<String>(supportedSobjectTypesMap.keySet()), ', ')
                                + ']';

            throw new UnsupportedSobjectTypeException(errorMessage);
        }

        if (quoteRecordTypeName == null) {
            quoteRecordTypeName = QuoteHelper.RT_NAME_SALES;
        }
        Id quoteRtId = QuoteHelper.RT_INFO_BY_NAME.get(quoteRecordTypeName).getRecordTypeId();

        if (quoteRtId != QuoteHelper.RT_ID_BILLING) {

            // get data for sales/proserv/ccproserv quotes(data will be retrieved from entitlements)
            if (field == Entitlement__c.DisplayQuantity__c) {

                switch on (SObject) obj {
                    when QuoteLineItem qli {
                        result = (qli.Entitlement__c == null || qli.Entitlement__r.DisplayQuantity__c == null)
                                    ? 0
                                    : qli.Entitlement__r.DisplayQuantity__c;
                    }
                    when Entitlement__c entl {
                        result = (entl.DisplayQuantity__c == null) ? 0 : entl.DisplayQuantity__c;
                    }
                    when else {
                        String errorMessage = 'Current SObject type not supported: ' + obj.getSObjectType() +
                            '. Supported sobject types: [' +
                            String.join(new List<String>(supportedSobjectTypesMap.keySet()), ', ') + ']';

                        throw new UnsupportedSobjectTypeException(errorMessage);
                    }
                }

            } else if (field == Product2.Charge_Term__c) {

                switch on (SObject) obj {
                    when QuoteLineItem qli {
                        String qliChargeTerm = QuoteLineItemHelper.getChargeTerm(qli);

                        result = (qli.Entitlement__c == null || qli.Entitlement__r.Product__c == null
                                    || qli.Entitlement__r.Product__r.Charge_Term__c == null)
                                ? qliChargeTerm
                                : qli.Entitlement__r.Product__r.Charge_Term__c;
                    }
                    when Entitlement__c entl {
                        result = (entl.Product__c == null || entl.Product__r.Charge_Term__c == null)
                                ? ''
                                : entl.Product__r.Charge_Term__c;
                    }
                    when else {
                        String errorMessage = 'Current SObject type not supported: ' + obj.getSObjectType() +
                            '. Supported sobject types: [' +
                            String.join(new List<String>(supportedSobjectTypesMap.keySet()), ', ') + ']';

                        throw new UnsupportedSobjectTypeException(errorMessage);
                    }
                }

            } else if (field == Entitlement__c.EffectivePrice__c) {

                switch on (SObject) obj {
                    when QuoteLineItem qli {
                        result = (qli.Entitlement__c == null || qli.Entitlement__r.EffectivePrice__c == null)
                                ? 0
                                : qli.Entitlement__r.EffectivePrice__c;
                    }
                    when Entitlement__c entl {
                        result = (entl.EffectivePrice__c == null) ? 0 : entl.EffectivePrice__c;
                    }
                    when else {
                        String errorMessage = 'Current SObject type not supported: ' + obj.getSObjectType() +
                            '. Supported sobject types: [' +
                            String.join(new List<String>(supportedSobjectTypesMap.keySet()), ', ') + ']';

                        throw new UnsupportedSobjectTypeException(errorMessage);
                    }
                }

            } else if (field == Entitlement__c.Price__c) {

                switch on (SObject) obj {
                    when QuoteLineItem qli {
                        result = (qli.Entitlement__c == null || qli.Entitlement__r.Price__c == null)
                                ? 0
                                : qli.Entitlement__r.Price__c;
                    }
                    when Entitlement__c entl {
                        result = (entl.Price__c == null) ? 0 : entl.Price__c;
                    }
                    when else {
                        String errorMessage = 'Current SObject type not supported: ' + obj.getSObjectType() +
                            '. Supported sobject types: [' +
                            String.join(new List<String>(supportedSobjectTypesMap.keySet()), ', ') + ']';

                        throw new UnsupportedSobjectTypeException(errorMessage);
                    }
                }
            }

        } else {

            switch on (SObject) obj {
                when QuoteLineItem qli {
                    if (field == Entitlement__c.DisplayQuantity__c) {
                        result = (qli.Entitlement__c == null || qli.Entitlement__r.DisplayQuantity__c == null)
                                    ? 0
                                    : qli.Entitlement__r.DisplayQuantity__c;
                    } else if (field == Product2.Charge_Term__c) {
                        result = (qli.Entitlement__c == null || qli.Entitlement__r.ChargeTerm__c == null)
                                    ? ''
                                    : qli.Entitlement__r.ChargeTerm__c;
                    } else if (field == Entitlement__c.EffectivePrice__c) {
                        result = (qli.Entitlement__c == null || qli.Entitlement__r.EffectivePrice__c == null)
                                    ? 0
                                    : qli.Entitlement__r.EffectivePrice__c;
                    } else if (field == Entitlement__c.Price__c) {
                        result = (qli.Entitlement__c == null || qli.Entitlement__r.Price__c == null)
                                    ? 0
                                    : qli.Entitlement__r.Price__c;
                    }
                } when Entitlement__c entl {
                    if (field == Entitlement__c.DisplayQuantity__c) {
                        result = (entl.DisplayQuantity__c == null) ? 0 : entl.DisplayQuantity__c;
                    } else if (field == Entitlement__c.EffectivePrice__c) {
                        result = (entl.EffectivePrice__c == null) ? 0 : entl.EffectivePrice__c;
                    }
                }
            }

        }

        return result;
    }

    private static Boolean isEntitlementMatchingWithQuote(Quote qt, Entitlement__c entl) {
        if (qt == null || entl == null) {
            return false;
        }
        if (!QuoteHelper.NGBS_QUOTES_RT_IDS.contains(qt.RecordTypeId)) {
            return true;
        }
        return (
                    QuoteHelper.isNewBillingQuote(qt) &&
                    entl.Quote__r != null &&
                    QuoteHelper.isNewBillingQuote(entl.Quote__r) &&
                    entl.Quote__r.Id == qt.Id
                )
            ||
                (
                    QuoteHelper.isCCQuote(qt) &&
                    entl.Product__r.Sub_Category__c == Product2Helper.SUBCATEGORY_CONTACT_CENTER
                );
    }
    @TestVisible
    private static List<QuoteLineItem> filterOutUsages(List<QuoteLineItem> qlis) {
        List<QuoteLineItem> filteredQlisList = new List<QuoteLineItem>();

        for (QuoteLineItem qli : qlis) {
          if (!QuoteLineItemHelper.isUsageLicense(qli)) {
              filteredQlisList.add(qli);
          }
        }
        return filteredQlisList;
    }
}