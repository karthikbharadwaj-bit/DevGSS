trigger Order_Before on Order (before insert, before update, before delete) {

    ByPassTrigger__c bypassTrigger = ByPassTrigger__c.getInstance();
        if (bypassTrigger != null && bypassTrigger.Bypass_Order_Trigger__c == true) {
             System.debug('$$$ ByPassTrigger__c Active For Order Credit $$$');
            return;
        }

    private static final Boolean isSandbox =
        ((Organization) new OrganizationSelector().selectOrg().setQueryCaching(true).executeQuery()[0]).isSandbox;

    if (Trigger.isBefore) {
        if (Trigger.isUpdate) {

            Map<Id, Order> accountIdToOrderMap = new Map<Id, Order>();
            List<Order> orders = new List<Order>();

            for (Order item : Trigger.new) {

                Order oldItem = Trigger.oldMap.get(item.Id);

                if ((item.RecordTypeId == OrderHelper.RT_ID_CC || item.RecordTypeId == OrderHelper.RT_ID_RC_CONTACT_CENTER)
                    && (item.Status == OrderHelper.STATUS_PROVISIONED && oldItem.Status != OrderHelper.STATUS_PROVISIONED)) {
                    accountIdToOrderMap.put(item.AccountId, item);

                    //B-1464 Populate dates on order when status changes occur
                    item.Provisioned_Date__c = Datetime.now();
                }

                if ((item.RecordTypeId == OrderHelper.RT_ID_CC || item.RecordTypeId == OrderHelper.RT_ID_RC_CONTACT_CENTER)
                    && item.Submitted_Date__c != oldItem.Submitted_Date__c
                    && !Test.isRunningTest()
                    && ((isSandbox && CCUtils.isCurrentUserCCDeskMember ) || (!isSandbox && !CCUtils.isCurrentUserCCDeskMember))) {

                    item.addError(isSandbox ? OrderHelper.ERROR_SUBMITTED_DATE_CHANGE_SANDBOX : OrderHelper.ERROR_SUBMITTED_DATE_CHANGE);
                }
                //B-1464 Populate dates on order when status changes occur
                if (OrderHelper.STATUS_SET_SUBMITTED.contains(item.Status) && !OrderHelper.STATUS_SET_SUBMITTED.contains(oldItem.Status)
                    && oldItem.Submitted_Date__c == null) {
                    item.Submitted_Date__c = Datetime.now();
                }

                if ((item.RecordTypeId == OrderHelper.RT_ID_CC || item.RecordTypeId == OrderHelper.RT_ID_RC_CONTACT_CENTER)
                    && OrderHelper.STATUS_SET_SUBMITTED.contains(item.Status) && !OrderHelper.STATUS_SET_SUBMITTED.contains(oldItem.Status)
                    && oldItem.FSC_Start_Date__c == null && item.FSC_Terms__c > 0) {
                    item.FSC_Start_Date__c = Datetime.now();
                }

                // B-802 Updated Order and Site Object for CloudConnect
                // if( Order.sObjectType.getDescribe().getRecordTypeInfosById().get( item.recordTypeID ).getName() == 'Cloud Connect'  ) {
                if (Order.SObjectType.getDescribe().getRecordTypeInfosById().get(item.RecordTypeId).getName() == OrderHelper.RT_NAME_PROSERV) {
                    orders.add(item);
                }
            }

            // accounts processing
            if (accountIdToOrderMap.size() > 0) {
                OrderBeforeTriggerHandler.updateAccs(accountIdToOrderMap);
            }
            // B-802 Updated Order and Site Object for CloudConnect
            if (!orders.isEmpty()) {
                OrderBeforeTriggerHandler.updateCloudConnect(orders);
            }

            OrderBeforeTriggerHandler.setBillingStatus(Trigger.new, Trigger.oldMap);
        }

        if (Trigger.isInsert) {
            Map<Id, Schema.RecordTypeInfo> rtMap = Order.SObjectType.getDescribe().getRecordTypeInfosById();
            Map<Id, Order> quoteIdToOrderMap = new Map<Id, Order> ();
            List<Order> orders = new List<Order>();

            Feature_Toggle__c featureToggleSetting = Feature_Toggle__c.getInstance();

            Map<Id, Opportunity> idToOpportunityMap = new Map<Id, Opportunity>();
            if (featureToggleSetting.NewChangeOrderFlow__c) {
                Set<Id> oppIds = new Set<Id>();
                for (Order order : Trigger.new) {
                    oppIds.add(order.OpportunityId);
                }
                if (!oppIds.isEmpty() ) {
                    idToOpportunityMap = new Map<Id, Opportunity>([SELECT Id, Parent_Order__c, Brand_Name__c, BusinessIdentity__c FROM Opportunity WHERE Id IN :oppIds]);
                }
            }

            for (Order newItem : Trigger.new) {

                String recordTypeName = rtMap.get(newItem.RecordTypeId).getName();

                // B-1196 Live Reports fields populated automatically only for "RingCentral" Record Type
                if (recordTypeName == OrderHelper.RT_NAME_RC && String.isNotEmpty(newItem.QuoteId)) {
                    quoteIdToOrderMap.put(newItem.QuoteId, newItem);
                }

                // B-802 Updated Order and Site Object for CloudConnect
                // if ( recordTypeName == 'Cloud Connect' && String.isNotEmpty(newItem.QuoteId) ) {
                if (recordTypeName == OrderHelper.RT_NAME_PROSERV && String.isNotEmpty(newItem.QuoteId) && newItem.TechnicalQuoteId__c == null) {
                    orders.add(newItem);
                }

                if (quoteIdToOrderMap.size() > 0) {
                    OrderBeforeTriggerHandler.updateRCRT(quoteIdToOrderMap);
                }
                // B-802 Updated Order and Site Object for CloudConnect
                if (orders.size() > 0) {
                    OrderBeforeTriggerHandler.populateFields(orders);
                }

                //B-1464 Populate dates on order when status changes occur
                if (newItem.RecordTypeId == OrderHelper.RT_ID_CC && newItem.Status == OrderHelper.STATUS_PROVISIONED) {
                    newItem.Provisioned_Date__c = Datetime.now();
                }
                if (OrderHelper.STATUS_SET_SUBMITTED.contains(newItem.Status)) {
                    newItem.Submitted_Date__c = Datetime.now();
                }

                if (featureToggleSetting.NewChangeOrderFlow__c && newItem.OpportunityId != null
                    && (newItem.RecordTypeId == OrderHelper.RT_ID_CC_PROSERV || newItem.RecordTypeId == OrderHelper.RT_ID_PROSERV)) {

                    if (idToOpportunityMap.get(newItem.OpportunityId).Parent_Order__c != null) {
                        newItem.Type = OrderHelper.TYPE_CHANGE_ORDER;
                    } else {
                        newItem.Type = OrderHelper.TYPE_INITIAL_ORDER;
                    }
                }
            }

            OrderBeforeTriggerHandler.setBillingStatus(Trigger.new, null);
        }

        if (Trigger.isDelete) {
            // if order is deleted - delete related Phase and Sites
            Set<Id> orderIds = new Set<Id>();
            for (Order order : (List<Order>) Trigger.old) {
                if (order.TechnicalQuoteId__c == null) {
                    orderIds.add(order.Id);
                }
            }
            Map<Id, Phase__c> phases =
                new Map<Id, Phase__c>([SELECT Id, Order__c FROM Phase__c WHERE Order__c IN :orderIds]);

            try {
                delete phases.values();
            } catch (DmlException e) {
                Trigger.oldMap.get(phases.get(e.getDmlId(0)).Order__c).addError(OrderHelper.PHASE_DELETION_ERROR);
            }

            delete [SELECT Id FROM Site__c WHERE Order__c IN :Trigger.oldMap.keySet()];
        }
    }
}