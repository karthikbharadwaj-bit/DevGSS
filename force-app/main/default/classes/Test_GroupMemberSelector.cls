@isTest
private class Test_GroupMemberSelector {
    //Fields for User object defined
    private static final String USER_FIRST_NAME = 'TestForGroupMemberFirstName';
    private static final String USER_LAST_NAME = 'TestForGroupMemberLastName';
    private static final String USER_USERNAME = 'testUserForGM@username.com';
    private static final STRING USER_EMAIL = 'user@email.com';

    //Fields for Group object defined
    private static final String GROUP_DEVELOPER_NAME = 'Test';
    private static final String GROUP_NAME = 'Test Group';
    private static final String GROUP_TYPE = 'Regular';

    //Assert message
    private static final String ASSERT_MESSAGE = 'Group members should be selected';

    @testSetup
    private static void testData(){
        User testUser = (User) new SObjectBuilder(User.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    User.FirstName => USER_FIRST_NAME,
                    User.LastName => USER_LAST_NAME,
                    User.ProfileId => System.UserInfo.getProfileId(),
                    User.UserName => USER_USERNAME,
                    User.Email => USER_EMAIL,
                    User.isActive => TRUE
                })
			.create()
            .getRecord();

		Group testGroup = (Group) new SObjectBuilder(Group.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Group.DeveloperName => GROUP_DEVELOPER_NAME,
                    Group.Name => GROUP_NAME,
                    Group.Type => GROUP_TYPE
                }
            )
            .create()
            .getRecord();

        GroupMember testGM = (GroupMember) new SObjectBuilder(GroupMember.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    GroupMember.GroupId => testGroup.Id,
                    GroupMember.UserOrGroupId => testUser.Id
                }
            )
            .create()
            .getRecord();

    }

    @isTest
    private static void testSelectExistGroupMembersBasedOnUserIdAndGroupId(){
        List<User> userByUsername = (List<User>) new UserSelector(true, true)
            .selectUserByUsername(new List<Object>{new Set<String>{USER_USERNAME}})
            .executeQuery();

        List<Group> groupBasedOnDeveloperNames = (List<Group>) new GroupSelector()
            .selectGroupBasedOnDeveloperNames(new List<Object>{new Set<String>{GROUP_DEVELOPER_NAME}})
            .executeQuery();

        List<GroupMember> existGroupMembersBasedOnUserIdAndGroupId = (List<GroupMember>) new GroupMemberSelector()
            .selectExistGroupMembersBasedOnUserIdAndGroupId(new List<Object>{new Set<Id>{userByUsername[0].Id},
                															 new Set<Id>{groupBasedOnDeveloperNames[0].Id}})
            .executeQuery();

        System.assert(existGroupMembersBasedOnUserIdAndGroupId.size() > 0, ASSERT_MESSAGE);
    }

    @isTest
    private static void testSelectGroupMembersByGroupName(){
        List<GroupMember> groupMembersByGroupName = (List<GroupMember>) new GroupMemberSelector(true, true)
            .selectGroupMembersByGroupName(GROUP_NAME)
            .executeQuery();

        System.assert(groupMembersByGroupName.size() > 0, ASSERT_MESSAGE);
    }

    @isTest
    private static void testSelectGroupMembersByGroupIds(){

        List<Group> groupBasedOnDeveloperNames = (List<Group>) new GroupSelector()
            .selectGroupBasedOnDeveloperNames(new List<Object>{new Set<String>{GROUP_DEVELOPER_NAME}})
            .executeQuery();

        List<GroupMember> groupMembersByGroupIds = (List<GroupMember>) new GroupMemberSelector(true, true)
            .selectGroupMembersByGroupIds(new Set<Id>{groupBasedOnDeveloperNames[0].Id})
            .executeQuery();

        System.assert(groupMembersByGroupIds.size() > 0, ASSERT_MESSAGE);
    }

    @isTest
    static void testSelectByGroupDeveloperName() {
        String dummyDeveloperName = 'developerName';
        Test.startTest();
            QueryFactory factory = new GroupMemberSelector()
                .selectByGroupDeveloperName(dummyDeveloperName)
                .setQuery();
        Test.stopTest();

        String expectedWhereClause = 'FROM GroupMember WHERE Group.DeveloperName = :bind0';

        System.assertNotEquals(null, factory, 'Selector must return QuoteFactory');
        System.assert(!String.isBlank(factory.getQuery()), 'Selector must compose a string query');
        System.assertEquals(true, factory.getQuery().contains(expectedWhereClause), 'Selector must have the right WHERE clause');
        System.assertEquals(1, factory.bindings.size(), 'Selector must have 1 input binding variables');
        System.assertEquals(dummyDeveloperName, factory.bindings[0], 'Selector must have the same developerName input');
    }

    @isTest
    private static void testSelectGroupMemberBasedOnUserAndGroupName(){
        List<User> userByUsername = (List<User>) new UserSelector(true, true)
            .selectUserByUsername(new List<Object>{new Set<String>{USER_USERNAME}})
            .executeQuery();

        List<Group> groupBasedOnDeveloperNames = (List<Group>) new GroupSelector()
            .selectGroupBasedOnDeveloperNames(new List<Object>{new Set<String>{GROUP_DEVELOPER_NAME}})
            .executeQuery();

        List<GroupMember> groupMemberBasedOnUserAndGroupNameList = (List<GroupMember>) new GroupMemberSelector(true, true)
            .selectGroupMemberBasedOnUserAndGroupName(new List<Object>{
                userByUsername[0].Id,
                GROUP_TYPE,
                new Set<String>{groupBasedOnDeveloperNames[0].Name}
            })
            .executeQuery();

        System.assert(groupMemberBasedOnUserAndGroupNameList.size() > 0, ASSERT_MESSAGE);
    }
}