@isTest
public class Test_OpportunityContactRoleExtension {
    @testSetup
    static void setupTestData() {
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        Contact testContact1 = new Contact(
            FirstName = 'John', 
            LastName = 'Doe', 
            AccountId = testAccount.Id
        );
        Contact testContact2 = new Contact(
            FirstName = 'Jane', 
            LastName = 'Doe', 
            AccountId = testAccount.Id
        );
        insert new List<Contact>{testContact1, testContact2};
        Opportunity testOpportunity = new Opportunity(
            Name = 'Test Opportunity', 
            StageName = 'Prospecting', 
            CloseDate = Date.today(), 
            AccountId = testAccount.Id
        );
        insert testOpportunity;
        Order__c testOrder = new Order__c(Name = 'Test Order', Account__c = testAccount.Id);
        insert testOrder;
    }
    
    @isTest
    static void testConstructorInitialization() {
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        Opportunity testOpportunity = new Opportunity(
            Name = 'Test Opportunity', 
            StageName = 'Prospecting', 
            CloseDate = Date.today(), 
            AccountId = testAccount.Id
        );
        insert testOpportunity;
        
        ApexPages.StandardController sc = new ApexPages.StandardController(testOpportunity);
        
        Test.startTest();
        OpportunityContactRoleExtension extension = new OpportunityContactRoleExtension(sc);
        Test.stopTest();
        
        System.assertNotEquals(null, extension.contactRecordType);
        System.assertNotEquals(null, extension.objacc);
        System.assertNotEquals(null, extension.oppObj);
        System.assertNotEquals(null, extension.lstContact);
        System.assertNotEquals(null, extension.listContactWrapper);
    }

    @isTest
    static void testConstructor() {
        ApexPages.currentPage().getParameters().put('accid', [SELECT Id FROM Account LIMIT 1].Id);
        ApexPages.currentPage().getParameters().put('conid', [SELECT Id FROM Contact LIMIT 1].Id);
        ApexPages.currentPage().getParameters().put('RecordType', Schema.SObjectType.Opportunity
                                                    .getRecordTypeInfosByName()
                                                    .get('Cancel Opportunity')
                                                    .getRecordTypeId()
                                                   );

        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        ApexPages.StandardController sc = new ApexPages.StandardController(testAccount);

        OpportunityContactRoleExtension controller = new OpportunityContactRoleExtension(sc);

        System.assertNotEquals(null, controller.oppObj);
        System.assertNotEquals(null, controller.lstContact);
        System.assertNotEquals(null, controller.listContactWrapper);
        System.assertEquals(true, controller.isForCancel);
    }

    @isTest
    static void testCallDispatcher() {
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        Opportunity testOpportunity = new Opportunity(
            	Name = 'Test Opportunity', 
            	StageName = 'Prospecting', 
            	CloseDate = Date.today(), 
            	AccountId = testAccount.Id
        );
        insert testOpportunity;
        ApexPages.StandardController sc = new ApexPages.StandardController(testOpportunity);
        OpportunityContactRoleExtension extension = new OpportunityContactRoleExtension(sc);
        ApexPages.currentPage().getParameters().put('accid', testAccount.Id);
        
        Test.startTest();
        PageReference result = extension.callDispatcher();
        Test.stopTest();
        
        System.assertEquals(null, result);
    }

    @isTest
    static void testGetContactLstOnAccountSelection() {
        ApexPages.currentPage().getParameters().put('accid', [SELECT Id FROM Account LIMIT 1].Id);

        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        ApexPages.StandardController sc = new ApexPages.StandardController(testAccount);
        OpportunityContactRoleExtension controller = new OpportunityContactRoleExtension(sc);

        Account testAccount1 = new Account(Name = 'Test Account');
        insert testAccount1;
        Opportunity testOpportunity = new Opportunity(
            Name = 'Test Opportunity', 
            StageName = 'Prospecting', 
            CloseDate = Date.today(), 
            AccountId = testAccount1.Id
        );
        insert testOpportunity;
        ApexPages.StandardController osc = new ApexPages.StandardController(testOpportunity);
        OpportunityContactRoleExtension extension = new OpportunityContactRoleExtension(osc);
        extension.oppObj.AccountId = testAccount1.Id;

        Test.startTest();
        controller.getContactLstOnAccountSelection();
        extension.getContactLstOnAccountSelection();
        Test.stopTest();

        System.assertNotEquals(null, controller.lstContact);
        System.assertNotEquals(null, controller.listContactWrapper);
        System.assertNotEquals(null, extension.lstContact);
        System.assertNotEquals(null, extension.listContactWrapper);
    }

    @isTest
    static void testGetContactList() {
        Account testAccount = new Account(
            Name = 'Test Account', 
            RC_Account_Status__c = 'Paid'
        );
        insert testAccount;
        Contact testContact = new Contact(
            FirstName = 'Test', 
            LastName = 'Contact', 
            AccountId = testAccount.Id
        );
        insert testContact;
        Opportunity testOpportunity = new Opportunity(
            Name = 'Test Opportunity', 
            StageName = 'Prospecting', 
            CloseDate = Date.today(), 
            AccountId = testAccount.Id
        );
        insert testOpportunity;
        AccountContactRole acr = new AccountContactRole(
            AccountId = testAccount.Id, 
            isPrimary = true, 
            ContactId = testContact.Id
        );
        insert acr;

        Test.startTest();
        ApexPages.StandardController sc = new ApexPages.StandardController(testOpportunity);
        OpportunityContactRoleExtension extension = new OpportunityContactRoleExtension(sc);
        extension.getContactList(string.valueOf(testAccount.Id).substring(0,15));
        extension.contactIdTemp = testContact.Id;
        extension.getContactList(string.valueOf(testAccount.Id).substring(0,15));
        Test.stopTest();

        System.assertNotEquals(null, extension.lstContact);
        System.assert(extension.lstContact.size() > 0);
        System.assertNotEquals(null, extension.listContactWrapper);
        System.assert(extension.listContactWrapper.size() > 0);
    }
    
    @isTest
    static void testGetContactList2() {
        Account testAccount = new Account(
            Name = 'Test Account', 
            RC_Account_Status__c = 'Paid'
        );
        insert testAccount;
        Contact testContact = new Contact(
            FirstName = 'Test', 
            LastName = 'Contact', 
            AccountId = testAccount.Id
        );
        insert testContact;
        Opportunity testOpportunity = new Opportunity(
            Name = 'Test Opportunity', 
            StageName = 'Prospecting', 
            CloseDate = Date.today(), 
            AccountId = testAccount.Id
        );
        insert testOpportunity;
        PageReference pageref = Page.OpportunityContactSelection;
        test.setCurrentPage(pageref);
        pageref.getParameters().put('accid', string.valueOf(testAccount.Id).substring(0,15));

        Test.startTest();
        ApexPages.StandardController sc = new ApexPages.StandardController(testOpportunity);
        OpportunityContactRoleExtension extension = new OpportunityContactRoleExtension(sc);
        extension.getContactList(string.valueOf(testAccount.Id).substring(0,15));
        extension.contactIdTemp = testContact.Id;
        extension.getContactList(string.valueOf(testAccount.Id).substring(0,15));
        Test.stopTest();

        System.assertNotEquals(null, extension.lstContact);
        System.assert(extension.lstContact.size() > 0);
        System.assertNotEquals(null, extension.listContactWrapper);
        System.assert(extension.listContactWrapper.size() > 0);
    }
    
    @isTest
    static void testGetContactList3() {
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        Contact testContact = new Contact(
            FirstName = 'Test', 
            LastName = 'Contact', 
            AccountId = testAccount.Id
        );
        insert testContact;
        Opportunity testOpportunity = new Opportunity(
            Name = 'Test Opportunity', 
            StageName = 'Prospecting', 
            CloseDate = Date.today(), 
            AccountId = testAccount.Id
        );
        insert testOpportunity;
        AccountContactRole acr = new AccountContactRole(
            AccountId = testAccount.Id, 
            isPrimary = true, 
            ContactId = testContact.Id
        );
        insert acr;

        Test.startTest();
        ApexPages.StandardController sc = new ApexPages.StandardController(testOpportunity);
        OpportunityContactRoleExtension extension = new OpportunityContactRoleExtension(sc);
        extension.getContactList(string.valueOf(testAccount.Id).substring(0,15));
        extension.contactIdTemp = testContact.Id;
        extension.getContactList(string.valueOf(testAccount.Id).substring(0,15));
        Test.stopTest();
        
        System.assertNotEquals(null, extension.lstContact);
        System.assert(extension.lstContact.size() > 0);
        System.assertNotEquals(null, extension.listContactWrapper);
        System.assert(extension.listContactWrapper.size() > 0);
    }

    @isTest
    static void testCancelOppty() {
        ApexPages.currentPage().getParameters().put('accid', [SELECT Id FROM Account LIMIT 1].Id);
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        ApexPages.StandardController sc = new ApexPages.StandardController(testAccount);
        OpportunityContactRoleExtension controller = new OpportunityContactRoleExtension(sc);
        PageReference result = controller.cancelOppty();
        System.assertNotEquals(null, result);
        System.assert(result.getUrl().contains('OpportunityCancellation'));
    }

    @isTest
    static void testCancel() {
        ApexPages.currentPage().getParameters().put('retURL', '/006/o');
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        ApexPages.StandardController sc = new ApexPages.StandardController(testAccount);
        OpportunityContactRoleExtension controller = new OpportunityContactRoleExtension(sc);
        PageReference result = controller.cancel();
        System.assertNotEquals(null, result);
        System.assertEquals('/006/o', result.getUrl());
    }

    @isTest
    static void testCreateOpportunity() {
        ApexPages.currentPage().getParameters().put('accid', [SELECT Id FROM Account LIMIT 1].Id);
        ApexPages.currentPage().getParameters().put('retURL', '/006/o');
        ApexPages.currentPage().getParameters().put('conid', [SELECT Id FROM Contact LIMIT 1].Id);

        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        ApexPages.StandardController sc = new ApexPages.StandardController(testAccount);
        OpportunityContactRoleExtension controller = new OpportunityContactRoleExtension(sc);
        controller.selectedContact = [SELECT Id FROM Contact LIMIT 1].Id;
        PageReference result = controller.createOpportunity();
        System.assertNotEquals(null, result);
        System.assert(result.getUrl().contains('/e'));
    }
}