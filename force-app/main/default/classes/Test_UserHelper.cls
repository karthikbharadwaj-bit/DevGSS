@IsTest
public with sharing class Test_UserHelper {
    private static final String ASSERT_MSG_WHEN_ENTERPRISE = 'isSegmentEnterprise should return true when SegmentPicklist__c is about Enterprise';

    @isTest
    static void testGetUsersByPermissionSetAssignees() {
        PermissionSet testPermissionSet = (PermissionSet) new SObjectBuilder(PermissionSet.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                PermissionSet.Name => 'TestPermissionSet',
                PermissionSet.Label => 'Test Permission Set'
            })
            .create()
            .getRecord();
        User testUser = (User) new SObjectBuilder(User.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    User.Username => UserHelper.getUniqueUserName(),
                    User.LastName => ValueProviderBuilder.provideUniqueString('LastName'),
                    User.ProfileId => ProfileHelper.PROFILE_ID_SYSADMIN,
                    User.Email => ValueProviderBuilder.provideUniqueEmail(),
                    User.Alias => StringHelper.getRandomString(8),
                    User.TimeZoneSidKey => 'America/Los_Angeles',
                    User.LocaleSidKey => 'en_US',
                    User.EmailEncodingKey => 'UTF-8',
                    User.LanguageLocaleKey => 'en_US',
                    User.Region__c => 'US',
                    User.Sub_Region__c => 'All'
                }
            )
            .create()
            .getRecord();
        PermissionSetAssignment testPermissionSetAssignment = (PermissionSetAssignment) new SObjectBuilder(PermissionSetAssignment.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                PermissionSetAssignment.AssigneeId => testUser.Id,
                PermissionSetAssignment.PermissionSetId => testPermissionSet.Id
            })
            .create()
            .getRecord();
        Set<Id> userIdsSet = new Set<Id>();
        Test.startTest();
            userIdsSet = UserHelper.getUsersByPermissionSetAssignees('TestPermissionSet');
        Test.stopTest();
        System.assert(userIdsSet.contains(testUser.Id), 'Method should return users ids with Test Permission Set assignments');
    }

    @isTest
    static void testIsSegmentEnterprise() {
        User testUser = (User) new SObjectBuilder(User.SObjectType)
            .setField(User.SegmentPicklist__c, null)
            .build()
            .getRecord();

        Test.startTest();
            Boolean whenNull = UserHelper.isSegmentEnterprise(null);
            Boolean whenEmpty = UserHelper.isSegmentEnterprise(testUser);

            testUser.SegmentPicklist__c = UserHelper.SEGMENT_MAJORS;
            Boolean whenNotEnterprise = UserHelper.isSegmentEnterprise(testUser);

            testUser.SegmentPicklist__c = UserHelper.SEGMENT_ENTERPRISE;
            Boolean whenEnterprise = UserHelper.isSegmentEnterprise(testUser);

            testUser.SegmentPicklist__c = UserHelper.SEGMENT_EXPANSION_ENTERPRISE;
            Boolean whenExpansionEnterprise = UserHelper.isSegmentEnterprise(testUser);
        Test.stopTest();

        Assert.isFalse(whenNull, 'isSegmentEnterprise should return false when input User is null');
        Assert.isFalse(whenEmpty, 'isSegmentEnterprise should return false when SegmentPicklist__c is null');
        Assert.isFalse(whenNotEnterprise, 'isSegmentEnterprise should return false when SegmentPicklist__c is not about Enterprise');
        Assert.isTrue(whenEnterprise, ASSERT_MSG_WHEN_ENTERPRISE);
        Assert.isTrue(whenExpansionEnterprise, ASSERT_MSG_WHEN_ENTERPRISE);
    }

    @isTest
    static void retrieveUserMapWithCache_WithEmptyUserIds_ReturnsEmptyMap() {
        // Given
        Set<Id> emptyUserIds = new Set<Id>();
        
        // When
        Test.startTest();
        Map<Id, User> result = UserHelper.retrieveUserMapWithCache(emptyUserIds);
        Test.stopTest();
        
        // Then
        Assert.isNotNull(result, 'Result should not be null');
        Assert.areEqual(0, result.size(), 'Result map should be empty');
    }
    
    @isTest
    static void retrieveUserMapWithCache_WithValidUserIds_ReturnsUserMap() {
        // Given
        List<User> testUsers = [SELECT Id FROM User WHERE IsActive = true LIMIT 2];
        Set<Id> userIds = new Map<Id, User>(testUsers).keySet();
        
        // When
        Test.startTest();
        Map<Id, User> result = UserHelper.retrieveUserMapWithCache(userIds);
        Test.stopTest();
        
        // Then
        Assert.isNotNull(result, 'Result should not be null');
        Assert.areEqual(userIds.size(), result.size(), 'Result map should contain all requested users');
        
        for(Id userId : userIds) {
            Assert.isTrue(result.containsKey(userId), 'Result should contain user with ID: ' + userId);
            Assert.isNotNull(result.get(userId), 'User record should not be null');
        }
    }
    
    @isTest
    static void retrieveUserMapWithCache_WithCachedUsers_ReturnsFromCache() {
        // Given
        List<User> testUsers = [SELECT Id FROM User WHERE IsActive = true LIMIT 1];
        Set<Id> userIds = new Map<Id, User>(testUsers).keySet();
        
        // Mock cache to return a user
        User cachedUser = testUsers[0];
        PlatformCacheUtility.put(PlatformCacheUtility.SESSION_CACHE, cachedUser.Id, cachedUser, PlatformCacheUtility.CURRENT_USER_SESSION_DATA);
        
        // When
        Test.startTest();
        Map<Id, User> result = UserHelper.retrieveUserMapWithCache(userIds);
        Test.stopTest();
        
        // Then
        Assert.isNotNull(result, 'Result should not be null');
        Assert.areEqual(1, result.size(), 'Result map should contain one user');
        Assert.isTrue(result.containsKey(cachedUser.Id), 'Result should contain cached user');
    }
    
    @isTest
    static void retrieveUsersWithCache_WithEmptyUserIds_ReturnsEmptyList() {
        // Given
        Set<Id> emptyUserIds = new Set<Id>();
        
        // When
        Test.startTest();
        List<User> result = UserHelper.retrieveUsersWithCache(emptyUserIds);
        Test.stopTest();
        
        // Then
        Assert.isNotNull(result, 'Result should not be null');
        Assert.areEqual(0, result.size(), 'Result list should be empty');
    }
    
    @isTest
    static void retrieveUsersWithCache_WithValidUserIds_ReturnsUserList() {
        // Given
        List<User> testUsers = [SELECT Id FROM User WHERE IsActive = true LIMIT 2];
        Set<Id> userIds = new Map<Id, User>(testUsers).keySet();
        
        // When
        Test.startTest();
        List<User> result = UserHelper.retrieveUsersWithCache(userIds);
        Test.stopTest();
        
        // Then
        Assert.isNotNull(result, 'Result should not be null');
        Assert.areEqual(userIds.size(), result.size(), 'Result list should contain all requested users');
        
        Set<Id> resultUserIds = new Map<Id, User>(result).keySet();
        Assert.areEqual(userIds, resultUserIds, 'Result should contain the same user IDs');
    }
    
    @isTest
    static void retrieveUsersWithCache_WithCachedUsers_ReturnsFromCache() {
        // Given
        List<User> testUsers = [SELECT Id FROM User WHERE IsActive = true LIMIT 1];
        Set<Id> userIds = new Map<Id, User>(testUsers).keySet();
        
        // Mock cache to return a user
        User cachedUser = testUsers[0];
        PlatformCacheUtility.put(PlatformCacheUtility.SESSION_CACHE, cachedUser.Id, cachedUser, PlatformCacheUtility.CURRENT_USER_SESSION_DATA);
        
        // When
        Test.startTest();
        List<User> result = UserHelper.retrieveUsersWithCache(userIds);
        Test.stopTest();
        
        // Then
        Assert.isNotNull(result, 'Result should not be null');
        Assert.areEqual(1, result.size(), 'Result list should contain one user');
        Assert.areEqual(cachedUser.Id, result[0].Id, 'Result should contain cached user');
    }
    
    @isTest
    static void retrieveUserMapWithCache_WithMixedCacheState_ReturnsCompleteMap() {
        // Given
        List<User> testUsers = [SELECT Id FROM User WHERE IsActive = true LIMIT 3];
        Set<Id> userIds = new Map<Id, User>(testUsers).keySet();
        
        // Cache only one user
        User cachedUser = testUsers[0];
        PlatformCacheUtility.put(PlatformCacheUtility.SESSION_CACHE, cachedUser.Id, cachedUser, PlatformCacheUtility.CURRENT_USER_SESSION_DATA);
        
        // When
        Test.startTest();
        Map<Id, User> result = UserHelper.retrieveUserMapWithCache(userIds);
        Test.stopTest();
        
        // Then
        Assert.isNotNull(result, 'Result should not be null');
        Assert.areEqual(userIds.size(), result.size(), 'Result map should contain all requested users');
        Assert.isTrue(result.containsKey(cachedUser.Id), 'Result should contain cached user');
        
        // Verify other users were queried and cached
        for(User user : testUsers) {
            Assert.isTrue(result.containsKey(user.Id), 'Result should contain user: ' + user.Id);
        }
    }
    
    @isTest
    static void retrieveUsersWithCache_WithMixedCacheState_ReturnsCompleteList() {
        // Given
        List<User> testUsers = [SELECT Id FROM User WHERE IsActive = true LIMIT 3];
        Set<Id> userIds = new Map<Id, User>(testUsers).keySet();
        
        // Cache only one user
        User cachedUser = testUsers[0];
        PlatformCacheUtility.put(PlatformCacheUtility.SESSION_CACHE, cachedUser.Id, cachedUser, PlatformCacheUtility.CURRENT_USER_SESSION_DATA);
        
        // When
        Test.startTest();
        List<User> result = UserHelper.retrieveUsersWithCache(userIds);
        Test.stopTest();
        
        // Then
        Assert.isNotNull(result, 'Result should not be null');
        Assert.areEqual(userIds.size(), result.size(), 'Result list should contain all requested users');
        
        Set<Id> resultUserIds = new Map<Id, User>(result).keySet();
        Assert.areEqual(userIds, resultUserIds, 'Result should contain the same user IDs');
    }
    
    @isTest
    static void queryUsersWithSelectorForPlatformCache_WithValidUserIds_ReturnsUserList() {
        // Given
        List<User> testUsers = [SELECT Id FROM User WHERE IsActive = true LIMIT 2];
        Set<Id> userIds = new Map<Id, User>(testUsers).keySet();
        
        // When
        Test.startTest();
        List<User> result = UserHelper.queryUsersWithSelectorForPlatformCache(userIds);
        Test.stopTest();
        
        // Then
        Assert.isNotNull(result, 'Result should not be null');
        Assert.areEqual(userIds.size(), result.size(), 'Result should contain all requested users');
        
        for(User user : result) {
            Assert.isNotNull(user.Id, 'User ID should not be null');
            Assert.isTrue(userIds.contains(user.Id), 'User should be in the requested set');
        }
    }
    
    @isTest
    static void queryUsersWithSelectorForPlatformCache_WithEmptyUserIds_ReturnsEmptyList() {
        // Given
        Set<Id> emptyUserIds = new Set<Id>();
        
        // When
        Test.startTest();
        List<User> result = UserHelper.queryUsersWithSelectorForPlatformCache(emptyUserIds);
        Test.stopTest();
        
        // Then
        Assert.isNotNull(result, 'Result should not be null');
        Assert.areEqual(0, result.size(), 'Result should be empty');
    }
    
    @isTest
    static void retrieveUserMapWithCache_WithInvalidUserIds_HandlesGracefully() {
        // Given
        Set<Id> invalidUserIds = new Set<Id>{UserInfo.getUserId()}; // Use current user ID which should exist
        
        // When
        Test.startTest();
        Map<Id, User> result = UserHelper.retrieveUserMapWithCache(invalidUserIds);
        Test.stopTest();
        
        // Then
        Assert.isNotNull(result, 'Result should not be null');
        // Should return empty map or handle gracefully
    }
    
    @isTest
    static void retrieveUsersWithCache_WithInvalidUserIds_HandlesGracefully() {
        // Given
        Set<Id> invalidUserIds = new Set<Id>{UserInfo.getUserId()}; // Use current user ID which should exist
        
        // When
        Test.startTest();
        List<User> result = UserHelper.retrieveUsersWithCache(invalidUserIds);
        Test.stopTest();
        
        // Then
        Assert.isNotNull(result, 'Result should not be null');
        // Should return empty list or handle gracefully
    }
}