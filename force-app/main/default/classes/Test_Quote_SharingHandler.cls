@isTest
private class Test_Quote_SharingHandler {

    @isTest
    private static void testHandleDealSupportShareFuture() {
       // setupData();
       PartnerRecordsUtil util = new PartnerRecordsUtil();
        System.runAs(PartnerRecordsUtil.runAsSysAdmin){
            Deal_Support__c rec = PartnerRecordsUtil.createDealSupport();
            Deal_Support__c rec1=[SELECT id, Portal_Cloud_Specialist__c,CreatedById,OwnerId,Partner_Account__c, Partner_Contact__c
                                                    from Deal_Support__c where Id=:rec.Id];

            List<User_Account_Mapping__c> listUAM = new List<User_Account_Mapping__c>();
            User_Account_Mapping__c userObj=new User_Account_Mapping__c();
            userObj.Name='Test User';
            userObj.Partner_Account__c=rec1.Partner_Account__c;
            userObj.Partner_Contact__c=rec1.Partner_Contact__c;
            userObj.Partner_User__c=PartnerRecordsUtil.runAsAvayaMasterRole.Id;
            listUAM.add(userObj);
            User_Account_Mapping__c userObj1=new User_Account_Mapping__c();
            userObj.Name='Test User 1';
            userObj1.Partner_Account__c=rec1.Partner_Account__c;
            userObj1.Partner_Contact__c=rec1.Partner_Contact__c;
            userObj1.Partner_User__c=PartnerRecordsUtil.runAsAvayaAdmin.Id;
            listUAM.add(userObj1);
            insert listUAM;

            Test.startTest();
            Quote_SharingHandler.handleDealSupportShareFuture(new Set<Id>{rec.Id});
            Quote_SharingHandler.PartnerDealSupprtAndRegsWrapper.dealSupportSharingWithDealRegOwners(new Set<Id>{rec.Id});
            Test.stopTest();
            System.assertEquals(rec1.Portal_Cloud_Specialist__c, rec.Portal_Cloud_Specialist__c);
            //List<Deal_Support__share> result = [SELECT Id FROM Deal_Support__share];
            //System.assertNotEquals(null, result, 'share record must exist');
        }
    }

    @isTest
    private static void testHandleDealRegistrationShareFuture() {
        //setupData();
         PartnerRecordsUtil util = new PartnerRecordsUtil();
        System.runAs(PartnerRecordsUtil.runAsAvayaAdmin){
            Deal_Registration__c rec = PartnerRecordsUtil.createAvayaDeal();
            List<User_Account_Mapping__c> listUAM = new List<User_Account_Mapping__c>();
            User_Account_Mapping__c userObj=new User_Account_Mapping__c();
            userObj.Name='Test User 2';
            userObj.Partner_Account__c=rec.Partner_Account__c;
            userObj.Partner_Contact__c=rec.Partner_Contact__c;
            userObj.Partner_User__c=PartnerRecordsUtil.runAsAvayaMasterRole.Id;
            listUAM.add(userObj);
            User_Account_Mapping__c userObj1=new User_Account_Mapping__c();
            userObj.Name='Test User 3';
            userObj1.Partner_Account__c=rec.Partner_Account__c;
            userObj1.Partner_Contact__c=rec.Partner_Contact__c;
            userObj1.Partner_User__c=PartnerRecordsUtil.runAsAvayaAdmin.Id;
            listUAM.add(userObj1);

            Test.startTest();
            insert listUAM;
            Quote_SharingHandler.handleDealRegistrationShare(new Set<Id>{rec.Id});
            Test.stopTest();
            List<Deal_Registration__Share> result = [SELECT Id FROM Deal_Registration__Share];
            System.assertNotEquals(null, result, 'share record must exist');
        }
    }


    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest static void testPartnerQuoteSharing() {
        //setupData();
        //Quote_TestDataFactory factory = new Quote_TestDataFactory();
        //factory.createUsersWithAyavaE2ECustomerProfile(1);
        List<Account> accList = Quote_TestDataFactory.generateAccounts(1);
            insert accList;

        Opportunity opp = new Opportunity();
        opp.Name = 'test';
        opp.AccountId = accList[0].Id;
        opp.StageName = '5. Agreement';
        insert opp;
        List<Partner_Quote__c> quoteList = Quote_TestDataFactory.generateQuotes(1);
        quoteList[0].Opportunity__c  = opp.Id;
        insert quoteList;
        List<Partner_Quote_Line__c> quoteLineList = Quote_TestDataFactory.generateQuoteLines(2,quoteList[0].Id);
        insert quoteLineList;
        Set<Id> accIDSet = new Set<Id>();
        accIDSet.add(accList[0].Id);
        Test.startTest();
        Quote_SharingHandler.handlePartnerQuoteSharing(quoteList[0].id);
        Test.stopTest();
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest static void testPartnerQuoteSharingFuture() {
        //setupData();
        //Quote_TestDataFactory factory = new Quote_TestDataFactory();
        //factory.createUsersWithAyavaE2ECustomerProfile(1);
        List<Account> accList = Quote_TestDataFactory.generateAccounts(1);
            insert accList;

        Opportunity opp = new Opportunity();
        opp.Name = 'test';
        opp.AccountId = accList[0].Id;
        opp.StageName = '5. Agreement';
        insert opp;
        List<Partner_Quote__c> quoteList = Quote_TestDataFactory.generateQuotes(1);
        quoteList[0].Opportunity__c  = opp.Id;
        insert quoteList;
        List<Partner_Quote_Line__c> quoteLineList = Quote_TestDataFactory.generateQuoteLines(2,quoteList[0].Id);
        insert quoteLineList;
        Set<Id> accIDSet = new Set<Id>();
        accIDSet.add(accList[0].Id);
        Test.startTest();
        Quote_SharingHandler.handlePartnerQuoteSharingFuture(quoteList[0].id);
        Test.stopTest();
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest static void testPartnerQuoteSharingForAccount() {
        //setupData();
        //Quote_TestDataFactory factory = new Quote_TestDataFactory();
        //factory.createUsersWithAyavaE2ECustomerProfile(1);
        List<Account> accList = Quote_TestDataFactory.generateAccounts(1);
            insert accList;

        Opportunity opp = new Opportunity();
        opp.Name = 'test';
        opp.AccountId = accList[0].Id;
        opp.StageName = '5. Agreement';
        insert opp;
        List<Partner_Quote__c> quoteList = Quote_TestDataFactory.generateQuotes(1);
        quoteList[0].Opportunity__c  = opp.Id;
        insert quoteList;
        List<Partner_Quote_Line__c> quoteLineList = Quote_TestDataFactory.generateQuoteLines(2,quoteList[0].Id);
        insert quoteLineList;
        Set<Id> accIDSet = new Set<Id>();
        accIDSet.add(accList[0].Id);
        Test.startTest();
        Quote_SharingHandler.handlePartnerQuoteSharingForAccount(accIDSet);
        Test.stopTest();
    }
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
     @isTest static void testHandleAccountChangeRequestSharingFuture() {
           List<Account> accList = Quote_TestDataFactory.generateAccounts(1);
            insert accList;
         Account_Change_Request__c acr=new Account_Change_Request__c();
         acr.Account__c=accList[0].id;
         insert acr;
         Test.startTest();
         Quote_SharingHandler.handleAccountChangeRequestSharingFuture(acr.Id);
         Test.stopTest();
     }
@isTest
private static void testHandleDealSupportShareFuture10() {

    PartnerRecordsUtil objutil = new PartnerRecordsUtil();
    system.runAs(PartnerRecordsUtil.runAsAvayaAdmin){   
        Test.startTest();

        Account partnerAccount = new Account(Name = 'Partner Account');
        insert partnerAccount;

        Contact partnerContact = new Contact(LastName = 'Partner Contact', AccountId = partnerAccount.Id);
        insert partnerContact;

        Deal_Registration__c dealObj = new Deal_Registration__c(
            First_Name__c = 'Test Deal Registration',
            Address__c = '123 Test Street',
            City__c = 'Test City',
            Company_Name__c = 'Test Company',
            Competitor_s__c = 'Avaya',
            Description__c = 'Test Description',
            Email_Address__c = 'test@example.com',
            Estimated_Close_Date__c = Date.today().addMonths(1),
            Existing_Solution_Provider__c = 'Avaya',
            How_did_you_acquire_this_Lead__c = 'Test Source',
            Industry__c = 'Banking',
            Last_Name__c = 'Test Last Name',
            Number_of_Employees__c = '100',
            Partner_Contact__c = PartnerRecordsUtil.partnerContact.Id,
            Phone_Number__c = '123-456-7890',
            Website__c = 'www.testsite.com',
            Whats_prompting_change__c = 'Other',
            Partner_Account__c = PartnerRecordsUtil.partnerAccount.Id
        );
        insert dealObj;

        Lead leadObj = new Lead(
            LastName = 'Test Lead',
            Company = 'Test Company',
            Status = 'Open - Not Contacted',
            Deal_Registration__c = dealObj.Id,
            email='virendra.singh@simplion.com'
        );
        insert leadObj;

        Deal_Support__c dealSupTmp = new Deal_Support__c();
        dealSupTmp.Type__c = 'Lead Conversion';
        dealSupTmp.Partner_Account__c = PartnerRecordsUtil.partnerAccount.Id;
        dealSupTmp.Partner_Contact__c = PartnerRecordsUtil.partnerContact.Id;
        dealSupTmp.Lead__c = leadObj.Id;
        dealSupTmp.Name = 'Lead Conversion - ' + leadObj.Name;
        insert dealSupTmp;

        Quote_SharingHandler.handleDealSupportShareFuture(new Set<Id>{dealSupTmp.Id});
        Quote_SharingHandler.PartnerDealSupprtAndRegsWrapper.dealSupportSharingWithDealRegOwners(new Set<Id>{dealSupTmp.Id});

        Test.stopTest();

        System.assert([SELECT COUNT() FROM Deal_Support__c WHERE Id = :dealSupTmp.Id] > 0, 'Deal support should be shared with the managers.');
    }
}

    static void setupData() {
        String AVAYA_PARTNER_ACCOUNT_ID = System.Label.Avaya_Partner_Account_Id;
        PartnerRecordsUtil util = new PartnerRecordsUtil();
        system.runAs(PartnerRecordsUtil.runAsSysAdmin){
            List<Account> accList = [SELECT Id FROM Account Limit 1];
            List<Contact> conList = [SELECT Id FROM Contact];
            PortalAccessTestUtil portalAccessUtil = new PortalAccessTestUtil(accList.get(0),conList);
        }
    }
}