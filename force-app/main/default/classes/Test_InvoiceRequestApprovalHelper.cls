@IsTest
public with sharing class Test_InvoiceRequestApprovalHelper {
    public static final String DIRECTOR_BO_NAME = 'Jane Yang';
    public static final String TREASURE_MANAGER_NAME = 'Lin Wang';
    public static final String TREASURER_NAME = 'Teo Kridech';
    public static final String CONTROLLER_NAME = 'Vaibhav Agarwal';
    public static final String INVOICE_CONTROLLER ='Candice Barcela';

    @isTest
    static void testInvoiceRequestApproval() {

        new SObjectBuilder(RingCentralVariousSettings__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                RingCentralVariousSettings__c.Director_BO_Invoice_Billing_Approver__c => DIRECTOR_BO_NAME,
                RingCentralVariousSettings__c.Treasurer_Invoice_Billing_Approve__c => TREASURE_MANAGER_NAME,
                RingCentralVariousSettings__c.Treasure_Manager_Invoice_Billing_Approve__c => TREASURER_NAME,
                RingCentralVariousSettings__c.Controller_Invoice_Billing_Approver__c => CONTROLLER_NAME,
                RingCentralVariousSettings__c.Controller_for_Invoice_Request__c => INVOICE_CONTROLLER
            })
            .create();

        Triggers.switchOff();
        Account testAccount = new Account(Name = 'testAcc', BillingStreet = '3022  Strother Street', BillingCity = 'Into', BillingState = 'Alabama', BillingPostalCode = '35222',BillingCountry = 'United States');
        insert testAccount;

        Contact contact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(Contact.SObjectType))
            .setField(Contact.AccountId, testAccount.Id)
            .create()
            .getRecord();

        AccountContactRole payableContactRole = new AccountContactRole();
        payableContactRole.AccountId = testAccount.Id;
        payableContactRole.ContactId = contact.Id;
        payableContactRole.Role = AccountContactRoleHelper.CONTACT_ROLE_ACCOUNT_PAYABLE;
        payableContactRole.IsPrimary = true; 	
        insert payableContactRole;

        Opportunity testOppty = new Opportunity (Name = 'testOpty',AccountId = testAccount.Id, StageName = 'Qualify',
                                                 CloseDate = system.today()+10);
        insert testOppty;

        Triggers.switchOn();

        Approval__c testApproval = new Approval__c(
            Account__c = testAccount.Id,
            Opportunity__c = testOppty.Id,
            Invoice_Terms__c = '3',
            Payment_Terms__c = '7',
            Potential_Users__c = 1,
            Accounts_Payable_Email_Address__c = 'test@test.com',
            Reason_Customer_is_Requesting_Invoicing__c = 'Test',
            Why_RingCentral_Should_Invoice_Customer__c = 'Test',
            Initial_Number_of_Users__c = 1,
            Initial_Number_of_Devices__c = 1,
            Price_per_User__c = 1,
			Industry__c = 'Media',
            Tax_Exempt_Approval__c = false,
            Sign_Up_Purchase_Limit__c = 1,
            Monthly_Credit_Limit__c = 1,
            Name = 'testApproval',
            Status__c = 'Required',
            RecordTypeId = ApprovalHelper.RT_ID_INVOICING_REQUEST,
            AccountPayableContact__c = contact.Id);

        insert testApproval;
        Test.startTest();
        string InvoiceReq = SubmitforInvoiceApproval.submitApproval(testApproval.Id, 'Approve');
        ProcessInstance prcInst = [SELECT Id, (SELECT Id,
        processInstanceId,
        processInstance.Status,
        processInstance.submittedById,
        TargetObjectId,
        StepStatus,
        OriginalActor.Name,
        CreatedDate,
        ProcessNode.Name FROM StepsAndWorkitems WHERE ProcessNode.Name != NULL
        )
        FROM ProcessInstance
        WHERE TargetObjectId =: testApproval.Id];

        Approval__c apprQueue = [select id, InvoiceApprovalType__c, Status__c from Approval__c where id =: testApproval.Id];
        InvoiceRequestApprovalHelper irah = new InvoiceRequestApprovalHelper(apprQueue, ApprovalHelper.FINANCE_EXCEPTION_APPROVAL); 
        System.enqueueJob(irah);

        Test.stopTest();
        Approval__c resultApproval = [SELECT Id, Status__c FROM Approval__c WHERE Id =: testApproval.Id];
        System.assertEquals(ApprovalHelper.STATUS_PENDING_L3_APPROVAL, resultApproval.Status__c, 'Status should be PendingL3Approval');
    }

    @isTest
    static void testInvoiceRequestApprovalRetry() {

        new SObjectBuilder(RingCentralVariousSettings__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                RingCentralVariousSettings__c.Director_BO_Invoice_Billing_Approver__c => DIRECTOR_BO_NAME,
                RingCentralVariousSettings__c.Treasurer_Invoice_Billing_Approve__c => TREASURE_MANAGER_NAME,
                RingCentralVariousSettings__c.Treasure_Manager_Invoice_Billing_Approve__c => TREASURER_NAME,
                RingCentralVariousSettings__c.Controller_Invoice_Billing_Approver__c => CONTROLLER_NAME,
                RingCentralVariousSettings__c.Controller_for_Invoice_Request__c => INVOICE_CONTROLLER
            })
            .create();

        Triggers.switchOff();
        Account testAccount = new Account(Name = 'testAcc', BillingStreet = '3022  Strother Street', BillingCity = 'Into', BillingState = 'Alabama', BillingPostalCode = '35222',BillingCountry = 'United States');
        insert testAccount;

        Contact contact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(Contact.SObjectType))
            .setField(Contact.AccountId, testAccount.Id)
            .create()
            .getRecord();

        AccountContactRole payableContactRole = new AccountContactRole();
        payableContactRole.AccountId = testAccount.Id;
        payableContactRole.ContactId = contact.Id;
        payableContactRole.Role = AccountContactRoleHelper.CONTACT_ROLE_ACCOUNT_PAYABLE;
        payableContactRole.IsPrimary = true; 	
        insert payableContactRole;

        Opportunity testOppty = new Opportunity (Name = 'testOpty',AccountId = testAccount.Id, StageName = 'Qualify',
                                                 CloseDate = system.today()+10);
        insert testOppty;

        Triggers.switchOn();

        Approval__c testApproval = new Approval__c(
            Account__c = testAccount.Id,
            Opportunity__c = testOppty.Id,
            Invoice_Terms__c = '3',
            Payment_Terms__c = '7',
            Potential_Users__c = 1,
            Accounts_Payable_Email_Address__c = 'test@test.com',
            Reason_Customer_is_Requesting_Invoicing__c = 'Test',
            Why_RingCentral_Should_Invoice_Customer__c = 'Test',
            Initial_Number_of_Users__c = 1,
            Initial_Number_of_Devices__c = 1,
            Price_per_User__c = 1,
			Industry__c = 'Media',
            Tax_Exempt_Approval__c = false,
            Sign_Up_Purchase_Limit__c = 1,
            Monthly_Credit_Limit__c = 1,
            Name = 'testApproval',
            Status__c = 'Required',
            RecordTypeId = ApprovalHelper.RT_ID_INVOICING_REQUEST,
            AccountPayableContact__c = contact.Id);

        insert testApproval;
        Test.startTest();
        string InvoiceReq = SubmitforInvoiceApproval.submitApproval(testApproval.Id, 'Approve');
        ProcessInstance prcInst = [SELECT Id, (SELECT Id,
        processInstanceId,
        processInstance.Status,
        processInstance.submittedById,
        TargetObjectId,
        StepStatus,
        OriginalActor.Name,
        CreatedDate,
        ProcessNode.Name FROM StepsAndWorkitems WHERE ProcessNode.Name != NULL
        )
        FROM ProcessInstance
        WHERE TargetObjectId =: testApproval.Id];

        Approval__c apprQueue = [select id, InvoiceApprovalType__c, Status__c from Approval__c where id =: testApproval.Id];
        InvoiceRequestApprovalHelper irah = new InvoiceRequestApprovalHelper(apprQueue, ApprovalHelper.DB_CREDIT_CHECK, 1); 
        System.enqueueJob(irah);
        Test.stopTest();

        Approval__c resultApproval = [SELECT Id, Status__c FROM Approval__c WHERE Id =: testApproval.Id];
        System.assertEquals(ApprovalHelper.STATUS_PENDING_L4_APPROVAL, resultApproval.Status__c, 'Status should be PendingL4Approval');
    }
}