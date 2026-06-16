@isTest
public with sharing class Test_BatchJob_SObjectCPUMonitor {
    
    
    @isTest
    static void testCPUMonitorRecordCreation() {
        Test.startTest();
        Id batchJobId = Database.executeBatch(new BatchJob_SObjectCPUMonitor('Case'));
        Test.stopTest();
        List<CPU_Monitor__c> sObjectInsert = (List<CPU_Monitor__c>) new CPUMonitorSelector().selectCPUMonitorByTransactionType(new List<String>{'Case Creation'}).executeQuery();
        List<CPU_Monitor__c> sObjectUpdate = (List<CPU_Monitor__c>) new CPUMonitorSelector().selectCPUMonitorByTransactionType(new List<String>{'Case Update'}).executeQuery();
        System.assertEquals(1,sObjectInsert.size());
        System.assertEquals(1,sObjectUpdate.size());
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testParseCSV() {
        String csvData = ''
                + 'Status;Origin;Subject;Description;Support_Disposition_Level_1__c;Support_Disposition_Level_2__c;Case_Owner_Manager_Email__c;RecordTypeId\n'
                + 'New;Email;testetstetstetstets;testetstetstetstetstetste;Discount;Add;testtt@testtt.com;01234000000HpP9AAK\n'
                + 'New;Email;testetstetstetstets;testetstetstetstetstetste;Discount;Add;testtt@testtt.com;01234000000HpP9AAK\n'
                ;
        List<Lead> sObjectsFromCSV = LeadCPUMonitorHelper.csvToSObjectList(LeadCPUMonitorHelper.parseCSV(csvData, false),'Case');
    }
}