@isTest
private class Test_TransactionHistoryService {
    @isTest
    static void test_createTransactionHistories() {
        Approval__c testApproval = (Approval__c) new SObjectBuilder(Approval__c.SObjectType).create().getRecord();

        PostSaleRefundsWrappers.TransactionPosted tp = new PostSaleRefundsWrappers.TransactionPosted();
        tp.billingTransactionId = '10484835004';
        tp.refundType = 'Max';
        tp.transactionRefundAmount = 200;
        tp.transactionType = ApprovalHelper.REFUND_FAMILY_RC_LEGACY;
        tp.refundId = '1234523';

        PostSaleRefundsWrappers.TransactionHistoryServiceParams pars = new PostSaleRefundsWrappers.TransactionHistoryServiceParams();
        pars.action = 'createTransactionHistories';
        pars.approvalId = testApproval.Id;
        pars.transactions = new List<PostSaleRefundsWrappers.TransactionPosted>{tp};

        String requestPayload = JSON.serialize(pars);

        RestRequest request = new RestRequest();
        request.requestBody = Blob.valueOf(requestPayload);
        RestContext.request = request;

        TransactionHistoryService.handle();

        Integer resStatus = RestContext.response.statusCode;
        String resBody = RestContext.response.responseBody.toString();

        System.assertEquals(200, resStatus, 'Response status doesn\'t match');
        System.assert(resBody.containsIgnoreCase('success'), 'Wrong response body');

        List<Transaction_History__c> ths = [
            SELECT RefundAmount__c, TransactionType__c, TransactionId__c, Type__c, Status__c, Refund_Id__c
            FROM Transaction_History__c
        ];

        System.assert(!ths.isEmpty() && ths.size() == 1);

        Transaction_History__c th = ths[0];

        System.assertEquals(200, th.RefundAmount__c, 'Refund amount doesn\'t match');
        System.assertEquals(
            TransactionHistoryService.refundFamilyMatcher.get(ApprovalHelper.REFUND_FAMILY_RC_LEGACY),
            th.TransactionType__c,
            'Transaction history refund family doesn\'t match'
        );
        System.assertEquals('10484835004', th.TransactionId__c, 'Transaction ID doesn\'t match');
        System.assertEquals('Max', th.Type__c, 'Refund type doesn\'t match');
        System.assertEquals(
            TransactionHistoryHelper.STATUS_IN_PROGRESS,
            th.Status__c,
            'Transaction history status doesn\'t match'
        );
        System.assertEquals(
            '1234523',
            th.Refund_Id__c,
            'Transaction history refund ID doesn\'t match'
        );
    }

    @isTest
    static void test_createTransactionHistories_error() {
        Approval__c testApproval = (Approval__c) new SObjectBuilder(Approval__c.SObjectType).create().getRecord();

        PostSaleRefundsWrappers.TransactionPosted tp = new PostSaleRefundsWrappers.TransactionPosted();
        tp.billingTransactionId = '10484835004';
        tp.refundType = 'Max';
        tp.transactionRefundAmount = 200;
        tp.transactionType = ApprovalHelper.REFUND_FAMILY_RC_LEGACY;
        tp.refundId = '1234523';

        PostSaleRefundsWrappers.TransactionHistoryServiceParams pars = new PostSaleRefundsWrappers.TransactionHistoryServiceParams();
        pars.action = 'createTransactionHistories';
        pars.approvalId = 'bad id';
        pars.transactions = new List<PostSaleRefundsWrappers.TransactionPosted>{tp};

        String requestPayload = JSON.serialize(pars);

        RestRequest request = new RestRequest();
        request.requestBody = Blob.valueOf(requestPayload);
        RestContext.request = request;

        TransactionHistoryService.handle();

        Integer resStatus = RestContext.response.statusCode;
        String resBody = RestContext.response.responseBody.toString();

        System.assertEquals(500, resStatus, 'Response status doesn\'t match');
        System.assert(resBody.containsIgnoreCase('error'), 'Wrong response body');
    }
}