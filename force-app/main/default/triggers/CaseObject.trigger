trigger CaseObject on Case (before insert, before update, after insert, after update, after delete) {

    ByPassTrigger__c bypassTrigger = ByPassTrigger__c.getInstance();
    if (bypassTrigger != null && bypassTrigger.Bypass_Case_Trigger__c == true) {
        System.debug('$$$ ByPassTrigger__c Active For Case Credit $$$');
        return;
    }

    new Triggers()
        .bind(Triggers.Evt.beforeinsert, new CaseTriggerHandler.AssignOwnerForClosedLoopRelationshipCases())
        .bind(Triggers.Evt.beforeinsert, new CaseTriggerHandler.ValidateCaseStatusForDealAndOrderSupportRT())
        .bind(Triggers.Evt.beforeinsert, new CaseTriggerHandler.PopulateFields())
        .bind(Triggers.Evt.beforeinsert, new CaseTriggerHandler.ChangeOwnerForProfessionalServices())
        .bind(Triggers.Evt.beforeinsert, new CaseTriggerHandler.ChangeRecordType())
        .bind(Triggers.Evt.beforeinsert, new CaseTriggerHandler.PreventCaseCreation())
        .bind(Triggers.Evt.beforeinsert, new CaseTriggerHandler.PopulateTotalMRRtoSurveyDateFieldOnCreation())
        .bind(Triggers.Evt.beforeinsert, new CaseTriggerHandler.BasicHandler())
        .bind(Triggers.Evt.beforeinsert, new CaseTriggerHandler.EntitleAssignmentOncase())
        .bind(Triggers.Evt.beforeinsert, new CaseTriggerHandler.SetDateStarted())
        .bind(Triggers.Evt.beforeinsert, new CaseTriggerHandler.PopulateCaseFieldsWithContactFields())
        .bind(Triggers.Evt.beforeinsert, new CaseTriggerHandler.UpdateEscalationActualDate())
        .bind(Triggers.Evt.beforeinsert, new CaseTriggerHandler.UpdateInternalBusinessServiceCaseDescription())
        .bind(Triggers.Evt.beforeinsert, new CaseTriggerHandler.RoundRobinAssignment())

        .bind(Triggers.Evt.afterinsert, new CaseTriggerHandler.CreateCaseContactAttempts())
        .bind(Triggers.Evt.afterinsert, new CaseTriggerHandler.CloseCaseMilestone())

        .bind(Triggers.Evt.beforeupdate, new CaseTriggerHandler.EntitleAssignmentOncase())
        .bind(Triggers.Evt.beforeupdate, new CaseTriggerHandler.SetDateStarted())
        .bind(Triggers.Evt.beforeupdate, new CaseTriggerHandler.PopulateCaseFieldsWithContactFields())
        .bind(Triggers.Evt.beforeupdate, new CaseTriggerHandler.UpdateEscalationActualDate())
        .bind(Triggers.Evt.beforeupdate, new CaseTriggerHandler.ValidateCaseStatusForDealAndOrderSupportRT())
        .bind(Triggers.Evt.beforeupdate, new CaseTriggerHandler.PopulateFields())
        .bind(Triggers.Evt.beforeupdate, new CaseTriggerHandler.ValidateCaseFieldsForProductIssues())
        .bind(Triggers.Evt.beforeupdate, new CaseTriggerHandler.UpdateAddressAndContactInfoFieldsForTelusBrand())
        .bind(Triggers.Evt.beforeupdate, new CaseTriggerHandler.ValidateFieldsForPortingCase())
        .bind(Triggers.Evt.beforeupdate, new CaseTriggerHandler.PopulateContactForPortingCase())
        .bind(Triggers.Evt.beforeupdate, new CaseTriggerHandler.UpdateRelatedOrders())
        .bind(Triggers.Evt.beforeupdate, new CaseTriggerHandler.UpdateInternalBusinessServiceCaseDescription())
        .bind(Triggers.Evt.beforeupdate, new CaseTriggerHandler.RoundRobinAssignment())
        
        .bind(Triggers.Evt.afterupdate, new CaseTriggerHandler.CloseCaseMilestone())
        .bind(Triggers.Evt.afterupdate, new CaseTriggerHandler.ValidateOnAfterUpdateEvent())
        .bind(Triggers.Evt.afterupdate, new CaseTriggerHandler.ValidateByPassCase())
        .bind(Triggers.Evt.afterupdate, new CaseTriggerHandler.CloseCaseAssignedMilestone())
        .bind(Triggers.Evt.afterupdate, new CaseTriggerHandler.AutoSyncWithNGBS())
        .manage();

    if (TriggerHandler.BY_PASS_CASE_ON_UPDATE
        || TriggerHandler.BY_PASS_CASE_ON_INSERT
        || (TriggerHandler.BY_PASS_BEFORE && Trigger.isBefore)
        || (TriggerHandler.BY_PASS_AFTER && Trigger.isAfter)
    ) {
        return;
    }
    if (!TriggerHandler.BY_PASS_AFTER && Trigger.isAfter) {
        TriggerHandler.BY_PASS_AFTER = true;
    }

    if (!TriggerHandler.BY_PASS_BEFORE && Trigger.isBefore) {
        TriggerHandler.BY_PASS_BEFORE = true;
    }

    new Triggers()
        .bind(Triggers.Evt.beforeinsert, new CaseTriggerHandler.CommonHandlers())
        .bind(Triggers.Evt.beforeinsert, new CaseTriggerHandler.AttachContactInCases())
        .bind(Triggers.Evt.beforeinsert, new CaseTriggerHandler.MapContactOnTelusSharedCases())
        .bind(Triggers.Evt.beforeinsert, new CaseTriggerHandler.WebCaseRouting())
        .bind(Triggers.Evt.beforeinsert, new CaseTriggerHandler.CaseCreationOnPRM())
        .bind(Triggers.Evt.beforeinsert, new CaseTriggerHandler.InsertManagerFieldForSupportRecordType())
        .bind(Triggers.Evt.beforeinsert, new CaseTriggerHandler.CalculateBalanceAndPortOutStatus())
        .bind(Triggers.Evt.beforeinsert, new CaseTriggerHandler.PortOutCloseForCase())
        .bind(Triggers.Evt.beforeinsert, new CaseTriggerHandler.HandleEngageDigitalCaseUpdates())
        .bind(Triggers.Evt.beforeinsert, new CaseTriggerHandler.UpdateCaseOwnerAndManagerDetails())
        .bind(Triggers.Evt.beforeinsert, new CaseTriggerHandler.ProcessT1ShippingAndUpdateDetails())
        .bind(Triggers.Evt.beforeinsert, new CaseTriggerHandler.HandleCaseForPortingESB())
        .bind(Triggers.Evt.beforeinsert, new CaseTriggerHandler.AssignUserDetailsToCase())
        .bind(Triggers.Evt.beforeinsert, new CaseTriggerHandler.PopulateCaseDates())

        .bind(Triggers.Evt.afterinsert, new CaseTriggerHandler.CheckForEmail())
        .bind(Triggers.Evt.afterinsert, new CaseTriggerHandler.HandleCaseForTelus())
        .bind(Triggers.Evt.afterinsert, new CaseTriggerHandler.CalculateGraduationCompletionRateOverCase())
        .bind(Triggers.Evt.afterinsert, new CaseTriggerHandler.CreateUpdateJuraIssue())
        .bind(Triggers.Evt.afterinsert, new CaseTriggerHandler.CreateCaseFeedForParentCase())
        .bind(Triggers.Evt.afterinsert, new CaseTriggerHandler.MakeCallOutToSCP())

        .bind(Triggers.Evt.beforeupdate, new CaseTriggerHandler.CommonHandlers())
        .bind(Triggers.Evt.beforeupdate, new CaseTriggerHandler.InsertManagerFieldForSupportRecordType())
        .bind(Triggers.Evt.beforeupdate, new CaseTriggerHandler.PortOutCloseForCase())
        .bind(Triggers.Evt.beforeupdate, new CaseTriggerHandler.HandleEngageDigitalCaseUpdates())
        .bind(Triggers.Evt.beforeupdate, new CaseTriggerHandler.UpdateCaseOwnerAndManagerDetails())
        .bind(Triggers.Evt.beforeupdate, new CaseTriggerHandler.AssignUserDetailsToCase())
        .bind(Triggers.Evt.beforeupdate, new CaseTriggerHandler.ChangeCaseOwnerForSupportT1User())
        .bind(Triggers.Evt.beforeupdate, new CaseTriggerHandler.PopulateCasePortingFields())
        .bind(Triggers.Evt.beforeupdate, new CaseTriggerHandler.CreateSurveysForPortingInRTCases())
        .bind(Triggers.Evt.beforeupdate, new CaseTriggerHandler.CreateSurveysForSupportCSATRTCases())
        .bind(Triggers.Evt.beforeupdate, new CaseTriggerHandler.CreateSurveysForITRTCases())
        .bind(Triggers.Evt.beforeupdate, new CaseTriggerHandler.CreateSurveysForBizServRTCases())
        .bind(Triggers.Evt.beforeupdate, new CaseTriggerHandler.CreateSurveysForSupportMedalliaCases())
        .bind(Triggers.Evt.beforeupdate, new CaseTriggerHandler.SendMedalliaInvitation())
        .bind(Triggers.Evt.beforeupdate, new CaseTriggerHandler.UpdateSupportCNRCases())
        .bind(Triggers.Evt.beforeupdate, new CaseTriggerHandler.UpdateDescriptionCodeForCases())
        .bind(Triggers.Evt.beforeupdate, new CaseTriggerHandler.PopulateCaseDates())

        .bind(Triggers.Evt.afterupdate, new CaseTriggerHandler.CheckForEmail())
        .bind(Triggers.Evt.afterupdate, new CaseTriggerHandler.HandleCaseForTelus())
        .bind(Triggers.Evt.afterupdate, new CaseTriggerHandler.CalculateGraduationCompletionRateOverCase())
        .bind(Triggers.Evt.afterupdate, new CaseTriggerHandler.CreateUpdateJuraIssue())
        .bind(Triggers.Evt.afterupdate, new CaseTriggerHandler.ShareAttachments())

        .bind(Triggers.Evt.afterdelete, new CaseTriggerHandler.CalculateGraduationCompletionRateOverCase())
        .manage();
}