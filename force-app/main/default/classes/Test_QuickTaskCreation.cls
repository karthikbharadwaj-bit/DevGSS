@isTest
private class Test_QuickTaskCreation {
    @testSetup
    static void createTestData() {
        List<RecordType> acctRecTypes = [SELECT Id, Name from RecordType where SobjectType = 'Account' order by Name];
        List<Account> acctList = (List<Account>) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Name =>ValueProviderBuilder.provideList(new List<String> {'Test Customer Acct','Test Partner Acct'}),
                Account.RecordTypeId =>ValueProviderBuilder.provideList(new List<Id> {AccountHelper.RT_ID_CUSTOMER_ACCOUNT,AccountHelper.RT_ID_PARTNER_ACCOUNT})
            })
            .quantity(2)
            .create()
            .getRecords();
    }
    
    @isTest
    static void testAsInScopeProfileUser() {
        String objName = 'Account';
        Account customerAcct = [SELECT Id from Account WHERE Name = 'Test Customer Acct' LIMIT 1];
        QuickTaskCreation.QuickTaskWrapper qtw = QuickTaskCreation.getQuickTaskInfo(customerAcct.Id, objName);
        Assert.areEqual('success', qtw.errorMsg, 'Record Type Validation for Quick Task is incorrect');
        
        Account partnerAcct = [SELECT Id from Account WHERE Name = 'Test Partner Acct' LIMIT 1];
        QuickTaskCreation.QuickTaskWrapper qtw2 = QuickTaskCreation.getQuickTaskInfo(partnerAcct.Id, objName);
        String expectedRTErrorMsg = System.Label.QuickTask_IneligibleRecordTypes_ErrorMsg + ' ' + objName;
        Assert.areEqual(expectedRTErrorMsg, qtw2.errorMsg, 'Record Type Validation for Quick Task is incorrect');
    }
}