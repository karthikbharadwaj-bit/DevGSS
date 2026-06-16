@isTest
private class Test_BatchJob_DeleteMainDataSched {
    @TestSetup
    static void setup() {

        SObjectBuilder settings = new SObjectBuilder(GDPR_Requests__c.SObjectType)
            .setField(GDPR_Requests__c.Name, 'Account')
            .setField(GDPR_Requests__c.Object_name__c, 'Account')
            .setField(GDPR_Requests__c.Priority__c, 10)
            .setField(GDPR_Requests__c.RetentionPeriod__c, 120)
            .create();

        SObjectBuilder accsBuilder = new SObjectBuilder(Account.SObjectType).quantity(10)
            .setFields(new Map<SObjectField, Object> {
                Account.RC_Churn_Date__c => Datetime.now().addMonths(-121)
            })
            .create();
    }

    @isTest
    static void testBatchScheduler() {
        List<Account> accs = [SELECT Id FROM Account];
        System.assertEquals(10, accs.size());

        Test.startTest();
            BatchJob_DeleteMainDataSched sched = new BatchJob_DeleteMainDataSched();
            sched.execute(null);
        Test.stopTest();

        accs = [SELECT Id FROM Account];
        System.assertEquals(0, accs.size());
    }
}