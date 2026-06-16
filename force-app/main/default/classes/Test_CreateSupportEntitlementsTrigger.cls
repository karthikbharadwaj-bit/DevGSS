@isTest
private class Test_CreateSupportEntitlementsTrigger {

    @isTest
    static void testCreateSupportEntitlements() {
        Account testAcc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Name => 'test account'
            })
            .create()
            .getRecord();

        Order testOrder = (Order) new SObjectBuilder(Order.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Order.AccountId => testAcc.Id,
                Order.Status => OrderHelper.STATUS_NEW,
                Order.Type => OrderHelper.TYPE_INITIAL_ORDER,
                Order.EffectiveDate => System.today()
            })
            .create()
            .getRecord();

        List<CreateSupportEntitlements__e> events =
            (List<CreateSupportEntitlements__e>) new SObjectBuilder(CreateSupportEntitlements__e.SObjectType)
                .setFields(
                    new Map<SObjectField, Object> {
                        CreateSupportEntitlements__e.OrderId__c => String.valueOf(testOrder.Id)
                    }
                )
                .create()
                .getRecords();

        Test.startTest();

        EventBus.publish(events);

        Test.stopTest();

        System.assertEquals(1, Limits.getQueueableJobs(), 'CreateSupportEntitlements Queueable job should be enqueued on event publish');
    }
}