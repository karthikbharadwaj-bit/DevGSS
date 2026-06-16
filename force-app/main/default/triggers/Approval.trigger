trigger Approval on Approval__c (
    before insert,
    before update,
    before delete,
    after insert,
    after update,
    after delete) {
        ByPassTrigger__c bypassTrigger = ByPassTrigger__c.getInstance();
    if (bypassTrigger != null && bypassTrigger.Bypass_Approval_Trigger__c == true) {
        System.debug('$$$ ByPassTrigger__c Active For Approval $$$');
        return;
    }
    new Triggers()
        /*
        * INSERT
        */
        .bind(Triggers.Evt.beforeinsert, new ApprovalTriggerHandler.ValidateCreationOnTechAccount())
        .bind(Triggers.Evt.beforeinsert, new ApprovalTriggerHandler.ValidateApprovalsCreditLimitIncrease())
        .bind(Triggers.Evt.beforeinsert, new ApprovalTriggerHandler.PrepareData())
        .bind(Triggers.Evt.beforeinsert, new ApprovalTriggerHandler.BrandPartnerPopulationHandler())
        .bind(Triggers.Evt.beforeinsert, new ApprovalTriggerHandler.StatusChangeValidator())
        .bind(Triggers.Evt.beforeinsert, new ApprovalTriggerHandler.RequestCompleteDateFiller())
        .bind(Triggers.Evt.beforeinsert, new ApprovalTriggerHandler.LegalOutForSignatureHandler())
        .bind(Triggers.Evt.beforeinsert, new ApprovalTriggerHandler.ApprovalBefore())
        .bind(Triggers.Evt.beforeinsert, new ApprovalTriggerHandler.SetCurrencyIsoCode())
        .bind(Triggers.Evt.beforeinsert, new ApprovalTriggerHandler.SetAccountId())
        .bind(Triggers.Evt.beforeinsert, new ApprovalTriggerHandler.ProcessExistingApprovals())
        .bind(Triggers.Evt.beforeinsert, new ApprovalTriggerHandler.SetApprovers())
        .bind(Triggers.Evt.beforeinsert, new ApprovalTriggerHandler.LegalServiceLevelAgreementValidator())
        .bind(Triggers.Evt.beforeinsert, new ApprovalTriggerHandler.PopulateApprovalContactEmail())
        .bind(Triggers.Evt.beforeinsert, new ApprovalTriggerHandler.AssignRefundOwnerManager())
        .bind(Triggers.Evt.beforeinsert, new ApprovalTriggerHandler.PopulateContractFromAccount())
        .bind(Triggers.Evt.beforeinsert, new ApprovalTriggerHandler.PopulateDLsFromQLI())
        .bind(Triggers.Evt.beforeinsert, new ApprovalTriggerHandler.PopulateCompanyInfo())
        .bind(Triggers.Evt.beforeinsert, new ApprovalTriggerHandler.ApproverIdsSetter())
        .bind(Triggers.Evt.beforeinsert, new ApprovalTriggerHandler.RepPenaltyMultiplier())
        .bind(Triggers.Evt.beforeinsert, new ApprovalTriggerHandler.PrepopulateFieldsFromAccount())
        .bind(Triggers.Evt.beforeinsert, new ApprovalTriggerHandler.PopulatePaymentMethod())
        .bind(Triggers.Evt.beforeinsert, new ApprovalTriggerHandler.SetVATNumberFromAccount())
        .bind(Triggers.Evt.beforeinsert, new ApprovalTriggerHandler.DNBInvoiceAndPartnerApprovalHandler())
        .bind(Triggers.Evt.beforeinsert, new ApprovalTriggerHandler.ValidateTaxExemptApprovalStatus())
        .bind(Triggers.Evt.beforeinsert, new ApprovalTriggerHandler.ValidateApprovalTypeByProfile())
        .bind(Triggers.Evt.beforeinsert, new ApprovalTriggerHandler.PopulateRefundApprovalBU())
        .bind(Triggers.Evt.beforeinsert, new ApprovalTriggerHandler.CheckSecondaryDLUniqueness())
        .bind(Triggers.Evt.beforeinsert, new ApprovalTriggerHandler.PopulateSourceWithOther())
        .bind(Triggers.Evt.beforeinsert, new ApprovalTriggerHandler.ValidateInvoiceRequest())
        .bind(Triggers.Evt.beforeinsert, new ApprovalTriggerHandler.ValidateInvoiceOnBehalfRequest())
        .bind(Triggers.Evt.beforeinsert, new ApprovalTriggerHandler.SyncPaymentMethodInfo())
        .bind(Triggers.Evt.beforeinsert, new ApprovalTriggerHandler.PopulateFieldsFromKYCToSEZWOPTaxExemption())
        .bind(Triggers.Evt.beforeinsert, new ApprovalTriggerHandler.ValidateKycApproval())
        .bind(Triggers.Evt.beforeinsert, new ApprovalTriggerHandler.PopulateStatusLastModifiedDate())
        .bind(Triggers.Evt.beforeinsert, new ApprovalTriggerHandler.RecalculateApprovalsMonthlyAndSignUpLimits())

        .bind(Triggers.Evt.afterinsert, new ApprovalTriggerHandler.CopyInvoiceValuesToRelatedRecords())
        .bind(Triggers.Evt.afterinsert, new ApprovalTriggerHandler.ApprovalAfter())
        .bind(Triggers.Evt.afterinsert, new ApprovalTriggerHandler.DNBInvoiceAndPartnerApprovalHandler())
        .bind(Triggers.Evt.afterinsert, new ApprovalTriggerHandler.TaxExemptionVATCountry())
        .bind(Triggers.Evt.afterinsert, new ApprovalTriggerHandler.CreateKycDocuments())
        .bind(Triggers.Evt.afterinsert, new ApprovalTriggerHandler.CopyKycApprovalEntities())
        .bind(Triggers.Evt.afterinsert, new ApprovalTriggerHandler.SubmitKycApproval())
        .bind(Triggers.Evt.afterinsert, new ApprovalTriggerHandler.CreateBillingAddressLsaForKycApproval())
        .bind(Triggers.Evt.afterinsert, new ApprovalTriggerHandler.ApproveIndiaTaxExemptionApproval())
        .bind(Triggers.Evt.afterinsert, new ApprovalTriggerHandler.CompleteTaxExemptApprovalOnFastApproveOrReject())
        /*
        * UPDATE
        */
        .bind(Triggers.Evt.beforeupdate, new ApprovalTriggerHandler.PrepareData())
        .bind(Triggers.Evt.beforeupdate, new ApprovalTriggerHandler.BrandPartnerPopulationHandler())
        .bind(Triggers.Evt.beforeupdate, new ApprovalTriggerHandler.StatusChangeValidator())
        .bind(Triggers.Evt.beforeupdate, new ApprovalTriggerHandler.RequestCompleteDateFiller())
        .bind(Triggers.Evt.beforeupdate, new ApprovalTriggerHandler.LegalOutForSignatureHandler())
        .bind(Triggers.Evt.beforeupdate, new ApprovalTriggerHandler.ApprovalBefore())
        .bind(Triggers.Evt.beforeupdate, new ApprovalTriggerHandler.SetAccountId())
        .bind(Triggers.Evt.beforeupdate, new ApprovalTriggerHandler.ProcessExistingApprovals())
        .bind(Triggers.Evt.beforeupdate, new ApprovalTriggerHandler.SetApprovers())
        .bind(Triggers.Evt.beforeupdate, new ApprovalTriggerHandler.PopulateApprovalHistory())
        .bind(Triggers.Evt.beforeupdate, new ApprovalTriggerHandler.CopyInvoiceValuesToRelatedRecords())
        .bind(Triggers.Evt.beforeupdate, new ApprovalTriggerHandler.LegalServiceLevelAgreementValidator())
        .bind(Triggers.Evt.beforeupdate, new ApprovalTriggerHandler.PopulateApprovalContactEmail())
        .bind(Triggers.Evt.beforeupdate, new ApprovalTriggerHandler.AssignRefundOwnerManager())
        .bind(Triggers.Evt.beforeupdate, new ApprovalTriggerHandler.ValidateAccountBillingAddress())
        .bind(Triggers.Evt.beforeupdate, new ApprovalTriggerHandler.ApproverIdsSetter())
        .bind(Triggers.Evt.beforeupdate, new ApprovalTriggerHandler.ApprovalEmailsHandler())
        .bind(Triggers.Evt.beforeupdate, new ApprovalTriggerHandler.RepPenaltyMultiplier())
        .bind(Triggers.Evt.beforeupdate, new ApprovalTriggerHandler.DNBInvoiceAndPartnerApprovalHandler())
        .bind(Triggers.Evt.beforeupdate, new ApprovalTriggerHandler.ValidateApprovalTypeByProfile())
        .bind(Triggers.Evt.beforeupdate, new ApprovalTriggerHandler.PopulateRefundApprovalBU())
        .bind(Triggers.Evt.beforeupdate, new ApprovalTriggerHandler.ValidateMassApproval())
        .bind(Triggers.Evt.beforeupdate, new ApprovalTriggerHandler.SetBlockedTaxExemptionApprovalStatusToRejected())
        .bind(Triggers.Evt.beforeupdate, new ApprovalTriggerHandler.ValidateKYCApprovalOnApprove())
        .bind(Triggers.Evt.beforeupdate, new ApprovalTriggerHandler.CheckSecondaryDLUniqueness())
        .bind(Triggers.Evt.beforeupdate, new ApprovalTriggerHandler.UncheckSendSpecialTermsToPDFCheckbox())
        .bind(Triggers.Evt.beforeupdate, new ApprovalTriggerHandler.ValidateInvoiceRequest())
        .bind(Triggers.Evt.beforeupdate, new ApprovalTriggerHandler.ValidateInvoiceOnBehalfRequest())
        .bind(Triggers.Evt.beforeupdate, new ApprovalTriggerHandler.SyncPaymentMethodInfo())
        .bind(Triggers.Evt.beforeupdate, new ApprovalTriggerHandler.PopulateStatusLastModifiedDate())
        .bind(Triggers.Evt.beforeupdate, new ApprovalTriggerHandler.RecalculateApprovalsMonthlyAndSignUpLimits())

        .bind(Triggers.Evt.afterupdate, new ApprovalTriggerHandler.ApprovalAfter())
        .bind(Triggers.Evt.afterupdate, new ApprovalTriggerHandler.LegalOutForSignatureHandler())
        .bind(Triggers.Evt.afterupdate, new ApprovalTriggerHandler.LegalInProgressNotifier())
        .bind(Triggers.Evt.afterupdate, new ApprovalTriggerHandler.LegalRejectionNotifier())
        .bind(Triggers.Evt.afterupdate, new ApprovalTriggerHandler.LegalRequiredNotifier())
        .bind(Triggers.Evt.afterupdate, new ApprovalTriggerHandler.LegalRequestRecalledApproval())
        .bind(Triggers.Evt.afterupdate, new ApprovalTriggerHandler.LegalRequestPassApproval())
        .bind(Triggers.Evt.afterupdate, new ApprovalTriggerHandler.LegalRequestRejectedApproval())
        .bind(Triggers.Evt.afterupdate, new ApprovalTriggerHandler.SetTaxReestimationCheckboxOnRelatedQuotes())
        .bind(Triggers.Evt.afterupdate, new ApprovalTriggerHandler.CheckAndRecallApproval())
        .bind(Triggers.Evt.afterupdate, new ApprovalTriggerHandler.CompleteTaxExemptApprovalOnFastApproveOrReject())
        .bind(Triggers.Evt.afterupdate, new ApprovalTriggerHandler.RejectTaxExemptionApproval())
        .bind(Triggers.Evt.afterupdate, new ApprovalTriggerHandler.PopulateVatNumberOnAccountByGstNumber())
        .bind(Triggers.Evt.afterupdate, new ApprovalTriggerHandler.UpdateBillingAddressFromKYCApproval())
        .bind(Triggers.Evt.afterupdate, new ApprovalTriggerHandler.PublishEventAfterKycStatusChanging())
        .bind(Triggers.Evt.afterupdate, new ApprovalTriggerHandler.IncreaseSpendingLimitAfterApproved())
        .bind(Triggers.Evt.afterupdate, new ApprovalTriggerHandler.ResubmitCreditLimitApproval())
        /*
        * DELETE
        */
        .bind(Triggers.Evt.beforedelete, new ApprovalTriggerHandler.PrepareData())

        .bind(Triggers.Evt.afterdelete, new ApprovalTriggerHandler.UncheckVATExemptionOnAccount())
        .bind(Triggers.Evt.afterdelete, new ApprovalTriggerHandler.RemoveTechnicalApprovalsOnMasterDelete())
        /*
        * UNDELETE
        */
        .bind(Triggers.Evt.afterundelete, new ApprovalTriggerHandler.PrepareData())
        .manage();
}