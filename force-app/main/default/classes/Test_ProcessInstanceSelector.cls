@isTest
private class Test_ProcessInstanceSelector {
    @isTest
    private static void testSelectProcessInstances() {
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => 'testAcc'
                }
            )
            .create()
            .getRecord();
        Approval__c app = (Approval__c) new SObjectBuilder(Approval__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Approval__c.Name => 'Test Approval',
                    Approval__c.Account__c => acc.Id,
                    Approval__c.RecordTypeId => ApprovalHelper.RT_ID_KYC_APPROVAL_REQUEST,
                    Approval__c.DateOfSignOff__c => System.today()
                }
            )
            .create()
            .getRecord();
        /* KYC Approval was auto submitted to approve */

        Test.startTest();
        List<ProcessInstance> processInstancesForApprovals = new ProcessInstanceSelector()
                .selectProcessInstancesForApproval(new List<Object>{new Set<Id>{app.Id}})
                .executeQuery();
        Test.stopTest();

        System.assertEquals(1, processInstancesForApprovals.size(), 'Should be created 1 Process Instance after submit approval');
    }
}