@isTest
public class Test_RefundManagementController {

    private static final String APPROVAL_IDENTIFIER = 'Test Approval Identifier';
    private static final String ACCOUNT_IDENTIFIER = 'Test Account Identifier';

    private static final String UNEXPECTED_EXCEPTION_OCCURED = 'Unexpected exception occured ';
    private static final String CORRECT_NGBS_TRANSACTION_JSON = '{"bills":[{"id":34836007,"state":"Paid","recurring":true,"billingCycleNumber":5,"billDate":"2018-08-23T08:01:20.620Z[UTC]","dueDate":"2018-08-23T00:00Z[UTC]","previousBalance":0,"newBalance":12004.28,"appliedCredit":19.23,"remainingCredit":0,"invoices":[{"id":34408007,"packageId":2548007,"type":"Invoice","state":"Paid","created":"2018-08-22T17:10:37.263Z[UTC]","recurring":false,"billingCycleNumber":5,"currency":"USD","preTaxAmount":3632.84,"totalAmount":3859.89,"paidAmount":3859.89,"freeServiceCredit":{"providedCredit":0,"appliedCredit":0}},{"id":20604007,"packageId":2548007,"type":"Invoice","state":"Paid","created":"2018-07-23T16:54:18.847Z[UTC]","recurring":true,"billingCycleNumber":5,"currency":"USD","preTaxAmount":0,"totalAmount":0,"paidAmount":0,"freeServiceCredit":{"providedCredit":0,"appliedCredit":0}}],"payments":[{"id":34790007,"created":"2018-08-23T08:01:20.727Z[UTC]","amount":12004.28,"successful":true,"paymentMethod":{"methodId":1597007,"methodType":"Invoice","nickname":null,"address":{"firstName":"ivan","lastName":"tultsev","phone":null,"street1":" 66 Beacon St","street2":null,"city":"boston","county":null,"state":"MA","zip":"02108","country":"USA"},"info":{"terms":0}}}]}]}';
    private static final String CORRECT_NGBS_BILL_JSON = '{"bill":{"id":20404007,"accountId":2548007,"recurring":true,"state":"Paid","dueDate":"2018-07-23","billDate":"2018-07-23T08:01:51.177Z[UTC]","previousBalance":0,"newBalance":15.93,"appliedCredit":0,"remainingCredit":0,"invoices":[{"id":20432007,"billingAddress":{"firstName":"ivan","lastName":"tultsev","phone":"","street1":" 66 Beacon St","street2":null,"city":"boston","county":null,"state":"MA","zip":"02108","country":"USA"},"date":"2018-07-23T08:01:49.657Z[UTC]","timezone":"America/Los_Angeles","currency":"USD","type":"Invoice","state":"Paid","items":[{"lineNo":"1","parentLineNo":null,"licenseId":4583007,"billingCodeId":null,"licenseExternalId":null,"itemGroupId":40353007,"categoryId":"SC","description":"Subscription","combinedCatalogId":"P:7.1,L:LC_SC_404","billingCycleDuration":1,"numberOfUnits":1,"pricePerUnit":0,"amount":0,"recurring":true,"itemType":"FeatureCharge","dateRangeStart":"2018-07-23","dateRangeEnd":"2018-08-22","discountInfo":null,"glCode":"4005","newLicense":false,"properties":{"servicetype":"54","ZoomCallOut":"true"}},{"lineNo":"2","parentLineNo":null,"licenseId":4582007,"billingCodeId":null,"licenseExternalId":null,"itemGroupId":40352007,"categoryId":"SM","description":"Meetings","combinedCatalogId":"P:7.1,L:LC_SM_405","billingCycleDuration":1,"numberOfUnits":1,"pricePerUnit":14.99,"amount":14.99,"recurring":true,"itemType":"FeatureCharge","dateRangeStart":"2018-07-23","dateRangeEnd":"2018-08-22","discountInfo":null,"glCode":"4072","newLicense":false,"properties":{"LicenseTypeId":"1001","servicetype":"54","ExternalProvisioning":{"ZoomUserType":"Pro","ZoomFeature":"RCMeeting"},"LimitValues":[{"limitid":149,"amount":1000}],"int.raterQty":"1"}},{"lineNo":"3","parentLineNo":null,"licenseId":null,"billingCodeId":null,"licenseExternalId":null,"itemGroupId":40352007,"categoryId":"Remote Software","description":"Telecommunications Sales Tax","combinedCatalogId":null,"billingCycleDuration":0,"numberOfUnits":0,"pricePerUnit":null,"amount":0.94,"recurring":false,"itemType":"Tax Charge","dateRangeStart":"2018-07-23","dateRangeEnd":"2018-07-23","discountInfo":null,"glCode":null,"newLicense":false,"properties":{"categoryType":"Service","taxLevel":"State","country":"USA","rate":"0.0625","city":"BOSTON","effectiveRate":"0.06271","county":"SUFFOLK","avalaraTaxTypeId":"138","taxRateType":"Percent","state":"MA","taxItemId":"5456007"}}],"controlSum":"15.93","preTaxAmount":14.99,"totalAmount":15.93,"paidAmount":15.93,"freeServiceCredit":{"providedCredit":0,"appliedCredit":0},"billingCodesData":{"1000":{"path":[{"name":"RingCentral Inc.","code":null}],"addressId":755381001,"charges":0,"adjustments":0,"taxesAndFees":0,"total":0},"1010":{"path":[{"name":"RingCentral Inc.","code":null},{"name":"San Francisco","code":null}],"addressId":755383001,"charges":2699.88,"adjustments":-279.98,"taxesAndFees":384.98,"total":2804.88},"1020":{"path":[{"name":"RingCentral Inc.","code":null},{"name":"New York","code":null}],"addressId":755382001,"charges":599.76,"adjustments":-79.96,"taxesAndFees":301.3,"total":821.1},"1030":{"path":[{"name":"RingCentral Inc.","code":null},{"name":"San Francisco 2","code":null}],"addressId":755383001,"charges":899.64,"adjustments":-119.94,"taxesAndFees":482.15,"total":1261.85}},"recurring":true}]},"payments":[{"id":20364007,"status":true,"date":"2018-07-23T08:01:51.200Z[UTC]","amount":15.93,"paymentMethod":{"id":1597007,"nickname":null,"type":"Invoice","address":{"firstName":"ivan","lastName":"tultsev","phone":null,"street1":" 66 Beacon St","street2":null,"city":"boston","county":null,"state":"MA","zip":"02108","country":"USA"},"info":{"terms":0}},"providerProfile":null,"providerAuthCode":null}]}';
    private static final String CORRECT_CALCULATE_REFUNDS_BILL_JSON = '{"refundApplicationMap":{"applications":{"20432007":{"40352007":10,"40353007":0}},"taxes":{"20432007":{"40352007":[{"taxItemId":5456007,"description":"Telecommunications Sales Tax","amount":0.64}]}}},"maxAmount":120.63}';
    private static final String CORRECT_NGBS_INVOICE_JSON = '{"id":462266001,"billingAddress":{"firstName":"Vladislav","lastName":"Niyazov","phone":"Fake Phone","street1":"650 5th Ave","street2":null,"city":"New York","county":null,"state":"NY","zip":"10019","country":"USA"},"date":"2018-08-28T12:44:24.276Z[UTC]","timezone":"America/Los_Angeles","currency":"USD","type":"Invoice","state":"Pending","items":[{"lineNo":"1","parentLineNo":null,"licenseId":2536583001,"billingCodeId":null,"licenseExternalId":null,"itemGroupId":1832596001,"categoryId":"LM","description":"Large Meetings 200","combinedCatalogId":"P:7.1,L:LC_LM_406","billingCycleDuration":1,"numberOfUnits":3,"pricePerUnit":90,"amount":270,"recurring":true,"itemType":"FeatureCharge","dateRangeStart":"2018-08-09","dateRangeEnd":"2018-09-08","discountInfo":null,"glCode":"4310","newLicense":true,"properties":{"LicenseTypeId":"1002","ExternalProvisioning":"{\'ZoomFeature\':\'LargeMeeting\', \'capacity\': 200}"}},{"lineNo":"1.1","parentLineNo":"1","licenseId":2536583001,"billingCodeId":null,"licenseExternalId":null,"itemGroupId":1832596001,"categoryId":"LM","description":"Large Meetings 200","combinedCatalogId":"P:7.1,L:LC_LM_406","billingCycleDuration":1,"numberOfUnits":3,"pricePerUnit":-55.16,"amount":-165.48,"recurring":true,"itemType":"ProrationCredit","dateRangeStart":"2018-08-09","dateRangeEnd":"2018-08-27","discountInfo":null,"glCode":"4310","newLicense":true,"properties":{"LicenseTypeId":"1002","ExternalProvisioning":"{\'ZoomFeature\':\'LargeMeeting\', \'capacity\': 200}"}},{"lineNo":"2","parentLineNo":null,"licenseId":2536584001,"billingCodeId":null,"licenseExternalId":null,"itemGroupId":1832597001,"categoryId":"WB","description":"RingCentral Webinar 100","combinedCatalogId":"P:7.1,L:LC_WB_409","billingCycleDuration":1,"numberOfUnits":4,"pricePerUnit":40,"amount":160,"recurring":true,"itemType":"FeatureCharge","dateRangeStart":"2018-08-09","dateRangeEnd":"2018-09-08","discountInfo":null,"glCode":"4310","newLicense":true,"properties":{"LicenseTypeId":"1003","ExternalProvisioning":"{\'ZoomFeature\':\'Webinar\', \'capacity\': 100}"}},{"lineNo":"2.1","parentLineNo":"2","licenseId":2536584001,"billingCodeId":null,"licenseExternalId":null,"itemGroupId":1832597001,"categoryId":"WB","description":"RingCentral Webinar 100","combinedCatalogId":"P:7.1,L:LC_WB_409","billingCycleDuration":1,"numberOfUnits":4,"pricePerUnit":-24.52,"amount":-98.08,"recurring":true,"itemType":"ProrationCredit","dateRangeStart":"2018-08-09","dateRangeEnd":"2018-08-27","discountInfo":null,"glCode":"4310","newLicense":true,"properties":{"LicenseTypeId":"1003","ExternalProvisioning":"{\'ZoomFeature\':\'Webinar\', \'capacity\': 100}"}},{"lineNo":"2.2","parentLineNo":"2","licenseId":2536584001,"billingCodeId":null,"licenseExternalId":null,"itemGroupId":1832597001,"categoryId":"WB","description":"RingCentral Webinar 100 - Discount $5.00 off for 1 month (ends 09/27/2018)","combinedCatalogId":"P:7.1,L:LC_WB_409","billingCycleDuration":1,"numberOfUnits":4,"pricePerUnit":-1.94,"amount":-7.76,"recurring":true,"itemType":"ProratedDiscountCredit","dateRangeStart":"2018-08-28","dateRangeEnd":"2018-09-08","discountInfo":{"startDate":"2018-08-28","endDate":"2018-09-27","promoCode":null},"glCode":"4310","newLicense":true,"properties":{}},{"lineNo":"3","parentLineNo":null,"licenseId":null,"billingCodeId":null,"licenseExternalId":null,"itemGroupId":1832596001,"categoryId":"Remote Software","description":"NY Sales Tax","combinedCatalogId":null,"billingCycleDuration":0,"numberOfUnits":0,"pricePerUnit":null,"amount":6.35,"recurring":false,"itemType":"Tax Charge","dateRangeStart":"2018-08-28","dateRangeEnd":"2018-08-28","discountInfo":null,"glCode":null,"newLicense":false,"properties":{"categoryType":"Service","taxLevel":"Local","country":"USA","rate":"0.04","city":null,"effectiveRate":"0.04002","county":null,"avalaraTaxTypeId":"313","taxRateType":"Percent","state":"NY","taxItemId":"1018433001"}},{"lineNo":"4","parentLineNo":null,"licenseId":null,"billingCodeId":null,"licenseExternalId":null,"itemGroupId":1832596001,"categoryId":"Remote Software","description":"NY Sales Tax","combinedCatalogId":null,"billingCycleDuration":0,"numberOfUnits":0,"pricePerUnit":null,"amount":6.35,"recurring":false,"itemType":"Tax Charge","dateRangeStart":"2018-08-28","dateRangeEnd":"2018-08-28","discountInfo":null,"glCode":null,"newLicense":false,"properties":{"categoryType":"Service","taxLevel":"State","country":"USA","rate":"0.04","city":null,"effectiveRate":"0.04002","county":null,"avalaraTaxTypeId":"313","taxRateType":"Percent","state":"NY","taxItemId":"1018434001"}}],"controlSum":"171.38","preTaxAmount":158.68,"totalAmount":171.38,"paidAmount":0,"freeServiceCredit":{"providedCredit":0,"appliedCredit":0},"billingCodesData":{},"recurring":false}';
    private static final String CORRECT_CALCULATE_REFUNDS_INVOICE_JSON = '{"applicationMap":{"applications":{"462266001":{"1832596001":104.52,"1832597001":54.16}},"taxes":{"462266001":{"1832596001":[{"taxItemId":1018433001,"description":"NY Sales Tax","amount":4.18},{"taxItemId":1018434001,"description":"NY Sales Tax","amount":4.18}],"1832597001":[]}}},"maxAmount":171.38}';
    private static final String INCORRECT_POST_REFUNDS_JSON = '{"refund":{"transactions":[{"billingTransactionID":"1231443","Status":"false","message":"Internal error occurred [UserId could not be acquired from UserRequest: mandatory userId field is NULL]"}]}}';
    private static final String CORRECT_BILL_ID = '123';
    private static final String CORRECT_INVOICE_ID = '789';
    private static final String CORRECT_ACCOUNT_BILLING_ID = '456';

    private static final String CORRECT_TALEND_JSON = '{"Body":{"SFDCResponse":{"UserId":"400129611008","StartDate":"01-20-2017","EndDate":"01-31-2018","Transactions":[{"TransactionID":"RB1:C:400059120008","TransactionDate":"28-Dec-2017","TransactionType":"Charge","TransactionStatus":"Paid","PaySystem":"MeS RC-US","PaymentType":"Visa","ProductItems":[{"ProductID":"2235109","ProductDescription":"Office Standard 2 lines","TransactionAmount":"314.91"},{"ProductID":"9000013","ProductDescription":"Office Standard 2 lines","TransactionAmount":"25.91"}]},{"TransactionID":"RB1:C:400071024008","TransactionDate":"28-Jan-2018","TransactionType":"Charge","TransactionStatus":"Paid","PaySystem":"MeS RC-US","PaymentType":"Visa","ProductItems":[{"ProductID":"2235109","ProductDescription":"Office Standard 2 lines","TransactionAmount":"314.91"}]}]}}}';
    private static final String CORRECT_TRANSACTION_PAGES_INFO = '{"body": {"sfdcResponse": {"userId": "400151499008","transactionId": "400036433008","transactionType": "RC","SessionID":"12345","SessionPageCount":"1"}}}';
    @TestSetup
    static void createData() {
        upsert new Refunds_Settings__c(
                Refunds_Service_Endpoint__c = 'https://testapi/'
        );

        upsert new NGBS_Settings__c(
            BaseEndpoint__c = 'https://testapi/',
            Login__c = 'testLogin',
            Password__c = 'test password'
        );

        upsert new Feature_Toggle__c(
            NGBS_PSR__c = true
        );

        Refund_Categories__c category = new Refund_Categories__c(
                Name = 'Account Closed',
                Category_Id__c = 1,
                Category_Name__c = 'Account Closed'
        );
        insert category;

        RefundCategoryAndTypeMapping__c categoryTypeMapping = new RefundCategoryAndTypeMapping__c(
                Name = '85',
                Refund_Category_Id__c = 1,
                Refund_Type_Id__c = 85,
                Refund_Type_Name__c = 'Other'
        );
        insert categoryTypeMapping;
        Triggers.switchOff();
        Account testAccount = new Account(
                Name = ACCOUNT_IDENTIFIER,
                RC_User_ID__c = '12345',
                Billing_ID__c = '67890'
        );
        insert testAccount;

        Opportunity testOpportunity = new Opportunity(
                Name = 'Test Opportunity',
                StageName = '1. Qualify',
                CloseDate = System.today(),
                AccountId = testAccount.Id
        );
        insert testOpportunity;

        Quote testActiveSalesAgreement = new Quote(
                Name = 'Test Quote',
                OpportunityId = testOpportunity.Id,
                Start_Date__c = System.today(),
                End_Date__c = System.today(),
                Initial_Term_months__c = '24',
                Term_months__c = '24',
                QuoteType__c = QuoteHelper.QUOTE_TYPE_AGREEMENT,
                Status = QuoteHelper.QUOTE_STATUS_ACTIVE
        );
        insert testActiveSalesAgreement;

        Approval__c testApproval = new Approval__c(
                Status__c = APPROVAL_IDENTIFIER,
                RecordTypeId = ApprovalHelper.RT_ID_REFUND_APPROVAL,
                Account__c = testAccount.Id,
                CurrencyIsoCode = 'USD',
                Category__c = 'Account Closed',
                Refund_Type__c = 'Other'
        );
        insert testApproval;

        Triggers.switchOn();
    }

    @isTest
    static void testGetApproval() {

        Test.startTest();

        Id approvalId = [SELECT Id FROM Approval__c WHERE Status__c = :APPROVAL_IDENTIFIER].Id;
        Response response = RefundManagementController.getApprovalInfo(ApprovalId);

        Test.stopTest();

        System.assertNotEquals(null, response);
    }

    @isTest
    static void testGetTalendTransactions() {
        Id accountId = [SELECT Id FROM Account WHERE Name = :ACCOUNT_IDENTIFIER].Id;
        Id approvalId = [SELECT Id FROM Approval__c WHERE Status__c = :APPROVAL_IDENTIFIER].Id;
        String startDate = String.valueOf(System.today() - 30);
        String endDate = String.valueOf(System.today());

        Test.startTest();

        Test.setMock(HttpCalloutMock.class, new Mock());
        TransactionsRefundsAPI.SFDCResponseDTO result = RefundManagementController.getTalendTransactions(accountId, approvalId, TransactionsRefundsAPI.TRANSACTION_TYPE_RC, startDate, endDate);

        Test.stopTest();

        System.assertNotEquals(null, result);
    }

    @isTest
    static void testGetTalendTransactionsException() {
        Id approvalId = [SELECT Id FROM Approval__c WHERE Status__c = :APPROVAL_IDENTIFIER].Id;
        String startDate = String.valueOf(System.today() - 30);
        String endDate = String.valueOf(System.today());

        Test.startTest();

        Test.setMock(HttpCalloutMock.class, new Mock());
        TransactionsRefundsAPI.SFDCResponseDTO result;
        try {
             result = RefundManagementController.getTalendTransactions(null, approvalId, TransactionsRefundsAPI.TRANSACTION_TYPE_NON_RC, startDate, endDate);
            System.assert(false, 'Code should never reach here because the start date passed to the method is incorrect');
        } catch (Exception e) {
            //Code should always go here.
        }

        Test.stopTest();
        System.assertEquals(null, result, 'not null response was returned');
    }

    @isTest
    static void testPostRefunds() {
        Id approvalId = [SELECT Id FROM Approval__c WHERE Status__c = :APPROVAL_IDENTIFIER].Id;

//        TransactionsRefundsAPI.mockJsonResponce = '{"refund":{"transactions":[{"billingTransactionID":"1231443","Status":"false",' +
//                '"message":"Internal error occurred [UserId could not be acquired from UserRequest: mandatory userId field is NULL]"}]}}';
        Test.setMock(HttpCalloutMock.class, new Mock());

        Test.startTest();

        TransactionsRefundsAPI.RefundItem refundItem1 = new TransactionsRefundsAPI.RefundItem(
            '1234',
            10
        );
        TransactionsRefundsAPI.RefundItem refundItem2 = new TransactionsRefundsAPI.RefundItem(
            '12345',
            20
        );
        List<TransactionsRefundsAPI.RefundItem> refundItemList = new List<TransactionsRefundsAPI.RefundItem>{refundItem1, refundItem2};

        TransactionsRefundsAPI.PostRefundData postRefundData = new TransactionsRefundsAPI.PostRefundData(
            'exampleTransactionId',
            refundItemList,
            TransactionsRefundsAPI.TRANSACTION_TYPE_RC
        );

        TransactionsRefundsAPI.PostRefundsResponseWrapper result = RefundManagementController.postRefundsWrapper(
                JSON.serialize(new List<TransactionsRefundsAPI.PostRefundData>{postRefundData}),
                approvalId,
                '1234',
                TransactionsRefundsAPI.TRANSACTION_TYPE_RC
        );
        System.assertNotEquals(null, result);
        Test.stopTest();
    }

    @isTest
    static void testGetTalendTransactionHistory() {
        Id approvalId = [SELECT Id FROM Approval__c WHERE Status__c = :APPROVAL_IDENTIFIER].Id;
        insert new Transaction_History__c(Approval__c = approvalId);

        List <Transaction_History__c> approvalResult = RefundManagementController.getTalendTransactionHistory(ApprovalId);

        System.assertEquals(1, approvalResult.size());
    }

    @isTest
    static void testGetBillingTransactionHistory() {

        Test.startTest();

        String accountBillingId = [SELECT Id, Billing_ID__c FROM Account WHERE Name = :ACCOUNT_IDENTIFIER].Billing_ID__c;
        Date startDate = Date.newInstance(2018, 01, 21);
        Date endDate = startDate.addYears(1);
        String startDateStr = String.valueOf(startDate);
        String endDateStr = String.valueOf(endDate);

        Test.setMock(HttpCalloutMock.class, new Mock());

        List<TransactionsRefundsAPI.TransactionsDTO> transactions =
                RefundManagementController.getNGBSTransactions(accountBillingId, startDateStr, endDateStr);

        Test.stopTest();

        System.assertEquals(1, transactions.size(),
                'Number of transactions should be 1, because there is only 1 transaction in JSON');
    }

    @isTest
    static void testGetBillingTransactionHistoryException() {
        Date startDate = Date.newInstance(2018, 01, 21);
        Date endDate = startDate.addYears(1);
        String startDateStr = String.valueOf(startDate);
        String endDateStr = String.valueOf(endDate);

        Test.setMock(HttpCalloutMock.class, new Mock());

        Test.startTest();

        List<TransactionsRefundsAPI.TransactionsDTO> transactions;
        try {
            transactions = RefundManagementController.getNGBSTransactions(null, startDateStr, endDateStr);
            System.assert(false, 'the code should never reach here because start date is incorrect');
        } catch (Exception e) {}
        System.assertEquals(transactions, null,
                'response should be null, because of exception');

        Test.stopTest();
    }

    @isTest
    static void testGetNGBSProductItems() {
        Test.setMock(HttpCalloutMock.class, new Mock());
        Test.startTest();
            RefundManagementController.NGBSTProductDetailsResponseWrapper responseBill =
                RefundManagementController.getNGBSProductItems(
                    CORRECT_ACCOUNT_BILLING_ID,
                    CORRECT_BILL_ID,
                    TransactionsRefundsAPI.TRANSACTION_NGBS_TYPE_BILL
                );

            System.assertEquals(
                2,
                responseBill.productItems.size(),
                'Expect to get 1 bill product items - Meetings and Subscription. ' +
                'Tax should be in subitems. Subscription removed because its amount 0'
            );
            System.assertEquals(
                2,
                responseBill.productItems[0].items.size(),
                'Expect to get 2 items - Meetings and tax under Meetings item.'
            );
            System.assertEquals(
                10,
                responseBill.productItems[0].items[0].maxRefundAmount,
                'Max refund for Meetings should be 10, because it\'s 10 in CORRECT_CALCULATE_REFUNDS_BILL_JSON'
            );
            System.assertEquals(
                0.64,
                responseBill.productItems[0].items[1].maxRefundAmount,
                'Max refund for Tax should be 0.64, because it\'s 0.64 in CORRECT_CALCULATE_REFUNDS_BILL_JSON'
            );

            RefundManagementController.NGBSTProductDetailsResponseWrapper responseInvoice =
                RefundManagementController.getNGBSProductItems(
                    CORRECT_ACCOUNT_BILLING_ID,
                    CORRECT_INVOICE_ID,
                    TransactionsRefundsAPI.TRANSACTION_NGBS_TYPE_INVOICE
                );

            System.assertEquals(
                2,
                responseInvoice.productItems.size(),
                'Expect to get 2 Invoice product items - Large Meetings and RingCentral Webinar 100. ' +
                'Other items should be skipped because of negative values and tax should be under items.'
            );
            System.assertEquals(
                3,
                responseInvoice.productItems[0].items.size(),
                'Expect to get 3 items - Large Meetings and 2 NY Sales Tax.'
            );
            System.assertEquals(
                104.52,
                responseInvoice.productItems[0].items[0].maxRefundAmount,
                'Max refund for Large Meetings should be 104.52, ' +
                'because it\'s 104.52 in CORRECT_CALCULATE_REFUNDS_INVOICE_JSON'
            );
            System.assertEquals(
                4.18,
                responseInvoice.productItems[0].items[1].maxRefundAmount,
                'Max refund for Large Meetings should be 4.18, ' +
                'because it\'s 4.18 in CORRECT_CALCULATE_REFUNDS_INVOICE_JSON'
            );
            System.assertEquals(
                4.18,
                responseInvoice.productItems[0].items[2].maxRefundAmount,
                'Max refund for Large Meetings should be 4.18, ' +
                'because it\'s 4.18 in CORRECT_CALCULATE_REFUNDS_INVOICE_JSON'
            );
            System.assertEquals(
                1,
                responseInvoice.productItems[1].items.size(),
                'Expect to get 3 items - RingCentral Webinar 100 and 2 NY Sales Tax.'
            );
            System.assertEquals(
                54.16,
                responseInvoice.productItems[1].items[0].maxRefundAmount,
                'Max refund for Large Meetings should be 54.16, ' +
                'because it\'s 54.16 in CORRECT_CALCULATE_REFUNDS_INVOICE_JSON'
            );

            try {
                RefundManagementController.NGBSTProductDetailsResponseWrapper responseException =
                    RefundManagementController.getNGBSProductItems(CORRECT_ACCOUNT_BILLING_ID, 'something', 'unexpectedTransactionType');
                System.assert(false, 'Code should never reach here, because of unexpected transaction type');
            } catch (Exception e) {
                //code should always reach here.
                System.assert(
                e.getMessage().contains('Unexpected transaction type received'),
                'Id passed ngbsType != "bill" and passed ngbsType != "pendingInvoice" exception shoudl be thrown'
                );
            }
        Test.stopTest();
    }

    @isTest
    static void testValidateDates() {
        Date startDate = Date.newInstance(2018, 01, 21);
        Date endDate = startDate.addYears(1);
        String startDateStr = String.valueOf(startDate);
        String endDateStr = String.valueOf(endDate);
        //start date incorrect
        try {
            RefundManagementController.validateDates(startDateStr + '12312', endDateStr);
            System.assert(false, 'Code should never reach here because of incorrect start date');
        } catch (Exception e) {}

        try {
            RefundManagementController.validateDates(startDateStr, endDateStr + '123123');
            System.assert(false, 'Code should never reach here because of incorrect end date');
        } catch (Exception e) {}

        Date endDateLessThanStartDate = startDate.addDays(-1);
        String endDateLessThanStartDateStr = String.valueOf(endDateLessThanStartDate);
        try {
            RefundManagementController.validateDates(startDateStr, endDateLessThanStartDateStr);
            System.assert(false, 'Code should never reach here because end date is less than start date');
        } catch (Exception e) {}

        RefundManagementController.validateDates(startDateStr, endDateStr);
    }

    @isTest
    static void testApplyBillingRefund() {
        Test.setMock(HttpCalloutMock.class, new Mock());

        Test.startTest();

        Approval__c approval = [select id from Approval__c limit 1];
        String postJson = '{"id":1,"itemGroups":[{"id":"10","invoiceId":"101","items":[{"id":"1001","type":"other","description":"test item 1","amount":10},{"id":"1002","type":"tax","description":"test item 2","amount":5}]},{"id":"20","invoiceId":"201","items":[{"id":"2001","type":"other","description":"test item 3","amount":20},{"id":"2002","type":"tax","description":"test item 4","amount":7}]}]}';

        Response res = RefundManagementController.applyBillingRefund('1', approval.id, postJson);

        Test.stopTest();

        Transaction_History__c[] trHistoryList = [select Id, RefundAmount__c, TransactionId__c, Type__c, Status__c from Transaction_History__c where Approval__c =: approval.id];

        System.assertEquals(Response.STATUS_SUCCESS, res.status);
        System.assertEquals(1, trHistoryList.size());

        System.assertEquals('1', trHistoryList[0].TransactionId__c);
        System.assertEquals(42, trHistoryList[0].RefundAmount__c);
        System.assertEquals('NGBS', trHistoryList[0].Type__c);
        System.assertEquals('success', trHistoryList[0].Status__c);
    }

    @isTest
    static void testErrorApplyBillingRefund() {
        Test.setMock(HttpCalloutMock.class, new ErrorMock());

        Test.startTest();

        Approval__c approval = [select id from Approval__c limit 1];
        String postJson = '{"id":1,"itemGroups":[{"id":"10","invoiceId":"101","items":[{"id":"1001","type":"other","description":"test item 1","amount":10},{"id":"1002","type":"tax","description":"test item 2","amount":5}]},{"id":"20","invoiceId":"201","items":[{"id":"2001","type":"other","description":"test item 3","amount":20},{"id":"2002","type":"tax","description":"test item 4","amount":7}]}]}';
        Response res = RefundManagementController.applyBillingRefund('1', approval.id, postJson);

        Transaction_History__c[] trHistoryList = [select Id, RefundAmount__c, TransactionId__c, Type__c, Status__c from Transaction_History__c where Approval__c =: approval.id];

        Test.stopTest();

        System.assertEquals(Response.STATUS_ERROR, res.status);
        System.assertEquals(0, trHistoryList.size());
    }

    @isTest
    static void testApplyInvoiceAdjustment() {
        Test.setMock(HttpCalloutMock.class, new Mock());

        Test.startTest();

        Approval__c approval = [select id from Approval__c limit 1];
        String postJson = '{"id":1,"itemGroups":[{"id":"10","invoiceId":"101","items":[{"id":"1001","type":"other","description":"test item 1","amount":10},{"id":"1002","type":"tax","description":"test item 2","amount":5}]},{"id":"20","invoiceId":"201","items":[{"id":"2001","type":"other","description":"test item 3","amount":20},{"id":"2002","type":"tax","description":"test item 4","amount":7}]}]}';


        Response res = RefundManagementController.applyInvoiceAdjustment('1', approval.id, postJson);

        Transaction_History__c[] trHistoryList = [select Id, RefundAmount__c, TransactionId__c, Type__c, Status__c from Transaction_History__c where Approval__c =: approval.id];

        Test.stopTest();

        System.assertEquals(Response.STATUS_SUCCESS, res.status);
        System.assertEquals(1, trHistoryList.size());

        System.assertEquals('1', trHistoryList[0].TransactionId__c);
        System.assertEquals(42, trHistoryList[0].RefundAmount__c);
        System.assertEquals('NGBS', trHistoryList[0].Type__c);
        System.assertEquals('success', trHistoryList[0].Status__c);
    }

    @isTest
    static void testErrorApplyInvoiceAdjustment() {
        Test.setMock(HttpCalloutMock.class, new ErrorMock());

        Test.startTest();

        Approval__c approval = [select id from Approval__c limit 1];
        String postJson = '{"id":1,"itemGroups":[{"id":"10","invoiceId":"101","items":[{"id":"1001","type":"other","description":"test item 1","amount":10},{"id":"1002","type":"tax","description":"test item 2","amount":5}]},{"id":"20","invoiceId":"201","items":[{"id":"2001","type":"other","description":"test item 3","amount":20},{"id":"2002","type":"tax","description":"test item 4","amount":7}]}]}';

        Response res = RefundManagementController.applyInvoiceAdjustment('1', approval.id, postJson);

        Transaction_History__c[] trHistoryList = [select Id, RefundAmount__c, TransactionId__c, Type__c, Status__c from Transaction_History__c where Approval__c =: approval.id];

        Test.stopTest();

        System.assertEquals(Response.STATUS_ERROR, res.status);
        System.assertEquals(0, trHistoryList.size());
    }

    @isTest
    static void testIsReadOnlyRefundPage() {
        Id approvalId = [SELECT Id FROM Approval__c WHERE Status__c = :APPROVAL_IDENTIFIER].Id;
        // Feature toggle disabled, read only functionality is hidden
        Response respToggleOff = RefundManagementController.getApprovalInfo(approvalId);
        System.assertEquals(false, respToggleOff.data.get('isReadOnly'));
        Feature_toggle__c featureToggle = Feature_Toggle__c.getInstance();
        featureToggle.Refund_Management_Read_Only__c = true;
        upsert featureToggle;
        // Feature toggle enabled, read only functionality is in action
        Response respToggleOn = RefundManagementController.getApprovalInfo(approvalId);
        System.assertEquals(true, respToggleOn.data.get('isReadOnly'));
    }

    @isTest
    static void testGetTalendTransactionsPageInfo() {
        Approval__c approvalRecord = (Approval__c) new ApprovalSelector().selectApprovals()
            .selectFields(new List<String>{'Id'})
            .setCondition('Status__c = ' + '\'' + APPROVAL_IDENTIFIER + '\'')
            .executeQuery()
            .get(0);
        Test.setMock(HttpCalloutMock.class, new Mock());

        Test.startTest();
            TransactionsRefundsAPI.TransactionInfoResponse getTRansactionPagesInfoResult =
                RefundManagementController.getTransactionPagesInfo('userId', approvalRecord.Id, 'transactionId',
                TransactionsRefundsApi.TRANSACTION_TYPE_RC);
        Test.stopTest();
        System.assertEquals('12345', getTRansactionPagesInfoResult.sessionId,'Transaction session Id doesn\'t match');
        System.assertEquals('1', getTRansactionPagesInfoResult.SessionPageCount, 'Details have incorrect pages amount');
    }

    @isTest
    static void testGetTalendTransactionDetails() {
        Id approvalId = [SELECT Id FROM Approval__c WHERE Status__c = :APPROVAL_IDENTIFIER].Id;
        Test.setMock(HttpCalloutMock.class, new MockWithTransactionDetails());
        Test.startTest();
            TransactionsRefundsAPI.SFDCResponseDTO getTransactionDetailsResult =
                RefundManagementController.getTransactionDetails('userId_1234', 'transactionId_1234', approvalId,
                'type','sessionId', 'sessionPage');
        Test.stopTest();
        System.assertEquals('12345', getTransactionDetailsResult.sessionId);
        System.assertEquals('2', getTransactionDetailsResult.sessionPageId);
    }

     /* Used to mock transaction details response*/
    private class MockWithTransactionDetails implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();
            res.setStatus('OK');
            res.setBody('{"body": {"sfdcResponse": {"userId": "400149525008","startDate": "6-18-2018","endDate":' +
            '"7-18-2018","sessionId":"12345","sessionPageId":"2","transactions": [{"transactionId": "400023038008"' +
            ',"transactionDate": "06-26-2018","transactionStatus": "Refunded","refundTransactionDate": "2018-06-2' +
             '19:44:46.0 GMT","paySystem": "MeS RC-US","refundedAmount": "300","productItems": [{"productId":' +
             '"400453434008","productDescription": "Subscription Fee - Annual (RingCentral Office Standard 2 lines)"' +
             ',"transactionAmount": "599.76","currency": "USD","transactionType": "Upgrade","items": [{"productId":' +
             '"400453435008","productDescription": "Federal Universal Service Fund","transactionAmount": "44.86"' +
             ',"transactionType": "Upgrade","itemDetails": [{"productId": "400453435008","productDescription": "Feder' +
             'al Universal Service Fund","transactionAmount": "44.86","transactionType": "Upgrade"}]},{"productId":' +
             '"400453436008","productDescription": "State and local taxes and fees","transactionAmount": ".74"' +
             ',"transactionType": "Upgrade","itemDetails": [{"productId": "400453436008","productDescription": "Stat' +
             'e and local taxes and fees","transactionAmount": ".74","transactionType": "Upgrade"}]},{"productId":' +
             '"400453437008","productDescription": "State and local taxes and fees","transactionAmount": "2.27"' +
             ',"transactionType": "Upgrade","itemDetails": [{"productId": "400453437008","productDescription": "Stat' +
             'e and local taxes and fees","transactionAmount": "2.27","transactionType": "Upgrade"}]},{"productId":' +
             '"400453438008","productDescription": "State and local taxes and fees","transactionAmount": "1.58"' +
             ',"transactionType": "Upgrade","itemDetails": [{"productId": "400453438008","productDescription": "Stat' +
             'e and local taxes and fees","transactionAmount": "1.58","transactionType": "Upgrade"}]},{"productId":' +
              '"400453439008","productDescription": "State and local taxes and fees","transactionAmount": "1.05"' +
              ',"transactionType": "Upgrade","itemDetails": [{"productId": "400453439008","productDescription": "Stat' +
              'e and local taxes and fees","transactionAmount": "1.05","transactionType": "Upgrade"}]},{"productId"' +
              ': "400453440008","productDescription": "State and local taxes and fees","transactionAmount": "10"' +
              ',"transactionType": "Upgrade","itemDetails": [{"productId": "400453440008","productDescription": "Stat' +
              'e and local taxes and fees","transactionAmount": "10","transactionType": "Upgrade"}]},{"productId"' +
              ': "400453441008","productDescription": "State and local taxes and fees","transactionAmount": "51.14"' +
              ',"transactionType": "Upgrade","itemDetails": [{"productId": "400453441008","productDescription": "Stat' +
              'e and local taxes and fees","transactionAmount": "51.14","transactionType": "Upgrade"}]}]}]}]}}}');
            res.setStatusCode(200);
            return res;
        }
    }

    private class Mock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();
            res.setStatus('OK');
            res.setStatusCode(200);

            String endpoint = req.getEndpoint();
            if (endpoint.endsWith('history')) {
                //NGBS transactions
                res.setBody(CORRECT_NGBS_TRANSACTION_JSON);
            } else if (endpoint.endsWith(CORRECT_BILL_ID)) {
                //bill details
                res.setBody(CORRECT_NGBS_BILL_JSON);
            } else if (endpoint.endsWith('/refund/calculate')) {
                //bill calculate refunds
                res.setBody(CORRECT_CALCULATE_REFUNDS_BILL_JSON);
            } else if (endpoint.endsWith('/refund/calculate?creditApplication=AutoDistribute')) {
                //bill calculate refunds
                res.setBody(CORRECT_CALCULATE_REFUNDS_BILL_JSON);
            } else if (endpoint.substring(0, endpoint.lastIndexOf('/')).endsWith('/purchase/invoice')) {
                //invoice detail
                res.setBody(CORRECT_NGBS_INVOICE_JSON);
            } else if (endpoint.endsWith('/invoice/adjustment/calculate')) {
                //invoice calculate refunds
                res.setBody(CORRECT_CALCULATE_REFUNDS_INVOICE_JSON);
            } else if (endpoint.endsWith('/invoice/adjustment/calculate?creditApplication=AutoDistribute')) {
                //invoice calculate refunds
                res.setBody(CORRECT_CALCULATE_REFUNDS_INVOICE_JSON);
            } else if (endpoint.endsWith('GetTransactions')) {
                //Talend transactions response
                res.setBody(CORRECT_TALEND_JSON);
            } else if (endpoint.endsWith('PostRefunds')) {
                //NGBS post refunds
                res.setBody(INCORRECT_POST_REFUNDS_JSON);
            } else if (endpoint.endsWith('/bill/1/refund/apply')) {
                //NGBS post refunds
                res.setBody('ok');
            } else if (endpoint.endsWith('invoice/adjustment/apply')) {
                res.setBody('ok');
            } else if (endpoint.endsWith('/GetTransactionDetails')) {
                //Talend transactions pages info
                res.setBody(CORRECT_TRANSACTION_PAGES_INFO);
            } else {
                //unexpected
                System.assert(false, 'unexpected endpoint ' + endpoint);
            }
            return res;
        }
    }
    private class ErrorMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();
            res.setStatus('BAD');
            res.setStatusCode(404);
            return res;
        }
    }
}