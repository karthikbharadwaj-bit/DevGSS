@IsTest
private class Test_CreditSpendingLimitNGBSSync {
    private static final String CURRENT_SPENDING_LIMIT_RESP = '[{"id":179015005,"name":"Monthly money amount limit","code":"MONTHLY_AMOUNT_LIMIT","value":50555,"type":"Amount","scope":"BillingCycle","transactionType":"Any","target":"Global","targetId":null,"exclusions":[{"target":"LicenseCategoryId","targetId":"AP"},{"target":"LicenseCategoryId","targetId":"HD"}],"override":true,"paymentType":null,"startDate":null,"limitDuration":null,"overriddenLimitId":null,"limitOverride":null}]';
    private static final String CURRENT_PAYMENT_TYPE_RESP = '{"currentType": "Invoice", "formerTypes": [] }';
    private static final String INCREASE_SPENDING_LIMIT_RESP_FAIL = '{"code":422,"message":"[Either limit ID or limit code should be specified, both at the same time are not allowed. accountId=339307005 packageId=139887005]","errors":["Either limit ID or limit code should be specified, both at the same time are not allowed. accountId=339307005 packageId=139887005"]}';
    private static final String CURRENT_SPENDING_LIMIT_RESP_EMPTY = '[]';

    private static final String PACKAGE_ID = '112233445566';
    private static final String PACKAGE_ID_BAD_2 = '665544332211';
    private static final String PACKAGE_ID_BAD_3 = '111222333444';
    private static final String EndPointPaymentMethodType = 'paymentMethod/type';

    private static final String APPROVAL_NAME_1 = 'Approval 1';
    private static final String APPROVAL_NAME_2 = 'Approval 2';
    private static final String APPROVAL_NAME_3 = 'Approval 3';

    @testSetup
    static void generateData() {
        new SObjectBuilder(NGBS_Settings__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                NGBS_Settings__c.BaseEndpoint__c => 'https://testapi/',
                NGBS_Settings__c.AccountManagerPath__c => '/restapi/account-manager/v1.0',
                NGBS_Settings__c.Login__c => '123',
                NGBS_Settings__c.Password__c => '456'
            })
            .create();

        Triggers.switchOff();
        List<Account> accs = (List<Account>) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Name => 'Test Account',
                Account.Account_Payment_Method__c => 'Invoice',
                Account.Billing_ID__c => ValueProviderBuilder.provideList(new List<String>{'123123123123', '636253667367', '876876386755'})
                })
            .quantity(3)
            .create()
            .getRecords();

        new SObjectBuilder(Package__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Package__c.Account__c => ValueProviderBuilder.provideList(new List<Id>{accs[0].Id, accs[1].Id, accs[2].Id}),
                Package__c.Account_Package_Id__c => ValueProviderBuilder.provideList(new List<String>{PACKAGE_ID, PACKAGE_ID_BAD_2, PACKAGE_ID_BAD_3}),
                Package__c.Offer_Type__c => 'Regular',
                Package__c.Package_Catalog_Id__c => '18',
                Package__c.Package_Version__c => '3'
            })
            .quantity(3)
            .create();

        new SObjectBuilder(Approval__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Approval__c.Account__c => ValueProviderBuilder.provideList(new List<Id>{accs[0].Id, accs[1].Id, accs[2].Id}),
                Approval__c.Name => ValueProviderBuilder.provideList(new List<String>{APPROVAL_NAME_1, APPROVAL_NAME_2, APPROVAL_NAME_3}),
                Approval__c.Status__c => ApprovalHelper.STATUS_APPROVED,
                Approval__c.NGBSCurrentSpendingLimit__c => 50555.0,
                Approval__c.NGBSAmountToIncrease__c => 2000,
                Approval__c.RecordTypeId => ApprovalHelper.RT_ID_CREDIT_LIMIT_INCREASE
            })
            .quantity(3)
            .create();

        Triggers.switchOn();
    }

    public class Mock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();
            res.setStatus('OK');
            res.setStatusCode(200);

            String endpoint = req.getEndpoint();
            if (endpoint.endsWith(PACKAGE_ID + '/limits') || endpoint.endsWith(PACKAGE_ID_BAD_3 + '/limits')) {
                res.setBody(CURRENT_SPENDING_LIMIT_RESP);
            } else if (endpoint.endsWith(PACKAGE_ID_BAD_2 + '/limits')) {
                res.setBody(CURRENT_SPENDING_LIMIT_RESP_EMPTY);
            } else if (endpoint.endsWith(EndPointPaymentMethodType)) {
                res.setBody(CURRENT_PAYMENT_TYPE_RESP);
            } else if (endpoint.endsWith(PACKAGE_ID_BAD_3 + '/limits/update')) {
                res.setStatusCode(422);
                res.setStatus('Unprocessable Entity');
                res.setBody(INCREASE_SPENDING_LIMIT_RESP_FAIL);
            }

            return res;
        }
    }

    @IsTest
    static void test_getCurrentSpendingLimit() {
        Id accId = (Id) ([select Account__c from Approval__c where Name =: APPROVAL_NAME_1]).get(0).Account__c;
        Account acc = (Account) new AccountSelector()
            .selectAccountsForApproval(new List<Object>{new Set<Id>{accId}})
            .executeQuery()
            .get(0);

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new Mock());
        NGBSAPI.AccountPackageLimit res = CreditSpendingLimitNGBSSync.getCurrentSpendingLimit(acc.Id, acc.Billing_ID__c, acc.Service_Accounts__r[0].Account_Package_Id__c);
        Test.stopTest();
        System.assertEquals(true, res != null);
        System.assertEquals(50555.0, res.value);
    }

    @IsTest
    static void test_getCurrentSpendingLimit_fail() {
        Id accId = (Id) ([select Account__c from Approval__c where Name =: APPROVAL_NAME_2]).get(0).Account__c;
        Account acc = (Account) new AccountSelector()
            .selectAccountsForApproval(new List<Object>{new Set<Id>{accId}})
            .executeQuery()
            .get(0);

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new Mock());
        NGBSAPI.AccountPackageLimit res = CreditSpendingLimitNGBSSync.getCurrentSpendingLimit(acc.Id, acc.Billing_ID__c, acc.Service_Accounts__r[0].Account_Package_Id__c);
        Test.stopTest();
        System.assertEquals(true, res == null);
    }

    @IsTest
    static void test_getNewLimitFromApproval() {
        Approval__c app = (Approval__c) ([Select Id, Name, NGBSCurrentSpendingLimit__c, NGBSAmountToIncrease__c from Approval__c where Name =: APPROVAL_NAME_1]).get(0);

        NGBSAPI.UpdateAccountPackageLimitData newLimit = CreditSpendingLimitNGBSSync.getNewLimit(app, new NGBSAPI.AccountPackageLimit());
        Assert.areEqual(54555.0, newLimit.value, 'Should return correct new credit value');
    }

    @IsTest
    static void test_increaseCurrentSpendingLimit() {
        Id appId = (Id) ([Select Id from Approval__c where Name =: APPROVAL_NAME_1]).get(0).Id;

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new Mock());
        QueueableBase.enqueJob('CreditSpendingLimitNGBSSync', new List<Id>{appId});
        Test.stopTest();

        Approval__c app1 = (Approval__c) ([Select Id, Name, NGBSSyncInfo__c from Approval__c where Name =: APPROVAL_NAME_1]).get(0);
        System.assertEquals(CreditSpendingLimitNGBSSync.SUCCESS_TEXT, app1.NGBSSyncInfo__c);
    }

    @IsTest
    static void test_increaseCurrentSpendingLimit_failCurrentLimit() {
        Approval__c app = (Approval__c) ([Select Id, Name, NGBSCurrentSpendingLimit__c from Approval__c where Name =: APPROVAL_NAME_1]).get(0);

        Triggers.switchOff();
        app.NGBSCurrentSpendingLimit__c = 55000.0;
        update app;
        Triggers.switchOn();

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new Mock());
        QueueableBase.enqueJob('CreditSpendingLimitNGBSSync', new List<Id>{app.Id});
        Test.stopTest();

        Approval__c app1 = (Approval__c) ([Select Id, Account__c, NGBSSyncInfo__c from Approval__c where Name =: APPROVAL_NAME_1]).get(0);
        System.assertEquals(true, app1.NGBSSyncInfo__c.startsWith(CreditSpendingLimitNGBSSync.ERROR_START_TEXT));
        List<Case> cases = (List<Case>)([SELECT Id FROM Case WHERE Subject =: DealDeskCaseGenerator.CASE_SUBJECT_NGBSAPI_ERROR]);
        System.assertEquals(1, cases.size());
    }

    @IsTest
    static void test_increaseCurrentSpendingLimit_failCurrentLimitIsNull() {
        Id appId = (Id) ([Select Id from Approval__c where Name =: APPROVAL_NAME_2]).get(0).Id;

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new Mock());
        QueueableBase.enqueJob('CreditSpendingLimitNGBSSync', new List<Id>{appId});
        Test.stopTest();

        Approval__c app1 = (Approval__c) ([Select Id, Account__c, NGBSSyncInfo__c from Approval__c where Name =: APPROVAL_NAME_2]).get(0);
        System.assertEquals(true, app1.NGBSSyncInfo__c.startsWith(CreditSpendingLimitNGBSSync.ERROR_START_TEXT));
        List<Case> cases = (List<Case>)([SELECT Id FROM Case WHERE Subject =: DealDeskCaseGenerator.CASE_SUBJECT_NGBSAPI_ERROR]);
        System.assertEquals(1, cases.size());
    }

    @IsTest
    static void test_increaseCurrentSpendingLimit_failResp() {
        Id appId = (Id) ([Select Id from Approval__c where Name =: APPROVAL_NAME_3]).get(0).Id;

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new Mock());
        QueueableBase.enqueJob('CreditSpendingLimitNGBSSync', new List<Id>{appId});
        Test.stopTest();

        Approval__c app1 = (Approval__c) ([Select Id, Account__c, NGBSSyncInfo__c from Approval__c where Name =: APPROVAL_NAME_3]).get(0);
        System.assertEquals(true, app1.NGBSSyncInfo__c.startsWith(CreditSpendingLimitNGBSSync.ERROR_START_TEXT));
        List<Case> cases = (List<Case>)([SELECT Id FROM Case WHERE Subject =: DealDeskCaseGenerator.CASE_SUBJECT_NGBSAPI_ERROR]);
        System.assertEquals(1, cases.size());
    }
}