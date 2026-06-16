@isTest
private class Test_CampaignMemberPlatEvents {
    @TestSetup
    static void createTestData() {
        List<Campaign> camps = (List<Campaign>) new SObjectBuilder(Campaign.SObjectType)
            .setField(Campaign.Name, 'Camp Test')
            .setField(Campaign.Sell_Type__c, 'New Business')
            .setField(Campaign.Status, 'Planned')
            .setField(Campaign.Sub_Channel__c, 'Affiliate Window')
            .setField(Campaign.Intended_Product__c, 'AU Contact Center')
            .setField(Campaign.BMID__c, 'BMID')
            .quantity(10)
            .build()
            .getRecords();

        List<Campaign> campsToUpdate = new List<Campaign>();
        integer i = 1;
        for (Campaign camp : camps) {
            camp.Name = 'Camp Test ' + i;
            camp.BMID__c = 'BMID ' + i;
            camp.Non_Attributable__c = true;
            i++;
            campsToUpdate.add(camp);
        }

        campsToUpdate.add(
            (Campaign) new SObjectBuilder(Campaign.SObjectType)
                .setField(Campaign.Name, 'RC_Mitel Test')
                .setField(Campaign.Sell_Type__c, 'New Business')
                .setField(Campaign.Status, 'Planned')
                .setField(Campaign.Sub_Channel__c, 'Affiliate Window')
                .setField(Campaign.Intended_Product__c, 'AU Contact Center')
                .build()
                .getRecord()
        );

        campsToUpdate.add(
            (Campaign) new SObjectBuilder(Campaign.SObjectType)
                .setField(Campaign.Name, 'Mitel_Agency_Unassigned')
                .setField(Campaign.Sell_Type__c, 'New Business')
                .setField(Campaign.Status, 'Planned')
                .setField(Campaign.Sub_Channel__c, 'Affiliate Window')
                .setField(Campaign.Intended_Product__c, 'AU Contact Center')
                .build()
                .getRecord()
        );

        insert campsToUpdate;

        Feature_Toggle__c featureToggle = new Feature_Toggle__c();
        featureToggle.CampMemberAsyncRecordQantity__c = 5;
        featureToggle.CampMemberCreationRetriesAttempts__c = 1;
        featureToggle.Mitel_Campaign_Member_sync__c = 5;
        insert featureToggle;
    }
    @isTest
    private static void testCampaignMemberCreationAsyncFromLead() {
        List<Lead> lds = (List<Lead>) new SObjectBuilder(Lead.SObjectType)
            .setField(Lead.LastName, 'Lead Test')
            .setField(Lead.Status, 'X. Suspect')
            .setField(Lead.Email, 'testemail@testemail.com')
            .setField(Lead.Phone, '123456')
            .setField(Lead.LeadSource, 'FR Office Weblead')
            .setField(Lead.BMID__c, 'BMID')
            .quantity(6)
            .build()
            .getRecords();

        List<Lead> ldsToUpdate = new List<Lead>();
        integer i = 1;
        for (lead ld : lds) {
            ld.LastName = 'Lead Test' + i;
            ld.BMID__c = 'BMID ' + i;
            i++;
            ldsToUpdate.add(ld);
        }
        Test.startTest();
        insert ldsToUpdate;
        Test.stopTest();

        List<CampaignMember> campMembCreated = (List<CampaignMember>) new CampaignMemberSelector()
            .selectCampaignMemberForLeadConvert()
            .executeQuery();
        System.assertEquals(6, campMembCreated.size(), 'CampaignMember was not created');
    }
    @isTest
    private static void testCampaignMemberUpdateAsync() {
        List<Lead> lds = (List<Lead>) new SObjectBuilder(Lead.SObjectType)
            .setField(Lead.LastName, 'Lead Test')
            .setField(Lead.Status, 'X. Suspect')
            .setField(Lead.Email, 'testemail@testemail.com')
            .setField(Lead.Phone, '123456')
            .setField(Lead.LeadSource, 'FR Office Weblead')
            .setField(Lead.BMID__c, 'BMID')
            .quantity(5)
            .build()
            .getRecords();

        List<Lead> ldsToInsert = new List<Lead>();
        integer i = 1;
        for (lead ld : lds) {
            ld.LastName = 'Lead Test' + i;
            ld.BMID__c = 'BMID ' + i;
            i++;
            ldsToInsert.add(ld);
        }
        insert ldsToInsert;

        List<Lead> leadsCreated = [SELECT Id, BMID__c FROM Lead WHERE lastname LIKE 'Lead Test%'];
        List<Lead> ldsToUpdate = new List<Lead>();
        integer j = 1;
        for (lead ld : leadsCreated) {
            ld.BMID__c = 'BMID ' + (j + 1);
            ld.Status = '2. Contacted';
            j++;
            ldsToUpdate.add(ld);
        }
        Feature_Toggle__c featureToogle = Feature_Toggle__c.getOrgDefaults();
        featureToogle.CampMemberAsyncRecordQantity__c = 4;
        update featureToogle;
        Test.startTest();
        update ldsToUpdate;
        Test.stopTest();

        List<CampaignMember> campMembCreated = (List<CampaignMember>) new CampaignMemberSelector()
            .selectCampaignMemberForLeadConvert()
            .executeQuery();
        System.assertEquals(10, campMembCreated.size(), 'CampaignMember was not created');
    }
    @isTest
    private static void testPublishCampaignMemberEventWithErrorForTriggerOn() {
        User marketingUser = (User) new SObjectBuilder(User.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(User.SObjectType))
            .setFields(new Map<SObjectField, Object> {
                User.UserPermissionsMarketingUser => true,
                User.UserName => 'marketingUser@user.com',
                User.CommunityNickname => 'marketingTest1'
            })
            .create()
            .getRecord();
        
        List<Campaign> camps = (List<Campaign>) new SObjectBuilder(Campaign.SObjectType)
            .setField(Campaign.Name, 'Camp Test')
            .setField(Campaign.Sell_Type__c, 'New Business')
            .setField(Campaign.Status, 'Planned')
            .setField(Campaign.Sub_Channel__c, 'Affiliate Window')
            .setField(Campaign.Intended_Product__c, 'AU Contact Center')
            .setField(Campaign.BMID__c, 'BMID')
            .quantity(1)
            .createAsUser(marketingUser)
            .getRecords();

        List<Lead> lds = (List<Lead>) new SObjectBuilder(Lead.SObjectType)
            .setField(Lead.LastName, 'Lead Test')
            .setField(Lead.Status, 'X. Suspect')
            .setField(Lead.Email, 'testemail@testemail.com')
            .setField(Lead.Phone, '123456')
            .setField(Lead.LeadSource, 'FR Office Weblead')
            .setField(Lead.BMID__c, 'BMID')
            .quantity(1)
            .create()
            .getRecords();

        List<CampaignMember> campMembs = (List<CampaignMember>) new SObjectBuilder(CampaignMember.SObjectType)
            .setField(CampaignMember.CampaignId, camps[0].id)
            .setField(CampaignMember.LeadId, lds[0].id)
            .quantity(5)
            .build()
            .getRecords();

        Test.startTest();
        CampaignMemberPlatEvents.campaignMemberCreationAsyncFromLead(campMembs, true);
        Test.stopTest();

        List<CampaignMember> campMembCreated = (List<CampaignMember>) new CampaignMemberSelector()
            .selectCampaignMemberForLeadConvert()
            .executeQuery();
        System.assertEquals(1, campMembCreated.size(), 'CampaignMember was not created');
    }
    @isTest
    private static void testPublishCampaignMemberEventWithErrorForTriggerOff() {
        User marketingUser = (User) new SObjectBuilder(User.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(User.SObjectType))
            .setFields(new Map<SObjectField, Object> {
                User.UserPermissionsMarketingUser => true,
                    User.UserName => 'marketingUser@user.com',
                    User.CommunityNickname => 'marketingTest1'
                    })
            .create()
            .getRecord(); 
        
        List<Campaign> camps = (List<Campaign>) new SObjectBuilder(Campaign.SObjectType)
            .setField(Campaign.Name, 'Camp Test')
            .setField(Campaign.Sell_Type__c, 'New Business')
            .setField(Campaign.Status, 'Planned')
            .setField(Campaign.Sub_Channel__c, 'Affiliate Window')
            .setField(Campaign.Intended_Product__c, 'AU Contact Center')
            .setField(Campaign.BMID__c, 'BMID')
            .quantity(1)
            .createAsUser(marketingUser)
            .getRecords();

        List<Lead> lds = (List<Lead>) new SObjectBuilder(Lead.SObjectType)
            .setField(Lead.LastName, 'Lead Test')
            .setField(Lead.Status, 'X. Suspect')
            .setField(Lead.Email, 'testemail@testemail.com')
            .setField(Lead.Phone, '123456')
            .setField(Lead.LeadSource, 'FR Office Weblead')
            .setField(Lead.BMID__c, 'BMID')
            .quantity(1)
            .create()
            .getRecords();

        List<CampaignMember> campMembs = (List<CampaignMember>) new SObjectBuilder(CampaignMember.SObjectType)
            .setField(CampaignMember.CampaignId, camps[0].id)
            .setField(CampaignMember.LeadId, lds[0].id)
            .quantity(5)
            .build()
            .getRecords();

        Test.startTest();
        CampaignMemberPlatEvents.campaignMemberCreationAsyncFromLead(campMembs, false);
        Test.stopTest();

        List<CampaignMember> campMembCreated = (List<CampaignMember>) new CampaignMemberSelector()
            .selectCampaignMemberForLeadConvert()
            .executeQuery();
        System.assertEquals(1, campMembCreated.size(), 'CampaignMember was not created');
    }

    @isTest
    private static void testPublishCampaignMemberRetryEventWithErrorForTriggerOn() {
        Feature_Toggle__c featureToogle = Feature_Toggle__c.getOrgDefaults();
        featureToogle.CampMemberCreationRetriesAttempts__c = 0;
        update featureToogle;
		
        User marketingUser = (User) new SObjectBuilder(User.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(User.SObjectType))
            .setFields(new Map<SObjectField, Object> {
                User.UserPermissionsMarketingUser => true,
                User.UserName => 'marketingUser@user.com',
                User.CommunityNickname => 'marketingTest1'
            })
            .create()
            .getRecord();
        List<Campaign> camps = (List<Campaign>) new SObjectBuilder(Campaign.SObjectType)
            .setField(Campaign.Name, 'Camp Test')
            .setField(Campaign.Sell_Type__c, 'New Business')
            .setField(Campaign.Status, 'Planned')
            .setField(Campaign.Sub_Channel__c, 'Affiliate Window')
            .setField(Campaign.Intended_Product__c, 'AU Contact Center')
            .setField(Campaign.BMID__c, 'BMID')
            .quantity(1)
            .createAsUser(marketingUser)
            .getRecords();

        List<Lead> lds = (List<Lead>) new SObjectBuilder(Lead.SObjectType)
            .setField(Lead.LastName, 'Lead Test')
            .setField(Lead.Status, 'X. Suspect')
            .setField(Lead.Email, 'testemail@testemail.com')
            .setField(Lead.Phone, '123456')
            .setField(Lead.LeadSource, 'FR Office Weblead')
            .setField(Lead.BMID__c, 'BMID')
            .quantity(1)
            .create()
            .getRecords();

        List<CampaignMember> campMembs = (List<CampaignMember>) new SObjectBuilder(CampaignMember.SObjectType)
            .setField(CampaignMember.CampaignId, camps[0].id)
            .setField(CampaignMember.LeadId, lds[0].id)
            .quantity(5)
            .build()
            .getRecords();
        List<CampaignMemberRetry__e> campaignMemberRetriesEventsOn = new List<CampaignMemberRetry__e>();
        List<CampaignMemberRetry__e> campaignMemberRetriesEventsOff = new List<CampaignMemberRetry__e>();

        for (CampaignMember camp : campMembs) {
            campaignMemberRetriesEventsOn.add(
                new CampaignMemberRetry__e(
                    CampaignId__c = camp.CampaignId,
                    LeadId__c = camp.LeadId,
                    Primary_Marketing_Asset__c = camp.Primary_Marketing_Asset__c,
                    Trigger_On__c = true
                )
            );
        }

        Test.startTest();
        PlatformEvents.publishPlatformEvent(campaignMemberRetriesEventsOn, 'CampaignMemberCreationEvent');
        PlatformEvents.publishPlatformEvent(campaignMemberRetriesEventsOff, 'CampaignMemberCreationEvent');
        Test.stopTest();

        List<Exception_and_notification_history__c> lstExceptions = (List<Exception_and_notification_history__c>) new ExceptionAndNotificationHistorySelector()
            .selectExceptionAndNotificationHistorys()
            .selectFields(
                new List<String>{
                    'object_type__c',
                    'Affected_record_ID__c',
                    'Exception__c',
                    'RecordTypeId',
                    'Exception_desc__c'
                }
            )
            .executeQuery();
        System.assertEquals(5, lstExceptions.size(), 'Exception were not created');
    }

    @isTest
    private static void testPublishCampaignMemberRetryEventWithErrorForTriggerOff() {
        Feature_Toggle__c featureToogle = Feature_Toggle__c.getOrgDefaults();
        featureToogle.CampMemberCreationRetriesAttempts__c = 0;
        update featureToogle;
	
        User marketingUser = (User) new SObjectBuilder(User.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(User.SObjectType))
            .setFields(new Map<SObjectField, Object> {
                User.UserPermissionsMarketingUser => true,
                User.UserName => 'marketingUser@user.com',
                User.CommunityNickname => 'marketingTest1'
            })
            .create()
            .getRecord();
        
        List<Campaign> camps = (List<Campaign>) new SObjectBuilder(Campaign.SObjectType)
            .setField(Campaign.Name, 'Camp Test')
            .setField(Campaign.Sell_Type__c, 'New Business')
            .setField(Campaign.Status, 'Planned')
            .setField(Campaign.Sub_Channel__c, 'Affiliate Window')
            .setField(Campaign.Intended_Product__c, 'AU Contact Center')
            .setField(Campaign.BMID__c, 'BMID')
            .quantity(1)
            .createAsUser(marketingUser)
            .getRecords();

        List<Lead> lds = (List<Lead>) new SObjectBuilder(Lead.SObjectType)
            .setField(Lead.LastName, 'Lead Test')
            .setField(Lead.Status, 'X. Suspect')
            .setField(Lead.Email, 'testemail@testemail.com')
            .setField(Lead.Phone, '123456')
            .setField(Lead.LeadSource, 'FR Office Weblead')
            .setField(Lead.BMID__c, 'BMID')
            .quantity(1)
            .create()
            .getRecords();

        List<CampaignMember> campMembs = (List<CampaignMember>) new SObjectBuilder(CampaignMember.SObjectType)
            .setField(CampaignMember.CampaignId, camps[0].id)
            .setField(CampaignMember.LeadId, lds[0].id)
            .quantity(5)
            .build()
            .getRecords();
        List<CampaignMemberRetry__e> campaignMemberRetriesEventsOn = new List<CampaignMemberRetry__e>();
        List<CampaignMemberRetry__e> campaignMemberRetriesEventsOff = new List<CampaignMemberRetry__e>();

        for (CampaignMember camp : campMembs) {
            campaignMemberRetriesEventsOn.add(
                new CampaignMemberRetry__e(
                    CampaignId__c = camp.CampaignId,
                    LeadId__c = camp.LeadId,
                    Primary_Marketing_Asset__c = camp.Primary_Marketing_Asset__c,
                    Trigger_On__c = false
                )
            );
        }

        Test.startTest();
        PlatformEvents.publishPlatformEvent(campaignMemberRetriesEventsOn, 'CampaignMemberCreationEvent');
        PlatformEvents.publishPlatformEvent(campaignMemberRetriesEventsOff, 'CampaignMemberCreationEvent');
        Test.stopTest();

        List<Exception_and_notification_history__c> lstExceptions = (List<Exception_and_notification_history__c>) new ExceptionAndNotificationHistorySelector()
            .selectExceptionAndNotificationHistorys()
            .selectFields(
                new List<String>{
                    'object_type__c',
                    'Affected_record_ID__c',
                    'Exception__c',
                    'RecordTypeId',
                    'Exception_desc__c'
                }
            )
            .executeQuery();
        System.assertEquals(5, lstExceptions.size(), 'Exception were not created');
    }

    @isTest
    private static void testCampaignMemberCreationSync() {
        List<Lead> lds = (List<Lead>) new SObjectBuilder(Lead.SObjectType)
            .setField(Lead.LastName, 'Lead Test')
            .setField(Lead.Status, 'X. Suspect')
            .setField(Lead.Email, 'testemail@testemail.com')
            .setField(Lead.Phone, '123456')
            .setField(Lead.LeadSource, 'FR Office Weblead')
            .setField(Lead.BMID__c, 'BMID')
            .quantity(10)
            .create()
            .getRecords();

        Feature_Toggle__c featureToogle = Feature_Toggle__c.getOrgDefaults();
        featureToogle.CampMemberAsyncRecordQantity__c = 10;
        update featureToogle;

        Test.startTest();
        List<Campaign> campaign = [SELECT Id FROM Campaign WHERE Name = 'Camp Test 1' LIMIT 1];
        set<id> ldIds = new Set<id>();
        for (Lead ld : [SELECT Id, BMID__c FROM Lead WHERE lastname LIKE 'Lead Test']) {
            ldIds.add(ld.Id);
        }
        List<CampaignMember> cmToInsert = new List<CampaignMember>();
        for (id ldId : ldIds) {
            cmToInsert.add(new CampaignMember(CampaignId = campaign[0].Id, LeadId = ldId));
        }
        insert cmToInsert;
        try {
            List<CampaignMember> cmToInsertDuplicated = new List<CampaignMember>();
            for (id ldId : ldIds) {
                cmToInsertDuplicated.add(new CampaignMember(CampaignId = campaign[0].Id, LeadId = ldId));
            }
            insert cmToInsertDuplicated;
        } catch (Exception ex) {
            List<Exception_and_notification_history__c> lstExceptions = (List<Exception_and_notification_history__c>) new ExceptionAndNotificationHistorySelector()
                .selectExceptionAndNotificationHistorys()
                .selectFields(
                    new List<String>{
                        'object_type__c',
                        'Affected_record_ID__c',
                        'Exception__c',
                        'RecordTypeId',
                        'Exception_desc__c'
                    }
                )
                .executeQuery();
            System.assertEquals(0, lstExceptions.size(), 'Exception were  created');
        }

        Test.stopTest();

        List<CampaignMember> campMembCreated = (List<CampaignMember>) new CampaignMemberSelector()
            .selectCampaignMemberForLeadConvert()
            .executeQuery();
        System.assertEquals(10, campMembCreated.size(), 'CampaignMember was not created');

        List<Exception_and_notification_history__c> lstExceptions = (List<Exception_and_notification_history__c>) new ExceptionAndNotificationHistorySelector()
            .selectExceptionAndNotificationHistorys()
            .selectFields(
                new List<String>{
                    'object_type__c',
                    'Affected_record_ID__c',
                    'Exception__c',
                    'RecordTypeId',
                    'Exception_desc__c'
                }
            )
            .executeQuery();
        System.assertEquals(0, lstExceptions.size(), 'Exception were  created');
    }

    @isTest
    private static void testCampaignMemberCreationAsync() {
        List<Lead> lds = (List<Lead>) new SObjectBuilder(Lead.SObjectType)
            .setField(Lead.LastName, 'Lead Test')
            .setField(Lead.Status, 'X. Suspect')
            .setField(Lead.Email, 'testemail@testemail.com')
            .setField(Lead.Phone, '123456')
            .setField(Lead.LeadSource, 'FR Office Weblead')
            .setField(Lead.BMID__c, 'BMID')
            .quantity(10)
            .create()
            .getRecords();

        Feature_Toggle__c featureToogle = Feature_Toggle__c.getOrgDefaults();
        featureToogle.CampMemberAsyncRecordQantity__c = 9;
        update featureToogle;

        Test.startTest();
        List<Campaign> campaign = [SELECT Id FROM Campaign WHERE Name = 'Camp Test 1' LIMIT 1];
        set<id> ldIds = new Set<id>();
        for (Lead ld : [SELECT Id, BMID__c FROM Lead WHERE lastname LIKE 'Lead Test']) {
            ldIds.add(ld.Id);
        }
        List<CampaignMember> cmToInsert = new List<CampaignMember>();
        for (id ldId : ldIds) {
            cmToInsert.add(new CampaignMember(CampaignId = campaign[0].Id, LeadId = ldId));
        }
        insert cmToInsert;
        Test.getEventBus().deliver();
        try {
            List<CampaignMember> cmToInsertDuplicated = new List<CampaignMember>();
            for (id ldId : ldIds) {
                cmToInsertDuplicated.add(new CampaignMember(CampaignId = campaign[0].Id, LeadId = ldId));
            }
            insert cmToInsertDuplicated;
            Test.getEventBus().deliver();
        } catch (Exception ex) {
            List<Exception_and_notification_history__c> lstExceptions = (List<Exception_and_notification_history__c>) new ExceptionAndNotificationHistorySelector()
                .selectExceptionAndNotificationHistorys()
                .selectFields(
                    new List<String>{
                        'object_type__c',
                        'Affected_record_ID__c',
                        'Exception__c',
                        'RecordTypeId',
                        'Exception_desc__c'
                    }
                )
                .executeQuery();
        }

        Test.stopTest();

        List<CampaignMember> campMembCreated = (List<CampaignMember>) new CampaignMemberSelector()
            .selectCampaignMemberForLeadConvert()
            .executeQuery();
        System.assertEquals(10, campMembCreated.size(), 'CampaignMember was not created');
    }

    @isTest
    private static void testCampaignMemberCreationForContacts() {
        List<Campaign> campaign = [SELECT Id FROM Campaign WHERE Name = 'Camp Test 1' LIMIT 1];

        Feature_Toggle__c featureToogle = Feature_Toggle__c.getOrgDefaults();
        featureToogle.CampMemberAsyncRecordQantity__c = 9;
        update featureToogle;

        Test.startTest();
        List<Contact> contacts = (List<Contact>) new SObjectBuilder(Contact.SObjectType)
            .setField(Contact.LastName, 'Contact Test')
            .setField(Contact.Email, 'testemail@testemail.com')
            .setField(Contact.Phone, '12345678')
            .setField(Contact.BMID__c, 'BMID')
            .setField(Contact.Primary_Campaign__c, campaign[0].Id)
            .quantity(10)
            .create()
            .getRecords();
        Test.getEventBus().deliver();
        Test.stopTest();

        List<CampaignMember> campMembCreated = (List<CampaignMember>) new CampaignMemberSelector()
            .selectCampaignMemberForLeadConvert()
            .executeQuery();
        System.assertEquals(10, campMembCreated.size(), 'CampaignMember was not created');
    }

    @isTest
    private static void testCampaignMemberCreationForContactsOnBMIDUpdate() {
        User marketingUser = (User) new SObjectBuilder(User.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(User.SObjectType))
            .setFields(new Map<SObjectField, Object> {
                User.UserPermissionsMarketingUser => true,
                User.UserName => 'marketingUser@user.com',
                User.CommunityNickname => 'marketingTest1'
            })
            .create()
            .getRecord();
        
        Feature_Toggle__c featureToogle = Feature_Toggle__c.getOrgDefaults();
        featureToogle.CampMemberAsyncRecordQantity__c = 9;
        update featureToogle;
        Campaign brokenAtt = (Campaign) new SObjectBuilder(Campaign.sObjectType)
            .setField(Campaign.IsActive, true)
            .setField(Campaign.Non_Attributable__c, false)
            .setField(Campaign.Name, 'Broken Attribution')
            .setField(Campaign.BMID__c, 'brokenAttBMID')
            .setField(Campaign.AID__c, 'brokenAttAID')
            .setField(Campaign.PID__c, 'brokenAttPID')
            .createAsUser(marketingUser)
            .getRecord();

        Campaign trueWalkOnAtt = (Campaign) new SObjectBuilder(Campaign.sObjectType)
            .setField(Campaign.IsActive, true)
            .setField(Campaign.Non_Attributable__c, false)
            .setField(Campaign.Name, 'True_Walk_On_2024')
            .setField(Campaign.BMID__c, 'trueWalkOnAttBMID')
            .setField(Campaign.AID__c, 'trueWalkOnAttAID')
            .setField(Campaign.PID__c, 'trueWalkOnAttPID')
            .createAsUser(marketingUser)
            .getRecord();

        Campaign salesGeneratedAtt = (Campaign) new SObjectBuilder(Campaign.sObjectType)
            .setField(Campaign.IsActive, true)
            .setField(Campaign.Non_Attributable__c, false)
            .setField(Campaign.Name, 'Sales Generated')
            .setField(Campaign.BMID__c, 'salesGeneratedAttBMID')
            .setField(Campaign.AID__c, 'salesGeneratedAttAID')
            .setField(Campaign.PID__c, 'salesGeneratedAttPID')
            .createAsUser(marketingUser)
            .getRecord();
	
        //Adding the bypasstrigger flag to not trigger the validation when creating contact. PBC-10858
        ByPassTrigger__c byPassTrigger = ByPassTrigger__c.getOrgDefaults();
        byPassTrigger.ByPass_OppContactRole_Validation__c = true;
        insert byPassTrigger;
        List<Contact> contacts = (List<Contact>) new SObjectBuilder(Contact.SObjectType)
            .setField(Contact.LastName, 'Contact Test')
            .setField(Contact.Email, 'testemail@testemail.com')
            .setField(Contact.Phone, '12345678')
            .quantity(10)
            .create()
            .getRecords();
		Test.getEventBus().deliver();
        List<CampaignMember> campMembCreatedBeforeUpdate = (List<CampaignMember>) new CampaignMemberSelector()
            .selectCampaignMemberForLeadConvert()
            .executeQuery();
        System.assertEquals(10, campMembCreatedBeforeUpdate.size(), 'CampaignMember was not created in Insert');

        Test.startTest();
        for (Contact con : contacts) {
            con.BMID__c = 'BMID';
        }
        update contacts;
        Test.getEventBus().deliver();
        Test.stopTest();

        List<CampaignMember> campMembCreated = (List<CampaignMember>) new CampaignMemberSelector()
            .selectCampaignMemberForLeadConvert()
            .executeQuery();
        System.assertEquals(20, campMembCreated.size(), 'CampaignMember was not created in Update');
    }

    @isTest
    static void testMitelCampaignMemberCreationMatchingCampaign() {
        Deal_Registration__c dealReg = createTestDealRegistration('RC_Mitel Test', false);

        Test.startTest();
        dealReg.Status__c = 'Approved';
        update dealReg;

        Campaign camp = (Campaign) new CampaignSelector()
            .selectCampaignsByName(new List<Object>{ 'RC_Mitel Test' })
            .executeQuery()[0];
        CampaignMember campMember = (CampaignMember) new CampaignMemberSelector()
            .selectCampaignMemberForLeadConvert()
            .executeQuery()[0];
        Lead ld = (Lead) new LeadSelector()
            .selectLeads()
            .executeQuery()[0];
        Test.stopTest();
        System.assertEquals(ld.Id, campMember.LeadId);
        System.assertEquals(camp.Id, campMember.CampaignId);
        System.assertEquals('Responded', campMember.Status);
    }

    @isTest
    static void testMitelCampaignMemberCreationWithoutMatchingCampaign() {
        Deal_Registration__c dealReg = createTestDealRegistration('RC_Mitel Test not match', true);

        Test.startTest();
        dealReg.Status__c = 'Approved';
        update dealReg;

        Campaign camp = (Campaign) new CampaignSelector()
            .selectCampaignsByName(new List<Object>{ 'Mitel_Agency_Unassigned' })
            .executeQuery()[0];
        CampaignMember campMember = (CampaignMember) new CampaignMemberSelector()
            .selectCampaignMemberForLeadConvert()
            .executeQuery()[0];
        Lead ld = (Lead) new LeadSelector()
            .selectLeads()
            .executeQuery()[0];
        Test.stopTest();
        System.assertEquals(ld.Id, campMember.LeadId);
        System.assertEquals(camp.Id, campMember.CampaignId);
        System.assertEquals('Sent', campMember.Status);
    }

    static Deal_Registration__c createTestDealRegistration(String campaignName, Boolean withAgencyRep) {
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setField(Account.Name, 'Opty test account')
            .setField(Account.Partner_ID__c, 'testID')
            .setField(Account.Type, 'Partner')
            .create()
            .getRecord();

        Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setField(Contact.AccountId, acc.Id)
            .setField(Contact.LastName, 'Contact Test')
            .setField(Contact.Email, 'testemail@testemail.com')
            .setField(Contact.Phone, '1234567')
            .create()
            .getRecord();

        Id agencyRep = withAgencyRep ? UserInfo.getUserId() : null;
        Deal_Registration__c dealRegObj = (Deal_Registration__c) new SObjectBuilder(Deal_Registration__c.SObjectType)
            .setField(Deal_Registration__c.Partner_Contact__c, con.Id)
            .setField(Deal_Registration__c.First_Name__c, 'Test')
            .setField(Deal_Registration__c.Last_Name__c, 'DealReg')
            .setField(Deal_Registration__c.How_did_you_acquire_this_Lead__c, campaignName)
            .setField(Deal_Registration__c.Business_Title__c, 'Consultant')
            .setField(Deal_Registration__c.Company_Name__c, 'Test Company')
            .setField(Deal_Registration__c.Email_Address__c, 'testdealreg@mail.com')
            .setField(Deal_Registration__c.Phone_Number__c, '1234567')
            .setField(Deal_Registration__c.Address__c, 'ABC street')
            .setField(Deal_Registration__c.City__c, 'abc city')
            .setField(Deal_Registration__c.State__c, 'ALASKA')
            .setField(Deal_Registration__c.Postal_Code__c, '123456')
            .setField(Deal_Registration__c.Country__c, 'United States')
            .setField(Deal_Registration__c.Forecasted_Users__c, 5)
            .setField(Deal_Registration__c.Brand_Name__c, 'Avaya Cloud Office')
            .setField(Deal_Registration__c.Tier_Name__c, 'Office')
            .setField(Deal_Registration__c.Edition__c, 'Standard')
            .setField(Deal_Registration__c.Term__c, 'Annual')
            .setField(Deal_Registration__c.Number_of_Employees__c, '50-249')
            .setField(Deal_Registration__c.Number_of_Locations__c, '5-9')
            .setField(Deal_Registration__c.Industry__c, 'Banking')
            .setField(Deal_Registration__c.Estimated_Close_Date__c, System.today())
            .setField(Deal_Registration__c.Website__c, 'www.testsite.com')
            .setField(Deal_Registration__c.Description__c, 'Test Deal Reg description')
            .setField(Deal_Registration__c.Budget_available_for_project__c, 'Yes')
            .setField(Deal_Registration__c.Existing_Solution_Provider__c, 'Avaya')
            .setField(Deal_Registration__c.Competitor_s__c, 'Avaya')
            .setField(Deal_Registration__c.Whats_prompting_change__c, 'Other')
            .setField(Deal_Registration__c.Decision_Maker__c, 'Other')
            .setField(Deal_Registration__c.Currently_in_a_contract__c, 'Yes')
            .setField(Deal_Registration__c.Sales_Notes__c, 'Test Sales notes')
            .setField(Deal_Registration__c.Avaya_Partnership_Deal__c, true)
            .setField(Deal_Registration__c.Status__c, 'Pending Approval')
            .setField(Deal_Registration__c.Existing_Solution_Provider_Others__c, agencyRep)
            .create()
            .getRecord();

        return dealRegObj;
    }
}