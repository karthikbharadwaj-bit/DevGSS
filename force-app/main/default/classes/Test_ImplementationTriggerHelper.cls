@isTest
public class Test_ImplementationTriggerHelper {
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    //Is used to test  ProfessionalServices__c population when implementation record is inserted 
    //for case when a corresponding quote with ProServ_Status__c = 'Sold' exists
    public static void test_ProfessionalServicesCheckBoxPopulation() {
        Triggers.switchOff();
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator']; 
        Profile p2 = [SELECT Id FROM Profile WHERE Name='Sales Operations Lightning']; 
       
        
        User u2 = new User(Alias = 'standt', Email='standarduser@testorg.com', 
                EmailEncodingKey='UTF-8', LastName='James Drabbant', LanguageLocaleKey='en_US', 
                LocaleSidKey='en_US', ProfileId = p2.Id,
                TimeZoneSidKey='America/Los_Angeles', UserName='standarduser655@testorg.com');
        insert u2;
        
         User u = new User(Alias = 'standt', Email='standarduser@testorg.com', 
                EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                LocaleSidKey='en_US', ProfileId = p.Id,
                TimeZoneSidKey='America/Los_Angeles', UserName='standarduser555@testorg.com');
        insert u;

        
       // PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'ProfessionalServicesManager'];
       
        //insert new PermissionSetAssignment(AssigneeId = u2.id, PermissionSetId = ps.Id);
        Account testAcc = new Account(
            Name = 'testAccount',
            RC_User_ID__c = '62329416005',
            Partner_ID__c = '66163'
        );
        insert testAcc;
       
        Contact c = new Contact(lastName='lastTest', AccountId = testAcc.Id, email='rcpartnersync@ringcentral.com.box1');
            insert c;
        
        Network_Information__c objNetwork = new Network_Information__c(Account__c=testAcc.id);
        insert objNetwork;
        
        Lead_Qualification__c leadQualObj1 = new Lead_Qualification__c();
       leadQualObj1.Account__c = testAcc.id;
        insert leadQualObj1;
        
       
        RCSF_Sync__c rcsfSyncObj = new RCSF_Sync__c(Is_Primary__c = true, Id__c = u.Id, Name = 'RCSFSync');
        insert rcsfSyncObj;
        
        Event eve = new Event();
        eve.CustomerId__c = '62329416005';
        eve.Type = 'Initial Implementation';
        eve.DurationInMinutes = 60;
        eve.ActivityDateTime = Date.today();
        insert eve;
        system.debug('Event from TC-->' +eve);
        system.debug('Event parentid from TC-->' + eve.IsChild);
        EventRelation er = new EventRelation(EventId = eve.id, 
                                             RelationId = u.id);
        insert er;
        
        Opportunity testOpp = new Opportunity(
            Name = 'MyTestOpportunity',
            Type = 'Existing Business',
            Brand_Name__c = 'RingCentral',
            Tier_Name__c = 'Professional',
            StageName = '1. Qualify',
            CloseDate = System.today(),
            CurrencyIsoCode = 'USD'
        );
        testOpp.AccountId = testAcc.Id;
        insert testOpp;
        //Prepare proserv quote
        Quote proservTestQuote = new Quote (Name='proservTestQuote',
                                            OpportunityId = testOpp.Id,
                                            Pricebook2Id = Test.getStandardPricebookId(), 
                                            RecordTypeId = QuoteHelper.RT_ID_PROSERV,
                                            ProServ_Status__c = 'Sold');
        insert (new List<Quote>{proservTestQuote});
        Triggers.switchOn();
        Test.startTest();
        //insert 
       system.runAs(u2){
           
           Account Acc2 = new Account();
                Acc2.Name = 'Testacc';
                Acc2.RC_User_ID__c = '12345';
                insert Acc2;
                Contact c2 = new Contact ();
                c2.Email = 'TEstemail@gmail.com';
                c2.FirstName = 'Test_';
                c2.LastName = 'implementation';
                c2.AccountId = Acc2.id;
                insert c2;
                  Network_Information__c objNetwork2 = new Network_Information__c(Account__c=Acc2.id);
        insert objNetwork2;
        
        Implementation__c testImp1 = new Implementation__c (
            Name = 'testImp1',
            Brand__c = 'RingCentral EU',
            Most_Recent_follow_up_Date__c = system.today(),
            Account__c = Acc2.id,
            Implementation_Status__c = '1. New',
            Implementation_Status_2__c = 'New',
            Contact__c = c2.id,
            isBypassValidation__c = false
            
        );
        
      /*  Implementation__c testImp2 = new Implementation__c (
            Name = 'testImp2',
            Brand__c = 'RingCentral EU',
            Most_Recent_follow_up_Date__c = system.today(),
            Account__c = testAcc.id,
            Implementation_Status_2__c = 'Work in Progress',
            WIP_Status__c = false
            
        );
                                       
        /*Implementation__c testImp3 = new Implementation__c (
            Name = 'testImp3',
            Brand__c = 'RingCentral EU',
            Most_Recent_follow_up_Date__c = system.today(),
            Account__c = testAcc.id,
            Implementation_Status_2__c = 'Completed'
            
        );*/
        insert testImp1;
        testImp1.Implementation_Status__c = '6a. Completed';
        testImp1.Implementation_Status_2__c = 'Completed';
        testImp1.Brand__c = 'RingCentral';
        system.debug('Updating imp');
        TriggerHandler.BY_PASS_IMPLEMENTATION_ON_BEFORE = false;
        
        update testImp1;
            
        
         testImp1.Brand__c = 'Rogers';
        
        //update testImp1;
        }
        
        Test.stopTest();
        /*List <Implementation__c> impListAfterInsert = [SELECT Id, ProfessionalServices__c FROM Implementation__c];
        for(Implementation__c impRecord : impListAfterInsert) {
            System.assertEquals(impRecord.ProfessionalServices__c, true);
        }*/
    }
   
   @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    public static void test_event() {
        List<Profile> profilesList = (List<Profile>) new ProfileSelector()
            .selectProfilesByNames(new List<Object>{new Set<String>{ProfileHelper.PROFILE_NAME_SALES_OPERATIONS_LIGHTNING, ProfileHelper.PROFILE_NAME_SYSTEM_ADMINISTRATOR}})
            .executeQuery();
        
        List<User> usersList = (List<User>) new SObjectBuilder(User.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    User.Alias => ValueProviderBuilder.provideList(new List<String>{'standt1', 'standt2'}),
                    User.Email => 'standarduser@testorg.com',
                    User.EmailEncodingKey => 'UTF-8',
                    User.LastName => ValueProviderBuilder.provideList(new List<String>{'Testing', 'Booking Bug'}),
                    User.LanguageLocaleKey => 'en_US',
                    User.LocaleSidKey => 'en_US',
                    User.ProfileId => ValueProviderBuilder.provideList(new List<Id>{profilesList[1].Id, profilesList[0].Id}),
                    User.TimeZoneSidKey => 'America/Los_Angeles',
                    User.UserName => ValueProviderBuilder.provideList(new List<String>{'standarduser555@testorg.com', 'BookingBug@testorg.com'})
                }
            )
            .quantity(2)
            .create()
            .getrecords();       
        
        Account testAcc = new Account(
            Name = 'testAccount',
            RC_User_ID__c = '62329416005',
            Partner_ID__c = '66163'
        );
        insert testAcc;
        
        Contact c = new Contact(lastName='lastTest', AccountId = testAcc.Id, email='rcpartnersync@ringcentral.com.box1');
        insert c;
        
        Network_Information__c objNetwork = new Network_Information__c(Account__c=testAcc.id);
        insert objNetwork;
        
        Lead_Qualification__c leadQualObj1 = new Lead_Qualification__c();
        leadQualObj1.Account__c = testAcc.id;
        insert leadQualObj1;
       
        RCSF_Sync__c rcsfSyncObj = new RCSF_Sync__c(Is_Primary__c = true, Id__c = usersList[1].Id, Name = 'RCSFSync');
        insert rcsfSyncObj;
        
        Lead testLead = new Lead(Email='fake@email.com', LastName='Test', Company='Test Co.');
        insert testLead;
        
        Opportunity testOpp = new Opportunity(
            Name = 'MyTestOpportunity',
            Type = 'Existing Business',
            Brand_Name__c = 'RingCentral',
            Tier_Name__c = 'Professional',
            StageName = '1. Qualify',
            CloseDate = System.today(),
            CurrencyIsoCode = 'USD',
            AccountId = testAcc.Id
        );
        insert testOpp;
        
        /*Event eve = new Event();
        eve.CustomerId__c = '62329416005';
        eve.Type = 'Initial Implementation';
        eve.DurationInMinutes = 60;
        eve.ActivityDateTime = Date.today();
        eve.WhatId = testOpp.id;
        eve.WhoId = c.id;
        eve.Appointment_Source__c='Calendar';
        system.runAs(usersList[1]) {
            insert eve;  
        }
        
        system.debug('Event from TC-->' +eve);
        system.debug('Event parentid from TC-->' + eve.IsChild);
        EventRelation er = new EventRelation(EventId = eve.id, 
                                             RelationId = usersList[0].id);
        insert er;
        
        //Prepare proserv quote
        Quote proservTestQuote = new Quote (Name='proservTestQuote',
                                            OpportunityId = testOpp.Id,
                                            Pricebook2Id = Test.getStandardPricebookId(), 
                                            RecordTypeId = QuoteHelper.RT_ID_PROSERV,
                                            ProServ_Status__c = 'Sold');
        insert proservTestQuote;*/
        
        Test.startTest();
        //insert 
            system.runAs(usersList[1]) {
                Account Acc1 = new Account();
                Acc1.Name = 'Testacc';
                Acc1.RC_User_ID__c = '12345';
                insert Acc1;
                Contact c1 = new Contact ();
                c1.Email = 'TEstemail@gmail.com';
                c1.FirstName = 'Test_';
                c1.LastName = 'implementation';
                c1.AccountId = Acc1.id;
                insert c1;
                  Network_Information__c objNetwork1 = new Network_Information__c(Account__c=Acc1.id);
        insert objNetwork1;
        
                
                Implementation__c testImp1 = new Implementation__c (
                    Name = 'testImp1',
                    Brand__c = 'RingCentral EU',
                    Most_Recent_follow_up_Date__c = system.today(),
                    Account__c = Acc1.id,
                    Implementation_Status__c = '1. New',
                    Implementation_Status_2__c = 'New',
                    Contact__c = c1.id,
                    isBypassValidation__c = false
                );
                insert testImp1;
        
                testImp1.Implementation_Status__c = '6a. Completed';
                testImp1.Implementation_Status_2__c = 'Completed';
                testImp1.Brand__c = 'RingCentral';
                TriggerHandler.BY_PASS_IMPLEMENTATION_ON_BEFORE = false;
                update testImp1;
                Test.stopTest();
                testImp1.Brand__c = 'Rogers';
                Event eve1 = new Event();
                eve1.CustomerId__c = '62329416005';
                eve1.Type = 'Follow-Up Implementation 1';
                eve1.DurationInMinutes = 60;
                eve1.ActivityDateTime = Date.today();
                eve1.WhatId = testImp1.id;
                eve1.WhoId = c1.id;
                eve1.Appointment_Source__c='Calendar';

                Event eve2 = new Event();
                eve2.CustomerId__c = '62329416005';
                eve2.Type = 'Follow-Up Implementation 2';
                eve2.DurationInMinutes = 60;
                eve2.ActivityDateTime = Date.today();
                eve2.WhatId = testImp1.id;
                eve2.WhoId = c1.id;
                eve2.Appointment_Source__c='Calendar';
                insert new List<Event>{eve1,eve2};

                eve1.Implementation_Status__c='Scheduled';
                update eve1;
           }
        
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    public static void test_event2() {
        List<Profile> profilesList = (List<Profile>) new ProfileSelector()
            .selectProfilesByNames(new List<Object>{new Set<String>{ProfileHelper.PROFILE_NAME_SYSTEM_ADMINISTRATOR, ProfileHelper.PROFILE_NAME_SALES_OPERATIONS_LIGHTNING}})
            .executeQuery();
        
        List<User> usersList = (List<User>) new SObjectBuilder(User.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    User.Alias => ValueProviderBuilder.provideList(new List<String>{'standt1', 'standt2'}),
                    User.Email => 'standarduser@testorg.com',
                    User.EmailEncodingKey => 'UTF-8',
                    User.LastName => ValueProviderBuilder.provideList(new List<String>{ 'Booking Bug','Testing'}),
                    User.LanguageLocaleKey => 'en_US',
                    User.LocaleSidKey => 'en_US',
                    User.ProfileId => ValueProviderBuilder.provideList(new List<Id>{profilesList[0].Id, profilesList[1].Id}),
                    User.TimeZoneSidKey => 'America/Los_Angeles',
                    User.UserName => ValueProviderBuilder.provideList(new List<String>{'standarduser555@testorg.com', 'BookingBug@testorg.com'})
                }
            )
            .quantity(2)
            .create()
            .getrecords();
        
        Account testAcc = new Account(
            Name = 'testAccount',
            RC_User_ID__c = '62329416005',
            Partner_ID__c = '66163'
        );
        insert testAcc;
        
        Contact c = new Contact(lastName='lastTest', AccountId = testAcc.Id, email='rcpartnersync@ringcentral.com.box1');
        insert c;
        
        Network_Information__c objNetwork = new Network_Information__c(Account__c=testAcc.id);
        insert objNetwork;
        
        Lead_Qualification__c leadQualObj1 = new Lead_Qualification__c();
        leadQualObj1.Account__c = testAcc.id;
        insert leadQualObj1;
       
        RCSF_Sync__c rcsfSyncObj = new RCSF_Sync__c(Is_Primary__c = true, Id__c = usersList[1].Id, Name = 'RCSFSync');
        insert rcsfSyncObj;
        
        Lead testLead = new Lead(Email='fake@email.com', LastName='Test', Company='Test Co.');
        insert testLead;
        
        Opportunity testOpp = new Opportunity(
            Name = 'MyTestOpportunity',
            Type = 'Existing Business',
            Brand_Name__c = 'RingCentral',
            Tier_Name__c = 'Professional',
            StageName = '1. Qualify',
            CloseDate = System.today(),
            CurrencyIsoCode = 'USD',
            AccountId = testAcc.Id
        );
        insert testOpp;
        Test.startTest();
        //insert 
        system.runAs(usersList[1]) {
            Account Acc1 = new Account();
            Acc1.Name = 'Testacc';
            Acc1.RC_User_ID__c = '12345';
            insert Acc1;
            Contact c1 = new Contact ();
            c1.Email = 'TEstemail@gmail.com';
            c1.FirstName = 'Test_';
            c1.LastName = 'implementation';
            c1.AccountId = Acc1.id;
            insert c1;

            Network_Information__c objNetwork1 = new Network_Information__c(Account__c=Acc1.id);
            insert objNetwork1;

            Implementation__c testImp1 = new Implementation__c (
                Name = 'testImp1',
                Brand__c = 'RingCentral EU',
                Most_Recent_follow_up_Date__c = system.today(),
                Account__c = testAcc.id,
                Implementation_Status__c = '1. New',
                Implementation_Status_2__c = 'New',
                Contact__c = c1.id,
                isBypassValidation__c = false
            );
            insert testImp1;

            testImp1.Implementation_Status__c = '6a. Completed';
            testImp1.Implementation_Status_2__c = 'Completed';
            testImp1.Brand__c = 'RingCentral';
            TriggerHandler.BY_PASS_IMPLEMENTATION_ON_BEFORE = false;
            update testImp1;

            Test.stopTest();

            testImp1.Brand__c = 'Rogers';

            Event eve1 = new Event();
            eve1.CustomerId__c = '62329416005';
            eve1.Type = 'Initial Implementation';
            eve1.DurationInMinutes = 60;
            eve1.ActivityDateTime = Date.today();
            eve1.WhatId = testOpp.id;
            eve1.Appointment_Source__c='Calendar';
            eve1.RecordTypeId = Schema.SObjectType.Event.getRecordTypeInfosByName().get('SE Event').getRecordTypeId();

            Event eve2 = new Event();
            eve2.CustomerId__c = '62329416005';
            eve2.Type = 'Follow-Up Implementation 2';
            eve2.DurationInMinutes = 60;
            eve2.ActivityDateTime = Date.today();
            eve2.WhatId = testOpp.id;
            eve2.Appointment_Source__c='Calendar';
            eve2.RecordTypeId = Schema.SObjectType.Event.getRecordTypeInfosByName().get('SE Event').getRecordTypeId();

            insert new List<Event>{eve1,eve2};

            eve1.Implementation_Status__c='Scheduled';
            update eve1;
        }
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    public static void test_ProfessionalServicesCheckBoxPopulationRogers() {
        Triggers.switchOff();
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator']; 
        Profile p2 = [SELECT Id FROM Profile WHERE Name='Sales Operations Lightning']; 
        User u = new User(Alias = 'standt', Email='standarduser@testorg.com', 
                EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                LocaleSidKey='en_US', ProfileId = p.Id,
                TimeZoneSidKey='America/Los_Angeles', UserName='standarduser555@testorg.com');
        insert u;
        
        User u2 = new User(Alias = 'standt', Email='standarduser@testorg.com', 
                EmailEncodingKey='UTF-8', LastName='James Drabbant', LanguageLocaleKey='en_US', 
                LocaleSidKey='en_US', ProfileId = p2.Id,
                TimeZoneSidKey='America/Los_Angeles', UserName='standarduser655@testorg.com');
        insert u2;
        
         //PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'ProfessionalServicesManager'];
       
        //insert new PermissionSetAssignment(AssigneeId = u2.id, PermissionSetId = ps.Id);
        
        Account testAcc = new Account(
            Name = 'testAccount',
            RC_User_ID__c = '62329416005',
            Partner_ID__c = '66163'
        );
        insert testAcc;
        
        Contact c = new Contact(lastName='lastTest', AccountId = testAcc.Id, email='rcpartnersync@ringcentral.com.box1');
            insert c;
        
        Network_Information__c objNetwork = new Network_Information__c(Account__c=testAcc.id);
        insert objNetwork;
        
        Lead_Qualification__c leadQualObj1 = new Lead_Qualification__c();
       leadQualObj1.Account__c = testAcc.id;
        insert leadQualObj1;
        
       
        
        RCSF_Sync__c rcsfSyncObj = new RCSF_Sync__c(Is_Primary__c = true, Id__c = u.Id, Name = 'RCSFSync');
        insert rcsfSyncObj;
        
        Event eve = new Event();
        eve.CustomerId__c = '62329416005';
        eve.Type = 'Initial Implementation';
        eve.DurationInMinutes = 60;
        eve.ActivityDateTime = Date.today();
        insert eve;
        system.debug('Event from TC-->' +eve);
        system.debug('Event parentid from TC-->' + eve.IsChild);
        EventRelation er = new EventRelation(EventId = eve.id, 
                                             RelationId = u.id);
        insert er;
        
        Opportunity testOpp = new Opportunity(
            Name = 'MyTestOpportunity',
            Type = 'Existing Business',
            Brand_Name__c = 'RingCentral',
            Tier_Name__c = 'Professional',
            StageName = '1. Qualify',
            CloseDate = System.today(),
            CurrencyIsoCode = 'USD'
        );
        testOpp.AccountId = testAcc.Id;
        insert testOpp;
        //Prepare proserv quote
        Quote proservTestQuote = new Quote (Name='proservTestQuote',
                                            OpportunityId = testOpp.Id,
                                            Pricebook2Id = Test.getStandardPricebookId(), 
                                            RecordTypeId = QuoteHelper.RT_ID_PROSERV,
                                            ProServ_Status__c = 'Sold');
        insert (new List<Quote>{proservTestQuote});
        Triggers.switchOn();
        Test.startTest();
        //insert 
       system.runAs(u2){
            Account Acc3 = new Account();
                Acc3.Name = 'Testacc';
                Acc3.RC_User_ID__c = '12345';
                insert Acc3;
                Contact c3 = new Contact ();
                c3.Email = 'TEstemail@gmail.com';
                c3.FirstName = 'Test_';
                c3.LastName = 'implementation';
                c3.AccountId = Acc3.id;
                insert c3;
                  Network_Information__c objNetwork3 = new Network_Information__c(Account__c=Acc3.id);
        insert objNetwork3;
        
        Implementation__c testImp1 = new Implementation__c (
            Name = 'testImp1',
            Brand__c = 'RingCentral EU',
            Most_Recent_follow_up_Date__c = system.today(),
            Account__c = Acc3.id,
            Implementation_Status__c = '1. New',
            Implementation_Status_2__c = 'New',
            Contact__c = c3.id,
            isBypassValidation__c = false
            
        );
        
       
        insert testImp1;
        
        testImp1.Implementation_Status__c = '6a. Completed';
        testImp1.Implementation_Status_2__c = 'Completed';
        testImp1.Brand__c = 'Rogers';
        system.debug('Updating imp');
        TriggerHandler.BY_PASS_IMPLEMENTATION_ON_BEFORE = false;
        
        update testImp1;
            
             }
        
        Test.stopTest();
       
    }
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    public static void test_ProfessionalServicesCheckBoxPopulationATandT() {
        Triggers.switchOff();
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator']; 
        Profile p2 = [SELECT Id FROM Profile WHERE Name='Sales Operations Lightning']; 
        User u = new User(Alias = 'standt', Email='standarduser@testorg.com', 
                EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                LocaleSidKey='en_US', ProfileId = p.Id,
                TimeZoneSidKey='America/Los_Angeles', UserName='standarduser555@testorg.com');
        insert u;
        
        User u2 = new User(Alias = 'standt', Email='standarduser@testorg.com', 
                EmailEncodingKey='UTF-8', LastName='James Drabbant', LanguageLocaleKey='en_US', 
                LocaleSidKey='en_US', ProfileId = p2.Id,
                TimeZoneSidKey='America/Los_Angeles', UserName='standarduser655@testorg.com');
        insert u2;
        
         //PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'ProfessionalServicesManager'];
       
        //insert new PermissionSetAssignment(AssigneeId = u2.id, PermissionSetId = ps.Id);
        
        Account testAcc = new Account(
            Name = 'testAccount',
            RC_User_ID__c = '62329416005',
            Partner_ID__c = '66163'
        );
        insert testAcc;
        
        Contact c = new Contact(lastName='lastTest', AccountId = testAcc.Id, email='rcpartnersync@ringcentral.com.box1');
            insert c;
        
        Network_Information__c objNetwork = new Network_Information__c(Account__c=testAcc.id);
        insert objNetwork;
        
        Lead_Qualification__c leadQualObj1 = new Lead_Qualification__c();
       leadQualObj1.Account__c = testAcc.id;
        insert leadQualObj1;
        
       
        RCSF_Sync__c rcsfSyncObj = new RCSF_Sync__c(Is_Primary__c = true, Id__c = u.Id, Name = 'RCSFSync');
        insert rcsfSyncObj;
        
        Event eve = new Event();
        eve.CustomerId__c = '62329416005';
        eve.Type = 'Initial Implementation';
        eve.DurationInMinutes = 60;
        eve.ActivityDateTime = Date.today();
        insert eve;
        system.debug('Event from TC-->' +eve);
        system.debug('Event parentid from TC-->' + eve.IsChild);
        EventRelation er = new EventRelation(EventId = eve.id, 
                                             RelationId = u.id);
        insert er;
        
        Opportunity testOpp = new Opportunity(
            Name = 'MyTestOpportunity',
            Type = 'Existing Business',
            Brand_Name__c = 'RingCentral',
            Tier_Name__c = 'Professional',
            StageName = '1. Qualify',
            CloseDate = System.today(),
            CurrencyIsoCode = 'USD'
        );
        testOpp.AccountId = testAcc.Id;
        insert testOpp;
        //Prepare proserv quote
        Quote proservTestQuote = new Quote (Name='proservTestQuote',
                                            OpportunityId = testOpp.Id,
                                            Pricebook2Id = Test.getStandardPricebookId(), 
                                            RecordTypeId = QuoteHelper.RT_ID_PROSERV,
                                            ProServ_Status__c = 'Sold');
        insert (new List<Quote>{proservTestQuote});
        Triggers.switchOn();
        //insert 
       // system.runAs(u2){
                   Test.startTest();

               Implementation__c testImp1 = new Implementation__c (
            Name = 'testImp1',
            Brand__c = 'AT&T Office@Hand',
            Most_Recent_follow_up_Date__c = system.today(),
            Account__c = testAcc.id,
            Implementation_Status__c = '1. New',
            Implementation_Status_2__c = 'New',
            Contact__c = c.id,
            isBypassValidation__c = false
            
        );
        
     
        insert testImp1;

         testImp1.Implementation_Status__c = '6a. Completed';
        testImp1.Implementation_Status_2__c = 'Completed';
        testImp1.Brand__c = 'AT&T Office@Hand';
        system.debug('Updating imp');
        TriggerHandler.BY_PASS_IMPLEMENTATION_ON_BEFORE = false;
        
        update testImp1;
        
        Survey__c surveyObj = new Survey__c();
        surveyObj.SurveyType__c = 'ATT Implementation';
        surveyObj.Account__c = testAcc.id;
        surveyObj.Implementation__c = testImp1.Id;
        
        insert surveyObj;


        //}
        
        Test.stopTest();
       
    }
    
    @IsTest
    static void testPopulateImplemantationFieldsWithPackageFields() {
        Triggers.switchOff();
        Triggers.except('ImplementationTriggerHelper.PopulateImplemantationFieldsWithPackageFields');
        Account testAcc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Name => 'TestAcc1'
            })
            .create()
            .getRecord();

            
        Package__c testPackage = (Package__c) new SObjectBuilder(Package__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Package__c.Account_Package_Id__c => '1111',
                Package__c.Account__c => testAcc.Id,
                Package__c.RC_Brand__c => 'RingCentral',
                Package__c.Service_Version__c => '1',
                Package__c.Enterprise_Account_ID__c => testAcc.Id,
                Package__c.Package_Name__c => 'RingCX IVR Only (USD)',
                Package__c.Service_Type__c => QuoteHelper.NGBS_OFFICE_PRODUCT
            })
            .create()
            .getRecord();
    
        Test.startTest();
            Implementation__c implRecord = (Implementation__c) new SObjectBuilder(Implementation__c.SObjectType)
                .setFields(new Map<SObjectField, Object>{
                    Implementation__c.Account__c => testAcc.Id
                })
                .create()
                .getRecord();

        Test.stopTest();
        Triggers.switchOn();
        Implementation__c result = (Implementation__c) new ImplementationSelector()
            .selectImplementations()
            .setCondition('Id IN :bind0')
            .selectFields(new List<String>{'Service_Version_Name__c'})
            .setQueryBindings(new List<Object>{ new Set<Id>{implRecord.Id}})
            .executeQuery()
            .get(0);

        Package__c resultPackage = (Package__c) new PackageSelector()
            .selectPackagesForNewReferences(new List<Object> {new Set<Id>{testAcc.Id}})
            .executeQuery()
            .get(0);

        Assert.areEqual(result.Service_Version_Name__c, resultPackage.Service_Version_Label__c, 'Service Version Name should be populated with Service Version Label');
    }
}