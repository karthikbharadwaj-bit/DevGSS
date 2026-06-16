@IsTest
private class Test_AssignmentRuleSelector {

    @IsTest
    static void testSelectAssignmentRuleBySobject() {
        Test.startTest();
        AssignmentRule caseAssignmentRule = (AssignmentRule) new ListOptional(new AssignmentRuleSelector()
            .selectAssignmentRuleBySobject('Case')
            .executeQuery()
        ).getFirst();
        AssignmentRule leadAssignmentRule = (AssignmentRule) new ListOptional(new AssignmentRuleSelector()
            .selectAssignmentRuleBySobject('Lead')
            .executeQuery()
        ).getFirst();
        Test.stopTest();
        System.assert(caseAssignmentRule != null, 'Assignment rule for case object was returned');
        System.assert(leadAssignmentRule != null, 'Assignment rule for lead object was returned');
    }
}