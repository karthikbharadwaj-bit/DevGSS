@isTest
private class ApprovalDefaultsTest
{
	//test's poorly written because the page itself's bad. No point in writing good tests for it.
    private static String responseAddress = '{"label":"test",' +
                '"firstName":"test","lastName":"test",' +
                '"phone":null,"street1":"test","street2":"test",' +
                '"city":"test","county":"test","state":"test",' +
                '"zip": "12313", "country": "USA"}';

    private static String billingIdentitiesResponse = '[{"id": 1,"name": "RingCentral, Ltd (France)",' +
            '"address": {"label": null,"firstName": "RingCentral France","lastName": "",' +
            '"phone": "","street1": "3-5 rue Saint Georges","street2": "",' +
            '"city": "Paris","county": "","state": "","zip": "75009","country": "FRA"},' +
            '"isDefault": true}]';

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
	static void itShould()
	{
		Account acc = new Account(Name='goodAcc', BillingCountry = 'United States', BillingCity = 'NY',
				BillingState = 'NY', BillingStreet = '1st', BillingPostalCode = '123');
		insert acc;
		Opportunity opp = new Opportunity(AccountId = acc.Id, Name = 'goodOpp', StageName = '1. Draft');
		insert opp;

		Test.startTest();
		//setting settings for page
		Test.setCurrentPageReference(new PageReference('Page.ApprovalDefaults'));
		System.currentPageReference().getParameters().put('RecordType',
            Schema.SObjectType.Approval__c.getRecordTypeInfosByName().get('Feature Add-Ons').getRecordTypeId());//Farming Claim Owner
		System.currentPageReference().getParameters().put('CF00N80000004iCmz_lkid', acc.Id);//Farming Claim Owner

		ApexPages.StandardController sc = new ApexPages.StandardController(new Approval__c());
		Approvaldefaults ad = new ApprovalDefaults(sc);

		Test.stopTest();
	}

    @isTest
	static void testInvoiceApprovalDefaults()
	{
		Account acc = new Account(
            Name='goodAcc', Payment_Method__c = AccountHelper.PAYMENT_METHOD_INVOICE,
            BillingCountry = 'United States', BillingCity = 'NY', BillingState = 'NY', BillingStreet = '1st', BillingPostalCode = '123',
            Monthly_Credit_Limit__c = 100, Sign_up_purchase_limit__c = 1000,
            Payment_Terms__c = '3', Invoice_Terms__c = '7'
        );
		insert acc;

		Opportunity opp = new Opportunity(AccountId = acc.Id, Name = 'goodOpp', StageName = '1. Draft');
		insert opp;

		Test.startTest();
		//setting settings for page
		Test.setCurrentPageReference(new PageReference('Page.ApprovalDefaults'));
		System.currentPageReference().getParameters().put('CF00N80000004iCmz_lkid', acc.Id);
        ApprovalHelperCls.describeRecordTypesById();
        System.currentPageReference().getParameters().put(
            'RecordType',
            ApprovalHelperCls.rtMapByID.get(ApprovalHelper.INVOICING_REQUEST_APPROVAL_RT_NAME).getRecordTypeId()
        );

		ApexPages.StandardController sc = new ApexPages.StandardController(new Approval__c());
		Approvaldefaults ad = new ApprovalDefaults(sc);

        PageReference approvalPage = ad.actapprovalObject();
        // Monthly_Credit_Limit__c
        System.assertEquals(
            Decimal.valueOf(approvalPage.getParameters().get(HardcodedIdsMapper.getMatchedObjectId('00N80000004j6pe'))),
            acc.Monthly_Credit_Limit__c,
            'value should be defaulted'
        );
        // Sign_up_purchase_limit__c
        System.assertEquals(
            Decimal.valueOf(approvalPage.getParameters().get(HardcodedIdsMapper.getMatchedObjectId('00N80000004j6pU'))),
            acc.Sign_up_purchase_limit__c,
            'value should be defaulted'
        );
        // Payment_Terms__c
        System.assertEquals(
            approvalPage.getParameters().get(HardcodedIdsMapper.getMatchedObjectId('00N80000004jB6A')),
            acc.Payment_Terms__c,
            'value should be defaulted'
        );
        // Invoice_Terms__c
        System.assertEquals(
            approvalPage.getParameters().get(HardcodedIdsMapper.getMatchedObjectId('00N80000005H5ND')),
            acc.Invoice_Terms__c,
            'value should be defaulted'
        );

		Test.stopTest();
	}

    @isTest static void testMonthlyRecurringRevenue(){

        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(Account.SObjectType))
            .setField(Account.BillingStreet, 'Lenin')
            .setField(Account.BillingCity, 'Chicago')
            .setField(Account.BillingState, 'Alabama')
            .setField(Account.BillingPostalCode, '12345')
            .setField(Account.BillingCountry, 'AUT')
            .setField(Account.Billing_System__c, AccountHelper.BILLING_SYSTEM_NBS)
            .setField(Account.Billing_ID__c, '123456')
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setField(Opportunity.RecordTypeId, OpportunityHelper.RT_ID_NEW_SALES_OPPORTUNITY)
            .setField(Opportunity.Brand_Name__c, OpportunityHelper.BRAND_RINGCENTRAL_EU)
            .setField(Opportunity.AccountId, acc.Id)
            .create()
            .getRecord();

        Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.Name => ValueProviderBuilder.provideUniqueString('Test Billing Quote'),
                Quote.OpportunityId => opp.Id,
                Quote.Account__c => acc.Id,
                Quote.Status => QuoteHelper.QUOTE_STATUS_DRAFT,
                Quote.Approved_Status__c => QuoteHelper.APPROVAL_STATUS_NOT_REQUIRED,
                Quote.Total_Number_of_Digital_Lines__c => 1,
                Quote.Start_Date__c => Date.today(),
                Quote.End_Date__c => Date.today().addDays(2),
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.Pricebook2Id => Test.getStandardPricebookId()
            })
            .create()
            .getRecord();

        Test.startTest();
            Approval__c appr = (Approval__c) new SObjectBuilder(Approval__c.SObjectType)
                .setFields(new Map<SObjectField, Object>{
                    Approval__c.Quote__c => qt.Id,
                    Approval__c.Opportunity__c => qt.OpportunityId,
                    Approval__c.Account__c => qt.Account__c
                })
                .build()
                .getRecord();

            ApexPages.StandardController sc = new ApexPages.StandardController(appr);

            Boolean hasError = false;
            String errorMessage = '';
            try{
                Approvaldefaults ad = new Approvaldefaults(sc);
            }
            catch(Exception ex){
                hasError = true;
                errorMessage = ex.getMessage() + '\\n' + ex.getStackTraceString();
            }
            system.assert(!hasError, 'Error should not occur: ' + errorMessage);
        Test.stopTest();
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest static void testCheckRecordTypeWithAddress(){
        Test.setMock(HttpCalloutMock.class, new MockBusinessIdentitites());
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(Account.SObjectType))
            .setField(Account.CurrencyIsoCode, 'EUR')
            .setField(Account.BillingStreet, 'Lenin')
            .setField(Account.BillingCity, 'Chicago')
            .setField(Account.BillingState, 'Alabama')
            .setField(Account.BillingPostalCode, '12345')
            .setField(Account.BillingCountry, 'AUT')
            .setField(Account.Billing_System__c, AccountHelper.BILLING_SYSTEM_NBS)
            .setField(Account.Billing_ID__c, '123456')
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setField(Opportunity.CurrencyIsoCode, 'EUR')
            .setField(Opportunity.RecordTypeId, OpportunityHelper.RT_ID_NEW_SALES_OPPORTUNITY)
            .setField(Opportunity.Brand_Name__c, OpportunityHelper.BRAND_RINGCENTRAL_EU)
            .setField(Opportunity.AccountId, acc.Id)
            .create()
            .getRecord();

        new SObjectBuilder(NGBS_Settings__c.SObjectType)
            .setField(NGBS_Settings__c.BaseEndpoint__c, 'http://185.23.251.118:8080')
            .setField(NGBS_Settings__c.AccountManagerPath__c, '/restapi/account-manager/v1.0')
            .setField(NGBS_Settings__c.Login__c, 'login')
            .setField(NGBS_Settings__c.Password__c, 'password')
            .create();

        Test.startTest();
        Approval__c app = new Approval__c(
            RecordTypeId = ApprovalHelper.RT_ID_TAX_EXEMPT_APPROVAL,
            Status__c = ApprovalHelper.STATUS_NEW,
            Opportunity__c = opp.Id);
        ApexPages.StandardController sc = new ApexPages.StandardController(app);
        Approvaldefaults ad = new Approvaldefaults(sc);
        System.debug('checkMsin: ' + ad);
        // System.assertEquals(null, ad.checkRecordType());
        Test.stopTest();
    }

    @isTest static void testCheckRecordTypeWithoutAddress(){
        Test.setMock(HttpCalloutMock.class, new MockBusinessIdentitites());

        List<CountryCodes__c> cc = (List<CountryCodes__c>) new SObjectBuilder(CountryCodes__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                CountryCodes__c.Name => ValueProviderBuilder.provideList(new List<String> {'FRA', 'USA'}),
                CountryCodes__c.CountryName__c => ValueProviderBuilder.provideList(new List<String> {'fra;france', 'usa;united states'}),
                CountryCodes__c.CountryNameFull__c => ValueProviderBuilder.provideList(new List<String> {'France', 'United States'}),
                CountryCodes__c.CountryNameShort__c => ValueProviderBuilder.provideList(new List<String> {'FR','US'})
            })
            .quantity(2)
            .create()
            .getRecords();

        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(Account.SObjectType))
            .setField(Account.BillingStreet, 'Lenin')
            .setField(Account.BillingCity, 'Chicago')
            .setField(Account.BillingState, 'Alabama')
            .setField(Account.BillingPostalCode, '12345')
            .setField(Account.BillingCountry, 'USA')
            .setField(Account.Billing_System__c, AccountHelper.BILLING_SYSTEM_NBS)
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setField(Opportunity.RecordTypeId, OpportunityHelper.RT_ID_NEW_SALES_OPPORTUNITY)
            .setField(Opportunity.Brand_Name__c, OpportunityHelper.BRAND_RINGCENTRAL_EU)
            .setField(Opportunity.AccountId, acc.Id)
            .create()
            .getRecord();

        new SObjectBuilder(NGBS_Settings__c.SObjectType)
            .setField(NGBS_Settings__c.BaseEndpoint__c, 'http://185.23.251.118:8080')
            .setField(NGBS_Settings__c.AccountManagerPath__c, '/restapi/account-manager/v1.0')
            .setField(NGBS_Settings__c.Login__c, 'login')
            .setField(NGBS_Settings__c.Password__c, 'password')
            .create();

        String packageInfo = '[{"id":"65","version":"1",' +
            '"packageInfo":{"catalogId":"65","version":"1",' +
            '"name":"Office Standard 1/2/20/100+ Lines - 2021/2022/2023/2024",' +
            '"displayName":"RingCentral Office Standard"},' +
            '"productName":"Office","duration":"Monthly",' +
            '"edition":{"id":1,"name":"Standard"},"contract":null,' +
            '"offerType":"Regular","poc":null,"globalPackageLimits":' +
            '[{"value":"6000","code":"MONTHLY_AMOUNT_LIMIT",' +
            '"name":"Monthly money amount limit",' +
            '"type":"Amount","scope":"BillingCycle","transactionType":"Any",' +
            '"target":"Global","exclusions":[{"target":"LicenseCategoryId","targetId":"AP"}],' +
            '"override":false}],"permissions":null}]';

        Quote quote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Quote.Name => 'Test Quote',
                Quote.OpportunityId => opp.Id,
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.Pricebook2Id => Pricebook2Helper.getStandardPricebookId(),
                Quote.Package_Info__c => packageInfo
            })
            .create()
            .getRecord();

        Test.startTest();
        Approval__c app = new Approval__c(
            RecordTypeId = ApprovalHelper.RT_ID_TAX_EXEMPT_APPROVAL,
            Status__c = ApprovalHelper.STATUS_NEW,
            Opportunity__c = opp.Id);
        ApexPages.StandardController sc = new ApexPages.StandardController(app);
        Approvaldefaults ad = new Approvaldefaults(sc);
        System.assertNotEquals(null, ad.checkRecordType());
        Test.stopTest();
    }

    @isTest static void testCheckRecordTypeAddressErrors(){
        Test.setMock(HttpCalloutMock.class, new MockBusinessIdentitites());

        List<CountryCodes__c> cc = (List<CountryCodes__c>) new SObjectBuilder(CountryCodes__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                CountryCodes__c.Name => ValueProviderBuilder.provideList(new List<String> {'FRA', 'USA'}),
                CountryCodes__c.CountryName__c => ValueProviderBuilder.provideList(new List<String> {'fra;france', 'usa;united states'}),
                CountryCodes__c.CountryNameFull__c => ValueProviderBuilder.provideList(new List<String> {'France', 'United States'}),
                CountryCodes__c.CountryNameShort__c => ValueProviderBuilder.provideList(new List<String> {'FR','US'})
            })
            .quantity(2)
            .create()
            .getRecords();

        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(Account.SObjectType))
            .setField(Account.Billing_ID__c, ValueProviderBuilder.provideUniqueString())
            .setField(Account.BillingStreet, 'Lenin')
            .setField(Account.BillingCity, 'Chicago')
            .setField(Account.BillingState, 'Alabama')
            .setField(Account.BillingPostalCode, '12345')
            .setField(Account.BillingCountry, 'BEL')
            .setField(Account.Billing_System__c, AccountHelper.BILLING_SYSTEM_NBS)
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setField(Opportunity.RecordTypeId, OpportunityHelper.RT_ID_NEW_SALES_OPPORTUNITY)
            .setField(Opportunity.Brand_Name__c, OpportunityHelper.BRAND_RINGCENTRAL_EU)
            .setField(Opportunity.AccountId, acc.Id)
            .setField(Opportunity.CurrencyIsoCode, 'EUR')
            .create()
            .getRecord();

        new SObjectBuilder(NGBS_Settings__c.SObjectType)
            .setField(NGBS_Settings__c.BaseEndpoint__c, 'http://185.23.251.118:8080')
            .setField(NGBS_Settings__c.AccountManagerPath__c, '/restapi/account-manager/v1.0')
            .setField(NGBS_Settings__c.Login__c, 'login')
            .setField(NGBS_Settings__c.Password__c, 'password')
            .create();

        String packageInfo = '[{"id":"65","version":"1",' +
            '"packageInfo":{"catalogId":"65","version":"1",' +
            '"name":"Office Standard 1/2/20/100+ Lines - 2021/2022/2023/2024",' +
            '"displayName":"RingCentral Office Standard"},' +
            '"productName":"Office","duration":"Monthly",' +
            '"edition":{"id":1,"name":"Standard"},"contract":null,' +
            '"offerType":"Regular","poc":null,"globalPackageLimits":' +
            '[{"value":"6000","code":"MONTHLY_AMOUNT_LIMIT",' +
            '"name":"Monthly money amount limit",' +
            '"type":"Amount","scope":"BillingCycle","transactionType":"Any",' +
            '"target":"Global","exclusions":[{"target":"LicenseCategoryId","targetId":"AP"}],' +
            '"override":false}],"permissions":null,"packageBusinessIdentities":{"selectedBi":{"name":"RingCentral, Ltd (France)","isDefault":true,"id":"1","address":{"zip":"75009","street2":"","street1":"3-5 rue Saint Georges","state":"","phone":"","lastName":"","label":null,"firstName":"RingCentral France","county":"","country":"FRA","city":"Paris"}},"defaultBi":{"name":"RingCentral, Ltd (France)","isDefault":true,"id":"1","address":{"zip":"75009","street2":"","street1":"3-5 rue Saint Georges","state":"","phone":"","lastName":"","label":null,"firstName":"RingCentral France","county":"","country":"FRA","city":"Paris"}},"approvedBi":{"name":"RingCentral, Ltd (France)","isDefault":true,"id":"1","address":{"zip":"75009","street2":"","street1":"3-5 rue Saint Georges","state":"","phone":"","lastName":"","label":null,"firstName":"RingCentral France","county":"","country":"FRA","city":"Paris"}}}}]';

        Quote quote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Quote.Name => 'Test Quote',
                Quote.OpportunityId => opp.Id,
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.Pricebook2Id => Pricebook2Helper.getStandardPricebookId(),
                Quote.Package_Info__c => packageInfo
            })
            .create()
            .getRecord();

        Test.startTest();
        Approval__c app = new Approval__c(
            RecordTypeId = ApprovalHelper.RT_ID_TAX_EXEMPT_APPROVAL,
            Status__c = ApprovalHelper.STATUS_NEW,
            Opportunity__c = opp.Id);

        ApexPages.StandardController sc = new ApexPages.StandardController(app);

        Approvaldefaults ad = new Approvaldefaults(sc);
        System.assertEquals(true, ad.showError, 'Show error must be true value');
        System.assertEquals('Billing Country on SFDC Account does not match with Billing Country in NGBS. Please, check your Account\'s Billing Address.', ad.errMsg, 'Error message must be "Billing Country on SFDC Account does not match with Billing Country in NGBS. Please, check your Account\'s Billing Address."');

        acc.BillingCountry = '';
        update acc;

        Approvaldefaults ad1 = new Approvaldefaults(sc);
        System.assertEquals(true, ad1.showError, 'Show error must be true value');
        System.assertEquals('Please fill up Billing Country on Account', ad1.errMsg, 'Error message must be "Please fill up Billing Country on Account"');


        Test.stopTest();
    }

    @isTest static void testCheckRecordTypeAddressErrorsBIException(){
        Test.setMock(HttpCalloutMock.class, new MockBusinessIdentitites());

        List<CountryCodes__c> cc = (List<CountryCodes__c>) new SObjectBuilder(CountryCodes__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                CountryCodes__c.Name => ValueProviderBuilder.provideList(new List<String> {'FRA', 'USA'}),
                CountryCodes__c.CountryName__c => ValueProviderBuilder.provideList(new List<String> {'fra;france', 'usa;united states'}),
                CountryCodes__c.CountryNameFull__c => ValueProviderBuilder.provideList(new List<String> {'France', 'United States'}),
                CountryCodes__c.CountryNameShort__c => ValueProviderBuilder.provideList(new List<String> {'FR','US'})
            })
            .quantity(2)
            .create()
            .getRecords();

        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(Account.SObjectType))
            .setField(Account.Billing_ID__c, ValueProviderBuilder.provideUniqueString())
            .setField(Account.BillingStreet, 'Lenin')
            .setField(Account.BillingCity, 'Chicago')
            .setField(Account.BillingState, 'Alabama')
            .setField(Account.BillingPostalCode, '12345')
            .setField(Account.BillingCountry, 'FRA')
            .setField(Account.Billing_System__c, AccountHelper.BILLING_SYSTEM_NBS)
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setField(Opportunity.RecordTypeId, OpportunityHelper.RT_ID_NEW_SALES_OPPORTUNITY)
            .setField(Opportunity.Brand_Name__c, OpportunityHelper.BRAND_RINGCENTRAL_EU)
            .setField(Opportunity.AccountId, acc.Id)
            .setField(Opportunity.CurrencyIsoCode, 'EUR')
            .create()
            .getRecord();

        new SObjectBuilder(NGBS_Settings__c.SObjectType)
            .setField(NGBS_Settings__c.BaseEndpoint__c, 'http://185.23.251.118:8080')
            .setField(NGBS_Settings__c.AccountManagerPath__c, '/restapi/account-manager/v1.0')
            .setField(NGBS_Settings__c.Login__c, 'login')
            .setField(NGBS_Settings__c.Password__c, 'password')
            .create();

        String packageInfo = '[{"id":"63","version":"1","packageInfo":{"id":56454005,"catalogId":"63","version":"1","name":"Office Premium 1/2/20/100+ Lines - 2031/2032/2033/2034","displayName":"RingCentral Office Premium","oldPackageName":"RingCentral Video Pro"},"productName":"Office","productId":"2","duration":"Monthly","edition":{"id":5,"name":"Premium"},"contract":null,"offerType":"Regular","poc":null,"globalPackageLimits":[{"value":"6000","code":"MONTHLY_AMOUNT_LIMIT","name":"Monthly money amount limit","type":"Amount","scope":"BillingCycle","transactionType":"Any","target":"Global","exclusions":[{"target":"LicenseCategoryId","targetId":"AP"}],"override":false}],"permissions":null,"packageBusinessIdentities":{"selectedBi":{"name":"RingCentral, Ltd (France)","isDefault":true,"id":"1","address":{"zip":"75009","street2":"","street1":"3-5 rue Saint Georges","state":"","phone":"","lastName":"","label":null,"firstName":"RingCentral France","county":"","country":"FRA","city":"Paris"}},"defaultBi":{"name":"RingCentral, Ltd (France)","isDefault":true,"id":"1","address":{"zip":"75009","street2":"","street1":"3-5 rue Saint Georges","state":"","phone":"","lastName":"","label":null,"firstName":"RingCentral France","county":"","country":"FRA","city":"Paris"}},"approvedBi":{"name":"RingCentral, Ltd (France)","isDefault":true,"id":"1","address":{"zip":"75009","street2":"","street1":"3-5 rue Saint Georges","state":"","phone":"","lastName":"","label":null,"firstName":"RingCentral France","county":"","country":"FRA","city":"Paris"}}},"existingPackageInfo":{"id":"240","version":"1","offerType":"Free","productName":"Meetings"}}]';

        Quote quote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Quote.Name => 'Test Quote',
                Quote.OpportunityId => opp.Id,
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.Pricebook2Id => Pricebook2Helper.getStandardPricebookId(),
                Quote.Package_Info__c => packageInfo
            })
            .create()
            .getRecord();

        Test.startTest();
        Approval__c app = new Approval__c(
            RecordTypeId = ApprovalHelper.RT_ID_TAX_EXEMPT_APPROVAL,
            Status__c = ApprovalHelper.STATUS_NEW,
            Opportunity__c = opp.Id);

        ApexPages.StandardController sc = new ApexPages.StandardController(app);

        Approvaldefaults ad = new Approvaldefaults(sc);
        System.assertEquals(true, ad.showError, 'Show error must be true value');
        System.assertEquals('VAT exemption is not available for this country!', ad.errMsg, 'Error message must be "VAT exemption is not available for this country!"');
        Test.stopTest();
    }

    @isTest static void testCheckRecordTypeIndianTEAErrors(){
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(Account.SObjectType))
            .setFields(new Map<SObjectField, Object> {
                Account.Billing_ID__c => ValueProviderBuilder.provideUniqueString(),
                Account.BillingStreet => 'Lenin',
                Account.BillingCity => 'Chicago',
                Account.BillingState => 'Alabama',
                Account.BillingPostalCode => '12345',
                Account.BillingCountry => 'India',
                Account.Billing_System__c => AccountHelper.BILLING_SYSTEM_NBS
            })
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.RecordTypeId => OpportunityHelper.RT_ID_NEW_SALES_OPPORTUNITY,
                Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL_EU,
                Opportunity.AccountId => acc.Id,
                Opportunity.CurrencyIsoCode => 'INR'
            })
            .create()
            .getRecord();

        Approval__c kyc = (Approval__c) new ApprovalSelector()
            .selectKYCRequestApprovalsForAccount(new List<Object>{new Set<Id>{acc.Id}})
            .selectFields(new List<String>{
                'Status__c',
                'GstNo__c',
                'KycFiles__c'
            })
            .executeQuery()
            .get(0);

        kyc.Status__c = ApprovalHelper.STATUS_APPROVED;
        kyc.DateOfSignOff__c = System.today();
        kyc.Other__c = 'test other';
        kyc.NameOfTheAuthorisedSignatory__c = 'test name of Authorised Signatory';
        kyc.NameOfFatherOrHusband__c = 'test name of father';
        kyc.GenderOfAuthorisedSignatory__c = 'Male';
        kyc.NationalityOfAuthorisedSignatory__c = 'India';
        kyc.DateOfBirthOfAuthorisedSignatory__c = System.today().addYears(-20);
        kyc.KycFiles__c = 'file1;file2;file3;file4;file5;;file7;file8;file9';
        kyc.PanGirNo__c = '1234567890';
        kyc.PinCode__c = '123456';
        kyc.HouseNo__c = '1';
        kyc.StreetAddress__c = 'Test street';
        kyc.Area__c = 'Test area';
        kyc.City__c = 'Test city';
        kyc.District__c = 'Test district';
        kyc.State__c = 'Assam';
        kyc.Other__c = 'Test other';
        kyc.GstNo__c = '11111';

        Test.startTest();
        new SObjectBuilder(LocalSubscribedAddress__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    LocalSubscribedAddress__c.Approval__c => kyc.Id,
                    LocalSubscribedAddress__c.RecordTypeId => LocalSubscribedAddressHelper.RT_ID_REGISTERED_ADDRESS_OF_COMPANY
                }
            )
            .create();

        update kyc;
        ApprovalHelper.processApprovalRequest(new Set<Id>{kyc.Id}, null, 'Approve');

        Approval__c app = new Approval__c(
            RecordTypeId = ApprovalHelper.RT_ID_TAX_EXEMPT_APPROVAL,
            Status__c = ApprovalHelper.STATUS_NEW,
            Opportunity__c = opp.Id);

        kyc.GstNo__c = '33333';
        update kyc;
        ApexPages.StandardController sc = new ApexPages.StandardController(app);
        Approvaldefaults ad = new Approvaldefaults(sc);
        System.assertEquals(true, ad.showError, 'Show error must be true value');
        System.assertEquals(TaxExemptionHelper.TEA_ERROR_SEZ_CERT_NOT_FOUND, ad.errMsg, 'Error message must be: ' + TaxExemptionHelper.TEA_ERROR_SEZ_CERT_NOT_FOUND);

        kyc.KycFiles__c = 'file1;file2;file3;file4;file5;file6;file7;file8;file9';
        update kyc;
        sc = new ApexPages.StandardController(app);
        ad = new Approvaldefaults(sc);
        System.assertEquals(false, ad.showError, 'Show error must be true value');
        Test.stopTest();
    }

    @isTest static void testCheckRecordTypeAddressErrorsCCException(){
        Test.setMock(HttpCalloutMock.class, new MockBusinessIdentitites());

        List<CountryCodes__c> cc = (List<CountryCodes__c>) new SObjectBuilder(CountryCodes__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                CountryCodes__c.Name => ValueProviderBuilder.provideList(new List<String> {'FRA', 'USA'}),
                CountryCodes__c.CountryName__c => ValueProviderBuilder.provideList(new List<String> {'fra;france', 'usa;united states'}),
                CountryCodes__c.CountryNameFull__c => ValueProviderBuilder.provideList(new List<String> {'France', 'United States'}),
                CountryCodes__c.CountryNameShort__c => ValueProviderBuilder.provideList(new List<String> {'FR','US'})
            })
            .quantity(2)
            .create()
            .getRecords();

        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(Account.SObjectType))
            .setField(Account.BillingStreet, 'Lenin')
            .setField(Account.BillingCity, 'Chicago')
            .setField(Account.BillingState, 'Alabama')
            .setField(Account.BillingPostalCode, '12345')
            .setField(Account.BillingCountry, 'BEL')
            .setField(Account.Billing_System__c, AccountHelper.BILLING_SYSTEM_NBS)
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setField(Opportunity.RecordTypeId, OpportunityHelper.RT_ID_NEW_SALES_OPPORTUNITY)
            .setField(Opportunity.Brand_Name__c, OpportunityHelper.BRAND_RINGCENTRAL_EU)
            .setField(Opportunity.AccountId, acc.Id)
            .setField(Opportunity.CurrencyIsoCode, 'EUR')
            .create()
            .getRecord();

        new SObjectBuilder(NGBS_Settings__c.SObjectType)
            .setField(NGBS_Settings__c.BaseEndpoint__c, 'http://185.23.251.118:8080')
            .setField(NGBS_Settings__c.AccountManagerPath__c, '/restapi/account-manager/v1.0')
            .setField(NGBS_Settings__c.Login__c, 'login')
            .setField(NGBS_Settings__c.Password__c, 'password')
            .create();

        String packageInfo = '[{"id":"63","version":"1","packageInfo":{"id":56454005,"catalogId":"63","version":"1","name":"Office Premium 1/2/20/100+ Lines - 2031/2032/2033/2034","displayName":"RingCentral Office Premium","oldPackageName":"RingCentral Video Pro"},"productName":"Office","productId":"2","duration":"Monthly","edition":{"id":5,"name":"Premium"},"contract":null,"offerType":"Regular","poc":null,"globalPackageLimits":[{"value":"6000","code":"MONTHLY_AMOUNT_LIMIT","name":"Monthly money amount limit","type":"Amount","scope":"BillingCycle","transactionType":"Any","target":"Global","exclusions":[{"target":"LicenseCategoryId","targetId":"AP"}],"override":false}],"permissions":null,"packageBusinessIdentities":{"selectedBi":{"name":"RingCentral, Ltd (France)","isDefault":true,"id":"1","address":{"zip":"75009","street2":"","street1":"3-5 rue Saint Georges","state":"","phone":"","lastName":"","label":null,"firstName":"RingCentral France","county":"","country":"FRA","city":"Paris"}},"defaultBi":{"name":"RingCentral, Ltd (France)","isDefault":true,"id":"1","address":{"zip":"75009","street2":"","street1":"3-5 rue Saint Georges","state":"","phone":"","lastName":"","label":null,"firstName":"RingCentral France","county":"","country":"FRA","city":"Paris"}},"approvedBi":{"name":"RingCentral, Ltd (France)","isDefault":true,"id":"1","address":{"zip":"75009","street2":"","street1":"3-5 rue Saint Georges","state":"","phone":"","lastName":"","label":null,"firstName":"RingCentral France","county":"","country":"FRA","city":"Paris"}}},"existingPackageInfo":{"id":"240","version":"1","offerType":"Free","productName":"Meetings"}}]';
        Quote quote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Quote.Name => 'Test Quote',
                Quote.OpportunityId => opp.Id,
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.Pricebook2Id => Pricebook2Helper.getStandardPricebookId(),
                Quote.Package_Info__c => packageInfo
            })
            .create()
            .getRecord();

        Test.startTest();
        Approval__c app = new Approval__c(
            RecordTypeId = ApprovalHelper.RT_ID_TAX_EXEMPT_APPROVAL,
            Status__c = ApprovalHelper.STATUS_NEW,
            Opportunity__c = opp.Id);

        ApexPages.StandardController sc = new ApexPages.StandardController(app);

        Approvaldefaults ad = new Approvaldefaults(sc);
        System.assertEquals(true, ad.showError, 'Show error must be true value');
        System.assertEquals('Billing Country on SFDC Account does not match with Billing Country in NGBS. Please, check your Account\'s Billing Address.', ad.errMsg, 'Error message must be "Billing Country on SFDC Account does not match with Billing Country in NGBS. Please, check your Account\'s Billing Address."');
        Test.stopTest();
    }

    public class MockBusinessIdentitites implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();
            String body = '';

            res.setStatus('OK');
            res.setStatusCode(200);
            res.setBody(getRequestBody(req));
            return res;
        }

        private String getRequestBody(HTTPRequest req) {
            String body = '';

            if (req.getEndpoint().endsWith('Billing') && req.getMethod() == HttpHelper.METHOD_GET) {
                body = responseAddress;
            } else {
                body = billingIdentitiesResponse;
            }

            return body;
        }
    }

    @isTest static void testGetUserInfo(){
        String userInfo = Approvaldefaults.getUsersInfo(UserInfo.getUserId());
        System.assertNotEquals(null, userInfo, 'Url must be returned');
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    private static void testSetFieldsMethods() {
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
                .setFields(new Map<SObjectField, Object>{
                        Account.Name => 'Test acc',
                        Account.Billing_ID__c => ValueProviderBuilder.provideUniqueString(),
                        Account.RC_User_ID__c => ValueProviderBuilder.provideUniqueString(),
                        Account.BillingStreet => '2078 Adamsville Road',
                        Account.BillingCity => 'Laredo',
                        Account.BillingPostalCode => '78040',
                        Account.BillingState => 'Texas',
                        Account.BillingCountry => 'United States',
                        Account.EnabledLBO__c => true,
                        Account.RC_Account_Status__c => AccountHelper.PAID_STATUS
                })
                .create()
                .getRecord();

        //Adding the bypasstrigger flag to not trigger the validation when creating contact. PBC-10857
		ByPassTrigger__c byPassTrigger = ByPassTrigger__c.getOrgDefaults();
        byPassTrigger.ByPass_OppContactRole_Validation__c = true;
        insert byPassTrigger;
        Contact cont = (Contact) new SObjectBuilder(Contact.SObjectType)
                .setFields(new Map<SObjectField, Object>{
                        Contact.FirstName => 'Test2',
                        Contact.LastName => 'Test2',
                        Contact.AccountId => acc.Id,
                        Contact.Email => 'test@test.com',
                        Contact.Phone => '1234567890',
                        Contact.Preferred_Language__c => 'en_US'
                })
                .create()
                .getRecord();

        Opportunity opportunity = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
                .setFields(new Map<SObjectField, Object>{
                        Opportunity.Name => 'Test1',
                        Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL,
                        Opportunity.Type => OpportunityHelper.OPPORTUNITY_TYPE_EX_BUSINESS,
                        Opportunity.RecordTypeId => OpportunityHelper.RT_ID_NEW_SALES_OPPORTUNITY,
                        Opportunity.AccountId => acc.Id,
                        Opportunity.Is_Billing_Opportunity__c => true,
                        Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                        Opportunity.CloseDate => system.today().addMonths(1),
                        Opportunity.Primary_Opportunity_Contact__c => cont.Id,
                        Opportunity.CurrencyIsoCode => RingCentralHelper.USD
                })
                .create()
                .getRecord();

        PriceBook2 pb = (PriceBook2) new SObjectBuilder(PriceBook2.sObjectType)
                .setFields(new Map<SObjectField, Object>{
                        PriceBook2.Name => ValueProviderBuilder.provideUniqueString('test pricebook'),
                        PriceBook2.IsActive => true,
                        PriceBook2.Line_Range_Min__c => 2,
                        PriceBook2.Service__c => Pricebook2Helper.SERVICE_OFFICE,
                        PriceBook2.Plan__c => Pricebook2Helper.PLAN_ANNUAL
                })
                .create()
                .getRecord();

        Triggers.switchOff();
        String packageInfoQLI = '{"categoryCode":"HD","discount":{"value":0,"type":"Money"},"duration":"One - Time","id":"18","version":"1","lboxes":[{"elementID":"LB_698","min":0,"max":99999}],"categoryPath":"HD"}';
        Quote quote = (Quote) new SObjectBuilder(Quote.SObjectType)
                .setFields(new Map<SObjectField, Object> {
                        Quote.Name => ValueProviderBuilder.provideUniqueString('Test Billing Quote'),
                        Quote.OpportunityId => opportunity.Id,
                        Quote.Status => QuoteHelper.QUOTE_STATUS_DRAFT,
                        Quote.Approved_Status__c => QuoteHelper.APPROVAL_STATUS_NOT_REQUIRED,
                        Quote.Total_Number_of_Digital_Lines__c => 1,
                        Quote.Start_Date__c => Date.today(),
                        Quote.End_Date__c => Date.today().addDays(2),
                        Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                        Quote.Pricebook2Id => pb.Id
                })
                .create()
                .getRecord();

        List<Product2> product = (List<Product2>) new SObjectBuilder(Product2.SObjectType)
                .setFields(new Map<SObjectField, Object> {
                        Product2.Name => ValueProviderBuilder.provideList(new List<String> {'Test_Product', 'Test_Product1'}),
                        Product2.Charge_Term__c => Product2Helper.CHARGE_TERM_ONE_TIME,
                        Product2.IsActive => true,
                        Product2.Feature__c => 17,
                        Product2.Family => Product2Helper.FAMILY_DISCOUNTED_PHONES
                })
                .quantity(2)
                .create()
                .getRecords();

        PricebookEntry standardPricebookEntry = (PricebookEntry) new SObjectBuilder(PricebookEntry.SObjectType)
                .setFields(new Map<SObjectField, Object> {
                        PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                        PricebookEntry.Product2Id => product[0].Id,
                        PricebookEntry.UnitPrice => 100,
                        PricebookEntry.IsActive => true,
                        PricebookEntry.UseStandardPrice => false
                })
                .create()
                .getRecord();

        PricebookEntry currentPricebookEntry = (PricebookEntry) new SObjectBuilder(PricebookEntry.SObjectType)
                .setFields(new Map<SObjectField, Object> {
                        PricebookEntry.Pricebook2Id => pb.Id,
                        PricebookEntry.Product2Id => product[0].Id,
                        PricebookEntry.UnitPrice => 50,
                        PricebookEntry.IsActive => true,
                        PricebookEntry.UseStandardPrice => false
                })
                .create()
                .getRecord();
        /* Sales end date should be in the past */
        List<QuoteLineItem> qlis = (List<QuoteLineItem>) new SObjectBuilder(QuoteLineItem.SObjectType)
                .setFields(new Map<SObjectField, Object> {
                        QuoteLineItem.QuoteId => quote.Id,
                        QuoteLineItem.Deactivated__c => false,
                        QuoteLineItem.Product2Id => ValueProviderBuilder.provideList(new List<String> {product[0].Id, product[1].Id}),
                        QuoteLineItem.PricebookEntryId => currentPricebookEntry.Id,
                        QuoteLineItem.Quantity => 3,
                        QuoteLineItem.PackageInfo__c => packageInfoQLI,
                        QuoteLineItem.Package_Info_QLI__c => packageInfoQLI,
                        QuoteLineItem.Package_Info__c => packageInfoQLI,
                        QuoteLineItem.NewQuantity__c => 3,
                        QuoteLineItem.UnitPrice => 50,
                        QuoteLineItem.Discount => 2,
                        QuoteLineItem.Zero_Quantity__c => false,
                        QuoteLineItem.SalesEndDate__c => System.now().addDays(-1)
                })
                .quantity(2)
                .create()
                .getRecords();

        Triggers.switchOn();

        Test.startTest();
        Test.setCurrentPageReference(new PageReference('Page.ApprovalDefaults'));
        System.currentPageReference().getParameters().put('CF00N80000004iCmz_lkid', acc.Id);
        System.currentPageReference().getParameters().put('CF00N80000004j6pF_lkid', opportunity.Id);
        ApprovalHelperCls.describeRecordTypesById();
        System.currentPageReference().getParameters().put(
                'RecordType',
                ApprovalHelperCls.rtMapByID.get(ApprovalHelper.INVOICING_REQUEST_APPROVAL_RT_NAME).getRecordTypeId()
        );
        ApexPages.StandardController sc = new ApexPages.StandardController(new Approval__c());
        Approvaldefaults ad = new ApprovalDefaults(sc);

        PageReference approvalPage = ad.actapprovalObject();
        ad.setQuoteFields(approvalPage);
        ad.setAccount(approvalPage);
        ad.setOpportunityAndAccount(approvalPage);
        Test.stopTest();
    }
    @isTest
    static void testCreateTaxExemptionApprovalForOpportunity(){
        Test.setMock(HttpCalloutMock.class, new MockBusinessIdentitites());

        List<CountryCodes__c> cc = (List<CountryCodes__c>) new SObjectBuilder(CountryCodes__c.SObjectType)
                .setFields(new Map<SObjectField, Object>{
                        CountryCodes__c.Name => ValueProviderBuilder.provideList(new List<String> {'FRA', 'USA'}),
                        CountryCodes__c.CountryName__c => ValueProviderBuilder.provideList(new List<String> {'fra;france', 'usa;united states'}),
                        CountryCodes__c.CountryNameFull__c => ValueProviderBuilder.provideList(new List<String> {'France', 'United States'}),
                        CountryCodes__c.CountryNameShort__c => ValueProviderBuilder.provideList(new List<String> {'FR','US'})
                })
                .quantity(2)
                .create()
                .getRecords();

        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
                .setFields(SObjectFactoryFieldDefaults.getDefaults(Account.SObjectType))
                .setField(Account.BillingStreet, 'Lenin')
                .setField(Account.BillingCity, 'Chicago')
                .setField(Account.BillingState, 'Alabama')
                .setField(Account.BillingPostalCode, '12345')
                .setField(Account.BillingCountry, 'BEL')
                .setField(Account.Billing_System__c, AccountHelper.BILLING_SYSTEM_NBS)
                .create()
                .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
                .setField(Opportunity.RecordTypeId, OpportunityHelper.RT_ID_NEW_SALES_OPPORTUNITY)
                .setField(Opportunity.Brand_Name__c, OpportunityHelper.BRAND_RINGCENTRAL_EU)
                .setField(Opportunity.AccountId, acc.Id)
                .setField(Opportunity.CurrencyIsoCode, 'EUR')
                .create()
                .getRecord();

        new SObjectBuilder(NGBS_Settings__c.SObjectType)
                .setField(NGBS_Settings__c.BaseEndpoint__c, 'http://185.23.251.118:8080')
                .setField(NGBS_Settings__c.AccountManagerPath__c, '/restapi/account-manager/v1.0')
                .setField(NGBS_Settings__c.Login__c, 'login')
                .setField(NGBS_Settings__c.Password__c, 'password')
                .create();

        String packageInfo = '[{"id":"65","version":"1",' +
                '"packageInfo":{"catalogId":"65","version":"1",' +
                '"name":"Office Standard 1/2/20/100+ Lines - 2021/2022/2023/2024",' +
                '"displayName":"RingCentral Office Standard"},' +
                '"productName":"Office","duration":"Monthly",' +
                '"edition":{"id":1,"name":"Standard"},"contract":null,' +
                '"offerType":"Regular","poc":null,"globalPackageLimits":' +
                '[{"value":"6000","code":"MONTHLY_AMOUNT_LIMIT",' +
                '"name":"Monthly money amount limit",' +
                '"type":"Amount","scope":"BillingCycle","transactionType":"Any",' +
                '"target":"Global","exclusions":[{"target":"LicenseCategoryId","targetId":"AP"}],' +
                '"override":false}],"permissions":null}]';

        Quote quote = (Quote) new SObjectBuilder(Quote.SObjectType)
                .setFields(new Map<SObjectField, Object>{
                        Quote.Name => 'Test Quote',
                        Quote.OpportunityId => opp.Id,
                        Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                        Quote.Pricebook2Id => Pricebook2Helper.getStandardPricebookId(),
                        Quote.Package_Info__c => packageInfo
                })
                .create()
                .getRecord();

        Test.startTest();
        Approval__c app = new Approval__c(
                RecordTypeId = ApprovalHelper.RT_ID_TAX_EXEMPT_APPROVAL,
                Status__c = ApprovalHelper.STATUS_NEW,
                Opportunity__c = opp.Id);

        ApexPages.StandardController sc = new ApexPages.StandardController(app);

        Approvaldefaults ad = new Approvaldefaults(sc);
        System.assertEquals(true, ad.showError, 'Show error must be true value');
        System.assertEquals('VAT exemption is not available for this quote due to BI absence (the quote may be too old). Please re-create the quote.', ad.errMsg, 'Error message must be "VAT exemption is not available for this quote!"');
        Test.stopTest();
    }
}