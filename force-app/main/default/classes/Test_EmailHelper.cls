@IsTest
private class Test_EmailHelper {
    private static final String EMAIL_TEMPLATE_HTML_DEFAULT =
        '\n' +
        'Test Email Template HTML: <br/>\n' +
        'testVariable1 = {!testVariable1}<br/>\n' +
        'testVariable2 = {!testVariable2}<br/>\n';
    private static final String EMAIL_TEMPLATE_TEXT_DEFAULT =
        '\n' +
        'Test Email Template Text:\n' +
        'testVariable1 = {!testVariable1}\n' +
        'testVariable2 = {!testVariable2}\n';
    private static final String EMAIL_TEMPLATE_HTML_QUOTE_FIELDS =
        '<br/>\n' +
        'Name = {!Name}<br/>\n' +
        'OpportunityId = {!OpportunityId}<br/>\n' +
        'OpportunityName = {!OpportunityName}<br/>\n' +
        'AccountId = {!AccountId}<br/>\n' +
        'AccountName = {!AccountName}<br/>\n' +
        'QuoteNumber = {!QuoteNumber}<br/>\n' +
        'JustificationandDescription = {!JustificationandDescription}<br/>\n';
    private static final String EMAIL_TEMPLATE_HTML_NEW_IGNITE_QUOTE =
        '<br/>\n' +
            'Name = {!Name}<br/>\n' +
            'OpportunityName = {!OpportunityName}<br/>\n' +
            'OpportunityLink = {!OpportunityLink}<br/>\n' +
            'QuoteNumber = {!QuoteNumber}<br/>\n' +
            'QuoteLink = {!QuoteLink}<br/>\n';
    private static final String EMAIL_TEMPLATE_HTML_PROSERV_IGNITE =
        '<br/>\n' +
            'Name = {!Name}<br/>\n' +
            'OpportunityName = {!OpportunityName}<br/>\n' +
            'OpportunityLink = {!OpportunityLink}<br/>\n' +
            'QuoteNumber = {!QuoteNumber}<br/>\n' +
            'QuoteLink = {!QuoteLink}<br/>\n' + 
            'PartnerContactName = {!PartnerContactName}<br/>\n' +
            'PartnerContactEmail = {!PartnerContactEmail}<br/>\n' +
            'AccountName = {!AccountName}<br/>\n' +
            'AccountLink = {!AccountLink}<br/>\n' +
            'CaseReasons = {!CaseReasons}<br/>\n';

    private static SObjectBuilder getEmailTemplateBuilder(Integer quantity, Map<SObjectField, Object> fieldsMap) {
        List<String> testDeveloperNames = new List<String>();
        List<String> testNames = new List<String>();
        List<String> testSubjects = new List<String>();

        for (Integer i = 0; i < quantity; i++) {
            testDeveloperNames.add('Test_EmailTemplate' + i);
            testNames.add('Test Email Template ' + i);
            testSubjects.add('Test Subject ' + i);
        }

        return new SObjectBuilder(EmailTemplate.getSObjectType())
            .setFields(
                new Map<SObjectField, Object>{
                    EmailTemplate.IsActive => true,
                    EmailTemplate.FolderId => UserInfo.getUserId(),
                    EmailTemplate.DeveloperName => ValueProviderBuilder.provideList(testDeveloperNames),
                    EmailTemplate.TemplateType => 'custom',
                    EmailTemplate.Name => ValueProviderBuilder.provideList(testNames),
                    EmailTemplate.Subject => ValueProviderBuilder.provideList(testSubjects),
                    EmailTemplate.HtmlValue => '',
                    EmailTemplate.Body => '',
                    EmailTemplate.Encoding => 'ISO-8859-1'
                }
            )
            .setFields(fieldsMap)
            .quantity(quantity);
    }

    private static SObjectBuilder getEmailTemplateBuilder(Integer quantity) {
        return getEmailTemplateBuilder(quantity, new Map<SObjectField, Object>());
    }

    private static SObjectBuilder getEmailTemplateBuilder() {
        return getEmailTemplateBuilder(1);
    }

    private static SObjectBuilder getQuoteBuilder(Integer quantity, Map<SObjectField, Object> fieldsMap) {
        List<String> testNames = new List<String>();
        List<String> testJustifications = new List<String>();

        for (Integer i = 0; i < quantity; i++) {
            testNames.add('TestQuote' + i);
            testJustifications.add('TestJustification' + i);
        }

        return new SObjectBuilder(Quote.getSObjectType())
            .setFields(
                new Map<SObjectField, Object>{
                    Quote.Name => ValueProviderBuilder.provideList(testNames),
                    Quote.JustificationandDescription__c => ValueProviderBuilder.provideList(testJustifications),
                    Quote.Approved_Status__c => ValueProviderBuilder.provideList(
                        new List<String>{
                            QuoteHelper.APPROVAL_STATUS_APPROVED,
                            QuoteHelper.APPROVAL_STATUS_REJECTED,
                            QuoteHelper.APPROVAL_STATUS_REQUIRED
                        }
                    )
                }
            )
            .setFields(fieldsMap)
            .quantity(quantity);
    }

    @TestSetup
    static void setup() {
        Triggers.switchOff();

        List<User> channelManagers = (List<User>) new SObjectBuilder(User.getSObjectType())
            .setFields(
                new Map<SObjectField, Object>{
                    User.FirstName => ValueProviderBuilder.provideUniqueString('FirstName'),
                    User.LastName => ValueProviderBuilder.provideUniqueString('LastName'),
                    User.Email => ValueProviderBuilder.provideUniqueEmail('channel.manager', '@example.tld')
                })
            .quantity(1)
            .create()
            .getRecords();

        Account account = (Account) new SObjectBuilder(Account.getSObjectType())
            .setFields(new Map<SObjectField, Object>{ Account.Name => 'TestAccount1' })
            .create()
            .getRecord();

        List<Opportunity> opp = (List<Opportunity>) new SObjectBuilder(Opportunity.getSObjectType())
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.Name => 'TestOpportunity1',
                    Opportunity.AccountId => account.Id,
                    Opportunity.CloseDate => Date.today(),
                    Opportunity.StageName => '1. Qualify'
                }
            )
            .quantity(1)
            .create()
            .getRecords();
        List<Opportunity> opp1 = (List<Opportunity>) new SObjectBuilder(Opportunity.getSObjectType())
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.Name => 'TestOpportunity1',
                    Opportunity.AccountId => account.Id,
                    Opportunity.CloseDate => Date.today(),
                    Opportunity.StageName => '1. Qualify',
                    Opportunity.Inside_Sales_Rep__c => ValueProviderBuilder.provideParents(channelManagers)
                }
            )
            .quantity(1)
            .create()
            .getRecords();

        List<Opportunity> opp2 = (List<Opportunity>) new SObjectBuilder(Opportunity.getSObjectType())
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.Name => 'TestOpportunity2',
                    Opportunity.AccountId => account.Id,
                    Opportunity.CloseDate => Date.today(),
                    Opportunity.StageName => OpportunityHelper.STAGE_NAME_CLOSED_WON,
                    Opportunity.Type => OpportunityHelper.OPPORTUNITY_TYPE_NEW_BUSINESS,
                    Opportunity.Inside_Sales_Rep__c => ValueProviderBuilder.provideParents(channelManagers),
                    Opportunity.PartnerProgram__c => 'Ignite'
                }
            )
            .quantity(1)
            .create()
            .getRecords();

        List<Opportunity> opp3 = (List<Opportunity>) new SObjectBuilder(Opportunity.getSObjectType())
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.Name => 'TestOpportunity3',
                    Opportunity.AccountId => account.Id,
                    Opportunity.CloseDate => Date.today(),
                    Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                    Opportunity.Type => OpportunityHelper.OPPORTUNITY_TYPE_EX_BUSINESS,
                    Opportunity.Inside_Sales_Rep__c => ValueProviderBuilder.provideParents(channelManagers),
                    Opportunity.PartnerProgram__c => 'Ignite'
                }
            )
            .quantity(1)
            .create()
            .getRecords();

        opp.addAll(opp1);
        opp.addAll(opp2);
        opp.addAll(opp3);

        List<Quote> qts = (List<Quote>) getQuoteBuilder(
                100,
                new Map<SObjectField, Object>{ Quote.OpportunityId => ValueProviderBuilder.provideParents(opp) }
            )
            .create()
            .getRecords();

        Triggers.switchOn();
    }

    @IsTest
    static void test_EmailBuilder() {
        Test.startTest();
        EmailHelper.EmailBuilder emailBuilder = new EmailHelper.EmailBuilder();
        Test.stopTest();

        System.assertEquals(0, emailBuilder.getRecipients().size(), 'Should have no recipients');
        System.assertEquals(0, emailBuilder.getCCRecipients().size(), 'Should have no CC recipients');
        System.assertEquals(0, emailBuilder.getBCCRecipients().size(), 'Should have no BCC recipients');
        System.assertEquals(0, emailBuilder.getBodyVariables().size(), 'Should have no body variables');
        System.assertEquals(null, emailBuilder.getTemplate(), 'Should have no template');
        System.assertEquals(null, emailBuilder.getTemplateId(), 'Should have no template ID');
        System.assertEquals(null, emailBuilder.getTemplateDeveloperName(), 'Should have no template developer name');
        System.assertEquals(null, emailBuilder.getTemplateName(), 'Should have no template name');
        System.assertEquals(null, emailBuilder.getTemplateType(), 'Should have no template type');
        System.assertEquals(null, emailBuilder.getTemplateHtml(), 'Should have no template HTML');
        System.assertEquals(null, emailBuilder.getTemplateText(), 'Should have no template text');
        System.assertEquals(null, emailBuilder.getSubject(), 'Should have no subject');
        System.assertEquals(null, emailBuilder.getFromAddress(), 'Should have no from address');
    }

    @IsTest
    static void test_EmailBuilder_addRecipient() {
        EmailHelper.EmailBuilder builder = new EmailHelper.EmailBuilder();

        Test.startTest();
        builder.addRecipient('test1@example.tld');
        Test.stopTest();

        System.assertEquals(1, builder.getRecipients().size(), 'Should have only one recipient');
        System.assertEquals(
            true,
            builder.getRecipients().contains('test1@example.tld'),
            'Should have correct recipient'
        );
    }

    @IsTest
    static void test_EmailBuilder_addRecipient_Duplicate() {
        EmailHelper.EmailBuilder builder = new EmailHelper.EmailBuilder();

        Test.startTest();
        builder.addRecipient('test1@example.tld');
        builder.addRecipient('test1@example.tld');
        Test.stopTest();

        System.assertEquals(1, builder.getRecipients().size(), 'Should have only one recipient');
        System.assertEquals(
            true,
            builder.getRecipients().contains('test1@example.tld'),
            'Should have correct recipient'
        );
    }

    @IsTest
    static void test_EmailBuilder_addRecipient_InvalidEmail() {
        EmailHelper.EmailBuilder builder = new EmailHelper.EmailBuilder();

        try {
            Test.startTest();
            builder.addRecipient('recipient@example');
            Test.stopTest();

            System.assert(false, 'Should have thrown an exception');
        } catch (EmailHelper.ArgumentException e) {
            System.assertEquals(
                String.format(
                    EmailHelper.ERROR_ARG_EMAIL_INVALID,
                    new List<Object>{ 0, 'recipient@example' }
                ),
                e.getMessage(),
                'Should have correct error message'
            );
            System.assertEquals(
                0,
                e.getArgumentIndex(),
                'Should have correct argument index'
            );
            System.assertEquals(
                'recipient@example',
                String.valueOf(e.getArgumentValue()),
                'Should have correct argument value'
            );
        }
    }

    @IsTest
    static void test_EmailBuilder_addRecipient_User() {
        User user = [SELECT Id, Email FROM User WHERE IsActive = true LIMIT 1];

        EmailHelper.EmailBuilder builder = new EmailHelper.EmailBuilder();

        Test.startTest();
        builder.addRecipient(user);
        Test.stopTest();

        System.assertEquals(1, builder.getRecipients().size(), 'Should have only one recipient');
        System.assertEquals(
            true,
            builder.getRecipients().contains(user.Email),
            'Should have correct recipient'
        );
    }

    @IsTest
    static void test_EmailBuilder_addRecipients() {
        EmailHelper.EmailBuilder builder = new EmailHelper.EmailBuilder();

        Test.startTest();
        builder.addRecipients(new List<String>{ 'test1@example.tld', 'test2@example.tld' });
        Test.stopTest();

        System.assertEquals(2, builder.getRecipients().size(), 'Should have two recipients');
        System.assertEquals(
            true,
            builder.getRecipients().contains('test1@example.tld'),
            'Should have correct recipient'
        );
        System.assertEquals(
            true,
            builder.getRecipients().contains('test2@example.tld'),
            'Should have correct recipient'
        );
    }

    @IsTest
    static void test_EmailBuilder_addRecipients_Duplicates() {
        EmailHelper.EmailBuilder builder = new EmailHelper.EmailBuilder();

        Test.startTest();
        builder.addRecipients(new List<String>{ 'test1@example.tld', 'test1@example.tld' });
        Test.stopTest();

        System.assertEquals(1, builder.getRecipients().size(), 'Should have only one recipient');
        System.assertEquals(
            true,
            builder.getRecipients().contains('test1@example.tld'),
            'Should have correct recipient'
        );
    }

    @IsTest
    static void test_EmailBuilder_addRecipients_Users() {
        User user1 = [SELECT Id, Email FROM User WHERE IsActive = true LIMIT 1];
        User user2 = [SELECT Id, Email FROM User WHERE IsActive = true LIMIT 1 OFFSET 1];

        EmailHelper.EmailBuilder builder = new EmailHelper.EmailBuilder();

        Test.startTest();
        builder.addRecipients(new List<User>{ user1, user2 });
        Test.stopTest();

        System.assertEquals(2, builder.getRecipients().size(), 'Should have two recipients');
        System.assertEquals(
            true,
            builder.getRecipients().contains(user1.Email),
            'Should have correct recipient'
        );
        System.assertEquals(
            true,
            builder.getRecipients().contains(user2.Email),
            'Should have correct recipient'
        );
    }

    @IsTest
    static void test_EmailBuilder_addCCRecipient() {
        EmailHelper.EmailBuilder builder = new EmailHelper.EmailBuilder();

        Test.startTest();
        builder.addCCRecipient('test1@example.tld');
        Test.stopTest();

        System.assertEquals(1, builder.getCCRecipients().size(), 'Should have only one recipient');
        System.assertEquals(
            true,
            builder.getCCRecipients().contains('test1@example.tld'),
            'Should have correct recipient'
        );
    }

    @IsTest
    static void test_EmailBuilder_addCCRecipient_Duplicate() {
        EmailHelper.EmailBuilder builder = new EmailHelper.EmailBuilder();

        Test.startTest();
        builder.addCCRecipient('test1@example.tld');
        builder.addCCRecipient('test1@example.tld');
        Test.stopTest();

        System.assertEquals(1, builder.getCCRecipients().size());
        System.assertEquals(
            true,
            builder.getCCRecipients().contains('test1@example.tld'),
            'Should have correct recipient'
        );
    }

    @IsTest
    static void test_EmailBuilder_addCCRecipient_InvalidEmail() {
        EmailHelper.EmailBuilder builder = new EmailHelper.EmailBuilder();

        try {
            Test.startTest();
            builder.addCCRecipient('ccRecipient@example');
            Test.stopTest();

            System.assert(false, 'Should have thrown an exception');
        } catch (EmailHelper.ArgumentException e) {
            System.assertEquals(
                String.format(
                    EmailHelper.ERROR_ARG_EMAIL_INVALID,
                    new List<Object>{ 0, 'ccRecipient@example' }
                ),
                e.getMessage(),
                'Should have correct error message'
            );
            System.assertEquals(0, e.getArgumentIndex(), 'Should have correct parameter name');
            System.assertEquals('ccRecipient@example', String.valueOf(e.getArgumentValue()), 'Should have correct parameter value');
        }
    }

    @IsTest
    static void test_EmailBuilder_addCCRecipient_User() {
        User user = [SELECT Id, Email FROM User WHERE IsActive = true LIMIT 1];

        EmailHelper.EmailBuilder builder = new EmailHelper.EmailBuilder();

        Test.startTest();
        builder.addCCRecipient(user);
        Test.stopTest();

        System.assertEquals(1, builder.getCCRecipients().size(), 'Should have only one recipient');
        System.assertEquals(
            true,
            builder.getCCRecipients().contains(user.Email),
            'Should have correct recipient'
        );
    }

    @IsTest
    static void test_EmailBuilder_addCCRecipients() {
        EmailHelper.EmailBuilder builder = new EmailHelper.EmailBuilder();

        Test.startTest();
        builder.addCCRecipients(new List<String>{ 'test1@example.tld', 'test2@example.tld' });
        Test.stopTest();

        System.assertEquals(2, builder.getCCRecipients().size(), 'Should have two recipients');
        System.assertEquals(
            true,
            builder.getCCRecipients().contains('test1@example.tld'),
            'Should have correct recipient'
        );
        System.assertEquals(
            true,
            builder.getCCRecipients().contains('test2@example.tld'),
            'Should have correct recipient'
        );
    }

    @IsTest
    static void test_EmailBuilder_addCCRecipients_Duplicates() {
        EmailHelper.EmailBuilder builder = new EmailHelper.EmailBuilder();

        Test.startTest();
        builder.addCCRecipients(new List<String>{ 'test1@example.tld', 'test1@example.tld' });
        Test.stopTest();

        System.assertEquals(1, builder.getCCRecipients().size(), 'Should have only one recipient');
        System.assertEquals(
            true,
            builder.getCCRecipients().contains('test1@example.tld'),
            'Should have correct recipient'
        );
    }

    @IsTest
    static void test_EmailBuilder_addCCRecipients_Users() {
        User user1 = [SELECT Id, Email FROM User WHERE IsActive = true LIMIT 1];
        User user2 = [SELECT Id, Email FROM User WHERE IsActive = true LIMIT 1 OFFSET 1];

        EmailHelper.EmailBuilder builder = new EmailHelper.EmailBuilder();

        Test.startTest();
        builder.addCCRecipients(new List<User>{ user1, user2 });
        Test.stopTest();

        System.assertEquals(2, builder.getCCRecipients().size(), 'Should have two recipients');
        System.assertEquals(
            true,
            builder.getCCRecipients().contains(user1.Email),
            'Should have correct recipient'
        );
        System.assertEquals(
            true,
            builder.getCCRecipients().contains(user2.Email),
            'Should have correct recipient'
        );
    }

    @IsTest
    static void test_EmailBuilder_addBCCRecipient() {
        EmailHelper.EmailBuilder builder = new EmailHelper.EmailBuilder();

        Test.startTest();
        builder.addBCCRecipient('test1@example.tld');
        Test.stopTest();

        System.assertEquals(1, builder.getBCCRecipients().size(), 'Should have only one recipient');
        System.assertEquals(
            true,
            builder.getBCCRecipients().contains('test1@example.tld'),
            'Should have correct recipient'
        );
    }

    @IsTest
    static void test_EmailBuilder_addBCCRecipient_Duplicate() {
        EmailHelper.EmailBuilder builder = new EmailHelper.EmailBuilder();

        Test.startTest();
        builder.addBCCRecipient('test1@example.tld');
        builder.addBCCRecipient('test1@example.tld');
        Test.stopTest();

        System.assertEquals(1, builder.getBCCRecipients().size(), 'Should have only one recipient');
        System.assertEquals(
            true,
            builder.getBCCRecipients().contains('test1@example.tld'),
            'Should have correct recipient'
        );
    }

    @IsTest
    static void test_EmailBuilder_addBCCRecipient_InvalidEmail() {
        EmailHelper.EmailBuilder builder = new EmailHelper.EmailBuilder();

        try {
            Test.startTest();
            builder.addBCCRecipient('bccRecipient@example');
            Test.stopTest();

            System.assert(false, 'Should have thrown an exception');
        } catch (EmailHelper.ArgumentException e) {
            System.assertEquals(
                String.format(
                    EmailHelper.ERROR_ARG_EMAIL_INVALID,
                    new List<Object>{ 0, 'bccRecipient@example' }
                ),
                e.getMessage(),
                'Should have correct error message'
            );
            System.assertEquals(0, e.getArgumentIndex(), 'Should have correct parameter name');
            System.assertEquals(
                'bccRecipient@example',
                String.valueOf(e.getArgumentValue()),
                'Should have correct parameter value'
            );
        }
    }

    @IsTest
    static void test_EmailBuilder_addBCCRecipient_User() {
        User user = [SELECT Id, Email FROM User WHERE IsActive = true LIMIT 1];

        EmailHelper.EmailBuilder builder = new EmailHelper.EmailBuilder();

        Test.startTest();
        builder.addBCCRecipient(user);
        Test.stopTest();

        System.assertEquals(1, builder.getBCCRecipients().size(), 'Should have only one recipient');
        System.assertEquals(
            true,
            builder.getBCCRecipients().contains(user.Email),
            'Should have correct recipient'
        );
    }

    @IsTest
    static void test_EmailBuilder_addBCCRecipients() {
        EmailHelper.EmailBuilder builder = new EmailHelper.EmailBuilder();

        Test.startTest();
        builder.addBCCRecipients(new List<String>{ 'test1@example.tld', 'test2@example.tld' });
        Test.stopTest();

        System.assertEquals(2, builder.getBCCRecipients().size(), 'Should have two recipients');
        System.assertEquals(
            true,
            builder.getBCCRecipients().contains('test1@example.tld'),
            'Should have correct recipient'
        );
        System.assertEquals(
            true,
            builder.getBCCRecipients().contains('test2@example.tld'),
            'Should have correct recipient'
        );
    }

    @IsTest
    static void test_EmailBuilder_addBCCRecipients_Duplicates() {
        EmailHelper.EmailBuilder builder = new EmailHelper.EmailBuilder();

        Test.startTest();
        builder.addBCCRecipients(new List<String>{ 'test1@example.tld', 'test1@example.tld' });
        Test.stopTest();

        System.assertEquals(1, builder.getBCCRecipients().size(), 'Should have only one recipient');
        System.assertEquals(
            true,
            builder.getBCCRecipients().contains('test1@example.tld'),
            'Should have correct recipient'
        );
    }

    @IsTest
    static void test_EmailBuilder_addBCCRecipients_Users() {
        User user1 = [SELECT Id, Email FROM User WHERE IsActive = true LIMIT 1];
        User user2 = [SELECT Id, Email FROM User WHERE IsActive = true LIMIT 1 OFFSET 1];

        EmailHelper.EmailBuilder builder = new EmailHelper.EmailBuilder();

        Test.startTest();
        builder.addBCCRecipients(new List<User>{ user1, user2 });
        Test.stopTest();

        System.assertEquals(2, builder.getBCCRecipients().size(), 'Should have two recipients');
        System.assertEquals(
            true,
            builder.getBCCRecipients().contains(user1.Email),
            'Should have correct recipient'
        );
        System.assertEquals(
            true,
            builder.getBCCRecipients().contains(user2.Email),
            'Should have correct recipient'
        );
    }

    @IsTest
    static void test_EmailBuilder_setBodyVariable() {
        EmailHelper.EmailBuilder builder = new EmailHelper.EmailBuilder();

        Test.startTest();
        builder.setBodyVariable('testVariable', 'testValue');
        Test.stopTest();

        System.assertEquals(1, builder.getBodyVariables().size(), 'Should have one body variable');
        System.assertEquals(
            'testValue',
            builder.getBodyVariables().get('testVariable'),
            'Should have correct body variable value'
        );
    }

    @IsTest
    static void test_EmailBuilder_setBodyVariable_BlankVariableName() {
        EmailHelper.EmailBuilder builder = new EmailHelper.EmailBuilder();

        try {
            Test.startTest();
            builder.setBodyVariable('', 'testValue');
            Test.stopTest();

            System.assert(false, 'Should have thrown an exception');
        } catch (EmailHelper.ArgumentException e) {
            System.assertEquals(
                String.format(
                    EmailHelper.ERROR_ARG_VALUE_BLANK,
                    new List<Object>{ 0 }
                ),
                e.getMessage(),
                'Should have correct error message'
            );
            System.assertEquals(0, e.getArgumentIndex(), 'Should have correct parameter name');
            System.assertEquals('', String.valueOf(e.getArgumentValue()), 'Should have correct parameter value');
        }
    }

    @IsTest
    static void test_EmailBuilder_setBodyVariables() {
        EmailHelper.EmailBuilder builder = new EmailHelper.EmailBuilder();

        Test.startTest();
        builder.setBodyVariables(
            new Map<String, String>{ 'testVariable1' => 'testValue1', 'testVariable2' => 'testValue2' }
        );
        Test.stopTest();

        System.assertEquals(2, builder.getBodyVariables().size(), 'Should have two body variables');
        System.assertEquals(
            'testValue1',
            builder.getBodyVariables().get('testVariable1'),
            'Should have correct body variable value'
        );
        System.assertEquals(
            'testValue2',
            builder.getBodyVariables().get('testVariable2'),
            'Should have correct body variable value'
        );
    }

    @IsTest
    static void test_EmailBuilder_getBodyVariable() {
        EmailHelper.EmailBuilder builder = new EmailHelper.EmailBuilder();
        builder.setBodyVariable('testVariable', 'testValue');

        Test.startTest();
        String bodyVariable = builder.getBodyVariable('testVariable');
        Test.stopTest();

        System.assertEquals('testValue', bodyVariable, 'Should have correct body variable value');
    }

    @IsTest
    static void test_EmailBuilder_getBodyVariable_BlankVariableName() {
        EmailHelper.EmailBuilder builder = new EmailHelper.EmailBuilder();
        builder.setBodyVariable('testVariable', 'testValue');

        try {
            Test.startTest();
            builder.getBodyVariable('');
            Test.stopTest();

            System.assert(false, 'Should have thrown an exception');
        } catch (EmailHelper.ArgumentException e) {
            System.assertEquals(
                String.format(
                    EmailHelper.ERROR_ARG_VALUE_BLANK,
                    new List<Object>{ 0 }
                ),
                e.getMessage(),
                'Should have correct error message'
            );
            System.assertEquals(0, e.getArgumentIndex(), 'Should have correct parameter name');
            System.assertEquals('', e.getArgumentValue(), 'Should have correct parameter value');
        }
    }

    @IsTest
    static void test_EmailBuilder_getBodyVariable_UndefinedVariable() {
        EmailHelper.EmailBuilder builder = new EmailHelper.EmailBuilder();
        builder.setBodyVariable('testVariable', 'testValue');

        try {
            Test.startTest();
            builder.getBodyVariable('invalidVariable');
            Test.stopTest();

            System.assert(false, 'Should have thrown an exception');
        } catch (EmailHelper.ArgumentException e) {
            System.assertEquals(
                String.format(
                    EmailHelper.ERROR_ARG_BODY_VAR_UNDEFINED,
                    new List<Object>{ 0, 'invalidVariable' }
                ),
                e.getMessage(),
                'Should have correct error message'
            );
            System.assertEquals(0, e.getArgumentIndex(), 'Should have correct parameter name');
            System.assertEquals('invalidVariable', e.getArgumentValue(), 'Should have correct parameter value');
        }
    }

    @IsTest
    static void test_EmailBuilder_setCompiledPattern() {
        EmailHelper.EmailBuilder builder = new EmailHelper.EmailBuilder();

        Test.startTest();
        builder.setCompiledPattern('testVariable');
        Test.stopTest();

        System.assert(builder.getCompiledPattern('testVariable') != null, 'Should have compiled pattern');
    }

    @IsTest
    static void test_EmailBuilder_setCompiledPattern_BlankVariableName() {
        EmailHelper.EmailBuilder builder = new EmailHelper.EmailBuilder();

        try {
            Test.startTest();
            builder.setCompiledPattern('');
            Test.stopTest();

            System.assert(false, 'Should have thrown an exception');
        } catch (EmailHelper.ArgumentException e) {
            System.assertEquals(
                String.format(
                    EmailHelper.ERROR_ARG_VALUE_BLANK,
                    new List<Object>{ 0 }
                ),
                e.getMessage(),
                'Should have correct error message'
            );
            System.assertEquals(0, e.getArgumentIndex(), 'Should have correct parameter name');
            System.assertEquals('', e.getArgumentValue(), 'Should have correct parameter value');
        }
    }

    @IsTest
    static void test_EmailBuilder_setCompiledPattern_ExistingPattern() {
        EmailHelper.EmailBuilder builder = new EmailHelper.EmailBuilder();
        builder.setCompiledPattern('testVariable');

        Test.startTest();
        builder.setCompiledPattern('testVariable');
        Test.stopTest();

        System.assert(builder.getCompiledPattern('testVariable') != null, 'Should have compiled pattern');
    }

    @IsTest
    static void test_EmailBuilder_getCompiledPattern() {
        EmailHelper.EmailBuilder builder = new EmailHelper.EmailBuilder();
        builder.setCompiledPattern('testVariable');

        Test.startTest();
        Pattern pattern = builder.getCompiledPattern('testVariable');
        Test.stopTest();

        System.assert(pattern != null, 'Should have compiled pattern');
    }

    @IsTest
    static void test_EmailBuilder_getCompiledPattern_BlankVariableName() {
        EmailHelper.EmailBuilder builder = new EmailHelper.EmailBuilder();
        builder.setCompiledPattern('testVariable');

        try {
            Test.startTest();
            builder.getCompiledPattern('');
            Test.stopTest();

            System.assert(false, 'Should have thrown an exception');
        } catch (EmailHelper.ArgumentException e) {
            System.assertEquals(
                String.format(
                    EmailHelper.ERROR_ARG_VALUE_BLANK,
                    new List<Object>{ 0 }
                ),
                e.getMessage(),
                'Should have correct error message'
            );
            System.assertEquals(0, e.getArgumentIndex(), 'Should have correct parameter name');
            System.assertEquals('', e.getArgumentValue(), 'Should have correct parameter value');
        }
    }

    @IsTest
    static void test_EmailBuilder_setTemplate() {
        EmailTemplate tpl = (EmailTemplate) getEmailTemplateBuilder(
                1,
                new Map<SObjectField, Object>{
                    EmailTemplate.HtmlValue => EMAIL_TEMPLATE_HTML_DEFAULT,
                    EmailTemplate.Body => EMAIL_TEMPLATE_TEXT_DEFAULT
                }
            )
            .create()
            .getRecord();

        EmailHelper.EmailBuilder builder = new EmailHelper.EmailBuilder();

        Test.startTest();
        builder.setTemplate(tpl);
        Test.stopTest();

        System.assertEquals(tpl.Id, builder.getTemplateId(), 'Should have correct template ID');
        System.assertEquals(tpl.TemplateType, builder.getTemplateType(), 'Should have correct template type');
        System.assertEquals(tpl.Name, builder.getTemplateName(), 'Should have correct template name');
        System.assertEquals(
            tpl.DeveloperName,
            builder.getTemplateDeveloperName(),
            'Should have correct template developer name'
        );
        System.assertEquals(tpl.HtmlValue, builder.getTemplateHtml(), 'Should have correct template HTML');
        System.assertEquals(tpl.Body, builder.getTemplateText(), 'Should have correct template text');
    }

    @IsTest
    static void test_EmailBuilder_setTemplate_InactiveTemplate() {
        EmailTemplate tpl = (EmailTemplate) getEmailTemplateBuilder(
                1,
                new Map<SObjectField, Object>{ EmailTemplate.IsActive => false }
            )
            .create()
            .getRecord();

        EmailHelper.EmailBuilder builder = new EmailHelper.EmailBuilder();

        try {
            Test.startTest();
            builder.setTemplate(tpl);
            Test.stopTest();

            System.assert(false, 'Should have thrown an exception');
        } catch (EmailHelper.EmailBuilderTemplateException e) {
            System.assertEquals(
                String.format(EmailHelper.ERROR_EMAIL_INACTIVE_TEMPLATE, new List<String>{ tpl.DeveloperName }),
                e.getMessage(),
                'Should have correct error message'
            );
            System.assertEquals(tpl.Id, e.getTemplate().Id, 'Should have correct template');
            System.assertEquals(false, e.getTemplate().IsActive, 'Should have inactive template');
        }
    }

    @IsTest
    static void test_EmailBuilder_setTemplate_UnsupportedTemplateType() {
        EmailTemplate tpl = (EmailTemplate) getEmailTemplateBuilder(
                1,
                new Map<SObjectField, Object>{ EmailTemplate.TemplateType => 'text' }
            )
            .create()
            .getRecord();

        EmailHelper.EmailBuilder builder = new EmailHelper.EmailBuilder();

        try {
            Test.startTest();
            builder.setTemplate(tpl);
            Test.stopTest();

            System.assert(false, 'Should have thrown an exception');
        } catch (EmailHelper.EmailBuilderTemplateException e) {
            System.assertEquals(
                String.format(
                    EmailHelper.ERROR_EMAIL_UNSUPPORTED_TEMPLATE_TYPE,
                    new List<String>{ tpl.DeveloperName, tpl.TemplateType }
                ),
                e.getMessage(),
                'Should have correct error message'
            );
            System.assertEquals(tpl.Id, e.getTemplate().Id, 'Should have correct template');
            System.assertNotEquals('custom', e.getTemplate().TemplateType, 'Should have unsupported type');
        }
    }

    @IsTest
    static void test_EmailBuilder_buildBodyHtml() {
        EmailTemplate tpl = (EmailTemplate) getEmailTemplateBuilder(
                1,
                new Map<SObjectField, Object>{
                    EmailTemplate.HtmlValue => EMAIL_TEMPLATE_HTML_DEFAULT,
                    EmailTemplate.Body => EMAIL_TEMPLATE_TEXT_DEFAULT
                }
            )
            .create()
            .getRecord();

        OrgWideEmailAddress address = [SELECT Id FROM OrgWideEmailAddress WHERE Address = 'noreply@ringcentral.com'];

        EmailHelper.EmailBuilder builder = new EmailHelper.EmailBuilder();
        builder.setFromAddress(address);
        builder.setTemplate(tpl);
        builder.addRecipient('test1@example.tld');
        builder.setBodyVariable('testVariable1', 'testValue1');
        builder.setBodyVariable('testVariable2', 'testValue2');

        Test.startTest();
        Messaging.SingleEmailMessage email = builder.buildEmail();
        Test.stopTest();

        System.assert(email.getHtmlBody().contains('testValue1'), 'Should have correct body variable value');
        System.assert(email.getHtmlBody().contains('testValue2'), 'Should have correct body variable value');
    }

    @IsTest
    static void test_EmailBuilder_buildBodyText() {
        EmailTemplate tpl = (EmailTemplate) getEmailTemplateBuilder(
                1,
                new Map<SObjectField, Object>{
                    EmailTemplate.HtmlValue => EMAIL_TEMPLATE_HTML_DEFAULT,
                    EmailTemplate.Body => EMAIL_TEMPLATE_TEXT_DEFAULT
                }
            )
            .create()
            .getRecord();

        OrgWideEmailAddress address = [SELECT Id FROM OrgWideEmailAddress WHERE Address = 'noreply@ringcentral.com'];

        EmailHelper.EmailBuilder builder = new EmailHelper.EmailBuilder();
        builder.setTemplate(tpl);
        builder.setFromAddress(address);
        builder.addRecipient('test@example.tld');
        builder.setBodyVariable('testVariable1', 'testValue1');
        builder.setBodyVariable('testVariable2', 'testValue2');

        Test.startTest();
        Messaging.SingleEmailMessage email = builder.buildEmail();
        Test.stopTest();

        System.assert(email.getPlainTextBody().contains('testValue1'), 'Should have correct body variable value');
        System.assert(email.getPlainTextBody().contains('testValue2'), 'Should have correct body variable value');
    }

    @IsTest
    static void test_EmailBuilder_buildEmail() {
        EmailTemplate tpl = (EmailTemplate) getEmailTemplateBuilder(
                1,
                new Map<SObjectField, Object>{
                    EmailTemplate.HtmlValue => EMAIL_TEMPLATE_HTML_DEFAULT,
                    EmailTemplate.Body => EMAIL_TEMPLATE_TEXT_DEFAULT
                }
            )
            .create()
            .getRecord();

        OrgWideEmailAddress address = [SELECT Id FROM OrgWideEmailAddress WHERE Address = 'noreply@ringcentral.com'];

        EmailHelper.EmailBuilder builder = new EmailHelper.EmailBuilder();
        builder.setTemplate(tpl);
        builder.setFromAddress(address);
        builder.addRecipients(new List<String>{ 'to1@example.tld' });
        builder.addCCRecipients(new List<String>{ 'cc1@example.tld' });
        builder.addBCCRecipients(new List<String>{ 'bcc1@example.tld' });
        builder.setBodyVariable('testVariable1', 'testValue1');
        builder.setBodyVariable('testVariable2', 'testValue2');

        Test.startTest();
        Messaging.SingleEmailMessage email = builder.buildEmail();
        Test.stopTest();

        System.assertEquals(tpl.Subject, email.getSubject(), 'Should have correct subject');
        System.assertEquals(tpl.Name, email.getTemplateName(), 'Should have correct template name');
        System.assertEquals(address.Id, email.getOrgWideEmailAddressId(), 'Should have correct from address');
        System.assertEquals(1, email.getToAddresses().size(), 'Should have correct number of recipients');
        System.assertEquals(1, email.getCcAddresses().size(), 'Should have correct number of CC recipients');
        System.assertEquals(1, email.getBccAddresses().size(), 'Should have correct number of BCC recipients');
        System.assert(email.getHtmlBody().contains('testValue1'), 'Should have correct body variable value');
        System.assert(email.getHtmlBody().contains('testValue2'), 'Should have correct body variable value');
        System.assert(email.getPlainTextBody().contains('testValue1'), 'Should have correct body variable value');
        System.assert(email.getPlainTextBody().contains('testValue2'), 'Should have correct body variable value');
    }

    @IsTest
    static void test_EmailBuilder_buildEmail_NoTemplate() {
        OrgWideEmailAddress address = [SELECT Id FROM OrgWideEmailAddress WHERE Address = 'noreply@ringcentral.com'];

        EmailHelper.EmailBuilder builder = new EmailHelper.EmailBuilder();
        builder.setFromAddress(address);
        builder.addRecipients(new List<String>{ 'to1@example.tld' });

        try {
            Test.startTest();
            builder.buildEmail();
            Test.stopTest();

            System.assert(false, 'Should have thrown an exception');
        } catch (EmailHelper.EmailBuilderException e) {
            System.assertEquals(
                EmailHelper.ERROR_EMAIL_NULL_TEMPLATE,
                e.getMessage(),
                'Should have correct error message'
            );
        }
    }

    @IsTest
    static void test_EmailBuilder_buildEmail_NoFromAddress() {
        EmailTemplate tpl = (EmailTemplate) getEmailTemplateBuilder(
            1,
            new Map<SObjectField, Object>{
                EmailTemplate.HtmlValue => EMAIL_TEMPLATE_HTML_DEFAULT,
                EmailTemplate.Body => EMAIL_TEMPLATE_TEXT_DEFAULT
            }
        )
            .create()
            .getRecord();

        EmailHelper.EmailBuilder builder = new EmailHelper.EmailBuilder();
        builder.setTemplate(tpl);
        builder.addRecipients(new List<String>{
            'recipient1@example.tld'
        });

        try {
            Test.startTest();
            builder.buildEmail();
            Test.stopTest();

            System.assert(false, 'Should have thrown an exception');
        } catch (EmailHelper.EmailBuilderException e) {
            System.assertEquals(
                EmailHelper.ERROR_EMAIL_NULL_FROM_ADDRESS,
                e.getMessage(),
                'Should have correct error message'
            );
        }
    }

    @IsTest
    static void test_EmailBuilder_buildEmail_NoRecipients() {
        EmailTemplate tpl = (EmailTemplate) getEmailTemplateBuilder(
            1,
            new Map<SObjectField, Object>{
                EmailTemplate.HtmlValue => EMAIL_TEMPLATE_HTML_DEFAULT,
                EmailTemplate.Body => EMAIL_TEMPLATE_TEXT_DEFAULT
            }
        )
            .create()
            .getRecord();

        OrgWideEmailAddress address = [SELECT Id FROM OrgWideEmailAddress WHERE Address = 'noreply@ringcentral.com'];

        EmailHelper.EmailBuilder builder = new EmailHelper.EmailBuilder();
        builder.setTemplate(tpl);
        builder.setFromAddress(address);

        try {
            Test.startTest();
            builder.buildEmail();
            Test.stopTest();

            System.assert(false, 'Should have thrown an exception');
        } catch (EmailHelper.EmailBuilderException e) {
            System.assertEquals(
                EmailHelper.ERROR_EMAIL_NO_RECIPIENTS,
                e.getMessage(),
                'Should have correct error message'
            );
        }
    }

    @IsTest
    static void test_EmailBuilder_buildEmail_DisabledBodyProcessing() {
        EmailTemplate tpl = (EmailTemplate) getEmailTemplateBuilder(
                1,
                new Map<SObjectField, Object>{
                    EmailTemplate.HtmlValue => EMAIL_TEMPLATE_HTML_DEFAULT,
                    EmailTemplate.Body => EMAIL_TEMPLATE_TEXT_DEFAULT
                }
            )
            .create()
            .getRecord();

        OrgWideEmailAddress address = [SELECT Id FROM OrgWideEmailAddress WHERE Address = 'noreply@ringcentral.com'];

        EmailHelper.EmailBuilder builder = new EmailHelper.EmailBuilder();
        builder.setTemplate(tpl);
        builder.setFromAddress(address);
        builder.addRecipients(new List<String>{ 'to1@example.tld' });
        builder.setBodyVariable('testVariable1', 'testValue1');
        builder.setBodyVariable('testVariable2', 'testValue2');
        builder.setIsProcessBody(false);

        Test.startTest();
        Messaging.SingleEmailMessage email = builder.buildEmail();
        Test.stopTest();

        System.assertEquals(tpl.HtmlValue, email.getHtmlBody(), 'Should have correct HTML body');
        System.assertEquals(tpl.Body, email.getPlainTextBody(), 'Should have correct text body');
    }

    @IsTest
    static void test_EmailBuilder_buildEmail_DisabledSubjectProcessing() {
        EmailTemplate tpl = (EmailTemplate) getEmailTemplateBuilder(
                1,
                new Map<SObjectField, Object>{
                    EmailTemplate.Subject => 'Test Subject 1 with {!testVariable1} and {!testVariable2}',
                    EmailTemplate.HtmlValue => EMAIL_TEMPLATE_HTML_DEFAULT,
                    EmailTemplate.Body => EMAIL_TEMPLATE_TEXT_DEFAULT
                }
            )
            .create()
            .getRecord();

        OrgWideEmailAddress address = [SELECT Id FROM OrgWideEmailAddress WHERE Address = 'noreply@ringcentral.com'];

        EmailHelper.EmailBuilder builder = new EmailHelper.EmailBuilder();
        builder.setTemplate(tpl);
        builder.setFromAddress(address);
        builder.addRecipients(new List<String>{ 'to1@example.tld' });
        builder.setBodyVariable('testVariable1', 'testValue1');
        builder.setBodyVariable('testVariable2', 'testValue2');
        builder.setIsProcessSubject(false);

        Test.startTest();
        Messaging.SingleEmailMessage emailRawSubject = builder.buildEmail();
        Test.stopTest();

        System.assertEquals(tpl.Subject, emailRawSubject.getSubject(), 'Should have correct subject');
    }

    @IsTest
    static void test_EmailBuilder_buildEmail_EmptyTemplate() {
        EmailTemplate tpl = (EmailTemplate) getEmailTemplateBuilder().create().getRecord();

        OrgWideEmailAddress address = [SELECT Id FROM OrgWideEmailAddress WHERE Address = 'noreply@ringcentral.com'];

        EmailHelper.EmailBuilder builder = new EmailHelper.EmailBuilder();
        builder.setTemplate(tpl);
        builder.setFromAddress(address);
        builder.addRecipients(new List<String>{ 'to1@example.tld' });

        Test.startTest();
        Messaging.SingleEmailMessage email = builder.buildEmail();
        Test.stopTest();

        System.assertEquals('', email.getHtmlBody(), 'Should have empty HTML body');
        System.assertEquals('', email.getPlainTextBody(), 'Should have empty text body');
    }

    @IsTest
    static void test_EmailBuilder_QuoteApprovalEmailBuilder_buildEmails() {
        List<EmailTemplate> templates = (List<EmailTemplate>) getEmailTemplateBuilder(
                2,
                new Map<SObjectField, Object>{
                    EmailTemplate.Name => ValueProviderBuilder.provideList(
                        new List<String>{ 'Test Quote Approved Template', 'Test Quote Rejected Template' }
                    ),
                    EmailTemplate.DeveloperName => ValueProviderBuilder.provideList(
                        new List<String>{ 'Test_QuoteApprovedEmail', 'Test_QuoteRejectedEmail' }
                    ),
                    EmailTemplate.Subject => ValueProviderBuilder.provideList(
                        new List<String>{ 'Quote Approved', 'Quote Rejected' }
                    ),
                    EmailTemplate.HtmlValue => EMAIL_TEMPLATE_HTML_QUOTE_FIELDS
                }
            )
            .create()
            .getRecords();

        OrgWideEmailAddress address = [SELECT Id FROM OrgWideEmailAddress WHERE Address = 'noreply@ringcentral.com'];
        List<Quote> quotes = [
            SELECT
                Id,
                Name,
                QuoteNumber,
                Approved_Status__c,
                JustificationandDescription__c,
                OpportunityId,
                Opportunity.Name,
                Opportunity.Owner.Name,
                Opportunity.Owner.Email,
                Opportunity.Owner.ManagerId,
                Opportunity.Owner.Manager.Name,
                Opportunity.Owner.Manager.Email,
                Opportunity.Inside_Sales_Rep__c,
                Opportunity.Inside_Sales_Rep__r.Name,
                Opportunity.Inside_Sales_Rep__r.Email,
                AccountId,
                Account.Name
            FROM Quote
        ];

        Map<String, Quote> qtByQuoteNumber = new Map<String, Quote>();
        for (Quote qt : quotes) {
            qtByQuoteNumber.put(qt.QuoteNumber, qt);
        }

        EmailTemplate tplApproved = null;
        EmailTemplate tplRejected = null;
        for (EmailTemplate tpl : templates) {
            switch on tpl.DeveloperName {
                when 'Test_QuoteApprovedEmail' {
                    tplApproved = tpl;
                }
                when 'Test_QuoteRejectedEmail' {
                    tplRejected = tpl;
                }
            }
        }

        EmailHelper.QuoteApprovalEmailBuilder emailBuilder = new EmailHelper.QuoteApprovalEmailBuilder();
        emailBuilder.setQuotes(quotes);
        emailBuilder.setApprovedTemplate(tplApproved);
        emailBuilder.setRejectedTemplate(tplRejected);
        emailBuilder.setFromAddress(address);

        System.assertEquals(tplApproved, emailBuilder.getApprovedTemplate(), 'Approved template should be set');
        System.assertEquals(tplRejected, emailBuilder.getRejectedTemplate(), 'Rejected template should be set');

        Test.startTest();
        List<Messaging.SingleEmailMessage> emails = emailBuilder.buildEmails();
        Test.stopTest();

        for (Messaging.SingleEmailMessage email : emails) {
            String quoteNumber = email.getHtmlBody().substringAfter('QuoteNumber = ').substringBefore('<br/>\n');
            Quote qt = qtByQuoteNumber.get(quoteNumber);

            if (String.isNotBlank(qt.Opportunity.Inside_Sales_Rep__c)) {
                System.assert(
                    new Set<String>(email.getCcAddresses()).contains(qt.Opportunity.Inside_Sales_Rep__r.Email),
                    'Should contain channel manager as CC recipient'
                );
            }

            System.assert(
                new Set<String>(email.getCcAddresses()).contains(qt.Opportunity.Owner.Manager.Email),
                'Should contain opportunity owner\'s manager as CC recipient'
            );
            System.assert(
                new Set<String>(email.getToAddresses()).contains(qt.Opportunity.Owner.Email),
                'Should have correct recipient'
            );
            System.assert(
                email.getHtmlBody().contains(qt.Opportunity.Owner.Name),
                'Should have correct body variable value'
            );
            System.assert(email.getHtmlBody().contains(qt.QuoteNumber), 'Should have correct body variable value');
            System.assert(email.getHtmlBody().contains(qt.OpportunityId), 'Should have correct body variable value');
            System.assert(email.getHtmlBody().contains(qt.Opportunity.Name), 'Should have correct body variable value');
            System.assert(email.getHtmlBody().contains(qt.AccountId), 'Should have correct body variable value');
            System.assert(email.getHtmlBody().contains(qt.Account.Name), 'Should have correct body variable value');
            System.assert(
                email.getHtmlBody().contains(qt.JustificationandDescription__c),
                'Should have correct body variable value'
            );
        }
    }

    @IsTest
    static void test_EmailBuilder_QuoteApprovalEmailBuilder_getRecipients() {
        EmailHelper.QuoteApprovalEmailBuilder emailBuilder = new EmailHelper.QuoteApprovalEmailBuilder();
        emailBuilder.addRecipients(new List<String>{ 'test1@example.tld' });

        Test.startTest();
        Set<String> recipients = emailBuilder.getRecipients();
        Test.stopTest();

        System.assertEquals(1, recipients.size(), 'Should have correct number of recipients');
        System.assertEquals(true, recipients.contains('test1@example.tld'));
    }

    @IsTest
    static void test_EmailBuilder_QuoteApprovalEmailBuilder_setRecipients() {
        EmailHelper.QuoteApprovalEmailBuilder emailBuilder = new EmailHelper.QuoteApprovalEmailBuilder();

        Test.startTest();
        emailBuilder.setRecipients(new Set<String>{ 'test1@example.tld' });
        Test.stopTest();

        System.assertEquals(1, emailBuilder.getRecipients().size(), 'Should have correct number of recipients');
        System.assertEquals(true, emailBuilder.getRecipients().contains('test1@example.tld'));
    }

    @IsTest
    static void test_EmailBuilder_QuoteApprovalEmailBuilder_addRecipient() {
        EmailHelper.QuoteApprovalEmailBuilder emailBuilder = new EmailHelper.QuoteApprovalEmailBuilder();

        Test.startTest();
        emailBuilder.addRecipient('test1@example.tld');
        Test.stopTest();

        System.assertEquals(1, emailBuilder.getRecipients().size(), 'Should have correct number of recipients');
        System.assertEquals(true, emailBuilder.getRecipients().contains('test1@example.tld'));
    }

    @IsTest
    static void test_EmailBuilder_QuoteApprovalEmailBuilder_addRecipients() {
        EmailHelper.QuoteApprovalEmailBuilder emailBuilder = new EmailHelper.QuoteApprovalEmailBuilder();

        Test.startTest();
        emailBuilder.addRecipients(new List<String>{ 'test1@example.tld' });
        Test.stopTest();

        System.assertEquals(1, emailBuilder.getRecipients().size(), 'Should have correct number of recipients');
        System.assertEquals(true, emailBuilder.getRecipients().contains('test1@example.tld'));
    }

    @IsTest
    static void test_EmailBuilder_QuoteApprovalEmailBuilder_addRecipients_Set() {
        EmailHelper.QuoteApprovalEmailBuilder emailBuilder = new EmailHelper.QuoteApprovalEmailBuilder();

        Test.startTest();
        emailBuilder.addRecipients(new Set<String>{ 'test1@example.tld' });
        Test.stopTest();

        System.assertEquals(1, emailBuilder.getRecipients().size(), 'Should have correct number of recipients');
        System.assertEquals(true, emailBuilder.getRecipients().contains('test1@example.tld'));
    }

    @IsTest
    static void test_EmailBuilder_QuoteApprovalEmailBuilder_getCCRecipients() {
        EmailHelper.QuoteApprovalEmailBuilder emailBuilder = new EmailHelper.QuoteApprovalEmailBuilder();
        emailBuilder.addCCRecipients(new List<String>{ 'test1@example.tld' });

        Test.startTest();
        Set<String> recipients = emailBuilder.getCCRecipients();
        Test.stopTest();

        System.assertEquals(1, recipients.size(), 'Should have correct number of recipients');
        System.assertEquals(true, recipients.contains('test1@example.tld'));
    }

    @IsTest
    static void test_EmailBuilder_QuoteApprovalEmailBuilder_setCCRecipients() {
        EmailHelper.QuoteApprovalEmailBuilder emailBuilder = new EmailHelper.QuoteApprovalEmailBuilder();

        Test.startTest();
        emailBuilder.setCCRecipients(new Set<String>{ 'test1@example.tld' });
        Test.stopTest();

        System.assertEquals(1, emailBuilder.getCCRecipients().size(), 'Should have correct number of recipients');
        System.assertEquals(true, emailBuilder.getCCRecipients().contains('test1@example.tld'));
    }

    @IsTest
    static void test_EmailBuilder_QuoteApprovalEmailBuilder_addCCRecipient() {
        EmailHelper.QuoteApprovalEmailBuilder emailBuilder = new EmailHelper.QuoteApprovalEmailBuilder();

        Test.startTest();
        emailBuilder.addCCRecipient('test1@example.tld');
        Test.stopTest();

        System.assertEquals(1, emailBuilder.getCCRecipients().size(), 'Should have correct number of recipients');
        System.assertEquals(true, emailBuilder.getCCRecipients().contains('test1@example.tld'));
    }

    @IsTest
    static void test_EmailBuilder_QuoteApprovalEmailBuilder_addCCRecipients() {
        EmailHelper.QuoteApprovalEmailBuilder emailBuilder = new EmailHelper.QuoteApprovalEmailBuilder();

        Test.startTest();
        emailBuilder.addCCRecipients(new List<String>{
            'test1@example.tld'
        });
        Test.stopTest();

        System.assertEquals(1, emailBuilder.getCCRecipients().size(), 'Should have correct number of recipients');
        System.assertEquals(true, emailBuilder.getCCRecipients().contains('test1@example.tld'));
    }

    @IsTest
    static void test_EmailBuilder_QuoteApprovalEmailBuilder_addCCRecipients_Set() {
        EmailHelper.QuoteApprovalEmailBuilder emailBuilder = new EmailHelper.QuoteApprovalEmailBuilder();

        Test.startTest();
        emailBuilder.addCCRecipients(new Set<String>{
            'test1@example.tld'
        });
        Test.stopTest();

        System.assertEquals(1, emailBuilder.getCCRecipients().size(), 'Should have correct number of recipients');
        System.assertEquals(true, emailBuilder.getCCRecipients().contains('test1@example.tld'));
    }

    @IsTest
    static void test_EmailBuilder_QuoteApprovalEmailBuilder_getBCCRecipients() {
        EmailHelper.QuoteApprovalEmailBuilder emailBuilder = new EmailHelper.QuoteApprovalEmailBuilder();
        emailBuilder.addBCCRecipients(new List<String>{ 'test1@example.tld' });

        Test.startTest();
        Set<String> recipients = emailBuilder.getBCCRecipients();
        Test.stopTest();

        System.assertEquals(1, recipients.size(), 'Should have correct number of recipients');
        System.assertEquals(true, recipients.contains('test1@example.tld'));
    }

    @IsTest
    static void test_EmailBuilder_QuoteApprovalEmailBuilder_setBCCRecipients() {
        EmailHelper.QuoteApprovalEmailBuilder emailBuilder = new EmailHelper.QuoteApprovalEmailBuilder();

        Test.startTest();
        emailBuilder.setBCCRecipients(new Set<String>{ 'test1@example.tld' });
        Test.stopTest();

        System.assertEquals(1, emailBuilder.getBCCRecipients().size(), 'Should have correct number of recipients');
        System.assertEquals(true, emailBuilder.getBCCRecipients().contains('test1@example.tld'));
    }

    @IsTest
    static void test_EmailBuilder_QuoteApprovalEmailBuilder_addBCCRecipient() {
        EmailHelper.QuoteApprovalEmailBuilder emailBuilder = new EmailHelper.QuoteApprovalEmailBuilder();

        Test.startTest();
        emailBuilder.addBCCRecipient('test1@example.tld');
        Test.stopTest();

        System.assertEquals(1, emailBuilder.getBCCRecipients().size(), 'Should have correct number of recipients');
        System.assertEquals(true, emailBuilder.getBCCRecipients().contains('test1@example.tld'));
    }

    @IsTest
    static void test_EmailBuilder_QuoteApprovalEmailBuilder_addBCCRecipients() {
        EmailHelper.QuoteApprovalEmailBuilder emailBuilder = new EmailHelper.QuoteApprovalEmailBuilder();

        Test.startTest();
        emailBuilder.addBCCRecipients(new List<String>{
            'test1@example.tld'
        });
        Test.stopTest();

        System.assertEquals(1, emailBuilder.getBCCRecipients().size(), 'Should have correct number of recipients');
        System.assertEquals(true, emailBuilder.getBCCRecipients().contains('test1@example.tld'));
    }

    @IsTest
    static void test_EmailBuilder_QuoteApprovalEmailBuilder_addBCCRecipients_Set() {
        EmailHelper.QuoteApprovalEmailBuilder emailBuilder = new EmailHelper.QuoteApprovalEmailBuilder();

        Test.startTest();
        emailBuilder.addBCCRecipients(new Set<String>{
            'test1@example.tld'
        });
        Test.stopTest();

        System.assertEquals(1, emailBuilder.getBCCRecipients().size(), 'Should have correct number of recipients');
        System.assertEquals(true, emailBuilder.getBCCRecipients().contains('test1@example.tld'));
    }

    @IsTest
    static void test_EmailBuilder_QuoteApprovalEmailBuilder_setCompiledPatterns() {
        EmailHelper.QuoteApprovalEmailBuilder emailBuilder = new EmailHelper.QuoteApprovalEmailBuilder();

        Test.startTest();
        emailBuilder.setCompiledPatterns(new Map<String, Pattern>{
            'testVariable1' => Pattern.compile('testValue1'),
            'testVariable2' => Pattern.compile('testValue2')
        });
        Test.stopTest();

        System.assertEquals(2, emailBuilder.getCompiledPatterns().size(), 'Should have correct number of patterns');
        System.assertEquals(true, emailBuilder.getCompiledPatterns().containsKey('testVariable1'));
        System.assertEquals(true, emailBuilder.getCompiledPatterns().containsKey('testVariable2'));
    }

    @IsTest
    static void test_EmailBuilder_QuoteApprovalEmailBuilder_setCompiledPatterns_List() {
        EmailHelper.QuoteApprovalEmailBuilder emailBuilder = new EmailHelper.QuoteApprovalEmailBuilder();

        Test.startTest();
        emailBuilder.setCompiledPatterns(new List<String>{ 'testVariable1', 'testVariable2' });
        Test.stopTest();

        System.assertEquals(9, emailBuilder.getCompiledPatterns().size(), 'Should have correct number of patterns');
        System.assertEquals(true, emailBuilder.getCompiledPatterns().containsKey('testVariable1'));
        System.assertEquals(true, emailBuilder.getCompiledPatterns().containsKey('testVariable2'));
    }

    @IsTest
    static void test_EmailBuilder_QuoteApprovalEmailBuilder_setBodyVariable() {
        EmailHelper.QuoteApprovalEmailBuilder emailBuilder = new EmailHelper.QuoteApprovalEmailBuilder();

        Test.startTest();
        emailBuilder.setBodyVariable('testVariable1', 'testValue1');
        Test.stopTest();

        System.assertEquals(1, emailBuilder.getBodyVariables().size(), 'Should have correct number of variables');
        System.assertEquals(true, emailBuilder.getBodyVariables().containsKey('testVariable1'), 'Should have correct variable name');
        System.assertEquals('testValue1', emailBuilder.getBodyVariables().get('testVariable1'), 'Should have correct variable value');
    }

    @IsTest
    static void test_EmailBuilder_QuoteApprovalEmailBuilder_setBodyVariables() {
        EmailHelper.QuoteApprovalEmailBuilder emailBuilder = new EmailHelper.QuoteApprovalEmailBuilder();

        Test.startTest();
        emailBuilder.setBodyVariables(new Map<String, String>{
            'testVariable1' => 'testValue1',
            'testVariable2' => 'testValue2'
        });
        Test.stopTest();

        System.assertEquals(2, emailBuilder.getBodyVariables().size(), 'Should have correct number of variables');
        System.assertEquals(true, emailBuilder.getBodyVariables().containsKey('testVariable1'), 'Should have correct variable name');
        System.assertEquals('testValue1', emailBuilder.getBodyVariables().get('testVariable1'), 'Should have correct variable value');
        System.assertEquals(true, emailBuilder.getBodyVariables().containsKey('testVariable2'), 'Should have correct variable name');
        System.assertEquals('testValue2', emailBuilder.getBodyVariables().get('testVariable2'), 'Should have correct variable value');
    }

    @IsTest
    static void test_EmailBuilder_QuoteApprovalEmailBuilder_getBodyVariable() {
        EmailHelper.QuoteApprovalEmailBuilder emailBuilder = new EmailHelper.QuoteApprovalEmailBuilder();
        emailBuilder.setBodyVariable('testVariable1', 'testValue1');

        Test.startTest();
        String bodyVariableValue = emailBuilder.getBodyVariable('testVariable1');
        Test.stopTest();

        System.assertEquals('testValue1', bodyVariableValue, 'Should have correct variable value');
    }

    @IsTest
    static void test_EmailBuilder_QuoteApprovalEmailBuilder_setFromAddress() {
        EmailHelper.QuoteApprovalEmailBuilder emailBuilder = new EmailHelper.QuoteApprovalEmailBuilder();
        OrgWideEmailAddress address = [SELECT Id FROM OrgWideEmailAddress WHERE Address = 'noreply@ringcentral.com'];

        Test.startTest();
        emailBuilder.setFromAddress(address);
        Test.stopTest();

        System.assertEquals(address.Id, emailBuilder.getFromAddress().Id, 'Should have correct from address');
    }

    @IsTest
    static void test_EmailBuilder_QuoteCreationEmailBuilder_buildEmails() {
        List<EmailTemplate> templates = (List<EmailTemplate>) getEmailTemplateBuilder(
            1,
            new Map<SObjectField, Object>{
                EmailTemplate.Name => 'New Quote Ignite',
                EmailTemplate.DeveloperName => 'New_Quote_Ignite',
                EmailTemplate.Subject => 'New Quote',
                EmailTemplate.HtmlValue => EMAIL_TEMPLATE_HTML_NEW_IGNITE_QUOTE
            }
        )
            .create()
            .getRecords();

        OrgWideEmailAddress address = [SELECT Id FROM OrgWideEmailAddress WHERE Address = 'noreply@ringcentral.com'];
        List<Quote> quotes = [
            SELECT
                Id,
                Name,
                QuoteNumber,
                JustificationandDescription__c,
                OpportunityId,
                Opportunity.Id,
                Opportunity.AccountId,
                Opportunity.Name,
                Opportunity.Type,
                Opportunity.Owner.Name,
                Opportunity.Owner.Email,
                Opportunity.Owner.ManagerId,
                Opportunity.Owner.Manager.Name,
                Opportunity.Owner.Manager.Email,
                Opportunity.Inside_Sales_Rep__c,
                Opportunity.Inside_Sales_Rep__r.Name,
                Opportunity.Inside_Sales_Rep__r.Email,
                Opportunity.StageName,
                Opportunity.PartnerProgram__c,
                AccountId,
                Account.Name
            FROM Quote
        ];

        Map<String, Quote> qtByQuoteNumber = new Map<String, Quote>();
        for (Quote qt : quotes) {
            qtByQuoteNumber.put(qt.QuoteNumber, qt);
        }

        Set<String> opportunityStages = new Set<String> {
            '1. Qualify',
            '2. Problem'
        };

        EmailHelper.QuoteCreationEmailBuilder emailBuilder = new EmailHelper.QuoteCreationEmailBuilder();
        emailBuilder.setQuotes(quotes);
        emailBuilder.setTemplate(templates.get(0));
        emailBuilder.setFromAddress(address);
        emailBuilder.setOpportunityStages(opportunityStages);

        System.assertEquals(templates.get(0), emailBuilder.getTemplate(), 'Template should be set');
        System.assertEquals(address, emailBuilder.getFromAddress(), 'From address should be set');
        System.assertEquals(quotes, emailBuilder.getQuotes(), 'Quotes should be set');
        System.assertEquals(opportunityStages, emailBuilder.getOpportunityStages(), 'Opportunity stages should be set');

        Test.startTest();
        List<Messaging.SingleEmailMessage> emails = emailBuilder.buildEmails();
        Test.stopTest();

        for (Messaging.SingleEmailMessage email : emails) {
            String quoteNumber = email.getHtmlBody().substringAfter('QuoteNumber = ').substringBefore('<br/>\n');
            Quote qt = qtByQuoteNumber.get(quoteNumber);

            if (String.isNotBlank(qt.Opportunity.Inside_Sales_Rep__c)) {
                System.assert(
                    new Set<String>(email.getCcAddresses()).contains(qt.Opportunity.Inside_Sales_Rep__r.Email),
                    'Should contain channel manager as CC recipient'
                );
            }

            System.assert(
                new Set<String>(email.getToAddresses()).contains(qt.Opportunity.Owner.Email),
                'Should have correct recipient'
            );
            System.assert(
                email.getHtmlBody().contains(qt.Opportunity.Owner.Name),
                'Should have correct body variable value'
            );
            System.assert(email.getHtmlBody().contains(qt.QuoteNumber), 'Should have correct body variable value');
            System.assert(email.getHtmlBody().contains(Url.getOrgDomainUrl().toExternalForm() + '/' + qt.Id), 'Should have correct body variable value');
            System.assert(email.getHtmlBody().contains(qt.OpportunityId), 'Should have correct body variable value');
            System.assert(email.getHtmlBody().contains(Url.getOrgDomainUrl().toExternalForm() + '/' + qt.OpportunityId), 'Should have correct body variable value');
            System.assert(email.getHtmlBody().contains(qt.Opportunity.Name), 'Should have correct body variable value');
        }
    }

    @IsTest
    static void testProServIgniteEmailBuilder() {
        String proServCaseReasons = 'test case Reason';
        List<EmailTemplate> templates = (List<EmailTemplate>)
            getEmailTemplateBuilder(
                1,
                new Map<SObjectField, Object>{
                    EmailTemplate.Name => 'Initiate ProServ Ignite',
                    EmailTemplate.DeveloperName => 'Initiate_ProServ_Ignite',
                    EmailTemplate.Subject => 'UC Quote requested for {!AccountName}',
                    EmailTemplate.HtmlValue => EMAIL_TEMPLATE_HTML_PROSERV_IGNITE
                }
            )
            .create()
            .getRecords();

        List<OrgWideEmailAddress> orgWideEmailAdresses = (List<OrgWideEmailAddress>) new QueryFactory(OrgWideEmailAddress.SObjectType)
            .selectFields(new List<String>{'Id'})
            .setCondition('Address = :bind0')
            .setQueryBindings(new List<String>{ EmailHelper.EMAIL_ADDRESS_NO_REPLY })
            .executeQuery();

        List<Quote> testQuotes = (List<Quote>) new QuoteSelector()
            .newQueryFactory()
            .setFactoryName('selectQuotes')
            .selectFields(new List<String> {
                'Id',
                'QuoteNumber',
                'AccountId',
                'Account.Id',
                'Account.Name',
                'Account.Partner_Contact__r.Name',
                'Account.Partner_Contact__r.Email',
                'OpportunityId',
                'Opportunity.Id',
                'Opportunity.AccountId',
                'Opportunity.Name',
                'Opportunity.Inside_Sales_Rep__c.Email',
                'Opportunity.Owner.Name',
                'Opportunity.Owner.Email',
                'Opportunity.Owner.Manager.Name',
                'Opportunity.Owner.Manager.Email',
                'Opportunity.Name',
                'Opportunity.Type',
                'Opportunity.StageName',
                'Opportunity.PartnerProgram__c'
            })
            .withoutSelectorOrderByIncluded()
            .setLimit(1)
            .executeQuery();

        EmailHelper.ProServIgniteEmailBuilder emailBuilder = new EmailHelper.ProServIgniteEmailBuilder();
        emailBuilder.setQuotes(testQuotes);
        emailBuilder.setTemplate(templates.get(0));
        emailBuilder.setFromAddress(orgWideEmailAdresses.get(0));
        emailBuilder.setCaseReasons(proServCaseReasons);

        System.assertEquals(templates.get(0), emailBuilder.getTemplate(), 'Template should be set');
        System.assertEquals(orgWideEmailAdresses[0], emailBuilder.getFromAddress(), 'From address should be set');
        System.assertEquals(testQuotes, emailBuilder.getQuotes(), 'Quotes should be set');

        Test.startTest();
            List<Messaging.SingleEmailMessage> emails = emailBuilder.buildEmails();
        Test.stopTest();

        for (Messaging.SingleEmailMessage email : emails) {
            if (String.isNotBlank(testQuotes[0].Opportunity.Inside_Sales_Rep__c)) {
                System.assert(
                    new Set<String>(email.getCcAddresses()).contains(testQuotes[0].Opportunity.Inside_Sales_Rep__r.Email),
                    'Should contain channel manager as CC recipient'
                );
            }

            System.assert(
                new Set<String>(email.getToAddresses()).contains(testQuotes[0].Opportunity.Owner.Email),
                'Should have correct recipient'
            );
            System.assert(
                email.getHtmlBody().contains(testQuotes[0].Opportunity.Owner.Name),
                'Should have correct body variable value'
            );
            System.assert(email.getHtmlBody().contains(testQuotes[0].QuoteNumber), 'Should have correct body variable value');
            System.assert(email.getHtmlBody().contains(Url.getOrgDomainUrl().toExternalForm() + '/' + testQuotes[0].Id), 'Should have correct body variable value');
            System.assert(email.getHtmlBody().contains(testQuotes[0].OpportunityId), 'Should have correct body variable value');
            System.assert(email.getHtmlBody().contains(Url.getOrgDomainUrl().toExternalForm() + '/' + testQuotes[0].OpportunityId), 'Should have correct body variable value');
            System.assert(email.getHtmlBody().contains(testQuotes[0].Opportunity.Name), 'Should have correct body variable value');
            System.assert(email.getHtmlBody().contains(Url.getOrgDomainUrl().toExternalForm() + '/' + testQuotes[0].AccountId), 'Should have correct body variable value');
            System.assert(email.getHtmlBody().contains(testQuotes[0].Account.Name), 'Should have correct body variable value');
            System.assert(email.getHtmlBody().contains(proServCaseReasons), 'Should have correct body variable value');
        }
    }

    @IsTest
    static void testProServIgniteEmailBuilderEmptyCaseReasons() {
        String proServCaseReasons;
        List<EmailTemplate> templates = (List<EmailTemplate>)
            getEmailTemplateBuilder(
                1,
                new Map<SObjectField, Object>{
                    EmailTemplate.Name => 'Initiate ProServ Ignite',
                    EmailTemplate.DeveloperName => 'Initiate_ProServ_Ignite',
                    EmailTemplate.Subject => 'UC Quote requested for {!AccountName}',
                    EmailTemplate.HtmlValue => EMAIL_TEMPLATE_HTML_PROSERV_IGNITE
                }
            )
            .create()
            .getRecords();

        List<OrgWideEmailAddress> orgWideEmailAdresses = (List<OrgWideEmailAddress>) new QueryFactory(OrgWideEmailAddress.SObjectType)
            .selectFields(new List<String>{'Id'})
            .setCondition('Address = :bind0')
            .setQueryBindings(new List<String>{ EmailHelper.EMAIL_ADDRESS_NO_REPLY })
            .executeQuery();

        List<Quote> testQuotes = (List<Quote>) new QuoteSelector()
            .newQueryFactory()
            .setFactoryName('selectQuotes')
            .selectFields(new List<String> {
                'Id',
                'QuoteNumber',
                'AccountId',
                'Account.Id',
                'Account.Name',
                'Account.Partner_Contact__r.Name',
                'Account.Partner_Contact__r.Email',
                'OpportunityId',
                'Opportunity.Id',
                'Opportunity.AccountId',
                'Opportunity.Name',
                'Opportunity.Inside_Sales_Rep__c.Email',
                'Opportunity.Owner.Name',
                'Opportunity.Owner.Email',
                'Opportunity.Owner.Manager.Name',
                'Opportunity.Owner.Manager.Email',
                'Opportunity.Name',
                'Opportunity.Type',
                'Opportunity.StageName',
                'Opportunity.PartnerProgram__c'
            })
            .withoutSelectorOrderByIncluded()
            .setLimit(1)
            .executeQuery();

        EmailHelper.ProServIgniteEmailBuilder emailBuilder = new EmailHelper.ProServIgniteEmailBuilder();
        emailBuilder.setQuotes(testQuotes);
        emailBuilder.setTemplate(templates.get(0));
        emailBuilder.setFromAddress(orgWideEmailAdresses.get(0));
        emailBuilder.setCaseReasons(proServCaseReasons);

        System.assertEquals(templates.get(0), emailBuilder.getTemplate(), 'Template should be set');
        System.assertEquals(orgWideEmailAdresses[0], emailBuilder.getFromAddress(), 'From address should be set');
        System.assertEquals(testQuotes, emailBuilder.getQuotes(), 'Quotes should be set');

        Test.startTest();
            List<Messaging.SingleEmailMessage> emails = emailBuilder.buildEmails();
        Test.stopTest();

        for (Messaging.SingleEmailMessage email : emails) {
            if (String.isNotBlank(testQuotes[0].Opportunity.Inside_Sales_Rep__c)) {
                System.assert(
                    new Set<String>(email.getCcAddresses()).contains(testQuotes[0].Opportunity.Inside_Sales_Rep__r.Email),
                    'Should contain channel manager as CC recipient'
                );
            }

            System.assert(
                new Set<String>(email.getToAddresses()).contains(testQuotes[0].Opportunity.Owner.Email),
                'Should have correct recipient'
            );
            System.assert(
                email.getHtmlBody().contains(testQuotes[0].Opportunity.Owner.Name),
                'Should have correct body variable value'
            );
            System.assert(email.getHtmlBody().contains(testQuotes[0].QuoteNumber), 'Should have correct body variable value');
            System.assert(email.getHtmlBody().contains(Url.getOrgDomainUrl().toExternalForm() + '/' + testQuotes[0].Id), 'Should have correct body variable value');
            System.assert(email.getHtmlBody().contains(testQuotes[0].OpportunityId), 'Should have correct body variable value');
            System.assert(email.getHtmlBody().contains(Url.getOrgDomainUrl().toExternalForm() + '/' + testQuotes[0].OpportunityId), 'Should have correct body variable value');
            System.assert(email.getHtmlBody().contains(testQuotes[0].Opportunity.Name), 'Should have correct body variable value');
            System.assert(email.getHtmlBody().contains(Url.getOrgDomainUrl().toExternalForm() + '/' + testQuotes[0].AccountId), 'Should have correct body variable value');
            System.assert(email.getHtmlBody().contains(testQuotes[0].Account.Name), 'Should have correct body variable value');
            System.assert(email.getHtmlBody().contains('A category has not been selected'), 'Should have correct body variable value because case reasons are not selected');
        }
    }
}