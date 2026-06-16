@isTest
public without sharing class EventTriggerHandlerTest {
    private static final String ACC_NAME = 'EventAccount';
    private static final String OPP_NAME = 'EventOpportunity';
    private static final String USER_NAME = 'useruserson@testly.com';

    @testSetup
    private static void addTestData() {
        Profile standardProfile = (Profile) new ListOptional(
            new ProfileSelector()
                .selectProfileByName(new List<String> { 'Standard User' })
                .executeQuery()
        ).getFirst();

        User standardUser = (User) new SObjectBuilder(User.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                User.LastName => 'Testing',
                User.Username => USER_NAME,
                User.Email => 'standarduser@testorg.com',
                User.Alias => 'standt',
                User.TimeZoneSidKey => 'America/Los_Angeles',
                User.ManagerId => UserInfo.getUserId(),
                User.LocaleSidKey => 'en_US',
                User.EmailEncodingKey => 'UTF-8',
                User.ProfileId => standardProfile.Id,
                User.LanguageLocaleKey => 'en_US',
                User.Hierarchy_Role__c => UserHelper.SALES_REP_ROLE
            })
            .create()
            .getRecord();

        Account testAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Name => ACC_NAME,
                Account.OwnerId => standardUser.Id,
                Account.RC_User_ID__c => '123'
            })
            .create()
            .getRecord();

        new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.Name => OPP_NAME,
                Opportunity.AccountId => testAccount.Id,
                Opportunity.CloseDate => Date.today(),
                Opportunity.OwnerId => standardUser.Id
            })
            .create();

        new SObjectBuilder(Event.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Event.WhatId => testAccount.Id,
                Event.DurationInMinutes => 180,
                Event.ActivityDateTime => Datetime.now().addMinutes(5),
                Event.OwnerId => standardUser.Id
            })
            .create();
    }

    @isTest
    private static void testEventSaver() {
        Account oneAccount = selectAccount();

        Implementation__c imp = new Implementation__c();
        imp.Account__c = oneAccount.Id;
        insert imp;

        Event preexistingEvent = (Event) new SObjectBuilder(Event.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Event.WhatId => oneAccount.Id,
                Event.DurationInMinutes => 180,
                Event.ActivityDateTime => Datetime.now().addMinutes(5),
                Event.CustomerId__c => '123'
            })
            .create()
            .getRecord();

        Assert.areEqual(180, preexistingEvent.DurationInMinutes, 'Event minutes changed');
    }

    @isTest
    private static void testAccountAndOpportunityTeamMemberInsertion() {
        Account testAccount = selectAccount();
        Opportunity testOpportunity = selectOpportunity();
        User standardUser = selectUser();

        Test.startTest();
        createEvent(new List<Id> { testAccount.Id, testOpportunity.Id }, standardUser.Id);
        Test.stopTest();

        Assert.isTrue(
            [SELECT COUNT() FROM AccountTeamMember WHERE AccountId = :testAccount.Id] > 0,
            'Account Contact Role not created for Event.'
        );

        Assert.isTrue(
            [SELECT COUNT() FROM OpportunityTeamMember WHERE OpportunityId = :testOpportunity.Id] > 0,
            'Opportunity Contact Role not created for Event.'
        );
    }

    @isTest
    private static void testAccountAndOpportunityTeamMemberInsertionByCase() {
        User standardUser = selectUser();
        Triggers.switchOff();
        List<Account> testAccounts = (List<Account>) new SObjectBuilder(Account.SObjectType)
            .quantity(2)
            .setFields(new Map<SObjectField, Object> {
                Account.Name => ValueProviderBuilder.provideList(new List<String> { 'name1', 'name2' }),
                Account.RC_Account_Status__c => AccountHelper.PAID_STATUS
            })
            .create()
            .getRecords();
        Id accId1 = testAccounts[0].Id;
        Id accId2 = testAccounts[1].Id;

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.Name => 'oppName',
                Opportunity.AccountId => accId2,
                Opportunity.CloseDate => Date.today(),
                Opportunity.OwnerId => standardUser.Id
            })
            .create()
            .getRecord();

        Contact testContact = (Contact) new SObjectBuilder(Contact.sObjectType)
            .setFields(new Map<SObjectField, Object> { Contact.LastName => 'CONTACT_LAST_NAME', Contact.AccountId => accId1 })
            .create()
            .getRecord();
        Id contactId = testContact.Id;

        List<Case> newCases = (List<Case>) new SObjectBuilder(Case.SObjectType)
            .quantity(2)
            .setFields(
                new Map<SObjectField, Object> {
                    Case.AccountId => accId1,
                    Case.ContactId => contactId,
                    Case.Opportunity_Reference__c => ValueProviderBuilder.provideList(new List<Id> { null, opp.Id })
                }
            )
            .create()
            .getRecords();
        Triggers.switchOn();

        Test.startTest();
        createEvent(new List<Id> { newCases[0].Id, newCases[1].Id }, standardUser.Id);
        Test.stopTest();

        Assert.isTrue(
            [SELECT COUNT() FROM AccountTeamMember WHERE AccountId = :accId1] > 0,
            'Account Contact Role not created for Event.'
        );

        Assert.isTrue(
            [SELECT COUNT() FROM AccountTeamMember WHERE AccountId = :accId2] > 0,
            'Account Contact Role not created for Event by opportunity.'
        );

        Assert.isTrue(
            [SELECT COUNT() FROM OpportunityTeamMember WHERE OpportunityId = :opp.Id] > 0,
            'Opportunity Contact Role not created for Event.'
        );
    }

    private static Account selectAccount() {
        return (Account) new ListOptional(new AccountSelector()
            .selectAccountByName(new List<Object> { ACC_NAME })
            .executeQuery()
        ).getFirst();
    }

    private static Opportunity selectOpportunity() {
        return (Opportunity) new ListOptional(new OpportunitySelector()
            .selectOpportunityByName(OPP_NAME)
            .executeQuery()
        ).getFirst();
    }

    private static User selectUser() {
        return (User) new ListOptional(new UserSelector()
            .selectUserByUsername(new List<Object> { new Set<String> { USER_NAME }})
            .executeQuery()
        ).getFirst();
    }

    private static void createEvent(List<Id> objectIds, Id userId) {
        new SObjectBuilder(Event.SObjectType)
            .quantity(objectIds.size())
            .setFields(new Map<SObjectField, Object> {
                Event.WhatId => ValueProviderBuilder.provideList(objectIds),
                Event.DurationInMinutes => 180,
                Event.ActivityDateTime => Datetime.now().addMinutes(5),
                Event.OwnerId => userId,
                Event.RecordTypeId => EventTriggerHelper.RT_ID_SE_EVENT
            })
            .create();
    }

}