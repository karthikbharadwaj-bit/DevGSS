/**
 * Cache diagnostics and monitoring utility
 * Follows Single Responsibility Principle - handles diagnostics and monitoring
 */
public with sharing class CacheDiagnostics {
    
    private ICacheProvider cacheProvider;
    private static final String LOCAL_PREFIX = 'local.';
    
    public CacheDiagnostics(ICacheProvider provider) {
        this.cacheProvider = provider;
    }
    
    /**
     * Gets basic cache statistics for a partition
     */
    public Map<String, Object> getCacheStats(String cacheType, String partition) {
        Map<String, Object> stats = new Map<String, Object>();
        
        try {
            Set<String> keys = cacheProvider.getKeys(cacheType, partition);
            stats.put('keyCount', keys.size());
            stats.put('partition', partition);
            stats.put('cacheType', cacheType);
            stats.put('timestamp', System.now());
            
            // Note: Avoid calling getCapacity() frequently as it's expensive
            stats.put('warning', 'Use getCapacity() sparingly due to performance impact');
        } catch (Exception ex) {
            stats.put('error', ex.getMessage());
        }
        
        return stats;
    }
    
    /**
     * Comprehensive cache diagnostics (expensive operation)
     * Use sparingly due to performance impact
     */
    public void logCacheDiagnostics(String cacheType, String partition) {
        
        try {
            Set<String> keys = cacheProvider.getKeys(cacheType, partition);
            
            // Sample a few keys for size estimation
            Integer sampleCount = 0;
            Long totalEstimatedSize = 0;
            
            for (String key : keys) {
                if (sampleCount >= 5){
                    break; // Sample only first 5 keys
                }
                String originalKey = CacheKeyManager.extractOriginalKey(key, partition);
                Object value = cacheProvider.get(cacheType, originalKey, partition);
                if (value != null) {
                    Long size = estimateValueSize(value);
                    totalEstimatedSize += size;
                }
                sampleCount++;
            }
            
            if (sampleCount > 0) {
                Long avgSize = totalEstimatedSize / sampleCount;
            }
        } catch (Exception ex) {
        }
    }
    
    /**
     * Analyzes cache usage patterns
     */
    public Map<String, Object> analyzeCacheUsage(String cacheType, String partition, Integer sampleSize) {
        Map<String, Object> analysis = new Map<String, Object>();
        
        try {
            Set<String> keys = cacheProvider.getKeys(cacheType, partition);
            analysis.put('totalKeys', keys.size());
            
            if (keys.isEmpty()) {
                analysis.put('status', 'empty');
                return analysis;
            }
            
            // Sample analysis
            Integer actualSampleSize = Math.min(sampleSize != null ? sampleSize : 10, keys.size());
            List<String> keyList = new List<String>(keys);
            
            Long totalSize = 0;
            Integer validSamples = 0;
            Map<String, Integer> keyPatterns = new Map<String, Integer>();
            
            for (Integer i = 0; i < actualSampleSize; i++) {
                String fullKey = keyList[i];
                String originalKey = CacheKeyManager.extractOriginalKey(fullKey, partition);
                
                Object value = cacheProvider.get(cacheType, originalKey, partition);
                if (value != null) {
                    totalSize += estimateValueSize(value);
                    validSamples++;
                    
                    // Analyze key patterns
                    String pattern = originalKey.contains('_') ? originalKey.split('_')[0] : originalKey;
                    keyPatterns.put(pattern, keyPatterns.containsKey(pattern) ? keyPatterns.get(pattern) + 1 : 1);
                }
            }
            
            analysis.put('sampledKeys', actualSampleSize);
            analysis.put('validSamples', validSamples);
            analysis.put('averageSize', validSamples > 0 ? totalSize / validSamples : 0);
            analysis.put('estimatedTotalSize', validSamples > 0 ? (totalSize / validSamples) * keys.size() : 0);
            analysis.put('keyPatterns', keyPatterns);
            analysis.put('analysisTimestamp', System.now());
            
        } catch (Exception ex) {
            analysis.put('error', ex.getMessage());
        }
        
        return analysis;
    }
    
    /**
     * Health check for cache partition
     */
    public Map<String, Object> healthCheck(String cacheType, String partition) {
        Map<String, Object> health = new Map<String, Object>();
        
        try {
            // Test basic operations
            String testKey = 'health_check_' + System.currentTimeMillis();
            String testValue = 'health_check_value';
            
            // Test put
            Boolean putSuccess = cacheProvider.put(cacheType, testKey, testValue, partition);
            health.put('putTest', putSuccess);
            
            // Test get
            Object retrievedValue = cacheProvider.get(cacheType, testKey, partition);
            Boolean getSuccess = testValue.equals(retrievedValue);
            health.put('getTest', getSuccess);
            
            // Test contains
            Boolean containsSuccess = cacheProvider.contains(cacheType, testKey, partition);
            health.put('containsTest', containsSuccess);
            
            // Test remove
            Boolean removeSuccess = cacheProvider.remove(cacheType, testKey, partition);
            health.put('removeTest', removeSuccess);
            
            // Overall health
            Boolean isHealthy = putSuccess && getSuccess && containsSuccess && removeSuccess;
            health.put('isHealthy', isHealthy);
            health.put('timestamp', System.now());
            
        } catch (Exception ex) {
            health.put('isHealthy', false);
            health.put('error', ex.getMessage());
        }
        
        return health;
    }
    
    private Long estimateValueSize(Object value) {
        String serialized = JSON.serialize(value);
        return (Long) serialized.length() * 2;
    }
}