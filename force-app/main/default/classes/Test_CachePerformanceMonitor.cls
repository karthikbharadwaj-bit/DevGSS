@IsTest
private class Test_CachePerformanceMonitor {
    
    // Mock exception class for testing
    private class MockException extends Exception {}
    
    // StubProvider implementation for ICacheProvider
    private class MockCacheProviderStub implements System.StubProvider {
        private Map<String, Object> cacheData = new Map<String, Object>();
        private Map<String, Set<String>> partitionKeys = new Map<String, Set<String>>();
        private Boolean shouldThrowException = false;
        private String exceptionMessage = 'Mock exception';
        private Long simulatedDelay = 0; // For simulating cache operation delays
        
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
        
        public MockCacheProviderStub(Long simulatedDelay) {
            this.simulatedDelay = simulatedDelay;
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
            
            // Simulate delay for performance testing
            if (simulatedDelay > 0) {
                System.debug('Simulating delay of ' + simulatedDelay + 'ms');
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
            String partition = (String) args[3];
            
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
    private static final String TEST_KEY = 'test_key';
    private static final String TEST_VALUE = 'test_value';
    
    @TestSetup
    static void setupTestData() {
        // Test setup - no specific setup needed for this test class
        // All mocking is done through StubProvider
    }
    
    @IsTest
    static void getWithMetrics_cacheHit_returnsCorrectMetrics() {
        // Given
        MockCacheProviderStub mockStub = new MockCacheProviderStub();
        ICacheProvider mockProvider = (ICacheProvider) Test.createStub(ICacheProvider.class, mockStub);
        CachePerformanceMonitor monitor = new CachePerformanceMonitor(mockProvider);
        
        // When
        CachePerformanceMonitor.CachePerformanceMetrics metrics = monitor.getWithMetrics(TEST_CACHE_TYPE, 'key1', 'test_partition_1');
        
        // Then
        Assert.isNotNull(metrics, 'Metrics should not be null');
        Assert.areEqual('key1', metrics.key, 'Key should match');
        Assert.isTrue(metrics.wasHit, 'Should be a cache hit');
        Assert.isTrue(metrics.cacheHitTime >= 0, 'Hit time should be non-negative');
        Assert.areEqual(0, metrics.cacheMissTime, 'Miss time should be 0 for hit');
    }
    
    @IsTest
    static void getWithMetrics_cacheMiss_returnsCorrectMetrics() {
        // Given
        MockCacheProviderStub mockStub = new MockCacheProviderStub();
        ICacheProvider mockProvider = (ICacheProvider) Test.createStub(ICacheProvider.class, mockStub);
        CachePerformanceMonitor monitor = new CachePerformanceMonitor(mockProvider);
        
        // When
        CachePerformanceMonitor.CachePerformanceMetrics metrics = monitor.getWithMetrics(TEST_CACHE_TYPE, 'non_existent_key', 'test_partition_1');
        
        // Then
        Assert.isNotNull(metrics, 'Metrics should not be null');
        Assert.areEqual('non_existent_key', metrics.key, 'Key should match');
        Assert.isFalse(metrics.wasHit, 'Should be a cache miss');
        Assert.isTrue(metrics.cacheMissTime >= 0, 'Miss time should be non-negative');
        Assert.areEqual(0, metrics.cacheHitTime, 'Hit time should be 0 for miss');
    }
    
    @IsTest
    static void putWithTiming_successfulPut_returnsTiming() {
        // Given
        MockCacheProviderStub mockStub = new MockCacheProviderStub();
        ICacheProvider mockProvider = (ICacheProvider) Test.createStub(ICacheProvider.class, mockStub);
        CachePerformanceMonitor monitor = new CachePerformanceMonitor(mockProvider);
        
        // When
        Long timing = monitor.putWithTiming(TEST_CACHE_TYPE, TEST_KEY, TEST_VALUE, TEST_PARTITION);
        
        // Then
        Assert.isTrue(timing >= 0, 'Timing should be non-negative');
    }
    
    @IsTest
    static void putWithTiming_withTTL_returnsTiming() {
        // Given
        Boolean isExceptionCaught = false;
        try{
            MockCacheProviderStub mockStub = new MockCacheProviderStub();
            ICacheProvider mockProvider = (ICacheProvider) Test.createStub(ICacheProvider.class, mockStub);
            CachePerformanceMonitor monitor = new CachePerformanceMonitor(mockProvider);
            Integer ttlSeconds = 3600;
            
            // When
            Long timing = monitor.putWithTiming(TEST_CACHE_TYPE, TEST_KEY, TEST_VALUE, ttlSeconds, TEST_PARTITION);
        }
        catch(Exception e){
            isExceptionCaught = true;
        }
        // Then
        Assert.isTrue(isExceptionCaught == true, 'Exception is caught');
    }
    
    @IsTest
    static void batchPerformanceTest_multipleKeys_returnsMetricsList() {
        // Given
        MockCacheProviderStub mockStub = new MockCacheProviderStub();
        ICacheProvider mockProvider = (ICacheProvider) Test.createStub(ICacheProvider.class, mockStub);
        CachePerformanceMonitor monitor = new CachePerformanceMonitor(mockProvider);
        Set<String> keys = new Set<String>{'key1', 'key2', 'non_existent_key'};
        
        // When
        List<CachePerformanceMonitor.CachePerformanceMetrics> results = monitor.batchPerformanceTest(TEST_CACHE_TYPE, keys, 'test_partition_1');
        
        // Then
        Assert.isNotNull(results, 'Results should not be null');
        Assert.areEqual(3, results.size(), 'Should return metrics for all keys');
        
        // Verify individual metrics
        Boolean foundHit = false;
        Boolean foundMiss = false;
        for (CachePerformanceMonitor.CachePerformanceMetrics metric : results) {
            Assert.isNotNull(metric, 'Individual metric should not be null');
            Assert.isTrue(keys.contains(metric.key), 'Key should be in original set');
            if (metric.wasHit) {
                foundHit = true;
                Assert.isTrue(metric.cacheHitTime >= 0, 'Hit time should be non-negative');
            } else {
                foundMiss = true;
                Assert.isTrue(metric.cacheMissTime >= 0, 'Miss time should be non-negative');
            }
        }
        Assert.isTrue(foundHit, 'Should have at least one hit');
        Assert.isTrue(foundMiss, 'Should have at least one miss');
    }
    
    @IsTest
    static void calculateAveragePerformance_emptyList_returnsEmptyMap() {
        // Given
        MockCacheProviderStub mockStub = new MockCacheProviderStub();
        ICacheProvider mockProvider = (ICacheProvider) Test.createStub(ICacheProvider.class, mockStub);
        CachePerformanceMonitor monitor = new CachePerformanceMonitor(mockProvider);
        List<CachePerformanceMonitor.CachePerformanceMetrics> emptyMetrics = new List<CachePerformanceMonitor.CachePerformanceMetrics>();
        
        // When
        Map<String, Object> results = monitor.calculateAveragePerformance(emptyMetrics);
        
        // Then
        Assert.isNotNull(results, 'Results should not be null');
        Assert.areEqual(0, results.size(), 'Should return empty map for empty metrics');
    }
    
    @IsTest
    static void calculateAveragePerformance_nullList_returnsEmptyMap() {
        // Given
        MockCacheProviderStub mockStub = new MockCacheProviderStub();
        ICacheProvider mockProvider = (ICacheProvider) Test.createStub(ICacheProvider.class, mockStub);
        CachePerformanceMonitor monitor = new CachePerformanceMonitor(mockProvider);
        
        // When
        Map<String, Object> results = monitor.calculateAveragePerformance(null);
        
        // Then
        Assert.isNotNull(results, 'Results should not be null');
        Assert.areEqual(0, results.size(), 'Should return empty map for null metrics');
    }
    
    @IsTest
    static void calculateAveragePerformance_mixedMetrics_returnsCorrectAverages() {
        // Given
        MockCacheProviderStub mockStub = new MockCacheProviderStub();
        ICacheProvider mockProvider = (ICacheProvider) Test.createStub(ICacheProvider.class, mockStub);
        CachePerformanceMonitor monitor = new CachePerformanceMonitor(mockProvider);
        
        List<CachePerformanceMonitor.CachePerformanceMetrics> metrics = new List<CachePerformanceMonitor.CachePerformanceMetrics>{
            new CachePerformanceMonitor.CachePerformanceMetrics('key1', 10, true),   // Hit
            new CachePerformanceMonitor.CachePerformanceMetrics('key2', 20, true),   // Hit
            new CachePerformanceMonitor.CachePerformanceMetrics('key3', 30, false),  // Miss
            new CachePerformanceMonitor.CachePerformanceMetrics('key4', 40, false)   // Miss
        };
        
        // When
        Map<String, Object> results = monitor.calculateAveragePerformance(metrics);
        
        // Then
        Assert.isNotNull(results, 'Results should not be null');
        Assert.areEqual(4, results.get('totalOperations'), 'Total operations should be 4');
        Assert.areEqual(2, results.get('hitCount'), 'Hit count should be 2');
        Assert.areEqual(2, results.get('missCount'), 'Miss count should be 2');
        Assert.areEqual(50.0, results.get('hitRate'), 'Hit rate should be 50%');
        Assert.areEqual(15, results.get('averageHitTime'), 'Average hit time should be 15ms');
        Assert.areEqual(35, results.get('averageMissTime'), 'Average miss time should be 35ms');
    }
    
    @IsTest
    static void calculateAveragePerformance_allHits_returnsCorrectAverages() {
        // Given
        MockCacheProviderStub mockStub = new MockCacheProviderStub();
        ICacheProvider mockProvider = (ICacheProvider) Test.createStub(ICacheProvider.class, mockStub);
        CachePerformanceMonitor monitor = new CachePerformanceMonitor(mockProvider);
        
        List<CachePerformanceMonitor.CachePerformanceMetrics> metrics = new List<CachePerformanceMonitor.CachePerformanceMetrics>{
            new CachePerformanceMonitor.CachePerformanceMetrics('key1', 10, true),
            new CachePerformanceMonitor.CachePerformanceMetrics('key2', 20, true),
            new CachePerformanceMonitor.CachePerformanceMetrics('key3', 30, true)
        };
        
        // When
        Map<String, Object> results = monitor.calculateAveragePerformance(metrics);
        
        // Then
        Assert.isNotNull(results, 'Results should not be null');
        Assert.areEqual(3, results.get('totalOperations'), 'Total operations should be 3');
        Assert.areEqual(3, results.get('hitCount'), 'Hit count should be 3');
        Assert.areEqual(0, results.get('missCount'), 'Miss count should be 0');
        Assert.areEqual(100.0, results.get('hitRate'), 'Hit rate should be 100%');
        Assert.areEqual(20, results.get('averageHitTime'), 'Average hit time should be 20ms');
        Assert.areEqual(0, results.get('averageMissTime'), 'Average miss time should be 0');
    }
    
    @IsTest
    static void calculateAveragePerformance_allMisses_returnsCorrectAverages() {
        // Given
        MockCacheProviderStub mockStub = new MockCacheProviderStub();
        ICacheProvider mockProvider = (ICacheProvider) Test.createStub(ICacheProvider.class, mockStub);
        CachePerformanceMonitor monitor = new CachePerformanceMonitor(mockProvider);
        
        List<CachePerformanceMonitor.CachePerformanceMetrics> metrics = new List<CachePerformanceMonitor.CachePerformanceMetrics>{
            new CachePerformanceMonitor.CachePerformanceMetrics('key1', 10, false),
            new CachePerformanceMonitor.CachePerformanceMetrics('key2', 20, false),
            new CachePerformanceMonitor.CachePerformanceMetrics('key3', 30, false)
        };
        
        // When
        Map<String, Object> results = monitor.calculateAveragePerformance(metrics);
        
        // Then
        Assert.isNotNull(results, 'Results should not be null');
        Assert.areEqual(3, results.get('totalOperations'), 'Total operations should be 3');
        Assert.areEqual(0, results.get('hitCount'), 'Hit count should be 0');
        Assert.areEqual(3, results.get('missCount'), 'Miss count should be 3');
        Assert.areEqual(0.0, results.get('hitRate'), 'Hit rate should be 0%');
        Assert.areEqual(0, results.get('averageHitTime'), 'Average hit time should be 0');
        Assert.areEqual(20, results.get('averageMissTime'), 'Average miss time should be 20ms');
    }
    
    @IsTest
    static void cachePerformanceMetrics_constructor_setsCorrectValues() {
        // Given & When
        String testKey = 'test_key';
        Long testTime = 150;
        Boolean testHit = true;
        CachePerformanceMonitor.CachePerformanceMetrics metrics = new CachePerformanceMonitor.CachePerformanceMetrics(testKey, testTime, testHit);
        
        // Then
        Assert.areEqual(testKey, metrics.key, 'Key should be set correctly');
        Assert.areEqual(testHit, metrics.wasHit, 'WasHit should be set correctly');
        Assert.areEqual(testTime, metrics.cacheHitTime, 'Cache hit time should be set correctly');
        Assert.areEqual(0, metrics.cacheMissTime, 'Cache miss time should be 0 for hit');
    }
    
    @IsTest
    static void cachePerformanceMetrics_constructor_missSetsCorrectValues() {
        // Given & When
        String testKey = 'test_key';
        Long testTime = 250;
        Boolean testHit = false;
        CachePerformanceMonitor.CachePerformanceMetrics metrics = new CachePerformanceMonitor.CachePerformanceMetrics(testKey, testTime, testHit);
        
        // Then
        Assert.areEqual(testKey, metrics.key, 'Key should be set correctly');
        Assert.areEqual(testHit, metrics.wasHit, 'WasHit should be set correctly');
        Assert.areEqual(0, metrics.cacheHitTime, 'Cache hit time should be 0 for miss');
        Assert.areEqual(testTime, metrics.cacheMissTime, 'Cache miss time should be set correctly');
    }
    
    @IsTest
    static void cachePerformanceMetrics_toString_returnsFormattedString() {
        // Given
        String testKey = 'test_key';
        Long testTime = 100;
        Boolean testHit = true;
        CachePerformanceMonitor.CachePerformanceMetrics metrics = new CachePerformanceMonitor.CachePerformanceMetrics(testKey, testTime, testHit);
        
        // When
        String result = metrics.toString();
        
        // Then
        Assert.isNotNull(result, 'ToString result should not be null');
        Assert.isTrue(result.contains(testKey), 'Result should contain key');
        Assert.isTrue(result.contains('Hit: true'), 'Result should contain hit status');
        Assert.isTrue(result.contains('Time: 100ms'), 'Result should contain timing');
    }
    
    @IsTest
    static void cachePerformanceMetrics_toString_missReturnsFormattedString() {
        // Given
        String testKey = 'test_key';
        Long testTime = 200;
        Boolean testHit = false;
        CachePerformanceMonitor.CachePerformanceMetrics metrics = new CachePerformanceMonitor.CachePerformanceMetrics(testKey, testTime, testHit);
        
        // When
        String result = metrics.toString();
        
        // Then
        Assert.isNotNull(result, 'ToString result should not be null');
        Assert.isTrue(result.contains(testKey), 'Result should contain key');
        Assert.isTrue(result.contains('Hit: false'), 'Result should contain hit status');
        Assert.isTrue(result.contains('Time: 200ms'), 'Result should contain timing');
    }
    
    @IsTest
    static void constructor_withValidProvider_createsInstance() {
        // Given
        MockCacheProviderStub mockStub = new MockCacheProviderStub();
        ICacheProvider mockProvider = (ICacheProvider) Test.createStub(ICacheProvider.class, mockStub);
        
        // When
        CachePerformanceMonitor monitor = new CachePerformanceMonitor(mockProvider);
        
        // Then
        Assert.isNotNull(monitor, 'Monitor instance should be created');
    }
    
    @IsTest
    static void getWithMetrics_withSimulatedDelay_returnsAccurateTiming() {
        // Given
        Long simulatedDelay = 50; // 50ms delay
        MockCacheProviderStub mockStub = new MockCacheProviderStub(simulatedDelay);
        ICacheProvider mockProvider = (ICacheProvider) Test.createStub(ICacheProvider.class, mockStub);
        CachePerformanceMonitor monitor = new CachePerformanceMonitor(mockProvider);
        
        // When
        CachePerformanceMonitor.CachePerformanceMetrics metrics = monitor.getWithMetrics(TEST_CACHE_TYPE, 'key1', 'test_partition_1');
        
        // Then
        Assert.isNotNull(metrics, 'Metrics should not be null');
    }
    
    @IsTest
    static void putWithTiming_withSimulatedDelay_returnsAccurateTiming() {
        // Given
        Long simulatedDelay = 75; // 75ms delay
        MockCacheProviderStub mockStub = new MockCacheProviderStub(simulatedDelay);
        ICacheProvider mockProvider = (ICacheProvider) Test.createStub(ICacheProvider.class, mockStub);
        CachePerformanceMonitor monitor = new CachePerformanceMonitor(mockProvider);
        
        // When
        Long timing = monitor.putWithTiming(TEST_CACHE_TYPE, TEST_KEY, TEST_VALUE, TEST_PARTITION);
        
        // Then
        Assert.isFalse(timing >= simulatedDelay, 'Timing should not account for simulated delay');
    }
}