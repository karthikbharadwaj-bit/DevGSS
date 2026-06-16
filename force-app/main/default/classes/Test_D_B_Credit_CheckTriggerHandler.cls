@isTest
private class Test_D_B_Credit_CheckTriggerHandler  {

    public static final String DIRECTOR_BO_NAME = 'Jane Yang';
    public static final String TREASURE_MANAGER_NAME = 'Lin Wang';
    public static final String TREASURER_NAME = 'Teo Kridech';
    public static final String CONTROLLER_NAME = 'Vaibhav Agarwal';
    public static final String INVOICE_CONTROLLER ='Candice Barcela';

    @testSetup
    static void setup() {
    insert new RingCentralVariousSettings__c(
                            Director_BO_Invoice_Billing_Approver__c = DIRECTOR_BO_NAME,
                            Treasure_Manager_Invoice_Billing_Approve__c = TREASURE_MANAGER_NAME,
                            Treasurer_Invoice_Billing_Approve__c = TREASURER_NAME,
                            Controller_Invoice_Billing_Approver__c = CONTROLLER_NAME,
                            Controller_for_Invoice_Request__c  = INVOICE_CONTROLLER);
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    private static void DBApplicationReturningApprovedStatusShouldApproveApprovalProcess() {

        Triggers.switchOff();
        Triggers.except(ApprovalTriggerHandler.DNBInvoiceAndPartnerApprovalHandler.class.toString());
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
        Triggers.switchOn();

        Test.startTest();

        D_B_Credit_Check__c dnbiRecordFromApproval = [SELECT Id, D_B_Status__c, Approval__c
                                                      FROM D_B_Credit_Check__c
                                                      WHERE Approval__c =: appr.Id
                                                      LIMIT 1];

        dnbiRecordFromApproval.D_B_Status__c = 'Approved';
        update dnbiRecordFromApproval;

        Id dnbiUser = (D_B_Credit_CheckObj.getDnbiUser()).Id;

        Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
        req.setComments('Submitting request for approval.');
        req.setObjectId(appr.Id);
        req.setSubmitterId(UserInfo.getUserId());
        req.setProcessDefinitionNameOrId(ApprovalHelper.PROCESS_INVOICE_REQUEST_APPROVAL);
        req.setSkipEntryCriteria(false);
        Approval.ProcessResult result = Approval.process(req);
        List<Id> newWorkItemIds = result.getNewWorkitemIds();

        Approval.ProcessWorkitemRequest req2 =
            new Approval.ProcessWorkitemRequest();
        req2.setComments('Approving request.');
        req2.setAction('Approve');
        req2.setNextApproverIds(new Id[] {dnbiUser});
        req2.setWorkitemId(newWorkItemIds.get(0));
        Approval.ProcessResult result2 =  Approval.process(req2);
        newWorkItemIds = result2.getNewWorkitemIds();

        ObjectCache.removeKey(ObjectCache.Partition.QUERIES, 'selectUserForApproval');

        Approval.ProcessWorkitemRequest req3 =
            new Approval.ProcessWorkitemRequest();
        req3.setComments('Approving request.');
        req3.setAction('Approve');
        req3.setNextApproverIds(new Id[] {dnbiUser});
        req3.setWorkitemId(newWorkItemIds.get(0));
        Approval.ProcessResult result3 =  Approval.process(req3);
        newWorkItemIds = result3.getNewWorkitemIds();

        List<Id> mapAppId = new List<Id>();
        mapAppId.add(dnbiRecordFromApproval.Approval__c);


        List<ProcessInstanceWorkitem> currentApprovers = [SELECT Id, ActorId, ProcessInstanceId, ProcessInstance.TargetObjectId
                                                          FROM ProcessInstanceWorkitem
                                                          WHERE ProcessInstance.TargetObjectId IN :mapAppId
                                                          ORDER BY CreatedDate DESC];

        D_B_Credit_CheckObj processApproval = new D_B_Credit_CheckObj();
        processApproval.approveDNBStep(dnbiRecordFromApproval, currentApprovers);

        Test.stopTest();

        List<ProcessInstance> lastApprovalStep = [SELECT TargetObjectId,
                                                  (SELECT StepStatus, CreatedDate, OriginalActorId
                                                   FROM Steps
                                                   ORDER BY CreatedDate DESC
                                                   LIMIT 1),
                                                  (SELECT StepStatus, CreatedDate, OriginalActorId
                                                   FROM StepsAndWorkitems
                                                   ORDER BY CreatedDate DESC
                                                   LIMIT 1)
                                                  FROM ProcessInstance
                                                  WHERE TargetObjectId = :appr.Id
                                                  ORDER BY CreatedDate ASC];

        /* system.assertEquals('Approved', lastApprovalStep[0].StepsAndWorkitems[0].StepStatus,
                            'Approval Step should have been Approved based on D&B Status'); */
    }

    @isTest
    private static void DBApplicationReturningPendingStatusShouldSendAnEmail() {

        Id dnbiUser = D_B_Credit_CheckObj.getDnbiUser().Id;

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
        appr.Status__c = ApprovalHelper.STATUS_PENDING_L1_APPROVAL;
        appr.Potential_Users__c = 1;
        appr.Reason_Customer_is_Requesting_Invoicing__c = 'test';
        insert appr;

        Test.startTest();

            List<D_B_Credit_Check__c> dnbiRecordFromApproval = [SELECT Id, D_B_Status__c
                                                                FROM D_B_Credit_Check__c
                                                                WHERE Approval__c =: appr.Id];
            dnbiRecordFromApproval[0].D_B_Status__c = 'Further Review Required';
            update dnbiRecordFromApproval;

            Integer emailInvocations = Limits.getEmailInvocations();

        Test.stopTest();

        system.assertEquals(1, emailInvocations, 'An email should be sent');
    }
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    private static void DBApplicationReturningDeclinedStatusShouldRejectApprovalProcess() {
    /*


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

        appr.Opportunity__c = oppty.Id;
        appr.Account__c = acc.Id;

        appr.RecordTypeId = Schema.SObjectType.Approval__c.getRecordTypeInfosByName()
                                                                .get('Invoicing Request')
                                                                .getRecordTypeId();
        appr.Monthly_Credit_Limit__c = 501;
        appr.Sign_up_Purchase_Limit__c = 99999;
        insert appr;
        User dnbiUser = D_B_Credit_CheckObj.getDnbiUser();

        D_B_Credit_Check__c dnbiRecordFromApproval = [SELECT Id, D_B_Status__c, Approval__c
                                                      FROM D_B_Credit_Check__c
                                                      WHERE Approval__c =: appr.Id
                                                      LIMIT 1];

        Test.startTest();

        Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
        req.setComments('Submitting request for approval.');
        req.setObjectId(appr.Id);
        req.setSubmitterId(UserInfo.getUserId());
        req.setProcessDefinitionNameOrId(ApprovalHelper.PROCESS_INVOICE_REQUEST_APPROVAL);
        req.setSkipEntryCriteria(false);
        Approval.ProcessResult result = Approval.process(req);
        List<Id> newWorkItemIds = result.getNewWorkitemIds();

        Approval.ProcessWorkitemRequest req2 =
            new Approval.ProcessWorkitemRequest();
        req2.setComments('Approving request.');
        req2.setAction('Approve');
        req2.setNextApproverIds(new Id[] {dnbiUser.Id});
        req2.setWorkitemId(newWorkItemIds.get(0));
        Approval.ProcessResult result2 =  Approval.process(req2);
        newWorkItemIds = result2.getNewWorkitemIds();

        ObjectCache.removeKey(ObjectCache.Partition.QUERIES, 'selectUserForApproval');

        Approval.ProcessWorkitemRequest req3 =
            new Approval.ProcessWorkitemRequest();
        req3.setComments('Approving request.');
        req3.setAction('Approve');
        req3.setNextApproverIds(new Id[] {dnbiUser.Id});
        req3.setWorkitemId(newWorkItemIds.get(0));
        Approval.ProcessResult result3 =  Approval.process(req3);
        newWorkItemIds = result3.getNewWorkitemIds();

        Approval.ProcessWorkitemRequest req4 =
            new Approval.ProcessWorkitemRequest();
        req4.setComments('Approving request.');
        req4.setAction('Reject');
        req4.setWorkitemId(newWorkItemIds.get(0));
        Approval.ProcessResult result4 =  Approval.process(req4);
        newWorkItemIds = result4.getNewWorkitemIds();


        List<ProcessInstanceWorkitem> currentApprovers = [SELECT Id, ActorId, ProcessInstanceId, ProcessInstance.TargetObjectId
                                                          FROM ProcessInstanceWorkitem
                                                          WHERE ProcessInstance.TargetObjectId = :appr.Id
                                                          ORDER BY CreatedDate DESC];


        Test.stopTest();

        List<ProcessInstance> lastApprovalStep = [SELECT TargetObjectId,
                                                  (SELECT StepStatus, CreatedDate, OriginalActorId
                                                   FROM Steps
                                                   ORDER BY CreatedDate DESC),
                                                  (SELECT StepStatus, CreatedDate, OriginalActorId
                                                   FROM StepsAndWorkitems
                                                   ORDER BY CreatedDate DESC )
                                                  FROM ProcessInstance
                                                  WHERE TargetObjectId = :appr.Id
                                                  ORDER BY CreatedDate ASC];

        system.assertEquals('Rejected', lastApprovalStep[0].StepsAndWorkitems[0].StepStatus,
                            'Approval Step should have been Rejected based on D&B Status');
        system.assertEquals(dnbiUser.Id, lastApprovalStep[0].Steps[0].OriginalActorId);

    */
    }
    @isTest
    private static void DNBiRecordCreationForBob() {

        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.RecordTypeId => AccountHelper.RT_ID_PARTNER_ACCOUNT,
                    Account.Partner_Type__c => 'Bill-on-Behalf',
                    Account.PartnerStatus__c => 'New',
                    Account.Name => 'TestBoBAccount',
                    Account.Partner_ID__c => '114880',
                    Account.Partner_Account_Name__c => '114880-Name',
                    Account.Permitted_Brands__c => 'RingCentral',
                    Account.VAR_Territory__c => 'TerrTest'
                }
            )
            .create()
            .getRecord();

        Approval__c bobApproval = (Approval__c) new SObjectBuilder(Approval__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Approval__c.RecordTypeId => ApprovalHelper.RT_ID_BOB_APPROVAL,
                Approval__c.Account__c => acc.Id,
                Approval__c.Partner_Type__c => acc.Partner_Type__c,
                Approval__c.Brands_Permitted_to_Sell__c => acc.Permitted_Brands__c,
                Approval__c.VAR_Territory__c => acc.VAR_Territory__c,
                Approval__c.Partner_Account_ID__c => acc.Partner_ID__c,
                Approval__c.Partner_MRR__c => 100
            })
            .build()
            .getRecord();

        Test.startTest();
        insert bobApproval;
        Test.stopTest();



        D_B_Credit_Check__c dnbiRecordFromApproval = [SELECT Id, D_B_Status__c, Approval__c
                                                      FROM D_B_Credit_Check__c
                                                      WHERE Approval__c =: bobApproval.Id
                                                      LIMIT 1];

        Approval__c bobApprovalAfter = [SELECT Id, Partner_MRR__c, Sign_Up_Purchase_Limit__c
                                                      FROM Approval__c
                                                      WHERE id =: bobApproval.Id
                                                      LIMIT 1];

        System.assertEquals(bobApproval.Id, dnbiRecordFromApproval.Approval__c, 'D_B_Credit_Check__c was not created');
        System.assertEquals(bobApprovalAfter.Partner_MRR__c, bobApprovalAfter.Sign_Up_Purchase_Limit__c, 'Partner MRR was not copied to Sign_Up_Purchase_Limit__c');
    }

    @isTest
    private static void DNBiRecordUpdateForBob() {

        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.RecordTypeId => AccountHelper.RT_ID_PARTNER_ACCOUNT,
                    Account.Partner_Type__c => 'Bill-on-Behalf',
                    Account.PartnerStatus__c => 'New',
                    Account.Name => 'TestBoBAccount',
                    Account.Partner_ID__c => '114880',
                    Account.Partner_Account_Name__c => '114880-Name',
                    Account.Permitted_Brands__c => 'RingCentral',
                    Account.VAR_Territory__c => 'TerrTest'
                }
            )
            .create()
            .getRecord();

        Approval__c bobApproval = (Approval__c) new SObjectBuilder(Approval__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Approval__c.RecordTypeId => ApprovalHelper.RT_ID_BOB_APPROVAL,
                Approval__c.Account__c => acc.Id,
                Approval__c.Partner_Type__c => acc.Partner_Type__c,
                Approval__c.Brands_Permitted_to_Sell__c => acc.Permitted_Brands__c,
                Approval__c.VAR_Territory__c => acc.VAR_Territory__c,
                Approval__c.Partner_Account_ID__c => acc.Partner_ID__c,
                Approval__c.Partner_MRR__c => 100
            })
            .create()
            .getRecord();

        D_B_Credit_Check__c dnbiRecordFromApproval = [SELECT Id, D_B_Status__c, Approval__c
                                                      FROM D_B_Credit_Check__c
                                                      WHERE Approval__c =: bobApproval.Id
                                                      LIMIT 1];

        Approval__c bobApprovalAfterInsert = [SELECT Id, Partner_MRR__c, Sign_Up_Purchase_Limit__c
                                                      FROM Approval__c
                                                      WHERE id =: bobApproval.Id
                                                      LIMIT 1];

        System.assertEquals(bobApproval.Id, dnbiRecordFromApproval.Approval__c, 'D_B_Credit_Check__c was not created');
        System.assertEquals(bobApprovalAfterInsert.Partner_MRR__c, bobApprovalAfterInsert.Sign_Up_Purchase_Limit__c, 'Partner MRR was not copied to Sign_Up_Purchase_Limit__c');

        bobApproval.Partner_MRR__c = 200;

        Test.startTest();
        update bobApproval;
        Test.stopTest();

        Approval__c bobApprovalAfterUpdate = [SELECT Id, Partner_MRR__c, Sign_Up_Purchase_Limit__c
                                                      FROM Approval__c
                                                      WHERE id =: bobApproval.Id
                                                      LIMIT 1];

        System.assertEquals(200, bobApprovalAfterUpdate.Sign_Up_Purchase_Limit__c, 'Partner MRR was not updated to Sign_Up_Purchase_Limit__c');
        System.assertEquals(200, bobApprovalAfterUpdate.Partner_MRR__c, 'Partner MRR was not updated to Sign_Up_Purchase_Limit__c');
    }

    @isTest
    private static void DBApplicationReturningPendingStatusShouldSendAnEmailForBob() {

        Id dnbiUser = D_B_Credit_CheckObj.getDnbiUser().Id;

        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.RecordTypeId => AccountHelper.RT_ID_PARTNER_ACCOUNT,
                    Account.Partner_Type__c => 'Bill-on-Behalf',
                    Account.PartnerStatus__c => 'New',
                    Account.Name => 'TestBoBAccount',
                    Account.Partner_ID__c => '114880',
                    Account.Partner_Account_Name__c => '114880-Name',
                    Account.Permitted_Brands__c => 'RingCentral',
                    Account.VAR_Territory__c => 'TerrTest'
                }
            )
            .create()
            .getRecord();

        Approval__c bobApproval = (Approval__c) new SObjectBuilder(Approval__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Approval__c.RecordTypeId => ApprovalHelper.RT_ID_BOB_APPROVAL,
                Approval__c.Account__c => acc.Id,
                Approval__c.Partner_Type__c => acc.Partner_Type__c,
                Approval__c.Brands_Permitted_to_Sell__c => acc.Permitted_Brands__c,
                Approval__c.VAR_Territory__c => acc.VAR_Territory__c,
                Approval__c.Partner_Account_ID__c => acc.Partner_ID__c,
                Approval__c.Partner_MRR__c => 100
            })
            .create()
            .getRecord();


        Test.startTest();
        List<D_B_Credit_Check__c> dnbiRecordFromApproval = [SELECT Id, D_B_Status__c
                                                            FROM D_B_Credit_Check__c
                                                            WHERE Approval__c =: bobApproval.Id];

        dnbiRecordFromApproval[0].D_B_Status__c = D_B_Credit_CheckTriggerHandler.DNBI_FURTHER_REVIEW;
        update dnbiRecordFromApproval;
        Integer emailInvocations = Limits.getEmailInvocations();
        Test.stopTest();
        system.assertEquals(1, emailInvocations, 'An email should be sent');
    }

    @isTest
    private static void DBApplicationReturningPendingStatusShouldSendAnEmailForWholesale() {

        Id dnbiUser = D_B_Credit_CheckObj.getDnbiUser().Id;

        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.RecordTypeId => AccountHelper.RT_ID_PARTNER_ACCOUNT,
                    Account.Partner_Type__c => AccountHelper.ACCOUNT_PARTNER_WHOLESALE,
                    Account.PartnerStatus__c => AccountHelper.NEW_STATUS,
                    Account.Name => 'TestWholesaleAccount',
                    Account.Partner_ID__c => '114880',
                    Account.Partner_Account_Name__c => '114880-Name',
                    Account.Permitted_Brands__c => 'RingCentral',
                    Account.VAR_Territory__c => 'TerrTest'
                }
            )
            .create()
            .getRecord();

        Approval__c wholesaleApproval = (Approval__c) new SObjectBuilder(Approval__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Approval__c.RecordTypeId => ApprovalHelper.RT_ID_WHOLESALE_APPROVAL,
                Approval__c.Account__c => acc.Id,
                Approval__c.Partner_Type__c => acc.Partner_Type__c,
                Approval__c.Brands_Permitted_to_Sell__c => acc.Permitted_Brands__c,
                Approval__c.VAR_Territory__c => acc.VAR_Territory__c,
                Approval__c.Partner_Account_ID__c => acc.Partner_ID__c,
                Approval__c.Partner_MRR__c => 100
            })
            .create()
            .getRecord();


        Test.startTest();
        List<D_B_Credit_Check__c> dnbiRecordFromApproval = [SELECT Id, D_B_Status__c
                                                            FROM D_B_Credit_Check__c
                                                            WHERE Approval__c =: wholesaleApproval.Id];

        dnbiRecordFromApproval[0].D_B_Status__c = D_B_Credit_CheckTriggerHandler.DNBI_FURTHER_REVIEW;
        update dnbiRecordFromApproval;
        Integer emailInvocations = Limits.getEmailInvocations();
        Test.stopTest();
        System.assertEquals(1, emailInvocations, 'An email should be sent');
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    private static void testApproveIfDNBIUserIsApprover() {
        Id dnbiUser = (D_B_Credit_CheckObj.getDnbiUser()).Id;
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

        Approval__c appr = (Approval__c) new SObjectBuilder(Approval__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Approval__c.Opportunity__c => oppty.Id,
                Approval__c.Account__c => acc.Id,
                Approval__c.RecordTypeId => ApprovalHelper.RT_ID_INVOICING_REQUEST,
                Approval__c.Monthly_Credit_Limit__c => 501,
                Approval__c.Sign_up_Purchase_Limit__c => 99999,
                Approval__c.AccountPayableContact__c => contact.Id,
                Approval__c.Potential_Users__c => 1,
                Approval__c.Reason_Customer_is_Requesting_Invoicing__c => 'test'
            })
            .create()
            .getRecord();

        Test.startTest();
            D_B_Credit_Check__c dnbiRecordFromApproval = [
                SELECT Id, D_B_Status__c, Approval__c
                FROM D_B_Credit_Check__c
                WHERE Approval__c = : appr.Id
                LIMIT 1
            ];

            Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
            req.setComments('Submitting request for approval.');
            req.setObjectId(appr.Id);
            req.setSubmitterId(UserInfo.getUserId());
            req.setNextApproverIds(new Id[] {dnbiUser});
            req.setProcessDefinitionNameOrId(ApprovalHelper.PROCESS_INVOICE_REQUEST_APPROVAL);
            req.setSkipEntryCriteria(false);
            Approval.ProcessResult result = Approval.process(req);
            List<Id> newWorkItemIds = result.getNewWorkitemIds();

            Approval.ProcessWorkitemRequest req2 = new Approval.ProcessWorkitemRequest();
            req2.setComments('Approving request.');
            req2.setAction('Approve');
            req2.setNextApproverIds(new Id[] {dnbiUser});
            req2.setWorkitemId(newWorkItemIds.get(0));
            Approval.ProcessResult result2 =  Approval.process(req2);

            dnbiRecordFromApproval.D_B_Status__c = 'Approved';
            dnbiRecordFromApproval.Approval__c = appr.Id;
            update dnbiRecordFromApproval;
        Test.stopTest();
    }
}