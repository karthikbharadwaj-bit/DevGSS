public class CampaignMemberPlatEvents {
    static final String RECORDTYPENAME = 'Camp Memb Exception Log';
    public static void campaignMemberCreationAsyncFromLead(List<CampaignMember> campaignMemberList, boolean triggerOn) {
        List<CampaignMemberCreation_From_Lead__e> campMembEvents = new List<CampaignMemberCreation_From_Lead__e>();
        for (CampaignMember campMemb : campaignMemberList) {
            campMembEvents.add(
                new CampaignMemberCreation_From_Lead__e(
                    CampaignId__c = campMemb.CampaignId,
                    LeadId__c = campMemb.LeadId,
                    Primary_Marketing_Asset__c = campMemb.Primary_Marketing_Asset__c,
                    Trigger_On__c = triggerOn
                )
            );
        }
        PlatformEvents.publishPlatformEvent(campMembEvents, 'campaignMemberCreationAsyncFromLead');
    }
    public static void processCampaignMemberCreationFromLeadEvent(List<CampaignMemberCreation_From_Lead__e> events) {
        List<CampaignMember> campaignMemberListTriggerOn = new List<CampaignMember>();
        List<CampaignMember> campaignMemberListTriggerOff = new List<CampaignMember>();
        for (CampaignMemberCreation_From_Lead__e event : events) {
            CampaignMember cm = new CampaignMember(
                CampaignId = event.CampaignId__c,
                LeadId = event.LeadId__c,
                Primary_Marketing_Asset__c = event.Primary_Marketing_Asset__c
            );
            if (event.Trigger_On__c) {
                campaignMemberListTriggerOn.add(cm);
            } else {
                campaignMemberListTriggerOff.add(cm);
            }
        }
        createCampaignMembers(campaignMemberListTriggerOn, campaignMemberListTriggerOff);
    }
    public static void createCampaignMembers(
        List<CampaignMember> campaignMemberListTriggerOn,
        List<CampaignMember> campaignMemberListTriggerOff
    ) {
        List<CampaignMemberRetry__e> campaignMemberRetriesEvents = new List<CampaignMemberRetry__e>();

        if (campaignMemberListTriggerOn != null && campaignMemberListTriggerOn.size() > 0) {
            CampaignMemberTriggerHandler.dmlFromPlatformEvents = true;
            Database.SaveResult[] srList = Database.insert(campaignMemberListTriggerOn, false);
            campaignMemberRetriesEvents = generateCampaignMemberRetry(srList, campaignMemberListTriggerOn, true);
        }

        if (campaignMemberListTriggerOff != null && campaignMemberListTriggerOff.size() > 0) {
            TriggerHandler.BY_PASS_CAMPAIGNMEMBER_TRIGGER_FIREPLATFORMEVENTCHECK = true;
            TriggerHandler.BY_PASS_CAMPAIGNMEMBER_TRIGGER_FIREPLATFORMEVENTLOG = true;
            CampaignMemberTriggerHandler.dmlFromPlatformEvents = true;
            Database.SaveResult[] srList = Database.insert(campaignMemberListTriggerOff, false);
            TriggerHandler.BY_PASS_CAMPAIGNMEMBER_TRIGGER_FIREPLATFORMEVENTCHECK = false;
            TriggerHandler.BY_PASS_CAMPAIGNMEMBER_TRIGGER_FIREPLATFORMEVENTLOG = false;
            campaignMemberRetriesEvents = generateCampaignMemberRetry(srList, campaignMemberListTriggerOff, false);
        }

        if (!campaignMemberRetriesEvents.isEmpty()) {
            PlatformEvents.publishPlatformEvent(campaignMemberRetriesEvents, 'CampaignMemberCreationEvent');
        }
    }

    public static List<CampaignMemberRetry__e> generateCampaignMemberRetry(
        Database.SaveResult[] srList,
        List<CampaignMember> campaignMemberList,
        Boolean isTriggerOn
    ) {
        List<CampaignMemberRetry__e> campaignMemberRetriesEvents = new List<CampaignMemberRetry__e>();
        for (Integer i = 0; i < srList.size(); i++) {
            if (!srList[i].isSuccess()) {
                campaignMemberRetriesEvents.add(
                    new CampaignMemberRetry__e(
                        CampaignId__c = campaignMemberList[i].CampaignId,
                        LeadId__c = campaignMemberList[i].LeadId,
                        ContactId__c = campaignMemberList[i].ContactId,
                        Primary_Marketing_Asset__c = campaignMemberList[i].Primary_Marketing_Asset__c,
                        Trigger_On__c = isTriggerOn
                    )
                );
            }
        }
        return campaignMemberRetriesEvents;
    }

    public static void processCampaignMemberRetryCreationEvent(List<CampaignMemberRetry__e> events) {
        List<CampaignMember> campaignMemberListTriggerOn = new List<CampaignMember>();
        List<CampaignMember> campaignMemberListTriggerOff = new List<CampaignMember>();
        for (CampaignMemberRetry__e event : events) {
            if (event.LeadId__c != null || event.ContactId__c != null) {
                CampaignMember cm = new CampaignMember(
                    CampaignId = event.CampaignId__c,
                    LeadId = (event.LeadId__c != null) ? event.LeadId__c : null,
                    ContactId = (event.ContactId__c != null) ? event.ContactId__c : null,
                    Primary_Marketing_Asset__c = event.Primary_Marketing_Asset__c
                );
                if (event.Trigger_On__c) {
                    campaignMemberListTriggerOn.add(cm);
                } else {
                    campaignMemberListTriggerOff.add(cm);
                }
            }
        }

        if (campaignMemberListTriggerOn.size() > 0) {
            CampaignMemberTriggerHandler.dmlFromPlatformEvents = true;
            insert campaignMemberListTriggerOn;
        }

        if (campaignMemberListTriggerOff.size() > 0) {
            CampaignMemberTriggerHandler.dmlFromPlatformEvents = true;
            Triggers.switchOff();
            insert campaignMemberListTriggerOff;
            Triggers.switchOn();
        }
    }

    public static void processCampaignMemberRetryCreationEventException(
        List<CampaignMemberRetry__e> events,
        Exception e
    ) {
        List<Exception_And_Notification_History__c> exceptions = new List<Exception_And_Notification_History__c>();
        Id rtId = Schema.SObjectType.Exception_And_Notification_History__c.getRecordTypeInfosByName()
            .get(RECORDTYPENAME)
            .getRecordTypeId();
        for (CampaignMemberRetry__e event : events) {
            exceptions.add(
                new Exception_And_Notification_History__c(
                    RecordTypeId = rtId,
                    Object_Type__c = CampaignMemberRetry__e.SObjectType.getDescribe().getName(),
                    Affected_record_ID__c = JSON.serialize(event),
                    Exception__c = e.getTypeName(),
                    Exception_desc__c = e.getMessage()
                )
            );
        }
        if (exceptions.size() > 0) {
            insert exceptions;
        }
    }

    public static void processCampaignMemberLogCreationEvent(List<Campaign_Member_Log__e> events) {
        List<Exception_And_Notification_History__c> exceptions = new List<Exception_And_Notification_History__c>();
        Id rtId = Schema.SObjectType.Exception_And_Notification_History__c.getRecordTypeInfosByName()
            .get(RECORDTYPENAME)
            .getRecordTypeId();
        for (Campaign_Member_Log__e event : events) {
            exceptions.add(
                new Exception_And_Notification_History__c(
                    RecordTypeId = rtId,
                    Object_Type__c = Campaign_Member_Log__e.SObjectType.getDescribe().getName(),
                    Record_Id__c = event.RecordId__c,
                    Affected_record_ID__c = event.Data__c
                )
            );
        }
        if (exceptions.size() > 0) {
            insert exceptions;
        }
    }

    public static void processCampaignMemberCheckCreationEvent(List<Campaign_Member_Check__e> events) {
        Id rtId = Schema.SObjectType.Exception_And_Notification_History__c.getRecordTypeInfosByName()
            .get(RECORDTYPENAME)
            .getRecordTypeId();
        List<Object> bindings = new List<Object>();
        bindings.add(rtId);
        bindings.add(Campaign_Member_Log__e.SObjectType.getDescribe().getName());
        Set<string> recordIds = new Set<string>();
        for (Campaign_Member_Check__e event : events) {
            recordIds.add(event.RecordId__c);
        }
        bindings.add(recordIds);
        List<Exception_and_notification_history__c> lstExceptions = (List<Exception_and_notification_history__c>) new ExceptionAndNotificationHistorySelector()
            .selectExceptionAndNotificationHistoryByIdRecordIdOrAffectedRecordID(bindings)
            .executeQuery();
        delete lstExceptions;
    }
    
    public static void campaignMemberCreationAsyncFromContact(
        List<CampaignMember> campaignMemberList,
        boolean triggerOn
    ) {
        List<CampaignMemberCreation_From_Contact__e> campMembEvents = new List<CampaignMemberCreation_From_Contact__e>();
        for (CampaignMember campMemb : campaignMemberList) {
            campMembEvents.add(
                new CampaignMemberCreation_From_Contact__e(
                    Campaign_Id__c = campMemb.CampaignId,
                    Contact_Id__c = campMemb.ContactId,
                    Trigger_On__c = triggerOn
                )
            );
        }
        PlatformEvents.publishPlatformEvent(campMembEvents, 'campaignMemberCreationAsyncFromContact');
    }

    public static void processCampaignMemberCreationFromContactEvent(
        List<CampaignMemberCreation_From_Contact__e> events
    ) {
        List<CampaignMember> campaignMemberListTriggerOn = new List<CampaignMember>();
        List<CampaignMember> campaignMemberListTriggerOff = new List<CampaignMember>();

        for (CampaignMemberCreation_From_Contact__e event : events) {
            CampaignMember cm = new CampaignMember(
                CampaignId = event.Campaign_Id__c,
                ContactId = event.Contact_Id__c,
                Primary_Marketing_Asset__c = event.Primary_Marketing_Asset__c
            );

            if (event.Trigger_On__c) {
                campaignMemberListTriggerOn.add(cm);
            } else {
                campaignMemberListTriggerOff.add(cm);
            }
        }
        createCampaignMembers(campaignMemberListTriggerOn, campaignMemberListTriggerOff);
    }
}