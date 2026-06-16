@isTest
public with sharing class Test_PaymentInfoSync {
   
    @testSetup
    static void generateData() {
        upsert new NGBS_Settings__c(
            BaseEndpoint__c = 'https://testapi/',
            AccountManagerPath__c = '/restapi/account-manager/v1.0',
            Login__c = '123',
            Password__c = '456'
        );
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
        .setFields(
            new Map<SObjectField, Object>{
                Account.Name => 'Test account',
                Account.Billing_ID__c => '123'
            }
        )
        .create()
        .getRecord();
    }

    @isTest
    static void test_PaymentInfoSync_Job_pos() {
        Account acc = (Account) new AccountSelector()
                .selectAccountByName(new List<Object>{'Test account'})
                .executeQuery()
                .get(0);
        List<PaymentInfoSync.PaymentInfoParams> paramsList = new List<PaymentInfoSync.PaymentInfoParams>();
        paramsList.add(
            new PaymentInfoSync.PaymentInfoParams(
                acc.Billing_ID__c,
                acc.Id,
                QuoteHelper.PAYMENT_METHOD_DIRECT_DEBIT,
                2000,
                null
            )
        );
        BillingHttpRequestMock testMock = new BillingHttpRequestMock();
        testMock.endpointToBodyMap = new Map<String, BillingHttpRequestMock.MockInfo>{
            '/summary?shortView=true' => new BillingHttpRequestMock.MockInfo('{"packages":[{"id":9710002,"catalogId":"101","version":"1","offerType":"ProofOfConcept"}]}')
        };

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, testMock);
            QueueableBase.enqueJob('PaymentInfoSync', paramsList);
        Test.stopTest();

        List<PlatformLog__c> logs = (List<PlatformLog__c>) new QueryFactory(PlatformLog__c.SObjectType)
            .selectFields(new Set<String> {'Id', 'Error__c', 'Source__c', 'StackTrace__c'})
            .executeQuery();

        System.assertEquals(2, logs.size(), 'Should be created successful log records');
        System.assertEquals(null, logs[0].StackTrace__c, 'Log should not contain error');
        System.assertEquals(null, logs[1].StackTrace__c, 'Log should not contain error');
    }

    @isTest
    static void test_PaymentInfoSync_Job_neg_MissedBillingId() {
        Account acc = (Account) new AccountSelector()
                .selectAccountByName(new List<Object>{'Test account'})
                .executeQuery()
                .get(0);
        List<PaymentInfoSync.PaymentInfoParams> paramsList = new List<PaymentInfoSync.PaymentInfoParams>();
        paramsList.add(
            new PaymentInfoSync.PaymentInfoParams(
                '',
                acc.Id,
                QuoteHelper.PAYMENT_METHOD_DIRECT_DEBIT,
                null,
                null
            )
        );
        BillingHttpRequestMock testMock = new BillingHttpRequestMock();
        testMock.endpointToBodyMap = new Map<String, BillingHttpRequestMock.MockInfo>{
            '/summary?shortView=true' => new BillingHttpRequestMock.MockInfo('{"packages":[{"id":9710002,"catalogId":"101","version":"1","offerType":"ProofOfConcept"}]}')
        };

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, testMock);
            QueueableBase.enqueJob('PaymentInfoSync', paramsList);
        Test.stopTest();

        List<PlatformLog__c> logs = (List<PlatformLog__c>) new QueryFactory(PlatformLog__c.SObjectType)
            .selectFields(new Set<String> {'Id', 'Error__c', 'Source__c', 'StackTrace__c'})
            .executeQuery();

        System.assertEquals(PaymentInfoSync.ERROR_HEADER, logs[0].Source__c, 'Should be created error log when billing id is missed');
    
    }

    @isTest
    static void test_PaymentInfoSync_Job_neg_MissedLimitValue() {
        Account acc = (Account) new AccountSelector()
                .selectAccountByName(new List<Object>{'Test account'})
                .executeQuery()
                .get(0);
        List<PaymentInfoSync.PaymentInfoParams> paramsList = new List<PaymentInfoSync.PaymentInfoParams>();
        paramsList.add(
            new PaymentInfoSync.PaymentInfoParams(
                acc.Billing_ID__c,
                acc.Id,
                QuoteHelper.PAYMENT_METHOD_DIRECT_DEBIT,
                null,
                null
            )
        );
        BillingHttpRequestMock testMock = new BillingHttpRequestMock();
        testMock.endpointToBodyMap = new Map<String, BillingHttpRequestMock.MockInfo>{
            '/summary?shortView=true' => new BillingHttpRequestMock.MockInfo('{"packages":[{"id":9710002,"catalogId":"101","version":"1","offerType":"ProofOfConcept"}]}')
        };

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, testMock);
            QueueableBase.enqueJob('PaymentInfoSync', paramsList);
        Test.stopTest();

        List<PlatformLog__c> logs = (List<PlatformLog__c>) new QueryFactory(PlatformLog__c.SObjectType)
            .selectFields(new Set<String> {'Id', 'Error__c', 'Source__c', 'StackTrace__c'})
            .executeQuery();

        System.assertEquals(PaymentInfoSync.ERROR_HEADER, logs[0].Source__c, 'Should be created error log when limit value is missed');
    }
}