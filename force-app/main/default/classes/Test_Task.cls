@isTest 
private class Test_Task {

    static User getTestUser() {
        String uniqueUserName = 'standarduser' + DateTime.now().getTime() + '@testorg.com';
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User'];
        User u = new User(
            Alias = 'standt',
            Email = 'standarduser@testorg.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Testing',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = uniqueUserName
        );
        return u;
    }

	@isTest static void test_TaskBeforeLogic(){
        Id RT_TASK_STANDARD_TASK = Schema.SObjectType.Task.getRecordTypeInfosByName()
            .get('Standard Task').getRecordTypeId();
        System.runAs(getTestUser()) {
            Lead testLead = (Lead) new SObjectBuilder(Lead.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        Lead.email => 'fake@email.com',
                        Lead.LastName => 'fakeLastName',
                        Lead.Company => 'fakeCompany'
                    }
                )
                .create()
                .getRecord();
            Task testTask = new Task();
            testTask.Reset_OnCallAttemp__c = false;
            testTask.SDR_Meeting_Status__c = 'Accepted';
            testTask.whoId = testLead.id;
            testTask.Subject = 'Call';
            testTask.Status = 'Not Satrted';
            testTask.RecordTypeId = RT_TASK_STANDARD_TASK;
            testTask.Description = 'Test Description';
            testTask.ActivityDate = Date.today().addDays(2);
            insert testTask;

            test.startTest();
            testTask.Status = 'Completed';
            update testTask;
            test.stopTest();

            Lead comparedLead = [SELECT Call_Attempts__c FROM Lead LIMIT 1];
            System.assertNotEquals(null, comparedLead.Call_Attempts__c, 'Call Attempts should not be null');        
        }
    }
}