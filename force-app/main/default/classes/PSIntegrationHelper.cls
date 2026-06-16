public with sharing class PSIntegrationHelper {
    
    public static final String STATUS_NEW = 'New';
    public static final String STATUS_BILLED = 'Billed';
    public static final String STATUS_CANCELED = 'Canceled';
    public static final String STATUS_FAILED = 'Failed';

    public static List<PS_Integration__c> buildPSRecords(Map<Id, List<Suborder__c>> orderIDToSuborderListMap, boolean isUpdate) {
        
        Map<Id, Order> orderIdToOrderMap = new Map<Id, Order>( (List<Order>) new OrderSelector()
                .selectOrdersForPSIntegrationManagement(new List<Object> { orderIDToSuborderListMap.keySet() })
                .executeQuery());

        Set<Id> opptyIds = new Set<Id>();
        Set<Id> psProjectIds = new Set<Id>();
        List<PS_Integration__c> psIntegrationsToUpsert = new List<PS_Integration__c>();
        
        for (Order ord : orderIdToOrderMap.values()) {
            if (ord.ProServProject__r?.Opportunity__c != null) {
                psProjectIds.add(ord.ProServProject__r.Id);
                opptyIds.add(ord.ProServProject__r.Opportunity__c);
            }
        }

        if(!opptyIds.isEmpty()) {
            Set<Id> opptyIdsWithBillingPackage = checkAvailableBillingPackage(opptyIds);
            if(!opptyIdsWithBillingPackage.isEmpty()) {

                List<PS_Integration__c> existingPSIntegrations = new PSIntegrationSelector()
                        .selectPSIntegrationsByProjectIds(new List<Object> { psProjectIds , new List<String> { STATUS_NEW,STATUS_FAILED,STATUS_CANCELED } })
                        .executeQuery();

                Map<String, PS_Integration__c> psIntegrationNumberToPSIntegrationMap = new Map<String, PS_Integration__c>();
                for (PS_Integration__c psIntegration : existingPSIntegrations) {
                    if(psIntegration.ProServProject__c != null) {
                        psIntegrationNumberToPSIntegrationMap.put(psIntegration.PSIntegrationNumber__c, psIntegration);
                    }
                }

                for(Id orderId : orderIDToSuborderListMap.keySet()) {

                    Order order = orderIdToOrderMap.get(orderId);
                    if(order.ProServProject__r?.Opportunity__c == null || (order.ProServProject__r?.Opportunity__c != null && !opptyIdsWithBillingPackage.contains(order.ProServProject__r.Opportunity__c))) { continue; }

                    List<Suborder__c> suborders = orderIDToSuborderListMap.get(orderId);
                    for(Suborder__c suborder : suborders) {
        
                        String psIntegrationNumber = buildPSIntegrationNumber(String.valueOf(order?.ProServProject__r?.Quote__r?.QuoteNumber), String.valueOf(suborder.SuborderNumber__c));
                        PS_Integration__c psRecord = psIntegrationNumberToPSIntegrationMap.containsKey(psIntegrationNumber) ? psIntegrationNumberToPSIntegrationMap.get(psIntegrationNumber) : !isUpdate ? createNewPSIntegrationRecord(order, suborder) : null;
        
                        if(psRecord == null){ continue; }
                        
                        psRecord.PSIntegrationNumber__c = psIntegrationNumber;
                        psRecord.Status__c = getPSIntegrationStatus(suborder);
                        updateLatestDetailOnPSRecords(suborder, psRecord);  
                        psIntegrationsToUpsert.add(psRecord);
                    }
                }
            }
        }
        
        return psIntegrationsToUpsert;
    }

    public static List<PS_Integration__c>  updatePSRecordsOnSuborderDelete(Set<Id> subOrderIds) {
        List<PS_Integration__c> psIntegrationsToUpdate = new PSIntegrationSelector()
                .selectPSIntegrationsBySubOrderIds(new List<Object> { subOrderIds })
                .executeQuery();
        for(PS_Integration__c psIntegration : psIntegrationsToUpdate) {
            psIntegration.Status__c = STATUS_CANCELED;
            psIntegration.MostRecentSuborder__c = null;
        }
        return psIntegrationsToUpdate;
    }
    
    private static PS_Integration__c createNewPSIntegrationRecord(Order order, Suborder__c suborder) {
        return new PS_Integration__c(
            CurrencyIsoCode = order?.CurrencyIsoCode,
            ProServProject__c = order?.ProServProject__r.Id,
            Status__c = STATUS_NEW
        );
    }

    private static void updateLatestDetailOnPSRecords(Suborder__c suborder, PS_Integration__c psIntegration) {
        psIntegration.MostRecentSuborder__c = suborder.Id;
        psIntegration.Order__c = suborder?.Order__c;
        psIntegration.Phase__c = suborder?.Phase__c;
    }

    private static String buildPSIntegrationNumber(String mainQuoteNumber, String subOrderNumber) {
        return mainQuoteNumber + ' - ' +subOrderNumber;
    }

    private static String getPSIntegrationStatus(Suborder__c suborder) {
        if(suborder.Status__c == SuborderHelper.STATUS_NEW ||  suborder.Status__c == SuborderHelper.STATUS_LOCKED){
            return STATUS_NEW;
        }else if(suborder.Status__c == SuborderHelper.STATUS_BILLED){
            return STATUS_BILLED;
        }else if(suborder.Status__c == SuborderHelper.STATUS_FAILED){
            return STATUS_FAILED;
        }
        return STATUS_CANCELED;
    }

    public static Set<Id> checkAvailableBillingPackage(Set<Id> opptyIds) {
        List<Package__c> existingPSPackages = (List<Package__c>) new PackageSelector()
                .selectPackagesByOpportunityIdAndServiceName(opptyIds, QuoteHelper.NGBS_PROFESSIONAL_SERVICES_PRODUCT)
                .executeQuery();
        Set<Id> opptyIdsWithBillingPackage = new Set<Id>();
        for(Package__c pkg : existingPSPackages) {
            opptyIdsWithBillingPackage.add(pkg.Opportunity__c);
        }
        return opptyIdsWithBillingPackage;
    }
}