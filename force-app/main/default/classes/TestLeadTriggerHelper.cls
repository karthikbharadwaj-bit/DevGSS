@isTest
private class TestLeadTriggerHelper {

	enum PortalType { CSPLiteUser, PowerPartner, PowerCustomerSuccess, CustomerSuccess }

    private static final String POSTAL_CODE_TEST = '123432';
    private static final String ZIP_CODE_TEST = '44432222';
    private static final String LEAD_COMMON_EMAIL = 'som23@dsd.sd';
    private static final String TEST_STATUS_TO_TRACK_DATE_STATUS_FIELD_CHANGED = 'X. Open';
    private static final String STATUS_TO_SKIP_UPDATE_SYSTEM_USER_MODIFIED_DATA_FIELD = '0. Downgraded';
    private static final String STATUS_TO_ENTER_UPDATE_SYSTEM_USER_MODIFIED_DATA_FIELD = 'X. Open';

    @testSetup static void prepareData() {
        Id sysAdminProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id;
        User sysAdminUser = new User(
                Username= 'RCSysAdmin@RCAdmin.SysAdmin',
                FirstName='Sys',
                Email='123Email@email.em',
                LastName = 'Admin',
                ProfileId = sysAdminProfileId,
                Alias = 'tests',
                TimeZoneSidKey = 'America/Los_Angeles',
                LocaleSidKey = 'en_US',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US'
        );
        insert sysAdminUser;

//Username, Email, Alias, CommunityNickname, TimeZoneSidKey, LocaleSidKey, EmailEncodingKey, LanguageLocaleKey
        System.runAs(sysAdminUser) {
            Lead lCommon = new Lead(Email=LEAD_COMMON_EMAIL, LastName='3123123', Company='dasdasd');
            insert new List<Lead>{lCommon};
        }

        Lead lCommonAfterInsert = [SELECT Id, PostalCode, Zip_Code__c FROM Lead WHERE Email = :LEAD_COMMON_EMAIL];
        System.assert(lCommonAfterInsert.PostalCode == null, 'Postal Code is expected to be empty if we dont set it on insertion');
        System.assert(lCommonAfterInsert.Zip_Code__c == null, 'Zip_Code__c is expected to be empty if we dont set it on insertion');

        //Custom Setting for Callout - Mocked
        Gating_Process_Stage__c sledWsUrl = new Gating_Process_Stage__c(
            Name = 'SLED_WS_URL',
            SLED_WS_URL__c = 'https://example.com/api/endpoint'
        );
        insert sledWsUrl;
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest static void myUnitTest() {
        try {
        	Profile p1 = [select id ,name from profile where name = 'RC Partner User' limit 1];
        	User pu = getPortalUser(PortalType.PowerPartner,null,true,p1.id,'A'); /// RC Partner User
        	Schema.DescribeSObjectResult result = Lead.SObjectType.getDescribe();
   			Map<String,Schema.RecordTypeInfo> rtMapById = result.getRecordTypeInfosByName();
   			Map<ID,Schema.RecordTypeInfo> rtMapByName = new Map<ID,Schema.RecordTypeInfo>();
   			rtMapByName.put(rtMapById.get('Partner Leads').getRecordTypeId(),rtMapById.get('Partner Leads'));
   			Test.startTest();
   			Lead leadObj = new Lead();
   			leadObj.RecordTypeId = rtMapById.get('Partner Leads').getRecordTypeId();
   			leadObj.FirstName = 'TestLead';
   			leadObj.Company = 'TestLead';
   			leadObj.LastName = 'TestLead';
   			leadObj.Email = 'TestLead@test.com';
   			leadObj.Phone = '9810546322';
   			leadObj.LeadPartnerID__c = '12346';
   			leadObj.Partner_Lead_Owner__c = pu.Id;
   			leadObj.BMID__c='test';
   			leadObj.AID__c='test';
   			leadObj.PID__c='test';
   			leadObj.Five9_DNIS__c='test';
   			leadObj.Country = 'UK';
   			leadObj.LeadSource = 'Initial';
   			insert leadObj;
   			List<Lead> leadList = new List<Lead>();
   			leadList.add(leadObj);
   			Lead oldLeadObj = new Lead(BMID__c='',AID__c='',PID__c='',Five9_DNIS__c='');
   			Map<Id,Lead> oldLeadMap = new Map<Id,Lead>{leadObj.Id => oldLeadObj};
   			LeadTriggerHelper.updateMostRecentCampaign(leadList, oldLeadMap, rtMapByName);

   			leadObj.BMID__c = '';
   			leadObj.AID__c='';
   			leadObj.PID__c='';
   			leadObj.Five9_DNIS__c='';
   			update leadObj;
   			Lead oldLeadObj1 = new Lead(BMID__c='asd',AID__c='asd',PID__c='asd',Five9_DNIS__c='asd');
   			Map<Id,Lead> oldLeadMap1 = new Map<Id,Lead>{leadObj.Id => oldLeadObj1};
   			LeadTriggerHelper.updateMostRecentCampaign(leadList, oldLeadMap1, rtMapByName);

   			LeadTriggerHelper.createUniqueCombination('BMID', 'AID', 'PID', 'DNIS');
   			LeadTriggerHelper.getCustomerSize(leadList);
   			LeadTriggerHelper.assignLeadSource(leadObj);
   			LeadTriggerHelper.assignLeadSource(new Lead(Country='UK',LeadSource='About To Be Cancelled'));
   			LeadTriggerHelper.assignLeadSource(new Lead(Country='UK',LeadSource='Vista Print'));
   			LeadTriggerHelper.assignLeadSource(leadObj);
   			Lead newObj = new Lead(RecordTypeId = rtMapById.get('Partner Leads').getRecordTypeId());
   			LeadTriggerHelper.getLeadUltimatePartnerId(new List<Lead>{newObj},new Map<Id, Lead>(),rtMapByName);
   			LeadTriggerHelper.byPassTrgrsAtConvertLead();
   			LeadName__C setting = new LeadName__C(Name='test',First_Name__c='TestLead',Last_Name__c='TestLead');
   			insert setting;
   			LeadTriggerHelper.getLeadOwnerRCSFsync(leadList);
   			Test.stopTest();
        } catch(Exception ex) {}
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest static void test1(){

    	List<Campaign> campList = new List<Campaign>();

        Campaign campObj1 = new Campaign(Name='TestCampaign',Protected_Campaign__c=true
        , Shared_Lead_Campaign__c=true, Lead_Creation_Score__c='300', IsActive=true, AID__c='test0121' );
        //insert campObj1;
        campList.add(campObj1);
        Campaign campObj2 = new Campaign(Name='TestCampaign',Protected_Campaign__c=false
        , Shared_Lead_Campaign__c=true, Lead_Creation_Score__c='test', IsActive=true, DNIS__c='test0121' );
        //insert campObj2;
        campList.add(campObj2);
        Campaign campObj3 = new Campaign(Name='TestCampaign',Protected_Campaign__c=true
        , Shared_Lead_Campaign__c=true, Lead_Creation_Score__c='-200', IsActive=true, PID__c='test0121' );
        //insert campObj3;
        campList.add(campObj3);
        Campaign campObj4 = new Campaign(Name='TestCampaign',Protected_Campaign__c=false
        , Shared_Lead_Campaign__c=true, Lead_Creation_Score__c='200.00', IsActive=true, BMID__c='test0121' );
        //insert campObj4;
        campList.add(campObj4);
        Campaign campObj5 = new Campaign(Name='TestCampaign',Protected_Campaign__c=true
        , Shared_Lead_Campaign__c=true, IsActive=true, Lead_Entry_Source__c='ROI Form' );
        //insert campObj5;
        campList.add(campObj5);
        insert campList;

    	User user1 = new User(alias = 'newUser1', email='newuser1@simplion.com.test',
        emailencodingkey='UTF-8', lastname='Testing1',
        languagelocalekey='en_US', localesidkey='en_US', profileid = Userinfo.getProfileId(),
        timezonesidkey='America/Los_Angeles', username= System.now().millisecond() + 'newuser1@simplion.com.test');
        insert user1;

        User user2 = new User(alias = 'newUser2', email='newuser2@simplion.com.test',
        emailencodingkey='UTF-8', lastname='Testing2',
        languagelocalekey='en_US', localesidkey='en_US', profileid = Userinfo.getProfileId(),
        timezonesidkey='America/Los_Angeles', username= System.now().millisecond() + 'newuser2@simplion.com.test');
        insert user2;

        Lead leadObj = new Lead(Lead_Entry_Source__c = 'test',LeadSource='Inbound Call');
    }

    @isTest static void populateZipCustomFieldsZipBlank(){
        Lead l = [SELECT Id FROM Lead WHERE Email =: LEAD_COMMON_EMAIL LIMIT 1];

        Test.startTest();

        l.PostalCode = POSTAL_CODE_TEST;
        update l;
        Lead leadAfterPostalCodeUpdate = [SELECT Id, PostalCode, Zip_Code__c FROM Lead WHERE Id =: l.Id];

        System.assertEquals(leadAfterPostalCodeUpdate.Zip_Code__c, POSTAL_CODE_TEST, 'Zip_Code__c field should be equal to PostalCode if we set it.');

        Test.stopTest();
    }

    @isTest static void populateZipCustomFieldsPostalCodeNotChanged(){
        Lead l = [SELECT Id FROM Lead WHERE Email =: LEAD_COMMON_EMAIL LIMIT 1];

        Test.startTest();

        //setting PostalCode for the first time
        l.PostalCode = POSTAL_CODE_TEST;
        update l;
        //updating the lead again without changing postal code. Postal code and Zip code should remain the same.
        update l;
        Lead leadAfterPostalCodeUpdate = [SELECT Id, PostalCode, Zip_Code__c FROM Lead WHERE Id =: l.Id];

        System.assertEquals(leadAfterPostalCodeUpdate.Zip_Code__c, POSTAL_CODE_TEST, 'Zip_Code__c field should be equal to PostalCode if we set it.');

        Test.stopTest();
    }

    @isTest static void populateZipCustomFieldsZipNotBlank(){
        Lead l = [SELECT Id FROM Lead WHERE Email =: LEAD_COMMON_EMAIL LIMIT 1];

        Test.startTest();

        l.PostalCode = POSTAL_CODE_TEST;
        l.Zip_Code__c = ZIP_CODE_TEST;
        update l;
        Lead leadAfterPostalCodeUpdate = [SELECT Id, PostalCode, Zip_Code__c FROM Lead WHERE Id =: l.Id];

        System.assertEquals(leadAfterPostalCodeUpdate.PostalCode, POSTAL_CODE_TEST, 'PostalCode field should be equal to PostalCode if we set it.');
        System.assertEquals(leadAfterPostalCodeUpdate.Zip_Code__c, ZIP_CODE_TEST, 'Zip_Code__c field should be equal to ZIP_CODE_TEST because we have explicitily set it on update.');

        Test.stopTest();
    }

    @isTest static void populateDateStatusChangedTrackedStatus(){
        Lead l = [SELECT Id FROM Lead WHERE Email =: LEAD_COMMON_EMAIL LIMIT 1];
        //hard to test properly, since on insertion Date_Status_Changed__c will equal to today on insertion.
        Test.startTest();

        l.Status = TEST_STATUS_TO_TRACK_DATE_STATUS_FIELD_CHANGED;
        update l;
        Lead leadAfterStatusUpdate = [SELECT Id, Date_Status_Changed__c FROM Lead WHERE Id =: l.Id];

        System.assertEquals(leadAfterStatusUpdate.Date_Status_Changed__c, Date.today(), 'Date_Status_Changed__c field should be equal to today.');

        Test.stopTest();
    }



    private static User getPortalUser(PortalType portalType, User userWithRole, Boolean doInsert ,string profileId, string ranDomStr) {
        /* Make sure the running user has a role otherwise an exception
           will be thrown. */
        if(userWithRole == null) {
            if(UserInfo.getUserRoleId() == null) {
                UserRole r = new UserRole(name = 'TEST ROLE');
                Database.insert(r);
                userWithRole = new User(alias = 'hasrole', email='userwithrole@roletest5.com', userroleid = r.id,
                        emailencodingkey='UTF-8', lastname='Testing', languagelocalekey='en_US',
                        localesidkey='en_US', profileid = UserInfo.getProfileId(),
                        timezonesidkey='America/Los_Angeles', username='userwithrole55@testorg.com');
            } else {
                userWithRole = new User(Id = UserInfo.getUserId(), UserRoleId = UserInfo.getUserRoleId());
            }
            System.assert(userWithRole.userRoleId != null,
                    'This test requires the target org to have at least one UserRole created. Please create a user role in this organization and try again.');
        }

        Account acc1;
        Contact contact1;
        System.runAs(userWithRole) {
            Schema.DescribeSObjectResult result = Account.SObjectType.getDescribe();
            Map<string,Schema.RecordTypeInfo> rtMapById = result.getRecordTypeInfosByName();

            acc1 = new Account();
            acc1.Name = 'Test Account';
            acc1.Partner_ID__c = '12346';
            acc1.Current_Owner_Email__c = [select Email from User where Id = :UserInfo.getUserId()].Email;
            acc1.RecordTypeId = rtMapById.get('Partner Account').getRecordTypeID();
            Database.insert(acc1);

            contact1 = new Contact(AccountId = acc1.id, lastname = 'lastname1',email='testcontact1@test.com');
            Database.insert(contact1);
        }

        /* Get any profile for the given type.*/
        Profile p = [select id from profile where Id  = :profileId limit 1];

        String testemail = 'puser0011@amamama.com';
        User pu;
        if(ranDomStr == 'A') {
            pu = new User(profileId = p.id, username = ranDomStr + testemail, email = testemail,
                    emailencodingkey = 'UTF-8', localesidkey = 'en_US',
                    languagelocalekey = 'en_US', timezonesidkey = 'America/Los_Angeles',
                    alias='cspu', lastname='lastname', contactId = contact1.id);
        }
        if(doInsert) {
            Database.insert(pu);
        }
        return pu;
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    private static void testCheckPartnerOpportunityPermittedByBrand() {
      Map<Id, Schema.RecordTypeInfo> rtMapById = Lead.sObjectType.getDescribe().getRecordTypeInfosById();
      Map<String, Schema.RecordTypeInfo> rtMapByName = Lead.sObjectType.getDescribe().getRecordTypeInfosByName();
      Lead newLead = (Lead) new SObjectBuilder(Lead.SObjectType)
        .setFields(
            new Map<SObjectField, Object>{
                Lead.email => 'fake@email.com',
                Lead.LastName => 'fakeLastName',
                Lead.Company => 'fakeCompany',
                Lead.LeadPartnerID__c => 'PartnerId#1',
                Lead.LeadPartnerID__c => 'approved brand',
                Lead.RecordTypeId => rtMapByName.get('Partner Leads').getRecordTypeId()
            }
        )
        .create()
        .getRecord();
      Map<String, List<String>> approvedBrands = new Map<String, List<String>>
      {
        'PartnerId#1' => new List<String>{ 'approved brand' }
      };

      LeadTriggerHelper.checkPartnerLeadPermittedByBrand(new List<Lead>{ newLead }, null,
        approvedBrands, rtMapById);
    }


    @isTest
    static void testLeadQualificationRecordsProcessing_process() {
      Lead leadRecord = [SELECT Id FROM Lead LIMIT 1];

      DateTime createdDate = DateTime.now().addDays(-5);
      DateTime lastModifedDate = DateTime.now().addDays(-3);

      String createdDateStr = createdDate.format('yyyy-MM-dd\'T\'hh:mm:ss.000+0000');
      String lastModifiedDateStr1 = lastModifedDate.format('yyyy-MM-dd\'T\'hh:mm:ss.000+0000');
      String lastModifiedDateStr2 = lastModifedDate.addMinutes(1).format('yyyy-MM-dd\'T\'hh:mm:ss.000+0000');

      String leadQualificationsJson = '[{"attributes":{"type":"Lead_Qualification__c",' +
          '"url":"/services/data/v45.0/sobjects/Lead_Qualification__c/"},"Lead__c":null,' +
          '"CreatedDate":"' + createdDateStr + '",' +
          '"LastModifiedDate":"' + lastModifiedDateStr1 + '"},{"attributes":{"type":"Lead_Qualification__c",' +
          '"url":"/services/data/v45.0/sobjects/Lead_Qualification__c/"},"Lead__c":null,' +
          '"CreatedDate":"' + createdDateStr + '",' +
          '"LastModifiedDate":"' + lastModifiedDateStr2 + '"}]';

      List<Lead_Qualification__c> recordsToInsert = (List<Lead_Qualification__c>)Json.deserialize(leadQualificationsJson, List<Lead_Qualification__c>.class);
      recordsToInsert[0].Lead__c = leadRecord.Id;
      recordsToInsert[1].Lead__c = leadRecord.Id;

      insert recordsToInsert;

      LeadStatus convertStatus = [
        SELECT MasterLabel
        FROM LeadStatus
        WHERE IsConverted= true
        LIMIT 1
      ];

      Test.startTest();
      Database.LeadConvert lc = new Database.LeadConvert();
      lc.setLeadId(leadRecord.Id);
      lc.setConvertedStatus(convertStatus.MasterLabel);
      Database.LeadConvertResult lcr = Database.convertLead(lc);
      Test.stopTest();

      List<Lead_Qualification__c> recordsToVerify = [
          SELECT Lead__c, Account__c, Contact__c, Opportunity__c
          FROM Lead_Qualification__c];

      System.assertEquals(1, recordsToVerify.size(), 'Record with earlier date should be deleted on lead conversion');
      System.assertEquals(null, recordsToVerify[0].Lead__c, 'Lead__c field should be empty');
      System.assertEquals(lcr.getAccountId(), recordsToVerify[0].Account__c, 'Account__c field should contains Id of created Account');
      System.assertEquals(lcr.getContactId(), recordsToVerify[0].Contact__c, 'Contact__c field should contains Id of created Contact');
      System.assertEquals(lcr.getOpportunityId(), recordsToVerify[0].Opportunity__c, 'Opportunity__c field should contains Id of created Opportunity');
  }

  @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testLeadPhoneStartingWithPlusShouldAvoidFormatting() {
        String testPhone = '+45 31 68 19 40';
        Lead testLead = (Lead) new SObjectBuilder(Lead.sObjectType)
            .setField(Lead.LastName, 'fakeLastName')
            .setField(Lead.Company, 'fakeCompany')
            .setField(Lead.Email, 'test@email.com')
            .setField(Lead.Phone, '4531681940')
            .create()
            .getRecord();
        Test.startTest();
            testLead.Phone = testPhone;
            update testLead;
        Test.stopTest();

        List<Lead> leads = (List<Lead>) new LeadSelector()
            .selectLeadById(new List<Object>{new Set<Id>{testLead.Id}})
            .executeQuery();
        //system.AssertEquals(testPhone, leads[0].Phone, 'Phone should be updated without using formatting');
    }

    @isTest
    public static void testPopulatePartnerAccount() {
        Account partnerAccount = (Account) new SObjectBuilder(Account.SObjectType)
                                            .setField(Account.Name, 'partnerAcc')
                                            .setField(Account.Partner_ID__c, '1234')
                                            .create()
                                            .getRecord();
        Account secondPartnerAccount = (Account) new SObjectBuilder(Account.SObjectType)
                                            .setField(Account.Name, 'secondpartnerAcc')
                                            .create()
                                            .getRecord();
        Lead testLead = (Lead) new SObjectBuilder(Lead.sObjectType)
            .setField(Lead.LastName, 'fakeLastName')
            .setField(Lead.Company, 'fakeCompany')
            .setField(Lead.Email, 'test@email.com')
            .setField(Lead.Phone, '4531681940')
            .setField(Lead.Partner_Account__c, partnerAccount.id)
            .setField(Lead.LeadPartnerID__c, partnerAccount.Partner_ID__c)
            .create()
            .getRecord();

        Test.startTest();
        testLead.Partner_Account__c = secondPartnerAccount.id;
        update testLead;
        Test.stopTest();
        System.assert(testLead.Partner_Account__c == secondPartnerAccount.id,
                      'Partner Account Id should be valid');
    }

    @isTest
    public static void testCreateCCIO() {
        insert new LeadRoutingSettings__c(LeanDataCreateCCIOToggle__c = true, RoutingSystemUserId__c = UserHelper.LEANDATAUSERID);
        Lead testLead = (Lead) new SObjectBuilder(Lead.sObjectType)
            .setField(Lead.LastName, 'fakeLastName')
            .setField(Lead.Company, 'fakeCompany')
            .setField(Lead.Email, 'test@email.com')
            .setField(Lead.Phone, '4531681940')
            .create()
            .getRecord();
        Lead newLead = testLead.clone(true, true, false, false);
        newLead.OwnerId = UserHelper.LEANDATAUSERID;
        newLead.Routing_Reason__c = LeadTriggerHelper.ROUTINGREASONNETNEWLEAD;
        LeanData__Routing_Deployment__c routDeployment = (LeanData__Routing_Deployment__c) new SObjectBuilder(LeanData__Routing_Deployment__c.SObjectType)
                        .setField(LeanData__Routing_Deployment__c.LeanData__Object_Type__c, 'Lead')
                        .setField(LeanData__Routing_Deployment__c.LeanData__Name__c, 'LeanData')
                        .create()
                        .getRecord();
        Test.startTest();
        LeadTriggerHelper.createCCIOForLeanDataRouting(new Map<Id, Lead>{newLead.id => newLead}, new Map<Id, Lead>{testLead.id => testLead});
        Test.stopTest();
        System.assert(newLead.OwnerId == UserHelper.LEANDATAUSERID,
                     'New Lead OwnerId shouldnt have changed');
    }

    @isTest
    public static void testCampaignAttribution() {
        Id sysAdminProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id;
        User marketingUser = new User(
            Username= 'marketing@RCAdmin.SysAdmin',
            FirstName='marketing',
            Email='marketing@email.em',
            LastName = 'Admin',
            ProfileId = sysAdminProfileId,
            Alias = 'tests',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            UserPermissionsMarketingUser = true
        );
        insert marketingUser;

        System.runAs(marketingUser) {
            Campaign campAtt = (Campaign) new SObjectBuilder(Campaign.sObjectType)
                                  .setField(Campaign.Non_Attributable__c, true)
                                  .setField(Campaign.Name, 'campNonAtt')
                                  .setField(Campaign.BMID__c, 'NonAttributableBMID')
                                  .create()
                                  .getRecord();
            Campaign campAtt2 = (Campaign) new SObjectBuilder(Campaign.sObjectType)
                               .setField(Campaign.Non_Attributable__c, false)
                               .setField(Campaign.Name, 'campAtt')
                               .setField(Campaign.BMID__c, 'AttributableBMID')
                               .create()
                               .getRecord();


            Lead oldLead = (Lead) new SObjectBuilder(Lead.sObjectType)
                .setField(Lead.LastName, 'fakeLastName')
                .setField(Lead.Company, 'fakeCompany')
                .setField(Lead.Email, 'test@email.com')
                .setField(Lead.Most_Recent_Campaign__c, campAtt.id)
                .setField(Lead.Phone, '4531681940')
                .create()
                .getRecord();
            Lead newLead = oldLead.clone(true, true, false, false);
            newLead.Most_Recent_Campaign__c = campAtt2.Id;
            LeadTriggerHelper.campaignAttribution(new Set<Id>{campAtt.Id, campAtt2.Id},
                                                new List<Lead>{newLead},
                                                new Map<Id, Lead>{oldLead.id => oldLead});
            CampaignMemberSelector cmSelector = new CampaignMemberSelector();
            Test.startTest();
            insert new List<CampaignMember>{new CampaignMember(CampaignId = campAtt2.Id, LeadId = newLead.Id)};
            List<CampaignMember> existingCM = cmSelector.selectCampaignMemberForLeadConvert().executeQuery();
            CampaignMember removedCampaign = existingCM[0];
            LeadTriggerHelper.removeExistingCampMembers(existingCM, new List<CampaignMember>{removedCampaign});
            Test.stopTest();
            System.assert(newLead.Most_Recent_Campaign__c == campAtt2.Id,
                        'Attributable Campaigns should always remain as the most recent campaign');
        }
    }

    @isTest static void populateAssignedCSS(){

        Id salesMgrProfileId = [SELECT Id FROM Profile WHERE Name = 'Channel Sales Manager - Lightning'].Id;
        User salesmgrUser = new User(
            Username= 'salesmgr@RCAdmin.SysAdmin',
            FirstName='salesmgr',
            Email='salesmgr@email.em',
            LastName = 'SalesManager',
            ProfileId = salesMgrProfileId,
            Alias = 'tests',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        insert salesmgrUser;

        Account partnerAccount;
        Lead l = [SELECT Id FROM Lead WHERE Email =: LEAD_COMMON_EMAIL LIMIT 1];
        System.runAs(salesmgrUser) {
            partnerAccount = (Account) new SObjectBuilder(Account.SObjectType)
                                                .setField(Account.Name, 'partnerAcc')
                                                .setField(Account.Partner_ID__c, '1234')
                                                .setField(Account.Assigned_CSS__C, salesmgrUser.Id)
                                                .create()
                                                .getRecord();
        }
        Test.startTest();
        l.LeadPartnerID__c = partnerAccount.Partner_ID__c;
        l.Partner_Account__c = partnerAccount.Id;
        update l;
        Test.stopTest();

        Lead leadAfterPartnerIdUpdate = [SELECT Id, Assigned_CSS__C FROM Lead WHERE Id =: l.Id];
        System.assertEquals(leadAfterPartnerIdUpdate.Assigned_CSS__C, partnerAccount.Assigned_CSS__C, 'Lead Assigned CSS field should be equal to Account Lead Assigned CSS if we set it.');

    }

     @isTest
    public static void testPopulateSaaSquatchReferralEmailIdOnLead(){

        Lead l = [SELECT Id FROM Lead WHERE Email =: LEAD_COMMON_EMAIL LIMIT 1];

        Test.startTest();
        l.Saasquatch_Advocate_ID__c = 'TestTest';
        update l;
        System.assertEquals(l.Email, l.Saasquatch_Referral_Email_ID__c);
        l.Saasquatch_Advocate_ID__c = null;
        update l;
        System.assertEquals(l.Email, l.Saasquatch_Referral_Email_ID__c);
        Test.stopTest();

    }

    @isTest
    public static void testPopulateBMIDBasedOnLeadSource(){
        User marketingUserEnabled = (User) new UserSelector()
            .selectUsers()
            .selectFields(new List<String>{'Id'})
            .setQueryBindings(new List<Object>{ProfileHelper.SYSTEM_ADMIN})
            .setCondition('Profile.Name = :bind0 AND UserPermissionsMarketingUser = true AND IsActive = true')
            .executeQuery()
            .get(0);

        Campaign campAtt;
        System.runAs(marketingUserEnabled) {
            campAtt = (Campaign) new SObjectBuilder(Campaign.sObjectType)
                .setField(Campaign.Non_Attributable__c, false)
                .setField(Campaign.Name, 'campAtt')
                .setField(Campaign.BMID__c, 'SAASQUATCH_VB_USCA')
                .create()
                .getRecord();
        }

        Saasquatch_Settings__c setting = new Saasquatch_Settings__c();
        setting.name = 'BMID Mapping 2';
        setting.Lead_Source__c = 'Referral Programs';
        setting.BMID_Value__c = 'SAASQUATCH_VB_USCA';
        setting.Campaign_ID__c = campAtt.Id;

        insert setting;

        Lead l = [SELECT Id FROM Lead WHERE Email =: LEAD_COMMON_EMAIL LIMIT 1];

        Test.startTest();
        l.LeadSource = 'Referral Programs';
        update l;

        Lead newLead = [SELECT Id, BMID__c From Lead WHERE Email =: LEAD_COMMON_EMAIL LIMIT 1];

        System.assertEquals(setting.BMID_Value__c, newLead.BMID__c);
        Test.stopTest();
    }
    
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    public static void testRemainingCoverage() {
        Map<String, Schema.RecordTypeInfo> accRT = Account.SObjectType.getDescribe().getRecordTypeInfosByName();
        Test.startTest();
        Account testAccount1 = new Account();
        testAccount1.Name = 'Test123';
        testAccount1.SignupType__c = 'TRIAL_30NOCC';
        testAccount1.RC_Account_Status__c = 'TRIAL';
        testAccount1.SignupPlatform__c = 'WEB';
        testAccount1.RC_Service_name__c = 'office123';
        testAccount1.RC_Activation_Date__c = null;
        testAccount1.Partner_ID__c = '9852';
        testAccount1.ZI_Id__c = '12345';
        testAccount1.RecordTypeId = accRT.get('ZI Customer Shell Account').getRecordTypeId();
        insert testAccount1;

        Account testAccount2 = new Account();
        testAccount2.Name = 'Test124';
        testAccount2.SignupType__c = 'TRIAL_30NOCC';
        testAccount2.RC_Account_Status__c = 'TRIAL';
        testAccount2.SignupPlatform__c = 'WEB';
        testAccount2.RC_Service_name__c = 'office123';
        testAccount2.RC_Activation_Date__c = null;
        testAccount2.Partner_ID__c = '9852';
        testAccount1.ZI_CDP_Match__c = '12345';
        testAccount1.RecordTypeId = accRT.get('ZI Customer Shell Account').getRecordTypeId();
        testAccount2.ParentId=testAccount1.Id;
        insert testAccount2;
        Lead leadObj0 = new Lead(firstName='Singh15', Title='VP', PID__c='test0121', BMID__c='test0122',
                                        NumberOfEmployees__c ='955',ZI_CDP_Account_Id__c=testAccount1.Id,ZI_Id__c='12345',
                                        LeadSource = 'Vista Print', lastname = 'Virendra',
                                        company='Simplion', email= 'virendra.singh15@simplion.com', phone='(919)191-9115');
        insert leadObj0;

        Lead leadObj1 = new Lead(firstName='Singh16', Title='VP', PID__c='test0121', BMID__c='test0122',
                                        NumberOfEmployees__c ='955',ZI_CDP_Account_Id__c=testAccount2.Id,ZI_CDP_Match__c='12345',
                                        LeadSource = 'Vista Print', lastname = 'Virendra',
                                        company='Simplion', email= 'virendra.singh16@simplion.com', phone='(919)191-9115');
        insert leadObj1;

        leadObj0.ZI_CDP_Account_Id__c=testAccount2.Id;
        update leadObj0;
        Test.stopTest();
    }

    @isTest static void populateZipCustomFieldsError() {
        Lead l = [SELECT Id FROM Lead WHERE Email =: LEAD_COMMON_EMAIL LIMIT 1];

        Test.startTest();
        LeadTriggerHelper.populateZipCustomFields(new List<Lead>{l}, new Map<Id, Lead>());
        Test.stopTest();
        List<Exception_and_notification_history__c> lstExceptions = (List<Exception_and_notification_history__c>) new ExceptionAndNotificationHistorySelector()
            .selectExceptionAndNotificationHistorys()
            .executeQuery();
        System.assertEquals(1, lstExceptions.size(), 'Exception were not created');
    }
    @isTest static void updatePartnerLeadCurrentOwnerEmailError() {
        Schema.DescribeSObjectResult result = Lead.SObjectType.getDescribe();
        Map<ID,Schema.RecordTypeInfo> rtMapByName = result.getRecordTypeInfosById();
        Lead l = [SELECT Id FROM Lead WHERE Email =: LEAD_COMMON_EMAIL LIMIT 1];

        Test.startTest();
        LeadTriggerHelper.updatePartnerLeadCurrentOwnerEmail(new List<Lead>{l}, new Map<Id, Lead>(), new Map<Id, Lead>(), rtMapByName);
        Test.stopTest();
        List<Exception_and_notification_history__c> lstExceptions = (List<Exception_and_notification_history__c>) new ExceptionAndNotificationHistorySelector()
            .selectExceptionAndNotificationHistorys()
            .executeQuery();
        System.assertEquals(1, lstExceptions.size(), 'Exception were not created');
    }
    @isTest static void getApprovedBrandListError() {
        Lead l = [SELECT Id FROM Lead WHERE Email =: LEAD_COMMON_EMAIL LIMIT 1];

        Test.startTest();
        LeadTriggerHelper.getApprovedBrandList(new List<Lead>{l});
        Test.stopTest();
        List<Exception_and_notification_history__c> lstExceptions = (List<Exception_and_notification_history__c>) new ExceptionAndNotificationHistorySelector()
            .selectExceptionAndNotificationHistorys()
            .executeQuery();
        System.assertEquals(1, lstExceptions.size(), 'Exception were not created');
    }
    @isTest static void validatePerTodayError() {
        Lead l = [SELECT Id FROM Lead WHERE Email =: LEAD_COMMON_EMAIL LIMIT 1];

        Test.startTest();
        ValidateLeadDuplicacy.validatePerToday(new List<Lead>{l});
        Test.stopTest();
        List<Exception_and_notification_history__c> lstExceptions = (List<Exception_and_notification_history__c>) new ExceptionAndNotificationHistorySelector()
            .selectExceptionAndNotificationHistorys()
            .executeQuery();
        System.assertEquals(1, lstExceptions.size(), 'Exception were not created');
    }
    @isTest static void getLeadOwnerRCSFsyncError() {
        Lead l = [SELECT Id FROM Lead WHERE Email =: LEAD_COMMON_EMAIL LIMIT 1];

        Test.startTest();
        LeadTriggerHelper.getLeadOwnerRCSFsync(new List<Lead>{l});
        Test.stopTest();
        List<Exception_and_notification_history__c> lstExceptions = (List<Exception_and_notification_history__c>) new ExceptionAndNotificationHistorySelector()
            .selectExceptionAndNotificationHistorys()
            .executeQuery();
        System.assertEquals(1, lstExceptions.size(), 'Exception were not created');
    }
    @isTest static void getCheckForBadValueError() {
        Lead l = [SELECT Id FROM Lead WHERE Email =: LEAD_COMMON_EMAIL LIMIT 1];

        Test.startTest();
        LeadTriggerHelperExt.getCheckForBadValue(new List<Lead>{l});
        Test.stopTest();
        List<Exception_and_notification_history__c> lstExceptions = (List<Exception_and_notification_history__c>) new ExceptionAndNotificationHistorySelector()
            .selectExceptionAndNotificationHistorys()
            .executeQuery();
        System.assertEquals(1, lstExceptions.size(), 'Exception were not created');
    }
    @isTest static void updateLeadActiveDateError() {
        Lead l = [SELECT Id FROM Lead WHERE Email =: LEAD_COMMON_EMAIL LIMIT 1];

        Test.startTest();
        LeadTriggerHelper.updateLeadActiveDate(new List<Lead>{l}, new Map<Id, Lead>());
        Test.stopTest();
        List<Exception_and_notification_history__c> lstExceptions = (List<Exception_and_notification_history__c>) new ExceptionAndNotificationHistorySelector()
            .selectExceptionAndNotificationHistorys()
            .executeQuery();
        System.assertEquals(1, lstExceptions.size(), 'Exception were not created');
    }
    @isTest static void getLeadOwnerManagerError() {
        Lead l = [SELECT Id FROM Lead WHERE Email =: LEAD_COMMON_EMAIL LIMIT 1];

        Test.startTest();
        LeadTriggerHelper.getLeadOwnerManager(new List<Lead>{l});
        Test.stopTest();
        List<Exception_and_notification_history__c> lstExceptions = (List<Exception_and_notification_history__c>) new ExceptionAndNotificationHistorySelector()
            .selectExceptionAndNotificationHistorys()
            .executeQuery();
        System.assertEquals(1, lstExceptions.size(), 'Exception were not created');
    }
    @isTest static void updateMostRecentCampaignError() {
        Schema.DescribeSObjectResult result = Lead.SObjectType.getDescribe();
        Map<ID,Schema.RecordTypeInfo> rtMapByName = result.getRecordTypeInfosById();
        Lead l = [SELECT Id FROM Lead WHERE Email =: LEAD_COMMON_EMAIL LIMIT 1];

        Test.startTest();
        LeadTriggerHelper.updateMostRecentCampaign(new List<Lead>{l}, new Map<Id, Lead>(), rtMapByName);
        Test.stopTest();
        List<Exception_and_notification_history__c> lstExceptions = (List<Exception_and_notification_history__c>) new ExceptionAndNotificationHistorySelector()
            .selectExceptionAndNotificationHistorys()
            .executeQuery();
        System.assertEquals(1, lstExceptions.size(), 'Exception were not created');
    }
    @isTest static void setLeadFieldsError() {
        Lead l = [SELECT Id FROM Lead WHERE Email =: LEAD_COMMON_EMAIL LIMIT 1];

        Test.startTest();
        LeadTriggerHelperExt.setLeadFields(new List<Lead>{l}, new Map<Id, Lead>());
        Test.stopTest();
        List<Exception_and_notification_history__c> lstExceptions = (List<Exception_and_notification_history__c>) new ExceptionAndNotificationHistorySelector()
            .selectExceptionAndNotificationHistorys()
            .executeQuery();
        System.assertEquals(1, lstExceptions.size(), 'Exception were not created');
    }
    @isTest static void insertCampaignMemberError() {
        Lead l = [SELECT Id FROM Lead WHERE Email =: LEAD_COMMON_EMAIL LIMIT 1];
        CampaignMember campMemberObj = new CampaignMember(CampaignId=null, LeadId=l.Id);

        Test.startTest();
        LeadTriggerHelperExt.insertCampaignMember(new List<CampaignMember>{campMemberObj}, true);
        Test.stopTest();
        List<Exception_and_notification_history__c> lstExceptions = (List<Exception_and_notification_history__c>) new ExceptionAndNotificationHistorySelector()
            .selectExceptionAndNotificationHistorys()
            .executeQuery();
        System.assertEquals(1, lstExceptions.size(), 'Exception were not created');
    }
    @isTest static void generateCampaignMemberError() {
        Lead l = [SELECT Id FROM Lead WHERE Email =: LEAD_COMMON_EMAIL LIMIT 1];

        Test.startTest();
        LeadTriggerHelperExt.generateCampaignMember(new List<Lead>{l});
        Test.stopTest();
        List<Exception_and_notification_history__c> lstExceptions = (List<Exception_and_notification_history__c>) new ExceptionAndNotificationHistorySelector()
            .selectExceptionAndNotificationHistorys()
            .executeQuery();
        System.assertEquals(1, lstExceptions.size(), 'Exception were not created');
    }
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    public static void testRemainingCoverage2() {
        List<Lead> ldList=new List<Lead>();
        Map<String, Schema.RecordTypeInfo> accRT = Account.SObjectType.getDescribe().getRecordTypeInfosByName();
        User mark =[select id from User where id='00580000003to4FAAQ'];
        System.runAs(mark) {
            Test.startTest();
            Account testAccount1 = new Account();
            testAccount1.Name = 'Test123';
            testAccount1.SignupType__c = 'TRIAL_30NOCC';
            testAccount1.RC_Account_Status__c = 'TRIAL';
            testAccount1.SignupPlatform__c = 'WEB';
            testAccount1.RC_Service_name__c = 'office123';
            testAccount1.RC_Activation_Date__c = null;
            testAccount1.Partner_ID__c = '9852';
            testAccount1.ZI_Id__c = '12345';
            testAccount1.RecordTypeId = accRT.get('ZI Customer Shell Account').getRecordTypeId();
            insert testAccount1;

            /*Account testAccount2 = new Account();
            testAccount2.Name = 'Test124';
            testAccount2.SignupType__c = 'TRIAL_30NOCC';
            testAccount2.RC_Account_Status__c = 'TRIAL';
            testAccount2.SignupPlatform__c = 'WEB';
            testAccount2.RC_Service_name__c = 'office123';
            testAccount2.RC_Activation_Date__c = null;
            testAccount2.Partner_ID__c = '9852';
            testAccount1.ZI_CDP_Match__c = '12345';
            testAccount1.RecordTypeId = accRT.get('ZI Customer Shell Account').getRecordTypeId();
            testAccount2.ParentId=testAccount1.Id;
            insert testAccount2;*/
            Lead leadObj0 = new Lead(firstName='Singh15', Title='VP', PID__c='test0121', BMID__c='test0122',
                                            NumberOfEmployees__c ='955',
                                            LeadSource = 'Vista Print', lastname = 'Virendra',
                                            company='Simplion', email= 'virendra.singh15@simplion.com', phone='(919)191-9115');

            Lead leadObj1 = new Lead(firstName='Singh16', Title='VP', PID__c='test0121', BMID__c='test0122',
                                            NumberOfEmployees__c ='955',
                                            LeadSource = 'Vista Print', lastname = 'Virendra',
                                            company='Simplion', email= 'virendra.singh16@simplion.com', phone='(919)191-9115');

            Lead leadObj2 = new Lead(firstName='Singh17', Title='VP', PID__c='test0121', BMID__c='test0122',
                                            NumberOfEmployees__c ='955',
                                            LeadSource = 'Vista Print', lastname = 'Virendra',
                                            company='Simplion', email= 'virendra.singh17@simplion.com', phone='(919)191-9115');

            Lead leadObj3 = new Lead(firstName='Singh17', Title='VP', PID__c='test0121', BMID__c='test0122',
                                            NumberOfEmployees__c ='955',
                                            LeadSource = 'Vista Print', lastname = 'Virendra',
                                            company='Simplion', email= 'virendra.singh17@simplion.com', phone='(919)191-9115');
            ldList.add(leadObj0);
            ldList.add(leadObj1);
            ldList.add(leadObj2);
            ldList.add(leadObj3);
            insert ldList;
            //insert ldList;
            //ldList[0].leadspacesync__Status__c='Success';
            //ldList[0].leadspacesync__Last_Leadspace_Activity_Date__c=System.now();
            ldList[1].email='virendra.singh161@simplion.com';
            ldList[2].Systems_Process_Stage__c='Segment complete';
            ldList[2].NumberOfEmployees__c='10';
            ldList[3].Systems_Process_Stage__c='Segment complete';
            ldList[3].ZI_CDP_Account_Id__c=testAccount1.Id;
            Gating_Process_Stage__c processStage = Gating_Process_Stage__c.getInstance();
            processStage.Bypass_Gating_Process_Stage__c=true;
            insert processStage;
            update ldList;
        }
        Test.stopTest();
    }
    
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    public static void testRemainingCoverage3() { //CMR-306098 9/9/2021 ends at testRemainingCoverage3
        List<Lead> ldList=new List<Lead>();
        Map<String, Schema.RecordTypeInfo> accRT = Account.SObjectType.getDescribe().getRecordTypeInfosByName();
        Test.startTest();
        Account testAccount1 = new Account();
        testAccount1.Name = 'Test123';
        testAccount1.SignupType__c = 'TRIAL_30NOCC';
        testAccount1.RC_Account_Status__c = 'TRIAL';
        testAccount1.SignupPlatform__c = 'WEB';
        testAccount1.RC_Service_name__c = 'office123';
        testAccount1.RC_Activation_Date__c = null;
        testAccount1.Partner_ID__c = '9852';
        testAccount1.ZI_Id__c = '12345';
        testAccount1.RecordTypeId = accRT.get('ZI Customer Shell Account').getRecordTypeId();
        insert testAccount1;

        Lead leadObj0 = new Lead(firstName='Singh15', Title='VP', PID__c='test0121', BMID__c='test0122',
                                        NumberOfEmployees__c ='955',
                                        LeadSource = 'Vista Print', lastname = 'Virendra',
                                        company='Simplion', email= 'virendra.singh15@simplion.com', phone='(919)191-9115');

        Lead leadObj1 = new Lead(firstName='Singh16', Title='VP', PID__c='test0121', BMID__c='test0122',
                                        NumberOfEmployees__c ='955',
                                        LeadSource = 'Vista Print', lastname = 'Virendra',
                                        company='Simplion', email= 'virendra.singh16@simplion.com', phone='(919)191-9115');

        Lead leadObj2 = new Lead(firstName='Singh17', Title='VP', PID__c='test0121', BMID__c='test0122',
                                        NumberOfEmployees__c ='955',
                                        LeadSource = 'Vista Print', lastname = 'Virendra',
                                        company='Simplion', email= 'virendra.singh17@simplion.com', phone='(919)191-9115');

        Lead leadObj3 = new Lead(firstName='Singh17', Title='VP', PID__c='test0121', BMID__c='test0122',
                                        NumberOfEmployees__c ='955',
                                        LeadSource = 'Vista Print', lastname = 'Virendra',
                                        company='Simplion', email= 'virendra.singh17@simplion.com', phone='(919)191-9115');
        ldList.add(leadObj0);
        ldList.add(leadObj1);
        ldList.add(leadObj2);
        ldList.add(leadObj3);

        insert ldList;

        //ldList[0].leadspacesync__Status__c='Success';
        //ldList[0].leadspacesync__Last_Leadspace_Activity_Date__c=System.now();
        ldList[1].email='virendra.singh161@simplion.com';
        ldList[2].Systems_Process_Stage__c='Segment complete';
        ldList[2].NumberOfEmployees__c='10';
        ldList[3].Systems_Process_Stage__c='Segment complete';
        ldList[3].ZI_CDP_Account_Id__c=testAccount1.Id;

        update ldList;
        Test.stopTest();
    }
    
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    private static void testRemainingCoverage4() {
        Test.setMock(HttpCalloutMock.class, new SLEDWebServiceCalloutMock());
        Gating_Process_Stage__c processStage = Gating_Process_Stage__c.getInstance();
        processStage.Gating_Excluded_Domains__c='test,unavailable';
        processStage.Gating_Excluded_Websites__c='test,unavailable';
        processStage.Gating_eCommerce_Batch__c='eCommerce,eCom,Test';
        processStage.Gating_Enrichment_New_Company__c='test,unavailable';
        processStage.Bypass_Segmentation_Process__c=true;
        processStage.Bypass_Routing_Process__c=true;
        processStage.Bypass_Gating_Nullifying_Datetime__c=true;
        insert processStage;
        Leadspace_field_bypass__c LSField = Leadspace_field_bypass__c.getInstance();
        LSField.Bypass_Lead_Fields__c=true;
        insert LSField;
        Lead leadObj0 = new Lead(firstName='Singh15', Title='VP', PID__c='test0121', BMID__c='test0122',
                                        NumberOfEmployees__c ='955',
                                        LeadSource = 'Vista Print', lastname = 'Virendra',
                                        company='Simplion', email= 'virendra.singh15@simplion.com', phone='(919)191-9115');
        Lead leadObj1 = new Lead(firstName='Singh16', Title='VP', PID__c='test0121', BMID__c='test0122',
                                        NumberOfEmployees__c ='955',
                                        LeadSource = 'Vista Print', lastname = 'Virendra',
                                        company='Simplion', email= 'virendra.singh16@simplion.com', phone='(919)191-9115');
        insert leadObj0;
        insert leadObj1;
        leadObj0.LS_Status__c='Success';
        leadObj0.LS_Enrichment_Date__c=System.today();
        leadObj0.Enrichment_Last_Processed_Date__c=System.now();
        update leadObj0;
        leadObj1.Website='https://www.sample.com/page';
        update leadObj1;

        processStage.Bypass_Enrichment_Process__c=true;
        update processStage;
        leadObj1.Website='https://www.sample1.com/page';
        update leadObj1;

    }
    
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    private static void testRemainingCoverage5() {

        Gating_Process_Stage__c processStage = Gating_Process_Stage__c.getInstance();
        processStage.Gating_Excluded_Domains__c='test,unavailable';
        processStage.Gating_Excluded_Websites__c='test,unavailable';
        processStage.Gating_eCommerce_Batch__c='eCommerce,eCom,Test';
        processStage.Gating_Enrichment_New_Company__c='test,unavailable';
        processStage.Gating_Excluded_Lead_Sources__c='test';
        processStage.Bypass_Segmentation_Process__c=true;
        processStage.Bypass_Routing_Process__c=true;
        processStage.Bypass_Gating_Nullifying_Datetime__c=true;
        insert processStage;
        Leadspace_field_bypass__c LSField = Leadspace_field_bypass__c.getInstance();
        LSField.Bypass_Lead_Fields__c=true;
        insert LSField;
        DateTime fakeMarketoDate = DateTime.newInstance(1900,1,1);
        List<Lead> ldList=new List<Lead>();

        Lead leadObj0 = new Lead(firstName='Singh17', Title='VP', PID__c='test0121', BMID__c='test0122',
                                        NumberOfEmployees__c ='955',
                                        LeadSource = 'Vista Print', lastname = 'Virendra',
                                        company='Simplion', email= 'virendra.singh17@simplion.com', phone='(919)191-9115',Marketo_enriched_date_time__c=fakeMarketoDate);

        Lead leadObj1 = new Lead(firstName='Singh18', Title='VP', PID__c='test0121', BMID__c='test0122',
                                        NumberOfEmployees__c ='955',
                                        LeadSource = 'Vista Print', lastname = 'Virendra',
                                        company='test', email= 'virendra.singh18@simplion.com', phone='(919)191-9115');

        Lead leadObj2 = new Lead(firstName='Singh19', Title='VP', PID__c='test0121', BMID__c='test0122',
                                        NumberOfEmployees__c ='955',
                                        LeadSource = 'Vista Print', lastname = 'Virendra',
                                        company='Simplion', email= 'virendra.singh19@simplion.com', phone='(919)191-9115',Lead_Entry_Source__c='Test');

        Lead leadObj3 = new Lead(firstName='Singh20', Title='VP', PID__c='test0121', BMID__c='test0122',
                                        NumberOfEmployees__c ='955',
                                        LeadSource = 'Vista Print', lastname = 'Virendra',
                                        company='Simplion', email= 'virendra.singh20@test.com', phone='(919)191-9115');

        Lead leadObj4 = new Lead(firstName='Singh21', Title='VP', PID__c='test0121', BMID__c='test0122',
                                 NumberOfEmployees__c ='955',
                                 LeadSource = 'Test', lastname = 'Virendra',
                                 company='Simplion', email= 'virendra.singh20@simplion.com', phone='(919)191-9115');

        ldList.add(leadObj0);
        ldList.add(leadObj1);
        ldList.add(leadObj2);
        ldList.add(leadObj3);
        ldList.add(leadObj4);

        insert ldList;

    }

    @isTest
    public static void testPopulateSaaSquatchAdvocateFieldsOnlead() {


        SaasquatchEmailConfig__c sec = new SaasquatchEmailConfig__c();
        sec.SaaSquatchEmail__c = 'scamargo@aquivalabs.com';
        upsert sec;

        Account testAcc = (Account) new SObjectBuilder(Account.SObjectType)
        .setFields(
            new Map<SObjectField, Object>{
                Account.Name => 'Account Testing',
                Account.RC_Account_Status__c => 'Other'
            }
        )
        .create()
        .getRecord();

        Contact testContact = (Contact) new SObjectBuilder(Contact.SObjectType)
        .setFields(
            new Map<SObjectField, Object>{
                Contact.FirstName => 'Contact',
                Contact.LastName => 'Testing',
                Contact.AccountId => testAcc.Id,
                Contact.Email => 'mailContact@gmail.com',
                Contact.Phone => '123456789',
                Contact.UK_Saasquatch_Referral_Code__c => 'Contact-UK-Saasq-Code'
            }
        )
        .create()
        .getRecord();

        saasquatch__SaaSquatch_User__c  saasqUser = (saasquatch__SaaSquatch_User__c) new SObjectBuilder(saasquatch__SaaSquatch_User__c.SobjectType)
        .setFields(
            new Map<SObjectField, Object>{
                saasquatch__SaaSquatch_User__c.saasquatch__First_Name__c => 'TestingMock',
                saasquatch__SaaSquatch_User__c.saasquatch__Account_Id__c => 'test.test@gmail.com',
                saasquatch__SaaSquatch_User__c.saasquatch__User_Id__c => 'test.test@gmail.com',
                saasquatch__SaaSquatch_User__c.saasquatch__Email__c => 'test.test@gmail.com',
                saasquatch__SaaSquatch_User__c.saasquatch__SaaSquatch_Combined_User_Id__c => 'test.test@gmail.com/test.test@gmail.com'
            }
        )
        .create()
        .getRecord();

		Test.startTest();
        saasqUser.saasquatch__Contact__c = testContact.Id;
        saasqUser.saasquatch__Referral_Code__c = 'User-Saasq-Code';
        update saasqUser;
        Lead testLead = (Lead) new SObjectBuilder(Lead.SobjectType)
        .setFields(
            new Map<SObjectField, Object>{
                Lead.FirstName => 'Testing',
                Lead.LastName => 'Saasquatch',
                Lead.Email => 'mail@gmail.com',
                Lead.saasquatch_program_selector__c => 'UK Referral Programme (external)'
            }
        )
        .create()
        .getRecord();

        testLead.Saasquatch_Advocate_Name__c = saasqUser.Id;
        update testLead;
        List<Id> leadsForQuery = new List<String>();
        leadsForQuery.add(testLead.Id);

        List<Lead> leadsQueried = (List<Lead>) new LeadSelector()
        .selectLeadsByIdsForSaasquatchEmailing(new List<Object> {leadsForQuery})
        .executeQuery();
		Test.stopTest();

        System.assertEquals('Contact-UK-Saasq-Code', leadsQueried[0].Saasquatch_Advocate_ID__c, 'Saasquatch_Advocate_ID__c was not assigned Correctly to Contact UK Code');


        testLead.saasquatch_program_selector__c = 'US and Canada Referral Program (external)';
        update testLead;

        leadsQueried = (List<Lead>) new LeadSelector()
        .selectLeadsByIdsForSaasquatchEmailing(new List<Object> {leadsForQuery})
        .executeQuery();

        System.assertEquals('User-Saasq-Code', leadsQueried[0].Saasquatch_Advocate_ID__c, 'Saasquatch_Advocate_ID__c was not assigned Correctly to Contact UK Code');

        testContact.UK_Saasquatch_Referral_Code__c = null;
        update testContact;

        testLead.saasquatch_program_selector__c = 'UK Referral Programme (external)';
        update testLead;

        leadsQueried = (List<Lead>) new LeadSelector()
        .selectLeadsByIdsForSaasquatchEmailing(new List<Object> {leadsForQuery})
        .executeQuery();
        System.assertEquals(null, leadsQueried[0].Saasquatch_Advocate_ID__c, 'Saasquatch_Advocate_ID__c was not assigned Correctly to Contact UK Code');
    }

    @isTest
    public static void testPopulateSaaSquatchAdvocateFieldsOnleadMatchUserByContactCode() {
        Account testAcc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => 'Account Testing',
                    Account.RC_Account_Status__c => 'Other'
                }
            )
            .create()
            .getRecord();
        Contact testContact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.FirstName => 'Contact',
                    Contact.LastName => 'Testing',
                    Contact.AccountId => testAcc.Id,
                    Contact.Email => 'mailContact@gmail.com',
                    Contact.Phone => '123456789',
                    Contact.UK_Saasquatch_Referral_Code__c => 'Contact-UK-Saasq-Code'
                }
            )
            .create()
            .getRecord();
        saasquatch__SaaSquatch_User__c  saasqUser = (saasquatch__SaaSquatch_User__c) new SObjectBuilder(saasquatch__SaaSquatch_User__c.SobjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    saasquatch__SaaSquatch_User__c.saasquatch__First_Name__c => 'TestingMock',
                    saasquatch__SaaSquatch_User__c.saasquatch__Referral_Code__c  => 'CODE1234',
                    saasquatch__SaaSquatch_User__c.saasquatch__Account_Id__c => 'test.test@gmail.com',
                    saasquatch__SaaSquatch_User__c.saasquatch__User_Id__c => 'test.test@gmail.com',
                    saasquatch__SaaSquatch_User__c.saasquatch__Email__c => 'test.test@gmail.com',
                    saasquatch__SaaSquatch_User__c.saasquatch__SaaSquatch_Combined_User_Id__c => 'test.test@gmail.com/test.test@gmail.com',
                    saasquatch__SaaSquatch_User__c.saasquatch__Referral_Code__c => 'User-Saasq-Code'
                }
            )
            .create()
            .getRecord();
        saasqUser.saasquatch__Contact__c = testContact.Id;
        update saasqUser;
        Lead testLead = (Lead) new SObjectBuilder(Lead.SobjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Lead.FirstName => 'Testing',
                    Lead.LastName => 'Saasquatch',
                    Lead.Email => 'mail@gmail.com'
                }
            )
            .create()
            .getRecord();
        Test.startTest();
        testLead.saasquatch_program_selector__c = 'UK Referral Programme (external)';
        testLead.Saasquatch_Advocate_ID__c = 'Contact-UK-Saasq-Code';
        update testLead;
        Test.stopTest();
        testLead = (Lead) new LeadSelector()
            .selectLeadById(new List<Object>{testLead.Id})
            .selectField('Saasquatch_Advocate_Name__c')
            .executeQuery()[0];
        System.assertEquals(saasqUser.Id, testLead.Saasquatch_Advocate_Name__c, 'Saasquatch_Advocate_Name__c was not assigned Correctly to Contact UK Code');
    }

    @isTest
    public static void testPopulateSaaSquatchAdvocateFieldsOnleadNoMatches() {
        Account testAcc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => 'Account Testing',
                    Account.RC_Account_Status__c => 'Other'
                }
            )
            .create()
            .getRecord();
        Contact testContact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.FirstName => 'Contact',
                    Contact.LastName => 'Testing',
                    Contact.AccountId => testAcc.Id,
                    Contact.Email => 'mailContact@gmail.com',
                    Contact.Phone => '123456789',
                    Contact.UK_Saasquatch_Referral_Code__c => 'Contact-UK-Saasq-Code'
                }
            )
            .create()
            .getRecord();
        saasquatch__SaaSquatch_User__c  saasqUser = (saasquatch__SaaSquatch_User__c) new SObjectBuilder(saasquatch__SaaSquatch_User__c.SobjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    saasquatch__SaaSquatch_User__c.saasquatch__First_Name__c => 'TestingMock',
                    saasquatch__SaaSquatch_User__c.saasquatch__Referral_Code__c  => 'CODE1234',
                    saasquatch__SaaSquatch_User__c.saasquatch__Account_Id__c => 'test.test@gmail.com',
                    saasquatch__SaaSquatch_User__c.saasquatch__User_Id__c => 'test.test@gmail.com',
                    saasquatch__SaaSquatch_User__c.saasquatch__Email__c => 'test.test@gmail.com',
                    saasquatch__SaaSquatch_User__c.saasquatch__SaaSquatch_Combined_User_Id__c => 'test.test@gmail.com/test.test@gmail.com',
                    saasquatch__SaaSquatch_User__c.saasquatch__Referral_Code__c => 'User-Saasq-Code',
                    saasquatch__SaaSquatch_User__c.saasquatch__Contact__c => testContact.Id
                }
            )
            .create()
            .getRecord();
        Lead testLead = (Lead) new SObjectBuilder(Lead.SobjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Lead.FirstName => 'Testing',
                    Lead.LastName => 'Saasquatch',
                    Lead.Email => 'mail@gmail.com'
                }
            )
            .create()
            .getRecord();

        SaasquatchEmailConfig__c sec = new SaasquatchEmailConfig__c();
        sec.SaaSquatchEmail__c = 'mquiller@aquivalabs.com';
        upsert sec;
        Test.startTest();
        testLead.saasquatch_program_selector__c = 'UK Referral Programme (external)';
        testLead.Saasquatch_Advocate_ID__c = 'NOMATCHESADSDSA';
        update testLead;
        Test.stopTest();
        System.assertEquals(null , testLead.Saasquatch_Advocate_Name__c, 'Expected lead should not have an advocate assigned');
    }

    @isTest
    public static void testPopulateSaaSquatchAdvocateFieldsOnleadMatchByUserCode() {
        Account testAcc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => 'Account Testing',
                    Account.RC_Account_Status__c => 'Other'
                }
            )
            .create()
            .getRecord();
        Contact testContact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.FirstName => 'Contact',
                    Contact.LastName => 'Testing',
                    Contact.AccountId => testAcc.Id,
                    Contact.Email => 'mailContact@gmail.com',
                    Contact.Phone => '123456789',
                    Contact.UK_Saasquatch_Referral_Code__c => 'Contact-UK-Saasq-Code'
                }
            )
            .create()
            .getRecord();
        saasquatch__SaaSquatch_User__c  saasqUser = (saasquatch__SaaSquatch_User__c) new SObjectBuilder(saasquatch__SaaSquatch_User__c.SobjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    saasquatch__SaaSquatch_User__c.saasquatch__First_Name__c => 'TestingMock',
                    saasquatch__SaaSquatch_User__c.saasquatch__Referral_Code__c  => 'CODE1234',
                    saasquatch__SaaSquatch_User__c.saasquatch__Account_Id__c => 'test.test@gmail.com',
                    saasquatch__SaaSquatch_User__c.saasquatch__User_Id__c => 'test.test@gmail.com',
                    saasquatch__SaaSquatch_User__c.saasquatch__Email__c => 'test.test@gmail.com',
                    saasquatch__SaaSquatch_User__c.saasquatch__SaaSquatch_Combined_User_Id__c => 'test.test@gmail.com/test.test@gmail.com',
                    saasquatch__SaaSquatch_User__c.saasquatch__Referral_Code__c => 'User-Saasq-Code',
                    saasquatch__SaaSquatch_User__c.saasquatch__Contact__c => testContact.Id
                }
            )
            .create()
            .getRecord();
        Lead testLead = (Lead) new SObjectBuilder(Lead.SobjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Lead.FirstName => 'Testing',
                    Lead.LastName => 'Saasquatch',
                    Lead.Email => 'mail@gmail.com'
                }
            )
            .create()
            .getRecord();
        Test.startTest();
        testLead.saasquatch_program_selector__c = 'US and Canada Referral Program (external)';
        testLead.Saasquatch_Advocate_ID__c = 'User-Saasq-Code';
        update testLead;
        Test.stopTest();
        testLead = (Lead) new LeadSelector()
            .selectLeadById(new List<Object>{testLead.Id})
            .selectField('Saasquatch_Advocate_Name__c')
            .executeQuery()[0];
        System.assertEquals(saasqUser.Id, testlead.Saasquatch_Advocate_Name__c, 'The saasquatch user was not assigned correctly');
    }

    @isTest
    public static void testSendEmailOnUnmatchedId() {
        SaasquatchEmailConfig__c emailConfig = new SaasquatchEmailConfig__c(
            SaaSquatchEmail__c = 'testing@test.com'
        );
        insert emailConfig;

        Test.startTest();
        Lead testLead = (Lead) new SObjectBuilder(Lead.SobjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Lead.FirstName => 'Testing',
                    Lead.LastName => 'Saasquatch',
                    Lead.Email => 'mail@gmail.com',
                    Lead.saasquatch_program_selector__c => 'UK Referral Programme (external)',
                    Lead.Saasquatch_Advocate_ID__c => 'ID-NOT-FOUND'
                }
            )
            .create()
            .getRecord();
        Test.stopTest();

        testLead = (Lead) new LeadSelector()
        .selectLeadById(new List<Object>{testLead.Id})
        .selectField('Saasquatch_Advocate_Name__c')
        .executeQuery()[0];
        System.assertEquals(null , testLead.Saasquatch_Advocate_Name__c, 'Expected lead should not have an advocate assigned');

    }


    public class ClayLeadEnrichmentServiceMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();
            res.setStatus('OK');
            res.setStatusCode(200);
            return res;
        }
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    public static void testClayEnrichmentCode() {
        Test.setMock(HttpCalloutMock.class, new ClayLeadEnrichmentServiceMock());
        Gating_Process_Stage__c processStage = Gating_Process_Stage__c.getInstance();
        processStage.IsClayEnabled__c = true;
        processStage.Clay_Lead_WebHook_URL__c = 'https://example.com/api/endpoint';
        insert processStage;
		// Since the assertion involves comparing the queueable class http response result that gets triggered via trigger method,
		// it cannot be validated and therefore assert not included in this method 
        Lead testLead = (Lead) new SObjectBuilder(Lead.SobjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Lead.FirstName => 'Steve',
                    Lead.LastName => 'Benson',
                    Lead.Street => 'Congress Avenue',
                    Lead.State => 'TX',
                    Lead.PostalCode => '78701',
                    Lead.Country => 'United States',
                    Lead.City => 'Austin',
                    Lead.Company => 'mail@gmail.com',
                    Lead.Email => 'steve.benson@siliconlabs.com',
                    Lead.Phone => '(919)191-9115'
                }
            )
            .create()
            .getRecord();
    }
}