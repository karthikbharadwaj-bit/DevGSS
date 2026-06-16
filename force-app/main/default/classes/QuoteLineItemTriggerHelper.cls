/*
* Name         : QuoteLineItemTriggerHelper.cls
* Created By   : Dmitry Nikitin (dnikitin@aquivalabs.com)
* Created Date : 28/Apr/2016
* Description  : Class contains methods for QuoteLineItem trigger
*/
public with sharing class QuoteLineItemTriggerHelper {

    public static boolean bypassQuoteApprovedStatusChangeLogic = false;
    public static boolean bypassQuantityChangeLogic = false;
    public static boolean bypassSalesRepErase = false;
    public static boolean isRequirePrimaryQuoteApproval = false;
    public static boolean isApprovedPrimaryQuoteApproval = false;

    public static Map<Id, Product2> productsMapStatic = new Map<Id, Product2>();
    public static Map<Id, Quote> quotesMapStatic = new Map<Id, Quote>();
    public static Map<Id, PriceBookEntry> priceBookEntryMapStatic = new Map<Id, PriceBookEntry>();
    public static Set<Id> qliIdsToBypassQuantityChange = new Set<Id>();
    public static Map<Id, User> usersStaticMap = new Map<Id, User>();
    public static Map<Id, Map<Id, QuoteLineItem>> quoteIdToProdIdToQLIMap = new Map<Id, Map<Id, QuoteLineItem>>();
    public static Map<Id, List<Area_Code_Line_Item__c>> qliIdToAreaCodeLineItemsListMap;
    public static Map<Id, Entitlement__c> entitlementsMapStatic = new Map<Id, Entitlement__c>();

    public static Set<Id> filteredFromTaxesQuotes = new Set<Id>();
    public static Set<Id> product2IdOnInsertSet = new Set<Id>();

    public static String IVINEX_UNIFIED_USER_EXPERIENCE_PER_CONCURRENT_USER = '1508-821-000';
    public static String IVINEX_UNIFIED_USER_EXPERIENCE_PER_CONFIGURED_USER = '1508-813-000';
    public static String IVINEX_UNIFIED_USER_EXPERIENCE_ADDITIONAL_STORAGE = '1508-815-000';
    public static String IVINEX_UNIFIED_USER_EXPERIENCE_BU_CHARGE = '1508-1091-000';

    // Account Id to Entitlements
    public static Map<Id, List<Entitlement__c>> accountIdToEntitlements = new Map<Id, List<Entitlement__c>>();

    //B-1753 common overages is no longer matching by parent
    public static Set<String> commonOverageTypes = new Set<String>{'IVN',
            'International',
            'Storage Usage',
            'ProServOnDemand',
            'IncomingSMS',
            'OutgoingSMS',
            'OutgoingSMSRate',
            'SmsTfLongRate',
            'Non-emergency Service Short Code UK',
            'Premium Short Code 118 Number UK',
            'Premium Short Code UK',
            'Premium Range UK',
            'Premium Range UK'
        };

    private static Map<Id, Map<Id, QuoteLineItem>> setQuoteIdToProdIdToQLIMap(Set<Id> missedQuoteIdSet, Map<Id, Map<Id, QuoteLineItem>> quoteIdToProdIdToQLIMap) {
        List<QuoteLineItem> qliList = new QuoteLineItemSelector()
            .selectQuoteLineItemsForQLITrigger(missedQuoteIdSet)
            .executeQuery();

        for(QuoteLineItem qli : qliList) {
            if (!quoteIdToProdIdToQLIMap.containsKey(qli.QuoteId)) {
                quoteIdToProdIdToQLIMap.put(qli.Quoteid, new Map<Id, QuoteLineItem>());
            }
            Map<Id, QuoteLineItem> prodIdToQLIMap = quoteIdToProdIdToQLIMap.get(qli.Quoteid);
            prodIdToQLIMap.put(qli.Product2Id, qli);
        }

        //undelete logic - currenty not supported
        qliList = new List<QuoteLineItem>();
        if (Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)) {
            qliList = (List<QuoteLineItem>) Trigger.new;
        } else if (Trigger.isBefore && Trigger.isDelete) {
            qliList = (List<QuoteLineItem>) Trigger.old;
        }

        for (QuoteLineItem qli : qliList) {
            if (!quoteIdToProdIdToQLIMap.containsKey(qli.QuoteId)) {
                quoteIdToProdIdToQLIMap.put(qli.Quoteid, new Map<Id, QuoteLineItem>());
            }
            Map<Id, QuoteLineItem> prodIdToQLIMap = quoteIdToProdIdToQLIMap.get(qli.Quoteid);
            prodIdToQLIMap.put(qli.Product2Id, qli);
        }

        return quoteIdToProdIdToQLIMap;
    }

    public class ManageQuotesMapStatic extends Triggers.TriggerHandlerBase {
        override public void handle() {
            Set<Id> quoteIds = new Set<Id>();

            if (Trigger.isBefore) {
                for(QuoteLineItem qli: (List<QuoteLineItem>) this.TriggerRecords) {
                    quoteIds.add(qli.QuoteId);
                }
            }

            Set<Id> quoteIdsToLoad = new Set<Id>();
            for (Id qtId : quoteIds) {
                if (!quotesMapStatic.containsKey(qtId)) {
                    quoteIdsToLoad.add(qtId);
                }
            }

            if (!quoteIdsToLoad.isEmpty()) {
                List<Quote> quotesList = (List<Quote>) new QuoteSelector()
                    .selectQuotesForQuoteLineItemTrigger(quoteIdsToLoad)
                    .executeQuery();

                quotesMapStatic.putAll(quotesList);
            }
        }
    }

    public class UpdateQuoteOnQuoteLineItemUpdate extends Triggers.TriggerHandlerBase {

        private final String IN_PROGRESS_PROSERV_STATUS = 'In progress';

        private final String SALES_QUOTE_RT_NAME = 'Sales Quote';
        private final String PROSERV_QUOTE_RT_NAME = 'ProServ Quote';
        private final String CC_PROSERV_QUOTE_RT_NAME = 'CC ProServ Quote';

        private final Map<String, Schema.RecordTypeInfo> QUOTE_RT_INFO_BY_NAME =
                Quote.SObjectType.getDescribe().getRecordTypeInfosByName();

        private final Id SALES_QUOTE_RT_ID = QUOTE_RT_INFO_BY_NAME.get(SALES_QUOTE_RT_NAME).getRecordTypeId();
        private final Id PROSERV_QUOTE_RT_ID = QUOTE_RT_INFO_BY_NAME.get(PROSERV_QUOTE_RT_NAME).getRecordTypeId();
        private final Id CC_PROSERV_QUOTE_RT_ID = QUOTE_RT_INFO_BY_NAME.get(CC_PROSERV_QUOTE_RT_NAME).getRecordTypeId();

        private final String PROSERV_PRODUCT_SUBCATEGORY = 'Professional Services';
        private final String CC_PROSERV_PRODUCT_SUBCATEGORY = 'CC Professional Services';

        override public void handle() {
            Set<Id> quoteIds = new Set<Id>();
            Set<Id> productIds = new Set<Id>();

            List<QuoteLineItem> qliWithUpdatedQuantity = new List<QuoteLineItem>();
            Map<Id, Map<Id, QuoteLineItem>> qliToUpdateQuantityInScope = new Map<Id, Map<Id, QuoteLineItem>>();
            Set<Id> priceBookEntryIds = new Set<Id>();

            Map<Id, Map<Id, QuoteLineItem>> quoteToQLIMap = new Map<Id, Map<Id, QuoteLineItem>>();
            Map<Id, Map<Id, QuoteLineItem>> quoteToQLIFilteredMap = new Map<Id, Map<Id, QuoteLineItem>>();

            Map <Id, QuoteLineItem> deletedQuotelineItemMap = new Map<Id, QuoteLineItem>();
            for(QuoteLineItem qli: trigger.isDelete ? (List<QuoteLineItem>)trigger.old : (List<QuoteLineItem>)trigger.new){
                //QuoteLineItem oldQLI = trigger.isInsert ? qli : (QuoteLineItem)trigger.oldMap.get(qli.Id);
                quoteIds.add(qli.QuoteId);

                if(trigger.isDelete){
                    // for after insert put it into the map here in case if there are no more QuoteLineItems for this
                    // quote at all, so we need to clear InvalidDiscountedPhonesQuantity__c flag
                    quoteToQLIFilteredMap.put(qli.QuoteId, new Map<Id, QuoteLineItem>());
                    productIds.add(qli.Product2Id);
                    deletedQuotelineItemMap.put(qli.Id, qli);
                }else{
                    if(trigger.isInsert || (qli.Quantity != ((QuoteLineItem)trigger.oldMap.get(qli.Id)).Quantity)) {
                        qliWithUpdatedQuantity.add(qli);
                    }

                    if(trigger.isBefore){
                        productIds.add(qli.Product2Id);
                        priceBookEntryIds.add(qli.PriceBookEntryId);

                        if(!qliToUpdateQuantityInScope.containsKey(qli.QuoteId)) {
                            qliToUpdateQuantityInScope.put(qli.QuoteId, new Map<Id, QuoteLineItem>());
                        }
                        qliToUpdateQuantityInScope.get(qli.QuoteId).put(qli.Id, qli);
                    }else{
                        if(!quoteToQLIFilteredMap.containsKey(qli.QuoteId)) {
                            quoteToQLIFilteredMap.put(qli.QuoteId, new Map<Id, QuoteLineItem>());
                        }
                        quoteToQLIFilteredMap.get(qli.QuoteId).put(qli.Id, qli);
                    }
                }
            }

            if (!Trigger.isDelete) {
                Set<Id> entsToLoad = new Set<Id>();
                for (QuoteLineItem entry : (QuoteLineItem[])Trigger.new) {
                    if (entry.Entitlement__c != null && !entitlementsMapStatic.containsKey(entry.Entitlement__c)) {
                        entsToLoad.add(entry.Entitlement__c);
                    }
                }
                if (!entsToLoad.isEmpty()) {
                    for (Entitlement__c entry : [
                        SELECT Name, Discount_Type__c, Price__c, Discount__c, DisplayQuantity__c, EffectivePrice__c, Product__c, Product__r.Charge_Term__c, PackageDuration__c
                        FROM Entitlement__c
                        WHERE Id IN :entsToLoad
                    ])
                    {
                        entitlementsMapStatic.put(entry.Id, entry);
                    }
                }
            }

            Boolean doSOQL = false;
            if(trigger.isBefore){
                for (Id pId : productIds) {
                    if (!productsMapStatic.containsKey(pId)) {
                        doSOQL = true;
                    }
                }
                if (doSOQL){
                    for(Product2 p2:[SELECT Id, Name, Family, Feature__c, Sub_Feature__c, Sub_Category__c, Charge_Term__c, ExtID__c FROM Product2 WHERE Id IN :productIds]){
                        productsMapStatic.put(p2.Id, p2);
                    }
                }
                doSOQL = false;
                for (Id pId : priceBookEntryIds) {
                    if (!priceBookEntryMapStatic.containsKey(pId)) {
                        doSOQL = true;
                    }
                }
                if (doSOQL){
                    for(PriceBookEntry pbe:[SELECT Id, Per_Line__c, CurrencyIsoCode, Min_Quantity__c, Max_Quantity__c,
                            Max_DIscount__c, Pricebook2Id, Pricebook2.Line_Range_Min__c,
                            Pricebook2.Line_Range_Max__c, Pricebook2.Name, Product2.Name,
                            Product2.Family, Product2Id, UnitPrice, Product2.Description,
                            Product2.Feature__c, Product2.Product_Type__c, Product2.Dependent_on_Feature__c,
                            Product2.Charge_Term__c, Pricebook2.Tier_ID__c, Product2.Sub_Category__c
                    FROM PriceBookEntry
                    WHERE Id IN :priceBookEntryIds]){
                        priceBookEntryMapStatic.put(pbe.Id, pbe);
                    }
                }
            }

            // this before trigger is required to avoid recursion
            // when Quote.Total_Number_of_Digital_Lines__c is changed SetDefaultLineItems trigger will
            // update child QuoteLineItem which could already be in trigger context
            // in this case Salesforce will throw an SELF_REFERENCE_FROM_TRIGGER exception
            // So when we know that Quote.Total_Number_of_Digital_Lines__c will be changed, and there is
            // some other QUoteLineItems for this Quote in trigger context,
            // then update them in before triggger and skipp update for this records in Quote trigger
            if(trigger.isBefore){
                if (Trigger.isUpdate) {
                    System.debug('QLI quantity might change here');
                    for(QuoteLineItem qli:qliWithUpdatedQuantity){

                        /* Suggest we don't need to do it for new billing (same code exist in QuoteTriggerHelper) */
                        if (QuoteHelper.isNewBillingQuote(qli)) {
                            continue;
                        }

                        if(productsMapStatic.containsKey(qli.Product2Id) && quotesMapStatic.containsKey(qli.QuoteId)){
                            Product2 p = productsMapStatic.get(qli.Product2Id);
                            Quote qt = quotesMapStatic.get(qli.QuoteId);
                            Decimal qliQuantity = QuoteLineItemHelper.getResultingQuantity(qli, entitlementsMapStatic.get(qli.Entitlement__c));
                            if ((p.Family == 'Tier' || p.Family == 'Service')
                                    && qt.Total_Number_of_Digital_Lines__c != qliQuantity
                                    && qliToUpdateQuantityInScope.containsKey(qli.QuoteId)){

                                for(QuoteLineItem qliToUpdate:qliToUpdateQuantityInScope.get(qli.QuoteId).values()){
                                    if(qliToUpdate.Id != qli.Id){
                                        Product2 prodForNonTierQLI = productsMapStatic.get(qliToUpdate.Product2Id);
                                        PriceBookEntry pbe = priceBookEntryMapStatic.get(qliToUpdate.PriceBookEntryId);
                                        System.debug('prodForNonTierQLI.Name: ' + prodForNonTierQLI.Name + '  :pbe.Per_Line__c:  ' + pbe.Per_Line__c);
                                        if(pbe.Per_Line__c && prodForNonTierQLI.Family != 'Tier' && prodForNonTierQLI.Family != 'Service'){
                                            if(isChangedQuoteLineItemQuantity(qliToUpdate, qli.Quantity, pbe)){
                                                qliIdsToBypassQuantityChange.add(qliToUpdate.Id);
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                } else {
                    Map<Id,Quote> quoteToUpdateMap = new Map <Id, Quote>();
                    //Walk through deleted quote line items and check if Taxes are deleted
                    //If taxes are deleted Estimated_Taxes_Request_Failed__c check box set to unchecked
                    for(QuoteLineItem deletedQli : deletedQuotelineItemMap.values()) {
                        if (productsMapStatic.get(deletedQli.Product2Id).Family == 'Taxes') {
                           quotesMapStatic.get(deletedQli.QuoteId).Estimated_Taxes_Request_Failed__c = false;
                           quoteToUpdateMap.put(quotesMapStatic.get(deletedQli.QuoteId).Id, quotesMapStatic.get(deletedQli.QuoteId));
                        }
                    }
                    if (!quoteToUpdateMap.isEmpty()) {
                        update quoteToUpdateMap.values();
                    }
                }

            } else {

                List<Decimal> featureIds = new List<Decimal>{12,17,18,47,50};
                Set<String> productFamilyFilterSet = new Set<String>{
                                'Discounted Phones',
                                'Rental Phones',
                                'Refurbished Phones',
                                'Global Office Discounted Phones',
                                'Global Office Rental Phones',
                                'Global Office Refurbished Phones',
                                'Limited Extension Discounted Phones',
                                'Limited Extension Rental Phones',
                                'Common Discounted Phones',
                                'Common Refurbished Phones',
                                'Common Rental Phones',
                                'Add - Ons',
                                'Global Office - Limited Extension Discounted Phones',
                                'Global Office - Limited Extension Rental Phones'
                            };

                Map<Id, Quote> updateLineNumberQuoteList = new Map<Id, Quote>();
                List<QuoteLineItem> qliList = new QuoteLineItemSelector()
                    .selectQuoteLineItemsForQLITrigger(quoteIds)
                    .executeQuery();
                for (QuoteLineItem qli : qliList) {
                    if(!quoteToQLIMap.containsKey(qli.QuoteId)) {
                        quoteToQLIMap.put(qli.QuoteId, new Map<Id, QuoteLineItem>());
                    }

                    if(!quoteToQLIFilteredMap.containsKey(qli.QuoteId)
                                            && ( featureIds.contains(qli.Product2.Feature__c)
                                            || productFamilyFilterSet.contains(qli.Product2.Family) )
                                            ) {
                        quoteToQLIFilteredMap.put(qli.QuoteId, new Map<Id, QuoteLineItem>());
                    }


                    // update Quantity field on existing QLI for those which included in trigger scope
                    // so if Quantity changed on several QLI in the same time we will use new Quantity values
                    if(quoteToQLIFilteredMap.get(qli.QuoteId).containsKey(qli.Id)){
                        qli.Quantity = quoteToQLIFilteredMap.get(qli.QuoteId).get(qli.Id).Quantity;
                    }

                    quoteToQLIFilteredMap.get(qli.QuoteId).put(qli.Id, qli);
                }
                // Recount total number of DLs
                Map<Id, Quote> updatedQuotesMap = setTotalNumberOfDL(quoteIds, qliList);

                //Will update Quote.Total_Number_of_Digital_Lines__c with actual value, after QLI was inserted
                //Or, this field will keep Pricebook2.Line_Range_Min value (QuoteTriggerHelper.SetDefaultLineItems::handle method)
                //until Quantity will be changed on any QLI
                if (Trigger.isInsert) {
                    QuoteLineItem serviceQLI = QuoteLineItemHelper.findActiveServicePlan(qliList);
                    if (serviceQLI != null && !updatedQuotesMap.containsKey(serviceQLI.QuoteId)) {
                        if (serviceQLI.Quote.Total_Number_of_Digital_Lines__c != QuoteLineItemHelper.getResultingQuantity(serviceQLI)) {
                            Quote qt = quotesMapStatic.get(serviceQLI.QuoteId);
                            qt.Total_Number_of_Digital_Lines__c = QuoteLineItemHelper.getResultingQuantity(serviceQLI);
                            updateLineNumberQuoteList.put(qt.Id, qt);
                        }
                    }
                }

                updateLineNumberQuoteList.putAll(updatedQuotesMap);
                NGBS_LBO_Settings__c LBOSetting = NGBS_LBO_Settings__c.getOrgDefaults();
                System.debug('quantity calculation');
                for (Id quoteId : quoteToQLIFilteredMap.keySet()) {
                    Decimal discountedPhonesQTY = 0;
                    Decimal numOfDigitalLines = 0;

                    Decimal globalPhonesQuantity = 0;
                    Decimal globalLinesQuantity = 0;

                    Decimal limitedExtensionPhonesQuantity = 0;
                    Decimal limitedExtensionLinesQuantity = 0;

                    Decimal commonPhonesQuantity = 0;
                    Decimal commonLinesQuantity = 0;

                    Decimal existingDiscountedPhonesQTY = 0;
                    Decimal newDiscountedPhonesQTY = 0;

                    Decimal globalOfficeLimitedExtensionPhonesQTY = 0;
                    Decimal globalOfficeLimitedExtensionLinesQTY = 0;

                    Quote qt;
                    if(updateLineNumberQuoteList.containsKey(quoteId)){
                        qt = updateLineNumberQuoteList.get(quoteId);
                    } else {
                        Id quoteRtId = quoteToQLIFilteredMap.get(quoteId).values().size() > 0
                            ? quoteToQLIFilteredMap.get(quoteId).values().get(0).Quote.RecordTypeId
                            : null;
                        qt = new Quote(
                            Id = quoteId,
                            RecordTypeId = quoteRtId
                        );
                    }

                    for (QuoteLineItem qli : quoteToQLIFilteredMap.get(quoteId).values()) {

                        // Getting Quote.Upsell_Status__c without additional query;
                        if(qt.Upsell_Status__c == null && qli.Quote.Upsell_Status__c != null) {
                            qt.Upsell_Status__c = qli.Quote.Upsell_Status__c;
                        }
                        if (qt.Entitlement_Rental_Phones_Quantity__c == null
                                && qli.Quote.Entitlement_Rental_Phones_Quantity__c != null) {
                            qt.Entitlement_Rental_Phones_Quantity__c = qli.Quote.Entitlement_Rental_Phones_Quantity__c;
                        }
                        if (qt.Entitlement_Global_Phones_Quantity__c == null
                                && qli.Quote.Entitlement_Global_Phones_Quantity__c != null) {
                            qt.Entitlement_Global_Phones_Quantity__c = qli.Quote.Entitlement_Global_Phones_Quantity__c;
                        }
                        if (qt.Entitlement_Limited_Phones_Quantity__c == null
                                && qli.Quote.Entitlement_Limited_Phones_Quantity__c != null) {
                            qt.Entitlement_Limited_Phones_Quantity__c = qli.Quote.Entitlement_Limited_Phones_Quantity__c;
                        }
                        if (qt.Entitlement_Common_Phones_Quantity__c == null
                                && qli.Quote.Entitlement_Common_Phones_Quantity__c != null) {
                            qt.Entitlement_Common_Phones_Quantity__c = qli.Quote.Entitlement_Common_Phones_Quantity__c;
                        }
                        if (qt.Entitlement_GO_LE_Phones_Quantity__c == null
                            && qli.Quote.Entitlement_GO_LE_Phones_Quantity__c != null) {
                            qt.Entitlement_GO_LE_Phones_Quantity__c = qli.Quote.Entitlement_GO_LE_Phones_Quantity__c;
                        }
                        // In case if isset a newQuantitty field
                        Decimal currentQty = qli.Zero_Quantity__c ? 0 : qli.Quantity;
                        Decimal existingQty = 0;
                        if(qli.NewQuantity__c != null) {
                            currentQty = qli.NewQuantity__c;
                        }
                        if(qli.Entitlement__r.DisplayQuantity__c != null) {
                            existingQty = qli.Entitlement__r.DisplayQuantity__c;
                        }

                        Boolean isDigitalLineProduct = (qli.Product2.Family == Product2Helper.FAMILY_SERVICE &&
                            qli.Product2.Feature__c == Product2Helper.FEATURE_SERVICE_PLAN) ||
                            qli.Product2.Feature__c == 18;

                        if (Product2Helper.DISCOUNTED_PHONES_FAMILIES.contains(qli.Product2.Family)) {
                            discountedPhonesQTY += qli.Zero_Quantity__c ? 0 : currentQty;
                            if (qli.Product2.Charge_Term__c != Product2Helper.CHARGE_TERM_ONE_TIME) {
                                existingDiscountedPhonesQTY += existingQty;
                                newDiscountedPhonesQTY += qli.Zero_Quantity__c ? 0 : qli.Quantity;
                            }
                        } else if (isDigitalLineProduct) {
                            numOfDigitalLines += currentQty;
                        }

                        //Nikita Sergienko 26.07.16
                        //B-268 Global Office phones quantity validation

                        Boolean isGlobalPhonesQuantity = (
                            qli.Product2.Family == 'Global Office Discounted Phones' ||
                            qli.Product2.Family == 'Global Office Rental Phones' ||
                            qli.Product2.Family == 'Global Office Refurbished Phones'
                        );

                        if(qt.Upsell_Status__c != QuoteHelper.STATUS_NEW_CUSTOMER) {
                            isGlobalPhonesQuantity = isGlobalPhonesQuantity &&
                                qli.Product2.Charge_Term__c != Product2Helper.CHARGE_TERM_ONE_TIME;
                        }

                        if(isGlobalPhonesQuantity) {
                            globalPhonesQuantity += (qli.Zero_Quantity__c ? 0 : qli.Quantity) + existingQty;
                        }else if(qli.Product2.Feature__c == Product2Helper.FEATURE_GLOBAL_OFFICE) {
                            globalLinesQuantity += (qli.Zero_Quantity__c ? 0 : qli.Quantity) + existingQty;
                        }

                        // Alexey Gemberg 11.01.17
                        // B-1134 Support Voice Only Limited Extension Phones

                        Boolean isLimitedExtensionPhonesQuantity = (
                            qli.Product2.Family == 'Limited Extension Discounted Phones' ||
                            qli.Product2.Family == 'Limited Extension Rental Phones'
                        );

                        if(qt.Upsell_Status__c != QuoteHelper.STATUS_NEW_CUSTOMER) {
                            isLimitedExtensionPhonesQuantity = isLimitedExtensionPhonesQuantity &&
                                qli.Product2.Charge_Term__c != Product2Helper.CHARGE_TERM_ONE_TIME;
                        }

                        if(isLimitedExtensionPhonesQuantity) {
                            limitedExtensionPhonesQuantity += (qli.Zero_Quantity__c ? 0 : qli.Quantity) + existingQty;
                        } else if(qli.Product2.Feature__c == Product2Helper.FEATURE_LIMITED_EXTENSION &&
                            qli.Product2.Family != Product2Helper.FAMILY_SERVICE) {
                            limitedExtensionLinesQuantity += (qli.Zero_Quantity__c ? 0 : qli.Quantity) + existingQty;
                        }

                        // Azimzhanov Evgeniy 01.02.17
                        Boolean isCommonPhonesQuantity = (
                            qli.Product2.Family == 'Common Discounted Phones' ||
                            qli.Product2.Family == 'Common Refurbished Phones' ||
                            qli.Product2.Family == 'Common Rental Phones'
                        );

                        if(qt.Upsell_Status__c != QuoteHelper.STATUS_NEW_CUSTOMER) {
                            isCommonPhonesQuantity = isCommonPhonesQuantity &&
                                qli.Product2.Charge_Term__c != Product2Helper.CHARGE_TERM_ONE_TIME;
                        }

                        if(isCommonPhonesQuantity) {
                            commonPhonesQuantity += qli.Zero_Quantity__c ? 0 : qli.Quantity;
                        } else if( qli.Product2.Feature__c == 50 ) {
                            commonLinesQuantity += qli.Zero_Quantity__c ? 0 : qli.Quantity;
                        }
                        //Savickiy Alexander 17.11.2017
                        //B-3429 validations for GO LE Phones and GO LE Lines
                        Boolean isGlobaOfficeLimitedExtensionPhonesQuantity = (qli.Product2.Family == 'Global Office - Limited Extension Discounted Phones' ||
                            qli.Product2.Family == 'Global Office - Limited Extension Rental Phones');

                        if(qt.Upsell_Status__c != QuoteHelper.STATUS_NEW_CUSTOMER) {
                            isGlobaOfficeLimitedExtensionPhonesQuantity = isGlobaOfficeLimitedExtensionPhonesQuantity &&
                                qli.Product2.Charge_Term__c != Product2Helper.CHARGE_TERM_ONE_TIME;
                        }

                        if(isGlobaOfficeLimitedExtensionPhonesQuantity) {
                            globalOfficeLimitedExtensionPhonesQTY += (qli.Zero_Quantity__c ? 0 : qli.Quantity) + existingQty;
                        } else if( qli.Product2.Feature__c == Product2Helper.FEATURE_GLOBAL_OFFICE_LIMITED_EXTENSION) {
                            globalOfficeLimitedExtensionLinesQTY += (qli.Zero_Quantity__c ? 0 : qli.Quantity) + existingQty;
                        }
                    }

                    if(qt.Upsell_Status__c == QuoteHelper.STATUS_NEW_CUSTOMER) {
                        if((discountedPhonesQTY > 0 || numOfDigitalLines > 0) && numOfDigitalLines != discountedPhonesQTY && numOfDigitalLines < LBOSetting.LBOAutoOnThreshold__c) {
                            qt.InvalidDiscountedPhonesQuantity__c = true;
                        }else if(numOfDigitalLines == discountedPhonesQTY) {
                            qt.InvalidDiscountedPhonesQuantity__c = false;
                        }

                        if ((globalOfficeLimitedExtensionPhonesQTY > 0 || globalOfficeLimitedExtensionLinesQTY > 0)
                            && globalOfficeLimitedExtensionPhonesQTY != globalOfficeLimitedExtensionLinesQTY) {
                            qt.Invalid_GO_LE_Phones_Quantity__c = true;
                        } else if (globalOfficeLimitedExtensionPhonesQTY == globalOfficeLimitedExtensionLinesQTY) {
                            qt.Invalid_GO_LE_Phones_Quantity__c = false;
                        }
                        updateLineNumberQuoteList.put(qt.Id, qt);
                    } else {
                        System.debug('newdiscountedPhonesQTY: ' + newdiscountedPhonesQTY);
                        System.debug('numOfDigitalLines: ' + numOfDigitalLines);
                        System.debug('Quote on upsell' + JSON.serializePretty(qt));
                        System.debug('Quote on upsell' + qt.Entitlement_Rental_Phones_Quantity__c);
                        if (newdiscountedPhonesQTY +
                                (qt.Entitlement_Rental_Phones_Quantity__c == null
                                        ? 0
                                        : qt.Entitlement_Rental_Phones_Quantity__c)
                                <= numOfDigitalLines) {
                            qt.Errors__c = null;
                            qt.InvalidDiscountedPhonesQuantity__c = false;
                        } else {
                            System.debug('newdiscountedPhonesQTY: ' + newdiscountedPhonesQTY);
                            System.debug('numOfDigitalLines: ' + numOfDigitalLines);
                            System.debug('Quote on upsell' + JSON.serializePretty(qt));
                            System.debug('Quote on upsell' + qt.Entitlement_Rental_Phones_Quantity__c);
                            if (newdiscountedPhonesQTY +
                                (qt.Entitlement_Rental_Phones_Quantity__c == null
                                    ? 0
                                    : qt.Entitlement_Rental_Phones_Quantity__c)
                                <= numOfDigitalLines || numOfDigitalLines >= LBOSetting.LBOAutoOnThreshold__c) {
                                qt.Errors__c = null;
                                qt.InvalidDiscountedPhonesQuantity__c = false;
                            } else {
                                qt.Errors__c = 'InvalidDiscountedPhonesQuantityForUpsell';
                                qt.InvalidDiscountedPhonesQuantity__c = true;
                            }
                            updateLineNumberQuoteList.put(qt.Id, qt);
                        }
                    }

                    System.debug('globalPhonesQuantityyyy: ' + globalPhonesQuantity + '  :globalLinesQuantity:  ' + globalLinesQuantity);
                    if((globalPhonesQuantity > 0 || globalLinesQuantity > 0) && globalLinesQuantity != globalPhonesQuantity) {
                        qt.InvalidGlobalOfficePhonesQuantity__c = true;
                        updateLineNumberQuoteList.put(qt.Id, qt);
                    }else if(globalLinesQuantity == globalPhonesQuantity) {
                        qt.InvalidGlobalOfficePhonesQuantity__c = false;
                        updateLineNumberQuoteList.put(qt.Id, qt);
                    }

                    System.debug('limitedExtensionPhonesQuantity: ' + limitedExtensionPhonesQuantity
                            + '  :limitedExtensionLinesQuantity:  ' + limitedExtensionLinesQuantity);
                    if ((limitedExtensionPhonesQuantity > 0 || limitedExtensionLinesQuantity > 0)
                            && limitedExtensionPhonesQuantity != limitedExtensionLinesQuantity ) {
                        qt.InvalidLimitedExtensionPhonesQuantity__c = true;
                        updateLineNumberQuoteList.put(qt.Id, qt);
                    } else if ( limitedExtensionPhonesQuantity == limitedExtensionLinesQuantity ) {
                        qt.InvalidLimitedExtensionPhonesQuantity__c = false;
                        updateLineNumberQuoteList.put(qt.Id, qt);
                    }

                    System.debug('commonPhonesQuantity: ' + commonPhonesQuantity + '  :commonLinesQuantity:  ' + commonLinesQuantity);
                    if((commonPhonesQuantity > 0 || commonLinesQuantity > 0) && commonPhonesQuantity != commonLinesQuantity){
                        updateLineNumberQuoteList.put(qt.Id, qt);
                    }

                    if((globalOfficeLimitedExtensionPhonesQTY > 0 || globalOfficeLimitedExtensionLinesQTY > 0) && globalOfficeLimitedExtensionPhonesQTY != globalOfficeLimitedExtensionLinesQTY){
                        qt.Invalid_GO_LE_Phones_Quantity__c = true;
                        updateLineNumberQuoteList.put(qt.Id, qt);
                    }else if(globalOfficeLimitedExtensionPhonesQTY == globalOfficeLimitedExtensionLinesQTY){
                        qt.Invalid_GO_LE_Phones_Quantity__c = false;
                        updateLineNumberQuoteList.put(qt.Id, qt);
                    }

                    //B-2445
                    if(qt.Upsell_Status__c != 'New' && qt.Upsell_Status__c != 'Sign Up') {
                        //B-3768
                        if (globalOfficeLimitedExtensionPhonesQTY > 0 || globalOfficeLimitedExtensionLinesQTY > 0) {
                            qt.Invalid_GO_LE_Phones_Quantity__c = globalOfficeLimitedExtensionPhonesQTY > globalOfficeLimitedExtensionLinesQTY;
                            updateLineNumberQuoteList.put(qt.Id, qt);
                        }
                        //B-3768

                        if(globalPhonesQuantity != 0 || globalLinesQuantity != 0) {
                            qt.InvalidGlobalOfficePhonesQuantity__c = globalPhonesQuantity > globalLinesQuantity;
                            updateLineNumberQuoteList.put(qt.Id, qt);
                        }

                        if ( limitedExtensionPhonesQuantity != 0 || limitedExtensionLinesQuantity != 0 ) {
                            qt.InvalidLimitedExtensionPhonesQuantity__c = limitedExtensionPhonesQuantity > limitedExtensionLinesQuantity;
                            updateLineNumberQuoteList.put(qt.Id, qt);
                        }

                        if(commonPhonesQuantity != 0 || commonLinesQuantity != 0) {
                            updateLineNumberQuoteList.put(qt.Id, qt);
                        }
                    }

                    if(qt.Upsell_Status__c == 'Sign Up') {
                        if(globalPhonesQuantity != 0 || globalLinesQuantity != 0) {
                            qt.InvalidGlobalOfficePhonesQuantity__c = globalPhonesQuantity != globalLinesQuantity;
                            updateLineNumberQuoteList.put(qt.Id, qt);
                        }
                        if (limitedExtensionPhonesQuantity != 0 || limitedExtensionLinesQuantity != 0 ) {
                            qt.InvalidLimitedExtensionPhonesQuantity__c = limitedExtensionPhonesQuantity != limitedExtensionLinesQuantity;
                            updateLineNumberQuoteList.put(qt.Id, qt);
                        }
                        if(commonPhonesQuantity != 0 || commonLinesQuantity != 0) {
                            updateLineNumberQuoteList.put(qt.Id, qt);
                        }
                    }
                }


                // B-2188
                Map<Id, List<QuoteLineItem>> quoteIdToQLIListMap = new Map<Id, List<QuoteLineItem>>();
                for(Id quoteId : quoteToQLIMap.keySet()) {
                    Map<Id, QuoteLineItem> qliMap = quoteToQLIMap.get(quoteId);
                    quoteIdToQLIListMap.put(quoteId, qliMap.values());
                }

                List<QuoteLineItem> qlis = Trigger.isDelete ? Trigger.old : Trigger.new;
                CheckNumberOfVanitySteps checker = new CheckNumberOfVanitySteps();

                List<Quote> changedQuotesList = checker.handleInvalidNumberSetups(qlis, quoteIdToQLIListMap);

                if(!updateLineNumberQuoteList.isEmpty() && !changedQuotesList.isEmpty()){
                    for(Quote q : changedQuotesList) {

                        Quote quoteToUpdate = updateLineNumberQuoteList.get(q.Id);

                        if(quoteToUpdate != null) {

                            quoteToUpdate.Invalid_Number_of_Vanity_Setups__c = q.Invalid_Number_of_Vanity_Setups__c;
                            quoteToUpdate.Invalid_Number_of_800_Setups__c = q.Invalid_Number_of_800_Setups__c;
                            quoteToUpdate.Invalid_Number_of_Int_TF_Setups__c = q.Invalid_Number_of_Int_TF_Setups__c;
                            quoteToUpdate.Required_Area_Codes_are_empty__c = q.Required_Area_Codes_are_empty__c;

                        }
                    }
                }

                Map <Id,List <QuoteLineItem>> quoteToQlisMap = new Map <Id,List <QuoteLineItem>>();
                for (QuoteLineItem qli : qliList) {
                    if (!quoteToQlisMap.containsKey(qli.QuoteId)) {
                        quoteToQlisMap.put(qli.QuoteId, new List <QuoteLineItem>());
                    }
                    quoteToQlisMap.get(qli.QuoteId).add(qli);
                }
                // B-2680(Estimated Pro Services SOW calculating)
                Decimal totalPriceProServSOW = 0;
                Id optyId;
                //If quoteLineItems are not deleted -> count totalPriceProServSOW
                if (!qliList.isEmpty()) {
                    for (QuoteLineItem qli : qliList) {
                        Quote qt = quotesMapStatic.get(qli.QuoteId);
                        String chargeTerm = QuoteLineItemHelper.getChargeTerm(qli);
                        optyId = qt.OpportunityId;
                        if ((qt.RecordTypeId == PROSERV_QUOTE_RT_ID || qt.RecordTypeId == CC_PROSERV_QUOTE_RT_ID)
                            && chargeTerm == 'One - Time'){
                                totalPriceProServSOW += qli.TotalPrice;
                        }
                    }
                }

                Feature_Toggle__c featureToggle = Feature_Toggle__c.getInstance();
                //Populate Credit_Amount__c and Free_Service_Taxes__c fields on quote
                for (Id quoteId : quoteToQlisMap.keyset()) {
                    String specialTerms = !quoteToQlisMap.get(quoteId).isEmpty()
                        ? quoteToQlisMap.get(quoteId)[0].Quote.Special_Terms__c
                        : null;
                    Integer numberOfFreeTerms = specialTerms != null
                        ? QuoteHelper.getNumberFromString(specialTerms)
                        : null;

                    Decimal creditAmount;
                    Decimal freeServiceTaxes;
                    if (QuoteHelper.FREE_MONTHS_TERMS.contains(specialTerms)) {
                        Map<String,Decimal> freeServiceValues =
                            QuoteHelper.calculateFreeValuesOnQuote(quoteToQlisMap.get(quoteId), numberOfFreeTerms);

                        creditAmount = freeServiceValues.get('freeDiscount');
                        freeServiceTaxes = freeServiceValues.get('freeServiceTaxes');
                    }

                    //Assign values and populate map with quotes to update
                    if (updateLineNumberQuoteList.containsKey(quoteId)) {
                        if (QuoteHelper.isNewBillingQuote(updateLineNumberQuoteList.get(quoteId))) {
                            if (!featureToggle.CalculateFSCInQW__c) {
                                updateLineNumberQuoteList.get(quoteId).Credit_Amount__c = creditAmount;
                                updateLineNumberQuoteList.get(quoteId).Free_Service_Taxes__c = freeServiceTaxes;
                            }
                        } else {
                            updateLineNumberQuoteList.get(quoteId).Credit_Amount__c = creditAmount;
                            // Skip because CC Quote has no tax QLIs. And FSC taxes for CC Quote are calculating on Quote Wizard
                            if(!QuoteHelper.isCCQuote(updateLineNumberQuoteList.get(quoteId))) {
                                updateLineNumberQuoteList.get(quoteId).Free_Service_Taxes__c = freeServiceTaxes;
                            }
                        }
                    } else {
                        if (QuoteHelper.isNewBillingQuote(quotesMapStatic.get(quoteId))) {
                            if (!featureToggle.CalculateFSCInQW__c) {
                                quotesMapStatic.get(quoteId).Credit_Amount__c = creditAmount;
                                quotesMapStatic.get(quoteId).Free_Service_Taxes__c = freeServiceTaxes;
                                updateLineNumberQuoteList.put(quoteId,quotesMapStatic.get(quoteId));
                            }
                        } else {
                            quotesMapStatic.get(quoteId).Credit_Amount__c = creditAmount;
                            quotesMapStatic.get(quoteId).Free_Service_Taxes__c = freeServiceTaxes;
                            updateLineNumberQuoteList.put(quoteId,quotesMapStatic.get(quoteId));
                        }
                    }
                }

                populateProductsFieldOnQuotes(updateLineNumberQuoteList, qliList);

                populateQuoteNewTotals(updateLineNumberQuoteList, quoteToQlisMap, deletedQuotelineItemMap);

                if(!updateLineNumberQuoteList.isEmpty()){
                    bypassQuantityChangeLogic = true;
                    System.debug('updateLineNumberQuoteList.values() >>> ' + updateLineNumberQuoteList.values());
                }

                if (Trigger.isDelete) {
                    Boolean isSalesRepToBeErased = false;

                    updateProServStatus(Trigger.old);

                    Boolean isEESprodDeleted = isListHasEESproduct(
                        (List<QuoteLineItem>)Trigger.old
                    );

                    if(isEESprodDeleted) {
                        List<QuoteLineItem> deletedQLIs = (List<QuoteLineItem>)Trigger.old;
                        Id quoteId = deletedQLIs[0].QuoteId;

                        if(qliList.size() > 0) {
                            Boolean isHasEeQLIs = isListHasEESproduct(qliList);
                            Boolean isChangeOrder = QuoteHelper.isChangeOrderQuote(qliList[0].Quote, null);

                            if( qliList[0].Quote.isPrimary__c
                            && !isChangeOrder
                            && !isHasEeQLIs
                            && isEESprodDeleted ) {
                                isSalesRepToBeErased = true;
                            }

                        } else {
                            isSalesRepToBeErased = true;
                        }

                        if(isSalesRepToBeErased && !bypassSalesRepErase) {
                            if (updateLineNumberQuoteList.get(quoteId) == null) {
                                Quote qt = quotesMapStatic.get(quoteId);
                                updateLineNumberQuoteList.put(quoteId, qt);
                            }

                            updateLineNumberQuoteList.get(quoteId).ProServSalesRep__c = null;
                        }
                    }
                }
                try {
                    if (!updateLineNumberQuoteList.isEmpty()) {
//                        Triggers.switchOff();
                        update updateLineNumberQuoteList.values();
//                        Triggers.switchOn();
                    }
                } catch(DMLException e) {
                    AquivaHelper.throwAquivaException(e.getDmlMessage(0));
                }
            }
        }

        @TestVisible
        private Map<Id, Quote> setTotalNumberOfDL(Set<Id>quoteIdSet, List<QuoteLineItem> qliList) {
            Map<Id, Quote> updatedQuotesList = new Map<Id, Quote>();
            /* In case when last item was removed from the card and it was Service item */
            if (qliList == null || qliList.isEmpty()) {
                for (Id quoteId : quoteIdSet) {
                    Quote qtToReset = quotesMapStatic.get(quoteId);
                    if (QuoteHelper.isNGBSQuote(qtToReset)) {
                        qtToReset.Total_Number_of_Digital_Lines__c = 0;
                        updatedQuotesList.put(quoteId, qtToReset);
                    }
                }
                return updatedQuotesList;
            }

            Map<Id, List<QuoteLineItem>> quoteIdToQliListMap = QuoteLineItemHelper.buildQuoteIdToQliMap(qliList);
            for (Id quoteId : quoteIdToQliListMap.keySet()) {
                Quote qt = quotesMapStatic.get(quoteId);

                if (qt == null) {
                    continue;
                }

                Boolean isUpdateTotalNumberOfDLRequired =
                    Trigger.isUpdate ||
                    Trigger.isDelete ||
                    (Trigger.isInsert && QuoteHelper.isNGBSQuote(qt));

                if (!isUpdateTotalNumberOfDLRequired) {
                    return updatedQuotesList;
                }

                Decimal totalNumberOfDigitalLines = 0;
                for (QuoteLineItem qli : quoteIdToQliListMap.get(quoteId)) {
                    Product2 product = productsMapStatic.get(qli.Product2Id);
                    if (product == null) {
                        continue;
                    }

                    if (Product2Helper.isServicePlan(product)) {
                        totalNumberOfDigitalLines =
                            QuoteLineItemHelper.getResultingQuantity(qli, entitlementsMapStatic.get(qli.Entitlement__c));
                    }
                }

                if (qt.Total_Number_of_Digital_Lines__c != totalNumberOfDigitalLines) {
                    qt.Total_Number_of_Digital_Lines__c = totalNumberOfDigitalLines;
                    updatedQuotesList.put(qt.Id, qt);
                }
            }

            return updatedQuotesList;
        }

        private void populateProductsFieldOnQuotes(Map<Id, Quote> updateLineNumberQuoteList,
                                                        List<QuoteLineItem> qliList) {
            Map<Id, Set<String>> quoteIdToSubCategoriesSet = new Map<Id, Set<String>>();
            List<String> picklistValues = AquivaHelper.getPicklistValues('Quote', 'Products__c');    // get possible picklist values from Quote's Products__c multi picklist

            for(QuoteLineItem qli : qliList) {
                if(!picklistValues.contains(qli.Product2.Sub_Category__c) && qli.Product2.Sub_Category__c != 'Main') {
                    continue;
                }

                if(!quoteIdToSubCategoriesSet.containsKey(qli.QuoteId)) {
                    quoteIdToSubCategoriesSet.put(qli.QuoteId, new Set<String>());
                }
                quoteIdToSubCategoriesSet.get(qli.QuoteId).add(qli.Product2.Sub_Category__c);
            }

            for(Id quoteId : quoteIdToSubCategoriesSet.keySet()) {
                Quote tempQuote = updateLineNumberQuoteList.get(quoteId);
                String prodsStr = String.join(new List<String>(quoteIdToSubCategoriesSet.get(quoteId)), ';')
                                            .replace('Main', 'RingCentral');
                tempQuote.Products__c = prodsStr;
                updateLineNumberQuoteList.put(quoteId, tempQuote);
            }
        }

        private void populateQuoteNewTotals(Map<Id, Quote> updateLineNumberQuoteList, Map<Id, List<QuoteLineItem>> quoteToQlisMap, Map<Id, QuoteLineItem> deletedQuotelineItemMap) {

            if(quoteToQlisMap.isEmpty() && !deletedQuotelineItemMap.isEmpty()) {
                Set<Id> quotesWithDeletedQlisIdSet = new Set<Id>();
                for(QuoteLineITem deletedQli : deletedQuotelineItemMap.values()) {
                    quotesWithDeletedQlisIdSet.add(deletedQli.QuoteId);
                }
                for(Id quoteId : quotesWithDeletedQlisIdSet) {
                    quoteToQlisMap.put(quoteId, new List<QuoteLineItem>());
                }
            }

            // prepare map for populating new totals on quote(exclude deleted qlis)
            Set<Id> quoteToUpdateTotalsIdSet = new Set<Id>();

            for(Id quoteId : quoteToQlisMap.keySet()) {
                List<QuoteLineItem> qlisForCurrentQuote = quoteToQlisMap.get(quoteId);

                if(qlisForCurrentQuote.isEmpty()) {
                    quoteToUpdateTotalsIdSet.add(quoteId);
                }

                for(QuoteLineItem qli : qlisForCurrentQuote) {

                    if(Trigger.isUpdate && Trigger.newMap.containsKey(qli.Id) && !quoteToUpdateTotalsIdSet.contains(quoteId)) {

                        Boolean isNeedUpdateTotals = checkIsNeedUpdateTotals(qli.Id);

                        if(isNeedUpdateTotals) {
                            quoteToUpdateTotalsIdSet.add(quoteId);
                        }
                    }

                    if(!Trigger.isUpdate && !quoteToUpdateTotalsIdSet.contains(quoteId)) {
                        quoteToUpdateTotalsIdSet.add(quoteId);
                    }
                }
            }

            Map<Id, List<QuoteLineItem>> quoteIdToQliListMapForTotals = new Map<Id, List<QuoteLineItem>>();

            for(Id quoteId : quoteToQlisMap.keySet()) {
                if(!quoteToUpdateTotalsIdSet.contains(quoteId)) {
                    continue;
                }

                List<QuoteLineItem> qlisForCurrentQuote = quoteToQlisMap.get(quoteId);

                for(QuoteLineItem qli : qlisForCurrentQuote) {

                    if(!deletedQuotelineItemMap.containsKey(qli.Id)) {
                        if(!quoteIdToQliListMapForTotals.containsKey(quoteId)) {
                            quoteIdToQliListMapForTotals.put(quoteId, new List<QuoteLineItem>());
                        }
                        quoteIdToQliListMapForTotals.get(quoteId).add(qli);
                    }
                }

                if(qlisForCurrentQuote.isEmpty()) {
                    if(!quoteIdToQliListMapForTotals.containsKey(quoteId)) {
                        quoteIdToQliListMapForTotals.put(quoteId, new List<QuoteLineItem>());
                    }
                }
            }

            List<Quote> quotesWithUpdatedTotals = QuoteTotals.populateTotals(quoteIdToQliListMapForTotals);
            System.debug('quotesWithUpdatedTotals >>>> ' + quotesWithUpdatedTotals);

            for (Quote quote : quotesWithUpdatedTotals) {
                Quote quoteStatic = quotesMapStatic.get(quote.Id);
                if (!DQGoa.isDQGoaEnabled() && QuoteHelper.isNGBSQuote(quoteStatic) && quoteStatic.IsNewGOAEnabled__c) {
                    quote.Approved_Status__c = DQ_SubmitQuoteForApproval1.getQuoteApprovalStatus(quote.Id);
                }
            }

            if (DQGoa.isDQGoaEnabled()) {
                Quote q = !quotesWithUpdatedTotals.isEmpty() ? quotesWithUpdatedTotals.get(0) : null;
                Quote quoteStatic = (q!=null) ? quotesMapStatic.get(q.Id) : null;

                if (quoteStatic != null && quoteStatic.RecordTypeId == QuoteHelper.RT_ID_CC && QuoteHelper.isNewBusiness(quoteStatic)) {

                    List<DQGoa.ApproverData> lstApprovers = DQGoa.getApproversForQuote(q.Id);

                    if (!lstApprovers.isEmpty() && quoteStatic.Approved_Status__c != QuoteHelper.APPROVAL_STATUS_REQUIRED) {
                        q.Approved_Status__c = QuoteHelper.APPROVAL_STATUS_REQUIRED;
                        isRequirePrimaryQuoteApproval = true;
                    } else if (lstApprovers.isEmpty() && quoteStatic.Approved_Status__c != QuoteHelper.APPROVAL_STATUS_APPROVED && quoteStatic.Approved_Status__c != QuoteHelper.APPROVAL_STATUS_NOT_REQUIRED) {
                        q.Approved_Status__c = QuoteHelper.APPROVAL_STATUS_NOT_REQUIRED;
                        isApprovedPrimaryQuoteApproval = true;
                    }

                }
            }

            if(!updateLineNumberQuoteList.isEmpty() && !quotesWithUpdatedTotals.isEmpty()) {
                for(Quote qt : quotesWithUpdatedTotals) {
                    Map<String, Decimal> quotesTotalMap = new Map<String, Decimal> {
                        'Total_One_Time__c' => qt.Total_One_Time__c,
                        'Total_MRR_New__c' => qt.Total_MRR_New__c,
                        'Total_ARR__c' => qt.Total_ARR__c,
                        'Total_Initial_Payment__c' => qt.Total_Initial_Payment__c,
                        'Total_First_Year_Cost__c' => qt.Total_First_Year_Cost__c,
                        'Total_One_Time_Discount__c' => qt.Total_One_Time_Discount__c,
                        'Total_MRR_Discount__c' => qt.Total_MRR_Discount__c,
                        'Total_ARR_Discount__c' => qt.Total_ARR_Discount__c,
                        'Total_Initial_Payment_Discount__c' => qt.Total_Initial_Payment_Discount__c,
                        'Total_First_Year_Discount__c' => qt.Total_First_Year_Discount__c,
                        'Total_One_Time_with_Taxes__c' => qt.Total_One_Time_with_Taxes__c,
                        'Total_MRR_with_Taxes__c' => qt.Total_MRR_with_Taxes__c,
                        'Total_ARR_with_Taxes__c' => qt.Total_ARR_with_Taxes__c,
                        'Total_Initial_Payment_with_Taxes__c' => qt.Total_Initial_Payment_with_Taxes__c,
                        'Total_First_Year_Cost_with_Taxes__c' => qt.Total_First_Year_Cost_with_Taxes__c,
                        'TotalQuoteSummary__c' => qt.TotalQuoteSummary__c,
                        'Contact_Center_Total_One_Time__c' => qt.Contact_Center_Total_One_Time__c,
                        'Contact_Center_Total_MRR__c' => qt.Contact_Center_Total_MRR__c,
                        'Contact_Center_Total_ARR__c' => qt.Contact_Center_Total_ARR__c,
                        'Contact_Center_Total_Initial_Payment__c' => qt.Contact_Center_Total_Initial_Payment__c,
                        'Contact_Center_Total_First_Year_Cost__c' => qt.Contact_Center_Total_First_Year_Cost__c,
                        'Contact_Center_Total_One_Time_Discount__c' => qt.Contact_Center_Total_One_Time_Discount__c,
                        'Contact_Center_Total_MRR_Discount__c' => qt.Contact_Center_Total_MRR_Discount__c,
                        'Contact_Center_Total_ARR_Discount__c' => qt.Contact_Center_Total_ARR_Discount__c,
                        'ContactCenterTotalInitialPaymentDiscount__c' => qt.ContactCenterTotalInitialPaymentDiscount__c,
                        'Contact_Center_Total_First_Year_Discount__c' => qt.Contact_Center_Total_First_Year_Discount__c,
                        'Estimated_Hardware__c' => qt.Estimated_Hardware__c,
                        'Delta_MRR__c' => qt.Delta_MRR__c,
                        'Delta_ARR__c' => qt.Delta_ARR__c,
                        'Delta_CC_MRR__c' => qt.Delta_CC_MRR__c,
                        'Delta_CC_ARR__c' => qt.Delta_CC_ARR__c,
                        'CLM_Total_Initial_Payment__c' => qt.CLM_Total_Initial_Payment__c,
                        'TotalInitialPaymentWithoutProServ__c' => qt.TotalInitialPaymentWithoutProServ__c,
                        'ProServListPrice__c' => qt.ProServListPrice__c,
                        'ProServDiscount__c' => qt.ProServDiscount__c
                    };
                    if(updateLineNumberQuoteList.containsKey(qt.Id)) {
                        Quote quoteToUpdate = updateLineNumberQuoteList.get(qt.Id);

                        for (String field : quotesTotalMap.keySet()) {
                            if (quoteToUpdate.get(field) != quotesTotalMap.get(field)) {
                                quoteToUpdate.put(field, quotesTotalMap.get(field));
                            }
                        }

                        if (qt.Approved_Status__c != null) {
                            quoteToUpdate.Approved_Status__c = qt.Approved_Status__c;
                        }

                        if (qt.Delta_MRR__c < 0) {
                            quoteToUpdate.FSC_Full_MRS_Calculation__c = true;
                        }
                    }else{
                        updateLineNumberQuoteList.put(qt.Id, qt);
                    }
                }
            }
        }

        private Boolean checkIsNeedUpdateTotals(Id quoteLineItemId) {

            if(quoteLineItemId == null || !Trigger.newMap.containsKey(quoteLineItemId)) {
                return false;
            }

            Boolean isDiscountChanged = Trigger.newMap.get(quoteLineItemId).get('DiscountValueNew__c') !=
                Trigger.oldMap.get(quoteLineItemId).get('DiscountValueNew__c');

            Boolean isDiscountTypeChanged = Trigger.newMap.get(quoteLineItemId).get('Discount_type__c') !=
                Trigger.oldMap.get(quoteLineItemId).get('Discount_type__c');

            Boolean isNewQuantityChanged = Trigger.newMap.get(quoteLineItemId).get('NewQuantity__c') !=
                Trigger.oldMap.get(quoteLineItemId).get('NewQuantity__c');

            Boolean isZeroQuantityChanged = Trigger.newMap.get(quoteLineItemId).get('Zero_Quantity__c') !=
                Trigger.oldMap.get(quoteLineItemId).get('Zero_Quantity__c');

            Boolean isEffectivePriceChanged = Trigger.newMap.get(quoteLineItemId).get('EffectivePriceNew__c') !=
                Trigger.oldMap.get(quoteLineItemId).get('EffectivePriceNew__c');

            Boolean isFixedTaxesChanged = Trigger.newMap.get(quoteLineItemId).get('Fixed_Taxes_Amount__c') !=
                Trigger.oldMap.get(quoteLineItemId).get('Fixed_Taxes_Amount__c');

            Boolean isVariableTaxesChanged = Trigger.newMap.get(quoteLineItemId).get('Variable_Taxes_Amount__c') !=
                Trigger.oldMap.get(quoteLineItemId).get('Variable_Taxes_Amount__c');

            Boolean isNeedUpdateTotals = isDiscountChanged || isDiscountTypeChanged ||
                isNewQuantityChanged || isZeroQuantityChanged || isEffectivePriceChanged ||
                isFixedTaxesChanged || isVariableTaxesChanged;

            return isNeedUpdateTotals;
        }

        @TestVisible
        private boolean isChangedQuoteLineItemQuantity(QuoteLineItem qli, Decimal newQTY, PriceBookEntry pbe){
            boolean isChanged = false;
            Decimal minLines = 0;
            Decimal maxLines = 0;

            if (pbe.Min_Quantity__c != null) {
                minLines = pbe.Min_Quantity__c * newQTY;
            } else {
                minLines = 0;
            }
            if (pbe.Max_Quantity__c != null) {
                maxLines = pbe.Max_Quantity__c * newQTY;
            } else {
                maxLines = 999999999;
            }
            if (qli.Quantity < minLines){
                qli.Quantity = minLines;
                isChanged = true;
            }
            else if (qli.Quantity > maxLines){
                qli.Quantity = maxLines;
                isChanged = true;
            }

            return isChanged;
        }


        /**
         *  Update Status on ProServ (CC ProServ) Quote to InProgress if ProServ (CC ProServ) product was
         *  removed from Primary Quote
         */
        private void updateProServStatus(List<QuoteLineItem> qlis) {
            Set<Id> opptyIds = new Set<Id>();
            List<Quote> quotesToUpdate = new List<Quote>();
            Boolean isPrimarySalesQuote = true;

            Boolean isUpdateStatusOnProServQuote = false;
            Boolean isUpdateStatusOnCCProServQuote = false;

            List<QuoteLineItem> qliProServs = [
                    SELECT Id, QuoteId, Quote.IsPrimary__c, Quote.OpportunityId, Product2.Sub_Category__c,
                           Quote.RecordTypeId, QuoteRecordType__c
                    FROM QuoteLineItem
                    WHERE Id IN :qlis
                    ALL ROWS
            ];

            if (!qliProServs.isEmpty()) {

                // Check if products were removed from primary Quote or ProServ Quote
                for (QuoteLineItem qli : qliProServs) {
                    Boolean updateStatus = false;
                    opptyIds.add(qli.Quote.OpportunityId);

                    if (qli.Product2.Sub_Category__c == PROSERV_PRODUCT_SUBCATEGORY
                            && ( qli.Quote.RecordTypeId == PROSERV_QUOTE_RT_ID
                                || qli.Quote.IsPrimary__c )) {
                        isUpdateStatusOnProServQuote = true;
                    }

                    if (qli.Product2.Sub_Category__c == CC_PROSERV_PRODUCT_SUBCATEGORY
                            && ( qli.Quote.RecordTypeId == CC_PROSERV_QUOTE_RT_ID
                                || qli.Quote.IsPrimary__c )) {
                        isUpdateStatusOnCCProServQuote = true;
                    }

                }

                // Get ProServ Quotes
                List<Quote> quoteProServs = [
                        SELECT Id, Name, ProServ_Status__c, RecordTypeId, Products__c
                        FROM Quote
                        WHERE OpportunityId IN :opptyIds
                        AND RecordTypeId IN ( :PROSERV_QUOTE_RT_ID, :CC_PROSERV_QUOTE_RT_ID )
                ];

                // Update Status
                for (Quote q : quoteProServs) {
                    if (q.RecordTypeId == PROSERV_QUOTE_RT_ID && isUpdateStatusOnProServQuote) {
                        q.ProServ_Status__c = IN_PROGRESS_PROSERV_STATUS;
                        quotesToUpdate.add(q);
                    }

                    if (q.RecordTypeId == CC_PROSERV_QUOTE_RT_ID && isUpdateStatusOnCCProServQuote) {
                        q.ProServ_Status__c = IN_PROGRESS_PROSERV_STATUS;
                        quotesToUpdate.add(q);
                    }
                }

                if (quotesToUpdate.size() > 0){
                     update quotesToUpdate;
                }
            }

            System.debug(' Limits.getQueries >>> ' + Limits.getQueries());
            System.debug(' Limits.getLimitQueries >>> ' + Limits.getLimitQueries());
        }

        private Boolean isListHasEESproduct(List<QuoteLineItem> qliListToCheck) {
            Boolean isHasEEproduct = false;
            for(QuoteLineItem qli : qliListToCheck) {
                if(
                    qli.Product2Id != null
                    && productsMapStatic.containsKey(qli.Product2Id)
                    && (productsMapStatic.get(qli.Product2Id).Feature__c
                        == Product2Helper.FEATURE_EXTENDED_ENTERPRISE_SUPPORT
                    || productsMapStatic.get(qli.Product2Id).Feature__c
                        == Product2Helper.FEATURE_CC_EXTENDED_ENTERPRISE_SUPPORT)
                  ) {
                    isHasEEproduct = true;
                    break;
                }
            }
            return isHasEEproduct;
        }
    }


    public static boolean disableDiscountValidationOnUpdate = false;
    public class ApplyQuoteLineItemRestrictions extends Triggers.TriggerHandlerBase {
        override public void handle() {
            Map<Id, Quote> quotesMap = new Map<Id, Quote>();
            Map<Id, List<QuoteLineItem>> existingQLIMap = new Map<Id, List<QuoteLineItem>>();
            Map<Id, Product2> productsMap = new Map<Id, Product2>();
            List<Quote> quotesToUpdate = new List<Quote>();
            Map<id, Entitlement__c> entitlementsMap = new Map <id, Entitlement__c>();

            for(QuoteLineItem qli:(List<QuoteLineItem>)trigger.new){
                if(qli.Product2Id != null){
                    quotesMap.put(qli.QuoteId, null);
                    productsMap.put(qli.Product2Id, null);
                    entitlementsMap.put(qli.Entitlement__c, null);
                }
            }

            Boolean doSOQL = false;
            List<Product2> products = new List<Product2>();
            for (Id pId : productsMap.keySet()){
                if (productsMapStatic.containsKey(pId)){
                    products.add(productsMapStatic.get(pId));
                }else{
                    doSOQL = true;
                }
            }
            if (doSOQL){
                products = [SELECT Id, Name, Feature__c, Sub_Feature__c, Sub_Category__c, Charge_Term__c, Family, ExtID__c FROM Product2 WHERE Id IN :productsMap.keySet()];
            }
            for(Product2 p:products){
                productsMap.put(p.Id, p);
                productsMapStatic.put(p.Id, p);
            }

            doSOQL = false;
            List<Entitlement__c> entitlements = new List<Entitlement__c>();
            for (Id entId : entitlementsMap.keySet()) {
                if (entitlementsMapStatic.containsKey(entId)) {
                    entitlements.add(entitlementsMapStatic.get(entId));
                }else {
                    doSOQL = true;
                }
            }

            if (doSOQL){
                entitlements = [SELECT Id, Name,
                        Discount_Type__c, DisplayQuantity__c,
                        EffectivePrice__c, Product__c,
                        Discount__c, Price__c,
                        Product__r.Charge_Term__c,
                        PackageDuration__c
                    FROM Entitlement__c
                    WHERE Id IN: entitlementsMap.keySet()];
            }
            for (Entitlement__c ent: entitlements) {
                entitlementsMap.put(ent.Id,ent);
                entitlementsMapStatic.put(ent.Id,ent);
            }

            /* Create a restriction Map for QuoteLineItem Restriction Setting */
            Map <String, QuoteLineItemRestrictionSettings__c> restrictionsMap = QuoteWizardPageController.getRestrictionsMap();

            Boolean isRestrictionFound = false;
            for(QuoteLineItem qli:(List<QuoteLineItem>)trigger.new) {
                if(qli.Product2Id != null && productsMap.get(qli.Product2Id) != null) {
                    Product2 p = productsMap.get(qli.Product2Id);
                    String f = String.valueOf(p.Feature__c);
                    String sf = String.valueOf(p.Sub_Feature__c);

                    /* Check by Product Type */
                    Boolean r_ByProductType = restrictionsMap.containsKey(qli.Product_Type__c);
                    Boolean isChangedAnyDiscountField = isChangedDiscountField(qli, QuoteLineItem.Discount) ||
                                                        isChangedDiscountField(qli, QuoteLineItem.Discount_number__c) ||
                                                        isChangedField(qli, QuoteLineItem.Discount_type__c);
                    if(r_ByProductType) {
                      Boolean showError;
                      if (trigger.isInsert && this.isNotZero(qli.Discount_Number__c)) {
                        showError = true;
                      }
                      if (!trigger.isInsert && isChangedAnyDiscountField) {
                        showError = true;
                      }

                      if(showError != null) {
                        qli.addError('Discount is not applicable for "' + p.Name + '".');
                      }
                    }
                    /* End Check by Product Type */

                    String key = f+'k';
                    if (String.isNotBlank(sf) && restrictionsMap.get(key+sf) != null) {
                        key+=sf;
                    }

                    QuoteLineItemRestrictionSettings__c restriction = restrictionsMap.get(key);

                    //Get available discount types
                    if (restriction != null) {
                        isRestrictionFound = true;
                    }
                }
            }

            if (!isRestrictionFound) {
                return;
            }

            List<QuoteLineItem> qlis = new List<QuoteLineItem>();
            if (!quoteIdToProdIdToQLIMap.keySet().containsAll(quotesMap.keySet()) || Trigger.isInsert) {
                qlis = new QuoteLineItemSelector()
                    .selectQuoteLineItemsForQLITrigger(quotesMap.keySet())
                    .executeQuery();
            } else {
                for (Id quoteId : quoteIdToProdIdToQLIMap.keySet()) {
                    for (QuoteLineItem qli : quoteIdToProdIdToQLIMap.get(quoteId).values()) {
                        qlis.add(qli);
                    }
                }
            }

            for (QuoteLineItem qli : qlis){
                if(!existingQLIMap.containsKey(qli.QuoteId)) {
                    existingQLIMap.put(qli.QuoteId, new List<QuoteLineItem>());
                }
                existingQLIMap.get(qli.QuoteId).add(qli);
            }


            Map<Id, QuoteLineItem> qliToUpdateDiscounts = new Map<Id, QuoteLineItem>();

            for(QuoteLineItem qli:(List<QuoteLineItem>)trigger.new){
                if(qli.Product2Id != null && productsMap.get(qli.Product2Id) != null) {

                    Product2 p = productsMap.get(qli.Product2Id);
                    Entitlement__c entitlement = entitlementsMap.get(qli.Entitlement__c);
                    String f = String.valueOf(p.Feature__c);
                    String sf = String.valueOf(p.Sub_Feature__c);

                    // new refacored logic
                    Boolean checkSubFeature = false;
                    String key = f+'k';
                    if (String.isNotBlank(sf) && restrictionsMap.get(key+sf) != null) {
                        key+=sf;
                        checkSubFeature = true;
                    }

                    QuoteLineItemRestrictionSettings__c restriction = restrictionsMap.get(key);

                    //Get available discount types
                    Set <String> discountTypeSet = new Set <String>();
                    if (restriction != null) {

                        discountTypeSet = stringToSet(restriction.DiscountTypesAvailable__c);

                        if (trigger.isInsert) {
                            if (restriction.NotAllowSameLineItemInQuote__c || restriction.PreventDifferentDiscount__c) {
                                if (existingQLIMap.containsKey(qli.QuoteId) ) {
                                    for (QuoteLineItem existingQLI : existingQLIMap.get(qli.QuoteId)) {

                                        Decimal exFeature    = existingQLI.Product2.Feature__c;
                                        Decimal exSubFeature = existingQLI.Product2.Sub_Feature__c;
                                        Decimal pFeature     = p.Feature__c;
                                        Decimal pSubFeature  = p.Sub_Feature__c;
                                        String  eChargeTerm  = existingQLI.Product2.Charge_Term__c;
                                        String  pChargeTerm  = p.Charge_Term__c;

                                        Boolean byFeature    = exFeature == pFeature;
                                        Boolean bySubFeature = (!checkSubFeature || exSubFeature == pSubFeature);

                                        //Restrict to add products in the cart with feature/subfeature which are already present in the cart
                                        if (restriction.NotAllowSameLineItemInQuote__c && byFeature && bySubFeature
                                            && existingQLI.NewQuantity__c != 0) {
                                            qli.addError('Only one product of such product type can be added to the Cart.');
                                            break;
                                        }

                                        //Add the similar disount for products with same feature
                                        if (restriction.PreventDifferentDiscount__c && byFeature && bySubFeature && eChargeTerm == pChargeTerm) {
                                            qli.Discount_number__c = existingQLI.Discount_number__c;
                                            qli.Discount_type__c = existingQLI.Discount_type__c;
                                        }

                                        // When create qlis from entitlements unit price can be less than discount
                                        // number after change to existing qli discount with same feature
                                        if(qli.Discount_type__c == QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY && qli.UnitPrice < qli.Discount_number__c) {
                                            qli.addError('Discount can not be more than UnitPrice');
                                        }
                                    }
                                } else {
                                    existingQLIMap.put(qli.QuoteId, new List<QuoteLineItem>());
                                }

                                QuoteLineItem clonedQLI = qli.clone(false, true);
                                clonedQLI.Product2 = p;
                                existingQLIMap.get(qli.QuoteId).add(clonedQLI);
                            }

                            //When quoteLineItems are inserted and there are no entitlements and only one discount allowed by QuoteLineItemRestrictionSetting__c
                            if (entitlement == null && discountTypeSet.Size() == 1) {
                                qli.Discount_type__c = restriction.DiscountTypesAvailable__c;
                            }

                            /* When There are no records found in QuoteLineItemRestrictionSetting__c */
                            if (discountTypeSet.isEmpty() && qli.Discount_Number__c != null && qli.Discount_Number__c != 0) {
                                qli.addError('Discount is not applicable for ' + p.Name + '.');
                            }
                        }
                        else {

                            if (!disableDiscountValidationOnUpdate && existingQLIMap.containsKey(qli.QuoteId)) {
                                for(QuoteLineItem existingQLI : existingQLIMap.get(qli.QuoteId)) {

                                    Boolean isNotEqualDiscountNumber = existingQLI.Discount_number__c != qli.Discount_number__c;
                                    Boolean isNotEqualDiscountType = existingQLI.Discount_type__c != qli.Discount_type__c;
                                    Boolean isEqualChargeTerm = existingQLI.Product2.Charge_Term__c == p.Charge_Term__c;

                                    Decimal exFeature    = existingQLI.Product2.Feature__c;
                                    Decimal pFeature     = p.Feature__c;
                                    Boolean byFeature    = exFeature == pFeature;

                                    Decimal exSubFeature = existingQLI.Product2.Sub_Feature__c;
                                    Decimal pSubFeature  = p.Sub_Feature__c;
                                    Boolean bySubFeature = (!checkSubFeature || exSubFeature == pSubFeature);

                                    if (existingQLI.Id != qli.Id && restriction.PreventDifferentDiscount__c
                                        && byFeature && bySubFeature
                                        && isEqualChargeTerm
                                        && (isNotEqualDiscountNumber || isNotEqualDiscountType)) {

                                            existingQLI.Discount_number__c = qli.Discount_number__c;
                                            existingQLI.Discount_type__c = qli.Discount_type__c;

                                            if(!trigger.newMap.containsKey(existingQLI.Id)) {
                                                qliToUpdateDiscounts.put(existingQLI.Id, existingQLI);
                                            } else {
                                                trigger.newMap.get(existingQLI.Id).put('Discount_number__c', qli.Discount_number__c);
                                                trigger.newMap.get(existingQLI.Id).put('Discount_type__c', qli.Discount_type__c);
                                            }

                                    }
                                }
                            }

                            QuoteLineItem oldQli = (QuoteLineItem)trigger.oldMap.get(qli.Id);
                            //Should perform validation if Discount or Discount_number__c or Discount_type__c is changed
                            Boolean validateDiscountType = this.isValidateDiscountType(qli);

                            if (validateDiscountType && !disableDiscountValidationOnUpdate) {

                                Boolean hasDiscountType = discountTypeSet.contains(qli.Discount_type__c);
                                Boolean hasOldDiscountType = discountTypeSet.contains(String.valueOf(oldValue(qli, QuoteLineItem.Discount_type__c)));

                                /* If User try to add a discount for a product which is not available in QuoteLineItemRestrictionSettings__c */
                                if (!hasDiscountType &&
                                    (entitlement == null || qli.Discount_type__c != entitlement.Discount_Type__c || hasOldDiscountType)) {
                                        qli.addError('Only ' + restriction.DiscountTypesAvailable__c + ' discount types are allowed for ' + p.Name + '.');
                                }

                                /* If there are no any discount types in QuoteLineItemRestrictionSettings__c for QLI */
                                if (discountTypeSet.isEmpty()) {
                                    qli.addError('Discount is not applicable for ' + p.Name + '.');
                                }
                            }
                        }
                    }
                }
            }


            if(qliToUpdateDiscounts.size() > 0){
                disableDiscountValidationOnUpdate = true;
                update qliToUpdateDiscounts.values();
            }
        }

        public Boolean isChangedDiscountField(SObject record, SObjectField field) {
          Boolean result = false;

            if (Trigger.isInsert || Trigger.isUndelete) {
              result = record.get(field) != null;
            } else if (Trigger.isDelete) {
              result = Trigger.oldMap.get(record.Id).get(field) != null;
            } else if (Trigger.isUpdate) {
              if( Trigger.oldMap.get(record.Id).get(field) != null && record.get(field) != 0) {
                result = record.get(field) != Trigger.oldMap.get(record.Id).get(field);
              }
            }

          return result;
        }

        public Set <String> stringToSet(String discountType){
            Set <String> setOfDiscountTypes = new Set <String>();
            if (String.isNotBlank(discountType) || discountType != null) {
                for (String s : discountType.split(',')) {
                    setOfDiscountTypes.add(s.trim());
                }
            }
            return setOfDiscountTypes;
        }

        public Boolean isValidateDiscountType(QuoteLineItem qli) {
            String oldDiscountNumber = String.valueOf(oldValue(qli, QuoteLineItem.Discount_number__c));
            String oldDiscount = String.valueOf(oldValue(qli, QuoteLineItem.Discount));

            Boolean isChangedAnyField =   isChangedField(qli, QuoteLineItem.Discount) ||
                                        isChangedField(qli, QuoteLineItem.Discount_number__c) ||
                                        isChangedField(qli, QuoteLineItem.Discount_type__c);

            Boolean isZeroDiscountNumber = (oldDiscountNumber == null && qli.Discount_number__c == 0);
            Boolean isZeroDiscount = (oldDiscount == null && qli.Discount == 0);

            return isChangedAnyField && !(isZeroDiscountNumber || isZeroDiscount);
        }

        public Boolean isNotZero(Decimal value) {
          return value != null && value != 0;
        }
    }

    public class ValidateIvinexQuoteLineItem extends Triggers.TriggerHandlerBase {
        override public void handle() {
            if (Trigger.isDelete && Trigger.isBefore) {
                Set<Id> quoteIds = new Set<Id>();
                for (QuoteLineItem qli: (List<QuoteLineItem>)Trigger.old) {
                    quoteIds.add(qli.QuoteId);
                }
                List<QuoteLineItem> qlis = new QuoteLineItemSelector()
                    .selectQuoteLineItemsByQuoteIds(quoteIds)
                    .executeQuery();
                Map<Id,QuoteLineItem> allQLIsMap = new Map<Id,QuoteLineItem>(qlis);
                for (QuoteLineItem existingQli: allQLIsMap.values()) {
                    for (Id qliId: Trigger.oldMap.keySet()) {
                        if ((existingQli.Product2.CatID__c == IVINEX_UNIFIED_USER_EXPERIENCE_PER_CONCURRENT_USER ||
                            existingQli.Product2.CatID__c == IVINEX_UNIFIED_USER_EXPERIENCE_PER_CONFIGURED_USER)
                            && (allQLIsMap.get(qliId).Product2.CatID__c == IVINEX_UNIFIED_USER_EXPERIENCE_ADDITIONAL_STORAGE ||
                            allQLIsMap.get(qliId).Product2.CatID__c == IVINEX_UNIFIED_USER_EXPERIENCE_BU_CHARGE)
                            && allQLIsMap.get(qliId).QuoteId == existingQli.QuoteId) {
                                // Throw exception
                                AquivaHelper.throwAuraException('You can\'t delete this item when \'Ivinex Unified User Experience\' product is in the cart');
                        }
                    }
                }
            }
        }
    }

    public class ValidateQuoteLineItem extends Triggers.TriggerHandlerBase {
        override public void handle() {
            Set<Id> quoteIds = new Set<Id>();
            Map<QuoteLineItem, String> Errors = new Map<QuoteLineItem, String>();
            Map<Id, Decimal> QuoteDigitalLines = new Map<Id, Decimal>();
            Map<Id, QuoteLineItem> pbeIdQuoteLineItem = new map<Id, QuoteLineItem>();
            Map<Id, Quote> quotesMap = new Map<Id, Quote>();
            OpportunityTriggerHelperRefactored.skipForecastValidations = true;

            for(QuoteLineItem qli: (List<QuoteLineItem>)trigger.new) {
                if((trigger.isUpdate && (( ((QuoteLineItem)Trigger.oldMap.get(qli.id)).Quantity != ((QuoteLineItem)Trigger.newMap.get(qli.id)).Quantity) ||
                        (((QuoteLineItem)Trigger.oldMap.get(qli.id)).Discount != ((QuoteLineItem)Trigger.newMap.get(qli.id)).Discount) ||
                        (((QuoteLineItem)Trigger.oldMap.get(qli.id)).Discount_type__c != ((QuoteLineItem)Trigger.newMap.get(qli.id)).Discount_type__c) ||
                        (((QuoteLineItem)Trigger.oldMap.get(qli.id)).Discount_number__c != ((QuoteLineItem)Trigger.newMap.get(qli.id)).Discount_number__c))) ||
                        trigger.isInsert){
                    pbeIdQuoteLineItem.put(qli.PriceBookEntryId, qli);
                    quoteIds.add(qli.QuoteId);
                }
            }

            if(trigger.isInsert) {

                for(QuoteLineItem qli : (List<QuoteLineItem>)trigger.new) {

                    Boolean isUpgradeQuote = quotesMapStatic.containsKey(qli.QuoteId) &&
                        quotesMapStatic.get(qli.QuoteId).get('Upsell_Status__c') == QuoteHelper.STATUS_UPGRADE;

                    Boolean isBillingQuote = (quotesMapStatic.get(qli.QuoteId)).RecordTypeId == QuoteHelper.RT_ID_BILLING;

                    if(isUpgradeQuote || isBillingQuote) {
                        continue;
                    }

                    if(qli.PriceFromEntitlement__c != null) {
                        qli.UnitPrice = qli.PriceFromEntitlement__c;
                    }
                    if(qli.DiscountFromEntitlement__c != null) {
                        qli.Discount_number__c = qli.DiscountFromEntitlement__c;
                    }
                    if(qli.DiscountTypeFromEntitlement__c != null) {
                        qli.Discount_type__c = qli.DiscountTypeFromEntitlement__c;
                    }
                }
            }

            Boolean doSOQL = false;
            List<Quote> quotesList = new List<Quote>();
            for (Id qId : quoteIds){
                quotesList.add(quotesMapStatic.get(qId));
            }

            for(Quote qt: quotesList){
                QuoteDigitalLines.put(qt.id, qt.Total_Number_of_Digital_Lines__c);
                quotesMap.put(qt.Id, qt);
            }

            doSOQL = false;
            List<PriceBookEntry> pBookEntries = new List<PriceBookEntry>();
            for (Id pbeId : pbeIdQuoteLineItem.keySet()){
                if (!priceBookEntryMapStatic.containsKey(pbeId)){
                    doSOQL = true;
                } else {
                    pBookEntries.add(priceBookEntryMapStatic.get(pbeId));
                }
            }
            if (doSOQL){
                pBookEntries = [SELECT Id, Per_Line__c, CurrencyIsoCode, Min_Quantity__c, Max_Quantity__c,
                        Max_DIscount__c, Pricebook2Id, Pricebook2.Line_Range_Min__c,
                        Pricebook2.Line_Range_Max__c, Pricebook2.Name, Product2.Name,
                        Product2.Family, Product2Id, UnitPrice, Product2.Description,
                        Product2.Sub_Category__c, Product2.Product_Type__c, Product2.Feature__c,
                        Product2.Dependent_on_Feature__c, Product2.Charge_Term__c, Pricebook2.Tier_ID__c,
                        Product2.IsActive
                FROM PriceBookEntry
                WHERE Id IN: pbeIdQuoteLineItem.keySet()];
            }

            Boolean quoteHaveMinutesBundle = false;

            //B-3310 Quote line items restriction settings
            Map<String, QuoteLineItemRestrictionSettings__c> qliSettings = new Map<String, QuoteLineItemRestrictionSettings__c>();
            for (QuoteLineItemRestrictionSettings__c st : QuoteLineItemRestrictionSettings__c.getAll().values()) {
                if (String.isNotBlank(st.FeatureId__c)) {
                    qliSettings.put(st.FeatureId__c, st);
                }
            }

            List<QuoteLineItem> changedQuantityOnUpsellProservQliList = new List<QuoteLineItem>();

            addMissingMapValues(pBookEntries, quoteIdToProdIdToQLIMap, pbeIdQuoteLineItem, quotesMap);

            for (PriceBookEntry pBookEntry : pBookEntries) {
                priceBookEntryMapStatic.put(pBookEntry.Id, pBookEntry);
                Decimal tempPerLineMultiplier = (pBookEntry.Per_Line__c
                        ? (QuoteDigitalLines.get(pbeIdQuoteLineItem.get(pBookEntry.id).QuoteId)!=null
                                ? QuoteDigitalLines.get(pbeIdQuoteLineItem.get(pBookEntry.id).QuoteId)
                                : (pBookEntry.Pricebook2.Line_Range_Min__c!=null
                                        ? pBookEntry.Pricebook2.Line_Range_Min__c
                                        : 1))
                        : 1);

                QuoteLineItem qli = pbeIdQuoteLineItem.get(pBookEntry.Id);
                Quote qt = quotesMap.get(qli.QuoteId);
                if(!QuoteHelper.isNewBillingQuote(qt) && pBookEntry.Product2 != null
                    && (pBookEntry.Product2.Family == Product2Helper.FAMILY_TIER || pBookEntry.Product2.Family == Product2Helper.FAMILY_SERVICE)) {

                    if(qt.Upsell_Status__c == 'Upsell') {
                        Decimal totalQTY = (qli.Zero_Quantity__c ? 0 : qli.Quantity) + (qt.Account.Number_of_DL_s__c != null ? qt.Account.Number_of_DL_s__c : 0);
                        Decimal currentDL = qt.Account.Number_of_DL_s__c;
                        Decimal minTierDl = pBookEntry.Pricebook2.Line_Range_Min__c;
                        Decimal line_range_min = (currentDL > minTierDl) ? minTierDl : currentDL;

                        if((pBookEntry.Pricebook2.Line_Range_Min__c != null ? line_range_min : 0) > totalQTY && qt.Opportunity.RecordTypeId != OpportunityHelper.RT_ID_CANCEL_OPPORTUNITY) {
                            String errorText = 'Number of Lines shouldn\'t be less than ' +
                                    String.ValueOf((pBookEntry.Pricebook2.Line_Range_Min__c != null
                                            ? pBookEntry.Pricebook2.Line_Range_Min__c
                                            : 1)
                                            - (qt.Account.Number_of_DL_s__c != null
                                                ? qt.Account.Number_of_DL_s__c
                                                : 0)) +
                                    ' for the ' + pBookEntry.Pricebook2.Name + ' Service Plan.';

                            Errors.put(qli, errorText);
                        }
                    } else {
                        // If QLI Quantity < Pricebook2.Line_Range_Min__c
                        if ((pBookEntry.Pricebook2.Line_Range_Min__c != null
                                ? pBookEntry.Pricebook2.Line_Range_Min__c
                                : 1)
                                > (qli.NewQuantity__c != null
                                        ? qli.NewQuantity__c
                                        : qli.Quantity)) {
                            System.debug('QLI -> ' + qli);
                            String errorText = 'Number of Lines shouldn\'t be less than ' +
                                    String.ValueOf(pBookEntry.Pricebook2.Line_Range_Min__c != null ? pBookEntry.Pricebook2.Line_Range_Min__c : 1) +
                                    ' for the ' + pBookEntry.Pricebook2.Name + ' Service Plan.';
                            Errors.put(qli, errorText);
                        }

                        // If QLI Quantity > Pricebook2.Line_Range_Max__c || 5000
                        if ((pBookEntry.Pricebook2.Line_Range_Max__c != null
                                ? pBookEntry.Pricebook2.Line_Range_Max__c
                                : 5000)
                                < (qli.NewQuantity__c != null
                                        ? qli.NewQuantity__c
                                        : qli.Quantity)) {
                            String errorText = 'Number of Lines shouldn\'t be more than ' +
                                    String.ValueOf(pBookEntry.Pricebook2.Line_Range_Max__c != null ? pBookEntry.Pricebook2.Line_Range_Max__c : 5000) +
                                    ' for the ' + pBookEntry.Pricebook2.Name + ' Service Plan.';
                            Errors.put(qli, errorText);
                        }
                    }
                }

                if(qt.Upsell_Status__c == QuoteHelper.STATUS_UPSELL) {

                    // if it is Proserv Upsell quote and qli.Quantity
                    // was changed - add it to list to validate quantity later(validateChangeOrderQliQuantityChange)
                    Boolean isProservQuote = qt.RecordTypeId == QuoteHelper.RT_ID_PROSERV;

                    Boolean quantityChangedOnUpsellProservQuote = isProservQuote &&
                        CoreObjectBase.isFieldChanged(qli, QuoteLineItem.Quantity);

                    if(quantityChangedOnUpsellProservQuote) {
                        changedQuantityOnUpsellProservQliList.add(qli);
                    }
                }

                List<QuoteLineItem> existingQLIs = quoteIdToProdIdToQLIMap.get(qt.Id).values();
                List<String> euTransportSettings = QuoteLineItemHelper.getEuropeTransportTypes();

                // Bundle validation
                String bundleTypeName = Product2Helper.getCCBundleTypeName(pBookEntry.Product2);
                if (Trigger.isInsert && bundleTypeName != null && !Product2Helper.isOverage(pBookEntry.Product2)) {
                    for (QuoteLineItem existingQLI : existingQLIs) {
                        String sameBundleExistingProdName = getSameBundleExistingProdName(pBookEntry.Product2.Name, existingQLI.Product2.Name);
                        if (!Product2Helper.isOverage(existingQLI.Product2)
                            && bundleTypeName == Product2Helper.getCCBundleTypeName(existingQLI.Product2)
                            && existingQLI.Entitlement__c == null
                            && sameBundleExistingProdName != null)
                        {
                            Errors.put(
                                pbeIdQuoteLineItem.get(pBookEntry.id),
                                'Only one ' + sameBundleExistingProdName + ' bundle can be sold at a time'
                            );
                        }
                    }
                }

                Boolean isMinutesBundleProduct = QuoteLineItemHelper.isMinutesBundleProduct(pBookEntry.Product2.Product_Type__c, Product2Helper.PRODUCT_TYPES_EU_TRANSPORT);
                Boolean isInbentaBundleProduct = pBookEntry.Product2.Product_Type__c == QuoteLineItemHelper.PRODUCT_TYPE_AI;
                Boolean isCCProduct = Product2Helper.isCCProduct(pBookEntry.Product2);
                Boolean isNotOverage = !Product2Helper.FAMILY_OVERAGE.equalsIgnoreCase(pBookEntry.Product2.Family);

                if ( isInbentaBundleProduct && isCCProduct && isNotOverage ) {
                    if ( !allowToAddInbentaBundle(Trigger.isInsert, existingQLIs, pBookEntry) ) {
                        Errors.put(
                            pbeIdQuoteLineItem.get(pBookEntry.Id),
                            'Only one ' + QuoteLineItemHelper.CC_CATEGORIES.get(pBookEntry.Product2.Sub_Category__c) + ' Inbenta Bundle can be sold at a time'
                        );
                    }
                }

                if( isMinutesBundleProduct && isCCProduct && isNotOverage ) {
                    if( !allowToAddMinuteBundle(Trigger.isInsert, existingQLIs, pBookEntry, euTransportSettings) ) {
                        Errors.put(
                            pbeIdQuoteLineItem.get(pBookEntry.id),
                            'Only one ' + QuoteLineItemHelper.CC_CATEGORIES.get(pBookEntry.Product2.Sub_Category__c) + ' Minute Bundle can be sold at a time'
                        );
                    }
                }

                //B-3310 using custom settings to determine single prods
                if(qliSettings.containsKey(String.valueOf(pBookEntry.Product2.Feature__c))
                        && qliSettings.get(String.valueOf(pBookEntry.Product2.Feature__c)).NotAllowSameLineItemInQuote__c) {
                    if (Trigger.isInsert) {
                        if( !allowToAddRCMinuteBundle(qliSettings, existingQLIs, pBookEntry)) {
                            Errors.put(
                                pbeIdQuoteLineItem.get(pBookEntry.id),
                                'Only one RingCentral Native Minute Bundle can be sold at a time'
                            );
                        }
                    }
                }
                // -- end --

                if(pbeIdQuoteLineItem.get(pBookEntry.id).Discount_number__c >= 0){
                    if (pBookEntry.Max_DIscount__c!=null){
                        Decimal maxDiscountInCurrency = (pBookEntry.Max_DIscount__c/100) * pbeIdQuoteLineItem.get(pBookEntry.id).UnitPrice;
                        Decimal maxDiscountInPercentage = pBookEntry.Max_DIscount__c;
                        if((pbeIdQuoteLineItem.get(pBookEntry.id).Discount_type__c == QuoteLineItemHelper.DISCOUNT_TYPE_PERCENTAGE) || (pbeIdQuoteLineItem.get(pBookEntry.id).Discount_type__c == null)){
                            if((maxDiscountInPercentage > 100) && (pbeIdQuoteLineItem.get(pBookEntry.id).Discount_number__c > 100)){
                                if((Errors.get(pbeIdQuoteLineItem.get(pBookEntry.id))) ==null){
                                    Errors.put((pbeIdQuoteLineItem.get(pBookEntry.id)), 'Discount shouldn\'t be more than 100%.');
                                }
                                else{
                                    Errors.put(
                                            pbeIdQuoteLineItem.get(pBookEntry.id),
                                            ((Errors.get(pbeIdQuoteLineItem.get(pBookEntry.id)))
                                                    + '<br/>Discount shouldn\'t be more than 100%.')
                                    );
                                }

                            }
                        }
                        if(pbeIdQuoteLineItem.get(pBookEntry.id).Discount_type__c == QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY){
                            if(
                                    (maxDiscountInPercentage > 100)
                                            && (pbeIdQuoteLineItem.get(pBookEntry.id).Discount_number__c
                                            > pbeIdQuoteLineItem.get(pBookEntry.id).UnitPrice)
                                            && (pbeIdQuoteLineItem.get(pBookEntry.id).UnitPrice > 0)
                                    ){
                                if((Errors.get(pbeIdQuoteLineItem.get(pBookEntry.id))) ==null){
                                    Errors.put((pbeIdQuoteLineItem.get(pBookEntry.id)), 'Discount shouldn\'t be more than a price of the Product.');
                                }
                                else{
                                    Errors.put(
                                            (pbeIdQuoteLineItem.get(pBookEntry.id)),
                                            ((Errors.get(pbeIdQuoteLineItem.get(pBookEntry.id)))
                                                    + '<br/>Discount shouldn\'t be more than a price of the Product.')
                                    );
                                }
                            }
                        }
                    }
                    if(pBookEntry.Max_DIscount__c == null){
                        if(
                                ((pbeIdQuoteLineItem.get(pBookEntry.id).Discount_type__c == QuoteLineItemHelper.DISCOUNT_TYPE_PERCENTAGE)
                                        || (pbeIdQuoteLineItem.get(pBookEntry.id).Discount_type__c == null))
                                        && (pbeIdQuoteLineItem.get(pBookEntry.id).Discount_number__c > 100)
                                ){
                            if((Errors.get(pbeIdQuoteLineItem.get(pBookEntry.id))) == null){
                                Errors.put((pbeIdQuoteLineItem.get(pBookEntry.id)), 'Discount shouldn\'t be more than 100%.');
                            }
                            else{
                                Errors.put(
                                        pbeIdQuoteLineItem.get(pBookEntry.id),
                                        ((Errors.get(pbeIdQuoteLineItem.get(pBookEntry.id)))
                                                + '<br/>Discount shouldn\'t be more than 100%.')
                                );
                            }
                        }
                        if(
                                (pbeIdQuoteLineItem.get(pBookEntry.id).Discount_type__c == QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY)
                                        && (pbeIdQuoteLineItem.get(pBookEntry.id).Discount_number__c
                                        > pbeIdQuoteLineItem.get(pBookEntry.id).UnitPrice)
                                        && (pbeIdQuoteLineItem.get(pBookEntry.id).UnitPrice > 0)
                                ){
                            if((Errors.get(pbeIdQuoteLineItem.get(pBookEntry.id))) ==null){
                                Errors.put((pbeIdQuoteLineItem.get(pBookEntry.id)), 'Discount shouldn\'t be more than a price of the Product.');
                            }
                            else{
                                Errors.put(
                                        pbeIdQuoteLineItem.get(pBookEntry.id),
                                        ((Errors.get(pbeIdQuoteLineItem.get(pBookEntry.id)))
                                                + '<br/>Discount shouldn\'t be more than a price of the Product.')
                                );
                            }
                        }
                    }
                }
                if(pbeIdQuoteLineItem.get(pBookEntry.id).Discount_number__c < 0){
                    if((Errors.get(pbeIdQuoteLineItem.get(pBookEntry.id))) ==null){
                        Errors.put((pbeIdQuoteLineItem.get(pBookEntry.id)), 'Discount should be a positive number.');
                    }
                    else{
                        Errors.put(
                                (pbeIdQuoteLineItem.get(pBookEntry.id)),
                                ((Errors.get(pbeIdQuoteLineItem.get(pBookEntry.id)))
                                        + '<br/>Discount should be a positive number.')
                        );
                    }
                }

            }

            if(Trigger.isBefore) {
                Set<Id> accIds = new Set<Id>();
                for (PriceBookEntry pBookEntry : pBookEntries){
                    QuoteLineItem qli = pbeIdQuoteLineItem.get(pBookEntry.Id);
                    Quote qt = quotesMap.get(qli.QuoteId);
                    accIds.add(qt.AccountId);
                }

                List<Entitlement__c> entitlements = [SELECT Product__c, Product__r.Feature__c, Product__r.Sub_Category__c, Account__c
                                                     FROM Entitlement__c
                                                     WHERE Active__c = true AND Quote__c = null
                                                     AND Account__c IN :accIds];

                validateCcAndInContactProdsInsert(entitlements, pBookEntries, pbeIdQuoteLineItem, quotesMap, Errors);
            }

            // validate QuoteLineItems Quantity field changes(for Proserv Upsell Quotes)
            if(!changedQuantityOnUpsellProservQliList.isEmpty()) {

                Map<QuoteLineItem, String> errorsMap = validateChangeOrderQliQuantityChange(changedQuantityOnUpsellProservQliList, quotesMap);

                if(!errorsMap.isEmpty()) {
                    Errors.putAll(errorsMap);
                }
            }


            if(Errors.size()>0){
                for(QuoteLineItem qli : (List<QuoteLineItem>)Trigger.new){
                    if(Errors.containsKey(qli)){
                        qli.addError((Errors.get(qli)), false);
                    }
                }
            }
        }

        private void addMissingMapValues(PriceBookEntry[] pBookEntries, Map<Id, Map<Id, QuoteLineItem>> quoteIdToProdIdToQLIMap, Map<Id, QuoteLineItem> pbeIdQuoteLineItem, Map<Id, Quote> quotesMap) {
            Set<Id> missedQuoteIdSet = new Set<Id>();
            for (PriceBookEntry pBookEntry : pBookEntries) {
                QuoteLineItem qli = pbeIdQuoteLineItem.get(pBookEntry.Id);
                Quote qt = quotesMap.get(qli.QuoteId);

                if( !quoteIdToProdIdToQLIMap.containsKey(qt.Id) ) {
                    missedQuoteIdSet.add(qt.Id);
                }
            }

            if(!missedQuoteIdSet.isEmpty()) {
                QuoteLineItemTriggerHelper.setQuoteIdToProdIdToQLIMap(missedQuoteIdSet, quoteIdToProdIdToQLIMap);
            }
        }

        private void validateCcAndInContactProdsInsert(List<Entitlement__c> entitlements, List<PriceBookEntry> pBookEntries, Map<Id, QuoteLineItem> pbeIdQuoteLineItem, Map<Id, Quote> quotesMap, Map<QuoteLineItem, String> Errors) {

            Map<Id, List<Entitlement__c>> entitlementsByAccMap = new Map<Id, List<Entitlement__c>>();

            for(Entitlement__c e : entitlements) {
                List<Entitlement__c> tempEntList = new List<Entitlement__c>();
                if(entitlementsByAccMap.containsKey(e.Account__c)) {
                    tempEntList.addAll(entitlementsByAccMap.get(e.Account__c));
                }
                tempEntList.add(e);
                entitlementsByAccMap.put(e.Account__c, tempEntList);
            }

            for (PriceBookEntry pBookEntry : pBookEntries){

                QuoteLineItem qli = pbeIdQuoteLineItem.get(pBookEntry.Id);
                Quote qt = quotesMap.get(qli.QuoteId);

                List<Entitlement__c> currEnts = new List<Entitlement__c>();
                if(entitlementsByAccMap.containsKey(qt.AccountId)) {
                    currEnts.addAll(entitlementsByAccMap.get(qt.AccountId));
                }

                Set<String> subCategoriesSet = new Set<String>();
                Set<Decimal> featuresSet = new Set<Decimal>();

                for(QuoteLineItem qliEntry : quoteIdToProdIdToQLIMap.get(qt.Id).values()) {
                    subCategoriesSet.add(
                        productsMapStatic.get(qliEntry.Product2Id)?.Sub_Category__c
                    );
                    featuresSet.add(qliEntry.Product2.Feature__c);
                }

                if(pBookEntry.Product2.Feature__c != null && pBookEntry.Product2.Feature__c == Product2Helper.FEATURE_INCONTACT_INTERCONNECT) {
                    if(subCategoriesSet.contains(Product2Helper.SUBCATEGORY_CONTACT_CENTER)) {
                        Errors.put((pbeIdQuoteLineItem.get(pBookEntry.id)),
                                'inContact Interconnect product can\'t be added to the current Quote because there are Contact Center products on it.');
                        break;
                    }

                    if(!currEnts.isEmpty()) {
                        for(Entitlement__c e : currEnts) {
                            if(e.Product__r.Sub_Category__c == Product2Helper.SUBCATEGORY_CONTACT_CENTER) {
                                Errors.put((pbeIdQuoteLineItem.get(pBookEntry.id)),
                                        'inContact Interconnect product can\'t be added to the current Quote because there are Contact Center Entitlements on associated Account.');
                                break;
                            }
                        }
                    }
                }

                if( pBookEntry.Product2.Sub_Category__c != null && pBookEntry.Product2.Sub_Category__c.equals(Product2Helper.SUBCATEGORY_CONTACT_CENTER) ) {
                    if(featuresSet.contains(Product2Helper.FEATURE_INCONTACT_INTERCONNECT)) {
                        Errors.put((pbeIdQuoteLineItem.get(pBookEntry.id)),
                                'Contact Center products can\'t be added to the current Quote because there is an inContact Interconnect product on it.');
                        break;
                    }

                    if(!currEnts.isEmpty()) {
                        for(Entitlement__c e : currEnts) {
                            if(e.Product__r.Feature__c == Product2Helper.FEATURE_INCONTACT_INTERCONNECT) {
                                Errors.put((pbeIdQuoteLineItem.get(pBookEntry.id)),
                                        'Contact Center products can\'t be added to the current Quote because there are inContact Interconnect Entitlements on associated Account.');
                                break;
                            }
                        }
                    }
                }
            }
        }

        /**
        * Validate QuoteLineItems Quantity field changes - if quoteLineItem related to 'ChangeOrder' Quote
        * (Opportunity has only one quote - and this Quote has Upsell status and Proserv recordType)
        * if user try to save quoteLineItem from that Quote and its Quantity lower
        * than <Delivered Quantity> on related Asset(Asset.QuoteLineItem__c) - we should throw error 'Quantity can\'t be less than <Delivered Quantity> for that QLI.'
        *
        * if user try to save QLI (with disabled Product) from that Quote and its NewQuantity is higher than Asset.Quantity
        * we should throw an error 'This Product became unavailable, you can’t sell more than was sold on original Order - ' + asset.Quantity
        *
        * @param quoteLineItems List of Quote Line Items to validate. Should have fields:
        *                       QuoteId, Product2Id, Quantity, Product2.IsActive
        *
        * @param quotesMap      Map where QuoteId related to Quote Sobject(quote should have fields:
        *                       OpportunityId, AccountId)
        *
        * @return Map<QuoteLineItem, String> - errorsMap - map where QuoteLineItem related to his error string
        */
        private Map<QuoteLineItem, String> validateChangeOrderQliQuantityChange(List<QuoteLineItem> qliToProcessList, Map<Id, Quote> quotesMap) {

            Map<QuoteLineItem, String> qliToErrorsMap = new Map<QuoteLineItem, String>();

            if( (qliToProcessList == null || qliToProcessList.isEmpty()) ||
                (quotesMap == null || quotesMap.isEmpty()) ) {

                return qliToErrorsMap;
            }

            Set<Id> oppIdSet = new Set<Id>();
            for(QuoteLineItem qli : qliToProcessList) {
                Quote qt = quotesMap.get(qli.QuoteId);
                if(qt.OpportunityId != null) {
                    oppIdSet.add(qt.OpportunityId);
                }
            }

            if(oppIdSet.isEmpty()) {
                return qliToErrorsMap;
            }

            Map<Id, Integer> oppIdToRelatedQuoteCountMap = new Map<Id, Integer>();

            for(Quote qt : [select Id, OpportunityId, RecordTypeId, Products__c from Quote where OpportunityId in :oppIdSet]) {
                if(oppIdToRelatedQuoteCountMap.get(qt.OpportunityId) == null) {
                    oppIdToRelatedQuoteCountMap.put(qt.OpportunityId, 1);
                }else{
                    Integer quotesForOppCount = oppIdToRelatedQuoteCountMap.get(qt.OpportunityId);
                    oppIdToRelatedQuoteCountMap.put(qt.OpportunityId, quotesForOppCount + 1);
                }
            }

            List<QuoteLineItem> qliToValidateList = new List<QuoteLineItem>();

            for(QuoteLineItem qli : qliToProcessList) {
                Quote qt = quotesMap.get(qli.QuoteId);
                Integer quotesOnOpportunityCount = oppIdToRelatedQuoteCountMap.get(qt.OpportunityId);

                Boolean isProservQuote = qt.RecordTypeId == QuoteHelper.RT_ID_PROSERV;
                // changeOrder quote - opp has only one quote, and this quote with proserv recordtype and upsell status
                Boolean isChangeOrderQuote = isProservQuote && (qt.Upsell_Status__c == QuoteHelper.STATUS_UPSELL) &&
                    (quotesOnOpportunityCount == 1);

                if(isChangeOrderQuote) {

                    qliToValidateList.add(qli);
                }
            }

            if(qliToValidateList.isEmpty()) {
                return qliToErrorsMap;
            }

            Set<Id> assetIdSet = new Set<Id>();
            for(QuoteLineItem qli : qliToValidateList) {
                if(qli.Asset__c != null) {
                    assetIdSet.add(qli.Asset__c);
                }
            }

            if(assetIdSet.isEmpty()) {
                return qliToErrorsMap;
            }

            Map<Id, Asset> assetMap = new Map<Id, Asset>([select Id, Delivered_Quantity__c, Quantity
                from Asset where Id in :assetIdSet]);

            for(QuoteLineItem qli : qliToValidateList) {
                if(qli.Asset__c != null && assetMap.get(qli.Asset__c) != null) {
                    Asset asset = assetMap.get(qli.Asset__c);
                    Decimal qliQuantityZeroed = qli.Zero_Quantity__c ? 0 : qli.Quantity;
                    Boolean qliProductIsActive = priceBookEntryMapStatic.get(qli.PriceBookEntryId).Product2.IsActive;

                    if(asset.Delivered_Quantity__c > qli.NewQuantity__c || qliQuantityZeroed < 0) {
                       qliToErrorsMap.put(qli, 'Quantity can\'t be less than ' + asset.Delivered_Quantity__c + ' for that QLI.');
                    }
                    if(qliProductIsActive != true &&
                        (qli.NewQuantity__c > asset.Quantity || qliQuantityZeroed + asset.Delivered_Quantity__c > asset.Quantity)){
                        qliToErrorsMap.put(qli, 'This Product became unavailable, you can’t sell more than was sold on original Order - ' + asset.Quantity);
                    }
                }
            }

            return qliToErrorsMap;
        }

        private String getSameBundleExistingProdName(String pBookEntryProdName, String existingQLIprodName) {
            String prodName;
            String prodNameBeforeParentheses = pBookEntryProdName.substringBefore('(');
            String prodNameBeforeDash = pBookEntryProdName.substringBefore('-');

            if (prodNameBeforeParentheses.equals(existingQLIprodName?.substringBefore('('))) {
                prodName = prodNameBeforeParentheses;
            } else if (prodNameBeforeDash.equals(existingQLIprodName?.substringBefore('-'))) {
                prodName = prodNameBeforeDash;
            }
            return prodName;
        }
    }

    public static Boolean allowToAddInbentaBundle(Boolean isInsert, List<QuoteLineItem> qliList, PriceBookEntry pBookEntry) {
        Boolean result = true;

        if( !(qliList.size() > 0) ) {
            return result;
        }

        // new
        if(isInsert) {
            Map<String,Set<Id>> ProductTypeToSetProductId = new Map<String,Set<Id>>();
            for( QuoteLineItem item : qliList ) {
                Boolean isInbentaBundleProduct = pBookEntry.Product2.Product_Type__c == QuoteLineItemHelper.PRODUCT_TYPE_AI;
                Boolean isCCProduct = Product2Helper.isCCProduct(item.Product2);
                Boolean isNotOverage = !QuoteLineItemHelper.isOverage(item);
                if( isInbentaBundleProduct && isNotOverage && isCCProduct && item.Deactivated__c == false && item.Entitlement__r.Id == null ) {
                    Set<Id> existingProductIds = ProductTypeToSetProductId.get(item.Product2.Product_Type__c);
                    existingProductIds = (existingProductIds != null) ? existingProductIds : new Set<Id>();
                    existingProductIds.add(item.Product2Id);
                    ProductTypeToSetProductId.put(item.Product2.Product_Type__c, existingProductIds);
                }
            }

            Set<Id> productIdsForValidate = ProductTypeToSetProductId.get(pBookEntry.Product2.Product_Type__c);
            if( productIdsForValidate != null && productIdsForValidate.size() > 0 ) { result = false; }
        }

        return result;
    }

    public static Boolean allowToAddMinuteBundle(Boolean isInsert, List<QuoteLineItem> qliList, PriceBookEntry pBookEntry, List<String> euTransportSettings) {

        Boolean result = true;

        if( !(qliList.size() > 0) ) {
            return result;
        }

        // Cases when we can add Minutes Bundle(MB):
        // 1. Quote does not contain any MB;
        // 2. Quote contains any MB with entitlement;
        // 4. MB with different Product Types;
        // !? Quote can not contains Deactivated MB as new product but validation takes it into account.
        // !  Frontend part has validation (deactivation of MB by demand - see QuotingToolCartList in Aura Components).

        // new
        if(isInsert) {
            Map<String,Set<Id>> ProductTypeToSetProductId = new Map<String,Set<Id>>();
            for( QuoteLineItem item : qliList ) {
                Boolean isMinutesBundleProduct = QuoteLineItemHelper.isMinutesBundleProduct(item.Product2.Product_Type__c, euTransportSettings);
                Boolean isCCProduct = Product2Helper.isCCProduct(item.Product2);
                Boolean isNotOverage = !QuoteLineItemHelper.isOverage(item);
                if( isMinutesBundleProduct && isNotOverage && isCCProduct && item.Deactivated__c == false && item.Entitlement__r.Id == null ) {
                    Set<Id> existingProductIds = ProductTypeToSetProductId.get(item.Product2.Product_Type__c);
                    existingProductIds = (existingProductIds != null) ? existingProductIds : new Set<Id>();
                    existingProductIds.add(item.Product2Id);
                    ProductTypeToSetProductId.put(item.Product2.Product_Type__c, existingProductIds);
                }
            }

            Set<Id> productIdsForValidate = ProductTypeToSetProductId.get(pBookEntry.Product2.Product_Type__c);
            if( productIdsForValidate != null && productIdsForValidate.size() > 0 ) { result = false; }
        }

        return result;
    }

    public static Boolean allowToAddRCMinuteBundle(
            Map<String, QuoteLineItemRestrictionSettings__c> qliSettings,
            List<QuoteLineItem> qliList,
            PriceBookEntry pBookEntry
    ) {
        Boolean result = true;

        if( !(qliList.size() > 0) ) {
            return result;
        }

        Map<Decimal, Set<Id>> ProductFeatureToSetProductId = new Map<Decimal, Set<Id>>();
        for (QuoteLineItem item : qliList ) {
            Boolean isQLIRestrSettingExists = (qliSettings.get(String.valueOf(item.Product2.Feature__c)) != null) ? true : false;
            Boolean isItemSatisfyRequiments = (item.Product2.Family == 'Add - Ons'
                                        && item.Product2.Sub_Category__c == 'Main'
                                        && item.Deactivated__c == false
                                        && item.Entitlement__r.Id == null) ? true : false;
            // Ignore 'Restriction Setting' logic if there is no restriction for current feature.
            if (isItemSatisfyRequiments
                    && (!isQLIRestrSettingExists
                    || (isQLIRestrSettingExists && qliSettings.get(String.valueOf(item.Product2.Feature__c)).NotAllowSameLineItemInQuote__c))) {
                Set<Id> existingProductIds = ProductFeatureToSetProductId.get(item.Product2.Feature__c);
                existingProductIds = (existingProductIds != null) ? existingProductIds : new Set<Id>();
                existingProductIds.add(item.Product2Id);
                ProductFeatureToSetProductId.put(item.Product2.Feature__c, existingProductIds);
            }
        }

        Set<Id> productIdsForValidate = ProductFeatureToSetProductId.get(pBookEntry.Product2.Feature__c);
        if( productIdsForValidate != null && productIdsForValidate.size() > 0 ) { result = false; }

        return result;
    }

    public class SetIsHiddenLicense extends Triggers.TriggerHandlerBase {

        override public void handle() {

            Set<String> hiddenLicensesSet = new Set<String>();

            Quote staticQuote = Trigger.new.size() > 0 ? quotesMapStatic.get(((QuoteLineItem)Trigger.new[0]).QuoteId) : null;

            Boolean isExistingBusiness = OpportunityHelper.isExistingBusinessBilling(staticQuote);

            List<String> bypassLicenses = QuoteLineItemHelper.getLicensesForPurchaseBypass(staticQuote?.Opportunity?.BusinessIdentity__c);

            SettingsService.NGBSLicenseSetting ngbsLicenseSetting = SettingsService.getNGBSLicenseSetting(isExistingBusiness, bypassLicenses);

            BillingWrappers.QuotePackageInfo info = staticQuote != null && String.isNotBlank(staticQuote.Package_Info__c)
                ? new BillingWrappers.QuotePackageInfoWrapper(staticQuote.Package_Info__c).getPackageInfo()
                : null;

            for(String packageId : ngbsLicenseSetting.hiddenSettings.keySet()) {
                if(packageId == SettingsService.ALL ||
                    info != null && info.packageInfo != null && info.packageInfo.catalogId != null && info.packageInfo.catalogId == packageId
                ) {
                    hiddenLicensesSet.addAll(ngbsLicenseSetting.hiddenSettings.get(packageId));
                }
            }

            if(hiddenLicensesSet.isEmpty()) {
                System.debug('cannot found any hidden licences in NGBSHiddenLicenses__c custom setting. skip processing IsHiddenLicense__c');
                return;
            }

            List<QuoteLineItem> ngbsQliList = new List<QuoteLineItem>();
            Set<Id> product2IdSet = new Set<Id>();

            for(QuoteLineItem qli: (List<QuoteLineItem>)Trigger.new) {
                if(QuoteLineItemHelper.isNGBSQuoteLineItem(qli)) {
                    ngbsQliList.add(qli);
                    product2IdSet.add(qli.Product2Id);
                }
            }

            if(ngbsQliList.isEmpty()) {
                System.debug('not found NGBS qlis in trigger.new. skip processing IsHiddenLicense__c');
                return;
            }

            Boolean isNeedToSelectProducts = !productsMapStatic.keySet().containsAll(product2IdSet);
            if(isNeedToSelectProducts) {
                List<Product2> productList = [SELECT Id, Name, Family,
                        Feature__c, Sub_Feature__c,
                        Charge_Term__c, ExtID__c, Sub_Category__c
                    FROM Product2
                    WHERE Id IN :product2IdSet];

                for(Product2 p2 : productList) {
                    productsMapStatic.put(p2.Id, p2);
                }
            }

            List<QuoteLineItem> hiddenLicenseQliList = new List<QuoteLineItem>();
            List<QuoteLineItem> visibleLicenseQliList = new List<QuoteLineItem>();

            for(QuoteLineItem qli: ngbsQliList) {
                if(productsMapStatic.containsKey(qli.Product2Id)) {

                    Product2 prod = productsMapStatic.get(qli.Product2Id);

                    if(hiddenLicensesSet.contains(prod.ExtID__c)) {
                        qli.IsHiddenLicense__c = true;
                        hiddenLicenseQliList.add(qli);
                    }else{
                        qli.IsHiddenLicense__c = false;
                        visibleLicenseQliList.add(qli);
                    }
                }
            }
        }
    }

    public class CountPerecentageFromCurrencyDiscount extends Triggers.TriggerHandlerBase {

        private final Set<sObjectField> DISCOUNT_RECALCULATION_FIELDS = new Set<sObjectField>{
            QuoteLineItem.UnitPrice,
            QuoteLineItem.NewQuantity__c,
            QuoteLineItem.Discount_type__c,
            QuoteLineItem.Discount_number__c
        };

        override public void handle() {
            List<QuoteLineItem> qliUpdatedList = new List<QuoteLineItem>();
            Set<Id> qliIds = new Set<Id>();
            String [] SalesRep;
            String [] SalesManager;
            String [] SalesManagerManager;
            String [] SalesVP;
            String [] Range;
            Map<Id, Integer> qliAppType = new Map<Id, Integer>();

            if(trigger.isUpdate){
                for(QuoteLineItem qli: (List<QuoteLineItem>)Trigger.new){

                    Boolean isRecalculate = false;
                    for (sObjectField field : DISCOUNT_RECALCULATION_FIELDS) {
                        if ( isChangedField(qli, field) ) {
                            isRecalculate = true;
                            break;
                        }
                    }

                    if(!isRecalculate) {
                        continue;
                    }

                    Decimal newDiscount = qli.Discount_number__c == null ? 0 : qli.Discount_number__c;

                    if (qli.UnitPrice == 0) {
                        qli.Discount = null;
                    } else if (qli.Discount_type__c == QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY) {
                        qli.Discount = (newDiscount / qli.UnitPrice) * 100;
                    } else {
                         qli.Discount = newDiscount;
                    }
                }
            }
            if(trigger.isInsert){
                for(QuoteLineItem qli: (List<QuoteLineItem>)Trigger.new){
                    if(qli.Discount_number__c != null){
                        if (qli.Discount_type__c == QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY) {
                            qli.Discount = (qli.UnitPrice != null && qli.UnitPrice != 0)
                                ? (qli.Discount_number__c / qli.UnitPrice) * 100
                                : 0;
                        } else {
                            qli.Discount = qli.Discount_number__c;
                        }
                    }
                }
            }
        }
    }

    private static Boolean byPassNewQuantityUpdate = false;
    public static void setByPassNewQuantityUpdate(Boolean byPass) {
        if(Test.isRunningTest()) {
            byPassNewQuantityUpdate = byPass;
        }else{
            System.debug('you can bypass newQuantity update only in tests!');
        }
    }


    /**
     * @see QuoteLineItemTriggerHelper.testPopulateNewQuantity Test method
     * Documentation:
     * https://aquiva.atlassian.net/wiki/spaces/RC/pages/209977389/Quantity+fields
     */
    public class PopulateNewQuantity extends Triggers.TriggerHandlerBase {
        override public void handle() {

            if(byPassNewQuantityUpdate == true) {
                return;
            }

            Set<Id> entIds = new Set<Id>();
            Set<Id> assetIds = new Set<Id>();
            for(QuoteLineItem qli : (List<QuoteLineItem>)Trigger.new) {
                if(qli.Entitlement__c != null) {
                    entIds.add(qli.Entitlement__c);
                }
                if(qli.Asset__c != null) {
                   assetIds.add(qli.Asset__c);
                }
            }
            Map<Id, Entitlement__c> entQuantityMap = new Map<Id, Entitlement__c>();
            if(!entIds.isEmpty()) {
                entQuantityMap = new Map<Id, Entitlement__c>([SELECT Id, DisplayQuantity__c FROM Entitlement__c WHERE Id IN: entIds]);
            }

            Map<Id, Asset> assetQuantityMap = new Map<Id, Asset>();
            if(!assetIds.isEmpty()) {
                assetQuantityMap = new Map<Id, Asset>([SELECT Id, Quantity, Delivered_Quantity__c FROM Asset WHERE Id IN: assetIds]);
            }
            for (QuoteLineItem qli : (List<QuoteLineItem>) Trigger.new) {

                Decimal quantity = QuoteLineItemHelper.getQuantity(qli);
                Decimal existingQuantity = 0;

                if (!entQuantityMap.isEmpty() &&
                    qli.Entitlement__c != null &&
                    entQuantityMap.containsKey(qli.Entitlement__c) &&
                    null != entQuantityMap.get(qli.Entitlement__c).DisplayQuantity__c) {

                    existingQuantity = entQuantityMap.get(qli.Entitlement__c).DisplayQuantity__c;
                } else if (!assetQuantityMap.isEmpty() &&
                    qli.Entitlement__c == null &&
                    assetQuantityMap.containsKey(qli.Asset__c) &&
                    null != assetQuantityMap.get(qli.Asset__c).Delivered_Quantity__c) {

                    existingQuantity = assetQuantityMap.get(qli.Asset__c).Delivered_Quantity__c;
                }

                qli.NewQuantity__c = existingQuantity + quantity;
            }
        }
    }


    private static final String TAXES_PRODUCT_FAMILY = 'Taxes';

    public static Boolean byPassQuoteUpdate = false;

    public class SetQuoteApprovalType extends Triggers.TriggerHandlerBase {

        override public void handle() {
            List<QuoteLineItem> qlis = Trigger.isDelete
                    ? (List<QuoteLineItem>) Trigger.old
                    : (List<QuoteLineItem>) Trigger.new;

            List<QuoteLineItem> qlisToProcess = new List<QuoteLineItem>();

            Map<String, Set<String>> quoteRTNameToSuitableSubCategoriesMap = QuoteApprovals.buildQuoteRTNameToSuitableSubCategoryMap();

            for (QuoteLineItem qli : qlis) {

                Id quoteRtId = (quotesMapStatic.get(qli.QuoteId)).RecordTypeId;

                Boolean isNGBSQuote = quoteRtId == QuoteHelper.RT_ID_BILLING ||
                    quoteRtId == QuoteHelper.RT_ID_CC ||
                    quoteRtId == QuoteHelper.RT_ID_POC;

                if(isNGBSQuote) {
                    continue;
                }

                Boolean isSuitableQuoteRT = quoteRTNameToSuitableSubCategoriesMap.keySet().contains(qli.QuoteRecordType__c);
                Boolean isSuitableSubCategory = isSuitableQuoteRT
                        ? quoteRTNameToSuitableSubCategoriesMap.get(qli.QuoteRecordType__c).contains(qli.Sub_Category__c)
                        : false;

                if(!isSuitableQuoteRT || !isSuitableSubCategory) {
                    continue;
                }

                Quote qt = quotesMapStatic.get(qli.QuoteId);

                if (QuoteHelper.isMigrationFlow(qt, UserInfo.getUserId())) {
                    continue;
                }

                qlisToProcess.add(qli);
            }

            Set<Id> quoteIdSet = new Set<Id>();
            Set<Id> qliIdToDeleteSet = new Set<Id>();

            Boolean isSkipUpdate = QuoteLineItemHelper.isSkipUpdate(qlis);
            for(QuoteLineItem qli : qlisToProcess) {

                Double qliDiscount = qli.Discount_type__c == QuoteLineItemHelper.DISCOUNT_TYPE_PERCENTAGE ?
                    qli.Discount == null ? 0 : qli.Discount
                    : qli.Discount_Value__c == null ? 0 : qli.Discount_Value__c;

                if(Trigger.isDelete && qliDiscount > 0){
                    qliIdToDeleteSet.add(qli.Id);
                }

                if(Trigger.isUpdate && !isSkipUpdate) {
                    QuoteLineItem oldQli = (QuoteLineItem)Trigger.oldMap.get(qli.Id);

                    if (qli.Quantity != oldQli.Quantity ||
                            (qli.Discount != oldQli.Discount) ||
                            (qli.NewQuantity__c != oldQli.NewQuantity__c)) {

                        quoteIdSet.add(qli.QuoteId);
                    }

                } else {

                    // if we add or delete taxes - do not change quote approvers and status
                    Boolean isTaxesProduct = (qli.Product_Family__c == TAXES_PRODUCT_FAMILY);

                    if(!isTaxesProduct && qliDiscount > 0) {
                        quoteIdSet.add(qli.QuoteId);
                    }
                }

            }

            List<Quote> quotesToUpdate = QuoteApprovals.handleQuotes(quoteIdSet, qliIdToDeleteSet, null);

            if(!quotesToUpdate.isEmpty() || !QuoteApprovals.quotesExcludedForDQGoa.isEmpty()) {
                if (!QuoteApprovals.quotesExcludedForDQGoa.isEmpty()) {
                    Set<Id> addedQuoteIds = new Set<Id>();
                    for (Quote qt : QuoteApprovals.quotesExcludedForDQGoa) {
                        if (!addedQuoteIds.contains(qt.Id)) {
                            quotesToUpdate.add(
                                getQuoteWithApproversFields(qt)
                            );
                            addedQuoteIds.add(qt.Id);
                        }
                    }
                }
                // set totals(First_Year_Cost_of_Service__c, First_Year_Discount__c, Monthly_Recurring_Revenue__c, First_Year_Total_Cost_excluding_Taxes__c)
                quotesToUpdate = QuoteLineItemHelper.setTotals(quotesToUpdate, QuoteApprovals.qliList);

                // add svpWws and coo approvers
                if(quoteIdSet.size() > 0) {
                    // merge changes in quotesToUpdateMap
                    Map<Id, Quote> quotesToUpdateMap = new Map<Id, Quote>();

                    for(Quote q : quotesToUpdate) {

                        quotesToUpdateMap.put(q.Id, q);
                    }

                    if(quotesToUpdateMap.size() > 0) {
                        update quotesToUpdateMap.values();
                    }
                }
            }


            //NEW LOGIC
            Set<Id> quoteIds = new Set<Id>();
            Set<Id> quotesWithChangedQlis = new Set<Id>();
            List<QuoteLineItem> allQlis = new List<QuoteLineItem>();
            Map<Id, Map<Id, QuoteLineItem>> quoteIdToQliMap = new Map<Id, Map<Id, QuoteLineItem>>();
            Map<Id, Id> quoteIdToContractId = new Map<Id, Id>();
            List<Contract__c> allContracts = new List<Contract__c>();
            List<Quote> quotesForUpdate = new List<Quote>();
            qliIdToDeleteSet = new Set<Id>();
            Boolean needToHandle = true;

            //find qlis with changed discounts
            for(QuoteLineItem qli : qlis) {
                if(!Trigger.isDelete) {
                    if(Trigger.isUpdate) {
                        QuoteLineItem newQli = ((Map<Id, QuoteLineItem>) Trigger.newMap).get(qli.Id);
                        QuoteLineItem oldQli = ((Map<Id, QuoteLineItem>) Trigger.oldMap).get(qli.Id);

                        // Skip taxes
                        if (!Product2Helper.isTaxes(newQli) && hasPricingOrDiscountChanged(newQli, oldQli)) {
                            quoteIds.add(qli.QuoteId);
                        }
                    }

                    if(Trigger.isInsert) {
                        quoteIds.add(qli.QuoteId);
                    }
                } else {
                    quoteIds.add(qli.QuoteId);
                    qliIdToDeleteSet.add(qli.Id);
                }
            }

            //get all quotes with changed qlis
            if(quoteIds.size() > 0) {
                for(Quote q : quotesMapStatic.values()) {
                    if(quoteIds.contains(q.Id) && (q.RecordTypeId == QuoteHelper.RT_ID_BILLING || q.RecordTypeId == QuoteHelper.RT_ID_CC)) {
                        quotesWithChangedQlis.add(q.Id);
                    }
                }


                allQlis = [
                    SELECT id, Discount_type__c, TotalPrice, Discount, QuoteId, PackageInfo__c, Package_Info_QLI__c, Package_Info__c,
                           Discount_number__c, Product2Id, ListPrice, UnitPrice, ServiceName__c, Product2.ExtID__c, Product_Family__c,
                           Entitlement__r.Discount__c, Entitlement__r.Discount_Type__c
                    FROM QuoteLineItem
                    WHERE QuoteId IN: quotesWithChangedQlis
                ];
            }

            for(Id qId : quotesWithChangedQlis) {
                Quote q = quotesMapStatic.get(qId);
                BillingWrappers.QuotePackageInfo info = new BillingWrappers.QuotePackageInfo();
                if(q.Package_Info__c != null && q.Package_Info__c != '') {
                    info = (BillingWrappers.QuotePackageInfo) JSON.deserialize(q.Package_Info__c.substring(1, q.Package_Info__c.length() - 1), BillingWrappers.QuotePackageInfo.class);
                }
                if(info != null && info.contract != null && info.contract.id != null) {
                    quoteIdToContractId.put(qId, info.contract.id);
                }
            }

            if (!quoteIdToContractId.isEmpty() && quoteIdToContractId.values().size() > 0) {
                allContracts = [
                    SELECT Id,
                    (SELECT Contract__c, ApplicableTo__c, Discount__c FROM Contract_Discounts__r)
                    FROM Contract__c
                    WHERE Id IN: quoteIdToContractId.values()
                ];
            }

            Map<Id, QuoteLineItem> proservQlis = new Map<Id, QuoteLineItem>();

            if (Trigger.isUpdate) {
                for (QuoteLineItem qli : (List<QuoteLineItem>) Trigger.old) {
                    if (QuoteLineItemHelper.isProfessionalServiceQli(qli)) {
                        proservQlis.put(qli.Id, qli);
                    }
                }
            }

            for (Id qId : quotesWithChangedQlis) {
                List<Contract_Discount__c> discounts = new List<Contract_Discount__c>();

                for(Contract__c c : allContracts) {
                    if(c.Id == quoteIdToContractId.get(qId)) {
                        for(Contract_Discount__c discount : c.Contract_Discounts__r) {
                            discounts.add(discount);
                        }
                    }
                }

                Quote q = quotesMapStatic.get(qId);

                if (QuoteHelper.isNGBSQuote(q) && q.IsNewGOAEnabled__c) {
                    continue;
                }

                if (q.IsMultiProductTechnicalQuote__c) {
                    continue;
                }

                List<QuoteLineItem> qlisToApprove = new List<QuoteLineItem>();

                // Build Map Quote Id to Qli Map
                for(QuoteLineItem qli : allQlis) {
                    if(!quoteIdToQliMap.containsKey(qli.QuoteId)) {
                        quoteIdToQliMap.put(qli.QuoteId, new Map<Id, QuoteLineItem>());
                    }
                    quoteIdToQliMap.get(qli.QuoteId).put(qli.Id, qli);
                }

                // Filter by current quote id
                List<QuoteLineItem> qlisToProcessByQuoteId = new List<QuoteLineItem>();
                for (QuoteLineItem qli : (List<QuoteLineItem>) (Trigger.isDelete ? Trigger.old : Trigger.new)) {
                    if (qli.QuoteId == q.Id) {
                        qlisToProcessByQuoteId.add(qli);
                    }
                }

                // Commissionable logic
                Set<Id> commisionableQliIds = new Set<Id>();
                for (QuoteLineItem qli : qlisToProcessByQuoteId) {
                    BillingWrappers.QLIPackageInfo qliPackageInfo = BillingWrappers.parseQLIPackageInfo(qli.PackageInfo__c);
                    if (qliPackageInfo != null && qliPackageInfo.isCommissionable()) {
                        commisionableQliIds.add(qli.Id);
                    }
                }

                Boolean isCommissionable = !commisionableQliIds.isEmpty();

                // Main logic
                for (QuoteLineItem qli : qlisToProcessByQuoteId) {
                    if (Product2Helper.isTaxes(qli)) {
                        continue;
                    }
                    if (AccountHelper.isElaService(qli.Quote.Account) && UserCustomSettingHelper.getELALicenses().contains(qli.Product_Lic_Id__c)) {
                        continue;
                    }
                    if (commisionableQliIds.contains(qli.Id)) {
                        continue;
                    }
                    if (isCommissionable && qli.Product_Lic_Id__c == Product2Helper.MOBILE_USER_ELEMENT_ID) {
                        continue;
                    }

                    qlisToApprove.add(
                        quoteIdToQliMap.get(qli.QuoteId).get(qli.Id)
                    );
                }

                quotesForUpdate.add(BillingApprovals.approveDiscounts(qlisToApprove, q, discounts, proservQlis));
            }

            Set<Id> oppIdSet = new Set<Id>();

            quoteIdSet = new Set<Id>();
            for (Quote qt : quotesForUpdate) {
                Quote fullQt = quotesMapStatic.get(qt.Id);
                if(QuoteHelper.APPROVAL_STATUSES_NOT_REQUIRED.contains(qt.Approved_Status__c)
                    && qt.RecordTypeId == QuoteHelper.RT_ID_BILLING
                    && fullQt != null
                    && fullQt.FreeShippingTerms__c != QuoteHelper.FREESHIPPING) {
                    // Bypass finding quote approvers if Approved_Status__c is Not Required
                    needToHandle = false;
                }

                quoteIdSet.add(qt.Id);

                if(quotesMapStatic.containsKey(qt.Id)) {
                    Id oppId = (Id) quotesMapStatic.get(qt.Id).get('OpportunityId');
                    oppIdSet.add(oppId);
                }
            }

            // do not bypass finding quote approvers if opportuinty has Quote with RecordType "Contact Center Quote"
            if(!oppIdSet.isEmpty() && !needToHandle) {
                for(Quote qt : [SELECT Id, RecordTypeId from Quote where OpportunityId in :oppIdSet]) {
                    if(qt.RecordTypeId == QuoteHelper.RT_ID_CC && quoteIdSet.contains(qt.Id)) {
                        needToHandle = true;
                        break;
                    }
                }
            }

            if(needToHandle) {
                quotesToUpdate = QuoteApprovals.handleBillingQuotes(oppIdSet, qliIdToDeleteSet);
            } else {
                Triggers.switchOff();
                update quotesForUpdate;
                Triggers.switchOn();
            }

            if(!quotesToUpdate.isEmpty() || !QuoteApprovals.quotesExcludedForDQGoa.isEmpty()) {
                if (!QuoteApprovals.quotesExcludedForDQGoa.isEmpty()) {
                    Set<Id> addedQuoteIds = new Set<Id>();
                    for (Quote qt : QuoteApprovals.quotesExcludedForDQGoa) {
                        if (!addedQuoteIds.contains(qt.Id)) {
                            quotesToUpdate.add(
                                getQuoteWithApproversFields(qt)
                            );
                            addedQuoteIds.add(qt.Id);
                        }
                    }
                }
                quotesToUpdate = QuoteLineItemHelper.setTotals(quotesToUpdate, QuoteApprovals.qliList);

                Boolean isUpdateRequired = false;

                if (DQGoa.isDQGoaEnabled() && (isRequirePrimaryQuoteApproval || isApprovedPrimaryQuoteApproval) && !quotesToUpdate.isEmpty()) {
                    Quote primaryQuote = QuoteApprovals.primaryQuote != null && (quotesToUpdate.get(0).Id != QuoteApprovals.primaryQuote.Id) ? QuoteApprovals.primaryQuote : quotesToUpdate.get(0);

                    if (isRequirePrimaryQuoteApproval && primaryQuote.Approved_Status__c != QuoteHelper.APPROVAL_STATUS_REQUIRED) {
                        primaryQuote.Approved_Status__c = QuoteHelper.APPROVAL_STATUS_REQUIRED;
                        isUpdateRequired = true;
                    } else if (isApprovedPrimaryQuoteApproval) {

                        List<DQGoa.ApproverData> lstApprovers = DQGoa.getApproversForQuote(primaryQuote.Id);
                        if (!lstApprovers.isEmpty() && primaryQuote.Approved_Status__c != QuoteHelper.APPROVAL_STATUS_REQUIRED) {
                            primaryQuote.Approved_Status__c = QuoteHelper.APPROVAL_STATUS_REQUIRED;
                            isUpdateRequired = true;
                        } else if (lstApprovers.isEmpty() && primaryQuote.Approved_Status__c != QuoteHelper.APPROVAL_STATUS_APPROVED && primaryQuote.Approved_Status__c != QuoteHelper.APPROVAL_STATUS_NOT_REQUIRED) {
                            primaryQuote.Approved_Status__c = QuoteHelper.APPROVAL_STATUS_NOT_REQUIRED;
                            isUpdateRequired = true;
                        }

                    }

                    if (isUpdateRequired && !quotesToUpdate.isEmpty() && quotesToUpdate.get(0).Id != primaryQuote.Id) {
                        quotesToUpdate.add(new Quote(Id = primaryQuote.Id, Approved_Status__c=primaryQuote.Approved_Status__c));
                    }
                }
                Triggers.switchOff();
                update quotesToUpdate;
                Triggers.switchOn();
            }
        }

        private Boolean hasPricingOrDiscountChanged(QuoteLineItem newQli, QuoteLineItem oldQli) {
            // Fields to compare for pricing or discount changes
            List<String> fields = new List<String>{
                'Discount_type__c',
                'Discount_number__c',
                'Discount',
                'Quantity',
                'NewQuantity__c',
                'Promotion__c'
            };
            for (String fieldName : fields) {
                if (newQli.get(fieldName) != oldQli.get(fieldName)) {
                    return true;
                }
            }
            return false;
        }

        @TestVisible
        private Quote getQuoteWithApproversFields(Quote qt) {
            if (qt == null) {
                return qt;
            }
            Quote result = new Quote(
                Id = qt.Id,
                Level_1_Approver__c = qt.Level_1_Approver__c,
                Level_2_Approver__c = qt.Level_2_Approver__c,
                Level_3_Approver__c = qt.Level_3_Approver__c,
                Level_4_Approver__c = qt.Level_4_Approver__c,
                Level_5_Approver__c = qt.Level_5_Approver__c
            );
            return result;
        }
    }

    public class UpdateSortOrder extends Triggers.TriggerHandlerBase {

        override public void handle() {

            Set<Id> product2Ids = new Set<Id>();
            if (Trigger.isInsert) {
                for (QuoteLineItem qli : (List<QuoteLineItem>)Trigger.new) {
                    product2Ids.add(qli.Product2Id);
                }
            } else if (Trigger.isUpdate) {
                for (QuoteLineItem qli : (List<QuoteLineItem>)Trigger.new) {
                    QuoteLineItem oldQli = (QuoteLineItem)Trigger.oldMap.get(qli.Id);
                    if (qli.Product2Id != oldQli.Product2Id || qli.Sort_Order__c != oldQli.Sort_Order__c ||
                            qli.Product_Family__c != oldQli.Product_Family__c) {
                        product2Ids.add(qli.Product2Id);
                    }
                }
            }

            if (product2Ids.isEmpty()) {
                return;
            }

            List<Product2> products = new Product2Selector()
                .selectProductsForSortOrderUpdates(product2Ids)
                .executeQuery();
            Map<Id, Product2> product2Map = new Map<Id, Product2>(products);

            for (QuoteLineItem qli : (List<QuoteLineItem>)Trigger.new) {
                if (!product2Map.containsKey(qli.Product2Id)) {
                    continue;
                }
                Product2 product2 = product2Map.get(qli.Product2Id);
                if ('DigitalLine Unlimited'.equalsIgnoreCase(product2.Name) && qli.Sort_Order__c == 22) {
                    qli.Sort_Order__c = 19.4;
                }
                if ('Compliance and Administrative Cost Recovery Fee'.equalsIgnoreCase(product2.Name) && qli.Sort_Order__c == 20) {
                    qli.Sort_Order__c = 22;
                }
                if ('Taxes'.equalsIgnoreCase(product2.Name)) {
                    qli.Sort_Order__c = 80000;
                }

            }
        }
    }

    //Method to insert fees within service product. Do not use any SOQL queries inside.
    @TestVisible
    public static List<QuoteLineItem> prepareQuoteLineItemsFeesOnInsert(List<QuoteLineItem> featureDependentLineItemsToInsert,
            Map<Id, List<PriceBookEntry>> priceBookEntrys,
            Map<String, DefaultLineItemsTriggerHandler.DepandantFee> dependantItemsHelper){

        Map<String,List<PriceBookEntry>> featureDependentEntrys = new Map<String, List<PriceBookEntry>>();

        //Understand the fees pricebook entrys
        for(Id quoteId : priceBookEntrys.keySet()){
            for(PriceBookEntry pbe : priceBookEntrys.get(quoteId)){
                if(pbe.Product2.Family == 'Fee' && pbe.Product2.Dependent_on_Feature__c != null){
                    String key = pbe.Pricebook2Id + String.ValueOf(pbe.Product2.Dependent_on_Feature__c);
                    if(!featureDependentEntrys.containsKey(key)){
                        featureDependentEntrys.put(key, new List<PriceBookEntry>());
                    }
                    featureDependentEntrys.get(key).add(pbe);
                }
            }
        }

        //Create the fees from service items
        for(Id quoteId : priceBookEntrys.keySet()){
            for(PriceBookEntry pbe : priceBookEntrys.get(quoteId)){
                if((pbe.Product2.Family == 'Tier' || pbe.Product2.Family == 'Service') && pbe.Product2.Feature__c != null){
                    String key = pbe.Pricebook2Id + String.ValueOf(pbe.Product2.Feature__c);
                    if(featureDependentEntrys.containsKey(key) && dependantItemsHelper.containsKey(key)){
                        for(PriceBookEntry depPbe : featureDependentEntrys.get(key)){
                            QuoteLineItem newQli = new QuoteLineItem();
                            newQli.ServiceDate = date.today();
                            newQli.Description = depPbe.Product2.Description;
                            newQli.UnitPrice = depPbe.UnitPrice;
                            newQli.Quantity = dependantItemsHelper.get(key).quantity;
                            newQli.QuoteId = dependantItemsHelper.get(key).quoteId;
                            newQli.PriceBookEntryId = depPbe.Id;
                            newQli.Product2Id = depPbe.Product2Id;
                            featureDependentLineItemsToInsert.add(newQli);
                        }
                    }
                }
            }
        }

        return featureDependentLineItemsToInsert;

    }

    public class RemoveAreCodeLineItems extends Triggers.TriggerHandlerBase {
        override public void handle() {

            List<Area_Code_Line_Item__c> acliToDelete = [
                SELECT Id FROM Area_Code_Line_Item__c
                WHERE Quote_Line_Item__c IN :trigger.old
                AND Quote_Line_Item__r.IsMultiProductTechnicalQLI__c = false
                ];

            if (acliToDelete.size() > 0) {
                delete acliToDelete;
            }

        }
    }

    public class RemoveAssignmentLineItems extends Triggers.TriggerHandlerBase {
        override public void handle() {

            delete (List<AssignmentLineItem__c>) new AssignmentLineItemSelector()
                .selectALIForRemove( new List<Object> { Trigger.old } )
                .executeQuery();
        }
    }

    public class RemoveCustomAddressAssignments extends Triggers.TriggerHandlerBase {
        override public void handle() {

            delete (List<CustomAddressAssignments__c>) new CustomAddressAssignmentsSelector()
                .selectCAAForShipping( new List<Object> { Trigger.old } )
                .executeQuery();
        }
    }

    public class SetChargeTerms extends Triggers.TriggerHandlerBase {
        public String DURATION_ERROR = 'Package Info field doesn\'t contain duration';
        override public void handle() {
            Set<Id> productsIdSet = new Set<Id>();
            for (QuoteLineItem qli : (QuoteLineItem[])Trigger.new) {
                productsIdSet.add(qli.Product2Id);
            }

            if(!QuoteLineItemTriggerHelper.productsMapStatic.keyset().containsAll(productsIdSet)){
                List<Product2> products = new Product2Selector()
                    .selectProductsForQLITrigger(productsIdSet)
                    .executeQuery();
                Map<Id, Product2> productsMap = new Map<Id, Product2>(products);
                QuoteLineItemTriggerHelper.productsMapStatic.putAll(productsMap);
            }
            for (QuoteLineItem qli : (QuoteLineItem[])Trigger.new) {
                if (QuoteHelper.isNGBSQuote(qli)) {
                    setChargeTermForValidNGBSLineItem(qli);
                } else if (String.isNotBlank(qli.Product2Id)) {
                    qli.ChargeTerm__c = QuoteLineItemTriggerHelper.productsMapStatic.get(qli.Product2Id).Charge_Term__c;
                }
            }
        }

        private void setChargeTermForValidNGBSLineItem(QuoteLineItem qli) {
            if (String.isBlank(qli.PackageInfo__c)) {
                return;
            }
            BillingWrappers.QLIPackageInfo packageInfo = BillingWrappers.parseQLIPackageInfo(qli.PackageInfo__c);
            if (!Test.isRunningTest() && String.isBlank(packageInfo.duration)) {
                qli.addError(this.DURATION_ERROR);
            } else {
                qli.ChargeTerm__c = packageInfo.duration;
            }
        }
    }

    public static Map<Id, Area_Codes__c> areaCodesMapStatic = new Map<Id, Area_Codes__c>();
    public static Map<Id, Pricebook2> pricebookMapStatic = new Map<Id, Pricebook2>();

    public class CheckNumberOfVanitySteps {

        public List<Quote> handleInvalidNumberSetups(List<QuoteLineItem> qlis, Map<Id, List<QuoteLineItem>> quoteIdToQliListMap) {

            Set<Id> quoteIdsToProcess = new Set<Id>();
            List<QuoteLineItem> qlisToInsert = new List<QuoteLineItem>();
            List<QuoteLineItem> qlisToUpdate = new List<QuoteLineItem>();
            Set<Id> qliIdsToDelete = new Set<Id>();

            for(QuoteLineItem item : qlis) {

                Quote currentQuote = quotesMapStatic.get( item.QuoteId );

                if( (currentQuote.Upsell_status__c == 'New') &&
                        (currentQuote.PriceBook2.Service__c == 'Office') ) {

                    quoteIdsToProcess.add(item.QuoteId);

                    if( Trigger.isDelete ) {
                        qliIdsToDelete.add( item.Id );
                    }else if( Trigger.isInsert ) {
                        qlisToInsert.add( item );
                    }else if( Trigger.isUpdate ) {
                        qlisToUpdate.add( item );
                    }
                }
            }

            if(quoteIdsToProcess.size() > 0) {

                if(quoteIdToQliListMap == null) {
                    quoteIdToQliListMap = buildQuoteIdToQliListMap(quoteIdsToProcess, qlisToInsert, qlisToUpdate, qliIdsToDelete);
                }

                Boolean addMissingProductsToStaticMap = false;

                Map<Id, Product2> productsMap = buildProductsMap(quoteIdToQliListMap, addMissingProductsToStaticMap);


                Map<Id, List<Area_Code_Line_Item__c>> qliIdToAclisListMap = buildQliIdToAreaCodeLineItemsListMap(quoteIdToQliListMap);


                Map<Id, String> quoteIdToBrandNameMap = new Map<Id, String>();

                Set<Id> areaCodeIdSet = new Set<Id>();

                for(Id currentQuoteId : quoteIdsToProcess) {
                    Quote currentQuote = quotesMapStatic.get(currentQuoteId);
                    quoteIdToBrandNameMap.put(currentQuoteId, currentQuote.Pricebook2.Brand__r.Name);

                    if(currentQuote.AreaCode__c != null) {
                        areaCodeIdSet.add(currentQuote.AreaCode__c);
                    }
                    if(currentQuote.FaxAreaCode__c != null) {
                        areaCodeIdSet.add(currentQuote.FaxAreaCode__c);
                    }
                }

                Map<Id, Area_Codes__c> areaCodesMap;

                if(areaCodeIdSet.size() > 0) {

                    if(areaCodesMapStatic.keySet().containsAll(areaCodeIdSet)) {
                        areaCodesMap = new Map<Id, Area_Codes__c>();
                        for(Id areaCodeId : areaCodeIdSet) {
                            areaCodesMap.put(areaCodeId, areaCodesMapStatic.get(areaCodeId));
                        }
                    }else{
                        areaCodesMap = new Map<Id, Area_Codes__c>([select Id, Name, Type__c from Area_Codes__c where Id in :areaCodeIdSet]);
                        areaCodesMapStatic.putAll(areaCodesMap);
                    }
                }else{
                    areaCodesMap = new Map<Id, Area_Codes__c>();
                }


                List<Quote> quoteToUpdateList = setInvalidNumberSetups(quotesMapStatic, areaCodesMap, quoteIdToBrandNameMap, quoteIdToQliListMap, productsMap, qliIdToAclisListMap);

                return quoteToUpdateList;
            }else{
                return new List<Quote>();
            }

        }

        public List<Quote> checkInvalidNumberSetups(List<Quote> quotestToCheck, Set<Id> priceBook2IdSet) {

            Map<Id, Pricebook2> pricebook2Map;

            if(!pricebookMapStatic.keySet().containsAll(priceBook2IdSet)) {
                pricebook2Map = new Map<Id, Pricebook2>([select Id, Service__c, Brand__r.Name, Plan__c from Pricebook2 where Id in :priceBook2IdSet]);

                pricebookMapStatic.putAll(pricebook2Map);
            }else{
                pricebook2Map = new Map<Id, Pricebook2>();
                for(Id item : priceBook2IdSet) {
                    pricebook2Map.put(item, pricebookMapStatic.get(item));
                }
            }

            Set<Id> areaCodeIdSet = new Set<Id>();

            Map<Id, String> quoteIdToBrandNameMap = new Map<Id, String>();

            Map<Id, Quote> quoteToProcessMap = new Map<Id, Quote>();

            for(Quote item : quotestToCheck) {
                Pricebook2 pb = pricebook2Map.get(item.PriceBook2Id);
                if(pb != null && pb.Service__c == 'Office') {
                    quoteToProcessMap.put(item.Id, item);
                    quoteIdToBrandNameMap.put(item.Id, pb.Brand__r.Name);

                    if(item.AreaCode__c != null) {
                        areaCodeIdSet.add(item.AreaCode__c);
                    }

                    if(item.FaxAreaCode__c != null) {
                        areaCodeIdSet.add(item.FaxAreaCode__c);
                    }
                }
            }


            List<Quote> updatedQuotesList = new List<Quote>();

            if(quoteToProcessMap.size() > 0) {

                Map<Id, Area_Codes__c> areaCodesMap;
                if(areaCodeIdSet.size() > 0) {

                    if(areaCodesMapStatic.keySet().containsAll(areaCodeIdSet)) {
                        areaCodesMap = new Map<Id, Area_Codes__c>();
                        for(Id areaCodeId : areaCodeIdSet) {
                            areaCodesMap.put(areaCodeId, areaCodesMapStatic.get(areaCodeId));
                        }
                    }else{
                        areaCodesMap = new Map<Id, Area_Codes__c>([select Id, Name, Type__c from Area_Codes__c where Id in :areaCodeIdSet]);
                        areaCodesMapStatic.putAll(areaCodesMap);
                    }
                }else{
                    areaCodesMap = new Map<Id, Area_Codes__c>();
                }


                Map<Id, List<QuoteLineItem>> quoteIdToQliListMap = buildQuoteIdToQliListMap(quoteToProcessMap.keySet(), null, null, null);


                Map<Id, Product2> productsMap = buildProductsMap(quoteIdToQliListMap, false);


                Map<Id, List<Area_Code_Line_Item__c>> qliIdToAclisListMap = buildQliIdToAreaCodeLineItemsListMap(quoteIdToQliListMap);


                updatedQuotesList = setInvalidNumberSetups(quoteToProcessMap, areaCodesMap, quoteIdToBrandNameMap, quoteIdToQliListMap, productsMap, qliIdToAclisListMap);
            }

            return updatedQuotesList;
        }


        private Set<String> tollFreeProductFamilySet = new Set<string>{
                'Discounted Phones',
                'Rental Phones',
                'Refurbished Phones',
                'Common Phones'
        };


        private List<Quote> setInvalidNumberSetups(
                Map<Id, Quote> quotesMap,
                Map<Id, Area_Codes__c> areaCodeMap,
                Map<Id, String> quoteIdToBrandNameMap,
                Map<Id, List<QuoteLineItem>> quoteIdToQliListMap,
                Map<Id, Product2> productsMap,
                Map<Id, List<Area_Code_Line_Item__c>> qliIdToAclisListMap
        ) {

            List<Quote> quoteToUpdateList = new List<Quote>();

            for(Id quoteId : quoteIdToQliListMap.keySet()) {

                Quote currentQuote = quotesMap.get(quoteId);

                String mainAreaCodeType = '';

                if(currentQuote.AreaCode__c != null && areaCodeMap.containsKey(currentQuote.AreaCode__c)) {
                    Area_Codes__c mainAreaCode = areaCodeMap.get(currentQuote.AreaCode__c);
                    mainAreaCodeType = mainAreaCode.Type__c;
                }


                String quoteBrandName = quoteIdToBrandNameMap.get(quoteId);

                List<QuoteLineItem> qlisForCurrentQuote = quoteIdToQliListMap.get(quoteId);


                Integer countOfTrueVanityNumber = 0;

                if( currentQuote.Main_Vanity_Number__c && currentQuote.Fax_Vanity_Number__c ) {
                    countOfTrueVanityNumber = 2;
                }else if( currentQuote.Main_Vanity_Number__c || currentQuote.Fax_Vanity_Number__c ) {
                    countOfTrueVanityNumber = 1;
                }else{
                    countOfTrueVanityNumber = 0;
                }

                Integer qliQuantityForFeature5 = 0;
                Integer qliQuantityForFeature4 = 0;
                Integer qliQuantityForFeature42 = 0;
                Integer qliQuantityForFeature43 = 0;
                Integer qliQuantityForFeature46 = 0;

                Integer acliQuantitySumm = 0;

                for(QuoteLineItem item : qlisForCurrentQuote) {

                    Product2 currentProduct = productsMap.get(item.Product2Id);

                    if(currentProduct.Feature__c == 5) {
                        qliQuantityForFeature5 += (Integer) item.Quantity;
                    }else if(currentProduct.Feature__c == 4) {
                        qliQuantityForFeature4 += (Integer) item.Quantity;
                    }else if(currentProduct.Feature__c == 42) {
                        qliQuantityForFeature42 += (Integer) item.Quantity;
                    }else if(currentProduct.Feature__c == 43) {
                        qliQuantityForFeature43 += (Integer) item.Quantity;
                    }else if(currentProduct.Feature__c == 46) {
                        qliQuantityForFeature46 += (Integer) item.Quantity;
                    }

                    if(item.Id != null) {

                        List<Area_Code_Line_Item__c> currentAclisList = qliIdToAclisListMap.get(item.id);

                        if(currentAclisList != null){

                            for(Area_Code_Line_Item__c currentAcli : currentAclisList){

                                if(currentAcli != null && currentAcli.Quote_Line_Item__c != null) {

                                    if( (currentAcli.Quote_Line_Item__r.Product2.Feature__c == 2) && (currentAcli.Area_Code__r.Name == '800') ) {
                                        acliQuantitySumm += (Integer) currentAcli.Quantity__c;
                                    }
                                }
                            }
                        }
                    }
                }

                Boolean productExist = false;
                Boolean acliExistForMainAreaCode = false;
                Boolean isProductWithoutAreaCodeExist = false;

                // set Required_Area_Codes_are_empty__c
                for(QuoteLineItem item : qlisForCurrentQuote) {

                    Product2 currentProduct = productsMap.get(item.Product2Id);

                    Integer numberOfAclis = qliIdToAclisListMap.get(item.Id).size();

                    if('Toll-Free'.equalsIgnoreCase(mainAreaCodeType) &&
                            (tollFreeProductFamilySet.contains(currentProduct.Family) || (currentProduct.Feature__c == 2 || currentProduct.Feature__c == 3)) ) {

                        productExist = true;

                        if(item.Id != null) {

                            if(numberOfAclis > 0) {
                                acliExistForMainAreaCode = true;
                            }
                        }

                    }else if('Local'.equalsIgnoreCase(mainAreaCodeType) && currentProduct.Feature__c == 2) {

                        productExist = true;

                        if(item.Id != null) {

                            if(numberOfAclis > 0) {
                                acliExistForMainAreaCode = true;
                            }
                        }
                    }

                    isProductWithoutAreaCodeExist = !(productExist && acliExistForMainAreaCode) && (productExist == true);

                    if(isProductWithoutAreaCodeExist) {
                        break;
                    }else{
                        productExist = false;
                        acliExistForMainAreaCode = false;
                    }
                }

                Integer countOf_800_AreaCode_WithFalseVanity = determineCountOf_800_AreaCode_WithFalseVanity(currentQuote, areaCodeMap);

                Boolean brandNameMet = (quoteBrandName == 'RingCentral' || quoteBrandName == 'RingCentral Canada');

                Boolean computed_InvalidNumberOfVanitySetups = (countOfTrueVanityNumber != qliQuantityForFeature5);
                Boolean computed_InvalidNumberOf800Setups = (brandNameMet && (qliQuantityForFeature4 != (countOf_800_AreaCode_WithFalseVanity + acliQuantitySumm)));
                Boolean computed_InvalidNumberOfIntTFSetups = (
                    qliQuantityForFeature42 != (qliQuantityForFeature43 + qliQuantityForFeature46)
                );

                Boolean quoteIsUpdated = false;

                if(currentQuote.Invalid_Number_of_Vanity_Setups__c != computed_InvalidNumberOfVanitySetups) {
                    currentQuote.Invalid_Number_of_Vanity_Setups__c = computed_InvalidNumberOfVanitySetups;
                    quoteIsUpdated = true;
                }

                if(currentQuote.Invalid_Number_of_800_Setups__c != computed_InvalidNumberOf800Setups) {
                    currentQuote.Invalid_Number_of_800_Setups__c = computed_InvalidNumberOf800Setups;
                    quoteIsUpdated = true;
                }

                if(currentQuote.Invalid_Number_of_Int_TF_Setups__c != computed_InvalidNumberOfIntTFSetups) {
                    currentQuote.Invalid_Number_of_Int_TF_Setups__c = computed_InvalidNumberOfIntTFSetups;
                    quoteIsUpdated = true;
                }

                Boolean computed_Required_Area_Codes_are_empty = isProductWithoutAreaCodeExist;

                if(currentQuote.Required_Area_Codes_are_empty__c != computed_Required_Area_Codes_are_empty) {
                    currentQuote.Required_Area_Codes_are_empty__c = computed_Required_Area_Codes_are_empty;
                    quoteIsUpdated = true;
                }

                if(quoteIsUpdated) {
                    quoteToUpdateList.add(currentQuote);
                }
            }

            return quoteToUpdateList;
        }


        private Integer determineCountOf_800_AreaCode_WithFalseVanity(Quote currentQuote, Map<Id, Area_Codes__c> areaCodeMap) {

            Integer result = 0;

            Area_Codes__c mainAreaCode = areaCodeMap.containsKey(currentQuote.AreaCode__c)
                                         ? areaCodeMap.get(currentQuote.AreaCode__c)
                                         : null;
            Area_Codes__c faxAreaCode = areaCodeMap.containsKey(currentQuote.FaxAreaCode__c)
                                         ? areaCodeMap.get(currentQuote.FaxAreaCode__c)
                                         : null;

            if(!currentQuote.Main_Vanity_Number__c
                && ( currentQuote.AreaCode__c != null
                     && mainAreaCode != null
                     && '800'.equalsIgnoreCase(mainAreaCode.Name)
                   )
              ) {
                result += 1;
            }

            if(!currentQuote.Fax_Vanity_Number__c
                && ( currentQuote.FaxAreaCode__c != null
                     && faxAreaCode != null
                     && '800'.equalsIgnoreCase(faxAreaCode.Name)
                   )
              ) {
                result += 1;
            }

            return result;
        }


        private Map<Id, List<QuoteLineItem>> buildQuoteIdToQliListMap(
                Set<Id> quoteIdSet,
                List<QuoteLineItem> qlisToInsert,
                List<QuoteLineItem> qlisToUpdate,
                Set<Id> qliIdsToDelete
        ) {
            // TODO: add checking for null for quoteIdSet(throw exception if it is null??)

            Set<Id> contextQLIIdSet = new Set<Id>();

            if(qlisToUpdate != null) {
                for(QuoteLineItem item : qlisToUpdate) {
                    contextQLIIdSet.add(item.Id);
                }
            }

            if(qliIdsToDelete != null) {
                if(qliIdsToDelete.size() > 0) {
                    contextQLIIdSet.addAll(qliIdsToDelete);
                }
            }

            List<QuoteLineItem> qliList = [
                    select Id, Quantity, QuoteId, Product2.Feature__c, Product2.Sub_Category__c,
                    Zero_Quantity__c
                    from QuoteLineItem
                    where QuoteId in :quoteIdSet
                    and Id not in :contextQLIIdSet
            ];


            Map<Id, List<QuoteLineItem>> quoteIdToQliListMap = new Map<Id, List<QuoteLineItem>>();

            for(Id quoteId : quoteIdSet) {
                if(quoteIdToQliListMap.get(quoteId) == null) {
                    quoteIdToQliListMap.put(quoteId, new List<QuoteLineItem>());
                }
            }


            if(qlisToInsert != null) {
                qliList.addAll(qlisToInsert);
            }

            if(qlisToUpdate != null) {
                qliList.addAll(qlisToUpdate);
            }

            for(QuoteLineItem item : qliList) {

                if(quoteIdToQliListMap.get(item.QuoteId) == null) {
                    quoteIdToQliListMap.put(item.QuoteId, new List<QuoteLineItem>());
                }
                quoteIdToQliListMap.get(item.QuoteId).add(item);
            }

            return quoteIdToQliListMap;
        }

        private Map<Id, Product2> buildProductsMap(Map<Id, List<QuoteLineItem>> quoteIdToQliListMap, Boolean addMissingProductsToStaticMap) {

            Set<Id> productsIdSet = new Set<Id>();

            for(Id currentQuoteId : quoteIdToQliListMap.keySet()) {

                List<QuoteLineItem> qliList = quoteIdToQliListMap.get(currentQuoteId);

                for(QuoteLineItem item : qliList) {
                    productsIdSet.add(item.Product2Id);
                }
            }

            Map<Id, Product2> productsMap;

            if(productsMapStatic.keySet().containsAll(productsIdSet)) {

                productsMap = new Map<Id, Product2>();

                for(Id prodId : productsIdSet) {
                    productsMap.put( prodId, productsMapStatic.get(prodId) );
                }
            }else {
                List<Product2> products = new Product2Selector()
                    .selectProductsForQLITrigger(productsIdSet)
                    .executeQuery();
                productsMap = new Map<Id, Product2>(products);

                if(addMissingProductsToStaticMap) {
                    productsMapStatic.putAll( productsMap );
                }
            }

            return productsMap;
        }


        private Map<Id, List<Area_Code_Line_Item__c>> buildQliIdToAreaCodeLineItemsListMap(Map<Id, List<QuoteLineItem>> quoteIdToQliListMap) {
            if (qliIdToAreaCodeLineItemsListMap == null) {
                qliIdToAreaCodeLineItemsListMap = new Map<Id, List<Area_Code_Line_Item__c>>();
            }
            Set<Id> qliIdSetToQuery = new Set<Id>();

            for(Id currentQuoteId : quoteIdToQliListMap.keySet()) {

                List<QuoteLineItem> qliList = quoteIdToQliListMap.get(currentQuoteId);

                for(QuoteLineItem item : qliList) {
                    if(item.Id != null && !qliIdToAreaCodeLineItemsListMap.containsKey(item.Id)) {
                        qliIdSetToQuery.add(item.Id);
                        qliIdToAreaCodeLineItemsListMap.put(item.Id, new List<Area_Code_Line_Item__c>());//to avoid executing SOQL multiple times even if SOQL returned 0 items.
                    }
                }
            }
            if (qliIdSetToQuery.size() < 1) {
                return qliIdToAreaCodeLineItemslistMap;
            }

            List<Area_Code_Line_Item__c> aclis = [SELECT
                    Id, Quantity__c, Quote_Line_Item__c,
                    Quote_Line_Item__r.Product2.Feature__c,
                    Area_Code__c, Area_Code__r.Name
            FROM Area_Code_Line_Item__c
            WHERE Quote_Line_Item__c IN :qliIdSetToQuery];

            for(Area_Code_Line_Item__c item : aclis) {
                if(qliIdToAreaCodeLineItemsListMap.get(item.Quote_Line_Item__c) == null){
                    qliIdToAreaCodeLineItemsListMap.put(item.Quote_Line_Item__c, new List<Area_Code_Line_Item__c>());
                }
                qliIdToAreaCodeLineItemsListMap.get(item.Quote_Line_Item__c).add(item);
            }

            return qliIdToAreaCodeLineItemsListMap;
        }
    }

    public class PopulateProductsMap extends Triggers.TriggerHandlerBase {
        override public void handle() {
            Set<Id> productIds = new Set<Id>();
            for (Map<Id, QuoteLineItem> prodIdToQLIMap: quoteIdToProdIdToQLIMap.values()) {
                productIds.addAll(prodIdToQLIMap.keySet()) ;
            }

            if (!productsMapStatic.keySet().containsAll(productIds)) {
                List<Product2> products = new Product2Selector()
                    .selectProductsForQLITrigger(productIds)
                    .executeQuery();

                productsMapStatic = new Map<Id, Product2>(products);
            }
        }
    }

    public class UpdateServiceInfo extends Triggers.TriggerHandlerBase {
        override public void handle() {
            Set<Id> quoteIds = new Set<Id>();
            for (QuoteLineItem qli : (List<QuoteLineItem>) Trigger.new) {
                quoteIds.add(qli.QuoteId);
            }

            QuoteHelper.updateServiceInfo(quoteIds, quotesMapStatic);
        }
    }

}