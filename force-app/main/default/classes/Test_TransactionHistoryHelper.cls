@isTest
private class Test_TransactionHistoryHelper {
    @isTest
    static void test_getTransactionHistoriesSumsByFamily() {
        Approval__c testApproval = (Approval__c) new SObjectBuilder(Approval__c.SObjectType).create().getRecord();
        // Create transaction histories for approval
        new SObjectBuilder(Transaction_History__c.SObjectType)
            .quantity(5)
            .setFields(new Map<SObjectField, Object>{
                Transaction_History__c.Approval__c => testApproval.Id,
                Transaction_History__c.TransactionType__c => ValueProviderBuilder.provideList(new List<String>{
                    TransactionHistoryService.refundFamilyMatcher.get(ApprovalHelper.REFUND_FAMILY_RC_LEGACY),
                    TransactionHistoryService.refundFamilyMatcher.get(ApprovalHelper.REFUND_FAMILY_NGBS),
                    TransactionHistoryService.refundFamilyMatcher.get(ApprovalHelper.REFUND_FAMILY_CONTACT_CENTER),
                    TransactionHistoryService.refundFamilyMatcher.get(ApprovalHelper.REFUND_FAMILY_PROSERV),
                    TransactionHistoryService.refundFamilyMatcher.get(ApprovalHelper.REFUND_FAMILY_PROSERV)
                }),
                Transaction_History__c.Refunded__c => ValueProviderBuilder.provideList(new List<Boolean>{
                    false,
                    false,
                    false,
                    true,
                    false
                }),
                Transaction_History__c.Status__c => ValueProviderBuilder.provideList(new List<String>{
                    TransactionHistoryHelper.STATUS_IN_PROGRESS,
                    TransactionHistoryHelper.STATUS_IN_PROGRESS,
                    TransactionHistoryHelper.STATUS_IN_PROGRESS,
                    TransactionHistoryHelper.STATUS_SUCCESS,
                    TransactionHistoryHelper.STATUS_FAILURE
                }),
                Transaction_History__c.RefundAmount__c => ValueProviderBuilder.provideList(new List<Decimal>{
                    100,
                    200,
                    300,
                    400,
                    500 // This one shouldn't be taken into account as far as Status__c == 'Failure'
                })
            })
            .create();

        Map<String,Decimal> res = TransactionHistoryHelper.getTransactionHistoriesSumsByFamily(testApproval.Id);

        System.assertEquals(100, res.get(ApprovalHelper.REFUND_FAMILY_RC_LEGACY));
        System.assertEquals(200, res.get(ApprovalHelper.REFUND_FAMILY_NGBS));
        System.assertEquals(300, res.get(ApprovalHelper.REFUND_FAMILY_CONTACT_CENTER));
        System.assertEquals(400, res.get(ApprovalHelper.REFUND_FAMILY_PROSERV));
    }
}