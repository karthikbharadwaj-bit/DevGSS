@isTest
private class Test_CasePriorityIncrementSched{

    private static final Set<String> PRIORITIES_WITH_NEXT_PRIORITY_AVAILABLE = new Set<String>{'Low', 'Medium', 'High'};

    @testSetup
    private static void testSetup() {
        Case[] cs = new List<case>();
        
        List<String> priopitiesToTest = new List<String>{'Low', 'Critical', 'None'};
        List<String> statusesToTest = new List<String>{'Hold', 'New'};

        Set<Id> ownersToTest = new Set<Id>();
        List<Group> groups = (new GroupSelector()).newQueryFactory()
            .setCondition('DeveloperName = :bind0 AND Type = \'Queue\'')
            .subselect(new GroupMemberSelector().newQueryFactory()
                .selectField(GroupMember.UserOrGroupId))
            .setQueryBindings(new List<Object>{CasePriorityIncrementSched.QUEUE_DEV_NAME})
            .setLimit(1)
            .executeQuery();

        ownersToTest.add(UserInfo.getUserId());
        ownersToTest.add(groups[0].Id);
        if (groups[0].GroupMembers.size() > 0) {
            ownersToTest.add(groups[0].GroupMembers[0].UserOrGroupId);
        }

        List<String> priopitiesForValueProvider = new List<String>();
        List<String> statusesForValueProvider = new List<String>();
        List<Id> ownersForValueProvider = new List<Id>();

        for (String priority : priopitiesToTest) {
            for (String status : statusesToTest) {
                for (Id owner : ownersToTest) {
                    priopitiesForValueProvider.add(priority);
                    statusesForValueProvider.add(status);
                    ownersForValueProvider.add(owner);
                }
            }
        }

        new SObjectBuilder(Case.SObjectType)
            .quantity(priopitiesForValueProvider.size())
            .setFields(
                new Map<SObjectField, Object> {
                    Case.Priority => ValueProviderBuilder.provideList(priopitiesForValueProvider),
                    Case.Status => ValueProviderBuilder.provideList(statusesForValueProvider),
                    Case.OwnerId => ValueProviderBuilder.provideList(ownersForValueProvider)
                })
            .create();
    }

    @isTest
    private static void testGetNextPriority() {
        String errorMsg = 'Next priority is incorrect.';

        System.assertEquals('Medium', CasePriorityIncrementSched.getNextPriority('Low'), errorMsg);
        System.assertEquals('High', CasePriorityIncrementSched.getNextPriority('Medium'), errorMsg);
        System.assertEquals('Critical', CasePriorityIncrementSched.getNextPriority('High'), errorMsg);
        System.assertEquals(null, CasePriorityIncrementSched.getNextPriority('RandomPriority'), errorMsg);
        System.assertEquals(null, CasePriorityIncrementSched.getNextPriority('Critical'), errorMsg);
    }

    @isTest
    private static void testGetQueueMembers() {
        Set<Id> queueMemberIds = CasePriorityIncrementSched.getQueueMembers();
        System.assert(queueMemberIds.size() > 0, 'getQueueMembers() must return at least queue itself.');

        List<Group> groups = (new GroupSelector()).newQueryFactory()
            .setCondition('DeveloperName = :bind0 AND Type = \'Queue\'')
            .subselect(new GroupMemberSelector().newQueryFactory()
                .selectField(GroupMember.UserOrGroupId))
            .setQueryBindings(new List<Object>{CasePriorityIncrementSched.QUEUE_DEV_NAME})
            .setLimit(1)
            .executeQuery();

        System.assert(queueMemberIds.contains(groups[0].Id), 'getQueueMembers() must contain \'' +
            CasePriorityIncrementSched.QUEUE_DEV_NAME + '\' queue id.');
    }

    @isTest
    private static void testWholeProcessNoPriorityIncrements() {
        CasePriorityIncrementSched shed = new CasePriorityIncrementSched();

        Map<Id, Case> casesBefore = new Map<Id, Case>((List<Case>)
            (new CaseSelector()).newQueryFactory()
                .selectFields(new List<Schema.SObjectField>{Case.Id, Case.Priority})
                .executeQuery()
        );
        System.assert(casesBefore.size() > 0, 'Some cases must be created in @testSetup');
        
        Test.startTest();

            shed.execute(null);

        Test.stopTest();

        Map<Id, Case> casesAfter = new Map<Id, Case>((List<Case>)
            (new CaseSelector()).newQueryFactory()
                .selectFields(new List<Schema.SObjectField>{Case.Id, Case.Priority})
                .executeQuery()
        );
        // for each case checks that prioprity is not changed  
        for (Id caseId : casesBefore.keySet()) {
            System.assertEquals(casesBefore.get(caseId).Priority, casesAfter.get(caseId).Priority, 
                'Case priority should not be changed when big increment period used');
        }
    }

    @isTest
    private static void testWholeProcessWithPriorityIncrements() {
        // -1 as days offset will lead to priopirty increment of any case created in a past (i.e. before System.now())
        CasePriorityIncrementSched shed = new CasePriorityIncrementSched(-1);

        Map<Id, Case> casesBefore = new Map<Id, Case>((List<Case>)
            (new CaseSelector()).newQueryFactory()
                .selectFields(new List<Schema.SObjectField>{Case.Id, Case.Priority, Case.Status, Case.OwnerId})
                .executeQuery()
        );
        System.assert(casesBefore.size() > 0, 'Some cases must be created in @testSetup');
        
        Set<Id> queueMemberIds = CasePriorityIncrementSched.getQueueMembers();

        Test.startTest();

            shed.execute(null);

        Test.stopTest();

        Map<Id, Case> casesAfter = new Map<Id, Case>((List<Case>)
            (new CaseSelector()).newQueryFactory()
                .selectFields(new List<Schema.SObjectField>{Case.Id, Case.Priority})
                .executeQuery()
        );

        // for each case checks that prioprity is not changed
        for (Case caseBefore : casesBefore.values()) {
            // all cases was 'marked' at creation time
            if (isPriorityShouldBeChanged(caseBefore, queueMemberIds)) {
                System.assertNotEquals(caseBefore.Priority, casesAfter.get(caseBefore.Id).Priority,
                    'Case priority should be updated when case is matches the criteria.');
            } else {
                System.assertEquals(caseBefore.Priority, casesAfter.get(caseBefore.Id).Priority,
                    'Case priority should not be changed when case is not matches the criteria.');
            }
        }
    }

    private static Boolean isPriorityShouldBeChanged(Case c, Set<Id> owners) {
        return c.Status == 'Hold' && owners.contains(c.OwnerId) 
            && PRIORITIES_WITH_NEXT_PRIORITY_AVAILABLE.contains(c.Priority);
    }

    /*
     * CaseHistory record could not be created in unit test context,
     * therefore some fake records are passed directly to getCasesWithIncreasedPriorities() method.
     * This way we could test a logic which uses History records.
     */
    @isTest
    private static void testGetCasesWithIncreasedPriorities() {
        CasePriorityIncrementSched shed = new CasePriorityIncrementSched(2);

        // this case has a History record with 1 days old
        // this case priority should not be increased
        Case case1day = createCaseWithHistoryRecord('1dayCase', -1, 'Low');
        // this case has a History record with 30 days old
        // this case priority should be increased
        Case case30days = createCaseWithHistoryRecord('30daysCase', -30, 'Low');

        List<Case> cases = new List<Case>{case1day, case30days};

        Test.startTest();

            List<Case> casesWithIncreasedPriorities = shed.getCasesWithIncreasedPriorities(cases);

        Test.stopTest();

        System.assertEquals(1, casesWithIncreasedPriorities.size(), 'Only one case should have increased priority.');
        System.assertEquals('30daysCase', casesWithIncreasedPriorities[0].CaseNumber, 'Wrong case record returned.');
        System.assertNotEquals('Low', casesWithIncreasedPriorities[0].Priority, 'Priority must be changed.');

    }

    private static Case createCaseWithHistoryRecord(String caseNumber, Integer offsetHistory, String priority) {
        String caseJson = '{"CaseNumber":"' + caseNumber + '","Histories":{"done":true,"records":[{"CreatedDate":' +
            JSON.serialize(System.now().addDays(offsetHistory)) + '}],"totalSize":1},"Priority":"' + priority + '"}';
        return (Case) JSON.deserialize(caseJson, Case.class);
    }

    @isTest
    private static void testIncorrectBusinessHoursName() {
        Boolean isExceptionThrown = false;
        try{
            new CasePriorityIncrementSched(0, 'fake\nName');
        } catch (AquivaHelper.AquivaException ex) {
            isExceptionThrown = true;
            System.assertEquals('No such BusinessHours : \'fake\nName\'.', ex.getMessage(), 'Wrong exception message.');
        }
        System.assert(isExceptionThrown, 'An exception should be thrown if nonexistent name is passed.');
    }

}