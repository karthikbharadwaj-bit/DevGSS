@isTest
public with sharing class Test_CreditMemoService {

    public static String testJSONResponse;
    private final static String FIRST_CREDIT_MEMO_ID = '444444';
    private final static String SECOND_CREDIT_MEMO_ID = '555555';

    private static void makeData(Integer count){
        List<Account> accs = new List<Account>();
        for (Integer i = 0; i < count; i++) {
            Account testAcc = new Account(
                Name = 'testAcc ' + i,
                InContact_Service__c = 'Contact Center Basic',
                No_of_InContact_Seats__c = 3,
                RC_User_ID__c = '23232' + i
            );
            accs.add(testAcc);
        }
        insert accs;

        List<Contact> contacts = new List<Contact>();
        for (Account acc : accs) {
            Contact testContact = new Contact(
                Account = acc,
                LastName = 'Test' + acc.Name,
                Preferred_Language__c = 'en_US',
                Email = 'test@test.com',
                Phone = '7777777',
                CurrencyIsoCode = 'USD'
            );
            contacts.add(testContact);
        }
        insert contacts;

        List<Opportunity> opps = new List<Opportunity>();
        for (Contact con : contacts) {
            Opportunity opp = new Opportunity(
                Name = 'Test Opportunity 2017 ' + con.Account.Name,
                Type = 'Existing Business',
                Sales_Model__c = 'Direct',
                Brand_Name__c = 'RingCentral',
                Tier_Name__c = 'Office',
                Primary_Opportunity_Contact__c = con.Id,
                StageName = '1. Qualify',
                CloseDate = System.today(),
                CurrencyIsoCode = 'USD'
            );
            opps.add(opp);
        }
        insert opps;

        List<Product2> productList = new List<Product2>();

        Product2 testProduct1 = new Product2(
            Name = 'CloudConnect Setup',
            IsActive = true,
            Sub_Category__c = 'Contact Center',
            Charge_Term__c = 'Annual'
        );
        productList.add(testProduct1);

        Product2 testProduct2 = new Product2(
            Name = 'CloudConnect - Standard 200 Mbps',
            IsActive = true,
            Sub_Category__c = 'Contact Center',
            Charge_Term__c = 'Annual'
        );
        productList.add(testProduct2);

        insert productList;

        List<PriceBookEntry> pbeList = new List<PriceBookEntry>();

        PriceBookEntry testPBE1 = new PriceBookEntry(
            Pricebook2Id = Test.getStandardPricebookId(),
            IsActive = true,
            UnitPrice = 1000,
            Product2Id = testProduct1.Id
        );
        pbeList.add(testPBE1);

        PriceBookEntry testPBE2 = new PriceBookEntry(
            Pricebook2Id = Test.getStandardPricebookId(),
            IsActive = true,
            UnitPrice = 2000,
            Product2Id = testProduct2.Id
        );
        pbeList.add(testPBE2);

        insert pbeList;

        List<Quote> quotes = new List<Quote>();
        Id recTypeId = [SELECT Id FROM RecordType WHERE SobjectType = 'Quote' and Name LIKE '%Contact Center%'].Id;
        for (Opportunity opp : opps) {
            Quote testQuote = new Quote(
                Name = 'testQuote',
                OpportunityId = opp.id,
                Initial_Term_months__c = '24',
                Pricebook2Id = Test.getStandardPricebookId(),
                RecordTypeId = recTypeId
            );
            quotes.add(testQuote);
        }
        insert quotes;

        List<QuoteLineItem> qliList = new List<QuoteLineItem>();
        for (Quote qt : quotes) {
            QuoteLineItem qli1 = new QuoteLineItem(
                QuoteId = qt.Id,
                Product2Id = testProduct1.Id,
                Quantity = 2,
                UnitPrice = testPBE1.UnitPrice,
                PricebookEntryId = testPBE1.Id
            );
            qliList.add(qli1);
        }

        insert qliList;

        Id ccRecTypeId = Order.SObjectType.getDescribe().getRecordTypeInfosByName().get('Contact Center').getRecordTypeId();

        List<Order> orders = new List<Order>();
        for (Integer i = 0; i < count; i++) {
            Order testOrder = new Order(
                AccountId = accs[i].Id,
                Status = 'New',
                EffectiveDate = System.today(),
                inContact_Cluster__c = 'C20',
                inContact_account_ID__c = 'testInContactAccountId',
                Provision_Date__c = System.today(),
                Pricebook2Id = Test.getStandardPricebookId(),
                QuoteId = quotes[i].Id,
                OpportunityId = opps[i].Id,
                Submitted_Date__c = DateTime.now(),
                RecordTypeId = ccRecTypeId,
                Credit_Amount__c = 100.50,
                Taxes_Amount__c = 90.50
            );
            orders.add(testOrder);
        }
        insert orders;

        List<OrderItem> orderItemList = new List<OrderItem>();

        for (Integer i = 0; i < count; i++) {
            OrderItem testOrderItem1 = new OrderItem(
                OrderId = orders[i].Id,
                PricebookEntryId = testPBE1.Id,
                Quantity = qliList[i].Quantity,
                UnitPrice = qliList[i].UnitPrice
            );
            orderItemList.add(testOrderItem1);
        }

        insert orderItemList;
    }

    public static void setTestResponse(Id orderId, Boolean testError) {
        String status = testError ? 'error' : 'success';
        String message = testError ? 'Duplicate order' : '';
        String testResponse = '{"SFDCFSCResponse":{"responseData":[{"userId":"63534242004","orderId":"' + orderId +
                                    '","status":"'+ status + '","NSCreditMemoId":"' + FIRST_CREDIT_MEMO_ID + '","message":"' + message +
                                    '"}],"responseTimestamp":"2021-06-01T00:00:00Z"}}';

        testJSONResponse = testResponse;
    }

    public static void setBulkTestResponse(Id orderId, Id secOrderId, Boolean testError) {
        String status = testError ? 'error' : 'success';
        String message = testError ? 'Duplicate order' : '';
        String testResponse = '{"SFDCFSCResponse":{"responseData":[{"userId":"63534242004","orderId":"' + orderId +
                                    '","status":"'+ status + '","NSCreditMemoId":"' + FIRST_CREDIT_MEMO_ID + '","message":"' + message +
                                    '"},{"userId":"63534242004","orderId":"' + secOrderId + '","status":"success",' +
                                    '"NSCreditMemoId":"' + SECOND_CREDIT_MEMO_ID + '","message":""}],"responseTimestamp":"2021-06-01T00:00:00Z"}}';

        testJSONResponse = testResponse;
    }

    @isTest
    static void testCreateCreditMemo() {
        makeData(1);
        Order ccOrder = [SELECT Id, BillingStatus__c FROM Order LIMIT 1];
        ccOrder.BillingStatus__c = OrderHelper.STATUS_ACCEPTED;

        Integer numberOfJobs = Limits.getQueueableJobs();

        Test.startTest();
        update ccOrder;
        Test.stopTest();

        System.assertEquals(numberOfJobs, Limits.getQueueableJobs());
    }

    @isTest
    static void testCreditMemoService() {
        makeData(2);
        new SObjectBuilder(Contact_Center_FSC__c.SObjectType)
            .setField(Contact_Center_FSC__c.Credit_Memo_Endpoint__c, 'http://199.68.214.238/')
            .setField(Contact_Center_FSC__c.EmailForCreditMemoFailures__c, 'testUser@mail.com.invalid')
            .create();

        Order ccOrder = [SELECT Id, BillingStatus__c, AccountId, CurrencyIsoCode,
                                Submitted_Date__c, FSC_Total_Amount__c
                        FROM Order LIMIT 1];
        ccOrder.BillingStatus__c = OrderHelper.STATUS_ACCEPTED;

        setTestResponse(ccOrder.Id, false);

        Map<Id, Order> acceptedCCFSCOrders = new Map<Id, Order>();
        acceptedCCFSCOrders.put(ccOrder.Id, ccOrder);

        Test.setMock(HttpCalloutMock.class, new MockCreditMemo());
        Test.startTest();
        System.enqueueJob(new CreditMemoService(acceptedCCFSCOrders));
        Test.stopTest();

        Order updatedCCOrder = [SELECT Id, CC_FSC_CreditMemo__c FROM Order WHERE Id = :ccOrder.Id LIMIT 1];

        System.assertEquals(updatedCCOrder.CC_FSC_CreditMemo__c, FIRST_CREDIT_MEMO_ID);
    }

    @isTest
    static void testNegativeCreditMemoService() {
        makeData(2);
        new SObjectBuilder(Contact_Center_FSC__c.SObjectType)
            .setField(Contact_Center_FSC__c.Credit_Memo_Endpoint__c, 'http://199.68.214.238/')
            .setField(Contact_Center_FSC__c.EmailForCreditMemoFailures__c, 'testUser@mail.com.invalid')
            .create();

        Order ccOrder = [SELECT Id, BillingStatus__c, AccountId, CurrencyIsoCode,
                                Submitted_Date__c, FSC_Total_Amount__c
                        FROM Order LIMIT 1];
        ccOrder.BillingStatus__c = OrderHelper.STATUS_ACCEPTED;

        setTestResponse(ccOrder.Id, true);

        Map<Id, Order> acceptedCCFSCOrders = new Map<Id, Order>();
        acceptedCCFSCOrders.put(ccOrder.Id, ccOrder);

        Test.setMock(HttpCalloutMock.class, new MockCreditMemo());
        Test.startTest();
        System.enqueueJob(new CreditMemoService(acceptedCCFSCOrders));
        Test.stopTest();

        Order updatedCCOrder = [SELECT Id, CC_FSC_CreditMemo__c FROM Order WHERE Id = :ccOrder.Id LIMIT 1];

        System.assertEquals(updatedCCOrder.CC_FSC_CreditMemo__c, null);
    }

    @isTest
    static void testEmptyEndpointCreditMemoService() {
        makeData(1);
        new SObjectBuilder(Contact_Center_FSC__c.SObjectType)
            .setField(Contact_Center_FSC__c.EmailForCreditMemoFailures__c, 'testUser@mail.com.invalid')
            .create();

        Order ccOrder = [SELECT Id, BillingStatus__c, AccountId, CurrencyIsoCode,
                                Submitted_Date__c, FSC_Total_Amount__c
                        FROM Order LIMIT 1];
        ccOrder.BillingStatus__c = OrderHelper.STATUS_ACCEPTED;

        setTestResponse(ccOrder.Id, false);

        Map<Id, Order> acceptedCCFSCOrders = new Map<Id, Order>();
        acceptedCCFSCOrders.put(ccOrder.Id, ccOrder);

        Test.setMock(HttpCalloutMock.class, new MockCreditMemo());
        Test.startTest();
        System.enqueueJob(new CreditMemoService(acceptedCCFSCOrders));
        Test.stopTest();

        Order updatedCCOrder = [SELECT Id, CC_FSC_CreditMemo__c FROM Order WHERE Id = :ccOrder.Id LIMIT 1];

        System.assertEquals(updatedCCOrder.CC_FSC_CreditMemo__c, null);
    }

    @isTest
    static void testBulkCreditMemoService() {
        makeData(2);
        new SObjectBuilder(Contact_Center_FSC__c.SObjectType)
            .setField(Contact_Center_FSC__c.Credit_Memo_Endpoint__c, 'http://199.68.214.238/')
            .setField(Contact_Center_FSC__c.EmailForCreditMemoFailures__c, 'testUser@mail.com.invalid')
            .create();

        Map<Id, Order> acceptedCCFSCOrders = new Map<Id, Order>();
        List<Order> ccOrders = [SELECT Id, BillingStatus__c, AccountId, CurrencyIsoCode,
                                    Submitted_Date__c, FSC_Total_Amount__c
                                FROM Order];
        for (Order ccOrder : ccOrders) {
            ccOrder.BillingStatus__c = OrderHelper.STATUS_ACCEPTED;
            acceptedCCFSCOrders.put(ccOrder.Id, ccOrder);
        }

        setBulkTestResponse(ccOrders[0].Id, ccOrders[1].Id, false);

        Test.setMock(HttpCalloutMock.class, new MockCreditMemo());
        Test.startTest();
        System.enqueueJob(new CreditMemoService(acceptedCCFSCOrders));
        Test.stopTest();

        List<Order> updatedCCOrders = [SELECT Id, CC_FSC_CreditMemo__c
                                        FROM Order
                                        WHERE Id IN :acceptedCCFSCOrders.keySet()];

        System.assertNotEquals(updatedCCOrders[0].CC_FSC_CreditMemo__c, null);
        System.assertNotEquals(updatedCCOrders[1].CC_FSC_CreditMemo__c, null);
        System.assertNotEquals(updatedCCOrders[0].CC_FSC_CreditMemo__c, updatedCCOrders[1].CC_FSC_CreditMemo__c);
    }

    @isTest
    static void testNegativeBulkCreditMemoService() {
        makeData(2);
        new SObjectBuilder(Contact_Center_FSC__c.SObjectType)
            .setField(Contact_Center_FSC__c.Credit_Memo_Endpoint__c, 'http://199.68.214.238/')
            .setField(Contact_Center_FSC__c.EmailForCreditMemoFailures__c, 'testUser@mail.com.invalid')
            .create();

        Map<Id, Order> acceptedCCFSCOrders = new Map<Id, Order>();
        List<Order> ccOrders = [SELECT Id, BillingStatus__c, AccountId, CurrencyIsoCode,
                                    Submitted_Date__c, FSC_Total_Amount__c
                                FROM Order];
        for (Order ccOrder : ccOrders) {
            ccOrder.BillingStatus__c = OrderHelper.STATUS_ACCEPTED;
            acceptedCCFSCOrders.put(ccOrder.Id, ccOrder);
        }

        setBulkTestResponse(ccOrders[0].Id, ccOrders[1].Id, true);

        Test.setMock(HttpCalloutMock.class, new MockCreditMemo());
        Test.startTest();
        System.enqueueJob(new CreditMemoService(acceptedCCFSCOrders));
        Test.stopTest();

        Map<Id, Order> updatedCCOrders = new Map<Id, Order>([SELECT Id, CC_FSC_CreditMemo__c
                                        FROM Order
                                        WHERE Id IN :acceptedCCFSCOrders.keySet()]);

        System.assertEquals(updatedCCOrders.get(ccOrders[0].Id).CC_FSC_CreditMemo__c, null);
        System.assertEquals(updatedCCOrders.get(ccOrders[1].Id).CC_FSC_CreditMemo__c, SECOND_CREDIT_MEMO_ID);
    }

    @isTest
    static void testCreditMemoServiceSyncButton() {
        makeData(1);
        new SObjectBuilder(Contact_Center_FSC__c.SObjectType)
            .setField(Contact_Center_FSC__c.Credit_Memo_Endpoint__c, 'http://199.68.214.238/')
            .setField(Contact_Center_FSC__c.EmailForCreditMemoFailures__c, 'testUser@mail.com.invalid')
            .create();

        Order ccOrder = [SELECT Id, BillingStatus__c, AccountId, CurrencyIsoCode,
                                Submitted_Date__c, FSC_Total_Amount__c
                        FROM Order LIMIT 1];
        ccOrder.BillingStatus__c = OrderHelper.STATUS_ACCEPTED;
        update ccOrder;

        setTestResponse(ccOrder.Id, false);

        Test.setMock(HttpCalloutMock.class, new MockCreditMemo());
        Test.startTest();
        CreditMemoService.reSyncFSCButton(ccOrder.Id);
        Test.stopTest();

        Order updatedCCOrder = [SELECT Id, CC_FSC_CreditMemo__c FROM Order WHERE Id = :ccOrder.Id LIMIT 1];

        System.assertEquals(updatedCCOrder.CC_FSC_CreditMemo__c, FIRST_CREDIT_MEMO_ID);
    }

    public class MockCreditMemo implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();
            res.setStatus('OK');
            res.setStatusCode(200);
            res.setBody(testJSONResponse);
            return res;
        }
    }
}