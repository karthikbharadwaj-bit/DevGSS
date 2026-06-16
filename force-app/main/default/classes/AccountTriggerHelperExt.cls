/**************************************************************************************************
* UPDATE                                                                                          *
*                                                                                                 *
* @Case...................:  04065723                                                             *
* @Discription............:  Request to have Channel Mananger Email value on Account              *
* @Param..................:  Account                                                              *
* @Return.................:  NA                                                                   *
* @Last Modified by.......:  eugenebasianomutya                                                   *
* @Last Modified Date.....:  12/16/2015                                                           *
*                                                                                                 *
* UPDATE                                                                                          *
*                                                                                                 *
* @Case...................:  04343815                                                             *
* @Discription............:  (QW) New Implementation Fields for Reporting                         *
* @Param..................:  Account                                                              *
* @Return.................:  NA                                                                   *
* @Last Modified by.......:  eugenebasianomutya                                                   *
* @Last Modified Date.....:  2/26/2015                                                            *
**************************************************************************************************/


public class AccountTriggerHelperExt {
    //VARIABLE DECLARATION
    private static final String PARTNER = 'Partner';
    public static final String CUSTOMER_ACCOUNT = 'Customer Account';
    public static final String PARTNER_ACCOUNT = 'Partner Account';
    private static final String CLOSED = 'Closed';

    //Declaring Updated Account Map and Older Account Map.

    public static Map<string, Account> partnerIdToAccountMap = new Map<string, Account>();
    public static Set<Id> eligiblePartnerAccountStaticIdSet = new Set<Id>();
    public static Set<Id> trackDeletedAccntSplitSet = new Set<Id>();

    public static Map<Id, Account> oldAccountMap = new Map<Id, Account>();

    public class CustomException extends Exception {}
    private static final ImplementationMethods IMPLEMENTATION_METHODS = new ImplementationMethods();

    private static Boolean isRunningUserConnectionUser() {
        return UserInfo.getUserType() == 'PartnerNetwork' && UserInfo.getName() == 'Connection User';
    }

    private static User currentUser {
        get {
            if(currentUser == null) {
                currentUser = UserHelper.getCachedCurrentUser();
            }
            return currentUser;
        }
        set;
    }

    private static final Boolean byPass = isRunningUserConnectionUser()
        ? false
        : currentUser == null
            ? false
            : currentUser.IsTmtTriggersDisabled__c;

    public static Set<Id> prepareUserIdSet(List<Account> accountList) {
        Set<Id> userIds = new Set<Id>();
        for (Account accObj : accountList) {
            if (String.isNotBlank(accObj.OwnerId)) {
                userIds.add(accObj.OwnerId);
            }
            if (String.isNotBlank(accObj.Current_Owner__c)) {
                userIds.add(accObj.Current_Owner__c);
            }

            // Case #04065723 - START
            if (String.isNotBlank(accObj.OwnerId) && accObj.Inside_Sales_Rep__c != null) {
                userIds.add(accObj.Inside_Sales_Rep__c);
            }
            // Case #04065723 - END
        }
        return userIds;
    }

    /* Utility Method */
    /****************************************************************************
     * @Description - Queries User object and fetches relevant details.          *
     * @params Set<User>                                                        *
     * @return Map<Id,User>                                                      *
     *****************************************************************************/
    public static Map<Id, User> getUsers(Set<Id> userIds) {
        Map<Id, User> userMap = new Map<Id, User>();
        if (userIds.isEmpty()) {
            return userMap;
        }

        return new Map<Id, User>((List<User>) new UserSelector().selectUsersByIds(userIds).executeQuery());
    }
    /*****************************************************************************
     * @Description - Method to update Account information                        *
     * @params List<Account>, Map<Id,user>                                        *
     * @return void                                                               *
     *****************************************************************************/
    public static void accountRecordTypeInformation(List<Account> accountList) {

        System.debug('no.of queries got executed accountPhone' + limits.getqueries());
        try {
            //CMR - 221423
            //Record Type for ZI Shell accounts should not be changed on creation of new accounts
            for (Account acct : accountList) {
                //CMR - 221423
                //Record Type for ZI Shell accounts should not be changed on creation of new accounts
                if(acct.RecordTypeId != AccountHelper.RT_ID_ZI_ACCOUNT) {
                    acct.RecordTypeId = acct.Type == PARTNER ? AccountHelper.RT_ID_PARTNER_ACCOUNT : AccountHelper.RT_ID_CUSTOMER_ACCOUNT;
                }
                if (arePhoneAndBillingCountryNotNull(acct)) {
                    acct.Original_Phone_Number__c = acct.Phone;
                    acct.Phone = ValidationUtility.validatePhoneNumber(acct.Phone, acct.BillingCountry);
                }
            }
        } catch (Exception e) {
            System.debug('accountRecordTypeInformation @ ' + e.getlineNumber());
            System.debug('#### accountRecordTypeInformation ' + e.getMessage());
        }
    }
    /*********************************************************************************
     * @Description - Method to populate partner Account name on Customer's Account   *
     * @params List<Account>, Map<Id,Schema.RecordTypeInfo>                           *
     * @return void                                                                   *
     *********************************************************************************/


    public static void accountSharingOnInsert(List<Account> accountList) {
        System.debug('no.of queries got executed updateCurrentOwner' + limits.getqueries());
        if (accountList == null || accountList.isEmpty()) {
            return;
        }

        try {
            Set<String> setPartnerId = new Set<String>();
            for (Account accountObj : accountList) {
                // no need to use accountobj.type
                if (String.isNotBlank(accountObj.Partner_ID__c)
                    && AccountHelper.TYPE_CUSTOMER.equalsIgnoreCase(accountObj.Type)
                    && isCustomerAccount(accountObj)
                ) {
                    setPartnerId.add(accountObj.Partner_ID__c);
                }
                if (String.isNotBlank(accountObj.Partner_ID__c)
                    && isPartnerAccount(accountObj)
                    && String.isBlank(accountObj.RC_User_ID__c)
                ) {
                    accountObj.RC_User_ID__c = accountObj.Partner_ID__c;
                }
            }

            if (setPartnerId.isEmpty()){
                return;
            }

            List<Account> lstAcc = (List<Account>) new AccountSelector()
                .selectAccountsByTypeAndByPartnerIds(PARTNER, setPartnerId)
                .executeQuery();
            if (lstAcc.isEmpty()) {
                return;
            }

            Map<String, Account> mapPartnerIdToAccount = new Map<String, Account>();
            for (Account accountObj : lstAcc) {
                mapPartnerIdToAccount.put(accountObj.Partner_ID__c, accountObj);
            }
            for (Account accountObj : accountList) {
                if (String.isEmpty(accountObj.Partner_ID__c) || mapPartnerIdToAccount.get(accountObj.Partner_ID__c) == null) {
                    continue;
                }

                Account partnerAccount = mapPartnerIdToAccount.get(accountObj.Partner_ID__c);
                accountObj.Do_Not_Creation_Implementation__c = partnerAccount.Do_Not_Creation_Implementation__c;

                /***************************** code for populating partner Account name on Customer's Account *************/
                if (!isCustomerAccountWithType(accountObj)) {
                    continue;
                }

                accountObj.Partner_Account__c = partnerAccount.Id;
                accountObj.Partner_Account_Name__c = partnerAccount.Name;
                accountObj.Ultimate_Partner_ID__c = partnerAccount.Ultimate_Parent_Partner_ID__c;
                accountObj.Ultimate_Partner_Name__c = partnerAccount.Ultimate_Parent_Account_Name__c;

                //Case #03765152
                accountObj.VAR_Territory__c = partnerAccount.VAR_Territory__c;
                //Case #03765152
                /****************************************/
            }

        } catch (exception ex) {
            System.debug('Exception accountSharingOnInsert @@' + ex.getlineNumber());
            System.debug('Exception accountSharingOnInsert' + ex.getMessage());
        }
    }
    /*********************************************************************************
     * @Description - Method to update current owner name, email                      *
     * @params List<Account>, Map<Id,Schema.RecordTypeInfo>                           *
     * @return void                                                                   *
     *********************************************************************************/

    //ambiguous name
    public static void accountSharingOnUpdate0(List<Account> accList, Map<Id, User> userMap, Map<Id, Package__c> accountToPackagesMap) {
        try {
            if (accList.isEmpty()) {
                return;
            }

            // wht is bypass
            if (!byPass) {
                for (Account accObj : accList) {
                    Account oldAccObj = oldAccountMap.get(accObj.ID);
                    if (shouldUpdateCustomerProfileLastModifiedDate(accObj, oldAccObj)) {
                        accObj.Customer_Profile_Last_modified_Date__c = System.now();
                    }
                    if (oldaccObj.Current_Owner__c != null && accObj.Current_Owner__c == null) {
                        // if current owner was removed
                        accObj.Current_Owner_Name__c = null;
                        accObj.Current_Owner_Email__c = null;
                        continue;
                    }
                    //update current owner name, email
                    if (accObj.Current_Owner__c != null
                        && oldaccObj.Current_Owner__c != accObj.Current_Owner__c
                        && !UserInfo.getFirstName().containsIgnoreCase('RCSF')
                    ) {
                        User CO = usermap.get(accObj.Current_Owner__c);
                        accObj.Current_Owner_Name__c = CO.Name;
                        accObj.Current_Owner_Email__c = CO.Email;
                    }
                }
            }

            Set<Id> accIds = new Set<Id>();
            for (Account accObj : accList) {
                // Adding Logic to Ignore 1 from the Account Number for AT&T Accounts - ITPMO-4123
                if (accObj.RC_Account_Number__c != null && System.Label.BizMerge_Brand_Exclusion_List != null && System.Label.BizMerge_Brand_Exclusion_List.contains(accObj.RC_Brand__c)) {
                    if (accObj.RC_Account_Number__c.length() == 11 && accObj.RC_Account_Number__c.startsWith('1')) {
                        accObj.RC_Account_Number__c = accObj.RC_Account_Number__c.substring(1);
                    }
                }
                accIds.add(accObj.id);
            }
            for (Account newAccount : accList) {
                Account oldAccount = oldAccountMap.get(newAccount.id);
                Package__c pkg = accountToPackagesMap.get(newAccount.Id);
                if (IMPLEMENTATION_METHODS.chkToHardwareRtnOnDeactivation(newAccount, oldAccount, pkg)) {
                    newAccount.Hardware_Return_Pending__c = true;
                    newAccount.Trial_De_activation_Date__c = System.today();
                }
                if (shouldValidatePhoneNumber(newAccount, oldAccount)) {
                    newAccount.Phone = ValidationUtility.validatePhoneNumber(newAccount.Phone, newAccount.BillingCountry);
                }
            }
        } catch (Exception e) {
            System.debug('Exception accountSharingOnUpdate0 @@' + e.getlineNumber());
            System.debug('Exception accountSharingOnUpdate0' + e.getMessage());
        }
    }
    /*********************************************************************************
     * @Description - Method to update current owner name, email                      *
     * @params List<Account>, Map<Id,Account>[trigger.oldMap]                         *
     * @return void                                                                   *
     *********************************************************************************/
    // TODO: split this into two methods
    public static void accountSharingOnUpdate2(List<Account> accList) {
        if (accList.isEmpty()) {
            return;
        }

        Map<String, Account> mapPartnerIdToAccount = new Map<String, Account>();
        try {
            Set<String> setPartnerId = new Set<String>();
            for (Account objAcc : accList) {
                Account accB4Update = oldAccountMap.get(objAcc.id);

                if (String.isNotEmpty(objAcc.Partner_ID__c)
                    && isCustomerAccountWithType(objAcc)
                    && accB4Update.Partner_ID__c != objAcc.Partner_ID__c
                ) {
                    setPartnerId.add(objAcc.Partner_ID__c);
                }
            }

            List<Account> lstAcc;
            if (!setPartnerId.isEmpty()) {
                lstAcc = (List<Account>) new AccountSelector()
                    .selectAccountsByTypeAndByPartnerIds(PARTNER, setPartnerId)
                    .executeQuery();
            }

            if (lstAcc != null && !lstAcc.isEmpty()) {
                for (Account objAcc : lstAcc) {
                    mapPartnerIdToAccount.put(objAcc.Partner_ID__c, objAcc);
                }
            }

            if (!mapPartnerIdToAccount.isEmpty()) {
                for (Account objAcc : accList) {
                    if (String.isEmpty(objAcc.Partner_ID__c) || !mapPartnerIdToAccount.containsKey(objAcc.Partner_ID__c)) {
                        continue;
                    }

                    Account objAccount = mapPartnerIdToAccount.get(objAcc.Partner_ID__c);
                    objAcc.Do_Not_Creation_Implementation__c = objAccount.Do_Not_Creation_Implementation__c;
                }

                /***************************** code for populating partner Account name on Customer's Account *************/
                for (Account objAcc : accList) {
                    if (String.isNotEmpty(objAcc.Partner_ID__c)
                        && isCustomerAccountWithType(objAcc)
                        && mapPartnerIdToAccount.containsKey(objAcc.Partner_ID__c)
                    ) {
                        Account partnerAccount = mapPartnerIdToAccount.get(objAcc.Partner_ID__c);
                        objAcc.Partner_Account__c = partnerAccount.Id;
                        objAcc.Partner_Account_Name__c = partnerAccount.name;
                        objAcc.Ultimate_Partner_ID__c = partnerAccount.Ultimate_Parent_Partner_ID__c;
                        objAcc.Ultimate_Partner_Name__c = partnerAccount.Ultimate_Parent_Account_Name__c;

                        //Case #03765152
                        objAcc.VAR_Territory__c = partnerAccount.VAR_Territory__c;
                        //Case #03765152
                    }
                }
                /****************************************/
            }
        } catch (exception ex) {
            System.debug('Exception accountSharingOnUpdate2 @@' + ex.getlineNumber());
            System.debug('Exception accountSharingOnUpdate2' + ex.getMessage());
        }
        try {
            List<Account> partnerAccountLst = new List<Account>();
            Set<String> lstPartnerAcc = new Set<String>();

            for (Account objAcc : accList) {
                Account partnerAccountB4 = oldAccountMap.get(objAcc.id);
                if ((partnerAccountB4.Do_Not_Creation_Implementation__c != objAcc.Do_Not_Creation_Implementation__c)
                    && (objAcc.Type == PARTNER) && objAcc.Partner_Id__c != null
                    && isPartnerAccount(objAcc)
                ) {
                    lstPartnerAcc.add(objAcc.Partner_Id__c);
                    partnerAccountLst.add(objAcc);
                }
            }
            Map<String, List<Account>> MapToPartnerLstCustomer = new Map<String, List<Account>>();
            List<Account> lstPartnerCustomer = new List<Account>();
            if (!lstPartnerAcc.isEmpty()) {
                lstPartnerCustomer = (List<Account>) new AccountSelector()
                    .selectCustomerAccountsByPartnerIds(lstPartnerAcc)
                    .executeQuery();
            }
            for (Account accountObj : lstPartnerCustomer) {
                if (String.isEmpty(accountObj.Partner_Id__c)) {
                    continue;
                }

                List<Account> accountList = new List<Account>();
                if (MapToPartnerLstCustomer.containsKey(accountObj.Partner_Id__c)) {
                    accountList = MapToPartnerLstCustomer.get(accountObj.Partner_Id__c);
                }
                accountList.add(accountObj);
                MapToPartnerLstCustomer.put(accountObj.Partner_Id__c, accountList);
            }

            List<Account> lstPartnerChildCustomer = new List<Account>();
            for (Account objPartner : partnerAccountLst) {
                if (objPartner.Do_Not_Creation_Implementation__c != oldAccountMap.get(objPartner.Id).Do_Not_Creation_Implementation__c) {
                    for (Account PartnerCustomer : MapToPartnerLstCustomer.get(objPartner.Partner_Id__c)) {
                        if (objPartner.Partner_Id__c == PartnerCustomer.Partner_Id__c) {
                            PartnerCustomer.Do_Not_Creation_Implementation__c = objPartner.Do_Not_Creation_Implementation__c;
                            lstPartnerChildCustomer.add(PartnerCustomer);
                        }
                    }
                }
            }
            if (!lstPartnerChildCustomer.isEmpty()) {
                TriggerHandler.BY_PASS_ACCOUNT_ON_UPDATE();
                update lstPartnerChildCustomer;
                TriggerHandler.RESET_VARIABLES();
            }
        } catch (exception ex) {
            System.debug('Exception lstPartnerChildCustomer @@' + ex.getlineNumber());
            System.debug('Exception lstPartnerChildCustomer' + ex.getMessage());
        }
    }

    /*********************************************************************************
    * @Description - Method to update customer of Partner account in customer count field                      *
    * @params List<Account>, Map<Id,Account>[trigger.oldMap]                         *
    * @return void                                                                   *
    *********************************************************************************/
    public static void updateCreditCounter(List<Account> accountList, map<Id, Account> oldAccountMapParam) {
        try {
            Set<String> partnerIDSet = new Set<String>();
            for (Account accObj : accountList) {
                if (isCustomerAccount(accObj) &&
                    accObj.Partner_ID__c != null) {
                    partnerIDSet.add(accObj.Partner_ID__c);
                }
            }
            Map<Id, Integer> counterToPartnerAccount = new Map<Id, Integer>();

            List<Account> partnerAccounts = new List<Account>();
            if (!partnerIDSet.isEmpty()) {
                partnerAccounts = (List<Account>) new AccountSelector()
                    .selectPartnerAccountsByPartnerIds(partnerIDSet)
                    .executeQuery();
            }

            if (!partnerAccounts.isEmpty()) {
                for (Account accObj : partnerAccounts) {
                    partnerIdToAccountMap.put(accObj.Partner_ID__c, accObj);
                    Integer initialCounter = 0;
                    counterToPartnerAccount.put(accObj.Id, initialCounter);
                }
            }
            Map<Id, Account> accountIdMapToUpd = new Map<Id, Account>();
            for (Account accObj : accountList) {
                if (!isCustomerAccount(accObj)
                    || String.isEmpty(accObj.Partner_ID__c)
                    || String.isBlank(accObj.RC_Account_Status__c)
                    || !(oldAccountMapParam == null
                        || oldAccountMapParam.get(accObj.id).RC_Account_Status__c != accObj.RC_Account_Status__c
                        || oldAccountMapParam != null)
                    || !accObj.RC_Account_Status__c.equalsIgnoreCase('Paid')
                    || partnerIdToAccountMap == null
                    || partnerIdToAccountMap.get(accObj.Partner_ID__c) == null
                ) {
                    continue;
                }

                Boolean accountShouldBeProcessed = oldAccountMapParam == null
                    || oldAccountMapParam != null
                        && !AccountHelper.SUSPENDED_STATUS.equalsIgnoreCase(oldAccountMapParam.get(accObj.id).RC_Account_Status__c)
                        && !AccountHelper.CANCELED_STATUS.equalsIgnoreCase(oldAccountMapParam.get(accObj.id).RC_Account_Status__c);
                if (!accountShouldBeProcessed) {
                    continue;
                }

                Account partnerAccountObj = partnerIdToAccountMap.get(accObj.Partner_ID__c);
                accountShouldBeProcessed = partnerAccountObj != null
                    && partnerAccountObj.Referring_DSR__c != null
                    && partnerAccountObj.Partner_Sign_Up_Date__c != null
                    && (counterToPartnerAccount.get(partnerAccountObj.id) < 5 && partnerAccountObj.Partner_Sign_Up_Date__c.year() < 2015
                        || counterToPartnerAccount.get(partnerAccountObj.id) < 3 && partnerAccountObj.Partner_Sign_Up_Date__c.year() >= 2015)
                    && accObj.RC_Signup_Date__c != null
                    && partnerAccountObj.Partner_Sign_Up_Date__c.daysBetween(accObj.RC_Signup_Date__c.date()) < 185;
                if (!accountShouldBeProcessed) {
                    continue;
                }

                accObj.Eligible_for_Refferel_Credit__c = true;
                counterToPartnerAccount.put(partnerAccountObj.id, counterToPartnerAccount.get(partnerAccountObj.id) + 1);
                accountIdMapToUpd.put(partnerAccountObj.id, partnerAccountObj);
            }
            if (accountIdMapToUpd.isEmpty()) {
                return;
            }

            eligiblePartnerAccountStaticIdSet.addall(accountIdMapToUpd.keySet());

            triggerhandler.BY_PASS_ACCOUNT_ON_INSERT();
            triggerhandler.BY_PASS_ACCOUNT_ON_UPDATE();
            update accountIdMapToUpd.values();
            TriggerHandler.RESET_VARIABLES();
        } catch (Exception ex) {
        }
    }
    public static Map<Id, Account> updateMostRecentImplementationContact(Map<Id, Account> mapAccount) {
        Map<Id, Account> mapAccountToUpdate = new Map<Id, Account>();
        try {
            if (mapAccount == null || mapAccount.isEmpty()) {
                return mapAccountToUpdate;
            }
            List<Account> accountsWithAccountContactRoles = [
                Select Most_Recent_Implementation_Contact__c, (
                    Select Id, AccountId, ContactId,
                        Role, IsPrimary, CreatedDate, CreatedById, LastModifiedDate, LastModifiedById, SystemModstamp, IsDeleted
                    From AccountContactRoles
                    where isPrimary = true
                )
                From Account a
                where a.id IN :mapAccount.keySet()
            ];
            if (accountsWithAccountContactRoles.isEmpty()) {
                return mapAccountToUpdate;
            }

            for (Account objAccount : accountsWithAccountContactRoles) {
                if (objAccount.AccountContactRoles.isEmpty()) {
                    continue;
                }

                AccountContactRole objACR = objAccount.AccountContactRoles[0];
                if (objACR == null
                    || objACR.ContactId == null
                    || mapAccount.get(objAccount.Id).Most_Recent_Implementation_Contact__c == objACR.ContactId
                ) {
                    continue;
                }

                mapAccount.get(objAccount.Id).Most_Recent_Implementation_Contact__c = objACR.ContactId;
                mapAccountToUpdate.put(objAccount.Id, mapAccount.get(objAccount.Id));
            }
            return mapAccountToUpdate;
        } catch (Exception e) {
            System.debug('Exception updatePartnerCodeOnIsertAndUpdate @@' + e.getlineNumber());
            System.debug('Exception updatePartnerCodeOnIsertAndUpdate' + e.getMessage());
        }
        return mapAccountToUpdate;
    }

    // Case 04343815 - (QW) New Implementation Fields for Reporting - START
    public static Map<Id, Account> populateFirstAppointmentSource(Map<Id, Account> mAccount) {
        Map<Id, Account> accountMapToUpdate = new Map<Id, Account>();
        try {
            if (mAccount == null || mAccount.isEmpty()) {
                return accountMapToUpdate;
            }

            // Get Account with no Appointment Source
            Set<Id> accIdToProcess = new Set<Id>();
            for (Account acc : mAccount.values()) {
                if (String.isEmpty(acc.First_Appointment_Source__c)) {
                    accIdToProcess.add(acc.Id);
                }
            }

            // Process Account with no Appointment Source
            if (accIdToProcess.isEmpty()) {
                return accountMapToUpdate;
            }

            // Get Implementations
            Set<Id> idImpl = new Set<Id>();
            Map<Id, Id> mAccImp = new Map<Id, Id>();
            List<Implementation__c> implementations = (List<Implementation__c>) new ImplementationSelector()
                .selectImplementationsByAccountIds(accIdToProcess)
                .executeQuery();
            if (implementations.isEmpty()) {
                return accountMapToUpdate;
            }

            for (Implementation__c implementation : implementations) {
                mAccImp.put(implementation.Account__c, implementation.Id);
            }
            if (mAccImp.isEmpty()) {
                return accountMapToUpdate;
            }

            //Get Unique Implementation
            for (Id i : mAccImp.values()) {
                idImpl.add(i);
            }

            // Get Event
            Map<Id, Event> mImpEvent = new Map<Id, Event>();
            List<Event> events = (List<Event>) new EventSelector().selectEventsByWhatIds(idImpl).executeQuery();
            if (events.isEmpty()) {
                return accountMapToUpdate;
            }

            for (Event evnt : events) {
                mImpEvent.put(evnt.WhatId, evnt);
            }

            // Populate the value of Activities to Account
            for (Id accId : accIdToProcess) {
                Account acc = mAccount.get(accId);
                if (acc == null) {
                    System.debug('NO IMPLEMENTATION');
                    continue;
                }

                Event evnt = mImpEvent.get(mAccImp.get(acc.Id));
                if (evnt?.Appointment_Source__c == null) {
                    System.debug('NO ACTIVITY');
                    continue;
                }

                if (acc.First_Appointment_Source__c == evnt.Appointment_Source__c) {
                    continue;
                }

                acc.First_Appointment_Source__c = evnt.Appointment_Source__c;
                accountMapToUpdate.put(accId, acc);
            }
        } catch (Exception e) {
            System.debug('Exception populateFirstAppointmentSource @@' + e.getlineNumber());
            System.debug('Exception populateFirstAppointmentSource' + e.getMessage());
        }
        return accountMapToUpdate;
    }
    // Case 04343815 - (QW) New Implementation Fields for Reporting - END

    public static Set<String> getSetOfIds(BatchJobQueue__c batchJobQueueObject) {

        if (batchJobQueueObject == null) {
            return null;
        }

        return getSetOfIds(new List<BatchJobQueue__c>{batchJobQueueObject});
    }

    public static Set<String> getSetOfIds(List<BatchJobQueue__c> batchJobQueueObjects) {

        if (batchJobQueueObjects == null || batchJobQueueObjects.isEmpty()) {
            return null;
        }

        Set<String> setOfId = new Set<String>();
        for (BatchJobQueue__c batchJobQueue : batchJobQueueObjects) {
            if (String.isNotBlank(batchJobQueue.RecordIdsToBeProcessedInQueue__c)) {
                setOfId.addAll(batchJobQueue.RecordIdsToBeProcessedInQueue__c.split(', '));
            }
        }
        return setOfId;
    }

    public static void runAccountHierarchyCalculation(Set<String> ultimateParentIdSet) {
        Integer batchThreshold =
            (Integer) RingCentralVariousSettings__c.getInstance().CalculateTotalDlsThresholdToRunBatch__c;
        List<Account> accs = queryAccountsForHierarchyCalculation(ultimateParentIdSet);
        System.debug('------> queryAccountsForHierarchyCalculation size: ' + accs.size());
        if (accs.size() < batchThreshold) {
            calculateAccountHierarchyTotalDLS(accs);
            return;
        }

        BatchJobQueue__c bjq = new BatchJobQueue__c();
        bjq.BatchJobName__c = 'CalculateAccountHierarchyBatch';
        bjq.Status__c = 'New';
        String setIds = '';
        for (String str : ultimateParentIdSet) {
            setIds += str + ', ';
        }
        setIds = setIds.left(setIds.length() - 2);
        bjq.RecordIdsToBeProcessedInQueue__c = setIds;

        try {
            insert bjq;
        } catch (Exception ex) {
            System.debug(ex.getMessage());
        }
    }

    public static List<Account> queryAccountsForHierarchyCalculation(Set<String> ultimateParentIdSet) {
        if (ultimateParentIdSet == null || ultimateParentIdSet.isEmpty()) {
            return new List<Account>();
        }

        String queryString = getQueryStringForAccountHierarchyCalculation();
        return Database.query(queryString);
    }

    public static String getQueryStringForAccountHierarchyCalculation() {
        return 'SELECT Id, Ultimate_Parent_Account_ID__c, RC_Account_Status__c, Ultimate_Parent_Snapshot__c, ' +
            'Number_of_DL_s__c, Total_DLs__c, Name FROM Account ' +
            'WHERE NAME != NULL ' +
            'AND RecordType.Name =: CUSTOMER_ACCOUNT ' +
            'AND (Ultimate_Parent_Snapshot__c IN : ultimateParentIdSet ' +
            'OR Id IN : ultimateParentIdSet) ' +
            'ORDER BY Ultimate_Parent_Snapshot__c, Id';
    }
    /*************************************************************************************
    * @Description - Method to RollUp # of DL to all Parents and childs on Account on   *
    *                Insert/Update                                                      *
    * @params      -                                                                    *
    * @return      -                                                                    *
    ************************************************************************************/

    public static void calculateAccountHierarchyTotalDLS(List<Account> accMainList) {
        Map<Id, Decimal> parentCounterMap = new Map<Id, Decimal>();
        Map<Id, List<Account>> childAccountMap = new Map<Id, List<Account>>();
        System.debug('==accMainList==' + accMainList.size() + '==' + accMainList);
        //TODO
        //implement a bypass via code.
        //remove field RingCentralVariousSettings__c.BypassHierarchy__c

        for (Account accObj : accMainList) {
            // Only re-evaluate the hierarchy if it is either Ultimate Parent or any 'Paid' Account.
            if (accObj.RC_Account_Status__c != 'Paid' && String.valueOf(accObj.Ultimate_Parent_Account_ID__c).subString(0, 15) != String.valueOf(accObj.id).subString(0, 15)) {
                System.debug(accObj.Name + ' is not a paid account and not top parent');
                continue;
            }

            Id accountId = accObj.Ultimate_Parent_Account_ID__c != null ? accObj.Ultimate_Parent_Account_ID__c : accObj.Id;
            if (!parentCounterMap.containsKey(accountId)) {
                parentCounterMap.put(accountId, (accObj.Number_of_DL_s__c != null ? accObj.Number_of_DL_s__c : 0));
                childAccountMap.put(accountId, new List<Account> {accObj});
                continue;
            }

            Decimal counterValue = parentCounterMap.get(accountId);
            counterValue += (accObj.Number_of_DL_s__c != null ? accObj.Number_of_DL_s__c : 0);
            parentCounterMap.put(accountId, counterValue);
            if (childAccountMap.containsKey(accountId)) {
                childAccountMap.get(accountId).add(accObj);
            } else {
                childAccountMap.put(accountId, new List<Account> {accObj});
            }
        }

        System.debug('==parentCounterMap==' + parentCounterMap.size() + '==' + parentCounterMap);
        System.debug('==childAccountMap==' + childAccountMap.size() + '==' + childAccountMap);

        List<Account> updatedAccountList = new List<Account>();

        for (Id idValue : childAccountMap.keySet()) {
            for (Account accObj : childAccountMap.get(idValue)) {
                if (parentCounterMap == null || parentCounterMap.get(idValue) == null) {
                    continue;
                }

                accObj.Total_DLs__c = parentCounterMap.get(idValue);
                updatedAccountList.add(accObj);
            }
        }

        System.debug('==updatedAccountList==' + updatedAccountList.size() + '==' + updatedAccountList);

        Database.SaveResult[] srList = new List<Database.SaveResult>();
        if (!updatedAccountList.isEmpty()) {
            TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT();
            TriggerHandler.BY_PASS_ACCOUNT_ON_UPDATE();
            srList = Database.update(updatedAccountList, false);
            TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT = false;
            TriggerHandler.BY_PASS_ACCOUNT_ON_UPDATE = false;
        }

        Set<String> errorRecordIds = new Set<String>();
        List<String> errorMessages = new List<String>();
        for (Integer i = 0; i < srList.size(); i++) {
            if (!srList.get(i).isSuccess()) {
                errorRecordIds.add(updatedAccountList[i].Id);
                errorMessages.add(srList.get(i).getErrors().get(0).getMessage());
            }
        }

        if (errorRecordIds == null || errorRecordIds.isEmpty()) {
            return;
        }

        List<BatchJobQueue__c> batchJobQueues = (List<BatchJobQueue__c>) new BatchJobQueueSelector()
            .selectBatchJobQueuesByBatchJobNameAndByStatus('CalculateAccountHierarchyBatch', 'New')
            .executeQuery();
        if (batchJobQueues.isEmpty()) {
            return;
        }

        List<BatchJobQueue__c> batchJobQueuesToUpdate = new List<BatchJobQueue__c>();
        for (BatchJobQueue__c batchJobQueue : batchJobQueues) {
            Set<String> setIds = getSetOfIds(batchJobQueue);
            for (String bjqId : errorRecordIds) {
                if (!setIds.contains(bjqId)) {
                    continue;
                }
                batchJobQueue.Status__c = 'Failed';
                batchJobQueue.ExceptionMessage__c = String.join(errorMessages, ',');
                batchJobQueuesToUpdate.add(batchJobQueue);
            }
        }

        if (!batchJobQueuesToUpdate.isEmpty()) {
            update batchJobQueuesToUpdate;
        }
    }

    /*******End Of Method to RollUp # of DL to all Parents and childs on Account on Insert/Update*******************************************************************/

    /**************************************************************************
     * @Discription............:  Create Or/And Update Account-Split Records  *
     * @Param..................:  List<Account>, Set<Id>                      *
     * @Return.................:  Void                                        *
     * @Last Modified by.......:  Rajesh Kumar                                *
     * @Last Modified Date.....:  4/21/2015                                   *
     **************************************************************************/
    public static void createUpdateAccountSplits(List<Account> customerAccountList, Set<Id> eligiblePartnerAccountIdSet) {
        if (customerAccountList.isEmpty() || partnerIdToAccountMap.isEmpty()) {
            return;
        }

        List<Account> eligibleCustomerAccountList = new List<Account>();// only those customers whose partner is going to increase the Counter on it.
        List<Account_Split__c> accountSplitList = new List<Account_Split__c>();
        List<Account_Split__c> toDeleteAccSplitList = new List<Account_Split__c>();
        List<Account_Split__c> accountSplitToUpsertList = new List<Account_Split__c>();
        Map<Id, Account_Split__c> accountToAccSplitOverlayTypeMap = new Map<Id, Account_Split__c>();
        Map<Id, Account> idToCustomerAccntMap = new Map<Id, Account>();
        Map<Id, Account_Split__c> accountToAccSplitResselerTypeMap = new Map<Id, Account_Split__c>();
        Set<Id> accountIdSet = new Set<Id>();
        Set<Id> accIdSet = new Set<Id>(); /// Case #03726551
        for (Account acc : customerAccountList) {
            if (partnerIdToAccountMap.get(acc.Partner_ID__c) == null) {
                continue;
            }

            if (eligiblePartnerAccountIdSet != null && eligiblePartnerAccountIdSet.contains(partnerIdToAccountMap.get(acc.Partner_ID__c).Id)) {
                accountIdSet.add(acc.id);
                eligibleCustomerAccountList.add(acc);
                idToCustomerAccntMap.put(acc.Id, acc);
                trackDeletedAccntSplitSet.add(acc.Id);
                // Case #03726551 15th July 2015, Below elseif condition. If it has not gone to Partner Referral logic then it should do the following
            } else if (isCustomerAccount(acc)
                && acc.RC_Account_Status__c != null
                && acc.RC_Account_Status__c.equalsIgnoreCase(AccountHelper.PAID_STATUS)
                && !oldAccountMap.isEmpty()
                && oldAccountMap.containsKey(acc.Id)
                && oldAccountMap.get(acc.Id).RC_Account_Status__c != acc.RC_Account_Status__c
            ) {
                accIdSet.add(acc.id);
            }
        }

        if (!idToCustomerAccntMap.isEmpty()) {
            accountSplitList = returnAccountSplitList(accountIdSet);

            for (Account_Split__c accSplit : accountSplitList) {
                if (idToCustomerAccntMap.containsKey(accSplit.Account__c)
                    && !oldAccountMap.isEmpty()
                    && oldAccountMap.containsKey(accSplit.Account__c)
                    && oldAccountMap.get(accSplit.Account__c) != null
                    && idToCustomerAccntMap.get(accSplit.Account__c).Partner_ID__c != oldAccountMap.get(accSplit.Account__c).Partner_ID__c
                    && (accSplit.Role__c == 'DSR Shared Agent' && accSplit.Agent_Credit_Sub_Type__c == 'Overlay Shared'
                        || accSplit.Role__c == 'Reseller Referral Agent' && accSplit.Agent_Credit_Sub_Type__c == 'Reseller Referral')
                ) {
                    // If Customer's Partner is being changed, then delete previous AC Split records and create new ones.
                    toDeleteAccSplitList.add(accSplit);
                    continue;
                }
                if (accSplit.Role__c == 'DSR Shared Agent' && accSplit.Agent_Credit_Sub_Type__c == 'Overlay Shared') {
                    accountToAccSplitOverlayTypeMap.put(accSplit.Account__c, accSplit);
                }
                if (accSplit.Role__c == 'Reseller Referral Agent' && accSplit.Agent_Credit_Sub_Type__c == 'Reseller Referral') {
                    accountToAccSplitResselerTypeMap.put(accSplit.Account__c, accSplit);
                }
            }
            accountSplitToUpsertList = getAccountSplitUpsertList(eligibleCustomerAccountList, accountToAccSplitOverlayTypeMap, accountToAccSplitResselerTypeMap);
        }
        /// Case #03726551
        if (accIdSet.size() > 0) {
            List<Account_Split__c> accSplitTempList = new List<Account_Split__c>();
            accSplitTempList = returnAccountSplitList(accIdSet);
            for (Account_Split__c accSpl : accSplitTempList) {
                if (accSpl.Agent_Credit_Sub_Type__c != 'Overlay Shared' || accSpl.BeginDateUpdateOnStatusChange__c) {
                    continue;
                }

                accSpl.Begin_Date__c = System.today();
                accSpl.BeginDateUpdateOnStatusChange__c = true;
                accountSplitToUpsertList.add(accSpl);
            }
        }
        if (!toDeleteAccSplitList.isEmpty()) {
            delete toDeleteAccSplitList;
        }
        if (!accountSplitToUpsertList.isEmpty()) {
            upsert accountSplitToUpsertList;
        }
    }
    /************************************************************************************************
     * @Discription............:  This method returns AccountSplit lists to Update or Insert        *
     *                         :  - based on Conditions.                                            *
     * @Param..................:  List<Account>, Map<Id,Account_Split__c>, Map<Id,Account_Split__c> *
     * @Return.................:  List<Account_Split__c>                                            *
     * @Last Modified by.......:  Rajesh Kumar                                                      *
     * @Last Modified Date.....:  4/21/2015                                                         *
     ************************************************************************************************/
    private static List<Account_Split__c> getAccountSplitUpsertList(List<Account> customerAccountList, Map<Id, Account_Split__c> accountToAccSplitOverlayTypeMap, Map<Id, Account_Split__c> accountToAccSplitResselerTypeMap) {
        List<Account_Split__c> accountSplitToUpsertList = new List<Account_Split__c>();
        if (customerAccountList.isEmpty()) {
            return accountSplitToUpsertList;
        }

        for (Account acc : customerAccountList) {
            if (!isCustomerAccount(acc)) {
                continue;
            }

            Account partnerAccount;
            Boolean referralAcntSplitFoundBool = false;
            Boolean overlayAcntSplitFoundBool = false;
            overlayAcntSplitFoundBool = isAcntSplitFound(accountToAccSplitOverlayTypeMap, acc);
            referralAcntSplitFoundBool = isAcntSplitFound(accountToAccSplitResselerTypeMap, acc);

            if (partnerIdToAccountMap.containsKey(acc.Partner_ID__c)) {
                partnerAccount = partnerIdToAccountMap.get(acc.Partner_ID__c);
            }
            if (partnerAccount?.Partner_Sign_Up_Date__c == null) {
                continue;
            }

            if (overlayAcntSplitFoundBool) {
                Account_Split__c accSplitToUpdate = accountToAccSplitOverlayTypeMap.get(acc.id);
                accSplitToUpdate.Commission__c = 70;
                /// Case #03726551
                if (!accSplitToUpdate.BeginDateUpdateOnStatusChange__c) {
                    accSplitToUpdate.Begin_Date__c = System.today();
                    accSplitToUpdate.BeginDateUpdateOnStatusChange__c = true;
                }
                System.debug('======= End Date ====== ' + String.isBlank(String.valueOf(accSplitToUpdate.End_Date__c)));
                System.debug('======= Commissionable_Period__c ====== ' + accSplitToUpdate.Commissionable_Period__c);
                accountSplitToUpsertList.add(accSplitToUpdate);
            }

            if (referralAcntSplitFoundBool) {
                continue;
            }

            Id tempSalesUserId = partnerAccount.Referring_DSR__c;
            Date partnerSignUpDate = partnerAccount.Partner_Sign_Up_Date__c;
            Date beginDate = acc.RC_Upgrade_Date__c < partnerAccount.Partner_Sign_Up_Date__c
                             ? acc.RC_Upgrade_Date__c.date()
                             : partnerSignUpDate;
            System.debug('========== tempSalesUserIdfdfd ============' + partnerAccount.Referring_DSR__c);

            Integer commisionPercentage = populateCommissionPercentage(partnerSignUpDate, overlayAcntSplitFoundBool);
            Account_Split__c accSplitToInsert = new Account_Split__c(
                Account__c = acc.Id,
                Sales_Agent__c = tempSalesUserId,
                Role__c = 'Reseller Referral Agent',
                Agent_Credit_Split__c = 'Overlay',
                Agent_Credit_Sub_Type__c = 'Reseller Referral',
                Commission__c = commisionPercentage,
                Begin_Date__c = beginDate
            );

            accountSplitToUpsertList.add(accSplitToInsert);
        }
        return accountSplitToUpsertList;
    }
    /************************************************************************************************
     * @Discription............:  This method returns Commision Percentage based on SignUp Date     *
     * @Param..................:  Date, Boolean                                                     *
     * @Return.................:  Integer                                                           *
     * @Last Modified by.......:  Rajesh Kumar                                                      *
     * @Last Modified Date.....:  4/21/2015                                                         *
     ************************************************************************************************/
    private static Integer populateCommissionPercentage(Date partnerSignUpDate, Boolean overlayAcntSplitFoundBool) {
        if (overlayAcntSplitFoundBool) {
            return 30;
        }

        System.debug('========== partnerSignUpDate ====' + partnerSignUpDate);
        if (partnerSignUpDate.year() >= 2015) {
            return 100;
        }

        return 80;
    }
    /**************************************************************************************************
     * @Discription............:  This method deletes Account Splits if Partner of Customer Accoount -*
     *                         :  - changes                                                           *
     * @Param..................:  Map<Id,Account> newAccountMap                                       *
     * @Return.................:  void                                                                *
     * @Last Modified by.......:  Rajesh Kumar                                                        *
     * @Last Modified Date.....:  4/21/2015                                                           *
     **************************************************************************************************/
    public static void deleteAccntSplitOnPartnerChange(Map<Id, Account> newAccountMap) {
        Set<Id> accountIdSet = new Set<Id>();
        try {
            for (Id accId : newAccountMap.keySet()) {
                if (!trackDeletedAccntSplitSet.contains(accId)) {
                    // Will only get Account-Splits that were not deleted in 'createUpdateAccountSplits' Method as they did not match the conditions.
                    accountIdSet.add(accId);
                }
            }
            List<Account_Split__c> accountSplitList = returnAccountSplitList(accountIdSet);
            if (accountSplitList.isEmpty()) {
                return;
            }

            List<Account_Split__c> toDeleteAccSplitList = new List<Account_Split__c>();
            for (Account_Split__c accSplit : accountSplitList) {
                Account tempNewAccount = newAccountMap.get(accSplit.Account__c) != null
                        ? newAccountMap.get(accSplit.Account__c)
                        : new Account();
                Account tempOldAccount = oldAccountMap.get(accSplit.Account__c) != null
                        ? oldAccountMap.get(accSplit.Account__c)
                        : new Account();

                // DIRECT TO VAR
                System.debug('###### accSplit.PartnerId__c ' + accSplit.PartnerId__c);
                System.debug('###### tempNewAccount.Partner_ID__c ' + tempNewAccount.Partner_ID__c);
                if ((tempNewAccount.Partner_ID__c != tempOldAccount.Partner_ID__c || Test.isRunningTest())
                    && accSplit.PartnerId__c != tempNewAccount.Partner_ID__c
                    && tempOldAccount.Partner_ID__c != null
                    && (accSplit.Role__c == 'DSR Shared Agent' && accSplit.Agent_Credit_Sub_Type__c == 'Overlay Shared'
                        || accSplit.Role__c == 'Reseller Referral Agent' && accSplit.Agent_Credit_Sub_Type__c == 'Reseller Referral')
                ) {
                    // If Customer's Partner is being changed, then delete previous AC Split records and create new ones.
                    toDeleteAccSplitList.add(accSplit);
                }
            }
            if (toDeleteAccSplitList.size() > 0) {
                delete toDeleteAccSplitList;
            }
        } catch (Exception ex) {
        }
    }
    /**************************************************************************************************
     * @Discription............:  Gets the AccountSplit Records based on Account Ids                  *
     * @Param..................:  Set<Id>. Set of Account's Id                                        *
     * @Return.................:  List<Account_Split__c>                                              *
     * @Last Modified by.......:  Rajesh Kumar                                                        *
     * @Last Modified Date.....:  4/21/2015                                                           *
     **************************************************************************************************/
    private static List<Account_Split__c> returnAccountSplitList(Set<Id> accountIdSet) {
        if (accountIdSet.isEmpty()) {
            return new List<Account_Split__c>();
        }

        return [
            SELECT Id,PartnerId__c,Account__c,Sales_Agent__c,Role__c,Commission__c,
                Commissionable_Period__c,Agent_Credit_Sub_Type__c,BeginDateUpdateOnStatusChange__c,
                Agent_Credit_Split__c, End_Date__c
            FROM Account_Split__c
            WHERE Account__c IN:accountIdSet
        ];
    }


    /**************************************************************************************************
     * @Discription............:  Update Signature Opt Out                      *
     * @Param..................:  New Account, Old Account, Boolean if new or update                      *
     * @Return.................:  NA                                              *
     * @Last Modified by.......:  eugenebasianomutya                                              *
     * @Last Modified Date.....:  6/10/2015                                                 *
     **************************************************************************************************/
    public static void Update_SignatureRepPartnershipOptOut(list<Account> lAccount, map<Id, Account> mAccountNew, map<Id, Account> mAccountOld, Boolean isNew) {

        // New Partner/Customer Account is created. This code handles Bulk insert.
        if (isNew) {
            Map<String, Boolean> mPartId_PartOptOut = new Map<String, Boolean>();
            Set<String> sPartId_CustOptOut = new Set<String>();
            Map<String, boolean> myset = new Map<String, Boolean>();

            // Get the New Customer Account and Partner Account
            for (Account a : lAccount) {
                if (isPartnerAccount(a)) {
                    if (a.Partner_Id__c != '' && a.Partner_Id__c != NULL) {
                        mPartId_PartOptOut.put(a.Partner_Id__c, a.Signature_Rep_Partnership_Opt_Out__c);
                    }
                } else {
                    if (a.Partner_Id__c != '' && a.Partner_Id__c != NULL) {
                        sPartId_CustOptOut.add(a.Partner_Id__c);
                    }
                }
            }


            // ################################################# If partner Id of newly created Partner Account is already used by Customer Account, update Customer Account
            If (mPartId_PartOptOut.size() > 0) {
                List<Account> lCustomerAccountForUpdate = new List<Account>();
                List<Account> customerAccountsByPartnerIds = (List<Account>) new AccountSelector()
                    .selectCustomerAccountsByPartnerIds(mPartId_PartOptOut.keyset())
                    .executeQuery();

                if (!customerAccountsByPartnerIds.isEmpty()) {
                    for (Account a : customerAccountsByPartnerIds) {
                        if (!mPartId_PartOptOut.containsKey(a.Partner_Id__c)) {
                            continue;
                        }

                        a.Signature_Rep_Partnership_Opt_Out__c = mPartId_PartOptOut.get(a.Partner_Id__c);
                        lCustomerAccountForUpdate.add(a);
                    }
                }
                if (lCustomerAccountForUpdate.size() > 0) {
                    TriggerHandler.BY_PASS_ACCOUNT_ON_UPDATE = true;
                    update lCustomerAccountForUpdate;
                    TriggerHandler.BY_PASS_ACCOUNT_ON_UPDATE = false;
                }

            }

            // ################################################# Set the value of Customer Account SigOptout checbox base on the Partner Account (Partner Id)
            if (sPartId_CustOptOut.size() > 0) {
                // Get the Partner Account of the created Customer Account
                List<Account> partnerAccountsByPartnerIds = (List<Account>) new AccountSelector()
                    .selectPartnerAccountsByPartnerIds(mPartId_PartOptOut.keyset())
                    .executeQuery();

                for (Account a : partnerAccountsByPartnerIds) {
                    myset.put(a.Partner_Id__c, a.Signature_Rep_Partnership_Opt_Out__c);
                }

                if (lAccount == null || lAccount.isEmpty() || myset.isEmpty()) {
                    return;
                }
                for (Account a : lAccount) {
                    if (myset.containskey(a.Partner_Id__c)) {
                        a.Signature_Rep_Partnership_Opt_Out__c = myset.get(a.partner_Id__c);
                    }
                }
            }

            return;
        }
        // Updates on Partner/Customer Account. This code handles Bulk insert.

        List<Account> lCustomerAccountToUpdate = new List<Account>();
        Set<String> sPartnerAccountPartnerIdToCheck = new Set<String>();
        Map<String, boolean> mCustomerAccountPartnerIdToUpdate = new Map<String, Boolean>();

        // If Partner ID of Partner Account is removed, set checkbox of customer account to false if there are any
        if (mAccountNew == null || mAccountNew.isEmpty()) {
            return;
        }
        for (Account a : mAccountNew.values()) {

            // If Partner Account Partner ID or SigOptout is updated, get all customer Account and update
            if (isPartnerAccount(a) && a.Signature_Rep_Partnership_Opt_Out__c != mAccountOld.get(a.Id).Signature_Rep_Partnership_Opt_Out__c) {
                mCustomerAccountPartnerIdToUpdate.put(a.Partner_Id__c, a.Signature_Rep_Partnership_Opt_Out__c);
                // Customer Account partner Id is updated, if set to null, uncheck the box, if changes to another partner Id, check the Partner Account
            } else {
                if (a.Partner_Id__c != mAccountOld.get(a.Id).Partner_Id__c) {
                    if (a.Partner_Id__c == '' || a.Partner_Id__c == NULL) {
                        a.Signature_Rep_Partnership_Opt_Out__c = false;
                    } else {
                        sPartnerAccountPartnerIdToCheck.add(a.Partner_Id__c);
                    }

                }
            }
        }

        if (mCustomerAccountPartnerIdToUpdate.size() > 0) {
            List<Account> customerAccountsByPartnerIds = (List<Account>) new AccountSelector()
                .selectCustomerAccountsByPartnerIds(mCustomerAccountPartnerIdToUpdate.keyset())
                .executeQuery();
            if (!customerAccountsByPartnerIds.isEmpty()) {
                for (Account a : customerAccountsByPartnerIds) {
                    a.Signature_Rep_Partnership_Opt_Out__c = mCustomerAccountPartnerIdToUpdate.get(a.Partner_Id__c);
                    lCustomerAccountToUpdate.add(a);
                }
            }

            if (lCustomerAccountToUpdate.size() > 0) {
                TriggerHandler.BY_PASS_ACCOUNT_ON_UPDATE = True;
                Update lCustomerAccountToUpdate;
                TriggerHandler.BY_PASS_ACCOUNT_ON_UPDATE = False;
            }
        }

        if (sPartnerAccountPartnerIdToCheck.isEmpty()) {
            return;
        }

        // Get the Partner Account of the updated Customer Account
        List<Account> partnerAccountsByPartnerIds = (List<Account>) new AccountSelector()
            .selectPartnerAccountsByPartnerIds(sPartnerAccountPartnerIdToCheck)
            .executeQuery();
        if (partnerAccountsByPartnerIds.isEmpty()) {
            return;
        }

        Map<String, Boolean> mySet = new Map<String, Boolean>();
        for (Account a : partnerAccountsByPartnerIds) {
            mySet.put(a.Partner_Id__c, a.Signature_Rep_Partnership_Opt_Out__c);
        }

        for (Account a : mAccountNew.values()) {
            if (sPartnerAccountPartnerIdToCheck.contains(a.Partner_Id__c) && mySet.containskey(a.Partner_Id__c)) {
                a.Signature_Rep_Partnership_Opt_Out__c = mySet.get(a.partner_Id__c);
            }
        }
    }
    // ############################################################## END Update_SignatureRepPartnershipOptOut


    /**************************************************************************************************
    * @Case...................:  04018783                                                             *
    * @Discription............:  Update Account Trigger to Pull Count of Order                        *
    * @Param..................:  Account                                                              *
    * @Return.................:  NA                                                                   *
    * @Last Modified by.......:  eugenebasianomutya                                                   *
    * @Last Modified Date.....:  10/14/2015                                                            *
    **************************************************************************************************/

    public static Map<Id, Account> Update_Account_CountOfOrder(map<Id, Account> mAccount) {
        Map<Id, Account> result = new Map<Id, Account>();

        if (mAccount.isEmpty()) {
            return result;
        }

        //Get Orders
        map<Id, Integer> mNegativeDelta = new map<Id, Integer>();
        map<Id, Integer> mPositiveDelta = new map<Id, Integer>();
        integer iCurrentCount;

        List<Order__c> orderList = (List<Order__c>) new OrderCustomSelector()
                .selectOrdersWithinMonthByAccountIds(new List<Object>{mAccount.keySet()})
                .executeQuery();

        if (orderList.isEmpty()) {
            return result;
        }

        for (Order__c o : orderList) {

            if (o.MRS_Delta__c < 0) {
                if (mNegativeDelta != NULL) {
                    if (mNegativeDelta.containsKey(o.Account__c)) {
                        iCurrentCount = mNegativeDelta.get(o.Account__c) + 1;
                    } else {
                        iCurrentCount = 1;
                    }
                } else {
                    iCurrentCount = 1;
                }
                mNegativeDelta.put(o.Account__c, iCurrentCount);

            } else if (o.MRS_Delta__c > 0) {
                if (mPositiveDelta != NULL) {
                    if (mPositiveDelta.containsKey(o.Account__c)) {
                        iCurrentCount = mPositiveDelta.get(o.Account__c) + 1;
                    } else {
                        iCurrentCount = 1;
                    }
                } else {
                    iCurrentCount = 1;
                }
                mPositiveDelta.put(o.Account__c, iCurrentCount);
            }
        }

        for (Account a : mAccount.values()) {
            if (mNegativeDelta != null && mNegativeDelta.containsKey(a.Id)) {
                result.put(a.Id, a);
            }
            if (mPositiveDelta != null && mPositiveDelta.containsKey(a.Id)) {
                result.put(a.Id, a);
            }
        }
        return result;
    }

    // Case #04065723 - START
    public static void populateChannelManagerEmail(List<Account> accounts, Map<Id, User> userMap) {
        for (Account acc : accounts) {
            if (acc.Inside_Sales_Rep__c != null && userMap.containsKey(acc.Inside_Sales_Rep__c)) {
                acc.Channel_Manager_Email__c = userMap.get(acc.Inside_Sales_Rep__c).Email;
            } else {
                acc.Channel_Manager_Email__c = '';
            }
        }
    }
    // Case #04065723 - END

    /**************************************************************************************************
     * @Case...................:  05149600                                                            *
     * @Discription............:  CSM Assignment and Reporting                                        *
     * @Param..................:  Account                                                             *
     * @Return.................:  NA                                                                  *
     * @Last Modified by.......:  eugenebasianomutya                                                  *
     * @Last Modified Date.....:  10/14/2015                                                          *
     **************************************************************************************************/

    public static void setAccountTeamForCSM(Boolean isInsert, Map<Id, Account> oldAccMap, Map<Id, Account> newAccMap) {

        string CsmRole = 'Customer Success Manager (CSM)';

        AccountTeamMember[] lCsmToInsert = new AccountTeamMember[]{
        };
        AccountTeamMember[] lCsmToDelete = new AccountTeamMember[]{
        };
        AccountShare[] lAccSForUpdate = new AccountShare[]{
        };

        set<Id> sAccId = new set<Id>();
        set<Id> sAccIdOld = new set<Id>();
        set<Id> sUserId = new set<Id>();
        set<Id> sUserIdOld = new set<Id>();
        map<Id, Id> mAccIdUserId = new map<Id, Id>();
        map<Id, Id> mAccIdOwnerId = new map<Id, Id>();

        if (isInsert) {

            for (Account acc : newAccMap.values()) {
                if (acc.CSM__c != NULL) {

                    sAccId.add(acc.Id);
                    sUserId.add(acc.CSM__c);
                    mAccIdUserId.put(acc.Id, acc.CSM__c);
                    mAccIdOwnerId.put(acc.Id, acc.OwnerId);
                    lCsmToInsert.add(CreateCsmAccountTeam(acc, CsmRole));
                }
            }
            if (lCsmToInsert.size() > 0) {
                insert lCsmToInsert;

                for (AccountShare lAccS : [
                    SELECT Id, AccountId, AccountAccessLevel, CaseAccessLevel, ContactAccessLevel, OpportunityAccessLevel, RowCause
                    from AccountShare
                    WHERE AccountId IN:sAccId and UserOrGroupId IN:sUserId
                ]) {

                    if (mAccIdUserId.get(lAccS.AccountId) != NULL) {
                        if (mAccIdOwnerId.get(lAccS.AccountId) != mAccIdUserId.get(lAccS.AccountId)) {
                            if (lAccS.RowCause != 'Owner') {
                                AccountShare a = new AccountShare();
                                a.Id = lAccS.Id;
                                a.AccountAccessLevel = 'Edit';
                                a.CaseAccessLevel = 'Edit';
                                a.ContactAccessLevel = 'Edit';
                                a.OpportunityAccessLevel = 'Edit';
                                lAccSForUpdate.add(a);
                            }
                        }
                    }
                }

                if (lAccSForUpdate.size() > 0) {
                    update lAccSForUpdate;
                }
            }
        } else {

            map<Id, Id> mAccountUser = new map<Id, Id>();

            for (Account accNew : newAccMap.values()) {
                Account accOld = oldAccMap.get(accNew.Id);

                if (accOld.CSM__c != accNew.CSM__c) {

                    if (accNew.CSM__c != NULL) {

                        sAccId.add(accNew.Id);
                        sUserId.add(accNew.CSM__c);
                        mAccIdUserId.put(accNew.Id, accNew.CSM__c);
                        mAccIdOwnerId.put(accNew.Id, accNew.OwnerId);
                        lCsmToInsert.add(CreateCsmAccountTeam(accNew, CsmRole));
                    }
                    if (accOld.CSM__c != NULL) {
                        sAccIdOld.add(accOld.Id);
                        sUserIdOld.add(accOld.CSM__c);
                        mAccountUser.put(accOld.Id, accOld.CSM__c);
                    }
                }
            }

            if (mAccountUser.size() > 0) {
                for (AccountTeamMember atm : [
                    SELECT Id,AccountId,UserId
                    FROM AccountTeamMember
                    WHERE AccountId IN:sAccIdOld AND UserId IN:sUserIdOld AND TeamMemberRole = :CsmRole
                ]) {
                    if (mAccountUser.get(atm.AccountId) == atm.UserId) {
                        lCsmToDelete.add(atm);
                    }
                }
                if (lCsmToDelete.size() > 0) {
                    delete lCsmToDelete;
                }
            }

            if (lCsmToInsert.size() > 0) {
                insert lCsmToInsert;

                for (AccountShare lAccS : [
                    SELECT Id, AccountId, AccountAccessLevel, CaseAccessLevel, ContactAccessLevel, OpportunityAccessLevel, RowCause
                    from AccountShare
                    WHERE AccountId IN:sAccId and UserOrGroupId IN:sUserId
                ]) {

                    if (mAccIdUserId.get(lAccS.AccountId) != NULL) {
                        if (mAccIdOwnerId.get(lAccS.AccountId) != mAccIdUserId.get(lAccS.AccountId)) {
                            if (lAccS.RowCause != 'Owner') {
                                AccountShare a = new AccountShare();
                                a.Id = lAccS.Id;
                                a.AccountAccessLevel = 'Edit';
                                a.CaseAccessLevel = 'Edit';
                                a.ContactAccessLevel = 'Edit';
                                a.OpportunityAccessLevel = 'Edit';
                                lAccSForUpdate.add(a);
                            }
                        }
                    }
                }

                if (lAccSForUpdate.size() > 0) {
                    update lAccSForUpdate;
                }

            }
        }

    }

    /**************************************************************************************************
     * @Case...................:  05149600                                                            *
     * @Discription............:  CSM Assignment and Reporting                                        *
    ***************************************************************************************************/
    private static AccountTeamMember CreateCsmAccountTeam(Account acc, string sRole) {
        AccountTeamMember csm = new AccountTeamMember();
        csm.UserId = acc.CSM__c;
        csm.AccountId = acc.Id;
        csm.TeamMemberRole = sRole;
        return csm;
    }

    /*********************************************************************************************************
     * @Case...................:  05329077                                                                   *
     * @Discription............:  Update Channel Manager in Child Records when update on Partner Account     *
     * @Param..................:  Account, NewMap, OldMap                                                    *
     * @Return.................:  NA                                                                         *
     * @Last Modified by.......:  eugenebasianomutya                                                         *
     * @Last Modified Date.....:  01/19/2017                                                                 *
     ********************************************************************************************************/
    public static void updateChannelManager(Map<Id, Account> mAccountNew, Map<Id, Account> mAccountOld) {

        Map<String, Id> mAccPartnerIdChannelManager = new Map<String, Id>();
        List<Account> lCustomerAccountToUpdate = new List<Account>();
        List<Opportunity> lOpportunityToUpdate = new List<Opportunity>();
        List<Lead> lLeadToUpdate = new List<Lead>();

        for (Account a : mAccountNew.values()) {
            if (isPartnerAccount(a)
                && a.Partner_Hierarchy_Level__c == 'Reseller'
                && a.VAR_Territory__c != 'House') {
                if (a.Inside_Sales_Rep__c != mAccountOld.get(a.Id).Inside_Sales_Rep__c) {
                    mAccPartnerIdChannelManager.put(a.Partner_Id__c, a.Inside_Sales_Rep__c);
                }
            }
        }

        if (mAccPartnerIdChannelManager.size() > 0) {
            List<Account> customerAccounts = (List<Account>) new AccountSelector()
                .selectCustomerAccountsByPartnerIds(mAccPartnerIdChannelManager.keyset())
                .executeQuery();
            if (!customerAccounts.isEmpty()) {
                for (Account a : customerAccounts) {
                    if (!mAccPartnerIdChannelManager.containsKey(a.Partner_Id__c)) {
                        continue;
                    }

                    a.Inside_Sales_Rep__c = mAccPartnerIdChannelManager.get(a.Partner_Id__c);
                    lCustomerAccountToUpdate.add(a);
                }
            }
            if (lCustomerAccountToUpdate.size() > 0) {
                QueueableDMLExecuter.enqueueJob(
                    lCustomerAccountToUpdate,
                    QueueableDMLExecuter.DMLType.DML_UPDATE,
                    null,
                    new List<String>{'BY_PASS_ACCOUNT_ON_UPDATE'}
                );
            }

            Set<String> sOppStage = new Set<String> { OpportunityHelper.STAGE_NAME_DOWNGRADED };
            sOppStage.addAll(OpportunityHelper.STAGE_NAMES_CLOSED);

            for (Opportunity o : [SELECT Id, Partner_ID__c, Inside_Sales_Rep__c, StageName
                                    FROM Opportunity
                                    WHERE StageName NOT IN :sOppStage
                                    AND Partner_Id__c IN :mAccPartnerIdChannelManager.keyset()]) {
                if (mAccPartnerIdChannelManager.get(o.Partner_Id__c) != null) {
                    o.Inside_Sales_Rep__c = mAccPartnerIdChannelManager.get(o.Partner_Id__c);
                    lOpportunityToUpdate.add(o);
                }
            }
            if (lOpportunityToUpdate.size() > 0) {
                QueueableDMLExecuter.enqueueJob(
                    lOpportunityToUpdate,
                    QueueableDMLExecuter.DMLType.DML_UPDATE,
                    null,
                    new List<String>{'BY_PASS_OPPORTUNITY_ON_UPDATE'}
                );
            }

            Set<String> sLeadStatus = new Set<String>();
            sLeadStatus.add('0. Downgraded');
            for (Lead l : [SELECT Id, LeadPartnerID__c, Inside_Sales_Rep__c, Status
                            FROM Lead
                            WHERE Status NOT IN :sLeadStatus
                            AND isConverted = false
                            AND LeadPartnerID__c IN :mAccPartnerIdChannelManager.keyset()]) {
                if (mAccPartnerIdChannelManager.get(l.LeadPartnerID__c) != null) {
                    l.Inside_Sales_Rep__c = mAccPartnerIdChannelManager.get(l.LeadPartnerID__c);
                    lLeadToUpdate.add(l);
                }
            }
            if (lLeadToUpdate.size() > 0) {
                QueueableDMLExecuter.enqueueJob(
                    lLeadToUpdate,
                    QueueableDMLExecuter.DMLType.DML_UPDATE,
                    null,
                    new List<String>{'BY_PASS_LEAD_UPDATE'}
                );
            }

        }
    }
    private static Boolean shouldUpdateCustomerProfileLastModifiedDate(Account accObj, Account oldAccObj) {
        return accObj.Website != oldAccObj.Website
            || accObj.Number_of_Locations__c != oldAccObj.Number_of_Locations__c
            || accObj.NumberOfEmployees != oldAccObj.NumberOfEmployees
            || accObj.No_of_Employees__c != oldAccObj.No_of_Employees__c
            || accObj.Industry != oldAccObj.Industry
            || accObj.Is_the_customer_interested_in_porting__c != oldAccObj.Is_the_customer_interested_in_porting__c;
    }

    private static Boolean shouldValidatePhoneNumber(Account newAccount, Account oldAccount) {
        return arePhoneAndBillingCountryNotNull(newAccount)
            && (newAccount.Phone != oldAccount.Phone || newAccount.billingCountry != oldAccount.billingCountry);
    }

    private static Boolean arePhoneAndBillingCountryNotNull(Account acc) {
        return acc.Phone != null && acc.billingCountry != null;
    }

    private static Boolean isCustomerAccountWithType(Account acc) {
        return acc.Type == AccountHelper.TYPE_CUSTOMER && isCustomerAccount(acc);
    }

    private static Boolean isCustomerAccount(Account acc) {
        return acc.RecordTypeId == AccountHelper.RT_ID_CUSTOMER_ACCOUNT;
    }

    private static Boolean isPartnerAccount(Account acc) {
        return acc.RecordTypeId == AccountHelper.RT_ID_PARTNER_ACCOUNT;
    }

    private static Boolean isAcntSplitFound(Map<Id, Account_Split__c> accountToAccSplitMap, Account acc) {
        return !accountToAccSplitMap.isEmpty() && accountToAccSplitMap.containsKey(acc.id) && accountToAccSplitMap.get(acc.id) != null;
    }
}