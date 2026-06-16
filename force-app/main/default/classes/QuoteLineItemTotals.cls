public with sharing class QuoteLineItemTotals {

    // temporary solution until legact QT controller test class is refactored
    public static Boolean bypassQuoteLineItemTotals = false;

    public class PopulateDiscountAndEffectivePrice extends Triggers.TriggerHandlerBase {

        override public void handle() {

            List<QuoteLineItem> qliToProcessList = new List<QuoteLineItem>();

            for(QuoteLineItem qli : (List<QuoteLineItem>) Trigger.new) {
                qliToProcessList.add(qli);
            }

            if(qliToProcessList.isEmpty()) {
                return;
            }

            List<QuoteLineItem> updatedQliList = populateFields(qliToProcessList);
        }

        @TestVisible
        private List<QuoteLineItem> populateFields(List<QuoteLineItem> qliListToProcess) {
            if(qliListToProcess == null || qliListToProcess.isEmpty()) {
                return new List<QuoteLineItem>();
            }

            List<QuoteLineItem> processedQlis = new List<QuoteLineItem>();

            for(QuoteLineItem qli : qliListToProcess) {

                Decimal qliDiscount = qli.Discount == null ? 0 : qli.Discount;
                qliDiscount = qliDiscount / 100; // in QuoteLineItem.Discount field value always stored as percent

                Decimal qliUnitPrice = qli.UnitPrice == null ? 0 : qli.UnitPrice;

                qli.DiscountValueNew__c = qliUnitPrice * qliDiscount;
                qli.EffectivePriceNew__c = qli.QuoteRecordType__c == QuoteHelper.RT_NAME_CONTACT_CENTER
                    ? qliUnitPrice * (1 - qliDiscount)
                    : (qliUnitPrice * (1 - qliDiscount)).setScale(2);

                processedQlis.add(qli);
            }

            return processedQlis;
        }
    }

    class CannotFindEntitlementException extends Exception {}

    public class PopulateQLITotals extends Triggers.TriggerHandlerBase {

        override public void handle() {
            if (bypassQuoteLineItemTotals) {
                return;
            }

            List<QuoteLineItem> qliToProcessList = new List<QuoteLineItem>();

            for(QuoteLineItem qli : (List<QuoteLineItem>) Trigger.new) {
                qliToProcessList.add(qli);
            }

            if(qliToProcessList.isEmpty()) {
                return;
            }

            List<QuoteLineItem> updatedQliList = populateTotalFields(
                qliToProcessList,
                QuoteLineItemTriggerHelper.productsMapStatic,
                QuoteLineItemTriggerHelper.entitlementsMapStatic
            );
        }

        @TestVisible
        private List<QuoteLineItem> populateTotalFields(
            List<QuoteLineItem> qliListToProcess,
            Map<Id, Product2> productsMap,
            Map<Id, Entitlement__c> entitilementsMap
        ) {
            Decimal qliQuantity = 0;
            Decimal qliNewQuantity = 0;
            String qliChargeTerm = '';
            String entitlementChargeTerm = '';

            if(qliListToProcess == null || qliListToProcess.isEmpty()) {
                return new List<QuoteLineItem>();
            }

            List<QuoteLineItem> processedQlis = new List<QuoteLineItem>();

            for(QuoteLineItem qli : qliListToProcess) {
                qliQuantity = QuoteLineItemHelper.getQuantity(qli);
                qliNewQuantity = (Decimal) NumberHelper.getNumberNullSafe(qli.NewQuantity__c);

                qli.Product2 = productsMap.get(qli.Product2Id);
                qliChargeTerm = QuoteLineItemHelper.getChargeTerm(qli);

                qli.Total_Annual__c = computeTotalAnnual(
                    qliChargeTerm,
                    qliQuantity,
                    qli.EffectivePriceNew__c
                );

                qli.Total_Monthly__c = computeTotalMonthly(
                    qliChargeTerm,
                    qliQuantity,
                    qli.EffectivePriceNew__c
                );

                qli.Total_One_Time__c = computeTotalOneTime(
                    qliChargeTerm,
                    (AccountHelper.isTrial(QuoteLineItemTriggerHelper.quotesMapStatic.get(qli.QuoteId).Account)
                    || QuoteLineItemTriggerHelper.quotesMapStatic.get(qli.QuoteId).Account.Offer_Type__c == AccountHelper.OFFER_TYPE_POC)
                        ? qliNewQuantity
                        : qliQuantity,
                    qli.EffectivePriceNew__c
                );

                qli.TotalSummary__c = qli.EffectivePriceNew__c * qliNewQuantity;

                Decimal entlDisplayQuantity = 0;
                Decimal entlEffectivePrice = 0;

                if(qli.Entitlement__c != null && entitilementsMap != null && entitilementsMap.containsKey(qli.Entitlement__c)) {
                    Entitlement__c entl = entitilementsMap.get(qli.Entitlement__c);

                    if (entl.PackageDuration__c != null) {
                        entitlementChargeTerm = entl.PackageDuration__c;
                    } else if (entl.Product__c == null || entl.Product__r.Charge_Term__c == null) {
                        entitlementChargeTerm = qliChargeTerm;
                    }else{
                        entitlementChargeTerm = entl.Product__r.Charge_Term__c;
                    }

                    entlDisplayQuantity = (Decimal) QuoteTotals.getRelatedData(qli.QuoteRecordType__c, entl, Entitlement__c.DisplayQuantity__c);
                    entlEffectivePrice = EntitlementHelper.getEntitlementEffectivePrice(entl);

                }else if(qli.Entitlement__c != null && entitilementsMap != null && !entitilementsMap.containsKey(qli.Entitlement__c)) {
                    // quoteLineItem has entitlement, but that entitlement not found in entitlement map
                    throw new CannotFindEntitlementException('cannot find entitlement with Id: ' + qli.Entitlement__c);
                }else if(qli.Entitlement__c == null) {
                    entitlementChargeTerm = qliChargeTerm;
                }

                qli.Delta_MRR__c = computeDeltaMrr(
                    qliChargeTerm,
                    qliQuantity,
                    qli.EffectivePriceNew__c,
                    entlDisplayQuantity,
                    entlEffectivePrice,
                    entitlementChargeTerm,
                    qli.Product2.Family
                );

                qli.Delta_ARR__c = computeDeltaArr(
                    qliChargeTerm,
                    qliQuantity,
                    qli.EffectivePriceNew__c,
                    entlDisplayQuantity,
                    entlEffectivePrice,
                    entitlementChargeTerm,
                    qli.Product2.Family
                );

                processedQlis.add(qli);
            }

            calculateHierarchySummaries(qliListToProcess);

            return processedQlis;
        }

        @TestVisible
        private Decimal computeTotalOneTime(String productChargeTerm, Decimal quantity, Decimal effectivePrice) {
            Decimal result = 0;

            if(String.isBlank(productChargeTerm)) {
                return result;
            }

            Decimal quantityValue = 0;
            Decimal effectivePriceValue = 0;

            if(quantity != null) {
                quantityValue = quantity;
            }

            if(effectivePrice != null) {
                effectivePriceValue = effectivePrice;
            }

            if(productChargeTerm == Product2Helper.CHARGE_TERM_ONE_TIME) {
                result = quantityValue * effectivePriceValue;
            }

            return result;
        }

        @TestVisible
        private Decimal computeTotalMonthly(String productChargeTerm, Decimal quantity, Decimal effectivePrice) {

            Decimal result = 0;

            if(String.isBlank(productChargeTerm)) {
                return result;
            }

            Decimal quantityValue = 0;
            Decimal effectivePriceValue = 0;

            if(quantity != null) {
                quantityValue = quantity;
            }

            if(effectivePrice != null) {
                effectivePriceValue = effectivePrice;
            }

            if(new Set<String>{
                Product2Helper.CHARGE_TERM_MONTHLY,
                Product2Helper.CHARGE_TERM_MONTHLY_CONTRACT
            }.contains(productChargeTerm)) {
                result = quantityValue * effectivePriceValue;
            }else if(productChargeTerm == Product2Helper.CHARGE_TERM_ANNUAL) {
                result = (quantityValue * effectivePriceValue) / 12;
            }

            return result;
        }

        @TestVisible
        private Decimal computeTotalAnnual(String productChargeTerm, Decimal quantity, Decimal effectivePrice) {

            Decimal result = 0;

            if(String.isBlank(productChargeTerm)) {
                return result;
            }

            Decimal quantityValue = 0;
            Decimal effectivePriceValue = 0;

            if(quantity != null) {
                quantityValue = quantity;
            }

            if(effectivePrice != null) {
                effectivePriceValue = effectivePrice;
            }

            if(new Set<String>{
                Product2Helper.CHARGE_TERM_MONTHLY,
                Product2Helper.CHARGE_TERM_MONTHLY_CONTRACT
            }.contains(productChargeTerm)) {
                result = (quantityValue * effectivePriceValue) * 12;
            }else if(productChargeTerm == Product2Helper.CHARGE_TERM_ANNUAL) {
                result = quantityValue * effectivePriceValue;
            }

            return result;
        }

        @TestVisible
        private Decimal computeDeltaMrr(
            String productChargeTerm,
            Decimal quantity,
            Decimal effectivePrice,
            Decimal entlDisplayQuantity,
            Decimal entlEffectivePrice,
            String entitlementChargeTerm,
            String family
        ) {
            Decimal result = 0;

            if (family == 'Taxes') {
                return result;
            }

            if(productChargeTerm == Product2Helper.CHARGE_TERM_ONE_TIME) {
                return result;
            }

            Decimal quantityValue = 0;
            Decimal effectivePriceValue = 0;
            Decimal entlDisplayQuantityValue = 0;
            Decimal entlEffectivePriceValue = 0;

            if(quantity != null) {
                quantityValue = quantity;
            }

            if(effectivePrice != null) {
                effectivePriceValue = effectivePrice;
            }

            if(entlDisplayQuantity != null) {
                entlDisplayQuantityValue = entlDisplayQuantity;
            }

            if(entlEffectivePrice != null) {
                entlEffectivePriceValue = entlEffectivePrice;
            }

            if(productChargeTerm != Product2Helper.CHARGE_TERM_ANNUAL && entitlementChargeTerm != Product2Helper.CHARGE_TERM_ANNUAL) {
                result = ((quantityValue + entlDisplayQuantityValue) * effectivePriceValue) -
                    (entlDisplayQuantityValue * entlEffectivePriceValue);
            }else if(productChargeTerm != Product2Helper.CHARGE_TERM_ANNUAL && entitlementChargeTerm == Product2Helper.CHARGE_TERM_ANNUAL) {
                result = ((quantityValue + entlDisplayQuantityValue) * effectivePriceValue) -
                    ((entlDisplayQuantityValue * entlEffectivePriceValue) / 12);
            }else if(productChargeTerm == Product2Helper.CHARGE_TERM_ANNUAL && entitlementChargeTerm == Product2Helper.CHARGE_TERM_ANNUAL) {
                result = (((quantityValue + entlDisplayQuantityValue) * effectivePriceValue) / 12) -
                    ((entlDisplayQuantityValue * entlEffectivePriceValue) / 12);
            }else if(productChargeTerm == Product2Helper.CHARGE_TERM_ANNUAL && entitlementChargeTerm != Product2Helper.CHARGE_TERM_ANNUAL) {
                result = (((quantityValue + entlDisplayQuantityValue) * effectivePriceValue) / 12) -
                    (entlDisplayQuantityValue * entlEffectivePriceValue);
            }

            return result;
        }

        @TestVisible
        private Decimal computeDeltaArr(
            String productChargeTerm,
            Decimal quantity,
            Decimal effectivePrice,
            Decimal entlDisplayQuantity,
            Decimal entlEffectivePrice,
            String entitlementChargeTerm,
            String family
        ) {
            Decimal result = 0;

            if (family == 'Taxes') {
                return result;
            }

            if(productChargeTerm == Product2Helper.CHARGE_TERM_ONE_TIME) {
                return result;
            }

            Decimal quantityValue = 0;
            Decimal effectivePriceValue = 0;
            Decimal entlDisplayQuantityValue = 0;
            Decimal entlEffectivePriceValue = 0;

            if(quantity != null) {
                quantityValue = quantity;
            }

            if(effectivePrice != null) {
                effectivePriceValue = effectivePrice;
            }

            if(entlDisplayQuantity != null) {
                entlDisplayQuantityValue = entlDisplayQuantity;
            }

            if(entlEffectivePrice != null) {
                entlEffectivePriceValue = entlEffectivePrice;
            }

            if(productChargeTerm != Product2Helper.CHARGE_TERM_ANNUAL && entitlementChargeTerm != Product2Helper.CHARGE_TERM_ANNUAL) {
                result = (((quantityValue + entlDisplayQuantityValue) * effectivePriceValue) * 12) -
                    ((entlDisplayQuantityValue * entlEffectivePriceValue) * 12);
            }else if(productChargeTerm != Product2Helper.CHARGE_TERM_ANNUAL && entitlementChargeTerm == Product2Helper.CHARGE_TERM_ANNUAL) {
                result = (((quantityValue + entlDisplayQuantityValue) * effectivePriceValue) * 12) -
                    (entlDisplayQuantityValue * entlEffectivePriceValue);
            }else if(productChargeTerm == Product2Helper.CHARGE_TERM_ANNUAL && entitlementChargeTerm == Product2Helper.CHARGE_TERM_ANNUAL) {
                result = ((quantityValue + entlDisplayQuantityValue) * effectivePriceValue) -
                    (entlDisplayQuantityValue * entlEffectivePriceValue);
            }else if(productChargeTerm == Product2Helper.CHARGE_TERM_ANNUAL && entitlementChargeTerm != Product2Helper.CHARGE_TERM_ANNUAL) {
                result = ((quantityValue + entlDisplayQuantityValue) * effectivePriceValue) -
                    ((entlDisplayQuantityValue * entlEffectivePriceValue) * 12);
            }

            return result;
        }

        @TestVisible
        public void calculateHierarchySummaries(List<QuoteLineItem> qliListToProcess) {
            Map<Id, Map<Id, QuoteLineItem>> quoteIdToProdIdToQLIMap = new Map<Id, Map<Id, QuoteLineItem>>();

            if (QuoteLineItemTriggerHelper.quoteIdToProdIdToQLIMap.isEmpty()) {
                for (QuoteLineItem qli : qliListToProcess) {
                    if (!quoteIdToProdIdToQLIMap.containsKey(qli.QuoteId)) {
                        quoteIdToProdIdToQLIMap.put(qli.QuoteId, new Map<Id, QuoteLineItem>());
                    }
                    Map<Id, QuoteLineItem> prodIdToQLIMap = quoteIdToProdIdToQLIMap.get(qli.Quoteid);
                    prodIdToQLIMap.put(qli.Product2Id, qli);
                }
            } else {
                quoteIdToProdIdToQLIMap = QuoteLineItemTriggerHelper.quoteIdToProdIdToQLIMap;
            }
            
            Map<Id, Quote> quoteMap = new Map<Id, Quote>([Select Id, PackageNameNew__c From Quote Where Id =: quoteIdToProdIdToQLIMap.keyset()]);
			
            for (QuoteLineItem qli : qliListToProcess) {
                if (
                    String.isBlank(qli.QuoteId)
                    || quoteIdToProdIdToQLIMap.get(qli.QuoteId) == null
                    || quoteIdToProdIdToQLIMap.get(qli.QuoteId).isEmpty()
                ) {
                    continue;
                }

                qli.TotalHierarchySummary__c = (Decimal) NumberHelper.getNumberNullSafe(qli.EffectivePriceNew__c) * (Decimal) NumberHelper.getNumberNullSafe(qli.NewQuantity__c);
                qli.DeltaHierarchySummary__c = QuoteLineItemHelper.getDeltaRecurringRevenue(qli);
                if (isRootElement(qli)) {
                    List<QuoteLineItem> childQLIs = getChildQLIsForParent(
                        qli,
                        quoteIdToProdIdToQLIMap.get(qli.QuoteId).values()
                    );
                    for (QuoteLineItem childQli : childQLIs) {
                        if (
                            String.isBlank(QuoteLineItemHelper.getCategoryPath(qli))
                            || QuoteLineItemHelper.getCategoryPath(qli).equalsIgnoreCase(QuoteLineItemHelper.getCategoryPath(childQli))
                        ) {
                            // skip parent element in child list
                            continue;
                        }
                        qli.TotalHierarchySummary__c += childQli.EffectivePriceNew__c * qli.NewQuantity__c;
                        //if not AIR package, then calculate DeltaHierarchySummary__c for licenses other than AIR
                        //if AIR package, then calculate DeltaHierarchySummary__c for all licenses including AIR
                        Boolean isAIRPackage = !quoteMap.isEmpty() && quoteMap.containsKey(qli.QuoteId) && quoteMap.get(qli.QuoteId).PackageNameNew__c == 'RingCentral AIR';
                        if((isAIRPackage || (!isAIRPackage && QuoteLineItemHelper.getCategoryPath(qli) != 'AIR')) && QuoteLineItemHelper.getQuantity(childQli) != 0){
                            qli.DeltaHierarchySummary__c += QuoteLineItemHelper.getDeltaRecurringRevenue(childQli)
                                * QuoteLineItemHelper.getQuantity(qli)
                                / QuoteLineItemHelper.getQuantity(childQli);
                        }
                    }
                }
            }
        }

        private Boolean isRootElement(QuoteLineItem qli) {
            for (PdfHierarchySettings__mdt setting : QuoteLineItemHelper.hierarchySettings) {
                if (setting.Parent__c.equalsIgnoreCase(QuoteLineItemHelper.getCategoryPath(qli))) {
                    return true;
                }
            }

            return false;
        }

        private Boolean isChildElement(QuoteLineItem qli) {
            for (PdfHierarchySettings__mdt setting : QuoteLineItemHelper.hierarchySettings) {
                if (setting.Childs__c.split(',').contains(QuoteLineItemHelper.getCategoryPath(qli))) {
                    return true;
                }
            }

            return false;
        }

        private Boolean isNotInHierarchy(QuoteLineItem qli) {
            return !isRootElement(qli) && !isChildElement(qli);
        }

        private List<QuoteLineItem> getChildQLIsForParent(QuoteLineItem parentQLI, List<QuoteLineItem> allQlis) {
            List<QuoteLineItem> res = new List<QuoteLineItem>();

            PdfHierarchySettings__mdt currentMdt;

            for (PdfHierarchySettings__mdt m : QuoteLineItemHelper.hierarchySettings) {
                if (m.Parent__c.equalsIgnoreCase(QuoteLineItemHelper.getCategoryPath(parentQli))) {
                    currentMdt = m;
                    break;
                }
            }

            List<String> childPaths = currentMdt.Childs__c.split(',');

            for (QuoteLineItem qli : allQlis) {
                if (qli.QuoteId != parentQli.QuoteId) {
                    continue;
                }
                if (childPaths.contains(QuoteLineItemHelper.getCategoryPath(qli))) {
                    res.add(qli);
                }
            }

            return res;
        }
    }
}