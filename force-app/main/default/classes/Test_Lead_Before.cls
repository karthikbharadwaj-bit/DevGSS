@isTest
private class Test_Lead_Before {

	@isTest static void testLeadSystemSourceInboundCall() {
		Lead testLead = new Lead(
            LastName = 'Test',
            Company = 'Test Company',
            Email = 'test@test.com',
            LeadSource = LeadHelper.LEAD_SOURCE_INBOUND_CALL,
            Industry = 'Retail'
        );

        Test.startTest();
            insert testLead;
        Test.stopTest();

        Lead leadToCheck = [SELECT LeadSource, Lead_System_Source__c FROM Lead WHERE Id = :testLead.Id];

        System.assertEquals(LeadHelper.LEAD_SYSTEM_SOURCE_INBOUND_CALL, leadToCheck.Lead_System_Source__c);
	}

	@isTest static void testLeadSystemSourceInboundChat() {
		Lead testLead = new Lead(
            LastName = 'Test',
            Company = 'Test Company',
            Email = 'test@test.com',
            LeadSource = LeadHelper.LEAD_SOURCE_INBOUND_CHAT,
            Industry = 'Retail'
        );

        Test.startTest();
            insert testLead;
        Test.stopTest();

        Lead leadToCheck = [SELECT LeadSource, Lead_System_Source__c FROM Lead WHERE Id = :testLead.Id];

        System.assertEquals(LeadHelper.LEAD_SYSTEM_SOURCE_INBOUND_CHAT, leadToCheck.Lead_System_Source__c);
	}

    @isTest static void testSkipLeadRoutingByUserPositive(){
        Test.startTest();

        insert new SkipLeadRoutingLogicUsers__c(Name = UserInfo.getUserId().left(15), UserName__c = 'CurrentUser' );
        Lead leadObjTest = (Lead) new SObjectBuilder(Lead.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Lead.FirstName => 'testFirstName',
                    Lead.Phone => '9910106866',
                    Lead.Notes__c => 'Test Notes',
                    Lead.Website => 'http://test.com',
                    Lead.NumberOfEmployees => 123,
                    Lead.Industry => 'Test',
                    Lead.NumberOfEmployees__c => '2-19',
                    Lead.Number_of_Locations__c => '2-4',
                    Lead.OwnerId => UserInfo.getUserId(),
                    Lead.Company => 'fakeCompany',
                    Lead.RecordTypeId => LeadHelper.RT_INFO_BY_NAME.get('Partner Leads').getRecordTypeId()
                }
            )
            .create()
            .getRecord();

        Test.stopTest();

        Lead assertLead = new List<Lead>([ SELECT Id, OwnerId
                                     FROM Lead
                                     WHERE Id =: leadObjTest.Id
                                     LIMIT 1])[0];

        System.assertEquals(leadObjTest.OwnerId, assertLead.OwnerId, 'Owner should be current user');
    }

    @isTest static void testSkipLeadRoutingByUserNegative(){
        LeadRoutingSettings__c lrs = LeadRoutingSettings__c.getOrgDefaults();
        lrs.LeanDataUserId__c = HardcodedIdsMapper.getMatchedObjectId('0053400000C176u');
        lrs.RoutingSystemUserId__c = HardcodedIdsMapper.getMatchedObjectId('00580000005USPT');
        lrs.RoutingSystemReason__c = 'PR PER LAR SYSTEM USER';
        lrs.IsBypassProtectionRouting__c = false;
        upsert lrs LeadRoutingSettings__c.Id;

        System.assertEquals(false, SkipLeadRoutingLogicUsers__c.getAll().keySet().contains(UserInfo.getUserId().left(15)) );

        Test.startTest();
        Lead leadObjTest = (Lead) new SObjectBuilder(Lead.SObjectType)
        .setFields(
            new Map<SObjectField, Object>{
                Lead.FirstName => 'testFirstName',
                Lead.Phone => '9910106866',
                Lead.Notes__c => 'Test Notes',
                Lead.Website => 'http://test.com',
                Lead.NumberOfEmployees => 123,
                Lead.Industry => 'Test',
                Lead.NumberOfEmployees__c => '2-19',
                Lead.Number_of_Locations__c => '2-4',
                Lead.OwnerId => UserInfo.getUserId().left(15),
                Lead.Company => 'fakeCompany',
                Lead.RecordTypeId => LeadHelper.RT_INFO_BY_NAME.get('Partner Leads').getRecordTypeId()
            }
        )
        .create()
        .getRecord();
        Test.stopTest();

        Lead assertLead = new List<Lead>([ SELECT Id, OwnerId
                                     FROM Lead
                                     WHERE Id =: leadObjTest.Id
                                     LIMIT 1])[0];

        System.assertNotEquals(leadObjTest.OwnerId, assertLead.OwnerId, 'Owner should not be current user');
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest static void testRoutingReasonWhenInactiveOwnerAndMarketoUpdate(){
         User inactiveUser = (User) new SObjectBuilder(User.sObjectType)
             .setField(User.IsActive, false)
             .create()
             .getRecord();

        LeadRoutingSettings__c leadRoutingSettings = LeadRoutingSettings__c.getOrgDefaults();
        leadRoutingSettings.UseNewRouting__c = false;
        leadRoutingSettings.IsbypassProtectionRouting__c = false;
        leadRoutingSettings.LeanDataFutureMethodToggle__c = true;
        leadRoutingSettings.RoutingSystemUserId__c = inactiveUser.Id;
        insert leadRoutingSettings;

        Id RecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Sales Leads').getRecordTypeId();

        Lead leadToBeRouted = (Lead) new SObjectBuilder(Lead.sObjectType)
            .setField(Lead.OwnerId, inactiveUser.Id)
            .setField(Lead.LeadSource, 'test')
            .setField(Lead.RecordTypeId, RecordTypeId)
            .setField(Lead.Bypass_PR__c, false)
            .setField(Lead.Lead_Brand_Name__c, 'RingCentral Canada')
            .setField(Lead.Email, 'tost@da.com')
            .create()
            .getRecord();
        List<Object> bindings = new List<Object>();
        
        bindings.add('Marketo');
        User userMarketo = (User) new UserSelector().selectUserByLastName(bindings).executeQuery()[0];
        
        Test.startTest();
        Test.stoptest();
        bindings.clear();
        bindings.add(leadToBeRouted.Id);
        leadToBeRouted = (Lead) new LeadSelector().selectLeadById(bindings).executeQuery()[0];
        
        /*Lead routing code deprecation changes*/
        //System.assertEquals(leadToBeRouted.Routing_Reason__c, LeadTriggerHelper.ROUTINGREASONINACTIVEOWNER,
            //'The lead with inactive user as owner and updated by user marketo has an incorrect routing reason message');
    }

    public static void createCampaigns() {
        List<Campaign> testCamps = new List<Campaign>();
        Campaign campNonAtt = (Campaign) new SObjectBuilder(Campaign.sObjectType)
                               .setField(Campaign.Non_Attributable__c, true)
                               .setField(Campaign.Name, 'campNonAtt')
                               .build()
                               .getRecord();
        testCamps.add(campNonAtt);

        Campaign campNonAtt2 = (Campaign) new SObjectBuilder(Campaign.sObjectType)
                               .setField(Campaign.Non_Attributable__c, true)
                               .setField(Campaign.Name, 'campNonAtt2')
                               .build()
                               .getRecord();
        testCamps.add(campNonAtt2);

        Campaign campAtt = (Campaign) new SObjectBuilder(Campaign.sObjectType)
                               .setField(Campaign.Non_Attributable__c, false)
                               .setField(Campaign.Name, 'campAtt')
                               .build()
                               .getRecord();
        testCamps.add(campAtt);

        Campaign campAtt2 = (Campaign) new SObjectBuilder(Campaign.sObjectType)
                               .setField(Campaign.Non_Attributable__c, false)
                               .setField(Campaign.Name, 'campAtt2')
                               .build()
                               .getRecord();
        testCamps.add(campAtt2);

        insert testCamps;
    }

    public static Campaign getCampaign(List<Object> bindings) {
        return (Campaign) new CampaignSelector().selectCampaignsByName(bindings).executeQuery()[0];
    }

    @isTest
    private static void testMostRecentCampaignAfterUpdateAttNonAtt() {
        Feature_Toggle__c featureToggle = new Feature_Toggle__c();
        insert featureToggle;
        createCampaigns();
        List<Object> bindings = new List<Object>();
        bindings.add('campAtt');
        Campaign camp = getCampaign(bindings);

        Lead lead = (Lead) new SObjectBuilder(Lead.sObjectType)
                               .setField(Lead.LastName, 'TestLead')
                               .build()
                               .getRecord();

        lead.Primary_Campaign__c = camp.id;
        lead.Most_Recent_Campaign__c = camp.id;
        insert lead;

        Test.startTest();
            bindings.clear();
            bindings.add(new Set<Id>{lead.Id});
            lead = (Lead) new LeadSelector().selectLeadsByIds(bindings).executeQuery()[0];
            bindings.clear();
            bindings.add('campNonAtt');
            Campaign nonAttCampaign = getCampaign(bindings);

            lead.Primary_Campaign__c = nonAttCampaign.Id;
            lead.Most_Recent_Campaign__c = nonAttCampaign.Id;
            TriggerHandler.BY_PASS_LEAD_UPDATE = false;
            update lead;

        Test.stopTest();

        bindings.clear();
        bindings.add(new Set<Id>{lead.Id});
        lead = (Lead) new LeadSelector().selectLeadsByIds(bindings).executeQuery()[0];

        System.assert(lead.Most_Recent_Campaign__c != null, 
            'Most Recent Campaign should not be null after Lead is updated from Attributable Campaign to Non Attributable');
        System.assertEquals(lead.Most_Recent_Campaign__c, camp.Id,
            'Most Recent Campaign should not change after Lead is updated from Attributable Campaign to Non Attributable');
    }

    @isTest
    private static void testMostRecentCampaignAfterUpdateNonAttAtt() {
        Feature_Toggle__c featureToggle = new Feature_Toggle__c();
        createCampaigns();
        List<Object> bindings = new List<Object>();
        bindings.add('campNonAtt');
        Campaign camp = getCampaign(bindings);

        Lead lead = (Lead) new SObjectBuilder(Lead.sObjectType)
                               .setField(Lead.LastName, 'TestLead')
                               .build()
                               .getRecord();

        lead.Primary_Campaign__c = camp.id;
        lead.Most_Recent_Campaign__c = camp.id;
        insert lead;

        Test.startTest();
            bindings.clear();
            bindings.add(new Set<Id>{lead.Id});
            lead = (Lead) new LeadSelector().selectLeadsByIds(bindings).executeQuery()[0];
            bindings.clear();
            bindings.add('campAtt');
            Campaign attCampaign = getCampaign(bindings);

            lead.Primary_Campaign__c = attCampaign.Id;
            lead.Most_Recent_Campaign__c = attCampaign.Id;
            TriggerHandler.BY_PASS_LEAD_UPDATE = false;
            update lead;

        Test.stopTest();

        bindings.clear();
        bindings.add(new Set<Id>{lead.Id});
        lead = (Lead) new LeadSelector().selectLeadsByIds(bindings).executeQuery()[0];

        System.assert(lead.Most_Recent_Campaign__c != null, 
            'Most Recent Campaign should not be null after Lead is updated from Non Attributable Campaign to Attributable');
        System.assertEquals(lead.Most_Recent_Campaign__c, attCampaign.Id,
            'Most Recent Campaign should change after Lead is updated from Non Attributable Campaign to Attributable');
    }

    @isTest
    private static void testMostRecentCampaignAfterUpdateNonAttNonAtt() {
        Feature_Toggle__c featureToggle = new Feature_Toggle__c();
        createCampaigns();
        List<Object> bindings = new List<Object>();
        bindings.add('campNonAtt');
        Campaign camp = getCampaign(bindings);

        Lead lead = (Lead) new SObjectBuilder(Lead.sObjectType)
                               .setField(Lead.LastName, 'TestLead')
                               .build()
                               .getRecord();

        lead.Primary_Campaign__c = camp.id;
        lead.Most_Recent_Campaign__c = camp.id;
        insert lead;

        Test.startTest();
            bindings.clear();
            bindings.add(new Set<Id>{lead.Id});
            lead = (Lead) new LeadSelector().selectLeadsByIds(bindings).executeQuery()[0];
            bindings.clear();
            bindings.add('campNonAtt2');
            Campaign nonAttCampaign = getCampaign(bindings);

            lead.Primary_Campaign__c = nonAttCampaign.Id;
            lead.Most_Recent_Campaign__c = nonAttCampaign.Id;
            TriggerHandler.BY_PASS_LEAD_UPDATE = false;
            update lead;

        Test.stopTest();

        bindings.clear();
        bindings.add(new Set<Id>{lead.Id});
        lead = (Lead) new LeadSelector().selectLeadsByIds(bindings).executeQuery()[0];

        System.assert(lead.Most_Recent_Campaign__c != null, 
            'Most Recent Campaign should not be null after Lead is updated from Non Attributable Campaign to Non Attributable');
        System.assertEquals(lead.Most_Recent_Campaign__c, nonAttCampaign.Id,
            'Most Recent Campaign should change after Lead is updated from Non Attributable Campaign to Non Attributable');
    }

    @isTest
    private static void testMostRecentCampaignAfterUpdateAttAtt() {
        Feature_Toggle__c featureToggle = new Feature_Toggle__c();
        createCampaigns();
        List<Object> bindings = new List<Object>();
        bindings.add('campAtt');
        Campaign camp = getCampaign(bindings);

        Lead lead = (Lead) new SObjectBuilder(Lead.sObjectType)
                               .setField(Lead.LastName, 'TestLead')
                               .build()
                               .getRecord();

        lead.Primary_Campaign__c = camp.id;
        lead.Most_Recent_Campaign__c = camp.id;
        insert lead;

        Test.startTest();
            bindings.clear();
            bindings.add(new Set<Id>{lead.Id});
            lead = (Lead) new LeadSelector().selectLeadsByIds(bindings).executeQuery()[0];
            bindings.clear();
            bindings.add('campAtt2');
            Campaign attCampaign = getCampaign(bindings);

            lead.Primary_Campaign__c = attCampaign.Id;
            lead.Most_Recent_Campaign__c = attCampaign.Id;
            TriggerHandler.BY_PASS_LEAD_UPDATE = false;
            update lead;

        Test.stopTest();

        bindings.clear();
        bindings.add(new Set<Id>{lead.Id});
        lead = (Lead) new LeadSelector().selectLeadsByIds(bindings).executeQuery()[0];

        System.assert(lead.Most_Recent_Campaign__c != null, 
            'Most Recent Campaign should not be null after Lead is updated from Attributable Campaign to Attributable');
        System.assertEquals(lead.Most_Recent_Campaign__c, attCampaign.Id,
            'Most Recent Campaign should change after Lead is updated from Attributable Campaign to Attributable');
    }

    @isTest
    private static void testMostRecentCampaignAfterUpdateNullNonAtt() {
        Feature_Toggle__c featureToggle = new Feature_Toggle__c();
        createCampaigns();
        List<Object> bindings = new List<Object>();

        Lead lead = (Lead) new SObjectBuilder(Lead.sObjectType)
                               .setField(Lead.LastName, 'TestLead')
                               .build()
                               .getRecord();

        lead.Primary_Campaign__c = null;
        lead.Most_Recent_Campaign__c = null;
        insert lead;

        Test.startTest();
            bindings.clear();
            bindings.add(new Set<Id>{lead.Id});
            lead = (Lead) new LeadSelector().selectLeadsByIds(bindings).executeQuery()[0];
            bindings.clear();
            bindings.add('campNonAtt');
            Campaign nonAttCampaign = getCampaign(bindings);

            lead.Primary_Campaign__c = nonAttCampaign.Id;
            lead.Most_Recent_Campaign__c = nonAttCampaign.Id;
            TriggerHandler.BY_PASS_LEAD_UPDATE = false;
            update lead;

        Test.stopTest();

        bindings.clear();
        bindings.add(new Set<Id>{lead.Id});
        lead = (Lead) new LeadSelector().selectLeadsByIds(bindings).executeQuery()[0];

        System.assert(lead.Most_Recent_Campaign__c != null,
            'Most Recent Campaign should not be null after Lead is updated from null Campaign to Non Attributable');
        System.assertEquals(lead.Most_Recent_Campaign__c, nonAttCampaign.Id,
            'Most Recent Campaign should change after Lead is updated from Null Campaign to Non Attributable');
    }

    @isTest
    public static void recruitedByIsTakenFromAccountWhenLeadIsPartner() {
        String PARTNER_ID = '1234';
        Account testAcc;
        Lead testLead;
        User testUser;

        SObjectFactory factory = new SObjectFactory();

        Test.startTest();
            testUser = (User) factory
                .create(User.SObjectType);

            testAcc = (Account) factory
                .create(
                    Account.SObjectType,
                    new Map<SObjectField, Object>{
                        Account.Name => 'Test',
                        Account.Recruited_By__c => testUser.Id,
                        Account.Partner_ID__c => PARTNER_ID
                    }
                );

            testLead = (Lead) factory
                .create(
                    Lead.SObjectType,
                    new Map<SObjectField, Object>{
                        Lead.Partner_Account_Name__c => testAcc.Name,
                        Lead.Partner_Account__c => testAcc.Id,
                        Lead.RecordTypeId => LeadHelper.RT_ID_PARTNER_LEADS,
                        Lead.LeadPartnerID__c => PARTNER_ID
                    }
                );
        Test.stopTest();

        Lead leadToCheck = (Lead) new LeadSelector()
            .selectLeadById(new List<Object>{ new Set<Id>{ testLead.Id } })
            .selectFields(new List<String>{ 'Id', 'Recruited_By__c', 'Partner_Account_Name__c', 'Partner_Account__c' })
            .executeQuery()
            .get(0);

        System.assertEquals(testUser.Id, leadToCheck.Recruited_By__c);
	}


    @isTest
    public static void recruitedByIsNotTakenFromAccountWhenLeadIsSales() {
        String PARTNER_ID = '1234';
        Account testAcc;
        Lead testLead;
        User testUser;

        SObjectFactory factory = new SObjectFactory();

        Test.startTest();
            testUser = (User) factory
                .create(User.SObjectType);

            testAcc = (Account) factory
                .create(
                    Account.SObjectType,
                    new Map<SObjectField, Object>{
                        Account.Name => 'Test',
                        Account.Recruited_By__c => testUser.Id,
                        Account.Partner_ID__c => PARTNER_ID
                    }
                );

            testLead = (Lead) factory
                .create(
                    Lead.SObjectType,
                    new Map<SObjectField, Object>{
                        Lead.Partner_Account_Name__c => testAcc.Name,
                        Lead.Partner_Account__c => testAcc.Id,
                        Lead.RecordTypeId => LeadHelper.RT_ID_SALES_LEADS,
                        Lead.LeadPartnerID__c => PARTNER_ID
                    }
                );
        Test.stopTest();

        Lead leadToCheck = (Lead) new LeadSelector()
            .selectLeadById(new List<Object>{ new Set<Id>{ testLead.Id } })
            .selectFields(new List<String>{ 'Id', 'Recruited_By__c', 'Partner_Account_Name__c', 'Partner_Account__c' })
            .executeQuery()
            .get(0);

        System.assertEquals(null, leadToCheck.Recruited_By__c);
    }

    @isTest
    static void testMultipleLeadUpdate() {
        Feature_Toggle__c featureToggle = new Feature_Toggle__c();
        insert featureToggle;
        createCampaigns();
        List<Object> bindings = new List<Object>();
        bindings.add('campAtt');
        Campaign campAttOriginal = getCampaign(bindings);
        bindings.clear();
        bindings.add('campAtt2');
        Campaign campAttSubstitute = getCampaign(bindings);

        Lead firstLead = (Lead) new SObjectBuilder(Lead.sObjectType)
                .setField(Lead.LastName, 'fakeLastName')
                .setField(Lead.Company, 'fakeCompany')
                .setField(Lead.Email, 'test@email.com')
                .setField(Lead.Phone, '4531681940')
                .setField(Lead.Most_Recent_Campaign__c, campAttOriginal.id)
                .create()
                .getRecord();
        Lead secondLead = (Lead) new SObjectBuilder(Lead.sObjectType)
                .setField(Lead.LastName, 'fakeLastName')
                .setField(Lead.Company, 'fakeCompany')
                .setField(Lead.Email, 'test@email.com')
                .setField(Lead.Phone, '4531681940')
                .setField(Lead.Most_Recent_Campaign__c, campAttOriginal.id)
                .create()
                .getRecord();
        List<lead> updatedLeads = new List<Lead>{firstlead, secondLead};
        Boolean errorOccured = false;
        Test.startTest();
        try {
            for(Lead l : updatedLeads) {
                l.Most_Recent_Campaign__c = campAttSubstitute.id;
            }
            update updatedLeads;
            for(Lead l : updatedLeads) {
                l.Most_Recent_Campaign__c = campAttOriginal.id;
            }
            update updatedLeads;
        } catch(DmlException e){
            errorOccured = true;
         }
        Test.stopTest();
        System.assert(!errorOccured,
                      'Updating multiple leads with already-existing Campaign Members shouldnt throw a DML error');
    }

    @isTest
    static void testCampaignMembersCreateLeadByBMID() {
        Feature_Toggle__c featureToggle = new Feature_Toggle__c();
        List<Object> bindings = new List<Object>();
        insert featureToggle;
        Campaign testCampaign = (Campaign) new SObjectBuilder(Campaign.sObjectType)
            .setField(Campaign.Non_Attributable__c, true)
            .setField(Campaign.Name, 'campNonAtt')
            .setField(Campaign.BMID__c, 'testCamp')
            .build()
            .create()
            .getRecord();

        test.startTest();
        Lead testLead = (Lead) new SObjectBuilder(Lead.sObjectType)
            .setField(Lead.LastName, 'testLastName')
            .setField(Lead.Company, 'testCompany')
            .setField(Lead.Email, 'test@testemail.com')
            .setField(Lead.Phone, '4531681940')
            .setField(Lead.BMID__c, testCampaign.BMID__c)
            .create()
            .getRecord();
        test.stopTest();

        bindings.add(new List<Id>{ testLead.Id });
        bindings.add(new List<Id>{ testCampaign.Id });
        List<CampaignMember> listCampaignMember = (List<CampaignMember>) new CampaignMemberSelector()
            .selectCampaignMemberByLeadAndCampaignIds(bindings)
            .executeQuery();

        System.assertEquals(1, listCampaignMember.size(), 'CampaignMember was not created');
        System.assertEquals(
            testLead.Id,
            listCampaignMember[0].LeadId,
            'CampaignMember Lead doesnt match with created Lead'
        );
        System.assertEquals(
            testCampaign.Id,
            listCampaignMember[0].CampaignId,
            'CampaignMember Campaign doesnt match with created Campaign'
        );
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testCampaignMembersCreationInLeadUpdateByBMID() {
        Feature_Toggle__c featureToggle = new Feature_Toggle__c();
        List<Object> bindings = new List<Object>();
        insert featureToggle;

        Campaign testCampaign = (Campaign) new SObjectBuilder(Campaign.sObjectType)
            .setField(Campaign.Non_Attributable__c, true)
            .setField(Campaign.Name, 'campNonAtt')
            .setField(Campaign.BMID__c, 'testCamp')
            .build()
            .create()
            .getRecord();
        Campaign testCampaignForUpdate = (Campaign) new SObjectBuilder(Campaign.sObjectType)
            .setField(Campaign.Non_Attributable__c, true)
            .setField(Campaign.Name, 'campNonAtt')
            .setField(Campaign.BMID__c, 'testCampForUpdate')
            .build()
            .create()
            .getRecord();
        Lead testLead = (Lead) new SObjectBuilder(Lead.sObjectType)
            .setField(Lead.LastName, 'testLastName')
            .setField(Lead.Company, 'testCompany')
            .setField(Lead.Email, 'test@testemail.com')
            .setField(Lead.Phone, '4531681940')
            .setField(Lead.BMID__c, testCampaign.BMID__c)
            .create()
            .getRecord();

        test.startTest();
        testLead.BMID__c = testCampaignForUpdate.BMID__c;
        update testLead;
        test.stopTest();

        bindings.add(new List<Id>{ testLead.Id });
        bindings.add(new List<Id>{ testCampaignForUpdate.Id });
        List<CampaignMember> listCampaignMember = (List<CampaignMember>) new CampaignMemberSelector()
            .selectCampaignMemberByLeadAndCampaignIds(bindings)
            .executeQuery();
    }

    @isTest
    static void testCampaignMembersExistsOnLeadBMIDUpdate() {
        Feature_Toggle__c featureToggle = new Feature_Toggle__c();
        List<Object> bindings = new List<Object>();
        insert featureToggle;

        Campaign testCampaign = (Campaign) new SObjectBuilder(Campaign.sObjectType)
            .setField(Campaign.Non_Attributable__c, true)
            .setField(Campaign.Name, 'campNonAtt')
            .setField(Campaign.BMID__c, 'testCamp')
            .build()
            .create()
            .getRecord();
        Campaign testCampaignForUpdate = (Campaign) new SObjectBuilder(Campaign.sObjectType)
            .setField(Campaign.Non_Attributable__c, true)
            .setField(Campaign.Name, 'campNonAtt')
            .setField(Campaign.BMID__c, 'testCampForUpdate')
            .build()
            .create()
            .getRecord();
        Lead testLead = (Lead) new SObjectBuilder(Lead.sObjectType)
            .setField(Lead.LastName, 'testLastName')
            .setField(Lead.Company, 'testCompany')
            .setField(Lead.Email, 'test@testemail.com')
            .setField(Lead.Phone, '4531681940')
            .setField(Lead.BMID__c, testCampaign.BMID__c)
            .create()
            .getRecord();

        bindings.add(new List<Id>{ testLead.Id });
        bindings.add(new List<Id>{ testCampaign.Id });
        List<CampaignMember> listCampaignMemberInsert = (List<CampaignMember>) new CampaignMemberSelector()
            .selectCampaignMemberByLeadAndCampaignIds(bindings)
            .executeQuery();

        System.assertEquals(1, listCampaignMemberInsert.size(), 'CampaignMember on Lead creation has failed');
        System.assertEquals(
            testLead.Id,
            listCampaignMemberInsert[0].LeadId,
            'CampaignMember Lead doesnt match with created Lead'
        );
        System.assertEquals(
            testCampaign.Id,
            listCampaignMemberInsert[0].CampaignId,
            'CampaignMember Campaign doesnt match with created Campaign'
        );

        testLead.BMID__c = testCampaignForUpdate.BMID__c;
        update testLead;

        test.startTest();
        testLead.BMID__c = testCampaign.BMID__c;
        update testLead;
        test.stopTest();

        bindings.add(new List<Id>{ testLead.Id });
        bindings.add(new List<Id>{ testCampaign.Id });
        List<CampaignMember> listCampaignMember = (List<CampaignMember>) new CampaignMemberSelector()
            .selectCampaignMemberByLeadAndCampaignIds(bindings)
            .executeQuery();

        System.assertEquals(1, listCampaignMember.size(), 'CampaignMember was duplicated');
        System.assertEquals(
            testLead.Id,
            listCampaignMember[0].LeadId,
            'CampaignMember Lead doesnt match with created Lead'
        );
        System.assertEquals(
            testCampaign.Id,
            listCampaignMember[0].CampaignId,
            'CampaignMember Campaign doesnt match with created Campaign'
        );
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testCampaignMembersCreationInLeadUpdateBulk() {
        Feature_Toggle__c featureToggle = new Feature_Toggle__c();
        List<Object> bindings = new List<Object>();
        insert featureToggle;

        Campaign testCampaign = (Campaign) new SObjectBuilder(Campaign.sObjectType)
            .setField(Campaign.Non_Attributable__c, true)
            .setField(Campaign.Name, 'campNonAtt')
            .setField(Campaign.BMID__c, 'testCamp')
            .build()
            .create()
            .getRecord();
        Campaign testCampaignForUpdate = (Campaign) new SObjectBuilder(Campaign.sObjectType)
            .setField(Campaign.Non_Attributable__c, true)
            .setField(Campaign.Name, 'campNonAtt')
            .setField(Campaign.BMID__c, 'testCampForUpdate')
            .build()
            .create()
            .getRecord();

        List<Lead> testLeads = (List<Lead>) new SObjectBuilder(Lead.sObjectType)
            .setField(Lead.LastName, 'testLastName')
            .setField(Lead.Company, 'testCompany')
            .setField(Lead.Email, 'test@testemail.com')
            .setField(Lead.Phone, '4531681940')
            .setField(Lead.BMID__c, testCampaign.BMID__c)
            .quantity(100)
            .create()
            .getRecords();

        test.startTest();
        Map<Id,Lead> leadsToUpdate = new Map<Id,Lead>();
        for (Lead testLead : testLeads) {
            testLead.BMID__c = testCampaignForUpdate.BMID__c;
            leadsToUpdate.put(testLead.id,testLead);
        }
        update leadsToUpdate.values();
        test.stopTest();

        bindings.add(leadsToUpdate.keySet());
        bindings.add(new List<Id>{ testCampaignForUpdate.Id });
        List<CampaignMember> listCampaignMember = (List<CampaignMember>) new CampaignMemberSelector()
            .selectCampaignMemberByLeadAndCampaignIds(bindings)
            .executeQuery();
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testLeadBMIDUpdateWithExistingCampaignMembers() {
        Feature_Toggle__c featureToggle = new Feature_Toggle__c();
        List<Object> bindings = new List<Object>();
        Integer i = 1;
        insert featureToggle;

        Campaign testCampaign1 = (Campaign) new SObjectBuilder(Campaign.sObjectType)
            .setField(Campaign.Non_Attributable__c, true)
            .setField(Campaign.Name, 'Test Camp 1')
            .setField(Campaign.BMID__c, 'BMID 1')
            .build()
            .create()
            .getRecord();
        Campaign testCampaign2 = (Campaign) new SObjectBuilder(Campaign.sObjectType)
            .setField(Campaign.Non_Attributable__c, true)
            .setField(Campaign.Name, 'Test Camp 2')
            .setField(Campaign.BMID__c, 'BMID 2')
            .build()
            .create()
            .getRecord();
        Campaign testCampaign3 = (Campaign) new SObjectBuilder(Campaign.sObjectType)
            .setField(Campaign.Non_Attributable__c, true)
            .setField(Campaign.Name, 'Test Camp 3')
            .setField(Campaign.BMID__c, 'BMID 3')
            .build()
            .create()
            .getRecord();
        Campaign testCampaign4 = (Campaign) new SObjectBuilder(Campaign.sObjectType)
            .setField(Campaign.Non_Attributable__c, true)
            .setField(Campaign.Name, 'Test Camp 4')
            .setField(Campaign.BMID__c, 'BMID 4')
            .build()
            .create()
            .getRecord();
        
        List<Lead> testLeads = (List<Lead>) new SObjectBuilder(Lead.SObjectType)
            .setField(Lead.LastName, 'Test Lead')
            .setField(Lead.Status, 'X. Suspect')
            .setField(Lead.Email, 'testemail@testemail.com')
            .setField(Lead.Phone, '123456')
            .setField(Lead.LeadSource, 'FR Office Weblead')
    		.setField(Lead.BMID__c, 'test BMID 1')
            .quantity(3)
            .build()
    		.getRecords();

        for (lead lead : testLeads) {
            lead.LastName = 'Test Lead' + i;
            lead.BMID__c = 'BMID ' + i;
            i++;
        }        
        insert testLeads;

        test.startTest();
            i = 1;
            for (lead lead : testLeads) {
            lead.BMID__c = 'BMID ' + (i+1);
            i++;
            }
            update testLeads;
        test.stopTest();

        bindings.add(new Map<Id,Lead>(testLeads).keySet());
        bindings.add(new List<Id>{ testCampaign1.Id, testCampaign2.Id, testCampaign3.Id, testCampaign4.Id });
        List<CampaignMember> listCampaignMember = (List<CampaignMember>) new CampaignMemberSelector()
            .selectCampaignMemberByLeadAndCampaignIds(bindings)
            .executeQuery();
    }
    
    //16-Apr-21 : Code coverage for ZI fields automation logic
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest static void testLeadZIFieldsAutomation() {
        
        Id ZIRTypeId = Account.SObjectType.getDescribe().getRecordTypeInfosByName().get('ZI Customer Shell Account').getRecordTypeId();
        
        Account testZiAccount = new Account(
            Name = 'Test Account',
            RecordTypeId = ZIRTypeId,
            ZI_Id__c = '12345678'
        );
        
        insert testZiAccount;
        
		Lead testLead1 = new Lead(
            LastName = 'Test',
            Company = 'Test Company',
            Email = 'test@test.com',
            LeadSource = LeadHelper.LEAD_SOURCE_INBOUND_CALL,
            Industry = 'Retail',
            ZI_CDP_AccountId_From_LS4SF__c = testZiAccount.Id,
            ZI_Id__c = '12345678'
        );
        
        Lead testLead2 = new Lead(
            LastName = 'Test',
            Company = 'Test Company',
            Email = 'test@test.com',
            LeadSource = LeadHelper.LEAD_SOURCE_INBOUND_CALL,
            Industry = 'Retail',
            ZI_CDP_AccountId_From_LS4SF__c = testZiAccount.Id,
            ZI_CDP_Match__c = '12345678'
        );

        Test.startTest();
            insert testLead1;
            insert testLead2;
        Test.stopTest();
	}
}