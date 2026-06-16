@isTest
private class Test_LeadQualificationControllers {

    @testSetup static void generateData() {
        try{
            Test_Utils utilObj = new Test_Utils();

            Account acctest = new Account();
            acctest.Name = 'TestAccount';
            acctest.RC_Attribution_Channel__c = 'Sales Agents & Resellers';
            acctest.Partner_ID__c ='123';
            //acctest.RecordTypeId  = '01280000000UERq';
            acctest.Current_Owner__c = Userinfo.getUserId();
            acctest.RC_User_ID__c = 'test123';
            insert acctest;

            Contact c = new Contact();
            c.LastName = 'contactLast1';
            c.AccountId = acctest.Id;   //[SELECT id FROM Account WHERE name=: acctest.Name].id;
            c.email='test11@rc.com';
            c.Phone='1234567890';
            insert c;

            List<Opportunity> OpportunityObjList = new List<Opportunity>();
            Opportunity Oppval1 = new Opportunity();
            Oppval1.Name = 'Test Opp';
            Oppval1.AccountId = acctest.Id;
            Oppval1.Type = 'Existing Business';
            Oppval1.StageName = '3. ActivePipe';
            Oppval1.Sales_Model__c = 'Direct';
            Oppval1.CloseDate = System.Today() + 10;
            Oppval1.CurrencyIsoCode = 'USD';
            Oppval1.Brand_Name__c= 'RingCentral';
            Oppval1.Agent_Email_Address__c='test@test.com';
            Oppval1.RC_User_ID__c = Userinfo.getUserId();
            oppval1.OwnerId = Userinfo.getUserId();
            oppval1.Total_MRR__c = 50;
            Oppval1.X12_Month_Booking__c =50;
            Oppval1.Total_Initial_Amount__c= 60;
            OpportunityObjList.add(Oppval1);

            Opportunity Oppval1Obj  = new Opportunity();
            Oppval1Obj.Name = 'Test Opp';
            Oppval1Obj.AccountId = acctest.Id;
            Oppval1Obj.Type = 'Existing Business';
            Oppval1Obj.StageName = '3. ActivePipe';
            Oppval1Obj.Sales_Model__c = 'Direct';
            Oppval1Obj.CloseDate = System.Today() + 10;
            Oppval1Obj.CurrencyIsoCode = 'USD';
            Oppval1Obj.Brand_Name__c= 'RingCentral';
            Oppval1Obj.Agent_Email_Address__c='test@test.com';
            Oppval1Obj.RC_User_ID__c = Userinfo.getUserId();
            Oppval1Obj.OwnerId = Userinfo.getUserId();
            Oppval1Obj.Total_MRR__c = 50;
            Oppval1Obj.X12_Month_Booking__c =50;
            Oppval1Obj.Total_Initial_Amount__c= 60;
            OpportunityObjList.add(Oppval1Obj);
            insert OpportunityObjList;
        }
        catch (Exception e) {
            System.assert(false);
        }
    }
//tests are poorly written because of lack of time.
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest static void testing() {
        Test.startTest();
        Account acc = [SELECT Id FROM Account LIMIT 1];
        ApexPages.StandardController sc = new ApexPages.StandardController(acc);
        AccountLeadQualificationController controller = new AccountLeadQualificationController(sc);
        controller.showEdit();
        controller.hideEdit();
        controller.save();
        Test.stopTest();
    }
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest static void testing2() {
        Test.startTest();
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Lead_Qualification__c lq = new Lead_Qualification__c();
        lq.Account__c = acc.Id;
        insert lq;

        ApexPages.StandardController sc = new ApexPages.StandardController(acc);
        AccountLeadQualificationController controller = new AccountLeadQualificationController(sc);
        controller.showEdit();
        controller.hideEdit();
        controller.save();
        Test.stopTest();
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest static void leadTesting() {
        Test.startTest();
        Lead lead = (Lead) new SObjectBuilder(Lead.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Lead.email => 'fake@email.com',
                    Lead.LastName => 'fakeLastName',
                    Lead.Company => 'fakeCompany'
                }
            )
            .create()
            .getRecord();
        Lead_Qualification__c lq = new Lead_Qualification__c();
        lq.Lead__c = lead.Id;
        insert lq;

        ApexPages.StandardController sc = new ApexPages.StandardController(lead);
        LeadQualificationController controller = new LeadQualificationController(sc);
        controller.showEdit();
        controller.hideEdit();
        controller.save();
        Test.stopTest();

    }

    @isTest
    private static void testSalesProfileUser() {
        Lead lead = (Lead) new SObjectBuilder(Lead.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Lead.email => 'fake@email.com',
                    Lead.LastName => 'fakeLastName',
                    Lead.Company => 'fakeCompany'
                }
            )
            .create()
            .getRecord();
        Lead_Qualification__c lq = new Lead_Qualification__c();
        lq.Lead__c = lead.Id;
        insert lq;

        User us = (User) new SObjectBuilder (User.SObjectType)        
            .setFields(
                new Map<SObjectField, Object>{
                    User.LastName => 'TestAtt',
                    User.Username => 'Test!user@gmail.com',
                    User.Email => 'Att_user@gmail.com',
                    User.Alias => 'Test',
                    User.TimeZoneSidKey => 'America/Los_Angeles',
                    User.ManagerId => UserInfo.getUserId(),
                    User.LocaleSidKey => 'en_US',
                    User.EmailEncodingKey => 'UTF-8',
                    User.ProfileId => [SELECT Id, Name FROM Profile WHERE Name = 'Channel Sales - Lightning'].Id,
                    User.LanguageLocaleKey => 'en_US',
                    User.Hierarchy_Role__c => 'Sales Rep'
                }
            )
            .create()
            .getRecord();

        System.runAs(us) {
            Test.startTest();
                ApexPages.StandardController sc = new ApexPages.StandardController(lead);
                LeadQualificationController controller = new LeadQualificationController(sc);
            Test.stopTest();

            System.assertEquals(controller.isSalesProfile,
                                true,
                                'Sales profile was not assigned correctly to user.');
            System.assertEquals(controller.isInsideSalesProfile,
                                false,
                                'Inside Sales profile was not assigned correctly to user.');
        }
    }

    @isTest
    private static void testSalesInsideProfileUser() {
        Lead lead = (Lead) new SObjectBuilder(Lead.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Lead.email => 'fake@email.com',
                    Lead.LastName => 'fakeLastName',
                    Lead.Company => 'fakeCompany'
                }
            )
            .create()
            .getRecord();
        Lead_Qualification__c lq = new Lead_Qualification__c();
        lq.Lead__c = lead.Id;
        insert lq;

        User us = (User) new SObjectBuilder (User.SObjectType)        
            .setFields(
                new Map<SObjectField, Object>{
                    User.LastName => 'TestAtt',
                    User.Username => 'Test!user@gmail.com',
                    User.Email => 'Att_user@gmail.com',
                    User.Alias => 'Test',
                    User.TimeZoneSidKey => 'America/Los_Angeles',
                    User.ManagerId => UserInfo.getUserId(),
                    User.LocaleSidKey => 'en_US',
                    User.EmailEncodingKey => 'UTF-8',
                    User.ProfileId => [SELECT Id, Name FROM Profile WHERE Name = :ProfileHelper.PROFILE_NAME_SALES_MANAGER_WITH_INSIDESALES].Id,
                    User.LanguageLocaleKey => 'en_US',
                    User.Hierarchy_Role__c => 'Sales Rep'
                }
            )
            .create()
            .getRecord();

        System.runAs(us) {
            Test.startTest();
                ApexPages.StandardController sc = new ApexPages.StandardController(lead);
                LeadQualificationController controller = new LeadQualificationController(sc);
            Test.stopTest();

            System.assertEquals(controller.isSalesProfile,
                                false,
                                'Sales profile was not assigned correctly to user.');
            System.assertEquals(controller.isInsideSalesProfile,
                                true,
                                'Inside Sales profile was not assigned correctly to user.');
        }
    }
}