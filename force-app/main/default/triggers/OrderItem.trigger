trigger OrderItem on OrderItem (
	before insert,
	before update,
	before delete,
	after insert,
	after update,
	after delete,
	after undelete) {

		new Triggers()

			.bind(Triggers.Evt.beforeinsert, new OrderItemTriggerHelper.HandleZeroQuantity())
			.bind(Triggers.Evt.beforeupdate, new OrderItemTriggerHelper.HandleZeroQuantity())
			.bind(Triggers.Evt.beforeupdate, new OrderItemTriggerHelper.PopulateOrderFields())
			.bind(Triggers.Evt.beforedelete, new OrderItemTriggerHelper.PopulateOrderFields())

			.bind(Triggers.Evt.afterinsert, new OrderItemTriggerHelper.NotifyProserv())
			.bind(Triggers.Evt.afterinsert, new OrderItemTriggerHelper.NotifyCcDesk())
			.bind(Triggers.Evt.afterupdate, new OrderItemTriggerHelper.CalcEstimatedProServMRR())
			.bind(Triggers.Evt.afterdelete, new OrderItemTriggerHelper.CalcEstimatedProServMRR())
			.bind(Triggers.Evt.afterinsert, new OrderItemTriggerHelper.UpdatePhaseLineItem())
			.bind(Triggers.Evt.afterinsert, new OrderItemTriggerHelper.AddProductDetail())
			.bind(Triggers.Evt.afterinsert, new OrderItemTriggerHelper.CalculateTotalsOnOrder())
	        .manage();
}