public class AccountHelper {
    public static Schema.DescribeSObjectResult DESCRIBE {
        get {
            if(DESCRIBE == null) {
                DESCRIBE = Account.SObjectType.getDescribe();
            }
            return DESCRIBE;
        }
        set;
    }
    public static Map<String, Schema.RecordTypeInfo> RT_INFO_BY_NAME {
        get {
            if(RT_INFO_BY_NAME == null) {
                RT_INFO_BY_NAME = DESCRIBE.getRecordTypeInfosByName();
            }
            return RT_INFO_BY_NAME;
        }
        set;
    }
    public static final Map<String, SObjectField> FIELDS_MAP = DESCRIBE?.fields.getMap();

    public static final Feature_Toggle__c featureToggle = Feature_Toggle__c.getInstance();

    public static final String RT_NAME_CUSTOMER_ACCOUNT = 'Customer Account';
    public static final String RT_NAME_BB_ACCOUNT = 'BBAccount';
    public static final String RT_NAME_PARTNER_ACCOUNT = 'Partner Account';
    public static final String VAT_NUMBER_EXCEPTION_APPROVAL = 'VAT Number entered does not match the VAT Number in VAT exemption approval. Please remove the existing VAT exemption approval or create a new approval if you need to update the VAT Number.';
    public static final String PARTNER_APPROVAL_EXCEPTION  = 'record is already created.';
    public static final String PARTNER_APPROVAL_VALIDATION_EXCEPTION = 'Account does not meet the requirements for Partner Approval.';
    public static final String GST_NUMBER_EXCEPTION_APPROVAL = 'Please remove the existing exemption approval or create a new approval if you need to update the GST Number.';
    public static final String VAT_NUMBER_EXCEPTION_ACCOUNT = 'VAT Number entered does not match the VAT Number on Account. Please remove or change the existing VAT Number if you need to update the VAT Number.';
    public static final String VAT_NUMBER_NOTIFICATION_ACCOUNT = 'VAT Number will be removed once you save the address.';
    public static final String RT_NAME_ZI_ACCOUNT = 'ZI Customer Shell Account';
    public static final String ACCOUNT_STATUS_TRIAL = 'TRIAL';
    public static final String ACCOUNT_STATUS_FREE = 'Free';
    public static final String ACCOUNT_STATUS_TERMINATED = 'terminated';
    public static final String ACCOUNT_STATUS_CANCELED = 'canceled';
    public static final String ACCOUNT_STATUS_CANCELLED = 'cancelled';
    public static final String ACCOUNT_STATUS_DELETED = 'deleted';
    public static final String ACCOUNT_STATUS_DISABLED = 'disabled';
    public static final String ACCOUNT_STATUS_SUSPENDED = 'suspended';
    public static final String ACCOUNT_STATUS_PAID = 'paid';
    public static final Integer LEGACY_OFFSET = 130000000;
    public static final Integer BLOCK_ID = 990;
    public static final Id RT_ID_ZI_ACCOUNT = RT_INFO_BY_NAME.get(RT_NAME_ZI_ACCOUNT).getRecordTypeId();
    public static final List<String> RENEWAL_OPP_ACCOUNT_STATUS_LIST = new List<String>{
        AccountHelper.PAID_STATUS,
        AccountHelper.SUSPENDED_STATUS
    };

    // Account Partners Type
    public static final String ACCOUNT_PARTNER_BILL_ON_BEHALF = 'Bill-on-Behalf';
    public static final String ACCOUNT_PARTNER_ALCATEL_LUCENT_BILL_ON_BEHALF = 'Alcatel-Lucent - Bill-on-Behalf';
    public static final String ACCOUNT_PARTNER_ATOS_BILL_ON_BEHALF = 'Atos - Bill-on-Behalf';
    public static final String ACCOUNT_PARTNER_AVAYA_BILL_ON_BEHALF = 'Avaya - Bill-on-Behalf';
    public static final String ACCOUNT_PARTNER_WHOLESALE = 'Wholesale-Reseller';
    public static final String ACCOUNT_PARTNER_ALCATEL_LUCENT_WHOLESALE = 'Alcatel-Lucent - Wholesale-Reseller';
    public static final String ACCOUNT_PARTNER_ATOS_WHOLESALE = 'Atos - Wholesale-Reseller';
    public static final String ACCOUNT_PARTNER_AVAYA_WHOLESALE = 'Avaya - Wholesale-Reseller';
    public static final String ACCOUNT_PARTNER_GENERAL = 'General Partner';
    public static final String ACCOUNT_PARTNER_MASTER_AGENT = 'Master Agent';
    public static final String ACCOUNT_PARTNER_EXPRESS_AGENT = 'Partner Express Agent';
    public static final String ACCOUNT_PARTNER_SALES_AGENT = 'Sales Agent';

    public static final List<String> ACCOUNT_BILL_ON_BEHALF_PARTNERS = new List<String>{
        ACCOUNT_PARTNER_BILL_ON_BEHALF,
        ACCOUNT_PARTNER_ALCATEL_LUCENT_BILL_ON_BEHALF,
        ACCOUNT_PARTNER_ATOS_BILL_ON_BEHALF,
        ACCOUNT_PARTNER_AVAYA_BILL_ON_BEHALF
    };

    public static final List<String> ACCOUNT_ENGAGE_STANDALONE_PARTNER_TYPES = new List<String>{
        ACCOUNT_PARTNER_BILL_ON_BEHALF,
        ACCOUNT_PARTNER_GENERAL,
        ACCOUNT_PARTNER_MASTER_AGENT,
        ACCOUNT_PARTNER_EXPRESS_AGENT,
        ACCOUNT_PARTNER_SALES_AGENT
    };

    public static final List<String> ACCOUNT_WHOLESALE_PARTNERS = new List<String>{
        ACCOUNT_PARTNER_WHOLESALE,
        ACCOUNT_PARTNER_ALCATEL_LUCENT_WHOLESALE,
        ACCOUNT_PARTNER_ATOS_WHOLESALE,
        ACCOUNT_PARTNER_AVAYA_WHOLESALE
    };

    public static final Set<String> TERMINATED_ACCOUNT_STATUSES = new Set<String>{
        ACCOUNT_STATUS_TERMINATED,
        ACCOUNT_STATUS_CANCELED,
        ACCOUNT_STATUS_CANCELLED,
        ACCOUNT_STATUS_DELETED,
        ACCOUNT_STATUS_DISABLED
    };

    public static final Set<String> FEATURE_ADD_ONS_ACCOUNT_STATUSES = new Set<String>{
        ACCOUNT_STATUS_PAID,
        ACCOUNT_STATUS_CANCELED,
        ACCOUNT_STATUS_CANCELLED,
        ACCOUNT_STATUS_DISABLED
    };

    public static final List<String> INACTIVE_ACCOUNT_STATUSES = new List<String>{
        'Suspended',
        'Canceled',
        'Disabled'
    };

    public static final Id RT_ID_CUSTOMER_ACCOUNT = RT_INFO_BY_NAME.get(RT_NAME_CUSTOMER_ACCOUNT).getRecordTypeId();
    //public static final Id RT_ID_BB_ACCOUNT = RT_INFO_BY_NAME.get(RT_NAME_BB_ACCOUNT).getRecordTypeId();
    public static final Id RT_ID_PARTNER_ACCOUNT = RT_INFO_BY_NAME.get(RT_NAME_PARTNER_ACCOUNT).getRecordTypeId();

    // Billing_System__c
    public final static String BILLING_SYSTEM_NBS = 'NBS';

    // Package_Status__c
    public final static String PACKAGE_STATUS_INITIAL = 'Initial';
    public final static String PACKAGE_STATUS_ACTIVE = 'Active';

    // Service_Type__c
    public final static String SERVICE_TYPE_OFFICE = Constants.CONST_OFFICE;
    public final static String SERVICE_TYPE_PROFESSIONAL = Constants.CONST_PROFESSIONAL;
    public final static String SERVICE_TYPE_FAX = Constants.CONST_FAX;
    public final static String SERVICE_TYPE_RCCC = Constants.CONST_RCCC;
    public final static String SERVICE_TYPE_ENGAGE_VOICE = Constants.CONST_ENGAGE_VOICE;
    public final static String SERVICE_TYPE_ENGAGE_DIGITAL = Constants.CONST_ENGAGE_DIGITAL;
    public final static String SERVICE_TYPE_ENGAGE_DIGITAL_LEGACY = Constants.CONST_ENGAGE_DIGITAL_LEGACY;
    public final static String SERVICE_TYPE_ENGAGE_VOICE_LEGACY = Constants.CONST_ENGAGE_VOICE_LEGACY;
    public final static String SERVICE_TYPE_RC_EVENT = Constants.CONST_RC_EVENT;
    public final static String SERVICE_TYPE_PROFESSIONAL_SERVICES = 'Professional Services';

    // Service_name__c
    public final static String SERVICE_NAME_RC_OFFICE = 'RC Office';

    // Account_Graduation_Status__c
    public final static String GRADUATION_STATUS_DONE = 'DONE';
    public final static String GRADUATION_STATUS_GRADUATION_PHASE = 'Graduation Phase';
    public final static String GRADUATION_STATUS_ADOPTION = 'Adoption/Maturity Phase';

    // PartnerStatus__c
    public final static String ACTIVE_STATUS = 'Active';
    public final static String MIGRATED_STATUS = 'Migrated';
    public final static String DECLINED_STATUS = 'Declined';
    public final static String PENDING_STATUS = 'Pending';
    public final static String NEW_STATUS = 'New';
    public final static String CANCELLED_STATUS = 'Cancelled';

    // Status
    public final static String PAID_STATUS = 'Paid';
    public final static String SUSPENDED_STATUS = 'Suspended';
    public final static String DISABLED_STATUS = 'Disabled';
    public final static String CANCELED_STATUS = 'Canceled';

    /* Type */
    public static final String TYPE_CUSTOMER = 'Customer';
    public static final String TYPE_PARTNER = 'Partner';
    public static final String OFFER_TYPE_POC = 'PoC';
    public static final String OFFER_TYPE_TRIAL = 'Trial';

    //Account_Payment_Method__c
    public static final String PAYMENT_METHOD_INVOICE = 'Invoice';
    public static final String PAYMENT_METHOD_INVOICE_ON_BEHALF = 'Invoice On Behalf';
    public static final String PAYMENT_METHOD_WHOLESALE = 'InvoiceWholesale';
    public static final String PAYMENT_METHOD_CREDIT_CARD = 'Credit Card';
    public static final String PAYMENT_METHOD_NGBS_CREDIT_CARD = 'CreditCard';
    public static final String PAYMENT_METHOD_DIRECT_DEBIT = 'Direct Debit';
    public static final String PAYMENT_METHOD_DIRECTDEBIT = 'DirectDebit';
    public final static String PAYMENT_METHOD_NONE = 'None';
    public static final String PAYMENT_METHOD_PARTNER_BILLING_NGBS = 'Partner Billing (NGBS)';

    // GSP validation error message constant
    public static final String NON_GSP_OWNER_ERROR = 'Owner of GSP Account cannot be a Non GSP User';

    public static final String ENGAGE_VALIDATION_VAT_EXCEPTION = 'Engage Digital doesn\\\'t support setting VAT Number from Account. Please create VAT Exemption Approval.';

    //ELA_Account_Type__c
    public static final String ACCOUNT_TYPE_ELA_SERVICE = 'ELA Service';
    public static final String ACCOUNT_TYPE_ELA_BILLING = 'ELA Billing';

    // AccMigrationFlag__c
    public static final String ACCOUNT_MIGRATION_TYPE_IN_PROGRESS = 'InProgress';
    public static final String ACCOUNT_MIGRATION_TYPE_SCHEDULED = 'Scheduled';
    public static final String ACCOUNT_MIGRATION_TYPE_IN_PROGRESS_BLOCKED = 'InProgressBlocked';
    public static final String ACCOUNT_MIGRATION_TYPE_SCHEDULED_BLOCKED = 'ScheduledBlocked';
    public static final String ACCOUNT_MIGRATION_TYPE_ROLLBACKED = 'Rollbacked';
    public static final String ACCOUNT_MIGRATION_TYPE_MIGRATED = 'Migrated';

    public static final Set<String> ACCOUNT_MIGRATION_SCHEDULED_TYPES = new Set<String> {
        ACCOUNT_MIGRATION_TYPE_SCHEDULED,
        ACCOUNT_MIGRATION_TYPE_SCHEDULED_BLOCKED
    };

    public static final Set<String> ACCOUNT_MIGRATION_IN_PROGRESS_TYPES = new Set<String> {
        ACCOUNT_MIGRATION_TYPE_IN_PROGRESS,
        ACCOUNT_MIGRATION_TYPE_IN_PROGRESS_BLOCKED
    };

    public static final Set<String> MIGRATION_STATUSES = new Set<String>();
    public static final Set<String> ALL_MIGRATION_STATUSES = new Set<String> {
        ACCOUNT_MIGRATION_TYPE_ROLLBACKED,
        ACCOUNT_MIGRATION_TYPE_MIGRATED
    };

    static {
        MIGRATION_STATUSES.addAll(ACCOUNT_MIGRATION_SCHEDULED_TYPES);
        MIGRATION_STATUSES.addAll(ACCOUNT_MIGRATION_IN_PROGRESS_TYPES);
        ALL_MIGRATION_STATUSES.addAll(MIGRATION_STATUSES);
    }

    //Postfix for billing account name
    public static final String ACCOUNT_BILLABLE_POSTFIX = ' - Billable';

    public static final Map<String, String> ACCOUNT_TYPE_ELA_MAP = new Map<String, String>{
        AccountHelper.ACCOUNT_TYPE_ELA_SERVICE => 'Service',
        AccountHelper.ACCOUNT_TYPE_ELA_BILLING => 'Billing'
    };

    //AccountRelation__c.Relation_Type__c
    public static final String RELATION_TYPE_ELA = 'ELA';
    public static final String RELATION_TYPE_CONTRACT_SYNC = 'Contract Sync';

    // Service_Status__c
    public static final String SERVICE_STATUS_CONTRACT_COMPLETE = 'Contract Complete';

    public static final String ACCOUNT_RELATION_CHILD_NAME = 'Child_Account_Relation__r';
    public static final String ACCOUNT_RELATION_PARENT_NAME = 'Parent_Account_Relation__r';
    public static final String ACCOUNT_RELATION_MASTER_ACCOUNTS_NAME = 'Master_Accounts__r';
    public static final String ACCOUNT_RELATION_TECH_ACCOUNTS_NAME = 'Service_Accounts1__r';
    public static final String ACCOUNT_RELATION_ACCOUNT_CONTACT_ROLES = 'AccountContactRoles';

    // Payment_Plan__c
    public static final String ACCOUNT_PAYMENT_PLAN_MONTHLY = 'Monthly';

    public static Schema.ChildRelationship CHILD_ACCOUNT_JUNCTION_RELATIONSHIP {
        get {
            if(CHILD_ACCOUNT_JUNCTION_RELATIONSHIP == null) {
                CHILD_ACCOUNT_JUNCTION_RELATIONSHIP = SFDescribeHelper.getChildRelationship(AccountHelper.DESCRIBE, ACCOUNT_RELATION_CHILD_NAME);
            }
            return CHILD_ACCOUNT_JUNCTION_RELATIONSHIP;
        }
        set;
    }

    public static Schema.ChildRelationship PARENT_ACCOUNT_JUNCTION_RELATIONSHIP {
        get {
            if(PARENT_ACCOUNT_JUNCTION_RELATIONSHIP == null) {
                PARENT_ACCOUNT_JUNCTION_RELATIONSHIP = SFDescribeHelper.getChildRelationship(AccountHelper.DESCRIBE, ACCOUNT_RELATION_PARENT_NAME);
            }
            return PARENT_ACCOUNT_JUNCTION_RELATIONSHIP;
        }
        set;
    }

    /* Nda Status */
    public static final String NDA_GENERATED = 'Generated';
    public static final String NDA_OUT_FOR_SIGNATURE = 'Out for Customer Signature';

    public static final Map<String, String> DOCUSIGN_TO_NDA_STATUS = new Map<String, String> {
        'Completed' => 'Signed by Customer',
        'Expired'   => 'Voided',
        'Voided'    => 'Voided by RingCentral',
        'Declined'  => 'Voided by Customer'
    };

    public static Schema.ChildRelationship MASTER_ACCOUNT_JUNCTION_RELATIONSHIP {
        get {
            if(MASTER_ACCOUNT_JUNCTION_RELATIONSHIP == null) {
                MASTER_ACCOUNT_JUNCTION_RELATIONSHIP = SFDescribeHelper.getChildRelationship(AccountHelper.DESCRIBE, ACCOUNT_RELATION_MASTER_ACCOUNTS_NAME);
            }
            return MASTER_ACCOUNT_JUNCTION_RELATIONSHIP;
        }
        set;
    }
    public static Schema.ChildRelationship ACCOUNT_CONTACT_ROLES_RELATIONSHIP {
        get {
            if(ACCOUNT_CONTACT_ROLES_RELATIONSHIP == null) {
                ACCOUNT_CONTACT_ROLES_RELATIONSHIP = SFDescribeHelper.getChildRelationship(AccountHelper.DESCRIBE, ACCOUNT_RELATION_ACCOUNT_CONTACT_ROLES);
            }
            return ACCOUNT_CONTACT_ROLES_RELATIONSHIP;
        }
        set;
    }

    public static final Set<String> BILLING_ADDRESS_FIELDS = new Set<String>{
        'BillingCity',
        'BillingCountry',
        'BillingPostalCode',
        'BillingState',
        'BillingStreet'
    };

    /**
     * Check if Account migrated to NGBS
     */

    public static Boolean isAccFlagMigrated(Account acc) {
        return StringHelper.safeString(acc?.AccMigrationFlag__c).containsIgnoreCase(ACCOUNT_MIGRATION_TYPE_MIGRATED);
    }

    public static Boolean isAccFlagInAnyMigrationStatus(Account acc) {
        return ALL_MIGRATION_STATUSES.contains(acc?.AccMigrationFlag__c);
    }

    public static Boolean isMigrationInProgress(String accMigrationFlag) {
        return ACCOUNT_MIGRATION_IN_PROGRESS_TYPES.contains(accMigrationFlag);
    }

    public static Boolean isTrial(Account acc) {
        return StringHelper.safeString(acc?.RC_Account_Status__c).containsIgnoreCase(ACCOUNT_STATUS_TRIAL);
    }

    public static Boolean isPaid(Account acc) {
        return StringHelper.safeString(acc?.RC_Account_Status__c).containsIgnoreCase(PAID_STATUS);
    }

    public static Boolean isElaService(Account acc) {
        return ACCOUNT_TYPE_ELA_SERVICE == acc?.ELA_Account_Type__c;
    }

    public static Boolean isTerminated(Account acc) {
        return isTerminated(acc?.RC_Account_Status__c);
    }

    public static Boolean isTerminated(String status) {
        return TERMINATED_ACCOUNT_STATUSES.contains(status?.toLowerCase());
    }

    public static Boolean isInactive(Account acc) {
        return TERMINATED_ACCOUNT_STATUSES.contains(acc?.RC_Account_Status__c?.toLowerCase())
            || acc?.RC_Account_Status__c?.toLowerCase() == ACCOUNT_STATUS_SUSPENDED;
    }

    public static Boolean isInContactLegacyExistingBusiness(Account masterAccount) {
        if (masterAccount == null) {
            return false;
        }

        return masterAccount.inContact_account_ID__c != null;
    }

    public static Boolean isInvoiceOnBehalfAccount(Account acc) {
        return String.isNotEmpty(acc?.Partner_ID__c) && ACCOUNT_BILL_ON_BEHALF_PARTNERS.contains(acc?.Partner_Type__c);
    }

    public static Boolean isWholesaleAccount(Account acc) {
        return String.isNotEmpty(acc?.Partner_ID__c) && ACCOUNT_WHOLESALE_PARTNERS.contains(acc?.Partner_Type__c);
    }

    public static Boolean accountInvoiceOnBehalfSwitch(Account newAcc, Account oldAcc) {
        return ((isInvoiceOnBehalfAccount(newAcc) && !isInvoiceOnBehalfAccount(oldAcc)) ||
            (!isInvoiceOnBehalfAccount(newAcc) && isInvoiceOnBehalfAccount(oldAcc)));
    }

    public static Boolean accountWholesaleSwitch(Account newAcc, Account oldAcc) {
        return ((isWholesaleAccount(newAcc) && !isWholesaleAccount(oldAcc)) ||
            (!isWholesaleAccount(newAcc) && isWholesaleAccount(oldAcc)));
    }

    public static Boolean isCreditCardAccount(Account acc) {
        return acc?.Account_Payment_Method__c == AccountHelper.PAYMENT_METHOD_CREDIT_CARD
            || acc?.Account_Payment_Method__c == AccountHelper.PAYMENT_METHOD_NGBS_CREDIT_CARD;
    }

    public static Boolean isAnyInvoiceAccount(Account acc) {
        return acc.Payment_Method__c == PAYMENT_METHOD_INVOICE
            || acc.Payment_Method__c == PAYMENT_METHOD_INVOICE_ON_BEHALF
            || acc.Payment_Method__c == PAYMENT_METHOD_WHOLESALE;
    }

    public static Boolean isApprovedInvoiceOnBehalf(Account acc) {
        List<Approval__c> approvals = (List<Approval__c>) new ApprovalSelector()
            .selectInvoiceApprovalsForPayableInfo(new List<Object>{
                new List<Id> { ApprovalHelper.RT_ID_INVOICE_ON_BEHALF_REQUEST },
                new Set<Id>{ acc.Id },
                new List<String>{ ApprovalHelper.STATUS_APPROVED }
            })
            .executeQuery();
        return approvals != null && !approvals.isEmpty();
    }

    public static Boolean isApprovedInvoiceWholesale(Account acc) {
        List<Approval__c> approvals = (List<Approval__c>) new ApprovalSelector()
            .selectInvoiceApprovalsForPayableInfo(new List<Object>{
                new List<Id> { ApprovalHelper.RT_ID_INVOICE_WHOLESALE_REQUEST },
                new Set<Id>{ acc.Id },
                new List<String>{ ApprovalHelper.STATUS_APPROVED }
            })
            .executeQuery();
        return approvals != null && !approvals.isEmpty();
    }

    public static List<Account> generateElaServiceAccounts(Account elaBillingAccount, Integer amount, String name) {
        List<Account> elaServiceAccountList = new List<Account>();
        Account elaServiceAccount;
        do {
            elaServiceAccount = elaBillingAccount.clone(false, false, false);
            elaServiceAccount.ELA_Account_Type__c = AccountHelper.ACCOUNT_TYPE_ELA_SERVICE;
            elaServiceAccount.Name = Name;
            elaServiceAccountList.add(elaServiceAccount);
            --amount;
        } while (amount > 0);
        return elaServiceAccountList;
    }

    public static AccountContactRole createAccountContactRole(Id accountId, Id contactId) {
        return new AccountContactRole(
            AccountId = accountId,
            ContactId = contactId,
            IsPrimary = true
        );
    }

    public static AccountRelation__c createAccountRelationEla(Id parentId, Id childId) {
        return new AccountRelation__c(
            Parent_Account__c = parentId,
            Child_Account__c = childId,
            Relation_Type__c = AccountHelper.RELATION_TYPE_ELA
        );
    }

    public static void convertAccountToElaBilling(Account elaBillingAccount) {
        elaBillingAccount.ELA_Account_Type__c = AccountHelper.ACCOUNT_TYPE_ELA_BILLING;
        elaBillingAccount.Name = StringHelper.safeSubstring(elaBillingAccount.Name,
            Account.Name.getDescribe().length - AccountHelper.ACCOUNT_BILLABLE_POSTFIX.length()) +
            AccountHelper.ACCOUNT_BILLABLE_POSTFIX;
    }

    public static Boolean isBillingAddressEmpty(Account acc) {
        return acc == null ||
            (String.isBlank(acc.BillingCountry)
            || String.isBlank(acc.BillingState)
            || String.isBlank(acc.BillingPostalCode)
            || String.isBlank(acc.BillingCity)
            || String.isBlank(acc.BillingStreet));
    }

    public static void updateWholesalePartnerInformation(Opportunity opp) {
        Account acc = opp.Account;

        List<PartnerOperationsLog__c> operationLogList = QuoteHelper.getPartnerOperationLog(opp.Id);

        if (!isWholesaleAccount(acc) && operationLogList.isEmpty()) {
            return;
        }

        List<Approval__c> lastApprovedApprovals = (List<Approval__c>) new ApprovalSelector()
            .selectApprovalsForPartnerOperations(
                new List<Object>{
                    new Set<Id>{ ApprovalHelper.RT_ID_INVOICE_WHOLESALE_REQUEST },
                    new Set<Id>{ acc.id },
                    new List<String>{ ApprovalHelper.STATUS_APPROVED }
                },
                new List<String>{
                    'Account__c',
                    'SwitchInvoicePartnerAccount__c',
                    'PartnerAccountPayableContact__c',
                    'Opportunity__c'
                }
            )
            .executeQuery();

        if (lastApprovedApprovals.isEmpty()){
            return;
        }

        Account partnerAccount =  (Account) new AccountSelector()
            .selectPartnerAccountsByIds(new List<Object>{
                    new Set<Id>{lastApprovedApprovals[0]?.SwitchInvoicePartnerAccount__c}
                })
            .executeQuery()
            .get(0);

        acc = copyPartnerInformation(acc, partnerAccount);
        acc.Partner_Contact__c = lastApprovedApprovals[0]?.PartnerAccountPayableContact__c;

        opp.Partner_Account__c = acc.Partner_Account__c;
        opp.Partner_Contact__c = acc.Partner_Contact__c;

        Triggers.switchOff();
        update acc;
        update opp;
        Triggers.switchOn();
    }

    public static Account copyPartnerInformation(Account acc, Account partnerAcc) {
        acc.Partner_Account__c = partnerAcc.Id;
        acc.Partner_ID__c = partnerAcc.Partner_ID__c;
        acc.Partner_Type__c = partnerAcc.Partner_Type__c;
        acc.Partner_Account_Name__c = partnerAcc.Name;
        acc.Parent_Partner_Account__c = partnerAcc.Parent_Partner_Account__c;
        acc.Ultimate_Partner_Name__c = partnerAcc.Ultimate_Partner_Name__c;
        acc.Ultimate_Partner_ID__c = partnerAcc.Ultimate_Partner_ID__c;
        acc.Settlement_Type__c = partnerAcc.Settlement_Type__c;
        return acc;
    }

    public static Account getMasterAccount(Account acc) {
        return acc.IsMultiProductTechnicalAccount__c ? acc.Master_Account__r : acc;
    }

    public static Account getPartnerAccountById(Id partnerId) {
        Account partnerAccount;
        List<Account> partnerAccounts = (List<Account>) new AccountSelector()
            .selectPartnerAccountsByIds(new List<Object>{
                    new Set<Id>{partnerId}
                })
                .subselect(new AccountContactRoleSelector()
                .selectAccountContactRoles()
                .selectFields(new List<String>{
                    'ContactId'
                })
                .setCondition('Role = \'Accounts Payable\''))
            .executeQuery();

        if (!partnerAccounts.isEmpty()) {
            partnerAccount = partnerAccounts.get(0);
        }

        return partnerAccount;
    }

    public static Boolean isExistingBusiness(Account acc) {
        return String.isNotBlank(acc?.Billing_ID__c);
    }

    public static Decimal getNgbsPartnerId(Id accountId) {
        Account account = (Account) new AccountSelector().selectAccountById(accountId)
            .executeQuery()
            .get(0);
        return Account.NGBS_Partner_ID__c;
    }

    public static Boolean isSingaporeBillingCountry(Account acc) {
        return acc?.BillingCountry == 'Singapore';
    }

    public static Boolean isEBIndianAccount(Account acc) {
        return acc?.RC_Brand__c == OpportunityHelper.BRAND_RINGCENTRAL_EU
            && acc?.CurrencyIsoCode == OpportunityHelper.CURRENCY_NAME_INR;
    }

    public static Boolean isAustraliaBillingCountry(Account acc) {
        return acc != null && acc.BillingCountry == 'Australia';
    }

    public static Boolean isPartner(Account acc) {
        return acc?.RecordTypeId == RT_ID_PARTNER_ACCOUNT;
    }

    public static Boolean isContracted(Account acc) {
        return acc?.Active_Sales_Agreement__c != null;
    }

    public static Map<Id, Boolean> updateAccountIdToIsMPUBMap(Map<Id, Boolean> accountIdToIsMPUBMap, Account acc) {
        if (accountIdToIsMPUBMap.get(acc.Id) == null) {
            accountIdToIsMPUBMap.put(acc.Id, isMPUBAccount(acc));
        }
        return accountIdToIsMPUBMap;
    }

    public static Boolean isMPUBAccount(Account acc) {
        if (acc == null || acc.IsMultiProductTechnicalAccount__c) {
            return false;
        }

        return isMPUBAccount(acc.Id);
    }

    public static Boolean isMPUBAccount(Id accountId) {
        if (String.isBlank(accountId)) {
            return false;
        }

        if (!featureToggle.EnableMultiProductUnifiedBilling__c) {
            return false;
        }

        return isMPUBAccount(accountId, getTechnicalAccounts(accountId));
    }

    public static Boolean isMPUBAccount(Id accountId, List<Account> techAccounts) {
        if (String.isBlank(accountId) || techAccounts == null) {
            return false;
        }

        if (!featureToggle.EnableMultiProductUnifiedBilling__c) {
            return false;
        }

        return techAccounts.isEmpty();
    }

    public static Map<String, Account> getTechnicalAccountsByMasterId(
        Id masterAccountId
    ) {
        List<Account> technicalAccounts = getTechnicalAccounts(masterAccountId);
        Map<String, Account> result = new Map<String, Account>();

        for(Account acc: technicalAccounts) {
            result.put(acc.Service_Type__c, acc);
        }

        return result;
    }

    public static List<Account> getTechnicalAccounts(Id masterAccountId) {
        return new AccountSelector()
            .selectMPTechAccountsByMasterIds(masterAccountId)
            .subselect(new PackageSelector(ACCOUNT_RELATION_TECH_ACCOUNTS_NAME, Account.SObjectType).selectPackageForApproval())
            .executeQuery();
    }

    public static Set<String> TECH_ACCOUNT_FIELDS_CLEAR = new Set<String>{
        'Billing_ID__c',
        'Package_Status__c',
        'RC_Account_Number__c',
        'RC_Account_Status__c',
        'RC_Activation_Date__c',
        'RC_Edition__c',
        'RC_Plan_Renewal_Date__c',
        'RC_Service_ID__c',
        'RC_Service_Name__c',
        'RC_Signup_Date__c',
        'RC_Signup_Funnel__c',
        'RC_Sync_Status__c',
        'RC_Tier__c',
        'RC_Tier_ID__c',
        'RC_Upgrade_Date__c',
        'RC_User_ID__c',
        'Sales_Booking_MRS__c',
        'Service_Version__c',
        'Sign_up_Purchase_Limit__c',
        'SignupType__c',
        'Total_Contract_Value_Calculated__c',
        'Total_Contract_Value_Override__c',
        'ParentId',
        'Active_Sales_Agreement__c',
        'Ultimate_Account__c',
        'Ultimate_Parent_Snapshot__c',
        'Ultimate_Partner_ID__c',
        'Ultimate_Partner_Name__c',
        'Total_DLs__c',
        'Total_Potential_Users__c',
        'VideoProvider__c',
        'Actual_transport_MRR__c',
        'Additional_Products_MRR__c',
        'aMRR__c',
        'MRR_Transfer_Effective_Date__c',
        'MRR_of_current_customers__c',
        'Farming_Assignment_MRR__c'
    };

    private static Set<String> ACCOUNT_UNIQUE_FIELDS = SObjectDescribeHelper.getDescribe(Account.SObjectType).getUniqueFieldNames();
    public static Map<String, Account> createTechnicalAccounts(
        Id masterAccountId,
        String[] serviceNames
    ) {
        Account masterAccount = (Account) new AccountSelector()
            .selectAccountByIdWithAllFields(masterAccountId)
            .executeQuery()
            .get(0);

        return createTechnicalAccounts(masterAccount, serviceNames);
    }

    public static Map<String, Account> createTechnicalAccounts(
        Account masterAccount,
        String[] serviceNames
    ) {
        Map<String, Account> technicalAccounts = getTechnicalAccountsByMasterId(masterAccount.Id);
        User technicalUser = UserHelper.getMultiproductTechnicalUser();

        List<Account> accountsToCreate = new List<Account>();
        for (String serviceName: serviceNames) {
            if (!QuoteHelper.CREATE_TECHNICAL_ACCOUNT_FOR_SERVICES.contains(serviceName)) {
                continue;
            }

            if (!technicalAccounts.containsKey(serviceName)) {
                Account clonedAccount = masterAccount.clone(false, false, false, false);

                for (String fieldName : ACCOUNT_UNIQUE_FIELDS) {
                    clonedAccount.put(fieldName, null);
                }

                for (String fieldName : TECH_ACCOUNT_FIELDS_CLEAR) {
                    clonedAccount.put(fieldName, null);
                }

                clonedAccount.Master_Account__c = masterAccount.Id;
                clonedAccount.Service_Type__c = serviceName;
                clonedAccount.IsMultiProductTechnicalAccount__c = true;
                clonedAccount.Name = String.format('{0} [system: {1}]', new List<Object> { masterAccount.Name, serviceName});
                clonedAccount.EnterpriseCustomerID__c = masterAccount.RC_User_ID__c;

                if (technicalUser != null) {
                    clonedAccount.OwnerId = technicalUser.Id;
                }

                accountsToCreate.add(clonedAccount);
            }
        }

        Map<String, Account> result = new Map<String, Account>();
        if (!accountsToCreate.isEmpty()) {
            TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT = true;
            insert accountsToCreate;
            TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT = false;
        }

        List<Id> createdAccountIds = (List<Id>) AquivaHelper.collectFieldValues(List<Id>.class, accountsToCreate, 'Id', true);

        List<Account> createdAccounts = new AccountSelector()
            .selectMPTechAccountsByIdsForCopying(createdAccountIds)
            .executeQuery();

        for (Account createdAccount : createdAccounts) {
            result.put(createdAccount.Service_Type__c, createdAccount);
        }

        // part of incremental save.
        for (Account technicalAccount : technicalAccounts.values()) {
            if (!result.containsKey(technicalAccount.Service_Type__c)) {
                result.put(technicalAccount.Service_Type__c, technicalAccount);
            }
        }

        return result;
    }

    public static Boolean isPackageActive(String status) {
        return PACKAGE_STATUS_ACTIVE.equalsIgnoreCase(status);
    }

    public static String generateEnterpriseAccountId() {
        Id orgId = UserInfo.getOrganizationId();
        RCSequence__c rcSequence = [
            SELECT SubSequence__c, SandboxNumber__c
            FROM RCSequence__c
            WHERE SetupOwnerId =: orgId FOR UPDATE
        ].get(0);
        Integer sq = NumberHelper.toNumber((Integer) rcSequence.SubSequence__c) + 1;

        rcSequence.SubSequence__c = sq;
        update rcSequence;

        Integer sequenceShift = 1000;
        Integer envShift = 0;
        Integer envNumber = NumberHelper.toNumber((Integer) rcSequence.SandboxNumber__c);
        if (envNumber > 0) {
            Integer sequenceShiftMultiplier = (Integer) Math.pow(10, (Double) String.valueOf(envNumber).length());
            envShift = sequenceShift * envNumber;
            sequenceShift = sequenceShift * sequenceShiftMultiplier;
        }

        return String.valueOf(LEGACY_OFFSET + sequenceShift*sq + envShift + BLOCK_ID);
    }

    public static Boolean isPOCToPaid(Account acc) {
        if (acc == null) {
            return false;
        }
        Boolean isOfferTypePOCOrTrial = String.isNotBlank(acc.Offer_Type__c)
            && (acc.Offer_Type__c.containsIgnoreCase(OFFER_TYPE_TRIAL) || acc.Offer_Type__c.equalsIgnoreCase(OFFER_TYPE_POC));

        Boolean isStatusPOCOrTrial = String.isNotBlank(acc.RC_Account_Status__c)
            && (acc.RC_Account_Status__c.containsIgnoreCase(OFFER_TYPE_TRIAL) || acc.RC_Account_Status__c.equalsIgnoreCase(OFFER_TYPE_POC));

        return String.isNotBlank(acc.Billing_ID__c)
            && (acc.RC_Account_Status__c != PAID_STATUS && acc.Offer_Type__c != PAID_STATUS)
            && (isOfferTypePOCOrTrial || isStatusPOCOrTrial);
    }

    @AuraEnabled
    public static Response getAccountNameById(Id accId){
        Response res = new Response();
        Account acc = (Account) new AccountSelector()
            .selectAccountById(accId)
            .executeQuery()
            .get(0);

        res.setData('Name', acc.Name);
        return res;
    }

    public static Boolean isAccountHasCCEntitlements(String accountId) {
        Boolean hasCCEntitlements = false;
        List<Entitlement__c> entitlements = new EntitlementSelector()
            .getEntitlements(accountId)
            .executeQuery();

        if (entitlements.isEmpty()){
            return hasCCEntitlements;
        }

        for (Entitlement__c ent: entitlements) {
            if (Product2Helper.isCCProduct(ent.Product__r)) {
                hasCCEntitlements = true;
                break;
            }
        }
        return hasCCEntitlements;
    }

    public class FunnelNotSupportedProductsHandler {
        private Id accId;
        private Id oppId;
        private SubscriberInfoBuilder.AssignmentData[] assignments;
        private Boolean isLBO;

        public FunnelNotSupportedProductsHandler(
            Id accId,
            Id oppId,
            SubscriberInfoBuilder.AssignmentData[] assignments,
            Boolean isLBO
        ) {
            this.accId = accId;
            this.oppId = oppId;
            this.assignments = assignments;
            this.isLBO = isLBO;
        }

        public FunnelNotSupportedProductsHandler(Id accId, Id oppId) {
            this.accId = accId;
            this.oppId = oppId;
        }

        public String getProductsDescription() {
            String resultStr = getHeaderDescription();
            resultStr += '\n\n';
            for (SubscriberInfoBuilder.AssignmentData ad : assignments) {
                resultStr += getQLIDescription(ad.parent, ad.quantity);
                resultStr += '\n\n';

                if (ad.child != null) {
                    resultStr += getQLIDescription(ad.child, ad.quantity);
                    resultStr += '\n\n';
                }

                if (ad.areaCode != null && !isLBO) {
                    resultStr += getACdescription(ad.areaCode);
                    resultStr += '\n\n';
                }

                resultStr += '\n\n';
            }

            return resultStr;
        }

        public String getHeaderDescription() {

            String headerString = '';

            String urlToAccount = StringHelper.createObjectLink(accId);
            String urlToOpportunity = StringHelper.createObjectLink(oppId);

            headerString += 'Account: "' + urlToAccount + '" \n';
            headerString += 'Opportunity: "' + urlToOpportunity + '" \n\n';

            headerString += 'Products that should be provisioned manually: \n\n';

            return headerString;
        }

        public String getQLIDescription(QuoteLineItem qli, Integer quantity) {
            String resultStr = '';

            String discountStr = NumberHelper.toNumber(qli.Discount_number__c) + ' ' +
                (qli.Discount_Type__c == QuoteLineItemHelper.DISCOUNT_TYPE_PERCENTAGE
                    ? '% '
                    : qli.CurrencyIsoCode
                );

            resultStr += 'Product Name: ' + qli.Display_Name__c +
                '; Charge Term: ' + qli.ChargeTerm__c +
                '; Quantity: ' + quantity +
                '; Discount: ' + discountStr +
                ';';

            return resultStr;
        }

        private String getACDescription(SubscriberInfoBuilder.AreaCodeData acd) {
            return 'Area Code: ' + acd.areaCode + ' ' + acd.city + ' ' + acd.country + ';';
        }
    }

    public static Map<String, Set<Id>> getSupportedAccountIdsGroupedBySupportType(Set<Id> accountIds) {
        Map<String, Set<Id>> result = new Map<String, Set<Id>>();
        for (Entitlement entitlement : (List<Entitlement>) new SupportEntitlementSelector()
                                            .selectSupportEntitlementsByAccountIds(accountIds).executeQuery()) {
            if (!result.containsKey(entitlement.Type)) {
                result.put(entitlement.Type, new Set<Id>());
            }
            result.get(entitlement.Type).add(entitlement.AccountId);
        }
        return result;
    }

    public static void prepareAccountForUpdating(
        Package__c targetPkg,
        Account accountToUpdate,
        Map<Id, Account> accountsToUpdate
    ) {
        for (SObjectField packageField : PackageHelper.PACKAGE_FIELDS) {
            SObjectField accountField = PackageHelper.PACKAGE_TO_ACCOUNT_FIELDS_MAP.get(packageField);
            Object accountFieldValue = accountToUpdate.get(accountField);
            Object packageFieldValue = targetPkg.get(packageField);

            if (accountFieldValue == packageFieldValue) {
                continue;
            }

            accountToUpdate.put(accountField, packageFieldValue);
            accountsToUpdate.put(accountToUpdate.Id, accountToUpdate);
        }
    }
}