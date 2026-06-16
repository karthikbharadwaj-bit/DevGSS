trigger PhaseTrigger on Phase__c (before insert, before update, before delete, after insert, after update) {

	new Triggers()
		.bind(Triggers.Evt.beforeinsert, new PhaseTriggerHandler.PrepopulateFields())
		.bind(Triggers.Evt.beforeinsert, new PhaseTriggerHandler.PhaseBefore())

		.bind(Triggers.Evt.afterinsert, new PhaseTriggerHandler.PopulateMaxPhaseNumberOnOrder())
		.bind(Triggers.Evt.afterinsert, new PhaseTriggerHandler.PhaseAfter())
		.bind(Triggers.Evt.afterinsert, new PhaseTriggerHandler.LockOrder())
		
		.bind(Triggers.Evt.beforeupdate, new PhaseTriggerHandler.ValidateCompletedOrder())
		.bind(Triggers.Evt.beforeupdate, new PhaseTriggerHandler.PopulatePhaseAndOrderFields())
		.bind(Triggers.Evt.beforeupdate, new PhaseTriggerHandler.PhaseBefore())

        .bind(Triggers.Evt.beforeinsert, new PhaseTriggerHandler.BrandPartnerPopulationHandler())
        .bind(Triggers.Evt.beforeupdate, new PhaseTriggerHandler.BrandPartnerPopulationHandler())

		.bind(Triggers.Evt.afterupdate, new PhaseTriggerHandler.PopulateMaxPhaseNumberOnOrder())		
		.bind(Triggers.Evt.afterupdate, new PhaseTriggerHandler.LockOrder())
		.bind(Triggers.Evt.afterupdate, new PhaseTriggerHandler.PopulateAssetDeliveredQuantity())

		.bind(Triggers.Evt.beforedelete, new PhaseTriggerHandler.PopulateMaxPhaseNumberOnOrder())
		.bind(Triggers.Evt.beforedelete, new PhaseTriggerHandler.ValidateCompletedOrder())
		.bind(Triggers.Evt.beforedelete, new PhaseTriggerHandler.ValidatePermissionToDeletePhase())
		.bind(Triggers.Evt.beforedelete, new PhaseTriggerHandler.DeleteRelatedPLI())
  .manage();

}