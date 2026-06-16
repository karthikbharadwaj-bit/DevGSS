@IsTest
private class Test_AccInfo {
    private static final String UNEXPECTED_BOOLEAN_ASSERT_MSG = 'Unexpected Boolean value was returned when passing an Account with no Package__c records.';

    private static final String ACCOUNT_ACQUISITION_TIER = 'att officehand';
    private static final String PACKAGE_NAME = 'Test Package';
    private static final String PACKAGE_ID = '112233445566';

    // Test banner content which display information about most recent completed EL
    @IsTest
    private static void testRecentEngageLegal() {
        Triggers.switchOff();
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        Account.Name => 'testAcc'
                    }
                )
                .create()
                .getRecord();
        Contact contact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.FirstName => 'Test1',
                    Contact.LastName => 'Test1',
                    Contact.AccountId => acc.Id,
                    Contact.Email => 'something@mostcommon.fake',
                    Contact.Phone => '1234567890',
                    Contact.Preferred_Language__c => 'en_US'
                }
            )
            .create()
            .getRecord();

        Product2 p2 = (Product2) new SObjectBuilder(Product2.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Product2.Name => 'Connect Pro - Annual Fee',
                    Product2.IsActive => true,
                    Product2.GOA_Group__c => 'DEVICES_B_STOCK',
                    Product2.Family => 'RingCentral'
                }
            )
            .create()
            .getRecord();

        Opportunity oppty = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.Name => 'Test Opportunity 2016',
                    Opportunity.Type => 'Syndicated - New',
                    Opportunity.StageName => 'Planning',
                    Opportunity.CloseDate => system.today().addMonths(1),
                    Opportunity.AccountId => acc.Id,
                    Opportunity.Primary_Opportunity_Contact__c => contact.Id
                    }
                )
                .create()
                .getRecord();
        Triggers.switchOn();
        Test.startTest();
        Quote q = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Quote.Name => 'quotetest',
                    Quote.OpportunityId => oppty.Id,
                    Quote.Total_Number_of_Digital_Lines__c => 10,
                    Quote.Account__c => oppty.AccountId,
                    Quote.Pricebook2Id => Test.getStandardPriceBookId()
                }
            )
            .create()
            .getRecord();

        Approval__c engageLegal = (Approval__c) new SObjectBuilder(Approval__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Approval__c.Quote__c => q.Id,
                    Approval__c.Opportunity__c => q.OpportunityId,
                    Approval__c.Type__c => ApprovalHelperCls.LEGAL_REQUEST_TYPE_AMENDMENT,
                    Approval__c.Account__c => q.Account__c,
                    Approval__c.RecordTypeId => ApprovalHelperCls.RT_ID_ENGAGE_LEGAL
                }
            )
            .create()
            .getRecord();

        Opportunity opportunity = [SELECT AccountId FROM Opportunity WHERE Id = :engageLegal.Opportunity__c];
		Test.stopTest();

        Account account = [SELECT Id FROM Account WHERE Id = :opportunity.AccountId];

        engageLegal.Status__c = 'Completed';
        engageLegal.Account__c = account.Id;
        engageLegal.SLA__c = 'Other';
        engageLegal.Elasticity__c = 'Elasticity - 10% - 12 mos';
        update engageLegal;

        PageReference pageRef = Page.AccountPop;
        Test.setCurrentPage(pageRef);
        ApexPages.StandardController sc = new ApexPages.StandardController(account);

        AccInfo testAccInfo = new AccInfo(sc);

        System.assertEquals(false, testAccInfo.isELBannerEmpty);
        System.assertEquals('Other', testAccInfo.completedEngageLegal.sla);
        System.assertEquals('Elasticity - 10% - 12 mos', testAccInfo.completedEngageLegal.elasticity);
    }

    // Test banner content for O@H Accounts...
    @IsTest
    private static void testAccInfo() {
        Account testAccount = createAccWithPackage();
        createAccountData(testAccount);

        PageReference pageRef = Page.AccountPop;
        Test.setCurrentPage(pageRef);
        ApexPages.StandardController sc = new ApexPages.StandardController(testAccount);
        AccInfo testAccInfo = new AccInfo(sc);
        testAccInfo.PopulateATM();



        assertAccInfo(testAccInfo);
        Assert.isTrue(
            testAccInfo.IsInMigrationToAcquistionTier,
            'IsInMigrationToAcquistionTier must be set if the given Account has Package__c records with needed Acquisition_Tier__c values.'
        );
    }

    @isTest
    static void testBannerContentWhenAccHasNoPackage() {
        Account testAccount = createAcc(true);
        createAccountData(testAccount);

        PageReference pageRef = Page.AccountPop;
        Test.setCurrentPage(pageRef);
        ApexPages.StandardController sc = new ApexPages.StandardController(testAccount);
        Test.startTest();
            AccInfo testAccInfo = new AccInfo(sc);
            testAccInfo.PopulateATM();
        Test.stopTest();

        assertAccInfo(testAccInfo);
        Assert.isNull(testAccInfo.IsInMigrationToAcquistionTier, 'IsInMigrationToAcquistionTier must not be set if the given Account has no Package__c records.');
    }

    @isTest
    static void testBannerContentWhenAccHasNoPackageWithExpectedAcquisition() {
        Package__c packageToInsert = (Package__c) new SObjectBuilder(Package__c.sObjectType)
            .setFields(new Map<SObjectField, Object> {
                Package__c.Name => PACKAGE_NAME,
                Package__c.Account_Package_Id__c => PACKAGE_ID
            })
            .build()
            .getRecord();
        Account testAccount = createAccWithPackage(packageToInsert);
        createAccountData(testAccount);

        PageReference pageRef = Page.AccountPop;
        Test.setCurrentPage(pageRef);
        ApexPages.StandardController sc = new ApexPages.StandardController(testAccount);
        Test.startTest();
            AccInfo testAccInfo = new AccInfo(sc);
            testAccInfo.PopulateATM();
        Test.stopTest();

        assertAccInfo(testAccInfo);
        Assert.isNull(
            testAccInfo.IsInMigrationToAcquistionTier,
            'IsInMigrationToAcquistionTier must not be set if the given Account has no Package__c records with needed Acquisition_Tier__c values.'
        );
    }

    @IsTest
    private static void testAccInfo3() {
        Account testAccount = createAccWithPackage();
        Account parentAccount = new Account(Name = 'testing');
        insert parentAccount;

        testAccount.ParentId = parentAccount.Id;
        testAccount.ELA_Account_Type__c = AccountHelper.ACCOUNT_TYPE_ELA_BILLING;
        update testAccount;

        PageReference pageRef = Page.AccountPop;
        Test.setCurrentPage(pageRef);
        ApexPages.StandardController sc = new ApexPages.StandardController(testAccount);
        AccInfo testAccInfo = new AccInfo(sc);

        System.assertEquals(true, testAccInfo.warn10);
    }

    @isTest
    private static void testDuplicateAccountSection() {
        Account accToFind = createAcc(false);
        accToFind.Name = 'You will find me';
        accToFind.Partner_ID__c = '1234';
        insert accToFind;

        Account accForCtrl = createAcc(false);
        accForCtrl.FoundDuplicateAccountIds__c = accToFind.Id;
        accForCtrl.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner Account').getRecordTypeId();
        accForCtrl.RC_User_ID__c = '4321';
        insert accForCtrl;

        PageReference pageRef = Page.AccountPop;
        Test.setCurrentPage(pageRef);
        ApexPages.StandardController ctrl = new ApexPages.StandardController(accForCtrl);
        AccInfo accInfoExCtrl = new AccInfo(ctrl);

        System.assert(accInfoExCtrl.DuplicatePartnerAccounts != null, 'Unexpected null value');
        System.assertEquals(1, accInfoExCtrl.DuplicatePartnerAccounts.size(), 'Should contains one record of Account object');
    }

    //Test banner for Fujitsu - House Account
    @isTest
    private static void testFujitsuParentAccount() {
        Account fujitsuParent = createAcc(false);
        fujitsuParent.Name = 'Fujitsu - House Account';
        insert fujitsuParent;

        system.debug('fujitsuParent--->'+fujitsuParent);
        system.debug('fujitsuParentid--->'+fujitsuParent.id);
        Account fujitsuChild = createAcc(false);
        fujitsuChild.Parent = fujitsuParent;
        fujitsuChild.Parentid = fujitsuParent.Id;
        fujitsuChild.Name = 'Fujitsu - Child Account';
        fujitsuChild.RC_User_ID__c = '4357575';
        insert fujitsuChild;

        PageReference pageRef = Page.AccountPop;
        Test.setCurrentPage(pageRef);
        ApexPages.StandardController ctrl = new ApexPages.StandardController(fujitsuChild);
        AccInfo accInfoExCtrl = new AccInfo(ctrl);

        System.assertEquals(true, accInfoExCtrl.isFujitsuBrand, 'Parent is Fujitsu - House Account');
    }

    private static Account createAccWithPackage() {
        Package__c packageToInsert = (Package__c) new SObjectBuilder(Package__c.sObjectType)
            .setFields(new Map<SObjectField, Object> {
                Package__c.Name => PACKAGE_NAME,
                Package__c.Account_Package_Id__c => PACKAGE_ID,
                Package__c.Acquisition_Tier__c => ACCOUNT_ACQUISITION_TIER
            })
            .build()
            .getRecord();
        return createAccWithPackage(packageToInsert);
    }
    private static Account createAccWithPackage(Package__c packageToInsert) {
        Account testAcc = createAcc(true);
        packageToInsert.Account__c = testAcc.Id;
        Triggers.switchOff();
        insert packageToInsert;
        Triggers.switchOn();
        return testAcc;
    }

    private static Account createAcc(Boolean insertAccount) {
        Account testAccount = new Account();
        testAccount.Name = 'First Group America Test Account';
        testAccount.Account_Highlights_Message__c = 'Highlights Message';
        testAccount.RC_User_ID__c = 'UserId';
        testAccount.RC_Brand__c = 'RINGCENTRAL OFFICE@HAND FROM AT&T';
        testAccount.RC_Account_Status__c = 'Trial';
        testAccount.RC_Service_name__c = 'AT&T Office@Hand';
        testAccount.InContact_Service__c = 'Contact Center Basic';
        testAccount.No_of_InContact_Seats__c = 5;
        testAccount.Acquisition_Tier__c = ACCOUNT_ACQUISITION_TIER;
        testAccount.RC_Attribution_L2__c = 'AT&t migration';
        testAccount.RC_Tier__c  = 'RBS_RCO';
        testAccount.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner Account').getRecordTypeId();
        testAccount.Partner_Type__c = 'Franchisor';
        testAccount.MRR__c = 0;
        testAccount.RC_SignUp_date__c = System.today() + 7 ;
        testAccount.Partner_ID__c = '105267001';

        if (insertAccount) {
            insert testAccount;
        }

        return testAccount;
    }

    private static void createAccountContactRole(Id accId) {

        Contact testContact = new Contact();
        testContact.LastName = 'testContact';
        testContact.AccountId = accId;
        testContact.Email = 'test@test.com';
        testContact.Phone = '1234567890';
        insert testContact;

        AccountContactRole testAccountContactRole = new AccountContactRole();
        testAccountContactRole.AccountId = accId;
        testAccountContactRole.ContactId = testContact.Id;
        testAccountContactRole.IsPrimary = true;
        insert testAccountContactRole;
    }

    private static void createAccountTeamMember(Id accId) {

        AccountTeamMember testAccountTeamMember = new AccountTeamMember();
        testAccountTeamMember.AccountId = accId;
        testAccountTeamMember.TeamMemberRole = 'Technical Account Manager - Primary';
        testAccountTeamMember.UserId = UserInfo.getUserId();
        insert testAccountTeamMember;
    }

    private static void createDoc() {

        try {
            Folder folder = [SELECT Id FROM Folder WHERE Name = 'Lead Routing' LIMIT 1];
            Document testDocument = new Document();
            testDocument.FolderId = folder.Id;
            testDocument.Name = 'Account_Highlighter';
            testDocument.body = Blob.valueOf('Name, ContactName, ExecContactName, UserId');
            insert testDocument;
        } catch (QueryException ex) {}
    }

    private static void createStepUp(Id approvalId) {

        Step_Up__c stepUp = new Step_Up__c(
            Name = 'Testing',
            Step_Up_DLs__c = 10,
            Step_Up_Date__c = system.today() + 7,
            Engage_Legal_Record__c = approvalId
        );
        insert stepUp;
    }

    private static void createAccountData(Account testAccount) {
        createAccountContactRole(testAccount.Id);
        createAccountTeamMember(testAccount.Id);
        createDoc();
    }

    private static void assertAccInfo(AccInfo accountInfo) {
        Assert.isTrue(accountInfo.isAccountMessage, UNEXPECTED_BOOLEAN_ASSERT_MSG);
        Assert.isFalse(accountInfo.isBTApproved, UNEXPECTED_BOOLEAN_ASSERT_MSG);
        Assert.isTrue(accountInfo.isATT, UNEXPECTED_BOOLEAN_ASSERT_MSG);
        Assert.isTrue(accountInfo.isFirstGroupAcc, UNEXPECTED_BOOLEAN_ASSERT_MSG);
        Assert.isTrue(accountInfo.warn4, UNEXPECTED_BOOLEAN_ASSERT_MSG);
        Assert.isTrue(accountInfo.warn5, UNEXPECTED_BOOLEAN_ASSERT_MSG);
        Assert.isTrue(accountInfo.warn7, UNEXPECTED_BOOLEAN_ASSERT_MSG);
        Assert.isTrue(accountInfo.warn8, UNEXPECTED_BOOLEAN_ASSERT_MSG);
        Assert.isFalse(accountInfo.warn9, UNEXPECTED_BOOLEAN_ASSERT_MSG);
        Assert.isTrue(accountInfo.IsInTransitionToRcDirect, UNEXPECTED_BOOLEAN_ASSERT_MSG);
    }

    @IsTest
    private static void testAccInfo2() {

        Account testAccount = createAccWithPackage();
        Account parentAccount = new Account(Name = 'testing');
        insert parentAccount;

        testAccount.ParentId = parentAccount.Id;
        update testAccount;
        createAccountData(testAccount);

        PageReference pageRef = Page.AccountPop;
        Test.setCurrentPage(pageRef);
        ApexPages.StandardController sc = new ApexPages.StandardController(testAccount);
        AccInfo testAccInfo = new AccInfo(sc);
        testAccInfo.PopulateATM();



        System.assertEquals(true, testAccInfo.isAccountMessage);
        System.assertEquals(false, testAccInfo.isBTApproved);
        System.assertEquals(true, testAccInfo.isATT);
        System.assertEquals(true, testAccInfo.isFirstGroupAcc);
        System.assertEquals(true, testAccInfo.warn4);
        System.assertEquals(true, testAccInfo.warn5);
        System.assertEquals(true, testAccInfo.warn7);
        System.assertEquals(true, testAccInfo.warn8);
        System.assertEquals(false, testAccInfo.warn9);
        System.assertEquals(true, testAccInfo.IsInTransitionToRcDirect);
        System.assertEquals(true, testAccInfo.IsInMigrationToAcquistionTier);
    }

     @IsTest
    private static void testRecentEngageLegal2() {
         Account acc = (Account) new SObjectBuilder(Account.SObjectType)
             .setFields(
                 new Map<SObjectField, Object>{
                     Account.Name => 'testAcc'
                 }
             )
             .create()
             .getRecord();
         Contact contact = (Contact) new SObjectBuilder(Contact.SObjectType)
             .setFields(
                 new Map<SObjectField, Object>{
                     Contact.FirstName => 'Test1',
                     Contact.LastName => 'Test1',
                     Contact.AccountId => acc.Id,
                     Contact.Email => 'something@mostcommon.fake',
                     Contact.Phone => '1234567890',
                     Contact.Preferred_Language__c => 'en_US'
                 }
             )
             .create()
             .getRecord();
         DateTime dateNow = System.now();
         Opportunity oppty = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
             .setFields(
                 new Map<SObjectField, Object>{
                     Opportunity.Name => 'Test Opportunity',
                     Opportunity.Type => 'Syndicated - New',
                     Opportunity.StageName => 'Planning',
                     Opportunity.CloseDate => Date.newinstance(dateNow.year(), dateNow.month(), dateNow.day()),
                     Opportunity.AccountId => acc.Id,
                     Opportunity.Primary_Opportunity_Contact__c => contact.Id
                 }
             )
             .create()
             .getRecord();
         PriceBook2 pB2 = (PriceBook2) new SObjectBuilder(PriceBook2.SObjectType)
             .setFields(
                 new Map<SObjectField, Object>{
                     PriceBook2.Name => 'Test Price Book',
                     PriceBook2.Description => 'Test Price Book Products',
                     PriceBook2.IsActive => true,
                     PriceBook2.Line_Range_Min__c => 5,
                     PriceBook2.Service__c => 'Office'
                 }
             )
             .create()
             .getRecord();
         Quote q = (Quote) new SObjectBuilder(Quote.SObjectType)
             .setFields(
                 new Map<SObjectField, Object>{
                     Quote.Name => 'quotetest',
                     Quote.OpportunityId => oppty.Id,
                     Quote.Total_Number_of_Digital_Lines__c => 10,
                     Quote.Account__c => oppty.AccountId,
                     Quote.ProServ_Sold_Date__c => System.now(),
                     Quote.Pricebook2Id => pB2.Id
                 }
             )
             .create()
             .getRecord();

         Test.startTest();
         Approval__c engageLegal = (Approval__c) new SObjectBuilder(Approval__c.SObjectType)
             .setFields(
                 new Map<SObjectField, Object>{
                     Approval__c.Name => 'test',
                     Approval__c.Quote__c => q.Id,
                     Approval__c.Opportunity__c => oppty.Id,
                     Approval__c.Account__c => oppty.AccountId,
                     Approval__c.Type__c => ApprovalHelperCls.LEGAL_REQUEST_TYPE_AMENDMENT,
                     Approval__c.RecordTypeId => ApprovalHelperCls.RT_ID_ENGAGE_LEGAL
                 }
             )
             .create()
             .getRecord();

        createStepUp(engageLegal.Id);
        Opportunity opportunity = [SELECT AccountId FROM Opportunity WHERE Id = :engageLegal.Opportunity__c];
        Account account = [SELECT Id FROM Account WHERE Id = :opportunity.AccountId];
        account.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer Account').getRecordTypeId();
        update account;

        engageLegal.Status__c = 'Completed';
        engageLegal.Account__c = account.Id;
        engageLegal.SLA__c = 'Other';
        engageLegal.Elasticity__c = 'Elasticity - 10% - 12 mos';
        update engageLegal;

        PageReference pageRef = Page.AccountPop;
        Test.setCurrentPage(pageRef);
        ApexPages.StandardController sc = new ApexPages.StandardController(account);
        Test.stopTest();
        AccInfo testAccInfo = new AccInfo(sc);
        System.assertEquals(false, testAccInfo.isELBannerEmpty);
        System.assertEquals('Other', testAccInfo.completedEngageLegal.sla);
        System.assertEquals('Elasticity - 10% - 12 mos', testAccInfo.completedEngageLegal.elasticity);
    }

    @IsTest
    private static void testGPOWarningFlag() {
        Account testAccount = new Account();
        testAccount.Name = 'GPO Account';
		testAccount.GPA_Account__c = true;
		insert testAccount;

        PageReference pageRef = Page.AccountPop;
        Test.setCurrentPage(pageRef);
        ApexPages.StandardController sc = new ApexPages.StandardController(testAccount);
        AccInfo testAccInfo = new AccInfo(sc);

        Assert.areEqual(true, testAccInfo.isGPAAccount);
    }
}