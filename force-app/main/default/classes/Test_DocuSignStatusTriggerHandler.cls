@isTest
private class Test_DocuSignStatusTriggerHandler {

    public enum DocusignStatus {
    Sent,
    Completed
    }

    public enum TestObject {
    Account,
    Contact,
    Opportunity,
    Product2,
    Quote,
    cpqQuote,
    QuoteLineItem,
    Approval
  }

    @isTest
    static void AquivaHelper_getOpportunitiesByQuotes() {
        // TODO: move this test to separate class, test for AquivaHelper
        Triggers.switchOff();
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => 'testAcc',
                    Account.BillingPostalCode => 'testCode',
                    Account.BillingCity => 'testCity',
                    Account.BillingCountry => 'testCountry',
                    Account.BillingState => 'testState',
                    Account.BillingStreet => 'testStreet'
                }
            )
            .create()
            .getRecord();
        Contact contact = (Contact) new SObjectBuilder(Contact.SObjectType)
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
        Opportunity o = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.Name => 'Test Opportunity 2016',
                    Opportunity.Type => 'Syndicated - New',
                    Opportunity.StageName => 'Planning',
                    Opportunity.CloseDate => system.today().addMonths(1),
                    Opportunity.AccountId => acc.Id,
                    Opportunity.Primary_Opportunity_Contact__c => contact.Id,
                    Opportunity.EstimatedProfessionalServices12Month__c => 10
                }
            )
            .create()
            .getRecord();
        Quote q = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Quote.Name => 'quotetest',
                    Quote.OpportunityId => o.Id,
                    Quote.Total_Number_of_Digital_Lines__c => 10,
                    Quote.Account__c => o.AccountId,
                    Quote.ProServ_Sold_Date__c => System.now(),
                    Quote.Pricebook2Id => Test.getStandardPriceBookId()
                }
            )
            .create()
            .getRecord();
        Approval__c appr = (Approval__c) new SObjectBuilder(Approval__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Approval__c.Quote__c => q.Id,
                    Approval__c.Opportunity__c => o.Id,
                    Approval__c.Type__c => ApprovalHelperCls.LEGAL_REQUEST_TYPE_AMENDMENT,
                    Approval__c.Account__c => acc.Id,
                    Approval__c.RecordTypeId => Schema.SObjectType.Approval__c.getRecordTypeInfosByName().get('Invoicing Request').getRecordTypeId(),
                    Approval__c.Status__c => 'PendingL1Approval',
                    Approval__c.Monthly_Credit_Limit__c => 501,
                    Approval__c.Potential_Users__c => 1,
                    Approval__c.Reason_Customer_is_Requesting_Invoicing__c => 'test'
                }
            )
            .create()
            .getRecord();
        Triggers.switchOn();
        Test.startTest();
        Map<Id, Opportunity> testMap = AquivaHelper.getOpportunitiesByQuotes(new List<Quote>{q});
        Test.stopTest();
        System.assert(testMap.containsKey(q.Id));
        System.assertEquals(testMap.get(q.Id).Id, o.Id);
    }

    @isTest
    static void docusign_SimpleSend() {
        Triggers.switchOff();
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => 'testAcc',
                    Account.BillingPostalCode => 'testCode',
                    Account.BillingCity => 'testCity',
                    Account.BillingCountry => 'testCountry',
                    Account.BillingState => 'testState',
                    Account.BillingStreet => 'testStreet'
                }
            )
            .create()
            .getRecord();
        Contact contact = (Contact) new SObjectBuilder(Contact.SObjectType)
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
        Opportunity o = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.Name => 'Test Opportunity 2016',
                    Opportunity.Type => 'Syndicated - New',
                    Opportunity.StageName => 'Planning',
                    Opportunity.CloseDate => system.today().addMonths(1),
                    Opportunity.AccountId => acc.Id,
                    Opportunity.Primary_Opportunity_Contact__c => contact.Id,
                    Opportunity.EstimatedProfessionalServices12Month__c => 10
                }
            )
            .create()
            .getRecord();
        Quote q = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Quote.Name => 'quotetest',
                    Quote.OpportunityId => o.Id,
                    Quote.Total_Number_of_Digital_Lines__c => 10,
                    Quote.Account__c => o.AccountId,
                    Quote.ProServ_Sold_Date__c => System.now(),
                    Quote.Pricebook2Id => Test.getStandardPriceBookId()
                }
            )
            .create()
            .getRecord();
        Approval__c appr = (Approval__c) new SObjectBuilder(Approval__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Approval__c.Quote__c => q.Id,
                    Approval__c.Opportunity__c => o.Id,
                    Approval__c.Type__c => ApprovalHelperCls.LEGAL_REQUEST_TYPE_AMENDMENT,
                    Approval__c.Account__c => acc.Id,
                    Approval__c.RecordTypeId => Schema.SObjectType.Approval__c.getRecordTypeInfosByName().get('Invoicing Request').getRecordTypeId(),
                    Approval__c.Status__c => 'PendingL1Approval',
                    Approval__c.Monthly_Credit_Limit__c => 501,
                    Approval__c.Potential_Users__c => 1,
                    Approval__c.Reason_Customer_is_Requesting_Invoicing__c => 'test'
                }
            )
            .create()
            .getRecord();
        q.isPrimary__c = true;
        update q;
        Triggers.switchOn();
        Test.startTest();
        Triggers.switchOff();
        q.Special_TOS_Approval__c = appr.Id;
        o.Special_TOS_Approval__c = appr.Id;
        Triggers.switchOn();
        DSFS__DocuSign_Status__c docuSignStatus = (DSFS__DocuSign_Status__c) new SObjectBuilder(DSFS__DocuSign_Status__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    DSFS__DocuSign_Status__c.DSFS__Company__c => acc.Id,
                    DSFS__DocuSign_Status__c.DSFS__Opportunity__c => o.Id,
                    DSFS__DocuSign_Status__c.DFSQ__Quote__c => q.Id,
                    DSFS__DocuSign_Status__c.DSFS__Completed_Date_Time__c => DateTime.newInstance(2000, 10, 11, 8, 6, 16),
                    DSFS__DocuSign_Status__c.DSFS__Envelope_Status__c => DocusignStatus.Sent.name()
                }
            )
            .create()
            .getRecord();
        Test.stopTest();
        List<Quote> quotesList = new QuoteSelector()
            .selectQuoteById(new List<Object>{q.Id})
            .executeQuery();
        q = quotesList[0];

        System.assertEquals(QuoteTriggerHelper.STATUS_PRESENTED, q.Status);
    }

    @isTest
    static void docusign_SimpleComplete() {
        Triggers.switchOff();
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => 'testAcc',
                    Account.BillingPostalCode => 'testCode',
                    Account.BillingCity => 'testCity',
                    Account.BillingCountry => 'testCountry',
                    Account.BillingState => 'testState',
                    Account.BillingStreet => 'testStreet'
                }
            )
            .create()
            .getRecord();
        Contact contact = (Contact) new SObjectBuilder(Contact.SObjectType)
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
        Opportunity o = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.Name => 'Test Opportunity 2016',
                    Opportunity.Type => 'Syndicated - New',
                    Opportunity.StageName => 'Planning',
                    Opportunity.CloseDate => system.today().addMonths(1),
                    Opportunity.AccountId => acc.Id,
                    Opportunity.Primary_Opportunity_Contact__c => contact.Id,
                    Opportunity.EstimatedProfessionalServices12Month__c => 10
                }
            )
            .create()
            .getRecord();
        Quote q = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Quote.Name => 'quotetest',
                    Quote.OpportunityId => o.Id,
                    Quote.Total_Number_of_Digital_Lines__c => 10,
                    Quote.Account__c => o.AccountId,
                    Quote.ProServ_Sold_Date__c => System.now(),
                    Quote.Pricebook2Id => Test.getStandardPriceBookId()
                }
            )
            .create()
            .getRecord();
        Approval__c appr = (Approval__c) new SObjectBuilder(Approval__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Approval__c.Quote__c => q.Id,
                    Approval__c.Opportunity__c => o.Id,
                    Approval__c.Type__c => ApprovalHelperCls.LEGAL_REQUEST_TYPE_AMENDMENT,
                    Approval__c.Account__c => acc.Id,
                    Approval__c.RecordTypeId => Schema.SObjectType.Approval__c.getRecordTypeInfosByName().get('Invoicing Request').getRecordTypeId(),
                    Approval__c.Status__c => 'PendingL1Approval',
                    Approval__c.Monthly_Credit_Limit__c => 501,
                    Approval__c.Potential_Users__c => 1,
                    Approval__c.Reason_Customer_is_Requesting_Invoicing__c => 'test'
                }
            )
            .create()
            .getRecord();
        q.isPrimary__c = true;
        update q;
        Triggers.switchOn();
        Test.startTest();
        Triggers.switchOff();
        q.Special_TOS_Approval__c = appr.Id;
        o.Special_TOS_Approval__c = appr.Id;
        Triggers.switchOn();
        DSFS__DocuSign_Status__c docuSignStatus = (DSFS__DocuSign_Status__c) new SObjectBuilder(DSFS__DocuSign_Status__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    DSFS__DocuSign_Status__c.DSFS__Company__c => acc.Id,
                    DSFS__DocuSign_Status__c.DSFS__Opportunity__c => o.Id,
                    DSFS__DocuSign_Status__c.DFSQ__Quote__c => q.Id,
                    DSFS__DocuSign_Status__c.DSFS__Completed_Date_Time__c => DateTime.newInstance(2000, 10, 11, 8, 6, 16),
                    DSFS__DocuSign_Status__c.DSFS__Envelope_Status__c => DocusignStatus.Completed.name()
                }
            )
            .create()
            .getRecord();
        Test.stopTest();
        Quote resultQuote = (Quote) new QuoteSelector()
            .selectQuoteById(new List<Object>{q.Id})
            .executeQuery()
            .get(0);
        System.assert(resultQuote.isPrimary__c);
        System.assertEquals(appr.Id, o.Special_TOS_Approval__c);
        System.assertEquals('Accepted', resultQuote.Status);
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void docusign_VerifyFieldValuesIsCopied() {

        Account acc = new Account(
            Name = 'testAcc'
        );
        insert acc;

        Contact testContact = new Contact(
            FirstName = 'Test1',
            LastName = 'Test1',
            AccountId = acc.Id,
            Email = 'test@test.com',
            Phone = '1234567890',
            Preferred_Language__c = 'en_US'
        );
        insert testContact;

        Opportunity testOpportunity = new Opportunity(
            Name = 'Test Opportunity 2016',
            Type = 'Syndicated - New',
            StageName = 'Planning',
            CloseDate = System.today().addMonths(1),
            AccountId = acc.Id,
            Primary_Opportunity_Contact__c = testContact.Id
        );
        insert testOpportunity;


        PriceBook2 testPriceBook = new Pricebook2(
            Name = 'Test Price Book',
            Description ='Test Price Book Products',
            IsActive = true,
            Line_Range_Min__c = 5,
            Service__c='Office'
        );
        insert testPriceBook;

        Date todayDate = Date.today();
        todayDate = todayDate.addDays(5);

        List<Quote> quotesList = new List<Quote>();

        Quote testQuote = new Quote(
            Name = 'qoutetest',
            OpportunityId = testOpportunity.id,
            Account__c = acc.Id,
            Pricebook2Id = testPriceBook.Id,
            Total_Number_of_Digital_Lines__c = 10,
            QuoteType__c = QuoteHelper.QUOTE_TYPE_AGREEMENT,
            Status = QuoteTriggerHelper.STATUS_ACTIVE,
            Auto_Renewal__c = true,
            Initial_Term_months__c = '12',
            Term_months__c = '12',
            Start_Date__c = todayDate,
            End_Date__c = todayDate
        );
        quotesList.add(testQuote);

        Quote testQuote1 = new Quote(
            Name = 'qoutetest1',
            OpportunityId = testOpportunity.id,
            Account__c = acc.Id,
            Pricebook2Id = testPriceBook.Id,
            Total_Number_of_Digital_Lines__c = 10,
            QuoteType__c = QuoteHelper.QUOTE_TYPE_AGREEMENT,
            Status = QuoteTriggerHelper.STATUS_EXECUTED,
            Start_Date__c = Date.today(),
            End_Date__c = Date.today()
        );
        quotesList.add(testQuote1);

        insert quotesList;


        Test.startTest();

            DSFS__DocuSign_Status__c dsStatus = new DSFS__DocuSign_Status__c(
                DSFS__Company__c = acc.Id,
                DSFS__Opportunity__c = testOpportunity.Id,
                DFSQ__Quote__c = testQuote1.Id,
                DSFS__Envelope_Status__c = 'Completed',
                DSFS__Completed_Date_Time__c = DateTime.newInstance(2000, 10, 11, 8, 6, 16)
            );
            insert dsStatus;

        Test.stopTest();

        Quote reselectedTestQuote1 = [select Id, Name, Initial_Term_months__c, Term_months__c,
                                        Auto_Renewal__c, Start_Date__c, End_Date__c,
                                        QuoteType__c, AccountId, Status
                                    from Quote
                                    where Id = :testQuote1.Id];
        //System.debug('reselectedTestQuote1 >>>> ' + reselectedTestQuote1);

        //System.assert(reselectedTestQuote1.Start_Date__c == testQuote.Start_Date__c);
        //System.assert(reselectedTestQuote1.End_Date__c == testQuote.End_Date__c);
        //System.assert(reselectedTestQuote1.Auto_Renewal__c == testQuote.Auto_Renewal__c);
        //System.assert(reselectedTestQuote1.Term_months__c == testQuote.Term_months__c);
        //System.assert(reselectedTestQuote1.Initial_Term_months__c == testQuote.Initial_Term_months__c);
    }

    static Map<TestObject, sObject> docuSignEnvelopeStatusChangedDataSetup(Boolean isContractExist) {
        Map<TestObject, sObject> resultMap = new Map<TestObject, sObject>();
        
        Triggers.switchOff();
        
            Account acc = new Account(Name = 'testAcc');
            insert acc;
            resultMap.put(TestObject.Account, acc);

            Opportunity testOpportunity = new Opportunity(
                Name = 'Test Opportunity 2016',
                Type = 'Syndicated - New',
                StageName = 'Planning',
                CloseDate = System.today().addMonths(1),
                AccountId = acc.Id
            );
            insert testOpportunity;

            Quote testQuote = new Quote(
                Name = 'qoutetest',
                OpportunityId = testOpportunity.id,
                Account__c = acc.Id,
                Pricebook2Id = Test.getStandardPricebookId(),
                isPrimary__c = true,
                RecordTypeId = QuoteHelper.RT_ID_BILLING,
                Status = QuoteHelper.QUOTE_STATUS_DRAFT,
                Total_Number_of_Digital_Lines__c = 10,
                Start_Date__c = Date.today(),
                End_Date__c = Date.today(),
                Auto_Renewal__c = true,
                Term_months__c = '12',
                Initial_Term_months__c = '12'
            );

            if (isContractExist) {
                testQuote.Package_Info__c = '[{"contract": {"id":"someContractId"}}]';
            }

            insert testQuote;
            resultMap.put(TestObject.Quote, testQuote);

            Approval__c testAppr = new Approval__c (Status__c = 'Completed',
                RecordTypeId = ApprovalHelper.RT_ID_ENGAGE_LEGAL, Opportunity__c = testOpportunity.Id );
            insert testAppr;
            resultMap.put(TestObject.Approval, testAppr);

        Triggers.switchOn();

        DSFS__DocuSign_Status__c dsStatus = new DSFS__DocuSign_Status__c(
            DSFS__Company__c = acc.Id,
            DFSQ__Quote__c = testQuote.Id,
            DSFS__Envelope_Status__c = 'Sent',
            DSFS__Opportunity__c = testOpportunity.Id,
            DSFS__Completed_Date_Time__c = DateTime.newInstance(2000, 10, 11, 8, 6, 16)
        );
        insert dsStatus;

        DSFS__DocuSign_Envelope__c testEnvelope = new DSFS__DocuSign_Envelope__c();
        testEnvelope.dsfs__Source_Object__c = testQuote.Id;
        testEnvelope.dsfs__DocuSign_Envelope_ID__c = '2155d73219918144d3';
        insert testEnvelope;

        DSFS__DocuSign_Envelope_Recipient__c recipient = new DSFS__DocuSign_Envelope_Recipient__c();
        recipient.dsfs__DocuSign_EnvelopeID__c = testEnvelope.Id;
        insert recipient;

        DSFS__DocuSign_Recipient_Status__c recipientStatus = new DSFS__DocuSign_Recipient_Status__c();
        recipientStatus.Name = 'John Doe';
        recipientStatus.dsfs__Parent_Status_Record__c = dsStatus.Id;
        recipientStatus.dsfs__Recipient_Status__c = 'Completed';
        recipientStatus.dsfs__DocuSign_Recipient_Id__c = recipient.Id;
        insert recipientStatus;

        Attachment testAttach = new Attachment(Name = 'Unit Test Attachment', ParentId = dsStatus.Id);
        Blob bodyBlob = Blob.valueOf('Body');
        testAttach.Body = bodyBlob;
        insert testAttach;

        return resultMap;
    }

    private static List<Contract> createTestContracts(Id accountId, Boolean createActiveContract) {

        List<Contract> createdContracts = new List<Contract>();

        Contract draftContract = new Contract(
            AccountId = accountId,
            Status = 'Draft'
        );
        insert draftContract;

        createdContracts.add(draftContract);

        if (createActiveContract) {
            Contract activeContract = new Contract(
                AccountId = accountId,
                Original_Signed_Date__c = System.today(),
                Status = 'Draft'
            );
            insert activeContract;

            activeContract.Status = 'Active';
            update activeContract;

            createdContracts.add(activeContract);
        }

        return createdContracts;
    }

    @isTest
    static void docuSign_ChangeEnvelopeStatusWithExistingActiveContract() {
        Triggers.switchOff();
        Map<TestObject, sObject> testObjects = docuSignEnvelopeStatusChangedDataSetup(true);
        Triggers.switchOn();
        Id accountId = (Id)testObjects.get(TestObject.Account).get('Id');
        createTestContracts(accountId, true);

        Triggers.switchOn();

        DSFS__DocuSign_Status__c dsStatus = [SELECT Id FROM DSFS__DocuSign_Status__c LIMIT 1];

        Test.startTest();
            dsStatus.dsfs__Envelope_Status__c = 'Completed';
            update dsStatus;
        Test.stopTest();

        List<Contract> contractsFromAccount = docuSignValidateTestResult(dsStatus, testObjects);
        System.assert(contractsFromAccount.size() == 2, 'Unexpected count of Contract records');
    }

    @isTest
    static void docuSign_ChangeEnvelopeStatusWithNotExistingActiveContract() {
        Triggers.switchOff();
        Map<TestObject, sObject> testObjects = docuSignEnvelopeStatusChangedDataSetup(true);
        Triggers.switchOn();
        Id accountId = (Id)testObjects.get(TestObject.Account).get('Id');
        createTestContracts(accountId, false);

        Triggers.switchOn();

        DSFS__DocuSign_Status__c dsStatus = [SELECT Id FROM DSFS__DocuSign_Status__c LIMIT 1];

        Test.startTest();
            dsStatus.dsfs__Envelope_Status__c = 'Completed';
            update dsStatus;
        Test.stopTest();

        List<Contract> contractsFromAccount = docuSignValidateTestResult(dsStatus, testObjects);
        System.assert(contractsFromAccount.size() == 2, 'Unexpected count of Contract records');
    }

    static List<Contract> docuSignValidateTestResult(DSFS__DocuSign_Status__c dsStatus, Map<TestObject, sObject> testObjects) {

        Id accountId = (Id)testObjects.get(TestObject.Account).get('Id');

        List<Contract> existingContracts = (List<Contract>) new ContractSelector()
            .selectContracts()
            .selectFields(
                new List<Schema.SObjectField>{
                    Contract.Status,
                    Contract.Original_Signed_Date__c,
                    Contract.Source__c,
                    Contract.Auto_Renewal__c,
                    Contract.Start_Date__c,
                    Contract.End_Date__c,
                    Contract.Renewal_Term__c,
                    Contract.Initial_Term__c,
                    Contract.Original_Contract__c,
                    Contract.Original_Auto_Renewal__c,
                    Contract.Original_Start_Date__c,
                    Contract.Original_End_Date__c,
                    Contract.Original_Initial_Term__c,
                    Contract.Original_Renewal_Term__c,
                    Contract.Previous_Contract__c
                }
            )
            .subselect(
                new ContractVersionSelector()
                    .selectContractVersions()
                    .addOrdering(ContractVersion__c.VersionNumber__c, QueryFactory.SortOrder.DESCENDING, true)
            )
            .setCondition('AccountId = \'' + accountId + '\'')
            .executeQuery();
        Id activeContractId;
        Id terminatedContractId;
        for (Contract c : existingContracts) {
            if (activeContractId != null) {
                System.assert(true == false, 'More than one active contracts exists!');
            }
            if (c.Status == 'Active') {
                activeContractId = c.Id;
                System.assert(c.Original_Signed_Date__c != null, 'Active Contract should has filled Original_Signed_Date__c field');
            } else if (c.Status == DocuSignStatusTriggerHandler.CONTRACT_STATUS_TERMINATED) {
                terminatedContractId = c.Id;
            }
        }

        Approval__c approval = [
            SELECT Contracts__c, Executed_Contract__c
            FROM Approval__c
            WHERE Id = :(Id)testObjects.get(TestObject.Approval).get('Id')];

        System.assert(
            approval.Contracts__c == activeContractId || approval.Contracts__c == terminatedContractId,
            'Contracts__c field on Approval__c record was not updated as expected'
        );
        System.assertEquals(approval.Executed_Contract__c, dsStatus.Id, 'Executed_Contract__c field on Approval__c record was not updated as expected');

        return existingContracts;
    }

    @isTest
    static void docusign_PrepopulateFields() {
        Account acc = new Account(Name = 'testAcc');
        insert acc;

        Opportunity testOpportunity = new Opportunity(
            Name = 'Test Opportunity 2016',
            Type = 'Syndicated - New',
            StageName = 'Planning',
            CloseDate = System.today().addMonths(1),
            AccountId = acc.Id
        );
        insert testOpportunity;

        PriceBook2 testPriceBook = new Pricebook2(
            Name = 'Test Price Book',
            Description ='Test Price Book Products',
            IsActive = true,
            Line_Range_Min__c = 5,
            Service__c = 'Office'
        );
        insert testPriceBook;

        Quote testQuote = new Quote(
            Name = 'qoutetest',
            OpportunityId = testOpportunity.id,
            Account__c = acc.Id,
            Pricebook2Id = testPriceBook.Id,
            Total_Number_of_Digital_Lines__c = 10,
            Start_Date__c = Date.today(),
            End_Date__c = Date.today()
        );
        insert testQuote;

        // Precreate docusign envelope
        dsfs__DocuSign_Envelope__c testEnvelope = new dsfs__DocuSign_Envelope__c(
            dsfs__Source_Object__c = testQuote.Id,
            dsfs__DocuSign_Envelope_ID__c = '2155d73219918144d3');
        insert testEnvelope;
        Test.StartTest();
            DSFS__DocuSign_Status__c dsStatus = new DSFS__DocuSign_Status__c(
                DSFS__Envelope_Status__c = 'Sent',
                dsfs__DocuSign_Envelope_ID__c = '2155d73219918144d3');
            insert dsStatus;
        Test.StopTest();

        dsfs__DocuSign_Status__c dsStatusReselected = [
            SELECT Id, dfsq__Quote__c, dsfs__Opportunity__c, dsfs__DocuSign_Envelope_ID__c, dsfs__Company__c
            FROM dsfs__DocuSign_Status__c
            WHERE Id = :dsStatus.Id
        ];
        System.assertEquals(testOpportunity.Id, dsStatusReselected.dsfs__Opportunity__c);
        System.assertEquals(testQuote.Id, dsStatusReselected.dfsq__Quote__c);
        System.assertEquals(acc.Id, dsStatusReselected.dsfs__Company__c);
    }

    @isTest
    static void testChangeLinkedQuoteStatusToPresented() {

        Account acc = (Account) new SObjectBuilder(Account.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Name => 'Test Account'
            })
            .create()
            .getRecord();

        Contact testContact = (Contact) new SObjectBuilder(Contact.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Contact.AccountId => acc.Id,
                Contact.LastName => 'Doe',
                Contact.FirstName => 'John',
                Contact.Email => 'jg@rc.test',
                Contact.Phone => '1234567890',
                Contact.Preferred_Language__c => 'en_US'
            })
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SOBjectBuilder(Opportunity.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.AccountId => acc.Id,
                Opportunity.Type => 'Syndicated - New',
                Opportunity.StageName => 'Quote',
                Opportunity.CloseDate => System.today().addMonths(1),
                Opportunity.AccountId => acc.Id,
                Opportunity.Primary_Opportunity_Contact__c => testContact.Id
            })
            .create()
            .getRecord();

        Pricebook2 testPriceBook = (Pricebook2) new SObjectBuilder(PriceBook2.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Pricebook2.Line_Range_Min__c => 5,
                Pricebook2.IsActive => true,
                Pricebook2.Service__c => 'Office'
            })
            .create()
            .getRecord();

        Quote testOfficeQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Quote.Name => 'Office Quote',
                Quote.OpportunityId => opp.Id,
                Quote.Pricebook2Id => testPriceBook.Id,
                Quote.CurrencyIsoCode => 'USD',
                Quote.Account__c => acc.Id,
                Quote.Pricebook2Id => testPriceBook.Id,
                Quote.Total_Number_of_Digital_Lines__c => 10,
                Quote.Status => QuoteTriggerHelper.STATUS_EXECUTED,
                Quote.Auto_Renewal__c => true,
                Quote.Initial_Term_months__c => '12',
                Quote.Term_months__c => '12',
                Quote.Start_Date__c => Date.today(),
                Quote.End_Date__c => Date.today()
            })
            .create()
            .getRecord();

        Quote testEngageQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Quote.Name => 'Engage Quote',
                Quote.OpportunityId => opp.Id,
                Quote.Pricebook2Id => testPriceBook.Id,
                Quote.CurrencyIsoCode => 'USD',
                Quote.Account__c => acc.Id,
                Quote.Pricebook2Id => testPriceBook.Id,
                Quote.Total_Number_of_Digital_Lines__c => 10,
                Quote.Status => QuoteTriggerHelper.STATUS_EXECUTED,
                Quote.ParentQuote__c => testOfficeQuote.Id
            })
            .create()
            .getRecord();

        Test.startTest();

            DSFS__DocuSign_Status__c dsStatus = (DSFS__DocuSign_Status__c) new SObjectBuilder(DSFS__DocuSign_Status__c.SObjectType)
                .setFields(new Map<SObjectField, Object>{
                    DSFS__DocuSign_Status__c.DSFS__Company__c => acc.Id,
                    DSFS__DocuSign_Status__c.DSFS__Opportunity__c => opp.Id,
                    DSFS__DocuSign_Status__c.DFSQ__Quote__c => testEngageQuote.Id,
                    DSFS__DocuSign_Status__c.DSFS__Envelope_Status__c => 'Sent',
                    DSFS__DocuSign_Status__c.DSFS__Completed_Date_Time__c => DateTime.newInstance(2000, 10, 11, 8, 6, 16)
                })
                .create()
                .getRecord();

        Test.stopTest();

        Quote engageQuote = (Quote) new QuoteSelector()
            .selectQuotes()
            .selectFields(new List<String>{'Status', 'Auto_Renewal__c', 'Initial_Term_months__c', 'Start_Date__c', 'End_Date__c'})
            .setCondition('Id =:bind0')
            .setQueryBindings(new List<Object>{testEngageQuote.Id})
            .executeQuery()
            .get(0);

        System.assertEquals('Presented', engageQuote.Status, 'Status field on Quote record was not updated as expected');
        System.assert(true, engageQuote.Auto_Renewal__c);
        System.assertEquals('12', engageQuote.Initial_Term_months__c, 'Initial_Term_months field on Quote record was not updated as expected');
        System.assertEquals(Date.today(), engageQuote.Start_Date__c, 'Start_Date field on Quote record was not updated as expected');
        System.assertEquals(Date.today(), engageQuote.End_Date__c, 'End_Date field on Quote record was not updated as expected');

    }

    @isTest
    static void testChangeLinkedQuoteStatusToActive() {

        Account acc = (Account) new SObjectBuilder(Account.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Name => 'Test Account'
            })
            .create()
            .getRecord();

        Contact testContact = (Contact) new SObjectBuilder(Contact.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Contact.AccountId => acc.Id,
                Contact.LastName => 'Doe',
                Contact.FirstName => 'John',
                Contact.Email => 'jg@rc.test',
                Contact.Phone => '1234567890',
                Contact.Preferred_Language__c => 'en_US'
            })
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SOBjectBuilder(Opportunity.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.AccountId => acc.Id,
                Opportunity.Type => 'Syndicated - New',
                Opportunity.StageName => 'Quote',
                Opportunity.CloseDate => System.today().addMonths(1),
                Opportunity.AccountId => acc.Id,
                Opportunity.Primary_Opportunity_Contact__c => testContact.Id
            })
            .create()
            .getRecord();

        Pricebook2 testPriceBook = (Pricebook2) new SObjectBuilder(PriceBook2.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Pricebook2.Line_Range_Min__c => 5,
                Pricebook2.IsActive => true,
                Pricebook2.Service__c => 'Office'
            })
            .create()
            .getRecord();

        Quote testOfficeQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Quote.Name => 'Office Quote',
                Quote.OpportunityId => opp.Id,
                Quote.Pricebook2Id => testPriceBook.Id,
                Quote.CurrencyIsoCode => 'USD',
                Quote.Account__c => acc.Id,
                Quote.Pricebook2Id => testPriceBook.Id,
                Quote.Total_Number_of_Digital_Lines__c => 10,
                Quote.Status => QuoteTriggerHelper.STATUS_EXECUTED,
                Quote.Auto_Renewal__c => true,
                Quote.Initial_Term_months__c => '12',
                Quote.Term_months__c => '12',
                Quote.Start_Date__c => Date.today(),
                Quote.End_Date__c => Date.today()
            })
            .create()
            .getRecord();

        Quote testEngageQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Quote.Name => 'Engage Quote',
                Quote.OpportunityId => opp.Id,
                Quote.Pricebook2Id => testPriceBook.Id,
                Quote.CurrencyIsoCode => 'USD',
                Quote.Account__c => acc.Id,
                Quote.Pricebook2Id => testPriceBook.Id,
                Quote.Total_Number_of_Digital_Lines__c => 10,
                Quote.Status => QuoteTriggerHelper.STATUS_EXECUTED,
                Quote.Auto_Renewal__c => true,
                Quote.Initial_Term_months__c => '12',
                Quote.Term_months__c => '12',
                Quote.Start_Date__c => Date.today(),
                Quote.End_Date__c => Date.today(),
                Quote.ParentQuote__c => testOfficeQuote.Id
            })
            .create()
            .getRecord();

        Test.startTest();

            DSFS__DocuSign_Status__c dsStatus = (DSFS__DocuSign_Status__c) new SObjectBuilder(DSFS__DocuSign_Status__c.SObjectType)
                .setFields(new Map<SObjectField, Object>{
                    DSFS__DocuSign_Status__c.DSFS__Company__c => acc.Id,
                    DSFS__DocuSign_Status__c.DSFS__Opportunity__c => opp.Id,
                    DSFS__DocuSign_Status__c.DFSQ__Quote__c => testEngageQuote.Id,
                    DSFS__DocuSign_Status__c.DSFS__Envelope_Status__c => 'Completed',
                    DSFS__DocuSign_Status__c.DSFS__Completed_Date_Time__c => DateTime.newInstance(2000, 10, 11, 8, 6, 16)
                })
                .create()
                .getRecord();

        Test.stopTest();

        Quote engageQuote = (Quote) new QuoteSelector()
            .selectQuoteById(new List<Object>{testEngageQuote.Id})
            .executeQuery()
            .get(0);

        System.assertEquals(QuoteTriggerHelper.STATUS_ACTIVE, engageQuote.Status, 'Status field on Quote record was not updated as expected');
    }

    @isTest
    static void testGetListChildQuotesId() {

        Account acc = (Account) new SObjectBuilder(Account.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Name => 'Test Account'
            })
            .create()
            .getRecord();

        Contact testContact = (Contact) new SObjectBuilder(Contact.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Contact.AccountId => acc.Id,
                Contact.LastName => 'Doe',
                Contact.FirstName => 'John',
                Contact.Email => 'jg@rc.test',
                Contact.Phone => '1234567890',
                Contact.Preferred_Language__c => 'en_US'
            })
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SOBjectBuilder(Opportunity.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.AccountId => acc.Id,
                Opportunity.Type => 'Syndicated - New',
                Opportunity.StageName => 'Quote',
                Opportunity.CloseDate => System.today().addMonths(1),
                Opportunity.AccountId => acc.Id,
                Opportunity.Primary_Opportunity_Contact__c => testContact.Id
            })
            .create()
            .getRecord();

        Pricebook2 testPriceBook = (Pricebook2) new SObjectBuilder(PriceBook2.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Pricebook2.Line_Range_Min__c => 5,
                Pricebook2.IsActive => true,
                Pricebook2.Service__c => 'Office'
            })
            .create()
            .getRecord();

        Quote testOfficeQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Quote.Name => 'Office Quote',
                Quote.OpportunityId => opp.Id,
                Quote.Pricebook2Id => testPriceBook.Id,
                Quote.CurrencyIsoCode => 'USD',
                Quote.Account__c => acc.Id,
                Quote.Pricebook2Id => testPriceBook.Id,
                Quote.Total_Number_of_Digital_Lines__c => 10,
                Quote.Status => QuoteTriggerHelper.STATUS_EXECUTED,
                Quote.Auto_Renewal__c => true,
                Quote.Initial_Term_months__c => '12',
                Quote.Term_months__c => '12',
                Quote.Start_Date__c => Date.today(),
                Quote.End_Date__c => Date.today()
            })
            .create()
            .getRecord();

        List<Quote> listChildQuotes = DocuSignStatusTriggerHandler.getListChildQuotes(testOfficeQuote.Id);

        System.assertEquals(0, listChildQuotes.size(), 'Method must return Quotes which have Parent Quote');

        Quote testEngageQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Quote.Name => 'Engage Quote2',
                Quote.OpportunityId => opp.Id,
                Quote.Pricebook2Id => testPriceBook.Id,
                Quote.CurrencyIsoCode => 'USD',
                Quote.Account__c => acc.Id,
                Quote.Pricebook2Id => testPriceBook.Id,
                Quote.Total_Number_of_Digital_Lines__c => 10,
                Quote.Status => QuoteTriggerHelper.STATUS_EXECUTED,
                Quote.Auto_Renewal__c => true,
                Quote.Initial_Term_months__c => '12',
                Quote.Term_months__c => '12',
                Quote.Start_Date__c => Date.today(),
                Quote.End_Date__c => Date.today(),
                Quote.ParentQuote__c => testOfficeQuote.Id
            })
            .create()
            .getRecord();

        Test.startTest();

            listChildQuotes = DocuSignStatusTriggerHandler.getListChildQuotes(testOfficeQuote.Id);

        Test.stopTest();

        System.assertEquals(1, listChildQuotes.size(), 'Method must return Quotes which have Parent Quote');
    }

    @isTest
    static void testContractCreation() {

        Account masterAccount = (Account) new SObjectBuilder(Account.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Name => 'Master Account'
            })
            .create()
            .getRecord();
        /* As child account has no contact roles yet - account trigger validation will always fail insert dml */
        Triggers.switchOff();
        Account childAccount = (Account) new SObjectBuilder(Account.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Name => 'Child Account',
                Account.Master_Account__c => masterAccount.Id
            })
            .create()
            .getRecord();
        Triggers.switchOn();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.sObjectType)
            .setField(Opportunity.AccountId, childAccount.Id)
            .create()
            .getRecord();

        Quote q = (Quote) new SObjectBuilder(Quote.sObjectType)
            .setField(Quote.OpportunityId, opp.Id)
            .create()
            .getRecord();

        Quote testEngageQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Quote.Name => 'Engage Quote2',
                Quote.OpportunityId => opp.Id,
                Quote.CurrencyIsoCode => 'USD',
                Quote.Account__c => childAccount.Id,
                Quote.Total_Number_of_Digital_Lines__c => 10,
                Quote.Status => QuoteTriggerHelper.STATUS_EXECUTED,
                Quote.Auto_Renewal__c => true,
                Quote.Initial_Term_months__c => '12',
                Quote.Term_months__c => '12',
                Quote.Start_Date__c => Date.today(),
                Quote.End_Date__c => Date.today(),
                Quote.ParentQuote__c => q.Id
            })
            .create()
            .getRecord();

        Test.startTest();

            DSFS__DocuSign_Status__c dsStatus = (DSFS__DocuSign_Status__c)
                new SObjectBuilder(DSFS__DocuSign_Status__c.SObjectType)
                    .setFields(new Map<SObjectField, Object>{
                        DSFS__DocuSign_Status__c.DSFS__Company__c => masterAccount.Id,
                        DSFS__DocuSign_Status__c.DSFS__Opportunity__c => opp.Id,
                        DSFS__DocuSign_Status__c.DSFS__Envelope_Status__c => 'Completed',
                        DSFS__DocuSign_Status__c.DSFS__Completed_Date_Time__c => DateTime.now(),
                        DSFS__DocuSign_Status__c.dfsq__Quote__c => q.Id
                    })
                    .create()
                    .getRecord();

        Test.stopTest();

        List<Contract> contractList = (List<Contract>) new ContractSelector()
            .selectContracts()
            .executeQuery();

        System.assertEquals(2, contractList.size(), 'Contract for Master and Child accounts should be created');
        /* Both contracts should be active */
        System.assertEquals(DocuSignHelper.CONTRACT_STATUS_ACTIVE, contractList[0].Status, 'Contract should be active');
        System.assertEquals(DocuSignHelper.CONTRACT_STATUS_ACTIVE, contractList[1].Status, 'Contract should be active');

    }

    @isTest
    static void testNewContractTermFlowWithoutActiveContract() {

        Triggers.switchOff();

        new SObjectBuilder(Feature_Toggle__c.SObjectType)
            .setField(Feature_Toggle__c.Enable_new_Contract_Term_flow__c, true)
            .create();

        Triggers.switchOff();
        Map<TestObject, sObject> testObjects = docuSignEnvelopeStatusChangedDataSetup(true);
        Triggers.switchOn();
        Id accountId = (Id)testObjects.get(TestObject.Account).get('Id');
        createTestContracts(accountId, false);

        Triggers.switchOn();

        DSFS__DocuSign_Status__c dsStatus = [SELECT Id FROM DSFS__DocuSign_Status__c LIMIT 1];

        Test.startTest();
            dsStatus.dsfs__Envelope_Status__c = DocuSignHelper.ENVELOPE_STATUS_COMPLETED;
            update dsStatus;
        Test.stopTest();

        List<Contract> reselectedContracts = docuSignValidateTestResult(dsStatus, testObjects);

        Contract activeContract;
        for (Contract con : reselectedContracts) {
            if (con.Status == DocuSignHelper.CONTRACT_STATUS_ACTIVE) {
                activeContract = con;
            }
        }

        Id testQuoteId = (Id) testObjects.get(TestObject.Quote).get('Id');

        Quote reselectedQuote = (Quote) new QuoteSelector()
            .selectQuotes()
            .selectFields(
                new List<Schema.SObjectField>{
                    Quote.Auto_Renewal__c,
                    Quote.Start_Date__c,
                    Quote.End_Date__c,
                    Quote.Term_months__c,
                    Quote.Initial_Term_months__c
                }
            )
            .setCondition('Id = \'' + testQuoteId + '\'')
            .setLimit(1)
            .executeQuery()
            .get(0);

        System.assertEquals(
            reselectedQuote.Auto_Renewal__c,
            activeContract.Auto_Renewal__c,
            'Auto_Renewal__c value should be copied from Quote to Contract'
        );

        System.assertEquals(
            reselectedQuote.Start_Date__c,
            activeContract.Start_Date__c,
            'Start_Date__c value should be copied from Quote to Contract'
        );

        System.assertEquals(
            reselectedQuote.End_Date__c,
            activeContract.End_Date__c,
            'End_Date__c value should be copied from Quote to Contract'
        );

        System.assertEquals(
            QuoteHelper.getNumberFromString(reselectedQuote.Term_months__c),
            activeContract.Renewal_Term__c,
            'Term_months__c value should be copied from Quote to Contract into Renewal_Term__c field'
        );

        System.assertEquals(
            QuoteHelper.getNumberFromString(reselectedQuote.Initial_Term_months__c),
            activeContract.Initial_Term__c,
            'Initial_Term__c value should be copied from Quote to Contract'
        );

        System.assertEquals(
            DocuSignHelper.CONTRACT_STATUS_ACTIVE,
            activeContract.Status,
            'Contract.Status should be "Active"'
        );

        System.assertEquals(
            Date.today(),
            activeContract.Original_Signed_Date__c,
            'Contract.Original_Signed_Date__c should be populated with today date'
        );

        System.assertEquals(
            null,
            activeContract.Previous_Contract__c,
            'For the first Active Contract on Account Previous_Contract__c field should be empty'
        );

        System.assertEquals(
            activeContract.Auto_Renewal__c,
            activeContract.Original_Auto_Renewal__c,
            'For the first Active Contract on Account Original_Auto_Renewal__c should be equal to Auto_Renewal__c'
        );

        System.assertEquals(
            activeContract.Start_Date__c,
            activeContract.Original_Start_Date__c,
            'For the first Active Contract on Account Original_Start_Date__c should be equal to Start_Date__c'
        );

        System.assertEquals(
            activeContract.End_Date__c,
            activeContract.Original_End_Date__c,
            'For the first Active Contract on Account Original_End_Date__c should be equal to End_Date__c'
        );

        System.assertEquals(
            activeContract.Initial_Term__c,
            activeContract.Original_Initial_Term__c,
            'For the first Active Contract on Account Original_Initial_Term__c should be equal to Initial_Term__c'
        );

        System.assertEquals(
            activeContract.Renewal_Term__c,
            activeContract.Original_Renewal_Term__c,
            'For the first Active Contract on Account Original_Renewal_Term__c should be equal to Renewal_Term__c'
        );

        System.assert(
            !activeContract.ContractVersions__r.isEmpty(),
            'ContractVersion__c object should be created'
        );

        ContractVersion__c lastContractVersion = activeContract.ContractVersions__r.get(0);

        System.assertEquals(
            1,
            lastContractVersion.VersionNumber__c,
            'ContractVersion__c.VersionNumber__c should be "1" but got: "' + lastContractVersion.VersionNumber__c + '"'
        );

        System.assertEquals(
            DocuSignStatusTriggerHandler.CONTRACT_VERSION_STATUS_STATUS_ACTIVE,
            lastContractVersion.Status__c,
            'ContractVersion__c.Status__c Should be "Active"'
        );

        System.assertEquals(
            reselectedQuote.Auto_Renewal__c,
            lastContractVersion.AutoRenewal__c,
            'Auto_Renewal__c value should be copied from Quote to ContractVersion__c'
        );

        System.assertEquals(
            reselectedQuote.Start_Date__c,
            lastContractVersion.StartDate__c,
            'Start_Date__c value should be copied from Quote to ContractVersion__c'
        );

        System.assertEquals(
            reselectedQuote.End_Date__c,
            lastContractVersion.EndDate__c,
            'End_Date__c value should be copied from Quote to ContractVersion__c'
        );

        System.assertEquals(
            QuoteHelper.getNumberFromString(reselectedQuote.Term_months__c),
            lastContractVersion.RenewalTerm__c,
            'Term_months__c value should be copied from Quote to ContractVersion__c into RenewalTerm__c field'
        );

        System.assertEquals(
            QuoteHelper.getNumberFromString(reselectedQuote.Initial_Term_months__c),
            lastContractVersion.InitialTerm__c,
            'Initial_Term__c value should be copied from Quote to ContractVersion__c'
        );
    }

    @isTest
    static void testNewContractTermFlowWithActiveContract() {

        Triggers.switchOff();

        new SObjectBuilder(Feature_Toggle__c.SObjectType)
            .setField(Feature_Toggle__c.Enable_new_Contract_Term_flow__c, true)
            .create();

        Triggers.switchOff();
        Map<TestObject, sObject> testObjects = docuSignEnvelopeStatusChangedDataSetup(true);
        Triggers.switchOn();
        Id accountId = (Id)testObjects.get(TestObject.Account).get('Id');
        List<Contract> testContracts = createTestContracts(accountId, true);
        Id activeContractId;
        for (Contract con : testContracts) {
            if (con.Status == DocuSignHelper.CONTRACT_STATUS_ACTIVE) {
                activeContractId = con.Id;
            }
        }
        // create ContractVersion__c for active contract
        insert new ContractVersion__c(
            Contract__c = activeContractId,
            AutoRenewal__c = false,
            StartDate__c = System.today().addMonths(-1),
            EndDate__c = System.today().addMonths(1),
            Status__c = DocuSignStatusTriggerHandler.CONTRACT_VERSION_STATUS_STATUS_ACTIVE,
            VersionNumber__c = 1
        );

        Triggers.switchOn();

        DSFS__DocuSign_Status__c dsStatus = [SELECT Id FROM DSFS__DocuSign_Status__c LIMIT 1];

        Test.startTest();
            dsStatus.dsfs__Envelope_Status__c = DocuSignHelper.ENVELOPE_STATUS_COMPLETED;
            update dsStatus;
        Test.stopTest();

        Id testQuoteId = (Id) testObjects.get(TestObject.Quote).get('Id');

        Quote reselectedQuote = (Quote) new QuoteSelector()
            .selectQuotes()
            .selectFields(
                new List<Schema.SObjectField>{
                    Quote.Auto_Renewal__c,
                    Quote.Start_Date__c,
                    Quote.End_Date__c,
                    Quote.Term_months__c,
                    Quote.Initial_Term_months__c
                }
            )
            .setCondition('Id = \'' + testQuoteId + '\'')
            .setLimit(1)
            .executeQuery()
            .get(0);

        List<Contract> reselectedContracts = docuSignValidateTestResult(dsStatus, testObjects);

        Contract activeContract;
        for (Contract con : reselectedContracts) {
            if (con.Status == DocuSignHelper.CONTRACT_STATUS_ACTIVE) {
                activeContract = con;
            }
        }

        System.assertEquals(
            2,
            activeContract.ContractVersions__r.size(),
            'new ContractVersion__c object should be created'
        );

        ContractVersion__c lastContractVersion = activeContract.ContractVersions__r.get(0);
        ContractVersion__c closedContractVersion = activeContract.ContractVersions__r.get(1);

        System.assertEquals(
            2,
            lastContractVersion.VersionNumber__c,
            'ContractVersion__c.VersionNumber__c should be "2" but got: "' + lastContractVersion.VersionNumber__c + '"'
        );

        System.assertEquals(
            DocuSignStatusTriggerHandler.CONTRACT_VERSION_STATUS_STATUS_ACTIVE,
            lastContractVersion.Status__c,
            'ContractVersion__c.Status__c should be "Active"'
        );

        System.assertEquals(
            reselectedQuote.Auto_Renewal__c,
            lastContractVersion.AutoRenewal__c,
            'AutoRenewal__c value should be copied from Acive SA to new ContractVersion__c'
        );

        System.assertEquals(
            reselectedQuote.Start_Date__c,
            lastContractVersion.StartDate__c,
            'StartDate__c value should be copied from Acive SA to new ContractVersion__c'
        );

        System.assertEquals(
            reselectedQuote.End_Date__c,
            lastContractVersion.EndDate__c,
            'EndDate__c value should be copied from Acive SA to new ContractVersion__c'
        );

        System.assertEquals(
            Decimal.valueOf(reselectedQuote.Term_months__c),
            lastContractVersion.RenewalTerm__c,
            'Term_months__c value should be copied from Acive SA to new ContractVersion__c'
        );

        System.assertEquals(
            Decimal.valueOf(reselectedQuote.Initial_Term_months__c),
            lastContractVersion.InitialTerm__c,
            'Initial_Term__c value should be copied from Acive SA to new ContractVersion__c'
        );

        System.assertEquals(
            DocuSignStatusTriggerHandler.CONTRACT_VERSION_STATUS_AMENDED_AND_CLOSED,
            closedContractVersion.Status__c,
            'previous ContractVersion__c status should be "Amended and Closed" but got "' + closedContractVersion.Status__c + '"'
        );
    }

    @isTest
    static void testNewContractTermFlowContractTermination() {

        Triggers.switchOff();

        new SObjectBuilder(Feature_Toggle__c.SObjectType)
            .setField(Feature_Toggle__c.Enable_new_Contract_Term_flow__c, true)
            .create();

        Triggers.switchOff();
        Map<TestObject, sObject> testObjects = docuSignEnvelopeStatusChangedDataSetup(false);
        Triggers.switchOn();
        Id accountId = (Id)testObjects.get(TestObject.Account).get('Id');
        List<Contract> testContracts = createTestContracts(accountId, true);
        Id activeContractId;
        for (Contract con : testContracts) {
            if (con.Status == DocuSignHelper.CONTRACT_STATUS_ACTIVE) {
                activeContractId = con.Id;
            }
        }
        // create ContractVersion__c for active contract
        insert new ContractVersion__c(
            Contract__c = activeContractId,
            AutoRenewal__c = false,
            StartDate__c = System.today().addMonths(-1),
            EndDate__c = System.today().addMonths(1),
            Status__c = DocuSignStatusTriggerHandler.CONTRACT_VERSION_STATUS_STATUS_ACTIVE,
            VersionNumber__c = 1
        );

        Triggers.switchOn();

        DSFS__DocuSign_Status__c dsStatus = [SELECT Id FROM DSFS__DocuSign_Status__c LIMIT 1];

        Test.startTest();
            dsStatus.dsfs__Envelope_Status__c = DocuSignHelper.ENVELOPE_STATUS_COMPLETED;
            update dsStatus;
        Test.stopTest();

        Id testQuoteId = (Id) testObjects.get(TestObject.Quote).get('Id');

        Quote reselectedQuote = (Quote) new QuoteSelector()
            .selectQuotes()
            .selectFields(
                new List<Schema.SObjectField>{
                    Quote.Auto_Renewal__c,
                    Quote.Start_Date__c,
                    Quote.End_Date__c,
                    Quote.Term_months__c,
                    Quote.Initial_Term_months__c
                }
            )
            .setCondition('Id = \'' + testQuoteId + '\'')
            .setLimit(1)
            .executeQuery()
            .get(0);

        List<Contract> reselectedContracts = docuSignValidateTestResult(dsStatus, testObjects);

        Contract terminatedContract;
        for (Contract con : reselectedContracts) {
            if (con.Status == DocuSignStatusTriggerHandler.CONTRACT_STATUS_TERMINATED) {
                terminatedContract = con;
            }
        }

        System.assert(
            terminatedContract != null,
            'if Quote.Package_Info__c does not contain contract info - active contract should be terminated'
        );

        ContractVersion__c lastContractVersion = terminatedContract.ContractVersions__r.get(0);

        System.assertEquals(
            DocuSignStatusTriggerHandler.CONTRACT_STATUS_TERMINATED,
            lastContractVersion.Status__c,
            'ContractVersion__c.Status__c should be "Terminated"'
        );
    }




    @isTest
    static void testCreateContractForChildAccount() {
        new SObjectBuilder(Feature_Toggle__c.SObjectType)
            .setField(Feature_Toggle__c.Enable_new_Contract_Term_flow__c, true)
            .create();

        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => 'testAcc'
                }
            )
            .create()
            .getRecord();

        Opportunity testOpportunity = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.Name => 'Test Opportunity 2016',
                    Opportunity.Type => 'Syndicated - New',
                    Opportunity.StageName => 'Planning',
                    Opportunity.CloseDate => system.today().addMonths(1),
                    Opportunity.AccountId => acc.Id
                }
            )
            .create()
            .getRecord();
            
        Triggers.switchOff();
        Quote testQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Quote.Name => 'qoutetest',
                    Quote.OpportunityId => testOpportunity.id,
                    Quote.Account__c => acc.Id,
                    Quote.Pricebook2Id => Test.getStandardPricebookId(),
                    Quote.isPrimary__c => true,
                    Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                    Quote.Status => QuoteHelper.QUOTE_STATUS_DRAFT,
                    Quote.Total_Number_of_Digital_Lines__c => 10,
                    Quote.Start_Date__c => Date.today(),
                    Quote.End_Date__c => Date.today(),
                    Quote.Auto_Renewal__c => true,
                    Quote.Term_months__c => '12',
                    Quote.Initial_Term_months__c => '12',
                    Quote.Package_Info__c => '[{"contract": {"id":"someContractId"}}]'
                }
            )
            .create()
            .getRecord();
        Triggers.switchOn();

        Approval__c testAppr = (Approval__c) new SObjectBuilder(Approval__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Approval__c.Status__c => ApprovalHelper.STATUS_COMPLETED,
                    Approval__c.RecordTypeId => ApprovalHelper.RT_ID_ENGAGE_LEGAL,
                    Approval__c.Opportunity__c =>  testOpportunity.Id
                }
            )
            .create()
            .getRecord();

        DSFS__DocuSign_Status__c dsStatus = (DSFS__DocuSign_Status__c) new SObjectBuilder(DSFS__DocuSign_Status__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    DSFS__DocuSign_Status__c.DSFS__Company__c => acc.Id,
                    DSFS__DocuSign_Status__c.DSFS__Opportunity__c => testOpportunity.Id,
                    DSFS__DocuSign_Status__c.DFSQ__Quote__c => testQuote.Id,
                    DSFS__DocuSign_Status__c.DSFS__Completed_Date_Time__c => DateTime.newInstance(2000, 10, 11, 8, 6, 16),
                    DSFS__DocuSign_Status__c.DSFS__Envelope_Status__c => 'Sent'
                }
            )
            .create()
            .getRecord();

        DSFS__DocuSign_Envelope__c testEnvelope = (DSFS__DocuSign_Envelope__c) new SObjectBuilder(DSFS__DocuSign_Envelope__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    DSFS__DocuSign_Envelope__c.dsfs__Source_Object__c => testQuote.Id,
                    DSFS__DocuSign_Envelope__c.dsfs__DocuSign_Envelope_ID__c => '2155d73219918144d3'
                }
            )
            .create()
            .getRecord();

        DSFS__DocuSign_Envelope_Recipient__c recipient = (DSFS__DocuSign_Envelope_Recipient__c) new SObjectBuilder(DSFS__DocuSign_Envelope_Recipient__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    DSFS__DocuSign_Envelope_Recipient__c.dsfs__DocuSign_EnvelopeID__c => testEnvelope.Id
                }
            )
            .create()
            .getRecord();

        DSFS__DocuSign_Recipient_Status__c recipientStatus = (DSFS__DocuSign_Recipient_Status__c) new SObjectBuilder(DSFS__DocuSign_Recipient_Status__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    DSFS__DocuSign_Recipient_Status__c.Name => 'John Doe',
                    DSFS__DocuSign_Recipient_Status__c.dsfs__Parent_Status_Record__c => dsStatus.Id,
                    DSFS__DocuSign_Recipient_Status__c.dsfs__Recipient_Status__c => ApprovalHelper.STATUS_COMPLETED,
                    DSFS__DocuSign_Recipient_Status__c.dsfs__DocuSign_Recipient_Id__c => recipient.Id
                }
            )
            .create()
            .getRecord();

        Test.startTest();
            Attachment testAttach = new Attachment(Name = 'Unit Test Attachment', ParentId = dsStatus.Id);
            Blob bodyBlob = Blob.valueOf('Body');
            testAttach.Body = bodyBlob;
            insert testAttach;
            createTestContracts(acc.Id, false);
            
            /* As child account has no contact roles yet - account trigger validation will always fail insert dml */
            Triggers.switchOff();
            Account childAcc = (Account) new SObjectBuilder(Account.SObjectType)
                .setFields(new Map<SObjectField, Object>{
                    Account.Name => ValueProviderBuilder.provideUniqueString('ChildAccount'),
                    Account.Master_Account__c => acc.Id
                })
                .create()
                .getRecord();
            Triggers.switchOn();
            dsStatus.dsfs__Envelope_Status__c = DocuSignHelper.ENVELOPE_STATUS_COMPLETED;
            update dsStatus;
        Test.stopTest();

        List<Contract> reselectedContracts = new ContractSelector()
            .selectActiveContractsByAccountId(new Set<Id>{acc.Id, childAcc.Id})
            .executeQuery();

        System.assertEquals(2, reselectedContracts.size(), '2 Contract should be Created');

        Map<Id, Contract> accountIdToContractMap = new Map<Id, Contract>();
        for (Contract con : reselectedContracts) {
            System.assertEquals(con.Status, 'Active', 'created contracts should be "Active"');
            accountIdToContractMap.put(con.AccountId, con);
        }

        System.assert(accountIdToContractMap.containsKey(childAcc.Id));
        System.assert(accountIdToContractMap.containsKey(acc.Id));
    }

    @isTest
    static void testAccountNdaStatusPopulated() {
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(Account.SObjectType))
            .create()
            .getRecord();

        dsfs__DocuSign_Status__c env = (dsfs__DocuSign_Status__c) new SObjectBuilder(dsfs__DocuSign_Status__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                dsfs__DocuSign_Status__c.dsfs__Company__c => acc.Id,
                dsfs__DocuSign_Status__c.dsfs__DocuSign_Envelope_ID__c => '2155d73219918144d3',
                dsfs__DocuSign_Status__c.dsfs__Envelope_Status__c => DocuSignHelper.ENVELOPE_STATUS_SENT
            })
            .create()
            .getRecord();

        Attachment att = (Attachment) new SObjectBuilder(Attachment.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Attachment.Name => 'Non-Disclosure Agreement for Test Account 2020-01-01 00:00:00.pdf',
                Attachment.Body => EncodingUtil.base64Decode('Body'),
                Attachment.ParentId => env.Id
            })
            .create()
            .getRecord();

        env.dsfs__Envelope_Status__c = 'Completed';
        update env;

        Account updatedAcc = (Account) new AccountSelector()
            .selectAccountById(acc.Id)
            .selectField('NdaStatus__c')
            .executeQuery()
            .get(0);

        System.assertEquals(AccountHelper.DOCUSIGN_TO_NDA_STATUS.get(env.dsfs__Envelope_Status__c),
            updatedAcc.NdaStatus__c,
            'NdaStatus__c on Account should be \'Signed by Customer\'');

        env.dsfs__Envelope_Status__c = 'Expired';
        update env;

        updatedAcc = (Account) new AccountSelector()
            .selectAccountById(acc.Id)
            .selectField('NdaStatus__c')
            .executeQuery()
            .get(0);

        System.assertEquals(AccountHelper.DOCUSIGN_TO_NDA_STATUS.get(env.dsfs__Envelope_Status__c),
            updatedAcc.NdaStatus__c,
            'NdaStatus__c on Account should be \'Voided\'');

        env.dsfs__Envelope_Status__c = 'Voided';
        update env;

        updatedAcc = (Account) new AccountSelector()
            .selectAccountById(acc.Id)
            .selectField('NdaStatus__c')
            .executeQuery()
            .get(0);

        System.assertEquals(AccountHelper.DOCUSIGN_TO_NDA_STATUS.get(env.dsfs__Envelope_Status__c),
            updatedAcc.NdaStatus__c,
            'NdaStatus__c on Account should be \'Voided by RingCentral\'');

        env.dsfs__Envelope_Status__c = 'Declined';
        update env;

        updatedAcc = (Account) new AccountSelector()
            .selectAccountById(acc.Id)
            .selectField('NdaStatus__c')
            .executeQuery()
            .get(0);

        System.assertEquals(AccountHelper.DOCUSIGN_TO_NDA_STATUS.get(env.dsfs__Envelope_Status__c),
            updatedAcc.NdaStatus__c,
            'NdaStatus__c on Account should be \'Voided by Customer\'');
    }
}