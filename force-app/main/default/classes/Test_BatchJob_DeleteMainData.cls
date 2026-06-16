@isTest
private class Test_BatchJob_DeleteMainData {

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
    static void testBatchConstructorNoParams() {
        List<Account> accs = [SELECT Id FROM Account];
        System.assertEquals(10, accs.size());

        Test.startTest();
            BatchJob_DeleteMainData batch = new BatchJob_DeleteMainData();
            Database.executeBatch(batch);
        Test.stopTest();
        accs = [SELECT Id FROM Account];
        System.assertEquals(0, accs.size());
        Case createdCase = [SELECT Id, Subject, (SELECT Name FROM Attachments) FROM Case LIMIT 1];
        System.assert(createdCase != null, 'A new case should be created');
        System.assertEquals(
            'Account data deletion report',
            createdCase.Subject,
            'Subject should be named as \'Account data deletion report\''
        );

        System.assert(!createdCase.Attachments.isEmpty(), 'A new case should have an attachment');
        System.assertEquals(
            'Account.csv',
            createdCase.Attachments.get(0).Name,
            'Attachment file should be named as it\'s object');
    }

    @isTest
    static void testBatchConstructorWithParams() {
        List<Account> accs = [SELECT Id FROM Account];
        System.assertEquals(10, accs.size());

        Test.startTest();
            BatchJob_DeleteMainData batch = new BatchJob_DeleteMainData(GDPRHelper.getRequestsQueue(false));
            Database.executeBatch(batch, batch.getScope());
        Test.stopTest();
        accs = [SELECT Id FROM Account];
        System.assertEquals(0, accs.size());
    }
}