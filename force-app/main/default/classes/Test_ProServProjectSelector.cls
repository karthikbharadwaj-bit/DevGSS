@isTest
public with sharing class Test_ProServProjectSelector {

    @isTest
    private static void testSelectProServProjects() {
        Triggers.switchOff();
        Proserv_Project__c proservProject = (Proserv_Project__c) new SObjectBuilder(Proserv_Project__c.SObjectType)
            .create()
            .getRecord();
        Triggers.switchOn();

        Test.startTest();
            List<Proserv_Project__c> reselectedProServProjects = new ProServProjectSelector()
                .selectProServProjects()
                .executeQuery();
        Test.stopTest();
        Assert.areEqual(false, reselectedProServProjects.isEmpty(), 'Selector should return Proserv_Project__c record');
    }

    @isTest
    private static void testSelectProServProjectsUserFields() {
        Triggers.switchOff();
        Proserv_Project__c proservProject = (Proserv_Project__c) new SObjectBuilder(Proserv_Project__c.SObjectType)
            .create()
            .getRecord();
        Triggers.switchOn();

        Test.startTest();
            List<Proserv_Project__c> reselectedProServProjects = new ProServProjectSelector()
                .selectProServProjectsUserFields()
                .executeQuery();
        Test.stopTest();
        Assert.areEqual(false, reselectedProServProjects.isEmpty(), 'Selector should return Proserv_Project__c record');
    }

    @isTest
    private static void testSelectProServProjectsAllFields() {
        Triggers.switchOff();
        Proserv_Project__c proservProject = (Proserv_Project__c) new SObjectBuilder(Proserv_Project__c.SObjectType)
            .create()
            .getRecord();
        Triggers.switchOn();

        Test.startTest();
            List<Proserv_Project__c> reselectedProServProjects = new ProServProjectSelector()
                .selectProServProjectsAllFields()
                .executeQuery();
        Test.stopTest();
        Assert.areEqual(false, reselectedProServProjects.isEmpty(), 'Selector should return Proserv_Project__c record');
    }

    @isTest
    private static void testSelectProServProjectsByOrderIds() {
        Triggers.switchOff();
        Account testAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Name => ValueProviderBuilder.provideUniqueString()
            })
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.Name => 'Test Opportunity',
                Opportunity.AccountId => testAccount.Id,
                Opportunity.CloseDate => Date.today()
            })
            .create()
            .getRecord();

        Order testOrder = (Order) new SObjectBuilder(Order.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Order.AccountId => testAccount.Id,
                    Order.Name => 'test',
                    Order.Status => OrderHelper.STATUS_NEW,
                    Order.OpportunityId => opp.Id,
                    Order.EffectiveDate => Date.newInstance(2050, 11, 11)
                }
            )
            .create()
            .getRecord();

        Proserv_Project__c proservProject = (Proserv_Project__c) new SObjectBuilder(Proserv_Project__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Proserv_Project__c.Account__c => testAccount.Id,
                Proserv_Project__c.Order__c => testOrder.Id
            })
            .create()
            .getRecord();


        Triggers.switchOn();

        Test.startTest();
            List<ProServ_Project__c> reselectedProServProjects = (List<ProServ_Project__c>) new ProServProjectSelector()
                .selectProServProjectsByOrderIds(new Set<Id>{testOrder.Id})
                .executeQuery();
        Test.stopTest();
        Assert.areEqual(false, reselectedProServProjects.isEmpty(), 'Selector should return Proserv_Project__c record');
    }
}