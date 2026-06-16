@isTest
private class Test_TransactionsRefundsAPI {
    private static final String UNEXPECTED_EXCEPTION_OCCURED = 'Unexpected exception occured ';
    private static final String CORRECT_NGBS_TRANSACTION_JSON = '{"bills":[{"id":3483600712345,"state":"Paid","recurring":true,"billingCycleNumber":5,"billDate":"2018-08-23T08:01:20.620Z[UTC]","dueDate":"2018-08-23T00:00Z[UTC]","previousBalance":0,"newBalance":12004.28,"appliedCredit":19.23,"remainingCredit":0,"invoices":[{"id":34408007,"packageId":2548007,"type":"Invoice","state":"Paid","created":"2018-08-22T17:10:37.263Z[UTC]","recurring":false,"billingCycleNumber":5,"currency":"USD","preTaxAmount":3632.84,"totalAmount":3859.89,"paidAmount":3859.89,"freeServiceCredit":{"providedCredit":0,"appliedCredit":0}},{"id":20604007,"packageId":2548007,"type":"Invoice","state":"Paid","created":"2018-07-23T16:54:18.847Z[UTC]","recurring":true,"billingCycleNumber":5,"currency":"USD","preTaxAmount":0,"totalAmount":0,"paidAmount":0,"freeServiceCredit":{"providedCredit":0,"appliedCredit":0}}],"payments":[{"id":34790007,"created":"2018-08-23T08:01:20.727Z[UTC]","amount":12004.28,"successful":true,"paymentMethod":{"methodId":1597007,"methodType":"Invoice","nickname":null,"address":{"firstName":"ivan","lastName":"tultsev","phone":null,"street1":" 66 Beacon St","street2":null,"city":"boston","county":null,"state":"MA","zip":"02108","country":"USA"},"info":{"terms":0}}}]}]}';
    private static final String CORRECT_NGBS_BILL_JSON = '{"bill":{"id":20404007,"accountId":2548007,"recurring":true,"state":"Paid","dueDate":"2018-07-23","billDate":"2018-07-23T08:01:51.177Z[UTC]","previousBalance":0,"newBalance":15.93,"appliedCredit":0,"remainingCredit":0,"invoices":[{"id":20432007,"billingAddress":{"firstName":"ivan","lastName":"tultsev","phone":"","street1":" 66 Beacon St","street2":null,"city":"boston","county":null,"state":"MA","zip":"02108","country":"USA"},"date":"2018-07-23T08:01:49.657Z[UTC]","timezone":"America/Los_Angeles","currency":"USD","type":"Invoice","state":"Paid","items":[{"lineNo":"1","parentLineNo":null,"licenseId":4583007,"billingCodeId":null,"licenseExternalId":null,"itemGroupId":40353007,"categoryId":"SC","description":"Subscription","combinedCatalogId":"P:7.1,L:LC_SC_404","billingCycleDuration":1,"numberOfUnits":1,"pricePerUnit":0,"amount":0,"recurring":true,"itemType":"FeatureCharge","dateRangeStart":"2018-07-23","dateRangeEnd":"2018-08-22","discountInfo":null,"glCode":"4005","newLicense":false,"properties":{"servicetype":"54","ZoomCallOut":"true"}},{"lineNo":"2","parentLineNo":null,"licenseId":4582007,"billingCodeId":null,"licenseExternalId":null,"itemGroupId":40352007,"categoryId":"SM","description":"Meetings","combinedCatalogId":"P:7.1,L:LC_SM_405","billingCycleDuration":1,"numberOfUnits":1,"pricePerUnit":14.99,"amount":14.99,"recurring":true,"itemType":"FeatureCharge","dateRangeStart":"2018-07-23","dateRangeEnd":"2018-08-22","discountInfo":null,"glCode":"4072","newLicense":false,"properties":{"LicenseTypeId":"1001","servicetype":"54","ExternalProvisioning":{"ZoomUserType":"Pro","ZoomFeature":"RCMeeting"},"LimitValues":[{"limitid":149,"amount":1000}],"int.raterQty":"1"}},{"lineNo":"3","parentLineNo":null,"licenseId":null,"billingCodeId":null,"licenseExternalId":null,"itemGroupId":40352007,"categoryId":"Remote Software","description":"Telecommunications Sales Tax","combinedCatalogId":null,"billingCycleDuration":0,"numberOfUnits":0,"pricePerUnit":null,"amount":0.94,"recurring":false,"itemType":"Tax Charge","dateRangeStart":"2018-07-23","dateRangeEnd":"2018-07-23","discountInfo":null,"glCode":null,"newLicense":false,"properties":{"categoryType":"Service","taxLevel":"State","country":"USA","rate":"0.0625","city":"BOSTON","effectiveRate":"0.06271","county":"SUFFOLK","avalaraTaxTypeId":"138","taxRateType":"Percent","state":"MA","taxItemId":"5456007"}}],"controlSum":"15.93","preTaxAmount":14.99,"totalAmount":15.93,"paidAmount":15.93,"freeServiceCredit":{"providedCredit":0,"appliedCredit":0},"billingCodesData":{"1000":{"path":[{"name":"RingCentral Inc.","code":null}],"addressId":755381001,"charges":0,"adjustments":0,"taxesAndFees":0,"total":0},"1010":{"path":[{"name":"RingCentral Inc.","code":null},{"name":"San Francisco","code":null}],"addressId":755383001,"charges":2699.88,"adjustments":-279.98,"taxesAndFees":384.98,"total":2804.88},"1020":{"path":[{"name":"RingCentral Inc.","code":null},{"name":"New York","code":null}],"addressId":755382001,"charges":599.76,"adjustments":-79.96,"taxesAndFees":301.3,"total":821.1},"1030":{"path":[{"name":"RingCentral Inc.","code":null},{"name":"San Francisco 2","code":null}],"addressId":755383001,"charges":899.64,"adjustments":-119.94,"taxesAndFees":482.15,"total":1261.85}},"recurring":true}]},"payments":[{"id":20364007,"status":true,"date":"2018-07-23T08:01:51.200Z[UTC]","amount":15.93,"paymentMethod":{"id":1597007,"nickname":null,"type":"Invoice","address":{"firstName":"ivan","lastName":"tultsev","phone":null,"street1":" 66 Beacon St","street2":null,"city":"boston","county":null,"state":"MA","zip":"02108","country":"USA"},"info":{"terms":0}},"providerProfile":null,"providerAuthCode":null}]}';
    private static final String CORRECT_CALCULATE_REFUNDS_BILL_JSON = '{"refundApplicationMap":{"applications":{"20432007":{"40352007":10,"40353007":0}},"taxes":{"20432007":{"40352007":[{"taxItemId":5456007,"description":"Telecommunications Sales Tax","amount":0.64}]}}},"maxAmount":120.63}';
    private static final String CORRECT_NGBS_INVOICE_JSON = '{"id":462266001,"billingAddress":{"firstName":"Vladislav","lastName":"Niyazov","phone":"Fake Phone","street1":"650 5th Ave","street2":null,"city":"New York","county":null,"state":"NY","zip":"10019","country":"USA"},"date":"2018-08-28T12:44:24.276Z[UTC]","timezone":"America/Los_Angeles","currency":"USD","type":"Invoice","state":"Pending","items":[{"lineNo":"1","parentLineNo":null,"licenseId":2536583001,"billingCodeId":null,"licenseExternalId":null,"itemGroupId":1832596001,"categoryId":"LM","description":"Large Meetings 200","combinedCatalogId":"P:7.1,L:LC_LM_406","billingCycleDuration":1,"numberOfUnits":3,"pricePerUnit":90,"amount":270,"recurring":true,"itemType":"FeatureCharge","dateRangeStart":"2018-08-09","dateRangeEnd":"2018-09-08","discountInfo":null,"glCode":"4310","newLicense":true,"properties":{"LicenseTypeId":"1002","ExternalProvisioning":"{\'ZoomFeature\':\'LargeMeeting\', \'capacity\': 200}"}},{"lineNo":"1.1","parentLineNo":"1","licenseId":2536583001,"billingCodeId":null,"licenseExternalId":null,"itemGroupId":1832596001,"categoryId":"LM","description":"Large Meetings 200","combinedCatalogId":"P:7.1,L:LC_LM_406","billingCycleDuration":1,"numberOfUnits":3,"pricePerUnit":-55.16,"amount":-165.48,"recurring":true,"itemType":"ProrationCredit","dateRangeStart":"2018-08-09","dateRangeEnd":"2018-08-27","discountInfo":null,"glCode":"4310","newLicense":true,"properties":{"LicenseTypeId":"1002","ExternalProvisioning":"{\'ZoomFeature\':\'LargeMeeting\', \'capacity\': 200}"}},{"lineNo":"2","parentLineNo":null,"licenseId":2536584001,"billingCodeId":null,"licenseExternalId":null,"itemGroupId":1832597001,"categoryId":"WB","description":"RingCentral Webinar 100","combinedCatalogId":"P:7.1,L:LC_WB_409","billingCycleDuration":1,"numberOfUnits":4,"pricePerUnit":40,"amount":160,"recurring":true,"itemType":"FeatureCharge","dateRangeStart":"2018-08-09","dateRangeEnd":"2018-09-08","discountInfo":null,"glCode":"4310","newLicense":true,"properties":{"LicenseTypeId":"1003","ExternalProvisioning":"{\'ZoomFeature\':\'Webinar\', \'capacity\': 100}"}},{"lineNo":"2.1","parentLineNo":"2","licenseId":2536584001,"billingCodeId":null,"licenseExternalId":null,"itemGroupId":1832597001,"categoryId":"WB","description":"RingCentral Webinar 100","combinedCatalogId":"P:7.1,L:LC_WB_409","billingCycleDuration":1,"numberOfUnits":4,"pricePerUnit":-24.52,"amount":-98.08,"recurring":true,"itemType":"ProrationCredit","dateRangeStart":"2018-08-09","dateRangeEnd":"2018-08-27","discountInfo":null,"glCode":"4310","newLicense":true,"properties":{"LicenseTypeId":"1003","ExternalProvisioning":"{\'ZoomFeature\':\'Webinar\', \'capacity\': 100}"}},{"lineNo":"2.2","parentLineNo":"2","licenseId":2536584001,"billingCodeId":null,"licenseExternalId":null,"itemGroupId":1832597001,"categoryId":"WB","description":"RingCentral Webinar 100 - Discount $5.00 off for 1 month (ends 09/27/2018)","combinedCatalogId":"P:7.1,L:LC_WB_409","billingCycleDuration":1,"numberOfUnits":4,"pricePerUnit":-1.94,"amount":-7.76,"recurring":true,"itemType":"ProratedDiscountCredit","dateRangeStart":"2018-08-28","dateRangeEnd":"2018-09-08","discountInfo":{"startDate":"2018-08-28","endDate":"2018-09-27","promoCode":null},"glCode":"4310","newLicense":true,"properties":{}},{"lineNo":"3","parentLineNo":null,"licenseId":null,"billingCodeId":null,"licenseExternalId":null,"itemGroupId":1832596001,"categoryId":"Remote Software","description":"NY Sales Tax","combinedCatalogId":null,"billingCycleDuration":0,"numberOfUnits":0,"pricePerUnit":null,"amount":6.35,"recurring":false,"itemType":"Tax Charge","dateRangeStart":"2018-08-28","dateRangeEnd":"2018-08-28","discountInfo":null,"glCode":null,"newLicense":false,"properties":{"categoryType":"Service","taxLevel":"Local","country":"USA","rate":"0.04","city":null,"effectiveRate":"0.04002","county":null,"avalaraTaxTypeId":"313","taxRateType":"Percent","state":"NY","taxItemId":"1018433001"}},{"lineNo":"4","parentLineNo":null,"licenseId":null,"billingCodeId":null,"licenseExternalId":null,"itemGroupId":1832596001,"categoryId":"Remote Software","description":"NY Sales Tax","combinedCatalogId":null,"billingCycleDuration":0,"numberOfUnits":0,"pricePerUnit":null,"amount":6.35,"recurring":false,"itemType":"Tax Charge","dateRangeStart":"2018-08-28","dateRangeEnd":"2018-08-28","discountInfo":null,"glCode":null,"newLicense":false,"properties":{"categoryType":"Service","taxLevel":"State","country":"USA","rate":"0.04","city":null,"effectiveRate":"0.04002","county":null,"avalaraTaxTypeId":"313","taxRateType":"Percent","state":"NY","taxItemId":"1018434001"}}],"controlSum":"171.38","preTaxAmount":158.68,"totalAmount":171.38,"paidAmount":0,"freeServiceCredit":{"providedCredit":0,"appliedCredit":0},"billingCodesData":{},"recurring":false}';
    private static final String CORRECT_CALCULATE_REFUNDS_INVOICE_JSON = '{"applicationMap":{"applications":{"462266001":{"1832596001":104.52,"1832597001":54.16}},"taxes":{"462266001":{"1832596001":[{"taxItemId":1018433001,"description":"NY Sales Tax","amount":4.18},{"taxItemId":1018434001,"description":"NY Sales Tax","amount":4.18}],"1832597001":[]}}},"maxAmount":171.38}';
    private static final String CORRECT_BILL_ID = '123';
    private static final String CORRECT_INVOICE_ID = '789';
    private static final String CORRECT_ACCOUNT_BILLING_ID = '456';

    private static final String CORRECT_TALEND_JSON = '{"Body":{"SFDCResponse":{"UserId":"400129611008","StartDate":"01-20-2017","EndDate":"01-31-2018","Transactions":[{"TransactionID":"RB1:C:400059120008","TransactionDate":"28-Dec-2017","TransactionType":"Charge","TransactionStatus":"Paid","PaySystem":"MeS RC-US","PaymentType":"Visa","ProductItems":[{"ProductID":"2235109","ProductDescription":"Office Standard 2 lines","TransactionAmount":"314.91"},{"ProductID":"9000013","ProductDescription":"Office Standard 2 lines","TransactionAmount":"25.91"}]},{"TransactionID":"RB1:C:400071024008","TransactionDate":"28-Jan-2018","TransactionType":"Charge","TransactionStatus":"Paid","PaySystem":"MeS RC-US","PaymentType":"Visa","ProductItems":[{"ProductID":"2235109","ProductDescription":"Office Standard 2 lines","TransactionAmount":"314.91"}]}]}}}';
    private static final String CORRECT_TRANSACTION_PAGES_INFO = '{"body": {"sfdcResponse": {"userId": "400151499008","transactionId": "400036433008","transactionType": "RC","SessionID":"12345","SessionPageCount":"1"}}}';

    @testSetup
    static void generateData() {
        upsert new Refunds_Settings__c(
            Refunds_Service_Endpoint__c = 'https://testapi/'
        );
        upsert new NGBS_Settings__c(
            BaseEndpoint__c = 'https://testapi/',
            AccountManagerPath__c = '/restapi/account-manager/v1.0',
            Login__c = '123',
            Password__c = '456'
        );
    }

    @isTest
    static void testCreateInstances() {

        TransactionsRefundsAPI trAPI = new TransactionsRefundsAPI();

        TransactionsRefundsAPI.GetTransactionDTO getTransactionDTOInstance = new TransactionsRefundsAPI.GetTransactionDTO(null, TransactionsRefundsAPI.TRANSACTION_TYPE_RC, system.today(), system.today());
        TransactionsRefundsAPI.SFDCRequestDTO sfdcRequestDTOInstance = new TransactionsRefundsAPI.SFDCRequestDTO(null);
        TransactionsRefundsAPI.ProductItemDTO productItemDTOInstance = new TransactionsRefundsAPI.ProductItemDTO(null, null, null, null, null, null, null);
        TransactionsRefundsAPI.TransactionsDTO transactionsDTOInstance = new TransactionsRefundsAPI.TransactionsDTO(null, null, null, null, null, null, null,null);

        TransactionsRefundsAPI.SFDCResponseDTO sfdcResponseDTOInstance = new TransactionsRefundsAPI.SFDCResponseDTO(null, null, null, null);
        TransactionsRefundsAPI.Response responseInstance = new TransactionsRefundsAPI.Response(null);
        TransactionsRefundsAPI.GetTransactionsResponseWrapper getTransactionsResponseWrapperInstance = new TransactionsRefundsAPI.GetTransactionsResponseWrapper(null);

        TransactionsRefundsAPI.RefundBillingItemDetail refundBillingItemDetailInstance = new TransactionsRefundsAPI.RefundBillingItemDetail(null, null, null, null, null, null, null, null, null, null, null, null);
        TransactionsRefundsAPI.TransactionDetailDTO transactionDetailDTOInstance = new TransactionsRefundsAPI.TransactionDetailDTO(null, null, null, null, null, null);
        TransactionsRefundsAPI.TransactionsDetailsDTO transactionDetailsDTOInstance = new TransactionsRefundsAPI.TransactionsDetailsDTO(null);
        TransactionsRefundsAPI.PostRefundsDTO postRefundsDTOInstance = new TransactionsRefundsAPI.PostRefundsDTO(null);
        TransactionsRefundsAPI.PostRefundsResponseItem postRefundsResponseItemInstance = new TransactionsRefundsAPI.PostRefundsResponseItem(null, null, null);
        TransactionsRefundsAPI.PostRefundsResponseWrapper postRefundsResponseWrapperInstance = new TransactionsRefundsAPI.PostRefundsResponseWrapper(null);
        TransactionsRefundsAPI.GetTransactionDetailsResponseWrapper getTransactionDetailsResponseWrapper = new TransactionsRefundsAPI.GetTransactionDetailsResponseWrapper(null);
        TransactionsRefundsAPI.GetTransactionInfoResponse getTransactionInfoResponseWrapper = new TransactionsRefundsAPI.GetTransactionInfoResponse(null);
        TransactionsRefundsAPI.GetTransactionInfoWrapper getTransactionInfoWrapper = new TransactionsRefundsAPI.GetTransactionInfoWrapper(null);
        TransactionsRefundsAPI.GetTransactionDetailsDTO getTransactionDetail = new TransactionsRefundsAPI.GetTransactionDetailsDTO(null, null, null, null, null);
        TransactionsRefundsAPI.SFDCTransactionDetailsRequestDTO transactionDetailsRequest = new TransactionsRefundsAPI.SFDCTransactionDetailsRequestDTO(null);

        try {
            TransactionsRefundsAPI.SFDCResponseDTO getTransactionsResult = TransactionsRefundsAPI.getTalendTransactions(null, null, null, null);
            // if exception not thrown during getTransactions process - we throw custom exception and compare messages in catch block
            throw new TransactionsRefundsAPI.CustomException('An exception should have been thrown');
        }catch(Exception ex) {
            Boolean expectedExceptionThrown = ex.getMessage().contains(TransactionsRefundsAPI.ACC_TALEND_TRANS_REQUIRED_FIELDS_IS_NULL_ERROR_MESSAGE);
            System.assertEquals(expectedExceptionThrown, true);
        }

        Map<String, Transaction_History__c> transactionHistoryMap;
        try {
            TransactionsRefundsAPI.PostRefundsResponseWrapper postRefundResult =
                                                        TransactionsRefundsAPI.postRefund(
                                                                null, transactionHistoryMap);
            // if exception not thrown during getTransactions process - we throw custom exception and compare messages in catch block
            throw new TransactionsRefundsAPI.CustomException('An exception should have been thrown');
        }catch(Exception ex) {
            Boolean expectedExceptionThrown = ex.getMessage().contains(TransactionsRefundsAPI.TRANSACTION_DTO_ARG_IS_NULL_ERROR_MESSAGE);
            System.assertEquals(expectedExceptionThrown, true);
        }

        String accUserId = null;
        try {
            TransactionsRefundsAPI.PostRefundsResponseWrapper postRefundResult = TransactionsRefundsAPI.postRefund(
                null,
                null,
                accUserId,
                TransactionsRefundsAPI.TRANSACTION_TYPE_RC
            );
            // if exception not thrown during getTransactions process - we throw custom exception and compare messages in catch block
            throw new TransactionsRefundsAPI.CustomException('An exception should have been thrown');
        }catch(Exception ex) {
            Boolean expectedExceptionThrown = ex.getMessage().contains(TransactionsRefundsAPI.ARGS_IS_NULL_ERROR_MESSAGE);
            System.assertEquals(expectedExceptionThrown, true);
        }

        System.assertEquals(null, TransactionsRefundsAPI.makeRequest(null, null, null));
        System.assertEquals(null, TransactionsRefundsAPI.makeRequest('', '', ''));

        System.assertEquals(null, TransactionsRefundsAPI.findCategoryIdByName(null));
        System.assertEquals(null, TransactionsRefundsAPI.findCategoryIdByName(''));

        System.assertEquals(null, TransactionsRefundsAPI.findRefundTypeId(null, null));
        System.assertEquals(null, TransactionsRefundsAPI.findRefundTypeId(null, ''));
    }

    @isTest
    static void testGetTransactions() {

        Test.setMock(HttpCalloutMock.class, new Mock());

        Test.startTest();
            TransactionsRefundsAPI.SFDCResponseDTO getTransactionsResult = TransactionsRefundsAPI.getTalendTransactions('some_user_id', TransactionsRefundsAPI.TRANSACTION_TYPE_RC, Date.today(), Date.today().addDays(2));
        Test.stopTest();

        System.assertNotEquals(null, getTransactionsResult);
    }

    @isTest
    static void testGetTransactionsWithoutEndpointShouldThrowError() {
        delete [SELECT Id FROM Refunds_Settings__c];
        delete [SELECT Id FROM NGBS_Settings__c];
        Test.setMock(HttpCalloutMock.class, new Mock());

        Test.startTest();

            try {
                TransactionsRefundsAPI.SFDCResponseDTO getTransactionsResult = TransactionsRefundsAPI.getTalendTransactions('some_user_id', TransactionsRefundsAPI.TRANSACTION_TYPE_NON_RC, Date.today(), Date.today().addDays(2));
                // if exception not thrown during getTransactions process - we throw custom exception and compare messages in catch block
                throw new TransactionsRefundsAPI.CustomException('An exception should have been thrown');
            }catch(Exception ex) {
                Boolean expectedExceptionThrown = ex.getMessage().contains(TransactionsRefundsAPI.ENDPOINT_TALEND_NOT_FOUND_ERROR_MESSAGE);
                System.assertEquals(expectedExceptionThrown, true);
            }

        Test.stopTest();
    }

    @isTest
    static void testPostRefund() {

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

        Approval__c app = new Approval__c(
            Category__c = 'Account Closed',
            Refund_Type__c = 'Other'
        );
        insert app;

        Test.setMock(HttpCalloutMock.class, new MockWithIncorrectResponse());

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

            TransactionsRefundsAPI.PostRefundsResponseWrapper postRefundResult = TransactionsRefundsAPI.postRefund(
                new List<TransactionsRefundsAPI.PostRefundData>{postRefundData},
                app.Id,
                null,
                TransactionsRefundsAPI.TRANSACTION_TYPE_RC
            );

            System.assertNotEquals(null, postRefundResult);
        Test.stopTest();
    }

    @isTest
    static void testPostRefundForApprovalWithEmptyCategoryShouldThrowError() {

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

        Approval__c app = new Approval__c(
            Category__c = null,
            Refund_Type__c = 'Other'
        );
        insert app;

        Test.setMock(HttpCalloutMock.class, new MockWithIncorrectResponse());

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
                TransactionsRefundsAPI.TRANSACTION_TYPE_NON_RC
            );

            try {
                TransactionsRefundsAPI.PostRefundsResponseWrapper postRefundResult = TransactionsRefundsAPI.postRefund(
                    new List<TransactionsRefundsAPI.PostRefundData>{postRefundData},
                    app.Id,
                    null,
                    TransactionsRefundsAPI.TRANSACTION_TYPE_RC
                );
                // if exception not thrown during getTransactions process - we throw custom exception and compare messages in catch block
                throw new TransactionsRefundsAPI.CustomException('An exception should have been thrown');
            }catch(Exception ex) {
                Boolean expectedExceptionThrown = ex.getMessage().contains(TransactionsRefundsAPI.CATEGORY_FIELD_IS_EMPTY_ERROR_MESSAGE);
                System.assertEquals(expectedExceptionThrown, true);
            }
        Test.stopTest();
    }

    @isTest
    static void testPostRefundForApprovalWithEmptyRefundTypeShouldThrowError() {

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

        Approval__c app = new Approval__c(
            Category__c = 'Account Closed',
            Refund_Type__c = null
        );
        insert app;

        Test.setMock(HttpCalloutMock.class, new MockWithIncorrectResponse());

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

            try {
                TransactionsRefundsAPI.PostRefundsResponseWrapper postRefundResult = TransactionsRefundsAPI.postRefund(
                    new List<TransactionsRefundsAPI.PostRefundData>{postRefundData},
                    app.Id,
                    null,
                    TransactionsRefundsAPI.TRANSACTION_TYPE_RC
                );
                // if exception not thrown during getTransactions process - we throw custom exception and compare messages in catch block
                throw new TransactionsRefundsAPI.CustomException('An exception should have been thrown');
            }catch(Exception ex) {
                Boolean expectedExceptionThrown = ex.getMessage().contains(TransactionsRefundsAPI.REFUNDTYPE_FIELD_IS_EMPTY_ERROR_MESSAGE);
                System.assertEquals(expectedExceptionThrown, true);
            }
        Test.stopTest();
    }

    @isTest
    static void testPostRefundWithoutEndpointShouldThrowError() {
        delete [SELECT Id FROM Refunds_Settings__c];
        delete [SELECT Id FROM NGBS_Settings__c];

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

        Test.setMock(HttpCalloutMock.class, new MockWithIncorrectResponse());

        Test.startTest();

            Approval__c app = new Approval__c(
                Category__c = 'Account Closed',
                Refund_Type__c = 'Other'
            );
            insert app;


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
                TransactionsRefundsAPI.TRANSACTION_TYPE_NON_RC
            );

            try {
                TransactionsRefundsAPI.PostRefundsResponseWrapper postRefundResult = TransactionsRefundsAPI.postRefund(
                    new List<TransactionsRefundsAPI.PostRefundData>{postRefundData},
                    app.Id,
                    null,
                    TransactionsRefundsAPI.TRANSACTION_TYPE_RC
                );
                // if exception not thrown during getTransactions process - we throw custom exception and compare messages in catch block
                throw new TransactionsRefundsAPI.CustomException('An exception should have been thrown');
            }catch(Exception ex) {
                Boolean expectedExceptionThrown = ex.getMessage().contains(TransactionsRefundsAPI.ENDPOINT_TALEND_NOT_FOUND_ERROR_MESSAGE);
                System.assertEquals(expectedExceptionThrown, true);
            }

        Test.stopTest();
    }

    @isTest
    static void testPostRefundForDeletedApprovalShouldThrowError() {
        Approval__c app = new Approval__c();
        insert app;

        Id testApprovalId = app.Id;

        delete app;

        Test.setMock(HttpCalloutMock.class, new MockWithIncorrectResponse());

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

            try {
                TransactionsRefundsAPI.PostRefundsResponseWrapper postRefundResult = TransactionsRefundsAPI.postRefund(
                    new List<TransactionsRefundsAPI.PostRefundData>{postRefundData},
                    testApprovalId,
                    null,
                    TransactionsRefundsAPI.TRANSACTION_TYPE_RC
                );
                // if exception not thrown during getTransactions process - we throw custom exception and compare messages in catch block
                throw new TransactionsRefundsAPI.CustomException('An exception should have been thrown');
            }catch(Exception ex) {
                Boolean expectedExceptionThrown = ex.getMessage().contains(TransactionsRefundsAPI.APPROVAL_NOT_FOUND_ERROR_MESSAGE);
                System.assertEquals(expectedExceptionThrown, true);
            }
        Test.stopTest();
    }

    @isTest
    static void testSFDCResponseDTOEnrichment() {
        String testJSON = '{"transactions": [{"productItems": [{ "productId": "1", "items": [ { "productId": "2", "itemDetails": [ { "productId": "3" } ] } ] }] }] }';

        Test.startTest();
        TransactionsRefundsAPI.SFDCResponseDTO testObj = (TransactionsRefundsAPI.SFDCResponseDTO)
                JSON.deserialize(testJSON, TransactionsRefundsAPI.SFDCResponseDTO.class);
        Test.stopTest();
        testObj.normalize();

        // Transaction
        TransactionsRefundsAPI.TransactionsDTO t = testObj.transactions.get(0);

        // Product Level
        List<TransactionsRefundsAPI.ProductItemDTO> prods = t.productItems;
        System.assertEquals(1, prods.size());

        TransactionsRefundsAPI.ProductItemDTO prod = prods.get(0);
        System.assertEquals('1', prod.productId);

        // Item Level
        List<TransactionsRefundsAPI.ItemsDTO> items = prod.items;
        System.assertEquals(2, items.size());

        TransactionsRefundsAPI.ItemsDTO item1 = items.get(0);
        TransactionsRefundsAPI.ItemsDTO item2 = items.get(1);
        System.assertEquals('1', item1.productId);
        System.assertEquals('2', item2.productId);

        // Sub Item Level
        List<TransactionsRefundsAPI.ItemDetailsDTO> subItems = item2.itemDetails;
        System.assertEquals(2, subItems.size());

        TransactionsRefundsAPI.ItemDetailsDTO subItem1 = subItems.get(0);
        TransactionsRefundsAPI.ItemDetailsDTO subItem2 = subItems.get(1);
        System.assertEquals('2', subItem1.productId);
        System.assertEquals('3', subItem2.productId);
    }

    @isTest
    static void testSFDCResponseDTOEnrichmentNoNormalizeRequired() {
        String testJSON = '{"transactions": [{"productItems": [{ "productId": "1", "items": [ { "productId": "1", "itemDetails": [ { "productId": "1" } ] } ] }] }] }';

        Test.startTest();
        TransactionsRefundsAPI.SFDCResponseDTO testObj = (TransactionsRefundsAPI.SFDCResponseDTO)
                JSON.deserialize(testJSON, TransactionsRefundsAPI.SFDCResponseDTO.class);
        Test.stopTest();
        testObj.normalize();

        // Transaction
        TransactionsRefundsAPI.TransactionsDTO t = testObj.transactions.get(0);

        // Product Level
        List<TransactionsRefundsAPI.ProductItemDTO> prods = t.productItems;
        System.assertEquals(1, prods.size());

        TransactionsRefundsAPI.ProductItemDTO prod = prods.get(0);
        System.assertEquals('1', prod.productId);

        // Item Level
        List<TransactionsRefundsAPI.ItemsDTO> items = prod.items;
        System.assertEquals(1, items.size());

        TransactionsRefundsAPI.ItemsDTO item1 = items.get(0);
        System.assertEquals('1', item1.productId);

        // Sub Item Level
        List<TransactionsRefundsAPI.ItemDetailsDTO> subItems = item1.itemDetails;
        System.assertEquals(1, subItems.size());

        TransactionsRefundsAPI.ItemDetailsDTO subItem1 = subItems.get(0);
        System.assertEquals('1', subItem1.productId);
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testgetNGBSTransactionsEmptyAccBillingId() {
        Test.startTest();
        try {
            TransactionsRefundsAPI.getNGBSTransactions('');
            assertFalse('Empty accountBillingId passed - expect an exception');
        } catch (Exception e) {
            if (!e.getMessage().contains(TransactionsRefundsAPI.UNEXPECTED_PARAMETER_EMPTY)) {
                assertFalse(e);
            }
        }
        Test.stopTest();
    }

    private static void assertFalse(Exception e) {
        assertFalse(UNEXPECTED_EXCEPTION_OCCURED + e.getMessage());
    }

    private static void assertFalse(String message) {
        System.assert(false, message);
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testgetNGBSTransactionsCorrectResponse() {
        Test.setMock(HttpCalloutMock.class, new Mock());

        Test.startTest();
        List<TransactionsRefundsAPI.TransactionsDTO> transactions =
            TransactionsRefundsAPI.getNGBSTransactions(CORRECT_ACCOUNT_BILLING_ID);
        Test.stopTest();
    }

    // TODO uncomment
//    @isTest
//    static void testgetNGBSBill() {
//        Test.setMock(HttpCalloutMock.class, new Mock());
//
//        Test.startTest();
//        TransactionsRefundsAPI.DetailsResponse detailsResponse =
//            TransactionsRefundsAPI.getNGBSBill(CORRECT_ACCOUNT_BILLING_ID, CORRECT_BILL_ID);
//        Test.stopTest();
//
//        List<TransactionsRefundsAPI.ProductItemDTO> productItems = detailsResponse.products;
//
//        System.assertEquals(productItems.size(), 2,
//            'Expect to have 1 product items because mocked JSON has 2 product items and 1 tax. ' +
//                'Subscription waved off because its amount 0');
//        System.assertEquals(productItems[0].items.size(), 2, 'second product item should have 1 item and 1 tax');
//        System.assertEquals(productItems[0].items[0].maxRefundAmount, 10,
//            'first product item should have maxRefundAmount 10,because CORRECT_CALCULATE_REFUNDS_BILL_JSON has ' +
//                '10 max refund for this item');
//        System.assertEquals(productItems[1].items.size(), 1, 'second product item should have 1 item and 1 tax');
//        System.assertEquals(productItems[1].items[0].maxRefundAmount, 0,
//            'first product item should have maxRefundAmount 10,because CORRECT_CALCULATE_REFUNDS_BILL_JSON has ' +
//                '10 max refund for this item');
//    }

    @isTest
    static void testgetNGBSInvoice() {
        Test.setMock(HttpCalloutMock.class, new Mock());

        Test.startTest();
        TransactionsRefundsAPI.DetailsResponse detailsResponse =
            TransactionsRefundsAPI.getNGBSInvoice(CORRECT_ACCOUNT_BILLING_ID, CORRECT_INVOICE_ID);
        Test.stopTest();

        List<TransactionsRefundsAPI.ProductItemDTO> productItems = detailsResponse.products;

        System.assertEquals(2, productItems.size(),
            'Expect to get 2 Invoice product items - Large Meetings and RingCentral Webinar 100. ' +
                'Other items should be skipped because of negative values and tax should be under items.');
        System.assertEquals(3, productItems[0].items.size(),
            'Expect to get 3 items - Large Meetings and 2 NY Sales Tax. ');
        System.assertEquals(104.52, productItems[0].items[0].maxRefundAmount,
            'Max refund for Large Meetings should be 104.52, ' +
                'because it\'s 104.52 in CORRECT_CALCULATE_REFUNDS_INVOICE_JSON ');
        System.assertEquals(4.18, productItems[0].items[1].maxRefundAmount,
            'Max refund for Large Meetings should be 4.18, ' +
                'because it\'s 4.18 in CORRECT_CALCULATE_REFUNDS_INVOICE_JSON ');
        System.assertEquals(4.18, productItems[0].items[2].maxRefundAmount,
            'Max refund for Large Meetings should be 4.18, ' +
                'because it\'s 4.18 in CORRECT_CALCULATE_REFUNDS_INVOICE_JSON ');
        System.assertEquals(1, productItems[1].items.size(),
            'Expect to get 3 items - RingCentral Webinar 100 and 2 NY Sales Tax. ');
        System.assertEquals(54.16, productItems[1].items[0].maxRefundAmount,
            'Max refund for Large Meetings should be 54.16, ' +
                'because it\'s 54.16 in CORRECT_CALCULATE_REFUNDS_INVOICE_JSON ');
    }

    //TODO make tests for Invoice type

    public class Mock implements HttpCalloutMock {
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
            } else if (endpoint.endsWith('GetTransactions')) {
                //Talend transactions response
                res.setBody(CORRECT_TALEND_JSON);
            } else if (endpoint.substring(0, endpoint.lastIndexOf('/')).endsWith('/purchase/invoice')) {
                //invoice detail
                res.setBody(CORRECT_NGBS_INVOICE_JSON);
            } else if (endpoint.endsWith('/invoice/adjustment/calculate')) {
                //invoice calculate refunds
                res.setBody(CORRECT_CALCULATE_REFUNDS_INVOICE_JSON);
            } else if (endpoint.endsWith('/invoice/adjustment/calculate?creditApplication=AutoDistribute')) {
                //invoice calculate refunds
                res.setBody(CORRECT_CALCULATE_REFUNDS_INVOICE_JSON);
            } else if (endpoint.endsWith('/GetTransactionDetails_Page')) {
                //Talend transactions pages info
                res.setBody(CORRECT_TRANSACTION_PAGES_INFO);
            } else {
                //unexpected
                System.assert(false, 'unexpected endpoint ' + endpoint);
            }
            return res;
        }
    }

    private class MockWithIncorrectResponse implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();
            res.setStatus('OK');
            res.setBody('{"refund" : {"transactions":[{"billingTransactionID":"1231443","Status":"false",' + '"message":"Internal error occurred [UserId could not be acquired from UserRequest: mandatory userId field is NULL]"}]}}');
            res.setStatusCode(200);
            return res;
        }
    }

    @isTest
    private static void test_replaceTransactionType_successed() {
        System.assertEquals(
            TransactionsRefundsAPI.replaceTransactionType(TransactionsRefundsAPI.TRANSACTION_WO_TYPE),
            '',
            'Request transaction type was replaced incorrectly.'
        );
    }

    @isTest
    private static void test_replaceTransactionType_failed() {
        String request = TransactionsRefundsAPI.TRANSACTION_WO_TYPE.replace('null', TransactionsRefundsAPI.TRANSACTION_TYPE_RC);

        System.assertEquals(
            TransactionsRefundsAPI.replaceTransactionType(request),
            request,
            'Request transaction type was replaced incorrectly.'
        );
    }

    @isTest
    static void testGetTalendTransactionsPagesInfoWithoutParam() {
        insert new Feature_Toggle__c (Large_Transactions_Processing__c = true);
        Test.startTest();
            try {
                TransactionsRefundsAPI.TransactionInfoResponse getTransactionsResult =
                    TransactionsRefundsAPI.getTalendTransactionPagesInfo(null, 'transactionId_1234',
                    TransactionsRefundsAPI.TRANSACTION_TYPE_RC);
            } catch(Exception ex) {
                Boolean expectedExceptionThrown = ex.getMessage().contains
                (TransactionsRefundsAPI.ACC_TALEND_TRANS_DETAILS_REQUIRED_FIELDS_IS_NULL_ERROR_MESSAGE);
                System.assertEquals(expectedExceptionThrown, true, 'Required params are not specified for page info request');
            }
        Test.stopTest();
    }

    @isTest
    static void testGetTalendTransactionsPagesInfoWithEmptyEndPoint() {
        delete [SELECT Id FROM Refunds_Settings__c];
        Test.startTest();
            try {
                TransactionsRefundsAPI.TransactionInfoResponse getTransactionsResult =
                    TransactionsRefundsAPI.getTalendTransactionPagesInfo('userId_1234', 'transactionId_1234',
                    TransactionsRefundsAPI.TRANSACTION_TYPE_RC);
            } catch(Exception ex) {
                Boolean expectedExceptionThrown = ex.getMessage().contains
                (TransactionsRefundsAPI.ENDPOINT_TALEND_NOT_FOUND_ERROR_MESSAGE);
                System.assertEquals(expectedExceptionThrown, true, 'Endpoint for page info request is not populated');
            }
        Test.stopTest();
    }

    @isTest
    static void testGetTalendTransactionPageInfo() {
        insert new Feature_Toggle__c (Large_Transactions_Processing__c = true);
        Test.setMock(HttpCalloutMock.class, new Mock());
        Test.startTest();
            TransactionsRefundsAPI.TransactionInfoResponse getTransactionPagesInfoResult =
                TransactionsRefundsAPI.getTalendTransactionPagesInfo('userId_1234', 'transactionId_1234',
                TransactionsRefundsAPI.TRANSACTION_TYPE_RC);
        Test.stopTest();
        System.assertEquals('12345', getTransactionPagesInfoResult.sessionId,'Transaction session Id doesn\'t match');
        System.assertEquals('1', getTransactionPagesInfoResult.SessionPageCount, 'Details have incorrect pages amount');
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

    @isTest
    static void testGetTalendTransactionDetails() {
        insert new Feature_Toggle__c (Large_Transactions_Processing__c = true);
        Test.setMock(HttpCalloutMock.class, new MockWithTransactionDetails());
        Test.startTest();
            TransactionsRefundsAPI.SFDCResponseDTO getTransactionDetailsResult =
                TransactionsRefundsAPI.getTalendTransactionDetails('userId_1234', 'transactionId_1234', 'type',
                'sessionId','sessionPage');
        Test.stopTest();
        System.assertEquals('12345', getTransactionDetailsResult.sessionId);
        System.assertEquals('2', getTransactionDetailsResult.sessionPageId);
    }
}