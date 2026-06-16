@RestResource(UrlMapping='/TransactionHistoryService/*')
global with sharing class TransactionHistoryService {

    public static final Map<String, String> refundFamilyMatcher = new Map<String, String> {
        'RC Core' => 'RC',
        'RC Legacy' => 'RC',
        'RC' => 'RC',
        'NGBS' => 'NGBS',
        'Contact Center' => 'CC',
        'CC' => 'CC',
        'ProServ' => 'PS',
        'PS' => 'PS'
    };

    public static final Map<String, String> refundFamilyReverseMatcher = new Map<String, String> {
        'RC Core' => 'RC Legacy',
        'RC Legacy' => 'RC Legacy',
        'RC' => 'RC Legacy',
        'NGBS' => 'NGBS',
        'Contact Center' => 'Contact Center',
        'CC' => 'Contact Center',
        'ProServ' => 'ProServ',
        'PS' => 'ProServ'
    };

    @HttpPost
    global static void handle() {
        String result = '';
        PostSaleRefundsWrappers.TransactionHistoryServiceParams paramsData =
            (PostSaleRefundsWrappers.TransactionHistoryServiceParams) JSON.deserialize(
                RestContext.request.requestBody.toString(),
                PostSaleRefundsWrappers.TransactionHistoryServiceParams.class
            );
        RestResponse res = RestContext.response;
        if (res == null) {
            res = new RestResponse();
            RestContext.response = res;
        }

        try {
            if (paramsData.action != 'createTransactionHistories') {
                sendLogEmail('Incorrect action attribute: ' + paramsData.action.escapeHtml4(), paramsData);
                res.statusCode = 500;
            } else if (paramsData.transactions == null) {
                sendLogEmail('No successful transactions', paramsData);
                res.statusCode = 500;
            } else if (paramsData.transactions.size() == 0) {
                sendLogEmail('No transactions specified', paramsData);
                res.statusCode = 500;
            } else {
                result = JSON.serialize(createTransactionHistories(paramsData));
                res.responseBody = Blob.valueOf(result);
                res.statusCode = 200;
            }
        } catch (Exception e) {
            sendLogEmail('Apex Exception: ' + e.getMessage(), paramsData, e.getStackTraceString());
            Map<String, String> errMsg = new Map<String, String>();
            errMsg.put('error', e.getMessage());
            errMsg.put('stackTrace', e.getStackTraceString());
            res.statusCode = 500;
            res.responseBody = Blob.valueOf(JSON.serialize(errMsg));
        }
    }

    private static Map<String, String> createTransactionHistories(
        PostSaleRefundsWrappers.TransactionHistoryServiceParams params
    ) {
        List<Transaction_History__c> transactionHistories = new List<Transaction_History__c>();
        for (PostSaleRefundsWrappers.TransactionPosted t : params.transactions) {
            transactionHistories.add(
                new Transaction_History__c(
                    Approval__c = params.approvalId,
                    TransactionId__c = t.billingTransactionId,
                    Type__c = t.refundType,
                    TransactionType__c = refundFamilyMatcher.get(t.transactionType),
                    RefundAmount__c = t.transactionRefundAmount,
                    Refunded__c = false,
                    Status__c = TransactionHistoryHelper.STATUS_IN_PROGRESS,
                    Refund_Id__c = t.refundId
                )
            );
        }

        if (!transactionHistories.isEmpty()) {
            insert transactionHistories;
        }

        return new Map<String, String>{'Status' => 'Success'};
    }

    private static void sendLogEmail(String context, PostSaleRefundsWrappers.TransactionHistoryServiceParams params) {
        sendLogEmail(context, params, null);
    }

    private static void sendLogEmail(String context, PostSaleRefundsWrappers.TransactionHistoryServiceParams params, String stackTrace) {
        Refunds_Settings__c refSettings = Refunds_Settings__c.getInstance();
        if (refSettings.IsEmailOnRefundFailures__c && !String.isBlank(refSettings.EmailForRefundFailures__c)) {
            Messaging.SingleEmailMessage emailMessage = new Messaging.SingleEmailMessage();
            emailMessage.setSaveAsActivity(false);
            emailMessage.setToAddresses(new List<String>{refSettings.EmailForRefundFailures__c});
            emailMessage.setSubject(context.escapeHtml4());
            emailMessage.setHtmlBody(
                'Approval Id: ' + params.approvalId
                + '<br/>Timestamp: ' + System.now().formatGmt('dd/MM/yyyy HH:mm:ss')
                + '<br/><br/>Transaction List:<br/>' + JSON.serialize(params.transactions, true).escapeHtml4()
                + '<br/><br/>Request:<br/>' + params.requestRaw.escapeHtml4()
                + '<br/><br/>Response:<br/>' + params.responseRaw.escapeHtml4()
                + (stackTrace != null ? ('<br/><br/>Stack trace:<br/>' + stackTrace.escapeHtml4()) : '')
            );
            
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { emailMessage });
        }
    }
}