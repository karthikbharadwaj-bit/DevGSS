public with sharing class AccountValidator {
    public class SignUp_AlreadySignedUpValidator extends Validator{
        public Quote primaryQuote;
        public Opportunity opty;

        public SignUp_AlreadySignedUpValidator(String priority, Quote primaryQuote, Opportunity opty) {
            super(priority);
            this.primaryQuote = primaryQuote;
            this.opty = opty;
        }

        public SignUp_AlreadySignedUpValidator(Quote primaryQuote) {
            this.primaryQuote = primaryQuote;
        }

        public override void addErrorMessage(Response resp) {
            resp.addMessage(
                Label.QW_Notification_Related_Account_is_already_signed_up_text,
                Label.QW_Notification_Related_Account_is_already_signed_up_help_text,
                Response.SEVERITY_ERROR
            );
        }

        public override Boolean isFailedValidation () {
            return !OpportunityHelper.isInContact(opty) && primaryQuote.Account.RC_User_ID__c != null && primaryQuote.Account.Billing_ID__c != null;
        }
    }

    public class MasterAccountValidator extends Validator{
        public Opportunity opty;
        public AccountContactRole childAccountRole;
        public Account masterAccount;
        public Boolean isIndiaOpp;
        public Boolean isTaiwanOpp;
        public BillingWrappers.NGBSAccount accountInfo;

        public MasterAccountValidator(Opportunity opty,AccountContactRole childAccountRole, Account masterAccount,
            BillingWrappers.NGBSAccount accountInfo
        ) {
            this.opty = opty;
            this.childAccountRole = childAccountRole;
            this.masterAccount = masterAccount;
            this.isIndiaOpp = OpportunityHelper.isIndia(opty);
            this.isTaiwanOpp = OpportunityHelper.isTaiwan(opty);
            this.accountInfo = accountInfo;
        }

        public override void addErrorMessage(Response resp) {
             if (!isIndiaOpp && !isTaiwanOpp) {
                Boolean isSearchAmongContacts =
                    (FeatureManagement.checkPermission(CustomPermissionHelper.PERMISSION_EXPANDED_ENGAGE_BINDING));

                String helpText = isSearchAmongContacts
                    ? Label.Opportunity_Error_OnClose_Contacts_Mismatch
                    : Label.Opportunity_Error_OnClose_Contact_Roles_Mismatch;

                resp.addMessage(
                    Label.Opportunity_Error_OnClose_Cannot_close_this_oppty_text,
                    helpText,
                    Response.SEVERITY_ERROR
                );
            } else {
                resp.addMessage(
                    Label.Opportunity_Error_OnClose_Cannot_close_this_oppty_text,
                    Label.MasterAccountIsNotBindOnOpportunityClose,
                    Response.SEVERITY_ERROR
                );
            }
        }

        public override Boolean isFailedValidation () {

            if ((isIndiaOpp || isTaiwanOpp) && isMisMasterAcc()) {
                return true;
            }


            if (!OpportunityHelper.isEngageLegacy(opty) && !isIndiaOpp && !isTaiwanOpp) {
                if (isMisMasterAcc()
                    || isNotPaidMasterAccount()
                    || OpportunityHelper.isNotSuitableMasterAcc(childAccountRole, masterAccount)
                    ) {
                    return true;
                }
            }
            return false;
        }

        private Boolean isMisMasterAcc() {
            return masterAccount == null &&
                (OpportunityHelper.isEngageUnified(opty)
                    || OpportunityHelper.isEngageVoice(opty)
                    || OpportunityHelper.isEngageOmnichannel(opty)
                    || isIndiaOpp  || isTaiwanOpp
                    || OpportunityHelper.isInContact(opty));
        }

        private Boolean isNotPaidMasterAccount() {
            return masterAccount != null && (String.isBlank(masterAccount.RC_User_ID__c) || !isPaidAccount());
        }

        private Boolean isPaidAccount() {
            if (AccountHelper.PAID_STATUS.equalsIgnoreCase(masterAccount.RC_Account_Status__c)) {
                return true;
            }
            if (accountInfo != null && accountInfo.getPackage() != null) {
                return accountInfo.getPackage().isActive();
            }
            return false;
        }
    }

    public class SignUp_MasterAccountIsPaidValidator extends Validator{
        public Opportunity opty;
        public Account masterAccount;
        public Exception error;

        public SignUp_MasterAccountIsPaidValidator(Opportunity opty, Account masterAccount) {
            this.opty = opty;
            this.masterAccount = masterAccount;
        }

        public override void addErrorMessage(Response resp) {
            if (error != null) {
                resp.error(error);
                return;
            }

            String masterAccountLink = URL.getOrgDomainUrl().toExternalForm() + '/' + masterAccount?.Id;
            resp.addMessage(
                Label.Opportunity_SignUp_Master_Account_Is_Not_Paid,
                Label.Opportunity_SignUp_Master_Account_Is_Not_Paid_help_text,
                Response.SEVERITY_ERROR,
                masterAccountLink,
                'Master Account'
            );
        }

        public override Boolean isFailedValidation () {
            if (OpportunityHelper.isInContact(opty)) {
                try {
                    return isNotPaidMasterAccount() && !isActiveRegularAccount();
                } catch (Exception e) {
                    error = e.getCause();
                    return true;
                }
            }

            if (!OpportunityHelper.isEngageLegacy(opty)) {
                return isNotPaidMasterAccount();
            }
            return false;
        }

        private Boolean isNotPaidMasterAccount() {
            return masterAccount != null &&
                (String.isBlank(masterAccount.RC_User_ID__c) ||
                    !AccountHelper.PAID_STATUS.equalsIgnoreCase(masterAccount.RC_Account_Status__c));
        }

        private Boolean isActiveRegularAccount() {
            BillingWrappers.NGBSAccountPackage accountPackage =
                NGBSAPI.getNGBSAccount(masterAccount?.Billing_ID__c)?.getPackage();
            return accountPackage != null && accountPackage.isActiveRegular();
        }
    }

    public class MasterAccountActiveAgreementValidator extends Validator{
        public Account masterAccount;
        public Boolean onClose;

        public MasterAccountActiveAgreementValidator(Account masterAccount, Boolean onClose) {
            this.masterAccount = masterAccount;
            this.onClose = onClose;
        }

        public override void addErrorMessage(Response resp) {
            resp.addMessage(
                    onClose ? Label.Opportunity_Error_OnClose_Cannot_close_this_oppty_text : Label.Sign_Up_is_not_allowed,
                    Label.Bound_Account_Active_agreement_status_help_text,
                    Response.SEVERITY_ERROR
            );
        }

        public override Boolean isFailedValidation () {
            if (masterAccount != null) {
                return masterAccount.Active_Sales_Agreement__c == null;
            }
            return false;
        }
    }

    public class OfficeMasterAccountValidator extends Validator{
        public Account masterAccount;
        public Opportunity opty;
        public Boolean onClose = false;
        public BillingWrappers.NGBSAccount accountInfo;

        public OfficeMasterAccountValidator(Opportunity opty, Account masterAccount) {
            this.opty = opty;
            this.masterAccount = masterAccount;
        }

        public OfficeMasterAccountValidator(Opportunity opty, Account masterAccount,
            BillingWrappers.NGBSAccount accountInfo, Boolean onClose) {
            this(opty, masterAccount);
            this.onClose = onClose;
            this.accountInfo = accountInfo;
        }

        public override void addErrorMessage(Response resp) {
            resp.addMessage(
                onClose ? Label.Opportunity_Error_OnClose_Cannot_close_this_oppty_text : Label.Sign_Up_is_not_allowed,
                Label.Opportunity_Error_OnClose_Linked_Bound_Account_Office_help_text,
                Response.SEVERITY_ERROR
            );
        }

        public override Boolean isFailedValidation () {
            Boolean isFailedValidation = false;
            if (OpportunityHelper.isInContact(opty) || OpportunityHelper.isEngageVoiceStandalone(opty)) {
                isFailedValidation =
                    !AccountHelper.SERVICE_TYPE_OFFICE.equalsIgnoreCase(masterAccount?.Service_Type__c) &&
                    !AccountHelper.SERVICE_TYPE_OFFICE.equalsIgnoreCase(accountInfo?.getPackage()?.product);
            }
            return isFailedValidation;
        }
    }

    public class MasterAccountContractValidator extends Validator{
        public Account masterAccount;
        public Opportunity opty;

        public MasterAccountContractValidator(Opportunity opty, Account masterAccount) {
            this.opty = opty;
            this.masterAccount = masterAccount;
        }

        public override void addErrorMessage(Response resp) {
            resp.addMessage(
                    Label.Opportunity_Error_OnClose_Cannot_close_this_oppty_text,
                    Label.Opportunity_Error_OnClose_Linked_Bound_Account_Contract_help_text,
                    Response.SEVERITY_ERROR
            );
        }

        public override Boolean isFailedValidation () {
            Boolean isFailedValidation = false;
            if (String.isNotEmpty(masterAccount?.Active_Sales_Agreement__r?.Package_Info__c)) {
                List<BillingWrappers.QuotePackageInfo> pInfos = (List<BillingWrappers.QuotePackageInfo>)
                        JSON.deserialize(masterAccount.Active_Sales_Agreement__r.Package_Info__c, List<BillingWrappers.QuotePackageInfo>.class);
                BillingWrappers.QuotePackageInfo pInfo = pInfos[0];
                isFailedValidation = pInfo?.contract == null;
            }
            return isFailedValidation;
        }
    }

    public class ApprovedInvoiceValidatorParams {
        public Opportunity opp;
        public List<Approval__c> invoiceApprovals;
        public String paymentMethod;
        public Boolean onClose;
        public List<PartnerOperationsLog__c> partnerOperationsLogs;
        public Boolean isMPUB;
        public List<String> servicesOnPrimaryQuote;
        public Boolean isSingleQuote;
        public Set<String> extServices; 

        public ApprovedInvoiceValidatorParams(
            Opportunity opp,
            List<Approval__c> invoiceApprovals,
            String paymentMethod,
            Boolean onClose,
            List<PartnerOperationsLog__c> partnerOperationsLogs,
            Boolean isMPUB,
            List<String> servicesOnPrimaryQuote,
            Boolean isSingleQuote,
            Set<String> extServices
        ) {
            this.opp = opp;
            this.invoiceApprovals = invoiceApprovals;
            this.paymentMethod = paymentMethod;
            this.onClose = onClose;
            this.partnerOperationsLogs = partnerOperationsLogs;
            this.isMPUB = isMPUB;
            this.servicesOnPrimaryQuote = servicesOnPrimaryQuote;
            this.isSingleQuote = isSingleQuote;
            this.extServices = extServices;
        }
    }

    public class ApprovedInvoiceValidator extends Validator {
        public ApprovedInvoiceValidatorParams params;
        private String serviceNames = '';

        public ApprovedInvoiceValidator(ApprovedInvoiceValidatorParams params) {
            this.params = params;
        }

        public override void addErrorMessage(Response resp) {
            if (params.isMPUB) {
                resp.addMessage(
                params.onClose
                    ? Label.Opportunity_Error_OnClose_Cannot_close_this_oppty_text
                    : Label.Sign_Up_is_not_allowed,
                params.onClose
                    ? 'You won\'t be able to close this opportunity, please, obtain Invoice payment approval for ' + serviceNames + ' first.'
                    : 'You won\'t be able to sign up this account, please, obtain Invoice payment approval for ' + serviceNames + ' first.',
                Response.SEVERITY_ERROR
                );
            } else {
                resp.addMessage(
                params.onClose
                    ? Label.Opportunity_Error_OnClose_Cannot_close_this_oppty_text
                    : Label.Sign_Up_is_not_allowed,
                params.onClose
                    ? Label.Approved_Invoicing_Request_is_requred_on_oppty_close
                    : Label.Approved_Invoicing_Request_is_requred_on_sign_up,
                Response.SEVERITY_ERROR
                );
            }
        }

        public override Boolean isFailedValidation () {
            if (!params.partnerOperationsLogs.isEmpty()) {
                return false;
            }
            return QuoteHelper.isInvoice(params.paymentMethod) && !isApprovedInvoicingRequest();
        }

        private Boolean isApprovedInvoicingRequest() {
            if (params.isMPUB) {
                List<Approval__c> approvedInvoiceApprovals = new List<Approval__c>();
                for (Approval__c invApproval : params.invoiceApprovals) {
                    if (invApproval.Status__c == ApprovalHelper.STATUS_APPROVED) {
                        approvedInvoiceApprovals.add(invApproval);
                    }
                }
                Approval__c lastApprovedApproval = ApprovalHelper.getLastApprovedInvoiceApproval(approvedInvoiceApprovals, params.isSingleQuote);
                if (params.isSingleQuote) {
                    if (lastApprovedApproval == null || lastApprovedApproval.Monthly_Credit_Limit__c < 0 || lastApprovedApproval.Sign_Up_Purchase_Limit__c < 0) {
                        serviceNames = params.servicesOnPrimaryQuote[0];
                    }
                } else {
                    Map<String, Boolean> approvedServicesMap = new Map<String,Boolean>();
                    Boolean officeApproved = lastApprovedApproval?.Monthly_Credit_Limit_Office__c > 0 || lastApprovedApproval?.Sign_Up_Purchase_Limit_Office__c > 0;
                    approvedServicesMap.put(AccountHelper.SERVICE_TYPE_OFFICE, officeApproved);
                    Boolean ccApproved = lastApprovedApproval?.Monthly_Credit_Limit_Contact_Center__c > 0 || lastApprovedApproval?.Sign_Up_Purchase_Limit_Contact_Center__c > 0;
                    approvedServicesMap.put(AccountHelper.SERVICE_TYPE_RCCC, ccApproved);
                    Boolean engVoiceApproved = lastApprovedApproval?.Monthly_Credit_Limit_Engage_Voice__c > 0 || lastApprovedApproval?.Sign_Up_Purchase_Limit_Engage_Voice__c > 0;
                    approvedServicesMap.put(AccountHelper.SERVICE_TYPE_ENGAGE_VOICE, engVoiceApproved);
                    Boolean engDigitalApproved = lastApprovedApproval?.Monthly_Credit_Limit_Engage_Digital__c > 0 || lastApprovedApproval?.Sign_Up_Purchase_Limit_Engage_Digital__c > 0;
                    approvedServicesMap.put(AccountHelper.SERVICE_TYPE_ENGAGE_DIGITAL, engDigitalApproved);
                    Boolean proServApproved = lastApprovedApproval?.MonthlyCreditLimitProServ__c > 0 || lastApprovedApproval?.SignUpPurchaseLimitProServ__c > 0;
                    approvedServicesMap.put(AccountHelper.SERVICE_TYPE_PROFESSIONAL_SERVICES, proServApproved);
                    Boolean rcEventApproved = lastApprovedApproval?.Monthly_Credit_Limit_for_RC_Events__c > 0 || lastApprovedApproval?.Sign_Up_Purchase_Limit_for_RC_Events__c > 0;
                    approvedServicesMap.put(AccountHelper.SERVICE_TYPE_RC_EVENT, rcEventApproved);
                    for (String service : params.servicesOnPrimaryQuote) {
                        if ((!approvedServicesMap.containsKey(service) || !approvedServicesMap.get(service))
                            && params.extServices != null && !params.extServices.contains(service)) { 
                            serviceNames += service + ', ';
                        }
                    }
                    serviceNames = String.isEmpty(serviceNames) ? serviceNames : serviceNames.substring(0, serviceNames.length() - 2);
                }
                return String.isEmpty(serviceNames);
            } else {
                if (params.invoiceApprovals == null || params.invoiceApprovals.isEmpty()) {
                    return false;
                }
                for (Approval__c app : params.invoiceApprovals) {
                    if (app.Status__c == ApprovalHelper.STATUS_APPROVED &&
                        (app.Opportunity__c == params.opp.Id || params.onClose)) {
                        return true;
                    }
                }
            }
            return false;
        }
    }

    public class ApprovedInvoiceOnBehalfValidator extends Validator{
        public Opportunity opty;
        public Boolean onClose;
        public List<PartnerOperationsLog__c> partnerOperationsLogs;
        private Boolean isOutOfLimits = false;
        private Boolean isPartnerTypeChanged = false;

        public ApprovedInvoiceOnBehalfValidator(Opportunity opty, Boolean onClose, List<PartnerOperationsLog__c> partnerOperationsLogs) {
            this.opty = opty;
            this.onClose = onClose;
            this.partnerOperationsLogs = partnerOperationsLogs;
            this.isPartnerTypeChanged = !partnerOperationsLogs.isEmpty()
                && opty.Partner_Account__r.Partner_Type__c != null
                && opty.Partner_Account__r.Partner_Type__c != opty.Account.Partner_Type__c;
        }

        public override void addErrorMessage(Response resp) {
            String infoLabel = isPartnerTypeChanged ? Label.Invoice_Wholesale_Not_Approved : Label.Invoice_On_Behalf_Not_Approved;
            resp.addMessage(
                onClose ? Label.Opportunity_Error_OnClose_Cannot_close_this_oppty_text : Label.Sign_Up_is_not_allowed,
                (onClose && isOutOfLimits)
                    ? Label.Quote_Is_Outside_Limits
                    : onClose
                        ? infoLabel
                        : Label.Invoice_On_Behalf_Not_Approved_On_SignUp,
                Response.SEVERITY_ERROR
            );
        }

        public override Boolean isFailedValidation () {
            if (isPartnerTypeChanged) {
                return isApprovedWholesaleInvoice(opty);
            }
            return AccountHelper.isInvoiceOnBehalfAccount(opty.Account) && !AccountHelper.isApprovedInvoiceOnBehalf(opty.Account) || isQuoteOutsideLimits(opty);
        }

        private Boolean isApprovedWholesaleInvoice(Opportunity opty) {
            return AccountHelper.isWholesaleAccount(opty.Partner_Account__r) && !AccountHelper.isApprovedInvoiceWholesale(opty.Account) || isQuoteOutsideLimits(opty);
        }

        private Boolean isQuoteOutsideLimits(Opportunity opty) {
            if (!(partnerOperationsLogs.isEmpty() && !String.isEmpty(opty.Account.Billing_ID__c) && AccountHelper.isInvoiceOnBehalfAccount(opty.Account))) {
                return false;
            }
            Quote primaryQuote = (Quote) new QuoteSelector()
                .selectPrimaryQuotes(new List<Id>{opty.Id})
                .executeQuery()
                .get(0);

            Package__c pack = (Package__c) new PackageSelector()
                .selectPackageByAccountBillingId(opty.Account.Billing_ID__c)
                .executeQuery()
                .get(0);

            List<NGBSAPI.AccountPackageLimit> accPackageLimits = NGBSAPI.getAccountPackageLimits(opty.Account.Billing_ID__c, pack.Account_Package_Id__c);

            Decimal newMonthlyRecurringCharges = primaryQuote?.Entitlement_Total_MRR__c + primaryQuote?.Total_MRR_New__c;

            if (accPackageLimits[0].value <= newMonthlyRecurringCharges) {
                isOutOfLimits = true;
            }

            return (accPackageLimits[0].value <= newMonthlyRecurringCharges);
        }
    }

    public class ApprovedInvoiceWholesaleValidator extends Validator{
        public Opportunity opty;
        public Boolean onClose;
        public List<PartnerOperationsLog__c> partnerOperationsLogs;
        private Boolean isOutOfLimits = false;
        private Boolean isPartnerTypeChanged = false;

        public ApprovedInvoiceWholesaleValidator(Opportunity opty, Boolean onClose ,List<PartnerOperationsLog__c> partnerOperationsLogs) {
            this.opty = opty;
            this.onClose = onClose;
            this.partnerOperationsLogs = partnerOperationsLogs;
            this.isPartnerTypeChanged = !partnerOperationsLogs.isEmpty()
                && opty.Partner_Account__r.Partner_Type__c != null
                && opty.Partner_Account__r.Partner_Type__c != opty.Account.Partner_Type__c;
        }

        public override void addErrorMessage(Response resp) {
            String infoLabel = isPartnerTypeChanged ? Label.Invoice_On_Behalf_Not_Approved : Label.Invoice_Wholesale_Not_Approved;
            resp.addMessage(
                onClose ? Label.Opportunity_Error_OnClose_Cannot_close_this_oppty_text : Label.Sign_Up_is_not_allowed,
                (onClose && isOutOfLimits)
                    ? Label.Quote_Is_Outside_Limits
                    : onClose
                        ? infoLabel
                        : Label.Invoice_Wholesale_Not_Approved_On_SignUp,
                Response.SEVERITY_ERROR
            );
        }

        public override Boolean isFailedValidation () {
            if (isPartnerTypeChanged) {
                return isApprovedOnBehalfInvoice(opty);
            }
            return AccountHelper.isWholesaleAccount(opty.Account) && !AccountHelper.isApprovedInvoiceWholesale(opty.Account) || isQuoteOutsideLimits(opty);
        }

        private Boolean isApprovedOnBehalfInvoice(Opportunity opty) {
            return AccountHelper.isInvoiceOnBehalfAccount(opty.Partner_Account__r) && !AccountHelper.isApprovedInvoiceOnBehalf(opty.Account) || isQuoteOutsideLimits(opty);
        }

        private Boolean isQuoteOutsideLimits(Opportunity opty) {
            if (!(partnerOperationsLogs.isEmpty() && !String.isEmpty(opty.Account.Billing_ID__c) && AccountHelper.isWholesaleAccount(opty.Account))) {
                return false;
            }
            Quote primaryQuote = (Quote) new QuoteSelector()
                .selectPrimaryQuotes(new List<Id>{opty.Id})
                .executeQuery()
                .get(0);

            Package__c pack = (Package__c) new PackageSelector()
                .selectPackageByAccountBillingId(opty.Account.Billing_ID__c)
                .executeQuery()
                .get(0);

            List<NGBSAPI.AccountPackageLimit> accPackageLimits = NGBSAPI.getAccountPackageLimits(opty.Account.Billing_ID__c, pack.Account_Package_Id__c);

            Decimal newMonthlyRecurringCharges = primaryQuote?.Entitlement_Total_MRR__c + primaryQuote?.Total_MRR_New__c;

            if (accPackageLimits[0].value <= newMonthlyRecurringCharges) {
                isOutOfLimits = true;
            }

            return (accPackageLimits[0].value <= newMonthlyRecurringCharges);
        }
    }

    public class ELABillingAccountValidator extends Validator{
        public Account currAccount;
        public List<AccountRelation__c> accountsRel;

        public ELABillingAccountValidator(Account currAccount, List<AccountRelation__c> accountsRel) {
            this.currAccount = currAccount;
            this.accountsRel = accountsRel;
        }

        public override void addErrorMessage(Response resp) {

            resp.addMessage(
                Label.Opportunity_Sign_Up_Error_Ela_Child_Acc_Validation_help_text,
                Label.Opportunity_Sign_Up_Error_Ela_Child_Acc_Validation,
                Response.SEVERITY_ERROR
            );
            resp.setData('showAccountViewer', true);
        }

        public override Boolean isFailedValidation () {
            Boolean isFailedValidation = false;
            if (isCurrAccElaBillingAccount() && this.accountsRel != null) {
                for (AccountRelation__c accR : this.accountsRel) {
                    if (accR.Parent_Account__c == currAccount.Id &&
                        accR.Child_Account__c != null &&
                        !isChildAccElaServiceSignedActiveAccount(accR)
                        ) {
                        isFailedValidation = true;
                    }
                }
            }
            return isFailedValidation;
        }

        private Boolean isCurrAccElaBillingAccount() {
            return !String.isEmpty(currAccount.ELA_Account_Type__c) &&
                currAccount.ELA_Account_Type__c == AccountHelper.ACCOUNT_TYPE_ELA_BILLING;
        }

        private Boolean isChildAccElaServiceSignedActiveAccount(AccountRelation__c accR) {
            return accR.Relation_Type__c == AccountHelper.RELATION_TYPE_ELA &&
                String.isNotBlank(accR.Child_Account__r.Billing_ID__c);
        }
    }

    public class SyncWithNGBS_TerminatedAccountValidator extends Validator {
        private Account accToValidate;
        private Boolean isMaster;

        public SyncWithNGBS_TerminatedAccountValidator(Account accToValidate) {
            super();
            this.accToValidate = accToValidate;
            this.isMaster = false;
        }

        public SyncWithNGBS_TerminatedAccountValidator(Account accToValidate, Boolean isMaster) {
            super();
            this.accToValidate = accToValidate;
            this.isMaster = isMaster;
        }

        public override void addErrorMessage(Response resp) {
            if (isMaster) {
                resp.addMessage(
                    Label.IsNotAvailableToSyncWithNGBS,
                    Label.TerminatedMasterAccountOnOpportunity,
                    Response.SEVERITY_ERROR
                );
            } else {
                resp.addMessage(
                    Label.IsNotAvailableToSyncWithNGBS,
                    Label.TerminatedAccountOnOpportunity,
                    Response.SEVERITY_ERROR
                );
            }
        }

        public override Boolean isFailedValidation() {
            return isMaster
                ? AccountHelper.isTerminated(accToValidate.Master_Account__r?.RC_Account_Status__c)
                : AccountHelper.isTerminated(accToValidate.RC_Account_Status__c);
        }
    }

    public abstract class KYCApprovalGenericValidator extends Validator{
        private List<Approval__c> kycApprovals;

        public KYCApprovalGenericValidator(List<Approval__c> approvals) {
            super();
            this.kycApprovals = approvals;
        }
        public KYCApprovalGenericValidator(String severity, List<Approval__c> approvals) {
            super(severity);
            this.kycApprovals = approvals;

        }

        public override void addErrorMessage(Response resp) {
            addErrorMessageBody(resp);
        }
        protected abstract void addErrorMessageBody(Response resp);

        public override Boolean isFailedValidation() {
            if (kycApprovals == null || kycApprovals.isEmpty()) {
                return true;
            }
            Approval__c KYCApprWithLastStatusUpdate = kycApprovals[0];
            for (Approval__c approval : kycApprovals) {
                if (approval.StatusLastModifiedDate__c > KYCApprWithLastStatusUpdate.StatusLastModifiedDate__c) {
                    KYCApprWithLastStatusUpdate = approval;
                }
            }
            return KYCApprWithLastStatusUpdate.Status__c != ApprovalHelper.STATUS_APPROVED;
        }
    }

    public class KYCApprovalValidatorOnSignUp extends KYCApprovalGenericValidator{
        public KYCApprovalValidatorOnSignUp(List<Approval__c> approvals) {
            super(approvals);
        }
        public KYCApprovalValidatorOnSignUp(String severity, List<Approval__c> approvals) {
            super(severity, approvals);
        }

        public override void addErrorMessageBody(Response resp) {
            resp.addMessage(
                Label.Opportunity_SignUp_Validation_SignUp_failed,
                Label.KYCRequestIsNotApprovedOnSignUp,
                Response.SEVERITY_ERROR
            );
        }
    }

    public class KYCApprovalValidatorOnOpportunityClose extends KYCApprovalGenericValidator{
        public KYCApprovalValidatorOnOpportunityClose(List<Approval__c> approvals) {
            super(approvals);
        }
        public KYCApprovalValidatorOnOpportunityClose(String severity, List<Approval__c> approvals) {
            super(severity, approvals);
        }

        public override void addErrorMessageBody(Response resp) {
            resp.addMessage(
                Label.Opportunity_Error_OnClose_Cannot_close_this_oppty_text,
                Label.KYCRequestIsNotApprovedOnOpportunityClose,
                Response.SEVERITY_ERROR
            );
        }
    }

    public class BoundPartnerAccountsValidator extends Validator {
        private List<Account> boundAccs;

        public BoundPartnerAccountsValidator(List<Account> boundAccs) {
            this.boundAccs = boundAccs;
        }

        public override void addErrorMessage(Response resp) {
            resp.addMessage(
                Label.Sign_Up_is_not_allowed,
                Label.SignUp_BoundPartnerAccountsMismatch,
                Response.SEVERITY_ERROR
            );
        }

        public override Boolean isFailedValidation() {
           if (boundAccs.isEmpty()) {
                return false;
            }

            Set<String> partnerTypes = new Set<String>();
            Set<String> partnerIds = new Set<String>();
            Integer bobPartnerAccsCount = 0;

            for (Account acc : boundAccs) {
                if (
                    AccountHelper.ACCOUNT_ENGAGE_STANDALONE_PARTNER_TYPES.contains(acc.Partner_Type__c)
                        && acc.Partner_ID__c != null
                    ) {
                    partnerTypes.add(acc.Partner_Type__c);
                    partnerIds.add(acc.Partner_ID__c);
                    bobPartnerAccsCount++;
                }
            }
            /*
             * if ALL bound accounts doesn't have partner type or partner id
             * or ALL of them have the same partner type and partner id
             * then validation is passed
            */
            if (
                bobPartnerAccsCount == 0
                    || bobPartnerAccsCount == boundAccs.size()
                        && partnerTypes.size() == 1
                        && partnerIds.size() == 1
                ) {
                return false;
            } else {
                return true;
            }
        }
    }
}