@isTest
public class Test_ContactHighlighter {

    @isTest 
    static void testHighlighterCreation() {
        Account testAcc = (Account) new SObjectBuilder(Account.sObjectType)
            .setField(Account.RC_Brand__c, 'BTtest')
            .create()
            .getRecord();

        Contact testContact = (Contact) new SObjectBuilder(Contact.sObjectType)
            .setField(Contact.HasOptedOutOfEmail, true)
            .setField(Contact.Do_Not_Call__c, true)
            .setField(Contact.Domain_Type__c, 'test domain')
            .setField(Contact.Ok_to_Email__c, 'No')
            .setField(Contact.AccountId, testAcc.Id)
            .create()
            .getRecord();

        Test.startTest(); 
        PageReference currentPage = Page.contactHighlighter;
        currentPage.getParameters().put('id', testContact.Id);
        Test.setCurrentPage(currentPage);
        ApexPages.StandardController standardController = new ApexPages.StandardController(testContact);
        contactHighlighter controller = new contactHighlighter(standardController);
        Test.stopTest();

        System.assertEquals(controller.pageContact.Id, testContact.Id, 
                            'The controller\'s contact is not the same as the contact in the page.');
	}

    @isTest 
    static void testDomainTypeHighlighterCreation() {
        DomainTypeLeadContact__C domainType = (DomainTypeLeadContact__C) 
            new SObjectBuilder(DomainTypeLeadContact__C.sObjectType)
            .setField(DomainTypeLeadContact__C.Name, 'test domain')
            .setField(DomainTypeLeadContact__C.Contact__c, true)
            .setField(DomainTypeLeadContact__C.Lead__c, true)
            .create()
            .getRecord();

        Account testAcc = (Account) new SObjectBuilder(Account.sObjectType)
            .setField(Account.RC_Brand__c, 'BTtest')
            .create()
            .getRecord();

        Contact testContact = (Contact) new SObjectBuilder(Contact.sObjectType)
            .setField(Contact.HasOptedOutOfEmail, true)
            .setField(Contact.Do_Not_Call__c, true)
            .setField(Contact.Domain_Type__c, 'test domain')
            .setField(Contact.Ok_to_Email__c, 'No')
            .setField(Contact.AccountId, testAcc.Id)
            .create()
            .getRecord();

        Test.startTest(); 
        PageReference currentPage = Page.contactHighlighter;
        currentPage.getParameters().put('id', testContact.Id);
        Test.setCurrentPage(currentPage);
        ApexPages.StandardController standardController = new ApexPages.StandardController(testContact);
        contactHighlighter controller = new contactHighlighter(standardController);
        Test.stopTest();

        System.assertEquals(controller.getHasDomainType(), domainType.Contact__c,
                            'The controller should show a message if the contact has a domain type.');
    }

    @isTest 
    static void testBTApprovedHighlighterCreation() {
        System.assertEquals(contactHighlighter.imgPath, '/resource/warning',
            'Constants misinstantiated.');
        System.assertEquals(contactHighlighter.imgPathRed, '/resource/warningRed',
            'Constants misinstantiated.');
        DomainTypeLeadContact__C domainType = (DomainTypeLeadContact__C) 
            new SObjectBuilder(DomainTypeLeadContact__C.sObjectType)
            .setField(DomainTypeLeadContact__C.Name, 'test domain')
            .setField(DomainTypeLeadContact__C.Contact__c, true)
            .setField(DomainTypeLeadContact__C.Lead__c, true)
            .create()
            .getRecord();
            
        Account testAcc = (Account) new SObjectBuilder(Account.sObjectType)
            .setField(Account.RC_Brand__c, 'BTtest')
            .create()
            .getRecord();

        Contact testContact = (Contact) new SObjectBuilder(Contact.sObjectType)
            .setField(Contact.HasOptedOutOfEmail, true)
            .setField(Contact.Do_Not_Call__c, true)
            .setField(Contact.Domain_Type__c, 'test domain')
            .setField(Contact.Ok_to_Email__c, 'No')
            .setField(Contact.AccountId, testAcc.Id)
            .create()
            .getRecord();

        Test.startTest(); 
        PageReference currentPage = Page.contactHighlighter;
        currentPage.getParameters().put('id', testContact.Id);
        Test.setCurrentPage(currentPage);
        ApexPages.StandardController standardController = new ApexPages.StandardController(testContact);
        contactHighlighter controller = new contactHighlighter(standardController);
        Test.stopTest();

        System.assertEquals(controller.getIsBTApproved(), true, 
                     'The controller should show a message if the account\'s brand contains BT.');
	}

    @isTest 
    static void testLeadStatusMessageCreation() {
        DomainTypeLeadContact__C domainType = (DomainTypeLeadContact__C) 
            new SObjectBuilder(DomainTypeLeadContact__C.sObjectType)
            .setField(DomainTypeLeadContact__C.Name, 'test domain')
            .setField(DomainTypeLeadContact__C.Contact__c, true)
            .setField(DomainTypeLeadContact__C.Lead__c, true)
            .create()
            .getRecord();
        
        Account testAcc = (Account) new SObjectBuilder(Account.sObjectType)
            .setField(Account.RC_Brand__c, 'BTtest')
            .create()
            .getRecord();

        Contact testContact = (Contact) new SObjectBuilder(Contact.sObjectType)
            .setField(Contact.HasOptedOutOfEmail, true)
            .setField(Contact.Do_Not_Call__c, true)
            .setField(Contact.Domain_Type__c, 'test domain')
            .setField(Contact.Ok_to_Email__c, 'No')
            .setField(Contact.AccountId, testAcc.Id)
            .create()
            .getRecord();

        String expectedMessage = Label.DomainTypeLeadContact1 + ' <test domain>' + ': ' + Label.DomainTypeLeadContact2;
        Test.startTest(); 
        PageReference currentPage = Page.contactHighlighter;
        currentPage.getParameters().put('id', testContact.Id);
        Test.setCurrentPage(currentPage);
        ApexPages.StandardController standardController = new ApexPages.StandardController(testContact);
        contactHighlighter controller = new contactHighlighter(standardController);
        controller.errorMsg = null;
        Boolean check = controller.getShouldRender();
        String currentMessage = controller.getleadStatusMessage();
        Test.stopTest();

        System.assertEquals(currentMessage, expectedMessage, 
                            'The lead status message created by the controller is not correct.');
    }
}