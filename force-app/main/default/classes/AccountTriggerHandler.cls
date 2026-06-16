public with sharing class AccountTriggerHandler {
    public static Map<Id, User> userMapStatic = new Map<Id, User>();
    public static List<Account> serviceInfoAccountListStatic = new List<Account>();
    public static Map<Id, List<Contact>> contactMapStatic = new Map<Id, List<Contact>>();
    public static Map<Id, List<Implementation__c>> implementationMapStatic = new Map<Id, List<Implementation__c>>();
    public static Set<Id> accountIds = new Set<Id>();
    public static Boolean isImplementationUpdated = false;
    public static Boolean isPartnerLeadConversion = false;
    public static Boolean isSalesLeadConversion = false;

    public class ManageAccountMapStatic extends Triggers.TriggerHandlerBase {
        override public void handle() {
            if (Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)) {
                this.handleBeforeUpsert();
            }
            if (Trigger.isAfter && Trigger.isDelete) {
                this.handleAfterDelete();
            }
        }

        private void handleBeforeUpsert() {
            Set<Id> accountIdsToLoad = new Set<Id>();
            for (Account acc : (List<Account>) Trigger.new) {
                if (!OpportunityTriggerHelperRefactored.accountMapStatic.containsKey(acc.Id)) {
                    accountIdsToLoad.add(acc.Id);
                }
            }

            if (!accountIdsToLoad.isEmpty()) {
                List<Account> accountsLoaded = new AccountSelector()
                    .selectAccountsForOpportunityTrigger(accountIdsToLoad)
                    .executeQuery();

                OpportunityTriggerHelperRefactored.accountMapStatic.putAll(accountsLoaded);
            }
        }

        private void handleAfterDelete() {
            for (Account acc : (List<Account>) Trigger.old) {
                OpportunityTriggerHelperRefactored.accountMapStatic.remove(acc.Id);
            }
        }
    }

    public class UpdateBrandPartnerOnRelatedRecords extends Triggers.TriggerHandlerBase {
        private final List<SObjectType> relatedSoTypes = BrandPartnerFieldPopulationHandler.relatedSoTypes;
        override public void handle() {
            // related records update is toggled, cause of potential issues with platform limits.
            if (Feature_Toggle__c.getInstance().SkipBrandPartnerSyncFromAccount__c) {
                return;
            }

            List<Id> accIdsWithChangedBrand = new List<Id>();
            for (Account acc : (List<Account>) this.triggerRecords) {
                if (BrandPartnerFieldPopulationHandler.getBrandPartnerValue(acc)!=
                    BrandPartnerFieldPopulationHandler.getBrandPartnerValue((Account) oldRecord(acc))
                ) {
                    accIdsWithChangedBrand.add(acc.Id);
                }
            }

            if (!accIdsWithChangedBrand.isEmpty()) {
                updateBrandPartner(accIdsWithChangedBrand);
            }
        }

        public void updateBrandPartner(List<Id> accIds) {
            // build query to select Accounts and related records
            QueryFactory qFactory = new AccountSelector()
                                    .selectAccountsByIds(new List<Object>{ accIds })
                                    .selectField(Account.RC_Brand__c);
            for (SObjectType soType : relatedSoTypes) {
                qFactory.subselect(BrandPartnerFieldPopulationHandler.getRelatedRecordsQuery(soType));
            }
            List<Account> accountsWithRelatedRecords = (List<Account>) qFactory.executeQuery();

            // collect all related records and update Brand_Partner__c field
            List<SObject> recordsToUpdate = new List<SObject>();
            for (SObjectType soType : relatedSoTypes) {
                String relationshipName = getChildRelationship(Account.SObjectType, soType).getRelationshipName();
                for (Account acc : accountsWithRelatedRecords) {
                    String newBrandPartnerValue = BrandPartnerFieldPopulationHandler.getBrandPartnerValue(acc);
                    for (SObject relatedRecord : acc.getSObjects(relationshipName)) {
                        if ((String) (relatedRecord.get('Brand_Partner__c')) != newBrandPartnerValue) {
                            relatedRecord.put('Brand_Partner__c', newBrandPartnerValue);
                            recordsToUpdate.add(relatedRecord);
                        }
                    }
                }
            }

            if (!recordsToUpdate.isEmpty()) {
                update recordsToUpdate;
            }
        }

        public Schema.ChildRelationship getChildRelationship(SObjectType parentObjType, SObjectType childObjType) {
            for (Schema.ChildRelationship childRow : parentObjType.getDescribe().getChildRelationships()) {
                /* Occasionally on some standard objects (Like Contact child of Contact) do not have a relationship name.
                if there is no relationship name, we cannot query on it, so throw an exception. */
                if (childRow.getChildSObject() == childObjType && childRow.getRelationshipName() != null) {
                    return childRow;
                }
            }
            return null;
        }
    }

    /*************************************************
    Trigger on Account object
    Before Update: Update Current Owner Name and Email fields as needed.
    Before Insert & Update: Format RC Account Number by removing the the 1 from the front of US numbers.

    * UPDATE:
     * By:        eugenebasianomutya
     * Date:      5/21/2015
     * Details:   Case: Case 03562230: Target Accounts in SFDC
     * Updates:
                  Create number field "Target Accounts Owned" in User object
                  Create checkbox field "Target Account" in Account object
                  Create validation rules to require Current Owner if Target Account is true

                  If field changes to True, check if CurrentOwner's Target Accounts Owned has < 20
                  If YES, increment Target Accounts Owned, ELSE, show error that CurrentOwner already
                    has 20 Target Accounts


       Case: 03775648 - Hortonworks
       Case Desc:  I need to figure out what sync or automation is changing Current Owners on the accounts that Sales Ops moduled to the Signature Team
       Update by: eugenebasianomutya
       Update date: 07312015
       Update made: Comment out code that change Account's Current Owner

    * UPDATE
    *
    * @Case...................:  04065723
    * @Discription............:  Request to have Channel Mananger Email value on Account
    * @Param..................:  Account
    * @Return.................:  NA
    * @Last Modified by.......:  eugenebasianomutya
    * @Last Modified Date.....:  12/16/2015

    * UPDATE
    *
    * @Case...................:  04343815
    * @Discription............:  (QW) New Implementation Fields for Reporting
    * @Param..................:  Account
    * @Return.................:  NA
    * @Last Modified by.......:  eugenebasianomutya
    * @Last Modified Date.....:  2/26/2015

    /************************************************/
    public class AccountBefore extends Triggers.TriggerHandlerBase {

        override public void handle() {

            //To by pass trigger when converting lead from Relayware
            if (UserInfo.getName() == UserHelper.API_USER_NAME) {
                return;
            }

            Map<Id, Package__c> accountToPackagesMap = new Map<Id, Package__c>();

            if (Trigger.isInsert) {
                for (Account acc : (List<Account>) Trigger.new) {
                    acc.AHSearchCriteriaFieldsHaveBeenModified__c = true;
                    if (acc.CSM__c != null) {
                        acc.Date_CSM_Added__c = Date.today();
                    }
                }
            }

            //B-5816
            if (Trigger.isUpdate) {
                Set<Id> accountIds = Trigger.newMap.keySet();
                List<Package__c> packages = new PackageSelector()
                    .selectPackagesForNewReferences(new List<Object> {accountIds})
                    .setQueryCaching(true)
                    .executeQuery();

                for (Package__c pkg : packages) {
                    accountToPackagesMap.put(pkg.Enterprise_Account_ID__c, pkg);
                }
                AccountTriggerHelper.syncUltimateAccountIdToCustomerAccount();

                Leadspace_field_bypass__c LSField = Leadspace_field_bypass__c.getInstance();

                for (Account acc : (List<Account>) Trigger.new) {
                    Account oldAccount = (Account) Trigger.oldMap.get(acc.Id);

                    if (isChangedFieldFrom(acc, Account.CSM__c, null)) {
                        acc.Date_CSM_Added__c = Date.today();
                    }

                    // B- 6291
                    if (isChangedField(acc, Account.CcPaymentType__c)) {
                        if (isChangedFieldTo(acc, Account.CcPaymentType__c, AccountTriggerHelper.CC_PAYMENT_TYPE_MONTH_TO_MONTH)
                            && (isChangedFieldFrom(acc, Account.CcPaymentType__c, AccountTriggerHelper.CC_PAYMENT_TYPE_ANNUAL)
                                || isChangedFieldFrom(acc, Account.CcPaymentType__c, AccountTriggerHelper.CC_PAYMENT_TYPE_ANNUAL_PRE_PAY))
                        ) {
                            acc.CcConverted__c = true;
                        } else {
                            acc.CcConverted__c = false;
                        }
                    }

                    if ((!isChangedField(acc, Account.AH_Name__c) && isChangedField(acc, Account.Company_DUNS__c))
                        || isChangedField(acc, Account.SiteDunsNumber__c)
                        || isChangedField(acc, Account.BillingCountry)
                        || (isChangedField(acc, Account.LS_Country__c) && LSField != null && LSField.Bypass_Account_fields__c == false)
                        || (isChangedField(acc, Account.ZI_Company_Country__c) && LSField != null && LSField.Bypass_Account_fields__c == true)
                        || (isChangedField(acc, Account.ZI_Website__c) && LSField != null && LSField.Bypass_Account_fields__c == true)
                        || isChangedField(acc, Account.Website)
                        || isChangedField(acc, Account.ContactMostFrequentEmail__c)
                    ) {
                        acc.AHSearchCriteriaFieldsHaveBeenModified__c = true;
                    }

                    String changes = acc.Changes__c == null ? '' : acc.Changes__c;
                    if (isChangedField(acc, Account.RC_Account_Status__c)
                        && acc.RC_Account_Status__c != null
                        && (acc.RC_Account_Status__c.equalsIgnoreCase('Paid')
                            || acc.RC_Account_Status__c.equalsIgnoreCase('Cancelled')
                            && !changes.contains('ContactStatusNeedsToUpdate'))
                    ) {
                        changes += ';ContactStatusNeedsToUpdate';
                    }

                    if (isChangedField(acc, Account.Current_Owner__c)
                        && String.isNotBlank(acc.Type)
                        && acc.Type.equalsIgnoreCase('Customer')
                        && !changes.contains('Current_Owner__c')
                    ) {
                        changes += ';Current_Owner__c';
                    }

                    if (isChangedField(acc, Account.AH_Name__c)
                        || isChangedField(acc, Account.Number_of_DL_s__c)
                    ) {
                        changes = changes.contains('AH_Name__c')
                                    ? replaceValue(changes, 'AH_Name__c', (String) oldAccount.AH_Name__c)
                                    : changes + ';AH_Name__c:' + oldAccount.AH_Name__c;
                    }

                    if (isChangedField(acc, Account.RC_Upgrade_Date__c) && !changes.contains('RC_Upgrade_Date__c')) {
                        changes += ';RC_Upgrade_Date__c';
                    }

                    if (isChangedField(acc, Account.RC_Account_Status__c) && !changes.contains('RC_Account_Status__c')) {
                        changes = changes.contains('RC_Account_Status__c') ?
                            replaceValue(changes, 'RC_Account_Status__c', (String) oldAccount.RC_Account_Status__c) :
                            changes + ';RC_Account_Status__c:' + oldAccount.RC_Account_Status__c;
                    }

                    if (String.isBlank((String) oldAccount.RC_User_ID__c)
                        && String.isNotBlank((String) acc.RC_User_ID__c)
                        && acc.Funnel_not_supported__c != null
                        && !changes.contains('RC_User_ID__c')
                    ) {
                        changes += ';RC_User_ID__c';
                    }
                    acc.Changes__c = changes;
                }
            }
            //B-4695 Sergienko 5/7/2018
            //Company object decomissioning starts
            ByPassTrigger__c byPassTrigger = ByPassTrigger__c.getInstance();
            if (byPassTrigger != null && !byPassTrigger.Bypass_Company_Process_Logic__c) {
                if (!Trigger.isDelete) {
                    Set<Id> companyIds = new Set<Id>();
                    for (Account acc : (List<Account>) Trigger.new) {
                        if ((Trigger.isInsert || (Trigger.isUpdate && isChangedField(acc, Account.AH_Name__c))) && acc.AH_Name__c != null) {
                            companyIds.add(acc.AH_Name__c);
                        }
                    }
                    Map<Id, Account_Hierarchy__c> companyMap = new Map<Id, Account_Hierarchy__c>();
                    if (!companyIds.isEmpty()) {
                        companyMap = new Map<Id, Account_Hierarchy__c>((List<Account_Hierarchy__c>) new AccountHierarchySelector()
                                    .selectCompanyStatusByIds(new List<Object>{companyIds})
                                    .executeQuery());
                    }
                    for (Account acc : (List<Account>) Trigger.new) {
                        if (companyMap.containsKey(acc.AH_Name__c)) {
                            acc.Target_Account__c = AccountHierarchyHelper.TARGET_COMPANY_STATUSES.contains(companyMap.get(acc.AH_Name__c).Company_Status__c);
                        } else if (acc.AH_Name__c == null && acc.Target_Account__c) {
                            acc.Target_Account__c = false;
                        }
                    }
                }
            }
            //company object decomissioning ends

            // Flag to check if trigger is to be executed or not.
            if (TriggerHandler.BY_PASS_ACCOUNT_ON_BEFORE) {
                return;
            } else {
                TriggerHandler.BY_PASS_ACCOUNT_ON_BEFORE = true;
            }
            //---------------------------As/Simplion/9/24/2014----------------------------------------
            //---------------------------map to maintain serviceName and serviceType Mappings---------
            Map<String, String> serviceAndTypeMap = new Map<String, String>{
                'FAX' => 'Fax',
                'PROFESSIONAL' => 'Professional',
                'OFFICE' => 'Office'
            };
            //---------------------------------As/Simplion/10/16/2014 ends--------------------------------------------------------------------------
            if (!Trigger.isDelete) {
                for (Account accObj : (List<Account>) Trigger.new) {
                    if (accObj.Ultimate_Parent_Account_ID__c != null) {
                        accObj.Ultimate_Parent_Snapshot__c = String.valueOf(accObj.Ultimate_Parent_Account_ID__c).substring(0, 15);
                    }
                }
            }

            if (TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT || TriggerHandler.BY_PASS_ACCOUNT_ON_UPDATE) {
                return;
            }

            Map<Id, User> userMap = new Map<Id, User>();
            if (!Trigger.isDelete) {
                Set<Id> userIds = AccountTriggerHelperExt.prepareUserIdSet((List<Account>) Trigger.new);
                userMap = AccountTriggerHelperExt.getUsers(userIds);
            }

            if (Trigger.isInsert) {
                AccountTriggerHelperExt.accountRecordTypeInformation((List<Account>) Trigger.new);
                AccountTriggerHelperExt.accountSharingOnInsert((List<Account>) Trigger.new);
                /*-----For Update  of customer count on Partner Account ------------*/
                AccountTriggerHelperExt.updateCreditCounter((List<Account>) Trigger.new, null);

            }

            if (Trigger.isUpdate) {
                AccountTriggerHelperExt.oldAccountMap = (Map<Id, Account>) Trigger.oldMap;
                AccountTriggerHelperExt.accountSharingOnUpdate0((List<Account>) Trigger.new, userMap, accountToPackagesMap);
                AccountTriggerHelperExt.accountSharingOnUpdate2((List<Account>) Trigger.new);
                /*-----For Update  of customer count on Partner Account ------------*/
                AccountTriggerHelperExt.updateCreditCounter((List<Account>) Trigger.new, (Map<Id, Account>) Trigger.oldMap);

            }

            if (Trigger.isInsert || Trigger.isUpdate) {
                // B-9392 (Populate Churn Date on Partner Accounts when PartnerStatus__c field changes)
                for (Account acc : (List<Account>) Trigger.new) {
                    Boolean isChangedToActive = isChangedFieldTo(acc, Account.PartnerStatus__c, AccountHelper.ACTIVE_STATUS);
                    Boolean isChangedToMigrated = isChangedFieldTo(acc, Account.PartnerStatus__c, AccountHelper.MIGRATED_STATUS);
                    Boolean isChangedPartnerStatus = isChangedField(acc, Account.PartnerStatus__c);
                    Boolean isPartnerAccount = acc.RecordTypeId == AccountHelper.RT_ID_PARTNER_ACCOUNT;
                    Boolean isChangedParentId = isChangedField(acc, Account.ParentId);
                    Boolean isChangedPartnerAcc = isChangedField(acc, Account.Partner_Account__c);

                    if (isPartnerAccount && isChangedPartnerStatus) {
                        if (!isChangedToActive && !isChangedToMigrated) {
                            acc.RC_Churn_Date__c = System.today();
                        } else if (isChangedToActive || isChangedToMigrated) {
                            acc.RC_Churn_Date__c = null;
                        }
                        if (isChangedToActive) {
                            acc.Avaya_Partnership_Account__c = true; //PBC-10146
                        }
                    }
                    if (isPartnerAccount) {
                        //PBC-10146
                        if (acc.RC_Brand__c == OpportunityHelper.BRAND_RINGCENTRAL) {
                            if (isChangedParentId) {
                                acc.Partner_Account__c = acc.ParentId;
                            }
                            if (isChangedPartnerAcc) {
                                acc.ParentId = acc.Partner_Account__c;
                            }
                        }
                    }
                }

                // Case 03775648 - Remove this code
                // AccountTriggerHelperExt.updatePartnerCodeOnInsertAndUpdate(trigger.new);
                // Case 03775648 - Remove this code
                //---------------------------------As/Simplion/10/16/2014 start--------------------------------------------------------------------------
                //--------------------------------Service Type mapping as per service Name for account with Account status = 'test'---------------
                String serviceName = '';
                for (Account currentAccount : (List<Account>) Trigger.new) {
                    if (String.isNotBlank(currentAccount.RC_Service_name__c) && String.isNotBlank(currentAccount.RC_Account_Status__c)) {
                        serviceName = currentAccount.RC_Service_name__c.toUpperCase();
                        if (currentAccount.RC_Account_Status__c.toUpperCase().equals('TEST')) {
                            currentAccount.Service_Type__c = serviceName.contains('OFFICE') ? serviceAndTypeMap.get('OFFICE')
                                : (serviceName.contains('PROFESSIONAL') || serviceName.startsWith('PRO')) ? serviceAndTypeMap.get('PROFESSIONAL')
                                    : serviceName.contains('FAX') ? serviceAndTypeMap.get('FAX')
                                        : currentAccount.Service_Type__c;
                        }
                    }
                }
                //---------------------------------As/Simplion/10/16/2014 ends--------------------------------------------------------------------------
                /**Start calculation of Completion Rate and Completion Date of Graduation Phase of Graduation Score Card */
            }

            /********** For Account Hierarchy Total DLS Field updation *********
            * @Description : updating the Account's Hierarchy with total num- *
            *              : -ber of DLs.                     *
            * @updatedBy   : India team                                       *
            * @updateDate  : 23/07/2014                                       *
            *******************************************************************/
            if (Trigger.isDelete) {
                Set<String> ultimateParentIdSet = new Set<String>();
                for (Account accObj : (List<Account>) Trigger.old) {
                    // Only re-evaluate the hierarchy if either Ultimate Parent is being deleted or any 'PaId' Account is deleted.
                    if (accObj.RC_Account_Status__c == 'Paid' || String.valueOf(accObj.Ultimate_Parent_Account_ID__c).substring(0, 15) == String.valueOf(accObj.Id).substring(0, 15)) {
                        if (String.valueOf(accObj.Id).substring(0, 15) != String.valueOf(accObj.Ultimate_Parent_Account_ID__c).substring(0, 15)) {
                            ultimateParentIdSet.add(String.valueOf(accObj.Ultimate_Parent_Account_ID__c).substring(0, 15));
                            ultimateParentIdSet.add(String.valueOf(accObj.Id).substring(0, 15));
                        } else if (String.valueOf(accObj.Id).substring(0, 15) == String.valueOf(accObj.Ultimate_Parent_Account_ID__c).substring(0, 15)) {
                            ultimateParentIdSet.add(String.valueOf(accObj.Id).substring(0, 15));
                        }
                    }
                }
                if (ultimateParentIdSet != null && !ultimateParentIdSet.isEmpty()) {
                    List<Account> accounts = (List<Account>) new AccountSelector()
                                            .selectCustomerAccountsByParentSnapshot(new List<Object>{ultimateParentIdSet})
                                            .executeQuery();

                    if (accounts != null && !accounts.isEmpty()) {
                        for (Account acc : accounts) {
                            ultimateParentIdSet.add(String.valueOf(acc.Id).substring(0, 15));
                            ultimateParentIdSet.add(String.valueOf(acc.Ultimate_Parent_Account_ID__c).substring(0, 15));
                        }
                    }
                }
                TriggerHandler.RELATED_ACCOUNT_ID_SET.addAll(ultimateParentIdSet) ;
            }
            /************End of For Account Hierarchy Total DLS Field updation**************************************/

            try {
                // Case #04065723 - START
                if (!userMap.isEmpty()) {
                    AccountTriggerHelperExt.populateChannelManagerEmail(Trigger.new, userMap);
                }
                // Case #04065723 - END
            } catch (Exception e) {
                PlatformLog.logException('Error account trigger populateChannelManagerEmail', e);
            }

            /*******************************************************************
            * @Description.: Target Accounts in SFDC                          *
            * @updatedBy...: eugenebasianomutya                               *
            * @updateDate..: 5/21/2015                                      *
            * @Case Number.: 03562230                                         *
            *******************************************************************/
            // NOTE: We can move this to AccountTriggerHelper class
            if (Trigger.isInsert || Trigger.isUpdate) {
                Map<Id, Id> mUserAcc = new Map<Id, Id>();
                Set<Id> sUserIdToCheck = new Set<Id>();
                Set<Id> sUserTargetAdd = new Set<Id>();
                Set<Id> sUserTargetReduce = new Set<Id>();
                Set<Id> sAccountError = new Set<Id>();
                Account oldAcc;

                for (Account acc : (List<Account>) Trigger.new) {
                    if (Trigger.isUpdate) {
                        oldAcc = (Account) Trigger.oldMap.get(acc.Id);

                        // TA - 0>1, CO - 0>1; TA - 0>1, CO - 1>1;
                        if (!oldAcc.Target_Account__c && acc.Target_Account__c &&
                            acc.Current_Owner__c != null) {
                            sUserTargetAdd.add(acc.Current_Owner__c);
                            sUserIdToCheck.add(acc.Current_Owner__c);
                        }

                        // TA - 1>1, CO - 0>1
                        if (oldAcc.Target_Account__c && acc.Target_Account__c &&
                            oldAcc.Current_Owner__c == null && acc.Current_Owner__c != null) {
                            sUserTargetAdd.add(acc.Current_Owner__c);
                            sUserIdToCheck.add(acc.Current_Owner__c);
                        }

                        // TA - 1>0, CO - 1>0
                        if (oldAcc.Target_Account__c && !acc.Target_Account__c &&
                            oldAcc.Current_Owner__c != null && acc.Current_Owner__c == null) {
                            sUserTargetReduce.add(oldAcc.Current_Owner__c);
                            sUserIdToCheck.add(oldAcc.Current_Owner__c);
                        }

                        // TA - 1>0, CO - 1>1
                        if (oldAcc.Target_Account__c && !acc.Target_Account__c &&
                            oldAcc.Current_Owner__c != null && acc.Current_Owner__c != null) {
                            if (oldAcc.Current_Owner__c != acc.Current_Owner__c) {
                                sUserTargetReduce.add(oldAcc.Current_Owner__c);
                                sUserIdToCheck.add(oldAcc.Current_Owner__c);
                            } else {
                                sUserTargetReduce.add(acc.Current_Owner__c);
                                sUserIdToCheck.add(acc.Current_Owner__c);
                            }
                        }

                        // TA - 1>1, CO 1>0
                        if (oldAcc.Target_Account__c && acc.Target_Account__c &&
                            oldAcc.Current_Owner__c != null && acc.Current_Owner__c == null) {
                            sUserTargetReduce.add(oldAcc.Current_Owner__c);
                            sUserIdToCheck.add(oldAcc.Current_Owner__c);
                            // Now set the checkbox to false
                            acc.Target_Account__c = false;
                        }

                        // TA - 1>1, CO 1>1
                        if (oldAcc.Target_Account__c && acc.Target_Account__c &&
                            oldAcc.Current_Owner__c != null && acc.Current_Owner__c != null) {

                            if (oldAcc.Current_Owner__c != acc.Current_Owner__c) {
                                sUserTargetAdd.add(acc.Current_Owner__c);
                                sUserIdToCheck.add(acc.Current_Owner__c);
                                sUserTargetReduce.add(oldAcc.Current_Owner__c);
                                sUserIdToCheck.add(oldAcc.Current_Owner__c);
                            }
                        }

                        mUserAcc.put(acc.Current_Owner__c, acc.Id);
                        mUserAcc.put(oldAcc.Current_Owner__c, acc.Id);

                    } else {
                        // TA - 0>1, CO - 0>1; TA - 0>1, CO - 1>1;
                        if (acc.Target_Account__c && acc.Current_Owner__c != null) {
                            sUserTargetAdd.add(acc.Current_Owner__c);
                            sUserIdToCheck.add(acc.Current_Owner__c);
                        }

                        mUserAcc.put(acc.Current_Owner__c, acc.Id);
                    }

                }

                if (sUserIdToCheck != null && !sUserIdToCheck.isEmpty()) {
                    List<User> userToUpdate = new List<User>();

                    for (User usr : (List<User>) new UserSelector()
                                    .selectUsersByIds(sUserIdToCheck)
                                    .selectFields(new List<String>{
                                        'Id', 'Target_Accounts_Owned__c'
                                    })
                                    .executeQuery()) {
                        if (sUserTargetAdd.contains(usr.Id)) {
                            if (usr.Target_Accounts_Owned__c == null) {
                                usr.Target_Accounts_Owned__c = 1;
                                userToUpdate.add(usr);
                            } else {
                                if (usr.Target_Accounts_Owned__c >= 20) {
                                    sAccountError.add(mUserAcc.get(usr.Id));
                                } else {
                                    usr.Target_Accounts_Owned__c = usr.Target_Accounts_Owned__c + 1;
                                    userToUpdate.add(usr);
                                }
                            }
                        }

                        if (sUserTargetReduce.contains(usr.Id)) {
                            if (usr.Target_Accounts_Owned__c == null || usr.Target_Accounts_Owned__c == 0) {
                                usr.Target_Accounts_Owned__c = null;
                                userToUpdate.add(usr);
                            } else {
                                usr.Target_Accounts_Owned__c = usr.Target_Accounts_Owned__c - 1;
                                userToUpdate.add(usr);
                            }
                        }
                    }

                    if (!userToUpdate.isEmpty()
                        && User.SObjectType.getDescribe().isAccessible()
                        && Schema.SObjectType.User.fields.Target_Accounts_Owned__c.isAccessible()
                    ) {
                        update userToUpdate;
                    }
                }

                // Check if needed to prompt user if Current Owner already has 20 Target Accounts
                if (sAccountError != null && !sAccountError.isEmpty()) {
                    for (Id accountError : sAccountError) {
                        Trigger.newMap.get(accountError)?.addError(Label.Account_Error_Current_Owner_Target_Accounts_Limit);
                    }
                }
            }
            /******************************************Case:03562230 End's here*************************************************/

            /*******************************************************************
            * @Description.: Signature Opt-Out for Partner Accounts                        *
            * @updatedBy...: eugenebasianomutya                               *
            * @updateDate..: 6/13/2015                                      *
            * @Case Number.: 03647888                                         *
            *******************************************************************/
            if (Trigger.isInsert || Trigger.isUpdate) {
                if (Trigger.isInsert) {
                    AccountTriggerHelperExt.Update_SignatureRepPartnershipOptOut((List<Account>) Trigger.new, null, null, true);
                } else {
                    AccountTriggerHelperExt.Update_SignatureRepPartnershipOptOut(null, (Map<Id, Account>) Trigger.newMap, (Map<Id, Account>) Trigger.oldMap, false);
                }
                //Case: 04018783 - Update Account Trigger to Pull Count of Order - START

                //Case: 04018783 - Update Account Trigger to Pull Count of Order - END
            }
            /******************************************Case:03647888 End's here*************************************************/
        }
    }

    public static String replaceValue(String changes, String field, String replaceTo) {
        String result = '';
        String[] fields = changes.split(';');
        for (String item : fields) {
            if (item.contains(field)) {
                String[] itemValue = item.split(':');
                item = itemValue[0] + ':' + replaceTo;
            }
            result += item + ';';
        }
        return result;
    }

    /*********************************************************************** ***************************
     * Project Name..........:                                                                         *
     * File..................: Account.Trigger                                                         *
     * Version...............: 1.0                                                                     *
     * Created by............: Simplion Technologies                                                   *
     * Created Date..........: 14-04-2014                                                              *
     * Last Modified by......: Simplion Technologies                                                   *
     * Last Modified Date....: 14-04-2014                                                              *
     * Description...........: Trigger on Account object                                               *
     *                        After Insert: Check to see if implementation is needed.                 *
     *                        After Update: Check to see if implementation is warrented with update.  *
     *                                      Closed implementations if necessary.                      *
     *                                      Created Cancelled Trial leads.                            *
     *                                      Alert contract owners if necessary.                       *
     **************************************************************************************************/
    public class AccountAfter extends Triggers.TriggerHandlerBase {
        override public void handle() {
            //To by pass trigger when converting lead from Relayware
            if (UserInfo.getName() == UserHelper.API_USER_NAME) {
                return;
            }

            // Flag to check if trigger is to be executed or not.
            if (TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT || TriggerHandler.BY_PASS_ACCOUNT_ON_UPDATE || TriggerHandler.BY_PASS_ACCOUNT_ON_AFTER) {
                return;
            } else {
                TriggerHandler.BY_PASS_ACCOUNT_ON_AFTER = true;
            }
            /********************* Start ------- Code for Bypassing AccountHierarchyValidation ***********************/
            Boolean validateAccountHierarchyBool = ByPassTrigger__c.getOrgDefaults() != null && ByPassTrigger__c.getOrgDefaults().Validate_Account_Hierarchy__c;
            /********************* End ------- Code for Bypassing AccountHierarchyValidation ***********************/

            Boolean accountHierarchyCalculationEnabled = (AccountHierarchyCustomSetting__c.getInstance('AccountHierarchyInstance') != null && AccountHierarchyCustomSetting__c.getInstance('AccountHierarchyInstance').HierarchyCalculationEnabled__c);
            if (Trigger.isUpdate) {
                /*This code is used for updating customer account's fields for partner account*/
                AccountTriggerHelper.partnerAccount();
                //Added for BOB NGBS Hierarchy update - start
                Set<Id> accIds = new Set<Id>();
                Id partnerAccountRecordTypeId = AccountHelper.RT_ID_PARTNER_ACCOUNT;
                for (Account acc : (List<Account>) Trigger.new) {
                    Boolean isPartnerAccountChanged = isChangedField(acc, Account.Partner_Account__c);
                    Boolean isBOB = acc.Partner_Type__c != null && acc.Partner_Type__c.contains(AccountHelper.ACCOUNT_PARTNER_BILL_ON_BEHALF);
                    if (acc.Partner_Account__c != null && isPartnerAccountChanged && isBOB && acc.RecordTypeId == partnerAccountRecordTypeId) {
                        accIds.add(acc.Id);
                    }
                }
                if (!accIds.isEmpty()) {
                    NGBS_Partner_Hierarchy_Generator.getNGBSPartnerHierarchyFuture(accIds, false, false);
                }
                //Added for BOB NGBS Hierarchy update - end
            }

            List<Account> lstAccount = new List<Account>();

            Set<String> ultimateParentIdSet = new Set<String>(); // used for Account Hierarchy Total DLS Field update
            if (Trigger.isInsert || Trigger.isUpdate) {
                try {
                    /*This code is used to create Entitlements when entitlement is enabled*/
                    if (EntitlementHelper.IsEntitlementsEnabled()) {
                        EntitlementHelper.createEntitlements((List<Account>) Trigger.new, (Trigger.isInsert ? null : (Map<Id, Account>) Trigger.oldMap));
                    }
                } catch (Exception e) {
                    PlatformLog.logException('Error account trigger createEntitlements', e);
                }

                /****** For Account Hierarchy Total DLS Field update ********/
                for (Account acc : (List<Account>) Trigger.new) {
                    if (Trigger.isInsert) {
                        if (acc.Ultimate_Parent_Account_ID__c != null) {
                            ultimateParentIdSet.add(String.valueOf(acc.Ultimate_Parent_Account_ID__c).substring(0, 15));
                            ultimateParentIdSet.add(String.valueOf(acc.Id).substring(0, 15));
                        } else {
                            ultimateParentIdSet.add(String.valueOf(acc.Id).substring(0, 15));
                        }
                    } else if (Trigger.isUpdate) {
                        Account oldAcc = (Account) Trigger.oldMap.get(acc.Id);
                        if (isChangedField(acc, Account.ParentId) || isChangedField(acc, Account.RC_Account_Status__c) || isChangedField(acc, Account.Number_of_DL_s__c)) {
                            if (acc.Ultimate_Parent_Account_ID__c != null) {
                                ultimateParentIdSet.add(String.valueOf(acc.Ultimate_Parent_Account_ID__c).substring(0, 15));
                                ultimateParentIdSet.add(String.valueOf(acc.Id).substring(0, 15));
                                ultimateParentIdSet.add(String.valueOf(oldAcc.Ultimate_Parent_Account_ID__c).substring(0, 15));
                            } else {
                                ultimateParentIdSet.add(String.valueOf(acc.Id).substring(0, 15));
                            }
                        }
                    }
                }
                /************************** ADDED BY VIREN FOR CASE # 04258110 FOR INDUSTRY*********************************/
            }

            if (Trigger.isDelete) {
                ultimateParentIdSet = TriggerHandler.RELATED_ACCOUNT_ID_SET;
            }
            if (!ultimateParentIdSet.isEmpty() && !Test.isRunningTest()) {
                if (accountHierarchyCalculationEnabled) {// if Custom settings enabled
                    AccountTriggerHelperExt.runAccountHierarchyCalculation(ultimateParentIdSet);
                    if (Trigger.isDelete) {
                        TriggerHandler.RELATED_ACCOUNT_ID_SET = new Set<String>();
                    }
                }
            }
            /****** End of For Account Hierarchy Total DLS Field update ********/

            if (Trigger.isInsert) {
                /*This code is use to insert CarrierDataRecord */
                HelperUtils.updateCarrierDataRecordNew((List<Account>) Trigger.new);
                AccountTriggerHelper.newAccountMap = (Map<Id, Account>) Trigger.newMap;
                AccountTriggerHelper objAccountTrgHlpr = new AccountTriggerHelper();
            }

            if (Trigger.isUpdate) {
                AccountTriggerHelper.newAccountMap = (Map<Id, Account>) Trigger.newMap;
                AccountTriggerHelper.oldAccountMap = (Map<Id, Account>) Trigger.oldMap;
                AccountTriggerHelper objAccountTrgHlpr = new AccountTriggerHelper();
                //Naresh Kumar 03/02/2020 - Handles account sharing on owner change
                Sharing_AccountLeadHandler.handleAccountSharingOnOwnerChange((Map<Id, Account>) Trigger.newMap, (Map<Id, Account>) Trigger.oldMap);
                /*This code is used for inserting new lead, new implementaion,sending email*/
                AccountTriggerHelper.updateAccountActiveDate();
                //Start Account Hierarchy Validation
                /*This code is use to update partner account list*/
                lstAccount = AccountTriggerHelper.getAccountsToValidate();
            }

            if (Trigger.isInsert || Trigger.isUpdate) {
                AccountTriggerHelperExt.createUpdateAccountSplits((List<Account>) Trigger.new, AccountTriggerHelperExt.eligiblePartnerAccountStaticIdSet);
                if (lstAccount != null && !lstAccount.isEmpty()) {
                    try {
                        /*This code is used for updating customer account hierarchy*/
                        if (validateAccountHierarchyBool) {
                            AccountHierarchyValidation.validateAccountHierarchy(lstAccount);
                        }
                    } catch (Exception e) {
                        PlatformLog.logException('Error account trigger validateAccountHierarchy', e);
                    }
                }
                /*This code is used to clear the value of all the collections*/
                AccountTriggerHelper.deinitalize();
            }

            /********************************************************/
            if (Trigger.isInsert) {
                AccountTriggerHelper.createFinanceCaseOnPaid(null, (Map<Id, Account>) Trigger.newMap);
                /*This code is used for Account TeamRole for Case 05149600 - CSM Assignment and Reporting */
                AccountTriggerHelperExt.SetAccountTeamforCSM(true, null, (Map<Id, Account>) Trigger.newMap);
            } else if (Trigger.isUpdate) {
                AccountTriggerHelper.createFinanceCaseOnPaid((Map<Id, Account>) Trigger.oldMap, (Map<Id, Account>) Trigger.newMap);
                AccountTriggerHelperExt.deleteAccntSplitOnPartnerChange((Map<Id, Account>) Trigger.newMap);
                /*This code is used for Account TeamRole for Case 05149600 - CSM Assignment and Reporting */
                AccountTriggerHelperExt.SetAccountTeamforCSM(false, (Map<Id, Account>) Trigger.oldMap, (Map<Id, Account>) Trigger.newMap);
                //Case 05329077 - update Channel Manager in Child Records when update on Partner Account - START
                AccountTriggerHelperExt.UpdateChannelManager((Map<Id, Account>) Trigger.newMap, (Map<Id, Account>) Trigger.oldMap);
                //Case 05329077 - update Channel Manager in Child Records when update on Partner Account - END
                //Case 07333711 - Update Red_Account__c.IssueOwner__c on Account's CSM change
                setRedAccountIssueOwner((List<Account>) Trigger.new);
            }

            // Calculating AH_TOTAL_DLS__C and AH_TOTAL_MRR__C on Companies
            // Backlog Item: B-4026
            // CMR-230304
            // company object decommissioning starts
            ByPassTrigger__c byPassTrigger = ByPassTrigger__c.getInstance();
            if (!byPassTrigger.Bypass_Company_Process_Logic__c) {
                Set<Id> companyIdsToUpdate = new Set<Id>();
                if (Trigger.isDelete) {
                    for (Account acc : (List<Account>) Trigger.old) {
                        if (acc.AH_Name__c != null && acc.Number_of_DL_s__c != null) {
                            companyIdsToUpdate.add(acc.AH_Name__c);
                        }
                    }
                }
                updateCompanyTotalsFromAccount(companyIdsToUpdate);
            }
            // company object decommissioning ends
            if (Trigger.isUpdate) {
                Set<Id> accsId = new Set<Id>();
                for (Account acc : (List<Account>) Trigger.new) {
                    // Mavenlink integration logic
                    if (isChangedFieldFrom(acc, Account.Current_Owner_Name__c, null)
                        || isChangedFieldFrom(acc, Account.Current_Owner_Manager_Name__c, null)
                        || isChangedFieldFrom(acc, Account.RC_User_ID__c, null)) {
                        accsId.add(acc.Id);
                    }
                }
                if (!accsId.isEmpty()) {
                    PhaseTriggerHandler.updateRelatedPhases('Account', accsId);
                }
                // End of Mavenlink integration logic
            }
            //START ITEA-682 AAA AAE (Expansion team) assignment
            //Description: Update Opp Owners under Avaya Customer Accounts when Account Owner is Updated

            Schema.DescribeSObjectResult result = Account.SObjectType.getDescribe();
            Map<Id, Schema.RecordTypeInfo> rtMapByName = result.getRecordTypeInfosById();

            if (Trigger.isUpdate) {
                Set<Id> acctIds = new Set<Id>();
                for (Account acc : (List<Account>) Trigger.new) {
                    if ((isChangedField(acc, Account.OwnerId) || isChangedField(acc, Account.Current_Owner__c))
                        && rtMapByName.get(acc.RecordTypeId).getName() == AccountHelper.RT_NAME_CUSTOMER_ACCOUNT
                        && acc.RC_Brand__c == OpportunityHelper.BRAND_AVAYA) {
                        acctIds.add(acc.Id);
                    }
                }

                List<Opportunity> oppsToUpdate = (List<Opportunity>) new OpportunitySelector()
                                                .selectOpportunitiesForAcctOwnerUpdates(acctIds)
                                                .executeQuery();

                for (Opportunity opp : oppsToUpdate) {
                    Account acc = (Account) Trigger.newMap.get(opp.AccountId);
                    opp.OwnerId = acc.Current_Owner__c != null ? acc.Current_Owner__c : acc.OwnerId;
                }

                if (!oppsToUpdate.isEmpty()) {
                    update oppsToUpdate;
                }
            }
            //END ITEA-682

            if (Trigger.isUpdate) {
                Set<Id> accountsIds = new Set<Id>();
                Set<Id> wholesaleAccountIds = new Set<Id>();
                Set<Id> iobAccountIds = new Set<Id>();
                Set<Id> excludeOpportunityIds = new Set<Id>();
                for (Account newAcc : (List<Account>) Trigger.new) {
                    Account oldAcc = (Account) Trigger.oldMap.get(newAcc.Id);
                    if (AccountHelper.accountInvoiceOnBehalfSwitch(newAcc, oldAcc)) {
                        iobAccountIds.add(newAcc.Id);
                    }
                    if (AccountHelper.accountWholesaleSwitch(newAcc, oldAcc)) {
                        wholesaleAccountIds.add(newAcc.Id);
                    }
                }
                if (!wholesaleAccountIds.isEmpty()) {
                    // Do not invalidate opportunity from the current Wholesale Wizard process
                    List<PartnerOperationsLog__c> partnerOperationsLogs = (List<PartnerOperationsLog__c>)
                        new QueryFactory(PartnerOperationsLog__c.SObjectType)
                            .selectFields(new Set<String>{'Opportunity__c'})
                            .setCondition('Account__c IN :bind0'
                                    + ' AND Opportunity__c != null'
                                    + ' AND isCompleted__c = false'
                                    + ' AND isRejected__c = false')
                            .setQueryBindings(new List<Object>{ wholesaleAccountIds })
                            .executeQuery();
                    for (PartnerOperationsLog__c log : partnerOperationsLogs) {
                        if (log.Opportunity__c != null) {
                            excludeOpportunityIds.add(log.Opportunity__c);
                        }
                    }
                }

                if (!iobAccountIds.isEmpty()) {
                    List<Approval__c> iobApprovals = (List<Approval__c>) new ApprovalSelector()
                        .selectAllApprovalsForAccountByRecordType(
                            new List<Object>{
                                ApprovalHelper.RT_ID_INVOICE_ON_BEHALF_REQUEST,
                                iobAccountIds
                            })
                        .executeQuery();
                    for (Approval__c iobApproval : iobApprovals) {
                        if (iobApproval.Opportunity__c != null) {
                            excludeOpportunityIds.add(iobApproval.Opportunity__c);
                        }
                    }
                }

                accountsIds.addAll(iobAccountIds);
                accountsIds.addAll(wholesaleAccountIds);
                if (!accountsIds.isEmpty()) {
                    AccountTriggerHelper.invalidateQuotes(accountsIds, excludeOpportunityIds);
                }
            }
        }

        public void updateCompanyTotalsFromAccount(Set<Id> companyIds) {
            if (companyIds.isEmpty()) {
                return;
            }
            List<Account_Hierarchy__c> accountHierarchies = (List<Account_Hierarchy__c>) new AccountHierarchySelector()
                    .selectAccountHierarchyByIdInRange(companyIds).withoutSelectorFieldsIncluded()
                    .selectFields(new List<String>{'Id', 'AH_Total_DLs__c', 'AH_Total_MRR__c'})
                    .subselect(new AccountSelector()
                        .selectAccounts()
                        .withoutSelectorFieldsIncluded()
                        .selectFields(new List<String>{'Id', 'Number_of_DL_s__c'}))
                    .executeQuery();
            for (Account_Hierarchy__c comp : accountHierarchies) {
                comp.AH_Total_DLs__c = 0;
                comp.AH_Total_MRR__c = 0;
                for (Account acc : comp.Accounts__r) {
                    comp.AH_Total_DLs__c += (acc.Number_of_DL_s__c != null ? acc.Number_of_DL_s__c : 0);
                }
            }

            if (!accountHierarchies.isEmpty()) {
                update accountHierarchies;
            }
        }

        private void setRedAccountIssueOwner(List<Account> newAccounts) {
            Map<Id, Id> accId_changedCsmIdMap = new Map<Id, Id>();
            for (Account acc : newAccounts) {
                if (CoreObjectBase.isFieldChanged(acc, Account.CSM__c)) {
                    accId_changedCsmIdMap.put(acc.Id, acc.CSM__c);
                }
            }

            if (accId_changedCsmIdMap.isEmpty()) {
                return;
            }

            List<Red_Account__c> redAccounts = (List<Red_Account__c>) new QueryFactory(Red_Account__c.SObjectType)
                .selectFields(new List<String>{'EscalatedAccount__c'})
                .setCondition('EscalatedAccount__c IN :bind0')
                .setQueryBindings(new List<Object>{accId_changedCsmIdMap.keySet()})
                .executeQuery();

            for (Red_Account__c redAcc : redAccounts) {
                redAcc.Issue_Owner__c = accId_changedCsmIdMap.get(redAcc.EscalatedAccount__c);
            }

            if (!redAccounts.isEmpty()) {
                update redAccounts;
            }
        }
    }

    public class ProcessMigratedAccounts extends Triggers.TriggerHandlerBase {
        override public void handle() {
            List<Id> migratedAccountIdSet = new List<Id>();
            List<Quote> quotesToUpdate = new List<Quote>();
            List<Entitlement__c> entitlementsToUpdate = new List<Entitlement__c>();

            for (Account acc : (List<Account>) Trigger.new) {
                if (isChangedFieldToNonNull(acc, Account.Billing_ID__c)
                    && acc.Billing_System__c == AccountHelper.BILLING_SYSTEM_NBS
                    || isChangedFieldTo(acc, Account.Billing_System__c, AccountHelper.BILLING_SYSTEM_NBS)
                    && String.isNotBlank(acc.Billing_ID__c)
                ) {
                    migratedAccountIdSet.add(acc.Id);
                }
            }
            if (migratedAccountIdSet.isEmpty()) {
                return;
            }

            List<String> opportunityStages = new List<String>{
                OpportunityHelper.STAGE_NAME_DOWNGRADED
            };
            opportunityStages.addAll(OpportunityHelper.STAGE_NAMES_CLOSED);

            for (Quote qt : (List<Quote>) new QuoteSelector()
                            .selectQuotes()
                            .withoutSelectorFieldsIncluded()
                            .selectFields(new List<String>{
                                'Id', 'Account__c', 'Status', 'RecordTypeId', 'Quote_is_Invalid__c', 'Opportunity.StageName'
                            })
                            .setCondition('Account__c IN :bind0')
                            .setQueryBindings(new List<Object>{ migratedAccountIdSet })
                            .executeQuery()) {
                if (QuoteHelper.isSalesQuote(qt) && !opportunityStages.contains(qt.Opportunity.StageName)) {
                    qt.Quote_is_Invalid__c = true;
                    quotesToUpdate.add(qt);
                }
            }

            for (Entitlement__c ent : (List<Entitlement__c>) new EntitlementSelector()
                                    .selectActiveEntitlementsForAccount(new List<Object>{ migratedAccountIdSet })
                                    .executeQuery()) {
                if (ent.Product__r.Sub_Category__c == Product2Helper.SUBCATEGORY_RINGCENTRAL && ent.Quote__c == null) {
                    ent.Active__c = false;
                    entitlementsToUpdate.add(ent);
                }
            }

            System.enqueueJob(new AsyncJob(quotesToUpdate, entitlementsToUpdate));
        }
    }

    public class AsyncJob implements Queueable {
        private List<Quote> quotesToInvalidate;
        private List<Entitlement__c> entitlementsToDeactivate;

        public AsyncJob(List<Quote> quotesToInvalidate, List<Entitlement__c> entitlementsToDeactivate) {
            this.quotesToInvalidate = quotesToInvalidate;
            this.entitlementsToDeactivate = entitlementsToDeactivate;
        }

        public void execute(QueueableContext context) {
            try {
                if (!quotesToInvalidate.isEmpty()) {
                    update quotesToInvalidate;
                }
                if (!entitlementsToDeactivate.isEmpty()) {
                    update entitlementsToDeactivate;
                }
            } catch (DmlException e) {
                PlatformLog.logException('Quote invalidation & entitlement deactivation for migrated accounts', e);
            }
        }
    }

    public class PopulateSDRAgentRoleNames extends Triggers.TriggerHandlerBase {
        override public void handle() {

            Map<Id, Account> sdrAgentIdToAccountMap = new Map<Id, Account>();

            for (Account acc : (List<Account>) Trigger.new) {
                if (acc.SDR_Agent__c != null) {
                    sdrAgentIdToAccountMap.put(acc.SDR_Agent__c, acc);
                }
            }

            if (sdrAgentIdToAccountMap.isEmpty()) {
                return;
            }

            for (User usr : AccountTriggerHelper.getUserDetails(sdrAgentIdToAccountMap.keySet()).values()) {
                Account acc = sdrAgentIdToAccountMap.get(usr.Id);
                acc.SDR_Agent_Name__c = usr.Name;
                acc.SDR_Role_Name__c = usr.UserRole.Name;
            }
        }
    }

    public class PerformWorkFlowActions extends Triggers.TriggerHandlerBase {
        override public void handle() {
            Feature_Toggle__c featureToggle = Feature_Toggle__c.getInstance();
            if (featureToggle == null || featureToggle.AccountWorkflowRulesAndProcToTrigger__c == null || featureToggle.AccountWorkflowRulesAndProcToTrigger__c == false) {
                return;
            }
            Set<Id> accountIds = new Set<Id>();
            List<Package__c> packages = new List<Package__c>();

            If (Trigger.isUpdate) {
                accountIds = Trigger.newMap.keySet();
                packages = new PackageSelector()
                    .selectPackagesForNewReferences(new List<Object> {accountIds})
                    .setQueryCaching(true)
                    .executeQuery();
            }

            Map<Id, Package__c> accountToPackagesMap = new Map<Id, Package__c>();
            for (Package__c pkg : packages) {
                accountToPackagesMap.put(pkg.Enterprise_Account_ID__c, pkg);
            }

            Set<Id> userIdSet = getUserIdSet(Trigger.new);
            Map<Id, User> userIdToUserMap = UserHelper.getORQueryUsers(userIdSet);
            for (Account acc : (List<Account>) Trigger.new) {
                Package__c pkg = accountToPackagesMap.get(acc.Id);
                updateBillAsOfDate(acc);
                clearCurrentOwnerIfRCSFSync(acc);
                npsSurveyUpdate(acc, pkg);
                updateBTBrand(acc);
                populateOwnerEmailPrevious(acc, userIdToUserMap);
                // Process builder "account CSM" logic is implemented in this method
                updateAccountCSM(acc, userIdToUserMap);
            }
        }

        private Set<Id> getUserIdSet(List<Account> accList) {
            Set<Id> userIdSet = new Set<Id>();
            for (Account acc : accList) {
                if (acc.Current_Owner_Previous__c != null) {
                    userIdSet.add(acc.Current_Owner_Previous__c);
                }
                if (acc.CSM__c != null) {
                    userIdSet.add(acc.CSM__c);
                }
                if (acc.Technical_Account_Manager__c != null) {
                    userIdSet.add(acc.Technical_Account_Manager__c);
                }
                if (acc.Contact_Center_TAM_Updated__c != null) {
                    userIdSet.add(acc.Contact_Center_TAM_Updated__c);
                }
            }
            return userIdSet;
        }

        private void updateBillAsOfDate(Account acc) {
            if (isChangedFieldFrom(acc, Account.InContact_Service__c, null) || isChangedFieldFrom(acc, Account.InContact_Service__c, '')
            ) {
                acc.Bill_As_Of_Date__c = System.today().addDays(60);
            }
        }

        private void clearCurrentOwnerIfRCSFSync(Account acc) {
            if (isChangedFieldTo(acc, Account.Current_Owner__c, UserRC.rcsfSyncUserObj.Id__c)) {
                acc.Current_Owner__c = null;
            }
        }

        private void npsSurveyUpdate(Account acc, Package__c pkg) {
            if (pkg == null) {
                return;
            }
            if (pkg.Service_Type__c == AccountHelper.SERVICE_TYPE_OFFICE || pkg.Service_Type__c == AccountHelper.SERVICE_TYPE_PROFESSIONAL) {
                acc.Product_Survey__c = 'http://ringcentral.force.com/rcsurvey/OfficeProSurvey?conId=';
            } else if (pkg.Service_Type__c == AccountHelper.SERVICE_TYPE_FAX) {
                acc.Product_Survey__c = 'http://ringcentral.force.com/rcsurvey/FaxSurvey?conId=';
            }
        }

        private void updateBTBrand(Account acc) {
            if (acc.RC_Brand__c == AccountTriggerHelper.RC_BRAND_BT_CLOUD_PHONE) {
                acc.RC_Brand__c = AccountTriggerHelper.RC_BRAND_BT_BUSINESS;
            }
        }

        private void populateOwnerEmailPrevious(Account acc, Map<Id, User> userIdToUserMap) {
            User currentOwnerPrevious = userIdToUserMap.get(acc.Current_Owner_Previous__c);

            acc.Current_Owner_Email_Previous__c = currentOwnerPrevious != null
                ? currentOwnerPrevious.Email
                : null;
        }

        private void updateAccountCSM(Account acc, Map<Id, User> userIdToUserMap) {
            User csmUser = userIdToUserMap.get(acc.CSM__c);
            if (csmUser == null) {
                acc.CSM_Email__c = null;
                acc.CSM_Name__c = null;
                acc.CSM_Phone__c = null;
            } else if (isChangedFieldToNonNull(acc, Account.CSM__c)) {
                acc.CSM_Email__c = csmUser.Email;
                acc.CSM_Name__c = getUserName(csmUser);
                acc.CSM_Phone__c = csmUser.Phone != null ? csmUser.Phone : acc.CSM_Phone__c;
            }
        }

        private String getUserName(User user) {
            return user.FirstName != null ? user.FirstName + ' ' + user.LastName : user.LastName;
        }
    }

    public class RejectApporvals extends Triggers.TriggerHandlerBase {
        override public void handle() {
            Set<Id> accIds = new Set<Id>();
            Map<String, String> countryCodes = SettingsHelper.getCountryCodesFullName();
            for (Account acc : (List<Account>) Trigger.new) {
                Account oldAccount = (Account) Trigger.oldMap.get(acc.Id);
                if (acc.TaxExemptionApprovals__c
                    && !TaxExemptionHelper.isIndiaCountry(acc.BillingCountry)
                    && ((isChangedField(acc, Account.BillingCountry) && oldAccount.BillingCountry != null && acc.BillingCountry != countryCodes.get(oldAccount.BillingCountry.toLowerCase()))
                        || isChangedField(acc, Account.BillingStreet)
                        || isChangedField(acc, Account.BillingCity)
                        || isChangedField(acc, Account.BillingPostalCode)
                        || isChangedField(acc, Account.BillingState))
                ) {
                    accIds.add(acc.Id);
                }
            }
            if (accIds.isEmpty()) {
                return;
            }

            List<Approval__c> accountApprovals = ApprovalHelper.getApprovedApprovals(
                accIds, new List<String>{ ApprovalHelper.STATUS_APPROVED }
            );
            String comment = 'Approval was rejected due to billing country changed';
            if (!accountApprovals.isEmpty()) {
                System.enqueueJob(new BusinessIdentitiesService(accountApprovals, comment));
            }
        }
    }

    public class CreateDealDeskCase extends Triggers.TriggerHandlerBase {
        override public void handle() {
            Set<Id> accIdsToCreateCasesFor = new Set<Id>();
            Map<Id,Account> idsToAccountsWithChangedFromNullUserIds = new Map<Id,Account>();
            Set<Id> accIdsWithExistingCaseDescriptions = new Set<Id>();

            for (Account acc : (List<Account>) Trigger.new) {
                if (isChangedFieldFrom(acc, Account.RC_User_ID__c, null)) {
                    idsToAccountsWithChangedFromNullUserIds.put(acc.Id, acc);
                }
            }
            if(idsToAccountsWithChangedFromNullUserIds.isEmpty()) {
                return;
            }

            List<DealDeskCaseDescription__c> existingDescsForAccounts = (List<DealDeskCaseDescription__c>) new DealDeskCaseDescriptionSelector()
                .selectDealDeskCaseDescriptionsForAccounts(new List<Object> {idsToAccountsWithChangedFromNullUserIds.keySet()})
                .executeQuery();
            for(DealDeskCaseDescription__c caseDesc : existingDescsForAccounts) {
                accIdsWithExistingCaseDescriptions.add(caseDesc.Account__c);
            }

            for (Account acc : idsToAccountsWithChangedFromNullUserIds.values()) {
                if (acc.Changes__c != null && acc.Changes__c.contains('RC_User_ID__c')
                    || accIdsWithExistingCaseDescriptions.contains(acc.Id)
                ) {
                    accIdsToCreateCasesFor.add(acc.Id);
                }
            }

            if (!accIdsToCreateCasesFor.isEmpty()) {
                System.enqueueJob(new CaseQueueable(accIdsToCreateCasesFor, existingDescsForAccounts));
            }
        }
    }

    public class ValidateVATNumberWithApproval extends Triggers.TriggerHandlerBase {
        override public void handle() {
            List<Id> accIds = new List<Id>();
            List<Approval__c> approvedApprovals = new List<Approval__c>();

            for (Account acc : (List<Account>) Trigger.new) {
                if (isChangedField(acc, Account.VATNumber__c)) {
                    accIds.add(acc.Id);
                }
            }

            if (!accIds.isEmpty()) {
                approvedApprovals = new ApprovalSelector()
                                    .selectApprovedTaxExemptionApprovalsForAccount(
                                        new List<Object>{ accIds, new List<String>{ ApprovalHelper.STATUS_APPROVED }, new Set<Id>() }
                                    )
                                    .executeQuery();
            }

            if (!approvedApprovals.isEmpty()) {
                for (Approval__c app : approvedApprovals) {
                    for (Account acc : (List<Account>) Trigger.new) {
                        if (acc.VATNumber__c != app.VATNumber__c && acc.Id == app.Account__c && !TaxExemptionHelper.notCheckVATNumber) {
                            acc.addError(AccountHelper.VAT_NUMBER_EXCEPTION_APPROVAL);
                            break;
                        }
                    }
                }
            }
        }
    }

    public class PopulateWebisteFromContactEmail extends Triggers.TriggerHandlerBase {
        override public void handle() {
            String ignoreDomains = Label.Ignore_domains_Webiste_Account;
            List<String> lstIgnoreDomains = (!String.isEmpty(ignoreDomains)) ? ignoreDomains.split(',') : new List<String>();
            String domain;
            for (Account acc : (List<Account>) Trigger.new) {
                if (acc.RecordTypeId != AccountHelper.RT_ID_PARTNER_ACCOUNT
                    && !String.isEmpty(acc.ContactMostFrequentEmail__c)
                    && (Trigger.isInsert || (Trigger.isUpdate && isChangedField(acc, Account.ContactMostFrequentEmail__c)))
                ) {
                    if (acc.ContactMostFrequentEmail__c.contains('@')) {
                        domain = acc.ContactMostFrequentEmail__c.substringafter('@');
                        if (lstIgnoreDomains.isEmpty() || (!lstIgnoreDomains.contains(domain))) {
                            acc.Website = domain;
                        }
                    }
                }
            }
        }
    }

    public class PopulateSystemProcessStageCreated extends Triggers.TriggerHandlerBase {
        override public void handle() {
            Gating_Process_Stage__c processStage = Gating_Process_Stage__c.getInstance();
            Id recTypeId = AccountHelper.RT_ID_CUSTOMER_ACCOUNT;

            try {
                for (Account acc : (List<Account>) Trigger.new) {
                    if(acc.RC_Brand__c!=null && System.Label.BizMerge_Brand_Exclusion_List!=null
                    && System.Label.BizMerge_Brand_Exclusion_List.contains(acc.RC_Brand__c))//BizMerge-Added Brand Name check to exclude Gating Logic for converted ATT Leads
                    {
                        continue;
                    }

                    if (Trigger.isInsert && acc.Systems_process_stage__c == null) {
                        acc.Systems_process_stage__c = 'SFDC Created';

                        if (processStage != null) {
                            if (acc.Systems_process_enrichment_bypass__c != null && acc.Systems_process_enrichment_bypass__c != 'Exclusions') {
                                acc.Systems_process_enrichment_bypass__c = null;
                            }

                            if (processStage.Bypass_Account_Gating_Process__c || processStage.Bypass_Enrichment_Process__c) {
                                acc.Systems_process_enrichment_bypass__c = 'Custom Setting Bypass';
                            } else if (processStage.Bypass_Account_Gating_Process__c == false && !processStage.Bypass_Enrichment_Process__c && recTypeId != null && acc.recordTypeId != recTypeId) {
                                //if partner and zi customer account enrichment should be bypassed and business rule is the reason
                                acc.Systems_process_enrichment_bypass__c = 'Business Rule';
                            }
                        }
                    }
                }
            } catch (Exception e) {
                PlatformLog.logException('Error AccountTriggerHandler.PopulateSystemProcessStageCreated', e);
            }
        }
    }

    public class PopulateSystemProcessEnrichmentBypass extends Triggers.TriggerHandlerBase {
        override public void handle() {
            Gating_Process_Stage__c processStage = Gating_Process_Stage__c.getInstance();
            if (processStage == null) {
                return;
            }

            List<String> excludedWebsites = new List<String>();
            List<String> excludedAccName = new List<String>();
            if (processStage.Account_Gating_Website_Exclusion__c != null && processStage.Account_Gating_Name_Exclusion__c != null) {
                excludedWebsites = processStage.Account_Gating_Website_Exclusion__c.split(',');
                excludedAccName = processStage.Account_Gating_Name_Exclusion__c.split(',');
            }
            try {
                for (Account acc: (List<Account>) Trigger.new) {
                    if(acc.RC_Brand__c!=null && System.Label.BizMerge_Brand_Exclusion_List!=null
                    && System.Label.BizMerge_Brand_Exclusion_List.contains(acc.RC_Brand__c))//BizMerge-Added Brand Name check to exclude Gating Logic for converted ATT Leads
                    {
                        continue;
                    }

                    if (Trigger.isInsert && !processStage.Bypass_Account_Gating_Process__c && !processStage.Bypass_Enrichment_Process__c) {
                        if (acc.LS_Status__c == 'Success') {
                            acc.Systems_process_enrichment_bypass__c = 'Business Rule';
                        } else if (acc.RC_Account_Status__c != null && processStage.Account_Gating_Status_Exclusion__c != null && processStage.Account_Gating_Status_Exclusion__c.containsIgnoreCase(acc.RC_Account_Status__c)) {
                            acc.Systems_process_enrichment_bypass__c = 'Exclusions';
                        }

                        if (acc.Name != null) {
                            for (String name : excludedAccName) {
                                if (acc.Name.containsIgnoreCase(name)) {
                                    acc.Systems_process_enrichment_bypass__c = 'Exclusions';
                                    break;
                                }
                            }
                        }

                        if (acc.Website != null) {
                            for (String webSite:excludedWebsites) {
                                if (acc.Website.containsIgnoreCase(webSite)) {
                                    acc.Systems_process_enrichment_bypass__c = 'Exclusions';
                                    break;
                                }
                            }
                        }
                    }
                }
            } catch (Exception e) {
                PlatformLog.logException('Error AccountTriggerHandler.PopulateSystemProcessEnrichmentBypass', e);
            }
        }
    }

    public class PopulateSystemProcessStageEnriched extends Triggers.TriggerHandlerBase {
        override public void handle() {
            try {
                Gating_Process_Stage__c processStage = Gating_Process_Stage__c.getInstance();
                if (processStage == null) {
                    return;
                }

                //SFDC enriched should be stamped only for customer accounts and non paid accounts
                for (Account acc: (List<Account>) Trigger.new) {
                    if(acc.RC_Brand__c!=null && System.Label.BizMerge_Brand_Exclusion_List!=null
                    && System.Label.BizMerge_Brand_Exclusion_List.contains(acc.RC_Brand__c))//BizMerge-Added Brand Name check to exclude Gating Logic for converted ATT Leads
                    {
                        continue;
                    }
                    if (!processStage.Bypass_Account_Gating_Process__c
                        && !processStage.Bypass_Enrichment_Process__c
                        && acc.LS_Status__c == 'Success'
                        && acc.LS_Enrichment_Date__c != null
                        && isChangedField(acc, Account.LS_Status__c)
                        && acc.Systems_process_stage__c != null
                        && (acc.Systems_process_stage__c == 'SFDC Created' || acc.Systems_process_stage__c == 'SFDC Updated' || acc.Systems_process_stage__c == 'Manual SFDC updated')
                    ) {
                        acc.Systems_process_stage__c = 'SFDC Enriched';
                        acc.SFDC_Enriched_Date_time__c = System.now();
                    }
                }
            } catch (Exception e) {
                PlatformLog.logException('Error AccountTriggerHandler.PopulateSystemProcessStageEnriched', e);
            }
        }
    }

    public class PopulateSystemProcessStageUpdated extends Triggers.TriggerHandlerBase {
        override public void handle() {
            Gating_Process_Stage__c processStage = Gating_Process_Stage__c.getInstance();
            if (processStage == null) {
                return;
            }
            List<String> excludedWebsites = new List<String>();
            List<String> excludedAccName = new List<String>();
            if (processStage.Account_Gating_Website_Exclusion__c != null && processStage.Account_Gating_Name_Exclusion__c != null) {
                excludedWebsites = processStage.Account_Gating_Website_Exclusion__c.split(',');
                excludedAccName = processStage.Account_Gating_Name_Exclusion__c.split(',');
            }
            for (Account acc : (List<Account>) Trigger.new) {
                if(acc.RC_Brand__c!=null && System.Label.BizMerge_Brand_Exclusion_List!=null
                && System.Label.BizMerge_Brand_Exclusion_List.contains(acc.RC_Brand__c))//BizMerge-Added Brand Name check to exclude Gating Logic for converted ATT Leads
                {
                    continue;
                }
                 if (!processStage.Bypass_Account_Gating_Process__c
                    && acc.RecordTypeId == AccountHelper.RT_ID_CUSTOMER_ACCOUNT
                    && ((acc.Systems_process_stage__c != null && acc.Systems_process_stage__c != 'SFDC Enriched') || acc.Systems_process_stage__c == null)
                    && (acc.LastModifiedById != null && processStage.Account_Last_Modified_Exclusion_Ids__c != null && !processStage.Account_Last_Modified_Exclusion_Ids__c.contains(acc.LastModifiedById))
                    && (acc.RC_Account_Status__c == null
                        || (acc.RC_Account_Status__c != null
                            && processStage.Account_Status_Exclusion__c != null
                            && !processStage.Account_Status_Exclusion__c.containsIgnoreCase(acc.RC_Account_Status__c)))
                    && (Trigger.isUpdate
                        && (isChangedField(acc, Account.Name)
                            || isChangedField(acc, Account.BillingCountry)
                            || isChangedField(acc, Account.Website)))
                ) {
                    acc.Systems_process_stage__c = 'SFDC Updated';
                    acc.SFDC_Updated_date_time__c = System.now();
                    acc.Systems_process_enrichment_bypass__c = null;
                    acc.LS_Status__c = null;
                    acc.LS_Enrichment_Date__c = null;

                    if (acc.RC_Account_Status__c != null
                        && processStage.Account_Gating_Status_Exclusion__c != null
                        && processStage.Account_Gating_Status_Exclusion__c.containsIgnoreCase(acc.RC_Account_Status__c)
                    ) {
                        acc.Systems_process_enrichment_bypass__c = 'Exclusions';
                    }

                    if (acc.Name != null) {
                        for (String name : excludedAccName) {
                            if (acc.Name.containsIgnoreCase(name)) {
                                acc.Systems_process_enrichment_bypass__c = 'Exclusions';
                                break;
                            }
                        }
                    }

                    if (acc.Website != null) {
                        for (String webSite : excludedWebsites) {
                            if (acc.Website.containsIgnoreCase(webSite)) {
                                acc.Systems_process_enrichment_bypass__c = 'Exclusions';
                                break;
                            }
                        }
                    }
                }

                if (acc.Systems_process_stage__c == 'Manual SFDC updated' && Trigger.isUpdate && isChangedField(acc, Account.Systems_process_stage__c)) {
                    acc.LS_Status__c = null;
                    acc.LS_Enrichment_Date__c = null;
                    acc.Systems_process_enrichment_bypass__c = null;
                    acc.SFDC_Updated_date_time__c = System.now();

                    if (acc.RC_Account_Status__c != null && processStage.Account_Gating_Status_Exclusion__c.containsIgnoreCase(acc.RC_Account_Status__c)){
                            acc.Systems_process_enrichment_bypass__c = 'Exclusions';
                    }
                    if (acc.Name != null) {
                        for (String name : excludedAccName) {
                            if (acc.Name.containsIgnoreCase(name)) {
                                acc.Systems_process_enrichment_bypass__c = 'Exclusions';
                                break;
                            }
                        }
                    }
                    if (acc.Website != null) {
                        for (String webSite : excludedWebsites) {
                            if (acc.Website.containsIgnoreCase(webSite)) {
                                acc.Systems_process_enrichment_bypass__c = 'Exclusions';
                                break;
                            }
                        }
                    }
                }
            }
        }
    }

    public class populateZIFieldsOnAccount extends Triggers.TriggerHandlerBase {
        override public void handle() {
            for (Account acc : (List<Account>) Trigger.new) {
                if (acc.ZI_CDP_AccountID_From_LS4SF__c != null
                    && (Trigger.isInsert || (Trigger.isUpdate && isChangedField(acc, Account.ZI_CDP_AccountID_From_LS4SF__c)))
                ) {
                    acc.ParentId = acc.ZI_CDP_AccountID_From_LS4SF__c;
                }
            }
        }
    }

    public class populateParentIdfromZIIdonAccount extends Triggers.TriggerHandlerBase {
        override public void handle() {
            Set<String> setZIIds = new Set<String>();
            Map<String, Id> mapAccountIds = new Map<String, Id>();
            Leadspace_field_bypass__c LSField = Leadspace_field_bypass__c.getInstance();
            Boolean lsFieldByPassAccountFields = LSField != null && LSField.Bypass_Account_fields__c;
            try {
                for (Account acc : (List<Account>) Trigger.new) {
                    if (Trigger.isInsert
                        || (Trigger.isUpdate && acc.RecordTypeId == AccountHelper.RT_ID_CUSTOMER_ACCOUNT)
                        || (Trigger.isUpdate
                            && lsFieldByPassAccountFields
                            && acc.ParentId == null
                            && acc.RecordTypeId == AccountHelper.RT_ID_CUSTOMER_ACCOUNT
                            && acc.LS_Enrichment_Date__c != null
                            && acc.LS_Status__c == 'Success'
                            && isChangedField(acc, Account.LS_Enrichment_Date__c))
                    ) {
                        if (acc.ZI_Id__c != null) {
                            if (Trigger.isInsert || Trigger.isUpdate && isChangedField(acc, Account.ZI_Id__c)) {
                                setZIIds.add(acc.ZI_Id__c);
                            }
                        }
                        if (acc.ZI_CDP_Match__c != null) {
                            if (Trigger.isInsert || Trigger.isUpdate && isChangedField(acc, Account.ZI_CDP_Match__c)) {
                                setZIIds.add(acc.ZI_CDP_Match__c);
                            }
                        }
                    }
                }
                if (setZIIds.isEmpty()) {
                    return;
                }

                for (Account acc : (List<Account>) new AccountSelector()
                    .selectAccounts()
                    .withoutSelectorFieldsIncluded()
                    .selectFields(new List<String>{ 'Id', 'ZI_Id__c' })
                    .setCondition('ZI_Id__c IN :bind0 AND RecordType.Name = \'ZI Customer Shell Account\'')
                    .setQueryBindings(new List<Object>{ setZIIds })
                    .executeQuery()) {
                    if (acc.ZI_Id__c != null) {
                        mapAccountIds.put(acc.ZI_Id__c, acc.Id);
                    }
                }

                for (Account acc : (List<Account>) Trigger.new) {
                    if (mapAccountIds != null && mapAccountIds.containsKey(acc.ZI_Id__c)) {
                        acc.ParentId = mapAccountIds.get(acc.ZI_Id__c);
                    }
                }
            } catch (Exception e) {
                PlatformLog.logException('Error AccountTriggerHelper.populateParentIdfromZIIdonAccount', e);
            }
        }
    }

    public class PopulateSegmentNameUltimateParentLogic extends Triggers.TriggerHandlerBase {
        override public void handle() {
            Gating_Process_Stage__c processStage = Gating_Process_Stage__c.getInstance();
            if (processStage == null) {
                return;
            }
            Set<String> setCountryNames = new Set<String>();
            Set<Decimal> setEmployeeNumbers = new Set<Decimal>();
            Set<Id> accIds = new Set<Id>();
            Map<String, List<Segment_Master__c>> mapCountryNameNLstSegmentMasters = new Map<String, List<Segment_Master__c>>();
            String SMCountry = '';
            String ROWCountryName = 'ROW';
            ByPassTrigger__c bypassTrigger = ByPassTrigger__c.getInstance();
            Id recTypeId = AccountHelper.RT_ID_CUSTOMER_ACCOUNT;
            if (bypassTrigger != null && bypassTrigger.Bypass_Resegmentation_Trigger_Logic__c == true) {
                return;
            }
            Set<SObjectField> fieldsToCheck = new Set<SObjectField>{
                Account.Multinational_Ultimate__c,
                Account.ZI_Company_Country__c,
                Account.Emp_Range_Sales_Override__c,
                Account.ZI_Employees__c,
                Account.NumberOfEmployees,
                Account.No_of_Employees__c,
                Account.LS_Employees__c,
                Account.ParentId,
                Account.Segment_Exception_Flag__c
            };

            for (Account acc : (List<Account>) Trigger.new) {
                if(acc.RC_Brand__c!=null && System.Label.BizMerge_Brand_Exclusion_List!=null
                && System.Label.BizMerge_Brand_Exclusion_List.contains(acc.RC_Brand__c))//BizMerge-Added Brand Name check to exclude Gating Logic for converted ATT Leads
                {
                    continue;

                }
                if (acc.SM_Country__c != null
                    && acc.SM_Employees__c != null
                    && (Trigger.isInsert || Trigger.isUpdate && (isChangedAnyField(acc, fieldsToCheck)
                            || (isChangedField(acc, Account.BillingCountry) && processStage.Bypass_Account_Gating_Process__c)
                            || (!processStage.Bypass_Account_Gating_Process__c)
                                && isChangedField(acc, Account.Systems_process_stage__c)
                                && (acc.Systems_process_stage__c == 'SFDC Enriched'
                                    || ((acc.Systems_process_stage__c == 'Manual SFDC updated' || acc.Systems_process_stage__c == 'SFDC Updated')
                                        && acc.Systems_process_enrichment_bypass__c == 'Exclusions'))
                            || (!processStage.Bypass_Account_Gating_Process__c
                                && isChangedField(acc, Account.Systems_process_enrichment_bypass__c)
                                && (acc.Systems_process_enrichment_bypass__c == 'Issue' || acc.Systems_process_enrichment_bypass__c == 'Exclusions'))))
                ) {
                    setCountryNames.add(acc.SM_Country__c);
                    setEmployeeNumbers.add(acc.SM_Employees__c);
                    accIds.add(acc.Id);
                } else if (Trigger.isUpdate && (acc.SM_Employees__c == null || acc.SM_Country__c == null)) {
                    accIds.add(acc.Id);
                }
            }

            if (accIds.isEmpty()) {
                return;
            }
            List<Account> recordsToUpdate = new List<Account>();

            if (Trigger.isUpdate
                && Limits.getQueueableJobs() < Limits.getLimitQueueableJobs()
                && processStage != null
                && !processStage.Bypass_Account_Gating_Process__c
            ) {
                System.enqueueJob(new GatingAccountSegmentQueuable(accIds, setCountryNames, setEmployeeNumbers, (Map<Id, Account>) Trigger.oldMap));
            } else {
                for (Segment_Master__c segmentMaster : (List<Segment_Master__c>) new QueryFactory(Segment_Master__c.SObjectType)
                                                        .selectFields(new List<String>{ 'Id', 'Country__c', 'Max__c', 'Min__c', 'Name' })
                                                        .setCondition('(Country__c IN :bind0 OR Country__c = \'ROW\') '
                                                            + 'AND Min__c <= :bind1 '
                                                            + 'AND Max__c >= :bind1 '
                                                            + 'AND Active__c = true'
                                                        )
                                                        .setQueryBindings(new List<Object>{setCountryNames, setEmployeeNumbers})
                                                        .executeQuery()) {
                    if (mapCountryNameNLstSegmentMasters.containsKey(segmentMaster.Country__c)) {
                        mapCountryNameNLstSegmentMasters.get(segmentMaster.Country__c).add(segmentMaster);
                    } else {
                        mapCountryNameNLstSegmentMasters.put(
                            segmentMaster.Country__c,
                            new List<Segment_Master__c>{ segmentMaster}
                        );
                    }
                }
            }

            for (Account acc : (List<Account>) Trigger.new) {
                Boolean isUpdated = false;
                Account updatedAccount = new Account(Id = acc.Id);
                if (acc.SM_Country__c != null && acc.SM_Employees__c != null) {
                    if (mapCountryNameNLstSegmentMasters.containskey(acc.SM_Country__c)) {
                        SMCountry = acc.SM_Country__c;
                    } else {
                        SMCountry = ROWCountryName;
                    }

                    if (mapCountryNameNLstSegmentMasters.containsKey(SMCountry)) {
                        for (Segment_Master__c segmentMaster : (List<Segment_Master__c>) mapCountryNameNLstSegmentMasters.get(SMCountry)) {
                            if (segmentMaster.Country__c != null
                                && segmentMaster.Min__c != null
                                && segmentMaster.Max__c != null
                                && segmentMaster.Max__c >= acc.SM_Employees__c
                                && segmentMaster.Min__c <= acc.SM_Employees__c
                                && processStage != null
                                && (processStage.Bypass_Account_Gating_Process__c
                                    || (!processStage.Bypass_Account_Gating_Process__c
                                        && Trigger.isInsert
                                        && (acc.LS_Status__c == 'Success'
                                            || acc.Systems_process_enrichment_bypass__c == 'Business Rule'
                                            || acc.Systems_process_enrichment_bypass__c == 'Exclusions'
                                            || (recTypeId != null && acc.RecordTypeId != recTypeId))))
                            ) {
                                if (acc.Segment_Name__c != segmentMaster.Id) {
                                    if (Trigger.isInsert) {
                                        updatedAccount.Segment_Name__c = segmentMaster.Id;
                                        isUpdated = true;
                                    } else {
                                        acc.Segment_Name__c = segmentMaster.Id;
                                    }
                                }
                                if (acc.Marketo_Segment_Name__c == null
                                    || (acc.Marketo_Segment_Name__c != null && !acc.Marketo_Segment_Name__c.equals(segmentMaster.Name))
                                ) {
                                    if (Trigger.isInsert) {
                                        updatedAccount.Marketo_Segment_Name__c = segmentMaster.Name;
                                        isUpdated = true;
                                    } else {
                                        acc.Marketo_Segment_Name__c = segmentMaster.Name;
                                    }
                                }
                                if (Trigger.isInsert && processStage != null && !processStage.Bypass_Account_Gating_Process__c) {
                                    if (Trigger.isInsert) {
                                        updatedAccount.Systems_process_stage__c = 'Segment Complete';
                                        updatedAccount.Segment_complete_date__c = System.now();
                                        isUpdated = true;
                                    } else {
                                        acc.Systems_process_stage__c = 'Segment Complete';
                                        acc.Segment_complete_date__c = System.now();
                                    }
                                }
                            }
                        }
                    }
                } else if (Trigger.isUpdate && (acc.SM_Employees__c == null || acc.SM_Country__c == null)) {
                    acc.Segment_Name__c = null;
                    acc.Marketo_Segment_Name__c = null;
                    acc.Systems_process_stage__c = 'Segment Complete';
                    acc.Segment_complete_date__c = System.now();
                }
                if (isUpdated) {
                    if(ConvertLead.IS_LEAD_CONVERT_PROCESSING && SettingsHelper.FEATURE_TOGGLE.EnableLeadConversionUsingCache__c){
                        Triggers.switchOff();
                        recordsToUpdate.add(updatedAccount);
                        Triggers.switchOn();
                    }
                    else {
                    recordsToUpdate.add(updatedAccount);
                	}
				}
            }
            if (!recordsToUpdate.isEmpty()) {
                update recordsToUpdate;
            }
        }
    }

    public class PopulateSegmentNameOnChildAccounts extends Triggers.TriggerHandlerBase {
        override public void handle() {
            Map<Id, String> accountMarketoSegmentName = new Map<Id, String>();
            Map<Id, String> accountSegmentName = new Map<Id, String>();

            ByPassTrigger__c bypassTrigger = ByPassTrigger__c.getInstance();

            if (bypassTrigger != null && bypassTrigger.Bypass_Resegmentation_Trigger_Logic__c == true) {
                return;
            }

            for (Account acc : (List<Account>) Trigger.new) {
                if(acc.RC_Brand__c!=null && System.Label.BizMerge_Brand_Exclusion_List!=null
                && System.Label.BizMerge_Brand_Exclusion_List.contains(acc.RC_Brand__c))//BizMerge-Added Brand Name check to exclude Gating Logic for converted ATT Leads
                {
                    continue;
                }

                if (acc.ParentId == null && (isChangedField(acc, Account.Segment_Name__c) || (isChangedField(acc, Account.ParentId)))) {
                    accountSegmentName.put(acc.Id, acc.Segment_Name__c);
                    accountMarketoSegmentName.put(acc.Id, acc.Marketo_Segment_Name__c);
                } else if (isChangedFieldToNonNull(acc, Account.ParentId)) {
                    accountSegmentName.put(acc.Ultimate_Parent_Account_ID__c, acc.Segment_Name__c);
                    accountMarketoSegmentName.put(acc.Ultimate_Parent_Account_ID__c, acc.Marketo_Segment_Name__c);
                }
            }

            if (accountSegmentName.isEmpty() || accountMarketoSegmentName.isEmpty()) {
                return;
            }

            //CMR-215399
            if (Limits.getQueueableJobs() < Limits.getLimitQueueableJobs()) {
                System.enqueueJob(new AccountSegmentNameQueuable(accountMarketoSegmentName, accountSegmentName));
            } else {
                Boolean isUpdated = false;
                List<Account> accountsToUpdate = new List<Account>();
                Set<Id> setAccountIds = new Set<Id>();
                setAccountIds = accountSegmentName.keySet();
                for (Account acc : (List<Account>) new QueryFactory(Account.SObjectType)
                                    .selectFields(new List<String>{
                                        'Id', 'Ultimate_Parent_Account_ID__c','SM_Employees__c','Parent.SM_Employees__c',
                                        'Segment_Name__c', 'Marketo_Segment_Name__c','Segment_Exception_Flag__c'
                                    })
                                    .setCondition(
                                        'ParentId != null AND ('
                                        +       'ParentId IN :bind0 '
                                        +       'OR Parent.ParentId IN :bind0 '
                                        +       'OR Parent.Parent.ParentId IN :bind0 '
                                        +       'OR Parent.Parent.Parent.ParentId IN :bind0 '
                                        +       'OR Parent.Parent.Parent.Parent.ParentId IN :bind0 '
                                        +       'OR Parent.Parent.Parent.Parent.Parent.ParentId IN :bind0'
                                        + ')')
                                    .setQueryBindings(new List<Object>{ setAccountIds })
                                    .executeQuery()) {
                    if (accountSegmentName.containsKey(acc.Ultimate_Parent_Account_ID__c)
                        && acc.Segment_Name__c != accountSegmentName.get(acc.Ultimate_Parent_Account_ID__c)
                        && !acc.Segment_Exception_Flag__c && acc.SM_Employees__c == acc.Parent.SM_Employees__c
                    ) {
                        acc.Segment_Name__c = accountSegmentName.get(acc.Ultimate_Parent_Account_ID__c);
                        isUpdated = true;
                    }

                    if (accountMarketoSegmentName.containsKey(acc.Ultimate_Parent_Account_ID__c)
                        && acc.Marketo_Segment_Name__c != accountMarketoSegmentName.get(acc.Ultimate_Parent_Account_ID__c)
                        && !acc.Segment_Exception_Flag__c && acc.SM_Employees__c == acc.Parent.SM_Employees__c
                    ) {
                        acc.Marketo_Segment_Name__c = accountMarketoSegmentName.get(acc.Ultimate_Parent_Account_ID__c);
                        isUpdated = true;
                    }

                    if (isUpdated) {
                        accountsToUpdate.add(acc);
                    }
                }

                if (!accountsToUpdate.isEmpty()) {
                    update accountsToUpdate;
                }
            }
        }
    }

    public class PopulateParentId extends Triggers.TriggerHandlerBase {
        override public void handle() {
            for (Account acc : (List<Account>) Trigger.new) {
                if (acc.ParentId == null
                    && acc.ZI_CDP_Account_ID_From_Lead__c != null
                    && (Trigger.isInsert || (Trigger.isUpdate && isChangedField(acc, Account.ZI_CDP_Account_ID_From_Lead__c)))
                ) {
                    acc.ParentId = acc.ZI_CDP_Account_ID_From_Lead__c;
                }
            }

        }
    }

    public class PopulateUltimateParentId extends Triggers.TriggerHandlerBase {
        override public void handle() {
            Set<Id> parentAccountIds = new Set<Id>();
            Map<Id, Id> mapAccountUltimates = new Map<Id, Id>();
            ByPassTrigger__c bypassTrigger = ByPassTrigger__c.getInstance();
            Gating_Process_Stage__c processStage = Gating_Process_Stage__c.getInstance();

            if (bypassTrigger != null && bypassTrigger.Bypass_Resegmentation_Trigger_Logic__c == true) {
                return;
            }

            for (Account acc : (List<Account>) Trigger.new) {
                if(acc.RC_Brand__c!=null && System.Label.BizMerge_Brand_Exclusion_List!=null
                && System.Label.BizMerge_Brand_Exclusion_List.contains(acc.RC_Brand__c))//BizMerge-Added Brand Name check to exclude Gating Logic for converted ATT Leads
                {
                    continue;

                }
                if (acc.ParentId != null) {
                    if (Trigger.isInsert) {
                        parentAccountIds.add(acc.ParentId);
                    }

                    if (Trigger.isUpdate) {
                        if (isChangedField(acc, Account.ParentId)
                            || isChangedField(acc, Account.Segment_Exception_Flag__c)
                            || (processStage != null && !processStage.Bypass_Account_Gating_Process__c
                                && isChangedField(acc, Account.Systems_process_stage__c)
                                && (acc.Systems_process_stage__c == 'SFDC Enriched'
                                    || ((acc.Systems_process_stage__c == 'Manual SFDC updated' || acc.Systems_process_stage__c=='SFDC Updated')
                                        && acc.Systems_process_enrichment_bypass__c=='Exclusions')))
                            || (processStage != null && !processStage.Bypass_Account_Gating_Process__c
                                && isChangedField(acc, Account.Systems_process_enrichment_bypass__c)
                                && (acc.Systems_process_enrichment_bypass__c == 'Issue' || acc.Systems_process_enrichment_bypass__c == 'Exclusions'))
                        ) {
                            parentAccountIds.add(acc.ParentId);
                        }
                    }
                } else if (Trigger.isUpdate && isChangedField(acc, Account.ParentId)) {
                    acc.Ultimate_Account__c = null;
                    mapAccountUltimates.put(acc.Id, acc.Id);
                }
            }

            //Logic to populate Ultimate Account on all child accounts under updated parent account
            if (!parentAccountIds.isEmpty()) {
                Map<Id, Account> parentAccounts = new Map<Id, Account>();
                for (Account acc : (List<Account>) new AccountSelector()
                                    .selectAccountsByIdNoFields(new List<Object> { parentAccountIds })
                                    .selectFields(new List<String>{
                                        'Id', 'Segment_Name__c', 'Marketo_Segment_Name__c', 'ParentId',
                                        'Parent.Segment_Name__c', 'Parent.Marketo_Segment_Name__c', 'Parent.ParentId',
                                        'Parent.Parent.Segment_Name__c', 'Parent.Parent.Marketo_Segment_Name__c',
                                        'Parent.Parent.Parent.Segment_Name__c',
                                        'Parent.Parent.Parent.Marketo_Segment_Name__c',
                                        'Parent.Parent.Parent.Parent.Segment_Name__c',
                                        'Parent.Parent.Parent.Parent.Marketo_Segment_Name__c',
                                        'Parent.Parent.ParentId', 'Parent.Parent.Parent.ParentId'
                                    })
                                    .executeQuery()) {
                    parentAccounts.put(acc.Id, acc);
                }
                for (Account acc : (List<Account>) Trigger.new) {
                    if (acc.ParentId != null) {
                        if (parentAccounts != null && parentAccounts.containsKey(acc.ParentId)) {
                            Account parentAccount = parentAccounts.get(acc.ParentId);
                            if (parentAccount.Parent.Parent.Parent.ParentId != null) {
                                acc.Ultimate_Account__c = parentAccount.Parent.Parent.Parent.ParentId;
                                if (!acc.Segment_Exception_Flag__c) {
                                    acc.Segment_Name__c = parentAccount.Parent.Parent.Parent.Parent.Segment_Name__c;
                                    acc.Marketo_Segment_Name__c = parentAccount.Parent.Parent.Parent.Parent.Marketo_Segment_Name__c;
                                }
                            } else if (parentAccount.Parent.Parent.ParentId != null) {
                                acc.Ultimate_Account__c = parentAccount.Parent.Parent.ParentId;
                                if (!acc.Segment_Exception_Flag__c) {
                                    acc.Segment_Name__c = parentAccount.Parent.Parent.Parent.Segment_Name__c;
                                    acc.Marketo_Segment_Name__c = parentAccount.Parent.Parent.Parent.Marketo_Segment_Name__c;
                                }
                            } else if (parentAccount.Parent.ParentId != null) {
                                acc.Ultimate_Account__c = parentAccount.Parent.ParentId;
                                if (!acc.Segment_Exception_Flag__c) {
                                    acc.Segment_Name__c = parentAccount.Parent.Parent.Segment_Name__c;
                                    acc.Marketo_Segment_Name__c = parentAccount.Parent.Parent.Marketo_Segment_Name__c;
                                }
                            } else if (parentAccount.ParentId != null) {
                                acc.Ultimate_Account__c = parentAccount.ParentId;
                                if (!acc.Segment_Exception_Flag__c) {
                                    acc.Segment_Name__c = parentAccount.Parent.Segment_Name__c;
                                    acc.Marketo_Segment_Name__c = parentAccount.Parent.Marketo_Segment_Name__c;
                                }
                            } else {
                                acc.Ultimate_Account__c = parentAccount.Id;
                                if (!acc.Segment_Exception_Flag__c) {
                                    acc.Segment_Name__c = parentAccount.Segment_Name__c;
                                    acc.Marketo_Segment_Name__c = parentAccount.Marketo_Segment_Name__c;
                                }
                            }
                            if (Trigger.isInsert
                                && processStage != null
                                && !processStage.Bypass_Account_Gating_Process__c
                                && (acc.LS_Status__c == 'Success'
                                || acc.Systems_process_enrichment_bypass__c == 'Business Rule'
                                || acc.Systems_process_enrichment_bypass__c == 'Exclusions')
                            ) {
                                if (acc.Segment_Name__c != null) {
                                    acc.Systems_process_stage__c='Segment Complete';
                                    acc.Segment_complete_date__c = System.now();
                                }
                            }
                        }
                    }

                    if (Trigger.isUpdate) {
                        mapAccountUltimates.put(acc.Id, acc.Ultimate_Account__c);
                    }
                }
            }

            if (!mapAccountUltimates.isEmpty()) {
                System.enqueueJob(new UltimateAccountChildQueuable(mapAccountUltimates,(Map<Id,Account>)Trigger.oldMap));
            }
        }
    }

    public class ValidateVATNumberForEngageAccounts extends Triggers.TriggerHandlerBase {
        override public void handle() {
            Set<Id> accIds = new Set<Id>();
            Map<Id, Id> accOppIds = new Map<Id, Id>();
            for (Account acc : (List<Account>) Trigger.new) {
                if (isChangedFieldFrom(acc, Account.VATNumber__c, null)) {
                    accIds.add(acc.Id);
                }
            }
            if (accIds.isEmpty()) {
                return;
            }

            for (Opportunity opp : (List<Opportunity>) new OpportunitySelector()
                                    .selectEngageOpportunitiesByAccountId(new List<Object>{
                                        accIds, OpportunityHelper.ENGAGE_TIERS
                                    })
                                    .executeQuery()) {
                accOppIds.put(opp.AccountId, opp.Id);
            }

            if (accOppIds.isEmpty() || TaxExemptionHelper.notCheckVATNumber) {
                return;
            }

            for (Account acc : (List<Account>) Trigger.new) {
                if (accOppIds.get(acc.Id) != null && !acc.IsMultiProductTechnicalAccount__c) {
                    acc.addError(AccountHelper.ENGAGE_VALIDATION_VAT_EXCEPTION);
                }
            }
        }
    }

    public class SendElaDataToNGBS extends Triggers.TriggerHandlerBase {
        private ElaNGBSIntegrationService elaNGBSIntegrationService = new ElaNGBSIntegrationService();
        override public void handle() {
            Set<Id> paidBillingAccountIds = findPaidBillingAccountIds(AccountHelper.ACCOUNT_TYPE_ELA_BILLING);
            Set<Id> paidServiceAccountIds = findPaidBillingAccountIds(AccountHelper.ACCOUNT_TYPE_ELA_SERVICE);

            if (!paidBillingAccountIds.isEmpty()) {
                List<Account> paidBillingAccountsWithPackage = elaNGBSIntegrationService.getBillingPaidAccountsWithPackages(paidBillingAccountIds);
                if (!paidBillingAccountsWithPackage.isEmpty()) {
                    elaNGBSIntegrationService.handleBillingAccSignUp(paidBillingAccountsWithPackage);
                }
            }

            if (!paidServiceAccountIds.isEmpty()) {
                List<Account> paidBillingAccountsWithPackage = elaNGBSIntegrationService.getParentAccountsWithPackages(paidServiceAccountIds);
                if (!paidBillingAccountsWithPackage.isEmpty()) {
                    elaNGBSIntegrationService.handleMissedServiceAccSignUp(paidBillingAccountsWithPackage, paidServiceAccountIds);
                }
            }
        }

        private Set<Id> findPaidBillingAccountIds(String elaAccountType) {
            Set<Id> paidElaAccounts = new Set<Id>();
            for (Account acc : (List<Account>) Trigger.new) {
                if (elaAccountType == acc.ELA_Account_Type__c && isChangedFieldTo(acc, Account.RC_Account_Status__c, AccountHelper.PAID_STATUS)) {

                    paidElaAccounts.add(acc.Id);
                }
            }
            return paidElaAccounts;
        }
    }

    public class TerminateActiveAgreement extends Triggers.TriggerHandlerBase {
        override public void handle() {
            List<Quote> quotesForTermination = new List<Quote>();
            Set<Id> activeSalesAgreementIds = new Set<Id>();
            Map<Id, Account> oldAccounts = (Map<Id, Account>) Trigger.oldMap;
            for (Account account : (List<Account>) Trigger.new) {
                if (!AccountHelper.isTerminated(oldAccounts.get(account.Id))
                    && AccountHelper.isTerminated(account) && account.Active_Sales_Agreement__c != null) {

                    activeSalesAgreementIds.add(account.Active_Sales_Agreement__c);
                    quotesForTermination.add(new Quote( Id = account.Active_Sales_Agreement__c ));
                    account.Active_Sales_Agreement__c = null;
                }
            }

            if (activeSalesAgreementIds.isEmpty()) {
                return;
            }

            List<Quote> quotes = (List<Quote>) new QuoteSelector()
                .selectMultiProductTechnicalQuotesByMasterQuoteIds(activeSalesAgreementIds)
                .executeQuery();

            if (!quotes.isEmpty()) {
                quotesForTermination.addAll(quotes);
            }

            for (Quote quote : quotesForTermination) {
                quote.Status = QuoteHelper.QUOTE_STATUS_TERMINATED;
            }

            if (!quotesForTermination.isEmpty()) {
                Triggers.switchOff();
                update quotesForTermination;
                Triggers.switchOn();
            }
        }
    }

    public class DFR_UpdateRelatedDFR extends Triggers.TriggerHandlerBase {

        override public void handle() {
            List<DFR_Update_Field__e> events = new List<DFR_Update_Field__e>();

            for (Account acc : (List<Account>) Trigger.new) {

                DFR_Update_Field__e event = new DFR_Update_Field__e();

                if (isChangedField(acc, Account.RC_Brand__c)
                    || isChangedField(acc, Account.Multinational_Ultimate__c)
                    || isChangedField(acc, Account.ZI_Company_Country__c)
                    || isChangedField(acc, Account.BillingCountry)) {

                    event.Id__c = acc.Id;
                    event.Fields__c = DemandFunnelPlatEvents.INTENDED_BRAND_FIELD;
                }

                if (isChangedField(acc, Account.Emp_Range_Sales_Override__c)
                    || isChangedField(acc, Account.SM_Employees__c)
                    || isChangedField(acc, Account.NumberOfEmployees)
                    || isChangedField(acc, Account.No_of_Employees__c)
                    || isChangedField(acc, Account.ZI_Employees__c)
                    || isChangedField(acc, Account.LS_Employees__c)) {

                    event.Id__c = acc.Id;
                    event.Fields__c = String.isBlank(event.Fields__c)
                                        ? DemandFunnelPlatEvents.SM_EMPLOYEES_FIELD
                                        : event.Fields__c + ';' + DemandFunnelPlatEvents.SM_EMPLOYEES_FIELD;
                }

                if (event.Id__c != null) {
                    events.add(event);
                }
            }

            if (!events.isEmpty()) {
                PlatformEvents.publishPlatformEvent(events, 'AccountTriggerHandler');
            }
        }
    }

    public class ValidateHoldOut extends Triggers.TriggerHandlerBase {
        override public void handle() {
            /* if (System.isBatch() || System.isFuture()) {
                return;
            } */

            Boolean doSOQL = false;
            Set<Id> accountOwners = new Set<Id>();
            for (Account acc : (List<Account>) Trigger.new) {
                accountOwners.add(acc.OwnerId);
                if (!userMapStatic.containsKey(acc.OwnerId)) {
                    doSOQL = true;
                }
            }
            if (doSOQL) {
                Map<Id, User> users = AccountTriggerHelper.getUserDetails(accountOwners);
                if (!users.isEmpty()) {
                    userMapStatic.putAll(users);
                }
            }

            Integer holdOutLimit;
            if (String.isNotBlank(Label.Hold_Out_List_Limit)) {
                holdOutLimit = Integer.valueOf(Label.Hold_Out_List_Limit);
            } else {
                if (Test.isRunningTest()) {
                    holdOutLimit = 20;
                } else {
                    AquivaHelper.throwAquivaException('Please ask your admin to set Hold Out List Limit in Custom Settings.');
                }
            }

            Map<Id, Integer> holdOutCountMap = new Map<Id, Integer>();

            for (Id ownerId : userMapStatic.keySet()) {
                User accOwner = userMapStatic.get(ownerId);
                Integer currentCount = (Integer) accOwner.Hold_Out_List__c != null ? (Integer) accOwner.Hold_Out_List__c : 0;
                holdOutCountMap.put(ownerId, currentCount);
            }

            for (Account acc : (List<Account>) Trigger.new) {
                if (acc.OwnerId == null) {
                    continue;
                }

                Integer count = holdOutCountMap.containsKey(acc.OwnerId) ? holdOutCountMap.get(acc.OwnerId) : 0;

                if (Trigger.isInsert) {
                    if (acc.Hold_Out__c) {
                        count++;
                    }
                }

                if (Trigger.isUpdate) {
                    if (isChangedFieldFrom(acc, Account.Hold_Out__c, false)) {
                        count++;
                    } else if (isChangedFieldTo(acc, Account.Hold_Out__c, false)) {
                        count--;
                    }
                }

                holdOutCountMap.put(acc.OwnerId, count);

                if (count > holdOutLimit) {
                    acc.Hold_Out__c.addError(String.format(Label.Account_Error_Account_Owner_Hold_Out_Limit, new List<Object>{ String.valueOf(holdOutLimit) }));
                }
            }
        }
    }

    @Future
    private static void updateUserHoldOut(Map<Id, Integer> usersToUpdate) {
        List<User> lstUsersToUpdate = new List<User>();
        for (Id uId : usersToUpdate.keySet()) {
            lstUsersToUpdate.add(new User(
                Id = uId,
                Hold_Out_List__c = usersToUpdate.get(uId)
            ));
        }

        try {
            update lstUsersToUpdate;
        } catch (Exception e) {
            List<Exception_And_Notification_History__c> exceptionList = new List<Exception_And_Notification_History__c>();
            for (User u : lstUsersToUpdate) {
                Exception_And_Notification_History__c exceptionObj = new Exception_And_Notification_History__c();
                exceptionObj.Object_Type__c = 'Exception';
                exceptionObj.content_var_01__c = 'ITEA-975 Account Hold Out';
                exceptionObj.Affected_record_ID__c = u.Id;
                exceptionList.add(exceptionObj);
            }
            ExceptionAndNotificationHelper.trackExceptions(exceptionList, e);
        }
    }

    private static void updateUserHoldOutBatch(Map<Id, Integer> usersToUpdate) {
        List<User> lstUsersToUpdate = new List<User>();
        for (Id uId : usersToUpdate.keySet()) {
            lstUsersToUpdate.add(new User(
                Id = uId,
                Hold_Out_List__c = usersToUpdate.get(uId)
            ));
        }

        try {
            update lstUsersToUpdate;
        } catch (Exception e) {
            List<Exception_And_Notification_History__c> exceptionList = new List<Exception_And_Notification_History__c>();
            for (User u : lstUsersToUpdate) {
                Exception_And_Notification_History__c exceptionObj = new Exception_And_Notification_History__c();
                exceptionObj.Object_Type__c = 'Exception';
                exceptionObj.content_label_01__c = 'Project';
                exceptionObj.content_label_02__c = 'Line Number';
                exceptionObj.content_label_03__c = 'Exception';
                exceptionObj.content_label_04__c = 'Get Stack Trace String';
                exceptionObj.content_label_05__c = 'Details';
                exceptionObj.content_label_06__c = 'Is Discrepancy Resolved';
                exceptionObj.content_var_01__c = 'ITEA-975 Account Hold Out';
                exceptionObj.Affected_record_ID__c = u.Id;
                exceptionList.add(exceptionObj);
            }
            ExceptionAndNotificationHelper.trackExceptions(exceptionList, e);
        }
    }

    public class UpdateHoldOut extends Triggers.TriggerHandlerBase {
        override public void handle() {
            Boolean doSOQL = false;
            Set<Id> accountOwners = new Set<Id>();
            Map<Id, Integer> usersToUpdate = new Map<Id, Integer>();
            for (Account acc : (List<Account>) Trigger.new) {
                accountOwners.add(acc.OwnerId);
                if (!userMapStatic.containsKey(acc.OwnerId)) {
                    doSOQL = true;
                }
            }
            if (doSOQL) {
                Map<Id, User> users = AccountTriggerHelper.getUserDetails(accountOwners);
                if (!users.isEmpty()) {
                    userMapStatic.putAll(users);
                }
            }

            Map<Id, Integer> holdOutCountMap = new Map<Id, Integer>();

            for (Id ownerId : userMapStatic.keySet()) {
                Integer currentCount = (Integer) userMapStatic.get(ownerId).Hold_Out_List__c != null ? (Integer) userMapStatic.get(ownerId).Hold_Out_List__c : 0;
                holdOutCountMap.put(ownerId, currentCount);
            }

            for (Account acc : (List<Account>) Trigger.new) {
                if (acc.OwnerId == null) {
                    continue;
                }

                Integer count = holdOutCountMap.containsKey(acc.OwnerId) ? holdOutCountMap.get(acc.OwnerId) : 0;

                if (Trigger.isInsert) {
                    if (acc.Hold_Out__c) {
                        count++;
                    }
                }

                if (Trigger.isUpdate) {
                    if (isChangedFieldFrom(acc, Account.Hold_Out__c, false)) {
                        count++;
                    } else if (isChangedFieldTo(acc, Account.Hold_Out__c, false)) {
                        count--;
                    }
                }

                holdOutCountMap.put(acc.OwnerId, count);
            }

            for (Id ownerId : holdOutCountMap.keySet()) {
                Integer newCount = holdOutCountMap.get(ownerId);
                Integer originalCount = (Integer) userMapStatic.get(ownerId).Hold_Out_List__c != null ? (Integer) userMapStatic.get(ownerId).Hold_Out_List__c : 0;

                if (newCount != originalCount) {
                    usersToUpdate.put(ownerId, newCount);
                }
            }


            try {
                if (!usersToUpdate.isEmpty() && !Test.isRunningTest()) {//Changed the Running option because of mixed DML in LeadTriggerHelper test class
                    if (System.isBatch()) {
                        updateUserHoldOutBatch(usersToUpdate);
                    } else {
                        updateUserHoldOut(usersToUpdate);
                    }
                }
            } catch (Exception exp) {
                List<Exception_And_Notification_History__c> exceptionList = new List<Exception_And_Notification_History__c>();
                for (Id userId : usersToUpdate.keySet()) {
                    Exception_And_Notification_History__c exceptionObj = new Exception_And_Notification_History__c();
                    exceptionObj.Object_Type__c = 'Exception';
                    exceptionObj.content_var_01__c = 'ITEA-975 Account Hold Out';
                    exceptionObj.Affected_record_ID__c = userId;
                    exceptionList.add(exceptionObj);
                }
            }
        }
    }

    public class ImplementationCreation extends Triggers.TriggerHandlerBase {
        override public void handle() {
            Set<Id> newlyRegisteredAccountIds = new Set<Id>();
            for (Account acc : (List<Account>) this.triggerRecords) {
                if ((Trigger.isInsert && String.isNotBlank(acc.RC_User_ID__c))
                    || (Trigger.isUpdate && ImplementationMethods.isImplConditionChanged(acc, (Account) oldRecord(acc)))) {
                    newlyRegisteredAccountIds.add(acc.Id);
                }
            }
            if (!newlyRegisteredAccountIds.isEmpty()) {
                if (System.isBatch() || System.isFuture()) {
                    ImplementationMethods.createImplementations(newlyRegisteredAccountIds);
                } else {
                    ImplementationMethods.createImplementationsAsync(newlyRegisteredAccountIds);
                }
            }
        }
    }

    public class ImplementationStatus2Change extends Triggers.TriggerHandlerBase {
        override public void handle() {
            if (isImplementationUpdated == true) {
                return;
            }
            isImplementationUpdated = true;
            List<Implementation__c> implsToUpdate = new List<Implementation__c>();
            for (Implementation__c impl : (List<Implementation__c>) new ImplementationSelector()
                                            .selectImplementationsWithStatusFields(new List<Object>{ Trigger.newMap.keySet() })
                                            .executeQuery()) {
                Account acc = (Account) Trigger.newMap.get(impl.Account__c);
                if (isChangedFieldTo(acc, Account.RC_Account_Status__c, AccountHelper.CANCELED_STATUS)
                    && !ImplementationHelper.CANCELABLE_IMPLEMENTATION_STATUSES_2.contains(impl.Implementation_Status_2__c)) {

                    impl.Implementation_Status_2__c = ImplementationHelper.STATUS_2_6c_COMPLETED_ACCOUNT_CANCELLED;
                    implsToUpdate.add(impl);
                } else if (AccountHelper.INACTIVE_ACCOUNT_STATUSES.contains(acc.RC_Account_Status__c)
                    && ImplementationHelper.CANCELABLE_IMPLEMENTATION_STATUSES_2.contains(impl.Implementation_Status_2__c)) {

                    impl.Implementation_Status_2__c = Date.valueOf(impl.CreatedDate).daysBetween(Date.today()) <= 15
                                                        ? ImplementationHelper.STATUS_2_INVALID_IMPLEMENTATIONS
                                                        : ImplementationHelper.STATUS_2_ACCOUNT_CANCELLED;
                    implsToUpdate.add(impl);
                }
                Trigger.newMap.get(impl.Account__c).put('Implementation_Status__c', impl.Implementation_Status_2__c);
            }
            if (!implsToUpdate.isEmpty()) {
                Triggers.switchOff();
                TriggerHandler.BY_PASS_IMPLEMENTATION_ON_AFTER = true;
                update implsToUpdate;
                TriggerHandler.BY_PASS_IMPLEMENTATION_ON_AFTER = false;
                Triggers.switchOn();
            }
        }
    }

    public class RestrictEditBillingAddressForIndianAccounts extends Triggers.TriggerHandlerBase {
        override public void handle() {
            if (isIntegrationUser()
                || ProfileHelper.isSysAdmin(UserInfo.getProfileId())
                || ProfileHelper.isCrmProfile(UserInfo.getProfileId())
                || isSalesLeadConversion) {
                return;
            }

            Map<Id, Account> accountsToCheck = new Map<Id, Account>();
            for (Account acc : (List<Account>) Trigger.new) {
                if (isAnyAddressFieldChanged(acc) && !KycDetailsHelper.canEditBillingAddressOnAccount(acc.Id)) {
                    if (AccountHelper.isEBIndianAccount(acc)) {
                        acc.addError(Label.BillingAddressCantBeEditedOnIndianAccount);
                    } else {
                        accountsToCheck.put(acc.Id, acc);
                    }
                }
            }
            if (accountsToCheck.isEmpty()) {
                return;
            }

            for (Account acc : (List<Account>) new AccountSelector()
                                .selectAccountWithKYCApprovals(new List<Object>{ accountsToCheck.keySet() })
                                .executeQuery()) {
                if (!acc.Approvals__r.isEmpty()) {
                    accountsToCheck.get(acc.Id).addError(Label.BillingAddressCantBeEditedOnIndianAccount);
                }
            }
        }

        private Boolean isAnyAddressFieldChanged(Account acc) {
            Boolean isAnyFieldChanged = false;
            for (String fieldName : AccountHelper.BILLING_ADDRESS_FIELDS) {
                isAnyFieldChanged |= isChangedField(acc, AccountHelper.FIELDS_MAP.get(fieldName.toLowerCase()));
            }
            return isAnyFieldChanged;
        }

        private Boolean isIntegrationUser() {
            return Billing_Address_Integration_Users__c.getAll().containsKey(
                UserInfo.getFirstName() + ' ' + UserInfo.getLastName()
            );
        }
    }

    public class ContactStatusUpdateForPaidAccounts extends Triggers.TriggerHandlerBase {
        override public void handle() {
            List<Contact_Update_ClosedWon_Opp__e> events = new List<Contact_Update_ClosedWon_Opp__e>();

            for (Account acc : (List<Account>) Trigger.new) {
                Account oldAcc = (Account) Trigger.oldMap.get(acc.Id);
                if (!ContactUpdatePlatformEventsHelper.isPaidOrTrial(oldAcc.RC_Account_Status__c)
                    && ContactUpdatePlatformEventsHelper.isPaidOrTrial(acc.RC_Account_Status__c)) {

                    events.add(new Contact_Update_ClosedWon_Opp__e(Account_Id__c = acc.Id));
                }
            }

            if (!events.isEmpty()) {
                PlatformEvents.publishPlatformEvent(events, 'AccountTriggerHandler');
            }
        }
    }

    public class qualtricsChurnSurvey extends Triggers.TriggerHandlerBase {
        override public void handle() {
            List<Id> accountIds = new List<Id>();
            for (Account acc : (List<Account>) Trigger.new) {
                if (acc.RC_Account_Status__c != null
                    && (isChangedField(acc, Account.RC_Account_Status__c) &&
                        (acc.RC_Account_Status__c.equalsIgnoreCase(AccountHelper.ACCOUNT_STATUS_CANCELED)
                        || AccountHelper.isPaid(acc)
                        || acc.RC_Account_Status__c.equalsIgnoreCase(AccountHelper.ACCOUNT_STATUS_FREE)))
                    || (isChangedField(acc, Account.Resend_Invitation__c)
                        && acc.Resend_Invitation__c == true)
                    || isChangedField(acc, Account.RC_Upgrade_Date__c)) {

                    accountIds.add(acc.Id);
                }
            }

            if (accountIds.isEmpty()) {
                return;
            }

            List<Case> caseListToSend = new List<Case>();
            List<Account> accountsToUpdate = new List<Account>();
            List<Account> accountListToSend = new List<Account>();

            Map<String, Primary_Contact_Fields_Medallia__mdt> pcFieldMap = Primary_Contact_Fields_Medallia__mdt.getAll();
            List<String> pcFieldValues = new List<String>();
            List<String> pcFieldKeySet = new List<String>(pcFieldMap.keySet());
            pcFieldKeySet.sort();
            String pcFields = '';
            for (String s : pcFieldKeySet) {
                pcFieldValues.add('Contact.' + pcFieldMap.get(s).Label);
            }
            pcFields = String.join(pcFieldValues, ', ') + ' ';
            List<String> ERFLabels = new List<String>{
                'Owner.Email',
                'Account_Owner_Manager_Email__c',
                'Current_Owner__r.Email',
                'Current_Owner_Manager_Email__c',
                'CSM__r.Email',
                'CSM__r.manager.Email',
                'Technical_Account_Manager__r.Email',
                'Contact_Center_TAM_Updated__r.Email'
            };
            String ERFFields = String.join(ERFLabels, ',') + ', ';
            //RC_Brand__c and Brand_Account__c fields added to the query as a part of the bizMerge project
            String queryString = 'SELECT Id, Account_Email_Recipient_Fields_Medallia__c, '
                + 'RC_Account_Status__c, RC_Brand__c, Main_point_of_contact__c, RC_Signup_Date__c, RC_Upgrade_Date__c, '
                + 'Primary_Contact_Fields_Medallia__c, RC_Service_name__c, Primary_Contact__c, '
                + ERFFields
                + '(SELECT Id, ContactId, Contact_Name__c , Brand_Account__c, ContactEmail, Contact.Email, Call_Outcome__c, RecordTypeName__c, Status ' +
                    + 'FROM Cases '
                    + 'WHERE RecordTypeName__c = \'CERT\' AND Call_Outcome__c = \'Cancelled\' '
                    + 'ORDER BY CreatedDate DESC LIMIT 1), '
                + '(SELECT Contact.Id, Role, IsPrimary, ' + pcFields
                    + 'FROM AccountContactRoles '
                    + 'WHERE IsPrimary = true AND Contact.Email != null '
                    + 'LIMIT 1), '
                + '(SELECT Id, Email FROM Contacts WHERE Email != null) '
                + 'FROM Account '
                + 'WHERE Id IN :accountIds';

            List<Account> accounts = (List<Account>) Database.query(queryString);
            if (accounts.isEmpty()) {
                return;
            }

            for (Account acc : accounts) {
                Boolean isUpdated = false;

                if (acc.AccountContactRoles != null && !acc.AccountContactRoles.isEmpty()) {
                    for (AccountContactRole acr : acc.AccountContactRoles) {
                        if (acr.IsPrimary) {
                            List<String> con = new List<String>();
                            for (String s : pcFieldValues) {
                                String fieldName = s.remove('Contact.');
                                if (fieldName == 'Customer_Contact_Role__c') {
                                    con.add(acr.Role);
                                } else if (fieldName == 'Customer_Contact_Is_Primary__c') {
                                    con.add(String.valueOf(acr.IsPrimary));
                                } else {
                                    String value = acr.getSObject('Contact') != null && acr.getSObject('Contact').get(fieldName) != null
                                                    ? acr.getSObject('Contact').get(fieldName).toString()
                                                    : '';
                                    con.add(value);
                                }
                            }
                            acc.Primary_Contact_Fields_Medallia__c = String.join(con, '|');
                            isUpdated = true;
                        }

                    }
                }

                // Added for Qualtrics Churn Survey. Populate Primary Contact when an Account is Cancelled.
                if (AccountHelper.ACCOUNT_STATUS_CANCELED.equalsIgnoreCase(acc.RC_Account_Status__c)) {
                    // This is make sure the primary contact is nullified when there is no primary contact in the account
                    if (acc.Primary_Contact__c != null) {
                        acc.Primary_Contact__c = null;
                        isUpdated = true;
                    }
                    if (acc.AccountContactRoles != null && !acc.AccountContactRoles.isEmpty()) {
                        for (AccountContactRole acr : acc.AccountContactRoles) {
                            if (acr.IsPrimary) {
                                acc.Primary_Contact__c = acr.ContactId;
                                isUpdated = true;
                            }

                        }
                    }
                    if (!acc.Cases.isEmpty()) {
                        caseListToSend.addAll(acc.Cases);
                    } else {
                        List<String> erfValues = new List<String>();
                        for (String erfLabel : ERFLabels) {
                            Integer dotMatches = erfLabel.countMatches('.');
                            List<String> erfLabelSplit = erfLabel.split('\\.');
                            if (erfLabelSplit.size() == 3) {
                                erfValues.add(
                                    acc.getSObject(erfLabelSplit[0]) != null && acc.getSObject(erfLabelSplit[0]).getSObject(erfLabelSplit[1]) != null
                                    ? acc.getSObject(erfLabelSplit[0]).getSObject(erfLabelSplit[1]).get(erfLabelSplit[2]).toString()
                                    : ''
                                );
                            } else if (erfLabelSplit.size() == 2) {
                                erfValues.add(
                                    acc.getSObject(erfLabelSplit[0]) != null && acc.getSObject(erfLabelSplit[0]).get(erfLabelSplit[1]) != null
                                    ? acc.getSObject(erfLabelSplit[0]).get(erfLabelSplit[1]).toString()
                                    : ''
                                );
                            } else {
                                erfValues.add(
                                    acc.get(erfLabelSplit[0]) != null
                                    ? acc.get(erfLabelSplit[0]).toString()
                                    : ''
                                );
                            }

                        }
                        acc.Account_Email_Recipient_Fields_Medallia__c = String.join(erfValues, '|');
                        accountListToSend.add(acc);
                        isUpdated = true;
                    }
                }

                if (isUpdated) {
                    accountsToUpdate.add(acc);
                }
            }

            if (!accountsToUpdate.isEmpty()) {
                Triggers.switchOff();
                update accountsToUpdate;
                Triggers.switchOn();
            }
            if (!caseListToSend.isEmpty()) {
                MedalliaSurveyHelper.sendMedalliaInvitation(caseListToSend, new List<Account>());
            }
            if (!accountListToSend.isEmpty()) {
                MedalliaSurveyHelper.sendMedalliaInvitation(new List<Case>(), accountListToSend);
            }
        }
    }

    public class UpdateDeletedAccountFields extends Triggers.TriggerHandlerBase {
        override public void handle() {
            for (Account acc : (List<Account>) Trigger.new) {
                if (isChangedToAnyStringCaseInsensitive(acc, Account.RC_Account_Status__c, AccountHelper.TERMINATED_ACCOUNT_STATUSES)) {
                    AccountTriggerHelper.updateAccountMRRFieldsToZero(acc);
                }
            }
        }
    }

    public class validateDPSFlaggedAccount extends Triggers.TriggerHandlerBase {
        override public void handle() {
            Map<String, Schema.SObjectField> fieldsMap = Schema.SObjectType.Account.fields.getMap();
            if (TriggerHandler.BY_PASS_ACCOUNT_ON_UPDATE) {
                return;
            }
            for (Account acc : (List<Account>) Trigger.new) {
                if (acc.descartesdps__HasBeenFlaggedByDPS__c) {
                    for (String fieldName : fieldsMap.keySet()) {
                        if (!fieldName.equalsIgnoreCase('descartesdps__HasBeenFlaggedByDPS__c')
                            && !fieldName.equalsIgnoreCase('DPS_Screening_Status__c')
                            && isChangedField(acc, fieldsMap.get(fieldName))) {

                            acc.addError(Label.DPS_Validation_Message);
                        }
                    }
                }
            }
        }
    }

    public class DescartesDPSAccountAfter extends Triggers.TriggerHandlerBase {
        override public void handle() {
            Map<Id, Account> oldMap = (Map<Id, Account>) Trigger.oldMap;
            Map<Id, Account> newMap = (Map<Id, Account>) Trigger.newMap;
            List<Account> newList = (List<Account>) Trigger.new;
            List<String> Ids = new List<String>();

            //Skip screening logic
            List<Account> newAccList = new List<Account>();
            List<String> skipScreeningNames = new List<String>();
            List<String> skipScreeningBrandTypes = new List<String>();
            if (System.Label.DPS_Skip_Account != null && System.Label.DPS_Skip_Account != '') {
                skipScreeningNames = System.Label.DPS_Skip_Account.split(';');
            }
            if(system.label.DPS_Skip_Account_Brand_Name != null && system.label.DPS_Skip_Account_Brand_Name != ''){
                skipScreeningBrandTypes = system.label.DPS_Skip_Account_Brand_Name.split(';');
            }
            if (newList != null && !newList.isEmpty() && skipScreeningNames != null && !skipScreeningNames.isEmpty()) {
                for (Account acc : newList) {
                    if (!(System.Label.DPS_Skip_User != null
                        && System.Label.DPS_Skip_User != ''
                        && acc.CreatedById == System.Label.DPS_Skip_User && skipScreeningNames.contains(acc.Name))&& !(skipScreeningBrandTypes.contains(acc.RC_Brand__c))) {

                        newAccList.add(acc);
                    }
                }
            }
            descartesdps__DPSAppSettings__c dpsAppSettings = descartesdps__DPSAppSettings__c.getAll().get('DPSDefaultAppSettings');
            if (dpsAppSettings != null && Trigger.isInsert && dpsAppSettings.descartesdps__StdInsertTriggersEnabled__c) {
                for (Account a : newAccList) {
                    Ids.add(a.Id);
                }
                if (isPartnerLeadConversion == true) {
                    if (Limits.getQueueableJobs() < Limits.getLimitQueueableJobs() && !System.isBatch()) {
                        System.enqueueJob(new DPSQueueableJob(Ids, newMap, null, false));
                    }
                } else if (!Ids.isEmpty() && descartesdps.DescartesDPSTriggerManager.ProceedWithScreening(Ids.get(0), null, newMap) && !System.isBatch()) {
                    descartesdps.DescartesDPSTriggerManager.triggerOnDemandSearchDPS(Ids.get(0));
                }
            } else if (dpsAppSettings != null && Trigger.isUpdate && dpsAppSettings.descartesdps__StdUpdateTriggersEnabled__c) {
                for (Account a : newAccList) {
                    Ids.add(a.Id);
                }
                if (!Ids.isEmpty() && descartesdps.DescartesDPSTriggerManager.ProceedWithScreening(Ids.get(0), oldMap, newMap) && !System.isBatch()) {
                    descartesdps.DescartesDPSTriggerManager.triggerOnDemandSearchDPS(Ids.get(0));
                }
            } else {
                System.debug('Screening skipped. To screen, enable insert/update trigger for this object.');
            }
        }
    }

    public class sendAccountDPSNotifications extends Triggers.TriggerHandlerBase {
        override public void handle() {
            Messaging.SingleEmailMessage[] messages = new List<Messaging.SingleEmailMessage>();
            List<String> toEmailAddress = new List<String>();
            List<String> toBccAddress = new List<String>();
            if (Label.Descartes_DPS_bccAddress != null) {
                toBccAddress.addAll((Label.Descartes_DPS_bccAddress).split(';'));
            }
            Map<Id, Account> accountsForNotification = new Map<Id, Account>();
            for (Account acc : (List<Account>) Trigger.new) {
                if (Trigger.isUpdate
                    && !acc.Allow_Notifications_from_DPS__c
                    && isChangedField(acc, Account.descartesdps__HasBeenFlaggedByDPS__c)) {
                    accountsForNotification.put(acc.Id, acc);
                }
            }

            if (accountsForNotification.isEmpty()) {
                return;
            }

            for (Account acc : (List<Account>) new AccountSelector()
                                .selectAccountsByIdForNotification(new List<Object>{ accountsForNotification.keySet() })
                                .executeQuery()) {
                toEmailAddress.add(acc.Owner.Email);
            }

            if (toEmailAddress.isEmpty()) {
                return;
            }

            Map<String, EmailTemplate> templates = new Map<String, EmailTemplate>();
            for (EmailTemplate template : (List<EmailTemplate>) new EmailTemplateSelector()
                                            .selectEmailTemplatesByDeveloperNames(
                                                new List<String>{
                                                    Label.DPS_ONHold_templatename,
                                                    Label.DPS_Screening_Complete_templatename
                                                },
                                                true
                                            )
                                            .executeQuery()) {
                templates.put(template.DeveloperName, template);
            }

            List<OrgWideEmailAddress> orgWideEmailAddress = (List<OrgWideEmailAddress>) new QueryFactory(OrgWideEmailAddress.SObjectType)
                                                            .selectFields(new List<String>{ 'Id' })
                                                            .setCondition('DisplayName =: bind0')
                                                            .setQueryBindings(new List<String>{ Label.OrgWideAddressDPS })
                                                            .executeQuery();

            if (templates.isEmpty() || orgWideEmailAddress.isEmpty()) {
                return;
            }

            for (Account acc : accountsForNotification.values()) {
                String emailTemplateName = acc.descartesdps__HasBeenFlaggedByDPS__c ? Label.DPS_ONHold_templatename : Label.DPS_Screening_Complete_templatename;
                EmailTemplate template = templates.get(emailTemplateName);

                String subject = template.Subject;
                subject = subject.replace('{!Account.Name}', acc.Name);
                String htmlBody = template.HtmlValue;
                htmlBody = htmlBody.replace('{!Account.Name}', acc.Name);
                htmlBody = htmlBody.replace('{!Account.Link}', URL.getOrgDomainUrl().toExternalForm() + '/' + acc.Id);

                Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
                message.setUseSignature(false);
                if (!orgWideEmailAddress.isEmpty()) {
                    message.setOrgWideEmailAddressId(orgWideEmailAddress[0].Id);
                }
                message.setBccSender(false);
                message.setTemplateId(template.Id);
                message.setWhatId(acc.Id);
                message.setSubject(subject);
                message.setHtmlBody(htmlBody);
                message.setSaveAsActivity(false);
                message.setToAddresses(toEmailAddress);
                if (!toBccAddress.isEmpty()) {
                    message.setBccAddresses(toBccAddress);
                }
                messages.add(message);
            }
            if (!messages.isEmpty()) {
                Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);
            }
        }
    }

    public class LockRecordsOnDPSFlagging extends Triggers.TriggerHandlerBase {
        override public void handle() {
            List<Id> recordsToLock = new List<Id>();
            List<Id> recordsToUnlock = new List<Id>();
            for (Account acc : (List<Account>) Trigger.new) {
                if (isChangedField(acc, Account.descartesdps__HasBeenFlaggedByDPS__c)) {
                    if (acc.descartesdps__HasBeenFlaggedByDPS__c) {
                        if (!Approval.isLocked(acc.Id)) {
                            recordsToLock.add(acc.Id);
                        }
                    } else if (Approval.isLocked(acc.Id)) {
                        recordsToUnlock.add(acc.Id);
                    }
                }
            }
            if (!recordsToLock.isEmpty() || !recordsToUnlock.isEmpty()) {
                Set<Id> recordIds = new Set<Id>();
                recordIds.addAll(recordsToLock);
                recordIds.addAll(recordsToUnlock);
                for (Account acc : (List<Account>) new AccountSelector()
                                    .selectAccountsWithContactsAndOpptys(new List<Object>{ recordIds })
                                    .executeQuery()) {
                    Map<Id, Contact> contacts = new Map<Id, Contact>(acc.Contacts);
                    Map<Id, Opportunity> opps = new Map<Id, Opportunity>(acc.Opportunities);
                    if (recordsToLock.contains(acc.Id)) {
                        recordsToLock.addAll(contacts.keySet());
                        recordsToLock.addAll(opps.keySet());
                    }
                    if (recordsToUnlock.contains(acc.Id)) {
                        recordsToUnlock.addAll(contacts.keySet());
                        recordsToUnlock.addAll(opps.keySet());
                    }
                }
            }

            //Lock the relevant records in case DPS is flagged
            if (!recordsToLock.isEmpty()) {
                AccountTriggerDPSHandler.LockRecordsonDPSFlag(recordsToLock);
            }
            //Unlock records if DPS has clelared the account
            if (!recordsToUnLock.isEmpty()) {
                AccountTriggerDPSHandler.UnlockRecordsonDPSClear(recordsToUnLock);
            }
        }
    }

    public class CustomerContactsForPaidAccounts extends Triggers.TriggerHandlerBase {
        override public void handle() {
            try {
                List<Customer_Contacts_Paid_Accounts__e> events = new List<Customer_Contacts_Paid_Accounts__e>();
                Set<Id> paidAccounts = new Set<Id>();
                Set<Id> cancelAccounts = new Set<Id>();
                for (Account acc : (List<Account>) Trigger.new) {
                    Account oldAcc = (Account) Trigger.oldMap.get(acc.Id);
                    if (acc.RC_Upgrade_Date__c != null && isChangedField(acc, Account.RC_Upgrade_Date__c)
                        || (acc.RC_Account_Status__c != null
                            && acc.RC_Account_Status__c.containsIgnoreCase('Paid')
                            && isChangedField(acc, Account.RC_Account_Status__c))) {

                        paidAccounts.add(acc.Id);
                    } else if (String.isNotBlank(acc.RC_Account_Status__c)
                                && acc.RC_Account_Status__c.startsWithIgnoreCase('cancel')
                                && (String.isBlank(oldAcc.RC_Account_Status__c) || !oldAcc.RC_Account_Status__c.startsWithIgnoreCase('cancel'))
                                || isChangedFieldFrom(acc, Account.RC_Churn_Date__c, null)) {

                        cancelAccounts.add(acc.Id);
                    }
                }

                String condition = '';
                String paidCondition = '(AccountId IN :paidAccounts AND Contact_Status__c != \'4. Customer\' AND Contact_Status__c != \'3. Working Opp\')';
                String cancelCondition = '(AccountId IN :cancelAccounts AND Contact_Status__c != \'0. Downgraded\' AND Contact_Status__c != \'3. Working Opp\')';
                if (!paidAccounts.isEmpty()) {
                    condition += paidCondition;
                }
                if (!cancelAccounts.isEmpty()) {
                    condition += String.isEmpty(condition) ? cancelCondition : ' OR ' + cancelCondition;
                }
                if (String.isEmpty(condition)) {
                    return;
                }

                Map<Id, String> accountsForBatch = new Map<Id, String>();
                String queryStr = 'SELECT AccountId, COUNT(Id) FROM Contact WHERE ' + condition + ' GROUP BY AccountId';
                for (AggregateResult ar : Database.query(queryStr)) {
                    //if number of contacts its bigger than 200 process in batch.
                    Id accId = (Id) ar.get('AccountId');
                    String processType = paidAccounts.contains(accId) ? 'Customer Contacts' : 'Cancel Accounts';
                    if ((Integer) ar.get('expr0') >= 200) {
                        accountsForBatch.put(accId, processType);
                    } else {
                        events.add(new Customer_Contacts_Paid_Accounts__e(
                            AccountId__c = accId,
                            Process_Type__c = processType
                        ));
                    }
                }

                if (!events.isEmpty()) {
                    PlatformEvents.publishPlatformEvent(events, 'AccountTriggerHandler');
                }

                Id accountsPaidAndCancelledRecordTypeId = Schema.SObjectType.Exception_And_Notification_History__c
                    .getRecordTypeInfosByName()
                    .get('Accounts Paid And Cancelled')?.getRecordTypeId();
                if (accountsForBatch.isEmpty() || accountsPaidAndCancelledRecordTypeId == null) {
                    return;
                }

                List<Exception_And_Notification_History__c> pendingAccounts = new List<Exception_And_Notification_History__c>();
                for (Id accId : accountsForBatch.keySet()) {
                    pendingAccounts.add(new Exception_And_Notification_History__c(
                        RecordTypeId = accountsPaidAndCancelledRecordTypeId,
                        Object_Type__c = accountsForBatch.get(accId),
                        Record_Id__c = accId
                    ));
                }
                insert pendingAccounts;
            } catch (Exception e) {
                ExceptionHelper.createExceptionAndNotificacionHistory(e, Trigger.new, 'DFR Exception Log');
            }
        }
    }

    public class CreateTaskUponNumberOfDLValueChanges extends Triggers.TriggerHandlerBase {
        override public void handle() {
            List<Task> tasks = new List<Task>();
            Account_Enterprise_Support_Uplift__c dlValues = Account_Enterprise_Support_Uplift__c.getInstance();
            if (dlValues == null || dlValues.No_of_DL_Field__c == null) {
                return;
            }

            for (Account newAccount : (List<Account>) Trigger.new) {
                Decimal newNumberOfDL = (Decimal) newAccount.get(dlValues.No_of_DL_Field__c);
                Decimal oldNumberOfDL = (Decimal) ((Account) Trigger.oldMap.get(newAccount.Id)).get(dlValues.No_of_DL_Field__c);
                if (dlValues.No_of_DL_Field__c != null && newNumberOfDL != null && oldNumberOfDL != null && oldNumberOfDL != newNumberOfDL) {
                    if ((oldNumberOfDL <= dlValues.Threshold_1__c && newNumberOfDL >= dlValues.Threshold_2__c)
                        || (oldNumberOfDL <= dlValues.Threshold_3__c && newNumberOfDL >= dlValues.Threshold_4__c)
                        || (oldNumberOfDL <= dlValues.Threshold_5__c && newNumberOfDL >= dlValues.Threshold_6__c)
                        || (oldNumberOfDL <= dlValues.Threshold_7__c && newNumberOfDL >= dlValues.Threshold_8__c)
                        || (oldNumberOfDL <= dlValues.Threshold_9__c && newNumberOfDL >= dlValues.Threshold_10__c)
                        || (oldNumberOfDL <= dlValues.Threshold_11__c && newNumberOfDL >= dlValues.Threshold_12__c)) {

                        Task tsk = new Task();
                        tsk.Subject = 'Notice of change in DL and corresponding change in Enterprise Support Tier for ' + newAccount.Name ;
                        tsk.Status = 'Open';
                        tsk.Priority = 'Normal';
                        tsk.WhatId = newAccount.Id;
                        tsk.OwnerId = newAccount.OwnerId;
                        tsk.ActivityDate = System.today();
                        tsk.IsReminderSet = true;
                        tsk.ReminderDateTime = System.now().addMinutes(1);
                        tasks.add(tsk);
                    }
                }
            }

            try {
                if (!tasks.isEmpty()) {
                    insert tasks;
                }
            } catch (DmlException e) {
                PlatformLog.logException('Error AccountTriggerHelper.CreateTaskUponNumberOfDLValueChanges', e);
            }
        }
    }

    public class partnerAccountsVisibility extends Triggers.TriggerHandlerBase {
        override public void handle() {
            List<Account> newAccounts = (List<Account>) Trigger.new;
            Id partnerAccountRTId = AccountHelper.RT_ID_PARTNER_ACCOUNT;
            Id customerAccountRTId = AccountHelper.RT_ID_CUSTOMER_ACCOUNT;
            List<AccountTeamMember> accTeamMembers = new List<AccountTeamMember>();

            if (Trigger.isInsert) {
                Set<Id> customerAccIds = new Set<Id>();
                for (Account acc : newAccounts) {
                    if (acc.RecordTypeId == partnerAccountRTId && acc.Inside_Sales_Rep__c != null) {
                        accTeamMembers.add(constructATMObj(acc.Id, acc.Inside_Sales_Rep__c));
                    } else if (acc.RecordTypeId == customerAccountRTId && acc.Partner_Account__c != null) {
                        customerAccIds.add(acc.Partner_Account__c);
                    }
                }

                if (!customerAccIds.isEmpty()) {
                    Map<Id, Account> partnerAccounts = new Map<Id, Account>((List<Account>) new AccountSelector()
                                                        .selectAccounts()
                                                        .selectFields(new List<String> { 'Id', 'Inside_Sales_Rep__c' })
                                                        .setCondition('Id IN :bind0 AND Inside_Sales_Rep__r.isActive = true')
                                                        .setQueryBindings(new List<Object>{ customerAccIds })
                                                        .executeQuery());
                    for (Account acc : newAccounts) {
                        if (acc.Partner_Account__c != null && partnerAccounts.containsKey(acc.Partner_Account__c)) {
                            Account partner = partnerAccounts.get(acc.Partner_Account__c);
                            accTeamMembers.add(constructATMObj(acc.Id, partner.Inside_Sales_Rep__c));
                        }
                    }
                }
            }

            if (Trigger.isUpdate) {
                Map<Id, Account> oldTriggerAccountsMap = (Map<Id, Account>) Trigger.oldMap;
                // Contains Ids of Partner Accounts in which channel manager is changed
                Set<Id> partnerAccountIds = new Set<Id>();
                Set<Id> customerAccountIds = new Set<Id>();
                Map<Id, Set<Id>> accountATM = new Map<Id, Set<Id>>();

                //contains previous ChannelManager in ATM
                List<AccountTeamMember> removeAccountTeamMember = new List<AccountTeamMember>();

                // If a customer account's Partner_Account__c field is updated OR if a partner account's Inside_Sales_Rep__c field is updated
                for (Account acc : newAccounts) {
                    if (acc.RecordTypeId == partnerAccountRTId && isChangedField(acc, Account.Inside_Sales_Rep__c)) {
                        partnerAccountIds.add(acc.Id);
                    } else if (acc.RecordTypeId == customerAccountRTId && isChangedField(acc, Account.Partner_Account__c)) {
                        customerAccountIds.add(acc.Id);
                    }
                }

                if (!partnerAccountIds.isEmpty()) {
                    for (Account acc : (List<Account>) new AccountSelector()
                                        .selectPartnerAccountsByIdsAndRT(new List<Object>{ partnerAccountIds })
                                        .executeQuery()) {
                        if (partnerAccountIds.contains(acc.Id) && AccountHelper.RT_NAME_PARTNER_ACCOUNT.equalsIgnoreCase(acc.RecordType.Name)) {
                            // adds the accountTeamMembers available in current partner account and to remove the previous channel manager
                            accountATM.put(acc.Id, new Set<Id>());
                            for (AccountTeamMember atm : acc.AccountTeamMembers) {
                                if (atm.TeamMemberRole == AccountTriggerHelper.TEAM_MEMBER_ROLE_ACCOUNT_MANAGER) {
                                    accountATM.get(acc.Id).add(atm.UserId);
                                    // add atm to be removed - previous channel manager
                                    if (atm.UserId == oldTriggerAccountsMap.get(acc.Id).Inside_Sales_Rep__c) {
                                        removeAccountTeamMember.add(atm);
                                    }
                                }
                            }

                            if (!(accountATM.get(acc.Id) != null
                                    && accountATM.get(acc.Id).contains(acc.Inside_Sales_Rep__c)
                                    || acc.Inside_Sales_Rep__c == null)
                                && acc.Inside_Sales_Rep__r.IsActive) {

                                accTeamMembers.add(constructATMObj(acc.Id, acc.Inside_Sales_Rep__c));
                            }
                        } else if (partnerAccountIds.contains(acc.Partner_Account__c)) {
                            // adds the accountTeamMembers available in current customer account
                            accountATM.put(acc.Id, new Set<Id>());
                            for (AccountTeamMember atm : acc.AccountTeamMembers) {
                                if (atm.TeamMemberRole == AccountTriggerHelper.TEAM_MEMBER_ROLE_ACCOUNT_MANAGER) {
                                    accountATM.get(acc.Id).add(atm.UserId);
                                    // Adds ATM to be removed - previous channel manager in partner account
                                    if (oldTriggerAccountsMap.get(acc.Partner_Account__c).Inside_Sales_Rep__c == atm.UserId) {
                                        removeAccountTeamMember.add(atm);
                                    }
                                }
                            }
                            // Check if the ATM is already available under customer account
                            if (!(acc.Partner_Account__r.Inside_Sales_Rep__c == null
                                    || accountATM.get(acc.Id) != null
                                    && accountATM.get(acc.Id).contains(acc.Partner_Account__r.Inside_Sales_Rep__c))) {

                                accTeamMembers.add(constructATMObj(acc.Id, acc.Partner_Account__r.Inside_Sales_Rep__c));
                            }
                        }
                    }
                }

                if (!customerAccountIds.isEmpty()) {
                    Set<Id> oldPartnerAccIds = new Set<Id>();
                    // Get the previous partner account of customer account
                    for (Account customerAcc : oldTriggerAccountsMap.values()) {
                        if (customerAccountIds.contains(customerAcc.Id) && customerAcc.Partner_Account__c != null) {
                            oldPartnerAccIds.add(customerAcc.Partner_Account__c);
                        }
                    }
                    Map<Id, Account> oldPartners = new Map<Id, Account>((List<Account>) new AccountSelector()
                                                    .selectAccounts()
                                                    .selectFields(new List<String>{ 'Id', 'Inside_Sales_Rep__c' })
                                                    .setCondition('Id IN :bind0 AND Inside_Sales_Rep__c != null')
                                                    .setQueryBindings(new List<Object>{ oldPartnerAccIds })
                                                    .executeQuery());

                    for (Account acc : (List<Account>) new AccountSelector()
                                        .selectAccounts()
                                        .selectFields(new List<String>{
                                            'Id', 'Partner_Account__c', 'Partner_Account__r.Inside_Sales_Rep__c',
                                            'Partner_Account__r.Inside_Sales_Rep__r.IsActive'
                                        })
                                        .subselect(new AccountTeamMemberSelector()
                                                    .selectAccountTeamMembers())
                                        .setCondition('Id IN :bind0')
                                        .setQueryBindings(new List<Object>{ customerAccountIds })
                                        .executeQuery()) {
                        // adds the accountTeamMembers available in current customer account
                        accountATM.put(acc.Id, new Set<Id>());
                        for (AccountTeamMember atm : acc.AccountTeamMembers) {
                            if (atm.TeamMemberRole == AccountTriggerHelper.TEAM_MEMBER_ROLE_ACCOUNT_MANAGER) {
                                accountATM.get(acc.Id).add(atm.UserId);
                                // Adds ATM to be removed - previous channel manager in partner account
                                Id oldPartnerAccId = oldTriggerAccountsMap.get(acc.Id).Partner_Account__c;
                                if (oldPartnerAccId != null && oldPartners.get(oldPartnerAccId).Inside_Sales_Rep__c == atm.UserId) {
                                    removeAccountTeamMember.add(atm);
                                }
                            }
                        }
                        // Check if the ATM is already available under customer account
                        if (!(acc.Partner_Account__c == null || (accountATM.get(acc.Id) != null && accountATM.get(acc.Id).contains(acc.Partner_Account__r.Inside_Sales_Rep__c)))
                            && acc.Partner_Account__r.Inside_Sales_Rep__r.IsActive) {
                            accTeamMembers.add(constructATMObj(acc.Id, acc.Partner_Account__r.Inside_Sales_Rep__c));
                        }
                    }
                }

                if (!removeAccountTeamMember.isEmpty()) {
                    delete removeAccountTeamMember;
                }
            }

            if (!accTeamMembers.isEmpty()) {
                insert accTeamMembers;
            }
        }

        private AccountTeamMember constructATMObj(Id accountId, Id userId) {
            AccountTeamMember newATM = new AccountTeamMember();
            newATM.AccountId = accountId;
            newATM.UserId = userId;
            newATM.AccountAccessLevel = 'Edit';
            newATM.CaseAccessLevel = 'Edit';
            newATM.ContactAccessLevel = 'Edit';
            newATM.OpportunityAccessLevel = 'Edit';
            newATM.TeamMemberRole = AccountTriggerHelper.TEAM_MEMBER_ROLE_ACCOUNT_MANAGER;
            return newATM;
        }
    }

    public class CopyServiceDetailsToBillingAccountPackage extends Triggers.TriggerHandlerBase {
        private Set<Schema.SObjectField> ACCOUNT_FIELDS_SERVICE_INFO = new Set<SObjectField>{
            Account.Account_Payment_Method__c,
            Account.RC_Account_Status__c,
            Account.RC_Service_name__c,
            Account.Service_Version__c,
            Account.Total_Account_DL_s__c,
            Account.Provision_Date__c,
            Account.inContact_account_ID__c,
            Account.InContact_Service__c,
            Account.Bill_As_Of_Date__c
        };

        override public void handle() {

            Set<Id> accountIds = new Set<Id>();
            for (Account acc : (List<Account>) Trigger.new) {
                if (!isChangedAnyField(acc, ACCOUNT_FIELDS_SERVICE_INFO)) {
                    continue;
                }
                accountIds.add(acc.Id);
            }

            if (accountIds.isEmpty()) {
                return;
            }

            serviceInfoAccountListStatic = new AccountSelector()
                                    .selectAccountsByIdsWithBillingAccountPackagesServiceInfo(accountIds)
                                    .executeQuery();

            if (serviceInfoAccountListStatic.isEmpty()) {
                return;
            }

            List<Package__c> recordsToUpdate = new List<Package__c>();
            for (Account acc : serviceInfoAccountListStatic) {
                for (Package__c bap : acc.Service_Accounts1__r) {
                    Package__c updatedPackage = new Package__c(Id = bap.Id);
                    Boolean isUpdated = false;

                    for (SObjectField field : ACCOUNT_FIELDS_SERVICE_INFO) {
                        if (!isChangedField(acc, field)) {
                            continue;
                        }

                        String fieldName = field.getDescribe().getName();
                        Object fieldValue = acc.get(fieldName);

                        if (field.getDescribe().isUpdateable()) {
                            if (bap.get(fieldName) != fieldValue) {
                                updatedPackage.put(fieldName, fieldValue);
                                isUpdated = true;
                            }
                        }
                    }

                    if (isUpdated) {
                        recordsToUpdate.add(updatedPackage);
                    }
                }
            }

            if (!recordsToUpdate.isEmpty()) {
                Triggers.switchOff();
                update recordsToUpdate;
                Triggers.switchOn();
            }
        }
    }

    public class CopyContactCenterServiceFieldsToMasterAccount extends Triggers.TriggerHandlerBase {
        private Set<Schema.SObjectField> CC_ACCOUNT_FIELDS_SERVICE_INFO = new Set<SObjectField>{
            Account.Provision_Date__c,
            Account.InContact_Service__c,
            Account.Bill_As_Of_Date__c
        };

        override public void handle() {
            if (System.isBatch() || System.isFuture()) {
                return;
            }
            Set<Account> accountsToProcess = new Set<Account>();
            for (Account acc : (List<Account>) Trigger.new) {
                if (!isChangedAnyField(acc, CC_ACCOUNT_FIELDS_SERVICE_INFO)) {
                    continue;
                }
                accountsToProcess.add(acc);
            }

            if (accountsToProcess.isEmpty()) {
                return;
            }

            Map<Id, Account> masterAccountsMap = new Map<Id, Account>();

            for (Account account : serviceInfoAccountListStatic) {
                for (Account techAcc : accountsToProcess) {
                    if (account.Id != techAcc.Id) {
                        continue;
                    }

                    if (!account.IsMultiProductTechnicalAccount__c) {
                        continue;
                    }

                    if (masterAccountsMap.get(account.Master_Account__c) != null) {
                        continue;
                    }

                    masterAccountsMap.put(
                        account.Master_Account__c,
                        new Account(
                            Id = account.Master_Account__c,
                            Provision_Date__c = techAcc.Provision_Date__c,
                            InContact_Service__c = techAcc.InContact_Service__c,
                            Bill_As_Of_Date__c = techAcc.Bill_As_Of_Date__c
                        )
                    );
                }
            }

            if (!masterAccountsMap.values().isEmpty()) {
                Triggers.switchOff();
                update masterAccountsMap.values();
                Triggers.switchOn();
            }
        }
    }

    public class UpdateServiceMRRFieldsOnMasterAccount extends Triggers.TriggerHandlerBase {
        Set<SObjectField> FIELDS_AGGREGATED_TOTALS = new Set<SObjectField> {
            Account.CombinedMVPCurrentTotalMRR__c,
            Account.CombinedMVPAcquisitionMRR__c,
            Account.CombinedCCAcquisitionMRR__c,
            Account.inContactARPU__c,
            Account.CombinedEngageDigitalMRR__c,
            Account.CombinedEDAcquisitionMRR__c,
            Account.CombinedNumberOfEngageDigitalUsers__c,
            Account.EngageDigitalARPU__c,
            Account.CombinedEngageVoiceMRR__c,
            Account.CombinedEVAcquisitionMRR__c,
            Account.CombinedNumberOfEngageVoiceSeats__c,
            Account.EngageVoiceARPU__c,
            Account.CombinedEventsMRR__c,
            Account.CombinedEventsAcquisitionMRR__c,
            Account.CombinedNumberofEventsUsers__c,
            Account.EventsARPU__c
        };

        override public void handle() {
            if (System.isBatch() || System.isFuture()) {
                return;
            }
            List<Id> accountIds = new List<Id>();
            for (Account acc : (List<Account>) Trigger.new) {
                if (acc.Master_Account__c == null
                    || !isChangedAnyField(acc, FIELDS_AGGREGATED_TOTALS)) {
                    continue;
                }
                accountIds.add(acc.Master_Account__c);
            }

            if (accountIds.isEmpty()) {
                return;
            }

            processMasterAccounts(accountIds);
        }
    }

    @future
    private static void processMasterAccounts(List<Id> accountIds) {

        List<Account> accounts = new List<Account>();
        accounts = new AccountSelector()
                    .selectAccountsByIdsWithTechnicalAccounts(accountIds)
                    .executeQuery();
        List<Package__c> packages = new PackageSelector()
            .selectPackagesForAccountUpdateByAccountIds(accountIds)
            .executeQuery();

        List<Account> recordsToUpdate = new List<Account>();
        for (Account masterAccount : accounts) {
            Account updatedAccount = new Account(Id = masterAccount.Id);

            Boolean isUpdated = false;

            Decimal ccAcquisitionTotal = null;
            Decimal ccARPU = null;

            Decimal edCurrentTotal = null;
            Decimal edAcquisitionTotal = null;
            Decimal edNumOfMainLicenses = null;
            Decimal edARPU = null;

            Decimal evCurrentTotal = null;
            Decimal evAcquisitionTotal = null;
            Decimal evNumOfMainLicenses = null;
            Decimal evARPU = null;

            Decimal eventCurrentTotal = null;
            Decimal eventAcquisitionTotal = null;
            Decimal eventNumOfMainLicenses = null;
            Decimal eventARPU = null;

            for (Package__c pkg : packages) {
                if (pkg.Account__c != masterAccount.Id) {
                    continue;
                }
                if (pkg.NumberOfEngageDigitalUsers__c != null) {
                    edNumOfMainLicenses = (Decimal) NumberHelper.getNumberNullSafe(edNumOfMainLicenses) + pkg.NumberOfEngageDigitalUsers__c;
                }
                if (pkg.NumberOfEngageVoiceSeats__c != null) {
                    evNumOfMainLicenses = (Decimal) NumberHelper.getNumberNullSafe(evNumOfMainLicenses) + pkg.NumberOfEngageVoiceSeats__c;
                }
                if (pkg.EDAcquisitionMRR__c != null) {
                    edAcquisitionTotal = (Decimal) NumberHelper.getNumberNullSafe(edAcquisitionTotal) + pkg.EDAcquisitionMRR__c;
                }
                if (pkg.EVAcquisitionMRR__c != null) {
                    evAcquisitionTotal = (Decimal) NumberHelper.getNumberNullSafe(evAcquisitionTotal) + pkg.EVAcquisitionMRR__c;
                }
                if (pkg.CCAcquisitionMRR__c != null) {
                    ccAcquisitionTotal = (Decimal) NumberHelper.getNumberNullSafe(ccAcquisitionTotal) + pkg.CCAcquisitionMRR__c;
                }
                if (pkg.EngageVoiceMRR__c != null) {
                    evCurrentTotal = (Decimal) NumberHelper.getNumberNullSafe(evCurrentTotal) + pkg.EngageVoiceMRR__c;
                }
                if (pkg.EngageDigitalMRR__c != null) {
                    edCurrentTotal = (Decimal) NumberHelper.getNumberNullSafe(edCurrentTotal) + pkg.EngageDigitalMRR__c;
                }
                if (pkg.Number_of_Events_Users__c != null) {
                    eventNumOfMainLicenses = (Decimal) NumberHelper.getNumberNullSafe(eventNumOfMainLicenses) + pkg.Number_of_Events_Users__c;
                }
                if (pkg.Events_MRR__c != null) {
                    eventCurrentTotal = (Decimal) NumberHelper.getNumberNullSafe(eventCurrentTotal) + pkg.Events_MRR__c;
                }
                if (pkg.Events_Acquisition_MRR__c != null) {
                    eventAcquisitionTotal = (Decimal) NumberHelper.getNumberNullSafe(eventAcquisitionTotal) + pkg.Events_Acquisition_MRR__c;
                }
            }

            for (Account technicalAccount: masterAccount.Master_Accounts__r) {
                if (technicalAccount.inContactARPU__c != null) {
                    ccARPU = (Decimal) NumberHelper.getNumberNullSafe(ccARPU) + technicalAccount.inContactARPU__c;
                }
                if (technicalAccount.EngageDigitalARPU__c != null) {
                    edARPU = (Decimal) NumberHelper.getNumberNullSafe(edARPU) + technicalAccount.EngageDigitalARPU__c;
                }
                if (technicalAccount.EngageVoiceARPU__c != null) {
                    evARPU = (Decimal) NumberHelper.getNumberNullSafe(evARPU) + technicalAccount.EngageVoiceARPU__c;
                }
                if (technicalAccount.EventsARPU__c != null) {
                    eventARPU = (Decimal) NumberHelper.getNumberNullSafe(eventARPU) + technicalAccount.EventsARPU__c;
                }
            }
            if (ccAcquisitionTotal != null) {
                updatedAccount.CombinedCCAcquisitionMRR__c = ccAcquisitionTotal;

                isUpdated = true;
            }
            if (ccARPU != null) {
                updatedAccount.inContactARPU__c = ccARPU;

                isUpdated = true;
            }
            if (edCurrentTotal != null) {
                updatedAccount.CombinedEngageDigitalMRR__c = edCurrentTotal;

                isUpdated = true;
            }
            if (edAcquisitionTotal != null) {
                updatedAccount.CombinedEDAcquisitionMRR__c = edAcquisitionTotal;

                isUpdated = true;
            }
            if (edNumOfMainLicenses != null) {
                updatedAccount.CombinedNumberOfEngageDigitalUsers__c = edNumOfMainLicenses;

                isUpdated = true;
            }
            if (edARPU != null) {
                updatedAccount.EngageDigitalARPU__c = edARPU;

                isUpdated = true;
            }
            if (evCurrentTotal != null) {
                updatedAccount.CombinedEngageVoiceMRR__c = evCurrentTotal;

                isUpdated = true;
            }
            if (evAcquisitionTotal != null) {
                updatedAccount.CombinedEVAcquisitionMRR__c = evAcquisitionTotal;

                isUpdated = true;
            }
            if (evNumOfMainLicenses != null) {
                updatedAccount.CombinedNumberOfEngageVoiceSeats__c = evNumOfMainLicenses;

                isUpdated = true;
            }
            if (evARPU != null) {
                updatedAccount.EngageVoiceARPU__c = evARPU;

                isUpdated = true;
            }

            if (eventCurrentTotal != null) {
                updatedAccount.CombinedEventsMRR__c = eventCurrentTotal;

                isUpdated = true;
            }
            if (eventAcquisitionTotal != null) {
                updatedAccount.CombinedEventsAcquisitionMRR__c = eventAcquisitionTotal;

                isUpdated = true;
            }
            if (eventNumOfMainLicenses != null) {
                updatedAccount.CombinedNumberofEventsUsers__c = eventNumOfMainLicenses;

                isUpdated = true;
            }
            if (eventARPU != null) {
                updatedAccount.EventsARPU__c = eventARPU;

                isUpdated = true;
            }

            if (isUpdated) {
                recordsToUpdate.add(updatedAccount);
            }
        }

        if (!recordsToUpdate.isEmpty()) {
            update recordsToUpdate;
        }
    }

    public class UpdateReportedMRSOnPackage extends Triggers.TriggerHandlerBase {
        Set<SObjectField> ACCOUNT_FIELDS_MVP_DEPENDANTS = new Set<SObjectField>{
            Account.CombinedEngageDigitalMRR__c,
            Account.CombinedEngageVoiceMRR__c
        };

        override public void handle() {

            List<Id> accountIds = new List<Id>();
            List<Package__c> packages = new PackageSelector()
                .selectPackagesForNewReferences(new List<Object> {Trigger.newMap.keySet()})
                .setQueryCaching(true)
                .executeQuery();

            Map<Id, Package__c> accountToPackagesMap = new Map<Id, Package__c>();
            for (Package__c pkg : packages) {
                accountToPackagesMap.put(pkg.Enterprise_Account_ID__c, pkg);
            }
            for (Account acc : (List<Account>) Trigger.new) {
                Package__c pkgToCheck = accountToPackagesMap.get(acc.Id);
                if (!isChangedAnyField(acc, ACCOUNT_FIELDS_MVP_DEPENDANTS)
                    || pkgToCheck != null && pkgToCheck?.Service_Type__c != QuoteHelper.NGBS_OFFICE_PRODUCT) {
                    continue;
                }
                accountIds.add(acc.Id);
            }

            if (accountIds.isEmpty()) {
                return;
            }

            List<Account> accountsList = new List<Account>();
            accountsList = new AccountSelector()
                            .selectAccountsByIdsWithBillingAccountPackagesReportedMRSDependants(accountIds)
                            .executeQuery();

            List<Package__c> recordsToUpdate = new List<Package__c>();
            for (Account account : accountsList) {
                for (Package__c bap : account.Service_Accounts1__r) {
                    Decimal reportedMRS = PackageHelper.getReportedMRS(bap, account);
                    if (reportedMRS != null) {
                        if (bap.Reported_MRS__c != reportedMRS) {
                            bap.Reported_MRS__c = reportedMRS;
                            recordsToUpdate.add(bap);
                        }
                    }
                }
            }

            if (!recordsToUpdate.isEmpty()) {
                Triggers.switchOff();
                update recordsToUpdate;
                Triggers.switchOn();
            }
        }
    }

    public class CopyFieldsToTechnicalAccounts extends Triggers.TriggerHandlerBase {
        Set<SObjectField> ACCOUNT_FIELDS_TO_COPY = new Set<SObjectField>{
            Account.RC_User_ID__c,
            Account.BillingPostalCode,
            Account.BillingCountry,
            Account.BillingState,
            Account.BillingCity,
            Account.BillingStreet,
            Account.VATNumber__c,
            Account.Tax_Exempt__c
        };

        override public void handle() {
            System.debug('CopyBillingAddressToTechnicalAccounts ' + Trigger.new.size());

            List<Account> accountsList = new List<Account>();
            for (Account acc : (List<Account>) Trigger.new) {
                if (acc.IsMultiProductTechnicalAccount__c) {
                    continue;
                }

                if (!isChangedAnyField(acc, ACCOUNT_FIELDS_TO_COPY)) {
                    continue;
                }

                accountsList.add(acc);
            }

            if (accountsList.isEmpty()) {
                return;
            }

            List<Id> accountIds = (List<Id>) AquivaHelper.collectFieldValues(List<Id>.class, accountsList, 'Id', true);

            accountsList = new AccountSelector()
                .selectMPTechAccountsByMasterIdsForCopying(accountIds)
                .executeQuery();

            if (accountsList.isEmpty()) {
                return;
            }

            List<Account> recordsToUpdate = new List<Account>();
            for (Account acc : accountsList) {
                Account masterAccount = acc.Master_Account__r;
                Account updatedAccount = new Account(
                    Id = acc.Id,
                    BillingPostalCode = masterAccount.BillingPostalCode,
                    BillingCountry = masterAccount.BillingCountry,
                    BillingState = masterAccount.BillingState,
                    BillingCity = masterAccount.BillingCity,
                    BillingStreet = masterAccount.BillingStreet,
                    EnterpriseCustomerID__c = masterAccount.RC_User_ID__c,
                    VATNumber__c = masterAccount.VATNumber__c,
                    Tax_Exempt__c = masterAccount.Tax_Exempt__c
                );

                recordsToUpdate.add(updatedAccount);
            }

            if (!recordsToUpdate.isEmpty()) {
                Triggers.switchOff();
                update recordsToUpdate;
                Triggers.switchOn();
            }
        }
    }

    public class ActivateNewestOrders extends Triggers.TriggerHandlerBase {
        override public void handle() {
            Set<Id> accIds = new Set<Id>();
            // Check accounts status changed
            for (Account acc : (List<Account>) Trigger.new) {
                if (isChangedFieldTo(acc, Account.RC_Account_Status__c, AccountHelper.PAID_STATUS)) {
                    accIds.add(acc.Id);
                }
            }

            if (accIds.isEmpty()) {
                return;
            }

            List<Quote> quotesForAccounts = (List<Quote>) new QuoteSelector()
                .selectQuotesForOrderActivationProcess(new List<Object>{accIds})
                .executeQuery();

            List<Order> ordersToUpdate = new List<Order>();
            for (Quote quote : quotesForAccounts) {
                if (quote.Orders3__r.isEmpty() || !quote.ServiceInfo__r.isEmpty()) {
                    continue;
                }

                Order orderToActivate = (Order) quote.Orders3__r.get(0);
                ordersToUpdate.add(new Order(
                    Id = orderToActivate.Id,
                    Status = OrderHelper.STATUS_ACTIVATED
                ));
            }
            if (!ordersToUpdate.isEmpty()) {
                update ordersToUpdate;
            }
        }
    }

    public class CreateOrderAfterSignUpComplete extends Triggers.TriggerHandlerBase {
        override public void handle() {
            Set<Id> accountIds = new Set<Id>();

            for (Account acc : (List<Account>) Trigger.new) {
                if (!isChangedFieldToNonNull(acc, Account.Billing_ID__c) || !isChangedFieldToNonNull(acc, Account.RC_User_ID__c)) {
                    continue;
                }

                if (!acc.IsMultiProductTechnicalAccount__c && AccountHelper.isMPUBAccount(acc.Id, OpportunityTriggerHelperRefactored.accountMapStatic.get(acc.Id)?.Master_Accounts__r)) {
                    continue;
                }

                accountIds.add(acc.Id);
            }

            if (accountIds.isEmpty()) {
                return;
            }

            List<Quote> quotes = (List<Quote>) new QuoteSelector()
                .newQueryFactory()
                .selectFields(
                    new List<String>{
                        'Id',
                        'Name',
                        'AccountId',
                        'Account.IsMultiProductTechnicalAccount__c',
                        'OpportunityId',
                        'Opportunity.Tier_Name__c',
                        'CurrencyIsoCode',
                        'BillingPackage__c',
                        'MasterQuote__c',
                        'MasterQuote__r.AccountId',
                        'MasterQuote__r.OpportunityId',
                        'ServiceName__c',
                        'IsMultiProductTechnicalQuote__c',
                        'Package_Info__c',
                        'IsPrimary__c'
                    }
                )
                .subselect(
                    new QuoteSelector('Master_Quotes__r', Quote.SObjectType)
                        .newQueryFactory()
                        .selectFields(new List<String>{
                            'Id',
                            'Name',
                            'AccountId',
                            'OpportunityId',
                            'Opportunity.Tier_Name__c',
                            'CurrencyIsoCode',
                            'ServiceName__c',
                            'IsMultiProductTechnicalQuote__c',
                            'MasterQuote__c',
                            'MasterQuote__r.AccountId',
                            'MasterQuote__r.OpportunityId',
                            'Package_Info__c',
                            'IsPrimary__c'
                        })
                )
                .subselect(
                    new QuoteLineItemSelector('QuoteLineItems', Quote.SObjectType)
                        .newQueryFactory()
                        .selectFields(new List<String>{
                            'Id',
                            'Product2Id',
                            'Product2.Product_Type__c',
                            'Quantity',
                            'NewQuantity__c',
                            'QuoteId',
                            'UnitPrice',
                            'TotalPrice',
                            'ChargeTerm__c',
                            'Product_Lic_Id__c',
                            'TotalSummary__c'
                        })
                )
                .subselect(
                    new ServiceInfoSelector('ServiceInfo__r', Quote.SObjectType)
                        .newQueryFactory()
                        .selectFields(new List<String>{
                            'Id'
                        })
                )
                .setCondition('AccountId IN :bind0')
                .setQueryBindings(new List<Object>{accountIds})
                .executeQuery();

            if (quotes.isEmpty()) {
                return;
            }

            List<Quote> quotesToProcess = new List<Quote>();
            for (Quote qt: quotes) {
                if (qt.ServiceInfo__r.isEmpty()) {
                    quotesToProcess.add(qt);
                }
            }

            Map<Id, List<QuoteLineItem>> quoteLineItemsByQuoteIds = new Map<Id, List<QuoteLineItem>>();
            for (Quote qt : quotes) {
                quoteLineItemsByQuoteIds.put(qt.Id, qt.QuoteLineItems);
            }

            OrderHelper.QuoteOrdersFactory quoteOrdersFactory = new OrderHelper.QuoteOrdersFactory(quotesToProcess, false, false);
            Map<Id, List<Order>> quoteOrdersMap = quoteOrdersFactory.buildOrdersForQuotes();

            List<Order> ordersToInsert = new List<Order>();
            for (Quote qt : quotes) {
                if (!quoteOrdersMap.containsKey(qt.Id)) {
                    continue;
                }

                ordersToInsert.addAll(quoteOrdersMap.get(qt.Id));
            }

            if (!ordersToInsert.isEmpty()) {
                insert ordersToInsert;
            }
        }
    }

    public class CopyAccountContactRolesToTechnicalAccounts extends Triggers.TriggerHandlerBase {
        override public void handle() {
            List<Account> accounts = new List<Account>();
            for (Account acc : (List<Account>) Trigger.new) {
                if (acc.IsMultiProductTechnicalAccount__c && isChangedFieldToNonNull(acc, Account.Master_Account__c)) {
                    accounts.add(acc);
                }
            }

            List<Id> accountIds = (List<Id>) AquivaHelper.collectFieldValues(List<Id>.class, accounts, 'Master_Account__c', true);

            if (accountIds.isEmpty()) {
                return;
            }

            List<AccountContactRole> acrs = new AccountContactRoleSelector()
                .selectAccountContactRolesWithNonEmptyRoleByAccountIds(accountIds)
                .executeQuery();
            Map<Id, AccountContactRole[]> acrsByAccountIdMap = (Map<Id, AccountContactRole[]>) AquivaHelper.groupByIdField(List<AccountContactRole>.class, acrs, 'AccountId');

            List<AccountContactRole> acrsToInsert = new List<AccountContactRole>();
            for (Account acc : accounts) {
                if (!acrsByAccountIdMap.containsKey(acc.Master_Account__c)) {
                    continue;
                }

                for (AccountContactRole acr : acrsByAccountIdMap.get(acc.Master_Account__c)) {
                    AccountContactRole clonedACR = acr.clone(false, true, false, false);
                    clonedACR.AccountId = acc.Id;

                    acrsToInsert.add(clonedACR);
                }
            }

            if (!acrsToInsert.isEmpty()) {
                insert acrsToInsert;
            }
        }
    }

    public class RejectCreditLimitApporvals extends Triggers.TriggerHandlerBase {
        override public void handle() {
            Set<Id> accIds = new Set<Id>();
            for (Account acc : (List<Account>) Trigger.new) {
                Account oldAccount = (Account) Trigger.oldMap.get(acc.Id);
                if (acc.RC_User_ID__c != null &&
                    acc.Billing_ID__c != null &&
                    acc.Account_Payment_Method__c != null &&
                    oldAccount.Account_Payment_Method__c != null &&
                    AccountHelper.isCreditCardAccount(oldAccount) &&
                    !AccountHelper.isCreditCardAccount(acc) &&
                    isChangedField(acc, Account.Account_Payment_Method__c) &&
                    oldAccount.Account_Payment_Method__c != acc.Account_Payment_Method__c
                ) {
                    accIds.add(acc.Id);
                }
            }
            if (!accIds.isEmpty()) {
                List<Approval__c> approvalsForReject = new List<Approval__c>();
                approvalsForReject = new ApprovalSelector()
                    .selectCreditLimitIncreaseByAccountIdByStatus(new List<Object>{accIds, new Set<String>{ApprovalHelper.STATUS_PENDING_APPROVAL}})
                    .executeQuery();
                if (!approvalsForReject.isEmpty()) {
                    ApprovalHelper.processApprovalRequest(new Map<Id, Approval__c>(approvalsForReject).keySet(), 'Payment method has been changed after approval was submitted', 'Reject');
                }
            }
        }
    }

    // PBC-13962 - Always Retain Renewals Manager Account Team Member when owner is changed
    public class RetainTeamMemberOnOwnerChange extends Triggers.TriggerHandlerBase {
        override public void handle() {
            Set<Account> updateAccounts = new Set<Account>();

            for (Account acc : (List<Account>) Trigger.new){
                if(isChangedField(acc, Account.OwnerId)){
                    updateAccounts.add(acc);
                }
            }
            List<AccountTeamMember> listAcc = (List<AccountTeamMember>) new AccountTeamMemberSelector()
                .selectAccountTeamMemberByAccountIdAndRole(new List<Object>{updateAccounts, 'Renewals Manager'})
                .executeQuery();
            if (!listAcc.isEmpty()) {
                QueueableDMLExecuter.enqueueJob(
                    listAcc.deepClone(), QueueableDMLExecuter.DMLType.DML_INSERT);
            }
        }
    }

    public class CopyFieldsToMasterAccount extends Triggers.TriggerHandlerBase {
        Set<SObjectField> ACCOUNT_FIELDS_TO_COPY = new Set<SObjectField>{
            Account.EV_Account_ID__c,
            Account.EV_Platform__c,
            Account.EV_Shard__c,
            Account.ED_Account_ID__c,
            Account.ED_Platform__c,
            Account.Engage_Domain__c
        };

        override public void handle() {
            List<Id> masterAccountIds = new List<Id>();
            Map<Id, Account> masterAccountsMapForUpdate = new Map<Id, Account>();
            for (Account acc : (List<Account>) Trigger.new) {
                if (acc.IsMultiProductTechnicalAccount__c && isChangedAnyField(acc, ACCOUNT_FIELDS_TO_COPY)) {
                    masterAccountIds.add(acc.Master_Account__c);
                }
            }

            if (!masterAccountIds.isEmpty()) {
                masterAccountsMapForUpdate = new Map<Id, Account>((List<Account>) new AccountSelector()
                    .selectAccountsByIds(new List<Object>{ masterAccountIds })
                    .executeQuery());
            }

            for (Account techAcc : (List<Account>) Trigger.new) {
                if (techAcc.Master_Account__c == null
                    || !masterAccountsMapForUpdate.containsKey(techAcc.Master_Account__c)
                ) {
                    continue;
                }
                copyTechFieldsToMasterAccount(techAcc, masterAccountsMapForUpdate);
            }

            Triggers.switchOff();
            update masterAccountsMapForUpdate.values();
            Triggers.switchOn();
        }

        private void copyTechFieldsToMasterAccount(Account techAcc, Map<Id, Account> masterAccountsMapForUpdate) {
            Account updatedMasterAccount = masterAccountsMapForUpdate.get(techAcc.Master_Account__c);
            for (SObjectField field : ACCOUNT_FIELDS_TO_COPY) {
                if (techAcc.get(field) != null) {
                    updatedMasterAccount.put(field, techAcc.get(field));
                }
            }
            masterAccountsMapForUpdate.put(updatedMasterAccount.Id, updatedMasterAccount);
        }
    }
    //Sharing recalculate for Access Controls
	public class accessControls extends Triggers.TriggerHandlerBase {
        List<AccountShare> listAccShareInsert = new List<AccountShare>();
        List<AccountShare> listExistingShare = new List<AccountShare>();
        List<AccountShare> listSharingToDelete = new List<AccountShare>();
        Map<Id, Id> mapAccToGroup = new Map<Id, Id>();
        Set<Id> accIdsShareDelete = new Set<Id>();
        Set<Id> accountIds = new Set<Id>();
        SettingsService.AccessControlSettingsWrapper accessSettings = new SettingsService.AccessControlSettingsWrapper();
        Map<String, AccessControlSettings__c> mapBrandSetting = new Map<String, AccessControlSettings__c>();
        Map<String, AccessControlSettings__c> mapBISetting = new Map<String, AccessControlSettings__c>();
        Map<String, AccessControlSettings__c> mapPIDSetting = new Map<String, AccessControlSettings__c>(); /*Access Controls Revamp*/
        Set<String> allBrands = new Set<String>();
        Map<String, Id> mapGroups = new Map<String, Id>();
        /*Access Controls Revamp*/
        Set<String> otherBrands = new Set<String>();
        Set<String> otherBIs = new Set<String>();
        String nonGSPGroup = '';
        Set<String> allPartnerIds = new Set<String>();
        /*Access Controls Revamp*/

        override public void handle() {
            if (accessSettings.allGroups != null) {
                        mapGroups = accessSettings.getMapOfGroups(accessSettings.allGroups);
            }
            //Iterate over Accounts and get Map of Account Id to Groups to be shared to
            for (Account acc : (List<Account>) Trigger.new) {
                String groupName = '';
                if (isChangedField(acc, Account.Sub_Brand__c) || isChangedField(acc, Account.RC_Brand__c) || isChangedField(acc, Account.BusinessIdentity__c) || isChangedField(acc, Account.OwnerId) || isChangedField(acc, Account.Partner_ID__c)) {
                    if (accessSettings.mapBrandSetting != null && accessSettings.mapBISetting != null && accessSettings.mapBISetting != null) {
                        mapBrandSetting = accessSettings.mapBrandSetting;
                        mapBISetting = accessSettings.mapBISetting;
                        allBrands = accessSettings.allBrands;
                        /*Access Controls Revamp*/
                        otherBrands = accessSettings.otherBrands;
                        nonGSPGroup = accessSettings.nonGSPGroup;
                        otherBIs = accessSettings.otherBIs;
                        allPartnerIds = accessSettings.allPartnerIds;
                        /*Access Controls Revamp*/
                    }
                    /*Access Controls Revamp*/                
                    if ((acc.Sub_Brand__c == null || !otherBrands.contains(acc.Sub_Brand__c))
                        && (acc.BusinessIdentity__c == null || !otherBIs.contains(acc.BusinessIdentity__c))
                        && (acc.RC_Brand__c == null || !otherBrands.contains(acc.RC_Brand__c))
                        && !allPartnerIds.contains(acc.Partner_ID__c)) {
                            accIdsShareDelete.add(acc.Id);
                            mapAccToGroup.put(acc.Id, mapGroups.get(nonGSPGroup));
                        	continue;
                    } 
                    /*Access Controls Revamp*/
                   
                    if (mapBrandSetting != null && mapBISetting != null && mapGroups != null) { /*Access Controls Revamp*/
                        /*Access Controls Revamp*/
                        if ((acc.RC_Brand__c != null && !mapBrandSetting.containsKey(acc.RC_Brand__c)) 
                            || (acc.Sub_Brand__c != null && !mapBrandSetting.containsKey(acc.Sub_Brand__c))
                            || (acc.BusinessIdentity__c != null && !mapBISetting.containsKey(acc.BusinessIdentity__c))){
                                if (Trigger.isUpdate) {
                                    accIdsShareDelete.add(acc.Id);
                                }
                        }
                        /*Access Controls Revamp*/
                        if (acc.Sub_Brand__c != null && mapBrandSetting.containsKey(acc.Sub_Brand__c)) { //Sub brand not empty and for AccessControls
                            groupName = mapBrandSetting.get(acc.Sub_Brand__c).Public_Group_Name__c;
                            mapAccToGroup.put(acc.Id, mapGroups.get(groupName));
                            accIdsShareDelete.add(acc.Id);
                            continue;
                        } else if (acc.BusinessIdentity__c != null && mapBISetting.containsKey(acc.BusinessIdentity__c)) { //Business identity not empty and for AccessControls
                            groupName = mapBISetting.get(acc.BusinessIdentity__c).Public_Group_Name__c;
                            mapAccToGroup.put(acc.Id, mapGroups.get(groupName));
                            accIdsShareDelete.add(acc.Id);
                            continue;
                        } else if (acc.RC_Brand__c != null && allBrands.contains(acc.RC_Brand__c) && mapBrandSetting.containsKey(acc.RC_Brand__c)) { //Brand is not null and for AccessControls
                            groupName = mapBrandSetting.get(acc.RC_Brand__c).Public_Group_Name__c;
                            mapAccToGroup.put(acc.Id, mapGroups.get(groupName));
                            accIdsShareDelete.add(acc.Id);
                            continue;
                        }
                    } 
                }
            }
            if (!accIdsShareDelete.isEmpty() && mapGroups.isEmpty() && accessSettings.allGroups != null) {
                mapGroups = accessSettings.getMapOfGroups(accessSettings.allGroups);
            }
            if (!accIdsShareDelete.isEmpty() && mapGroups != null) {
                listExistingShare = [SELECT Id, AccountId, UserOrGroupId, AccountAccessLevel,
                                        OpportunityAccessLevel, ContactAccessLevel, CaseAccessLevel
                                        FROM AccountShare
                                        WHERE AccountId IN: accIdsShareDelete
                                        AND UserOrGroupId IN: mapGroups.values()
                                        AND RowCause = 'Manual'];

                if (!listExistingShare.isEmpty() && !mapAccToGroup.isEmpty()) {
                    recalculateSharing(listExistingShare, mapAccToGroup);
                } else if (listExistingShare.isEmpty() && !mapAccToGroup.isEmpty()) {
                    addNewAccountSharing(mapAccToGroup);
                } else if (!listExistingShare.isEmpty() && mapAccToGroup.isEmpty()) {
                    deleteExistingSharing(listExistingShare);
                }
            }
        }

        //check if recalculate required
        private void recalculateSharing(List<AccountShare> listExistingShare, Map<Id, Id> mapAccToGroup) {
            List<AccountShare> listToCheckSharing = new List<AccountShare>();
            for (AccountShare accShare : listExistingShare) {
                if (mapAccToGroup.containsKey(accShare.AccountId) && mapAccToGroup.get(accShare.AccountId) == accShare.UserOrGroupId) {
                    mapAccToGroup.remove(accShare.AccountId);
                } else {
                    listSharingToDelete.add(accShare);
                }
            }
            if (!listSharingToDelete.isEmpty()) {
                deleteExistingSharing(listSharingToDelete);
            }
            if (!mapAccToGroup.isEmpty()) {
                addNewAccountSharing(mapAccToGroup);
            }
        }

        //Delete existing sharing if Access Controls
        private void deleteExistingSharing(List<AccountShare> listSharingToDelete) {
            if (!listSharingToDelete.isEmpty()) {
                delete listSharingToDelete;
            }
        }

        //Add new sharing if Access Controls
        private void addNewAccountSharing(Map<Id, Id> mapAccToGroup) {
            if (!mapAccToGroup.isEmpty()) {
                for (Id accId : mapAccToGroup.keySet()) {
                    if (mapAccToGroup.get(accId) != null) {
                        listAccShareInsert.add(new AccountShare(AccountId = accId, UserOrGroupId = mapAccToGroup.get(accId),
                                                                AccountAccessLevel = 'Edit', OpportunityAccessLevel = 'Edit',
                                                                ContactAccessLevel = 'Edit', CaseAccessLevel='Edit',
                                                                RowCause = 'Manual'));
                    }
                }
            }
            if (!listAccShareInsert.isEmpty()) {
                try {
                    insert listAccShareInsert;
                } catch(Exception e){
                    system.debug('Exception'+e);
                }
            }
        }
    }

    public class TestTriggerHandler extends Triggers.TriggerHandlerBase {
        override public void handle() {
            this.assertContextVariables();
        }

        private void assertContextVariables() {
            System.assertEquals(Trigger.isExecuting, this.isExecuting);
            System.assertEquals(Trigger.isBefore, this.isBefore());
            System.assertEquals(Trigger.isAfter, this.isAfter());
            System.assertEquals(Trigger.isInsert, this.isInsert());
            System.assertEquals(Trigger.isUpdate, this.isUpdate());
            System.assertEquals(Trigger.isDelete, this.isDelete());
            System.assertEquals(Trigger.isUndelete, this.isUndelete());
            this.assertTriggerRecords();
            System.assertEquals(Trigger.old, this.oldRecords());
            System.assertEquals(Trigger.newMap, this.newMap());
            System.assertEquals(Trigger.oldMap, this.oldMap());
        }

        private void assertTriggerRecords() {
            if (!Trigger.isExecuting) {
                System.assertEquals(new List<SObject>(), this.triggerRecords);
                return;
            }

            if (Trigger.isDelete) {
                System.assertEquals(Trigger.old, this.triggerRecords);
            } else {
                System.assertEquals(Trigger.new, this.triggerRecords);
            }
        }
    }
    
    public class GSPAccountOwnerValidation extends Triggers.TriggerHandlerBase {
        
        private Map<String, Brand_List__c> brandListRecordByBrandName;
        private Map<String, Reseller_Partner_Id__c> resellerPartnerIdRecordByPartnerId;
        private Map<String, Bypass_GSP_override_Validation__c> bypassGSPOverrideValidationByProfileName;
        private Map<Id, User> ownerUserById;

        private Boolean isLeadConversionEnabled = ConvertLead.IS_LEAD_CONVERT_PROCESSING;
        private Boolean isLeadConversionUsingCacheEnabled = SettingsHelper.FEATURE_TOGGLE.EnableLeadConversionUsingCache__c;
        
        override public void handle() {
            if (!shouldProcessGSPValidation()) {
                return;
            }
            
            initializeCustomSettingsMaps();
            initializeOwnerUserById();
            
            for (Account acc : (List<Account>) Trigger.new) {
                processGSPValidation(acc);
            }
        }

        private void initializeOwnerUserById() {
            Set<Id> ownerIds = new Set<Id>();
            for (Account acc : (List<Account>) Trigger.new) {
                if (acc.OwnerId != null) {
                    ownerIds.add(acc.OwnerId);
                }
            }
            
            if (ownerIds.isEmpty()) {
                ownerUserById = new Map<Id, User>();
                return;
            }
            
            if (isLeadConversionEnabled && isLeadConversionUsingCacheEnabled) {
                ownerUserById = UserHelper.retrieveUserMapWithCache(ownerIds);
            } else {
                ownerUserById = new Map<Id, User>((List<User>) new UserSelector()
                    .selectUsersByIds(ownerIds)
                    .selectFields(new List<String>{'Id', 'GSP_User__c', 'Profile.Name'})
                    .executeQuery());
            }
        }

        private Boolean shouldProcessGSPValidation() {
            if (Trigger.isInsert) {
                return true;
            }
            
            if (Trigger.isUpdate) {
                for (Account acc : (List<Account>) Trigger.new) {
                    Account oldAcc = (Account) Trigger.oldMap.get(acc.Id);
                    if (isChangedField(acc, Account.RC_Brand__c) ||
                        isChangedField(acc, Account.Partner_ID__c) ||
                        isChangedField(acc, Account.OwnerId)) {
                        return true;
                    }
                }
            }
            
            return false;
        }
        
        private void initializeCustomSettingsMaps() {
            if (brandListRecordByBrandName == null) {
                brandListRecordByBrandName = new Map<String, Brand_List__c>();
                for (Brand_List__c brand : Brand_List__c.getAll().values()) {
                    if (brand.GSP_Brand__c == true && brand.Brand_Name__c != null) {
                        brandListRecordByBrandName.put(brand.Brand_Name__c.toLowerCase(), brand);
                    }
                }
            }
            
            if (resellerPartnerIdRecordByPartnerId == null) {
                resellerPartnerIdRecordByPartnerId = new Map<String, Reseller_Partner_Id__c>();
                for (Reseller_Partner_Id__c partner : Reseller_Partner_Id__c.getAll().values()) {
                    if (partner.Partner_ID__c != null) {
                        resellerPartnerIdRecordByPartnerId.put(partner.Partner_ID__c.toLowerCase(), partner);
                    }
                }
            }
            
            if (bypassGSPOverrideValidationByProfileName == null) {
                bypassGSPOverrideValidationByProfileName = new Map<String, Bypass_GSP_override_Validation__c>();
                for (Bypass_GSP_override_Validation__c bypass : Bypass_GSP_override_Validation__c.getAll().values()) {
                    if (bypass.Profile_Name__c != null) {
                        bypassGSPOverrideValidationByProfileName.put(bypass.Profile_Name__c.toLowerCase(), bypass);
                    }
                }
            }
        }
        
        private void processGSPValidation(Account acc) {
            Boolean shouldBeGSP = isGSPAccount(acc);
            
            if (acc.GSP__c != shouldBeGSP) {
                acc.GSP__c = shouldBeGSP;
            }
        }
        
        private Boolean isGSPAccount(Account acc) {
            Boolean isGSPBrand = false;
            if (acc.RC_Brand__c != null) {
                isGSPBrand = brandListRecordByBrandName.containsKey(acc.RC_Brand__c.toLowerCase());
            }
            
            Boolean isGSPPartner = false;
            if (acc.Partner_ID__c != null) {
                isGSPPartner = resellerPartnerIdRecordByPartnerId.containsKey(acc.Partner_ID__c.toLowerCase());
            }
            
            if ((isGSPBrand || isGSPPartner) && acc.GSP__c == false && 
                acc.Account_Payment_Method__c == AccountHelper.PAYMENT_METHOD_PARTNER_BILLING_NGBS) {
                return true; 
            }
            
            if ((isGSPBrand || isGSPPartner) && acc.GSP__c == false && 
                acc.Account_Payment_Method__c != AccountHelper.PAYMENT_METHOD_PARTNER_BILLING_NGBS) {
                return true; 
            }
            
            if (!isGSPBrand && !isGSPPartner && acc.GSP__c == true) {
                return false; 
            }
            
            if (Trigger.isUpdate) {
                validateGSPOwner(acc);
            }
            
            return acc.GSP__c;
        }
        
        private void validateGSPOwner(Account acc) {
          Account oldAcc = (Account) Trigger.oldMap.get(acc.Id);
            
            User newOwner = ownerUserById.get(acc.OwnerId);
            if (newOwner == null) {
                return;
            }
            
            Boolean isOwnerNonGSP = newOwner.GSP_User__c == false;
            
            Boolean isOwnerChanged = acc.OwnerId != oldAcc.OwnerId;
            
            Boolean isAccountGSP = acc.GSP__c == true;
            
            Boolean noBypassProfile = !canUserBypassValidation(newOwner);
            
            if (isOwnerNonGSP && isOwnerChanged && isAccountGSP && noBypassProfile) {
                acc.addError(AccountHelper.NON_GSP_OWNER_ERROR);
            }
        }
        
        private Boolean canUserBypassValidation(User user) {
            return bypassGSPOverrideValidationByProfileName.containsKey(user.Profile.Name.toLowerCase());
        }
    }

    public class SendAccountDetailsforClayEnrichment extends Triggers.TriggerHandlerBase {
        override public void handle() {
            Gating_Process_Stage__c cs = Gating_Process_Stage__c.getInstance();
            if (cs != null && cs.IsClayEnabled__c) {
                AccountTriggerHelper.SendAccountDetailsforClayEnrichment((List<Account>) Trigger.New);
            }
        }
    }

    /**
     * @description Assigns Wave__c on the given Account based on its RC_Upgrade_Date__c month
     *              and the Medallia_Survey_schedule__mdt month-range configuration.
     *              Used by the PopulateWaveOnInsertAndUpdate handler for both before-insert
     *              and before-update contexts to keep wave-assignment logic in one place.
     * @param acc    Account record to evaluate and update in-memory.
     * @param msList All Medallia_Survey_schedule__mdt records to evaluate against.
     */
    private static void applyWaveFromMetadata(Account acc, List<Medallia_Survey_schedule__mdt> msList) {
        if (!AccountHelper.isPaid(acc) || acc.RC_Upgrade_Date__c == null) {
            return;
        }
        Integer upgradeMonth = acc.RC_Upgrade_Date__c.month();
        for (Medallia_Survey_schedule__mdt ms : msList) {
            if (upgradeMonth >= ms.MonthRange1__c && upgradeMonth <= ms.MonthRange2__c) {
                acc.Wave__c = ms.Label;
                return;
            }
        }
    }

    /**
     * @description Populates Wave__c on Account records using Medallia_Survey_schedule__mdt
     *              month-range configuration via the shared applyWaveFromMetadata helper.
     *
     *              Before Insert: applies wave mapping for every new Account.
     *              Before Update: recalculates wave only when:
     *                - status changed to Paid while RC_Upgrade_Date__c is non-null, OR
     *                - RC_Upgrade_Date__c changed (non-null) while status is already Paid.
     */
    public class PopulateWaveOnInsertAndUpdate extends Triggers.TriggerHandlerBase {
        override public void handle() {
            List<Medallia_Survey_schedule__mdt> msList = Medallia_Survey_schedule__mdt.getAll().values();
            if (msList.isEmpty()) {
                return;
            }

            if (Trigger.isInsert) {
                for (Account acc : (List<Account>) Trigger.new) {
                    applyWaveFromMetadata(acc, msList);
                }
            } else if (Trigger.isUpdate) {
                for (Account acc : (List<Account>) Trigger.new) {
                    Boolean statusChangedToPaid =
                        isChangedFieldTo(acc, Account.RC_Account_Status__c, AccountHelper.PAID_STATUS)
                        && acc.RC_Upgrade_Date__c != null;

                    Boolean upgradeDateChanged =
                        isChangedField(acc, Account.RC_Upgrade_Date__c)
                        && acc.RC_Upgrade_Date__c != null
                        && AccountHelper.isPaid(acc);

                    if (statusChangedToPaid || upgradeDateChanged) {
                        applyWaveFromMetadata(acc, msList);
                    }
                }
            }
        }
    }
}