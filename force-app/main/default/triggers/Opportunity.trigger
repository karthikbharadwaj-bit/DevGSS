/*************************************************
Trigger on Opportunity object
Before Insert: Set Owner Manger/Last Touched/Responded fields.
               Enforce activepipe limit (require that user have an employee record with division field filled in)
Before Update: Update Owner Manger/Last Touched/Responded fields.
               Enforce activepipe limit.
               Actions if downgraded: Set date, create cancelled trial based on reason
               Actions if closed:  Set date, create and send sales survey.
               Update 12 Month QC.
               Check warm transfer box for implemenation creation
/************************************************/

trigger Opportunity on Opportunity(before insert, before update, before delete, after insert, after update) {
    if (TriggerHandler.BY_PASS_OPPORTUNITY_ON_CONVERT != true) {
        ByPassTrigger__c bypassTrigger = ByPassTrigger__c.getInstance();
        if (bypassTrigger != null && bypassTrigger.Bypass_Opportunity_Trigger__c == true) {
            System.debug('$$$ ByPassTrigger__c Active For Opportunity $$$');
            return;
        }

        new Triggers()
            .bind(Triggers.Evt.beforeinsert, new OpportunityTriggerHelperRefactored.ManageAccountMapStatic())
            .bind(Triggers.Evt.beforeupdate, new OpportunityTriggerHelperRefactored.ManageAccountMapStatic())
            .bind(Triggers.Evt.afterdelete, new OpportunityTriggerHelperRefactored.ManageAccountMapStatic())
            .bind(Triggers.Evt.afterupdate, new OpportunityTriggerHelperRefactored.ManageAfterUpdateStatic())
            .bind(Triggers.Evt.beforeinsert, new OpportunityTriggerHelperRefactored.ForecastedAmountsHelper())
            .bind(Triggers.Evt.beforeinsert, new OpportunityTriggerHelperRefactored.PerformWorkFlowActions())
            .bind(Triggers.Evt.beforeinsert, new OpportunityTriggerHelperRefactored.OpportunityBeforeUpdateInsert())
            .bind(Triggers.Evt.beforeinsert, new OpportunityTriggerHelperRefactored.SetOpportunityCampaign())
            .bind(Triggers.Evt.beforeinsert, new OpportunityTriggerHelperRefactored.UpdateCloseDateCounter())
            .bind(Triggers.Evt.beforeinsert, new OpportunityTriggerHelperRefactored.SetCLMAccess())
            .bind(Triggers.Evt.beforeinsert, new OpportunityTriggerHelperRefactored.addWhiteSpace())
            .bind(Triggers.Evt.beforeinsert, new OpportunityTriggerHelperRefactored.PopulateSlapFiveAdvocateId())
            .bind(Triggers.Evt.afterinsert, new OpportunityTriggerHelperRefactored.OpportunityAfterInsert())
            .bind(Triggers.Evt.afterinsert, new OpportunityTriggerHelperRefactored.CreateOpportunityContactRole())
            .bind(Triggers.Evt.afterinsert, new OpportunityTriggerHelperRefactored.CreateKYCApprovalForIndiaOffice())
            .bind(Triggers.Evt.afterinsert, new OpportunityTriggerHelperRefactored.CreateSalesTaxExemptionApproval())
            .bind(Triggers.Evt.afterinsert, new OpportunityTriggerHelperRefactored.SendAvisoPlatformEvents())
            .bind(Triggers.Evt.afterinsert, new OpportunityTriggerHelperRefactored.IdentifyImmediateNextStepUsingAI())
            .bind(Triggers.Evt.beforeupdate, new OpportunityTriggerHelperRefactored.ForecastedAmountsHelper())
            .bind(Triggers.Evt.beforeupdate, new OpportunityTriggerHelperRefactored.PerformWorkFlowActions())
            .bind(Triggers.Evt.beforeupdate, new OpportunityTriggerHelperRefactored.StageValidation())
            .bind(Triggers.Evt.beforeupdate, new OpportunityTriggerHelperRefactored.OpportunityBeforeUpdateInsert())
            .bind(
                Triggers.Evt.beforeupdate,
                new OpportunityTriggerHelperRefactored.PopulateProvisionedAndSubStageFields()
            )
            .bind(Triggers.Evt.beforeupdate, new OpportunityTriggerHelperRefactored.ProcessConfirmAndCloseFlow())
            .bind(Triggers.Evt.beforeupdate, new OpportunityTriggerHelperRefactored.UpdateCloseDateCounter())
            .bind(Triggers.Evt.beforeupdate, new OpportunityTriggerHelperRefactored.RecallApprovalRequests())
            .bind(Triggers.Evt.beforeupdate, new OpportunityTriggerHelperRefactored.ValidateLBOOpportunityOnClose())
            .bind(Triggers.Evt.beforeupdate, new OpportunityTriggerHelperRefactored.ValidateVerizonOpptyClose())
            .bind(Triggers.Evt.beforeupdate, new OpportunityTriggerHelperRefactored.UpdateDealsDeskStage())
            /* CRM-5079 - Added as Part of EU Data Privacy Project to restrict changing the Account Owner when the Record is of EU*/
            .bind(Triggers.Evt.beforeupdate, new OpportunityTriggerHelperRefactored.CheckEUDataPrivacy())
            .bind(Triggers.Evt.afterupdate, new OpportunityTriggerHelperRefactored.CallSyncWithNGBSForLBOAccounts())
            .bind(Triggers.Evt.afterupdate, new OpportunityTriggerHelperRefactored.OpportunityAfterUpdate())
            .bind(Triggers.Evt.afterupdate, new OpportunityTriggerHelperRefactored.AutoGenerateOrders())
            .bind(Triggers.Evt.afterupdate, new OpportunityTriggerHelperRefactored.GenerateAssistanceCases())
            .bind(Triggers.Evt.afterupdate, new OpportunityTriggerHelperRefactored.UnParentChildQuotes())
            .bind(Triggers.Evt.afterupdate, new OpportunityTriggerHelperRefactored.SyncPaymentInfo())
            .bind(Triggers.Evt.afterUpdate, new OpportunityTriggerHelperRefactored.UpdateContactLogic())
            .bind(Triggers.Evt.afterUpdate, new OpportunityTriggerHelperRefactored.CopyFieldsToTechnicalOppty())
            .bind(Triggers.Evt.afterUpdate, new OpportunityTriggerHelperRefactored.CreateOrderAfterClosingOpp())
            .bind(Triggers.Evt.afterUpdate, new OpportunityTriggerHelperRefactored.DeactivatePackageAndOrderOnClose())
            .bind(Triggers.Evt.afterUpdate, new OpportunityTriggerHelperRefactored.SendAvisoPlatformEvents())
            .bind(Triggers.Evt.beforedelete, new OpportunityTriggerHelperRefactored.ValidateOpportunityBeforeDelete())
            /* CRM-5079 - Added as Part of EU Data Privacy Project to restrict changing the Account Owner when the Record is of EU*/
        	//.bind(Triggers.Evt.beforeupdate, new OpportunityTriggerHelperRefactored.CheckEUDataPrivacy()) //Commented as part of ITPMO-3741
        	.bind(Triggers.Evt.afterupdate, new OpportunityTriggerHelperRefactored.AdjustDFREstimatedARRPipeline())
            .bind(Triggers.Evt.afterupdate, new OpportunityTriggerHelperRefactored.IdentifyImmediateNextStepUsingAI())
            .manage();

        //For Avaya Mappings
        if (Trigger.isBefore && (Trigger.isUpdate || Trigger.isInsert)) {
            try {
                for (Opportunity oppObj : Trigger.new) {
                    if (oppObj.Avaya_Partnership_Opportunity__c) {
                        Partner_OpportunityTrgHelper.oppBeforeMappings(oppObj, Trigger.oldMap);
                    }
                }
            } catch (exception ex) {
                System.debug('Exception at Line : ' + ex.getLineNumber() + ' Message :' + ex.getMessage());
            }
        }
        //On Change of Cloud Specialist,recalculate sharing
        if (Trigger.isAfter && (Trigger.isUpdate || Trigger.isInsert)) {
            Boolean isAvayaOpp = false;
            try {
                for (Opportunity oppObj : Trigger.new) {
                    if (oppObj.Avaya_Partnership_Opportunity__c) {
                        isAvayaOpp = true;
                    }
                }
                if (isAvayaOpp) {
                    Partner_OpportunityTrgHelper.oppAfterMappings(Trigger.new, Trigger.oldMap);
                }
            } catch (exception ex) {
                System.debug('Exception at Line : ' + ex.getLineNumber() + ' Message :' + ex.getMessage());
            }
        }
    }

}