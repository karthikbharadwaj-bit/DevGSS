@isTest
private class Test_SendWithDocuSign {
	private static Account testAcc;
	private static Opportunity testOpp;

	private static void createTestData() {
		testAcc = new Account(Name = 'testAcc');
		insert testAcc;
		testOpp = new Opportunity(Name = 'testOpp', AccountId = testAcc.Id, StageName = '1. Qualify');
		insert testOpp;
	}

	@isTest
	static void test_Validation_NoQuotes() {
		
		createTestData();
		Test.startTest();
			String errors = SendWithDocuSign.processData(testOpp.Id, null);
			List<SendWithDocuSign.ErrorWrapper> errorMessagesList  = (List<SendWithDocuSign.ErrorWrapper>)JSON.deserialize(errors, List<SendWithDocuSign.ErrorWrapper>.class);
		Test.stopTest();
		System.assertEquals(1, errorMessagesList.size());
		System.assertEquals('Send with DocuSign Error', errorMessagesList[0].header);
		System.assertEquals('To send with DocuSign you must have at least one Quote on the Opportunity', errorMessagesList[0].message);
	}

	@isTest
	static void test_Validation_HasActiveQuote() {

		createTestData();
		Quote testQuote = new Quote (Name='testQuote',
            OpportunityId = testOpp.Id,
            Pricebook2Id = Test.getStandardPricebookId(), 
            RecordTypeId = QuoteHelper.RT_ID_SALES,
            Start_Date__c = System.today(),
            End_Date__c = System.today(),
            Status = QuoteHelper.QUOTE_STATUS_ACTIVE);
        insert testQuote;

		Test.startTest();
			String errors = SendWithDocuSign.processData(testOpp.Id, null);
			List<SendWithDocuSign.ErrorWrapper> errorMessagesList  = (List<SendWithDocuSign.ErrorWrapper>)JSON.deserialize(errors, List<SendWithDocuSign.ErrorWrapper>.class);
		Test.stopTest();
		System.assertEquals(1, errorMessagesList.size());
		System.assertEquals('Send with DocuSign Error', errorMessagesList[0].header);
		System.assertEquals('Active Agreement already exists under this Opportunity', errorMessagesList[0].message);
	}

	@isTest
	static void test_Validation_NoPrimaryQuote() {

		createTestData();
		Quote testQuote = new Quote (Name='testQuote',
            OpportunityId = testOpp.Id,
            Pricebook2Id = Test.getStandardPricebookId(),
            RecordTypeId = QuoteHelper.RT_ID_BILLING);
        insert testQuote;

		Test.startTest();
			String errors = SendWithDocuSign.processData(testOpp.Id, null);
			List<SendWithDocuSign.ErrorWrapper> errorMessagesList  = (List<SendWithDocuSign.ErrorWrapper>)JSON.deserialize(errors, List<SendWithDocuSign.ErrorWrapper>.class);
		Test.stopTest();
		System.assertEquals(1, errorMessagesList.size());
		System.assertEquals('Send with DocuSign Error', errorMessagesList[0].header);
		System.assertEquals('There is no appropriate primary Quote under this Opportunity', errorMessagesList[0].message);
	}

	@isTest
	static void test_Validation_NotReadyForDocusign() {

		createTestData();
		Quote testQuote = new Quote (Name='testQuote',
            OpportunityId = testOpp.Id,
            Pricebook2Id = Test.getStandardPricebookId(),
            QuoteType__c = QuoteHelper.QUOTE_TYPE_QUOTE,
            Approved_Status__c = 'Required',
            RecordTypeId = QuoteHelper.RT_ID_SALES);
        insert testQuote;

		Test.startTest();
			String errors = SendWithDocuSign.processData(testOpp.Id, null);
			List<SendWithDocuSign.ErrorWrapper> errorMessagesList  = (List<SendWithDocuSign.ErrorWrapper>)JSON.deserialize(errors, List<SendWithDocuSign.ErrorWrapper>.class);
		Test.stopTest();
		System.assertEquals(1, errorMessagesList.size());
		System.assertEquals('Send with DocuSign Error', errorMessagesList[0].header);
		System.assertEquals('Primary Quote should be in \'Agreement\' stage and has \'Approved\' or \'Not Required\' approved status in order to be sent with DocuSign', errorMessagesList[0].message);
	}

	@isTest
	static void test_Validation_WrongBillingAddress() {

		createTestData();
		Quote testQuote = new Quote (Name='testQuote',
            OpportunityId = testOpp.Id,
            Pricebook2Id = Test.getStandardPricebookId(),
            QuoteType__c = QuoteHelper.QUOTE_TYPE_AGREEMENT,
            Approved_Status__c = 'Approved',
            Special_Terms__c = '1 Free Month',
            Billing_City__c = 'testCity',
            Billing_Zip_Postal_Code__c = 'testPostalCode',
            Billing_Country__c = 'testCountry',
            Billing_State_Province__c = 'testState',
            Billing_Street__c = 'testStreet',
            RecordTypeId = QuoteHelper.RT_ID_SALES);
        insert testQuote;

		Test.startTest();
			String errors = SendWithDocuSign.processData(testOpp.Id, null);
			List<SendWithDocuSign.ErrorWrapper> errorMessagesList  = (List<SendWithDocuSign.ErrorWrapper>)JSON.deserialize(errors, List<SendWithDocuSign.ErrorWrapper>.class);
		Test.stopTest();
		System.assertEquals(1, errorMessagesList.size());
		System.assertEquals('Send with DocuSign Error', errorMessagesList[0].header);
		System.assertEquals('Taxes were requested for the Address that doesn\'t match Billing Address on the Account. Please change Quote Stage to Quote, remove and add Taxes for new Account Billing Address', errorMessagesList[0].message);
	}

    @isTest
    private static void testgetSelectedPrimaryQuoteWithNGBSQuote() {

        Account billingAcc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Billing_ID__c => ValueProviderBuilder.provideUniqueString()
            })
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.AccountId => billingAcc.Id,
                Opportunity.Is_Billing_Opportunity__c => true
            })
            .create()
            .getRecord();

        Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.OpportunityId => opp.Id,
                Quote.RecordTypeId => QuoteHelper.RT_ID_POC,
                Quote.isPrimary__c => true
            })
            .create()
            .getRecord();
        qt.Opportunity = opp;

        List<Quote> qts = (List<Quote>) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.OpportunityId => opp.Id,
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.isPrimary__c => false
            })
            .quantity(2)
            .create()
            .getRecords();
        qts.add(qt);

        Test.startTest();

            Quote testQuote = SendWithDocuSign.getSelectedPrimaryQuote(qts, qt.Id);

        Test.stopTest();

        System.assertNotEquals(
            null,
            testQuote,
            'Quote has not been retrieved.'
        );

        System.assertEquals(
            qt.Id,
            testQuote.Id,
            'Incorrect primary NGBS Quote.'
        );
    }

    @isTest
    private static void testgetSelectedPrimaryQuoteWOQuoteId() {

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.AccountId => ValueProviderBuilder.provideCommonParent(Account.SObjectType),
                Opportunity.Is_Billing_Opportunity__c => false
            })
            .create()
            .getRecord();

        Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.OpportunityId => opp.Id,
                Quote.RecordTypeId => QuoteHelper.RT_ID_SALES,
                Quote.isPrimary__c => true
            })
            .create()
            .getRecord();

        List<Quote> qts = (List<Quote>) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.OpportunityId => opp.Id,
                Quote.RecordTypeId => QuoteHelper.RT_ID_SALES,
                Quote.isPrimary__c => false
            })
            .quantity(3)
            .create()
            .getRecords();
        qts.add(qt);

        Test.startTest();

            Quote testQuote = SendWithDocuSign.getSelectedPrimaryQuote(qts, null);

        Test.stopTest();

        System.assertNotEquals(
            null,
            testQuote,
            'Quote has not been retrieved.'
        );

        System.assertEquals(
            qt.Id,
            testQuote.Id,
            'Incorrect primary Sales Quote.'
        );
    }

    @isTest
    private static void testgetSelectedPrimaryQuoteWithSalesQuote() {

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.AccountId => ValueProviderBuilder.provideCommonParent(Account.SObjectType),
                Opportunity.Is_Billing_Opportunity__c => false
            })
            .create()
            .getRecord();

        Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.OpportunityId => opp.Id,
                Quote.RecordTypeId => QuoteHelper.RT_ID_SALES,
                Quote.isPrimary__c => true
            })
            .create()
            .getRecord();

        List<Quote> qts = (List<Quote>) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.OpportunityId => opp.Id,
                Quote.RecordTypeId => QuoteHelper.RT_ID_SALES,
                Quote.isPrimary__c => false
            })
            .quantity(3)
            .create()
            .getRecords();
        qts.add(qt);

        Test.startTest();

            Quote testQuote = SendWithDocuSign.getSelectedPrimaryQuote(qts, qt.Id);

        Test.stopTest();

        System.assertNotEquals(
            null,
            testQuote,
            'Quote has not been retrieved.'
        );

        System.assertEquals(
            qt.Id,
            testQuote.Id,
            'Incorrect primary Sales Quote.'
        );
    }
}