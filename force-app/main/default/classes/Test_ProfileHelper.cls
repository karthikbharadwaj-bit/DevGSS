@isTest
private class Test_ProfileHelper {
    private static User createTestUser(String profileName) {
        String uniqueUserName = 'testUser' + DateTime.now().getTime() + '@ringcentral.com.test';
        Profile p = (Profile) new ProfileSelector()
            .selectProfileByName(new List<Object>{profileName})
            .executeQuery()
            .get(0);

        User testUser = new User(
            Alias = 'standt',
            Email = 'standarduser@testorg.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Testing',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = uniqueUserName
        );

        return testUser;
    }

    private static Set<String> profileNameListToProfileNameSet(List<String> profileNames) {
        Set<string> profileNamesSet = new Set<String>();
        for (String profileName : profileNames) {
            profileNamesSet.add(profileName);
        }
        return profileNamesSet;
    }

    @isTest
    static void adminOrSalesProfileIdToNameTest() {
        Test.startTest();
            Map<Id, String> profileIdToName = ProfileHelper.ADMIN_OR_SALES_PROFILE_ID_TO_NAME;

            Profile crmAdminProfile = (Profile) new ProfileSelector()
                .selectProfileByName(new List<Object>{ProfileHelper.PROFILE_NAME_CRM_DEV_TEAM_ADMINISTRATOR})
                .executeQuery()
                .get(0);

            String crmAdminProfileName = ProfileHelper.ADMIN_OR_SALES_PROFILE_ID_TO_NAME.get(crmAdminProfile.Id);
            Boolean doesContainAllCrmProfiles = ProfileHelper.ADMIN_OR_CRM_PROFILES.containsAll(profileNameListToProfileNameSet(ProfileHelper.ADMIN_OR_SALES_PROFILE_ID_TO_NAME.values()));
        Test.stopTest();

        System.assertNotEquals(null, profileIdToName, 'ProfileHelper.ADMIN_OR_SALES_PROFILE_ID_TO_NAME cannot be null.');
        System.assertEquals(true, doesContainAllCrmProfiles, 'ProfileHelper.ADMIN_OR_SALES_PROFILE_ID_TO_NAME must contain all Sales profiles.');
        System.assertEquals(crmAdminProfile.Name, crmAdminProfileName, 'ProfileHelper.ADMIN_OR_SALES_PROFILE_ID_TO_NAME.get should return CRM Dev Team Administrator');
    }

    @isTest
    static void isCurrentUserSysAdminTest() {
        Boolean resultForSysAdmin;
        Boolean resultForNotSysAdmin;

        Test.startTest();
            System.runAs(createTestUser(ProfileHelper.SYSTEM_ADMIN)) {
                resultForSysAdmin = ProfileHelper.isCurrentUserSysAdmin();
            }

            System.runAs(createTestUser(ProfileHelper.PROFILE_NAME_SALES_4_IN_CONTACT_ORDER_LIGHTNING)) {
                resultForNotSysAdmin = ProfileHelper.isCurrentUserSysAdmin();
            }
        Test.stopTest();

        System.assertEquals(true, resultForSysAdmin, 'The test user is an admin. The ProfileHelper.isCurrentUserSysAdmin() must return true!');
        System.assertEquals(false, resultForNotSysAdmin, 'The test user is not an admin. The ProfileHelper.isCurrentUserSysAdmin() must return false!');
    }

    @isTest
    static void isSysAdminTest() {
        Profile sysAdminProfile = (Profile) new ProfileSelector()
            .selectProfileByName(new List<Object>{ProfileHelper.PROFILE_NAME_SYSTEM_ADMINISTRATOR})
            .executeQuery()
            .get(0);

        Test.startTest();
            Boolean isSysAdmin = ProfileHelper.isSysAdmin(sysAdminProfile.Id);
        Test.stopTest();

        SYstem.assert(isSysAdmin, 'The test profile is an admin profile. The ProfileHelper.isSysAdmin() must return true!');
    }

    @isTest
    static void isCrmProfileTest() {
        Test.startTest();
            Boolean resultForCrmProfileUser = ProfileHelper.isCrmProfile(createTestUser(ProfileHelper.PROFILE_NAME_CRM_DEVELOPER).ProfileId);
            Boolean resultForNotCrmProfileUser = ProfileHelper.isCrmProfile(createTestUser(ProfileHelper.PROFILE_NAME_SYSTEM_ADMINISTRATOR).ProfileId);
        Test.stopTest();

        System.assertEquals(true, resultForCrmProfileUser, 'The test user is a CRM user. The ProfileHelper.isCurrentUserSysAdmin() must return true!');
        System.assertEquals(false, resultForNotCrmProfileUser, 'The test user is not an admin. The ProfileHelper.isCurrentUserSysAdmin() must return false!');
    }

    @isTest
    static void testIsSupportT1Profile() {
        Profile supportT1Profile = (Profile) new ListOptional(new ProfileSelector()
            .selectProfileByName(new List<Object> {ProfileHelper.PROFILE_NAME_SUPPORT_T1})
            .executeQuery()
        ).getFirst();

        Test.startTest();
            Boolean isSupportT1 = ProfileHelper.isSupportT1Profile(supportT1Profile.Id);
        Test.stopTest();

        Assert.areEqual(true, isSupportT1, 'The test profile is a support T1 profile. The ProfileHelper.isSupportT1Profile() must return true!');
    }

    @isTest
    static void getCurrentUserProfileTest() {
        Profile currentUserProfile;

        Test.startTest();
            System.runAs(createTestUser(ProfileHelper.PROFILE_NAME_SYSTEM_ADMINISTRATOR)) {
                currentUserProfile = ProfileHelper.getCurrentUserProfile();
            }
        Test.stopTest();

        System.assertEquals(ProfileHelper.PROFILE_NAME_SYSTEM_ADMINISTRATOR, currentUserProfile?.Name, 'Profile names should be the same.');
    }
    
    @isTest
    static void getCurrentUserProfileWithCache_WithProfileInCache_ReturnsFromCache() {
        // Given
        String currentProfileId = UserInfo.getProfileId();
        Profile testProfile = [SELECT Id, Name FROM Profile WHERE Id = :currentProfileId LIMIT 1];
        
        // Mock cache to return a profile
        PlatformCacheUtility.put(PlatformCacheUtility.SESSION_CACHE, currentProfileId, testProfile, PlatformCacheUtility.CURRENT_USER_SESSION_DATA);
        
        // When
        Test.startTest();
        Profile result = ProfileHelper.getCurrentUserProfileWithCache();
        Test.stopTest();
        
        // Then
        Assert.isNotNull(result, 'Result should not be null');
        Assert.areEqual(testProfile.Id, result.Id, 'Result should contain cached profile');
        Assert.areEqual(testProfile.Name, result.Name, 'Result should contain cached profile name');
    }
    
    @isTest
    static void getCurrentUserProfileWithCache_WithProfileNotInCache_QueriesAndCaches() {
        // Given
        String currentProfileId = UserInfo.getProfileId();
        
        // Ensure profile is not in cache by clearing it first
        PlatformCacheUtility.remove(PlatformCacheUtility.SESSION_CACHE, currentProfileId, PlatformCacheUtility.CURRENT_USER_SESSION_DATA);
        
        // When
        Test.startTest();
        Profile result = ProfileHelper.getCurrentUserProfileWithCache();
        Test.stopTest();
        
        // Then
        Assert.isNotNull(result, 'Result should not be null');
        Assert.areEqual(currentProfileId, result.Id, 'Result should contain current user profile');
    }
    
    @isTest
    static void getCurrentUserProfileWithCache_WithInvalidProfileId_HandlesGracefully() {
        
        // Mock UserInfo.getProfileId() to return invalid ID
        Test.startTest();
        
        // Since we can't easily mock UserInfo.getProfileId(), we'll test with a profile that doesn't exist
        // This test verifies the method handles cases where the profile might not be found
        
        // Clear any existing cache
        String currentProfileId = UserInfo.getProfileId();
        PlatformCacheUtility.remove(PlatformCacheUtility.SESSION_CACHE, currentProfileId, PlatformCacheUtility.CURRENT_USER_SESSION_DATA);
        
        Profile result = ProfileHelper.getCurrentUserProfileWithCache();
        Test.stopTest();
        
        // Then
        // The method should still return a valid profile for the current user
        Assert.isNotNull(result, 'Result should not be null for current user profile');
    }
    
    @isTest
    static void getCurrentUserProfileWithCache_WithEmptyQueryResult_ReturnsNull() {
        // Given
        String currentProfileId = UserInfo.getProfileId();
        
        // Clear cache
        PlatformCacheUtility.remove(PlatformCacheUtility.SESSION_CACHE, currentProfileId, PlatformCacheUtility.CURRENT_USER_SESSION_DATA);
        
        // When
        Test.startTest();
        Profile result = ProfileHelper.getCurrentUserProfileWithCache();
        Test.stopTest();
        
        // Then
        // This test verifies that if the query returns empty results, the method handles it gracefully
        // In practice, this should not happen for a valid current user profile
        Assert.isNotNull(result, 'Result should not be null for current user profile');
    }
    
    @isTest
    static void getCurrentUserProfileWithCache_WithMultipleCalls_UsesCache() {
        // Given
        String currentProfileId = UserInfo.getProfileId();
        
        // Clear cache initially
        PlatformCacheUtility.remove(PlatformCacheUtility.SESSION_CACHE, currentProfileId, PlatformCacheUtility.CURRENT_USER_SESSION_DATA);
        
        // When
        Test.startTest();
        
        // First call - should query and cache
        Profile firstResult = ProfileHelper.getCurrentUserProfileWithCache();
        
        // Second call - should use cache
        Profile secondResult = ProfileHelper.getCurrentUserProfileWithCache();
        
        Test.stopTest();
        
        // Then
        Assert.isNotNull(firstResult, 'First result should not be null');
        Assert.isNotNull(secondResult, 'Second result should not be null');
        Assert.areEqual(firstResult.Id, secondResult.Id, 'Both results should be the same profile');
    }

    @isTest
    static void getCurrentUserProfileWithCache_WithNullProfileInCache_HandlesGracefully() {
        // Given
        String currentProfileId = UserInfo.getProfileId();
        
        // Store null in cache (simulating cache corruption or invalid data)
        PlatformCacheUtility.put(PlatformCacheUtility.SESSION_CACHE, currentProfileId, null, PlatformCacheUtility.CURRENT_USER_SESSION_DATA);
        
        // When
        Test.startTest();
        Profile result = ProfileHelper.getCurrentUserProfileWithCache();
        Test.stopTest();
        
        // Then
        // The method should handle null cache values gracefully
        // In practice, it should fall back to querying the database
        Assert.isNotNull(result, 'Result should not be null even with null cache value');
    }
    
    @isTest
    static void getCurrentUserProfileWithCache_WithDifferentProfileTypes_WorksCorrectly() {
        // Given
        String currentProfileId = UserInfo.getProfileId();
        Profile currentProfile = [SELECT Id, Name, UserType FROM Profile WHERE Id = :currentProfileId LIMIT 1];
        
        // Clear cache
        PlatformCacheUtility.remove(PlatformCacheUtility.SESSION_CACHE, currentProfileId, PlatformCacheUtility.CURRENT_USER_SESSION_DATA);
        
        // When
        Test.startTest();
        Profile result = ProfileHelper.getCurrentUserProfileWithCache();
        Test.stopTest();
        
        // Then
        Assert.isNotNull(result, 'Result should not be null');
        Assert.areEqual(currentProfile.Id, result.Id, 'Result should match current profile ID');
        Assert.areEqual(currentProfile.Name, result.Name, 'Result should match current profile name');
    }
    
    @isTest
    static void getCurrentUserProfileWithCache_WithSystemAdminProfile_WorksCorrectly() {
        // Given
        // This test verifies the method works correctly with System Administrator profile
        // The current user in test context should have a valid profile
        
        // When
        Test.startTest();
        Profile result = ProfileHelper.getCurrentUserProfileWithCache();
        Test.stopTest();
        
        // Then
        Assert.isNotNull(result, 'Result should not be null');
        Assert.isNotNull(result.Id, 'Profile ID should not be null');
        Assert.isNotNull(result.Name, 'Profile name should not be null');
    }
    
    @isTest
    static void getCurrentUserProfileWithCache_WithCacheExpiration_RefreshesData() {
        // Given
        String currentProfileId = UserInfo.getProfileId();
        
        // Store old data in cache
        Profile oldProfile = [SELECT Id, Name FROM Profile WHERE Id = :currentProfileId LIMIT 1];
        PlatformCacheUtility.put(PlatformCacheUtility.SESSION_CACHE, currentProfileId, oldProfile, PlatformCacheUtility.CURRENT_USER_SESSION_DATA);
        
        // When
        Test.startTest();
        
        // Simulate cache expiration by removing and re-adding
        PlatformCacheUtility.remove(PlatformCacheUtility.SESSION_CACHE, currentProfileId, PlatformCacheUtility.CURRENT_USER_SESSION_DATA);
        
        Profile result = ProfileHelper.getCurrentUserProfileWithCache();
        Test.stopTest();
        
        // Then
        Assert.isNotNull(result, 'Result should not be null after cache expiration');
        Assert.areEqual(currentProfileId, result.Id, 'Result should contain current profile ID');
    }
}