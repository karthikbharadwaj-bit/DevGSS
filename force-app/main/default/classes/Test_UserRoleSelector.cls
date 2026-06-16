@isTest
private class Test_UserRoleSelector {

    @isTest
    private static void testSelectUserRole() {
        UserRole ur = new UserRole(
            DeveloperName = 'TestCustomRole',
            Name = 'Test Role');
        
        insert ur;

        UserRole obtainedUserRole;

        Test.startTest();
            obtainedUserRole = (UserRole) new UserRoleSelector()
                .selectUserRoleById(new List<Object>{ ur.Id })
                .executeQuery()
                .get(0);
        Test.stopTest();

        System.assertEquals(obtainedUserRole.Name, 'Test Role');
    }
}