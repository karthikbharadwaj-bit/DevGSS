public with sharing class QuoteApprovals {

    public static Map<Id, Id> quoteIdToOpportunityOwnerIdStaticMap = new Map<Id, Id>();

    public static final String PERCENTAGE_GOA_CURRENCY = QuoteLineItemHelper.DISCOUNT_TYPE_PERCENTAGE;

    public static Boolean IS_NEED_RECALCULATE_MAIN_QUOTE_APPROVALS = false;

    public static final Set<Id> RT_IDS_DONT_RECALCULATE_APPROVER_LEVELS = new Set<Id>{
        ApprovalHelper.RT_ID_UPDATE_CONTRACT_STATUS
    };

    public static final string GOA_SEGMENT_POPULATED = 'Has segment';
    public static final string GOA_SEGMENT_NOT_POPULATED = 'No segment';

    public static final string CC_FSC_APPROVERS_QUEUE_NAME = 'Finance Approval Queue';

    public static final string ENGAGE_FSC_APPROVERS_QUEUE_NAME = 'Finance Deal Review';

    public static final String NEW_ORDER = OrderHelper.TYPE_NEW_ORDER;
    public static final String CHANGE_ORDER = 'Change Order';

    private static Map<Id, Integer> qliGoaStatic = new Map<Id, Integer>();

    public static List<QuoteLineItem> qliList = new List<QuoteLineItem>();

    public static Quote primaryQuote = new Quote();

    // inner class for hold Billing quotes data
    private class BillingOppData {
        public Id opportunityId;
        public Map<Quote, List<QuoteLineItem>> salesQuoteMap;
        public Map<Quote, List<QuoteLineItem>> contactCenterQuoteMap;

        public BillingOppData(Id oppId, Map<Quote, List<QuoteLineItem>> salesQuote, Map<Quote, List<QuoteLineItem>> contactCenterQuote) {
            this.opportunityId = oppId;
            this.salesQuoteMap = salesQuote;
            this.contactCenterQuoteMap = contactCenterQuote;
        }

        public Map<Id, List<QuoteLineItem>> makeBillingMap() {

            // map where Id Quote with RecordType SalesQuoteV2 => List<QuoteLineItem> from currentQuote + QuoteLineItem from ContactCenter quote
            Map<Id, List<QuoteLineItem>> billingMap = new Map<Id, List<QuoteLineItem>>();

            Quote primarySalesQuoteV2 = QuoteHelper.getPrimaryQuote(new List<Quote>(this.salesQuoteMap.keySet()), true);
            primaryQuote = primarySalesQuoteV2;

            List<QuoteLineItem> mergedQliList = new List<QuoteLineItem>();

            for (Quote salesQuoteV2 : this.salesQuoteMap.keySet()) {
                mergedQliList.addAll(this.salesQuoteMap.get(salesQuoteV2));
            }

            for (Quote contactCenterQuote : this.contactCenterQuoteMap.keySet()) {
                mergedQliList.addAll(this.contactCenterQuoteMap.get(contactCenterQuote));
            }

            if (primarySalesQuoteV2 != null) {
                billingMap.put(primarySalesQuoteV2.Id, mergedQliList);
            }

            return billingMap;
        }

        public Set<Quote> getContactCenterQuotesBySalesQuoteV2Id(Id salesQuoteV2Id) {

            if (salesQuoteV2Id == null) {
                return null;
            }

            Set<Id> salesQuoteIdSet = new Set<Id>();
            for (Quote qt : this.salesQuoteMap.keySet()) {
                salesQuoteIdSet.add(qt.Id);
            }

            if (salesQuoteIdSet.contains(salesQuoteV2Id)) {
                return this.contactCenterQuoteMap.keySet();
            } else {
                return null;
            }
        }
    }

    private static String getOrderType(Id quoteId) {
        Quote currentQuote = [SELECT Account.RC_User_ID__c, Account.RC_Account_Status__c FROM Quote WHERE id = :quoteId];
        Boolean hasAccount = String.isNotBlank(currentQuote.Account.RC_User_ID__c);
        Boolean isFree = String.isNotBlank(currentQuote.Account.RC_Account_Status__c) && currentQuote.Account.RC_Account_Status__c.containsIgnoreCase('trial');
        return hasAccount && !isFree ? CHANGE_ORDER : NEW_ORDER;
    }

    public static List<Quote> handleBillingQuotes(Set<Id> oppIdSet, Set<Id> qliToDeleteIdSet) {
        if (oppIdSet == null || oppIdSet.size() == 0) {
            return new List<Quote>();
        }

        Id rtIdBilling = QuoteHelper.RT_ID_BILLING;
        Id rtIdCC = QuoteHelper.RT_ID_CC;

        qliList = (List<QuoteLineItem>) new QuoteLineItemSelector()
            .selectQuoteLineItemsForHandleBillingQuotes(oppIdSet, qliToDeleteIdSet)
            .executeQuery();

        Map<Id, List<Quote>> oppIdToQuoteListMap = new Map<Id, List<Quote>>();
        Map<Id, List<QuoteLineItem>> quoteIdToQliListMap = new Map<Id, List<QuoteLineItem>>();

        for (QuoteLineItem item : qliList) {

            if (oppIdToQuoteListMap.get(item.Quote.OpportunityId) == null) {
                oppIdToQuoteListMap.put(item.Quote.OpportunityId, new List<Quote>());
            }
            oppIdToQuoteListMap.get(item.Quote.OpportunityId).add(item.Quote);

            if (quoteIdToQliListMap.get(item.QuoteId) == null) {
                quoteIdToQliListMap.put(item.QuoteId, new List<QuoteLineItem>());
            }
            quoteIdToQliListMap.get(item.QuoteId).add(item);
        }

        // check we have ContactCenter quote ONLY with Billing Quote
        // if we have only ContactCenter quote(without billing) - thats possibly mean billing quote has no any quoteLineItems

        Boolean isNeedReselectQuotes = false;
        for (Id oppId : oppIdToQuoteListMap.keySet()) {
            List<Quote> quoteList = oppIdToQuoteListMap.get(oppId);

            Boolean hasBillingQuote = false;
            Boolean hasCCQuote = false;

            for (Quote qt : quoteList) {

                if (qt.RecordTypeId == rtIdBilling) {
                    hasBillingQuote = true;
                } else if (qt.RecordTypeId == rtIdCC) {
                    hasCCQuote = true;
                }
            }

            if (!hasBillingQuote && hasCCQuote) {
                isNeedReselectQuotes = true;
                break;
            }
        }

        if (isNeedReselectQuotes) {

            Set<Id> alreadySelectedQuoteIdSet = new Set<Id>();

            for (Id oppId : oppIdToQuoteListMap.keySet()) {
                List<Quote> quoteList = oppIdToQuoteListMap.get(oppId);
                for (Quote qt : quoteList) {
                    alreadySelectedQuoteIdSet.add(qt.Id);
                }
            }

            List<Quote> reselectedQuoteList = [
                SELECT Id, Account_Number_of_Lines__c,
                    Status, AccountId, Approved_Status__c, ActiveAgreementYears__c,
                    Special_Terms__c, Upsell_Status__c, Pricebook2Id, isPrimary__c,
                    IsMultiProductTechnicalQuote__c, BillingPackage__c,
                    Pricebook2.Plan__c, Initial_Term_months__c, RecordTypeId, CurrencyIsoCode,
                    RecordType.DeveloperName, OpportunityId, Opportunity.OwnerId,
                    Opportunity.Type, Opportunity.Account.Active_Sales_Agreement__c,
                    Opportunity.Brand_Name__c, Package_Info__c, Products__c, Payment_Plan__c, Term_months__c, Delta_MRR__c,
                    Opportunity.Account.Active_Sales_Agreement__r.Status,
                    Account.RC_User_ID__c, Account.Billing_ID__c
                FROM Quote
                WHERE OpportunityId IN :oppIdSet AND
                (RecordTypeId = :rtIdBilling OR RecordTypeId = :rtIdCC) AND
                Id NOT IN :alreadySelectedQuoteIdSet
            ];

            for (Quote qt : reselectedQuoteList) {

                if (oppIdToQuoteListMap.get(qt.OpportunityId) == null) {
                    oppIdToQuoteListMap.put(qt.OpportunityId, new List<Quote>());
                }
                oppIdToQuoteListMap.get(qt.OpportunityId).add(qt);

                if (!quoteIdToQliListMap.containsKey(qt.Id)) {
                    quoteIdToQliListMap.put(qt.Id, new List<QuoteLineItem>());
                }

                if (!quoteIdToOpportunityOwnerIdStaticMap.containsKey(qt.Id)) {
                    quoteIdToOpportunityOwnerIdStaticMap.put(qt.Id, qt.Opportunity.OwnerId);
                }
            }
        }

        List<BillingOppData> bodList = new List<BillingOppData>();

        for (Id oppId : oppIdToQuoteListMap.keySet()) {

            List<Quote> quoteList = oppIdToQuoteListMap.get(oppId);

            Map<Quote, List<QuoteLineItem>> salesQuoteMap = new Map<Quote, List<QuoteLineItem>>();
            Map<Quote, List<QuoteLineItem>> contactCenterQuoteMap = new Map<Quote, List<QuoteLineItem>>();

            for (Quote qt : quoteList) {
                if (!quoteIdToQliListMap.containsKey(qt.Id)) {
                    continue;
                }

                if (qt.RecordTypeId == rtIdBilling) {
                    salesQuoteMap.put(qt, quoteIdToQliListMap.get(qt.Id));
                } else if (qt.RecordTypeId == rtIdCC) {
                    contactCenterQuoteMap.put(qt, quoteIdToQliListMap.get(qt.Id));
                }
            }

            BillingOppData bod = new BillingOppData(oppId, salesQuoteMap, contactCenterQuoteMap);
            bodList.add(bod);
        }


        Map<Id, List<QuoteLineItem>> billingQuoteIdToQliListMap = new Map<Id, List<QuoteLineItem>>();
        for (BillingOppData bod : bodList) {
            billingQuoteIdToQliListMap.putAll(
                bod.makeBillingMap()
            );
        }

        billingQuoteIdToQliListMap = excludeQuotesForDQGOAFlow(billingQuoteIdToQliListMap);

        // process
        List<Quote> processedQuotes = handleQuotesNew(billingQuoteIdToQliListMap, null);

        List<Quote> resultQuoteList = new List<Quote>();

        // copy approvedStatus from SalesQuoteV2 to ContactCenter Quote
        for (Quote processedQt : processedQuotes) {

            for (BillingOppData bod : bodList) {

                Set<Quote> ccQuoteSet = bod.getContactCenterQuotesBySalesQuoteV2Id(processedQt.Id);
                if (ccQuoteSet == null) {
                    continue;
                }
                List<Quote> contactCenterQuoteList = new List<Quote>(ccQuoteSet);
                for (Quote ccQt : contactCenterQuoteList) {
                    if (ApprovalHelper.STATUS_REQUIRED.equalsIgnoreCase(ccQt.Approved_Status__c)
                        && ApprovalHelper.STATUS_APPROVED.equalsIgnoreCase(processedQt.Approved_Status__c)) {

                        processedQt.Approved_Status__c = ccQt.Approved_Status__c;
                    } else {
                        ccQt.Approved_Status__c = processedQt.Approved_Status__c;
                    }
                    resultQuoteList.add(ccQt);
                }
            }
            resultQuoteList.add(processedQt);
        }

        System.debug('resultQuoteList.size() >>>> ' + resultQuoteList.size());

        return resultQuoteList;
    }


    public static List<Quote> handleQuotes(Set<Id> quoteIdSet, Set<Id> qliToDeleteIdSet, Map<Id, Quote> quotesMap) {
        List<GOA_V2__c> goasList = GOA_V2__c.getAll().values();

        if (goasList == null || quoteIdSet == null || quoteIdSet.size() == 0 || OpportunityTriggerHelperRefactored.isChangeOrderFlow) {
            return new List<Quote>();
        }

        qliList = (List<QuoteLineItem>) new QuoteLineItemSelector()
            .selectQuoteLineItemsForHandleQuotes(quoteIdSet, qliToDeleteIdSet)
            .executeQuery();
        System.debug('qliList >>> ' + qliList);

        Set<Id> accountIdSet = new Set<Id>();

        Map<Id, List<QuoteLineItem>> quoteIdToQliListMap = new Map<Id, List<QuoteLineItem>>();

        for (QuoteLineItem item : qliList) {

            if (quoteIdToQliListMap.get(item.QuoteId) == null) {
                quoteIdToQliListMap.put(item.QuoteId, new List<QuoteLineItem>());
            }
            quoteIdToQliListMap.get(item.QuoteId).add(item);

            if (item.Quote.Upsell_Status__c != 'New') {
                accountIdSet.add(item.Quote.AccountId);
            }

            quoteIdToOpportunityOwnerIdStaticMap.put(item.QuoteId, item.Quote.Opportunity.OwnerId);
        }

        quoteIdToQliListMap = excludeQuotesForDQGOAFlow(quoteIdToQliListMap);

        // if last qli was deleted from quote -
        // this quote will not be found by soql from QuoteLineItems(qliList) and quote will not search for approvers
        // but we still need update approvers for this quote - so add it to quoteIdToQliListMap(just quoteId and empty List<QuoteLineItem>)
        // also we need to find Opportnuity Owner
        if (qliList.isEmpty() && !quoteIdSet.isEmpty()) {
            for (Id quoteId : quoteIdSet) {
                if (quoteIdToQliListMap.get(quoteId) == null) {
                    quoteIdToQliListMap.put(quoteId, new List<QuoteLineItem>());
                }
            }

            for (Quote q : [SELECT Id, Opportunity.OwnerId FROM Quote WHERE Id IN :quoteIdSet]) {
                if (quoteIdToOpportunityOwnerIdStaticMap.get(q.Id) == null) {
                    quoteIdToOpportunityOwnerIdStaticMap.put(q.Id, q.Opportunity.OwnerId);
                }
            }
        }

        return handleQuotesNew(quoteIdToQliListMap, quotesMap);
    }

    public static List<Quote> handleQuotesNew(Map<Id, List<QuoteLineItem>> quoteIdToQliListMap, Map<Id, Quote> quotesMap) {

        List<GOA_V2__c> goasList = GOA_V2__c.getAll().values();

        if (goasList == null || quoteIdToQliListMap == null || quoteIdToQliListMap.size() == 0) {
            return new List<Quote>();
        }

        Set<Id> accountIdSet = new Set<Id>();

        for (List<QuoteLineItem> qliList : quoteIdToQliListMap.values()) {
            for (QuoteLineItem item : qliList) {
                if (item.Quote.Upsell_Status__c != 'New') {
                    accountIdSet.add(item.Quote.AccountId);
                }

                quoteIdToOpportunityOwnerIdStaticMap.put(item.QuoteId, item.Quote.Opportunity.OwnerId);
            }
        }

        Map<Id, String> accountIdToInitialTermMap = new Map<Id, String>();

        if (accountIdSet.size() > 0) {
            for (Quote item : [SELECT Id, AccountId, Initial_Term_months__c FROM Quote WHERE AccountId IN :accountIdSet AND Status = 'Active' AND Id NOT IN :quoteIdToQliListMap.keySet()]) {
                accountIdToInitialTermMap.put(item.AccountId, item.Initial_Term_months__c);
            }
        }

        Boolean useAllQLI = false;
        Map<Id, List<String>> quoteIdToHRListMap = buildQuoteIdToHRListMap(
            quoteIdToQliListMap,
            goasList,
            accountIdToInitialTermMap,
            quotesMap,
            useAllQLI
        );

        useAllQLI = true;
        Map<Id, List<String>> quoteIdToHRListMap_Full = buildQuoteIdToHRListMap(
            quoteIdToQliListMap,
            goasList,
            accountIdToInitialTermMap,
            quotesMap,
            useAllQLI
        );

        Map<Id, Integer> quoteIdToSpecialApproverMap = buildQuoteIdToSpecialApproverMap(quoteIdToQliListMap);
        if (quotesMap == null) {

            quotesMap = new Map<Id, Quote>([
                SELECT Id, Approval_Type__c, Approved_Status__c, Auto_Renewal__c, OwnerId,
                    Level_1_Approver__c, Level_2_Approver__c, Pricebook2Id, AccountId,
                    Pricebook2.Plan__c, RecordTypeId, RecordType.DeveloperName,
                    Initial_Term_months__c, Special_Terms__c, Upsell_Status__c, PackageNameOld__c,
                    Account_Number_of_Lines__c, ActiveAgreementYears__c, IsPRMQuote__c,
                    IsMultiProductTechnicalQuote__c,
                    Level_3_Approver__c, Level_4_Approver__c, Level_5_Approver__c, Level_7_Approver__c,
                    Level_6_Approver__c, Package_Info__c, Credit_Amount__c, CurrencyIsoCode,
                    Initial_Term__c, Products__c, Payment_Plan__c, Term_months__c,
                    Account__r.ELA_Account_Type__c, First_Year_Cost_of_Service__c,
                    FreeShippingTerms__c, Shipping_Option__c, Enabled_LBO__c,
                    Total_First_Year_Cost__c, JD_GOA__c, OpportunityId, Opportunity.Type, Delta_MRR__c,
                    Opportunity.Account.Active_Sales_Agreement__r.Status,
                    Opportunity.Account.Active_Sales_Agreement__c, Opportunity.Brand_Name__c,
                    Account.BillingCountry, Account.RC_User_ID__c, Account.Billing_ID__c,
                    ProservLevelApprover__c, ServiceName__c, Opportunity.Parent_Order__c,
                    Opportunity.Tier_Name__c,
                    (
                        SELECT Id, LineNumber, Quantity, Discount, Discount_number__c,
                            Discount_type__c, Deactivated__c, Product2.GOA_Group__c, Product2.GOA_Group_V2__c,
                            Product2.GOA_Group_V3__c, Quote.Account.BillingCountry
                        FROM QuoteLineItems
                    )

                    from Quote
                    where Id in :quoteIdToHRListMap.keySet()
            ]);
        }
        // we should process "autoRenewal" and "special terms" only if quote changed(not QuoteLineItem - we should pass processing it in this case)
        Boolean isQuoteUpdate = (Trigger.isUpdate != null && Trigger.isUpdate) && Trigger.oldMap != null && (Trigger.oldMap instanceof Map<Id, Quote>);
        Boolean quoteHasInitialTerm = false;
        Boolean quoteHasSpecialTerms = false;
        Boolean quoteHasRampUpPeriod = false;

        for (Quote qt : quotesMap.values()) {
            if (qt.Initial_Term__c != null || qt.Initial_Term_months__c != null) {
                quoteHasInitialTerm = true;
            }
            if (qt.Special_Terms__c != null) {
                quoteHasSpecialTerms = true;
            }
        }

        Boolean isAnyQuoteContainsProductDependOnGOAInitialTerm = false;

        QuoteTriggerHelper.SetApprovalType approvalTypeSetter = new QuoteTriggerHelper.SetApprovalType();

        for (Id quoteId : quoteIdToHRListMap.keySet()) {
            List<QuoteLineItem> qliList = quoteIdToQliListMap.get(quoteId);
            isAnyQuoteContainsProductDependOnGOAInitialTerm = approvalTypeSetter.checkIsQuoteContainsProductsDependsOnGOAInitialTerm(qliList);
            if (isAnyQuoteContainsProductDependOnGOAInitialTerm) {
                break;
            }
        }

        Boolean checkSpecialTermsAndAutoRenewal = isQuoteUpdate ||
            (!isQuoteUpdate
                && (quoteHasSpecialTerms || quoteHasInitialTerm)
                || isAnyQuoteContainsProductDependOnGOAInitialTerm);


        if (checkSpecialTermsAndAutoRenewal) {

            Set<Id> accIdsSet = new Set<Id>();
            for (Quote currQuote : quotesMap.values()) {
                accIdsSet.add(currQuote.AccountId);
            }

            Map<Id, Account> accIdToActiveSalesAgreementMap = new Map<Id, Account>([SELECT Id, Active_Sales_Agreement__c, Active_Sales_Agreement__r.Auto_Renewal__c FROM Account WHERE Id IN :accIdsSet]);

            // check autoRenewal
            for (Id quoteId : quoteIdToHRListMap.keySet()) {

                Quote currentQuote = quotesMap.get(quoteId);

                Account currentAccount = accIdToActiveSalesAgreementMap.get(currentQuote.AccountId);
                Boolean isActiveSalesAgreementAutorenewal = (currentAccount?.Active_Sales_Agreement__c != null &&
                    currentAccount?.Active_Sales_Agreement__r.Auto_Renewal__c) ||
                    currentAccount?.Active_Sales_Agreement__c == null;

                if ((!currentQuote.Auto_Renewal__c && isActiveSalesAgreementAutorenewal) && QuoteHelper.isQuoteHasContract(currentQuote)) {

                    List<String> hrList = quoteIdToHRListMap.get(quoteId);

                    Set<String> hrSet = new Set<String>(hrList);

                    if (!hrSet.contains(UserHelper.SVP_WWS_DIRECTS_ROLE)) {
                        quoteIdToHRListMap.get(quoteId).add(UserHelper.SVP_WWS_DIRECTS_ROLE);
                        quoteIdToHRListMap_Full.get(quoteId).add(UserHelper.SVP_WWS_DIRECTS_ROLE);
                        System.debug('found quote with unchecked AutoRenewal. add svp wws directs to approver List');
                    }
                }
            }

            // check special terms
            Map<Id, String> quoteIdToLastApproverMap = processSpecialTermsApprovers(quotesMap.values(), qliList);
            for (Id quoteId : quoteIdToHRListMap.keySet()) {

                if (quoteIdToLastApproverMap.keySet().contains(quoteId)) {

                    String lastApproverForCurrentQuote = quoteIdToLastApproverMap.get(quoteId);

                    List<String> hrList = quoteIdToHRListMap.get(quoteId);

                    Set<String> hrSet = new Set<String>(hrList);

                    if (!hrSet.contains(lastApproverForCurrentQuote)) {
                        quoteIdToHRListMap.get(quoteId).add(lastApproverForCurrentQuote);
                        quoteIdToHRListMap_Full.get(quoteId).add(lastApproverForCurrentQuote);
                    }
                }
            }
        }

        List<Quote> quotesToUpdateList;
        if (hasSpecialApprovers) {
            quotesToUpdateList = findSpecialApproversByHierarchyRoles(quoteIdToSpecialApproverMap, quotesMap);
        } else {
            quotesToUpdateList = findApproversByHierarchyRoles(quoteIdToHRListMap, quoteIdToHRListMap_Full, quotesMap, quoteIdToQliListMap);
        }

        // Updating approvers list for CC FSC on Main Quote
        quotesToUpdateList = processFSCforCCapprovers(quotesToUpdateList);
        quotesToUpdateList = processFSCforEngageApprovers(quotesToUpdateList);
        quotesToUpdateList = processDownsell(quotesToUpdateList, quoteIdToQliListMap);
        quotesToUpdateList = processsTermMonth(quotesToUpdateList);
        quotesToUpdateList = processFreeShippingApprover(quotesToUpdateList, quoteIdToQliListMap);
        quotesToUpdateList = processProservApproverQueue(quotesToUpdateList, quoteIdToQliListMap);

        //Updating approvers list for UC not in role hierarchy
        quotesToUpdateList = processFSCforUCapprovers(quotesToUpdateList);

        // process Quote.Products__c
        quotesToUpdateList = processProducts(quotesToUpdateList, quoteIdToQliListMap);

        return quotesToUpdateList;
    }

    private static List<Quote> processFSCforCCapprovers(List<Quote> quotesList) {
        Set<Id> oppIdsSet = new Set<Id>();
        for (Quote currentQuote : quotesList) {
            if (QuoteHelper.isProservQuote(currentQuote) || QuoteHelper.isCCProservQuote(currentQuote)) {
                continue;
            }
            oppIdsSet.add(currentQuote.OpportunityId);
        }
        List<Opportunity> allOpps = [
            SELECT Id, Name, Is_Billing_Opportunity__c, (
                SELECT
                    Id, Name, Approval_Type__c, Approved_Status__c, Auto_Renewal__c,
                    Level_1_Approver__c, Level_2_Approver__c, Pricebook2Id,
                    Pricebook2.Plan__c, RecordTypeId, RecordType.DeveloperName,
                    Initial_Term_months__c, Special_Terms__c, Upsell_Status__c,
                    Account_Number_of_Lines__c, ActiveAgreementYears__c, LastModifiedDate,
                    Level_3_Approver__c, Level_4_Approver__c, Level_5_Approver__c, Level_6_Approver__c, Level_7_Approver__c,
                    Package_Info__c, Credit_Amount__c, CurrencyIsoCode, isPrimary__c,
                    Initial_Term__c, Products__c, Payment_Plan__c, Term_months__c,
                    Account__r.ELA_Account_Type__c, First_Year_Cost_of_Service__c,
                    Total_First_Year_Cost__c, OpportunityId, Opportunity.Type
                FROM Quotes
            )
            FROM Opportunity
            WHERE Id IN :oppIdsSet
        ];
        Map<Id, Quote> quotesToUpdate = new Map<Id, Quote>();
        for (Opportunity currentOpp : allOpps) {
            Quote primaryQuote = QuoteHelper.getPrimaryQuote(currentOpp.Quotes, currentOpp.Is_Billing_Opportunity__c);
            Quote ccQuote = QuoteHelper.getCCQuote(currentOpp.Quotes);
            if ((Trigger.isExecuting && (Trigger.isUpdate || Trigger.isInsert)) && ccQuote != null) {
                if (Trigger.newMap.get(ccQuote.Id) != null) {
                    ccQuote = (Quote) Trigger.newMap.get(ccQuote.Id);
                }
                if (!DQGoa.isDQGoaEnabled()) {

                    String approverLevel = findApproverLevelsForCCFSC(ccQuote);
                    Boolean isPrimaryQuoteFoundInProcessedQuotes = false;
                    for (Quote qt : quotesList) {
                        if (qt.Id == primaryQuote.Id) {
                            isPrimaryQuoteFoundInProcessedQuotes = true;
                            if ((Trigger.isUpdate || Trigger.isInsert) && Trigger.isBefore) {
                                qt = setApproverForCCFSC(qt, approverLevel);
                            } else {
                                qt = setApproverForCCFSC(qt, approverLevel);
                                quotesToUpdate.put(qt.Id, qt);
                            }
                        }
                    }
                    if (!isPrimaryQuoteFoundInProcessedQuotes) {
                        primaryQuote = setApproverForCCFSC(primaryQuote, approverLevel);
                        quotesToUpdate.put(primaryQuote.Id, primaryQuote);
                    }
                }
            }
        }
        if (quotesToUpdate.size() > 0) {
            update quotesToUpdate.values();
        }
        return quotesList;
    }

    private static String findApproverLevelsForCCFSC(Quote ccQuote) {
        String approverLevel;
        if (ccQuote.Initial_Term_months__c != null && ccQuote.Special_Terms__c != null) {
            List<SpecialTermsApprovers_V2__c> stApprovers = SpecialTermsApprovers_V2__c.getAll().values();
            for (SpecialTermsApprovers_V2__c approver : stApprovers) {
                String[] itRange;
                String its;
                String ite;
                if (approver.Initial_Term__c.contains('-')) {
                    itRange = approver.Initial_Term__c.split('-');
                    its = itRange[0];
                    ite = itRange[1];
                } else {
                    its = approver.Initial_Term__c;
                    ite = approver.Initial_Term__c;
                }
                Boolean isQuoteUpdate = true == Trigger.isUpdate && Trigger.oldMap != null && Trigger.newMap.containsKey(ccQuote.Id);
                if (Decimal.valueOf(its) <= Decimal.valueOf(ccQuote.Initial_Term_months__c)
                    && Decimal.valueOf(ite) >= Decimal.valueOf(ccQuote.Initial_Term_months__c)
                    && approver.Special_Terms__c == ccQuote.Special_Terms__c
                    && approver.Plan__c == null) {
                    approverLevel = approver.Last_Approver__c;
                }
            }
        }
        return approverLevel;
    }

    private static List<User> CCFSCApprover_p;
    private static List<User> CCFSCApprover {
        get {
            if (CCFSCApprover_p == null) {
                RingCentralVariousSettings__c settings = RingCentralVariousSettings__c.getInstance();
                if (settings.CC_FSC_Approvers_Queues__c != null) {
                    List<String> ccFscQueuesNames = settings.CC_FSC_Approvers_Queues__c.split(';');
                    CCFSCApprover_p = ApproversSearch.getApproversByQueues(ccFscQueuesNames);
                } else {
                    CCFSCApprover_p = new List<User>();
                }
            }
            return CCFSCApprover_p;
        }
    }

    private static Integer MAX_LEVEL_APPROVER = 7;

    private static Quote setApproverForCCFSC(Quote primaryQuote, String approverLevel) {
        List<User> approvers = CCFSCApprover;

        for (User approver : approvers) {
            if (approverLevel != null) {
                String firstFreeApproverField = findFirstFreeApproverField (primaryQuote);
                if (isApproverFoundOnQuote(primaryQuote, approver.Id)) {
                    continue;
                }
                if (firstFreeApproverField != null) {
                    primaryQuote.put(firstFreeApproverField, approver.Id);
                    primaryQuote.Approved_Status__c = 'Required';
                }
            } else {
                clearFieldsWithFSCapprovers(primaryQuote, approvers);
            }
        }

        return primaryQuote;
    }

    private static Boolean isApproverFoundOnQuote(Quote primaryQuote, Id approverId) {
        Boolean result = false;

        for (Integer i = 1; i <= MAX_LEVEL_APPROVER; i++) {
            if (primaryQuote.get('Level_' + i + '_Approver__c') == approverId) {
                result = true;
                break;
            }
        }

        return result;
    }

    private static String findFirstFreeApproverField(Quote targetQuote) {
        String firsFreeApprover = 'Level_1_Approver__c';
        for (Integer i = 1; i <= MAX_LEVEL_APPROVER; i++) {
            if (targetQuote.get('Level_' + i + '_Approver__c') == null) {
                firsFreeApprover = 'Level_' + i + '_Approver__c';
                break;
            }
        }
        return firsFreeApprover;
    }

    private static void clearFieldsWithFSCapprovers(Quote targetQuote, List<User> fscApprovers) {
        List<String> resultApproverFields = new List<String>();
        for (Integer i = MAX_LEVEL_APPROVER; i >= 1; i--) {
            if (targetQuote.get('Level_' + i + '_Approver__c') != null && resultApproverFields.size() < 2) {
                for (User fscApprover : fscApprovers) {
                    if (fscApprover.Id == targetQuote.get('Level_' + i + '_Approver__c') && fscApprover.Hierarchy_Role__c == null) {
                        resultApproverFields.add('Level_' + i + '_Approver__c');
                    }
                }
            }
        }
        for (String fieldToClear : resultApproverFields) {
            targetQuote.put(fieldToClear, null);
        }
    }

    private static List<Quote> processFSCforEngageApprovers(List<Quote> quotesList) {
        Set<Id> oppIdsSet = new Set<Id>();
        Quote currentEngageQuote;
        for (Quote currentQuote : quotesList) {
            if (currentQuote.Special_Terms__c == null ||
                currentQuote.Initial_Term_months__c == null ||
                !(QuoteHelper.isEngageService(currentQuote) ||
                    QuoteHelper.isCCService(currentQuote))) {
                continue;
            }
            currentEngageQuote = currentQuote;
            oppIdsSet.add(currentQuote.OpportunityId);
        }
        List<Quote> quotesToUpdate = new List<Quote>();
        if (currentEngageQuote != null) {
            String approverLevel = findApproverLevelsForEngageFSC(currentEngageQuote);
            currentEngageQuote = setApproverForEngageFSC(currentEngageQuote, approverLevel);
            quotesToUpdate.add(currentEngageQuote);
        }

        return quotesList;
    }

    private static String findApproverLevelsForEngageFSC(Quote ccQuote) {
        String approverLevel;
        if (ccQuote.Initial_Term_months__c != null && ccQuote.Special_Terms__c != null) {
            List<SpecialTermsApprovers_V2__c> stApprovers = SpecialTermsApprovers_V2__c.getAll().values();
            for (SpecialTermsApprovers_V2__c approver : stApprovers) {
                String[] itRange;
                String its;
                String ite;
                if (approver.Initial_Term__c.contains('-')) {
                    itRange = approver.Initial_Term__c.split('-');
                    its = itRange[0];
                    ite = itRange[1];
                } else {
                    its = approver.Initial_Term__c;
                    ite = approver.Initial_Term__c;
                }
                if (Decimal.valueOf(its) <= Decimal.valueOf(ccQuote.Initial_Term_months__c)
                    && Decimal.valueOf(ite) >= Decimal.valueOf(ccQuote.Initial_Term_months__c)
                    && approver.Special_Terms__c == ccQuote.Special_Terms__c
                    && approver.Plan__c == (QuoteHelper.isEngageService(ccQuote) ? 'Engage' : 'RCCC')) {
                    approverLevel = approver.Last_Approver__c;
                }
            }
        }
        return approverLevel;
    }

    private static User engageFSCApprover_p;
    private static User engageFSCApprover {
        get {
            if (engageFSCApprover_p == null) {
                engageFSCApprover_p = ApproversSearch.getApproverByQueue(ENGAGE_FSC_APPROVERS_QUEUE_NAME);
            }
            return engageFSCApprover_p;
        }
    }

    private static Quote setApproverForEngageFSC(Quote primaryQuote, String approverLevel) {
        String firstFreeApproverField = findFirstFreeApproverField (primaryQuote);
        User approver = engageFSCApprover;

        if (approverLevel != null && firstFreeApproverField != null) {
            primaryQuote.put(firstFreeApproverField, approver.Id);
            primaryQuote.Approved_Status__c = ApprovalHelper.STATUS_REQUIRED;
        }
        return primaryQuote;
    }

    private static List<Quote> processsTermMonth(List<Quote> quoteList) {

        if (!Feature_Toggle__c.getInstance().Enable_new_Contract_Term_flow__c) {
            return quoteList;
        }

        for (Quote qt : quoteList) {
            Boolean isBillingQuote = qt.RecordTypeId == QuoteHelper.RT_ID_BILLING;

            if (!isBillingQuote) {
                continue;
            }

            Boolean isSmallTermMonth = QuoteHelper.isTermsLessYear(qt);

            Boolean isNeedToClearLastApprover = qt.Approved_Status__c == QuoteHelper.APPROVAL_STATUS_APPROVED &&
                qt.Approval_Type__c == QuoteHelper.FINANCE_QUEUE_APPROVAL_TYPE &&
                qt.Level_1_Approver__c == null;

            if (isSmallTermMonth) {
                qt.Approved_Status__c = QuoteHelper.APPROVAL_STATUS_REQUIRED;
                qt.Approval_Type__c = QuoteHelper.FINANCE_QUEUE_APPROVAL_TYPE;
            } else if (isNeedToClearLastApprover) {
                qt.Approval_Type__c = null;
            }
        }

        return quoteList;
    }

    private static Map<String, Integer> specialApproversOrderMap = new Map<String, Integer>{
        UserHelper.SALES_REP_ROLE => 1,
        'Level_1_Approver__c' => 2,
        'Level_2_Approver__c' => 3,
        'Level_3_Approver__c' => 4
    };

    private static Boolean hasSpecialApprovers;

    public static Map<Id, Integer> buildQuoteIdToSpecialApproverMap(Map<Id, List<QuoteLineItem>> quoteIdToQliListMap) {
        List<GOA_Special_Approvers__c> goaSpecialApproversList = GOA_Special_Approvers__c.getAll().values();
        Map<Id, Integer> quoteIdToApproverListMap = new Map<Id, Integer>();
        hasSpecialApprovers = false;

        Map<Id, String> qliIdToApproverRoleName = new Map<Id, String>();
        for (Id quoteId : quoteIdToQliListMap.keySet()) {
            qliIdToApproverRoleName = findSpecialGOAForQLI(goaSpecialApproversList, quoteIdToQliListMap.get(quoteId));

            // Find highest Approver
            String highestApprover;
            Integer highestApproverLevel;
            for (QuoteLineItem qli : quoteIdToQliListMap.get(quoteId)) {
                if (qli.QuoteId != quoteId) {
                    continue;
                }
                String qliApprover = qliIdToApproverRoleName.get(qli.Id);
                if (qliApprover != null && highestApproverLevel == null) {
                    highestApproverLevel = specialApproversOrderMap.get(qliApprover);
                    highestApprover = qliApprover;
                    hasSpecialApprovers = true;
                }
                if (qliApprover != null && specialApproversOrderMap.get(qliApprover) > highestApproverLevel) {
                    highestApprover = qliApprover;
                    highestApproverLevel = specialApproversOrderMap.get(qliApprover);
                }
            }

            quoteIdToApproverListMap.put(quoteId, highestApproverLevel);
        }

        return quoteIdToApproverListMap;
    }

    private static Map<Id, String> findSpecialGOAForQLI(List<GOA_Special_Approvers__c> goasList, List<QuoteLineItem> qliList) {
        Map<Id, String> qliIdToApproverRoleName = new Map<Id, String>();
        Id mobileUserId;

        Map<Id, QuoteLineItem> requireApprovalQLIList = new Map<Id, QuoteLineItem>(filterQLIForApproval(qliList));

        Boolean isNeededApproversFound = false;

        for (QuoteLineItem item : qliList) {
            Double itemDiscount = item.Discount_Value__c == null ? 0 : item.Discount_Value__c;

            if (itemDiscount == 0) {
                continue;
            }

            BillingWrappers.QLIPackageInfo qliPackageInfo = BillingWrappers.parseQLIPackageInfo(item.PackageInfo__c);
            if (qliPackageInfo != null && qliPackageInfo.isCommissionable()) {
                continue;
            }

            if (Product2Helper.isMobileUser(item)) {
                continue;
            }

            if (item.Product2.GOA_Group_V2__c != null || item.Product2.GOA_Group_V3__c != null) {
                String hRoleFound = findSpecialApproverRoleForQLI(goasList, item);
                if (hRoleFound != null) {
                    isNeededApproversFound = true;
                }
                if (requireApprovalQLIList.get(item.Id) != null) {
                    qliIdToApproverRoleName.put(item.Id, hRoleFound);
                }
            }
        }

        if (isNeededApproversFound) {
            hasSpecialApprovers = true;
        }

        return qliIdToApproverRoleName;
    }

    private static String findSpecialApproverRoleForQLI(List<GOA_Special_Approvers__c> goasList, QuoteLineItem qli) {
        String roleName;
        Double itemDiscount = qli.Discount_Value__c == null ? 0 : qli.Discount_Value__c;

        for (GOA_Special_Approvers__c goa : goasList) {
            if (qli.Quote.Opportunity.Brand_Name__c != goa.Brand__c) {
                continue;
            }

            // If GOA from custom setting has 'Percentage' currency we should take Discount from QuoteLineItem.Discount
            if (goa.Currency__c == PERCENTAGE_GOA_CURRENCY) {
                itemDiscount = qli.Discount == null ? 0 : qli.Discount;
            } else {
                itemDiscount = qli.Discount_Value__c == null ? 0 : qli.Discount_Value__c;
            }

            List<Range> rangeList = new List<Range>();

            Range salesRepDiscounts = new Range(goa.Sales_Rep__c, '-', UserHelper.SALES_REP_ROLE);
            rangeList.add(salesRepDiscounts);
            Range l1Discounts = new Range(goa.Level_1_Approver__c, '-', 'Level_1_Approver__c');
            rangeList.add(l1Discounts);
            Range l2Discounts = new Range(goa.Level_2_Approver__c, '-', 'Level_2_Approver__c');
            rangeList.add(l2Discounts);
            Range l3Discounts = new Range(goa.Level_3_Approver__c, '-', 'Level_3_Approver__c');
            rangeList.add(l3Discounts);

            Boolean discountFitsInRanges = salesRepDiscounts.isInRange(itemDiscount) || l1Discounts.isInRange(itemDiscount) || l2Discounts.isInRange(itemDiscount) ||
                l3Discounts.isInRange(itemDiscount);

            // group
            Boolean groupFound = false;
            if (String.isBlank(qli.Product2.GOA_Group_V3__c)) {
                groupFound = qli.Product2.GOA_Group_V2__c == goa.Group__c;
            } else {
                List<BillingWrappers.QuotePackageInfo> pInfos =
                    (List<BillingWrappers.QuotePackageInfo>)
                        JSON.deserialize(
                            qli.Quote.Package_Info__c,
                            List<BillingWrappers.QuotePackageInfo>.class
                        );
                BillingWrappers.QuotePackageInfo pInfo = pInfos[0];

                String goaGroup = '';
                try {
                    goaGroup = QuoteLineItemHelper.parseOldFormatGOA(qli, pInfo);
                } catch (JSONException e) {
                    goaGroup = QuoteLineItemHelper.parseNewFormatGOA(qli, pInfo);
                }

                groupFound = goaGroup == goa.Group__c;
            }

            if (discountFitsInRanges && groupFound) {
                for (Range currentRange : rangeList) {
                    if (currentRange.isInRange(itemDiscount)) {
                        roleName = currentRange.rangeName;
                    }
                }
            }
        }

        return roleName;
    }

    private static Map<Id, List<String>> buildQuoteIdToHRListMap(
        Map<Id, List<QuoteLineItem>> quoteIdToQliListMap,
        List<GOA_V2__c> goasList,
        Map<Id, String> accountIdToInitialTermMap,
        Map<Id, Quote> quotesMap,
        Boolean useAllQLI) {

        Map<Id, List<String>> quoteIdToHRListMap = new Map<Id, List<String>>();

        for (Id item : quoteIdToQliListMap.keySet()) {
            List<QuoteLineItem> qliForCurrentQuote = quoteIdToQliListMap.get(item);
            qliForCurrentQuote = filterQlisWithoutPreApproveDiscounts(qliForCurrentQuote);
            qliForCurrentQuote = filterQlisWithoutProserv(qliForCurrentQuote);
            Map<Id, String> qliIdToApproverRoleName = new Map<Id, String>();

            if (useAllQLI) {
                qliIdToApproverRoleName = findGOAForQLI(goasList, qliForCurrentQuote, accountIdToInitialTermMap, quotesMap);
            } else {
                List<QuoteLineItem> requireApprovalQLIList = filterQLIForApproval(qliForCurrentQuote);
                qliIdToApproverRoleName = findGOAForQLI(goasList, requireApprovalQLIList, accountIdToInitialTermMap, quotesMap);
            }

            Set<String> foundedRolesSet = new Set<String>();
            List<Integer> foundedRolesOrder = new List<Integer>();

            for (Id qliId : qliIdToApproverRoleName.keySet()) {
                String roleName = qliIdToApproverRoleName.get(qliId);

                if (!foundedRolesSet.contains(roleName)) {
                    foundedRolesSet.add(roleName);

                    Integer currentRolePriority = UserHelper.hierarchyRolesNameToOrderMap.get(roleName);
                    foundedRolesOrder.add(currentRolePriority);
                }
            }

            foundedRolesOrder.sort();
            System.debug('foundedRolesOrder.size() >>>> ' + foundedRolesOrder.size());
            if (!foundedRolesOrder.isEmpty()) {
                List<String> approverRolesNameList = new List<String>();

                for (Integer hRoleOrder : foundedRolesOrder) {
                    approverRolesNameList.add(
                        UserHelper.hierarchyRolesOrderToNameMap.get(hRoleOrder)
                    );
                }

                if (quoteIdToHRListMap.get(item) == null) {
                    quoteIdToHRListMap.put(item, approverRolesNameList);
                }
            } else {
                if (quoteIdToHRListMap.get(item) == null) {
                    quoteIdToHRListMap.put(item, new List<String>{
                        UserHelper.SALES_REP_ROLE
                    });
                }
            }
        }

        return quoteIdToHRListMap;
    }

    // method used for filtering QLI that require approval only
    private static List<QuoteLineItem> filterQLIForApproval(List<QuoteLineItem> qliForCurrentQuote) {
        ApprovalNeededQualifiers.ApprovalNeededChecker myChecker = new ApprovalNeededQualifiers.ApprovalNeededChecker();

        myChecker.addQualifier(
            new ApprovalNeededQualifiers.QLIQuantityChangeQualifier()
        );

        myChecker.addQualifier(
            new ApprovalNeededQualifiers.CurrentDiscountsQualifier()
        );

        myChecker.addQualifier(
            new ApprovalNeededQualifiers.ProServCurrentDiscountsQualifier()
        );
        myChecker.addQualifier(
            new ApprovalNeededQualifiers.ProServOneTimeDiscountQualifier()
        );

        // run process
        Map<Id, Boolean> qliIdToNeedApprovalMap = myChecker.process(qliForCurrentQuote);

        // filter qliForCurrentQuote - select qli that require approval only
        List<QuoteLineItem> requireApprovalQLIList = new List<QuoteLineItem>();

        for (QuoteLineItem qli : qliForCurrentQuote) {
            if (qliIdToNeedApprovalMap.get(qli.Id) == null) {
                continue;
            }
            Boolean isApprovalRequired = qliIdToNeedApprovalMap.get(qli.Id);
            if (isApprovalRequired) {
                requireApprovalQLIList.add(qli);
            }
        }

        return requireApprovalQLIList;
    }


    private static List<Quote> processProducts(List<Quote> quotesList, Map<Id, List<QuoteLineItem>> quoteIdToQliListMap) {
        for (Quote item : quotesList) {
            List<QuoteLineItem> qliList = quoteIdToQliListMap.get(item.Id);

            if (qliList != null) {
                Map<Id, QuoteLineItem> qliMap = new Map<Id, QuoteLineItem>();
                for (QuoteLineItem qli : qliList) {
                    qliMap.put(qli.Id, qli);
                }

                Map<Id, String> productsMap = SetApprovalTypeHelper.getProductsMap(qliMap);
                System.debug('productsMap: ' + productsMap);

                if (productsMap.containsKey(item.Id)) {
                    if (item.Products__c != productsMap.get(item.Id)) {
                        item.Products__c = productsMap.get(item.Id);
                    }
                }
            }
        }

        return quotesList;
    }

    @TestVisible
    private static List<Quote> processDownsell(List<Quote> quotesToUpdateList, Map<Id, List<QuoteLineItem>> quoteIdToQliListMap) {
        Decimal threshold = InContractDownsell__c.getOrgDefaults().Threshold__c;
        Map<String, Decimal> currencyToConversionRateMap = AquivaHelper.getCurrencyToConversionRateMap();

        for (Quote q : quotesToUpdateList) {
            List<QuoteLineItem> qlis = quoteIdToQliListMap.get(q.Id);
            Quote quoteToCheck = qlis.isEmpty() ? q : qlis.get(0).Quote;

            Decimal currencyRate = currencyToConversionRateMap.get(q.CurrencyIsoCode) == null ? 1 : currencyToConversionRateMap.get(q.CurrencyIsoCode);
            Decimal convertedThreshold = threshold == null ? q.Delta_MRR__c : threshold * currencyRate;

            q.DownsellApprover__c = null;

            if (AccountHelper.isContracted(quoteToCheck?.Opportunity.Account)
                && OpportunityHelper.isRcBrand(quoteToCheck?.Opportunity)
                && (q.Delta_MRR__c < convertedThreshold || QuoteHelper.isQuoteOutOfContract(quoteToCheck)
                && !OpportunityHelper.isProServChangeOrderOpportunity(quoteToCheck.Opportunity.Parent_Order__c, quoteToCheck.Opportunity.Tier_Name__c))
            ) {
                q.DownsellApprover__c = GroupHelper.APPROVAL_DOWNSELL_QUEUE;
                q.Approved_Status__c = QuoteHelper.APPROVAL_STATUS_REQUIRED;
                q.Approval_Type__c = QuoteHelper.DOWNSELL_QUEUE_APPORVAL_TYPE;
            } else {
                Boolean isNeedToClearLastApprover = q.Approved_Status__c == QuoteHelper.APPROVAL_STATUS_APPROVED &&
                    q.Approval_Type__c == QuoteHelper.DOWNSELL_QUEUE_APPORVAL_TYPE &&
                    q.Level_1_Approver__c == null;

                q.Approval_Type__c = isNeedToClearLastApprover ? null : q.Approval_Type__c;
            }
        }

        return quotesToUpdateList;
    }

    private static List<Quote> findSpecialApproversByHierarchyRoles(Map<Id, Integer> quoteIdToSpecialApproverMap, Map<Id, Quote> quotesMap) {
        List<GOA_Special_Approvers_Settings__c> specialApprovers = GOA_Special_Approvers_Settings__c.getAll().values();
        List<Quote> quotesToUpdate = new List<Quote>();

        Map<Integer, String> orderToSpecialApproverMap = new Map<Integer, String>();
        for (String approverName : specialApproversOrderMap.keySet()) {
            orderToSpecialApproverMap.put(specialApproversOrderMap.get(approverName), approverName);
        }

        for (Quote currentQuote : quotesMap.values()) {
            Map<Integer, GOA_Special_Approvers_Settings__c> specialApproversMap = new Map<Integer, GOA_Special_Approvers_Settings__c>();

            // Find default special approvers (with Country = null)
            for (GOA_Special_Approvers_Settings__c specialApprover : specialApprovers) {
                if (specialApprover.Country__c == null) {
                    specialApproversMap.put((Integer) specialApprover.Approver_Level__c, specialApprover);
                }
            }

            // Override default special approvers with country (if found)
            for (GOA_Special_Approvers_Settings__c specialApprover : specialApprovers) {
                if (specialApprover.Country__c == currentQuote.Account.BillingCountry) {
                    specialApproversMap.put((Integer) specialApprover.Approver_Level__c, specialApprover);
                }
            }

            if (quoteIdToSpecialApproverMap.containsKey(currentQuote.Id)) {
                // Reset Quote approvers
                for (Integer i = 1; i <= MAX_LEVEL_APPROVER; i++) {
                    currentQuote.put('Level_' + i + '_Approver__c', null);
                }

                List<Id> finalApproversList = new List<Id>();

                // Find Sales Rep approver as first approver
                User currentUser = ApproversSearch.findUserById(currentQuote.OwnerId);

                ApproversSearch approversSearcher = new ApproversSearch();
                List<Id> approversIdList = approversSearcher.findApproverIdsByHierarchyRoles(new List<String>{
                    UserHelper.SALES_REP_ROLE
                }, currentUser);
                if (approversIdList.size() > 0) {
                    finalApproversList.add(approversIdList[0]);
                }

                for (Integer i = 1; i < quoteIdToSpecialApproverMap.get(currentQuote.Id); i++) {
                    if (specialApproversMap.get(i) != null) {
                        finalApproversList.add(specialApproversMap.get(i).Approver_Id__c);
                    }
                }
                for (Integer i = 0; i < finalApproversList.size(); i++) {
                    currentQuote.put('Level_' + (i + 1) + '_Approver__c', finalApproversList[i]);
                }

                if (currentQuote.Level_1_Approver__c != null) {
                    currentQuote.Approved_Status__c = 'Required';
                } else {
                    currentQuote.Approved_Status__c = 'Approved';
                }

                quotesToUpdate.add(currentQuote);
            }
        }

        return quotesToUpdate;
    }

    private static List<Quote> findApproversByHierarchyRoles(
        Map<Id, List<String>> quoteIdToHRListMap,
        Map<Id, List<String>> quoteIdToHRListMap_Full,
        Map<Id, Quote> quotesMap,
        Map<Id, List<QuoteLineItem>> quoteIdToQliListMap
    ) {
        Map<Id, Quote> quotesToUpdateMap = new Map<Id, Quote>();
        List<Id> queueIds = collectQueueIds(Custom_GOA__c.getAll().values());
        Map<Id, List<Id>> queueIdToUserIdMap = fetchQueueMembers(queueIds);
        Map<Id, Opportunity> oppMap = quoteOpportunity(quotesMap.values());

        for (Id quoteId : quoteIdToHRListMap.keySet()) {
            Quote qt = quotesMap.get(quoteId);
            if (QuoteHelper.isMigrationFlow(qt, UserInfo.getUserId())) {
                continue;
            }

            System.debug('quoteId >>>>> ' + quoteId);
            Quote currentQuote = quotesMap.get(quoteId);
            if (currentQuote != null && RT_IDS_DONT_RECALCULATE_APPROVER_LEVELS.contains(currentQuote.RecordTypeId)) {
                continue;
            }

            Id startedSearchUserId;
            String currentQuoteRecordTypeName = currentQuote.RecordTypeId == null ? null : QuoteHelper.RT_INFO_BY_ID.get(currentQuote.RecordTypeId).getName();
            if (currentQuoteRecordTypeName == QuoteHelper.RT_NAME_SALES || currentQuoteRecordTypeName == QuoteHelper.RT_NAME_BILLING) {
                // it is SalesQuote use opportunityOwner as user who start search approvers.
                startedSearchUserId = quoteIdToOpportunityOwnerIdStaticMap.get(currentQuote.Id);
                System.debug('get userId from staticMap. currentQuote.Id >> ' + currentQuote.Id);
                System.debug('quoteIdToOpportunityOwnerIdStaticMap >> ' + quoteIdToOpportunityOwnerIdStaticMap);
            } else {
                // it is not SalesQuote use currentUser as user who start search approvers.
                startedSearchUserId = UserInfo.getUserId();
                System.debug('get userId from userInfo. startedSearchUserId >> ' + startedSearchUserId);
            }

            User startedSearchUser = ApproversSearch.findUserById(startedSearchUserId);
            System.debug('startedSearchUserId >>>> ' + startedSearchUserId);
            System.debug('startedSearchUser >>>> ' + startedSearchUser);

            String startedSearchUserHRole = startedSearchUser.Hierarchy_Role__c;
            System.debug('startedSearchUserHRole >>>> ' + startedSearchUserHRole);

            Boolean isSuitableRole = ApproversSearch.isSuitableHierarchyRole(startedSearchUserHRole);
            System.debug('isSuitableRole >>>> ' + isSuitableRole);

            if (startedSearchUserHRole == null || !isSuitableRole) {
                startedSearchUserHRole = UserHelper.SALES_REP_ROLE;
            }

            List<String> roleList = quoteIdToHRListMap.get(quoteId);
            roleList = sortRoleList(roleList);

            Boolean isPRMQuote = currentQuote.IsPRMQuote__c && QuoteHelper.isNewBusiness(currentQuote);

            String lastApprover = roleList.get(roleList.size() - 1);
            Boolean lastApproverEqualToCurrentUserHRole = (lastApprover == startedSearchUserHRole);

            Integer startedSearchUserHRoleProirity = UserHelper.hierarchyRolesNameToOrderMap.get(startedSearchUserHRole);
            Integer lastApproverHRoleProirity = UserHelper.hierarchyRolesNameToOrderMap.get(lastApprover);
            Boolean startedSearchUserHRoleIsHigherThanLastApprover = startedSearchUserHRoleProirity > lastApproverHRoleProirity;

            String approvalStatus = '';

            if (isPRMQuote || lastApproverEqualToCurrentUserHRole || startedSearchUserHRoleIsHigherThanLastApprover) {
                approvalStatus = QuoteHelper.APPROVAL_STATUS_APPROVED;
                Boolean quoteHasDiscount = isQuoteHasDiscounts(currentQuote.Id, quoteIdToQliListMap);

                if (!quoteHasDiscount) {
                    // we had "Approved" status and we dont have any discounts. clear level_#_approver fields
                    currentQuote.Level_1_Approver__c = null;
                    currentQuote.Level_2_Approver__c = null;
                    currentQuote.Level_3_Approver__c = null;
                    currentQuote.Level_4_Approver__c = null;
                    currentQuote.Level_5_Approver__c = null;
                    currentQuote.Level_6_Approver__c = null;
                    currentQuote.Level_7_Approver__c = null;
                } else {
                    // check we need or not update approverLevels - for doing this - run setApproverLevels, but with roleList getting from quoteIdToHRListMap_Full
                    List<String> roleListFull = quoteIdToHRListMap_Full.get(quoteId);
                    String lastApproverFull = roleListFull.get(roleListFull.size() - 1);
                    Quote clonedQuote = currentQuote.clone(true, true);
                    clonedQuote = setApproverLevels(roleListFull, startedSearchUserId, startedSearchUserHRole, startedSearchUserHRoleProirity, clonedQuote, queueIdToUserIdMap, oppMap);

                    // now check approverLevels on currentQuote and on clonedQuote
                    // if clonedQuote has less approverLevels than currentQuote - set ApproverLevels as on clonedQuote
                    Boolean isApprovalLevelsChanged = isApprovalLevelsUpdated(currentQuote, clonedQuote);

                    if (isApprovalLevelsChanged) {
                        currentQuote.Level_1_Approver__c = clonedQuote.Level_1_Approver__c;
                        currentQuote.Level_2_Approver__c = clonedQuote.Level_2_Approver__c;
                        currentQuote.Level_3_Approver__c = clonedQuote.Level_3_Approver__c;
                        currentQuote.Level_4_Approver__c = clonedQuote.Level_4_Approver__c;
                        currentQuote.Level_5_Approver__c = clonedQuote.Level_5_Approver__c;
                        currentQuote.Level_6_Approver__c = clonedQuote.Level_6_Approver__c;
                        currentQuote.Level_7_Approver__c = clonedQuote.Level_7_Approver__c;

                        // update lastApprover(Approval_Type__c)
                        currentQuote.Approval_Type__c = lastApproverFull;
                    }
                }
            } else {
                approvalStatus = QuoteHelper.APPROVAL_STATUS_REQUIRED;
                // if status is required - update lastApprover(Approval_Type__c)
                currentQuote.Approval_Type__c = lastApprover;
            }

            currentQuote.Approved_Status__c = approvalStatus;

            if (approvalStatus == QuoteHelper.APPROVAL_STATUS_REQUIRED) {
                if (currentQuote.RecordTypeId == QuoteHelper.RT_ID_CC || currentQuote.RecordTypeId == QuoteHelper.RT_ID_BILLING) {
                    // for billing quote we should check 2 quotes - RT_ID_BILLING and RT_ID_CC(if exist)
                    // so set approver lvls list based on full(unfiltered and with qlis from both quotes) RoleList
                    List<String> roleListFull = sortRoleList(quoteIdToHRListMap_Full.get(quoteId));
                    currentQuote = setApproverLevels(roleListFull, startedSearchUserId, startedSearchUserHRole, startedSearchUserHRoleProirity, currentQuote, queueIdToUserIdMap, oppMap);
                } else {
                    currentQuote = setApproverLevels(roleList, startedSearchUserId, startedSearchUserHRole, startedSearchUserHRoleProirity, currentQuote, queueIdToUserIdMap, oppMap);
                }
            }

            quotesToUpdateMap.put(currentQuote.Id, currentQuote);
        }

        return quotesToUpdateMap.values();
    }

    private static Boolean isSVPNeededApproval(Quote currentQuote) {
        system.debug('METHOD FOR isSVPNeededApproval');
        Boolean isNeededApproval = false;
        Boolean validTCV = (currentQuote.Total_First_Year_Cost__c > 1000000) ? true : false;
        system.debug('validTCV? ' + validTCV);
        Boolean isChangeOrder = getOrderType(currentQuote.Id) == CHANGE_ORDER ? true : false;
        system.debug('isChangeOrder? ' + isChangeOrder);

        for (QuoteLineItem qli : currentQuote.QuoteLineItems) {
            if (currentQuote.Package_Info__c != null && ((validTCV && isChangeOrder && qli.Discount > 50)
                || (isChangeOrder && qli.Discount > 60))) {
                String GOA_Products_SVP = label.GOA_Products_SVP;
                List<String> pList = GOA_Products_SVP.split(',');
                List<BillingWrappers.QuotePackageInfo> pInfos =
                    (List<BillingWrappers.QuotePackageInfo>)
                        JSON.deserialize(
                            currentQuote.Package_Info__c,
                            List<BillingWrappers.QuotePackageInfo>.class
                        );
                BillingWrappers.QuotePackageInfo pInfo = pInfos[0];

                String goaGroup = '';
                if (qli.product2.GOA_Group_V3__c != null) {
                    try {
                        goaGroup = QuoteLineItemHelper.parseOldFormatGOA(qli, pInfo);
                    } catch (JSONException e) {
                        goaGroup = QuoteLineItemHelper.parseNewFormatGOA(qli, pInfo);
                    }
                } else {
                    goaGroup = (qli.product2.GOA_Group_V2__c != null) ? qli.product2.GOA_Group_V2__c : qli.product2.GOA_Group__c;
                }
                system.debug('goaGroup: ' + goaGroup);
                if (pList.contains(goaGroup)) {
                    isNeededApproval = true;
                }
            }
        }
        system.debug('return isNeededSVPApproval: ' + isNeededApproval);
        return isNeededApproval;
    }

    public static Map<Id, List<Custom_GOA__c>> getMatchingGOAs(
        Quote qt
    ) {
        return getMatchingGOAs(new List<Quote>{
            qt
        });
    }

    public static Map<Id, List<Custom_GOA__c>> getMatchingGOAs(
        List<Quote> quotes
    ) {
        return getMatchingGOAs(quotes, quoteOpportunity(quotes));
    }

    public static Map<Id, List<Custom_GOA__c>> getMatchingGOAs(
        Quote qt,
        Map<Id, Opportunity> oppMap
    ) {
        return getMatchingGOAs(new List<Quote>{
            qt
        }, oppMap);
    }

    public static Map<Id, List<Custom_GOA__c>> getMatchingGOAs(
        List<Quote> quotes,
        Map<Id, Opportunity> oppMap
    ) {
        List<Custom_GOA__c> customGOAs = Custom_GOA__c.getall().values();
        Map<Id, List<Custom_GOA__c>> matchingGOAsByQuoteId = new Map<Id, List<Custom_GOA__c>>();

        if (customGOAs.isEmpty()) {
            return matchingGOAsByQuoteId;
        }

        for (Quote currentQuote : quotes) {
            String brand = oppMap.get(currentQuote.OpportunityId).Brand_Name__c;
            String oppRecordType = oppMap.get(currentQuote.OpportunityId).RecordTypeName__c;
            String ownerSegment = oppMap.get(currentQuote.OpportunityId).Opportunity_Owner_Segment__c != null ? oppMap.get(currentQuote.OpportunityId).Opportunity_Owner_Segment__c : '';
            String ownerRegion = oppMap.get(currentQuote.OpportunityId).Opportunity_Owner_Region__c != null ? oppMap.get(currentQuote.OpportunityId).Opportunity_Owner_Region__c.toUpperCase() : '';
            String ownerSubregion = oppMap.get(currentQuote.OpportunityId).Owner.Sub_Region__c != null ? oppMap.get(currentQuote.OpportunityId).Owner.Sub_Region__c.toUpperCase() : '';
            Boolean isPRMQuote = currentQuote.IsPRMQuote__c;

            for (Custom_GOA__c goa : customGOAs) {
                List<String> brandList = String.isNotBlank(goa.Opportunity_Brand__c) ? goa.Opportunity_Brand__c.split(',') : new List<String>();
                List<String> oppRecordTypeList = String.isNotBlank(goa.Opportunity_Recordtype__c) ? goa.Opportunity_Recordtype__c.split(',') : new List<String>();
                List<String> oppOwnerSegmentList = String.isNotBlank(goa.Opportunity_Owner_Segment__c) ? goa.Opportunity_Owner_Segment__c.split(',') : new List<String>();
                List<String> regionList = String.isNotBlank(goa.Opportunity_Owner_Region__c) ? goa.Opportunity_Owner_Region__c.split(',') : new List<String>();
                List<String> subregionList = String.isNotBlank(goa.Opportunity_Owner_Subregion__c) ? goa.Opportunity_Owner_Subregion__c.split(',') : new List<String>();

                Boolean isPrmGoa = goa.IsEnabledForPRM__c;

                Boolean isBrandMatch = true;
                Boolean isRecordTypeMatch = true;
                Boolean isOwnerSegmentMatch = true;
                Boolean isRegionMatch = true;
                Boolean isSubregionMatch = true;
                Boolean isPRMMatch = true;

                if (!brandList.isEmpty()) {
                    isBrandMatch = brandList.contains(brand);
                }

                if (!oppRecordTypeList.isEmpty()) {
                    isRecordTypeMatch = oppRecordTypeList.contains(oppRecordType);
                }

                if (!oppOwnerSegmentList.isEmpty()) {
                    isOwnerSegmentMatch = oppOwnerSegmentList.contains(ownerSegment);
                }

                if (!regionList.isEmpty()) {
                    isRegionMatch = regionList.contains(ownerRegion);
                }

                if (!subregionList.isEmpty()) {
                    isSubregionMatch = subregionList.contains(ownerSubregion);
                }

                if (isPrmGoa) {
                    isPRMMatch = isPRMQuote;
                }

                if (isBrandMatch && isRecordTypeMatch && isOwnerSegmentMatch && isRegionMatch && isSubregionMatch && isPRMMatch) {
                    if (matchingGOAsByQuoteId.containsKey(currentQuote.Id)) {
                        matchingGOAsByQuoteId.get(currentQuote.Id).add(goa);
                    } else {
                        matchingGOAsByQuoteId.put(currentQuote.Id, new List<Custom_GOA__c>{
                            goa
                        });
                    }
                }
            }
        }

        return matchingGOAsByQuoteId;
    }

    private static final List<SObjectField> approverFields = new List<SObjectField>{
        Custom_GOA__c.L1_Approver__c,
        Custom_GOA__c.L2_Approver__c,
        Custom_GOA__c.L3_Approver__c,
        Custom_GOA__c.L4_Approver__c
    };

    public static Map<Id, List<Id>> collectQueueIdsByQuoteIds(Map<Id, List<Custom_GOA__c>> goasByQuoteId) {
        Map<Id, List<Id>> queueIdsByQuoteId = new Map<Id, List<Id>>();

        if (goasByQuoteId.isEmpty()) {
            return queueIdsByQuoteId;
        }

        for (Id quoteId : goasByQuoteId.keySet()) {
            List<Custom_GOA__c> goas = goasByQuoteId.get(quoteId);
            List<Id> queueIds = collectQueueIds(goas);
            queueIdsByQuoteId.put(quoteId, queueIds);
        }

        return queueIdsByQuoteId;
    }

    public static List<Id> collectQueueIds(List<Custom_GOA__c> customGOAs) {
        List<Id> queueIds = new List<Id>();

        if (customGOAs.isEmpty()) {
            return queueIds;
        }

        for (Custom_GOA__c goa : customGOAs) {
            for (SObjectField f : approverFields) {
                Id approverId = (Id) goa.get(f);
                if (approverId != null) {
                    if (String.isNotBlank(approverId) && approverId.getSobjectType() == Group.SObjectType) {
                        queueIds.add(approverId);
                    }
                }
            }
        }

        return queueIds;
    }

    public static Map<Id, List<Id>> fetchQueueMembers(Map<Id, List<Id>> queueIdByQuoteId) {
        List<Id> queueIds = new List<Id>();
        if (queueIdByQuoteId.isEmpty()) {
            return new Map<Id, List<Id>>();
        }

        for (List<Id> ids : queueIdByQuoteId.values()) {
            queueIds.addAll(ids);
        }

        return fetchQueueMembers(queueIds);
    }

    public static Map<Id, List<Id>> fetchQueueMembers(List<Id> queueIds) {
        if (queueIds.isEmpty()) {
            return new Map<Id, List<Id>>();
        }

        List<GroupMember> gms = [
            SELECT Id, GroupId, Group.Type, UserOrGroupId
            FROM GroupMember
            WHERE GroupId IN :queueIds
        ];

        return fetchQueueMembers(queueIds, gms);
    }

    public static Map<Id, List<Id>> fetchQueueMembers(List<Id> queueIds, List<GroupMember> gms) {
        Map<Id, List<Id>> queueIdToUserIdsMap = new Map<Id, List<Id>>();

        if (queueIds.isEmpty()) {
            return queueIdToUserIdsMap;
        }

        for (GroupMember gm : gms) {
            if (gm.Group.Type != 'Queue') {
                continue;
            }

            if (gm.UserOrGroupId.getSobjectType() != User.SObjectType) {
                continue;
            }

            if (queueIdToUserIdsMap.get(gm.GroupId) == null) {
                queueIdToUserIdsMap.put(gm.GroupId, new List<Id>());
            }

            queueIdToUserIdsMap.get(gm.GroupId).add((Id) gm.UserOrGroupId);
        }

        return queueIdToUserIdsMap;
    }

    //For custom ApproverId list
    private static List<Id> getCustomApproversList(
        Quote currentQuote,
        List<Id> approversIdList,
        String startedSearchUserHRole,
        Map<Id, List<Id>> queueIdToUserIdsMap,
        Map<Id, Opportunity> oppMap
    ) {
        List<Id> newApproversList = new List<Id>();
        List<Custom_GOA__c> customGOASettings = Custom_GOA__c.getall().values();

        if (customGOASettings.isEmpty()) {
            return newApproversList;
        }

        List<Id> goaSettingApprovers = new List<Id>();
        String approvalType = currentQuote.Approval_Type__c;

        Map<Id, List<Custom_GOA__c>> matchingGoasMap = getMatchingGOAs(currentQuote, oppMap);
        List<Custom_GOA__c> matchingGoas = matchingGoasMap.containsKey(currentQuote.Id)
            ? matchingGoasMap.get(currentQuote.Id)
            : new List<Custom_GOA__c>();

        for (Custom_GOA__c goa : matchingGoas) {
            String goaType = goa.Name;

            if (goaType.containsIgnoreCase('JennyDingus')) {
                currentQuote.JD_GOA__c = true;
            }

            for (SObjectField f : approverFields) {
                Id approverId = (Id) goa.get(f);
                if (approverId != null) {
                    if (approverId.getSobjectType() == Group.SObjectType) {
                        Id u = queueIdToUserIdsMap.get(approverId).get(
                            NumberHelper.getRandomNumberInRange(0, queueIdToUserIdsMap.get(approverId).size() - 1)
                        );
                        goaSettingApprovers.add(u);
                    } else {
                        goaSettingApprovers.add(approverId);
                    }
                } else {
                    if (f == Custom_GOA__c.L1_Approver__c) {
                        goaSettingApprovers.add(approversIdList[0]);
                    } else {
                        goaSettingApprovers.add(null);
                    }
                }
            }

            Map<String, Integer> roleMap = new Map<String, Integer>();
            roleMap.put(UserHelper.SALES_REP_ROLE, 0);
            roleMap.put(UserHelper.DIRECT_MANAGER_ROLE, 1);
            roleMap.put(UserHelper.SEGMENT_LEADER_ROLE, 2);
            roleMap.put(UserHelper.SVP_WWS_DIRECTS_ROLE, 3);
            roleMap.put(UserHelper.SVP_WWS_ROLE, 4);

            String oppOwnerRole = startedSearchUserHRole != null ? startedSearchUserHRole : UserHelper.SALES_REP_ROLE;
            Integer firstRoleIndex = roleMap.get(oppOwnerRole) + 1;
            Integer lastRoleIndex = roleMap.get(approvalType);

            for (Integer i = (firstRoleIndex); i <= (lastRoleIndex); i++) {
                newApproversList.add(goaSettingApprovers[i - 1]);
            }
            if (goaType.containsIgnoreCase('ACOUpsell')) {
                newApproversList.remove(0);
            }
        }
        return newApproversList;
    }

    private static Map<Id, Opportunity> quoteOpportunity(List<Quote> quotes) {
        Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>();

        if (quotes == null || quotes.isEmpty()) {
            return oppMap;
        }

        Set<Id> oppIds = new Set<Id>();
        for (Quote q : quotes) {
            if (String.isNotBlank(q.OpportunityId)) {
                oppIds.add(q.OpportunityId);
            }
        }

        oppMap.putAll([
            SELECT
                Id, OwnerId, Type, RecordTypeName__c,
                Owner.SegmentPicklist__c, Owner.Region__c, Owner.Sub_Region__c,
                Brand_Name__c, Opportunity_Owner_Segment__c, Opportunity_Owner_Region__c
            FROM Opportunity
            WHERE Id IN :oppIds
        ]);

        system.debug('oppMap: ' + oppMap);
        return oppMap;
    }


    private static Quote setApproverLevels(
        List<String> roleList,
        Id startedSearchUserId,
        String startedSearchUserHRole,
        Integer startedSearchUserHRoleProirity,
        Quote currentQuote,
        Map<Id, List<Id>> queueIdToUserIdsMap,
        Map<Id, Opportunity> oppMap
    ) {
        ApproversSearch approversSearcher = new ApproversSearch();
        // populate approvers on the Quote
        List<Map<Id, String>> userIdToHRMapsList = approversSearcher.findManagersByRoleName(roleList, startedSearchUserId);
        List<Id> approversIdList = approversSearcher.buildApproversIdList(userIdToHRMapsList, roleList, startedSearchUserHRole, startedSearchUserHRoleProirity);

        System.debug('Feature_Toggle__c.getInstance().Bypass_GOA_SVP_Approval__c >>> ' + Feature_Toggle__c.getInstance().Bypass_GOA_SVP_Approval__c);
        System.debug('Feature_Toggle__c.getInstance().Bypass_GOA_for_Expansion_AE__c >>> ' + Feature_Toggle__c.getInstance().Bypass_GOA_for_Expansion_AE__c);
        if (Feature_Toggle__c.getInstance().Bypass_GOA_SVP_Approval__c) {
            Boolean isSVPValid = isSVPNeededApproval(currentQuote);
            system.debug('isSVPValid? ' + isSVPValid);
            RingCentralVariousSettings__c settings = RingCentralVariousSettings__c.getInstance();
            Id svpUserId = settings.SVP_WWS_User_ID__c;
            system.debug('svpUserId: ' + svpUserId);
            Boolean needApproval = approversIdList.size() > 1;

            for (Integer i = (approversIdList.size() - 1); i >= 0; i--) {
                String s = approversIdList[i];
                if (svpUserId != null && isSVPValid != null && needApproval != null) {
                    if (s.contains(svpUserId) && !isSVPValid && needApproval) {
                        approversIdList.remove(i);
                    }
                }
            }
            if (!approversIdList.contains(svpUserId) && isSVPValid) {
                approversIdList.add(svpUserId);
            }

            system.debug('approversIdListv2: ' + approversIdList);
        }

        //custom approver id
        if (approversIdList.size() > 0) {
            List<Id> newApprovers = getCustomApproversList(
                currentQuote,
                approversIdList,
                startedSearchUserHRole,
                queueIdToUserIdsMap,
                oppMap
            );
            if (newApprovers.size() > 0) {
                approversIdList.clear();
                approversIdList.addAll(newApprovers);
            }
            system.debug('approversIdList NEW: ' + approversIdList);
        }

        if (ApproversSearch.defaultApproverIsNeeded && ApproversSearch.defaultApprover != null) {
            Id lastApproverId = approversIdList.get(approversIdList.size() - 1);
            if (lastApproverId == ApproversSearch.defaultApprover.Id && currentQuote.Approval_Type__c != UserHelper.SVP_WWS_ROLE) {
                // we already found ryanAzus and add him to approverIdList - set SVP_WWS_ROLE in ApprovalType.
                currentQuote.Approval_Type__c = UserHelper.SVP_WWS_ROLE;
            }
        }

        if (ApproversSearch.checkIsFoundRoleHigherThanLastApprover(userIdToHRMapsList, roleList)) {
            // if we found Hierarchy role that higher than lastApprover - update quote.lastApprover field(Quote.Approval_Type__c)
            List<String> lastFoundedRolesList = userIdToHRMapsList.get(userIdToHRMapsList.size() - 1).values();
            String lastFoundedRole = lastFoundedRolesList.get(lastFoundedRolesList.size() - 1);

            if (currentQuote.Approval_Type__c != lastFoundedRole) {
                currentQuote.Approval_Type__c = lastFoundedRole;
            }
        }

        System.debug('approversIdList.size() >>> ' + approversIdList.size());

        if (!approversIdList.isEmpty()) {
            // fill Level_#_Approver__c fields
            for (Integer i = 0; i < approversIdList.size(); i++) {
                currentQuote.put('Level_' + (i + 1) + '_Approver__c', approversIdList.get(i));
            }

            // clear other Level_#_Approver__c fields
            // we have max 5 level of approvers
            Integer fieldsCountToClear = QuoteHelper.MAX_APPROVER_LEVELS - approversIdList.size();
            for (Integer i = 0; i < fieldsCountToClear; i++) {
                currentQuote.put('Level_' + (QuoteHelper.MAX_APPROVER_LEVELS - i) + '_Approver__c', null);
            }
        } else {
            // we have no approvers - clear Level_#_Approver__c fields
            // we have max 5 level of approvers
            Integer fieldsCountToClear = QuoteHelper.MAX_APPROVER_LEVELS - approversIdList.size();
            for (Integer i = 0; i < fieldsCountToClear; i++) {
                currentQuote.put('Level_' + (QuoteHelper.MAX_APPROVER_LEVELS - i) + '_Approver__c', null);
            }
        }
        currentQuote.put('Level_5_Approver__c', null);
        return currentQuote;
    }

    private static Boolean isApprovalLevelsUpdated(Quote q1, Quote q2) {
        Boolean isLevel1Equal = q1.Level_1_Approver__c == q2.Level_1_Approver__c;
        Boolean isLevel2Equal = q1.Level_2_Approver__c == q2.Level_2_Approver__c;
        Boolean isLevel3Equal = q1.Level_3_Approver__c == q2.Level_3_Approver__c;
        Boolean isLevel4Equal = q1.Level_4_Approver__c == q2.Level_4_Approver__c;
        Boolean isLevel5Equal = q1.Level_5_Approver__c == q2.Level_5_Approver__c;
        Boolean isLevel6Equal = q1.Level_6_Approver__c == q2.Level_6_Approver__c;
        Boolean isLevel7Equal = q1.Level_7_Approver__c == q2.Level_7_Approver__c;

        return (!isLevel1Equal || !isLevel2Equal || !isLevel3Equal || !isLevel4Equal || !isLevel5Equal || !isLevel6Equal || !isLevel7Equal);
    }

    private static Boolean isQuoteHasDiscounts(Id quoteId, Map<Id, List<QuoteLineItem>> quoteIdToQliListMap) {
        Boolean quoteHasDiscount = false;
        if (quoteId != null && quoteIdToQliListMap != null &&
            quoteIdToQliListMap.containsKey(quoteId)) {

            List<QuoteLineItem> qlisForCurrentQuote = quoteIdToQliListMap.get(quoteId);
            for (QuoteLineItem qli : qlisForCurrentQuote) {
                if (qli.Discount > 0 || qli.Discount_Value__c > 0) {
                    quoteHasDiscount = true;
                }
            }
        }

        return quoteHasDiscount;
    }

    public static Map<String, Set<String>> buildQuoteRTNameToSuitableSubCategoryMap() {
        Map<String, Set<String>> resultMap = new Map<String, Set<String>>();
        Map<String, Products_taken_into_account_in_GOA__c> productsCS = Products_taken_into_account_in_GOA__c.getAll();

        if (productsCS == null) {
            return resultMap;
        }

        for (Products_taken_into_account_in_GOA__c item : productsCS.values()) {
            Set<String> subCategoriesSet = new Set<String>();

            if (item.Sub_Categories__c != null && item.Sub_Categories__c.contains(',')) {
                List<String> splitted = item.Sub_Categories__c.split(',');

                for (String subCategory : splitted) {
                    String trimmed = subCategory.trim();
                    subCategoriesSet.add(trimmed);
                }
            } else {
                String subCategory = item.Sub_Categories__c;
                subCategory = (subCategory == null) ? null : subCategory.trim();
                subCategoriesSet.add(subCategory);
            }

            resultMap.put(item.Quote_Record_Type__c, subCategoriesSet);
        }

        return resultMap;
    }

    private static Map<Id, String> findGOAForQLI(
        List<GOA_V2__c> goasList,
        List<QuoteLineItem> qliList,
        Map<Id, String> accountIdToInitialTermMap,
        Map<Id, Quote> quotesMap
    ) {

        if (goasList == null || qliList == null || qliList.isEmpty()) {
            return new Map<Id, String>();
        }

        /* Assuming that we will have the items for the single quote in this method: qliList */
        String brand;
        if (!QuoteHelper.isPhoenix(new Quote(Id = qliList[0].QuoteId, Package_Info__c = qliList[0].Quote.Package_Info__c))) {
            brand = qliList[0].Quote.Opportunity.Brand_Name__c;
        }

        if (QuoteHelper.isPhoenix(new Quote(Id = qliList[0].QuoteId, Package_Info__c = qliList[0].Quote.Package_Info__c))) {
            if (qliList[0].Quote.Opportunity.Brand_Name__c == RingCentralHelper.BRAND_ATOS) {
                brand = qliList[0].Quote.Opportunity.Brand_Name__c + ' ' + PDFTemplateHelper.PHOENIX;
            } else {
                brand = PDFTemplateHelper.PHOENIX;
            }
        }

        goasList = filterGOAsByBrand(brand, goasList);

        if (goasList == null || goasList.isEmpty()) {
            return new Map<Id, String>();
        }

        Map<String, Set<String>> quoteRTNameToSuitableSubCategoriesMap = buildQuoteRTNameToSuitableSubCategoryMap();
        Map<Id, String> qliIdToApproverRoleName = new Map<Id, String>();
        Boolean isCommissionable = false;
        List<Id> mobileUserIds = new List<Id>();

        for (QuoteLineItem item : qliList) {
            String currentQuoteRTName = item.Quote.RecordTypeId == null ? null : QuoteHelper.RT_INFO_BY_ID.get(item.Quote.RecordTypeId).getName();

            if (quoteRTNameToSuitableSubCategoriesMap.keySet().contains(currentQuoteRTName)) {
                Boolean isSuitableSubCategory = quoteRTNameToSuitableSubCategoriesMap.get(currentQuoteRTName).contains(item.Product2.Sub_Category__c);

                if (!isSuitableSubCategory) {
                    System.debug('found product with not suitable SubCategory: ' + item.Product2.Sub_Category__c + '. bypass them.');
                    continue;
                }
            }

            Double itemDiscount = item.Discount_Value__c == null ? 0 : item.Discount_Value__c;

            if (itemDiscount == 0) {
                // found product with empty discount. bypass them.
                continue;
            }

            if (item.NewQuantity__c == 0) {
                continue;
            }

            if (AccountHelper.isElaService(item.Quote.Account)
                && UserCustomSettingHelper.getELALicenses().contains(item.Product_Lic_Id__c)) {
                // found product under ELA. bypass them.
                continue;
            }

            BillingWrappers.QLIPackageInfo qliPackageInfo = BillingWrappers.parseQLIPackageInfo(item.PackageInfo__c);
            if (qliPackageInfo != null && qliPackageInfo.isCommissionable()) {
                isCommissionable = true;
                continue;
            }

            if (Product2Helper.isMobileUser(item)) {
                mobileUserIds.add(item.id);
            }

            if (item.Product2.GOA_Group_V2__c == null && item.Product2.GOA_Group_V3__c == null) {
                // choose 'SVP WWS Directs'
                qliIdToApproverRoleName = putHierarchyRole(
                    qliIdToApproverRoleName,
                    item.Id,
                    UserHelper.SVP_WWS_DIRECTS_ROLE
                );
            } else {
                // SPLIT GOA GROUPS BY SEGMENT (HAS SEGMENT OR HAS NO SEGMENT)
                Map<String, List<GOA_V2__c>> goasSplitted = splitGOAbySegment(goasList);
                String hRoleFound;

                // If user has Segment__c populated – first try to find GOA in the list of GOAs with populated Segment__c field
                if (!String.isBlank(item.Quote.Opportunity.Owner.SegmentPicklist__c)) {
                    hRoleFound = findApproverRoleForQLI(
                        goasSplitted.get(GOA_SEGMENT_POPULATED),
                        quotesMap,
                        true,
                        item
                    );
                }

                // If user has no Segment__c populated or GOA by segment hasn't been found
                // try to find GOA in the list of GOAs without Segment__c
                if (String.isBlank(hRoleFound)) {
                    hRoleFound = findApproverRoleForQLI(
                        goasSplitted.get(GOA_SEGMENT_NOT_POPULATED),
                        quotesMap,
                        false,
                        item
                    );
                }

                // If still no suitable GOA found in GOA_V2 custom setting – set approver hierarchy role to SVP WWS Directs
                if (String.isBlank(hRoleFound)) {
                    System.debug('no suitable GOA found in GOA_V2 custom setting. set approver hierarchy role to SVP WWS Directs');
                    hRoleFound = UserHelper.SVP_WWS_DIRECTS_ROLE;
                }

                qliIdToApproverRoleName = putHierarchyRole(qliIdToApproverRoleName, item.Id, hRoleFound);
            }
        }

        if (isCommissionable && !mobileUserIds.isEmpty()) {
            for (Id mobileUserId : mobileUserIds) {
                qliIdToApproverRoleName.remove(mobileUserId);
            }
        }

        return qliIdToApproverRoleName;
    }

    // SPLIT GOA GROUPS BY SEGMENT (HAS SEGMENT OR HAS NO SEGMENT)
    private static Map<String, List<GOA_V2__c>> splitGOAbySegment(List<GOA_V2__c> goas) {
        Map<String, List<GOA_V2__c>> goasSplitted = new Map<String, List<GOA_V2__c>>{
            GOA_SEGMENT_POPULATED => new List<GOA_V2__c>(),
            GOA_SEGMENT_NOT_POPULATED => new List<GOA_V2__c>()
        };

        for (GOA_V2__c goa : goas) {
            if (String.isNotBlank(goa.Segment__c)) {
                goasSplitted.get(GOA_SEGMENT_POPULATED).add(goa);
            } else {
                goasSplitted.get(GOA_SEGMENT_NOT_POPULATED).add(goa);
            }
        }

        return goasSplitted;
    }

    @TestVisible
    /* Filter the goa groups by the brand. If there is no goas found for the corresponding brand
     * use the default ones with the empty brand field.
     * If there is at least one goa group with the brand specified, only groups with those brand will be processed. */
    private static List<GOA_V2__c> filterGOAsByBrand(String brand, List<GOA_V2__c> goasList) {
        Map<String, List<GOA_V2__c>> goasByBrand = new Map<String, List<GOA_V2__c>>();

        for (GOA_V2__c goa : goasList) {
            if (!goasByBrand.containsKey(goa.Brand__c)) {
                goasByBrand.put(goa.Brand__c, new List<GOA_V2__c>());
            }
            goasByBrand.get(goa.Brand__c).add(goa);
        }

        return goasByBrand.get(goasByBrand.containsKey(brand) ? brand : null);
    }

    private static String findApproverRoleForQLI(
        List<GOA_V2__c> goasList,
        Map<Id, Quote> quotesMap,
        Boolean isWithSegmentSearch,
        QuoteLineItem qliChecked
    ) {
        String hRoleName;
        Double itemDiscount = qliChecked.Discount_Value__c == null ? 0 : qliChecked.Discount_Value__c;

        for (GOA_V2__c goa : goasList) {
            Range quantityRange = new Range(goa.Quantity_Range__c, '-');

            // If GOA from custom setting has 'Percentage' currency we should take Discount from QuoteLineItem.Discount
            if (goa.Currency__c == PERCENTAGE_GOA_CURRENCY) {
                itemDiscount = qliChecked.Discount;
            } else {
                itemDiscount = qliChecked.Discount_Value__c == null ? 0 : qliChecked.Discount_Value__c;
            }

            // Check whether GOA's Segment__c field contains User's Segment__c.
            // If isWithSegmentSearch – we are not checking the segment while searching for an appropriate GOA entry
            Boolean isUserSegmentMatches = false;
            if (isWithSegmentSearch) {
                Set<String> goaSegments = new Set<String>();

                for (String s : goa.Segment__c.split(';')) {
                    goaSegments.add(s.trim().toLowerCase());
                }

                if (!goaSegments.isEmpty()) {
                    isUserSegmentMatches = goaSegments.contains(
                        qliChecked.Quote.Opportunity.Owner.SegmentPicklist__c.toLowerCase()
                    );
                }

                if (!isUserSegmentMatches) {
                    continue;
                }
            } else {
                isUserSegmentMatches = true;
            }

            Boolean isQuantityInRange = (Decimal) NumberHelper.getNumberNullSafe(qliChecked.NewQuantity__c) > 0 ? quantityRange.isInRange(qliChecked.NewQuantity__c) : true;
            Boolean isCurrencyMatch = goa.Currency__c == qliChecked.CurrencyIsoCode || goa.Currency__c == PERCENTAGE_GOA_CURRENCY;
            Boolean isPRMMatch = goa.IsEnabledForPRM__c ? qliChecked.Quote.IsPRMQuote__c : !qliChecked.Quote.IsPRMQuote__c;

            System.debug('quantity range ' + goa.Quantity_Range__c + ' check: ' + qliChecked.NewQuantity__c);
            System.debug(isQuantityInRange);
            if (isQuantityInRange && isCurrencyMatch && isPRMMatch) {
                // discounts
                List<Range> rangeList = new List<Range>();

                // salesRep
                Range salesRepDiscounts = new Range(goa.Sales_Rep__c, '-', UserHelper.SALES_REP_ROLE);
                rangeList.add(salesRepDiscounts);
                System.debug('salesRep range ' + goa.Sales_Rep__c + ' check: ' + itemDiscount);
                System.debug(salesRepDiscounts.isInRange(itemDiscount));

                // direct manager
                Range directManagerDiscounts = new Range(goa.Direct_Manager__c, '-', UserHelper.DIRECT_MANAGER_ROLE);
                rangeList.add(directManagerDiscounts);
                System.debug('direct manager ' + goa.Direct_Manager__c + ' range check: ' + itemDiscount);
                System.debug(directManagerDiscounts.isInRange(itemDiscount));

                // segment leader
                Range segmentLeaderDiscounts = new Range(goa.Segment_Leader__c, '-', UserHelper.SEGMENT_LEADER_ROLE);
                rangeList.add(segmentLeaderDiscounts);
                System.debug('segment leader ' + goa.Segment_Leader__c + ' range check: ' + itemDiscount);
                System.debug(segmentLeaderDiscounts.isInRange(itemDiscount));

                // svp wws directs
                Range swpWwsDirectsDiscounts = new Range(goa.SVP_WWS_Directs__c, '-', UserHelper.SVP_WWS_DIRECTS_ROLE);
                rangeList.add(swpWwsDirectsDiscounts);
                System.debug('swp wws directs ' + goa.SVP_WWS_Directs__c + ' range check: ' + itemDiscount);
                System.debug(swpWwsDirectsDiscounts.isInRange(itemDiscount));

                // svp wws
                Range swpWwsDiscounts = new Range(goa.SVP_WWS__c, '-', UserHelper.SVP_WWS_ROLE);
                rangeList.add(swpWwsDiscounts);
                System.debug('swp wws  ' + goa.SVP_WWS__c + ' range check: ' + itemDiscount);
                System.debug(swpWwsDiscounts.isInRange(itemDiscount));

                Boolean discountFitsInRanges = salesRepDiscounts.isInRange(itemDiscount) || directManagerDiscounts.isInRange(itemDiscount) ||
                    segmentLeaderDiscounts.isInRange(itemDiscount) || swpWwsDirectsDiscounts.isInRange(itemDiscount) ||
                    swpWwsDiscounts.isInRange(itemDiscount);

                String pkgInfo = quotesMap != null ? quotesMap.get(qliChecked.QuoteId).Package_Info__c : qliChecked.Quote.Package_Info__c;

                // group
                Boolean groupFound = false;
                if (String.isBlank(qliChecked.Product2.GOA_Group_V3__c)) {
                    groupFound = qliChecked.Product2.GOA_Group_V2__c == goa.Group__c;
                } else {
                    List<BillingWrappers.QuotePackageInfo> pInfos =
                        (List<BillingWrappers.QuotePackageInfo>)
                            JSON.deserialize(
                                pkgInfo,
                                List<BillingWrappers.QuotePackageInfo>.class
                            );
                    BillingWrappers.QuotePackageInfo pInfo = pInfos[0];

                    String goaGroup = '';
                    try {
                        goaGroup = QuoteLineItemHelper.parseOldFormatGOA(qliChecked, pInfo);
                    } catch (JSONException e) {
                        goaGroup = QuoteLineItemHelper.parseNewFormatGOA(qliChecked, pInfo);
                    }

                    Boolean editionMatch = String.isBlank(goa.Edition__c)
                        ? true
                        : (pInfo.edition.name == goa.Edition__c);

                    groupFound = (goaGroup == goa.Group__c) && editionMatch;
                }

                System.debug('groupFound >>> ' + groupFound);

                if (discountFitsInRanges && groupFound) {
                    String contractInitialTerm = '';
                    String plan = QuoteHelper.getPlan(qliChecked.Quote);
                    if (qliChecked.Quote.Upsell_Status__c == 'New' && plan == 'Monthly - Contract') {

                        if (quotesMap != null) {
                            // we can get quotes map from Quote trigger
                            Quote q = quotesMap.get(qliChecked.QuoteId);
                            contractInitialTerm = q.Initial_Term_months__c;
                        } else {
                            contractInitialTerm = qliChecked.Quote.Initial_Term_months__c;
                        }

                    } else if (qliChecked.Quote.Upsell_Status__c == 'New' && plan == 'Annual') {
                        contractInitialTerm = '12';
                    } else if (qliChecked.Quote.Upsell_Status__c != 'New') {
                        System.debug('find Initial_Term_months__c >> ' + qliChecked.Quote.Initial_Term_months__c);
                        String initialTerm = qliChecked.Quote.Initial_Term_months__c;
                        System.debug('initialTerm >> ' + initialTerm);
                        contractInitialTerm = (String.isBlank(initialTerm) && plan == 'Annual')
                            ? '12'
                            : initialTerm;

                        if (initialTerm == null) {
                            System.debug('cannot find contract initialTerm by Initial_Term_months__c. >> ' + qliChecked.Quote.Initial_Term_months__c);
                        }
                    } else {
                        contractInitialTerm = null;
                    }

                    if (goa.Contract_Initial_Term_Range__c != null && contractInitialTerm != null) {
                        Range contractInitialTermRange = new Range(goa.Contract_Initial_Term_Range__c, '-', 'ContractInitialTerm');

                        System.debug('contractInitialTerm >>> ' + contractInitialTerm);
                        System.debug('contractInitialTermRange.isInRange(contractInitialTerm) >>> ' + contractInitialTermRange.isInRange(contractInitialTerm));

                        if (contractInitialTermRange.isInRange(contractInitialTerm)) {
                            hRoleName = findHierarcyRoleByDiscountRange(rangeList, itemDiscount);
                            break;
                        }
                    } else {
                        hRoleName = findHierarcyRoleByDiscountRange(rangeList, itemDiscount);
                        System.debug('hRoleName >>> ' + hRoleName);
                        System.debug('qliChecked.Id >>> ' + qliChecked.Id);
                    }
                }
            }
        }

        return hRoleName;
    }

    private static Map<Id, String> putHierarchyRole(Map<Id, String> qliIdToApproverRoleName, Id qliId, String hRoleName) {
        if (qliIdToApproverRoleName == null) {
            qliIdToApproverRoleName = new Map<Id, String>();
        }

        if (String.isBlank(hRoleName)) {
            return qliIdToApproverRoleName;
        }

        if (String.isBlank(qliIdToApproverRoleName.get(qliId))) {
            qliIdToApproverRoleName.put(qliId, hRoleName);
        } else {
            String prevFoundHRole = qliIdToApproverRoleName.get(qliId);
            String highestHRole = chooseHigherOrderRole(
                new Set<String>{
                    hRoleName, prevFoundHRole
                }
            );

            if (highestHRole != null) {
                qliIdToApproverRoleName.put(qliId, highestHRole);
            }
        }

        return qliIdToApproverRoleName;
    }

    private static String findHierarcyRoleByDiscountRange(List<Range> ranges, Double qliDiscount) {
        String resultRolename = '';
        Set<String> suitableRolesSet = new Set<String>();

        for (Range item : ranges) {
            if (item.isInRange(qliDiscount)) {
                resultRolename = item.rangeName;
                suitableRolesSet.add(resultRolename);
            }
        }

        String highestHRole = chooseHigherOrderRole(suitableRolesSet);

        if (String.isNotBlank(highestHRole)) {
            resultRolename = highestHRole;
        }

        return resultRolename;
    }


    public static List<String> sortRoleList(List<String> rolesList) {
        List<Integer> rolesPriorityList = new List<Integer>();

        for (String roleName : rolesList) {
            rolesPriorityList.add(UserHelper.hierarchyRolesNameToOrderMap.get(roleName));
        }

        rolesPriorityList.sort();
        List<String> sortedRoleList = new List<String>();

        for (Integer rolePriority : rolesPriorityList) {
            sortedRoleList.add(UserHelper.hierarchyRolesOrderToNameMap.get(rolePriority));
        }

        return sortedRoleList;
    }

    private static String chooseHigherOrderRole(Set<String> rolesSet) {
        List<Integer> rolesPriorityList = new List<Integer>();

        for (String roleName : rolesSet) {
            rolesPriorityList.add(UserHelper.hierarchyRolesNameToOrderMap.get(roleName));
        }

        rolesPriorityList.sort();
        Integer higherPriority = rolesPriorityList.get(rolesPriorityList.size() - 1);
        String mostHigherRole = UserHelper.hierarchyRolesOrderToNameMap.get(higherPriority);

        return mostHigherRole;
    }


    private static Map<Id, String> processSpecialTermsApprovers(List<Quote> quotesToProcess, List<QuoteLineItem> qliList) {
        Map<Id, String> quoteIdToLastApproverMap = new Map<Id, String>();
        List<SpecialTermsApprovers_V2__c> stApprovers = SpecialTermsApprovers_V2__c.getAll().values();
        Integer approvalLevel;

        Map<Id, Quote> quotesToProcessMap = new Map<Id, Quote>();
        for (Quote qt : quotesToProcess) {
            quotesToProcessMap.put(qt.Id, qt);
        }

        Boolean doPricebookSearch = false;
        Set<Id> pbIds = new Set<Id>();
        for (Quote qt : quotesToProcess) {
            if ((qt.Pricebook2Id != null) && (!QuoteTriggerHelper.pricebookMapStatic.containsKey(qt.Pricebook2Id))) {
                doPricebookSearch = true;
                pbIds.add(qt.Pricebook2Id);
            }
        }
        if (doPricebookSearch) {
            List<Pricebook2> pbooks = [SELECT Id, Plan__c, IsStandard FROM Pricebook2 WHERE Id IN :pbIds];
            for (Pricebook2 pb : pbooks) {
                QuoteTriggerHelper.pricebookMapStatic.put(pb.Id, pb);
            }
        }

        for (Quote qt : quotesToProcess) {
            if (QuoteHelper.isEngageService(qt) || QuoteHelper.isCCService(qt)) {
                continue;
            }
            System.debug('quotesToProcess. qt  >>>>> ' + qt.Id);
            String plan = QuoteHelper.getPlan(qt);

            if (String.isBlank(plan)) {
                Pricebook2 pb = QuoteTriggerHelper.pricebookMapStatic.get(qt.Pricebook2Id);
                plan = (pb != null ? pb.Plan__c : (Test.isRunningTest() ? 'Monthly' : null));
            }

            if ((qt.Pricebook2Id == null) && (String.isBlank(plan))) {
                System.debug('processSpecialTermsApprovers >>>> Quote ' + qt.Id + ' has empty Pricebook2Id and unknown plan. BYPASS');
                continue;
            }

            approvalLevel = 0;
            for (SpecialTermsApprovers_V2__c approver : stApprovers) {
                if (qt.Initial_Term_months__c != null) {
                    String[] itRange;
                    String its;
                    String ite;
                    if (approver.Initial_Term__c.contains('-')) {
                        itRange = approver.Initial_Term__c.split('-');
                        its = itRange[0];
                        ite = itRange[1];
                    } else {
                        its = approver.Initial_Term__c;
                        ite = approver.Initial_Term__c;
                    }
                    Boolean isQuoteUpdate = true == Trigger.isUpdate && Trigger.oldMap != null && Trigger.newMap.containsKey(qt.Id);
                    System.debug('isQuoteUpdate >>>>> ' + isQuoteUpdate);

                    if (Decimal.valueOf(its) <= Decimal.valueOf(qt.Initial_Term_months__c)
                        && Decimal.valueOf(ite) >= Decimal.valueOf(qt.Initial_Term_months__c)
                        && approver.Special_Terms__c == qt.Special_Terms__c
                        && approver.Special_Terms__c == (isQuoteUpdate ? Trigger.newMap.get(qt.Id).get('Special_Terms__c') : qt.Special_Terms__c)
                        && approver.Plan__c == plan) {

                        approvalLevel = UserHelper.hierarchyRolesNameToOrderMap.get(approver.Last_Approver__c);
                    }
                }
            }

            Integer prevApprovalLevel = UserHelper.hierarchyRolesNameToOrderMap.get(qt.Approval_Type__c);

            System.debug('approvalLevel >>>> ' + approvalLevel);
            System.debug('prevApprovalLevel >>>> ' + prevApprovalLevel);

            if (approvalLevel > 0) {
                quoteIdToLastApproverMap.put(qt.Id, UserHelper.hierarchyRolesOrderToNameMap.get(approvalLevel));
            }
        }

        return quoteIdToLastApproverMap;
    }

    private static boolean isQuoteHasShippingDevices(List<QuoteLineItem> qlis) {
        for (QuoteLineItem qli : qlis) {
            if (qli.PackageInfo__c != null) {
                BillingWrappers.QLIPackageInfo qliPackageInfo = (BillingWrappers.QLIPackageInfo)
                    JSON.deserialize(qli.PackageInfo__c, BillingWrappers.QLIPackageInfo.class);
                if (qliPackageInfo.CategoryCode != null
                    && Product2Helper.SHIPPING_PHONES.contains(qliPackageInfo.CategoryCode)
                    && !qli.Zero_Quantity__c
                    && qli.Quantity > 0) {
                    return true;
                }
            }
        }
        return false;
    }

    public static boolean isFreeShippingApprovalNeeded(Quote qt, List<QuoteLineItem> qlis) {
        if (qt.FreeShippingTerms__c != QuoteHelper.FREESHIPPING) {
            return false;
        }

        Boolean hasOptionOnShippingItems = ShippingService.hasShippingOptions(qlis, new Set<String>{
            QuoteHelper.SHIPPING_OPTION_2_DAY, QuoteHelper.SHIPPING_OPTION_OVERNIGHT
        });
        Boolean hasOptionOnQuote = isQuoteHasShippingDevices(qlis) && (qt.Shipping_Option__c == QuoteHelper.SHIPPING_OPTION_2_DAY || qt.Shipping_Option__c == QuoteHelper.SHIPPING_OPTION_OVERNIGHT);

        // there is an option which is required an approval in case on quote is selected Special Shipping Terms as "Free shipping"
        Boolean hasOption = hasOptionOnQuote;
        if (!QuoteHelper.isExistingBusiness(qt) && Feature_Toggle__c.getInstance().Shipping_Tab_New_Business__c || QuoteHelper.isExistingBusiness(qt) && qt.Enabled_LBO__c) {
            hasOption = hasOptionOnShippingItems;
        }
        return qt.FreeShippingTerms__c == QuoteHelper.FREESHIPPING && hasOption;
    }

    private static boolean isApproverInApproversList(Quote qt, Id approverId) {
        for (Integer i = 1; i <= MAX_LEVEL_APPROVER; i++) {
            if (qt.get('Level_' + i + '_Approver__c') == approverId) {
                return true;
            }
        }
        return false;
    }

    private static void shiftApproversForFreeShippingDiscount(Quote qt, Id approverId) {
        if (qt.Level_5_Approver__c != null) {
            return;
        }
        if (qt.get('Level_' + MAX_LEVEL_APPROVER + '_Approver__c') != null) {
            System.debug('ERROR:: Maximum Approver level exceeded. Please set your role hierarchy');
            return;
        }
        for (Integer i = MAX_LEVEL_APPROVER; i > 1; i--) {
            qt.put('Level_' + i + '_Approver__c', qt.get('Level_' + (i - 1) + '_Approver__c'));
        }
        qt.Level_1_Approver__c = approverId;
    }

    private static List<Quote> processFreeShippingApprover(List<Quote> quoteList, Map<Id, List<QuoteLineItem>> quoteIdToQliListMap) {
        Set<Id> oppIdsSet = new Set<Id>();
        List<Quote> fsQuotes = new List<Quote>();
        Map<Id, Opportunity> opptyMap;

        for (Quote qt : quoteList) {
            Boolean isBillingQuote = qt.RecordTypeId == QuoteHelper.RT_ID_BILLING;
            List<QuoteLineItem> qlis = quoteIdToQliListMap.get(qt.Id);
            if (isBillingQuote && !qlis.isEmpty() && isFreeShippingApprovalNeeded(qt, qlis)) {
                fsQuotes.add(qt);
                oppIdsSet.add(qt.OpportunityId);
            }
        }

        if (oppIdsSet.size() > 0) {
            List<Opportunity> oppList = new OpportunitySelector()
                .selectOpportunitiesFreeShippingDiscount(new List<Object>{
                    oppIdsSet
                })
                .executeQuery();
            opptyMap = new Map<Id, Opportunity>(oppList);
        }

        for (Quote qt : fsQuotes) {
            Opportunity oppty = opptyMap.get(qt.OpportunityId);

            // choose Approver
            Id approverId = oppty.Owner.Manager.Id;
            if (approverId == null) {
                approverId = oppty.Account.Owner.Id;
            }

            // if approver in Approver list, then skip
            if (isApproverInApproversList(qt, approverId)) {
                continue;
            }

            // if Approver not in Approver list and approvers is empty
            if (qt.Level_1_Approver__c == null) {
                qt.Approved_Status__c = QuoteHelper.APPROVAL_STATUS_REQUIRED;
                qt.Level_1_Approver__c = approverId;
            } else { // if approvers not is empty, then shift approvers
                shiftApproversForFreeShippingDiscount(qt, approverId);
            }
        }

        return quoteList;
    }

    private static List<Quote> processFSCforUCapprovers(List<Quote> quotesList) {
        List<Quote> quotesToUpdate = new List<Quote>();
        Quote currentQuote = QuoteHelper.getPrimaryQuote(quotesList, true);

        if (currentQuote != null) {
            String approverLevel = findApproverLevelsForUCfsc(currentQuote);
            currentQuote = setApproverForCCFSC(currentQuote, approverLevel);
            quotesToUpdate.add(currentQuote);
        }

        return quotesList;
    }

    private static String findApproverLevelsForUCfsc(Quote currentQuote) {
        String approverLevel;
        if (currentQuote.Initial_Term_months__c != null && currentQuote.Special_Terms__c != null) {

            String plan = QuoteHelper.getPlan(currentQuote);
            if (String.isBlank(plan)) {
                Pricebook2 pb = QuoteTriggerHelper.pricebookMapStatic.get(currentQuote.Pricebook2Id);
                plan = (pb != null ? pb.Plan__c : (Test.isRunningTest() ? 'Monthly' : null));
            }

            if ((currentQuote.Pricebook2Id == null) && (String.isBlank(plan))) {
                return null;
            }

            List<SpecialTermsApprovers_V2__c> stApprovers = SpecialTermsApprovers_V2__c.getAll().values();
            for (SpecialTermsApprovers_V2__c approver : stApprovers) {
                String[] itRange;
                String its;
                String ite;
                if (approver.Initial_Term__c.contains('-')) {
                    itRange = approver.Initial_Term__c.split('-');
                    its = itRange[0];
                    ite = itRange[1];
                } else {
                    its = approver.Initial_Term__c;
                    ite = approver.Initial_Term__c;
                }

                if (Decimal.valueOf(its) <= Decimal.valueOf(currentQuote.Initial_Term_months__c)
                    && Decimal.valueOf(ite) >= Decimal.valueOf(currentQuote.Initial_Term_months__c)
                    && approver.Special_Terms__c == currentQuote.Special_Terms__c
                    && approver.Plan__c == plan
                    && approver.Last_Approver__c == ENGAGE_FSC_APPROVERS_QUEUE_NAME) {
                    approverLevel = approver.Last_Approver__c;
                }
            }
        }
        return approverLevel;
    }

    private static List<QuoteLineItem> filterQlisWithoutPreApproveDiscounts(List<QuoteLineItem> qliList) {
        List<QuoteLineItem> filteredList = new List<QuoteLineItem>();
        for (QuoteLineItem qli : qliList) {
            if (qli.Promotion__c == null) {
                filteredList.add(qli);
            }
        }
        return filteredList;
    }


    public class Range {

        public Double min;
        public Double max;
        public String rangeName;

        public Range() {
            init(0, 0, '');
        }

        public Range(Double min, Double max) {
            init(min, max, '');
        }
        public Range(Double min, Double max, String rangeName) {
            init(min, max, rangeName);
        }

        public Range(String rangeStr, String separator) {
            List<String> tmp = rangeStr.split(separator);
            Double min = Double.valueOf(tmp[0].trim());
            Double max = Double.valueOf(tmp[1].trim());
            init(min, max, '');
        }

        public Range(String rangeStr, String separator, String rangeName) {
            List<String> tmp = rangeStr.split(separator);
            Double min = Double.valueOf(tmp[0].trim());
            Double max = Double.valueOf(tmp[1].trim());
            init(min, max, rangeName);
        }

        private void init(Double min, Double max, String rangeName) {
            this.min = min;
            this.max = max;
            this.rangeName = rangeName;
        }

        public Boolean isInRange(Double numberToCheck) {
            return isNumberInRange(numberToCheck);
        }
        public Boolean isInRange(Decimal numberToCheck) {
            return isNumberInRange(Double.valueOf(numberToCheck));
        }
        public Boolean isInRange(Integer numberToCheck) {
            return isNumberInRange(Double.valueOf(numberToCheck));
        }
        public Boolean isInRange(String numberToCheck) {

            Double n = numberToCheck.containsWhitespace() ? Double.valueOf(numberToCheck.trim()) : Double.valueOf(numberToCheck);

            return isNumberInRange(n);
        }

        private Boolean isNumberInRange(Double numberToCheck) {
            return (numberToCheck >= this.min) && (numberToCheck <= this.max);
        }
    }


    public static List<Quote> quotesExcludedForDQGoa = new List<Quote>();

    @TestVisible
    private static Map<Id, List<QuoteLineItem>> excludeQuotesForDQGOAFlow(Map<Id, List<QuoteLineItem>> quoteIdToQliListMap) {
        Map<Id, List<QuoteLineItem>> result = new Map<Id, List<QuoteLineItem>>();
        if (quoteIdToQliListMap == null || quoteIdToQliListMap.isEmpty()) {
            return result;
        }
        for (Id quoteId : quoteIdToQliListMap.keySet()) {
            List<QuoteLineItem> qliList = quoteIdToQliListMap.get(quoteId);
            if (qliList.isEmpty()) {
                result.put(quoteId, qliList);
                continue;
            }
            Quote qt = qliList.get(0).Quote;
            Boolean isDQGoaEnabled = QuoteHelper.isDQGoaEnabled(qt);
            if (isDQGoaEnabled) {
                quotesExcludedForDQGoa.add(qt);
            } else {
                result.put(quoteId, qliList);
            }
        }

        return result;
    }

    @TestVisible
    private static List<Quote> processProservApproverQueue(List<Quote> quoteList, Map<Id, List<QuoteLineItem>> quoteIdToQliListMap) {
        for (Quote qt : quoteList) {
            Boolean isBillingQuote = qt.RecordTypeId == QuoteHelper.RT_ID_BILLING;
            List<QuoteLineItem> proservQlis = getProservQLItems(quoteIdToQliListMap.get(qt.Id));

            if (isBillingQuote && !proservQlis.isEmpty()) {
                List<QuoteLineItem> qliListThatNeedApprove = filterQLIForApproval(proservQlis);
                if (!qliListThatNeedApprove.isEmpty()) {
                    qt.Approved_Status__c = QuoteHelper.APPROVAL_STATUS_REQUIRED;
                    qt.ProservLevelApprover__c = GroupHelper.APPROVAL_NGBS_PROSERV_QUEUE;
                } else {
                    qt.ProservLevelApprover__c = null;
                }
            }
        }

        return quoteList;
    }

    @TestVisible
    private static List<QuoteLineItem> getProservQLItems(List<QuoteLineItem> quoteLineItems) {
        List<QuoteLineItem> proservQlitems = new List<QuoteLineItem>();
        for (QuoteLineItem qli: quoteLineItems) {
            if (QuoteLineItemHelper.isProfessionalServiceQli(qli)) {
                proservQlitems.add(qli);
            }
        }

        return proservQlitems;
    }

    private static List<QuoteLineItem> filterQlisWithoutProserv(List<QuoteLineItem> qliList) {
        List<QuoteLineItem> filteredList = new List<QuoteLineItem>();
        if (qliList.isEmpty()) {
            return qliList;
        }
        for (QuoteLineItem qli : qliList) {
            if (!QuoteLineItemHelper.isProfessionalServiceQli(qli)) {
                filteredList.add(qli);
            }
        }
        return filteredList;
    }

}