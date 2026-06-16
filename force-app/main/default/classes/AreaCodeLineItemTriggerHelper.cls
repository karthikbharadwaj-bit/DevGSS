public with sharing class AreaCodeLineItemTriggerHelper{

    public class UpdateQuoteLineItemOnAreaCodeLineItemUpdate extends Triggers.TriggerHandlerBase {

        override public void handle() {
            Map <Id, QuoteLineItem> idToQLIAfterMap = new Map <Id, QuoteLineItem>();
            Map <Id, QuoteLineItem> idToQLIBeforeMap = new Map <Id, QuoteLineItem>();
            Set <Id> affectedQlisIdsSet = new Set<Id>();
            List <QuoteLineItem> qlisToUpdate = new List <QuoteLineItem>();

            for (Area_Code_Line_Item__c changedACLI: (List<Area_Code_Line_Item__c>) TriggerRecords) {
                if (String.isNotBlank(changedACLI.Quote_Line_Item__c)) {
                    affectedQlisIdsSet.add(changedACLI.Quote_Line_Item__c);
                }
            }

            if (affectedQlisIdsSet.size() == 0) { return; }

            List<Area_Code_Line_Item__c> areaCodeLineItems = [
                SELECT Id, Quantity__c, Quote_Line_Item__r.CreatedDate, Quote_Line_Item__r.Quantity,
                    Quote_Line_Item__r.Zero_Quantity__c, Quote_Line_Item__r.Entitlement__r.Quantity__c,
                    Quote_Line_Item__r.Asset__r.Delivered_Quantity__c, Quote_Line_Item__r.QuoteRecordType__c
                FROM Area_Code_Line_Item__c
                WHERE Quote_Line_Item__c IN :affectedQlisIdsSet
            ];

            /* Does not need for Billing Quote */
            if (areaCodeLineItems.size() > 0) {
                QuoteLineItem qli = areaCodeLineItems.get(0).Quote_Line_Item__r;
                if (QuoteHelper.isNewBillingQuote(qli)) {
                    return;
                }
            }

            for (Area_Code_Line_Item__c acli : areaCodeLineItems) {
                idToQLIBeforeMap.put(acli.Quote_Line_Item__c, acli.Quote_Line_Item__r);

                Id qliIdFromAcli = acli.Quote_Line_Item__c;
                Decimal acliQty = (Decimal) NumberHelper.getNumberNullSafe(acli.Quantity__c);

                if(!idToQLIAfterMap.containsKey(acli.Quote_Line_Item__c)) {
                    idToQLIAfterMap.put(qliIdFromAcli, new QuoteLineItem(
                        Id = acli.Quote_Line_Item__c,
                        Quantity = 1,
                        Zero_Quantity__c = true
                    ));
                }
                QuoteLineItem tempQli = idToQLIAfterMap.get(qliIdFromAcli);
                Decimal currQliQty = QuoteLineItemHelper.getQuantity(tempQli);
                QuoteLineItemHelper.setQuantity(tempQli, currQliQty + acliQty);
            }

            for (Id qliId : idToQLIAfterMap.keySet()) {
                QuoteLineItem qliBefore = idToQLIBeforeMap.get(qliId);
                QuoteLineItem qliAfter = idToQLIAfterMap.get(qliId);
                if (QuoteLineItemHelper.getQuantity(qliBefore) != QuoteLineItemHelper.getQuantity(qliAfter)) {
                    qlisToUpdate.add(qliAfter);
                }
            }

            if (qlisToUpdate.size() > 0) {
                update qlisToUpdate;
            }
        }
    }


    public class CheckInvalidNumberSetups extends Triggers.TriggerHandlerBase {

        override public void handle() {

            Set<Id> qliIdsSet = new Set<Id>();

            List<Area_Code_Line_Item__c> aclis =  Trigger.isDelete ? (List<Area_Code_Line_Item__c>) Trigger.old : (List<Area_Code_Line_Item__c>) Trigger.new;

            for (Area_Code_Line_Item__c item : aclis) {
                if (String.isNotBlank(item.Quote_Line_Item__c)) {
                    qliIdsSet.add(item.Quote_Line_Item__c);
                }
            }

            if(qliIdsSet.size() > 0) {

                Set<Id> quoteIdSet = new Set<Id>();

                for(QuoteLineItem qli : [select Id, QuoteId from QuoteLineItem where Id in :qliIdsSet]) {
                    quoteIdSet.add(qli.QuoteId);
                }

                List<Quote> quotes = new List<Quote>([select
                                                        Id, AreaCode__c, FaxAreaCode__c, Main_Vanity_Number__c,
                                                        Fax_Vanity_Number__c, Upsell_status__c,PriceBook2Id, PriceBook2.Service__c,
                                                        Invalid_Number_of_Vanity_Setups__c, Invalid_Number_of_800_Setups__c,
                                                        Invalid_Number_of_Int_TF_Setups__c, Required_Area_Codes_are_empty__c
                                                    from Quote where Id in :quoteIdSet]);

                Set<Id> priceBook2IdSet = new Set<Id>();
                List<Quote> quotesWithNewUpsellStatus = new List<Quote>();

                for(Quote item : quotes) {
                    if(item.Upsell_status__c == 'New') {
                        quotesWithNewUpsellStatus.add(item);
                        priceBook2IdSet.add(item.PriceBook2Id);
                    }
                }

                if(quotesWithNewUpsellStatus.size() > 0) {

                    QuoteLineItemTriggerHelper.CheckNumberOfVanitySteps checker = new QuoteLineItemTriggerHelper.CheckNumberOfVanitySteps();

                    List<Quote> quotesToUpdate = checker.checkInvalidNumberSetups(quotesWithNewUpsellStatus, priceBook2IdSet);

                    if(quotesToUpdate.size() > 0) {
                        update quotesToUpdate;
                    }
                }
            }
        }
    }

    public class CopyLineItemFromMasterToTechnicalQliOnInsert extends Triggers.TriggerHandlerBase {
        override public void handle() {
            List<Area_Code_Line_Item__c> masterAclis = (List<Area_Code_Line_Item__c>) new AreaCodeLineItemSelector()
                .selectMasterItemsAllFieldsForCloning(new List<Object> {Trigger.newMap.keySet()})
                .executeQuery();

            Set<Id> masterQliIds = new Set<Id>();
            for (Area_Code_Line_Item__c acli : masterAclis) {
                if (AreaCodeLineItemTriggerHelper.isMasterAreaCodeLineItem(acli)) {
                    masterQliIds.add(acli.Quote_Line_Item__r.Id);
                }
            }

            if (masterQliIds.isEmpty()) {
                return;
            }

            List<QuoteLineItem> relatedTechnicalQlis = new QuoteLineItemSelector()
                .selectQuoteLineItemsByMasterQliIds(masterQliIds)
                .executeQuery();

            List<Area_Code_Line_Item__c> acliToInsert = new List<Area_Code_Line_Item__c>();
            for (Area_Code_Line_Item__c masterAcli : masterAclis) {
                for (QuoteLineItem technicalQli : relatedTechnicalQlis) {
                    if (masterAcli.Quote_Line_Item__r.Id == technicalQli.MasterQLI__c) {
                        Area_Code_Line_Item__c technicalAcli = masterAcli.clone(false, true, false, false);
                        technicalAcli.Quote_Line_Item__c = technicalQli.Id;
                        acliToInsert.add(technicalAcli);
                        break;
                    }
                }
            }

            insert acliToInsert;
        }
    }

    private static boolean isMasterAreaCodeLineItem(Area_Code_Line_Item__c acli) {
        return acli.Quote_Line_Item__r.MasterQLI__c == null && !acli.Quote_Line_Item__r.IsMultiProductTechnicalQLI__c;
    }

    public class CopyLineItemFromMasterToTechnicalQliOnUpdate extends Triggers.TriggerHandlerBase {
        override public void handle() {
            List<Area_Code_Line_Item__c> masterAclis = (List<Area_Code_Line_Item__c>) new AreaCodeLineItemSelector()
                .selectMasterItemsAllFieldsForCloning(new List<Object> {Trigger.newMap.keySet()})
                .executeQuery();

            Set<Id> masterQliIds = new Set<Id>();
            for (Area_Code_Line_Item__c acli : masterAclis) {
                if (AreaCodeLineItemTriggerHelper.isMasterAreaCodeLineItem(acli)) {
                    masterQliIds.add(acli.Quote_Line_Item__r.Id);
                }
            }

            if (masterQliIds.isEmpty()) {
                return;
            }

            List<Area_Code_Line_Item__c> relatedTechnicalAreaCodeItems = (List<Area_Code_Line_Item__c>) new AreaCodeLineItemSelector()
                .selectTechnicalItemsByMasterQliId(new List<Object> {masterQliIds})
                .executeQuery();

            List<Area_Code_Line_Item__c> acliToUpdate = new List<Area_Code_Line_Item__c>();
            for (Area_Code_Line_Item__c masterAcli : masterAclis) {
                for (Area_Code_Line_Item__c technicalAcli : relatedTechnicalAreaCodeItems) {
                    if (masterAcli.Quote_Line_Item__r.Id == technicalAcli.Quote_Line_Item__r.MasterQLI__c && masterAcli.Area_Code__c == technicalAcli.Area_Code__c) {
                        Area_Code_Line_Item__c updatedTechnicalAcli = masterAcli.clone(false, true, false, false);
                        updatedTechnicalAcli.Id = technicalAcli.Id;
                        updatedTechnicalAcli.Quote_Line_Item__c = technicalAcli.Quote_Line_Item__c;
                        acliToUpdate.add(updatedTechnicalAcli);
                        break;
                    }
                }
            }

            update acliToUpdate;
        }
    }

    public class DeleteLineItemsOnTechnicalQlisOnMasterDelete extends Triggers.TriggerHandlerBase {
        override public void handle() {
            List<Area_Code_Line_Item__c> masterAclis = (List<Area_Code_Line_Item__c>) new AreaCodeLineItemSelector()
                .selectMasterItemsAllFieldsForCloning(new List<Object> {Trigger.oldMap.keySet()})
                .executeQuery();

            Set<Id> masterQliIds = new Set<Id>();
            for (Area_Code_Line_Item__c acli : masterAclis) {
                if (AreaCodeLineItemTriggerHelper.isMasterAreaCodeLineItem(acli)) {
                    masterQliIds.add(acli.Quote_Line_Item__r.Id);
                }
            }

            if (masterQliIds.isEmpty()) {
                return;
            }

            List<Area_Code_Line_Item__c> relatedTechnicalAreaCodeItems = (List<Area_Code_Line_Item__c>) new AreaCodeLineItemSelector()
                .selectTechnicalItemsByMasterQliId(new List<Object> {masterQliIds})
                .executeQuery();

            List<Area_Code_Line_Item__c> acliToDelete = new List<Area_Code_Line_Item__c>();
            for (Area_Code_Line_Item__c masterAcli : masterAclis) {
                for (Area_Code_Line_Item__c technicalAcli : relatedTechnicalAreaCodeItems) {
                    if (masterAcli.Quote_Line_Item__r.Id == technicalAcli.Quote_Line_Item__r.MasterQLI__c && !acliToDelete.contains(technicalAcli)) {
                        acliToDelete.add(technicalAcli);
                        break;
                    }
                }
            }

            delete acliToDelete;
        }
    }
}