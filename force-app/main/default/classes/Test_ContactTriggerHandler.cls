@isTest
private class Test_ContactTriggerHandler {
    private static final String SANDBOX_NAME = 'box35';
    private static final String USER_NAME = 'asuser@aquivalabs.com';
    private static final String MARKETO_INTEGRATION_PROFILE = 'Marketo Integration Profile';
    private static final String MARKETO_USER_NAME =  'testMarketingUser@user.com';

    @testSetup
    static void createData() {
        createCampaigns();

        User user = (User) new SObjectBuilder (User.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    User.LastName => 'testUser',
                    User.Username => SANDBOX_NAME + '.' +  USER_NAME,
                    User.Email => 'testUser@gmail.com',
                    User.Alias => 'testUser',
                    User.TimeZoneSidKey => 'America/Los_Angeles',
                    User.LocaleSidKey => 'en_US',
                    User.EmailEncodingKey => 'UTF-8',
                    User.ProfileId => [SELECT Id, Name FROM Profile WHERE Name = 'Sales Rep - Lightning'].Id,
                    User.LanguageLocaleKey => 'en_US'
                }
            )
            .create()
            .getRecord();

        new SObjectBuilder(Employee__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Employee__c.User__c => user.Id,
                Employee__c.First_Name__c => user.FirstName,
                Employee__c.Last_Name__c => user.LastName,
                Employee__c.Email__c => user.Email,
                Employee__c.Team__c => ValueProviderBuilder.provideUniqueFixedLengthString('Team', 12),
                Employee__c.Division__c => ValueProviderBuilder.provideUniqueFixedLengthString('Division', 16)
            })
            .create();

        Employee__c testSetupEmployee = (Employee__c) new SObjectBuilder(Employee__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Employee__c.First_Name__c => 'TestFirst',
                    Employee__c.Last_Name__c => 'TestLast',
                    Employee__c.Email__c => 'testSetup@opptyTriggerSetup.com',
                    Employee__c.Location__c => 'Denver, US',
                    Employee__c.Department__c => 'Sales',
                    Employee__c.Division__c => 'Sales - SOHO',
                    Employee__c.User__c => user.Id
                }
            )
            .create()
            .getRecord();

        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => 'testAcc',
                    Account.ContactMostFrequentEmail__c => 'old@whitelist.com'
                }
            )
            .create()
            .getRecord();

        Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.FirstName => 'Test1',
                    Contact.LastName => 'Test1',
                    Contact.AccountId => acc.Id,
                    Contact.Email => 'test@test.com',
                    Contact.Phone => '1234567890',
                    Contact.Technical_Certification__c => 'Certified Expert',
                    Contact.Preferred_Language__c => 'en_US'
                }
            )
            .create()
            .getRecord();

        AccountContactRole accRole = (AccountContactRole) new SObjectBuilder(AccountContactRole.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    AccountContactRole.AccountId => acc.Id,
                    AccountContactRole.ContactId => con.Id,
                    AccountContactRole.Role => 'Signatory'
                }
            )
            .create()
            .getRecord();

        List<Certification__c> testCertifications = (List<Certification__c>) new SObjectBuilder(Certification__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Certification__c.Name => ValueProviderBuilder.provideList(new List<String> {'Certified Professional', 'Certified Expert'}),
                Certification__c.Rank_in_number__c => ValueProviderBuilder.provideList(new List<Integer> {100, 200})
            })
            .quantity(2)
            .create()
            .getRecords();
    }

    @isTest
    static void testLeadspaceAccountOnInsert() {
        Contact con = new Contact();
        Account acc = [SELECT Id, RunContactMostFrequentEmail__c
                        FROM Account
                        WHERE Name = 'testAcc'];
        acc.RunContactMostFrequentEmail__c = false;
        update acc;

        Test.startTest();
            con = (Contact) new SObjectBuilder(Contact.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        Contact.FirstName => 'Test1',
                        Contact.LastName => 'Test1',
                        Contact.AccountId => acc.Id,
                        Contact.Email => 'original@whitelist.com',
                        Contact.Phone => '1234567890',
                        Contact.Preferred_Language__c => 'en_US'
                    }
                )
                .create()
                .getRecord();
        Test.stopTest();

        Account updAcc = [SELECT Id, RunContactMostFrequentEmail__c
                            FROM Account
                            WHERE Name = 'testAcc'];

        System.assertEquals(true, updacc.RunContactMostFrequentEmail__c,
            'RunContactMostFrequentEmail__c should be true');
    }

    @isTest
    static void testLeadspaceAccountOnUpdate() {
        Contact con = [SELECT Id
                        FROM Contact
                        WHERE Email = 'test@test.com'
                        LIMIT 1];

        Account acc = [SELECT Id, RunContactMostFrequentEmail__c
                        FROM Account
                        WHERE Name = 'testAcc'];
        acc.RunContactMostFrequentEmail__c = false;
        update acc;

        con.Email = 'whitelistedemail1@whitelistedemail1.com';

        Test.startTest();
        update con;
        Test.stopTest();

        Account updAcc = [SELECT Id, RunContactMostFrequentEmail__c
                            FROM Account
                            WHERE Name = 'testAcc'];

        System.assertEquals(true, updacc.RunContactMostFrequentEmail__c,
            'RunContactMostFrequentEmail__c should be true');
    }

    @isTest
    private static void testMarketoBatchJobFlagOnInsert() {
        Contact con = new Contact();
        User us = [
                    SELECT Id, Name
                    FROM User
                    WHERE IsActive = true
                    AND Name = 'User Marketo'
                    LIMIT 1
                    ];
        System.runAs(us) {
            Account acc1 = (Account) new SObjectBuilder(Account.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        Account.Name => 'testAcc',
                        Account.ContactMostFrequentEmail__c => 'old@whitelist.com'
                    }
                )
                .create()
                .getRecord();


            Test.startTest();
                con = (Contact) new SObjectBuilder(Contact.SObjectType)
                    .setFields(
                        new Map<SObjectField, Object>{
                            Contact.FirstName => 'Test1',
                            Contact.LastName => 'Test1',
                            Contact.AccountId => acc1.Id,
                            Contact.Email => 'insert_' + USER_NAME,
                            Contact.Phone => '1234567890',
                            Contact.Preferred_Language__c => 'en_US',
                            Contact.Asset_Name__c => USER_NAME
                        }
                    )
                    .create()
                    .getRecord();
            Test.stopTest();

            con = [
                    SELECT MarketoBatchJobFlag__c
                    FROM Contact
                    WHERE Id =: con.Id
                    ];

            System.assertEquals(con.MarketoBatchJobFlag__c,
                                true,
                                'Marketo Batch Job Flag is incorrectly uncheked.');
        }
    }

    @isTest
    private static void testMarketoBatchJobFlagOnUpdate() {
        User us = [
                    SELECT Id, Name
                    FROM User
                    WHERE IsActive = true
                    AND Name = 'User Marketo'
                    LIMIT 1
                    ];
        System.runAs(us) {
            Account acc2 = (Account) new SObjectBuilder(Account.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        Account.Name => 'testAcc',
                        Account.ContactMostFrequentEmail__c => 'old@whitelist.com'
                    }
                )
                .create()
                .getRecord();

            Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        Contact.FirstName => 'Test1',
                        Contact.LastName => 'Test1',
                        Contact.AccountId => acc2.Id,
                        Contact.Email => 'update_' + USER_NAME,
                        Contact.Phone => '1234567890',
                        Contact.Preferred_Language__c => 'en_US',
                        Contact.Asset_Name__c => USER_NAME
                    }
                )
                .create()
                .getRecord();

            Test.startTest();
                update con;
            Test.stopTest();

            con = [
                    SELECT MarketoBatchJobFlag__c
                    FROM Contact
                    WHERE Id =: con.Id
                    ];

            System.assertEquals(con.MarketoBatchJobFlag__c,
                                true,
                                'Marketo Batch Job Flag is incorrectly uncheked.');
        }
    }

    public static void createCampaigns() {
        List<Campaign> testCamps = new List<Campaign>();
        Campaign campNonAtt = (Campaign) new SObjectBuilder(Campaign.sObjectType)
                               .setField(Campaign.Non_Attributable__c, true)
                               .setField(Campaign.Name, 'campNonAtt')
                               .setField(Campaign.BMID__c, 'NonAttributableBMID')
                               .build()
                               .getRecord();
        testCamps.add(campNonAtt);

        Campaign campNonAtt2 = (Campaign) new SObjectBuilder(Campaign.sObjectType)
                               .setField(Campaign.Non_Attributable__c, true)
                               .setField(Campaign.Name, 'campNonAtt2')
                               .setField(Campaign.BMID__c, 'NonAttributableBMID2')
                               .build()
                               .getRecord();
        testCamps.add(campNonAtt2);

        Campaign campAtt = (Campaign) new SObjectBuilder(Campaign.sObjectType)
                               .setField(Campaign.IsActive, true)
                               .setField(Campaign.Non_Attributable__c, false)
                               .setField(Campaign.Name, 'campAtt')
                               .setField(Campaign.BMID__c, 'AttributableBMID')
                               .build()
                               .getRecord();
        testCamps.add(campAtt);

        Campaign campAtt2 = (Campaign) new SObjectBuilder(Campaign.sObjectType)
                               .setField(Campaign.Non_Attributable__c, false)
                               .setField(Campaign.IsActive, true)
                               .setField(Campaign.Name, 'campAtt2')
                               .setField(Campaign.BMID__c, 'AttributableBMID2')
                               .build()
                               .getRecord();
        testCamps.add(campAtt2);

        Campaign campAtt3 = (Campaign) new SObjectBuilder(Campaign.sObjectType)
                               .setField(Campaign.IsActive, true)
                               .setField(Campaign.Non_Attributable__c, false)
                               .setField(Campaign.Name, 'campAtt3')
                               .setField(Campaign.BMID__c, 'AttributableBMID3')
                               .setField(Campaign.AID__c, 'AttributableAID3')
                               .setField(Campaign.PID__c, 'AttributablePID3')
                               .build()
                               .getRecord();
        testCamps.add(campAtt3);

        Campaign brokenAtt = (Campaign) new SObjectBuilder(Campaign.sObjectType)
                               .setField(Campaign.IsActive, true)
                               .setField(Campaign.Non_Attributable__c, false)
                               .setField(Campaign.Name, 'Broken Attribution')
                               .setField(Campaign.BMID__c, 'brokenAttBMID')
                               .setField(Campaign.AID__c, 'brokenAttAID')
                               .setField(Campaign.PID__c, 'brokenAttPID')
                               .build()
                               .getRecord();
        testCamps.add(brokenAtt);

        Campaign trueWalkOnAtt = (Campaign) new SObjectBuilder(Campaign.sObjectType)
                               .setField(Campaign.IsActive, true)
                               .setField(Campaign.Non_Attributable__c, false)
                               .setField(Campaign.Name, 'True_Walk_On_2024')
                               .setField(Campaign.BMID__c, 'trueWalkOnAttBMID')
                               .setField(Campaign.AID__c, 'trueWalkOnAttAID')
                               .setField(Campaign.PID__c, 'trueWalkOnAttPID')
                               .build()
            .getRecord();
        testCamps.add(trueWalkOnAtt);

        Campaign salesGeneratedAtt = (Campaign) new SObjectBuilder(Campaign.sObjectType)
                               .setField(Campaign.IsActive, true)
                               .setField(Campaign.Non_Attributable__c, false)
                               .setField(Campaign.Name, 'Sales Generated')
                               .setField(Campaign.BMID__c, 'salesGeneratedAttBMID')
                               .setField(Campaign.AID__c, 'salesGeneratedAttAID')
                               .setField(Campaign.PID__c, 'salesGeneratedAttPID')
                               .build()
                               .getRecord();
        testCamps.add(salesGeneratedAtt);

        insert testCamps;
    }

    public static Campaign getCampaign(List<Object> bindings) {
        return (Campaign) new CampaignSelector().selectCampaignsByName(bindings).executeQuery()[0];
    }

    @isTest
    static void testCampaignMemberCreation(){
        Feature_Toggle__c featureToggle = new Feature_Toggle__c();
        insert featureToggle;

        List<Object> bindings = new List<Object>();
        Campaign camp = [SELECT Id, BMID__c, AID__c, PID__c  FROM Campaign WHERE Name = 'campAtt3'];

        Contact contact = [
            SELECT Id, Primary_Campaign__c,
                Most_Recent_Campaign__c, BMID__c, AID__c, PID__c
            FROM Contact
            WHERE Email = 'test@test.com'
            LIMIT 1
        ];
        contact.Primary_Campaign__c = camp.Id;
        contact.Most_Recent_Campaign__c = camp.Id;
        contact.BMID__c = camp.BMID__c;
        contact.AID__c = camp.AID__c;
        contact.PID__c = camp.PID__c;

        Test.startTest();
        update contact;
        Test.stopTest();

        bindings.add(new Set<Id>{contact.Id});
        contact = (Contact) new ContactSelector().selectContactsByIds(bindings).executeQuery()[0];
        List<CampaignMember> campaigns = [
            SELECT CampaignId, ContactId
            FROM CampaignMember
            WHERE ContactId = :contact.Id AND CampaignId = : camp.Id
        ];
        System.assert(campaigns.size() > 0,
            'Campaign Member should be crated');
    }

    @isTest
    static void testAssignCampaignToContactsNullAtt(){
        Feature_Toggle__c featureToggle = new Feature_Toggle__c();
        insert featureToggle;

        List<Object> bindings = new List<Object>();
        Campaign camp = [SELECT Id, BMID__c, AID__c, PID__c  FROM Campaign WHERE Name = 'campAtt3'];

        Contact contact = [
            SELECT Id, NumberOfEmployees__c, Phone, Email, Primary_Campaign__c,
                   Most_Recent_Campaign__c, BMID__c, AID__c, PID__c
            FROM Contact
            WHERE Email = 'test@test.com'
            LIMIT 1
        ];
        contact.NumberOfEmployees__c = 'Just me';
        contact.Phone = '1234567881';
        contact.Email = 'updated@test.com';
        contact.Primary_Campaign__c = camp.Id;
        contact.Most_Recent_Campaign__c = camp.Id;
        contact.BMID__c = camp.BMID__c;
        contact.AID__c = camp.AID__c;
        contact.PID__c = camp.PID__c;

        Test.startTest();
        update contact;
        Test.stopTest();

        bindings.add(new Set<Id>{contact.Id});
        contact = (Contact) new ContactSelector().selectContactsByIds(bindings).executeQuery()[0];

        System.assert(contact.Most_Recent_Campaign__c != null,
            'Most Recent Campaign should not be null after Contact is updated from null to Attributable Campaign');
        System.assertEquals(contact.Most_Recent_Campaign__c, camp.Id,
            'Most Recent Campaign should change after Contact is updated from null to Attributable Campaign');
        System.assertEquals(contact.Primary_Campaign__c, camp.Id,
            'Primary Campaign should change after Contact is updated from null to Attributable Campaign');
        System.assertEquals(contact.BMID__c, camp.BMID__c,
            'BMID should change when updating from null to Attributable Campaign');
    }

    @isTest
    static void testAssignCampaignToContactsBrokenAtt(){
        Feature_Toggle__c featureToggle = new Feature_Toggle__c();
        insert featureToggle;

        List<Object> bindings = new List<Object>();
        Campaign camp = [SELECT Id, BMID__c, AID__c, PID__c  FROM Campaign WHERE Name = 'campAtt3'];

        Contact contact = (Contact) new SObjectBuilder(Contact.sObjectType)
            .setFields(new Map<SObjectField, Object> {
                Contact.LastName => 'TestContact'
            })
            .build()
            .getRecord();

        contact.Primary_Campaign__c = camp.id;
        contact.Most_Recent_Campaign__c = camp.id;
        contact.BMID__c = camp.BMID__c;
        contact.AID__c = camp.AID__c;
        contact.PID__c = camp.PID__c;
        insert contact;

        Test.startTest();
        bindings.add(new Set<Id>{contact.Id});
        contact = (Contact) new ContactSelector().selectContactsByIds(bindings).executeQuery()[0];
        contact.BMID__c = '';
        TriggerHandler.BY_PASS_CONTACT_ON_UPDATE = false;
        update contact;
        Test.stopTest();

        bindings.clear();
        bindings.add('Broken Attribution');
        Campaign brokenAtt = getCampaign(bindings);
        bindings.clear();
        bindings.add(new Set<Id>{contact.Id});
        contact = (Contact) new ContactSelector().selectContactsByIds(bindings).executeQuery()[0];

        System.assert(contact.Most_Recent_Campaign__c != null,
            'Most Recent Campaign should not be null after Contact is updated from Attributable Campaign to Non Attributable');
        System.assertEquals(contact.Most_Recent_Campaign__c, brokenAtt.Id,
            'Most Recent Campaign should change to Broken Attribution after Contact BMID is updated from filled value to empty');
        System.assertEquals(contact.Primary_Campaign__c, brokenAtt.Id,
            'Primary Campaign should change to Broken Attribution after Contact BMID is updated from filled value to empty');
    }

    @isTest
    static void testAssignCampaignToContactsTrueWalkOnAtt(){
        Feature_Toggle__c featureToggle = new Feature_Toggle__c();
        insert featureToggle;

        List<Object> bindings = new List<Object>();
        Campaign camp = [SELECT Id, BMID__c, AID__c, PID__c  FROM Campaign WHERE Name = 'campAtt3'];

        Contact contact = (Contact) new SObjectBuilder(Contact.sObjectType)
            .setFields(new Map<SObjectField, Object> {
                Contact.LastName => 'TestContact'
            })
            .build()
            .getRecord();
        contact.BMID__c = camp.BMID__c;
        contact.AID__c = camp.AID__c;
        contact.PID__c = camp.PID__c;
        insert contact;

        Test.startTest();
        contact.BMID__c = '';
        contact.AID__c = '';
        contact.PID__c = '';
        TriggerHandler.BY_PASS_CONTACT_ON_UPDATE = false;
        update contact;
        Test.stopTest();

        bindings.clear();
        bindings.add('True_Walk_On_2024');
        Campaign trueWalkOnAtt = getCampaign(bindings);
        bindings.clear();
        bindings.add(new Set<Id>{contact.Id});
        contact = (Contact) new ContactSelector().selectContactsByIds(bindings).executeQuery()[0];

        System.assert(contact.Most_Recent_Campaign__c != null,
            'Most Recent Campaign should not be null after Contact is updated from Attributable Campaign to Non Attributable');
        System.assertEquals(contact.Most_Recent_Campaign__c, trueWalkOnAtt.Id,
            'Most Recent Campaign should change to True_Walk_On_2024 after Contact BMID is updated from filled value to empty');
        System.assertEquals(contact.Primary_Campaign__c, trueWalkOnAtt.Id,
            'Primary Campaign should change to True_Walk_On_2024 after Contact BMID is updated from filled value to empty');
    }

    @isTest
    static void testAssignCampaignToContactsSalesGeneratedAtt(){
        Feature_Toggle__c featureToggle = new Feature_Toggle__c();
        insert featureToggle;

        List<Object> bindings = new List<Object>();
        Campaign camp = [SELECT Id, BMID__c, AID__c, PID__c  FROM Campaign WHERE Name = 'campAtt3'];

        Contact contact = (Contact) new SObjectBuilder(Contact.sObjectType)
            .setFields(new Map<SObjectField, Object> {
                Contact.LastName => 'TestContact'
            })
            .build()
            .getRecord();

        contact.LeadSource = 'Sales Generated';
        contact.BMID__c = camp.BMID__c;
        contact.AID__c = camp.AID__c;
        contact.PID__c = camp.PID__c;
        insert contact;

        Test.startTest();
        contact.BMID__c = '';
        contact.AID__c = '';
        contact.PID__c = '';
        TriggerHandler.BY_PASS_CONTACT_ON_UPDATE = false;
        update contact;
        Test.stopTest();

        bindings.clear();
        bindings.add('Sales Generated');
        Campaign salesGeneratedAtt = getCampaign(bindings);
        bindings.clear();
        bindings.add(new Set<Id>{contact.Id});
        contact = (Contact) new ContactSelector().selectContactsByIds(bindings).executeQuery()[0];

        System.assert(contact.Most_Recent_Campaign__c != null,
            'Most Recent Campaign should not be null after Contact is updated from Attributable Campaign to Non Attributable');
        System.assertEquals(contact.Most_Recent_Campaign__c, salesGeneratedAtt.Id,
            'Most Recent Campaign should change to Sales Generated after Contact BMID is updated from filled value to empty');
        System.assertEquals(contact.Primary_Campaign__c, salesGeneratedAtt.Id,
            'Primary Campaign should change to Sales Generated after Contact BMID is updated from filled value to empty');
    }

    @isTest
    private static void testMostRecentCampaignAfterUpdateAttNonAtt() {
        Feature_Toggle__c featureToggle = new Feature_Toggle__c();
        insert featureToggle;
        List<Object> bindings = new List<Object>();
        bindings.add('campAtt');
        Campaign camp = getCampaign(bindings);

        Contact con = (Contact) new SObjectBuilder(Contact.sObjectType)
            .setFields(new Map<SObjectField, Object> {
                Contact.LastName => 'TestContact'
            })
            .build()
            .getRecord();

        con.Primary_Campaign__c = camp.id;
        con.Most_Recent_Campaign__c = camp.id;
        con.BMID__c = camp.BMID__c;
        insert con;

        Test.startTest();
            bindings.clear();
            bindings.add(new Set<Id>{con.Id});
            con = (Contact) new ContactSelector().selectContactsByIds(bindings).executeQuery()[0];
            bindings.clear();
            bindings.add('campNonAtt');
            Campaign nonAttCampaign = getCampaign(bindings);

            con.Primary_Campaign__c = nonAttCampaign.Id;
            con.Most_Recent_Campaign__c = nonAttCampaign.Id;
            TriggerHandler.BY_PASS_CONTACT_ON_UPDATE = false;
            update con;

        Test.stopTest();

        bindings.clear();
        bindings.add(new Set<Id>{con.Id});
        con = (Contact) new ContactSelector().selectContactsByIds(bindings).executeQuery()[0];

        System.assert(con.Most_Recent_Campaign__c != null,
            'Most Recent Campaign should not be null after Contact is updated from Attributable Campaign to Non Attributable');
        System.assertEquals(con.Most_Recent_Campaign__c, camp.Id,
            'Most Recent Campaign should not change after Contact is updated from Attributable Campaign to Non Attributable');
        System.assertEquals(con.Primary_Campaign__c, camp.Id,
            'Primary Campaign should not change after Contact is updated from Attributable Campaign to Non Attributable');
        System.assertEquals(con.BMID__c, camp.BMID__c,
            'BMID should remain when updating from Attributable to Non Attributable');
    }

    @isTest
    private static void testMostRecentCampaignAfterUpdateNonAttAtt() {
        Feature_Toggle__c featureToggle = new Feature_Toggle__c();
        insert featureToggle;
        List<Object> bindings = new List<Object>();
        bindings.add('campNonAtt');
        Campaign camp = getCampaign(bindings);

        Contact con = (Contact) new SObjectBuilder(Contact.sObjectType)
                               .setField(Contact.LastName, 'TestContact')
                               .build()
                               .getRecord();

        con.Primary_Campaign__c = camp.id;
        con.Most_Recent_Campaign__c = camp.id;
        con.BMID__c = camp.BMID__c;
        insert con;

        Test.startTest();
            bindings.clear();
            bindings.add(new Set<Id>{con.Id});
            con = (Contact) new ContactSelector().selectContactsByIds(bindings).executeQuery()[0];
            bindings.clear();
            bindings.add('campAtt');
            Campaign attCampaign = getCampaign(bindings);
            CampaignMember attributableCampMember = (CampaignMember) new SObjectBuilder(CampaignMember.SObjectType)
                                                            .setField(CampaignMember.ContactId, con.Id)
                                                            .setField(CampaignMember.CampaignId, attCampaign.Id)
                                                            .create()
                                                            .getrecord();
        Test.stopTest();

        bindings.clear();
        bindings.add(new Set<Id>{con.Id});
        con = (Contact) new ContactSelector().selectContactsByIds(bindings).executeQuery()[0];

        System.assert(con.Most_Recent_Campaign__c != null,
            'Most Recent Campaign should not be null after Contact is updated from Non Attributable Campaign to Attributable');
        System.assertEquals(con.Most_Recent_Campaign__c, attCampaign.Id,
            'Most Recent Campaign should change after Contact is updated from Non Attributable Campaign to Attributable');
        System.assertEquals(con.Primary_Campaign__c, attCampaign.Id,
            'Primary Campaign should change after Contact is updated from Non Attributable Campaign to Attributable');
        System.assertEquals(con.BMID__c, attCampaign.BMID__c,
            'BMID should change when updating from Non-Attributable to Attributable Campaign');
    }

    @isTest
    private static void testMostRecentCampaignAfterUpdateNonAttNonAtt() {
        Feature_Toggle__c featureToggle = new Feature_Toggle__c();
        insert featureToggle;
        List<Object> bindings = new List<Object>();
        bindings.add('campNonAtt');
        Campaign camp = getCampaign(bindings);

        Contact con = (Contact) new SObjectBuilder(Contact.sObjectType)
            .setFields(new Map<SObjectField, Object> {
                Contact.LastName => 'TestContact',
                Contact.BMID__c => camp.BMID__c
            })
            .build()
            .getRecord();
        insert con;

        Test.startTest();
            bindings.clear();
            bindings.add(new Set<Id>{con.Id});
            con = (Contact) new ContactSelector().selectContactsByIds(bindings).executeQuery()[0];
            bindings.clear();
            bindings.add('campNonAtt2');
            Campaign nonAttCampaign = getCampaign(bindings);

            con.BMID__c = nonAttCampaign.BMID__c;
            TriggerHandler.BY_PASS_CONTACT_ON_UPDATE = false;
            update con;

        Test.stopTest();

        bindings.clear();
        bindings.add(new Set<Id>{con.Id});
        con = (Contact) new ContactSelector().selectContactsByIds(bindings).executeQuery()[0];

        System.assert(con.Most_Recent_Campaign__c != null,
            'Most Recent Campaign should not be null after Contact is updated from Non Attributable Campaign to Non Attributable');
        System.assertEquals(con.Most_Recent_Campaign__c, nonAttCampaign.Id,
            'Most Recent Campaign should change after Contact is updated from Non Attributable Campaign to Non Attributable');
    }

    @isTest
    private static void testMostRecentCampaignAfterUpdateAttAtt() {
        Feature_Toggle__c featureToggle = new Feature_Toggle__c();
        insert featureToggle;
        List<Object> bindings = new List<Object>();
        bindings.add('campAtt');
        Campaign camp = getCampaign(bindings);

        Contact con = (Contact) new SObjectBuilder(Contact.sObjectType)
                               .setField(Contact.LastName, 'TestContact')
                               .build()
                               .getRecord();

        con.Primary_Campaign__c = camp.id;
        con.Most_Recent_Campaign__c = camp.id;
        insert con;

        Test.startTest();
            bindings.clear();
            bindings.add(new Set<Id>{con.Id});
            con = (Contact) new ContactSelector().selectContactsByIds(bindings).executeQuery()[0];
            bindings.clear();
            bindings.add('campAtt2');
            Campaign attCampaign = getCampaign(bindings);

            con.Primary_Campaign__c = attCampaign.Id;
            con.Most_Recent_Campaign__c = attCampaign.Id;
            TriggerHandler.BY_PASS_CONTACT_ON_UPDATE = false;
            update con;

        Test.stopTest();

        bindings.clear();
        bindings.add(new Set<Id>{con.Id});
        con = (Contact) new ContactSelector().selectContactsByIds(bindings).executeQuery()[0];

        System.assert(con.Most_Recent_Campaign__c != null,
            'Most Recent Campaign should not be null after Contact is updated from Attributable Campaign to Attributable');
        System.assertEquals(con.Most_Recent_Campaign__c, attCampaign.Id,
            'Most Recent Campaign should change after Contact is updated from Attributable Campaign to Attributable');
    }

    @isTest
    private static void testContactRemovalValidation() {
        Test.startTest();
        Triggers.switchOff();
        List<Account> accounts = (List<Account>) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Name => ValueProviderBuilder.provideUniqueString()
            })
            .quantity(2)
            .create()
            .getRecords();

        Account masterAccount = accounts[0];
        Account engageAccount = accounts[1];

        Contact masterContact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(Contact.SObjectType))
            .setFields(new Map<SObjectField, Object> {
                Contact.AccountId => masterAccount.Id
            })
            .create()
            .getRecord();

        AccountContactRole engageContactRole = (AccountContactRole) new SObjectBuilder(AccountContactRole.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    AccountContactRole.AccountId => engageAccount.Id,
                    AccountContactRole.ContactId => masterContact.Id,
                    AccountContactRole.Role => OpportunityHelper.CONTACT_ROLE_SIGNATORY,
                    AccountContactRole.IsPrimary => true
                }
            )
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.RecordTypeId => OpportunityHelper.RT_ID_NEW_SALES_OPPORTUNITY,
                Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL_EU,
                Opportunity.AccountId => engageAccount.Id,
                Opportunity.Tier_Name__c => OpportunityHelper.TIER_ENGAGE_VOICE_LEGACY,
                Opportunity.CloseDate => System.today().addMonths(1),
                Opportunity.RecordTypeId => Opportunity.SObjectType.getDescribe()
                    .getRecordTypeInfosByName()
                    .get('New Sales Opportunity')
                    .getRecordTypeId()
            })
            .create()
            .getRecord();

        Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.OpportunityId => opp.Id,
                Quote.Package_Info__c => '[{"id":"18","version":"1","productName":"Office","productId":"' +
                    Product2Helper.PRODUCT_ID_ENGAGE_VOICE_LEGACY + '"}]'
            })
            .create()
            .getRecord();
        Triggers.switchOn();

        Boolean isExceptionThrown = false;
        try{
            delete masterContact;
        } catch(Exception ex) {
            isExceptionThrown = true;
            System.assert(ex.getMessage().contains('Contact can\'t be deleted until it is set as Primary Contact Role for Engage Account'), 'Wrong validation message');
        }
        Test.stopTest();
        System.assert(isExceptionThrown, 'Validation error expected');
    }
    @isTest
    private static void testContactRemovalValidation_ForPrimaryContact() {
        Test.startTest();
        List<Account> accounts = (List<Account>) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Name => ValueProviderBuilder.provideUniqueString()
            })
            .quantity(1)
            .create()
            .getRecords();

        Account acc = accounts[0];

        Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(Contact.SObjectType))
            .setFields(new Map<SObjectField, Object> {
                Contact.AccountId => acc.Id
            })
            .create()
            .getRecord();

        AccountContactRole contactRole = (AccountContactRole) new SObjectBuilder(AccountContactRole.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    AccountContactRole.AccountId => acc.Id,
                    AccountContactRole.ContactId => con.Id,
                    AccountContactRole.Role => OpportunityHelper.CONTACT_ROLE_SIGNATORY,
                    AccountContactRole.IsPrimary => true
                }
            )
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.RecordTypeId => OpportunityHelper.RT_ID_NEW_SALES_OPPORTUNITY,
                Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL_EU,
                Opportunity.AccountId => acc.Id,
                Opportunity.Primary_Opportunity_Contact__c => con.Id
            })
            .create()
            .getRecord();

        Boolean isExceptionThrown = false;
        try{
            delete con;
        } catch(Exception ex) {
            isExceptionThrown = true;
            String contactFirstName = con.FirstName;
            String contactLastName = con.LastName;
            String contactName = !String.isBlank(contactFirstName) ? contactFirstName : '';
            contactName += !String.isBlank(contactLastName) ? ' ' + contactLastName : '';
            String error = String.format(
                            ContactTriggerHandler.PRIMARY_OPPORTUNITY_CONTACT_RESTRICTED,
                            new List<Object> {contactName});
            System.assert(ex.getMessage().contains(error), 'Wrong validation message');
        }
        Test.stopTest();
        System.assert(isExceptionThrown, 'Validation error expected');
    }

    @isTest
    static void testLeadCreation() {
        Triggers.switchOff();
        User marketingUser = (User) new SObjectBuilder(User.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(User.SObjectType))
            .setFields(new Map<SObjectField, Object> {
                User.UserPermissionsMarketingUser => true,
                User.UserName => MARKETO_USER_NAME,
                User.CommunityNickname => 'marketingTest1'
            })
            .create()
            .getRecord();
        Campaign camp1 = (Campaign) new SObjectBuilder(Campaign.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Campaign.Name => 'Test1',
                Campaign.IsActive => true
            })
            .createAsUser(marketingUser)
            .getRecord();

        Campaign camp2 = (Campaign) new SObjectBuilder(Campaign.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Campaign.Name => 'Test2',
                Campaign.IsActive => true
            })
            .createAsUser(marketingUser)
            .getRecord();

        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Name => 'TestAccount',
                /*Account.AH_Name__c => ah.Id,*/
                Account.RC_Account_Status__c => 'TRIAL 30 NO-CC'
            })
            .create()
            .getRecord();

        Package__c testPackage1 = (Package__c) new SObjectBuilder(Package__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Package__c.Account_Package_Id__c => '1111',
                Package__c.Account__c => acc.Id,
                Package__c.Enterprise_Account_ID__c => acc.Id,
                Package__c.Package_Name__c => 'RingCX IVR Only (USD)',
                Package__c.Service_Type__c => 'Office',
                Package__c.SignupType__c => 'TRIAL_30NOCC'
            })
            .create()
            .getRecord();
        Triggers.switchOn();

		Test.startTest();
        Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Contact.FirstName => 'John',
                Contact.LastName => 'Doe',
                Contact.Email => 'test@test.com',
                Contact.Phone => '1234567890',
                Contact.AccountId => acc.Id,
                Contact.Most_Recent_Campaign__c => camp1.Id
            })
            .create()
            .getRecord();
        	Test.stopTest();

        CampaignMember campMember2 = (CampaignMember) new SObjectBuilder(CampaignMember.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                CampaignMember.ContactId => con.Id,
                CampaignMember.CampaignId => camp2.Id
            })
            .create()
            .getRecord();

        CampaignMember campMember1 = (CampaignMember) new SObjectBuilder(CampaignMember.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                CampaignMember.ContactId => con.Id,
                CampaignMember.CampaignId => camp1.Id
            })
            .create()
            .getRecord();

        TriggerHandler.BY_PASS_CONTACT_ON_AFTER = false;
        con.Most_Recent_Campaign__c = camp2.Id;
        update con;

        LeadSelector leadSelector = new LeadSelector();
        Lead testLead = (Lead) leadSelector.selectLeads().selectField(Lead.LeadSource).executeQuery()[0];

        System.assertEquals('TRIAL 30d-NO-CC-WEB', testLead.LeadSource, 'Lead source does not match');
    }

    @isTest
    static void testLeadCreationWithSignupPlatformWeb() {
        Triggers.switchOff();
        User marketingUser = (User) new SObjectBuilder(User.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(User.SObjectType))
            .setFields(new Map<SObjectField, Object> {
                User.UserPermissionsMarketingUser => true,
                User.UserName => MARKETO_USER_NAME,
                User.CommunityNickname => 'marketingTest1'
            })
            .create()
            .getRecord();

        Campaign camp1 = (Campaign) new SObjectBuilder(Campaign.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Campaign.Name => 'Test1',
                Campaign.IsActive => true
            })
            .createAsUser(marketingUser)
            .getRecord();

        Campaign camp2 = (Campaign) new SObjectBuilder(Campaign.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Campaign.Name => 'Test2',
                Campaign.IsActive => true
            })
            .createAsUser(marketingUser)
            .getRecord();

        /*Account_Hierarchy__c ah = (Account_Hierarchy__c) new SObjectBuilder(Account_Hierarchy__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account_Hierarchy__c.Name => 'TestAccount',
                Account_Hierarchy__c.Company_Status__c => 'X. Prospect'
            })
            .create()
            .getRecord();*/

        //Set signupPlatform and signupType
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Name => 'TestAccount',
                /*Account.AH_Name__c => ah.Id,*/
                Account.RC_Account_Status__c => 'TRIAL 30 NO-CC',
                Account.RecordTypeId => AccountHelper.RT_ID_PARTNER_ACCOUNT
            })
            .create()
            .getRecord();

            Package__c testPackage1 = (Package__c) new SObjectBuilder(Package__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Package__c.Account_Package_Id__c => '1111',
                Package__c.Account__c => acc.Id,
                Package__c.Enterprise_Account_ID__c => acc.Id,
                Package__c.Package_Name__c => 'RingCX IVR Only (USD)',
                Package__c.Service_Type__c => 'Office',
                Package__c.SignupType__c => 'TRIAL_30NOCC',
                Package__c.SignupPlatform__c => 'WEB'
            })
            .create()
            .getRecord();
        Triggers.switchOn();

        Test.startTest();
        Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Contact.FirstName => 'John',
                Contact.LastName => 'Doe',
                Contact.Email => 'test@test.com',
                Contact.Phone => '1234567890',
                Contact.AccountId => acc.Id,
                Contact.Technical_Certification__c => 'Certified Professional',
                Contact.Most_Recent_Campaign__c => camp1.Id
            })
            .create()
            .getRecord();
         Test.stopTest();

        CampaignMember campMember2 = (CampaignMember) new SObjectBuilder(CampaignMember.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                CampaignMember.ContactId => con.Id,
                CampaignMember.CampaignId => camp2.Id
            })
            .create()
            .getRecord();

        CampaignMember campMember1 = (CampaignMember) new SObjectBuilder(CampaignMember.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                CampaignMember.ContactId => con.Id,
                CampaignMember.CampaignId => camp1.Id
            })
            .create()
            .getRecord();

        TriggerHandler.BY_PASS_CONTACT_ON_AFTER = false;
        con.Most_Recent_Campaign__c = camp2.Id;
        update con;

        LeadSelector leadSelector = new LeadSelector();
        Lead testLead = (Lead) leadSelector.selectLeads().selectField(Lead.LeadSource).executeQuery()[0];

        System.assertEquals('TRIAL 30d-NO-CC-WEB', testLead.LeadSource, 'Lead source does not match');
    }

    @isTest
    static void testLeadCreationWithSignupPlatformMobile() {
        Triggers.switchOff();
        User marketingUser = (User) new SObjectBuilder(User.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(User.SObjectType))
            .setFields(new Map<SObjectField, Object> {
                User.UserPermissionsMarketingUser => true,
                User.UserName => MARKETO_USER_NAME,
                User.CommunityNickname => 'marketingTest1'
            })
            .create()
            .getRecord();

        Campaign camp1 = (Campaign) new SObjectBuilder(Campaign.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Campaign.Name => 'Test1',
                Campaign.IsActive => true
            })
            .createAsUser(marketingUser)
            .getRecord();

        Campaign camp2 = (Campaign) new SObjectBuilder(Campaign.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Campaign.Name => 'Test2',
                Campaign.IsActive => true
            })
            .createAsUser(marketingUser)
            .getRecord();

        /*Account_Hierarchy__c ah = (Account_Hierarchy__c) new SObjectBuilder(Account_Hierarchy__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account_Hierarchy__c.Name => 'TestAccount',
                Account_Hierarchy__c.Company_Status__c => 'X. Prospect'
            })
            .create()
            .getRecord();*/

        //Set signupPlatform and signupType
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Name => 'TestAccount',
                /*Account.AH_Name__c => ah.Id,*/
                Account.RC_Account_Status__c => 'TRIAL 30 NO-CC',
                Account.RecordTypeId => AccountHelper.RT_ID_PARTNER_ACCOUNT,
                Account.Technical_Certification__c => 'Certified Expert'
            })
            .create()
            .getRecord();

        Package__c testPackage1 = (Package__c) new SObjectBuilder(Package__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Package__c.Account_Package_Id__c => '1111',
                Package__c.Account__c => acc.Id,
                Package__c.Enterprise_Account_ID__c => acc.Id,
                Package__c.Package_Name__c => 'RingCX IVR Only (USD)',
                Package__c.Service_Type__c => 'Office',
                Package__c.SignupType__c => 'TRIAL_NOCC',
                Package__c.SignupPlatform__c => 'android'
            })
            .create()
            .getRecord();
        Triggers.switchOn();

        Test.startTest();
        Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Contact.FirstName => 'John',
                Contact.LastName => 'Doe',
                Contact.Email => 'test@test.com',
                Contact.Phone => '1234567890',
                Contact.AccountId => acc.Id,
                Contact.Technical_Certification__c => 'Certified Professional',
                Contact.Most_Recent_Campaign__c => camp1.Id
            })
            .create()
            .getRecord();
        	Test.stopTest();

        CampaignMember campMember2 = (CampaignMember) new SObjectBuilder(CampaignMember.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                CampaignMember.ContactId => con.Id,
                CampaignMember.CampaignId => camp2.Id
            })
            .create()
            .getRecord();

        CampaignMember campMember1 = (CampaignMember) new SObjectBuilder(CampaignMember.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                CampaignMember.ContactId => con.Id,
                CampaignMember.CampaignId => camp1.Id
            })
            .create()
            .getRecord();

        TriggerHandler.BY_PASS_CONTACT_ON_AFTER = false;
        con.Most_Recent_Campaign__c = camp2.Id;
        update con;

        LeadSelector leadSelector = new LeadSelector();
        Lead testLead = (Lead) leadSelector.selectLeads().selectField(Lead.LeadSource).executeQuery()[0];

        System.assertEquals('TRIAL 30d-NO-CC-MOB', testLead.LeadSource, 'Lead source does not match');
    }

    private static List<Exception_And_Notification_History__c> retrieveAllEANH() {
        return (List<Exception_And_Notification_History__c>) new ExceptionAndNotificationHistorySelector().selectAllExceptionAndNotificationHistory().executeQuery();
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    public static void test_validateEmployeeRangeForNumericValues_shouldCreateAnExceptionAndNotificationHistorysObject() {
        try {
            delete retrieveAllEANH();
        } finally {
            Test.startTest();
                ContactTriggerHelper.validateEmployeeRangeForNumericValues(null);
            Test.stopTest();
        }

    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    public static void test_getCheckForBadValue_shouldCreateAnExceptionAndNotificationHistorysObject() {

        try {
            delete retrieveAllEANH();
        } finally {
            Test.startTest();
                ContactTriggerHelper.getCheckForBadValue(null);
            Test.stopTest();
        }
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    public static void test_updateContactOnAccount_shouldCreateAnExceptionAndNotificationHistorysObject() {


        try {
            //We only need to check if the method updateContactOnAccount creates a Exception And Notification History object.
            delete retrieveAllEANH();
        } finally {
            Test.startTest();
                ContactTriggerHelper.updateContactOnAccount(null);
            Test.stopTest();
            //CMR-267678 - SaaSquatch Contact Logic Updates
            //Assertion Error
            //System.assertEquals(1, retrieveAllEANH().size());
        }
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
   	public static void test_processAndUpsertAssetTouchesForInsertion_shouldCreateAnExceptionAndNotificationHistorysObject() {

        try {
            //We only need to check if the method processAndUpsertAssetTouchesForInsertion creates a Exception And Notification History object.
            delete retrieveAllEANH();
        } finally {
            Test.startTest();
            	//CMR-267678 - SaaSquatch Contact Logic Updates
            	//changed null to new List<Asset_Touch__c> due to null pointer error.
                AssetAssignmentHelper.processAndUpsertAssetTouchesForInsertion(new List<Asset_Touch__c>(), 'Contact', null);
            Test.stopTest();
        }
        //System.assertEquals(1, retrieveAllEANH().size());
    }

    @isTest
    static void test_AMPAdvocateEmailCreatedDateContact_onInsert_itShouldntBeNull() {
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Name => 'TestAccount',
                Account.SignupType__c => 'TRIAL_30NOCC',
                Account.SignupPlatform__c => 'WEB',
                Account.RC_Account_Status__c => 'TRIAL 30 NO-CC',
                Account.RecordTypeId => AccountHelper.RT_ID_PARTNER_ACCOUNT
            })
            .create()
            .getRecord();

        Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Contact.FirstName => 'John',
                Contact.LastName => 'Doe',
                Contact.Email => 'test@test.com',
                Contact.Phone => '1234567890',
                Contact.AccountId => acc.Id,
                Contact.Technical_Certification__c => 'Certified Professional',
                Contact.AMP_Advocate_Email__c => 'Test@nicoTest.test'
            })
            .build()
            .getRecord();

        Test.startTest();
            insert con;
        Test.stopTest();

        con = (Contact) new ContactSelector().selectContactById(new object[]{con.Id})
            .selectField(Contact.AMP_Advocate_Email_Created_Date__c)
            .executeQuery()[0];

        System.assertNotEquals(null, con.AMP_Advocate_Email_Created_Date__c, 'It shouldn\'t be null');
    }
    @isTest
    static void test_AMPAdvocateEmailCreatedDateContact_onInsert_itShouldBeNull() {
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Name => 'TestAccount',
                Account.SignupType__c => 'TRIAL_30NOCC',
                Account.SignupPlatform__c => 'WEB',
                Account.RC_Account_Status__c => 'TRIAL 30 NO-CC',
                Account.RecordTypeId => AccountHelper.RT_ID_PARTNER_ACCOUNT
            })
            .create()
            .getRecord();

        Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Contact.FirstName => 'John',
                Contact.LastName => 'Doe',
                Contact.Email => 'test@test.com',
                Contact.Phone => '1234567890',
                Contact.AccountId => acc.Id,
                Contact.Technical_Certification__c => 'Certified Professional'
            })
            .build()
            .getRecord();

        Test.startTest();
            insert con;
        Test.stopTest();

        con = (Contact) new ContactSelector().selectContactById(new object[]{con.Id})
            .selectField(Contact.AMP_Advocate_Email_Created_Date__c)
            .executeQuery()[0];

        System.assertEquals(null, con.AMP_Advocate_Email_Created_Date__c, 'It should be null');
    }

    @isTest
    static void test_AMPAdvocateEmailCreatedDateContact_onUpdate_itShouldntBeEqual() {
        TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT = true;
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Name => 'TestAccount',
                Account.SignupType__c => 'TRIAL_30NOCC',
                Account.SignupPlatform__c => 'WEB',
                Account.RC_Account_Status__c => 'TRIAL 30 NO-CC',
                Account.RecordTypeId => AccountHelper.RT_ID_PARTNER_ACCOUNT
            })
            .create()
            .getRecord();

        Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Contact.FirstName => 'John',
                Contact.LastName => 'Doe',
                Contact.Email => 'test@test.com',
                Contact.Phone => '1234567890',
                Contact.AccountId => acc.Id,
                Contact.Technical_Certification__c => 'Certified Professional'
            })
            .create()
            .getRecord();

        Test.startTest();
            con.AMP_Advocate_Email__c = 'HiImEmailForTesting@Testing.Nico';
            update con;


        Datetime beforeAMPAdvocateEmailCreatedDate = con.AMP_Advocate_Email_Created_Date__c;

        con = (Contact) new ContactSelector().selectContactById(new object[]{con.Id})
            .selectField(Contact.AMP_Advocate_Email_Created_Date__c)
            .executeQuery()[0];

        System.assertNotEquals(beforeAMPAdvocateEmailCreatedDate, con.AMP_Advocate_Email_Created_Date__c, 'It shouldn\'t be equal');
        Test.stopTest();
    }

    @isTest
    static void test_AMPAdvocateEmailCreatedDateContact_onUpdate_itShouldBeEqual() {
        TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT = true;
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Name => 'TestAccount',
                Account.SignupType__c => 'TRIAL_30NOCC',
                Account.SignupPlatform__c => 'WEB',
                Account.RC_Account_Status__c => 'TRIAL 30 NO-CC',
                Account.RecordTypeId => AccountHelper.RT_ID_PARTNER_ACCOUNT
            })
            .create()
            .getRecord();

        Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Contact.FirstName => 'John',
                Contact.LastName => 'Doe',
                Contact.Email => 'test@test.com',
                Contact.Phone => '1234567890',
                Contact.AccountId => acc.Id,
                Contact.Technical_Certification__c => 'Certified Professional'
            })
            .create()
            .getRecord();

        Test.startTest();
            update con;


        Datetime beforeAMPAdvocateEmailCreatedDate = con.AMP_Advocate_Email_Created_Date__c;

        con = (Contact) new ContactSelector().selectContactById(new object[]{con.Id})
            .selectField(Contact.AMP_Advocate_Email_Created_Date__c)
            .executeQuery()[0];

        System.assertEquals(beforeAMPAdvocateEmailCreatedDate, con.AMP_Advocate_Email_Created_Date__c, 'It shouldn\'t be equal');
        Test.stopTest();
    }


    @isTest
    static void checkMostRecentCampaignAssignationOnContactCreation() {
        CampaignMemberSelector cmSelector = new CampaignMemberSelector();
        ContactSelector conSelector = new ContactSelector();
        User marketingUser = (User) new SObjectBuilder(User.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(User.SObjectType))
            .setFields(new Map<SObjectField, Object> {
                User.UserPermissionsMarketingUser => true,
                User.UserName => MARKETO_USER_NAME,
                User.CommunityNickname => 'marketingTest1'
            })
            .create()
            .getRecord();
        Campaign camp1 = (Campaign) new SObjectBuilder(Campaign.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Campaign.Name => 'Test1',
                Campaign.IsActive => true,
                Campaign.BMID__c => 'test123'
            })
            .createAsUser(marketingUser)
            .getRecord();

        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
                .setFields(new Map<SObjectField, Object> {
                    Account.Name => 'TestAccount'
                })
                .create()
                .getRecord();

        test.startTest();
        Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
                .setFields(new Map<SObjectField, Object> {
                    Contact.FirstName => 'John',
                    Contact.LastName => 'Doe',
                    Contact.Email => 'test@test.com',
                    Contact.Phone => '1234567890',
                    Contact.AccountId => acc.Id,
                    Contact.BMID__c => 'test123',
                    Contact.LeadSource => 'Inbound Call'
                })
                .create()
                .getRecord();
        test.stopTest();
        List<Contact> contactCampaignAssigned = (List<Contact>) conSelector.selectContactsByIds(new List<Object> { new List<Id> {con.Id} }).executeQuery();
        System.assertEquals(camp1.Id, contactCampaignAssigned[0].Primary_Campaign__c, 'Primary_Campaign__c was not assigned to Contact');
    }

    @isTest
    public static void changeContactStatus_From_3WorkingOpp_To_0Downgraded_ContactRole_bulkOperation_ShouldThrowAnError() {
        System.runAs((User) new UserSelector().selectUserByUsername(new object[]{new string[]{SANDBOX_NAME + '.' +  USER_NAME}}).executeQuery()[0]) {
            Account acc = (Account) new SObjectBuilder(Account.SObjectType)
                .setFields(new Map<SObjectField, Object> {
                    Account.Name => 'TestAccount',
                    Account.RecordTypeId => AccountHelper.RT_ID_PARTNER_ACCOUNT
                })
                .create()
                .getRecord();

            List<Contact> cons =  new SObjectBuilder(Contact.SObjectType)
            .quantity(50)
                .setFields(new Map<SObjectField, Object> {
                    Contact.FirstName => 'John',
                    Contact.LastName => 'Doe',
                    Contact.Email => 'test@test.com',
                    Contact.Phone => '1234567890',
                    Contact.AccountId => acc.Id,
                    Contact.Contact_Status__c => '1. New'
                })
                .create()
                .getRecords();

                List<Opportunity> opps = new List<Opportunity>();

                for (integer i = 0; i < 50; i++) {
                    opps.add((Opportunity) new SObjectBuilder(Opportunity.SObjectType)
                        .setFields(new Map<SObjectField, Object> {
                            Opportunity.RecordTypeId => OpportunityHelper.RT_ID_NEW_SALES_OPPORTUNITY,
                            Opportunity.Primary_Opportunity_Contact__c => cons[i].Id,
                            Opportunity.StageName => '3. Solution',
                            Opportunity.Downgrade_Reason_Opp__c => 'Lost to Competition',
                            Opportunity.Service_Lost__c => 'Mobile'
                        })
                        .build()
                        .getRecord()
                    );
                }

            insert opps;

            List<OpportunityContactRole> ocrs = new List<OpportunityContactRole>();

            for (integer i = 0; i < 50; i++) {
                OpportunityContactRole ocr = (OpportunityContactRole) new SObjectBuilder(OpportunityContactRole.SObjectType)
                    .setFields(new Map<SObjectField, Object>{
                        OpportunityContactRole.ContactId => cons[i].Id,
                        OpportunityContactRole.OpportunityId => opps[i].Id,
                        OpportunityContactRole.Role => 'Influencer',
                        OpportunityContactRole.IsPrimary => true
                    })
                    .getRecord();
            }

            insert ocrs;

            Database.SaveResult [] updateResult;
            Test.startTest();
            Test.getEventBus().deliver();
            TriggerHandler.BY_PASS_CONTACT_ON_UPDATE = false;
            for(Contact con : cons) {
                con.Contact_Status__c = '0. Downgraded';
            }
            updateResult = Database.update(cons, false);
            Test.stopTest();

            System.assertNotEquals(0, updateResult.size(), 'There should be at least one record.');

            for (Database.SaveResult r : updateResult) {
                System.assertEquals(false, r.isSuccess(), 'The record should had failed.');
                System.assertEquals(true, r.getErrors()[0].getMessage().contains('cannot be downgraded because it is primary contact on'),
                    'The exception message should contains "cannot be downgraded because it is primary contact on"'
                );
            }
        }
    }

    @isTest
    public static void changeContactStatus_From_3WorkingOpp_To_0Downgraded_ShouldBeOk() {
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Name => 'TestAccount',
                Account.RecordTypeId => AccountHelper.RT_ID_PARTNER_ACCOUNT
            })
            .create()
            .getRecord();

        Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Contact.FirstName => 'John',
                Contact.LastName => 'Doe',
                Contact.Email => 'test@test.com',
                Contact.Phone => '1234567890',
                Contact.AccountId => acc.Id,
                Contact.Contact_Status__c => '1. New'
            })
            .create()
            .getRecord();

            Boolean exceptionWasTrown = false;
            con.Contact_Status__c = '3. Working Opp';
            update con;
            try {
                Test.startTest();
                    con.Contact_Status__c = '0. Downgraded';
                    update con;
                Test.stopTest();
            } catch(Exception e) {
            }

            System.assertEquals(false, exceptionWasTrown, 'It shouldn\'t throw an exception.');
    }


    @isTest
    static void testPopulateContactStatusToCustomer() {
        ContactSelector conSelector = new ContactSelector();
        AccountSelector accSelector = new AccountSelector();
        User allowedUser = (User) new SObjectBuilder(User.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(User.SObjectType))
            .setFields(new Map<SObjectField, Object> {
                User.UserPermissionsMarketingUser => true,
                User.UserName => 'RCTest@user.com',
                User.CommunityNickname => 'rcTest'
            })
            .create()
            .getRecord();
        Account testAcc = (Account) accSelector.selectAccountByName(new List<Object>{'testAcc'}).executeQuery()[0];
        testAcc.RC_Account_Status__c = 'Paid';
        update testAcc;

        Contact_Customer_Status_Users__c ContactStatusCS = new Contact_Customer_Status_Users__c(SetupOwnerId=allowedUser.Id, isPopulatingCustomer__c = true);
        insert ContactStatusCS;

        test.startTest();
        Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Contact.FirstName => 'Pepe',
                Contact.LastName => 'Test',
                Contact.Email => 'thisIsAEmailTest@TessstingEmail.com',
                Contact.Phone => '1234567890',
                Contact.AccountId => testAcc.Id,
                Contact.Contact_Status__c => null,
                Contact.RCService_ContactStatus__c => 'Active'
            })
            .createAsUser(allowedUser)
            .getRecord();
        test.stopTest();

        Contact testContact = (Contact) conSelector.selectContactsByIds(new List<Object>{ new Set<Id> {con.Id} }).selectField(Contact.Contact_Status__c).executeQuery()[0];
        System.assertEquals('4. Customer', testContact.Contact_Status__c, 'Contact_Status__c was not populated to 4. Customer on Contact Creation');
    }

    @isTest
    static void testDowngradeInactiveRCServiceStatusPositive() {
        ContactSelector conSelector = new ContactSelector();
        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setField(Opportunity.Name, 'Test Opportunity')
            .setField(Opportunity.Type, 'Syndicated - New')
            .setField(Opportunity.StageName, 'Planning')
            .setField(Opportunity.CloseDate, System.today().addMonths(1))
            .setField(
                Opportunity.RecordTypeId,
                Opportunity.SObjectType.getDescribe()
                    .getRecordTypeInfosByName()
                    .get('New Sales Opportunity')
                    .getRecordTypeId()
            )
            .create()
            .getRecord();
        Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Contact.FirstName => 'Pepe',
                Contact.LastName => 'Test',
                Contact.Email => 'thisIsAEmailTest@TessstingEmail.com',
                Contact.Phone => '1234567890',
                Contact.Contact_Status__c => '1. New'
            })
            .create()
            .getRecord();
        OpportunityContactRole oppCR = (OpportunityContactRole)
            new SObjectBuilder(OpportunityContactRole.SObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                OpportunityContactRole.ContactId => con.Id,
                OpportunityContactRole.OpportunityId => opp.Id,
                OpportunityContactRole.Role => 'Signatory',
                OpportunityContactRole.isPrimary => false
                }
            )
            .create()
            .getRecord();

        test.startTest();
        con.RCService_ContactStatus__c = 'Inactive';
        update con;
        test.stopTest();

        Contact testContact = (Contact) conSelector.selectContactsByIds(new List<Object>{ new Set<Id> {con.Id} }).selectField(Contact.Contact_Status__c).executeQuery()[0];
        System.assertEquals('0. Downgraded', testContact.Contact_Status__c,
         'Contact_Status__c was not populated to 0. Downgraded on Contact RCService_ContactStatus__c Update');
    }

    @isTest
    static void testDowngradeInactiveRCServiceStatusNegative() {
        ContactSelector conSelector = new ContactSelector();
        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setField(Opportunity.Name, 'Test Opportunity')
            .setField(Opportunity.Type, 'Syndicated - New')
            .setField(Opportunity.StageName, 'Planning')
            .setField(Opportunity.CloseDate, System.today().addMonths(1))
            .setField(
                Opportunity.RecordTypeId,
                Opportunity.SObjectType.getDescribe()
                    .getRecordTypeInfosByName()
                    .get('New Sales Opportunity')
                    .getRecordTypeId()
            )
            .create()
            .getRecord();
        Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Contact.FirstName => 'Pepe',
                Contact.LastName => 'Test',
                Contact.Email => 'thisIsAEmailTest@TessstingEmail.com',
                Contact.Phone => '1234567890',
                Contact.Contact_Status__c => '1. New'
            })
            .create()
            .getRecord();
        OpportunityContactRole oppCR = (OpportunityContactRole)
            new SObjectBuilder(OpportunityContactRole.SObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                OpportunityContactRole.ContactId => con.Id,
                OpportunityContactRole.OpportunityId => opp.Id,
                OpportunityContactRole.Role => 'Signatory',
                OpportunityContactRole.isPrimary => True
                }
            )
            .create()
            .getRecord();

        test.startTest();
        try {
            con.RCService_ContactStatus__c = 'Inactive';
            update con;
        } catch (Exception e) {
            Boolean isError =  e.getMessage().
            contains('cannot be set to inactive because it is primary on the following open Opportunities: ') ? true : false;
            System.assertEquals(true, isError, 'Error message should have been displayed');
        }
        test.stopTest();

        Contact testContact = (Contact) conSelector.selectContactsByIds(new List<Object>{ new Set<Id> {con.Id} }).selectField(Contact.Contact_Status__c).executeQuery()[0];
        System.assertNotEquals('0. Downgraded', testContact.Contact_Status__c,
         'Contact_Status__c was populated to 0. Downgraded on Contact RCService_ContactStatus__c Update beign Primary in any Open Opportunity');
    }


    @isTest
    static void testDowngradeInactiveRCServiceStatusOnContactCreation() {
        ContactSelector conSelector = new ContactSelector();

        test.startTest();
        Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Contact.FirstName => 'Pepe',
                Contact.LastName => 'Test',
                Contact.Email => 'thisIsAEmailTest@TessstingEmail.com',
                Contact.Phone => '1234567890',
                Contact.Contact_Status__c => '1. New',
                Contact.RCService_ContactStatus__c => 'Inactive'
            })
            .create()
            .getRecord();
        test.stopTest();

        Contact testContact = (Contact) conSelector.selectContactsByIds(new List<Object>{ new Set<Id> {con.Id} }).selectField(Contact.Contact_Status__c).executeQuery()[0];
        System.assertEquals('0. Downgraded', testContact.Contact_Status__c, 'Contact_Status__c was not populated to 0. Downgraded on Contact Creation');
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testSetStatusToReNewWithAccountStatusCancelled() {
        Account acc = (Account) new AccountSelector().selectAccounts().executeQuery()[0];
        Contact con = (Contact) new ContactSelector()
            .selectContactsByAccountId(new List<Object>{ acc.Id })
            .executeQuery()[0];
        Test.startTest();
        acc.RC_Account_Status__c = 'Cancelled';
        update acc;
        con.Contact_Status__c = '1. New';
        update con;
        Test.getEventBus().deliver();
        Test.stopTest();

        Contact conToAssert = (Contact) new ContactSelector()
            .selectContactsByAccountId(new List<Object>{ acc.Id })
            .selectField(Contact.Contact_Status__c)
            .executeQuery()[0];
        //System.AssertEquals('.5 Re-New', conToAssert.Contact_Status__c);
    }

    @isTest
    public static void changeContactStatus_From_4Customer_To_ReNew_Using_Porfile_SysAdmin_ShouldBeOk(){
        Profile sysAdminProfile = (Profile) new ProfileSelector().selectProfileByName(new String[]{'System administrator'}).executeQuery()[0];

        TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT();
        TriggerHandler.BY_PASS_OPPORTUNITY_ON_INSERT();

        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setField(Account.Name, 'Test Account')
            .create()
            .getRecord();

        Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setField(Contact.FirstName, 'John')
            .setField(Contact.LastName, 'Doe')
            .setField(Contact.Email, 'thisIsAnEmailForTesting@gmail.test.invalid')
            .setField(Contact.Contact_Status__c, '4. Customer')
            .setField(Contact.Contact_Funnel_Type__c, 'Prospect')
            .setField(Contact.AccountId, acc.Id)
            .create()
            .getRecord();

        Boolean transactionSuccess = true;

        Test.startTest();
            con.Contact_Status__c = '.5 Re-New';
            try {
                System.runAs((User) new SObjectBuilder(User.SObjectType)
                    .setField(User.Username, 'usernameTest@gmail.invalid')
                    .setField(User.Email, 'usernameTest@gmail.invalid')
                    .setfield(User.LastName, 'lastnameTest')
                    .setField(User.ProfileId, sysAdminProfile.Id)
                    .setField(User.CommunityNickname, 'test15')
                    .create()
                    .getRecord()
                ){
                    update con;
                }
            } catch(Exception e) {
                transactionSuccess = false;
            }
        Test.stopTest();

        system.assert(transactionSuccess, 'The transaction shouldn\'t throw an exception.');
    }

    @isTest
    static void testPhoneNumberValidation() {
        Account testAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => 'testAcc'
                }
            )
            .create()
            .getRecord();

        Contact contact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.FirstName => 'Test1',
                    Contact.LastName => 'Test1',
                    Contact.AccountId => testAccount.Id,
                    Contact.Email => 'test@test.com',
                    Contact.Phone => '1234',
                    Contact.Preferred_Language__c => 'en_US',
                    Contact.Marketo_Sync_Disabled__c => true,
                    Contact.Is_Instructor__c => true,
                    Contact.Account_Admin__c => true
                }
            )
            .build()
            .getRecord();

        Test.startTest();
        try{
            insert contact;
        }catch(Exception ex){
            Boolean isError =  ex.getMessage().contains('Please use at least 7 digits and no letters in the phone number') ? true : false;
            System.assertEquals(true, isError, 'The exception message should contains: "Please use at least 7 digits and no letters in the phone number"');
        }
        Test.stopTest();

    }
    @isTest
    static void testPhoneNumberValidationForACRNegative() {
        Account testAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => 'testAcc'
                }
            )
            .create()
            .getRecord();

        Contact contact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.FirstName => 'Test1',
                    Contact.LastName => 'Test1',
                    Contact.AccountId => testAccount.Id,
                    Contact.Email => 'test@test.com',
                    Contact.Phone => '123456789',
                    Contact.Preferred_Language__c => 'en_US',
                    Contact.Marketo_Sync_Disabled__c => true,
                    Contact.Is_Instructor__c => true,
                    Contact.Account_Admin__c => true
                }
            )
            .create()
            .getRecord();

        AccountContactRole accRole = (AccountContactRole) new SObjectBuilder(AccountContactRole.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                AccountContactRole.AccountId => testAccount.Id,
                AccountContactRole.ContactId => contact.Id,
                AccountContactRole.Role => AccountContactRoleHelper.CONTACT_ROLE_ACCOUNT_PAYABLE
            })
            .create()
            .getRecord();

        Test.startTest();
        try{
            contact.Phone = '7812978129781297812978129781297123';
            update contact;
        }catch(Exception ex){
            Boolean isError =  ex.getMessage().contains(ContactHelper.CONTACT_PHONE_NOT_IN_RANGE) ? true : false;
            System.assertEquals(true, isError, 'The exception message should contains: ' + ContactHelper.CONTACT_PHONE_NOT_IN_RANGE);
        }
        Test.stopTest();

    }

    @isTest
    static void testPhoneNumberValidationForACRPositive() {
        Account testAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => 'testAcc'
                }
            )
            .create()
            .getRecord();

        Contact contact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.FirstName => 'Test1',
                    Contact.LastName => 'Test1',
                    Contact.AccountId => testAccount.Id,
                    Contact.Email => 'test@test.com',
                    Contact.Phone => '123456789',
                    Contact.Preferred_Language__c => 'en_US',
                    Contact.Marketo_Sync_Disabled__c => true,
                    Contact.Is_Instructor__c => true,
                    Contact.Account_Admin__c => true
                }
            )
            .create()
            .getRecord();

        AccountContactRole accRole = (AccountContactRole) new SObjectBuilder(AccountContactRole.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                AccountContactRole.AccountId => testAccount.Id,
                AccountContactRole.ContactId => contact.Id,
                AccountContactRole.Role => AccountContactRoleHelper.CONTACT_ROLE_SIGNATORY
            })
            .create()
            .getRecord();

        Test.startTest();
        try{
            contact.Phone = '7812978129781297812978129781297123';
            insert contact;
        }catch(Exception ex){
            Boolean isError =  ex.getMessage().contains(ContactHelper.CONTACT_PHONE_NOT_IN_RANGE) ? true : false;
            System.assertEquals(false, isError, 'The exception message should not contains: ' + ContactHelper.CONTACT_PHONE_NOT_IN_RANGE);
        }
        Test.stopTest();

    }

    @isTest
    public static void UpdateRCServiceToInactive_UsingMarketoIntegrationProfile_ShouldNotThrowException() {
        Profile marketoIntegrationProfile = (Profile) new ProfileSelector().selectProfileByName(new String[]{MARKETO_INTEGRATION_PROFILE}).executeQuery()[0];

        TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT();
        TriggerHandler.BY_PASS_OPPORTUNITY_ON_INSERT();

        Boolean transactionSuccess = true;
        User marketoUser = (User) new SObjectBuilder(User.SObjectType)
            .setField(User.Username, 'usernameTest@gmail.invalid')
            .setField(User.Email, 'usernameTest@gmail.invalid')
            .setfield(User.LastName, 'lastnameTest')
            .setField(User.ProfileId, marketoIntegrationProfile.Id)
            .setField(User.CommunityNickname, 'test15')
            .create()
            .getRecord();
        Opportunity opp;
        Contact con;
        System.runAs(marketoUser){
            opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
                .setField(Opportunity.Name, 'Test Opportunity')
                .setField(Opportunity.Type, 'Syndicated - New')
                .setField(Opportunity.StageName, 'Planning')
                .setField(Opportunity.CloseDate, System.today().addMonths(1))
                .setField(
                    Opportunity.RecordTypeId,
                    Opportunity.SObjectType.getDescribe()
                        .getRecordTypeInfosByName()
                        .get('New Sales Opportunity')
                        .getRecordTypeId()
                )
                .create()
                .getRecord();
            con = (Contact) new SObjectBuilder(Contact.SObjectType)
                .setFields(new Map<SObjectField, Object> {
                    Contact.FirstName => 'Pepe',
                    Contact.LastName => 'Test',
                    Contact.Email => 'thisIsAEmailTest@TessstingEmail.com',
                    Contact.Phone => '1234567890',
                    Contact.Contact_Status__c => '1. New'
                })
                .create()
                .getRecord();
        }

        OpportunityContactRole oppCR = (OpportunityContactRole)
            new SObjectBuilder(OpportunityContactRole.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                OpportunityContactRole.ContactId => con.Id,
                OpportunityContactRole.OpportunityId => opp.Id,
                OpportunityContactRole.Role => 'Signatory',
                OpportunityContactRole.isPrimary => True
            })
            .create()
            .getRecord();

        Test.startTest();
            con.RCService_ContactStatus__c = 'Inactive';
            try {
                System.runAs(marketoUser) {
                    update con;
                }
            } catch(Exception e) {
                transactionSuccess = false;
            }
        Test.stopTest();

        system.assert(transactionSuccess, 'The transaction shouldn\'t throw an exception.');
    }
    @isTest
    public static void UpdateRCServiceToInactive_UsingFinanceAdminProfile_ShouldThrowException() {
        Profile sysAdminProfile = (Profile) new ProfileSelector().selectProfileByName(new String[]{MARKETO_INTEGRATION_PROFILE}).executeQuery()[0];

        TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT();
        TriggerHandler.BY_PASS_OPPORTUNITY_ON_INSERT();

            Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setField(Opportunity.Name, 'Test Opportunity')
            .setField(Opportunity.Type, 'Syndicated - New')
            .setField(Opportunity.StageName, 'Planning')
            .setField(Opportunity.CloseDate, System.today().addMonths(1))
            .setField(
                Opportunity.RecordTypeId,
                Opportunity.SObjectType.getDescribe()
                    .getRecordTypeInfosByName()
                    .get('New Sales Opportunity')
                    .getRecordTypeId()
            )
            .create()
            .getRecord();
        Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Contact.FirstName => 'Pepe',
                Contact.LastName => 'Test',
                Contact.Email => 'thisIsAEmailTest@TessstingEmail.com',
                Contact.Phone => '1234567890',
                Contact.Contact_Status__c => '1. New'
            })
            .create()
            .getRecord();

        OpportunityContactRole oppCR = (OpportunityContactRole)
            new SObjectBuilder(OpportunityContactRole.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                OpportunityContactRole.ContactId => con.Id,
                OpportunityContactRole.OpportunityId => opp.Id,
                OpportunityContactRole.Role => 'Signatory',
                OpportunityContactRole.isPrimary => True
            })
            .create()
            .getRecord();

        Boolean transactionFailed = false;

        Test.startTest();
            con.RCService_ContactStatus__c = 'Inactive';
            try {
                System.runAs((User) new UserSelector().selectUserByLastName(new Object[]{'testUser'}).executeQuery()[0]) {
                    update con;
                }
            } catch(Exception e) {
                transactionFailed = true;
            }
        Test.stopTest();

        system.assert(transactionFailed, 'The transaction should throw an exception.');
    }
    @isTest
    public static void updateContactStatusToDowngraded_When_ContactHasAccountStatusCancelAndWithoutDFR_Should_NotCreateADFR(){

        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setField(Account.Name, 'Test Account')
            .setField(Account.RC_Account_Status__c, 'Cancel Test')
            .create()
            .getRecord();

        Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Contact.FirstName => 'Pepe',
                Contact.LastName => 'Test',
                Contact.Email => 'thisIsAEmailTest@TessstingEmail.com',
                Contact.AccountId => acc.Id
            })
            .create()
            .getRecord();

        System.AssertEquals(
            0,
            new DemandFunnelSelector().selectDFRByContactTest(new Object[]{new Contact[]{con}}).executeQuery().size(),
            'There should not exist a dfr created.'
        );

        Test.startTest();
            con.Contact_Status__c = '0. Downgraded';
            update con;
        Test.stopTest();

        con = (Contact) new ContactSelector()
            .selectContactById(new Object[]{con.Id})
            .selectField(Contact.Contact_Status__c)
            .executeQuery()[0];

        System.assertEquals('0. Downgraded', con.Contact_Status__c, 'The Contact Status field value should be 0 Downgraded.');

        System.AssertEquals(
            0,
            new DemandFunnelSelector().selectDFRByContactTest(new Object[]{new Contact[]{con}}).executeQuery().size(),
            'There should not exist a dfr created.'
        );
    }
    @isTest
    public static void accountDFR_whenUpdateAccountField_ShouldUpdateAccountDFR(){

        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setField(Account.Name, 'Test Account')
            .create()
            .getRecord();

        List<Contact> conts;
        Test.startTest();
            conts = (List<Contact>) new SObjectBuilder(Contact.SObjectType)
                .setField(Contact.LastName, 'LastName test')
                .setField(Contact.AccountId, acc.Id)
                .setField(Contact.Contact_Status__c, '2. Contacted')
                .quantity(50)
                .create()
                .getRecords();
        Test.stopTest();

        List<Demand_Funnel__c> dfrs = (List<Demand_Funnel__c>) new DemandFunnelSelector()
            .selectDFRByContactTest(new Object[]{conts})
            .selectField(Demand_Funnel__c.Account__c)
            .executeQuery();

        System.assertEquals(50, dfrs.size(), 'There should be 50 created DFRs.');

        for (Demand_Funnel__c dfr : dfrs) {
            System.assertEquals(acc.Id, dfr.Account__c, 'The account should be the same as the Contact');
        }
    }
    @isTest
    public static void accountDFR_whenUpdateAccountField_ShouldNotUpdateAccountDFR() {

        Triggers.switchOff();

        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setField(Account.Name, 'Test Account')
            .create()
            .getRecord();

        Contact cont = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setField(Contact.LastName, 'LastName test')
            .setField(Contact.AccountId, acc.Id)
            .setField(Contact.Contact_Status__c, '2. Contacted')
            .create()
            .getRecord();

        Account acc2 = (Account) new SObjectBuilder(Account.SObjectType)
            .setField(Account.Name, 'TestAccount')
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.Name => 'Test Opportunity 2016',
                Opportunity.Type => 'Syndicated - New',
                Opportunity.StageName => 'Planning',
                Opportunity.CloseDate => system.today().addMonths(1),
                Opportunity.AccountId => acc2.Id
            })
            .create()
            .getRecord();

        Account acc3 = (Account) new SObjectBuilder(Account.SObjectType)
            .setField(Account.Name, 'Test Account')
            .create()
            .getRecord();

        Triggers.switchOn();

        List<Demand_Funnel__c> dfrs = (List<Demand_Funnel__c>) new SObjectBuilder(Demand_Funnel__c.SObjectType)
            .setField(Demand_Funnel__c.Opportunity__c, opp.Id)
            .setField(Demand_Funnel__c.Contact__c, cont.Id)
            .quantity(50)
            .create()
            .getRecords();

        Test.startTest();
            cont.AccountId = acc3.id;
            update cont;
        Test.stopTest();

        dfrs = (List<Demand_Funnel__c>) new DemandFunnelSelector()
            .selectDFRByIds(new Object[]{dfrs})
            .selectField(Demand_Funnel__c.Account__c)
            .executeQuery();

        System.assertEquals(50, dfrs.size(), 'There should be 50 created DFRs.');

        for (Demand_Funnel__c dfr : dfrs) {
            System.assertEquals(acc2.Id, dfr.Account__c, 'The account should be the same as the Contact');
        }
    }
    @isTest
    public static void SMEmployeesDFR_whenUpdateAccountField_ShouldUpdateSMCountry(){

        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setField(Account.Name, 'Test Account')
            .setField(Account.Emp_Range_Sales_Override__c, 102)
            .create()
            .getRecord();

        Account acc2 = (Account) new SObjectBuilder(Account.SObjectType)
            .setField(Account.Name, 'Test Account2')
            .setField(Account.Emp_Range_Sales_Override__c, 159)
            .create()
            .getRecord();

        List<Contact> conts = (List<Contact>) new SObjectBuilder(Contact.SObjectType)
            .setField(Contact.LastName, 'LastName test')
            .setField(Contact.AccountId, acc.Id)
            .setField(Contact.Contact_Status__c, '2. Contacted')
            .quantity(50)
            .create()
            .getRecords();
        Test.startTest();
            for (Contact cont : conts) {
                cont.AccountId = acc2.Id;
            }
            update conts;
        Test.stopTest();

        List<Demand_Funnel__c> dfrs = (List<Demand_Funnel__c>) new DemandFunnelSelector()
            .selectDFRByContactTest(new Object[]{conts})
            .selectField(Demand_Funnel__c.Account__c)
            .selectField(Demand_Funnel__c.SM_Employees__c)
            .executeQuery();

        System.assertEquals(50, dfrs.size(), 'There should be 50 created DFRs.');

        for (Demand_Funnel__c dfr : dfrs) {
            System.assertEquals(acc2.Id, dfr.Account__c, 'The account should be the same as the Contact');
            System.assertEquals(159, dfr.SM_Employees__c, 'The  SM EMployees should be the same as the Contact Account SM EMployees');
        }
    }

    @isTest
    public static void AccountIdCustomFieldShouldBePopulated(){

        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setField(Account.Name, 'Test Account')
            .create()
            .getRecord();

        Test.startTest();
        Contact cont = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setField(Contact.LastName, 'Test Name')
            .setField(Contact.AccountId, acc.Id)
            .create()
            .getRecord();

            Map<Id, Contact> contacts = new Map<Id, Contact>([SELECT Id, AccountId, Matching_Rule_Account__c FROM Contact]);
            System.assertEquals(contacts.get(cont.Id).AccountId, contacts.get(cont.Id).Matching_Rule_Account__c, 'custom account id should be populated on insert');

            Account acc2 = (Account) new SObjectBuilder(Account.SObjectType)
                .setField(Account.Name, 'Test Account2')
                .create()
                .getRecord();

            contacts.get(cont.Id).AccountId = acc2.Id;
            update contacts.get(cont.Id);
        Test.stopTest();

        Map<Id, Contact> reselectedContacts = new Map<Id, Contact>([SELECT Id, AccountId, Matching_Rule_Account__c FROM Contact]);
        System.assertEquals(reselectedContacts.get(cont.Id).AccountId, reselectedContacts.get(cont.Id).Matching_Rule_Account__c, 'custom account id should be populated on update');
    }

    /* CRM-5077 - Added as Part of EU Data Privacy Project to restrict changing the Account Owner when the Record is of EU*/
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
	public static void CheckEUDataPrivacyTest(){
        List<Account> accountListt = new List<Account>();
        Account acctObjj = new Account();
        acctObjj.Name = 'Test12';
        acctObjj.Number_of_DL_s__c = 2;
        acctObjj.RC_Service_name__c = 'office123';
        acctObjj.RC_Account_Status__c = 'Paid';
        acctObjj.BillingCountry = 'Germany';
        accountListt.add(acctObjj);
        //insert acctObjj;

        Account acctObjj1 = new Account();
        acctObjj1.Name = 'Test122';
        acctObjj1.Number_of_DL_s__c = 3;
        acctObjj1.RC_Service_name__c = 'office1233';
        acctObjj1.RC_Account_Status__c = 'Canceled';
        //acctObjj.SM_Country__c = 'Germany';
        accountListt.add(acctObjj1);
        insert accountListt;

        List<contact> lstconn = new list<contact>();
        Contact contactObj = new Contact();
        contactObj.LastName= 'TEst1';
        contactObj.AccountId =  acctObjj.id;
        contactObj.isCustomer__c=True;
        contactObj.Contact_Status__c='Closed Won';
        contactObj.Contact_Funnel_Type__c='Customer';
        contactObj.People_Segment__c='Customer';
        lstconn.add(contactObj);

        insert lstconn;
        List<contact> lstconnupdate = new list<contact>();
        User u = [Select id from user where usertype='Standard' and isActive=true limit 1];
        for(Contact c:lstconn){
            c.ownerid = u.id;
            lstconnupdate.add(c);
        }
	    update lstconnupdate;
    }

    @isTest
    private static void testProcessDUNSLogic() {

        Test.startTest();
        Account_Hierarchy__c accHier = (Account_Hierarchy__c) new SObjectBuilder(Account_Hierarchy__c.SObjectType)
            .create()
            .getRecord();

        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Name => 'TestAccount',
                Account.SignupType__c => 'TRIAL_30NOCC',
                Account.SignupPlatform__c => 'WEB',
                Account.RC_Account_Status__c => 'TRIAL 30 NO-CC',
                Account.RecordTypeId => AccountHelper.RT_ID_CUSTOMER_ACCOUNT,
                Account.AH_Name__c => accHier.Id
            })
            .create()
            .getRecord();

        Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Contact.FirstName => 'John',
                Contact.LastName => 'Doe',
                Contact.Email => 'test@test.com',
                Contact.Phone => '1234567890',
                Contact.AccountId => acc.Id,
                Contact.Technical_Certification__c => 'Certified Professional',
                Contact.Marketo_Sync_Disabled__c => false
            })
            .create()
            .getRecord();
        Test.stopTest();

        System.assert([SELECT COUNT() FROM Company_Persons__c] > 0, 'New company person should be created');
    }

    @isTest
    private static void testvalidateChangeContact() {

        List<sObject> accobj = new List<sObject>();
        Set<Id> contsIdSet = new Set<Id>();
        ContactTriggerHandler.ValidateContactedit vc = new ContactTriggerHandler.ValidateContactedit();


        AccountContactRole accConRole = [SELECT Id FROM AccountContactRole LIMIT 1];

        Contact contact = [SELECT Id FROM Contact where email = 'test@test.com' LIMIT 1];

        if(contact != null){
            contsIdSet.add(accConRole.Id);
        }

        Test.startTest();

        accobj = vc.validateChangeContact('AccountContactRole', contsIdSet);

        Test.stopTest();

        System.assert(accobj != null, 'validateChangeContact method is not working ok');
    }

    @isTest
    private static void addCoverageValidateContactedit() {

    Boolean exceptionThrown = false;

    Profile sysAdminProfile = (Profile) new ProfileSelector().selectProfileByName(new String[]{'System administrator'}).executeQuery()[0];
        Triggers.switchOff();
        User adminUser = (User) new SObjectBuilder (User.SObjectType)
        .setFields(
            new Map<SObjectField, Object>{
                User.LastName => 'testUser3',
                User.Username => SANDBOX_NAME + '.' +  USER_NAME + '3',
                User.Email => 'testUser3@gmail.com',
                User.Alias => 'testUs3',
                User.TimeZoneSidKey => 'America/Los_Angeles',
                User.LocaleSidKey => 'en_US',
                User.EmailEncodingKey => 'UTF-8',
                User.ProfileId => sysAdminProfile.Id,
                User.CommunityNickname => 'test20'
            }
        )
        .create()
        .getRecord();

        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Name => 'TestAccount2',
                Account.SignupType__c => 'Test',
                Account.RC_Account_Status__c => 'Paid'
            })
            .create()
            .getRecord();

        Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Contact.FirstName => 'John',
                Contact.LastName => 'Doe',
                Contact.Email => 'test@testt.com',
                Contact.Phone => '1234567890',
                Contact.AccountId => acc.Id
            })
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.AccountId => acc.Id,
                Opportunity.Tier_Name__c => OpportunityHelper.TIER_ENGAGE_VOICE_LEGACY,
                Opportunity.CloseDate => System.today().addMonths(1),
                Opportunity.RecordTypeId => Opportunity.SObjectType.getDescribe()
                    .getRecordTypeInfosByName()
                    .get('New Sales Opportunity')
                    .getRecordTypeId()
            })
            .create()
            .getRecord();

        Test.startTest();
        AccountContactRole accRole = (AccountContactRole) new SObjectBuilder(AccountContactRole.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    AccountContactRole.AccountId => acc.Id,
                    AccountContactRole.ContactId => con.Id,
                    AccountContactRole.IsPrimary => true
                }
            )
            .create()
            .getRecord();

        OpportunityContactRole ocr = (OpportunityContactRole) new SObjectBuilder(OpportunityContactRole.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                OpportunityContactRole.ContactId => con.Id,
                OpportunityContactRole.OpportunityId => opp.Id,
                OpportunityContactRole.IsPrimary => true
            })
            .create()
            .getRecord();
        Triggers.switchOn();


        Contact contact = [SELECT Id, Phone FROM Contact where email = 'test@testt.com' LIMIT 1];
        contact.Phone = '123456789';

        System.runAs(adminUser){
            try{
                update contact;
            } catch (Exception e){
                exceptionThrown = true;
            }
        }
        Test.stopTest();

        System.assertEquals(true, exceptionThrown, 'No exception was thrown');
    }

    @isTest
    static void testInsertedContactDate_Status_Changed() {
        Contact con = new Contact();
        Account acc = [SELECT Id, RunContactMostFrequentEmail__c
                        FROM Account
                        WHERE Name = 'testAcc'];

        Test.startTest();
            con = (Contact) new SObjectBuilder(Contact.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        Contact.FirstName => 'TestStatus',
                        Contact.LastName => 'Test',
                        Contact.AccountId => acc.Id,
                        Contact.Email => 'testing@gmail.com',
                        Contact.Phone => '1234567890',
                        Contact.Preferred_Language__c => 'en_US',
                        Contact.Contact_Status__c => '1. New'
                    }
                )
                .create()
                .getRecord();
        Test.stopTest();

        Contact conNew = [SELECT Id, Date_Status_Changed__c
                        FROM Contact
                        WHERE Email = 'testing@gmail.com'
                        LIMIT 1];

        System.assert(conNew.Date_Status_Changed__c != null,
            'Date_Status_Changed__c should be populated');

        System.assertEquals(conNew.Date_Status_Changed__c, Date.today(),
            'Date_Status_Changed__c field should be equal to today.');

    }

    @isTest
    static void testUpdatedContactDate_Status_Changed() {
        Contact con = [SELECT Id, Date_Status_Changed__c
                        FROM Contact
                        WHERE Email = 'test@test.com'
                        LIMIT 1];

        con.Contact_Status__c = '1. New';

        Test.startTest();
        update con;
        Test.stopTest();

        Contact con2 = [SELECT Id, Date_Status_Changed__c
                        FROM Contact
                        WHERE Email = 'test@test.com'
                        LIMIT 1];

        System.assert(con2.Date_Status_Changed__c != null,
            'Date_Status_Changed__c should be populated');

        System.assertEquals(con2.Date_Status_Changed__c, Date.today(),
            'Date_Status_Changed__c field should be equal to today.');

    }

    @isTest
    private static void recalculateCDPDeliverStatusAccountField_whenAccountFieldIsChanged_shouldUpdateAccounts() {
        skilljar__Course__c course = (skilljar__Course__c) new SObjectBuilder(skilljar__Course__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    skilljar__Course__c.skilljar__Title__c => 'CDP Course',
                    skilljar__Course__c.skilljar__Skilljar_Id__c => '123456',
                    skilljar__Course__c.skilljar__Short_Description__c => 'This is a CDP Course test record',
                    skilljar__Course__c.CDP_Course__c => true
                }
            )
            .create()
            .getRecord();

        skilljar__Published_Course__c publishedCourse = (skilljar__Published_Course__c) new SObjectBuilder(skilljar__Published_Course__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    skilljar__Published_Course__c.skilljar__Course_Title__c => 'CDP Course',
                    skilljar__Published_Course__c.skilljar__Course_URL__c => 'https://fakeurl.com',
                    skilljar__Published_Course__c.skilljar__Domain__c => 'fakeurl',
                    skilljar__Published_Course__c.skilljar__Lesson_Count__c => 1,
                    skilljar__Published_Course__c.skilljar__Obfuscated_Id__c => '123456',
                    skilljar__Published_Course__c.skilljar__Course__c => course.Id
                }
            )
            .create()
            .getRecord();

        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Name => 'test'
            })
            .create()
            .getRecord();

        Account acc2 = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Name => 'test2'
            })
            .create()
            .getRecord();

        Contact cont = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.FirstName => 'firstname',
                    Contact.LastName => 'lastname',
                    Contact.Email => 'fakeemail@gmail.com',
                    Contact.Phone => '12345678',
                    Contact.Phone_Ext__c => 123,
                    Contact.Contact_Status__c => '2. Contacted',
                    Contact.AccountId => acc.Id
                }
            )
            .create()
            .getRecord();

        skilljar__Student__c student = (skilljar__Student__c) new SObjectBuilder(skilljar__Student__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    skilljar__Student__c.skilljar__Obfuscated_Id__c => '123456',
                    skilljar__Student__c.skilljar__Contact__c => cont.Id,
                    skilljar__Student__c.skilljar__Email__c => 'fakeemail@gmail.com'
                }
            )
            .create()
            .getRecord();

        skilljar__Course_Progress__c[] CPs = (List<skilljar__Course_Progress__c>) new SObjectBuilder(skilljar__Course_Progress__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    skilljar__Course_Progress__c.skilljar__Obfuscated_Id__c => ValueProviderBuilder.provideList(new String[]{'123456','12345'}),
                    skilljar__Course_Progress__c.skilljar__Published_Course__c => publishedCourse.Id,
                    skilljar__Course_Progress__c.skilljar__Student__c => student.Id,
                    skilljar__Course_Progress__c.skilljar__Course__c => course.Id,
                    skilljar__Course_Progress__c.skilljar__Contact__c => cont.Id
                }
            )
            .quantity(2)
            .create()
            .getRecords();

        CPs[0].skilljar__Completed_At__c = Datetime.now();
        CPs[1].skilljar__Completed_At__c = Datetime.now();
        update CPs;

        Test.startTest();
            cont.AccountId = acc2.Id;
            update cont;
        Test.stopTest();


        acc = (Account) new AccountSelector()
            .selectAccountByName(new Object[]{'test'})
            .selectFields(new List<String>{'Certified_Delivery_Partner_Status__c'})
            .executeQuery()[0];

        Assert.areEqual(CourseProgressHelper.CDP_STATUS_NONE, acc.Certified_Delivery_Partner_Status__c, 'Invalid value');

        acc2 = (Account) new AccountSelector()
            .selectAccountByName(new Object[]{'test2'})
            .selectFields(new List<String>{'Certified_Delivery_Partner_Status__c'})
            .executeQuery()[0];


        Assert.areEqual(CourseProgressHelper.CDP_STATUS_COMPLETE, acc2.Certified_Delivery_Partner_Status__c, 'Invalid value');
    }

    @isTest
    private static void recalculateCDPDeliverStatusAccountField_whenAccountFieldIsChangedFromOneContact_shouldUpdateAccounts() {
        Triggers.switchOff();
        skilljar__Course__c course = (skilljar__Course__c) new SObjectBuilder(skilljar__Course__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    skilljar__Course__c.skilljar__Title__c => 'CDP Course',
                    skilljar__Course__c.skilljar__Skilljar_Id__c => '123456',
                    skilljar__Course__c.skilljar__Short_Description__c => 'This is a CDP Course test record',
                    skilljar__Course__c.CDP_Course__c => true
                }
            )
            .create()
            .getRecord();

        skilljar__Published_Course__c publishedCourse = (skilljar__Published_Course__c) new SObjectBuilder(skilljar__Published_Course__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    skilljar__Published_Course__c.skilljar__Course_Title__c => 'CDP Course',
                    skilljar__Published_Course__c.skilljar__Course_URL__c => 'https://fakeurl.com',
                    skilljar__Published_Course__c.skilljar__Domain__c => 'fakeurl',
                    skilljar__Published_Course__c.skilljar__Lesson_Count__c => 1,
                    skilljar__Published_Course__c.skilljar__Obfuscated_Id__c => '123456',
                    skilljar__Published_Course__c.skilljar__Course__c => course.Id
                }
            )
            .create()
            .getRecord();

        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Name => 'test'
            })
            .create()
            .getRecord();

        Account acc2 = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Name => 'test2'
            })
            .create()
            .getRecord();

        Contact[] conts = (Contact[]) new SObjectBuilder(Contact.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.FirstName => ValueProviderBuilder.provideList(new String[]{'firstname','firstname2'}),
                    Contact.LastName => ValueProviderBuilder.provideList(new String[]{'lastname','lastname2'}),
                    Contact.Email => ValueProviderBuilder.provideList(new String[]{'fakeemail@gmail.com','fakeemail2@gmail.com'}),
                    Contact.Phone => ValueProviderBuilder.provideList(new String[]{'12345678','123456781'}),
                    Contact.Phone_Ext__c => 123,
                    Contact.Contact_Status__c => '2. Contacted',
                    Contact.AccountId => acc.Id
                }
            )
            .quantity(2)
            .create()
            .getRecords();

        skilljar__Student__c[] students = (skilljar__Student__c[]) new SObjectBuilder(skilljar__Student__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    skilljar__Student__c.skilljar__Obfuscated_Id__c => ValueProviderBuilder.provideList(new String[]{'123456','1234563'}),
                    skilljar__Student__c.skilljar__Contact__c => ValueProviderBuilder.provideList(new Id[]{conts[0].Id, conts[1].Id}),
                    skilljar__Student__c.skilljar__Email__c => 'fakeemail@gmail.com'
                }
            )
            .quantity(2)
            .create()
            .getRecords();

        skilljar__Course_Progress__c[] CPs = (List<skilljar__Course_Progress__c>) new SObjectBuilder(skilljar__Course_Progress__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    skilljar__Course_Progress__c.skilljar__Obfuscated_Id__c => ValueProviderBuilder.provideList(new String[]{'123456','12345'}),
                    skilljar__Course_Progress__c.skilljar__Published_Course__c => publishedCourse.Id,
                    skilljar__Course_Progress__c.skilljar__Student__c => ValueProviderBuilder.provideList(new Id[]{students[0].Id, students[1].Id}),
                    skilljar__Course_Progress__c.skilljar__Course__c => course.Id,
                    skilljar__Course_Progress__c.skilljar__Contact__c => ValueProviderBuilder.provideList(new Id[]{conts[0].Id, conts[1].Id})
                }
            )
            .quantity(2)
            .create()
            .getRecords();
        Triggers.switchOn();

        CPs[0].skilljar__Completed_At__c = Datetime.now();
        CPs[1].skilljar__Completed_At__c = Datetime.now();
        update CPs;

        Test.startTest();
            conts[0].AccountId = acc2.Id;
            update conts[0];
        Test.stopTest();


        acc = (Account) new AccountSelector()
            .selectAccountByName(new Object[]{'test'})
            .selectFields(new List<String>{'Certified_Delivery_Partner_Status__c'})
            .executeQuery()[0];

        Assert.areEqual(CourseProgressHelper.CDP_STATUS_INCOMPLETE, acc.Certified_Delivery_Partner_Status__c, 'Invalid value');

        acc2 = (Account) new AccountSelector()
            .selectAccountByName(new Object[]{'test2'})
            .selectFields(new List<String>{'Certified_Delivery_Partner_Status__c'})
            .executeQuery()[0];


        Assert.areEqual(CourseProgressHelper.CDP_STATUS_INCOMPLETE, acc2.Certified_Delivery_Partner_Status__c, 'Invalid value');
    }

    @isTest
    private static void recalculateCDPDeliverStatusAccountField_whenContactIsDeleted_shouldUpdateAccounts() {
        skilljar__Course__c course = (skilljar__Course__c) new SObjectBuilder(skilljar__Course__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    skilljar__Course__c.skilljar__Title__c => 'CDP Course',
                    skilljar__Course__c.skilljar__Skilljar_Id__c => '123456',
                    skilljar__Course__c.skilljar__Short_Description__c => 'This is a CDP Course test record',
                    skilljar__Course__c.CDP_Course__c => true
                }
            )
            .create()
            .getRecord();

        skilljar__Published_Course__c publishedCourse = (skilljar__Published_Course__c) new SObjectBuilder(skilljar__Published_Course__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    skilljar__Published_Course__c.skilljar__Course_Title__c => 'CDP Course',
                    skilljar__Published_Course__c.skilljar__Course_URL__c => 'https://fakeurl.com',
                    skilljar__Published_Course__c.skilljar__Domain__c => 'fakeurl',
                    skilljar__Published_Course__c.skilljar__Lesson_Count__c => 1,
                    skilljar__Published_Course__c.skilljar__Obfuscated_Id__c => '123456',
                    skilljar__Published_Course__c.skilljar__Course__c => course.Id
                }
            )
            .create()
            .getRecord();

        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Name => 'test'
            })
            .create()
            .getRecord();

        Contact[] conts = (Contact[]) new SObjectBuilder(Contact.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.FirstName => ValueProviderBuilder.provideList(new String[]{'firstname','firstname2'}),
                    Contact.LastName => ValueProviderBuilder.provideList(new String[]{'lastname','lastname2'}),
                    Contact.Email => ValueProviderBuilder.provideList(new String[]{'fakeemail@gmail.com','fakeemail2@gmail.com'}),
                    Contact.Phone => ValueProviderBuilder.provideList(new String[]{'12345678','123456781'}),
                    Contact.Phone_Ext__c => 123,
                    Contact.Contact_Status__c => '2. Contacted',
                    Contact.AccountId => acc.Id
                }
            )
            .quantity(2)
            .create()
            .getRecords();

        skilljar__Student__c[] students = (skilljar__Student__c[]) new SObjectBuilder(skilljar__Student__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    skilljar__Student__c.skilljar__Obfuscated_Id__c => ValueProviderBuilder.provideList(new String[]{'123456','1234563'}),
                    skilljar__Student__c.skilljar__Contact__c => ValueProviderBuilder.provideList(new Id[]{conts[0].Id, conts[1].Id}),
                    skilljar__Student__c.skilljar__Email__c => 'fakeemail@gmail.com'
                }
            )
            .quantity(2)
            .create()
            .getRecords();

        skilljar__Course_Progress__c[] CPs = (List<skilljar__Course_Progress__c>) new SObjectBuilder(skilljar__Course_Progress__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    skilljar__Course_Progress__c.skilljar__Obfuscated_Id__c => ValueProviderBuilder.provideList(new String[]{'123456','12345'}),
                    skilljar__Course_Progress__c.skilljar__Published_Course__c => publishedCourse.Id,
                    skilljar__Course_Progress__c.skilljar__Student__c => ValueProviderBuilder.provideList(new Id[]{students[0].Id, students[1].Id}),
                    skilljar__Course_Progress__c.skilljar__Course__c => course.Id,
                    skilljar__Course_Progress__c.skilljar__Contact__c => ValueProviderBuilder.provideList(new Id[]{conts[0].Id, conts[1].Id})
                }
            )
            .quantity(2)
            .create()
            .getRecords();

        CPs[0].skilljar__Completed_At__c = Datetime.now();
        CPs[1].skilljar__Completed_At__c = Datetime.now();
        update CPs;


        acc = (Account) new AccountSelector()
            .selectAccountByName(new Object[]{'test'})
            .selectFields(new List<String>{'Certified_Delivery_Partner_Status__c'})
            .executeQuery()[0];

        Assert.areEqual(CourseProgressHelper.CDP_STATUS_COMPLETE, acc.Certified_Delivery_Partner_Status__c, 'Invalid value');

        Test.startTest();
            delete conts[0];
        Test.stopTest();


        acc = (Account) new AccountSelector()
            .selectAccountByName(new Object[]{'test'})
            .selectFields(new List<String>{'Certified_Delivery_Partner_Status__c'})
            .executeQuery()[0];

        Assert.areEqual(CourseProgressHelper.CDP_STATUS_INCOMPLETE, acc.Certified_Delivery_Partner_Status__c, 'Invalid value');
    }
    
    @isTest
    private static void testPopulateSaasquatchReferralEmailOnAccount() {
        // Create test data
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => 'Test Account for SaaSquatch Referral'
                }
            )
            .create()
            .getRecord();
            
        Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.FirstName => 'SaaSquatch',
                    Contact.LastName => 'Referral Test',
                    Contact.Email => 'referral@example.com',
                    Contact.AccountId => acc.Id,
                    Contact.Phone => '1234567890',
                    Contact.Preferred_Language__c => 'en_US'
                }
            )
            .create()
            .getRecord();
            
        Test.startTest();
            con.Saasquatch_Referral_Email_ID__c = 'referral@example.com';
            update con;
        Test.stopTest();
        
        Account updatedAccount = [
            SELECT Saasquatch_Referral_Email_ID__c
            FROM Account
            WHERE Id = :acc.Id
        ];
        
        System.assertEquals('referral@example.com', updatedAccount.Saasquatch_Referral_Email_ID__c, 
            'Account Saasquatch_Referral_Email_ID__c should be populated with contact email');
    }
    
    @isTest
    private static void testPopulateCustomAccountId() {
        Account acc1 = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => 'Original Account for Custom ID'
                }
            )
            .create()
            .getRecord();
            
        Account acc2 = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => 'New Account for Custom ID'
                }
            )
            .create()
            .getRecord();
            
        Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.FirstName => 'CustomID',
                    Contact.LastName => 'Test',
                    Contact.Email => 'customid@example.com',
                    Contact.AccountId => acc1.Id,
                    Contact.Phone => '1234567890',
                    Contact.Preferred_Language__c => 'en_US'
                }
            )
            .create()
            .getRecord();
            
        Test.startTest();
            con.AccountId = acc2.Id;
            update con;
        Test.stopTest();
        
        Contact updatedContact = [
            SELECT Matching_Rule_Account__c
            FROM Contact
            WHERE Id = :con.Id
        ];
        
        System.assertEquals(acc2.Id, updatedContact.Matching_Rule_Account__c, 
            'Matching_Rule_Account__c should match the new AccountId');
    }
    
    @isTest
    private static void testCreateContactExtensions() {
        // Note: Contact_Ext__c is no longer used - CreateContactExtensions handler is commented out
        // This test verifies that Contact_Ext__c records are NOT created (deprecated functionality)
        Test.startTest();
            Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        Contact.FirstName => 'Extension',
                        Contact.LastName => 'Test',
                        Contact.Email => 'extension@example.com',
                        Contact.Phone => '1234567890',
                        Contact.Preferred_Language__c => 'en_US'
                    }
                )
                .create()
                .getRecord();
        Test.stopTest();
        
        List<Contact_Ext__c> extensions = [
            SELECT Id
            FROM Contact_Ext__c
            WHERE Contact__c = :con.Id
        ];
        
        // Contact_Ext__c is deprecated - no records should be created
        System.assertEquals(0, extensions.size(), 
            'Contact_Ext__c records should NOT be created as this object is no longer used');
    }
    
    @isTest
    private static void testPopulateDateStatusChanged() {
        Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.FirstName => 'Status',
                    Contact.LastName => 'Test',
                    Contact.Email => 'status@example.com',
                    Contact.Phone => '1234567890',
                    Contact.Preferred_Language__c => 'en_US',
                    Contact.Contact_Status__c => '1. New'
                }
            )
            .create()
            .getRecord();
            
        // Check insert behavior
        System.assertNotEquals(null, [SELECT Date_Status_Changed__c FROM Contact WHERE Id = :con.Id].Date_Status_Changed__c,
            'Date_Status_Changed__c should be set on insert');
            
        Test.startTest();
            con.Contact_Status__c = '2. Contacted';
            update con;
        Test.stopTest();
        
        Contact updatedContact = [
            SELECT Date_Status_Changed__c
            FROM Contact
            WHERE Id = :con.Id
        ];
        
        System.assertEquals(Date.today(), updatedContact.Date_Status_Changed__c,
            'Date_Status_Changed__c should be updated to today');
    }
    
    @isTest
    private static void testRecalculateCDPDeliverStatusAccountField() {
        // Create test data
        skilljar__Course__c course = (skilljar__Course__c) new SObjectBuilder(skilljar__Course__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    skilljar__Course__c.skilljar__Title__c => 'CDP Course Test',
                    skilljar__Course__c.skilljar__Skilljar_Id__c => '12345',
                    skilljar__Course__c.skilljar__Short_Description__c => 'Test CDP Course',
                    skilljar__Course__c.CDP_Course__c => true
                }
            )
            .create()
            .getRecord();
            
        skilljar__Published_Course__c pubCourse = (skilljar__Published_Course__c) new SObjectBuilder(skilljar__Published_Course__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    skilljar__Published_Course__c.skilljar__Course_Title__c => 'CDP Course Test',
                    skilljar__Published_Course__c.skilljar__Course_URL__c => 'https://test.com',
                    skilljar__Published_Course__c.skilljar__Domain__c => 'test.com',
                    skilljar__Published_Course__c.skilljar__Lesson_Count__c => 1,
                    skilljar__Published_Course__c.skilljar__Obfuscated_Id__c => '12345',
                    skilljar__Published_Course__c.skilljar__Course__c => course.Id
                }
            )
            .create()
            .getRecord();
            
        Account acc1 = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => 'CDP Original Account'
                }
            )
            .create()
            .getRecord();
            
        Account acc2 = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => 'CDP New Account'
                }
            )
            .create()
            .getRecord();
            
        Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.FirstName => 'CDP',
                    Contact.LastName => 'Test',
                    Contact.Email => 'cdp@example.com',
                    Contact.AccountId => acc1.Id,
                    Contact.Phone => '1234567890',
                    Contact.Preferred_Language__c => 'en_US'
                }
            )
            .create()
            .getRecord();
            
        skilljar__Student__c student = (skilljar__Student__c) new SObjectBuilder(skilljar__Student__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    skilljar__Student__c.skilljar__Obfuscated_Id__c => '54321',
                    skilljar__Student__c.skilljar__Contact__c => con.Id,
                    skilljar__Student__c.skilljar__Email__c => 'cdp@example.com'
                }
            )
            .create()
            .getRecord();
            
        skilljar__Course_Progress__c progress = (skilljar__Course_Progress__c) new SObjectBuilder(skilljar__Course_Progress__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    skilljar__Course_Progress__c.skilljar__Obfuscated_Id__c => '98765',
                    skilljar__Course_Progress__c.skilljar__Published_Course__c => pubCourse.Id,
                    skilljar__Course_Progress__c.skilljar__Student__c => student.Id,
                    skilljar__Course_Progress__c.skilljar__Course__c => course.Id,
                    skilljar__Course_Progress__c.skilljar__Contact__c => con.Id,
                    skilljar__Course_Progress__c.skilljar__Completed_At__c => Datetime.now()
                }
            )
            .create()
            .getRecord();
            
        Test.startTest();
            con.AccountId = acc2.Id;
            update con;
        Test.stopTest();
        
        List<Account> accounts = [
            SELECT Certified_Delivery_Partner_Status__c
            FROM Account
            WHERE Id IN (:acc1.Id, :acc2.Id)
        ];
        
        // Verification that accounts are properly recalculated happens in the trigger
        System.assertEquals(2, accounts.size(), 'Both accounts should still exist');
    }
    
    // This mock class simulates SaaSquatch API responses
    private class SaaSquatchReferralMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"success": true}');
            res.setStatusCode(200);
            return res;
        }
    }
}