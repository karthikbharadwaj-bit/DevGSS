@isTest
private class Test_OpportunityTeamMemberSelector {

    @testSetup
    private static void testSetup() {
        List<User> users = (List<User>) new SObjectBuilder(User.SObjectType)
            .quantity(2)
            .create()
            .getRecords();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setField(Opportunity.Name, new ValueProvider.ListProvider(new List<String>{'testOpp_1', 'testOpp_2'}))
            .quantity(2)
            .create()
            .getRecord(0);
        
        List<SObject> sos = new SObjectBuilder(OpportunityTeamMember.SObjectType)
            .quantity(2)
            .setField(OpportunityTeamMember.OpportunityId, opp.Id)
            .setField(OpportunityTeamMember.UserId,
                new ValueProvider.ListProvider(new List<String>{users[0].Id, users[1].Id}))
            .setField(OpportunityTeamMember.TeamMemberRole, 
                new ValueProvider.ListProvider(new List<String>{'testRole_1', 'testRole_2'}))
            .create()
            .getRecords();
    }

    @isTest
    private static void testSelectByOpportunityIdsAndRoles() {
        List<Opportunity> opps = (new OpportunitySelector()).newQueryFactory()
            .selectField(Opportunity.Name)
            .setCondition('Name = \'testOpp_1\'')
            .executeQuery();

        List<Object> bindings = new List<Object>{new Set<Id>{opps[0].Id}, new Set<String>{'testRole_1'}};

        Test.startTest();

            List<OpportunityTeamMember> oppTeamMems = (new OpportunityTeamMemberSelector())
                .selectByOpportunityIdsAndRoles(bindings)
                .selectField(OpportunityTeamMember.TeamMemberRole)
                .executeQuery();

        Test.stopTest();
        
        System.assertEquals(1, oppTeamMems.size(), 'Wrong number of returned records');
        System.assertEquals('testRole_1', oppTeamMems[0].TeamMemberRole, 'Wrong OpportunityTeamMember returned.');
    }
}