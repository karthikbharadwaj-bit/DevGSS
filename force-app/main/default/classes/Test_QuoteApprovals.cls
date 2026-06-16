@isTest
private class Test_QuoteApprovals {
    public static final String DIRECTOR_BO_NAME = 'Jane Yang';
    public static final String TREASURE_MANAGER_NAME = 'Lin Wang';
    public static final String TREASURER_NAME = 'Teo Kridech';
    public static final String CONTROLLER_NAME = 'Vaibhav Agarwal';
    public static final String INVOICE_CONTROLLER ='Candice Barcela';

    @testSetup
    static void defaultSetup() {

        createCustomSetting();

        List<User> userList = new List<User>();

        Id adminProfileId = ProfileHelper.PROFILE_ID_SYSADMIN;

        // create users
        User svpWWSUsr = createUser('sWWS', adminProfileId, null, UserHelper.SVP_WWS_ROLE, false);
        userList.add(svpWWSUsr);

        User svpWWSDirectsUsr = createUser('sWDr', adminProfileId, null, UserHelper.SVP_WWS_DIRECTS_ROLE, false);
        userList.add(svpWWSDirectsUsr);

        User segmentLeagerUsr = createUser('sLdr', adminProfileId, null, UserHelper.SEGMENT_LEADER_ROLE, false);
        userList.add(segmentLeagerUsr);

        User directManagerUsr = createUser('dMan', adminProfileId, null, UserHelper.DIRECT_MANAGER_ROLE, false);
        userList.add(directManagerUsr);

        User salesRepUsr = createUser('sRep', adminProfileId, null, UserHelper.SALES_REP_ROLE, false);
        userList.add(salesRepUsr);

        User salesRepUsrWithSegment = createUser(
            'rSeg',
            adminProfileId,
            null,
            UserHelper.SALES_REP_ROLE,
            UserHelper.SEGMENT_SOHO,
            false
        );
        userList.add(salesRepUsrWithSegment);


        User testUserManagerUsr = createUser('mngr', adminProfileId, null, UserHelper.SEGMENT_LEADER_ROLE, false);
        userList.add(testUserManagerUsr);

        User testUsr = createUser('test', adminProfileId, null, null, false);
        userList.add(testUsr);

        User specialUsr = createUser('spec', adminProfileId, null, null, false);
        userList.add(specialUsr);

        insert userList;

        // set managers
        salesRepUsr.ManagerId = directManagerUsr.Id;
        salesRepUsrWithSegment.ManagerId = directManagerUsr.Id;
        directManagerUsr.ManagerId = segmentLeagerUsr.Id;
        segmentLeagerUsr.ManagerId = svpWWSDirectsUsr.Id;
        svpWWSDirectsUsr.ManagerId = svpWWSUsr.Id;

        testUsr.ManagerId = testUserManagerUsr.Id;

        update userList;

        System.runAs(testUsr) {
            createQueue(userList.get(0).Id);
        }
    }

    private static void createQueue(Id userId) {
        Group DefaultApproversQueue = (Group) new GroupSelector()
            .selectQueueByName(GroupHelper.DEFAULT_APPROVERS_QUEUE)
            .executeQuery()
            .get(0);

        insert new GroupMember(UserOrGroupId = userId, GroupId = DefaultApproversQueue.Id);
    }

    private static void createCustomSetting() {
        RingCentralVariousSettings__c rcvs = RingCentralVariousSettings__c.getOrgDefaults();
        rcvs.SVP_WWS_User_ID__c = HardcodedIdsMapper.getMatchedObjectId('0058000000371o2');
        upsert rcvs RingCentralVariousSettings__c.Id;

        new SObjectBuilder(NGBS_Phoenix_Settings__c.sObjectType)
            .setField(NGBS_Phoenix_Settings__c.NGBSPhoenixAvailablePackageIDs__c, '666;210;260;220;230;231;240;241;250;251;510;')
            .setField(NGBS_Phoenix_Settings__c.NGBSPhoenixAvailableBrands__c, 'RingCentral;RingCentral Canada;RingCentral AU;RingCentral UK;RingCentral EU;Unify Office')
            .setField(NGBS_Phoenix_Settings__c.NGBSPhoenixAvailableProducts__c, 'RC Meetings;Meetings;')
            .create();

    }

    private static User createUser(String name, Id profileId, Id managerId, String hierarchyRole) {
        return createUser(name, profileId, managerId, hierarchyRole, '', true);
    }

    private static User createUser(String name, Id profileId, Id managerId, String hierarchyRole, Boolean isNeedInsert) {
        return createUser(name, profileId, managerId, hierarchyRole, '', isNeedInsert);
    }

    private static User createUser(
        String name,
        Id profileId,
        Id managerId,
        String hierarchyRole,
        String segment,
        Boolean isNeedInsert
    ) {
        User user = new User(
            Username = createUserName(name),
            LastName = 'Test'+name,
            Email = name+'_user@gmail.com',
            Alias = 'test'+name,
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            SegmentPicklist__c = segment,
            Region__c = 'US',
            Sub_Region__c = 'All'
        );

        if(profileId != null) {
            user.ProfileId = profileId;
        }else{
            user.ProfileId = ProfileHelper.PROFILE_ID_SYSADMIN;
        }

        if(managerId != null) {
            user.ManagerId = managerId;
        }

        if(hierarchyRole != null) {
            user.Hierarchy_Role__c = hierarchyRole;
        }

        if(isNeedInsert) {
            insert user;
        }
        return user;
    }

    private static String createUserName(String namePrefix) {
        if(namePrefix == null) {
            namePrefix = '';
        }
        return namePrefix + '!user@gmail.com';
    }

    @IsTest
    static void test_CC_FSC_Approvals_WithFinanceQueueApprover () {
        User testUser;
        User testUserManager;

        List<String> userNameList = new List<String>{
            createUserName('test'),
            createUserName('mngr')
        };

        for(User u : [select Id, LastName, Username, Hierarchy_Role__c, ManagerId, Email from User where UserName IN :userNameList]) {
            if(u.UserName == createUserName('test')) {
                testUser = u;
            }else if(u.UserName == createUserName('mngr')) {
                testUserManager = u;
            }
        }

		Group approversQueue = (Group) new GroupSelector()
            .selectQueueByName('Finance Approval Queue')
            .executeQuery()
            .get(0);

        insert new GroupMember(UserOrGroupId = testUserManager.Id, GroupId = approversQueue.Id);

        System.runAs(testUser) {
            upsert new RingCentralVariousSettings__c(
                CC_FSC_Approvers_Queues__c = 'Finance Approval Queue'
            );

            List<SpecialTermsApprovers_V2__c> goasList = new List<SpecialTermsApprovers_V2__c>();

            SpecialTermsApprovers_V2__c goaItem = new SpecialTermsApprovers_V2__c(
                Name = 'STACC001_Test',
                Initial_Term__c = '1-36',
                Last_Approver__c = 'Finance Approval Queue',
                Special_Terms__c = '3 Free Months of Service'
            );
            goasList.add(goaItem);
			insert goasList;

			Account testAccount = new Account(
                Name = 'Opty test account'
            );
            insert testAccount;

            Opportunity testOpp = new Opportunity(
                AccountId = testAccount.Id,
                Name = 'MyTestOpportunity',
                Type = 'Existing Business',
                CurrencyIsoCode = 'USD',
                StageName = '1. Qualify',
                Is_Billing_Opportunity__c = true
            );
            insert testOpp;

            Pricebook2 testPriceBook = new Pricebook2(
                Name = 'Test Price Book',
                Description ='Test Price Book Products',
                IsActive = true,
                Line_Range_Min__c = 5,
                Line_Range_Max__c = 10,
                CurrencyIsoCode = 'USD'
            );
            insert testPriceBook;

			List<Quote> quoteList = new List<Quote>();

            Quote testBillingQuote = new Quote(
                Name = 'testBillingQuote',
                OpportunityId = testOpp.Id,
                Pricebook2Id = testPriceBook.Id,
                RecordTypeId = QuoteHelper.RT_ID_BILLING,
                CurrencyIsoCode = 'USD'
            );
            quoteList.add(testBillingQuote);

            Quote testContactCenterQuote = new Quote(
                Name = 'testBillingQuote',
                OpportunityId = testOpp.Id,
                Pricebook2Id = testPriceBook.Id,
                RecordTypeId = QuoteHelper.RT_ID_CC,
                CurrencyIsoCode = 'USD'
            );
            quoteList.add(testContactCenterQuote);
            insert quoteList;

			Test.startTest();

				testContactCenterQuote.Initial_Term_months__c = '24';
				testContactCenterQuote.Special_Terms__c = '3 Free Months of Service';

				update testContactCenterQuote;

				Quote reselectedMainQuote = [SELECT Id, Approved_Status__c,
                        Approval_Type__c, Level_1_Approver__c,
                        Level_2_Approver__c, Level_3_Approver__c,
                        Level_4_Approver__c, Auto_Renewal__c
                    FROM Quote
                    WHERE Id = :testBillingQuote.Id];

				System.assert(QuoteHelper.APPROVAL_STATUS_REQUIRED == reselectedMainQuote.Approved_Status__c);
				System.assert(reselectedMainQuote.Level_1_Approver__c != null);

			Test.stopTest();

		}
	}


	@IsTest
	static void test_CC_FSC_Approvals_WithoutFinanceQueueApprover () {
		User testUser;
        User testUserManager;

        List<String> userNameList = new List<String>{
            createUserName('test'),
            createUserName('mngr')
        };

        for(User u : [select Id, LastName, Username, Hierarchy_Role__c, ManagerId, Email from User where UserName IN :userNameList]) {
            if(u.UserName == createUserName('test')) {
                testUser = u;
            }else if(u.UserName == createUserName('mngr')) {
                testUserManager = u;
            }
        }

		Group approversQueue = (Group) new GroupSelector()
            .selectQueueByName('Finance Approval Queue')
            .executeQuery()
            .get(0);

        insert new GroupMember(UserOrGroupId = testUserManager.Id, GroupId = approversQueue.Id);

        System.runAs(testUser) {
            upsert new RingCentralVariousSettings__c(
                CC_FSC_Approvers_Queues__c = 'Finance Approval Queue'
            );

            List<SpecialTermsApprovers_V2__c> goasList = new List<SpecialTermsApprovers_V2__c>();

            SpecialTermsApprovers_V2__c goaItem = new SpecialTermsApprovers_V2__c(
                Name = 'STACC001_Test',
                Initial_Term__c = '1-36',
                Last_Approver__c = 'Finance Approval Queue',
                Special_Terms__c = '3 Free Months of Service'
            );
            goasList.add(goaItem);
            insert goasList;

            Account testAccount = new Account(
                Name = 'Opty test account'
            );
            insert testAccount;

            Opportunity testOpp = new Opportunity(
                AccountId = testAccount.Id,
                Name = 'MyTestOpportunity',
                Type = 'Existing Business',
                CurrencyIsoCode = 'USD',
                StageName = '1. Qualify',
                Is_Billing_Opportunity__c = true
            );
            insert testOpp;

            Pricebook2 testPriceBook = new Pricebook2(
                Name = 'Test Price Book',
                Description ='Test Price Book Products',
                IsActive = true,
                Line_Range_Min__c = 5,
                Line_Range_Max__c = 10,
                CurrencyIsoCode = 'USD'
            );
            insert testPriceBook;

            List<Quote> quoteList = new List<Quote>();

            Quote testBillingQuote = new Quote(
                Name = 'testBillingQuote',
                OpportunityId = testOpp.Id,
                Pricebook2Id = testPriceBook.Id,
                RecordTypeId = QuoteHelper.RT_ID_BILLING,
                CurrencyIsoCode = 'USD'
            );
            quoteList.add(testBillingQuote);

            Quote testContactCenterQuote = new Quote(
                Name = 'testBillingQuote',
                OpportunityId = testOpp.Id,
                Pricebook2Id = testPriceBook.Id,
                RecordTypeId = QuoteHelper.RT_ID_CC,
                CurrencyIsoCode = 'USD'
            );
            quoteList.add(testContactCenterQuote);
            insert quoteList;

            Test.startTest();

                testContactCenterQuote.Initial_Term_months__c = '24';
                testContactCenterQuote.Special_Terms__c = '1 Free Months of Service';

                update testContactCenterQuote;

                Quote reselectedMainQuote = [SELECT Id, Approved_Status__c,
                        Approval_Type__c, Level_1_Approver__c,
                        Level_2_Approver__c, Level_3_Approver__c,
                        Level_4_Approver__c, Auto_Renewal__c
                    FROM Quote
                    WHERE Id = :testBillingQuote.Id];

                System.assert(QuoteHelper.APPROVAL_STATUSES_NOT_REQUIRED.contains(reselectedMainQuote.Approved_Status__c));
                System.assert(reselectedMainQuote.Level_1_Approver__c == null);

            Test.stopTest();

        }
    }

    @isTest
    static void test_QuoteApprovalsAndRangeClass() {

        User testUser = [select Id, LastName, Username, Hierarchy_Role__c, ManagerId, Email from User where UserName = :createUserName('test')];

        System.runAs(testUser) {

            QuoteApprovals.handleQuotes(null, null, null);

            QuoteApprovals.handleQuotes(new Set<Id>(), new Set<Id>(), null);

            QuoteApprovals.Range simpleRange = new QuoteApprovals.Range();
            System.assert(simpleRange.min == 0);
            System.assert(simpleRange.max == 0);
            System.assert(simpleRange.rangeName == '');

            QuoteApprovals.Range myRange = new QuoteApprovals.Range(1, 10);
            System.assert(myRange.min == 1);
            System.assert(myRange.max == 10);
            System.assert(myRange.rangeName == '');
            System.assert(myRange.isInRange(7) == true);
            System.assert(myRange.isInRange('7') == true);
            System.assert(myRange.isInRange(18) == false);
            System.assert(myRange.isInRange(-3) == false);

            QuoteApprovals.Range namedRange = new QuoteApprovals.Range(1, 3, 'MyTestRange');
            System.assert(namedRange.min == 1);
            System.assert(namedRange.max == 3);
            System.assert(namedRange.rangeName == 'MyTestRange');
            System.assert(namedRange.isInRange(2) == true);
            System.assert(namedRange.isInRange('2') == true);
            System.assert(namedRange.isInRange(18) == false);
            System.assert(namedRange.isInRange(-3) == false);

            QuoteApprovals.Range strRange = new QuoteApprovals.Range('1 - 12 ', '-', 'strRange');
            System.assert(strRange.min == 1);
            System.assert(strRange.max == 12);
            System.assert(strRange.rangeName == 'strRange');
            System.assert(strRange.isInRange(10) == true);
            System.assert(strRange.isInRange('10') == true);
            System.assert(strRange.isInRange(18) == false);
            System.assert(strRange.isInRange(-3) == false);
        }
    }

    @isTest
    static void test_handleQuote() {

        User testUser;
        User testUserManager;

        List<String> userNameList = new List<String>{
            createUserName('test'),
            createUserName('mngr')
        };

        List<User> users = (List<User>) new UserSelector()
            .selectUserByUsername(new List<Object>{ userNameList })
            .selectFields( new List<String>{
                'Id',
                'LastName',
                'Username',
                'Hierarchy_Role__c',
                'ManagerId',
                'Email',
                'SegmentPicklist__c'
            })
            .executeQuery();

        for(User u : users) {
            if (u.UserName == createUserName('test')) {
                testUser = u;
            } else if (u.UserName == createUserName('mngr')) {
                testUserManager = u;
            }
        }

        System.runAs(testUser) {

            new SObjectBuilder(GOA_V2__c.sObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        GOA_V2__c.Name => '1',
                        GOA_V2__c.Quantity_Range__c => '1-99',
                        GOA_V2__c.Contract_Initial_Term_Range__c => '',
                        GOA_V2__c.Sales_Rep__c => '0-0',
                        GOA_V2__c.Direct_Manager__c => '0.01-2.00',
                        GOA_V2__c.Segment_Leader__c => '2.01-3.00',
                        GOA_V2__c.SVP_WWS_Directs__c => '3.01-5.00',
                        GOA_V2__c.SVP_WWS__c => '5.01-99999999',
                        GOA_V2__c.Group__c => 'RC_Office_Standard_Monthly_Contract',
                        GOA_V2__c.Currency__c => 'USD'
                    }
                )
                .create();

            new SObjectBuilder(Products_taken_into_account_in_GOA__c.sObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        Products_taken_into_account_in_GOA__c.Name => 'test',
                        Products_taken_into_account_in_GOA__c.Quote_Record_Type__c => QuoteHelper.RT_NAME_SALES,
                        Products_taken_into_account_in_GOA__c.Sub_Categories__c => 'Main, Contact Center'
                    }
                )
                .create();

            Account testAccount = (Account) new SObjectBuilder(Account.sObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        Account.Name => 'Opty test account',
                        Account.Permitted_Brands__c => OpportunityHelper.BRAND_RINGCENTRAL
                    }
                )
                .create()
                .getRecord();

            Opportunity testOpp = (Opportunity) new SObjectBuilder(Opportunity.sObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        Opportunity.AccountId => testAccount.Id,
                        Opportunity.Name => 'MyTestOpportunity',
                        Opportunity.Type => OpportunityHelper.OPPORTUNITY_TYPE_EX_BUSINESS,
                        Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL,
                        Opportunity.Tier_Name__c => OpportunityHelper.TIER_OFFICE,
                        Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                        Opportunity.CloseDate => System.today(),
                        Opportunity.CurrencyIsoCode => 'USD'
                    }
                )
                .create()
                .getRecord();

            Pricebook2 testPriceBook = (Pricebook2) new SObjectBuilder(Pricebook2.sObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        Pricebook2.Name => 'Test Price Book',
                        Pricebook2.Description => 'Test Price Book Products',
                        Pricebook2.IsActive => true,
                        Pricebook2.Line_Range_Min__c => 5,
                        Pricebook2.Line_Range_Max__c => 10,
                        Pricebook2.CurrencyIsoCode => 'USD'
                    }
                )
                .create()
                .getRecord();

            Quote testSalesQuote = (Quote) new SObjectBuilder(Quote.sObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        Quote.Name => 'testSalesQuote',
                        Quote.Auto_Renewal__c => true,
                        Quote.OpportunityId => testOpp.Id,
                        Quote.Pricebook2Id => testPriceBook.Id,
                        Quote.RecordTypeId => QuoteHelper.RT_ID_SALES,
                        Quote.CurrencyIsoCode => 'USD'
                    }
                )
                .create()
                .getRecord();

            Product2 testProduct = (Product2) new SObjectBuilder(Product2.sObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        Product2.Name => 'test product',
                        Product2.IsActive => true,
                        Product2.Sub_Category__c => 'Main',
                        Product2.GOA_Group_V2__c => 'RC_Office_Standard_Monthly_Contract'
                    }
                )
                .create()
                .getRecord();

            PricebookEntry standartPricebookEntry = (PricebookEntry) new SObjectBuilder(PricebookEntry.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                        PricebookEntry.Product2Id => testProduct.Id,
                        PricebookEntry.UnitPrice => 200,
                        PricebookEntry.IsActive => true,
                        PricebookEntry.UseStandardPrice => false,
                        PricebookEntry.CurrencyIsoCode => 'USD'
                    }
                )
                .create()
                .getRecord();

            PricebookEntry currentPricebookEntry = (PricebookEntry) new SObjectBuilder(PricebookEntry.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        PricebookEntry.Pricebook2Id => testPriceBook.Id,
                        PricebookEntry.Product2Id => testProduct.Id,
                        PricebookEntry.UnitPrice => 200,
                        PricebookEntry.IsActive => true,
                        PricebookEntry.UseStandardPrice => false,
                        PricebookEntry.Per_Line__c => false,
                        PricebookEntry.CurrencyIsoCode => 'USD'
                    }
                )
                .create()
                .getRecord();

            Test.startTest();

                QuoteLineItem qli = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.SObjectType)
                    .setFields(
                        new Map<SObjectField, Object>{
                            QuoteLineItem.QuoteId => testSalesQuote.Id,
                            QuoteLineItem.Product2Id => currentPricebookEntry.Product2Id,
                            QuoteLineItem.Quantity => 1,
                            QuoteLineItem.UnitPrice => currentPricebookEntry.UnitPrice,
                            QuoteLineItem.Discount_number__c => 2.5,
                            QuoteLineItem.PricebookEntryId => currentPricebookEntry.Id
                        }
                    )
                    .create()
                    .getRecord();

                Quote reselectedSalesQuote = (Quote) new QuoteSelector()
                    .selectQuoteById(new List<Id>{ testSalesQuote.Id })
                    .selectFields( new List<String>{
                        'Id',
                        'Approved_Status__c',
                        'Approval_Type__c',
                        'Level_1_Approver__c',
                        'Level_2_Approver__c',
                        'Level_3_Approver__c',
                        'Level_4_Approver__c',
                        'Auto_Renewal__c'
                    })
                    .executeQuery()
                    .get(0);

                System.assert(reselectedSalesQuote.Approved_Status__c == QuoteHelper.APPROVAL_STATUS_REQUIRED);
                System.assert(reselectedSalesQuote.Approval_Type__c == UserHelper.SEGMENT_LEADER_ROLE);
                System.assert(reselectedSalesQuote.Level_1_Approver__c == testUserManager.Id);


                qli.Discount_number__c = 6;
                update qli;

            Test.stopTest();

            User defaultApprover = ApproversSearch.getDefaultApprover();

            Quote reselectedSalesQuote2 = (Quote) new QuoteSelector()
                .selectQuoteById(new List<Id>{ testSalesQuote.Id })
                .selectFields( new List<String>{
                    'Id',
                    'Approved_Status__c',
                    'Approval_Type__c',
                    'Level_1_Approver__c',
                    'Level_2_Approver__c',
                    'Level_3_Approver__c',
                    'Level_4_Approver__c',
                    'Auto_Renewal__c'
                })
                .executeQuery()
                .get(0);

            System.assert(reselectedSalesQuote2.Approved_Status__c == QuoteHelper.APPROVAL_STATUS_REQUIRED);
            System.assert(reselectedSalesQuote2.Approval_Type__c == UserHelper.SVP_WWS_ROLE);
            System.assert(reselectedSalesQuote2.Level_1_Approver__c == testUserManager.Id);
            System.assert(reselectedSalesQuote2.Level_2_Approver__c == defaultApprover.Id);
        }
    }

    @isTest
    static void test_handleQuote_onDeleteQLI() {

        User testUser;
        User testUserManager;

        List<String> userNameList = new List<String>{
            createUserName('test'),
            createUserName('mngr')
        };

        for(User u : [select Id, LastName, Username, Hierarchy_Role__c, ManagerId, Email from User where UserName IN :userNameList]) {
            if(u.UserName == createUserName('test')) {
                testUser = u;
            }else if(u.UserName == createUserName('mngr')) {
                testUserManager = u;
            }
        }

        System.runAs(testUser) {

            List<GOA_V2__c> goasList = new List<GOA_V2__c>();

            GOA_V2__c goaItem = new GOA_V2__c(
                Name = '1',
                Quantity_Range__c = '1-99',
                Contract_Initial_Term_Range__c = '',
                Sales_Rep__c = '0-0',
                Direct_Manager__c = '0.01-2.00',
                Segment_Leader__c = '2.01-3.00',
                SVP_WWS_Directs__c = '3.01-5.00',
                SVP_WWS__c = '5.01-99999999',
                Group__c = 'RC_Office_Standard_Monthly_Contract',
                Currency__c = 'USD'
            );
            goasList.add(goaItem);

            GOA_V2__c goaItem1 = new GOA_V2__c(
                Name = '2',
                Quantity_Range__c = '1-99',
                Contract_Initial_Term_Range__c = '',
                Sales_Rep__c = '0-0',
                Direct_Manager__c = '0.01-2.00',
                Segment_Leader__c = '2.01-3.00',
                SVP_WWS_Directs__c = '3.01-5.00',
                SVP_WWS__c = '5.01-99999999',
                Group__c = 'Device_Contract',
                Currency__c = 'USD'
            );
            goasList.add(goaItem1);

            insert goasList;

            insert new Products_taken_into_account_in_GOA__c(
                Name = 'test',
                Quote_Record_Type__c = 'Sales Quote',
                Sub_Categories__c = 'Main, Contact Center'
            );


            Account testAccount = new Account(
                Name = 'Opty test account',
                Permitted_Brands__c = 'RingCentral'
            );
            insert testAccount;

            Opportunity testOpp = new Opportunity(
                AccountId = testAccount.Id,
                Name = 'MyTestOpportunity',
                Type = 'Existing Business',
                Brand_Name__c = 'RingCentral',
                Tier_Name__c = 'Office',
                StageName = '1. Qualify',
                CloseDate = System.today(),
                CurrencyIsoCode = 'USD'
            );
            insert testOpp;

            Pricebook2 testPriceBook = new Pricebook2(
                Name = 'Test Price Book',
                Description ='Test Price Book Products',
                IsActive = true,
                Line_Range_Min__c = 5,
                Line_Range_Max__c = 10,
                CurrencyIsoCode = 'USD'
            );
            insert testPriceBook;

            Quote testSalesQuote = new Quote (
                Name = 'testSalesQuote',
                Auto_Renewal__c = true,
                OpportunityId = testOpp.Id,
                Pricebook2Id = testPriceBook.Id,
                RecordTypeId = QuoteHelper.RT_ID_SALES,
                CurrencyIsoCode = 'USD'
            );
            insert testSalesQuote;


            List<Product2> prodList = new List<Product2>();

            Product2 testProduct = new Product2(
                Name = 'test product',
                IsActive = true,
                Sub_Category__c = 'Main',
                GOA_Group_V2__c = 'RC_Office_Standard_Monthly_Contract'
            );
            prodList.add(testProduct);

            Product2 testProduct1 = new Product2(
                Name = 'test product1',
                IsActive = true,
                GOA_Group_V2__c = 'Device_Contract',
                Family = 'Discounted Phones',
                Feature__c = 11,
                Sub_Feature__c = 56,
                Sub_Category__c = 'Main',
                Charge_Term__c = 'One - Time'
            );
            prodList.add(testProduct1);
            insert prodList;


            List<PricebookEntry> pbeList = new List<PricebookEntry>();
            PricebookEntry pbe;

            for(Product2 item : prodList) {

                pbe = new PricebookEntry(
                    Pricebook2Id = Test.getStandardPricebookId(),
                    Product2Id = item.Id,
                    UnitPrice = 200,
                    IsActive = true,
                    UseStandardPrice = false,
                    CurrencyIsoCode = 'USD'
                );
                pbeList.add(pbe);

                pbe = new PricebookEntry(
                    Pricebook2Id = testPriceBook.Id,
                    Product2Id = item.Id,
                    UnitPrice = 200,
                    IsActive = true,
                    UseStandardPrice = false,
                    Per_Line__c = false,
                    CurrencyIsoCode = 'USD'
                );
                pbeList.add(pbe);
            }
            insert pbeList;

            Test.startTest();

            List<QuoteLineItem> qliList = new List<QuoteLineItem>();

            for(PricebookEntry item : pbeList) {

                if(item.PriceBook2Id == testSalesQuote.Pricebook2Id) {

                    QuoteLineItem qli = new QuoteLineItem(
                        QuoteId = testSalesQuote.Id,
                        Product2Id = item.Product2Id,
                        Quantity = 1,
                        UnitPrice = item.UnitPrice,
                        Discount_number__c = 0,
                        PricebookEntryId = item.Id
                    );
                    qliList.add(qli);
                }
            }

            // set discount for first product
            qliList[0].Discount_number__c = 2.5;

            insert qliList;

            Quote reselectedSalesQuote = [SELECT Id, Approved_Status__c,
                                        Approval_Type__c, Level_1_Approver__c,
                                        Level_2_Approver__c, Level_3_Approver__c,
                                        Level_4_Approver__c, Auto_Renewal__c
                                    FROM Quote
                                    WHERE Id = :testSalesQuote.Id];

            System.assert(reselectedSalesQuote.Approved_Status__c == QuoteHelper.APPROVAL_STATUS_REQUIRED);
            System.assert(reselectedSalesQuote.Approval_Type__c == UserHelper.SEGMENT_LEADER_ROLE);
            System.assert(reselectedSalesQuote.Level_1_Approver__c == testUserManager.Id);


                // delete product with discount
                delete qliList[0];

                Quote reselectedSalesQuote2 = [SELECT Id, Approved_Status__c,
                                                    Approval_Type__c, Level_1_Approver__c,
                                                    Level_2_Approver__c, Level_3_Approver__c,
                                                    Level_4_Approver__c, Auto_Renewal__c
                                                FROM Quote
                                                WHERE Id = :testSalesQuote.Id];

                System.assert(reselectedSalesQuote2.Approved_Status__c == QuoteHelper.APPROVAL_STATUS_APPROVED);

            Test.stopTest();
        }
    }

    @isTest
    static void test_handleQuote_onQLIUpdateWithSpecialTerms() {

        User testUser;
        User testUserManager;

        List<String> userNameList = new List<String>{
            createUserName('test'),
            createUserName('mngr')
        };

        for(User u : [select Id, LastName, Username, Hierarchy_Role__c, ManagerId, Email from User where UserName IN :userNameList]) {
            if(u.UserName == createUserName('test')) {
                testUser = u;
            }else if(u.UserName == createUserName('mngr')) {
                testUserManager = u;
            }
        }

        System.runAs(testUser) {

            List<GOA_V2__c> goasList = new List<GOA_V2__c>();

            GOA_V2__c goaItem = new GOA_V2__c(
                Name = '1',
                Quantity_Range__c = '1-99',
                Contract_Initial_Term_Range__c = '',
                Sales_Rep__c = '0-0',
                Direct_Manager__c = '0.01-2.00',
                Segment_Leader__c = '2.01-3.00',
                SVP_WWS_Directs__c = '3.01-5.00',
                SVP_WWS__c = '5.01-99999999',
                Group__c = 'RC_Office_Standard_Monthly_Contract',
                Currency__c = 'USD'
            );
            goasList.add(goaItem);

            insert goasList;

            insert new Products_taken_into_account_in_GOA__c(
                Name = 'test',
                Quote_Record_Type__c = 'Sales Quote',
                Sub_Categories__c = 'Main, Contact Center'
            );

            List<SpecialTermsApprovers_V2__c> specialTermsList = new List<SpecialTermsApprovers_V2__c>();

            SpecialTermsApprovers_V2__c specialTermsItem = new SpecialTermsApprovers_V2__c(
                Name = 'STA1',
                Special_Terms__c = '3 Free Weeks of Service',
                Plan__c = 'Monthly - Contract',
                Initial_Term__c = '12-60',
                Last_Approver__c = 'Segment Leader'
            );
            specialTermsList.add(specialTermsItem);
            insert specialTermsList;

            Triggers.switchOff();

            Account testAccount = new Account(
                Name = 'Opty test account',
                Permitted_Brands__c = 'RingCentral'
            );
            insert testAccount;

            Opportunity testOpp = new Opportunity(
                AccountId = testAccount.Id,
                Name = 'MyTestOpportunity',
                Type = 'Existing Business',
                Brand_Name__c = 'RingCentral',
                Tier_Name__c = 'Office',
                StageName = '1. Qualify',
                CloseDate = System.today(),
                CurrencyIsoCode = 'USD'
            );
            insert testOpp;

            Triggers.switchOn();

            Pricebook2 testPriceBook = new Pricebook2(
                Name = 'Test Price Book',
                Description ='Test Price Book Products',
                IsActive = true,
                Plan__c = 'Monthly - Contract',
                Line_Range_Min__c = 5,
                Line_Range_Max__c = 10,
                CurrencyIsoCode = 'USD'
            );
            insert testPriceBook;

            Test.startTest();

            Quote testSalesQuote = new Quote (
                Name = 'testSalesQuote',
                Auto_Renewal__c = true,
                OpportunityId = testOpp.Id,
                Special_Terms__c = '3 Free Weeks of Service',
                Initial_Term_months__c = '12',
                Pricebook2Id = testPriceBook.Id,
                RecordTypeId = QuoteHelper.RT_ID_SALES,
                CurrencyIsoCode = 'USD'
            );
            insert testSalesQuote;


            List<Product2> prodList = new List<Product2>();

            Product2 testProduct = new Product2(
                Name = 'test product',
                IsActive = true,
                GOA_Group_V2__c = 'RC_Office_Standard_Monthly_Contract',
                Sub_Category__c = 'Main'
            );
            prodList.add(testProduct);
            insert prodList;


            List<PricebookEntry> pbeList = new List<PricebookEntry>();
            PricebookEntry pbe;

            for(Product2 item : prodList) {

                pbe = new PricebookEntry(
                    Pricebook2Id = Test.getStandardPricebookId(),
                    Product2Id = item.Id,
                    UnitPrice = 200,
                    IsActive = true,
                    UseStandardPrice = false,
                    CurrencyIsoCode = 'USD'
                );
                pbeList.add(pbe);

                pbe = new PricebookEntry(
                    Pricebook2Id = testPriceBook.Id,
                    Product2Id = item.Id,
                    UnitPrice = 200,
                    IsActive = true,
                    UseStandardPrice = false,
                    Per_Line__c = false,
                    CurrencyIsoCode = 'USD'
                );
                pbeList.add(pbe);
            }
            insert pbeList;


            List<QuoteLineItem> qliList = new List<QuoteLineItem>();

            for(PricebookEntry item : pbeList) {

                if(item.PriceBook2Id == testSalesQuote.Pricebook2Id) {

                    QuoteLineItem qli = new QuoteLineItem(
                        QuoteId = testSalesQuote.Id,
                        Product2Id = item.Product2Id,
                        Quantity = 1,
                        UnitPrice = 200,
                        Discount_number__c = 2.5,
                        PricebookEntryId = item.Id
                    );
                    qliList.add(qli);
                }
            }
            OpportunityTotals.bypassOpportnuityUpdate = true;
                insert qliList;
            OpportunityTotals.bypassOpportnuityUpdate = false;
            Test.stopTest();
                Quote reselectedSalesQuote = [SELECT Id, Approved_Status__c,
                                            Approval_Type__c, Level_1_Approver__c,
                                            Level_2_Approver__c, Level_3_Approver__c,
                                            Level_4_Approver__c, Auto_Renewal__c, Special_Terms__c
                                        FROM Quote
                                        WHERE Id = :testSalesQuote.Id];

                System.assert(reselectedSalesQuote.Approved_Status__c == QuoteHelper.APPROVAL_STATUS_REQUIRED);
                System.assert(reselectedSalesQuote.Approval_Type__c == UserHelper.SEGMENT_LEADER_ROLE);
                System.assert(reselectedSalesQuote.Level_1_Approver__c == testUserManager.Id);

                // delete discount on qli
                for(QuoteLineItem item : qliList) {
                    item.Discount_number__c = 0;
                }
                update qliList;

                // delete special terms on quote
                reselectedSalesQuote.Special_Terms__c = null;
                update reselectedSalesQuote;

                Quote reselectedSalesQuote2 = [SELECT Id, Approved_Status__c,
                                            Approval_Type__c, Level_1_Approver__c,
                                            Level_2_Approver__c, Level_3_Approver__c,
                                            Level_4_Approver__c, Auto_Renewal__c, Special_Terms__c
                                        FROM Quote
                                        WHERE Id = :testSalesQuote.Id];

                System.assert(reselectedSalesQuote2.Approved_Status__c == QuoteHelper.APPROVAL_STATUS_APPROVED);
        }
    }

    @isTest
    static void test_handleQuote_onQLIUpdate_InitialDiscountInRange() {
        User specialUser;
        User salesRepUser;
        User directManager;
        User segmentLeager;
        User svpWWSDirects;
        User svpWWS;

        List<String> userNameList = new List<String>{
            createUserName('spec'),
            createUserName('sRep'),
            createUserName('dMan'),
            createUserName('sLdr'),
            createUserName('sWDr'),
            createUserName('sWWS')
        };

        for(User u : [select Id, LastName, Username, Hierarchy_Role__c, ManagerId, Email from User where UserName IN :userNameList]) {
            if(u.UserName == createUserName('spec')) {
                specialUser = u;
            }else if(u.UserName == createUserName('sRep')) {
                salesRepUser = u;
            }else if(u.UserName == createUserName('dMan')) {
                directManager = u;
            }else if(u.UserName == createUserName('sLdr')) {
                segmentLeager = u;
            }else if(u.UserName == createUserName('sWDr')) {
                svpWWSDirects = u;
            }else if(u.UserName == createUserName('sWWS')) {
                svpWWS = u;
            }
        }

        System.runAs(salesRepUser) {

            Test.startTest();

                Integer cooRangeMin = 6000;
                Integer cooRangeMax = 99999999;

                String cooRange = String.valueOf(cooRangeMin) + '-' + String.valueOf(cooRangeMax);

                insert new GOA_Initial_Discount__c(Name = 'GOA1', COO_Annual__c = cooRange, COO_Monthly__c = cooRange, Currency__c = 'USD');

                upsert new RingCentralVariousSettings__c(
                    CRO_User_ID__c = specialUser.Id,
                    SVP_WWS_User_ID__c = svpWWS.Id,
                    SetupOwnerId = salesRepUser.Id
                );

                List<GOA_V2__c> goasList = new List<GOA_V2__c>();

                GOA_V2__c goaItem = new GOA_V2__c(
                    Name = '1',
                    Quantity_Range__c = '500-999',
                    Contract_Initial_Term_Range__c = '',
                    Sales_Rep__c = '0-0',
                    Direct_Manager__c = '0.01-5.00',
                    Segment_Leader__c = '5.01-6.00',
                    SVP_WWS_Directs__c = '6.01-7.00',
                    SVP_WWS__c = '9-99999999',
                    Group__c = 'RC_Office_Premium_Monthly_Contract',
                    Currency__c = 'USD'
                );
                goasList.add(goaItem);

                insert goasList;

                insert new Products_taken_into_account_in_GOA__c(
                    Name = 'test',
                    Quote_Record_Type__c = 'Sales Quote',
                    Sub_Categories__c = 'Main, Contact Center'
                );

                Triggers.switchOff();
                Account testAccount = new Account(
                    Name = 'Opty test account',
                    Permitted_Brands__c = 'RingCentral'
                );
                insert testAccount;

                Opportunity testOpp = new Opportunity(
                    AccountId = testAccount.Id,
                    Name = 'MyTestOpportunity',
                    Type = 'Existing Business',
                    Brand_Name__c = 'RingCentral',
                    Tier_Name__c = 'Office',
                    StageName = '1. Qualify',
                    CloseDate = System.today(),
                    CurrencyIsoCode = 'USD'
                );
                insert testOpp;

                Pricebook2 testPriceBook = new Pricebook2(
                    Name = 'Test Price Book',
                    Description ='Test Price Book Products',
                    IsActive = true,
                    Plan__c = 'Monthly - Contract',
                    Line_Range_Min__c = 5,
                    Line_Range_Max__c = 10,
                    CurrencyIsoCode = 'USD'
                );
                insert testPriceBook;
                Triggers.switchOn();

                Quote testSalesQuote = new Quote (
                    Name = 'testSalesQuote',
                    Auto_Renewal__c = true,
                    OpportunityId = testOpp.Id,
                    Special_Terms__c = '3 Free Weeks of Service',
                    Pricebook2Id = testPriceBook.Id,
                    RecordTypeId = QuoteHelper.RT_ID_SALES,
                    CurrencyIsoCode = 'USD'
                );
                insert testSalesQuote;


                List<Product2> prodList = new List<Product2>();

                Product2 testProduct = new Product2(
                    Name = 'test product',
                    IsActive = true,
                    GOA_Group_V2__c = 'RC_Office_Premium_Monthly_Contract',
                    Sub_Category__c = 'Main',
                    Charge_Term__c = 'One - Time'
                );
                prodList.add(testProduct);
                insert prodList;


                List<PricebookEntry> pbeList = new List<PricebookEntry>();
                PricebookEntry pbe;

                for(Product2 item : prodList) {

                    pbe = new PricebookEntry(
                        Pricebook2Id = Test.getStandardPricebookId(),
                        Product2Id = item.Id,
                        UnitPrice = 200,
                        IsActive = true,
                        UseStandardPrice = false,
                        CurrencyIsoCode = 'USD'
                    );
                    pbeList.add(pbe);

                    pbe = new PricebookEntry(
                        Pricebook2Id = testPriceBook.Id,
                        Product2Id = item.Id,
                        UnitPrice = 200,
                        IsActive = true,
                        UseStandardPrice = false,
                        Per_Line__c = false,
                        CurrencyIsoCode = 'USD'
                    );
                    pbeList.add(pbe);
                }
                insert pbeList;

                List<QuoteLineItem> qliList = new List<QuoteLineItem>();

                for(PricebookEntry item : pbeList) {

                    if(item.PriceBook2Id == testSalesQuote.Pricebook2Id) {

                        QuoteLineItem qli = new QuoteLineItem(
                            QuoteId = testSalesQuote.Id,
                            Product2Id = item.Product2Id,
                            Quantity = 800,
                            UnitPrice = item.UnitPrice,
                            Discount_number__c = 55,
                            Discount_Type__c = 'Percentage',
                            PricebookEntryId = item.Id
                        );
                        qliList.add(qli);


                    }
                }

                insert qliList;

                Quote reselectedSalesQuote = [SELECT Id, Approved_Status__c, Initial_Discount_without_ProServ__c,
                                                    Approval_Type__c, Level_1_Approver__c,
                                                    Level_2_Approver__c, Level_3_Approver__c,
                                                    Level_4_Approver__c, Level_5_Approver__c,
                                                    Auto_Renewal__c, Special_Terms__c, SubTotal, Total_First_Year_Discount__c
                                                FROM Quote
                                                WHERE Id =: testSalesQuote.Id];


                System.assert(reselectedSalesQuote.Approved_Status__c == QuoteHelper.APPROVAL_STATUS_REQUIRED);
                System.assert(reselectedSalesQuote.Level_1_Approver__c == directManager.Id);
                System.assert(reselectedSalesQuote.Level_2_Approver__c == segmentLeager.Id);
                System.assert(reselectedSalesQuote.Level_3_Approver__c == svpWWSDirects.Id);


                Boolean initialDiscountInRange = (reselectedSalesQuote.Initial_Discount_without_ProServ__c >= cooRangeMin) &&
                    (reselectedSalesQuote.Initial_Discount_without_ProServ__c <= cooRangeMax) && (reselectedSalesQuote.Total_First_Year_Discount__c >= 0.5*(reselectedSalesQuote.subTotal));

                System.assert(initialDiscountInRange);

                //System.assertequals(reselectedSalesQuote.Level_4_Approver__c, svpWWS.Id);

            Test.stopTest();
        }
    }

    @isTest
    static void test_handleQuote_WithPercentageDiscount_CustomApproverList() {
        final String quotePackageInfo = '[{"id":"24","version":"1","packageInfo":{"catalogId":"24","version":"1"},'
            + '"productName":"Office","duration":"Monthly","edition":{"id":5,"name":"Premium"},'
            + '"offerType":"Regular","globalPackageLimits":[{"value":"50000","code":"MONTHLY_AMOUNT_LIMIT",'
            + '"name":"Monthly money amount limit","type":"Amount","scope":"BillingCycle","transactionType":"Any",'
            + '"target":"Global","exclusions":[{"target":"LicenseCategoryId","targetId":"AP"}],'
            + '"override":false}],"permissions":null}]';
        final String productGOA = '{"regular":"GOA_RC_Office","contracted":"GOA_RC_Office"}';

        User salesRepUsrWithSegment;
        User testUserManager;

        List<String> userNameList = new List<String>{
            createUserName('rSeg'),
            createUserName('mngr')
        };

        for(User u : [select Id, LastName, Username, Hierarchy_Role__c, ManagerId, Email, SegmentPicklist__c, Region__c, Sub_Region__c from User where UserName IN :userNameList]) {
            if(u.UserName == createUserName('rSeg')) {
                salesRepUsrWithSegment = u;
            }else if(u.UserName == createUserName('mngr')) {
                testUserManager = u;
            }
        }

        System.runAs(salesRepUsrWithSegment) {

            List<Custom_GOA__c> customApproversSettings = new List<Custom_GOA__c>();
            Custom_GOA__c cusItem = new Custom_GOA__c(
                Name = 'ACOUpsell_1',
                Opportunity_Brand__c = 'Avaya Cloud Office',
                Opportunity_Recordtype__c = 'VAR Opportunity',
                Opportunity_Owner_Segment__c = 'SOHO,Small Business,SMB',
                Opportunity_Owner_Region__c = 'US,CA',
                Opportunity_Owner_Subregion__c = 'ALL',
                L1_Approver__c = null,
                L2_Approver__c = null,
                L3_Approver__c = null,
                L4_Approver__c = null
            );
            customApproversSettings.add(cusItem);
            insert customApproversSettings;



            List<GOA_V2__c> goasList = new List<GOA_V2__c>();

            GOA_V2__c goaItem = new GOA_V2__c(
                Name = '1',
                Quantity_Range__c = '1-99999999',
                Brand__c = 'Avaya Cloud Office',
                Contract_Initial_Term_Range__c = '',
                Sales_Rep__c = '0-0',
                Direct_Manager__c = '0-0',
                Segment_Leader__c = '20.00001-35.00',
                SVP_WWS_Directs__c = '35.00001-50.00',
                SVP_WWS__c = '50.00001-100',
                Group__c = 'GOA_RC_Office',
                Currency__c = QuoteLineItemHelper.DISCOUNT_TYPE_PERCENTAGE
            );
            goasList.add(goaItem);

            insert goasList;

            insert new Products_taken_into_account_in_GOA__c(
                Name = 'test',
                Quote_Record_Type__c = 'Sales Quote',
                Sub_Categories__c = 'Main, Contact Center'
            );

            Account testAccount = new Account(
                Name = 'Opty test account',
                Permitted_Brands__c = 'RingCentral'
            );
            insert testAccount;

            Opportunity testOpp = new Opportunity(
                AccountId = testAccount.Id,
                Name = 'MyTestOpportunity',
                Type = 'Existing Business',
                Brand_Name__c = 'Avaya Cloud Office',
                Tier_Name__c = 'Office',
                StageName = '1. Qualify',
                CloseDate = System.today(),
                CurrencyIsoCode = 'USD',
                recordtypeId = OpportunityHelper.RT_ID_VAR_OPPORTUNITY
            );
            insert testOpp;

            Pricebook2 testPriceBook = new Pricebook2(
                Name = 'Test Price Book',
                Description ='Test Price Book Products',
                IsActive = true,
                Plan__c = 'Monthly - Contract',
                Line_Range_Min__c = 5,
                Line_Range_Max__c = 10,
                CurrencyIsoCode = 'USD'
            );
            insert testPriceBook;

            Quote testSalesQuote = new Quote (
                Name = 'testSalesQuote',
                Auto_Renewal__c = true,
                OpportunityId = testOpp.Id,
                Pricebook2Id = testPriceBook.Id,
                RecordTypeId = QuoteHelper.RT_ID_SALES,
                CurrencyIsoCode = 'USD',
                Package_Info__c = quotePackageInfo,
                Upsell_Status__c = 'Upsell'
            );
            insert testSalesQuote;


            List<Product2> prodList = new List<Product2>();

            Product2 testProduct = new Product2(
                Name = 'test product',
                IsActive = true,
                GOA_Group_V3__c = productGOA,
                Sub_Category__c = 'Main'
            );
            prodList.add(testProduct);
            insert prodList;


            List<PricebookEntry> pbeList = new List<PricebookEntry>();
            PricebookEntry pbe;

            for(Product2 item : prodList) {

                pbe = new PricebookEntry(
                    Pricebook2Id = Test.getStandardPricebookId(),
                    Product2Id = item.Id,
                    UnitPrice = 200,
                    IsActive = true,
                    UseStandardPrice = false,
                    CurrencyIsoCode = 'USD'
                );
                pbeList.add(pbe);

                pbe = new PricebookEntry(
                    Pricebook2Id = testPriceBook.Id,
                    Product2Id = item.Id,
                    UnitPrice = 200,
                    IsActive = true,
                    UseStandardPrice = false,
                    Per_Line__c = false,
                    CurrencyIsoCode = 'USD'
                );
                pbeList.add(pbe);
            }
            insert pbeList;


            List<QuoteLineItem> qliList = new List<QuoteLineItem>();

            for(PricebookEntry item : pbeList) {

                if(item.PriceBook2Id == testSalesQuote.Pricebook2Id) {

                    QuoteLineItem qli = new QuoteLineItem(
                        QuoteId = testSalesQuote.Id,
                        Product2Id = item.Product2Id,
                        Quantity = 1,
                        UnitPrice = item.UnitPrice,
                        Discount = 36,
                        Discount_type__c = QuoteLineItemHelper.DISCOUNT_TYPE_PERCENTAGE,
                        PricebookEntryId = item.Id
                    );
                    qliList.add(qli);
                }
            }

            Test.startTest();

                insert qliList;

                Quote reselectedSalesQuote = [SELECT Id, Approved_Status__c,
                                            Approval_Type__c, Level_1_Approver__c,
                                            Level_2_Approver__c, Level_3_Approver__c,
                                            Level_4_Approver__c,Level_5_Approver__c,
                                            Auto_Renewal__c, Special_Terms__c
                                        FROM Quote
                                        WHERE Id = :testSalesQuote.Id];

                System.assert(reselectedSalesQuote.Approved_Status__c == QuoteHelper.APPROVAL_STATUS_REQUIRED);

            Test.stopTest();
        }
    }


    @isTest
    static void test_handleQuote_WithPercentageDiscount_svpApproval() {
        final String quotePackageInfo = '[{"id":"24","version":"1","packageInfo":{"catalogId":"24","version":"1"},'
            + '"productName":"Office","duration":"Monthly","edition":{"id":5,"name":"Premium"},'
            + '"offerType":"Regular","globalPackageLimits":[{"value":"50000","code":"MONTHLY_AMOUNT_LIMIT",'
            + '"name":"Monthly money amount limit","type":"Amount","scope":"BillingCycle","transactionType":"Any",'
            + '"target":"Global","exclusions":[{"target":"LicenseCategoryId","targetId":"AP"}],'
            + '"override":false}],"permissions":null}]';
        final String productGOA = '{"regular":"GOA_RC_Office","contracted":"GOA_RC_Office"}';

        User testUser;
        User testUserManager;

        List<String> userNameList = new List<String>{
            createUserName('test'),
            createUserName('mngr')
        };

        for(User u : [select Id, LastName, Username, Hierarchy_Role__c, ManagerId, Email from User where UserName IN :userNameList]) {
            if(u.UserName == createUserName('test')) {
                testUser = u;
            }else if(u.UserName == createUserName('mngr')) {
                testUserManager = u;
            }
        }

        System.runAs(testUser) {

            List<GOA_V2__c> goasList = new List<GOA_V2__c>();

            GOA_V2__c goaItem = new GOA_V2__c(
                Name = '1',
                Quantity_Range__c = '1-99999999',
                Contract_Initial_Term_Range__c = '',
                Sales_Rep__c = '0-0',
                Direct_Manager__c = '.00001-20',
                Segment_Leader__c = '20.00001-35.00',
                SVP_WWS_Directs__c = '35.00001-50.00',
                SVP_WWS__c = '50.00001-100',
                Group__c = 'GOA_RC_Office',
                Currency__c = QuoteLineItemHelper.DISCOUNT_TYPE_PERCENTAGE
            );
            goasList.add(goaItem);

            insert goasList;

            insert new Products_taken_into_account_in_GOA__c(
                Name = 'test',
                Quote_Record_Type__c = 'Sales Quote',
                Sub_Categories__c = 'Main, Contact Center'
            );

            Account testAccount = new Account(
                Name = 'Opty test account',
                Permitted_Brands__c = 'RingCentral'
            );
            insert testAccount;

            Opportunity testOpp = new Opportunity(
                AccountId = testAccount.Id,
                Name = 'MyTestOpportunity',
                Type = 'Upsell',
                Brand_Name__c = 'RingCentral',
                Tier_Name__c = 'Office',
                StageName = '1. Qualify',
                CloseDate = System.today(),
                CurrencyIsoCode = 'USD'
            );
            insert testOpp;

            Pricebook2 testPriceBook = new Pricebook2(
                Name = 'Test Price Book',
                Description ='Test Price Book Products',
                IsActive = true,
                Plan__c = 'Monthly - Contract',
                Line_Range_Min__c = 5,
                Line_Range_Max__c = 10,
                CurrencyIsoCode = 'USD'
            );
            insert testPriceBook;

            Quote testSalesQuote = new Quote (
                Name = 'testSalesQuote',
                Auto_Renewal__c = true,
                OpportunityId = testOpp.Id,
                Pricebook2Id = testPriceBook.Id,
                RecordTypeId = QuoteHelper.RT_ID_SALES,
                CurrencyIsoCode = 'USD',
                Package_Info__c = quotePackageInfo
            );
            insert testSalesQuote;


            List<Product2> prodList = new List<Product2>();

            Product2 testProduct = new Product2(
                Name = 'test product',
                IsActive = true,
                GOA_Group_V3__c = productGOA,
                Sub_Category__c = 'Main'
            );
            prodList.add(testProduct);
            insert prodList;


            List<PricebookEntry> pbeList = new List<PricebookEntry>();
            PricebookEntry pbe;

            for(Product2 item : prodList) {

                pbe = new PricebookEntry(
                    Pricebook2Id = Test.getStandardPricebookId(),
                    Product2Id = item.Id,
                    UnitPrice = 200,
                    IsActive = true,
                    UseStandardPrice = false,
                    CurrencyIsoCode = 'USD'
                );
                pbeList.add(pbe);

                pbe = new PricebookEntry(
                    Pricebook2Id = testPriceBook.Id,
                    Product2Id = item.Id,
                    UnitPrice = 200,
                    IsActive = true,
                    UseStandardPrice = false,
                    Per_Line__c = false,
                    CurrencyIsoCode = 'USD'
                );
                pbeList.add(pbe);
            }
            insert pbeList;


            List<QuoteLineItem> qliList = new List<QuoteLineItem>();

            for(PricebookEntry item : pbeList) {

                if(item.PriceBook2Id == testSalesQuote.Pricebook2Id) {

                    QuoteLineItem qli = new QuoteLineItem(
                        QuoteId = testSalesQuote.Id,
                        Product2Id = item.Product2Id,
                        Quantity = 1,
                        UnitPrice = item.UnitPrice,
                        Discount = 65,
                        Discount_type__c = QuoteLineItemHelper.DISCOUNT_TYPE_PERCENTAGE,
                        PricebookEntryId = item.Id
                    );
                    qliList.add(qli);
                }
            }

            Test.startTest();

                insert qliList;

                Quote reselectedSalesQuote = [SELECT Id, Approved_Status__c,
                                            Approval_Type__c, Level_1_Approver__c,
                                            Level_2_Approver__c, Level_3_Approver__c,
                                            Level_4_Approver__c,Level_5_Approver__c,
                                            Auto_Renewal__c, Special_Terms__c
                                        FROM Quote
                                        WHERE Id = :testSalesQuote.Id];

                System.assert(reselectedSalesQuote.Approved_Status__c == QuoteHelper.APPROVAL_STATUS_REQUIRED);
                System.assert(reselectedSalesQuote.Level_1_Approver__c == testUserManager.Id);

            Test.stopTest();
        }
    }


    @isTest
    static void test_handleQuote_WithPercentageDiscount() {

        User testUser;
        User testUserManager;

        List<String> userNameList = new List<String>{
            createUserName('test'),
            createUserName('mngr')
        };

        for(User u : [select Id, LastName, Username, Hierarchy_Role__c, ManagerId, Email from User where UserName IN :userNameList]) {
            if(u.UserName == createUserName('test')) {
                testUser = u;
            }else if(u.UserName == createUserName('mngr')) {
                testUserManager = u;
            }
        }

        System.runAs(testUser) {

            List<GOA_V2__c> goasList = new List<GOA_V2__c>();

            GOA_V2__c goaItem = new GOA_V2__c(
                Name = '1',
                Quantity_Range__c = '1-99999999',
                Contract_Initial_Term_Range__c = '',
                Sales_Rep__c = '0-0',
                Direct_Manager__c = '0-0',
                Segment_Leader__c = '0.01-20.00',
                SVP_WWS_Directs__c = '20.01-100.00',
                SVP_WWS__c = '0-0',
                Group__c = 'ProServ_Directs',
                Currency__c = QuoteLineItemHelper.DISCOUNT_TYPE_PERCENTAGE
            );
            goasList.add(goaItem);

            insert goasList;

            insert new Products_taken_into_account_in_GOA__c(
                Name = 'test',
                Quote_Record_Type__c = 'Sales Quote',
                Sub_Categories__c = 'Main, Contact Center'
            );

            Account testAccount = new Account(
                Name = 'Opty test account',
                Permitted_Brands__c = 'RingCentral'
            );
            insert testAccount;

            Opportunity testOpp = new Opportunity(
                AccountId = testAccount.Id,
                Name = 'MyTestOpportunity',
                Type = 'Existing Business',
                Brand_Name__c = 'RingCentral',
                Tier_Name__c = 'Office',
                StageName = '1. Qualify',
                CloseDate = System.today(),
                CurrencyIsoCode = 'USD'
            );
            insert testOpp;

            Pricebook2 testPriceBook = new Pricebook2(
                Name = 'Test Price Book',
                Description ='Test Price Book Products',
                IsActive = true,
                Plan__c = 'Monthly - Contract',
                Line_Range_Min__c = 5,
                Line_Range_Max__c = 10,
                CurrencyIsoCode = 'USD'
            );
            insert testPriceBook;

            Quote testSalesQuote = new Quote (
                Name = 'testSalesQuote',
                Auto_Renewal__c = true,
                OpportunityId = testOpp.Id,
                Pricebook2Id = testPriceBook.Id,
                RecordTypeId = QuoteHelper.RT_ID_SALES,
                CurrencyIsoCode = 'USD'
            );
            insert testSalesQuote;


            List<Product2> prodList = new List<Product2>();

            Product2 testProduct = new Product2(
                Name = 'test product',
                IsActive = true,
                GOA_Group_V2__c = 'ProServ_Directs',
                Sub_Category__c = 'Main'
            );
            prodList.add(testProduct);
            insert prodList;


            List<PricebookEntry> pbeList = new List<PricebookEntry>();
            PricebookEntry pbe;

            for(Product2 item : prodList) {

                pbe = new PricebookEntry(
                    Pricebook2Id = Test.getStandardPricebookId(),
                    Product2Id = item.Id,
                    UnitPrice = 200,
                    IsActive = true,
                    UseStandardPrice = false,
                    CurrencyIsoCode = 'USD'
                );
                pbeList.add(pbe);

                pbe = new PricebookEntry(
                    Pricebook2Id = testPriceBook.Id,
                    Product2Id = item.Id,
                    UnitPrice = 200,
                    IsActive = true,
                    UseStandardPrice = false,
                    Per_Line__c = false,
                    CurrencyIsoCode = 'USD'
                );
                pbeList.add(pbe);
            }
            insert pbeList;


            List<QuoteLineItem> qliList = new List<QuoteLineItem>();

            for(PricebookEntry item : pbeList) {

                if(item.PriceBook2Id == testSalesQuote.Pricebook2Id) {

                    QuoteLineItem qli = new QuoteLineItem(
                        QuoteId = testSalesQuote.Id,
                        Product2Id = item.Product2Id,
                        Quantity = 1,
                        UnitPrice = item.UnitPrice,
                        Discount = 12.5,
                        Discount_type__c = QuoteLineItemHelper.DISCOUNT_TYPE_PERCENTAGE,
                        PricebookEntryId = item.Id
                    );
                    qliList.add(qli);
                }
            }

            Test.startTest();

                insert qliList;

                Quote reselectedSalesQuote = [SELECT Id, Approved_Status__c,
                                            Approval_Type__c, Level_1_Approver__c,
                                            Level_2_Approver__c, Level_3_Approver__c,
                                            Level_4_Approver__c, Auto_Renewal__c, Special_Terms__c
                                        FROM Quote
                                        WHERE Id = :testSalesQuote.Id];

                System.assert(reselectedSalesQuote.Approved_Status__c == QuoteHelper.APPROVAL_STATUS_REQUIRED);
                System.assert(reselectedSalesQuote.Approval_Type__c == UserHelper.SEGMENT_LEADER_ROLE);
                System.assert(reselectedSalesQuote.Level_1_Approver__c == testUserManager.Id);

            Test.stopTest();
        }
    }

    @isTest
    static void test_selectOnlyApplicableApprovers() {

        User testUser;
        User testUserManager;

        List<String> userNameList = new List<String>{
            createUserName('test'),
            createUserName('mngr')
        };

        for(User u : [select Id, LastName, Username, Hierarchy_Role__c, ManagerId, Email from User where UserName IN :userNameList]) {
            if(u.UserName == createUserName('test')) {
                testUser = u;
            }else if(u.UserName == createUserName('mngr')) {
                testUserManager = u;
            }
        }

        User operationsUser = createUser('oper', null, testUserManager.Id, 'Operations');

        testUser.managerId = operationsUser.Id;

        System.runAs(testUser) {

            List<GOA_V2__c> goasList = new List<GOA_V2__c>();

            GOA_V2__c goaItem = new GOA_V2__c(
                Name = '1',
                Quantity_Range__c = '0-999',
                Contract_Initial_Term_Range__c = '',
                Sales_Rep__c = '0-0',
                Direct_Manager__c = '0.01-5.00',
                Segment_Leader__c = '5.01-6.00',
                SVP_WWS_Directs__c = '6.01-7.00',
                SVP_WWS__c = '7.01-99999999',
                Group__c = 'RC_Office_Premium_Monthly_Contract',
                Currency__c = 'USD'
            );
            goasList.add(goaItem);

            insert goasList;

            insert new Products_taken_into_account_in_GOA__c(
                Name = 'test',
                Quote_Record_Type__c = 'Sales Quote',
                Sub_Categories__c = 'Main, Contact Center'
            );


            Account testAccount = new Account(
                Name = 'Opty test account',
                Permitted_Brands__c = 'RingCentral'
            );
            insert testAccount;

            Opportunity testOpp = new Opportunity(
                AccountId = testAccount.Id,
                Name = 'MyTestOpportunity',
                Type = 'Existing Business',
                Brand_Name__c = 'RingCentral',
                Tier_Name__c = 'Office',
                StageName = '1. Qualify',
                CloseDate = System.today(),
                CurrencyIsoCode = 'USD'
            );
            insert testOpp;

            Pricebook2 testPriceBook = new Pricebook2(
                Name = 'Test Price Book',
                Description ='Test Price Book Products',
                IsActive = true,
                Plan__c = 'Monthly - Contract',
                Line_Range_Min__c = 5,
                Line_Range_Max__c = 10,
                CurrencyIsoCode = 'USD'
            );
            insert testPriceBook;

            Quote testSalesQuote = new Quote (
                Name = 'testSalesQuote',
                Auto_Renewal__c = true,
                OpportunityId = testOpp.Id,
                Pricebook2Id = testPriceBook.Id,
                RecordTypeId = QuoteHelper.RT_ID_SALES,
                CurrencyIsoCode = 'USD'
            );
            insert testSalesQuote;


            List<Product2> prodList = new List<Product2>();

            Product2 testProduct = new Product2(
                Name = 'test product',
                IsActive = true,
                Sub_Category__c = 'Main',
                GOA_Group_V2__c = 'RC_Office_Premium_Monthly_Contract'
            );
            prodList.add(testProduct);
            insert prodList;


            List<PricebookEntry> pbeList = new List<PricebookEntry>();
            PricebookEntry pbe;

            for(Product2 item : prodList) {

                pbe = new PricebookEntry(
                    Pricebook2Id = Test.getStandardPricebookId(),
                    Product2Id = item.Id,
                    UnitPrice = 200,
                    IsActive = true,
                    UseStandardPrice = false,
                    CurrencyIsoCode = 'USD'
                );
                pbeList.add(pbe);

                pbe = new PricebookEntry(
                    Pricebook2Id = testPriceBook.Id,
                    Product2Id = item.Id,
                    UnitPrice = 200,
                    IsActive = true,
                    UseStandardPrice = false,
                    Per_Line__c = false,
                    CurrencyIsoCode = 'USD'
                );
                pbeList.add(pbe);
            }
            insert pbeList;


            List<QuoteLineItem> qliList = new List<QuoteLineItem>();

            for(PricebookEntry item : pbeList) {

                if(item.PriceBook2Id == testSalesQuote.Pricebook2Id) {

                    QuoteLineItem qli = new QuoteLineItem(
                        QuoteId = testSalesQuote.Id,
                        Product2Id = item.Product2Id,
                        Quantity = 1,
                        UnitPrice = item.UnitPrice,
                        Discount_number__c = 5.5,
                        PricebookEntryId = item.Id
                    );
                    qliList.add(qli);
                }
            }

            Test.startTest();

                insert qliList;

                Quote reselectedSalesQuote = [SELECT Id, Approved_Status__c,
                                            Approval_Type__c, Level_1_Approver__c,
                                            Level_2_Approver__c, Level_3_Approver__c,
                                            Level_4_Approver__c, Auto_Renewal__c, Special_Terms__c
                                        FROM Quote
                                        WHERE Id = :testSalesQuote.Id];

                System.assert(reselectedSalesQuote.Approved_Status__c == QuoteHelper.APPROVAL_STATUS_REQUIRED);
                System.assert(reselectedSalesQuote.Approval_Type__c == UserHelper.SEGMENT_LEADER_ROLE);
                System.assert(reselectedSalesQuote.Level_1_Approver__c == testUserManager.Id);

                System.assert(reselectedSalesQuote.Level_1_Approver__c != operationsUser.Id);
                System.assert(reselectedSalesQuote.Level_2_Approver__c != operationsUser.Id);
                System.assert(reselectedSalesQuote.Level_3_Approver__c != operationsUser.Id);
                System.assert(reselectedSalesQuote.Level_4_Approver__c != operationsUser.Id);

            Test.stopTest();
        }
    }


    @isTest
    static void test_virefyApproversSearchStartedFromOpportunityOwnerForSalesQuotes() {

        User testUser;
        User testUserManager;
        User salesRepUser;
        User directManager;
        User segmentLeager;
        User svpWWSDirects;
        User svpWWS;

        List<String> userNameList = new List<String>{
            createUserName('test'),
            createUserName('mngr'),
            createUserName('sRep'),
            createUserName('dMan'),
            createUserName('sLdr'),
            createUserName('sWDr'),
            createUserName('sWWS')
        };

        List<User> users = (List<User>) new UserSelector()
            .selectUserByUsername(new List<Object>{ userNameList })
            .selectFields( new List<String>{
                'Id',
                'LastName',
                'Username',
                'Hierarchy_Role__c',
                'ManagerId',
                'Email',
                'SegmentPicklist__c'
            })
            .executeQuery();

        for(User u : users) {
            if(u.UserName == createUserName('test')) {
                testUser = u;
            }else if(u.UserName == createUserName('mngr')) {
                testUserManager = u;
            }else if(u.UserName == createUserName('sRep')) {
                salesRepUser = u;
            }else if(u.UserName == createUserName('dMan')) {
                directManager = u;
            }else if(u.UserName == createUserName('sLdr')) {
                segmentLeager = u;
            }else if(u.UserName == createUserName('sWDr')) {
                svpWWSDirects = u;
            }else if(u.UserName == createUserName('sWWS')) {
                svpWWS = u;
            }
        }

        Quote testSalesQuote;
        PricebookEntry standartPricebookEntry;
        PricebookEntry currentPricebookEntry;

        System.runAs(salesRepUser) {

            new SObjectBuilder(GOA_V2__c.sObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        GOA_V2__c.Name => '1',
                        GOA_V2__c.Quantity_Range__c => '1-99',
                        GOA_V2__c.Contract_Initial_Term_Range__c => '',
                        GOA_V2__c.Sales_Rep__c => '0-0',
                        GOA_V2__c.Direct_Manager__c => '0.01-2.00',
                        GOA_V2__c.Segment_Leader__c => '2.01-3.00',
                        GOA_V2__c.SVP_WWS_Directs__c => '3.01-5.00',
                        GOA_V2__c.SVP_WWS__c => '5.01-99999999',
                        GOA_V2__c.Group__c => 'RC_Office_Standard_Monthly_Contract',
                        GOA_V2__c.Currency__c => 'USD'
                    }
                )
                .create();

            new SObjectBuilder(Products_taken_into_account_in_GOA__c.sObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        Products_taken_into_account_in_GOA__c.Name => 'test',
                        Products_taken_into_account_in_GOA__c.Quote_Record_Type__c => QuoteHelper.RT_NAME_SALES,
                        Products_taken_into_account_in_GOA__c.Sub_Categories__c => 'Main, Contact Center'
                    }
                )
                .create();

            Account testAccount = (Account) new SObjectBuilder(Account.sObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        Account.Name => 'Opty test account',
                        Account.Permitted_Brands__c => OpportunityHelper.BRAND_RINGCENTRAL
                    }
                )
                .create()
                .getRecord();

            Opportunity testOpp = (Opportunity) new SObjectBuilder(Opportunity.sObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        Opportunity.AccountId => testAccount.Id,
                        Opportunity.Name => 'MyTestOpportunity',
                        Opportunity.Type => OpportunityHelper.OPPORTUNITY_TYPE_EX_BUSINESS,
                        Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL,
                        Opportunity.Tier_Name__c => OpportunityHelper.TIER_OFFICE,
                        Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                        Opportunity.CloseDate => System.today(),
                        Opportunity.CurrencyIsoCode => 'USD'
                    }
                )
                .create()
                .getRecord();

            Pricebook2 testPriceBook = (Pricebook2) new SObjectBuilder(Pricebook2.sObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        Pricebook2.Name => 'Test Price Book',
                        Pricebook2.Description => 'Test Price Book Products',
                        Pricebook2.IsActive => true,
                        Pricebook2.Line_Range_Min__c => 5,
                        Pricebook2.Line_Range_Max__c => 10,
                        Pricebook2.CurrencyIsoCode => 'USD'
                    }
                )
                .create()
                .getRecord();

            testSalesQuote = (Quote) new SObjectBuilder(Quote.sObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        Quote.Name => 'testSalesQuote',
                        Quote.Auto_Renewal__c => true,
                        Quote.OpportunityId => testOpp.Id,
                        Quote.Pricebook2Id => testPriceBook.Id,
                        Quote.RecordTypeId => QuoteHelper.RT_ID_SALES,
                        Quote.CurrencyIsoCode => 'USD'
                    }
                )
                .create()
                .getRecord();


            Product2 testProduct = (Product2) new SObjectBuilder(Product2.sObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        Product2.Name => 'test product',
                        Product2.IsActive => true,
                        Product2.Sub_Category__c => 'Main',
                        Product2.GOA_Group_V2__c => 'RC_Office_Standard_Monthly_Contract'
                    }
                )
                .create()
                .getRecord();

            standartPricebookEntry = (PricebookEntry) new SObjectBuilder(PricebookEntry.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                        PricebookEntry.Product2Id => testProduct.Id,
                        PricebookEntry.UnitPrice => 200,
                        PricebookEntry.IsActive => true,
                        PricebookEntry.UseStandardPrice => false,
                        PricebookEntry.CurrencyIsoCode => 'USD'
                    }
                )
                .create()
                .getRecord();

            currentPricebookEntry = (PricebookEntry) new SObjectBuilder(PricebookEntry.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        PricebookEntry.Pricebook2Id => testPriceBook.Id,
                        PricebookEntry.Product2Id => testProduct.Id,
                        PricebookEntry.UnitPrice => 200,
                        PricebookEntry.IsActive => true,
                        PricebookEntry.UseStandardPrice => false,
                        PricebookEntry.Per_Line__c => false,
                        PricebookEntry.CurrencyIsoCode => 'USD'
                    }
                )
                .create()
                .getRecord();

        }

        System.runAs(testUser) {

            Test.startTest();

                QuoteLineItem qli = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.SObjectType)
                    .setFields(
                        new Map<SObjectField, Object>{
                            QuoteLineItem.QuoteId => testSalesQuote.Id,
                            QuoteLineItem.Product2Id => currentPricebookEntry.Product2Id,
                            QuoteLineItem.Quantity => 1,
                            QuoteLineItem.UnitPrice => currentPricebookEntry.UnitPrice,
                            QuoteLineItem.Discount_number__c => 2.5,
                            QuoteLineItem.PricebookEntryId => currentPricebookEntry.Id
                        }
                    )
                    .create()
                    .getRecord();

                Quote reselectedSalesQuote = (Quote) new QuoteSelector()
                    .selectQuoteById(new List<Id>{ testSalesQuote.Id })
                    .selectFields( new List<String>{
                        'Id',
                        'Approved_Status__c',
                        'Approval_Type__c',
                        'Level_1_Approver__c',
                        'Level_2_Approver__c',
                        'Level_3_Approver__c',
                        'Level_4_Approver__c',
                        'Auto_Renewal__c'
                    })
                    .executeQuery()
                    .get(0);

                System.assert(reselectedSalesQuote.Approved_Status__c == QuoteHelper.APPROVAL_STATUS_REQUIRED);
                System.assert(reselectedSalesQuote.Approval_Type__c == UserHelper.SEGMENT_LEADER_ROLE);
                System.assert(reselectedSalesQuote.Level_1_Approver__c == directManager.Id);
                System.assert(reselectedSalesQuote.Level_2_Approver__c == segmentLeager.Id);

                qli.Discount_number__c = 6;
                update qli;

            Test.stopTest();

            User defaultApprover = ApproversSearch.getDefaultApprover();

            Quote reselectedSalesQuote2 = (Quote) new QuoteSelector()
                .selectQuoteById(new List<Id>{ testSalesQuote.Id })
                .selectFields( new List<String>{
                    'Id',
                    'Approved_Status__c',
                    'Approval_Type__c',
                    'Level_1_Approver__c',
                    'Level_2_Approver__c',
                    'Level_3_Approver__c',
                    'Level_4_Approver__c',
                    'Auto_Renewal__c'
                })
                .executeQuery()
                .get(0);

            System.assert(reselectedSalesQuote2.Approved_Status__c == QuoteHelper.APPROVAL_STATUS_REQUIRED);
            System.assert(reselectedSalesQuote2.Approval_Type__c == UserHelper.SVP_WWS_ROLE);
            System.assert(reselectedSalesQuote2.Level_1_Approver__c == directManager.Id);
            System.assert(reselectedSalesQuote2.Level_2_Approver__c == segmentLeager.Id);
            System.assert(reselectedSalesQuote2.Level_3_Approver__c == svpWWSDirects.Id);
            System.assert(reselectedSalesQuote2.Level_4_Approver__c == svpWWS.Id);
        }
    }


    @isTest
    static void test_virefyApproversSearchStartedFromCurrentUserForNonSalesQuotes() {

        User testUser;
        User testUserManager;
        User salesRepUser;

        List<String> userNameList = new List<String>{
            createUserName('test'),
            createUserName('mngr'),
            createUserName('sRep')
        };

        List<User> users = (List<User>) new UserSelector()
            .selectUserByUsername(new List<Object>{ userNameList })
            .selectFields( new List<String>{
                'Id',
                'LastName',
                'Username',
                'Hierarchy_Role__c',
                'ManagerId',
                'Email',
                'SegmentPicklist__c'
            })
            .executeQuery();

        for(User u : users) {
            if(u.UserName == createUserName('test')) {
                testUser = u;
            }else if(u.UserName == createUserName('mngr')) {
                testUserManager = u;
            }else if(u.UserName == createUserName('sRep')) {
                salesRepUser = u;
            }
        }

        Quote testProServQuote;
        PricebookEntry standartPricebookEntry;
        PricebookEntry currentPricebookEntry;

        System.runAs(salesRepUser) {

            new SObjectBuilder(GOA_V2__c.sObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        GOA_V2__c.Name => '1',
                        GOA_V2__c.Quantity_Range__c => '1-99',
                        GOA_V2__c.Contract_Initial_Term_Range__c => '',
                        GOA_V2__c.Sales_Rep__c => '0-0',
                        GOA_V2__c.Direct_Manager__c => '0.01-2.00',
                        GOA_V2__c.Segment_Leader__c => '2.01-3.00',
                        GOA_V2__c.SVP_WWS_Directs__c => '3.01-5.00',
                        GOA_V2__c.SVP_WWS__c => '5.01-99999999',
                        GOA_V2__c.Group__c => 'RC_Office_Standard_Monthly_Contract',
                        GOA_V2__c.Currency__c => 'USD'
                    }
                )
                .create();

            new SObjectBuilder(Products_taken_into_account_in_GOA__c.sObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        Products_taken_into_account_in_GOA__c.Name => 'test',
                        Products_taken_into_account_in_GOA__c.Quote_Record_Type__c => 'ProServ Quote',
                        Products_taken_into_account_in_GOA__c.Sub_Categories__c => 'Professional Services'
                    }
                )
                .create();

            Map<String, Schema.RecordTypeInfo> quoteRTInfoByNameMap = Quote.sObjectType.getDescribe().getRecordTypeInfosByName();
            Id proservQuoteRtId = quoteRTInfoByNameMap.get('ProServ Quote').getRecordTypeId();


            Account testAccount = (Account) new SObjectBuilder(Account.sObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        Account.Name => 'Opty test account',
                        Account.Permitted_Brands__c => OpportunityHelper.BRAND_RINGCENTRAL
                    }
                )
                .create()
                .getRecord();

            Opportunity testOpp = (Opportunity) new SObjectBuilder(Opportunity.sObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        Opportunity.AccountId => testAccount.Id,
                        Opportunity.Name => 'MyTestOpportunity',
                        Opportunity.Type => OpportunityHelper.OPPORTUNITY_TYPE_EX_BUSINESS,
                        Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL,
                        Opportunity.Tier_Name__c => OpportunityHelper.TIER_OFFICE,
                        Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                        Opportunity.CloseDate => System.today(),
                        Opportunity.CurrencyIsoCode => 'USD'
                    }
                )
                .create()
                .getRecord();

            Pricebook2 testPriceBook = (Pricebook2) new SObjectBuilder(Pricebook2.sObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        Pricebook2.Name => 'Test Price Book',
                        Pricebook2.Description => 'Test Price Book Products',
                        Pricebook2.IsActive => true,
                        Pricebook2.Line_Range_Min__c => 5,
                        Pricebook2.Line_Range_Max__c => 10,
                        Pricebook2.CurrencyIsoCode => 'USD'
                    }
                )
                .create()
                .getRecord();

            testProServQuote = (Quote) new SObjectBuilder(Quote.sObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        Quote.Name => 'testProServQuote',
                        Quote.Auto_Renewal__c => true,
                        Quote.OpportunityId => testOpp.Id,
                        Quote.Pricebook2Id => testPriceBook.Id,
                        Quote.RecordTypeId => proservQuoteRtId,
                        Quote.CurrencyIsoCode => 'USD'
                    }
                )
                .create()
                .getRecord();

            List<Product2> prodList = new List<Product2>();

            Product2 testProduct = (Product2) new SObjectBuilder(Product2.sObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Product2.Name => 'test product',
                    Product2.IsActive => true,
                    Product2.Sub_Category__c => 'Professional Services',
                    Product2.GOA_Group_V2__c => 'RC_Office_Standard_Monthly_Contract'
                }
            )
            .create()
            .getRecord();

            standartPricebookEntry = (PricebookEntry) new SObjectBuilder(PricebookEntry.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                        PricebookEntry.Product2Id => testProduct.Id,
                        PricebookEntry.UnitPrice => 200,
                        PricebookEntry.IsActive => true,
                        PricebookEntry.UseStandardPrice => false,
                        PricebookEntry.CurrencyIsoCode => 'USD'
                    }
                )
                .create()
                .getRecord();

            currentPricebookEntry = (PricebookEntry) new SObjectBuilder(PricebookEntry.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        PricebookEntry.Pricebook2Id => testPriceBook.Id,
                        PricebookEntry.Product2Id => testProduct.Id,
                        PricebookEntry.UnitPrice => 200,
                        PricebookEntry.IsActive => true,
                        PricebookEntry.UseStandardPrice => false,
                        PricebookEntry.Per_Line__c => false,
                        PricebookEntry.CurrencyIsoCode => 'USD'
                    }
                )
                .create()
                .getRecord();

        }

        System.runAs(testUser) {

            Test.startTest();

                QuoteLineItem qli = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.SObjectType)
                    .setFields(
                        new Map<SObjectField, Object>{
                            QuoteLineItem.QuoteId => testProServQuote.Id,
                            QuoteLineItem.Product2Id => currentPricebookEntry.Product2Id,
                            QuoteLineItem.Quantity => 1,
                            QuoteLineItem.UnitPrice => currentPricebookEntry.UnitPrice,
                            QuoteLineItem.Discount_number__c => 2.5,
                            QuoteLineItem.PricebookEntryId => currentPricebookEntry.Id
                        }
                    )
                    .create()
                    .getRecord();

                Quote reselectedProServQuote = (Quote) new QuoteSelector()
                    .selectQuoteById(new List<Id>{ testProServQuote.Id })
                    .selectFields( new List<String>{
                        'Id',
                        'Approved_Status__c',
                        'Approval_Type__c',
                        'Level_1_Approver__c',
                        'Level_2_Approver__c',
                        'Level_3_Approver__c',
                        'Level_4_Approver__c',
                        'Auto_Renewal__c'
                    })
                    .executeQuery()
                    .get(0);

                System.assert(reselectedProServQuote.Approved_Status__c == QuoteHelper.APPROVAL_STATUS_REQUIRED);
                System.assert(reselectedProServQuote.Approval_Type__c == UserHelper.SEGMENT_LEADER_ROLE);
                System.assert(reselectedProServQuote.Level_1_Approver__c == testUserManager.Id);

                qli.Discount_number__c = 6;
                update qli;

            Test.stopTest();

            User defaultApprover = ApproversSearch.getDefaultApprover();

            Quote reselectedProServQuote2 = (Quote) new QuoteSelector()
                .selectQuoteById(new List<Id>{ testProServQuote.Id })
                .selectFields( new List<String>{
                    'Id',
                    'Approved_Status__c',
                    'Approval_Type__c',
                    'Level_1_Approver__c',
                    'Level_2_Approver__c',
                    'Level_3_Approver__c',
                    'Level_4_Approver__c',
                    'Auto_Renewal__c'
                })
                .executeQuery()
                .get(0);

            System.assert(reselectedProServQuote2.Approved_Status__c == QuoteHelper.APPROVAL_STATUS_REQUIRED);
            System.assert(reselectedProServQuote2.Approval_Type__c == UserHelper.SVP_WWS_ROLE);
            System.assert(reselectedProServQuote2.Level_1_Approver__c == testUserManager.Id);
            System.assert(reselectedProServQuote2.Level_2_Approver__c == defaultApprover.Id);
        }
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void test_deletingLastQLIShouldTriggerApproversSearch() {

        User testUser;
        User testUserManager;
        User salesRepUser;

        List<String> userNameList = new List<String>{
            createUserName('test'),
            createUserName('mngr'),
            createUserName('sRep')
        };

        for(User u : [select Id, LastName, Username, Hierarchy_Role__c, ManagerId, Email from User where UserName IN :userNameList]) {
            if(u.UserName == createUserName('test')) {
                testUser = u;
            }else if(u.UserName == createUserName('mngr')) {
                testUserManager = u;
            }else if(u.UserName == createUserName('sRep')) {
                salesRepUser = u;
            }
        }

        Quote testProServQuote;
        List<PricebookEntry> pbeList = new List<PricebookEntry>();

        Triggers.switchOff();

        System.runAs(salesRepUser) {

            List<GOA_V2__c> goasList = new List<GOA_V2__c>();

            GOA_V2__c goaItem = new GOA_V2__c(
                Name = '1',
                Quantity_Range__c = '1-99',
                Contract_Initial_Term_Range__c = '',
                Sales_Rep__c = '0-0',
                Direct_Manager__c = '0.01-2.00',
                Segment_Leader__c = '2.01-3.00',
                SVP_WWS_Directs__c = '3.01-5.00',
                SVP_WWS__c = '5.01-99999999',
                Group__c = 'RC_Office_Standard_Monthly_Contract',
                Currency__c = 'USD'
            );
            goasList.add(goaItem);

            insert goasList;

            insert new Products_taken_into_account_in_GOA__c(
                Name = 'test',
                Quote_Record_Type__c = 'ProServ Quote',
                Sub_Categories__c = 'Professional Services'
            );


            Map<String, Schema.RecordTypeInfo> quoteRTInfoByNameMap = Quote.sObjectType.getDescribe().getRecordTypeInfosByName();

            Id proservQuoteRtId = quoteRTInfoByNameMap.get('ProServ Quote').getRecordTypeId();

            Account testAccount = new Account(
                Name = 'Opty test account',
                Permitted_Brands__c = 'RingCentral'
            );
            insert testAccount;

            Opportunity testOpp = new Opportunity(
                AccountId = testAccount.Id,
                Name = 'MyTestOpportunity',
                Type = 'Existing Business',
                Brand_Name__c = 'RingCentral',
                Tier_Name__c = 'Office',
                StageName = '1. Qualify',
                CloseDate = System.today(),
                CurrencyIsoCode = 'USD'
            );
            insert testOpp;

            Pricebook2 testPriceBook = new Pricebook2(
                Name = 'Test Price Book',
                Description ='Test Price Book Products',
                IsActive = true,
                Line_Range_Min__c = 5,
                Line_Range_Max__c = 10,
                CurrencyIsoCode = 'USD'
            );
            insert testPriceBook;

            Triggers.switchOn();
            testProServQuote = new Quote (
                Name = 'testProServQuote',
                Auto_Renewal__c = true,
                OpportunityId = testOpp.Id,
                Pricebook2Id = testPriceBook.Id,
                RecordTypeId = proservQuoteRtId,
                CurrencyIsoCode = 'USD'
            );
            insert testProServQuote;


            List<Product2> prodList = new List<Product2>();

            Product2 testProduct = new Product2(
                Name = 'test product',
                IsActive = true,
                Sub_Category__c = 'Professional Services',
                GOA_Group_V2__c = 'RC_Office_Standard_Monthly_Contract'
            );
            prodList.add(testProduct);
            insert prodList;


            PricebookEntry pbe;

            for(Product2 item : prodList) {

                pbe = new PricebookEntry(
                    Pricebook2Id = Test.getStandardPricebookId(),
                    Product2Id = item.Id,
                    UnitPrice = 200,
                    IsActive = true,
                    UseStandardPrice = false,
                    CurrencyIsoCode = 'USD'
                );
                pbeList.add(pbe);

                pbe = new PricebookEntry(
                    Pricebook2Id = testPriceBook.Id,
                    Product2Id = item.Id,
                    UnitPrice = 200,
                    IsActive = true,
                    UseStandardPrice = false,
                    Per_Line__c = false,
                    CurrencyIsoCode = 'USD'
                );
                pbeList.add(pbe);
            }
            insert pbeList;
        }

        System.runAs(testUser) {
            Triggers.switchOff();
            Triggers.except(QuoteLineItemTriggerHelper.ManageQuotesMapStatic.class.toString());
            Triggers.except(QuoteLineItemTriggerHelper.UpdateQuoteOnQuoteLineItemUpdate.class.toString());
            Triggers.except(QuoteLineItemTriggerHelper.SetQuoteApprovalType.class.toString());
            Triggers.except(QuoteLineItemTriggerHelper.UpdateQuoteOnQuoteLineItemUpdate.class.toString());
            List<QuoteLineItem> qliList = new List<QuoteLineItem>();

            for(PricebookEntry item : pbeList) {

                if(item.PriceBook2Id == testProServQuote.Pricebook2Id) {

                    QuoteLineItem qli = new QuoteLineItem(
                        QuoteId = testProServQuote.Id,
                        Product2Id = item.Product2Id,
                        Quantity = 1,
                        UnitPrice = 200,
                        Discount_number__c = 2.5,
                        PricebookEntryId = item.Id
                    );
                    qliList.add(qli);
                }
            }
            Test.startTest();
                OpportunityTotals.bypassOpportnuityUpdate = true;
                insert qliList;
                OpportunityTotals.bypassOpportnuityUpdate = false;
            Test.stopTest();

                Quote reselectedProServQuote = [SELECT Id, Approved_Status__c,
                                            Approval_Type__c, Level_1_Approver__c,
                                            Level_2_Approver__c, Level_3_Approver__c,
                                            Level_4_Approver__c, Auto_Renewal__c
                                        FROM Quote
                                        WHERE Id = :testProServQuote.Id];

                /*System.assert(reselectedProServQuote.Approved_Status__c == QuoteHelper.APPROVAL_STATUS_REQUIRED);
                System.assert(reselectedProServQuote.Approval_Type__c == UserHelper.SEGMENT_LEADER_ROLE);
                System.assert(reselectedProServQuote.Level_1_Approver__c == testUserManager.Id);*/
                delete qliList;

            Quote reselectedProServQuote2 = [SELECT Id, Approved_Status__c,
                                            Approval_Type__c, Level_1_Approver__c,
                                            Level_2_Approver__c, Level_3_Approver__c,
                                            Level_4_Approver__c, Auto_Renewal__c
                                        FROM Quote
                                        WHERE Id = :testProServQuote.Id];

            //System.assert(reselectedProServQuote2.Approved_Status__c == QuoteHelper.APPROVAL_STATUS_APPROVED);
        }
    }

    @isTest
    static void testApproversSearchWorkedForFeatureAddonsApprovals() {

        User salesRepUser;
        User directManager;
        User segmentLeager;

        List<String> userNameList = new List<String>{
            createUserName('sRep'),
            createUserName('dMan'),
            createUserName('sLdr')
        };

        for(User u : [select Id, LastName, Username, Hierarchy_Role__c, ManagerId, Email from User where UserName IN :userNameList]) {
            if(u.UserName == createUserName('sRep')) {
                salesRepUser = u;
            }else if(u.UserName == createUserName('dMan')) {
                directManager = u;
            }else if(u.UserName == createUserName('sLdr')) {
                segmentLeager = u;
            }
        }

        System.runAs(salesRepUser) {

            insert new ApprovalAssignment__c(
                Name = 'POC - Send out additional POC Devices',
                Direct_Manager__c = true,
                Segment_Leader__c = true,
                SVP_WWS__c = false,
                SVP_WWS_Directs__c = false,
                Finance_Queue__c = true,
                FeatureActivations__c = true
            );

            Account testAcc = new Account(
                Name = 'test account',
                RC_User_ID__c = '',
                RC_Account_Status__c = 'New'
            );
            insert testAcc;

            Triggers.switchOff();
                Approval__c approval = (Approval__c) new SObjectBuilder(Approval__c.sObjectType)
                    .setField(Approval__c.Account__c, testAcc.Id)
                    .setField(Approval__c.RecordTypeId, ApprovalHelper.RT_ID_POC_ACCOUNT)
                    .setField(Approval__c.Number_of_POC_Users__c, 1)
                    .setField(Approval__c.Status__c, ApprovalHelper.STATUS_APPROVED)
                    .create()
                    .getRecord();
            Triggers.switchOn();

            Map<String, Schema.RecordTypeInfo> approvalRTInfoByNameMap = Approval__c.sObjectType.getDescribe().getRecordTypeInfosByName();

            Id featureAddonsRtId = approvalRTInfoByNameMap.get('Feature Add-Ons').getRecordTypeId();

            Approval__c testApproval = new Approval__c(
                POCSendOutAdditionalPOCDevices__c = true,
                Status__c = 'New',
                RecordTypeId = featureAddonsRtId,
                Account__c = testAcc.Id,
                CurrencyIsoCode = 'USD'
            );
            insert testApproval;

            Approval__c reselectedApproval = [SELECT Id,
                                              Level1Approver__c, Level2Approver__c,
                                              Level3Approver__c, Level4Approver__c,
                                              Level5Approver__c, AdditionalFeatures__c,
                                              Finance__c
                                          FROM Approval__c
                                          WHERE Id = :testApproval.Id];

            System.assertEquals(directManager.Id, reselectedApproval.Level1Approver__c);
            System.assertEquals(segmentLeager.Id, reselectedApproval.Level2Approver__c);
            System.assertEquals('POC - Send out additional POC Devices;', reselectedApproval.AdditionalFeatures__c);
            System.assertEquals(true, reselectedApproval.Finance__c);
        }
    }

    @isTest
    static void testApproversSearchWorkedForPOCAccountApprovals() {

        User salesRepUser;
        User directManager;
        User segmentLeager;
        User svpWWSDirects;

        List<String> userNameList = new List<String>{
            createUserName('sRep'),
            createUserName('dMan'),
            createUserName('sLdr'),
            createUserName('sWDr')
        };

        for(User u : [select Id, LastName, Username, Hierarchy_Role__c, ManagerId, Email from User where UserName IN :userNameList]) {
            if(u.UserName == createUserName('sRep')) {
                salesRepUser = u;
            }else if(u.UserName == createUserName('dMan')) {
                directManager = u;
            }else if(u.UserName == createUserName('sLdr')) {
                segmentLeager = u;
            }else if(u.UserName == createUserName('sWDr')) {
                svpWWSDirects = u;
            }
        }

        System.runAs(salesRepUser) {

            insert new POC_GOA__c(
                Sales_Rep__c = '0-0',
                Direct_Manager__c = '0-19',
                Segment_Leader__c = '0-0',
                SVP_WWS_Directs__c = '0-0',
                SVP_WWS__c = '0-0'
            );

            Account testAcc = new Account(
                Name = 'test account',
                RC_User_ID__c = '',
                RC_Account_Status__c = 'New'
            );
            insert testAcc;

            Map<String, Schema.RecordTypeInfo> approvalRTInfoByNameMap = Approval__c.sObjectType.getDescribe().getRecordTypeInfosByName();

            Id pocAccountRtId = approvalRTInfoByNameMap.get('POC Account').getRecordTypeId();

            Approval__c testApproval = new Approval__c(
                POCSendOutAdditionalPOCDevices__c = true,
                Number_of_POC_Users__c = 18,
                Status__c = 'Approved',
                RecordTypeId = pocAccountRtId,
                Account__c = testAcc.Id,
                CurrencyIsoCode = 'USD'
            );
            insert testApproval;

            Approval__c reselectedApproval = [SELECT Id,
                                              Level1Approver__c, Level2Approver__c,
                                              Level3Approver__c, Level4Approver__c,
                                              Level5Approver__c, AdditionalFeatures__c,
                                              Finance__c, Status__c
                                          FROM Approval__c
                                          WHERE Id = :testApproval.Id];

            System.assertEquals('Required', reselectedApproval.Status__c);
            System.assertEquals(directManager.Id, reselectedApproval.Level1Approver__c);
            System.assertEquals(null, reselectedApproval.Level2Approver__c);
            System.assertEquals(null, reselectedApproval.Level3Approver__c);
        }
    }

    @isTest
    static void testPopulateApprovalHistory() {
        insert new RingCentralVariousSettings__c(
                            Director_BO_Invoice_Billing_Approver__c = DIRECTOR_BO_NAME,
                            Treasure_Manager_Invoice_Billing_Approve__c = TREASURE_MANAGER_NAME,
                            Treasurer_Invoice_Billing_Approve__c = TREASURER_NAME,
                            Controller_Invoice_Billing_Approver__c = CONTROLLER_NAME,
                            Controller_for_Invoice_Request__c  = INVOICE_CONTROLLER);

        User salesRepUser = [select Id, LastName, Username, Hierarchy_Role__c, ManagerId, Email from User where UserName = :createUserName('sRep')];

        System.runAs(salesRepUser) {

            String currencyValue = 'USD';

            insert new Invoice_GOA__c(
                Name = '1',
                Currency__c = currencyValue,
                Sales_Rep__c = '500.00-999999999',
                Direct_Manager__c = '350.00-499.99',
                Segment_Leader__c = null,
                SVP_WWS_Directs__c = null,
                SVP_WWS__c = '0.01-349.99'
            );

            Triggers.switchOff();
            Approval__c appr = new Approval__c();
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => 'testAcc',
                    Account.BillingPostalCode => 'testCode',
                    Account.BillingCity => 'testCode',
                    Account.BillingCountry => 'testCountry',
                    Account.BillingState => 'testState',
                    Account.BillingStreet => 'testStreet',
                    Account.Payment_Method__c => 'Invoice'
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

        AccountContactRole payableContactRole = (AccountContactRole) new SObjectBuilder(AccountContactRole.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    AccountContactRole.AccountId => acc.Id,
                    AccountContactRole.ContactId => contact.Id,
                    AccountContactRole.Role => AccountContactRoleHelper.CONTACT_ROLE_ACCOUNT_PAYABLE
                }
            )
            .create()
            .getRecord();

        DateTime dateNow = System.now();
        Triggers.switchOff();
        Opportunity oppty = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.Name => 'Test Opportunity 2016',
                    Opportunity.Type => 'Syndicated - New',
                    Opportunity.StageName => 'Planning',
                    Opportunity.CloseDate => Date.newinstance(dateNow.year(), dateNow.month(), dateNow.day()),
                    Opportunity.AccountId => acc.Id,
                    Opportunity.Primary_Opportunity_Contact__c => contact.Id,
                    Opportunity.EstimatedProfessionalServices12Month__c => 10
                }
            )
            .create()
            .getRecord();

        Triggers.switchOn();

        appr.Opportunity__c = oppty.Id;
        appr.Account__c = acc.Id;

        appr.RecordTypeId = Schema.SObjectType.Approval__c.getRecordTypeInfosByName()
                                                                .get('Invoicing Request')
                                                                .getRecordTypeId();
        appr.Monthly_Credit_Limit__c = 501;
        appr.Sign_up_Purchase_Limit__c = 99999;
        appr.AccountPayableContact__c = contact.Id;
        appr.Potential_Users__c = 1;
        appr.Reason_Customer_is_Requesting_Invoicing__c = 'test';
        insert appr;

            Approval__c reselectedApproval = [SELECT Id,
                                                Level1Approver__c, Level2Approver__c,
                                                Level3Approver__c, Level4Approver__c,
                                                Level5Approver__c, AdditionalFeatures__c,
                                                Monthly_Credit_Limit__c, Status__c, Approval_History__c
                                            FROM Approval__c
                                            WHERE Id = :appr.Id];

            System.assertEquals('Required', reselectedApproval.Status__c);

            Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
            req1.setComments('Submitting request for approval.');
            req1.setObjectId(appr.Id);
            req1.setSubmitterId(salesRepUser.Id);
            req1.setProcessDefinitionNameOrId(ApprovalHelper.PROCESS_INVOICE_REQUEST_APPROVAL);
            req1.setSkipEntryCriteria(true);

            Test.startTest();
            Approval.ProcessResult result = Approval.process(req1);
            List<Id> newWorkItemIds = result.getNewWorkitemIds();

                // approve request
                Approval.ProcessWorkitemRequest req2 = new Approval.ProcessWorkitemRequest();
                req2.setComments('Approving request.');
                req2.setAction('Approve');
                req2.setNextApproverIds(new Id[] {reselectedApproval.Level1Approver__c});

                // Use the ID from the newly created item to specify the item to be worked
                req2.setWorkitemId(newWorkItemIds.get(0));

                Approval.ProcessResult result2 =  Approval.process(req2);


                Approval__c reselectedApproval2 = [SELECT Id,
                                                    Level1Approver__c, Level2Approver__c,
                                                    Level3Approver__c, Level4Approver__c,
                                                    Level5Approver__c, AdditionalFeatures__c,
                                                    Monthly_Credit_Limit__c, Status__c, Approval_History__c,
                                                    Sign_up_Purchase_Limit__c, Completed_Date__c,
                                                    Invoice_Terms__c, Payment_Terms__c
                                                FROM Approval__c
                                                WHERE Id = :appr.Id];

                System.assertEquals('PendingL4Approval', reselectedApproval2.Status__c);


                List<ProcessInstanceStep> historyStepsList = [SELECT StepStatus,
                        CreatedDate, OriginalActor.Name, Actor.Name, Comments,
                        ActorId, ProcessInstance.TargetObjectId, ProcessInstanceId
                    FROM ProcessInstanceStep];

                String resultHistory = '<table style="" border="1" cellpadding="0" cellspacing="0" width="100%">';
                resultHistory += '<tr><th colspan="5" rowspan="1"><p style="text-align: center; font-size: 120%;">Current approval request history</p></th></tr><tr>';
                resultHistory += '<td colspan="1" rowspan="1" width="70%"><p style="text-align: center;">Comments</p></td>';
                resultHistory += '<td colspan="1" rowspan="1" width="6%"><p style="text-align: center;">Action</p></td>';
                resultHistory += '<td colspan="1" rowspan="1" width="8%"><p style="text-align: center;">Assigned To</p></td>';
                resultHistory += '<td colspan="1" rowspan="1" width="8%"><p style="text-align: center;">Actual Approver</p></td>';
                resultHistory += '<td colspan="1" rowspan="1" width="8%"><p style="text-align: center;">Date</p></td></tr><tr>';
                resultHistory += '<td colspan="1" rowspan="1"><p style="text-align: center;">Submitting request for approval.</p></td>';
                resultHistory += '<td colspan="1" rowspan="1"><p style="text-align: center;">' + salesRepUser.Hierarchy_Role__c + ' submitted</p></td>';
                resultHistory += '<td colspan="1" rowspan="1"><p style="text-align: center;">' + salesRepUser.LastName + '</p></td>';
                resultHistory += '<td colspan="1" rowspan="1"><p style="text-align: center;">' + salesRepUser.LastName + '</p></td>';
                resultHistory += '<td colspan="1" rowspan="1"><p style="text-align: center;">' + historyStepsList[0].CreatedDate + '</p></td></tr></table>';



                // approve request
                Approval.ProcessWorkitemRequest req3 = new Approval.ProcessWorkitemRequest();
                req3.setComments('Approving request.');
                req3.setAction('Approve');
                req3.setNextApproverIds(new Id[] {reselectedApproval2.Level1Approver__c});

                Account reselectAcc = [
                        SELECT Id, Sign_up_Purchase_Limit__c,
                                Payment_Method__c, Monthly_Credit_Limit__c, Approval_Date__c,
                                Active_Invoice_Approval__c, Invoice_Terms__c, Payment_Terms__c
                        FROM Account
                        WHERE Id = :acc.Id
                ];

            Test.stopTest();
        }
    }


    @isTest
    static void testCurrencyCopiedFromOppOnInsertForInvoicingRequestApprovals() {

        User salesRepUser = [SELECT Id, LastName, Username, Hierarchy_Role__c, ManagerId, Email FROM User WHERE Username = :createUserName('sRep')];

        System.runAs(salesRepUser) {

            String currencyValue = 'USD';

            insert new Invoice_GOA__c(
                Name = '1',
                Currency__c = currencyValue,
                Sales_Rep__c = '500.00-999999999',
                Direct_Manager__c = null,
                Segment_Leader__c = '350.00-499.99',
                SVP_WWS_Directs__c = null,
                SVP_WWS__c = '0.01-349.99'
            );

            Account testAcc = new Account(
                Name = 'test account',
                RC_User_ID__c = '',
                RC_Account_Status__c = 'New'
            );
            insert testAcc;

            Contact contact = (Contact) new SObjectBuilder(Contact.SObjectType)
                .setFields(SObjectFactoryFieldDefaults.getDefaults(Contact.SObjectType))
                .setField(Contact.AccountId, testAcc.Id)
                .create()
                .getRecord();

            AccountContactRole payableContactRole = new AccountContactRole();
            payableContactRole.AccountId = testAcc.Id;
            payableContactRole.ContactId = contact.Id;
            payableContactRole.Role = AccountContactRoleHelper.CONTACT_ROLE_ACCOUNT_PAYABLE;
            insert payableContactRole;

            Opportunity testOpp = new Opportunity(
                AccountId = testAcc.Id,
                Name = 'MyTestOpportunity',
                Type = 'Existing Business',
                Brand_Name__c = 'RingCentral',
                Tier_Name__c = 'Office',
                StageName = '1. Qualify',
                CloseDate = System.today(),
                CurrencyIsoCode = currencyValue
            );
            insert testOpp;

            Map<String, Schema.RecordTypeInfo> approvalRTInfoByNameMap = Approval__c.sObjectType.getDescribe().getRecordTypeInfosByName();

            Id invoicingRequestRtId = approvalRTInfoByNameMap.get('Invoicing Request').getRecordTypeId();

            Approval__c testApproval = new Approval__c(
                POCSendOutAdditionalPOCDevices__c = true,
                Number_of_POC_Users__c = 1,
                Monthly_Credit_Limit__c = 501,
                Status__c = 'Approved',
                RecordTypeId = invoicingRequestRtId,
                Account__c = testAcc.Id,
                Opportunity__c = testOpp.Id,
                CurrencyIsoCode = 'CAD',
                AccountPayableContact__c = contact.Id,
                Potential_Users__c = 1,
                Reason_Customer_is_Requesting_Invoicing__c = 'test'
            );

            Test.startTest();
                insert testApproval;
            Test.stopTest();

            Approval__c reselectedApproval = [SELECT Id, CurrencyIsoCode, Status__c,
                                            Monthly_Credit_Limit__c, Completed_Date__c,
                                            Invoice_Terms__c, Payment_Terms__c
                                          FROM Approval__c
                                          WHERE Id = :testApproval.Id];

            System.assertEquals(testOpp.CurrencyIsoCode, reselectedApproval.CurrencyIsoCode);
            System.assertEquals(ApprovalTriggerHandler.APPROVAL_STATUS_REQUIRED, reselectedApproval.Status__c);
        }
    }


    @isTest
    static void testAccountIdCopiedFromOppForInvoicingRequestApprovals() {

        User salesRepUser = [SELECT Id, LastName, Username, Hierarchy_Role__c, ManagerId, Email FROM User WHERE Username = :createUserName('sRep')];

        System.runAs(salesRepUser) {

            String currencyValue = 'USD';

            insert new Invoice_GOA__c(
                Name = '1',
                Currency__c = currencyValue,
                Sales_Rep__c = '500.00-999999999',
                Direct_Manager__c = null,
                Segment_Leader__c = '350.00-499.99',
                SVP_WWS_Directs__c = null,
                SVP_WWS__c = '0.01-349.99'
            );

            Account testAcc = new Account(
                Name = 'test account',
                RC_User_ID__c = '',
                RC_Account_Status__c = 'New'
            );
            insert testAcc;

            Contact contact = (Contact) new SObjectBuilder(Contact.SObjectType)
                .setFields(SObjectFactoryFieldDefaults.getDefaults(Contact.SObjectType))
                .setField(Contact.AccountId, testAcc.Id)
                .create()
                .getRecord();

            AccountContactRole payableContactRole = new AccountContactRole();
            payableContactRole.AccountId = testAcc.Id;
            payableContactRole.ContactId = contact.Id;
            payableContactRole.Role = AccountContactRoleHelper.CONTACT_ROLE_ACCOUNT_PAYABLE;
            insert payableContactRole;

            Opportunity testOpp = new Opportunity(
                AccountId = testAcc.Id,
                Name = 'MyTestOpportunity',
                Type = 'Existing Business',
                Brand_Name__c = 'RingCentral',
                Tier_Name__c = 'Office',
                StageName = '1. Qualify',
                CloseDate = System.today(),
                CurrencyIsoCode = currencyValue
            );
            insert testOpp;

            Map<String, Schema.RecordTypeInfo> approvalRTInfoByNameMap = Approval__c.sObjectType.getDescribe().getRecordTypeInfosByName();

            Id invoicingRequestRtId = approvalRTInfoByNameMap.get('Invoicing Request').getRecordTypeId();

            Approval__c testApproval = new Approval__c(
                POCSendOutAdditionalPOCDevices__c = true,
                Number_of_POC_Users__c = 1,
                Monthly_Credit_Limit__c = 351,
                Status__c = 'Approved',
                RecordTypeId = invoicingRequestRtId,
                Opportunity__c = testOpp.Id,
                CurrencyIsoCode = 'CAD',
                AccountPayableContact__c = contact.Id,
                Potential_Users__c = 1,
                Reason_Customer_is_Requesting_Invoicing__c = 'test'
            );

            Test.startTest();
                insert testApproval;
            Test.stopTest();

            Approval__c reselectedApproval = [SELECT Id, Account__c
                                          FROM Approval__c
                                          WHERE Id = :testApproval.Id];

            System.assertEquals(testOpp.AccountId, reselectedApproval.Account__c);
        }
    }


    @isTest
    static void testApproversSearchWorkedForInvoicingRequestApprovals() {

        User salesRepUser;
        User directManager;

        List<String> userNameList = new List<String>{
            createUserName('sRep'),
            createUserName('dMan')
        };

        for(User u : [SELECT Id, LastName, Username, Hierarchy_Role__c, ManagerId, Email FROM User WHERE Username IN :userNameList]) {
            if(u.Username == createUserName('sRep')) {
                salesRepUser = u;
            }else if(u.Username == createUserName('dMan')) {
                directManager = u;
            }
        }

        System.runAs(salesRepUser) {

            String currencyValue = 'USD';

            insert new Invoice_GOA__c(
                Name = '1',
                Currency__c = currencyValue,
                Sales_Rep__c = '500.00-999999999',
                Direct_Manager__c = null,
                Segment_Leader__c = '350.00-499.99',
                SVP_WWS_Directs__c = null,
                SVP_WWS__c = '0.01-349.99'
            );

            Triggers.switchOff();
            Account testAcc = new Account(
                Name = 'test account',
                RC_User_ID__c = '',
                RC_Account_Status__c = 'New'
            );
            insert testAcc;

            Contact contact = (Contact) new SObjectBuilder(Contact.SObjectType)
                .setFields(SObjectFactoryFieldDefaults.getDefaults(Contact.SObjectType))
                .setField(Contact.AccountId, testAcc.Id)
                .create()
                .getRecord();

            AccountContactRole payableContactRole = new AccountContactRole();
            payableContactRole.AccountId = testAcc.Id;
            payableContactRole.ContactId = contact.Id;
            payableContactRole.Role = AccountContactRoleHelper.CONTACT_ROLE_ACCOUNT_PAYABLE;
            insert payableContactRole;

            Opportunity testOpp = new Opportunity(
                AccountId = testAcc.Id,
                Name = 'MyTestOpportunity',
                Type = 'Existing Business',
                Brand_Name__c = 'RingCentral',
                Tier_Name__c = 'Office',
                StageName = '1. Qualify',
                CloseDate = System.today(),
                CurrencyIsoCode = currencyValue
            );
            insert testOpp;
            Triggers.switchOn();

            Map<String, Schema.RecordTypeInfo> approvalRTInfoByNameMap = Approval__c.sObjectType.getDescribe().getRecordTypeInfosByName();

            Id invoicingRequestRtId = approvalRTInfoByNameMap.get('Invoicing Request').getRecordTypeId();

            // set Monthly_Credit_Limit__c for SegmentLeader range
            Approval__c testApproval = new Approval__c(
                POCSendOutAdditionalPOCDevices__c = true,
                Number_of_POC_Users__c = 1,
                Monthly_Credit_Limit__c = 351,
                Status__c = 'Approved',
                RecordTypeId = invoicingRequestRtId,
                Account__c = testAcc.Id,
                Opportunity__c = testOpp.Id,
                CurrencyIsoCode = currencyValue,
                AccountPayableContact__c = contact.Id,
                Potential_Users__c = 1,
                Reason_Customer_is_Requesting_Invoicing__c = 'test'
            );
            insert testApproval;
            Approval__c reselectedApproval = [SELECT Id,
                                              Level1Approver__c, Level2Approver__c,
                                              Level3Approver__c, Level4Approver__c,
                                              Level5Approver__c, AdditionalFeatures__c,
                                              Monthly_Credit_Limit__c, Status__c, Approval_History__c
                                          FROM Approval__c
                                          WHERE Id = :testApproval.Id];

            System.assertEquals('Required', reselectedApproval.Status__c);
            System.assertEquals(directManager.Id, reselectedApproval.Level1Approver__c);

            // set Monthly_Credit_Limit__c for SWP WWS range
            reselectedApproval.Monthly_Credit_Limit__c = 11;

            Test.startTest();
            update reselectedApproval;
            Test.stopTest();

            Approval__c reselectedApproval2 = [SELECT Id,
                                              Level1Approver__c, Level2Approver__c,
                                              Level3Approver__c, Level4Approver__c,
                                              Level5Approver__c, AdditionalFeatures__c,
                                              Monthly_Credit_Limit__c, Status__c, Approval_History__c
                                          FROM Approval__c
                                          WHERE Id = :testApproval.Id];

            System.assertEquals('Required', reselectedApproval2.Status__c);
            System.assertEquals(directManager.Id, reselectedApproval2.Level1Approver__c);
        }
    }

    @isTest
    static void testPOCAccountApprovalsAutoApproveBySalesRep() {

        User salesRepUser = [select Id, Username, Hierarchy_Role__c, ManagerId, Email from User where UserName = :createUserName('sRep')];

        System.runAs(salesRepUser) {

            insert new POC_GOA__c(
                Sales_Rep__c = '1-5',
                Direct_Manager__c = '6-25',
                Segment_Leader__c = '0-0',
                SVP_WWS_Directs__c = '26-50',
                SVP_WWS__c = '51-9999'
            );

            Account testAcc = new Account(
                Name = 'test account',
                RC_User_ID__c = '',
                RC_Account_Status__c = 'New'
            );
            insert testAcc;

            List<Package__c> testPackages = (List<Package__c>) new SObjectBuilder(Package__c.SObjectType)
                .setFields(new Map<SObjectField, Object>{
                    Package__c.Account__c => ValueProviderBuilder.provideList(new List<String>{testAcc.Id}),
                    Package__c.Service_Type__c => ValueProviderBuilder.provideList(new List<String>{AccountHelper.SERVICE_TYPE_OFFICE}),
                    Package__c.Account_Package_Id__c => ValueProviderBuilder.provideList(new List<String>{'11111111111'}),
                    Package__c.Enterprise_Account_ID__c => ValueProviderBuilder.provideList(new List<String>{testAcc.Id})
                })
                .quantity(1)
                .create()
                .getRecords();

            Map<String, Schema.RecordTypeInfo> approvalRTInfoByNameMap = Approval__c.sObjectType.getDescribe().getRecordTypeInfosByName();

            Id pocAccountRtId = approvalRTInfoByNameMap.get('POC Account').getRecordTypeId();

            Approval__c testApproval = new Approval__c(
                POCSendOutAdditionalPOCDevices__c = true,
                Number_of_POC_Users__c = 2,
                Status__c = 'Required',
                RecordTypeId = pocAccountRtId,
                Account__c = testAcc.Id,
                CurrencyIsoCode = 'USD'
            );
            insert testApproval;

            Approval__c reselectedApproval = [SELECT Id,
                                              Level1Approver__c, Level2Approver__c,
                                              Level3Approver__c, Level4Approver__c,
                                              Level5Approver__c, AdditionalFeatures__c,
                                              Finance__c, Status__c, Number_of_POC_Users__c
                                          FROM Approval__c
                                          WHERE Id = :testApproval.Id];

            System.assertEquals('Approved', reselectedApproval.Status__c);
            System.assertEquals(null, reselectedApproval.Level1Approver__c);
            System.assertEquals(null, reselectedApproval.Level2Approver__c);
            System.assertEquals(null, reselectedApproval.Level3Approver__c);
            System.assertEquals(null, reselectedApproval.Level4Approver__c);


            Package__c reselectedPackage = [select Id, Number_of_POC_Users__c from Package__c where Id = :testPackages.get(0).Id];
            // verify Number_of_POC_Users__c copied on related Account if Approval get Status 'Approved'
            // System.assertEquals(reselectedPackage.Number_of_POC_Users__c, reselectedApproval.Number_of_POC_Users__c);
        }
    }

    @isTest
    static void test_approversSearchWorkedForOtherHierarchyRoles() {

        User directManager;
        User segmentLeager;

        List<String> userNameList = new List<String>{
            createUserName('dMan'),
            createUserName('sLdr')
        };

        for(User u : [select Id, LastName, Username, Hierarchy_Role__c, ManagerId, Email from User where UserName IN :userNameList]) {
            if(u.UserName == createUserName('dMan')) {
                directManager = u;
            }else if(u.UserName == createUserName('sLdr')) {
                segmentLeager = u;
            }
        }

        System.runAs(directManager) {

            List<GOA_V2__c> goasList = new List<GOA_V2__c>();

            GOA_V2__c goaItem = new GOA_V2__c(
                Name = '1',
                Quantity_Range__c = '1-99',
                Contract_Initial_Term_Range__c = '',
                Sales_Rep__c = '0-0',
                Direct_Manager__c = '0.01-2.00',
                Segment_Leader__c = '2.01-3.00',
                SVP_WWS_Directs__c = '3.01-5.00',
                SVP_WWS__c = '5.01-99999999',
                Group__c = 'RC_Office_Standard_Monthly_Contract',
                Currency__c = 'USD'
            );
            goasList.add(goaItem);

            insert goasList;

            insert new Products_taken_into_account_in_GOA__c(
                Name = 'test',
                Quote_Record_Type__c = 'Sales Quote',
                Sub_Categories__c = 'Main, Contact Center'
            );


            Account testAccount = new Account(
                Name = 'Opty test account',
                Permitted_Brands__c = 'RingCentral'
            );
            insert testAccount;

            Opportunity testOpp = new Opportunity(
                AccountId = testAccount.Id,
                Name = 'MyTestOpportunity',
                Type = 'Existing Business',
                Brand_Name__c = 'RingCentral',
                Tier_Name__c = 'Office',
                StageName = '1. Qualify',
                CloseDate = System.today(),
                CurrencyIsoCode = 'USD'
            );
            insert testOpp;

            Pricebook2 testPriceBook = new Pricebook2(
                Name = 'Test Price Book',
                Description ='Test Price Book Products',
                IsActive = true,
                Line_Range_Min__c = 5,
                Line_Range_Max__c = 10,
                CurrencyIsoCode = 'USD'
            );
            insert testPriceBook;

            Quote testSalesQuote = new Quote (
                Name = 'testSalesQuote',
                Auto_Renewal__c = true,
                OpportunityId = testOpp.Id,
                Pricebook2Id = testPriceBook.Id,
                RecordTypeId = QuoteHelper.RT_ID_SALES,
                CurrencyIsoCode = 'USD'
            );
            insert testSalesQuote;


            List<Product2> prodList = new List<Product2>();

            Product2 testProduct = new Product2(
                Name = 'test product',
                IsActive = true,
                Sub_Category__c = 'Main',
                GOA_Group_V2__c = 'RC_Office_Standard_Monthly_Contract'
            );
            prodList.add(testProduct);
            insert prodList;


            List<PricebookEntry> pbeList = new List<PricebookEntry>();
            PricebookEntry pbe;

            for(Product2 item : prodList) {

                pbe = new PricebookEntry(
                    Pricebook2Id = Test.getStandardPricebookId(),
                    Product2Id = item.Id,
                    UnitPrice = 200,
                    IsActive = true,
                    UseStandardPrice = false,
                    CurrencyIsoCode = 'USD'
                );
                pbeList.add(pbe);

                pbe = new PricebookEntry(
                    Pricebook2Id = testPriceBook.Id,
                    Product2Id = item.Id,
                    UnitPrice = 200,
                    IsActive = true,
                    UseStandardPrice = false,
                    Per_Line__c = false,
                    CurrencyIsoCode = 'USD'
                );
                pbeList.add(pbe);
            }
            insert pbeList;


            Test.startTest();

                List<QuoteLineItem> qliList = new List<QuoteLineItem>();

                for(PricebookEntry item : pbeList) {

                    if(item.PriceBook2Id == testSalesQuote.Pricebook2Id) {

                        QuoteLineItem qli = new QuoteLineItem(
                            QuoteId = testSalesQuote.Id,
                            Product2Id = item.Product2Id,
                            Quantity = 1,
                            UnitPrice = item.UnitPrice,
                            Discount_number__c = 2.5,
                            PricebookEntryId = item.Id
                        );
                        qliList.add(qli);
                    }
                }
                insert qliList;

                Quote reselectedSalesQuote = [SELECT Id, Approved_Status__c,
                                            Approval_Type__c, Level_1_Approver__c,
                                            Level_2_Approver__c, Level_3_Approver__c,
                                            Level_4_Approver__c, Auto_Renewal__c
                                        FROM Quote
                                        WHERE Id = :testSalesQuote.Id];

                System.assert(reselectedSalesQuote.Approved_Status__c == QuoteHelper.APPROVAL_STATUS_REQUIRED);
                System.assert(reselectedSalesQuote.Approval_Type__c == UserHelper.SEGMENT_LEADER_ROLE);
                System.assert(reselectedSalesQuote.Level_1_Approver__c == segmentLeager.Id);
                System.assert(reselectedSalesQuote.Level_2_Approver__c == null);
                System.assert(reselectedSalesQuote.Level_3_Approver__c == null);
                System.assert(reselectedSalesQuote.Level_4_Approver__c == null);

            Test.stopTest();
        }
    }


    @isTest
    static void test_approvals_notNeedApprovalIfYouHaveHighestHierarchyRole() {

        User testUser;
        User salesRepUser;
        User directManager;
        User segmentLeager;

        List<String> userNameList = new List<String>{
            createUserName('test'),
            createUserName('sRep'),
            createUserName('dMan'),
            createUserName('sLdr')
        };

        for(User u : [select Id, LastName, Username, Hierarchy_Role__c, ManagerId, Email from User where UserName IN :userNameList]) {
            if(u.UserName == createUserName('test')) {
                testUser = u;
            }else if(u.UserName == createUserName('sRep')) {
                salesRepUser = u;
            }else if(u.UserName == createUserName('dMan')) {
                directManager = u;
            }else if(u.UserName == createUserName('sLdr')) {
                segmentLeager = u;
            }
        }

        Approval__c testApproval;

        System.runAs(salesRepUser) {

            List<ApprovalAssignment__c> apprAssignmentList = new List<ApprovalAssignment__c>();

            ApprovalAssignment__c appAssignment1 = new ApprovalAssignment__c(
                Name = 'POC - Send out additional POC Devices',
                Direct_Manager__c = true,
                Segment_Leader__c = true,
                SVP_WWS__c = false,
                SVP_WWS_Directs__c = false,
                Finance_Queue__c = false,
                FeatureActivations__c = false
            );
            apprAssignmentList.add(appAssignment1);

            ApprovalAssignment__c appAssignment2 = new ApprovalAssignment__c(
                Name = '50 people per meeting',
                Direct_Manager__c = true,
                Segment_Leader__c = true,
                SVP_WWS__c = true,
                SVP_WWS_Directs__c = true,
                Finance_Queue__c = false,
                FeatureActivations__c = false
            );
            apprAssignmentList.add(appAssignment2);

            insert apprAssignmentList;


            Account testAcc = new Account(
                Name = 'test account',
                Number_of_POC_Users__c = 1,
                RC_User_ID__c = '',
                RC_Account_Status__c = 'New'
            );
            insert testAcc;

            Triggers.switchOff();
                Approval__c approval = (Approval__c) new SObjectBuilder(Approval__c.sObjectType)
                    .setField(Approval__c.Account__c, testAcc.Id)
                    .setField(Approval__c.RecordTypeId, ApprovalHelper.RT_ID_POC_ACCOUNT)
                    .setField(Approval__c.Number_of_POC_Users__c, 1)
                    .setField(Approval__c.Status__c, ApprovalHelper.STATUS_APPROVED)
                    .create()
                    .getRecord();
            Triggers.switchOn();

            Map<String, Schema.RecordTypeInfo> approvalRTInfoByNameMap = Approval__c.sObjectType.getDescribe().getRecordTypeInfosByName();

            Id featureAddonsRtId = approvalRTInfoByNameMap.get('Feature Add-Ons').getRecordTypeId();

            testApproval = new Approval__c(
                POCSendOutAdditionalPOCDevices__c = true,
                Status__c = 'New',
                RecordTypeId = featureAddonsRtId,
                Account__c = testAcc.Id,
                CurrencyIsoCode = 'USD'
            );
            insert testApproval;

            Approval__c reselectedApproval = [SELECT Id,
                                                Level1Approver__c, Level2Approver__c,
                                                Level3Approver__c, Level4Approver__c,
                                                Level5Approver__c, AdditionalFeatures__c,
                                                Finance__c, Status__c
                                            FROM Approval__c
                                            WHERE Id = :testApproval.Id];

            System.assertEquals(directManager.Id, reselectedApproval.Level1Approver__c);
            System.assertEquals(segmentLeager.Id, reselectedApproval.Level2Approver__c);
            System.assertEquals('POC - Send out additional POC Devices;', reselectedApproval.AdditionalFeatures__c);
            System.assertEquals(false, reselectedApproval.Finance__c);
        }

        System.runAs(testUser) {

            if(ApproversSearch.userStaticMap.get(salesRepUser.Id) != null) {
                ApproversSearch.userStaticMap.put(salesRepUser.Id, null);
            }

            salesRepUser.Hierarchy_Role__c = UserHelper.SVP_WWS_ROLE;
            update salesRepUser;
        }

        System.runAs(salesRepUser) {

            testApproval.PeoplePerMeeting__c = true;
            update testApproval;

            Approval__c reselectedApproval2 = [SELECT Id,
                                                Level1Approver__c, Level2Approver__c,
                                                Level3Approver__c, Level4Approver__c,
                                                Level5Approver__c, AdditionalFeatures__c,
                                                Finance__c, Status__c
                                            FROM Approval__c
                                            WHERE Id = :testApproval.Id];


            System.assertEquals('Approved', reselectedApproval2.Status__c);
            System.assertEquals(null, reselectedApproval2.Level1Approver__c);
            System.assertEquals(null, reselectedApproval2.Level2Approver__c);
            System.assertEquals(null, reselectedApproval2.Level3Approver__c);
            System.assertEquals(null, reselectedApproval2.Level4Approver__c);
            System.assertEquals('POC - Send out additional POC Devices; 50 people per meeting;', reselectedApproval2.AdditionalFeatures__c);
        }
    }


    @isTest
    static void testApproversFoundCorrectlyWithCOOInManagerChain() {

        User salesRepUser;
        User directManager;
        User segmentLeager;
        User svpWWSDirects;

        List<String> userNameList = new List<String>{
            createUserName('sRep'),
            createUserName('dMan'),
            createUserName('sLdr'),
            createUserName('sWDr')
        };

        List<User> users = (List<User>) new UserSelector()
            .selectUserByUsername(new List<Object>{ userNameList })
            .selectFields( new List<String>{
                'Id',
                'LastName',
                'Username',
                'Hierarchy_Role__c',
                'ManagerId',
                'Email',
                'SegmentPicklist__c'
            })
            .executeQuery();

        for(User u : users) {
            if(u.UserName == createUserName('sRep')) {
                salesRepUser = u;
            }else if(u.UserName == createUserName('dMan')) {
                directManager = u;
            }else if(u.UserName == createUserName('sLdr')) {
                segmentLeager = u;
            }else if(u.UserName == createUserName('sWDr')) {
                svpWWSDirects = u;
            }
        }

        User coo = createUser('COO', null, null, 'COO');

        svpWWSDirects.ManagerId = coo.Id;
        update svpWWSDirects;

        User defaultApprover = ApproversSearch.getDefaultApprover();

        System.runAs(salesRepUser) {

            new SObjectBuilder(GOA_V2__c.sObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        GOA_V2__c.Name => '1',
                        GOA_V2__c.Quantity_Range__c => '1-99',
                        GOA_V2__c.Contract_Initial_Term_Range__c => '',
                        GOA_V2__c.Sales_Rep__c => '0-0',
                        GOA_V2__c.Direct_Manager__c => '0.01-2.00',
                        GOA_V2__c.Segment_Leader__c => '2.01-3.00',
                        GOA_V2__c.SVP_WWS_Directs__c => '3.01-5.00',
                        GOA_V2__c.SVP_WWS__c => '5.01-99999999',
                        GOA_V2__c.Group__c => 'RC_Office_Standard_Monthly_Contract',
                        GOA_V2__c.Currency__c => 'USD'
                    }
                )
                .create();

            new SObjectBuilder(Products_taken_into_account_in_GOA__c.sObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        Products_taken_into_account_in_GOA__c.Name => 'test',
                        Products_taken_into_account_in_GOA__c.Quote_Record_Type__c => QuoteHelper.RT_NAME_SALES,
                        Products_taken_into_account_in_GOA__c.Sub_Categories__c => 'Main, Contact Center'
                    }
                )
                .create();

            Account testAccount = (Account) new SObjectBuilder(Account.sObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        Account.Name => 'Opty test account',
                        Account.Permitted_Brands__c => OpportunityHelper.BRAND_RINGCENTRAL
                    }
                )
                .create()
                .getRecord();

            Opportunity testOpp = (Opportunity) new SObjectBuilder(Opportunity.sObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        Opportunity.AccountId => testAccount.Id,
                        Opportunity.Name => 'MyTestOpportunity',
                        Opportunity.Type => OpportunityHelper.OPPORTUNITY_TYPE_EX_BUSINESS,
                        Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL,
                        Opportunity.Tier_Name__c => OpportunityHelper.TIER_OFFICE,
                        Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                        Opportunity.CloseDate => System.today(),
                        Opportunity.CurrencyIsoCode => 'USD'
                    }
                )
                .create()
                .getRecord();

            Pricebook2 testPriceBook = (Pricebook2) new SObjectBuilder(Pricebook2.sObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        Pricebook2.Name => 'Test Price Book',
                        Pricebook2.Description => 'Test Price Book Products',
                        Pricebook2.IsActive => true,
                        Pricebook2.Line_Range_Min__c => 5,
                        Pricebook2.Line_Range_Max__c => 10,
                        Pricebook2.CurrencyIsoCode => 'USD'
                    }
                )
                .create()
                .getRecord();

            Quote testSalesQuote = (Quote) new SObjectBuilder(Quote.sObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Quote.Name => 'testSalesQuote',
                    Quote.Auto_Renewal__c => true,
                    Quote.OpportunityId => testOpp.Id,
                    Quote.Pricebook2Id => testPriceBook.Id,
                    Quote.RecordTypeId => QuoteHelper.RT_ID_SALES,
                    Quote.CurrencyIsoCode => 'USD'
                }
            )
            .create()
            .getRecord();

            Product2 testProduct = (Product2) new SObjectBuilder(Product2.sObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        Product2.Name => 'test product',
                        Product2.IsActive => true,
                        Product2.Sub_Category__c => 'Main',
                        Product2.GOA_Group_V2__c => 'RC_Office_Standard_Monthly_Contract'
                    }
                )
                .create()
                .getRecord();

            PricebookEntry standartPricebookEntry = (PricebookEntry) new SObjectBuilder(PricebookEntry.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                        PricebookEntry.Product2Id => testProduct.Id,
                        PricebookEntry.UnitPrice => 200,
                        PricebookEntry.IsActive => true,
                        PricebookEntry.UseStandardPrice => false,
                        PricebookEntry.CurrencyIsoCode => 'USD'
                    }
                )
                .create()
                .getRecord();

            PricebookEntry currentPricebookEntry = (PricebookEntry) new SObjectBuilder(PricebookEntry.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        PricebookEntry.Pricebook2Id => testPriceBook.Id,
                        PricebookEntry.Product2Id => testProduct.Id,
                        PricebookEntry.UnitPrice => 200,
                        PricebookEntry.IsActive => true,
                        PricebookEntry.UseStandardPrice => false,
                        PricebookEntry.Per_Line__c => false,
                        PricebookEntry.CurrencyIsoCode => 'USD'
                    }
                )
                .create()
                .getRecord();


            Test.startTest();

                QuoteLineItem qli = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.SObjectType)
                    .setFields(
                        new Map<SObjectField, Object>{
                            QuoteLineItem.QuoteId => testSalesQuote.Id,
                            QuoteLineItem.Product2Id => currentPricebookEntry.Product2Id,
                            QuoteLineItem.Quantity => 1,
                            QuoteLineItem.UnitPrice => currentPricebookEntry.UnitPrice,
                            QuoteLineItem.Discount_number__c => 7,
                            QuoteLineItem.PricebookEntryId => currentPricebookEntry.Id
                        }
                    )
                    .create()
                    .getRecord();

                Quote reselectedSalesQuote = (Quote) new QuoteSelector()
                    .selectQuoteById(new List<Id>{ testSalesQuote.Id })
                    .selectFields( new List<String>{
                        'Id',
                        'Approved_Status__c',
                        'Approval_Type__c',
                        'Level_1_Approver__c',
                        'Level_2_Approver__c',
                        'Level_3_Approver__c',
                        'Level_4_Approver__c',
                        'Auto_Renewal__c'
                    })
                    .executeQuery()
                    .get(0);

                System.assert(reselectedSalesQuote.Approved_Status__c == QuoteHelper.APPROVAL_STATUS_REQUIRED);
                System.assert(reselectedSalesQuote.Approval_Type__c == UserHelper.SVP_WWS_ROLE);
                System.assert(reselectedSalesQuote.Level_1_Approver__c == directManager.Id);
                System.assert(reselectedSalesQuote.Level_2_Approver__c == segmentLeager.Id);
                System.assert(reselectedSalesQuote.Level_3_Approver__c == svpWWSDirects.Id);
                System.assert(reselectedSalesQuote.Level_4_Approver__c == defaultApprover.Id);

            Test.stopTest();
        }
    }


    @isTest
    static void testVerifyStatusNotDropAfterDelProservProductFromSalesQuote() {

        User salesRepUser = [select Id, LastName, Username, Hierarchy_Role__c, ManagerId, Email from User where UserName = :createUserName('sRep')];

        List<PricebookEntry> pbeList = new List<PricebookEntry>();

        List<GOA_V2__c> goasList = new List<GOA_V2__c>();

        GOA_V2__c goaItem = new GOA_V2__c(
            Name = '1',
            Quantity_Range__c = '1-99',
            Contract_Initial_Term_Range__c = '',
            Sales_Rep__c = '0-0',
            Direct_Manager__c = '0.01-2.00',
            Segment_Leader__c = '2.01-3.00',
            SVP_WWS_Directs__c = '3.01-5.00',
            SVP_WWS__c = '5.01-99999999',
            Group__c = 'RC_Office_Standard_Monthly_Contract',
            Currency__c = 'USD'
        );
        goasList.add(goaItem);

        insert goasList;

        insert new Products_taken_into_account_in_GOA__c(
            Name = 'test',
            Quote_Record_Type__c = 'Sales Quote',
            Sub_Categories__c = 'Main, Contact Center'
        );


        System.runAs(salesRepUser) {

            Triggers.switchOff();
            Account testAccount = new Account(
                Name = 'Opty test account',
                Permitted_Brands__c = 'RingCentral'
            );
            insert testAccount;

            Opportunity testOpp = new Opportunity(
                AccountId = testAccount.Id,
                Name = 'MyTestOpportunity',
                Type = 'Existing Business',
                Brand_Name__c = 'RingCentral',
                Tier_Name__c = 'Office',
                StageName = '1. Qualify',
                CloseDate = System.today(),
                CurrencyIsoCode = 'USD'
            );
            insert testOpp;

            Pricebook2 testPriceBook = new Pricebook2(
                Name = 'Test Price Book',
                Description ='Test Price Book Products',
                IsActive = true,
                Line_Range_Min__c = 5,
                Line_Range_Max__c = 10,
                CurrencyIsoCode = 'USD'
            );
            insert testPriceBook;

            List<Quote> quotesList = new List<Quote>();

            Quote testSalesQuote = new Quote (
                Name = 'testSalesQuote',
                Auto_Renewal__c = true,
                OpportunityId = testOpp.Id,
                Pricebook2Id = testPriceBook.Id,
                Approved_Status__c = QuoteHelper.APPROVAL_STATUS_APPROVED,
                RecordTypeId = QuoteHelper.RT_ID_SALES,
                CurrencyIsoCode = 'USD'
            );
            quotesList.add(testSalesQuote);

            insert quotesList;


            List<Product2> prodList = new List<Product2>();

            Product2 testProduct = new Product2(
                Name = 'test product',
                IsActive = true,
                Sub_Category__c = 'Main',
                GOA_Group_V2__c = 'RC_Office_Standard_Monthly_Contract'
            );
            prodList.add(testProduct);

            Product2 testProservProduct = new Product2(
                Name = 'test proserv product',
                IsActive = true,
                Family = 'ProServ',
                Sub_Category__c = 'Professional Services',
                GOA_Group_V2__c = 'RC_Office_Standard_Monthly_Contract'
            );
            prodList.add(testProservProduct);
            insert prodList;


            PricebookEntry pbe;

            for(Product2 item : prodList) {

                pbe = new PricebookEntry(
                    Pricebook2Id = Test.getStandardPricebookId(),
                    Product2Id = item.Id,
                    UnitPrice = 200,
                    IsActive = true,
                    UseStandardPrice = false,
                    CurrencyIsoCode = 'USD'
                );
                pbeList.add(pbe);

                pbe = new PricebookEntry(
                    Pricebook2Id = testPriceBook.Id,
                    Product2Id = item.Id,
                    UnitPrice = 200,
                    IsActive = true,
                    UseStandardPrice = false,
                    Per_Line__c = false,
                    CurrencyIsoCode = 'USD'
                );
                pbeList.add(pbe);
            }
            insert pbeList;

            List<QuoteLineItem> qliList = new List<QuoteLineItem>();

            for(PricebookEntry item : pbeList) {

                if(item.PriceBook2Id == testSalesQuote.Pricebook2Id) {

                    QuoteLineItem salesQli = new QuoteLineItem(
                        QuoteId = testSalesQuote.Id,
                        Product2Id = item.Product2Id,
                        Quantity = 1,
                        UnitPrice = item.UnitPrice,
                        PricebookEntryId = item.Id
                    );
                    qliList.add(salesQli);
                }
            }

            // set discount for not-proserv product
            for(QuoteLineItem qli : qliList) {

                if(qli.Product2Id != testProservProduct.Id) {
                    qli.Discount_number__c = 3;
                }
            }
            insert qliList;

            Triggers.switchOn();

            Test.startTest();

                // approove discounts in sales quote
                testSalesQuote.Approved_Status__c = QuoteHelper.APPROVAL_STATUS_APPROVED;
                update testSalesQuote;

                // find qli with proserv product and delete it
                QuoteLineItem proservQli;

                for(QuoteLineItem qli : qliList) {

                    if(qli.Product2Id == testProservProduct.Id) {
                        proservQli = qli;
                    }
                }

                if(proservQli != null) {
                    delete proservQli;
                }

            Test.stopTest();

            List<Quote> reselectedQuotes = [SELECT Id, Approved_Status__c,
                                                Approval_Type__c, Level_1_Approver__c,
                                                Level_2_Approver__c, Level_3_Approver__c,
                                                Level_4_Approver__c, Auto_Renewal__c, RecordType.DeveloperName
                                            FROM Quote WHERE Id IN :new Set<Id>{testSalesQuote.Id}];

            System.assertEquals(reselectedQuotes.size(), 1);

            for(Quote item : reselectedQuotes) {

                System.assertEquals(QuoteHelper.APPROVAL_STATUS_APPROVED, item.Approved_Status__c);
            }
        }
    }

    // verify that ApproversSearch.isSuitableHierarchyRole(String) return true
    // only for suitable hierarchy roles(listed in UserHelper class)
    @isTest
    static void testIsSuitableHierarchyRole() {

        System.assertEquals(false, ApproversSearch.isSuitableHierarchyRole(null));
        System.assertEquals(false, ApproversSearch.isSuitableHierarchyRole(''));
        System.assertEquals(false, ApproversSearch.isSuitableHierarchyRole('Operations'));
        System.assertEquals(false, ApproversSearch.isSuitableHierarchyRole('OtherNotSuitableHierarchyRole'));
        System.assertEquals(true, ApproversSearch.isSuitableHierarchyRole(UserHelper.SALES_REP_ROLE));
        System.assertEquals(true, ApproversSearch.isSuitableHierarchyRole(UserHelper.DIRECT_MANAGER_ROLE));
        System.assertEquals(true, ApproversSearch.isSuitableHierarchyRole(UserHelper.SEGMENT_LEADER_ROLE));
        System.assertEquals(true, ApproversSearch.isSuitableHierarchyRole(UserHelper.SVP_WWS_DIRECTS_ROLE));
        System.assertEquals(true, ApproversSearch.isSuitableHierarchyRole(UserHelper.SVP_WWS_ROLE));
    }


    @isTest
    static void testCheckCurrentDiscountsWithEntitlements() {

        User testUser = [select Id, LastName, Username, Hierarchy_Role__c, ManagerId, Email from User where UserName = :createUserName('test')];


        System.runAs(testUser) {

            List<GOA_V2__c> goasList = new List<GOA_V2__c>();

            GOA_V2__c goaItem = new GOA_V2__c(
                Name = '1',
                Quantity_Range__c = '1-99',
                Contract_Initial_Term_Range__c = '',
                Sales_Rep__c = '0-0',
                Direct_Manager__c = '0.01-2.00',
                Segment_Leader__c = '2.01-3.00',
                SVP_WWS_Directs__c = '3.01-5.00',
                SVP_WWS__c = '5.01-99999999',
                Group__c = 'RC_Office_Standard_Monthly_Contract',
                Currency__c = 'USD'
            );
            goasList.add(goaItem);

            insert goasList;

            insert new Products_taken_into_account_in_GOA__c(
                Name = 'test',
                Quote_Record_Type__c = 'Sales Quote',
                Sub_Categories__c = 'Main, Contact Center'
            );


            Account testAccount = new Account(
                Name = 'Opty test account',
                Permitted_Brands__c = 'RingCentral'
            );
            insert testAccount;

            Opportunity testOpp = new Opportunity(
                AccountId = testAccount.Id,
                Name = 'MyTestOpportunity',
                Type = 'Existing Business',
                Brand_Name__c = 'RingCentral',
                Tier_Name__c = 'Office',
                StageName = '1. Qualify',
                CloseDate = System.today(),
                CurrencyIsoCode = 'USD'
            );
            insert testOpp;

            Pricebook2 testPriceBook = new Pricebook2(
                Name = 'Test Price Book',
                Description ='Test Price Book Products',
                IsActive = true,
                Line_Range_Min__c = 5,
                Line_Range_Max__c = 10,
                CurrencyIsoCode = 'USD'
            );
            insert testPriceBook;

            Quote testSalesQuote = new Quote (
                Name = 'testSalesQuote',
                Auto_Renewal__c = true,
                OpportunityId = testOpp.Id,
                Pricebook2Id = testPriceBook.Id,
                RecordTypeId = QuoteHelper.RT_ID_SALES,
                CurrencyIsoCode = 'USD'
            );
            insert testSalesQuote;


            List<Product2> prodList = new List<Product2>();

            Product2 testProduct = new Product2(
                Name = 'test product',
                IsActive = true,
                Sub_Category__c = 'Main',
                GOA_Group_V2__c = 'RC_Office_Standard_Monthly_Contract'
            );
            prodList.add(testProduct);
            insert prodList;


            List<PricebookEntry> pbeList = new List<PricebookEntry>();
            PricebookEntry pbe;

            for(Product2 item : prodList) {

                pbe = new PricebookEntry(
                    Pricebook2Id = Test.getStandardPricebookId(),
                    Product2Id = item.Id,
                    UnitPrice = 200,
                    IsActive = true,
                    UseStandardPrice = false,
                    CurrencyIsoCode = 'USD'
                );
                pbeList.add(pbe);

                pbe = new PricebookEntry(
                    Pricebook2Id = testPriceBook.Id,
                    Product2Id = item.Id,
                    UnitPrice = 200,
                    IsActive = true,
                    UseStandardPrice = false,
                    Per_Line__c = false,
                    CurrencyIsoCode = 'USD'
                );
                pbeList.add(pbe);
            }
            insert pbeList;

            Entitlement__c entl = new Entitlement__c(
                Active__c = true,
                Account__c = testAccount.Id,
                Product__c = testProduct.Id,
                Discount__c = 3,
                Discount_Type__c = QuoteLineItemHelper.DISCOUNT_TYPE_PERCENTAGE,
                Quantity__c = 1,
                Price__c = 10
            );
            insert entl;


            List<QuoteLineItem> qliList = new List<QuoteLineItem>();

            for(PricebookEntry item : pbeList) {

                if(item.PriceBook2Id == testSalesQuote.Pricebook2Id) {

                    // set disocunt equal to Entitlemtent discount
                    QuoteLineItem qli = new QuoteLineItem(
                        QuoteId = testSalesQuote.Id,
                        Product2Id = item.Product2Id,
                        Quantity = 1,
                        UnitPrice = item.UnitPrice,
                        PricebookEntryId = item.Id,
                        Discount_type__c = QuoteLineItemHelper.DISCOUNT_TYPE_PERCENTAGE,
                        Discount = entl.Discount__c,
                        Discount_number__c = entl.Discount__c,
                        Entitlement__c = entl.Id
                    );
                    qliList.add(qli);
                }
            }

            Test.startTest();

                insert qliList;

                Quote reselectedSalesQuote = [SELECT Id, Approved_Status__c,
                                            Approval_Type__c, Level_1_Approver__c,
                                            Level_2_Approver__c, Level_3_Approver__c,
                                            Level_4_Approver__c, Auto_Renewal__c
                                        FROM Quote
                                        WHERE Id = :testSalesQuote.Id];

                System.assert(reselectedSalesQuote.Approved_Status__c == QuoteHelper.APPROVAL_STATUS_APPROVED);

                // set discount bigger than in Entitlement
                for(QuoteLineItem qli :qliList) {
                    qli.Discount_number__c = entl.Discount__c + 1;
                    qli.Discount = entl.Discount__c + 1;
                }
                update qliList;


                reselectedSalesQuote = [SELECT Id, Approved_Status__c,
                                            Approval_Type__c, Level_1_Approver__c,
                                            Level_2_Approver__c, Level_3_Approver__c,
                                            Level_4_Approver__c, Auto_Renewal__c
                                        FROM Quote
                                        WHERE Id = :testSalesQuote.Id];

                System.assert(reselectedSalesQuote.Approved_Status__c == QuoteHelper.APPROVAL_STATUS_REQUIRED);

            Test.stopTest();
        }
    }

    @isTest
    static void testChangeInitialTermWithoutSpecialTermsShouldNotTriggerApproverSearch() {
        // Verify ApprovalLogic(From QuoteTrigger) not Runned if Initial Term was changed on the Quote without Special Terms.
        Triggers.switchOff();
        User testUser = [select Id, LastName, Username, Hierarchy_Role__c, ManagerId, Email from User where UserName = :createUserName('test')];

        System.runAs(testUser) {

            insert new SpecialTermsApprovers_V2__c(
                Name = 'STA1',
                Special_Terms__c = '1 Free Month of Service',
                Plan__c = 'Monthly',
                Initial_Term__c = '12-60',
                Last_Approver__c = 'Segment Leader'
            );

            GOA_V2__c goaItem = new GOA_V2__c(
                Name = '1',
                Quantity_Range__c = '1-99',
                Contract_Initial_Term_Range__c = '',
                Sales_Rep__c = '0-0',
                Direct_Manager__c = '0.01-2.00',
                Segment_Leader__c = '2.01-3.00',
                SVP_WWS_Directs__c = '3.01-5.00',
                SVP_WWS__c = '5.01-99999999',
                Group__c = 'RC_Office_Standard_Monthly_Contract',
                Currency__c = 'USD'
            );

            insert new List<GOA_V2__c>{ goaItem };

            insert new Products_taken_into_account_in_GOA__c(
                Name = 'test',
                Quote_Record_Type__c = 'Sales Quote',
                Sub_Categories__c = 'Main, Contact Center'
            );


            Account testAccount = new Account(
                Name = 'Opty test account',
                Permitted_Brands__c = 'RingCentral'
            );
            insert testAccount;

            Opportunity testOpp = new Opportunity(
                AccountId = testAccount.Id,
                Name = 'MyTestOpportunity',
                Type = 'Existing Business',
                Brand_Name__c = 'RingCentral',
                Tier_Name__c = 'Office',
                StageName = '1. Qualify',
                CloseDate = System.today(),
                CurrencyIsoCode = 'USD'
            );
            insert testOpp;

            Pricebook2 testPriceBook = new Pricebook2(
                Name = 'Test Price Book',
                Description ='Test Price Book Products',
                IsActive = true,
                Line_Range_Min__c = 5,
                Line_Range_Max__c = 10,
                CurrencyIsoCode = 'USD',
                Plan__c = 'Monthly'
            );
            insert testPriceBook;

            Quote testSalesQuote = new Quote (
                Name = 'testSalesQuote',
                Auto_Renewal__c = true,
                OpportunityId = testOpp.Id,
                Pricebook2Id = testPriceBook.Id,
                RecordTypeId = QuoteHelper.RT_ID_SALES,
                CurrencyIsoCode = 'USD',
                Approved_Status__c = QuoteHelper.APPROVAL_STATUS_APPROVED
            );
            insert testSalesQuote;


            List<Product2> prodList = new List<Product2>();

            Product2 testProduct = new Product2(
                Name = 'test product',
                IsActive = true,
                Sub_Category__c = 'Main',
                GOA_Group_V2__c = 'RC_Office_Standard_Monthly_Contract'
            );
            prodList.add(testProduct);
            insert prodList;


            List<PricebookEntry> pbeList = new List<PricebookEntry>();
            PricebookEntry pbe;

            for(Product2 item : prodList) {

                pbe = new PricebookEntry(
                    Pricebook2Id = Test.getStandardPricebookId(),
                    Product2Id = item.Id,
                    UnitPrice = 200,
                    IsActive = true,
                    UseStandardPrice = false,
                    CurrencyIsoCode = 'USD'
                );
                pbeList.add(pbe);

                pbe = new PricebookEntry(
                    Pricebook2Id = testPriceBook.Id,
                    Product2Id = item.Id,
                    UnitPrice = 200,
                    IsActive = true,
                    UseStandardPrice = false,
                    Per_Line__c = false,
                    CurrencyIsoCode = 'USD'
                );
                pbeList.add(pbe);
            }
            insert pbeList;

                List<QuoteLineItem> qliList = new List<QuoteLineItem>();

                for(PricebookEntry item : pbeList) {

                    if(item.PriceBook2Id == testSalesQuote.Pricebook2Id) {

                        QuoteLineItem qli = new QuoteLineItem(
                            QuoteId = testSalesQuote.Id,
                            Product2Id = item.Product2Id,
                            Quantity = 1,
                            UnitPrice = item.UnitPrice,
                            Discount_number__c = 5,
                            PricebookEntryId = item.Id
                        );
                        qliList.add(qli);
                    }
                }
                insert qliList;
            Triggers.switchOn();
            Test.startTest();
                Quote reselectedSalesQuote = [SELECT Id, Approved_Status__c,
                                            Approval_Type__c, Level_1_Approver__c,
                                            Level_2_Approver__c, Level_3_Approver__c,
                                            Level_4_Approver__c, Auto_Renewal__c, Initial_Term_months__c, Special_Terms__c
                                        FROM Quote
                                        WHERE Id = :testSalesQuote.Id];

                // approove quote
                reselectedSalesQuote.Approved_Status__c = QuoteHelper.APPROVAL_STATUS_APPROVED;
                Triggers.switchOff();
                Triggers.except('QuoteTriggerHelper.SetApprovalType');
                update reselectedSalesQuote;
                Triggers.switchOn();


                reselectedSalesQuote = [SELECT Id, Approved_Status__c,
                                            Approval_Type__c, Level_1_Approver__c,
                                            Level_2_Approver__c, Level_3_Approver__c,
                                            Level_4_Approver__c, Auto_Renewal__c, Initial_Term_months__c, Special_Terms__c
                                        FROM Quote
                                        WHERE Id = :testSalesQuote.Id];
                System.assertEquals(QuoteHelper.APPROVAL_STATUS_APPROVED, reselectedSalesQuote.Approved_Status__c);

                // change "Initial Term" and verify quote still approoved
                reselectedSalesQuote.Initial_Term_months__c = '12'; // initialTerm Updated on Quote Without SpecialTerms(Approval_logic should be passed)
                Triggers.switchOff();
                Triggers.except('QuoteTriggerHelper.SetApprovalType');
                update reselectedSalesQuote;
                Triggers.switchOn();



                // verify that Approval_logic was passed
                System.assertEquals(true, QuoteTriggerHelper.quoteIdToPassApprovalLogicMap.get(reselectedSalesQuote.Id));

                reselectedSalesQuote = [SELECT Id, Approved_Status__c,
                                            Approval_Type__c, Level_1_Approver__c,
                                            Level_2_Approver__c, Level_3_Approver__c,
                                            Level_4_Approver__c, Auto_Renewal__c, Initial_Term_months__c, Special_Terms__c
                                        FROM Quote
                                        WHERE Id = :testSalesQuote.Id];
                System.assertEquals(QuoteHelper.APPROVAL_STATUS_APPROVED, reselectedSalesQuote.Approved_Status__c);


                // set special term and update "Initial Term"
                reselectedSalesQuote.Special_Terms__c = '1 Free Month of Service';
                reselectedSalesQuote.Initial_Term_months__c = '24'; // initialTerm Updated on Quote With SpecialTerms(Approval_logic should not be passed)
                Triggers.switchOff();
                Triggers.except('QuoteTriggerHelper.SetApprovalType');
                update reselectedSalesQuote;
                Triggers.switchOn();

                // verify that Approval_logic was not passed
                System.assertEquals(false, QuoteTriggerHelper.quoteIdToPassApprovalLogicMap.get(reselectedSalesQuote.Id));


                reselectedSalesQuote = [SELECT Id, Approved_Status__c,
                                            Approval_Type__c, Level_1_Approver__c,
                                            Level_2_Approver__c, Level_3_Approver__c,
                                            Level_4_Approver__c, Auto_Renewal__c, Initial_Term_months__c, Special_Terms__c
                                        FROM Quote
                                        WHERE Id = :testSalesQuote.Id];
                System.assertEquals(QuoteHelper.APPROVAL_STATUS_REQUIRED, reselectedSalesQuote.Approved_Status__c);
            Test.stopTest();
        }
    }

    @isTest
    static void testChangeInitialTermWithoutGOADependentProductsShouldNotTriggerApproverSearch() {
        // Verify ApprovalLogic(From QuoteTrigger) not Runned if Initial Term was changed on the Quote
        // without products that have GOA rules that depend on Initial Term (GOA Group Device_Contract for example).

        User testUser = [select Id, LastName, Username, Hierarchy_Role__c, ManagerId, Email from User where UserName = :createUserName('test')];

        final String quotePackageInfo = '[{"id":"24","version":"1","packageInfo":{"catalogId":"24","version":"1"},'
            + '"productName":"Office","duration":"Monthly","edition":{"id":5,"name":"Premium"},'
            + '"offerType":"Regular","globalPackageLimits":[{"value":"50000","code":"MONTHLY_AMOUNT_LIMIT",'
            + '"name":"Monthly money amount limit","type":"Amount","scope":"BillingCycle","transactionType":"Any",'
            + '"target":"Global","exclusions":[{"target":"LicenseCategoryId","targetId":"AP"}],'
            + '"override":false}],"permissions":null}]';

        System.runAs(testUser) {
            Triggers.switchOff();
            insert new SpecialTermsApprovers_V2__c(
                Name = 'STA1',
                Special_Terms__c = '1 Free Month of Service',
                Plan__c = 'Monthly',
                Initial_Term__c = '12-60',
                Last_Approver__c = 'Segment Leader'
            );

            GOA_V2__c goaItem = new GOA_V2__c(
                Name = '1',
                Quantity_Range__c = '1-99',
                Contract_Initial_Term_Range__c = '',
                Sales_Rep__c = '0-0',
                Direct_Manager__c = '0.01-2.00',
                Segment_Leader__c = '2.01-3.00',
                SVP_WWS_Directs__c = '3.01-5.00',
                SVP_WWS__c = '5.01-99999999',
                Group__c = 'RC_Office_Standard_Monthly_Contract',
                Currency__c = 'USD'
            );

            GOA_V2__c goaItem2 = new GOA_V2__c(
                Name = '2',
                Quantity_Range__c = '1-99',
                Contract_Initial_Term_Range__c = '12-30',
                Sales_Rep__c = '0-0',
                Direct_Manager__c = '0.01-2.00',
                Segment_Leader__c = '2.01-3.00',
                SVP_WWS_Directs__c = '3.01-5.00',
                SVP_WWS__c = '5.01-99999999',
                Group__c = 'Device_Contract',
                Currency__c = 'USD'
            );

            insert new List<GOA_V2__c>{
                goaItem, goaItem2
            };

            insert new Products_taken_into_account_in_GOA__c(
                Name = 'test',
                Quote_Record_Type__c = 'Sales Quote',
                Sub_Categories__c = 'Main, Contact Center'
            );


            Account testAccount = new Account(
                Name = 'Opty test account',
                Permitted_Brands__c = 'RingCentral'
            );
            insert testAccount;

            Opportunity testOpp = new Opportunity(
                AccountId = testAccount.Id,
                Name = 'MyTestOpportunity',
                Type = 'Existing Business',
                Brand_Name__c = 'RingCentral',
                Tier_Name__c = 'Office',
                StageName = '1. Qualify',
                CloseDate = System.today(),
                CurrencyIsoCode = 'USD'
            );
            insert testOpp;

            Pricebook2 testPriceBook = new Pricebook2(
                Name = 'Test Price Book',
                Description ='Test Price Book Products',
                IsActive = true,
                Line_Range_Min__c = 5,
                Line_Range_Max__c = 10,
                CurrencyIsoCode = 'USD',
                Plan__c = 'Monthly'
            );
            insert testPriceBook;
            Triggers.switchOn();

            Quote testSalesQuote = new Quote (
                Name = 'testSalesQuote',
                Auto_Renewal__c = true,
                OpportunityId = testOpp.Id,
                Pricebook2Id = testPriceBook.Id,
                RecordTypeId = QuoteHelper.RT_ID_SALES,
                CurrencyIsoCode = 'USD',
                Approved_Status__c = QuoteHelper.APPROVAL_STATUS_APPROVED,
                Package_Info__c = quotePackageInfo
            );
            insert testSalesQuote;

            Triggers.switchOff();
            List<Product2> prodList = new List<Product2>();

            Product2 testProduct = new Product2(
                Name = 'test product',
                IsActive = true,
                Sub_Category__c = 'Main',
                GOA_Group_V2__c = 'RC_Office_Standard_Monthly_Contract'
            );
            prodList.add(testProduct);

            Product2 testProduct2 = new Product2(
                Name = 'test product2',
                IsActive = true,
                Sub_Category__c = 'Main',
                GOA_Group_V2__c = 'Device_Contract'
            );
            prodList.add(testProduct2);
            insert prodList;


            List<PricebookEntry> pbeList = new List<PricebookEntry>();
            PricebookEntry pbe;

            for(Product2 item : prodList) {

                pbe = new PricebookEntry(
                    Pricebook2Id = Test.getStandardPricebookId(),
                    Product2Id = item.Id,
                    UnitPrice = 200,
                    IsActive = true,
                    UseStandardPrice = false,
                    CurrencyIsoCode = 'USD'
                );
                pbeList.add(pbe);

                pbe = new PricebookEntry(
                    Pricebook2Id = testPriceBook.Id,
                    Product2Id = item.Id,
                    UnitPrice = 200,
                    IsActive = true,
                    UseStandardPrice = false,
                    Per_Line__c = false,
                    CurrencyIsoCode = 'USD'
                );
                pbeList.add(pbe);
            }
            insert pbeList;
            Triggers.switchOn();

                Quote reselectedSalesQuote = [SELECT Id, Approved_Status__c,
                                            Approval_Type__c, Level_1_Approver__c,
                                            Level_2_Approver__c, Level_3_Approver__c,
                                            Level_4_Approver__c, Auto_Renewal__c, Initial_Term_months__c, Special_Terms__c
                                        FROM Quote
                                        WHERE Id = :testSalesQuote.Id];

                System.assertEquals(QuoteHelper.APPROVAL_STATUS_APPROVED, reselectedSalesQuote.Approved_Status__c);

                // change InitialTerm
                reselectedSalesQuote.Initial_Term_months__c = '12'; //initialTerm updated on quote without GOA dependent product(Approval_Logic should be passed)
                update reselectedSalesQuote;

                // verify Approval_Logic is passed
                System.assertEquals(true, QuoteTriggerHelper.quoteIdToPassApprovalLogicMap.get(reselectedSalesQuote.Id));


                reselectedSalesQuote = [SELECT Id, Approved_Status__c,
                                            Approval_Type__c, Level_1_Approver__c,
                                            Level_2_Approver__c, Level_3_Approver__c,
                                            Level_4_Approver__c, Auto_Renewal__c, Initial_Term_months__c, Special_Terms__c
                                        FROM Quote
                                        WHERE Id = :testSalesQuote.Id];
                System.assertEquals(QuoteHelper.APPROVAL_STATUS_APPROVED, reselectedSalesQuote.Approved_Status__c);

                // add Device_Contract product
                List<QuoteLineItem> qliList = new List<QuoteLineItem>();

                for(PricebookEntry item : pbeList) {

                    if(item.PriceBook2Id == testSalesQuote.Pricebook2Id) {

                        QuoteLineItem qli = new QuoteLineItem(
                            QuoteId = testSalesQuote.Id,
                            Product2Id = item.Product2Id,
                            Quantity = 1,
                            UnitPrice = item.UnitPrice,
                            Discount_number__c = 1,
                            PricebookEntryId = item.Id,
                            PackageInfo__c = TestDataGenerator.TEST_PACKAGE_INFO
                        );
                        qliList.add(qli);
                    }
                }
            Test.startTest();
                insert qliList;


                reselectedSalesQuote = [SELECT Id, Approved_Status__c,
                                            Approval_Type__c, Level_1_Approver__c,
                                            Level_2_Approver__c, Level_3_Approver__c,
                                            Level_4_Approver__c, Auto_Renewal__c, Initial_Term_months__c, Special_Terms__c
                                        FROM Quote
                                        WHERE Id = :testSalesQuote.Id];
                System.assertEquals(QuoteHelper.APPROVAL_STATUS_REQUIRED, reselectedSalesQuote.Approved_Status__c);

                // approve quote
                reselectedSalesQuote.Approved_Status__c = QuoteHelper.APPROVAL_STATUS_APPROVED;
                update reselectedSalesQuote;

                Test.stopTest();

                reselectedSalesQuote = [SELECT Id, Approved_Status__c,
                                            Approval_Type__c, Level_1_Approver__c,
                                            Level_2_Approver__c, Level_3_Approver__c,
                                            Level_4_Approver__c, Auto_Renewal__c, Initial_Term_months__c, Special_Terms__c
                                        FROM Quote
                                        WHERE Id = :testSalesQuote.Id];
                System.assertEquals(QuoteHelper.APPROVAL_STATUS_APPROVED, reselectedSalesQuote.Approved_Status__c);

                reselectedSalesQuote.Initial_Term_months__c = '24'; //initialTerm updated on quote with GOA dependent product(Approval_Logic should not be passed)
                update reselectedSalesQuote;

                // verify Approval_Logic is not passed
                System.assertEquals(false, QuoteTriggerHelper.quoteIdToPassApprovalLogicMap.get(reselectedSalesQuote.Id));


                // verify status is changed
                reselectedSalesQuote = [SELECT Id, Approved_Status__c,
                                            Approval_Type__c, Level_1_Approver__c,
                                            Level_2_Approver__c, Level_3_Approver__c,
                                            Level_4_Approver__c, Auto_Renewal__c, Initial_Term_months__c, Special_Terms__c
                                        FROM Quote
                                        WHERE Id = :testSalesQuote.Id];
                System.assertEquals(QuoteHelper.APPROVAL_STATUS_REQUIRED, reselectedSalesQuote.Approved_Status__c);
        }
    }

    @isTest
    static void testVerifyApproverLevelsUpdatedIfApprovalStatusNotChanged() {

        User salesRepUser;
        User directManager;
        User segmentLeager;

        List<String> userNameList = new List<String>{
            createUserName('sRep'),
            createUserName('dMan'),
            createUserName('sLdr')
        };

        for(User u : [select Id, LastName, Username, Hierarchy_Role__c, ManagerId, Email from User where UserName IN :userNameList]) {
            if(u.UserName == createUserName('sRep')) {
                salesRepUser = u;
            }else if(u.UserName == createUserName('dMan')) {
                directManager = u;
            }else if(u.UserName == createUserName('sLdr')) {
                segmentLeager = u;
            }
        }

        System.runAs(salesRepUser) {

            List<GOA_V2__c> goasList = new List<GOA_V2__c>();

            GOA_V2__c goaItem = new GOA_V2__c(
                Name = '1',
                Quantity_Range__c = '1-99',
                Contract_Initial_Term_Range__c = '',
                Sales_Rep__c = '0-0',
                Direct_Manager__c = '0.01-50.00',
                Segment_Leader__c = '50.01-100.00',
                SVP_WWS_Directs__c = '100.01-99999',
                SVP_WWS__c = '0-0',
                Group__c = 'Refurbished_Phone',
                Currency__c = 'USD'
            );
            goasList.add(goaItem);

            GOA_V2__c goaItem1 = new GOA_V2__c(
                Name = '2',
                Quantity_Range__c = '1-99',
                Contract_Initial_Term_Range__c = '',
                Sales_Rep__c = '0-1.00',
                Direct_Manager__c = '1.01-2.00',
                Segment_Leader__c = '2.01-3.00',
                SVP_WWS_Directs__c = '3.01-5.00',
                SVP_WWS__c = '5.01-99999999',
                Group__c = 'Device_Contract',
                Currency__c = 'USD'
            );
            goasList.add(goaItem1);

            insert goasList;

            insert new Products_taken_into_account_in_GOA__c(
                Name = 'test',
                Quote_Record_Type__c = 'Sales Quote',
                Sub_Categories__c = 'Main, Contact Center'
            );


            Account testAccount = new Account(
                Name = 'Opty test account',
                Permitted_Brands__c = 'RingCentral'
            );
            insert testAccount;

            Opportunity testOpp = new Opportunity(
                AccountId = testAccount.Id,
                Name = 'MyTestOpportunity',
                Type = 'Existing Business',
                Brand_Name__c = 'RingCentral',
                Tier_Name__c = 'Office',
                StageName = '1. Qualify',
                CloseDate = System.today(),
                CurrencyIsoCode = 'USD'
            );
            insert testOpp;

            Pricebook2 testPriceBook = new Pricebook2(
                Name = 'Test Price Book',
                Description ='Test Price Book Products',
                IsActive = true,
                Line_Range_Min__c = 5,
                Line_Range_Max__c = 10,
                CurrencyIsoCode = 'USD'
            );
            insert testPriceBook;

            Quote testSalesQuote = new Quote (
                Name = 'testSalesQuote',
                Auto_Renewal__c = true,
                OpportunityId = testOpp.Id,
                Pricebook2Id = testPriceBook.Id,
                RecordTypeId = QuoteHelper.RT_ID_SALES,
                CurrencyIsoCode = 'USD'
            );
            insert testSalesQuote;


            List<Product2> prodList = new List<Product2>();

            Product2 testRefurbishedProduct = new Product2(
                Name = 'test Refurbished Product',
                IsActive = true,
                Sub_Category__c = 'Main',
                GOA_Group_V2__c = 'Refurbished_Phone',
                Feature__c = 39,
                Sub_Feature__c = 52
            );
            prodList.add(testRefurbishedProduct);

            Product2 testDiscountedProduct = new Product2(
                Name = 'test Discounted Product',
                IsActive = true,
                GOA_Group_V2__c = 'Device_Contract',
                Family = 'Discounted Phones',
                Feature__c = 11,
                Sub_Feature__c = 16,
                Sub_Category__c = 'Main',
                Charge_Term__c = 'One - Time'
            );
            prodList.add(testDiscountedProduct);
            insert prodList;


            List<PricebookEntry> pbeList = new List<PricebookEntry>();
            PricebookEntry pbe;

            for(Product2 item : prodList) {

                pbe = new PricebookEntry(
                    Pricebook2Id = Test.getStandardPricebookId(),
                    Product2Id = item.Id,
                    UnitPrice = 200,
                    IsActive = true,
                    UseStandardPrice = false,
                    CurrencyIsoCode = 'USD'
                );
                pbeList.add(pbe);

                pbe = new PricebookEntry(
                    Pricebook2Id = testPriceBook.Id,
                    Product2Id = item.Id,
                    UnitPrice = 200,
                    IsActive = true,
                    UseStandardPrice = false,
                    Per_Line__c = false,
                    CurrencyIsoCode = 'USD'
                );
                pbeList.add(pbe);
            }
            insert pbeList;

            Test.startTest();

                List<QuoteLineItem> qliList = new List<QuoteLineItem>();

                for(PricebookEntry item : pbeList) {

                    if(item.PriceBook2Id == testSalesQuote.Pricebook2Id) {

                        QuoteLineItem qli = new QuoteLineItem(
                            QuoteId = testSalesQuote.Id,
                            Product2Id = item.Product2Id,
                            Quantity = 1,
                            UnitPrice = item.UnitPrice,
                            Discount_number__c = 2.5,
                            PricebookEntryId = item.Id
                        );
                        qliList.add(qli);
                    }
                }
                insert qliList;

                Quote reselectedSalesQuote = [SELECT Id, Approved_Status__c,
                        Approval_Type__c, Level_1_Approver__c,
                        Level_2_Approver__c, Level_3_Approver__c,
                        Level_4_Approver__c, Level_5_Approver__c, Auto_Renewal__c
                    FROM Quote
                    WHERE Id = :testSalesQuote.Id];

                System.assert(reselectedSalesQuote.Approved_Status__c == QuoteHelper.APPROVAL_STATUS_REQUIRED);
                System.assert(reselectedSalesQuote.Approval_Type__c == UserHelper.SEGMENT_LEADER_ROLE);
                System.assert(reselectedSalesQuote.Level_1_Approver__c == directManager.Id);
                System.assert(reselectedSalesQuote.Level_2_Approver__c == segmentLeager.Id);
                System.assertEquals(null, reselectedSalesQuote.Level_3_Approver__c);
                System.assertEquals(null, reselectedSalesQuote.Level_4_Approver__c);

                // approve quote
                reselectedSalesQuote.Approved_Status__c = QuoteHelper.APPROVAL_STATUS_APPROVED;
                update reselectedSalesQuote;

                // set SalesRep discount on DiscountedPhone product and verify that approved status is not changed(still approved), but approvalLevels was updated
                for(QuoteLineItem qli : qliList) {
                    if(qli.Product2Id == testDiscountedProduct.Id) {
                        qli.Discount_number__c = 0.5;
                    }
                }

                update qliList;

                Quote reselectedSalesQuote2 = [SELECT Id, Approved_Status__c,
                        Approval_Type__c, Level_1_Approver__c,
                        Level_2_Approver__c, Level_3_Approver__c,
                        Level_4_Approver__c, Level_5_Approver__c, Auto_Renewal__c
                    FROM Quote
                    WHERE Id = :testSalesQuote.Id];

                System.assert(reselectedSalesQuote2.Approved_Status__c == QuoteHelper.APPROVAL_STATUS_APPROVED);
                System.assert(reselectedSalesQuote2.Approval_Type__c == UserHelper.DIRECT_MANAGER_ROLE);
                System.assert(reselectedSalesQuote2.Level_1_Approver__c == directManager.Id);
                System.assertEquals(null, reselectedSalesQuote2.Level_2_Approver__c);
                System.assertEquals(null, reselectedSalesQuote2.Level_3_Approver__c);
                System.assertEquals(null, reselectedSalesQuote2.Level_4_Approver__c);

            Test.stopTest();
        }
    }

    @isTest
    static void test_approvedStatusOnQuotesWithSpecialTerms() {

        User testUser;
        User testUserManager;

        List<String> userNameList = new List<String>{
            createUserName('test'),
            createUserName('mngr')
        };

        for(User u : [select Id, LastName, Username, Hierarchy_Role__c, ManagerId, Email from User where UserName IN :userNameList]) {
            if(u.UserName == createUserName('test')) {
                testUser = u;
            }else if(u.UserName == createUserName('mngr')) {
                testUserManager = u;
            }
        }

        System.runAs(testUser) {

            List<GOA_V2__c> goasList = new List<GOA_V2__c>();

            GOA_V2__c goaItem = new GOA_V2__c(
                Name = '1',
                Quantity_Range__c = '1-99',
                Contract_Initial_Term_Range__c = '12-24',
                Sales_Rep__c = '0-0',
                Direct_Manager__c = '0.01-2.00',
                Segment_Leader__c = '2.01-3.00',
                SVP_WWS_Directs__c = '3.01-5.00',
                SVP_WWS__c = '5.01-99999999',
                Group__c = 'RC_Office_Standard_Monthly_Contract',
                Currency__c = 'USD'
            );
            goasList.add(goaItem);

            insert goasList;

            insert new Products_taken_into_account_in_GOA__c(
                Name = 'test',
                Quote_Record_Type__c = 'Sales Quote',
                Sub_Categories__c = 'Main, Contact Center'
            );

            List<SpecialTermsApprovers_V2__c> specialTermsList = new List<SpecialTermsApprovers_V2__c>();

            SpecialTermsApprovers_V2__c specialTermsItem = new SpecialTermsApprovers_V2__c(
                Name = 'STA1',
                Special_Terms__c = '3 Free Weeks of Service',
                Plan__c = 'Monthly - Contract',
                Initial_Term__c = '12-60',
                Last_Approver__c = 'Segment Leader'
            );
            specialTermsList.add(specialTermsItem);
            insert specialTermsList;


            Account testAccount = new Account(
                Name = 'Opty test account',
                Permitted_Brands__c = 'RingCentral'
            );
            insert testAccount;

            Opportunity testOpp = new Opportunity(
                AccountId = testAccount.Id,
                Name = 'MyTestOpportunity',
                Type = 'Existing Business',
                Brand_Name__c = 'RingCentral',
                Tier_Name__c = 'Office',
                StageName = '1. Qualify',
                CloseDate = System.today(),
                CurrencyIsoCode = 'USD'
            );
            insert testOpp;

            Pricebook2 testPriceBook = new Pricebook2(
                Name = 'Test Price Book',
                Description ='Test Price Book Products',
                IsActive = true,
                Plan__c = 'Monthly - Contract',
                Line_Range_Min__c = 5,
                Line_Range_Max__c = 10,
                CurrencyIsoCode = 'USD'
            );
            insert testPriceBook;

            Quote testSalesQuote = new Quote (
                Name = 'testSalesQuote',
                Auto_Renewal__c = true,
                OpportunityId = testOpp.Id,
                Special_Terms__c = '3 Free Weeks of Service',
                Pricebook2Id = testPriceBook.Id,
                RecordTypeId = QuoteHelper.RT_ID_SALES,
                CurrencyIsoCode = 'USD'
            );
            insert testSalesQuote;


            List<Product2> prodList = new List<Product2>();

            Product2 testProduct = new Product2(
                Name = 'test product',
                IsActive = true,
                GOA_Group_V2__c = 'RC_Office_Standard_Monthly_Contract',
                Sub_Category__c = 'Main'
            );
            prodList.add(testProduct);
            insert prodList;


            List<PricebookEntry> pbeList = new List<PricebookEntry>();
            PricebookEntry pbe;

            for(Product2 item : prodList) {

                pbe = new PricebookEntry(
                    Pricebook2Id = Test.getStandardPricebookId(),
                    Product2Id = item.Id,
                    UnitPrice = 200,
                    IsActive = true,
                    UseStandardPrice = false,
                    CurrencyIsoCode = 'USD'
                );
                pbeList.add(pbe);

                pbe = new PricebookEntry(
                    Pricebook2Id = testPriceBook.Id,
                    Product2Id = item.Id,
                    UnitPrice = 200,
                    IsActive = true,
                    UseStandardPrice = false,
                    Per_Line__c = false,
                    CurrencyIsoCode = 'USD'
                );
                pbeList.add(pbe);
            }
            insert pbeList;


            List<QuoteLineItem> qliList = new List<QuoteLineItem>();

            for(PricebookEntry item : pbeList) {

                if(item.PriceBook2Id == testSalesQuote.Pricebook2Id) {

                    QuoteLineItem qli = new QuoteLineItem(
                        QuoteId = testSalesQuote.Id,
                        Product2Id = item.Product2Id,
                        Quantity = 1,
                        UnitPrice = 200,
                        Discount_number__c = 2.5,
                        PricebookEntryId = item.Id
                    );
                    qliList.add(qli);
                }
            }

            Test.startTest();

                insert qliList;

                Quote reselectedSalesQuote = [SELECT Id, Approved_Status__c,
                                            Approval_Type__c, Level_1_Approver__c,
                                            Level_2_Approver__c, Level_3_Approver__c,
                                            Level_4_Approver__c, Auto_Renewal__c, Special_Terms__c
                                        FROM Quote
                                        WHERE Id = :testSalesQuote.Id];

                System.assert(reselectedSalesQuote.Approved_Status__c == QuoteHelper.APPROVAL_STATUS_REQUIRED);
                System.assert(reselectedSalesQuote.Approval_Type__c == UserHelper.SEGMENT_LEADER_ROLE);
                System.assert(reselectedSalesQuote.Level_1_Approver__c == testUserManager.Id);

                // delete discount on qli
                for(QuoteLineItem item : qliList) {
                    item.Discount_number__c = 0;
                }
                update qliList;

                // verify that approval is still 'Required'(we have not empty specialTerms on quote)
                Quote reselectedSalesQuote2 = [SELECT Id, Approved_Status__c,
                                            Approval_Type__c, Level_1_Approver__c,
                                            Level_2_Approver__c, Level_3_Approver__c,
                                            Level_4_Approver__c, Auto_Renewal__c, Special_Terms__c
                                        FROM Quote
                                        WHERE Id = :testSalesQuote.Id];

                System.assert(reselectedSalesQuote2.Approved_Status__c == QuoteHelper.APPROVAL_STATUS_REQUIRED);
                System.assert(reselectedSalesQuote2.Approval_Type__c == UserHelper.SEGMENT_LEADER_ROLE);
                System.assert(reselectedSalesQuote2.Level_1_Approver__c == testUserManager.Id);

            Test.stopTest();
        }
    }

    @isTest
    static void testHandleBillingWithContactCenter() {

        User testUser;
        User testUserManager;

        List<String> userNameList = new List<String>{
            createUserName('test'),
            createUserName('mngr')
        };

        for(User u : [select Id, LastName, Username, Hierarchy_Role__c, ManagerId, Email from User where UserName IN :userNameList]) {
            if(u.UserName == createUserName('test')) {
                testUser = u;
            }else if(u.UserName == createUserName('mngr')) {
                testUserManager = u;
            }
        }

        Triggers.switchOff();
        Group approversQueue = (Group) new GroupSelector()
            .selectQueueByName('Finance Approval Queue')
            .executeQuery()
            .get(0);

        insert new GroupMember(UserOrGroupId = testUserManager.Id, GroupId = approversQueue.Id);

        System.runAs(testUser) {

            upsert new RingCentralVariousSettings__c(
                CC_FSC_Approvers_Queues__c = 'Finance Approval Queue'
            );

            ByPassTrigger__c bpt = new ByPassTrigger__c(SetupOwnerId= Userinfo.getUserId(), Bypass_Account_Trigger__c = true, Bypass_Contact_Trigger__c = true);
            insert bpt;
            Triggers.switchOn();
            List<GOA_V2__c> goasList = new List<GOA_V2__c>();

            GOA_V2__c goaItem = new GOA_V2__c(
                Name = '1',
                Quantity_Range__c = '1-99',
                Contract_Initial_Term_Range__c = '',
                Sales_Rep__c = '0-0',
                Direct_Manager__c = '0.01-2.00',
                Segment_Leader__c = '2.01-3.00',
                SVP_WWS_Directs__c = '3.01-5.00',
                SVP_WWS__c = '5.01-99999999',
                Group__c = 'RC_Office_Standard_Monthly_Contract',
                Currency__c = 'USD'
            );
            goasList.add(goaItem);

            GOA_V2__c goaCCItem = new GOA_V2__c(
                Name = '2',
                Quantity_Range__c = '1-99',
                Contract_Initial_Term_Range__c = '',
                Sales_Rep__c = '0-0',
                Direct_Manager__c = '0.01-2.00',
                Segment_Leader__c = '2.01-3.00',
                SVP_WWS_Directs__c = '3.01-5.00',
                SVP_WWS__c = '5.01-99999999',
                Group__c = 'Contact_Center_test_product',
                Currency__c = 'USD'
            );
            goasList.add(goaCCItem);
            insert goasList;

            List<Products_taken_into_account_in_GOA__c> goaProductsList = new List<Products_taken_into_account_in_GOA__c>();

            Products_taken_into_account_in_GOA__c goaProduct = new Products_taken_into_account_in_GOA__c(
                Name = 'test main',
                Quote_Record_Type__c = 'Sales Quote',
                Sub_Categories__c = 'Main, Contact Center'
            );
            goaProductsList.add(goaProduct);

            Products_taken_into_account_in_GOA__c goaContactCenterProduct = new Products_taken_into_account_in_GOA__c(
                Name = 'test contact center',
                Quote_Record_Type__c = 'Contact Center Quote',
                Sub_Categories__c = 'Contact Center'
            );
            goaProductsList.add(goaContactCenterProduct);

            insert goaProductsList;

            Account testAccount = new Account(
                Name = 'Opty test account'
            );
            insert testAccount;

            Opportunity testOpp = new Opportunity(
                AccountId = testAccount.Id,
                Name = 'MyTestOpportunity',
                Type = 'Existing Business',
                CurrencyIsoCode = 'USD',
                StageName = '1. Qualify',
                Is_Billing_Opportunity__c = true
            );
            insert testOpp;

            Pricebook2 testPriceBook = new Pricebook2(
                Name = 'Test Price Book',
                Description ='Test Price Book Products',
                IsActive = true,
                Line_Range_Min__c = 5,
                Line_Range_Max__c = 10,
                CurrencyIsoCode = 'USD'
            );
            insert testPriceBook;

            List<Quote> quoteList = new List<Quote>();

            Quote testBillingQuote = new Quote(
                Name = 'testBillingQuote',
                OpportunityId = testOpp.Id,
                Pricebook2Id = testPriceBook.Id,
                RecordTypeId = QuoteHelper.RT_ID_BILLING,
                CurrencyIsoCode = 'USD'
            );
            quoteList.add(testBillingQuote);

            Quote testContactCenterQuote = new Quote(
                Name = 'testBillingQuote',
                OpportunityId = testOpp.Id,
                Pricebook2Id = testPriceBook.Id,
                RecordTypeId = QuoteHelper.RT_ID_CC,
                CurrencyIsoCode = 'USD'
            );
            quoteList.add(testContactCenterQuote);
            insert quoteList;

            List<Product2> prodList = new List<Product2>();

            Product2 testProduct = new Product2(
                Name = 'test product',
                IsActive = true,
                Sub_Category__c = 'Main',
                GOA_Group_V2__c = 'RC_Office_Standard_Monthly_Contract'
            );
            prodList.add(testProduct);

            Product2 testContactCenterProduct = new Product2(
                Name = 'test product',
                IsActive = true,
                Sub_Category__c = 'Contact Center',
                GOA_Group_V2__c = 'Contact_Center_test_product'
            );
            prodList.add(testContactCenterProduct);

            insert prodList;


            List<PricebookEntry> pbeList = new List<PricebookEntry>();
            PricebookEntry pbe;

            for(Product2 item : prodList) {

                pbe = new PricebookEntry(
                    Pricebook2Id = Test.getStandardPricebookId(),
                    Product2Id = item.Id,
                    UnitPrice = 200,
                    IsActive = true,
                    UseStandardPrice = false,
                    CurrencyIsoCode = 'USD'
                );
                pbeList.add(pbe);

                pbe = new PricebookEntry(
                    Pricebook2Id = testPriceBook.Id,
                    Product2Id = item.Id,
                    UnitPrice = 200,
                    IsActive = true,
                    UseStandardPrice = false,
                    Per_Line__c = false,
                    CurrencyIsoCode = 'USD'
                );
                pbeList.add(pbe);
            }
            insert pbeList;

            List<QuoteLineItem> qliList = new List<QuoteLineItem>();

            for(PricebookEntry item : pbeList) {
                if(item.PriceBook2Id == testBillingQuote.Pricebook2Id) {
                    QuoteLineItem qli = new QuoteLineItem(
                        QuoteId = testBillingQuote.Id,
                        Product2Id = item.Product2Id,
                        Quantity = 1,
                        UnitPrice = item.UnitPrice,
                        Discount_number__c = 0,
                        PricebookEntryId = item.Id
                    );
                    qliList.add(qli);

                    QuoteLineItem ccQli = new QuoteLineItem(
                        QuoteId = testContactCenterQuote.Id,
                        Product2Id = item.Product2Id,
                        Quantity = 1,
                        UnitPrice = item.UnitPrice,
                        Discount_number__c = 0,
                        PricebookEntryId = item.Id
                    );
                    qliList.add(ccQli);
                }
            }
            Triggers.switchOff();
            insert qliList;
            Triggers.switchOn();

            Test.startTest();

                List<Quote> reselectedQuotesList = [SELECT Id, Approved_Status__c,
                        Approval_Type__c, Level_1_Approver__c,
                        Level_2_Approver__c, Level_3_Approver__c,
                        Level_4_Approver__c, Auto_Renewal__c
                    FROM Quote
                    WHERE Id IN :new Set<Id>{testBillingQuote.Id, testContactCenterQuote.Id}];

                // if Quotes have no discounts - approved should be Approved
                for(Quote qt : reselectedQuotesList) {
                    System.assert(QuoteHelper.APPROVAL_STATUSES_NOT_REQUIRED.contains(qt.Approved_Status__c));
                }

                // set discounts for Contact Center Quote Line Items
                for(QuoteLineItem qli : qliList) {
                    if(qli.QuoteId == testContactCenterQuote.Id) {
                        qli.Discount_number__c = 2.5;
                    }
                }
                update qliList;

                // reselect Quotes and verify that Approved_Status__c become Required for both quotes
                reselectedQuotesList = [SELECT Id, Approved_Status__c,
                        Approval_Type__c, Level_1_Approver__c,
                        Level_2_Approver__c, Level_3_Approver__c,
                        Level_4_Approver__c, Auto_Renewal__c
                    FROM Quote
                    WHERE Id IN :new Set<Id>{testBillingQuote.Id, testContactCenterQuote.Id}];

                for(Quote qt : reselectedQuotesList) {
                    System.assertEquals(QuoteHelper.APPROVAL_STATUS_REQUIRED, qt.Approved_Status__c);

                    if(qt.Id == testBillingQuote.Id) {
                        System.assert(qt.Approval_Type__c == UserHelper.SEGMENT_LEADER_ROLE);
                        System.assert(qt.Level_1_Approver__c == testUserManager.Id);
                    }
                }
            Test.stopTest();
                /*
                // approve billing quote and verify Approved_Status__c become Approved on both Quotes
                for(Quote qt : reselectedQuotesList) {
                    if(qt.Id == testBillingQuote.Id) {
                        qt.Approved_Status__c = QuoteHelper.APPROVAL_STATUS_APPROVED;
                    }
                }
                update reselectedQuotesList;

                reselectedQuotesList = [SELECT Id, Approved_Status__c,
                        Approval_Type__c, Level_1_Approver__c,
                        Level_2_Approver__c, Level_3_Approver__c,
                        Level_4_Approver__c, Auto_Renewal__c
                    FROM Quote
                    WHERE Id IN :new Set<Id>{testBillingQuote.Id, testContactCenterQuote.Id}];

                for(Quote qt : reselectedQuotesList) {
                    System.assertEquals(QuoteHelper.APPROVAL_STATUS_APPROVED, qt.Approved_Status__c);
                }*/
        }
    }

    /**
    * 1. Create Quote with Initial Term and no Special Terms – Approval not required
    * 2. Update Special terms on Quote – Approval becomes required
    * 3. Update Discounts on QLIs – Approval is still required
    * 4. Remove discounts from QLIs – Approval should stay required
    */
    @isTest
    static void test_approvedStatusOnBillingWithSpecialTerms() {

        final String quotePackageInfo = '[{"id":"24","version":"1","packageInfo":{"catalogId":"24","version":"1"},'
            + '"productName":"Office","duration":"Monthly","edition":{"id":5,"name":"Premium"},'
            + '"offerType":"Regular","globalPackageLimits":[{"value":"50000","code":"MONTHLY_AMOUNT_LIMIT",'
            + '"name":"Monthly money amount limit","type":"Amount","scope":"BillingCycle","transactionType":"Any",'
            + '"target":"Global","exclusions":[{"target":"LicenseCategoryId","targetId":"AP"}],'
            + '"override":false}],"permissions":null}]';

        User testUser;
        User testUserManager;

        List<String> userNameList = new List<String>{
            createUserName('rSeg'),
            createUserName('dMan')
        };

        for (User u : (List<User>) new UserSelector()
                                    .selectUserByUsername(new List<Object>{userNameList})
                                    .selectFields( new List<String>{
                                        'Id',
                                        'LastName',
                                        'Username',
                                        'Hierarchy_Role__c',
                                        'ManagerId',
                                        'Email',
                                        'SegmentPicklist__c'
                                    })
                                    .executeQuery()
        ) {
            if (u.UserName == createUserName('rSeg')) {
                testUser = u;
            } else if (u.UserName == createUserName('dMan')) {
                testUserManager = u;
            }
        }

        System.runAs(testUser) {
            Triggers.switchOff();
            new SObjectBuilder(GOA_V2__c.sObjectType)
                .setFields(
                    new Map<SObjectField, Object> {
                        GOA_V2__c.Name => '1',
                        GOA_V2__c.Quantity_Range__c => '1-99',
                        GOA_V2__c.Contract_Initial_Term_Range__c => '',
                        GOA_V2__c.Sales_Rep__c => '0-0',
                        GOA_V2__c.Direct_Manager__c => '0.01-2.00',
                        GOA_V2__c.Segment_Leader__c => '2.01-3.00',
                        GOA_V2__c.SVP_WWS_Directs__c => '3.01-5.00',
                        GOA_V2__c.SVP_WWS__c => '5.01-99999999',
                        GOA_V2__c.Group__c => 'GOA_RC_Office',
                        GOA_V2__c.Currency__c => 'USD'
                    }
                )
                .create();

            new SObjectBuilder(Products_taken_into_account_in_GOA__c.sObjectType)
                .setFields(
                    new Map<SObjectField, Object> {
                        Products_taken_into_account_in_GOA__c.Name => 'test',
                        Products_taken_into_account_in_GOA__c.Quote_Record_Type__c => 'Sales Quote v2',
                        Products_taken_into_account_in_GOA__c.Sub_Categories__c => 'Main'
                    }
                )
                .create();

            new SObjectBuilder(SpecialTermsApprovers_V2__c.sObjectType)
                .setFields(
                    new Map<SObjectField, Object> {
                        SpecialTermsApprovers_V2__c.Name => 'STA1',
                        SpecialTermsApprovers_V2__c.Special_Terms__c => '3 Free Weeks of Service',
                        SpecialTermsApprovers_V2__c.Plan__c => 'Monthly',
                        SpecialTermsApprovers_V2__c.Initial_Term__c => '12-60',
                        SpecialTermsApprovers_V2__c.Last_Approver__c => 'Segment Leader'
                    }
                )
                .create();

            Opportunity testOpp = (Opportunity) new SObjectBuilder(Opportunity.sObjectType)
                .setFields(
                    new Map<SObjectField, Object> {
                        Opportunity.Name => ValueProviderBuilder.provideUniqueString('test opportunity'),
                        Opportunity.AccountId => ValueProviderBuilder.provideGenericParent(Account.sObjectType),
                        Opportunity.CloseDate => System.today()
                    }
                )
                .create()
                .getRecord();

            PriceBook2 testPriceBook = (PriceBook2) new SObjectBuilder(PriceBook2.sObjectType)
                .setFields(
                    new Map<SObjectField, Object> {
                        PriceBook2.Description =>'Test Price Book Products',
                        PriceBook2.IsActive => true,
                        PriceBook2.Plan__c => 'Monthly',
                        PriceBook2.Line_Range_Min__c => 5,
                        PriceBook2.Line_Range_Max__c => 10,
                        PriceBook2.CurrencyIsoCode => 'USD'
                    }
                )
                .create()
                .getRecord();

            Quote testSalesQuote = (Quote) new SObjectBuilder(Quote.sObjectType)
                .setFields(
                    new Map<SObjectField, Object> {
                        Quote.Auto_Renewal__c => true,
                        Quote.OpportunityId => testOpp.Id,
                        Quote.Initial_Term_months__c => '12',
                        Quote.Special_Terms__c => null,
                        Quote.Pricebook2Id => testPriceBook.Id,
                        Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                        Quote.CurrencyIsoCode => 'USD',
                        Quote.Package_Info__c => quotePackageInfo
                    })
                .create()
                .getRecord();

            Product2 testProduct = (Product2) new SObjectBuilder(Product2.sObjectType)
                .setFields(
                    new Map<SObjectField, Object> {
                        Product2.Name => 'test product',
                        Product2.IsActive => true,
                        Product2.GOA_Group_V3__c => '{"regular":"GOA_RC_Office","contracted":"GOA_RC_Office"}',
                        Product2.Sub_Category__c => 'Main'
                    }
                )
                .create()
                .getRecord();


            List<PricebookEntry> pbeList = (List<PricebookEntry>) new SObjectBuilder(PricebookEntry.sObjectType)
                .quantity(2)
                .setFields(
                    new Map<SObjectField, Object> {
                        PricebookEntry.Pricebook2Id => ValueProviderBuilder.ProvideList(
                            new List<Object> {
                                Test.getStandardPricebookId(),
                                testPriceBook.Id
                            }
                        ),
                        PricebookEntry.Product2Id => testProduct.Id,
                        PricebookEntry.UnitPrice => 200,
                        PricebookEntry.IsActive => true,
                        PricebookEntry.UseStandardPrice => false,
                        PricebookEntry.Per_Line__c => false,
                        PricebookEntry.CurrencyIsoCode => 'USD'
                    })
                .create()
                .getRecords();
            Triggers.switchOn();

            QuoteLineItem qli;

            for(PricebookEntry pbe : pbeList) {
                if(pbe.PriceBook2Id == testSalesQuote.Pricebook2Id) {
                    qli = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.SObjectType)
                        .setFields(
                            new Map<SObjectField, Object> {
                                QuoteLineItem.QuoteId => testSalesQuote.Id,
                                QuoteLineItem.Product2Id => pbe.Product2Id,
                                QuoteLineItem.Quantity => 1,
                                QuoteLineItem.UnitPrice => 200,
                                QuoteLineItem.Discount_number__c => 2.5,
                                QuoteLineItem.PricebookEntryId => pbe.Id
                            })
                        .build()
                        .getRecord();
                }
            }

            Test.startTest();
                testSalesQuote.Special_Terms__c = '3 Free Weeks of Service';
                Triggers.switchOff();
                Triggers.except('QuoteTriggerHelper.SetApprovalType');
                update testSalesQuote;
                Triggers.switchOn();

                List<Object> binds = new List<Object>{testSalesQuote.Id};
                QueryFactory selector = new QuoteSelector().selectQuoteById(binds);

                Quote reselectedSalesQuote1 = (Quote) selector.executeQuery()[0];

                System.assertEquals(reselectedSalesQuote1.Approved_Status__c, QuoteHelper.APPROVAL_STATUS_REQUIRED);
                System.assertEquals(reselectedSalesQuote1.Approval_Type__c, UserHelper.SEGMENT_LEADER_ROLE);
                System.assertEquals(reselectedSalesQuote1.Level_1_Approver__c, testUserManager.Id);

                Triggers.switchOff();
                Triggers.except('QuoteLineItemTriggerHelper.ManageQuotesMapStatic');
                Triggers.except('QuoteLineItemTriggerHelper.SetQuoteApprovalType');
                insert qli;
                Triggers.switchOn();

                Quote reselectedSalesQuote2 = (Quote) selector.executeQuery()[0];

                System.assertEquals(reselectedSalesQuote2.Approved_Status__c, QuoteHelper.APPROVAL_STATUS_REQUIRED);
                System.assertEquals(reselectedSalesQuote2.Approval_Type__c, UserHelper.SEGMENT_LEADER_ROLE);
                System.assertEquals(reselectedSalesQuote2.Level_1_Approver__c, testUserManager.Id);

                // delete discount on qli
                qli.Discount_number__c = 0;
                Triggers.switchOff();
                Triggers.except('QuoteLineItemTriggerHelper.ManageQuotesMapStatic');
                Triggers.except('QuoteLineItemTriggerHelper.SetQuoteApprovalType');
                update qli;
                Triggers.switchOn();

                Quote reselectedSalesQuote3 = (Quote) selector.executeQuery()[0];

                System.assertEquals(reselectedSalesQuote3.Approved_Status__c, QuoteHelper.APPROVAL_STATUS_REQUIRED);
                System.assertEquals(reselectedSalesQuote3.Approval_Type__c, UserHelper.SEGMENT_LEADER_ROLE);
                System.assertEquals(reselectedSalesQuote3.Level_1_Approver__c, testUserManager.Id);

            Test.stopTest();
        }
    }

    @isTest
    static void testHandleBillingWithoutContactCenter() {

        User testUser;
        User testUserManager;

        List<String> userNameList = new List<String>{
            createUserName('test'),
            createUserName('mngr')
        };

        for(User u : [select Id, LastName, Username, Hierarchy_Role__c, ManagerId, Email from User where UserName IN :userNameList]) {
            if(u.UserName == createUserName('test')) {
                testUser = u;
            }else if(u.UserName == createUserName('mngr')) {
                testUserManager = u;
            }
        }

        System.runAs(testUser) {

            List<GOA_V2__c> goasList = new List<GOA_V2__c>();

            GOA_V2__c goaItem = new GOA_V2__c(
                Name = '1',
                Quantity_Range__c = '1-99',
                Contract_Initial_Term_Range__c = '',
                Sales_Rep__c = '0-0',
                Direct_Manager__c = '0.01-2.00',
                Segment_Leader__c = '2.01-3.00',
                SVP_WWS_Directs__c = '3.01-5.00',
                SVP_WWS__c = '5.01-99999999',
                Group__c = 'RC_Office_Standard_Monthly_Contract',
                Currency__c = 'USD'
            );
            goasList.add(goaItem);
            insert goasList;

            List<Products_taken_into_account_in_GOA__c> goaProductsList = new List<Products_taken_into_account_in_GOA__c>();

            Products_taken_into_account_in_GOA__c goaProduct = new Products_taken_into_account_in_GOA__c(
                Name = 'test main',
                Quote_Record_Type__c = 'Sales Quote',
                Sub_Categories__c = 'Main, Contact Center'
            );
            goaProductsList.add(goaProduct);
            insert goaProductsList;

            Account testAccount = new Account(
                Name = 'Opty test account'
            );
            insert testAccount;

            Opportunity testOpp = new Opportunity(
                AccountId = testAccount.Id,
                Name = 'MyTestOpportunity',
                Type = 'Existing Business',
                CurrencyIsoCode = 'USD',
                StageName = '1. Qualify',
                Is_Billing_Opportunity__c = true
            );
            insert testOpp;

            Pricebook2 testPriceBook = new Pricebook2(
                Name = 'Test Price Book',
                Description ='Test Price Book Products',
                IsActive = true,
                Line_Range_Min__c = 5,
                Line_Range_Max__c = 10,
                CurrencyIsoCode = 'USD'
            );
            insert testPriceBook;

            List<Quote> quoteList = new List<Quote>();

            Quote testBillingQuote = new Quote(
                Name = 'testBillingQuote',
                OpportunityId = testOpp.Id,
                Pricebook2Id = testPriceBook.Id,
                RecordTypeId = QuoteHelper.RT_ID_BILLING,
                CurrencyIsoCode = 'USD'
            );
            quoteList.add(testBillingQuote);
            insert quoteList;

            List<Product2> prodList = new List<Product2>();

            Product2 testProduct = new Product2(
                Name = 'test product',
                IsActive = true,
                Sub_Category__c = 'Main',
                GOA_Group_V2__c = 'RC_Office_Standard_Monthly_Contract'
            );
            prodList.add(testProduct);
            insert prodList;


            List<PricebookEntry> pbeList = new List<PricebookEntry>();
            PricebookEntry pbe;

            for(Product2 item : prodList) {

                pbe = new PricebookEntry(
                    Pricebook2Id = Test.getStandardPricebookId(),
                    Product2Id = item.Id,
                    UnitPrice = 200,
                    IsActive = true,
                    UseStandardPrice = false,
                    CurrencyIsoCode = 'USD'
                );
                pbeList.add(pbe);

                pbe = new PricebookEntry(
                    Pricebook2Id = testPriceBook.Id,
                    Product2Id = item.Id,
                    UnitPrice = 200,
                    IsActive = true,
                    UseStandardPrice = false,
                    Per_Line__c = false,
                    CurrencyIsoCode = 'USD'
                );
                pbeList.add(pbe);
            }
            insert pbeList;


            Test.startTest();

                List<QuoteLineItem> qliList = new List<QuoteLineItem>();

                for(PricebookEntry item : pbeList) {
                    if(item.PriceBook2Id == testBillingQuote.Pricebook2Id) {
                        QuoteLineItem qli = new QuoteLineItem(
                            QuoteId = testBillingQuote.Id,
                            Product2Id = item.Product2Id,
                            Quantity = 1,
                            UnitPrice = item.UnitPrice,
                            Discount_number__c = 0,
                            PricebookEntryId = item.Id
                        );
                        qliList.add(qli);
                    }
                }
                insert qliList;

                List<Quote> reselectedQuotesList = [SELECT Id, Approved_Status__c,
                        Approval_Type__c, Level_1_Approver__c,
                        Level_2_Approver__c, Level_3_Approver__c,
                        Level_4_Approver__c, Auto_Renewal__c
                    FROM Quote
                    WHERE Id IN :new Set<Id>{testBillingQuote.Id}];

                // if Quotes have no discounts - approved should be Approved
                for(Quote qt : reselectedQuotesList) {
                    System.assert(QuoteHelper.APPROVAL_STATUSES_NOT_REQUIRED.contains(qt.Approved_Status__c));
                }

                // set discounts for Quote Line Items
                for(QuoteLineItem qli : qliList) {
                    qli.Discount_number__c = 2.5;
                    qli.PackageInfo__c = TestDataGenerator.TEST_PACKAGE_INFO;
                    qli.Package_Info_QLI__c = TestDataGenerator.TEST_PACKAGE_INFO;
                }
                update qliList;

                // reselect Quotes and verify that Approved_Status__c become Required
                reselectedQuotesList = [SELECT Id, Approved_Status__c,
                        Approval_Type__c, Level_1_Approver__c,
                        Level_2_Approver__c, Level_3_Approver__c,
                        Level_4_Approver__c, Auto_Renewal__c
                    FROM Quote
                    WHERE Id = :testBillingQuote.Id];

                for(Quote qt : reselectedQuotesList) {
                    System.assertEquals(QuoteHelper.APPROVAL_STATUS_REQUIRED, qt.Approved_Status__c);
                    System.assert(qt.Approval_Type__c == UserHelper.SEGMENT_LEADER_ROLE);
                    System.assert(qt.Level_1_Approver__c == testUserManager.Id);
                }
            Test.stopTest();
        }
    }

    @isTest
    static void testChangeQuantityOnQuoteWithStatusRequired() {

        // quote should not become 'Approved'(should remain 'Required') if it was Required and quote line item quantity was changed
        // (related with defect B-7823(https://rc.my.salesforce.com/a2034000004FJx5))

        User testUser;
        User testUserManager;

        List<String> userNameList = new List<String>{
            createUserName('test'),
            createUserName('mngr')
        };

        for(User u : [select Id, LastName, Username, Hierarchy_Role__c, ManagerId, Email from User where UserName IN :userNameList]) {
            if(u.UserName == createUserName('test')) {
                testUser = u;
            }else if(u.UserName == createUserName('mngr')) {
                testUserManager = u;
            }
        }

        System.runAs(testUser) {

            List<GOA_V2__c> goasList = new List<GOA_V2__c>();

            GOA_V2__c goaItem = new GOA_V2__c(
                Name = '1',
                Quantity_Range__c = '1-99',
                Contract_Initial_Term_Range__c = '',
                Sales_Rep__c = '0-0',
                Direct_Manager__c = '0.01-2.00',
                Segment_Leader__c = '2.01-3.00',
                SVP_WWS_Directs__c = '3.01-5.00',
                SVP_WWS__c = '5.01-99999999',
                Group__c = 'RC_Office_Standard_Monthly_Contract',
                Currency__c = 'USD'
            );
            goasList.add(goaItem);

            insert goasList;

            insert new Products_taken_into_account_in_GOA__c(
                Name = 'test',
                Quote_Record_Type__c = 'Sales Quote',
                Sub_Categories__c = 'Main, Contact Center'
            );


            Account testAccount = new Account(
                Name = 'Opty test account',
                Permitted_Brands__c = 'RingCentral'
            );
            insert testAccount;

            Opportunity testOpp = new Opportunity(
                AccountId = testAccount.Id,
                Name = 'MyTestOpportunity',
                Type = 'Existing Business',
                Brand_Name__c = 'RingCentral',
                Tier_Name__c = 'Office',
                StageName = '1. Qualify',
                CloseDate = System.today(),
                CurrencyIsoCode = 'USD'
            );
            insert testOpp;

            Pricebook2 testPriceBook = new Pricebook2(
                Name = 'Test Price Book',
                Description ='Test Price Book Products',
                IsActive = true,
                Line_Range_Min__c = 5,
                Line_Range_Max__c = 10,
                CurrencyIsoCode = 'USD'
            );
            insert testPriceBook;

            Quote testSalesQuote = new Quote (
                Name = 'testSalesQuote',
                Auto_Renewal__c = true,
                OpportunityId = testOpp.Id,
                Pricebook2Id = testPriceBook.Id,
                RecordTypeId = QuoteHelper.RT_ID_SALES,
                CurrencyIsoCode = 'USD'
            );
            insert testSalesQuote;


            List<Product2> prodList = new List<Product2>();

            Product2 testProduct1 = new Product2(
                Name = 'test product 1',
                IsActive = true,
                Sub_Category__c = 'Main',
                GOA_Group_V2__c = 'RC_Office_Standard_Monthly_Contract'
            );
            prodList.add(testProduct1);

            Product2 testProduct2 = new Product2(
                Name = 'test product 2',
                IsActive = true,
                Sub_Category__c = 'Main',
                GOA_Group_V2__c = 'RC_Office_Standard_Monthly_Contract'
            );
            prodList.add(testProduct2);

            insert prodList;


            List<PricebookEntry> pbeList = new List<PricebookEntry>();
            PricebookEntry pbe;

            for(Product2 item : prodList) {

                pbe = new PricebookEntry(
                    Pricebook2Id = Test.getStandardPricebookId(),
                    Product2Id = item.Id,
                    UnitPrice = 200,
                    IsActive = true,
                    UseStandardPrice = false,
                    CurrencyIsoCode = 'USD'
                );
                pbeList.add(pbe);

                pbe = new PricebookEntry(
                    Pricebook2Id = testPriceBook.Id,
                    Product2Id = item.Id,
                    UnitPrice = 200,
                    IsActive = true,
                    UseStandardPrice = false,
                    Per_Line__c = false,
                    CurrencyIsoCode = 'USD'
                );
                pbeList.add(pbe);
            }
            insert pbeList;


            Test.startTest();

                List<QuoteLineItem> qliList = new List<QuoteLineItem>();

                for(PricebookEntry item : pbeList) {

                    if(item.PriceBook2Id == testSalesQuote.Pricebook2Id) {

                        QuoteLineItem qli = new QuoteLineItem(
                            QuoteId = testSalesQuote.Id,
                            Product2Id = item.Product2Id,
                            Quantity = 10,
                            UnitPrice = item.UnitPrice,
                            PricebookEntryId = item.Id
                        );
                        // set discount for one product
                        if(qli.Product2Id == testProduct1.Id) {
                            qli.Discount_number__c = 2.5;
                        }
                        qliList.add(qli);
                    }
                }
                insert qliList;

                Quote reselectedSalesQuote = [SELECT Id, Approved_Status__c,
                                            Approval_Type__c, Level_1_Approver__c,
                                            Level_2_Approver__c, Level_3_Approver__c,
                                            Level_4_Approver__c, Auto_Renewal__c
                                        FROM Quote
                                        WHERE Id = :testSalesQuote.Id];

                System.assert(reselectedSalesQuote.Approved_Status__c == QuoteHelper.APPROVAL_STATUS_REQUIRED);
                System.assert(reselectedSalesQuote.Approval_Type__c == UserHelper.SEGMENT_LEADER_ROLE);
                System.assert(reselectedSalesQuote.Level_1_Approver__c == testUserManager.Id);

                // change quantity on product without discounts
                for(QuoteLineItem item : qliList) {
                    if(item.Product2Id == testProduct2.Id) {
                        item.Quantity = 9;
                    }
                }
                update qliList;

            Test.stopTest();

            Quote reselectedSalesQuote2 = [SELECT Id, Approved_Status__c,
                                            Approval_Type__c, Level_1_Approver__c,
                                            Level_2_Approver__c, Level_3_Approver__c,
                                            Level_4_Approver__c, Auto_Renewal__c
                                        FROM Quote
                                        WHERE Id = :testSalesQuote.Id];

            System.assert(reselectedSalesQuote2.Approved_Status__c == QuoteHelper.APPROVAL_STATUS_REQUIRED);
            System.assert(reselectedSalesQuote2.Approval_Type__c == UserHelper.SEGMENT_LEADER_ROLE);
            System.assert(reselectedSalesQuote2.Level_1_Approver__c == testUserManager.Id);
        }
    }

    @isTest
    static void testRemoveDiscountOnQuoteWithStatusRequired() {

        // quote should not become 'Approved'(should remain 'Required') if it was Required and quote line item discount was removed(set to 0)
        // (related with defect B-7823(https://rc.my.salesforce.com/a2034000004FJx5))

        User testUser;
        User testUserManager;

        List<String> userNameList = new List<String>{
            createUserName('test'),
            createUserName('mngr')
        };

        for(User u : [select Id, LastName, Username, Hierarchy_Role__c, ManagerId, Email from User where UserName IN :userNameList]) {
            if(u.UserName == createUserName('test')) {
                testUser = u;
            }else if(u.UserName == createUserName('mngr')) {
                testUserManager = u;
            }
        }

        System.runAs(testUser) {

            List<GOA_V2__c> goasList = new List<GOA_V2__c>();

            GOA_V2__c goaItem = new GOA_V2__c(
                Name = '1',
                Quantity_Range__c = '1-99',
                Contract_Initial_Term_Range__c = '',
                Sales_Rep__c = '0-0',
                Direct_Manager__c = '0.01-2.00',
                Segment_Leader__c = '2.01-3.00',
                SVP_WWS_Directs__c = '3.01-5.00',
                SVP_WWS__c = '5.01-99999999',
                Group__c = 'RC_Office_Standard_Monthly_Contract',
                Currency__c = 'USD'
            );
            goasList.add(goaItem);

            insert goasList;

            insert new Products_taken_into_account_in_GOA__c(
                Name = 'test',
                Quote_Record_Type__c = 'Sales Quote',
                Sub_Categories__c = 'Main, Contact Center'
            );


            Account testAccount = new Account(
                Name = 'Opty test account',
                Permitted_Brands__c = 'RingCentral'
            );
            insert testAccount;

            Opportunity testOpp = new Opportunity(
                AccountId = testAccount.Id,
                Name = 'MyTestOpportunity',
                Type = 'Existing Business',
                Brand_Name__c = 'RingCentral',
                Tier_Name__c = 'Office',
                StageName = '1. Qualify',
                CloseDate = System.today(),
                CurrencyIsoCode = 'USD'
            );
            insert testOpp;

            Pricebook2 testPriceBook = new Pricebook2(
                Name = 'Test Price Book',
                Description ='Test Price Book Products',
                IsActive = true,
                Line_Range_Min__c = 5,
                Line_Range_Max__c = 10,
                CurrencyIsoCode = 'USD'
            );
            insert testPriceBook;

            Quote testSalesQuote = new Quote (
                Name = 'testSalesQuote',
                Auto_Renewal__c = true,
                OpportunityId = testOpp.Id,
                Pricebook2Id = testPriceBook.Id,
                RecordTypeId = QuoteHelper.RT_ID_SALES,
                CurrencyIsoCode = 'USD'
            );
            insert testSalesQuote;


            List<Product2> prodList = new List<Product2>();

            Product2 testProduct1 = new Product2(
                Name = 'test product 1',
                IsActive = true,
                Sub_Category__c = 'Main',
                GOA_Group_V2__c = 'RC_Office_Standard_Monthly_Contract'
            );
            prodList.add(testProduct1);

            Product2 testProduct2 = new Product2(
                Name = 'test product 2',
                IsActive = true,
                Sub_Category__c = 'Main',
                GOA_Group_V2__c = 'RC_Office_Standard_Monthly_Contract'
            );
            prodList.add(testProduct2);

            insert prodList;


            List<PricebookEntry> pbeList = new List<PricebookEntry>();
            PricebookEntry pbe;

            for(Product2 item : prodList) {

                pbe = new PricebookEntry(
                    Pricebook2Id = Test.getStandardPricebookId(),
                    Product2Id = item.Id,
                    UnitPrice = 200,
                    IsActive = true,
                    UseStandardPrice = false,
                    CurrencyIsoCode = 'USD'
                );
                pbeList.add(pbe);

                pbe = new PricebookEntry(
                    Pricebook2Id = testPriceBook.Id,
                    Product2Id = item.Id,
                    UnitPrice = 200,
                    IsActive = true,
                    UseStandardPrice = false,
                    Per_Line__c = false,
                    CurrencyIsoCode = 'USD'
                );
                pbeList.add(pbe);
            }
            insert pbeList;


            Test.startTest();

                List<QuoteLineItem> qliList = new List<QuoteLineItem>();

                for(PricebookEntry item : pbeList) {

                    if(item.PriceBook2Id == testSalesQuote.Pricebook2Id) {

                        QuoteLineItem qli = new QuoteLineItem(
                            QuoteId = testSalesQuote.Id,
                            Product2Id = item.Product2Id,
                            Quantity = 10,
                            Discount_number__c = 2.5,
                            UnitPrice = item.UnitPrice,
                            PricebookEntryId = item.Id
                        );
                        qliList.add(qli);
                    }
                }
                insert qliList;

                Quote reselectedSalesQuote = [SELECT Id, Approved_Status__c,
                                            Approval_Type__c, Level_1_Approver__c,
                                            Level_2_Approver__c, Level_3_Approver__c,
                                            Level_4_Approver__c, Auto_Renewal__c
                                        FROM Quote
                                        WHERE Id = :testSalesQuote.Id];

                System.assert(reselectedSalesQuote.Approved_Status__c == QuoteHelper.APPROVAL_STATUS_REQUIRED);
                System.assert(reselectedSalesQuote.Approval_Type__c == UserHelper.SEGMENT_LEADER_ROLE);
                System.assert(reselectedSalesQuote.Level_1_Approver__c == testUserManager.Id);

                // remove discount for 1 product
                for(QuoteLineItem item : qliList) {
                    if(item.Product2Id == testProduct1.Id) {
                        item.Discount_number__c = 0;
                    }
                }
                update qliList;

            Test.stopTest();

            Quote reselectedSalesQuote2 = [SELECT Id, Approved_Status__c,
                                            Approval_Type__c, Level_1_Approver__c,
                                            Level_2_Approver__c, Level_3_Approver__c,
                                            Level_4_Approver__c, Auto_Renewal__c
                                        FROM Quote
                                        WHERE Id = :testSalesQuote.Id];

            System.assert(reselectedSalesQuote2.Approved_Status__c == QuoteHelper.APPROVAL_STATUS_REQUIRED);
            System.assert(reselectedSalesQuote2.Approval_Type__c == UserHelper.SEGMENT_LEADER_ROLE);
            System.assert(reselectedSalesQuote2.Level_1_Approver__c == testUserManager.Id);
        }
    }

    @isTest
    static void test_handleQuote_withSegment() {

        User testUser;
        User testUserManager;

        Triggers.switchOff();
        List<String> userNameList = new List<String>{
            createUserName('rSeg'),
            createUserName('dMan')
        };

        for(User u : (List<User>) new UserSelector()
                                    .selectUserByUsername(new List<Object>{userNameList})
                                    .selectFields( new List<String>{
                                        'Id',
                                        'LastName',
                                        'Username',
                                        'Hierarchy_Role__c',
                                        'ManagerId',
                                        'Email',
                                        'SegmentPicklist__c'
                                    })
                                    .executeQuery()
        ) {
            if(u.UserName == createUserName('rSeg')) {
                testUser = u;
            }else if(u.UserName == createUserName('dMan')) {
                testUserManager = u;
            }
        }

        System.runAs(testUser) {

            new SObjectBuilder(GOA_V2__c.sObjectType)
                .setFields(
                    new Map<SObjectField, Object> {
                        GOA_V2__c.Name => '1',
                        GOA_V2__c.Quantity_Range__c => '1-99',
                        GOA_V2__c.Contract_Initial_Term_Range__c => '',
                        GOA_V2__c.Sales_Rep__c => '0-0',
                        GOA_V2__c.Direct_Manager__c => '0.01-2.00',
                        GOA_V2__c.Segment_Leader__c => '2.01-3.00',
                        GOA_V2__c.SVP_WWS_Directs__c => '3.01-5.00',
                        GOA_V2__c.SVP_WWS__c => '5.01-99999999',
                        GOA_V2__c.Group__c => 'RC_Office_Standard_Monthly_Contract',
                        GOA_V2__c.Currency__c => 'USD',
                        GOA_V2__c.Segment__c => UserHelper.SEGMENT_SOHO
                    }
                )
                .create();

            new SObjectBuilder(Products_taken_into_account_in_GOA__c.sObjectType)
                .setFields(
                    new Map<SObjectField, Object> {
                        Products_taken_into_account_in_GOA__c.Name => 'test',
                        Products_taken_into_account_in_GOA__c.Quote_Record_Type__c => 'Sales Quote',
                        Products_taken_into_account_in_GOA__c.Sub_Categories__c => 'Main, Contact Center'
                    }
                )
                .create();


            Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.sObjectType)
                .setFields(
                    new Map<SObjectField, Object> {
                        Opportunity.AccountId => ValueProviderBuilder.provideGenericParent(Account.sObjectType),
                        Opportunity.CloseDate => System.today()
                    }
                )
                .create()
                .getRecord();

            PriceBook2 pb = (PriceBook2) new SObjectBuilder(PriceBook2.sObjectType)
                .setFields(
                    new Map<SObjectField, Object> {
                        PriceBook2.Description => ValueProviderBuilder.provideUniqueString(),
                        PriceBook2.IsActive => true
                    }
                )
                .create()
                .getRecord();

            Product2 serviceProd = (Product2) new SObjectBuilder(Product2.sObjectType)
                .setFields(
                    new Map<SObjectField, Object> {
                        Product2.Family => Product2Helper.FAMILY_SERVICE,
                        Product2.Charge_Term__c => Product2Helper.CHARGE_TERM_ANNUAL,
                        Product2.Description => ValueProviderBuilder.provideUniqueString(),
                        Product2.Sub_Category__c => 'Main',
                        Product2.GOA_Group_V2__c => 'RC_Office_Standard_Monthly_Contract'
                    }
                )
                .create()
                .getRecord();

            List<PricebookEntry> pbeList = (List<PricebookEntry>) new SObjectBuilder(PricebookEntry.sObjectType)
                .quantity(2)
                .setFields(
                    new Map<SObjectField, Object> {
                        PricebookEntry.Pricebook2Id => ValueProviderBuilder.ProvideList(
                            new List<Object> {
                                Test.getStandardPricebookId(),
                                pb.Id
                            }
                        ),
                        PricebookEntry.Product2Id => serviceProd.Id,
                        PricebookEntry.UnitPrice => 200,
                        PricebookEntry.IsActive => true,
                        PricebookEntry.UseStandardPrice => false
                    })
                .create()
                .getRecords();

            Triggers.switchOn();
            Quote q = (Quote) new SObjectBuilder(Quote.sObjectType)
                .setFields(
                    new Map<SObjectField, Object> {
                        Quote.Pricebook2Id => pb.Id,
                        Quote.OpportunityId => opp.Id,
                        Quote.RecordTypeId => QuoteHelper.RT_ID_SALES
                    }
                )
                .create()
                .getRecord();

            Test.startTest();

                List<QuoteLineItem> qliList = new List<QuoteLineItem>();

                for(PricebookEntry pbe : pbeList) {

                    if(pbe.PriceBook2Id == q.Pricebook2Id) {

                        new SObjectBuilder(QuoteLineItem.SObjectType)
                            .setFields(
                                new Map<SObjectField, Object> {
                                    QuoteLineItem.QuoteId => q.Id,
                                    QuoteLineItem.Product2Id => pbe.Product2Id,
                                    QuoteLineItem.Quantity => 1,
                                    QuoteLineItem.UnitPrice => pbe.UnitPrice,
                                    QuoteLineItem.Discount_number__c => 2.5,
                                    QuoteLineItem.PricebookEntryId => pbe.Id
                                })
                            .create();
                    }
                }

            Test.stopTest();

            Quote reselectedSalesQuote = [
                SELECT Approved_Status__c, Approval_Type__c, Level_1_Approver__c
                FROM Quote
                WHERE Id = :q.Id
            ];

            System.assertEquals(QuoteHelper.APPROVAL_STATUS_REQUIRED, reselectedSalesQuote.Approved_Status__c);
            System.assertEquals(UserHelper.SEGMENT_LEADER_ROLE, reselectedSalesQuote.Approval_Type__c);
            System.assertEquals(testUserManager.Id, reselectedSalesQuote.Level_1_Approver__c);

        }
    }

    @isTest
    static void test_handleQuote_goaWithoutSegment() {

        User testUser;
        User testUserManager;

        Triggers.switchOff();
        List<String> userNameList = new List<String>{
            createUserName('rSeg'),
            createUserName('dMan')
        };

        for(User u : (List<User>) new UserSelector()
                                    .selectUserByUsername(new List<Object>{userNameList})
                                    .selectFields( new List<String>{
                                        'Id',
                                        'LastName',
                                        'Username',
                                        'Hierarchy_Role__c',
                                        'ManagerId',
                                        'Email',
                                        'SegmentPicklist__c'
                                    })
                                    .executeQuery()
        ) {
            if(u.UserName == createUserName('rSeg')) {
                testUser = u;
            }else if(u.UserName == createUserName('dMan')) {
                testUserManager = u;
            }
        }

        System.runAs(testUser) {

            new SObjectBuilder(GOA_V2__c.sObjectType)
                .setFields(
                    new Map<SObjectField, Object> {
                        GOA_V2__c.Name => '1',
                        GOA_V2__c.Quantity_Range__c => '1-99',
                        GOA_V2__c.Contract_Initial_Term_Range__c => '',
                        GOA_V2__c.Sales_Rep__c => '0-0',
                        GOA_V2__c.Direct_Manager__c => '0.01-2.00',
                        GOA_V2__c.Segment_Leader__c => '2.01-3.00',
                        GOA_V2__c.SVP_WWS_Directs__c => '3.01-5.00',
                        GOA_V2__c.SVP_WWS__c => '5.01-99999999',
                        GOA_V2__c.Group__c => 'RC_Office_Standard_Monthly_Contract',
                        GOA_V2__c.Currency__c => 'USD',
                        GOA_V2__c.Segment__c => UserHelper.SEGMENT_SOHO
                    }
                )
                .create();

            new SObjectBuilder(Products_taken_into_account_in_GOA__c.sObjectType)
                .setFields(
                    new Map<SObjectField, Object> {
                        Products_taken_into_account_in_GOA__c.Name => 'test',
                        Products_taken_into_account_in_GOA__c.Products_taken_into_account_in_GOA__c.Quote_Record_Type__c => 'Sales Quote',
                        Products_taken_into_account_in_GOA__c.Products_taken_into_account_in_GOA__c.Sub_Categories__c => 'Main, Contact Center'
                    }
                )
                .create();


            Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.sObjectType)
                .setFields(
                    new Map<SObjectField, Object> {
                        Opportunity.AccountId => ValueProviderBuilder.provideGenericParent(Account.sObjectType),
                        Opportunity.CloseDate => System.today()
                    }
                )
                .create()
                .getRecord();

            PriceBook2 pb = (PriceBook2) new SObjectBuilder(PriceBook2.sObjectType)
                .setFields(
                    new Map<SObjectField, Object> {
                        PriceBook2.Description => ValueProviderBuilder.provideUniqueString(),
                        PriceBook2.IsActive => true
                    }
                )
                .create()
                .getRecord();

            Product2 serviceProd = (Product2) new SObjectBuilder(Product2.sObjectType)
                .setFields(
                    new Map<SObjectField, Object> {
                        Product2.Family => Product2Helper.FAMILY_SERVICE,
                        Product2.Charge_Term__c => Product2Helper.CHARGE_TERM_ANNUAL,
                        Product2.Description => ValueProviderBuilder.provideUniqueString(),
                        Product2.Sub_Category__c => 'Main',
                        Product2.GOA_Group_V2__c => 'RC_Office_Standard_Monthly_Contract'
                    }
                )
                .create()
                .getRecord();

            List<PricebookEntry> pbeList = (List<PricebookEntry>) new SObjectBuilder(PricebookEntry.sObjectType)
                .quantity(2)
                .setFields(
                    new Map<SObjectField, Object> {
                        PricebookEntry.Pricebook2Id => ValueProviderBuilder.ProvideList(
                            new List<Object> {
                                Test.getStandardPricebookId(),
                                pb.Id
                            }
                        ),
                        PricebookEntry.Product2Id => serviceProd.Id,
                        PricebookEntry.UnitPrice => 200,
                        PricebookEntry.IsActive => true,
                        PricebookEntry.UseStandardPrice => false
                    })
                .create()
                .getRecords();

            Triggers.switchOn();

            Quote q = (Quote) new SObjectBuilder(Quote.sObjectType)
                .setFields(
                    new Map<SObjectField, Object> {
                        Quote.Pricebook2Id => pb.Id,
                        Quote.OpportunityId => opp.Id,
                        Quote.RecordTypeId => QuoteHelper.RT_ID_SALES
                    }
                )
                .create()
                .getRecord();

            Test.startTest();

                List<QuoteLineItem> qliList = new List<QuoteLineItem>();

                for(PricebookEntry pbe : pbeList) {

                    if(pbe.PriceBook2Id == q.Pricebook2Id) {

                        new SObjectBuilder(QuoteLineItem.SObjectType)
                            .setFields(
                                new Map<SObjectField, Object> {
                                    QuoteLineItem.QuoteId => q.Id,
                                    QuoteLineItem.Product2Id => pbe.Product2Id,
                                    QuoteLineItem.Quantity => 1,
                                    QuoteLineItem.UnitPrice => pbe.UnitPrice,
                                    QuoteLineItem.Discount_number__c => 2.5,
                                    QuoteLineItem.PricebookEntryId => pbe.Id
                                })
                            .create();
                    }
                }

            Test.stopTest();

            Quote reselectedSalesQuote = [
                SELECT Approved_Status__c, Approval_Type__c, Level_1_Approver__c
                FROM Quote
                WHERE Id = :q.Id
            ];

            System.assertEquals(QuoteHelper.APPROVAL_STATUS_REQUIRED, reselectedSalesQuote.Approved_Status__c);
            System.assertEquals(UserHelper.SEGMENT_LEADER_ROLE, reselectedSalesQuote.Approval_Type__c);
        }
    }

    @isTest
    static void test_handleQuote_oppOwnerWithoutSegment() {

        User testUser;
        User testUserManager;

        Triggers.switchOff();
        List<String> userNameList = new List<String>{
            createUserName('rSeg'),
            createUserName('dMan')
        };

        for(User u : (List<User>) new UserSelector()
                                    .selectUserByUsername(new List<Object>{userNameList})
                                    .selectFields( new List<String>{
                                        'Id',
                                        'LastName',
                                        'Username',
                                        'Hierarchy_Role__c',
                                        'ManagerId',
                                        'Email',
                                        'SegmentPicklist__c'
                                    })
                                    .executeQuery()
        ) {
            if(u.UserName == createUserName('rSeg')) {
                testUser = u;
            }else if(u.UserName == createUserName('dMan')) {
                testUserManager = u;
            }
        }

        System.runAs(testUser) {

            new SObjectBuilder(GOA_V2__c.sObjectType)
                .setFields(
                    new Map<SObjectField, Object> {
                        GOA_V2__c.Name => '1',
                        GOA_V2__c.Quantity_Range__c => '1-99',
                        GOA_V2__c.Contract_Initial_Term_Range__c => '',
                        GOA_V2__c.Sales_Rep__c => '0-0',
                        GOA_V2__c.Direct_Manager__c => '0.01-2.00',
                        GOA_V2__c.Segment_Leader__c => '2.01-3.00',
                        GOA_V2__c.SVP_WWS_Directs__c => '3.01-5.00',
                        GOA_V2__c.SVP_WWS__c => '5.01-99999999',
                        GOA_V2__c.Group__c => 'RC_Office_Standard_Monthly_Contract',
                        GOA_V2__c.Currency__c => 'USD',
                        GOA_V2__c.Segment__c => UserHelper.SEGMENT_SOHO
                    }
                )
                .create();

            new SObjectBuilder(Products_taken_into_account_in_GOA__c.sObjectType)
                .setFields(
                    new Map<SObjectField, Object> {
                        Products_taken_into_account_in_GOA__c.Name => 'test',
                        Products_taken_into_account_in_GOA__c.Products_taken_into_account_in_GOA__c.Quote_Record_Type__c => 'Sales Quote',
                        Products_taken_into_account_in_GOA__c.Products_taken_into_account_in_GOA__c.Sub_Categories__c => 'Main, Contact Center'
                    }
                )
                .create();


            Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.sObjectType)
                .setFields(
                    new Map<SObjectField, Object> {
                        Opportunity.AccountId => ValueProviderBuilder.provideGenericParent(Account.sObjectType),
                        Opportunity.CloseDate => System.today()
                    }
                )
                .create()
                .getRecord();

            PriceBook2 pb = (PriceBook2) new SObjectBuilder(PriceBook2.sObjectType)
                .setFields(
                    new Map<SObjectField, Object> {
                        PriceBook2.Description => ValueProviderBuilder.provideUniqueString(),
                        PriceBook2.IsActive => true
                    }
                )
                .create()
                .getRecord();

            Product2 serviceProd = (Product2) new SObjectBuilder(Product2.sObjectType)
                .setFields(
                    new Map<SObjectField, Object> {
                        Product2.Family => Product2Helper.FAMILY_SERVICE,
                        Product2.Charge_Term__c => Product2Helper.CHARGE_TERM_ANNUAL,
                        Product2.Description => ValueProviderBuilder.provideUniqueString(),
                        Product2.Sub_Category__c => 'Main',
                        Product2.GOA_Group_V2__c => 'RC_Office_Standard_Monthly_Contract'
                    }
                )
                .create()
                .getRecord();

            List<PricebookEntry> pbeList = (List<PricebookEntry>) new SObjectBuilder(PricebookEntry.sObjectType)
                .quantity(2)
                .setFields(
                    new Map<SObjectField, Object> {
                        PricebookEntry.Pricebook2Id => ValueProviderBuilder.ProvideList(
                            new List<Object> {
                                Test.getStandardPricebookId(),
                                pb.Id
                            }
                        ),
                        PricebookEntry.Product2Id => serviceProd.Id,
                        PricebookEntry.UnitPrice => 200,
                        PricebookEntry.IsActive => true,
                        PricebookEntry.UseStandardPrice => false
                    })
                .create()
                .getRecords();

            Triggers.switchOn();
            Quote q = (Quote) new SObjectBuilder(Quote.sObjectType)
                .setFields(
                    new Map<SObjectField, Object> {
                        Quote.Pricebook2Id => pb.Id,
                        Quote.OpportunityId => opp.Id,
                        Quote.RecordTypeId => QuoteHelper.RT_ID_SALES
                    }
                )
                .create()
                .getRecord();

            Test.startTest();

                List<QuoteLineItem> qliList = new List<QuoteLineItem>();

                for(PricebookEntry pbe : pbeList) {

                    if(pbe.PriceBook2Id == q.Pricebook2Id) {

                        new SObjectBuilder(QuoteLineItem.SObjectType)
                            .setFields(
                                new Map<SObjectField, Object> {
                                    QuoteLineItem.QuoteId => q.Id,
                                    QuoteLineItem.Product2Id => pbe.Product2Id,
                                    QuoteLineItem.Quantity => 1,
                                    QuoteLineItem.UnitPrice => pbe.UnitPrice,
                                    QuoteLineItem.Discount_number__c => 2.5,
                                    QuoteLineItem.PricebookEntryId => pbe.Id
                                })
                            .create();
                    }
                }

            Test.stopTest();

            Quote reselectedSalesQuote = [
                SELECT Approved_Status__c, Approval_Type__c, Level_1_Approver__c
                FROM Quote
                WHERE Id = :q.Id
            ];

            System.assertEquals(QuoteHelper.APPROVAL_STATUS_REQUIRED, reselectedSalesQuote.Approved_Status__c);
            System.assertEquals(UserHelper.SEGMENT_LEADER_ROLE, reselectedSalesQuote.Approval_Type__c);
        }
    }

    @isTest
    static void test_handleQuote_noGoaGroupForProduct() {

        User testUser;
        User testUserManager;

        Triggers.switchOff();
        List<String> userNameList = new List<String>{
            createUserName('rSeg'),
            createUserName('dMan')
        };

        for(User u : (List<User>) new UserSelector()
                                    .selectUserByUsername(new List<Object>{userNameList})
                                    .selectFields( new List<String>{
                                        'Id',
                                        'LastName',
                                        'Username',
                                        'Hierarchy_Role__c',
                                        'ManagerId',
                                        'Email',
                                        'SegmentPicklist__c'
                                    })
                                    .executeQuery()
        ) {
            if(u.UserName == createUserName('rSeg')) {
                testUser = u;
            }else if(u.UserName == createUserName('dMan')) {
                testUserManager = u;
            }
        }

        System.runAs(testUser) {

            new SObjectBuilder(GOA_V2__c.sObjectType)
                .setFields(
                    new Map<SObjectField, Object> {
                        GOA_V2__c.Name => '1',
                        GOA_V2__c.Quantity_Range__c => '1-99',
                        GOA_V2__c.Contract_Initial_Term_Range__c => '',
                        GOA_V2__c.Sales_Rep__c => '0-0',
                        GOA_V2__c.Direct_Manager__c => '0.01-2.00',
                        GOA_V2__c.Segment_Leader__c => '2.01-3.00',
                        GOA_V2__c.SVP_WWS_Directs__c => '3.01-5.00',
                        GOA_V2__c.SVP_WWS__c => '5.01-99999999',
                        GOA_V2__c.Group__c => 'Refurbished_Phones',
                        GOA_V2__c.Currency__c => 'USD',
                        GOA_V2__c.Segment__c => UserHelper.SEGMENT_SOHO
                    }
                )
                .create();

            new SObjectBuilder(Products_taken_into_account_in_GOA__c.sObjectType)
                .setFields(
                    new Map<SObjectField, Object> {
                        Products_taken_into_account_in_GOA__c.Name => 'test',
                        Products_taken_into_account_in_GOA__c.Products_taken_into_account_in_GOA__c.Quote_Record_Type__c => 'Sales Quote',
                        Products_taken_into_account_in_GOA__c.Products_taken_into_account_in_GOA__c.Sub_Categories__c => 'Main, Contact Center'
                    }
                )
                .create();


            Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.sObjectType)
                .setFields(
                    new Map<SObjectField, Object> {
                        Opportunity.AccountId => ValueProviderBuilder.provideGenericParent(Account.sObjectType),
                        Opportunity.CloseDate => System.today()
                    }
                )
                .create()
                .getRecord();

            PriceBook2 pb = (PriceBook2) new SObjectBuilder(PriceBook2.sObjectType)
                .setFields(
                    new Map<SObjectField, Object> {
                        PriceBook2.Description => ValueProviderBuilder.provideUniqueString(),
                        PriceBook2.IsActive => true
                    }
                )
                .create()
                .getRecord();

            Product2 serviceProd = (Product2) new SObjectBuilder(Product2.sObjectType)
                .setFields(
                    new Map<SObjectField, Object> {
                        Product2.Family => Product2Helper.FAMILY_SERVICE,
                        Product2.Charge_Term__c => Product2Helper.CHARGE_TERM_ANNUAL,
                        Product2.Description => ValueProviderBuilder.provideUniqueString(),
                        Product2.Sub_Category__c => 'Main',
                        Product2.GOA_Group_V2__c => 'RC_Office_Standard_Monthly_Contract'
                    }
                )
                .create()
                .getRecord();

            List<PricebookEntry> pbeList = (List<PricebookEntry>) new SObjectBuilder(PricebookEntry.sObjectType)
                .quantity(2)
                .setFields(
                    new Map<SObjectField, Object> {
                        PricebookEntry.Pricebook2Id => ValueProviderBuilder.ProvideList(
                            new List<Object> {
                                Test.getStandardPricebookId(),
                                pb.Id
                            }
                        ),
                        PricebookEntry.Product2Id => serviceProd.Id,
                        PricebookEntry.UnitPrice => 200,
                        PricebookEntry.IsActive => true,
                        PricebookEntry.UseStandardPrice => false
                    })
                .create()
                .getRecords();

            Triggers.switchOn();
            Quote q = (Quote) new SObjectBuilder(Quote.sObjectType)
                .setFields(
                    new Map<SObjectField, Object> {
                        Quote.Pricebook2Id => pb.Id,
                        Quote.OpportunityId => opp.Id,
                        Quote.RecordTypeId => QuoteHelper.RT_ID_SALES
                    }
                )
                .create()
                .getRecord();

            Test.startTest();

                List<QuoteLineItem> qliList = new List<QuoteLineItem>();

                for(PricebookEntry pbe : pbeList) {

                    if(pbe.PriceBook2Id == q.Pricebook2Id) {

                        new SObjectBuilder(QuoteLineItem.SObjectType)
                            .setFields(
                                new Map<SObjectField, Object> {
                                    QuoteLineItem.QuoteId => q.Id,
                                    QuoteLineItem.Product2Id => pbe.Product2Id,
                                    QuoteLineItem.Quantity => 1,
                                    QuoteLineItem.UnitPrice => pbe.UnitPrice,
                                    QuoteLineItem.Discount_number__c => 2.5,
                                    QuoteLineItem.PricebookEntryId => pbe.Id
                                })
                            .create();
                    }
                }

            Test.stopTest();

            Quote reselectedSalesQuote = [
                SELECT Approved_Status__c, Approval_Type__c, Level_1_Approver__c
                FROM Quote
                WHERE Id = :q.Id
            ];

            System.assertEquals(QuoteHelper.APPROVAL_STATUS_REQUIRED, reselectedSalesQuote.Approved_Status__c);
            System.assertEquals(UserHelper.SVP_WWS_DIRECTS_ROLE, reselectedSalesQuote.Approval_Type__c);
        }
    }

    @isTest
    static void testSpecialTermsChangedAnnualContractBillingQuoteRequiresApproval() {
        Quote qt;

        final String packageInfo = '[{"id":"7","version":"1","packageInfo":{"catalogId":"7","version":"1"},'
            + '"productName":"Meetings","duration":"Annual","edition":{"id":3,"name":"Essentials"},'
            + '"contract":{"id":"a8f3B0000000BHEQA2","extId":"Office","billingId":null},'
            + '"offerType":"Regular","globalPackageLimits":[{"value":"2000","code":"MONTHLY_AMOUNT_LIMIT",'
            + '"name":"Monthly money amount limit","type":"Amount","scope":"BillingCycle","transactionType":"Any",'
            + '"target":"Global","override":false}],"permissions":null}]';

        User managerLevel2 = (User) new SObjectBuilder(User.SObjectType)
            .setField(User.Hierarchy_Role__c, UserHelper.DIRECT_MANAGER_ROLE)
            .create()
            .getRecord();

        User managerLevel1 = (User) new SObjectBuilder(User.SObjectType)
            .setField(User.Hierarchy_Role__c, UserHelper.SALES_REP_ROLE)
            .setField(User.ManagerId, managerLevel2.Id)
            .create()
            .getRecord();

        User testUser = (User) new SObjectBuilder(User.SObjectType)
            .setField(User.ManagerId, managerLevel1.Id)
            .setField(User.Hierarchy_Role__c, UserHelper.SALES_REP_ROLE)
            .create()
            .getRecord();

        new SObjectBuilder(SpecialTermsApprovers_V2__c.SObjectType)
            .setField(SpecialTermsApprovers_V2__c.Name, 'STA95')
            .setField(SpecialTermsApprovers_V2__c.Special_Terms__c, QuoteHelper.FREE_MONTH_3)
            .setField(SpecialTermsApprovers_V2__c.Plan__c, 'Annual - Contract')
            .setField(SpecialTermsApprovers_V2__c.Initial_Term__c, '12-99999')
            .setField(SpecialTermsApprovers_V2__c.Last_Approver__c, UserHelper.DIRECT_MANAGER_ROLE)
            .create();

        System.runAs(testUser) {
            Account testAccount = (Account) new SobjectBuilder(Account.SObjectType)
                .setField(Account.Name, 'Opty test account')
                .create()
                .getRecord();

            Opportunity testOpp = (Opportunity) new SobjectBuilder(Opportunity.SObjectType)
                .setField(Opportunity.AccountId, testAccount.Id)
                .setField(Opportunity.Name, 'TestOpportunity')
                .setField(Opportunity.Brand_Name__c, 'RingCentral')
                .setField(Opportunity.Tier_Name__c, 'Office')
                .setField(Opportunity.StageName, '1. Qualify')
                .setField(Opportunity.CloseDate, System.today())
                .setField(Opportunity.CurrencyIsoCode, 'USD')
                .create()
                .getRecord();

            qt = (Quote) new SObjectBuilder(Quote.SObjectType)
                .setField(Quote.OpportunityId, testOpp.Id)
                .setField(Quote.Package_Info__c, packageInfo)
                .setField(Quote.Initial_Term_months__c, '12')
                .setField(Quote.Approved_Status__c, QuoteHelper.APPROVAL_STATUS_NOT_REQUIRED)
                .setField(Quote.RecordTypeId, QuoteHelper.RT_ID_BILLING)
                .create()
                .getRecord();

            qt.Special_Terms__c = QuoteHelper.FREE_MONTH_3;
            update qt;
        }

        List<Quote> updatedQuotes = (List<Quote>) new QuoteSelector()
            .selectQuoteById(new List<Object>{new Set<Id>{qt.Id}})
            .executeQuery();

        System.assertEquals(QuoteHelper.APPROVAL_STATUS_REQUIRED, updatedQuotes.get(0).Approved_Status__c,
            'Approval status should be required when special terms were changed');
        System.assertEquals(UserHelper.DIRECT_MANAGER_ROLE, updatedQuotes.get(0).Approval_Type__c,
            'Wrong Approval Type set on Quote when special terms were changed');
        System.assertEquals(managerLevel2.Id, updatedQuotes.get(0).Level_1_Approver__c,
            'Wrong Level 1 Approval set on Quote when special terms were changed');
    }

    @isTest
    static void verifyGOAsFilteredByBrand() {
        final String FILTER_SELECT_ASSERTION_MESSAGE = 'Filter should select GOA records with existing brands';
        final String FILTER_NOT_SELECT_ASSERTION_MESSAGE = 'Filter shouldn\'t select GOA records with not existing brands';
        List<GOA_V2__c> goas =  new SObjectBuilder(GOA_V2__c.sObjectType)
                                    .setFields(
                                        new Map<SObjectField, Object> {
                                            GOA_V2__c.Name => ValueProviderBuilder.ProvideList(new List<String> {'1','2','3','4'}),
                                            GOA_V2__c.Brand__c => ValueProviderBuilder.ProvideList(new List<String> { OpportunityHelper.BRAND_RINGCENTRAL,
                                                                                                                      OpportunityHelper.BRAND_AVAYA,
                                                                                                                      OpportunityHelper.BRAND_AVAYA,
                                                                                                                      null })
                                        }
                                    )
                                    .quantity(4)
                                    .build()
                                    .getRecords();

        System.assertEquals(QuoteApprovals.filterGOAsByBrand(OpportunityHelper.BRAND_RINGCENTRAL, goas).size(), 1,
                            FILTER_SELECT_ASSERTION_MESSAGE);
        System.assertEquals(QuoteApprovals.filterGOAsByBrand(OpportunityHelper.BRAND_RINGCENTRAL, goas)[0].Name, '1',
                            FILTER_SELECT_ASSERTION_MESSAGE);
        System.assertEquals(QuoteApprovals.filterGOAsByBrand(OpportunityHelper.BRAND_AVAYA, goas).size(), 2,
                            FILTER_SELECT_ASSERTION_MESSAGE);
        System.assertEquals(QuoteApprovals.filterGOAsByBrand(OpportunityHelper.BRAND_AVAYA, goas)[0].Name, '2',
                            FILTER_SELECT_ASSERTION_MESSAGE);
        System.assertEquals(QuoteApprovals.filterGOAsByBrand(OpportunityHelper.BRAND_AVAYA, goas)[1].Name, '3',
                            FILTER_SELECT_ASSERTION_MESSAGE);
        System.assertEquals(QuoteApprovals.filterGOAsByBrand(OpportunityHelper.BRAND_TELUS, goas).size(), 1,
                            FILTER_NOT_SELECT_ASSERTION_MESSAGE);
        System.assertEquals(QuoteApprovals.filterGOAsByBrand(OpportunityHelper.BRAND_TELUS, goas)[0].Name, '4',
                            FILTER_NOT_SELECT_ASSERTION_MESSAGE);
    }

    @isTest
    static void testVerifyApprovedStatusForPOCQuotesIsNotRequired() {

        new SObjectBuilder(GOA_V2__c.sObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    GOA_V2__c.Name => '1',
                    GOA_V2__c.Quantity_Range__c => '1-99',
                    GOA_V2__c.Contract_Initial_Term_Range__c => '',
                    GOA_V2__c.Sales_Rep__c => '0-0',
                    GOA_V2__c.Direct_Manager__c => '0.01-2.00',
                    GOA_V2__c.Segment_Leader__c => '2.01-3.00',
                    GOA_V2__c.SVP_WWS_Directs__c => '3.01-5.00',
                    GOA_V2__c.SVP_WWS__c => '5.01-99999999',
                    GOA_V2__c.Group__c => 'RC_Office_Standard_Monthly_Contract',
                    GOA_V2__c.Currency__c => 'USD'
                }
            )
            .create();

        new SObjectBuilder(Products_taken_into_account_in_GOA__c.sObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    Products_taken_into_account_in_GOA__c.Name => 'test',
                    Products_taken_into_account_in_GOA__c.Quote_Record_Type__c => 'Sales Quote v2',
                    Products_taken_into_account_in_GOA__c.Sub_Categories__c => 'Main'
                }
            )
            .create();

        User managerLevel2 = (User) new SObjectBuilder(User.SObjectType)
            .setField(User.Hierarchy_Role__c, UserHelper.DIRECT_MANAGER_ROLE)
            .create()
            .getRecord();

        User managerLevel1 = (User) new SObjectBuilder(User.SObjectType)
            .setField(User.Hierarchy_Role__c, UserHelper.SALES_REP_ROLE)
            .setField(User.ManagerId, managerLevel2.Id)
            .create()
            .getRecord();

        User testUser = (User) new SObjectBuilder(User.SObjectType)
            .setField(User.ManagerId, managerLevel1.Id)
            .setField(User.Hierarchy_Role__c, UserHelper.SALES_REP_ROLE)
            .create()
            .getRecord();

        Quote pocQuote;
        Quote pocQuote2;

        System.runAs(testUser) {

            Product2 serviceProd = (Product2) new SObjectBuilder(Product2.sObjectType)
                .setFields(
                    new Map<SObjectField, Object> {
                        Product2.Family => Product2Helper.FAMILY_SERVICE,
                        Product2.Charge_Term__c => Product2Helper.CHARGE_TERM_ANNUAL,
                        Product2.Description => ValueProviderBuilder.provideUniqueString(),
                        Product2.Sub_Category__c => 'Main',
                        Product2.GOA_Group_V2__c => 'RC_Office_Standard_Monthly_Contract'
                    }
                )
                .create()
                .getRecord();

            PriceBook2 pb = (PriceBook2) new SObjectBuilder(PriceBook2.sObjectType)
                .setFields(
                    new Map<SObjectField, Object> {
                        PriceBook2.Description => ValueProviderBuilder.provideUniqueString(),
                        PriceBook2.IsActive => true
                    }
                )
                .create()
                .getRecord();

            List<PricebookEntry> pbeList = (List<PricebookEntry>) new SObjectBuilder(PricebookEntry.sObjectType)
                .quantity(2)
                .setFields(
                    new Map<SObjectField, Object> {
                        PricebookEntry.Pricebook2Id => ValueProviderBuilder.ProvideList(
                            new List<Object> {
                                Test.getStandardPricebookId(),
                                pb.Id
                            }
                        ),
                        PricebookEntry.Product2Id => serviceProd.Id,
                        PricebookEntry.UnitPrice => 200,
                        PricebookEntry.IsActive => true,
                        PricebookEntry.UseStandardPrice => false
                    })
                .create()
                .getRecords();

            Opportunity testOpp = (Opportunity) new SobjectBuilder(Opportunity.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        Opportunity.AccountId => ValueProviderBuilder.provideGenericParent(Account.sObjectType),
                        Opportunity.Is_Billing_Opportunity__c => true,
                        Opportunity.Name => 'TestBillingOpportunity',
                        Opportunity.Brand_Name__c => 'RingCentral',
                        Opportunity.Tier_Name__c => 'Office',
                        Opportunity.StageName => '1. Qualify',
                        Opportunity.CloseDate => System.today(),
                        Opportunity.CurrencyIsoCode => 'USD'
                    })
                .create()
                .getRecord();

            pocQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        Quote.OpportunityId => testOpp.Id,
                        Quote.Initial_Term_months__c => '12',
                        Quote.Approved_Status__c => QuoteHelper.APPROVAL_STATUS_NOT_REQUIRED,
                        Quote.RecordTypeId => QuoteHelper.RT_ID_POC,
                        Quote.PriceBook2Id => pb.Id,
                        Quote.isPrimary__c => true
                    }
                )
                .create()
                .getRecord();

            pocQuote2 = (Quote) new SObjectBuilder(Quote.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        Quote.OpportunityId => testOpp.Id,
                        Quote.Initial_Term_months__c => '12',
                        Quote.Approved_Status__c => QuoteHelper.APPROVAL_STATUS_NOT_REQUIRED,
                        Quote.RecordTypeId => QuoteHelper.RT_ID_POC,
                        Quote.PriceBook2Id => pb.Id,
                        Quote.isPrimary__c => false
                    }
                )
                .create()
                .getRecord();

            Test.startTest();

                for(PricebookEntry pbe : pbeList) {

                    if(pbe.PriceBook2Id == pb.Id) {

                        new SObjectBuilder(QuoteLineItem.SObjectType)
                            .setFields(
                                new Map<SObjectField, Object> {
                                    QuoteLineItem.QuoteId => pocQuote.Id,
                                    QuoteLineItem.Product2Id => pbe.Product2Id,
                                    QuoteLineItem.Quantity => 1,
                                    QuoteLineItem.UnitPrice => pbe.UnitPrice,
                                    QuoteLineItem.Discount_number__c => 2.5,
                                    QuoteLineItem.PricebookEntryId => pbe.Id
                                })
                            .create();

                        new SObjectBuilder(QuoteLineItem.SObjectType)
                            .setFields(
                                new Map<SObjectField, Object> {
                                    QuoteLineItem.QuoteId => pocQuote2.Id,
                                    QuoteLineItem.Product2Id => pbe.Product2Id,
                                    QuoteLineItem.Quantity => 1,
                                    QuoteLineItem.UnitPrice => pbe.UnitPrice,
                                    QuoteLineItem.Discount_number__c => 2.5,
                                    QuoteLineItem.PricebookEntryId => pbe.Id
                                })
                            .create();
                    }
                }

                pocQuote2.isPrimary__c = true;
                update pocQuote2;

            Test.stopTest();
        }

        List<Quote> updatedQuotes = (List<Quote>) new QuoteSelector()
            .selectQuoteById(new List<Object>{new Set<Id>{pocQuote.Id, pocQuote2.Id}})
            .executeQuery();

        for (Quote qt : updatedQuotes) {
            System.assertEquals(QuoteHelper.APPROVAL_STATUS_NOT_REQUIRED, qt.Approved_Status__c,
                'Approval status should be "Not required" for POC Quotes');
        }
    }

    @isTest
    static void testApprovalsForNewContractTermFlow() {

        new SobjectBuilder(Feature_Toggle__c.SObjectType)
            .setField(Feature_Toggle__c.Enable_new_Contract_Term_flow__c, true)
            .create();

        Opportunity testOpp = (Opportunity) new SobjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.AccountId => ValueProviderBuilder.provideGenericParent(Account.sObjectType),
                    Opportunity.Name => ValueProviderBuilder.provideUniqueString('testOpportunity'),
                    Opportunity.Is_Billing_Opportunity__c => true,
                    Opportunity.CloseDate => System.today(),
                    Opportunity.CurrencyIsoCode => 'USD'
                })
            .create()
            .getRecord();

        Quote qt = NGBSTestDataGenerator.createQuote(testOpp.Id);

        Test.startTest();

            qt.Initial_Term_months__c = '1';
            update qt;

            Quote updatedQuote = (Quote) new QuoteSelector()
                .selectQuoteById(new List<Object>{ qt.Id })
                .executeQuery()
                .get(0);

            System.assertEquals(
                QuoteHelper.APPROVAL_STATUS_REQUIRED,
                updatedQuote.Approved_Status__c,
                'if Initial_Term_months__c less than 12 months Approved_Status__c ' +
                'should be "Required", but got "' + qt.Approved_Status__c + '"'
            );

            System.assertEquals(
                QuoteHelper.FINANCE_QUEUE_APPROVAL_TYPE,
                updatedQuote.Approval_Type__c,
                'if Initial_Term_months__c less than 12 months Approval_Type__c ' +
                'should be "Finance Queue", but got "' + qt.Approval_Type__c + '"'
            );

        Test.stopTest();
    }

    @isTest
    static void testProcessDownsell() {

        new SObjectBuilder(InContractDownsell__c.sObjectType)
                .setField(InContractDownsell__c.Threshold__c, -100)
                .create();

        Account testAccount = (Account) new SObjectBuilder(Account.SObjectType)
                .setFields(
                        new Map<SObjectField, Object>{
                                Account.Name => 'Test Account',
                                Account.Active_Sales_Agreement__c => '123778899'
                        }
                )
                .build()
                .getRecord();

        Opportunity testOpportunity = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
                .setFields(
                        new Map<SObjectField, Object>{
                                Opportunity.Name => 'Test Opportunity',
                                Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL,
                                Opportunity.Tier_Name__c => QuoteHelper.NGBS_OFFICE_PRODUCT,
                                Opportunity.Type => OpportunityHelper.OPPORTUNITY_TYPE_EX_BUSINESS
                        }
                )
                .build()
                .getRecord();

                testOpportunity.Account = testAccount;

        Quote testQuote = (Quote) new SObjectBuilder(Quote.sObjectType)
                .setFields(
                        new Map<SObjectField, Object>{
                                Quote.Id => ValueProviderBuilder.provideDummyId(Quote.SObjectType),
                                Quote.Delta_MRR__c => -120,
                                Quote.CurrencyIsoCode => 'USD'
                        }
                )
                .build()
                .getRecord();

        testQuote.Opportunity = testOpportunity;

        QuoteLineItem testQuoteLineItem = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.sObjectType)
                .setFields(
                        new Map<SObjectField, Object>{
                                QuoteLineItem.QuoteId => testQuote.Id
                        }
                )
                .build()
                .getRecord();

        testQuoteLineItem.Quote = testQuote;
        Map<Id, List<QuoteLineItem>>  quoteIdToQliListMap = new Map<Id, List<QuoteLineItem>>{
                testQuote.Id => new List<QuoteLineItem>{testQuoteLineItem}
        };

        List<Quote> result = QuoteApprovals.processDownsell(new List<Quote>{testQuote}, quoteIdToQliListMap);

        System.assertEquals(
                QuoteHelper.APPROVAL_STATUS_REQUIRED,
                testQuote.Approved_Status__c,
                'if Delta_MRR__c less than InContractDownsell__c.Threshold__c Approved_Status__c ' +
                        'should be "Required", but got "' + testQuote.Approved_Status__c + '"'
        );

        System.assertEquals(
                GroupHelper.APPROVAL_DOWNSELL_QUEUE,
                testQuote.DownsellApprover__c,
                'if Delta_MRR__c less than InContractDownsell__c.Threshold__c DownsellApprover__c ' +
                        'should be "In Contract Downsell", but got "' + testQuote.DownsellApprover__c + '"'
        );

        System.assertEquals(
                QuoteHelper.DOWNSELL_QUEUE_APPORVAL_TYPE,
                testQuote.Approval_Type__c,
                'if Delta_MRR__c less than InContractDownsell__c.Threshold__c DownsellApprover__c ' +
                        'should be "In Contract Downsell", but got "' + testQuote.Approval_Type__c + '"'
        );
    }

    @isTest
    static void testProcessDownsellProServ() {

        new SObjectBuilder(InContractDownsell__c.sObjectType)
            .setField(InContractDownsell__c.Threshold__c, -100)
            .create();

        Account testAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => 'Test Account'
                }
            )
            .create()
            .getRecord();

        Proserv_Project__c proservProject = (Proserv_Project__c) new SObjectBuilder(Proserv_Project__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Proserv_Project__c.Account__c => testAccount.Id
            })
            .create()
            .getRecord();

        Opportunity testOpp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.Name => 'Test Opportunity',
                    Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL,
                    Opportunity.Tier_Name__c => QuoteHelper.NGBS_OFFICE_PRODUCT,
                    Opportunity.Type => OpportunityHelper.OPPORTUNITY_TYPE_EX_BUSINESS
                }
            )
            .build()
            .getRecord();
            testOpp.Account = testAccount;


        Order testOrder = (Order) new SObjectBuilder(Order.SObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    Order.AccountId => testAccount.Id,
                    Order.Status => OrderHelper.STATUS_NEW,
                    Order.PriceBook2Id => Test.getStandardPricebookId(),
                    Order.EffectiveDate => System.today(),
                    Order.RecordTypeId => OrderHelper.RT_ID_PROSERV,
                    Order.Booked_ProServ_OTP__c => 1000,
                    Order.ProServProject__c => proservProject.Id,
                    Order.Type => OrderHelper.TYPE_CHANGE_ORDER
                }
            )
            .create()
            .getRecord();

        Opportunity testOpportunity = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.Name => 'Test Opportunity',
                    Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL,
                    Opportunity.Type => OpportunityHelper.OPPORTUNITY_TYPE_EX_BUSINESS,
                    Opportunity.Tier_Name__c => 'Professional Services',
                    Opportunity.Parent_Order__c => testOrder.Id
                }
            )
            .build()
            .getRecord();
            testOpportunity.Account = testAccount;

        Quote testQuote = (Quote) new SObjectBuilder(Quote.sObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Quote.Id => ValueProviderBuilder.provideDummyId(Quote.SObjectType),
                    Quote.Delta_MRR__c => -120,
                    Quote.CurrencyIsoCode => 'USD',
                    Quote.Approved_Status__c => QuoteHelper.APPROVAL_STATUS_APPROVED
                }
            )
            .build()
            .getRecord();
            testQuote.Opportunity = testOpportunity;

        QuoteLineItem testQuoteLineItem = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.sObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    QuoteLineItem.QuoteId => testQuote.Id
                }
            )
            .build()
            .getRecord();

        testQuoteLineItem.Quote = testQuote;
        Map<Id, List<QuoteLineItem>>  quoteIdToQliListMap = new Map<Id, List<QuoteLineItem>>{
            testQuote.Id => new List<QuoteLineItem>{testQuoteLineItem}
        };

        List<Quote> result = QuoteApprovals.processDownsell(new List<Quote>{testQuote}, quoteIdToQliListMap);

        System.assertEquals(
            QuoteHelper.APPROVAL_STATUS_APPROVED,
            testQuote.Approved_Status__c,
            'For ProServ Change Order Approved_Status__c should be "Approved", but got "' + testQuote.Approved_Status__c + '"'
        );
    }

    // @isTest
    // static void testFreeShippingProcess() {

    //     User testUser;
    //     User testUserManager;

    //     List<String> userNameList = new List<String>{
    //         createUserName('test'),
    //         createUserName('mngr')
    //     };

    //     for(User u : [select Id, LastName, Username, Hierarchy_Role__c, ManagerId, Email from User where UserName IN :userNameList]) {
    //         if(u.UserName == createUserName('test')) {
    //             testUser = u;
    //         }else if(u.UserName == createUserName('mngr')) {
    //             testUserManager = u;
    //         }
    //     }

    //     System.runAs(testUser) {

    //         Test.startTest();

    //         new SObjectBuilder(Feature_Toggle__c.sObjectType)
    //             .setField(Feature_Toggle__c.Shipping_Tab_New_Business__c, false)
    //             .create();

    //         Triggers.switchOff();

    //         Account testAccount = (Account) new SObjectBuilder(Account.sObjectType)
    //             .setFields(
    //                 new Map<SObjectField, Object>{
    //                     Account.Name => 'Opty test account',
    //                     Account.Permitted_Brands__c => 'RingCentral'
    //                 }
    //             )
    //             .create()
    //             .getRecord();

    //         Opportunity testOpp = (Opportunity) new SObjectBuilder(Opportunity.sObjectType)
    //             .setFields(
    //                 new Map<SObjectField, Object>{
    //                     Opportunity.AccountId => testAccount.Id,
    //                     Opportunity.Name => 'MyTestOpportunity',
    //                     Opportunity.Type => 'Existing Business',
    //                     Opportunity.Brand_Name__c => 'RingCentral',
    //                     Opportunity.Tier_Name__c => 'Office',
    //                     Opportunity.StageName => '1. Qualify',
    //                     Opportunity.CloseDate => System.today(),
    //                     Opportunity.CurrencyIsoCode => 'USD'
    //                 }
    //             )
    //             .create()
    //             .getRecord();

    //         Pricebook2 testPriceBook = (Pricebook2) new SObjectBuilder(Pricebook2.sObjectType)
    //             .setFields(
    //                 new Map<SObjectField, Object>{
    //                     Pricebook2.Name => 'Test Price Book',
    //                     Pricebook2.Description =>'Test Price Book Products',
    //                     Pricebook2.IsActive => true,
    //                     Pricebook2.Line_Range_Min__c => 5,
    //                     Pricebook2.Line_Range_Max__c => 10,
    //                     Pricebook2.CurrencyIsoCode => 'USD'
    //                 }
    //             )
    //             .create()
    //             .getRecord();

    //         Quote testSalesQuote = (Quote) new SObjectBuilder(Quote.sObjectType)
    //             .setFields(
    //                 new Map<SObjectField, Object>{
    //                     Quote.Name => 'testSalesQuote',
    //                     Quote.Auto_Renewal__c => true,
    //                     Quote.OpportunityId => testOpp.Id,
    //                     Quote.Pricebook2Id => testPriceBook.Id,
    //                     Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
    //                     Quote.CurrencyIsoCode => 'USD'
    //                 }
    //             )
    //             .create()
    //             .getRecord();


    //         List<Product2> prodList = (List<Product2>) new SObjectBuilder(Product2.SObjectType)
    //             .setFields(
    //                 new Map<SObjectField, Object>{
    //                     Product2.Name => ValueProviderBuilder.provideList(
    //                         new List<String> {'test product 1', 'test product 2'}
    //                     ),
    //                     Product2.IsActive => ValueProviderBuilder.provideList(
    //                         new List<Boolean> {true, true}
    //                     ),
    //                     Product2.Sub_Category__c => ValueProviderBuilder.provideList(
    //                         new List<String> {'Main', 'Main'}
    //                     ),
    //                     Product2.GOA_Group_V2__c => ValueProviderBuilder.provideList(
    //                         new List<String> {'RC_Office_Standard_Monthly_Contract', 'RC_Office_Standard_Monthly_Contract'}
    //                     )
    //                 }
    //             )
    //             .quantity(2)
    //             .create()
    //             .getRecords();

    //         List<PricebookEntry> pbeList = new List<PricebookEntry>();

    //         for(Product2 item : prodList) {
    //             List<PricebookEntry> pbeListTemp = (List<PricebookEntry>) new SObjectBuilder(PricebookEntry.SObjectType)
    //                 .setFields(
    //                     new Map<SObjectField, Object>{

    //                         PricebookEntry.Pricebook2Id => ValueProviderBuilder.provideList(
    //                             new List<String> {Test.getStandardPricebookId(), testPriceBook.Id}
    //                         ),
    //                         PricebookEntry.Product2Id => ValueProviderBuilder.provideList(
    //                             new List<String> {item.Id, item.Id}
    //                         ),
    //                         PricebookEntry.UnitPrice => ValueProviderBuilder.provideList(
    //                             new List<Decimal> {200, 200}
    //                         ),
    //                         PricebookEntry.IsActive => ValueProviderBuilder.provideList(
    //                             new List<Boolean> {true, true}
    //                         ),
    //                         PricebookEntry.UseStandardPrice => ValueProviderBuilder.provideList(
    //                             new List<Boolean> {false, false}
    //                         ),
    //                         PricebookEntry.Per_Line__c => ValueProviderBuilder.provideList(
    //                             new List<Boolean> {true, false}
    //                         ),
    //                         PricebookEntry.CurrencyIsoCode => ValueProviderBuilder.provideList(
    //                             new List<String> {'USD', 'USD'}
    //                         )
    //                     }
    //                 )
    //                 .quantity(2)
    //                 .create()
    //                 .getRecords();
    //             pbeList.addAll(pbeListTemp);
    //         }

    //         Triggers.switchOn();

    //         List<QuoteLineItem> qliList = new List<QuoteLineItem>();

    //         for(PricebookEntry item : pbeList) {
    //             if(item.PriceBook2Id == testSalesQuote.Pricebook2Id) {
    //                 QuoteLineItem qli = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.sObjectType)
    //                     .setFields(
    //                         new Map<SObjectField, Object>{
    //                             QuoteLineItem.QuoteId => testSalesQuote.Id,
    //                             QuoteLineItem.Product2Id => item.Product2Id,
    //                             QuoteLineItem.Quantity => 10,
    //                             QuoteLineItem.UnitPrice => item.UnitPrice,
    //                             QuoteLineItem.PricebookEntryId => item.Id,
    //                             QuoteLineItem.PackageInfo__c => TestDataGenerator.TEST_DEVICE_PACKAGE_INFO
    //                         }
    //                     )
    //                     .create()
    //                     .getRecord();
    //             }
    //         }

    //         Test.stopTest();

    //         // not required if FreeShippingTerms__c != QuoteHelper.FREESHIPPING
    //         Quote reselectedSalesQuote = [
    //             SELECT Id, Approved_Status__c, Level_1_Approver__c, FreeShippingTerms__c, Shipping_Option__c
    //             FROM Quote WHERE Id = :testSalesQuote.Id ];
    //         System.assert(reselectedSalesQuote.Approved_Status__c != QuoteHelper.APPROVAL_STATUS_REQUIRED);

    //         // prepare for not requited if status = approved
    //         reselectedSalesQuote.Approved_Status__c = QuoteHelper.APPROVAL_STATUS_APPROVED;
    //         update reselectedSalesQuote;
    //         Quote reselectedSalesQuote01 = [
    //             SELECT Id, Approved_Status__c, Level_1_Approver__c, FreeShippingTerms__c, Shipping_Option__c
    //             FROM Quote WHERE Id = :testSalesQuote.Id ];

    //         // not required with FreeShippingTerms__c = QuoteHelper.FREESHIPPING and Option = Ground (PBC-7314)
    //         reselectedSalesQuote01.FreeShippingTerms__c = QuoteHelper.FREESHIPPING;
    //         reselectedSalesQuote01.Shipping_Option__c = QuoteHelper.SHIPPING_OPTION_GROUND;
    //         update reselectedSalesQuote01;

    //         Quote reselectedSalesQuote1 = [
    //             SELECT Id, Approved_Status__c, Level_1_Approver__c, Enabled_LBO__c, Shipping_Option__c, Upsell_Status__c
    //             FROM Quote WHERE Id = :testSalesQuote.Id ];
    //         System.assert(reselectedSalesQuote1.Approved_Status__c == QuoteHelper.APPROVAL_STATUS_APPROVED);

    //         // required with FreeShippingTerms__c = QuoteHelper.FREESHIPPING and option != Ground
    //         reselectedSalesQuote1.Shipping_Option__c = QuoteHelper.SHIPPING_OPTION_OVERNIGHT;
    //         update reselectedSalesQuote1;

    //         Quote reselectedSalesQuote2 = [
    //             SELECT Id, Approved_Status__c, Level_1_Approver__c, Enabled_LBO__c, Shipping_Option__c, Upsell_Status__c
    //             FROM Quote WHERE Id = :testSalesQuote.Id ];
    //         System.assert(reselectedSalesQuote2.Approved_Status__c == QuoteHelper.APPROVAL_STATUS_REQUIRED);
    //         System.assert(reselectedSalesQuote2.Level_1_Approver__c == testUserManager.Id);

    //         // not required for EB LBO without ShippingGroups
    //         reselectedSalesQuote2.Approved_Status__c = QuoteHelper.APPROVAL_STATUS_APPROVED;
    //         reselectedSalesQuote2.Enabled_LBO__c = true;
    //         reselectedSalesQuote2.Shipping_Option__c = QuoteHelper.SHIPPING_OPTION_2_DAY;
    //         reselectedSalesQuote2.Upsell_Status__c = QuoteHelper.STATUS_UPSELL;
    //         update reselectedSalesQuote2;

    //         Quote reselectedSalesQuote3 = [
    //             SELECT Id, Approved_Status__c, Level_1_Approver__c
    //             FROM Quote WHERE Id = :testSalesQuote.Id ];
    //         System.assert(reselectedSalesQuote3.Approved_Status__c != QuoteHelper.APPROVAL_STATUS_REQUIRED);
    //     }
    // }

    @isTest
    static void testExcludeQuotesForDQGOAFlow() {

        new SobjectBuilder(Feature_Toggle__c.SObjectType)
            .setField(Feature_Toggle__c.EnableTPAndDQBasedGOAInQT__c, true)
            .create();

        Opportunity testOpp = (Opportunity) new SObjectBuilder(Opportunity.sObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    Opportunity.AccountId => ValueProviderBuilder.provideGenericParent(Account.SObjectType)
                }
            )
            .create()
            .getRecord();

        Quote testQuote = (Quote) new SObjectBuilder(Quote.sObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    Quote.OpportunityId => testOpp.Id,
                    Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                    Quote.Package_Info__c => NGBSTestDataGenerator.generateQuotePackageInfo()
                }
            )
            .create()
            .getRecord();

        Quote reselectedQuote = (Quote) new QuoteSelector()
            .selectQuotes()
            .withoutSelectorFieldsIncluded()
            .selectFields(new List<String> {
                'RecordTypeId',
                'Account.RC_User_ID__c',
                'Account.Billing_ID__c',
                'IsPRMQuote__c',
                'BillingPackage__c'
            })
            .setCondition('Id = :bind0')
            .setQueryBindings(new List<Object>{ testQuote.Id })
            .executeQuery()
            .get(0);

        QuoteLineItem testQli = new QuoteLineItem();
        testQli.Quote = reselectedQuote;

        Map<Id, List<QuoteLineItem>> quoteIdToQliListMap = new Map<Id, List<QuoteLineItem>>{
            testQuote.Id => new List<QuoteLineItem>{testQli}
        };

        Map<Id, List<QuoteLineItem>> result = QuoteApprovals.excludeQuotesForDQGOAFlow(quoteIdToQliListMap);
        System.assert(
            result.isEmpty(),
            'New Business Quotes should be excluded from GOA process ' +
            'if Feature_Toggle__c.EnableTPAndDQBasedGOAInQT__c is enabled'
        );
        System.assert(
            !QuoteApprovals.quotesExcludedForDQGoa.isEmpty(),
            'all excluded quotes should be stored in QuoteApprovals.quotesExcludedForDQGoa list'
        );
        System.assertEquals(
            testQuote.Id,
            QuoteApprovals.quotesExcludedForDQGoa.get(0).Id,
            'all excluded quotes should be stored in QuoteApprovals.quotesExcludedForDQGoa list'
        );
    }

    @isTest
    static void testFindApproverRoleForQLIUsesCurrentQuoteInitialTerm() {

        User testUser;
        User testUserManager;

        List<String> userNameList = new List<String>{
                createUserName('rSeg'),
                createUserName('dMan')
        };

        for(User u : (List<User>) new UserSelector()
                .selectUserByUsername(new List<Object>{userNameList})
                .selectFields( new List<String>{
                        'Id',
                        'LastName',
                        'Username',
                        'Hierarchy_Role__c',
                        'ManagerId',
                        'Email',
                        'SegmentPicklist__c'
                })
                .executeQuery()
        ) {
            if(u.UserName == createUserName('rSeg')) {
                testUser = u;
            }else if(u.UserName == createUserName('dMan')) {
                testUserManager = u;
            }
        }

        System.runAs(testUser) {

            new SObjectBuilder(GOA_V2__c.sObjectType)
                    .quantity(4)
                    .setField(GOA_V2__c.Name,
                    ValueProviderBuilder.provideList(new List<String>{
                            '1',
                            '2',
                            '3',
                            '4'
                    }
                    )
            )
                    .setField(GOA_V2__c.Quantity_Range__c,
                    ValueProviderBuilder.provideList(new List<String>{
                            '1-99',
                            '1-99',
                            '1-99',
                            '1-99'
                    }
                    )
            )
                    .setField(GOA_V2__c.Contract_Initial_Term_Range__c,
                    ValueProviderBuilder.provideList(new List<String>{
                            '0-11',
                            '12-23',
                            '24-36',
                            '37-99'
                    }
                    )
            )
                    .setField(GOA_V2__c.Sales_Rep__c,
                    ValueProviderBuilder.provideList(new List<String>{
                            '0-0',
                            '0-20',
                            '0-20',
                            '0-25'
                    }
                    )
            )
                    .setField(GOA_V2__c.Direct_Manager__c,
                    ValueProviderBuilder.provideList(new List<String>{
                            '0.01-25',
                            '20.01-30',
                            '20.01-50',
                            '25.01-50'
                    }
                    )
            )
                    .setField(GOA_V2__c.Segment_Leader__c,
                    ValueProviderBuilder.provideList(new List<String>{
                            '25.01-50',
                            '30.01-50',
                            '50.01-75',
                            '50.01-75'
                    }
                    )
            )
                    .setField(GOA_V2__c.SVP_WWS_Directs__c,
                    ValueProviderBuilder.provideList(new List<String>{
                            '50.01-100',
                            '50.01-100',
                            '75.01-100',
                            '75.01-100'
                    }
                    )
            )
                    .setField(GOA_V2__c.SVP_WWS__c,
                    ValueProviderBuilder.provideList(new List<String>{
                            '0-0',
                            '0-0',
                            '0-0',
                            '0-0'
                    }
                    )
            )
                    .setField(GOA_V2__c.Group__c,
                    ValueProviderBuilder.provideList(new List<String>{
                            'GOA_Devices',
                            'GOA_Devices',
                            'GOA_Devices',
                            'GOA_Devices'
                    }
                    )
            )
                    .setField(GOA_V2__c.Currency__c,
                    ValueProviderBuilder.provideList(new List<String>{
                            'Percentage',
                            'Percentage',
                            'Percentage',
                            'Percentage'
                    }
                    )
            )
                    .create();

            new SObjectBuilder(Products_taken_into_account_in_GOA__c.sObjectType)
                    .setFields(
                    new Map<SObjectField, Object> {
                            Products_taken_into_account_in_GOA__c.Name => 'test',
                            Products_taken_into_account_in_GOA__c.Products_taken_into_account_in_GOA__c.Quote_Record_Type__c => 'Sales Quote',
                            Products_taken_into_account_in_GOA__c.Products_taken_into_account_in_GOA__c.Sub_Categories__c => 'Main, Contact Center'
                    }
            )
                    .create();


            Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.sObjectType)
                    .setFields(
                            new Map<SObjectField, Object> {
                                    Opportunity.AccountId => ValueProviderBuilder.provideGenericParent(Account.sObjectType),
                                    Opportunity.Brand_Name__c => 'RingCentral'
                            }
                    )
                    .create()
                    .getRecord();

            PriceBook2 pb = (PriceBook2) new SObjectBuilder(PriceBook2.sObjectType)
                    .setFields(
                            new Map<SObjectField, Object> {
                                    PriceBook2.Description => ValueProviderBuilder.provideUniqueString(),
                                    PriceBook2.IsActive => true
                            }
                    )
                    .create()
                    .getRecord();

            Product2 serviceProd = (Product2) new SObjectBuilder(Product2.sObjectType)
                    .setFields(
                            new Map<SObjectField, Object> {
                                    Product2.Family => Product2Helper.FAMILY_SERVICE,
                                    Product2.Charge_Term__c => Product2Helper.CHARGE_TERM_ANNUAL,
                                    Product2.Description => ValueProviderBuilder.provideUniqueString(),
                                    Product2.Sub_Category__c => 'Main',
                                    Product2.GOA_Group_V2__c => 'GOA_Devices'
                            }
                    )
                    .create()
                    .getRecord();

            List<PricebookEntry> pbeList = (List<PricebookEntry>) new SObjectBuilder(PricebookEntry.sObjectType)
                    .quantity(2)
                    .setFields(
                            new Map<SObjectField, Object> {
                                    PricebookEntry.Pricebook2Id => ValueProviderBuilder.ProvideList(
                                            new List<Object> {
                                                    Test.getStandardPricebookId(),
                                                    pb.Id
                                            }
                                    ),
                                    PricebookEntry.Product2Id => serviceProd.Id,
                                    PricebookEntry.UnitPrice => 200,
                                    PricebookEntry.IsActive => true,
                                    PricebookEntry.UseStandardPrice => false
                            })
                    .create()
                    .getRecords();

            Quote q = (Quote) new SObjectBuilder(Quote.sObjectType)
                    .setFields(
                            new Map<SObjectField, Object> {
                                    Quote.Pricebook2Id => pb.Id,
                                    Quote.OpportunityId => opp.Id,
                                    Quote.RecordTypeId => QuoteHelper.RT_ID_SALES,
                                    Quote.Initial_Term_months__c => '48',
                                    Quote.Upsell_Status__c => 'Upsell'
                            }
                    )
                    .create()
                    .getRecord();

            Test.startTest();

            List<QuoteLineItem> qliList = new List<QuoteLineItem>();

            for(PricebookEntry pbe : pbeList) {

                if(pbe.PriceBook2Id == q.Pricebook2Id) {

                    new SObjectBuilder(QuoteLineItem.SObjectType)
                            .setFields(
                            new Map<SObjectField, Object> {
                                    QuoteLineItem.QuoteId => q.Id,
                                    QuoteLineItem.Product2Id => pbe.Product2Id,
                                    QuoteLineItem.Quantity => 1,
                                    QuoteLineItem.UnitPrice => pbe.UnitPrice,
                                    QuoteLineItem.Discount => 22,
                                    QuoteLineItem.PricebookEntryId => pbe.Id
                            })
                            .create();
                }
            }

            Test.stopTest();

            Quote reselectedSalesQuote = [
                    SELECT Approved_Status__c, Approval_Type__c, Level_1_Approver__c
                    FROM Quote
                    WHERE Id = :q.Id
            ];

            System.assertEquals(QuoteHelper.APPROVAL_STATUS_APPROVED, reselectedSalesQuote.Approved_Status__c);
        }
    }
}