/*
Created By:     eugenebasianomutya
Date:           08312016
Case:           04920610 - Insert System status into Community header
Description:    Used by FetchSystemStatus
*/

@isTest
private class Test_FetchSystemStatus {

    private static list<System_Status__c> CreateSystemStatus() {
        list<System_Status__c> lSysStats = new list<System_Status__c>();

        System_Status__c SysStats1 = new System_Status__c();
        SysStats1.Summary__c = 'Summary';
        SysStats1.Severity__c = 'Severity Level-3';
        SysStats1.Region__c = 'UK';
        SysStats1.Public_Description__c = 'PublicDescription';
        SysStats1.Internal_Status__c = 'RESOLVED';
        SysStats1.Incident_Start_Date__c = system.today();
        SysStats1.Incident_Resolved_Date__c = system.today();
        SysStats1.IncidentID__c = '12345';
        lSysStats.add(SysStats1);

        System_Status__c SysStats2 = new System_Status__c();
        SysStats2.Summary__c = 'Summary';
        SysStats2.Severity__c = 'Severity Level-3';
        SysStats2.Region__c = 'UK';
        SysStats2.Public_Description__c = 'PublicDescription';
        SysStats2.Internal_Status__c = 'RESOLVED';
        SysStats2.Incident_Start_Date__c = system.today();
        SysStats2.Incident_Resolved_Date__c = system.today();
        SysStats2.IncidentID__c = '12346';
        lSysStats.add(SysStats2);

        Insert lSysStats;
        return lSysStats;
    }
    
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @IsTest
    private static void testRestService() {

        list<System_Status__c> lSystemStatus = new list<System_Status__c>();
        lSystemStatus = CreateSystemStatus();

        Test.startTest();
      
            RestRequest req = new RestRequest(); 
            RestResponse res = new RestResponse();

            req.requestURI = '/services/apexrest/fetchsystemstatus?brand=UK';  
            req.httpMethod = 'GET';
            RestContext.request = req;
            RestContext.response = res;
            
            FetchSystemStatus.GetSystemStatus();
    
       Test.stopTest();
    }
}