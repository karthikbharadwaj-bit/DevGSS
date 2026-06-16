@IsTest
private class Test_LeadHelperCls {
    static final String SALES_AGENT_SDR = 'Sales Agent SDR w Insidesales';
    static final String SALES_AGENT_USERNAME = 'SalesAgentUserName@email.com';

    @TestSetup
    static void testSetup() {

        Profile agentProfile = (Profile) new ProfileSelector()
            .selectProfileByName(new List<String> {SALES_AGENT_SDR})
            .executeQuery()
            .get(0);

        UserRole userRole = (UserRole) new SObjectBuilder(UserRole.SObjectType)
            .setField(UserRole.Name, 'BDR Manager')
            .create()
            .getRecord();

        new SObjectBuilder(User.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                User.LastName => ValueProviderBuilder.provideUniqueString('LastName'),
                User.FirstName => ValueProviderBuilder.provideUniqueString('FirstName'),
                User.Email => ValueProviderBuilder.provideUniqueEmail('Email'),
                User.Username => SALES_AGENT_USERNAME,
                User.LanguageLocaleKey => 'en_US',
                User.ProfileId => agentProfile.Id,
                User.UserRoleId => userRole.Id
            })
            .create();
    }

    static User salesAgentSDRUser {
        get {
            if (salesAgentSDRUser == null) {
                List<User> users = (List<User>) new UserSelector()
                    .selectUserByUsername(new List<Object> {new List<String> {SALES_AGENT_USERNAME}})
                    .executeQuery();

                salesAgentSDRUser = users.get(0);
            }
            return salesAgentSDRUser;
        }
        private set;
    }

    @IsTest
    static void test_Convert_ShouldReturnNull_WhenFeatureToggleEnabled() {
        System.runAs(salesAgentSDRUser) {
            Feature_Toggle__c featureToggle = Feature_Toggle__c.getInstance();
            featureToggle.SkipLeadQualifications__c = true;
            upsert featureToggle;

            System.assertEquals(
                LeadHelperCls.POPULATE_REQUIRED_FIELDS,
                LeadHelperCls.convert(getLeadCreatedByUser(salesAgentSDRUser).Id),
                'Should be null, since Feature Toggle is enabled');
        }
    }

    @IsTest
    static void test_Convert_ShouldExecuteMethodLogic_WhenFeatureToggleDisabled() {
        System.runAs(salesAgentSDRUser) {
            Feature_Toggle__c featureToggle = Feature_Toggle__c.getInstance();
            featureToggle.SkipLeadQualifications__c = false;
            upsert featureToggle;

            System.assertEquals(
                LeadHelperCls.POPULATE_REQUIRED_FIELDS,
                LeadHelperCls.convert(getLeadCreatedByUser(salesAgentSDRUser).Id),
                'Should be an error message, since Feature Toggle is disabled and no Lead Qualification object was not created');
        }
    }

    static Lead getLeadCreatedByUser(User user) {
        return (Lead) new SObjectBuilder(Lead.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Lead.LastName => 'TestLead',
                Lead.Company => ValueProviderBuilder.provideUniqueString(),
                Lead.Email => ValueProviderBuilder.provideUniqueEmail('Email'),
                Lead.LeadSource => 'Inbound Call',
                Lead.OwnerId => user.Id
            })
            .create()
            .getRecord();
    }
}