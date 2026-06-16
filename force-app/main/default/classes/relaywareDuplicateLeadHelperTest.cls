/*
* Name         : relaywareDuplicateLeadHelperTest.cls
* Created By   : Golovanov Fedor (fgolovanov@newmarketinc.com)
* Created Date : 15/September/2016
* Description  : Unit tests for the relaywareDuplicateLeadHelper class.
* Dependencies : relaywareDuplicateLeadHelper.cls
*/

@isTest
private class relaywareDuplicateLeadHelperTest {

    private static User apiUser =  createUser('aU'); //relayware User
    private static User nonApiUser =  createUser('naU'); //relayware User
    private static Account testAccount = null; //account that exists on the org in the tests
    private static Contact testContact = null; //contact that exists on the org in the tests
    private static Lead testLead = null; //lead that exists on the org in the tests
    private static Case testCase = null; //case that exists on the org in the tests


    private static User createUser(String name){
        User user = new User(
            Username = name+'!user@gmail.com',
            LastName = 'Test'+name,
            Email = name+'_user@gmail.com',
            Alias = 'test'+name,
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = [SELECT Id, Name FROM Profile WHERE Name = 'System Administrator'].Id,
            LanguageLocaleKey = 'en_US'
        );
        insert user;
        return user;
    }

    private static void createEmailSettings(){
        List<Emails__c> settings = new List<Emails__c>();
        Map<String, String> emailTestSettings = new Map<String, String>{'duplicateleadreplyto' => 'replayto@email.com',
                                                                        'partnersuk' => 'partnersuk@email.com'};
        for(String sName : emailTestSettings.keySet()){
            Emails__c temp = new Emails__c(Name = sName,
                                           Email_Address__c = emailTestSettings.get(sName),
                                           Description__c = 'For Unit Testing'
                                           );
            settings.add(temp);
        }

        upsert settings;
    }

    private static void createRelaywareSettings(String userName, Boolean allowOutboundEmails, String AdditionalEmails){
        Relayware_Duplicate_Settings__c settings = Relayware_Duplicate_Settings__c.getOrgDefaults();
        settings.Users__c = userName;
        settings.Send_Email_Copy_To__c = AdditionalEmails;
        settings.Allow_Outbound_Emails__c = allowOutboundEmails;
        upsert settings;
    }

    public static Account createAccount(String name){
        Account acc = new Account();
        acc.Name = name;
        insert acc;
        return acc;
    }

    public static Contact createContact(Id accId, String lastName, String cEmail){
        Contact con = new Contact();
        con.LastName = lastName;
        con.AccountId = accId;
        con.Email = cEmail;
        insert con;
        return con;
    }

    public static Case createCase(String cStatus, Id rType, String pEmail){
        Case newCase = new Case(
            AccountId = testAccount.Id,
            ContactId = testContact.Id,
            Case_Severity__c = 'Level 1 - Critical',
            Origin =  'Phone',
            Subject = 'Duplicate Lead Ring Central Russia from Partner Ring Central Russia without account attached',
            Description = 'Ring Central Russia submitted a Lead which was found to already exist in SFDC. Please verify if this is a valid Lead or not.',
            Partner_Lead_Email__c = pEmail,
            Status = cStatus,
            RecordTypeId = rType
        );
        insert newCase;
        return newCase;
    }

    public static Lead createLead(String LeadEmail){
        Lead newLead = new Lead(
            FirstName = 'Fedor',
            LastName = 'Golovanov',
            Company='Fedor Industries',
            Email = LeadEmail,
            Phone='9910106804',
            LeadSource = 'Inbound Call',
            Notes__c = 'Test Notes',
            Website = 'http://test.com',
            NumberOfEmployees = 999,
            Industry = 'Other',
            NumberOfEmployees__c = '50-249',
            Number_of_Locations__c = '50+',
            Agent_Email_Address__c = 'test@test.com',
            Partner_Contact__c = testContact.Id,
            Partner_Account__c = testAccount.Id,
            Eligible_Protection_Period__c = system.today(),
            Status = '2. Contacted',
            Country__c='USA',
            Zip_Code__c = '100',
            LS_Primary_NAIC__c='1',
            Employees_Override__c='50-249'
        );

        insert newLead;
        return newLead;
    }

    public static void CreateTestData(Boolean isExistingCaseNeeded, String caseStatus, String leadEmail, String contactEmail, String caseEmail){

        //Create settings for the test
        //Realyware settings to idetify API User and Email settings for the recipients email adresses
        createRelaywareSettings(apiUser.LastName, true, 'additional@email.com');
        createEmailSettings();
        //Create account
        testAccount = createAccount('Ring Central Russia');
        //Create contact
        testContact = createContact(testAccount.Id, 'Golovanov', contactEmail);
        //Create case if needed
        if(isExistingCaseNeeded) {
            testCase = createCase(caseStatus, Schema.SObjectType.Case.getRecordTypeInfosByName().get('Partner Lead').getRecordTypeId(), caseEmail);
        }
        //Create Lead
        testLead = createLead(leadEmail);

    }

    //Verify that 2 duplicate leads can be created under non api user
    @isTest static void testDuplicationExists() {
        System.runAs(nonApiUser){
            Test.startTest();
                CreateTestData(true, 'New', 'fgolovanov@aquivalabs1.com', 'fgolovanov@aquivalabs2.com', 'fgolovanov@aquivalabs3.com');
            Test.stopTest();
            createLead('fgolovanov@aquivalabs1.com');
            System.assertEquals([SELECT Count() FROM Lead WHERE Email = 'fgolovanov@aquivalabs1.com'], 2);
        }
    }

    //Verify that 2 duplicate leads can not be created under api user
    @isTest static void testDuplicationDontExists() {
        System.runAs(apiUser){
            Test.startTest();
                CreateTestData(true, 'New', 'fgolovanov@aquivalabs1.com', 'fgolovanov@aquivalabs2.com', 'fgolovanov@aquivalabs3.com');
                System.assertEquals(Relayware_Duplicate_Settings__c.getOrgDefaults().Users__c, UserInfo.getName());
            Test.stopTest();

            try{
                createLead('fgolovanov@aquivalabs1.com');
            }catch(Exception ex) {
                ExceptionHelper.checkIsMassEmailException(ex);
                return;
            }

            //System.assertEquals([SELECT Count() FROM Lead WHERE Email = 'fgolovanov@aquivalabs1.com'], 1);
        }
    }

    //Verify that 2 duplicate leads can not be created under api user and new case was created as well as outbound message
    @isTest static void testDuplicationDontExistsAndCaseCreated() {
        System.runAs(apiUser){
            Test.startTest();
                CreateTestData(false, 'New', 'fgolovanov@aquivalabs1.com', 'fgolovanov@aquivalabs2.com', 'fgolovanov@aquivalabs3.com');
                System.assertEquals(Relayware_Duplicate_Settings__c.getOrgDefaults().Users__c, UserInfo.getName());
            Test.stopTest();

            try{
                createLead('fgolovanov@aquivalabs1.com');
            }catch(Exception ex) {
                ExceptionHelper.checkIsMassEmailException(ex);
                return;
            }

            //System.assertEquals([SELECT Count() FROM Lead WHERE Email = 'fgolovanov@aquivalabs1.com'], 1);
            //System.assertEquals([SELECT Count() FROM Case], 1);
        }
    }
}