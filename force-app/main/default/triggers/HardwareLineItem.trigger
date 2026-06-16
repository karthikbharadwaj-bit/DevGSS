trigger HardwareLineItem on Hardware_Line_Item__c (
	before insert, 
	before update, 
	before delete,
	after update,
	after insert) {

	System.debug('in HardwareLineItem trigger. Trigger.new >>> ' + Trigger.new);
	System.debug('in HardwareLineItem trigger. Trigger.old >>> ' + Trigger.old);

	new Triggers()
		.bind(Triggers.Evt.beforeinsert, new HardwareLineItemTriggerHandler.HandleInsertUpdate())
		.bind(Triggers.Evt.beforeinsert, new HardwareLineItemTriggerHandler.ValidateOrderItem())

		.bind(Triggers.Evt.afterinsert, new HardwareLineItemTriggerHandler.PopulatePhaseFields())

		.bind(Triggers.Evt.beforeupdate, new HardwareLineItemTriggerHandler.HandleInsertUpdate())

		.bind(Triggers.Evt.afterupdate, new HardwareLineItemTriggerHandler.PopulatePhaseFields())
		
		.bind(Triggers.Evt.beforedelete, new HardwareLineItemTriggerHandler.HandleDelete())
	.manage();

}