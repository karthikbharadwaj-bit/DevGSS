/**
 * Main Platform Cache Utility - Facade Pattern
 * Follows Facade Pattern - provides a unified interface to the cache subsystem
 * Maintains backward compatibility while leveraging SOLID principles
 * 
 * SOLID Principles Applied:
 * - Single Responsibility: Each component has one clear responsibility
 * - Open/Closed: Easy to extend with new cache providers or behaviors
 * - Liskov Substitution: ICacheProvider implementations are interchangeable
 * - Interface Segregation: Focused interfaces for specific capabilities
 * - Dependency Inversion: Depends on abstractions, not concrete implementations
 */
public with sharing class PlatformCacheUtility {
    
    // Static instances for backward compatibility
    private static ICacheProvider cacheProvider = new PlatformCacheProvider();
    //private static CacheManager cacheManager = new CacheManager(cacheProvider);
    private static CachePerformanceMonitor performanceMonitor = new CachePerformanceMonitor(cacheProvider);
    private static CacheDiagnostics diagnostics = new CacheDiagnostics(cacheProvider);
    private static BulkCacheOperations bulkOps = new BulkCacheOperations(cacheProvider);
    
    // Constants for backward compatibility
    public static final String ORG_CACHE = 'ORG_CACHE';
    public static final String SESSION_CACHE = 'SESSION_CACHE';
    public static final String CURRENT_USER_SESSION_DATA = 'CurrentUserSessionData';
    
    // Legacy Custom Exception for backward compatibility
    public class PlatformCacheException extends Exception {}
    
    // Legacy Classes for backward compatibility
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
    }
    
    public interface CacheBuilder {
        Object buildValue(String key);
    }
    
    // ===== BACKWARD COMPATIBLE API =====
    
    /**
     * Gets value from cache - maintains original signature
     */
    public static Object get(String cacheType, String key, String partition) {
        return cacheProvider.get(cacheType, key, partition);
    }
    
    /**
     * Puts value in cache with TTL - maintains original signature
     */
    public static Boolean put(String cacheType, String key, Object value, Integer ttlSeconds, String partition) {
        return cacheProvider.put(cacheType, key, value, ttlSeconds, partition);
    }
    
    /**
     * Puts value in cache without TTL - maintains original signature
     */
    public static Boolean put(String cacheType, String key, Object value, String partitionName) {
        return cacheProvider.put(cacheType, key, value, partitionName);
    }
    
    /**
     * Removes value from cache - maintains original signature
     */
    public static Boolean remove(String cacheType, String key, String partition) {
        return cacheProvider.remove(cacheType, key, partition);
    }
    
    /**
     * Checks if cache contains key - maintains original signature
     */
    public static Boolean contains(String cacheType, String key, String partition) {
        return cacheProvider.contains(cacheType, key, partition);
    }
    
    /**
     * Gets all keys from partition - maintains original signature
     */
    public static Set<String> getKeys(String cacheType, String partition) {
        return cacheProvider.getKeys(cacheType, partition);
    }
    
    /**
     * Gets dynamic SObject record - maintains original signature
     */
    public static SObject getDynamicRecord(String cacheType, String key, String partitionName, String sObjectTypeVal) {
        return cacheProvider.getDynamicRecord(cacheType, key, partitionName, sObjectTypeVal);
    }
    
    /**
     * Removes all keys from a specific partition in platform cache
     */
    public static void removeKeys(String cacheType, String partitionName) {
        cacheProvider.removeKeys(cacheType, partitionName);
    }
    
    /**
     * Gets cache value with performance metrics
     */
    public static CachePerformanceMetrics getWithMetrics(String cacheType, String key, String partition) {
        CachePerformanceMonitor.CachePerformanceMetrics metrics = performanceMonitor.getWithMetrics(cacheType, key, partition);
        return new CachePerformanceMetrics(metrics.key, 
            metrics.wasHit ? metrics.cacheHitTime : metrics.cacheMissTime, metrics.wasHit);
    }
    
    /**
     * Bulk cache operations
     */
    public static Map<String, Object> getBulk(String cacheType, Set<String> keys, String partition) {
        return bulkOps.getBulk(cacheType, keys, partition);
    }
    
    public static Boolean putBulk(String cacheType, Map<String, Object> keyValuePairs, String partition, Integer ttlSeconds) {
        return bulkOps.putBulk(cacheType, keyValuePairs, partition, ttlSeconds);
    }
    
    public static Boolean putBulk(String cacheType, Map<String, Object> keyValuePairs, String partition) {
        return bulkOps.putBulk(cacheType, keyValuePairs, partition);
    }
    
    /**
     * Collection caching
     */
    public static Boolean putCollection(String cacheType, String key, List<SObject> records, String partition, Integer ttlSeconds) {
        return bulkOps.putCollection(cacheType, key, records, partition, ttlSeconds);
    }
    
    public static Boolean putCollection(String cacheType, String key, List<SObject> records, String partition) {
        return bulkOps.putCollection(cacheType, key, records, partition);
    }
    
    public static List<SObject> getCollection(String cacheType, String key, String partition) {
        return bulkOps.getCollection(cacheType, key, partition);
    }
    
    // ===== DEPENDENCY INJECTION SUPPORT =====
    
    /**
     * Allows injection of custom cache provider for testing or extending functionality
     * Follows Dependency Inversion Principle
     */
    public static void setCacheProvider(ICacheProvider provider) {
        cacheProvider = provider;
        performanceMonitor = new CachePerformanceMonitor(provider);
        diagnostics = new CacheDiagnostics(provider);
        bulkOps = new BulkCacheOperations(provider);
    }
    
    /**
     * Gets current cache provider instance
     */
    public static ICacheProvider getCacheProvider() {
        return cacheProvider;
    }
}