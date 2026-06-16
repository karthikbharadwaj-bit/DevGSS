/**
 * Controller for Phase Management Lightning App
 * see PhaseManagement Aura component
 */
public class PhaseManagementController {

    /**
     * Retrieves Phases with Phase line Items
     *
     * @param sObjectId Quote or Order Id
     */
    @AuraEnabled
    public static List<Phase__c> getPhases(Id sObjectId){
        if (String.isBlank(sObjectId)) {
            AquivaHelper.throwAuraException('Id is required');
        }
        List<Phase__c> phases = [
                SELECT Id, Name, Estimated_Completion_Date__c, Completed_Date__c, Order__c, Order__r.Status, Quote__c,
                       Initial_Payment__c, CurrencyIsoCode, Phase_Number__c, Status__c, OwnerId, CreatedById,
                       LastModifiedById, PhaseDescription__c, Order__r.Opportunity.CreatedBy.Name, Original_Phase__c,
                       Executed_Signoff_Link__c, Phase_Type__c,
                (
                        SELECT Id, Quote_Line_Item__c, Quote_Line_Item__r.Product2.Name, Quantity__c, CurrencyIsoCode,
                               Order_Line_Item__c, Quote_Line_Item__r.Product2.Family, Quote_Line_Item__r.UnitPrice,
                               Quote_Line_Item__r.EffectivePrice__c, Location_ID__c, Location_Name__c, Country__c,
                               City__c, Address_Line__c, Postal_Code__c, State__c, Address_Validated__c,
                               Quote_Line_Item__r.CurrencyIsoCode, Quote_Line_Item__r.EffectivePriceNew__c
                        FROM Hardware_Line_Items__r
                )
                FROM Phase__c
                WHERE Quote__c = :sObjectId
                OR Order__c = :sObjectId
                ORDER BY Phase_Number__c ASC
        ];

        return phases;
    }

    @AuraEnabled
    public static Map<String, Boolean> getUserAccessInfo() {
        Map<String, Boolean> userInfo = new Map<String, Boolean> {
                'isSystemAdmin' => ProfileHelper.isCurrentUserSysAdmin(),
                'isUserInApprovalQueue' => GroupHelper.isUserInQueue(GroupHelper.GROUP_REVENUE_OPERATIONS_TEAM_QUEUE)
        };
        return userInfo;
    }

    @AuraEnabled
    public static Order getOrder(Id orderId){
        if (String.isBlank(orderId)) {
            AquivaHelper.throwAuraException('Order id is required');
        }
        return (Order) new ListOptional(
            new OrderSelector()
                .selectOrdersByIdsForPhaseManagement(new Set<Id> {orderId})
                .executeQuery()
        ).getFirst();
    }

    /**
     * Creates new phase records or updates existing ones
     */
    @AuraEnabled
    public static Map<String, Phase__c> upsertPhases(Map<String, Phase__c> phasesToUpsert){
        if (phasesToUpsert == null || phasesToUpsert.values().size() == 0) {
            AquivaHelper.throwAuraException('Nothing specified to upsert');
        }
        for (Phase__c phaseToUpsert: phasesToUpsert.values()) {
            if(phaseToUpsert.Phase_Number__c != null){
                phaseToUpsert.RecordTypeId = PhaseHelper.RT_ID_PROSERV_PHASE;
                // Only set standard name for new records; preserve existing names
                if (String.isBlank(phaseToUpsert.Id)) {
                    phaseToUpsert.Name = 'Phase ' + phaseToUpsert.Phase_Number__c;
                }
            }
        }

        upsert phasesToUpsert.values();
        return phasesToUpsert;
    }

    /**
     * Creates new phase line item records or updates existing ones
     */
    @AuraEnabled
    public static void upsertPhaseLineItems(List<Hardware_Line_Item__c> phaseLineItemsToUpsert){
        if (phaseLineItemsToUpsert == null || phaseLineItemsToUpsert.size() == 0) {
            AquivaHelper.throwAuraException('Nothing specified to upsert');
        }
        List<Hardware_Line_Item__c> hardwareLineItems = new List<Hardware_Line_Item__c>();

        for (Hardware_Line_Item__c phaseLineItem : phaseLineItemsToUpsert){
            Hardware_Line_Item__c phaseLineItemToUpsert = phaseLineItem.clone(true, true);

            if(String.isBlank(phaseLineItemToUpsert.Id)) {
                phaseLineItemToUpsert.RecordTypeId = HardwareLineItemHelper.RT_ID_PROSERV_LINE_ITEM;
            }

            hardwareLineItems.add(phaseLineItemToUpsert);
        }

        try{
            upsert hardwareLineItems;
        } catch (Exception ex){
            AquivaHelper.throwAuraException(ex);
        }

    }

    /**
     * Deletes Phases
     */
    @AuraEnabled
    public static void deletePhases(List<Id> phaseIdsToDelete){
        if (phaseIdsToDelete == null || phaseIdsToDelete.size() == 0) {
            AquivaHelper.throwAuraException('Nothing specified to delete');
        }
        List <Phase__c> phasesToDelete = new List <Phase__c>();
        for (Id phaseId : phaseIdsToDelete){
            phasesToDelete.add(new Phase__c (Id = phaseId) );
        }

        delete phasesToDelete;
    }

    /**
     * Deletes PhaseLineItems
     */
    @AuraEnabled
    public static void deletePhaseLineItems(List<Id> phaseLineItemIdsToDelete){
        if (phaseLineItemIdsToDelete == null || phaseLineItemIdsToDelete.size() == 0) {
            AquivaHelper.throwAuraException('Nothing specified to delete');
        }
        List <Hardware_Line_Item__c> phaseLineItemsToDelete = new List <Hardware_Line_Item__c>();
        for (Id phaseLineItemId : phaseLineItemIdsToDelete){
            phaseLineItemsToDelete.add(new Hardware_Line_Item__c (Id = phaseLineItemId) );
        }

        delete phaseLineItemsToDelete;
    }

    /**
     * Updates cloned deleted phases with the new status
     */
    @AuraEnabled
    public static void lockDeletedPhases(Map<String, Phase__c> phasesToUpdate) {
        if (phasesToUpdate == null || phasesToUpdate.isEmpty() ) {
            AquivaHelper.throwAuraException('Nothing specified to update');
        }

        List<Id> phasesToLock = new List<Id>();
        for (Phase__c phaseToUpdate: phasesToUpdate.values()) {
            if(!String.isBlank(phaseToUpdate.Id)){
                phasesToLock.add(phaseToUpdate.Id);
                phaseToUpdate.Status__c = PhaseHelper.STATUS_DELETED;
            }
        }
        update phasesToUpdate.values();
        Approval.lock(phasesToLock);
    }

    /**
     * Upload locations from CSV
     * The process contains 2 steps:
     * 1. Remove all PLIs for products specified in CSV
     * 2. Upsert new PLIs
     * @return Boolean isProcessingSuccesful – returns true if data from CSV has been succesfully saved to database
     */
    @AuraEnabled
    public static Boolean processLocationsFromCSV(
        List<Id> phaseLineItemIdsToDelete,
        List<Hardware_Line_Item__c> phaseLineItemsToUpsert
    ) {
        Savepoint sp = Database.setSavepoint();
        try {
            if (!phaseLineItemsToUpsert.isEmpty()) {
                if (!phaseLineItemIdsToDelete.isEmpty()) {
                    deletePhaseLineItems(phaseLineItemIdsToDelete);
                }
                upsertPhaseLineItems(phaseLineItemsToUpsert);
            } else {
                AquivaHelper.throwAquivaException('No values to upsert!');
            }
            return true;
        } catch(Exception e) {
            AquivaHelper.throwAquivaException(e.getMessage());
            Database.rollback(sp);
            return false;
        }
    }

    /**
     * Completes Phase
     * Set Completion Date and lock records
     */
    @auraEnabled
    public static void completePhase(Id phaseId, String completeOption, Datetime completionDate) {
        CustomPermissionHelper customPermissions = new CustomPermissionHelper();
        if (!customPermissions.hasPermission(CustomPermissionHelper.PERMISSION_COMPLETE_PHASES)) {
            AquivaHelper.throwAuraException('You don\'t have permission to complete phase');
        }
        try {
            Phase__c phase = [
                    SELECT Id, BillingStatus__c, (SELECT Id FROM Hardware_Line_Items__r)
                    FROM Phase__c
                    WHERE Id = :phaseId
            ];

            // Store completion date taking into account user time - zone offset
            phase.Completed_Date__c = DateTime.newInstance(completionDate.dateGMT(), completionDate.timeGmt());
            phase.Completion_Date__c = completionDate.dateGMT();

            if (completeOption == 'Manual') {
                phase.BillingStatus__c = 'Manual';
            } else {
                String comment = 'Submitting request for approval from Phase Management Tool.';
                ApprovalHelper.submitApprovalRequest(phase.Id, ApprovalHelper.PROCESS_PHASE_COMPLETION_APPROVAL_PROCESS, comment);
            }

            update phase;

            Approval.lock(phase);
            Approval.lock(phase.Hardware_Line_Items__r);

        } catch (Exception e) {
            AquivaHelper.throwAuraException(e.getMessage());
        }

    }

    @auraEnabled
    public static Map<String, Boolean> getUserPermissions(){
        CustomPermissionHelper customPermissions = new CustomPermissionHelper();
        return customPermissions.getPermissionMap();
    }

    @AuraEnabled
    public static List<String> getPicklistValues(String sObjectApiName, String fieldApiName) {
        List<String> res = new List<String>();
        for(Schema.PicklistEntry pe : SFDescribeHelper.getOptions(sObjectApiName, fieldApiName)) {
            res.add(pe.getValue());
        }
        return res;
    }

    /**
     * Get New Change Order Feature Toggle
     */
    @AuraEnabled
    public static Boolean getIsNewChangeOrder() {
        Feature_Toggle__c featureToggleSetting = Feature_Toggle__c.getInstance();
        return featureToggleSetting.NewChangeOrderFlow__c;
    }

    @AuraEnabled
    public static Map<Id,Boolean> getQliPhaseMap (List<String> qlisIds) {
        System.debug('//////qliIds' + qlisIds);

        List <Hardware_Line_Item__c> pliList = [SELECT Id, Quote_Line_Item__c FROM Hardware_Line_Item__c WHERE Quote_Line_Item__c IN: qlisIds];

        List<Id> qlisWithPli = new List <Id>();
        for (Hardware_Line_Item__c pli : pliList) {
            if(pli.Quote_Line_Item__c != null) {
                System.debug('///HERE');
                qlisWithPli.add(pli.Quote_Line_Item__c);
            }
        }
        System.debug('///HERE'+qlisWithPli);
        Map<Id, Boolean> mapToReturn = new Map<Id, Boolean>();
        for (Id qliId : qlisIds) {
            if(!qlisWithPli.contains(qliId) || qlisWithPli.isEmpty()) {
                mapToReturn.put(qliId,false);
            } else {
                mapToReturn.put(qliId,true);
            }
        }
        System.debug('//////mapToReturn' + mapToReturn);
        return mapToReturn;
    }

    @auraEnabled
    public static List<Phase__c> getPhasesBeforeChangeOrder(Id optyId) {
        List <Opportunity> optyList = [SELECT Id, Parent_Order__c
                                FROM Opportunity
                                WHERE Id =:optyId
                                AND Parent_Order__c != null];

        List <Order> ordersToProcess = new List <Order>();
        if (!optyList.isEmpty()) {
            ordersToProcess = [SELECT Id,
                                    (SELECT Id, Name, Phase_Number__c
                                    FROM Phases__r
                                    WHERE Completed_Date__c != null
                                    ORDER BY Phase_Number__c)
                                FROM Order
                                WHERE Id =:optyList.get(0).Parent_Order__c
                                AND RecordTypeId IN: OrderHelper.ORDER_RTID_TO_QUOTE_RTID_MAP.keyset() ];
        }
        if (ordersToProcess.isEmpty() || ordersToProcess.get(0).Phases__r.isEmpty()) {
            return new List <Phase__c>();
        }

        return ordersToProcess.get(0).Phases__r;
    }

    @auraEnabled
    public static void updateQuote(Quote updatedQuote) {
        QuotingToolQuoteApexController.updateQuote(updatedQuote);
    }

    public class AddressRequestItemWrapper {
        @auraEnabled public AddressValidationApi.AddressRequestItem itemToValidate;
        @auraEnabled public Id pliId;
    }

    public class AddressResponseItemWrapper {
        @auraEnabled public AddressValidationApi.AddressResponseItem response;
        @auraEnabled public Hardware_Line_Item__c pli;
        @auraEnabled public Boolean isResponseValid;
    }

    @AuraEnabled
    public static Map<String, AddressResponseItemWrapper> validateAdressesWrapper(String addressItemList) {
        // Lightning fails to properly pass custom type variable. Have to convert it first
        // https://salesforce.stackexchange.com/questions/145357/salesforce-system-error-when-accessing-a-list-in-auraenabled-method
        // Salesforce issue W-3159538
        List<AddressRequestItemWrapper> addressItemListConverted = (List<AddressRequestItemWrapper>)
                JSON.deserialize(addressItemList, List<AddressRequestItemWrapper>.class);
        return validateAdresses(addressItemListConverted);
    }

    @AuraEnabled
    public static Map<String, AddressResponseItemWrapper> validateAdresses(List<AddressRequestItemWrapper> addressItemList) {
        Map<String, AddressResponseItemWrapper> result = null;
        try {
            List<AddressValidationApi.AddressRequestItem> toValidateList = new List<AddressValidationApi.AddressRequestItem>();
            Map<Id, AddressValidationApi.AddressRequestItem> pliIdToValidateItemMap = new Map<Id, AddressValidationApi.AddressRequestItem>();

            for (AddressRequestItemWrapper item : addressItemList) {
                toValidateList.add(item.itemToValidate);
                if (String.isNotBlank(item.pliId)) {
                    pliIdToValidateItemMap.put(item.pliId, item.itemToValidate);
                }
            }

            Map<String, AddressValidationApi.AddressResponseItem> validationResult = AddressValidationApi.validateAddresses(toValidateList);

            Map<Id, Hardware_Line_Item__c> pliIdToPliMap = new Map<Id, Hardware_Line_Item__c>();
            if (pliIdToValidateItemMap.keySet().size() > 0) {
                pliIdToPliMap = new Map<Id, Hardware_Line_Item__c>([
                        SELECT Id, Quote_Line_Item__c, Quote_Line_Item__r.Product2.Name, Quantity__c, CurrencyIsoCode,
                                Order_Line_Item__c, Quote_Line_Item__r.Product2.Family, Quote_Line_Item__r.UnitPrice,
                                Quote_Line_Item__r.EffectivePrice__c, Location_ID__c, Location_Name__c, Country__c,
                                City__c, Address_Line__c, Postal_Code__c, State__c, Address_Validated__c,
                                Quote_Line_Item__r.CurrencyIsoCode, Quote_Line_Item__r.EffectivePriceNew__c
                        FROM Hardware_Line_Item__c
                        WHERE Id IN :pliIdToValidateItemMap.keySet()
                ]);

            }
            result = createValidateResponseAndUpdatePLIList(addressItemList, pliIdToPliMap, validationResult);

            if (pliIdToValidateItemMap.keySet().size() > 0) {
                update pliIdToPliMap.values();
            }

        } catch (Exception ex) {
            AquivaHelper.throwAuraException(ex);
        }
        return result;
    }

    public static Map<String, AddressResponseItemWrapper> createValidateResponseAndUpdatePLIList(
            List<AddressRequestItemWrapper> addressItemList,
            Map<Id, Hardware_Line_Item__c> pliIdToPliMap,
            Map<String, AddressValidationApi.AddressResponseItem> validationResult) {

        Map<String, AddressResponseItemWrapper> result = new Map<String, AddressResponseItemWrapper>();
        Map<String, AddressRequestItemWrapper> keyToRequestItemMap = new Map<String, AddressRequestItemWrapper>();

        for (AddressRequestItemWrapper item : addressItemList) {
            keyToRequestItemMap.put(item.itemToValidate.seqId, item);
        }

        for (String seqId : validationResult.keySet()) {
            AddressValidationApi.AddressResponseItem responseItem = validationResult.get(seqId);
            AddressRequestItemWrapper requestItem = keyToRequestItemMap.get(seqId);

            AddressResponseItemWrapper resultItem = new AddressResponseItemWrapper();
            resultItem.response = responseItem;
            Boolean isResponseValid =  AddressValidationApi.isResponseValid(responseItem);
            resultItem.isResponseValid = isResponseValid;
            if (String.isNotBlank(requestItem.pliId)) {
                resultItem.pli = pliIdToPliMap.get(requestItem.pliId);

                resultItem.pli.Address_Line__c      = isResponseValid?
                                                        responseItem.adressLine
                                                        : requestItem.itemToValidate.addressLine1;
                resultItem.pli.City__c              = isResponseValid? responseItem.city
                                                        : requestItem.itemToValidate.city;
                resultItem.pli.State__c             = requestItem.itemToValidate.state;
                resultItem.pli.Postal_Code__c       = requestItem.itemToValidate.zip;
                resultItem.pli.Country__c           = requestItem.itemToValidate.country;
                resultItem.pli.Address_Validated__c = isResponseValid;
            }

            result.put(seqId, resultItem);
        }

        return result;
    }

    /**
     *   Recall/Approve/Reject request for approval
     */
    @AuraEnabled
    public static void setApprovalAction(Id phaseId, String action, String comment) {
        try {
            ApprovalHelper.setApprovalAction(phaseId, action, comment);
        } catch (Exception e) {
            AquivaHelper.throwAuraException(e);
        }
    }

    @AuraEnabled
    public static Order findParentOrder(String oppOrOrderId) {

        if (String.isBlank(oppOrOrderId)) {
            AquivaHelper.throwAuraException('Id param is required');
        }

        Order result = null;

        Id idValue = Id.valueOf(oppOrOrderId);

        if(idValue.getSobjectType() == Schema.Opportunity.SObjectType) {

            Opportunity currOpp = [SELECT Parent_Order__c FROM Opportunity WHERE Id = :idValue];

            if(currOpp.Parent_Order__c == null) {
                return null;
            }

            result = [
                SELECT Id,
                    (SELECT Id, Phase_Number__c FROM Phases__r WHERE Completed_Date__c = null)
                FROM Order
                WHERE Id = :currOpp.Parent_Order__c
            ];

        }else if(idValue.getSobjectType() == Schema.Order.SObjectType) {

            Order ord = [SELECT Quote.Opportunity.Parent_Order__c FROM Order WHERE Id = :idValue];

            if(ord.Quote.Opportunity.Parent_Order__c == null) {
                return null;
            }

            result = [
                SELECT Id,
                    (SELECT Id, Phase_Number__c FROM Phases__r WHERE Completed_Date__c = null)
                FROM Order
                WHERE Id = :ord.Quote.Opportunity.Parent_Order__c
            ];

        }else{
            AquivaHelper.throwAuraException('Id should be Opportunity or Order type');
        }

        return result;
    }

    @AuraEnabled
    public static Integer findMaxPhaseNumberOnOrder(Id orderId) {

        if (String.isBlank(orderId)) {
            AquivaHelper.throwAuraException('Order id is required');
        }

        Order currentOrder = [
            SELECT
                Id,
                MaxPhaseNumber__c,
                (SELECT Id, Phase_Number__c FROM Phases__r)
            FROM Order WHERE Id = :orderId
        ];

        Decimal maxPhaseNumber = 0;

        for(Phase__c ph : currentOrder.Phases__r) {
            if(ph.Phase_Number__c > maxPhaseNumber) {
                maxPhaseNumber = ph.Phase_Number__c;
            }
        }

        Decimal result = maxPhaseNumber > currentOrder.MaxPhaseNumber__c ? maxPhaseNumber : currentOrder.MaxPhaseNumber__c;

        return Integer.valueOf(result);
    }
    /**
     *  Get Ring Central various settings
     *  Returns sObject - to avoid "Internal Server Error" if user does not have access to RingCentralVariousSettings__c
     */
    @AuraEnabled
    public static SObject getRcVariousSettings(Id phaseId, String action, String comment) {
        RingCentralVariousSettings__c settings = RingCentralVariousSettings__c.getInstance();
        return settings;
    }

    @AuraEnabled
    public static Boolean getIsNewProservFlow(Id orderId) {
        Boolean isNewProservFlow = false;
        Order currentOrder= (Order) new ListOptional(
            new OrderSelector()
                .selectOrdersByIdsForPhaseManagement(new Set<Id> {orderId})
                .executeQuery()
        ).getFirst();

        Boolean isChangeOrderForNewFlow = currentOrder.RecordTypeId == OrderHelper.RT_ID_PROSERV
            && currentOrder.Type == OrderHelper.TYPE_CHANGE_ORDER
            && currentOrder.Opportunity.RecordTypeId == OpportunityHelper.RT_ID_NEW_SALES_OPPORTUNITY
            && currentOrder.Opportunity.Type == OpportunityHelper.OPPORTUNITY_TYPE_EX_BUSINESS
            && currentOrder.Opportunity.Tier_Name__c == OpportunityHelper.TIER_PROFESSIONAL_SERVICES;

        if (isChangeOrderForNewFlow) {
            isNewProservFlow = true;
            return isNewProservFlow;
        }

        List<Quote> techQuotes = (List<Quote>) new QuoteSelector()
            .selectTechQuotesByOppIdUB(currentOrder.OpportunityId)
            .executeQuery();
        for (Quote qt: techQuotes) {
            if (qt.ServiceName__c == QuoteHelper.NGBS_PROFESSIONAL_SERVICES_PRODUCT) {
                isNewProservFlow = true;
            }
        }

        return isNewProservFlow;
    }
}