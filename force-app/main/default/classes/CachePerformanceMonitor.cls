/**
 * Cache performance monitoring utility
 * Follows Single Responsibility Principle - handles performance metrics and timing
 */
public with sharing class CachePerformanceMonitor {
    
    /**
     * Performance metrics data structure
     */
    public class CachePerformanceMetrics {
        public Long cacheHitTime;
        public Long cacheMissTime;
        public Boolean wasHit;
        public String key;
        
        public CachePerformanceMetrics(String cacheKey, Long elapsedTime, Boolean hit) {
            this.key = cacheKey;
            this.wasHit = hit;
            this.cacheHitTime = hit ? elapsedTime : 0;
            this.cacheMissTime = hit ? 0 : elapsedTime;
        }
        
        public override String toString() {
            return 'Key: ' + key + ', Hit: ' + wasHit + ', Time: ' + (wasHit ? cacheHitTime : cacheMissTime) + 'ms';
        }
    }
    
    private ICacheProvider cacheProvider;
    
    public CachePerformanceMonitor(ICacheProvider provider) {
        this.cacheProvider = provider;
    }
    
    /**
     * Gets cache value with performance timing
     */
    public CachePerformanceMetrics getWithMetrics(String cacheType, String key, String partition) {
        Long startTime = System.currentTimeMillis();
        Object value = cacheProvider.get(cacheType, key, partition);
        Long elapsedTime = System.currentTimeMillis() - startTime;
        
        return new CachePerformanceMetrics(key, elapsedTime, value != null);
    }
    
    /**
     * Puts cache value with performance timing
     */
    public Long putWithTiming(String cacheType, String key, Object value, String partition) {
        Long startTime = System.currentTimeMillis();
        cacheProvider.put(cacheType, key, value, partition);
        return System.currentTimeMillis() - startTime;
    }
    
    /**
     * Puts cache value with TTL and performance timing
     */
    public Long putWithTiming(String cacheType, String key, Object value, Integer ttlSeconds, String partition) {
        Long startTime = System.currentTimeMillis();
        cacheProvider.put(cacheType, key, value, ttlSeconds, partition);
        return System.currentTimeMillis() - startTime;
    }
    
    /**
     * Batch performance test for multiple keys
     */
    public List<CachePerformanceMetrics> batchPerformanceTest(String cacheType, Set<String> keys, String partition) {
        List<CachePerformanceMetrics> results = new List<CachePerformanceMetrics>();
        
        for (String key : keys) {
            results.add(getWithMetrics(cacheType, key, partition));
        }
        
        return results;
    }
    
    /**
     * Calculates average performance across multiple operations
     */
    public Map<String, Object> calculateAveragePerformance(List<CachePerformanceMetrics> metrics) {
        if (metrics == null || metrics.isEmpty()) {
            return new Map<String, Object>();
        }
        
        Long totalHitTime = 0;
        Long totalMissTime = 0;
        Integer hitCount = 0;
        Integer missCount = 0;
        
        for (CachePerformanceMetrics metric : metrics) {
            if (metric.wasHit) {
                totalHitTime += metric.cacheHitTime;
                hitCount++;
            } else {
                totalMissTime += metric.cacheMissTime;
                missCount++;
            }
        }
        
        Map<String, Object> results = new Map<String, Object>();
        results.put('totalOperations', metrics.size());
        results.put('hitCount', hitCount);
        results.put('missCount', missCount);
        results.put('hitRate', hitCount > 0 ? (Decimal) hitCount / metrics.size() * 100 : 0);
        results.put('averageHitTime', hitCount > 0 ? totalHitTime / hitCount : 0);
        results.put('averageMissTime', missCount > 0 ? totalMissTime / missCount : 0);
        
        return results;
    }
}