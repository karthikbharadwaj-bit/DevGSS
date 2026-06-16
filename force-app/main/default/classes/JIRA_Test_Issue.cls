@isTest
private class JIRA_Test_Issue {
    
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void test1(){
        
        // Get Record Type
        Id CaseRecordTypeInfo = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Service Engineer').getRecordTypeId();

        //Create Account
        Account Acc = new Account();
        Acc.Name = 'Eugene';
        insert Acc;

        //Create Contact
        Contact cont = new Contact();
        cont.LastName = 'Mutya';
        cont.AccountId = Acc.Id;
        insert Cont;

        //Create Case
        Case cas = new Case();
        cas.AccountId = Acc.Id;
        cas.ContactId = Cont.Id;
        cas.ERT_Case_Type__c = 'BBB Cases';
        cas.Case_Severity__c = 'Level 1 - Critical'; 
        cas.Status = 'New';
        cas.Origin =  'Phone';
        cas.Subject = 'Test';
        cas.Description = 'Test';
        cas.Support_Disposition_Level_1__c= 'Test';
        cas.Support_Disposition_Level_2__c= 'Test';
        cas.Support_Disposition_Level_3__c= 'Test';
        cas.CSAT_Prediction__c = '0';
        insert cas;
        
        // Call the Batch Update
        Test.startTest();

        JIRA_Issue_CreateUpdate.CreateUpdate_Issue('CNV-16120',cas.Id);

        Test.stopTest();   


    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void test2(){
        
        // Get Record Type
        Id CaseRecordTypeInfo = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Service Engineer').getRecordTypeId();
        Id JiraCaseRecordTypeInfo = Schema.SObjectType.JIRA_Case__c.getRecordTypeInfosByName().get('Issue').getRecordTypeId();

        //Create Account
        Account Acc = new Account();
        Acc.Name = 'Eugene';
        insert Acc;

        //Create Contact
        Contact cont = new Contact();
        cont.LastName = 'Mutya';
        cont.AccountId = Acc.Id;
        insert Cont;


        //Create Jira Case
        JIRA_Case__c jc = new JIRA_Case__c();
        jc.Issue_Id__c = '530591';
        jc.Issue_Key__c = 'CNV-16120';
        jc.recordTypeId = JiraCaseRecordTypeInfo;
        insert jc;

        //Create Case
        Case cas = new Case();
        cas.AccountId = Acc.Id;
        cas.ContactId = Cont.Id;
        cas.ERT_Case_Type__c = 'BBB Cases';
        cas.Case_Severity__c = 'Level 1 - Critical'; 
        cas.Status = 'New';
        cas.Origin =  'Phone';
        cas.Subject = 'Test';
        cas.Description = 'Test';
        cas.Support_Disposition_Level_1__c= 'Test';
        cas.Support_Disposition_Level_2__c= 'Test';
        cas.Support_Disposition_Level_3__c= 'Test';
        cas.CSAT_Prediction__c = '0';
        cas.JIRA_Case__c = jc.Id;
        insert cas;

        
        // Call the Batch Update
        Test.startTest();

        JIRA_Issue_BatchUpdate jibu = new JIRA_Issue_BatchUpdate();
        ID batchprocessid = Database.executeBatch(jibu);

        JIRA_Issue_BatchUpdate_Scheduler JiraScehduler = new JIRA_Issue_BatchUpdate_Scheduler();
        String sch = '0 0 23 * * ?';
        system.schedule('Test status Check', sch, JiraScehduler );
        
        Test.stopTest();   


    }


}