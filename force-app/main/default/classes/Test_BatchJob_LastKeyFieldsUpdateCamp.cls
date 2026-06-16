@isTest
public with sharing class Test_BatchJob_LastKeyFieldsUpdateCamp {
    
    @TestSetup
    static void setupData() {
        Test.startTest();
        Triggers.switchOff();
        Account acc1 = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => 'testAcc',
                    Account.RC_Brand__c => 'Test Brand'
                }
            )
            .create()
            .getRecord();

        Account acc2 = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => 'testAcc2',
                    Account.RC_Brand__c => 'Test Brand',
                    Account.BillingCountry => 'Uruguay'
                }
            )
            .create()
            .getRecord();

        Account acc3 = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => 'testAccUS',
                    Account.RC_Brand__c => 'Test Brand',
                    Account.BillingCountry => 'United States'
                }
            )
            .create()
            .getRecord();

        Opportunity opp1 = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.Name => 'Test Opportunity 2016',
                    Opportunity.Type => 'Syndicated - New',
                    Opportunity.StageName => 'Planning',
                    Opportunity.CloseDate => system.today().addMonths(1),
                    Opportunity.AccountId => acc1.Id,
                    Opportunity.Brand_Name__c => 'Test'
                }
            )
            .create()
            .getRecord();
            
        Opportunity opp2 = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.Name => 'Test Opportunity 2016',
                    Opportunity.Type => 'Syndicated - New',
                    Opportunity.StageName => 'Planning',
                    Opportunity.CloseDate => system.today().addMonths(1),
                    Opportunity.AccountId => acc2.Id,
                    Opportunity.Brand_Name__c => 'Test'
                }
            )
            .create()
            .getRecord();

        Campaign camp = (Campaign) new SObjectBuilder(Campaign.sObjectType)
            .setField(Campaign.IsActive, true)
            .setField(Campaign.Non_Attributable__c, false)
            .setField(Campaign.Name, 'Campaign1')
            .setField(Campaign.BMID__c, '1')
            .setField(Campaign.AID__c, '1')
            .setField(Campaign.PID__c, '1')
            .setField(Campaign.DNIS__c, '1')
            .setField(Campaign.Intended_Product__c, 'Test')
            .create()
            .getRecord();
        
        Lead leadUsa = (Lead) new SObjectBuilder(Lead.sObjectType)
            .setField(Lead.lastName, 'Lead1')
            .setField(Lead.BMID__c, null)
            .setField(Lead.AID__c, '1')
            .setField(Lead.PID__c, '1')
            .setField(Lead.Country, 'United States')
            .create()
            .getRecord();

        Lead leadArg = (Lead) new SObjectBuilder(Lead.sObjectType)
            .setField(Lead.lastName, 'Lead1')
            .setField(Lead.BMID__c, null)
            .setField(Lead.AID__c, '1')
            .setField(Lead.PID__c, '1')
            .setField(Lead.Country, 'Argentina')
            .create()
            .getRecord();

        Contact conUsa = (Contact) new SObjectBuilder(Contact.sObjectType)
            .setField(Contact.lastName, 'Contact1')
            .setField(Contact.BMID__c, null)
            .setField(Contact.AID__c, '1')
            .setField(Contact.PID__c, '1')
            .setField(Contact.AccountId, acc1.Id)
            .create()
            .getRecord();

        Contact conUru = (Contact) new SObjectBuilder(Contact.sObjectType)
            .setField(Contact.lastName, 'Contact1')
            .setField(Contact.BMID__c, null)
            .setField(Contact.AID__c, '1')
            .setField(Contact.PID__c, '1')
            .setField(Contact.AccountId, acc2.Id)
            .create()
            .getRecord();

        CampaignMember campMemb1 = (CampaignMember) new SObjectBuilder(CampaignMember.sObjectType)
            .setField(CampaignMember.CampaignId, camp.Id)
            .setField(CampaignMember.ContactId, conUsa.Id)
            .create()
            .getRecord();

        CampaignMember campMemb2 = (CampaignMember) new SObjectBuilder(CampaignMember.sObjectType)
            .setField(CampaignMember.CampaignId, camp.Id)
            .setField(CampaignMember.LeadId, leadUsa.Id)
            .create()
            .getRecord();

        CampaignMember campMemb3 = (CampaignMember) new SObjectBuilder(CampaignMember.sObjectType)
            .setField(CampaignMember.CampaignId, camp.Id)
            .setField(CampaignMember.LeadId, leadArg.Id)
            .create()
            .getRecord();

        CampaignMember campMemb4 = (CampaignMember) new SObjectBuilder(CampaignMember.sObjectType)
            .setField(CampaignMember.CampaignId, camp.Id)
            .setField(CampaignMember.ContactId, conUru.Id)
            .create()
            .getRecord();

        CampaignInfluenceModel model = [SELECT Id FROM CampaignInfluenceModel LIMIT 1];

        CampaignInfluence campInf1 = (CampaignInfluence) new SObjectBuilder(CampaignInfluence.sObjectType)
            .setField(CampaignInfluence.CampaignId, camp.Id)
            .setField(CampaignInfluence.ContactId, conUsa.Id)
            .setField(CampaignInfluence.OpportunityId, opp1.Id)
            .setField(CampaignInfluence.ModelId, model.Id)
            .create()
            .getRecord();

        CampaignInfluence campInf2 = (CampaignInfluence) new SObjectBuilder(CampaignInfluence.sObjectType)
            .setField(CampaignInfluence.CampaignId, camp.Id)
            .setField(CampaignInfluence.ContactId, conUru.Id)
            .setField(CampaignInfluence.OpportunityId, opp1.Id)
            .setField(CampaignInfluence.ModelId, model.Id)
            .create()
            .getRecord();

        Triggers.switchOn();
        Test.stopTest();
    }

    @isTest
    static void testPopulateCampaignMembers() {
        List<CampaignMember> campMembers = [SELECT Last_Key_Fields_Update__c FROM CampaignMember];
        for (CampaignMember cm : campMembers) {
            cm.Last_Key_Fields_Update__c = null;
        }
        update campMembers;
        Test.startTest();
        BatchJob_LastKeyFieldsUpdateCampaigns batch = new BatchJob_LastKeyFieldsUpdateCampaigns('CampaignMember', true, DateTime.now().addDays(-5), DateTime.now());
        Database.executeBatch(batch);
        Test.stopTest();

        List<CampaignMember> testCampMembers = [SELECT Last_Key_Fields_Update__c FROM CampaignMember WHERE Last_Key_Fields_Update__c != null];
        System.assertEquals(2, testCampMembers.size(), 'The number of Campaign Members with Last Key Fields Update populated should be 2');
    }


    @isTest
    static void testPopulateCampaignInfluence() {
        List<CampaignInfluence> campInflu = [SELECT Last_Key_Fields_Update__c FROM CampaignInfluence];
        for (CampaignInfluence ci : campInflu) {
            ci.Last_Key_Fields_Update__c = null;
        }
        update campInflu;
        Test.startTest();
        BatchJob_LastKeyFieldsUpdateCampaigns batch = new BatchJob_LastKeyFieldsUpdateCampaigns('CampaignInfluence', true, DateTime.now().addDays(-5), DateTime.now());
        Database.executeBatch(batch);
        Test.stopTest();

        List<CampaignInfluence> campInfluence = [SELECT Last_Key_Fields_Update__c FROM CampaignInfluence WHERE Last_Key_Fields_Update__c != null];
        System.assertEquals(1, campInfluence.size(), 'The number of Campaign Influence with Last Key Fields Update populated should be 1');
    }

    @isTest
    static void testNullCampaignMembers() {
        List<CampaignMember> campMembers = [SELECT Last_Key_Fields_Update__c FROM CampaignMember];
        for (CampaignMember cm : campMembers) {
            cm.Last_Key_Fields_Update__c = DateTime.now();
        }
        update campMembers;
        Test.startTest();
        BatchJob_LastKeyFieldsUpdateCampaigns batch = new BatchJob_LastKeyFieldsUpdateCampaigns('CampaignMember', false, DateTime.now().addDays(-5), DateTime.now());
        Database.executeBatch(batch);
        Test.stopTest();

        List<CampaignMember> testCampMembers = [SELECT Last_Key_Fields_Update__c FROM CampaignMember WHERE Last_Key_Fields_Update__c = null];
        System.assertEquals(2, testCampMembers.size(), 'The number of Campaign Members with Last Key Fields Update nullified should be 2');
    }


    @isTest
    static void testNullCampaignInfluence() {
        List<CampaignInfluence> campInflu = [SELECT Last_Key_Fields_Update__c FROM CampaignInfluence];
        for (CampaignInfluence ci : campInflu) {
            ci.Last_Key_Fields_Update__c = Datetime.now();
        }
        update campInflu;
        Test.startTest();
        BatchJob_LastKeyFieldsUpdateCampaigns batch = new BatchJob_LastKeyFieldsUpdateCampaigns('CampaignInfluence', false, DateTime.now().addDays(-5), DateTime.now());
        Database.executeBatch(batch);
        Test.stopTest();

        List<CampaignInfluence> campInfluence = [SELECT Last_Key_Fields_Update__c FROM CampaignInfluence WHERE Last_Key_Fields_Update__c = null];
        System.assertEquals(1, campInfluence.size(), 'The number of Campaign Influence with Last Key Fields Update nullified should be 1');
    }

    @isTest
    static void testPopulateOpportunity() {
        List<Opportunity> opps = [SELECT Last_Key_Fields_Update__c FROM Opportunity];
        for (Opportunity opp : opps) {
            opp.Last_Key_Fields_Update__c = null;
        }
        update opps;
        Test.startTest();
        BatchJob_LastKeyFieldsUpdateCampaigns batch = new BatchJob_LastKeyFieldsUpdateCampaigns('Opportunity', true, DateTime.now().addDays(-5), DateTime.now());
        Database.executeBatch(batch);
        Test.stopTest();

        List<Opportunity> oppsToTest = [SELECT Last_Key_Fields_Update__c FROM Opportunity WHERE Last_Key_Fields_Update__c != null];
        System.assertEquals(1, oppsToTest.size(), 'The number of Opportunities with Last Key Fields Update populated should be 1');
    }

    @isTest
    static void testPopulateOpportunityContactRole() {
        List<Contact> contacts = [SELECT Id FROM Contact];
        List<Opportunity> opps = [SELECT Id FROM Opportunity];
        OpportunityContactRole oppCon1 = (OpportunityContactRole) new SObjectBuilder(OpportunityContactRole.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    OpportunityContactRole.ContactId => contacts[0].Id,
                    OpportunityContactRole.OpportunityId => opps[0].Id,
                    OpportunityContactRole.Role => 'Signatory'
                }
            )
            .create()
            .getRecord();
        OpportunityContactRole oppCon2 = (OpportunityContactRole) new SObjectBuilder(OpportunityContactRole.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    OpportunityContactRole.ContactId => contacts[1].Id,
                    OpportunityContactRole.OpportunityId => opps[1].Id,
                    OpportunityContactRole.Role => 'Signatory'
                }
            )
            .create()
            .getRecord();
        List<OpportunityContactRole> oppsConRoles = new List<OpportunityContactRole>{oppCon1, oppCon2};
        for (OpportunityContactRole oppCon : oppsConRoles) {
            oppCon.Last_Key_Fields_Update__c = null;
        }
        update oppsConRoles;
        Test.startTest();
        BatchJob_LastKeyFieldsUpdateCampaigns batch = new BatchJob_LastKeyFieldsUpdateCampaigns('OpportunityContactRole', true, DateTime.now().addDays(-5), DateTime.now());
        Database.executeBatch(batch);
        Test.stopTest();

        List<OpportunityContactRole> oppConToTest = [SELECT Last_Key_Fields_Update__c FROM OpportunityContactRole WHERE Last_Key_Fields_Update__c != null];
        System.assertEquals(1, oppConToTest.size(), 'The number of Opportunity Contact Roles with Last Key Fields Update populated should be 1');
    }

    @isTest
    static void testPopulateTask() {
        List<Contact> contacts = [SELECT Id FROM Contact];
        Task task1 = (Task) new SObjectBuilder(Task.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Task.WhoId => contacts[0].Id,
                    Task.Subject => 'Call'
                }
            )
            .create()
            .getRecord();

        Task task2 = (Task) new SObjectBuilder(Task.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Task.WhoId => contacts[1].Id,
                    Task.Subject => 'Call'
                }
            )
            .create()
            .getRecord();

        Test.startTest();
        BatchJob_LastKeyFieldsUpdateCampaigns batch = new BatchJob_LastKeyFieldsUpdateCampaigns('Task', true, DateTime.now().addDays(-5), DateTime.now());
        Database.executeBatch(batch);
        Test.stopTest();
        List<Task> tasksToTest = [SELECT Last_Key_Fields_Update__c FROM Task WHERE Last_Key_Fields_Update__c != null];
        System.assertEquals(1, tasksToTest.size(), 'The number of Tasks with Last Key Fields Update populated should be 1');
    }

    @isTest
    static void testPopulateEvent() {
        List<Contact> contacts = [SELECT Id FROM Contact];
        Event event1 = (Event) new SObjectBuilder(Event.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Event.WhoId => contacts[0].Id,
                    Event.Subject => 'Call',
                    Event.DurationInMinutes => 60,
                    Event.ActivityDateTime => DateTime.now().addDays(1)
                }
            )
            .create()
            .getRecord();

        Event eventk2 = (Event) new SObjectBuilder(Event.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Event.WhoId => contacts[1].Id,
                    Event.Subject => 'Call',
                    Event.DurationInMinutes => 60,
                    Event.ActivityDateTime => DateTime.now().addDays(1)
                }
            )
            .create()
            .getRecord();

        Test.startTest();
        BatchJob_LastKeyFieldsUpdateCampaigns batch = new BatchJob_LastKeyFieldsUpdateCampaigns('Event', true, DateTime.now().addDays(-5), DateTime.now());
        Database.executeBatch(batch);
        Test.stopTest();
        List<Event> eventsToTest = [SELECT Last_Key_Fields_Update__c FROM Event WHERE Last_Key_Fields_Update__c != null];
        System.assertEquals(1, eventsToTest.size(), 'The number of Events with Last Key Fields Update populated should be 1');
    }

    @isTest
    static void testNullifyTask() {
        List<Contact> contacts = [SELECT Id FROM Contact];
        Task task1 = (Task) new SObjectBuilder(Task.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Task.WhoId => contacts[1].Id,
                    Task.Subject => 'Call',
                    Task.Last_Key_Fields_Update__c => DateTime.now().addDays(-1)
                }
            )
            .create()
            .getRecord();

        Test.startTest();
        BatchJob_LastKeyFieldsUpdateCampaigns batch = new BatchJob_LastKeyFieldsUpdateCampaigns('Task', false, DateTime.now().addDays(-5), DateTime.now());
        Database.executeBatch(batch);
        Test.stopTest();
        List<Task> tasksToTest = [SELECT Last_Key_Fields_Update__c FROM Task WHERE Last_Key_Fields_Update__c = null];
        System.assertEquals(1, tasksToTest.size(), 'The number of Tasks with Last Key Fields Update null should be 1');
    }
    
    @isTest
    static void testNullifyEvent() {
        List<Contact> contacts = [SELECT Id FROM Contact];
        Event event1 = (Event) new SObjectBuilder(Event.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Event.WhoId => contacts[1].Id,
                    Event.Subject => 'Call',
                    Event.DurationInMinutes => 60,
                    Event.ActivityDateTime => DateTime.now().addDays(1),
                    Event.Last_Key_Fields_Update__c => DateTime.now().addDays(-1)
                }
            )
            .create()
            .getRecord();

        Test.startTest();
        BatchJob_LastKeyFieldsUpdateCampaigns batch = new BatchJob_LastKeyFieldsUpdateCampaigns('Event', false, DateTime.now().addDays(-5), DateTime.now());
        Database.executeBatch(batch);
        Test.stopTest();
        List<Event> eventsToTest = [SELECT Last_Key_Fields_Update__c FROM Event WHERE Last_Key_Fields_Update__c = null];
        System.assertEquals(1, eventsToTest.size(), 'The number of Events with Last Key Fields Update null should be 1');
    }

    @isTest
    static void testPopulateCase() {
        Account acc = (Account) new AccountSelector()
                .selectAccountByName(new List<Object>{
                    'testAccUS'
                })
                .executeQuery()
                .get(0);

        Case c = (Case) new SObjectBuilder(Case.SObjectType)
                .setField(Case.Type, 'Telecom Ops (US)')
                .setField(Case.AccountId, acc.Id)
                .setField(Case.Status, 'New')
                .setField(Case.Priority, 'Medium')
                .setField(Case.Origin, 'Phone')
                .create()
                .getRecord();

        c.Last_Key_Fields_Update__c = null;
        update c;

        Test.startTest();
        BatchJob_LastKeyFieldsUpdateCampaigns batch = new BatchJob_LastKeyFieldsUpdateCampaigns('Case', true, DateTime.now().addDays(-5), DateTime.now());
        Database.executeBatch(batch);
        Test.stopTest();
        List<Case> caseToTest = [SELECT Last_Key_Fields_Update__c FROM Case WHERE Last_Key_Fields_Update__c != null];
        System.assertEquals(1, caseToTest.size(), 'The number of Cases with Last Key Fields Update populated should be 1');
    }

    @isTest
    static void testNullifyCase() {
        Account acc = (Account) new AccountSelector()
                .selectAccountByName(new List<Object>{
                    'testAccUS'
                })
                .executeQuery()
                .get(0);

        Case c = (Case) new SObjectBuilder(Case.SObjectType)
                .setField(Case.Type, 'Telecom Ops (US)')
                .setField(Case.AccountId, acc.Id)
                .setField(Case.Status, 'New')
                .setField(Case.Priority, 'Medium')
                .setField(Case.Origin, 'Phone')
                .create()
                .getRecord();

        Test.startTest();
        BatchJob_LastKeyFieldsUpdateCampaigns batch = new BatchJob_LastKeyFieldsUpdateCampaigns('Case', false, DateTime.now().addDays(-5), DateTime.now());
        Database.executeBatch(batch);
        Test.stopTest();
        List<Case> caseToTest = [SELECT Last_Key_Fields_Update__c FROM Case WHERE Last_Key_Fields_Update__c = null];
        System.assertEquals(1, caseToTest.size(), 'The number of Cases with Last Key Fields Update null should be 1');
    }

    @isTest
    static void testPopulateRedAccount() {
        Account acc = (Account) new AccountSelector()
                .selectAccountByName(new List<Object>{
                    'testAccUS'
                })
                .executeQuery()
                .get(0);

        Red_Account__c c = (Red_Account__c) new SObjectBuilder(Red_Account__c.SObjectType)
                .setField(Red_Account__c.EscalatedAccount__c, acc.Id)
                .setField(Red_Account__c.Issue_Category__c, 'Contract')
                .setField(Red_Account__c.Issue_Status__c, 'New')
                .create()
                .getRecord();

        c.Last_Key_Fields_Update__c = null;
        update c;

        Test.startTest();
        BatchJob_LastKeyFieldsUpdateCampaigns batch = new BatchJob_LastKeyFieldsUpdateCampaigns('RedAccount', true, DateTime.now().addDays(-5), DateTime.now());
        Database.executeBatch(batch);
        Test.stopTest();
        List<Red_Account__c> redAccountToTest = [SELECT Last_Key_Fields_Update__c FROM Red_Account__c WHERE Last_Key_Fields_Update__c != null];
        System.assertEquals(1, redAccountToTest.size(), 'The number of Red Accounts with Last Key Fields Update populated should be 1');
    }

    @isTest
    static void testNullifyRedAccount() {
        Account acc = (Account) new AccountSelector()
                .selectAccountByName(new List<Object>{
                    'testAcc2'
                })
                .executeQuery()
                .get(0);

        Red_Account__c c = (Red_Account__c) new SObjectBuilder(Red_Account__c.SObjectType)
                .setField(Red_Account__c.EscalatedAccount__c, acc.Id)
                .setField(Red_Account__c.Issue_Category__c, 'Contract')
                .setField(Red_Account__c.Issue_Status__c, 'New')
                .setField(Red_Account__c.Last_Key_Fields_Update__c, DateTime.now())
                .create()
                .getRecord();

        Test.startTest();
        BatchJob_LastKeyFieldsUpdateCampaigns batch = new BatchJob_LastKeyFieldsUpdateCampaigns('RedAccount', false, DateTime.now().addDays(-5), DateTime.now());
        Database.executeBatch(batch);
        Test.stopTest();
        List<Red_Account__c> redAccountToTest = [SELECT Last_Key_Fields_Update__c FROM Red_Account__c WHERE Last_Key_Fields_Update__c = null];
        System.assertEquals(1, redAccountToTest.size(), 'The number of Red Accounts with Last Key Fields null populated should be 1');
    }
}