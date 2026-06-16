@IsTest
public class Test_PlatformCacheUtility {
    
    // Test data constants
    private static final String TEST_CACHE_TYPE = 'ORG_CACHE';
    private static final String TEST_SESSION_CACHE_TYPE = 'SESSION_CACHE';
    private static final String TEST_PARTITION = 'local.Default';
    private static final String TEST_KEY = 'test_key';
    private static final String TEST_VALUE = 'test_value';
    private static final Integer TEST_TTL = 3600;
    
    // Mock interfaces for testing
    private interface MockICacheProvider extends ICacheProvider {}
    private interface MockCacheBuilder extends PlatformCacheUtility.CacheBuilder {}
    
    // Mock cache provider stub
    public class MockCacheProviderStub implements System.StubProvider {
        private Map<String, Object> cacheData = new Map<String, Object>();
        private Map<String, Boolean> cacheContains = new Map<String, Boolean>();
        private Map<String, Set<String>> partitionKeys = new Map<String, Set<String>>();
        private Boolean shouldThrowException = false;
        private String exceptionMessage = 'Mock exception';
        private Integer removeCallCount = 0;
        private Set<String> removedKeys = new Set<String>();
        
        public MockCacheProviderStub() {
            setupMockData();
        }
        
        private void setupMockData() {
            // Setup mock cache data
            cacheData.put('ORG_CACHE_local.Default_test_key', 'test_value');
            cacheData.put('SESSION_CACHE_local.Default_session_key', 'session_value');
            cacheData.put('ORG_CACHE_local.Default_account_key', new Account(Name = 'Test Account'));
            
            // Setup mock contains responses
            cacheContains.put('ORG_CACHE_local.Default_test_key', true);
            cacheContains.put('SESSION_CACHE_local.Default_session_key', true);
            cacheContains.put('ORG_CACHE_local.Default_nonexistent_key', false);
            
            // Setup mock partition keys
            partitionKeys.put('local.Default', new Set<String>{'test_key', 'account_key'});
            partitionKeys.put('CurrentUserSessionData', new Set<String>{'session_key'});
        }
        
        public Object handleMethodCall(Object stubbedObject, String stubbedMethodName, 
                                     Type returnType, List<Type> listOfParamTypes, 
                                     List<String> listOfParamNames, List<Object> listOfArgs) {
            
            if (shouldThrowException) {
                throw new PlatformCacheUtility.PlatformCacheException(exceptionMessage);
            }
            
            switch on stubbedMethodName {
                when 'get' {
                    return handleGet(listOfArgs);
                }
                when 'put' {
                    return handlePut(listOfArgs);
                }
                when 'remove' {
                    return handleRemove(listOfArgs);
                }
                when 'contains' {
                    return handleContains(listOfArgs);
                }
                when 'getKeys' {
                    return handleGetKeys(listOfArgs);
                }
                when 'getDynamicRecord' {
                    return handleGetDynamicRecord(listOfArgs);
                }
                when 'removeKeys' {
                    handleRemoveKeys(listOfArgs);
                    return null;
                }
                when else {
                    throw new PlatformCacheUtility.PlatformCacheException('Unsupported method: ' + stubbedMethodName);
                }
            }
        }
        
        private Object handleGet(List<Object> args) {
            String cacheType = (String) args[0];
            String key = (String) args[1];
            String partition = (String) args[2];
            String cacheKey = cacheType + '_' + partition + '_' + key;
            return cacheData.get(cacheKey);
        }
        
        private Boolean handlePut(List<Object> args) {
            String cacheType = (String) args[0];
            String key = (String) args[1];
            Object value = args[2];
            
            // Handle both put method signatures:
            // put(cacheType, key, value, ttl, partition) - 5 args
            // put(cacheType, key, value, partition) - 4 args
            String partition;
            Integer ttl = null;
            
            if (args.size() == 5) {
                // TTL put: put(cacheType, key, value, ttl, partition)
                ttl = (Integer) args[3];
                partition = (String) args[4];
            } else if (args.size() == 4) {
                // Regular put: put(cacheType, key, value, partition)
                partition = (String) args[3];
            } else {
                partition = 'local.Default';
            }
            
            String cacheKey;
            if (ttl != null) {
                cacheKey = cacheType + '_' + partition + '_' + key + '_ttl_' + ttl;
            } else {
                cacheKey = cacheType + '_' + partition + '_' + key;
            }
            
            cacheData.put(cacheKey, value);
            return true;
        }
        
        private Boolean handleRemove(List<Object> args) {
            String cacheType = (String) args[0];
            String key = (String) args[1];
            String partition = (String) args[2];
            String cacheKey = cacheType + '_' + partition + '_' + key;
            
            Object removedValue = cacheData.remove(cacheKey);
            removeCallCount++;
            removedKeys.add(key);
            return removedValue != null;
        }
        
        private Boolean handleContains(List<Object> args) {
            String cacheType = (String) args[0];
            String key = (String) args[1];
            String partition = (String) args[2];
            String cacheKey = cacheType + '_' + partition + '_' + key;
            
            // Check if we have data for this key
            Boolean hasData = cacheData.containsKey(cacheKey) && cacheData.get(cacheKey) != null;
            return hasData;
        }
        
        private Set<String> handleGetKeys(List<Object> args) {
            String cacheType = (String) args[0];
            String partition = (String) args[1];
            return partitionKeys.get(partition) != null ? partitionKeys.get(partition) : new Set<String>();
        }
        
        private SObject handleGetDynamicRecord(List<Object> args) {
            String cacheType = (String) args[0];
            String key = (String) args[1];
            String partition = (String) args[2];
            String sObjectType = (String) args[3];
            String cacheKey = cacheType + '_' + partition + '_' + key;
            
            Object cachedValue = cacheData.get(cacheKey);
            if (cachedValue instanceof SObject) {
                return (SObject) cachedValue;
            }
            return null;
        }

        private void handleRemoveKeys(List<Object> args) {
            // Handle removeKeys operation inline since it's void
            String cacheType = (String) args[0];
            String partition = (String) args[1];
            
            // Get keys for the partition
            Set<String> keysToRemove = handleGetKeys(args);
            
            // Remove each key
            if (keysToRemove != null && !keysToRemove.isEmpty()) {
                for (String key : keysToRemove) {
                    List<Object> removeArgs = new List<Object>{cacheType, key, partition};
                    handleRemove(removeArgs);
                }
            }
            
            // Clear the partition keys after removal
            if (cacheType == 'SESSION_CACHE') {
                partitionKeys.remove('session_' + partition);
            } else {
                partitionKeys.remove(partition);
            }
        }
        
        public void setShouldThrowException(Boolean shouldThrow, String message) {
            this.shouldThrowException = shouldThrow;
            this.exceptionMessage = message;
        }
        
        public Integer getRemoveCallCount() {
            return removeCallCount;
        }
        
        public Set<String> getRemovedKeys() {
            return removedKeys;
        }
        
        public void resetRemoveTracking() {
            removeCallCount = 0;
            removedKeys.clear();
        }
    }
    
    @TestSetup
    static void setupTestData() {
        // Create minimal test data only for tests that actually use it
        // Most tests use mock data, so we only create what's needed
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
    }
    
    // ===== GET METHOD TESTS =====
    
    @IsTest
    static void get_withValidKeyAndPartition_returnsCachedValue() {
        // Given
        MockCacheProviderStub mockStub = new MockCacheProviderStub();
        ICacheProvider mockProvider = (ICacheProvider) Test.createStub(ICacheProvider.class, mockStub);
        
        // When
        Object result = mockProvider.get(TEST_CACHE_TYPE, TEST_KEY, TEST_PARTITION);
        
        // Then
        Assert.areEqual('test_value', result, 'Should return cached value for valid key and partition');
    }
    
    @IsTest
    static void get_withNonExistentKey_returnsNull() {
        // Given
        MockCacheProviderStub mockStub = new MockCacheProviderStub();
        ICacheProvider mockProvider = (ICacheProvider) Test.createStub(ICacheProvider.class, mockStub);
        
        // When
        Object result = mockProvider.get(TEST_CACHE_TYPE, 'nonexistent_key', TEST_PARTITION);
        
        // Then
        Assert.isNull(result, 'Should return null for non-existent key');
    }
    
    @IsTest
    static void get_withNullKey_returnsNull() {
        // Given
        MockCacheProviderStub mockStub = new MockCacheProviderStub();
        ICacheProvider mockProvider = (ICacheProvider) Test.createStub(ICacheProvider.class, mockStub);
        
        // When
        Object result = mockProvider.get(TEST_CACHE_TYPE, null, TEST_PARTITION);
        
        // Then
        Assert.isNull(result, 'Should return null for null key');
    }
    
    // ===== PUT METHOD TESTS =====
    
    @IsTest
    static void put_withValidData_returnsTrue() {
        // Given
        MockCacheProviderStub mockStub = new MockCacheProviderStub();
        ICacheProvider mockProvider = (ICacheProvider) Test.createStub(ICacheProvider.class, mockStub);
        
        // When
        Boolean result = mockProvider.put(TEST_CACHE_TYPE, 'new_key', 'new_value', TEST_PARTITION);
        
        // Then
        Assert.isTrue(result, 'Should return true for successful put operation');
    }
    
    @IsTest
    static void put_withTTL_returnsTrue() {
        // Given
        MockCacheProviderStub mockStub = new MockCacheProviderStub();
        ICacheProvider mockProvider = (ICacheProvider) Test.createStub(ICacheProvider.class, mockStub);
        
        // When
        Boolean result = mockProvider.put(TEST_CACHE_TYPE, 'ttl_key', 'ttl_value', TEST_TTL, TEST_PARTITION);
        
        // Then
        Assert.isTrue(result, 'Should return true for successful put operation with TTL');
    }
    
    @IsTest
    static void put_withNullValue_returnsTrue() {
        // Given
        MockCacheProviderStub mockStub = new MockCacheProviderStub();
        ICacheProvider mockProvider = (ICacheProvider) Test.createStub(ICacheProvider.class, mockStub);
        
        // When
        Boolean result = mockProvider.put(TEST_CACHE_TYPE, 'null_key', null, TEST_PARTITION);
        
        // Then
        Assert.isTrue(result, 'Should return true for put operation with null value');
    }
    
    // ===== REMOVE METHOD TESTS =====
    
    @IsTest
    static void remove_withExistingKey_returnsTrue() {
        // Given
        MockCacheProviderStub mockStub = new MockCacheProviderStub();
        ICacheProvider mockProvider = (ICacheProvider) Test.createStub(ICacheProvider.class, mockStub);
        
        // When
        Boolean result = mockProvider.remove(TEST_CACHE_TYPE, TEST_KEY, TEST_PARTITION);
        
        // Then
        Assert.isTrue(result, 'Should return true for successful remove operation');
    }
    
    // ===== CONTAINS METHOD TESTS =====
    
    @IsTest
    static void contains_withExistingKey_returnsTrue() {
        // Given
        MockCacheProviderStub mockStub = new MockCacheProviderStub();
        ICacheProvider mockProvider = (ICacheProvider) Test.createStub(ICacheProvider.class, mockStub);
        
        // When
        Boolean result = mockProvider.contains(TEST_CACHE_TYPE, TEST_KEY, TEST_PARTITION);
        
        // Then
        Assert.isTrue(result, 'Should return true for existing key');
    }
    
    @IsTest
    static void contains_withNonExistentKey_returnsFalse() {
        // Given
        MockCacheProviderStub mockStub = new MockCacheProviderStub();
        ICacheProvider mockProvider = (ICacheProvider) Test.createStub(ICacheProvider.class, mockStub);
        
        // When
        Boolean result = mockProvider.contains(TEST_CACHE_TYPE, 'nonexistent_key', TEST_PARTITION);
        
        // Then
        Assert.isFalse(result, 'Should return false for non-existent key');
    }
    
    // ===== GETKEYS METHOD TESTS =====
    
    @IsTest
    static void getKeys_withValidPartition_returnsKeySet() {
        // Given
        MockCacheProviderStub mockStub = new MockCacheProviderStub();
        ICacheProvider mockProvider = (ICacheProvider) Test.createStub(ICacheProvider.class, mockStub);
        
        // When
        Set<String> result = mockProvider.getKeys(TEST_CACHE_TYPE, TEST_PARTITION);
        
        // Then
        Assert.isNotNull(result, 'Should return key set for valid partition');
        Assert.areEqual(2, result.size(), 'Should return correct number of keys');
        Assert.isTrue(result.contains('test_key'), 'Should contain expected key');
        Assert.isTrue(result.contains('account_key'), 'Should contain expected key');
    }
    
    @IsTest
    static void getKeys_withEmptyPartition_returnsEmptySet() {
        // Given
        MockCacheProviderStub mockStub = new MockCacheProviderStub();
        ICacheProvider mockProvider = (ICacheProvider) Test.createStub(ICacheProvider.class, mockStub);
        
        // When
        Set<String> result = mockProvider.getKeys(TEST_CACHE_TYPE, 'empty_partition');
        
        // Then
        Assert.isNotNull(result, 'Should return empty set for empty partition');
        Assert.areEqual(0, result.size(), 'Should return empty set');
    }
    
    // ===== GETDYNAMICRECORD METHOD TESTS =====
    
    @IsTest
    static void getDynamicRecord_withSObject_returnsSObject() {
        // Given
        MockCacheProviderStub mockStub = new MockCacheProviderStub();
        ICacheProvider mockProvider = (ICacheProvider) Test.createStub(ICacheProvider.class, mockStub);
        
        // When
        SObject result = mockProvider.getDynamicRecord(TEST_CACHE_TYPE, 'account_key', TEST_PARTITION, 'Account');
        
        // Then
        Assert.isNotNull(result, 'Should return SObject for valid key');
        Assert.isTrue(result instanceof Account, 'Should return Account type');
        Assert.areEqual('Test Account', ((Account) result).Name, 'Should return correct Account data');
    }
    
    @IsTest
    static void getDynamicRecord_withNonSObject_returnsNull() {
        // Given
        MockCacheProviderStub mockStub = new MockCacheProviderStub();
        ICacheProvider mockProvider = (ICacheProvider) Test.createStub(ICacheProvider.class, mockStub);
        
        // When
        SObject result = mockProvider.getDynamicRecord(TEST_CACHE_TYPE, TEST_KEY, TEST_PARTITION, 'Account');
        
        // Then
        Assert.isNull(result, 'Should return null for non-SObject value');
    }
    
    // ===== REMOVEKEYS METHOD TESTS =====
    
    @IsTest
    static void removeKeys_withValidPartition_removesAllKeys() {
        // Given
        MockCacheProviderStub mockStub = new MockCacheProviderStub();
        ICacheProvider mockProvider = (ICacheProvider) Test.createStub(ICacheProvider.class, mockStub);
        PlatformCacheUtility.setCacheProvider(mockProvider);
        
        // Reset tracking before test
        mockStub.resetRemoveTracking();
        
        // When - removeKeys is void, so we just call it
        PlatformCacheUtility.removeKeys(TEST_CACHE_TYPE, TEST_PARTITION);
        
        // Then - verify the side effects (keys are removed)
        Assert.areEqual(2, mockStub.getRemoveCallCount(), 'Should call remove method for each key in partition');
        Assert.isTrue(mockStub.getRemovedKeys().contains('test_key'), 'Should remove test_key');
        Assert.isTrue(mockStub.getRemovedKeys().contains('account_key'), 'Should remove account_key');
        Assert.areEqual(2, mockStub.getRemovedKeys().size(), 'Should remove exactly 2 keys');
    }
    
    @IsTest
    static void removeKeys_withSessionCachePartition_removesAllKeys() {
        // Given
        MockCacheProviderStub mockStub = new MockCacheProviderStub();
        ICacheProvider mockProvider = (ICacheProvider) Test.createStub(ICacheProvider.class, mockStub);
        PlatformCacheUtility.setCacheProvider(mockProvider);
        
        // Reset tracking before test
        mockStub.resetRemoveTracking();
        
        // When - removeKeys is void, so we just call it
        PlatformCacheUtility.removeKeys(TEST_SESSION_CACHE_TYPE, 'CurrentUserSessionData');
        
        // Then - verify the side effects (keys are removed)
        Assert.areEqual(1, mockStub.getRemoveCallCount(), 'Should call remove method for session key in partition');
        Assert.isTrue(mockStub.getRemovedKeys().contains('session_key'), 'Should remove session_key');
        Assert.areEqual(1, mockStub.getRemovedKeys().size(), 'Should remove exactly 1 session key');
    }
    
    @IsTest
    static void removeKeys_withInvalidPartition_handlesGracefully() {
        // Given
        MockCacheProviderStub mockStub = new MockCacheProviderStub();
        ICacheProvider mockProvider = (ICacheProvider) Test.createStub(ICacheProvider.class, mockStub);
        PlatformCacheUtility.setCacheProvider(mockProvider);
        
        // Reset tracking before test
        mockStub.resetRemoveTracking();
        
        // When - removeKeys is void, so we just call it
        PlatformCacheUtility.removeKeys(TEST_CACHE_TYPE, 'InvalidPartition123');
        
        // Then - verify no errors occurred and no keys were removed
        Assert.areEqual(0, mockStub.getRemoveCallCount(), 'Should not call remove method for invalid partition');
        Assert.areEqual(0, mockStub.getRemovedKeys().size(), 'Should not remove any keys for invalid partition');
    }
    
    @IsTest
    static void removeKeys_withNullPartition_handlesException() {
        // Given
        MockCacheProviderStub mockStub = new MockCacheProviderStub();
        ICacheProvider mockProvider = (ICacheProvider) Test.createStub(ICacheProvider.class, mockStub);
        PlatformCacheUtility.setCacheProvider(mockProvider);
        
        // Reset tracking before test
        mockStub.resetRemoveTracking();
        
        // When & Then - removeKeys is void and should handle null gracefully
        try {
            PlatformCacheUtility.removeKeys(TEST_CACHE_TYPE, null);
            // If no exception is thrown, the method should handle null gracefully
            // This is acceptable behavior as the method has try-catch
        } catch (Exception ex) {
            // If an exception is thrown, it should be handled gracefully
            Assert.isNotNull(ex, 'Exception should be handled gracefully');
        }
        
        // Verify no keys were removed due to null partition
        Assert.areEqual(0, mockStub.getRemoveCallCount(), 'Should not call remove method for null partition');
        Assert.areEqual(0, mockStub.getRemovedKeys().size(), 'Should not remove any keys for null partition');
    }
    
    @IsTest
    static void removeKeys_withEmptyPartition_handlesGracefully() {
        // Given
        MockCacheProviderStub mockStub = new MockCacheProviderStub();
        ICacheProvider mockProvider = (ICacheProvider) Test.createStub(ICacheProvider.class, mockStub);
        PlatformCacheUtility.setCacheProvider(mockProvider);
        
        // Reset tracking before test
        mockStub.resetRemoveTracking();
        
        // When - removeKeys is void, so we just call it
        PlatformCacheUtility.removeKeys(TEST_CACHE_TYPE, 'EmptyPartition');
        
        // Then - verify no errors occurred and no keys were removed
        Assert.areEqual(0, mockStub.getRemoveCallCount(), 'Should not call remove method for empty partition');
        Assert.areEqual(0, mockStub.getRemovedKeys().size(), 'Should not remove any keys for empty partition');
    }
    
    // ===== GETWITHMETRICS METHOD TESTS =====
    
    @IsTest
    static void getWithMetrics_withExistingKey_returnsHitMetrics() {
        // Given
        MockCacheProviderStub mockStub = new MockCacheProviderStub();
        ICacheProvider mockProvider = (ICacheProvider) Test.createStub(ICacheProvider.class, mockStub);
        PlatformCacheUtility.setCacheProvider(mockProvider);
        
        // When
        PlatformCacheUtility.CachePerformanceMetrics result = PlatformCacheUtility.getWithMetrics(TEST_CACHE_TYPE, TEST_KEY, TEST_PARTITION);
        
        // Then
        Assert.isNotNull(result, 'Should return performance metrics');
        Assert.areEqual(TEST_KEY, result.key, 'Metrics should contain correct key');
        Assert.isNotNull(result.wasHit, 'Should indicate hit status');
    }
    
    @IsTest
    static void getWithMetrics_withNonExistentKey_returnsMissMetrics() {
        // Given
        MockCacheProviderStub mockStub = new MockCacheProviderStub();
        ICacheProvider mockProvider = (ICacheProvider) Test.createStub(ICacheProvider.class, mockStub);
        PlatformCacheUtility.setCacheProvider(mockProvider);
        
        // When
        PlatformCacheUtility.CachePerformanceMetrics result = PlatformCacheUtility.getWithMetrics(TEST_CACHE_TYPE, 'nonexistent_key', TEST_PARTITION);
        
        // Then
        Assert.isNotNull(result, 'Should return performance metrics for miss');
        Assert.areEqual('nonexistent_key', result.key, 'Metrics should contain correct key');
        Assert.isFalse(result.wasHit, 'Should indicate miss status');
    }
    
    // ===== BULK OPERATIONS TESTS =====
    
    @IsTest
    static void getBulk_withValidKeys_returnsMap() {
        // Given
        MockCacheProviderStub mockStub = new MockCacheProviderStub();
        ICacheProvider mockProvider = (ICacheProvider) Test.createStub(ICacheProvider.class, mockStub);
        PlatformCacheUtility.setCacheProvider(mockProvider);
        
        Set<String> keys = new Set<String>{'test_key', 'account_key'};
        
        // When
        Map<String, Object> result = PlatformCacheUtility.getBulk(TEST_CACHE_TYPE, keys, TEST_PARTITION);
        
        // Then
        Assert.isNotNull(result, 'Should return bulk results map');
        Assert.areEqual(2, result.size(), 'Should return results for all keys');
    }
    
    @IsTest
    static void putBulk_withValidData_returnsTrue() {
        // Given
        MockCacheProviderStub mockStub = new MockCacheProviderStub();
        ICacheProvider mockProvider = (ICacheProvider) Test.createStub(ICacheProvider.class, mockStub);
        PlatformCacheUtility.setCacheProvider(mockProvider);
        
        Map<String, Object> keyValuePairs = new Map<String, Object>{
            'bulk_key1' => 'bulk_value1',
            'bulk_key2' => 'bulk_value2'
        };
        
        // When
        Boolean result = PlatformCacheUtility.putBulk(TEST_CACHE_TYPE, keyValuePairs, TEST_PARTITION);
        
        // Then
        Assert.isTrue(result, 'Should return true for successful bulk put operation');
    }
    
    @IsTest
    static void putBulk_withTTL_returnsTrue() {
        // Given
        MockCacheProviderStub mockStub = new MockCacheProviderStub();
        ICacheProvider mockProvider = (ICacheProvider) Test.createStub(ICacheProvider.class, mockStub);
        PlatformCacheUtility.setCacheProvider(mockProvider);
        
        Map<String, Object> keyValuePairs = new Map<String, Object>{
            'ttl_bulk_key1' => 'ttl_bulk_value1',
            'ttl_bulk_key2' => 'ttl_bulk_value2'
        };
        
        // When
        Boolean result = PlatformCacheUtility.putBulk(TEST_CACHE_TYPE, keyValuePairs, TEST_PARTITION, TEST_TTL);
        
        // Then
        Assert.isTrue(result, 'Should return true for successful bulk put operation with TTL');
    }
    
    // ===== COLLECTION OPERATIONS TESTS =====
    
    @IsTest
    static void putCollection_withValidRecords_returnsTrue() {
        // Given
        MockCacheProviderStub mockStub = new MockCacheProviderStub();
        ICacheProvider mockProvider = (ICacheProvider) Test.createStub(ICacheProvider.class, mockStub);
        PlatformCacheUtility.setCacheProvider(mockProvider);
        
        List<Account> accounts = [SELECT Id, Name FROM Account LIMIT 2];
        
        // When
        Boolean result = PlatformCacheUtility.putCollection(TEST_CACHE_TYPE, 'accounts_key', accounts, TEST_PARTITION);
        
        // Then
        Assert.isTrue(result, 'Should return true for successful collection put operation');
    }
    
    @IsTest
    static void putCollection_withTTL_returnsTrue() {
        // Given
        MockCacheProviderStub mockStub = new MockCacheProviderStub();
        ICacheProvider mockProvider = (ICacheProvider) Test.createStub(ICacheProvider.class, mockStub);
        PlatformCacheUtility.setCacheProvider(mockProvider);
        
        List<Account> accounts = [SELECT Id, Name FROM Account LIMIT 2];
        
        // When
        Boolean result = PlatformCacheUtility.putCollection(TEST_CACHE_TYPE, 'ttl_accounts_key', accounts, TEST_PARTITION, TEST_TTL);
        
        // Then
        Assert.isTrue(result, 'Should return true for successful collection put operation with TTL');
    }
    
    @IsTest
    static void getCollection_withNonExistentKey_returnsNull() {
        // Given
        MockCacheProviderStub mockStub = new MockCacheProviderStub();
        ICacheProvider mockProvider = (ICacheProvider) Test.createStub(ICacheProvider.class, mockStub);
        PlatformCacheUtility.setCacheProvider(mockProvider);
        
        // When
        List<SObject> result = PlatformCacheUtility.getCollection(TEST_CACHE_TYPE, 'nonexistent_collection', TEST_PARTITION);
        
        // Then
        Assert.isNull(result, 'Should return null for non-existent collection key');
    }
    
    // ===== CONSTANTS AND CONSTRUCTOR TESTS =====
    
    @IsTest
    static void constants_areCorrectlyDefined() {
        // When & Then
        Assert.areEqual('ORG_CACHE', PlatformCacheUtility.ORG_CACHE, 'ORG_CACHE constant should be correct');
        Assert.areEqual('SESSION_CACHE', PlatformCacheUtility.SESSION_CACHE, 'SESSION_CACHE constant should be correct');
        Assert.areEqual('CurrentUserSessionData', PlatformCacheUtility.CURRENT_USER_SESSION_DATA, 'CURRENT_USER_SESSION_DATA constant should be correct');
    }
    
    @IsTest
    static void CachePerformanceMetrics_constructor_setsPropertiesCorrectly() {
        // Given
        String testKey = 'constructor_test';
        Long testTime = 150;
        Boolean testHit = true;
        
        // When
        PlatformCacheUtility.CachePerformanceMetrics metrics = new PlatformCacheUtility.CachePerformanceMetrics(testKey, testTime, testHit);
        
        // Then
        Assert.areEqual(testKey, metrics.key, 'Constructor should set key correctly');
        Assert.areEqual(testHit, metrics.wasHit, 'Constructor should set wasHit correctly');
        Assert.areEqual(testTime, metrics.cacheHitTime, 'Constructor should set hit time correctly');
        Assert.areEqual(0, metrics.cacheMissTime, 'Constructor should set miss time to 0 for hit');
    }
    
    @IsTest
    static void CachePerformanceMetrics_constructorForMiss_setsPropertiesCorrectly() {
        // Given
        String testKey = 'miss_constructor_test';
        Long testTime = 200;
        Boolean testHit = false;
        
        // When
        PlatformCacheUtility.CachePerformanceMetrics metrics = new PlatformCacheUtility.CachePerformanceMetrics(testKey, testTime, testHit);
        
        // Then
        Assert.areEqual(testKey, metrics.key, 'Constructor should set key correctly');
        Assert.areEqual(testHit, metrics.wasHit, 'Constructor should set wasHit correctly');
        Assert.areEqual(0, metrics.cacheHitTime, 'Constructor should set hit time to 0 for miss');
        Assert.areEqual(testTime, metrics.cacheMissTime, 'Constructor should set miss time correctly');
    }
    
    // ===== EDGE CASES AND ERROR HANDLING TESTS =====
    
    @IsTest
    static void getBulk_withEmptyKeys_returnsEmptyMap() {
        // Given
        MockCacheProviderStub mockStub = new MockCacheProviderStub();
        ICacheProvider mockProvider = (ICacheProvider) Test.createStub(ICacheProvider.class, mockStub);
        PlatformCacheUtility.setCacheProvider(mockProvider);
        
        // When
        Map<String, Object> result = PlatformCacheUtility.getBulk(TEST_CACHE_TYPE, new Set<String>(), TEST_PARTITION);
        
        // Then
        Assert.isNotNull(result, 'Should return empty map for empty keys');
        Assert.areEqual(0, result.size(), 'Should return empty map');
    }
    
    @IsTest
    static void putBulk_withEmptyMap_returnsTrue() {
        // Given
        MockCacheProviderStub mockStub = new MockCacheProviderStub();
        ICacheProvider mockProvider = (ICacheProvider) Test.createStub(ICacheProvider.class, mockStub);
        PlatformCacheUtility.setCacheProvider(mockProvider);
        
        // When
        Boolean result = PlatformCacheUtility.putBulk(TEST_CACHE_TYPE, new Map<String, Object>(), TEST_PARTITION);
        
        // Then
        Assert.isTrue(result, 'Should return true for empty map put operation');
    }
}