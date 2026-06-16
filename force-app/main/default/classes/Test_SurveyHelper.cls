@IsTest
private class Test_SurveyHelper {
    @isTest
    static void testBuildSurveyForCase() {
        Contact contactObj = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Contact.Id => ValueProviderBuilder.provideDummyId(Contact.sObjectType),
                Contact.FirstName => 'TestFirstName',
                Contact.LastName => 'TestLastName',
                Contact.Email => new ValueProvider.UniqueStringProvider('test@test.test')
            })
            .build()
            .getRecord();
        Map<Id, Contact> contactsMap = new Map<Id, Contact> {contactObj.Id => contactObj};

        User userObj = getUserById(UserInfo.getUserId());
        Map<Id, User> usersMap = new Map<Id, User> {userObj.Id => userObj};

        Case caseObj = (Case) new SObjectBuilder(Case.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Case.Id => ValueProviderBuilder.provideDummyId(Case.sObjectType),
                Case.ContactId => contactObj.Id,
                Case.Status => CaseHelper.CASE_STATUS_CLOSED,
                Case.RecordTypeId => CaseHelper.RT_ID_SUPPORT_T1,
                Case.OwnerId => userObj.Id
            })
            .build()
            .getRecord();
        Test.startTest();
        Survey__c surveObj = SurveyHelper.buildSurveyForCase(caseObj, SurveyHelper.SURVEY_TYPE_PORTING, usersMap, contactsMap);
        Test.stopTest();

        Assert.isNotNull(surveObj, 'A survey should be created for a corresponding case.');
        Assert.areEqual(caseObj.Id, surveObj.Case__c, 'A survey does not have a related case');
        Assert.areEqual(caseObj.ContactId, surveObj.Contact__c, 'A survey should have a related contact');
        Assert.areEqual(contactObj.Email, surveObj.Contact_Email__c, 'A survey does not have a corresponding email');
        Assert.areEqual(userObj.Name, surveObj.Agent_Name__c, 'A survey should have a corresponding owner name');
        Assert.areEqual(SurveyHelper.SURVEY_TYPE_PORTING, surveObj.SurveyType__c, 'A created survey should have a Porting type');
    }

    @isTest
    static void testGetAgentEmail() {
        new SObjectBuilder(Emails__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Emails__c.Name => SurveyHelper.SURVEY_AGENT_EMAIL,
                Emails__c.Email_Address__c => new ValueProvider.UniqueStringProvider('test@test.test')
            })
            .create();
        User userObj = getUserById(UserInfo.getUserId());
        Map<Id, User> usersMap = new Map<Id, User> {userObj.Id => userObj};

        Case caseObj = (Case) new SObjectBuilder(Case.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Case.OwnerId => userObj.Id
            })
            .build()
            .getRecord();

        Test.startTest();
        String agentEmail = SurveyHelper.getAgentEmail(caseObj, usersMap);
        String agentEmailFromCustomSettings = SurveyHelper.getAgentEmail(caseObj, new Map<Id, User>());
        Test.stopTest();

        Assert.isNotNull(agentEmail, 'An agent email should be returned');
        Assert.isNotNull(agentEmailFromCustomSettings, 'An agent email should be returned');
        Assert.areEqual(agentEmail, userObj.Email, 'An agent email should be equal to the user email');
    }

    private static User getUserById(Id userId) {
        return (User) new ListOptional(new UserSelector()
            .selectUserByIdForNewCase(new List<Object> {new Set<Id> {userId}})
            .withoutSelectorFieldsIncluded()
            .selectFields(new List<String> {
                'Id',
                'Name',
                'Team__c',
                'Manager.Email',
                'Manager.Name',
                'Email',
                'IsActive'
            })
            .executeQuery()
        ).getFirst();
    }
}