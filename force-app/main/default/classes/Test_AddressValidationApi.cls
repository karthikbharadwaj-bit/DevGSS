@isTest
public with sharing class Test_AddressValidationApi {
	@isTest
    static void test_ValidateAddress_AddressRequestData() {
    	insert new RingCentralVariousSettings__c (Address_Validation_API_Endpoint__c = 'https://testapi/');

    	AddressValidationApi.AddressRequestItem testAddressItem1 = new AddressValidationApi.AddressRequestItem(
			'1',
			'123 NIMBUS RD',
			'123 NIMBUS RD',
			'HOLBROOK',
			'NY',
			'11741',
			'USA'
		);
		AddressValidationApi.AddressRequestItem testAddressItem2 = new AddressValidationApi.AddressRequestItem(
			'2',
			'2001 cross pl',
			'',
			'regina',
			'SK',
			's4s 4c8',
			'USA'
		);
		AddressValidationApi.AddressRequestItem testAddressItem3 = new AddressValidationApi.AddressRequestItem(
			'3',
			'402 E Gutierrez St.',
			'',
			'Santa Barbara',
			'California',
			'93101',
			'USA'
		);

    	Test.startTest();
    		AddressValidationApi.mockJsonResponce = '{"response":{"addressStandardizationResponse":[{"seqId":"1","address":"123NIMBUSRD,HOLBROOK,NY11741-4433","adressLine":"123NIMBUSRD","addressQualityFlags":"S4","carrierRoute":"C007","city":"HOLBROOK","cityStateZip":"HOLBROOK,NY11741-4433","countyCode":"103","deliveryPointValidation":"3","enhancedLineOfTravel":"0","reliability":"100","state":"NY","pcode":"2664600","zip":"11741","zip4":"4433","addressFault":null},{"seqId":"2","address":null,"adressLine":null,"addressQualityFlags":null,"carrierRoute":null,"city":null,"cityStateZip":null,"countyCode":"0","deliveryPointValidation":null,"enhancedLineOfTravel":null,"reliability":null,"state":null,"pcode":"5082200","zip":null,"zip4":null,"addressFault":null},{"seqId":"3","address":"402EGUTIERREZST,SANTABARBARA,CA93101-1709","adressLine":"402EGUTIERREZST","addressQualityFlags":"S4","carrierRoute":"C047","city":"SANTABARBARA","cityStateZip":"SANTABARBARA,CA93101-1709","countyCode":"83","deliveryPointValidation":"3","enhancedLineOfTravel":"0","reliability":"100","state":"CA","pcode":"386500","zip":"93101","zip4":"1709","addressFault":null}]}}';
    		Test.setMock(HttpCalloutMock.class, new AddressValidationApi());
    		
    		Map<String, AddressValidationApi.AddressResponseItem> responseMap = AddressValidationApi.validateAddresses(new List<AddressValidationApi.AddressRequestItem>{testAddressItem1, testAddressItem2, testAddressItem3});
    	Test.stopTest();
    	System.assertEquals(3, responseMap.size());
    	for(AddressValidationApi.AddressResponseItem item : responseMap.values()) {
    		System.assertEquals(null, item.addressFault);
    	}
    }

    @isTest
    static void test_ValidateAddress_PhaseLineItems() {
    	insert new RingCentralVariousSettings__c (Address_Validation_API_Endpoint__c = 'https://testapi/');
    	Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

    	Opportunity opp = new Opportunity(
    		Name = 'Test Opportunity',
    		StageName = 'Qualify',
    		AccountId = testAccount.Id);
        insert opp;

        Quote testQuote = new Quote (
                Name = 'Test Quote',
                OpportunityId = opp.id,
                Pricebook2Id = Test.getStandardPricebookId()
        );
        insert testQuote;

        Product2 testProduct1 = new Product2(
            Name = 'testProduct1',
            Family = 'Office',
            IsActive = true,
            Sub_Category__c = 'Main'
        );
	    Product2 testProduct2 = new Product2(
	        Name = 'testProduct2',
	        Family = 'Office',
	        IsActive = true,
	        Sub_Category__c = 'Main'
	    );
	    Product2 testProduct3 = new Product2(
	        Name = 'testProduct3',
	        Family = 'Office',
	        IsActive = true,
	        Sub_Category__c = 'Main'
	    );
	    insert (new List<Product2>{testProduct1, testProduct2, testProduct3});


        PricebookEntry testPbe1 = new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(),
            Product2Id = testProduct1.Id,
            UnitPrice = 100, 
            IsActive = true,
            UseStandardPrice = false,
            Per_Line__c = false,
            Min_Quantity__c = 1,
            Max_Quantity__c = 100
        );
        PricebookEntry testPbe2 = new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(),
            Product2Id = testProduct2.Id,
            UnitPrice = 100, 
            IsActive = true,
            UseStandardPrice = false,
            Per_Line__c = false,
            Min_Quantity__c = 1,
            Max_Quantity__c = 100
        );
        PricebookEntry testPbe3 = new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(),
            Product2Id = testProduct3.Id,
            UnitPrice = 100, 
            IsActive = true,
            UseStandardPrice = false,
            Per_Line__c = false,
            Min_Quantity__c = 1,
            Max_Quantity__c = 100
        );
        insert (new List<PricebookEntry>{testPbe1, testPbe2, testPbe3});


        QuoteLineItem testQuoteLineItem1 = new QuoteLineItem (
            UnitPrice = testPbe1.UnitPrice,
            Quantity = 5,
            QuoteId = testQuote.Id,
            PriceBookEntryId = testPbe1.Id,
            Product2Id = testProduct1.Id
        );

        QuoteLineItem testQuoteLineItem2 =  new QuoteLineItem (
            UnitPrice = testPbe2.UnitPrice,
            Quantity = 5,
            QuoteId = testQuote.Id,
            PriceBookEntryId = testPbe2.Id,
			Product2Id = testProduct2.Id
        );

        QuoteLineItem testQuoteLineItem3 =  new QuoteLineItem (
            UnitPrice = testPbe3.UnitPrice,
            Quantity = 5,
            QuoteId = testQuote.Id,
            PriceBookEntryId = testPbe3.Id,
			Product2Id = testProduct3.Id
        );
        insert (new List<QuoteLineItem>{testQuoteLineItem1, testQuoteLineItem2, testQuoteLineItem3});

        Id proServPhaseRTId =  Phase__c.SObjectType.getDescribe().getRecordTypeInfosByName().get('ProServ Phase').getRecordTypeId();

        Phase__c testPhase = new Phase__c(
            Name = 'testPhase1',
            Opportunity__c = opp.Id,
            Quote__c = testQuote.Id,
            RecordTypeId = proServPhaseRTId
        );
        insert testPhase;

        Hardware_Line_Item__c testPli1 = new Hardware_Line_Item__c(
			Name = 'testPLI1',
            Quantity__c = 2,
            Quote_Line_Item__c = testQuoteLineItem1.Id,
            Address_Line__c = '123 NIMBUS RD',
            City__c = 'HOLBROOK',
            Country__c = 'USA',
            State__c = 'NY',
            Postal_Code__c = '11741',
            RingCentral_Hardware_Phase__c = testPhase.Id
		);

		Hardware_Line_Item__c testPli2 = new Hardware_Line_Item__c(
			Name = 'testPLI2',
            Quantity__c = 2,
            Quote_Line_Item__c = testQuoteLineItem2.Id,
            Address_Line__c = '2001 cross pl',
            City__c = 'regina',
            Country__c = 'USA',
            State__c = 'SK',
            Postal_Code__c = 's4s 4c8',
            RingCentral_Hardware_Phase__c = testPhase.Id
		);
		Hardware_Line_Item__c testPli3 = new Hardware_Line_Item__c(
			Name = 'testPLI3',
            Quantity__c = 2,
            Quote_Line_Item__c = testQuoteLineItem3.Id,
            Address_Line__c = '402 E Gutierrez St.',
            City__c = 'Santa Barbara',
            Country__c = 'USA',
            State__c = 'California',
            Postal_Code__c = '93101',
            RingCentral_Hardware_Phase__c = testPhase.Id
		);
		insert (new List<Hardware_Line_Item__c>{testPli1, testPli2, testPli3});


    	Test.startTest();
    		AddressValidationApi.mockJsonResponce = '{"response":{"addressStandardizationResponse":[{"seqId":"1","address":"123NIMBUSRD,HOLBROOK,NY11741-4433","adressLine":"123NIMBUSRD","addressQualityFlags":"S4","carrierRoute":"C007","city":"HOLBROOK","cityStateZip":"HOLBROOK,NY11741-4433","countyCode":"103","deliveryPointValidation":"3","enhancedLineOfTravel":"0","reliability":"100","state":"NY","pcode":"2664600","zip":"11741","zip4":"4433","addressFault":null},{"seqId":"2","address":null,"adressLine":null,"addressQualityFlags":null,"carrierRoute":null,"city":null,"cityStateZip":null,"countyCode":"0","deliveryPointValidation":null,"enhancedLineOfTravel":null,"reliability":null,"state":null,"pcode":"5082200","zip":null,"zip4":null,"addressFault":null},{"seqId":"3","address":"402EGUTIERREZST,SANTABARBARA,CA93101-1709","adressLine":"402EGUTIERREZST","addressQualityFlags":"S4","carrierRoute":"C047","city":"SANTABARBARA","cityStateZip":"SANTABARBARA,CA93101-1709","countyCode":"83","deliveryPointValidation":"3","enhancedLineOfTravel":"0","reliability":"100","state":"CA","pcode":"386500","zip":"93101","zip4":"1709","addressFault":null}]}}';
    		Test.setMock(HttpCalloutMock.class, new AddressValidationApi());


    		Map<String, AddressValidationApi.AddressResponseItem> result = AddressValidationApi.validateAddresses(new List<Hardware_Line_Item__c>{testPli1, testPli2, testPli3});
    	Test.stopTest();
    	System.assertNotEquals(null, result);
    	System.assertEquals(3, result.size());
    	for(AddressValidationApi.AddressResponseItem item : result.values()) {
    		System.assertEquals(null, item.addressFault);
    	}
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testCreateInstances() {
    	AddressValidationApi.SFDCRequestDTO requestWrapper = new AddressValidationApi.SFDCRequestDTO(null);
    	AddressValidationApi.AddressRequest addressRequestWrapper = new AddressValidationApi.AddressRequest(null);
    	AddressValidationApi.AddressRequestItem addressRequestItemWrapper = new AddressValidationApi.AddressRequestItem(null, null, null, null, null, null, null);
    	AddressValidationApi.SFDCResponseDTO responseWrapper = new AddressValidationApi.SFDCResponseDTO (null);
    	AddressValidationApi.AddressResponse addressResponseWrapper = new AddressValidationApi.AddressResponse(null);
    	AddressValidationApi.AddressResponseItem addressResponseItemWrapper = new AddressValidationApi.AddressResponseItem(null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null);
    }
}