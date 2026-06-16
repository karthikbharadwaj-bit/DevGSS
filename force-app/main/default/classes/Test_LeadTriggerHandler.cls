@isTest
private class Test_LeadTriggerHandler {

    private static final String RINGCENTRAL_AU_BRAND = 'RingCentral AU';

    @isTest
    public static void intendedBrandDFR_whenUpdateLeadBrandNameField_shouldUpdateIntendedBrandOnRelatedDFR() {

        Campaign camp = (Campaign) new SObjectBuilder(Campaign.sObjectType)
            .setField(Campaign.IsActive, true)
            .setField(Campaign.Non_Attributable__c, false)
            .setField(Campaign.Name, 'camp Test')
            .setField(Campaign.Intended_Product__c, 'CA')
            .create()
            .getRecord();

        List<Lead> leads = (List<Lead>) new SObjectBuilder(Lead.sObjectType)
            .setField(Lead.lastName, 'LEAD TEST')
            .setField(Lead.BMID__c, null)
            .setField(Lead.AID__c, '1')
            .setField(Lead.PID__c, '1')
            .setField(Lead.Lead_Brand_Name__c, 'RingCentral Canada')
            .quantity(2)
            .create()
            .getRecords();

        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => 'testAcc',
                    Account.RC_Brand__c => 'Test Brand',
                    Account.ZI_Company_Country__c => 'Germany'
                }
            )
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.Name => 'Test Opportunity 2016',
                    Opportunity.Type => 'Syndicated - New',
                    Opportunity.StageName => 'Planning',
                    Opportunity.CloseDate => system.today().addMonths(1),
                    Opportunity.AccountId => acc.Id,
                    Opportunity.Brand_Name__c => 'Test'
                }
            )
            .create()
            .getRecord();

        List<Demand_Funnel__c> dfrs = new List<Demand_Funnel__c>();

        for (Integer i=0 ; i< 2; i++) {
            dfrs.add(
                (Demand_Funnel__c) new SObjectBuilder(Demand_Funnel__c.SObjectType)
                    .setFields(
                        new Map<SObjectField, Object>{
                            Demand_Funnel__c.Opportunity__c => opp.Id,
                            Demand_Funnel__c.Lead__c => leads[i].Id,
                            Demand_Funnel__c.Prospect_campaign__c => camp.Id
                        }
                    )
                    .build()
                    .getRecord()
            );
        }

        insert dfrs;

        Test.startTest();
            for (Lead ld : leads) {
                ld.Lead_brand_name__c = 'RingCentral AU';
            }
            update leads;
        Test.stopTest();

        dfrs = (List<Demand_Funnel__c>) new DemandFunnelSelector()
            .selectDFRByIds(new Object[]{dfrs})
            .selectField(Demand_Funnel__c.Intended_Brand__c)
            .executeQuery();

        System.assertEquals(2, dfrs.size(), 'There should be fifty (2) Demand Funnel records.');

        for (Demand_Funnel__c dfr : dfrs) {
            System.assertEquals(RINGCENTRAL_AU_BRAND, dfr.Intended_Brand__c, 'The Intended Brand should be RingCentral AU because the Lead brand name contains AU');
        }
    }

    @isTest
    public static void intendedBrandDFR_whenUpdateSMCountryField_shouldUpdateIntendedBrandOnRelatedDFR() {

        List<Account> accs = (List<Account>) new SObjectBuilder(Account.sObjectType)
            .setField(Account.Name, 'camp Test')
            .setField(Account.ZI_Company_Country__c, 'Netherlands')
            .setField(Account.Multinational_Ultimate__c, false)
            .quantity(20)
            .create()
            .getRecords();

        List<Lead> leads = new List<Lead>();

        for(Account acc : accs) {
            leads.add((Lead) new SObjectBuilder(Lead.sObjectType)
                .setField(Lead.lastName, 'LEAD TEST')
                .setField(Lead.BMID__c, null)
                .setField(Lead.AID__c, '1')
                .setField(Lead.PID__c, '1')
                .build()
                .getRecord()
            );
        }

        insert leads;

        List<Demand_Funnel__c> dfrs = new List<Demand_Funnel__c>();

        for(Lead ld : leads) {
            dfrs.add((Demand_Funnel__c) new SObjectBuilder(Demand_Funnel__c.SObjectType)
                .setField(Demand_Funnel__c.Lead__c, ld.Id)
                .build()
                .getRecord()
            );
        }

        insert dfrs;

        Test.startTest();
            integer i = 0;
            for (Lead ld : leads) {
                ld.ZI_CDP_Account_Id__c = accs[i++].Id;
            }
            update leads;
        Test.stopTest();

        dfrs = (List<Demand_Funnel__c>) new DemandFunnelSelector()
            .selectDFRByIds(new Object[]{dfrs})
            .selectField(Demand_Funnel__c.Intended_Brand__c)
            .executeQuery();

        System.assertEquals(20, dfrs.size(), 'There should be twenty (20) Demand Funnel records.');

        for (Demand_Funnel__c dfr : dfrs) {
            System.assertEquals('RingCentral EU', dfr.Intended_Brand__c, 'The Intended Brand should be RingCentral EU because the SM Country of the related Lead is Netherlands.');
        }
    }

    @isTest
    static void accountDFR_whenUpdateAccount_shouldUpdateAccountOnRelatedDFR() {

        TriggerHandler.BY_PASS_CONTACT_ON_INSERT = true;
        TriggerHandler.BY_PASS_LEAD_UPDATE_ON_INSERT = true;
        TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT();
        TriggerHandler.BY_PASS_OPPORTUNITY_ON_INSERT();

        Triggers.switchOff();

        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
        .setField(Account.Name, 'TestAccount')
            .create()
            .getRecord();

        Account acc2 = (Account) new SObjectBuilder(Account.SObjectType)
            .setField(Account.Name, 'TestAccount2')
            .create()
            .getRecord();

        Lead leadTest = (Lead) new SObjectBuilder(Lead.sObjectType)
            .setField(Lead.lastName, 'LEAD TEST')
            .setField(Lead.BMID__c, null)
            .setField(Lead.AID__c, '1')
            .setField(Lead.PID__c, '1')
            .setField(Lead.ZI_CDP_Account_Id__c, acc.Id)
            .create()
            .getRecord();

        Triggers.switchOn();
        TriggerHandler.BY_PASS_LEAD_UPDATE_ON_INSERT = false;

        List<Demand_Funnel__c> dfrs = (List<Demand_Funnel__c>) new SObjectBuilder(Demand_Funnel__c.SObjectType)
            .setField(Demand_Funnel__c.Lead__c, leadTest.Id)
            .quantity(1)
            .create()
            .getRecords();

        dfrs = (List<Demand_Funnel__c>) new DemandFunnelSelector()
            .selectDFRByIds(new Object[]{dfrs})
            .selectField(Demand_Funnel__c.Account__c)
            .executeQuery();

        for (Demand_Funnel__c dfr : dfrs) {
            System.assertEquals(acc.Id, dfr.Account__c, 'The account field should be the same as the lead account');
        }

        Test.startTest();
            leadTest.ZI_CDP_Account_Id__c = acc2.Id;
            update leadTest;
            Test.getEventBus().deliver();
        Test.stopTest();

        dfrs = (List<Demand_Funnel__c>) new DemandFunnelSelector()
            .selectDFRByIds(new Object[]{dfrs})
            .selectField(Demand_Funnel__c.Account__c)
            .executeQuery();

        for (Demand_Funnel__c dfr : dfrs) {
            System.assertEquals(acc2.Id, dfr.Account__c, 'The account field should be the same as the lead account');
        }
    }

    @isTest
    static void accountDFR_whenUpdateAccount_shouldNotUpdateAccountOnRelatedDFR() {

        TriggerHandler.BY_PASS_CONTACT_ON_INSERT = true;
        TriggerHandler.BY_PASS_LEAD_UPDATE_ON_INSERT = true;
        TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT();
        TriggerHandler.BY_PASS_OPPORTUNITY_ON_INSERT();

        Triggers.switchOff();

        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
        .setField(Account.Name, 'TestAccount')
            .create()
            .getRecord();

        Account acc2 = (Account) new SObjectBuilder(Account.SObjectType)
            .setField(Account.Name, 'TestAccount2')
            .create()
            .getRecord();

        Account acc3 = (Account) new SObjectBuilder(Account.SObjectType)
            .setField(Account.Name, 'TestAccount3')
            .create()
            .getRecord();

        Lead leadTest = (Lead) new SObjectBuilder(Lead.sObjectType)
            .setField(Lead.lastName, 'LEAD TEST')
            .setField(Lead.BMID__c, null)
            .setField(Lead.AID__c, '1')
            .setField(Lead.PID__c, '1')
            .setField(Lead.ZI_CDP_Account_Id__c, acc.Id)
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.Name => 'Test Opportunity 2016',
                    Opportunity.Type => 'Syndicated - New',
                    Opportunity.StageName => 'Planning',
                    Opportunity.CloseDate => system.today().addMonths(1),
                    Opportunity.AccountId => acc2.Id
                }
            )
            .create()
            .getRecord();
        Triggers.switchOn();
        TriggerHandler.BY_PASS_LEAD_UPDATE_ON_INSERT = false;

        List<Demand_Funnel__c> dfrs = (List<Demand_Funnel__c>) new SObjectBuilder(Demand_Funnel__c.SObjectType)
            .setField(Demand_Funnel__c.Opportunity__c, opp.Id)
            .setField(Demand_Funnel__c.Lead__c, leadTest.Id)
            .quantity(50)
            .create()
            .getRecords();

        dfrs = (List<Demand_Funnel__c>) new DemandFunnelSelector()
            .selectDFRByIds(new Object[]{dfrs})
            .selectField(Demand_Funnel__c.Account__c)
            .executeQuery();

        for (Demand_Funnel__c dfr : dfrs) {
            System.assertEquals(acc2.Id, dfr.Account__c, 'The account field should be the same as the lead account');
        }

        Test.startTest();
            leadTest.ZI_CDP_Account_Id__c = acc3.Id;
            update leadTest;
        Test.stopTest();

        dfrs = (List<Demand_Funnel__c>) new DemandFunnelSelector()
            .selectDFRByIds(new Object[]{dfrs})
            .selectField(Demand_Funnel__c.Account__c)
            .executeQuery();

        for (Demand_Funnel__c dfr : dfrs) {
            System.assertEquals(acc2.Id, dfr.Account__c, 'The account field should be the same as the opportunity account');
        }
    }

    @isTest
    static void test_PWFA_casAutodowngrade() {
        Group sharedLeadsQueue = [SELECT Id, Name FROM Group WHERE Type = 'Queue' AND Id =: HardcodedIdsMapper.getMatchedObjectId(QueueHelper.SHARED_LEADS_ID)];

        //verify that shared leads queue exists and has correct Id
        System.assertEquals(sharedLeadsQueue.Id, HardcodedIdsMapper.getMatchedObjectId(QueueHelper.SHARED_LEADS_ID).substring(0, 15));

        Test.startTest();
            insert new Feature_Toggle__c (LeadWorkflowRulesAndProcToTrigger__c = true);

            Lead testLeadOnInsert = new Lead(
                OwnerId = sharedLeadsQueue.Id,
                FirstName = 'testName',
                Title = 'VP',
                Country = 'UK',
                BMID__c = 'test0121',
                LeadSource = 'NotInitial',
                Lastname = 'testName',
                Company = 'Google',
                Email = 'test@gmail.com',
                Phone = '9910106803',
                Status = LeadHelper.STATUS_CALL_OUT,
                cas__NumberAttempts__c = 30);
            Lead testLeadOnUpdate = new Lead(
                OwnerId = sharedLeadsQueue.Id,
                FirstName = 'testName',
                Title = 'VP',
                Country = 'UK',
                BMID__c = 'test0122',
                LeadSource = 'NotInitial',
                Lastname = 'testName',
                Company = 'Google',
                Email = 'test@gmail.com',
                Phone = '9910106803',
                Status = LeadHelper.STATUS_CALL_OUT,
                cas__NumberAttempts__c = 29);

            //skipping old trigger logic because we don't need it and it reassigns the lead owner to Shared Leads
            LeadTriggerHelper.skipLeadTriggerOnUpdateFromCompanyPersonBatch = true;
            insert (new List<Lead>{testLeadOnInsert, testLeadOnUpdate});
            // Test Insert action
            List<Lead> testLeadsOnInsert = [
                SELECT Id, OwnerId, BMID__c, Status, Downgrade_Reason__c/*, Sub_Downgrade_Reason__c*/
                FROM Lead
            ];
            for (Lead item : testLeadsOnInsert) {
                if (item.BMID__c == 'test0121') {
                    System.assertEquals(LeadHelper.STATUS_DOWNGRADED, item.Status);
                    System.assertEquals('No response', item.Downgrade_Reason__c);
                } else {
                    System.assertEquals(LeadHelper.STATUS_CALL_OUT, item.Status);
                    System.assertEquals(null, item.Downgrade_Reason__c);
                }

            }
            testLeadOnUpdate.cas__NumberAttempts__c = 31;
            testLeadOnUpdate.Initial_Category__c = 'No Activation – Changed Mind';
            update testLeadOnUpdate;
            // Test Update action
            List<Lead> testLeadsOnUpdate = [
                SELECT Id, BMID__c, Status, Downgrade_Reason__c/*, Sub_Downgrade_Reason__c*/
                FROM Lead
            ];
            for (Lead item : testLeadsOnUpdate) {
                System.assertEquals(LeadHelper.STATUS_DOWNGRADED, item.Status);
                System.assertEquals('No response', item.Downgrade_Reason__c);
            }
        Test.stopTest();
    }

    @isTest
    static void test_PWFA_resetCallAttempts() {
        insert new Feature_Toggle__c (LeadWorkflowRulesAndProcToTrigger__c = true);

        Lead testLeadOnInsert = new Lead(
            FirstName = 'testName',
            Title = 'VP',
            Country = 'UK',
            BMID__c = 'test0121',
            LeadSource = 'Initial',
            Lastname = 'testName',
            Company = 'Google',
            Email = 'test@gmail.com',
            Phone = '9910106803',
            Status = LeadHelper.STATUS_RENEW,
            RecordTypeId = LeadHelper.RT_ID_SALES_LEADS);
        Lead testLeadOnUpdate = new Lead(
            FirstName = 'testName',
            Title = 'VP',
            Country = 'UK',
            BMID__c = 'test0122',
            LeadSource = 'Initial',
            Lastname = 'testName',
            Company = 'Google',
            Email = 'test@gmail.com',
            Phone = '9910106803',
            Status = LeadHelper.STATUS_CALL_OUT,
            RecordTypeId = LeadHelper.RT_ID_SALES_LEADS,
            Activity_First_Attempt__c = System.now(),
            Call_Attempts__c = 10,
            InContact_Dial_Attempt__c = 10,
            cas__FirstAttempt__c = System.now(),
            cas__NumberAttempts__c = 10);
        insert (new List<Lead>{testLeadOnInsert, testLeadOnUpdate});
        // Test Insert action
        List<Lead> testLeadsOnInsert = [
            SELECT Id, BMID__c, Status, Activity_First_Attempt__c, Call_Attempts__c, InContact_Dial_Attempt__c, cas__FirstAttempt__c, cas__NumberAttempts__c
            FROM Lead
        ];
        for (Lead item : testLeadsOnInsert) {
            if (item.BMID__c == 'test0121') {
                System.assertEquals(null, item.Activity_First_Attempt__c);
                System.assertEquals(0, item.Call_Attempts__c);
                System.assertEquals(0, item.InContact_Dial_Attempt__c);
                System.assertEquals(null, item.cas__FirstAttempt__c);
                System.assertEquals(0, item.cas__NumberAttempts__c);
            } else {
                System.assertNotEquals(null, item.Activity_First_Attempt__c);
                System.assertEquals(10, item.Call_Attempts__c);
                System.assertEquals(10, item.InContact_Dial_Attempt__c);
                System.assertNotEquals(null, item.cas__FirstAttempt__c);
                System.assertEquals(10, item.cas__NumberAttempts__c);
            }

        }
        testLeadOnUpdate.Status = LeadHelper.STATUS_RENEW;
        testLeadOnUpdate.Initial_Category__c = 'No Activation – Changed Mind';
        update testLeadOnUpdate;
        // Test Update action
        List<Lead> testLeadsOnUpdate = [
            SELECT Id, BMID__c, Status, Activity_First_Attempt__c, Call_Attempts__c, InContact_Dial_Attempt__c, cas__FirstAttempt__c, cas__NumberAttempts__c
            FROM Lead
        ];
        for (Lead item : testLeadsOnUpdate) {
            System.assertEquals(null, item.Activity_First_Attempt__c);
            System.assertEquals(0, item.Call_Attempts__c);
            System.assertEquals(0, item.InContact_Dial_Attempt__c);
            System.assertEquals(null, item.cas__FirstAttempt__c);
            System.assertEquals(0, item.cas__NumberAttempts__c);
        }
    }

    @isTest
    static void test_PWFA_setLeadCreationDate() {
        insert new Feature_Toggle__c (LeadWorkflowRulesAndProcToTrigger__c = true);

        Lead testLeadOnInsert = new Lead(
            FirstName = 'testName',
            Title = 'VP',
            Country = 'UK',
            BMID__c = 'test0121',
            LeadSource = 'Initial',
            Lastname = 'testName',
            Company = 'Google',
            Email = 'test@gmail.com',
            Phone = '9910106803',
            Status = LeadHelper.STATUS_RENEW);
        Lead testLeadOnUpdate = new Lead(
            FirstName = 'testName',
            Title = 'VP',
            Country = 'UK',
            BMID__c = 'test0122',
            LeadSource = 'Initial',
            Lastname = 'testName',
            Company = 'Google',
            Email = 'test@gmail.com',
            Phone = '9910106803',
            Status = LeadHelper.STATUS_CALL_OUT);
        insert (new List<Lead>{testLeadOnInsert, testLeadOnUpdate});
        // Test Insert action
        List<Lead> testLeadsOnInsert = [SELECT Id, BMID__c, Lead_Creation_Date__c FROM Lead];
        for (Lead item : testLeadsOnInsert) {
            System.assertNotEquals(null, item.Lead_Creation_Date__c);
        }
    }

    @isTest
    public static void SMEmployeesDFR_whenUpdateAccountField_ShouldUpdateSMCountry(){

        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setField(Account.Name, 'Test Account')
            .setField(Account.Emp_Range_Sales_Override__c, 102)
            .create()
            .getRecord();

        Account acc2 = (Account) new SObjectBuilder(Account.SObjectType)
            .setField(Account.Name, 'Test Account2')
            .setField(Account.Emp_Range_Sales_Override__c, 159)
            .create()
            .getRecord();

        List<Lead> leads = (List<Lead>) new SObjectBuilder(Lead.sObjectType)
            .setField(Lead.lastName, 'LEAD TEST')
            .setField(Lead.BMID__c, null)
            .setField(Lead.AID__c, '1')
            .setField(Lead.PID__c, '1')
            .setField(Lead.ZI_CDP_Account_Id__c, acc.Id)
            .quantity(50)
            .create()
            .getRecords();

        Test.startTest();
            for (Lead ld : leads) {
                ld.ZI_CDP_Account_Id__c = acc2.Id;
            }
            update leads;
        Test.stopTest();

        List<Demand_Funnel__c> dfrs = (List<Demand_Funnel__c>) new DemandFunnelSelector()
            .selectDFRByLeadIds(new Object[]{leads})
            .selectField(Demand_Funnel__c.Account__c)
            .selectField(Demand_Funnel__c.SM_Employees__c)
            .executeQuery();

        System.assertEquals(50, dfrs.size(), 'There should be 50 created DFRs.');

        for (Demand_Funnel__c dfr : dfrs) {
            System.assertEquals(acc2.Id, dfr.Account__c, 'The account should be the same as the Contact');
            System.assertEquals(159, dfr.SM_Employees__c, 'The  SM EMployees should be the same as the Contact Account SM EMployees');
        }
    }
    @IsTest
    static void testRecalculateSharingForAccessControls() {
        Triggers.switchOff();
        Triggers.except('LeadTriggerHandler.accessControls');

        Set<Id> setOfLeadIds = new Set<Id>();
        List<Group> groupsList = new List<Group>();
        List<AccessControlSettings__c> accessSettingsList = new List<AccessControlSettings__c>();
        accessSettingsList.add(
                new AccessControlSettings__c(
                    Name = 'Rise America', Brand__c = 'Rise America', BusinessIdentity__c = 'Rise America',
                    Public_Group_Name__c = 'Access_Users', isParent__c = true, isActive__c = true
                ));
        accessSettingsList.add(
                new AccessControlSettings__c(
                    Name = 'Access2', Brand__c = 'Access.Abc', BusinessIdentity__c = 'Abc',
                    ParentBrand__c = 'Access', Public_Group_Name__c = 'Abc_Users', isParent__c = false, isActive__c = true
                ));
		accessSettingsList.add(
                new AccessControlSettings__c(
                    Name = 'Access3', Brand__c = 'Access.Def', BusinessIdentity__c = 'Def',
                    ParentBrand__c = 'Access', Public_Group_Name__c = 'Def_Users', isParent__c = false, isActive__c = true
                ));
        insert accessSettingsList;

        groupsList.add(
                new Group(
                    Name = 'Access Users', DeveloperName = 'Access_Users', Type = 'Regular'
                ));
        groupsList.add(
                new Group(
                    Name = 'Abc Users', DeveloperName = 'Abc_Users', Type = 'Regular'
                ));
        groupsList.add(
                new Group(
                    Name = 'Def Users', DeveloperName = 'Def_Users', Type = 'Regular'
                ));
        insert groupsList;

        List<Lead> leads = (List<Lead>) new SObjectBuilder(Lead.sObjectType)
			.setFields(
				new Map<SObjectField, Object>{
					Lead.LastName => 'Test lead',
					Lead.Lead_Brand_Name__c => ValueProviderBuilder.provideList(new List<String>{'Rise America','Rise America','Rise America','Access','Access'}),
					Lead.Sub_Brand__c => ValueProviderBuilder.provideList(new List<String>{'Access.Abc',null,null,null,null}),
					Lead.BusinessIdentity__c => ValueProviderBuilder.provideList(new List<String>{'Abc','Def',null,null,null})
				}
			)
			.quantity(5)
			.create()
			.getRecords();
        setOfLeadIds.add(leads[0].Id);
        setOfLeadIds.add(leads[1].Id);
        setOfLeadIds.add(leads[2].Id);
        setOfLeadIds.add(leads[3].Id);
        setOfLeadIds.add(leads[4].Id);

        Test.startTest();
            List<LeadShare> listNewSharing = [SELECT Id, LeadId, UserOrGroupId, RowCause, LeadAccessLevel
                                                    FROM LeadShare WHERE LeadId =:setOfLeadIds AND RowCause = 'Manual'];

            if (leads != null) {
                leads[4].Lead_Brand_Name__c = null;
                leads[3].Lead_Brand_Name__c = 'Xyz';
                leads[2].BusinessIdentity__c = 'Abc';
                leads[1].Sub_Brand__c = 'Access.Def';
            }
            update leads;
            Lead leadUpdate = [SELECT Id, Name, Lead_Brand_Name__c, Sub_Brand__c, BusinessIdentity__c FROM Lead WHERE Id =:leads[0].Id];
            leadUpdate.Lead_Brand_Name__c = 'Access';
            update leadUpdate;

            List<LeadShare> listUpdatedSharing = [SELECT Id, LeadId, UserOrGroupId, RowCause, LeadAccessLevel
                                                    FROM LeadShare WHERE LeadId =:setOfLeadIds AND RowCause = 'Manual'];
            System.assertEquals(true, listNewSharing.size() > 0, 'Manual sharing should be created on Lead insert');
            System.assertEquals(true, listUpdatedSharing.size() > 0, 'Manual sharing should be created on Lead update');
            if (!listUpdatedSharing.isEmpty()) {
                for (LeadShare ldShare : listUpdatedSharing) {
                    System.assertEquals('Edit', ldShare.LeadAccessLevel, 'Lead Access Level should be Edit');
                }
            }
        Test.stopTest();
        Triggers.switchOn();
    }

    @isTest
    static void testRemoveDowngradeValuesForNonDowngradedLeads() {
        Triggers.switchOff();
        Triggers.except('LeadTriggerHandler.RemoveDowngradeValuesForNonDowngradedLeads');

        Lead testLead = (Lead) new SObjectBuilder(Lead.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Lead.Email => 'test@email.com',
                Lead.LastName => 'TestLastName',
                Lead.Company => 'TestCompany',
                Lead.Status => LeadHelper.STATUS_DOWNGRADED,
                Lead.Downgrade_Reason__c => 'val',
                Lead.Downgrade_Reason_Other__c => 'val',
                Lead.Sub_Downgrade_Reason__c => 'val',
                Lead.Sub_Downgrade_Reason_Other__c => 'val',
                Lead.Downgrade_Other_Reason_for_Loss__c => 'val',
                Lead.Downgrade_Date__c => System.today()
            })
            .create()
            .getRecord();

        Test.startTest();

        testLead.Status = LeadHelper.STATUS_NEW;
        update testLead;

        Test.stopTest();

        Lead updatedLead = (Lead) new LeadSelector()
            .selectLeadById(new List<Id>{ testLead.Id })
            .selectFields(new List<String>{
                'Downgrade_Reason__c',
                'Downgrade_Reason_Other__c',
                'Sub_Downgrade_Reason__c',
                'Sub_Downgrade_Reason_Other__c',
                'Downgrade_Other_Reason_for_Loss__c',
                'Downgrade_Date__c'
            })
            .executeQuery()
            .get(0);

        System.assertEquals(
            updatedLead.Downgrade_Reason__c,
            null,
            'Downgrade_Reason__c should be empty for non-Downgraded Lead'
        );

        System.assertEquals(
            updatedLead.Downgrade_Reason_Other__c,
            null,
            'Downgrade_Reason_Other__c should be empty for non-Downgraded Lead'
        );

        System.assertEquals(
            updatedLead.Sub_Downgrade_Reason__c,
            null,
            'Sub_Downgrade_Reason__c should be empty for non-Downgraded Lead'
        );

        System.assertEquals(
            updatedLead.Sub_Downgrade_Reason_Other__c,
            null,
            'Sub_Downgrade_Reason_Other__c should be empty for non-Downgraded Lead'
        );

        System.assertEquals(
            updatedLead.Downgrade_Other_Reason_for_Loss__c,
            null,
            'Downgrade_Other_Reason_for_Loss__c should be empty for non-Downgraded Lead'
        );

        System.assertEquals(
            updatedLead.Downgrade_Date__c,
            null,
            'Downgrade_Date__c should be empty for non-Downgraded Lead'
        );

        Triggers.switchOn();
    }
    @isTest
    static void testwebsitevalidation() {
         Lead leadTest = (Lead) new SObjectBuilder(Lead.sObjectType)
            .setField(Lead.lastName, 'LEAD TEST')
            .setField(Lead.BMID__c, null)
            .setField(Lead.AID__c, '1')
            .setField(Lead.PID__c, '1')
            .create()
            .getRecord();
        leadTest.Website='google.com'; // Blocked website
        Test.startTest();
        Database.SaveResult result = Database.update(leadTest, false);
        Test.stopTest();
        System.assert(!result.isSuccess(), 'Updating a lead with a blocked website should fail.');
        System.assert(result.getErrors().size() > 0, 'Error should be triggered on update.');
    }
}