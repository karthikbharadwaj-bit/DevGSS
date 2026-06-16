/**************************************************************************************************
 * Project Name..........:                                                                         *
 * File..................: AccountTriggerHelper.class                                              *
 * Version...............: 1.0                                                                     *
 * Created by............: Simplion Technologies                                                   *
 * Created Date..........: 29-01-2014                                                              *
 * Last Modified by......: Simplion Technologies                                                   *
 * Last Modified Date....: 29-01-2014                                                              *
 * Description...........: This is a helper class for Account.trigger.                             *
 **************************************************************************************************/

public class AccountTriggerHelper {
    public static Map<Id, Account> newAccountMap = new Map<Id, Account>();
    public static Map<Id, Account> oldAccountMap = new Map<Id, Account>();

    public static final String CC_PAYMENT_TYPE_MONTH_TO_MONTH = 'Month-to-Month';
    public static final String CC_PAYMENT_TYPE_ANNUAL = 'Annual';
    public static final String CC_PAYMENT_TYPE_ANNUAL_PRE_PAY = 'Annual Pre-Pay';
    public static final String INVOICE_PAYMENT_METHOD = 'Invoice';
    public static final String ACCOUNT_STATUS_PAID = 'Paid';

    public static final String SIGN_UP_TYPE_TRIAL_30NOCC = 'TRIAL_30NOCC';
    public static final String SIGN_UP_TYPE_TRIAL_30CC = 'trial_30CC';
    public static final String SIGN_UP_TYPE_TRIAL_15CC = 'trial_15CC';
    public static final String OFFICE_TRIAL_15DAYS = '15 Days';
    public static final String OFFICE_TRIAL_30DAYS = '30 Days';
    public static final String RC_BRAND_BT_CLOUD_PHONE = 'BT Cloud Phone';
    public static final String TEAM_MEMBER_ROLE_ACCOUNT_MANAGER = 'Account Manager';
    public static final Set<String> COUNTRY_REQUIRE_STATE = new Set<String>{
        'usa',
        'us',
        'united states',
        'united states of america',
        'can',
        'canada',
        'aus',
        'australia',
        'uk',
        'united kingdom',
        'gb',
        'great britain'
    };

    private static ImplementationMethods im = new ImplementationMethods();
    private static List<Survey__c> surveyListTOInsert = new List<Survey__c>();
    private static List<Lead> leadList = new List<Lead>();
    private static Set<Id> contractOwnerId = new Set<Id>();
    private static Set<String> partnerAccountIdSet = new Set<String>();
    private static Map<String, Account> partnerAccMap = new Map<String, Account>();
    private static Map<Id, User> userMap = new Map<Id, User>();

    private static final String SERVICE_NAME_RC_OFFICE ='RC Office';
    private static final String RC_ATTR_CHANNEL_SALES_AGENT_RESELLERS = 'Sales Agents & Resellers';
    private static final String ACCOUNT_TYPE_PARTNER = 'Partner';
    private static final String PROFILE_NAME_SALES = 'Sales';
    private static final String PROFILE_NAME_ENGINEER = 'Engineer';
    private static final String USER_TITLE_DIRECTOR = 'Director';
    private static final String USER_TITLE_VP = 'VP';
    private static final String USER_TITLE_TRAINING = 'Training';
    private static final String CASE_RT_FINANCE = 'COE Audit';
    private static final String GROUP_FINANCE_QUEUE = 'Finance Queue';

    public static String RC_BRAND_BT_BUSINESS {
        get {
            if(RC_BRAND_BT_BUSINESS == null) {
                RC_BRAND_BT_BUSINESS = !Test.isRunningTest() ? RcDealHealper.getBTBrand() : 'BT Business';
            }
            return RC_BRAND_BT_BUSINESS;
        }
        set;
    }

    private static Id USER_ID_CONNECTION_USER {
        get {
            if(USER_ID_CONNECTION_USER == null) {
                USER_ID_CONNECTION_USER = TelusIntegrationSettings__c.getOrgDefaults()?.Connection_User_Safe_Id__c;
            }
            return USER_ID_CONNECTION_USER;
        }
        set;
    }

    private static String RT_EMAIL_NOTIFICATION {
        get {
            if(RT_EMAIL_NOTIFICATION == null) {
                RT_EMAIL_NOTIFICATION = ExceptionAndNotificationHelper.getRcId('Email Notification');
            }
            return RT_EMAIL_NOTIFICATION;
        }
        set;
    }

    private static Set<Id> accountIds {
        get {
            if(accountIds == null) {
                accountIds = newAccountMap.keySet();
            }
            return accountIds;
        }
        set;
    }

    private static Map<Id, Contact> contactAccountMap {
        get {
            if(contactAccountMap == null) {
                contactAccountMap = ImplementationMethods.getContactAccountMap(newAccountMap);
            }
            return contactAccountMap;
        }
        set;
    }

    private static Map<String, Account> partnerAccountContactMap {
        get {
            if(partnerAccountContactMap == null) {
                partnerAccountContactMap = im.getPartnerAccountContactMap(newAccountMap.values());
            }
            return partnerAccountContactMap;
        }
        set;
    }

    private static Map<Id, Boolean> allowImplMap {
        get {
            if(allowImplMap == null) {
                allowImplMap = im.allImplementationMap(newAccountMap.values());
            }
            return allowImplMap;
        }
        set;
    }

    /*****************************************************************************
     * @Description - Method to update Account Active Date.                      *
     * @params Map<Id,Account> [trigger.new], Map<Id,Account> [trigger.oldMap]   *
     * @return void                                                              *
     *****************************************************************************/
    public static void updateAccountActiveDate() {
        try {
            Map<Id,List<Implementation__c>> implementations = getImplementations(accountIds);
            Map<Id, Account> accounts = getAccounts(accountIds);
            Map<Id, Contact> contacts = getContacts(accountIds);
            Map<Id, Account> accountMapForOfficeTrail = getAccountMapForOfficeTrail(accountIds);
            Map<Id, List<Contract>> contractMap = getContracts(accountIds);
            Map<Id, Lead> accountLeadMap = createAccountLeadMap(newAccountMap.keySet());

            // getting the updated lead object from the create lead method.
            accountLeadMap = im.createAccountLead(accountLeadMap, newAccountMap, contacts);

            List<Exception_And_Notification_History__c> exceptionNotifications = new List<Exception_And_Notification_History__c>();

            for (Account newAccount : newAccountMap.values()) {
                Account oldAccount = oldAccountMap.get(newAccount.Id);

                /* If activation date has been filled in for first time check for contracts and alert contract owner. */
                if (oldAccount.RC_Activation_Date__c == null
                    && oldAccount.RC_Activation_Date__c != newAccount.RC_Activation_Date__c
                    && SERVICE_NAME_RC_OFFICE.equalsIgnoreCase(newAccount.RC_Service_name__c)
                    && contractMap.containsKey(newAccount.Id)
                    && !contractMap.get(newAccount.Id).isEmpty()) {

                    exceptionNotifications.addAll(getEmails(contractMap.get(newAccount.Id)));
                }

                /***************** Create VAR Survey on Account Activation *******************/
                if (!newAccount.Is_Demo_Account__c
                    && RC_ATTR_CHANNEL_SALES_AGENT_RESELLERS.equalsIgnoreCase(newAccount.RC_Attribution_Channel__c)
                    && oldAccount.RC_Activation_Date__c == null && newAccount.RC_Activation_Date__c != null
                    && !accountMapForOfficeTrail.isEmpty()
                    && accountMapForOfficeTrail.get(newAccount.Id) != null
                    && (accountMapForOfficeTrail.get(newAccount.Id).Surveys__r == null
                        || accountMapForOfficeTrail.get(newAccount.Id).Surveys__r.isEmpty())
                    && String.isNotBlank(newAccount.Partner_ID__c)
                    && partnerAccountContactMap.get(newAccount.Partner_ID__c) != null
                    && partnerAccountContactMap.get(newAccount.Partner_ID__c).Contacts != null) {

                    List<Contact> partnerAccountContactList = partnerAccountContactMap.get(newAccount.Partner_ID__c).Contacts;
                    Survey__c survObj = im.createVARSurveyOnAccountActivation(newAccount, accountMapForOfficeTrail, partnerAccountContactList);
                    if (survObj != null) {
                        surveyListTOInsert.add(survObj);
                    }
                }
            }

            if (!exceptionNotifications.isEmpty()) {
                insert exceptionNotifications;
            }

            // Bypassing Account Trigger to avoid loop.
            TriggerHandler.BY_PASS_ACCOUNT_ON_UPDATE();
            TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT();

            if (!surveyListTOInsert.isEmpty() && !surveyListTOInsert.isEmpty()) {
                insert surveyListTOInsert;
            }
        } catch (Exception e) {
            PlatformLog.logException('Error AccountTriggerHelper.updateAccountActiveDate', e);
        }
    }

    /*****************************************************************************
     * @Description - Method to Create  Account for Partner.                     *
     * @params Map<Id,Account> [trigger.new]                                     *
     * @return void                                                              *
     *****************************************************************************/
    public static void partnerAccount() {
        Id partnerAccountRecordType = AccountHelper.RT_ID_PARTNER_ACCOUNT;

        try {
            for (Account newAccount : (List<Account>)Trigger.new) {
                if (ACCOUNT_TYPE_PARTNER.equalsIgnoreCase(newAccount.Type)
                    && String.isNotBlank(newAccount.Partner_ID__c)
                    && partnerAccountRecordType == newAccount.RecordTypeId) {

                    partnerAccMap.put(newAccount.Partner_ID__c, newAccount);
                    partnerAccountIdSet.add('%'+String.valueOf(newAccount.Id).substring(0,15)+'%');
                }
            }

            if (partnerAccMap.isEmpty() || partnerAccountIdSet.isEmpty()) {
                return;
            }

            for (Account partnerAccount : (List<Account>) new AccountSelector()
                                .selectPartnerAccountsByParentDetail(new List<Object>{ partnerAccountIdSet })
                                .executeQuery()) {
                if (!partnerAccMap.containsKey(partnerAccount.Partner_ID__c)) {
                    partnerAccMap.put(partnerAccount.Partner_ID__c, partnerAccount);
                }
            }

            List<Account> customerAccountsToUpdate = new List<Account>();
            for (Account customerAccount : (List<Account>) new AccountSelector()
                                            .selectCustomerAccountsByParentId(new List<Object>{ partnerAccMap.keySet() })
                                            .executeQuery()) {
                if (partnerAccMap.get(customerAccount.Partner_ID__c) != null
                    && customerAccount.Current_Owner__c != partnerAccMap.get(customerAccount.Partner_ID__c).Current_Owner__c
                    && customerAccount.Ultimate_Partner_ID__c != partnerAccMap.get(customerAccount.Partner_ID__c).Ultimate_Parent_Partner_ID__c) {

                    customerAccount.Ultimate_Partner_ID__c = partnerAccMap.get(customerAccount.Partner_ID__c).Ultimate_Parent_Partner_ID__c;
                    customerAccount.Ultimate_Partner_Name__c = partnerAccMap.get(customerAccount.Partner_ID__c).Ultimate_Parent_Account_Name__c;
                    customerAccountsToUpdate.add(customerAccount);
                }
            }

            if (!customerAccountsToUpdate.isEmpty()) {
                TriggerHandler.BY_PASS_ACCOUNT_ON_UPDATE();
                update customerAccountsToUpdate;
                TriggerHandler.RESET_VARIABLES();
            }
        } catch (Exception e) {
            PlatformLog.logException('Error AccountTriggerHelper.partnerAccount', e);
        }
    }

    public static void syncUltimateAccountIdToCustomerAccount () {
        Id partnerAccountRecordType  = AccountHelper.RT_ID_PARTNER_ACCOUNT;
        Id customerAccountRecordType = AccountHelper.RT_ID_CUSTOMER_ACCOUNT;

        List<Account> accountsToProcess = new List<Account>();
        Map<String, Account> partnerAccMap = new Map<String, Account>();
        Set<String> partnerIds = new Set<String>();

        for (Account currentAcc: (List<Account>) Trigger.new) {
            if (currentAcc.RecordTypeId == customerAccountRecordType) {
                if ((CoreObjectBase.isFieldChanged(currentAcc, Account.ParentId) || CoreObjectBase.isFieldChanged(currentAcc, Account.Partner_ID__c) || CoreObjectBase.isFieldChanged(currentAcc, Account.Current_Owner__c))
                    && currentAcc.ParentId != null && currentAcc.Partner_ID__c != null) {

                    accountsToProcess.add(currentAcc);
                    partnerIds.add(currentAcc.Partner_ID__c);
                }
            }
        }

        if (accountsToProcess.size() > 0) {
            for (Account partnerAccount : (List<Account>) new AccountSelector()
                                .selectPartnerAccountsByPartnerId(new List<Object>{ partnerIds })
                                .executeQuery()) {
                if (!partnerAccMap.containsKey(partnerAccount.Partner_ID__c)) {
                    partnerAccMap.put(partnerAccount.Partner_ID__c, partnerAccount);
                }
            }

            for (Account currentAccount: accountsToProcess) {
                if (partnerAccMap.get(currentAccount.Partner_ID__c) != null
                    && currentAccount.Current_Owner__c != partnerAccMap.get(currentAccount.Partner_ID__c).Current_Owner__c
                    && currentAccount.Ultimate_Partner_ID__c != partnerAccMap.get(currentAccount.Partner_ID__c).Ultimate_Parent_Partner_ID__c) {

                    currentAccount.Ultimate_Partner_ID__c = partnerAccMap.get(currentAccount.Partner_ID__c).Ultimate_Parent_Partner_ID__c;
                    currentAccount.Ultimate_Partner_Name__c = partnerAccMap.get(currentAccount.Partner_ID__c).Ultimate_Parent_Account_Name__c;
                }
            }
        }
    }

    /*****************************************************************************
     * @Description - Method to validate account list.                           *
     * @params                                                                   *
     * @return List<Account>                                                     *
     *****************************************************************************/
    public static List<Account> getAccountsToValidate() {
        List<Account> accounts = new List<Account>();
        try {
            for (Account acc : newAccountMap.values()) {
                if (acc.ParentId != null && acc.ParentId != oldAccountMap.get(acc.Id).ParentId) {
                    accounts.add(acc);
                }
            }
        } catch (Exception e) {
            PlatformLog.logException('Error AccountTriggerHelper.getAccountsToValidate', e);
        }
        return accounts;
    }

    /*****************************************************************************
     * @Description - Method to deinitalize maps, lists, sets.                   *
     * @params                                                                   *
     * @return void                                                              *
     *****************************************************************************/
    public static void deinitalize() {
        try {
            surveyListTOInsert.clear();
            leadList.clear();
            contractOwnerId.clear();
            partnerAccountIdSet.clear();
            partnerAccMap.clear();
        } catch (Exception e) {
            PlatformLog.logException('Error AccountTriggerHelper.deinitalize', e);
        }
    }

    /******************************************************************************
     * @Description - Method to create Finance Case                               *
     * @params Map<Id, Account> trigger.newMap, Map<Id, Account> trigger.oldMap   *
     * @return void                                                               *
     ******************************************************************************/
    public static void createFinanceCaseOnPaid(Map<Id, Account> oldAccounts, Map<Id, Account> newAccounts) {
        List<Case> caseToInsert = new List<Case>();
        if (newAccounts.isEmpty()) {
            return;
        }
        Id financeRecordTypeId = Case.SObjectType.getDescribe().getRecordTypeInfosByName().get(CASE_RT_FINANCE)?.getRecordTypeId();
        List<Group> financeGroup = (List<Group>) new GroupSelector()
                                    .selectQueueByName(GROUP_FINANCE_QUEUE)
                                    .executeQuery();
        if (financeRecordTypeId == null || financeGroup.isEmpty()) {
            return;
        }

        try {
            Map<Id, Integer> mapAccountToNumberOfCases = new Map<Id, Integer>();
            for (Account acc : (List<Account>) new AccountSelector()
                                .selectAccountsWithFinanceCases(new List<Object>{ newAccountMap.keySet() })
                                .executeQuery()) {
                Integer numberOfCases = acc.Cases != null ? acc.Cases.size() : 0;
                mapAccountToNumberOfCases.put(acc.Id, numberOfCases);
            }

            for (Account acc : newAccounts.values()) {
                if (acc.Active_Invoice_Approval__c != null
                    && mapAccountToNumberOfCases.get(acc.Id) == 0
                    && acc.RC_Account_Status__c == 'Paid'
                    && (oldAccounts == null
                        || oldAccounts.get(acc.Id).RC_Account_Status__c != acc.RC_Account_Status__c
                        || oldAccounts.get(acc.Id).Active_Invoice_Approval__c == null)
                ) {
                    Case caseObj = new Case();
                    caseObj.Status = 'New';
                    caseObj.Subject = 'New Customer Tracking for Finance';
                    caseObj.OwnerId = financeGroup.get(0).Id;
                    caseObj.AccountId = acc.Id;
                    caseObj.RecordTypeId  = financeRecordTypeId;
                    caseToInsert.add(caseObj);
                }
            }

            TriggerHandler.BY_PASS_CASE_ON_INSERT = true;
            TriggerHandler.BY_PASS_CASE_ON_UPDATE = true;

            if (!caseToInsert.isEmpty() && Case.SObjectType.getDescribe().isAccessible()) {
                insert caseToInsert;
            }

            TriggerHandler.BY_PASS_CASE_ON_INSERT = false;
            TriggerHandler.BY_PASS_CASE_ON_UPDATE = false;
        } catch (Exception e) {
            PlatformLog.logException('Error AccountTriggerHelper.createFinanceCaseOnPaid', e);
        }
    }

    public static void invalidateQuotes(Set<Id> accountIds, Set<Id> excludeOpportunityIds) {
        List<Quote> quotes = new List<Quote>();
        if (accountIds.isEmpty()) {
            return;
        }
        if (excludeOpportunityIds == null || excludeOpportunityIds.isEmpty()) {
            quotes = (List<Quote>) new QuoteSelector()
                        .selectQuotesWithOpportunityForAccount(accountIds)
                        .executeQuery();
        } else {
            quotes = (List<Quote>) new QuoteSelector()
                .selectQuotesWithOpportunityForAccountExcept(accountIds, excludeOpportunityIds)
                .executeQuery();
        }

        List<Quote> quotesToInvalidate = new List<Quote>();
        for (Quote q : quotes) {
            if (q.Opportunity.StageName != OpportunityHelper.STAGE_NAME_DOWNGRADED
                && !OpportunityHelper.STAGE_NAMES_CLOSED.contains(q.Opportunity.StageName)) {

                q.Quote_is_Invalid__c = true;
                quotesToInvalidate.add(q);
            }
        }

        if (quotesToInvalidate.isEmpty()) {
            return;
        }

        try {
            Triggers.switchOff();
            update quotesToInvalidate;
            Triggers.switchOn();
        } catch (Exception e) {
            Triggers.switchOn();
        }
    }

    public static void updateAccountMRRFieldsToZero(Account acc) {
        acc.No_of_InContact_Seats__c = 0;
    }

    public static Boolean isValidBillingState(String billingState, String billingCountry) {
        String billingCountryNormalized = String.isNotBlank(billingCountry) ? billingCountry.toLowerCase() : '';
        Boolean isStateRequired = COUNTRY_REQUIRE_STATE.contains(billingCountryNormalized);
        return !isStateRequired || String.isNotBlank(billingState);
    }

    // Utility methods

    /*****************************************************************************
    * @Description - Queries Implementation object and fetches relevant details. *
    * @params Set<Account> [trigger.new]                                         *
    * @return Map<Id,List<Implementation__c>                                     *
    *****************************************************************************/
    public static Map<Id, List<Implementation__c>> getImplementations(Set<Id> accountIds) {
        try {
            Boolean doSOQL = false;
            for (Id accId : accountIds) {
                if (!AccountTriggerHandler.implementationMapStatic.containsKey(accId) || AccountTriggerHandler.implementationMapStatic.get(accId).isEmpty()) {
                    doSOQL = true;
                    AccountTriggerHandler.implementationMapStatic.put(accId, new List<Implementation__c>());
                }
            }
            if (doSOQL) {
                for (Implementation__c imp : (List<Implementation__c>) new ImplementationSelector()
                                                .selectImplementationsWithStatusFields(new List<Object>{ accountIds })
                                                .executeQuery()) {
                    if (AccountTriggerHandler.implementationMapStatic.containsKey(imp.Account__c)) {
                        AccountTriggerHandler.implementationMapStatic.get(imp.Account__c).add(imp);
                    } else {
                        AccountTriggerHandler.implementationMapStatic.put(
                            imp.Account__c, new List<Implementation__c>{imp}
                        );
                    }
                }
            }
        } catch (Exception e) {
            PlatformLog.logException('Error AccountTriggerHelper.getImplementations', e);
        }
        return AccountTriggerHandler.implementationMapStatic;
    }

    /*****************************************************************************
     * @Description - Queries Account object and fetches relevant details.       *
     * @params Set<Id> [trigger.new] Id's                                        *
     * @return Map<Id, Account>                                                  *
     *****************************************************************************/
    public static Map<Id, Account> getAccounts(Set<Id> accountIds) {
        Map<Id, Account> accountMap = new Map<Id, Account>();
        Boolean doSOQL = false;

        try {
            for (Id accId : accountIds) {
                if (newAccountMap.containsKey(accId)) {
                    accountMap.put(accId, newAccountMap.get(accId));
                } else {
                    doSOQL = true;
                }
            }

            if (!doSOQL) {
                return accountMap;
            }

            List<Account> accounts = (List<Account>) new AccountSelector()
                                        .selectAccountsByIdNoFields(new List<Object>{ accountIds })
                                        .selectFields(new List<String>{
                                            'Id', 'RC_User_ID__c'
                                        })
                                        .executeQuery();
            if (!accounts.isEmpty()) {
                accountMap.putAll(accounts);
            }

        } catch (Exception e) {
            PlatformLog.logException('Error AccountTriggerHelper.getAccounts', e);
        }
        return accountMap;
    }

    /*****************************************************************************
     * @Description - Queries Contact object and fetches relevant details.       *
     * @params Set<Id> accountIds [trigger.newMap.keySet()]                      *
     * @return Map<Id, Contact>                                                  *
     *****************************************************************************/
    public static Map<Id, Contact> getContacts(Set<Id> accountIds) {
        Map<Id, Contact> contacts = new Map<Id, Contact>();
        if (accountIds.isEmpty()) {
            return contacts;
        }
        try {
            Boolean doSOQL = false;
            for (Id accId : accountIds) {
                if (!AccountTriggerHandler.contactMapStatic.containsKey(accId)) {
                    doSOQL = true;
                }
            }

            if (doSOQL) {
                for (Contact contact : (List<Contact>) new ContactSelector()
                                        .selectContactsByAccountId(new List<Object>{ accountIds, ContactHelper.INVALID_CONTACT_STATUSES })
                                        .withoutSelectorFieldsIncluded()
                                        .withoutSelectorOrderByIncluded()
                                        .selectFields(new List<String>{
                                            'Id', 'FirstName', 'LastName', 'NumberOfEmployees__c', 'AccountId',
                                            'Email', 'Phone', 'Account.No_of_Employees__c', 'Account.Name', 'isCustomer__c',
                                            'Contact_Status__c', 'People_Segment__c', 'RCService_ContactStatus__c'
                                        })
                                        .setCondition('AccountId IN :bind0 AND Contact_Status__c NOT IN :bind1')
                                        .executeQuery()) {
                    if (AccountTriggerHandler.contactMapStatic.containsKey(contact.AccountId)) {
                        AccountTriggerHandler.contactMapStatic.get(contact.AccountId).add(contact);
                    } else {
                        AccountTriggerHandler.contactMapStatic.put(
                            contact.AccountId, new List<Contact>{ contact }
                        );
                    }
                    contacts.put(contact.AccountId, contact);
                }
            }
        } catch (Exception e) {
            PlatformLog.logException('Error AccountTriggerHelper.getContacts', e);
        }
        return contacts;
    }

    /*****************************************************************************
     * @Description - accountMapForOfficeTrail.                                  *
     * @params Set<Id> accountIds [trigger.newMap.keySet()]                      *
     * @return Map<Id, Account>                                                  *
     ****************************************************************************/
    public static Map<Id, Account> getAccountMapForOfficeTrail(Set<Id> accountIds) {
        Map<Id, Account> accountMap = new Map<Id, Account>();
        if (accountIds.isEmpty()) {
            return accountMap;
        }
        try {
            for (Account acc : (List<Account>) new AccountSelector()
                                    .selectAccountsForOfficeTrail(new List<Object>{ accountIds })
                                    .executeQuery()) {
                AccountTriggerHandler.contactMapStatic.put(acc.Id, acc.Contacts);
                accountMap.put(acc.Id, acc);
            }
        } catch (Exception e) {
            PlatformLog.logException('Error AccountTriggerHelper.getAccountMapForOfficeTrail', e);
        }
        return accountMap;
    }

    /*****************************************************************************
     * @Description - Queries Contract object and fetches relevant details.      *
     * @params Set<Account> [trigger.new]                                        *
     * @return Map<Id,List<Contract>                                             *
     *****************************************************************************/
    public static Map<Id, List<Contract>> getContracts(Set<Id> accountIds) {
        Map<Id, List<Contract>> contracts = new Map<Id, List<Contract>>();
        if (accountIds.isEmpty()) {
            return contracts;
        }
        try {
            for (Contract contract : (List<Contract>) new ContractSelector()
                                        .selectContractsByAccountId(new List<Object>{ accountIds })
                                        .selectFields(new List<String>{
                                            'Id', 'OwnerId', 'Owner.Email', 'AccountId'
                                        })
                                        .executeQuery()) {
                if (contracts.containsKey(contract.AccountId)) {
                    contracts.get(contract.AccountId).add(contract);
                } else {
                    contracts.put(contract.AccountId, new List<Contract>{contract});
                }
                contractOwnerId.add(contract.OwnerId);
            }
        } catch (Exception e) {
            PlatformLog.logException('Error AccountTriggerHelper.getContracts', e);
        }
        return contracts;
    }

    /*****************************************************************************
     * @Description - Queries Account object and fetches relevant details.       *
     * @params Set<Id> [trigger.new] Id's                                        *
     * @return Map<Id, Account>                                                  *
     *****************************************************************************/
    public static Map<Id, User> getUserDetails(Set<Id> userIds) {
        Map<Id, User> userDetails = new Map<Id, User>();

        try {
            populateUsersStatic(userIds);
            for (Id userId : userIds) {
                if (userMap.containsKey(userId)) {
                    userDetails.put(userId, userMap.get(userId));
                }
            }
        } catch (Exception e) {
            PlatformLog.logException('Error AccountTriggerHelper.getUserDetails', e);
        }

        return userDetails;
    }

    public static void populateUsersStatic(Set<Id> userIds) {
        Set<Id> userIdsForQuery = new Set<Id>();
        for (Id userId : userIds) {
            if (!userMap.containsKey(userId)) {
                userIdsForQuery.add(userId);
            }
        }

        if (!userIdsForQuery.isEmpty()) {
            List<User> users = new List<User>();
            if(ConvertLead.IS_LEAD_CONVERT_PROCESSING && SettingsHelper.FEATURE_TOGGLE.EnableLeadConversionUsingCache__c){
                users = UserHelper.retrieveUsersWithCache(userIdsForQuery);
            }
            else {
                users = (List<User>) new UserSelector()
                .selectUsersByIds(userIdsForQuery)
                .selectFields(new List<String>{
                    'Id', 'FirstName', 'LastName', 'Email',
                    'Name', 'UserRole.Name', 'Phone', 'Profile.Name',
                    'Title', 'Hold_Out_List__c',
                    'Profile.Id', 'Profile.Name'
                })
                .executeQuery();
            }
            if (!users.isEmpty()) {
                userMap.putAll(users);
            }
        }
    }

    /*****************************************************************************
     * @Description - Create Account Lead Map.                                   *
     * @params Set<Id> [trigger.new] Id's                                        *
     * @return Map<Id, Account>                                                  *
     *****************************************************************************/
    public static Map<Id, Lead> createAccountLeadMap(Set<Id> accountIdList) {
        Map<Id, Lead> accountLeadMap = new Map<Id, Lead>();
        for (Id thisAccountId : accountIdList) {
            accountLeadMap.put(thisAccountId, new Lead());
        }
        return accountLeadMap;
    }

    /*****************************************************************************
     * @Description - Method to get emails.                                      *
     * @params List<Contract> [trigger.new]                                      *
     * @return List<Exception_And_Notification_History__c>                       *
     *****************************************************************************/
    public static List<Exception_And_Notification_History__c> getEmails(List<Contract> contracts) {
        List<Exception_And_Notification_History__c> exceptionNotifications = new List<Exception_And_Notification_History__c>();
        for (Contract contract : contracts) {
            Exception_And_Notification_History__c exceptionNotification = new Exception_And_Notification_History__c();
            exceptionNotification.Sender_Display_Name__c = 'SFDC Account Alert';
            exceptionNotification.Email_Subject__c = 'Please review this Account Contract';
            exceptionNotification.To_Address_1__c = contract.Owner.Email;
            exceptionNotification.Reply_To__c = UserRC.rcsfSyncUserObj.Email__c;
            exceptionNotification.Object_Type__c = 'Account';
            exceptionNotification.content_label_01__c = 'SFDC_ACCOUNT_CONTRACT_NOTIFICATION';
            exceptionNotification.content_var_01__c = contract.Id;
            exceptionNotification.RecordTypeId = RT_EMAIL_NOTIFICATION;
            exceptionNotifications.add(exceptionNotification);
        }
        return exceptionNotifications;
    }

    public static void SendAccountDetailsforClayEnrichment(List<Account> acctsToBeChecked) {
        List<Account> acctsToBeSent = new List<Account>();
        for (Account acc : acctsToBeChecked) {
            if (
                (String.isBlank(acc.zi_id__c)) &&
                ((acc.Systems_process_stage__c != NULL && acc.Systems_process_stage__c.equalsIgnoreCase('SFDC Created')) &&   
                acc.SFDC_Enriched_Date_time__c == NULL && 
                acc.RecordTypeId != AccountHelper.RT_ID_ZI_ACCOUNT &&    
                String.isBlank(acc.Systems_process_enrichment_bypass__c) &&  
                !acc.descartesdps__HasBeenFlaggedByDPS__c)
            ) {
                    acctsToBeSent.add(acc);
            }
        }
        if (!acctsToBeSent.isEmpty()) {
            System.enqueueJob(new ClayAccountWebHookHandler(acctsToBeSent));
        }
    }
}