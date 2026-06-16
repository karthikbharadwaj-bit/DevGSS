@isTest
private class Test_Case_RecallCase_Controller {

    class TestState {
        List<User> testUsers;
        List<Case> cases;
        TestState(List<User> testUsers, List<Case> cases) {
            this.testUsers = testUsers;
            this.cases = cases;
        }
    }

    @isTest
    static void testRecallCaseSuccess() {
        TestState state = createTestData();
        User testUser = state.testUsers[0];
        User adminUser = state.testUsers[1];
        
        Test.startTest();
        String resultCancelled = Case_RecallCase_Controller.recallCase(state.cases[0].Id, adminUser.Id);
        String resultCurrentAssignee = Case_RecallCase_Controller.recallCase(state.cases[1].Id, adminUser.Id);
        String resultSuccess = Case_RecallCase_Controller.recallCase(state.cases[2].Id, adminUser.Id);
        String resultNotValid = Case_RecallCase_Controller.recallCase(state.cases[2].Id, testUser.Id);
        Test.stopTest();

        Assert.areEqual(
            'Since the Case is ' + CaseHelper.CASE_STATUS_CANCELLED + ', you cannot perform this action anymore.',
            resultCancelled,
            'Case should not be recalled.'
        );
        Assert.areEqual(
            'You are the current assignee of the case. You cannot recall the case',
            resultCurrentAssignee,
            'Case should not be recalled.'
        );
        Assert.areEqual('Success', resultSuccess, 'Case should be recalled successfully.');
        Assert.areEqual('This action is not valid for you', resultNotValid, 'Case should not be recalled.');
    }

    @isTest
    static void testUpdateCase() {
        TestState state = createTestData();
        User testUser = state.testUsers[0];
        User adminUser = state.testUsers[1];
        Case testCase = state.cases[2];
        
        Assert.areEqual(testCase.Status, CaseHelper.CASE_STATUS_REOPENED, 'Case should be in Reopened status.');
        Assert.areEqual(testCase.OwnerId, testUser.Id, 'Case should be assigned to test user.');
        Test.startTest();
        String result = Case_RecallCase_Controller.updateCase(state.cases[2].Id, adminUser.Id);
        Test.stopTest();

        Assert.areEqual(
            'You have Recalled Case successfully',
            result,
            'Case should be recalled successfully.'
        );

        testCase = (Case) new ListOptional(new CaseSelector()
            .selectCasesByIds(new Set<Id> { testCase.Id })
            .withoutSelectorFieldsIncluded()
            .selectFields(new List<SObjectField> { Case.Status, Case.OwnerId })
            .executeQuery()
        ).getFirst();

        Assert.areEqual(testCase.Status, CaseHelper.CASE_STATUS_NEW, 'Case should be in New status.');
        Assert.areEqual(testCase.OwnerId, adminUser.Id, 'Case should be assigned to admin user.');
    }

    static TestState createTestData() {
        List<User> testUsers = (List<User>) new SObjectBuilder(User.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                User.LastName => new ValueProvider.ListProvider(
                    new List<String> {
                        'TEST_USER_NAME',
                        'TEST_ADMIN_NAME'
                    }
                ),
                User.Username => new ValueProvider.ListProvider(
                    new List<String> {
                        'TestUserNameForTest!user@gmail.com',
                        'TestAdminUserOwner!user@gmail.com'
                    }
                ),
                User.Email => new ValueProvider.ListProvider(
                    new List<String> {
                        'TestUserNameForTest!user@gmail.com',
                        'TestAdminUserOwner!user@gmail.com'
                    }
                ),
                User.Alias => new ValueProvider.ListProvider(
                    new List<String> {
                        'Test',
                        'Admi'
                    }
                ),
                User.Hierarchy_Role__c => new ValueProvider.ListProvider(
                    new List<String> {
                        UserHelper.SALES_REP_ROLE,
                        null
                    }
                ),
                User.LocaleSidKey => 'en_US',
                User.EmailEncodingKey => 'UTF-8',
                User.LanguageLocaleKey => 'en_US',
                User.TimeZoneSidKey => 'America/Los_Angeles',
                User.ProfileId => ProfileHelper.PROFILE_ID_SYSADMIN
            })
            .quantity(2)
            .create()
            .getRecords();

        User testUser = testUsers[0];
        User adminUser = testUsers[1];

        List<Case> cases = (List<Case>) new SObjectBuilder(Case.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Case.Status => new ValueProvider.ListProvider(new List<String> { 
                    CaseHelper.CASE_STATUS_CANCELLED, 
                    CaseHelper.CASE_STATUS_NEW,
                    CaseHelper.CASE_STATUS_REOPENED
                }),
                Case.OwnerId => new ValueProvider.ListProvider(new List<Id> { adminUser.Id, adminUser.Id, testUser.Id })
            })
            .quantity(3)
            .createAsUser(adminUser)
            .getRecords();

        return new TestState(testUsers, cases);
    }
}