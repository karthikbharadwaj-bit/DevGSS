public class SWNMessageHelper {
    @TestVisible
    static final String INFO_HEADER = 'Info';
    @TestVisible
    static final String NOTHING_TO_SYNC_MSG = 'Nothing to sync';
    @TestVisible
    static final String UPSELL_UPGRADE_AT_SAME_TIME_HEADER = 'Quantity change is not supported with simultaneous Package and/or Plan change';
    @TestVisible
    static final String UPSELL_UPGRADE_AT_SAME_TIME_MSG = 'Please change Package and/or Plan in Billing Admin Portal manually. <br/>' +
        'Please create separate Opportunity to change any Product Quantity after Package and/or Plan are successfully changed manually. ';
    @TestVisible
    static final String SUSPENDED_NGBS_STATUS_MSG = 'You are working with Suspended Account. You might need to check validity of the Payment Method of the Account.';
    @TestVisible
    static final String CONTRACT_SYNCED_HEADER = 'Contracts already synced';
    @TestVisible
    static final String CONTRACT_SYNCED_MSG = 'Contracts for this quote were already synced';
    @TestVisible
    static final String REPRICE_RESPONSE_EXCEEDS_HEAP_HEADER = 'System was unable to handle NGBS response';
    @TestVisible
    static final String REPRICE_RESPONSE_EXCEEDS_HEAP_MSG = 'Please check that all discounts are synced correctly';
    @TestVisible
    static final String SYNC_DISCOUNT_HEADER = 'Sync Discount';
    @TestVisible
    static final String SYNC_CONTRACT_HEADER = 'Sync Contract';
    @TestVisible
    static final String SYNC_CONTRACT_MSG = 'Contracts were successfully sent to the billing system';
    @TestVisible
    static final String SYNC_REPRICE_HEADER = 'Process Order';
    @TestVisible
    static final String SYNC_REPRICE_MSG = 'Price has been successfully changed';
    @TestVisible
    static final String REPRICE_SKIPPED_HEADER = 'Step is skipped';
    @TestVisible
    static final String REPRICE_SKIPPED_MSG = 'Reprice step is skipped(Nothing to sync)';
    @TestVisible
    static final String SPENDING_LIMIT_RETRIEVED_HEADER = 'Spending limits retrieved';
    @TestVisible
    static final String SPENDING_LIMIT_RETRIEVED_MSG = 'Spending limits retrieved successfully';
    @TestVisible
    static final String COMMON_PERMISSION_HEADER = 'You don\'t have permission to use Process Order';
    @TestVisible
    static final String COMMON_PERMISSION_MSG = 'Please contact Sales Ops for assistance';
    @TestVisible
    static final String SUCCESS_HEADER = 'Success';
    @TestVisible
    static final String CHARGE_TERM_SYNCED_MSG = 'Charge term plan successfully synced to the billing system';
    @TestVisible
    static final String PKG_AND_LICENSES_QUANTITIES_SYNCED_MSG = 'Package and licenses quantities successfully synced to the billing system';
    @TestVisible
    static final String LICENSES_QUANTITIES_SYNCED_MSG = 'License quantities successfully synced to the billing system';
    @TestVisible
    static final String PKG_CONSOLIDATION_SETTINGS_SYNCED_MSG = 'Package Consolidation Settings synced successfully';
    @TestVisible
    static final String ACC_PACKAGE_LIMITS_SYNCED_MSG = 'Account Package Limits synced successfully';
    @TestVisible
    static final String PAYMENT_METHOD_SYNCED_MSG = 'Payment Method synced successfully';
    @TestVisible
    static final String ACC_PAYMENT_CONTACT_SYNCED_MSG = 'Account Payment Contact synced successfully';

    public class SWNMessage {
        public String status;
        public String header;
        public String message;
        public String stackTrace;

        public SWNMessage() {}

        public SWNMessage(String status, String header, String message) {
            this.status = status;
            this.header = header;
            this.message = message;
        }

        public SWNMessage(String status, String header, String message, String stackTrace) {
            this(status, header, message);
            this.stackTrace = stackTrace;
        }
    }

    public class CompositeResult {
        public SWNMessage baseMessage;
        public Map<String, Object> data = new Map<String, Object>();

        public CompositeResult() {
            this.baseMessage = new SWNMessage();
        }
        
        public CompositeResult(SWNMessage message) {
            this.baseMessage = message;
        }
        
        public void addData(String key, Object value) {
            this.data.put(key, value);
        }
    }

    public enum LabelMessage {
        //error message
        NO_PERMISSION_SYNC_WITH_NGBS_ERROR,
        NO_PERMISSION_SYNC_RCCC_ERROR,
        NO_PERMISSION_SYNC_RINGCX_ERROR,
        DIRECT_DEBIT_LIMIT_EXCEEDED,
        OVERRIDE_LICENSE_LIMITS_FOR_POC,
        LICENSE_LIMITS_OVERRIDE_IF_EXISTS_LBOX_ON_QLI,
        LICENSE_LIMITS_OVERRIDE_IF_PKG_INFO_ON_QUOTE,
        CANCEL_CONTRACT_IF_NO_PKG_INFO_ON_QUOTE,
        //info message
        SUSPENDED_NGBS_STATUS,
        CONTRACTS_ALREADY_SYNCED,
        REPRICE_RESPONSE_EXCEEDS_HEAP,
        NOTHING_TO_SYNC,
        //success message
        SYNC_CONTRACTS_SUCCESS,
        SYNC_DISCOUNTS_SUCCESS,
        SYNC_REPRICE_SUCCESS,
        REPRICE_IS_SKIPPED,
        SYNC_SPENDING_LIMIT_RETRIEVE_SUCCESS,
        ACCOUNT_PAYMENT_CONTACT_SYNCED,
        PAYMENT_METHOD_SYNCED,
        ACC_PACKAGE_LIMITS_SYNCED,
        PKG_CONSOLIDATION_SETTINGS_SYNCED,
        ACCOUNT_TERMINATION_SUCCESS,
        LICENSE_QUANTITY_SYNCED,
        UPGRADE_SYNC_SUCCESS,
        CHARGE_TERM_SYNCED,
        LICENSE_LIMIT_OVERRIDE_SUCCESS,
        CANCEL_CONTRACT_SUCCESS
    }

    public abstract class MessageBuilder {
        @TestVisible
        protected final String status;
        @TestVisible
        final Map<LabelMessage, SWNMessage> messagesMap;

        public MessageBuilder(String status) {
            this.status = status;
            this.messagesMap = buildMessages();
        }

        protected abstract Map<LabelMessage, SWNMessage> buildMessages();

        public SWNMessage getSWNMessage(LabelMessage messageLabel) {
            return messagesMap.get(messageLabel);
        }

        public SWNMessage buildSWNMessage(String header, String message, String stackTrace) {
            return new SWNMessage(status, header, message, stackTrace);
        }
    }

    public class InfoMessagesBuilder extends MessageBuilder {
        public InfoMessagesBuilder() {
            super(Response.STATUS_INFO);
        }

        protected override Map<LabelMessage, SWNMessage> buildMessages() {
            return new Map<LabelMessage, SWNMessage> {
                LabelMessage.SUSPENDED_NGBS_STATUS => buildSuspendedNGBSStatusInfoMsg(),
                LabelMessage.CONTRACTS_ALREADY_SYNCED => buildContractAlreadySyncedInfoMsg(),
                LabelMessage.REPRICE_RESPONSE_EXCEEDS_HEAP => buildRepriceResponseExceedsHeapInfoMsg(),
                LabelMessage.NOTHING_TO_SYNC => buildNothingToSyncInfoMsg()
            };
        }

        @TestVisible
        private SWNMessage buildNothingToSyncInfoMsg() {
            return new SWNMessage(
                status,
                INFO_HEADER,
                NOTHING_TO_SYNC_MSG
            );
        }

        @TestVisible
        private SWNMessage buildSuspendedNGBSStatusInfoMsg() {
            return new SWNMessage(
                status,
                '',
                SUSPENDED_NGBS_STATUS_MSG
            );
        }

        @TestVisible
        private SWNMessage buildContractAlreadySyncedInfoMsg() {
            return new SWNMessage(
                status,
                CONTRACT_SYNCED_HEADER,
                CONTRACT_SYNCED_MSG
            );
        }

        @TestVisible
        private SWNMessage buildRepriceResponseExceedsHeapInfoMsg() {
            return new SWNMessage(
                status,
                REPRICE_RESPONSE_EXCEEDS_HEAP_HEADER,
                REPRICE_RESPONSE_EXCEEDS_HEAP_MSG
            );
        }
    }

    public class SuccessMessagesBuilder extends MessageBuilder {
        public SuccessMessagesBuilder() {
            super(Response.STATUS_SUCCESS);
        }

        protected override Map<LabelMessage, SWNMessage> buildMessages() {
            return new Map<LabelMessage, SWNMessage> {
                LabelMessage.SYNC_CONTRACTS_SUCCESS => buildSyncContractsSuccessMsg(),
                LabelMessage.SYNC_REPRICE_SUCCESS => buildSyncRepriceSuccessMsg(),
                LabelMessage.REPRICE_IS_SKIPPED => buildRepriceIsSkippedSuccessMsg(),
                LabelMessage.SYNC_SPENDING_LIMIT_RETRIEVE_SUCCESS => buildSyncSpendingLimitRetrieveSuccessMsg(),
                LabelMessage.SYNC_DISCOUNTS_SUCCESS => buildSyncDiscountsSuccessMsg(),
                LabelMessage.ACCOUNT_PAYMENT_CONTACT_SYNCED => buildAccPaymentContactSyncedSuccessMsg(),
                LabelMessage.PAYMENT_METHOD_SYNCED => buildPaymentMethodSyncedSuccessMsg(),
                LabelMessage.ACC_PACKAGE_LIMITS_SYNCED => buildAccPackageLimitsSyncedSuccessMsg(),
                LabelMessage.PKG_CONSOLIDATION_SETTINGS_SYNCED => buildPkgConsolidationSettingsSyncedSuccessMsg(),
                LabelMessage.ACCOUNT_TERMINATION_SUCCESS => buildAccountTerminationSuccessMsg(),
                LabelMessage.LICENSE_QUANTITY_SYNCED => buildLicenseQuantitySyncedSuccessMsg(),
                LabelMessage.UPGRADE_SYNC_SUCCESS => buildUpgradeSyncSuccessMsg(),
                LabelMessage.CHARGE_TERM_SYNCED => buildChargeTermSyncedSuccessMsg(),
                LabelMessage.LICENSE_LIMIT_OVERRIDE_SUCCESS => buildLicenseLimitsOverrideSuccessMsg(),
                LabelMessage.CANCEL_CONTRACT_SUCCESS => buildCancelContractSuccessMsg()
            };
        }

        @TestVisible
        private SWNMessage buildCancelContractSuccessMsg() {
            return new SWNMessage(
                status,
                Label.Contract_Cancellation_succeeded,
                ''
            );
        }

        @TestVisible
        private SWNMessage buildLicenseLimitsOverrideSuccessMsg() {
            return new SWNMessage(
                status,
                Label.License_limits_override_succeeded,
                ''
            );
        }

        @TestVisible
        private SWNMessage buildChargeTermSyncedSuccessMsg() {
            return new SWNMessage(
                status,
                SUCCESS_HEADER,
                CHARGE_TERM_SYNCED_MSG
            );
        }
        
        @TestVisible
        private SWNMessage buildUpgradeSyncSuccessMsg() {
            return new SWNMessage(
                status,
                SUCCESS_HEADER,
                PKG_AND_LICENSES_QUANTITIES_SYNCED_MSG
            );
        }

        @TestVisible
        private SWNMessage buildLicenseQuantitySyncedSuccessMsg() {
            return new SWNMessage(
                status,
                SUCCESS_HEADER,
                LICENSES_QUANTITIES_SYNCED_MSG
            );
        }

        @TestVisible
        private SWNMessage buildAccountTerminationSuccessMsg() {
            return new SWNMessage(
                status,
                SUCCESS_HEADER,
                Label.Account_Termination_succeeded
            );
        }

        @TestVisible
        private SWNMessage buildPkgConsolidationSettingsSyncedSuccessMsg() {
            return new SWNMessage(
                status, 
                SUCCESS_HEADER,
                PKG_CONSOLIDATION_SETTINGS_SYNCED_MSG
            );
        }

        @TestVisible
        private SWNMessage buildAccPackageLimitsSyncedSuccessMsg() {
            return new SWNMessage(
                status, 
                SUCCESS_HEADER,
                ACC_PACKAGE_LIMITS_SYNCED_MSG
            );
        }

        @TestVisible
        private SWNMessage buildPaymentMethodSyncedSuccessMsg() {
            return new SWNMessage(
                status, 
                SUCCESS_HEADER,
                PAYMENT_METHOD_SYNCED_MSG
            );
        }

        @TestVisible
        private SWNMessage buildAccPaymentContactSyncedSuccessMsg() {
            return new SWNMessage(
                status, 
                SUCCESS_HEADER,
                ACC_PAYMENT_CONTACT_SYNCED_MSG
            );
        }

        @TestVisible
        private SWNMessage buildSyncDiscountsSuccessMsg() {
            return new SWNMessage(
                status, 
                SYNC_DISCOUNT_HEADER,
                Label.Billing_success_message
            );
        }

        @TestVisible
        private SWNMessage buildSyncContractsSuccessMsg() {
            return new SWNMessage(
                status, 
                SYNC_CONTRACT_HEADER,
                SYNC_CONTRACT_MSG
            );
        }

        @TestVisible
        private SWNMessage buildSyncRepriceSuccessMsg() {
            return new SWNMessage(
                status, 
                SYNC_REPRICE_HEADER,
                SYNC_REPRICE_MSG
            );
        }

        @TestVisible
        private SWNMessage buildRepriceIsSkippedSuccessMsg() {
            return new SWNMessage(
                status, 
                REPRICE_SKIPPED_HEADER,
                REPRICE_SKIPPED_MSG
            );
        }

        @TestVisible
        private SWNMessage buildSyncSpendingLimitRetrieveSuccessMsg() {
            return new SWNMessage(
                status, 
                SPENDING_LIMIT_RETRIEVED_HEADER,
                SPENDING_LIMIT_RETRIEVED_MSG
            );
        }
    }

    public class ErrorMessagesBuilder extends MessageBuilder {
        public ErrorMessagesBuilder() {
            super(Response.STATUS_ERROR);
        }

        protected override Map<LabelMessage, SWNMessage> buildMessages() {
            return new Map<LabelMessage, SWNMessage> {
                LabelMessage.NO_PERMISSION_SYNC_WITH_NGBS_ERROR => buildNoPermissionSyncWithNGBSErrorMsg(),
                LabelMessage.NO_PERMISSION_SYNC_RCCC_ERROR => buildNoPermissionSyncRCCCErrorMsg(),
                LabelMessage.NO_PERMISSION_SYNC_RINGCX_ERROR => buildNoPermissionSyncRingCXErrorMsg(),
                LabelMessage.DIRECT_DEBIT_LIMIT_EXCEEDED => buildDirectDebitLimitExceededErrorMsg(),
                LabelMessage.OVERRIDE_LICENSE_LIMITS_FOR_POC => buildOverrideLimitsForPOCErrorMsg(),
                LabelMessage.LICENSE_LIMITS_OVERRIDE_IF_EXISTS_LBOX_ON_QLI => buildLimitOverrideIfExistsLboxOnQliErrorMsg(),
                LabelMessage.LICENSE_LIMITS_OVERRIDE_IF_PKG_INFO_ON_QUOTE => buildLimitOverrideIfPkgInfoExistsOnQuoteErrorMsg(),
                LabelMessage.CANCEL_CONTRACT_IF_NO_PKG_INFO_ON_QUOTE => buildCancelContractIfNoPkgInfoErrorMsg()

            };
        }

        @TestVisible
        private SWNMessage buildCancelContractIfNoPkgInfoErrorMsg() {
            return new SWNMessage(
                status,
                Label.Contract_Cancellation_no_package_info_on_quote,
                Label.Please_contact_your_manager
            );
        }

        @TestVisible
        private SWNMessage buildLimitOverrideIfPkgInfoExistsOnQuoteErrorMsg() {
            return new SWNMessage(
                status,
                Label.License_limits_override_no_package_info_on_quote,
                Label.Please_contact_your_manager
            );
        }

        @TestVisible
        private SWNMessage buildLimitOverrideIfExistsLboxOnQliErrorMsg() {
            return new SWNMessage(
                status,
                Label.License_limits_override_no_lboxes_exist_for_qli,
                Label.Please_contact_your_manager
            );
        }
        
        @TestVisible
        private SWNMessage buildOverrideLimitsForPOCErrorMsg() {
            return new SWNMessage(
                status,
                Label.License_limits_override_for_non_POC_account,
                Label.Please_contact_your_manager
            );
        }

        @TestVisible
        private SWNMessage buildNoPermissionSyncWithNGBSErrorMsg() {
            return new SWNMessage(
                status,
                COMMON_PERMISSION_HEADER,
                COMMON_PERMISSION_MSG
            );
        }

        @TestVisible
        private SWNMessage buildNoPermissionSyncRCCCErrorMsg() {
            return new SWNMessage(
                status, 
                COMMON_PERMISSION_HEADER + ' for Contact Center',
                COMMON_PERMISSION_MSG
            );
        }

        @TestVisible
        private SWNMessage buildNoPermissionSyncRingCXErrorMsg() {
            return new SWNMessage(
                status, 
                COMMON_PERMISSION_HEADER + ' for Engage',
                COMMON_PERMISSION_MSG
            );
        }

        @TestVisible
        private SWNMessage buildDirectDebitLimitExceededErrorMsg() {
            return new SWNMessage(
                status, 
                Label.IsNotAvailableToSyncWithNGBS,
                Label.Approval_Direct_Debit_Limit_Error
            );
        }
    }
}