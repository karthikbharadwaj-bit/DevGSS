trigger SuborderLineItemTrigger on SuborderLineItem__c (after insert, after update, after delete) {

	new Triggers()

        .bind(Triggers.Evt.afterinsert, new SuborderLineItemTriggerHandler.PopulateSuborderSumOfAllItems())
        .bind(Triggers.Evt.afterupdate, new SuborderLineItemTriggerHandler.PopulateSuborderSumOfAllItems())
        .bind(Triggers.Evt.afterdelete, new SuborderLineItemTriggerHandler.PopulateSuborderSumOfAllItems())

        .bind(Triggers.Evt.afterinsert, new SuborderLineItemTriggerHandler.PopulateOrderSubTotals())
        .bind(Triggers.Evt.afterupdate, new SuborderLineItemTriggerHandler.PopulateOrderSubTotals())
        .bind(Triggers.Evt.afterdelete, new SuborderLineItemTriggerHandler.PopulateOrderSubTotals())

  .manage();

}