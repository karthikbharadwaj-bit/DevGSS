@isTest
private class Test_PSIntegrationSelector {

    @testSetup
    private static void createTestData(){

        Triggers.SwitchOff();
        Account testAccount = TestDataGenerator.createAccount('Test Account');
        Opportunity testOpp = TestDataGenerator.createOpportunity(testAccount);
        Quote testQuote = TestDataGenerator.createQuote(testOpp);

        ProServ_Project__c testProject = (ProServ_Project__c) new SObjectBuilder(ProServ_Project__c.sObjectType)
        .setFields(new Map<SObjectField, Object> {
            ProServ_Project__c.Account__c => testAccount.Id,
            ProServ_Project__c.Quote__c => testQuote.Id
        })
        .create()
        .getRecord();

        Order testOrder = (Order) new SObjectBuilder(Order.sObjectType)
            .setFields(new Map<SObjectField, Object> {
                Order.Name => 'Test Order',
                Order.AccountId => testAccount.Id,
                Order.Status => 'New',
                Order.EffectiveDate => System.today(),
                Order.Pricebook2Id => Test.getStandardPricebookId(),
                Order.RecordTypeId => OrderHelper.RT_ID_PROSERV,
                Order.ProServProject__c => testProject.Id,
                Order.CurrencyIsoCode => 'USD'
            })
            .create()
            .getRecord();
            
        Phase__c testPhase = (Phase__c) new SObjectBuilder(Phase__c.sObjectType)
            .setFields(new Map<SObjectField, Object> {
                Phase__c.Order__c => testOrder.Id,
                Phase__c.Phase_Number__c => 1,
                Phase__c.Phase_Type__c => 'UC',
                Phase__c.Status__c => 'Active'
            })
            .create()
            .getRecord();
        
        
        Suborder__c testSuborder = (Suborder__c) new SObjectBuilder(Suborder__c.sObjectType)
            .setFields(new Map<SObjectField, Object> {
                Suborder__c.Order__c => testOrder.Id,
                Suborder__c.Phase__c => testPhase.Id,
                Suborder__c.Status__c => SuborderHelper.STATUS_NEW,
                Suborder__c.SuborderNumber__c => 1,
                Suborder__c.Suborder_Type__c => 'UC'
            })
            .create()
            .getRecord();

        PS_Integration__c testPSIntegration = (PS_Integration__c) new SObjectBuilder(PS_Integration__c.sObjectType)
            .setFields(new Map<SObjectField, Object> {
                PS_Integration__c.Status__c => PSIntegrationHelper.STATUS_NEW,
                PS_Integration__c.Order__c => testOrder.Id,
                PS_Integration__c.Phase__c => testPhase.Id,
                PS_Integration__c.ProServProject__c => testProject.Id,
                PS_Integration__c.MostRecentSuborder__c => testSuborder.Id,
                PS_Integration__c.PSIntegrationNumber__c => '12345 - 1'
            })
            .create()
            .getRecord();

        Triggers.SwitchOn();
    }

    @isTest
    private static void testselectPSIntegrationsBySubOrderIds() {
       
        List<Suborder__c> reselectedSuborders = (List<Suborder__c>) new SuborderSelector()
            .selectSuborders()
            .executeQuery();

        if (!reselectedSuborders.isEmpty()) {
        List<PS_Integration__c> reselectedPSIntegrations = new PSIntegrationSelector()
                .selectPSIntegrationsBySubOrderIds(new List<Object> { new List<Id> { reselectedSuborders[0].Id } })
                .executeQuery();
            
        Assert.areEqual(false, reselectedPSIntegrations.isEmpty(), 'Selector should return PS_Integration__c record');
        }
    }

    @isTest
    private static void testselectPSIntegrationsByOrderIds() {
       
        List<Order> reselectedOrders = (List<Order>) new OrderSelector()
            .selectOrders()
            .executeQuery();

        if (!reselectedOrders.isEmpty()) {
        List<PS_Integration__c> reselectedPSIntegrations = new PSIntegrationSelector()
                .selectPSIntegrationsByOrderIds(new Set<Id> { reselectedOrders[0].Id })
                .executeQuery();
            
        Assert.areEqual(false, reselectedPSIntegrations.isEmpty(), 'Selector should return PS_Integration__c record');
        }
    }

    @isTest
    private static void testselectPSIntegrationsByProjectIds() {
       
        List<ProServ_Project__c> reselectedProjects = (List<ProServ_Project__c>) new ProServProjectSelector()
            .selectProServProjects()
            .executeQuery();

        if (!reselectedProjects.isEmpty()) {
        List<PS_Integration__c> reselectedPSIntegrations = new PSIntegrationSelector()
                .selectPSIntegrationsByProjectIds(new List<Object> { new List<ID> { reselectedProjects[0].Id }, new List<String> { PSIntegrationHelper.STATUS_NEW} })
                .executeQuery();
            
        Assert.areEqual(false, reselectedPSIntegrations.isEmpty(), 'Selector should return PS_Integration__c record');
        }
    }

}