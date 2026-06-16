@IsTest
private class Test_PlatformCacheProvider {
    
    @isTest
    static void testGet_WithValidKey_ReturnsCachedValue() {
        // Given
        PlatformCacheProvider provider = new PlatformCacheProvider();
        String cacheType = PlatformCacheUtility.SESSION_CACHE;
        String key = 'testKey';
        String partition = PlatformCacheUtility.CURRENT_USER_SESSION_DATA;
        String testValue = 'testValue';
        
        // When
        Boolean putResult = provider.put(cacheType, key, testValue, partition);
        Object result = provider.get(cacheType, key, partition);
        
        // Then
        Assert.isTrue(putResult, 'Put operation should succeed');
        Assert.areEqual(testValue, result, 'Retrieved value should match stored value');
    }

    @isTest
    static void testGet_WithNullKey_ThrowsException() {
        // Given
        PlatformCacheProvider provider = new PlatformCacheProvider();
        String cacheType = PlatformCacheUtility.SESSION_CACHE;
        String key = '';
        String partition = PlatformCacheUtility.CURRENT_USER_SESSION_DATA;
        String testValue = 'testValue';
        
        // When
        Object result = provider.get(cacheType, key, partition);
        
        // Then
        Assert.areNotEqual(testValue, result, 'Retrieved value should match stored value');
    }

    @isTest
    static void testGet_WithValidKeyOrgCache_ReturnsCachedValue() {
        // Given
        PlatformCacheProvider provider = new PlatformCacheProvider();
        String cacheType = PlatformCacheUtility.ORG_CACHE;
        String key = 'testKey'; 
        String partition = PlatformCacheUtility.CURRENT_USER_SESSION_DATA;
        String testValue = 'testValue';
        
        // When
        Boolean putResult = provider.put(cacheType, key, testValue, partition);
        Object result = provider.get(cacheType, key, partition);
        
        // Then
        Assert.isTrue(putResult, 'Put operation should succeed');
        Assert.areEqual(testValue, result, 'Retrieved value should match stored value');
    }
    
    @isTest
    static void testPut_WithValidData_ReturnsTrue() {
        // Given
        PlatformCacheProvider provider = new PlatformCacheProvider();
        String cacheType = PlatformCacheUtility.SESSION_CACHE;
        String key = 'testKey';
        String partition = PlatformCacheUtility.CURRENT_USER_SESSION_DATA;
        String testValue = 'testValue';
        
        // When
        Boolean result = provider.put(cacheType, key, testValue, partition);
        
        // Then
        Assert.isTrue(result, 'Put operation should succeed');
    }

    @isTest
    static void testPut_WithNullKey_ThrowsException() {
        // Given
        PlatformCacheProvider provider = new PlatformCacheProvider();
        String cacheType = PlatformCacheUtility.SESSION_CACHE;
        String key = '';
        String partition = PlatformCacheUtility.CURRENT_USER_SESSION_DATA;
        String testValue = 'testValue';
        
        // When
        Boolean result = provider.put(cacheType, key, testValue, partition);
        
        // Then
        Assert.isFalse(result, 'Put operation should not succeed');
    }

    @isTest
    static void testPut_WithValidDataOrgCache_ReturnsTrue() {
        // Given
        PlatformCacheProvider provider = new PlatformCacheProvider();
        String cacheType = PlatformCacheUtility.ORG_CACHE;
        String key = 'testKey';
        String partition = PlatformCacheUtility.CURRENT_USER_SESSION_DATA;
        String testValue = 'testValue';
        
        // When
        Boolean result = provider.put(cacheType, key, testValue, partition);
        
        // Then
        Assert.isTrue(result, 'Put operation should succeed');
    }
    
    @isTest
    static void testPut_WithTTL_ReturnsTrue() { 
        // Given
        PlatformCacheProvider provider = new PlatformCacheProvider();
        String cacheType = PlatformCacheUtility.SESSION_CACHE;
        String key = 'testKeyWithTTL';
        String partition = PlatformCacheUtility.CURRENT_USER_SESSION_DATA;
        String testValue = 'testValue';
        Integer ttlSeconds = 3600;
        
        // When
        Boolean result = provider.put(cacheType, key, testValue, ttlSeconds, partition);
        
        // Then
        Assert.isTrue(result, 'Put operation with TTL should succeed');
    }

    @isTest
    static void testPut_WithTTLOrgCache_ReturnsTrue() {
        // Given
        PlatformCacheProvider provider = new PlatformCacheProvider();
        String cacheType = PlatformCacheUtility.ORG_CACHE;
        String key = 'testKeyWithTTL';
        String partition = PlatformCacheUtility.CURRENT_USER_SESSION_DATA;
        String testValue = 'testValue';
        Integer ttlSeconds = 3600;
        
        // When
        Boolean result = provider.put(cacheType, key, testValue, ttlSeconds, partition);
        
        // Then
        Assert.isTrue(result, 'Put operation with TTL should succeed');
    }

    @isTest
    static void testContains_WithExistingKeyOrgCache_ReturnsTrue() {
        // Given
        PlatformCacheProvider provider = new PlatformCacheProvider();
        String cacheType = PlatformCacheUtility.ORG_CACHE;
        String key = 'testKey';
        String partition = PlatformCacheUtility.CURRENT_USER_SESSION_DATA;
        String testValue = 'testValue';
        
        // When
        provider.put(cacheType, key, testValue, partition);
        Boolean result = provider.contains(cacheType, key, partition);
        
        // Then
        Assert.isTrue(result, 'Contains should return true for existing key');
    }
    
    @isTest
    static void testContains_WithExistingKey_ReturnsTrue() {
        // Given
        PlatformCacheProvider provider = new PlatformCacheProvider();
        String cacheType = PlatformCacheUtility.SESSION_CACHE;
        String key = 'testKey';
        String partition = PlatformCacheUtility.CURRENT_USER_SESSION_DATA;
        String testValue = 'testValue';
        
        // When
        provider.put(cacheType, key, testValue, partition);
        Boolean result = provider.contains(cacheType, key, partition);
        
        // Then
        Assert.isTrue(result, 'Contains should return true for existing key');
    }

    @isTest
    static void testContains_WithNullKey_ThrowsException() {
        // Given
        PlatformCacheProvider provider = new PlatformCacheProvider();
        String cacheType = PlatformCacheUtility.SESSION_CACHE;
        String key = '';
        String partition = PlatformCacheUtility.CURRENT_USER_SESSION_DATA;
        String testValue = 'testValue';
        
        // When
        Boolean result = provider.contains(cacheType, key, partition);
        
        // Then
        Assert.isFalse(result, 'Contains should not return true for existing key');
    }
    
    @isTest
    static void testContains_WithNonExistingKey_ReturnsFalse() {
        // Given
        PlatformCacheProvider provider = new PlatformCacheProvider();
        String cacheType = PlatformCacheUtility.SESSION_CACHE;
        String key = 'nonExistentKey';
        String partition = PlatformCacheUtility.CURRENT_USER_SESSION_DATA;
        
        // When
        Boolean result = provider.contains(cacheType, key, partition);
        
        // Then
        Assert.isFalse(result, 'Contains should return false for non-existing key');
    }

    @isTest
    static void testContains_WithNonExistingKeyOrgCache_ReturnsFalse() {
        // Given
        PlatformCacheProvider provider = new PlatformCacheProvider();
        String cacheType = PlatformCacheUtility.ORG_CACHE;
        String key = 'nonExistentKey';
        String partition = PlatformCacheUtility.CURRENT_USER_SESSION_DATA;
        
        // When
        Boolean result = provider.contains(cacheType, key, partition);
        
        // Then
        Assert.isFalse(result, 'Contains should return false for non-existing key');
    }
    
    @isTest
    static void testRemove_WithExistingKey_ReturnsTrue() {
        // Given
        PlatformCacheProvider provider = new PlatformCacheProvider();
        String cacheType = PlatformCacheUtility.SESSION_CACHE;
        String key = 'testKey';
        String partition = PlatformCacheUtility.CURRENT_USER_SESSION_DATA;
        String testValue = 'testValue';
        
        // When
        provider.put(cacheType, key, testValue, partition);
        Boolean result = provider.remove(cacheType, key, partition);
        
        // Then
        Assert.isTrue(result, 'Remove operation should succeed');
    }

    @isTest
    static void testRemove_WithNullKey_ThrowsException() {
        // Given
        PlatformCacheProvider provider = new PlatformCacheProvider();
        String cacheType = PlatformCacheUtility.SESSION_CACHE;
        String key = '';
        String partition = PlatformCacheUtility.CURRENT_USER_SESSION_DATA;
        String testValue = 'testValue';
        
        // When
        Boolean result = provider.remove(cacheType, key, partition);
        
        // Then
        Assert.isFalse(result, 'Remove operation should not succeed');
    }

    @isTest
    static void testRemove_WithExistingKeyOrgCache_ReturnsTrue() {
        // Given
        PlatformCacheProvider provider = new PlatformCacheProvider();
        String cacheType = PlatformCacheUtility.ORG_CACHE;
        String key = 'testKey';
        String partition = PlatformCacheUtility.CURRENT_USER_SESSION_DATA;
        String testValue = 'testValue';
        
        // When
        provider.put(cacheType, key, testValue, partition);
        Boolean result = provider.remove(cacheType, key, partition);
        
        // Then
        Assert.isTrue(result, 'Remove operation should succeed');
    }
    
    @isTest
    static void testGet_WithNonExistingKey_ReturnsNull() {
        // Given
        PlatformCacheProvider provider = new PlatformCacheProvider();
        String cacheType = PlatformCacheUtility.SESSION_CACHE;
        String key = 'nonExistentKey';
        String partition = PlatformCacheUtility.CURRENT_USER_SESSION_DATA;
        
        // When
        Object result = provider.get(cacheType, key, partition);
        
        // Then
        Assert.areEqual(null, result, 'Get should return null for non-existing key');
    }
    
    @isTest
    static void testGet_WithNonExistingKeyOrgCache_ReturnsNull() {
        // Given
        PlatformCacheProvider provider = new PlatformCacheProvider();
        String cacheType = PlatformCacheUtility.ORG_CACHE;
        String key = 'nonExistentKey';
        String partition = PlatformCacheUtility.CURRENT_USER_SESSION_DATA;
        
        // When
        Object result = provider.get(cacheType, key, partition);
        
        // Then
        Assert.areEqual(null, result, 'Get should return null for non-existing key');
    }

    @isTest
    static void testSessionCache_WithValidData_WorksCorrectly() {
        // Given
        PlatformCacheProvider provider = new PlatformCacheProvider();
        String cacheType = 'SESSION_CACHE';
        String key = 'sessionTestKey';
        String partition = PlatformCacheUtility.CURRENT_USER_SESSION_DATA;
        String testValue = 'sessionTestValue';
        
        // When
        Boolean putResult = provider.put(cacheType, key, testValue, partition);
        Object getResult = provider.get(cacheType, key, partition);
        Boolean containsResult = provider.contains(cacheType, key, partition);
        
        // Then
        Assert.isTrue(putResult, 'Session cache put should succeed');
        Assert.areEqual(testValue, getResult, 'Session cache get should return correct value');
        Assert.isTrue(containsResult, 'Session cache contains should return true');
    }

    @isTest
    static void testSessionCache_WithValidDataOrgCache_WorksCorrectly() {
        // Given
        PlatformCacheProvider provider = new PlatformCacheProvider();
        String cacheType = PlatformCacheUtility.ORG_CACHE;
        String key = 'sessionTestKey';
        String partition = PlatformCacheUtility.CURRENT_USER_SESSION_DATA;
        String testValue = 'sessionTestValue';
        
        // When
        Boolean putResult = provider.put(cacheType, key, testValue, partition);
        Object getResult = provider.get(cacheType, key, partition);
        Boolean containsResult = provider.contains(cacheType, key, partition);
        
        // Then
        Assert.isTrue(putResult, 'Session cache put should succeed');
        Assert.areEqual(testValue, getResult, 'Session cache get should return correct value');
        Assert.isTrue(containsResult, 'Session cache contains should return true');
    }
    
    @isTest
    static void testGetDynamicRecord_WithSObject_ReturnsSObject() {
        // Given
        PlatformCacheProvider provider = new PlatformCacheProvider();
        String cacheType = PlatformCacheUtility.SESSION_CACHE;
        String key = 'sobjectTestKey';
        String partition = PlatformCacheUtility.CURRENT_USER_SESSION_DATA;
        
        Account testAccount = new Account(Name = 'Test Account');
        
        // When
        provider.put(cacheType, key, testAccount, partition);
        SObject result = provider.getDynamicRecord(cacheType, key, partition, 'Account');
        
        // Then
        Assert.isNotNull(result, 'Dynamic record should not be null');
        Assert.areEqual('Account', result.getSObjectType().getDescribe().getName(), 'Should return Account SObject');
    }
    
    @isTest
    static void testGetDynamicRecord_WithSObjectOrgCache_ReturnsSObject() {
        // Given
        PlatformCacheProvider provider = new PlatformCacheProvider();
        String cacheType = PlatformCacheUtility.ORG_CACHE;
        String key = 'sobjectTestKey';
        String partition = PlatformCacheUtility.CURRENT_USER_SESSION_DATA;
        
        Account testAccount = new Account(Name = 'Test Account');
        
        // When
        provider.put(cacheType, key, testAccount, partition);
        SObject result = provider.getDynamicRecord(cacheType, key, partition, 'Account');
        
        // Then
        Assert.isNotNull(result, 'Dynamic record should not be null');
        Assert.areEqual('Account', result.getSObjectType().getDescribe().getName(), 'Should return Account SObject');
    }

    @isTest
    static void testGetDynamicRecord_WithString_ReturnsSObject() {
        // Given
        PlatformCacheProvider provider = new PlatformCacheProvider();
        String cacheType = PlatformCacheUtility.ORG_CACHE;
        String key = 'sobjectTestKey';
        String partition = PlatformCacheUtility.CURRENT_USER_SESSION_DATA;
        Account testAccount = new Account(Name = 'Test Account');
        String testValue = JSON.serialize(testAccount);
        
        // When
        provider.put(cacheType, key, testValue, partition);
        SObject result = provider.getDynamicRecord(cacheType, key, partition, 'Account');
        
        // Then
        Assert.isNotNull(result, 'Dynamic record should not be null');
        Assert.areEqual('Account', result.getSObjectType().getDescribe().getName(), 'Should return Account SObject');
    }

    @isTest
    static void testGetDynamicRecord_WithNonExistingKeyOrgCache_ReturnsNull() {
        // Given
        PlatformCacheProvider provider = new PlatformCacheProvider();
        String cacheType = PlatformCacheUtility.ORG_CACHE;
        String key = 'nonExistentKey';
        String partition = PlatformCacheUtility.CURRENT_USER_SESSION_DATA;
        
        // When
        SObject result = provider.getDynamicRecord(cacheType, key, partition, 'Account');
        
        // Then
        Assert.areEqual(null, result, 'Dynamic record should be null for non-existing key');
    }

    @isTest
    static void testGetDynamicRecord_WithNonExistingKey_ReturnsNull() {
        // Given
        PlatformCacheProvider provider = new PlatformCacheProvider();
        String cacheType = PlatformCacheUtility.SESSION_CACHE;
        String key = 'nonExistentKey';
        String partition = PlatformCacheUtility.CURRENT_USER_SESSION_DATA;
        
        // When
        SObject result = provider.getDynamicRecord(cacheType, key, partition, 'Account');
        
        // Then
        Assert.areEqual(null, result, 'Dynamic record should be null for non-existing key');
    }

    @isTest
    static void testGetKeys_WithValidPartition_ReturnsKeys() {
        // Given
        PlatformCacheProvider provider = new PlatformCacheProvider();
        String cacheType = PlatformCacheUtility.SESSION_CACHE;
        String partition = PlatformCacheUtility.CURRENT_USER_SESSION_DATA;
        String key1 = 'key1';
        String key2 = 'key2';
        String testValue = 'testValue';
        
        // When
        provider.put(cacheType, key1, testValue, partition);
        provider.put(cacheType, key2, testValue, partition);
        Set<String> keys = provider.getKeys(cacheType, partition);
        
        // Then
        Assert.isNotNull(keys, 'Keys set should not be null');
        Assert.isTrue(keys.size() >= 2, 'Should contain at least 2 keys');
    }

    @isTest
    static void testGetKeys_WithValidPartitionOrgCache_ReturnsKeys() {
        // Given
        PlatformCacheProvider provider = new PlatformCacheProvider();
        String cacheType = PlatformCacheUtility.ORG_CACHE;
        String partition = PlatformCacheUtility.CURRENT_USER_SESSION_DATA;
        String key1 = 'key1';
        String key2 = 'key2';
        String testValue = 'testValue';
        
        // When
        provider.put(cacheType, key1, testValue, partition);
        provider.put(cacheType, key2, testValue, partition);
        Set<String> keys = provider.getKeys(cacheType, partition);
        
        // Then
        Assert.isNotNull(keys, 'Keys set should not be null');
        Assert.isTrue(keys.size() >= 2, 'Should contain at least 2 keys');
    }
    
    @isTest
    static void testRemoveKeys_WithValidPartition_RemovesAllKeys() {
        // Given
        PlatformCacheProvider provider = new PlatformCacheProvider();
        String cacheType = PlatformCacheUtility.SESSION_CACHE;
        String partition = PlatformCacheUtility.CURRENT_USER_SESSION_DATA;
        String key1 = 'key1';
        String key2 = 'key2';
        String testValue = 'testValue';
        
        // When
        provider.put(cacheType, key1, testValue, partition);
        provider.put(cacheType, key2, testValue, partition);
        provider.removeKeys(cacheType, partition);
        
        // Then
        Assert.isFalse(provider.contains(cacheType, key1, partition), 'Key1 should be removed');
        Assert.isFalse(provider.contains(cacheType, key2, partition), 'Key2 should be removed');
    }

    @isTest
    static void testRemoveKeys_WithValidPartitionOrgCache_RemovesAllKeys() {
        // Given
        PlatformCacheProvider provider = new PlatformCacheProvider();
        String cacheType = PlatformCacheUtility.ORG_CACHE;
        String partition = PlatformCacheUtility.CURRENT_USER_SESSION_DATA;
        String key1 = 'key1';
        String key2 = 'key2';
        String testValue = 'testValue';

        // When
        provider.put(cacheType, key1, testValue, partition);
        provider.put(cacheType, key2, testValue, partition);
        provider.removeKeys(cacheType, partition);
        
        // Then
        Assert.isFalse(provider.contains(cacheType, key1, partition), 'Key1 should be removed');
        Assert.isFalse(provider.contains(cacheType, key2, partition), 'Key2 should be removed');
    }

    @isTest
    static void testRemoveKeys_WithNullSet_RemovesAllKeys() {
        // Given
        PlatformCacheProvider provider = new PlatformCacheProvider();
        String cacheType = PlatformCacheUtility.ORG_CACHE;
        String partition = PlatformCacheUtility.CURRENT_USER_SESSION_DATA;

        // When
        provider.removeKeys(cacheType, null);
        
        // Then
        Assert.areEqual(0, provider.getKeys(cacheType, partition).size(), 'Should return 0 keys');
    }
}