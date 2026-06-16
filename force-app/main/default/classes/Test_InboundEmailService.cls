@isTest
private class Test_InboundEmailService {

    private static Opportunity testOpportunity;
    private static List<Contract> contractList;

    private static void createTestData() {
        Account testAcc = new Account(Name = 'testAccount');
        insert testAcc;

        testOpportunity = new Opportunity(
            Name = 'testOpportunity',
            AccountId = testAcc.Id,
            StageName = OpportunityHelper.STAGE_NAME_ORDER,
            ConfirmAndClose__c = false
        );
        insert testOpportunity;

        Quote testQuote = new Quote(
            Name = 'testQuote',
            OpportunityId = testOpportunity.id,
            Pricebook2Id = Test.getStandardPricebookId()
        );
        insert testQuote;

        Contact testContact = new Contact(
            AccountId = testAcc.Id,
            LastName = 'testMan',
            FirstName = 'testMan',
            Email = 'testFrom@gmail.com'
        );
        insert testContact;

        OpportunityContactRole opConRole = new OpportunityContactRole(
            OpportunityId = testOpportunity.Id,
            Role = 'Signatory',
            IsPrimary = true,
            ContactId = testContact.Id);
        insert opConRole;

        Feature_toggle__c featureToggle = new Feature_toggle__c(Approval_For_Change_Order_Process__c = true);
        insert featureToggle;

        RC_Quote_Template__c testTemplate = new RC_Quote_Template__c(
            Name = 'test',
            Brand__c = 'RingCentral',
            Description__c = 'test123',
            Type__c = 'test',
            Language__c = 'English',
            Parameters__c = null,
            CSS_Styles_1__c = 'body{ font-size: 12pt;}'
        );

        insert testTemplate;

        TemplateSections__c section = new TemplateSections__c(
            Name='Section Name',
            Content_1__c = 'Hello-',
            Content_2__c = '{! Name }!',
            CSS_Styles_1__c = 'body{ font-size: 12pt;}'
        );
        insert section;

        TemplateSectionJunction__c junction = new TemplateSectionJunction__c(
            Position__c = 1.00,
            RC_Quote_Template__c = testTemplate.id,
            Template_Section__c = section.id
        );
        insert junction;

        RC_Quote_Templates__c rcQuoteTemplate = new RC_Quote_Templates__c(
            Name = 'CustomerNotificationOnConfirmAndClose',
            TemplateId__c = testTemplate.Id
        );
        insert rcQuoteTemplate;

        contractList = (List<Contract>) new SObjectBuilder(Contract.SObjectType)
            .setField(Contract.Name, 'Test Contract')
            .setField(Contract.AccountId, ValueProviderBuilder.provideParents(new List<Account>{testAcc}))
            .quantity(3)
            .create()
            .getRecords();
    }

    @isTest
    static void testRestrictedSectionExpired() {

        createTestData();
        // Create a new email and envelope object
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        email.subject = 'Opportunity ';
        email.plainTextBody = 'Reject';
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        env.fromAddress = 'testFrom@gmail.com';
        env.toAddress = 'testTo@gmail.com';
        //Prepopulate orgWideEmailMap
        Map<String, String> orgWideMap = new Map<String, String>{'InboundEmailService' => 'testTo@gmail.com'};
        InboundEmailService.orgWideEmailMap = orgWideMap;
        Test.startTest();
            InboundEmailService testInbound = new InboundEmailService();
            Messaging.InboundEmailResult rejectResult = testInbound.handleInboundEmail(email,env);
        Test.stopTest();
        System.assertEquals(false, rejectResult.success);
        System.assertEquals('This request has already expired. Please respond to the most recent email received', rejectResult.message);
    }

    @isTest
    static void testWrongSenderAddress() {

        createTestData();
        // Prepopulate orgWideEmailMap
        Map<String, String> orgWideMap = new Map<String, String>{'InboundEmailService' => 'testTo@gmail.com'};
        InboundEmailService.orgWideEmailMap = orgWideMap;
        // Trigger Uuid generation for opportunity
        testOpportunity.ConfirmAndClose__c = true;
        update testOpportunity;
        Opportunity optyWithUuid = [SELECT Uuid__c FROM Opportunity WHERE Id = :testOpportunity.Id];
        // Create a new email and envelope object
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        email.subject = 'Opportunity';
        email.fromAddress = 'testWrongFrom@gmail.com';
        email.plainTextBody = 'Reject' + '/------' + optyWithUuid.Uuid__c + '------/';
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        env.fromAddress = 'testFrom@gmail.com';
        env.toAddress = 'testTo@gmail.com';
        Test.startTest();
            InboundEmailService testInbound = new InboundEmailService();
            Messaging.InboundEmailResult result = testInbound.handleInboundEmail(email,env);
        Test.stopTest();
        System.assertEquals(false, result.success);
        System.assertEquals('You are not authorized to Approve or Reject this change. Please contact your Account Manager at RingCentral for assistance', result.message);
    }

    @isTest
    static void testOpportunityIsInAgreementStage() {

        createTestData();
        // Prepopulate orgWideEmailMap
        Map<String, String> orgWideMap = new Map<String, String>{'InboundEmailService' => 'testTo@gmail.com'};
        InboundEmailService.orgWideEmailMap = orgWideMap;
        // Trigger Uuid generation for opportunity
        testOpportunity.ConfirmAndClose__c = true;
        update testOpportunity;
        Opportunity optyWithUuid = [SELECT Uuid__c FROM Opportunity WHERE Id = :testOpportunity.Id];
        // create a new email and envelope object
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        email.subject = 'Opportunity';
        email.fromAddress = 'testFrom@gmail.com';
        email.plainTextBody = 'Reject' + '/------' + optyWithUuid.Uuid__c + '------/';
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        env.fromAddress = 'testFrom@gmail.com';
        env.toAddress = 'testTo@gmail.com';
        // Close the opportunity
        optyWithUuid.StageName = OpportunityHelper.STAGE_NAME_AGREEMENT;
        update optyWithUuid;
        Test.startTest();
            InboundEmailService testInbound = new InboundEmailService();
            Messaging.InboundEmailResult result = testInbound.handleInboundEmail(email,env);
        Test.stopTest();
        System.assertEquals(false, result.success);
        System.assertEquals('Opportunity is already in Agreement stage', result.message);
    }

    @isTest
    static void testCustomerApproved() {

        createTestData();
        // Prepopulate orgWideEmailMap
        Map<String, String> orgWideMap = new Map<String, String>{'InboundEmailService' => 'testTo@gmail.com'};
        InboundEmailService.orgWideEmailMap = orgWideMap;
        // Trigger Uuid generation for opportunity
        testOpportunity.ConfirmAndClose__c = true;
        update testOpportunity;
        Opportunity optyWithUuid = [SELECT Uuid__c FROM Opportunity WHERE Id = :testOpportunity.Id];
        // Create a new email and envelope object
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        email.subject = 'Opportunity';
        email.fromAddress = 'testFrom@gmail.com';
        email.plainTextBody = 'approve' + ' accept ' + '/------' + optyWithUuid.Uuid__c + '------/';
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        env.fromAddress = 'testFrom@gmail.com';
        env.toAddress = 'testTo@gmail.com';

        Test.startTest();
            InboundEmailService testInbound = new InboundEmailService();
            Messaging.InboundEmailResult result = testInbound.handleInboundEmail(email,env);
        Test.stopTest();

        System.assertEquals(true, result.success);
        // Check if cusotmer "approve" is correctly processed
        Opportunity updatedOpty = [
            SELECT CustomerConfirmation__c, StageName
            FROM Opportunity
            WHERE Id = :testOpportunity.Id
        ];
        System.assertEquals(OpportunityHelper.CONFIRMED, updatedOpty.CustomerConfirmation__c);
        System.assertEquals(OpportunityHelper.closedStage, updatedOpty.StageName);
    }

    @isTest
    static void testCustomerRejected() {

        createTestData();
        // Prepopulate orgWideEmailMap
        Map<String, String> orgWideMap = new Map<String, String>{'InboundEmailService' => 'testTo@gmail.com'};
        InboundEmailService.orgWideEmailMap = orgWideMap;
        // Trigger Uuid generation for opportunity
        testOpportunity.ConfirmAndClose__c = true;
        update testOpportunity;
        Opportunity optyWithUuid = [SELECT Uuid__c FROM Opportunity WHERE Id = :testOpportunity.Id];

        // Create a new email and envelope object
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        email.subject = 'Opportunity';
        email.fromAddress = 'testFrom@gmail.com';
        email.plainTextBody = 'reject' + '/------' + optyWithUuid.Uuid__c + '------/';
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        env.fromAddress = 'testFrom@gmail.com';
        env.toAddress = 'testTo@gmail.com';
        Test.startTest();
            InboundEmailService testInbound = new InboundEmailService();
            Messaging.InboundEmailResult result = testInbound.handleInboundEmail(email,env);
        Test.stopTest();
        System.assertEquals(true, result.success);

        // Check if cusotmer "reject" is correctly processed
        Opportunity updatedOpty = [
            SELECT CustomerConfirmation__c, StageName, ConfirmAndClose__c
            FROM Opportunity
            WHERE Id = :testOpportunity.Id
        ];
        System.assertEquals(OpportunityHelper.REJECTED, updatedOpty.CustomerConfirmation__c);
        System.assertEquals(false, updatedOpty.ConfirmAndClose__c);
        System.assertEquals(OpportunityHelper.STAGE_NAME_AGREEMENT, updatedOpty.StageName);
    }

    @isTest
    static void testInvalidCustomerAnswer() {

        createTestData();
        // Prepopulate orgWideEmailMap
        Map<String, String> orgWideMap = new Map<String, String>{'InboundEmailService' => 'testTo@gmail.com'};
        InboundEmailService.orgWideEmailMap = orgWideMap;
        // Trigger Uuid generation for opportunity
        testOpportunity.ConfirmAndClose__c = true;
        update testOpportunity;
        Opportunity optyWithUuid = [SELECT Uuid__c FROM Opportunity WHERE Id = :testOpportunity.Id];
        // Create a new email and envelope object
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        email.subject = 'Opportunity';
        email.fromAddress = 'testFrom@gmail.com';
        email.plainTextBody = 'ABRACADABRA' + '/------' + optyWithUuid.Uuid__c + '------/';
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        env.fromAddress = 'testFrom@gmail.com';
        env.toAddress = 'testTo@gmail.com';
        Test.startTest();
            InboundEmailService testInbound = new InboundEmailService();
            Messaging.InboundEmailResult result = testInbound.handleInboundEmail(email,env);
        Test.stopTest();
        System.assertEquals(true, result.success);
        //System.assertEquals('To approve or reject, please answer with \'Approve\' or \'Reject\' to this email', result.message);
    }

    @isTest
    static void testGetActiveContract() {
        createTestData();
        /* Make one of the contracts active */
        contractList[0].Status = 'Active';
        update contractList;

        Test.startTest();
            InboundEmailService ies = new InboundEmailService();
            Id activeContractId = ies.getActiveContractId(testOpportunity);
        Test.stopTest();

        System.assertEquals(contractList[0].Id, activeContractId, 'Wrong contract was selected');
    }

    @isTest
    static void testGetActiveContractNoActiveContracts() {
        createTestData();

        Test.startTest();
            InboundEmailService ies = new InboundEmailService();
            Id activeContractId = ies.getActiveContractId(testOpportunity);
        Test.stopTest();

        System.assertEquals(null, activeContractId, 'No contract id should be specified');
    }

    @isTest
    static void testGetActiveContractNoContracts() {
        createTestData();
        delete contractList;

        Test.startTest();
            InboundEmailService ies = new InboundEmailService();
            Id activeContractId = ies.getActiveContractId(testOpportunity);
        Test.stopTest();

        System.assertEquals(null, activeContractId, 'No contract id should be specified');
    }

    @isTest
    static void testSaveInboundEmail() {
        createTestData();
        Messaging.InboundEmail email =  new Messaging.InboundEmail();
        email.fromAddress = 'fromAddress';
        email.subject = 'Subject';
        email.plainTextBody = 'body';

        Test.startTest();
            InboundEmailService ies = new InboundEmailService();
            ies.saveInboundEmail(new List<Id>{testOpportunity.Id, contractList[0].Id}, email);
        Test.stopTest();

        List<Note> notesList = (List<Note>) new NoteSelector()
            .selectNotes()
            .executeQuery();

        System.assertEquals(2, notesList.size(), 'Notes should be created for opportunity and for contract');
        for (Note noteItem : notesList) {
            Id parentId = noteItem.ParentId;
            Schema.sObjectType entityType = parentId.getSObjectType();
            if (entityType == Opportunity.sObjectType) {
                System.assertEquals(testOpportunity.Id, parentId, 'Opportunity should be parent');
            } else if (entityType == Contract.sObjectType) {
                System.assertEquals(contractList[0].Id, parentId, 'Contract should be parent');
            }
        }
    }

    @isTest
    static void testNoAnswerIsSentForSystemEmail() {
        List<Emails__c> emailsToExclude = new List<Emails__c>{
            new Emails__c(Name = 'InboundEmailServiceExclude_1',
                          Email_Address__c = 'mailer-daemon@salesforce.com'),
            new Emails__c(Name = 'InboundEmailServiceExclude_2',
                          Email_Address__c = 'customerconfirmation@18eqon7i3v1qkn27e6m0skq4se7qbfac31i7p79m7yxahycdjl.8-aruxea')
        };
        insert emailsToExclude;
        Emails__c  emailtoExclude = Emails__c.getInstance('InboundEmailServiceExclude_1');
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        email.fromAddress = emailtoExclude.Email_Address__c;
        email.subject = 'Undeliverable: RE: RingCentral Change Order Confirmation';
        email.plainTextBody = 'body';

        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        env.fromAddress = emailtoExclude.Email_Address__c;
        env.toAddress = 'testTo@gmail.com';

        Map<String, String> orgWideMap = new Map<String, String>{'InboundEmailService' => 'testTo@gmail.com'};
        InboundEmailService.orgWideEmailMap = orgWideMap;

        Test.startTest();
            InboundEmailService testInbound = new InboundEmailService();
            Messaging.InboundEmailResult result = testInbound.handleInboundEmail(email, env);
        Test.stopTest();

        System.assertEquals(null, result, 'Method should return null if an inbound message was sent from mail server email address');
    }
}