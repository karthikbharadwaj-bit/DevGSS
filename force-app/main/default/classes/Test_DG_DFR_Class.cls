@isTest
private class Test_DG_DFR_Class {

    @testSetup
    static void setupData() {
        Test_DemandFunnelHelper.createSDRUser();
        Test_DemandFunnelHelper.createBDRUser();
        Test_DemandFunnelHelper.createAEUser();
    }

    // @isTest
    // static void smEmployeesUpdate_whenDeleteLead_shouldBlankSMEmployees() {
    //     Test.startTest();
    //     Lead ld = (Lead) new SObjectBuilder(Lead.SObjectType)
    //         .setField(Lead.LastName, Test_DemandFunnelHelper.LEADLASTNAME)
    //         .setField(Lead.Status, LeadTriggerHelper.LEADSTATUSCONTACTED)
    //         .setField(Lead.Email, Test_DemandFunnelHelper.LEADEMAIL)
    //         .setField(Lead.Phone, Test_DemandFunnelHelper.LEADPHONE)
    //         .setField(Lead.Test_DemandFunnelHelper.LEADSOURCE, Test_DemandFunnelHelper.LEADSOURCE)
    //         .create()
    //         .getRecord();

    //     Id ldId = ld.Id;
    //     Test.stopTest();
    //     List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRs(ld, new List<String>{ 'SM_Employees__c' });
    //     delete ld;
    //     dfrList[0].Lead__c = ldId;
    //     update dfrList;
    //     DemandFunnelSelector selectDFR = new DemandFunnelSelector();
    //     List<Demand_Funnel__c> dfrUpdated = selectDFR
    //         .selectDFRByLeadID(new List<Id>{ ldId })
    //         .selectField('SM_Employees__c')
    //         .executeQuery();
    //     System.assertEquals(null, dfrUpdated[0].SM_Employees__c, 'SM Employees value is not correct');
    // }

    @isTest
    static void smEmployeesUpdate_whenFromLead_ShouldUpdateSMEmployees() {
        Lead ld = (Lead) new SObjectBuilder(Lead.SObjectType)
            .setField(Lead.LastName, Test_DemandFunnelHelper.LEADLASTNAME)
            .setField(Lead.Status, LeadTriggerHelper.LEADSTATUSCONTACTED)
            .setField(Lead.Email, Test_DemandFunnelHelper.LEADEMAIL)
            .setField(Lead.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Lead.Test_DemandFunnelHelper.LEADSOURCE, Test_DemandFunnelHelper.LEADSOURCE)
            .setField(Lead.Emp_Range_Sales_Override__c, 10)
            .create()
            .getRecord();

        Test.startTest();
        ld.Emp_Range_Sales_Override__c = 50;
        update ld;
        Test.stopTest();

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRs(ld, new List<String>{ 'SM_Employees__c' });
        System.assertEquals(50, dfrList[0].SM_Employees__c, 'SM Employees value is not correct');
    }

    @isTest
    static void smEmployeesUpdate_whenLeadCreation_shouldPopulateSMEmployees() {
        Test.startTest();
        Lead ld = (Lead) new SObjectBuilder(Lead.SObjectType)
            .setField(Lead.LastName, Test_DemandFunnelHelper.LEADLASTNAME)
            .setField(Lead.Status, LeadTriggerHelper.LEADSTATUSCONTACTED)
            .setField(Lead.Email, Test_DemandFunnelHelper.LEADEMAIL)
            .setField(Lead.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Lead.Test_DemandFunnelHelper.LEADSOURCE, Test_DemandFunnelHelper.LEADSOURCE)
            .setField(Lead.Emp_Range_Sales_Override__c, 10)
            .create()
            .getRecord();
        Test.stopTest();

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRs(ld, new List<String>{ 'SM_Employees__c' });
        System.assertEquals(10, dfrList[0].SM_Employees__c, 'SM Employees value is not correct');
    }

    // @isTest
    // static void smEmployeesUpdate_whenUpdateLeadZICDPAccount_shouldUpdateSMEmployees() {

    //     Account acc = (Account) new SObjectBuilder(Account.SObjectType)
    //         .setField(Account.Name, 'Test Account')
    //         .setField(Account.Emp_Range_Sales_Override__c, 100)
    //         .create()
    //         .getRecord();

    //     Account acc2 = (Account) new SObjectBuilder(Account.SObjectType)
    //         .setField(Account.Name, 'Test Account2')
    //         .setField(Account.Emp_Range_Sales_Override__c, 50)
    //         .create()
    //         .getRecord();

    //     Lead ld = (Lead) new SObjectBuilder(Lead.SObjectType)
    //         .setField(Lead.LastName, Test_DemandFunnelHelper.LEADLASTNAME)
    //         .setField(Lead.Status, LeadTriggerHelper.LEADSTATUSCONTACTED)
    //         .setField(Lead.Email, Test_DemandFunnelHelper.LEADEMAIL)
    //         .setField(Lead.Phone, Test_DemandFunnelHelper.LEADPHONE)
    //         .setField(Lead.Test_DemandFunnelHelper.LEADSOURCE, Test_DemandFunnelHelper.LEADSOURCE)
    //         .setField(Lead.ZI_CDP_Account_Id__c, acc.Id)
    //         .create()
    //         .getRecord();

    //     Test.startTest();
    //         ld.ZI_CDP_Account_Id__c = acc2.Id;
    //         update ld;
    //     Test.stopTest();

    //     List<Demand_Funnel__c> dfrList = new DemandFunnelSelector()
    //         .selectDFRByLeadAccountOrOpportunity(new Object[]{ new Set<Id>{ ld.Id } })
    //         .selectField('SM_Employees__c')
    //         .executeQuery();

    //     System.assertEquals(50, dfrList[0].SM_Employees__c, 'SM Employees value is not correct');
    // }

    @isTest
    static void smEmployeesUpdate_whenFromAccount_shouldUpdateSMEmployees() {
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setField(Account.Name, 'Test Account')
            .setField(Account.Emp_Range_Sales_Override__c, 50)
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setField(Opportunity.Name, 'Test Opportunity')
            .setField(Opportunity.Type, 'Syndicated - New')
            .setField(Opportunity.StageName, 'Planning')
            .setField(Opportunity.AccountId, acc.Id)
            .setField(Opportunity.CloseDate, System.today().addMonths(1))
            .create()
            .getRecord();

        Demand_Funnel__c dfr = (Demand_Funnel__c) new SObjectBuilder(Demand_Funnel__c.SObjectType)
            .setField(Demand_Funnel__c.Opportunity__c, opp.Id)
            .create()
            .getRecord();

        DemandFunnelSelector selectDFR = new DemandFunnelSelector();
        List<Demand_Funnel__c> newDFRs = selectDFR
            .selectDFRById(new List<Id>{ dfr.Id })
            .selectField('SM_Employees__c')
            .executeQuery();

        System.assertEquals(50, newDFRs[0].SM_Employees__c, 'SM Employees value is not correct');

        Test.startTest();
            TriggerHandler.BY_PASS_ACCOUNT_ON_AFTER = false;
            TriggerHandler.BY_PASS_ACCOUNT_ON_UPDATE = false;
            TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT = false;
            acc.Emp_Range_Sales_Override__c = 100;
            update acc;
        Test.stopTest();

        List<Demand_Funnel__c> dfrList = selectDFR
            .selectDFRByLeadAccountOrOpportunity(new List<Set<Id>>{ new Set<Id>{ acc.Id } })
            .selectField('SM_Employees__c')
            .executeQuery();
        System.assertEquals(100, dfrList[0].SM_Employees__c, 'SM Employees value is not correct');
    }

    @isTest
    static void smEmployeesUpdate_whenFromUltimateAccount_shouldUpdateSMEmployees() {
        Account ultimateAcc = (Account) new SObjectBuilder(Account.SObjectType)
            .setField(Account.Name, 'Test Account')
            .setField(Account.Emp_Range_Sales_Override__c, 50)
            .create()
            .getRecord();

        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setField(Account.Name, 'Test Account')
            .setField(Account.ParentId, ultimateAcc.Id)
            .setField(Account.Ultimate_Account__c, ultimateAcc.Id)
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setField(Opportunity.Name, 'Test Opportunity')
            .setField(Opportunity.Type, 'Syndicated - New')
            .setField(Opportunity.StageName, 'Planning')
            .setField(Opportunity.AccountId, acc.Id)
            .setField(Opportunity.CloseDate, System.today().addMonths(1))
            .create()
            .getRecord();

        Demand_Funnel__c dfr = (Demand_Funnel__c) new SObjectBuilder(Demand_Funnel__c.SObjectType)
            .setField(Demand_Funnel__c.Opportunity__c, opp.Id)
            .create()
            .getRecord();


        DemandFunnelSelector selectDFR = new DemandFunnelSelector();

        List<Demand_Funnel__c> newDFRs = selectDFR
            .selectDFRById(new List<Id>{ dfr.Id })
            .selectField('SM_Employees__c')
            .executeQuery();

        System.assertEquals(50, newDFRs[0].SM_Employees__c, 'SM Employees value is not correct');

        Test.startTest();
            TriggerHandler.BY_PASS_ACCOUNT_ON_AFTER = false;
            TriggerHandler.BY_PASS_ACCOUNT_ON_UPDATE = false;
            TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT = false;
            ultimateAcc.Emp_Range_Sales_Override__c = 100;
            update ultimateAcc;
        Test.stopTest();

        List<Demand_Funnel__c> dfrList = selectDFR
            .selectDFRByLeadAccountOrOpportunity(new Object[]{ new Set<Id>{ acc.Id } })
            .selectField('SM_Employees__c')
            .executeQuery();
        System.assertEquals(100, dfrList[0].SM_Employees__c, 'SM Employees value is not correct');
    }

    // @isTest
    // static void smEmployeesUpdate_whenUpdateOpportunityAccount_shouldUpdateSMEmployees() {
    //     Account dfrAccount = (Account) new SObjectBuilder(Account.SObjectType)
    //         .setField(Account.Name, 'DFR Account')
    //         .setField(Account.Emp_Range_Sales_Override__c, 50)
    //         .create()
    //         .getRecord();

    //     Account oppAccount = (Account) new SObjectBuilder(Account.SObjectType)
    //         .setField(Account.Name, 'Opp Account')
    //         .setField(Account.Emp_Range_Sales_Override__c, 100)
    //         .create()
    //         .getRecord();

    //     Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
    //         .setField(Opportunity.Name, 'Test Opportunity')
    //         .setField(Opportunity.Type, 'Syndicated - New')
    //         .setField(Opportunity.StageName, 'Planning')
    //         .setField(Opportunity.AccountId, dfrAccount.Id)
    //         .setField(Opportunity.CloseDate, System.today().addMonths(1))
    //         .create()
    //         .getRecord();

    //     Demand_Funnel__c dfr = (Demand_Funnel__c) new SObjectBuilder(Demand_Funnel__c.SObjectType)
    //         .setField(Demand_Funnel__c.Opportunity__c, opp.Id)
    //         .create()
    //         .getRecord();

    //     DemandFunnelSelector selectDFR = new DemandFunnelSelector();

    //     List<Demand_Funnel__c> newDFRs = selectDFR
    //         .selectDFRById(new List<Id>{ dfr.Id })
    //         .selectField('SM_Employees__c')
    //         .executeQuery();
    //     System.assertEquals(50, newDFRs[0].SM_Employees__c, 'SM Employees value is not correct');

    //     Test.startTest();
    //         opp.AccountId = oppAccount.Id;
    //         update opp;
    //     Test.stopTest();

    //     List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRsByOpportunity(opp, new List<String>{ 'SM_Employees__c' });
    //     System.assertEquals(100, dfrList[0].SM_Employees__c, 'SM Employees value is not correct');
    // }

    @isTest
    static void smEmployeesUpdate_whenUpdateOpportunityEmpRangeSalesOverride_shouldUpdateSmEmployeesOnDFR() {
        Account oppAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setField(Account.Name, 'Opp Account')
            .setField(Account.Emp_Range_Sales_Override__c, 100)
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
        .setField(Opportunity.Name, 'Test Opportunity')
        .setField(Opportunity.Type, 'Syndicated - New')
        .setField(Opportunity.StageName, 'Planning')
        .setField(Opportunity.AccountId, oppAccount.Id)
        .setField(Opportunity.CloseDate, System.today().addMonths(1))
        .create()
        .getRecord();

        Demand_Funnel__c dfr = (Demand_Funnel__c) new SObjectBuilder(Demand_Funnel__c.SObjectType)
            .setField(Demand_Funnel__c.Opportunity__c, opp.Id)
            .create()
            .getRecord();

        DemandFunnelSelector selectDFR = new DemandFunnelSelector();
        List<Demand_Funnel__c> newDFRs = selectDFR
            .selectDFRById(new List<Id>{ dfr.Id })
            .selectField('SM_Employees__c')
            .executeQuery();

        System.assertEquals(100, newDFRs[0].SM_Employees__c, 'SM Employees value is not correct');

        Test.startTest();
            TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT = false;
            TriggerHandler.BY_PASS_ACCOUNT_ON_UPDATE = false;
            TriggerHandler.BY_PASS_ACCOUNT_ON_AFTER  = false;
            oppAccount.Emp_Range_Sales_Override__c = 150;
            update oppAccount;
        Test.stopTest();

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRsByOpportunity(opp, new List<String>{ 'SM_Employees__c' });
        System.assertEquals(150, dfrList[0].SM_Employees__c, 'SM Employees value is not correct');
    }

    @isTest
    static void smEmployeesUpdate_whenUpdateOpportunityParentAccount_shouldUpdateSMEmployees() {
        Account parentAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setField(Account.Name, 'Parent Account')
            .setField(Account.Emp_Range_Sales_Override__c, 100)
            .create()
            .getRecord();

        Account oppAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setField(Account.Name, 'Opp Account')
            .setField(Account.ParentId, parentAccount.Id)
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setField(Opportunity.Name, 'Test Opportunity')
            .setField(Opportunity.Type, 'Syndicated - New')
            .setField(Opportunity.StageName, 'Planning')
            .setField(Opportunity.AccountId, oppAccount.Id)
            .setField(Opportunity.CloseDate, System.today().addMonths(1))
            .create()
            .getRecord();

        Demand_Funnel__c dfr = (Demand_Funnel__c) new SObjectBuilder(Demand_Funnel__c.SObjectType)
            .setField(Demand_Funnel__c.Opportunity__c, opp.Id)
            .create()
            .getRecord();

        Test.startTest();
            TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT = false;
            TriggerHandler.BY_PASS_ACCOUNT_ON_UPDATE = false;
            TriggerHandler.BY_PASS_ACCOUNT_ON_AFTER  = false;
            parentAccount.Emp_Range_Sales_Override__c = 150;
            update parentAccount;
        Test.stopTest();
        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRsByOpportunity(opp, new List<String>{ 'SM_Employees__c' });
        System.assertEquals(150, dfrList[0].SM_Employees__c, 'SM Employees value is not correct');
    }

    @isTest
    static void smEmployeesUpdate_whenUpdateParentAccount_shouldUpdateSMEmployees() {
        Account parentAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setField(Account.Name, 'Parent Account')
            .setField(Account.Emp_Range_Sales_Override__c, 100)
            .create()
            .getRecord();

        Account mainAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setField(Account.Name, 'Opp Account')
            .setField(Account.ParentId, parentAccount.Id)
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setField(Opportunity.Name, 'Test Opportunity')
            .setField(Opportunity.Type, 'Syndicated - New')
            .setField(Opportunity.StageName, 'Planning')
            .setField(Opportunity.AccountId, mainAccount.Id)
            .setField(Opportunity.CloseDate, System.today().addMonths(1))
            .create()
            .getRecord();

        Demand_Funnel__c dfr = (Demand_Funnel__c) new SObjectBuilder(Demand_Funnel__c.SObjectType)
            .setField(Demand_Funnel__c.Opportunity__c, opp.Id)
            .create()
            .getRecord();

        Test.startTest();
            TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT = false;
            TriggerHandler.BY_PASS_ACCOUNT_ON_UPDATE = false;
            TriggerHandler.BY_PASS_ACCOUNT_ON_AFTER  = false;
            parentAccount.Emp_Range_Sales_Override__c = 150;
            update parentAccount;
        Test.stopTest();
        List<Demand_Funnel__c> dfrList = (List<Demand_Funnel__c>) new DemandFunnelSelector().selectDFRById(new List<Object>{ dfr.Id })
                                                                    .selectField('SM_Employees__c').executeQuery();
        System.assertEquals(150, dfrList[0].SM_Employees__c, 'SM Employees value is not correct');
    }

    @isTest
    static void smEmployeesUpdate_whenUpdateLeadParentAccount_shouldUpdateSMEmployees() {
        Account parentAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setField(Account.Name, 'Parent Account')
            .setField(Account.ZI_Employees__c, 100)
            .create()
            .getRecord();

        Lead ld = (Lead) new SObjectBuilder(Lead.SObjectType)
            .setField(Lead.Status, LeadTriggerHelper.LEADSTATUSOPEN)
            .setField(Lead.LastName, Test_DemandFunnelHelper.LEADLASTNAME)
            .setField(Lead.Email, Test_DemandFunnelHelper.LEADEMAIL)
            .setField(Lead.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Lead.Test_DemandFunnelHelper.LEADSOURCE, Test_DemandFunnelHelper.LEADSOURCE)
            .setField(Lead.ZI_CDP_Account_Id__c, parentAccount.Id)
            .create()
            .getRecord();

        Test.startTest();
            TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT = false;
            TriggerHandler.BY_PASS_ACCOUNT_ON_UPDATE = false;
            TriggerHandler.BY_PASS_ACCOUNT_ON_AFTER  = false;
            parentAccount.ZI_Employees__c = 150;
            update parentAccount;
        Test.stopTest();

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRs(ld, new List<String> {'SM_Employees__c'});
        List<Lead> dfrLeads = (List<Lead>) new LeadSelector().selectLeadById(new List<String> {ld.Id})
                                        .selectField('SM_Employees__c').executeQuery();
        System.assertEquals(dfrLeads[0].SM_Employees__c, dfrList[0].SM_Employees__c, 'SM Employees value is not correct');
    }
    @isTest
    static void smEmployeesUpdate_whenUpdateFromUltimateAccount_shouldUpdateSMEmployees() {
        Account ultimateAcc = (Account) new SObjectBuilder(Account.SObjectType)
            .setField(Account.Name, 'Test Account')
            .setField(Account.Emp_Range_Sales_Override__c, 50)
            .create()
            .getRecord();

        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setField(Account.Name, 'Test Account')
            .setField(Account.ParentId, ultimateAcc.Id)
            .setField(Account.Ultimate_Account__c, ultimateAcc.Id)
            .create()
            .getRecord();

        Lead ld = (Lead) new SObjectBuilder(Lead.SObjectType)
            .setField(Lead.LastName, Test_DemandFunnelHelper.LEADLASTNAME)
            .setField(Lead.Status, LeadTriggerHelper.LEADSTATUSCONTACTED)
            .setField(Lead.Email, Test_DemandFunnelHelper.LEADEMAIL)
            .setField(Lead.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Lead.Test_DemandFunnelHelper.LEADSOURCE, Test_DemandFunnelHelper.LEADSOURCE)
            .setField(Lead.ZI_CDP_Account_Id__c, acc.Id)
            .create()
            .getRecord();

        Demand_Funnel__c dfr = (Demand_Funnel__c) new SObjectBuilder(Demand_Funnel__c.SObjectType)
            .setField(Demand_Funnel__c.Lead__c, ld.Id)
            .create()
            .getRecord();


        DemandFunnelSelector selectDFR = new DemandFunnelSelector();

        List<Demand_Funnel__c> newDFRs = selectDFR
            .selectDFRById(new List<Id>{ dfr.Id })
            .selectField('SM_Employees__c')
            .executeQuery();

        System.assertEquals(50, newDFRs[0].SM_Employees__c, 'SM Employees value is not correct');

        Test.startTest();
            TriggerHandler.BY_PASS_ACCOUNT_ON_AFTER = false;
            TriggerHandler.BY_PASS_ACCOUNT_ON_UPDATE = false;
            TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT = false;
            ultimateAcc.Emp_Range_Sales_Override__c = 100;
            update ultimateAcc;
        Test.stopTest();

        List<Demand_Funnel__c> dfrList = selectDFR
            .selectDFRByLeadAccountOrOpportunity(new Object[]{ new Set<Id>{ acc.Id } })
            .selectField('SM_Employees__c')
            .executeQuery();
        System.assertEquals(100, dfrList[0].SM_Employees__c, 'SM Employees value is not correct');
    }

    @isTest
    static void testDemandFunnelTriggerByPassPositive() {
        User aeUser = Test_DemandFunnelHelper.getUser(Test_DemandFunnelHelper.AELASTNAME);
        ByPassTrigger__c bypassTrigger = ByPassTrigger__c.getInstance(UserInfo.getOrganizationId());
        bypassTrigger.Bypass_DemandFunnel_Trigger__c = true;
        upsert bypassTrigger;
        Lead ld = (Lead) new SObjectBuilder(Lead.SObjectType)
            .setField(Lead.OwnerId, aeUser.Id)
            .setField(Lead.Status, LeadTriggerHelper.LEADSTATUSOPEN)
            .setField(Lead.LastName, Test_DemandFunnelHelper.LEADLASTNAME)
            .setField(Lead.Email, Test_DemandFunnelHelper.LEADEMAIL)
            .setField(Lead.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Lead.Test_DemandFunnelHelper.LEADSOURCE, Test_DemandFunnelHelper.LEADSOURCE)
            .create()
            .getRecord();

        test.startTest();
        ld.Status = LeadTriggerHelper.LEADSTATUSCONTACTED;
        update ld;
        test.stopTest();
        List<Exception_and_Notification_history__c> dfrFieldTrackingRecords = (List<Exception_and_notification_history__c>) new ExceptionAndNotificationHistorySelector()
        .selectExceptionAndNotificationHistorys()
        .executeQuery();
        System.assertEquals(0, dfrFieldTrackingRecords.size(), 'Trigger its not beign bypassed, FieldTracking Records were created');
    }

    @isTest
    static void testDemandFunnelTriggerByPassNegative() {
        User aeUser = Test_DemandFunnelHelper.getUser(Test_DemandFunnelHelper.AELASTNAME);
        ByPassTrigger__c bypassTrigger = ByPassTrigger__c.getInstance(UserInfo.getOrganizationId());
        bypassTrigger.Bypass_DemandFunnel_Trigger__c = false;
        upsert bypassTrigger;
        Lead ld = (Lead) new SObjectBuilder(Lead.SObjectType)
            .setField(Lead.OwnerId, aeUser.Id)
            .setField(Lead.Status, LeadTriggerHelper.LEADSTATUSOPEN)
            .setField(Lead.LastName, Test_DemandFunnelHelper.LEADLASTNAME)
            .setField(Lead.Email, Test_DemandFunnelHelper.LEADEMAIL)
            .setField(Lead.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Lead.Test_DemandFunnelHelper.LEADSOURCE, Test_DemandFunnelHelper.LEADSOURCE)
            .create()
            .getRecord();

        test.startTest();
        ld.Status = LeadTriggerHelper.LEADSTATUSCONTACTED;
        update ld;
        test.stopTest();
        List<Exception_and_Notification_history__c> dfrFieldTrackingRecords = (List<Exception_and_notification_history__c>) new ExceptionAndNotificationHistorySelector()
        .selectExceptionAndNotificationHistorys()
        .executeQuery();
        System.assertEquals(1, dfrFieldTrackingRecords.size(), 'Trigger its beign bypassed, FieldTracking Records are not created');
    }

    @isTest
    static void contactShouldBeCustomerWhenAccountPaidStatus() {
        Account testAcc = Test_DemandFunnelHelper.createTestAccount();
        test.startTest();
        Contact con = Test_DemandFunnelHelper.createTestContact(testAcc);
        test.stopTest();
        testAcc.RC_Account_Status__c = 'Paid';
        update testAcc;
        Test.getEventBus().deliver();

        Contact checkContact = Test_DemandFunnelHelper.getTestContact(testAcc);
        List<Demand_Funnel__c> dfrs = Test_DemandFunnelHelper.getDFRsByContact(new List<Contact>{checkContact}, new List<String>{ 'DET_Current_Funnel_Status__c', 'EOL_Entered_From__c' });
        System.assertEquals('4. Customer', checkContact.Contact_Status__c, 'Contact status should be 4. Customer.');
        System.assertEquals('7 - Customer', dfrs[0].DET_Current_Funnel_Status__c, 'DFR status should be 7. Customer.');
    }

    @isTest
    static void contactShouldBeCustomerWhenRcUpgradeDatePopulates() {
        Account testAcc = Test_DemandFunnelHelper.createTestAccount();
        test.startTest();
        Contact con = Test_DemandFunnelHelper.createTestContact(testAcc);
        test.stopTest();
        testAcc.RC_Upgrade_Date__c = System.now();
        update testAcc;
        Test.getEventBus().deliver();

        Contact checkContact = Test_DemandFunnelHelper.getTestContact(testAcc);
        List<Demand_Funnel__c> dfrs = Test_DemandFunnelHelper.getDFRsByContact(new List<Contact>{checkContact}, new List<String>{ 'DET_Current_Funnel_Status__c', 'EOL_Entered_From__c' });
        System.assertEquals('4. Customer', checkContact.Contact_Status__c, 'Contact status should be 4. Customer.');
        System.assertEquals('7 - Customer', dfrs[0].DET_Current_Funnel_Status__c, 'DFR status should be 7. Customer.');
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testContactStatusDowngradedWhenAccountIsCancel() {
        Account acc = Test_DemandFunnelHelper.createTestAccount();
        Test.startTest();
        Contact con = Test_DemandFunnelHelper.createTestContact(acc);
        Test.stopTest();
        acc.RC_Account_Status__c = 'Canceled';
        update acc;
        Test.getEventBus().deliver();

        Contact testCon = Test_DemandFunnelHelper.getTestContact(acc);
        List<Demand_Funnel__c> dfrs = Test_DemandFunnelHelper.getDFRsByContact(
            new List<Contact>{ testCon },
            new List<String>{ 'DET_Current_Funnel_Status__c' }
        );

        /*System.assertEquals(
            ContactTriggerHandler.CONTACT_STATUS_DOWNGRADED,
            testCon.Contact_Status__c,
            'Contact Status should be Downgraded'
        );
        System.assertEquals(
            ContactUpdatePlatformEventsHelper.ACCOUNT_CHURNED,
            testCon.Downgrade_Reason__c,
            'Downgrade reason should be Account Churned'
        );
        Assert.areNotEqual(
            Test_DemandFunnelHelper.DOWNGRADEDFUNNELSTATUS,
            dfrs[0].DET_Current_Funnel_Status__c,
            'Current Funnel Status should be Downgraded'
        );*/
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testContactStatusDowngradedWhenAccountChurnDatePopulated() {
        Account acc = Test_DemandFunnelHelper.createTestAccount();
        Test.startTest();
        Contact con = Test_DemandFunnelHelper.createTestContact(acc);
        Test.stopTest();
        acc.RC_Churn_Date__c = Date.today();
        update acc;
        Test.getEventBus().deliver();

        Contact testCon = Test_DemandFunnelHelper.getTestContact(acc);
        List<Demand_Funnel__c> dfrs = Test_DemandFunnelHelper.getDFRsByContact(
            new List<Contact>{ testCon },
            new List<String>{ 'DET_Current_Funnel_Status__c', 'Pre_Opportunity_Close_Reason__c' }
        );

        /*System.assertEquals(
            ContactTriggerHandler.CONTACT_STATUS_DOWNGRADED,
            testCon.Contact_Status__c,
            'Contact Status should be Downgraded'
        );
        System.assertEquals(
            ContactUpdatePlatformEventsHelper.ACCOUNT_CHURNED,
            testCon.Downgrade_Reason__c,
            'Downgrade reason should be Account Churned'
        );
        Assert.areNotEqual(
            Test_DemandFunnelHelper.DOWNGRADEDFUNNELSTATUS,
            dfrs[0].DET_Current_Funnel_Status__c,
            'Current Funnel Status should be Downgraded'
        );*/
    }

    @isTest
    static void testBulkContactStatusDowngradedWhenAccountIsCancel() {
        Account acc = Test_DemandFunnelHelper.createTestAccount();
        Test.startTest();
        new SObjectBuilder(Contact.SObjectType)
            .setField(Contact.FirstName, 'Test')
            .setField(Contact.LastName, 'Record1')
            .setField(Contact.Email, 'test@test.com')
            .setField(Contact.Phone, '1234567890')
            .setField(Contact.Preferred_Language__c, 'en_US')
            .setField(Contact.AccountId, acc.Id)
            .quantity(201)
            .create();
        Test.stopTest();
        acc.RC_Account_Status__c = 'Canceled';
        update acc;

        String recordTypeId = Schema.SObjectType.Exception_And_Notification_History__c
            .getRecordTypeInfosByName()
            .get('Accounts Paid And Cancelled')
            .getRecordTypeId();
        List<Exception_And_Notification_History__c> eanhList = (List<Exception_And_Notification_History__c>) new ExceptionAndNotificationHistorySelector()
            .selectExceptionAndNotificationHistorysByRecordTypeIdAndObject(new List<Object>{new List<String>{recordTypeId}, 'Cancel Accounts'})
            .executeQuery();

        System.assertEquals(
            1,
            eanhList.size(),
            'One Exception And Notification History record should be created'
        );
        System.assertEquals(
            acc.Id,
            eanhList[0].Record_Id__c,
            'Affected Record ID should be the same as the Account Id'
        );
    }

    @isTest
    static void testBulkcontactShouldBeCustomerWhenRcUpgradeDatePopulates() {
        Account acc = Test_DemandFunnelHelper.createTestAccount();
        Test.startTest();
        new SObjectBuilder(Contact.SObjectType)
            .setField(Contact.FirstName, 'Test')
            .setField(Contact.LastName, 'Record1')
            .setField(Contact.Email, 'test@test.com')
            .setField(Contact.Phone, '1234567890')
            .setField(Contact.Preferred_Language__c, 'en_US')
            .setField(Contact.AccountId, acc.Id)
            .quantity(201)
            .create();
        Test.stopTest();
        acc.RC_Upgrade_Date__c = System.now();
        update acc;

        String recordTypeId = Schema.SObjectType.Exception_And_Notification_History__c
            .getRecordTypeInfosByName()
            .get('Accounts Paid And Cancelled')
            .getRecordTypeId();
        List<Exception_And_Notification_History__c> eanhList = (List<Exception_And_Notification_History__c>) new ExceptionAndNotificationHistorySelector()
            .selectExceptionAndNotificationHistorysByRecordTypeIdAndObject(new List<Object>{new List<String>{recordTypeId}, 'Customer Contacts'})
            .executeQuery();

        System.assertEquals(
            1,
            eanhList.size(),
            'One Exception And Notification History record should be created'
        );
        System.assertEquals(
            acc.Id,
            eanhList[0].Record_Id__c,
            'Affected Record ID should be the same as the Account Id'
        );
    }

    @isTest
    static void testBatchJobContactShouldBeCustomerWhenRcUpgradeDatePopulates() {
        Account acc = Test_DemandFunnelHelper.createTestAccount();
        Test.startTest();
        new SObjectBuilder(Contact.SObjectType)
            .setField(Contact.FirstName, 'Test')
            .setField(Contact.LastName, 'Record1')
            .setField(Contact.Email, 'test@test.com')
            .setField(Contact.Phone, '1234567890')
            .setField(Contact.Contact_Status__c, '1. New')
            .setField(Contact.Preferred_Language__c, 'en_US')
            .setField(Contact.AccountId, acc.Id)
            .quantity(200)
            .create();
        acc.RC_Upgrade_Date__c = System.now();
        update acc;

        String recordTypeId = Schema.SObjectType.Exception_And_Notification_History__c
            .getRecordTypeInfosByName()
            .get('Accounts Paid And Cancelled')
            .getRecordTypeId();
        List<Exception_And_Notification_History__c> eanhList = (List<Exception_And_Notification_History__c>) new ExceptionAndNotificationHistorySelector()
            .selectExceptionAndNotificationHistorysByRecordTypeIdAndObject(new List<Object>{new List<String>{recordTypeId}, 'Customer Contacts'})
            .executeQuery();

        System.assertEquals(
            1,
            eanhList.size(),
            'One Exception And Notification History record should be created'
        );

        System.assertEquals(
            acc.Id,
            eanhList[0].Record_Id__c,
            'Affected Record ID should be the same as the Account Id'
        );

        Database.executeBatch(new BatchJob_AccountsPaidAndCanceled(1, 'Customer Contacts'));
        Test.stopTest();

        eanhList = (List<Exception_And_Notification_History__c>) new ExceptionAndNotificationHistorySelector()
            .selectExceptionAndNotificationHistorysByRecordTypeIdAndObject(new List<Object>{new List<String>{recordTypeId}, 'Customer Contacts'})
            .executeQuery();
        Contact checkContact = Test_DemandFunnelHelper.getTestContact(acc);
        List<Demand_Funnel__c> dfrs = Test_DemandFunnelHelper.getDFRsByContact(new List<Contact>{checkContact}, new List<String>{ 'DET_Current_Funnel_Status__c', 'EOL_Entered_From__c' });
        System.assertEquals('4. Customer', checkContact.Contact_Status__c, 'Contact status should be 4. Customer.');
        System.assertEquals('7 - Customer', dfrs[0].DET_Current_Funnel_Status__c, 'DFR status should be 7. Customer.');
        System.assertEquals(
            0,
            eanhList.size(),
            'No Exception And Notification History record should exist'
        );
    }

    @isTest
    static void testBatchJobContactShouldBeDowngradedWhenAccountCanceledStatusPopulates() {
        Account acc = Test_DemandFunnelHelper.createTestAccount();
        Test.startTest();
        new SObjectBuilder(Contact.SObjectType)
            .setField(Contact.FirstName, 'Test')
            .setField(Contact.LastName, 'Record1')
            .setField(Contact.Email, 'test@test.com')
            .setField(Contact.Phone, '1234567890')
            .setField(Contact.Contact_Status__c, '1. New')
            .setField(Contact.Preferred_Language__c, 'en_US')
            .setField(Contact.AccountId, acc.Id)
            .quantity(200)
            .create();
        acc.RC_Account_Status__c = 'Cancel';
        update acc;

        String recordTypeId = Schema.SObjectType.Exception_And_Notification_History__c
            .getRecordTypeInfosByName()
            .get('Accounts Paid And Cancelled')
            .getRecordTypeId();
        List<Exception_And_Notification_History__c> eanhList = (List<Exception_And_Notification_History__c>) new ExceptionAndNotificationHistorySelector()
            .selectExceptionAndNotificationHistorysByRecordTypeIdAndObject(new List<Object>{new List<String>{recordTypeId}, 'Cancel Accounts'})
            .executeQuery();

        System.assertEquals(
            1,
            eanhList.size(),
            'One Exception And Notification History record should be created'
        );

        System.assertEquals(
            acc.Id,
            eanhList[0].Record_Id__c,
            'Affected Record ID should be the same as the Account Id'
        );

        Database.executeBatch(new BatchJob_AccountsPaidAndCanceled(1, 'Cancel Accounts'));
        Test.stopTest();

        eanhList = (List<Exception_And_Notification_History__c>) new ExceptionAndNotificationHistorySelector()
            .selectExceptionAndNotificationHistorysByRecordTypeIdAndObject(new List<Object>{new List<String>{recordTypeId}, 'Cancel Accounts'})
            .executeQuery();
        Contact checkContact = Test_DemandFunnelHelper.getTestContact(acc);
        List<Demand_Funnel__c> dfrs = Test_DemandFunnelHelper.getDFRsByContact(new List<Contact>{checkContact}, new List<String>{ 'DET_Current_Funnel_Status__c', 'EOL_Entered_From__c' });

        System.assertEquals(
            ContactTriggerHandler.CONTACT_STATUS_DOWNGRADED,
            checkContact.Contact_Status__c,
            'Contact Status should be Downgraded'
        );
        System.assertEquals(
            ContactUpdatePlatformEventsHelper.ACCOUNT_CHURNED,
            checkContact.Downgrade_Reason__c,
            'Downgrade reason should be Account Churned'
        );
        System.assertEquals(
            Test_DemandFunnelHelper.DOWNGRADEDFUNNELSTATUS,
            dfrs[0].DET_Current_Funnel_Status__c,
            'Current Funnel Status should be Downgraded'
        );
        System.assertEquals(
            0,
            eanhList.size(),
            'No Exception And Notification History record should exist'
        );
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @IsTest
    private static void testAccountsPaidAndCanceledSchedulable() {
        Test.startTest();
        AccountsPaidAndCanceledSchedulable testAccountsPaidAndCanceledSchedulable = new AccountsPaidAndCanceledSchedulable();
        String sch = '0 0 23 * * ?';
        System.schedule('Test run schedule AccountsPaidAndCanceledSchedulable', sch, testAccountsPaidAndCanceledSchedulable);
        Test.stopTest();
    }

    @isTest
    private static void testDowngradeContactsAndDFRs() {
        // Prepare test data
        Account testAcc = (Account) new SObjectBuilder(Account.SObjectType)
        .setFields(
            new Map<SObjectField, Object>{
                Account.Name => 'AccName',
                Account.Billing_ID__c => '121241'
            }
        )
        .create()
        .getRecord();

        Test.startTest();
        Contact testContact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.FirstName => 'TEst',
                    Contact.LastName => 'LName',
                    Contact.AccountId => testAcc.Id,
                    Contact.Email => 'test@t.com',
                    Contact.Phone => '123132434',
                    Contact.Contact_Status__c => '2. Contacted'
                }
            )
            .create()
            .getRecord();
        Test.stopTest();
        new DG_DFR_Class().DowngradeContactsAndDFRs();

        // Verify Contact and DFR records are downgraded correctly
        Contact updatedContact = (Contact) new ContactSelector()
            .selectContactsForDFRById(new List<Object>{new List<Id>{testContact.Id}})
            .selectField('Contact_Status__c')
            .executeQuery()[0];
         System.assertEquals('Downgraded', updatedContact.Contact_Status__c, 'Contact status should be downgraded.');

        Demand_Funnel__c updatedDFR = (Demand_Funnel__c) new DemandFunnelSelector()
            .selectDFRByContactTest(new List<Object>{new List<Id>{testContact.Id}})
            .selectField('EOL_Downgrade_Reason__c')
            .executeQuery()[0];
        System.assertEquals('No Sales Response', updatedDFR.EOL_Downgrade_Reason__c, 'DFR downgrade reason should be set.');
    }
    
    @isTest
    static void getUsersById_RunningInLeadConversionContextAndUserPresentInPlatformCache_ReturnMapOfUserById(){
        //GIVEN
        List<User> testUsers = [SELECT Id, Email, FirstName, LastName
                               FROM User WHERE IsActive = true LIMIT 1];
        ConvertLead.IS_LEAD_CONVERT_PROCESSING = true;
        SettingsHelper.FEATURE_TOGGLE.EnableLeadConversionUsingCache__c = true;
        PlatformCacheUtility.put(
            PlatformCacheUtility.SESSION_CACHE,
            testUsers[0].Id,
            testUsers[0],
            PlatformCacheUtility.CURRENT_USER_SESSION_DATA
        );
        
        //WHEN
        Test.startTest();
        Map<Id, User> result = DG_DFR_Class_Helper.getUsersById(new Set<Id>{testUsers[0].Id});
        Test.stopTest();
        
        //THEN
        Assert.isTrue(result.containsKey(testUsers[0].Id),'Test user record is present');
    }
    
    @isTest
    static void getUsersById_RunningInLeadConversionContextAndUserNotPresentInPlatformCache_ReturnMapOfUserById(){
        //GIVEN
        List<User> testUsers = [SELECT Id, Email, FirstName, LastName
                               FROM User WHERE IsActive = true LIMIT 1];
        ConvertLead.IS_LEAD_CONVERT_PROCESSING = true;
        SettingsHelper.FEATURE_TOGGLE.EnableLeadConversionUsingCache__c = true;
        
        //WHEN
        Test.startTest();
        Map<Id, User> result = DG_DFR_Class_Helper.getUsersById(new Set<Id>{testUsers[0].Id});
        Test.stopTest();
        
        //THEN
        Assert.isTrue(result.containsKey(testUsers[0].Id),'Test user record is present');
    }
    
    @isTest
    static void getUsersById_UserNotPresentInPlatformCache_ReturnMapOfUserById(){
        //GIVEN
        List<User> testUsers = [SELECT Id, Email, FirstName, LastName
                               FROM User WHERE IsActive = true LIMIT 1];
        ConvertLead.IS_LEAD_CONVERT_PROCESSING = false;
        SettingsHelper.FEATURE_TOGGLE.EnableLeadConversionUsingCache__c = false;
        
        //WHEN
        Test.startTest();
        Map<Id, User> result = DG_DFR_Class_Helper.getUsersById(new Set<Id>{testUsers[0].Id});
        Test.stopTest();
        
        //THEN
        Assert.isTrue(result.containsKey(testUsers[0].Id),'Test user record is present');
    }
    
}