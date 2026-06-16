@isTest
private class Test_DemandFunnelOpportunity {
    @testSetup
    static void setupData() {
        Test_DemandFunnelHelper.createSDRUser();
        Test_DemandFunnelHelper.createBDRUser();
        Test_DemandFunnelHelper.createAEUser();
        Test_DemandFunnelHelper.setupCustomSetting();


        Account acc = Test_DemandFunnelHelper.createTestAccount();
        Contact con = Test_DemandFunnelHelper.createTestContact(acc);
        Opportunity opp2 = Test_DemandFunnelHelper.createTestOpportunity(con);
    }

    @isTest
    static void testDowngradingOpportunityShouldReflectOnDFR() {
        Date actualCloseDate = Date.today();

        Account acc = Test_DemandFunnelHelper.getTestAccount();

        Contact con = Test_DemandFunnelHelper.getTestContact(acc);

        Opportunity opp = Test_DemandFunnelHelper.getTestOpportunity();

        Test.startTest();
        opp.StageName = OpportunityHelper.STAGE_NAME_DOWNGRADED;
        opp.Downgrade_Reason_Opp__c = 'some reason';
        opp.Brand_Name__c = 'testBrand';
        opp.CloseDate = actualCloseDate;
        opp.Type = 'New Business';
        opp.RecordTypeId = OpportunityHelper.RT_ID_SALES_OPPORTUNITY;
        update opp;
        Test.stopTest();

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRsByOpportunity(
            opp,
            new List<String>{
                'Prospect_Entered_From__c',
                'DFR_Active_Status__c',
                'MQL_Owner_Team__c',
                'Prospect_Exited_To__c',
                'MQL_Entered_From__c',
                'MQL_Exited_To__c',
                'TAL_Entered_From__c',
                'TAL_Exited_To__c',
                'SAL_Entered_From__c',
                'SAL_Exited_To__c',
                'EOL_Entered_From__c',
                'SQL_Entered_From__c',
                'SQL_Exited_To__c'
            }
        );

        System.assertEquals(
            'Inactive',
            dfrList[0].DFR_Active_Status__c,
            'If the Opportunity was downgraded, the DFR Status should be Inactive'
        );
    }

    //Test CRM-21069
    @isTest
    static void testDFRCreationCreatingOpportunityNewDFR() {
        Test.startTest();
        Account acc = Test_DemandFunnelHelper.getTestAccount();

        Contact con = Test_DemandFunnelHelper.getTestContact(acc);

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setField(Opportunity.Name, 'Test Opportunity')
            .setField(Opportunity.Type, 'Syndicated - New')
            .setField(Opportunity.StageName, 'Planning')
            .setField(Opportunity.CloseDate, System.today().addMonths(1))
            .setField(Opportunity.AccountId, acc.Id)
            .setField(
                Opportunity.RecordTypeId,
                Opportunity.SObjectType.getDescribe()
                    .getRecordTypeInfosByName()
                    .get('New Sales Opportunity')
                    .getRecordTypeId()
            )
            .setField(Opportunity.Primary_Opportunity_Contact__c, con.Id)
            .create()
            .getRecord();

        Test.stopTest();

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRsByOpportunity(
            opp,
            new List<String>{
                'Prospect_Entered_From__c',
                'DFR_Active_Status__c',
                'MQL_Owner_Team__c',
                'Prospect_Exited_To__c',
                'MQL_Entered_From__c',
                'MQL_Exited_To__c',
                'TAL_Entered_From__c',
                'TAL_Exited_To__c',
                'SAL_Entered_From__c',
                'SAL_Exited_To__c',
                'EOL_Entered_From__c',
                'SQL_Entered_From__c',
                'SQL_Exited_To__c'
            }
        );
        System.assertEquals(
            Test_DemandFunnelHelper.BACKFILLED,
            dfrList[0].Prospect_Entered_From__c,
            'Prospect_Entered_From__c incorrect value'
        );
        System.assertEquals(Test_DemandFunnelHelper.BACKFILLED, dfrList[0].Prospect_Exited_To__c, 'Prospect_Exited_To__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.BACKFILLED, dfrList[0].MQL_Entered_From__c, 'MQL_Entered_From__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.BACKFILLED, dfrList[0].MQL_Exited_To__c, 'MQL_Exited_To__c incorrect value');
        System.assertEquals(null, dfrList[0].TAL_Entered_From__c, 'TAL_Entered_From__c incorrect value');
        System.assertEquals(null, dfrList[0].TAL_Exited_To__c, 'TAL_Exited_To__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.BACKFILLED, dfrList[0].SAL_Entered_From__c, 'SAL_Entered_From__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.BACKFILLED, dfrList[0].SAL_Exited_To__c, 'SAL_Exited_To__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.CREATED, dfrList[0].SQL_Entered_From__c, 'SQL_Entered_From__c incorrect value');
        System.assertEquals(null, dfrList[0].SQL_Exited_To__c, 'SQL_Exited_To__c incorrect value');
        System.assertEquals(null, dfrList[0].EOL_Entered_From__c, 'EOL_Entered_From__c incorrect value');
        System.assertEquals('Active', dfrList[0].DFR_Active_Status__c, 'DFR_Active_Status__c incorrect value');
        System.assertEquals(
            Test_DemandFunnelHelper.SQLFUNNELSTATUS,
            dfrList[0].DET_Current_Funnel_Status__c,
            'DET_Current_Funnel_Status__c incorrect value'
        );
    }

    //Test CRM-21069
    @isTest
    static void testDFRCreationCreatingOpportunityExistingDFR() {
        User bdrUser = Test_DemandFunnelHelper.getUser(Test_DemandFunnelHelper.BDRLASTNAME);
        Test.startTest();
        Account acc = Test_DemandFunnelHelper.getTestAccount();

        Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setField(Contact.FirstName, 'Test')
            .setField(Contact.LastName, 'Contact DFR A')
            .setField(Contact.Email, 'test@DFRCreationCreatingOpportunityExistingDFR.com')
            .setField(Contact.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Contact.Preferred_Language__c, 'en_US')
            .setField(Contact.Demographic_Score__c, 123)
            .setField(Contact.Behavior_Score__c, 456)
            .setField(Contact.BMID__c, '1010')
            .setField(Contact.AID__c, 'Test Contact AID')
            .setField(Contact.PID__c, 'Test Contact PID')
            .setField(Contact.Asset_ID__c, 'AAA888')
            .setField(Contact.AccountId, acc.Id)
            .setField(Contact.Contact_Status__c, 'X. Open')
            .setField(Contact.OwnerId, bdrUser.Id)
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setField(Opportunity.Name, 'Test Opportunity')
            .setField(Opportunity.Type, 'Syndicated - New')
            .setField(Opportunity.StageName, 'Planning')
            .setField(Opportunity.CloseDate, System.today().addMonths(1))
            .setField(Opportunity.AccountId, acc.Id)
            .setField(
                Opportunity.RecordTypeId,
                Opportunity.SObjectType.getDescribe()
                    .getRecordTypeInfosByName()
                    .get('New Sales Opportunity')
                    .getRecordTypeId()
            )
            .setField(Opportunity.Primary_Opportunity_Contact__c, con.Id)
            .create()
            .getRecord();

        Test.stopTest();

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRsByOpportunity(
            opp,
            new List<String>{
                'Prospect_Entered_From__c',
                'DFR_Active_Status__c',
                'MQL_Owner_Team__c',
                'Prospect_Exited_To__c',
                'MQL_Entered_From__c',
                'MQL_Exited_To__c',
                'TAL_Entered_From__c',
                'TAL_Exited_To__c',
                'SAL_Entered_From__c',
                'SAL_Exited_To__c',
                'EOL_Entered_From__c',
                'SQL_Entered_From__c',
                'SQL_Exited_To__c'
            }
        );
        System.assertEquals(Test_DemandFunnelHelper.CREATED, dfrList[0].Prospect_Entered_From__c, 'Prospect_Entered_From__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.SQL, dfrList[0].Prospect_Exited_To__c, 'Prospect_Exited_To__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.BACKFILLED, dfrList[0].MQL_Entered_From__c, 'MQL_Entered_From__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.BACKFILLED, dfrList[0].MQL_Exited_To__c, 'MQL_Exited_To__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.BACKFILLED, dfrList[0].TAL_Entered_From__c, 'TAL_Entered_From__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.BACKFILLED, dfrList[0].TAL_Exited_To__c, 'TAL_Exited_To__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.BACKFILLED, dfrList[0].SAL_Entered_From__c, 'SAL_Entered_From__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.BACKFILLED, dfrList[0].SAL_Exited_To__c, 'SAL_Exited_To__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.PROSPECT, dfrList[0].SQL_Entered_From__c, 'SQL_Entered_From__c incorrect value');
        System.assertEquals(null, dfrList[0].SQL_Exited_To__c, 'SQL_Exited_To__c incorrect value');
        System.assertEquals(null, dfrList[0].EOL_Entered_From__c, 'EOL_Entered_From__c incorrect value');
        System.assertEquals('Active', dfrList[0].DFR_Active_Status__c, 'DFR_Active_Status__c incorrect value');
        System.assertEquals(
            Test_DemandFunnelHelper.SQLFUNNELSTATUS,
            dfrList[0].DET_Current_Funnel_Status__c,
            'DET_Current_Funnel_Status__c incorrect value'
        );
    }

    @isTest
    static void testOppClosedInBulk() {
        Date oneMonthFromNow = Date.today().addMonths(1);

        Account acc = Test_DemandFunnelHelper.getTestAccount();

        Contact con = Test_DemandFunnelHelper.getTestContact(acc);

        List<Opportunity> opps = (List<Opportunity>) new SObjectBuilder(Opportunity.SObjectType)
            .setField(Opportunity.Name, 'Test Opportunity')
            .setField(Opportunity.Type, 'Syndicated - New')
            .setField(Opportunity.StageName, 'Planning')
            .setField(Opportunity.CloseDate, oneMonthFromNow)
            .setField(Opportunity.Primary_Opportunity_Contact__c, con.Id)
            .quantity(20)
            .create()
            .getRecords();

        Test.startTest();
        List<Opportunity> oppsToUpdate = new List<Opportunity>();
        for (Opportunity opp : opps) {
            opp.StageName = '7. Closed Won';
            oppsToUpdate.add(opp);
        }
        update oppsToUpdate;
        Test.stopTest();
        System.assertEquals(oppsToUpdate.size(), 20, 'Missing Opps on creation');
    }

    //test case CRM-21522
    @isTest
    static void testOppDowngraded() {
        Date oneMonthFromNow = Date.today().addMonths(1);

        Account acc = Test_DemandFunnelHelper.getTestAccount();

        Contact con = Test_DemandFunnelHelper.getTestContact(acc);

        Opportunity opp = Test_DemandFunnelHelper.getTestOpportunity();

        OpportunityContactRole oppContactRoleObj = (OpportunityContactRole) new SObjectBuilder(
                OpportunityContactRole.SObjectType
            )
            .setField(OpportunityContactRole.OpportunityId, opp.Id)
            .setField(OpportunityContactRole.ContactId, con.id)
            .setField(OpportunityContactRole.IsPrimary, true)
            .create()
            .getRecord();

        Test.startTest();
        opp.StageName = '0. Downgraded';
        opp.Downgrade_Reason_Opp__c = 'Price';
        update opp;
        Test.stopTest();
        List<Demand_Funnel__c> dfrList = (List<Demand_Funnel__c>) Test_DemandFunnelHelper.getDFRsByOpportunity(
            opp,
            new List<String>{
                'Prospect_Entered_From__c',
                'DFR_Active_Status__c',
                'MQL_Owner_Team__c',
                'Prospect_Exited_To__c',
                'MQL_Entered_From__c',
                'MQL_Exited_To__c',
                'TAL_Entered_From__c',
                'TAL_Exited_To__c',
                'SAL_Entered_From__c',
                'SAL_Exited_To__c',
                'EOL_Entered_From__c',
                'SQL_Entered_From__c',
                'SQL_Exited_To__c',
                'Contact__r.Contact_Status__c'
            }
        );
        System.assertEquals(
            '6 - Opp Downgraded',
            dfrList[0].DET_Current_Funnel_Status__c,
            'Funnel Status its not Correct'
        );
        System.assertEquals(
            '0. Downgraded',
            dfrList[0].Contact__r.Contact_Status__c,
            'The Contact associated to the Opportunity Contact Role was not Downgraded'
        );
        System.assertEquals('0. Downgraded', dfrList[0].SQL_Exited_To__c, 'SQL_Exited_To__c incorrect value');
        System.assertEquals('Inactive', dfrList[0].DFR_Active_Status__c, 'DFR_Active_Status__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.SQL, dfrList[0].EOL_Entered_From__c, 'EOL_Entered_From__c incorrect value');
    }

    @isTest
    static void testOppClosedWon() {
        Date oneMonthFromNow = Date.today().addMonths(1);

        Account acc = Test_DemandFunnelHelper.getTestAccount();

        Contact con = Test_DemandFunnelHelper.getTestContact(acc);

        Opportunity opp = Test_DemandFunnelHelper.getTestOpportunity();

        OpportunityContactRole oppContactRoleObj = (OpportunityContactRole) new SObjectBuilder(
                OpportunityContactRole.SObjectType
            )
            .setField(OpportunityContactRole.OpportunityId, opp.Id)
            .setField(OpportunityContactRole.ContactId, con.id)
            .setField(OpportunityContactRole.IsPrimary, true)
            .create()
            .getRecord();

        Test.startTest();
        opp.StageName = '7. Closed Won';
        update opp;
        Test.stopTest();

        List<Demand_Funnel__c> dfrList = (List<Demand_Funnel__c>) Test_DemandFunnelHelper.getDFRsByOpportunity(
            opp,
            new List<String>{
                'Prospect_Entered_From__c',
                'DFR_Active_Status__c',
                'MQL_Owner_Team__c',
                'Prospect_Exited_To__c',
                'MQL_Entered_From__c',
                'MQL_Exited_To__c',
                'TAL_Entered_From__c',
                'TAL_Exited_To__c',
                'SAL_Entered_From__c',
                'SAL_Exited_To__c',
                'EOL_Entered_From__c',
                'SQL_Entered_From__c',
                'SQL_Exited_To__c',
                'Contact__r.Contact_Status__c'
            }
        );
        System.assertEquals('5 - Closed Won', dfrList[0].DET_Current_Funnel_Status__c, 'Funnel Status its not Correct');
        System.assertNotEquals(
            Test_DemandFunnelHelper.DOWNGRADED,
            dfrList[0].Contact__r.Contact_Status__c,
            'The Contact associated to the Opportunity Contact Role was Downgraded'
        );
        System.assertEquals('Inactive', dfrList[0].DFR_Active_Status__c, 'DFR_Active_Status__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.SQL, dfrList[0].EOL_Entered_From__c, 'EOL_Entered_From__c incorrect value');
    }

    @isTest
    static void testUpdateOpportunityStageName_UpdateADFRAssociated_PreOpportunityCloseReasonToNull() {
        Account acc = Test_DemandFunnelHelper.getTestAccount();

        Contact con = Test_DemandFunnelHelper.getTestContact(acc);

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setField(Opportunity.Name, 'Test Opportunity')
            .setField(Opportunity.Type, 'Syndicated - New')
            .setField(Opportunity.StageName, '0. Downgraded')
            .setField(Opportunity.CloseDate, System.today().addMonths(1))
            .setField(Opportunity.Downgrade_Reason_Opp__c, 'Lost to Competition')
            .setField(Opportunity.Service_Lost__c, 'Office')
            .setField(Opportunity.Primary_Opportunity_Contact__c, con.Id)
            .create()
            .getRecord();

        Demand_Funnel__c dfr = (Demand_Funnel__c) new SObjectBuilder(Demand_Funnel__c.SObjectType)
            .setField(Demand_Funnel__c.Opportunity__c, opp.Id)
            .setField(Demand_Funnel__c.Pre_Opportunity_Close_Reason__c, 'Test')
            .create()
            .getRecord();

        Test.startTest();
        opp.StageName = '7. Closed Won';
        update opp;
        Test.StopTest();

        DemandFunnelSelector selectDFR = new DemandFunnelSelector();

        List<Demand_Funnel__c> dfrList = selectDFR.selectDFRById(new List<String>{ DFR.Id })
            .selectField('Pre_Opportunity_Close_Reason__c')
            .executeQuery();

        System.assertEquals(1, dfrList.size(), 'Should be one dfr created.');

        for (Demand_Funnel__c dfrr : dfrList) {
            System.assertEquals(
                null,
                dfrr.Pre_Opportunity_Close_Reason__c,
                'the Pre_Opportunity_Close_Reason__c field should be null.'
            );
        }
    }

    @isTest
    static void testUpdateOpportunityStageName_UpdateDFRAssociateds_PreOpportunityCloseReasonToNull() {
        Account acc = Test_DemandFunnelHelper.getTestAccount();

        Contact con = Test_DemandFunnelHelper.getTestContact(acc);

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setField(Opportunity.Name, 'Test Opportunity')
            .setField(Opportunity.Type, 'Syndicated - New')
            .setField(Opportunity.StageName, '0. Downgraded')
            .setField(Opportunity.CloseDate, System.today().addMonths(1))
            .setField(Opportunity.Downgrade_Reason_Opp__c, 'Lost to Competition')
            .setField(Opportunity.Service_Lost__c, 'Office')
            .setField(Opportunity.Primary_Opportunity_Contact__c, con.Id)
            .create()
            .getRecord();

        new SObjectBuilder(Demand_Funnel__c.SObjectType)
            .setField(Demand_Funnel__c.Opportunity__c, opp.Id)
            .setField(Demand_Funnel__c.Pre_Opportunity_Close_Reason__c, 'Test')
            .quantity(25)
            .create();

        new SObjectBuilder(Demand_Funnel__c.SObjectType)
            .setField(Demand_Funnel__c.Opportunity__c, opp.Id)
            .quantity(25)
            .create();

        Test.startTest();
        opp.StageName = '7. Closed Won';
        update opp;
        Test.StopTest();

        DemandFunnelSelector selectDFR = new DemandFunnelSelector();

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRsByOpportunity(
            opp,
            new List<String>{ 'Pre_Opportunity_Close_Reason__c' }
        );

        System.assertNotEquals(0, dfrList.size(), 'Should be at least one dfr created.');

        for (Demand_Funnel__c dfrr : dfrList) {
            System.assertEquals(
                null,
                dfrr.Pre_Opportunity_Close_Reason__c,
                'the Pre_Opportunity_Close_Reason__c field should be null.'
            );
        }
    }

    //CRM-23483
    @isTest
    static void testOppCRClosedWonOpportunitySingleDFR() {
        Account acc = Test_DemandFunnelHelper.getTestAccount();

        Contact con = Test_DemandFunnelHelper.getTestContact(acc);

        Opportunity opp = Test_DemandFunnelHelper.getTestOpportunity();

        test.startTest();
        opp.StageName = '7. Closed Won';
        update opp;
        test.stopTest();

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRsByOpportunity(
            opp,
            new List<String>{
                'Contact__c',
                'Opportunity__c',
                'DET_Current_Funnel_Status__c',
                'SAL_Exited_To__c',
                'EOL_Entered_From__c',
                'SQL_Entered_From__c',
                'EOL_Owner_Name__c',
                'EOL_Owner_Team__c',
                'EOL_Owner_Id__c',
                'EOL_DateTime_Entered__c'
            }
        );
        System.assertEquals(1, dfrList.size(), 'DFR Record was not created');
        System.assertEquals(con.Id, dfrList[0].Contact__c, 'Contact field was not populated in DFR');
        System.assertEquals(opp.Id, dfrList[0].Opportunity__c, 'Opportunity field was not populated in DFR');
        System.assertEquals(
            '5 - Closed Won',
            dfrList[0].DET_Current_Funnel_Status__c,
            'DET_Current_Funnel_Status__c should be SQL'
        );
        System.assertEquals(Test_DemandFunnelHelper.SQL, dfrList[0].SAL_Exited_To__c, 'SAL_Exited_To__c should be SQL');
        System.assertEquals(Test_DemandFunnelHelper.SQL, dfrList[0].EOL_Entered_From__c, 'EOL_Entered_From__c should be SQL');
        System.assertEquals(Test_DemandFunnelHelper.SAL, dfrList[0].SQL_Entered_From__c, 'SQL_Entered_From__c should be SAL');
        System.assertNotEquals(null, dfrList[0].EOL_DateTime_Entered__c);
        System.assertNotEquals(null, dfrList[0].EOL_Owner_Name__c);
        System.assertNotEquals(null, dfrList[0].EOL_Owner_Id__c);
        System.assertNotEquals(null, dfrList[0].EOL_DateTime_Entered__c);
    }

    //CRM-23488
    @isTest
    static void testOppCRDowngradedOpportunitySingleDFR() {
        Account acc = Test_DemandFunnelHelper.getTestAccount();

        Contact con = Test_DemandFunnelHelper.getTestContact(acc);

        Opportunity opp = Test_DemandFunnelHelper.getTestOpportunity();

        test.startTest();
        opp.StageName = '0. Downgraded';
        opp.Downgrade_Reason_Opp__c = 'Lost';
        opp.Primary_Competitor__c = 'Avaya';
        update opp;
        test.stopTest();

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRsByOpportunity(
            opp,
            new List<String>{
                'Contact__c',
                'Opportunity__c',
                'DET_Current_Funnel_Status__c',
                'SAL_Exited_To__c',
                'EOL_Entered_From__c',
                'SQL_Entered_From__c',
                'EOL_Owner_Name__c',
                'EOL_Owner_Team__c',
                'EOL_Owner_Id__c',
                'EOL_DateTime_Entered__c'
            }
        );
        System.assertEquals(1, dfrList.size(), 'DFR Record was not created');
        System.assertEquals(con.Id, dfrList[0].Contact__c, 'Contact field was not populated in DFR');
        System.assertEquals(opp.Id, dfrList[0].Opportunity__c, 'Opportunity field was not populated in DFR');
        System.assertEquals(
            '6 - Opp Downgraded',
            dfrList[0].DET_Current_Funnel_Status__c,
            'DET_Current_Funnel_Status__c should be SQL'
        );
        System.assertEquals(Test_DemandFunnelHelper.SQL, dfrList[0].SAL_Exited_To__c, 'SAL_Exited_To__c should be SQL');
        System.assertEquals(Test_DemandFunnelHelper.SQL, dfrList[0].EOL_Entered_From__c, 'EOL_Entered_From__c should be SQL');
        System.assertEquals(Test_DemandFunnelHelper.SAL, dfrList[0].SQL_Entered_From__c, 'SQL_Entered_From__c should be SAL');
        System.assertNotEquals(null, dfrList[0].EOL_DateTime_Entered__c);
        System.assertNotEquals(null, dfrList[0].EOL_Owner_Name__c);
        System.assertNotEquals(null, dfrList[0].EOL_Owner_Id__c);
        System.assertNotEquals(null, dfrList[0].EOL_DateTime_Entered__c);
    }


    @isTest
    static void opportunityOwnerChangeSDRtoAE() {
        User aeUser = Test_DemandFunnelHelper.getUser(Test_DemandFunnelHelper.AELASTNAME);
        User sdrUser = Test_DemandFunnelHelper.getUser(Test_DemandFunnelHelper.SDRLASTNAME);

        Account acc = Test_DemandFunnelHelper.getTestAccount();

        Contact con = Test_DemandFunnelHelper.getTestContact(acc);

        OpportunityTriggerHelperRefactored.skipAsyncDFR = true;

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setField(Opportunity.Name, 'Test Opportunity')
            .setField(Opportunity.Type, 'Syndicated - New')
            .setField(Opportunity.StageName, 'Planning')
            .setField(Opportunity.CloseDate, System.today().addMonths(1))
            .setField(Opportunity.OwnerId, sdrUser.Id)
            .setField(Opportunity.AccountId, acc.Id)
            .setField(
                Opportunity.RecordTypeId,
                Opportunity.SObjectType.getDescribe()
                    .getRecordTypeInfosByName()
                    .get('New Sales Opportunity')
                    .getRecordTypeId()
            )
            .setField(Opportunity.Primary_Opportunity_Contact__c, con.Id)
            .create()
            .getRecord();

        Test.startTest();
        opp.OwnerId = aeUser.Id;
        update opp;
        Test.stopTest();

        Test.getEventBus().deliver();

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRsByOpportunity(
            opp,
            new List<String>{
                'SQL_Owner_Id__c',
                'DET_Current_Funnel_Status__c',
                'SQL_Owner_Name__c',
                'SQL_Owner_Team__c'
            }
        );
        System.assertEquals(aeUser.Id, dfrList[0].SQL_Owner_Id__c, 'SQL_Owner_Id__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.AELASTNAME, dfrList[0].SQL_Owner_Name__c, 'SQL_Owner_Name__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.AETEAM, dfrList[0].SQL_Owner_Team__c, 'SQL_Owner_Team__c incorrect value');
        System.assertEquals(
            Test_DemandFunnelHelper.SQLFUNNELSTATUS,
            dfrList[0].DET_Current_Funnel_Status__c,
            'DET_Current_Funnel_Status__c incorrect value'
        );
    }

    @isTest
    static void opportunityOwnerChangeAEtoSDR() {
        User aeUser = Test_DemandFunnelHelper.getUser(Test_DemandFunnelHelper.AELASTNAME);
        User sdrUser = Test_DemandFunnelHelper.getUser(Test_DemandFunnelHelper.SDRLASTNAME);

        Account acc = Test_DemandFunnelHelper.getTestAccount();

        Contact con = Test_DemandFunnelHelper.getTestContact(acc);

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setField(Opportunity.Name, 'Test Opportunity')
            .setField(Opportunity.Type, 'Syndicated - New')
            .setField(Opportunity.StageName, 'Planning')
            .setField(Opportunity.CloseDate, System.today().addMonths(1))
            .setField(Opportunity.OwnerId, aeUser.Id)
            .setField(Opportunity.AccountId, acc.Id)
            .setField(
                Opportunity.RecordTypeId,
                Opportunity.SObjectType.getDescribe()
                    .getRecordTypeInfosByName()
                    .get('New Sales Opportunity')
                    .getRecordTypeId()
            )
            .setField(Opportunity.Primary_Opportunity_Contact__c, con.Id)
            .create()
            .getRecord();

        Test.startTest();
        opp.OwnerId = sdrUser.Id;
        update opp;
        Test.stopTest();

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRsByOpportunity(
            opp,
            new List<String>{
                'SQL_Owner_Id__c',
                'DET_Current_Funnel_Status__c',
                'SQL_Owner_Name__c',
                'SQL_Owner_Team__c'
            }
        );
        System.assertEquals(aeUser.Id, dfrList[0].SQL_Owner_Id__c, 'SQL_Owner_Id__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.AELASTNAME, dfrList[0].SQL_Owner_Name__c, 'SQL_Owner_Name__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.AETEAM, dfrList[0].SQL_Owner_Team__c, 'SQL_Owner_Team__c incorrect value');
        System.assertEquals(
            Test_DemandFunnelHelper.SQLFUNNELSTATUS,
            dfrList[0].DET_Current_Funnel_Status__c,
            'DET_Current_Funnel_Status__c incorrect value'
        );
    }

    @isTest
    static void opportunityOwnerChangeSDRtoSDR() {
        User sdrUser = Test_DemandFunnelHelper.getUser(Test_DemandFunnelHelper.SDRLASTNAME);
        User sdrUser2 = (User) new SObjectBuilder(User.SObjectType)
            .setField(User.Username, 'TestDFROwnerChange' + Test_DemandFunnelHelper.LEADEMAIL)
            .setField(User.Email, 'testtesttest' + Test_DemandFunnelHelper.LEADEMAIL)
            .setfield(User.LastName, 'test')
            .setField(User.CommunityNickname, 'testingland')
            .setField(User.Team__c, Test_DemandFunnelHelper.SDRTEAM)
            .setField(User.SegmentPicklist__c, Test_DemandFunnelHelper.SDRSEGMENT)
            .create()
            .getRecord();

        Account acc = Test_DemandFunnelHelper.getTestAccount();

        Contact con = Test_DemandFunnelHelper.getTestContact(acc);

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setField(Opportunity.Name, 'Test Opportunity')
            .setField(Opportunity.Type, 'Syndicated - New')
            .setField(Opportunity.StageName, 'Planning')
            .setField(Opportunity.CloseDate, System.today().addMonths(1))
            .setField(Opportunity.OwnerId, sdrUser.Id)
            .setField(Opportunity.AccountId, acc.Id)
            .setField(
                Opportunity.RecordTypeId,
                Opportunity.SObjectType.getDescribe()
                    .getRecordTypeInfosByName()
                    .get('New Sales Opportunity')
                    .getRecordTypeId()
            )
            .setField(Opportunity.Primary_Opportunity_Contact__c, con.Id)
            .create()
            .getRecord();

        Test.startTest();
        opp.OwnerId = sdrUser2.Id;
        update opp;
        Test.stopTest();

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRsByOpportunity(
            opp,
            new List<String>{
                'SQL_Owner_Id__c',
                'DET_Current_Funnel_Status__c',
                'SQL_Owner_Name__c',
                'SQL_Owner_Team__c'
            }
        );
        System.assertEquals(sdrUser.Id, dfrList[0].SQL_Owner_Id__c, 'SQL_Owner_Id__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.SDRLASTNAME, dfrList[0].SQL_Owner_Name__c, 'SQL_Owner_Name__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.SDRTEAM, dfrList[0].SQL_Owner_Team__c, 'SQL_Owner_Team__c incorrect value');
        System.assertEquals(
            Test_DemandFunnelHelper.SQLFUNNELSTATUS,
            dfrList[0].DET_Current_Funnel_Status__c,
            'DET_Current_Funnel_Status__c incorrect value'
        );
    }

    @isTest
    static void testCreateOpportunityBDRtoAE() {
        Triggers.switchOff();
        User aeUser = Test_DemandFunnelHelper.getUser(Test_DemandFunnelHelper.AELASTNAME);
        User bdrUser = Test_DemandFunnelHelper.getUser(Test_DemandFunnelHelper.BDRLASTNAME);

        Test.startTest();
        Account acc = Test_DemandFunnelHelper.getTestAccount();

        Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setField(Contact.FirstName, 'John')
            .setField(Contact.LastName, 'Doe')
            .setField(Contact.Email, Test_DemandFunnelHelper.LEADEMAIL)
            .setField(Contact.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Contact.Contact_Status__c, LeadHelper.STATUS_NEW)
            .setField(Contact.Preferred_Language__c, 'en_US')
            .setField(Contact.AccountId, acc.Id)
            .setField(Contact.OwnerId, bdrUser.Id)
            .create()
            .getRecord();

        Demand_Funnel__c dfr = (Demand_Funnel__c) new SObjectBuilder(Demand_Funnel__c.SObjectType)
            .setField(Demand_Funnel__c.Contact__c, con.Id)
            .setField(Demand_Funnel__c.Pre_Opportunity_Status__c, Test_DemandFunnelHelper.MQL)
            .setField(Demand_Funnel__c.MQL_Owner_Id__c, bdrUser.Id)
            .setField(Demand_Funnel__c.MQL_Owner_Name__c, bdrUser.Name)
            .setField(Demand_Funnel__c.MQL_Owner_Team__c, bdrUser.Team__c)
            .create()
            .getRecord();

        

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setField(Opportunity.Name, 'Test Opportunity')
            .setField(Opportunity.Type, 'Syndicated - New')
            .setField(Opportunity.StageName, 'Planning')
            .setField(Opportunity.CloseDate, System.today().addMonths(1))
            .setField(Opportunity.AccountId, acc.Id)
            .setField(Opportunity.OwnerId, aeUser.Id)
            .setField(
                Opportunity.RecordTypeId,
                Opportunity.SObjectType.getDescribe()
                    .getRecordTypeInfosByName()
                    .get('New Sales Opportunity')
                    .getRecordTypeId()
            )
            .setField(Opportunity.Primary_Opportunity_Contact__c, con.Id)
            .create()
            .getRecord();

        Triggers.switchOn();
        DG_DFR_Class.DFR_AddOpportunity(new List<Opportunity>{opp});
        Test.stopTest();

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRsByOpportunity(
            opp,
            new List<String>{
                'SQL_Entered_From__c',
                'TAL_Entered_From__c',
                'TAL_Exited_To__c',
                'TAL_Owner_Name__c',
                'TQL_Entered_From__c',
                'TQL_Exited_To__c',
                'TQL_Owner_Name__c',
                'SAL_Entered_From__c',
                'SAL_Exited_To__c',
                'SAL_Owner_Name__c'
            }
        );
        System.assertEquals(Test_DemandFunnelHelper.BACKFILLED, dfrList[0].TAL_Entered_From__c, 'TAL_Entered_From__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.BACKFILLED, dfrList[0].TAL_Exited_To__c, 'TAL_Exited_To__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.BDRLASTNAME, dfrList[0].TAL_Owner_Name__c, 'TAL_Owner_Name__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.BACKFILLED, dfrList[0].TQL_Entered_From__c, 'TQL_Entered_From__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.BACKFILLED, dfrList[0].TQL_Exited_To__c, 'TQL_Exited_To__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.BDRLASTNAME, dfrList[0].TQL_Owner_Name__c, 'TQL_Owner_Name__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.BACKFILLED, dfrList[0].SAL_Entered_From__c, 'SAL_Entered_From__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.BACKFILLED, dfrList[0].SAL_Exited_To__c, 'SAL_Exited_To__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.AELASTNAME, dfrList[0].SAL_Owner_Name__c, 'SAL_Owner_Name__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.MQL, dfrList[0].SQL_Entered_From__c, 'SQL_Entered_From__c incorrect value');
    }

    @isTest
    static void testCreateOpportunityBDRtoBDR() {
        Triggers.switchOff();
        User bdrUser = Test_DemandFunnelHelper.getUser(Test_DemandFunnelHelper.BDRLASTNAME);

        Test.startTest();
        Account acc = Test_DemandFunnelHelper.getTestAccount();

        Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setField(Contact.FirstName, 'John')
            .setField(Contact.LastName, 'Doe')
            .setField(Contact.Email, Test_DemandFunnelHelper.LEADEMAIL)
            .setField(Contact.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Contact.Contact_Status__c, LeadHelper.STATUS_NEW)
            .setField(Contact.Preferred_Language__c, 'en_US')
            .setField(Contact.AccountId, acc.Id)
            .setField(Contact.OwnerId, bdrUser.Id)
            .create()
            .getRecord();

        Demand_Funnel__c dfr = (Demand_Funnel__c) new SObjectBuilder(Demand_Funnel__c.SObjectType)
            .setField(Demand_Funnel__c.Contact__c, con.Id)
            .setField(Demand_Funnel__c.Pre_Opportunity_Status__c, Test_DemandFunnelHelper.MQL)
            .setField(Demand_Funnel__c.MQL_Owner_Id__c, bdrUser.Id)
            .setField(Demand_Funnel__c.MQL_Owner_Name__c, bdrUser.Name)
            .setField(Demand_Funnel__c.MQL_Owner_Team__c, bdrUser.Team__c)
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setField(Opportunity.Name, 'Test Opportunity')
            .setField(Opportunity.Type, 'Syndicated - New')
            .setField(Opportunity.StageName, 'Planning')
            .setField(Opportunity.CloseDate, System.today().addMonths(1))
            .setField(Opportunity.AccountId, acc.Id)
            .setField(Opportunity.OwnerId, bdrUser.Id)
            .setField(
                Opportunity.RecordTypeId,
                Opportunity.SObjectType.getDescribe()
                    .getRecordTypeInfosByName()
                    .get('New Sales Opportunity')
                    .getRecordTypeId()
            )
            .setField(Opportunity.Primary_Opportunity_Contact__c, con.Id)
            .create()
            .getRecord();

        Triggers.switchOn();
        DG_DFR_Class.DFR_AddOpportunity(new List<Opportunity>{opp});
        Test.stopTest();

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRsByOpportunity(
            opp,
            new List<String>{
                'SQL_Entered_From__c',
                'TAL_Entered_From__c',
                'TAL_Exited_To__c',
                'TAL_Owner_Name__c',
                'TQL_Entered_From__c',
                'TQL_Exited_To__c',
                'TQL_Owner_Name__c',
                'SAL_Entered_From__c',
                'SAL_Exited_To__c',
                'SAL_Owner_Name__c'
            }
        );
        
        System.assertEquals(Test_DemandFunnelHelper.BACKFILLED, dfrList[0].TAL_Entered_From__c, 'TAL_Entered_From__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.BACKFILLED, dfrList[0].TAL_Exited_To__c, 'TAL_Exited_To__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.BDRLASTNAME, dfrList[0].TAL_Owner_Name__c, 'TAL_Owner_Name__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.BACKFILLED, dfrList[0].TQL_Entered_From__c, 'TQL_Entered_From__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.BACKFILLED, dfrList[0].TQL_Exited_To__c, 'TQL_Exited_To__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.BDRLASTNAME, dfrList[0].TQL_Owner_Name__c, 'TQL_Owner_Name__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.BACKFILLED, dfrList[0].SAL_Entered_From__c, 'SAL_Entered_From__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.BACKFILLED, dfrList[0].SAL_Exited_To__c, 'SAL_Exited_To__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.BDRLASTNAME, dfrList[0].SAL_Owner_Name__c, 'SAL_Owner_Name__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.MQL, dfrList[0].SQL_Entered_From__c, 'SQL_Entered_From__c incorrect value');
    }

    @isTest
    static void testCreateOpportunityAEtoBDR() {
        Triggers.switchOff();
        User aeUser = Test_DemandFunnelHelper.getUser(Test_DemandFunnelHelper.AELASTNAME);
        User bdrUser = Test_DemandFunnelHelper.getUser(Test_DemandFunnelHelper.BDRLASTNAME);

        Test.startTest();
        Account acc = Test_DemandFunnelHelper.getTestAccount();

        Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setField(Contact.FirstName, 'John')
            .setField(Contact.LastName, 'Doe')
            .setField(Contact.Email, Test_DemandFunnelHelper.LEADEMAIL)
            .setField(Contact.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Contact.Contact_Status__c, LeadHelper.STATUS_NEW)
            .setField(Contact.Preferred_Language__c, 'en_US')
            .setField(Contact.AccountId, acc.Id)
            .setField(Contact.OwnerId, aeUser.Id)
            .create()
            .getRecord();

        Demand_Funnel__c dfr = (Demand_Funnel__c) new SObjectBuilder(Demand_Funnel__c.SObjectType)
            .setField(Demand_Funnel__c.Contact__c, con.Id)
            .setField(Demand_Funnel__c.Pre_Opportunity_Status__c, Test_DemandFunnelHelper.MQL)
            .setField(Demand_Funnel__c.MQL_Owner_Id__c, aeUser.Id)
            .setField(Demand_Funnel__c.MQL_Owner_Name__c, aeUser.Name)
            .setField(Demand_Funnel__c.MQL_Owner_Team__c, aeUser.Team__c)
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setField(Opportunity.Name, 'Test Opportunity')
            .setField(Opportunity.Type, 'Syndicated - New')
            .setField(Opportunity.StageName, 'Planning')
            .setField(Opportunity.CloseDate, System.today().addMonths(1))
            .setField(Opportunity.AccountId, acc.Id)
            .setField(Opportunity.OwnerId, bdrUser.Id)
            .setField(
                Opportunity.RecordTypeId,
                Opportunity.SObjectType.getDescribe()
                    .getRecordTypeInfosByName()
                    .get('New Sales Opportunity')
                    .getRecordTypeId()
            )
            .setField(Opportunity.Primary_Opportunity_Contact__c, con.Id)
            .create()
            .getRecord();
        
        Triggers.switchOn();
        DG_DFR_Class.DFR_AddOpportunity(new List<Opportunity>{opp});
        Test.stopTest();

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRsByOpportunity(
            opp,
            new List<String>{
                'SQL_Entered_From__c',
                'TAL_Entered_From__c',
                'TAL_Exited_To__c',
                'TAL_Owner_Name__c',
                'TQL_Entered_From__c',
                'TQL_Exited_To__c',
                'TQL_Owner_Name__c',
                'SAL_Entered_From__c',
                'SAL_Exited_To__c',
                'SAL_Owner_Name__c'
            }
        );
        System.assertEquals(null, dfrList[0].TAL_Entered_From__c, 'TAL_Entered_From__c incorrect value');
        System.assertEquals(null, dfrList[0].TAL_Exited_To__c, 'TAL_Exited_To__c incorrect value');
        System.assertEquals(null, dfrList[0].TAL_Owner_Name__c, 'TAL_Owner_Name__c incorrect value');
        System.assertEquals(null, dfrList[0].TQL_Entered_From__c, 'TQL_Entered_From__c incorrect value');
        System.assertEquals(null, dfrList[0].TQL_Exited_To__c, 'TQL_Exited_To__c incorrect value');
        System.assertEquals(null, dfrList[0].TQL_Owner_Name__c, 'TQL_Owner_Name__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.BACKFILLED, dfrList[0].SAL_Entered_From__c, 'SAL_Entered_From__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.BACKFILLED, dfrList[0].SAL_Exited_To__c, 'SAL_Exited_To__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.BDRLASTNAME, dfrList[0].SAL_Owner_Name__c, 'SAL_Owner_Name__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.MQL, dfrList[0].SQL_Entered_From__c, 'SQL_Entered_From__c incorrect value');
    }

    
    @isTest
    static void testCreateOpportunityBDRtoAENewDFR() {
        User aeUser = Test_DemandFunnelHelper.getUser(Test_DemandFunnelHelper.AELASTNAME);
        User bdrUser = Test_DemandFunnelHelper.getUser(Test_DemandFunnelHelper.BDRLASTNAME);

        Test.startTest();
        Account acc = Test_DemandFunnelHelper.getTestAccount();

        Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setField(Contact.FirstName, 'John')
            .setField(Contact.LastName, 'Doe')
            .setField(Contact.Email, 'testEmail@test.com')
            .setField(Contact.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Contact.Preferred_Language__c, 'en_US')
            .setField(Contact.AccountId, acc.Id)
            .setField(Contact.OwnerId, bdrUser.Id)
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setField(Opportunity.Name, 'Test Opportunity')
            .setField(Opportunity.Type, 'Syndicated - New')
            .setField(Opportunity.StageName, 'Planning')
            .setField(Opportunity.CloseDate, System.today().addMonths(1))
            .setField(Opportunity.AccountId, acc.Id)
            .setField(Opportunity.OwnerId, aeUser.Id)
            .setField(
                Opportunity.RecordTypeId,
                Opportunity.SObjectType.getDescribe()
                    .getRecordTypeInfosByName()
                    .get('New Sales Opportunity')
                    .getRecordTypeId()
            )
            .setField(Opportunity.Primary_Opportunity_Contact__c, con.Id)
            .create()
            .getRecord();

        Test.stopTest();

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRsByOpportunity(
            opp,
            new List<String>{
                'SQL_Entered_From__c',
                'TAL_Entered_From__c',
                'TAL_Exited_To__c',
                'TAL_Owner_Name__c',
                'TQL_Entered_From__c',
                'TQL_Exited_To__c',
                'TQL_Owner_Name__c',
                'SAL_Entered_From__c',
                'SAL_Exited_To__c',
                'SAL_Owner_Name__c'
            }
        );
        System.assertEquals(Test_DemandFunnelHelper.BACKFILLED, dfrList[0].TAL_Entered_From__c, 'TAL_Entered_From__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.BACKFILLED, dfrList[0].TAL_Exited_To__c, 'TAL_Exited_To__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.BDRLASTNAME, dfrList[0].TAL_Owner_Name__c, 'TAL_Owner_Name__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.BACKFILLED, dfrList[0].TQL_Entered_From__c, 'TQL_Entered_From__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.BACKFILLED, dfrList[0].TQL_Exited_To__c, 'TQL_Exited_To__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.BDRLASTNAME, dfrList[0].TQL_Owner_Name__c, 'TQL_Owner_Name__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.BACKFILLED, dfrList[0].SAL_Entered_From__c, 'SAL_Entered_From__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.BACKFILLED, dfrList[0].SAL_Exited_To__c, 'SAL_Exited_To__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.AELASTNAME, dfrList[0].SAL_Owner_Name__c, 'SAL_Owner_Name__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.CREATED, dfrList[0].SQL_Entered_From__c, 'SQL_Entered_From__c incorrect value');
    }

    
    @isTest
    static void testCreateOpportunityBDRtoBDRNewDFR() {
        User bdrUser = Test_DemandFunnelHelper.getUser(Test_DemandFunnelHelper.BDRLASTNAME);

        Test.startTest();
        Account acc = Test_DemandFunnelHelper.getTestAccount();

        Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setField(Contact.FirstName, 'John')
            .setField(Contact.LastName, 'Doe')
            .setField(Contact.Email, 'testEmail@testmail.com')
            .setField(Contact.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Contact.Preferred_Language__c, 'en_US')
            .setField(Contact.AccountId, acc.Id)
            .setField(Contact.OwnerId, bdrUser.Id)
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setField(Opportunity.Name, 'Test Opportunity')
            .setField(Opportunity.Type, 'Syndicated - New')
            .setField(Opportunity.StageName, 'Planning')
            .setField(Opportunity.CloseDate, System.today().addMonths(1))
            .setField(Opportunity.AccountId, acc.Id)
            .setField(Opportunity.OwnerId, bdrUser.Id)
            .setField(
                Opportunity.RecordTypeId,
                Opportunity.SObjectType.getDescribe()
                    .getRecordTypeInfosByName()
                    .get('New Sales Opportunity')
                    .getRecordTypeId()
            )
            .setField(Opportunity.Primary_Opportunity_Contact__c, con.Id)
            .create()
            .getRecord();

        Test.stopTest();

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRsByOpportunity(
            opp,
            new List<String>{
                'SQL_Entered_From__c',
                'TAL_Entered_From__c',
                'TAL_Exited_To__c',
                'TAL_Owner_Name__c',
                'TQL_Entered_From__c',
                'TQL_Exited_To__c',
                'TQL_Owner_Name__c',
                'SAL_Entered_From__c',
                'SAL_Exited_To__c',
                'SAL_Owner_Name__c'
            }
        );
        
        System.assertEquals(Test_DemandFunnelHelper.BACKFILLED, dfrList[0].TAL_Entered_From__c, 'TAL_Entered_From__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.BACKFILLED, dfrList[0].TAL_Exited_To__c, 'TAL_Exited_To__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.BDRLASTNAME, dfrList[0].TAL_Owner_Name__c, 'TAL_Owner_Name__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.BACKFILLED, dfrList[0].TQL_Entered_From__c, 'TQL_Entered_From__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.BACKFILLED, dfrList[0].TQL_Exited_To__c, 'TQL_Exited_To__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.BDRLASTNAME, dfrList[0].TQL_Owner_Name__c, 'TQL_Owner_Name__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.BACKFILLED, dfrList[0].SAL_Entered_From__c, 'SAL_Entered_From__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.BACKFILLED, dfrList[0].SAL_Exited_To__c, 'SAL_Exited_To__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.BDRLASTNAME, dfrList[0].SAL_Owner_Name__c, 'SAL_Owner_Name__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.CREATED, dfrList[0].SQL_Entered_From__c, 'SQL_Entered_From__c incorrect value');
    }

    @isTest
    static void testCreateOpportunityAEtoBDRNewDFR() {
        User aeUser = Test_DemandFunnelHelper.getUser(Test_DemandFunnelHelper.AELASTNAME);
        User bdrUser = Test_DemandFunnelHelper.getUser(Test_DemandFunnelHelper.BDRLASTNAME);

        Test.startTest();
        Account acc = Test_DemandFunnelHelper.createTestAccount();

        Contact con = Test_DemandFunnelHelper.createTestContact(acc);

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setField(Opportunity.Name, 'Test Opportunity')
            .setField(Opportunity.Type, 'Syndicated - New')
            .setField(Opportunity.StageName, 'Planning')
            .setField(Opportunity.CloseDate, System.today().addMonths(1))
            .setField(Opportunity.AccountId, acc.Id)
            .setField(Opportunity.OwnerId, bdrUser.Id)
            .setField(
                Opportunity.RecordTypeId,
                Opportunity.SObjectType.getDescribe()
                    .getRecordTypeInfosByName()
                    .get('New Sales Opportunity')
                    .getRecordTypeId()
            )
            .setField(Opportunity.Primary_Opportunity_Contact__c, con.Id)
            .create()
            .getRecord();
        Test.stopTest();

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRsByOpportunity(
        opp,
            new List<String>{
                'SQL_Entered_From__c',
                'TAL_Entered_From__c',
                'TAL_Exited_To__c',
                'TAL_Owner_Name__c',
                'TQL_Entered_From__c',
                'TQL_Exited_To__c',
                'TQL_Owner_Name__c',
                'SAL_Entered_From__c',
                'SAL_Exited_To__c',
                'SAL_Owner_Name__c'
            }
        );

        System.assertEquals(null, dfrList[0].TAL_Entered_From__c, 'TAL_Entered_From__c incorrect value');
        System.assertEquals(null, dfrList[0].TAL_Exited_To__c, 'TAL_Exited_To__c incorrect value');
        System.assertEquals(null, dfrList[0].TAL_Owner_Name__c, 'TAL_Owner_Name__c incorrect value');
        System.assertEquals(null, dfrList[0].TQL_Entered_From__c, 'TQL_Entered_From__c incorrect value');
        System.assertEquals(null, dfrList[0].TQL_Exited_To__c, 'TQL_Exited_To__c incorrect value');
        System.assertEquals(null, dfrList[0].TQL_Owner_Name__c, 'TQL_Owner_Name__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.CREATED, dfrList[0].SAL_Entered_From__c, 'SAL_Entered_From__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.SQL, dfrList[0].SAL_Exited_To__c, 'SAL_Exited_To__c incorrect value');
        System.assertEquals('AEDFRTest', dfrList[0].SAL_Owner_Name__c, 'SAL_Owner_Name__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.SAL, dfrList[0].SQL_Entered_From__c, 'SQL_Entered_From__c incorrect value');
    }

    @isTest
    static void testOwnerFieldsOpportunityCreationNewDFRBDRtoAE() {
        User aeUser = Test_DemandFunnelHelper.getUser(Test_DemandFunnelHelper.AELASTNAME);
        User bdrUser = Test_DemandFunnelHelper.getUser(Test_DemandFunnelHelper.BDRLASTNAME);

        Test.startTest();
        Account acc = Test_DemandFunnelHelper.getTestAccount();

        Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setField(Contact.FirstName, 'John')
            .setField(Contact.LastName, 'Doe')
            .setField(Contact.Email, 'testEmail@tester.com')
            .setField(Contact.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Contact.Preferred_Language__c, 'en_US')
            .setField(Contact.AccountId, acc.Id)
            .setField(Contact.OwnerId, bdrUser.Id)
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setField(Opportunity.Name, 'Test Opportunity')
            .setField(Opportunity.Type, 'Syndicated - New')
            .setField(Opportunity.StageName, 'Planning')
            .setField(Opportunity.CloseDate, System.today().addMonths(1))
            .setField(Opportunity.AccountId, acc.Id)
            .setField(
                Opportunity.RecordTypeId,
                Opportunity.SObjectType.getDescribe()
                    .getRecordTypeInfosByName()
                    .get('New Sales Opportunity')
                    .getRecordTypeId()
            )
            .setField(Opportunity.Primary_Opportunity_Contact__c, con.Id)
            .setField(Opportunity.OwnerId, aeUser.Id)
            .create()
            .getRecord();

        Test.stopTest();

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRsByOpportunity(
            opp,
            new List<String> {
                'Prospect_Owner_Name__c',
                'MQL_Owner_Name__c',
                'TAL_Owner_Name__c',
                'TQL_Owner_Name__c',
                'SAL_Owner_Name__c',
                'SQL_Owner_Name__c'
            }
        );
        System.assertEquals(Test_DemandFunnelHelper.BDRLASTNAME, dfrList[0].Prospect_Owner_Name__c, 'Prospect_Owner_Name__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.BDRLASTNAME, dfrList[0].MQL_Owner_Name__c, 'MQL_Owner_Name__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.BDRLASTNAME, dfrList[0].TAL_Owner_Name__c, 'TAL_Owner_Name__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.BDRLASTNAME, dfrList[0].TQL_Owner_Name__c, 'TQL_Owner_Name__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.AELASTNAME, dfrList[0].SAL_Owner_Name__c, 'SAL_Owner_Name__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.AELASTNAME, dfrList[0].SQL_Owner_Name__c, 'SQL_Owner_Name__c incorrect value');
    }

    @isTest
    static void testOwnerFieldsOnOpportunityCreationExistingDFR() {
        Triggers.switchOff();
        User aeUser = Test_DemandFunnelHelper.getUser(Test_DemandFunnelHelper.AELASTNAME);
        User bdrUser = Test_DemandFunnelHelper.getUser(Test_DemandFunnelHelper.BDRLASTNAME);

        Account acc = Test_DemandFunnelHelper.getTestAccount();

        Test.startTest();
        
        Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setField(Contact.FirstName, 'John')
            .setField(Contact.LastName, 'Doe')
            .setField(Contact.Email, Test_DemandFunnelHelper.LEADEMAIL)
            .setField(Contact.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Contact.Preferred_Language__c, 'en_US')
            .setField(Contact.AccountId, acc.Id)
            .setField(Contact.OwnerId, bdrUser.Id)
            .create()
            .getRecord();

        Demand_Funnel__c dfr = (Demand_Funnel__c) new SObjectBuilder(Demand_Funnel__c.SObjectType)
            .setField(Demand_Funnel__c.Contact__c, con.Id)
            .setField(Demand_Funnel__c.Pre_Opportunity_Status__c, Test_DemandFunnelHelper.PROSPECT)
            .create()
            .getRecord(); 

            
        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setField(Opportunity.Name, 'Test Opportunity')
            .setField(Opportunity.Type, 'Syndicated - New')
            .setField(Opportunity.StageName, 'Planning')
            .setField(Opportunity.CloseDate, System.today().addMonths(1))
            .setField(Opportunity.AccountId, acc.Id)
            .setField(
                Opportunity.RecordTypeId,
                Opportunity.SObjectType.getDescribe()
                .getRecordTypeInfosByName()
                .get('New Sales Opportunity')
                .getRecordTypeId()
                )
                .setField(Opportunity.Primary_Opportunity_Contact__c, con.Id)
                .setField(Opportunity.OwnerId, aeUser.Id)
                .create()
                .getRecord();
                
        Triggers.switchOn();
        DG_DFR_Class.DFR_AddOpportunity(new List<Opportunity>{opp});
        Test.stopTest();

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRsByOpportunity(
            opp,
            new List<String> {
                'MQL_Owner_Name__c',
                'TAL_Owner_Name__c',
                'TQL_Owner_Name__c',
                'SAL_Owner_Name__c',
                'SQL_Owner_Name__c'
            }
        );
        System.assertEquals(Test_DemandFunnelHelper.BDRLASTNAME, dfrList[0].MQL_Owner_Name__c, 'MQL_Owner_Name__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.BDRLASTNAME, dfrList[0].TAL_Owner_Name__c, 'TAL_Owner_Name__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.BDRLASTNAME, dfrList[0].TQL_Owner_Name__c, 'TQL_Owner_Name__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.AELASTNAME, dfrList[0].SAL_Owner_Name__c, 'SAL_Owner_Name__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.AELASTNAME, dfrList[0].SQL_Owner_Name__c, 'SQL_Owner_Name__c incorrect value');
    }

    @isTest
    static void testOwnerFieldsOpportunityCreationNewDFRAEtoBDR() {
        User aeUser = Test_DemandFunnelHelper.getUser(Test_DemandFunnelHelper.AELASTNAME);
        User bdrUser = Test_DemandFunnelHelper.getUser(Test_DemandFunnelHelper.BDRLASTNAME);

        Test.startTest();
        Account acc = Test_DemandFunnelHelper.getTestAccount();

        Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setField(Contact.FirstName, 'John')
            .setField(Contact.LastName, 'Doe')
            .setField(Contact.Email, 'testemail@emailtester.com')
            .setField(Contact.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Contact.Preferred_Language__c, 'en_US')
            .setField(Contact.AccountId, acc.Id)
            .setField(Contact.OwnerId, aeUser.Id)
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setField(Opportunity.Name, 'Test Opportunity')
            .setField(Opportunity.Type, 'Syndicated - New')
            .setField(Opportunity.StageName, 'Planning')
            .setField(Opportunity.CloseDate, System.today().addMonths(1))
            .setField(Opportunity.AccountId, acc.Id)
            .setField(
                Opportunity.RecordTypeId,
                Opportunity.SObjectType.getDescribe()
                    .getRecordTypeInfosByName()
                    .get('New Sales Opportunity')
                    .getRecordTypeId()
            )
            .setField(Opportunity.Primary_Opportunity_Contact__c, con.Id)
            .setField(Opportunity.OwnerId, bdrUser.Id)
            .create()
            .getRecord();

        Test.stopTest();

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRsByOpportunity(
            opp,
            new List<String> {
                'Prospect_Owner_Name__c',
                'MQL_Owner_Name__c',
                'TAL_Owner_Name__c',
                'TQL_Owner_Name__c',
                'SAL_Owner_Name__c',
                'SQL_Owner_Name__c'
            }
        );
        System.assertEquals(Test_DemandFunnelHelper.AELASTNAME, dfrList[0].Prospect_Owner_Name__c, 'Prospect_Owner_Name__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.AELASTNAME, dfrList[0].MQL_Owner_Name__c, 'MQL_Owner_Name__c incorrect value');
        System.assertEquals(null, dfrList[0].TAL_Owner_Name__c, 'TAL_Owner_Name__c incorrect value');
        System.assertEquals(null, dfrList[0].TQL_Owner_Name__c, 'TQL_Owner_Name__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.BDRLASTNAME, dfrList[0].SAL_Owner_Name__c, 'SAL_Owner_Name__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.BDRLASTNAME, dfrList[0].SQL_Owner_Name__c, 'SQL_Owner_Name__c incorrect value');
    }

    @isTest
    static void testSALRemapOnOppCreation() {
        User aeUser = Test_DemandFunnelHelper.getUser(Test_DemandFunnelHelper.AELASTNAME);
        User bdrUser = Test_DemandFunnelHelper.getUser(Test_DemandFunnelHelper.BDRLASTNAME);

        Account acc = Test_DemandFunnelHelper.getTestAccount();

        Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setField(Contact.FirstName, 'John')
            .setField(Contact.LastName, 'Doe')
            .setField(Contact.Contact_Status__c, LeadHelper.STATUS_NEW)
            .setField(Contact.Email, 'testemail@emailtester.com')
            .setField(Contact.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Contact.Preferred_Language__c, 'en_US')
            .setField(Contact.AccountId, acc.Id)
            .setField(Contact.OwnerId, aeUser.Id)
            .create()
            .getRecord();

        Test.startTest();
        
        con.OwnerId = bdrUser.Id;
        con.Contact_Status__c = LeadTriggerHelper.LEADSTATUSCONTACTED;
        update con;


        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setField(Opportunity.Name, 'Test Opportunity')
            .setField(Opportunity.Type, 'Syndicated - New')
            .setField(Opportunity.StageName, 'Planning')
            .setField(Opportunity.CloseDate, System.today().addMonths(1))
            .setField(Opportunity.AccountId, acc.Id)
            .setField(
                Opportunity.RecordTypeId,
                Opportunity.SObjectType.getDescribe()
                    .getRecordTypeInfosByName()
                    .get('New Sales Opportunity')
                    .getRecordTypeId()
            )
            .setField(Opportunity.Primary_Opportunity_Contact__c, con.Id)
            .setField(Opportunity.OwnerId, aeUser.Id)
            .create()
            .getRecord();

        Test.stopTest();

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRsByOpportunity(
            opp,
            new List<String> {
                'Prospect_Owner_Name__c',
                'MQL_Owner_Name__c',
                'TAL_Owner_Name__c',
                'TQL_Owner_Name__c',
                'SAL_Owner_Name__c',
                'SQL_Owner_Name__c'
            }
        );
        System.assertEquals(Test_DemandFunnelHelper.AELASTNAME, dfrList[0].Prospect_Owner_Name__c, 'Prospect_Owner_Name__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.AELASTNAME, dfrList[0].MQL_Owner_Name__c, 'MQL_Owner_Name__c incorrect value');
        //System.assertEquals(null, dfrList[0].TAL_Owner_Name__c, 'TAL_Owner_Name__c incorrect value');
        System.assertEquals(null, dfrList[0].TQL_Owner_Name__c, 'TQL_Owner_Name__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.AELASTNAME, dfrList[0].SAL_Owner_Name__c, 'SAL_Owner_Name__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.AELASTNAME, dfrList[0].SQL_Owner_Name__c, 'SQL_Owner_Name__c incorrect value');
    }
    
    @isTest
    static void testOpportunityPipelineRecalculationSingleOppInsert() {

        Account acc = Test_DemandFunnelHelper.getTestAccount();

        Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setField(Contact.FirstName, 'John')
            .setField(Contact.LastName, 'Doe')
            .setField(Contact.Contact_Status__c, LeadHelper.STATUS_NEW)
            .setField(Contact.Email, 'testemail@emailtester.com')
            .setField(Contact.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Contact.Preferred_Language__c, 'en_US')
            .setField(Contact.AccountId, acc.Id)
            .create()
            .getRecord();

        Test.startTest();
        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setField(Opportunity.Name, 'Test Opportunity')
            .setField(Opportunity.Type, 'Syndicated - New')
            .setField(Opportunity.StageName, '1. Qualify')
            .setField(Opportunity.CloseDate, System.today().addMonths(1))
            .setField(Opportunity.AccountId, acc.Id)
            .setField(Opportunity.Estimated_12M_Total_Pipeline__c, 200)
            .setField(Opportunity.Estimated_Total_MRR__c, 1)
            .setField(Opportunity.Tier_Name__c, OpportunityHelper.TIER_OFFICE)
            .setField(Opportunity.CurrencyIsoCode, 'EUR')
            .setField(
                Opportunity.RecordTypeId,
                Opportunity.SObjectType.getDescribe()
                    .getRecordTypeInfosByName()
                    .get('New Sales Opportunity')
                    .getRecordTypeId()
            )
            .setField(Opportunity.Primary_Opportunity_Contact__c, con.Id)
            .create()
            .getRecord();

        Test.stopTest();
        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRsByOpportunity(
            opp,
            new List<String> {
                'Estimated_12M_Total_Pipeline_OC__c',
                'Opportunity_Currency__c',
                'Opportunity_Exchange_Rate__c',
                'Estimated_12M_Total_Pipeline_DC__c',
                'Estimated_12M_Total_Pipeline_TC__c'
            }
        );
        System.assertEquals(200, dfrList[0].Estimated_12M_Total_Pipeline_OC__c , 'Estimated_12M_Total_Pipeline_OC__c incorrect value');
        System.assertEquals('EUR', dfrList[0].Opportunity_Currency__c, 'Opportunity_Currency__c incorrect value');
        System.assert(dfrList[0].Opportunity_Exchange_Rate__c != null, 'Opportunity_Exchange_Rate__c incorrect value');
        System.assert(dfrList[0].Estimated_12M_Total_Pipeline_DC__c != null, 'Estimated_12M_Total_Pipeline_DC__c incorrect value');
        System.assert(dfrList[0].Estimated_12M_Total_Pipeline_TC__c.contains('EUR'), 'Estimated_12M_Total_Pipeline_TC__c incorrect value');
    }

    @isTest
    static void testOpportunityPipelineRecalculationSingleOppUpdate() {

        Account acc = Test_DemandFunnelHelper.getTestAccount();

        Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setField(Contact.FirstName, 'John')
            .setField(Contact.LastName, 'Doe')
            .setField(Contact.Contact_Status__c, LeadHelper.STATUS_NEW)
            .setField(Contact.Email, 'testemail@emailtester.com')
            .setField(Contact.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Contact.Preferred_Language__c, 'en_US')
            .setField(Contact.AccountId, acc.Id)
            .create()
            .getRecord();

        OpportunityTriggerHelperRefactored.skipAsyncDFR = true;

        Test.StartTest();   
            Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setField(Opportunity.Name, 'Test Opportunity')
            .setField(Opportunity.Type, 'Syndicated - New')
            .setField(Opportunity.StageName, '1. Qualify')
            .setField(Opportunity.CloseDate, System.today().addMonths(1))
            .setField(Opportunity.AccountId, acc.Id)
            .setField(Opportunity.Estimated_12M_Total_Pipeline__c, 200)
            .setField(Opportunity.Estimated_Total_MRR__c, 1)
            .setField(Opportunity.CurrencyIsoCode, 'EUR')
            .setField(
                Opportunity.RecordTypeId,
                Opportunity.SObjectType.getDescribe()
                    .getRecordTypeInfosByName()
                    .get('New Sales Opportunity')
                    .getRecordTypeId()
            )
            .setField(Opportunity.Primary_Opportunity_Contact__c, con.Id)
            .create()
            .getRecord();
            opp.Estimated_12M_Total_Pipeline__c = 500;
            opp.CurrencyIsoCode = 'GBP';
            update opp;
        Test.StopTest();
        
        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRsByOpportunity(
            opp,
            new List<String> {
                'Estimated_12M_Total_Pipeline_OC__c',
                'Opportunity_Currency__c',
                'Opportunity_Exchange_Rate__c',
                'Estimated_12M_Total_Pipeline_DC__c',
                'Estimated_12M_Total_Pipeline_TC__c'
            }
        );

        System.assertEquals(500, dfrList[0].Estimated_12M_Total_Pipeline_OC__c , 'Estimated_12M_Total_Pipeline_OC__c incorrect value');
        System.assertEquals('GBP', dfrList[0].Opportunity_Currency__c, 'Opportunity_Currency__c incorrect value');
        System.assert(dfrList[0].Opportunity_Exchange_Rate__c != null, 'Opportunity_Exchange_Rate__c incorrect value');
        System.assert(dfrList[0].Estimated_12M_Total_Pipeline_DC__c != null, 'Estimated_12M_Total_Pipeline_DC__c incorrect value');
        System.assert(dfrList[0].Estimated_12M_Total_Pipeline_TC__c.contains('GBP'), 'Estimated_12M_Total_Pipeline_TC__c incorrect value');
    }

    @isTest
    static void testOpportunityPipelineRecalculationBulkOpp() {
        Account acc = Test_DemandFunnelHelper.getTestAccount();
        Set<Id> opps1Ids = new Set<Id>();
        Set<Id> opps2Ids = new Set<Id>();

        Test.StartTest();
        List<Contact> con2 = (List<Contact>) new SObjectBuilder(Contact.SObjectType)
            .setField(Contact.FirstName, 'Johhn')
            .setField(Contact.LastName, 'Doee')
            .setField(Contact.Contact_Status__c, LeadHelper.STATUS_NEW)
            .setField(Contact.Email, 'testemaill@emailtester.com')
            .setField(Contact.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Contact.Preferred_Language__c, 'en_US')
            .setField(Contact.AccountId, acc.Id)
            .quantity(10)
            .create()
            .getRecords();
            
        List<Contact> con = (List<Contact>) new SObjectBuilder(Contact.SObjectType)
            .setField(Contact.FirstName, 'John')
            .setField(Contact.LastName, 'Doe')
            .setField(Contact.Contact_Status__c, LeadHelper.STATUS_NEW)
            .setField(Contact.Email, 'testemail@emailtester.com')
            .setField(Contact.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Contact.Preferred_Language__c, 'en_US')
            .setField(Contact.AccountId, acc.Id)
            .quantity(10)
            .create()
            .getRecords();

        List<Opportunity> opps = new List<Opportunity>();
        for (Contact ct : con ) {
            opps.add( (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setField(Opportunity.Name, 'Test Opportunity')
            .setField(Opportunity.Type, 'Syndicated - New')
            .setField(Opportunity.StageName, 'Planning')
            .setField(Opportunity.CloseDate, System.today().addMonths(1))
            .setField(Opportunity.AccountId, acc.Id)
            .setField(Opportunity.Estimated_12M_Total_Pipeline__c, 200)
            .setField(Opportunity.Estimated_Total_MRR__c, 1)
            .setField(Opportunity.CurrencyIsoCode, 'EUR')
            .setField(
                Opportunity.RecordTypeId,
                Opportunity.SObjectType.getDescribe()
                    .getRecordTypeInfosByName()
                    .get('New Sales Opportunity')
                    .getRecordTypeId()
            )
            .setField(Opportunity.Primary_Opportunity_Contact__c, ct.Id)
            .build()
            .getRecord());
        }

        insert opps;

        for (Opportunity opp : opps) {
            opps1Ids.add(opp.Id);
        }
        List<Opportunity> opps2 = new List<Opportunity>();
        for (Contact ct : con2) {
            opps2.add( (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setField(Opportunity.Name, 'Test Opportunity')
            .setField(Opportunity.Type, 'Syndicated - New')
            .setField(Opportunity.StageName, 'Planning')
            .setField(Opportunity.CloseDate, System.today().addMonths(1))
            .setField(Opportunity.AccountId, acc.Id)
            .setField(Opportunity.Estimated_12M_Total_Pipeline__c, 300)
            .setField(Opportunity.Estimated_Total_MRR__c, 1)
            .setField(Opportunity.CurrencyIsoCode, 'GBP')
            .setField(
                Opportunity.RecordTypeId,
                Opportunity.SObjectType.getDescribe()
                    .getRecordTypeInfosByName()
                    .get('New Sales Opportunity')
                    .getRecordTypeId()
            )
            .setField(Opportunity.Primary_Opportunity_Contact__c, ct.Id)
            .setField(Opportunity.Brand_Name__c, RingCentralHelper.BRAND_VERIZON)
            .build()
            .getRecord());
        }

        insert opps2;
   
        for (Opportunity opp : opps2) {
            opps2Ids.add(opp.Id);
        }
        Test.StopTest();

        List<Demand_Funnel__c> dfrListEUR = (List<Demand_Funnel__c>) new DemandFunnelSelector()
            .selectDFRByOpportunitiesId(new List<Object>{opps1Ids})
            .selectField('Estimated_12M_Total_Pipeline_OC__c')
            .selectField('Opportunity_Currency__c')
            .selectField('Opportunity_Exchange_Rate__c')
            .selectField('Estimated_12M_Total_Pipeline_DC__c')
            .selectField('Estimated_12M_Total_Pipeline_TC__c')
            .executeQuery();
        List<Demand_Funnel__c> dfrListGBP = (List<Demand_Funnel__c>) new DemandFunnelSelector()
            .selectDFRByOpportunitiesId(new List<Object>{opps2Ids})
            .selectField('Estimated_12M_Total_Pipeline_OC__c')
            .selectField('Opportunity_Currency__c')
            .selectField('Opportunity_Exchange_Rate__c')
            .selectField('Estimated_12M_Total_Pipeline_DC__c')
            .selectField('Estimated_12M_Total_Pipeline_TC__c')
            .executeQuery();

        System.assertEquals(200, dfrListEUR[2].Estimated_12M_Total_Pipeline_OC__c , 'Estimated_12M_Total_Pipeline_OC__c incorrect value');
        System.assertEquals('EUR', dfrListEUR[2].Opportunity_Currency__c, 'Opportunity_Currency__c incorrect value');
        System.assert(dfrListEUR[2].Opportunity_Exchange_Rate__c != null, 'Opportunity_Exchange_Rate__c incorrect value');
        System.assert(dfrListEUR[2].Estimated_12M_Total_Pipeline_DC__c != null, 'Estimated_12M_Total_Pipeline_DC__c incorrect value');
        System.assert(dfrListEUR[2].Estimated_12M_Total_Pipeline_TC__c.contains('EUR'), 'Estimated_12M_Total_Pipeline_TC__c incorrect value');

        System.assertEquals(300, dfrListGBP[2].Estimated_12M_Total_Pipeline_OC__c , 'Estimated_12M_Total_Pipeline_OC__c incorrect value');
        System.assertEquals('GBP', dfrListGBP[2].Opportunity_Currency__c, 'Opportunity_Currency__c incorrect value');
        System.assert(dfrListGBP[2].Opportunity_Exchange_Rate__c != null, 'Opportunity_Exchange_Rate__c incorrect value');
        System.assert(dfrListGBP[2].Estimated_12M_Total_Pipeline_DC__c != null, 'Estimated_12M_Total_Pipeline_DC__c incorrect value');
        System.assert(dfrListGBP[2].Estimated_12M_Total_Pipeline_TC__c.contains('GBP'), 'Estimated_12M_Total_Pipeline_TC__c incorrect value');
    }
}