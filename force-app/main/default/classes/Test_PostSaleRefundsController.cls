@isTest
private class Test_PostSaleRefundsController {
    @isTest
    static void test_pageInit() {
        new SObjectBuilder(EndpointsSettings__c.sObjectType)
            .setField(EndpointsSettings__c.UQTServerEndpoint__c, 'testEndp')
            .create();

        Account testAcc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.RC_User_ID__c => '12345',
                    Account.Billing_ID__c => '54321'
                }
            )
            .create()
            .getRecord();

        Approval__c testApproval = (Approval__c) new SObjectBuilder(Approval__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Approval__c.Account__c => testAcc.Id,
                Approval__c.RecordTypeId => ApprovalHelper.RT_ID_REFUND_APPROVAL,
                Approval__c.JustificationandDescription__c => 'testJust',
                Approval__c.Amount__c => 1000,
                Approval__c.Refund_Amount_2__c => 900,
                Approval__c.Refund_Amount_3__c => 800,
                Approval__c.Refund_Amount_4__c => 700,
                Approval__c.Refund_Product_Family_1__c => ApprovalHelper.REFUND_FAMILY_RC_LEGACY,
                Approval__c.Refund_Product_Family_2__c => ApprovalHelper.REFUND_FAMILY_NGBS,
                Approval__c.Refund_Product_Family_3__c => ApprovalHelper.REFUND_FAMILY_CONTACT_CENTER,
                Approval__c.Refund_Product_Family_4__c => ApprovalHelper.REFUND_FAMILY_PROSERV
            })
            .create()
            .getRecord();

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

        List<Approval__c> approvalList = new ApprovalSelector()
            .selectRefundApprovalById(new List<String>{testApproval.Id})
            .executeQuery();

        testApproval = approvalList[0];

        ApexPages.StandardController sc = new ApexPages.StandardController(testApproval);

        PostSaleRefundsController psrContr = new PostSaleRefundsController(sc);

        System.assertEquals('testEndp', psrContr.billingWizardURL);
        System.assertEquals(URL.getOrgDomainUrl().toExternalForm(), psrContr.origin);
        System.assert(String.isNotBlank(psrContr.dataJSON));

        PostSaleRefundsWrappers.RefundApprovalDTO paramsData =
            (PostSaleRefundsWrappers.RefundApprovalDTO) JSON.deserialize(
                psrContr.dataJSON,
                PostSaleRefundsWrappers.RefundApprovalDTO.class
            );

        System.assertEquals(testApproval.Id, paramsData.apprId);

        System.assertEquals(900, paramsData.refundAmountsTotals.get(ApprovalHelper.REFUND_FAMILY_RC_LEGACY));
        System.assertEquals(700, paramsData.refundAmountsTotals.get(ApprovalHelper.REFUND_FAMILY_NGBS));
        System.assertEquals(500, paramsData.refundAmountsTotals.get(ApprovalHelper.REFUND_FAMILY_CONTACT_CENTER));
        System.assertEquals(300, paramsData.refundAmountsTotals.get(ApprovalHelper.REFUND_FAMILY_PROSERV));

        System.assertEquals('12345', paramsData.accInfo.rcUserId);
        System.assertEquals('54321', paramsData.accInfo.billingId);

        System.assertEquals('testJust', paramsData.refundComment);
    }
}