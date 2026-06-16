public with sharing class OrderTriggerHelper {

    public class UpdateProservProjectLookupOfChangeOrder extends Triggers.TriggerHandlerBase {

        override public void handle() {
            Set<Id> opportunitiesIds = new Set<Id>();

            for(Order order : (List<Order>) Trigger.new) {
                if ((order.RecordTypeId == OrderHelper.RT_ID_PROSERV || order.RecordTypeId == OrderHelper.RT_ID_CC_PROSERV) &&
                    order.Type == OrderHelper.TYPE_CHANGE_ORDER) {
                    opportunitiesIds.add(order.OpportunityId);
                }
            }
            if (opportunitiesIds.isEmpty()) {
                return;
            }

            Map<Id, Opportunity> opportunitiesMap = new Map<Id, Opportunity>(
                (List<Opportunity>) new OpportunitySelector()
                    .selectOpportunitiesByIds(opportunitiesIds)
                    .selectFields(new List<String>{'Parent_Order__r.ProServProject__c'})
                    .executeQuery()
            );
            for(Order order : (List<Order>) Trigger.new) {
                order.ProServProject__c = opportunitiesMap.get(order.OpportunityId)?.Parent_Order__r?.ProServProject__c;
            }
        }
    }

    public class CreateProservProject extends Triggers.TriggerHandlerBase {
        override public void handle() {
            List<Proserv_Project__c> proservProjectsToInsert = new List<Proserv_Project__c>();

            Map<Id, Order> ordersMap = new Map<Id, Order>((List<Order>) new OrderSelector()
                                    .selectOrders()
                                    .selectFields(new List<String> {'Id','RecordTypeId','Quote.RecordTypeId'})
                                    .setCondition('Id IN :bind0')
                                    .setQueryBindings(new List<Object>{Trigger.newMap.keySet()})
                                    .executeQuery());
            
            for(Order order : (List<Order>) Trigger.new) {  
                if((order.RecordTypeId == OrderHelper.RT_ID_PROSERV || order.RecordTypeId == OrderHelper.RT_ID_CC_PROSERV) && order.Type == OrderHelper.TYPE_INITIAL_ORDER ) {
                    if(ordersMap.containsKey(order.Id) && ordersMap.get(order.Id)?.Quote != null && QuoteHelper.isProServOrCCProServ(ordersMap.get(order.Id).Quote)) {
                        proservProjectsToInsert.add(ProServProjectObj.createProject(order));
                    }
                }
            }

            insert proservProjectsToInsert;
        }
    }

    public class CreateSupportEntitlementsRecords extends Triggers.TriggerHandlerBase {
        override public void handle() {
            if (System.isFuture()) {
                return;
            }
            Set<Id> orderIds = Trigger.newMap.keySet();

            if (Limits.getLimitQueueableJobs() > Limits.getQueueableJobs()) {
                this.enqueueCreateSupportEntitlementsJob(orderIds);
            } else {
                this.publishCreateSupportEntitlementsEvent(orderIds);
            }
        }

        private void enqueueCreateSupportEntitlementsJob(Set<Id> orderIds) {
            QueueableBase.enqueJob('CreateSupportEntitlements', new List<Id>(orderIds));
        }

        private void publishCreateSupportEntitlementsEvent(Set<Id> orderIds) {
            List<CreateSupportEntitlements__e> events = new List<CreateSupportEntitlements__e>();

            for (Id orderId : orderIds) {
                events.add(
                    new CreateSupportEntitlements__e(
                        OrderId__c = String.valueOf(orderId)
                    )
                );
            }

            PlatformEvents.publishPlatformEvent(events, 'OrderTriggerHelper.CreateSupportEntitlementsRecords');
        }
    }
}