public with sharing class CreateSupportEntitlementsTriggerHandler {

    public class CreateSupportEntitlements extends Triggers.TriggerHandlerBase {
        override public void handle() {
            List<Id> orderIds = new List<Id>();

            for (CreateSupportEntitlements__e event : (List<CreateSupportEntitlements__e>) Trigger.new) {
                orderIds.add(Id.valueOf(event.OrderId__c));
            }

            if (!orderIds.isEmpty()) {
                QueueableBase.enqueJob('CreateSupportEntitlements', orderIds);
            }
        }
    }
}