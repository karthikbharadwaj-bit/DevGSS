@isTest
private class Test_CCMigrationAccountSvc {
    private static final String ACCOUNT_NAME = 'Test';
    private static final String CONTACT_EMAIL = 'test@test.com';
    private static final String CONTACT_FIRST_NAME = 'Test';
    private static final String CONTACT_LAST_NAME = 'Test';
    private static final String ENTERPRISE_ACCOUNT_ID_FIRST = '130486990';
    private static final String ENTERPRISE_ACCOUNT_ID_SECOND = '130486991';
    private static final String ENTERPRISE_ACCOUNT_ID_THIRD = '130486992';
    private static final String ENTERPRISE_ACCOUNT_ID_FOUR = '130486993';
    private static final String RC_CONTACT_CENTER_PREFIX = ' [system: RingCentral Contact Center]';
    private static final String RESPONSE_BODY_STATUS_MSG = 'The status of the response body is not as expected';
    private static final String RESPONSE_BODY_MESSAGE_MSG = 'The message of the response body is not as expected';
    private static final String RESPONSE_BODY_MESSAGE_DETAILS_MSG = 'The message details of the response body are not as expected';
    private static final String OPPTY_NOT_DELETED = 'The technical opportunity was not deleted';
    private static final String ORDER_NOT_DELETED = 'The order was not deleted';
    private static final String APPROVAL_NOT_DELETED = 'The approval was not deleted';
    private static final String QUOTE_NOT_DELETED = 'The quote was not deleted';
    private static final String INCORRECT_MIGRATION_FLAG = 'Incorrect Migration Flag';
    private static final String INCORRECT_ORDER_STATUS = 'Incorrect Order Status';

    @TestSetup
    static void createTestData(){
        new SObjectBuilder(RCSequence__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                RCSequence__c.SubSequence__c => 134
            })
            .create();

        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => ACCOUNT_NAME,
                    Account.IsMultiProductTechnicalAccount__c => false,
                    Account.Service_Type__c => AccountHelper.SERVICE_TYPE_OFFICE,
                    Account.RC_User_ID__c => ENTERPRISE_ACCOUNT_ID_FIRST,
                    Account.BillingStreet => '20 Davis Drive',
                    Account.BillingCity => 'Belmont',
                    Account.BillingState => 'CA',
                    Account.BillingPostalCode => '94002',
                    Account.BillingCountry => 'United States',
                    Account.AccMigrationFlag__c => AccountHelper.ACCOUNT_MIGRATION_TYPE_SCHEDULED_BLOCKED,
                    Account.Payment_Plan__c => AccountHelper.ACCOUNT_PAYMENT_PLAN_MONTHLY
                }
            )
            .build()
            .getRecord();

        Account acc2 = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => ACCOUNT_NAME,
                    Account.IsMultiProductTechnicalAccount__c => false,
                    Account.Service_Type__c => AccountHelper.SERVICE_TYPE_OFFICE,
                    Account.RC_User_ID__c => ENTERPRISE_ACCOUNT_ID_THIRD,
                    Account.BillingStreet => '20 Davis Drive',
                    Account.BillingCity => 'Belmont',
                    Account.BillingState => 'CA',
                    Account.BillingPostalCode => '94002',
                    Account.BillingCountry => 'United States',
                    Account.RC_Brand__c => 'RingCentral',
                    Account.AccMigrationFlag__c => AccountHelper.ACCOUNT_MIGRATION_TYPE_IN_PROGRESS_BLOCKED
                }
            )
            .build()
            .getRecord();

        insert new List<Account> {acc, acc2};

        Contact contact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(Contact.SObjectType))
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.AccountId => acc.Id,
                    Contact.Email => CONTACT_EMAIL,
                    Contact.FirstName => CONTACT_FIRST_NAME,
                    Contact.LastName => CONTACT_LAST_NAME
                }
            )
            .create()
            .getRecord();

        new SObjectBuilder(AccountContactRole.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    AccountContactRole.AccountId => acc.Id,
                    AccountContactRole.ContactId => contact.Id,
                    AccountContactRole.Role => OpportunityHelper.CONTACT_ROLE_SIGNATORY,
                    AccountContactRole.IsPrimary => true
                }
            )
            .create();

        PriceBook2 pb = (PriceBook2) new SObjectBuilder(PriceBook2.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                PriceBook2.Name => ValueProviderBuilder.provideUniqueString(),
                PriceBook2.IsActive => true,
                PriceBook2.Line_Range_Min__c => 2,
                PriceBook2.Plan__c => Pricebook2Helper.PLAN_ANNUAL,
                PriceBook2.AllowedRecordType__c => QuoteHelper.ALLOWED_RT_NAME_BILLING_PROSERV
            })
            .create()
            .getRecord();

        Product2 prod = (Product2) new SObjectBuilder(Product2.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Product2.Name => 'testProduct',
                Product2.Sub_Category__c => Product2Helper.SUBCATEGORY_RINGCENTRAL,
                Product2.IsActive => true
            })
            .create()
            .getRecord();

        new SObjectBuilder(PricebookEntry.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                PricebookEntry.Product2Id => prod.Id
            })
            .create();

        new SObjectBuilder(PricebookEntry.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                PricebookEntry.Pricebook2Id => pb.Id,
                PricebookEntry.Product2Id => prod.Id,
                PricebookEntry.UnitPrice => 100,
                PricebookEntry.IsActive => true,
                PricebookEntry.UseStandardPrice => false
            })
            .create();
    }

    @isTest
    private static void testCreateRCCCTechnicalAccount() {
        RestRequest req = new RestRequest();
        req.requestBody = createRequestBody(CCMigrationAccountSvc.MIGRATE_TYPE, ENTERPRISE_ACCOUNT_ID_FIRST);
        RestContext.request = req;

        Test.startTest();
        CCMigrationAccountSvc.doPost();
        Test.stopTest();

        String responseBody = RestContext.response.responseBody.toString();

        CCMigrationAccountSvc.ResponseParams responseParams = (CCMigrationAccountSvc.ResponseParams)
            JSON.deserialize(responseBody, CCMigrationAccountSvc.ResponseParams.class);

        Account masterAccount = selectTestMasterAccount(ENTERPRISE_ACCOUNT_ID_FIRST);
        Account technicalAccount = selectTechnicalAccount(masterAccount.Id);
        Assert.areEqual(AccountHelper.ACCOUNT_PAYMENT_PLAN_MONTHLY, technicalAccount.Payment_Plan__c, 'Account Payment Plan should be \'' + AccountHelper.ACCOUNT_PAYMENT_PLAN_MONTHLY + '\'');
        handleAsserts(responseParams, technicalAccount);
    }

    @isTest
    private static void testHandleIncorrectRequestBody() {
        RestRequest req = new RestRequest();
        req.requestBody = createRequestBody('test', ENTERPRISE_ACCOUNT_ID_FIRST);
        RestContext.request = req;

        Test.startTest();
        CCMigrationAccountSvc.doPost();
        Test.stopTest();

        String responseBody = RestContext.response.responseBody.toString();

        CCMigrationAccountSvc.ResponseParams responseParams = (CCMigrationAccountSvc.ResponseParams)
            JSON.deserialize(responseBody, CCMigrationAccountSvc.ResponseParams.class);

        Assert.areEqual(Response.STATUS_ERROR, responseParams.status, RESPONSE_BODY_STATUS_MSG);
        Assert.areEqual(responseParams.messages.get(0).message, CCMigrationAccountSvc.BAD_REQUEST_MESSAGE, RESPONSE_BODY_MESSAGE_MSG);
        Assert.areEqual(responseParams.messages.get(0).messageDetails, CCMigrationAccountSvc.INCORRECT_REQUEST_BODY, RESPONSE_BODY_MESSAGE_DETAILS_MSG);

        assertPlatformLog(
            responseParams.messages.get(0).message,
            responseParams.messages.get(0).messageDetails
        );
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    private static void testHandleResponseOfExistingTechnicalAccount() {
        Account masterAccount = selectTestMasterAccount(ENTERPRISE_ACCOUNT_ID_FIRST);
        masterAccount.AccMigrationFlag__c = AccountHelper.ACCOUNT_MIGRATION_TYPE_IN_PROGRESS_BLOCKED;
        Triggers.switchOff();
            update masterAccount;
        Triggers.switchOn();

        Account techAccount = createTechnicalAccount(masterAccount);
        RestRequest req = new RestRequest();
        req.requestBody = createRequestBody(CCMigrationAccountSvc.MIGRATE_TYPE, ENTERPRISE_ACCOUNT_ID_FIRST);
        RestContext.request = req;

        Test.startTest();
        CCMigrationAccountSvc.doPost();
        Test.stopTest();

        String responseBody = RestContext.response.responseBody.toString();

        CCMigrationAccountSvc.ResponseParams responseParams = (CCMigrationAccountSvc.ResponseParams)
            JSON.deserialize(responseBody, CCMigrationAccountSvc.ResponseParams.class);

        handleAsserts(responseParams, techAccount);
    }

    @isTest
    private static void testHandleNoSuchEnterpriseAccountId() {
        RestRequest req = new RestRequest();
        req.requestBody = createRequestBody(CCMigrationAccountSvc.MIGRATE_TYPE, ENTERPRISE_ACCOUNT_ID_SECOND);
        RestContext.request = req;

        Test.startTest();
        CCMigrationAccountSvc.doPost();
        Test.stopTest();

        String responseBody = RestContext.response.responseBody.toString();

        CCMigrationAccountSvc.ResponseParams responseParams = (CCMigrationAccountSvc.ResponseParams)
            JSON.deserialize(responseBody, CCMigrationAccountSvc.ResponseParams.class);
        Assert.areEqual(Response.STATUS_ERROR, responseParams.status, RESPONSE_BODY_STATUS_MSG);
        Assert.areEqual(responseParams.messages.get(0).message, CCMigrationAccountSvc.BAD_REQUEST_MESSAGE, RESPONSE_BODY_MESSAGE_MSG);
        Assert.areEqual(responseParams.messages.get(0).messageDetails, CCMigrationAccountSvc.INCORRECT_REQUEST_BODY, RESPONSE_BODY_MESSAGE_DETAILS_MSG);

        assertPlatformLog(
            responseParams.messages.get(0).message,
            responseParams.messages.get(0).messageDetails
        );
    }

    @isTest
    private static void testHandleInvalidRequestBodyJSON() {
        RestRequest req = new RestRequest();
        req.requestBody = createInvalidRequestBody(CCMigrationAccountSvc.MIGRATE_TYPE, ENTERPRISE_ACCOUNT_ID_SECOND);
        RestContext.request = req;

        Test.startTest();
        CCMigrationAccountSvc.doPost();
        Test.stopTest();

        String responseBody = RestContext.response.responseBody.toString();

        CCMigrationAccountSvc.ResponseParams responseParams = (CCMigrationAccountSvc.ResponseParams)
            JSON.deserialize(responseBody, CCMigrationAccountSvc.ResponseParams.class);
        Assert.areEqual(Response.STATUS_ERROR, responseParams.status, RESPONSE_BODY_STATUS_MSG);
        Assert.areEqual(responseParams.messages.get(0).message, IcbHelper.WRONG_JSON_FORMAT, RESPONSE_BODY_MESSAGE_MSG);

        String ccMigrationClassName = '%' + CCMigrationAccountSvc.ACCOUNT_MIGRATION_SERVICE_CLASS_NAME + '%';
        Assert.isTrue(
            [SELECT COUNT() FROM PlatformLog__c WHERE Source__c LIKE :ccMigrationClassName] > 0,
            'At least one PlatformLog__c should be created'
        );
    }

    @isTest
    private static void testHandleRollbackType() {
        Account masterAccount = selectTestMasterAccount(ENTERPRISE_ACCOUNT_ID_THIRD);

        Triggers.switchOff();
        Account techAccount = createTechnicalAccount(masterAccount);
        Contact cont = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Contact.AccountId => techAccount.Id,
                Contact.LastName => 'test',
                Contact.FirstName => 'test',
                Contact.Email => 'test@rc.test'
            })
            .create()
            .getRecord();

        new SObjectBuilder(AccountContactRole.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                AccountContactRole.AccountId => techAccount.Id,
                AccountContactRole.ContactId => cont.Id,
                AccountContactRole.Role => AccountContactRoleHelper.CONTACT_ROLE_ACCOUNT_PAYABLE
            })
            .create();

        Opportunity opp = createTechOpportunity(techAccount);
        Pricebook2 pb = [SELECT Id FROM Pricebook2 WHERE IsStandard = FALSE LIMIT 1];

        Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Quote.OpportunityId => opp.Id,
                Quote.RecordTypeId  => QuoteHelper.RT_ID_BILLING,
                Quote.Package_Info__c => NGBSTestDataGenerator.generateQuotePackageInfo(),
                Quote.isPrimary__c => true,
                Quote.Pricebook2Id => pb.Id,
                Quote.Status => QuoteHelper.QUOTE_STATUS_DRAFT,
                Quote.ServiceName__c => QuoteHelper.NGBS_RCCC_PRODUCT,
                Quote.IsMultiProductTechnicalQuote__c => true
            })
            .create()
            .getRecord();

        Product2 prod = (Product2) new Product2Selector()
            .selectProducts()
            .executeQuery()
            .get(0);

        PriceBookEntry pbeStandard = [SELECT Id FROM PricebookEntry WHERE Pricebook2Id = :Test.getStandardPricebookId() LIMIT 1];
        PriceBookEntry pbe = [SELECT Id FROM PricebookEntry WHERE Pricebook2Id = :pb.Id AND Product2Id = :prod.Id LIMIT 1];

        QuoteLineItem qli = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                QuoteLineItem.QuoteId => qt.Id,
                QuoteLineItem.Product2Id => prod.Id,
                QuoteLineItem.PricebookEntryId => pbe.Id,
                QuoteLineItem.NewQuantity__c => 1,
                QuoteLineItem.Quantity => 1,
                QuoteLineItem.Zero_Quantity__c => true,
                QuoteLineItem.UnitPrice => 100,
                QuoteLineItem.PackageInfo__c => NGBSTestDataGenerator.generateQLIPackageInfo()
            })
            .create()
            .getRecord();

        Order order = createOrder(techAccount, opp);
        createOrderItem(order, pbeStandard);

        Approval__c testApproval = (Approval__c) new SObjectBuilder(Approval__c.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Approval__c.Name => 'testApp',
                Approval__c.Account__c => techAccount.Id,
                Approval__c.Opportunity__c => opp.Id,
                Approval__c.IsMultiProductTechnicalApproval__c => true,
                Approval__c.RecordTypeId => ApprovalHelper.RT_ID_INVOICING_REQUEST,
                Approval__c.Potential_Users__c => 1,
                Approval__c.Reason_Customer_is_Requesting_Invoicing__c => 'Test Reason',
                Approval__c.AccountPayableContact__c => cont.Id
            })
            .create()
            .getRecord();

        techAccount.Active_Sales_Agreement__c = qt.id;
        update techAccount;
        Triggers.switchOn();

        RestRequest req = new RestRequest();
        req.requestBody = createRequestBody(CCMigrationAccountSvc.ROLLBACK_TYPE, ENTERPRISE_ACCOUNT_ID_THIRD);
        RestContext.request = req;

        Test.startTest();
        CCMigrationAccountSvc.doPost();
        List<Opportunity> techOppties = (List<Opportunity>) new OpportunitySelector()
                .selectOpportunityByAccountIdForCCMigration(techAccount.Id)
                .executeQuery();
        List<Order> orders = [SELECT Id FROM Order WHERE OpportunityId = :opp.Id];
        List<Approval__c> approvals = [SELECT Id FROM Approval__c WHERE Opportunity__c = :opp.Id];
        List<Quote> quotes = [SELECT Id FROM Quote WHERE OpportunityId =: opp.Id];

        String responseBody = RestContext.response.responseBody.toString();
        Test.stopTest();

        CCMigrationAccountSvc.ResponseParams responseParams = (CCMigrationAccountSvc.ResponseParams)
            JSON.deserialize(responseBody, CCMigrationAccountSvc.ResponseParams.class);

        Assert.areEqual(Response.STATUS_SUCCESS, responseParams.status, RESPONSE_BODY_STATUS_MSG);
        Assert.isTrue(techOppties.size() == 0, OPPTY_NOT_DELETED);
        Assert.isTrue(orders.size() == 0, ORDER_NOT_DELETED);
        Assert.isTrue(approvals.size() == 0, APPROVAL_NOT_DELETED);
        Assert.isTrue(quotes.size() == 0, QUOTE_NOT_DELETED);
    }

    @isTest
    private static void testHandleFinishType() {
        Account masterAccount = selectTestMasterAccount(ENTERPRISE_ACCOUNT_ID_THIRD);

        Triggers.switchOff();
        createRenewalSettings();
        Account techAccount = createTechnicalAccount(masterAccount);
        Opportunity oppty = createTechOpportunity(techAccount);
        createRenewalOpportunity(masterAccount);

        Order order = createOrder(techAccount, oppty);
        PriceBookEntry pbeStandard = [SELECT Id FROM PricebookEntry WHERE Pricebook2Id = :Test.getStandardPricebookId() LIMIT 1];
        createOrderItem(order, pbeStandard);
        Triggers.switchOn();

        RestRequest req = new RestRequest();
        req.requestBody = createRequestBody(CCMigrationAccountSvc.FINISH_TYPE, ENTERPRISE_ACCOUNT_ID_THIRD);
        RestContext.request = req;

        Test.startTest();
        CCMigrationAccountSvc.doPost();
        Account masterAcc = selectTestMasterAccount(ENTERPRISE_ACCOUNT_ID_THIRD);

        Account techAcc = (Account) new AccountSelector()
            .selectMPTechAccountsByMasterIds(masterAcc.Id)
            .executeQuery()
            .get(0);

        List<Order> orders = (List<Order>) new OrderSelector()
            .selectMigratedOrdersByAccountIds(techAcc.Id)
            .executeQuery();

        Opportunity renewalOppty = selectRenewalOppty(masterAcc.Id);
        String responseBody = RestContext.response.responseBody.toString();

        Test.stopTest();

        CCMigrationAccountSvc.ResponseParams responseParams = (CCMigrationAccountSvc.ResponseParams)
            JSON.deserialize(responseBody, CCMigrationAccountSvc.ResponseParams.class);

        Assert.areEqual(Response.STATUS_SUCCESS, responseParams.status, RESPONSE_BODY_STATUS_MSG);
        Assert.areEqual(masterAcc.AccMigrationFlag__c, AccountHelper.ACCOUNT_MIGRATION_TYPE_MIGRATED, INCORRECT_MIGRATION_FLAG);
        Assert.areEqual(techAcc.AccMigrationFlag__c, AccountHelper.ACCOUNT_MIGRATION_TYPE_MIGRATED, INCORRECT_MIGRATION_FLAG);
        Assert.areEqual(orders.get(0).Status, OrderHelper.STATUS_ACTIVATED, INCORRECT_ORDER_STATUS);

        Assert.isNotNull(renewalOppty, 'Renewal Opportunity must be created');
        Assert.areEqual(renewalOppty.Type, OpportunityHelper.OPPORTUNITY_TYPE_RENEWAL, 'Renewal Opportunity type must be renewal');
        Assert.areEqual(renewalOppty.StageName, OpportunityHelper.STAGE_NAME_QUALIFY, 'Renewal Opportunity stage name must be 1. Qualify');
    }

    @isTest
    private static void testHandleEmptyRCEnterpriseAccountId() {
        RestRequest req = new RestRequest();
        req.requestBody = createRequestBody(CCMigrationAccountSvc.MIGRATE_TYPE, '');
        RestContext.request = req;

        Test.startTest();
        CCMigrationAccountSvc.doPost();
        Test.stopTest();

        String responseBody = RestContext.response.responseBody.toString();

        CCMigrationAccountSvc.ResponseParams responseParams = (CCMigrationAccountSvc.ResponseParams)
            JSON.deserialize(responseBody, CCMigrationAccountSvc.ResponseParams.class);
        Assert.areEqual(Response.STATUS_ERROR, responseParams.status, RESPONSE_BODY_STATUS_MSG);
        Assert.areEqual(responseParams.messages.get(0).message, CCMigrationAccountSvc.BAD_REQUEST_MESSAGE, RESPONSE_BODY_MESSAGE_MSG);

        assertPlatformLog(
            responseParams.messages.get(0).message,
            responseParams.messages.get(0).messageDetails
        );
    }

    @isTest
    private static void testIncorrectAccountMigrationFlag() {
        Account masterAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => ACCOUNT_NAME,
                    Account.IsMultiProductTechnicalAccount__c => false,
                    Account.Service_Type__c => AccountHelper.SERVICE_TYPE_OFFICE,
                    Account.RC_User_ID__c => ENTERPRISE_ACCOUNT_ID_FOUR,
                    Account.AccMigrationFlag__c => AccountHelper.ACCOUNT_MIGRATION_TYPE_SCHEDULED_BLOCKED
                }
            )
            .create()
            .getRecord();

        createTechnicalAccount(masterAccount);

        RestRequest req = new RestRequest();
        req.requestBody = createRequestBody(CCMigrationAccountSvc.ROLLBACK_TYPE, ENTERPRISE_ACCOUNT_ID_FOUR);
        RestContext.request = req;

        Test.startTest();
        CCMigrationAccountSvc.doPost();
        Test.stopTest();

        String responseBody = RestContext.response.responseBody.toString();

        CCMigrationAccountSvc.ResponseParams responseParams = (CCMigrationAccountSvc.ResponseParams)
            JSON.deserialize(responseBody, CCMigrationAccountSvc.ResponseParams.class);

        Assert.areEqual(Response.STATUS_ERROR, responseParams.status, RESPONSE_BODY_STATUS_MSG);
        Assert.areEqual(responseParams.messages.get(0).message, CCMigrationAccountSvc.BAD_REQUEST_MESSAGE, RESPONSE_BODY_MESSAGE_MSG);
        Assert.areEqual(responseParams.messages.get(0).messageDetails, CCMigrationAccountSvc.NOT_MIGRATION_ACCOUNT_STATUS, RESPONSE_BODY_MESSAGE_DETAILS_MSG);

        assertPlatformLog(
            responseParams.messages.get(0).message,
            responseParams.messages.get(0).messageDetails
        );
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testHandleMigrateWithAllowingUpsellOppCreation() {
        Account masterAccount = selectTestMasterAccount(ENTERPRISE_ACCOUNT_ID_FIRST);
        masterAccount.AccMigrationFlag__c = AccountHelper.ACCOUNT_MIGRATION_TYPE_SCHEDULED;
        Triggers.switchOff();
        update masterAccount;
        Triggers.switchOn();

        Test.startTest();
            CCMigrationAccountSvc.ResponseParams resp = CCMigrationAccountSvc.handleMigrate(masterAccount);
        Test.stopTest();

        Account technicalAccount = selectTechnicalAccount(masterAccount.Id);
        handleAsserts(resp, technicalAccount, AccountHelper.ACCOUNT_MIGRATION_TYPE_IN_PROGRESS);
    }

    @isTest
    static void testHandleMigrateWithAccFlagInProgress() {
        Account masterAccount = selectTestMasterAccount(ENTERPRISE_ACCOUNT_ID_THIRD);
        masterAccount.AccMigrationFlag__c = AccountHelper.ACCOUNT_MIGRATION_TYPE_IN_PROGRESS;
        Triggers.switchOff();
        Account techAccount = createTechnicalAccount(masterAccount, AccountHelper.ACCOUNT_MIGRATION_TYPE_IN_PROGRESS);
        Triggers.switchOn();

        Test.startTest();
            CCMigrationAccountSvc.ResponseParams resp = CCMigrationAccountSvc.handleMigrate(masterAccount);
        Test.stopTest();

        Assert.isNotNull(resp, 'There must be a response');
        Assert.isNotNull(resp.data, 'There must be data inside the response');
        Assert.areEqual(Response.STATUS_SUCCESS, resp.status, 'The result must be successful');
        Assert.areEqual(techAccount.Id, resp.data.rcccSFDCAccountId, 'Wrong Technical Account was returned');
        Assert.areEqual(techAccount.RC_User_ID__c, resp.data.rcccEnterpriseAccountId, 'Wrong Technical Account was returned');
    }

    private static Blob createRequestBody(String type, String enterpriseAccountId) {
        return Blob.valueOf('{\n' +
            '  "type": "' + type + '",\n' +
            '  "rcEnterpriseAccountId": "' + enterpriseAccountId + '"\n' +
            '}'
        );
    }

    private static Blob createInvalidRequestBody(String type, String enterpriseAccountId) {
        return Blob.valueOf('{\n' +
            '  "type"; "' + type + '",\n' +
            '  "rcEnterpriseAccountId": "' + enterpriseAccountId + '"\n' +
            '}'
        );
    }

    private static Account createTechnicalAccount(Account masterAccount) {
        return createTechnicalAccount(masterAccount, AccountHelper.ACCOUNT_MIGRATION_TYPE_IN_PROGRESS_BLOCKED);
    }

    private static Account createTechnicalAccount(Account masterAccount, String migrationStatus) {
        return (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => ACCOUNT_NAME + RC_CONTACT_CENTER_PREFIX,
                    Account.IsMultiProductTechnicalAccount__c => true,
                    Account.Service_Type__c => AccountHelper.SERVICE_TYPE_RCCC,
                    Account.RC_User_ID__c => ENTERPRISE_ACCOUNT_ID_SECOND,
                    Account.Master_Account__c => masterAccount.Id,
                    Account.AccMigrationFlag__c => migrationStatus
                }
            )
            .create()
            .getRecord();
    }

    private static Opportunity createTechOpportunity(Account techAccount) {
        return (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.Name => 'test',
                Opportunity.isMultiproductTechnicalOpportunity__c => true,
                Opportunity.AccountId => techAccount.Id,
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                Opportunity.Tier_Name__c => OpportunityHelper.TIER_CONTACT_CENTER,
                Opportunity.CloseDate => System.today()
            })
            .create()
            .getRecord();
    }

    private static void createRenewalOpportunity(Account masterAccount) {
        new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.Name => 'test renewal',
                Opportunity.isMultiproductTechnicalOpportunity__c => false,
                Opportunity.AccountId => masterAccount.Id,
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_DOWNGRADED,
                Opportunity.Type => OpportunityHelper.OPPORTUNITY_TYPE_RENEWAL,
                Opportunity.Downgrade_Reason_Opp__c => OpportunityHelper.DOWNGRADE_REASON_MIGRATING_THIS_ACCOUNT_FROM_LEGACY_CC,
                Opportunity.Tier_Name__c => OpportunityHelper.TIER_CONTACT_CENTER,
                Opportunity.CloseDate => System.today()
            })
            .create();
    }

    private static Opportunity selectRenewalOppty(Id accId) {
        return (Opportunity) new ListOptional(
            new OpportunitySelector()
                .selectOpportunities()
                .selectFields(
                    new Set<SObjectField> {
                        Opportunity.Type,
                        Opportunity.StageName
                    }
                )
                .setCondition('AccountId = :bind0 AND Type = :bind1 And StageName = :bind2')
                .setQueryBindings(new List<Object> {
                    accId,
                    OpportunityHelper.OPPORTUNITY_TYPE_RENEWAL,
                    OpportunityHelper.STAGE_NAME_QUALIFY
                })
                .executeQuery()
            )
        .getFirst();
    }

    private static void createRenewalSettings() {
        new SObjectBuilder(OpportunityRenewalSettings__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                OpportunityRenewalSettings__c.BrandsForRenewal__c => 'RingCentral',
                OpportunityRenewalSettings__c.DefaultOwnerId__c => [SELECT Id FROM  User WHERE Name = 'LeanData Queue' LIMIT 1].Id,
                OpportunityRenewalSettings__c.Name => '100',
                OpportunityRenewalSettings__c.DaysTillAgreementEnd__c => 10,
                OpportunityRenewalSettings__c.Days_Till_Opportunity_Close_Date__c => 10,
                OpportunityRenewalSettings__c.MRRThreshold__c => 1000.00
            })
        .create();
    }

    private static Order createOrder(Account techAccount, Opportunity opp) {
        return (Order) new SOBjectBuilder(Order.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Order.Name => ValueProviderBuilder.provideUniqueString(),
                Order.Pricebook2Id => Test.getStandardPricebookId(),
                Order.RecordTypeId => OrderHelper.RT_ID_RC_CONTACT_CENTER,
                Order.AccountId => techAccount.Id,
                Order.EffectiveDate => System.today(),
                Order.OpportunityId => opp.Id,
                Order.Status => 'New'
            })
            .create()
            .getRecord();
    }

    private static void createOrderItem(Order order, PricebookEntry pbeStandard) {
        new SOBjectBuilder(OrderItem.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                OrderItem.OrderId => order.Id,
                OrderItem.PricebookEntryId => pbeStandard.Id,
                OrderItem.Quantity => 1,
                OrderItem.UnitPrice => 1
            })
            .create();
    }

    private static Account selectTestMasterAccount(String enterpriseAccId) {
        return (Account) new ListOptional(
                new AccountSelector()
                    .selectAccountsByUserIds(new List<Object> {new List<String> {enterpriseAccId}})
                    .executeQuery()
            )
            .getFirst();
    }

    private static Account selectTechnicalAccount(Id masterAccId) {
        return (Account) new ListOptional(
                new AccountSelector()
                    .newQueryFactory()
                    .selectFields(new Set<Schema.SObjectField> {
                        Account.Id,
                        Account.RC_User_ID__c,
                        Account.Payment_Plan__c
                    })
                    .setCondition('Master_Account__c = :bind0 AND Service_Type__c = :bind1')
                    .setQueryBindings(new List<Object> {
                        masterAccId,
                        AccountHelper.SERVICE_TYPE_RCCC
                    })
                    .executeQuery()
            )
            .getFirst();
    }

    private static void handleAsserts(CCMigrationAccountSvc.ResponseParams responseParams, Account technicalAccount) {
        handleAsserts(responseParams, technicalAccount, AccountHelper.ACCOUNT_MIGRATION_TYPE_IN_PROGRESS_BLOCKED);
    }

    private static void handleAsserts(CCMigrationAccountSvc.ResponseParams responseParams, Account technicalAccount, String expectedMigrationFlagStatus) {
        Assert.areEqual(Response.STATUS_SUCCESS, responseParams.status, 'An error occurred while creation RCCC technical Account');
        Assert.areEqual(responseParams.data.rcccEnterpriseAccountId, technicalAccount.RC_User_ID__c, 'Incorrect Enterprise Account Id');
        Assert.areEqual(responseParams.data.rcccSFDCAccountId, technicalAccount.Id, 'Incorrect technical Account Id');
        Assert.areEqual(expectedMigrationFlagStatus, technicalAccount.AccMigrationFlag__c, 'Account Migration flag should be \'' + expectedMigrationFlagStatus + '\'');
    }

    private static void assertPlatformLog(String message, String details) {
        String ccMigrationClassName = '%' + CCMigrationAccountSvc.ACCOUNT_MIGRATION_SERVICE_CLASS_NAME + '%';
        List<PlatformLog__c> pLogs = [SELECT Error__c FROM PlatformLog__c WHERE Source__c LIKE :ccMigrationClassName];

        Assert.isTrue(pLogs.size() > 0, 'At least one PlatformLog__c should be created');
        Assert.areEqual(pLogs[0].Error__c, CCMigrationAccountSvc.generateErrorMessage(message, details), 'Wrong exception message');
    }
}