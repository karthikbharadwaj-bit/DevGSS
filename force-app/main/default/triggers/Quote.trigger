trigger Quote on Quote (
        before insert,
        before update,
        before delete,
        after insert,
        after update,
        after delete) {

    ByPassTrigger__c bypassTrigger = ByPassTrigger__c.getInstance();
    if ((bypassTrigger != null && bypassTrigger.Bypass_Quote_Trigger__c == true) || TriggerHandler.BY_PASS_QUOTE_ON_UPDATE) {
        System.debug('$$$ ByPassTrigger__c Active For Quote $$$');
        return;
    }

    new Triggers()
        .bind(Triggers.Evt.beforeinsert, new QuoteTriggerHelper.CheckIfQuotingIsAvailableForBrand())
        .bind(Triggers.Evt.beforeinsert, new QuoteTriggerHelper.SalesAgreementBefore())
        .bind(Triggers.Evt.beforeinsert, new QuoteTriggerHelper.SetFirstQuotePrimary())
        .bind(Triggers.Evt.beforeinsert, new QuoteTriggerHelper.SetDefaultLineItems())
        .bind(Triggers.Evt.beforeinsert, new QuoteTotals.PopulateEntlTotalsOnInsert())
        .bind(Triggers.Evt.beforeinsert, new OpportunityTotals.OpportunityTotalsOnQuoteChange())
        .bind(Triggers.Evt.afterinsert, new QuoteTriggerHelper.SendEmailToCESE())
        .bind(Triggers.Evt.afterinsert, new QuoteTriggerHelper.SendEmailsOnIgniteQuoteCreation())
        .bind(Triggers.Evt.afterinsert, new ObjectMonitoringHelper.MonitoringAddObject(Quote.class.getName()))

        .bind(Triggers.Evt.afterinsert, new QuoteTriggerHelper.SalesAgreementAfter())
        .bind(Triggers.Evt.afterinsert, new QuoteTriggerHelper.SetDefaultLineItems())
        .bind(Triggers.Evt.afterinsert, new QuoteTriggerHelper.UpdatePrimaryQuoteOnOpportunity())
        .bind(Triggers.Evt.afterinsert, new QuoteTriggerHelper.SetProServQuote())
        .bind(Triggers.Evt.afterinsert, new QuoteTriggerHelper.AdjustTechQuoteTermsOnMasterUpdate())

        .bind(Triggers.Evt.beforeupdate, new QuoteTriggerHelper.ManageQuotesMapStatic())
        .bind(Triggers.Evt.beforeupdate, new QuoteTriggerHelper.CheckIfQuotingIsAvailableForBrand())
        .bind(Triggers.Evt.beforeupdate, new QuoteTriggerHelper.HandlePOCQuoteStatus())
        .bind(Triggers.Evt.beforeupdate, new QuoteTriggerHelper.SetApprovalType())
        .bind(Triggers.Evt.beforeupdate, new QuoteTriggerHelper.SalesAgreementBefore())
        .bind(Triggers.Evt.beforeupdate, new QuoteTriggerHelper.SetDefaultLineItems())
        .bind(Triggers.Evt.beforeupdate, new QuoteTriggerHelper.SetInvalidNumberSetups())
        .bind(Triggers.Evt.beforeupdate, new QuoteTriggerHelper.CalculateFreeValues())
        .bind(Triggers.Evt.beforeupdate, new QuoteTriggerHelper.PopulateApprovalHistory())
        .bind(Triggers.Evt.beforeupdate, new QuoteTriggerHelper.SetProServQuote())
        .bind(Triggers.Evt.beforeupdate, new QuoteTriggerHelper.MoveAcceptedQuoteToActiveStatus())
        .bind(Triggers.Evt.beforeupdate, new QuoteTriggerHelper.SetIsCLMChangeOrderFormRequired())
        .bind(Triggers.Evt.beforeupdate, new QuoteTriggerHelper.SalesAgreementStatusChangeValidation())
        
        .bind(Triggers.Evt.afterupdate, new QuoteTriggerHelper.SetPrimaryQuote())
        .bind(Triggers.Evt.afterupdate, new QuoteTriggerHelper.SalesAgreementAfter())
        .bind(Triggers.Evt.afterupdate, new QuoteTriggerHelper.SetDefaultLineItems())
        .bind(Triggers.Evt.afterupdate, new QuoteTriggerHelper.HandleAgreementPresented())
        .bind(Triggers.Evt.afterupdate, new QuoteTriggerHelper.HandleAgreementActiveExecuted())
        .bind(Triggers.Evt.afterupdate, new QuoteTriggerHelper.PopulateApprovedFieldsOnQli())
        .bind(Triggers.Evt.afterupdate, new QuoteTriggerHelper.UpdateApprovalAfterQuoteActivation())
        .bind(Triggers.Evt.afterupdate, new OpportunityTotals.OpportunityTotalsOnQuoteChange())
        .bind(Triggers.Evt.afterupdate, new QuoteTriggerHelper.CreateProservCase())
        .bind(Triggers.Evt.afterupdate, new QuoteTriggerHelper.QuoteAfterUpdate())
        .bind(Triggers.Evt.afterupdate, new QuoteTriggerHelper.UpdatePrimaryQuoteOnOpportunity())
        .bind(Triggers.Evt.afterupdate, new QuoteTriggerHelper.SetProServQuote())
        .bind(Triggers.Evt.afterupdate, new ObjectMonitoringHelper.MonitoringAddObject(Quote.class.getName()))
        .bind(Triggers.Evt.afterupdate, new QuoteTriggerHelper.UpdateParentOpportunityFieldAfterUpdateQuote())
        .bind(Triggers.Evt.afterupdate, new QuoteTriggerHelper.SyncDataFromMasterQuote())
        .bind(Triggers.Evt.afterupdate, new QuoteTriggerHelper.AdjustTechQuoteTermsOnMasterUpdate())
        .bind(Triggers.Evt.afterupdate, new QuoteTriggerHelper.SyncTechnicalQuotesOnMasterQuoteActivation())
        .bind(Triggers.Evt.afterupdate, new QuoteTriggerHelper.SendEmailsOnApprovalStatusChangeForPRM())
        .bind(Triggers.Evt.afterupdate, new QuoteTriggerHelper.DeleteRelatedAssignments())
        .bind(Triggers.Evt.afterupdate, new QuoteTriggerHelper.UpdateServiceInfo())
        .bind(Triggers.Evt.afterupdate, new QuoteTriggerHelper.SendEmailToSSE())
        .bind(Triggers.Evt.afterupdate, new QuoteTriggerHelper.SendEmailToCESE())

        .bind(Triggers.Evt.beforedelete, new QuoteTriggerHelper.CollectDataBeforeDelete())
        .bind(Triggers.Evt.beforedelete, new QuoteTriggerHelper.DeleteRelatedEntitlements())
        .bind(Triggers.Evt.beforedelete, new QuoteTriggerHelper.ValidateQuoteBeforeDelete())
        .bind(Triggers.Evt.beforedelete, new QuoteTriggerHelper.UpdateParentOpportunityFieldAfterDeleteQuote())
        .bind(Triggers.Evt.afterdelete, new QuoteTriggerHelper.SetLastModifiedPrimaryOnDeletingPrimaryQuote())
        .bind(Triggers.Evt.afterdelete, new QuoteTriggerHelper.SalesAgreementAfter())
        .bind(Triggers.Evt.afterdelete, new QuoteTriggerHelper.UpdateOpportunityAfterQuoteDelete())
        .bind(Triggers.Evt.afterdelete, new OpportunityTotals.OpportunityTotalsOnQuoteChange())
        .bind(Triggers.Evt.afterdelete, new ObjectMonitoringHelper.MonitoringAddObject(Quote.class.getName()))

        .manage();
}