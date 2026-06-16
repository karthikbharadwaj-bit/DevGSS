@isTest
private class Test_OppHighlighter {
    @TestSetup
    static void createTestData() {
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(Account.SObjectType))
            .setField(Account.BillingStreet, 'Lenin')
            .setField(Account.BillingCity, 'Chicago')
            .setField(Account.BillingState, 'Alabama')
            .setField(Account.BillingPostalCode, '12345')
            .setField(Account.BillingCountry, 'AUT')
            .setField(Account.Billing_System__c, AccountHelper.BILLING_SYSTEM_NBS)
            .setField(Account.Billing_ID__c, '123456')
            .setField(Account.RC_Brand__c, 'BT TEST')
            .setField(Account.GPA_Account__c, true)
            .create()
            .getRecord();

        Opportunity testOpportunity = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setField(Opportunity.Name, 'Test Opportunity')
            .setField(Opportunity.AccountId, acc.Id)
            .create()
            .getRecord();

        Contact ct = (Contact) new sObjectBuilder(Contact.sObjectType)
            .setField(Contact.AccountId, acc.Id)
            .setField(Contact.FirstName, 'Ronaldo')
            .setField(Contact.LastName, 'Test')
            .setField(Contact.Customer_Record__c, false)
            .setField(Contact.Contact_Status__c, '2. Contacted')
            .setField(Contact.Quoted_Products__c, 'Engage Voice')
            .create()
            .getRecord();

        new SObjectBuilder(OpportunityContactRole.SObjectType)
            .setField(OpportunityContactRole.OpportunityId, testOpportunity.Id)
            .setField(OpportunityContactRole.ContactId, ct.Id)
            .create()
            .getRecord();
    }

    @isTest 
    static void testConstructor() {
        Opportunity opp = (Opportunity) new OpportunitySelector().selectOpportunityByName('Test Opportunity').executeQuery()[0];
        PageReference myVfPage = Page.OppHighlighter;
        Test.setCurrentPage(myVfPage);
        ApexPages.currentPage().getParameters().put('id',Opp.Id);

        ApexPages.StandardController oppController = new ApexPages.StandardController(opp);

        OppHighlighter controller = new OppHighlighter(oppController);
        ApexPages.Message[] pageMessages = ApexPages.getMessages();
        System.assertEquals(0, pageMessages.size(), 'a message should not have been found');
    }

    @isTest
    static void testParseCSV() {
        String csv = 'Count of DOMAIN,\n' + 
            '"DOMAIN,Total \n' + 
            '"mauiplaycare.com",2 \n' +
            '1080teles.com",5 \n' +
            '10minutemanicure.com,4 \n' + 
            '123Fit.com,4 \n' + 
            '123refills.com,2 \n';
        Opportunity opp = (Opportunity) new OpportunitySelector().selectOpportunityByName('Test Opportunity').executeQuery()[0];
        PageReference myVfPage = Page.OppHighlighter;
        Test.setCurrentPage(myVfPage);
        ApexPages.currentPage().getParameters().put('id',Opp.Id);

        ApexPages.StandardController oppController = new ApexPages.StandardController(opp);

        OppHighlighter controller = new OppHighlighter(oppController);
        List <List<String>> result = OppHighlighter.parseCSV(csv,true);
        System.assert(result.size() > 0 , 'csv should have been parsed correctly');
    

    }

}