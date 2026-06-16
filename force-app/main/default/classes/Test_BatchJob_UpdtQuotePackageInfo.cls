@isTest
private class Test_BatchJob_UpdtQuotePackageInfo {
    private static String billingIdentitiesResponse =
        '[' +
            '{"id":1,"name":"RingCentral, Ltd (France)",' +
            '"address":{"label":null,"firstName":"RingCentral France","lastName":"",' +
            '"phone":"","street1":"3-5 rue Saint Georges","street2":"",' +
            '"city":"Paris","county":"","state":"","zip":"75009","country":"FRA"},' +
            '"isDefault":true}, ' +
            '{"id": 33,"name": "RingCentral, Ltd (Germany)",' +
            '"address": {"label": null,"firstName": "RingCentral Germany","lastName": "",' +
            '"phone": "","street1": "3-5 rue Saint Georges","street2": "",' +
            '"city": "Berlin","county": "","state": "","zip": "75009","country": "DEU"},' +
            '"isDefault": false}' +
        ']';
    private static String accountInfo = '{"id":123,"businessIdentityId":1,"firstName":"Something","lastName":"New","companyName":"RingCentral Inc."}';
    private static String accountBi = '{"id": 1,"name": "RingCentral, Ltd (France)",' +
        '"address": {"label": null,"firstName": "RingCentral France","lastName": "",' +
        '"phone": "","street1": "3-5 rue Saint Georges","street2": "",' +
        '"city": "Paris","county": "","state": "","zip": "75009","country": "FRA"},' +
        '"isDefault": true}';

    @TestSetup
    static void createData() {
        new SObjectBuilder(NGBS_Settings__c.SObjectType)
            .setField(NGBS_Settings__c.BaseEndpoint__c, 'http://185.23.251.118:8080')
            .setField(NGBS_Settings__c.AccountManagerPath__c, '/restapi/account-manager/v1.0')
            .setField(NGBS_Settings__c.InvoiceEnginePath__c, '/restapi/invoice-engine/v1.0')
            .setField(NGBS_Settings__c.CatalogPath__c, '/restapi/catalog/v1.0')
            .setField(NGBS_Settings__c.Login__c, 'login')
            .setField(NGBS_Settings__c.Password__c, 'password')
            .create();
    }

    @isTest
    static void testBatchJobWithPopulatedPackageBIFR() {
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(Account.SObjectType))
            .setField(Account.BillingStreet, 'street')
            .setField(Account.BillingCity, 'city')
            .setField(Account.BillingState, 'state')
            .setField(Account.BillingPostalCode, '12345')
            .setField(Account.BillingCountry, 'France')
            .setField(Account.Billing_System__c, AccountHelper.BILLING_SYSTEM_NBS)
            .create()
            .getRecord();

        Quote q = createQuote(createOpportunity(acc));
        q.Package_Info__c = generateQuotePackageInfoBIDE();
        insert q;

        Test.setMock(HttpCalloutMock.class, new MockBusinessIdentitites());
        Test.startTest();
            Database.executeBatch(new BatchJob_UpdtQuotePackageInfo(), 5);
        Test.stopTest();
        q = (Quote) new QuoteSelector().selectQuotes().executeQuery().get(0);

        BillingWrappers.QuotePackageInfo packageInfo = (BillingWrappers.QuotePackageInfo) JSON.deserialize(
            q.Package_Info__c.substring(1, q.Package_Info__c.length() - 1), BillingWrappers.QuotePackageInfo.class
        );

        System.assertEquals(true, packageInfo.packageBusinessIdentities != null, 'Incorrect population of package info');
        System.assertEquals(true, packageInfo.packageBusinessIdentities.approvedBi.id == '1', 'Incorrect population of package info');
        System.assertEquals(true, packageInfo.packageBusinessIdentities.selectedBi.id == '1', 'Incorrect population of package info');
        System.assertEquals(true, packageInfo.packageBusinessIdentities.defaultBi.id  == '1', 'Incorrect population of package info');
    }

    @isTest
    static void testBatchJobWithPopulatedPackageBIDE() {
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(Account.SObjectType))
            .setField(Account.BillingStreet, 'street')
            .setField(Account.BillingCity, 'city')
            .setField(Account.BillingState, 'state')
            .setField(Account.BillingPostalCode, '12345')
            .setField(Account.BillingCountry, 'Germany')
            .setField(Account.Billing_System__c, AccountHelper.BILLING_SYSTEM_NBS)
            .create()
            .getRecord();

        Quote q = createQuote(createOpportunity(acc));
        q.Package_Info__c = generateQuotePackageInfo();
        insert q;

        Test.setMock(HttpCalloutMock.class, new MockBusinessIdentitites());
        Test.startTest();
        Database.executeBatch(new BatchJob_UpdtQuotePackageInfo(), 5);
        Test.stopTest();
        q = (Quote) new QuoteSelector().selectQuotes().executeQuery().get(0);

        BillingWrappers.QuotePackageInfo packageInfo = (BillingWrappers.QuotePackageInfo) JSON.deserialize(
            q.Package_Info__c.substring(1, q.Package_Info__c.length() - 1), BillingWrappers.QuotePackageInfo.class
        );

        System.assertEquals(true, packageInfo.packageBusinessIdentities != null, 'Incorrect population of package info');
        System.assertEquals(true, packageInfo.packageBusinessIdentities.approvedBi.id == '33', 'Incorrect population of package info');
        System.assertEquals(true, packageInfo.packageBusinessIdentities.selectedBi.id == '33', 'Incorrect population of package info');
        System.assertEquals(true, packageInfo.packageBusinessIdentities.defaultBi.id  == '33', 'Incorrect population of package info');
    }

    @isTest
    static void testBatchJobWithPopulatedPackageBIUK() {
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(Account.SObjectType))
            .setField(Account.BillingStreet, 'street')
            .setField(Account.BillingCity, 'city')
            .setField(Account.BillingState, 'state')
            .setField(Account.BillingPostalCode, '12345')
            .setField(Account.BillingCountry, 'United Kingdom')
            .setField(Account.Billing_System__c, AccountHelper.BILLING_SYSTEM_NBS)
            .create()
            .getRecord();

        Quote q = createQuote(createOpportunity(acc));
        q.Package_Info__c = generateQuotePackageInfoBIDE();
        insert q;

        Test.setMock(HttpCalloutMock.class, new MockBusinessIdentitites());
        Test.startTest();
        Database.executeBatch(new BatchJob_UpdtQuotePackageInfo(), 5);
        Test.stopTest();
        q = (Quote) new QuoteSelector().selectQuotes().executeQuery().get(0);

        BillingWrappers.QuotePackageInfo packageInfo = (BillingWrappers.QuotePackageInfo) JSON.deserialize(
            q.Package_Info__c.substring(1, q.Package_Info__c.length() - 1), BillingWrappers.QuotePackageInfo.class
        );

        System.assertEquals(true, packageInfo.packageBusinessIdentities != null, 'Incorrect population of package info');
        System.assertEquals(true, packageInfo.packageBusinessIdentities.approvedBi.id == '33', 'Incorrect population of package info');
        System.assertEquals(true, packageInfo.packageBusinessIdentities.selectedBi.id == '33', 'Incorrect population of package info');
        System.assertEquals(true, packageInfo.packageBusinessIdentities.defaultBi.id  == '33', 'Incorrect population of package info');
    }

    @isTest
    static void testBatchJobWithoutPackageBI() {
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(Account.SObjectType))
            .setField(Account.BillingStreet, 'street')
            .setField(Account.BillingCity, 'city')
            .setField(Account.BillingState, 'state')
            .setField(Account.BillingPostalCode, '12345')
            .setField(Account.BillingCountry, 'Germany')
            .setField(Account.Billing_System__c, AccountHelper.BILLING_SYSTEM_NBS)
            .create()
            .getRecord();

        Quote q = createQuote(createOpportunity(acc));
        q.Package_Info__c = generateQuotePackageInfoWithoutBi();
        insert q;

        Test.setMock(HttpCalloutMock.class, new MockBusinessIdentitites());
        Test.startTest();
            Database.executeBatch(new BatchJob_UpdtQuotePackageInfo(), 5);
        Test.stopTest();
        q = (Quote) new QuoteSelector().selectQuotes().executeQuery().get(0);

        BillingWrappers.QuotePackageInfo packageInfo = (BillingWrappers.QuotePackageInfo) JSON.deserialize(
            q.Package_Info__c.substring(1, q.Package_Info__c.length() - 1), BillingWrappers.QuotePackageInfo.class
        );

        System.assertEquals(true, packageInfo.packageBusinessIdentities != null, 'Incorrect population of package info');
        System.assertEquals(true, packageInfo.packageBusinessIdentities.approvedBi.id == '33', 'Incorrect population of package info');
        System.assertEquals(true, packageInfo.packageBusinessIdentities.selectedBi.id == '33', 'Incorrect population of package info');
        System.assertEquals(true, packageInfo.packageBusinessIdentities.defaultBi.id  == '33', 'Incorrect population of package info');
    }

    @isTest
    static void testBatchJobWithoutPackageId() {
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(Account.SObjectType))
            .setField(Account.BillingStreet, 'street')
            .setField(Account.BillingCity, 'city')
            .setField(Account.BillingState, 'state')
            .setField(Account.BillingPostalCode, '12345')
            .setField(Account.BillingCountry, 'France')
            .setField(Account.Billing_System__c, AccountHelper.BILLING_SYSTEM_NBS)
            .create()
            .getRecord();

        Quote q = createQuote(createOpportunity(acc));
        q.Package_Info__c = generateQuotePackageInfoWithoutPackageId();
        insert q;

        Test.setMock(HttpCalloutMock.class, new MockBusinessIdentitites());
        Test.startTest();
            Database.executeBatch(new BatchJob_UpdtQuotePackageInfo(), 5);
        Test.stopTest();
        q = (Quote) new QuoteSelector().selectQuotes().executeQuery().get(0);

        BillingWrappers.QuotePackageInfo packageInfo = (BillingWrappers.QuotePackageInfo) JSON.deserialize(
            q.Package_Info__c.substring(1, q.Package_Info__c.length() - 1), BillingWrappers.QuotePackageInfo.class
        );

        System.assertEquals(true, packageInfo.packageBusinessIdentities == null, 'Incorrect population of package info');
    }

    @isTest
    static void testBatchJobWithoutPackageInfo() {
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(Account.SObjectType))
            .setField(Account.BillingStreet, 'street')
            .setField(Account.BillingCity, 'city')
            .setField(Account.BillingState, 'state')
            .setField(Account.BillingPostalCode, '12345')
            .setField(Account.BillingCountry, 'France')
            .setField(Account.Billing_System__c, AccountHelper.BILLING_SYSTEM_NBS)
            .create()
            .getRecord();

        Quote q = createQuote(createOpportunity(acc));
        insert q;

        Test.setMock(HttpCalloutMock.class, new MockBusinessIdentitites());
        Test.startTest();
            Database.executeBatch(new BatchJob_UpdtQuotePackageInfo(), 5);
        Test.stopTest();
        q = (Quote) new QuoteSelector().selectQuotes().executeQuery().get(0);

        System.assertEquals(true, String.isBlank(q.Package_Info__c), 'Incorrect population of package info');
    }

    @isTest
    static void testBatchJobExistingAccWithoutPackageBI() {
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(Account.SObjectType))
            .setField(Account.BillingStreet, 'street')
            .setField(Account.BillingCity, 'city')
            .setField(Account.BillingState, 'state')
            .setField(Account.BillingPostalCode, '12345')
            .setField(Account.BillingCountry, 'Germany')
            .setField(Account.Billing_System__c, AccountHelper.BILLING_SYSTEM_NBS)
            .setField(Account.Billing_ID__c, '123')
            .create()
            .getRecord();

        Quote q = createQuote(createOpportunity(acc));
        q.Package_Info__c = generateQuotePackageInfoWithoutBi();
        insert q;

        Test.setMock(HttpCalloutMock.class, new MockBusinessIdentitites());
        Test.startTest();
            Database.executeBatch(new BatchJob_UpdtQuotePackageInfo(), 5);
        Test.stopTest();
        q = (Quote) new QuoteSelector().selectQuotes().executeQuery().get(0);

        BillingWrappers.QuotePackageInfo packageInfo = (BillingWrappers.QuotePackageInfo) JSON.deserialize(
            q.Package_Info__c.substring(1, q.Package_Info__c.length() - 1), BillingWrappers.QuotePackageInfo.class
        );

        System.assertEquals(true, packageInfo.packageBusinessIdentities != null, 'Incorrect population of package info');
        System.assertEquals(true, packageInfo.packageBusinessIdentities.approvedBi.id == '1', 'Incorrect population of package info');
        System.assertEquals(true, packageInfo.packageBusinessIdentities.selectedBi.id == '1', 'Incorrect population of package info');
        System.assertEquals(true, packageInfo.packageBusinessIdentities.defaultBi.id == '1', 'Incorrect population of package info');
    }

    @isTest
    static void testBatchJobExistingAccWithoutPackageInfo() {
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(Account.SObjectType))
            .setField(Account.BillingStreet, 'street')
            .setField(Account.BillingCity, 'city')
            .setField(Account.BillingState, 'state')
            .setField(Account.BillingPostalCode, '12345')
            .setField(Account.BillingCountry, 'France')
            .setField(Account.Billing_System__c, AccountHelper.BILLING_SYSTEM_NBS)
            .setField(Account.Billing_ID__c, '123')
            .create()
            .getRecord();

        Quote q = createQuote(createOpportunity(acc));
        insert q;

        Test.setMock(HttpCalloutMock.class, new MockBusinessIdentitites());
        Test.startTest();
            Database.executeBatch(new BatchJob_UpdtQuotePackageInfo(), 5);
        Test.stopTest();
        q = (Quote) new QuoteSelector().selectQuotes().executeQuery().get(0);

        System.assertEquals(true, String.isBlank(q.Package_Info__c), 'Incorrect population of package info');
    }

    @isTest
    static void testBatchJobExistingAccWithoutPackageId() {
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(Account.SObjectType))
            .setField(Account.BillingStreet, 'street')
            .setField(Account.BillingCity, 'city')
            .setField(Account.BillingState, 'state')
            .setField(Account.BillingPostalCode, '12345')
            .setField(Account.BillingCountry, 'France')
            .setField(Account.Billing_System__c, AccountHelper.BILLING_SYSTEM_NBS)
            .setField(Account.Billing_ID__c, '123')
            .create()
            .getRecord();

        Quote q = createQuote(createOpportunity(acc));
        q.Package_Info__c = generateQuotePackageInfoWithoutPackageId();
        insert q;

        Test.setMock(HttpCalloutMock.class, new MockBusinessIdentitites());
        Test.startTest();
            Database.executeBatch(new BatchJob_UpdtQuotePackageInfo(), 5);
        Test.stopTest();
        q = (Quote) new QuoteSelector().selectQuotes().executeQuery().get(0);

        BillingWrappers.QuotePackageInfo packageInfo = (BillingWrappers.QuotePackageInfo) JSON.deserialize(
            q.Package_Info__c.substring(1, q.Package_Info__c.length() - 1), BillingWrappers.QuotePackageInfo.class
        );

        System.assertEquals(true, packageInfo.packageBusinessIdentities != null, 'Incorrect population of package info');
        System.assertEquals(true, packageInfo.packageBusinessIdentities.approvedBi.id == '1', 'Incorrect population of package info');
        System.assertEquals(true, packageInfo.packageBusinessIdentities.selectedBi.id == '1', 'Incorrect population of package info');
        System.assertEquals(true, packageInfo.packageBusinessIdentities.defaultBi.id  == '1', 'Incorrect population of package info');
    }

    @isTest
    static void testBatchJobWithPopulatedTaxNumbers() {
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(Account.SObjectType))
            .setField(Account.BillingStreet, 'street')
            .setField(Account.BillingCity, 'city')
            .setField(Account.BillingState, 'state')
            .setField(Account.BillingPostalCode, '12345')
            .setField(Account.BillingCountry, 'France')
            .setField(Account.Billing_System__c, AccountHelper.BILLING_SYSTEM_NBS)
            .create()
            .getRecord();

        Quote q = createQuote(createOpportunity(acc));
        q.Package_Info__c = generateQuotePackageInfoWithTaxNumbers();
        insert q;

        Test.setMock(HttpCalloutMock.class, new MockBusinessIdentitites());
        Test.startTest();
            Database.executeBatch(new BatchJob_UpdtQuotePackageInfo(), 5);
        Test.stopTest();
        q = (Quote) new QuoteSelector().selectQuotes().executeQuery().get(0);

        System.assertEquals(true, q.Package_Info__c != null, 'Incorrect population of package info');
        System.assertEquals(true, q.Package_Info__c.contains('taxNumbers'), 'Incorrect population of package info');
    }

    public static Opportunity createOpportunity(Account acc) {
        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setField(Opportunity.RecordTypeId, OpportunityHelper.RT_ID_NEW_SALES_OPPORTUNITY)
            .setField(Opportunity.Brand_Name__c, OpportunityHelper.BRAND_RINGCENTRAL_EU)
            .setField(Opportunity.AccountId, acc.Id)
            .setField(Opportunity.StageName, '1. Qualify')
            .setField(Opportunity.CloseDate, System.today())
            .create()
            .getRecord();

        return opp;

    }

    public static Quote createQuote(Opportunity opp) {
        Quote q = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.Name => ValueProviderBuilder.provideUniqueString('Test Quote'),
                Quote.OpportunityId => opp.Id,
                Quote.Status => QuoteHelper.QUOTE_STATUS_DRAFT,
                Quote.Approved_Status__c => QuoteHelper.APPROVAL_STATUS_APPROVED,
                Quote.Total_Number_of_Digital_Lines__c => 1,
                Quote.Start_Date__c => Date.today(),
                Quote.End_Date__c => Date.today().addDays(2),
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING
            })
            .build()
            .getRecord();

        return q;
    }

    public static String generateQuotePackageInfoWithTaxNumbers() {
        return '[{"id":"65","version":"1","packageInfo":{"catalogId":"65","version":"1","name":"Office Standard 1/2/20/100+ Lines - 2021/2022/2023/2024","displayName":"RingCentral Office Standard"},' +
            '"productName":"Office","productId":"2","duration":"Monthly","edition":{"id":1,"name":"Standard"},' +
            '"contract":{"id":"a8f0v0000002BiLAAU","extId":"Office_Europe","billingId":null},' +
            '"offerType":"Regular","poc":null,"globalPackageLimits":[{"value":"6000","code":"MONTHLY_AMOUNT_LIMIT","name":"Monthly money amount limit","type":"Amount","scope":"BillingCycle","transactionType":"Any","target":"Global","exclusions":[{"target":"LicenseCategoryId","targetId":"AP"}],"override":false}],' +
            '"permissions":null,' +
            '"packageBusinessIdentities":{"approvedBi":{"id":1,"name":"RingCentral, Ltd (France)","address":{"label":null,"firstName":"RingCentral France","lastName":"","phone":"","email":null,"street1":"3-5 rue Saint Georges","street2":"","city":"Paris","county":"","state":"","zip":"75009","country":"FRA"},"isDefault":true,"taxNumbers":[{"name":"VAT No.","number":"FR 55850332149"}]},"defaultBi":{"id":1,"name":"RingCentral, Ltd (France)","address":{"label":null,"firstName":"RingCentral France","lastName":"","phone":"","email":null,"street1":"3-5 rue Saint Georges","street2":"","city":"Paris","county":"","state":"","zip":"75009","country":"FRA"},"isDefault":true,"taxNumbers":[{"name":"VAT No.","number":"FR 55850332149"}]}},' +
            '"existingPackageInfo":{}}]';
    }

    public static String generateQuotePackageInfo() {
        return '[{"id":"65","version":"1","packageInfo":{"catalogId":"65","version":"1","name":"Office Standard 1/2/20/100+ Lines - 2021/2022/2023/2024","displayName":"RingCentral Office Standard"},' +
            '"productName":"Office","productId":"2","duration":"Monthly","edition":{"id":1,"name":"Standard"},' +
            '"contract":{"id":"a8f0v0000002BiLAAU","extId":"Office_Europe","billingId":null},' +
            '"offerType":"Regular","poc":null,"globalPackageLimits":[{"value":"6000","code":"MONTHLY_AMOUNT_LIMIT","name":"Monthly money amount limit","type":"Amount","scope":"BillingCycle","transactionType":"Any","target":"Global","exclusions":[{"target":"LicenseCategoryId","targetId":"AP"}],"override":false}],' +
            '"permissions":null,' +
            '"packageBusinessIdentities":{"approvedBi":{"id":1,"name":"RingCentral, Ltd (France)","address":{"label":null,"firstName":"RingCentral France","lastName":"","phone":"","street1":"3-5 rue Saint Georges","street2":"","city":"Paris","county":"","state":"","zip":"75009","country":"FRA"},"isDefault":true},"defaultBi":{"id":1,"name":"RingCentral, Ltd (France)","address":{"label":null,"firstName":"RingCentral France","lastName":"","phone":"","street1":"3-5 rue Saint Georges","street2":"","city":"Paris","county":"","state":"","zip":"75009","country":"FRA"},"isDefault":true},"selectedBi":{"id":1,"name":"RingCentral, Ltd (France)","address":{"label":null,"firstName":"RingCentral France","lastName":"","phone":"","street1":"3-5 rue Saint Georges","street2":"","city":"Paris","county":"","state":"","zip":"75009","country":"FRA"},"isDefault":true}},' +
            '"existingPackageInfo":{}}]';
    }

    public static String generateQuotePackageInfoBIDE() {
        return '[{"id":"65","version":"1","packageInfo":{"catalogId":"65","version":"1","name":"Office Standard 1/2/20/100+ Lines - 2021/2022/2023/2024","displayName":"RingCentral Office Standard"},' +
            '"productName":"Office","productId":"2","duration":"Monthly","edition":{"id":1,"name":"Standard"},' +
            '"contract":{"id":"a8f0v0000002BiLAAU","extId":"Office_Europe","billingId":null},' +
            '"offerType":"Regular","poc":null,"globalPackageLimits":[{"value":"6000","code":"MONTHLY_AMOUNT_LIMIT","name":"Monthly money amount limit","type":"Amount","scope":"BillingCycle","transactionType":"Any","target":"Global","exclusions":[{"target":"LicenseCategoryId","targetId":"AP"}],"override":false}],' +
            '"permissions":null,' +
            '"packageBusinessIdentities":{"approvedBi":{"id":33,"name":"RingCentral, Ltd (Germany)","address":{"label":null,"firstName":"RingCentral Germany","lastName":"","phone":"","street1":"3-5 rue Saint Georges","street2":"","city":"Paris","county":"","state":"","zip":"75009","country":"DEU"},"isDefault":true},"defaultBi":{"id":33,"name":"RingCentral, Ltd (Germany)","address":{"label":null,"firstName":"RingCentral DE","lastName":"","phone":"","street1":"3-5 rue Saint Georges","street2":"","city":"Paris","county":"","state":"","zip":"75009","country":"DEU"},"isDefault":true},"selectedBi":{"id":33,"name":"RingCentral, Ltd (Germany)","address":{"label":null,"firstName":"RingCentral DE","lastName":"","phone":"","street1":"3-5 rue Saint Georges","street2":"","city":"Paris","county":"","state":"","zip":"75009","country":"DEU"},"isDefault":true}},' +
            '"existingPackageInfo":{}}]';
    }

    public static String generateQuotePackageInfoWithoutBi() {
        return '[{"id":"65","version":"1","packageInfo":{"catalogId":"65","version":"1","name":"Office Standard 1/2/20/100+ Lines - 2021/2022/2023/2024","displayName":"RingCentral Office Standard"},' +
            '"productName":"Office","productId":"2","duration":"Monthly","edition":{"id":1,"name":"Standard"},' +
            '"contract":{"id":"a8f0v0000002BiLAAU","extId":"Office_Europe","billingId":null},' +
            '"offerType":"Regular","poc":null,"globalPackageLimits":[{"value":"6000","code":"MONTHLY_AMOUNT_LIMIT","name":"Monthly money amount limit","type":"Amount","scope":"BillingCycle","transactionType":"Any","target":"Global","exclusions":[{"target":"LicenseCategoryId","targetId":"AP"}],"override":false}],' +
            '"permissions":null,' +
            '"existingPackageInfo":{}}]';
    }

    public static String generateQuotePackageInfoWithoutPackageId() {
        return '[{"version":"1","packageInfo":{"catalogId":"65","version":"1","name":"Office Standard 1/2/20/100+ Lines - 2021/2022/2023/2024","displayName":"RingCentral Office Standard"},' +
            '"productName":"Office","productId":"2","duration":"Monthly","edition":{"id":1,"name":"Standard"},' +
            '"contract":{"id":"a8f0v0000002BiLAAU","extId":"Office_Europe","billingId":null},' +
            '"offerType":"Regular","poc":null,"globalPackageLimits":[{"value":"6000","code":"MONTHLY_AMOUNT_LIMIT","name":"Monthly money amount limit","type":"Amount","scope":"BillingCycle","transactionType":"Any","target":"Global","exclusions":[{"target":"LicenseCategoryId","targetId":"AP"}],"override":false}],' +
            '"permissions":null,' +
            '"existingPackageInfo":{}}]';
    }

    public class MockBusinessIdentitites implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();
            res.setStatus('OK');
            res.setStatusCode(200);

            if (req.getEndpoint().contains('http://185.23.251.118:8080/restapi/catalog/v1.0/packages')) {
                res.setBody(billingIdentitiesResponse);
            } else if (req.getEndpoint().contains('http://185.23.251.118:8080/restapi/account-manager/v1.0/account')) {
                res.setBody(accountInfo);
            } else if (req.getEndpoint().contains('http://185.23.251.118:8080/restapi/catalog/v1.0/businessidentities')) {
                res.setBody(accountBi);
            }
            return res;
        }
    }
}