public class CostCenterLineItemTriggerHandler {
    public class CopyLineItemFromMasterToTechnicalQliOnInsert extends Triggers.TriggerHandlerBase {
        override public void handle() {
            List<Cost_Center_Line_Item__c> masterCclis = (List<Cost_Center_Line_Item__c>) new CostCenterLineItemSelector()
                .selectMasterItemsAllFieldsForCloning(new List<Object> {Trigger.newMap.keySet()})
                .executeQuery();

            Set<Id> masterQliIds = new Set<Id>();
            for (Cost_Center_Line_Item__c ccli : masterCclis) {
                if (CostCenterLineItemTriggerHandler.isMasterCostCenterLineItem(ccli)) {
                    masterQliIds.add(ccli.Quote_Line_Item__r.Id);
                }
            }

            if (masterQliIds.isEmpty()) {
                return;
            }

            List<QuoteLineItem> relatedTechnicalQlis = new QuoteLineItemSelector()
                .selectQuoteLineItemsByMasterQliIds(masterQliIds)
                .executeQuery();

            List<Cost_Center_Line_Item__c> ccliToInsert = new List<Cost_Center_Line_Item__c>();
            for (QuoteLineItem technicalQli : relatedTechnicalQlis) {
                for (Cost_Center_Line_Item__c masterCcli : masterCclis) {
                    if (masterCcli.Quote_Line_Item__r.Id == technicalQli.MasterQLI__c) {
                        Cost_Center_Line_Item__c technicalccli = masterCcli.clone(false, true, false, false);
                        technicalccli.Quote_Line_Item__c = technicalQli.Id;
                        ccliToInsert.add(technicalccli);
                        break;
                    }
                }
            }

            insert ccliToInsert;
        }
    }

    private static boolean isMasterCostCenterLineItem(Cost_Center_Line_Item__c ccli) {
        return ccli.Quote_Line_Item__r.Id != null && ccli.Quote_Line_Item__r.MasterQLI__c == null && !ccli.Quote_Line_Item__r.IsMultiProductTechnicalQLI__c;
    }

    public class CopyLineItemFromMasterToTechnicalQliOnUpdate extends Triggers.TriggerHandlerBase {
        override public void handle() {
            List<Cost_Center_Line_Item__c> masterCclis = (List<Cost_Center_Line_Item__c>) new CostCenterLineItemSelector()
                .selectMasterItemsAllFieldsForCloning(new List<Object> {Trigger.newMap.keySet()})
                .executeQuery();

            Set<Id> masterQliIds = new Set<Id>();
            for (Cost_Center_Line_Item__c ccli : masterCclis) {
                if (CostCenterLineItemTriggerHandler.isMasterCostCenterLineItem(ccli)) {
                    masterQliIds.add(ccli.Quote_Line_Item__r.Id);
                }
            }

            if (masterQliIds.isEmpty()) {
                return;
            }

            List<Cost_Center_Line_Item__c> relatedTechnicalCostCenterItems = (List<Cost_Center_Line_Item__c>) new CostCenterLineItemSelector()
                .selectTechnicalItemsByMasterQliId(new List<Object> {masterQliIds})
                .executeQuery();

            List<Cost_Center_Line_Item__c> ccliToUpdate = new List<Cost_Center_Line_Item__c>();
            for (Cost_Center_Line_Item__c masterCcli : masterCclis) {
                for (Cost_Center_Line_Item__c technicalCcli : relatedTechnicalCostCenterItems) {
                    if (masterCcli.Quote_Line_Item__r.Id == technicalCcli.Quote_Line_Item__r.MasterQLI__c) {
                        Cost_Center_Line_Item__c updatedTechnicalCcli = masterCcli.clone(false, true, false, false);
                        updatedTechnicalCcli.Id = technicalCcli.Id;
                        updatedTechnicalCcli.Quote_Line_Item__c = technicalCcli.Quote_Line_Item__c;
                        ccliToUpdate.add(updatedTechnicalCcli);
                        break;
                    }
                }
            }

            update ccliToUpdate;
        }
    }

    public class DeleteLineItemsOnTechnicalQlisOnMasterDelete extends Triggers.TriggerHandlerBase {
        override public void handle() {
            List<Cost_Center_Line_Item__c> masterCclis = (List<Cost_Center_Line_Item__c>) new CostCenterLineItemSelector()
                .selectMasterItemsAllFieldsForCloning(new List<Object> {Trigger.oldMap.keySet()})
                .executeQuery();

            Set<Id> masterQliIds = new Set<Id>();
            for (Cost_Center_Line_Item__c ccli : masterCclis) {
                if (CostCenterLineItemTriggerHandler.isMasterCostCenterLineItem(ccli)) {
                    masterQliIds.add(ccli.Quote_Line_Item__r.Id);
                }
            }

            if (masterQliIds.isEmpty()) {
                return;
            }

            List<Cost_Center_Line_Item__c> relatedTechnicalCostCenterItems = (List<Cost_Center_Line_Item__c>) new CostCenterLineItemSelector()
                .selectTechnicalItemsByMasterQliId(new List<Object> {masterQliIds})
                .executeQuery();

            List<Cost_Center_Line_Item__c> ccliToDelete = new List<Cost_Center_Line_Item__c>();
            for (Cost_Center_Line_Item__c masterCcli : masterCclis) {
                for (Cost_Center_Line_Item__c technicalCcli : relatedTechnicalCostCenterItems) {
                    if (masterCcli.Quote_Line_Item__r.Id == technicalCcli.Quote_Line_Item__r.MasterQLI__c) {
                        ccliToDelete.add(technicalCcli);
                        break;
                    }
                }
            }

            delete ccliToDelete;
        }
    }
}