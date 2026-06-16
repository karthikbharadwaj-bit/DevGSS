trigger QuoteLineItem on QuoteLineItem (
	before insert,
	before update,
	before delete,
	after insert,
	after update,
	after delete) {
if(!TriggerHandler.BY_PASS_QUOTE_ON_CONVERT){
		new Triggers()

			.bind(Triggers.Evt.beforedelete, new QuoteLineItemTriggerHelper.ManageQuotesMapStatic())
			.bind(Triggers.Evt.beforeupdate, new QuoteLineItemTriggerHelper.ManageQuotesMapStatic())
			.bind(Triggers.Evt.beforeinsert, new QuoteLineItemTriggerHelper.ManageQuotesMapStatic())

			.bind(Triggers.Evt.beforedelete, new QuoteLineItemTriggerHelper.ValidateIvinexQuoteLineItem())

			.bind(Triggers.Evt.beforeupdate, new QuoteLineItemTriggerHelper.ValidateQuoteLineItem())
			.bind(Triggers.Evt.beforeinsert, new QuoteLineItemTriggerHelper.ValidateQuoteLineItem())

			.bind(Triggers.Evt.beforeupdate, new QuoteLineItemTriggerHelper.PopulateProductsMap())
			.bind(Triggers.Evt.beforeinsert, new QuoteLineItemTriggerHelper.PopulateProductsMap())

			.bind(Triggers.Evt.beforeupdate, new QuoteLineItemTriggerHelper.ApplyQuoteLineItemRestrictions())
			.bind(Triggers.Evt.beforeinsert, new QuoteLineItemTriggerHelper.ApplyQuoteLineItemRestrictions())

			.bind(Triggers.Evt.beforedelete, new QuoteLineItemTriggerHelper.UpdateQuoteOnQuoteLineItemUpdate())
			.bind(Triggers.Evt.beforeupdate, new QuoteLineItemTriggerHelper.UpdateQuoteOnQuoteLineItemUpdate())
			.bind(Triggers.Evt.afterinsert, new QuoteLineItemTriggerHelper.UpdateQuoteOnQuoteLineItemUpdate())
			.bind(Triggers.Evt.afterupdate, new QuoteLineItemTriggerHelper.UpdateQuoteOnQuoteLineItemUpdate())
			.bind(Triggers.Evt.afterdelete, new QuoteLineItemTriggerHelper.UpdateQuoteOnQuoteLineItemUpdate())

			.bind(Triggers.Evt.beforeupdate, new QuoteLineItemTriggerHelper.SetIsHiddenLicense())
			.bind(Triggers.Evt.beforeinsert, new QuoteLineItemTriggerHelper.SetIsHiddenLicense())

            .bind(Triggers.Evt.beforeupdate, new QuoteLineItemTriggerHelper.UpdateSortOrder())
            .bind(Triggers.Evt.beforeinsert, new QuoteLineItemTriggerHelper.UpdateSortOrder())

			.bind(Triggers.Evt.beforeupdate, new QuoteLineItemTriggerHelper.CountPerecentageFromCurrencyDiscount())
			.bind(Triggers.Evt.beforeinsert, new QuoteLineItemTriggerHelper.CountPerecentageFromCurrencyDiscount())

			.bind(Triggers.Evt.beforeinsert, new QuoteLineItemTotals.PopulateDiscountAndEffectivePrice())
			.bind(Triggers.Evt.beforeupdate, new QuoteLineItemTotals.PopulateDiscountAndEffectivePrice())

			.bind(Triggers.Evt.afterinsert, new QuoteLineItemTriggerHelper.SetQuoteApprovalType())
			.bind(Triggers.Evt.afterupdate, new QuoteLineItemTriggerHelper.SetQuoteApprovalType())
			.bind(Triggers.Evt.beforedelete, new QuoteLineItemTriggerHelper.SetQuoteApprovalType())

			.bind(Triggers.Evt.beforeinsert, new QuoteLineItemTriggerHelper.PopulateNewQuantity())
			.bind(Triggers.Evt.beforeupdate, new QuoteLineItemTriggerHelper.PopulateNewQuantity())

			.bind(Triggers.Evt.beforeinsert, new QuoteLineItemTotals.PopulateQLITotals())
			.bind(Triggers.Evt.beforeupdate, new QuoteLineItemTotals.PopulateQLITotals())

			.bind(Triggers.Evt.beforedelete, new QuoteLineItemTriggerHelper.RemoveAreCodeLineItems())
			.bind(Triggers.Evt.beforedelete, new QuoteLineItemTriggerHelper.RemoveAssignmentLineItems())
			.bind(Triggers.Evt.beforedelete, new QuoteLineItemTriggerHelper.RemoveCustomAddressAssignments())

			.bind(Triggers.Evt.beforeupdate, new QuoteLineItemTriggerHelper.SetChargeTerms())
			.bind(Triggers.Evt.beforeinsert, new QuoteLineItemTriggerHelper.SetChargeTerms())

			.bind(Triggers.Evt.afterupdate, new QuoteLineItemTriggerHelper.UpdateServiceInfo())

			// To reduce the number of requests, static structures(map) are used:
			// in the case when several handlers are executed and dml operations are present in more than one handler
			// (for example deleting QuoteLineItems in ApplyQuoteLineItemFees() and CheckNumbersOfExtendedEnterpriseSupport()) -
			// instead of executing the operations inside handler, objects are placed in a static structure
			// and the _last_ handler performs a dml operation on the structure.

			// TODO: find the way how to determine execution order inside triggerHandler
			// (in this case we can automatically determine which of the handlers(potentially last handler) should execute dml over the static structure)

			.manage();
		}
}
// .bind(Triggers.Evt.beforeinsert, new QuoteLineItemTriggerHelper.ApplyMonthlyContractDiscount())
//