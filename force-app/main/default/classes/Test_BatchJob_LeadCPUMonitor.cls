@isTest
public with sharing class Test_BatchJob_LeadCPUMonitor {
    
    
    @isTest
    static void testCPUMonitorRecordCreation_Lead() {
        LeadCPUMonitorHelper.SOBJECT_TO_TEST = 'Lead';
        LeadCPUMonitorHelper.AMOUNT_OF_SOBJECT_TO_TEST = 1;
        
        Test.startTest();
            Id batchJobId = Database.executeBatch(new BatchJob_LeadCPUMonitor());
        Test.stopTest();
        
        List<CPU_Monitor__c> leadInsert = (List<CPU_Monitor__c>) new CPUMonitorSelector().selectCPUMonitorByTransactionType(new List<String>{'Lead Creation'}).selectField(CPU_Monitor__c.Error__c).executeQuery();
        List<CPU_Monitor__c> leadUpdate = (List<CPU_Monitor__c>) new CPUMonitorSelector().selectCPUMonitorByTransactionType(new List<String>{'Lead Update'}).selectField(CPU_Monitor__c.Error__c).executeQuery();
        
        System.assertEquals(1,leadInsert.size());
        System.assertEquals(1,leadUpdate.size());
        System.assertEquals(null, leadInsert[0].Error__c);
        System.assertEquals(null, leadUpdate[0].Error__c);
    }
    @isTest
    static void testCPUMonitorRecordCreation_Contact() {
        LeadCPUMonitorHelper.SOBJECT_TO_TEST = 'Contact';
        LeadCPUMonitorHelper.AMOUNT_OF_SOBJECT_TO_TEST = 1;

        Test.startTest();
            Id batchJobId = Database.executeBatch(new BatchJob_LeadCPUMonitor());
        Test.stopTest();

        List<CPU_Monitor__c> contactInsert = (List<CPU_Monitor__c>) new CPUMonitorSelector().selectCPUMonitorByTransactionType(new List<String>{'Contact Creation'}).selectField(CPU_Monitor__c.Error__c).executeQuery();
        List<CPU_Monitor__c> contactUpdate = (List<CPU_Monitor__c>) new CPUMonitorSelector().selectCPUMonitorByTransactionType(new List<String>{'Contact Update'}).selectField(CPU_Monitor__c.Error__c).executeQuery();
        
        System.assertEquals(1,contactInsert.size());
        System.assertEquals(1,contactUpdate.size());
        System.assertEquals(null, contactInsert[0].Error__c);
        System.assertEquals(null, contactUpdate[0].Error__c);
    }
    @isTest
    static void testCPUMonitorRecordCreation_Case() {
        LeadCPUMonitorHelper.SOBJECT_TO_TEST = 'Case';
        LeadCPUMonitorHelper.AMOUNT_OF_SOBJECT_TO_TEST = 1;

        BatchjobCPUMonitorSettings__c settings = new BatchjobCPUMonitorSettings__c();
        settings.Cases_to_process__c = 1;
        insert settings;

        Test.startTest();
            Id batchJobId = Database.executeBatch(new BatchJob_LeadCPUMonitor());
        Test.stopTest();

        List<CPU_Monitor__c> caseInsert = (List<CPU_Monitor__c>) new CPUMonitorSelector().selectCPUMonitorByTransactionType(new List<String>{'Case Creation'}).selectField(CPU_Monitor__c.Error__c).executeQuery();
        List<CPU_Monitor__c> caseUpdate = (List<CPU_Monitor__c>) new CPUMonitorSelector().selectCPUMonitorByTransactionType(new List<String>{'Case Update'}).selectField(CPU_Monitor__c.Error__c).executeQuery();
        
        System.assertEquals(1,caseInsert.size());
        System.assertEquals(1,caseUpdate.size());
        System.assertEquals(null, caseInsert[0].Error__c);
        System.assertEquals(null, caseUpdate[0].Error__c);
    }

    @isTest
    static void testRecordsAreDeleted_Lead() {
        LeadCPUMonitorHelper.SOBJECT_TO_TEST = 'Lead';
        Test.startTest();
            Id batchJobId = Database.executeBatch(new BatchJob_LeadCPUMonitor());
        Test.stopTest();
        
        List<Account> existingAccounts = (List<Account>) new AccountSelector()
            .selectAccountByName(new String[]{'TestAccountMonitoring'})
            .executeQuery();
            
        List<Contact> existingContacts = (List<Contact>) new ContactSelector()
            .selectContactsByEmail(new object[]{
                new String[]{'firstNameTestMonitoring'},
                new String[]{'lastNameTestMonitoring'},
                new String[]{'EmailForTesting@TestingCsv.com'}
            })
            .executeQuery();

        List<Lead> existingLeads = (List<Lead>) new LeadSelector()
            .selectLeadByLastName(new List<Object>{ 'batchLeadCPUMonitor' })
            .executeQuery();

        List<Campaign> existingCampaigns = (List<Campaign>) new CampaignSelector()
            .selectCampaignsByName(new List<Object>{ 'LeadCPUMonitorCampaign' })
            .executeQuery();

        List<Marketing_Asset__c> existingAssets = (List<Marketing_Asset__c>) new MarketingAssetSelector()
            .selectMarketingAssets()
            .executeQuery();

        System.assertEquals(0, existingLeads.size());
        System.assertEquals(0, existingCampaigns.size());
        System.assertEquals(0, existingAssets.size());
        System.assertEquals(0, existingContacts.size());
        System.assertEquals(0, existingAccounts.size());
    }

    @isTest
    static void testSendEmailNotification() {
        BatchJobsConfiguration__c setting = new BatchJobsConfiguration__c();
        setting.Name = 'BatchJob_LeadCPUMonitor';
        setting.ErrorEmailDistributionList__c = 'test@testmail.com';
        insert setting;

        List<CPU_Monitor__c> monitorsToInsert = new List<CPU_Monitor__c>();
        monitorsToInsert.add(new CPU_Monitor__c(
            Name = 'Test',
            Transaction_type__c = 'Contact Update'
        ));
        monitorsToInsert.add(new CPU_Monitor__c(
            Name = 'Test Lead',
            Transaction_type__c = 'Lead Conversion',
            Error__c = 'Test error'
        ));

        LeadCPUMonitorHelper.sendEmailNotification(monitorsToInsert);
        LeadCPUMonitorHelper.sendEmailNotification(100, 100, 'error 1', 'error 2');

        System.assertEquals(2, Limits.getEmailInvocations());
    }

    @isTest
    static void formattedDate_whenSendADate_ShouldReturnsAFormattedDate() {
        Datetime today = Datetime.now();

        String expectedFormattedDate = today.format('MM/dd/yyyy, hh:mm aaa');

        String formattedDate = LeadCPUMonitorHelper.getFormattedDate(today);

        System.assert(formattedDate.contains(expectedFormattedDate), 'The formattedDate should contains: ' + expectedFormattedDate);
    }

    @isTest
    static void testParseCSV_Lead() {
        String csvData = ''
                + 'FirstName;LastName;Status;Email\n'
                + 'test;batchLeadCPUMonitor;1. New;test@test.com\n'
                + 'test;batchLeadCPUMonitor;1. New;test@test.com\n'
                ;
        List<Lead> leadsFromCSV = LeadCPUMonitorHelper.csvToLeadList(LeadCPUMonitorHelper.parseCSV(csvData, false));
        System.assertEquals(2, leadsFromCSV.size());
        System.assertEquals('test', leadsFromCSV[0].FirstName);
        System.assertEquals('batchLeadCPUMonitor', leadsFromCSV[0].LastName);
        System.assertEquals('1. New', leadsFromCSV[0].Status);
        System.assertEquals('test@test.com', leadsFromCSV[0].Email);
    }

    @isTest
    static void test_getCPUMonitorsFilteredByDays() {
        List<CPU_Monitor__c> monitors = (List<CPU_Monitor__c>) new SObjectBuilder(CPU_Monitor__c.sObjectType)
            .setFields(new Map<SObjectField, Object> {
                CPU_Monitor__c.Transaction_Type__c => 'Lead Creation'
            })
            .quantity(10)
            .create()
            .getRecords();
        
        
        Test.setCreatedDate(monitors[0].Id, DatetIME.now().addDays(-10));
        Test.setCreatedDate(monitors[1].Id, DatetIME.now().addDays(-10));

        Test.startTest();
            List<CPU_Monitor__c> retrieveMonitors = LeadCPUMonitorHelper.getCPUMonitorsFilteredByDays('Lead', 9, null, null);
        Test.stopTest();

        system.assertEquals(8, retrieveMonitors.size());
    }

    @isTest
    static void test_getCPUMonitorsFilteredByDaysForLeadConversion() {
        List<CPU_Monitor__c> monitors = (List<CPU_Monitor__c>) new SObjectBuilder(CPU_Monitor__c.sObjectType)
            .setFields(new Map<SObjectField, Object> {
                CPU_Monitor__c.Transaction_Type__c => 'Lead Conversion'
            })
            .quantity(10)
            .create()
            .getRecords();
        
        
        Test.setCreatedDate(monitors[0].Id, DateTime.now().addDays(-10));
        Test.setCreatedDate(monitors[1].Id, DateTime.now().addDays(-10));

        Test.startTest();
            List<CPU_Monitor__c> retrieveMonitors = LeadCPUMonitorHelper.getCPUMonitorsFilteredByDays('Lead Conversion', 9, null, null);
        Test.stopTest();

        System.assertEquals(8, retrieveMonitors.size());
    }

    @isTest
    static void test_getCPUMonitorsFilteredByDays_ShouldThrowAnError() {

        Boolean failed = false;

        try {
            List<CPU_Monitor__c> retrieveMonitors = LeadCPUMonitorHelper.getCPUMonitorsFilteredByDays('DoesntExist', 9, 'test', 'test');
        } catch(Exception e) {
            failed = true;
        }

        system.assertEquals(true, failed, 'The method "getCPUMonitorsFilteredByDays" should have failed.');
    }
    @isTest
    static void test_getReportInformation_shouldThrowAnError() {

        Boolean failed = false;

        try {
            String jsonReportInformation = LeadCPUMonitorHelper.getReportInformation('Lead Creation', 'LAST 7 DAYS');
        } catch(Exception e) {
            failed = true;
        }

        system.assertEquals(true, failed, 'The method "getReportInformation" should have failed.');
    }

    @isTest
    static void test_getSOQLReportInformationError() {
        Boolean failed = false;

        try {
            String jsonReportInformation = LeadCPUMonitorHelper.getSOQLReportInformation('LAST 7 DAYS');
        } catch(Exception e) {
            failed = true;
        }

        System.assertEquals(true, failed, 'The method "getSOQLReportInformation" should have failed.');
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void test_prepareData() {
        LeadCPUMonitorHelper.prepareData();
        LeadCPUMonitorHelper.sendEmailNotification(1000,100,'test','test2');
        LeadCPUMonitorHelper.csvToSObjectList(new List<List<String>>{new List<String>{'testmessage'},new List<String>{'testmessage'}},'Lead');
    }
}