@RestResource(urlMapping='/SyncAccountWsBilling/*')
global class SyncAccountWsBilling {

    // Some Integrated Services use SOAP version of this webservice and some JSON REST
    @HttpPost
    global static void handleRequest() {
        if (RestContext.response == null) {
            RestContext.response = new RestResponse();
        }
        Object resp = null;

        String body = RestContext.request.requestBody.toString();
        RequestParams params;
        params = (RequestParams) JSON.deserialize(body, RequestParams.class);
        switch on params.action {
            when 'applyBillingIdAndPackages' {
                resp = applyBillingIdAndPackages(params.billingAcctInfo);
            }
            when 'synAccountNew' {
                resp = synAccountNew(params.syncAcctInputParamBilling);
            }
            when 'synAccountCreateUser' {
                resp = synAccountCreateUser(params.syncAcctInputParamBilling);
            }
        }
        RestContext.response.responseBody = Blob.valueOf(JSON.serialize(resp));
    }

    public class RequestParams {
        public String action;

        public BillingAcctInfo billingAcctInfo;
        public syncAcctInputParamBilling syncAcctInputParamBilling;
    }

    public static final String ACCOUNT_TIER_NAME_FAX = 'Fax';

    global class BillingAcctInfo {
        webservice String rcUserID;
        webservice String billingID;
        webservice List<PackageWrapper> serviceAccounts = new List<PackageWrapper>();
    }

    global class PackageWrapper {
        webservice String accountPackageId;
        webservice String duration;
        webservice String offerType;
        webservice String packageCatalogId;
        webservice String packageName;
        webservice String packageVersion;
        webservice String serviceAccountId;
        webservice Boolean isActive;
        webservice Integer numberOfPrimaryUserLicenses;
        webservice List<License_Item> licenses = new List<License_Item>();
    }

    global class License_Item {
        webservice String licenseId;
        webservice Integer licencesPurchased;
        webservice Integer licensesAssigned;

        public License_Item(String initLicenseId,Integer initLicensesPurchased,Integer initLicensesAssigned) {
            licenseId = initLicenseId;
            licencesPurchased = initLicensesPurchased;
            licensesAssigned = initLicensesAssigned;
        }
    }

    global class SyncResult {
        webservice String accountID;
        webservice String errorMsg;
        webservice List<Warning> warnings = new List<Warning>();
        webservice List<ServiceAccountUpsertResult> serviceAccounts = new List<ServiceAccountUpsertResult>();
    }

    global class Warning {
        webservice String description;
        webservice Integer code;

        public Warning(String initDescription,Integer initCode) {
            description=initDescription;
            code=initCode;
        }
    }

    global class ServiceAccountUpsertResult {
        webservice Boolean isCreated;
        webservice PackageWrapper processedPackage;

        public ServiceAccountUpsertResult(Boolean initIsCreated,PackageWrapper initProcessedPackage) {
            isCreated = initIsCreated;
            processedPackage = initProcessedPackage;
        }
    }

    public final static String BILLING_ID_FIELD = 'Billing_ID__c';
    public final static String RC_USER_ID_FIELD = 'RC_User_ID__c';
    public final static String REMOVE_PACKAGES_PLACEHOLDER = 'remove';
    public final static String UPSERT_PACKAGES_PLACEHOLDER = 'upsert';
    public final static String ACCOUNT_ERROR_PREFIX = 'Account Update Failed:';
    public final static String PACKAGE_ERROR_PREFIX = 'Package Update Failed:';

    // this is used to bypass queuing unnecessary async jobs during QTC-227 Legacy CC Migration process
    @TestVisible
    private static Boolean IS_ACCOUNT_FOR_LEGACY_CC_MIGRATION_PROCESSING = false;

    webservice static SyncResult applyBillingIdAndPackages(BillingAcctInfo vsyncAcctInputParam) {
        SyncResult result = new SyncResult();
        Map<String, List<Package__c>> packagesByOperation;

        Account foundSingleAccount = searchAndValidateAccountInfo(vsyncAcctInputParam, result);

        Boolean isAccContainsMigrationFlag = AccountHelper.MIGRATION_STATUSES.contains(foundSingleAccount?.AccMigrationFlag__c);
        if (foundSingleAccount != null) {
            try {
                packagesByOperation = updateAccount(foundSingleAccount, vsyncAcctInputParam, result, isAccContainsMigrationFlag);
            } catch (Exception e) {
                result.errorMsg = ACCOUNT_ERROR_PREFIX + ' ' + e.getMessage();
                return result;
            }

            Savepoint sp = Database.setSavepoint();
            try {
                if (!isAccContainsMigrationFlag) {
                    updatePackages(packagesByOperation, vsyncAcctInputParam, result);
                }
            } catch(Exception e) {
                result.serviceAccounts.clear();
                result.errorMsg = PACKAGE_ERROR_PREFIX + ' ' + e.getMessage();
                Database.rollback(sp);
            }
        }

        return result;
    }

    public static void updatePackages(Map<String, List<Package__c>> packagesByOperation, BillingAcctInfo infoToUpdateWith, SyncResult syncResultOutput) {
        Map<String, PackageWrapper> initialPackageMap = new Map<String, PackageWrapper>();

        if (infoToUpdateWith != null && infoToUpdateWith.serviceAccounts != null) {
            for (PackageWrapper currentWrapper : infoToUpdateWith.serviceAccounts) {
                initialPackageMap.put(currentWrapper.accountPackageId, currentWrapper);
            }
        }

        if (packagesByOperation != null) {
            DataBase.UpsertResult[] packageUpsertResults=Database.upsert(packagesByOperation.get(UPSERT_PACKAGES_PLACEHOLDER), Package__c.Fields.Account_Package_Id__c, true);

            for (integer i=0; i < packageUpsertResults.size(); i++) {
                if (initialPackageMap.containsKey(packagesByOperation.get(UPSERT_PACKAGES_PLACEHOLDER)[i].Account_Package_Id__c)) {
                    syncResultOutput.serviceAccounts.add(
                        new ServiceAccountUpsertResult(
                            packageUpsertResults[i].isCreated(),
                            initialPackageMap.get(packagesByOperation.get(UPSERT_PACKAGES_PLACEHOLDER)[i].Account_Package_Id__c)
                        )
                    );
                }
            }

            Database.DeleteResult[] drList = Database.delete(packagesByOperation.get(REMOVE_PACKAGES_PLACEHOLDER), true);
        }
    }

    public static Map<String, List<Package__c>> updateAccount(Account accountToUpdate, BillingAcctInfo infoToUpdateWith, SyncResult syncResultOutput, Boolean isAccContainsMigrationFlag) {
        Map<String, List<Package__c>> result = new Map<String, List<Package__c>> {
            REMOVE_PACKAGES_PLACEHOLDER => new List<Package__c>(),
            UPSERT_PACKAGES_PLACEHOLDER => new List<Package__c>()
        };

        if (accountToUpdate.Billing_ID__c != null && accountToUpdate.Billing_ID__c != infoToUpdateWith.billingID) {
            syncResultOutput.warnings.add(new Warning(Label.AccountHasDifferentBillingId, 1));
        }
        if (accountToUpdate.RC_User_ID__c != null && accountToUpdate.RC_User_ID__c != infoToUpdateWith.rcUserID) {
            syncResultOutput.warnings.add(new Warning(Label.AccountHasDifferentEnterpriseId, 2));
        }

        Boolean isBillingIdChanged = accountToUpdate.Billing_ID__c != infoToUpdateWith.billingID;
        accountToUpdate.Billing_ID__c = infoToUpdateWith.billingID;
        accountToUpdate.RC_User_ID__c = infoToUpdateWith.rcUserID;
        accountToUpdate.Licenses_Purchased__c = 0;
        accountToUpdate.Offer_Type__c = '';

        List<Package__c> existingPackages = (List<Package__c>) new PackageSelector()
            .selectPackagesByAccountId(accountToUpdate.Id)
            .executeQuery();
        Map<String, Package__c> accountPackageIdToPackage = new Map<String, Package__c>();
        for (Package__c currentPackage : existingPackages) {
            accountPackageIdToPackage.put(currentPackage.Account_Package_Id__c, currentPackage);
        }

        if (infoToUpdateWith?.serviceAccounts != null && !isAccContainsMigrationFlag) {
            for (PackageWrapper currentPackageWrapper : infoToUpdateWith.serviceAccounts) {
                if (currentPackageWrapper == null) {
                    continue;
                }
                Package__c tempPackage = packageWrapperToPackage(currentPackageWrapper, accountToUpdate);
                if (!currentPackageWrapper.isActive && accountPackageIdToPackage.containsKey(tempPackage.Account_Package_Id__c)) {
                    result.get(REMOVE_PACKAGES_PLACEHOLDER).add(accountPackageIdToPackage.get(tempPackage.Account_Package_Id__c));
                    accountPackageIdToPackage.remove(tempPackage.Account_Package_Id__c);
                } else if (currentPackageWrapper.isActive) {
                    result.get(UPSERT_PACKAGES_PLACEHOLDER).add(tempPackage);
                    accountPackageIdToPackage.put(tempPackage.Account_Package_Id__c, tempPackage);
                }
            }
        }

        for (Package__c currentPackage : accountPackageIdToPackage.values()) {
            accountToUpdate.Offer_Type__c = currentPackage.Offer_Type__c;
            accountToUpdate.Licenses_Purchased__c = currentPackage.Licenses_Purchased__c;
        }

        update accountToUpdate;

        syncResultOutput.accountID = accountToUpdate.Id;

        return result;
    }

    public static Account searchAndValidateAccountInfo(BillingAcctInfo vsyncAcctInputParam, SyncResult syncResultOutput) {
        Account result;
        if (vsyncAcctInputParam == null || vsyncAcctInputParam.billingID == null || vsyncAcctInputParam.rcUserID == null) {
            syncResultOutput.errorMsg = 'Billing Id and Enterprise Account Id are required';
            return result;
        }

        List<Account> foundAccounts = (List<Account>) new AccountSelector()
            .selectAccountsByBillingIdOrRCUserId(vsyncAcctInputParam.billingID, vsyncAcctInputParam.rcUserID)
            .executeQuery();

        Map<String,List<Account>> accountMatchesByMatchedField = new Map<String, List<Account>> {
            BILLING_ID_FIELD => new List<Account>(),
            RC_USER_ID_FIELD => new List<Account>()
        };

        for (Account currentAccount : foundAccounts) {
            if (currentAccount.Billing_ID__c == vsyncAcctInputParam.billingID) {
                accountMatchesByMatchedField.get(BILLING_ID_FIELD).add(currentAccount);
            }
            if (currentAccount.RC_User_ID__c == vsyncAcctInputParam.rcUserID) {
                accountMatchesByMatchedField.get(RC_USER_ID_FIELD).add(currentAccount);
            }
        }

        if (accountMatchesByMatchedField.get(BILLING_ID_FIELD).size() == 1) {
            result = accountMatchesByMatchedField.get(BILLING_ID_FIELD)[0];
        } else if (accountMatchesByMatchedField.get(BILLING_ID_FIELD).size() == 0 && accountMatchesByMatchedField.get(RC_USER_ID_FIELD).size() == 1) {
            result = accountMatchesByMatchedField.get(RC_USER_ID_FIELD)[0];
        } else if (accountMatchesByMatchedField.get(BILLING_ID_FIELD).size() > 1) {
            syncResultOutput.errorMsg = 'More than 1 Account with matching Billing Id found';
        } else if (accountMatchesByMatchedField.get(RC_USER_ID_FIELD).size() > 1) {
            syncResultOutput.errorMsg = 'More than 1 Account with matching Enterprise Account Id found';
        } else {
            syncResultOutput.errorMsg = 'Matching Account not found';
        }

        return result;
    }

    public static Package__c packageWrapperToPackage(PackageWrapper packageToProcess, Account foundAccount) {
        Package__c result = new Package__c(
            Account_Package_Id__c = packageToProcess.accountPackageId,
            Offer_Type__c = packageToProcess.offerType,
            Package_Catalog_Id__c = packageToProcess.packageCatalogId,
            Package_Name__c = packageToProcess.packageName,
            Package_Version__c = packageToProcess.packageVersion,
            NumberOfPrimaryUserLicenses__c = packageToProcess.numberOfPrimaryUserLicenses,
            Enterprise_Account_ID__c = foundAccount.Id
        );

        if (foundAccount.Master_Account__c != null && foundAccount.IsMultiProductTechnicalAccount__c) {
            result.Account__c = foundAccount.Master_Account__c;
        } else {
            result.Account__c = foundAccount.id;
        }

        if (packageToProcess.serviceAccountId != null) {
            result.Name=packageToProcess.serviceAccountId;
        }

        if (packageToProcess.licenses != null) {
            result.Licenses_Purchased__c = 0;

            for (License_Item currentLicense:packageToProcess.licenses) {
                if(currentLicense.licencesPurchased != null) {
                    result.Licenses_Purchased__c += currentLicense.licencesPurchased;
                }
            }
        }

        return result;
    }
//DWH Sync End
//SignUp Sync Start

    //Define an object in apex that is exposed in apex web service
    global class syncAcctInputParamBilling{
        /*InPut*/
        webservice String In_OpportunityID;
        webservice String In_RCUserID;
        webservice String In_RCPrimaryNumber;
        webservice String In_Company;
        webservice String In_FirstName;
        webservice String In_LastName;
        webservice String In_ContactEmail;
        webservice string In_Contactphone;
        webservice string In_RCBRAND;
        webservice string In_SUBBRAND;
        webservice string In_Partner_Deal_Registration_Id;
        webservice string In_Bandwidth_Test_Id;
        webservice Decimal In_Bandwidth_MOS_Score;
        webservice Decimal In_Bandwidth_Num_Sim_Calls;
        webservice Boolean In_Porting_Numbers;

        /*New Field added*/
        webservice string In_SignupType ;
        webservice string In_SignupPlatform;

        /*New fields added, 23/06/2011 */
        webservice string In_SERVICENAME;
        webservice string In_TIERNAME;
        /*New fields added, 28/06/2011 */
        webservice string In_Attribute_Key_01;
        webservice string In_Attribute_Value_01;
        webservice string In_Attribute_Key_02;
        webservice string In_Attribute_Value_02;
        webservice string In_Attribute_Key_03;
        webservice string In_Attribute_Value_03;
        webservice string In_Attribute_Key_04;
        webservice string In_Attribute_Value_04;
        webservice string In_Attribute_Key_05;
        webservice string In_Attribute_Value_05;
        /*new fields added 07/12/2017*/
        webservice string In_BillingID;
        webservice List<Package__c> serviceAccounts=new List<Package__c>();
        /*new fields added 05/04/2018*/
        webservice String In_AccountID;
        webservice String In_ContactID;
        /*New field added, 14/04/2020 */
        webservice string In_Industry;

        /* Engage Voice & Digital */
        webservice String In_EngageAccountId;

        /* Engage Voice */
        webservice String In_EVAccountId;
        webservice String In_EVPlatform;

        /* Engage Digital */
        webservice String In_EDAccountId;
        webservice String In_EDDomainId;
        webservice String In_EDPlatform;

        /*OutPut*/
        webservice String Out_AccountID;
        webservice String Out_ContactID;
        webservice String Out_UserID;
        webservice String OutErrorMsg='';

        /*Processing*/
        webservice String proc_AccountId;
        webservice String proc_ContactId;
        webservice String proc_UserId;
        webservice String proc_UserRecCreation;
        webservice String proc_debugmsg;
        webservice String proc_BillingId;

        public List<Contact> searchContact;
        public List<Lead> searchlead;
    }

    public SyncAccountWsBilling() {}

webservice static syncAcctInputParamBilling synAccountNew(syncAcctInputParamBilling vsyncAcctInputParam) {
         //handleCreateAccount(vsyncAcctInputParam);
    if (vsyncAcctInputParam.In_AccountID != null || vsyncAcctInputParam.In_ContactID != null) {
        initializeIds(vsyncAcctInputParam);
        if (vsyncAcctInputParam.In_AccountID != null) {
            handleUpdateAccount(vsyncAcctInputParam);
        }
        if (vsyncAcctInputParam.In_ContactID != null) {
            handleUpdateContact(vsyncAcctInputParam);
        }
        handleReturn(vsyncAcctInputParam);
    } else if (searchAccountByUID(vsyncAcctInputParam) == true) {
        if (handleUpdateAccount(vsyncAcctInputParam) == true) {
            /*Block*/
            if (accountMatchingContactEmail(vsyncAcctInputParam) == true) {
                if (contactHavingUserRecord(vsyncAcctInputParam) == true) {
                    handleReturn(vsyncAcctInputParam);
                } else {
                    if (handleCreateUser(vsyncAcctInputParam) == true) {
                        handleReturn(vsyncAcctInputParam);
                    }
                }
            } else {
                if (handleCreateContact(vsyncAcctInputParam) == true) {
                    if (handleCreateUser(vsyncAcctInputParam) == true) {
                        handleReturn(vsyncAcctInputParam);
                    }
                }
            }
        }
        /*Block*/
    } else {
        if (vsyncAcctInputParam.In_OpportunityID != null && vsyncAcctInputParam.In_OpportunityID != '') {
            if (searchOppertunityByOID(vsyncAcctInputParam) == true) {
                if (handleUpdateAccount(vsyncAcctInputParam) == true) {
                    /*Block*/
                    if (accountMatchingContactEmail(vsyncAcctInputParam) == true) {
                        if (contactHavingUserRecord(vsyncAcctInputParam) == true) {
                            handleReturn(vsyncAcctInputParam);
                        } else {
                            if (handleCreateUser(vsyncAcctInputParam) == true) {
                                handleReturn(vsyncAcctInputParam);
                            }
                        }
                    } else {
                        if (handleCreateContact(vsyncAcctInputParam) == true) {
                            if (handleCreateUser(vsyncAcctInputParam) == true) {
                                handleReturn(vsyncAcctInputParam);
                            }
                        }
                    }
                    /*Block*/
                } else {
                    handleReturn(vsyncAcctInputParam);
                }
            }
        } else if (searchContactByMailForFax(vsyncAcctInputParam) == true) {
            if (handleUpdateAccount(vsyncAcctInputParam) == true) {
                /*Block*/
                if (accountMatchingContactEmail(vsyncAcctInputParam) == true) {
                    if (contactHavingUserRecord(vsyncAcctInputParam) == true) {
                        handleReturn(vsyncAcctInputParam);
                    } else {
                        if (handleCreateUser(vsyncAcctInputParam) == true) {
                            handleReturn(vsyncAcctInputParam);
                        }
                    }
                } else {
                    if (handleCreateContact(vsyncAcctInputParam) == true) {
                        if (handleCreateUser(vsyncAcctInputParam) == true) {
                            handleReturn(vsyncAcctInputParam);
                        }
                    }
                }
                /*Block*/
            } else {
                handleReturn(vsyncAcctInputParam);
            }
        } else {
            if (handleCreateAccount(vsyncAcctInputParam) == true) {
                if (handleCreateContact(vsyncAcctInputParam) == true) {
                    if (handleCreateUser(vsyncAcctInputParam) == true) {
                        handleReturn(vsyncAcctInputParam);
                    }
                }
            }
        }
    }

    return vsyncAcctInputParam;
   }

    public static String deNullifyString(String inputString) {
        return (inputString == null ? '' : inputString);
    }

    webservice static syncAcctInputParamBilling synAccountCreateUser(syncAcctInputParamBilling vsyncAcctInputParam) {
        String strGetIn_FirstName = vsyncAcctInputParam.In_FirstName;
        String strGetIn_ContactEmail = vsyncAcctInputParam.In_ContactEmail;

        /*Logic to get USRID

        Community nick name = email user name + user Id email id is validated per null or @ string, if it is not found,
        returns as input string else, split into Strings per @, provided that it is available in email, else we take an empty '' string.

        */
        String contactEmail = vsyncAcctInputParam.In_ContactEmail;
        String community_Nick_Name =
                (contactEmail != null && (contactEmail).indexOf('@') != -1
                        ? ((contactEmail.trim()).indexOf('@') == 0
                                ? ''
                                : (contactEmail).split('@')[0])
                        : contactEmail)
                        + deNullifyString(vsyncAcctInputParam.In_RCUserID);


        Integer resultUserNameLen = 0;
        String proc_EmailWORCUSERID = vsyncAcctInputParam.In_ContactEmail;
        String proc_EmailWithRCUSERID = deNullifyString(vsyncAcctInputParam.In_RCUserID) + vsyncAcctInputParam.In_ContactEmail;

        if (vsyncAcctInputParam.proc_UserRecCreation == '-1') {
            resultUserNameLen = proc_EmailWithRCUSERID.length();
            proc_EmailWithRCUSERID = proc_EmailWithRCUSERID.replace('@','.');
            if (resultUserNameLen > 70)
            {
                proc_EmailWithRCUSERID = proc_EmailWithRCUSERID.substring(0, 70);
            }
            proc_EmailWithRCUSERID = proc_EmailWithRCUSERID+'@rc.com';

            /**/

            /*
            If User found then return the userid
            */
            List<User> objUser = new List<User>();
            List<Contact> objContact = [
                    SELECT Id
                    FROM Contact
                    WHERE email =:vsyncAcctInputParam.In_ContactEmail
                        AND Account.Billing_ID__c=:vsyncAcctInputParam.In_BillingID
            ];
            if (objContact.size() > 0) {
                objUser = [
                        SELECT Id
                        FROM User
                        WHERE ContactId =: objContact[0].Id
                            AND ProfileId IN: SyncAccountWs.PROFILE_IDS_OF_PORTAL_USERS
                            AND IsActive = true
                        ORDER BY ProfileId ASC
                ];
                if (objUser.size() > 0) {
                    vsyncAcctInputParam.proc_UserId = objUser[0].Id;
                    handleReturn(vsyncAcctInputParam);
                    return vsyncAcctInputParam;
                }
            }

            /* Create New USER*/
            try {
                Integer result = strGetIn_FirstName.length();
                if (result > 8)
                {
                    strGetIn_FirstName = strGetIn_FirstName.substring(0, 8);
                }
                String strCommunityNickname=community_Nick_Name+system.Now().getTime();

                User u = new User(alias = strGetIn_FirstName,
                        Email= proc_EmailWORCUSERID,
                        Emailencodingkey = 'UTF-8',
                        Lastname = vsyncAcctInputParam.In_LastName,
                        Languagelocalekey = 'en_US',
                        Localesidkey = 'en_US',
                        Profileid = SyncAccountWS.PROFILE_ID_FOR_NEW_PORTAL_USERS,
                        ContactId = vsyncAcctInputParam.proc_ContactId,
                        Timezonesidkey='America/Los_Angeles',
                        Username = proc_EmailWithRCUSERID+system.Now().getTime(),
                        CommunityNickname = (strCommunityNickname.length() > 40 ? strCommunityNickname.substring(0,38): strCommunityNickname)
                );
                insert u;
                vsyncAcctInputParam.proc_UserId = u.Id;
                handleReturn(vsyncAcctInputParam);
            } catch (Exception ex) {
                vsyncAcctInputParam.outErrorMsg += ' Error while creating user :: ' + ex.getMessage();
                System.debug(ex.getMessage());
            }
        }

        return vsyncAcctInputParam;
    }

    public static Boolean searchAccountByUID(syncAcctInputParamBilling vsyncAcctInputParam) {
        Feature_Toggle__c featureToggle = Feature_Toggle__c.getInstance();
        try {
            vsyncAcctInputParam.proc_debugmsg += 'IN searchAccountByUID::';
            List<Account> searchAccount = new List<Account>();
            if (featureToggle.RC_User_Id_Sync__c == true && String.isNotBlank(vsyncAcctInputParam.In_RCUserID)) {
                searchAccount = getAccountByRCUserId(vsyncAcctInputParam.In_RCUserID);
            } else if (String.isNotBlank(vsyncAcctInputParam.In_BillingID)) {
                searchAccount = (List<Account>) [
                    SELECT Id, name,phone,Billing_ID__c, IsMultiProductTechnicalAccount__c, Master_Account__c
                    FROM Account
                    WHERE Billing_ID__c= :vsyncAcctInputParam.In_BillingID
                ];
            }
            if (searchAccount.size() == 0 && String.isNotBlank(vsyncAcctInputParam.In_RCUserID)) {
                searchAccount = getAccountByRCUserId(vsyncAcctInputParam.In_RCUserID);
            }

            if (searchAccount.size() > 0) {
                vsyncAcctInputParam.proc_AccountId = searchAccount[0].Id;
                vsyncAcctInputParam.proc_BillingId = searchAccount[0].Billing_ID__c;
                return true;
            } else {
                return false;
            }
        } catch (Exception ex) {
            vsyncAcctInputParam.OutErrorMsg = 'searchAccountByUID:: '+ex.getMessage();
            return false;
        }
        return true;
    }

    @TestVisible
    private static List<Account> getAccountByRCUserId(String rcUserId) {
        return [
            SELECT Id, Name, Phone, RC_user_Id__c, Billing_ID__c, IsMultiProductTechnicalAccount__c, Master_Account__c
            FROM Account
            WHERE RC_User_ID__c = :rcUserId
            OR Internal_Enterprise_Account_ID__c = :rcUserId
        ];
    }

    public static Boolean searchContactandLeadByDealId(syncAcctInputParamBilling vsyncAcctInputParam) {
        try {
            String PartnerDealId = vsyncAcctInputParam.In_Partner_Deal_Registration_Id;
            Decimal decPartnerDealId = Decimal.valueOf(PartnerDealId);
            List<Contact> lstContact = [SELECT Id, AccountId FROM Contact WHERE PartnerDeal_Registration_Id__c = :decPartnerDealId AND AccountId != NULL ORDER BY CreatedDate DESC limit 1];
            if (lstContact != null && lstContact.size() > 0) {
                vsyncAcctInputParam.searchContact = lstContact;
                return true;
            } else {
                List<Lead> lstLead = [SELECT Id FROM Lead WHERE PartnerDeal_Registration_Id__c = :decPartnerDealId AND IsConverted=false ORDER BY CreatedDate DESC LIMIT 1];
                if (lstLead != null && lstLead.size() > 0) {
                    vsyncAcctInputParam.searchlead = lstLead;
                    return true;
                }
            }
        } catch (Exception ex) {
            vsyncAcctInputParam.OutErrorMsg = 'searchContactandLeadByDealId:: '+ex.getMessage();
            return false;
        }
        return false;
    }

    public static Boolean searchOppertunityByOID(syncAcctInputParamBilling vsyncAcctInputParam) {
        try {
            vsyncAcctInputParam.proc_debugmsg += 'IN searchOppertunityByOID::';
            system.debug('vsyncAcctInputParam.In_OpportunityID: ' + vsyncAcctInputParam.In_OpportunityID);
            List<Opportunity> searchopportunity = [SELECT name,AccountId,Id ,StageName FROM Opportunity
            WHERE Id=:vsyncAcctInputParam.In_OpportunityID
            AND Account.RC_Sync_Status__c != 'In Sync'
            AND Account.Billing_ID__c = NULL Order by createddate desc limit 1];
            if (searchopportunity.size() > 0) {
                vsyncAcctInputParam.proc_AccountId = searchopportunity[0].AccountId;
            } else {
                return false;
            }

            return true;
        } catch (Exception ex) {
            vsyncAcctInputParam.OutErrorMsg = 'searchOppertunityByOID:: '+ex.getMessage();
            return false;
        }
        return true;
    }

    public static Boolean searchContactByMailForFax(syncAcctInputParamBilling vsyncAcctInputParam) {
        try {
            if (vsyncAcctInputParam.proc_debugmsg == null) {
                vsyncAcctInputParam.proc_debugmsg = '';
            }
            vsyncAcctInputParam.proc_debugmsg += 'IN searchContactByMail::';

            Boolean isFaxTier = vsyncAcctInputParam != null && !String.isBlank(vsyncAcctInputParam.In_TIERNAME) &&
                vsyncAcctInputParam.In_TIERNAME.containsIgnoreCase(ACCOUNT_TIER_NAME_FAX);
            if (!isFaxTier) {
                vsyncAcctInputParam.proc_debugmsg += 'The In_TIERNAME parameter is not a fax; ' +
                    'contact email searches will be skipped.::';
                return false;
            }

            Contact con = searchContactByEmail(vsyncAcctInputParam.In_ContactEmail);
            vsyncAcctInputParam.proc_AccountId = con.AccountId;
            vsyncAcctInputParam.proc_ContactId = con.Id;
            return true;

        } catch (SearchContactException ex) {
            vsyncAcctInputParam.OutErrorMsg = 'searchContactByMail:: ' + ex.getMessage();
            vsyncAcctInputParam.proc_debugmsg += 'SearchContactException: ' + ex.getMessage();
            return false;
        } catch (Exception ex) {
            vsyncAcctInputParam.OutErrorMsg = 'searchContactByMail:: ' + ex.getMessage();
            vsyncAcctInputParam.proc_debugmsg += 'Exception: ' + ex.getMessage();
            return false;
        }
    }

    private class SearchContactException extends Exception {}

    @TestVisible
    private static Contact searchContactByEmail(String contactEmail) {

        if (String.isBlank(contactEmail)) {
            throw new SearchContactException('Email is blank');
        }

        List<Contact> contactsList = (List<Contact>) new ContactSelector()
            .selectContactForSignUpSync(contactEmail)
            .executeQuery();

        List<Contact> customerAccountContacts = new List<Contact>();
        List<Contact> otherAccountContacts = new List<Contact>();
        for (Contact con : contactsList) {
            if (con.Account.RecordTypeId == AccountHelper.RT_ID_CUSTOMER_ACCOUNT) {
                customerAccountContacts.add(con);
            } else {
                otherAccountContacts.add(con);
            }
        }

        Contact resultContact = null;

        if (customerAccountContacts.size() == 1) {
            resultContact = customerAccountContacts.get(0);
        } else if (customerAccountContacts.size() > 1) {

            Map<Id, List<Opportunity>> accIdToOppListMap = getAccountIdToOpportunityListMap(customerAccountContacts);

            for (Contact con : customerAccountContacts) {
                if (accIdToOppListMap.containsKey(con.AccountId) && !accIdToOppListMap.get(con.AccountId).isEmpty()) {
                    resultContact = con;
                    break;
                }
            }

        } else {
            if (!otherAccountContacts.isEmpty()) {
                resultContact = otherAccountContacts.get(0);
            } else {
                throw new SearchContactException('Contact with Email "' + contactEmail + '" not found::');
            }
        }

        return resultContact;
    }

    private static Map<Id, List<Opportunity>> getAccountIdToOpportunityListMap(List<Contact> contactsList) {
        Map<Id, List<Opportunity>> accIdToOppListMap = new Map<Id, List<Opportunity>>();
        if (contactsList == null || contactsList.isEmpty()) {
            return accIdToOppListMap;
        }

        Set<Id> accIdSet = new Set<Id>();
        for (Contact con : contactsList) {
            accIdSet.add(con.AccountId);
        }

        List<Opportunity> oppList = (List<Opportunity>) new OpportunitySelector()
            .selectOpportunitiesForSignUpSync(accIdSet)
            .executeQuery();

        for (Opportunity opp : oppList) {
            if (!accIdToOppListMap.containsKey(opp.AccountId)) {
                accIdToOppListMap.put(opp.AccountId, new List<Opportunity>());
            }
            accIdToOppListMap.get(opp.AccountId).add(opp);
        }

        return accIdToOppListMap;
    }

    public static Boolean searchContactByMail(syncAcctInputParamBilling vsyncAcctInputParam) {
        try {
            vsyncAcctInputParam.proc_debugmsg += 'IN searchContactByMail::';
            system.debug('vsyncAcctInputParam.In_ContactEmail: ' + vsyncAcctInputParam.In_ContactEmail);
            Id accRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer Account')
                .getRecordTypeId();
            List<Contact> searchcontact = (List<Contact>)[Select Id, name ,email,phone,AccountId  from
                    Contact where email =:vsyncAcctInputParam.In_ContactEmail AND
            Account.Billing_ID__c = NULL AND Account.RecordTypeId =: accRecordTypeId Order by CreatedDate desc];

            if (searchcontact.size() == 1) {
                vsyncAcctInputParam.proc_AccountId = searchcontact[0].AccountId;
                vsyncAcctInputParam.proc_ContactId = searchcontact[0].Id;
                return true;
            }else if (searchcontact.size() > 1) {
                Id rcId = OpportunityHelper.getOppRecordTypeMap('Sales Opportunity');
                Map<Id, List<Opportunity>> opptysByAccountId = new Map<Id, List<Opportunity>>();
                List<Opportunity> allOptys = [SELECT Account.id FROM Opportunity WHERE RecordTypeId  =: rcId OR RecordTypeId = NULL];
                for(Opportunity opty: allOptys) {
                    if (!opptysByAccountId.containsKey(opty.Account.Id)) {
                        opptysByAccountId.put(opty.Account.Id, new List<Opportunity>());
                    }
                    opptysByAccountId.get(opty.Account.Id).add(opty);
                }
                for(Contact con: searchcontact)
                {
                    List<Opportunity> opp = opptysByAccountId.get(con.AccountId);
                    if (opp.size() > 0)
                    {
                        vsyncAcctInputParam.proc_AccountId = con.AccountId;
                        vsyncAcctInputParam.proc_ContactId = con.Id;
                        return true;
                    }
                }
                /*If no account found having oppertunity then return with latest record. Do query and assign*/
                List<Contact> searchcontactLT = (List<Contact>)[Select Id, name ,email,phone,AccountId  from
                        Contact where email =:vsyncAcctInputParam.In_ContactEmail AND
                Account.Billing_ID__c = NULL Order by CreatedDate desc limit 1];

                if (searchcontactLT != null && searchcontactLT.size() != 0) {
                    vsyncAcctInputParam.proc_AccountId = searchcontactLT[0].AccountId;
                    vsyncAcctInputParam.proc_ContactId = searchcontactLT[0].Id;
                } else {
                    return false;
                }
                return true;
            } else {
                return false;
            }
        } catch (Exception ex) {
            vsyncAcctInputParam.OutErrorMsg = 'searchContactByMail:: '+ex.getMessage();
            return false;
        }
        return true;
    }

    public static Boolean searchLeadByEmail(syncAcctInputParamBilling vsyncAcctInputParam) {
        try {
            vsyncAcctInputParam.proc_debugmsg += 'IN searchLeadByEmail::';
            system.debug('vsyncAcctInputParam.In_ContactEmail: ' + vsyncAcctInputParam.In_ContactEmail);
            vsyncAcctInputParam.searchlead = (List<Lead>)[SELECT ID, name, email,phone FROM Lead WHERE
            (LeadSource != 'About To Be Cancelled' AND LeadSource != 'About To Be Cancelled UK') AND
            ((Phone!='' AND Phone!=null AND Phone =:vsyncAcctInputParam.In_Contactphone)  OR
            (email!='' AND email!=null AND email =: vsyncAcctInputParam.In_ContactEmail))
            AND (Status ='2. Contacted' OR Status ='1.5 Call Out')
            AND Isconverted =False Order BY Name DESC Limit 1];
            if (vsyncAcctInputParam.searchlead.size() > 0) {
                return true;
            } else {
                return false;
            }
        } catch (Exception ex) {
            vsyncAcctInputParam.OutErrorMsg = 'searchLeadByEmail:: '+ex.getMessage();
            return false;
        }
        return true;
    }

    public static Boolean handleUpdateAccount(syncAcctInputParamBilling vsyncAcctInputParam) {
        try {
            vsyncAcctInputParam.proc_debugmsg += 'IN handleUpdateAccount::';
            List<Account> AcctUpdate = new Account[]{};

            Account acc = new Account(
                    Id = vsyncAcctInputParam.proc_AccountId,
                    RC_Account_Number__c = vsyncAcctInputParam.In_RCPrimaryNumber,
                    RC_User_ID__c = vsyncAcctInputParam.In_RCUserID,
                    Billing_ID__c = vsyncAcctInputParam.In_BillingID,
                    Name = deNullifyString(vsyncAcctInputParam.In_Company) == ''
                        ? (deNullifyString(vsyncAcctInputParam.In_FirstName) + ' ' + vsyncAcctInputParam.In_LastName).trim().abbreviate(80)
                        : vsyncAcctInputParam.In_Company,
                    SignupType__c = vsyncAcctInputParam.In_SignupType,
                    SignupPlatform__c = vsyncAcctInputParam.In_SignupPlatform,
                    Bandwidth_Test_Id__c = vsyncAcctInputParam.In_Bandwidth_Test_Id,
                    Bandwidth_MOS_Score__c = vsyncAcctInputParam.In_Bandwidth_MOS_Score,
                    Bandwidth_Num_Sim_Calls__c = vsyncAcctInputParam.In_Bandwidth_Num_Sim_Calls,
                    Licenses_Purchased__c = getPurchasedLicensesNumber(vsyncAcctInputParam),
                    isFedRamp__c = String.isNotBlank(vsyncAcctInputParam.In_OpportunityID) ? checkFedRampOpportunity(vsyncAcctInputParam.In_OpportunityID) : false
            );

            if (vsyncAcctInputParam.In_RCBRAND != null) {
                acc.RC_Brand__c = substringStr(vsyncAcctInputParam.In_RCBRAND, 127);
            }

            if (vsyncAcctInputParam.In_SUBBRAND != null) {
                acc.Sub_Brand__c = substringStr(vsyncAcctInputParam.In_SUBBRAND, 127);
            }

            if (vsyncAcctInputParam.In_SERVICENAME != null) {
                acc.RC_Service_name__c = substringStr(vsyncAcctInputParam.In_SERVICENAME, 127);
            }

            if (vsyncAcctInputParam.In_TIERNAME != null) {
                acc.RC_Tier__c = substringStr(vsyncAcctInputParam.In_TIERNAME, 127);
            }

            if (vsyncAcctInputParam.In_Industry != null) {
                acc.Industry = substringStr(vsyncAcctInputParam.In_Industry, 40);
            }

            // Avoiding to update an incorrect empty value when condition for update is not met (BZS-7909)
            if (getOfferTypeForAccount(vsyncAcctInputParam) != null) {
                acc.Offer_Type__c = getOfferTypeForAccount(vsyncAcctInputParam);
            }
            // Fields to be updated by CCB
            // Updating fields on demand to prevent override by DWH with empty values
            if (String.isNotBlank(vsyncAcctInputParam.In_EngageAccountId)) {
                acc.RC_Engage_Account_ID__c = StringHelper.safeSubstring(vsyncAcctInputParam.In_EngageAccountId, 255);
            }
            if (String.isNotBlank(vsyncAcctInputParam.In_EVAccountId)) {
                acc.EV_Account_ID__c = StringHelper.safeSubstring(vsyncAcctInputParam.In_EVAccountId, 255);
            }
            if (String.isNotBlank(vsyncAcctInputParam.In_EVPlatform)) {
                acc.EV_Platform__c = StringHelper.safeSubstring(vsyncAcctInputParam.In_EVPlatform, 255);
            }
            if (String.isNotBlank(vsyncAcctInputParam.In_EDAccountId)) {
                acc.ED_Account_ID__c = StringHelper.safeSubstring(vsyncAcctInputParam.In_EDAccountId, 255);
            }
            if (String.isNotBlank(vsyncAcctInputParam.In_EDDomainId)) {
                acc.Engage_Domain__c = StringHelper.safeSubstring(vsyncAcctInputParam.In_EDDomainId, 255);
            }
            if (String.isNotBlank(vsyncAcctInputParam.In_EDPlatform)) {
                acc.ED_Platform__c = StringHelper.safeSubstring(vsyncAcctInputParam.In_EDPlatform, 255);
            }
            AcctUpdate.add(acc);
            Upsert AcctUpdate;

            Account existingAccount = (Account) new ListOptional(
                new AccountSelector()
                    .selectAccountById(acc.Id)
                    .executeQuery()
                ).getFirst();

            Boolean isBillingIdChanged = String.isNotBlank(vsyncAcctInputParam.In_BillingID)
                    && vsyncAcctInputParam.In_BillingID != vsyncAcctInputParam.proc_BillingId;
            if (shouldCreateOpportunityForLegacyCCMigration(existingAccount, isBillingIdChanged)) {
                System.debug('>>>>> CCMigrationQueueable has been invoked');
                PlatformLog__c pl = PlatformLog.buildLog(
                        'SyncAccountWsBilling',
                        'CCMigrationQueueable has been invoked',
                        JSON.serialize(existingAccount),
                        null,
                        null
                );
                PlatformLog.logResults(new List<PlatformLog__c>{pl});
                IS_ACCOUNT_FOR_LEGACY_CC_MIGRATION_PROCESSING = true;

                // Enqueuing RCCC Migration Objects creation
                System.enqueueJob(new CCMigrationQueueable(existingAccount));
            }

            if (!AccountHelper.MIGRATION_STATUSES.contains(existingAccount.AccMigrationFlag__c)) {
                upsertServiceAccounts(vsyncAcctInputParam);
            }
            vsyncAcctInputParam.proc_AccountId = acc.Id;
            try {
                LogProcess(vsyncAcctInputParam, 'Upserting');
            } catch (Exception ex) {
                system.debug('Failed to Insert log: '+ ex.getMessage());
            }
            return true;
        } catch (Exception ex) {
            system.debug('Exception === ' + ex.getMessage() + ex.getStackTraceString());
            vsyncAcctInputParam.OutErrorMsg = 'handleUpdateAccount:: '+ex.getMessage();
            return false;
        }
        return true;
    }

    public static Boolean handleConverLead(syncAcctInputParamBilling vsyncAcctInputParam) {
        try {
            vsyncAcctInputParam.proc_debugmsg += 'IN handleConverLead::';
            TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT();
            TriggerHandler.BY_PASS_ACCOUNT_ON_UPDATE();
            TriggerHandler.BY_PASS_CONTACT_ON_INSERT();
            TriggerHandler.BY_PASS_CONTACT_ON_UPDATE();
            TriggerHandler.BY_PASS_OPPORTUNITY_ON_INSERT();
            TriggerHandler.BY_PASS_OPPORTUNITY_ON_UPDATE();
            LeadStatus convertStatus = [Select Id, MasterLabel from LeadStatus where IsConverted= true  limit 1];
            for(Lead l: vsyncAcctInputParam.searchlead) {
                vsyncAcctInputParam.proc_debugmsg += 'In handleConverLead::' + l.Id;
                Database.LeadConvert lc = new database.LeadConvert();
                lc.setLeadId(l.id);
                lc.setConvertedStatus(convertStatus.MasterLabel);
                Database.LeadConvertResult lcr = Database.convertLead(lc);
                vsyncAcctInputParam.proc_AccountId = lcr.getAccountId();
                vsyncAcctInputParam.proc_ContactId = lcr.getContactId();
                TriggerHandler.RESET_VARIABLES();
                vsyncAcctInputParam.proc_debugmsg += 'In handleConverLead:: Account ID' + l.Id + lcr.getAccountId() + 'Conytact ID'+lcr.getContactId();
                return true;
            }
        } catch (Exception ex) {
            vsyncAcctInputParam.OutErrorMsg = 'handleConverLead:: '+ex.getMessage();
            return false;
        }
        return true;
    }

    public static String substringStr(String str, Integer len) {
        String result = str;
        if (str.length() > len) {
            result = str.substring(0, len);
        }
        return result;
    }

    public static Boolean handleCreateAccount(syncAcctInputParamBilling vsyncAcctInputParam) {
        try {
            vsyncAcctInputParam.proc_debugmsg += 'IN handleCreateAccount::';
            Account a = new Account();
            a.Name = deNullifyString(vsyncAcctInputParam.In_Company) == ''
                ? (deNullifyString(vsyncAcctInputParam.In_FirstName) + ' ' + vsyncAcctInputParam.In_LastName).trim().abbreviate(80)
                : vsyncAcctInputParam.In_Company;
            a.RC_Account_Number__c= vsyncAcctInputParam.In_RCPrimaryNumber;
            a.Rc_User_Id__c= vsyncAcctInputParam.In_RCUserID;
            a.Billing_ID__c = vsyncAcctInputParam.In_BillingID;
            a.RC_Brand__c=vsyncAcctInputParam.In_RCBRAND;
            a.Sub_Brand__c=vsyncAcctInputParam.In_SUBBRAND;
            a.Offer_Type__c = getOfferTypeForAccount(vsyncAcctInputParam);
            a.Licenses_Purchased__c = getPurchasedLicensesNumber(vsyncAcctInputParam);

            a.RC_Account_Status__c= '';
            a.ownerId=HardcodedIdsMapper.getMatchedObjectId('005800000036sJJ');
            a.SignupType__c = vsyncAcctInputParam.In_SignupType;
            a.SignupPlatform__c = vsyncAcctInputParam.In_SignupPlatform;

            /*Added to populate Service name & Tier*/
            a.RC_Service_name__c = ((vsyncAcctInputParam.In_SERVICENAME==null)?'':substringStr(vsyncAcctInputParam.In_SERVICENAME, 127));
            a.RC_Tier__c = ((vsyncAcctInputParam.In_TIERNAME==null)?'':substringStr(vsyncAcctInputParam.In_TIERNAME, 127));
            a.Industry = vsyncAcctInputParam.In_Industry == null ? '' : substringStr(vsyncAcctInputParam.In_Industry, 40);
            a.RC_Engage_Account_ID__c = StringHelper.safeSubstring(vsyncAcctInputParam.In_EngageAccountId, 255);
            a.EV_Account_ID__c = StringHelper.safeSubstring(vsyncAcctInputParam.In_EVAccountId, 255);
            a.EV_Platform__c = StringHelper.safeSubstring(vsyncAcctInputParam.In_EVPlatform, 255);
            a.ED_Account_ID__c = StringHelper.safeSubstring(vsyncAcctInputParam.In_EDAccountId, 255);
            a.Engage_Domain__c = StringHelper.safeSubstring(vsyncAcctInputParam.In_EDDomainId, 255);
            a.ED_Platform__c = StringHelper.safeSubstring(vsyncAcctInputParam.In_EDPlatform, 255);

            insert a;
            vsyncAcctInputParam.proc_AccountId = a.Id;
            upsertServiceAccounts(vsyncAcctInputParam);
            try {
                LogProcess(vsyncAcctInputParam, 'Inserting');
            } catch (Exception ex) {
                system.debug('Failed to Insert log: '+ ex.getMessage());
            }
            return true;
        } catch (Exception ex) {
            vsyncAcctInputParam.OutErrorMsg = 'handleCreateAccount:: '+ex.getMessage();
            return false;
        }
        return true;
    }

    @TestVisible
    private static string getOfferTypeForAccount(syncAcctInputParamBilling vsyncAcctInputParam)
    {
        String result;

        if (vsyncAcctInputParam != null && vsyncAcctInputParam.serviceAccounts != null && vsyncAcctInputParam.serviceAccounts.size() == 1) {
            result = vsyncAcctInputParam.serviceAccounts[0].Offer_Type__c;
        } else {
            result = null;
        }

        return result;
    }

    @TestVisible
    private static Decimal getPurchasedLicensesNumber(syncAcctInputParamBilling vsyncAcctInputParam)
    {
        Decimal result;

        if (vsyncAcctInputParam!=null && vsyncAcctInputParam.serviceAccounts!=null && vsyncAcctInputParam.serviceAccounts.size()==1) {
            result=vsyncAcctInputParam.serviceAccounts[0].Licenses_Purchased__c;
        }

        return result;
    }

    public static Boolean upsertServiceAccounts(syncAcctInputParamBilling vsyncAcctInputParam) {
        vsyncAcctInputParam.proc_debugmsg += 'IN upsertServiceAccounts::';
        List<Package__c> existingPackages;
        Map<String,Package__c> upsertPackagesMap = new Map<String,Package__c>();
        Map<String,Package__c> deletePackagesMap = new Map<String,Package__c>();
        Account existingAcc;

        if (vsyncAcctInputParam != null
                && vsyncAcctInputParam.serviceAccounts != null
                && vsyncAcctInputParam.proc_AccountId != null) {
            existingPackages = [
                    SELECT id,Account__c,Account_Package_Id__c
                    FROM Package__c
                    WHERE Account__c = :vsyncAcctInputParam.proc_AccountId
            ];

            List<Account> existingAccs = (List<Account>) new AccountSelector()
                .selectAccsForSyncAccountWs(new List<Object>{new List<Id> {vsyncAcctInputParam.proc_AccountId}})
                .executeQuery();

            if (!existingAccs.isEmpty()) {
                existingAcc = existingAccs.get(0);
            }

            for (Package__c serviceAccount : vsyncAcctInputParam.serviceAccounts) {
                Package__c tempPackage = serviceAccount;

                if (tempPackage.RC_User_ID__c != null) {
                    tempPackage.Name = tempPackage.RC_User_ID__c;
                }

                if (existingAcc != null) {
                    tempPackage.Enterprise_Account_ID__c = existingAcc.Id;

                    if (existingAcc.Master_Account__c != null && existingAcc.IsMultiProductTechnicalAccount__c) {
                        tempPackage.Account__c = existingAcc.Master_Account__c;
                    } else {
                        tempPackage.Account__c = existingAcc.id;
                    }
                }

                upsertPackagesMap.put(serviceAccount.Account_Package_Id__c, tempPackage);
            }

            upsertPackagesMap.remove(null);

            for (Package__c serviceAccount : existingPackages) {
                if (!upsertPackagesMap.containsKey(serviceAccount.Account_Package_Id__c)) {
                    deletePackagesMap.put(serviceAccount.Account_Package_Id__c, serviceAccount);
                }
            }
            deletePackagesMap.remove(null);
        }

        try {
            if (upsertPackagesMap.size() > 0) {
                upsert upsertPackagesMap.values() Account_Package_Id__c;
            }
            if (deletePackagesMap.size() > 0) {
                delete deletePackagesMap.values();
            }
            return true;
        } catch (Exception ex) {
            vsyncAcctInputParam.OutErrorMsg = 'upsertServiceAccounts:: '+ex.getMessage();
            return false;
        }
        return false;
    }

    public static Boolean handleCreateContact(syncAcctInputParamBilling vsyncAcctInputParam) {
        Boolean result = true;
        try {
            String firstName = vsyncAcctInputParam.In_FirstName;
            if(firstName.length() > 40) {
                firstName = firstName.substring(0, 40);
            }

            String email = vsyncAcctInputParam.In_ContactEmail;
            if(email.length() > 80) {
                email = email.substring(email.length()-80, email.length());
            }

            Contact contact = new Contact(
                    LastName          = vsyncAcctInputParam.In_LastName,
                    AccountId         = vsyncAcctInputParam.proc_AccountId,
                    FirstName         = firstName,
                    CurrencyIsoCode   = 'USD',
                    Email             = email,
                    Company__c        = vsyncAcctInputParam.In_Company,
                    Phone             = vsyncAcctInputParam.In_ContactPhone
            );

            insert contact;

            vsyncAcctInputParam.proc_debugmsg += 'IN handleCreateContact::';
            vsyncAcctInputParam.proc_ContactId = contact.Id;
        } catch (Exception ex) {
            vsyncAcctInputParam.OutErrorMsg = 'handleCreateContact:: '+ex.getMessage();
            result = false;
        }

        return result;
    }

    public static Boolean handleUpdateContact(syncAcctInputParamBilling vsyncAcctInputParam) {
        try {
            Contact contact = new Contact(
                    id = vsyncAcctInputParam.In_ContactID,
                    LastName = vsyncAcctInputParam.In_LastName,
                    Email = vsyncAcctInputParam.In_ContactEmail,
                    FirstName = deNullifyString(vsyncAcctInputParam.In_FirstName).length() > 40
                            ? vsyncAcctInputParam.In_FirstName.substring(0, 40)
                            : vsyncAcctInputParam.In_FirstName
            );

            if(vsyncAcctInputParam.In_ContactPhone != null) {
                contact.Phone = vsyncAcctInputParam.In_ContactPhone;
            }

            update contact;
        } catch (Exception e) {
            vsyncAcctInputParam.OutErrorMsg = 'handleUpdateContact:: ' + e.getMessage();
            return false;
        }
        return true;
    }

    public static Boolean accountMatchingContactEmail(syncAcctInputParamBilling vsyncAcctInputParam) {
        try {
            vsyncAcctInputParam.proc_debugmsg += 'IN accountMatchingContactEmail::';
            List<Contact> matchacc = [select Id from Contact where AccountId =:vsyncAcctInputParam.proc_AccountId
            and Email=:vsyncAcctInputParam.In_ContactEmail];
            if (matchacc.size() > 0) {
                vsyncAcctInputParam.proc_ContactId = matchacc[0].id;
                return true;
            } else {
                return false;
            }
        } catch (Exception ex) {
            vsyncAcctInputParam.OutErrorMsg = 'accountMatchingContactEmail:: '+ex.getMessage();
        }
        return true;
    }

    public static Boolean contactHavingUserRecord(syncAcctInputParamBilling vsyncAcctInputParam) {
        try {
            vsyncAcctInputParam.proc_debugmsg += 'IN contactHavingUserRecord::';
            List<User> objUser = new List<User>();
            List<Contact> objContact = [SELECT Id FROM Contact  WHERE Account.Billing_ID__c=:vsyncAcctInputParam.In_BillingID AND email =:vsyncAcctInputParam.In_ContactEmail];
            if (objContact.size() > 0)
            {
                objUser = [
                        SELECT Id
                        FROM User
                        WHERE ContactId =: objContact[0].Id
                            AND ProfileId IN: SyncAccountWs.PROFILE_IDS_OF_PORTAL_USERS
                            AND IsActive = true
                        ORDER BY ProfileId ASC
                ];
                if (objUser.size() > 0) {
                    vsyncAcctInputParam.proc_UserId = objUser[0].Id;
                    return true;
                } else {
                    return false;
                }
            } else {
                return false;
            }
        } catch (Exception ex) {
            vsyncAcctInputParam.OutErrorMsg = 'contactHavingUserRecord:: '+ex.getMessage();
        }
        return true;
    }

    public static Boolean handleCreateUser(syncAcctInputParamBilling vsyncAcctInputParam) {
        vsyncAcctInputParam.proc_debugmsg += 'IN handleCreateUser::';
        vsyncAcctInputParam.proc_UserRecCreation = '-1';
        return true;
    }

    public static void handleReturn(syncAcctInputParamBilling vsyncAcctInputParam) {
        vsyncAcctInputParam.proc_debugmsg += 'IN handleReturn::';
        vsyncAcctInputParam.Out_AccountID = vsyncAcctInputParam.proc_AccountId;
        vsyncAcctInputParam.Out_ContactID = vsyncAcctInputParam.proc_ContactId;
        vsyncAcctInputParam.Out_UserID = vsyncAcctInputParam.proc_UserId;
    }

    public static void initializeIds(syncAcctInputParamBilling vsyncAcctInputParam) {
        vsyncAcctInputParam.proc_AccountId = vsyncAcctInputParam.In_AccountID;
        vsyncAcctInputParam.proc_ContactId = vsyncAcctInputParam.In_ContactID;
        try {
            if(vsyncAcctInputParam.proc_ContactId != null) {
                List<User> contactUser = [SELECT Id FROM User WHERE contactId =: vsyncAcctInputParam.proc_ContactId];
                vsyncAcctInputParam.proc_UserId = contactUser.size() > 0 ? contactUser.get(0).Id : null;
            }
        } catch(Exception e) {
            vsyncAcctInputParam.OutErrorMsg = 'IN initializeIds:: ' + e.getMessage();
        }
    }

    public static void LogProcess(syncAcctInputParamBilling vsyncAcctInputParam, String action) {
        CustomLog__c cl = new CustomLog__c(
                Name = action + ' Account ' + Datetime.now().format('dd-MM-yyyy HH:mm'),
                InputParameterFileds__c = 'In_proc_AccountId: ' + vsyncAcctInputParam.proc_AccountId + '\n' +
                        'In_Company: ' + vsyncAcctInputParam.In_Company + '\n' +
                        'In_RCUserID: ' + deNullifyString(vsyncAcctInputParam.In_RCUserID) + '\n' +
                        'In_BillingID: ' + deNullifyString(vsyncAcctInputParam.In_BillingID) + '\n' +
                        'In_ContactEmail: ' + vsyncAcctInputParam.In_ContactEmail + '\n' +
                        'In_OpportunityID: ' + vsyncAcctInputParam.In_OpportunityID + '\n' +
                        'In_Partner_Deal_Registration_Id: ' + vsyncAcctInputParam.In_Partner_Deal_Registration_Id,
                LoggedDate__c = Datetime.now()
        );
        insert cl;
    }

    public static Boolean checkFedRampOpportunity(String inputString) {
        Boolean isFedRamp = false;
        List<Opportunity> opps = (List<Opportunity>) new OpportunitySelector()
            .selectOpportunitiesByIds(new Set<Id>{inputString})
            .executeQuery();

        if (!opps.isEmpty()) {
            if (opps[0].isFedRamp__c) {
                isFedRamp = true;
            }
        }

        return isFedRamp;
    }
//SignUp Sync End

    public static Boolean isLegacyCCMigrationProcess() {
        return IS_ACCOUNT_FOR_LEGACY_CC_MIGRATION_PROCESSING;
    }

    @TestVisible
    private static Boolean shouldCreateOpportunityForLegacyCCMigration(Account migratingAccount, Boolean isBillingIdChanged) {
        return AccountHelper.isMigrationInProgress(migratingAccount?.AccMigrationFlag__c)
            && migratingAccount.Service_Type__c == AccountHelper.SERVICE_TYPE_RCCC
            && isBillingIdChanged;
    }
}