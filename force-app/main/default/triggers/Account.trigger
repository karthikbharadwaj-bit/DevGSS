trigger Account on Account (
    before insert,
    before update,
    before delete,
    after insert,
    after update,
    after delete) {

    ByPassTrigger__c bypassTrigger = ByPassTrigger__c.getInstance();
    if (bypassTrigger != null && bypassTrigger.Bypass_Account_Trigger__c == true) {
        System.debug('$$$ ByPassTrigger__c Active For Account $$$');
        return;
    }

    Triggers t = new Triggers();
    t
        .bind(Triggers.Evt.beforeinsert, new AccountTriggerHandler.ManageAccountMapStatic())
        .bind(Triggers.Evt.beforeupdate, new AccountTriggerHandler.ManageAccountMapStatic())
        .bind(Triggers.Evt.afterdelete, new AccountTriggerHandler.ManageAccountMapStatic())

        .bind(Triggers.Evt.afterinsert, new AccountTriggerHandler.accessControls())
        .bind(Triggers.Evt.afterupdate, new AccountTriggerHandler.accessControls())
        // Descartes-DPS changes
        .bind(Triggers.Evt.beforeupdate, new AccountTriggerHandler.validateDPSFlaggedAccount())
        .bind(Triggers.Evt.afterupdate, new AccountTriggerHandler.sendAccountDPSNotifications())
        .bind(Triggers.Evt.afterupdate, new AccountTriggerHandler.LockRecordsOnDPSFlagging())
        .bind(Triggers.Evt.afterinsert, new AccountTriggerHandler.DescartesDPSAccountAfter())
        .bind(Triggers.Evt.afterupdate, new AccountTriggerHandler.DescartesDPSAccountAfter())
        .bind(Triggers.Evt.beforeInsert, new AccountTriggerHandler.PopulateSystemProcessStageCreated())
        .bind(Triggers.Evt.beforeInsert, new AccountTriggerHandler.PopulateSystemProcessEnrichmentBypass())
        .bind(Triggers.Evt.beforeUpdate, new AccountTriggerHandler.PopulateSystemProcessStageEnriched())
        .bind(Triggers.Evt.beforeUpdate, new AccountTriggerHandler.PopulateSystemProcessStageUpdated())
        .bind(Triggers.Evt.afterinsert, new AccountTriggerHandler.SendAccountDetailsforClayEnrichment());

    if (bypassTrigger != null && bypassTrigger.Bypass_Except_Segmentation__c == false) {
        t
            .bind(Triggers.Evt.beforeinsert, new AccountTriggerHandler.PerformWorkFlowActions())
            .bind(Triggers.Evt.beforeinsert, new AccountTriggerHandler.AccountBefore())
            .bind(Triggers.Evt.beforeinsert, new AccountTriggerHandler.PopulateSDRAgentRoleNames())
            .bind(Triggers.Evt.beforeinsert, new AccountTriggerHandler.PopulateWebisteFromContactEmail())
            .bind(Triggers.Evt.beforeinsert, new AccountTriggerHandler.PopulateParentId())
            .bind(Triggers.Evt.beforeinsert, new AccountTriggerHandler.populateZIFieldsOnAccount())
            .bind(Triggers.Evt.beforeupdate, new AccountTriggerHandler.populateZIFieldsOnAccount())
            .bind(Triggers.Evt.beforeinsert, new AccountTriggerHandler.ValidateHoldOut())
            .bind(Triggers.Evt.beforeupdate, new AccountTriggerHandler.ValidateHoldOut())
            .bind(Triggers.Evt.beforeinsert, new AccountTriggerHandler.populateParentIdfromZIIdonAccount())
            .bind(Triggers.Evt.beforeupdate, new AccountTriggerHandler.populateParentIdfromZIIdonAccount())
            .bind(Triggers.Evt.afterinsert, new AccountTriggerHandler.AccountAfter())
            .bind(Triggers.Evt.afterinsert, new ObjectMonitoringHelper.MonitoringAddObject(Account.class.getName()))
            .bind(Triggers.Evt.beforeupdate, new AccountTriggerHandler.PerformWorkFlowActions())
            .bind(Triggers.Evt.beforeupdate, new AccountTriggerHandler.ValidateVATNumberWithApproval())
            .bind(Triggers.Evt.beforeupdate, new AccountTriggerHandler.AccountBefore())
            .bind(Triggers.Evt.beforeupdate, new AccountTriggerHandler.PopulateWebisteFromContactEmail())
            .bind(Triggers.Evt.beforeupdate, new AccountTriggerHandler.PopulateParentId())
            .bind(Triggers.Evt.beforeupdate, new AccountTriggerHandler.ValidateVATNumberForEngageAccounts())
            .bind(Triggers.Evt.beforeupdate, new AccountTriggerHandler.TerminateActiveAgreement())
            .bind(Triggers.Evt.beforeupdate, new AccountTriggerHandler.RestrictEditBillingAddressForIndianAccounts())
            .bind(Triggers.Evt.beforeinsert, new AccountTriggerHandler.GSPAccountOwnerValidation())
        	.bind(Triggers.Evt.beforeupdate, new AccountTriggerHandler.GSPAccountOwnerValidation())
            .bind(Triggers.Evt.beforeinsert, new AccountTriggerHandler.PopulateWaveOnInsertAndUpdate())
            .bind(Triggers.Evt.beforeupdate, new AccountTriggerHandler.PopulateWaveOnInsertAndUpdate())
            .bind(Triggers.Evt.afterupdate, new AccountTriggerHandler.AccountAfter())
            .bind(Triggers.Evt.afterupdate, new AccountTriggerHandler.RejectApporvals())
		    .bind(Triggers.Evt.afterupdate, new AccountTriggerHandler.RejectCreditLimitApporvals())
            .bind(Triggers.Evt.afterupdate, new AccountTriggerHandler.ProcessMigratedAccounts())
            .bind(Triggers.Evt.afterUpdate, new AccountTriggerHandler.UpdateBrandPartnerOnRelatedRecords())
            .bind(Triggers.Evt.afterUpdate, new AccountTriggerHandler.CreateDealDeskCase())
            .bind(Triggers.Evt.afterupdate, new AccountTriggerHandler.SendElaDataToNGBS())
            .bind(Triggers.Evt.afterupdate, new AccountTriggerHandler.DFR_UpdateRelatedDFR())
            .bind(Triggers.Evt.afterupdate, new AccountTriggerHandler.ContactStatusUpdateForPaidAccounts())
            .bind(Triggers.Evt.afterupdate, new AccountTriggerHandler.CustomerContactsForPaidAccounts())
            .bind(Triggers.Evt.afterupdate, new AccountTriggerHandler.CreateTaskUponNumberOfDLValueChanges())
            .bind(Triggers.Evt.afterinsert, new AccountTriggerHandler.UpdateHoldOut())
            .bind(Triggers.Evt.afterupdate, new AccountTriggerHandler.UpdateHoldOut())
            .bind(Triggers.Evt.afterupdate, new AccountTriggerHandler.qualtricsChurnSurvey())
            .bind(Triggers.Evt.afterupdate, new ObjectMonitoringHelper.MonitoringAddObject(Account.class.getName()))
            .bind(Triggers.Evt.beforedelete, new AccountTriggerHandler.AccountBefore())
            .bind(Triggers.Evt.afterdelete, new AccountTriggerHandler.AccountAfter())
            .bind(Triggers.Evt.afterdelete, new ObjectMonitoringHelper.MonitoringAddObject(Account.class.getName()))
            .bind(Triggers.Evt.afterinsert, new AccountTriggerHandler.ImplementationCreation())
            .bind(Triggers.Evt.afterupdate, new AccountTriggerHandler.ImplementationCreation())
            .bind(Triggers.Evt.afterupdate, new AccountTriggerHandler.partnerAccountsVisibility())
            .bind(Triggers.Evt.afterinsert, new AccountTriggerHandler.partnerAccountsVisibility())
            .bind(Triggers.Evt.beforeupdate, new AccountTriggerHandler.ImplementationStatus2Change())
            .bind(Triggers.Evt.beforeupdate, new AccountTriggerHandler.UpdateDeletedAccountFields())
            /* CRM-5076 - Added as Part of EU Data Privacy Project to restrict changing the Account Owner when the Record is of EU*/
            .bind(Triggers.Evt.afterinsert, new AccountTriggerHandler.CopyServiceDetailsToBillingAccountPackage())
            .bind(Triggers.Evt.afterupdate, new AccountTriggerHandler.CopyServiceDetailsToBillingAccountPackage())
            .bind(Triggers.Evt.afterinsert, new AccountTriggerHandler.CopyContactCenterServiceFieldsToMasterAccount())
            .bind(Triggers.Evt.afterupdate, new AccountTriggerHandler.CopyContactCenterServiceFieldsToMasterAccount())
            .bind(Triggers.Evt.afterinsert, new AccountTriggerHandler.CopyFieldsToTechnicalAccounts())
            .bind(Triggers.Evt.afterupdate, new AccountTriggerHandler.CopyFieldsToTechnicalAccounts())
            .bind(Triggers.Evt.afterinsert, new AccountTriggerHandler.UpdateReportedMRSOnPackage())
            .bind(Triggers.Evt.afterupdate, new AccountTriggerHandler.UpdateReportedMRSOnPackage())
            .bind(Triggers.Evt.afterinsert, new AccountTriggerHandler.UpdateServiceMRRFieldsOnMasterAccount())
            .bind(Triggers.Evt.afterupdate, new AccountTriggerHandler.UpdateServiceMRRFieldsOnMasterAccount())
            .bind(Triggers.Evt.afterupdate, new AccountTriggerHandler.activateNewestOrders())
            .bind(Triggers.Evt.afterupdate, new AccountTriggerHandler.CreateOrderAfterSignUpComplete())
            // ATT Account based Trigger
            .bind(Triggers.Evt.afterinsert, new AccountTriggerHandler.CopyAccountContactRolesToTechnicalAccounts())
            .bind(Triggers.Evt.beforeupdate, new AccountTriggerHandler.RetainTeamMemberOnOwnerChange()) // PBC-13962 - Always Retain Renewals Manager Account Team Member when owner is changed
            .bind(Triggers.Evt.beforeupdate, new AccountTriggerHandler.CopyFieldsToMasterAccount());
    }

    if (bypassTrigger != null && (bypassTrigger.Bypass_Except_Segmentation__c == true || bypassTrigger.Bypass_Resegmentation_Trigger_Logic__c == false)) {
        t
            .bind(Triggers.Evt.beforeinsert, new AccountTriggerHandler.PopulateUltimateParentId())
            .bind(Triggers.Evt.beforeupdate, new AccountTriggerHandler.PopulateUltimateParentId())
            .bind(Triggers.Evt.afterinsert, new AccountTriggerHandler.PopulateSegmentNameUltimateParentLogic())
            .bind(Triggers.Evt.beforeupdate, new AccountTriggerHandler.PopulateSegmentNameUltimateParentLogic())
            .bind(Triggers.Evt.afterUpdate, new AccountTriggerHandler.PopulateSegmentNameOnChildAccounts());
    }

    t
        .manage();
}