public with sharing class ApprovalNeededQualifiers {

    public interface IApprovalNeededQualifier {
        Map<Id, Boolean> checkNeedForApproval(List<QuoteLineItem> qliList);
    }

    public class ApprovalNeededChecker {
        List<ApprovalNeededQualifiers.IApprovalNeededQualifier> qualifierList = new List<ApprovalNeededQualifiers.IApprovalNeededQualifier>();

        public void addQualifier(ApprovalNeededQualifiers.IApprovalNeededQualifier qualifier) {
            if(qualifier == null) {
                return;
            }
            this.qualifierList.add(qualifier);
        }

        public Map<Id, Boolean> process(List<QuoteLineItem> qliList) {

            // map with results - qliId => NeedApproval/NotNeedApproval
            // if module said qli need approval, but next module said approval not need - save it as notNeed
            Map<Id, Boolean> resultMap = new Map<Id, Boolean>();

            for(ApprovalNeededQualifiers.IApprovalNeededQualifier q :this.qualifierList) {
                Map<Id, Boolean> isApprovalNeededMap = q.checkNeedForApproval(qliList);

                for(Id qliId :isApprovalNeededMap.keySet()) {
                    Boolean isApprovalNeeded = isApprovalNeededMap.get(qliId);

                    if(resultMap.containsKey(qliId) && !isApprovalNeeded) {
                        resultMap.put(qliId, isApprovalNeeded);
                    }else if(!resultMap.containsKey(qliId)) {
                        resultMap.put(qliId, isApprovalNeeded);
                    }
                }
            }

            return resultMap;
        }
    }

    public class CurrentDiscountsQualifier implements IApprovalNeededQualifier {
        public Map<Id, Boolean> checkNeedForApproval(List<QuoteLineItem> qliList) {

            Map<Id, Boolean> resultMap = checkCurrentDiscountsFromEntitlement(qliList);
            // This method additionally checks moving EES qli from Office to CC service according CC migration flow 
            // when we change CC package from Legacy To Standalone on Migrated Account (AccMigrationFlag__c = 'Migrated') 
            resultMap = checkOfficeEESQliMovedToCC(qliList, resultMap);

            return resultMap;
        }

        // method will determine whether an approval is needed for each qli(Based on related Entitlements__c)
        // will return map where QuoteLineItem.Id => NeedApproval/NotNeedApproval
        private Map<Id, Boolean> checkCurrentDiscountsFromEntitlement(List<QuoteLineItem> qliList) {

            Map<Id, Boolean> resultMap = new Map<Id, Boolean>();

            if(qliList == null || qliList.isEmpty()) {
                return resultMap;
            }

            for(QuoteLineItem qli : qliList) {

                Double qliDiscount = qli.Discount_type__c == QuoteLineItemHelper.DISCOUNT_TYPE_PERCENTAGE
                        ? (Double) NumberHelper.getNumberNullSafe(qli.Discount)
                        : (Double) NumberHelper.getNumberNullSafe(qli.Discount_Value__c);

                /* In case when qli is from NGBS - need to check that packages the same */
                Boolean isCheckPackage = qli.PackageCatalogId__c != null && qli.PackageVersion__c != null;
                Boolean isSamePackage = qli.PackageCatalogId__c == qli.Entitlement__r.PackageCatalogId__c
                                        && qli.PackageVersion__c == qli.Entitlement__r.PackageVersion__c
                                        && qli.ChargeTerm__c == qli.Entitlement__r.ChargeTerm__c;

                if(qli.Entitlement__c == null || isCheckPackage && !isSamePackage) {
                    resultMap.put(qli.Id, qliDiscount > 0);
                    continue;
                }

                if(qli.Discount_type__c == qli.Entitlement__r.Discount_Type__c) {

                    Decimal entlDiscount = (Decimal) NumberHelper.roundCurrency(qli.Entitlement__r.Discount__c, 3);

                    resultMap.put(qli.Id, qliDiscount > entlDiscount);

                }else{

                    if(qli.Entitlement__r.Discount_Type__c == QuoteLineItemHelper.DISCOUNT_TYPE_PERCENTAGE) {

                        resultMap.put(
                                qli.Id,
                                qli.Discount > (Double) NumberHelper.getNumberNullSafe(qli.Entitlement__r.Discount__c)
                        );

                    }else if(qli.Entitlement__r.Discount_Type__c == QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY) {

                        Decimal entlDiscountValue = (Double) NumberHelper.getNumberNullSafe(
                                                                            qli.Entitlement__r.Discount__c);
                        Decimal entlPriceValue = qli.Entitlement__r.Price__c;

                        Decimal entlPercentageDiscount =  entlDiscountValue / entlPriceValue * 100;

                        resultMap.put(qli.Id, qliDiscount > entlPercentageDiscount);
                    }
                }
            }

            return resultMap;
        }

        @TestVisible
        private Map<Id, Boolean> checkOfficeEESQliMovedToCC(List<QuoteLineItem> qliList, Map<Id, Boolean> qliIdToNeededToApprove) {
            if (qliList == null || qliList.isEmpty()) {
                return qliIdToNeededToApprove;
            }

            QuoteLineItem officeEESQliBilling;
            QuoteLineItem rcccEESQli;

            for (QuoteLineItem qli : qliList) {
                Boolean isOfficeEESQliBilling = QuoteLineItemHelper.EES_CC_LICENSES.contains(qli.Product_Lic_Id__c) 
                    && qli.Entitlement__r != null
                    && qli.ServiceName__c == QuoteHelper.NGBS_OFFICE_PRODUCT;

                if (isOfficeEESQliBilling) {
                    officeEESQliBilling = qli;
                }
                Boolean isCCEESQli = QuoteLineItemHelper.RCCC_EES_PRODUCT_CATALOG_ID.contains(qli.Product_Lic_Id__c) 
                    && qli.ServiceName__c == QuoteHelper.NGBS_RCCC_PRODUCT;

                if (isCCEESQli) {
                    rcccEESQli = qli;
                }
            }

            Boolean isChangeFromCCLegacyToStandaloneFlow = QuoteLineItemHelper.isChangePackageFromCCLegacyToStandalone(qliList)
                && rcccEESQli != null && officeEESQliBilling != null
                && officeEESQliBilling.Entitlement__r.Discount__c == rcccEESQli.Discount_number__c;

            if (isChangeFromCCLegacyToStandaloneFlow) {
                qliIdToNeededToApprove.put(rcccEESQli.Id, false);
            }

            return qliIdToNeededToApprove;
        }
    }

    public class ProServCurrentDiscountsQualifier implements IApprovalNeededQualifier {

        // method will determine whether an approval is needed for each qli(Based on related Asset)
        // will return map where QuoteLineItem.Id => NeedApproval/NotNeedApproval
        public Map<Id, Boolean> checkNeedForApproval(List<QuoteLineItem> qliList) {

            Map<Id, Boolean> resultMap = new Map<Id, Boolean>();

            if(qliList == null || qliList.isEmpty()) {
                return resultMap;
            }

            // process only ProServ or CCProServ quotes
            List<QuoteLineItem> qliToProcess = filterQLIToProcess(qliList);

            if(qliToProcess == null || qliToProcess.isEmpty()) {
                return resultMap;
            }

            for(QuoteLineItem qli : qliToProcess) {

                Double qliDiscount = qli.Discount_type__c == QuoteLineItemHelper.DISCOUNT_TYPE_PERCENTAGE ?
                        qli.Discount == null ? 0 : qli.Discount
                        : qli.Discount_Value__c == null ? 0 : qli.Discount_Value__c;

                if(qli.Asset__c == null) {
                    resultMap.put(qli.Id, qliDiscount > 0);
                    continue;
                }

                if(qli.Discount_type__c == qli.Asset__r.Discount_Type__c) {

                    Double assetDiscount = qli.Asset__r.Discount_Number__c == null ? 0 : qli.Asset__r.Discount_Number__c;

                    resultMap.put(qli.Id, qliDiscount > assetDiscount);

                } else {

                    if(qli.Asset__r.Discount_Type__c == QuoteLineItemHelper.DISCOUNT_TYPE_PERCENTAGE) {

                        resultMap.put(qli.Id, qli.Discount > qli.Asset__r.Discount_Number__c);

                    }else if(qli.Asset__r.Discount_Type__c == QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY) {

                        Decimal assetDiscountValue = qli.Asset__r.Discount_Number__c;
                        Decimal assetPriceValue = qli.Asset__r.Unit_Price__c;

                        Decimal assetPercentageDiscount = assetDiscountValue / assetPriceValue * 100;

                        resultMap.put(qli.Id, qliDiscount > assetPercentageDiscount);
                    }
                }
            }

            return resultMap;
        }

        @TestVisible
        private List<QuoteLineItem> filterQLIToProcess(List<QuoteLineItem> qliList) {

            List<QuoteLineItem> filteredQLI = new List<QuoteLineItem>();

            if(qliList == null || qliList.isEmpty()) {
                return filteredQLI;
            }

            Set<Id> supportedQuoteRecordTypes = new Set<Id>{
                QuoteHelper.RT_ID_PROSERV,
                QuoteHelper.RT_ID_CC_PROSERV
            };

            for(QuoteLineItem qli : qliList) {
                if(supportedQuoteRecordTypes.contains(qli.Quote.RecordTypeId)) {
                    filteredQLI.add(qli);
                }
            }

            return filteredQLI;
        }
    }
    public class ProServOneTimeDiscountQualifier implements IApprovalNeededQualifier {
        
        public Map<Id, Boolean> checkNeedForApproval(List<QuoteLineItem> qliList) {
            Map<Id, Boolean> resultMap = new Map<Id, Boolean>();
            
            if (qliList == null || qliList.isEmpty()) {
                return resultMap;
            }
            
            for (QuoteLineItem qli : qliList) {
                // Check if this is a ProServ One-Time line item
                if (qli.Product2 != null && 
                    qli.Product2.GOA_Group_V3__c != null && 
                    qli.Product2.GOA_Group_V3__c.contains('ProServ One-Time')) {
                    // Only require approval if discount >= 25%
                    resultMap.put(qli.Id, qli.Discount != null && qli.Discount >= 25);
                } else if (qli.Product2.GOA_Group_V3__c != null && (qli.Product2.GOA_Group_V3__c.contains('ProServ_Directs') || qli.Product2.GOA_Group_V3__c.contains('ProServ'))) {
                    resultMap.put(qli.Id, qli.Discount != null && qli.Discount >= 20);
                }
            }
            
            return resultMap;
        }
    }

    public class QuantityChangeMessage {
        @AuraEnabled public String productName;
        @AuraEnabled public String quantity;
        @AuraEnabled public String approvedQuantityRange;
        @AuraEnabled public String additionalMessage;

        public QuantityChangeMessage(String productName, String quantity, String approvedQuantityRange, String additionalMessage) {
            this.productName = productName;
            this.quantity = quantity;
            this.approvedQuantityRange = approvedQuantityRange;
            this.additionalMessage = additionalMessage;
        }
    }

    public static final String DISCOUNT_CHANGED_MESSAGE = 'Discount Changed';
    public static final String QUANTITY_NOT_IN_RANGE_MESSAGE = 'New Quantity not in Approved Range';

    public class QLIQuantityChangeQualifier implements IApprovalNeededQualifier {

        private Map<Id, QuoteLineItem> localOldMap;

        public Map<Id, QuantityChangeMessage> messagesMap = new Map<Id, QuantityChangeMessage>();

        public void setLocalOldMap(Map<Id, QuoteLineItem> oldMapToSet) {
            if(oldMapToSet != null) {
                this.localOldMap = oldMapToSet;
            }
        }

        public QLIQuantityChangeQualifier() {
            if((Trigger.isUpdate != null && Trigger.isUpdate) &&
                Trigger.oldMap != null && (Trigger.oldMap instanceof Map<Id, QuoteLineItem>)) {

                localOldMap = (Map<Id, QuoteLineItem>) Trigger.oldMap;
            }
        }

        public QLIQuantityChangeQualifier(Map<Id, QuoteLineItem> oldMapToSet) {
            setLocalOldMap(oldMapToSet);
        }

        public Map<Id, Boolean> checkNeedForApproval(List<QuoteLineItem> items) {

            Map<Id, Boolean> resultMap = new Map<Id, Boolean>();

            if(items == null || items.isEmpty()) {
                return resultMap;
            }

            if(localOldMap == null) {
                // localOldMap is not instantiated. current class should be run only in QuoteLineItem update context
                return resultMap;
            }

            List<GOA_V2__c> goasList = GOA_V2__c.getAll().values();

            for(QuoteLineItem qli : items) {

                if(!localOldMap.containsKey(qli.Id)) {
                    // QuoteLineItem not changed - not need to validate it
                    resultMap.put(qli.Id, false);
                    continue;
                }

                Double qliDiscount = getQLIDiscount(qli.Discount_type__c, qli.Discount, qli.Discount_Value__c);
                Boolean hasDiscount = qliDiscount > 0;

                QuoteLineItem oldQLI = localOldMap.get(qli.Id);

                Double oldQliDiscount = getQLIDiscount(oldQLI.Discount_type__c, oldQLI.Discount, oldQLI.Discount_Value__c);

                Boolean quantityIsChanged = oldQLI.Quantity != qli.Quantity || oldQLI.NewQuantity__c != qli.NewQuantity__c;
                Boolean discountOrTypeIsChanged = (qliDiscount != oldQliDiscount) || oldQLI.Discount_type__c != qli.Discount_type__c;

                if(discountOrTypeIsChanged) {
                    if(hasDiscount) {
                        resultMap.put(qli.Id, true);
                        messagesMap.put(qli.Id, new QuantityChangeMessage(qli.Product2.Name, '', '', DISCOUNT_CHANGED_MESSAGE));
                        continue;
                    }else{
                        resultMap.put(qli.Id, false);
                    }
                }

                if((qli.Approved_Quantity__c != null && (qli.Approved_Quantity__c != qli.Quantity || qli.Approved_Quantity__c != qli.NewQuantity__c)) && quantityIsChanged) {

                    Double allowedPercentageChange = findAllowedPercentageChange(
                        qli.Product2.GOA_Group_V2__c,
                        (Double) qli.Approved_Quantity__c,
                        goasList);

                    if(allowedPercentageChange == null) {
                        // allowed percentage quantity change not found and we have discount - require approval
                        resultMap.put(qli.Id, true);
                        messagesMap.put(qli.Id, new QuantityChangeMessage(qli.Product2.Name, '', '', DISCOUNT_CHANGED_MESSAGE));
                    }else{

                        Double minR = (qli.Approved_Quantity__c * (100 - allowedPercentageChange)) / 100;
                        Double maxR = (qli.Approved_Quantity__c * (100 + allowedPercentageChange)) / 100;

                        minR = Math.floor(minR);
                        maxR = Math.ceil(maxR);

                        // if QuoteLineItem has Entitlement - get Quantity from QuoteLineItem.NewQuantity__c field,
                        // if it dont - get Quantity from QuoteLineItem.Quantity
                        Decimal resultingQuantity = QuoteLineItemHelper.getResultingQuantity(qli);

                        Boolean chageIsAllowed = (resultingQuantity >= minR) && (resultingQuantity <= maxR);

                        if(chageIsAllowed) {
                            resultMap.put(qli.Id, false);
                        }else{
                            resultMap.put(qli.Id, true);
                            messagesMap.put(
                                qli.Id,
                                new QuantityChangeMessage(
                                    qli.Product2.Name,
                                    ''+Integer.valueOf(resultingQuantity),
                                    Integer.valueOf(minR) + ' - ' + Integer.valueOf(maxR),
                                    QUANTITY_NOT_IN_RANGE_MESSAGE
                                )
                            );
                        }
                    }
                }else{

                    if(qli.Approved_Quantity__c != null) {

                        if(discountOrTypeIsChanged) {
                            resultMap.put(qli.Id, true);
                            messagesMap.put(qli.Id, new QuantityChangeMessage(qli.Product2.Name, '', '', DISCOUNT_CHANGED_MESSAGE));
                        }else{
                            resultMap.put(qli.Id, false);
                        }
                    }
                }
            }

            return resultMap;
        }

        private Double findAllowedPercentageChange(String groupName, Double quantity, List<GOA_V2__c> goasList) {

            if(groupName == null || quantity == null || goasList == null) {
                return null;
            }

            Double result = null;

            for(GOA_V2__c item : goasList) {

                if(item.Group__c == groupName) {

                    QuoteApprovals.Range quantityRange = new QuoteApprovals.Range(item.Quantity_Range__c, '-');

                    if(quantityRange.isInRange(quantity)) {

                        result = item.Allowed_Percentage_Quantity_Change__c;
                        break;
                    }
                }
            }

            return result;
        }

        private Double getQLIDiscount(String discountType, Decimal discount, Decimal discountValue) {
            Double qliDiscount = discountType == QuoteLineItemHelper.DISCOUNT_TYPE_PERCENTAGE ?
                discount == null ? 0 : discount
                : discountValue == null ? 0 : discountValue;

            return qliDiscount;
        }
    }
}