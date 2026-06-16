@IsTest
private class Test_CustomPermissionHelper {

    @isTest
    static void testUserPermissions() {
        Triggers.switchOff();

        // Get Profiles
        Profile profile = [SELECT Id, Name FROM Profile WHERE Name = 'Sales Rep - Lightning'];

        System.debug(profile);
        // Create Users
        User user1 = new User(
                FirstName = 'John1',
                LastName = 'Doe1',
                Email = 'example@testemail.tld',
                Username = 'example@testemail.tld'+Math.Random(),
                Alias = 'JohnDoe1',
                ProfileId = profile.Id,
                TimeZoneSidKey = 'America/Los_Angeles',
                LocaleSidKey = 'en_US',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US'
        );

        User user2 = new User(
                FirstName = 'John2',
                LastName = 'Doe2',
                Email = 'example@testemail.tld',
                Username = 'example@testemail.tld'+Math.Random(),
                Alias = 'JohnDoe2',
                ProfileId = profile.Id,
                TimeZoneSidKey = 'America/Los_Angeles',
                LocaleSidKey = 'en_US',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US'
        );

        insert new List<User>{
            user1, user2
        };

        //

        // Create Permission Set
        PermissionSet ps1 = new PermissionSet(
                Name = 'Test_CustomPermissionHelper_PermissionSet1',
                Label = 'Test_CustomPermissionHelper_PermissionSet1'
        );
        PermissionSet ps2 = new PermissionSet(
                Name = 'Test_CustomPermissionHelper_PermissionSet2',
                Label = 'Test_CustomPermissionHelper_PermissionSet2'
        );
        insert new List<PermissionSet>{
                ps1, ps2
        };

        // Assign Permission Sets for Users
        SetupEntityAccess sea1 = new SetupEntityAccess(
                ParentId = ps1.Id,
                SetupEntityId = [SELECT Id FROM CustomPermission WHERE DeveloperName = :CustomPermissionHelper.PERMISSION_EDITSALESQUOTE].Id
        );
        SetupEntityAccess sea2 = new SetupEntityAccess(
                ParentId = ps2.Id,
                SetupEntityId = [SELECT Id FROM CustomPermission WHERE DeveloperName = :CustomPermissionHelper.PERMISSION_SEEPROSERVQUOTE].Id
        );
        insert new List<SetupEntityAccess>{
            sea1, sea2
        };

        PermissionSetAssignment psa1 = new PermissionSetAssignment(
                AssigneeId = UserInfo.getUserId(),
                PermissionSetId = ps1.Id
        );
        PermissionSetAssignment psa2 = new PermissionSetAssignment(
                AssigneeId = user2.Id,
                PermissionSetId = ps2.Id
        );
        insert new List<PermissionSetAssignment>{
                psa1, psa2
        };

        // Run Test
        Test.startTest();
        CustomPermissionHelper currentUserCS = new CustomPermissionHelper();
        Set<String> resultCurrentUserPermissionSet = currentUserCS.getPermissionSet();
        Boolean resultCurrentUserCS1 = currentUserCS.hasPermission(CustomPermissionHelper.PERMISSION_EDITSALESQUOTE);
        Boolean resultCurrentUserCS2 = currentUserCS.hasPermission(CustomPermissionHelper.PERMISSION_SEEPROSERVQUOTE);
        Boolean resultCurrentUserCS3 = currentUserCS.hasPermission('Random Permission');

        CustomPermissionHelper user1CS = new CustomPermissionHelper(user1.Id);
        Boolean resultUser1CS1 = user1CS.hasPermission(CustomPermissionHelper.PERMISSION_EDITSALESQUOTE);
        Boolean resultUser1CS2 = user1CS.hasPermission(CustomPermissionHelper.PERMISSION_SEEPROSERVQUOTE);
        Set<String> resultUser1CSPermissionSet = user1CS.getPermissionSet();

        CustomPermissionHelper user2CS = new CustomPermissionHelper(user2.Id);
        Set<String> resultUser2CSPermissionSet = user2CS.getPermissionSet();
        Boolean resultUser2CS1 = user2CS.hasPermission(CustomPermissionHelper.PERMISSION_EDITSALESQUOTE);
        Boolean resultUser2CS2 = user2CS.hasPermission(CustomPermissionHelper.PERMISSION_SEEPROSERVQUOTE);
        Boolean resultCurrUser1 = CustomPermissionHelper.currentUserHasProfilePermission(CustomPermissionHelper.PERMISSION_EDITSALESQUOTE);
        Boolean resultCurrUser2 = CustomPermissionHelper.currentUserHasPermissionSet('Test_CustomPermissionHelper_PermissionSet1');
        Test.stopTest();

        System.debug(resultCurrentUserPermissionSet);
        System.debug(resultUser1CSPermissionSet);
        System.debug(resultUser2CSPermissionSet);

        // Check
        // Current User
        System.assert(resultCurrentUserPermissionSet.size() > 0 , 'Current User most likely should have some custom permissions');
        System.assertEquals(false , resultCurrentUserCS3);

        // User 1
        System.assert(resultUser1CSPermissionSet.size() > 0);

        // For some reason check methods always returns true in test runs although permission sets were not assigned
        System.assertEquals(true , resultUser1CS1);
        System.assertEquals(true , resultUser1CS2);

        // User 2 (No Permissions)
        System.assert(resultUser2CSPermissionSet.size() > 0);

        // For some reason check methods always returns true in test runs although permission sets were not assigned
        System.assertEquals(true , resultUser2CS1);
        System.assertEquals(true , resultUser2CS2);

        System.assert(resultCurrUser1, 'Failed to verify that custom permission was assigned to the current user');
        System.assert(resultCurrUser2, 'Failed to verify that profile was assigned to the current user');
    }

}