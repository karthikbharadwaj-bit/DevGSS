public with sharing class OpportunityTotals {

    public static Boolean bypassOpportnuityUpdate = false;
    public static Boolean bypassTriggers = false;

    public class OpportunityTotalsOnQuoteChange extends Triggers.TriggerHandlerBase {
        override public void handle() {

            if(bypassOpportnuityUpdate ) {
                return;
            }

            List<Quote> quotesList = (List<Quote>) (!Trigger.isDelete ? Trigger.new : Trigger.old);

            Set<Id> oppIdSet = new Set<Id>();
            Set<Id> deletedQuotesIdSet = new Set<Id>();

            for(Quote qt : quotesList) {
                if(isChangedAnyField(qt, QuoteHelper.QUOTE_TOTALS_FIELDS)) {
                    oppIdSet.add(qt.OpportunityId);
                }

                if(Trigger.isDelete) {
                    deletedQuotesIdSet.add(qt.Id);
                }
            }

            OpportunityTotals oppTotals = new OpportunityTotals();
            List<Opportunity> updatedOppsList = oppTotals.populateTotals(oppIdSet, deletedQuotesIdSet);
            OpportunityTriggerHelperRefactored.skipForecastValidations = true;

            if (bypassTriggers || OpportunityTriggerHelperRefactored.isChangeOrderFlow) {
                Triggers.switchOff();
            }
            update updatedOppsList;
            if (bypassTriggers || OpportunityTriggerHelperRefactored.isChangeOrderFlow) {
                Triggers.switchOn();
            }
        }
    }

    public List<Opportunity> populateTotals(Set<Id> oppIdSet, Set<Id> deletedQuotesIdSet) {

        if(oppIdSet == null || oppIdSet.isEmpty()) {
            return new List<Opportunity>();
        }

        List<Opportunity> oppList = [SELECT
                Id, Actual_Estimated_CC_12M_Bookings__c, Total_MRR__c,
                X12_Month_Booking__c, EstimatedProfessionalServices12Month__c,
                CommissionableEstimated12MonthBooking__c, Deductible_Refunds_Penalty__c,
                Contact_Center_MRR__c, Initial_Contract_Term__c, Estimated_Hardware__c,
                Amount, Total_Initial_Amount__c, Total_Contract_Value__c,
                Is_Billing_Opportunity__c, OwnerId, Owner.Division, StageName,
                Forecast_Connect_First_Users__c, ForcastedDimeloUsers__c, Tier_Name__c,
                IsMultiProductTechnicalOpportunity__c, MasterOpportunity__c,
                    (SELECT
                        Id, isPrimary__c, LastModifiedDate, First_Year_Cost_of_Service__c,
                        Contact_Center_Entitlement_Total_ARR__c, Contact_Center_Total_ARR__c,
                        Opportunity.EstimatedProfessionalServices12Month__c, Contact_Center_Entitlement_Total_MRR__c,
                        RecordTypeId, Total_First_Year_Cost__c, Payment_Plan__c,
                        Contact_Center_Total_First_Year_Cost__c,
                        Total_MRR_New__c, Contact_Center_Total_MRR__c,
                        Pricebook2.Plan__c, Initial_Term_months__c,
                        Special_Terms__c, Credit_Amount__c, ProServ_Status__c,
                        Total_One_Time__c, Total_ARR__c, Estimated_Hardware__c, Upsell_Status__c,
                        IsMultiProductTechnicalQuote__c, MasterQuote__c, OpportunityId
                    FROM Quotes
                    WHERE Id NOT IN :deletedQuotesIdSet)
            FROM Opportunity
            WHERE Id IN :oppIdSet];

        List<Opportunity> updatedOppList = new List<Opportunity>();
        Id masterOppId = null;
        Quote masterQuote = null;
        for (Opportunity opp : oppList) {
           if (!opp.IsMultiProductTechnicalOpportunity__c && opp.MasterOpportunity__c == null) {
                masterOppId = opp.Id;
                for (Quote quote : opp.Quotes) {
                    if (quote.isPrimary__c && !quote.IsMultiProductTechnicalQuote__c && quote.MasterQuote__c == null && quote.OpportunityId == masterOppId) {
                        masterQuote = quote;
                    }
                }
            }
        }

        for (Opportunity opp : oppList) {
            if (UserInfo.getName() != 'DocuSign Integration') {
                Opportunity updatedOpp = populateTotalsForOpportunity(opp, opp.Quotes, masterOppId, masterQuote);
                if(updatedOpp != null) {
                    updatedOppList.add(updatedOpp);
                }
            }
        }

        return updatedOppList;
    }

    public Opportunity populateTotalsForOpportunity(Opportunity opp, List<Quote> quotes, Id masterOppId, Quote masterQuote) {

        if(opp == null) {
            return null;
        }

        if(quotes == null) {
            quotes = new List<Quote>();
        }

        List<Quote> filteredQuotesList = new List<Quote>();
        for(Quote qt : quotes) {
            Boolean isCancelledCCOrProservQuote = qt.ProServ_Status__c == QuoteHelper.PROSERVSTATUS_CANCELLED &&
                (qt.RecordTypeId == QuoteHelper.RT_ID_PROSERV || qt.RecordTypeId == QuoteHelper.RT_ID_CC_PROSERV);

            if(isCancelledCCOrProservQuote) {
                continue;
            }
            filteredQuotesList.add(qt);
        }

        // X12_Month_Booking__c
        Decimal estimated12MBookingsValue = computeEstimated12MBookings(filteredQuotesList, opp.Is_Billing_Opportunity__c);

        // EstimatedProfessionalServices12Month__c
        Decimal estimatedProServicesAmountValue = computeEstimatedProServicesAmount(filteredQuotesList);

        // Actual_Estimated_CC_12M_Bookings__c
        Decimal estimatedCCBookingsValue = computeEstimatedCCBookings(opp.Is_Billing_Opportunity__c, filteredQuotesList);

        // Estimated_Hardware__c
        Decimal estimatedHardwareValue = computeEstimatedHardware(opp.Is_Billing_Opportunity__c, filteredQuotesList);

        // Deductible_Refunds_Penalty__c
        Decimal deductibleRefundsValue = computeDeductibleRefunds(opp.Is_Billing_Opportunity__c, filteredQuotesList);

        // CommissionableEstimated12MonthBooking__c
        Decimal estimated12MCommisionableBookingsValue = computeEstimated12MCommissionableBookings(
            opp.Is_Billing_Opportunity__c,
            filteredQuotesList,
            estimatedHardwareValue,
            estimatedProServicesAmountValue,
            deductibleRefundsValue
        );

        // Total_MRR__c
        Decimal totalMRRValue = computeTotalMRR(opp.Is_Billing_Opportunity__c, filteredQuotesList);

        // Contact_Center_MRR__c
        Decimal cCMRRValue = computeCCMRR(opp.Is_Billing_Opportunity__c, filteredQuotesList);

        // Initial_Contract_Term__c
        Integer initialContractTermValue = computeInitialContractTerm(opp.Is_Billing_Opportunity__c, filteredQuotesList, masterOppId, masterQuote);

        // Total_Initial_Amount__c
        Decimal totalInitialAmountValue = computeTotalInitialAmount(opp.Is_Billing_Opportunity__c, filteredQuotesList);

        // Total_Contract_Value__c
        Decimal totalContractValue = computeTotalContractValue(opp.Is_Billing_Opportunity__c, filteredQuotesList);
        Map<String, Decimal> fieldsToCheck = new Map<String, Decimal> {
            'EstimatedProfessionalServices12Month__c' => estimatedProServicesAmountValue,
            'Actual_Estimated_CC_12M_Bookings__c' => estimatedCCBookingsValue,
            'Total_MRR__c' => totalMRRValue,
            'Deductible_Refunds_Penalty__c' => deductibleRefundsValue,
            'Contact_Center_MRR__c' => cCMRRValue,
            'Initial_Contract_Term__c' => initialContractTermValue,
            'CommissionableEstimated12MonthBooking__c' => estimated12MCommisionableBookingsValue,
            'Total_Initial_Amount__c' => totalInitialAmountValue,
            'Total_Contract_Value__c' => totalContractValue
        };

        if (!IsCallerOrOwnerSalesEnterpriseUser(opp)) {
            fieldsToCheck.put('X12_Month_Booking__c', estimated12MBookingsValue);
        }

        Boolean isTotalsChanged = false;
        Opportunity updatedOpp = new Opportunity(Id = opp.Id);
        Set<String> changedFields = new Set<String>();

        for (String field : fieldsToCheck.keySet()) {
            isTotalsChanged = isTotalsChanged || (opp.get(field) != fieldsToCheck.get(field));
            if (isTotalsChanged) {
                changedFields.add(field);
            }
        }

        if(!isTotalsChanged) {
            return null;
        }

        for (String field : fieldsToCheck.keySet()) {
            if (fieldsToCheck.get(field) != opp.get(field)) {
                updatedOpp.put(field, fieldsToCheck.get(field));
            }
        }

        return updatedOpp;
    }

    private Boolean IsCallerOrOwnerSalesEnterpriseUser(Opportunity opty) {
        return (
            OpportunityTriggerHelperRefactored.IsCurrentUserFromSalesEnterpriseDivision()
            ||
            OpportunityTriggerHelperRefactored.IsOpportunityOwnerFromSalesEnterpriseDivison(opty)
        );
    }

    @TestVisible
    private Decimal computeEstimated12MBookings(List<Quote> quotes, Boolean isNewBillingOpportunity) {
        /*
        1.  This field should be populated with Sum of values in
            Total First Year Cost field on Primary Sales Quote and
            Total First Year Cost fields on Quotes with Record Types 'ProServ Quote' and 'CC ProServ Quote'.
        2.  For Change Order it is populated only with
            Total First Year Cost fields on Quotes with Record Types 'ProServ Quote' and 'CC ProServ Quote'.
        */

        Decimal result = 0;

        if(quotes == null || quotes.isEmpty()) {
            return result;
        }

        Quote primaryQuote = getPrimaryQuoteIfExists(quotes, isNewBillingOpportunity);
        Quote CCQuote = QuoteHelper.getCCQuote(quotes);

        Decimal primaryQuoteTotalFirstYearCostValue = primaryQuote == null || primaryQuote.Total_First_Year_Cost__c == null ? 0 : primaryQuote.Total_First_Year_Cost__c;
        Decimal CCQuoteTotalFirstYearCostValue = CCQuote == null || CCQuote.Total_First_Year_Cost__c == null ? 0 : CCQuote.Total_First_Year_Cost__c;

        result = computeEstimatedProServicesAmount(quotes);

        if(primaryQuote != null && !QuoteHelper.isChangeOrderQuote(primaryQuote, null)) {
            result += primaryQuoteTotalFirstYearCostValue + CCQuoteTotalFirstYearCostValue;
        }

        return result;
    }

    @TestVisible
    private Decimal computeEstimated12MCommissionableBookings(Boolean isBillingOpportunity,
                                                                List<Quote> quotes,
                                                                Decimal estimatedHardware,
                                                                Decimal estimatedProServAmount,
                                                                Decimal deductibleRefunds) {
        /*
        2.1. This field should be populated using following formula:
        Primary Quote Total ARR + Estimated Hardware * 0.5 + Estimated Pro Services Amount * 0.5
        */
        /*
        B-6226 Formula is changed to:
        Primary Quote Total ARR + Estimated Hardware * 0.5 + Estimated Pro Services Amount * 0.5 - Deductible Service Credit (Penalty)
        */

        /*
        Case 10329252 For NGBS opp formula is changed to:
        Primary Quote Total ARR + CC Quote Total ARR + Estimated Hardware * 0.5 + Estimated Pro Services Amount * 0.5 - Deductible Service Credit (Penalty)
        */

        Quote primaryQuote = getPrimaryQuoteIfExists(quotes, isBillingOpportunity);

        if(primaryQuote == null) {
            // cannot find primary quote
            return 0;
        }

        Decimal totalArrValue = primaryQuote.Total_ARR__c == null ? 0 : primaryQuote.Total_ARR__c;

        Decimal estimatedHardwareValue = estimatedHardware == null ? 0 : estimatedHardware;
        Decimal estimatedProServAmountValue = estimatedProServAmount == null ? 0 : estimatedProServAmount;
        Decimal deductibleRefundsValue = deductibleRefunds == null ? 0 : deductibleRefunds;
        Decimal ccTotalArrValue = 0;

        if (isBillingOpportunity && quotes != null && !quotes.isEmpty()) {
            Quote ccQuote = QuoteHelper.getCCQuote(quotes);
            ccTotalArrValue = ccQuote == null ? 0 :
                ccQuote.Contact_Center_Total_ARR__c == null ? 0 : ccQuote.Contact_Center_Total_ARR__c;
        }

        return totalArrValue + ccTotalArrValue + (estimatedHardwareValue * 0.5)
            + (estimatedProServAmountValue * 0.5) - deductibleRefundsValue;
    }

    @TestVisible
    private Decimal computeEstimatedProServicesAmount(List<Quote> quotes) {
        // 3.1. This field should be populated with Sum of values
            // in Total First Year Cost field on Quotes with Record Types 'ProServ Quote' and 'CC ProServ Quote'.

        Decimal result = 0;

        if(quotes == null || quotes.isEmpty()) {
            return result;
        }

        for(Quote qt : quotes) {

            Boolean isCCOrProServQuote = qt.RecordTypeId == QuoteHelper.RT_ID_PROSERV ||
                qt.RecordTypeId == QuoteHelper.RT_ID_CC_PROSERV;

            if(isCCOrProServQuote && qt.ProServ_Status__c != QuoteHelper.PROSERVSTATUS_CANCELLED) {
                Decimal totalFirstYearCostValue = qt.Total_First_Year_Cost__c == null ? 0 : qt.Total_First_Year_Cost__c;
                result += totalFirstYearCostValue;
            }
        }

        return result;
    }

    @TestVisible
    private Decimal computeEstimatedCCBookings(Boolean isBillingOpportunity, List<Quote> quotes) {
        // 4.1. Value for this field should be taken from Primary Sales Quote.Contact Center Total First Year Cost field.

        Quote quoteToGetTotals;
        if (isBillingOpportunity) {
            quoteToGetTotals = QuoteHelper.getCCQuote(quotes);
        } else {
            quoteToGetTotals = getPrimaryQuoteIfExists(quotes, isBillingOpportunity);
        }
        return quoteToGetTotals == null
                ? 0
                : quoteToGetTotals.Contact_Center_Total_First_Year_Cost__c;
    }

    @TestVisible
    private Decimal computeEstimatedHardware(Boolean isBillingOpportunity, List<Quote> quotes) {
        // 5.3. Value for the Estimated Hardware field on Opportunity object should be taken from Estimated Hardware field on the Primary Quote.

        Quote primaryQuote = getPrimaryQuoteIfExists(quotes, isBillingOpportunity);
        return primaryQuote == null
                ? 0
                : primaryQuote.Estimated_Hardware__c;
    }

    @TestVisible
    private Decimal computeDeductibleRefunds(Boolean isBillingOpportunity, List<Quote> quotes) {
        /*
        6.2. It should be populated using following logic:
        - If Primary Sales Quote has 1 month free service: Deductible Refunds (Penalty) = Primary Quote.Credit_Amount__c * 12 / 52 * 4
        - If Primary Sales Quote has 2 months free service: Deductible Refunds (Penalty) = Primary Quote.Credit_Amount__c / 2 * 12 / 52 * 5
        - If Primary Sales Quote has 3 months free service: Deductible Refunds (Penalty) = Primary Quote.Credit_Amount__c / 3 * 12 / 52 * 6
        */

        Decimal result = 0;

        Quote primaryQuote = getPrimaryQuoteIfExists(quotes, isBillingOpportunity);

        if(primaryQuote == null) {
            // cannot find primary quote
            return result;
        }

        Decimal creditAmount = primaryQuote.Credit_Amount__c == null ? 0 : primaryQuote.Credit_Amount__c;

        if(primaryQuote.Special_Terms__c == QuoteHelper.FREE_MONTH_1) {
           result = (creditAmount);
       }else if(primaryQuote.Special_Terms__c == QuoteHelper.FREE_MONTH_2) {
           result = (creditAmount * 0.625);
       }else if(primaryQuote.Special_Terms__c == QuoteHelper.FREE_MONTH_3) {
           result = (creditAmount * 0.5) ;
       }else if(primaryQuote.Special_Terms__c == QuoteHelper.FREE_MONTH_4) {
           result = (creditAmount / 4 * 3 * 0.5) + (creditAmount / 4 );
       }else if(primaryQuote.Special_Terms__c == QuoteHelper.FREE_MONTH_5) {
           result = (creditAmount / 5 * 3 * 0.5) + (creditAmount / 5 * 2);
       }else if(primaryQuote.Special_Terms__c == QuoteHelper.FREE_MONTH_6) {
           result = (creditAmount / 6 * 3 * 0.5) + (creditAmount / 6 * 3);
       }

        return result;
    }

    @TestVisible
    private Decimal computeTotalMRR(Boolean isBillingOpportunity, List<Quote> quotes) {
        // 7.1. Value for this field should be taken from Primary Sales Quote.Total MRR field.

        Quote primaryQuote = getPrimaryQuoteIfExists(quotes, isBillingOpportunity);
        Decimal totalPrimaryMRRValue = primaryQuote == null || primaryQuote.Total_MRR_New__c == null
                                        ? 0
                                        : primaryQuote.Total_MRR_New__c;
        Decimal cCMRRValue = computeCCMRR(isBillingOpportunity, quotes);
        return totalPrimaryMRRValue + cCMRRValue;
    }

    public static void computeTotalFeesMRR(List<Opportunity> opps, Map<Id, List<Quote>> quotesByOppId) {
        // Value for this field should be taken as summ of Fees products on Primary quote.
        for (Opportunity opp : opps) {
            Quote primaryQuote = getPrimaryQuoteIfExists(quotesByOppId.get(opp.Id), opp.Is_Billing_Opportunity__c);
            if (primaryQuote == null
                || primaryQuote.RecordTypeId != QuoteHelper.RT_ID_BILLING) {
                continue;
            }
            Decimal totalFeesMRRValue = 0;
            for (QuoteLineItem item : primaryQuote.QuoteLineItems) {
                if (Product2Helper.FEES_PRODUCTS_EXT_IDS.contains(item.Product2.ExtID__c)) {
                    System.debug('####### item.Delta_MRR__c = ' + item.Delta_MRR__c);
                    totalFeesMRRValue += NumberHelper.roundCurrency(item.Delta_MRR__c);
                }
            }
            opp.Total_Fees_MRR__c = totalFeesMRRValue;
        }
    }


    @TestVisible
    private Decimal computeCCMRR(Boolean isBillingOpportunity, List<Quote> quotes) {
        // 8.2. Value for this field should be taken from Primary Sales Quote.Contact Center Total MRR field.
        Quote quoteToGetTotals;
        if (isBillingOpportunity) {
            quoteToGetTotals = QuoteHelper.getCCQuote(quotes);
        } else {
            quoteToGetTotals = getPrimaryQuoteIfExists(quotes, isBillingOpportunity);
        }

        return quoteToGetTotals == null
                ? 0
                : quoteToGetTotals.Contact_Center_Total_MRR__c == null
                    ? 0
                    : quoteToGetTotals.Contact_Center_Total_MRR__c;
    }

    @TestVisible
    private Integer computeInitialContractTerm(Boolean isBillingOpportunity, List<Quote> quotes, Id masterOppId, Quote masterQuote) {
        /*
        9.2. It should be populated with value from Initial Term (months) field on the Primary Quote if Primary Quote.Pricebook.Plan != 'Monthly'.
        9.1. It should be populated with 1 if Primary Quote.Pricebook.Plan == 'Monthly'.
        */

        Integer result = null;

        Quote primaryQuote = getPrimaryQuoteIfExists(quotes, isBillingOpportunity);

        if(primaryQuote == null) {
            // cannot find primary quote
            return result;
        }
        if (masterOppId != null && masterQuote != null && primaryQuote.OpportunityId != masterOppId) {
            primaryQuote = masterQuote;
        }

        if(primaryQuote.Payment_Plan__c == Pricebook2Helper.PLAN_MONTHLY) {
            result = 1;
        }else{
            if(primaryQuote.Initial_Term_months__c != null) {
                if(primaryQuote.Initial_Term_months__c.isNumeric()) {
                    result = Integer.valueOf(primaryQuote.Initial_Term_months__c);
                }else if(primaryQuote.Initial_Term_months__c.isNumericSpace()) {
                    result = Integer.valueOf(primaryQuote.Initial_Term_months__c.trim());
                }
            }
        }

        return result;
    }

    @TestVisible
    private Decimal computeTotalInitialAmount(Boolean isBillingOpportunity, List<Quote> quotes) {

        Quote primaryQuote = getPrimaryQuoteIfExists(quotes, isBillingOpportunity);
        return primaryQuote == null
                ? 0
                : primaryQuote.Total_First_Year_Cost__c;
    }

    @TestVisible
    private Decimal computeTotalContractValue(Boolean isBillingOpportunity, List<Quote> quotes) {

        Decimal result = 0;

        Quote primaryQuote = getPrimaryQuoteIfExists(quotes, isBillingOpportunity);

        if(primaryQuote == null) {
            // cannot find primary quote
            return result;
        }

        Quote ccQuote = QuoteHelper.getCCQuote(quotes);
        Decimal ccTotalResult = 0;
        if (isBillingOpportunity && ccQuote != null) {
            if(!String.isBlank(primaryQuote.Initial_Term_months__c)) {
                if(Integer.valueOf(primaryQuote.Initial_Term_months__c) == 12) {
                    ccTotalResult = (Decimal) NumberHelper.getNumberNullSafe(
                                    ccQuote.Contact_Center_Total_First_Year_Cost__c);
                } else if(Integer.valueOf(primaryQuote.Initial_Term_months__c) > 12) {
                    ccTotalResult = (Decimal) NumberHelper.getNumberNullSafe(
                                    ccQuote.Contact_Center_Total_First_Year_Cost__c)
                                    + ((Decimal) NumberHelper.getNumberNullSafe(
                                        ccQuote.Contact_Center_Total_MRR__c)
                                    * (Integer.valueOf(primaryQuote.Initial_Term_months__c) - 12));
                }
            }
        }

        if(!String.isBlank(primaryQuote.Initial_Term_months__c)) {
            if(Integer.valueOf(primaryQuote.Initial_Term_months__c) == 12) {
                result = (Decimal) NumberHelper.getNumberNullSafe(primaryQuote.Total_First_Year_Cost__c)
                            + (Decimal) NumberHelper.getNumberNullSafe(
                                primaryQuote.Opportunity.EstimatedProfessionalServices12Month__c
                            ) + ccTotalResult;

            } else if(Integer.valueOf(primaryQuote.Initial_Term_months__c) > 12) {
                result = (Decimal) NumberHelper.getNumberNullSafe(primaryQuote.Total_First_Year_Cost__c)
                            + ((Decimal) NumberHelper.getNumberNullSafe(primaryQuote.Total_MRR_New__c)
                            * (Integer.valueOf(primaryQuote.Initial_Term_months__c) - 12))
                            + (Decimal) NumberHelper.getNumberNullSafe(
                                primaryQuote.Opportunity.EstimatedProfessionalServices12Month__c
                            ) + ccTotalResult;
            }
        }

        return result;
    }

    public static Quote getPrimaryQuoteIfExists(List<Quote> quotes) {
        return getPrimaryQuoteIfExists(quotes, false);
    }

    public static Quote getPrimaryQuoteIfExists(List<Quote> quotes, Boolean isNewBilling) {
        if(quotes == null || quotes.isEmpty()) {
            return null;
        }

        if(isNewBilling == null) {
            isNewBilling = false;
        }

        Quote primaryQuote = QuoteHelper.getPrimaryQuote(quotes, isNewBilling);
        if(primaryQuote == null) {
            // if primary quote not found - try to find it with "Sales Quote v2" recordType
            isNewBilling = !isNewBilling;
            primaryQuote = QuoteHelper.getPrimaryQuote(quotes, isNewBilling);
        }

        return primaryQuote;
    }
}