@isTest
private class Test_GroupSelector {
	
    //Group fields defined
    private static final String GROUP_DEVELOPER_NAME = 'Test';
    private static final String GROUP_NAME = 'Test Group';
    private static final String ASSERT_MESSAGE = 'Should select 1 group';
    
    @testSetup
    private static void testData() {
        Group testGroup = (Group) new SObjectBuilder(Group.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Group.DeveloperName => GROUP_DEVELOPER_NAME,
                    Group.Name => GROUP_NAME,
                    Group.Type => GroupHelper.GROUP_TYPE_QUEUE
                }
            )
            .create()
            .getRecord();
    }
    
    @isTest
    private static void testSelectGroups(){
        List<Group> groups = (List<Group>) new GroupSelector()
            .selectGroups()
            .setLimit(1)
            .executeQuery();

        System.assert(groups.size() == 1, ASSERT_MESSAGE);
    }
    
    @isTest
    private static void testSelectGroupBasedOnDeveloperNames(){
        List<Group> groupBasedOnDeveloperNames = (List<Group>) new GroupSelector()
            .selectGroupBasedOnDeveloperNames(new List<Object>{new Set<String>{GROUP_DEVELOPER_NAME}})
            .executeQuery();
        
        System.assert(groupBasedOnDeveloperNames.size() == 1, ASSERT_MESSAGE);
    }
    
    @isTest
    private static void testSelectQueueByName(){
        List<Group> queueByName = (List<Group>) new GroupSelector(true, true)
            .selectQueueByName(GROUP_NAME)
            .executeQuery();
        
        System.assert(queueByName.size() == 1, ASSERT_MESSAGE);
    }

    @isTest
    private static void testSelectQueuesById() {
        List<Group> queuesById = (List<Group>) new GroupSelector(true, true)
            .selectQueuesById(new List<String>{[SELECT Id FROM Group WHERE Name = :GROUP_NAME].Id})
            .executeQuery();
        
        System.assert(queuesById.size() == 1, ASSERT_MESSAGE);
    }
}