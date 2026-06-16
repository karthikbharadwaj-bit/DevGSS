@isTest
private class Test_DifferentProfiles {
    
    private static Account testAccount;
    private static Contact testContact;
    private static Opportunity testOpportunity;
    private static User testUser;
    private static User testUser2;
    private static User testManager;
    private static Profile prof;
    private final static String TEST_COMMENT = 'This is test comment string';
    private final static String SYSTEM_ADMINISTRATOR = 'System Administrator';
    private static final String PROFILE_NAME_CHANNEL_SALES_MANAGER_LIGHTNING = 'Channel Sales Manager - Lightning';  
    private static final String PROFILE_NAME_CRM_DEV_TEAM_ADMINISTRATOR = 'CRM Dev Team Administrator';
    // Add this line of code
    private static final String PROFILE_NAME_SALES_REP = 'Sales Operations Lightning'; 
    private static final String PROFILE_NAME_CRM_QA_ENGINEER = 'CRM QA Engineer';
    private static final String PROFILE_NAME_CRM_DEVELOPER = 'CRM Developer';
    
    private final static String TEST_STRING = 'TestString';
    private final static String TEST_PACKAGE = '{"id":"1","version":"5","duration":"Monthly","categoryCode":"ATN","discount":{"type":"Percent","value":"3.48"},"price":"40"}';
    private final static String NEW_BUSINESS = 'New Business';
    private static id Testroleid;
    private static final String FAKE_PRIVATE_KEY = 'MIIEowIBAAKCAQEA7FBikJgR5gXkwHOvAhptmhmOTiQL+VWxNSOJrPlvCCubEk5Nm6JQv1YAoIDfASXO3JYXNPjsAlb4J+XnitsRNwNVZTBJT1DvQysBVUHfVDXPRiTzHklK7OWYdu+eRnxYdvHBVAd7eKEjNvmG6kRjUDP4d393REzu9PSJEGJlDO0i2ZIxiOMswCDmux5H2d4ahXl1jsTyI8J2sVE6g2nI6nduZuIJK1GsxAWmmjezK4j1vMTx4+2UaF6uuwTwzJ56e7/ECQCJDJENzp6Fm3UhqYY12AqW+AE81bbw6lJ3wIoKRT0ZQGnXuOrYypgRUtnrSgZ2RBtVBa43tWZmpScoXwIDAQABAoIBADpVtZ8gCvsPZWKkrAUG5RtvR5O+jj4kizQk662JfYE00nj4X2wV63zwDAOTDHnKDYCihGQNNqV1NpkSxc+fOGauKfxqqQ4tWoLoMNINCsZM6jfUkzdcvGQyYSqrCBU6SNRD5YeKuU4T6Q9/FXDrJOD9k05cZuKzYyGQ4+zpfSxtO++l3lIzrBVeVreBQMZ+p7WA+2gEvz6cxSOFL0mglAfiPIAHTM/zTXYeLweeeWvZSh7V9Y+MTbUP3INPaLWGQB/qDM3+s5L8Ztj1rtYOnWSUXruqQELXu/Jc4z59IUzym4MvdRurg+5+U2NatiNd5QNPA11ry7GEDe1HV1jzvbECgYEA/+ciRd56DJiK75VZOHl3icjd6pOTnPEJD09E/eilrFUyc8hAZhFJV32H6wzOkpOAqkrs7GAaIJwnezxDPmwkYRemH6LlLnNdDFpN/lmcH8DuGqN3GdaXm9WCarztB2CBMiWn5QLSA62+AvnuW9EbkWNufeCkL0Zf5nyHTuKwDR0CgYEA7GdZAgolTLLMXekqG4Bv9ipyUqnrHiQSLiCYRBeehPNavyYmo9dpcC9s6M/hDnRanIZRm0fa9vTr8vpoAZvFHDyZzgv7PPMFM3fZyeFUibj3wdTDJtdLE4BdtExXjIJHb8B3KmFYaYRBiOpsOaK4XRwcHw4wBFaGDt31ZQoJHqsCgYAQ0EzuLknyneszBqsQDNsP0ITULtIaE7Q2r0ynKiwIgKiJ9vRUQHqDJxpRFUxVUR+5EKc0eLP+xIPLkxAP/+b8AiPGHFvWi3nnn99UAOtDItgCJA9lQTZA5OxmuvcP7wVOGC9J2r+Vwkqjw2wn2DtpeBEAcEwZVxRh/niddEOA+QKBgFrK7mJcJysn2FmQ/T0GvPlcIAAjhktTKzBQEGrGb3k8RXP4YQq35qTRchCQFi2I/mvzIlBy7mO+eQgep+dGPhO0KpX6AAnOhAbaVui0A9XJFk55OmImeY0J1fMzBsTOHEWNM7cxH9WWl9zPu7T/C7Om4h4DQunHmUEIegDOM+Z1AoGBAL+U92I27aHif9PS2ZTwZnG5aMDocA0282vUJHPUQY1KThdwRVoFWiVPJhPJcmEpYdimARSpV5rrrzQBUEGKx6Z3OL2ptzz7WmPgOh839SR7CXcZ8Hqcu6h94pYoSDH4b/iNfniRJuABmbstoTCNK9QciDDeCq8wIes6mocheXtU====';

    @testSetup static void setup(){

        Triggers.switchOff();
        Profile testProfile = [ SELECT Id
                                FROM Profile
                                WHERE Name = 'Sales Rep - Lightning' LIMIT 1];

        User testSetupUser = new User(IsTmtTriggersDisabled__c = false,
                                        Phone = '+18885550505',
                                        IsActive = true,
                                        Mkto_Reply_Email__c = 'testSetup@opptyTriggerSetup.com',
                                        FirstName = 'TestSetup',
                                        Lastname = 'TestSetup',
                                        Email = 'testSetup@opptyTriggerSetup.com',
                                        ProfileId = testProfile.Id,
                                        Username = 'testSetup@opptyTriggerSetup.com',
                                        Alias = 'ssal',
                                        TimeZoneSidKey = 'America/Los_Angeles',
                                        LocaleSidKey = 'en_US',
                                        EmailEncodingKey = 'ISO-8859-1',
                                        LanguageLocaleKey = 'en_US');

        User testSetupManager = new User(IsTmtTriggersDisabled__c = false,
                                        Phone = '+18885550505',
                                        IsActive = true,
                                        Mkto_Reply_Email__c = 'manager@test.com',
                                        FirstName = 'manager',
                                        Lastname = 'managerson',
                                        Email = 'manager@test.com',
                                        ProfileId = testProfile.Id,
                                        Username = 'manager+1@optytriggertest.com',
                                        Alias = 'sman',
                                        TimeZoneSidKey = 'America/Los_Angeles',
                                        LocaleSidKey = 'en_US',
                                        EmailEncodingKey = 'ISO-8859-1',
                                        LanguageLocaleKey = 'en_US');

        insert new List<User>{testSetupUser, testSetupManager};
      
      

        Employee__c testSetupEmployee = new Employee__c(
            First_Name__c = 'TestFirst',
            Last_Name__c = 'TestLast',
            Email__c = 'testSetup@opptyTriggerSetup.com',
            Location__c = 'Denver, US',
            Department__c = 'Sales',
            Division__c = 'Sales - SOHO',
            User__c = testSetupUser.Id
        );
        insert testSetupEmployee;

        Account testSetupAccount = new Account(Name = 'Test Account',
                                                Partner_ID__c = 'testIDAcc',
                                                Permitted_Brands__c = 'RingCentral');
        insert testSetupAccount;

        Contact testSetupContact = new Contact(LastName = 'Test Contact',
                                                Preferred_Language__c = 'en_US',
                                                AccountId = testSetupAccount.Id,
                                                Email = 'test@domaintest.com',
                                                Phone = '+18885550505',
                                                CurrencyIsoCode = 'USD');
        insert testSetupContact;

        Triggers.switchOn();

        Opportunity testSetupOpportunity = new Opportunity(Name = 'Test Oppty',
                                                            CurrencyIsoCode = 'USD',
                                                            AccountId = testSetupAccount.Id,
                                                            StageName = '4. Proof',
                                                            RecordTypeId = OpportunityHelper.RT_ID_SALES_OPPORTUNITY,
                                                            Primary_Opportunity_Contact__c = testSetupContact.Id,
                                                            OwnerId = testSetupUser.Id,
                                                            Tier_Name__c = 'Fax1000',
                                                            Brand_Name__c = 'RingCentral',
                                                            Forecasted_Users__c = 23);
        insert testSetupOpportunity;

        Feature_Toggle__c featureToggle = (Feature_Toggle__c) new SObjectBuilder(Feature_Toggle__c.sObjectType)
                .setField(Feature_Toggle__c.ProvisioningFlow__c, true)
                .create()
                .getRecord();

        NGBS_Phoenix_Settings__c phoenixSettings = (NGBS_Phoenix_Settings__c) new SObjectBuilder(NGBS_Phoenix_Settings__c.sObjectType)
                .setFields(new Map<SObjectField, Object>{
                    NGBS_Phoenix_Settings__c.NGBSPhoenixAvailableBrands__c => 'RingCentral;RingCentral Canada;RingCentral AU;RingCentral UK;RingCentral EU; Unify Office;',
                    NGBS_Phoenix_Settings__c.NGBSPhoenixAvailablePackageIDs__c => '666;210;260;220;230;231;240;241;250;251;510;900;901;902',
                    NGBS_Phoenix_Settings__c.NGBSPhoenixAvailableProducts__c => 'RC Meetings;Meetings;'
                })
                .create()
                .getRecord();
        
        

        
    }


    public static void createTestData(Boolean dataSelector){

        testAccount = new Account(Name='Opty test account',
                                    Partner_ID__c='testID',
                                    Permitted_Brands__c='RingCentral');
        insert testAccount;

        testContact = new Contact(LastName='Opty test contact',
                                    Preferred_Language__c='en_US',
                                    AccountId=testAccount.Id,
                                    Email='test@test.com',
                                    Phone='+18885550505',
                                    CurrencyIsoCode='USD');
        insert testContact;

        Set<String> profNames = new Set<String>();
        profNames.add('Quoting Wizard Beta Tester');
        profNames.add('Sales Rep - Lightning');

        prof = [SELECT Id FROM Profile WHERE Name IN :profNames LIMIT 1];

        List<User> users = new List<User>();

        testManager = new User(IsTmtTriggersDisabled__c=false,
                            Phone='+18885550505',
                            IsActive=true,
                            Mkto_Reply_Email__c='manager@test.com',
                            FirstName='manager',
                            Lastname='managerson',
                            Email='manager@test.com',
                            ProfileId=prof.Id,
                            Username='manager@optytriggertest.com',
                            Alias='sman',
                            TimeZoneSidKey='America/Los_Angeles',
                            LocaleSidKey='en_US',
                            EmailEncodingKey='ISO-8859-1',
                            LanguageLocaleKey='en_US');

        insert testManager;

        testUser = new User(IsTmtTriggersDisabled__c=false,
                            ManagerId=testManager.Id,
                            Phone='+18885550505',
                            IsActive=true,
                            Mkto_Reply_Email__c='sales@optytriggertest.com',
                            FirstName='sales',
                            Lastname='salesson',
                            Email='sales@optytriggertest.com',
                            ProfileId=prof.Id,
                            Username='sales@optytriggertest.com',
                            Alias='ssal',
                            TimeZoneSidKey='America/Los_Angeles',
                            LocaleSidKey='en_US',
                            EmailEncodingKey='ISO-8859-1',
                            LanguageLocaleKey='en_US');

        users.add(testUser);

        testUser2 = new User(IsTmtTriggersDisabled__c=false,
                            ManagerId=testManager.Id,
                            Phone='+18885550505',
                            IsActive=true,
                            Mkto_Reply_Email__c='sales2@optytriggertest.com',
                            FirstName='sales2',
                            Lastname='salesson2',
                            Email='sales2@optytriggertest.com',
                            ProfileId=prof.Id,
                            Username='sales2@optytriggertest.com',
                            Alias='ssal2',
                            TimeZoneSidKey='America/Los_Angeles',
                            LocaleSidKey='en_US',
                            EmailEncodingKey='ISO-8859-1',
                            LanguageLocaleKey='en_US');

        users.add(testUser2);
        
         

        try{
            insert users;
        }catch(Exception e){}


        List<Employee__c> empls = new List<Employee__c>();
        Employee__c empl;
        for (User usr : users){
            empl = new Employee__c(First_Name__c=usr.FirstName,
                                    Last_Name__c=usr.LastName,
                                    Email__c=usr.Email,
                                    Location__c='San Mateo, US',
                                    Department__c='Sales',
                                    Division__c='Sales - Fax',
                                    Team__c='Sales - Customer Success Manager US',
                                    SPID__c=usr.Alias,
                                    User__c=usr.Id);
            empls.add(empl);
        }

        insert empls;
    // }

        testOpportunity = new Opportunity(Name='Test Opportunity',
                                            CurrencyIsoCode='USD',
                                            AccountId=testAccount.Id,
                                            StageName='4. Proof',
                                            RecordTypeId=OpportunityHelper.RT_ID_SALES_OPPORTUNITY,
                                            Primary_Opportunity_Contact__c = testContact.Id,
                                            OwnerId=testUser.Id,
                                            Tier_Name__c='Fax1000',
                                            Brand_Name__c='RingCentral',
                                            Forecasted_Users__c=23);
        if (dataSelector) {
            insert testOpportunity;
        }
    }
	
    //Add below methods to the test class 
    
    @isTest
    private static void testOwnerNamePopulationOnInsert_CRMSupport() {
        Profile prof = [
                        SELECT Id
                        FROM Profile
                        WHERE Name =: PROFILE_NAME_SALES_REP
                        LIMIT 1
                        ];
        User us = [
                    SELECT Id, Name
                    FROM User
                    WHERE IsActive = true
                    AND ProfileId =: prof.Id
                    LIMIT 1
                    ];
        System.runAs(us) {
            Account acc = (Account) new SObjectBuilder(Account.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        Account.Name => 'testAcc'
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
                        Contact.Preferred_Language__c => 'en_US'
                    }
                )
                .create()
                .getRecord();

            Opportunity opp = new Opportunity();
            Test.startTest();
            try {	
                opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
                    .setFields(
                        new Map<SObjectField, Object>{
                            Opportunity.Name => 'Test Opportunity 2016',
                            Opportunity.Type => 'Syndicated - New',
                            Opportunity.StageName => 'Planning',
                            Opportunity.CloseDate => system.today().addMonths(1),
                            Opportunity.AccountId => acc.Id,
                            Opportunity.Primary_Opportunity_Contact__c => con.Id,
                            Opportunity.EstimatedProfessionalServices12Month__c => 10
                        }
                    )
                    .create()
                    .getRecord();
                
            }
            catch(Exception ex){
                System.assertnotEquals(ex.getMessage(),'This user does not have access privilege to Employee object.');
            }
                
            Test.stopTest();

        }
    }

    @isTest
    private static void testOwnerNamePopulationOnUpdate_CMRSupport() {
        Profile prof = [
                        SELECT Id
                        FROM Profile
                        WHERE Name =: PROFILE_NAME_SALES_REP
                        LIMIT 1
                        ];
        User us = [
                    SELECT Id, Name
                    FROM User
                    WHERE IsActive = true
                    AND ProfileId =: prof.Id
                    LIMIT 1
                    ];
        Opportunity testSetupOpportunity = [Select id,Name from Opportunity];
        System.runAs(us) {
            Account acc = (Account) new SObjectBuilder(Account.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        Account.Name => 'testAcc'
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
                        Contact.Preferred_Language__c => 'en_US'
                    }
                )
                .create()
                .getRecord();

            Test.startTest();
            try{
                update testSetupOpportunity;
            }
            catch(Exception ex){
                System.assertnotEquals(ex.getMessage(),'This user does not have access privilege to Employee object.');
            }    
            
            Test.stopTest();

        }
    }
    
}