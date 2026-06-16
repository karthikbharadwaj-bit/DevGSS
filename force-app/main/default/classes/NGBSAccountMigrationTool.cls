public with sharing class NGBSAccountMigrationTool {
    
    public static final String MODE_VALIDATION = 'VALIDATION';
    public static final String MODE_MIGRATION = 'MIGRATION';
    public static final String MODE_ROLLBACK = 'ROLLBACK';
    
    public static final String ACCOUNT_STATUS_DELETED = 'Deleted';
    
    public class MigrationException extends Exception {}
    
    private static Boolean hasAccountUpdatePermission() {
        return Schema.sObjectType.Account.isUpdateable();
    }
    
    private static Boolean hasPackageQueryPermission() {
        return Schema.sObjectType.Package__c.isAccessible();
    }
    
    private static Boolean hasPackageUpdatePermission() {
        return Schema.sObjectType.Package__c.isUpdateable();
    }

    public static Account technicalAccount;
    public static Package__c technicalPackage;
    public static NGBSAccountMigrationToolData__c accountMigrationToolData;

    public static void logNGBSResponse(String responseStatus, String responseBody) {
        accountMigrationToolData.NGBS_Status__c = responseStatus;
        logResults('NGBS', '[Status: ' + responseStatus + '] ' + responseBody);
    }

    public static void logCCBResponse(String responseStatus, String responseBody) {
        accountMigrationToolData.NGBS_Status__c = responseStatus;
        logResults('CCB', '[Status: ' + responseStatus + '] ' + responseBody);
    }

    public static void logICBResponse(String responseStatus, String responseBody) {
        accountMigrationToolData.NGBS_Status__c = responseStatus;
        logResults('ICB', '[Status: ' + responseStatus + '] ' + responseBody);
    }

    public static void logResults(String serviceName, String errorStr) {
        DateTime nowDateTime = DateTime.now();
        technicalPackage.Package_Transfer_Logs__c = technicalPackage.Package_Transfer_Logs__c +
                                                    '[' + nowDateTime.format('yyyy-MM-dd h:mm:ss') + '] ' +
                                                    serviceName + ':\n' +
                                                    errorStr + '\n----\n';
    }

    public static void logSalesforceErrors(String errorStr) {
        accountMigrationToolData.Errors__c = errorStr;
    }
    
    public static void migrateAccount(NGBSAccountMigrationToolData__c accMigrationToolData) {
        try {
            accountMigrationToolData = accMigrationToolData;
            prepareRecordsForMigration(accountMigrationToolData);

            Triggers.switchOff();

            Boolean validationResult = performPackagesMigration(true);
            
            // Step 1: Validate package transfer
            if (!accountMigrationToolData.Package_Migration__c || validationResult) {
                // Step 2: Perform package migration
                Boolean isMigrationSuccess = true;
                Boolean isCCBSuccess = true;
                Boolean isICBSuccess = true;
                String masterAccIdForUnlock = technicalAccount.Master_Account__c;

                if (accountMigrationToolData.Package_Migration__c) {
                    isMigrationSuccess = performPackagesMigration(false);
                }
                
                if (isMigrationSuccess) {
                    // Step 3: Perform CCB callout
                    if (accountMigrationToolData.CCB_Callout__c && technicalPackage.Service_Type__c.startsWith('Engage')) {
                        isCCBSuccess = performCCBCallout();
                    }
                    
                    // Step 4: Perform ICB callout
                    if (accountMigrationToolData.ICB_Callout__c && technicalPackage.Service_Type__c == 'RingCentral Contact Center') {
                        isICBSuccess = performICBCallout();
                    }

                    if (accountMigrationToolData.Update_Local_Records__c) {
                        // Step 5: Update Package record
                        updatePackageRecords();
                        
                        // Step 6: Unlink technical account from master
                        unlinkTechnicalAccounts();
                    }

                    // Step 7: Perform Package revert (if needed)
                    if (accountMigrationToolData.Package_Revert__c) {
                        performPackageRevert();
                    }

                    // Step 8: Check migration status
                    if (accountMigrationToolData.Check_Migration_Status__c) {
                        getStatusFromNGBS(technicalAccount.Billing_Id__c, 
                                        technicalPackage.Account_Package_Id__c, 
                                        technicalAccount.Master_Account__r.Billing_Id__c);
                    }

                    // Step 9: Check revert status
                    if (accountMigrationToolData.Check_Revert_Status__c) {
                        getStatusFromNGBS(technicalAccount.Master_Account__r.Billing_Id__c, 
                                        technicalPackage.Account_Package_Id__c, 
                                        technicalAccount.Billing_Id__c);
                    }
                    
                    System.debug('Account migration completed');

                    if (isCCBSuccess && isICBSuccess) {
                        unlockAccountsForQuoting(masterAccIdForUnlock);
                        update technicalAccount;
                    }
                } else {
                    performPackageRevert();
                }
            }

            update accountMigrationToolData;
            update technicalPackage;

            Triggers.switchOn();
            
        } catch (Exception e) {
            System.debug('Migration failed: ' + e.getMessage());
            logSalesforceErrors(e.getMessage());
            update accountMigrationToolData;
            update technicalPackage;
            throw e;
        }
    }

    public static void prepareRecordsForMigration(NGBSAccountMigrationToolData__c accountMigrationToolData) {
        technicalAccount = [SELECT Id, Name, Billing_Id__c, AccMigrationFlag__c, Master_Account__c, Master_Account__r.Billing_Id__c,
                Master_Account__r.AccMigrationFlag__c
                FROM Account WHERE Billing_Id__c = :accountMigrationToolData.Technical_Account_Id__c];
        technicalPackage = [SELECT Id, Name, Account__c, Account__r.Billing_Id__c, Account__r.RC_User_Id__c, 
                MasterAccount__r.RC_User_Id__c, MasterAccount__r.Billing_Id__c, RC_User_Id__c,
                Enterprise_Account_Id__r.RC_User_Id__c, 
                Enterprise_Account_ID__c, Account_Package_Id__c, Package_Transfer_Logs__c, Service_Type__c 
                FROM Package__c WHERE Account_Package_Id__c = :accountMigrationToolData.Package_Id__c];
        technicalPackage.Package_Transfer_Logs__c = '';
    }
    
    public static void unlockAccountsForQuoting(String masterAccIdForUnlock) {
        try {
            List<Account> accounts = new List<Account>();
            
            Account masterAccount = new Account(
                Id = masterAccIdForUnlock,
                AccMigrationFlag__c = null
            );
            accounts.add(masterAccount);
            
            Account technicalAccount = new Account(
                Id = technicalAccount.Id,
                AccMigrationFlag__c = null
            );
            accounts.add(technicalAccount);
            
            update accounts;
            System.debug('Successfully unlocked accounts for quoting');
        } catch (Exception e) {
            System.debug('Failed to unlock accounts for quoting: ' + e.getMessage());
            logSalesforceErrors(e.getMessage());
        }
    }
    
    public static Boolean performPackagesMigration(Boolean validationOnly) {
        Boolean result = true;
        String endpointString = NGBSAPI.NGBS_ACCOUNT_MANAGER + '/' + technicalAccount.Billing_Id__c +
                                '/package/' + technicalPackage.Account_Package_Id__c + '/transfer?&validationOnly=' +
                                validationOnly;
        String requestPayload = '{"toAccountId":' + technicalAccount.Master_Account__r.Billing_Id__c + '}';

        result = movePackageRequest(endpointString, requestPayload);

        if (!validationOnly) {
            if (!result) {
                performPackageRevert();
            }
        }

        return result;
    }

    public static Boolean performPackageRevert() {
        String endpointString = NGBSAPI.NGBS_ACCOUNT_MANAGER + '/' + technicalAccount.Master_Account__r.Billing_Id__c +
                                '/package/' + technicalPackage.Account_Package_Id__c + '/transfer';
        String requestPayload = '{"toAccountId":' + technicalAccount.Billing_Id__c + '}';
        return movePackageRequest(endpointString, requestPayload);
    }

    public static Boolean movePackageRequest(String endpointString, String requestPayload) {
        Boolean result = true;
        try {
            HttpResponse response = NGBSAPI.requestNGBS(endpointString, 
                                                        HttpHelper.METHOD_POST, 
                                                        requestPayload, 
                                                        HttpHelper.CONTENT_TYPE_APPLICATION_JSON,
                                                        null);
            
            Integer ngbsStatus = response.getStatusCode();
            logNGBSResponse(String.valueOf(ngbsStatus), response.getBody());
            if (ngbsStatus != 200) {
                result = false;
            }
        } catch (NGBSAPI.NGBSAPIException ex) {
            result = false;
            logNGBSResponse('Error', ex?.getMessage());
            System.debug('Package Moving Error: ' + ex?.getMessage());
        }
        return result;
    }

    public static void getStatusFromNGBS(String fromAccountId, String packageId, String toAccountId) {
        try {
            String endpointString = NGBSAPI.NGBS_ACCOUNT_MANAGER + '/' + fromAccountId +
                                    '/package/' + packageId + '/transfer?toAccountId=' +
                                    toAccountId;
            HttpResponse response = NGBSAPI.requestNGBS(endpointString, 
                                                        HttpHelper.METHOD_GET, 
                                                        null, 
                                                        HttpHelper.CONTENT_TYPE_APPLICATION_JSON,
                                                        null);
            
            Integer ngbsStatus = response.getStatusCode();
            logNGBSResponse(String.valueOf(ngbsStatus), response.getBody());
        } catch (NGBSAPI.NGBSAPIException ex) {
            logNGBSResponse('Error', ex?.getMessage());
        }
    }


    
    public static Boolean performCCBCallout() {
        Boolean result = true;
        String endpoint = CCBAPI.CCB_SETTINGS.BaseEndpoint__c + 
                          '/ringcx/migrate/enterprise-account-id/' + 
                          technicalPackage.Enterprise_Account_Id__r.RC_User_Id__c;
        Map<String, String> payload = new Map<String, String>{
            'toEnterpriseAccountId' => technicalPackage.Account__r.RC_User_Id__c
        };
        String header = HttpHelper.prepareJWTAuthHeader(HttpHelper.CERT_DEV_NAME_CCB);

        try {
            HttpResponse response = CCBAPI.requestCCB(endpoint, 
                                                      HttpHelper.METHOD_PATCH, 
                                                      JSON.serialize(payload), 
                                                      HttpHelper.CONTENT_TYPE_APPLICATION_JSON, 
                                                      header);

            Integer ccbStatus = response.getStatusCode();
            logCCBResponse(String.valueOf(ccbStatus), response.getBody());
            if (ccbStatus != 200) {
                result = false;
            }
        } catch (Exception ex) {
            logCCBResponse('Error', ex.getMessage());
            result = false;
        }

        return result;
    }
    
    public static Boolean performICBCallout() {
        Boolean result = true;
        String endpoint = ICBAPI.ICB_SETTINGS.BaseEndpoint__c + 
                          '/v1/sfdc/migration/icb/accounts/' + 
                          technicalPackage.Enterprise_Account_Id__r.RC_User_Id__c;
        Map<String, String> payload = new Map<String, String>{
            'toEnterpriseAccountId' => technicalPackage.Account__r.RC_User_Id__c,
            'toBillingAccountId' => technicalPackage.Account__r.Billing_Id__c
        };

        try {
            HttpResponse response = ICBAPI.requestICB(endpoint, HttpHelper.METHOD_POST, JSON.serialize(payload));
            Integer icbStatus = response.getStatusCode();
            logICBResponse(String.valueOf(icbStatus), response.getBody());
            if (icbStatus != 200) {
                result = false;
            }
        } catch (Exception ex) {
            logICBResponse('Error', ex.getMessage());
            result = false;
        }

        return result;
    }
    
    public static void updatePackageRecords() {
        try {
            technicalPackage.Enterprise_Account_ID__c = technicalAccount.Master_Account__c;
            System.debug('Package records updated successfully with Account ID: ' + technicalAccount.Master_Account__c);
        } catch (Exception e) {
            logSalesforceErrors(e.getMessage());
        }
    }
    
    public static void unlinkTechnicalAccounts() {
        try {
            technicalAccount.Historical_Master_Account__c = technicalAccount.Master_Account__c;
            technicalAccount.Master_Account__c = null;
            technicalAccount.RC_Account_Status__c = 'Deleted';
            
            System.debug('Technical accounts unlinked from master account successfully');
        } catch (Exception e) {
            logSalesforceErrors(e.getMessage());
        }
    }
}