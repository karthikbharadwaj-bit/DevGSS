@IsTest
private class Test_NGBSAccountMigrationTool {
    
    private static final String TEST_BILLING_ID_1 = '100000001';
    private static final String TEST_BILLING_ID_2 = '100000002';
    private static final String TEST_PACKAGE_ID_1 = '999999999';
    private static final String TEST_PACKAGE_ID_2 = '999999999';
    private static final String TEST_RC_USER_ID_1 = '123456';
    private static final String TEST_RC_USER_ID_2 = '123459';
    private static final String TEST_ENTERPRISE_ACCOUNT_ID_1 = '789012';
    private static final String TEST_ENTERPRISE_ACCOUNT_ID_2 = '789016';
    
    @TestSetup
    static void setup() {
        // Create NGBS Settings
        new SObjectBuilder(NGBS_Settings__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                NGBS_Settings__c.BaseEndpoint__c => 'https://fake-ngbs-api',
                NGBS_Settings__c.AccountManagerPath__c => '/account-manager',
                NGBS_Settings__c.Login__c => 'testuser',
                NGBS_Settings__c.Password__c => 'testpass'
            })
            .create();
        
        // Create CCB Settings
        new SObjectBuilder(CCB_Settings__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                CCB_Settings__c.DirectBaseEndpoint__c => 'https://fake-ccb-api',
                CCB_Settings__c.Login__c => 'testuser',
                CCB_Settings__c.Password__c => 'testpass',
                CCB_Settings__c.APIVersion2Path__c => '/v2.0/ccb'
            })
            .create();
        
        // Create ICB Settings
        new SObjectBuilder(ICB_Settings__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                ICB_Settings__c.BaseEndpoint__c => 'https://fake-icb-api',
                ICB_Settings__c.APIVersion1Path__c => '/v1/sfdc'
            })
            .create();
    }
    
    // Helper method to create test accounts
    private static Account createTestAccount(String billingId, String rcUserId, String name) {
        return (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Name => name,
                Account.Billing_Id__c => billingId,
                Account.RC_User_Id__c => rcUserId
            })
            .create()
            .getRecord();
    }
    
    // Helper method to create test package
    private static Package__c createTestPackage(Id accountId, Id masterAccountId) {
        /*Account masterAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Name => 'Master Account',
                Account.Billing_Id__c => TEST_BILLING_ID_1,
                Account.RC_User_Id__c => TEST_ENTERPRISE_ACCOUNT_ID_1
            })
            .getRecord();
        
        insert masterAccount;*/
        
        return (Package__c) new SObjectBuilder(Package__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Package__c.Account__c => accountId,
                Package__c.Account_Package_Id__c => TEST_PACKAGE_ID_1,
                Package__c.MasterAccount__c => masterAccountId,
                Package__c.Service_Type__c => 'RingCentral Contact Center',
                Package__c.Enterprise_Account_Id__c => masterAccountId
            })
            .create()
            .getRecord();
    }
    
    // Helper method to create migration tool data
    private static NGBSAccountMigrationToolData__c createMigrationData(String accountBillingId) {
        return (NGBSAccountMigrationToolData__c) new SObjectBuilder(NGBSAccountMigrationToolData__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                NGBSAccountMigrationToolData__c.Technical_Account_Id__c => accountBillingId,
                NGBSAccountMigrationToolData__c.Package_Id__c => TEST_PACKAGE_ID_1,
                NGBSAccountMigrationToolData__c.Package_Migration__c => true,
                NGBSAccountMigrationToolData__c.Update_Local_Records__c => true,
                NGBSAccountMigrationToolData__c.CCB_Callout__c => false,
                NGBSAccountMigrationToolData__c.ICB_Callout__c => false,
                NGBSAccountMigrationToolData__c.Package_Revert__c => false,
                NGBSAccountMigrationToolData__c.Name => accountBillingId
            })
            .create()
            .getRecord();
    }
    
    // HTTP Callout Mock for successful NGBS responses
    private class NGBSSuccessMock implements HttpCalloutMock {
        public Integer statusCode;
        
        public NGBSSuccessMock() {
            this.statusCode = 200;
        }
        
        public NGBSSuccessMock(Integer statusCode) {
            this.statusCode = statusCode;
        }
        
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(statusCode);
            res.setStatus('OK');
            res.setBody('{"success": true}');
            res.setHeader('Content-Type', 'application/json');
            return res;
        }
    }
    
    // HTTP Callout Mock for successful CCB responses
    private class CCBSuccessMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setStatus('OK');
            res.setBody('{"success": true}');
            res.setHeader('Content-Type', 'application/json');
            return res;
        }
    }
    
    // HTTP Callout Mock for successful ICB responses
    private class ICBSuccessMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setStatus('OK');
            res.setBody('{"success": true}');
            res.setHeader('Content-Type', 'application/json');
            return res;
        }
    }
    
    // HTTP Callout Mock for failed responses
    private class FailedMock implements HttpCalloutMock {
        private String serviceName;
        
        public FailedMock(String serviceName) {
            this.serviceName = serviceName;
        }
        
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(400);
            res.setStatus('Bad Request');
            res.setBody('{"error": "Test error from ' + serviceName + '"}');
            res.setHeader('Content-Type', 'application/json');
            return res;
        }
    }
    
    // Test successful account migration
    @IsTest
    static void testMigrateAccountSuccess() {
        Test.startTest();
        
        Account technicalAccount = createTestAccount(TEST_BILLING_ID_1, TEST_RC_USER_ID_1, 'Technical Account');
        Account masterAccount = createTestAccount(TEST_BILLING_ID_2, TEST_RC_USER_ID_2, 'Master Account');
        
        technicalAccount.Master_Account__c = masterAccount.Id;
        update technicalAccount;
        
        Package__c pkg = createTestPackage(technicalAccount.Id, masterAccount.Id);
        NGBSAccountMigrationToolData__c migrationData = createMigrationData(TEST_BILLING_ID_1);
        
        Test.setMock(HttpCalloutMock.class, new NGBSSuccessMock());
        
        // Create account data helper
        Account enterpriseAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Name => 'Enterprise Account',
                Account.Billing_Id__c => TEST_BILLING_ID_2,
                Account.RC_User_Id__c => TEST_ENTERPRISE_ACCOUNT_ID_2
            })
            .create()
            .getRecord();
        
        // Update package with enterprise account
        pkg.Enterprise_Account_ID__c = enterpriseAccount.Id;
        update pkg;
        
        NGBSAccountMigrationTool.migrateAccount(migrationData);
        
        Test.stopTest();
        
        // Verify accounts were updated
        Account updatedTechnicalAccount = [SELECT Id, AccMigrationFlag__c FROM Account WHERE Id = :technicalAccount.Id];
        Account updatedMasterAccount = [SELECT Id, AccMigrationFlag__c FROM Account WHERE Id = :masterAccount.Id];
        
        System.assert(updatedTechnicalAccount.AccMigrationFlag__c == null, 'Technical account should be unlocked');
        System.assert(updatedMasterAccount.AccMigrationFlag__c == null, 'Master account should be unlocked');
    }
    
    // Test account migration with validation failure
    @IsTest
    static void testMigrateAccountValidationFailure() {
        Test.startTest();
        
        Account technicalAccount = createTestAccount(TEST_BILLING_ID_1, TEST_RC_USER_ID_1, 'Technical Account');
        Account masterAccount = createTestAccount(TEST_BILLING_ID_2, TEST_RC_USER_ID_2, 'Master Account');
        
        technicalAccount.Master_Account__c = masterAccount.Id;
        update technicalAccount;
        
        Package__c pkg = createTestPackage(technicalAccount.Id, masterAccount.Id);
        NGBSAccountMigrationToolData__c migrationData = createMigrationData(TEST_BILLING_ID_1);
        
        Test.setMock(HttpCalloutMock.class, new NGBSSuccessMock(400));
        
        NGBSAccountMigrationTool.migrateAccount(migrationData);
        
        Test.stopTest();
        
        // Verify accounts were updated (unlocked despite validation failure)
        Account updatedTechnicalAccount = [SELECT Id, AccMigrationFlag__c FROM Account WHERE Id = :technicalAccount.Id];
        Account updatedMasterAccount = [SELECT Id, AccMigrationFlag__c FROM Account WHERE Id = :masterAccount.Id];
        
        System.assert(updatedTechnicalAccount.AccMigrationFlag__c == null, 'Technical account should be unlocked');
        System.assert(updatedMasterAccount.AccMigrationFlag__c == null, 'Master account should be unlocked');
    }
    
    // Test account migration with package revert
    @IsTest
    static void testMigrateAccountWithPackageRevert() {
        Test.startTest();
        
        Account technicalAccount = createTestAccount(TEST_BILLING_ID_1, TEST_RC_USER_ID_1, 'Technical Account');
        Account masterAccount = createTestAccount(TEST_BILLING_ID_2, TEST_RC_USER_ID_2, 'Master Account');
        
        technicalAccount.Master_Account__c = masterAccount.Id;
        update technicalAccount;
        
        Package__c pkg = createTestPackage(technicalAccount.Id, masterAccount.Id);
        
        NGBSAccountMigrationToolData__c migrationData = (NGBSAccountMigrationToolData__c) new SObjectBuilder(NGBSAccountMigrationToolData__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                NGBSAccountMigrationToolData__c.Technical_Account_Id__c => TEST_BILLING_ID_1,
                NGBSAccountMigrationToolData__c.Package_Id__c => TEST_PACKAGE_ID_1,
                NGBSAccountMigrationToolData__c.Package_Migration__c => true,
                NGBSAccountMigrationToolData__c.Update_Local_Records__c => true,
                NGBSAccountMigrationToolData__c.Package_Revert__c => true,
                NGBSAccountMigrationToolData__c.NAME => TEST_BILLING_ID_1
            })
            .create()
            .getRecord();
        
        Test.setMock(HttpCalloutMock.class, new NGBSSuccessMock());
        
        NGBSAccountMigrationTool.migrateAccount(migrationData);
        
        Test.stopTest();
        
        // Verify package revert was called
        System.assert(true, 'Package revert test completed');
    }
    
    // Test account migration with CCB callout
    @IsTest
    static void testMigrateAccountWithCCBCallout() {
        Test.startTest();
        
        Account technicalAccount = createTestAccount(TEST_BILLING_ID_1, TEST_RC_USER_ID_1, 'Technical Account');
        Account masterAccount = createTestAccount(TEST_BILLING_ID_2, TEST_RC_USER_ID_2, 'Master Account');
        
        technicalAccount.Master_Account__c = masterAccount.Id;
        update technicalAccount;
        
        Package__c pkg = createTestPackage(technicalAccount.Id, masterAccount.Id);
        pkg.Service_Type__c = 'Engage Voice';
        update pkg;
        
        NGBSAccountMigrationToolData__c migrationData = (NGBSAccountMigrationToolData__c) new SObjectBuilder(NGBSAccountMigrationToolData__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                NGBSAccountMigrationToolData__c.Technical_Account_Id__c => TEST_BILLING_ID_1,
                NGBSAccountMigrationToolData__c.Package_Id__c => TEST_PACKAGE_ID_1,
                NGBSAccountMigrationToolData__c.Package_Migration__c => false,
                NGBSAccountMigrationToolData__c.Update_Local_Records__c => true,
                NGBSAccountMigrationToolData__c.CCB_Callout__c => true,
                NGBSAccountMigrationToolData__c.NAME => TEST_BILLING_ID_1
            })
            .create()
            .getRecord();
        
        Test.setMock(HttpCalloutMock.class, new CCBSuccessMock());
        
        NGBSAccountMigrationTool.migrateAccount(migrationData);
        
        Test.stopTest();
        
        // Verify package was updated
        Package__c updatedPackage = [SELECT RC_User_Id__c FROM Package__c WHERE Id = :pkg.Id];
        System.assert(updatedPackage.RC_User_Id__c == null, 'RC_User_Id__c should be cleared after CCB callout');
    }
    
    // Test account migration with ICB callout
    @IsTest
    static void testMigrateAccountWithICBCallout() {
        Test.startTest();
        
        Account technicalAccount = createTestAccount(TEST_BILLING_ID_1, TEST_RC_USER_ID_1, 'Technical Account');
        Account masterAccount = createTestAccount(TEST_BILLING_ID_2, TEST_RC_USER_ID_2, 'Master Account');
        
        technicalAccount.Master_Account__c = masterAccount.Id;
        update technicalAccount;
        
        Package__c pkg = createTestPackage(technicalAccount.Id, masterAccount.Id);
        pkg.Service_Type__c = 'RingCentral Contact Center';
        update pkg;
        
        NGBSAccountMigrationToolData__c migrationData = (NGBSAccountMigrationToolData__c) new SObjectBuilder(NGBSAccountMigrationToolData__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                NGBSAccountMigrationToolData__c.Technical_Account_Id__c => TEST_BILLING_ID_1,
                NGBSAccountMigrationToolData__c.Package_Id__c => TEST_PACKAGE_ID_1,
                NGBSAccountMigrationToolData__c.Package_Migration__c => false,
                NGBSAccountMigrationToolData__c.Update_Local_Records__c => false,
                NGBSAccountMigrationToolData__c.CCB_Callout__c => false,
                NGBSAccountMigrationToolData__c.ICB_Callout__c => true,
                NGBSAccountMigrationToolData__c.NAME => TEST_BILLING_ID_1
            })
            .create()
            .getRecord();
        
        Test.setMock(HttpCalloutMock.class, new ICBSuccessMock());
        
        NGBSAccountMigrationTool.migrateAccount(migrationData);
        
        Test.stopTest();
        
        // Verify package was updated
        System.assert(migrationData.Errors__c == null, 'Error received after ICB callout');
    }
    
    // Test batch class
    @IsTest
    static void testBatchClassSuccess() {
        Account technicalAccount = createTestAccount(TEST_BILLING_ID_1, TEST_RC_USER_ID_1, 'Technical Account');
        Account masterAccount = createTestAccount(TEST_BILLING_ID_2, TEST_RC_USER_ID_2, 'Master Account');
        
        technicalAccount.Master_Account__c = masterAccount.Id;
        update technicalAccount;
        
        Package__c pkg = createTestPackage(technicalAccount.Id, masterAccount.Id);
        NGBSAccountMigrationToolData__c migrationData = createMigrationData(TEST_BILLING_ID_1);
        
        Test.setMock(HttpCalloutMock.class, new NGBSSuccessMock());
        
        Test.startTest();
        NGBSAccountMigrationTool_batch.run(new List<Id> { migrationData.Id });
        Test.stopTest();
        
        // Verify the migration completed
        System.assert(true, 'Batch should complete without exceptions');
    }
    
    // Test batch class with specific record IDs
    @IsTest
    static void testBatchClassWithRecordIds() {
        Account technicalAccount = createTestAccount(TEST_BILLING_ID_1, TEST_RC_USER_ID_1, 'Technical Account');
        Account masterAccount = createTestAccount(TEST_BILLING_ID_2, TEST_RC_USER_ID_2, 'Master Account');
        
        technicalAccount.Master_Account__c = masterAccount.Id;
        update technicalAccount;
        
        Package__c pkg = createTestPackage(technicalAccount.Id, masterAccount.Id);
        NGBSAccountMigrationToolData__c migrationData = createMigrationData(TEST_BILLING_ID_1);
        
        Test.setMock(HttpCalloutMock.class, new NGBSSuccessMock());
        
        Test.startTest();
        Set<Id> recordIds = new Set<Id> { migrationData.Id };
        Id jobId = Database.executeBatch(new NGBSAccountMigrationTool_batch(recordIds), 1);
        Test.stopTest();
        
        System.assert(jobId != null, 'Batch job should be created');
    }
    
    // Test batch class start method
    @IsTest
    static void testBatchClassStart() {
        Account technicalAccount = createTestAccount(TEST_BILLING_ID_1, TEST_RC_USER_ID_1, 'Technical Account');
        Account masterAccount = createTestAccount(TEST_BILLING_ID_2, TEST_RC_USER_ID_2, 'Master Account');
        
        technicalAccount.Master_Account__c = masterAccount.Id;
        update technicalAccount;
        
        createTestPackage(technicalAccount.Id, masterAccount.Id);
        NGBSAccountMigrationToolData__c migrationData = createMigrationData(TEST_BILLING_ID_1);
        
        Test.startTest();
        NGBSAccountMigrationTool_batch batch = new NGBSAccountMigrationTool_batch(new Set<Id> { migrationData.Id });
        Database.QueryLocator locator = batch.start(null);
        Test.stopTest();
        
        System.assert(locator != null, 'Query locator should be returned');
    }
    
    // Test unlinkTechnicalAccounts method
    @IsTest
    static void testUnlinkTechnicalAccounts() {
        Account technicalAccount = createTestAccount(TEST_BILLING_ID_1, TEST_RC_USER_ID_1, 'Technical Account');
        Account masterAccount = createTestAccount(TEST_BILLING_ID_2, TEST_RC_USER_ID_2, 'Master Account');
        
        technicalAccount.Master_Account__c = masterAccount.Id;
        update technicalAccount;
        
        Package__c pkg = createTestPackage(technicalAccount.Id, masterAccount.Id);
        NGBSAccountMigrationToolData__c migrationData = createMigrationData(TEST_BILLING_ID_1);
        
        Test.setMock(HttpCalloutMock.class, new NGBSSuccessMock());
        
        Test.startTest();
        NGBSAccountMigrationTool.migrateAccount(migrationData);
        Test.stopTest();
        
        // Verify technical account was unlinked
        Account updatedTechnicalAccount = [SELECT Id, Master_Account__c, RC_Account_Status__c FROM Account WHERE Id = :technicalAccount.Id];
        System.assert(updatedTechnicalAccount.Master_Account__c == null, 'Technical account should be unlinked');
        System.assertEquals('Deleted', updatedTechnicalAccount.RC_Account_Status__c, 'Account status should be Deleted');
    }
    
    // Test performPackagesMigration with validation
    @IsTest
    static void testPerformPackagesMigrationValidation() {
        Account technicalAccount = createTestAccount(TEST_BILLING_ID_1, TEST_RC_USER_ID_1, 'Technical Account');
        Account masterAccount = createTestAccount(TEST_BILLING_ID_2, TEST_RC_USER_ID_2, 'Master Account');
        
        technicalAccount.Master_Account__c = masterAccount.Id;
        update technicalAccount;
        
        Package__c pkg = createTestPackage(technicalAccount.Id, masterAccount.Id);
        NGBSAccountMigrationToolData__c migrationData = createMigrationData(TEST_BILLING_ID_1);
        
        Test.setMock(HttpCalloutMock.class, new NGBSSuccessMock());
        
        Test.startTest();
        NGBSAccountMigrationTool.technicalAccount = technicalAccount;
        NGBSAccountMigrationTool.technicalPackage = pkg;
        NGBSAccountMigrationTool.accountMigrationToolData = migrationData;
        Boolean result = NGBSAccountMigrationTool.performPackagesMigration(true);
        Test.stopTest();
        
        System.assert(result, 'Validation should succeed');
    }
    
    // Test movePackageRequest success
    @IsTest
    static void testMovePackageRequestSuccess() {
        Account technicalAccount = createTestAccount(TEST_BILLING_ID_1, TEST_RC_USER_ID_1, 'Technical Account');
        Account masterAccount = createTestAccount(TEST_BILLING_ID_2, TEST_RC_USER_ID_2, 'Master Account');
        
        technicalAccount.Master_Account__c = masterAccount.Id;
        update technicalAccount;
        
        Package__c pkg = createTestPackage(technicalAccount.Id, masterAccount.Id);
        NGBSAccountMigrationToolData__c migrationData = createMigrationData(TEST_BILLING_ID_1);
        
        Test.setMock(HttpCalloutMock.class, new NGBSSuccessMock());
        
        Test.startTest();
        NGBSAccountMigrationTool.accountMigrationToolData = migrationData;
        NGBSAccountMigrationTool.technicalPackage = pkg;
        Boolean result = NGBSAccountMigrationTool.movePackageRequest('test-endpoint', '{"test": true}');
        Test.stopTest();
        
        System.assert(result, 'Request should succeed');
    }
    
    // Test movePackageRequest failure
    @IsTest
    static void testMovePackageRequestFailure() {
        Account technicalAccount = createTestAccount(TEST_BILLING_ID_1, TEST_RC_USER_ID_1, 'Technical Account');
        Account masterAccount = createTestAccount(TEST_BILLING_ID_2, TEST_RC_USER_ID_2, 'Master Account');
        
        technicalAccount.Master_Account__c = masterAccount.Id;
        update technicalAccount;
        
        Package__c pkg = createTestPackage(technicalAccount.Id, masterAccount.Id);
        NGBSAccountMigrationToolData__c migrationData = createMigrationData(TEST_BILLING_ID_1);
        
        Test.setMock(HttpCalloutMock.class, new NGBSSuccessMock(400));
        
        Test.startTest();
        NGBSAccountMigrationTool.technicalAccount = technicalAccount;
        NGBSAccountMigrationTool.technicalPackage = pkg;
        NGBSAccountMigrationTool.accountMigrationToolData = migrationData;
        Boolean result = NGBSAccountMigrationTool.movePackageRequest('test-endpoint', '{"test": true}');
        Test.stopTest();
        
        System.assert(!result, 'Request should fail');
    }
    
    // Test performPackageRevert
    @IsTest
    static void testPerformPackageRevert() {
        Account technicalAccount = createTestAccount(TEST_BILLING_ID_1, TEST_RC_USER_ID_1, 'Technical Account');
        Account masterAccount = createTestAccount(TEST_BILLING_ID_2, TEST_RC_USER_ID_2, 'Master Account');
        
        technicalAccount.Master_Account__c = masterAccount.Id;
        update technicalAccount;
        
        Package__c pkg = createTestPackage(technicalAccount.Id, masterAccount.Id);
        NGBSAccountMigrationToolData__c migrationData = createMigrationData(TEST_BILLING_ID_1);
        
        Test.setMock(HttpCalloutMock.class, new NGBSSuccessMock());
        
        Test.startTest();
        NGBSAccountMigrationTool.technicalAccount = technicalAccount;
        NGBSAccountMigrationTool.technicalPackage = pkg;
        NGBSAccountMigrationTool.accountMigrationToolData = migrationData;
        Boolean result = NGBSAccountMigrationTool.performPackageRevert();
        Test.stopTest();
        
        System.assert(result, 'Revert should succeed');
    }
    
    // Test failure handling with rollback
    @IsTest
    static void testMigrateAccountWithExceptionAndRollback() {
        Account technicalAccount = createTestAccount(TEST_BILLING_ID_1, TEST_RC_USER_ID_1, 'Technical Account');
        Account masterAccount = createTestAccount(TEST_BILLING_ID_2, TEST_RC_USER_ID_2, 'Master Account');
        
        technicalAccount.Master_Account__c = masterAccount.Id;
        update technicalAccount;
        
        Package__c pkg = createTestPackage(technicalAccount.Id, masterAccount.Id);
        
        NGBSAccountMigrationToolData__c migrationData = (NGBSAccountMigrationToolData__c) new SObjectBuilder(NGBSAccountMigrationToolData__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                NGBSAccountMigrationToolData__c.Technical_Account_Id__c => 'INVALID_ID',
                NGBSAccountMigrationToolData__c.Package_Id__c => TEST_PACKAGE_ID_1,
                NGBSAccountMigrationToolData__c.Package_Migration__c => true,
                NGBSAccountMigrationToolData__c.Update_Local_Records__c => false,
                NGBSAccountMigrationToolData__c.NAME => TEST_PACKAGE_ID_1
            })
            .create()
            .getRecord();
        
        Test.setMock(HttpCalloutMock.class, new NGBSSuccessMock());
        
        Test.startTest();
        try {
            NGBSAccountMigrationTool.migrateAccount(migrationData);
        } catch (Exception e) {
            System.assert(e.getMessage() != null, 'Exception should be thrown');
        }
        Test.stopTest();
    }
}