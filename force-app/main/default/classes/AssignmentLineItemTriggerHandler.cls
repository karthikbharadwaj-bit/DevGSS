public class AssignmentLineItemTriggerHandler {
    public class CopyLineItemFromMasterToTechnicalQliOnInsert extends Triggers.TriggerHandlerBase {
        override public void handle() {
            if (Feature_Toggle__c.getInstance().EnableIncrementalSave__c) {
                return;
            }
            List<AssignmentLineItem__c> masterAlis = (List<AssignmentLineItem__c>) new AssignmentLineItemSelector()
                .selectMasterItemsAllFieldsForCloning(new List<Object> {Trigger.newMap.keySet()})
                .executeQuery();

            Set<Id> relatedQliIds = new Set<Id>();
            for (AssignmentLineItem__c ali : masterAlis) {
                if (AssignmentLineItemTriggerHandler.isMasterAssignmentLineItem(ali)) {
                    relatedQliIds.add(ali.Parent__r.Id);
                    relatedQliIds.add(ali.Child__r.Id);
                }
            }

            if (relatedQliIds.isEmpty()) {
                return;
            }

            List<QuoteLineItem> relatedQlis = new QuoteLineItemSelector()
                .selectQuoteLineItemsByMasterQliIds(relatedQliIds)
                .executeQuery();

            List<AssignmentLineItem__c> aliToInsert = new List<AssignmentLineItem__c>();
            for (AssignmentLineItem__c masterAli : masterAlis) {
                AssignmentLineItem__c techAli = masterAli.clone(false, true, false, false);

                for (QuoteLineItem qli : relatedQlis) {
                    if (masterAli.Parent__r.Id == qli.MasterQLI__c) {
                        techAli.Parent__c = qli.Id;
                    }
                    if (masterAli.Child__r.Id == qli.MasterQLI__c) {
                        techAli.Child__c = qli.Id;
                    }
                }

                if (technicalAliIsUpdated(masterAli, techAli)) {
                    aliToInsert.add(techAli);
                }
            }

            insert aliToInsert;
        }

        private boolean technicalAliIsUpdated(AssignmentLineItem__c masterAli, AssignmentLineItem__c technicalAli) {
            return (masterAli.Parent__c != technicalAli.Parent__c) && (masterAli.Child__c != technicalAli.Child__c);
        }
    }

    private static boolean isMasterAssignmentLineItem(AssignmentLineItem__c ali) {
        return ali.Parent__r.MasterQLI__c == null && !ali.Parent__r.IsMultiProductTechnicalQLI__c;
    }

    public class CopyLineItemFromMasterToTechnicalQliOnUpdate extends Triggers.TriggerHandlerBase {
        override public void handle() {
            if (Feature_Toggle__c.getInstance().EnableIncrementalSave__c) {
                return;
            }
            List<AssignmentLineItem__c> masterAlis = (List<AssignmentLineItem__c>) new AssignmentLineItemSelector()
                .selectMasterItemsAllFieldsForCloning(new List<Object> {Trigger.newMap.keySet()})
                .executeQuery();

            Set<Id> relatedQliIds = new Set<Id>();
            for (AssignmentLineItem__c ali : masterAlis) {
                if (AssignmentLineItemTriggerHandler.isMasterAssignmentLineItem(ali)) {
                    relatedQliIds.add(ali.Parent__r.Id);
                    relatedQliIds.add(ali.Child__r.Id);
                }
            }

            if (relatedQliIds.isEmpty()) {
                return;
            }

            List<AssignmentLineItem__c> relatedTechnicalAlis = (List<AssignmentLineItem__c>) new AssignmentLineItemSelector()
                .selectTechnicalItemsByMasterQliId(new List<Object> {relatedQliIds})
                .executeQuery();

            List<AssignmentLineItem__c> alisToUpdate = new List<AssignmentLineItem__c>();
            for (AssignmentLineItem__c masterAli : masterAlis) {
                for (AssignmentLineItem__c technicalAli : relatedTechnicalAlis) {
                    if (masterAli.Parent__r.Id == technicalAli.Parent__r.MasterQLI__c
                        && masterAli.Child__r.Id == technicalAli.Child__r.MasterQLI__c) {
                            AssignmentLineItem__c updatedTechAli = masterAli.clone(false, true, false, false);
                            updatedTechAli.Id = technicalAli.Id;
                            updatedTechAli.Parent__c = technicalAli.Parent__c;
                            updatedTechAli.Child__c = technicalAli.Child__c;
                            alisToUpdate.add(updatedTechAli);
                            break;
                    }
                }
            }

            update alisToUpdate;
        }
    }

    public class DeleteLineItemsOnTechnicalQlisOnMasterDelete extends Triggers.TriggerHandlerBase {
        override public void handle() {
            if (Feature_Toggle__c.getInstance().EnableIncrementalSave__c) {
                return;
            }
            List<AssignmentLineItem__c> masterAlis = (List<AssignmentLineItem__c>) new AssignmentLineItemSelector()
                .selectMasterItemsAllFieldsForCloning(new List<Object> {Trigger.oldMap.keySet()})
                .executeQuery();

            Set<Id> relatedQliIds = new Set<Id>();
            for (AssignmentLineItem__c ali : masterAlis) {
                if (AssignmentLineItemTriggerHandler.isMasterAssignmentLineItem(ali)) {
                    relatedQliIds.add(ali.Parent__r.Id);
                    relatedQliIds.add(ali.Child__r.Id);
                }
            }

            if (relatedQliIds.isEmpty()) {
                return;
            }

            List<AssignmentLineItem__c> relatedTechnicalAlis = (List<AssignmentLineItem__c>) new AssignmentLineItemSelector()
                .selectTechnicalItemsByMasterQliId(new List<Object> {relatedQliIds})
                .executeQuery();

            List<AssignmentLineItem__c> alisToDelete = new List<AssignmentLineItem__c>();
            for (AssignmentLineItem__c masterAli : masterAlis) {
                for (AssignmentLineItem__c technicalAli : relatedTechnicalAlis) {
                    if (masterAli.Parent__r.Id == technicalAli.Parent__r.MasterQLI__c
                        && masterAli.Child__r.Id == technicalAli.Child__r.MasterQLI__c
                        && !alisToDelete.contains(technicalAli)
                        ) {
                            alisToDelete.add(technicalAli);
                            break;
                    }
                }
            }

            delete alisToDelete;
        }
    }
}