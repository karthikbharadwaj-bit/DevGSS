@isTest
public class Test_Approval_StandardCreateComp {

    private static final String NGBS_PACKAGE_LIMITS_API_RESPONSE = '[{"value":500000,"limitOverride":{"value":50000,"startDate":"2022-02-10T13:22Z[UTC]","paymentType" : null,"limitDuration":{"value":1,"unit":"Months"}},"exclusions":[{"targetId":"HD","target":"LicenseCategoryId"}],"code":"MONTHLY_AMOUNT_LIMIT"}]';
    private static String GET_PAYMENT_METHOD_TYPE_RESPONSE = '{"currentType":"testPaymentMethodType","formerTypes":[]}';

    private class Mock implements HttpCalloutMock {

        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();
            res.setStatus('OK');
            res.setStatusCode(200);
            res.setBody(getRequestBody(req));
            return res;
        }

        private String getRequestBody(HTTPRequest req) {
            String body = '';
            String endpoint = req.getEndpoint();
            if (req.getMethod() == HttpHelper.METHOD_GET && req.getEndpoint().endsWith('/paymentMethod/type')) {
                body = GET_PAYMENT_METHOD_TYPE_RESPONSE;
            } else if (req.getMethod() == HttpHelper.METHOD_GET && req.getEndpoint().endsWith('/limits')) {
                body = NGBS_PACKAGE_LIMITS_API_RESPONSE;
            }
            return body;
        }
    }

    @isTest
    public static void testApprovalStandardCreate(){
        Test.startTest();

            Triggers.switchOff();

            Id devRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer Account').getRecordTypeId();

            List<Account> testAccs = (List<Account>) new SObjectBuilder(Account.SObjectType)
                .setFields(new Map<SObjectField, Object> {
                    Account.Name => ValueProviderBuilder.provideList(new List<String> {'goodAcc', 'goodAcc2'}),
                    Account.BillingCountry => ValueProviderBuilder.provideList(new List<String> {'United Kingdom', 'FFFFF'}),
                    Account.BillingCity => 'London',
                    Account.BillingState => 'London',
                    Account.BillingStreet => '1st',
                    Account.BillingPostalCode => '76002',
                    Account.RecordTypeId => devRecordTypeId,
                    Account.Payment_Method__c => AccountHelper.PAYMENT_METHOD_INVOICE,
                    Account.Billing_ID__c => ValueProviderBuilder.provideList(new List<String> {'12345', null})
                })
                .quantity(2)
                .create()
                .getRecords();

            List<Contact> testContacts = (List<Contact>) new SObjectBuilder(Contact.SObjectType)
                .setFields(new Map<SObjectField, Object> {
                    Contact.LastName => 'Good Contact',
                    Contact.Email => 'good@contact.com',
                    Contact.AccountId => testAccs[0].Id
                })
                .quantity(1)
                .create()
                .getRecords();

            List<AccountContactRole> testACR = (List<AccountContactRole>) new SObjectBuilder(AccountContactRole.SObjectType)
                .setFields(new Map<SObjectField, Object> {
                    AccountContactRole.AccountId => testAccs[0].Id,
                    AccountContactRole.ContactId => testContacts[0].Id,
                    AccountContactRole.Role => AccountContactRoleHelper.CONTACT_ROLE_ACCOUNT_PAYABLE
                })
                .quantity(1)
                .create()
                .getRecords();

            List<Opportunity> testOpps = (List<Opportunity>) new SObjectBuilder(Opportunity.SObjectType)
                .setFields(
                    new Map<SObjectField, Object> {
                        Opportunity.AccountId => ValueProviderBuilder.provideList(new List<Id> {testAccs[0].Id, testAccs[1].Id}),
                        Opportunity.Name => 'Test Opportunity',
                        Opportunity.StageName => '1. Draft',
                        Opportunity.Brand_Name__c => ValueProviderBuilder.provideList(new List<String> {'RingCentral UK', 'RingCentral EU'}),
                        Opportunity.closeDate => System.today(),
                        Opportunity.CurrencyIsoCode => ValueProviderBuilder.provideList(new List<String> {'EUR'}),
                        Opportunity.Is_Billing_Opportunity__c => false
                    }
                )
                .quantity(2)
                .create()
                .getRecords();

            String packageInfo =
                '[' +
                    '{' +
                        '"id":"65",' +
                        '"version":"1",' +
                        '"packageInfo": {' +
                            '"catalogId":"65",' +
                            '"version":"1",' +
                            '"name":"Office Standard 1/2/20/100+ Lines - 2021/2022/2023/2024",' +
                            '"displayName":"RingCentral Office Standard"' +
                        '},' +
                        '"productName":"Office",' +
                        '"duration":"Monthly",' +
                        '"edition": {' +
                            '"id":1,' +
                            '"name":"Standard"' +
                        '},'+
                        '"contract":null,' +
                        '"offerType":"Regular",' +
                        '"poc":null,' +
                        '"globalPackageLimits":' +
                        '[' +
                            '{' +
                                '"value":"6000",' +
                                '"code":"MONTHLY_AMOUNT_LIMIT",' +
                                '"name":"Monthly money amount limit",' +
                                '"type":"Amount",' +
                                '"scope":"BillingCycle",' +
                                '"transactionType":"Any",' +
                                '"target":"Global",' +
                                '"exclusions":' +
                                '[' +
                                    '{' +
                                        '"target":"LicenseCategoryId",' +
                                        '"targetId":"AP"' +
                                    '}' +
                                '],' +
                                '"override":false' +
                            '}' +
                        '],' +
                        '"permissions":null' +
                    '}' +
                ']';

            List<Product2> testProducts = (List<Product2>) new SObjectBuilder(Product2.SObjectType)
                .setFields(
                    new Map<SObjectField, Object> {
                        Product2.Name => 'Test Product',
                        Product2.IsActive => true,
                        Product2.Sub_Category__c => Product2Helper.SUBCATEGORY_PROSERV,
                        Product2.Charge_Term__c => Product2Helper.CHARGE_TERM_ONE_TIME,
                        Product2.Family => 'Service'
                    }
                )
                .quantity(2)
                .create()
                .getRecords();

            PriceBook2 testPriceBook = (PriceBook2) new SObjectBuilder(PriceBook2.SObjectType)
                .setFields(new Map<SObjectField, Object> {
                    PriceBook2.Name => 'Test Price Book',
                    PriceBook2.Description => 'Test Price Book Products',
                    PriceBook2.IsActive => true,
                    PriceBook2.Line_Range_Min__c => 5,
                    PriceBook2.Service__c => 'Office',
                    PriceBook2.Plan__c => 'Monthly',
                    PriceBook2.CurrencyIsoCode => 'EUR'
                })
                .create()
                .getRecord();

            PriceBookEntry standardriceEntry = (PriceBookEntry) new SobjectBuilder(PriceBookEntry.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        PriceBookEntry.Product2Id => testProducts[0].Id,
                        PriceBookEntry.UnitPrice => 10000,
                        PriceBookEntry.IsActive => true,
                        PriceBookEntry.UseStandardPrice => false,
                        PriceBookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                        PriceBookEntry.CurrencyIsoCode => 'EUR'
                    }
                )
                .create()
                .getRecord();

            PriceBookEntry testPriceEntry = (PriceBookEntry) new SObjectBuilder(PriceBookEntry.SObjectType)
                .setFields(
                    new Map<SObjectField, Object> {
                        PriceBookEntry.Pricebook2Id => testPriceBook.Id,
                        PriceBookEntry.Product2Id => testProducts[0].Id,
                        PriceBookEntry.UnitPrice => 10000,
                        PriceBookEntry.IsActive => true,
                        PriceBookEntry.UseStandardPrice => false,
                        PriceBookEntry.CurrencyIsoCode => 'EUR'
                    }
                )
                .create()
                .getRecord();

            Id QuoteRecordType = Schema.SObjectType.Quote.getRecordTypeInfosByName().get('Sales Quote').getRecordTypeId();

            Quote testQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
                .setFields(
                    new Map<SObjectField, Object> {
                        Quote.Name => 'Sales Quote',
                        Quote.OpportunityId => testOpps[0].Id,
                        Quote.Pricebook2Id => testPriceBook.Id,
                        Quote.isPrimary__c => true,
                        Quote.RecordTypeId => QuoteRecordType,
                        Quote.Package_Info__c => packageInfo,
                        Quote.Monthly_Recurring_Revenue__c => 1000,
                        Quote.CurrencyIsoCode => 'EUR'
                    }
                )
                .create()
                .getRecord();

            QuoteLineItem testQli = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.SObjectType)
                .setFields(
                    new Map<SObjectField, Object> {
                        QuoteLineItem.QuoteId => testQuote.Id,
                        QuoteLineItem.Product2Id => testProducts[0].Id,
                        QuoteLineItem.PricebookEntryId => testPriceEntry.Id,
                        QuoteLineItem.UnitPrice => testPriceEntry.UnitPrice,
                        QuoteLineItem.Quantity => 5
                    }
                )
                .create()
                .getRecord();

            // Create Phase
            Phase__c testPhase = new Phase__c(
                Name = 'Test',
                Opportunity__c = testOpps[1].Id,
                Quote__c = testQuote.Id
            );
            insert new List<Phase__c> {testPhase};

            Triggers.switchOn();

            Id approvalRectypeID = Schema.SObjectType.Approval__c.getRecordTypeInfosByName().get(ApprovalHelper.INVOICING_REQUEST_APPROVAL_RT_NAME).getRecordTypeId();
            Id approvalRectypeID2 = Schema.SObjectType.Approval__c.getRecordTypeInfosByName().get(ApprovalHelper.RT_NAME_REFUND_APPROVAL).getRecordTypeId();

            Approval_StandardApprovalCreate.responseWrapper initialDataAcc = Approval_StandardApprovalCreate.getInitialData(testAccs[0].Id, null);
            System.assertEquals(initialDataAcc.errorMessage, null, 'Response was not return error messages');
            System.assertEquals(testContacts[0].Id, initialDataAcc.payingContactId, 'Paying Contact was not received');

            Map<Id, RecordType> recordTypesMap = new Map<Id, RecordType>(initialDataAcc.recordTypes);
            Schema.SObjectType  objType = Approval__c.SObjectType;
            for(RecordTypeInfo rt : objType.getDescribe().getRecordTypeInfos()) {
                RecordType recordType = new RecordType();
                if (!rt.isAvailable() || !rt.isActive()) {
                    recordType = recordTypesMap.get(rt.getRecordTypeId());
                    System.assertEquals(null, recordType, 'Inactive or not available RecordType was rendered for user');
                }
            }

            Approval_StandardApprovalCreate.responseWrapper initialDataOpp = Approval_StandardApprovalCreate.getInitialData(testOpps[0].Id, null);
            System.assertEquals(initialDataOpp.errorMessage, null, 'Response was not return error messages');
            System.assertEquals(testContacts[0].Id, initialDataOpp.payingContactId, 'Paying Contact was not received');

            testAccs[0].Partner_ID__c = testAccs[1].Id;
            testAccs[0].Partner_Type__c = AccountHelper.ACCOUNT_PARTNER_ALCATEL_LUCENT_BILL_ON_BEHALF;
            update testAccs[0];

            Approval_StandardApprovalCreate.responseWrapper initialDataAccSecond = Approval_StandardApprovalCreate.getInitialData(testAccs[0].Id, null);

            Map<Id, RecordType> recordTypesIoBMap = new Map<Id, RecordType>(initialDataAccSecond.recordTypes);

            for(RecordTypeInfo rt : objType.getDescribe().getRecordTypeInfos()) {
                RecordType recordType = new RecordType();

                if (rt.name == ApprovalHelper.RT_NAME_INVOICE_ON_BEHALF_REQUEST_APPROVAL) {
                    recordType = recordTypesIoBMap.get(rt.getRecordTypeId());
                    System.assertNotEquals(null, recordType, 'Invoice on Behalf RT wasn\'t rendered for Invoice on Behalf Account');
                }

                if (rt.name == ApprovalHelper.INVOICING_REQUEST_APPROVAL_RT_NAME) {
                    recordType = recordTypesIoBMap.get(rt.getRecordTypeId());
                    System.assertEquals(null, recordType, 'Invoice Request RT was rendered for Invoice on Behalf Account');
                }
            }
        Test.stopTest();
    }


    @isTest
    public static void testApprovalStandardCreate2(){
        Test.startTest();

            Triggers.switchOff();

            Id devRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer Account').getRecordTypeId();

            List<Account> testAccs = (List<Account>) new SObjectBuilder(Account.SObjectType)
                .setFields(new Map<SObjectField, Object> {
                    Account.Name => ValueProviderBuilder.provideList(new List<String> {'goodAcc', 'goodAcc2'}),
                    Account.BillingCountry => ValueProviderBuilder.provideList(new List<String> {'United Kingdom', 'FFFFF'}),
                    Account.BillingCity => 'London',
                    Account.BillingState => 'London',
                    Account.BillingStreet => '1st',
                    Account.BillingPostalCode => '76002',
                    Account.RecordTypeId => devRecordTypeId,
                    Account.Payment_Method__c => AccountHelper.PAYMENT_METHOD_INVOICE,
                    Account.Billing_ID__c => ValueProviderBuilder.provideList(new List<String> {'12345', null})
                })
                .quantity(2)
                .create()
                .getRecords();

            List<Contact> testContacts = (List<Contact>) new SObjectBuilder(Contact.SObjectType)
                .setFields(new Map<SObjectField, Object> {
                    Contact.LastName => 'Good Contact',
                    Contact.Email => 'good@contact.com',
                    Contact.AccountId => testAccs[0].Id
                })
                .quantity(1)
                .create()
                .getRecords();

            List<AccountContactRole> testACR = (List<AccountContactRole>) new SObjectBuilder(AccountContactRole.SObjectType)
                .setFields(new Map<SObjectField, Object> {
                    AccountContactRole.AccountId => testAccs[0].Id,
                    AccountContactRole.ContactId => testContacts[0].Id,
                    AccountContactRole.Role => AccountContactRoleHelper.CONTACT_ROLE_ACCOUNT_PAYABLE
                })
                .quantity(1)
                .create()
                .getRecords();

            List<Opportunity> testOpps = (List<Opportunity>) new SObjectBuilder(Opportunity.SObjectType)
                .setFields(
                    new Map<SObjectField, Object> {
                        Opportunity.AccountId => ValueProviderBuilder.provideList(new List<Id> {testAccs[0].Id, testAccs[1].Id}),
                        Opportunity.Name => 'Test Opportunity',
                        Opportunity.StageName => '1. Draft',
                        Opportunity.Brand_Name__c => ValueProviderBuilder.provideList(new List<String> {'RingCentral UK', 'RingCentral EU'}),
                        Opportunity.closeDate => System.today(),
                        Opportunity.CurrencyIsoCode => ValueProviderBuilder.provideList(new List<String> {'EUR'}),
                        Opportunity.Is_Billing_Opportunity__c => false
                    }
                )
                .quantity(2)
                .create()
                .getRecords();

            String packageInfo =
                '[' +
                    '{' +
                        '"id":"65",' +
                        '"version":"1",' +
                        '"packageInfo": {' +
                            '"catalogId":"65",' +
                            '"version":"1",' +
                            '"name":"Office Standard 1/2/20/100+ Lines - 2021/2022/2023/2024",' +
                            '"displayName":"RingCentral Office Standard"' +
                        '},' +
                        '"productName":"Office",' +
                        '"duration":"Monthly",' +
                        '"edition": {' +
                            '"id":1,' +
                            '"name":"Standard"' +
                        '},'+
                        '"contract":null,' +
                        '"offerType":"Regular",' +
                        '"poc":null,' +
                        '"globalPackageLimits":' +
                        '[' +
                            '{' +
                                '"value":"6000",' +
                                '"code":"MONTHLY_AMOUNT_LIMIT",' +
                                '"name":"Monthly money amount limit",' +
                                '"type":"Amount",' +
                                '"scope":"BillingCycle",' +
                                '"transactionType":"Any",' +
                                '"target":"Global",' +
                                '"exclusions":' +
                                '[' +
                                    '{' +
                                        '"target":"LicenseCategoryId",' +
                                        '"targetId":"AP"' +
                                    '}' +
                                '],' +
                                '"override":false' +
                            '}' +
                        '],' +
                        '"permissions":null' +
                    '}' +
                ']';

            List<Product2> testProducts = (List<Product2>) new SObjectBuilder(Product2.SObjectType)
                .setFields(
                    new Map<SObjectField, Object> {
                        Product2.Name => 'Test Product',
                        Product2.IsActive => true,
                        Product2.Sub_Category__c => Product2Helper.SUBCATEGORY_PROSERV,
                        Product2.Charge_Term__c => Product2Helper.CHARGE_TERM_ONE_TIME,
                        Product2.Family => 'Service'
                    }
                )
                .quantity(2)
                .create()
                .getRecords();

            PriceBook2 testPriceBook = (PriceBook2) new SObjectBuilder(PriceBook2.SObjectType)
                .setFields(new Map<SObjectField, Object> {
                    PriceBook2.Name => 'Test Price Book',
                    PriceBook2.Description => 'Test Price Book Products',
                    PriceBook2.IsActive => true,
                    PriceBook2.Line_Range_Min__c => 5,
                    PriceBook2.Service__c => 'Office',
                    PriceBook2.Plan__c => 'Monthly',
                    PriceBook2.CurrencyIsoCode => 'EUR'
                })
                .create()
                .getRecord();

            PriceBookEntry standardriceEntry = (PriceBookEntry) new SobjectBuilder(PriceBookEntry.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        PriceBookEntry.Product2Id => testProducts[0].Id,
                        PriceBookEntry.UnitPrice => 10000,
                        PriceBookEntry.IsActive => true,
                        PriceBookEntry.UseStandardPrice => false,
                        PriceBookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                        PriceBookEntry.CurrencyIsoCode => 'EUR'
                    }
                )
                .create()
                .getRecord();

            PriceBookEntry testPriceEntry = (PriceBookEntry) new SObjectBuilder(PriceBookEntry.SObjectType)
                .setFields(
                    new Map<SObjectField, Object> {
                        PriceBookEntry.Pricebook2Id => testPriceBook.Id,
                        PriceBookEntry.Product2Id => testProducts[0].Id,
                        PriceBookEntry.UnitPrice => 10000,
                        PriceBookEntry.IsActive => true,
                        PriceBookEntry.UseStandardPrice => false,
                        PriceBookEntry.CurrencyIsoCode => 'EUR'
                    }
                )
                .create()
                .getRecord();

            Id QuoteRecordType = Schema.SObjectType.Quote.getRecordTypeInfosByName().get('Sales Quote').getRecordTypeId();

            Quote testQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
                .setFields(
                    new Map<SObjectField, Object> {
                        Quote.Name => 'Sales Quote',
                        Quote.OpportunityId => testOpps[0].Id,
                        Quote.Pricebook2Id => testPriceBook.Id,
                        Quote.isPrimary__c => true,
                        Quote.RecordTypeId => QuoteRecordType,
                        Quote.Package_Info__c => packageInfo,
                        Quote.Monthly_Recurring_Revenue__c => 1000,
                        Quote.CurrencyIsoCode => 'EUR'
                    }
                )
                .create()
                .getRecord();

            QuoteLineItem testQli = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.SObjectType)
                .setFields(
                    new Map<SObjectField, Object> {
                        QuoteLineItem.QuoteId => testQuote.Id,
                        QuoteLineItem.Product2Id => testProducts[0].Id,
                        QuoteLineItem.PricebookEntryId => testPriceEntry.Id,
                        QuoteLineItem.UnitPrice => testPriceEntry.UnitPrice,
                        QuoteLineItem.Quantity => 5,
                        QuoteLineItem.NewQuantity__c => 5
                    }
                )
                .create()
                .getRecord();

            // Create Phase
            Phase__c testPhase = new Phase__c(
                Name = 'Test',
                Opportunity__c = testOpps[1].Id,
                Quote__c = testQuote.Id
            );
            insert new List<Phase__c> {testPhase};

            Triggers.switchOn();

            Id approvalRectypeID3 = Schema.SObjectType.Approval__c.getRecordTypeInfosByName().get(ApprovalHelper.RT_NAME_FARMING_CLAIM_OWNER).getRecordTypeId();
            Id approvalRectypeID4 = Schema.SObjectType.Approval__c.getRecordTypeInfosByName().get(ApprovalHelper.RT_NAME_ENGAGE_LEGAL).getRecordTypeId();

            Approval_StandardApprovalCreate.responseWrapper initialDataAcc = Approval_StandardApprovalCreate.getInitialData(testAccs[0].Id, null);
            System.assertEquals(initialDataAcc.errorMessage, null, 'Response was not return error messages');
            System.assertEquals(testContacts[0].Id, initialDataAcc.payingContactId, 'Paying Contact was not received');

            Map<Id, RecordType> recordTypesMap = new Map<Id, RecordType>(initialDataAcc.recordTypes);
            Schema.SObjectType  objType = Approval__c.SObjectType;
            for(RecordTypeInfo rt : objType.getDescribe().getRecordTypeInfos()) {
                RecordType recordType = new RecordType();
                if (!rt.isAvailable() || !rt.isActive()) {
                    recordType = recordTypesMap.get(rt.getRecordTypeId());
                    System.assertEquals(null, recordType, 'Inactive or not available RecordType was rendered for user');
                }
            }


            Approval_StandardApprovalCreate.responseWrapper res = Approval_StandardApprovalCreate.fetchFieldValues(testAccs[0].id, approvalRectypeID3, testOpps[0].Id);
            System.assertEquals(res.errorMessage, null, 'Response was not return error messages');

            res = Approval_StandardApprovalCreate.fetchFieldValues(testAccs[0].id, approvalRectypeID4, testOpps[0].Id);
            System.assertEquals(res.errorMessage, null, 'Response was not return error messages');
        Test.stopTest();
    }

    @isTest
    public static void testApprovalStandardCreate3(){
        Test.startTest();

            Triggers.switchOff();
        List<CountryCodes__c> cc = (List<CountryCodes__c>) new SObjectBuilder(CountryCodes__c.SObjectType)
                .setFields(new Map<SObjectField, Object>{
                        CountryCodes__c.Name => ValueProviderBuilder.provideList(new List<String> {'FRA', 'USA', 'GBR' }),
                        CountryCodes__c.CountryName__c => ValueProviderBuilder.provideList(new List<String> {'fra;france', 'usa;united states', 'gbr;united kingdom'}),
                        CountryCodes__c.CountryNameFull__c => ValueProviderBuilder.provideList(new List<String> {'France', 'United States, United Kingdom'}),
                        CountryCodes__c.CountryNameShort__c => ValueProviderBuilder.provideList(new List<String> {'FR','US', 'GB'})
                })
                .quantity(3)
                .create()
                .getRecords();

            Id devRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer Account').getRecordTypeId();

            List<Account> testAccs = (List<Account>) new SObjectBuilder(Account.SObjectType)
                .setFields(new Map<SObjectField, Object> {
                    Account.Name => ValueProviderBuilder.provideList(new List<String> {'goodAcc', 'goodAcc2'}),
                    Account.BillingCountry => ValueProviderBuilder.provideList(new List<String> {'United Kingdom', 'FFFFF'}),
                    Account.BillingCity => 'London',
                    Account.BillingState => 'London',
                    Account.BillingStreet => '1st',
                    Account.BillingPostalCode => '76002',
                    Account.RecordTypeId => devRecordTypeId,
                    Account.Payment_Method__c => AccountHelper.PAYMENT_METHOD_INVOICE,
                    Account.Billing_ID__c => ValueProviderBuilder.provideList(new List<String> {'12345', null})
                })
                .quantity(2)
                .create()
                .getRecords();

            List<Contact> testContacts = (List<Contact>) new SObjectBuilder(Contact.SObjectType)
                .setFields(new Map<SObjectField, Object> {
                    Contact.LastName => 'Good Contact',
                    Contact.Email => 'good@contact.com',
                    Contact.AccountId => testAccs[0].Id
                })
                .quantity(1)
                .create()
                .getRecords();

            List<AccountContactRole> testACR = (List<AccountContactRole>) new SObjectBuilder(AccountContactRole.SObjectType)
                .setFields(new Map<SObjectField, Object> {
                    AccountContactRole.AccountId => testAccs[0].Id,
                    AccountContactRole.ContactId => testContacts[0].Id,
                    AccountContactRole.Role => AccountContactRoleHelper.CONTACT_ROLE_ACCOUNT_PAYABLE
                })
                .quantity(1)
                .create()
                .getRecords();

            List<Opportunity> testOpps = (List<Opportunity>) new SObjectBuilder(Opportunity.SObjectType)
                .setFields(
                    new Map<SObjectField, Object> {
                        Opportunity.AccountId => ValueProviderBuilder.provideList(new List<Id> {testAccs[0].Id, testAccs[1].Id}),
                        Opportunity.Name => 'Test Opportunity',
                        Opportunity.StageName => '1. Draft',
                        Opportunity.Brand_Name__c => ValueProviderBuilder.provideList(new List<String> {'RingCentral UK', 'RingCentral EU'}),
                        Opportunity.closeDate => System.today(),
                        Opportunity.CurrencyIsoCode => ValueProviderBuilder.provideList(new List<String> {'EUR'}),
                        Opportunity.Is_Billing_Opportunity__c => false
                    }
                )
                .quantity(2)
                .create()
                .getRecords();

            String packageInfo =
                '[' +
                    '{' +
                        '"id":"65",' +
                        '"version":"1",' +
                        '"packageInfo": {' +
                            '"catalogId":"65",' +
                            '"version":"1",' +
                            '"name":"Office Standard 1/2/20/100+ Lines - 2021/2022/2023/2024",' +
                            '"displayName":"RingCentral Office Standard"' +
                        '},' +
                        '"productName":"Office",' +
                        '"duration":"Monthly",' +
                        '"edition": {' +
                            '"id":1,' +
                            '"name":"Standard"' +
                        '},'+
                        '"contract":null,' +
                        '"offerType":"Regular",' +
                        '"poc":null,' +
                        '"globalPackageLimits":' +
                        '[' +
                            '{' +
                                '"value":"6000",' +
                                '"code":"MONTHLY_AMOUNT_LIMIT",' +
                                '"name":"Monthly money amount limit",' +
                                '"type":"Amount",' +
                                '"scope":"BillingCycle",' +
                                '"transactionType":"Any",' +
                                '"target":"Global",' +
                                '"exclusions":' +
                                '[' +
                                    '{' +
                                        '"target":"LicenseCategoryId",' +
                                        '"targetId":"AP"' +
                                    '}' +
                                '],' +
                                '"override":false' +
                            '}' +
                        '],' +
                        '"permissions": null,' +
                        '"packageBusinessIdentities": {' +
                        '    "selectedBi": {' +
                        '        "name": "RingCentral, Ltd (France)",' +
                        '        "isDefault": true,' +
                        '        "id": "1",' +
                        '        "address": {' +
                        '            "zip": "75009",' +
                        '            "street2": "",' +
                        '            "street1": "3-5 rue Saint Georges",' +
                        '            "state": "",' +
                        '            "phone": "",' +
                        '            "lastName": "",' +
                        '            "label": null,' +
                        '            "firstName": "RingCentral France",' +
                        '            "county": "",' +
                        '            "country": "FRA",' +
                        '            "city": "Paris"' +
                        '        }' +
                        '    },' +
                        '    "defaultBi": {' +
                        '        "name": "RingCentral, Ltd (France)",' +
                        '        "isDefault": true,' +
                        '        "id": "1",' +
                        '        "address": {' +
                        '            "zip": "75009",' +
                        '            "street2": "",' +
                        '            "street1": "3-5 rue Saint Georges",' +
                        '            "state": "",' +
                        '            "phone": "",' +
                        '            "lastName": "",' +
                        '            "label": null,' +
                        '            "firstName": "RingCentral France",' +
                        '            "county": "",' +
                        '            "country": "FRA",' +
                        '            "city": "Paris"' +
                        '        }' +
                        '    },' +
                        '    "approvedBi": {' +
                        '        "name": "RingCentral, Ltd (France)",' +
                        '        "isDefault": true,' +
                        '        "id": "1",' +
                        '        "address": {' +
                        '            "zip": "75009",' +
                        '            "street2": "",' +
                        '            "street1": "3-5 rue Saint Georges",' +
                        '            "state": "",' +
                        '            "phone": "",' +
                        '            "lastName": "",' +
                        '            "label": null,' +
                        '            "firstName": "RingCentral France",' +
                        '            "county": "",' +
                        '            "country": "FRA",' +
                        '            "city": "Paris"' +
                        '        }' +
                        '    }' +
                        '}' +
                    '}' +
                ']';

            List<Product2> testProducts = (List<Product2>) new SObjectBuilder(Product2.SObjectType)
                .setFields(
                    new Map<SObjectField, Object> {
                        Product2.Name => 'Test Product',
                        Product2.IsActive => true,
                        Product2.Sub_Category__c => Product2Helper.SUBCATEGORY_PROSERV,
                        Product2.Charge_Term__c => Product2Helper.CHARGE_TERM_ONE_TIME,
                        Product2.Family => 'Service'
                    }
                )
                .quantity(2)
                .create()
                .getRecords();

            PriceBook2 testPriceBook = (PriceBook2) new SObjectBuilder(PriceBook2.SObjectType)
                .setFields(new Map<SObjectField, Object> {
                    PriceBook2.Name => 'Test Price Book',
                    PriceBook2.Description => 'Test Price Book Products',
                    PriceBook2.IsActive => true,
                    PriceBook2.Line_Range_Min__c => 5,
                    PriceBook2.Service__c => 'Office',
                    PriceBook2.Plan__c => 'Monthly',
                    PriceBook2.CurrencyIsoCode => 'EUR'
                })
                .create()
                .getRecord();

            PriceBookEntry standardriceEntry = (PriceBookEntry) new SobjectBuilder(PriceBookEntry.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        PriceBookEntry.Product2Id => testProducts[0].Id,
                        PriceBookEntry.UnitPrice => 10000,
                        PriceBookEntry.IsActive => true,
                        PriceBookEntry.UseStandardPrice => false,
                        PriceBookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                        PriceBookEntry.CurrencyIsoCode => 'EUR'
                    }
                )
                .create()
                .getRecord();

            PriceBookEntry testPriceEntry = (PriceBookEntry) new SObjectBuilder(PriceBookEntry.SObjectType)
                .setFields(
                    new Map<SObjectField, Object> {
                        PriceBookEntry.Pricebook2Id => testPriceBook.Id,
                        PriceBookEntry.Product2Id => testProducts[0].Id,
                        PriceBookEntry.UnitPrice => 10000,
                        PriceBookEntry.IsActive => true,
                        PriceBookEntry.UseStandardPrice => false,
                        PriceBookEntry.CurrencyIsoCode => 'EUR'
                    }
                )
                .create()
                .getRecord();

            Id QuoteRecordType = Schema.SObjectType.Quote.getRecordTypeInfosByName().get('Sales Quote').getRecordTypeId();

            Quote testQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
                .setFields(
                    new Map<SObjectField, Object> {
                        Quote.Name => 'Sales Quote',
                        Quote.OpportunityId => testOpps[0].Id,
                        Quote.Pricebook2Id => testPriceBook.Id,
                        Quote.isPrimary__c => true,
                        Quote.RecordTypeId => QuoteRecordType,
                        Quote.Package_Info__c => packageInfo,
                        Quote.Monthly_Recurring_Revenue__c => 1000,
                        Quote.CurrencyIsoCode => 'EUR'
                    }
                )
                .create()
                .getRecord();

            QuoteLineItem testQli = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.SObjectType)
                .setFields(
                    new Map<SObjectField, Object> {
                        QuoteLineItem.QuoteId => testQuote.Id,
                        QuoteLineItem.Product2Id => testProducts[0].Id,
                        QuoteLineItem.PricebookEntryId => testPriceEntry.Id,
                        QuoteLineItem.UnitPrice => testPriceEntry.UnitPrice,
                        QuoteLineItem.Quantity => 5,
                        QuoteLineItem.NewQuantity__c => 5
                    }
                )
                .create()
                .getRecord();

            // Create Phase
            Phase__c testPhase = new Phase__c(
                Name = 'Test',
                Opportunity__c = testOpps[1].Id,
                Quote__c = testQuote.Id
            );
            insert new List<Phase__c> {testPhase};

            Triggers.switchOn();

            Id approvalRectypeID5 = Schema.SObjectType.Approval__c.getRecordTypeInfosByName().get(ApprovalHelper.RT_NAME_FEATURE_ADD_ONS_APPROVAL).getRecordTypeId();
            Id approvalRectypeID6 = Schema.SObjectType.Approval__c.getRecordTypeInfosByName().get(ApprovalHelper.RT_NAME_TAX_EXEMPT_APPROVAL).getRecordTypeId();

            Approval_StandardApprovalCreate.responseWrapper initialDataAcc = Approval_StandardApprovalCreate.getInitialData(testAccs[0].Id, null);
            System.assertEquals(initialDataAcc.errorMessage, null, 'Response was not return error messages');
            System.assertEquals(testContacts[0].Id, initialDataAcc.payingContactId, 'Paying Contact was not received');

            Map<Id, RecordType> recordTypesMap = new Map<Id, RecordType>(initialDataAcc.recordTypes);
            Schema.SObjectType  objType = Approval__c.SObjectType;
            for(RecordTypeInfo rt : objType.getDescribe().getRecordTypeInfos()) {
                RecordType recordType = new RecordType();
                if (!rt.isAvailable() || !rt.isActive()) {
                    recordType = recordTypesMap.get(rt.getRecordTypeId());
                    System.assertEquals(null, recordType, 'Inactive or not available RecordType was rendered for user');
                }
            }

            Approval_StandardApprovalCreate.responseWrapper res = Approval_StandardApprovalCreate.fetchFieldValues(testAccs[0].id, approvalRectypeID5, testOpps[0].Id);
            System.assertEquals(null, res.errorMessage, 'Response returned error message');

            res = Approval_StandardApprovalCreate.fetchFieldValues(testAccs[0].id, approvalRectypeID6, testOpps[0].Id);
            System.assertEquals(null, res.errorMessage, 'Response returned error message');

            res = Approval_StandardApprovalCreate.fetchFieldValues(testAccs[1].id, approvalRectypeID6, testOpps[1].Id);
            System.assertNotEquals(null, res.errorMessage, 'Response returned error message');
        Test.stopTest();
    }

    @isTest
    static void testIsTaxExemptionAvailableForAccount() {
        Test.startTest();
        System.assertEquals(
            true,
            Approval_StandardApprovalCreate.isTaxExemptionAvailable(null),
            'method should return "true" if passed argument is null'
        );

        Account testAcc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Name => 'Test account'
            })
            .create()
            .getRecord();

        System.assertEquals(
            true,
            Approval_StandardApprovalCreate.isTaxExemptionAvailable(testAcc.Id),
            'method should return "true" if BillingCountry is not "Singapore" or "Australia"'
        );


        new SObjectBuilder(Feature_Toggle__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Feature_Toggle__c.SelectPackagesByBusinessIdentity__c => true
            })
            .create();

        testAcc.BillingCountry = 'Singapore';
        update testAcc;
        Test.stopTest();

        System.assertEquals(
            false,
            Approval_StandardApprovalCreate.isTaxExemptionAvailable(testAcc.Id),
            'method should return "false" if BillingCountry is "Singapore" ' +
            'and SelectPackagesByBusinessIdentity__c feature-toggle is toggled-on'
        );


        testAcc.BillingCountry = 'Australia';
        update testAcc;

        System.assertEquals(
            false,
            Approval_StandardApprovalCreate.isTaxExemptionAvailable(testAcc.Id),
            'method should return "false" if BillingCountry is "Australia" ' +
            'and SelectPackagesByBusinessIdentity__c feature-toggle is toggled-on'
        );
    }

    @isTest
    static void testIsTaxExemptionNotAvailableForSingaporeOpportunity() {
        Test.startTest();
        Account testAcc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Name => 'Test account'
            })
            .create()
            .getRecord();

        Opportunity testOpp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.Name => 'Test singapore opportunity',
                Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL_EU,
                Opportunity.CurrencyIsoCode => 'SGD'
            })
            .create()
            .getRecord();

        System.assertEquals(
            true,
            Approval_StandardApprovalCreate.isTaxExemptionAvailable(testOpp.Id),
            'method should return "true" for singapore opportunity(Brand is "RingCentral EU" and Currency is "SGD") ' +
            'if SelectPackagesByBusinessIdentity__c feature-toggle is toggled-off'
        );


        new SObjectBuilder(Feature_Toggle__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Feature_Toggle__c.SelectPackagesByBusinessIdentity__c => true
            })
            .create();
        Test.stopTest();

        System.assertEquals(
            false,
            Approval_StandardApprovalCreate.isTaxExemptionAvailable(testOpp.Id),
            'method should return "false" for singapore opportunity(Brand is "RingCentral EU" and Currency is "SGD") ' +
            'if SelectPackagesByBusinessIdentity__c feature-toggle is toggled-on'
        );
    }

    @isTest
    public static void testCalculateMRV() {
        Account testAccount = (Account) new SobjectBuilder(Account.SObjectType)
            .setField(Account.Name, 'Test account')
            .create()
            .getRecord();

        Opportunity testOpp = (Opportunity) new SobjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.AccountId => testAccount.Id,
                Opportunity.Is_Billing_Opportunity__c => true,
                Opportunity.Name => 'TestOpportunity',
                Opportunity.Brand_Name__c => 'RingCentral',
                Opportunity.Tier_Name__c => 'Office',
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                Opportunity.CloseDate => System.today(),
                Opportunity.CurrencyIsoCode => 'USD'
            })
            .create()
            .getRecord();

        PriceBook2 testPriceBook = (PriceBook2) new SObjectBuilder(PriceBook2.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                PriceBook2.Name => ValueProviderBuilder.provideUniqueString('test pricebook'),
                PriceBook2.Description => ValueProviderBuilder.provideUniqueString('description'),
                PriceBook2.IsActive => true,
                PriceBook2.Line_Range_Min__c => 2,
                PriceBook2.Service__c => Pricebook2Helper.SERVICE_OFFICE,
                PriceBook2.Plan__c => Pricebook2Helper.PLAN_MONTHLY
            })
            .create()
            .getRecord();

        List<Product2> testProducts = new SobjectBuilder(Product2.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Product2.Name => ValueProviderBuilder.provideUniqueString('testProduct'),
                Product2.IsActive => true,
                Product2.Sub_Category__c => Product2Helper.SUBCATEGORY_RINGCENTRAL,
                Product2.Family => Product2Helper.FAMILY_SERVICE,
                Product2.Feature__c => Product2Helper.FEATURE_SERVICE_PLAN
            })
            .create()
            .getRecords();

        List<PricebookEntry> stdPBEList = new SobjectBuilder(PricebookEntry.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                PricebookEntry.Product2Id => ValueProviderBuilder.provideParents(testProducts),
                PricebookEntry.UnitPrice => 200,
                PricebookEntry.IsActive => true,
                PricebookEntry.UseStandardPrice => false,
                PricebookEntry.CurrencyIsoCode => 'USD'
            })
            .create()
            .getRecords();

        List<PricebookEntry> pBEList = new SobjectBuilder(PricebookEntry.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                PricebookEntry.Pricebook2Id => testPriceBook.Id,
                PricebookEntry.Product2Id => ValueProviderBuilder.provideParents(testProducts),
                PricebookEntry.UnitPrice => 200,
                PricebookEntry.IsActive => true,
                PricebookEntry.UseStandardPrice => false,
                PricebookEntry.CurrencyIsoCode => 'USD'
            })
            .create()
            .getRecords();

        Quote testBillingQuote = (Quote) new SobjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Quote.Name => 'TestBillingQuote',
                Quote.OpportunityId => testOpp.Id,
                Quote.Pricebook2Id => testPriceBook.Id,
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING
            })
            .create()
            .getRecord();

        Decimal quoteLineItemQuantity = 7;

        List<QuoteLineItem> qlis = new SobjectBuilder(QuoteLineItem.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                QuoteLineItem.Product2Id => ValueProviderBuilder.provideParents(testProducts),
                QuoteLineItem.PricebookEntryId => ValueProviderBuilder.provideParents(pBEList),
                QuoteLineItem.QuoteId => testBillingQuote.Id,
                QuoteLineItem.Quantity => quoteLineItemQuantity,
                QuoteLineItem.Discount_type__c => QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY,
                QuoteLineItem.Discount_Number__c => 10,
                QuoteLineItem.UnitPrice => 200,
                QuoteLineItem.PackageInfo__c => '{"duration":"Monthly"}'
            })
            .build()
            .getRecords();
        Test.startTest();
        insert qlis;
        System.assertEquals(1330, Approval_StandardApprovalCreate.calculateMRV(testBillingQuote.Id));
        Test.stopTest();
    }

    @IsTest
    private static void testKycApprovalStandardCreate() {
        Account testAcc = (Account) new SObjectBuilder(Account.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Name => 'testAcc'
            })
            .create()
            .getRecord();
        Approval__c sourceApproval = (Approval__c) new SObjectBuilder(Approval__c.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Approval__c.Name => 'Source Approval',
                Approval__c.Account__c => testAcc.Id,
                Approval__c.RecordTypeId => ApprovalHelper.RT_ID_KYC_APPROVAL_REQUEST,
                Approval__c.DateOfSignOff__c => System.today()
            })
            .build()
            .getRecord();

        final List<SObjectField> picklistFields = new List<SObjectField>{
            Approval__c.GenderOfAuthorisedSignatory__c,
            Approval__c.Gst__c,
            Approval__c.TypeOfCustomer__c
        };
        for (SObjectField field: picklistFields) {
            sourceApproval.put(field, field.getDescribe().getPicklistValues().get(0).getValue());
        }
        final List<String> textFields = new List<String>{
            'Area__c',
            'City__c',
            'CoDoSoWoHo__c',
            'District__c',
            'RcPointOfPresence__c',
            'GstStateNameOfCustomer__c',
            'HouseNo__c',
            'Landmark__c',
            'NameOfFatherOrHusband__c',
            'NameOfTheAuthorisedSignatory__c',
            'NationalityOfAuthorisedSignatory__c',
            'State__c',
            'StreetAddress__c'
        };
        for (String field: textFields) {
            sourceApproval.put(field, String.valueOf(Math.random() * 1000));
        }
        sourceApproval.PanGirNo__c = '1234567890';
        sourceApproval.PinCode__c = '132456';
        sourceApproval.State__c = 'Assam';
        sourceApproval.GenderOfAuthorisedSignatory__c = 'Male';
        sourceApproval.DateOfBirthOfAuthorisedSignatory__c = System.today().addYears(-20);
        sourceApproval.PurposeForProcuringTheService__c = 'Telemarketing';
        sourceApproval.Other__c = 'Other';
        sourceApproval.KycFiles__c = 'file1;file2;file3;file4;file5;file6;file7;file8;file9';
        sourceApproval.GstNo__c = '1234567890';
        insert sourceApproval;
        new SObjectBuilder(LocalSubscribedAddress__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    LocalSubscribedAddress__c.Approval__c => sourceApproval.Id,
                    LocalSubscribedAddress__c.RecordTypeId => LocalSubscribedAddressHelper.RT_ID_REGISTERED_ADDRESS_OF_COMPANY
                }
            )
            .create();
        Approval.ProcessResult result = ApprovalHelper.setApprovalAction(sourceApproval.Id, 'Approve', 'Ok');

        Test.startTest();
        Approval_StandardApprovalCreate.ResponseWrapper res =
            Approval_StandardApprovalCreate.fetchFieldValues(testAcc.Id, ApprovalHelper.RT_ID_KYC_APPROVAL_REQUEST, null);
        Test.stopTest();

        List<String> kycFields = new List<String>{'DateOfSignOff__c'};
        kycFields.addAll(textFields);
        for (SObjectField field: picklistFields) {
            kycFields.add(field.getDescribe().getName());
        }
        Map<String, Object> resultMap = res.kycApprovalFieldsToValuesMap;
        for (String field: kycFields) {
            System.assert(sourceApproval.get(field) == resultMap.get(field),
                'New KYC approval ' + field + ' field should have the same values as approved source one');
        }
    }

    @IsTest
    private static void testCreditLimitApprovalStandardCreate_negative() {
        Approval_StandardApprovalCreate.ResponseWrapper res;
        Account testAcc = (Account) new SObjectBuilder(Account.SObjectType)
                .setFields(
                        new Map<SObjectField, Object>{
                                Account.Name => ValueProviderBuilder.provideUniqueString('Test account'),
                                Account.Partner_ID__c => '1234567',
                                Account.Payment_Method__c => 'Invoice',
                                Account.Payment_Plan__c => 'Monthly',
                                Account.RC_User_ID__c => '400389021061'
                        }
                )
                .create()
                .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
                .setField(Opportunity.RecordTypeId, OpportunityHelper.RT_ID_NEW_SALES_OPPORTUNITY)
                .setField(Opportunity.Brand_Name__c, OpportunityHelper.BRAND_RINGCENTRAL_EU)
                .setField(Opportunity.AccountId, testAcc.Id)
                .create()
                .getRecord();

        Test.startTest();
        res = Approval_StandardApprovalCreate.fetchFieldCreditLimitValues(testAcc.Id, ApprovalHelper.RT_ID_CREDIT_LIMIT_INCREASE, opp.Id);
        System.assert(
            res.errorMessage != null,
            'Got an amount for a Credit limit Increase Approval for new business'
        );
        System.assertEquals(
            Approval_StandardApprovalCreate.ERROR_CREDIT_LIMIT_INCREASE_APPROVAL_MUST_BE_CREATED_EXISTING_BUSINESS,
            res.errorMessage,
            'Wrong error msg when getting amount for a Credit limit Increase Approval for new business'
        );

        testAcc.Billing_ID__c = '1111111';
        Triggers.switchOff();
        update testAcc;
        Triggers.switchOn();

        res = Approval_StandardApprovalCreate.fetchFieldCreditLimitValues(null, ApprovalHelper.RT_ID_CREDIT_LIMIT_INCREASE, opp.Id);
        System.assert(
            res.errorMessage != null,
            'Got an amount for Credit limit Increase Approval without any quotes'
        );
        System.assertEquals(
            Approval_StandardApprovalCreate.ERROR_YOU_HAVE_TO_CLOSE_THE_OPPORTUNITY,
            res.errorMessage,
            'Wrong error msg when getting amount for a Credit limit Increase Approval without any quotes'
        );

        Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
                .setFields(new Map<SObjectField, Object> {
                        Quote.Name => ValueProviderBuilder.provideUniqueString('Test Billing Quote'),
                        Quote.OpportunityId => opp.Id,
                        Quote.Account__c => testAcc.Id,
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

        Approval__c appr = (Approval__c) new SObjectBuilder(Approval__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                    Approval__c.Quote__c => qt.Id,
                    Approval__c.Opportunity__c => qt.OpportunityId,
                    Approval__c.Account__c => qt.Account__c,
                    Approval__c.RecordTypeId => ApprovalHelper.RT_ID_CREDIT_LIMIT_INCREASE,
                    Approval__c.NGBSAmountToIncrease__c => 40000
            })
            .create()
            .getRecord();

        res = Approval_StandardApprovalCreate.fetchFieldCreditLimitValues(testAcc.Id, ApprovalHelper.RT_ID_CREDIT_LIMIT_INCREASE, null);
        System.assert(
            res.errorMessage != null,
            'Got an amount for a Credit limit Increase Approval when such approval already exists'
        );
        System.assertEquals(
            Approval_StandardApprovalCreate.ERROR_SUBMITTED_CREDIT_LIMIT_APPROVAL_ALREADY_EXIST,
            res.errorMessage,
            'Wrong error msg when getting amount for a Credit limit Increase Approval when such approval already exists'
        );
    }

    @IsTest
    private static void testCreditLimitApprovalStandardCreate_noServiceAccounts() {
        Approval_StandardApprovalCreate.ResponseWrapper res;
        Account testAcc = (Account) new SObjectBuilder(Account.SObjectType)
                .setFields(
                        new Map<SObjectField, Object>{
                                Account.Name => ValueProviderBuilder.provideUniqueString('Test account'),
                                Account.Partner_ID__c => '1234567',
                                Account.Payment_Method__c => 'Invoice',
                                Account.Payment_Plan__c => 'Monthly',
                                Account.RC_User_ID__c => '400389021061',
                                Account.Billing_ID__c => '1111111'
                        }
                )
                .create()
                .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
                .setField(Opportunity.RecordTypeId, OpportunityHelper.RT_ID_NEW_SALES_OPPORTUNITY)
                .setField(Opportunity.Brand_Name__c, OpportunityHelper.BRAND_RINGCENTRAL_EU)
                .setField(Opportunity.AccountId, testAcc.Id)
                .create()
                .getRecord();

        Test.startTest();
        res = Approval_StandardApprovalCreate.fetchFieldCreditLimitValues(testAcc.Id, ApprovalHelper.RT_ID_CREDIT_LIMIT_INCREASE, opp.Id);
        System.assertEquals(
            Approval_StandardApprovalCreate.ERROR_UNEXPECTED_ERROR_HAS_OCCURRED,
            res.errorMessage,
            'Wrong error msg when getting amount for a Credit limit Increase Approval with no service account present'
        );
    }

    @IsTest
    private static void testCreditLimitApprovalStandardCreate_nonCreditLimit() {
        Approval_StandardApprovalCreate.ResponseWrapper res;
        Account testAcc = (Account) new SObjectBuilder(Account.SObjectType)
                .setFields(
                        new Map<SObjectField, Object>{
                                Account.Name => ValueProviderBuilder.provideUniqueString('Test account'),
                                Account.Partner_ID__c => '1234567',
                                Account.Payment_Method__c => 'Invoice',
                                Account.Payment_Plan__c => 'Monthly',
                                Account.RC_User_ID__c => '400389021061',
                                Account.Billing_ID__c => '1111111'
                        }
                )
                .create()
                .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
                .setField(Opportunity.RecordTypeId, OpportunityHelper.RT_ID_NEW_SALES_OPPORTUNITY)
                .setField(Opportunity.Brand_Name__c, OpportunityHelper.BRAND_RINGCENTRAL_EU)
                .setField(Opportunity.AccountId, testAcc.Id)
                .create()
                .getRecord();

        Test.startTest();
        res = Approval_StandardApprovalCreate.fetchFieldCreditLimitValues(testAcc.Id, ApprovalHelper.RT_ID_INVOICING_REQUEST, opp.Id);
        System.assert(
            res.errorMessage == null,
            'fetchFieldCreditLimitValues failed to handle another approval record type correctly'
        );
    }

    @IsTest
    private static void testCreditLimitApprovalStandardCreate() {
        Approval_StandardApprovalCreate.ResponseWrapper res;
        Account testAcc = (Account) new SObjectBuilder(Account.SObjectType)
                .setFields(
                        new Map<SObjectField, Object>{
                                Account.Name => ValueProviderBuilder.provideUniqueString('Test account'),
                                Account.Partner_ID__c => '1234567',
                                Account.Payment_Method__c => 'Invoice',
                                Account.Payment_Plan__c => 'Monthly',
                                Account.RC_User_ID__c => '400389021061',
                                Account.Billing_ID__c => '1111111'
                        }
                )
                .create()
                .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
                .setField(Opportunity.RecordTypeId, OpportunityHelper.RT_ID_NEW_SALES_OPPORTUNITY)
                .setField(Opportunity.Brand_Name__c, OpportunityHelper.BRAND_RINGCENTRAL_EU)
                .setField(Opportunity.AccountId, testAcc.Id)
                .create()
                .getRecord();

        Package__c pack = (Package__c) new SObjectBuilder(Package__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Package__c.Account__c => testAcc.Id,
                Package__c.Enterprise_Account_ID__c => testAcc.Id,
                Package__c.Account_Package_Id__c => testAcc.Billing_ID__c
            })
            .create()
            .getRecord();
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new Mock());
        NGBSAPI.settings.Login = 'TestUser';
        NGBSAPI.settings.Password = 'TestPassword';
        res = Approval_StandardApprovalCreate.fetchFieldCreditLimitValues(testAcc.Id, ApprovalHelper.RT_ID_CREDIT_LIMIT_INCREASE, opp.Id);
        System.assert(
            res.errorMessage == null,
            'fetchFieldCreditLimitValues failed to retrieve a credit limit'
        );
    }

    @IsTest
    static void testCheckingNotApprovedIndianAccount() {
        List<Account> testAccs =  (List<Account>) new SObjectBuilder(Account.SObjectType)
            .quantity(2)
            .create()
            .getRecords();
        new SObjectBuilder(Approval__c.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Approval__c.Name => 'KYC Approval',
                Approval__c.Account__c => testAccs[0].Id,
                Approval__c.RecordTypeId => ApprovalHelper.RT_ID_KYC_APPROVAL_REQUEST,
                Approval__c.DateOfSignOff__c => System.today()
            })
            .create();

        Test.startTest();
            Boolean resForApprovedIndianAcc = Approval_StandardApprovalCreate.isNotApprovedIndianAccount(testAccs[0].Id);
            Boolean resForNotIndianAcc = Approval_StandardApprovalCreate.isNotApprovedIndianAccount(testAccs[1].Id);
        Test.stopTest();

        System.assert(resForApprovedIndianAcc,
            'It is not approved Indian account, KYC Approval is in \'Pending Approval\' status');
        System.assert(!resForNotIndianAcc,
            'It is not Indian account so result should be false');
    }

    @isTest
    static void testIsTaxExemptionNotAvailableForAustraliaOpportunity() {

        Account testAcc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Name => 'Test account'
            })
            .create()
            .getRecord();

        Opportunity testOpp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.Name => 'Test australia opportunity',
                Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL_AU,
                Opportunity.CurrencyIsoCode => 'AUD'
            })
            .create()
            .getRecord();

        System.assertEquals(
            true,
            Approval_StandardApprovalCreate.isTaxExemptionAvailable(testOpp.Id),
            'method should return "true" for singapore opportunity(Brand is "RingCentral AU" and Currency is "AUD") ' +
            'if SelectPackagesByBusinessIdentity__c feature-toggle is toggled-off'
        );


        new SObjectBuilder(Feature_Toggle__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Feature_Toggle__c.SelectPackagesByBusinessIdentity__c => true
            })
            .create();

        System.assertEquals(
            false,
            Approval_StandardApprovalCreate.isTaxExemptionAvailable(testOpp.Id),
            'method should return "false" for singapore opportunity(Brand is "RingCentral AU" and Currency is "AUD") ' +
            'if SelectPackagesByBusinessIdentity__c feature-toggle is toggled-on'
        );
    }

    @isTest
    static void testCreateTaxExemptionApprovalForOpportunity() {
        Triggers.switchOff();

        Id devRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer Account').getRecordTypeId();

        List<Account> testAccs = (List<Account>) new SObjectBuilder(Account.SObjectType)
                .setFields(new Map<SObjectField, Object> {
                        Account.Name => ValueProviderBuilder.provideList(new List<String> {'accTaxTest', 'accTaxTest'}),
                        Account.BillingCountry => ValueProviderBuilder.provideList(new List<String> {'Germany', 'FFFFF'}),
                        Account.BillingCity => 'Berlin',
                        Account.BillingStreet => '1st',
                        Account.BillingPostalCode => '76002',
                        Account.RecordTypeId => devRecordTypeId,
                        Account.Billing_ID__c => ValueProviderBuilder.provideList(new List<String> {'12345', null})
                })
                .quantity(2)
                .create()
                .getRecords();

        List<Contact> testContacts = (List<Contact>) new SObjectBuilder(Contact.SObjectType)
                .setFields(new Map<SObjectField, Object> {
                        Contact.LastName => 'Good Contact',
                        Contact.Email => 'good@contact.com',
                        Contact.AccountId => testAccs[0].Id
                })
                .quantity(1)
                .create()
                .getRecords();

        List<AccountContactRole> testACR = (List<AccountContactRole>) new SObjectBuilder(AccountContactRole.SObjectType)
                .setFields(new Map<SObjectField, Object> {
                        AccountContactRole.AccountId => testAccs[0].Id,
                        AccountContactRole.ContactId => testContacts[0].Id,
                        AccountContactRole.Role => AccountContactRoleHelper.CONTACT_ROLE_ACCOUNT_PAYABLE
                })
                .quantity(1)
                .create()
                .getRecords();

        List<Opportunity> testOpps = (List<Opportunity>) new SObjectBuilder(Opportunity.SObjectType)
                .setFields(
                        new Map<SObjectField, Object> {
                                Opportunity.AccountId => ValueProviderBuilder.provideList(new List<Id> {testAccs[0].Id, testAccs[1].Id}),
                                Opportunity.Name => 'Test Opportunity',
                                Opportunity.StageName => '1. Draft',
                                Opportunity.Brand_Name__c => ValueProviderBuilder.provideList(new List<String> {'RingCentral UK', 'RingCentral EU'}),
                                Opportunity.closeDate => System.today(),
                                Opportunity.CurrencyIsoCode => ValueProviderBuilder.provideList(new List<String> {'EUR'}),
                                Opportunity.Is_Billing_Opportunity__c => false
                        }
                )
                .quantity(2)
                .create()
                .getRecords();

        String packageInfo = '[{"id":"65","version":"2","packageInfo":{"catalogId":"65","version":"2","name":"MVP Standard 1/2/20/100+ Lines - 2021/2022/2023/2024","displayName":"RingCentral MVP Standard"},"productName":"Office","productId":"2","duration":"Monthly","edition":{"id":1,"name":"Standard"},"contract":{"id":"a8f8D0000004COzQAM","extId":"Office_Europe","billingId":null},"offerType":"Regular","poc":null,"globalPackageLimits":[{"code":"MONTHLY_AMOUNT_LIMIT","name":"Monthly money amount limit","type":"Amount","scope":"BillingCycle","transactionType":"Any","target":"Global","exclusions":[{"target":"LicenseCategoryId","targetId":"AP"}],"override":false,"value":"6000"}],"permissions":null,"packageBusinessIdentities":{"selectedBi":{"name":"RingCentral, Ltd (France)","isDefault":true,"id":"1","address":{"zip":"75009","street2":"","street1":"3-5 rue Saint Georges","state":"","phone":"","lastName":"","label":null,"firstName":"RingCentral France","county":"","country":"FRA","city":"Paris"}},"defaultBi":{"name":"RingCentral, Ltd (France)","isDefault":true,"id":"1","address":{"zip":"75009","street2":"","street1":"3-5 rue Saint Georges","state":"","phone":"","lastName":"","label":null,"firstName":"RingCentral France","county":"","country":"FRA","city":"Paris"}},"approvedBi":{"name":"RingCentral, Ltd (France)","isDefault":true,"id":"1","address":{"zip":"75009","street2":"","street1":"3-5 rue Saint Georges","state":"","phone":"","lastName":"","label":null,"firstName":"RingCentral France","county":"","country":"FRA","city":"Paris"}}},"existingPackageInfo":{}}]';
        Id QuoteRecordType = Schema.SObjectType.Quote.getRecordTypeInfosByName().get('Sales Quote v2').getRecordTypeId();

        List<Product2> testProducts = (List<Product2>) new SObjectBuilder(Product2.SObjectType)
                .setFields(
                        new Map<SObjectField, Object> {
                                Product2.Name => 'Test Product',
                                Product2.IsActive => true,
                                Product2.Sub_Category__c => Product2Helper.SUBCATEGORY_PROSERV,
                                Product2.Charge_Term__c => Product2Helper.CHARGE_TERM_ONE_TIME,
                                Product2.Family => 'Service'
                        }
                )
                .quantity(2)
                .create()
                .getRecords();

        PriceBook2 testPriceBook = (PriceBook2) new SObjectBuilder(PriceBook2.SObjectType)
                .setFields(new Map<SObjectField, Object> {
                        PriceBook2.Name => 'Test Price Book',
                        PriceBook2.Description => 'Test Price Book Products',
                        PriceBook2.IsActive => true,
                        PriceBook2.Line_Range_Min__c => 5,
                        PriceBook2.Service__c => 'Office',
                        PriceBook2.Plan__c => 'Monthly',
                        PriceBook2.CurrencyIsoCode => 'EUR'
                })
                .create()
                .getRecord();

        PriceBookEntry standardriceEntry = (PriceBookEntry) new SobjectBuilder(PriceBookEntry.SObjectType)
                .setFields(
                        new Map<SObjectField, Object>{
                                PriceBookEntry.Product2Id => testProducts[0].Id,
                                PriceBookEntry.UnitPrice => 10000,
                                PriceBookEntry.IsActive => true,
                                PriceBookEntry.UseStandardPrice => false,
                                PriceBookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                                PriceBookEntry.CurrencyIsoCode => 'EUR'
                        }
                )
                .create()
                .getRecord();

        PriceBookEntry testPriceEntry = (PriceBookEntry) new SObjectBuilder(PriceBookEntry.SObjectType)
                .setFields(
                        new Map<SObjectField, Object> {
                                PriceBookEntry.Pricebook2Id => testPriceBook.Id,
                                PriceBookEntry.Product2Id => testProducts[0].Id,
                                PriceBookEntry.UnitPrice => 10000,
                                PriceBookEntry.IsActive => true,
                                PriceBookEntry.UseStandardPrice => false,
                                PriceBookEntry.CurrencyIsoCode => 'EUR'
                        }
                )
                .create()
                .getRecord();

        Quote testQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
                .setFields(
                        new Map<SObjectField, Object> {
                                Quote.Name => 'Sales Quote test',
                                Quote.OpportunityId => testOpps[0].Id,
                                Quote.Pricebook2Id => testPriceBook.Id,
                                Quote.isPrimary__c => true,
                                Quote.RecordTypeId => QuoteRecordType,
                                Quote.Package_Info__c => packageInfo,
                                Quote.Monthly_Recurring_Revenue__c => 1000,
                                Quote.CurrencyIsoCode => 'EUR'
                        }
                )
                .create()
                .getRecord();

        QuoteLineItem testQli = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.SObjectType)
                .setFields(
                        new Map<SObjectField, Object> {
                                QuoteLineItem.QuoteId => testQuote.Id,
                                QuoteLineItem.Product2Id => testProducts[0].Id,
                                QuoteLineItem.PricebookEntryId => testPriceEntry.Id,
                                QuoteLineItem.UnitPrice => testPriceEntry.UnitPrice,
                                QuoteLineItem.Quantity => 5,
                                QuoteLineItem.NewQuantity__c => 5
                        }
                )
                .create()
                .getRecord();


        Triggers.switchOff();
        List<CountryCodes__c> countryCodes = new List<CountryCodes__c>();
        CountryCodes__c ccFrance = new CountryCodes__c(CountryName__c = 'France;fra', Name = 'FRA');
        CountryCodes__c ccGermany = new CountryCodes__c(CountryName__c = 'Germany;deu', Name = 'DEU');

        countryCodes.add(ccFrance);
        countryCodes.add(ccGermany);

        insert countryCodes;

        Approval_StandardApprovalCreate.responseWrapper initialDataOpp = Approval_StandardApprovalCreate.getInitialData(testOpps[0].Id, null);
        System.assertEquals(initialDataOpp.errorMessage, null, 'Response was not return error messages');
        System.assertEquals(testContacts[0].Id, initialDataOpp.payingContactId, 'Paying Contact was not received');

        Id approvalRectypeID = Schema.SObjectType.Approval__c.getRecordTypeInfosByName().get(ApprovalHelper.RT_NAME_TAX_EXEMPT_APPROVAL).getRecordTypeId();
        Approval_StandardApprovalCreate.responseWrapper res = Approval_StandardApprovalCreate.fetchFieldValues(testAccs[0].id, approvalRectypeID, testOpps[0].Id);
        res = Approval_StandardApprovalCreate.fetchFieldValues(testAccs[0].id, approvalRectypeID, testOpps[0].Id);
        System.assertEquals(res.errorMessage, null, 'Response was not return error messages');

        testQuote.Package_Info__c = testQuote.Package_Info__c.replaceAll('FRA', 'DEU');
        Triggers.switchOff();
        update testQuote;
        Triggers.switchOn();
        Approval_StandardApprovalCreate.responseWrapper res2 = Approval_StandardApprovalCreate.fetchFieldValues(testAccs[0].id, approvalRectypeID, testOpps[0].Id);
        res2 = Approval_StandardApprovalCreate.fetchFieldValues(testAccs[0].id, approvalRectypeID, testOpps[0].Id);
        System.debug('res2.errorMessage ' + res2.errorMessage);
        System.assertEquals(res2.errorMessage, 'VAT exemption is not available for this country!', 'Response was not return error messages');

        Triggers.switchOff();

        testQuote.Package_Info__c = '[{"id":"65","version":"2","packageInfo":{"catalogId":"65","version":"2","name":"MVP Standard 1/2/20/100+ Lines - 2021/2022/2023/2024","displayName":"RingCentral MVP Standard"},"productName":"Office","productId":"2","duration":"Monthly","edition":{"id":1,"name":"Standard"},"contract":{"id":"a8f8D0000004COzQAM","extId":"Office_Europe","billingId":null},"offerType":"Regular","poc":null,"globalPackageLimits":[{"code":"MONTHLY_AMOUNT_LIMIT","name":"Monthly money amount limit","type":"Amount","scope":"BillingCycle","transactionType":"Any","target":"Global","exclusions":[{"target":"LicenseCategoryId","targetId":"AP"}],"override":false,"value":"6000"}],"permissions":null,"existingPackageInfo":{}}]';
        update testQuote;
        Triggers.switchOn();

        Approval_StandardApprovalCreate.getInitialData(testOpps[0].Id, null);
        Approval_StandardApprovalCreate.responseWrapper res3 = Approval_StandardApprovalCreate.fetchFieldValues(testAccs[0].id, approvalRectypeID, testOpps[0].Id);
        res3 = Approval_StandardApprovalCreate.fetchFieldValues(testAccs[0].id, approvalRectypeID, testOpps[0].Id);
        System.assertEquals(res3.errorMessage, 'VAT exemption is not available for this quote due to BI absence (the quote may be too old). Please re-create the quote.', 'Response was not return error messages');
    }

    @IsTest
    private static void testValidateVatIdExemption() {
        Triggers.switchOff();

        Id devRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer Account').getRecordTypeId();

        List<Account> testAccounts = (List<Account>) new SObjectBuilder(Account.SObjectType)
                .setFields(new Map<SObjectField, Object> {
                        Account.Name => ValueProviderBuilder.provideList(new List<String> {'test1', 'test2', 'test3'}),
                        Account.BillingCountry => ValueProviderBuilder.provideList(new List<String> {'Switzeland', 'Switzeland',  null}),
                        Account.BillingCity => 'Bern',
                        Account.BillingStreet => 'Bundesplatz 1',
                        Account.BillingPostalCode => '94002',
                        Account.RecordTypeId => devRecordTypeId,
                        Account.VATNumber__c => ValueProviderBuilder.provideList(new List<String> {'123123', null, '123123'})
                })
                .quantity(3)
                .create()
                .getRecords();

        Triggers.switchOn();

        List<RecordType> recordTypes1 = Approval_StandardApprovalCreate.getRecordTypes(true, true, true);
        List<RecordType> recordTypes2 = recordTypes1.clone();
        List<RecordType> recordTypes3 = recordTypes1.clone();

        System.assert(recordTypes1.size() > 0);

        Integer size1 = recordTypes1.size();
        Integer size2 = recordTypes2.size();
        Integer size3 = recordTypes3.size();

        Approval_StandardApprovalCreate.validateVatIdExemption(testAccounts.get(0), recordTypes1);
        Approval_StandardApprovalCreate.validateVatIdExemption(testAccounts.get(1), recordTypes2);
        Approval_StandardApprovalCreate.validateVatIdExemption(testAccounts.get(2), recordTypes3);

        System.assertEquals(recordTypes1.size(), size1 - 1, 'Error 1');
        System.assertEquals(recordTypes2.size(), size2 - 1, 'Error 2');
        System.assertEquals(recordTypes3.size(), size3 - 1, 'Error 3');
    }

    @IsTest
    private static void testInvoiceApprovalFields() {
        Triggers.switchOff();
        Id devRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer Account').getRecordTypeId();
        List<Account> testAccs = (List<Account>) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Name => ValueProviderBuilder.provideList(new List<String> {'goodAcc', 'goodAcc2'}),
                Account.BillingCountry => ValueProviderBuilder.provideList(new List<String> {'United Kingdom', 'FFFFF'}),
                Account.BillingCity => 'London',
                Account.BillingState => 'London',
                Account.BillingStreet => '1st',
                Account.BillingPostalCode => '76002',
                Account.RecordTypeId => devRecordTypeId,
                Account.Payment_Method__c => AccountHelper.PAYMENT_METHOD_INVOICE,
                Account.Billing_ID__c => ValueProviderBuilder.provideList(new List<String> {'12345', null})
            })
            .quantity(2)
            .create()
            .getRecords();

        List<Opportunity> testOpps = (List<Opportunity>) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    Opportunity.AccountId => ValueProviderBuilder.provideList(new List<Id> {testAccs[0].Id, testAccs[1].Id}),
                    Opportunity.Name => 'Test Opportunity',
                    Opportunity.StageName => '1. Draft',
                    Opportunity.Brand_Name__c => ValueProviderBuilder.provideList(new List<String> {'RingCentral UK', 'RingCentral EU'}),
                    Opportunity.closeDate => System.today(),
                    Opportunity.CurrencyIsoCode => ValueProviderBuilder.provideList(new List<String> {'EUR'}),
                    Opportunity.Is_Billing_Opportunity__c => false
                }
            )
            .quantity(2)
            .create()
            .getRecords();

        Id approvalRectypeID = Schema.SObjectType.Approval__c.getRecordTypeInfosByDeveloperName().get(ApprovalHelper.RT_DEV_NAME_INVOICING_REQUEST).getRecordTypeId();

        Test.startTest();
        Approval_StandardApprovalCreate.responseWrapper res = Approval_StandardApprovalCreate.fetchFieldValues(testAccs[0].id, approvalRectypeID, testOpps[0].Id);
        System.assertEquals(testAccs[0].BillingStreet, res.legal_physical_address_street);
        System.assertEquals(testAccs[0].BillingCity, res.legal_physical_address_city);
        System.assertEquals(testAccs[0].BillingState, res.legal_physical_address_state_province);
        System.assertEquals(testAccs[0].BillingCountry, res.legal_physical_address_country);
        System.assertEquals(testAccs[0].BillingPostalCode, res.legal_physical_address_zip_code);
        System.assertEquals(testAccs[0].SegmentName__c, res.account_segment);
        System.assertEquals(testAccs[0].Payment_Plan__c, res.payment_plan);
        Test.stopTest();
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @IsTest
    private static void testAnnualLimitFieldsOnApproval () {
        Triggers.switchOff();
        Id devRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer Account').getRecordTypeId();
        List<Account> testAccs = (List<Account>) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Name => ValueProviderBuilder.provideList(new List<String> {'goodAcc', 'goodAcc2'}),
                Account.BillingCountry => ValueProviderBuilder.provideList(new List<String> {'United Kingdom', 'FFFFF'}),
                Account.BillingCity => 'London',
                Account.BillingState => 'London',
                Account.BillingStreet => '1st',
                Account.BillingPostalCode => '76002',
                Account.RecordTypeId => devRecordTypeId,
                Account.Payment_Method__c => AccountHelper.PAYMENT_METHOD_INVOICE,
                Account.Billing_ID__c => ValueProviderBuilder.provideList(new List<String> {'12345', null})
            })
            .quantity(2)
            .create()
            .getRecords();

        List<Contact> testContacts = (List<Contact>) new SObjectBuilder(Contact.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Contact.LastName => 'Good Contact',
                Contact.Email => 'good@contact.com',
                Contact.AccountId => testAccs[0].Id
            })
            .quantity(1)
            .create()
            .getRecords();

        List<AccountContactRole> testACR = (List<AccountContactRole>) new SObjectBuilder(AccountContactRole.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                AccountContactRole.AccountId => testAccs[0].Id,
                AccountContactRole.ContactId => testContacts[0].Id,
                AccountContactRole.Role => AccountContactRoleHelper.CONTACT_ROLE_ACCOUNT_PAYABLE
            })
            .quantity(1)
            .create()
            .getRecords();

        List<Opportunity> testOpps = (List<Opportunity>) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    Opportunity.AccountId => ValueProviderBuilder.provideList(new List<Id> {testAccs[0].Id, testAccs[1].Id}),
                    Opportunity.Name => 'Test Opportunity',
                    Opportunity.StageName => '1. Draft',
                    Opportunity.Brand_Name__c => ValueProviderBuilder.provideList(new List<String> {'RingCentral UK', 'RingCentral EU'}),
                    Opportunity.closeDate => System.today(),
                    Opportunity.CurrencyIsoCode => ValueProviderBuilder.provideList(new List<String> {'EUR'}),
                    Opportunity.Is_Billing_Opportunity__c => false
                }
            )
            .quantity(2)
            .create()
            .getRecords();

        String packageInfo =
            '[' +
                '{' +
                    '"id":"65",' +
                    '"version":"1",' +
                    '"packageInfo": {' +
                        '"catalogId":"65",' +
                        '"version":"1",' +
                        '"name":"Office Standard 1/2/20/100+ Lines - 2021/2022/2023/2024",' +
                        '"displayName":"RingCentral Office Standard"' +
                    '},' +
                    '"productName":"Office",' +
                    '"duration":"Monthly",' +
                    '"edition": {' +
                        '"id":1,' +
                        '"name":"Standard"' +
                    '},'+
                    '"contract":null,' +
                    '"offerType":"Regular",' +
                    '"poc":null,' +
                    '"globalPackageLimits":' +
                    '[' +
                        '{' +
                            '"value":"6000",' +
                            '"code":"MONTHLY_AMOUNT_LIMIT",' +
                            '"name":"Monthly money amount limit",' +
                            '"type":"Amount",' +
                            '"scope":"BillingCycle",' +
                            '"transactionType":"Any",' +
                            '"target":"Global",' +
                            '"exclusions":' +
                            '[' +
                                '{' +
                                    '"target":"LicenseCategoryId",' +
                                    '"targetId":"AP"' +
                                '}' +
                            '],' +
                            '"override":false' +
                        '}' +
                    '],' +
                    '"permissions":null' +
                '}' +
            ']';

        List<Product2> testProducts = (List<Product2>) new SObjectBuilder(Product2.SObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    Product2.Name => 'Test Product',
                    Product2.IsActive => true,
                    Product2.Sub_Category__c => Product2Helper.SUBCATEGORY_PROSERV,
                    Product2.Charge_Term__c => Product2Helper.CHARGE_TERM_ONE_TIME,
                    Product2.Family => 'Service'
                }
            )
            .quantity(2)
            .create()
            .getRecords();

        PriceBook2 testPriceBook = (PriceBook2) new SObjectBuilder(PriceBook2.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                PriceBook2.Name => 'Test Price Book',
                PriceBook2.Description => 'Test Price Book Products',
                PriceBook2.IsActive => true,
                PriceBook2.Line_Range_Min__c => 5,
                PriceBook2.Service__c => 'Office',
                PriceBook2.Plan__c => 'Monthly',
                PriceBook2.CurrencyIsoCode => 'EUR'
            })
            .create()
            .getRecord();

        PriceBookEntry standardriceEntry = (PriceBookEntry) new SobjectBuilder(PriceBookEntry.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    PriceBookEntry.Product2Id => testProducts[0].Id,
                    PriceBookEntry.UnitPrice => 10000,
                    PriceBookEntry.IsActive => true,
                    PriceBookEntry.UseStandardPrice => false,
                    PriceBookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                    PriceBookEntry.CurrencyIsoCode => 'EUR'
                }
            )
            .create()
            .getRecord();

        PriceBookEntry testPriceEntry = (PriceBookEntry) new SObjectBuilder(PriceBookEntry.SObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    PriceBookEntry.Pricebook2Id => testPriceBook.Id,
                    PriceBookEntry.Product2Id => testProducts[0].Id,
                    PriceBookEntry.UnitPrice => 10000,
                    PriceBookEntry.IsActive => true,
                    PriceBookEntry.UseStandardPrice => false,
                    PriceBookEntry.CurrencyIsoCode => 'EUR'
                }
            )
            .create()
            .getRecord();

        Id QuoteRecordType = Schema.SObjectType.Quote.getRecordTypeInfosByName().get('Sales Quote').getRecordTypeId();

        Quote testQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    Quote.Name => 'Sales Quote',
                    Quote.OpportunityId => testOpps[0].Id,
                    Quote.Pricebook2Id => testPriceBook.Id,
                    Quote.isPrimary__c => true,
                    Quote.RecordTypeId => QuoteRecordType,
                    Quote.Package_Info__c => packageInfo,
                    Quote.Monthly_Recurring_Revenue__c => 1000,
                    Quote.CurrencyIsoCode => 'EUR',
                    Quote.Payment_Period__c => QuoteHelper.ANNUAL_PAYMENT_METHOD
                }
            )
            .create()
            .getRecord();

        QuoteLineItem testQli = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    QuoteLineItem.QuoteId => testQuote.Id,
                    QuoteLineItem.Product2Id => testProducts[0].Id,
                    QuoteLineItem.PricebookEntryId => testPriceEntry.Id,
                    QuoteLineItem.UnitPrice => testPriceEntry.UnitPrice,
                    QuoteLineItem.Quantity => 5
                }
            )
            .create()
            .getRecord();

        Triggers.switchOn();
        Id approvalRectypeID = Schema.SObjectType.Approval__c.getRecordTypeInfosByDeveloperName().get(ApprovalHelper.RT_DEV_NAME_INVOICING_REQUEST).getRecordTypeId();
        Test.startTest();
        Approval_StandardApprovalCreate.responseWrapper res = Approval_StandardApprovalCreate.fetchFieldValues(testAccs[0].id, approvalRectypeID, testOpps[0].Id);

        Test.stopTest();
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @IsTest
    private static void testMonthlyLimitFieldsOnApproval () {
        Triggers.switchOff();
        Id devRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer Account').getRecordTypeId();
        List<Account> testAccs = (List<Account>) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Name => ValueProviderBuilder.provideList(new List<String> {'goodAcc', 'goodAcc2'}),
                Account.BillingCountry => ValueProviderBuilder.provideList(new List<String> {'United Kingdom', 'FFFFF'}),
                Account.BillingCity => 'London',
                Account.BillingState => 'London',
                Account.BillingStreet => '1st',
                Account.BillingPostalCode => '76002',
                Account.RecordTypeId => devRecordTypeId,
                Account.Payment_Method__c => AccountHelper.PAYMENT_METHOD_INVOICE,
                Account.Billing_ID__c => ValueProviderBuilder.provideList(new List<String> {'12345', null})
            })
            .quantity(2)
            .create()
            .getRecords();

        List<Contact> testContacts = (List<Contact>) new SObjectBuilder(Contact.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Contact.LastName => 'Good Contact',
                Contact.Email => 'good@contact.com',
                Contact.AccountId => testAccs[0].Id
            })
            .quantity(1)
            .create()
            .getRecords();

        List<AccountContactRole> testACR = (List<AccountContactRole>) new SObjectBuilder(AccountContactRole.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                AccountContactRole.AccountId => testAccs[0].Id,
                AccountContactRole.ContactId => testContacts[0].Id,
                AccountContactRole.Role => AccountContactRoleHelper.CONTACT_ROLE_ACCOUNT_PAYABLE
            })
            .quantity(1)
            .create()
            .getRecords();

        List<Opportunity> testOpps = (List<Opportunity>) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    Opportunity.AccountId => ValueProviderBuilder.provideList(new List<Id> {testAccs[0].Id, testAccs[1].Id}),
                    Opportunity.Name => 'Test Opportunity',
                    Opportunity.StageName => '1. Draft',
                    Opportunity.Brand_Name__c => ValueProviderBuilder.provideList(new List<String> {'RingCentral UK', 'RingCentral EU'}),
                    Opportunity.closeDate => System.today(),
                    Opportunity.CurrencyIsoCode => ValueProviderBuilder.provideList(new List<String> {'EUR'}),
                    Opportunity.Is_Billing_Opportunity__c => false
                }
            )
            .quantity(2)
            .create()
            .getRecords();

        String packageInfo =
            '[' +
                '{' +
                    '"id":"65",' +
                    '"version":"1",' +
                    '"packageInfo": {' +
                        '"catalogId":"65",' +
                        '"version":"1",' +
                        '"name":"Office Standard 1/2/20/100+ Lines - 2021/2022/2023/2024",' +
                        '"displayName":"RingCentral Office Standard"' +
                    '},' +
                    '"productName":"Office",' +
                    '"duration":"Monthly",' +
                    '"edition": {' +
                        '"id":1,' +
                        '"name":"Standard"' +
                    '},'+
                    '"contract":null,' +
                    '"offerType":"Regular",' +
                    '"poc":null,' +
                    '"globalPackageLimits":' +
                    '[' +
                        '{' +
                            '"value":"6000",' +
                            '"code":"MONTHLY_AMOUNT_LIMIT",' +
                            '"name":"Monthly money amount limit",' +
                            '"type":"Amount",' +
                            '"scope":"BillingCycle",' +
                            '"transactionType":"Any",' +
                            '"target":"Global",' +
                            '"exclusions":' +
                            '[' +
                                '{' +
                                    '"target":"LicenseCategoryId",' +
                                    '"targetId":"AP"' +
                                '}' +
                            '],' +
                            '"override":false' +
                        '}' +
                    '],' +
                    '"permissions":null' +
                '}' +
            ']';

        List<Product2> testProducts = (List<Product2>) new SObjectBuilder(Product2.SObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    Product2.Name => 'Test Product',
                    Product2.IsActive => true,
                    Product2.Sub_Category__c => Product2Helper.SUBCATEGORY_PROSERV,
                    Product2.Charge_Term__c => Product2Helper.CHARGE_TERM_ONE_TIME,
                    Product2.Family => 'Service'
                }
            )
            .quantity(2)
            .create()
            .getRecords();

        PriceBook2 testPriceBook = (PriceBook2) new SObjectBuilder(PriceBook2.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                PriceBook2.Name => 'Test Price Book',
                PriceBook2.Description => 'Test Price Book Products',
                PriceBook2.IsActive => true,
                PriceBook2.Line_Range_Min__c => 5,
                PriceBook2.Service__c => 'Office',
                PriceBook2.Plan__c => 'Monthly',
                PriceBook2.CurrencyIsoCode => 'EUR'
            })
            .create()
            .getRecord();

        PriceBookEntry standardriceEntry = (PriceBookEntry) new SobjectBuilder(PriceBookEntry.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    PriceBookEntry.Product2Id => testProducts[0].Id,
                    PriceBookEntry.UnitPrice => 10000,
                    PriceBookEntry.IsActive => true,
                    PriceBookEntry.UseStandardPrice => false,
                    PriceBookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                    PriceBookEntry.CurrencyIsoCode => 'EUR'
                }
            )
            .create()
            .getRecord();

        PriceBookEntry testPriceEntry = (PriceBookEntry) new SObjectBuilder(PriceBookEntry.SObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    PriceBookEntry.Pricebook2Id => testPriceBook.Id,
                    PriceBookEntry.Product2Id => testProducts[0].Id,
                    PriceBookEntry.UnitPrice => 10000,
                    PriceBookEntry.IsActive => true,
                    PriceBookEntry.UseStandardPrice => false,
                    PriceBookEntry.CurrencyIsoCode => 'EUR'
                }
            )
            .create()
            .getRecord();

        Id QuoteRecordType = Schema.SObjectType.Quote.getRecordTypeInfosByName().get('Sales Quote').getRecordTypeId();

        Quote testQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    Quote.Name => 'Sales Quote',
                    Quote.OpportunityId => testOpps[0].Id,
                    Quote.Pricebook2Id => testPriceBook.Id,
                    Quote.isPrimary__c => true,
                    Quote.RecordTypeId => QuoteRecordType,
                    Quote.Package_Info__c => packageInfo,
                    Quote.Monthly_Recurring_Revenue__c => 1000,
                    Quote.CurrencyIsoCode => 'EUR',
                    Quote.Payment_Period__c => QuoteHelper.MONTHLY_PAYMENT_METHOD
                }
            )
            .create()
            .getRecord();

        QuoteLineItem testQli = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    QuoteLineItem.QuoteId => testQuote.Id,
                    QuoteLineItem.Product2Id => testProducts[0].Id,
                    QuoteLineItem.PricebookEntryId => testPriceEntry.Id,
                    QuoteLineItem.UnitPrice => testPriceEntry.UnitPrice,
                    QuoteLineItem.Quantity => 5
                }
            )
            .create()
            .getRecord();

        Triggers.switchOn();
        Id approvalRectypeID = Schema.SObjectType.Approval__c.getRecordTypeInfosByDeveloperName().get(ApprovalHelper.RT_DEV_NAME_INVOICING_REQUEST).getRecordTypeId();
        Test.startTest();
        Approval_StandardApprovalCreate.responseWrapper res = Approval_StandardApprovalCreate.fetchFieldValues(testAccs[0].id, approvalRectypeID, testOpps[0].Id);

        Test.stopTest();
    }

    @IsTest
    private static void testPrepopulateMonthlyMultiProductLimitsForNB () {
        Triggers.switchOff();

        Account testMasterAccount = (Account) new SObjectBuilder(Account.sObjectType)
            .setField(Account.IsMultiProductTechnicalAccount__c, false)
            .create()
            .getRecord();

        List<Account> testAccounts = (List<Account>) new SObjectBuilder(Account.SObjectType)
            .setField(Account.IsMultiProductTechnicalAccount__c, true)
            .setField(Account.Master_Account__c, testMasterAccount.Id)
            .setField(Account.Service_Type__c, ValueProviderBuilder.provideList(new List<String>{
                'RingCentral Contact Center',
                'Engage Voice Standalone',
                'Engage Digital Standalone'
            }))
            .quantity(3)
            .create()
            .getRecords();

        Opportunity testMasterOpportunity = (Opportunity) new SObjectBuilder(Opportunity.sObjectType)
            .setField(Opportunity.AccountId, testMasterAccount.Id)
            .setField(Opportunity.CloseDate, system.today().addMonths(1))
            .setField(Opportunity.IsMultiProductTechnicalOpportunity__c, false)
            .setField(Opportunity.Estimated_12M_Office_Pipeline__c, 120)
            .setField(Opportunity.Estimated_12M_Contact_Center_Pipeline__c, 240)
            .setField(Opportunity.Estimated_12M_Engage_Voice_Pipeline__c, 360)
            .setField(Opportunity.Estimated_12M_Engage_Digital_Pipeline__c, 372)
            .setField(Opportunity.Estimated_Hardware__c, 30)
            .setField(Opportunity.Estimated_One_Time_Pipeline__c, 100)
            .setField(Opportunity.EstimatedProfessionalServices12Month__c, 200)
            .create()
            .getRecord();

        List<Opportunity> testOpportunities = (List<Opportunity>) new SObjectBuilder(Opportunity.sObjectType)
            .setField(Opportunity.AccountId, ValueProviderBuilder.provideList(new List<Id>{testAccounts.get(0).Id, testAccounts.get(1).Id, testAccounts.get(2).Id}))
            .setField(Opportunity.MasterOpportunity__c, testMasterOpportunity.Id)
            .setField(Opportunity.IsMultiProductTechnicalOpportunity__c, true)
            .setField(Opportunity.Estimated_One_Time_Pipeline__c, ValueProviderBuilder.provideList(new List<Integer>{15, 9, 6}))
            .quantity(3)
            .create()
            .getRecords();

        BillingWrappers.QuotePackageInfo pInfoOffice = new BillingWrappers.QuotePackageInfo();
        pInfoOffice.productName = QuoteHelper.NGBS_OFFICE_PRODUCT;

        BillingWrappers.QuotePackageInfo pInfoCC = new BillingWrappers.QuotePackageInfo();
        pInfoCC.productName = QuoteHelper.NGBS_RCCC_PRODUCT;

        BillingWrappers.QuotePackageInfo pInfoEV = new BillingWrappers.QuotePackageInfo();
        pInfoEV.productName = QuoteHelper.NGBS_ENGAGE_VOICE_PRODUCT;

        BillingWrappers.QuotePackageInfo pInfoED = new BillingWrappers.QuotePackageInfo();
        pInfoED.productName = QuoteHelper.NGBS_ENGAGE_DIGITAL_PRODUCT;

        Quote testMasterQuote = (Quote) new SObjectBuilder(Quote.sObjectType)
            .setField(Quote.IsPrimary__c, true)
            .setField(Quote.OpportunityId, testMasterOpportunity.Id)
            .setField(Quote.Payment_Period__c, QuoteHelper.MONTHLY_PAYMENT_METHOD)
            .setField(Quote.Package_Info__c, JSON.serialize(new List<BillingWrappers.QuotePackageInfo>{pInfoOffice}))
            .create()
            .getRecord();

            List<Quote> testQuotes = (List<Quote>) new SObjectBuilder(Quote.sObjectType)
            .setField(Quote.IsPrimary__c, false)
            .setField(Quote.OpportunityId, ValueProviderBuilder.provideList(new List<Id>{testMasterOpportunity.Id, testOpportunities.get(0).Id, testOpportunities.get(1).Id, testOpportunities.get(2).Id }))
            .setField(Quote.MasterQuote__c, testMasterQuote.Id)
            .setField(Quote.Package_Info__c, ValueProviderBuilder.provideList(new List<String>{
                JSON.serialize(new List<BillingWrappers.QuotePackageInfo>{pInfoOffice}),
                JSON.serialize(new List<BillingWrappers.QuotePackageInfo>{pInfoCC}),
                JSON.serialize(new List<BillingWrappers.QuotePackageInfo>{pInfoEV}),
                JSON.serialize(new List<BillingWrappers.QuotePackageInfo>{pInfoED})
                })
            )
            .quantity(4)
            .create()
            .getRecords();

        testMasterOpportunity.PrimaryQuote__c = testMasterQuote.Id;

        update testMasterOpportunity;

        Id approvalRectypeID = Schema.SObjectType.Approval__c.getRecordTypeInfosByName().get(ApprovalHelper.INVOICING_REQUEST_APPROVAL_RT_NAME).getRecordTypeId();

        Triggers.switchOn();

        Test.startTest();

        //Invoice request approval from opportunity
        Approval_StandardApprovalCreate.responseWrapper res = Approval_StandardApprovalCreate.fetchFieldValues(null, approvalRectypeID, testMasterOpportunity.Id);

        System.assertEquals('620.0', res.signUpPurchaseLimitOffice, 'signUpPurchaseLimitOffice is not calculated correctly');
        System.assertEquals('470.0', res.signUpPurchaseLimitContactCenter, 'signUpPurchaseLimitContactCenter is not calculated correctly');
        System.assertEquals('20.0', res.monthlycredLimitOffice, 'monthlycredLimitOffice is not calculated correctly');
        System.assertEquals('60.0', res.monthlycredLimitEngageVoice, 'monthlycredLimitEngageVoice is not calculated correctly');


        //Invoice request approval from account
        Approval_StandardApprovalCreate.responseWrapper res2 = Approval_StandardApprovalCreate.fetchFieldValues(testMasterAccount.Id, approvalRectypeID, null);

        System.assertEquals('620.0', res2.signUpPurchaseLimitOffice, 'signUpPurchaseLimitOffice is not calculated correctly');
        System.assertEquals('470.0', res2.signUpPurchaseLimitContactCenter, 'signUpPurchaseLimitContactCenter is not calculated correctly');
        System.assertEquals('20.0', res2.monthlycredLimitOffice, 'monthlycredLimitOffice is not calculated correctly');
        System.assertEquals('60.0', res2.monthlycredLimitEngageVoice, 'monthlycredLimitEngageVoice is not calculated correctly');

        Test.stopTest();
    }

    @IsTest
    private static void testPrepopulateMultiProductLimitsForNB () {
        new SObjectBuilder(Feature_Toggle__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Feature_Toggle__c.EnableMultiProductUnifiedBilling__c => true
            })
            .create();

        Triggers.switchOff();

        Account testMasterAccount = (Account) new SObjectBuilder(Account.sObjectType)
            .setField(Account.IsMultiProductTechnicalAccount__c, false)
            .create()
            .getRecord();

        Opportunity testMasterOpportunity = (Opportunity) new SObjectBuilder(Opportunity.sObjectType)
            .setField(Opportunity.AccountId, testMasterAccount.Id)
            .setField(Opportunity.CloseDate, system.today().addMonths(1))
            .setField(Opportunity.Type, OpportunityHelper.OPPORTUNITY_TYPE_NEW_BUSINESS)
            .setField(Opportunity.IsMultiProductTechnicalOpportunity__c, false)
            .create()
            .getRecord();

        BillingWrappers.QuotePackageInfo pInfoOffice = new BillingWrappers.QuotePackageInfo();
        pInfoOffice.productName = QuoteHelper.NGBS_OFFICE_PRODUCT;

        BillingWrappers.QuotePackageInfo pInfoCC = new BillingWrappers.QuotePackageInfo();
        pInfoCC.productName = QuoteHelper.NGBS_RCCC_PRODUCT;

        BillingWrappers.QuotePackageInfo pInfoEV = new BillingWrappers.QuotePackageInfo();
        pInfoEV.productName = QuoteHelper.NGBS_ENGAGE_VOICE_PRODUCT;

        BillingWrappers.QuotePackageInfo pInfoED = new BillingWrappers.QuotePackageInfo();
        pInfoED.productName = QuoteHelper.NGBS_ENGAGE_DIGITAL_PRODUCT;

        BillingWrappers.QuotePackageInfo pInfoProServ = new BillingWrappers.QuotePackageInfo();
        pInfoProServ.productName = QuoteHelper.NGBS_PROFESSIONAL_SERVICES_PRODUCT;

        List<String> serviceNames = new List<String> {
            QuoteHelper.NGBS_OFFICE_PRODUCT,
            QuoteHelper.NGBS_RCCC_PRODUCT,
            QuoteHelper.NGBS_ENGAGE_VOICE_PRODUCT,
            QuoteHelper.NGBS_ENGAGE_DIGITAL_PRODUCT,
            QuoteHelper.NGBS_PROFESSIONAL_SERVICES_PRODUCT
        };

        PriceBook2 testPriceBook = (PriceBook2) new SObjectBuilder(PriceBook2.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                PriceBook2.Name => ValueProviderBuilder.provideUniqueString('test pricebook'),
                PriceBook2.Description => ValueProviderBuilder.provideUniqueString('description'),
                PriceBook2.IsActive => true,
                PriceBook2.Line_Range_Min__c => 2,
                PriceBook2.Service__c => Pricebook2Helper.SERVICE_OFFICE,
                PriceBook2.Plan__c => Pricebook2Helper.PLAN_MONTHLY
            })
            .create()
            .getRecord();

        List<Product2> testProducts = (List<Product2>) new SObjectBuilder(Product2.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Product2.Name => ValueProviderBuilder.provideList(new List<String> { 'Test_Product', 'Test_Product1', 'Test_Product2', 'Test_Product3', 'Test_Product4'}),
                Product2.IsActive => true,
                Product2.Sub_Category__c => Product2Helper.SUBCATEGORY_RINGCENTRAL,
                Product2.Family => Product2Helper.FAMILY_SERVICE,
                Product2.Feature__c => Product2Helper.FEATURE_SERVICE_PLAN,
                Product2.Billing_Type__c => Product2Helper.BILLING_TYPE_RECURRING,
                Product2.Charge_Term__c => Product2Helper.CHARGE_TERM_MONTHLY
            })
            .quantity(5)
            .create()
            .getRecords();

        List<PricebookEntry> stdPBEList = new SobjectBuilder(PricebookEntry.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                PricebookEntry.Product2Id => testProducts.get(0).Id,
                PricebookEntry.UnitPrice => 200,
                PricebookEntry.IsActive => true,
                PricebookEntry.UseStandardPrice => false,
                PricebookEntry.CurrencyIsoCode => 'USD'
            })
            .create()
            .getRecords();

        List<PricebookEntry> pBEList = new SobjectBuilder(PricebookEntry.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                PricebookEntry.Pricebook2Id => testPriceBook.Id,
                PricebookEntry.Product2Id => testProducts.get(0).Id,
                PricebookEntry.UnitPrice => 200,
                PricebookEntry.IsActive => true,
                PricebookEntry.UseStandardPrice => false,
                PricebookEntry.CurrencyIsoCode => 'USD'
            })
            .create()
            .getRecords();

        Quote testMasterQuote = (Quote) new SObjectBuilder(Quote.sObjectType)
            .setField(Quote.IsPrimary__c, true)
            .setField(Quote.OpportunityId, testMasterOpportunity.Id)
            .setField(Quote.Payment_Period__c, QuoteHelper.MONTHLY_PAYMENT_METHOD)
            .setField(Quote.Package_Info__c, JSON.serialize(new List<BillingWrappers.QuotePackageInfo>{ pInfoOffice, pInfoCC, pInfoEV, pInfoED, pInfoProServ }))
            .create()
            .getRecord();

        List<Quote> testQuotes = (List<Quote>) new SObjectBuilder(Quote.sObjectType)
            .setField(Quote.IsPrimary__c, false)
            .setField(Quote.OpportunityId, testMasterOpportunity.Id)
            .setField(Quote.MasterQuote__c, testMasterQuote.Id)
            .setField(Quote.Pricebook2Id, testPriceBook.Id)
            .setField(Quote.ServiceName__c, ValueProviderBuilder.provideList(serviceNames))
            .setField(Quote.Monthly_Recurring_Revenue__c, ValueProviderBuilder.provideList(new List<Integer>{ 1000, 2000, 3000, 2000, 2000 }))
            .setField(Quote.Package_Info__c, ValueProviderBuilder.provideList(new List<String>{
                JSON.serialize(new List<BillingWrappers.QuotePackageInfo>{ pInfoOffice }),
                JSON.serialize(new List<BillingWrappers.QuotePackageInfo>{ pInfoCC }),
                JSON.serialize(new List<BillingWrappers.QuotePackageInfo>{ pInfoEV }),
                JSON.serialize(new List<BillingWrappers.QuotePackageInfo>{ pInfoED }),
                JSON.serialize(new List<BillingWrappers.QuotePackageInfo>{ pInfoProServ })
                })
            )
            .quantity(5)
            .create()
            .getRecords();

        Decimal quoteLineItemQuantity = 7;

        List<QuoteLineItem> qlis = new SobjectBuilder(QuoteLineItem.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                QuoteLineItem.Product2Id => ValueProviderBuilder.provideList(new List<String> {  testProducts.get(0).Id,  testProducts.get(1).Id,  testProducts.get(2).Id,  testProducts.get(3).Id, testProducts.get(4).Id}),
                QuoteLineItem.PricebookEntryId => ValueProviderBuilder.provideParents(pBEList),
                QuoteLineItem.QuoteId => ValueProviderBuilder.provideList(new List<Id>{ testQuotes.get(0).Id, testQuotes.get(1).Id, testQuotes.get(2).Id, testQuotes.get(3).Id, testQuotes.get(4).Id }),
                QuoteLineItem.Quantity => quoteLineItemQuantity,
                QuoteLineItem.Discount_type__c => QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY,
                QuoteLineItem.Discount_Number__c => 10,
                QuoteLineItem.NewQuantity__c => quoteLineItemQuantity,
                QuoteLineItem.UnitPrice => 200,
                QuoteLineItem.PackageInfo__c => '{"duration":"Monthly"}'
            })
            .quantity(5)
            .create()
            .getRecords();

        Id approvalRectypeID = Schema.SObjectType.Approval__c.getRecordTypeInfosByName().get(ApprovalHelper.INVOICING_REQUEST_APPROVAL_RT_NAME).getRecordTypeId();

        Triggers.switchOn();

        Test.startTest();

        //Invoice request approval from opportunity
        Approval_StandardApprovalCreate.responseWrapper res = Approval_StandardApprovalCreate.fetchFieldValues(null, approvalRectypeID, testMasterOpportunity.Id);

        Assert.areEqual('2100.000', res.signUpPurchaseLimitOffice, 'signUpPurchaseLimitOffice is not calculated correctly');
        Assert.areEqual('2100.000', res.signUpPurchaseLimitContactCenter, 'signUpPurchaseLimitContactCenter is not calculated correctly');
        Assert.areEqual('2100.000', res.monthlycredLimitOffice, 'monthlycredLimitOffice is not calculated correctly');
        Assert.areEqual('2100.000', res.monthlycredLimitContactCenter, 'monthlycredLimitContactCenter is not calculated correctly');
        Assert.areEqual('2100.000', res.monthlycredLimitEngageVoice, 'monthlycredLimitEngageVoice is not calculated correctly');
        Assert.areEqual('2100.000', res.monthlycredLimitEngageDigital, 'monthlycredLimitEngageDigital is not calculated correctly');
        Assert.areEqual('2100.000', res.signUpPurchaseLimitProServ, 'signUpPurchaseLimitProServ is not calculated correctly');
        Assert.areEqual('2100.000', res.monthlycredLimitProServ, 'monthlycredLimitProServ is not calculated correctly');

        Test.stopTest();
    }

    @IsTest
    private static void testPrepopulateAnnualMultiProductLimitsForNB () {
        Triggers.switchOff();

        Account testMasterAccount = (Account) new SObjectBuilder(Account.sObjectType)
            .setField(Account.IsMultiProductTechnicalAccount__c, false)
            .create()
            .getRecord();

        List<Account> testAccounts = (List<Account>) new SObjectBuilder(Account.SObjectType)
            .setField(Account.IsMultiProductTechnicalAccount__c, true)
            .setField(Account.Master_Account__c, testMasterAccount.Id)
            .setField(Account.Service_Type__c, ValueProviderBuilder.provideList(new List<String>{
                'RingCentral Contact Center',
                'Engage Voice Standalone',
                'Engage Digital Standalone'
            }))
            .quantity(3)
            .create()
            .getRecords();

        Opportunity testMasterOpportunity = (Opportunity) new SObjectBuilder(Opportunity.sObjectType)
            .setField(Opportunity.AccountId, testMasterAccount.Id)
            .setField(Opportunity.CloseDate, system.today().addMonths(1))
            .setField(Opportunity.IsMultiProductTechnicalOpportunity__c, false)
            .setField(Opportunity.Estimated_12M_Office_Pipeline__c, 120)
            .setField(Opportunity.Estimated_12M_Contact_Center_Pipeline__c, 240)
            .setField(Opportunity.Estimated_12M_Engage_Voice_Pipeline__c, 360)
            .setField(Opportunity.Estimated_12M_Engage_Digital_Pipeline__c, 372)
            .setField(Opportunity.Estimated_Hardware__c, 30)
            .setField(Opportunity.Estimated_One_Time_Pipeline__c, 100)
            .setField(Opportunity.EstimatedProfessionalServices12Month__c, 200)
            .create()
            .getRecord();

        List<Opportunity> testOpportunities = (List<Opportunity>) new SObjectBuilder(Opportunity.sObjectType)
            .setField(Opportunity.AccountId, ValueProviderBuilder.provideList(new List<Id>{testAccounts.get(0).Id, testAccounts.get(1).Id, testAccounts.get(2).Id}))
            .setField(Opportunity.MasterOpportunity__c, testMasterOpportunity.Id)
            .setField(Opportunity.IsMultiProductTechnicalOpportunity__c, true)
            .setField(Opportunity.Estimated_One_Time_Pipeline__c, ValueProviderBuilder.provideList(new List<Integer>{15, 9, 6}))
            .quantity(3)
            .create()
            .getRecords();

        BillingWrappers.QuotePackageInfo pInfoOffice = new BillingWrappers.QuotePackageInfo();
        pInfoOffice.productName = QuoteHelper.NGBS_OFFICE_PRODUCT;

        BillingWrappers.QuotePackageInfo pInfoCC = new BillingWrappers.QuotePackageInfo();
        pInfoCC.productName = QuoteHelper.NGBS_RCCC_PRODUCT;

        BillingWrappers.QuotePackageInfo pInfoEV = new BillingWrappers.QuotePackageInfo();
        pInfoEV.productName = QuoteHelper.NGBS_ENGAGE_VOICE_PRODUCT;

        BillingWrappers.QuotePackageInfo pInfoED = new BillingWrappers.QuotePackageInfo();
        pInfoED.productName = QuoteHelper.NGBS_ENGAGE_DIGITAL_PRODUCT;

        Quote testMasterQuote = (Quote) new SObjectBuilder(Quote.sObjectType)
            .setField(Quote.IsPrimary__c, true)
            .setField(Quote.OpportunityId, testMasterOpportunity.Id)
            .setField(Quote.Payment_Period__c, QuoteHelper.ANNUAL_PAYMENT_METHOD)
            .setField(Quote.Package_Info__c, JSON.serialize(new List<BillingWrappers.QuotePackageInfo>{pInfoOffice}))
            .create()
            .getRecord();

            List<Quote> testQuotes = (List<Quote>) new SObjectBuilder(Quote.sObjectType)
            .setField(Quote.IsPrimary__c, false)
            .setField(Quote.OpportunityId, ValueProviderBuilder.provideList(new List<Id>{testMasterOpportunity.Id, testOpportunities.get(0).Id, testOpportunities.get(1).Id, testOpportunities.get(2).Id }))
            .setField(Quote.MasterQuote__c, testMasterQuote.Id)
            .setField(Quote.Package_Info__c, ValueProviderBuilder.provideList(new List<String>{
                JSON.serialize(new List<BillingWrappers.QuotePackageInfo>{pInfoOffice}),
                JSON.serialize(new List<BillingWrappers.QuotePackageInfo>{pInfoCC}),
                JSON.serialize(new List<BillingWrappers.QuotePackageInfo>{pInfoEV}),
                JSON.serialize(new List<BillingWrappers.QuotePackageInfo>{pInfoED})
                })
            )
            .quantity(4)
            .create()
            .getRecords();

        testMasterOpportunity.PrimaryQuote__c = testMasterQuote.Id;

        update testMasterOpportunity;

        Id approvalRectypeID = Schema.SObjectType.Approval__c.getRecordTypeInfosByName().get(ApprovalHelper.INVOICING_REQUEST_APPROVAL_RT_NAME).getRecordTypeId();

        Triggers.switchOn();

        Test.startTest();

        //Invoice request approval from opportunity
        Approval_StandardApprovalCreate.responseWrapper res = Approval_StandardApprovalCreate.fetchFieldValues(null, approvalRectypeID, testMasterOpportunity.Id);

        System.assertEquals('840.0', res.signUpPurchaseLimitOffice, 'signUpPurchaseLimitOffice is not calculated correctly');
        System.assertEquals('910.0', res.signUpPurchaseLimitContactCenter, 'signUpPurchaseLimitContactCenter is not calculated correctly');
        System.assertEquals('20.0', res.monthlycredLimitOffice, 'monthlycredLimitOffice is not calculated correctly');
        System.assertEquals('60.0', res.monthlycredLimitEngageVoice, 'monthlycredLimitEngageVoice is not calculated correctly');


        //Invoice request approval from account
        Approval_StandardApprovalCreate.responseWrapper res2 = Approval_StandardApprovalCreate.fetchFieldValues(testMasterAccount.Id, approvalRectypeID, null);

        System.assertEquals('840.0', res2.signUpPurchaseLimitOffice, 'signUpPurchaseLimitOffice is not calculated correctly');
        System.assertEquals('910.0', res2.signUpPurchaseLimitContactCenter, 'signUpPurchaseLimitContactCenter is not calculated correctly');
        System.assertEquals('20.0', res2.monthlycredLimitOffice, 'monthlycredLimitOffice is not calculated correctly');
        System.assertEquals('60.0', res2.monthlycredLimitEngageVoice, 'monthlycredLimitEngageVoice is not calculated correctly');

        Test.stopTest();
    }

    @IsTest
    private static void testPrepopulateAnnualMultiProductLimitsForEB () {
        Triggers.switchOff();

        Account testMasterAccount = (Account) new SObjectBuilder(Account.sObjectType)
            .setField(Account.IsMultiProductTechnicalAccount__c, false)
            .setField(Account.RC_User_ID__c, ValueProviderBuilder.provideUniqueString())
            .setField(Account.RC_Account_Status__c, AccountHelper.PAID_STATUS)
            .setField(Account.Account_Payment_Method__c, AccountHelper.PAYMENT_METHOD_CREDIT_CARD)
            .setField(Account.MRR__c, 19.0)
            .create()
            .getRecord();

        List<Account> testAccounts = (List<Account>) new SObjectBuilder(Account.SObjectType)
            .setField(Account.IsMultiProductTechnicalAccount__c, true)
            .setField(Account.Master_Account__c, testMasterAccount.Id)
            .setField(Account.Service_Type__c, ValueProviderBuilder.provideList(new List<String>{
                'RingCentral Contact Center',
                'Engage Voice Standalone',
                'Engage Digital Standalone'
            }))
            .setField(Account.RC_User_ID__c, ValueProviderBuilder.provideList(new List<String>{
                '654343858',
                '546434575',
                '658564564'
            }))
            .setField(Account.RC_Account_Status__c, AccountHelper.PAID_STATUS)
            .setField(Account.Account_Payment_Method__c, AccountHelper.PAYMENT_METHOD_CREDIT_CARD)
            .quantity(3)
            .create()
            .getRecords();

        Opportunity testMasterOpportunity = (Opportunity) new SObjectBuilder(Opportunity.sObjectType)
            .setField(Opportunity.AccountId, testMasterAccount.Id)
            .setField(Opportunity.CloseDate, system.today().addMonths(1))
            .setField(Opportunity.IsMultiProductTechnicalOpportunity__c, false)
            .setField(Opportunity.Estimated_12M_Office_Pipeline__c, 120)
            .setField(Opportunity.Estimated_Hardware__c, 30)
            .setField(Opportunity.Estimated_One_Time_Pipeline__c, 100)
            .setField(Opportunity.EstimatedProfessionalServices12Month__c, 200)
            .create()
            .getRecord();

        List<Opportunity> testOpportunities = (List<Opportunity>) new SObjectBuilder(Opportunity.sObjectType)
            .setField(Opportunity.AccountId, ValueProviderBuilder.provideList(new List<Id>{testAccounts.get(0).Id, testAccounts.get(1).Id, testAccounts.get(2).Id}))
            .setField(Opportunity.MasterOpportunity__c, testMasterOpportunity.Id)
            .setField(Opportunity.IsMultiProductTechnicalOpportunity__c, true)
            .setField(Opportunity.Calculated_12M_Total_Pipeline__c, ValueProviderBuilder.provideList(new List<Integer>{240, 360, 372}))
            .setField(Opportunity.Estimated_One_Time_Pipeline__c, ValueProviderBuilder.provideList(new List<Integer>{15, 9, 6}))
            .quantity(3)
            .create()
            .getRecords();

        BillingWrappers.QuotePackageInfo pInfoOffice = new BillingWrappers.QuotePackageInfo();
        pInfoOffice.productName = QuoteHelper.NGBS_OFFICE_PRODUCT;

        BillingWrappers.QuotePackageInfo pInfoCC = new BillingWrappers.QuotePackageInfo();
        pInfoCC.productName = QuoteHelper.NGBS_RCCC_PRODUCT;

        BillingWrappers.QuotePackageInfo pInfoEV = new BillingWrappers.QuotePackageInfo();
        pInfoEV.productName = QuoteHelper.NGBS_ENGAGE_VOICE_PRODUCT;

        BillingWrappers.QuotePackageInfo pInfoED = new BillingWrappers.QuotePackageInfo();
        pInfoED.productName = QuoteHelper.NGBS_ENGAGE_DIGITAL_PRODUCT;

        Quote testMasterQuote = (Quote) new SObjectBuilder(Quote.sObjectType)
            .setField(Quote.IsPrimary__c, true)
            .setField(Quote.OpportunityId, testMasterOpportunity.Id)
            .setField(Quote.Payment_Period__c, QuoteHelper.ANNUAL_PAYMENT_METHOD)
            .setField(Quote.Package_Info__c, JSON.serialize(new List<BillingWrappers.QuotePackageInfo>{pInfoOffice}))
            .setField(Quote.RecordTypeId, QuoteHelper.RT_ID_BILLING)
            .create()
            .getRecord();

        List<Quote> testQuotes = (List<Quote>) new SObjectBuilder(Quote.sObjectType)
            .setField(Quote.IsPrimary__c, false)
            .setField(Quote.OpportunityId, ValueProviderBuilder.provideList(new List<Id>{testMasterOpportunity.Id, testOpportunities.get(0).Id, testOpportunities.get(1).Id, testOpportunities.get(2).Id }))
            .setField(Quote.MasterQuote__c, testMasterQuote.Id)
            .setField(Quote.Package_Info__c, ValueProviderBuilder.provideList(new List<String>{
                JSON.serialize(new List<BillingWrappers.QuotePackageInfo>{pInfoOffice}),
                JSON.serialize(new List<BillingWrappers.QuotePackageInfo>{pInfoCC}),
                JSON.serialize(new List<BillingWrappers.QuotePackageInfo>{pInfoEV}),
                JSON.serialize(new List<BillingWrappers.QuotePackageInfo>{pInfoED})
                })
            )
            .quantity(4)
            .create()
            .getRecords();

        testMasterOpportunity.PrimaryQuote__c = testMasterQuote.Id;

        update testMasterOpportunity;

        Id approvalRectypeID = Schema.SObjectType.Approval__c.getRecordTypeInfosByName().get(ApprovalHelper.INVOICING_REQUEST_APPROVAL_RT_NAME).getRecordTypeId();

        Triggers.switchOn();

        Test.startTest();

        //Invoice request approval from opportunity
        Approval_StandardApprovalCreate.responseWrapper res = Approval_StandardApprovalCreate.fetchFieldValues(null, approvalRectypeID, testMasterOpportunity.Id);

        System.assertEquals('456.0', res.signUpPurchaseLimitOffice, 'signUpPurchaseLimitOffice is not calculated correctly');
        System.assertEquals('456.0', res.signUpPurchaseLimitContactCenter, 'signUpPurchaseLimitContactCenter is not calculated correctly');
        System.assertEquals('38.0', res.monthlycredLimitOffice, 'monthlycredLimitOffice is not calculated correctly');
        System.assertEquals('38.0', res.monthlycredLimitEngageVoice, 'monthlycredLimitEngageVoice is not calculated correctly');


        //Invoice request approval from account
        Approval_StandardApprovalCreate.responseWrapper res2 = Approval_StandardApprovalCreate.fetchFieldValues(testMasterAccount.Id, approvalRectypeID, null);

        System.assertEquals('456.0', res2.signUpPurchaseLimitOffice, 'signUpPurchaseLimitOffice is not calculated correctly');
        System.assertEquals('456.0', res2.signUpPurchaseLimitContactCenter, 'signUpPurchaseLimitContactCenter is not calculated correctly');
        System.assertEquals('38.0', res2.monthlycredLimitOffice, 'monthlycredLimitOffice is not calculated correctly');
        System.assertEquals('38.0', res2.monthlycredLimitEngageVoice, 'monthlycredLimitEngageVoice is not calculated correctly');


        Test.stopTest();
    }

    @IsTest
    private static void testPrepopulateMonthlySingleProductLimitsForNB () {
        Triggers.switchOff();

        Account testAccount = (Account) new SObjectBuilder(Account.sObjectType)
            .setField(Account.IsMultiProductTechnicalAccount__c, false)
            .create()
            .getRecord();

        Opportunity testOpportunity = (Opportunity) new SObjectBuilder(Opportunity.sObjectType)
            .setField(Opportunity.AccountId, testAccount.Id)
            .setField(Opportunity.CloseDate, system.today().addMonths(1))
            .setField(Opportunity.IsMultiProductTechnicalOpportunity__c, false)
            .setField(Opportunity.Calculated_12M_Total_Pipeline__c, 1200)
            .setField(Opportunity.Estimated_Hardware__c, 30)
            .setField(Opportunity.Estimated_One_Time_Pipeline__c, 100)
            .setField(Opportunity.EstimatedProfessionalServices12Month__c, 200)
            .create()
            .getRecord();

        BillingWrappers.QuotePackageInfo pInfoOffice = new BillingWrappers.QuotePackageInfo();
        pInfoOffice.productName = QuoteHelper.NGBS_OFFICE_PRODUCT;

        Quote testQuote = (Quote) new SObjectBuilder(Quote.sObjectType)
            .setField(Quote.IsPrimary__c, true)
            .setField(Quote.OpportunityId, testOpportunity.Id)
            .setField(Quote.Payment_Period__c, QuoteHelper.MONTHLY_PAYMENT_METHOD)
            .setField(Quote.Package_Info__c, JSON.serialize(new List<BillingWrappers.QuotePackageInfo>{pInfoOffice}))
            .create()
            .getRecord();

        testOpportunity.PrimaryQuote__c = testQuote.Id;

        update testOpportunity;

        Id approvalRectypeID = Schema.SObjectType.Approval__c.getRecordTypeInfosByName().get(ApprovalHelper.INVOICING_REQUEST_APPROVAL_RT_NAME).getRecordTypeId();

        Triggers.switchOn();

        Test.startTest();

        //Invoice request approval from opportunity
        Approval_StandardApprovalCreate.responseWrapper res = Approval_StandardApprovalCreate.fetchFieldValues(null, approvalRectypeID, testOpportunity.Id);

        System.assertEquals('860.0', res.signUpPurchaseLimit, 'signUpPurchaseLimit is not calculated correctly');
        System.assertEquals('200.0', res.monthlycredLimit, 'monthlycredLimit is not calculated correctly');

        //Invoice request approval from account
        Approval_StandardApprovalCreate.responseWrapper res2 = Approval_StandardApprovalCreate.fetchFieldValues(testAccount.Id, approvalRectypeID, null);

        System.assertEquals('860.0', res2.signUpPurchaseLimit, 'signUpPurchaseLimit is not calculated correctly');
        System.assertEquals('200.0', res2.monthlycredLimit, 'monthlycredLimit is not calculated correctly');

        Test.stopTest();
    }

    @IsTest
    private static void testPrepopulateAnnualSingleProductLimitsForNB () {
        Triggers.switchOff();

        Account testAccount = (Account) new SObjectBuilder(Account.sObjectType)
            .setField(Account.IsMultiProductTechnicalAccount__c, false)
            .create()
            .getRecord();

        Opportunity testOpportunity = (Opportunity) new SObjectBuilder(Opportunity.sObjectType)
            .setField(Opportunity.AccountId, testAccount.Id)
            .setField(Opportunity.CloseDate, system.today().addMonths(1))
            .setField(Opportunity.IsMultiProductTechnicalOpportunity__c, false)
            .setField(Opportunity.Calculated_12M_Total_Pipeline__c, 1200)
            .setField(Opportunity.Estimated_Hardware__c, 30)
            .setField(Opportunity.Estimated_One_Time_Pipeline__c, 100)
            .setField(Opportunity.EstimatedProfessionalServices12Month__c, 200)
            .create()
            .getRecord();

        BillingWrappers.QuotePackageInfo pInfoOffice = new BillingWrappers.QuotePackageInfo();
        pInfoOffice.productName = QuoteHelper.NGBS_OFFICE_PRODUCT;

        Quote testQuote = (Quote) new SObjectBuilder(Quote.sObjectType)
            .setField(Quote.IsPrimary__c, true)
            .setField(Quote.OpportunityId, testOpportunity.Id)
            .setField(Quote.Payment_Period__c, QuoteHelper.ANNUAL_PAYMENT_METHOD)
            .setField(Quote.Package_Info__c, JSON.serialize(new List<BillingWrappers.QuotePackageInfo>{pInfoOffice}))
            .create()
            .getRecord();

        testOpportunity.PrimaryQuote__c = testQuote.Id;

        update testOpportunity;

        Id approvalRectypeID = Schema.SObjectType.Approval__c.getRecordTypeInfosByName().get(ApprovalHelper.INVOICING_REQUEST_APPROVAL_RT_NAME).getRecordTypeId();

        Triggers.switchOn();

        Test.startTest();

        //Invoice request approval from opportunity
        Approval_StandardApprovalCreate.responseWrapper res = Approval_StandardApprovalCreate.fetchFieldValues(null, approvalRectypeID, testOpportunity.Id);

        System.assertEquals('3060.0', res.signUpPurchaseLimit, 'signUpPurchaseLimit is not calculated correctly');
        System.assertEquals('200.0', res.monthlycredLimit, 'monthlycredLimit is not calculated correctly');

        //Invoice request approval from account
        Approval_StandardApprovalCreate.responseWrapper res2 = Approval_StandardApprovalCreate.fetchFieldValues(testAccount.Id, approvalRectypeID, null);

        System.assertEquals('3060.0', res2.signUpPurchaseLimit, 'signUpPurchaseLimit is not calculated correctly');
        System.assertEquals('200.0', res2.monthlycredLimit, 'monthlycredLimit is not calculated correctly');

        Test.stopTest();
    }

    @IsTest
    private static void testPrepopulateMonthlyMultiProductLimitsForEB () {
        Triggers.switchOff();

        Account testMasterAccount = (Account) new SObjectBuilder(Account.sObjectType)
            .setField(Account.IsMultiProductTechnicalAccount__c, false)
            .setField(Account.RC_User_ID__c, ValueProviderBuilder.provideUniqueString())
            .setField(Account.RC_Account_Status__c, AccountHelper.PAID_STATUS)
            .setField(Account.Account_Payment_Method__c, AccountHelper.PAYMENT_METHOD_CREDIT_CARD)
            .setField(Account.MRR__c, 19.0)
            .create()
            .getRecord();

        List<Account> testAccounts = (List<Account>) new SObjectBuilder(Account.SObjectType)
            .setField(Account.IsMultiProductTechnicalAccount__c, true)
            .setField(Account.Master_Account__c, testMasterAccount.Id)
            .setField(Account.Service_Type__c, ValueProviderBuilder.provideList(new List<String>{
                'RingCentral Contact Center',
                'Engage Voice Standalone',
                'Engage Digital Standalone'
            }))
            .setField(Account.RC_User_ID__c, ValueProviderBuilder.provideList(new List<String>{
                '654343858',
                '546434575',
                '658564564'
            }))
            .setField(Account.RC_Account_Status__c, AccountHelper.PAID_STATUS)
            .setField(Account.Account_Payment_Method__c, AccountHelper.PAYMENT_METHOD_CREDIT_CARD)
            .quantity(3)
            .create()
            .getRecords();

        Opportunity testMasterOpportunity = (Opportunity) new SObjectBuilder(Opportunity.sObjectType)
            .setField(Opportunity.AccountId, testMasterAccount.Id)
            .setField(Opportunity.CloseDate, system.today().addMonths(1))
            .setField(Opportunity.IsMultiProductTechnicalOpportunity__c, false)
            .setField(Opportunity.Estimated_12M_Office_Pipeline__c, 120)
            .setField(Opportunity.Estimated_Hardware__c, 30)
            .setField(Opportunity.Estimated_One_Time_Pipeline__c, 100)
            .setField(Opportunity.EstimatedProfessionalServices12Month__c, 200)
            .create()
            .getRecord();

        List<Opportunity> testOpportunities = (List<Opportunity>) new SObjectBuilder(Opportunity.sObjectType)
            .setField(Opportunity.AccountId, ValueProviderBuilder.provideList(new List<Id>{testAccounts.get(0).Id, testAccounts.get(1).Id, testAccounts.get(2).Id}))
            .setField(Opportunity.MasterOpportunity__c, testMasterOpportunity.Id)
            .setField(Opportunity.IsMultiProductTechnicalOpportunity__c, true)
            .setField(Opportunity.Calculated_12M_Total_Pipeline__c, ValueProviderBuilder.provideList(new List<Integer>{240, 360, 372}))
            .setField(Opportunity.Estimated_One_Time_Pipeline__c, ValueProviderBuilder.provideList(new List<Integer>{15, 9, 6}))
            .quantity(3)
            .create()
            .getRecords();

        BillingWrappers.QuotePackageInfo pInfoOffice = new BillingWrappers.QuotePackageInfo();
        pInfoOffice.productName = QuoteHelper.NGBS_OFFICE_PRODUCT;

        BillingWrappers.QuotePackageInfo pInfoCC = new BillingWrappers.QuotePackageInfo();
        pInfoCC.productName = QuoteHelper.NGBS_RCCC_PRODUCT;

        BillingWrappers.QuotePackageInfo pInfoEV = new BillingWrappers.QuotePackageInfo();
        pInfoEV.productName = QuoteHelper.NGBS_ENGAGE_VOICE_PRODUCT;

        BillingWrappers.QuotePackageInfo pInfoED = new BillingWrappers.QuotePackageInfo();
        pInfoED.productName = QuoteHelper.NGBS_ENGAGE_DIGITAL_PRODUCT;

        Quote testMasterQuote = (Quote) new SObjectBuilder(Quote.sObjectType)
            .setField(Quote.IsPrimary__c, true)
            .setField(Quote.OpportunityId, testMasterOpportunity.Id)
            .setField(Quote.Payment_Period__c, QuoteHelper.MONTHLY_PAYMENT_METHOD)
            .setField(Quote.Package_Info__c, JSON.serialize(new List<BillingWrappers.QuotePackageInfo>{pInfoOffice}))
            .create()
            .getRecord();

        List<Quote> testQuotes = (List<Quote>) new SObjectBuilder(Quote.sObjectType)
            .setField(Quote.IsPrimary__c, false)
            .setField(Quote.OpportunityId, ValueProviderBuilder.provideList(new List<Id>{testMasterOpportunity.Id, testOpportunities.get(0).Id, testOpportunities.get(1).Id, testOpportunities.get(2).Id }))
            .setField(Quote.MasterQuote__c, testMasterQuote.Id)
            .setField(Quote.Package_Info__c, ValueProviderBuilder.provideList(new List<String>{
                JSON.serialize(new List<BillingWrappers.QuotePackageInfo>{pInfoOffice}),
                JSON.serialize(new List<BillingWrappers.QuotePackageInfo>{pInfoCC}),
                JSON.serialize(new List<BillingWrappers.QuotePackageInfo>{pInfoEV}),
                JSON.serialize(new List<BillingWrappers.QuotePackageInfo>{pInfoED})
                })
            )
            .quantity(4)
            .create()
            .getRecords();

        testMasterOpportunity.PrimaryQuote__c = testMasterQuote.Id;

        update testMasterOpportunity;

        Id approvalRectypeID = Schema.SObjectType.Approval__c.getRecordTypeInfosByName().get(ApprovalHelper.INVOICING_REQUEST_APPROVAL_RT_NAME).getRecordTypeId();

        Triggers.switchOn();

        Test.startTest();

        //Invoice request approval from opportunity
        Approval_StandardApprovalCreate.responseWrapper res = Approval_StandardApprovalCreate.fetchFieldValues(null, approvalRectypeID, testMasterOpportunity.Id);

        System.assertEquals('38.0', res.signUpPurchaseLimitOffice, 'signUpPurchaseLimitOffice is not calculated correctly');
        System.assertEquals('38.0', res.signUpPurchaseLimitContactCenter, 'signUpPurchaseLimitContactCenter is not calculated correctly');
        System.assertEquals('38.0', res.monthlycredLimitOffice, 'monthlycredLimitOffice is not calculated correctly');
        System.assertEquals('38.0', res.monthlycredLimitEngageVoice, 'monthlycredLimitEngageVoice is not calculated correctly');


        //Invoice request approval from account
        Approval_StandardApprovalCreate.responseWrapper res2 = Approval_StandardApprovalCreate.fetchFieldValues(testMasterAccount.Id, approvalRectypeID, null);

        System.assertEquals('38.0', res2.signUpPurchaseLimitOffice, 'signUpPurchaseLimitOffice is not calculated correctly');
        System.assertEquals('38.0', res2.signUpPurchaseLimitContactCenter, 'signUpPurchaseLimitContactCenter is not calculated correctly');
        System.assertEquals('38.0', res2.monthlycredLimitOffice, 'monthlycredLimitOffice is not calculated correctly');
        System.assertEquals('38.0', res2.monthlycredLimitEngageVoice, 'monthlycredLimitEngageVoice is not calculated correctly');


        Test.stopTest();
    }

    @IsTest
    private static void testPrepopulateMultiProductLimitsFromApprovedApprovalForNB () {

        new SObjectBuilder(Feature_Toggle__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Feature_Toggle__c.EnableMultiProductUnifiedBilling__c => true
            })
            .create();

        Triggers.switchOff();

        Account testMasterAccount = (Account) new SObjectBuilder(Account.sObjectType)
            .setField(Account.IsMultiProductTechnicalAccount__c, false)
            .create()
            .getRecord();

        Opportunity testMasterOpportunity = (Opportunity) new SObjectBuilder(Opportunity.sObjectType)
            .setField(Opportunity.AccountId, testMasterAccount.Id)
            .setField(Opportunity.CloseDate, system.today().addMonths(1))
            .setField(Opportunity.IsMultiProductTechnicalOpportunity__c, false)
            .setField(Opportunity.Type, OpportunityHelper.OPPORTUNITY_TYPE_NEW_BUSINESS)
            .create()
            .getRecord();

        List<String> serviceNames = new List<String> {
            QuoteHelper.NGBS_OFFICE_PRODUCT,
            QuoteHelper.NGBS_RCCC_PRODUCT,
            QuoteHelper.NGBS_ENGAGE_VOICE_PRODUCT,
            QuoteHelper.NGBS_ENGAGE_DIGITAL_PRODUCT,
            QuoteHelper.NGBS_PROFESSIONAL_SERVICES_PRODUCT
        };

        BillingWrappers.QuotePackageInfo pInfoOffice = new BillingWrappers.QuotePackageInfo();
        pInfoOffice.productName = QuoteHelper.NGBS_OFFICE_PRODUCT;

        BillingWrappers.QuotePackageInfo pInfoCC = new BillingWrappers.QuotePackageInfo();
        pInfoCC.productName = QuoteHelper.NGBS_RCCC_PRODUCT;

        BillingWrappers.QuotePackageInfo pInfoEV = new BillingWrappers.QuotePackageInfo();
        pInfoEV.productName = QuoteHelper.NGBS_ENGAGE_VOICE_PRODUCT;

        BillingWrappers.QuotePackageInfo pInfoED = new BillingWrappers.QuotePackageInfo();
        pInfoED.productName = QuoteHelper.NGBS_ENGAGE_DIGITAL_PRODUCT;

        BillingWrappers.QuotePackageInfo pInfoProServ = new BillingWrappers.QuotePackageInfo();
        pInfoProServ.productName = QuoteHelper.NGBS_PROFESSIONAL_SERVICES_PRODUCT;

        Quote testMasterQuote = (Quote) new SObjectBuilder(Quote.sObjectType)
            .setField(Quote.IsPrimary__c, true)
            .setField(Quote.OpportunityId, testMasterOpportunity.Id)
            .setField(Quote.Payment_Period__c, QuoteHelper.MONTHLY_PAYMENT_METHOD)
            .setField(Quote.Package_Info__c, JSON.serialize(new List<BillingWrappers.QuotePackageInfo>{ pInfoOffice, pInfoCC, pInfoEV, pInfoED, pInfoProServ }))
            .create()
            .getRecord();

        List<Quote> testQuotes = (List<Quote>) new SObjectBuilder(Quote.sObjectType)
            .setField(Quote.IsPrimary__c, false)
            .setField(Quote.OpportunityId, testMasterOpportunity.Id)
            .setField(Quote.MasterQuote__c, testMasterQuote.Id)
            .setField(Quote.ServiceName__c, ValueProviderBuilder.provideList(serviceNames))
            .setField(Quote.Package_Info__c, ValueProviderBuilder.provideList(new List<String>{
                JSON.serialize(new List<BillingWrappers.QuotePackageInfo>{ pInfoOffice }),
                JSON.serialize(new List<BillingWrappers.QuotePackageInfo>{ pInfoCC }),
                JSON.serialize(new List<BillingWrappers.QuotePackageInfo>{ pInfoEV }),
                JSON.serialize(new List<BillingWrappers.QuotePackageInfo>{ pInfoED }),
                JSON.serialize(new List<BillingWrappers.QuotePackageInfo>{ pInfoProServ })
                })
            )
            .quantity(5)
            .create()
            .getRecords();

        Contact contact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setField(Contact.AccountId, testMasterAccount.Id)
            .create()
            .getRecord();

        AccountContactRole accRole = (AccountContactRole) new SObjectBuilder(AccountContactRole.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                AccountContactRole.AccountId => testMasterAccount.Id,
                AccountContactRole.ContactId => contact.Id,
                AccountContactRole.Role => AccountContactRoleHelper.CONTACT_ROLE_ACCOUNT_PAYABLE
            })
            .create()
            .getRecord();

        Approval__c lastApprovedApproval = (Approval__c) new SObjectBuilder(Approval__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Approval__c.Opportunity__c => testMasterOpportunity.Id,
                Approval__c.Account__c => testMasterAccount.Id,
                Approval__c.RecordTypeId => ApprovalHelper.RT_ID_INVOICING_REQUEST,
                Approval__c.AccountPayableContact__c => contact.Id,
                Approval__c.Sign_Up_Purchase_Limit_Office__c => 1000,
                Approval__c.Sign_Up_Purchase_Limit_Contact_Center__c => 2000,
                Approval__c.Monthly_Credit_Limit_Office__c => 500,
                Approval__c.Monthly_Credit_Limit_Contact_Center__c => 800,
                Approval__c.Potential_Users__c => 12,
                Approval__c.Reason_Customer_is_Requesting_Invoicing__c => 'Test',
                Approval__c.SignUpPurchaseLimitProServ__c => 1000,
                Approval__c.MonthlyCreditLimitProServ__c => 2000,
                Approval__c.Status__c => ApprovalHelper.STATUS_APPROVED
            })
            .create()
            .getRecord();

        Id approvalRectypeID = Schema.SObjectType.Approval__c.getRecordTypeInfosByName().get(ApprovalHelper.INVOICING_REQUEST_APPROVAL_RT_NAME).getRecordTypeId();

        Triggers.switchOn();

        Test.startTest();

        //Invoice request approval from opportunity
        Approval_StandardApprovalCreate.responseWrapper res = Approval_StandardApprovalCreate.fetchFieldValues(null, approvalRectypeID, testMasterOpportunity.Id);

        Assert.areEqual('1000.00', res.signUpPurchaseLimitOffice, 'signUpPurchaseLimitOffice is not calculated correctly');
        Assert.areEqual('2000.00', res.signUpPurchaseLimitContactCenter, 'signUpPurchaseLimitContactCenter is not calculated correctly');
        Assert.areEqual('500.00', res.monthlycredLimitOffice, 'monthlycredLimitOffice is not calculated correctly');
        Assert.areEqual('800.00', res.monthlycredLimitContactCenter, 'monthlycredLimitContactCenter is not calculated correctly');
        Assert.areEqual('1000.00', res.signUpPurchaseLimitProServ, 'signUpPurchaseLimitProServ is not calculated correctly');
        Assert.areEqual('2000.00', res.monthlycredLimitProServ, 'monthlycredLimitProServ is not calculated correctly');

        // Invoice request approval from account
        Approval_StandardApprovalCreate.responseWrapper res2 = Approval_StandardApprovalCreate.fetchFieldValues(testMasterAccount.Id, approvalRectypeID, null);

        Assert.areEqual('1000.00', res2.signUpPurchaseLimitOffice, 'signUpPurchaseLimitOffice is not calculated correctly');
        Assert.areEqual('2000.00', res2.signUpPurchaseLimitContactCenter, 'signUpPurchaseLimitContactCenter is not calculated correctly');
        Assert.areEqual('500.00', res2.monthlycredLimitOffice, 'monthlycredLimitOffice is not calculated correctly');
        Assert.areEqual('800.00', res2.monthlycredLimitContactCenter, 'monthlycredLimitContactCenter is not calculated correctly');
        Assert.areEqual('1000.00', res2.signUpPurchaseLimitProServ, 'signUpPurchaseLimitProServ is not calculated correctly');
        Assert.areEqual('2000.00', res2.monthlycredLimitProServ, 'monthlycredLimitProServ is not calculated correctly');

        Test.stopTest();
    }

    @IsTest
    private static void testPrepopulateSingleProductLimitsForNB() {
        new SObjectBuilder(Feature_Toggle__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Feature_Toggle__c.EnableMultiProductUnifiedBilling__c => true
            })
            .create();

        Triggers.switchOff();

        Account testAccount = (Account) new SObjectBuilder(Account.sObjectType)
            .setField(Account.IsMultiProductTechnicalAccount__c, false)
            .create()
            .getRecord();

        Opportunity testOpportunity = (Opportunity) new SObjectBuilder(Opportunity.sObjectType)
            .setField(Opportunity.AccountId, testAccount.Id)
            .setField(Opportunity.CloseDate, system.today().addMonths(1))
            .setField(Opportunity.Type, OpportunityHelper.OPPORTUNITY_TYPE_NEW_BUSINESS)
            .setField(Opportunity.IsMultiProductTechnicalOpportunity__c, false)
            .create()
            .getRecord();

        PriceBook2 testPriceBook = (PriceBook2) new SObjectBuilder(PriceBook2.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                PriceBook2.Name => ValueProviderBuilder.provideUniqueString('test pricebook'),
                PriceBook2.Description => ValueProviderBuilder.provideUniqueString('description'),
                PriceBook2.IsActive => true,
                PriceBook2.Line_Range_Min__c => 2,
                PriceBook2.Service__c => Pricebook2Helper.SERVICE_OFFICE,
                PriceBook2.Plan__c => Pricebook2Helper.PLAN_MONTHLY
            })
            .create()
            .getRecord();

        List<Product2> testProducts = (List<Product2>) new SObjectBuilder(Product2.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Product2.Name => 'Test_Product',
                Product2.IsActive => true,
                Product2.Sub_Category__c => Product2Helper.SUBCATEGORY_RINGCENTRAL,
                Product2.Family => Product2Helper.FAMILY_SERVICE,
                Product2.Feature__c => Product2Helper.FEATURE_SERVICE_PLAN,
                Product2.Billing_Type__c => Product2Helper.BILLING_TYPE_RECURRING,
                Product2.Charge_Term__c => Product2Helper.CHARGE_TERM_MONTHLY
            })
            .create()
            .getRecords();

        List<PricebookEntry> stdPBEList = new SobjectBuilder(PricebookEntry.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                PricebookEntry.Product2Id => testProducts.get(0).Id,
                PricebookEntry.UnitPrice => 200,
                PricebookEntry.IsActive => true,
                PricebookEntry.UseStandardPrice => false,
                PricebookEntry.CurrencyIsoCode => 'USD'
            })
            .create()
            .getRecords();

        List<PricebookEntry> pBEList = new SobjectBuilder(PricebookEntry.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                PricebookEntry.Pricebook2Id => testPriceBook.Id,
                PricebookEntry.Product2Id => testProducts.get(0).Id,
                PricebookEntry.UnitPrice => 200,
                PricebookEntry.IsActive => true,
                PricebookEntry.UseStandardPrice => false,
                PricebookEntry.CurrencyIsoCode => 'USD'
            })
            .create()
            .getRecords();

        BillingWrappers.QuotePackageInfo pInfoOffice = new BillingWrappers.QuotePackageInfo();
        pInfoOffice.productName = QuoteHelper.NGBS_OFFICE_PRODUCT;

        Quote testQuote = (Quote) new SObjectBuilder(Quote.sObjectType)
            .setField(Quote.IsPrimary__c, true)
            .setField(Quote.OpportunityId, testOpportunity.Id)
            .setField(Quote.Payment_Period__c, QuoteHelper.MONTHLY_PAYMENT_METHOD)
            .setField(Quote.Monthly_Recurring_Revenue__c, 1000)
            .setField(Quote.Pricebook2Id, testPriceBook.Id)
            .setField(Quote.Package_Info__c, JSON.serialize(new List<BillingWrappers.QuotePackageInfo>{pInfoOffice}))
            .create()
            .getRecord();

        List<QuoteLineItem> qlis = new SobjectBuilder(QuoteLineItem.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                QuoteLineItem.Product2Id => testProducts.get(0).Id,
                QuoteLineItem.PricebookEntryId => ValueProviderBuilder.provideParents(pBEList),
                QuoteLineItem.QuoteId => testQuote.Id,
                QuoteLineItem.Quantity => 7,
                QuoteLineItem.Discount_type__c => QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY,
                QuoteLineItem.Discount_Number__c => 10,
                QuoteLineItem.UnitPrice => 200,
                QuoteLineItem.NewQuantity__c => 7,
                QuoteLineItem.PackageInfo__c => '{"duration":"Monthly"}'
            })
            .create()
            .getRecords();


        Id approvalRectypeID = Schema.SObjectType.Approval__c.getRecordTypeInfosByName().get(ApprovalHelper.INVOICING_REQUEST_APPROVAL_RT_NAME).getRecordTypeId();

        Triggers.switchOn();

        Test.startTest();

        //Invoice request approval from opportunity
        Approval_StandardApprovalCreate.responseWrapper res = Approval_StandardApprovalCreate.fetchFieldValues(null, approvalRectypeID, testOpportunity.Id);

        System.assertEquals('2100.000', res.signUpPurchaseLimit, 'signUpPurchaseLimit is not calculated correctly');
        System.assertEquals('2100.000', res.monthlycredLimit, 'monthlycredLimit is not calculated correctly');

        Test.stopTest();
    }

    @IsTest
    private static void testPrepopulateMonthlySingleProductLimitsForEB () {
        Triggers.switchOff();

        Account testAccount = (Account) new SObjectBuilder(Account.sObjectType)
            .setField(Account.IsMultiProductTechnicalAccount__c, false)
            .setField(Account.RC_User_ID__c, ValueProviderBuilder.provideUniqueString())
            .setField(Account.RC_Account_Status__c, AccountHelper.PAID_STATUS)
            .setField(Account.Account_Payment_Method__c, AccountHelper.PAYMENT_METHOD_CREDIT_CARD)
            .setField(Account.MRR__c, 19.0)
            .create()
            .getRecord();

        Opportunity testOpportunity = (Opportunity) new SObjectBuilder(Opportunity.sObjectType)
            .setField(Opportunity.AccountId, testAccount.Id)
            .setField(Opportunity.CloseDate, system.today().addMonths(1))
            .setField(Opportunity.IsMultiProductTechnicalOpportunity__c, false)
            .create()
            .getRecord();

        BillingWrappers.QuotePackageInfo pInfoOffice = new BillingWrappers.QuotePackageInfo();
        pInfoOffice.productName = QuoteHelper.NGBS_OFFICE_PRODUCT;

        Quote testQuote = (Quote) new SObjectBuilder(Quote.sObjectType)
            .setField(Quote.IsPrimary__c, true)
            .setField(Quote.OpportunityId, testOpportunity.Id)
            .setField(Quote.Payment_Period__c, QuoteHelper.MONTHLY_PAYMENT_METHOD)
            .setField(Quote.Package_Info__c, JSON.serialize(new List<BillingWrappers.QuotePackageInfo>{pInfoOffice}))
            .create()
            .getRecord();

        testOpportunity.PrimaryQuote__c = testQuote.Id;

        update testOpportunity;

        Id approvalRectypeID = Schema.SObjectType.Approval__c.getRecordTypeInfosByName().get(ApprovalHelper.INVOICING_REQUEST_APPROVAL_RT_NAME).getRecordTypeId();

        Triggers.switchOn();

        Test.startTest();

        //Invoice request approval from opportunity
        Approval_StandardApprovalCreate.responseWrapper res = Approval_StandardApprovalCreate.fetchFieldValues(null, approvalRectypeID, testOpportunity.Id);

        System.assertEquals('38.0', res.signUpPurchaseLimit, 'signUpPurchaseLimit is not calculated correctly');
        System.assertEquals('38.0', res.monthlycredLimit, 'monthlycredLimit is not calculated correctly');

        //Invoice request approval from account
        Approval_StandardApprovalCreate.responseWrapper res2 = Approval_StandardApprovalCreate.fetchFieldValues(testAccount.Id, approvalRectypeID, null);

        System.assertEquals('38.0', res2.signUpPurchaseLimit, 'signUpPurchaseLimit is not calculated correctly');
        System.assertEquals('38.0', res2.monthlycredLimit, 'monthlycredLimit is not calculated correctly');

        Test.stopTest();
    }

    @IsTest
    private static void testPrepopulateSingleProductLimitsFromApprovedApprovalForEB () {

        new SObjectBuilder(Feature_Toggle__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Feature_Toggle__c.EnableMultiProductUnifiedBilling__c => true
            })
            .create();

        Triggers.switchOff();

        Account testAccount = (Account) new SObjectBuilder(Account.sObjectType)
            .setField(Account.IsMultiProductTechnicalAccount__c, false)
            .setField(Account.MRR__c, 19.0)
            .create()
            .getRecord();

        Opportunity testOpportunity = (Opportunity) new SObjectBuilder(Opportunity.sObjectType)
            .setField(Opportunity.AccountId, testAccount.Id)
            .setField(Opportunity.CloseDate, system.today().addMonths(1))
            .setField(Opportunity.IsMultiProductTechnicalOpportunity__c, false)
            .setField(Opportunity.Type, OpportunityHelper.OPPORTUNITY_TYPE_EX_BUSINESS)
            .create()
            .getRecord();

        BillingWrappers.QuotePackageInfo pInfoOffice = new BillingWrappers.QuotePackageInfo();
        pInfoOffice.productName = QuoteHelper.NGBS_OFFICE_PRODUCT;

        Quote testQuote = (Quote) new SObjectBuilder(Quote.sObjectType)
            .setField(Quote.IsPrimary__c, true)
            .setField(Quote.OpportunityId, testOpportunity.Id)
            .setField(Quote.Payment_Period__c, QuoteHelper.MONTHLY_PAYMENT_METHOD)
            .setField(Quote.Package_Info__c, JSON.serialize(new List<BillingWrappers.QuotePackageInfo>{pInfoOffice}))
            .create()
            .getRecord();

        Contact contact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setField(Contact.AccountId, testAccount.Id)
            .create()
            .getRecord();

        AccountContactRole accRole = (AccountContactRole) new SObjectBuilder(AccountContactRole.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                AccountContactRole.AccountId => testAccount.Id,
                AccountContactRole.ContactId => contact.Id,
                AccountContactRole.Role => AccountContactRoleHelper.CONTACT_ROLE_ACCOUNT_PAYABLE
            })
            .create()
            .getRecord();

        Approval__c lastApprovedApproval = (Approval__c) new SObjectBuilder(Approval__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Approval__c.Opportunity__c => testOpportunity.Id,
                Approval__c.Account__c => testAccount.Id,
                Approval__c.RecordTypeId => ApprovalHelper.RT_ID_INVOICING_REQUEST,
                Approval__c.AccountPayableContact__c => contact.Id,
                Approval__c.Monthly_Credit_Limit__c => 80,
                Approval__c.Sign_Up_Purchase_Limit__c => 180,
                Approval__c.Potential_Users__c => 12,
                Approval__c.Reason_Customer_is_Requesting_Invoicing__c => 'Test',
                Approval__c.Status__c => ApprovalHelper.STATUS_APPROVED
            })
            .create()
            .getRecord();

        Id approvalRectypeID = Schema.SObjectType.Approval__c.getRecordTypeInfosByName().get(ApprovalHelper.INVOICING_REQUEST_APPROVAL_RT_NAME).getRecordTypeId();

        Triggers.switchOn();

        Test.startTest();

        //Invoice request approval from opportunity
        Approval_StandardApprovalCreate.responseWrapper res = Approval_StandardApprovalCreate.fetchFieldValues(null, approvalRectypeID, testOpportunity.Id);

        System.assertEquals('180.00', res.signUpPurchaseLimit, 'signUpPurchaseLimit is not calculated correctly');
        System.assertEquals('80.00', res.monthlycredLimit, 'monthlycredLimit is not calculated correctly');

        //Invoice request approval from account
        Approval_StandardApprovalCreate.responseWrapper res2 = Approval_StandardApprovalCreate.fetchFieldValues(testAccount.Id, approvalRectypeID, null);

        System.assertEquals('180.00', res2.signUpPurchaseLimit, 'signUpPurchaseLimit is not calculated correctly');
        System.assertEquals('80.00', res2.monthlycredLimit, 'monthlycredLimit is not calculated correctly');

        Test.stopTest();
    }

    @IsTest
    private static void testPrepopulateAnnualSingleProductLimitsForEB () {
        Triggers.switchOff();

        Account testAccount = (Account) new SObjectBuilder(Account.sObjectType)
            .setField(Account.IsMultiProductTechnicalAccount__c, false)
            .setField(Account.RC_User_ID__c, ValueProviderBuilder.provideUniqueString())
            .setField(Account.RC_Account_Status__c, AccountHelper.PAID_STATUS)
            .setField(Account.Account_Payment_Method__c, AccountHelper.PAYMENT_METHOD_CREDIT_CARD)
            .setField(Account.MRR__c, 19.0)
            .create()
            .getRecord();

        Opportunity testOpportunity = (Opportunity) new SObjectBuilder(Opportunity.sObjectType)
            .setField(Opportunity.AccountId, testAccount.Id)
            .setField(Opportunity.CloseDate, system.today().addMonths(1))
            .setField(Opportunity.IsMultiProductTechnicalOpportunity__c, false)
            .create()
            .getRecord();

        BillingWrappers.QuotePackageInfo pInfoOffice = new BillingWrappers.QuotePackageInfo();
        pInfoOffice.productName = QuoteHelper.NGBS_OFFICE_PRODUCT;

        Quote testQuote = (Quote) new SObjectBuilder(Quote.sObjectType)
            .setField(Quote.IsPrimary__c, true)
            .setField(Quote.OpportunityId, testOpportunity.Id)
            .setField(Quote.Payment_Period__c, QuoteHelper.ANNUAL_PAYMENT_METHOD)
            .setField(Quote.Package_Info__c, JSON.serialize(new List<BillingWrappers.QuotePackageInfo>{pInfoOffice}))
            .create()
            .getRecord();

        testOpportunity.PrimaryQuote__c = testQuote.Id;

        update testOpportunity;

        Id approvalRectypeID = Schema.SObjectType.Approval__c.getRecordTypeInfosByName().get(ApprovalHelper.INVOICING_REQUEST_APPROVAL_RT_NAME).getRecordTypeId();

        Triggers.switchOn();

        Test.startTest();

        //Invoice request approval from opportunity
        Approval_StandardApprovalCreate.responseWrapper res = Approval_StandardApprovalCreate.fetchFieldValues(null, approvalRectypeID, testOpportunity.Id);

        System.assertEquals('456.0', res.signUpPurchaseLimit, 'signUpPurchaseLimit is not calculated correctly');
        System.assertEquals('38.0', res.monthlycredLimit, 'monthlycredLimit is not calculated correctly');

        //Invoice request approval from account
        Approval_StandardApprovalCreate.responseWrapper res2 = Approval_StandardApprovalCreate.fetchFieldValues(testAccount.Id, approvalRectypeID, null);

        System.assertEquals('456.0', res2.signUpPurchaseLimit, 'signUpPurchaseLimit is not calculated correctly');
        System.assertEquals('38.0', res2.monthlycredLimit, 'monthlycredLimit is not calculated correctly');

        Test.stopTest();
    }

    @IsTest
    private static void testIsApprovalCreateOnAccount() {
        String oppId = null;

        Account testAccount = (Account) new SObjectBuilder(Account.sObjectType)
            .setField(Account.IsMultiProductTechnicalAccount__c, false)
            .setField(Account.Payment_Method__c, AccountHelper.PAYMENT_METHOD_INVOICE)
            .setField(Account.Invoice_Terms__c, '1')
            .create()
            .getRecord();

        Opportunity testOpportunity = (Opportunity) new SObjectBuilder(Opportunity.sObjectType)
            .setField(Opportunity.AccountId, testAccount.Id)
            .setField(Opportunity.CloseDate, system.today().addMonths(1))
            .setField(Opportunity.IsMultiProductTechnicalOpportunity__c, false)
            .create()
            .getRecord();

        String accountId = testAccount.Id;
        Boolean isCreateAccount = Approval_StandardApprovalCreate.isApprovalCreateOnAccount(accountId, oppId);
        System.assert(isCreateAccount, 'Value must be equal to true');

        accountId = null;
        oppId = testOpportunity.Id;
        Boolean isCreateOpportunity = Approval_StandardApprovalCreate.isApprovalCreateOnAccount(accountId, oppId);
        System.assert(isCreateOpportunity == false, 'Value must be equal to false');
    }

    @IsTest
    private static void testPrepopulateInvoiceTermsForInvoiceApproval() {
        Triggers.switchOff();

        Account testAccount = (Account) new SObjectBuilder(Account.sObjectType)
            .setField(Account.IsMultiProductTechnicalAccount__c, false)
            .setField(Account.Payment_Method__c, AccountHelper.PAYMENT_METHOD_INVOICE)
            .setField(Account.Invoice_Terms__c, '1')
            .create()
            .getRecord();

        Opportunity testOpportunity = (Opportunity) new SObjectBuilder(Opportunity.sObjectType)
            .setField(Opportunity.AccountId, testAccount.Id)
            .setField(Opportunity.CloseDate, system.today().addMonths(1))
            .setField(Opportunity.IsMultiProductTechnicalOpportunity__c, false)
            .create()
            .getRecord();

        Id approvalRectypeID = Schema.SObjectType.Approval__c.getRecordTypeInfosByName().get(ApprovalHelper.INVOICING_REQUEST_APPROVAL_RT_NAME).getRecordTypeId();

        Triggers.switchOn();

        Test.startTest();

        Approval_StandardApprovalCreate.responseWrapper res = Approval_StandardApprovalCreate.fetchFieldValues(null, approvalRectypeID, testOpportunity.Id);

        System.assertEquals(true, res.invoiceTerms_access, 'invoiceTerms_access did not set correctly');
        System.assertEquals('1', res.invoiceTerms, 'invoiceTerms did not fetch');

        Test.stopTest();
    }

    @IsTest
    private static void testPrepopulateApprovalNameForInvoiceApprovalFromOpportunity() {
        Triggers.switchOff();

        Account testAccount = (Account) new SObjectBuilder(Account.sObjectType)
            .setField(Account.IsMultiProductTechnicalAccount__c, false)
            .setField(Account.Payment_Method__c, AccountHelper.PAYMENT_METHOD_INVOICE)
            .setField(Account.Name, 'Test Account')
            .create()
            .getRecord();

        Opportunity testOpportunity = (Opportunity) new SObjectBuilder(Opportunity.sObjectType)
            .setField(Opportunity.AccountId, testAccount.Id)
            .setField(Opportunity.CloseDate, system.today().addMonths(1))
            .setField(Opportunity.IsMultiProductTechnicalOpportunity__c, false)
            .create()
            .getRecord();

        Id approvalRectypeID = Schema.SObjectType.Approval__c.getRecordTypeInfosByName().get(ApprovalHelper.INVOICING_REQUEST_APPROVAL_RT_NAME).getRecordTypeId();

        Triggers.switchOn();

        Test.startTest();

        Approval_StandardApprovalCreate.responseWrapper res = Approval_StandardApprovalCreate.fetchFieldValues(null, approvalRectypeID, testOpportunity.Id);

        System.assertEquals('Invoicing Request "Test Account" 1', res.approvalName, 'Invoicing Request Approval Name was not set correctly');

        Test.stopTest();
    }

    @isTest
    private static void testGetNumberOfPOCUsers() {
        Triggers.switchOff();
        Account testAccount = (Account) new SObjectBuilder(Account.sObjectType)
            .setField(Account.IsMultiProductTechnicalAccount__c, false)
            .setField(Account.RC_User_ID__c, ValueProviderBuilder.provideUniqueString())
            .create()
            .getRecord();

        Approval__c approval = (Approval__c) new SObjectBuilder(Approval__c.sObjectType)
            .setField(Approval__c.Account__c, testAccount.Id)
            .setField(Approval__c.RecordTypeId, ApprovalHelper.RT_ID_POC_ACCOUNT)
            .setField(Approval__c.Number_of_POC_Users__c, 5)
            .setField(Approval__c.Status__c, ApprovalHelper.STATUS_APPROVED)
            .create()
            .getRecord();
        Triggers.switchOn();

        Test.startTest();
            Decimal numberOfPOCUsers = Approval_StandardApprovalCreate.getNumberOfPOCUsers(testAccount.Id);
        Test.stopTest();

        Assert.areEqual(approval.Number_of_POC_Users__c, numberOfPOCUsers, 'Number of POC Users is not correct');
    }

    @IsTest
    private static void testPrepopulateApprovalNameForInvoiceApprovalFromAccount() {
        Triggers.switchOff();

        Account testAccount = (Account) new SObjectBuilder(Account.sObjectType)
            .setField(Account.IsMultiProductTechnicalAccount__c, false)
            .setField(Account.Payment_Method__c, AccountHelper.PAYMENT_METHOD_INVOICE)
            .setField(Account.Name, 'Test Account')
            .create()
            .getRecord();

        Id approvalRectypeID = Schema.SObjectType.Approval__c.getRecordTypeInfosByName().get(ApprovalHelper.INVOICING_REQUEST_APPROVAL_RT_NAME).getRecordTypeId();

        Triggers.switchOn();

        Test.startTest();

        Approval_StandardApprovalCreate.responseWrapper res = Approval_StandardApprovalCreate.fetchFieldValues(testAccount.Id, approvalRectypeID, null);

        System.assertEquals('Invoicing Request "Test Account" 1', res.approvalName, 'Invoicing Request Approval Name was not set correctly');

        Test.stopTest();
    }

    @IsTest
    private static void testPrepopulateApprovalNameForBillingDateChangeRequestFromOpportunity() {
        Triggers.switchOff();

        Account testAccount = (Account) new SObjectBuilder(Account.sObjectType)
            .setField(Account.IsMultiProductTechnicalAccount__c, false)
            .setField(Account.Payment_Method__c, AccountHelper.PAYMENT_METHOD_INVOICE)
            .setField(Account.Invoice_Terms__c, '1')
            .setField(Account.Name, 'Test Account')
            .create()
            .getRecord();

        Opportunity testOpportunity = (Opportunity) new SObjectBuilder(Opportunity.sObjectType)
            .setField(Opportunity.AccountId, testAccount.Id)
            .setField(Opportunity.CloseDate, system.today().addMonths(1))
            .setField(Opportunity.IsMultiProductTechnicalOpportunity__c, false)
            .create()
            .getRecord();

        Id approvalRectypeID = Schema.SObjectType.Approval__c.getRecordTypeInfosByName().get(ApprovalHelper.RT_NAME_BILLING_DATE_CHANGE_REQUEST_APPROVAL).getRecordTypeId();

        Triggers.switchOn();

        Test.startTest();

        Approval_StandardApprovalCreate.responseWrapper res = Approval_StandardApprovalCreate.fetchFieldValues(null, approvalRectypeID, testOpportunity.Id);

        System.assertEquals('Change Billing Date "Test Account" 1', res.approvalName, 'Change Billing Date Approval Name was not set correctly');

        Test.stopTest();
    }

    @IsTest
    private static void testPrepopulateApprovalNameForBillingDateChangeRequestFromAccount() {
        Triggers.switchOff();

        Account testAccount = (Account) new SObjectBuilder(Account.sObjectType)
            .setField(Account.IsMultiProductTechnicalAccount__c, false)
            .setField(Account.Payment_Method__c, AccountHelper.PAYMENT_METHOD_INVOICE)
            .setField(Account.Invoice_Terms__c, '1')
            .setField(Account.Name, 'Test Account')
            .create()
            .getRecord();

        Id approvalRectypeID = Schema.SObjectType.Approval__c.getRecordTypeInfosByName().get(ApprovalHelper.RT_NAME_BILLING_DATE_CHANGE_REQUEST_APPROVAL).getRecordTypeId();

        Triggers.switchOn();

        Test.startTest();

        Approval_StandardApprovalCreate.responseWrapper res = Approval_StandardApprovalCreate.fetchFieldValues(testAccount.Id, approvalRectypeID, null);

        System.assertEquals('Change Billing Date "Test Account" 1', res.approvalName, 'Change Billing Date Approval Name was not set correctly');

        Test.stopTest();
    }


    @IsTest
    private static void testGetQuotesByServicesUB() {
        Triggers.switchOff();

        Account testAccount = (Account) new SObjectBuilder(Account.sObjectType)
            .setField(Account.IsMultiProductTechnicalAccount__c, false)
            .setField(Account.Payment_Method__c, AccountHelper.PAYMENT_METHOD_INVOICE)
            .setField(Account.Invoice_Terms__c, '1')
            .setField(Account.Name, 'Test Account')
            .create()
            .getRecord();

        Opportunity testOpportunity = (Opportunity) new SObjectBuilder(Opportunity.sObjectType)
            .setField(Opportunity.AccountId, testAccount.Id)
            .setField(Opportunity.CloseDate, system.today().addMonths(1))
            .setField(Opportunity.IsMultiProductTechnicalOpportunity__c, false)
            .create()
            .getRecord();

        BillingWrappers.QuotePackageInfo pInfoOffice = new BillingWrappers.QuotePackageInfo();
        pInfoOffice.productName = QuoteHelper.NGBS_OFFICE_PRODUCT;

        BillingWrappers.QuotePackageInfo pInfoCC = new BillingWrappers.QuotePackageInfo();
        pInfoCC.productName = QuoteHelper.NGBS_RCCC_PRODUCT;

        BillingWrappers.QuotePackageInfo pInfoEV = new BillingWrappers.QuotePackageInfo();
        pInfoEV.productName = QuoteHelper.NGBS_ENGAGE_VOICE_PRODUCT;

        BillingWrappers.QuotePackageInfo pInfoED = new BillingWrappers.QuotePackageInfo();
        pInfoED.productName = QuoteHelper.NGBS_ENGAGE_DIGITAL_PRODUCT;

        BillingWrappers.QuotePackageInfo pInfoProServ = new BillingWrappers.QuotePackageInfo();
        pInfoProServ.productName = QuoteHelper.NGBS_PROFESSIONAL_SERVICES_PRODUCT;

        Quote testMasterQuote = (Quote) new SObjectBuilder(Quote.sObjectType)
            .setField(Quote.OpportunityId, testOpportunity.Id)
            .setField(Quote.IsPrimary__c, true)
            .setField(Quote.IsMultiProductTechnicalQuote__c, false)
            .setField(Quote.Package_Info__c, JSON.serialize(new List<BillingWrappers.QuotePackageInfo>{pInfoOffice, pInfoCC, pInfoEV, pInfoED, pInfoProServ}))
            .create()
            .getRecord();

        List<Quote> testQuotes = (List<Quote>) new SObjectBuilder(Quote.sObjectType)
            .setField(Quote.IsPrimary__c, false)
            .setField(Quote.OpportunityId, testOpportunity.Id)
            .setField(Quote.IsMultiProductTechnicalQuote__c, true)
            .setField(Quote.MasterQuote__c, testMasterQuote.Id)
            .setField(Quote.ServiceName__c, ValueProviderBuilder.provideList(new List<String>{
                QuoteHelper.NGBS_OFFICE_PRODUCT,
                QuoteHelper.NGBS_RCCC_PRODUCT,
                QuoteHelper.NGBS_ENGAGE_VOICE_PRODUCT,
                QuoteHelper.NGBS_ENGAGE_DIGITAL_PRODUCT,
                QuoteHelper.NGBS_PROFESSIONAL_SERVICES_PRODUCT
            }))
            .quantity(5)
            .create()
            .getRecords();

        Triggers.switchOn();

        Test.startTest();

        Map<String, Quote> quotesByServices = Approval_StandardApprovalCreate.getQuotesByServicesUB(testMasterQuote);

        Assert.areEqual(5, quotesByServices.size(), 'Quotes by services map size is not correct');

        Test.stopTest();
    }

    @IsTest
    private static void testGetQuotesByServicesUBEmptyPackageInfo() {
        Triggers.switchOff();

        Account testAccount = (Account) new SObjectBuilder(Account.sObjectType)
            .setField(Account.IsMultiProductTechnicalAccount__c, false)
            .setField(Account.Payment_Method__c, AccountHelper.PAYMENT_METHOD_INVOICE)
            .setField(Account.Invoice_Terms__c, '1')
            .setField(Account.Name, 'Test Account')
            .create()
            .getRecord();

        Opportunity testOpportunity = (Opportunity) new SObjectBuilder(Opportunity.sObjectType)
            .setField(Opportunity.AccountId, testAccount.Id)
            .setField(Opportunity.CloseDate, system.today().addMonths(1))
            .setField(Opportunity.IsMultiProductTechnicalOpportunity__c, false)
            .create()
            .getRecord();

        Quote testMasterQuote = (Quote) new SObjectBuilder(Quote.sObjectType)
            .setField(Quote.OpportunityId, testOpportunity.Id)
            .setField(Quote.IsPrimary__c, true)
            .setField(Quote.IsMultiProductTechnicalQuote__c, false)
            .setField(Quote.Package_Info__c, '')
            .create()
            .getRecord();

        Triggers.switchOn();

        Test.startTest();

        Map<String, Quote> quotesByServices = Approval_StandardApprovalCreate.getQuotesByServicesUB(testMasterQuote);

        Assert.isTrue(quotesByServices.isEmpty(), 'Quotes by services map size is not correct');

        Test.stopTest();
    }
}