@isTest
private class Test_CCMigrationQueueable {
    private static final String TEST_ACCOUNT_NAME = 'Test Account';
    private static final String TEST_CONTACT_EMAIL = 'test@test.com';
    private static final String TEST_CONTACT_PHONE = '1234567890';

    private static void insertWithTriggersOff(SObject recordToInsert) {
        Triggers.switchOff();
        Database.insert(recordToInsert);
        Triggers.switchOn();
    }

    private static String expectedRecordName(String recordSystemName, Account testAccount) {
        return String.format(
            CCMigrationQueueable.CC_LEGACY_BASE_LINE_OPPORTUNITY_NAME_FORMAT,
            new List<String> {recordSystemName, testAccount.Name}
        );
    }

    private static Account selectTestAccount() {
        return (Account) new ListOptional(
            new AccountSelector()
                .selectAccountByName(new List<Object> {new Set<String> {TEST_ACCOUNT_NAME}})
                .selectField(Account.Monthly_Credit_Limit__c)
                .selectField(Account.Sign_Up_Purchase_Limit__c)
                .withSelectorFieldsIncluded()
                .executeQuery()
            )
            .getFirst();
    }

    private static Contact selectTestContact(Id testAccountId) {
        return (Contact) new ListOptional(
                new ContactSelector()
                    .selectContactsByAccountIdAndEmailOrPhone(new List<Object> {testAccountId, TEST_CONTACT_EMAIL, TEST_CONTACT_PHONE})
                    .executeQuery()
            )
            .getFirst();
    }

    private static Opportunity selectCreatedOpportunity(Account testAccount) {
        Set<Schema.SObjectField> fieldsToRetrieve = new Set<Schema.SObjectField> {
            Opportunity.Downgrade_Reason_Opp__c,
            Opportunity.IsMultiProductTechnicalOpportunity__c,
            Opportunity.MasterOpportunity__c,
            Opportunity.StageName,
            Opportunity.Type,
            Opportunity.Tier_Name__c,
            Opportunity.AccountId,
            Opportunity.Name,
            Opportunity.Is_Billing_Opportunity__c,
            Opportunity.Brand_Name__c
        };
        return (Opportunity) new ListOptional(
            new OpportunitySelector()
                .selectOpportunityByName(expectedRecordName(CCMigrationQueueable.CC_LEGACY_BASE_LINE_OPPORTUNITY_NAME, testAccount))
                .withoutSelectorFieldsIncluded()
                .selectFields(fieldsToRetrieve)
                .executeQuery()
            )
            .getFirst();
    }

    private static Quote selectCreatedQuote(Id oppId) {
        Set<Schema.SObjectField> fieldsToRetrieve = new Set<Schema.SObjectField> {
            Quote.OpportunityId,
            Quote.QuoteType__c,
            Quote.OwnerId,
            Quote.IsMultiProductTechnicalQuote__c,
            Quote.isPrimary__c,
            Quote.MasterQuote__c,
            Quote.Name,
            Quote.Status,
            Quote.RecordTypeId,
            Quote.Pricebook2Id
        };
        return (Quote) new ListOptional(
                new QuoteSelector()
                    .newQueryFactory()
                    .setFactoryName('selectQuoteByOppId')
                    .selectFields(fieldsToRetrieve)
                    .setCondition('OpportunityId = :bind0')
                    .setQueryBindings(new List<Object> {oppId})
                    .executeQuery()
            )
            .getFirst();
    }

    private static List<QuoteLineItem> selectCreatedQlis(Id quoteId) {
        return (List<QuoteLineItem>) new QuoteLineItemSelector()
            .newQueryFactory()
            .setFactoryName('selectQlisByQuoteId')
            .selectFields(new List<String> {'Id', 'TotalPrice', 'TotalSummary__c', 'IsMultiProductTechnicalQLI__c'})
            .setCondition('QuoteId = :bind0')
            .setQueryBindings(new List<Object> { quoteId })
            .executeQuery();
    }

    private static Approval__c selectCreatedApproval(Id accId, Id oppId) {
        Set<Schema.SObjectField> fieldsToRetrieve = new Set<Schema.SObjectField> {
            Approval__c.RecordTypeId,
            Approval__c.Account__c,
            Approval__c.AccountPayableContact__c,
            Approval__c.Opportunity__c,
            Approval__c.Monthly_Credit_Limit__c,
            Approval__c.Sign_Up_Purchase_Limit__c,
            Approval__c.Status__c,
            Approval__c.StatusLastModifiedDate__c,
            Approval__c.IsMultiProductTechnicalApproval__c
        };
        return (Approval__c) new ListOptional(
            new ApprovalSelector()
                .newQueryFactory()
                .setFactoryName('selectInvoiceRequestApprovalByAccountIdAndOpportunityId')
                .selectFields(fieldsToRetrieve)
                .setCondition('Account__c = :bind0 AND Opportunity__c = :bind1 AND RecordTypeId = :bind2')
                .setQueryBindings(new List<Object> {accId, oppId, ApprovalHelper.RT_ID_INVOICING_REQUEST})
                .executeQuery()
            )
            .getFirst();
    }

    private static Order selectCreatedOrderByQuote(Id quoteId) {
        return (Order) new ListOptional(
            new OrderSelector()
                .newQueryFactory()
                .setFactoryName('selectCreatedOrderByQuote')
                .selectFields(new List<String> {'Id', 'Recurring_total__c', 'SeatMRR__c'})
                .subselect(new OrderItemSelector().selectOrderItems())
                .setCondition('QuoteId = :bind0')
                .setQueryBindings(new List<Object> {quoteId})
                .executeQuery()
        ).getFirst();
    }

    private static BillingWrappers.NGBSAccountPackage getTestNgbsPackage() {
        BillingWrappers.NGBSAccountPackage pkg =
            ((BillingWrappers.NGBSAccount) JSON.deserialize(CCMigrationNGBSAPIMock.NGBS_ACCOUNT_RESPONSE, BillingWrappers.NGBSAccount.class))
            .getPackage();
        pkg.currencyCode = String.valueOf(((Map<String, Object>) JSON.deserializeUntyped(CCMigrationNGBSAPIMock.NGBS_ACCOUNT_RESPONSE)).get('currency'));
        return pkg;
    }

    private static BillingWrappers.BillingInfo2 getTestBillingInfo() {
        return (BillingWrappers.BillingInfo2) JSON.deserialize(CCMigrationNGBSAPIMock.BILLING_INFO_RESPONSE, BillingWrappers.BillingInfo2.class);
    }

    private static BillingWrappers.NGBSPackageLimit getTestNGBSPackageLimit() {
        return CCMigrationQueueable.getPackageLimit(CCMigrationNGBSAPIMock.PACKAGE_LIMITS_RESPONSE);
    }

    private static void assertCreatedOpportunity(Opportunity createdOpp, Account testAccount) {
        Assert.isNotNull(createdOpp, 'Technical opportunity must be created');
        Assert.areEqual(
            OpportunityHelper.STAGE_NAME_DOWNGRADED,
            createdOpp.StageName,
            'A technical base-line Opportunity for CC Migration has to be downgraded'
        );
        Assert.areEqual(
            OpportunityHelper.DOWNGRADE_REASON_CC_MIGRATION,
            createdOpp.Downgrade_Reason_Opp__c,
            'Downgrade reason for a technical base-line Opportunity for CC Migration has to be set to "Migration"'
        );
        Assert.isTrue(
            createdOpp.IsMultiProductTechnicalOpportunity__c,
            'A technical base-line Opportunity for CC Migration must be technical'
        );
        Assert.isTrue(
            createdOpp.Is_Billing_Opportunity__c,
            'A technical base-line Opportunity for CC Migration must have Is_Billing_Opportunity__c set to true'
        );
        Assert.areEqual(
            null,
            createdOpp.MasterOpportunity__c,
            'A technical base-line Opportunity for CC Migration should not have Master Opportunity'
        );
        Assert.areEqual(
            OpportunityHelper.OPPORTUNITY_TYPE_NEW_BUSINESS,
            createdOpp.Type,
            'A technical base-line Opportunity for CC Migration should be for New Business'
        );
        Assert.areEqual(
            OpportunityHelper.TIER_RC_CONTACT_CENTER,
            createdOpp.Tier_Name__c,
            'A technical base-line Opportunity for CC Migration should only be for Contact Center'
        );
        Assert.areEqual(
            testAccount.Id,
            createdOpp.AccountId,
            'A technical base-line Opportunity for CC Migration should be connected to a technical account'
        );
        Assert.areEqual(
            testAccount.RC_Brand__c,
            createdOpp.Brand_Name__c,
            'A technical base-line Opportunity for CC Migration should the same brand as technical account'
        );
    }

    private static void assertCreatedQuote(Quote createdQuote, Account testAccount, Id opportunityId) {
        Assert.isNotNull(createdQuote, 'Technical quote must be created');
        Assert.areEqual(
            QuoteHelper.QUOTE_STATUS_EXECUTED,
            createdQuote.Status,
            'A technical base-line Quote for CC Migration has to be Executed'
        );
        Assert.areEqual(
            QuoteHelper.QUOTE_TYPE_AGREEMENT,
            createdQuote.QuoteType__c,
            'Quote Type of a technical base-line Quote for CC Migration has to be set to "' + QuoteHelper.QUOTE_TYPE_AGREEMENT + '"'
        );
        Assert.isTrue(
            createdQuote.IsMultiProductTechnicalQuote__c,
            'A technical base-line Quote for CC Migration must be technical'
        );
        Assert.areEqual(
            null,
            createdQuote.MasterQuote__c,
            'A technical base-line Quote for CC Migration should not have Master Quote'
        );
        Assert.areEqual(
            expectedRecordName(CCMigrationQueueable.CC_LEGACY_QUOTE_NAME, testAccount),
            createdQuote.Name,
            'A technical base-line Quote for CC Migration should have a standard name'
        );
        Assert.areEqual(
            opportunityId,
            createdQuote.OpportunityId,
            'A technical Quote for CC Migration should be connected to a technical base-line Opportunity'
        );
        Assert.areEqual(
            QuoteHelper.RT_ID_BILLING,
            createdQuote.RecordTypeId,
            'A technical Quote for CC Migration should have ' + QuoteHelper.RT_NAME_BILLING + ' record type'
        );
        Assert.isTrue(
            createdQuote.isPrimary__c,
            'A technical Quote for CC Migration should be primary quote'
        );
        Assert.areEqual(
            Test.getStandardPricebookId(),
            createdQuote.Pricebook2Id,
            'A technical Quote for CC Migration should be connected to a standard PriceBook'
        );
    }

    private static void assertCreatedInvoiceRequest(Approval__c invoiceRequest, Id accId, Id oppId, BillingWrappers.NGBSPackageLimit testLimit) {
        Assert.isNotNull(invoiceRequest, 'Invoice Request must be created');
        Assert.areEqual(
            ApprovalHelper.RT_ID_INVOICING_REQUEST,
            invoiceRequest.RecordTypeId,
            'A created Approval for CC Migration must be an Invoicing Request'
        );
        Assert.areEqual(
            accId,
            invoiceRequest.Account__c,
            'A created Invoice Request for CC Migration must be connected to a technical Account'
        );
        Assert.areEqual(
            oppId,
            invoiceRequest.Opportunity__c,
            'A created Invoice Request for CC Migration must be connected to a technical base-line Opportunity'
        );
        Assert.areEqual(
            testLimit.value,
            invoiceRequest.Monthly_Credit_Limit__c,
            'Monthly_Credit_Limit__c must be the same as in NGBS'
        );
        Assert.areEqual(
            testLimit.limitOverride.value,
            invoiceRequest.Sign_Up_Purchase_Limit__c,
            'Sign_Up_Purchase_Limit__c must be the same as in NGBS'
        );
        Assert.areEqual(
            ApprovalHelper.STATUS_APPROVED,
            invoiceRequest.Status__c,
            'A created Approval must be in status ' + ApprovalHelper.STATUS_APPROVED
        );
        Assert.isNotNull(
            invoiceRequest.StatusLastModifiedDate__c,
            'The StatusLastModifiedDate__c must be populated'
        );
        Assert.isTrue(
            invoiceRequest.IsMultiProductTechnicalApproval__c,
            'A created Approval must be technical one'
        );
    }

    private static void assertCreatedQLIs(List<QuoteLineItem> qlis) {
        Assert.isTrue(qlis.size() > 0, 'Quote line items must be created');

        Decimal totalPrice = 0;
        for (QuoteLineItem qli : qlis) {
            totalPrice += qli.TotalPrice;
            Assert.isTrue(
                qli.IsMultiProductTechnicalQLI__c,
                'A technical QuoteLineItem for CC Migration must be technical');
        }
        Assert.areEqual(86400, totalPrice, 'Wrong total price');
    }

    private static void assertCreatedOrder(Order order, List<QuoteLineItem> qlis) {
        Assert.isNotNull(order, 'Order must be created');
        Assert.isTrue(order.OrderItems.size() > 0, 'Order items must be created');
        Assert.areEqual(order.OrderItems.size(), qlis.size(), 'Order items and quote line items must be equal');

        Decimal reccurringTotal = 0;
        Decimal totalSummary = 0;
        for (QuoteLineItem qli : qlis) {
            reccurringTotal += qli.TotalPrice;
            totalSummary += qli.TotalSummary__c;
        }

        Assert.areEqual(order.Recurring_total__c, reccurringTotal, 'Order recurring total does not match QLIs');
        Assert.areEqual(order.SeatMRR__c, totalSummary, 'Order seat MRR does not match QLIs');
    }

    private static void assertExceptionHandler(Integer emailInvocations) {
        String ccMigrationClassName = '%' + CCMigrationQueueable.CC_MIGRATION_CLASS_NAME + '%';
        Assert.isTrue(
            [SELECT COUNT() FROM PlatformLog__c WHERE Source__c LIKE :ccMigrationClassName] > 0,
            'If any exception was raised during migration, at least one PlatformLog__c should be created'
        );
        Assert.isNotNull(
            ChatterHelper.lastFeedItemInput,
            'In case of any exception raised during migration, message should be posted to Chatter'
        );
        Assert.isTrue(
            emailInvocations > 0,
            'In case of any exception raised during migration, an email message should be sent'
        );
    }

    @testSetup
    static void setup() {
        //User testCCMigrationSupportUser = (User) new SObjectBuilder(User.sObjectType).create().getRecord();
        /*Legacy Host Names*/
        User testCCMigrationSupportUser = (User) new SObjectBuilder(User.sObjectType)
            .setField(User.LastName, 'Technical User')
            .setField(User.FirstName, 'Multiproduct')
            .create()
            .getRecord(); /*Legacy Host Names*/
        Group testCCMigrationSupportGroup = (Group) new ListOptional(
            new GroupSelector()
                .selectGroupBasedOnDeveloperNames(
                    new List<Object> {new Set<String> {CCMigrationQueueable.CC_MIGRATION_GROUP_DEVELOPER_NAME}}
                )
                .executeQuery()
            )
            .getFirst();

        new SObjectBuilder(GroupMember.sObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    GroupMember.GroupId => testCCMigrationSupportGroup.Id,
                    GroupMember.UserOrGroupId => testCCMigrationSupportUser.Id
                }
            )
            .createAsUser(testCCMigrationSupportUser);

        new SObjectBuilder(NGBS_Settings__c.SObjectType)
                .setFields(new Map<SObjectField, Object> {
                    NGBS_Settings__c.BaseEndpoint__c => 'https://testapi',
                    NGBS_Settings__c.CatalogPath__c => '/restapi/v1.0/catalog',
                    NGBS_Settings__c.AccountManagerPath__c => '/restapi/account-manager/v1.0',
                    NGBS_Settings__c.Login__c => '123',
                    NGBS_Settings__c.Password__c => '456'
                })
            .create();

        new SObjectBuilder(Feature_Toggle__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Feature_Toggle__c.Opportunity_Stage_Flow_Validations__c => true
            })
            .create();

        Segment_Master__c seg = (Segment_Master__c) new SObjectBuilder(Segment_Master__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Segment_Master__c.Name => UserHelper.SEGMENT_MID_MARKET,
                Segment_Master__c.Max__c => 19,
                Segment_Master__c.Min__c => 1,
                Segment_Master__c.Country__c => 'United States',
                Segment_Master__c.Start_Date__c => System.today()
            })
            .create()
            .getRecord();

        Account testAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Name => TEST_ACCOUNT_NAME,
                Account.RC_Brand__c => OpportunityHelper.BRAND_RINGCENTRAL,
                Account.AccMigrationFlag__c => AccountHelper.ACCOUNT_MIGRATION_TYPE_IN_PROGRESS_BLOCKED,
                Account.Billing_ID__c => CCMigrationNGBSAPIMock.BILLING_ID,
                Account.Segment_Name__c => seg.Id
            })
            .create()
            .getRecord();

        new SObjectBuilder(Contact.sObjectType)
            .setFields(new Map<SObjectField, Object> {
                Contact.FirstName => 'Test2',
                Contact.LastName => 'Test2',
                Contact.AccountId => testAccount.Id,
                Contact.Email => TEST_CONTACT_EMAIL,
                Contact.Phone => TEST_CONTACT_PHONE,
                Contact.Preferred_Language__c => ContactHelper.PREFERRED_LANGUAGE_EN_US
            })
            .create();
        /*legacy Host Names*/
        // Bypass Quote trigger for all tests so Quote insert does not fire OpportunityTotals/OpportunityPipelineHelper (NPE)
        insert new ByPassTrigger__c(
            SetupOwnerId = UserInfo.getUserId(),
            Bypass_Quote_Trigger__c = true
        ); /*legacy Host Names*/
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testCreateTechnicalOpp() {
        Account testAccount = selectTestAccount();
        CCMigrationQueueable queueable = new CCMigrationQueueable(testAccount);
        queueable.ngbsAccountPackage = getTestNgbsPackage();
        Test.startTest();
            Opportunity createdOpp = queueable.createTechnicalOpp();
        Test.stopTest();

        assertCreatedOpportunity(createdOpp, testAccount);
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testCreateTechnicalQuoteForMigratedOpportunity() {
        Account testAccount = selectTestAccount();
        Id dummyOppId = (Id) new ValueProvider.DummyIdProvider(Opportunity.sObjectType).getValue();
        CCMigrationQueueable queueable = new CCMigrationQueueable(testAccount);
        queueable.ngbsAccountPackage = getTestNgbsPackage();
        Test.startTest();
            Quote createdQuote = queueable.createTechnicalQuoteForMigratedOpportunity(dummyOppId);
        Test.stopTest();

        assertCreatedQuote(createdQuote, testAccount, dummyOppId);
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testInsertTechnicalQuoteForMigratedOpportunity() {
        Account testAccount = selectTestAccount();
        CCMigrationQueueable queueable = new CCMigrationQueueable(testAccount);
        queueable.ngbsAccountPackage = getTestNgbsPackage();
        Test.startTest();
            Opportunity createdOpp = queueable.createTechnicalOpp();
            insertWithTriggersOff(createdOpp);
            Quote createdQuote = queueable.createTechnicalQuoteForMigratedOpportunity(createdOpp.Id);
            insert createdQuote;
        Test.stopTest();

        assertCreatedQuote(createdQuote, testAccount, createdOpp.Id);
    }

    @isTest
    static void testCCMigrationQueueableExecution() {
        Test.setMock(HttpCalloutMock.class, new CCMigrationNGBSAPIMock());

        new SObjectBuilder(Package_Main_Licenses__c.sObjectType)
            .setFields(new Map<SObjectField, Object> {
                Package_Main_Licenses__c.Name => ValueProviderBuilder.provideUniqueString('Engage Digital Standalone: Default'),
                Package_Main_Licenses__c.Main_License__c => 'SA_SEAT_5',
                Package_Main_Licenses__c.Package_Group__c => 'Engage Digital Standalone'
            })
            .create();

        Account testAccount = selectTestAccount();

        Product2 testProduct = (Product2) new SObjectBuilder(Product2.sObjectType)
            .setField(Product2.Name, 'SEAT')
            .setField(Product2.IsActive, true)
            .setField(Product2.ExtID__c, 'SA_SEAT_5')
            .create()
            .getRecord();

        new SObjectBuilder(PricebookEntry.sObjectType)
            .setField(PricebookEntry.Pricebook2Id, Pricebook2Helper.getStandardPricebookId())
            .setField(PricebookEntry.Product2Id, testProduct.Id)
            .setField(PricebookEntry.IsActive, true)
            .setField(PricebookEntry.CurrencyIsoCode, 'USD')
            .create();

        Contact testContact = selectTestContact(testAccount.Id);

        new SObjectBuilder(AccountContactRole.sObjectType)
            .setFields(new Map<SObjectField, Object> {
                AccountContactRole.AccountId => testAccount.Id,
                AccountContactRole.ContactId => testContact.Id,
                AccountContactRole.Role => AccountContactRoleHelper.CONTACT_ROLE_ACCOUNT_PAYABLE,
                AccountContactRole.IsPrimary => true
            })
            .create();

        Test.startTest();
            System.enqueueJob(new CCMigrationQueueable(testAccount));
        Test.stopTest();

        Opportunity createdOpportunity = selectCreatedOpportunity(testAccount);
        assertCreatedOpportunity(createdOpportunity, testAccount);

        Quote createdQuote = selectCreatedQuote(createdOpportunity.Id);
        assertCreatedQuote(createdQuote, testAccount, createdOpportunity.Id);

        Assert.areEqual(
            testAccount.Id,
            createdQuote.AccountId,
            'A technical Quote for CC Migration should be connected to a technical account'
        );

        List<QuoteLineItem> qlis = selectCreatedQlis(createdQuote.Id);
        assertCreatedQLIs(qlis);

        Approval__c createdInvoiceRequest = selectCreatedApproval(testAccount.Id, createdOpportunity.Id);
        assertCreatedInvoiceRequest(createdInvoiceRequest, testAccount.Id,  createdOpportunity.Id, getTestNGBSPackageLimit());

        Order order = selectCreatedOrderByQuote(createdQuote.Id);
        assertCreatedOrder(order, qlis);
    }

    @isTest
    static void testManualMigrateAccountWithException() {
//        Test.setMock(HttpCalloutMock.class, new CCMigrationNGBSAPIMock());

        Account testAccount = selectTestAccount();
        Test.startTest();
            new CCMigrationQueueable(testAccount, false).migrateAccount();
            Integer emailInvocations = Limits.getEmailInvocations();
        Test.stopTest();

        assertExceptionHandler(emailInvocations);

        //TODO: rework after fixing order creation
//        Opportunity createdOpportunity = selectCreatedOpportunity(testAccount);
//        Assert.isNotNull(createdOpportunity, 'Exception during Approval creation must not rollback created Opportunity when migrated manually');
//
//        Quote createdQuote = selectCreatedQuote(createdOpportunity.Id);
//        Assert.isNotNull(createdQuote, 'Exception during Approval creation must not rollback created Quote when migrated manually');
//
//        Assert.isFalse(selectCreatedQlis(createdQuote.Id).isEmpty(), 'QLIs should be kept in the database');
//        Assert.isNull(selectCreatedApproval(testAccount.Id, createdOpportunity.Id), 'No Approval should be created');

        Account testAccountAfterFailedMigration = selectTestAccount();
        Assert.areEqual(
            testAccount.Monthly_Credit_Limit__c,
            testAccountAfterFailedMigration.Monthly_Credit_Limit__c,
            'Monthly_Credit_Limit__c should not be changed if migration was failed'
        );
        Assert.areEqual(
            testAccount.Sign_Up_Purchase_Limit__c,
            testAccountAfterFailedMigration.Sign_Up_Purchase_Limit__c,
            'Sign_Up_Purchase_Limit__c should not be changed if migration was failed'
        );
    }

    @isTest
    static void testMigrateAccountWithExceptionInNGBS() {
        Test.setMock(HttpCalloutMock.class, new CCMigrationNGBSAPIMock(404));
        Account testAccount = selectTestAccount();
        Test.startTest();
            new CCMigrationQueueable(testAccount).migrateAccount();
            Integer emailInvocations = Limits.getEmailInvocations();
        Test.stopTest();

        assertExceptionHandler(emailInvocations);

        Assert.areEqual(null, selectCreatedOpportunity(testAccount), 'If data was retrieved unsuccessfully, no records should be created');

        Account testAccountAfterFailedMigration = selectTestAccount();
        Assert.areEqual(
            testAccount.Monthly_Credit_Limit__c,
            testAccountAfterFailedMigration.Monthly_Credit_Limit__c,
            'Monthly_Credit_Limit__c should not be changed if migration was failed'
        );
        Assert.areEqual(
            testAccount.Sign_Up_Purchase_Limit__c,
            testAccountAfterFailedMigration.Sign_Up_Purchase_Limit__c,
            'Sign_Up_Purchase_Limit__c should not be changed if migration was failed'
        );
    }

    @isTest
    static void testConstructCCMigrationName() {
        Account testAccount = selectTestAccount();
        CCMigrationQueueable queueable = new CCMigrationQueueable(testAccount);
        Test.startTest();
            String opportunityName = queueable.constructCCMigrationName(CCMigrationQueueable.CC_LEGACY_BASE_LINE_OPPORTUNITY_NAME, 120);
            String quoteName = queueable.constructCCMigrationName(CCMigrationQueueable.CC_LEGACY_QUOTE_NAME, 120);
        Test.stopTest();

        Assert.areEqual(
            expectedRecordName(CCMigrationQueueable.CC_LEGACY_BASE_LINE_OPPORTUNITY_NAME, testAccount),
            opportunityName,
            'Opportunity Name should follow the template for CC Migration'
        );
        Assert.areEqual(
            expectedRecordName(CCMigrationQueueable.CC_LEGACY_QUOTE_NAME, testAccount),
            quoteName,
            'Quote Name should follow the template for CC Migration'
        );
    }

    @isTest
    static void testCreateItemsFromNGBSBillingInfo() {
        Account testAccount = selectTestAccount();
        CCMigrationQueueable queueable = new CCMigrationQueueable(testAccount);

        queueable.ngbsAccountPackage = getTestNgbsPackage();
        queueable.bInfo = getTestBillingInfo();

        Test.startTest();
        CCMigrationQueueable.BillingData data = queueable.createItemsFromNGBSBillingInfo();
        Test.stopTest();

        Assert.isTrue(data.products.size() > 0, 'Products must be created');
        Assert.isTrue(data.cartItems.size() > 0, 'Cart items must be created');
    }

    @isTest
    static void testCreateItemsFromNGBSBillingInfoInvalid() {
        Account testAccount = selectTestAccount();
        CCMigrationQueueable queueable = new CCMigrationQueueable(testAccount);

        queueable.ngbsAccountPackage = getTestNgbsPackage();
        queueable.bInfo = (BillingWrappers.BillingInfo2) JSON.deserialize('{}', BillingWrappers.BillingInfo2.class);

        Test.startTest();
            try {
                queueable.createItemsFromNGBSBillingInfo();
                Assert.isTrue(false, 'An exception was expected');
            } catch (AquivaHelper.AquivaException e) {
                Assert.isTrue(e.getMessage().contains('Attempt to de-reference a null object'), 'NPE was expected');
            }
        Test.stopTest();
    }

    @isTest
    static void testRequestDataFromNGBS() {
        Test.setMock(HttpCalloutMock.class, new CCMigrationNGBSAPIMock());

        Account testAccount = selectTestAccount();
        CCMigrationQueueable queueable = new CCMigrationQueueable(testAccount);

        Test.startTest();
            queueable.requestDataFromNGBS();
        Test.stopTest();
        BillingWrappers.NGBSPackageLimit testLimit = getTestNGBSPackageLimit();

        Assert.areEqual(getTestNgbsPackage().id, queueable.ngbsAccountPackage.id, 'Ids must be equal');
        Assert.areEqual(getTestBillingInfo().accountId, queueable.bInfo.accountId, 'Ids must be equal');
        Assert.isTrue(queueable.ngbsAccountPackage.currencyCode != null, 'Currency codes must not be null');
        Assert.areEqual(getTestNgbsPackage().currencyCode, queueable.ngbsAccountPackage.currencyCode, 'Currency codes must be equal');
        Assert.areEqual(testLimit.value, queueable.packageLimit.value, 'Monthly_Credit_Limit__c must be the same as in NGBS');
        Assert.areEqual(testLimit.limitOverride.value, queueable.packageLimit.limitOverride.value, 'Sign_Up_Purchase_Limit__c must be the same as in NGBS');
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testHandleExceptionDuringRecordsCreation() {
        Test.setMock(HttpCalloutMock.class, new CCMigrationNGBSAPIMock());

        Account testAccountThatShouldCauseProblems = new Account(Billing_ID__c = CCMigrationNGBSAPIMock.BILLING_ID);

        Test.startTest();
            new CCMigrationQueueable(testAccountThatShouldCauseProblems).migrateAccount();
            Integer emailInvocations = Limits.getEmailInvocations();
            assertExceptionHandler(emailInvocations);
        Test.stopTest();
    }

    @isTest
    static void testInsertInvoiceApprovalForMigratedAccountWithoutPayableAccount() {
        Id dummyOppId = (Id) new ValueProvider.DummyIdProvider(Opportunity.sObjectType).getValue();
        CCMigrationQueueable queueable = new CCMigrationQueueable(selectTestAccount());

        Test.startTest();
            queueable.insertInvoiceApprovalForMigratedAccount(dummyOppId);
        Test.stopTest();

        Assert.isNotNull(
            ChatterHelper.lastFeedItemInput,
            'In case of an Account not having any of required AccountContactRoles during migration, a notification should be posted to Chatter'
        );

        Assert.isTrue(
            ChatterHelper.lastFeedItemInput.body.messageSegments[0].toString().contains(CCMigrationQueueable.ACCOUNT_DOES_NOT_HAVE_ACCOUNT_PAYABLE_ROLE),
            'The notification should contain the correct message'
        );
    }

    @isTest
    static void testGetNGBSAccountPackageFromBilling() {
        String accountIdString = '123';
        String body = '{"packages":[{"id":9710001,"catalogId":"2","version":"1","currency": "USD"}]}';
        BillingHttpRequestMock tstMock = new BillingHttpRequestMock();
        tstMock.body = body;
        tstMock.code = 200;
        tstMock.status = 'Complete';
        Test.setMock(HttpCalloutMock.class, tstMock);
        System.debug('tstMock.body: ' + tstMock.body);

        Test.startTest();
            BillingWrappers.NGBSAccountPackage ngbsPackage = CCMigrationQueueable.getNGBSAccountPackage(accountIdString);
        Test.stopTest();

        Assert.areEqual('9710001', ngbsPackage.id, 'NGBS Package id must be 9710001');
        Assert.areEqual('1', ngbsPackage.version, 'NGBS Package version must be 1');
        Assert.areEqual('2', ngbsPackage.catalogId, 'NGBS Package catalogId must be 2');
        Assert.areEqual('USD', ngbsPackage.currencyCode, 'NGBS Package currencyCode must be USD');
    }

    @isTest
    static void testInsertInvoiceApprovalForAccountWithOnlyPrimaryAccountContactRole() {
        Account masterAcc = selectTestAccount();
        Contact masterContact = selectTestContact(masterAcc.Id);

        Account technicalAcc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Name => 'tech ' + TEST_ACCOUNT_NAME,
                Account.Service_Type__c => AccountHelper.SERVICE_TYPE_RCCC,
                Account.AccMigrationFlag__c => AccountHelper.ACCOUNT_MIGRATION_TYPE_IN_PROGRESS_BLOCKED,
                Account.IsMultiProductTechnicalAccount__c => true,
                Account.Master_Account__c => masterAcc.Id
            })
            .build()
            .getRecord();
        insertWithTriggersOff(technicalAcc);

        Contact technicalContact = (Contact) new SObjectFactory()
            .create(Contact.SObjectType,
                new Map<SObjectField, Object> {
                    Contact.LastName => masterContact.LastName,
                    Contact.Phone => TEST_CONTACT_PHONE,
                    Contact.AccountId => technicalAcc.Id
                }
            );

        AccountContactRole masterPrimaryAcr = (AccountContactRole) new SObjectBuilder(AccountContactRole.sObjectType)
            .setFields(new Map<SObjectField, Object> {
                AccountContactRole.AccountId => new ValueProvider.ListProvider(new List<Id> {masterAcc.Id, technicalAcc.Id}),
                AccountContactRole.ContactId => new ValueProvider.ListProvider(new List<Id> {masterContact.Id, technicalContact.Id}),
                AccountContactRole.Role => AccountContactRoleHelper.CONTACT_ROLE_SIGNATORY,
                AccountContactRole.IsPrimary => true
            })
            .quantity(2)
            .create()
            .getRecord(0);

        CCMigrationQueueable queueable = new CCMigrationQueueable(technicalAcc);
        queueable.ngbsAccountPackage = getTestNgbsPackage();
        queueable.bInfo = getTestBillingInfo();
        queueable.packageLimit = getTestNGBSPackageLimit();

        Opportunity technicalOpp = queueable.createTechnicalOpp();
        insertWithTriggersOff(technicalOpp);

        Test.startTest();
            queueable.insertInvoiceApprovalForMigratedAccount(technicalOpp.Id);
        Test.stopTest();

        Assert.isNull(
            ChatterHelper.lastFeedItemInput,
            'There should be no message in Chatter'
        );

        AccountContactRole masterAccountContactPayable = (AccountContactRole) new ListOptional(
                new AccountContactRoleSelector()
                    .selectAccountContactRolesByRoleAndAccountId(
                        masterAcc.Id,
                        AccountContactRoleHelper.CONTACT_ROLE_ACCOUNT_PAYABLE
                    )
                    .executeQuery()
            )
            .getFirst();
        Assert.isNotNull(masterAccountContactPayable, 'The master Account should have a newly created AccountContactRole Payable');
        Assert.isFalse(masterAccountContactPayable.IsPrimary, 'The newly created AccountPayableRole should not be a primary role');
        Assert.areEqual(
            AccountContactRoleHelper.CONTACT_ROLE_ACCOUNT_PAYABLE,
            masterAccountContactPayable.Role,
            'The newly created AccountPayableRole must be a ' + AccountContactRoleHelper.CONTACT_ROLE_ACCOUNT_PAYABLE
        );
        Assert.areEqual(
            masterPrimaryAcr.AccountId,
            masterAccountContactPayable.AccountId,
            'The newly created AccountPayableRole must be created for the same master account'
        );
        Assert.areEqual(
            masterPrimaryAcr.ContactId,
            masterAccountContactPayable.ContactId,
            'The newly created AccountPayableRole must be created for the same master contact'
        );

        Approval__c createdInvoiceRequest = selectCreatedApproval(technicalAcc.Id, technicalOpp.Id);
        assertCreatedInvoiceRequest(createdInvoiceRequest, technicalAcc.Id,  technicalOpp.Id, queueable.packageLimit);
    }
}