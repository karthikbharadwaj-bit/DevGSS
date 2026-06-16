@isTest
private class Test_ProservProjectsReassignmentBatch {

    @testSetup
    static void setup() {
        Triggers.switchOff();
        IValueProvider accountId =  ValueProviderBuilder.provideGenericParent(Account.SObjectType);

        new SObjectBuilder(ByPassTrigger__c.sObjectType)
            .setField(ByPassTrigger__c.Bypass_Account_Trigger__c, true)
            .setField(ByPassTrigger__c.Bypass_Order_Trigger__c, true)
            .create()
            .getRecord();

        //Chain of CC Proserv Orders
        Proserv_Project__c proservProjectForInitialCCProserv = (Proserv_Project__c) new SObjectBuilder(Proserv_Project__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Proserv_Project__c.Account__c => accountId
            })
            .create()
            .getRecord();

        Order initialCCProservOrder = (Order) new SObjectBuilder(Order.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Order.RecordTypeId => OrderHelper.RT_ID_CC_PROSERV ,
                    Order.AccountId => accountId,
                    Order.Type => OrderHelper.TYPE_INITIAL_ORDER,
                    Order.EffectiveDate => System.today(),
                    Order.Status => OrderHelper.STATUS_NEW,
                    Order.ProServProject__c => proservProjectForInitialCCProserv.Id
                }
            )
            .create()
            .getRecord();

        Opportunity firstChangeCCProservOrderOpportunity = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.AccountId => accountId,
                    Opportunity.Parent_Order__c => initialCCProservOrder.Id,
                    Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                    Opportunity.CloseDate => System.today()
                }
            )
            .create()
            .getRecord();

        Proserv_Project__c proservProjectForFirstCCProserv = (Proserv_Project__c) new SObjectBuilder(Proserv_Project__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Proserv_Project__c.Account__c => accountId
            })
            .create()
            .getRecord();

        Order firstChangeCCProservOrder = (Order) new SObjectBuilder(Order.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Order.RecordTypeId => OrderHelper.RT_ID_CC_PROSERV ,
                    Order.AccountId => accountId,
                    Order.Type => OrderHelper.TYPE_CHANGE_ORDER,
                    Order.EffectiveDate => System.today(),
                    Order.Status => OrderHelper.STATUS_NEW,
                    Order.OpportunityId => firstChangeCCProservOrderOpportunity.Id,
                    Order.ProServProject__c => proservProjectForFirstCCProserv.Id
                }
            )
            .create()
            .getRecord();

        Opportunity secondChangeCCProservOrderOpportunity = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.AccountId => accountId,
                    Opportunity.Parent_Order__c => firstChangeCCProservOrder.Id,
                    Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                    Opportunity.CloseDate => System.today()
                }
            )
            .create()
            .getRecord();

        Proserv_Project__c proservProjectForSecondCCProserv = (Proserv_Project__c) new SObjectBuilder(Proserv_Project__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Proserv_Project__c.Account__c => accountId
            })
            .create()
            .getRecord();

        Order secondChangeCCProservOrder = (Order) new SObjectBuilder(Order.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Order.RecordTypeId => OrderHelper.RT_ID_CC_PROSERV ,
                    Order.AccountId => accountId,
                    Order.Type => OrderHelper.TYPE_CHANGE_ORDER,
                    Order.EffectiveDate => System.today(),
                    Order.Status => OrderHelper.STATUS_NEW,
                    Order.OpportunityId => secondChangeCCProservOrderOpportunity.Id,
                    Order.ProServProject__c => proservProjectForSecondCCProserv.Id
                }
            )
            .create()
            .getRecord();

        Opportunity thirdChangeCCProservOrderOpportunity = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.AccountId => accountId,
                    Opportunity.Parent_Order__c => secondChangeCCProservOrder.Id,
                    Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                    Opportunity.CloseDate => System.today()
                }
            )
            .create()
            .getRecord();

        Proserv_Project__c proservProjectForThirdCCProserv = (Proserv_Project__c) new SObjectBuilder(Proserv_Project__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Proserv_Project__c.Account__c => accountId
            })
            .create()
            .getRecord();

        Order thirdChangeCCProservOrder = (Order) new SObjectBuilder(Order.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Order.RecordTypeId => OrderHelper.RT_ID_CC_PROSERV ,
                    Order.AccountId => accountId,
                    Order.Type => OrderHelper.TYPE_CHANGE_ORDER,
                    Order.EffectiveDate => System.today(),
                    Order.Status => OrderHelper.STATUS_NEW,
                    Order.OpportunityId => thirdChangeCCProservOrderOpportunity.Id,
                    Order.ProServProject__c => proservProjectForThirdCCProserv.Id
                }
            )
            .create()
            .getRecord();

        //Chain of Proserv Orders
        Proserv_Project__c proservProjectForInitialProserv = (Proserv_Project__c) new SObjectBuilder(Proserv_Project__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Proserv_Project__c.Account__c => accountId
            })
            .create()
            .getRecord();

        Order initialProservOrder = (Order) new SObjectBuilder(Order.SObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    Order.RecordTypeId => OrderHelper.RT_ID_PROSERV ,
                    Order.AccountId => accountId,
                    Order.Type => OrderHelper.TYPE_INITIAL_ORDER,
                    Order.EffectiveDate => System.today(),
                    Order.Status => OrderHelper.STATUS_NEW,
                    Order.ProServProject__c => proservProjectForInitialProserv.Id
                }
            )
            .create()
            .getRecord();

        Opportunity firstChangeProservOrderOpportunity = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.AccountId => accountId,
                    Opportunity.Parent_Order__c => initialProservOrder.Id,
                    Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                    Opportunity.CloseDate => System.today()
                }
            )
            .create()
            .getRecord();

        Proserv_Project__c proservProjectForFirstProserv = (Proserv_Project__c) new SObjectBuilder(Proserv_Project__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Proserv_Project__c.Account__c => accountId
            })
            .create()
            .getRecord();

        Order firstChangeProservOrder = (Order) new SObjectBuilder(Order.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Order.RecordTypeId => OrderHelper.RT_ID_PROSERV ,
                    Order.AccountId => accountId,
                    Order.Type => OrderHelper.TYPE_CHANGE_ORDER,
                    Order.EffectiveDate => System.today(),
                    Order.Status => OrderHelper.STATUS_NEW,
                    Order.OpportunityId => firstChangeProservOrderOpportunity.Id,
                    Order.ProServProject__c => proservProjectForFirstProserv.Id
                }
            )
            .create()
            .getRecord();

        Opportunity secondChangeProservOrderOpportunity = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.AccountId => accountId,
                    Opportunity.Parent_Order__c => firstChangeProservOrder.Id,
                    Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                    Opportunity.CloseDate => System.today()
                }
            )
            .create()
            .getRecord();

        Proserv_Project__c proservProjectForSecondProserv = (Proserv_Project__c) new SObjectBuilder(Proserv_Project__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Proserv_Project__c.Account__c => accountId
            })
            .create()
            .getRecord();

        Order secondChangeProservOrder = (Order) new SObjectBuilder(Order.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Order.RecordTypeId => OrderHelper.RT_ID_PROSERV ,
                    Order.AccountId => accountId,
                    Order.Type => OrderHelper.TYPE_CHANGE_ORDER,
                    Order.EffectiveDate => System.today(),
                    Order.Status => OrderHelper.STATUS_NEW,
                    Order.OpportunityId => secondChangeProservOrderOpportunity.Id,
                    Order.ProServProject__c => proservProjectForSecondProserv.Id
                }
            )
            .create()
            .getRecord();

        Opportunity thirdChangeProservOrderOpportunity = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.AccountId => accountId,
                    Opportunity.Parent_Order__c => secondChangeProservOrder.Id,
                    Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                    Opportunity.CloseDate => System.today()
                }
            )
            .create()
            .getRecord();

        Proserv_Project__c proservProjectForThirdProserv = (Proserv_Project__c) new SObjectBuilder(Proserv_Project__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Proserv_Project__c.Account__c => accountId
            })
            .create()
            .getRecord();

        Order thirdChangeProservOrder = (Order) new SObjectBuilder(Order.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Order.RecordTypeId => OrderHelper.RT_ID_PROSERV ,
                    Order.AccountId => accountId,
                    Order.Type => OrderHelper.TYPE_CHANGE_ORDER,
                    Order.EffectiveDate => System.today(),
                    Order.Status => OrderHelper.STATUS_NEW,
                    Order.OpportunityId => thirdChangeProservOrderOpportunity.Id,
                    Order.ProServProject__c => proservProjectForThirdProserv.Id
                }
            )
            .create()
            .getRecord();
        Triggers.switchOn();
    }

    @isTest
    static void testBatch() {
        Triggers.switchOff();
        Test.startTest();
        Database.executeBatch(new ProservProjectsReassignmentBatch());
        Test.stopTest();

        List<Order> orders = (List<Order>) new OrderSelector()
            .selectOrders()
            .selectFields(
                new List<String> {
                    'ProservProject__c',
                    'Type',
                    'RecordTypeId'
                }
            )
            .executeQuery();

        Map<Id, List<Order>> accIdsToOrders = new Map<Id, List<Order>>();
        Order initialProservOrder;
        Order initialCCProservOrder;

        for (Order currentOrder : orders) {
            if (currentOrder.Type == OrderHelper.TYPE_INITIAL_ORDER && currentOrder.RecordTypeId == OrderHelper.RT_ID_PROSERV) {
                initialProservOrder = currentOrder;
            } else if (currentOrder.Type == OrderHelper.TYPE_INITIAL_ORDER && currentOrder.RecordTypeId == OrderHelper.RT_ID_CC_PROSERV) {
                initialCCProservOrder = currentOrder;
            }
        }

        for (Order order : orders) {
            if (order.RecordTypeId == OrderHelper.RT_ID_PROSERV) {
                Assert.areEqual(order.ProservProject__c, initialProservOrder.ProservProject__c);
            } else if (order.RecordTypeId == OrderHelper.RT_ID_CC_PROSERV) {
                Assert.areEqual(order.ProservProject__c, initialCCProservOrder.ProservProject__c);
            }
        }
        Triggers.switchOn();
    }
}