// Currently refering to QA NameSpace class
@isTest
public class DQ_DealQualificationController_Test {
    private static Id newSalesRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('New Sales Opportunity').getRecordTypeId();
    @testSetup static void setup() {
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        System.runAs(thisUser) {
            //Creating Group
            Group testGroup = new Group(Name = 'Segement Leader', Type = 'Queue');
            insert testGroup;

            //Create Group Member
            GroupMember grpMem1 = new GroupMember();
            grpMem1.UserOrGroupId = UserInfo.getUserId();
            grpMem1.GroupId = testGroup.Id;
            Insert grpMem1;

            //Associating queue with group AND to the Approver object
            QueuesObject testQueue = new QueueSObject(QueueID = testGroup.id, SObjectType = 'DQ_Deal_Qualification_Approver__c');
            insert testQueue;

        }

        Account ObjAcc = new Account();
        ObjAcc.Name = 'Test 1';
        insert ObjAcc;

        // insert Opp
        Opportunity objOpp = new Opportunity();
        objOpp.Name = 'Test 1';
        objOpp.StageName = '7. Closed Won';
        objOpp.AccountId = objAcc.Id;
        objOpp.RecordTypeId = newSalesRecordTypeId;
        objOpp.Brand_Name__c = 'Avaya Cloud Office';
        insert objOpp;

        Product2 objProduct = new Product2(Name = 'Test product1', family = 'Cafe');
        insert objProduct;

        PriceBookEntry objPBE = new PriceBookEntry(UnitPrice = 300, PriceBook2Id = Test.getStandardPricebookId(),
            Product2Id = objProduct.Id, IsActive = true);
        insert objPBE;

        List<Quote> lstQuote = new List<Quote>();
        lstQuote.add(new Quote(OpportunityId = objOpp.Id, Name = 'Test Quote', Pricebook2Id = Test.getStandardPricebookId(), Status = 'Review Pending'));
        insert lstQuote;
    }

    private static List<DQ_Deal_Qualification__c> getDealQualification() {
        return [
            SELECT Id,Brand__c,Deal_Type__c,Region__c,Segment__c,Name,Minimum_Package_s__c,opportunity__r.Name, Type__c, Special_Terms__c, Sub_Region__c,
                Charge_Term__c,Initial_Term__c,Opportunity__c,Renewal_Term__c,Status__c, Deal_Size__c, Overall_Discount__c, Justification_Description__c
            FROM DQ_Deal_Qualification__c
        ];
    }

    // First time when no DQ Exist
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    public static void checkDQExistNegative_Test() {
        Opportunity objOpp = [SELECT Id FROM Opportunity where Name = 'Test 1'];
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('PicklistFieldMockResponse');
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json');
        Test.setMock(HttpCalloutMock.class, mock);
        List<DQ_Deal_Qualification__c> objDQ = DQApprovalTestDataFactory.generateDQ(1, 'Avaya Cloud Office', 'Direct', 'EU', 'Small Business', objOpp.Id);
        insert objDQ;
        List<DQ_Approval_Step__c> objApprStep = DQApprovalTestDataFactory.generateDQApprovalStep(1);
        insert objApprStep;
        List<DQ_Approval_Step_Approver__c> objDQApprovalStepApproverList = DQApprovalTestDataFactory.generateDQApprovalStepApprover(1,
            objApprStep[0].Id, 'Avaya Cloud Office', 'Approval', 'Direct', 'EU', 'Small Business');
        insert objDQApprovalStepApproverList;

        DQ_Deal_Qualification_Approver__c objApprover1 = new DQ_Deal_Qualification_Approver__c();
        objApprover1.Deal_Qualification__c = objDQ[0].Id;
        objApprover1.Approval_Step_Approver__c = [SELECT ID FROM DQ_Approval_Step_Approver__c limit 1].Id;
        objApprover1.Approval_Step__c = objApprStep[0].Id; //[SELECT ID FROM DQ_Approval_Step__c limit 1].Id;
        objApprover1.Submitted_Order__c = 1;
        objApprover1.Step_Order__c = 1;
        insert objApprover1;
        Test.startTest();
        DQ_DealQualificationController.checkDQExistFOROpp(objOpp.Id);
        Test.stopTest();
    }

    // First time when no DQ Exist
    @isTest
    public static void checkDQExistPositive_Test() {
        Triggers.switchOff();
        Opportunity objOpp = [SELECT Id FROM Opportunity where Name = 'Test 1'];
        List<DQ_Deal_Qualification__c> objDQ = DQApprovalTestDataFactory.generateDQ(1, 'Avaya Cloud Office', 'Direct', 'EU', 'Small Business', objOpp.Id);
        insert objDQ;

        List<Partner_Quote__c> quoteList = Quote_TestDataFactory.generateQuotes(1);
        quoteList[0].opportunity__c = objOpp.Id;
        quoteList[0].Primary__c = true;
        insert quoteList;

        List<Product2> productList = Quote_TestDataFactory.generateProducts(1);
        insert productList;

        List<DQ_Deal_Qualification_Discounts__c> objDiscount = DQApprovalTestDataFactory.generateDQDiscount(1, objDQ[0].Id, 70, 'GOA_Devices', productList[0].Id, 80, false);
        insert objDiscount;

        Triggers.switchOn();

        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('PicklistFieldMockResponse');
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json');
        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();

        DQ_DealQualificationController.DealQualificationWrapper objDQWrapper2 = DQ_DealQualificationController.checkDQExistFOROpp(objDQ[0].opportunity__c);
        DQ_DealQualificationController.saveDealQualification(objDQ[0], objDiscount, true);
        DQ_DealQualificationController.submitForApprovalForDealQualification(objDQ[0].Id, objOpp.Id, objDQ.get(0));
        List<QuoteLIneItem> qtlines = DQ_DealQualificationController.getPrimayQuoteLineDetails(objOpp.Id);
        Test.stopTest();

        System.assertEquals(
            true,
            objDQWrapper2.isDQExist,
            'Wrapper should contain DQ details'
        );
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    public static void getProducts_Test() {
        DQ_DealQualificationController.getProducts('Devices', '');
        DQ_DealQualificationController.getProducts('Devices', 'test');
        DQ_DealQualificationController.getProducts('', 'test');

    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    public static void checkApprovePermission_Test() {
        Group gp = [SELECT id FROM Group WHERE Name = 'Segement Leader'];
        Opportunity objOpp = [SELECT Id FROM Opportunity where Name = 'Test 1'];
        List<DQ_Deal_Qualification__c> objDQ = DQApprovalTestDataFactory.generateDQ(1, 'Avaya Cloud Office', 'Direct', 'EU', 'Small Business', objOpp.Id);
        insert objDQ;

        List<Product2> productList = Quote_TestDataFactory.generateProducts(1);
        insert productList;

        List<DQ_Deal_Qualification_Discounts__c> objDiscount = DQApprovalTestDataFactory.generateDQDiscount(1, objDQ[0].Id, 70, 'GOA_Devices', productList[0].Id, 80, false);
        insert objDiscount;

        List<DQ_Approval_Step__c> objApprStep = DQApprovalTestDataFactory.generateDQApprovalStep(1);
        insert objApprStep;

        List<DQ_Approval_Step_Approver__c> objDQApprovalStepApproverList = DQApprovalTestDataFactory.generateDQApprovalStepApprover(1,
            objApprStep[0].Id, 'Avaya Cloud Office', 'Approval', 'Direct', 'EU', 'Small Business');
        insert objDQApprovalStepApproverList;

        DQ_Deal_Qualification_Approver__c objApprover1 = new DQ_Deal_Qualification_Approver__c();
        objApprover1.Deal_Qualification__c = objDQ[0].Id;
        objApprover1.Approval_Step_Approver__c = [SELECT ID FROM DQ_Approval_Step_Approver__c limit 1].Id;
        objApprover1.Approval_Step__c = objApprStep[0].Id; //[SELECT ID FROM DQ_Approval_Step__c limit 1].Id;
        objApprover1.Submitted_Order__c = 1;
        objApprover1.Step_Order__c = 1;
        insert objApprover1;

        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('PicklistFieldMockResponse');
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json');
        Test.setMock(HttpCalloutMock.class, mock);
        Test.startTest();
        DQ_DealQualificationController.DealQualificationWrapper objDQWrapper = DQ_DealQualificationController.checkDQExistFOROpp(objOpp.Id);
        DQ_DealQualificationController.saveDealQualification(objDQ[0], objDiscount, true);
        DQ_DealQualificationController.submitForApprovalForDealQualification(objDQ[0].Id, objOpp.Id, objDQ.get(0));

        DQ_Deal_Qualification_Approver__c objApprover = new DQ_Deal_Qualification_Approver__c(); //[SELECT Id,Submitted_Order__c,Approval_Step__c,Deal_Qualification__c,Approval_Step_Approver__c FROM DQ_Deal_Qualification_Approver__c LIMIT 1];
        objApprover.Id = objApprover1.Id;
        objApprover.OwnerId = gp.id;
        update objApprover;

        DQ_DealQualificationController.checkApprovePermission(objApprover.Id);
        DQ_DealQualificationController.checkIfDQApprovalAcceptorReject(objApprover.Id);
        DQ_DealQualificationController.saveApprovalDetails(objApprover.Id, 'testing', 'Approved', objDQ[0].id);
        DQ_DealQualificationController.revisedDealQualification(objDQ[0]);
        DQ_DealQualificationController.getApproverByOppId(objOpp.Id, null);
        DQ_DealQualificationController.decimalToBinary(2);
        DQ_DealQualificationController.base64ToBits('test');
        DQ_DealQualificationController.deleteDQDiscountRecord(objDiscount[0]);
        DQ_DealQualificationController.updateApproverUserAssignment(objApprover.Id, UserInfo.getUserId());
        DQ_DealQualificationController.getPendingDealQualificationApproverDetailsByDQId(objDQ.get(0).Id);
        DQ_DealQualificationController.saveChunk(objDQ.get(0).Id, 'TEST.XLS', 'Hello', 'XLS', '');
        List<Attachment> listOfFile = DQ_DealQualificationController.getFiles(objDQ.get(0).Id);
        DQ_DealQualificationController.saveChunk(objDQ.get(0).Id, 'TEST.XLS', 'Hello', 'XLS', listOfFile.get(0).Id);
        Test.stopTest();
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    public static void checkApprovePermission_Test2() {
        Group gp = [SELECT id FROM Group WHERE Name = 'Segement Leader'];
        Opportunity objOpp = [SELECT Id FROM Opportunity where Name = 'Test 1'];
        List<Product2> productList = Quote_TestDataFactory.generateProducts(1);
        insert productList;

        List<DQ_Deal_Qualification__c> objDQ = DQApprovalTestDataFactory.generateDQ(1, 'Avaya Cloud Office', 'Direct', 'EU', 'Small Business', objOpp.Id);
        objDQ[0].Status__c = 'Rejected';
        insert objDQ;

        List<DQ_Deal_Qualification_History__c> dqHistory = DQApprovalTestDataFactory.generateDQHistory(1, 'Avaya Cloud Office', 'Direct', 'EU', 'Small Business', objDQ[0].Id);
        dqHistory[0].Status__c = 'Pending Approval';
        insert dqHistory;

        List<DQ_Deal_Qualification_Discount_History__c> dqDiscHistory = DQApprovalTestDataFactory.generateDQDiscountHistory(1, dqHistory[0].Id, 5, 'GOA_RC_Office', productList[0].Id, 1);
        insert dqDiscHistory;

        List<DQ_Deal_Qualification_Discounts__c> objDiscount = DQApprovalTestDataFactory.generateDQDiscount(1, objDQ[0].Id, 70, 'GOA_Devices', productList[0].Id, 80, false);
        insert objDiscount;
        List<DQ_Approval_Step__c> objApprStep = DQApprovalTestDataFactory.generateDQApprovalStep(1);
        insert objApprStep;
        List<DQ_Approval_Step_Approver__c> objDQApprovalStepApproverList = DQApprovalTestDataFactory.generateDQApprovalStepApprover(1,
            objApprStep[0].Id, 'Avaya Cloud Office', 'Approval', 'Direct', 'EU', 'Small Business');
        insert objDQApprovalStepApproverList;

        DQ_Deal_Qualification_Approver__c objApprover1 = new DQ_Deal_Qualification_Approver__c();
        objApprover1.Deal_Qualification__c = objDQ[0].Id;
        objApprover1.Approval_Step_Approver__c = [SELECT ID FROM DQ_Approval_Step_Approver__c limit 1].Id;
        objApprover1.Approval_Step__c = objApprStep[0].Id; //[SELECT ID FROM DQ_Approval_Step__c limit 1].Id;
        objApprover1.Submitted_Order__c = 1;
        objApprover1.Step_Order__c = 1;
        insert objApprover1;

        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('PicklistFieldMockResponse');
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json');
        Test.setMock(HttpCalloutMock.class, mock);
        Test.startTest();
        DQ_DealQualificationController.DealQualificationWrapper objDQWrapper = DQ_DealQualificationController.checkDQExistFOROpp(objOpp.Id);
        DQ_DealQualificationController.saveDealQualification(objDQ[0], objDiscount, true);
        DQ_DealQualificationController.submitForApprovalForDealQualification(objDQ[0].Id, objOpp.Id, objDQ.get(0));

        DQ_Deal_Qualification_Approver__c objApprover = new DQ_Deal_Qualification_Approver__c(); //[SELECT Id,Submitted_Order__c,Approval_Step__c,Deal_Qualification__c,Approval_Step_Approver__c FROM DQ_Deal_Qualification_Approver__c LIMIT 1];
        objApprover.Id = objApprover1.Id;
        objApprover.OwnerId = gp.id;
        update objApprover;

        /*DQ_Deal_Qualification_Approver__c objApprover = new DQ_Deal_Qualification_Approver__c(); //[SELECT Id,Submitted_Order__c,Approval_Step__c,Deal_Qualification__c,Approval_Step_Approver__c FROM DQ_Deal_Qualification_Approver__c LIMIT 1];
        objApprover.Id = objApprover1.Id;
        objApprover.OwnerId = gp.id;
        update objApprover;*/
        DQ_DealQualificationController.checkApprovePermission(objApprover.Id);
        DQ_DealQualificationController.checkIfDQApprovalAcceptorReject(objApprover.Id);
        DQ_DealQualificationController.saveApprovalDetails(objApprover.Id, 'testing', 'Approved', objDQ[0].id);
        DQ_DealQualificationController.revisedDealQualification(objDQ[0]);
        DQ_DealQualificationController.getApproverByOppId(objOpp.Id, null);
        DQ_DealQualificationController.decimalToBinary(2);
        DQ_DealQualificationController.base64ToBits('test');
        DQ_DealQualificationController.deleteDQDiscountRecord(objDiscount[0]);
        DQ_DealQualificationController.updateApproverUserAssignment(objApprover.Id, UserInfo.getUserId());
        DQ_DealQualificationController.getPendingDealQualificationApproverDetailsByDQId(objDQ.get(0).Id);
        DQ_DealQualificationController.saveChunk(objDQ.get(0).Id, 'TEST.XLS', 'Hello', 'XLS', '');
        List<Attachment> listOfFile = DQ_DealQualificationController.getFiles(objDQ.get(0).Id);
        DQ_DealQualificationController.saveChunk(objDQ.get(0).Id, 'TEST.XLS', 'Hello', 'XLS', listOfFile.get(0).Id);
        Test.stopTest();
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    public static void checkApprovePermissionWithUser_Test() {
        User ur = (User) new SObjectBuilder(User.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    User.LastName => 'TestTest',
                    User.Username => 'Test!user@gmail.com',
                    User.Email => 'Test_user@gmail.com',
                    User.Alias => 'Test',
                    User.TimeZoneSidKey => 'America/Los_Angeles',
                    User.ManagerId => UserInfo.getUserId(),
                    User.LocaleSidKey => 'en_US',
                    User.EmailEncodingKey => 'UTF-8',
                    User.ProfileId => [SELECT Id, Name FROM Profile WHERE Name = 'System Administrator'].Id,
                    User.LanguageLocaleKey => 'en_US',
                    User.Hierarchy_Role__c => 'Sales Rep'
                }
            )
            .create()
            .getRecord();

        Group gp = [SELECT id FROM Group WHERE Name = 'Segement Leader'];
        Opportunity objOpp = [SELECT Id FROM Opportunity where Name = 'Test 1'];
        List<DQ_Deal_Qualification__c> objDQ = DQApprovalTestDataFactory.generateDQ(1, 'Avaya Cloud Office', 'Direct', 'EU', 'Small Business', objOpp.Id);
        insert objDQ;
        List<Product2> productList = Quote_TestDataFactory.generateProducts(1);
        insert productList;

        List<DQ_Deal_Qualification_Discounts__c> objDiscount = DQApprovalTestDataFactory.generateDQDiscount(1, objDQ[0].Id, 70, 'GOA_Devices', productList[0].Id, 80, false);
        insert objDiscount;

        List<DQ_Approval_Step__c> objApprStep = DQApprovalTestDataFactory.generateDQApprovalStep(1);
        insert objApprStep;

        List<DQ_Approval_Step_Approver__c> objDQApprovalStepApproverList = DQApprovalTestDataFactory.generateDQApprovalStepApprover(1,
            objApprStep[0].Id, 'Avaya Cloud Office', 'Approval', 'Direct', 'EU', 'Small Business');
        insert objDQApprovalStepApproverList;

        DQ_Deal_Qualification_Approver__c objApprover1 = new DQ_Deal_Qualification_Approver__c();
        objApprover1.Deal_Qualification__c = objDQ[0].Id;
        objApprover1.Approval_Step_Approver__c = [SELECT ID FROM DQ_Approval_Step_Approver__c limit 1].Id;
        objApprover1.Approval_Step__c = objApprStep[0].Id; //[SELECT ID FROM DQ_Approval_Step__c limit 1].Id;
        objApprover1.Submitted_Order__c = 1;
        objApprover1.Step_Order__c = 1;
        objApprover1.OwnerId = ur.Id;
        insert objApprover1;

        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('PicklistFieldMockResponse');
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json');
        Test.setMock(HttpCalloutMock.class, mock);
        Test.startTest();
        DQ_DealQualificationController.DealQualificationWrapper objDQWrapper = DQ_DealQualificationController.checkDQExistFOROpp(objOpp.Id);
        DQ_DealQualificationController.saveDealQualification(objDQ[0], objDiscount, true);
        DQ_DealQualificationController.submitForApprovalForDealQualification(objDQ[0].Id, objOpp.Id, objDQ.get(0));
        DQ_Deal_Qualification_Approver__c objApprover = [SELECT Id,Submitted_Order__c,Approval_Step__c,Deal_Qualification__c,Approval_Step_Approver__c FROM DQ_Deal_Qualification_Approver__c LIMIT 1];

        System.runAs(ur) {
            DQ_DealQualificationController.checkApprovePermission(objApprover.Id);
        }
        DQ_DealQualificationController.checkIfDQApprovalAcceptorReject(objApprover.Id);
        DQ_DealQualificationController.saveApprovalDetails(objApprover.Id, 'testing', 'Approved', objDQ[0].id);
        DQ_DealQualificationController.revisedDealQualification(objDQ[0]);

        Test.stopTest();

        DQ_DealQualificationController.getApproverByOppId(objOpp.Id, null);
        DQ_DealQualificationController.decimalToBinary(2);
        DQ_DealQualificationController.base64ToBits('test');
        DQ_DealQualificationController.deleteDQDiscountRecord(objDiscount[0]);
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    public static void checkDQApprovalHistory_Test() {
        Opportunity objOpp = [SELECT Id FROM Opportunity where Name = 'Test 1'];
        List<DQ_Deal_Qualification__c> objDQ = DQApprovalTestDataFactory.generateDQ(1, 'Avaya Cloud Office', 'Direct', 'EU', 'Small Business', objOpp.Id);
        insert objDQ;
        List<Product2> productList = Quote_TestDataFactory.generateProducts(1);
        insert productList;

        List<DQ_Deal_Qualification_Discounts__c> objDiscount = DQApprovalTestDataFactory.generateDQDiscount(1, objDQ[0].Id, 70, 'GOA_Devices', productList[0].Id, 80, false);
        insert objDiscount;
        Quote objQuoteRec = [SELECT Id FROM Quote LIMIT 1];
        DQ_DealQualificationController.getDQDealApprovalHistory(objDQ[0].Id);
        DQ_DealQualificationController.getPackageIdFromQuote(objQuoteRec.Id);
        DQ_ApproveRejectEmailTemplateController obj = new DQ_ApproveRejectEmailTemplateController();
        obj.dqId = objDQ[0].Id;
        obj.getDealQualification();
    }
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    public static void Quotejsonwrapper() {
        String quotePackageinfo = '[{"id":"18","version":"1","packageInfo":{"catalogId":"18","version":"1","name":"Office Standard 1/2/100/1000+ Lines - 5100/5101/5102/5103","displayName":"RingCentral Office Standard"},"productName":"Office","duration":"Monthly","edition":{"id":1,"name":"Standard"},"contract":{"id":"a8fP0000000ESuoIAG","extId":"Office","billingId":null},"offerType":"Regular","poc":null,"globalPackageLimits":[{"value":"50000","code":"MONTHLY_AMOUNT_LIMIT","name":"Monthly money amount limit","type":"Amount","scope":"BillingCycle","transactionType":"Any","target":"Global","exclusions":[{"target":"LicenseCategoryId","targetId":"AP"}],"override":false}],"permissions":null}]';
        Quote_QuoteJSONParent.Parse(quotePackageinfo);
        List<Quote_QuoteJSONParent> objWrappList = (List<Quote_QuoteJSONParent>) System.JSON.deserialize(quotePackageinfo, List<Quote_QuoteJSONParent>.class);
        Quote_QuoteJSONParent objQuoteJSONParent = new Quote_QuoteJSONParent();
        objQuoteJSONParent.id = '318';
        objQuoteJSONParent.version = '1';
        objQuoteJSONParent.productName = 'Office';
        //objQuoteJSONParent.duration =  paymentTerm ;
        objQuoteJSONParent.contract = null;
        objQuoteJSONParent.poc = null;
        objQuoteJSONParent.offerType = 'Regular';
        objQuoteJSONParent.permissions = null;

        Quote_QuoteJSONParent.packageInfo objPackageInfo = new Quote_QuoteJSONParent.packageInfo();
        objPackageInfo.catalogId = '318';
        objPackageInfo.version = '1';
        objPackageInfo.name = 'ACO Office Standard 1/2/100/1000+ Lines';

        objQuoteJSONParent.packageInfo = objPackageInfo;

        Quote_QuoteJSONParent.edition objEdition = new Quote_QuoteJSONParent.edition();
        objEdition.id = 1;
        objEdition.name = 'Standard';

        objQuoteJSONParent.edition = objEdition ;

        Quote_QuoteJSONParent.globalPackageLimits objGlobalPackageLimits = new Quote_QuoteJSONParent.globalPackageLimits();
        objGlobalPackageLimits.value = '50000';
        objGlobalPackageLimits.code = 'MONTHLY_AMOUNT_LIMIT';
        objGlobalPackageLimits.name = 'Monthly money amount limit';
        objGlobalPackageLimits.type = 'Amount';
        objGlobalPackageLimits.scope = 'BillingCycle';
        objGlobalPackageLimits.transactionType = 'Any';
        objGlobalPackageLimits.target = 'Global';
        objGlobalPackageLimits.overrideStr = false;

        Quote_QuoteJSONParent.exclusions objExclusions = new Quote_QuoteJSONParent.exclusions();
        objExclusions.target = 'LicenseCategoryId';
        objExclusions.targetId = 'AP';
        objGlobalPackageLimits.exclusions = new List<Quote_QuoteJSONParent.exclusions>{
            objExclusions
        };
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    public static void quoteTemplateCtrl_Test() {
        DQ_QuoteEmailTemplateController qEmailCtrl = new DQ_QuoteEmailTemplateController();
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    public static void verifyDealQualAndDiscountHistory() {
        DQ_DealQualificationController.DealQualAndDiscountHistory result = new DQ_DealQualificationController.DealQualAndDiscountHistory();
        result.dealQualificationHistory = new DQ_Deal_Qualification_History__c();
        result.dealQualDiscountHistory = new List<DQ_Deal_Qualification_Discount_History__c>();
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    public static void verifyPicklistEntryWrapper() {
        DQ_DealQualificationController.PicklistEntryWrapper result = new DQ_DealQualificationController.PicklistEntryWrapper();
        result.active = '';
        result.defaultValue = '';
        result.label = '';
        result.value = '';
        result.validFor = '';
    }

    @isTest
    static void testGetPackageIdFromQuote() {
        Triggers.switchOff();
        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setField(Opportunity.AccountId, ValueProviderBuilder.provideGenericParent(Account.SObjectType))
            .setField(Opportunity.Brand_Name__c, OpportunityHelper.BRAND_RINGCENTRAL_EU)
            .setField(Opportunity.CloseDate, System.today())
            .create()
            .getRecord();

        Triggers.switchOn();

        final String testPackageId = '1952';

        Test.startTest();
        Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.Name => ValueProviderBuilder.provideUniqueString('Test Billing Quote'),
                Quote.OpportunityId => opp.Id,
                Quote.Package_Info__c => NGBSTestDataGenerator.generateQuotePackageInfo(new Map<String, Object>{
                    'Id' => testPackageId
                })
            })
            .create()
            .getRecord();

        Product_package__c testPackage = (Product_package__c) new SObjectBuilder(Product_package__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Product_package__c.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL_EU,
                Product_package__c.Element_Ids__c => testPackageId,
                Product_package__c.Ext_Element_Id__c => testPackageId

            })
            .create()
            .getRecord();

        System.assertEquals(
            testPackage.Id,
            DQ_DealQualificationController.getPackageIdFromQuote(qt.Id),
            'getPackageIdFromQuote method should return package id from associated Product_package__c'
        );
        Test.stopTest();
    }

    @isTest
    static void testGetApproverDetailListByDQId() {
        Opportunity opp = [SELECT Id FROM Opportunity where Name = 'Test 1'];
        List<DQ_Deal_Qualification__c> testDQ = DQApprovalTestDataFactory.generateDQ(
            1,
            'Avaya Cloud Office',
            'Direct',
            'EU',
            'Small Business',
            opp.Id
        );
        insert testDQ;

        List<DQ_Approval_Step__c> apprStep = DQApprovalTestDataFactory.generateDQApprovalStep(1);
        insert apprStep;

        List<DQ_Approval_Step_Approver__c> dqApprovalStepApproverList = DQApprovalTestDataFactory.generateDQApprovalStepApprover(
            1,
            apprStep[0].Id,
            'Avaya Cloud Office',
            'Approval',
            'Direct',
            'EU',
            'Small Business'
        );
        insert dqApprovalStepApproverList;

        DQ_Deal_Qualification_Approver__c dqApprover = new DQ_Deal_Qualification_Approver__c();
        dqApprover.Deal_Qualification__c = testDQ.get(0).Id;
        dqApprover.Approval_Step_Approver__c = dqApprovalStepApproverList.get(0).Id;
        dqApprover.Approval_Step__c = apprStep.get(0).Id;
        dqApprover.Submitted_Order__c = 1;
        dqApprover.Step_Order__c = 1;
        dqApprover.Submitted_Date__c = System.today();
        insert dqApprover;

        List<DQ_DealQualificationController.ApprovalStatusWrapper> wrapper = DQ_DealQualificationController.getApproverDetailListByDQId(testDQ.get(0).Id);
        System.assert(wrapper != null, 'getApproverDetailListByDQId should return not empty wrapper');
        System.assert(!wrapper.get(0).approverList.isEmpty(), 'wrapper should contain not empty approverList');
        System.assertEquals(wrapper.get(0).approverList.get(0).Id, dqApprover.Id);
    }

    @isTest
    static void testGetSmallestStepOrderFromApprovalList() {

        Integer testStepOrder = 2;

        DQ_ApprovalEngine1.ApproverWrapper testApproverWrapper1 = new DQ_ApprovalEngine1.ApproverWrapper();
        testApproverWrapper1.listOfStepApprover = new List<DQ_Approval_Step_Approver__c>{
            new DQ_Approval_Step_Approver__c(),
            new DQ_Approval_Step_Approver__c()
        };
        testApproverWrapper1.approvalStepRecord = new DQ_Approval_Step__c(Step_Order__c = testStepOrder);

        DQ_ApprovalEngine1.ApproverWrapper testApproverWrapper2 = new DQ_ApprovalEngine1.ApproverWrapper();
        testApproverWrapper2.listOfStepApprover = new List<DQ_Approval_Step_Approver__c>{
            new DQ_Approval_Step_Approver__c(),
            new DQ_Approval_Step_Approver__c()
        };
        testApproverWrapper2.approvalStepRecord = new DQ_Approval_Step__c(Step_Order__c = 3);

        List<DQ_ApprovalEngine1.ApproverWrapper> testApproverList = new List<DQ_ApprovalEngine1.ApproverWrapper>{
            testApproverWrapper1,
            testApproverWrapper2
        };

        System.assertEquals(
            testStepOrder,
            DQ_DealQualificationController.getSmallestStepOrderFromApprovalList(testApproverList),
            'method should return smalles StepOrder'
        );
    }

    @isTest
    static void testGetHighestStepOrderFromApprovalList() {

        Integer testStepOrder = 5;

        DQ_ApprovalEngine1.ApproverWrapper testApproverWrapper1 = new DQ_ApprovalEngine1.ApproverWrapper();
        testApproverWrapper1.listOfStepApprover = new List<DQ_Approval_Step_Approver__c>{
            new DQ_Approval_Step_Approver__c(),
            new DQ_Approval_Step_Approver__c()
        };
        testApproverWrapper1.approvalStepRecord = new DQ_Approval_Step__c(Step_Order__c = testStepOrder);

        DQ_ApprovalEngine1.ApproverWrapper testApproverWrapper2 = new DQ_ApprovalEngine1.ApproverWrapper();
        testApproverWrapper2.listOfStepApprover = new List<DQ_Approval_Step_Approver__c>{
            new DQ_Approval_Step_Approver__c(),
            new DQ_Approval_Step_Approver__c()
        };
        testApproverWrapper2.approvalStepRecord = new DQ_Approval_Step__c(Step_Order__c = 3);

        List<DQ_ApprovalEngine1.ApproverWrapper> testApproverList = new List<DQ_ApprovalEngine1.ApproverWrapper>{
            testApproverWrapper1,
            testApproverWrapper2
        };

        System.assertEquals(
            testStepOrder,
            DQ_DealQualificationController.getHighestStepOrderFromApprovalList(testApproverList),
            'method should return highest StepOrder'
        );
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @IsTest
    static void testSubmitForApprovalForDealQualification() {

        User testApprover = (User) new SObjectBuilder(User.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    User.Username => UserHelper.getUniqueUserName(),
                    User.LastName => ValueProviderBuilder.provideUniqueString('LastName'),
                    User.ProfileId => ProfileHelper.PROFILE_ID_SYSADMIN,
                    User.Email => ValueProviderBuilder.provideUniqueEmail(),
                    User.Alias => StringHelper.getRandomString(8),
                    User.TimeZoneSidKey => 'America/Los_Angeles',
                    User.LocaleSidKey => 'en_US',
                    User.EmailEncodingKey => 'UTF-8',
                    User.LanguageLocaleKey => 'en_US',
                    User.Region__c => 'US',
                    User.Sub_Region__c => 'All'
                }
            )
            .create()
            .getRecord();

        DQ_Approval_Step__c dqApprovalStep = (DQ_Approval_Step__c) new SObjectBuilder(DQ_Approval_Step__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    DQ_Approval_Step__c.Name => 'Level 1',
                    DQ_Approval_Step__c.Step_Order__c => 1
                }
            )
            .create()
            .getRecord();

        DQ_Approval_Type__c dqApprovalType = (DQ_Approval_Type__c) new SObjectBuilder(DQ_Approval_Type__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    DQ_Approval_Type__c.IsActive__c => true,
                    DQ_Approval_Type__c.isUnifiedQuotingApprovalType__c => false,
                    DQ_Approval_Type__c.Approval_Type__c => 'Initial Term',
                    DQ_Approval_Type__c.Threshold__c => 12,
                    DQ_Approval_Type__c.ServiceName__c => QuoteHelper.NGBS_OFFICE_PRODUCT
                }
            )
            .create()
            .getRecord();

        DQ_Approval_Type_Step__c approvalTypeStep =
            (DQ_Approval_Type_Step__c) new SObjectBuilder(DQ_Approval_Type_Step__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    DQ_Approval_Type_Step__c.DQ_Approval_Type__c => dqApprovalType.Id,
                    DQ_Approval_Type_Step__c.DQ_Approval_Step__c => dqApprovalStep.Id,
                    DQ_Approval_Type_Step__c.Region__c => 'US',
                    DQ_Approval_Type_Step__c.Segment__c => 'Default',
                    DQ_Approval_Type_Step__c.Deal_Type__c => 'Direct',
                    DQ_Approval_Type_Step__c.Brand__c => 'Default',
                    DQ_Approval_Type_Step__c.Sub_Region__c => 'All'
                }
            )
            .create()
            .getRecord();

        DQ_Approval_Step_Approver__c approvalStepApprover =
            (DQ_Approval_Step_Approver__c) new SObjectBuilder(DQ_Approval_Step_Approver__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    DQ_Approval_Step_Approver__c.Approval_Type__c => 'Approval',
                    DQ_Approval_Step_Approver__c.OwnerId => testApprover.Id,
                    DQ_Approval_Step_Approver__c.DQ_Approval_Step__c => dqApprovalStep.Id,
                    DQ_Approval_Step_Approver__c.Region__c => 'US',
                    DQ_Approval_Step_Approver__c.Segment__c => 'Default',
                    DQ_Approval_Step_Approver__c.Deal_Type__c => 'Direct',
                    DQ_Approval_Step_Approver__c.Brand__c => 'Default',
                    DQ_Approval_Step_Approver__c.Sub_Region__c => 'All',
                    DQ_Approval_Step_Approver__c.Default__c => true
                }
            )
            .create()
            .getRecord();

        Test.startTest();

            Opportunity testOpp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
                .setFields(new Map<SObjectField, Object>{
                    Opportunity.Name => 'Test Opportunity',
                    Opportunity.OwnerId => testApprover.Id,
                    Opportunity.Tier_Name__c => QuoteHelper.NGBS_OFFICE_PRODUCT
                })
                .create()
                .getRecord();

            Quote testQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        Quote.Name => 'Test Quote',
                        Quote.OpportunityId => testOpp.Id,
                        Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                        Quote.ServiceName__c => QuoteHelper.NGBS_OFFICE_PRODUCT,
                        Quote.Initial_Term__c => '24'
                    }
                )
                .create()
                .getRecord();

            DQ_Deal_Qualification__c testDqRecord = (DQ_Deal_Qualification__c) new SObjectBuilder(DQ_Deal_Qualification__c.SObjectType)
                .setFields(new Map<SObjectField, Object>{
                    DQ_Deal_Qualification__c.Opportunity__c => testOpp.Id,
                    DQ_Deal_Qualification__c.Initial_Term__c => '12'
                })
                .create()
                .getRecord();

            DQ_DealQualificationController.submitForApprovalForDealQualification(testDqRecord.Id, testOpp.Id, testDqRecord);

        Test.stopTest();

    }
}