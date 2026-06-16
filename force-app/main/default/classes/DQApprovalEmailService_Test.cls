@isTest
public class DQApprovalEmailService_Test {

    private static Id newSalesRecordTypeId =  Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('New Sales Opportunity').getRecordTypeId();

    @testSetup static void setup() {
        DQApprovalTestDataFactory.generateDealQualificationWithConfig();
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    public static void testEmailServiceApproval() {
        Opportunity objOpp = [SELECT Id FROM Opportunity where Name = 'Test 1'];
        List<DQ_Deal_Qualification__c> objDQ = DQApprovalTestDataFactory.generateDQ(1,'Avaya Cloud Office','Direct','EU','Small Business',objOpp.Id);
        insert objDQ;
        List<Product2> productList = Quote_TestDataFactory.generateProducts(1);
        insert productList;

        List<DQ_Deal_Qualification_Discounts__c> objDiscount = DQApprovalTestDataFactory.generateDQDiscount(1, objDQ[0].Id, 70, 'GOA_Devices', productList[0].Id, 80, false);
        insert objDiscount;
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('PicklistFieldMockResponse');
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json');
        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();
        DQ_DealQualificationController.DealQualificationWrapper objDQWrapper = DQ_DealQualificationController.checkDQExistFOROpp(objOpp.Id);
        DQ_DealQualificationController.saveDealQualification(objDQ[0],objDiscount,true);
        DQ_DealQualificationController.submitForApprovalForDealQualification(objDQ[0].Id,objOpp.Id, objDQ.get(0));

        DQ_Deal_Qualification_Approver__c objApprover = [SELECT Id,Submitted_Order__c,Approval_Step__c,Deal_Qualification__c,Approval_Step_Approver__c FROM DQ_Deal_Qualification_Approver__c LIMIT 1];

        // Create a new email and envelope object.
        Messaging.InboundEmail email = new Messaging.InboundEmail() ;
        Messaging.InboundEnvelope env    = new Messaging.InboundEnvelope();

        // Create Test record.
        Contact cont = new Contact(firstName='john', lastName='smith', Email='test@test.com', HasOptedOutOfEmail=false);
        insert cont ;
        Test.stopTest();

        // Test with the subject that matches the unsubscribe statement.
        email.subject = 'Test Approval Email';
        email.plainTextBody = 'Approved'+'\n'+'_ref::'+objApprover.Id+'::ref_';

        env.fromAddress = 'test@test.com';

        DQApprovalEmailService obj= new DQApprovalEmailService();
        obj.handleInboundEmail(email, env );
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    public static void testEmailServiceApproval_Rejected() {
        Opportunity objOpp = [SELECT Id FROM Opportunity where Name = 'Test 1'];
        List<DQ_Deal_Qualification__c> objDQ = DQApprovalTestDataFactory.generateDQ(1,'Avaya Cloud Office','Direct','EU','Small Business',objOpp.Id);
        insert objDQ;
        List<Product2> productList = Quote_TestDataFactory.generateProducts(1);
        insert productList;

        List<DQ_Deal_Qualification_Discounts__c> objDiscount = DQApprovalTestDataFactory.generateDQDiscount(1, objDQ[0].Id, 70, 'GOA_Devices', productList[0].Id, 80, false);
        insert objDiscount;
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('PicklistFieldMockResponse');
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json');
        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();
        DQ_DealQualificationController.DealQualificationWrapper objDQWrapper = DQ_DealQualificationController.checkDQExistFOROpp(objOpp.Id);
        DQ_DealQualificationController.saveDealQualification(objDQ[0],objDiscount,true);
        DQ_DealQualificationController.submitForApprovalForDealQualification(objDQ[0].Id,objOpp.Id, objDQ.get(0));

        DQ_Deal_Qualification_Approver__c objApprover = [SELECT Id,Submitted_Order__c,Approval_Step__c,Deal_Qualification__c,Approval_Step_Approver__c FROM DQ_Deal_Qualification_Approver__c LIMIT 1];

        // Create a new email and envelope object.
        Messaging.InboundEmail email = new Messaging.InboundEmail() ;
        Messaging.InboundEnvelope env    = new Messaging.InboundEnvelope();

        // Create Test record.
        Contact cont = new Contact(firstName='john', lastName='smith', Email='test@test.com', HasOptedOutOfEmail=false);
        insert cont ;
        Test.stopTest();

        // Test with the subject that matches the unsubscribe statement.
        email.subject = 'Test Approval Email';
        email.plainTextBody = 'Rejected'+'\n'+'_ref::'+objApprover.Id+'::ref_';

        env.fromAddress = 'test@test.com';

        DQApprovalEmailService obj= new DQApprovalEmailService();
        obj.handleInboundEmail(email, env );

        DQApprovalEmailService obj1= new DQApprovalEmailService();
        obj1.handleInboundEmail(email, env );
    }
}