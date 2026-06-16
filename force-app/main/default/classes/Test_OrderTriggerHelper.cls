@isTest
private class Test_OrderTriggerHelper {

    @isTest
    private static void testCreateProservProjectForProservOrder() {
        Triggers.SwitchOff();
        Opportunity testOpp = TestDataGenerator.createOpportunity(null);
        Quote testQuote = TestDataGenerator.createQuote(testOpp);
        testQuote.RecordTypeId = QuoteHelper.RT_ID_PROSERV;
        testQuote.Payment_Plan__c = QuoteHelper.PAYMENT_PLAN_ANNUAL;
        update testQuote;
        Triggers.SwitchOn();
        Test.startTest();
        Order order = (Order) new SObjectBuilder(Order.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Order.RecordTypeId => OrderHelper.RT_ID_PROSERV ,
                    Order.AccountId => ValueProviderBuilder.provideGenericParent(Account.SObjectType),
                    Order.OpportunityId => testOpp.Id,
                    Order.Type => OrderHelper.TYPE_INITIAL_ORDER,
                    Order.EffectiveDate => System.today(),
                    Order.Status => 'New',
                    Order.QuoteId => testQuote.Id
                }
            )
            .create()
            .getRecord();
        Test.stopTest();

        List<ProServ_Project__c> proservProjectsList = (List<ProServ_Project__c>) new ProServProjectSelector()
            .selectProServProjects()
            .executeQuery();
        Assert.areEqual(proservProjectsList.size(), 1);
    }

    @isTest
    private static void testCreateProservProjectForCCOrder() {
        Triggers.SwitchOff();
        Opportunity testOpp = TestDataGenerator.createOpportunity(null);
        Quote testQuote = TestDataGenerator.createQuote(testOpp);
        testQuote.RecordTypeId = QuoteHelper.RT_ID_CC_PROSERV;
        testQuote.Payment_Plan__c = QuoteHelper.PAYMENT_PLAN_ANNUAL;
        update testQuote;
        Triggers.SwitchOn();   
        Test.startTest();
        Order order = (Order) new SObjectBuilder(Order.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Order.RecordTypeId => OrderHelper.RT_ID_CC ,
                    Order.AccountId => ValueProviderBuilder.provideGenericParent(Account.SObjectType),
                    Order.OpportunityId => testOpp.Id,
                    Order.Type => OrderHelper.TYPE_INITIAL_ORDER,
                    Order.EffectiveDate => System.today(),
                    Order.Status => 'New',
                    Order.QuoteId => testQuote.Id
                }
            )
            .create()
            .getRecord();
        Test.stopTest();

        List<ProServ_Project__c> proservProjectsList = (List<ProServ_Project__c>) new ProServProjectSelector()
            .selectProServProjects()
            .executeQuery();
        Assert.areEqual(proservProjectsList.size(), 0);
    }

    @isTest
    private static void testUpdateProservProjectLookupOfChangeOrder() {
        new SObjectBuilder(Feature_Toggle__c.sObjectType)
            .setField(Feature_Toggle__c.NewProServObjectRelatedData__c, true)
            .create();
        IValueProvider accountId =  ValueProviderBuilder.provideGenericParent(Account.SObjectType);

        Triggers.SwitchOff();
        Opportunity testOpp = TestDataGenerator.createOpportunity(null);
        Quote testQuote = TestDataGenerator.createQuote(testOpp);
        testQuote.RecordTypeId = QuoteHelper.RT_ID_CC_PROSERV;
        testQuote.Payment_Plan__c = QuoteHelper.PAYMENT_PLAN_ANNUAL;
        update testQuote;
        Triggers.SwitchOn();  
        
        Order initialOrder = (Order) new SObjectBuilder(Order.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Order.RecordTypeId => OrderHelper.RT_ID_CC_PROSERV ,
                    Order.AccountId => accountId,
                    Order.Type => OrderHelper.TYPE_INITIAL_ORDER,
                    Order.EffectiveDate => System.today(),
                    Order.Status => 'New',
                    Order.OpportunityId => testOpp.Id,
                    Order.QuoteId => testQuote.Id
                }
            )
            .create()
            .getRecord();

        Test.startTest();
            Opportunity changeOrderOpportunity = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        Opportunity.AccountId => accountId,
                        Opportunity.Parent_Order__c => initialOrder.Id,
                        Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY
                    }
                )
                .create()
                .getRecord();

            Order changeOrder = (Order) new SObjectBuilder(Order.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        Order.RecordTypeId => OrderHelper.RT_ID_CC_PROSERV ,
                        Order.AccountId => accountId,
                        Order.Type => OrderHelper.TYPE_CHANGE_ORDER,
                        Order.EffectiveDate => System.today(),
                        Order.Status => 'New',
                        Order.OpportunityId => changeOrderOpportunity.Id
                    }
                )
                .create()
                .getRecord();
        Test.stopTest();

        Order changeOrderWithProServProject = (Order) new OrderSelector()
            .selectOrders()
            .selectField('ProServProject__c')
            .setCondition('Type = \'' + OrderHelper.TYPE_CHANGE_ORDER + '\'')
            .executeQuery()
            .get(0);
        ProServ_Project__c proservProject = (ProServ_Project__c) new ProServProjectSelector()
            .selectProServProjects()
            .executeQuery()
            .get(0);
        Assert.areEqual(changeOrderWithProServProject.ProServProject__c, proservProject.Id);
    }

    @isTest
    private static void testEnqueueCreateSupportEntitlementsJobOnOrderInsert() {

        Account testAcc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Name => 'test account'
            })
            .create()
            .getRecord();

        System.assertEquals(0, Limits.getQueueableJobs());

        Order testOrder = (Order) new SObjectBuilder(Order.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Order.AccountId => testAcc.Id,
                Order.Status => OrderHelper.STATUS_NEW,
                Order.Type => OrderHelper.TYPE_INITIAL_ORDER,
                Order.EffectiveDate => System.today()
            })
            .create()
            .getRecord();

        System.assertEquals(1, Limits.getQueueableJobs(), 'CreateSupportEntitlements Queueable jobs should be enqueued on Order insert');
    }

    @isTest
    private static void testPublishCreateSupportEntitlementsEventOnOrderInsert() {
        EventBusSubscriber initialEventSubscriber = getCreateSupportEntitlementsEventSubscriber();
        System.assertEquals(0, initialEventSubscriber.Position, 'there should be no processed events');

        Test.startTest();

        System.enqueueJob(new QueueableJobForCreateSupportEntitlementsTest());

        Test.stopTest();

        EventBusSubscriber updatedEventSubscriber = getCreateSupportEntitlementsEventSubscriber();
        System.assert(updatedEventSubscriber.Position > initialEventSubscriber.Position, 'CreateSupportEntitlements event should be published on Order insert');
    }

    private class QueueableJobForCreateSupportEntitlementsTest implements Queueable {
        public void execute(QueueableContext context) {
            Account testAcc = (Account) new SObjectBuilder(Account.SObjectType)
                .setFields(new Map<SObjectField, Object> {
                    Account.Name => 'test account'
                })
                .create()
                .getRecord();

            List<Order> testOrders = (List<Order>) new SObjectBuilder(Order.SObjectType)
                .setFields(new Map<SObjectField, Object> {
                    Order.AccountId => testAcc.Id,
                    Order.Status => OrderHelper.STATUS_NEW,
                    Order.Type => OrderHelper.TYPE_INITIAL_ORDER,
                    Order.EffectiveDate => System.today()
                })
                .quantity(2)
                .build()
                .getRecords();

            insert testOrders.get(0);
            insert testOrders.get(1);
        }
    }

    private static EventBusSubscriber getCreateSupportEntitlementsEventSubscriber() {
        return (EventBusSubscriber) new QueryFactory(EventBusSubscriber.SObjectType)
            .withoutSelectorFieldsIncluded()
            .selectFields(new List<String>{'Position'})
            .setCondition('Topic = \'CreateSupportEntitlements__e\' AND Type = \'ApexTrigger\'')
            .withoutSelectorOrderByIncluded()
            .executeQuery()
            .get(0);
    }
}