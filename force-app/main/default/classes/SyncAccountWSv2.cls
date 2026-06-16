@RestResource(urlMapping='/SyncAccountWSv2/*')
global class SyncAccountWSv2 {

    public static Boolean isNewSyncAccountWSExecuted = false;
    public static Boolean enableCugSync = !Feature_Toggle__c.getInstance().Disable_CUG_Account_Sync__c;

    public final static Set<Id> PROFILE_IDS_OF_PORTAL_USERS = getProfilesForPortalUsers();

    // Some Integrated Services use SOAP version of this webservice and some JSON REST
    @HttpPost
    global static void handleRequest() {
        if (RestContext.response == null) {
            RestContext.response = new RestResponse();
        }
        Object resp = null;

        String body = RestContext.request.requestBody.toString();

        isNewSyncAccountWSExecuted = true;

        SyncAcctInputParam syncParams = (SyncAcctInputParam) JSON.deserialize(body, SyncAcctInputParam.class);
        if (syncParams.contactparams == null) {
            syncParams.contactparams = new Contact();
        }
        resp = syncAccountNew(syncParams, enableCugSync);

        RestContext.response.responseBody = Blob.valueOf(JSON.serialize(resp));
    }

    public class ErrorWrapper {
        public String message;
        public String stackTrace;
    }

    //Define an object in apex that is exposed in apex web service
    global class SyncAcctInputParam {
        public Boolean success;
        public ErrorWrapper error = new ErrorWrapper();

        public List<Package__c> packages = new List<Package__c>();
        public Account accountparams = new Account();
        public Contact contactparams = new Contact();
        public Map<String, String> searchParams = new Map<String, String>();
        public List<Lead> searchlead;

        public void prepareRequest (Boolean isSuccess, Exception ex) {
            this.success = isSuccess;
            this.error = new ErrorWrapper();
            if (!isSuccess && ex != null) {
                this.error.message = ex.getMessage();
                this.error.stackTrace = ex.getStackTraceString();
            }
        }

        /*Processing*/
        String proc_debugmsg;
    }

    public SyncAccountWSv2() {
    }

    public static SyncAcctInputParam syncAccountNew(SyncAcctInputParam vSyncAcctInputParam, Boolean isCugSyncEnabled) {
        vSyncAcctInputParam.success = true;
        Boolean isAccountFoundByRCUserID = searchAccountByEnterpriseAccountID(vSyncAcctInputParam, isCugSyncEnabled);
        if (isAccountFoundByRCUserID || (vSyncAcctInputParam.contactparams?.Id != null)) {
            Boolean accountMatchingContactEmail = accountMatchingContactEmail(vSyncAcctInputParam);
            initializeIds(vSyncAcctInputParam);
            if (isAccountFoundByRCUserID) {
                handleUpdateAccount(vSyncAcctInputParam);
            }
            if (vSyncAcctInputParam.contactparams?.Id != null || accountMatchingContactEmail) {
                handleUpdateContact(vSyncAcctInputParam);
            }
            if (accountMatchingContactEmail(vSyncAcctInputParam) == false) {
                handleCreateContact(vSyncAcctInputParam);
            }
        } else {
            if (String.isNotBlank(vSyncAcctInputParam.searchParams.get('dealRegId')) && searchContactandLeadByDealId(vSyncAcctInputParam) == true) {
                if (vSyncAcctInputParam.contactparams.Id != null) {
                    handleUpdateAccount(vSyncAcctInputParam);
                }
            } else {
                if (vSyncAcctInputParam.searchparams.get('opportunityId') != null && vSyncAcctInputParam.searchparams.get('opportunityId') != '') {
                    if (searchOpportunityById(vSyncAcctInputParam) == true) {
                        handleUpdateAccountAndContact(vSyncAcctInputParam);
                    } else {
                        if (searchContactByMailAndBrand(vSyncAcctInputParam) == true) {
                            handleUpdateAccountAndContact(vSyncAcctInputParam);
                        } else {
                            if (handleCreateAccount(vSyncAcctInputParam) == true) {
                                handleCreateContact(vSyncAcctInputParam);
                            }
                        }
                    }
                } else {
                    if (searchContactByMailAndBrand(vSyncAcctInputParam) == true) {
                        handleUpdateAccountAndContact(vSyncAcctInputParam);
                    } else {
                        if (handleCreateAccount(vSyncAcctInputParam) == true) {
                            handleCreateContact(vSyncAcctInputParam);
                        }
                    }
                }

            }
        }

        if (!vSyncAcctInputParam.success && vSyncAcctInputParam.error.message == null) {
            vSyncAcctInputParam.error.message = 'Something went wrong. Please check the passed parameters';
        }

        return vSyncAcctInputParam;
    }

    public static void handleUpdateAccountAndContact(SyncAcctInputParam vSyncAcctInputParam) {
        if (handleUpdateAccount(vSyncAcctInputParam) == true) {
            if (accountMatchingContactEmail(vSyncAcctInputParam) == false) {
                handleCreateContact(vSyncAcctInputParam);
            }
        }
    }

    public static Boolean searchAccountByEnterpriseAccountID(SyncAcctInputParam vSyncAcctInputParam, Boolean isCugSyncEnabled) {
        try {
            vSyncAcctInputParam.proc_debugmsg += 'IN searchAccountByEnterpriseAccountID::';
            System.debug('vSyncAcctInputParam.searchParams.get(\'enterpriseAccountId\'): ' + vSyncAcctInputParam.searchParams.get('enterpriseAccountId'));

            QueryFactory existingAccountQuery = new AccountSelector()
                .selectAccountForSyncWS(new List<Object>{
                    vSyncAcctInputParam.searchParams.get('enterpriseAccountId'),
                    vSyncAcctInputParam.accountparams.Bt_Cug_Number__c
                });

            if (isCugSyncEnabled) {
                existingAccountQuery.altCondition('(Bt_Cug_Number__c != NULL AND Bt_Cug_Number__c = :bind1)');
            }

            List<Account> searchAccount = (List<Account>) existingAccountQuery.executeQuery();

            if (!searchAccount.isEmpty()) {
                Account account = searchAccount.get(0);

                vSyncAcctInputParam.accountparams.Id = account.Id;
                vSyncAcctInputParam.accountparams.IsMultiProductTechnicalAccount__c = account.IsMultiProductTechnicalAccount__c;
                vSyncAcctInputParam.accountparams.Master_Account__c = account.Master_Account__c;

                if (isCugSyncEnabled) {
                    vSyncAcctInputParam.accountparams.RC_User_ID__c = vSyncAcctInputParam.searchParams.get('enterpriseAccountId');
                }
                if (String.isBlank(vSyncAcctInputParam.accountparams.Name)) {
                    vSyncAcctInputParam.accountparams.Name = account.Name;
                }
            } else {
                return false;
            }
            return true;
        } catch (Exception ex) {
            vSyncAcctInputParam.prepareRequest(false, ex);
            return false;
        }
    }

    public static Boolean searchContactandLeadByDealId(SyncAcctInputParam vSyncAcctInputParam) {
        System.debug('*** Inside searchContactandLeadByDealId ***');
        System.debug('vSyncAcctInputParam.searchParams.get(\'dealRegId\'): ' + vSyncAcctInputParam.searchParams.get('dealRegId'));
        try {
            String partnerDealId = vSyncAcctInputParam.searchParams.get('dealRegId');
            Decimal decPartnerDealId = Decimal.valueOf(partnerDealId);
            List<Contact> lstContact = [
                SELECT Id, AccountId FROM Contact
                WHERE PartnerDeal_Registration_ID__c = :decPartnerDealId AND AccountId != NULL
                ORDER BY CreatedDate DESC LIMIT 1
            ];
            if (lstContact != null && lstContact.size() > 0) {
                vSyncAcctInputParam.contactparams = lstContact[0];
                return true;
            } else {
                List<Lead> lstLead = [
                    SELECT Id FROM Lead
                    WHERE PartnerDeal_Registration_ID__c = :decPartnerDealId AND IsConverted = FALSE
                    ORDER BY CreatedDate DESC LIMIT 1
                ];
                if (lstLead != null && lstLead.size() > 0) {
                    vSyncAcctInputParam.searchlead = lstLead;
                    return true;
                }
            }
        } catch (Exception ex) {
            vSyncAcctInputParam.prepareRequest(false, ex);
        }
        return false;
    }

    public static Boolean searchOpportunityById(SyncAcctInputParam vSyncAcctInputParam) {
        try {
            vSyncAcctInputParam.proc_debugmsg += 'IN searchOpportunityById::';
            System.debug('vSyncAcctInputParam.searchParams.get(\'opportunityId\'): ' + vSyncAcctInputParam.searchParams.get('opportunityId'));
            List<Opportunity> searchopportunity = [
                SELECT Name, AccountId, Id, StageName
                FROM Opportunity
                WHERE Id = :vSyncAcctInputParam.searchParams.get('opportunityId')
                AND Account.RC_Sync_Status__c != 'In Sync'
                AND Account.RC_User_ID__c = NULL
                ORDER BY CreatedDate DESC
                LIMIT 1
            ];
            if (searchopportunity.size() > 0) {
                vSyncAcctInputParam.accountparams.Id = searchopportunity[0].AccountId;
            } else {
                return false;
            }
        } catch (Exception ex) {
            vSyncAcctInputParam.prepareRequest(false, ex);
            return false;
        }
        return true;
    }

    public static Boolean searchContactByMailAndBrand(SyncAcctInputParam vSyncAcctInputParam) {
        try {
            vSyncAcctInputParam.proc_debugmsg += 'IN searchContactByMailAndBrand::';
            System.debug('vSyncAcctInputParam.searchparams.get(\'email\'): ' + vSyncAcctInputParam.searchparams.get('email'));

            if (String.isBlank(vSyncAcctInputParam.searchparams.get('email'))) {
                return false;
            }

            List<Contact> searchContact = (List<Contact>) new ContactSelector()
                .selectContactsForSyncWS(new List<Object>{
                    vSyncAcctInputParam.searchparams.get('email'),
                    AccountHelper.RT_ID_CUSTOMER_ACCOUNT,
                    vSyncAcctInputParam.accountparams.RC_Brand__c
                })
                .executeQuery();

            if (searchContact.size() == 1) {
                vSyncAcctInputParam.accountparams.Id = searchContact[0].AccountId;
                vSyncAcctInputParam.contactparams.Id = searchContact[0].Id;
                return true;
            } else if (searchContact.size() > 1) {
                Set<Id> accountIds = new Set<Id>();
                for (Contact contact : searchContact) {
                    accountIds.add(contact.AccountId);
                }

                List<Opportunity> opportunities = (List<Opportunity>) new OpportunitySelector()
                    .selectOpportunitiesForSyncWS(new List<Object>{ accountIds, OpportunityHelper.RT_ID_NEW_SALES_OPPORTUNITY })
                    .executeQuery();

                for (Contact contact : searchContact) {
                    for (Opportunity oppByAccountId : opportunities) {
                        if (oppByAccountId.AccountId == contact.AccountId) {
                            vSyncAcctInputParam.accountparams.Id = contact.AccountId;
                            vSyncAcctInputParam.contactparams.Id = contact.Id;
                            return true;
                        }
                    }
                }
                /*If no account found having opportunity then return with latest record. Do query and assign*/
                vSyncAcctInputParam.accountparams.Id = searchContact[0].AccountId;
                vSyncAcctInputParam.contactparams.Id = searchContact[0].Id;
                return true;

            } else {
                return false;
            }
        } catch (Exception ex) {
            vSyncAcctInputParam.prepareRequest(false, ex);
            return false;
        }
    }

    public static Boolean searchLeadByEmail(SyncAcctInputParam vSyncAcctInputParam) {
        try {
            vSyncAcctInputParam.proc_debugmsg += 'IN searchLeadByEmail::';
            System.debug('vSyncAcctInputParam.searchparams.get(\'email\'): ' + vSyncAcctInputParam.searchparams.get('email'));
            vSyncAcctInputParam.searchlead =
                (List<Lead>) [
                    SELECT Id, Name, Email, Phone
                    FROM Lead
                    WHERE (LeadSource != 'About To Be Cancelled' AND LeadSource != 'About To Be Cancelled UK')
                    AND ((Phone != '' AND Phone != NULL AND Phone = :vSyncAcctInputParam.contactparams.Phone)
                    OR (Email != '' AND Email != NULL AND Email = :vSyncAcctInputParam.searchparams.get('email')))
                    AND (Status = '2. Contacted'
                    OR Status = '1.5 Call Out')
                    AND IsConverted = FALSE
                    ORDER BY Name DESC
                    LIMIT 1
                ];
            return vSyncAcctInputParam.searchlead.size() > 0;
        } catch (Exception ex) {
            vSyncAcctInputParam.prepareRequest(false, ex);
            return false;
        }
    }

    public static Boolean handleUpdateAccount(SyncAcctInputParam vSyncAcctInputParam) {
        try {
            vSyncAcctInputParam.proc_debugmsg += 'IN handleUpdateAccount::';
            List<Account> acctUpdate = new List<Account>{};

            Account acc = vSyncAcctInputParam.accountParams;

            if (acc.Id == null) {
                List<Account> accSelectedByRCUserId = new AccountSelector()
                    .selectAccountForSyncWS(new List<Object>{
                        vSyncAcctInputParam.searchParams.get('enterpriseAccountId')
                    })
                    .executeQuery();
                if (!accSelectedByRCUserId.isEmpty()) {
                    Account account = accSelectedByRCUserId.get(0);
                    acc.Id = account.Id;
                    acc.IsMultiProductTechnicalAccount__c = account.IsMultiProductTechnicalAccount__c;
                    acc.Master_Account__c = account.Master_Account__c;
                }
            }

            acctUpdate.add(acc);
            upsert acctUpdate Id;

            Account existingAccount = (Account) new ListOptional(
                new AccountSelector()
                    .selectAccountById(acc.Id)
                    .executeQuery()
                ).getFirst();

            Boolean isBillingIdChanged = String.isNotBlank(vSyncAcctInputParam.searchParams.get('billingId'));
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

                // Enqueuing RCCC Migration Objects creation
                System.enqueueJob(new CCMigrationQueueable(existingAccount));
            }

            vSyncAcctInputParam.accountparams.Id = acc.Id;
            if (!AccountHelper.MIGRATION_STATUSES.contains(existingAccount.AccMigrationFlag__c)) {
                upsertAccountPackages(vSyncAcctInputParam);
            }
            try {
                LogProcess(vSyncAcctInputParam, 'Upserting');
            } catch (Exception ex) {
                System.debug('Failed to Insert log: ' + ex.getMessage());
            }
        } catch (Exception ex) {
            System.debug('Exception === ' + ex.getMessage() + ex.getStackTraceString());
            vSyncAcctInputParam.prepareRequest(false, ex);
            return false;
        }
        return true;
    }

    public static Boolean handleCreateAccount(SyncAcctInputParam vSyncAcctInputParam) {
        try {
            vSyncAcctInputParam.proc_debugmsg += 'IN handleCreateAccount::';
            Account a = vSyncAcctInputParam.accountParams;
            a.OwnerId = HardcodedIdsMapper.getMatchedObjectId('005800000036sJJ');
            insert a;
            vSyncAcctInputParam.accountParams.Id = a.Id;
            upsertAccountPackages(vSyncAcctInputParam);
            try {
                LogProcess(vSyncAcctInputParam, 'Inserting');
            } catch (Exception ex) {
                System.debug('Failed to Insert log: ' + ex.getMessage());
            }
        } catch (Exception ex) {
            vSyncAcctInputParam.prepareRequest(false, ex);
            return false;
        }
        return true;
    }

    @TestVisible
    private static String getOfferTypeForAccount(SyncAcctInputParam vSyncAcctInputParam) {
        if (vSyncAcctInputParam?.packages?.size() == 1) {
            return vSyncAcctInputParam.packages[0].Offer_Type__c;
        }
        return null;
    }

    @TestVisible
    private static Decimal getPurchasedLicensesNumber(SyncAcctInputParam vSyncAcctInputParam) {
        Decimal result;

        if (vSyncAcctInputParam?.packages?.size() == 1) {
            result = vSyncAcctInputParam.packages[0].Licenses_Purchased__c;
        }

        return result;
    }

    public static Boolean upsertAccountPackages(SyncAcctInputParam vSyncAcctInputParam) {
        vSyncAcctInputParam.proc_debugmsg += 'IN upsertAccountPackages::';
        Map<String,Package__c> upsertPackagesMap = new Map<String,Package__c>();
        Account existingAcc;

        if (vSyncAcctInputParam?.packages != null && vSyncAcctInputParam?.accountParams?.Id != null) {

            List<Account> existingAccs = (List<Account>) new AccountSelector()
                .selectAccsForSyncAccountWs(new List<Object>{new List<Id> {vSyncAcctInputParam.accountParams.Id}})
                .executeQuery();

            if (!existingAccs.isEmpty()) {
                existingAcc = existingAccs.get(0);
            }

            for (Package__c currentPackage : vSyncAcctInputParam.packages) {
                Package__c tempPackage = currentPackage;

                if (tempPackage.RC_User_ID__c != null) {
                    tempPackage.Name = tempPackage.RC_User_ID__c;
                }

                if (existingAcc != null) {
                    tempPackage.Enterprise_Account_ID__c = existingAcc.Id;

                    if (existingAcc.Master_Account__c != null && existingAcc.IsMultiProductTechnicalAccount__c) {
                        tempPackage.Account__c = existingAcc.Master_Account__c;
                    } else {
                        tempPackage.Account__c = existingAcc.Id;
                    }
                }

                upsertPackagesMap.put(currentPackage.Account_Package_Id__c, tempPackage);
                System.debug('==== upsertPackagesMap >>>> ' + upsertPackagesMap);
            }

            upsertPackagesMap.remove(null);
        }

        try {
            if (upsertPackagesMap.size() > 0) {
                upsert upsertPackagesMap.values() Account_Package_Id__c;
            }
            return true;
        } catch (Exception ex) {
            vSyncAcctInputParam.prepareRequest(false, ex);
        }
        return false;
    }

    public static Boolean handleCreateContact(SyncAcctInputParam vSyncAcctInputParam) {
        try {
            vSyncAcctInputParam.proc_debugmsg += 'IN handleCreateContact::';
            Contact c = vSyncAcctInputParam.contactparams;
            if (c != null && c.LastName != null && c.Email != null) {
                c.AccountId = vSyncAcctInputParam.accountparams.Id;
                insert c;
                vSyncAcctInputParam.contactparams.Id = c.Id;
                return false;
            }
            return true;
        } catch (Exception ex) {
            vSyncAcctInputParam.prepareRequest(false, ex);
            return false;
        }
    }

    public static Boolean handleUpdateContact(SyncAcctInputParam vSyncAcctInputParam) {
        try {
            Contact contact = vSyncAcctInputParam.contactparams;

            update contact;
        } catch (Exception e) {
            vSyncAcctInputParam.prepareRequest(false, e);
            return false;
        }
        return true;
    }

    public static Boolean accountMatchingContactEmail(SyncAcctInputParam vSyncAcctInputParam) {
        try {
            vSyncAcctInputParam.proc_debugmsg += 'IN accountMatchingContactEmail::';
            String email = vSyncAcctInputParam.searchparams.get('email') != null
                ? vSyncAcctInputParam.searchparams.get('email')
                : vSyncAcctInputParam.contactparams?.Email;
            List<Contact> matchacc = [
                SELECT Id FROM Contact
                WHERE AccountId = :vSyncAcctInputParam.accountparams.Id AND Email = :email
            ];
            if (matchacc.size() > 0) {
                vSyncAcctInputParam.contactparams.Id = matchacc[0].Id;
                return true;
            } else {
                return false;
            }
        } catch (Exception ex) {
            vSyncAcctInputParam.prepareRequest(false, ex);
        }
        return true;
    }

    public static void initializeIds(SyncAcctInputParam vSyncAcctInputParam) {
        try {
            if (vSyncAcctInputParam.contactparams?.Id != null) {
                List<User> contactUser = [SELECT Id FROM User WHERE contactId =: vSyncAcctInputParam.contactparams.Id];
                vSyncAcctInputParam.searchParams.put('userId', contactUser.size() > 0 ? contactUser.get(0).Id : null);
            }
        } catch (Exception e) {
            vSyncAcctInputParam.prepareRequest(false, e);
        }
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

    @TestVisible
    private static Boolean shouldCreateOpportunityForLegacyCCMigration(Account migratingAccount, Boolean isBillingIdChanged) {
        return AccountHelper.isMigrationInProgress(migratingAccount?.AccMigrationFlag__c)
            && migratingAccount.Service_Type__c == AccountHelper.SERVICE_TYPE_RCCC
            && isBillingIdChanged;
    }

    public static void LogProcess(SyncAcctInputParam vSyncAcctInputParam, String action) {
        String accountName = vSyncAcctInputParam.accountparams.Name; // ???????
        String accountId = vSyncAcctInputParam.accountparams.Id;
        String source = 'SyncAccountWSv2: ' + action + ' Account ' + accountId + '/' + accountName;
        String message = JSON.serializePretty(vSyncAcctInputParam);

        PlatformLog__c pl = PlatformLog.buildLog(source, null, null, null, message);

        insert pl;
    }

    public static Set<Id> getProfilesForPortalUsers() {
        RingCentralVariousSettings__c settings = RingCentralVariousSettings__c.getInstance();

        if (settings.Use_Community_Licenses_on_portal__c || Test.isRunningTest()) {
            Set<Id> res = new Set<Id> {
                ProfileHelper.PROFILE_ID_CUSTOMER_PORTAL_USER,
                ProfileHelper.PROFILE_ID_CUSTOMER_COMMUNITY_LOGIN_USER_CUSTOM
            };
            String configLicences = settings?.SitesAcceptedProfiles__c;

            if (String.isBlank(configLicences)) {
                return res;
            }

            for (String licenceId : configLicences.split(';')) {
                try {
                    res.add(licenceId.trim());
                } catch (Exception e) {
                    //ignore bad ids
                    continue;
                }
            }
            return res;

        } else {
            return new Set<Id> {
                ProfileHelper.PROFILE_ID_CUSTOMER_PORTAL_USER
            };
        }
    }
}