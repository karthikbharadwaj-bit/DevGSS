@isTest
private class Test_CaseActivityTriggerHelper {
    
    static Account createAccount() {
        return (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.recordtypeId => Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer Account').getRecordTypeId(),
                    Account.Name => 'Test Account',
                    Account.RC_User_ID__c => '12345',
                    Account.Number_of_DL_s__c => 10,
                    Account.RC_Brand__c => 'RingCentral'
                }
            )
            .create()
            .getRecord();
    }
    
    static Contact createContact(Account acc) {
        return (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(Contact.SObjectType))
            .create()
            .getRecord();
    }

    static Case createCase(Account acc, Contact cont, Id ownerId) {
        return (Case) new SObjectBuilder(Case.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Case.Status => 'New',
                    Case.RecordTypeId => CaseHelper.RT_ID_CUSTOMER_FEEDBACK,
                    Case.AccountId => acc.Id,
                    Case.ContactId => cont.Id,
                    Case.Subject => 'Test',
                    Case.Description => 'Test',
                    Case.Origin => 'Phone',
                    Case.OwnerId => ownerId
                }
            )
            .create()
            .getRecord();
    }

    static User createUser() {
        return (User) new SObjectBuilder(User.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(User.SObjectType))
            .create()
            .getRecord();
    }

    static List<Case_Activity__c> createCaseActivities(Case aCase, Integer amount) {
        return (List<Case_Activity__c>) new SObjectBuilder(Case_Activity__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Case_Activity__c.Name => ValueProviderBuilder.provideUniqueString('Close attempt #'),
                Case_Activity__c.Case__c => aCase.Id,
                Case_Activity__c.Status__c => 'New',
                Case_Activity__c.Assigned_To__c => aCase.OwnerId,
                Case_Activity__c.RecordTypeId => CaseHelper.RT_ID_CASE_ACTIVITY_CLOSE_ATTEMPT
            })
            .quantity(amount)
            .create()
            .getRecords();
    }

    @isTest
    static void updateRelatedCaseActivitiesToCancelled_whenUpdateACaseActivityToSucceded_shouldMarkAllOtherCaseActivitiesToCancelled() {
        User testUser = createUser();

        Account acc = createAccount();
        Contact cont = createContact(acc);
        Case aCase = createCase(acc, cont, testUser.Id);
        List<Case_Activity__c> caseActivities = createCaseActivities(aCase, 3);

        Test.startTest();
            Case_Activity__c cActivity = caseActivities.get(0);
            cActivity.Status__c = 'Succeded';
            update cActivity;
        Test.stopTest();

        Case_Activity__c[] caseActivitiesQuery = new CaseActivitySelector()
            .selectCloseAttemptsByCaseIdAndRecordType(new Object[]{
                new Id[]{Acase.Id},
                CaseHelper.RT_ID_CASE_ACTIVITY_CLOSE_ATTEMPT
            })
            .executeQuery();

        System.assertEquals(3, caseActivitiesQuery.size(), 'The case activities size must be 3.');

        for (Case_Activity__c caseActivity : caseActivitiesQuery) {
            if (caseActivity.Id != cActivity.Id) {
                System.assertEquals('Cancelled', caseActivity.Status__c, 'Invalid status, it should be Cancelled.');
            }
        }
    }
}