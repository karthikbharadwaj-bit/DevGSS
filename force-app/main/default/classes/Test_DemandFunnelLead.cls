@isTest
public with sharing class Test_DemandFunnelLead {

    static String testEmail = 'test@test1234.com';
    @testSetup
    static void createSObjects() {
        Test.startTest();
        User aeUser = (User) new SObjectBuilder(User.SObjectType)
            .setField(User.Username, Test_DemandFunnelHelper.AEUSERNAME)
            .setField(User.Email, Test_DemandFunnelHelper.AELASTNAME + Test_DemandFunnelHelper.LEADEMAIL)
            .setField(User.LastName, Test_DemandFunnelHelper.AELASTNAME)
            .setField(User.CommunityNickname, Test_DemandFunnelHelper.AECOMMUNITYNICKNAME)
            .setField(User.Team__c, Test_DemandFunnelHelper.AETEAM)
            .build()
            .getRecord();

        User aeUser2 = (User) new SObjectBuilder(User.SObjectType)
            .setField(User.Username, Test_DemandFunnelHelper.AEUSERNAME + '2')
            .setField(User.Email, Test_DemandFunnelHelper.AELASTNAME + Test_DemandFunnelHelper.LEADEMAIL + '2')
            .setField(User.LastName, Test_DemandFunnelHelper.AELASTNAME + '2')
            .setField(User.CommunityNickname, Test_DemandFunnelHelper.AECOMMUNITYNICKNAME + '2')
            .setField(User.Team__c, Test_DemandFunnelHelper.AETEAM)
            .build()
            .getRecord();

        User bdrUser = (User) new SObjectBuilder(User.SObjectType)
            .setField(User.Username, Test_DemandFunnelHelper.BDRUSERNAME)
            .setField(User.Email, Test_DemandFunnelHelper.BDRLASTNAME + Test_DemandFunnelHelper.LEADEMAIL)
            .setfield(User.LastName, Test_DemandFunnelHelper.BDRLASTNAME)
            .setField(User.CommunityNickname, Test_DemandFunnelHelper.BDRCOMMUNITYNICKNAME)
            .setField(User.Team__c, Test_DemandFunnelHelper.BDRTEAM)
            .build()
            .getRecord();

        User sdrUser = (User) new SObjectBuilder(User.SObjectType)
            .setField(User.Username, Test_DemandFunnelHelper.SDRUSERNAME)
            .setField(User.Email, Test_DemandFunnelHelper.SDRLASTNAME + Test_DemandFunnelHelper.LEADEMAIL)
            .setfield(User.LastName, Test_DemandFunnelHelper.SDRLASTNAME)
            .setField(User.CommunityNickname, Test_DemandFunnelHelper.SDRCOMMUNITYNICKNAME)
            .setField(User.Team__c, Test_DemandFunnelHelper.SDRTEAM)
            .setField(User.SegmentPicklist__c, Test_DemandFunnelHelper.SDRSEGMENT)
            .setField(User.Upmarket_Territory__c, 'testTerritory')
            .build()
            .getRecord();

        insert new List<User>{aeUser, aeUser2, bdrUser, sdrUser};

        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setField(Account.Name, 'Opty test account')
            .setField(Account.Partner_ID__c, 'testID')
            .setField(Account.Permitted_Brands__c, 'RingCentral')
            .setField(Account.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .build()
            .getRecord();
        insert new List<Account>{acc};

        new SObjectBuilder(DFR_System_Users__c.SObjectType)
            .setField(DFR_System_Users__c.Name, [SELECT Name FROM User WHERE Name = 'LeanData Queue' LIMIT 1].Id)
            .setField(DFR_System_Users__c.Description__c, 'LeanData Queue')
            .create();

        SchedulerConfiguration__c brand = (SchedulerConfiguration__c) new SObjectBuilder(
                SchedulerConfiguration__c.SObjectType
            )
            .setField(schedulerConfiguration__c.Brand_Id__c, ValueProviderBuilder.provideUniqueString())
            .setField(schedulerConfiguration__c.Name, RingCentralHelper.BRAND_RINGCENTRAL)
            .create()
            .getRecord();

        new SObjectBuilder(PriceBook2.SObjectType)
            .setField(PriceBook2.Service__c, Pricebook2Helper.SERVICE_OFFICE)
            .setField(PriceBook2.Plan__c, Pricebook2Helper.PLAN_MONTHLY)
            .setfield(PriceBook2.Edition__c, Pricebook2Helper.EDITION_STANDARD)
            .setField(PriceBook2.Brand__c, brand.Id)
            .setField(PriceBook2.IsActive, true)
            .setField(PriceBook2.Line_Range_Min__c, 1)
            .setField(PriceBook2.Line_Range_Max__c, 1000)
            .setField(PriceBook2.Tier_ID__c, ValueProviderBuilder.provideUniqueString())
            .create();

        new SObjectBuilder(Lead.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Lead.Email => 'fake@email.com',
                    Lead.LastName => 'fakeLastName',
                    Lead.Company => 'fakeCompany',
                    Lead.OwnerId => ((QueueSObject) new QueueSelector()
                            .selectQueueForDFRBySObjectType(new List<String>{ 'Lead' })
                            .executeQuery()[0])
                        .QueueId
                }
            )
            .create();

        new SObjectBuilder(Contact.SObjectType)
            .setField(Contact.FirstName, 'John')
            .setField(Contact.LastName, 'Doe')
            .setField(Contact.Email, Test_DemandFunnelHelper.LEADEMAIL)
            .setField(Contact.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Contact.Preferred_Language__c, 'en_US')
            .setField(Contact.AccountId, acc.Id)
            .create()
            .getRecord();

        Lead ld1 = (Lead) new SObjectBuilder(Lead.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Lead.Email => 'fake@email.com',
                    Lead.LastName => 'fakeLastName',
                    Lead.Company => 'fakeCompany',
                    Lead.OwnerId => ((QueueSObject) new QueueSelector()
                            .selectQueueForDFRBySObjectType(new List<String>{ 'Lead' })
                            .executeQuery()[0])
                        .QueueId
                }
            )
            .build()
            .getRecord();

        Lead aeLead = (Lead) new SObjectBuilder(Lead.SObjectType)
            .setField(Lead.LastName, Test_DemandFunnelHelper.LEADLASTNAME)
            .setField(Lead.Status, LeadTriggerHelper.LEADSTATUSOPEN)
            .setField(Lead.Email, Test_DemandFunnelHelper.LEADEMAIL)
            .setField(Lead.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Lead.LeadSource, Test_DemandFunnelHelper.LEADSOURCE)
            .setField(
                Lead.RecordTypeId,
                Lead.SObjectType.getDescribe().getRecordTypeInfosByName().get('Sales Leads').getRecordTypeId()
            )
            .setField(Lead.OwnerId, aeUser.Id)
            .build()
            .getRecord();

        Lead bdrLead = (Lead) new SObjectBuilder(Lead.SObjectType)
            .setField(Lead.LastName, Test_DemandFunnelHelper.LEADLASTNAME + 'bdr')
            .setField(Lead.Email, Test_DemandFunnelHelper.LEADEMAIL)
            .setField(Lead.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Lead.Status, LeadTriggerHelper.LEADSTATUSSUSPECT)
            .setField(Lead.LeadSource, Test_DemandFunnelHelper.LEADSOURCE)
            .setField(
                Lead.RecordTypeId,
                Lead.SObjectType.getDescribe().getRecordTypeInfosByName().get('Sales Leads').getRecordTypeId()
            )
            .setField(Lead.OwnerId, bdrUser.Id)
            .build()
            .getRecord();
        
        Lead bdrnewLead = (Lead) new SObjectBuilder(Lead.SObjectType)
            .setField(Lead.LastName, Test_DemandFunnelHelper.LEADLASTNAME + 'bdr new')
            .setField(Lead.Email, Test_DemandFunnelHelper.LEADEMAIL)
            .setField(Lead.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Lead.Status, LeadTriggerHelper.LEADSTATUSNEW)
            .setField(Lead.LeadSource, Test_DemandFunnelHelper.LEADSOURCE)
            .setField(
                Lead.RecordTypeId,
                Lead.SObjectType.getDescribe().getRecordTypeInfosByName().get('Sales Leads').getRecordTypeId()
            )
            .setField(Lead.OwnerId, bdrUser.Id)
            .build()
            .getRecord();
        
        insert new List<Lead>{ld1, aeLead, bdrLead, bdrnewLead};

        Opportunity opp = (opportunity)new SObjectBuilder(Opportunity.SObjectType)
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
            .build()
            .getRecord();

        Opportunity oppbdr = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setField(Opportunity.Name, 'Test Opportunity bdr')
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
            .build()
            .getRecord();

        Opportunity oppae = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setField(Opportunity.Name, 'Test Opportunity ae')
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
            .build()
            .getRecord();

        insert new List<Opportunity>{opp, oppbdr, oppae};

        Test.stopTest();
    }


    @isTest
    static void testCreateLeadDFRQueueOwner() {
        QueueSobject testQueue = (QueueSObject) new QueueSelector()
            .selectQueueForDFRBySObjectType(new List<String>{ 'Lead' })
            .executeQuery()[0];

        Lead testLead = (Lead) new LeadSelector().selectLeads().executeQuery()[0];

        Test.startTest();

        TriggerHandler.BY_PASS_LEAD_UPDATE_ON_INSERT = false;
        TriggerHandler.BY_PASS_LEAD_UPDATE = false;
        testLead.Status = LeadTriggerHelper.LEADSTATUSOPEN;
        update testlead;
        DG_DFR_Class.CreateLeadDFR(new List<Lead>{ testlead });

        Test.stopTest();

        Demand_Funnel__c assertDFR = Test_DemandFunnelHelper.getDFRS(testLead, new List<String>{ 'Prospect_Owner_Name__c' })[0];

        System.assertEquals(
            testQueue.Queue.Name,
            assertDFR.Prospect_Owner_Name__c,
            'Lead Owner as Queue should be saved into the DFR'
        );
    }

    @isTest
    static void testDFR_LeadStatusChangeQueueOwner() {
        QueueSobject testQueue = (QueueSObject) new QueueSelector()
            .selectQueueForDFRBySObjectType(new List<String>{ 'Lead' })
            .executeQuery()[0];

        Lead oldTestlead = (Lead) new LeadSelector().selectLeads().executeQuery()[0];
        oldTestlead.Status = LeadTriggerHelper.LEADSTATUSOPEN;

        TriggerHandler.BY_PASS_LEAD_UPDATE_ON_INSERT = false;
        TriggerHandler.BY_PASS_LEAD_UPDATE = false;
        update oldTestLead;

        Lead newTestLead = oldTestlead;
        newTestLead.Status = LeadTriggerHelper.LEADSTATUSNEW;

        DG_DFR_Class.CreateLeadDFR(new List<Lead>{ oldTestlead });
        Test.startTest();

        DG_DFR_Class.DFR_LeadStatusChange(
            new List<Lead>{ newTestLead },
            new Map<Id, Lead>(new List<Lead>{ oldTestLead })
        );
        update newTestLead;
        Test.stopTest();

        Demand_Funnel__c assertDFR = Test_DemandFunnelHelper.getDFRS(oldTestLead, new List<String>{ 'MQL_Owner_Name__c' })[0];

        System.assertEquals(
            testQueue.Queue.Name,
            assertDFR.MQL_Owner_Name__c,
            'MQL Owner Name should be the Lead Queue Owner'
        );
    }

    @isTest
    static void testDFR_ChangeLeadOwnerQueueOwner() {
        QueueSobject testQueue = (QueueSObject) new QueueSelector()
            .selectQueueForDFRBySObjectType(new List<String>{ 'Lead' })
            .executeQuery()[0];

        Lead oldTestlead = (Lead) new LeadSelector().selectLeads().executeQuery()[0];
        oldTestlead.Status = LeadTriggerHelper.LEADSTATUSOPEN;

        TriggerHandler.BY_PASS_LEAD_UPDATE_ON_INSERT = false;
        TriggerHandler.BY_PASS_LEAD_UPDATE = false;
        update oldTestLead;

        DG_DFR_Class.CreateLeadDFR(new List<Lead>{ oldTestlead });

        Lead newTestLead = oldTestlead.clone(true, true, true, false);
        newTestLead.OwnerId = testQueue.QueueId;
        for (String userId : DG_DFR_Class_Helper.getDFRSystemUsers().keySet()) {
            break;
        }

        Test.startTest();

        DG_DFR_Class.DFR_ChangeLeadOwner(
            new List<Lead>{ newTestLead },
            new Map<Id, Lead>(new List<Lead>{ oldTestLead })
        );

        Test.stopTest();

        Demand_Funnel__c assertDFR = Test_DemandFunnelHelper.getDFRS(oldTestLead, new List<String>{ 'Prospect_Owner_Name__c' })[0];

        System.assertEquals(
            testQueue.Queue.Name,
            assertDFR.Prospect_Owner_Name__c,
            'Prospect_Owner_Name__c should be the Lead Queue Owner'
        );
    }

    @isTest
    static void testMQLHandOff_OnUpdateQueueOwner() {
        Set<String> userIds = new Set<String>();
        for (String key : DG_DFR_Class_Helper.getDFRSystemUsers().keySet()) {
            userIds.add(key);
        }
        List<Object> bindings = new List<Object>();
        bindings.add(userIds);
        User marketingUser = (User) new UserSelector()
            .selectUsersByIdNoFields(bindings)
            .selectFields(new List<String>{ 'Profile.Name' })
            .setCondition('IsActive = true AND Name = \'LeanData Queue\'')
            .executeQuery()[0];
        QueueSobject testQueue = (QueueSObject) new QueueSelector()
            .selectQueueForDFRBySObjectType(new List<String>{ 'Lead' })
            .executeQuery()[0];

        Test.startTest();

        Lead oldTestlead = (Lead) new LeadSelector().selectLeads().executeQuery()[0];
        oldTestlead.Status = LeadTriggerHelper.LEADSTATUSOPEN;

        TriggerHandler.BY_PASS_LEAD_UPDATE_ON_INSERT = false;
        TriggerHandler.BY_PASS_LEAD_UPDATE = false;
        update oldTestLead;

        DG_DFR_Class.CreateLeadDFR(new List<Lead>{ oldTestlead });

        Test.stopTest();

        Demand_Funnel__c testDFR = Test_DemandFunnelHelper.getDFRS(
            oldTestLead,
            new List<String>{ 'MQL_Owner_Name__c', 'MQL_DateTime_Entered__c', 'MQL_DateTime_Exited__c' }
        )[0];

        testDFR.MQL_DateTime_Entered__c = System.now();
        update testDFR;

        Lead newTestLead = oldTestlead.clone(true, true, true, false);
        oldTestLead.OwnerId = testQueue.QueueId;
        for (String userId : DG_DFR_Class_Helper.getDFRSystemUsers().keySet()) {
            newTestLead.OwnerId = userId;
            break;
        }

        DG_DFR_Class.MQLHandOff_OnUpdate(
            new List<Lead>{ newTestLead },
            new Map<Id, Lead>(new List<Lead>{ oldTestLead })
        );

        Demand_Funnel__c assertDFR = Test_DemandFunnelHelper.getDFRS(
            oldTestLead,
            new List<String>{ 'MQL_Owner_Name__c', 'MQL_DateTime_Entered__c', 'MQL_DateTime_Exited__c' }
        )[0];

        System.assertEquals(
            'LeanData Queue',
            assertDFR.MQL_Owner_Name__c,
            'MQL Owner Name should be the Lead Queue Owner'
        );
    }

    @isTest
    static void testDFR_ConvertLeadQueueOwner() {
        Test.startTest();
        QueueSobject testQueue = (QueueSObject) new QueueSelector()
            .selectQueueForDFRBySObjectType(new List<String>{ 'Lead' })
            .executeQuery()[0];

        Lead leadToConvert = (Lead) new LeadSelector().selectLeads().executeQuery()[0];

        leadToConvert.OwnerId = testQueue.QueueId;
        leadToConvert.Status = LeadTriggerHelper.LEADSTATUSOPEN;

        TriggerHandler.BY_PASS_LEAD_UPDATE_ON_INSERT = false;
        TriggerHandler.BY_PASS_LEAD_UPDATE = false;
        update leadToConvert;

        DG_DFR_Class.CreateLeadDFR(new List<Lead>{ leadToConvert });

        Test.stopTest();

        Demand_Funnel__c testDFR = Test_DemandFunnelHelper.getDFRS(
            leadToConvert,
            new List<String>{ 'MQL_Owner_Name__c', 'MQL_DateTime_Entered__c', 'MQL_DateTime_Exited__c' }
        )[0];
        testDFR.Lead__c = leadToConvert.Id;
        update testDFR;

        DG_DFR_Class.DFR_ConvertLead(leadToConvert);

        Demand_Funnel__c assertDFR = Test_DemandFunnelHelper.getDFRS(
            leadToConvert,
            new List<String>{
                'MQL_Owner_Name__c',
                'SAL_Owner_Name__c',
                'SQL_Owner_Name__c',
                'Prospect_Owner_Name__c',
                'TAL_Owner_Name__c',
                'TQL_Owner_Name__c'
            }
        )[0];

        System.assertEquals(
            testQueue.Queue.Name,
            assertDFR.Prospect_Owner_Name__c,
            'Prospect Owner Name should be the Lead Queue Owner'
        );
    }

    @isTest
    static void MQLUpdateOnLeanDataNoUpdateRequired() {
        UserSelector uSelector = new UserSelector();
        User someUser = (User) new SObjectBuilder(User.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(User.SObjectType))
            .setField(User.LastName, 'UniqueLastName')
            .create()
            .getRecord();
        Lead insertedLead;
        System.runAs(someUser) {
            insertedLead = (Lead) new SObjectBuilder(Lead.SObjectType)
                .setFields(SObjectFactoryFieldDefaults.getDefaults(Lead.SObjectType))
                .setfield(Lead.Status, LeadTriggerHelper.LEADSTATUSOPEN)
                .create()
                .getRecord();
        }
        insertedLead.Routing_Reason__c = 'someRoutingReason';

        Test.startTest();
        someUser.FirstName = 'notSoUniqueFirstName';
        update someUser;
        update insertedLead;
        Test.stopTest();
        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRList(new List<Lead>{ insertedLead });
        someUser = (User) uSelector.selectUserByLastName(new List<Object>{ 'UniqueLastName' }).executeQuery()[0];
        System.assertNotEquals(
            someUser.Name,
            dfrList[0].MQL_Owner_Name__c,
            'The Owner name in DFR record MQL fields shouldnt have been updated' +
            ' - no update of owner id on lead nor routing reason'
        );
    }

    @isTest
    static void MQLUpdateOnLeanDataUpdateRequired() {
        UserSelector uSelector = new UserSelector();
        User someUser = (User) new SObjectBuilder(User.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(User.SObjectType))
            .setField(User.LastName, 'UniqueLastName')
            .setField(User.FirstName, 'UniqueFirstName')
            .create()
            .getRecord();
        Lead insertedLead;
        System.runAs(someUser) {
            insertedLead = (Lead) new SObjectBuilder(Lead.SObjectType)
                .setFields(SObjectFactoryFieldDefaults.getDefaults(Lead.SObjectType))
                .setfield(Lead.Status, LeadTriggerHelper.LEADSTATUSOPEN)
                .setField(Lead.Routing_Reason__c, DG_DFR_Class.REROUTED_MARKETO_MQL_STATUS_UPDATE)
                .create()
                .getRecord();
        }
        insertedLead.Routing_Reason__c = 'someRoutingReason';
        Test.startTest();
        someUser.firstName = 'noSoUniqueFirstName';
        update someUser;
        update insertedLead;
        Test.stopTest();
        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRList(new List<Lead>{ insertedLead });
        someUser = (User) uSelector.selectUserByLastName(new List<Object>{ 'UniqueLastName' }).executeQuery()[0];
        System.assertEquals(
            someUser.Name,
            dfrList[0].MQL_Owner_Name__c,
            'The Owner name in DFR record MQL fields should have been updated'
        );
    }
    @isTest
    static void testDFRShouldGoIntoTAL() {
        User aeUser = (User) new UserSelector().selectUserByLastName(new List<String>{ Test_DemandFunnelHelper.AELASTNAME }).executeQuery()[0];
        User sdrUser = (User) new UserSelector()
            .selectUserByLastName(new List<String>{ Test_DemandFunnelHelper.SDRLASTNAME })
            .executeQuery()[0];

        Lead ld = (Lead) new SObjectBuilder(Lead.SObjectType)
            .setField(Lead.OwnerId, aeUser.Id)
            .setField(Lead.Status, LeadTriggerHelper.LEADSTATUSSUSPECT)
            .setField(Lead.LastName, Test_DemandFunnelHelper.LEADLASTNAME)
            .setField(Lead.Email, testEmail)
            .setField(Lead.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Lead.LeadSource, Test_DemandFunnelHelper.LEADSOURCE)
            .create()
            .getRecord();

        Test.startTest();
        ld.OwnerId = sdrUser.Id;
        update ld;
        ld.Status = LeadTriggerHelper.LEADSTATUSCONTACTED;
        update ld;
        Test.stopTest();

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRS(ld, new List<String>{ 'DET_Current_Funnel_Status__c' });

        System.assertEquals(
            Test_DemandFunnelHelper.TALFUNNELSTATUS,
            dfrList[0].DET_Current_Funnel_Status__c,
            'If the Owner Team was SDR, the DFR Status should be TAL'
        );
    }

    @isTest
    static void testDFRShouldGoIntoTQL() {
        User aeUser = (User) new UserSelector().selectUserByLastName(new List<String>{ Test_DemandFunnelHelper.AELASTNAME }).executeQuery()[0];
        User sdrUser = (User) new UserSelector()
            .selectUserByLastName(new List<String>{ Test_DemandFunnelHelper.SDRLASTNAME })
            .executeQuery()[0];

        Lead ld = (Lead) new SObjectBuilder(Lead.SObjectType)
            .setField(Lead.OwnerId, sdrUser.Id)
            .setField(Lead.Status, LeadTriggerHelper.LEADSTATUSOPEN)
            .setField(Lead.LastName, Test_DemandFunnelHelper.LEADLASTNAME)
            .setField(Lead.Email, testEmail)
            .setField(Lead.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Lead.LeadSource, Test_DemandFunnelHelper.LEADSOURCE)
            .create()
            .getRecord();
        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRS(ld, new List<String>{ 'TQL_Owner_Name__c' , 'MQL_Owner_Team__c'});
    
        ld.Status = LeadTriggerHelper.LEADSTATUSCONTACTED;
        update ld;

        Test.startTest();
        ld.OwnerId = aeUser.Id;
        update ld;
        Test.stopTest();

        dfrList = Test_DemandFunnelHelper.getDFRS(ld, new List<String>{ 'TQL_Owner_Name__c' });

        System.assertEquals(
            sdrUser.LastName,
            dfrList[0].TQL_Owner_Name__c,
            'DFR should stamp TQL when MQL Team contains SDR or BDR'
        );
    }

    @isTest
    static void testDFRShouldBackfillTALOnCreation() {
        User sdrUser = (User) new UserSelector()
            .selectUserByLastName(new List<String>{ Test_DemandFunnelHelper.SDRLASTNAME })
            .executeQuery()[0];

        Test.startTest();
        Lead ld = (Lead) new SObjectBuilder(Lead.SObjectType)
            .setField(Lead.OwnerId, sdrUser.Id)
            .setField(Lead.LastName, Test_DemandFunnelHelper.LEADLASTNAME)
            .setField(Lead.Status, LeadTriggerHelper.LEADSTATUSCONTACTED)
            .setField(Lead.Email, testEmail)
            .setField(Lead.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Lead.LeadSource, Test_DemandFunnelHelper.LEADSOURCE)
            .createAsUser(sdrUser)
            .getRecord();
        Test.stopTest();

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRS(ld, new List<String>{ 'DET_Current_Funnel_Status__c' });

        System.assertEquals(
            Test_DemandFunnelHelper.TALFUNNELSTATUS,
            dfrList[0].DET_Current_Funnel_Status__c,
            'If the Owner Team was SDR, the DFR Status should be TAL'
        );
    }
    @isTest
    static void testDFRSegmentFieldBeingPopulated() {
        User sdrUser = (User) new UserSelector()
            .selectUserByLastName(new List<String>{ Test_DemandFunnelHelper.SDRLASTNAME })
            .executeQuery()[0];
        Lead ld = (Lead) new SObjectBuilder(Lead.SObjectType)
            .setField(Lead.LastName, Test_DemandFunnelHelper.LEADLASTNAME)
            .setField(Lead.Status, LeadTriggerHelper.LEADSTATUSOPEN)
            .setField(Lead.Email, testEmail)
            .setField(Lead.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Lead.LeadSource, Test_DemandFunnelHelper.LEADSOURCE)
            .create()
            .getRecord();

        Test.startTest();
        ld.Status = LeadTriggerHelper.LEADSTATUSCONTACTED;
        ld.OwnerId = sdrUser.Id;
        update ld;
        Test.stopTest();

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRS(
            ld,
            new List<String>{ 'MQL_Owner_Segment__c', 'TAL_Owner_Segment__c' }
        );

        System.assertEquals(
            Test_DemandFunnelHelper.SDRSEGMENT,
            dfrList[0].MQL_Owner_Segment__c,
            'The DFR segment should be populated for this stage'
        );
        System.assertEquals(
            Test_DemandFunnelHelper.SDRSEGMENT,
            dfrList[0].TAL_Owner_Segment__c,
            'The DFR segment should be populated for this stage'
        );
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void TALDowngradedLogicOnLeadStatusChange() {
        User someUser = (User) new SObjectBuilder(User.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(User.SObjectType))
            .setField(User.LastName, 'UniqueLastName')
            .setField(User.FirstName, 'UniqueFirstName')
            .setField(User.Team__c, 'DEFAULT')
            .create()
            .getRecord();
        Lead oldLead = (Lead) new SObjectBuilder(Lead.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(Lead.SObjectType))
            .setfield(Lead.Status, '2. Contacted')
            .setField(Lead.OwnerId, someUser.id)
            .create()
            .getRecord();
        Lead newLead = oldLead.clone(true, true, false, false);

        Test.startTest();
        DG_DFR_Class.DFR_LeadStatusChange(new List<Lead>{ newLead }, new Map<Id, Lead>{ oldLead.id => oldLead });
        Test.stopTest();
        Demand_Funnel__c createdDFR = Test_DemandFunnelHelper.getDFRS(newLead, new List<String>{ 'TAL_DateTime_Entered__c' })[0];
        //System.assertEquals(null, createdDFR.TAL_DateTime_Entered__c, 'DFR Shouldnt have gone into TAL');
    }

    @isTest
    static void TALDateTimeEnteredIsAlwaysFilled() {
        User systemUser = (User) new SObjectBuilder(User.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(User.SObjectType))
            .setField(User.LastName, 'LAR System User')
            .create()
            .getRecord();
        Lead oldLead = new Lead();
        System.runAs(systemUser) {
            oldLead = (Lead) new SObjectBuilder(Lead.SObjectType)
                .setFields(SObjectFactoryFieldDefaults.getDefaults(Lead.SObjectType))
                .setfield(Lead.Status, '1.5 Call Out')
                .create()
                .getRecord();
        }

        User sdrUser = (User) new SObjectBuilder(User.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(User.SObjectType))
            .setField(User.LastName, 'UniqueLastName')
            .setField(User.FirstName, 'UniqueFirstName')
            .setField(User.Team__c, 'SDR')
            .create()
            .getRecord();
        oldLead.OwnerId = sdrUser.Id;
        update oldLead;
        Test.startTest();
        oldLead.Status = '2. Contacted';
        update oldLead;
        Test.stopTest();
        Demand_Funnel__c createdDFR = Test_DemandFunnelHelper.getDFRS(oldLead, new List<String>{ 'TAL_Entered_From__c', 'TAL_Owner_Id__c' })[0];
        System.assert(createdDFR.TAL_Owner_Id__c != null, 'TAL Owner fields should be mapped');
        System.assert(
            createdDFR.TAL_Entered_From__c != null,
            'TAL Entered From shouldnt be null if owner fields are mapped'
        );
    }

    @IsTest
    static void testLeadDFRMultipleDowngrade() {
        Lead oldLead = (Lead) new SObjectBuilder(Lead.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(Lead.SObjectType))
            .setfield(Lead.Status, 'X. Suspect')
            .create()
            .getRecord();
        oldLead.Status = '0. Downgraded';
        oldLead.Downgrade_Reason__c = 'AT&T Seller';
        oldLead.Sub_Downgrade_Reason__c = 'AT&T';
        update oldLead;
        oldLead.Status = '1. New';
        update oldLead;
        Test.startTest();
        oldLead.Status = '0. Downgraded';
        oldLead.Downgrade_Reason__c = 'AT&T Seller';
        oldLead.Sub_Downgrade_Reason__c = 'AT&T';
        update oldLead;
        oldLead.Status = '1. New';
        update oldLead;
        oldLead.Status = '0. Downgraded';
        oldLead.Downgrade_Reason__c = 'AT&T Seller';
        oldLead.Sub_Downgrade_Reason__c = 'AT&T';
        update oldLead;
        Test.stopTest();
        List<Demand_Funnel__c> createdDFRs = Test_DemandFunnelHelper.getDFRS(oldLead, new List<String>{ 'DFR_Active_Status__c' });
        Boolean isAnyDFRActive = false;
        for (Demand_Funnel__c dfr : createdDFRs) {
            if (dfr.DFR_Active_Status__c == 'Active') {
                isAnyDFRActive = true;
            }
        }
        System.assertEquals(2, createdDFRs.size(), 'There should only be two DFRs created');
        System.assert(!isAnyDFRActive, 'No DFRs should be active since all of them were downgraded');
    }

    @isTest
    static void testDFRTerritoryFieldBeingPopulated() {
        User sdrUser = (User) new UserSelector()
            .selectUserByLastName(new List<String>{ Test_DemandFunnelHelper.SDRLASTNAME })
            .selectField('Upmarket_Territory__c')
            .executeQuery()[0];

        Lead ld = (Lead) new SObjectBuilder(Lead.SObjectType)
            .setField(Lead.LastName, Test_DemandFunnelHelper.LEADLASTNAME)
            .setField(Lead.Status, LeadTriggerHelper.LEADSTATUSOPEN)
            .setField(Lead.Email, testEmail)
            .setField(Lead.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Lead.LeadSource, Test_DemandFunnelHelper.LEADSOURCE)
            .create()
            .getRecord();

        Test.startTest();
        ld.Status = LeadTriggerHelper.LEADSTATUSCONTACTED;
        ld.OwnerId = sdrUser.Id;
        update ld;
        Test.stopTest();

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRS(
            ld,
            new List<String>{ 'MQL_Owner_Territory__c', 'TAL_Owner_Territory__c' }
        );

        System.assertEquals(
            sdrUser.Upmarket_Territory__c,
            dfrList[0].MQL_Owner_Territory__c,
            'The DFR territory should be populated'
        );
        System.assertEquals(
            sdrUser.Upmarket_Territory__c,
            dfrList[0].TAL_Owner_Territory__c,
            'The DFR territory should be populated'
        );
    }

    @isTest
    static void testMQLEnteredFromPopulatedCorrectly() {
        User sdrUser = (User) new UserSelector()
            .selectUserByLastName(new List<String>{ Test_DemandFunnelHelper.SDRLASTNAME })
            .executeQuery()[0];

        Lead ld = (Lead) new SObjectBuilder(Lead.SObjectType)
            .setField(Lead.LastName, Test_DemandFunnelHelper.LEADLASTNAME)
            .setField(Lead.Status, LeadTriggerHelper.LEADSTATUSRENEW)
            .setField(Lead.Email, testEmail)
            .setField(Lead.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Lead.LeadSource, Test_DemandFunnelHelper.LEADSOURCE)
            .create()
            .getRecord();

        ld.OwnerId = sdrUser.Id;
        update ld;

        Test.startTest();
        ld.Status = LeadTriggerHelper.LEADSTATUSCONTACTED;
        update ld;
        Test.stopTest();
        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRS(ld, new List<String>{ 'MQL_Entered_From__c' });

        System.assertEquals(
            'Created',
            dfrList[0].MQL_Entered_From__c,
            'The DFR MQL entered From field was populated incorrectly'
        );
    }

    @isTest
    static void testMQLEnteredFromPopulatedCorrectlyOnOwnerChange() {
        User sdrUser = (User) new UserSelector()
            .selectUserByLastName(new List<String>{ Test_DemandFunnelHelper.SDRLASTNAME })
            .executeQuery()[0];

        Lead ld = (Lead) new SObjectBuilder(Lead.SObjectType)
            .setField(Lead.LastName, Test_DemandFunnelHelper.LEADLASTNAME)
            .setField(Lead.Status, LeadTriggerHelper.LEADSTATUSOPEN)
            .setField(Lead.Email, testEmail)
            .setField(Lead.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Lead.LeadSource, Test_DemandFunnelHelper.LEADSOURCE)
            .create()
            .getRecord();

        ld.Status = LeadTriggerHelper.LEADSTATUSNEW;
        update ld;

        Test.startTest();
        ld.OwnerId = sdrUser.Id;
        update ld;
        Test.stopTest();

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRS(ld, new List<String>{ 'MQL_Entered_From__c' });

        System.assertEquals(
            'Prospect',
            dfrList[0].MQL_Entered_From__c,
            'The DFR MQL entered From field was populated incorrectly'
        );
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testMQLExitedToPopulatedCorrectlyOnOwnerChange() {
        User sdrUser = (User) new UserSelector()
            .selectUserByLastName(new List<String>{ Test_DemandFunnelHelper.SDRLASTNAME })
            .executeQuery()[0];

        Lead ld = (Lead) new SObjectBuilder(Lead.SObjectType)
            .setField(Lead.LastName, Test_DemandFunnelHelper.LEADLASTNAME)
            .setField(Lead.Status, LeadTriggerHelper.LEADSTATUSRENEW)
            .setField(Lead.Email, testEmail)
            .setField(Lead.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Lead.LeadSource, Test_DemandFunnelHelper.LEADSOURCE)
            .create()
            .getRecord();

        ld.Status = LeadTriggerHelper.LEADSTATUSCONTACTED;
        update ld;

        Test.startTest();
        ld.OwnerId = sdrUser.Id;
        update ld;
        Test.stopTest();

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRS(ld, new List<String>{ 'MQL_Exited_To__c' });

        //System.assertEquals(Test_DemandFunnelHelper.SAL, dfrList[0].MQL_Exited_To__c, 'The DFR MQL Exited To field was populated incorrectly');
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testProspectExitedToPopulatedCorrectlyOnOwnerChange() {
        User sdrUser = (User) new UserSelector()
            .selectUserByLastName(new List<String>{ Test_DemandFunnelHelper.SDRLASTNAME })
            .executeQuery()[0];

        Lead ld = (Lead) new SObjectBuilder(Lead.SObjectType)
            .setField(Lead.LastName, Test_DemandFunnelHelper.LEADLASTNAME)
            .setField(Lead.Status, LeadTriggerHelper.LEADSTATUSOPEN)
            .setField(Lead.Email, testEmail)
            .setField(Lead.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Lead.LeadSource, Test_DemandFunnelHelper.LEADSOURCE)
            .create()
            .getRecord();

        ld.Status = LeadTriggerHelper.LEADSTATUSCONTACTED;
        update ld;

        Test.startTest();
        ld.OwnerId = sdrUser.Id;
        update ld;
        Test.stopTest();

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRS(ld, new List<String>{ 'Prospect_Exited_To__c' });

        //System.assertEquals(Test_DemandFunnelHelper.SAL, dfrList[0].Prospect_Exited_To__c, 'The DFR MQL Exited To field was populated incorrectly');
    }

    @isTest
    static void testSALDeletedCorrectlyOnOwnerChange() {
        Set<String> userIds = new Set<String>();
        for (String key : DG_DFR_Class_Helper.getDFRSystemUsers().keySet()) {
            userIds.add(key);
        }
        List<Object> bindings = new List<Object>();
        bindings.add(userIds);
        User systemUser = (User) new SObjectBuilder(User.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(User.SObjectType))
            .setField(User.LastName, 'LAR System User')
            .create()
            .getRecord();
        systemUser.Team__c = 'Not Null Team';

        Lead ld = (Lead) new SObjectBuilder(Lead.SObjectType)
            .setField(Lead.LastName, Test_DemandFunnelHelper.LEADLASTNAME)
            .setField(Lead.Status, LeadTriggerHelper.LEADSTATUSCONTACTED)
            .setField(Lead.Email, testEmail)
            .setField(Lead.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Lead.LeadSource, Test_DemandFunnelHelper.LEADSOURCE)
            .setField(Lead.OwnerId, systemUser.Id)
            .build()
            .getRecord();

        System.runAs(systemUser) {
            insert ld;
        }
        User sdrUser = (User) new UserSelector()
            .selectUserByLastName(new List<String>{ Test_DemandFunnelHelper.SDRLASTNAME })
            .executeQuery()[0];

        Test.startTest();
        ld.OwnerId = sdrUser.Id;
        update ld;
        Test.stopTest();

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRS(ld, new List<String>{ 'TAL_Owner_Name__c', 'SAL_Owner_Name__c' });

        System.assert(
            String.isNotBlank(dfrList[0].TAL_Owner_Name__c),
            'The DFR TAL fields shouldnt have been deleted on this particular owner change'
        );
        System.assert(
            String.isBlank(dfrList[0].SAL_Owner_Name__c),
            'The DFR SAL fields should have been deleted on this particular owner change'
        );
    }

    //Test Case CRM-21093
    @isTest
    static void testLeadConversionCreatingOpportunity() {
        User aeUser = (User) new UserSelector().selectUserByLastName(new List<String>{ Test_DemandFunnelHelper.AELASTNAME }).executeQuery()[0];
        Pricebook2 pb = Test_DemandFunnelHelper.getPriceBooks();
        Account acc = (Account) new AccountSelector().selectAccounts().executeQuery()[0];
        Contact con = (Contact) new ContactSelector().selectContacts().executeQuery()[0];
        Lead ld = (Lead) new LeadSelector().selectLeadByLastName(new List<Object>{Test_DemandFunnelHelper.LEADLASTNAME}).executeQuery()[0];

        ConvertLead.ConvertLeadDTO convertLeadData = new ConvertLead.ConvertLeadDTO();
        convertLeadData.leadId = ld.Id;
        convertLeadData.isCreateContact = false;
        convertLeadData.isBilling = false;
        convertLeadData.isCreateAccount = false;
        convertLeadData.isCreateOpportunity = true;
        convertLeadData.isCreateQuote = false;
        convertLeadData.opportunityName = 'my test opportunity from SalesLead';
        convertLeadData.upsellStatus = QuoteHelper.STATUS_NEW_CUSTOMER;
        convertLeadData.forecastedUsers = 0;
        convertLeadData.ccForecastedUsers = 0;
        convertLeadData.pricebook2Id = pb.Id;
        convertLeadData.accountId = acc.Id;
        convertLeadData.contactId = con.id;
        convertLeadData.doNotCreateOpportunity = false;

        ConvertLead.prepareLeadRecord(convertLeadData);
        Test.startTest();
        Response result = ConvertLead.convertPart1(convertLeadData);
        ConvertLeadData.opportunityId = (Id) result.data.get(ConvertLead.OPPORTUNITYID_RESPONSE_IDENTIFIER);
        Test.stopTest();
        ConvertLead.convertPart2(ConvertLeadData);
        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRS(
            ld,
            new List<String>{
                'Lead__c',
                'Contact__c',
                'Opportunity__c',
                'Account__c',
                'DET_Current_Sub_Status__c',
                'SAL_isContact__c',
                'isConverted__c',
                'isPrimary__c',
                'isContactMerge__c'
            }
        );

        System.assertEquals(ld.Id, dfrList[0].Lead__c, 'Lead__c incorrect value');
        System.assertEquals(
            result.data.get(ConvertLead.OPPORTUNITYID_RESPONSE_IDENTIFIER),
            dfrList[0].Opportunity__c,
            'Opportunity__c incorrect value'
        );
        System.assertEquals(acc.Id, dfrList[0].Account__c, 'Account__c incorrect value');
        System.assertEquals(
            Test_DemandFunnelHelper.SQLFUNNELSTATUS,
            dfrList[0].DET_Current_Funnel_Status__c,
            'DET_Current_Funnel_Status__c incorrect value'
        );
        System.assertEquals(false, dfrList[0].SAL_isContact__c, 'SAL_isContact__c incorrect value');
        System.assertEquals(true, dfrList[0].isConverted__c, 'isConverted__c incorrect value');
        System.assertEquals(true, dfrList[0].isPrimary__c, 'isPrimary__c incorrect value');
        System.assertEquals(true, dfrList[0].isContactMerge__c, 'isContactMerge__c incorrect value');
    }

    //Test Case CRM-21094
    @isTest
    static void testLeadConversionSelectingOpportunity() {
        User aeUser = (User) new UserSelector().selectUserByLastName(new List<String>{ Test_DemandFunnelHelper.AELASTNAME }).executeQuery()[0];
        Pricebook2 pb = Test_DemandFunnelHelper.getPriceBooks();
        Account acc = (Account) new AccountSelector().selectAccounts().executeQuery()[0];
        Contact con = (Contact) new ContactSelector().selectContacts().executeQuery()[0];
        Opportunity opp = (Opportunity) new OpportunitySelector().selectOpportunityByName('Test Opportunity').executeQuery()[0];

        Lead ld = (Lead) new LeadSelector().selectLeadByLastName(new List<Object>{Test_DemandFunnelHelper.LEADLASTNAME}).executeQuery()[0];

        Demand_Funnel__c dfr = (Demand_Funnel__c) new SObjectBuilder(Demand_Funnel__c.SObjectType)
            .setField(Demand_Funnel__c.Lead__c, ld.Id)
            .create()
            .getRecord();

        ConvertLead.ConvertLeadDTO convertLeadData = new ConvertLead.ConvertLeadDTO();
        convertLeadData.leadId = ld.Id;
        convertLeadData.isCreateContact = false;
        convertLeadData.isBilling = false;
        convertLeadData.isCreateAccount = false;
        convertLeadData.isCreateOpportunity = false;
        convertLeadData.isCreateQuote = false;
        convertLeadData.upsellStatus = QuoteHelper.STATUS_NEW_CUSTOMER;
        convertLeadData.pricebook2Id = pb.Id;
        convertLeadData.accountId = acc.Id;
        convertLeadData.contactId = con.id;
        convertLeadData.doNotCreateOpportunity = false;
        ConvertLeadData.opportunityId = opp.Id;
        Test.startTest();
        ConvertLead.prepareLeadRecord(convertLeadData);
        ConvertLead.convertPart1(convertLeadData);
        Test.stopTest();
        ConvertLead.convertPart2(ConvertLeadData);
        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRS(
            ld,
            new List<String>{
                'SQL_Entered_From__c',
                'Lead__c',
                'Contact__c',
                'Opportunity__c',
                'Account__c',
                'DET_Current_Sub_Status__c',
                'SAL_isContact__c',
                'isConverted__c',
                'isPrimary__c',
                'isContactMerge__c'
            }
        );

        System.assertEquals(ld.Id, dfrList[0].Lead__c, 'Lead__c incorrect value');
        System.assertEquals(opp.Id, dfrList[0].Opportunity__c, 'Opportunity__c incorrect value');
        System.assertEquals(acc.Id, dfrList[0].Account__c, 'Account__c incorrect value');
        System.assertEquals(
            Test_DemandFunnelHelper.SQLFUNNELSTATUS,
            dfrList[0].DET_Current_Funnel_Status__c,
            'DET_Current_Funnel_Status__c incorrect value'
        );
        System.assertEquals(false, dfrList[0].SAL_isContact__c, 'SAL_isContact__c incorrect value');
        System.assertEquals(true, dfrList[0].isConverted__c, 'isConverted__c incorrect value');
        System.assertEquals(false, dfrList[0].isPrimary__c, 'isPrimary__c incorrect value');
        System.assertEquals(true, dfrList[0].isContactMerge__c, 'isContactMerge__c incorrect value');
        System.assertEquals(
            'Existing Opportunity',
            dfrList[0].SQL_Entered_From__c,
            'SQL_Entered_From__c incorrect value'
        );
    }

    //Test Case CRM-21095
    @isTest
    static void testLeadConversionDoNotCreateOpportunity() {
        User aeUser = (User) new UserSelector().selectUserByLastName(new List<String>{ Test_DemandFunnelHelper.AELASTNAME }).executeQuery()[0];
        Pricebook2 pb = Test_DemandFunnelHelper.getPriceBooks();
        Account acc = (Account) new AccountSelector().selectAccounts().executeQuery()[0];
        Contact con = (Contact) new ContactSelector().selectContacts().executeQuery()[0];

        Lead ld = (Lead) new SObjectBuilder(Lead.SObjectType)
            .setField(Lead.LastName, Test_DemandFunnelHelper.LEADLASTNAME)
            .setField(Lead.Status, LeadTriggerHelper.LEADSTATUSOPEN)
            .setField(Lead.Email, testEmail)
            .setField(Lead.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Lead.LeadSource, Test_DemandFunnelHelper.LEADSOURCE)
            .setField(
                Lead.RecordTypeId,
                Lead.SObjectType.getDescribe().getRecordTypeInfosByName().get('Sales Leads').getRecordTypeId()
            )
            .setField(Lead.OwnerId, aeUser.Id)
            .build()
            .create()
            .getRecord();

        ConvertLead.ConvertLeadDTO convertLeadData = new ConvertLead.ConvertLeadDTO();
        convertLeadData.leadId = ld.Id;
        convertLeadData.isCreateContact = false;
        convertLeadData.isBilling = false;
        convertLeadData.isCreateAccount = false;
        convertLeadData.isCreateOpportunity = false;
        convertLeadData.isCreateQuote = false;
        convertLeadData.upsellStatus = QuoteHelper.STATUS_NEW_CUSTOMER;
        convertLeadData.pricebook2Id = pb.Id;
        convertLeadData.accountId = acc.Id;
        convertLeadData.contactId = con.id;
        convertLeadData.doNotCreateOpportunity = true;
        Test.startTest();
        ConvertLead.prepareLeadRecord(convertLeadData);
        ConvertLead.convertPart1(convertLeadData);
        ConvertLead.convertPart2(ConvertLeadData);
        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRS(
            ld,
            new List<String>{
                'EOL_Entered_From__c',
                'SQL_Entered_From__c',
                'Lead__c',
                'Contact__c',
                'Opportunity__c',
                'Account__c',
                'DET_Current_Sub_Status__c',
                'SAL_isContact__c',
                'isConverted__c',
                'isPrimary__c',
                'isContactMerge__c'
            }
        );
        Test.stopTest();

        System.assertEquals(ld.Id, dfrList[0].Lead__c, 'Lead__c incorrect value');
        System.assertEquals(null, dfrList[0].Opportunity__c, 'Opportunity__c incorrect value');
        System.assertEquals(acc.Id, dfrList[0].Account__c, 'Account__c incorrect value');
        System.assertEquals(
            '3a - Contact',
            dfrList[0].DET_Current_Funnel_Status__c,
            'DET_Current_Funnel_Status__c incorrect value'
        );
        System.assertEquals(true, dfrList[0].SAL_isContact__c, 'SAL_isContact__c incorrect value');
        System.assertEquals(true, dfrList[0].isConverted__c, 'isConverted__c incorrect value');
        System.assertEquals(false, dfrList[0].isPrimary__c, 'isPrimary__c incorrect value');
        System.assertEquals(true, dfrList[0].isContactMerge__c, 'isContactMerge__c incorrect value');
        System.assertEquals(null, dfrList[0].SQL_Entered_From__c, 'SQL_Entered_From__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.SAL, dfrList[0].EOL_Entered_From__c, 'EOL_Entered_From__c incorrect value');
    }

    //Test Case CRM-21097
    @isTest
    static void testLeadConversionCreateContact() {
        User aeUser = (User) new UserSelector().selectUserByLastName(new List<String>{ Test_DemandFunnelHelper.AELASTNAME }).executeQuery()[0];
        Pricebook2 pb = Test_DemandFunnelHelper.getPriceBooks();
        Account acc = (Account) new AccountSelector().selectAccounts().executeQuery()[0];
        Contact con = (Contact) new ContactSelector().selectContacts().executeQuery()[0];
        delete con;

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
            .create()
            .getRecord();

        Lead ld = (Lead) new SObjectBuilder(Lead.SObjectType)
            .setField(Lead.LastName, Test_DemandFunnelHelper.LEADLASTNAME)
            .setField(Lead.Status, LeadTriggerHelper.LEADSTATUSOPEN)
            .setField(Lead.Email, testEmail)
            .setField(Lead.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Lead.LeadSource, Test_DemandFunnelHelper.LEADSOURCE)
            .setField(Lead.Company, 'testcorp')
            .setField(Lead.Company_DUNS__c, 'testcorp2')
            .setField(
                Lead.RecordTypeId,
                Lead.SObjectType.getDescribe().getRecordTypeInfosByName().get('Sales Leads').getRecordTypeId()
            )
            .setField(Lead.OwnerId, aeUser.Id)
            .create()
            .getRecord();

        ConvertLead.ConvertLeadDTO convertLeadData = new ConvertLead.ConvertLeadDTO();
        convertLeadData.leadId = ld.Id;
        convertLeadData.doNotCreateOpportunity = false;
        convertLeadData.isBilling = false;
        convertLeadData.isCreateAccount = false;
        convertLeadData.isCreateOpportunity = false;
        convertLeadData.isCreateQuote = false;
        convertLeadData.pricebook2Id = pb.Id;
        convertLeadData.accountId = acc.Id;
        convertLeadData.isCreateContact = true;
        convertLeadData.opportunityId = opp.Id;
        convertleadData.contactRole = 'Influencer';

        ConvertLead.prepareLeadRecord(convertLeadData);
        Test.startTest();
        Response result = ConvertLead.convertPart1(convertLeadData);
        convertLeadData.contactId = (Id) result.data.get(ConvertLead.CONTACTID_RESPONSE_IDENTIFIER);
        ConvertLead.convertPart2(ConvertLeadData);
        Test.stopTest();
        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRS(
            ld,
            new List<String>{
                'EOL_Entered_From__c',
                'SQL_Entered_From__c',
                'Lead__c',
                'Contact__c',
                'Opportunity__c',
                'Account__c',
                'DET_Current_Sub_Status__c',
                'SAL_isContact__c',
                'isConverted__c',
                'isPrimary__c',
                'isContactMerge__c'
            }
        );

        System.assertEquals(opp.Id, dfrList[0].Opportunity__c, 'Opportunity__c incorrect value');
        System.assertEquals(acc.Id, dfrList[0].Account__c, 'Account__c incorrect value');
        System.assertEquals(
            result.data.get(ConvertLead.CONTACTID_RESPONSE_IDENTIFIER),
            dfrList[0].Contact__c,
            'Contact__c incorrect value'
        );
        System.assertEquals(ld.Id, dfrList[0].Lead__c, 'Lead__c incorrect value');
        System.assertEquals(
            Test_DemandFunnelHelper.SQLFUNNELSTATUS,
            dfrList[0].DET_Current_Funnel_Status__c,
            'DET_Current_Funnel_Status__c incorrect value'
        );
        System.assertEquals(false, dfrList[0].SAL_isContact__c, 'SAL_isContact__c incorrect value');
        System.assertEquals(true, dfrList[0].isConverted__c, 'isConverted__c incorrect value');
        System.assertEquals(false, dfrList[0].isPrimary__c, 'isPrimary__c incorrect value');
        System.assertEquals(false, dfrList[0].isContactMerge__c, 'isContactMerge__c incorrect value');
        System.assertEquals(
            'Existing Opportunity',
            dfrList[0].SQL_Entered_From__c,
            'SQL_Entered_From__c incorrect value'
        );
    }

    // @isTest
    // static void testLeadConversionBDRtoAE() {
    //     User aeUser = (User) new UserSelector().selectUserByLastName(new List<String>{ Test_DemandFunnelHelper.AELASTNAME }).executeQuery()[0];
    //     User bdrUser = (User) new UserSelector()
    //         .selectUserByLastName(new List<String>{ Test_DemandFunnelHelper.BDRLASTNAME })
    //         .executeQuery()[0];
    //     Pricebook2 pb = Test_DemandFunnelHelper.getPriceBooks();

    //     Account acc = (Account) new AccountSelector().selectAccounts().executeQuery()[0];
    //     Contact con = (Contact) new ContactSelector().selectContacts().executeQuery()[0];
    //     Opportunity opp = (Opportunity) new OpportunitySelector().selectOpportunityByName('Test Opportunity ae').executeQuery()[0];
    //     Lead ld = (Lead) new LeadSelector().selectLeadByLastName(new List<Object>{Test_DemandFunnelHelper.LEADLASTNAME + 'bdr new'}).executeQuery()[0];



    //     ConvertLead.ConvertLeadDTO convertLeadData = new ConvertLead.ConvertLeadDTO();
    //     convertLeadData.leadId = ld.Id;
    //     convertLeadData.isCreateContact = false;
    //     convertLeadData.isBilling = false;
    //     convertLeadData.isCreateAccount = false;
    //     convertLeadData.isCreateOpportunity = false;
    //     convertLeadData.isCreateQuote = false;
    //     convertLeadData.upsellStatus = QuoteHelper.STATUS_NEW_CUSTOMER;
    //     convertLeadData.pricebook2Id = pb.Id;
    //     convertLeadData.accountId = acc.Id;
    //     convertLeadData.contactId = con.id;
    //     convertLeadData.doNotCreateOpportunity = false;
    //     ConvertLeadData.opportunityId = opp.Id;
    //     Test.startTest();
    //     ConvertLead.prepareLeadRecord(convertLeadData);
    //     ConvertLead.convertPart1(convertLeadData);
    //     Test.stopTest();
    //     ConvertLead.convertPart2(ConvertLeadData);
    //     List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRS(
    //         ld,
    //         new List<String>{
    //             'SQL_Entered_From__c',
    //             'TAL_Entered_From__c',
    //             'TAL_Exited_To__c',
    //             'TAL_Owner_Name__c',
    //             'TQL_Entered_From__c',
    //             'TQL_Exited_To__c',
    //             'TQL_Owner_Name__c',
    //             'SAL_Entered_From__c',
    //             'SAL_Exited_To__c',
    //             'SAL_Owner_Name__c'
    //         }
    //     );

    //     System.assertEquals(Test_DemandFunnelHelper.MQL, dfrList[0].TAL_Entered_From__c, 'TAL_Entered_From__c incorrect value');
    //     System.assertEquals(Test_DemandFunnelHelper.TQL, dfrList[0].TAL_Exited_To__c, 'TAL_Exited_To__c incorrect value');
    //     System.assertEquals(Test_DemandFunnelHelper.BDRLASTNAME, dfrList[0].TAL_Owner_Name__c, 'TAL_Owner_Name__c incorrect value');
    //     System.assertEquals(Test_DemandFunnelHelper.TAL, dfrList[0].TQL_Entered_From__c, 'TQL_Entered_From__c incorrect value');
    //     System.assertEquals(Test_DemandFunnelHelper.SAL, dfrList[0].TQL_Exited_To__c, 'TQL_Exited_To__c incorrect value');
    //     System.assertEquals(Test_DemandFunnelHelper.BDRLASTNAME, dfrList[0].TQL_Owner_Name__c, 'TQL_Owner_Name__c incorrect value');
    //     System.assertEquals(Test_DemandFunnelHelper.TQL, dfrList[0].SAL_Entered_From__c, 'SAL_Entered_From__c incorrect value');
    //     System.assertEquals(Test_DemandFunnelHelper.SQL, dfrList[0].SAL_Exited_To__c, 'SAL_Exited_To__c incorrect value');
    //     System.assertEquals(Test_DemandFunnelHelper.AELASTNAME, dfrList[0].SAL_Owner_Name__c, 'SAL_Owner_Name__c incorrect value');
    //     System.assertEquals(
    //         'Existing Opportunity',
    //         dfrList[0].SQL_Entered_From__c,
    //         'SQL_Entered_From__c incorrect value'
    //     );
    // }

    // @isTest
    // static void testLeadConversionBDRtoBDR() {
    //     User bdrUser = (User) new UserSelector()
    //         .selectUserByLastName(new List<String>{ Test_DemandFunnelHelper.BDRLASTNAME })
    //         .executeQuery()[0];
    //     Pricebook2 pb = Test_DemandFunnelHelper.getPriceBooks();
    //     Account acc = (Account) new AccountSelector().selectAccounts().executeQuery()[0];
    //     Contact con = (Contact) new ContactSelector().selectContacts().executeQuery()[0];
    //     Opportunity opp = (Opportunity) new OpportunitySelector().selectOpportunityByName('Test Opportunity bdr').executeQuery()[0];
    //     Lead ld = (Lead) new LeadSelector().selectLeadByLastName(new List<Object>{Test_DemandFunnelHelper.LEADLASTNAME + 'bdr new'}).executeQuery()[0];


    //     ConvertLead.ConvertLeadDTO convertLeadData = new ConvertLead.ConvertLeadDTO();
    //     convertLeadData.leadId = ld.Id;
    //     convertLeadData.isCreateContact = false;
    //     convertLeadData.isBilling = false;
    //     convertLeadData.isCreateAccount = false;
    //     convertLeadData.isCreateOpportunity = false;
    //     convertLeadData.isCreateQuote = false;
    //     convertLeadData.upsellStatus = QuoteHelper.STATUS_NEW_CUSTOMER;
    //     convertLeadData.pricebook2Id = pb.Id;
    //     convertLeadData.accountId = acc.Id;
    //     convertLeadData.contactId = con.id;
    //     convertLeadData.doNotCreateOpportunity = false;
    //     ConvertLeadData.opportunityId = opp.Id;
    //     Test.startTest();
    //     ConvertLead.prepareLeadRecord(convertLeadData);
    //     ConvertLead.convertPart1(convertLeadData);
    //     Test.stopTest();
    //     ConvertLead.convertPart2(ConvertLeadData);
    //     List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRS(
    //         ld,
    //         new List<String>{
    //             'SQL_Entered_From__c',
    //             'TAL_Entered_From__c',
    //             'TAL_Exited_To__c',
    //             'TAL_Owner_Name__c',
    //             'TQL_Entered_From__c',
    //             'TQL_Exited_To__c',
    //             'TQL_Owner_Name__c',
    //             'SAL_Entered_From__c',
    //             'SAL_Exited_To__c',
    //             'SAL_Owner_Name__c'
    //         }
    //     );

    //     System.assertEquals(Test_DemandFunnelHelper.MQL, dfrList[0].TAL_Entered_From__c, 'TAL_Entered_From__c incorrect value');
    //     System.assertEquals(Test_DemandFunnelHelper.TQL, dfrList[0].TAL_Exited_To__c, 'TAL_Exited_To__c incorrect value');
    //     System.assertEquals(Test_DemandFunnelHelper.BDRLASTNAME, dfrList[0].TAL_Owner_Name__c, 'TAL_Owner_Name__c incorrect value');
    //     System.assertEquals(Test_DemandFunnelHelper.TAL, dfrList[0].TQL_Entered_From__c, 'TQL_Entered_From__c incorrect value');
    //     System.assertEquals(Test_DemandFunnelHelper.SAL, dfrList[0].TQL_Exited_To__c, 'TQL_Exited_To__c incorrect value');
    //     System.assertEquals(Test_DemandFunnelHelper.BDRLASTNAME, dfrList[0].TQL_Owner_Name__c, 'TQL_Owner_Name__c incorrect value');
    //     System.assertEquals(Test_DemandFunnelHelper.TQL, dfrList[0].SAL_Entered_From__c, 'SAL_Entered_From__c incorrect value');
    //     System.assertEquals(Test_DemandFunnelHelper.SQL, dfrList[0].SAL_Exited_To__c, 'SAL_Exited_To__c incorrect value');
    //     System.assertEquals(Test_DemandFunnelHelper.BDRLASTNAME, dfrList[0].SAL_Owner_Name__c, 'SAL_Owner_Name__c incorrect value');
    //     System.assertEquals(
    //         'Existing Opportunity',
    //         dfrList[0].SQL_Entered_From__c,
    //         'SQL_Entered_From__c incorrect value'
    //     );
    // }

    @isTest
    static void testLeadConversionAEtoBDR() {
        User aeUser = (User) new UserSelector().selectUserByLastName(new List<String>{ Test_DemandFunnelHelper.AELASTNAME }).executeQuery()[0];
        User bdrUser = (User) new UserSelector()
            .selectUserByLastName(new List<String>{ Test_DemandFunnelHelper.BDRLASTNAME })
            .executeQuery()[0];
        Pricebook2 pb = Test_DemandFunnelHelper.getPriceBooks();
        Account acc = (Account) new AccountSelector().selectAccounts().executeQuery()[0];
        Contact con = (Contact) new ContactSelector().selectContacts().executeQuery()[0];

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
            .create()
            .getRecord();

        Lead ld = (Lead) new SObjectBuilder(Lead.SObjectType)
            .setField(Lead.LastName, Test_DemandFunnelHelper.LEADLASTNAME)
            .setField(Lead.Status, LeadTriggerHelper.LEADSTATUSNEW)
            .setField(Lead.Email, testEmail)
            .setField(Lead.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Lead.LeadSource, Test_DemandFunnelHelper.LEADSOURCE)
            .setField(
                Lead.RecordTypeId,
                Lead.SObjectType.getDescribe().getRecordTypeInfosByName().get('Sales Leads').getRecordTypeId()
            )
            .setField(Lead.OwnerId, aeUser.Id)
            .build()
            .create()
            .getRecord();

        ConvertLead.ConvertLeadDTO convertLeadData = new ConvertLead.ConvertLeadDTO();
        convertLeadData.leadId = ld.Id;
        convertLeadData.isCreateContact = false;
        convertLeadData.isBilling = false;
        convertLeadData.isCreateAccount = false;
        convertLeadData.isCreateOpportunity = false;
        convertLeadData.isCreateQuote = false;
        convertLeadData.upsellStatus = QuoteHelper.STATUS_NEW_CUSTOMER;
        convertLeadData.pricebook2Id = pb.Id;
        convertLeadData.accountId = acc.Id;
        convertLeadData.contactId = con.id;
        convertLeadData.doNotCreateOpportunity = false;
        ConvertLeadData.opportunityId = opp.Id;

        ConvertLead.prepareLeadRecord(convertLeadData);

        Test.startTest();
        ConvertLead.convertPart1(convertLeadData);
        ConvertLead.convertPart2(ConvertLeadData);
        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRS(
            ld,
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
        Test.stopTest();

        System.assertEquals(null, dfrList[0].TAL_Entered_From__c, 'TAL_Entered_From__c incorrect value');
        System.assertEquals(null, dfrList[0].TAL_Exited_To__c, 'TAL_Exited_To__c incorrect value');
        System.assertEquals(null, dfrList[0].TAL_Owner_Name__c, 'TAL_Owner_Name__c incorrect value');
        System.assertEquals(null, dfrList[0].TQL_Entered_From__c, 'TQL_Entered_From__c incorrect value');
        System.assertEquals(null, dfrList[0].TQL_Exited_To__c, 'TQL_Exited_To__c incorrect value');
        System.assertEquals(null, dfrList[0].TQL_Owner_Name__c, 'TQL_Owner_Name__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.MQL, dfrList[0].SAL_Entered_From__c, 'SAL_Entered_From__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.SQL, dfrList[0].SAL_Exited_To__c, 'SAL_Exited_To__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.BDRLASTNAME, dfrList[0].SAL_Owner_Name__c, 'SAL_Owner_Name__c incorrect value');
        System.assertEquals(
            'Existing Opportunity',
            dfrList[0].SQL_Entered_From__c,
            'SQL_Entered_From__c incorrect value'
        );
    }

    @isTest
    static void testLeadConversionBDRtoAENewDFR() {
        User aeUser = (User) new UserSelector().selectUserByLastName(new List<String>{ Test_DemandFunnelHelper.AELASTNAME }).executeQuery()[0];
        User bdrUser = (User) new UserSelector()
            .selectUserByLastName(new List<String>{ Test_DemandFunnelHelper.BDRLASTNAME })
            .executeQuery()[0];
        Pricebook2 pb = Test_DemandFunnelHelper.getPriceBooks();
        Account acc = (Account) new AccountSelector().selectAccounts().executeQuery()[0];
        Contact con = (Contact) new ContactSelector().selectContacts().executeQuery()[0];
        Opportunity opp = (Opportunity) new OpportunitySelector().selectOpportunityByName('Test Opportunity ae').executeQuery()[0];
        Lead ld = (Lead) new LeadSelector().selectLeadByLastName(new List<Object>{Test_DemandFunnelHelper.LEADLASTNAME + 'bdr'}).executeQuery()[0];

        ConvertLead.ConvertLeadDTO convertLeadData = new ConvertLead.ConvertLeadDTO();
        convertLeadData.leadId = ld.Id;
        convertLeadData.isCreateContact = false;
        convertLeadData.isBilling = false;
        convertLeadData.isCreateAccount = false;
        convertLeadData.isCreateOpportunity = false;
        convertLeadData.isCreateQuote = false;
        convertLeadData.upsellStatus = QuoteHelper.STATUS_NEW_CUSTOMER;
        convertLeadData.pricebook2Id = pb.Id;
        convertLeadData.accountId = acc.Id;
        convertLeadData.contactId = con.id;
        convertLeadData.doNotCreateOpportunity = false;
        ConvertLeadData.opportunityId = opp.Id;
        
        ConvertLead.prepareLeadRecord(convertLeadData);
        
        Test.startTest();
        ConvertLead.convertPart1(convertLeadData);
        Test.stopTest();
        ConvertLead.convertPart2(ConvertLeadData);
        
        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRS(
            ld,
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
        System.assertEquals(
            'Existing Opportunity',
            dfrList[0].SQL_Entered_From__c,
            'SQL_Entered_From__c incorrect value'
        );
    }

    @isTest
    static void testLeadConversionBDRtoBDRNewDFR() {
        User bdrUser = (User) new UserSelector()
            .selectUserByLastName(new List<String>{ Test_DemandFunnelHelper.BDRLASTNAME })
            .executeQuery()[0];
        Pricebook2 pb = Test_DemandFunnelHelper.getPriceBooks();
        Account acc = (Account) new AccountSelector().selectAccounts().executeQuery()[0];
        Contact con = (Contact) new ContactSelector().selectContacts().executeQuery()[0];
        Opportunity opp = (Opportunity) new OpportunitySelector().selectOpportunityByName('Test Opportunity bdr').executeQuery()[0];
        Lead ld = (Lead) new LeadSelector().selectLeadByLastName(new List<Object>{Test_DemandFunnelHelper.LEADLASTNAME + 'bdr'}).executeQuery()[0];

        ConvertLead.ConvertLeadDTO convertLeadData = new ConvertLead.ConvertLeadDTO();
        convertLeadData.leadId = ld.Id;
        convertLeadData.isCreateContact = false;
        convertLeadData.isBilling = false;
        convertLeadData.isCreateAccount = false;
        convertLeadData.isCreateOpportunity = false;
        convertLeadData.isCreateQuote = false;
        convertLeadData.upsellStatus = QuoteHelper.STATUS_NEW_CUSTOMER;
        convertLeadData.pricebook2Id = pb.Id;
        convertLeadData.accountId = acc.Id;
        convertLeadData.contactId = con.id;
        convertLeadData.doNotCreateOpportunity = false;
        ConvertLeadData.opportunityId = opp.Id;
        
        ConvertLead.prepareLeadRecord(convertLeadData);
        
        Test.startTest();
        ConvertLead.convertPart1(convertLeadData);
        Test.stopTest();
        ConvertLead.convertPart2(ConvertLeadData);

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRS(
            ld,
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
        System.assertEquals(
            'Existing Opportunity',
            dfrList[0].SQL_Entered_From__c,
            'SQL_Entered_From__c incorrect value'
        );
    }

    @isTest
    static void testLeadConversionAEtoBDRNewDFR() {
        User aeUser = (User) new UserSelector().selectUserByLastName(new List<String>{ Test_DemandFunnelHelper.AELASTNAME }).executeQuery()[0];
        User bdrUser = (User) new UserSelector()
            .selectUserByLastName(new List<String>{ Test_DemandFunnelHelper.BDRLASTNAME })
            .executeQuery()[0];
        Pricebook2 pb = Test_DemandFunnelHelper.getPriceBooks();
        Account acc = (Account) new AccountSelector().selectAccounts().executeQuery()[0];
        Contact con = (Contact) new ContactSelector().selectContacts().executeQuery()[0];

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
            .create()
            .getRecord();

        Lead ld = (Lead) new SObjectBuilder(Lead.SObjectType)
            .setField(Lead.LastName, Test_DemandFunnelHelper.LEADLASTNAME)
            .setField(Lead.Email, testEmail)
            .setField(Lead.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Lead.Status, LeadTriggerHelper.LEADSTATUSSUSPECT)
            .setField(Lead.LeadSource, Test_DemandFunnelHelper.LEADSOURCE)
            .setField(
                Lead.RecordTypeId,
                Lead.SObjectType.getDescribe().getRecordTypeInfosByName().get('Sales Leads').getRecordTypeId()
            )
            .setField(Lead.OwnerId, aeUser.Id)
            .build()
            .create()
            .getRecord();

        ConvertLead.ConvertLeadDTO convertLeadData = new ConvertLead.ConvertLeadDTO();
        convertLeadData.leadId = ld.Id;
        convertLeadData.isCreateContact = false;
        convertLeadData.isBilling = false;
        convertLeadData.isCreateAccount = false;
        convertLeadData.isCreateOpportunity = false;
        convertLeadData.isCreateQuote = false;
        convertLeadData.upsellStatus = QuoteHelper.STATUS_NEW_CUSTOMER;
        convertLeadData.pricebook2Id = pb.Id;
        convertLeadData.accountId = acc.Id;
        convertLeadData.contactId = con.id;
        convertLeadData.doNotCreateOpportunity = false;
        ConvertLeadData.opportunityId = opp.Id;

        ConvertLead.prepareLeadRecord(convertLeadData);

        Test.startTest();
        ConvertLead.convertPart1(convertLeadData);
        ConvertLead.convertPart2(ConvertLeadData);
        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRS(
            ld,
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
        Test.stopTest();

        System.assertEquals(null, dfrList[0].TAL_Entered_From__c, 'TAL_Entered_From__c incorrect value');
        System.assertEquals(null, dfrList[0].TAL_Exited_To__c, 'TAL_Exited_To__c incorrect value');
        System.assertEquals(null, dfrList[0].TAL_Owner_Name__c, 'TAL_Owner_Name__c incorrect value');
        System.assertEquals(null, dfrList[0].TQL_Entered_From__c, 'TQL_Entered_From__c incorrect value');
        System.assertEquals(null, dfrList[0].TQL_Exited_To__c, 'TQL_Exited_To__c incorrect value');
        System.assertEquals(null, dfrList[0].TQL_Owner_Name__c, 'TQL_Owner_Name__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.BACKFILLED, dfrList[0].SAL_Entered_From__c, 'SAL_Entered_From__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.BACKFILLED, dfrList[0].SAL_Exited_To__c, 'SAL_Exited_To__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.BDRLASTNAME, dfrList[0].SAL_Owner_Name__c, 'SAL_Owner_Name__c incorrect value');
        System.assertEquals(
            'Existing Opportunity',
            dfrList[0].SQL_Entered_From__c,
            'SQL_Entered_From__c incorrect value'
        );
    }

    /* ADDING COMMENT DUE TO 101 SOQL ISSUE
    //Test Case CRM-21098
    @isTest
    static void testLeadConversionWithNewAccount() {
        User aeUser = (User) new UserSelector().selectUserByLastName(new List<String>{ Test_DemandFunnelHelper.AELASTNAME }).executeQuery()[0];
        Pricebook2 pb = Test_DemandFunnelHelper.getPriceBooks();

        Lead ld = (Lead) new SObjectBuilder(Lead.SObjectType)
            .setField(Lead.LastName, Test_DemandFunnelHelper.LEADLASTNAME)
            .setField(Lead.Status, LeadTriggerHelper.LEADSTATUSOPEN)
            .setField(Lead.Email, testEmail)
            .setField(Lead.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Lead.LeadSource, Test_DemandFunnelHelper.LEADSOURCE)
            .setField(
                Lead.RecordTypeId,
                Lead.SObjectType.getDescribe().getRecordTypeInfosByName().get('Sales Leads').getRecordTypeId()
            )
            .setField(Lead.OwnerId, aeUser.Id)
            .setField(Lead.NumberOfEmployees, 15)
            .setField(Lead.Rating, 'Hot')
            .setField(Lead.LID__LinkedIn_Company_Id__c, '123123213')
            .setField(Lead.AnnualRevenue, 12)
            .setField(Lead.Website, 'www.test.com')
            .setField(Lead.LS_Enrichment_Date__c, Date.today())
            .setField(Lead.Company, 'testcorp')
            .setField(Lead.Company_DUNS__c, 'testcorp2')
            .build()
            .create()
            .getRecord();

        ConvertLead.ConvertLeadDTO convertLeadData = new ConvertLead.ConvertLeadDTO();
        convertLeadData.leadId = ld.Id;
        convertLeadData.isBilling = false;
        convertLeadData.isCreateAccount = true;
        convertLeadData.isCreateOpportunity = true;
        convertLeadData.opportunityName = 'Test Oppty';
        convertLeadData.doNotCreateOpportunity = false;
        convertLeadData.isCreateQuote = false;
        convertLeadData.upsellStatus = QuoteHelper.STATUS_NEW_CUSTOMER;
        convertLeadData.pricebook2Id = pb.Id;
        convertLeadData.isCreateContact = true;
        convertLeadData.accountId = null;
        convertLeadData.contactId = null;
        convertLeadData.contactRole = 'Influencer';
        ConvertLeadData.brand = 'Ring Central';
        convertLeadData.forecastedUsers = 15;
        ConvertLead.prepareLeadRecord(convertLeadData);

        Response result = ConvertLead.convertPart1(convertLeadData);
        Test.startTest();
        convertLeadData.contactId = (Id) result.data.get(ConvertLead.CONTACTID_RESPONSE_IDENTIFIER);
        convertLeadData.accountId = (Id) result.data.get(ConvertLead.ACCOUNTID_RESPONSE_IDENTIFIER);
        convertLeadData.opportunityId = (Id) result.data.get(ConvertLead.OPPORTUNITYID_RESPONSE_IDENTIFIER);
        ConvertLead.convertPart2(convertLeadData);
        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRS(
            ld,
            new List<String>{
                'EOL_Entered_From__c',
                'SQL_Entered_From__c',
                'Lead__c',
                'Contact__c',
                'Opportunity__c',
                'Account__c',
                'DET_Current_Sub_Status__c',
                'SAL_isContact__c',
                'isConverted__c',
                'isPrimary__c',
                'isContactMerge__c'
            }
        );
        Test.stopTest();

        System.assertEquals(ld.Id, dfrList[0].Lead__c, 'Lead__c incorrect value');
        System.assertEquals(
            result.data.get(ConvertLead.OPPORTUNITYID_RESPONSE_IDENTIFIER),
            dfrList[0].Opportunity__c,
            'Opportunity__c incorrect value'
        );
        System.assertEquals(
            result.data.get(ConvertLead.ACCOUNTID_RESPONSE_IDENTIFIER),
            dfrList[0].Account__c,
            'Account__c incorrect value'
        );
        System.assertEquals(
            result.data.get(ConvertLead.CONTACTID_RESPONSE_IDENTIFIER),
            dfrList[0].Contact__c,
            'Contact__c incorrect value'
        );
        System.assertEquals(
            Test_DemandFunnelHelper.SQLFUNNELSTATUS,
            dfrList[0].DET_Current_Funnel_Status__c,
            'DET_Current_Funnel_Status__c incorrect value'
        );
    }
    */

    //Test CRM-20935
    @isTest
    static void testDFRCreationSuspectToOpen() {
        Lead ld = (Lead) new SObjectBuilder(Lead.SObjectType)
            .setField(Lead.LastName, Test_DemandFunnelHelper.LEADLASTNAME)
            .setField(Lead.Status, LeadTriggerHelper.LEADSTATUSSUSPECT)
            .setField(Lead.Email, testEmail)
            .setField(Lead.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Lead.LeadSource, Test_DemandFunnelHelper.LEADSOURCE)
            .create()
            .getRecord();

        Test.startTest();
        ld.Status = LeadTriggerHelper.LEADSTATUSOPEN;
        update ld;
        Test.stopTest();

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRS(
            ld,
            new List<String>{
                'Lead_Name_on_Creation__c',
                'Lead_Email_on_Creation__c',
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
                'EOL_Entered_From__c'
            }
        );
        System.assertEquals(
            Test_DemandFunnelHelper.LEADLASTNAME,
            dfrList[0].Lead_Name_on_Creation__c,
            'Lead_Name_on_Creation__c incorrect value'
        );
        System.assertEquals(
            testEmail,
            dfrList[0].Lead_Email_on_Creation__c,
            'Lead_Email_on_Creation__c incorrect value'
        );
        System.assertEquals(Test_DemandFunnelHelper.CREATED, dfrList[0].Prospect_Entered_From__c, 'Prospect_Entered_From__c incorrect value');
        System.assertEquals(null, dfrList[0].Prospect_Exited_To__c, 'Prospect_Exited_To__c incorrect value');
        System.assertEquals(null, dfrList[0].MQL_Entered_From__c, 'MQL_Entered_From__c incorrect value');
        System.assertEquals(null, dfrList[0].MQL_Exited_To__c, 'MQL_Exited_To__c incorrect value');
        System.assertEquals(null, dfrList[0].TAL_Entered_From__c, 'TAL_Entered_From__c incorrect value');
        System.assertEquals(null, dfrList[0].TAL_Exited_To__c, 'TAL_Exited_To__c incorrect value');
        System.assertEquals(null, dfrList[0].SAL_Entered_From__c, 'SAL_Entered_From__c incorrect value');
        System.assertEquals(null, dfrList[0].SAL_Exited_To__c, 'SAL_Exited_To__c incorrect value');
        System.assertEquals(null, dfrList[0].EOL_Entered_From__c, 'EOL_Entered_From__c incorrect value');
        System.assertEquals('Active', dfrList[0].DFR_Active_Status__c, 'DFR_Active_Status__c incorrect value');
        System.assertEquals(
            Test_DemandFunnelHelper.PROSPECTFUNNELSTATUS,
            dfrList[0].DET_Current_Funnel_Status__c,
            'DET_Current_Funnel_Status__c incorrect value'
        );
    }

    //Test CRM-21507
    @isTest
    static void testDFRCreationSuspectToDowngraded() {
        Lead ld = (Lead) new SObjectBuilder(Lead.SObjectType)
            .setField(Lead.LastName, Test_DemandFunnelHelper.LEADLASTNAME)
            .setField(Lead.Status, LeadTriggerHelper.LEADSTATUSSUSPECT)
            .setField(Lead.Email, testEmail)
            .setField(Lead.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Lead.LeadSource, Test_DemandFunnelHelper.LEADSOURCE)
            .create()
            .getRecord();

        Test.startTest();
        ld.Status = LeadTriggerHelper.LEADSTATUSDOWNGRADED;
        ld.Downgrade_Reason__c = 'Lost to Competition';
        ld.Sub_Downgrade_Reason__c = 'Other';
        update ld;
        Test.stopTest();

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRS(
            ld,
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
                'EOL_Entered_From__c'
            }
        );
        System.assert(dfrList.isEmpty(), 'DFR is not created');
    }

    //Test CRM-21501
    @isTest
    static void testDFRCreationSuspectToReNew() {
        Lead ld = (Lead) new SObjectBuilder(Lead.SObjectType)
            .setField(Lead.LastName, Test_DemandFunnelHelper.LEADLASTNAME)
            .setField(Lead.Status, LeadTriggerHelper.LEADSTATUSSUSPECT)
            .setField(Lead.Email, testEmail)
            .setField(Lead.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Lead.LeadSource, Test_DemandFunnelHelper.LEADSOURCE)
            .create()
            .getRecord();

        Test.startTest();
        ld.Status = LeadTriggerHelper.LEADSTATUSRENEW;
        update ld;
        Test.stopTest();

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRS(
            ld,
            new List<String>{
                'Lead_Name_on_Creation__c',
                'Lead_Email_on_Creation__c',
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
                'EOL_Entered_From__c'
            }
        );
        System.assertEquals(
            Test_DemandFunnelHelper.LEADLASTNAME,
            dfrList[0].Lead_Name_on_Creation__c,
            'Lead_Name_on_Creation__c incorrect value'
        );
        System.assertEquals(
            testEmail,
            dfrList[0].Lead_Email_on_Creation__c,
            'Lead_Email_on_Creation__c incorrect value'
        );
        System.assertEquals(
            Test_DemandFunnelHelper.BACKFILLED,
            dfrList[0].Prospect_Entered_From__c,
            'Prospect_Entered_From__c incorrect value'
        );
        System.assertEquals(Test_DemandFunnelHelper.BACKFILLED, dfrList[0].Prospect_Exited_To__c, 'Prospect_Exited_To__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.CREATED, dfrList[0].MQL_Entered_From__c, 'MQL_Entered_From__c incorrect value');
        System.assertEquals(null, dfrList[0].MQL_Exited_To__c, 'MQL_Exited_To__c incorrect value');
        System.assertEquals(null, dfrList[0].TAL_Entered_From__c, 'TAL_Entered_From__c incorrect value');
        System.assertEquals(null, dfrList[0].TAL_Exited_To__c, 'TAL_Exited_To__c incorrect value');
        System.assertEquals(null, dfrList[0].SAL_Entered_From__c, 'SAL_Entered_From__c incorrect value');
        System.assertEquals(null, dfrList[0].SAL_Exited_To__c, 'SAL_Exited_To__c incorrect value');
        System.assertEquals(null, dfrList[0].EOL_Entered_From__c, 'EOL_Entered_From__c incorrect value');
        System.assertEquals('Active', dfrList[0].DFR_Active_Status__c, 'DFR_Active_Status__c incorrect value');
        System.assertEquals(
            Test_DemandFunnelHelper.MQLFUNNELSTATUS,
            dfrList[0].DET_Current_Funnel_Status__c,
            'DET_Current_Funnel_Status__c incorrect value'
        );
    }

    //Test CRM-21502
    @isTest
    static void testDFRCreationSuspectToNew() {
        Lead ld = (Lead) new SObjectBuilder(Lead.SObjectType)
            .setField(Lead.LastName, Test_DemandFunnelHelper.LEADLASTNAME)
            .setField(Lead.Status, LeadTriggerHelper.LEADSTATUSSUSPECT)
            .setField(Lead.Email, testEmail)
            .setField(Lead.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Lead.LeadSource, Test_DemandFunnelHelper.LEADSOURCE)
            .create()
            .getRecord();

        Test.startTest();
        ld.Status = LeadTriggerHelper.LEADSTATUSNEW;
        update ld;
        Test.stopTest();

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRS(
            ld,
            new List<String>{
                'Lead_Name_on_Creation__c',
                'Lead_Email_on_Creation__c',
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
                'EOL_Entered_From__c'
            }
        );
        System.assertEquals(
            Test_DemandFunnelHelper.LEADLASTNAME,
            dfrList[0].Lead_Name_on_Creation__c,
            'Lead_Name_on_Creation__c incorrect value'
        );
        System.assertEquals(
            testEmail,
            dfrList[0].Lead_Email_on_Creation__c,
            'Lead_Email_on_Creation__c incorrect value'
        );
        System.assertEquals(
            Test_DemandFunnelHelper.BACKFILLED,
            dfrList[0].Prospect_Entered_From__c,
            'Prospect_Entered_From__c incorrect value'
        );
        System.assertEquals(Test_DemandFunnelHelper.BACKFILLED, dfrList[0].Prospect_Exited_To__c, 'Prospect_Exited_To__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.CREATED, dfrList[0].MQL_Entered_From__c, 'MQL_Entered_From__c incorrect value');
        System.assertEquals(null, dfrList[0].MQL_Exited_To__c, 'MQL_Exited_To__c incorrect value');
        System.assertEquals(null, dfrList[0].TAL_Entered_From__c, 'TAL_Entered_From__c incorrect value');
        System.assertEquals(null, dfrList[0].TAL_Exited_To__c, 'TAL_Exited_To__c incorrect value');
        System.assertEquals(null, dfrList[0].SAL_Entered_From__c, 'SAL_Entered_From__c incorrect value');
        System.assertEquals(null, dfrList[0].SAL_Exited_To__c, 'SAL_Exited_To__c incorrect value');
        System.assertEquals(null, dfrList[0].EOL_Entered_From__c, 'EOL_Entered_From__c incorrect value');
        System.assertEquals('Active', dfrList[0].DFR_Active_Status__c, 'DFR_Active_Status__c incorrect value');
        System.assertEquals(
            Test_DemandFunnelHelper.MQLFUNNELSTATUS,
            dfrList[0].DET_Current_Funnel_Status__c,
            'DET_Current_Funnel_Status__c incorrect value'
        );
    }

    //Test CRM-21503
    @isTest
    static void testDFRCreationSuspectToCalloutNotNullUser() {
        User sysUser = Test_DemandFunnelHelper.getSystemUser();
        sysUser.Team__c = 'Not null Team';
        update sysUser;

        Lead ld = (Lead) new SObjectBuilder(Lead.SObjectType)
            .setField(Lead.LastName, Test_DemandFunnelHelper.LEADLASTNAME)
            .setField(Lead.Status, LeadTriggerHelper.LEADSTATUSSUSPECT)
            .setField(Lead.Email, testEmail)
            .setField(Lead.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Lead.LeadSource, Test_DemandFunnelHelper.LEADSOURCE)
            .createAsUser(sysUser)
            .getRecord();

        Test.startTest();
        ld.Status = LeadTriggerHelper.LEADSTATUSCALLOUT;
        update ld;
        Test.stopTest();

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRS(
            ld,
            new List<String>{
                'Lead_Name_on_Creation__c',
                'Lead_Email_on_Creation__c',
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
                'EOL_Entered_From__c'
            }
        );
        System.assertEquals(
            Test_DemandFunnelHelper.LEADLASTNAME,
            dfrList[0].Lead_Name_on_Creation__c,
            'Lead_Name_on_Creation__c incorrect value'
        );
        System.assertEquals(
            testEmail,
            dfrList[0].Lead_Email_on_Creation__c,
            'Lead_Email_on_Creation__c incorrect value'
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
        System.assertEquals(Test_DemandFunnelHelper.CREATED, dfrList[0].SAL_Entered_From__c, 'SAL_Entered_From__c incorrect value');
        System.assertEquals(null, dfrList[0].SAL_Exited_To__c, 'SAL_Exited_To__c incorrect value');
        System.assertEquals(null, dfrList[0].EOL_Entered_From__c, 'EOL_Entered_From__c incorrect value');
        System.assertEquals('Active', dfrList[0].DFR_Active_Status__c, 'DFR_Active_Status__c incorrect value');
        System.assertEquals(
            Test_DemandFunnelHelper.SALFUNNELSTATUS,
            dfrList[0].DET_Current_Funnel_Status__c,
            'DET_Current_Funnel_Status__c incorrect value'
        );
    }

    //Test CRM-21504
    @isTest
    static void testDFRCreationSuspectToContactedNotNullUser() {
        User sysUser = Test_DemandFunnelHelper.getSystemUser();
        sysUser.Team__c = 'Not null Team';
        update sysUser;

        Lead ld = (Lead) new SObjectBuilder(Lead.SObjectType)
            .setField(Lead.LastName, Test_DemandFunnelHelper.LEADLASTNAME)
            .setField(Lead.Status, LeadTriggerHelper.LEADSTATUSSUSPECT)
            .setField(Lead.Email, testEmail)
            .setField(Lead.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Lead.LeadSource, Test_DemandFunnelHelper.LEADSOURCE)
            .createAsUser(sysUser)
            .getRecord();

        Test.startTest();
        ld.Status = LeadTriggerHelper.LEADSTATUSCONTACTED;
        update ld;
        Test.stopTest();

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRS(
            ld,
            new List<String>{
                'Lead_Name_on_Creation__c',
                'Lead_Email_on_Creation__c',
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
                'EOL_Entered_From__c'
            }
        );
        System.assertEquals(
            Test_DemandFunnelHelper.LEADLASTNAME,
            dfrList[0].Lead_Name_on_Creation__c,
            'Lead_Name_on_Creation__c incorrect value'
        );
        System.assertEquals(
            testEmail,
            dfrList[0].Lead_Email_on_Creation__c,
            'Lead_Email_on_Creation__c incorrect value'
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
        System.assertEquals(Test_DemandFunnelHelper.CREATED, dfrList[0].SAL_Entered_From__c, 'SAL_Entered_From__c incorrect value');
        System.assertEquals(null, dfrList[0].SAL_Exited_To__c, 'SAL_Exited_To__c incorrect value');
        System.assertEquals(null, dfrList[0].EOL_Entered_From__c, 'EOL_Entered_From__c incorrect value');
        System.assertEquals('Active', dfrList[0].DFR_Active_Status__c, 'DFR_Active_Status__c incorrect value');
        System.assertEquals(
            Test_DemandFunnelHelper.SALFUNNELSTATUS,
            dfrList[0].DET_Current_Funnel_Status__c,
            'DET_Current_Funnel_Status__c incorrect value'
        );
    }

    //Test CRM-21505
    @isTest
    static void testDFRCreationSuspectToCalloutSDRUser() {
        User sysUser = Test_DemandFunnelHelper.getSystemUser();
        sysUser.Team__c = Test_DemandFunnelHelper.SDRTEAM;
        update sysUser;

        Lead ld = (Lead) new SObjectBuilder(Lead.SObjectType)
            .setField(Lead.LastName, Test_DemandFunnelHelper.LEADLASTNAME)
            .setField(Lead.Status, LeadTriggerHelper.LEADSTATUSSUSPECT)
            .setField(Lead.Email, testEmail)
            .setField(Lead.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Lead.LeadSource, Test_DemandFunnelHelper.LEADSOURCE)
            .createAsUser(sysUser)
            .getRecord();

        Test.startTest();
        ld.Status = LeadTriggerHelper.LEADSTATUSCALLOUT;
        update ld;
        Test.stopTest();

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRS(
            ld,
            new List<String>{
                'Lead_Name_on_Creation__c',
                'Lead_Email_on_Creation__c',
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
                'EOL_Entered_From__c'
            }
        );
        System.assertEquals(
            Test_DemandFunnelHelper.LEADLASTNAME,
            dfrList[0].Lead_Name_on_Creation__c,
            'Lead_Name_on_Creation__c incorrect value'
        );
        System.assertEquals(
            testEmail,
            dfrList[0].Lead_Email_on_Creation__c,
            'Lead_Email_on_Creation__c incorrect value'
        );
        System.assertEquals(
            Test_DemandFunnelHelper.BACKFILLED,
            dfrList[0].Prospect_Entered_From__c,
            'Prospect_Entered_From__c incorrect value'
        );
        System.assertEquals(Test_DemandFunnelHelper.BACKFILLED, dfrList[0].Prospect_Exited_To__c, 'Prospect_Exited_To__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.BACKFILLED, dfrList[0].MQL_Entered_From__c, 'MQL_Entered_From__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.BACKFILLED, dfrList[0].MQL_Exited_To__c, 'MQL_Exited_To__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.CREATED, dfrList[0].TAL_Entered_From__c, 'TAL_Entered_From__c incorrect value');
        System.assertEquals(null, dfrList[0].TAL_Exited_To__c, 'TAL_Exited_To__c incorrect value');
        System.assertEquals(null, dfrList[0].SAL_Entered_From__c, 'SAL_Entered_From__c incorrect value');
        System.assertEquals(null, dfrList[0].SAL_Exited_To__c, 'SAL_Exited_To__c incorrect value');
        System.assertEquals(null, dfrList[0].EOL_Entered_From__c, 'EOL_Entered_From__c incorrect value');
        System.assertEquals('Active', dfrList[0].DFR_Active_Status__c, 'DFR_Active_Status__c incorrect value');
        System.assertEquals(
            Test_DemandFunnelHelper.TALFUNNELSTATUS,
            dfrList[0].DET_Current_Funnel_Status__c,
            'DET_Current_Funnel_Status__c incorrect value'
        );
    }

    //Test CRM-21506
    @isTest
    static void testDFRCreationSuspectToContactedSDRUser() {
        User sysUser = Test_DemandFunnelHelper.getSystemUser();
        sysUser.Team__c = Test_DemandFunnelHelper.SDRTEAM;
        update sysUser;

        Lead ld = (Lead) new SObjectBuilder(Lead.SObjectType)
            .setField(Lead.LastName, Test_DemandFunnelHelper.LEADLASTNAME)
            .setField(Lead.Status, LeadTriggerHelper.LEADSTATUSSUSPECT)
            .setField(Lead.Email, testEmail)
            .setField(Lead.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Lead.LeadSource, Test_DemandFunnelHelper.LEADSOURCE)
            .createAsUser(sysUser)
            .getRecord();

        Test.startTest();
        ld.Status = LeadTriggerHelper.LEADSTATUSCONTACTED;
        update ld;
        Test.stopTest();

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRS(
            ld,
            new List<String>{
                'Lead_Name_on_Creation__c',
                'Lead_Email_on_Creation__c',
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
                'EOL_Entered_From__c'
            }
        );
        System.assertEquals(
            Test_DemandFunnelHelper.LEADLASTNAME,
            dfrList[0].Lead_Name_on_Creation__c,
            'Lead_Name_on_Creation__c incorrect value'
        );
        System.assertEquals(
            testEmail,
            dfrList[0].Lead_Email_on_Creation__c,
            'Lead_Email_on_Creation__c incorrect value'
        );
        System.assertEquals(
            Test_DemandFunnelHelper.BACKFILLED,
            dfrList[0].Prospect_Entered_From__c,
            'Prospect_Entered_From__c incorrect value'
        );
        System.assertEquals(Test_DemandFunnelHelper.BACKFILLED, dfrList[0].Prospect_Exited_To__c, 'Prospect_Exited_To__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.BACKFILLED, dfrList[0].MQL_Entered_From__c, 'MQL_Entered_From__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.BACKFILLED, dfrList[0].MQL_Exited_To__c, 'MQL_Exited_To__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.CREATED, dfrList[0].TAL_Entered_From__c, 'TAL_Entered_From__c incorrect value');
        System.assertEquals(null, dfrList[0].TAL_Exited_To__c, 'TAL_Exited_To__c incorrect value');
        System.assertEquals(null, dfrList[0].SAL_Entered_From__c, 'SAL_Entered_From__c incorrect value');
        System.assertEquals(null, dfrList[0].SAL_Exited_To__c, 'SAL_Exited_To__c incorrect value');
        System.assertEquals(null, dfrList[0].EOL_Entered_From__c, 'EOL_Entered_From__c incorrect value');
        System.assertEquals('Active', dfrList[0].DFR_Active_Status__c, 'DFR_Active_Status__c incorrect value');
        System.assertEquals(
            Test_DemandFunnelHelper.TALFUNNELSTATUS,
            dfrList[0].DET_Current_Funnel_Status__c,
            'DET_Current_Funnel_Status__c incorrect value'
        );
    }
    //Test CRM-20918
    @isTest
    static void testDFRCreationContactedSDRUser() {
        User sysUser = Test_DemandFunnelHelper.getSystemUser();
        sysUser.Team__c = Test_DemandFunnelHelper.SDRTEAM;
        update sysUser;

        Test.startTest();
        Lead ld = (Lead) new SObjectBuilder(Lead.SObjectType)
            .setField(Lead.LastName, Test_DemandFunnelHelper.LEADLASTNAME)
            .setField(Lead.Status, LeadTriggerHelper.LEADSTATUSCONTACTED)
            .setField(Lead.Email, testEmail)
            .setField(Lead.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Lead.LeadSource, Test_DemandFunnelHelper.LEADSOURCE)
            .setField(Lead.OwnerId, sysUser.Id)
            .createAsUser(sysUser)
            .getRecord();
        Test.stopTest();

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRS(
            ld,
            new List<String>{
                'Lead_Name_on_Creation__c',
                'Lead_Email_on_Creation__c',
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
                'EOL_Entered_From__c'
            }
        );
        System.assertEquals(
            Test_DemandFunnelHelper.LEADLASTNAME,
            dfrList[0].Lead_Name_on_Creation__c,
            'Lead_Name_on_Creation__c incorrect value'
        );
        System.assertEquals(
            testEmail,
            dfrList[0].Lead_Email_on_Creation__c,
            'Lead_Email_on_Creation__c incorrect value'
        );
        System.assertEquals(
            Test_DemandFunnelHelper.BACKFILLED,
            dfrList[0].Prospect_Entered_From__c,
            'Prospect_Entered_From__c incorrect value'
        );
        System.assertEquals(Test_DemandFunnelHelper.BACKFILLED, dfrList[0].Prospect_Exited_To__c, 'Prospect_Exited_To__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.BACKFILLED, dfrList[0].MQL_Entered_From__c, 'MQL_Entered_From__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.BACKFILLED, dfrList[0].MQL_Exited_To__c, 'MQL_Exited_To__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.CREATED, dfrList[0].TAL_Entered_From__c, 'TAL_Entered_From__c incorrect value');
        System.assertEquals(null, dfrList[0].TAL_Exited_To__c, 'TAL_Exited_To__c incorrect value');
        System.assertEquals(null, dfrList[0].SAL_Entered_From__c, 'SAL_Entered_From__c incorrect value');
        System.assertEquals(null, dfrList[0].SAL_Exited_To__c, 'SAL_Exited_To__c incorrect value');
        System.assertEquals(null, dfrList[0].EOL_Entered_From__c, 'EOL_Entered_From__c incorrect value');
        System.assertEquals('Active', dfrList[0].DFR_Active_Status__c, 'DFR_Active_Status__c incorrect value');
        System.assertEquals(
            Test_DemandFunnelHelper.TALFUNNELSTATUS,
            dfrList[0].DET_Current_Funnel_Status__c,
            'DET_Current_Funnel_Status__c incorrect value'
        );
    }

    //Test CRM-20916
    @isTest
    static void testDFRCreationCalloutSDRUser() {
        User sysUser = Test_DemandFunnelHelper.getSystemUser();
        sysUser.Team__c = Test_DemandFunnelHelper.SDRTEAM;
        update sysUser;

        Test.startTest();
        Lead ld = (Lead) new SObjectBuilder(Lead.SObjectType)
            .setField(Lead.LastName, Test_DemandFunnelHelper.LEADLASTNAME)
            .setField(Lead.Status, LeadTriggerHelper.LEADSTATUSCALLOUT)
            .setField(Lead.Email, testEmail)
            .setField(Lead.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Lead.LeadSource, Test_DemandFunnelHelper.LEADSOURCE)
            .setField(Lead.OwnerId, sysUser.Id)
            .createAsUser(sysUser)
            .getRecord();
        Test.stopTest();

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRS(
            ld,
            new List<String>{
                'Lead_Name_on_Creation__c',
                'Lead_Email_on_Creation__c',
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
                'EOL_Entered_From__c'
            }
        );
        System.assertEquals(
            Test_DemandFunnelHelper.LEADLASTNAME,
            dfrList[0].Lead_Name_on_Creation__c,
            'Lead_Name_on_Creation__c incorrect value'
        );
        System.assertEquals(
            testEmail,
            dfrList[0].Lead_Email_on_Creation__c,
            'Lead_Email_on_Creation__c incorrect value'
        );
        System.assertEquals(
            Test_DemandFunnelHelper.BACKFILLED,
            dfrList[0].Prospect_Entered_From__c,
            'Prospect_Entered_From__c incorrect value'
        );
        System.assertEquals(Test_DemandFunnelHelper.BACKFILLED, dfrList[0].Prospect_Exited_To__c, 'Prospect_Exited_To__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.BACKFILLED, dfrList[0].MQL_Entered_From__c, 'MQL_Entered_From__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.BACKFILLED, dfrList[0].MQL_Exited_To__c, 'MQL_Exited_To__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.CREATED, dfrList[0].TAL_Entered_From__c, 'TAL_Entered_From__c incorrect value');
        System.assertEquals(null, dfrList[0].TAL_Exited_To__c, 'TAL_Exited_To__c incorrect value');
        System.assertEquals(null, dfrList[0].SAL_Entered_From__c, 'SAL_Entered_From__c incorrect value');
        System.assertEquals(null, dfrList[0].SAL_Exited_To__c, 'SAL_Exited_To__c incorrect value');
        System.assertEquals(null, dfrList[0].EOL_Entered_From__c, 'EOL_Entered_From__c incorrect value');
        System.assertEquals('Active', dfrList[0].DFR_Active_Status__c, 'DFR_Active_Status__c incorrect value');
        System.assertEquals(
            Test_DemandFunnelHelper.TALFUNNELSTATUS,
            dfrList[0].DET_Current_Funnel_Status__c,
            'DET_Current_Funnel_Status__c incorrect value'
        );
    }

    //Test CRM-20919
    @isTest
    static void testDFRCreationContactedNotNullUser() {
        User sysUser = Test_DemandFunnelHelper.getSystemUser();
        sysUser.Team__c = 'Not null Team';
        update sysUser;

        Test.startTest();
        Lead ld = (Lead) new SObjectBuilder(Lead.SObjectType)
            .setField(Lead.LastName, Test_DemandFunnelHelper.LEADLASTNAME)
            .setField(Lead.Status, LeadTriggerHelper.LEADSTATUSCONTACTED)
            .setField(Lead.Email, testEmail)
            .setField(Lead.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Lead.LeadSource, Test_DemandFunnelHelper.LEADSOURCE)
            .setField(Lead.OwnerId, sysUser.Id)
            .createAsUser(sysUser)
            .getRecord();
        Test.stopTest();

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRS(
            ld,
            new List<String>{
                'Lead_Name_on_Creation__c',
                'Lead_Email_on_Creation__c',
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
                'EOL_Entered_From__c'
            }
        );
        System.assertEquals(
            Test_DemandFunnelHelper.LEADLASTNAME,
            dfrList[0].Lead_Name_on_Creation__c,
            'Lead_Name_on_Creation__c incorrect value'
        );
        System.assertEquals(
            testEmail,
            dfrList[0].Lead_Email_on_Creation__c,
            'Lead_Email_on_Creation__c incorrect value'
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
        System.assertEquals(Test_DemandFunnelHelper.CREATED, dfrList[0].SAL_Entered_From__c, 'SAL_Entered_From__c incorrect value');
        System.assertEquals(null, dfrList[0].SAL_Exited_To__c, 'SAL_Exited_To__c incorrect value');
        System.assertEquals(null, dfrList[0].EOL_Entered_From__c, 'EOL_Entered_From__c incorrect value');
        System.assertEquals('Active', dfrList[0].DFR_Active_Status__c, 'DFR_Active_Status__c incorrect value');
        System.assertEquals(
            Test_DemandFunnelHelper.SALFUNNELSTATUS,
            dfrList[0].DET_Current_Funnel_Status__c,
            'DET_Current_Funnel_Status__c incorrect value'
        );
    }

    //Test CRM-20917
    @isTest
    static void testDFRCreationCalloutNotNullUser() {
        User sysUser = Test_DemandFunnelHelper.getSystemUser();
        sysUser.Team__c = 'Not null Team';
        update sysUser;

        Test.startTest();
        Lead ld = (Lead) new SObjectBuilder(Lead.SObjectType)
            .setField(Lead.LastName, Test_DemandFunnelHelper.LEADLASTNAME)
            .setField(Lead.Status, LeadTriggerHelper.LEADSTATUSCALLOUT)
            .setField(Lead.Email, testEmail)
            .setField(Lead.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Lead.LeadSource, Test_DemandFunnelHelper.LEADSOURCE)
            .setField(Lead.OwnerId, sysUser.Id)
            .createAsUser(sysUser)
            .getRecord();
        Test.stopTest();

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRS(
            ld,
            new List<String>{
                'Lead_Name_on_Creation__c',
                'Lead_Email_on_Creation__c',
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
                'EOL_Entered_From__c'
            }
        );
        System.assertEquals(
            Test_DemandFunnelHelper.LEADLASTNAME,
            dfrList[0].Lead_Name_on_Creation__c,
            'Lead_Name_on_Creation__c incorrect value'
        );
        System.assertEquals(
            testEmail,
            dfrList[0].Lead_Email_on_Creation__c,
            'Lead_Email_on_Creation__c incorrect value'
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
        System.assertEquals(Test_DemandFunnelHelper.CREATED, dfrList[0].SAL_Entered_From__c, 'SAL_Entered_From__c incorrect value');
        System.assertEquals(null, dfrList[0].SAL_Exited_To__c, 'SAL_Exited_To__c incorrect value');
        System.assertEquals(null, dfrList[0].EOL_Entered_From__c, 'EOL_Entered_From__c incorrect value');
        System.assertEquals('Active', dfrList[0].DFR_Active_Status__c, 'DFR_Active_Status__c incorrect value');
        System.assertEquals(
            Test_DemandFunnelHelper.SALFUNNELSTATUS,
            dfrList[0].DET_Current_Funnel_Status__c,
            'DET_Current_Funnel_Status__c incorrect value'
        );
    }

    //Test CRM-20912
    @isTest
    static void testDFRCreationOpen() {
        Test.startTest();
        Lead ld = (Lead) new SObjectBuilder(Lead.SObjectType)
            .setField(Lead.LastName, Test_DemandFunnelHelper.LEADLASTNAME)
            .setField(Lead.Status, LeadTriggerHelper.LEADSTATUSOPEN)
            .setField(Lead.Email, testEmail)
            .setField(Lead.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Lead.LeadSource, Test_DemandFunnelHelper.LEADSOURCE)
            .create()
            .getRecord();
        Test.stopTest();

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRS(
            ld,
            new List<String>{
                'Lead_Name_on_Creation__c',
                'Lead_Email_on_Creation__c',
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
                'EOL_Entered_From__c'
            }
        );
        System.assertEquals(
            Test_DemandFunnelHelper.LEADLASTNAME,
            dfrList[0].Lead_Name_on_Creation__c,
            'Lead_Name_on_Creation__c incorrect value'
        );
        System.assertEquals(
            testEmail,
            dfrList[0].Lead_Email_on_Creation__c,
            'Lead_Email_on_Creation__c incorrect value'
        );
        System.assertEquals(Test_DemandFunnelHelper.CREATED, dfrList[0].Prospect_Entered_From__c, 'Prospect_Entered_From__c incorrect value');
        System.assertEquals(null, dfrList[0].Prospect_Exited_To__c, 'Prospect_Exited_To__c incorrect value');
        System.assertEquals(null, dfrList[0].MQL_Entered_From__c, 'MQL_Entered_From__c incorrect value');
        System.assertEquals(null, dfrList[0].MQL_Exited_To__c, 'MQL_Exited_To__c incorrect value');
        System.assertEquals(null, dfrList[0].TAL_Entered_From__c, 'TAL_Entered_From__c incorrect value');
        System.assertEquals(null, dfrList[0].TAL_Exited_To__c, 'TAL_Exited_To__c incorrect value');
        System.assertEquals(null, dfrList[0].SAL_Entered_From__c, 'SAL_Entered_From__c incorrect value');
        System.assertEquals(null, dfrList[0].SAL_Exited_To__c, 'SAL_Exited_To__c incorrect value');
        System.assertEquals(null, dfrList[0].EOL_Entered_From__c, 'EOL_Entered_From__c incorrect value');
        System.assertEquals('Active', dfrList[0].DFR_Active_Status__c, 'DFR_Active_Status__c incorrect value');
        System.assertEquals(
            Test_DemandFunnelHelper.PROSPECTFUNNELSTATUS,
            dfrList[0].DET_Current_Funnel_Status__c,
            'DET_Current_Funnel_Status__c incorrect value'
        );
    }

    //Test CRM-20913
    @isTest
    static void testDFRCreationSuspect() {
        Test.startTest();
        Lead ld = (Lead) new SObjectBuilder(Lead.SObjectType)
            .setField(Lead.LastName, Test_DemandFunnelHelper.LEADLASTNAME)
            .setField(Lead.Status, LeadTriggerHelper.LEADSTATUSSUSPECT)
            .setField(Lead.Email, testEmail)
            .setField(Lead.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Lead.LeadSource, Test_DemandFunnelHelper.LEADSOURCE)
            .create()
            .getRecord();
        Test.stopTest();

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRS(
            ld,
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
                'EOL_Entered_From__c'
            }
        );
        System.assertEquals(true, dfrList.isEmpty(), 'A DFR record should not be created');
    }

    //Test CRM-20914
    @isTest
    static void testDFRCreationReNew() {
        Test.startTest();
        Lead ld = (Lead) new SObjectBuilder(Lead.SObjectType)
            .setField(Lead.LastName, Test_DemandFunnelHelper.LEADLASTNAME)
            .setField(Lead.Status, LeadTriggerHelper.LEADSTATUSRENEW)
            .setField(Lead.Email, testEmail)
            .setField(Lead.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Lead.LeadSource, Test_DemandFunnelHelper.LEADSOURCE)
            .create()
            .getRecord();
        Test.stopTest();

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRS(
            ld,
            new List<String>{
                'Lead_Name_on_Creation__c',
                'Lead_Email_on_Creation__c',
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
                'EOL_Entered_From__c'
            }
        );
        System.assertEquals(
            Test_DemandFunnelHelper.LEADLASTNAME,
            dfrList[0].Lead_Name_on_Creation__c,
            'Lead_Name_on_Creation__c incorrect value'
        );
        System.assertEquals(
            testEmail,
            dfrList[0].Lead_Email_on_Creation__c,
            'Lead_Email_on_Creation__c incorrect value'
        );
        System.assertEquals(
            Test_DemandFunnelHelper.BACKFILLED,
            dfrList[0].Prospect_Entered_From__c,
            'Prospect_Entered_From__c incorrect value'
        );
        System.assertEquals(Test_DemandFunnelHelper.BACKFILLED, dfrList[0].Prospect_Exited_To__c, 'Prospect_Exited_To__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.CREATED, dfrList[0].MQL_Entered_From__c, 'MQL_Entered_From__c incorrect value');
        System.assertEquals(null, dfrList[0].MQL_Exited_To__c, 'MQL_Exited_To__c incorrect value');
        System.assertEquals(null, dfrList[0].TAL_Entered_From__c, 'TAL_Entered_From__c incorrect value');
        System.assertEquals(null, dfrList[0].TAL_Exited_To__c, 'TAL_Exited_To__c incorrect value');
        System.assertEquals(null, dfrList[0].SAL_Entered_From__c, 'SAL_Entered_From__c incorrect value');
        System.assertEquals(null, dfrList[0].SAL_Exited_To__c, 'SAL_Exited_To__c incorrect value');
        System.assertEquals(null, dfrList[0].EOL_Entered_From__c, 'EOL_Entered_From__c incorrect value');
        System.assertEquals('Active', dfrList[0].DFR_Active_Status__c, 'DFR_Active_Status__c incorrect value');
        System.assertEquals(
            Test_DemandFunnelHelper.MQLFUNNELSTATUS,
            dfrList[0].DET_Current_Funnel_Status__c,
            'DET_Current_Funnel_Status__c incorrect value'
        );
    }

    //Test CRM-20915
    @isTest
    static void testDFRCreationNew() {
        Test.startTest();
        Lead ld = (Lead) new SObjectBuilder(Lead.SObjectType)
            .setField(Lead.LastName, Test_DemandFunnelHelper.LEADLASTNAME)
            .setField(Lead.Status, LeadTriggerHelper.LEADSTATUSNEW)
            .setField(Lead.Email, testEmail)
            .setField(Lead.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Lead.LeadSource, Test_DemandFunnelHelper.LEADSOURCE)
            .create()
            .getRecord();
        Test.stopTest();

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRS(
            ld,
            new List<String>{
                'Lead_Name_on_Creation__c',
                'Lead_Email_on_Creation__c',
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
                'EOL_Entered_From__c'
            }
        );
        System.assertEquals(
            Test_DemandFunnelHelper.LEADLASTNAME,
            dfrList[0].Lead_Name_on_Creation__c,
            'Lead_Name_on_Creation__c incorrect value'
        );
        System.assertEquals(
            testEmail,
            dfrList[0].Lead_Email_on_Creation__c,
            'Lead_Email_on_Creation__c incorrect value'
        );
        System.assertEquals(
            Test_DemandFunnelHelper.BACKFILLED,
            dfrList[0].Prospect_Entered_From__c,
            'Prospect_Entered_From__c incorrect value'
        );
        System.assertEquals(Test_DemandFunnelHelper.BACKFILLED, dfrList[0].Prospect_Exited_To__c, 'Prospect_Exited_To__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.CREATED, dfrList[0].MQL_Entered_From__c, 'MQL_Entered_From__c incorrect value');
        System.assertEquals(null, dfrList[0].MQL_Exited_To__c, 'MQL_Exited_To__c incorrect value');
        System.assertEquals(null, dfrList[0].TAL_Entered_From__c, 'TAL_Entered_From__c incorrect value');
        System.assertEquals(null, dfrList[0].TAL_Exited_To__c, 'TAL_Exited_To__c incorrect value');
        System.assertEquals(null, dfrList[0].SAL_Entered_From__c, 'SAL_Entered_From__c incorrect value');
        System.assertEquals(null, dfrList[0].SAL_Exited_To__c, 'SAL_Exited_To__c incorrect value');
        System.assertEquals(null, dfrList[0].EOL_Entered_From__c, 'EOL_Entered_From__c incorrect value');
        System.assertEquals('Active', dfrList[0].DFR_Active_Status__c, 'DFR_Active_Status__c incorrect value');
        System.assertEquals(
            Test_DemandFunnelHelper.MQLFUNNELSTATUS,
            dfrList[0].DET_Current_Funnel_Status__c,
            'DET_Current_Funnel_Status__c incorrect value'
        );
    }

    //Test CRM-21488
    @isTest
    static void testStatusChangesFromOpenToReNewSDRUser() {
        User sysUser = Test_DemandFunnelHelper.getSystemUser();
        sysUser.Team__c = Test_DemandFunnelHelper.SDRTEAM;
        update sysUser;

        Lead ld = (Lead) new SObjectBuilder(Lead.SObjectType)
            .setField(Lead.LastName, Test_DemandFunnelHelper.LEADLASTNAME)
            .setField(Lead.Status, LeadTriggerHelper.LEADSTATUSOPEN)
            .setField(Lead.Email, testEmail)
            .setField(Lead.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Lead.LeadSource, Test_DemandFunnelHelper.LEADSOURCE)
            .setField(Lead.OwnerId, sysUser.Id)
            .createAsUser(sysUser)
            .getRecord();

        Test.startTest();
        ld.Status = LeadTriggerHelper.LEADSTATUSRENEW;
        update ld;
        Test.stopTest();

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRS(
            ld,
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
                'EOL_Entered_From__c'
            }
        );
        System.assertEquals(Test_DemandFunnelHelper.CREATED, dfrList[0].Prospect_Entered_From__c, 'Prospect_Entered_From__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.MQL, dfrList[0].Prospect_Exited_To__c, 'Prospect_Exited_To__c incorrect value');
        System.assertEquals('Prospect', dfrList[0].MQL_Entered_From__c, 'MQL_Entered_From__c incorrect value');
        System.assertEquals(null, dfrList[0].MQL_Exited_To__c, 'MQL_Exited_To__c incorrect value');
        System.assertEquals(null, dfrList[0].TAL_Entered_From__c, 'TAL_Entered_From__c incorrect value');
        System.assertEquals(null, dfrList[0].TAL_Exited_To__c, 'TAL_Exited_To__c incorrect value');
        System.assertEquals(null, dfrList[0].SAL_Entered_From__c, 'SAL_Entered_From__c incorrect value');
        System.assertEquals(null, dfrList[0].SAL_Exited_To__c, 'SAL_Exited_To__c incorrect value');
        System.assertEquals(null, dfrList[0].EOL_Entered_From__c, 'EOL_Entered_From__c incorrect value');
        System.assertEquals('Active', dfrList[0].DFR_Active_Status__c, 'DFR_Active_Status__c incorrect value');
        System.assertEquals(
            Test_DemandFunnelHelper.MQLFUNNELSTATUS,
            dfrList[0].DET_Current_Funnel_Status__c,
            'DET_Current_Funnel_Status__c incorrect value'
        );
    }

    //Test CRM-21488
    @isTest
    static void testStatusChangesFromOpenToReNewNotNullUser() {
        User sysUser = Test_DemandFunnelHelper.getSystemUser();
        sysUser.Team__c = 'Not null Team';
        update sysUser;

        Lead ld = (Lead) new SObjectBuilder(Lead.SObjectType)
            .setField(Lead.LastName, Test_DemandFunnelHelper.LEADLASTNAME)
            .setField(Lead.Status, LeadTriggerHelper.LEADSTATUSOPEN)
            .setField(Lead.Email, testEmail)
            .setField(Lead.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Lead.LeadSource, Test_DemandFunnelHelper.LEADSOURCE)
            .setField(Lead.OwnerId, sysUser.Id)
            .createAsUser(sysUser)
            .getRecord();

        Test.startTest();
        ld.Status = LeadTriggerHelper.LEADSTATUSRENEW;
        update ld;
        Test.stopTest();

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRS(
            ld,
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
                'EOL_Entered_From__c'
            }
        );
        System.assertEquals(Test_DemandFunnelHelper.CREATED, dfrList[0].Prospect_Entered_From__c, 'Prospect_Entered_From__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.MQL, dfrList[0].Prospect_Exited_To__c, 'Prospect_Exited_To__c incorrect value');
        System.assertEquals('Prospect', dfrList[0].MQL_Entered_From__c, 'MQL_Entered_From__c incorrect value');
        System.assertEquals(null, dfrList[0].MQL_Exited_To__c, 'MQL_Exited_To__c incorrect value');
        System.assertEquals(null, dfrList[0].TAL_Entered_From__c, 'TAL_Entered_From__c incorrect value');
        System.assertEquals(null, dfrList[0].TAL_Exited_To__c, 'TAL_Exited_To__c incorrect value');
        System.assertEquals(null, dfrList[0].SAL_Entered_From__c, 'SAL_Entered_From__c incorrect value');
        System.assertEquals(null, dfrList[0].SAL_Exited_To__c, 'SAL_Exited_To__c incorrect value');
        System.assertEquals(null, dfrList[0].EOL_Entered_From__c, 'EOL_Entered_From__c incorrect value');
        System.assertEquals('Active', dfrList[0].DFR_Active_Status__c, 'DFR_Active_Status__c incorrect value');
        System.assertEquals(
            Test_DemandFunnelHelper.MQLFUNNELSTATUS,
            dfrList[0].DET_Current_Funnel_Status__c,
            'DET_Current_Funnel_Status__c incorrect value'
        );
    }

    //Test CRM-21489
    @isTest
    static void testStatusChangesFromOpenToNewSDRUser() {
        User sysUser = Test_DemandFunnelHelper.getSystemUser();
        sysUser.Team__c = Test_DemandFunnelHelper.SDRTEAM;
        update sysUser;

        Lead ld = (Lead) new SObjectBuilder(Lead.SObjectType)
            .setField(Lead.LastName, Test_DemandFunnelHelper.LEADLASTNAME)
            .setField(Lead.Status, LeadTriggerHelper.LEADSTATUSOPEN)
            .setField(Lead.Email, testEmail)
            .setField(Lead.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Lead.LeadSource, Test_DemandFunnelHelper.LEADSOURCE)
            .setField(Lead.OwnerId, sysUser.Id)
            .createAsUser(sysUser)
            .getRecord();

        Test.startTest();
        ld.Status = LeadTriggerHelper.LEADSTATUSNEW;
        update ld;
        Test.stopTest();

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRS(
            ld,
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
                'EOL_Entered_From__c'
            }
        );
        System.assertEquals(Test_DemandFunnelHelper.CREATED, dfrList[0].Prospect_Entered_From__c, 'Prospect_Entered_From__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.MQL, dfrList[0].Prospect_Exited_To__c, 'Prospect_Exited_To__c incorrect value');
        System.assertEquals('Prospect', dfrList[0].MQL_Entered_From__c, 'MQL_Entered_From__c incorrect value');
        System.assertEquals(null, dfrList[0].MQL_Exited_To__c, 'MQL_Exited_To__c incorrect value');
        System.assertEquals(null, dfrList[0].TAL_Entered_From__c, 'TAL_Entered_From__c incorrect value');
        System.assertEquals(null, dfrList[0].TAL_Exited_To__c, 'TAL_Exited_To__c incorrect value');
        System.assertEquals(null, dfrList[0].SAL_Entered_From__c, 'SAL_Entered_From__c incorrect value');
        System.assertEquals(null, dfrList[0].SAL_Exited_To__c, 'SAL_Exited_To__c incorrect value');
        System.assertEquals(null, dfrList[0].EOL_Entered_From__c, 'EOL_Entered_From__c incorrect value');
        System.assertEquals('Active', dfrList[0].DFR_Active_Status__c, 'DFR_Active_Status__c incorrect value');
        System.assertEquals(
            Test_DemandFunnelHelper.MQLFUNNELSTATUS,
            dfrList[0].DET_Current_Funnel_Status__c,
            'DET_Current_Funnel_Status__c incorrect value'
        );
    }

    //Test CRM-21489
    @isTest
    static void testStatusChangesFromOpenToNewNotNullUser() {
        User sysUser = Test_DemandFunnelHelper.getSystemUser();
        sysUser.Team__c = 'Not null Team';
        update sysUser;

        Lead ld = (Lead) new SObjectBuilder(Lead.SObjectType)
            .setField(Lead.LastName, Test_DemandFunnelHelper.LEADLASTNAME)
            .setField(Lead.Status, LeadTriggerHelper.LEADSTATUSOPEN)
            .setField(Lead.Email, testEmail)
            .setField(Lead.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Lead.LeadSource, Test_DemandFunnelHelper.LEADSOURCE)
            .setField(Lead.OwnerId, sysUser.Id)
            .createAsUser(sysUser)
            .getRecord();

        Test.startTest();
        ld.Status = LeadTriggerHelper.LEADSTATUSNEW;
        update ld;
        Test.stopTest();

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRS(
            ld,
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
                'EOL_Entered_From__c'
            }
        );
        System.assertEquals(Test_DemandFunnelHelper.CREATED, dfrList[0].Prospect_Entered_From__c, 'Prospect_Entered_From__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.MQL, dfrList[0].Prospect_Exited_To__c, 'Prospect_Exited_To__c incorrect value');
        System.assertEquals('Prospect', dfrList[0].MQL_Entered_From__c, 'MQL_Entered_From__c incorrect value');
        System.assertEquals(null, dfrList[0].MQL_Exited_To__c, 'MQL_Exited_To__c incorrect value');
        System.assertEquals(null, dfrList[0].TAL_Entered_From__c, 'TAL_Entered_From__c incorrect value');
        System.assertEquals(null, dfrList[0].TAL_Exited_To__c, 'TAL_Exited_To__c incorrect value');
        System.assertEquals(null, dfrList[0].SAL_Entered_From__c, 'SAL_Entered_From__c incorrect value');
        System.assertEquals(null, dfrList[0].SAL_Exited_To__c, 'SAL_Exited_To__c incorrect value');
        System.assertEquals(null, dfrList[0].EOL_Entered_From__c, 'EOL_Entered_From__c incorrect value');
        System.assertEquals('Active', dfrList[0].DFR_Active_Status__c, 'DFR_Active_Status__c incorrect value');
        System.assertEquals(
            Test_DemandFunnelHelper.MQLFUNNELSTATUS,
            dfrList[0].DET_Current_Funnel_Status__c,
            'DET_Current_Funnel_Status__c incorrect value'
        );
    }

    //Test CRM-21490
    @isTest
    static void testStatusChangesFromOpenToCalloutSDRUser() {
        User sysUser = Test_DemandFunnelHelper.getSystemUser();
        sysUser.Team__c = Test_DemandFunnelHelper.SDRTEAM;
        update sysUser;

        Lead ld = (Lead) new SObjectBuilder(Lead.SObjectType)
            .setField(Lead.LastName, Test_DemandFunnelHelper.LEADLASTNAME)
            .setField(Lead.Status, LeadTriggerHelper.LEADSTATUSOPEN)
            .setField(Lead.Email, testEmail)
            .setField(Lead.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Lead.LeadSource, Test_DemandFunnelHelper.LEADSOURCE)
            .setField(Lead.OwnerId, sysUser.Id)
            .createAsUser(sysUser)
            .getRecord();

        Test.startTest();
        ld.Status = LeadTriggerHelper.LEADSTATUSCALLOUT;
        update ld;
        Test.stopTest();

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRS(
            ld,
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
                'EOL_Entered_From__c'
            }
        );
        System.assertEquals(Test_DemandFunnelHelper.CREATED, dfrList[0].Prospect_Entered_From__c, 'Prospect_Entered_From__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.TAL, dfrList[0].Prospect_Exited_To__c, 'Prospect_Exited_To__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.BACKFILLED, dfrList[0].MQL_Entered_From__c, 'MQL_Entered_From__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.BACKFILLED, dfrList[0].MQL_Exited_To__c, 'MQL_Exited_To__c incorrect value');
        System.assertEquals('Prospect', dfrList[0].TAL_Entered_From__c, 'TAL_Entered_From__c incorrect value');
        System.assertEquals(null, dfrList[0].TAL_Exited_To__c, 'TAL_Exited_To__c incorrect value');
        System.assertEquals(null, dfrList[0].SAL_Entered_From__c, 'SAL_Entered_From__c incorrect value');
        System.assertEquals(null, dfrList[0].SAL_Exited_To__c, 'SAL_Exited_To__c incorrect value');
        System.assertEquals(null, dfrList[0].EOL_Entered_From__c, 'EOL_Entered_From__c incorrect value');
        System.assertEquals('Active', dfrList[0].DFR_Active_Status__c, 'DFR_Active_Status__c incorrect value');
        System.assertEquals(
            Test_DemandFunnelHelper.TALFUNNELSTATUS,
            dfrList[0].DET_Current_Funnel_Status__c,
            'DET_Current_Funnel_Status__c incorrect value'
        );
    }

    //Test CRM-21491
    @isTest
    static void testStatusChangesFromOpenToContactedSDRUser() {
        User sysUser = Test_DemandFunnelHelper.getSystemUser();
        sysUser.Team__c = Test_DemandFunnelHelper.SDRTEAM;
        update sysUser;

        Lead ld = (Lead) new SObjectBuilder(Lead.SObjectType)
            .setField(Lead.LastName, Test_DemandFunnelHelper.LEADLASTNAME)
            .setField(Lead.Status, LeadTriggerHelper.LEADSTATUSOPEN)
            .setField(Lead.Email, testEmail)
            .setField(Lead.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Lead.LeadSource, Test_DemandFunnelHelper.LEADSOURCE)
            .setField(Lead.OwnerId, sysUser.Id)
            .createAsUser(sysUser)
            .getRecord();

        Test.startTest();
        ld.Status = LeadTriggerHelper.LEADSTATUSCONTACTED;
        update ld;
        Test.stopTest();

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRS(
            ld,
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
                'EOL_Entered_From__c'
            }
        );
        System.assertEquals(Test_DemandFunnelHelper.CREATED, dfrList[0].Prospect_Entered_From__c, 'Prospect_Entered_From__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.TAL, dfrList[0].Prospect_Exited_To__c, 'Prospect_Exited_To__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.BACKFILLED, dfrList[0].MQL_Entered_From__c, 'MQL_Entered_From__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.BACKFILLED, dfrList[0].MQL_Exited_To__c, 'MQL_Exited_To__c incorrect value');
        System.assertEquals('Prospect', dfrList[0].TAL_Entered_From__c, 'TAL_Entered_From__c incorrect value');
        System.assertEquals(null, dfrList[0].TAL_Exited_To__c, 'TAL_Exited_To__c incorrect value');
        System.assertEquals(null, dfrList[0].SAL_Entered_From__c, 'SAL_Entered_From__c incorrect value');
        System.assertEquals(null, dfrList[0].SAL_Exited_To__c, 'SAL_Exited_To__c incorrect value');
        System.assertEquals(null, dfrList[0].EOL_Entered_From__c, 'EOL_Entered_From__c incorrect value');
        System.assertEquals('Active', dfrList[0].DFR_Active_Status__c, 'DFR_Active_Status__c incorrect value');
        System.assertEquals(
            Test_DemandFunnelHelper.TALFUNNELSTATUS,
            dfrList[0].DET_Current_Funnel_Status__c,
            'DET_Current_Funnel_Status__c incorrect value'
        );
    }

    //Test CRM-21492
    @isTest
    static void testStatusChangesFromOpenToCalloutNotNullUser() {
        User sysUser = Test_DemandFunnelHelper.getSystemUser();
        sysUser.Team__c = 'Not null Team';
        update sysUser;

        Lead ld = (Lead) new SObjectBuilder(Lead.SObjectType)
            .setField(Lead.LastName, Test_DemandFunnelHelper.LEADLASTNAME)
            .setField(Lead.Status, LeadTriggerHelper.LEADSTATUSOPEN)
            .setField(Lead.Email, testEmail)
            .setField(Lead.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Lead.LeadSource, Test_DemandFunnelHelper.LEADSOURCE)
            .setField(Lead.OwnerId, sysUser.Id)
            .createAsUser(sysUser)
            .getRecord();

        Test.startTest();
        ld.Status = LeadTriggerHelper.LEADSTATUSCALLOUT;
        update ld;
        Test.stopTest();

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRS(
            ld,
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
                'EOL_Entered_From__c'
            }
        );
        System.assertEquals(Test_DemandFunnelHelper.CREATED, dfrList[0].Prospect_Entered_From__c, 'Prospect_Entered_From__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.SAL, dfrList[0].Prospect_Exited_To__c, 'Prospect_Exited_To__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.BACKFILLED, dfrList[0].MQL_Entered_From__c, 'MQL_Entered_From__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.BACKFILLED, dfrList[0].MQL_Exited_To__c, 'MQL_Exited_To__c incorrect value');
        System.assertEquals(null, dfrList[0].TAL_Entered_From__c, 'TAL_Entered_From__c incorrect value');
        System.assertEquals(null, dfrList[0].TAL_Exited_To__c, 'TAL_Exited_To__c incorrect value');
        System.assertEquals('Prospect', dfrList[0].SAL_Entered_From__c, 'SAL_Entered_From__c incorrect value');
        System.assertEquals(null, dfrList[0].SAL_Exited_To__c, 'SAL_Exited_To__c incorrect value');
        System.assertEquals(null, dfrList[0].EOL_Entered_From__c, 'EOL_Entered_From__c incorrect value');
        System.assertEquals('Active', dfrList[0].DFR_Active_Status__c, 'DFR_Active_Status__c incorrect value');
        System.assertEquals(
            Test_DemandFunnelHelper.SALFUNNELSTATUS,
            dfrList[0].DET_Current_Funnel_Status__c,
            'DET_Current_Funnel_Status__c incorrect value'
        );
    }

    //Test CRM-21493
    @isTest
    static void testStatusChangesFromOpenToContactedNotNullUser() {
        User sysUser = Test_DemandFunnelHelper.getSystemUser();
        sysUser.Team__c = 'Not null Team';
        update sysUser;

        Lead ld = (Lead) new SObjectBuilder(Lead.SObjectType)
            .setField(Lead.LastName, Test_DemandFunnelHelper.LEADLASTNAME)
            .setField(Lead.Status, LeadTriggerHelper.LEADSTATUSOPEN)
            .setField(Lead.Email, testEmail)
            .setField(Lead.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Lead.LeadSource, Test_DemandFunnelHelper.LEADSOURCE)
            .setField(Lead.OwnerId, sysUser.Id)
            .createAsUser(sysUser)
            .getRecord();

        Test.startTest();
        ld.Status = LeadTriggerHelper.LEADSTATUSCONTACTED;
        update ld;
        Test.stopTest();

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRS(
            ld,
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
                'EOL_Entered_From__c'
            }
        );
        System.assertEquals(Test_DemandFunnelHelper.CREATED, dfrList[0].Prospect_Entered_From__c, 'Prospect_Entered_From__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.SAL, dfrList[0].Prospect_Exited_To__c, 'Prospect_Exited_To__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.BACKFILLED, dfrList[0].MQL_Entered_From__c, 'MQL_Entered_From__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.BACKFILLED, dfrList[0].MQL_Exited_To__c, 'MQL_Exited_To__c incorrect value');
        System.assertEquals(null, dfrList[0].TAL_Entered_From__c, 'TAL_Entered_From__c incorrect value');
        System.assertEquals(null, dfrList[0].TAL_Exited_To__c, 'TAL_Exited_To__c incorrect value');
        System.assertEquals('Prospect', dfrList[0].SAL_Entered_From__c, 'SAL_Entered_From__c incorrect value');
        System.assertEquals(null, dfrList[0].SAL_Exited_To__c, 'SAL_Exited_To__c incorrect value');
        System.assertEquals(null, dfrList[0].EOL_Entered_From__c, 'EOL_Entered_From__c incorrect value');
        System.assertEquals('Active', dfrList[0].DFR_Active_Status__c, 'DFR_Active_Status__c incorrect value');
        System.assertEquals(
            Test_DemandFunnelHelper.SALFUNNELSTATUS,
            dfrList[0].DET_Current_Funnel_Status__c,
            'DET_Current_Funnel_Status__c incorrect value'
        );
    }

    //Test CRM-21496
    @isTest
    static void testStatusChangesFromNewToCalloutSDRUser() {
        User sysUser = Test_DemandFunnelHelper.getSystemUser();
        sysUser.Team__c = Test_DemandFunnelHelper.SDRTEAM;
        update sysUser;

        Lead ld = (Lead) new SObjectBuilder(Lead.SObjectType)
            .setField(Lead.LastName, Test_DemandFunnelHelper.LEADLASTNAME)
            .setField(Lead.Status, LeadTriggerHelper.LEADSTATUSNEW)
            .setField(Lead.Email, testEmail)
            .setField(Lead.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Lead.LeadSource, Test_DemandFunnelHelper.LEADSOURCE)
            .setField(Lead.OwnerId, sysUser.Id)
            .createAsUser(sysUser)
            .getRecord();

        Test.startTest();
        ld.Status = LeadTriggerHelper.LEADSTATUSCALLOUT;
        update ld;
        Test.stopTest();

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRS(
            ld,
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
                'EOL_Entered_From__c'
            }
        );
        System.assertEquals(
            Test_DemandFunnelHelper.BACKFILLED,
            dfrList[0].Prospect_Entered_From__c,
            'Prospect_Entered_From__c incorrect value'
        );
        System.assertEquals(Test_DemandFunnelHelper.BACKFILLED, dfrList[0].Prospect_Exited_To__c, 'Prospect_Exited_To__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.CREATED, dfrList[0].MQL_Entered_From__c, 'MQL_Entered_From__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.TAL, dfrList[0].MQL_Exited_To__c, 'MQL_Exited_To__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.MQL, dfrList[0].TAL_Entered_From__c, 'TAL_Entered_From__c incorrect value');
        System.assertEquals(null, dfrList[0].TAL_Exited_To__c, 'TAL_Exited_To__c incorrect value');
        System.assertEquals(null, dfrList[0].SAL_Entered_From__c, 'SAL_Entered_From__c incorrect value');
        System.assertEquals(null, dfrList[0].SAL_Exited_To__c, 'SAL_Exited_To__c incorrect value');
        System.assertEquals(null, dfrList[0].EOL_Entered_From__c, 'EOL_Entered_From__c incorrect value');
        System.assertEquals('Active', dfrList[0].DFR_Active_Status__c, 'DFR_Active_Status__c incorrect value');
        System.assertEquals(
            Test_DemandFunnelHelper.TALFUNNELSTATUS,
            dfrList[0].DET_Current_Funnel_Status__c,
            'DET_Current_Funnel_Status__c incorrect value'
        );
    }

    //Test CRM-21497
    @isTest
    static void testStatusChangesFromNewToContactedSDRUser() {
        User sysUser = Test_DemandFunnelHelper.getSystemUser();
        sysUser.Team__c = Test_DemandFunnelHelper.SDRTEAM;
        update sysUser;

        Lead ld = (Lead) new SObjectBuilder(Lead.SObjectType)
            .setField(Lead.LastName, Test_DemandFunnelHelper.LEADLASTNAME)
            .setField(Lead.Status, LeadTriggerHelper.LEADSTATUSNEW)
            .setField(Lead.Email, testEmail)
            .setField(Lead.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Lead.LeadSource, Test_DemandFunnelHelper.LEADSOURCE)
            .setField(Lead.OwnerId, sysUser.Id)
            .createAsUser(sysUser)
            .getRecord();

        Test.startTest();
        ld.Status = LeadTriggerHelper.LEADSTATUSCONTACTED;
        update ld;
        Test.stopTest();

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRS(
            ld,
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
                'EOL_Entered_From__c'
            }
        );
        System.assertEquals(
            Test_DemandFunnelHelper.BACKFILLED,
            dfrList[0].Prospect_Entered_From__c,
            'Prospect_Entered_From__c incorrect value'
        );
        System.assertEquals(Test_DemandFunnelHelper.BACKFILLED, dfrList[0].Prospect_Exited_To__c, 'Prospect_Exited_To__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.CREATED, dfrList[0].MQL_Entered_From__c, 'MQL_Entered_From__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.TAL, dfrList[0].MQL_Exited_To__c, 'MQL_Exited_To__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.MQL, dfrList[0].TAL_Entered_From__c, 'TAL_Entered_From__c incorrect value');
        System.assertEquals(null, dfrList[0].TAL_Exited_To__c, 'TAL_Exited_To__c incorrect value');
        System.assertEquals(null, dfrList[0].SAL_Entered_From__c, 'SAL_Entered_From__c incorrect value');
        System.assertEquals(null, dfrList[0].SAL_Exited_To__c, 'SAL_Exited_To__c incorrect value');
        System.assertEquals(null, dfrList[0].EOL_Entered_From__c, 'EOL_Entered_From__c incorrect value');
        System.assertEquals('Active', dfrList[0].DFR_Active_Status__c, 'DFR_Active_Status__c incorrect value');
        System.assertEquals(
            Test_DemandFunnelHelper.TALFUNNELSTATUS,
            dfrList[0].DET_Current_Funnel_Status__c,
            'DET_Current_Funnel_Status__c incorrect value'
        );
    }

    //Test CRM-21498
    @isTest
    static void testStatusChangesFromNewToCalloutNotNullUser() {
        User sysUser = Test_DemandFunnelHelper.getSystemUser();
        sysUser.Team__c = 'Not null Team';
        update sysUser;

        Lead ld = (Lead) new SObjectBuilder(Lead.SObjectType)
            .setField(Lead.LastName, Test_DemandFunnelHelper.LEADLASTNAME)
            .setField(Lead.Status, LeadTriggerHelper.LEADSTATUSNEW)
            .setField(Lead.Email, testEmail)
            .setField(Lead.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Lead.LeadSource, Test_DemandFunnelHelper.LEADSOURCE)
            .setField(Lead.OwnerId, sysUser.Id)
            .createAsUser(sysUser)
            .getRecord();

        Test.startTest();
        ld.Status = LeadTriggerHelper.LEADSTATUSCALLOUT;
        update ld;
        Test.stopTest();

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRS(
            ld,
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
                'EOL_Entered_From__c'
            }
        );
        System.assertEquals(
            Test_DemandFunnelHelper.BACKFILLED,
            dfrList[0].Prospect_Entered_From__c,
            'Prospect_Entered_From__c incorrect value'
        );
        System.assertEquals(Test_DemandFunnelHelper.BACKFILLED, dfrList[0].Prospect_Exited_To__c, 'Prospect_Exited_To__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.CREATED, dfrList[0].MQL_Entered_From__c, 'MQL_Entered_From__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.SAL, dfrList[0].MQL_Exited_To__c, 'MQL_Exited_To__c incorrect value');
        System.assertEquals(null, dfrList[0].TAL_Entered_From__c, 'TAL_Entered_From__c incorrect value');
        System.assertEquals(null, dfrList[0].TAL_Exited_To__c, 'TAL_Exited_To__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.MQL, dfrList[0].SAL_Entered_From__c, 'SAL_Entered_From__c incorrect value');
        System.assertEquals(null, dfrList[0].SAL_Exited_To__c, 'SAL_Exited_To__c incorrect value');
        System.assertEquals(null, dfrList[0].EOL_Entered_From__c, 'EOL_Entered_From__c incorrect value');
        System.assertEquals('Active', dfrList[0].DFR_Active_Status__c, 'DFR_Active_Status__c incorrect value');
        System.assertEquals(
            Test_DemandFunnelHelper.SALFUNNELSTATUS,
            dfrList[0].DET_Current_Funnel_Status__c,
            'DET_Current_Funnel_Status__c incorrect value'
        );
    }

    //Test CRM-21499
    @isTest
    static void testStatusChangesFromNewToContactedNotNullUser() {
        User sysUser = Test_DemandFunnelHelper.getSystemUser();
        sysUser.Team__c = 'Not null Team';
        update sysUser;

        Lead ld = (Lead) new SObjectBuilder(Lead.SObjectType)
            .setField(Lead.LastName, Test_DemandFunnelHelper.LEADLASTNAME)
            .setField(Lead.Status, LeadTriggerHelper.LEADSTATUSNEW)
            .setField(Lead.Email, testEmail)
            .setField(Lead.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Lead.LeadSource, Test_DemandFunnelHelper.LEADSOURCE)
            .setField(Lead.OwnerId, sysUser.Id)
            .createAsUser(sysUser)
            .getRecord();

        Test.startTest();
        ld.Status = LeadTriggerHelper.LEADSTATUSCONTACTED;
        update ld;
        Test.stopTest();

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRS(
            ld,
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
                'EOL_Entered_From__c'
            }
        );
        System.assertEquals(
            Test_DemandFunnelHelper.BACKFILLED,
            dfrList[0].Prospect_Entered_From__c,
            'Prospect_Entered_From__c incorrect value'
        );
        System.assertEquals(Test_DemandFunnelHelper.BACKFILLED, dfrList[0].Prospect_Exited_To__c, 'Prospect_Exited_To__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.CREATED, dfrList[0].MQL_Entered_From__c, 'MQL_Entered_From__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.SAL, dfrList[0].MQL_Exited_To__c, 'MQL_Exited_To__c incorrect value');
        System.assertEquals(null, dfrList[0].TAL_Entered_From__c, 'TAL_Entered_From__c incorrect value');
        System.assertEquals(null, dfrList[0].TAL_Exited_To__c, 'TAL_Exited_To__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.MQL, dfrList[0].SAL_Entered_From__c, 'SAL_Entered_From__c incorrect value');
        System.assertEquals(null, dfrList[0].SAL_Exited_To__c, 'SAL_Exited_To__c incorrect value');
        System.assertEquals(null, dfrList[0].EOL_Entered_From__c, 'EOL_Entered_From__c incorrect value');
        System.assertEquals('Active', dfrList[0].DFR_Active_Status__c, 'DFR_Active_Status__c incorrect value');
        System.assertEquals(
            Test_DemandFunnelHelper.SALFUNNELSTATUS,
            dfrList[0].DET_Current_Funnel_Status__c,
            'DET_Current_Funnel_Status__c incorrect value'
        );
    }

    //Test CRM-20933
    @isTest
    static void testStatusChangesLeadDowngraded() {
        User aeUser = (User) new UserSelector().selectUserByLastName(new List<String>{ Test_DemandFunnelHelper.AELASTNAME }).executeQuery()[0];
        Lead ld = (Lead) new SObjectBuilder(Lead.SObjectType)
            .setField(Lead.LastName, Test_DemandFunnelHelper.LEADLASTNAME)
            .setField(Lead.Status, LeadTriggerHelper.LEADSTATUSNEW)
            .setField(Lead.Email, testEmail)
            .setField(Lead.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Lead.LeadSource, Test_DemandFunnelHelper.LEADSOURCE)
            .setField(Lead.OwnerId, aeUser.Id)
            .create()
            .getRecord();

        Test.startTest();
        ld.Status = LeadTriggerHelper.LEADSTATUSDOWNGRADED;
        ld.Downgrade_Reason__c = 'Not a new lead';
        ld.Sub_Downgrade_Reason__c = 'Duplicate lead';
        update ld;
        Test.stopTest();

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRS(
            ld,
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
                'EOL_Entered_From__c'
            }
        );
        System.assertEquals('Inactive', dfrList[0].DFR_Active_Status__c, 'DFR_Active_Status__c incorrect value');
        System.assertEquals(
            Test_DemandFunnelHelper.DOWNGRADEDFUNNELSTATUS,
            dfrList[0].DET_Current_Funnel_Status__c,
            'DET_Current_Funnel_Status__c incorrect value'
        );
        System.assertEquals(Test_DemandFunnelHelper.DOWNGRADED, dfrList[0].MQL_Exited_To__c, 'MQL_Exited_To__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.MQL, dfrList[0].EOL_Entered_From__c, 'EOL_Entered_From__c incorrect value');
    }

    //Test Case CRM-20934
    @isTest
    static void testStatusChangesLeadDelete() {
        Test.startTest();
        User aeUser = (User) new UserSelector().selectUserByLastName(new List<String>{ Test_DemandFunnelHelper.AELASTNAME }).executeQuery()[0];
        Lead ld = (Lead) new SObjectBuilder(Lead.SObjectType)
            .setField(Lead.LastName, Test_DemandFunnelHelper.LEADLASTNAME)
            .setField(Lead.Status, LeadTriggerHelper.LEADSTATUSNEW)
            .setField(Lead.Email, testEmail)
            .setField(Lead.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Lead.LeadSource, Test_DemandFunnelHelper.LEADSOURCE)
            .setField(Lead.OwnerId, aeUser.Id)
            .build()
            .create()
            .getRecord();
        Test.stopTest();

        delete ld;

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRS(ld, new List<String>{ 'Lead__c', 'DET_Current_Funnel_Status__c' });
        System.assert(dfrList.isEmpty(), 'Lead__c was not deleted from DFR record');
    }

    //Test CRM-21443
    @isTest
    static void testChangeOwnerFromSysUserSDRToSDRContacted() {
        User sysUser = Test_DemandFunnelHelper.getSystemUser();
        sysUser.Team__c = Test_DemandFunnelHelper.SDRTEAM;
        User sdrUser = (User) new UserSelector()
            .selectUserByLastName(new List<String>{ Test_DemandFunnelHelper.SDRLASTNAME })
            .executeQuery()[0];

        Lead ld = (Lead) new SObjectBuilder(Lead.SObjectType)
            .setField(Lead.LastName, Test_DemandFunnelHelper.LEADLASTNAME)
            .setField(Lead.Status, LeadTriggerHelper.LEADSTATUSCONTACTED)
            .setField(Lead.Email, testEmail)
            .setField(Lead.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Lead.LeadSource, Test_DemandFunnelHelper.LEADSOURCE)
            .setField(Lead.OwnerId, sysUser.Id)
            .createAsUser(sysUser)
            .getRecord();

        Test.startTest();
        ld.OwnerId = sdrUser.Id;
        update ld;
        Test.stopTest();

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRS(
            ld,
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
                'Prospect_Owner_Name__c',
                'Prospect_Owner_Team__c',
                'MQL_Owner_Name__c',
                'TAL_Owner_Name__c',
                'TAL_Owner_Team__c'
            }
        );

        System.assertEquals('Active', dfrList[0].DFR_Active_Status__c, 'DFR_Active_Status__c incorrect value');
        System.assertEquals(
            Test_DemandFunnelHelper.TALFUNNELSTATUS,
            dfrList[0].DET_Current_Funnel_Status__c,
            'DET_Current_Funnel_Status__c incorrect value'
        );
        System.assertEquals(Test_DemandFunnelHelper.SDRTEAM, dfrList[0].Prospect_Owner_Team__c, 'Prospect_Owner_Team__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.SDRLASTNAME, dfrList[0].Prospect_Owner_Name__c, 'Prospect_Owner_Name__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.SDRTEAM, dfrList[0].MQL_Owner_Team__c, 'MQL_Owner_Team__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.SDRLASTNAME, dfrList[0].MQL_Owner_Name__c, 'MQL_Owner_Name__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.SDRTEAM, dfrList[0].TAL_Owner_Team__c, 'TAL_Owner_Team__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.SDRLASTNAME, dfrList[0].TAL_Owner_Name__c, 'TAL_Owner_Name__c incorrect value');
        System.assertEquals(
            Test_DemandFunnelHelper.BACKFILLED,
            dfrList[0].Prospect_Entered_From__c,
            'Prospect_Entered_From__c incorrect value'
        );
        System.assertEquals(Test_DemandFunnelHelper.BACKFILLED, dfrList[0].Prospect_Exited_To__c, 'Prospect_Exited_To__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.BACKFILLED, dfrList[0].MQL_Entered_From__c, 'MQL_Entered_From__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.BACKFILLED, dfrList[0].MQL_Exited_To__c, 'MQL_Exited_To__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.CREATED, dfrList[0].TAL_Entered_From__c, 'TAL_Entered_From__c incorrect value');
        System.assertEquals(null, dfrList[0].TAL_Exited_To__c, 'TAL_Exited_To__c incorrect value');
        System.assertEquals(null, dfrList[0].SAL_Entered_From__c, 'SAL_Entered_From__c incorrect value');
        System.assertEquals(null, dfrList[0].SAL_Exited_To__c, 'SAL_Exited_To__c incorrect value');
        System.assertEquals(null, dfrList[0].EOL_Entered_From__c, 'EOL_Entered_From__c incorrect value');
    }

    //Test CRM-21445
    @isTest
    static void testChangeOwnerFromSysUserSDRToAEContacted() {
        User sysUser = Test_DemandFunnelHelper.getSystemUser();
        sysUser.Team__c = Test_DemandFunnelHelper.SDRTEAM;
        User aeUser = (User) new UserSelector().selectUserByLastName(new List<String>{ Test_DemandFunnelHelper.AELASTNAME }).executeQuery()[0];

        Lead ld = (Lead) new SObjectBuilder(Lead.SObjectType)
            .setField(Lead.LastName, Test_DemandFunnelHelper.LEADLASTNAME)
            .setField(Lead.Status, LeadTriggerHelper.LEADSTATUSCONTACTED)
            .setField(Lead.Email, testEmail)
            .setField(Lead.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Lead.LeadSource, Test_DemandFunnelHelper.LEADSOURCE)
            .setField(Lead.OwnerId, sysUser.Id)
            .createAsUser(sysUser)
            .getRecord();

        Test.startTest();
        ld.OwnerId = aeUser.Id;
        update ld;
        Test.stopTest();

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRS(
            ld,
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
                'EOL_Entered_From__c'
            }
        );
        System.assertEquals('Active', dfrList[0].DFR_Active_Status__c, 'DFR_Active_Status__c incorrect value');
        System.assertEquals(
            Test_DemandFunnelHelper.SALFUNNELSTATUS,
            dfrList[0].DET_Current_Funnel_Status__c,
            'DET_Current_Funnel_Status__c incorrect value'
        );
        System.assertEquals(Test_DemandFunnelHelper.AETEAM, dfrList[0].MQL_Owner_Team__c, 'MQL_Owner_Team__c incorrect value');
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
        System.assertEquals(Test_DemandFunnelHelper.CREATED, dfrList[0].SAL_Entered_From__c, 'SAL_Entered_From__c incorrect value');
        System.assertEquals(null, dfrList[0].SAL_Exited_To__c, 'SAL_Exited_To__c incorrect value');
        System.assertEquals(null, dfrList[0].EOL_Entered_From__c, 'EOL_Entered_From__c incorrect value');
    }

    //Test CRM-21444
    @isTest
    static void testChangeOwnerFromSysUserSDRToSDRCallout() {
        User sysUser = Test_DemandFunnelHelper.getSystemUser();
        sysUser.Team__c = Test_DemandFunnelHelper.SDRTEAM;
        User sdrUser = (User) new UserSelector()
            .selectUserByLastName(new List<String>{ Test_DemandFunnelHelper.SDRLASTNAME })
            .executeQuery()[0];

        Lead ld = (Lead) new SObjectBuilder(Lead.SObjectType)
            .setField(Lead.LastName, Test_DemandFunnelHelper.LEADLASTNAME)
            .setField(Lead.Status, LeadTriggerHelper.LEADSTATUSCALLOUT)
            .setField(Lead.Email, testEmail)
            .setField(Lead.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Lead.LeadSource, Test_DemandFunnelHelper.LEADSOURCE)
            .setField(Lead.OwnerId, sysUser.Id)
            .createAsUser(sysUser)
            .getRecord();

        Test.startTest();
        ld.OwnerId = sdrUser.Id;
        update ld;
        Test.stopTest();

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRS(
            ld,
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
                'Prospect_Owner_Name__c',
                'Prospect_Owner_Team__c',
                'MQL_Owner_Name__c',
                'TAL_Owner_Name__c',
                'TAL_Owner_Team__c'
            }
        );

        System.assertEquals('Active', dfrList[0].DFR_Active_Status__c, 'DFR_Active_Status__c incorrect value');
        System.assertEquals(
            Test_DemandFunnelHelper.TALFUNNELSTATUS,
            dfrList[0].DET_Current_Funnel_Status__c,
            'DET_Current_Funnel_Status__c incorrect value'
        );
        System.assertEquals(Test_DemandFunnelHelper.SDRTEAM, dfrList[0].Prospect_Owner_Team__c, 'Prospect_Owner_Team__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.SDRLASTNAME, dfrList[0].Prospect_Owner_Name__c, 'Prospect_Owner_Name__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.SDRTEAM, dfrList[0].MQL_Owner_Team__c, 'MQL_Owner_Team__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.SDRLASTNAME, dfrList[0].MQL_Owner_Name__c, 'MQL_Owner_Name__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.SDRTEAM, dfrList[0].TAL_Owner_Team__c, 'TAL_Owner_Team__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.SDRLASTNAME, dfrList[0].TAL_Owner_Name__c, 'TAL_Owner_Name__c incorrect value');
        System.assertEquals(
            Test_DemandFunnelHelper.BACKFILLED,
            dfrList[0].Prospect_Entered_From__c,
            'Prospect_Entered_From__c incorrect value'
        );
        System.assertEquals(Test_DemandFunnelHelper.BACKFILLED, dfrList[0].Prospect_Exited_To__c, 'Prospect_Exited_To__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.BACKFILLED, dfrList[0].MQL_Entered_From__c, 'MQL_Entered_From__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.BACKFILLED, dfrList[0].MQL_Exited_To__c, 'MQL_Exited_To__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.CREATED, dfrList[0].TAL_Entered_From__c, 'TAL_Entered_From__c incorrect value');
        System.assertEquals(null, dfrList[0].TAL_Exited_To__c, 'TAL_Exited_To__c incorrect value');
        System.assertEquals(null, dfrList[0].SAL_Entered_From__c, 'SAL_Entered_From__c incorrect value');
        System.assertEquals(null, dfrList[0].SAL_Exited_To__c, 'SAL_Exited_To__c incorrect value');
        System.assertEquals(null, dfrList[0].EOL_Entered_From__c, 'EOL_Entered_From__c incorrect value');
    }

    //Test CRM-21446
    @isTest
    static void testChangeOwnerFromSysUserSDRToAECallout() {
        User sysUser = Test_DemandFunnelHelper.getSystemUser();
        sysUser.Team__c = Test_DemandFunnelHelper.SDRTEAM;
        User aeUser = (User) new UserSelector().selectUserByLastName(new List<String>{ Test_DemandFunnelHelper.AELASTNAME }).executeQuery()[0];

        Lead ld = (Lead) new SObjectBuilder(Lead.SObjectType)
            .setField(Lead.LastName, Test_DemandFunnelHelper.LEADLASTNAME)
            .setField(Lead.Status, LeadTriggerHelper.LEADSTATUSCALLOUT)
            .setField(Lead.Email, testEmail)
            .setField(Lead.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Lead.LeadSource, Test_DemandFunnelHelper.LEADSOURCE)
            .setField(Lead.OwnerId, sysUser.Id)
            .createAsUser(sysUser)
            .getRecord();

        Test.startTest();
        ld.OwnerId = aeUser.Id;
        update ld;
        Test.stopTest();

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRS(
            ld,
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
                'EOL_Entered_From__c'
            }
        );
        System.assertEquals('Active', dfrList[0].DFR_Active_Status__c, 'DFR_Active_Status__c incorrect value');
        System.assertEquals(
            Test_DemandFunnelHelper.SALFUNNELSTATUS,
            dfrList[0].DET_Current_Funnel_Status__c,
            'DET_Current_Funnel_Status__c incorrect value'
        );
        System.assertEquals(Test_DemandFunnelHelper.AETEAM, dfrList[0].MQL_Owner_Team__c, 'MQL_Owner_Team__c incorrect value');
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
        System.assertEquals(Test_DemandFunnelHelper.CREATED, dfrList[0].SAL_Entered_From__c, 'SAL_Entered_From__c incorrect value');
        System.assertEquals(null, dfrList[0].SAL_Exited_To__c, 'SAL_Exited_To__c incorrect value');
        System.assertEquals(null, dfrList[0].EOL_Entered_From__c, 'EOL_Entered_From__c incorrect value');
    }

    //Test CRM-21447
    @isTest
    static void testChangeOwnerFromSysUserSDRToSDRNew() {
        User sysUser = Test_DemandFunnelHelper.getSystemUser();
        sysUser.Team__c = Test_DemandFunnelHelper.SDRTEAM;
        User sdrUser = (User) new UserSelector()
            .selectUserByLastName(new List<String>{ Test_DemandFunnelHelper.SDRLASTNAME })
            .executeQuery()[0];

        Lead ld = (Lead) new SObjectBuilder(Lead.SObjectType)
            .setField(Lead.LastName, Test_DemandFunnelHelper.LEADLASTNAME)
            .setField(Lead.Status, LeadTriggerHelper.LEADSTATUSNEW)
            .setField(Lead.Email, testEmail)
            .setField(Lead.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Lead.LeadSource, Test_DemandFunnelHelper.LEADSOURCE)
            .setField(Lead.OwnerId, sysUser.Id)
            .createAsUser(sysUser)
            .getRecord();

        Test.startTest();
        ld.OwnerId = sdrUser.Id;
        update ld;
        Test.stopTest();

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRS(
            ld,
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
                'Prospect_Owner_Name__c',
                'Prospect_Owner_Team__c',
                'MQL_Owner_Name__c',
                'TAL_Owner_Name__c',
                'TAL_Owner_Team__c'
            }
        );

        System.assertEquals('Active', dfrList[0].DFR_Active_Status__c, 'DFR_Active_Status__c incorrect value');
        System.assertEquals(
            Test_DemandFunnelHelper.MQLFUNNELSTATUS,
            dfrList[0].DET_Current_Funnel_Status__c,
            'DET_Current_Funnel_Status__c incorrect value'
        );
        System.assertEquals(Test_DemandFunnelHelper.SDRTEAM, dfrList[0].Prospect_Owner_Team__c, 'Prospect_Owner_Team__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.SDRLASTNAME, dfrList[0].Prospect_Owner_Name__c, 'Prospect_Owner_Name__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.SDRTEAM, dfrList[0].MQL_Owner_Team__c, 'MQL_Owner_Team__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.SDRLASTNAME, dfrList[0].MQL_Owner_Name__c, 'MQL_Owner_Name__c incorrect value');
        System.assertEquals(null, dfrList[0].TAL_Owner_Team__c, 'TAL_Owner_Team__c incorrect value');
        System.assertEquals(null, dfrList[0].TAL_Owner_Name__c, 'TAL_Owner_Name__c incorrect value');
        System.assertEquals(
            Test_DemandFunnelHelper.BACKFILLED,
            dfrList[0].Prospect_Entered_From__c,
            'Prospect_Entered_From__c incorrect value'
        );
        System.assertEquals(Test_DemandFunnelHelper.BACKFILLED, dfrList[0].Prospect_Exited_To__c, 'Prospect_Exited_To__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.CREATED, dfrList[0].MQL_Entered_From__c, 'MQL_Entered_From__c incorrect value');
        System.assertEquals(null, dfrList[0].MQL_Exited_To__c, 'MQL_Exited_To__c incorrect value');
        System.assertEquals(null, dfrList[0].TAL_Entered_From__c, 'TAL_Entered_From__c incorrect value');
        System.assertEquals(null, dfrList[0].TAL_Exited_To__c, 'TAL_Exited_To__c incorrect value');
        System.assertEquals(null, dfrList[0].SAL_Entered_From__c, 'SAL_Entered_From__c incorrect value');
        System.assertEquals(null, dfrList[0].SAL_Exited_To__c, 'SAL_Exited_To__c incorrect value');
        System.assertEquals(null, dfrList[0].EOL_Entered_From__c, 'EOL_Entered_From__c incorrect value');
    }

    //Test CRM-21449
    @isTest
    static void testChangeOwnerFromSysUserSDRToAENew() {
        User sysUser = Test_DemandFunnelHelper.getSystemUser();
        sysUser.Team__c = Test_DemandFunnelHelper.SDRTEAM;
        User aeUser = (User) new UserSelector().selectUserByLastName(new List<String>{ Test_DemandFunnelHelper.AELASTNAME }).executeQuery()[0];

        Lead ld = (Lead) new SObjectBuilder(Lead.SObjectType)
            .setField(Lead.LastName, Test_DemandFunnelHelper.LEADLASTNAME)
            .setField(Lead.Status, LeadTriggerHelper.LEADSTATUSNEW)
            .setField(Lead.Email, testEmail)
            .setField(Lead.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Lead.LeadSource, Test_DemandFunnelHelper.LEADSOURCE)
            .setField(Lead.OwnerId, sysUser.Id)
            .createAsUser(sysUser)
            .getRecord();

        Test.startTest();
        ld.OwnerId = aeUser.Id;
        update ld;
        Test.stopTest();

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRS(
            ld,
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
                'EOL_Entered_From__c'
            }
        );
        System.assertEquals('Active', dfrList[0].DFR_Active_Status__c, 'DFR_Active_Status__c incorrect value');
        System.assertEquals(
            Test_DemandFunnelHelper.MQLFUNNELSTATUS,
            dfrList[0].DET_Current_Funnel_Status__c,
            'DET_Current_Funnel_Status__c incorrect value'
        );
        System.assertEquals(Test_DemandFunnelHelper.AETEAM, dfrList[0].MQL_Owner_Team__c, 'MQL_Owner_Team__c incorrect value');
        System.assertEquals(
            Test_DemandFunnelHelper.BACKFILLED,
            dfrList[0].Prospect_Entered_From__c,
            'Prospect_Entered_From__c incorrect value'
        );
        System.assertEquals(Test_DemandFunnelHelper.BACKFILLED, dfrList[0].Prospect_Exited_To__c, 'Prospect_Exited_To__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.CREATED, dfrList[0].MQL_Entered_From__c, 'MQL_Entered_From__c incorrect value');
        System.assertEquals(null, dfrList[0].MQL_Exited_To__c, 'MQL_Exited_To__c incorrect value');
        System.assertEquals(null, dfrList[0].TAL_Entered_From__c, 'TAL_Entered_From__c incorrect value');
        System.assertEquals(null, dfrList[0].TAL_Exited_To__c, 'TAL_Exited_To__c incorrect value');
        System.assertEquals(null, dfrList[0].SAL_Entered_From__c, 'SAL_Entered_From__c incorrect value');
        System.assertEquals(null, dfrList[0].SAL_Exited_To__c, 'SAL_Exited_To__c incorrect value');
        System.assertEquals(null, dfrList[0].EOL_Entered_From__c, 'EOL_Entered_From__c incorrect value');
    }

    //Test CRM-21448
    @isTest
    static void testChangeOwnerFromSysUserSDRToSDRReNew() {
        User sysUser = Test_DemandFunnelHelper.getSystemUser();
        sysUser.Team__c = Test_DemandFunnelHelper.SDRTEAM;
        User sdrUser = (User) new UserSelector()
            .selectUserByLastName(new List<String>{ Test_DemandFunnelHelper.SDRLASTNAME })
            .executeQuery()[0];

        Lead ld = (Lead) new SObjectBuilder(Lead.SObjectType)
            .setField(Lead.LastName, Test_DemandFunnelHelper.LEADLASTNAME)
            .setField(Lead.Status, LeadTriggerHelper.LEADSTATUSRENEW)
            .setField(Lead.Email, testEmail)
            .setField(Lead.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Lead.LeadSource, Test_DemandFunnelHelper.LEADSOURCE)
            .setField(Lead.OwnerId, sysUser.Id)
            .createAsUser(sysUser)
            .getRecord();

        Test.startTest();
        ld.OwnerId = sdrUser.Id;
        update ld;
        Test.stopTest();

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRS(
            ld,
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
                'Prospect_Owner_Name__c',
                'Prospect_Owner_Team__c',
                'MQL_Owner_Name__c',
                'TAL_Owner_Name__c',
                'TAL_Owner_Team__c'
            }
        );

        System.assertEquals('Active', dfrList[0].DFR_Active_Status__c, 'DFR_Active_Status__c incorrect value');
        System.assertEquals(
            Test_DemandFunnelHelper.MQLFUNNELSTATUS,
            dfrList[0].DET_Current_Funnel_Status__c,
            'DET_Current_Funnel_Status__c incorrect value'
        );
        System.assertEquals(Test_DemandFunnelHelper.SDRTEAM, dfrList[0].Prospect_Owner_Team__c, 'Prospect_Owner_Team__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.SDRLASTNAME, dfrList[0].Prospect_Owner_Name__c, 'Prospect_Owner_Name__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.SDRTEAM, dfrList[0].MQL_Owner_Team__c, 'MQL_Owner_Team__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.SDRLASTNAME, dfrList[0].MQL_Owner_Name__c, 'MQL_Owner_Name__c incorrect value');
        System.assertEquals(null, dfrList[0].TAL_Owner_Team__c, 'TAL_Owner_Team__c incorrect value');
        System.assertEquals(null, dfrList[0].TAL_Owner_Name__c, 'TAL_Owner_Name__c incorrect value');
        System.assertEquals(
            Test_DemandFunnelHelper.BACKFILLED,
            dfrList[0].Prospect_Entered_From__c,
            'Prospect_Entered_From__c incorrect value'
        );
        System.assertEquals(Test_DemandFunnelHelper.BACKFILLED, dfrList[0].Prospect_Exited_To__c, 'Prospect_Exited_To__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.CREATED, dfrList[0].MQL_Entered_From__c, 'MQL_Entered_From__c incorrect value');
        System.assertEquals(null, dfrList[0].MQL_Exited_To__c, 'MQL_Exited_To__c incorrect value');
        System.assertEquals(null, dfrList[0].TAL_Entered_From__c, 'TAL_Entered_From__c incorrect value');
        System.assertEquals(null, dfrList[0].TAL_Exited_To__c, 'TAL_Exited_To__c incorrect value');
        System.assertEquals(null, dfrList[0].SAL_Entered_From__c, 'SAL_Entered_From__c incorrect value');
        System.assertEquals(null, dfrList[0].SAL_Exited_To__c, 'SAL_Exited_To__c incorrect value');
        System.assertEquals(null, dfrList[0].EOL_Entered_From__c, 'EOL_Entered_From__c incorrect value');
    }

    //Test CRM-21450
    @isTest
    static void testChangeOwnerFromSysUserSDRToAEReNew() {
        User sysUser = Test_DemandFunnelHelper.getSystemUser();
        sysUser.Team__c = Test_DemandFunnelHelper.SDRTEAM;
        User aeUser = (User) new UserSelector().selectUserByLastName(new List<String>{ Test_DemandFunnelHelper.AELASTNAME }).executeQuery()[0];

        Lead ld = (Lead) new SObjectBuilder(Lead.SObjectType)
            .setField(Lead.LastName, Test_DemandFunnelHelper.LEADLASTNAME)
            .setField(Lead.Status, LeadTriggerHelper.LEADSTATUSRENEW)
            .setField(Lead.Email, testEmail)
            .setField(Lead.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Lead.LeadSource, Test_DemandFunnelHelper.LEADSOURCE)
            .setField(Lead.OwnerId, sysUser.Id)
            .createAsUser(sysUser)
            .getRecord();

        Test.startTest();
        ld.OwnerId = aeUser.Id;
        update ld;
        Test.stopTest();

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRS(
            ld,
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
                'EOL_Entered_From__c'
            }
        );
        System.assertEquals('Active', dfrList[0].DFR_Active_Status__c, 'DFR_Active_Status__c incorrect value');
        System.assertEquals(
            Test_DemandFunnelHelper.MQLFUNNELSTATUS,
            dfrList[0].DET_Current_Funnel_Status__c,
            'DET_Current_Funnel_Status__c incorrect value'
        );
        System.assertEquals(Test_DemandFunnelHelper.AETEAM, dfrList[0].MQL_Owner_Team__c, 'MQL_Owner_Team__c incorrect value');
        System.assertEquals(
            Test_DemandFunnelHelper.BACKFILLED,
            dfrList[0].Prospect_Entered_From__c,
            'Prospect_Entered_From__c incorrect value'
        );
        System.assertEquals(Test_DemandFunnelHelper.BACKFILLED, dfrList[0].Prospect_Exited_To__c, 'Prospect_Exited_To__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.CREATED, dfrList[0].MQL_Entered_From__c, 'MQL_Entered_From__c incorrect value');
        System.assertEquals(null, dfrList[0].MQL_Exited_To__c, 'MQL_Exited_To__c incorrect value');
        System.assertEquals(null, dfrList[0].TAL_Entered_From__c, 'TAL_Entered_From__c incorrect value');
        System.assertEquals(null, dfrList[0].TAL_Exited_To__c, 'TAL_Exited_To__c incorrect value');
        System.assertEquals(null, dfrList[0].SAL_Entered_From__c, 'SAL_Entered_From__c incorrect value');
        System.assertEquals(null, dfrList[0].SAL_Exited_To__c, 'SAL_Exited_To__c incorrect value');
        System.assertEquals(null, dfrList[0].EOL_Entered_From__c, 'EOL_Entered_From__c incorrect value');
    }

    //Test CRM-21451
    @isTest
    static void testChangeOwnerFromSysUserSDRToSDROpen() {
        User sysUser = Test_DemandFunnelHelper.getSystemUser();
        sysUser.Team__c = Test_DemandFunnelHelper.SDRTEAM;
        User sdrUser = (User) new UserSelector()
            .selectUserByLastName(new List<String>{ Test_DemandFunnelHelper.SDRLASTNAME })
            .executeQuery()[0];

        Lead ld = (Lead) new SObjectBuilder(Lead.SObjectType)
            .setField(Lead.LastName, Test_DemandFunnelHelper.LEADLASTNAME)
            .setField(Lead.Status, LeadTriggerHelper.LEADSTATUSOPEN)
            .setField(Lead.Email, testEmail)
            .setField(Lead.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Lead.LeadSource, Test_DemandFunnelHelper.LEADSOURCE)
            .setField(Lead.OwnerId, sysUser.Id)
            .createAsUser(sysUser)
            .getRecord();

        Test.startTest();
        ld.OwnerId = sdrUser.Id;
        update ld;
        Test.stopTest();

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRS(
            ld,
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
                'Prospect_Owner_Name__c',
                'Prospect_Owner_Team__c',
                'MQL_Owner_Name__c',
                'TAL_Owner_Name__c',
                'TAL_Owner_Team__c'
            }
        );

        System.assertEquals('Active', dfrList[0].DFR_Active_Status__c, 'DFR_Active_Status__c incorrect value');
        System.assertEquals(
            Test_DemandFunnelHelper.PROSPECTFUNNELSTATUS,
            dfrList[0].DET_Current_Funnel_Status__c,
            'DET_Current_Funnel_Status__c incorrect value'
        );
        System.assertEquals(Test_DemandFunnelHelper.SDRTEAM, dfrList[0].Prospect_Owner_Team__c, 'Prospect_Owner_Team__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.SDRLASTNAME, dfrList[0].Prospect_Owner_Name__c, 'Prospect_Owner_Name__c incorrect value');
        System.assertEquals(null, dfrList[0].MQL_Owner_Team__c, 'MQL_Owner_Team__c incorrect value');
        System.assertEquals(null, dfrList[0].MQL_Owner_Name__c, 'MQL_Owner_Name__c incorrect value');
        System.assertEquals(null, dfrList[0].TAL_Owner_Team__c, 'TAL_Owner_Team__c incorrect value');
        System.assertEquals(null, dfrList[0].TAL_Owner_Name__c, 'TAL_Owner_Name__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.CREATED, dfrList[0].Prospect_Entered_From__c, 'Prospect_Entered_From__c incorrect value');
        System.assertEquals(null, dfrList[0].Prospect_Exited_To__c, 'Prospect_Exited_To__c incorrect value');
        System.assertEquals(null, dfrList[0].MQL_Entered_From__c, 'MQL_Entered_From__c incorrect value');
        System.assertEquals(null, dfrList[0].MQL_Exited_To__c, 'MQL_Exited_To__c incorrect value');
        System.assertEquals(null, dfrList[0].TAL_Entered_From__c, 'TAL_Entered_From__c incorrect value');
        System.assertEquals(null, dfrList[0].TAL_Exited_To__c, 'TAL_Exited_To__c incorrect value');
        System.assertEquals(null, dfrList[0].SAL_Entered_From__c, 'SAL_Entered_From__c incorrect value');
        System.assertEquals(null, dfrList[0].SAL_Exited_To__c, 'SAL_Exited_To__c incorrect value');
        System.assertEquals(null, dfrList[0].EOL_Entered_From__c, 'EOL_Entered_From__c incorrect value');
    }

    //Test CRM-21452
    @isTest
    static void testChangeOwnerFromSysUserSDRToAEOpen() {
        User sysUser = Test_DemandFunnelHelper.getSystemUser();
        sysUser.Team__c = Test_DemandFunnelHelper.SDRTEAM;
        User aeUser = (User) new UserSelector().selectUserByLastName(new List<String>{ Test_DemandFunnelHelper.AELASTNAME }).executeQuery()[0];

        Lead ld = (Lead) new SObjectBuilder(Lead.SObjectType)
            .setField(Lead.LastName, Test_DemandFunnelHelper.LEADLASTNAME)
            .setField(Lead.Status, LeadTriggerHelper.LEADSTATUSOPEN)
            .setField(Lead.Email, testEmail)
            .setField(Lead.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Lead.LeadSource, Test_DemandFunnelHelper.LEADSOURCE)
            .setField(Lead.OwnerId, sysUser.Id)
            .createAsUser(sysUser)
            .getRecord();

        Test.startTest();
        ld.OwnerId = aeUser.Id;
        update ld;
        Test.stopTest();

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRS(
            ld,
            new List<String>{
                'Prospect_Entered_From__c',
                'Prospect_Owner_Team__c',
                'Prospect_Owner_Name__c',
                'DFR_Active_Status__c',
                'MQL_Owner_Team__c',
                'Prospect_Exited_To__c',
                'MQL_Entered_From__c',
                'MQL_Exited_To__c',
                'TAL_Entered_From__c',
                'TAL_Exited_To__c',
                'SAL_Entered_From__c',
                'SAL_Exited_To__c',
                'EOL_Entered_From__c'
            }
        );
        System.assertEquals('Active', dfrList[0].DFR_Active_Status__c, 'DFR_Active_Status__c incorrect value');
        System.assertEquals(
            Test_DemandFunnelHelper.PROSPECTFUNNELSTATUS,
            dfrList[0].DET_Current_Funnel_Status__c,
            'DET_Current_Funnel_Status__c incorrect value'
        );
        System.assertEquals(Test_DemandFunnelHelper.AETEAM, dfrList[0].Prospect_Owner_Team__c, 'Prospect_Owner_Team__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.AELASTNAME, dfrList[0].Prospect_Owner_Name__c, 'Prospect_Owner_Name__c incorrect value');
        System.assertEquals(null, dfrList[0].MQL_Owner_Team__c, 'MQL_Owner_Team__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.CREATED, dfrList[0].Prospect_Entered_From__c, 'Prospect_Entered_From__c incorrect value');
        System.assertEquals(null, dfrList[0].Prospect_Exited_To__c, 'Prospect_Exited_To__c incorrect value');
        System.assertEquals(null, dfrList[0].MQL_Entered_From__c, 'MQL_Entered_From__c incorrect value');
        System.assertEquals(null, dfrList[0].MQL_Exited_To__c, 'MQL_Exited_To__c incorrect value');
        System.assertEquals(null, dfrList[0].TAL_Entered_From__c, 'TAL_Entered_From__c incorrect value');
        System.assertEquals(null, dfrList[0].TAL_Exited_To__c, 'TAL_Exited_To__c incorrect value');
        System.assertEquals(null, dfrList[0].SAL_Entered_From__c, 'SAL_Entered_From__c incorrect value');
        System.assertEquals(null, dfrList[0].SAL_Exited_To__c, 'SAL_Exited_To__c incorrect value');
        System.assertEquals(null, dfrList[0].EOL_Entered_From__c, 'EOL_Entered_From__c incorrect value');
    }

    //Test CRM-21453
    @isTest
    static void testChangeOwnerFromSysUserAEToSDRContacted() {
        User sysUser = Test_DemandFunnelHelper.getSystemUser();
        sysUser.Team__c = Test_DemandFunnelHelper.AETEAM;
        User sdrUser = (User) new UserSelector()
            .selectUserByLastName(new List<String>{ Test_DemandFunnelHelper.SDRLASTNAME })
            .executeQuery()[0];

        Lead ld = (Lead) new SObjectBuilder(Lead.SObjectType)
            .setField(Lead.LastName, Test_DemandFunnelHelper.LEADLASTNAME)
            .setField(Lead.Status, LeadTriggerHelper.LEADSTATUSCONTACTED)
            .setField(Lead.Email, testEmail)
            .setField(Lead.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Lead.LeadSource, Test_DemandFunnelHelper.LEADSOURCE)
            .setField(Lead.OwnerId, sysUser.Id)
            .createAsUser(sysUser)
            .getRecord();

        Test.startTest();
        ld.OwnerId = sdrUser.Id;
        update ld;
        Test.stopTest();

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRS(
            ld,
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
                'Prospect_Owner_Name__c',
                'Prospect_Owner_Team__c',
                'MQL_Owner_Name__c',
                'TAL_Owner_Name__c',
                'TAL_Owner_Team__c'
            }
        );

        System.assertEquals('Active', dfrList[0].DFR_Active_Status__c, 'DFR_Active_Status__c incorrect value');
        System.assertEquals(
            Test_DemandFunnelHelper.TALFUNNELSTATUS,
            dfrList[0].DET_Current_Funnel_Status__c,
            'DET_Current_Funnel_Status__c incorrect value'
        );
        System.assertEquals(Test_DemandFunnelHelper.SDRTEAM, dfrList[0].Prospect_Owner_Team__c, 'Prospect_Owner_Team__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.SDRLASTNAME, dfrList[0].Prospect_Owner_Name__c, 'Prospect_Owner_Name__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.SDRTEAM, dfrList[0].MQL_Owner_Team__c, 'MQL_Owner_Team__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.SDRLASTNAME, dfrList[0].MQL_Owner_Name__c, 'MQL_Owner_Name__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.SDRTEAM, dfrList[0].TAL_Owner_Team__c, 'TAL_Owner_Team__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.SDRLASTNAME, dfrList[0].TAL_Owner_Name__c, 'TAL_Owner_Name__c incorrect value');
        System.assertEquals(
            Test_DemandFunnelHelper.BACKFILLED,
            dfrList[0].Prospect_Entered_From__c,
            'Prospect_Entered_From__c incorrect value'
        );
        System.assertEquals(Test_DemandFunnelHelper.BACKFILLED, dfrList[0].Prospect_Exited_To__c, 'Prospect_Exited_To__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.BACKFILLED, dfrList[0].MQL_Entered_From__c, 'MQL_Entered_From__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.BACKFILLED, dfrList[0].MQL_Exited_To__c, 'MQL_Exited_To__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.CREATED, dfrList[0].TAL_Entered_From__c, 'TAL_Entered_From__c incorrect value');
        System.assertEquals(null, dfrList[0].TAL_Exited_To__c, 'TAL_Exited_To__c incorrect value');
        System.assertEquals(null, dfrList[0].SAL_Entered_From__c, 'SAL_Entered_From__c incorrect value');
        System.assertEquals(null, dfrList[0].SAL_Exited_To__c, 'SAL_Exited_To__c incorrect value');
        System.assertEquals(null, dfrList[0].EOL_Entered_From__c, 'EOL_Entered_From__c incorrect value');
    }

    //Test CRM-21454
    @isTest
    static void testChangeOwnerFromSysUserAEToAEContacted() {
        User sysUser = Test_DemandFunnelHelper.getSystemUser();
        sysUser.Team__c = Test_DemandFunnelHelper.AETEAM;
        User aeUser = (User) new UserSelector().selectUserByLastName(new List<String>{ Test_DemandFunnelHelper.AELASTNAME }).executeQuery()[0];

        Lead ld = (Lead) new SObjectBuilder(Lead.SObjectType)
            .setField(Lead.LastName, Test_DemandFunnelHelper.LEADLASTNAME)
            .setField(Lead.Status, LeadTriggerHelper.LEADSTATUSCONTACTED)
            .setField(Lead.Email, testEmail)
            .setField(Lead.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Lead.LeadSource, Test_DemandFunnelHelper.LEADSOURCE)
            .setField(Lead.OwnerId, sysUser.Id)
            .createAsUser(sysUser)
            .getRecord();

        Test.startTest();
        ld.OwnerId = aeUser.Id;
        update ld;
        Test.stopTest();

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRS(
            ld,
            new List<String>{
                'Prospect_Entered_From__c',
                'DFR_Active_Status__c',
                'MQL_Owner_Name__c',
                'Prospect_Owner_Name__c',
                'Prospect_Exited_To__c',
                'MQL_Entered_From__c',
                'MQL_Exited_To__c',
                'TAL_Entered_From__c',
                'TAL_Exited_To__c',
                'SAL_Entered_From__c',
                'SAL_Exited_To__c',
                'EOL_Entered_From__c'
            }
        );
        System.assertEquals('Active', dfrList[0].DFR_Active_Status__c, 'DFR_Active_Status__c incorrect value');
        System.assertEquals(
            Test_DemandFunnelHelper.SALFUNNELSTATUS,
            dfrList[0].DET_Current_Funnel_Status__c,
            'DET_Current_Funnel_Status__c incorrect value'
        );
        System.assertEquals(Test_DemandFunnelHelper.AELASTNAME, dfrList[0].Prospect_Owner_Name__c, 'Prospect_Owner_Name__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.AELASTNAME, dfrList[0].MQL_Owner_Name__c, 'MQL_Owner_name__c incorrect value');
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
        System.assertEquals(Test_DemandFunnelHelper.CREATED, dfrList[0].SAL_Entered_From__c, 'SAL_Entered_From__c incorrect value');
        System.assertEquals(null, dfrList[0].SAL_Exited_To__c, 'SAL_Exited_To__c incorrect value');
        System.assertEquals(null, dfrList[0].EOL_Entered_From__c, 'EOL_Entered_From__c incorrect value');
    }

    //Test CRM-21444
    @isTest
    static void testChangeOwnerFromSysUserAEToSDRCallout() {
        User sysUser = Test_DemandFunnelHelper.getSystemUser();
        sysUser.Team__c = Test_DemandFunnelHelper.AETEAM;
        User sdrUser = (User) new UserSelector()
            .selectUserByLastName(new List<String>{ Test_DemandFunnelHelper.SDRLASTNAME })
            .executeQuery()[0];

        Lead ld = (Lead) new SObjectBuilder(Lead.SObjectType)
            .setField(Lead.LastName, Test_DemandFunnelHelper.LEADLASTNAME)
            .setField(Lead.Status, LeadTriggerHelper.LEADSTATUSCALLOUT)
            .setField(Lead.Email, testEmail)
            .setField(Lead.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Lead.LeadSource, Test_DemandFunnelHelper.LEADSOURCE)
            .setField(Lead.OwnerId, sysUser.Id)
            .createAsUser(sysUser)
            .getRecord();

        Test.startTest();
        ld.OwnerId = sdrUser.Id;
        update ld;
        Test.stopTest();

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRS(
            ld,
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
                'Prospect_Owner_Name__c',
                'Prospect_Owner_Team__c',
                'MQL_Owner_Name__c',
                'TAL_Owner_Name__c',
                'TAL_Owner_Team__c'
            }
        );

        System.assertEquals('Active', dfrList[0].DFR_Active_Status__c, 'DFR_Active_Status__c incorrect value');
        System.assertEquals(
            Test_DemandFunnelHelper.TALFUNNELSTATUS,
            dfrList[0].DET_Current_Funnel_Status__c,
            'DET_Current_Funnel_Status__c incorrect value'
        );
        System.assertEquals(Test_DemandFunnelHelper.SDRTEAM, dfrList[0].Prospect_Owner_Team__c, 'Prospect_Owner_Team__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.SDRLASTNAME, dfrList[0].Prospect_Owner_Name__c, 'Prospect_Owner_Name__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.SDRTEAM, dfrList[0].MQL_Owner_Team__c, 'MQL_Owner_Team__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.SDRLASTNAME, dfrList[0].MQL_Owner_Name__c, 'MQL_Owner_Name__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.SDRTEAM, dfrList[0].TAL_Owner_Team__c, 'TAL_Owner_Team__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.SDRLASTNAME, dfrList[0].TAL_Owner_Name__c, 'TAL_Owner_Name__c incorrect value');
        System.assertEquals(
            Test_DemandFunnelHelper.BACKFILLED,
            dfrList[0].Prospect_Entered_From__c,
            'Prospect_Entered_From__c incorrect value'
        );
        System.assertEquals(Test_DemandFunnelHelper.BACKFILLED, dfrList[0].Prospect_Exited_To__c, 'Prospect_Exited_To__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.BACKFILLED, dfrList[0].MQL_Entered_From__c, 'MQL_Entered_From__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.BACKFILLED, dfrList[0].MQL_Exited_To__c, 'MQL_Exited_To__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.CREATED, dfrList[0].TAL_Entered_From__c, 'TAL_Entered_From__c incorrect value');
        System.assertEquals(null, dfrList[0].TAL_Exited_To__c, 'TAL_Exited_To__c incorrect value');
        System.assertEquals(null, dfrList[0].SAL_Entered_From__c, 'SAL_Entered_From__c incorrect value');
        System.assertEquals(null, dfrList[0].SAL_Exited_To__c, 'SAL_Exited_To__c incorrect value');
        System.assertEquals(null, dfrList[0].EOL_Entered_From__c, 'EOL_Entered_From__c incorrect value');
    }

    //Test CRM-21446
    @isTest
    static void testChangeOwnerFromSysUserAEToAECallout() {
        User sysUser = Test_DemandFunnelHelper.getSystemUser();
        sysUser.Team__c = Test_DemandFunnelHelper.AETEAM;
        User aeUser = (User) new UserSelector().selectUserByLastName(new List<String>{ Test_DemandFunnelHelper.AELASTNAME }).executeQuery()[0];

        Lead ld = (Lead) new SObjectBuilder(Lead.SObjectType)
            .setField(Lead.LastName, Test_DemandFunnelHelper.LEADLASTNAME)
            .setField(Lead.Status, LeadTriggerHelper.LEADSTATUSCALLOUT)
            .setField(Lead.Email, testEmail)
            .setField(Lead.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Lead.LeadSource, Test_DemandFunnelHelper.LEADSOURCE)
            .setField(Lead.OwnerId, sysUser.Id)
            .createAsUser(sysUser)
            .getRecord();

        Test.startTest();
        ld.OwnerId = aeUser.Id;
        update ld;
        Test.stopTest();

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRS(
            ld,
            new List<String>{
                'Prospect_Entered_From__c',
                'DFR_Active_Status__c',
                'MQL_Owner_Name__c',
                'Prospect_Exited_To__c',
                'Prospect_Owner_Name__c',
                'MQL_Entered_From__c',
                'MQL_Exited_To__c',
                'TAL_Entered_From__c',
                'TAL_Exited_To__c',
                'SAL_Entered_From__c',
                'SAL_Exited_To__c',
                'EOL_Entered_From__c'
            }
        );
        System.assertEquals('Active', dfrList[0].DFR_Active_Status__c, 'DFR_Active_Status__c incorrect value');
        System.assertEquals(
            Test_DemandFunnelHelper.SALFUNNELSTATUS,
            dfrList[0].DET_Current_Funnel_Status__c,
            'DET_Current_Funnel_Status__c incorrect value'
        );
        System.assertEquals(Test_DemandFunnelHelper.AELASTNAME, dfrList[0].Prospect_Owner_Name__c, 'Prospect_Owner_Name__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.AELASTNAME, dfrList[0].MQL_Owner_Name__c, 'MQL_Owner_Name__c incorrect value');
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
        System.assertEquals(Test_DemandFunnelHelper.CREATED, dfrList[0].SAL_Entered_From__c, 'SAL_Entered_From__c incorrect value');
        System.assertEquals(null, dfrList[0].SAL_Exited_To__c, 'SAL_Exited_To__c incorrect value');
        System.assertEquals(null, dfrList[0].EOL_Entered_From__c, 'EOL_Entered_From__c incorrect value');
    }

    //Test CRM-21457
    @isTest
    static void testChangeOwnerFromSysUserAEToSDRNew() {
        User sysUser = Test_DemandFunnelHelper.getSystemUser();
        sysUser.Team__c = Test_DemandFunnelHelper.AETEAM;
        User sdrUser = (User) new UserSelector()
            .selectUserByLastName(new List<String>{ Test_DemandFunnelHelper.SDRLASTNAME })
            .executeQuery()[0];

        Lead ld = (Lead) new SObjectBuilder(Lead.SObjectType)
            .setField(Lead.LastName, Test_DemandFunnelHelper.LEADLASTNAME)
            .setField(Lead.Status, LeadTriggerHelper.LEADSTATUSNEW)
            .setField(Lead.Email, testEmail)
            .setField(Lead.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Lead.LeadSource, Test_DemandFunnelHelper.LEADSOURCE)
            .setField(Lead.OwnerId, sysUser.Id)
            .createAsUser(sysUser)
            .getRecord();

        Test.startTest();
        ld.OwnerId = sdrUser.Id;
        update ld;
        Test.stopTest();

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRS(
            ld,
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
                'Prospect_Owner_Name__c',
                'Prospect_Owner_Team__c',
                'MQL_Owner_Name__c',
                'TAL_Owner_Name__c',
                'TAL_Owner_Team__c'
            }
        );

        System.assertEquals('Active', dfrList[0].DFR_Active_Status__c, 'DFR_Active_Status__c incorrect value');
        System.assertEquals(
            Test_DemandFunnelHelper.MQLFUNNELSTATUS,
            dfrList[0].DET_Current_Funnel_Status__c,
            'DET_Current_Funnel_Status__c incorrect value'
        );
        System.assertEquals(Test_DemandFunnelHelper.SDRTEAM, dfrList[0].Prospect_Owner_Team__c, 'Prospect_Owner_Team__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.SDRLASTNAME, dfrList[0].Prospect_Owner_Name__c, 'Prospect_Owner_Name__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.SDRTEAM, dfrList[0].MQL_Owner_Team__c, 'MQL_Owner_Team__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.SDRLASTNAME, dfrList[0].MQL_Owner_Name__c, 'MQL_Owner_Name__c incorrect value');
        System.assertEquals(null, dfrList[0].TAL_Owner_Team__c, 'TAL_Owner_Team__c incorrect value');
        System.assertEquals(null, dfrList[0].TAL_Owner_Name__c, 'TAL_Owner_Name__c incorrect value');
        System.assertEquals(
            Test_DemandFunnelHelper.BACKFILLED,
            dfrList[0].Prospect_Entered_From__c,
            'Prospect_Entered_From__c incorrect value'
        );
        System.assertEquals(Test_DemandFunnelHelper.BACKFILLED, dfrList[0].Prospect_Exited_To__c, 'Prospect_Exited_To__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.CREATED, dfrList[0].MQL_Entered_From__c, 'MQL_Entered_From__c incorrect value');
        System.assertEquals(null, dfrList[0].MQL_Exited_To__c, 'MQL_Exited_To__c incorrect value');
        System.assertEquals(null, dfrList[0].TAL_Entered_From__c, 'TAL_Entered_From__c incorrect value');
        System.assertEquals(null, dfrList[0].TAL_Exited_To__c, 'TAL_Exited_To__c incorrect value');
        System.assertEquals(null, dfrList[0].SAL_Entered_From__c, 'SAL_Entered_From__c incorrect value');
        System.assertEquals(null, dfrList[0].SAL_Exited_To__c, 'SAL_Exited_To__c incorrect value');
        System.assertEquals(null, dfrList[0].EOL_Entered_From__c, 'EOL_Entered_From__c incorrect value');
    }

    //Test CRM-21458
    @isTest
    static void testChangeOwnerFromSysUserAEToAENew() {
        User sysUser = Test_DemandFunnelHelper.getSystemUser();
        sysUser.Team__c = Test_DemandFunnelHelper.AETEAM;
        User aeUser = (User) new UserSelector().selectUserByLastName(new List<String>{ Test_DemandFunnelHelper.AELASTNAME }).executeQuery()[0];

        Lead ld = (Lead) new SObjectBuilder(Lead.SObjectType)
            .setField(Lead.LastName, Test_DemandFunnelHelper.LEADLASTNAME)
            .setField(Lead.Status, LeadTriggerHelper.LEADSTATUSNEW)
            .setField(Lead.Email, testEmail)
            .setField(Lead.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Lead.LeadSource, Test_DemandFunnelHelper.LEADSOURCE)
            .setField(Lead.OwnerId, sysUser.Id)
            .createAsUser(sysUser)
            .getRecord();

        Test.startTest();
        ld.OwnerId = aeUser.Id;
        update ld;
        Test.stopTest();

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRS(
            ld,
            new List<String>{
                'Prospect_Entered_From__c',
                'DFR_Active_Status__c',
                'MQL_Owner_Name__c',
                'Prospect_Owner_Name__c',
                'Prospect_Exited_To__c',
                'MQL_Entered_From__c',
                'MQL_Exited_To__c',
                'TAL_Entered_From__c',
                'TAL_Exited_To__c',
                'SAL_Entered_From__c',
                'SAL_Exited_To__c',
                'EOL_Entered_From__c'
            }
        );
        System.assertEquals('Active', dfrList[0].DFR_Active_Status__c, 'DFR_Active_Status__c incorrect value');
        System.assertEquals(
            Test_DemandFunnelHelper.MQLFUNNELSTATUS,
            dfrList[0].DET_Current_Funnel_Status__c,
            'DET_Current_Funnel_Status__c incorrect value'
        );
        System.assertEquals(Test_DemandFunnelHelper.AELASTNAME, dfrList[0].Prospect_Owner_Name__c, 'Prospect_Owner_Name__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.AELASTNAME, dfrList[0].MQL_Owner_Name__c, 'MQL_Owner_Name__c incorrect value');
        System.assertEquals(
            Test_DemandFunnelHelper.BACKFILLED,
            dfrList[0].Prospect_Entered_From__c,
            'Prospect_Entered_From__c incorrect value'
        );
        System.assertEquals(Test_DemandFunnelHelper.BACKFILLED, dfrList[0].Prospect_Exited_To__c, 'Prospect_Exited_To__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.CREATED, dfrList[0].MQL_Entered_From__c, 'MQL_Entered_From__c incorrect value');
        System.assertEquals(null, dfrList[0].MQL_Exited_To__c, 'MQL_Exited_To__c incorrect value');
        System.assertEquals(null, dfrList[0].TAL_Entered_From__c, 'TAL_Entered_From__c incorrect value');
        System.assertEquals(null, dfrList[0].TAL_Exited_To__c, 'TAL_Exited_To__c incorrect value');
        System.assertEquals(null, dfrList[0].SAL_Entered_From__c, 'SAL_Entered_From__c incorrect value');
        System.assertEquals(null, dfrList[0].SAL_Exited_To__c, 'SAL_Exited_To__c incorrect value');
        System.assertEquals(null, dfrList[0].EOL_Entered_From__c, 'EOL_Entered_From__c incorrect value');
    }

    //Test CRM-21459
    @isTest
    static void testChangeOwnerFromSysUserAEToSDRReNew() {
        User sysUser = Test_DemandFunnelHelper.getSystemUser();
        sysUser.Team__c = Test_DemandFunnelHelper.AETEAM;
        User sdrUser = (User) new UserSelector()
            .selectUserByLastName(new List<String>{ Test_DemandFunnelHelper.SDRLASTNAME })
            .executeQuery()[0];

        Lead ld = (Lead) new SObjectBuilder(Lead.SObjectType)
            .setField(Lead.LastName, Test_DemandFunnelHelper.LEADLASTNAME)
            .setField(Lead.Status, LeadTriggerHelper.LEADSTATUSRENEW)
            .setField(Lead.Email, testEmail)
            .setField(Lead.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Lead.LeadSource, Test_DemandFunnelHelper.LEADSOURCE)
            .setField(Lead.OwnerId, sysUser.Id)
            .createAsUser(sysUser)
            .getRecord();

        Test.startTest();
        ld.OwnerId = sdrUser.Id;
        update ld;
        Test.stopTest();

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRS(
            ld,
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
                'Prospect_Owner_Name__c',
                'Prospect_Owner_Team__c',
                'MQL_Owner_Name__c',
                'TAL_Owner_Name__c',
                'TAL_Owner_Team__c'
            }
        );

        System.assertEquals('Active', dfrList[0].DFR_Active_Status__c, 'DFR_Active_Status__c incorrect value');
        System.assertEquals(
            Test_DemandFunnelHelper.MQLFUNNELSTATUS,
            dfrList[0].DET_Current_Funnel_Status__c,
            'DET_Current_Funnel_Status__c incorrect value'
        );
        System.assertEquals(Test_DemandFunnelHelper.SDRTEAM, dfrList[0].Prospect_Owner_Team__c, 'Prospect_Owner_Team__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.SDRLASTNAME, dfrList[0].Prospect_Owner_Name__c, 'Prospect_Owner_Name__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.SDRTEAM, dfrList[0].MQL_Owner_Team__c, 'MQL_Owner_Team__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.SDRLASTNAME, dfrList[0].MQL_Owner_Name__c, 'MQL_Owner_Name__c incorrect value');
        System.assertEquals(null, dfrList[0].TAL_Owner_Team__c, 'TAL_Owner_Team__c incorrect value');
        System.assertEquals(null, dfrList[0].TAL_Owner_Name__c, 'TAL_Owner_Name__c incorrect value');
        System.assertEquals(
            Test_DemandFunnelHelper.BACKFILLED,
            dfrList[0].Prospect_Entered_From__c,
            'Prospect_Entered_From__c incorrect value'
        );
        System.assertEquals(Test_DemandFunnelHelper.BACKFILLED, dfrList[0].Prospect_Exited_To__c, 'Prospect_Exited_To__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.CREATED, dfrList[0].MQL_Entered_From__c, 'MQL_Entered_From__c incorrect value');
        System.assertEquals(null, dfrList[0].MQL_Exited_To__c, 'MQL_Exited_To__c incorrect value');
        System.assertEquals(null, dfrList[0].TAL_Entered_From__c, 'TAL_Entered_From__c incorrect value');
        System.assertEquals(null, dfrList[0].TAL_Exited_To__c, 'TAL_Exited_To__c incorrect value');
        System.assertEquals(null, dfrList[0].SAL_Entered_From__c, 'SAL_Entered_From__c incorrect value');
        System.assertEquals(null, dfrList[0].SAL_Exited_To__c, 'SAL_Exited_To__c incorrect value');
        System.assertEquals(null, dfrList[0].EOL_Entered_From__c, 'EOL_Entered_From__c incorrect value');
    }

    //Test CRM-21460
    @isTest
    static void testChangeOwnerFromSysUserAEToAEReNew() {
        User sysUser = Test_DemandFunnelHelper.getSystemUser();
        sysUser.Team__c = Test_DemandFunnelHelper.AETEAM;
        User aeUser = (User) new UserSelector().selectUserByLastName(new List<String>{ Test_DemandFunnelHelper.AELASTNAME }).executeQuery()[0];

        Lead ld = (Lead) new SObjectBuilder(Lead.SObjectType)
            .setField(Lead.LastName, Test_DemandFunnelHelper.LEADLASTNAME)
            .setField(Lead.Status, LeadTriggerHelper.LEADSTATUSRENEW)
            .setField(Lead.Email, testEmail)
            .setField(Lead.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Lead.LeadSource, Test_DemandFunnelHelper.LEADSOURCE)
            .setField(Lead.OwnerId, sysUser.Id)
            .createAsUser(sysUser)
            .getRecord();

        Test.startTest();
        ld.OwnerId = aeUser.Id;
        update ld;
        Test.stopTest();

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRS(
            ld,
            new List<String>{
                'Prospect_Entered_From__c',
                'DFR_Active_Status__c',
                'MQL_Owner_Name__c',
                'Prospect_Owner_Name__c',
                'Prospect_Exited_To__c',
                'MQL_Entered_From__c',
                'MQL_Exited_To__c',
                'TAL_Entered_From__c',
                'TAL_Exited_To__c',
                'SAL_Entered_From__c',
                'SAL_Exited_To__c',
                'EOL_Entered_From__c'
            }
        );
        System.assertEquals('Active', dfrList[0].DFR_Active_Status__c, 'DFR_Active_Status__c incorrect value');
        System.assertEquals(
            Test_DemandFunnelHelper.MQLFUNNELSTATUS,
            dfrList[0].DET_Current_Funnel_Status__c,
            'DET_Current_Funnel_Status__c incorrect value'
        );
        System.assertEquals(Test_DemandFunnelHelper.AELASTNAME, dfrList[0].Prospect_Owner_Name__c, 'Prospect_Owner_Name__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.AELASTNAME, dfrList[0].MQL_Owner_Name__c, 'MQL_Owner_Name__c incorrect value');
        System.assertEquals(
            Test_DemandFunnelHelper.BACKFILLED,
            dfrList[0].Prospect_Entered_From__c,
            'Prospect_Entered_From__c incorrect value'
        );
        System.assertEquals(Test_DemandFunnelHelper.BACKFILLED, dfrList[0].Prospect_Exited_To__c, 'Prospect_Exited_To__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.CREATED, dfrList[0].MQL_Entered_From__c, 'MQL_Entered_From__c incorrect value');
        System.assertEquals(null, dfrList[0].MQL_Exited_To__c, 'MQL_Exited_To__c incorrect value');
        System.assertEquals(null, dfrList[0].TAL_Entered_From__c, 'TAL_Entered_From__c incorrect value');
        System.assertEquals(null, dfrList[0].TAL_Exited_To__c, 'TAL_Exited_To__c incorrect value');
        System.assertEquals(null, dfrList[0].SAL_Entered_From__c, 'SAL_Entered_From__c incorrect value');
        System.assertEquals(null, dfrList[0].SAL_Exited_To__c, 'SAL_Exited_To__c incorrect value');
        System.assertEquals(null, dfrList[0].EOL_Entered_From__c, 'EOL_Entered_From__c incorrect value');
    }

    //Test CRM-21461
    @isTest
    static void testChangeOwnerFromSysUserAEToSDROpen() {
        User sysUser = Test_DemandFunnelHelper.getSystemUser();
        sysUser.Team__c = Test_DemandFunnelHelper.AETEAM;
        User sdrUser = (User) new UserSelector()
            .selectUserByLastName(new List<String>{ Test_DemandFunnelHelper.SDRLASTNAME })
            .executeQuery()[0];

        Lead ld = (Lead) new SObjectBuilder(Lead.SObjectType)
            .setField(Lead.LastName, Test_DemandFunnelHelper.LEADLASTNAME)
            .setField(Lead.Status, LeadTriggerHelper.LEADSTATUSOPEN)
            .setField(Lead.Email, testEmail)
            .setField(Lead.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Lead.LeadSource, Test_DemandFunnelHelper.LEADSOURCE)
            .setField(Lead.OwnerId, sysUser.Id)
            .createAsUser(sysUser)
            .getRecord();

        Test.startTest();
        ld.OwnerId = sdrUser.Id;
        update ld;
        Test.stopTest();

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRS(
            ld,
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
                'Prospect_Owner_Name__c',
                'Prospect_Owner_Team__c',
                'MQL_Owner_Name__c',
                'TAL_Owner_Name__c',
                'TAL_Owner_Team__c'
            }
        );

        System.assertEquals('Active', dfrList[0].DFR_Active_Status__c, 'DFR_Active_Status__c incorrect value');
        System.assertEquals(
            Test_DemandFunnelHelper.PROSPECTFUNNELSTATUS,
            dfrList[0].DET_Current_Funnel_Status__c,
            'DET_Current_Funnel_Status__c incorrect value'
        );
        System.assertEquals(Test_DemandFunnelHelper.SDRTEAM, dfrList[0].Prospect_Owner_Team__c, 'Prospect_Owner_Team__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.SDRLASTNAME, dfrList[0].Prospect_Owner_Name__c, 'Prospect_Owner_Name__c incorrect value');
        System.assertEquals(null, dfrList[0].MQL_Owner_Team__c, 'MQL_Owner_Team__c incorrect value');
        System.assertEquals(null, dfrList[0].MQL_Owner_Name__c, 'MQL_Owner_Name__c incorrect value');
        System.assertEquals(null, dfrList[0].TAL_Owner_Team__c, 'TAL_Owner_Team__c incorrect value');
        System.assertEquals(null, dfrList[0].TAL_Owner_Name__c, 'TAL_Owner_Name__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.CREATED, dfrList[0].Prospect_Entered_From__c, 'Prospect_Entered_From__c incorrect value');
        System.assertEquals(null, dfrList[0].Prospect_Exited_To__c, 'Prospect_Exited_To__c incorrect value');
        System.assertEquals(null, dfrList[0].MQL_Entered_From__c, 'MQL_Entered_From__c incorrect value');
        System.assertEquals(null, dfrList[0].MQL_Exited_To__c, 'MQL_Exited_To__c incorrect value');
        System.assertEquals(null, dfrList[0].TAL_Entered_From__c, 'TAL_Entered_From__c incorrect value');
        System.assertEquals(null, dfrList[0].TAL_Exited_To__c, 'TAL_Exited_To__c incorrect value');
        System.assertEquals(null, dfrList[0].SAL_Entered_From__c, 'SAL_Entered_From__c incorrect value');
        System.assertEquals(null, dfrList[0].SAL_Exited_To__c, 'SAL_Exited_To__c incorrect value');
        System.assertEquals(null, dfrList[0].EOL_Entered_From__c, 'EOL_Entered_From__c incorrect value');
    }

    //Test CRM-21462
    @isTest
    static void testChangeOwnerFromSysUserAEToAEOpen() {
        User sysUser = Test_DemandFunnelHelper.getSystemUser();
        sysUser.Team__c = Test_DemandFunnelHelper.AETEAM;
        User aeUser = (User) new UserSelector().selectUserByLastName(new List<String>{ Test_DemandFunnelHelper.AELASTNAME }).executeQuery()[0];

        Lead ld = (Lead) new SObjectBuilder(Lead.SObjectType)
            .setField(Lead.LastName, Test_DemandFunnelHelper.LEADLASTNAME)
            .setField(Lead.Status, LeadTriggerHelper.LEADSTATUSOPEN)
            .setField(Lead.Email, testEmail)
            .setField(Lead.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Lead.LeadSource, Test_DemandFunnelHelper.LEADSOURCE)
            .setField(Lead.OwnerId, sysUser.Id)
            .createAsUser(sysUser)
            .getRecord();

        Test.startTest();
        ld.OwnerId = aeUser.Id;
        update ld;
        Test.stopTest();

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRS(
            ld,
            new List<String>{
                'Prospect_Entered_From__c',
                'Prospect_Owner_Name__c',
                'DFR_Active_Status__c',
                'MQL_Owner_Name__c',
                'Prospect_Exited_To__c',
                'MQL_Entered_From__c',
                'MQL_Exited_To__c',
                'TAL_Entered_From__c',
                'TAL_Exited_To__c',
                'SAL_Entered_From__c',
                'SAL_Exited_To__c',
                'EOL_Entered_From__c'
            }
        );
        System.assertEquals('Active', dfrList[0].DFR_Active_Status__c, 'DFR_Active_Status__c incorrect value');
        System.assertEquals(
            Test_DemandFunnelHelper.PROSPECTFUNNELSTATUS,
            dfrList[0].DET_Current_Funnel_Status__c,
            'DET_Current_Funnel_Status__c incorrect value'
        );
        System.assertEquals(Test_DemandFunnelHelper.AELASTNAME, dfrList[0].Prospect_Owner_Name__c, 'Prospect_Owner_Name__c incorrect value');
        System.assertEquals(null, dfrList[0].MQL_Owner_Name__c, 'MQL_Owner_Name__c incorrect value');
        System.assertEquals(null, dfrList[0].MQL_Owner_Team__c, 'MQL_Owner_Team__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.CREATED, dfrList[0].Prospect_Entered_From__c, 'Prospect_Entered_From__c incorrect value');
        System.assertEquals(null, dfrList[0].Prospect_Exited_To__c, 'Prospect_Exited_To__c incorrect value');
        System.assertEquals(null, dfrList[0].MQL_Entered_From__c, 'MQL_Entered_From__c incorrect value');
        System.assertEquals(null, dfrList[0].MQL_Exited_To__c, 'MQL_Exited_To__c incorrect value');
        System.assertEquals(null, dfrList[0].TAL_Entered_From__c, 'TAL_Entered_From__c incorrect value');
        System.assertEquals(null, dfrList[0].TAL_Exited_To__c, 'TAL_Exited_To__c incorrect value');
        System.assertEquals(null, dfrList[0].SAL_Entered_From__c, 'SAL_Entered_From__c incorrect value');
        System.assertEquals(null, dfrList[0].SAL_Exited_To__c, 'SAL_Exited_To__c incorrect value');
        System.assertEquals(null, dfrList[0].EOL_Entered_From__c, 'EOL_Entered_From__c incorrect value');
    }

    @isTest
    static void testAfterLeanDataContactedSDRUser() {
        User sysUser = Test_DemandFunnelHelper.getSystemUser();
        User sdrUser = (User) new UserSelector()
            .selectUserByLastName(new List<String>{ Test_DemandFunnelHelper.SDRLASTNAME })
            .executeQuery()[0];
        User aeUser = (User) new UserSelector().selectUserByLastName(new List<String>{ Test_DemandFunnelHelper.AELASTNAME }).executeQuery()[0];

        User otherAEUser = (User) new SObjectBuilder(User.SObjectType)
            .setField(User.Username, 'otheraeuser@test.com')
            .setField(User.Email, Test_DemandFunnelHelper.AELASTNAME + testEmail)
            .setField(User.LastName, Test_DemandFunnelHelper.AELASTNAME)
            .setField(User.CommunityNickname, 'testAE')
            .setField(User.Team__c, Test_DemandFunnelHelper.AETEAM)
            .create()
            .getRecord();

        Lead ld = (Lead) new SObjectBuilder(Lead.SObjectType)
            .setField(Lead.LastName, Test_DemandFunnelHelper.LEADLASTNAME + 'SantiTest')
            .setField(Lead.Status, LeadTriggerHelper.LEADSTATUSCONTACTED)
            .setField(Lead.Email, testEmail)
            .setField(Lead.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Lead.LeadSource, Test_DemandFunnelHelper.LEADSOURCE)
            .setField(Lead.OwnerId, sysUser.Id)
            .setField(Lead.Routing_Reason__c, DG_DFR_Class.REROUTED_MARKETO_MQL_STATUS_UPDATE)
            .createAsUser(sysUser)
            .getRecord();

        Test.startTest();
        ld.OwnerId = sdrUser.Id;
        update ld;
        ld.OwnerId = otherAEUser.Id;
        update ld;
        ld.OwnerId = aeUser.Id;
        update ld;
        ld.Routing_Reason__c = 'someRoutingReason';
        update ld;
        Test.stopTest();

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRS(
            ld,
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
                'EOL_Entered_From__c'
            }
        );
        System.assertEquals('Active', dfrList[0].DFR_Active_Status__c, 'DFR_Active_Status__c incorrect value');
        System.assertEquals(
            Test_DemandFunnelHelper.SALFUNNELSTATUS,
            dfrList[0].DET_Current_Funnel_Status__c,
            'DET_Current_Funnel_Status__c incorrect value'
        );
        System.assertEquals(Test_DemandFunnelHelper.AETEAM, dfrList[0].MQL_Owner_Team__c, 'MQL_Owner_Team__c incorrect value');
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
        System.assertEquals(Test_DemandFunnelHelper.CREATED, dfrList[0].SAL_Entered_From__c, 'SAL_Entered_From__c incorrect value');
        System.assertEquals(null, dfrList[0].SAL_Exited_To__c, 'SAL_Exited_To__c incorrect value');
        System.assertEquals(null, dfrList[0].EOL_Entered_From__c, 'EOL_Entered_From__c incorrect value');
    }

    @isTest
    static void testAfterLeanDataContactedAEUser() {
        User sysUser = Test_DemandFunnelHelper.getSystemUser();
        User sdrUser = (User) new UserSelector()
            .selectUserByLastName(new List<String>{ Test_DemandFunnelHelper.SDRLASTNAME })
            .executeQuery()[0];
        User aeUser = (User) new UserSelector().selectUserByLastName(new List<String>{ Test_DemandFunnelHelper.AELASTNAME }).executeQuery()[0];

        Lead ld = (Lead) new SObjectBuilder(Lead.SObjectType)
            .setField(Lead.LastName, Test_DemandFunnelHelper.LEADLASTNAME)
            .setField(Lead.Status, LeadTriggerHelper.LEADSTATUSCONTACTED)
            .setField(Lead.Email, testEmail)
            .setField(Lead.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Lead.LeadSource, Test_DemandFunnelHelper.LEADSOURCE)
            .setField(Lead.OwnerId, sysUser.Id)
            .setField(Lead.Routing_Reason__c, DG_DFR_Class.REROUTED_MARKETO_MQL_STATUS_UPDATE)
            .createAsUser(sysUser)
            .getRecord();

        Test.startTest();        
        ld.OwnerId = aeUser.Id;
        update ld;
        ld.OwnerId = sdrUser.Id;
        update ld;
        ld.Routing_Reason__c = 'someRoutingReason';
        update ld;
        
        Test.stopTest();

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRS(
            ld,
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
                'EOL_Entered_From__c'
            }
        );

        System.assertEquals('Active', dfrList[0].DFR_Active_Status__c, 'DFR_Active_Status__c incorrect value');
        System.assertEquals(
            Test_DemandFunnelHelper.TALFUNNELSTATUS,
            dfrList[0].DET_Current_Funnel_Status__c,
            'DET_Current_Funnel_Status__c incorrect value'
        );
        System.assertEquals(Test_DemandFunnelHelper.SDRTEAM, dfrList[0].MQL_Owner_Team__c, 'MQL_Owner_Team__c incorrect value');
        System.assertEquals(
            Test_DemandFunnelHelper.BACKFILLED,
            dfrList[0].Prospect_Entered_From__c,
            'Prospect_Entered_From__c incorrect value'
        );
        System.assertEquals(Test_DemandFunnelHelper.BACKFILLED, dfrList[0].Prospect_Exited_To__c, 'Prospect_Exited_To__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.BACKFILLED, dfrList[0].MQL_Entered_From__c, 'MQL_Entered_From__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.BACKFILLED, dfrList[0].MQL_Exited_To__c, 'MQL_Exited_To__c incorrect value');
        System.assertEquals(Test_DemandFunnelHelper.CREATED, dfrList[0].TAL_Entered_From__c, 'TAL_Entered_From__c incorrect value');
        System.assertEquals(null, dfrList[0].TAL_Exited_To__c, 'TAL_Exited_To__c incorrect value');
        System.assertEquals(null, dfrList[0].SAL_Entered_From__c, 'SAL_Entered_From__c incorrect value');
        System.assertEquals(null, dfrList[0].SAL_Exited_To__c, 'SAL_Exited_To__c incorrect value');
        System.assertEquals(null, dfrList[0].EOL_Entered_From__c, 'EOL_Entered_From__c incorrect value');
    }

    //Test CRM-20919
    @isTest
    static void testDFRCreateLeadsInBulk() {
        Test.startTest();
        List<Lead> leads = (List<Lead>) new SObjectBuilder(Lead.SObjectType)
            .setField(Lead.LastName, Test_DemandFunnelHelper.LEADLASTNAME)
            .setField(Lead.Status, LeadTriggerHelper.LEADSTATUSCONTACTED)
            .setField(Lead.Email, testEmail)
            .setField(Lead.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Lead.LeadSource, Test_DemandFunnelHelper.LEADSOURCE)
            .quantity(40)
            .create()
            .getRecords();

        Test.stopTest();
        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRList(leads);
        System.assertEquals(leads.size(), dfrList.size(), 'Missing DFRS on creation');
    }

    //Test CRM-21739
    @isTest
    static void testDFRUpdateLeadsInBulk() {
        User aeUser = (User) new UserSelector().selectUserByLastName(new List<String>{ Test_DemandFunnelHelper.AELASTNAME }).executeQuery()[0];
        List<Lead> leads = (List<Lead>) new SObjectBuilder(Lead.SObjectType)
            .setField(Lead.LastName, Test_DemandFunnelHelper.LEADLASTNAME)
            .setField(Lead.Status, LeadTriggerHelper.LEADSTATUSSUSPECT)
            .setField(Lead.Email, testEmail)
            .setField(Lead.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Lead.LeadSource, Test_DemandFunnelHelper.LEADSOURCE)
            .setField(Lead.OwnerId, aeUser.Id)
            .quantity(20)
            .create()
            .getRecords();
        leads.addAll(
            (List<Lead>) new SObjectBuilder(Lead.SObjectType)
                .setField(Lead.LastName, Test_DemandFunnelHelper.LEADLASTNAME)
                .setField(Lead.Status, LeadTriggerHelper.LEADSTATUSSUSPECT)
                .setField(Lead.Email, testEmail)
                .setField(Lead.Phone, Test_DemandFunnelHelper.LEADPHONE)
                .setField(Lead.LeadSource, Test_DemandFunnelHelper.LEADSOURCE)
                .setField(Lead.OwnerId, aeUser.Id)
                .quantity(20)
                .create()
                .getRecords()
        );
        Test.getEventBus().deliver();

        Test.startTest();
        List<Lead> leadsToUpdate = new List<Lead>();
        for (Lead lead : leads) {
            lead.Status = LeadTriggerHelper.LEADSTATUSCONTACTED;
            leadsToUpdate.add(lead);
        }
        update leadsToUpdate;
        Test.stopTest();

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRList(leads);
        System.assertEquals(leads.size(), dfrList.size(), 'Missing DFRS on creation');
        System.assertEquals(Test_DemandFunnelHelper.SALFUNNELSTATUS, dfrList[0].DET_Current_Funnel_Status__c, 'Leads are not getting updated');
    }

    @isTest
    static void testTQLBulk() {
        User sdrUser = (User) new UserSelector()
            .selectUserByLastName(new List<String>{ Test_DemandFunnelHelper.SDRLASTNAME })
            .executeQuery()[0];
        User aeUser = (User) new UserSelector().selectUserByLastName(new List<String>{ Test_DemandFunnelHelper.AELASTNAME }).executeQuery()[0];
        List<Lead> leads = (List<Lead>) new SObjectBuilder(Lead.SObjectType)
            .setField(Lead.LastName, Test_DemandFunnelHelper.LEADLASTNAME)
            .setField(Lead.Status, LeadTriggerHelper.LEADSTATUSCONTACTED)
            .setField(Lead.Email, testEmail)
            .setField(Lead.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Lead.LeadSource, Test_DemandFunnelHelper.LEADSOURCE)
            .setField(Lead.OwnerId, sdrUser.Id)
            .quantity(55)
            .create()
            .getRecords();
        Test.startTest();
        List<Lead> leadsToUpdate = new List<Lead>();
        for (Lead lead : leads) {
            lead.OwnerId = aeUser.Id;
            leadsToUpdate.add(lead);
        }
        update leadsToUpdate;
        Test.stopTest();
        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRList(leads);
        System.assertEquals(leads.size(), dfrList.size(), 'Missing DFRS on creation');
        System.assertEquals(Test_DemandFunnelHelper.SALFUNNELSTATUS, dfrList[0].DET_Current_Funnel_Status__c, 'Leads are not getting updated');
    }

    @isTest
    static void testDemandFunnelTriggerByPassPositive() {
        User aeUser = (User) new UserSelector().selectUserByLastName(new List<String>{ Test_DemandFunnelHelper.AELASTNAME }).executeQuery()[0];
        ByPassTrigger__c bypassTrigger = ByPassTrigger__c.getInstance(UserInfo.getOrganizationId());
        bypassTrigger.Bypass_DemandFunnel_Trigger__c = true;
        upsert bypassTrigger;
        Lead ld = (Lead) new SObjectBuilder(Lead.SObjectType)
            .setField(Lead.OwnerId, aeUser.Id)
            .setField(Lead.Status, LeadTriggerHelper.LEADSTATUSOPEN)
            .setField(Lead.LastName, Test_DemandFunnelHelper.LEADLASTNAME)
            .setField(Lead.Email, testEmail)
            .setField(Lead.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Lead.LeadSource, Test_DemandFunnelHelper.LEADSOURCE)
            .create()
            .getRecord();

        test.startTest();
        ld.Status = LeadTriggerHelper.LEADSTATUSCONTACTED;
        update ld;
        test.stopTest();
        List<Exception_and_Notification_history__c> dfrFieldTrackingRecords = (List<Exception_and_notification_history__c>) new ExceptionAndNotificationHistorySelector()
            .selectExceptionAndNotificationHistorys()
            .executeQuery();
        System.assertEquals(
            0,
            dfrFieldTrackingRecords.size(),
            'Trigger its not beign bypassed, FieldTracking Records were created'
        );
    }

    @isTest
    static void testDemandFunnelTriggerByPassNegative() {
        User aeUser = (User) new UserSelector().selectUserByLastName(new List<String>{ Test_DemandFunnelHelper.AELASTNAME }).executeQuery()[0];
        ByPassTrigger__c bypassTrigger = ByPassTrigger__c.getInstance(UserInfo.getOrganizationId());
        bypassTrigger.Bypass_DemandFunnel_Trigger__c = false;
        upsert bypassTrigger;
        Lead ld = (Lead) new SObjectBuilder(Lead.SObjectType)
            .setField(Lead.OwnerId, aeUser.Id)
            .setField(Lead.Status, LeadTriggerHelper.LEADSTATUSOPEN)
            .setField(Lead.LastName, Test_DemandFunnelHelper.LEADLASTNAME)
            .setField(Lead.Email, testEmail)
            .setField(Lead.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Lead.LeadSource, Test_DemandFunnelHelper.LEADSOURCE)
            .create()
            .getRecord();

        test.startTest();
        ld.Status = LeadTriggerHelper.LEADSTATUSCONTACTED;
        update ld;
        test.stopTest();
        List<Exception_and_Notification_history__c> dfrFieldTrackingRecords = (List<Exception_and_notification_history__c>) new ExceptionAndNotificationHistorySelector()
            .selectExceptionAndNotificationHistorys()
            .executeQuery();
        System.assertEquals(
            1,
            dfrFieldTrackingRecords.size(),
            'Trigger its beign bypassed, FieldTracking Records are not created'
        );
    }

    @isTest
    static void leadStatusChange_Downgraded_to_Contacted_MQLTypeShouldBeReNew() {
        User aeUser = (User) new UserSelector().selectUserByLastName(new List<String>{ Test_DemandFunnelHelper.AELASTNAME }).executeQuery()[0];
        ByPassTrigger__c bypassTrigger = ByPassTrigger__c.getInstance(UserInfo.getOrganizationId());
        bypassTrigger.Bypass_DemandFunnel_Trigger__c = false;
        upsert bypassTrigger;
        Lead ld = (Lead) new SObjectBuilder(Lead.SObjectType)
            .setField(Lead.OwnerId, aeUser.Id)
            .setField(Lead.Status, LeadTriggerHelper.LEADSTATUSDOWNGRADED)
            .setField(Lead.Downgrade_Reason__c, 'AT&T Seller')
            .setField(Lead.Sub_Downgrade_Reason__c, 'AT&T')
            .setField(Lead.LastName, Test_DemandFunnelHelper.LEADLASTNAME)
            .setField(Lead.Email, testEmail)
            .setField(Lead.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Lead.LeadSource, Test_DemandFunnelHelper.LEADSOURCE)
            .create()
            .getRecord();

        test.startTest();
        ld.Status = LeadTriggerHelper.LEADSTATUSCONTACTED;
        update ld;
        test.stopTest();

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRS(ld, new List<String>{ 'MQL_Type__c' });

        System.assertEquals(Test_DemandFunnelHelper.RENEW, dfrList[0].MQL_Type__c, 'MQL_Type__c should be Re-New');
    }

    @isTest
    static void populateActivityFieldsByTaskInsertOnLead() {
        Lead ld = (Lead) new SObjectBuilder(Lead.SObjectType)
            .setField(Lead.Status, LeadTriggerHelper.LEADSTATUSNEW)
            .setField(Lead.LastName, Test_DemandFunnelHelper.LEADLASTNAME)
            .setField(Lead.Email, testEmail)
            .setField(Lead.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Lead.LeadSource, Test_DemandFunnelHelper.LEADSOURCE)
            .create()
            .getRecord();
        test.startTest();
        Task t = (Task) new SObjectBuilder(Task.SObjectType)
            .setField(Task.WhoId, ld.Id)
            .setField(Task.Subject, 'Call')
            .setField(Task.Status, 'Completed')
            .create()
            .getRecord();
        test.stopTest();

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRS(
            ld,
            new List<String>{
                'Lead__c',
                'First_Activity_ID_after_MQL__c',
                'First_Activity_DateTime_after_MQL__c',
                'First_Activity_Name_after_MQL__c'
            }
        );

        System.assertEquals(1, dfrList.size(), 'DFR creation failed');
        System.assertEquals(
            t.Id,
            dfrList[0].First_Activity_ID_after_MQL__c,
            'First_Activity_ID_after_MQL__c its not populated or Wrong Assignation'
        );
        System.assertNotEquals(
            null,
            dfrList[0].First_Activity_DateTime_after_MQL__c,
            'First_Activity_DateTime_after_MQL__c its not populated'
        );
        System.assertEquals(
            'Call',
            dfrList[0].First_Activity_Name_after_MQL__c,
            'First_Activity_Name_after_MQL__c its not populated or Wrong Assignation'
        );
    }

    @isTest
    static void populateActivityFieldsWrongSubjectTaskOnLead() {
        test.startTest();
        Lead ld = (Lead) new SObjectBuilder(Lead.SObjectType)
            .setField(Lead.Status, LeadTriggerHelper.LEADSTATUSNEW)
            .setField(Lead.LastName, Test_DemandFunnelHelper.LEADLASTNAME)
            .setField(Lead.Email, testEmail)
            .setField(Lead.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Lead.LeadSource, Test_DemandFunnelHelper.LEADSOURCE)
            .create()
            .getRecord();

        Task t = (Task) new SObjectBuilder(Task.SObjectType)
            .setField(Task.WhoId, ld.Id)
            .setField(Task.Subject, 'Export to vidReach')
            .setField(Task.Status, 'Completed')
            .create()
            .getRecord();
        test.stopTest();

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRS(
            ld,
            new List<String>{
                'Lead__c',
                'First_Activity_ID_after_MQL__c',
                'First_Activity_DateTime_after_MQL__c',
                'First_Activity_Name_after_MQL__c'
            }
        );

        System.assertEquals(1, dfrList.size(), 'DFR creation failed');
        System.assertEquals(
            null,
            dfrList[0].First_Activity_ID_after_MQL__c,
            'First_Activity_ID_after_MQL__c its populated'
        );
        System.assertEquals(
            null,
            dfrList[0].First_Activity_DateTime_after_MQL__c,
            'First_Activity_DateTime_after_MQL__c its  populated'
        );
        System.assertEquals(
            null,
            dfrList[0].First_Activity_Name_after_MQL__c,
            'First_Activity_Name_after_MQL__c its populated'
        );
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void populateActivityFieldsByTaskInsertOnLeadSAL() {
        User aeUser = (User) new UserSelector().selectUserByLastName(new List<String>{ Test_DemandFunnelHelper.AELASTNAME }).executeQuery()[0];

        test.startTest();
        Lead ld = (Lead) new SObjectBuilder(Lead.SObjectType)
            .setField(Lead.Status, LeadTriggerHelper.LEADSTATUSCONTACTED)
            .setField(Lead.LastName, Test_DemandFunnelHelper.LEADLASTNAME)
            .setField(Lead.Email, testEmail)
            .setField(Lead.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Lead.OwnerId, aeUser.Id)
            .setField(Lead.LeadSource, Test_DemandFunnelHelper.LEADSOURCE)
            .create()
            .getRecord();

        Task t = (Task) new SObjectBuilder(Task.SObjectType)
            .setField(Task.WhoId, ld.Id)
            .setField(Task.Subject, 'test Task')
            .setField(Task.Status, 'Completed')
            .create()
            .getRecord();
        test.stopTest();

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRS(
            ld,
            new List<String>{
                'Lead__c',
                'First_Activity_ID_after_MQL__c',
                'First_Activity_DateTime_after_MQL__c',
                'First_Activity_Name_after_MQL__c'
            }
        );

        /*System.assertEquals(1, dfrList.size(), 'DFR creation failed');
        System.assertEquals(
            null,
            dfrList[0].First_Activity_ID_after_MQL__c,
            'First_Activity_ID_after_MQL__c its populated'
        );
        System.assertEquals(
            null,
            dfrList[0].First_Activity_DateTime_after_MQL__c,
            'First_Activity_DateTime_after_MQL__c its  populated'
        );
        System.assertEquals(
            null,
            dfrList[0].First_Activity_Name_after_MQL__c,
            'First_Activity_Name_after_MQL__c its populated'
        );*/
    }

    @isTest
    static void populateActivityFieldsInProgressStatusTaskOnLead() {
        test.startTest();
        Lead ld = (Lead) new SObjectBuilder(Lead.SObjectType)
            .setField(Lead.Status, LeadTriggerHelper.LEADSTATUSNEW)
            .setField(Lead.LastName, Test_DemandFunnelHelper.LEADLASTNAME)
            .setField(Lead.Email, testEmail)
            .setField(Lead.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Lead.LeadSource, Test_DemandFunnelHelper.LEADSOURCE)
            .create()
            .getRecord();

        Task t = (Task) new SObjectBuilder(Task.SObjectType)
            .setField(Task.WhoId, ld.Id)
            .setField(Task.Subject, 'Call')
            .setField(Task.Status, 'In Progress')
            .create()
            .getRecord();
        test.stopTest();
        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRS(
            ld,
            new List<String>{
                'Lead__c',
                'First_Activity_ID_after_MQL__c',
                'First_Activity_DateTime_after_MQL__c',
                'First_Activity_Name_after_MQL__c'
            }
        );

        System.assertEquals(1, dfrList.size(), 'DFR creation failed');
        System.assertEquals(
            null,
            dfrList[0].First_Activity_ID_after_MQL__c,
            'First_Activity_ID_after_MQL__c its populated'
        );
        System.assertEquals(
            null,
            dfrList[0].First_Activity_DateTime_after_MQL__c,
            'First_Activity_DateTime_after_MQL__c its  populated'
        );
        System.assertEquals(
            null,
            dfrList[0].First_Activity_Name_after_MQL__c,
            'First_Activity_Name_after_MQL__c its populated'
        );
    }

    // @isTest
    // static void populateActivityFieldsByEventInsertOnLead() {
    //     test.startTest();
    //     Lead ld = (Lead) new SObjectBuilder(Lead.SObjectType)
    //         .setField(Lead.Status, LeadTriggerHelper.LEADSTATUSNEW)
    //         .setField(Lead.LastName, Test_DemandFunnelHelper.LEADLASTNAME)
    //         .setField(Lead.Email, testEmail)
    //         .setField(Lead.Phone, Test_DemandFunnelHelper.LEADPHONE)
    //         .setField(Lead.LeadSource, Test_DemandFunnelHelper.LEADSOURCE)
    //         .create()
    //         .getRecord();

    //     Event t = (Event) new SObjectBuilder(Event.SObjectType)
    //         .setField(Event.WhoId, ld.Id)
    //         .setField(Event.Subject, 'Call')
    //         .setField(Event.DurationInMinutes, 20)
    //         .setField(Event.ActivityDateTime, System.now())
    //         .create()
    //         .getRecord();
    //     test.stopTest();

    //     List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRS(
    //         ld,
    //         new List<String>{
    //             'Lead__c',
    //             'First_Activity_ID_after_MQL__c',
    //             'First_Activity_DateTime_after_MQL__c',
    //             'First_Activity_Name_after_MQL__c'
    //         }
    //     );

    //     System.assertEquals(1, dfrList.size(), 'DFR creation failed');
    //     System.assertEquals(
    //         t.Id,
    //         dfrList[0].First_Activity_ID_after_MQL__c,
    //         'First_Activity_ID_after_MQL__c its not populated or Wrong Assignation'
    //     );
    //     System.assertNotEquals(
    //         null,
    //         dfrList[0].First_Activity_DateTime_after_MQL__c,
    //         'First_Activity_DateTime_after_MQL__c its not populated'
    //     );
    //     System.assertEquals(
    //         'Call',
    //         dfrList[0].First_Activity_Name_after_MQL__c,
    //         'First_Activity_Name_after_MQL__c its not populated or Wrong Assignation'
    //     );
    // }

    @isTest
    static void populateActivityFieldsWrongSubjectEventOnLead() {
        test.startTest();
        Lead ld = (Lead) new SObjectBuilder(Lead.SObjectType)
            .setField(Lead.Status, LeadTriggerHelper.LEADSTATUSNEW)
            .setField(Lead.LastName, Test_DemandFunnelHelper.LEADLASTNAME)
            .setField(Lead.Email, testEmail)
            .setField(Lead.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Lead.LeadSource, Test_DemandFunnelHelper.LEADSOURCE)
            .create()
            .getRecord();

        Event t = (Event) new SObjectBuilder(Event.SObjectType)
            .setField(Event.WhoId, ld.Id)
            .setField(Event.Subject, 'Export to vidReach')
            .setField(Event.DurationInMinutes, 20)
            .setField(Event.ActivityDateTime, System.now())
            .create()
            .getRecord();
        test.stopTest();

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRS(
            ld,
            new List<String>{
                'Lead__c',
                'First_Activity_ID_after_MQL__c',
                'First_Activity_DateTime_after_MQL__c',
                'First_Activity_Name_after_MQL__c'
            }
        );

        System.assertEquals(1, dfrList.size(), 'DFR creation failed');
        System.assertEquals(
            null,
            dfrList[0].First_Activity_ID_after_MQL__c,
            'First_Activity_ID_after_MQL__c its populated'
        );
        System.assertEquals(
            null,
            dfrList[0].First_Activity_DateTime_after_MQL__c,
            'First_Activity_DateTime_after_MQL__c its  populated'
        );
        System.assertEquals(
            null,
            dfrList[0].First_Activity_Name_after_MQL__c,
            'First_Activity_Name_after_MQL__c its populated'
        );
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void populateActivityFieldsByEventOnLeadSAL() {
        User aeUser = (User) new UserSelector().selectUserByLastName(new List<String>{ Test_DemandFunnelHelper.AELASTNAME }).executeQuery()[0];

        test.startTest();
        Lead ld = (Lead) new SObjectBuilder(Lead.SObjectType)
            .setField(Lead.Status, LeadTriggerHelper.LEADSTATUSCONTACTED)
            .setField(Lead.LastName, Test_DemandFunnelHelper.LEADLASTNAME)
            .setField(Lead.Email, testEmail)
            .setField(Lead.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Lead.OwnerId, aeUser.Id)
            .setField(Lead.LeadSource, Test_DemandFunnelHelper.LEADSOURCE)
            .create()
            .getRecord();

        Event t = (Event) new SObjectBuilder(Event.SObjectType)
            .setField(Event.WhoId, ld.Id)
            .setField(Event.Subject, 'test Event')
            .setField(Event.DurationInMinutes, 20)
            .setField(Event.ActivityDateTime, System.now())
            .create()
            .getRecord();
        test.stopTest();

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRS(
            ld,
            new List<String>{
                'Lead__c',
                'First_Activity_ID_after_MQL__c',
                'First_Activity_DateTime_after_MQL__c',
                'First_Activity_Name_after_MQL__c'
            }
        );

        /*System.assertEquals(1, dfrList.size(), 'DFR creation failed');
        System.assertEquals(
            null,
            dfrList[0].First_Activity_ID_after_MQL__c,
            'First_Activity_ID_after_MQL__c its populated'
        );
        System.assertEquals(
            null,
            dfrList[0].First_Activity_DateTime_after_MQL__c,
            'First_Activity_DateTime_after_MQL__c its  populated'
        );
        System.assertEquals(
            null,
            dfrList[0].First_Activity_Name_after_MQL__c,
            'First_Activity_Name_after_MQL__c its populated'
        );*/
    }

    @isTest
    static void testSALRemapOnLeadConversion() {
        User aeUser = Test_DemandFunnelHelper.getUser(Test_DemandFunnelHelper.AELASTNAME);
        User bdrUser = Test_DemandFunnelHelper.getUser(Test_DemandFunnelHelper.BDRLASTNAME);
        Pricebook2 pb = Test_DemandFunnelHelper.getPriceBooks();

        Account acc = Test_DemandFunnelHelper.getTestAccount();

        Contact con = (Contact) new ContactSelector().selectContacts().executeQuery()[0];

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
            .create()
            .getRecord();

        Lead ld = (Lead) new SObjectBuilder(Lead.SObjectType)
            .setField(Lead.LastName, Test_DemandFunnelHelper.LEADLASTNAME)
            .setField(Lead.Status, LeadTriggerHelper.LEADSTATUSNEW)
            .setField(Lead.Email, testEmail)
            .setField(Lead.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Lead.LeadSource, Test_DemandFunnelHelper.LEADSOURCE)
            .setField(
                Lead.RecordTypeId,
                Lead.SObjectType.getDescribe().getRecordTypeInfosByName().get('Sales Leads').getRecordTypeId()
            )
            .setField(Lead.OwnerId, aeUser.Id)
            .build()
            .create()
            .getRecord();

        ld.OwnerId = bdrUser.Id;
        ld.Status = LeadTriggerHelper.LEADSTATUSCONTACTED;
        update ld;

        ConvertLead.ConvertLeadDTO convertLeadData = new ConvertLead.ConvertLeadDTO();
        convertLeadData.leadId = ld.Id;
        convertLeadData.isCreateContact = false;
        convertLeadData.isBilling = false;
        convertLeadData.isCreateAccount = false;
        convertLeadData.isCreateOpportunity = false;
        convertLeadData.isCreateQuote = false;
        convertLeadData.upsellStatus = QuoteHelper.STATUS_NEW_CUSTOMER;
        convertLeadData.pricebook2Id = pb.Id;
        convertLeadData.accountId = acc.Id;
        convertLeadData.contactId = con.id;
        convertLeadData.doNotCreateOpportunity = false;
        ConvertLeadData.opportunityId = opp.Id;
        
        ConvertLead.prepareLeadRecord(convertLeadData);

        Test.startTest();

        ConvertLead.convertPart1(convertLeadData);
        ConvertLead.convertPart2(ConvertLeadData);
        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRS(
            ld,
            new List<String>{
                'SQL_Owner_Name__c',
                'TAL_Owner_Name__c',
                'TQL_Owner_Name__c',
                'SAL_Owner_Name__c',
                'Prospect_Owner_Name__c',
                'MQL_Owner_Name__c'
            }
        );
        Test.stopTest();

        System.assertEquals(
            Test_DemandFunnelHelper.AELASTNAME,
            dfrList[0].Prospect_Owner_Name__c,
            'Prospect_Owner_Name__c incorrect value'
        );
        System.assertEquals(
            Test_DemandFunnelHelper.AELASTNAME,
            dfrList[0].MQL_Owner_Name__c,
            'MQL_Owner_Name__c incorrect value'
        );
        System.assertEquals(null, dfrList[0].TAL_Owner_Name__c, 'TAL_Owner_Name__c incorrect value');
        System.assertEquals(null, dfrList[0].TQL_Owner_Name__c, 'TQL_Owner_Name__c incorrect value');
        System.assertEquals(
            Test_DemandFunnelHelper.AELASTNAME,
            dfrList[0].SAL_Owner_Name__c,
            'SAL_Owner_Name__c incorrect value'
        );
        System.assertEquals(
            Test_DemandFunnelHelper.AELASTNAME,
            dfrList[0].SQL_Owner_Name__c,
            'SQL_Owner_Name__c incorrect value'
        );
    }
    
    @isTest
    static void testMQLFormUrl() {
        User sdrUser = (User) new UserSelector()
            .selectUserByLastName(new List<String>{ Test_DemandFunnelHelper.SDRLASTNAME })
            .executeQuery()[0];

        Test.startTest();
        Lead ld = (Lead) new SObjectBuilder(Lead.SObjectType)
            .setField(Lead.LastName, Test_DemandFunnelHelper.LEADLASTNAME)
            .setField(Lead.Status, LeadTriggerHelper.LEADSTATUSNEW)
            .setField(Lead.Email, testEmail)
            .setField(Lead.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Lead.LeadSource, Test_DemandFunnelHelper.LEADSOURCE)
            .setField(Lead.Form_URL__c, 'test')
            .create()
            .getRecord();
        Test.stopTest();

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRS(ld, new List<String>{ 'MQL_Form_URL__c', 'Prospect_Form_URL__c' });

        System.assertEquals(
            'test',
            dfrList[0].MQL_Form_URL__c,
            'The MQL_Form_URL__c field was populated incorrectly'
        );
        
        System.assertEquals(
            'test',
            dfrList[0].Prospect_Form_URL__c,
            'The Prospect_Form_URL__c field was populated incorrectly'
        );
    }
    
    @isTest
    static void testProspectFormUrl() {
        User sdrUser = (User) new UserSelector()
            .selectUserByLastName(new List<String>{ Test_DemandFunnelHelper.SDRLASTNAME })
            .executeQuery()[0];

        Test.startTest();
        Lead ld = (Lead) new SObjectBuilder(Lead.SObjectType)
            .setField(Lead.LastName, Test_DemandFunnelHelper.LEADLASTNAME)
            .setField(Lead.Status, LeadTriggerHelper.LEADSTATUSOPEN)
            .setField(Lead.Email, testEmail)
            .setField(Lead.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Lead.LeadSource, Test_DemandFunnelHelper.LEADSOURCE)
            .setField(Lead.Form_URL__c, 'test')
            .create()
            .getRecord();
        Test.stopTest();

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRS(ld, new List<String>{ 'Prospect_Form_URL__c' });

        System.assertEquals(
            'test',
            dfrList[0].Prospect_Form_URL__c,
            'The Prospect_Form_URL__c field was populated incorrectly'
        );
    }
}