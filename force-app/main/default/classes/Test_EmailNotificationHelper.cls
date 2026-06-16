@IsTest
private class Test_EmailNotificationHelper {
    private static final String TEST_SUBJECT = 'test subject';
    private static final String TEST_PLAIN_TEXT_BODY = 'test body';

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @IsTest
    static void testSendEmailNotification() {
        Legal_Requests__c legalReq = (Legal_Requests__c) new SObjectBuilder(Legal_Requests__c.SObjectType)
            .setField(Legal_Requests__c.Title_of_Invention__c, 'Test Invention')
            .setField(Legal_Requests__c.Status__c, 'Submitted')
            .create()
            .getRecord();

        Test.startTest();
        EmailNotificationHelper.sendEmailNotification(
            new Set<Id>{ legalReq.Id },
            new Map<Id, Legal_Requests__c> {
                legalReq.Id => legalReq
            }
        );
        Test.stopTest();
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @IsTest
    static void testSendEmailNotificationUpdateStatus() {
        Legal_Requests__c legalReq = (Legal_Requests__c) new SObjectBuilder(Legal_Requests__c.SObjectType)
            .setField(Legal_Requests__c.Title_of_Invention__c, 'Test Invention')
            .setField(Legal_Requests__c.Status__c, 'Submitted')
            .create()
            .getRecord();
        legalReq.Status__c = 'Initial';

        Test.startTest();
        EmailNotificationHelper.sendEmailNotification(
            new Set<Id>{ legalReq.Id },
            new Map<Id, Legal_Requests__c> {
                legalReq.Id => legalReq
            }
        );
        Test.stopTest();
    }

    @IsTest
    static void testCreateEmailMessage() {
        Id templateId = [SELECT Id FROM EmailTemplate LIMIT 1].Id;
        Account a = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => 'testAcc'
                }
            )
            .create()
            .getRecord();

        Test.startTest();
        Messaging.SingleEmailMessage result
            = EmailNotificationHelper.createEmailMessage(UserInfo.getUserId(),a.Id,templateId);
        Test.stopTest();

        System.assertEquals(templateId, result.templateId);
    }

    @IsTest
    static void testCreateErrorEmailMessageForCCteam() {

        Emails__c email = new Emails__c(
            Name = 'ccdesk',
            Email_Address__c = 'ccdesk@test.tld'
        );
        insert email;

        Case cs = (Case) new SObjectBuilder(Case.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Case.Status => 'New',
                    Case.RecordTypeId => CaseHelper.RT_ID_INCONTACT_ORDER,
                    Case.Contact_Email__c => 'test@test.tld',
                    Case.AccountId => ValueProviderBuilder.provideGenericParent(Account.SObjectType),
                    Case.Opportunity_Reference__c => ValueProviderBuilder.provideGenericParent(Opportunity.SObjectType)
                }
            )
            .create()
            .getRecord();


        AquivaHelper.AquivaException exExample = new AquivaHelper.AquivaException('Something went wrong');

        Test.startTest();
        Messaging.SingleEmailMessage result
            = EmailNotificationHelper.createErrorEmailMessageForCCteam(exExample, cs);
        Test.stopTest();

        System.assertNotEquals(null, result);
    }

    @IsTest
    static void testCreateEmailMessageForCCteam() {

        Emails__c email = new Emails__c(
            Name = 'ccdesk',
            Email_Address__c = 'ccdesk@test.tld'
        );
        insert email;

        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        Account.Name => 'testAcc'
                    }
                )
                .create()
                .getRecord();

        Opportunity opp = (Opportunity) new SobjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.AccountId => acc.Id,
                    Opportunity.Name => 'TestOpportunity',
                    Opportunity.Brand_Name__c => 'RingCentral',
                    Opportunity.Tier_Name__c => 'Office',
                    Opportunity.StageName => '1. Qualify',
                    Opportunity.CloseDate => System.today(),
                    Opportunity.CurrencyIsoCode => 'USD'
                }
            )
            .create()
            .getRecord();


        Test.startTest();
        Messaging.SingleEmailMessage result
            = EmailNotificationHelper.createEmailMessageForCCteam('string', 'detailString', opp, null);
        Test.stopTest();

        System.assertNotEquals(null, result);
    }

    @isTest
    static void testConstructSingleEmailMessage() {
        Id dummyUserId = (Id) new ValueProvider.DummyIdProvider(User.sObjectType).getValue();

        Test.startTest();
            Messaging.SingleEmailMessage result = EmailNotificationHelper.createEmailMessage(dummyUserId, TEST_SUBJECT, TEST_PLAIN_TEXT_BODY);
        Test.stopTest();

        Assert.areEqual(TEST_SUBJECT, result.getSubject(), 'Subject of the email message must be the same as the input');
        Assert.areEqual(TEST_PLAIN_TEXT_BODY, result.getPlainTextBody(), 'Plain text body of the email message must be the same as the input');
        Assert.isNull(result.getHtmlBody(), 'HTML Body of the email message must be empty when isHTML flag is false');
        Assert.areEqual(dummyUserId, result.getTargetObjectId(), 'Target object id of the email message must be the same as the input');
    }

    @isTest
    static void testConstructSingleEmailMessageWithHtmlBody() {
        Id dummyUserId = (Id) new ValueProvider.DummyIdProvider(User.sObjectType).getValue();

        Test.startTest();
            Messaging.SingleEmailMessage result = EmailNotificationHelper.createEmailMessage(dummyUserId, TEST_SUBJECT, TEST_PLAIN_TEXT_BODY, true);
        Test.stopTest();

        Assert.areEqual(TEST_SUBJECT, result.getSubject(), 'Subject of the email message must be the same as the input');
        Assert.areEqual(TEST_PLAIN_TEXT_BODY, result.getHtmlBody(), 'HTML body of the email message must be the same as the input');
        Assert.isNull(result.getPlainTextBody(), 'Plain Text Body of the email message must be empty when isHTML flag is true');
        Assert.areEqual(dummyUserId, result.getTargetObjectId(), 'Target object id of the email message must be the same as the input');
    }

    @isTest
    static void testSendSingleEmailMessages() {
        User testUser = (User) new SObjectBuilder(User.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(User.SObjectType))
            .create()
            .getRecord();
        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage> {EmailNotificationHelper.createEmailMessage(testUser.Id, TEST_SUBJECT, TEST_PLAIN_TEXT_BODY)};

        Test.startTest();
            EmailNotificationHelper.sendSingleEmailMessages(mails);
            Integer numberOfEmailInvocations = Limits.getEmailInvocations();
        Test.stopTest();

        Assert.areEqual(1, numberOfEmailInvocations, 'In case of correct input, Messaging.sendEmail() must be executed once');
        Assert.isTrue(
            [SELECT COUNT() FROM PlatformLog__c WHERE Source__c = :EmailNotificationHelper.EMAIL_NOTIFICATION_HELPER_CLASS_NAME] == 0,
            'Successful Messaging.sendEmail() must not produce any errors'
        );
    }

    @isTest
    static void testHandleSendEmailResultWithError() {
        String resultJson = '{"errors": [{"message" : "Test Error"}], "success": false}';
        Messaging.SendEmailResult result = (Messaging.SendEmailResult) JSON.deserialize(resultJson, Messaging.SendEmailResult.class);

        Test.startTest();
            EmailNotificationHelper.handleSendEmailResult(new List<Messaging.SendEmailResult> {result});
        Test.stopTest();

        Assert.isTrue(
            [SELECT COUNT() FROM PlatformLog__c WHERE Source__c = :EmailNotificationHelper.EMAIL_NOTIFICATION_HELPER_CLASS_NAME] > 0,
            'When result is not success, a platform log should be created'
        );
    }

    @isTest
    static void testSendEmailNotificationToGroupMembers() {
        User testUser = (User) new SObjectBuilder(User.sObjectType).create().getRecord();

        String testGroupDeveloperName = 'Unique_Developer_Name_' + String.valueOf(System.now().millisecond());
        Group testGroup = (Group) new SObjectBuilder(Group.SObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    Group.DeveloperName => testGroupDeveloperName,
                    Group.Name => 'Test Group'

                }
            )
            .create()
            .getRecord();

        new SObjectBuilder(GroupMember.sObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    GroupMember.GroupId => testGroup.Id,
                    GroupMember.UserOrGroupId => testUser.Id
                }
            )
            .create();

        Test.startTest();
            EmailNotificationHelper.sendEmailNotificationToGroupMembers(testGroupDeveloperName, TEST_SUBJECT, TEST_PLAIN_TEXT_BODY);
            Integer numberOfEmailInvocations = Limits.getEmailInvocations();
        Test.stopTest();

        Assert.areEqual(1, numberOfEmailInvocations, 'An email should have been sent once');
    }

    @IsTest
    static void testSendEmail() {
        Emails__c email = new Emails__c(
            Name = 'ccdesk',
            Email_Address__c = 'ccdesk@test.tld'
        );
        insert email;

        Case cs = (Case) new SObjectBuilder(Case.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Case.Status => 'New',
                    Case.RecordTypeId => CaseHelper.RT_ID_INCONTACT_ORDER,
                    Case.Contact_Email__c => 'test@test.tld',
                    Case.AccountId => ValueProviderBuilder.provideGenericParent(Account.SObjectType),
                    Case.Opportunity_Reference__c => ValueProviderBuilder.provideGenericParent(Opportunity.SObjectType)
                }
            )
            .create()
            .getRecord();

        Test.startTest();
            EmailNotificationHelper.sendEmail('string', 'detailString', null, cs);
            Integer numberOfEmailInvocations = Limits.getEmailInvocations();
            List<PlatformLog__c> platformLogs = [SELECT Id, Source__c FROM PlatformLog__c];
        Test.stopTest();

        if (numberOfEmailInvocations > 0) {
            Assert.areEqual(1, numberOfEmailInvocations, 'An email should have been sent once');
            Assert.areEqual(0, platformLogs.size(), 'No platform logs created');
        } else {
            Assert.areEqual(0, numberOfEmailInvocations, 'An email should not be sent');
            Assert.areEqual(1, platformLogs.size(), 'Platform log must be created');
        }
    }

    @IsTest
    static void testSendEmailNotificationToProServTeamForClonedQuote() {
        List<Emails__c> proServEmails = (List<Emails__c>) new SObjectBuilder(Emails__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Emails__c.Email_Address__c => 'proserv.test@example.com',
                Emails__c.Name => new ValueProvider.ListProvider(new List<String>{
                    QuotingToolQuoteApexController.PROSERV_EMAILS_CUSTOM_SETTING_NAME,
                    QuotingToolQuoteApexController.CC_PROSERV_EMAILS_CUSTOM_SETTING_NAME
                })
            })
            .quantity(2)
            .create()
            .getRecords();

        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object>{Account.Name => 'testAcc'})
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object>{Opportunity.Name => 'testOpp', Opportunity.AccountId => acc.Id})
            .create()
            .getRecord();

        Quote masterQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.OpportunityId => opp.Id,
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.PriceBook2Id => Test.getStandardPriceBookId(),
                Quote.Name => 'Master Quote'
            })
            .create()
            .getRecord();

        Triggers.switchOff();
        Quote proServQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.OpportunityId => opp.Id,
                Quote.Account__c => acc.Id,
                Quote.Name => 'ProServ Quote',
                Quote.isMultiProductTechnicalQuote__c => true,
                Quote.ServiceName__c => QuoteHelper.NGBS_PROFESSIONAL_SERVICES_PRODUCT,
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.MasterQuote__c => masterQuote.Id
            })
            .create()
            .getRecord();
        
        Quote clonedProServQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.OpportunityId => opp.Id,
                Quote.Name => 'Cloned ProServ Quote',
                Quote.isMultiProductTechnicalQuote__c => true,
                Quote.ServiceName__c => QuoteHelper.NGBS_PROFESSIONAL_SERVICES_PRODUCT,
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING
            })
            .create()
            .getRecord();
        Triggers.switchOn();

        Test.startTest();
            // Create existing ProServ cases
            List<Case> existingCases = (List<Case>) new SObjectBuilder(Case.SObjectType)
                .setFields(new Map<SObjectField, Object> {
                    Case.Subject => new ValueProvider.ListProvider(new List<String>{
                        CaseHelper.SUBJECT_PS_UC_QUOTE_REQUESTED,
                        CaseHelper.SUBJECT_PS_CC_QUOTE_REQUESTED
                    }),
                    Case.Description => 'Test ProServ Case Description',
                    Case.Quote_Approval_ID__c => masterQuote.Id,
                    Case.Opportunity_Reference__c => masterQuote.OpportunityId,
                    Case.AccountId => masterQuote.AccountId,
                    Case.RecordTypeId => CaseHelper.RT_ID_PROFESSIONAL_SERVICES
                })
                .quantity(2)
                .create()
                .getRecords();
                
            List<Quote> selectedQuotes = new QuoteSelector()
                .selectQuoteForCloning(new List<Object>{proServQuote.Id})
                .executeQuery();

            EmailNotificationHelper.sendEmailNotificationToProServTeamForClonedQuote(clonedProServQuote.Id, selectedQuotes[0].Id);
        Test.stopTest();
    
        List<PlatformLog__c> platformLogs = (List<PlatformLog__c>) new QueryFactory(PlatformLog__c.SObjectType)
            .selectFields(new List<String>{ 'Id' })
            .executeQuery();
        Assert.areEqual(0, platformLogs.size(), 'A platform log should not have been created');
    }
}