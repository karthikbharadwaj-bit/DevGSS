@isTest
public class Test_GlipApprovalService {

    private static User salesrepUser;
    private static User salesmanagerUser;
    private static User salesmanagermanagerUser;
    private static User salesVPUser;
    private static Quote testQuote;
    private static Account testAccount;
    private static QuoteLineItem testQuoteLineItem;
    private static Opportunity testOpportunity;
    private static PriceBook2 testPriceBook;
    private static final Id SYSTEM_ADMIN_PROFILE_ID =
        [SELECT Id, Name FROM Profile WHERE Name = 'System Administrator'].Id;

	@isTest
    static void testInvalidInputScenario1() {
        GlipApprovalService.GlipApprovalRequest req = new GlipApprovalService.GlipApprovalRequest();
        req.approvalWorkitemId = '';
        req.action = 'approve';
        req.comment = 'testing';
        req.approverEmail = 'test@rc.com';

        RestRequest request = new RestRequest();
        request.requestBody = Blob.valueOf(JSON.serialize(req));
        RestContext.request = request;

        GlipApprovalService.handleApprovalRequest();

        String body = RestContext.response.responseBody.toString();
        Assert.areEqual(true, body.contains(GlipApprovalService.INVALID_INPUT_MSG), 'Incorrect Response');
    }

    @isTest
    static void testInvalidInputScenario2() {
        Account testAccount = (Account) new SobjectBuilder(Account.SObjectType)
                .setFields(new Map<SObjectField, Object> {
                    Account.Name => 'Test Acc 1'
                })
                .create()
                .getRecord();
        // Random ID provided below as we are testing empty input param scenario
        String body = ProcessAPIRequest(testAccount.Id, '', 'test@rc.com');
        Assert.areEqual(true, body.contains(GlipApprovalService.INVALID_INPUT_MSG), 'Incorrect Response');
    }

    @isTest
    static void testInvalidActionScenario() {
        Account testAccount = (Account) new SobjectBuilder(Account.SObjectType)
                .setFields(new Map<SObjectField, Object> {
                    Account.Name => 'Test Acc 1'
                })
                .create()
                .getRecord();
        // Random ID provided below as we are testing invalid input param scenario
        String body = ProcessAPIRequest(testAccount.Id, 'appr', 'test@rc.com');
        Assert.areEqual(true, body.containsIgnoreCase('Invalid action'), 'Incorrect Response');
    }

    @isTest
    static void testRequestHandledScenario() {
        Account testAccount = (Account) new SobjectBuilder(Account.SObjectType)
        	.setFields(new Map<SObjectField, Object> {
            Account.Name => 'Test Acc 1'
            })
            .create()
            .getRecord();

        String response = ProcessAPIRequest(testAccount.Id, 'approve', 'test@rc.com');
        Assert.areEqual(true, response.contains(GlipApprovalService.REQUEST_ALREADY_HANDLED_MSG), 'Incorrect Response');
    }

    public static String ProcessAPIRequest(Id procInstWorkItemId, String action, String apprEmail) {
        GlipApprovalService.GlipApprovalRequest req = new GlipApprovalService.GlipApprovalRequest();
        req.approvalWorkitemId = procInstWorkItemId;
        req.action = action;
        req.comment = 'testing';
		req.approverEmail = apprEmail;

        RestRequest request = new RestRequest();
        request.requestBody = Blob.valueOf(JSON.serialize(req));
        RestContext.request = request;

        GlipApprovalService.handleApprovalRequest();
        String body = RestContext.response.responseBody.toString();
        return body;
    }

    @isTest
    static void testRequestApprovalScenarios() {
        Triggers.switchOff();
        salesrepUser = createUser('sr', false, true); // salesrepUser
        salesmanagerUser = createUser('sm', false); //salesmanagerUser
        salesmanagermanagerUser = createUser('smm', false); //salesmanagermanagerUser
        salesVPUser = createUser('svp', false); //salesmanagermanagerUser
        User userSysAdmin = (User) new SObjectBuilder (User.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    User.LastName => 'testUser',
                    User.Username => 'testUser@ringcentral.com',
                    User.Email => 'testUser@rc.com',
                    User.TimeZoneSidKey => 'America/Los_Angeles',
                    User.LocaleSidKey => 'en_US',
                    User.EmailEncodingKey => 'UTF-8',
                    User.ProfileId => SYSTEM_ADMIN_PROFILE_ID,
                    User.LanguageLocaleKey => 'en_US',
                    User.CommunityNickname => 'Test052323'
                }
            )
            .create()
            .getRecord();

        insert new List<User> {salesrepUser, salesmanagerUser, salesmanagermanagerUser, salesVPUser};
        Triggers.switchOn();

        system.runAs(userSysAdmin) {

            insert new GOA_V2__c(
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

            insert new Products_taken_into_account_in_GOA__c(
                Name = 'test',
                Quote_Record_Type__c = 'Sales Quote',
                Sub_Categories__c = 'Main, Contact Center'
            );

            salesrepUser.Hierarchy_Role__c = 'Direct Manager';
            salesmanagerUser.Hierarchy_Role__c = 'Segment Leader';
            salesmanagermanagerUser.Hierarchy_Role__c = 'SVP WWS Directs';
            update new List<User> { salesrepUser, salesmanagerUser, salesmanagermanagerUser };

            Test.startTest();
                CreateTestData(Test.getStandardPricebookId(), 999, 'SalesVP', '1-9999999', '0-0', '0-0', '0-0', '0-0', '1234');
                testQuote = [SELECT Id, Approved_Status__c, Level_1_Approver__r.Name FROM Quote WHERE Id=:testQuote.Id];
                Map<String, String> params = new Map<String, String>();
                params.put('quoteId', String.valueOf(testQuote.Id));
            Test.stopTest();

            testQuote = QuotingToolQuoteApexController.submitApprovalRequest(params);
            
			// Actor email will be absent, therefore we get null reference error. Hence the exception scenario will get covered.
           	ProcessInstanceWorkitem workInstance = [Select Id FROM ProcessInstanceWorkitem where ProcessInstance.TargetObjectId =:testQuote.Id LIMIT 1];
            String response = ProcessAPIRequest(workInstance.Id, 'approve', 'test@rc.com');
            Assert.areEqual(true, response.contains(GlipApprovalService.GLIP_ERROR_MSG), 'Incorrect Response for Glip Error Scenario');
            
            // Set the actor explicitly by creating new user to avoid above error
            User testapprover = createUser('Jers', true, false);
            workInstance.ActorId = testapprover.Id;
            update workInstance;
            String response1 = ProcessAPIRequest(workInstance.Id, 'approve', 'test@rc.com');
            Assert.areEqual(true, response1.contains(GlipApprovalService.INVALID_APPROVER), 'Incorrect Response for Invalid Approver Scenario');
            
            String response2 = ProcessAPIRequest(workInstance.Id, 'approve', 'Jers_user@rc.com');
            Assert.areEqual(true, response2.contains(GlipApprovalService.GLIP_SUCCESS_MSG), 'Incorrect Response for Approval Success Scenario');
        }
    }

    private static User createUser(String name, Boolean insertUser) {
        return createUser(name, insertUser, false);
    }

    private static User createUser(String name, Boolean insertUser, Boolean addManager) {
        User user = new User(
            Username = name+'!user@rc.com',
            LastName = 'Test'+name,
            Email = name+'_user@rc.com',
            Alias = 'te'+name,
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = SYSTEM_ADMIN_PROFILE_ID,
            LanguageLocaleKey = 'en_US'
        );
        if (addManager) {
            user.ManagerId = UserInfo.getUserId();
        }
        if (insertUser) {
            insert user;
        }
        return user;
    }

    private static void CreateTestData(Id standardPriceBookId, Decimal discount, String other, String range, 
                                        String srr, String smr, String smmr, String svpr, String rcUserId) {
         //Assign approvers
        assignManager(salesrepUser, salesmanagerUser);
        assignManager(salesmanagerUser, salesmanagermanagerUser);

        //Insert Sales VP
        upsert new RingCentralVariousSettings__c(
            SVP_WWS_User_ID__c = salesVPUser.Id,
            SetupOwnerId = salesrepUser.Id
        );

        testPriceBook = new Pricebook2(Name = 'Test Price Book', Description ='Test Price Book Products', 
            IsActive = true, Line_Range_Min__c = 5, Service__c = 'Office');
        insert testPriceBook;

        Product2 testProduct = new Product2(Name = 'Connect Pro - Annual Fee', IsActive = true, GOA_Group__c = 'DEVICES_B_STOCK', 
            Family = 'RingCentral', Sub_Category__c = 'Main');
        insert testProduct;

        PricebookEntry standardPrice = new PricebookEntry(Pricebook2Id = standardPriceBookId, Product2Id = testProduct.Id, 
            UnitPrice = 10000, IsActive = true, UseStandardPrice = false);
        insert standardPrice;

        PricebookEntry testPrice = new PricebookEntry(Pricebook2Id = testPriceBook.Id, Product2Id = testProduct.Id, 
            UnitPrice = 10000, IsActive = true, UseStandardPrice = false, Per_Line__c = false, Min_Quantity__c = 1,  Max_Quantity__c = 100);
        insert testPrice;

        Triggers.switchOff();

        testAccount = new Account(Name='Opty test account',
                                    Partner_ID__c='testID',
                                    Permitted_Brands__c='RingCentral',
                                    RC_User_ID__c = rcUserId);
        insert testAccount;

        testOpportunity = new Opportunity(Name = 'Test Opportunity 2025', Type = 'Existing Business', StageName = 'Qualify', CloseDate = System.Today(), AccountId = testAccount.Id);
        insert testOpportunity;

        testQuote = new Quote (Name = 'quotetest', OpportunityId = testOpportunity.id, Pricebook2Id = testPriceBook.id, Total_Number_of_Digital_Lines__c = 10, RecordTypeId = QuoteHelper.RT_ID_SALES);
        insert testQuote;
        Triggers.switchOn();

        testQuoteLineItem = new QuoteLineItem (ServiceDate = date.today(), Description = 'TestLineItem', UnitPrice = testPrice.UnitPrice, Quantity = 5,
                                                QuoteId = testQuote.Id, PriceBookEntryId = testPrice.Id, Product2Id = testProduct.Id, Discount_type__c = QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY, Discount_number__c = discount);
        OpportunityTotals.bypassOpportnuityUpdate = true;
        insert testQuoteLineItem;
        OpportunityTotals.bypassOpportnuityUpdate = false;
    }

    private static void assignManager(User u, User manager) {
        u.ManagerId = manager.Id;
        update u;
    }
}