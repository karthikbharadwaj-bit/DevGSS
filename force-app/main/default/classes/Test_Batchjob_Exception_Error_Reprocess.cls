@isTest
public with sharing class Test_Batchjob_Exception_Error_Reprocess {
    public static final String DEVELOPERNAME_EANH_CAMPAIGNMEMBER_LOG = 'Camp Memb Exception Log';

    @isTest
    public static void testCampaignMemberReinsert_FromCampaignMemberRetryEvent_ShouldBeReinserted() {
        BatchJobsConfiguration__c setting = new BatchJobsConfiguration__c();
        setting.Name = 'Batchjob_Exception_Error_Reprocess';
        setting.ErrorEmailDistributionList__c = 'test@testgmail.com';
        insert setting;

        List<Lead> lds = (List<Lead>) new SObjectBuilder(Lead.SObjectType)
            .setField(Lead.Company, 'test company')
            .setField(Lead.Email, 'fake@email.com22')
            .setField(Lead.LastName, 'lastName Test')
            .quantity(100)
            .create()
            .getRecords();

        List<Campaign> cms = (List<Campaign>) new SObjectBuilder(Campaign.SObjectType)
            .setField(Campaign.Name, 'True_Walk_On_2024')
            .quantity(100)
            .create()
            .getRecords();

        new SObjectBuilder(CampaignMember.SObjectType)
            .setField(CampaignMember.LeadId, lds[0].Id)
            .setField(CampaignMember.CampaignId, cms[0].Id)
            .create();
        
        new SObjectBuilder(CampaignMember.SObjectType)
            .setField(CampaignMember.LeadId, lds[1].Id)
            .setField(CampaignMember.CampaignId, cms[1].Id)
            .create();

        List<Marketing_Asset__c> mAssets = (List<Marketing_Asset__c>) new SObjectBuilder(Marketing_Asset__c.SObjectType)
            .quantity(100)
            .create()
            .getRecords();

        Id rtId = Schema.SObjectType.Exception_And_Notification_History__c.getRecordTypeInfosByName()
            .get(DEVELOPERNAME_EANH_CAMPAIGNMEMBER_LOG)
            .getRecordTypeId();

        List<Exception_And_Notification_History__c> EANHs = new List<Exception_And_Notification_History__c>();

        List<CampaignMemberRetry__e> cmRetriesEvents = new List<CampaignMemberRetry__e>();

        for (Integer i = 0; i < 100; i++) {
            cmRetriesEvents.add(
                new CampaignMemberRetry__e(
                    CampaignId__c = cms[i].Id,
                    LeadId__c = lds[i].Id,
                    Primary_Marketing_Asset__c = mAssets[i].Id,
                    Trigger_On__c = math.mod(i, 2) == 0
                )
            );
        }

        for (Integer i = 0; i < 100; i++) {
            EANHs.add(
                new Exception_and_Notification_History__c(
                    RecordTypeId = rtId,
                    Object_Type__c = campaignMemberRetry__e.SObjectType.getDescribe().getName(),
                    Affected_record_ID__c = JSON.serialize(cmRetriesEvents[i]),
                    Exception__c = 'System.DmlException',
                    Exception_desc__c = 'Desc'
                )
            );
        }

        insert EANHs;

        Test.startTest();
        ID batchprocessid = Database.executeBatch(new Batchjob_Exception_Error_Reprocess());
        Test.stopTest();

        List<Object> bindings = new List<Object>();
        List<Id> leadIds = new List<Id>();
        List<Id> campaignIds = new List<Id>();
        for (Integer i = 0; i < 100; i++) {
            leadIds.add(lds[i].Id);
            campaignIds.add(cms[i].Id);
        }
        bindings.add(leadIds);
        bindings.add(campaignIds);

        List<CampaignMember> cMemberss = (List<CampaignMember>) new CampaignMemberSelector()
            .selectCampaignMemberByLeadAndCampaignIds(bindings)
            .executeQuery();

        System.assertEquals(100, cMemberss.size(), 'There should be 100 campaign members createds.');

        System.assertEquals(
            0, 
            new ExceptionAndNotificationHistorySelector()
            .selectExceptionAndNotificationHistorysByIds(new object[]{EANHs})
            .executeQuery()
            .size(),
            'There shouldn\'t be an Exception and notification history sObject created.'
        );
    }

    @isTest
    public static void testCampaignMemberInsert_FromCampaignMemberLogEvent_ShouldBeInserted() {
        BatchJobsConfiguration__c setting = new BatchJobsConfiguration__c();
        setting.Name = 'Batchjob_Exception_Error_Reprocess';
        setting.ErrorEmailDistributionList__c = 'test@testgmail.com';
        insert setting;

        List<Lead> lds = (List<Lead>) new SObjectBuilder(Lead.SObjectType)
            .setField(Lead.Company, 'test company')
            .setField(Lead.Email, 'fake@email.com22')
            .setField(Lead.LastName, 'lastName Test')
            .quantity(100)
            .create()
            .getRecords();

        List<Campaign> cms = (List<Campaign>) new SObjectBuilder(Campaign.SObjectType)
            .setField(Campaign.Name, 'True_Walk_On_2024')
            .quantity(100)
            .create()
            .getRecords();

        List<CampaignMember> cMembersToInsert = new List<CampaignMember>();

        for (Integer i = 0; i < 100; i++) {
            cMembersToInsert.add(new CampaignMember(LeadId = lds[i].Id, CampaignId = cms[i].Id));
        }

        Id rtId = Schema.SObjectType.Exception_And_Notification_History__c.getRecordTypeInfosByName()
            .get(DEVELOPERNAME_EANH_CAMPAIGNMEMBER_LOG)
            .getRecordTypeId();

        List<Exception_And_Notification_History__c> EANHList = new List<Exception_And_Notification_History__c>();
        for (Integer i = 0; i < 100; i++) {
            CampaignMember cm = cMembersToInsert[i];
            if (math.mod(i, 2) == 0) {
                EANHList.add(
                    new Exception_And_Notification_History__c(
                        RecordTypeId = rtId,
                        Object_Type__c = Campaign_Member_Log__e.SObjectType.getDescribe().getName(),
                        Field_Changes__c = JSON.serialize(cm),
                        Record_Id__c = cm.CampaignId + '-' + cm.ContactId + '-' + cm.LeadId
                    )
                );
            } else {
                EANHList.add(
                    new Exception_And_Notification_History__c(
                        RecordTypeId = rtId,
                        Object_Type__c = Campaign_Member_Log__e.SObjectType.getDescribe().getName(),
                        Affected_record_ID__c = JSON.serialize(cm),
                        Record_Id__c = cm.CampaignId + '-' + cm.ContactId + '-' + cm.LeadId
                    )
                );
            }
        }
        insert EANHList;

        Test.startTest();
        ID batchprocessid = Database.executeBatch(new Batchjob_Exception_Error_Reprocess());
        Test.stopTest();

        List<Object> bindings = new List<Object>();
        List<Id> leadIds = new List<Id>();
        List<Id> campaignIds = new List<Id>();
        for (Integer i = 0; i < 100; i++) {
            leadIds.add(lds[i].Id);
            campaignIds.add(cms[i].Id);
        }
        bindings.add(leadIds);
        bindings.add(campaignIds);

        List<CampaignMember> cMemberss = (List<CampaignMember>) new CampaignMemberSelector()
            .selectCampaignMemberByLeadAndCampaignIds(bindings)
            .executeQuery();

        System.assertEquals(100, cMemberss.size(), 'There should be 100 campaign members createds.');

        System.assertEquals(
            0,
            new ExceptionAndNotificationHistorySelector()
            .selectExceptionAndNotificationHistorysByIds(new object[]{EANHList})
            .executeQuery()
            .size(),
            'There shouldn\'t be an Exception and notification history sObject created.'
        );
    }

    @isTest
    public static void testCampaignMemberUpdate_FromCampaignMemberLogEvent_ShouldBeUpdated() {
        BatchJobsConfiguration__c setting = new BatchJobsConfiguration__c();
        setting.Name = 'Batchjob_Exception_Error_Reprocess';
        setting.ErrorEmailDistributionList__c = 'test@testgmail.com';
        insert setting;

        List<Lead> lds = (List<Lead>) new SObjectBuilder(Lead.SObjectType)
            .setField(Lead.Company, 'test company')
            .setField(Lead.Email, 'fake@email.com22')
            .setField(Lead.LastName, 'lastName Test')
            .quantity(100)
            .create()
            .getRecords();

        List<Campaign> cms = (List<Campaign>) new SObjectBuilder(Campaign.SObjectType)
            .setField(Campaign.Name, 'True_Walk_On_2024')
            .quantity(100)
            .create()
            .getRecords();

        List<CampaignMember> cMembersToUpdate = new List<CampaignMember>();

        for (Integer i = 0; i < 100; i++) {
            cMembersToUpdate.add(
                new CampaignMember(
                    LeadId = lds[i].Id,
                    CampaignId = cms[i].Id,
                    Asset_Name__c = 'Test',
                    Asset_Type__c = '22'
                )
            );
        }

        insert cMembersToUpdate;

        String assetName = 'Asset_Name_Test';

        for (Integer i = 0; i < 100; i++) {
            cMembersToUpdate[i].Asset_Name__c = assetName;
        }

        Id rtId = Schema.SObjectType.Exception_And_Notification_History__c.getRecordTypeInfosByName()
            .get(DEVELOPERNAME_EANH_CAMPAIGNMEMBER_LOG)
            .getRecordTypeId();

        List<Exception_And_Notification_History__c> EANHList = new List<Exception_And_Notification_History__c>();

        for (Integer i = 0; i < 100; i++) {
            CampaignMember cm = cMembersToUpdate[i];
            if (Math.mod(i, 2) == 0) {
                EANHList.add(
                    new Exception_And_Notification_History__c(
                        RecordTypeId = rtId,
                        Object_Type__c = Campaign_Member_Log__e.SObjectType.getDescribe().getName(),
                        Field_Changes__c = JSON.serialize(cm),
                        Record_Id__c = cm.Id
                    )
                );
            } else {
                EANHList.add(
                    new Exception_And_Notification_History__c(
                        RecordTypeId = rtId,
                        Object_Type__c = Campaign_Member_Log__e.SObjectType.getDescribe().getName(),
                        Affected_Record_Id__c = JSON.serialize(cm),
                        Record_Id__c = cm.Id
                    )
                );
            }
        }

        insert EANHList;

        Test.startTest();
        ID batchprocessid = Database.executeBatch(new Batchjob_Exception_Error_Reprocess());
        Test.stopTest();

        List<Object> bindings = new List<Object>();
        List<Id> leadIds = new List<Id>();
        List<Id> campaignIds = new List<Id>();
        for (Integer i = 0; i < 100; i++) {
            leadIds.add(lds[i].Id);
            campaignIds.add(cms[i].Id);
        }
        bindings.add(leadIds);
        bindings.add(campaignIds);

        List<CampaignMember> cMemberss = (List<CampaignMember>) new CampaignMemberSelector()
            .selectCampaignMemberByLeadAndCampaignIds(bindings)
            .selectField('Asset_Name__c')
            .selectField('Asset_Type__c')
            .executeQuery();

        System.assertEquals(100, cMemberss.size(), 'There should be 100 campaign members createds.');

        for (CampaignMember cm : cMemberss) {
            System.assertEquals(assetName, cm.asset_Name__c, 'The changes on Asset Name field haven\'t be applied');
            System.assertEquals('22', cm.Asset_Type__c, 'The changes on Asset_Type__c field haven\'t be applied');
        }

        System.assertEquals(
            0,
            new ExceptionAndNotificationHistorySelector()
            .selectExceptionAndNotificationHistorysByIds(new object[]{EANHList})
            .executeQuery()
            .size(),
            'There shouldn\'t be an Exception and notification history sObject created.'
        );
    }

    @isTest
    public static void testCampaignMemberInsert_FromCampaignMemberRetryEvent_ShouldDeleteEANH() {
        BatchJobsConfiguration__c setting = new BatchJobsConfiguration__c();
        setting.Name = 'Batchjob_Exception_Error_Reprocess';
        setting.ErrorEmailDistributionList__c = 'test@testgmail.com';
        insert setting;

        ByPassTrigger__c bypassTrigger = ByPassTrigger__c.getInstance();
        bypassTrigger.Bypass_Lead_Trigger__c = true;
        insert bypassTrigger;

        List<Lead> lds = (List<Lead>) new SObjectBuilder(Lead.SObjectType)
            .setField(Lead.Company, 'test company')
            .setField(Lead.Email, 'fake@email.com22')
            .setField(Lead.LastName, 'lastName Test')
            .quantity(100)
            .create()
            .getRecords();

        List<Campaign> cms = (List<Campaign>) new SObjectBuilder(Campaign.SObjectType)
            .setField(Campaign.Name, 'True_Walk_On_2024')
            .quantity(100)
            .create()
            .getRecords();

        Id rtId = Schema.SObjectType.Exception_And_Notification_History__c.getRecordTypeInfosByName()
            .get(DEVELOPERNAME_EANH_CAMPAIGNMEMBER_LOG)
            .getRecordTypeId();

        List<Exception_And_Notification_History__c> EANHList = new List<Exception_And_Notification_History__c>();
        for (Integer i = 0; i < 100; i++) {
            if (Math.mod(i, 2) == 0) {
                EANHList.add(
                    new Exception_And_Notification_History__c(
                        RecordTypeId = rtId,
                        Object_Type__c = Campaign_Member_Log__e.SObjectType.getDescribe().getName(),
                        Field_Changes__c = JSON.serialize(
                            new CampaignMember(LeadId = lds[i].Id, CampaignId = cms[i].Id)
                        ),
                        Record_Id__c = cms[i].Id + '-null-' + lds[i].Id
                    )
                );
            } else {
                EANHList.add(
                    new Exception_And_Notification_History__c(
                        RecordTypeId = rtId,
                        Object_Type__c = Campaign_Member_Log__e.SObjectType.getDescribe().getName(),
                        Affected_Record_Id__c = JSON.serialize(
                            new CampaignMember(LeadId = lds[i].Id, CampaignId = cms[i].Id)
                        ),
                        Record_Id__c = cms[i].Id + '-null-' + lds[i].Id
                    )
                );
            }
        }

        delete lds;

        insert EANHList;

        Test.startTest();
        Database.executeBatch(new Batchjob_Exception_Error_Reprocess());
        Test.stopTest();

        List<Object> bindings = new List<Object>();
        List<Id> leadIds = new List<Id>();
        List<Id> campaignIds = new List<Id>();
        for (Integer i = 0; i < 100; i++) {
            leadIds.add(lds[i].Id);
            campaignIds.add(cms[i].Id);
        }
        bindings.add(leadIds);
        bindings.add(campaignIds);

        List<CampaignMember> cMemberss = (List<CampaignMember>) new CampaignMemberSelector()
            .selectCampaignMemberByLeadAndCampaignIds(bindings)
            .executeQuery();

        System.assertEquals(0, cMemberss.size(), 'There shouldn\'t exist  campaign members');

        List<Id> EANHIds = new List<Id>();
        for (Integer i = 0; i < 100; i++) {
            EANHIds.add(EANHList[i].Id);
        }
        bindings.clear();
        bindings.add(EANHIds);

        List<Exception_And_Notification_History__c> EANHs = (List<Exception_And_Notification_History__c>) new ExceptionAndNotificationHistorySelector()
            .selectExceptionAndNotificationHistorysByIds(bindings)
            .selectField('attempts__c')
            .executeQuery();

        System.assertEquals(0, EANHs.size(), 'There should exist 0 Exception And Notification History since all records are related to deleted leads');
    }

    @isTest
    public static void testCampaignMemberUpdate_FromCampaignMemberRetryEvent_ShouldDeleteEANH() {
        BatchJobsConfiguration__c setting = new BatchJobsConfiguration__c();
        setting.Name = 'Batchjob_Exception_Error_Reprocess';
        setting.ErrorEmailDistributionList__c = 'test@testgmail.com';
        insert setting;

        List<Lead> lds = (List<Lead>) new SObjectBuilder(Lead.SObjectType)
            .setField(Lead.Company, 'test company')
            .setField(Lead.Email, 'fake@email.com22')
            .setField(Lead.LastName, 'lastName Test')
            .quantity(20)
            .create()
            .getRecords();

        List<Campaign> cms = (List<Campaign>) new SObjectBuilder(Campaign.SObjectType)
            .setField(Campaign.Name, 'True_Walk_On_2024')
            .quantity(20)
            .create()
            .getRecords();

        List<CampaignMember> cmToInsert = new List<CampaignMember>();

        for (Integer i = 0; i < 20; i++) {
            cmToInsert.add(new CampaignMember(LeadId = lds[i].Id, CampaignId = cms[i].Id));
        }

        insert cmToInsert;

        delete lds;

        Id rtId = Schema.SObjectType.Exception_And_Notification_History__c.getRecordTypeInfosByName()
            .get(DEVELOPERNAME_EANH_CAMPAIGNMEMBER_LOG)
            .getRecordTypeId();

        List<Exception_And_Notification_History__c> EANHList = new List<Exception_And_Notification_History__c>();
        for (Integer i = 0; i < 20; i++) {
            CampaignMember cm = cmToInsert[i];
            if (Math.mod(i, 2) == 0) {
                EANHList.add(
                    new Exception_And_Notification_History__c(
                        RecordTypeId = rtId,
                        Object_Type__c = Campaign_Member_Log__e.SObjectType.getDescribe().getName(),
                        Field_Changes__c = JSON.serialize(cm),
                        Record_Id__c = cm.Id
                    )
                );
            } else {
                EANHList.add(
                    new Exception_And_Notification_History__c(
                        RecordTypeId = rtId,
                        Object_Type__c = Campaign_Member_Log__e.SObjectType.getDescribe().getName(),
                        Affected_Record_Id__c = JSON.serialize(cm),
                        Record_Id__c = cm.Id
                    )
                );
            }
        }

        insert EANHList;

        Test.startTest();
        Id batchprocessid = Database.executeBatch(new Batchjob_Exception_Error_Reprocess());
        Test.stopTest();

        List<Object> bindings = new List<Object>();
        List<Id> leadIds = new List<Id>();
        List<Id> campaignIds = new List<Id>();
        for (Integer i = 0; i < 20; i++) {
            leadIds.add(lds[i].Id);
            campaignIds.add(cms[i].Id);
        }
        bindings.add(leadIds);
        bindings.add(campaignIds);

        List<CampaignMember> cMemberss = (List<CampaignMember>) new CampaignMemberSelector()
            .selectCampaignMemberByLeadAndCampaignIds(bindings)
            .executeQuery();

        System.assertEquals(0, cMemberss.size(), 'There shouldn\'t exist  campaign members');

        List<Id> EANHIds = new List<Id>();
        for (Integer i = 0; i < 20; i++) {
            EANHIds.add(EANHList[i].Id);
        }
        bindings.clear();
        bindings.add(EANHIds);

        List<Exception_And_Notification_History__c> EANHs = (List<Exception_And_Notification_History__c>) new ExceptionAndNotificationHistorySelector()
            .selectExceptionAndNotificationHistorysByIds(bindings)
            .selectField('attempts__c')
            .executeQuery();

        System.assertEquals(0, EANHs.size(), 'There should exist 0 Exception And Notification History since all records are related to deleted leads');
    }

    @isTest
    public static void testCampaignMemberUpdateAndInsert_ExistingCampaignMembers_FromCampaignMemberRetryEvent_ShouldEliminateTheEANH() {
        BatchJobsConfiguration__c setting = new BatchJobsConfiguration__c();
        setting.Name = 'Batchjob_Exception_Error_Reprocess';
        setting.ErrorEmailDistributionList__c = 'test@testgmail.com';
        insert setting;

        ByPassTrigger__c bypassTrigger = ByPassTrigger__c.getInstance();
        bypassTrigger.Bypass_Lead_Trigger__c = true;
        bypassTrigger.Bypass_Campaign_Member_Trigger__c = true;
        bypassTrigger.Bypass_Contact_Trigger__c = true;
        insert bypassTrigger;

        List<Lead> lds = (List<Lead>) new SObjectBuilder(Lead.SObjectType)
            .setField(Lead.Company, 'test company')
            .setField(Lead.Email, 'fake@email.com22')
            .setField(Lead.LastName, 'lastName Test')
            .quantity(20)
            .create()
            .getRecords();

        List<Contact> cnts = (List<Contact>) new SObjectBuilder(Contact.SObjectType)
            .setField(Contact.LastName, 'lastName Test')
            .quantity(10)
            .create()
            .getRecords();

        List<Campaign> cms = (List<Campaign>) new SObjectBuilder(Campaign.SObjectType)
            .setField(Campaign.Name, 'True_Walk_On_2024')
            .quantity(20)
            .create()
            .getRecords();

        List<CampaignMember> cmToInsert = new List<CampaignMember>();
        List<CampaignMember> cmExisting = new List<CampaignMember>();

        List<Lead> ldToDelete = new List<Lead>();

        List<Id> leadIds = new List<Id>();
        List<Id> campaignIds = new List<Id>();
        List<Id> contactIds = new List<Id>();

        for (Integer i = 0; i < 20; i++) {
            if (i < 10) {
                cmToInsert.add(new CampaignMember(LeadId = lds[i].Id, CampaignId = cms[i].Id));
                ldToDelete.add(lds[i]);
            } else {
                cmToInsert.add(new CampaignMember(ContactId = cnts[i - 10].Id, CampaignId = cms[i].Id));
                contactIds.add(cnts[i - 10].Id);

                cmExisting.add(new CampaignMember(LeadId = lds[i].Id, CampaignId = cms[i].Id));
            }
            leadIds.add(lds[i].Id);
            campaignIds.add(cms[i].Id);
        }
        insert cmToInsert;
        insert cmExisting;

        delete ldToDelete;
        delete cnts;

        Id rtId = Schema.SObjectType.Exception_And_Notification_History__c.getRecordTypeInfosByName()
            .get(DEVELOPERNAME_EANH_CAMPAIGNMEMBER_LOG)
            .getRecordTypeId();

        List<Exception_And_Notification_History__c> EANHList = new List<Exception_And_Notification_History__c>();
        for (Integer i = 0; i < 20; i++) {
            CampaignMember cm = cmToInsert[i];
            if (Math.mod(i, 2) == 0) {
                EANHList.add(
                    new Exception_And_Notification_History__c(
                        RecordTypeId = rtId,
                        Object_Type__c = Campaign_Member_Log__e.SObjectType.getDescribe().getName(),
                        Field_Changes__c = JSON.serialize(cm),
                        Record_Id__c = cm.Id
                    )
                );
            } else {
                EANHList.add(
                    new Exception_And_Notification_History__c(
                        RecordTypeId = rtId,
                        Object_Type__c = Campaign_Member_Log__e.SObjectType.getDescribe().getName(),
                        Affected_Record_Id__c = JSON.serialize(cm),
                        Record_Id__c = cm.Id
                    )
                );
            }
        }

        for (CampaignMember cm : cmExisting) {
            EANHList.add(
                new Exception_And_Notification_History__c(
                    RecordTypeId = rtId,
                    Object_Type__c = Campaign_Member_Log__e.SObjectType.getDescribe().getName(),
                    Affected_Record_Id__c = JSON.serialize(cm),
                    Record_Id__c = cm.campaignId + '-' + cm.ContactId + '-' + cm.leadId
                )
            );
        }

        insert EANHList;

        Test.startTest();
        Id batchprocessid = Database.executeBatch(new Batchjob_Exception_Error_Reprocess());
        Test.stopTest();

        List<Object> bindings = new List<Object>();

        bindings.add(leadIds);
        bindings.add(campaignIds);
        bindings.add(contactIds);

        List<CampaignMember> cMemberss = (List<CampaignMember>) new CampaignMemberSelector()
            .selectCampaignMembersByLeadAndCampaignORByContactAndCampaign(bindings)
            .executeQuery();

        System.assertEquals(10, cMemberss.size(), 'There shouldn\'t exist  campaign members');

        List<Id> EANHIds = new List<Id>();
        for (Exception_And_Notification_History__c EANH : EANHList) {
            EANHIds.add(EANH.Id);
        }
        bindings.clear();
        bindings.add(EANHIds);

        List<Exception_And_Notification_History__c> EANHs = (List<Exception_And_Notification_History__c>) new ExceptionAndNotificationHistorySelector()
            .selectExceptionAndNotificationHistorysByIds(bindings)
            .selectField('attempts__c')
            .executeQuery();

        System.assertEquals(0, EANHs.size(), 'There should exist 0 Exception And Notification History since all records are related to deleted leads');
    }

    @isTest
    public static void testCampaignMemberUpdateAndInsert_FromCampaignMemberRetryAndLog_ShouldSendAnEmail() {
        BatchJobsConfiguration__c setting = new BatchJobsConfiguration__c();
        setting.Name = 'Batchjob_Exception_Error_Reprocess';
        setting.ErrorEmailDistributionList__c = 'nicolas.gomez@ringcentral.com';
        insert setting;

        Feature_Toggle__c featureToggle = new Feature_Toggle__c();
        featureToggle.CampMemberAsyncRecordQantity__c = 5;
        insert featureToggle;

        ByPassTrigger__c bypassTrigger = ByPassTrigger__c.getInstance();
        bypassTrigger.Bypass_Lead_Trigger__c = true;
        insert bypassTrigger;

        List<Lead> lds = (List<Lead>) new SObjectBuilder(Lead.SObjectType)
            .setField(Lead.Company, 'test company')
            .setField(Lead.Email, 'fake@email.com22')
            .setField(Lead.LastName, 'lastName Test')
            .quantity(100)
            .create()
            .getRecords();

        List<Campaign> cms = (List<Campaign>) new SObjectBuilder(Campaign.SObjectType)
            .setField(Campaign.Name, 'True_Walk_On_2024')
            .quantity(100)
            .create()
            .getRecords();

        List<Marketing_Asset__c> mAssets = (List<Marketing_Asset__c>) new SObjectBuilder(Marketing_Asset__c.SObjectType)
            .quantity(50)
            .create()
            .getRecords();

        Id rtId = Schema.SObjectType.Exception_And_Notification_History__c.getRecordTypeInfosByName()
            .get(DEVELOPERNAME_EANH_CAMPAIGNMEMBER_LOG)
            .getRecordTypeId();

        List<CampaignMemberRetry__e> cmRetriesEvents = new List<CampaignMemberRetry__e>();

        List<Lead> leadsToDelete = new List<Lead>();

        for (Integer i = 0; i < 50; i++) {
            cmRetriesEvents.add(
                new CampaignMemberRetry__e(
                    CampaignId__c = cms[i].Id,
                    LeadId__c = lds[i].Id,
                    Primary_Marketing_Asset__c = mAssets[i].Id,
                    Trigger_On__c = math.mod(i, 2) == 0
                )
            );
            if (Math.mod(i, 2) == 0) {
                leadsToDelete.add(lds[i]);
            }
        }

        List<CampaignMember> cMembersToInsert = new List<CampaignMember>();

        for (Integer i = 50; i < 75; i++) {
            cMembersToInsert.add(new CampaignMember(LeadId = lds[i].Id, CampaignId = cms[i].Id));
            if (Math.mod(i, 2) == 0) {
                leadsToDelete.add(lds[i]);
            }
        }

        List<CampaignMember> cMembersToUpdate = new List<CampaignMember>();

        for (Integer i = 75; i < 100; i++) {
            cMembersToUpdate.add(
                new CampaignMember(
                    LeadId = lds[i].Id,
                    CampaignId = cms[i].Id,
                    Asset_Name__c = 'Test',
                    Asset_Type__c = '22'
                )
            );
            if (Math.mod(i, 2) == 0) {
                leadsToDelete.add(lds[i]);
            }
        }

        insert cMembersToUpdate;

        List<Exception_And_Notification_History__c> EANHList = new List<Exception_And_Notification_History__c>();

        //CAMPAIGNMEMBERRETRY ONLY INSERT
        for (CampaignMemberRetry__e cmRetriesEvent : cmRetriesEvents) {
            EANHList.add(
                new Exception_and_Notification_History__c(
                    RecordTypeId = rtId,
                    Object_Type__c = campaignMemberRetry__e.SObjectType.getDescribe().getName(),
                    Affected_record_ID__c = JSON.serialize(cmRetriesEvent),
                    Exception__c = 'System.DmlException',
                    Exception_desc__c = 'Desc',
                    attempts__c = 50
                )
            );
        }

        //CAMPAIGNMEMBERLOG FOR INSERT
        Integer i = 0;
        for (CampaignMember cm : cMembersToInsert) {
            if (Math.mod(i++, 2) == 0) {
                EANHList.add(
                    new Exception_And_Notification_History__c(
                        RecordTypeId = rtId,
                        Object_Type__c = Campaign_Member_Log__e.SObjectType.getDescribe().getName(),
                        Field_Changes__c = JSON.serialize(cm),
                        Record_Id__c = cm.CampaignId + '-' + cm.ContactId + '-' + cm.LeadId,
                        attempts__c = 50
                    )
                );
            } else {
                EANHList.add(
                    new Exception_And_Notification_History__c(
                        RecordTypeId = rtId,
                        Object_Type__c = Campaign_Member_Log__e.SObjectType.getDescribe().getName(),
                        Affected_Record_Id__c = JSON.serialize(cm),
                        Record_Id__c = cm.CampaignId + '-' + cm.ContactId + '-' + cm.LeadId,
                        attempts__c = 50
                    )
                );
            }
        }

        i = 0;
        //CAMPAIGNMEMBERLOG FOR UPDATE
        for (CampaignMember cm : cMembersToUpdate) {
            if (Math.mod(i++, 2) == 0) {
                EANHList.add(
                    new Exception_And_Notification_History__c(
                        RecordTypeId = rtId,
                        Object_Type__c = Campaign_Member_Log__e.SObjectType.getDescribe().getName(),
                        Field_Changes__c = JSON.serialize(cm),
                        Record_Id__c = cm.Id,
                        attempts__c = 50
                    )
                );
            } else {
                EANHList.add(
                    new Exception_And_Notification_History__c(
                        RecordTypeId = rtId,
                        Object_Type__c = Campaign_Member_Log__e.SObjectType.getDescribe().getName(),
                        Affected_Record_Id__c = JSON.serialize(cm),
                        Record_Id__c = cm.Id,
                        attempts__c = 50
                    )
                );
            }
        }
        insert EANHList;

        Batchjob_Exception_Error_Reprocess batch = new Batchjob_Exception_Error_Reprocess();
        Test.startTest();
        delete leadsToDelete;
        Id batchprocessid = Database.executeBatch(batch);
        Test.stopTest();
        System.assertEquals(
            0,
            Batchjob_Exception_Error_Reprocess.emailInfoForTesting.getTotalSuccessCampaignMember()
        );
        System.assertEquals(
            0,
            Batchjob_Exception_Error_Reprocess.emailInfoForTesting.getTotalFailedCampaignMembersWithId()
        );
        System.assertEquals(
            0,
            Batchjob_Exception_Error_Reprocess.emailInfoForTesting.getTotalFailedCampaignMembersWithoutId()
        );
        System.assertEquals(
            25,
            Batchjob_Exception_Error_Reprocess.emailInfoForTesting.getTotalFailedCampaignMembersWithIdAndPassTheMaxAttempts()
        );
        System.assertEquals(
            75,
            Batchjob_Exception_Error_Reprocess.emailInfoForTesting.getTotalFailedCampaignMembersWithoutIdAndPassTheMaxAttempts()
        );
    }

    @isTest
    public static void testCampaignMemberUpdate_CMLastModifiedDate_GreatherThan_EANHCreatedDate_FromCampaignMemberLog() {
        BatchJobsConfiguration__c setting = new BatchJobsConfiguration__c();
        setting.Name = 'Batchjob_Exception_Error_Reprocess';
        setting.ErrorEmailDistributionList__c = 'nicolas.gomez@ringcentral.com';
        insert setting;

        Feature_Toggle__c featureToggle = new Feature_Toggle__c();
        featureToggle.CampMemberAsyncRecordQantity__c = 5;
        insert featureToggle;

        ByPassTrigger__c bypassTrigger = ByPassTrigger__c.getInstance();
        bypassTrigger.Bypass_Lead_Trigger__c = true;
        insert bypassTrigger;

        List<Lead> lds = (List<Lead>) new SObjectBuilder(Lead.SObjectType)
            .setField(Lead.Company, 'test company')
            .setField(Lead.Email, 'fake@email.com22')
            .setField(Lead.LastName, 'lastName Test')
            .quantity(100)
            .create()
            .getRecords();

        List<Campaign> cms = (List<Campaign>) new SObjectBuilder(Campaign.SObjectType)
            .setField(Campaign.Name, 'True_Walk_On_2024')
            .quantity(100)
            .create()
            .getRecords();

        Id rtId = Schema.SObjectType.Exception_And_Notification_History__c.getRecordTypeInfosByName()
            .get(DEVELOPERNAME_EANH_CAMPAIGNMEMBER_LOG)
            .getRecordTypeId();

        List<CampaignMember> cMembersToUpdate = new List<CampaignMember>();

        for (Integer i = 0; i < 100; i++) {
            cMembersToUpdate.add(
                new CampaignMember(
                    LeadId = lds[i].Id,
                    CampaignId = cms[i].Id,
                    Asset_Name__c = 'Test',
                    Asset_Type__c = '22'
                )
            );
        }

        insert cMembersToUpdate;

        List<Exception_And_Notification_History__c> EANHList = new List<Exception_And_Notification_History__c>();
        integer i = 0;
        //CAMPAIGNMEMBERLOG FOR UPDATE
        for (CampaignMember cm : cMembersToUpdate) {
            if (Math.mod(i++, 2) == 0) {
                EANHList.add(
                    new Exception_And_Notification_History__c(
                        RecordTypeId = rtId,
                        Object_Type__c = Campaign_Member_Log__e.SObjectType.getDescribe().getName(),
                        Field_Changes__c = JSON.serialize(cm),
                        Record_Id__c = cm.Id,
                        attempts__c = 50
                    )
                );
            } else {
                EANHList.add(
                    new Exception_And_Notification_History__c(
                        RecordTypeId = rtId,
                        Object_Type__c = Campaign_Member_Log__e.SObjectType.getDescribe().getName(),
                        Affected_Record_Id__c = JSON.serialize(cm),
                        Record_Id__c = cm.Id,
                        attempts__c = 50
                    )
                );
            }
        }
        insert EANHList;

        User marketingUser = (User) new SObjectBuilder(User.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(User.SObjectType))
            .setFields(new Map<SObjectField, Object> {
                User.UserPermissionsMarketingUser => true,
                User.UserName => 'marketingUser@user.com',
                User.CommunityNickname => 'marketingTest1'
            })
            .create()
            .getRecord();


        System.runAs(marketingUser) {
            for(CampaignMember cm : cMembersToUpdate) {
                cm.Asset_Name__c = 'modified :D';
                cm.Asset_Type__c = 'modifiedx2 :D';
            }
            update cMembersToUpdate;
        }
        
        Test.startTest();
        	Database.executeBatch(new Batchjob_Exception_Error_Reprocess());
        Test.stopTest();
        
        System.assertEquals(
            0, 
            new ExceptionAndNotificationHistorySelector()
            .selectExceptionAndNotificationHistorysByIds(new object[]{EANHList})
            .executeQuery()
            .size(),
            'There shouldn\'t be an Exception and notification history sObject created.'
        );
    }

    @isTest
    public static void testCampaignMemberUpdateAndInsert_usingContacts_FromCampaignMemberRetryEventAndLogEvent_ShouldInsertAndUpdate() {
        BatchJobsConfiguration__c setting = new BatchJobsConfiguration__c();
        setting.Name = 'Batchjob_Exception_Error_Reprocess';
        setting.ErrorEmailDistributionList__c = 'test@testgmail.com';
        insert setting;

        ByPassTrigger__c bypassTrigger = ByPassTrigger__c.getInstance();
        bypassTrigger.Bypass_Lead_Trigger__c = true;
        bypassTrigger.Bypass_Campaign_Member_Trigger__c = true;
        bypassTrigger.Bypass_Contact_Trigger__c = true;
        insert bypassTrigger;

        RingCentralVariousSettings__c settings = RingCentralVariousSettings__c.getOrgDefaults();
        settings.Report_Id_Campaign_Member_Insert__c = 'test1';
        settings.Report_Id_Campaign_Member_Update__c = 'test2';
        settings.Report_Id_Reprocess_CM_Update__c = 'test3';
        settings.Report_Id_Reprocess_CM_Insert__c = 'test4';
        upsert settings;

        List<Contact> cnts = (List<Contact>) new SObjectBuilder(Contact.SObjectType)
            .setField(Contact.LastName, 'lastName Test')
            .quantity(100)
            .create()
            .getRecords();

        List<Campaign> cms = (List<Campaign>) new SObjectBuilder(Campaign.SObjectType)
            .setField(Campaign.Name, 'True_Walk_On_2024')
            .quantity(100)
            .create()
            .getRecords();

        List<Marketing_Asset__c> mAssets = (List<Marketing_Asset__c>) new SObjectBuilder(Marketing_Asset__c.SObjectType)
            .quantity(50)
            .create()
            .getRecords();

        Id rtId = Schema.SObjectType.Exception_And_Notification_History__c.getRecordTypeInfosByName()
            .get(DEVELOPERNAME_EANH_CAMPAIGNMEMBER_LOG)
            .getRecordTypeId();

        List<Exception_And_Notification_History__c> EANHList = new List<Exception_And_Notification_History__c>();
        
        List<CampaignMember> campaignMembersToInsert = new List<CampaignMember>();
        
        for (Integer i = 75; i < 100; i++) {
                CampaignMember cm = new CampaignMember(
                    ContactId = cnts[i].Id,
                    CampaignId = cms[i].Id
                );
                campaignMembersToInsert.add(cm);
        }

        insert campaignMembersToInsert;

        for (Integer i = 0; i < 100; i++) {
            if (i < 50) {
                CampaignMemberRetry__e cmRetry = new CampaignMemberRetry__e(
                    CampaignId__c = cms[i].Id,
                    ContactId__c = cnts[i].Id,
                    Primary_Marketing_Asset__c = mAssets[i].Id,
                    Trigger_On__c = math.mod(i, 2) == 0
                );
                EANHList.add(
                    new Exception_And_Notification_History__c(
                        RecordTypeId = rtId,
                        Object_Type__c = CampaignMemberRetry__e.SObjectType.getDescribe().getName(),
                        Affected_record_ID__c = JSON.serialize(cmRetry),
                        Exception__c = 'Test.TestException',
                        Exception_desc__c = 'Description about exception'
                    )
                );
            } else if (i < 75){
                //For insert
                CampaignMember cm = new CampaignMember(
                    ContactId = cnts[i].Id,
                    CampaignId = cms[i].Id
                );
                EANHList.add(
                    new Exception_And_Notification_History__c(
                        RecordTypeId = rtId,
                        Object_Type__c = Campaign_Member_Log__e.SObjectType.getDescribe().getName(),
                        Affected_Record_Id__c = JSON.serialize(cm),
                        Record_Id__c = cms[i].Id + '-' + cnts[i].Id + '-' + 'null'
                    )
                );
            } else {
                //for update
                EANHList.add(
                    new Exception_And_Notification_History__c(
                        RecordTypeId = rtId,
                        Object_Type__c = Campaign_Member_Log__e.SObjectType.getDescribe().getName(),
                        Affected_Record_Id__c = JSON.serialize(campaignMembersToInsert[i-75]),
                        Record_Id__c = campaignMembersToInsert[i-75].Id
                    )
                );
            }
        }

        insert EANHList;

        Test.startTest();
            Id batchprocessid = Database.executeBatch(new Batchjob_Exception_Error_Reprocess());
        Test.stopTest();

        System.assertEquals(
            100, 
            new CampaignMemberSelector()
                .selectCampaignMembersByLeadAndCampaignORByContactAndCampaign(new object[]{
                    new Lead[]{},
                    cms,
                    cnts
                })
                .executeQuery()
                .size(),
            'There should exist 100 campaign members'
        );

        System.assertEquals(
            0, 
            new ExceptionAndNotificationHistorySelector()
                .selectExceptionAndNotificationHistorysByIds(new object[]{EANHList})
                .executeQuery()
                .size(), 
            'There should\'nt exist Exception And Notification History sObject.'
        );

        Map<Exception_Error_Reprocess_Helper.REPORT_TYPES, String> reports = Batchjob_Exception_Error_Reprocess.emailInfoForTesting.getReportsUrl();
        system.assert(reports.get(Exception_Error_Reprocess_Helper.REPORT_TYPES.UPDATE_WITH_MORE_5_ATTEMPS).contains('my.salesforce.com/test2'), 'It should contains "test2"');
        system.assert(reports.get(Exception_Error_Reprocess_Helper.REPORT_TYPES.INSERT_WITH_MORE_5_ATTEMPS).contains('my.salesforce.com/test1'), 'It should contains "test1"');
        system.assert(reports.get(Exception_Error_Reprocess_Helper.REPORT_TYPES.INSERT_WITH_LESS_5_ATTEMPS).contains('my.salesforce.com/test4'), 'It should contains "test4"');
        system.assert(reports.get(Exception_Error_Reprocess_Helper.REPORT_TYPES.UPDATE_WITH_LESS_5_ATTEMPS).contains('my.salesforce.com/test3'), 'It should contains "test3"');
    }
}