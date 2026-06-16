@isTest
private class Test_TaskAfter {

    @TestSetup static void createTestData() {
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
    }
    
    @isTest static void test_RollUpLogicUpdate(){
        Lead testLead = (Lead) new LeadSelector()
            .selectLeadByLastName(new List<Object>{
                'fakeLastName'
            })
            .executeQuery()
            .get(0);
        Task testTask = new Task();
        testTask.Subject = 'SomeSubject';
        testTask.Reset_OnCallAttemp__c = false;
        testTask.SDR_Meeting_Status__c = 'Accepted';
        testTask.whoId = testLead.id;
        testTask.Subject = 'Call';
        insert testTask;

        test.startTest();
        update testTask;
        test.stopTest();

        Lead comparedLead = [SELECT Call_Attempts__c FROM Lead LIMIT 1];
        System.assertNotEquals(null, comparedLead.Call_Attempts__c, 'Call Attempts should not be null');        
    }
    
     @isTest static void test_RollUpLogicInsert(){
        Lead testLead = (Lead) new LeadSelector()
            .selectLeadByLastName(new List<Object>{
                'fakeLastName'
            })
            .executeQuery()
            .get(0);
        testLead.Call_Attempts__c = 4;
        Task testTask = new Task();
        testTask.Subject = 'Call';
        testTask.WhoId = testLead.id;
        testTask.Reset_OnCallAttemp__c = false;
        testTask.SDR_Meeting_Status__c = 'Accepted';

        test.startTest();
        update testLead;
        insert testTask;
        test.stopTest();

        Lead comparedLead = [SELECT Call_Attempts__c FROM Lead LIMIT 1];
        System.assertEquals(5, comparedLead.Call_Attempts__c, 'Call Attempts should be the original plus 1');
    }

    @isTest static void test_RollUpLogicDelete(){
        Lead testLead = (Lead) new LeadSelector()
            .selectLeadByLastName(new List<Object>{
                'fakeLastName'
            })
            .executeQuery()
            .get(0);
        Task testTask = new Task();
        testTask.Subject = 'Call';
        testTask.WhoId = testLead.id;
        testTask.Reset_OnCallAttemp__c = false;
        testTask.SDR_Meeting_Status__c = 'Accepted';

        test.startTest();
        insert testTask;
        delete testTask;
        test.stopTest();

        Lead comparedLead = [SELECT Call_Attempts__c FROM Lead LIMIT 1];
        System.assertEquals(0, comparedLead.Call_Attempts__c, 'Call Attempts should be the zero');
    }

    @isTest static void test_RollUpLogicUndelete(){
        Lead testLead = (Lead) new LeadSelector()
            .selectLeadByLastName(new List<Object>{
                'fakeLastName'
            })
            .executeQuery()
            .get(0);
        Task testTask = new Task();
        testTask.Subject = 'Call';
        testTask.WhoId = testLead.id;
        testTask.Reset_OnCallAttemp__c = false;
        testTask.SDR_Meeting_Status__c = 'Accepted';

        test.startTest();
        insert testTask;
        delete testTask;
        undelete testTask;
        test.stopTest();

        Lead comparedLead = [SELECT Call_Attempts__c FROM Lead LIMIT 1];
        System.assertEquals(1, comparedLead.Call_Attempts__c, 'Call Attempts should be 1');
    }
    

}