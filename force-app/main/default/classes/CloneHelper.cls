public with sharing class CloneHelper {
    public static Quote cloneQuote(Id quoteId, Id masterQuoteId) {
        List<Quote> selectedQuotes = new QuoteSelector()
            .selectQuoteForCloning(new List<Object>{quoteId})
            .executeQuery();
        if (selectedQuotes.isEmpty()) {
            AquivaHelper.throwAquivaException(QuoteHelper.QUOTE_NOT_FOUND);
        }
        Quote originalQuote = selectedQuotes[0];
        Quote clonedQuote = originalQuote.clone(false, true, false, false);
        clonedQuote.isPrimary__c = false;
        clonedQuote.QuotePosition__c = clonedQuote.QuotePosition__c + 1; // TODO
        clonedQuote.Name = incrementQuoteNamePosition(clonedQuote.Name, clonedQuote.QuotePosition__c);
        if (masterQuoteId != null && clonedQuote.IsMultiProductTechnicalQuote__c == true) {
            clonedQuote.MasterQuote__c = masterQuoteId;
        }
        insert clonedQuote;

        Map<Id, Id> oldToNewPromotionIds = clonePromotions(quoteId, clonedQuote.Id);
        Map<Id, Id> oldToNewCostCenterIds = cloneCostCenter(quoteId, clonedQuote.Id);
        Map<Id, Id> oldToNewQliIds = cloneQuoteLineItems(quoteId, clonedQuote.Id, oldToNewPromotionIds);
        cloneCostCenterQli(quoteId, oldToNewQliIds, oldToNewCostCenterIds);
        clonePhasesAndLineItems(quoteId, clonedQuote.Id);
        processClonedQuote(clonedQuote, originalQuote);

        return clonedQuote;
    }

    public static String incrementQuoteNamePosition(String name, Decimal position) {
        List<String> quoteName = name.split(' ');
        quoteName.remove(quoteName.size() - 1);
        quoteName.add(String.valueOf(position));
        return String.join(quoteName, ' ');
    }

    public static Map<Id, Id> cloneQuoteLineItems(Id originalQuoteId, Id targetQuoteId, Map<Id, Id> oldToNewPromotionIds) {
        List<QuoteLineItem> clonedQlis = new List<QuoteLineItem>();
        List<QuoteLineItem> originalQuoteLineItems = new QuoteLineItemSelector()
            .selectQuoteLineItemsForCloning(new List<Object>{originalQuoteId})
            .executeQuery();
        Map<Id, Id> oldToNewEntitlementIds = cloneQuoteEntitlements(originalQuoteId, targetQuoteId);
        for (QuoteLineItem qli: originalQuoteLineItems) {
            QuoteLineItem clonedQli = qli.clone(false, true, false, false);
            clonedQli.QuoteId = targetQuoteId;
            clonedQli.Entitlement__c = oldToNewEntitlementIds.get(clonedQli.Entitlement__c);
            clonedQli.Promotion__c = oldToNewPromotionIds.get(clonedQli.Promotion__c);
            clonedQlis.add(clonedQli);
        }
        insert clonedQlis;

        Map<Id, Id> oldToNewQliIds = new Map<Id, Id>();
        for (QuoteLineItem clonedQli: clonedQlis) {
            oldToNewQliIds.put(clonedQli.getCloneSourceId(), clonedQli.Id);
        }

        // Overage_parent__c could be linked to the other changed QLIs, so we have to maintain it, as well as FeeFor__c
        Boolean shouldUpdate = false;
        for (QuoteLineItem clonedQli: clonedQlis) {
            if (clonedQli.Overage_parent__c != null && oldToNewQliIds.containsKey(clonedQli.Overage_parent__c)) {
                clonedQli.Overage_parent__c = oldToNewQliIds.get(clonedQli.Overage_parent__c);
                shouldUpdate = true;
            }
        }
        if (shouldUpdate){
            update clonedQlis;
        }

        cloneQliAreaCodes(originalQuoteId, oldToNewQliIds);
        cloneCustomAddressAssignments(originalQuoteId, oldToNewQliIds);
        cloneAssignmentLineItems(originalQuoteId, oldToNewQliIds);
        return oldToNewQliIds;
    }

    public static Map<Id, Id> cloneQuoteEntitlements(Id originalQuoteId, Id targetQuoteId) {
        List<Entitlement__c> clonedEntitlements = new List<Entitlement__c>();
        List<Entitlement__c> originalEntitlements = new EntitlementSelector()
            .selectEntitlementsForCloning(originalQuoteId)
            .executeQuery();
        for (Entitlement__c originalEntitlement: originalEntitlements) {
            Entitlement__c clonedEntitlement = originalEntitlement.clone(false, true, false, false);
            clonedEntitlement.Quote__c = targetQuoteId;
            clonedEntitlements.add(clonedEntitlement);
        }
        insert clonedEntitlements;
        Map<Id, Id> oldToNewEntitlementIds = new Map<Id, Id>();
        for (Entitlement__c clonedEntitlement: clonedEntitlements) {
            oldToNewEntitlementIds.put(clonedEntitlement.getCloneSourceId(), clonedEntitlement.Id);
        }
        return oldToNewEntitlementIds;
    }

    public static void cloneQliAreaCodes(Id originalQuoteId, Map<Id, Id> oldToNewQliIds) {
        List<Area_Code_Line_Item__c> clonedAreaCodes = new List<Area_Code_Line_Item__c>();
        List<Area_Code_Line_Item__c> areaCodesForQlis = new AreaCodeLineItemSelector()
                .selectAreaCodeLineItemsForCloning(new List<Object>{ originalQuoteId })
                .executeQuery();
        for (Area_Code_Line_Item__c areaCode: areaCodesForQlis) {
            Area_Code_Line_Item__c clonedAreaCode = areaCode.clone(false, true, false, false);
            clonedAreaCode.Quote_Line_Item__c = oldToNewQliIds.get(clonedAreaCode.Quote_Line_Item__c);
            clonedAreaCodes.add(clonedAreaCode);
        }
        insert clonedAreaCodes;
    }

    public static void cloneCustomAddressAssignments(Id originalQuoteId, Map<Id, Id> oldToNewQliIds) {
        List<CustomAddressAssignments__c> clonedCustomAddressQLIs = new List<CustomAddressAssignments__c>();
        List<CustomAddressAssignments__c> customAddresses = new CustomAddressAssignmentsSelector()
                .selectAllFieldsForCloning(new List<Object>{ oldToNewQliIds.keyset() })
                .executeQuery();
        for (CustomAddressAssignments__c customAddr: customAddresses) {
            CustomAddressAssignments__c clonedCustomAddr = customAddr.clone(false, true, false, false);
            clonedCustomAddr.QuoteLineItem__c = oldToNewQliIds.get(clonedCustomAddr.QuoteLineItem__c);
            clonedCustomAddressQLIs.add(clonedCustomAddr);
        }
        insert clonedCustomAddressQLIs;
    }

    public static void cloneAssignmentLineItems(Id originalQuoteId, Map<Id, Id> oldToNewQliIds) {
        List<AssignmentLineItem__c> clonedAssignmentLIs = new List<AssignmentLineItem__c>();
        List<AssignmentLineItem__c> assignmentLIs = new AssignmentLineItemSelector()
                .selectAllFieldsForCloning(new List<Object>{ oldToNewQliIds.keyset() })
                .executeQuery();
        for (AssignmentLineItem__c ali: assignmentLIs) {
            AssignmentLineItem__c clonedALI = ali.clone(false, true, false, false);
            clonedALI.Parent__c = oldToNewQliIds.get(clonedALI.Parent__c);
            clonedALI.Child__c = oldToNewQliIds.get(clonedALI.Child__c);
            clonedAssignmentLIs.add(clonedALI);
        }
        insert clonedAssignmentLIs;
    }

    public static Map<Id, Id> cloneCostCenter(Id originalQuoteId, Id targetQuoteId) {
        List<Cost_Center__c> clonedRecs = new List<Cost_Center__c>();
        List<Cost_Center__c> recs = new CostCenterSelector()
                .selectAllFieldsForCloning(new List<Object>{ new Set<Id>{originalQuoteId} })
                .executeQuery();
        for (Cost_Center__c rec: recs) {
            Cost_Center__c clonedRec = rec.clone(false, true, false, false);
            clonedRec.Quote__c = targetQuoteId;
            clonedRecs.add(clonedRec);
        }
        insert clonedRecs;

        Map<Id, Id> oldToNewCostCenterIds = new Map<Id, Id>();
        for (Cost_Center__c clonedRec: clonedRecs) {
            oldToNewCostCenterIds.put(clonedRec.getCloneSourceId(), clonedRec.Id);
        }

        List<Cost_Center__c> recsToUpdate = new List<Cost_Center__c>();
        for (Cost_Center__c rec: clonedRecs) {
            if (oldToNewCostCenterIds.containsKey(rec.Cost_Center_Parent__c)) {
                rec.Cost_Center_Parent__c = oldToNewCostCenterIds.get(rec.Cost_Center_Parent__c);
                recsToUpdate.add(rec);
            }
        }
        update recsToUpdate;

        return oldToNewCostCenterIds;
    }

    public static void cloneCostCenterQli(Id originalQuoteId, Map<Id, Id> oldToNewQliIds, Map<Id, Id> oldToNewCostCenterIds) {
        List<Cost_Center_Line_Item__c> clonedRecs = new List<Cost_Center_Line_Item__c>();
        List<Cost_Center_Line_Item__c> recs = new CostCenterLineItemSelector()
                .selectAllFieldsForCloning(oldToNewQliIds.keyset())
                .executeQuery();
        for (Cost_Center_Line_Item__c rec: recs) {
            Cost_Center_Line_Item__c clonedRec = rec.clone(false, true, false, false);
            clonedRec.Quote_Line_Item__c = oldToNewQliIds.get(clonedRec.Quote_Line_Item__c);
            if (oldToNewCostCenterIds.containsKey(clonedRec.Cost_Center__c)) {
                clonedRec.Cost_Center__c = oldToNewCostCenterIds.get(clonedRec.Cost_Center__c);
            }
            clonedRecs.add(clonedRec);
        }
        insert clonedRecs;

        Map<Id, Id> oldToNewCCLIIds = new Map<Id, Id>();
        for (Cost_Center_Line_Item__c clonedRec: clonedRecs) {
            oldToNewCCLIIds.put(clonedRec.getCloneSourceId(), clonedRec.Id);
        }

        List<Cost_Center_Line_Item__c> recsToUpdate = new List<Cost_Center_Line_Item__c>();
        for (Cost_Center_Line_Item__c rec: clonedRecs) {
            if (oldToNewCCLIIds.containsKey(rec.Parent__c)) {
                rec.Parent__c = oldToNewCostCenterIds.get(rec.Parent__c);
                recsToUpdate.add(rec);
            }
        }
        update recsToUpdate;
    }

    public static Map<Id, Id> clonePromotions(Id originalQuoteId, Id targetQuoteId) {
        List<Promotion__c> clonedRecs = new List<Promotion__c>();
        List<Promotion__c> recs = new PromotionSelector()
                .selectAllFieldsForCloning(new List<Object>{ new Set<Id>{originalQuoteId} })
                .executeQuery();
        for (Promotion__c rec: recs) {
            Promotion__c clonedRec = rec.clone(false, true, false, false);
            clonedRec.Quote__c = targetQuoteId;
            clonedRecs.add(clonedRec);
        }
        insert clonedRecs;

        Map<Id, Id> oldToNewPromotionIds = new Map<Id, Id>();
        for (Promotion__c clonedRec: clonedRecs) {
            oldToNewPromotionIds.put(clonedRec.getCloneSourceId(), clonedRec.Id);
        }

        return oldToNewPromotionIds;
    }

    @TestVisible
    private static void processClonedQuote(Quote clonedQuote, Quote originalQuote) {
        if (QuoteHelper.isProServService(clonedQuote)
            && QuoteHelper.isNewBillingQuote(clonedQuote)
            && clonedQuote.isMultiProductTechnicalQuote__c) {
            EmailNotificationHelper.sendEmailNotificationToProServTeamForClonedQuote(clonedQuote.Id, originalQuote.Id);
            createCasesForClonedProServQuote(clonedQuote.Id, originalQuote.Id);
        }
    }

    public static void clonePhasesAndLineItems(Id originalQuoteId, Id clonedQuoteId) {
        List<Phase__c> originalPhases = new PhaseSelector()
            .selectPhasesByQuoteIds(new List<Object>{new Set<Id>{originalQuoteId}})
            .executeQuery();
        
        if (originalPhases.isEmpty()) {
            return;
        }
        
        List<Phase__c> clonedPhases = new List<Phase__c>();
        List<Hardware_Line_Item__c> allLineItems = new List<Hardware_Line_Item__c>();
        
        //Clone phases and collect related line items
        for (Phase__c phase : originalPhases) {
            Phase__c cloned = phase.clone(false, true, false, false);
            cloned.Quote__c = clonedQuoteId;
            cloned.IsCloned__c = true;
            clonedPhases.add(cloned);
            
            if (phase.Hardware_Line_Items__r != null) {
                allLineItems.addAll(phase.Hardware_Line_Items__r);
            }
        }

        if (!clonedPhases.isEmpty()) {
            insert clonedPhases;
        }

        Map<Id, Id> oldToNewPhaseIds = new Map<Id, Id>();
        for (Phase__c clonedPhase : clonedPhases) {
            oldToNewPhaseIds.put(clonedPhase.getCloneSourceId(), clonedPhase.Id);
        }

        List<Hardware_Line_Item__c> clonedLineItems = new List<Hardware_Line_Item__c>();
        for (Hardware_Line_Item__c pli : allLineItems) {
            Hardware_Line_Item__c clonedPLI = pli.clone(false, true, false, false);
            clonedPLI.RingCentral_Hardware_Phase__c = oldToNewPhaseIds.get(pli.RingCentral_Hardware_Phase__c);
            clonedLineItems.add(clonedPLI);
        }
        
        if (!clonedLineItems.isEmpty()) {
            insert clonedLineItems;
        }
    }

    @future
    private static void createCasesForClonedProServQuote(Id clonedProServQuoteId, Id originalProServQuoteId) {
        try {
            List<Quote> quotes = new QuoteSelector()
                .selectQuotesByIds(new List<Object>{new Set<Id>{clonedProServQuoteId, originalProServQuoteId}})
                .executeQuery();

            Map<Id, Quote> quotesById = new Map<Id, Quote>(quotes);
            Quote clonedQuote = quotesById.get(clonedProServQuoteId);
            Quote originalQuote = quotesById.get(originalProServQuoteId);

            List<Case> proServCases = (List<Case>) new CaseSelector()
                .selectCaseByOpportunityAndQuoteAndRecordTypeName(
                    new List<Object>{
                        originalQuote.OpportunityId, originalQuote.MasterQuote__c, CaseHelper.RT_NAME_PROFESSIONAL_SERVICES
                    })
                .executeQuery();

            List<Case> casesToInsert = new List<Case>();
            
            for (Case cs : proServCases) {
                if (!CaseHelper.isUcProServCase(cs) && !CaseHelper.isCcProServCase(cs)) {
                    continue;
                }
    
                String description = !String.isEmpty(cs.description) && cs.description.contains(CaseHelper.CASE_DESCRIPTION_CLONED_QUOTE)
                    ? cs.description
                    : CaseHelper.CASE_DESCRIPTION_CLONED_QUOTE + '\n\n' + cs.description;

                Case newCase = (Case) new SObjectBuilder(Case.sObjectType)
                    .setFields(new Map<SObjectField, Object> {
                        Case.Subject => cs.Subject,
                        Case.Origin => CaseHelper.CASE_ORIGIN_QUOTING_PAGE,
                        Case.Description => description,
                        Case.Quote_Approval_ID__c => clonedQuote.MasterQuote__c,
                        Case.Opportunity_Reference__c => cs.Opportunity_Reference__c,
                        Case.AccountId => cs.AccountId,
                        Case.OpportunityOwnerEmail__c => cs.OpportunityOwnerEmail__c,
                        Case.Partner_Contact__c => cs.Partner_Contact__c,
                        Case.Category__c => cs.Category__c,
                        Case.Case_Category__c => cs.Case_Category__c,
                        Case.Segment__c => cs.Segment__c,
                        Case.RecordTypeId => cs.RecordTypeId
                    })
                    .build()
                    .getRecord();

                casesToInsert.add(newCase);
            }
            
            if (!casesToInsert.isEmpty()) {
                insert casesToInsert;
            }
        } catch (Exception e) {
            PlatformLog.logException('createCasesForClonedProServQuote: ' + clonedProServQuoteId, e);
        }
    }
}