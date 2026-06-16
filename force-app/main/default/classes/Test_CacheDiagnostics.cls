@IsTest
private class Test_CacheDiagnostics {
    
    // StubProvider implementation for ICacheProvider
    private class MockCacheProviderStub implements System.StubProvider {
        private Map<String, Object> cacheData = new Map<String, Object>();
        private Map<String, Set<String>> partitionKeys = new Map<String, Set<String>>();
        private Boolean shouldThrowException = false;
        private String exceptionMessage = 'Mock exception';
        
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
        }
        
        private void putToCache(String cacheType, String key, Object value, String partition) {
            String fullKey = CacheKeyManager.buildFullKey(key, partition);
            cacheData.put(fullKey, value);
            
            if (!partitionKeys.containsKey(partition)) {
                partitionKeys.put(partition, new Set<String>());
            }
            partitionKeys.get(partition).add(fullKey);
        }
        
        public Object handleMethodCall(
            Object stubbedObject,
            String stubbedMethodName,
            Type returnType,
            List<Type> listOfParamTypes,
            List<String> listOfParamNames,
            List<Object> listOfArgs
        ) {
            if (shouldThrowException) {
                throw new CalloutException(exceptionMessage);
            }
            
            switch on stubbedMethodName {
                when 'get' {
                    String cacheType = (String) listOfArgs[0];
                    String key = (String) listOfArgs[1];
                    String partition = (String) listOfArgs[2];
                    String fullKey = CacheKeyManager.buildFullKey(key, partition);
                    return cacheData.get(fullKey);
                }
                when 'put' {
                    String cacheType = (String) listOfArgs[0];
                    String key = (String) listOfArgs[1];
                    Object value = listOfArgs[2];
                    String partition = (String) listOfArgs[3];
                    putToCache(cacheType, key, value, partition);
                    return true;
                }
                when 'remove' {
                    String cacheType = (String) listOfArgs[0];
                    String key = (String) listOfArgs[1];
                    String partition = (String) listOfArgs[2];
                    String fullKey = CacheKeyManager.buildFullKey(key, partition);
                    Boolean removed = cacheData.containsKey(fullKey);
                    cacheData.remove(fullKey);
                    
                    if (partitionKeys.containsKey(partition)) {
                        partitionKeys.get(partition).remove(fullKey);
                    }
                    return removed;
                }
                when 'contains' {
                    String cacheType = (String) listOfArgs[0];
                    String key = (String) listOfArgs[1];
                    String partition = (String) listOfArgs[2];
                    String fullKey = CacheKeyManager.buildFullKey(key, partition);
                    return cacheData.containsKey(fullKey);
                }
                when 'getKeys' {
                    String cacheType = (String) listOfArgs[0];
                    String partition = (String) listOfArgs[1];
                    Set<String> keys = new Set<String>();
                    if (partitionKeys.containsKey(partition)) {
                        for (String fullKey : partitionKeys.get(partition)) {
                            String originalKey = CacheKeyManager.extractOriginalKey(fullKey, partition);
                            keys.add(originalKey);
                        }
                    }
                    return keys;
                }
                when else {
                    return null;
                }
            }
        }
    }
    
    // StubProvider that simulates put failure
    private class MockCacheProviderStubWithPutFailure implements System.StubProvider {
        private MockCacheProviderStub baseStub;
        
        public MockCacheProviderStubWithPutFailure() {
            this.baseStub = new MockCacheProviderStub();
        }
        
        public Object handleMethodCall(
            Object stubbedObject,
            String stubbedMethodName,
            Type returnType,
            List<Type> listOfParamTypes,
            List<String> listOfParamNames,
            List<Object> listOfArgs
        ) {
            if (stubbedMethodName == 'put') {
                return false; // Simulate put failure
            }
            return baseStub.handleMethodCall(stubbedObject, stubbedMethodName, returnType, listOfParamTypes, listOfParamNames, listOfArgs);
        }
    }
    
    @TestSetup
    static void setupTestData() {
        // Any test data setup if needed
    }
    
    @IsTest
    static void getCacheStats_Success_ReturnsValidStatsMap() {
        // Arrange
        ICacheProvider mockProvider = (ICacheProvider) Test.createStub(
            ICacheProvider.class, 
            new MockCacheProviderStub()
        );
        CacheDiagnostics diagnostics = new CacheDiagnostics(mockProvider);
        
        // Act
        Test.startTest();
        Map<String, Object> stats = diagnostics.getCacheStats('ORG_CACHE', 'test_partition_1');
        Test.stopTest();
        
        // Assert
        Assert.isNotNull(stats, 'Stats should not be null');
        Assert.areEqual(3, stats.get('keyCount'), 'Should return correct key count');
        Assert.areEqual('test_partition_1', stats.get('partition'), 'Should return correct partition');
        Assert.areEqual('ORG_CACHE', stats.get('cacheType'), 'Should return correct cache type');
        Assert.isNotNull(stats.get('timestamp'), 'Should include timestamp');
        Assert.isNotNull(stats.get('warning'), 'Should include warning about getCapacity');
    }
    
    @IsTest
    static void getCacheStats_Exception_ReturnsErrorInStatsMap() {
        // Arrange
        ICacheProvider mockProvider = (ICacheProvider) Test.createStub(
            ICacheProvider.class, 
            new MockCacheProviderStub(true, 'Test exception')
        );
        CacheDiagnostics diagnostics = new CacheDiagnostics(mockProvider);
        
        // Act
        Test.startTest();
        Map<String, Object> stats = diagnostics.getCacheStats('ORG_CACHE', 'test_partition_1');
        Test.stopTest();
        
        // Assert
        Assert.isNotNull(stats, 'Stats should not be null even on exception');
        Assert.areEqual('Test exception', stats.get('error'), 'Should include error message');
    }
    
    @IsTest
    static void analyzeCacheUsage_Success_ReturnsValidAnalysisMap() {
        // Arrange
        ICacheProvider mockProvider = (ICacheProvider) Test.createStub(
            ICacheProvider.class, 
            new MockCacheProviderStub()
        );
        CacheDiagnostics diagnostics = new CacheDiagnostics(mockProvider);
        
        // Act
        Test.startTest();
        Map<String, Object> analysis = diagnostics.analyzeCacheUsage('ORG_CACHE', 'test_partition_1', 5);
        Test.stopTest();
        
        // Assert
        Assert.isNotNull(analysis, 'Analysis should not be null');
        Assert.areEqual(3, analysis.get('totalKeys'), 'Should return correct total keys');
        Assert.areEqual(3, analysis.get('sampledKeys'), 'Should return correct sampled keys (limited by available keys)');
        Assert.isNotNull(analysis.get('validSamples'), 'Should include valid samples count');
        Assert.isNotNull(analysis.get('averageSize'), 'Should include average size');
        Assert.isNotNull(analysis.get('estimatedTotalSize'), 'Should include estimated total size');
        Assert.isNotNull(analysis.get('keyPatterns'), 'Should include key patterns');
        Assert.isNotNull(analysis.get('analysisTimestamp'), 'Should include timestamp');
    }
    
    @IsTest
    static void analyzeCacheUsage_EmptyPartition_ReturnsEmptyStatus() {
        // Arrange
        ICacheProvider mockProvider = (ICacheProvider) Test.createStub(
            ICacheProvider.class, 
            new MockCacheProviderStub()
        );
        CacheDiagnostics diagnostics = new CacheDiagnostics(mockProvider);
        
        // Act
        Test.startTest();
        Map<String, Object> analysis = diagnostics.analyzeCacheUsage('ORG_CACHE', 'empty_partition', 5);
        Test.stopTest();
        
        // Assert
        Assert.isNotNull(analysis, 'Analysis should not be null');
        Assert.areEqual(0, analysis.get('totalKeys'), 'Should return zero for empty partition');
        Assert.areEqual('empty', analysis.get('status'), 'Should indicate empty status');
    }
    
    @IsTest
    static void analyzeCacheUsage_Exception_ReturnsErrorInAnalysisMap() {
        // Arrange
        ICacheProvider mockProvider = (ICacheProvider) Test.createStub(
            ICacheProvider.class, 
            new MockCacheProviderStub(true, 'Analysis exception')
        );
        CacheDiagnostics diagnostics = new CacheDiagnostics(mockProvider);
        
        // Act
        Test.startTest();
        Map<String, Object> analysis = diagnostics.analyzeCacheUsage('ORG_CACHE', 'test_partition_1', 5);
        Test.stopTest();
        
        // Assert
        Assert.isNotNull(analysis, 'Analysis should not be null even on exception');
        Assert.areEqual('Analysis exception', analysis.get('error'), 'Should include error message');
    }
    
    @IsTest
    static void healthCheck_Success_ReturnsHealthyStatus() {
        // Arrange
        ICacheProvider mockProvider = (ICacheProvider) Test.createStub(
            ICacheProvider.class, 
            new MockCacheProviderStub()
        );
        CacheDiagnostics diagnostics = new CacheDiagnostics(mockProvider);
        
        // Act
        Test.startTest();
        Map<String, Object> health = diagnostics.healthCheck('ORG_CACHE', 'test_partition_1');
        Test.stopTest();
        
        // Assert
        Assert.isNotNull(health, 'Health check should not be null');
        Assert.areEqual(true, health.get('putTest'), 'Put test should pass');
        Assert.areEqual(true, health.get('getTest'), 'Get test should pass');
        Assert.areEqual(true, health.get('containsTest'), 'Contains test should pass');
        Assert.areEqual(true, health.get('removeTest'), 'Remove test should pass');
        Assert.areEqual(true, health.get('isHealthy'), 'Overall health should be true');
        Assert.isNotNull(health.get('timestamp'), 'Should include timestamp');
    }
    
    @IsTest
    static void healthCheck_Exception_ReturnsUnhealthyStatus() {
        // Arrange
        ICacheProvider mockProvider = (ICacheProvider) Test.createStub(
            ICacheProvider.class, 
            new MockCacheProviderStub(true, 'Health check exception')
        );
        CacheDiagnostics diagnostics = new CacheDiagnostics(mockProvider);
        
        // Act
        Test.startTest();
        Map<String, Object> health = diagnostics.healthCheck('ORG_CACHE', 'test_partition_1');
        Test.stopTest();
        
        // Assert
        Assert.isNotNull(health, 'Health check should not be null even on exception');
        Assert.areEqual(false, health.get('isHealthy'), 'Health should be false on exception');
        Assert.areEqual('Health check exception', health.get('error'), 'Should include error message');
    }
    
    @IsTest
    static void healthCheck_PartialFailure_ReturnsUnhealthyStatus() {
        // Arrange - Create a mock that fails specific operations
        ICacheProvider mockProvider = (ICacheProvider) Test.createStub(
            ICacheProvider.class, 
            new MockCacheProviderStubWithPutFailure()
        );
        CacheDiagnostics diagnostics = new CacheDiagnostics(mockProvider);
        
        // Act
        Test.startTest();
        Map<String, Object> health = diagnostics.healthCheck('ORG_CACHE', 'test_partition_1');
        Test.stopTest();
        
        // Assert
        Assert.isNotNull(health, 'Health check should not be null');
        Assert.areEqual(false, health.get('putTest'), 'Put test should fail');
        Assert.areEqual(false, health.get('isHealthy'), 'Overall health should be false');
    }
    
    @IsTest
    static void constructor_ValidProvider_InstantiatesSuccessfully() {
        // Arrange & Act
        ICacheProvider mockProvider = (ICacheProvider) Test.createStub(
            ICacheProvider.class, 
            new MockCacheProviderStub()
        );
        CacheDiagnostics diagnostics = new CacheDiagnostics(mockProvider);
        
        // Assert
        Assert.isNotNull(diagnostics, 'CacheDiagnostics should be instantiated');
    }
    
    @IsTest
    static void analyzeCacheUsage_NullSampleSize_UsesDefaultSampleSize() {
        // Arrange
        ICacheProvider mockProvider = (ICacheProvider) Test.createStub(
            ICacheProvider.class, 
            new MockCacheProviderStub()
        );
        CacheDiagnostics diagnostics = new CacheDiagnostics(mockProvider);
        
        // Act
        Test.startTest();
        Map<String, Object> analysis = diagnostics.analyzeCacheUsage('ORG_CACHE', 'test_partition_1', null);
        Test.stopTest();
        
        // Assert
        Assert.isNotNull(analysis, 'Analysis should not be null');
        Assert.areEqual(3, analysis.get('totalKeys'), 'Should return correct total keys');
        // Should use default sample size of 10, but limited by available keys
        Assert.areEqual(3, analysis.get('sampledKeys'), 'Should sample all available keys');
    }
    
    @IsTest
    static void analyzeCacheUsage_LargeSampleSize_LimitedByAvailableKeys() {
        // Arrange
        ICacheProvider mockProvider = (ICacheProvider) Test.createStub(
            ICacheProvider.class, 
            new MockCacheProviderStub()
        );
        CacheDiagnostics diagnostics = new CacheDiagnostics(mockProvider);
        
        // Act
        Test.startTest();
        Map<String, Object> analysis = diagnostics.analyzeCacheUsage('ORG_CACHE', 'test_partition_1', 100);
        Test.stopTest();
        
        // Assert
        Assert.isNotNull(analysis, 'Analysis should not be null');
        Assert.areEqual(3, analysis.get('totalKeys'), 'Should return correct total keys');
        // Should be limited by actual number of keys available
        Assert.areEqual(3, analysis.get('sampledKeys'), 'Should be limited by available keys');
    }
}