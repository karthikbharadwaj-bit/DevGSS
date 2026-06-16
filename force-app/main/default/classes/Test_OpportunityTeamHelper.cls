@IsTest
private class Test_OpportunityTeamHelper {
    private static final String TEST_OPPORTUNITY_NAME_BASE = 'Test Opportunity';
    private static final String TEST_ACC_NAME = 'Test Account';
    private static final String TEST_USER_USERNAME = 'test@ringcentral.com';
    private static final String SNIPPET_OF_MAIN_EMAIL_BODY_TEMPLATE = 'Please start engaging in conversations with the other team members along with the AE, BDR, Company, etc. to ensure a smooth and impactful sales process for';

    @TestSetup
    static void setup() {
        User testUser = (User) new SObjectBuilder(User.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                User.Alias => StringHelper.getRandomString(8),
                User.Email => ValueProviderBuilder.provideUniqueEmail(),
                User.EmailEncodingKey => 'UTF-8',
                User.LanguageLocaleKey => 'en_US',
                User.LastName => ValueProviderBuilder.provideUniqueString('LastName'),
                User.LocaleSidKey => 'en_US',
                User.ProfileId => ProfileHelper.PROFILE_ID_SYSADMIN,
                User.Region__c => 'US',
                User.Sub_Region__c => 'All',
                User.TimeZoneSidKey => 'America/Los_Angeles',
                User.Username => TEST_USER_USERNAME
            })
            .create()
            .getRecord();

        Triggers.switchOff();
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setField(Account.Name, TEST_ACC_NAME)
            .createAsUser(testUser)
            .getRecord();

        List<Opportunity> testOpps = (List<opportunity>) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.Name => ValueProviderBuilder.provideUniqueString(TEST_OPPORTUNITY_NAME_BASE),
                Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL,
                Opportunity.RecordTypeId => OpportunityHelper.RT_ID_NEW_SALES_OPPORTUNITY,
                Opportunity.AccountId => acc.Id,
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                Opportunity.CloseDate => Date.today().addMonths(1),
                Opportunity.CurrencyIsoCode => OpportunityHelper.CURRENCY_ISO_CODE_USD,
                Opportunity.Tier_Name__c => OpportunityHelper.TIER_OFFICE,
                Opportunity.Total_Contract_Value__c => 0,
                Opportunity.Forecasted_Users__c => 1,
                Opportunity.Forecasted_RingCentral_Video_Users__c => 0,
                Opportunity.Forecast_Contact_Center_Users__c => 0
            })
            .quantity(2)
            .createAsUser(testUser)
            .getRecords();

        new SObjectBuilder(OpportunityTeamMember.sObjectType)
            .setFields(new Map<SObjectField, Object> {
                OpportunityTeamMember.OpportunityId => ValueProviderBuilder.provideParents(testOpps),
                OpportunityTeamMember.UserId => testUser.Id
            })
            .createAsUser(testUser);
        Triggers.switchOn();
    }

    @isTest
    static void testNotifyOppTeamMembersAboutNewOpportunities() {
        List<OpportunityTeamHelper.NotificationParam> params = prepareTestInputParams(getTestOppTeamMember(), 1);

        Test.startTest();
            OpportunityTeamHelper.notifyOppTeamMembersAboutNewOpportunities(params);
            Integer numberOfEmailInvocations = Limits.getEmailInvocations();
        Test.stopTest();

        Assert.areEqual(1, numberOfEmailInvocations, 'In case of correct input, Messaging.sendEmail() must be executed once');
    }

    @isTest
    static void testNotifyOppTeamMembersAboutNewOpportunitiesInBulk() {
        List<OpportunityTeamHelper.NotificationParam> params = prepareTestInputParams(getTestOppTeamMember(), 2);

        Test.startTest();
            OpportunityTeamHelper.notifyOppTeamMembersAboutNewOpportunities(params);
            Integer numberOfEmailInvocations = Limits.getEmailInvocations();
        Test.stopTest();

        Assert.areEqual(1, numberOfEmailInvocations, 'In case of correct input, Messaging.sendEmail() must be executed once');
    }

    @isTest
    static void testNotifyOppTeamMembersAboutNewOpportunitiesEmptyInput() {
        List<OpportunityTeamHelper.NotificationParam> params = prepareTestInputParams(new List<OpportunityTeamMember>(), 0);

        Test.startTest();
            OpportunityTeamHelper.notifyOppTeamMembersAboutNewOpportunities(params);
            Integer numberOfEmailInvocations = Limits.getEmailInvocations();
        Test.stopTest();

        Assert.areEqual(0, numberOfEmailInvocations, 'In case of an empty input, Messaging.sendEmail() must not be executed');
    }

    @isTest
    static void testNotifyOppTeamMembersAboutNewOpportunitiesInputHasNoOppTeamMember() {
        List<OpportunityTeamHelper.NotificationParam> params = prepareTestInputParams(new List<OpportunityTeamMember>(), 1);

        Test.startTest();
            OpportunityTeamHelper.notifyOppTeamMembersAboutNewOpportunities(params);
            Integer numberOfEmailInvocations = Limits.getEmailInvocations();
        Test.stopTest();

        Assert.areEqual(0, numberOfEmailInvocations, 'In case of no Opportunity Team Member was provided, Messaging.sendEmail() must not be executed');
    }

    @isTest
    static void testConstructEmailMainBodyWithFullDetails() {
        Opportunity testOpp = getTestOpp();
        OpportunityTeamHelper.OpportunityTeamMemberNotifier notifier = new OpportunityTeamHelper.OpportunityTeamMemberNotifier(new List<OpportunityTeamHelper.NotificationParam>());
        Test.startTest();
            String resultBody = notifier.constructMainBody(testOpp);
        Test.stopTest();

        Assert.isNotNull(resultBody, 'The method must return a string');
        Assert.isTrue(
            resultBody.contains(SNIPPET_OF_MAIN_EMAIL_BODY_TEMPLATE),
            'The method must return correct email body'
        );
        Assert.isTrue(
            resultBody.contains('Tier Name:'),
            'The resulted body must contain Tier Name field if the input Opportunity has it'
        );
    }

    @isTest
    static void testConstructEmailMainBodyWithNotFullDetails() {
        Opportunity testOpp = getTestOpp();
        OpportunityTeamHelper.OpportunityTeamMemberNotifier notifier = new OpportunityTeamHelper.OpportunityTeamMemberNotifier(new List<OpportunityTeamHelper.NotificationParam>());

        testOpp.Tier_Name__c = null;
        testOpp.Total_Contract_Value__c = null;
        Test.startTest();
            String resultBody = notifier.constructMainBody(testOpp);
        Test.stopTest();

        Assert.isNotNull(resultBody, 'The method must return a string');
        Assert.isTrue(
            resultBody.contains(SNIPPET_OF_MAIN_EMAIL_BODY_TEMPLATE),
            'The method must return correct email body'
        );
        Assert.isFalse(
            resultBody.contains('Tier Name:'),
            'The resulted body must not contain Tier Name field if the input Opportunity does not have it'
        );
        Assert.isFalse(
            resultBody.contains('Total Contract Value:'),
            'The resulted body must not contain Total Contract Value field if the input Opportunity does not have it'
        );
        Assert.isTrue(
            resultBody.contains('Forecasted Office Users:'),
            'The resulted body must contain Forecasted Office Users field if the input Opportunity has it'
        );
    }

    private static List<OpportunityTeamHelper.NotificationParam> prepareTestInputParams(OpportunityTeamMember oppTeamMemberToNotify, Integer paramAmount) {
        return prepareTestInputParams(new List<OpportunityTeamMember> {oppTeamMemberToNotify}, paramAmount);
    }

    private static List<OpportunityTeamHelper.NotificationParam> prepareTestInputParams(List<OpportunityTeamMember> oppTeamMembersToNotify, Integer paramAmount) {
        List<OpportunityTeamHelper.NotificationParam> params = new List<OpportunityTeamHelper.NotificationParam>();
        for (Integer i = 0; i < paramAmount; i++) {
            OpportunityTeamHelper.NotificationParam param = new OpportunityTeamHelper.NotificationParam();
            param.oppTeamMembers = oppTeamMembersToNotify;

            params.add(param);
        }

        return params;
    }

    private static OpportunityTeamMember getTestOppTeamMember() {
        User testUser = (User) new ListOptional(
            new UserSelector()
                .selectUserByUsername(new List<Object> {new List<String> {TEST_USER_USERNAME}})
                .executeQuery()
        ).getFirst();

        return (OpportunityTeamMember) new ListOptional(
            new OpportunityTeamMemberSelector()
                .newQueryFactory()
                .setFactoryName('getByUserId')
                .withoutSelectorFieldsIncluded()
                .selectField(OpportunityTeamMember.Id)
                .setCondition('UserId = :bind0')
                .setQueryBindings(new List<Object> {testUser.Id})
                .executeQuery()
        ).getFirst();
    }

    private static Opportunity getTestOpp() {
        return (Opportunity) new ListOptional(
            new OpportunitySelector()
                .newQueryFactory()
                .setFactoryName('getOpptyByName')
                .withoutSelectorFieldsIncluded()
                .selectFields(new Set<String> {
                    'Id',
                    'Name',
                    'Owner.Name',
                    'Account.Name',
                    'Tier_Name__c',
                    'Total_Contract_Value__c',
                    'Forecasted_Users__c',
                    'Forecasted_RingCentral_Video_Users__c',
                    'Forecast_Contact_Center_Users__c'
                })
                .setCondition('Name LIKE :bind0')
                .setQueryBindings(new List<Object> {'%' + TEST_OPPORTUNITY_NAME_BASE + '%'})
                .executeQuery()
        ).getFirst();
    }
}