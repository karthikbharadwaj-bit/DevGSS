@isTest
private class Test_PartnerOperationsController {
    private static final String PACKAGE_INFO_ID = BillingHttpRequestMock.PACKAGE_ID;
    private static final String INNER_PACKAGE_INFO_ID = '1389379001';
    private static final String PACKAGE_INFO_VERSION = '1';
    private static final String CATALOG_ID = '18';
    private static final String EDITION_ID = '1';
    private static final String EDITION_NAME = 'Standard';
    private static final String CONTRACT_ID = (String) ValueProviderBuilder.provideDummyId(Contract__c.sObjectType).getValue();
    private static final String CONTRACT_EXT_ID = 'nib';
    private static final String CONTRACT_BILLING_ID = '1239';
    private static final String PACKAGE_LIMIT_CODE = 'testPackageLimitCode';
    private static final String PACKAGE_LIMIT_VALUE = '50000';
    private static final String BILLING_ID = BillingHttpRequestMock.ACCOUNT_ID;
    private static final String ACCOUNT_SUMMARY_ENDPOINT = BILLING_ID + '/summary?shortView=true';
    private static final String TEST_SCENARIO = 'Test Scenario';

    @TestSetup
    static void makeData(){
        Triggers.switchOff();

        new SobjectBuilder(NGBS_Settings__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                NGBS_Settings__c.BaseEndpoint__c => 'https://testapi',
                NGBS_Settings__c.CatalogPath__c => '/restapi/v1.0/catalog',
                NGBS_Settings__c.AccountManagerPath__c => '/restapi/account-manager/v1.0',
                NGBS_Settings__c.Login__c => '123',
                NGBS_Settings__c.Password__c => '456'
            })
            .create();

        Account acc = (Account) new SObjectBuilder(Account.sObjectType)
            .setField(Account.Name, 'testAcc')
			.setField(Account.BillingStreet, '111 Industrial Ctr')
			.setField(Account.BillingCity, 'Belmont')
			.setField(Account.BillingState, 'CA')
			.setField(Account.BillingPostalCode, '94002')
			.setField(Account.BillingCountry, 'USA')
			.setField(Account.Current_Owner__c, UserInfo.getUserId())
			.create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setField(Opportunity.RecordTypeId, OpportunityHelper.RT_ID_NEW_SALES_OPPORTUNITY)
            .setField(Opportunity.Brand_Name__c, OpportunityHelper.BRAND_RINGCENTRAL_EU)
            .setField(Opportunity.CloseDate, system.today().addMonths(1))
            .setField(Opportunity.AccountId, acc.Id)
            .setField(Opportunity.StageName, OpportunityHelper.STAGE_NAME_QUALIFY)
			.create()
            .getRecord();

        Contact cont = (Contact) new SObjectBuilder(Contact.SObjectType)
			.setFields(SObjectFactoryFieldDefaults.getDefaults(Contact.SObjectType))
			.setField(Contact.AccountId, acc.Id)
			.create()
            .getRecord();

        new SObjectBuilder(Approval__c.SObjectType)
            .setField(Approval__c.Name, 'test Approval')
            .setField(Approval__c.RecordTypeId, ApprovalHelper.RT_ID_INVOICING_REQUEST)
            .setField(Approval__c.Account__c, acc.Id)
            .setField(Approval__c.Status__c, ApprovalHelper.STATUS_NEW)
            .setField(Approval__c.Contact__c, cont.Id)
            .setField(Approval__c.Opportunity__c, opp.Id)
            .setField(Approval__c.Potential_Users__c, 1)
            .setField(Approval__c.Reason_Customer_is_Requesting_Invoicing__c, 'test')
            .create();

        Triggers.switchOn();
    }

    @isTest
    private static void testDowngradeClosedOpportunity() {
        Opportunity opp = getOpportunity();
        Response testResp = new Response();
        testResp.addMessage('Opportunity is closed won', 'success');

        Test.startTest();
        opp.StageName = OpportunityHelper.STAGE_NAME_CLOSED_WON;
        Triggers.switchOff();
        update opp;
        Triggers.switchOn();

        Response result = PartnerOperationsController.downgradeOpportunity(opp.Id);
        System.assertEquals(Response.STATUS_SUCCESS, result.status);
        System.assertEquals(testResp.messages[0].message , result.messages[0].message);
        System.assertEquals(OpportunityHelper.STAGE_NAME_CLOSED_WON, opp.StageName);

        Test.stopTest();

    }

    @isTest
    private static void testDowngradeOpportunity(){
        Opportunity opp = getOpportunity();
        Response testResp = new Response();
        testResp.addMessage('Opportunity is downgraded', 'success');

        Test.startTest();
        opp.StageName = OpportunityHelper.STAGE_NAME_QUALIFY;
        Triggers.switchOff();
        update opp;
        Triggers.switchOn();


        Response result = PartnerOperationsController.downgradeOpportunity(opp.Id);
        System.assertEquals(Response.STATUS_SUCCESS, result.status);
        System.assertEquals(testResp.messages[0].message , result.messages[0].message);

        Test.stopTest();
    }

    @isTest
    private static void testRecallApproval(){
        Triggers.switchOff();

        Account partnerAccount = (Account) new SObjectBuilder(Account.SObjectType)
        .setFields( new Map<SObjectField, Object>{
            Account.Name => 'TestAccount',
            Account.RecordTypeId => AccountHelper.RT_ID_PARTNER_ACCOUNT,
            Account.Credit_Limit__c => 150,
            Account.BusinessIdentity__c => 'RingCentral Ink.',
            Account.Partner_Type__c => 'Atos - Wholesale-Reseller',
            Account.Partner_ID__c => '12345',
            Account.PartnerStatus__c => 'Active'
        })
        .create()
        .getRecord();

        Account testAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setField(Account.Name, 'TestAccount')
            .create()
            .getRecord();

        Contact partnerContact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setField(Contact.AccountId, partnerAccount.Id)
            .create()
            .getRecord();

        Contact contact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setField(Contact.AccountId, testAccount.Id)
            .create()
            .getRecord();

        AccountContactRole accRole = (AccountContactRole) new SObjectBuilder(AccountContactRole.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                AccountContactRole.AccountId => testAccount.Id,
                AccountContactRole.ContactId => contact.Id,
                AccountContactRole.Role => AccountContactRoleHelper.CONTACT_ROLE_ACCOUNT_PAYABLE
            })
            .create()
            .getRecord();

        AccountContactRole accPartnerRole = (AccountContactRole) new SObjectBuilder(AccountContactRole.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                AccountContactRole.AccountId => partnerAccount.Id,
                AccountContactRole.ContactId => partnerContact.Id,
                AccountContactRole.Role => AccountContactRoleHelper.CONTACT_ROLE_ACCOUNT_PAYABLE
            })
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.RecordTypeId => OpportunityHelper.RT_ID_NEW_SALES_OPPORTUNITY,
                    Opportunity.Brand_Name__c => OpportunityHelper.BRAND_AVAYA,
                    Opportunity.CloseDate => system.today().addMonths(1),
                    Opportunity.AccountId => testAccount.Id})
            .create()
            .getRecord();

		Triggers.switchOn();

        Approval__c approval = (Approval__c) new SObjectBuilder(Approval__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Approval__c.Opportunity__c => opp.Id,
                Approval__c.Account__c => testAccount.Id,
                Approval__c.RecordTypeId => ApprovalHelper.RT_ID_INVOICING_REQUEST,
                Approval__c.AccountPayableContact__c => contact.Id,
                Approval__c.Monthly_Credit_Limit__c => 180,
                Approval__c.PartnerAccountPayableContact__c => partnerContact.Id,
                Approval__c.SwitchInvoicePartnerAccount__c => partnerAccount.Id,
                Approval__c.Status__c => ApprovalHelper.STATUS_NEW,
                Approval__c.Potential_Users__c => 1,
                Approval__c.Reason_Customer_is_Requesting_Invoicing__c => 'test'
            })
            .create()
            .getRecord();

        Test.startTest();

        Response result = PartnerOperationsController.recallApproval(approval.Id);

        System.assertEquals(Response.STATUS_SUCCESS, result.status);
        System.assertEquals('Approval is recalled' , result.messages[0].message);

        Approval__c approvedApproval = (Approval__c) new SObjectBuilder(Approval__c.SObjectType)
        .setFields(new Map<SObjectField, Object>{
            Approval__c.Opportunity__c => opp.Id,
            Approval__c.Status__c => ApprovalHelper.STATUS_APPROVED
        })
        .create()
        .getRecord();

        Response resultOnApproved = PartnerOperationsController.recallApproval(approvedApproval.Id);

        System.assertEquals(Response.STATUS_SUCCESS, resultOnApproved.status);
        System.assertEquals('Payment method was already updated, you cannot revert changes at this point' , resultOnApproved.messages[0].message);

        Test.stopTest();
    }

    private static Opportunity getOpportunity() {
		return (Opportunity) new OpportunitySelector()
			.selectOpportunities()
			.selectFields(
                new Set<SObjectField>{
                    Opportunity.StageName,
                    Opportunity.AccountId,
                    Opportunity.Brand_Name__c
                }
            )
            .setCondition('Brand_Name__c =\'RingCentral EU\'')
			.executeQuery()
			.get(0);
    }

    private static Approval__c getApproval(){
        return (Approval__c) new ApprovalSelector()
            .selectApprovals()
            .selectFields(
                new Set<SObjectField>{
                    Approval__c.Status__c,
                    Approval__c.Account__c,
                    Approval__c.RecordTypeId,
                    Approval__c.AccountPayableContact__c
                }
            )
            .setCondition('Name =\'test Approval\'')
            .executeQuery()
            .get(0);
    }

    @isTest
    private static void testGetDefaultFieldValues() {
        Account partnerAccount = (Account) new SObjectBuilder(Account.SObjectType)
        .setFields( new Map<SObjectField, Object>{
            Account.Name => 'TestAccount',
            Account.RecordTypeId => AccountHelper.RT_ID_PARTNER_ACCOUNT,
            Account.Credit_Limit__c => 150,
            Account.BusinessIdentity__c => 'RingCentral Ink.',
            Account.Partner_Type__c => 'Atos - Wholesale-Reseller',
            Account.Partner_ID__c => '12345',
            Account.PartnerStatus__c => 'Active'
        })
        .create()
        .getRecord();

        Account testAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields( new Map<SObjectField, Object>{
                Account.Name => 'TestAccount',
                Account.BusinessIdentity__c => 'RingCentral Ink.',
                Account.Partner_Type__c => 'Atos - Wholesale-Reseller',
                Account.Partner_Account__c => partnerAccount.Id,
                Account.Partner_ID__c => '12345'
            })
            .create()
            .getRecord();

        Contact partnerContact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setField(Contact.AccountId, partnerAccount.Id)
            .create()
            .getRecord();

        Contact contact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setField(Contact.AccountId, testAccount.Id)
            .create()
            .getRecord();

        AccountContactRole accRole = (AccountContactRole) new SObjectBuilder(AccountContactRole.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                AccountContactRole.AccountId => testAccount.Id,
                AccountContactRole.ContactId => contact.Id,
                AccountContactRole.Role => AccountContactRoleHelper.CONTACT_ROLE_ACCOUNT_PAYABLE
            })
            .create()
            .getRecord();

        AccountContactRole accPartnerRole = (AccountContactRole) new SObjectBuilder(AccountContactRole.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                AccountContactRole.AccountId => partnerAccount.Id,
                AccountContactRole.ContactId => partnerContact.Id,
                AccountContactRole.Role => AccountContactRoleHelper.CONTACT_ROLE_ACCOUNT_PAYABLE
            })
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.RecordTypeId => OpportunityHelper.RT_ID_NEW_SALES_OPPORTUNITY,
                Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL_EU,
                Opportunity.AccountId => testAccount.Id
            })
            .create()
            .getRecord();

        Test.startTest();

        Approval__c lastApprovedApproval = (Approval__c) new SObjectBuilder(Approval__c.SObjectType)
        .setFields(new Map<SObjectField, Object>{
            Approval__c.Opportunity__c => opp.Id,
            Approval__c.Account__c => testAccount.Id,
            Approval__c.RecordTypeId => ApprovalHelper.RT_ID_INVOICING_REQUEST,
            Approval__c.AccountPayableContact__c => contact.Id,
            Approval__c.Monthly_Credit_Limit__c => 180,
            Approval__c.PartnerAccountPayableContact__c => partnerContact.Id,
            Approval__c.SwitchInvoicePartnerAccount__c => partnerAccount.Id,
            Approval__c.Status__c => ApprovalHelper.STATUS_APPROVED,
            Approval__c.Potential_Users__c => 1,
            Approval__c.Reason_Customer_is_Requesting_Invoicing__c => 'test'
        })
        .create()
        .getRecord();

        BillingWrappers.ApprovalParams params = new BillingWrappers.ApprovalParams();
        params.accountId = testAccount.Id;
        params.accountPartnerId = partnerAccount.Id;

        Response result = PartnerOperationsController.getDefaultFieldValues(params);
        Approval__c app = (Approval__c) result.getData('defaultFieldValues');
        System.assertEquals(app.Monthly_Credit_Limit__c, lastApprovedApproval.Monthly_Credit_Limit__c, 'Monthly_Credit_Limit__c field is wrong');
        System.assertEquals(app.Account__c, lastApprovedApproval.Account__c, 'Account__c field is wrong');

        Test.stopTest();
    }

    @isTest
    private static void testIsCurrentSyncScenarioLastStepCompleted() {
        final String syncInfoUpsellNotCompleted = '{"timeStampMap":{"SYNC_INVOICE":"2022-02-08T14:08:19.649Z","CONTRACT_SYNC":"2022-02-08T14:06:08.971Z"},' + 
            '"scenarioName":"WHOLESALE_CONTRACTED_PAID_UPGRADE_UPSELL_INVOICE", "stepNames":["CONTRACT_SYNC","DISCOUNT_SYNC","SYNC_INVOICE","UPGRADE","UP_SELL"]}';

        final String syncInfoUpsellCompleted = '{"timeStampMap":{"SYNC_INVOICE":"2022-02-08T14:08:19.649Z","CONTRACT_SYNC":"2022-02-08T14:06:08.971Z","UP_SELL": "2022-02-08T14:06:09.971Z"},' + 
            '"scenarioName":"WHOLESALE_CONTRACTED_PAID_UPGRADE_UPSELL_INVOICE", "stepNames":["CONTRACT_SYNC","DISCOUNT_SYNC","SYNC_INVOICE","UPGRADE","UP_SELL"]}';
        Triggers.switchOff();

        // The last step of Sync With NGBS scenario has not completed
        Account parentPartnerAcc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Billing_ID__c => ValueProviderBuilder.provideUniqueString(),
                Account.RC_Account_Status__c => AccountHelper.PAID_STATUS,
                Account.Partner_ID__c => ValueProviderBuilder.provideUniqueString(),
                Account.NGBS_Partner_ID__c => 12345,
                Account.Partner_Type__c =>  AccountHelper.ACCOUNT_PARTNER_WHOLESALE
            })
            .create()
            .getRecord();

        Account testAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields( new Map<SObjectField, Object>{
                Account.Name => 'TestAccount',
                Account.BusinessIdentity__c => 'RingCentral Ink.',
                Account.Partner_Type__c => 'Atos - Wholesale-Reseller',
                Account.Billing_ID__c => '123',
                Account.Partner_Account__c => parentPartnerAcc.Id,
                Account.NGBS_Partner_ID__c => ValueProviderBuilder.provideUniqueNumber()
            })
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.RecordTypeId => OpportunityHelper.RT_ID_NEW_SALES_OPPORTUNITY,
                Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL_EU,
                Opportunity.AccountId => testAccount.Id,
                Opportunity.isUpsellStepCompleted__c => false,
                Opportunity.CloseDate => system.today().addMonths(1),
                Opportunity.SyncInfo__c => syncInfoUpsellNotCompleted
            })
            .create()
            .getRecord();

        Quote q = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Quote.Name => 'quotetest',
                Quote.OpportunityId => opp.Id,
                Quote.Total_Number_of_Digital_Lines__c => 10,
                Quote.Account__c => testAccount.Id,
                Quote.isPrimary__c => true,
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.ProServ_Sold_Date__c => System.now(),
                Quote.Pricebook2Id => Test.getStandardPriceBookId(),
                Quote.Package_Info__c => NGBSTestDataGenerator.generateQuotePackageInfo()
            })
            .create()
            .getRecord();
        Triggers.switchOn();
        Test.startTest();
            BillingHttpRequestMock tstMock = new BillingHttpRequestMock();
            Test.setMock(HttpCalloutMock.class, tstMock);

            Boolean result = PartnerOperationsController.isCurrentSyncScenarioLastStepCompleted(opp.Id);
		Test.stopTest();
        Assert.areEqual(false, result, 'Something is wrong, Sync With NGBS is completed');

        // The last step of Sync With NGBS scenario completed successfuly
        Opportunity opp2 = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.RecordTypeId => OpportunityHelper.RT_ID_NEW_SALES_OPPORTUNITY,
                Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL_EU,
                Opportunity.AccountId => testAccount.Id,
                Opportunity.isUpsellStepCompleted__c => true,
                Opportunity.SyncInfo__c => syncInfoUpsellCompleted
            })
            .create()
            .getRecord();

        Quote q2 = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Quote.Name => 'quotetest2',
                Quote.OpportunityId => opp2.Id,
                Quote.Total_Number_of_Digital_Lines__c => 10,
                Quote.Account__c => testAccount.Id,
                Quote.isPrimary__c => true,
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.ProServ_Sold_Date__c => System.now(),
                Quote.Pricebook2Id => Test.getStandardPriceBookId(),
                Quote.Package_Info__c => NGBSTestDataGenerator.generateQuotePackageInfo()
            })
            .create()
            .getRecord();

        result = PartnerOperationsController.isCurrentSyncScenarioLastStepCompleted(opp2.Id);
        Assert.areEqual(true, result, 'Sync With NGBS is not completed');
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testIsCurrentSyncScenarioLastStepCompleted_RepriceIsNotPresentInScenario() {
        SWNMockBuilders.ScenarioBuilder syncScenarioBuilder = new SWNMockBuilders.ScenarioBuilder(TEST_SCENARIO)
            .addSteps(new List<String> {
                SWNStep.DISCOUNT_SYNC,
                SWNStep.CONTRACT_SYNC,
                SWNStep.SYNC_INVOICE
            })
            .buildAndPut();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.SyncInfo__c => new SWNMockBuilders.SyncInfoBuilder(syncScenarioBuilder).build().getAsJson(),
                Opportunity.isDiscountsSynced__c => true,
                Opportunity.isContractsSynced__c => true,
                Opportunity.isInvoiceStepCompleted__c => true,
                Opportunity.isRepriceSynced__c => false
            })
            .build()
            .getRecord();
        Quote qt = buildQuoteWithAccount();
        qt = (Quote) Test_Utils.putIntoUnwritableField(qt, Quote.class, 'Opportunity', opp);
        SWNDataCollector sdc = new SWNDataCollector();
        sdc.qt = qt;
        sdc.syncable = NGBSSyncables.getSyncable(false, qt.Id, opp);
        User salesUser = createSalesUserWithRepricePermission();

        Boolean resultWhenLastStepIsCompleted;
        Boolean resultWhenLastStepIsNotCompleted;
        Test.setMock(HttpCalloutMock.class, buildMock());
        Test.startTest();
            System.runAs(salesUser) {
                resultWhenLastStepIsCompleted = PartnerOperationsController.isCurrentSyncScenarioLastStepCompleted(sdc);

                opp.isInvoiceStepCompleted__c = false;
                resultWhenLastStepIsNotCompleted = PartnerOperationsController.isCurrentSyncScenarioLastStepCompleted(sdc);
            }
        Test.stopTest();

        assertIsCurrentSyncScenarioLastStepCompleted(resultWhenLastStepIsCompleted, resultWhenLastStepIsNotCompleted);
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testIsCurrentSyncScenarioLastStepCompleted_RepriceIsLastMustNotBeSkippedNotCompleted() {
        SWNMockBuilders.ScenarioBuilder syncScenarioBuilder = new SWNMockBuilders.ScenarioBuilder(TEST_SCENARIO)
            .addSteps(new List<String> {
                SWNStep.DISCOUNT_SYNC,
                SWNStep.CONTRACT_SYNC,
                SWNStep.SYNC_INVOICE,
                SWNStep.REPRICE_SYNC
            })
            .buildAndPut();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.SyncInfo__c => new SWNMockBuilders.SyncInfoBuilder(syncScenarioBuilder).build().getAsJson(),
                Opportunity.isDiscountsSynced__c => true,
                Opportunity.isContractsSynced__c => true,
                Opportunity.isInvoiceStepCompleted__c => true,
                Opportunity.isRepriceSynced__c => false
            })
            .build()
            .getRecord();
        Quote qt = buildQuoteWithChangedPrice();
        qt = (Quote) Test_Utils.putIntoUnwritableField(qt, Quote.class, 'Opportunity', opp);
        SWNDataCollector sdc = new SWNDataCollector();
        sdc.qt = qt;
        User salesUser = createSalesUserWithRepricePermission();

        Boolean whenRepriceIsNotCompleted;
        Test.setMock(HttpCalloutMock.class, buildMock());
        Test.startTest();
            System.runAs(salesUser) {
                whenRepriceIsNotCompleted = PartnerOperationsController.isCurrentSyncScenarioLastStepCompleted(sdc);
            }
        Test.stopTest();

        assertIsCurrentSyncScenarioLastStepCompleted(
            whenRepriceIsNotCompleted,
            false,
            'isCurrentSyncScenarioLastStepCompleted must return false when the last reprice step is not completed'
        );
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testIsCurrentSyncScenarioLastStepCompleted_RepriceIsLastMustNotBeSkippedCompleted() {
        SWNMockBuilders.ScenarioBuilder syncScenarioBuilder = new SWNMockBuilders.ScenarioBuilder(TEST_SCENARIO)
            .addSteps(new List<String> {
                SWNStep.DISCOUNT_SYNC,
                SWNStep.CONTRACT_SYNC,
                SWNStep.SYNC_INVOICE,
                SWNStep.REPRICE_SYNC
            })
            .buildAndPut();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.SyncInfo__c => new SWNMockBuilders.SyncInfoBuilder(syncScenarioBuilder).build().getAsJson(),
                Opportunity.isDiscountsSynced__c => true,
                Opportunity.isContractsSynced__c => true,
                Opportunity.isInvoiceStepCompleted__c => true,
                Opportunity.isRepriceSynced__c => true
            })
            .build()
            .getRecord();
        Quote qt = buildQuoteWithChangedPrice();
        qt = (Quote) Test_Utils.putIntoUnwritableField(qt, Quote.class, 'Opportunity', opp);
        SWNDataCollector sdc = new SWNDataCollector();
        sdc.qt = qt;
        User salesUser = createSalesUserWithRepricePermission();

        Boolean whenRepriceIsCompleted;
        Test.setMock(HttpCalloutMock.class, buildMock());
        Test.startTest();
            System.runAs(salesUser) {
                whenRepriceIsCompleted = PartnerOperationsController.isCurrentSyncScenarioLastStepCompleted(sdc);
            }
        Test.stopTest();

        assertIsCurrentSyncScenarioLastStepCompleted(
            whenRepriceIsCompleted,
            true,
            'isCurrentSyncScenarioLastStepCompleted must return true when the last reprice step is completed'
        );
    }

    @isTest
    private static void testGetWholesaleRecordTypeId() {
        Response testResp = new Response();
        testResp.setData('wholesaleRecordTypeId', String.valueOf(ApprovalHelper.RT_ID_INVOICE_WHOLESALE_REQUEST));

        Test.startTest();

        Response result = PartnerOperationsController.getWholesaleRecordTypeId();
        System.assertEquals(Response.STATUS_SUCCESS, result.status);
        System.assertEquals(testResp.data, result.data);

        Test.stopTest();
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    private static void testGetPartnerOperation() {
        Opportunity opp = getOpportunity();
        PartnerOperationsLog__c log = (PartnerOperationsLog__c) new SObjectBuilder(PartnerOperationsLog__c.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                PartnerOperationsLog__c.Opportunity__c => opp.Id,
                PartnerOperationsLog__c.Account__c => opp.AccountId,
                PartnerOperationsLog__c.isRejected__c => false,
                PartnerOperationsLog__c.isCompleted__c => false
            })
            .create()
            .getRecord();

        Test.startTest();

        Response result = PartnerOperationsController.getCurrentOperation(opp.AccountId);

        Test.stopTest();
    }

    @isTest
    private static void testGetEmptyPartnerOperation() {
        Account testAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields( new Map<SObjectField, Object>{
                Account.Name => 'TestAccount',
                Account.BusinessIdentity__c => 'RingCentral Ink.',
                Account.Partner_Type__c => 'Atos - Wholesale-Reseller',
                Account.Billing_ID__c => '123',
                Account.NGBS_Partner_ID__c => ValueProviderBuilder.provideUniqueNumber()
            })
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.RecordTypeId => OpportunityHelper.RT_ID_NEW_SALES_OPPORTUNITY,
                Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL_EU,
                Opportunity.AccountId => testAccount.Id,
                Opportunity.isUpsellStepCompleted__c => false,
                Opportunity.CloseDate => system.today().addMonths(1),
                Opportunity.SyncInfo__c => '{"timeStampMap":{"SYNC_INVOICE":"2022-02-08T14:08:19.649Z","CONTRACT_SYNC":"2022-02-08T14:06:08.971Z"},"scenarioName":"WHOLESALE_CONTRACTED_PAID_UPGRADE_UPSELL_INVOICE"}'
            })
            .create()
            .getRecord();

        PartnerOperationsLog__c log = (PartnerOperationsLog__c) new SObjectBuilder(PartnerOperationsLog__c.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                PartnerOperationsLog__c.Opportunity__c => opp.Id,
                PartnerOperationsLog__c.isRejected__c => false,
                PartnerOperationsLog__c.isCompleted__c => false
            })
            .create()
            .getRecord();

        Test.startTest();

        Response result = PartnerOperationsController.getCurrentOperation(opp.AccountId);

        System.assertEquals(Response.STATUS_ERROR, result.status);
    }

    @isTest
    private static void testRejectPartnerOperation() {
        Opportunity opp = getOpportunity();
        PartnerOperationsLog__c log = (PartnerOperationsLog__c) new SObjectBuilder(PartnerOperationsLog__c.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                PartnerOperationsLog__c.Opportunity__c => opp.Id,
                PartnerOperationsLog__c.isRejected__c => false,
                PartnerOperationsLog__c.isCompleted__c => false
            })
            .create()
            .getRecord();

        Test.startTest();

        Response result = PartnerOperationsController.rejectPartnerOperation(log.Id);

        PartnerOperationsLog__c partnerOperationsLog = (PartnerOperationsLog__c)
            new QueryFactory(PartnerOperationsLog__c.SObjectType)
                .selectFields(new List<String> {'isRejected__c'})
                .setCondition('Id =:bind0')
                .setQueryBindings(new List<Object>{log.Id})
                .executeQuery()
                .get(0);

        System.assertEquals(Response.STATUS_SUCCESS, result.status);
        System.assertEquals('Partner Operations Log is rejected' , result.messages[0].message);
        System.assertNotEquals(true, log.isRejected__c);
        System.assertEquals(true, partnerOperationsLog.isRejected__c);

        Test.stopTest();

    }

    @isTest
    private static void testGetPartnerOperationSteps() {
		Map<String, PartnerOperationsHelper.PartnerStep> Steps =
            new Map<String, PartnerOperationsHelper.PartnerStep>
        {
            'CREATE_WHOLESALE_OPPTY' => new PartnerOperationsHelper.PartnerStep(
                'CREATE_WHOLESALE_OPPTY',
                'Create New Wholesale Opportunity',
                'You will be redirected to a new Opportunity Creation Page. '
                + 'Wholesale Opportunity with selected Partner Package that is similar to current Customer package is required. '
                + '\nComplete all Quoting Steps in order to proceed.',
                'Create New Opportunity',
                1
            ),
            'CREATE_WHOLESALE_REQUEST' => new PartnerOperationsHelper.PartnerStep(
                'CREATE_WHOLESALE_REQUEST',
                'Create New Invoice-Wholesale Request',
                'You will be redirected to a new Invoice Approval Creation Form. '
                + 'Create Invoice-Wholesale Request, adjust calculated limits as needed and submit for approval',
                'Create New Request',
                2
            ),
            'APPROVE_WHOLESALE_REQUEST' => new PartnerOperationsHelper.PartnerStep(
                'APPROVE_WHOLESALE_REQUEST',
                'Get Invoice-Wholesale Request approval',
                'If the limits on the approval are less or equal to Partner Credit Limits, '
                + 'the request will be approved automatically. Otherwise, wait for the Invoice Billing Approval',
                'Open Invoice-Wholesale Request',
                3
            ),
            'SYNC_WITH_NGBS' => new PartnerOperationsHelper.PartnerStep(
                'SYNC_WITH_NGBS',
                'Sync to NGBS',
                'Please go back to Opportunity and close it. Also perform SyncWithNGBS process to sync new information to NGBS.',
                'Open Wholesale Opportunity',
                4
            )
        };
        Response testResp = new Response();
        testResp.setData('steps', Steps);

        Test.startTest();

        Response result = PartnerOperationsController.getPartnerOperationSteps();
        Map<String, PartnerOperationsHelper.PartnerStep> stepsMap = (Map<String, PartnerOperationsHelper.PartnerStep>) result.data.get('steps');
        PartnerOperationsHelper.PartnerStep pStep = (PartnerOperationsHelper.PartnerStep) stepsMap.get('CREATE_WHOLESALE_OPPTY');

        System.assertEquals(Response.STATUS_SUCCESS, result.status);
        System.assertEquals('CREATE_WHOLESALE_OPPTY', pStep.name);

        Test.stopTest();
    }

    @isTest
    private static void testGetPartnerOperationScenario() {
        Account testAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setField(Account.Name, 'TestAccount')
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.RecordTypeId => OpportunityHelper.RT_ID_NEW_SALES_OPPORTUNITY,
                    Opportunity.Brand_Name__c => OpportunityHelper.BRAND_AVAYA,
                    Opportunity.CloseDate => system.today().addMonths(1),
                    Opportunity.AccountId => testAccount.Id
                })
            .create()
            .getRecord();

        Test.startTest();

        Approval__c approvedApproval = (Approval__c) new SObjectBuilder(Approval__c.SObjectType)
        .setFields(new Map<SObjectField, Object>{
            Approval__c.Opportunity__c => opp.Id,
            Approval__c.Status__c => ApprovalHelper.STATUS_APPROVED,
            Approval__c.Potential_Users__c => 1,
            Approval__c.Reason_Customer_is_Requesting_Invoicing__c => 'test'
        })
        .create()
        .getRecord();

        PartnerOperationsLog__c log = (PartnerOperationsLog__c) new SObjectBuilder(PartnerOperationsLog__c.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                PartnerOperationsLog__c.Account__c => testAccount.Id,
                PartnerOperationsLog__c.Opportunity__c => opp.Id,
                PartnerOperationsLog__c.Approval__c => approvedApproval.Id,
                PartnerOperationsLog__c.isRejected__c => false,
                PartnerOperationsLog__c.isCompleted__c => false
            })
            .create()
            .getRecord();

        PartnerOperationsStep__c step = (PartnerOperationsStep__c) new SObjectBuilder(PartnerOperationsStep__c.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                PartnerOperationsStep__c.PartnerOperationsLog__c => log.Id,
                PartnerOperationsStep__c.Name => 'CREATE_WHOLESALE_OPPTY',
                PartnerOperationsStep__c.isCompleted__c => true
            })
            .create()
            .getRecord();

        Response result = PartnerOperationsController.getPartnerOperationScenario(log.Id);
        PartnerOperationsHelper.PartnerScenario ps = (PartnerOperationsHelper.PartnerScenario) result.data.get('scenario');
        List<PartnerOperationsHelper.PartnerScenarioStep> pStep = (List<PartnerOperationsHelper.PartnerScenarioStep>) ps.steps;

        System.assertEquals(Response.STATUS_SUCCESS, result.status);
        System.assertEquals(step.name, pStep[0].name);

        Test.stopTest();
    }

    @isTest
    private static void testValidateStep() {
    Test.startTest();
        Account testAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setField(Account.Name, 'TestAccount')
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.RecordTypeId => OpportunityHelper.RT_ID_NEW_SALES_OPPORTUNITY,
                    Opportunity.Brand_Name__c => OpportunityHelper.BRAND_AVAYA,
                    Opportunity.CloseDate => system.today().addMonths(1),
                    Opportunity.AccountId => testAccount.Id
                })
            .create()
            .getRecord();
        Triggers.switchOff();
         Approval__c approvedApproval = (Approval__c) new SObjectBuilder(Approval__c.SObjectType)
        .setFields(new Map<SObjectField, Object>{
            Approval__c.Opportunity__c => opp.Id,
            Approval__c.Status__c => ApprovalHelper.STATUS_APPROVED,
            Approval__c.Potential_Users__c => 1,
            Approval__c.Reason_Customer_is_Requesting_Invoicing__c => 'test'
        })
        .create()
        .getRecord();
        Triggers.switchOn();
        PartnerOperationsLog__c log = (PartnerOperationsLog__c) new SObjectBuilder(PartnerOperationsLog__c.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                PartnerOperationsLog__c.Account__c => testAccount.Id,
                PartnerOperationsLog__c.Opportunity__c => opp.Id,
                PartnerOperationsLog__c.Approval__c => approvedApproval.Id,
                PartnerOperationsLog__c.isRejected__c => false,
                PartnerOperationsLog__c.isCompleted__c => false
            })
            .create()
            .getRecord();

        PartnerOperationsStep__c firstStep = (PartnerOperationsStep__c) new SObjectBuilder(PartnerOperationsStep__c.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                PartnerOperationsStep__c.PartnerOperationsLog__c => log.Id,
                PartnerOperationsStep__c.Name => 'CREATE_WHOLESALE_OPPTY',
                PartnerOperationsStep__c.isCompleted__c => false
            })
            .create()
            .getRecord();

        PartnerOperationsStep__c secondStep = (PartnerOperationsStep__c) new SObjectBuilder(PartnerOperationsStep__c.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                PartnerOperationsStep__c.PartnerOperationsLog__c => log.Id,
                PartnerOperationsStep__c.Name => 'CREATE_WHOLESALE_REQUEST',
                PartnerOperationsStep__c.isCompleted__c => false
            })
            .create()
            .getRecord();

        PartnerOperationsStep__c thirdStep = (PartnerOperationsStep__c) new SObjectBuilder(PartnerOperationsStep__c.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                PartnerOperationsStep__c.PartnerOperationsLog__c => log.Id,
                PartnerOperationsStep__c.Name => 'APPROVE_WHOLESALE_REQUEST',
                PartnerOperationsStep__c.isCompleted__c => false
            })
            .create()
            .getRecord();

        PartnerOperationsStep__c fourthStep = (PartnerOperationsStep__c) new SObjectBuilder(PartnerOperationsStep__c.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                PartnerOperationsStep__c.PartnerOperationsLog__c => log.Id,
                PartnerOperationsStep__c.Name => 'SYNC_WITH_NGBS',
                PartnerOperationsStep__c.isCompleted__c => false
            })
            .create()
            .getRecord();

        String testParamsFirstStep = '{"logId":"' + log.Id + '", "name":"' + firstStep.Name + '"}';
        String testParamsSecondStep = '{"logId":"' + log.Id + '", "name":"' + secondStep.Name + '"}';
        String testParamsThirdStep = '{"logId":"' + log.Id + '", "name":"' + thirdStep.Name + '"}';
        String testParamsFourthStep = '{"logId":"' + log.Id + '", "name":"' + fourthStep.Name + '"}';

        Response firstResult = PartnerOperationsController.validateStep(testParamsFirstStep);
        Response secondResult = PartnerOperationsController.validateStep(testParamsSecondStep);
        Response thirdResult = PartnerOperationsController.validateStep(testParamsThirdStep);
        Response fourthResult = PartnerOperationsController.validateStep(testParamsFourthStep);

        System.assertEquals(Response.STATUS_SUCCESS, firstResult.status);
        System.assertEquals(Response.STATUS_SUCCESS, secondResult.status);
        System.assertEquals(Response.STATUS_SUCCESS, thirdResult.status);
        System.assertEquals(Response.STATUS_SUCCESS, fourthResult.status);
        //System.assertEquals(step.name, pStep[0].name);

        Test.stopTest();
    }

    private static void assertIsCurrentSyncScenarioLastStepCompleted(Boolean resultWhenLastStepIsCompleted, Boolean resultWhenLastStepIsNotCompleted) {
        Assert.isNotNull(resultWhenLastStepIsCompleted, 'isCurrentSyncScenarioLastStepCompleted must not return null');
        Assert.isNotNull(
            resultWhenLastStepIsNotCompleted,
            'isCurrentSyncScenarioLastStepCompleted must not return null even if the last step is not completed'
        );
        Assert.isTrue(
            resultWhenLastStepIsCompleted,
            'isCurrentSyncScenarioLastStepCompleted must return true, when the last step is completed'
        );
        Assert.isFalse(
            resultWhenLastStepIsNotCompleted,
            'isCurrentSyncScenarioLastStepCompleted must return false, when the last step is not completed'
        );
    }

    private static void assertIsCurrentSyncScenarioLastStepCompleted(Boolean result, Boolean expectedResult, String assertMessage) {
        Assert.isNotNull(result, 'isCurrentSyncScenarioLastStepCompleted must not return null');
        Assert.areEqual(
            expectedResult,
            result,
            assertMessage
        );
    }

    private static Lead createLead() {
        return (Lead) new SObjectBuilder(Lead.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Lead.email => 'test@email.com',
                    Lead.LastName => 'TestLastName',
                    Lead.Company => 'TestCompany',
                    Lead.Status => '1. New'
                }
            )
            .create()
            .getRecord();
    }

    private static User createSalesUserWithRepricePermission() {
        Profile salesProfile = (Profile) new ProfileSelector()
            .selectProfileByName(ProfileHelper.PROFILE_NAME_SALES_REP_LIGHTNING)
            .executeQuery()
            .get(0);

        User salesUser = (User) new SObjectBuilder(User.SObjectType)
            .setField(User.ProfileId, salesProfile.Id)
            .create()
            .getRecord();

        PermissionSet ps1 = new PermissionSet(
            Name = CustomPermissionHelper.PERMISSION_CAN_TRIGGER_NGBS_REPRICE,
            Label = CustomPermissionHelper.PERMISSION_CAN_TRIGGER_NGBS_REPRICE
        );
        insert ps1;

        SetupEntityAccess testEntityAccess = new SetupEntityAccess(
            ParentId = ps1.Id,
            SetupEntityId = [
                SELECT Id
                FROM CustomPermission
                WHERE DeveloperName = :CustomPermissionHelper.PERMISSION_CAN_TRIGGER_NGBS_REPRICE
            ].Id
        );
        insert testEntityAccess;

        insert new PermissionSetAssignment(
            AssigneeId = salesUser.Id,
            PermissionSetId = ps1.Id
        );

        return salesUser;
    }

    private static Quote buildQuoteWithAccount() {
        Account acc = (Account) new SObjectBuilder(Account.sObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Name => 'Test Account',
                Account.Id => ValueProviderBuilder.provideDummyId(Account.sObjectType),
                Account.Billing_Id__c => BILLING_ID
            })
            .build()
            .getRecord();
        Quote testQuote = (Quote) new SObjectBuilder(Quote.sObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.Id => ValueProviderBuilder.provideDummyId(Quote.sObjectType),
                Quote.Package_Info__c => JSON.serialize(buildPackageInfo())
            })
            .build()
            .getRecord();
        return (Quote) Test_Utils.putIntoUnwritableFields(
            testQuote,
            Quote.class,
            new Map<String, Object> {
                'Account' => acc,
                'AccountId' => acc.Id
            }
        );
    }

    private static Quote buildQuoteWithChangedPrice() {
        final Decimal ORIGINAL_UNIT_PRICE = 100;
        final Decimal ORIGINAL_EFFECTIVE_PRICE = 100;
        final Decimal NEW_UNIT_PRICE = ORIGINAL_UNIT_PRICE + 1;
        final Decimal NEW_EFFECTIVE_PRICE = ORIGINAL_EFFECTIVE_PRICE + 1;

        Product2 product = (Product2) new SObjectBuilder(Product2.sObjectType)
            .setFields(new Map<SObjectField, Object> {
                Product2.Family => Product2Helper.FAMILY_TIER,
                Product2.Id => ValueProviderBuilder.provideDummyId(Product2.sObjectType)
            })
            .build()
            .getRecord();
        Entitlement__c ent = (Entitlement__c) new SObjectBuilder(Entitlement__c.sObjectType)
            .setFields(new Map<SObjectField, Object> {
                Entitlement__c.Id => ValueProviderBuilder.provideDummyId(Entitlement__c.sObjectType),
                Entitlement__c.Price__c => ORIGINAL_UNIT_PRICE
            })
            .build()
            .getRecord();
        ent = (Entitlement__c) Test_Utils.putIntoUnwritableField(
            ent,
            Entitlement__c.class,
            'EffectivePrice__c',
            ORIGINAL_EFFECTIVE_PRICE
        );
        QuoteLineItem qli = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.sObjectType)
            .setFields(new Map<SObjectField, Object> {
                QuoteLineItem.Product2Id => product.Id,
                QuoteLineItem.Entitlement__c => ent.Id,
                QuoteLineItem.UnitPrice => NEW_UNIT_PRICE
            })
            .build()
            .getRecord();
        qli = (QuoteLineItem) Test_Utils.putIntoUnwritableFields(
            qli,
            QuoteLineItem.class,
            new Map<String, Object> {
                'EffectivePrice__c' => NEW_EFFECTIVE_PRICE,
                'Product2' => product,
                'Entitlement__r' => ent
            }
        );
        return (Quote) Test_Utils.putIntoUnwritableField(
            buildQuoteWithAccount(),
            Quote.class,
            'QuoteLineItems',
            new List<QuoteLineItem> { qli }
        );
    }

    private static List<BillingWrappers.BillingContract> buildActiveBillingContracts() {
        BillingWrappers.BillingContract cnt = new BillingWrappers.BillingContract();
        cnt.id = '2';
        cnt.startBillingCycleNumber = 1;
        cnt.term = 24;
        cnt.renewalTerm = 24;
        cnt.startDate = System.today();
        cnt.description = '{"contractExtId":"nib","salesAgreement":"Test"}';
        return new List<BillingWrappers.BillingContract> {cnt};
    }

    private static BillingWrappers.NGBSAccount buildBillingAccountPackage() {
        BillingWrappers.NGBSAccountPackage ngbsAccountPackage = new BillingWrappers.NGBSAccountPackage();
        ngbsAccountPackage.id = PACKAGE_INFO_ID;
        ngbsAccountPackage.catalogId = CATALOG_ID;
        ngbsAccountPackage.version = PACKAGE_INFO_VERSION;
        ngbsAccountPackage.currencyCode = 'USD';
        ngbsAccountPackage.status = 'active';

        BillingWrappers.NGBSAccount ngbsAccount = new BillingWrappers.NGBSAccount();
        ngbsAccount.packages = new List<BillingWrappers.NGBSAccountPackage> {ngbsAccountPackage};
        return ngbsAccount;
    }

    private static List<BillingWrappers.QuotePackageInfo> buildPackageInfo() {
        BillingWrappers.PackageInfo innerPackageInfo = new BillingWrappers.PackageInfo();
        innerPackageInfo.id = INNER_PACKAGE_INFO_ID;
        innerPackageInfo.catalogId = CATALOG_ID;
        innerPackageInfo.version = PACKAGE_INFO_VERSION;

        BillingWrappers.Edition edition = new BillingWrappers.Edition();
        edition.id = EDITION_ID;
        edition.name = EDITION_NAME;

        BillingWrappers.Contract contract = new BillingWrappers.Contract();
        contract.id = CONTRACT_ID;
        contract.extId = CONTRACT_EXT_ID;
        contract.billingId = CONTRACT_BILLING_ID;

        BillingWrappers.GlobalPackageLimits packageLimit = new BillingWrappers.GlobalPackageLimits();
        packageLimit.value = PACKAGE_LIMIT_VALUE;
        packageLimit.code = PACKAGE_LIMIT_CODE;
        packageLimit.name = PACKAGE_LIMIT_CODE;
        packageLimit.limitType = 'Amount';
        packageLimit.scope = 'BillingCycle';
        packageLimit.transactionType = 'Any';
        packageLimit.target = 'Global';
        packageLimit.isOverride = 'false';

        BillingWrappers.QuotePackageInfo pInfo = new BillingWrappers.QuotePackageInfo();
        pInfo.id = PACKAGE_INFO_ID;
        pInfo.version = PACKAGE_INFO_VERSION;
        pInfo.packageInfo = innerPackageInfo;
        pInfo.productName = QuoteHelper.NGBS_OFFICE_PRODUCT;
        pInfo.duration = Product2Helper.CHARGE_TERM_MONTHLY;
        pInfo.edition = edition;
        pInfo.contract = contract;
        pInfo.offerType = QuoteHelper.OFFER_TYPE_REGULAR;
        pInfo.globalPackageLimits = new List<BillingWrappers.GlobalPackageLimits> {packageLimit};
        pInfo.permissions = null;

        return new List<BillingWrappers.QuotePackageInfo> {pInfo};
    }

    private static BillingHttpRequestMock buildMock() {
        BillingHttpRequestMock.MockInfo contractsMock = new BillingHttpRequestMock.MockInfo(
            JSON.serialize(buildActiveBillingContracts())
        );
        BillingHttpRequestMock.MockInfo ngbsAccountMock = new BillingHttpRequestMock.MockInfo(
            JSON.serialize(buildBillingAccountPackage())
        );

        BillingHttpRequestMock mock = new BillingHttpRequestMock();
        mock.endpointToBodyMap.put('/contract', contractsMock);
        mock.endpointToBodyMap.put(ACCOUNT_SUMMARY_ENDPOINT, ngbsAccountMock);
        return mock;
    }
}