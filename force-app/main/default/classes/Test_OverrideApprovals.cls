@isTest
public with sharing class Test_OverrideApprovals {

@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
@isTest
    private static void testOverrideApprovals() {

        Account testAcc = (Account) new SObjectBuilder(Account.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Name => 'Test account'
            })
            .create()
            .getRecord();

        Approval__c approval = (Approval__c) new SObjectBuilder(Approval__c.SObjectType)
            .setField(Approval__c.Account__c, testAcc.Id)
            .setField(Approval__c.Status__c, 'Approve')
            .setField(Approval__c.RecordTypeId, ApprovalHelper.RT_ID_DIRECT_DEBIT_REQUEST)
            .build()
            .getRecord();

        OverrideApprovals.ApprovalWrapper input = new OverrideApprovals.ApprovalWrapper();
        input.targetObjectId = approval.id;
        input.action = 'Approve';
        
        Test.startTest();
        OverrideApprovals.overrideApproval(new List<OverrideApprovals.ApprovalWrapper>{input});
        Test.stopTest();
        }
     }