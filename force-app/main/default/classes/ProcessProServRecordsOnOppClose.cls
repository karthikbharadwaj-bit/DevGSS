public with sharing class ProcessProServRecordsOnOppClose implements Queueable, Database.AllowsCallouts {

    List<Opportunity> proServChangeOrderOpps;
    List<Order> newOrderList;
    List<Order> oldOrderList = new List<Order>();
    Map<Id, String> oppIdToBillingPackageId = new Map<Id, String>();
    Map<Id, Id> oppIdToPackageIdMap = new Map<Id, Id>();
    Map<Id, Quote> oppIdToPrimaryQuote = new Map<Id, Quote>();
    Map<Id, Double> oppIdToMaxPhaseNum = new Map<Id, Double>();

    public ProcessProServRecordsOnOppClose(List<Opportunity> proServChangeOrderOpps, List<Order> newOrderList) {
        this.proServChangeOrderOpps = proServChangeOrderOpps;
        this.newOrderList = newOrderList;
    }

    public void execute(QueueableContext context) {
        try {
            getOldProServOrders();
            getPrimaryQuotes();
            syncProServDiscounts();
            getParentOrderMaxPhaseNumber();
            insertProServOrders();
            updateOldOrdersAndRelatedSuborders();
            createNewOrdersAndRelatedSuboders();
            cancelPSforMergedSuborders();
        } catch (Exception e) {
            PlatformLog.logException('Error on ProcessProServRecordsOnOppClose', e);
        }
        
    }

    private void getOldProServOrders() {    
        Map<Id, Id> oldOrderIdToOppIdMap = new Map<Id, Id>();
        for (Opportunity opp : proServChangeOrderOpps) {
            oldOrderIdToOppIdMap.put(opp.Parent_Order__c, opp.Id);
        }
        oldOrderList = (List<Order>) new OrderSelector()
            .selectOrdersWithPackage(new List<Object>{ oldOrderIdToOppIdMap.keySet() })
            .executeQuery();

        for (Order oldOrder: oldOrderList) {
            oppIdToPackageIdMap.put(oldOrderIdToOppIdMap.get(oldOrder.Id), oldOrder.PackageId__c);
            oppIdToBillingPackageId.put(oldOrderIdToOppIdMap.get(oldOrder.Id), oldOrder.PackageId__r.Account_Package_Id__c);
        }
    }

    private void getPrimaryQuotes() {
        Set<Id> primaryQuotesIds = new Set<Id>();
        for (Opportunity opp : proServChangeOrderOpps) {
            primaryQuotesIds.add(opp.PrimaryQuote__c);
        }
        List<Quote> primaryQuotes = new QuoteSelector()
            .selectQuotesByIds(new List<Object>{primaryQuotesIds})
            .executeQuery();

        for (Quote primaryQuote : primaryQuotes) {
            oppIdToPrimaryQuote.put(primaryQuote.OpportunityId, primaryQuote);
        }
    }

    private void syncProServDiscounts() {
        if(!oppIdToBillingPackageId.isEmpty()) {
            ProServDiscountsHelper.syncProServDiscounts(oppIdToBillingPackageId);
        }
    }

    private void getParentOrderMaxPhaseNumber() {
        if(!proServChangeOrderOpps.isEmpty()) {
            List<Opportunity> opptyWithMaxPhaseDetails = (List<Opportunity>) new OpportunitySelector()
                                                        .selectOpportunities()
                                                        .selectFields(new List<String>{'Id', 'Parent_Order__c', 'Parent_Order__r.MaxPhaseNumber__c'})
                                                        .setCondition('Id IN :bind0')
                                                        .setQueryBindings(new List<Object>{ proServChangeOrderOpps })
                                                        .executeQuery();
            for (Opportunity coOppty: opptyWithMaxPhaseDetails) {
                Double maxPhaseNum = coOppty.Parent_Order__c != null && coOppty.Parent_Order__r?.MaxPhaseNumber__c != null ? coOppty.Parent_Order__r.MaxPhaseNumber__c :0;
                oppIdToMaxPhaseNum.put(coOppty.Id, maxPhaseNum);
            }
        }
    }

    private void insertProServOrders() {
        for (Order newOrder: newOrderList) {
            newOrder.PackageId__c = oppIdToPackageIdMap.get(newOrder.OpportunityId);
            newOrder.Signed_SOW__c = oppIdToPrimaryQuote.get(newOrder.OpportunityId) != null ? oppIdToPrimaryQuote.get(newOrder.OpportunityId).Signed_SOW__c : '';
            newOrder.MaxPhaseNumber__c = oppIdToMaxPhaseNum.containskey(newOrder.OpportunityId)?oppIdToMaxPhaseNum.get(newOrder.OpportunityId):0;
        }

        if (!newOrderList.isEmpty()) {
            insert newOrderList; 
        }
    }

    private void updateOldOrdersAndRelatedSuborders() {
        List<Order> updatedOrders = new List<Order>();
        List<Suborder__c> updatedSuborders = new List<Suborder__c>();
        for (Order proServOrder: oldOrderList) {
            if (proServOrder.Status == OrderHelper.STATUS_LOCKED) {
                proServOrder.Status = OrderHelper.STATUS_REVISED;
                updatedOrders.add(proServOrder);
                for (Suborder__c suborder : proServOrder.Suborders__r) {
                    if (suborder.Status__c == SuborderHelper.STATUS_LOCKED) {
                        suborder.Status__c = SuborderHelper.STATUS_CANCELED;
                        updatedSuborders.add(suborder);
                    }
                }
            }
        }
        if (!updatedOrders.isEmpty()) {
            update updatedOrders;
        }
        if (!updatedSuborders.isEmpty()) {
            update updatedSuborders;
        }
    }

    private void createNewOrdersAndRelatedSuboders() {
        Map<Id, List<Order>> primaryQuoteIdToProServOrders = new Map<Id, List<Order>>();
        for (Order ord : newOrderList) {
            for (Opportunity opp: proServChangeOrderOpps) {
                if (ord.OpportunityId == opp.Id) {
                    if (primaryQuoteIdToProServOrders.get(opp.PrimaryQuote__c) != null) {
                        primaryQuoteIdToProServOrders.get(opp.PrimaryQuote__c).add(ord);
                    } else {
                        primaryQuoteIdToProServOrders.put(opp.PrimaryQuote__c, new List<Order>{ ord });
                    }
                }
            }
        }


        Map<Id, List<Phase__c>> primaryQuoteIdToPhases = new Map<Id, List<Phase__c>>();
        List<Phase__c> phases =  (List<Phase__c>) new PhaseSelector()
            .selectPhasesByQuoteIds(new List<Object>{ primaryQuoteIdToProServOrders.keySet() })
            .selectFields(new List<String>{'Order__r.orderNumber'})   
            .executeQuery();


        for (Phase__c phase: phases) {
            if (primaryQuoteIdToPhases.get(phase.Quote__c) != null) {
                primaryQuoteIdToPhases.get(phase.Quote__c).add(phase);
            } else {
                primaryQuoteIdToPhases.put(phase.Quote__c, new List<Phase__c>{ phase });
            }
        }
        for (Id quoteId: primaryQuoteIdToProServOrders.keySet()) {
            List<Order> proServOrders = primaryQuoteIdToProServOrders.get(quoteId);
            Map<Id, Phase__c> phasesMap = new Map<Id, Phase__c>(primaryQuoteIdToPhases.get(quoteId));
            List<Suborder__c> suborders = SuborderHelper.createSuborders(proServOrders, phasesMap);
            SuborderLineItemHelper.createSuborderLineItems(suborders, phasesMap);
        }
    }

    private void cancelPSforMergedSuborders() {
        Set<Id> psProjectIds = new Set<Id>();
        Set<Id> orderIds = new Set<Id>();        
        for (Order ord : (List<Order>) new OrderSelector().selectOrdersForPSIntegrationManagement(new List<Object> {newOrderList}).executeQuery()) {
            if (ord.ProServProject__r?.Opportunity__c != null) {
                psProjectIds.add(ord.ProServProject__r.Id);
                orderIds.add(ord.Id);
            }
        }
        if(!psProjectIds.isEmpty()) {
            List<PS_Integration__c> existingPSIntegrations = new PSIntegrationSelector()
                            .selectPSIntegrationsByProjectIds(new List<Object> { psProjectIds , new List<String> { PSIntegrationHelper.STATUS_NEW,PSIntegrationHelper.STATUS_FAILED, PSIntegrationHelper.STATUS_CANCELED }})
                            .executeQuery();
            List<PS_Integration__c > cancelledPSRecords = new List<PS_Integration__c >();
            for (PS_Integration__c psIntegration : existingPSIntegrations) {
                if(psIntegration.Order__c != null && !orderIds.contains(psIntegration.Order__c)) {
                    psIntegration.Status__c = PSIntegrationHelper.STATUS_CANCELED;
                    cancelledPSRecords.add(psIntegration);
                }
            }
            if(!cancelledPSRecords.isEmpty()) {
                update cancelledPSRecords;
            }
        }
    } 
}