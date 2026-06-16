public with sharing class ProcessOrderValidator {
    @TestVisible
    private static final String ERROR_MESSAGE = 'SignUp parameters are not specified';
    public static List<DealDeskCaseDescription__c> dealDeskDescriptionsToInsert = new List<DealDeskCaseDescription__c>();
    public static Response validate(POWrappers.SignUpParams[] dataArr) {
        Response resp = new Response();
        if (dataArr == null || dataArr.isEmpty()) {
            resp.addMessage(
                Response.STATUS_ERROR,
                ERROR_MESSAGE,
                Response.SEVERITY_ERROR
            );
            return resp;
        }

        Account masterAcc = dataArr.size() == 1 || dataArr[0].masterAcc == null ? dataArr[0].opportunity.Account : dataArr[0].masterAcc;
        Boolean isMPUB = AccountHelper.isMPUBAccount(masterAcc);
        String ngbsAccountStatus;
        List<String> servicesOnPrimaryQuote = new List<String>();
        for (POWrappers.SignUpParams data : dataArr) {
            if (QuoteHelper.isOffice(data.targetQuote)) {
                ngbsAccountStatus = data.ngbsAccountStatus;
            }
            if (isMPUB) {
                servicesOnPrimaryQuote.addAll(QuoteHelper.getProductNames(data.primaryQuote?.Package_Info__c));
            }
        }
        ngbsAccountStatus = ngbsAccountStatus == null ? dataArr[0].ngbsAccountStatus : ngbsAccountStatus;

        if (AccountHelper.isInactive(masterAcc)) {
            Boolean wasMasterAccPaid = false;
            //TODO: selector should be removed from validate method.
            List<AccountHistory> masterAccStatusHistory = (List<AccountHistory>) new AccountHistorySelector()
                .selectRCAccountStatusHistory(new List<Object>{ masterAcc.Id })
                .executeQuery();

            for (AccountHistory masterAccountHistory: masterAccStatusHistory) {
                String newValue = String.valueOf(masterAccountHistory.NewValue);

                if(newValue != null) {
                    if (AccountHelper.PAID_STATUS.equalsIgnoreCase(newValue)) {
                        wasMasterAccPaid = true;
                    }
                    if (wasMasterAccPaid
                        && (AccountHelper.TERMINATED_ACCOUNT_STATUSES.contains(newValue.toLowerCase())
                        || AccountHelper.INACTIVE_ACCOUNT_STATUSES.contains(newValue))
                    ) {
                        resp.addMessage(
                            Label.Opportunity_Error_onSignUp_Account_Is_Terminated_text,
                            Label.Opportunity_Error_onSignUp_Account_Is_Terminated_help_text,
                            Response.SEVERITY_ERROR);
                        return resp;
                    }
                }
            }
        }

        for (POWrappers.SignUpParams data : dataArr) {
            data.isMultiProductFTEnabled = true;
            data.servicesOnPrimaryQuote = servicesOnPrimaryQuote;
            Opportunity opp = (Opportunity) data.opportunity;
            String tierName = isMPUB ? OpportunityHelper.getShortTierNameByQuote(data.targetQuote) : OpportunityHelper.getTierName(opp, data.targetQuote);

            Response validationResponse = new Response();
            if (QuoteHelper.isRCCC(data.targetQuote) && String.isNotBlank(data.targetQuote.BillingPackage__c)) {
                String validateCC = SyncWithNGBS.validateSyncWithNGBS(data.targetQuote.Id);
                if (String.isNotBlank(validateCC)) {
                    validationResponse.addMessages((List<Response.ResponseMessage>) JSON.deserialize(validateCC, List<Response.ResponseMessage>.class));
                }
            } else if (AccountHelper.isPackageActive(data.ngbsAccountStatus)) {
                continue;
            } else {
                validationResponse = validate(data, isMPUB);
            }

            resp.addMessages(OpportunityHelper.addTierNameToMessages(tierName, validationResponse.messages));
        }

        return resp;
    }
    @TestVisible
    private static Response validate(POWrappers.SignUpParams data, Boolean isMPUB) {
        Response resp = new Response();

        if (data == null) {
            resp.addMessage(
                Response.STATUS_ERROR,
                ERROR_MESSAGE,
                Response.SEVERITY_ERROR
            );
            return resp;
        }

        Quote qt = (Quote) data.targetQuote;
        Quote primaryQuote = (Quote) data.primaryQuote;
        Quote pocQuote = (Quote) data.pocQuote;
        Quote psQuote = (Quote) data.psQuote;
        Quote ccQuote = (Quote) data.ccQuote;
        Opportunity opty = (Opportunity) data.opportunity;
        Account masterAcc = (Account) data.masterAcc;
        List<Account> boundAccs = (List<Account>) data.boundAccs;
        List<AccountRelation__c> accRelations = (List<AccountRelation__c>) data.accRelations;
        List<Approval__c> approvals = (List<Approval__c>) data.approvals;
        List<Area_Code_Line_Item__c> areacodeLineItems = (List<Area_Code_Line_Item__c>) data.areaCodeLineItems;
        List<Promotion__c> promoList = (List<Promotion__c>) data.promotions;
        String paymentMethod = data.paymentMethod;
        List<PartnerOperationsLog__c> partnerOperationsLogs = QuoteHelper.getPartnerOperationLog(opty.Id);
        Boolean isMultiProductFTEnabled = data.isMultiProductFTEnabled != null ? data.isMultiProductFTEnabled : false;
        List<String> servicesOnPrimaryQuote = data.servicesOnPrimaryQuote;

        Boolean hasProServInPackageInfo = QuoteHelper.hasProfessionalServicesInPackageInfo(primaryQuote);
        Boolean hasNGBSProServ = servicesOnPrimaryQuote.contains(QuoteHelper.NGBS_PROFESSIONAL_SERVICES_PRODUCT) || hasProServInPackageInfo;
        Boolean isProServQuotesNotCancelled = data.isProServQuotesNotCancelled || hasNGBSProServ;
        Boolean isSingleQuote = String.isEmpty(primaryQuote?.MasterQuote__c);

        //TODO: getQuoteLineItemsWithAddressAssignment logic should be moved to PODataCollector if qlis are not queried yet/else query from getQuoteLineItemsWithAddressAssignment should be removed
        List<QuoteLineItem> qlisForShipping = POHelper.getQuoteLineItemsWithAddressAssignment(qt);
        BillingWrappers.QuotePackageInfo pkgInfo = QuoteHelper.getPackageInfo(qt);
        String catalogId = pkgInfo?.id;
        String version = pkgInfo?.version;
        BillingWrappers.NGBSPackage pkg = NGBSAPI.getPackage(catalogId, version);
        BillingWrappers.BillingLabels packageLabels = pkg?.labels;

        BillingWrappers.NGBSAccount accountInfo = NGBSAPI.getNGBSAccount(data.opportunity.Account?.Billing_ID__c);
        List<Approval__c> invoiceApprovals = new List<Approval__c>();
        List<Approval__c> invoiceOfficeApprovals = new List<Approval__c>();
        List<Approval__c> kycApprovals = new List<Approval__c>();
        List<Approval__c> vatIdExemptAprovals = new List<Approval__c>();
        List<Approval__c> taxExemptAprovals = new List<Approval__c>();

        Boolean hasDirectDebitApproval = false;

        Set<String> extServices = new Set<String>();

        if (isMPUB && accountInfo != null && accountInfo.packages != null) {
            for (BillingWrappers.NGBSAccountPackage accPackage : accountInfo.packages){
                if (accPackage.product != null) {
                    extServices.add(accPackage.product);
                }
            }
        }
        for (Approval__c approval : approvals) {
            if (approval.RecordTypeId == ApprovalHelper.RT_ID_INVOICING_REQUEST) {
                if (approval.Account__c == opty.AccountId && approval.Opportunity__c == opty.Id) {
                    invoiceApprovals.add(approval);
                } else if (approval.Account__c == opty.Account.Master_Account__c) {
                    invoiceOfficeApprovals.add(approval);
                }
            } else if (approval.RecordTypeId == ApprovalHelper.RT_ID_KYC_APPROVAL_REQUEST) {
                kycApprovals.add(approval);
            } else if (approval.RecordTypeId == ApprovalHelper.RT_ID_DIRECT_DEBIT_REQUEST && approval.Account__c == opty.AccountId) {
                hasDirectDebitApproval = true;
            } else if (approval.RecordTypeId == ApprovalHelper.RT_ID_VAT_ID_Exemption && approval.Status__c == ApprovalHelper.STATUS_APPROVED) {
                vatIdExemptAprovals.add(approval);
            } else if (approval.RecordTypeId == ApprovalHelper.RT_ID_TAX_EXEMPT_APPROVAL && approval.Status__c == ApprovalHelper.STATUS_APPROVED) {
                taxExemptAprovals.add(approval);
            }
        }

        Validator noQuotesValidator =
            new OpportunityValidator.SignUp_NoQuotesValidator(Validator.SEVERITY_CRITICAL, qt);
        Validator unsupportedBrandValidator =
            new OpportunityValidator.UnsupportedBrandValidator(Validator.SEVERITY_CRITICAL, opty, POHelper.UNSUPPORTED_BRANDS, QuoteValidator.BillingProcessType.SIGN_UP);
        Validator verizonValidator =
            new OpportunityValidator.SignUp_VerizonValidator(Validator.SEVERITY_CRITICAL, opty);
        Validator swissVatIdValidator =
            new OpportunityValidator.SwissVatIdValidator(opty, vatIdExemptAprovals);
        Validator taiwanVatIdValidator =
            new OpportunityValidator.TaiwanVatIdValidator(
                new OpportunityValidator.TaiwanVatandTaxValidatorParams(
                    opty,
                    taxExemptAprovals,
                    false
                )
            );
        Validator quoteHasErrorsValidator =
            new QuoteValidator.SignUp_QuoteHasErrorsValidator(Validator.SEVERITY_CRITICAL, qt);
        Validator quoteHasPaymentMethodValidator =
            new QuoteValidator.SignUp_QuoteHasPaymentMethodValidator(qt);
        Validator billingCountryMatchBIValidator =
            new QuoteValidator.SignUp_BillingCountryMatchBIValidator(Validator.SEVERITY_CRITICAL, qt);
        Validator docuSignNotCompleted =
            new QuoteValidator.SignUp_DocusignNotCompletedValidator(Validator.SEVERITY_CRITICAL, qt);

        Validator areaCodeAssignmentValidator =
            new QuoteValidator.SignUp_AreaCodesAssignementValidator(Validator.SEVERITY_CRITICAL, qt, areacodeLineItems);
        Validator ngbsOfficeSignUpValidator =
            new QuoteValidator.SignUp_NGBSOfficeSignUpValidator(Validator.SEVERITY_CRITICAL, qt);
        Validator contractPricingValidator =
            new QuoteValidator.SignUp_ContractPricingValidator(Validator.SEVERITY_CRITICAL, qt);
        Validator specialTermsRequireActiveAgreementValidator =
            new QuoteValidator.SignUp_SpecialTermsRequireActiveAgreementValidator(Validator.SEVERITY_CRITICAL, qt);
        Validator specialTermsWithoutContractValidator =
            new QuoteValidator.SignUp_SpecialTermsWithoutContractValidator(Validator.SEVERITY_CRITICAL, qt);
        Validator alreadySignedUpValidator =
            new AccountValidator.SignUp_AlreadySignedUpValidator(Validator.SEVERITY_CRITICAL, qt, opty);
        Validator billingPackageExpirationValidator =
            new QuoteValidator.BillingPackageExpirationValidator(Validator.SEVERITY_CRITICAL, qt, QuoteValidator.BillingProcessType.SIGN_UP);
        Validator areaCodeLineItemValidator =
            new QuoteValidator.SignUp_AreaCodeLineItemValidator(Validator.SEVERITY_CRITICAL, qt);
        Validator productReachedSalesEndDateValidator =
            new QuoteValidator.SignUp_ProductReachedSalesEndDateValidator(Validator.SEVERITY_CRITICAL, qt);
        Validator contractAndActiveAgreementValidator =
            new QuoteValidator.SignUp_ContractAndActiveAgreementValidator(Validator.SEVERITY_CRITICAL, qt);
        Validator rentalPhoneValidator =
            new QuoteValidator.SignUp_RentalPhoneValidator(Validator.SEVERITY_CRITICAL, qt);
        Validator noQuoteLineItemsValidator = new QuoteValidator.SignUp_NoQuoteLineItemsValidator(qt);
        Validator primaryQuoteNotApprovedValidator = new QuoteValidator.SignUp_PrimaryQuoteNotApprovedValidator(qt);
        Validator quantityShippingValidator = new QuoteValidator.SignUp_QuantityShippingValidator(qt, qlisForShipping, POHelper.isAllowProcessOrderWithoutShipping, isProServQuotesNotCancelled);
        Validator quantityLessThenShippingValidator = new QuoteValidator.SignUp_QuantityLessThenShippingValidator(qt, qlisForShipping);
        Validator activeAgreementValidator = new QuoteValidator.SignUp_ActiveAgreementValidator(qt, isMPUB);
        Validator proservSyncAndSoldValidator = new QuoteValidator.SignUp_ProservSyncAndSoldValidator(psQuote);
        Validator psFieldsValidation = new QuoteValidator.PSFieldsValidation(primaryQuote, opty, hasNGBSProServ);
        Validator missApprovedPOCApprovalValidator =
            new QuoteValidator.SignUp_MissApprovedPOCApprovalValidator(qt, approvals);
        Validator pendingTaxExemptionApprovalValidator =
            new QuoteValidator.SignUp_PendingTaxExemptionApprovalValidator(qt, approvals);
        Validator inProgressTaxExemptionApprovalValidator =
            new QuoteValidator.SignUp_InProgressTaxExemptionApprovalValidator(qt, approvals);
        Validator masterAccountIsPaidValidator =
            new AccountValidator.SignUp_MasterAccountIsPaidValidator(opty, masterAcc);
        Validator approvedInvoiceValidator =
            new AccountValidator.ApprovedInvoiceValidator(
                new AccountValidator.ApprovedInvoiceValidatorParams(
                    opty,
                    invoiceApprovals,
                    paymentMethod,
                    false,
                    partnerOperationsLogs,
                    isMPUB,
                    servicesOnPrimaryQuote,
                    isSingleQuote,
                    extServices
                )
            );
        Validator directDebitThresholdValidator =
            new ApprovalValidator.DirectDebitThresholdValidator(qt, hasDirectDebitApproval, paymentMethod, ApprovalValidator.SIGN_UP);
        Validator directDebitLastApprovalValidator = new ApprovalValidator.DirectDebitLimitValidation(qt, paymentMethod, ApprovalValidator.SIGN_UP);
        Validator elaBillingAccountValidator =
            new AccountValidator.ELABillingAccountValidator(opty.Account, accRelations);
        Validator expiredPromotionValidator = new QuoteValidator.SignUp_ExpiredPromoValidator(promoList);
        Validator packageLabelsValidator = new QuoteValidator.SignUp_PackageLabelsValidator(packageLabels, opty);
        Validator hasIndiaInvoiceRequestValidator =
            new QuoteValidator.SignUp_HasIndiaInvoiceRequestValidator(opty, invoiceApprovals);
        Validator kycApprovalValidator = new AccountValidator.KYCApprovalValidatorOnSignUp(kycApprovals);
        Validator approvedInvoiceOnBehalfValidator =
            new AccountValidator.ApprovedInvoiceOnBehalfValidator(opty, false, partnerOperationsLogs);
        Validator approvedInvoiceWholesaleValidator =
            new AccountValidator.ApprovedInvoiceWholesaleValidator(opty, false, partnerOperationsLogs);
        Validator masterAccountActiveAgreementValidator =
            new AccountValidator.MasterAccountActiveAgreementValidator(masterAcc, false);
        Validator officeMasterAccountValidator =
            new AccountValidator.OfficeMasterAccountValidator(opty, masterAcc, accountInfo, false);
        Validator bobValidator = new AccountValidator.BoundPartnerAccountsValidator(boundAccs);
        Validator proServQliToPhaseValidator = new QuoteValidator.ProServQliToPhaseValidator(servicesOnPrimaryQuote, primaryQuote, isSingleQuote);
        Validator proServeProfileValidator =
             new QuoteValidator.SignUp_ProserveProfileValidator(qt,false);
        Validator rcEventsAdminRoleValidator = new OpportunityValidator.RCEventsAdminRoleValidator(Validator.SEVERITY_CRITICAL, opty, qt);

        Boolean isNewBilling = QuoteHelper.isNewBillingQuote(qt);
        Boolean isCreditCard = QuoteHelper.isCreditCard(paymentMethod);
        Boolean isEngage = QuoteHelper.isEngageService(qt);
        Boolean isPOC = QuoteHelper.isPOCQuote(qt);
        Boolean isInvoice = QuoteHelper.isInvoice(paymentMethod);
        Boolean isSingapore = OpportunityHelper.isSingapore(opty);
        Boolean isInContact = QuoteHelper.isRCCC(qt);
        Boolean isIndiaOffice = OpportunityHelper.isIndia(opty);
        Boolean isTaiwan = OpportunityHelper.isTaiwan(opty);
        Boolean isSelectPackagesByBusinessIdentity = Feature_Toggle__c.getInstance().SelectPackagesByBusinessIdentity__c;

        List<Validator> validators = new List<Validator> {
            unsupportedBrandValidator,
            verizonValidator,
            noQuotesValidator,
            swissVatIdValidator,
            taiwanVatIdValidator.enable(isTaiwan),
            noQuoteLineItemsValidator,
            proServQliToPhaseValidator,
            quoteHasErrorsValidator,
            activeAgreementValidator,
            packageLabelsValidator.enable(new List<Boolean> {isNewBilling, isPOC, isEngage}),
            docuSignNotCompleted.enable(isPOC),
            areaCodeAssignmentValidator.enable(new List<Boolean> {isNewBilling, isPOC}),
            ngbsOfficeSignUpValidator.enable(isNewBilling),
            contractPricingValidator.enable(new List<Boolean> {isNewBilling, isPOC}),
            contractAndActiveAgreementValidator.enable(new List<Boolean> {isNewBilling, isPOC, isEngage}),
            specialTermsRequireActiveAgreementValidator.enable(new List<Boolean> {isNewBilling, isPOC, isEngage}),
            specialTermsWithoutContractValidator.enable(new List<Boolean> {isNewBilling, isPOC, isEngage}),
            proServeProfileValidator,
            rcEventsAdminRoleValidator
        };

        if (!isMultiProductFTEnabled) {
            validators.add(3, new QuoteValidator.SignUp_ProfileValidator(qt)); //remove when old sign up flow will be removed
            validators.add(alreadySignedUpValidator.enable(new List<Boolean> {isNewBilling, isPOC, isEngage}));
        }

        validators.addAll(new List<Validator> {
            billingPackageExpirationValidator.enable(new List<Boolean>{isNewBilling, isPOC, isEngage}),
            areaCodeLineItemValidator.enable(new List<Boolean>{isNewBilling, isPOC}),
            productReachedSalesEndDateValidator.enable(new List<Boolean>{isNewBilling, isPOC, isEngage}),
            missApprovedPOCApprovalValidator.enable(isPOC),
            rentalPhoneValidator.enable(new List<Boolean>{isNewBilling, isEngage}),
            approvedInvoiceValidator.enable(new List<Boolean>{isNewBilling && !isSingapore && !isCreditCard, !isPOC && !isCreditCard}),
            directDebitThresholdValidator,
            directDebitLastApprovalValidator,
            expiredPromotionValidator.enable(isNewBilling && !isSingapore),
            hasIndiaInvoiceRequestValidator.enable(isIndiaOffice),
            kycApprovalValidator.enable(isIndiaOffice),
            primaryQuoteNotApprovedValidator,
            quantityLessThenShippingValidator,
            masterAccountActiveAgreementValidator.enable(new List<Boolean>{isInContact, isEngage})
        });

        if (!opty.IsMultiProductTechnicalOpportunity__c) {
            validators.add(officeMasterAccountValidator.enable(new List<Boolean>{isInContact, isEngage}));
        }

        validators.addAll(new List<Validator> {
            quoteHasPaymentMethodValidator.enable(isSelectPackagesByBusinessIdentity && OpportunityHelper.isSearchPackagesEnabledWithValidOppBI(opty) && !isPOC),
            billingCountryMatchBIValidator.enable(isInvoice),
            proservSyncAndSoldValidator,
            pendingTaxExemptionApprovalValidator,
            inProgressTaxExemptionApprovalValidator
        });
        if (QuoteHelper.isProServService(qt)) {
            validators.add(psFieldsValidation);
        }

        if (!opty.IsMultiProductTechnicalOpportunity__c) {
            validators.add(masterAccountIsPaidValidator);
        }

        validators.addAll(new List<Validator> {
            approvedInvoiceOnBehalfValidator.enable(new List<Boolean>{isNewBilling && !isSingapore, !isPOC}),
            approvedInvoiceWholesaleValidator.enable(new List<Boolean>{isNewBilling && !isSingapore, !isPOC}),
            elaBillingAccountValidator,
            bobValidator,
            quantityShippingValidator
        });

        resp = new HelperUtils.BaseValidator(validators).validate(resp);

        return resp;
    }
}