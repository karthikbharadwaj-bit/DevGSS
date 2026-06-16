public with sharing class TransactionHistoryHelper {
    public static final String STATUS_SUCCESS = 'Success';
    public static final String STATUS_IN_PROGRESS = 'In Progress';
    public static final String STATUS_FAILURE = 'Failure';

    public static Map<String,Decimal> getTransactionHistoriesSumsByFamily(Id apprId) {
        Map<String, Decimal> res = new Map<String, Decimal> {
            ApprovalHelper.REFUND_FAMILY_RC_LEGACY => 0,
            ApprovalHelper.REFUND_FAMILY_NGBS => 0,
            ApprovalHelper.REFUND_FAMILY_CONTACT_CENTER => 0,
            ApprovalHelper.REFUND_FAMILY_PROSERV => 0
        };

        AggregateResult[] transHistoriesSummed = [
            SELECT SUM(RefundAmount__c) sum, TransactionType__c
            FROM Transaction_History__c
            WHERE Approval__c = :apprId
                AND Status__c != :STATUS_FAILURE
            GROUP BY TransactionType__c
        ];

        for (AggregateResult ar : transHistoriesSummed) {
            res.put(
                TransactionHistoryService.refundFamilyReverseMatcher.get((String) ar.get('TransactionType__c')),
                (Decimal) ar.get('sum')
            );
        }

        return res;
    }
}