public with sharing class ChangeOrder {

    /**
    * @description The method for creating 'ChangeOrder': new Opportunity with
    *     1 ProServ or CCProServ quote in Upsell_Status__c 'Upsell' with QuoteLineItems created on every Asset.
    *     Also this method will be move Not completed Phases and phaseLineItems to changeOrder Quote
    * @param  orderId Id of Order record where 'ChangeOrder' btn was pressed
    * @return created change order Opportunity Id
    */
    public static Response createChangeOrder(String orderId) {

        Response resp = new Response();

        if(String.isBlank(orderId)) {
            resp.setData('newOppId',null);
            resp.error('Order Id can not be empty');
            return resp;
        }

        Feature_Toggle__c featureToggleSetting = Feature_Toggle__c.getInstance();

        Order currentOrder = [SELECT Id, AccountId, Status, OpportunityId, Opportunity.Name, QuoteId,
            Opportunity.CurrencyIsoCode,
            Pricebook2Id, Quote.Number_of_ProServ_Phases__c, Quote.Number_of_Hardware_Shipment_Phases__c,
            Quote.IsPrimary__c, RecordTypeId, Pricebook2.Brand__r.Name, Pricebook2.Service__c,
            RelatedChangeOpportunity__c, Quote.OriginalQuoteNumber__c, Quote.QuoteNumber, Change_Order__c,
            Opportunity.Brand_Name__c, Account.RC_Brand__c, 
            (SELECT Id, PricebookEntryId, Asset__c, Asset__r.Quantity,
                Asset__r.Discount_Number__c, Asset__r.Product2Id,
                Asset__r.Discount_Type__c, Asset__r.Unit_Price__c, Asset__r.Delivered_Quantity__c
            FROM OrderItems),
            (SELECT Id, Name, RecordTypeId, CurrencyIsoCode, Account__c, BillingStatus__c,
                BillingStatusDetails__c, Completion_Date__c, Completed_Date__c,
                Estimated_Completion_Date__c, Opportunity__c, Order__c,
                Percentage__c, Rental_Phones_MRR__c, Phase_Number__c, PhaseDescription__c,
                Initial_Payment__c, Quote__c, Ship_Date__c, Status__c,
                Original_Phase__c, Original_Phase__r.Id, OriginalQuoteNumber__r.QuoteNumber,
                Last_Phase__c, Last_Phase__r.Id, Quote__r.QuoteNumber, OriginalQuoteNumber__c
            FROM Phases__r WHERE Completed_Date__c = null AND Status__c !=: PhaseHelper.STATUS_DELETED)
            FROM Order WHERE Id = :orderId];

        if (String.isNotEmpty(currentOrder.RelatedChangeOpportunity__c) || String.isNotEmpty(currentOrder.Change_Order__c)) {
            resp.setData('newOppId', null);
            resp.setData('relatedChangeOpportunity', currentOrder.RelatedChangeOpportunity__c);
            resp.warning('Change Order has already been generated');
            return resp;
        }

        Id priceBookId;

        if(Test.isRunningTest()) {
            priceBookId = Test.getStandardPricebookId();
        }else {
            priceBookId = currentOrder.Pricebook2Id != null ? currentOrder.Pricebook2Id : [SELECT Id, Name, IsActive FROM Pricebook2 WHERE IsStandard = true limit 1].Id;
        }

        String newOpportunityName = currentOrder.Opportunity.Name + ' (Change Order)';

        String brandName = currentOrder.Pricebook2.Brand__r?.Name != null ? currentOrder.Pricebook2.Brand__r?.Name : 
                (String.isNotEmpty(currentOrder.Opportunity.Brand_Name__c) ? currentOrder.Opportunity.Brand_Name__c : currentOrder.Account.RC_Brand__c);

        Opportunity newOpp = new Opportunity(
            AccountId = currentOrder.AccountId,
            CurrencyIsoCode = currentOrder.Opportunity.CurrencyIsoCode,
            Name = newOpportunityName.abbreviate(120),
            StageName = '1. Qualify',
            Parent_Order__c = orderId,
            Brand_Name__c = brandName,
            Tier_Name__c = currentOrder.Pricebook2.Service__c,
            RecordTypeId = OpportunityHelper.RT_ID_NEW_SALES_OPPORTUNITY,
            Type = OpportunityHelper.OPPORTUNITY_TYPE_EX_BUSINESS,
            closeDate = System.today()
        );
        insert newOpp;

        // recordtype for changeOrder quote - if we click "Change order" on Proserv order - create Proserv quote
        // if it was CCProServ order - create CCProServ quote. In other cases(if it not Proserv order and not CC Proserv) - create Proserv quote.
        Id changeOrderQuoteRtId = OrderHelper.ORDER_RTID_TO_QUOTE_RTID_MAP.get(currentOrder.RecordTypeId) != null ?
            OrderHelper.ORDER_RTID_TO_QUOTE_RTID_MAP.get(currentOrder.RecordTypeId) : QuoteHelper.RT_ID_PROSERV;

        String quoteRtName = QuoteHelper.RT_INFO_BY_ID.get(changeOrderQuoteRtId) != null ?
            QuoteHelper.RT_INFO_BY_ID.get(changeOrderQuoteRtId).getName() : QuoteHelper.RT_NAME_PROSERV;

        Quote changeOrderQuote = new Quote (
            Name = newOpp.Name + ' (' + quoteRtName + ')',
            OpportunityId = newOpp.Id,
            Upsell_Status__c = QuoteHelper.STATUS_UPSELL,
            Pricebook2Id = priceBookId,
            RecordTypeId = changeOrderQuoteRtId,
            ExpirationDate = System.today().addDays(30),
            QuoteType__c = 'Quote',
            OriginalQuoteNumber__c = currentOrder.Quote.OriginalQuoteNumber__c == null
                ? currentOrder.Quote.Id
                : currentOrder.Quote.OriginalQuoteNumber__c
        );
        OpportunityTotals.bypassOpportnuityUpdate = true;
        insert changeOrderQuote;
        OpportunityTotals.bypassOpportnuityUpdate = false;


        if(!currentOrder.OrderItems.isEmpty()) {

            List<QuoteLineItem> qliToInsertList = new List<QuoteLineItem>();

            for(OrderItem item : currentOrder.OrderItems) {

                if(item.Asset__c == null) {
                    continue;
                }

                QuoteLineItem qli = new QuoteLineItem(
                    QuoteId = changeOrderQuote.Id,
                    PriceBookEntryId = item.PricebookEntryId,
                    Asset__c = item.Asset__c,
                    Product2Id = item.Asset__r.Product2Id,
                    UnitPrice = item.Asset__r.Unit_Price__c,
                    Discount_Type__c = item.Asset__r.Discount_Type__c,
                    Discount_Number__c = item.Asset__r.Discount_Number__c
                );

                if (featureToggleSetting.NewChangeOrderFlow__c) {
                    qli.OriginalOrderLineItem__c = item.Id;
                }

                QuoteLineItemHelper.setQuantity(qli, item.Asset__r.Quantity - item.Asset__r.Delivered_Quantity__c);

                qliToInsertList.add(qli);
            }

            if(!qliToInsertList.isEmpty()) {
                insert qliToInsertList;
            }

            // copy phases and phaseLineItems
            copyPhases(newOpp.Id, changeOrderQuote.Id, qliToInsertList, currentOrder.Phases__r);
        }

        if(!featureToggleSetting.NewChangeOrderFlow__c){
            currentOrder.Status = 'Completed';
            update currentOrder;
        }else{
            currentOrder.Status = OrderHelper.STATUS_LOCKED;
            currentOrder.RelatedChangeOpportunity__c = newOpp.Id;
            update currentOrder;
            Approval.lock(currentOrder.Id);
        }

        resp.setData('newOppId',newOpp.Id);
        return resp;
    }

    /**
    * @description The method for building Set of sobject Ids from List
    * @param  List<SObject> - a list of objects from which a set will be created(Id field should be populated - if not - these records will be omitted)
    * @return Set<Id> - set that contains all Ids from passed sobject list
    */
    @TestVisible
    private static Set<Id> buildIdSet(List<SObject> sobjList) {

        if(sobjList == null) {
            return new Set<Id>();
        }

        Set<Id> result = new Set<Id>();

        for(SObject item : sobjList) {
            if(item.get('Id') != null) {
                result.add( (Id) item.get('Id') );
            }
        }

        return result;
    }

    /**
    * @description The method for building Map where PhaseId related to List of PhaseLineItems
    * @param  Set<Id> - set with Id of Phases for selecting related PhaseLineItems
    * @return Map<Id, List<Hardware_Line_Item__c>> - Map where PhaseId related to List of PhaseLineItems
    */
    @TestVisible
    private static Map<Id, List<Hardware_Line_Item__c>> buildPhaseIdToHLIListMap(Set<Id> phaseIdSet) {
        Map<Id, List<Hardware_Line_Item__c>> phaseIdToHLIListMap = new Map<Id, List<Hardware_Line_Item__c>>();

        if(phaseIdSet == null || phaseIdSet.isEmpty()) {
            return phaseIdToHLIListMap;
        }

        for(Hardware_Line_Item__c item : [SELECT Id, Quote_Line_Item__c,
                            Quote_Line_Item__r.Product2Id, RingCentral_Hardware_Phase__c,
                            Address_Line__c, Address_Validated__c, City__c, Country__c,
                            Location_ID__c, Location_Name__c, Name, Postal_Code__c,
                            Quantity__c, State__c, Total_Price__c
                        FROM Hardware_Line_Item__c
                        WHERE RingCentral_Hardware_Phase__c IN : phaseIdSet]) {

            if(phaseIdToHLIListMap.get(item.RingCentral_Hardware_Phase__c) == null) {
                phaseIdToHLIListMap.put(item.RingCentral_Hardware_Phase__c, new List<Hardware_Line_Item__c>());
            }

            phaseIdToHLIListMap.get(item.RingCentral_Hardware_Phase__c).add(item);
        }

        return phaseIdToHLIListMap;
    }

    /**
    * @description The method for clone phases and PhaseLineItems to new 'changeOrder' quote. (used in changeOrder webservice)
    *      When "Change Order" button is clicked all not Completed Phases and Phase Line Items should be cloned to new ProServ Quote with Status = 'Upsell'.
    *      For Phase:
    *        Lookup to old Order on Phase record should be erased.
    *        Lookup to Opportunity should be populated with new Opportunity.
    *        Lookup to Quote should be populated with new Quote.
    *
    *      For PhaseLineItems:
    *        Lookup to old Order on Phase Line Item record should be erased.
    *        Lookup to old Order Item on Phase Line Item record should be erased.
    *        Lookup to Quote Line Item should be populated with newly created Quote Line Item(by Product2Id).
    *
    * @param  Id changeOrderOppId - Id of created opportunity for 'changeOrder' quote
    * @param  Id changeOrderQuoteId - Id of created 'changeOrder' quote
    * @param  List<QuoteLineItem> qliForChangeOrderQuote - list of quoteLineitems created for 'changeOrder' Quote
    * @param  List<Phase__c> notCompletedPhasesList - list of not completed(Completed_Date__c = null) phases for moving to new 'ChangeOrder' Quote
    * @return void (method will insert new Phase__c and update 2 sobjects: Phase__c and Hardware_Line_Item__c)
    */
    private static void copyPhases(Id changeOrderOppId, Id changeOrderQuoteId, List<QuoteLineItem> qliForChangeOrderQuote, List<Phase__c> notCompletedPhasesList) {
        Feature_Toggle__c featureToogleSetting = Feature_Toggle__c.getInstance();

        if((qliForChangeOrderQuote == null || qliForChangeOrderQuote.isEmpty()) || (notCompletedPhasesList == null || notCompletedPhasesList.isEmpty()) ||
            changeOrderOppId == null || changeOrderQuoteId == null) {

            return;
        }

        List<Phase__c> phasesToUpsert = new List<Phase__c>();

        Map<Id, Phase__c> cancelledPhaseIdToNewPhaseMap = new Map<Id, Phase__c>();

        Map<Id, QuoteLineItem> product2IdToQliMap = new Map<Id, QuoteLineItem>();
        for(QuoteLineItem qli : qliForChangeOrderQuote) {
            if(product2IdToQliMap.get(qli.Product2Id) == null) {
                product2IdToQliMap.put(qli.Product2Id, qli);
            }
        }

        Map<Id, List<Hardware_Line_Item__c>> phaseIdToHliListMap = buildPhaseIdToHLIListMap(
            buildIdSet(notCompletedPhasesList)
        );

        if (phaseIdToHliListMap != null && !phaseIdToHliListMap.isEmpty()) {
            for(Phase__c ph : notCompletedPhasesList) {

                Phase__c clonedPhase = ph.clone();

                clonedPhase.Original_Phase__c = ph.Original_Phase__r.Id == null
                                             ? ph.Id
                                             : ph.Original_Phase__r.Id;

                clonedPhase.Last_Phase__c = ph.Id;
                clonedPhase.IsCloned__c = featureToogleSetting.NewChangeOrderFlow__c;
                clonedPhase.Order__c = null;
                clonedPhase.Opportunity__c = changeOrderOppId;
                clonedPhase.Quote__c = changeOrderQuoteId;

                clonedPhase.OriginalQuoteNumber__c = ph.OriginalQuoteNumber__c == null
                    ? ph.Quote__r.Id
                    : ph.OriginalQuoteNumber__c;

                if(!featureToogleSetting.NewChangeOrderFlow__c){
                    ph.Status__c = 'Cancelled';
                }else{
                    ph.Status__c = PhaseHelper.STATUS_LOCKED;
                }
                phasesToUpsert.add(ph);

                cancelledPhaseIdToNewPhaseMap.put(ph.Id, clonedPhase);
            }
        }

        if(!cancelledPhaseIdToNewPhaseMap.isEmpty()) {
            phasesToUpsert.addAll(cancelledPhaseIdToNewPhaseMap.values());
        }

        if(!phasesToUpsert.isEmpty()) {
            upsert phasesToUpsert;
        }

        if(!cancelledPhaseIdToNewPhaseMap.isEmpty()) {

            // insert cancelledPhaseIdToNewPhaseMap.values();

            List<Hardware_Line_Item__c> phaseLineItemsToInsert = new List<Hardware_Line_Item__c>();

            for(Id cancelledPhaseId : cancelledPhaseIdToNewPhaseMap.keySet()) {

                if(phaseIdToHliListMap.get(cancelledPhaseId) != null) {

                    for(Hardware_Line_Item__c hli : phaseIdToHliListMap.get(cancelledPhaseId)) {

                        Id newQliId = product2IdToQliMap.get(hli.Quote_Line_Item__r.Product2Id) == null ? null : product2IdToQliMap.get(hli.Quote_Line_Item__r.Product2Id).Id;

                        if(newQliId == null) {
                            System.debug('not found quoteLineItem for product >> ' + hli.Quote_Line_Item__r.Product2Id);
                        }else{
                            Hardware_Line_Item__c clonedHLI = hli.clone();

                            clonedHLI.Order__c = null;
                            clonedHLI.Order_Line_Item__c = null;
                            clonedHLI.Quote_Line_Item__c = newQliId;
                            clonedHLI.RingCentral_Hardware_Phase__c = cancelledPhaseIdToNewPhaseMap.get(cancelledPhaseId).Id;

                            phaseLineItemsToInsert.add(clonedHLI);
                        }
                    }
                }
            }


            if(!phaseLineItemsToInsert.isEmpty()) {
                insert phaseLineItemsToInsert;
            }

            // lock Cancelled Phases and PLI
            if(!cancelledPhaseIdToNewPhaseMap.isEmpty()) {
                lockSobjects(cancelledPhaseIdToNewPhaseMap.keySet(), phaseIdToHliListMap);
            }
        }
    }

    // lock Cancelled Phases and PLI
    private static void lockSobjects(Set<Id> phaseIdsToLock, Map<Id, List<Hardware_Line_Item__c>> phaseIdToHliListMap) {

        Set<Id> sobjectIdsToLock = new Set<Id>();
        sobjectIdsToLock.addAll(phaseIdsToLock);

        for(Id cancelledPhaseId : phaseIdsToLock) {

            if(phaseIdToHliListMap.containsKey(cancelledPhaseId)) {

                for(Hardware_Line_Item__c hli : phaseIdToHliListMap.get(cancelledPhaseId)) {
                    sobjectIdsToLock.add(hli.Id);
                }
            }
        }

        if(!sobjectIdsToLock.isEmpty()) {
            Approval.lock(new List<Id>(sobjectIdsToLock));
        }
    }
}