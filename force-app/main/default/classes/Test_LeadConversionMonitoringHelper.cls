@isTest
private class Test_LeadConversionMonitoringHelper {
    @isTest
    static void testCPUMonitorCreation() {
        Account acc = (Account) new AccountSelector().selectAccounts().executeQuery()[0];
        Contact con = (Contact) new ContactSelector().selectContacts().executeQuery()[0];
        Lead ld = (Lead) new LeadSelector().selectLeads().executeQuery()[0];
        Opportunity opp = (Opportunity) new OpportunitySelector().selectOpportunities().executeQuery()[0];
        Test.startTest();
        LeadConversionMonitoringHelper.publishLeadConversionPlatformEvent(
            2000,
            60,
            acc.Id,
            con.Id,
            opp.Id,
            ld.Id,
            0,
            '',
            '',
            false,
            false,
            false,
            false,
            ''
        );

        Test.stopTest();
        Test.getEventBus().deliver();

        CPU_Monitor__c cpuMonitor = (CPU_Monitor__c) new CPUMonitorSelector()
            .selectCPUMonitorForLeadConversionMonitor(new List<Id>{ld.Id})
            .executeQuery()[0];
        System.assertEquals(2000, cpuMonitor.CPU_Usage__c, 'The amount of CPU Usage is not correct');
        System.assertEquals(60, cpuMonitor.SOQL_Queries__c, 'The amount of SOQL Queries is not correct');
        System.assertEquals(null, cpuMonitor.Error__c, 'There should be no error');
    }

    @isTest
    static void testBiggerCPUandSOQL() {
        Account acc = (Account) new AccountSelector().selectAccounts().executeQuery()[0];
        Contact con = (Contact) new ContactSelector().selectContacts().executeQuery()[0];
        Lead ld = (Lead) new LeadSelector().selectLeads().executeQuery()[0];
        Opportunity opp = (Opportunity) new OpportunitySelector().selectOpportunities().executeQuery()[0];

        createCPUMonitor(acc, con, ld, opp, false, false);

        Test.startTest();
        LeadConversionMonitoringHelper.publishLeadConversionPlatformEvent(
            7000,
            70,
            acc.Id,
            con.Id,
            opp.Id,
            ld.Id,
            1,
            '',
            '',
            false,
            false,
            false,
            false,
            ''
        );
        Test.stopTest();
        CPU_Monitor__c cpuMonitor = (CPU_Monitor__c) new CPUMonitorSelector()
            .selectCPUMonitorForLeadConversionMonitor(new List<Id>{ld.Id})
            .selectFields(
                new List<String>{ 'CPU_Convert_Part__c', 'Queries_Convert_Part__c' }
            )
            .executeQuery()[0];
        System.assertEquals(7000, cpuMonitor.CPU_Usage__c, 'The amount of CPU Usage is not correct');
        System.assertEquals(70, cpuMonitor.SOQL_Queries__c, 'The amount of SOQL Queries is not correct');
        System.assertEquals(
            'convertPart1',
            cpuMonitor.CPU_Convert_Part__c,
            'The convert part for CPU Usage is not correct'
        );
        System.assertEquals(
            'convertPart1',
            cpuMonitor.Queries_Convert_Part__c,
            'The convert part for SOQL Queries is not correct'
        );
        System.assertEquals(null, cpuMonitor.Error__c, 'There should be no error');
    }

    @isTest
    static void testLowerCPUandSOQL() {
        Account acc = (Account) new AccountSelector().selectAccounts().executeQuery()[0];
        Contact con = (Contact) new ContactSelector().selectContacts().executeQuery()[0];
        Lead ld = (Lead) new LeadSelector().selectLeads().executeQuery()[0];
        Opportunity opp = (Opportunity) new OpportunitySelector().selectOpportunities().executeQuery()[0];

        createCPUMonitor(acc, con, ld, opp, false, false);

        Test.startTest();
        LeadConversionMonitoringHelper.publishLeadConversionPlatformEvent(
            4000,
            40,
            acc.Id,
            con.Id,
            opp.Id,
            ld.Id,
            1,
            '',
            '',
            false,
            false,
            false,
            false,
            ''
        );
        Test.stopTest();
        CPU_Monitor__c cpuMonitor = (CPU_Monitor__c) new CPUMonitorSelector()
            .selectCPUMonitorForLeadConversionMonitor(new List<Id>{ld.Id})
            .selectFields(
                new List<String>{ 'CPU_Convert_Part__c', 'Queries_Convert_Part__c' }
            )
            .executeQuery()[0];
        System.assertEquals(5000, cpuMonitor.CPU_Usage__c, 'The amount of CPU Usage is not correct');
        System.assertEquals(50, cpuMonitor.SOQL_Queries__c, 'The amount of SOQL Queries is not correct');
        System.assertEquals(
            'prepareLeadRecord',
            cpuMonitor.CPU_Convert_Part__c,
            'The convert part for CPU Usage is not correct'
        );
        System.assertEquals(
            'prepareLeadRecord',
            cpuMonitor.Queries_Convert_Part__c,
            'The convert part for SOQL Queries is not correct'
        );
        System.assertEquals(null, cpuMonitor.Error__c, 'There should be no error');
    }

    @isTest
    static void testCPUMonitorWithErrorInConvertLead() {
        Account acc = (Account) new AccountSelector().selectAccounts().executeQuery()[0];
        Contact con = (Contact) new ContactSelector().selectContacts().executeQuery()[0];
        Lead ld = (Lead) new LeadSelector().selectLeads().executeQuery()[0];
        Opportunity opp = (Opportunity) new OpportunitySelector().selectOpportunities().executeQuery()[0];
        createCPUMonitor(acc, con, ld, opp, false, false);
        Test.startTest();
        LeadConversionMonitoringHelper.publishLeadConversionPlatformEvent(
            4000,
            40,
            acc.Id,
            con.Id,
            opp.Id,
            ld.Id,
            1,
            'There was an error',
            'This is the error stacktrace',
            false,
            false,
            false,
            false,
            ''
        );
        Test.stopTest();
        CPU_Monitor__c cpuMonitor = (CPU_Monitor__c) new CPUMonitorSelector()
            .selectCPUMonitorForLeadConversionMonitor(new List<Id>{ld.Id})
            .selectField('Error_stacktrace__c')
            .selectField('Error_Part__c')
            .executeQuery()[0];
        System.assertEquals(5000, cpuMonitor.CPU_Usage__c, 'The amount of CPU Usage is not correct');
        System.assertEquals(50, cpuMonitor.SOQL_Queries__c, 'The amount of SOQL Queries is not correct');
        System.assertEquals('There was an error', cpuMonitor.Error__c, 'There should be an error');
        System.assertEquals('This is the error stacktrace', cpuMonitor.Error_stacktrace__c, 'There should be an error stacktrace');
        System.assertEquals('ConvertLead', cpuMonitor.Error_Part__c, 'The error should be in ConvertLead part');
    }

    @isTest
    static void testCPUMonitorWithErrorInExistingAccount() {
        Account acc = (Account) new AccountSelector().selectAccounts().executeQuery()[0];
        Contact con = (Contact) new ContactSelector().selectContacts().executeQuery()[0];
        Lead ld = (Lead) new LeadSelector().selectLeads().executeQuery()[0];
        Opportunity opp = (Opportunity) new OpportunitySelector().selectOpportunities().executeQuery()[0];
        createCPUMonitor(acc, con, ld, opp, false, false);
        Test.startTest();
        LeadConversionMonitoringHelper.publishLeadConversionPlatformEvent(
            4000,
            40,
            acc.Id,
            con.Id,
            opp.Id,
            ld.Id,
            2,
            'There was an error',
            'This is the error stacktrace',
            false,
            false,
            false,
            false,
            LeadConversionMonitoringHelper.ACCOUNT_NAME
        );
        Test.stopTest();
        CPU_Monitor__c cpuMonitor = (CPU_Monitor__c) new CPUMonitorSelector()
            .selectCPUMonitorForLeadConversionMonitor(new List<Id>{ld.Id})
            .selectField('Error_stacktrace__c')
            .selectField('Error_Part__c')
            .executeQuery()[0];
        System.assertEquals(5000, cpuMonitor.CPU_Usage__c, 'The amount of CPU Usage is not correct');
        System.assertEquals(50, cpuMonitor.SOQL_Queries__c, 'The amount of SOQL Queries is not correct');
        System.assertEquals('There was an error', cpuMonitor.Error__c, 'There should be an error');
        System.assertEquals('This is the error stacktrace', cpuMonitor.Error_stacktrace__c, 'There should be an error stacktrace');
        System.assertEquals('ExistingAccount', cpuMonitor.Error_Part__c, 'The error should be in ConvertLead part');
    }

    @isTest
    static void testCPUMonitorWithErrorInCreateAccount() {
        Account acc = (Account) new AccountSelector().selectAccounts().executeQuery()[0];
        Contact con = (Contact) new ContactSelector().selectContacts().executeQuery()[0];
        Lead ld = (Lead) new LeadSelector().selectLeads().executeQuery()[0];
        Opportunity opp = (Opportunity) new OpportunitySelector().selectOpportunities().executeQuery()[0];
        createCPUMonitor(acc, con, ld, opp, true, false);
        Test.startTest();
        LeadConversionMonitoringHelper.publishLeadConversionPlatformEvent(
            4000,
            40,
            acc.Id,
            con.Id,
            opp.Id,
            ld.Id,
            2,
            'There was an error',
            'This is the error stacktrace',
            true,
            false,
            false,
            false,
            LeadConversionMonitoringHelper.ACCOUNT_NAME
        );
        Test.stopTest();
        CPU_Monitor__c cpuMonitor = (CPU_Monitor__c) new CPUMonitorSelector()
            .selectCPUMonitorForLeadConversionMonitor(new List<Id>{ld.Id})
            .selectField('Error_stacktrace__c')
            .selectField('Error_Part__c')
            .executeQuery()[0];
        System.assertEquals(5000, cpuMonitor.CPU_Usage__c, 'The amount of CPU Usage is not correct');
        System.assertEquals(50, cpuMonitor.SOQL_Queries__c, 'The amount of SOQL Queries is not correct');
        System.assertEquals('There was an error', cpuMonitor.Error__c, 'There should be an error');
        System.assertEquals('This is the error stacktrace', cpuMonitor.Error_stacktrace__c, 'There should be an error stacktrace');
        System.assertEquals('CreateAccount', cpuMonitor.Error_Part__c, 'The error should be in ConvertLead part');
    }

    @isTest
    static void testCPUMonitorWithErrorInExistingOpportunity() {
        Account acc = (Account) new AccountSelector().selectAccounts().executeQuery()[0];
        Contact con = (Contact) new ContactSelector().selectContacts().executeQuery()[0];
        Lead ld = (Lead) new LeadSelector().selectLeads().executeQuery()[0];
        Opportunity opp = (Opportunity) new OpportunitySelector().selectOpportunities().executeQuery()[0];
        createCPUMonitor(acc, con, ld, opp, false, false);
        Test.startTest();
        LeadConversionMonitoringHelper.publishLeadConversionPlatformEvent(
            4000,
            40,
            acc.Id,
            con.Id,
            opp.Id,
            ld.Id,
            2,
            'There was an error',
            'This is the error stacktrace',
            true,
            false,
            false,
            false,
            LeadConversionMonitoringHelper.OPPORTUNITY_NAME
        );
        Test.stopTest();
        CPU_Monitor__c cpuMonitor = (CPU_Monitor__c) new CPUMonitorSelector()
            .selectCPUMonitorForLeadConversionMonitor(new List<Id>{ld.Id})
            .selectField('Error_stacktrace__c')
            .selectField('Error_Part__c')
            .executeQuery()[0];
        System.assertEquals(5000, cpuMonitor.CPU_Usage__c, 'The amount of CPU Usage is not correct');
        System.assertEquals(50, cpuMonitor.SOQL_Queries__c, 'The amount of SOQL Queries is not correct');
        System.assertEquals('There was an error', cpuMonitor.Error__c, 'There should be an error');
        System.assertEquals('This is the error stacktrace', cpuMonitor.Error_stacktrace__c, 'There should be an error stacktrace');
        System.assertEquals('ExistingOpportunity', cpuMonitor.Error_Part__c, 'The error should be in ConvertLead part');
    }

    @isTest
    static void testCPUMonitorWithErrorInCreateOpportunity() {
        Account acc = (Account) new AccountSelector().selectAccounts().executeQuery()[0];
        Contact con = (Contact) new ContactSelector().selectContacts().executeQuery()[0];
        Lead ld = (Lead) new LeadSelector().selectLeads().executeQuery()[0];
        Opportunity opp = (Opportunity) new OpportunitySelector().selectOpportunities().executeQuery()[0];
        createCPUMonitor(acc, con, ld, opp, false, true);
        Test.startTest();
        LeadConversionMonitoringHelper.publishLeadConversionPlatformEvent(
            4000,
            40,
            acc.Id,
            con.Id,
            opp.Id,
            ld.Id,
            2,
            'There was an error',
            'This is the error stacktrace',
            true,
            true,
            false,
            false,
            LeadConversionMonitoringHelper.OPPORTUNITY_NAME
        );
        Test.stopTest();
        CPU_Monitor__c cpuMonitor = (CPU_Monitor__c) new CPUMonitorSelector()
            .selectCPUMonitorForLeadConversionMonitor(new List<Id>{ld.Id})
            .selectField('Error_stacktrace__c')
            .selectField('Error_Part__c')
            .executeQuery()[0];
        System.assertEquals(5000, cpuMonitor.CPU_Usage__c, 'The amount of CPU Usage is not correct');
        System.assertEquals(50, cpuMonitor.SOQL_Queries__c, 'The amount of SOQL Queries is not correct');
        System.assertEquals('There was an error', cpuMonitor.Error__c, 'There should be an error');
        System.assertEquals('This is the error stacktrace', cpuMonitor.Error_stacktrace__c, 'There should be an error stacktrace');
        System.assertEquals('CreateOpportunity', cpuMonitor.Error_Part__c, 'The error should be in ConvertLead part');
    }

    @isTest
    static void testGetLastErrorLeadConversionCPUMonitor() {
        Account acc = (Account) new AccountSelector().selectAccounts().executeQuery()[0];
        Contact con = (Contact) new ContactSelector().selectContacts().executeQuery()[0];
        Lead ld = (Lead) new LeadSelector().selectLeads().executeQuery()[0];
        Opportunity opp = (Opportunity) new OpportunitySelector().selectOpportunities().executeQuery()[0];
        CPU_Monitor__c cpuMonitor1 = createCPUMonitor(acc, con, ld, opp, false, false);
        CPU_Monitor__c cpuMonitor2 = createCPUMonitor(acc, con, ld, opp, false, false);
        CPU_Monitor__c cpuMonitor3 = createCPUMonitor(acc, con, ld, opp, false, false);
        Test.setCreatedDate(cpuMonitor1.Id, DateTime.now().addMinutes(-10));
        Test.setCreatedDate(cpuMonitor2.Id, DateTime.now().addMinutes(-5));
        Test.startTest();
        cpuMonitor2.Error__c = 'This run had an error';
        update cpuMonitor2;
        CPU_Monitor__c cpuMonitorToTest = LeadConversionMonitoringHelper.getLastErrorLeadConversionCPUMonitor();
        Test.stopTest();
        System.assertEquals(cpuMonitor2.Id, cpuMonitorToTest.Id, 'Ids should match with the last record of CPU Monitor that has an error');
    }

    @isTest
    static void testGetCPUMonitorByRecordId() {
        Account acc = (Account) new AccountSelector().selectAccounts().executeQuery()[0];
        Contact con = (Contact) new ContactSelector().selectContacts().executeQuery()[0];
        Lead ld = (Lead) new LeadSelector().selectLeads().executeQuery()[0];
        Opportunity opp = (Opportunity) new OpportunitySelector().selectOpportunities().executeQuery()[0];
        Test.startTest();
        CPU_Monitor__c cpuMonitor1 = createCPUMonitor(acc, con, ld, opp, false, false);
        CPU_Monitor__c cpuMonitor2 = createCPUMonitor(acc, con, ld, opp, false, false);
        Test.stopTest();
        CPU_Monitor__c cpuMonitorToTest = LeadConversionMonitoringHelper.getCPUMonitorByRecordId(cpuMonitor1.Id);
        System.assertEquals(cpuMonitor1.Id, cpuMonitorToTest.Id, 'Ids should match with the last record of CPU Monitor created');
    }

    @isTest
    static void testValidationError() {
        Account acc = (Account) new AccountSelector().selectAccounts().executeQuery()[0];
        Contact con = (Contact) new ContactSelector().selectContacts().executeQuery()[0];
        Lead ld = (Lead) new LeadSelector().selectLeads().executeQuery()[0];
        Opportunity opp = (Opportunity) new OpportunitySelector().selectOpportunities().executeQuery()[0];
        createCPUMonitor(acc, con, ld, opp, false, false);
        Test.startTest();
        LeadConversionMonitoringHelper.publishLeadConversionPlatformEvent(
            4000,
            40,
            acc.Id,
            con.Id,
            opp.Id,
            ld.Id,
            2,
            'There was an error in' + LeadConversionMonitoringHelper.VALIDATION_ERROR,
            'This is the error stacktrace',
            true,
            false,
            false,
            false,
            LeadConversionMonitoringHelper.OPPORTUNITY_NAME
        );
        Test.stopTest();
        List<CPU_Monitor__c> cpuMonitorList = (List<CPU_Monitor__c>) new CPUMonitorSelector()
            .selectCPUMonitorForLeadConversionMonitor(new List<Id>{ ld.Id })
            .executeQuery();
        System.assertEquals(
            0,
            cpuMonitorList.size(),
            'The CPU Monitor record should be deleted if there are validation errors'
        );
    }

    @isTest
    static void testSOQLLimitsError() {
        Account acc = (Account) new AccountSelector().selectAccounts().executeQuery()[0];
        Contact con = (Contact) new ContactSelector().selectContacts().executeQuery()[0];
        Lead ld = (Lead) new LeadSelector().selectLeads().executeQuery()[0];
        Opportunity opp = (Opportunity) new OpportunitySelector().selectOpportunities().executeQuery()[0];
        createCPUMonitor(acc, con, ld, opp, false, false);
        Test.startTest();
        ConvertLeadController.publishLimitsError(
            ld.Id,
            LeadConversionMonitoringHelper.SOQL_EXCEPTION,
            LeadConversionMonitoringHelper.LIMIT_EXCEPTION,
            'convertPart2'
        );
        Test.stopTest();
        CPU_Monitor__c cpuMonitor = (CPU_Monitor__c) new CPUMonitorSelector()
            .selectCPUMonitorForLeadConversionMonitor(new List<Id>{ ld.Id })
            .selectField('Queries_Convert_Part__c')
            .selectField('Notes__c')
            .executeQuery()[0];
        System.assertEquals(101, cpuMonitor.SOQL_Queries__c, 'The amount of SOQL Queries is not correct');
        System.assertEquals(
            'convertPart2',
            cpuMonitor.Queries_Convert_Part__c,
            'The convert part for SOQL Queries is not correct'
        );
        System.assertEquals(
            'Lead was converted to Opportunity. Error found in Field Mapping or Contact Role creation.',
            cpuMonitor.Notes__c,
            'The Notes field value is not correct'
        );
    }

    @isTest
    static void testCPULimitsError() {
        Account acc = (Account) new AccountSelector().selectAccounts().executeQuery()[0];
        Contact con = (Contact) new ContactSelector().selectContacts().executeQuery()[0];
        Lead ld = (Lead) new LeadSelector().selectLeads().executeQuery()[0];
        Opportunity opp = (Opportunity) new OpportunitySelector().selectOpportunities().executeQuery()[0];
        createCPUMonitor(acc, con, ld, opp, false, false);
        Test.startTest();
        ConvertLeadController.publishLimitsError(
            ld.Id,
            LeadConversionMonitoringHelper.CPU_EXCEPTION,
            LeadConversionMonitoringHelper.LIMIT_EXCEPTION,
            'convertPart3'
        );
        Test.stopTest();
        CPU_Monitor__c cpuMonitor = (CPU_Monitor__c) new CPUMonitorSelector()
            .selectCPUMonitorForLeadConversionMonitor(new List<Id>{ ld.Id })
            .selectField('CPU_Convert_part__c')
            .selectField('Notes__c')
            .executeQuery()[0];
        System.assertEquals(10000, cpuMonitor.CPU_Usage__c, 'The amount of CPU Time is not correct');
        System.assertEquals(
            'convertPart3',
            cpuMonitor.CPU_Convert_part__c,
            'The convert part for CPU Time is not correct'
        );
        System.assertEquals(
            'Lead was converted to Opportunity. Quote Creation failed.',
            cpuMonitor.Notes__c,
            'The Notes field value is not correct'
        );
    }

    static CPU_Monitor__c createCPUMonitor(Account acc, Contact con, Lead ld, Opportunity opp, Boolean createAccount, Boolean createOpportunity) {
        return (CPU_Monitor__c) new SObjectBuilder(CPU_Monitor__c.SObjectType)
            .setField(CPU_Monitor__c.Name, 'Monitor Lead Conversion')
            .setField(CPU_Monitor__c.Transaction_Type__c, 'Lead Conversion')
            .setField(CPU_Monitor__c.CPU_Usage__c, 5000)
            .setField(CPU_Monitor__c.SOQL_Queries__c, 50)
            .setField(CPU_Monitor__c.Account__c, acc.Id)
            .setField(CPU_Monitor__c.Contact__c, con.Id)
            .setField(CPU_Monitor__c.Lead__c, ld.Id)
            .setField(CPU_Monitor__c.Opportunity__c, opp.Id)
            .setField(CPU_Monitor__c.CPU_Convert_Part__c, 'prepareLeadRecord')
            .setField(CPU_Monitor__c.Queries_Convert_Part__c, 'prepareLeadRecord')
            .setField(CPU_Monitor__c.Create_Account__c, createAccount)
            .setField(CPU_Monitor__c.Create_Opportunity__c, createOpportunity)
            .create()
            .getRecord();
    }

    @testSetup
    static void sobjCreation() {
        Account testAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object>{ Account.Name => 'Test account' })
            .create()
            .getRecord();

        Contact testContact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.FirstName => 'Test',
                    Contact.LastName => 'Contact',
                    Contact.AccountId => testAccount.Id,
                    Contact.Email => 'test@test.com',
                    Contact.Phone => '+18885550505'
                }
            )
            .create()
            .getRecord();

        Lead testLead = (Lead) new SObjectBuilder(Lead.SObjectType)
            .setField(Lead.LastName, 'Test Lead')
            .setField(Lead.Email, 'test@testLead.com')
            .setField(Lead.Phone, '+25468954654')
            .create()
            .getRecord();

        Opportunity testOpp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setField(Opportunity.Name, 'Test Opportunity')
            .setField(Opportunity.Type, 'Syndicated - New')
            .setField(Opportunity.StageName, 'Planning')
            .setField(Opportunity.CloseDate, System.today().addMonths(1))
            .setField(Opportunity.AccountId, testAccount.Id)
            .create()
            .getRecord();
    }
}