@IsTest
private class Test_BulkCacheOperations {
    
    // Mock exception class for testing
    private class MockException extends Exception {}
    
    // Mock cache builder for testing
    private class MockCacheBuilder implements ICacheBuilder {
        private Map<String, Object> buildData = new Map<String, Object>();
        
        public MockCacheBuilder() {
            setupBuildData();
        }
        
        private void setupBuildData() {
            buildData.put('key1', 'built_value_1');
            buildData.put('key2', 'built_value_2');
            buildData.put('key3', new Map<String, Object>{'nested' => 'data'});
        }
        
        public Object buildValue(String key) {
            return buildData.get(key);
        }
    }
    
    // StubProvider implementation for ICacheProvider
    private class MockCacheProviderStub implements System.StubProvider {
        private Map<String, Object> cacheData = new Map<String, Object>();
        private Map<String, Set<String>> partitionKeys = new Map<String, Set<String>>();
        private Boolean shouldThrowException = false;
        private String exceptionMessage = 'Mock exception';
        private Map<String, Boolean> operationResults = new Map<String, Boolean>();
        
        public MockCacheProviderStub() {
            setupTestData();
        }
        
        public MockCacheProviderStub(Boolean shouldThrowException, String exceptionMessage) {
            this.shouldThrowException = shouldThrowException;
            this.exceptionMessage = exceptionMessage;
            if (!shouldThrowException) {
                setupTestData();
            }
        }
        
        public MockCacheProviderStub(Map<String, Boolean> operationResults) {
            this.operationResults = operationResults;
            setupTestData();
        }
        
        private void setupTestData() {
            // Setup test data for different partitions
            String partition1 = 'test_partition_1';
            String partition2 = 'test_partition_2';
            
            // Add test keys and values
            putToCache('ORG_CACHE', 'key1', 'value1', partition1);
            putToCache('ORG_CACHE', 'key2', 'value2', partition1);
            putToCache('SESSION_CACHE', 'key3', 'value3', partition1);
            putToCache('ORG_CACHE', 'key4', 'large_value_that_is_quite_long_for_testing_purposes', partition2);
            putToCache('SESSION_CACHE', 'key5', new Map<String, Object>{'nested' => 'data'}, partition2);
            
            // Add some SObject collections for testing
            List<Account> accounts = new List<Account>{
                new Account(Name = 'Test Account 1'),
                new Account(Name = 'Test Account 2')
            };
            putToCache('ORG_CACHE', 'accounts_key', accounts, partition1);
            
            List<Contact> contacts = new List<Contact>{
                new Contact(FirstName = 'John', LastName = 'Doe'),
                new Contact(FirstName = 'Jane', LastName = 'Smith')
            };
            putToCache('SESSION_CACHE', 'contacts_key', contacts, partition1);
        }
        
        private void putToCache(String cacheType, String key, Object value, String partition) {
            String cacheKey = cacheType + '_' + partition + '_' + key;
            cacheData.put(cacheKey, value);
            
            if (!partitionKeys.containsKey(partition)) {
                partitionKeys.put(partition, new Set<String>());
            }
            partitionKeys.get(partition).add(key);
        }
        
        public Object handleMethodCall(Object stubbedObject, String stubbedMethodName, 
                                     Type returnType, List<Type> listOfParamTypes, 
                                     List<String> listOfParamNames, List<Object> listOfArgs) {
            
            if (shouldThrowException) {
                throw new MockException(exceptionMessage);
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
                when else {
                    throw new MockException('Unsupported method: ' + stubbedMethodName);
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
        
        private Object handlePut(List<Object> args) {
            String cacheType = (String) args[0];
            String key = (String) args[1];
            Object value = args[2];
            
            // Handle both put method signatures
            String partition;
            Integer ttlSeconds = null;
            
            if (args.size() == 4) {
                // put(String cacheType, String key, Object value, String partition)
                partition = (String) args[3];
            } else if (args.size() == 5) {
                // put(String cacheType, String key, Object value, Integer ttlSeconds, String partition)
                Object ttlArg = args[3];
                if (ttlArg instanceof Integer) {
                    ttlSeconds = (Integer) ttlArg;
                }
                partition = (String) args[4];
            } else {
                throw new MockException('Invalid number of arguments for put method: ' + args.size());
            }
            
            // Check if we have a specific result for this operation
            String operationKey = cacheType + '_' + key + '_' + partition;
            if (operationResults.containsKey(operationKey)) {
                return operationResults.get(operationKey);
            }
            
            putToCache(cacheType, key, value, partition);
            return true;
        }
        
        private Object handleRemove(List<Object> args) {
            String cacheType = (String) args[0];
            String key = (String) args[1];
            String partition = (String) args[2];
            String cacheKey = cacheType + '_' + partition + '_' + key;
            
            Object removedValue = cacheData.remove(cacheKey);
            if (partitionKeys.containsKey(partition)) {
                partitionKeys.get(partition).remove(key);
            }
            
            return removedValue != null;
        }
        
        private Object handleContains(List<Object> args) {
            String cacheType = (String) args[0];
            String key = (String) args[1];
            String partition = (String) args[2];
            String cacheKey = cacheType + '_' + partition + '_' + key;
            
            return cacheData.containsKey(cacheKey);
        }
        
        private Object handleGetKeys(List<Object> args) {
            String cacheType = (String) args[0];
            String partition = (String) args[1];
            
            return partitionKeys.get(partition) != null ? partitionKeys.get(partition) : new Set<String>();
        }
    }
    
    // Test data constants
    private static final String TEST_CACHE_TYPE = 'ORG_CACHE';
    private static final String TEST_PARTITION = 'test_partition';
    
    @TestSetup
    static void setupTestData() {
        // Test setup - no specific setup needed for this test class
        // All mocking is done through StubProvider
    }
    
    @IsTest
    static void constructor_withValidProvider_createsInstance() {
        // Given
        MockCacheProviderStub mockStub = new MockCacheProviderStub();
        ICacheProvider mockProvider = (ICacheProvider) Test.createStub(ICacheProvider.class, mockStub);
        
        // When
        BulkCacheOperations bulkOps = new BulkCacheOperations(mockProvider);
        
        // Then
        Assert.isNotNull(bulkOps, 'BulkCacheOperations instance should be created');
    }
    
    @IsTest
    static void getBulk_withExistingKeys_returnsValues() {
        // Given
        MockCacheProviderStub mockStub = new MockCacheProviderStub();
        ICacheProvider mockProvider = (ICacheProvider) Test.createStub(ICacheProvider.class, mockStub);
        BulkCacheOperations bulkOps = new BulkCacheOperations(mockProvider);
        Set<String> keys = new Set<String>{'key1', 'key2', 'non_existent_key'};
        
        // When
        Map<String, Object> results = bulkOps.getBulk(TEST_CACHE_TYPE, keys, 'test_partition_1');
        
        // Then
        Assert.isNotNull(results, 'Results should not be null');
        Assert.areEqual(2, results.size(), 'Should return values for existing keys only');
        Assert.areEqual('value1', results.get('key1'), 'Should return correct value for key1');
        Assert.areEqual('value2', results.get('key2'), 'Should return correct value for key2');
        Assert.isFalse(results.containsKey('non_existent_key'), 'Should not contain non-existent key');
    }
    
    @IsTest
    static void getBulk_withEmptyKeys_returnsEmptyMap() {
        // Given
        MockCacheProviderStub mockStub = new MockCacheProviderStub();
        ICacheProvider mockProvider = (ICacheProvider) Test.createStub(ICacheProvider.class, mockStub);
        BulkCacheOperations bulkOps = new BulkCacheOperations(mockProvider);
        Set<String> emptyKeys = new Set<String>();
        
        // When
        Map<String, Object> results = bulkOps.getBulk(TEST_CACHE_TYPE, emptyKeys, TEST_PARTITION);
        
        // Then
        Assert.isNotNull(results, 'Results should not be null');
        Assert.areEqual(0, results.size(), 'Should return empty map for empty keys');
    }
    
    @IsTest
    static void putBulk_withTTL_allSuccessful_returnsTrue() {
        // Given
        MockCacheProviderStub mockStub = new MockCacheProviderStub();
        ICacheProvider mockProvider = (ICacheProvider) Test.createStub(ICacheProvider.class, mockStub);
        BulkCacheOperations bulkOps = new BulkCacheOperations(mockProvider);
        Map<String, Object> keyValuePairs = new Map<String, Object>{
            'new_key1' => 'new_value1',
            'new_key2' => 'new_value2'
        };
        Integer ttlSeconds = 3600;
        
        // When
        Boolean result = bulkOps.putBulk(TEST_CACHE_TYPE, keyValuePairs, TEST_PARTITION, ttlSeconds);
        
        // Then
        Assert.isTrue(result, 'Should return true when all operations succeed');
    }
    
    @IsTest
    static void putBulk_withoutTTL_allSuccessful_returnsTrue() {
        // Given
        MockCacheProviderStub mockStub = new MockCacheProviderStub();
        ICacheProvider mockProvider = (ICacheProvider) Test.createStub(ICacheProvider.class, mockStub);
        BulkCacheOperations bulkOps = new BulkCacheOperations(mockProvider);
        Map<String, Object> keyValuePairs = new Map<String, Object>{
            'new_key1' => 'new_value1',
            'new_key2' => 'new_value2'
        };
        
        // When
        Boolean result = bulkOps.putBulk(TEST_CACHE_TYPE, keyValuePairs, TEST_PARTITION);
        
        // Then
        Assert.isTrue(result, 'Should return true when all operations succeed');
    }
    
    @IsTest
    static void putBulkWithTTLs_withIndividualTTLs_returnsResultsMap() {
        // Given
        MockCacheProviderStub mockStub = new MockCacheProviderStub();
        ICacheProvider mockProvider = (ICacheProvider) Test.createStub(ICacheProvider.class, mockStub);
        BulkCacheOperations bulkOps = new BulkCacheOperations(mockProvider);
        Map<String, Object> keyValuePairs = new Map<String, Object>{
            'key1' => 'value1',
            'key2' => 'value2'
        };
        Map<String, Integer> keyTTLMap = new Map<String, Integer>{
            'key1' => 3600,
            'key2' => 7200
        };
        
        // When
        Map<String, Boolean> results = bulkOps.putBulkWithTTLs(TEST_CACHE_TYPE, keyValuePairs, keyTTLMap, TEST_PARTITION);
        
        // Then
        Assert.isNotNull(results, 'Results should not be null');
        Assert.areEqual(2, results.size(), 'Should return results for all keys');
        Assert.isTrue(results.get('key1'), 'Key1 operation should succeed');
        Assert.isTrue(results.get('key2'), 'Key2 operation should succeed');
    }
    
    @IsTest
    static void putBulkWithTTLs_withMissingTTL_handlesNullTTL() {
        // Given
        MockCacheProviderStub mockStub = new MockCacheProviderStub();
        ICacheProvider mockProvider = (ICacheProvider) Test.createStub(ICacheProvider.class, mockStub);
        BulkCacheOperations bulkOps = new BulkCacheOperations(mockProvider);
        Map<String, Object> keyValuePairs = new Map<String, Object>{
            'key1' => 'value1',
            'key2' => 'value2'
        };
        Map<String, Integer> keyTTLMap = new Map<String, Integer>{
            'key1' => 3600
            // key2 is missing from TTL map, so it will be null
        };
        
        // When
        Map<String, Boolean> results = bulkOps.putBulkWithTTLs(TEST_CACHE_TYPE, keyValuePairs, keyTTLMap, TEST_PARTITION);
        
        // Then
        Assert.isNotNull(results, 'Results should not be null');
        Assert.areEqual(2, results.size(), 'Should return results for all keys');
        Assert.isTrue(results.get('key1'), 'Key1 operation should succeed');
        Assert.isTrue(results.get('key2'), 'Key2 operation should succeed even with null TTL');
    }
    
    @IsTest
    static void removeBulk_withExistingKeys_returnsResultsMap() {
        // Given
        MockCacheProviderStub mockStub = new MockCacheProviderStub();
        ICacheProvider mockProvider = (ICacheProvider) Test.createStub(ICacheProvider.class, mockStub);
        BulkCacheOperations bulkOps = new BulkCacheOperations(mockProvider);
        Set<String> keys = new Set<String>{'key1', 'key2', 'non_existent_key'};
        
        // When
        Map<String, Boolean> results = bulkOps.removeBulk(TEST_CACHE_TYPE, keys, 'test_partition_1');
        
        // Then
        Assert.isNotNull(results, 'Results should not be null');
        Assert.areEqual(3, results.size(), 'Should return results for all keys');
        Assert.isTrue(results.get('key1'), 'Key1 removal should succeed');
        Assert.isTrue(results.get('key2'), 'Key2 removal should succeed');
        Assert.isFalse(results.get('non_existent_key'), 'Non-existent key removal should fail');
    }
    
    @IsTest
    static void containsBulk_withMixedKeys_returnsResultsMap() {
        // Given
        MockCacheProviderStub mockStub = new MockCacheProviderStub();
        ICacheProvider mockProvider = (ICacheProvider) Test.createStub(ICacheProvider.class, mockStub);
        BulkCacheOperations bulkOps = new BulkCacheOperations(mockProvider);
        Set<String> keys = new Set<String>{'key1', 'key2', 'non_existent_key'};
        
        // When
        Map<String, Boolean> results = bulkOps.containsBulk(TEST_CACHE_TYPE, keys, 'test_partition_1');
        
        // Then
        Assert.isNotNull(results, 'Results should not be null');
        Assert.areEqual(3, results.size(), 'Should return results for all keys');
        Assert.isTrue(results.get('key1'), 'Key1 should exist');
        Assert.isTrue(results.get('key2'), 'Key2 should exist');
        Assert.isFalse(results.get('non_existent_key'), 'Non-existent key should not exist');
    }
    
    @IsTest
    static void putCollection_withValidRecords_returnsTrue() {
        // Given
        MockCacheProviderStub mockStub = new MockCacheProviderStub();
        ICacheProvider mockProvider = (ICacheProvider) Test.createStub(ICacheProvider.class, mockStub);
        BulkCacheOperations bulkOps = new BulkCacheOperations(mockProvider);
        List<Account> accounts = new List<Account>{
            new Account(Name = 'Test Account 1'),
            new Account(Name = 'Test Account 2')
        };
        Integer ttlSeconds = 3600;
        
        // When
        Boolean result = bulkOps.putCollection(TEST_CACHE_TYPE, 'accounts_key', accounts, TEST_PARTITION, ttlSeconds);
        
        // Then
        Assert.isTrue(result, 'Should return true for successful collection put');
    }
    
    @IsTest
    static void putCollection_withoutTTL_returnsTrue() {
        // Given
        MockCacheProviderStub mockStub = new MockCacheProviderStub();
        ICacheProvider mockProvider = (ICacheProvider) Test.createStub(ICacheProvider.class, mockStub);
        BulkCacheOperations bulkOps = new BulkCacheOperations(mockProvider);
        List<Contact> contacts = new List<Contact>{
            new Contact(FirstName = 'John', LastName = 'Doe'),
            new Contact(FirstName = 'Jane', LastName = 'Smith')
        };
        
        // When
        Boolean result = bulkOps.putCollection(TEST_CACHE_TYPE, 'contacts_key', contacts, TEST_PARTITION);
        
        // Then
        Assert.isTrue(result, 'Should return true for successful collection put without TTL');
    }
    
    @IsTest
    static void putCollection_withNullTTL_returnsTrue() {
        // Given
        MockCacheProviderStub mockStub = new MockCacheProviderStub();
        ICacheProvider mockProvider = (ICacheProvider) Test.createStub(ICacheProvider.class, mockStub);
        BulkCacheOperations bulkOps = new BulkCacheOperations(mockProvider);
        List<Account> accounts = new List<Account>{
            new Account(Name = 'Test Account 1'),
            new Account(Name = 'Test Account 2')
        };
        Integer ttlSeconds = null; // Explicitly null TTL
        
        // When
        Boolean result = bulkOps.putCollection(TEST_CACHE_TYPE, 'accounts_key', accounts, TEST_PARTITION, ttlSeconds);
        
        // Then
        Assert.isTrue(result, 'Should return true for successful collection put with null TTL');
    }
    
    @IsTest
    static void getCollection_withExistingCollection_returnsList() {
        // Given
        MockCacheProviderStub mockStub = new MockCacheProviderStub();
        ICacheProvider mockProvider = (ICacheProvider) Test.createStub(ICacheProvider.class, mockStub);
        BulkCacheOperations bulkOps = new BulkCacheOperations(mockProvider);
        
        // When
        List<SObject> result = bulkOps.getCollection(TEST_CACHE_TYPE, 'accounts_key', 'test_partition_1');
        
        // Then
        Assert.isNotNull(result, 'Result should not be null');
        Assert.isTrue(result instanceof List<Account>, 'Should return Account list');
        Assert.areEqual(2, result.size(), 'Should return correct number of records');
    }
    
    @IsTest
    static void getCollection_withNonCollectionValue_returnsNull() {
        // Given
        MockCacheProviderStub mockStub = new MockCacheProviderStub();
        ICacheProvider mockProvider = (ICacheProvider) Test.createStub(ICacheProvider.class, mockStub);
        BulkCacheOperations bulkOps = new BulkCacheOperations(mockProvider);
        
        // When
        List<SObject> result = bulkOps.getCollection(TEST_CACHE_TYPE, 'key1', 'test_partition_1');
        
        // Then
        Assert.isNull(result, 'Should return null for non-collection value');
    }
    
    @IsTest
    static void putMultipleCollections_withValidCollections_returnsResultsMap() {
        // Given
        MockCacheProviderStub mockStub = new MockCacheProviderStub();
        ICacheProvider mockProvider = (ICacheProvider) Test.createStub(ICacheProvider.class, mockStub);
        BulkCacheOperations bulkOps = new BulkCacheOperations(mockProvider);
        Map<String, List<SObject>> collections = new Map<String, List<SObject>>{
            'accounts_key' => new List<Account>{new Account(Name = 'Test Account')},
            'contacts_key' => new List<Contact>{new Contact(FirstName = 'John', LastName = 'Doe')}
        };
        Integer ttlSeconds = 3600;
        
        // When
        Map<String, Boolean> results = bulkOps.putMultipleCollections(TEST_CACHE_TYPE, collections, TEST_PARTITION, ttlSeconds);
        
        // Then
        Assert.isNotNull(results, 'Results should not be null');
        Assert.areEqual(2, results.size(), 'Should return results for all collections');
        Assert.isTrue(results.get('accounts_key'), 'Accounts collection should succeed');
        Assert.isTrue(results.get('contacts_key'), 'Contacts collection should succeed');
    }
    
    @IsTest
    static void getMultipleCollections_withExistingCollections_returnsCollectionsMap() {
        // Given
        MockCacheProviderStub mockStub = new MockCacheProviderStub();
        ICacheProvider mockProvider = (ICacheProvider) Test.createStub(ICacheProvider.class, mockStub);
        BulkCacheOperations bulkOps = new BulkCacheOperations(mockProvider);
        Set<String> keys = new Set<String>{'accounts_key', 'contacts_key', 'non_existent_key'};
        
        // When
        Map<String, List<SObject>> results = bulkOps.getMultipleCollections(TEST_CACHE_TYPE, keys, 'test_partition_1');
        
        // Then
        Assert.isNotNull(results, 'Results should not be null');
        Assert.areEqual(1, results.size(), 'Should return existing collections only');
        Assert.isTrue(results.containsKey('accounts_key'), 'Should contain accounts collection');
        Assert.isFalse(results.containsKey('non_existent_key'), 'Should not contain non-existent collection');
    }
    
    @IsTest
    static void refreshBulk_withValidBuilder_returnsRefreshedValues() {
        // Given
        MockCacheProviderStub mockStub = new MockCacheProviderStub();
        ICacheProvider mockProvider = (ICacheProvider) Test.createStub(ICacheProvider.class, mockStub);
        BulkCacheOperations bulkOps = new BulkCacheOperations(mockProvider);
        Set<String> keys = new Set<String>{'key1', 'key2'};
        MockCacheBuilder builder = new MockCacheBuilder();
        Integer ttlSeconds = 3600;
        
        // When
        Map<String, Object> results = bulkOps.refreshBulk(TEST_CACHE_TYPE, keys, TEST_PARTITION, builder, ttlSeconds);
        
        // Then
        Assert.isNotNull(results, 'Results should not be null');
        Assert.areEqual(2, results.size(), 'Should return refreshed values for all keys');
        Assert.areEqual('built_value_1', results.get('key1'), 'Should return built value for key1');
        Assert.areEqual('built_value_2', results.get('key2'), 'Should return built value for key2');
    }
    
    @IsTest
    static void refreshBulk_withBuilderReturningNull_skipsNullValues() {
        // Given
        MockCacheProviderStub mockStub = new MockCacheProviderStub();
        ICacheProvider mockProvider = (ICacheProvider) Test.createStub(ICacheProvider.class, mockStub);
        BulkCacheOperations bulkOps = new BulkCacheOperations(mockProvider);
        Set<String> keys = new Set<String>{'key1', 'non_existent_build_key'};
        MockCacheBuilder builder = new MockCacheBuilder();
        Integer ttlSeconds = 3600;
        
        // When
        Map<String, Object> results = bulkOps.refreshBulk(TEST_CACHE_TYPE, keys, TEST_PARTITION, builder, ttlSeconds);
        
        // Then
        Assert.isNotNull(results, 'Results should not be null');
        Assert.areEqual(1, results.size(), 'Should return only non-null built values');
        Assert.areEqual('built_value_1', results.get('key1'), 'Should return built value for key1');
        Assert.isFalse(results.containsKey('non_existent_build_key'), 'Should not contain null built value');
    }
    
    @IsTest
    static void refreshBulk_withNullTTL_handlesNullTTL() {
        // Given
        MockCacheProviderStub mockStub = new MockCacheProviderStub();
        ICacheProvider mockProvider = (ICacheProvider) Test.createStub(ICacheProvider.class, mockStub);
        BulkCacheOperations bulkOps = new BulkCacheOperations(mockProvider);
        Set<String> keys = new Set<String>{'key1', 'key2'};
        MockCacheBuilder builder = new MockCacheBuilder();
        Integer ttlSeconds = null; // Null TTL
        
        // When
        Map<String, Object> results = bulkOps.refreshBulk(TEST_CACHE_TYPE, keys, TEST_PARTITION, builder, ttlSeconds);
        
        // Then
        Assert.isNotNull(results, 'Results should not be null');
        Assert.areEqual(2, results.size(), 'Should return refreshed values for all keys');
        Assert.areEqual('built_value_1', results.get('key1'), 'Should return built value for key1');
        Assert.areEqual('built_value_2', results.get('key2'), 'Should return built value for key2');
    }
    
    @IsTest
    static void getBulk_withNullKeys_returnsEmptyMap() {
        // Given
        MockCacheProviderStub mockStub = new MockCacheProviderStub();
        ICacheProvider mockProvider = (ICacheProvider) Test.createStub(ICacheProvider.class, mockStub);
        BulkCacheOperations bulkOps = new BulkCacheOperations(mockProvider);
        
        // When
        Set<String> keys = new Set<String>();
        Map<String, Object> results = bulkOps.getBulk(TEST_CACHE_TYPE, keys, TEST_PARTITION);
        
        // Then
        Assert.isNotNull(results, 'Results should not be null');
        Assert.areEqual(0, results.size(), 'Should return empty map for null keys');
    }
    
    @IsTest
    static void putBulk_withEmptyMap_returnsTrue() {
        // Given
        MockCacheProviderStub mockStub = new MockCacheProviderStub();
        ICacheProvider mockProvider = (ICacheProvider) Test.createStub(ICacheProvider.class, mockStub);
        BulkCacheOperations bulkOps = new BulkCacheOperations(mockProvider);
        Map<String, Object> emptyMap = new Map<String, Object>();
        
        // When
        Boolean result = bulkOps.putBulk(TEST_CACHE_TYPE, emptyMap, TEST_PARTITION);
        
        // Then
        Assert.isTrue(result, 'Should return true for empty map');
    }
    
    @IsTest
    static void removeBulk_withEmptyKeys_returnsEmptyMap() {
        // Given
        MockCacheProviderStub mockStub = new MockCacheProviderStub();
        ICacheProvider mockProvider = (ICacheProvider) Test.createStub(ICacheProvider.class, mockStub);
        BulkCacheOperations bulkOps = new BulkCacheOperations(mockProvider);
        Set<String> emptyKeys = new Set<String>();
        
        // When
        Map<String, Boolean> results = bulkOps.removeBulk(TEST_CACHE_TYPE, emptyKeys, TEST_PARTITION);
        
        // Then
        Assert.isNotNull(results, 'Results should not be null');
        Assert.areEqual(0, results.size(), 'Should return empty map for empty keys');
    }
    
    @IsTest
    static void containsBulk_withEmptyKeys_returnsEmptyMap() {
        // Given
        MockCacheProviderStub mockStub = new MockCacheProviderStub();
        ICacheProvider mockProvider = (ICacheProvider) Test.createStub(ICacheProvider.class, mockStub);
        BulkCacheOperations bulkOps = new BulkCacheOperations(mockProvider);
        Set<String> emptyKeys = new Set<String>();
        
        // When
        Map<String, Boolean> results = bulkOps.containsBulk(TEST_CACHE_TYPE, emptyKeys, TEST_PARTITION);
        
        // Then
        Assert.isNotNull(results, 'Results should not be null');
        Assert.areEqual(0, results.size(), 'Should return empty map for empty keys');
    }
}