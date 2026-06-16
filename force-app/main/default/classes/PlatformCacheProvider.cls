/**
 * Core platform cache provider implementation
 * Follows Single Responsibility Principle - handles core cache operations
 * Implements Dependency Inversion Principle - depends on ICacheProvider abstraction
 */
public with sharing class PlatformCacheProvider implements ICacheProvider {
    
    // Cache Type Constants
    public static final String ORG_CACHE = 'ORG_CACHE';
    private static final String CACHE_OPERATION_FAILED_FOR_KEY_AND_PARTITION_ERROR = 'Cache operation {0} failed for key {1}: {2}';
    
    // Custom Exception
    public class PlatformCacheException extends Exception {}
    
    public Object get(String cacheType, String key, String partition) {
        try {
            CacheValidator.validateKey(key);
            CacheValidator.validatePartitionName(partition);
            
            String fullKey = CacheKeyManager.buildFullKey(key, partition);
            
            if (cacheType == ORG_CACHE) {
                return Cache.Org.get(fullKey);
            } else {
                return Cache.Session.get(fullKey);
            }
        } catch (Exception ex) {
            handleCacheException('GET', key, ex);
            return null;
        }
    }
    
    public Boolean put(String cacheType, String key, Object value, Integer ttlSeconds, String partition) {
        try {
            CacheValidator.validateKey(key);
            CacheValidator.validateValue(value);
            CacheValidator.validateLocalCacheLimit(cacheType, value);
            CacheValidator.validatePartitionName(partition);
            
            String fullKey = CacheKeyManager.buildFullKey(key, partition);
            
            if (cacheType == ORG_CACHE) {
                if (ttlSeconds != null) {
                    Cache.Org.put(fullKey, value, ttlSeconds);
                } else {
                    Cache.Org.put(fullKey, value);
                }
            } else {
                if (ttlSeconds != null) {
                    Cache.Session.put(fullKey, value, ttlSeconds);
                } else {
                    Cache.Session.put(fullKey, value);
                }
            }
            
            return true;
        } catch (Exception ex) {
            handleCacheException('PUT', key, ex);
            return false;
        }
    }
    
    public Boolean put(String cacheType, String key, Object value, String partition) {
        return put(cacheType, key, value, null, partition);
    }
    
    public Boolean remove(String cacheType, String key, String partition) {
        try {
            CacheValidator.validateKey(key);
            CacheValidator.validatePartitionName(partition);
            
            String fullKey = CacheKeyManager.buildFullKey(key, partition);
            
            if (cacheType == ORG_CACHE) {
                return Cache.Org.remove(fullKey);
            } else {
                return Cache.Session.remove(fullKey);
            }
        } catch (Exception ex) {
            handleCacheException('REMOVE', key, ex);
            return false;
        }
    }
    
    public Boolean contains(String cacheType, String key, String partition) {
        try {
            CacheValidator.validateKey(key);
            CacheValidator.validatePartitionName(partition);
            
            String fullKey = CacheKeyManager.buildFullKey(key, partition);
            
            if (cacheType == ORG_CACHE) {
                return Cache.Org.contains(fullKey);
            } else {
                return Cache.Session.contains(fullKey);
            }
        } catch (Exception ex) {
            handleCacheException('CONTAINS', key, ex);
            return false;
        }
    }
    
    public Set<String> getKeys(String cacheType, String partition) {
        CacheValidator.validatePartitionName(partition);
        String qualifiedPartition = 'local.' + partition;
        Set<String> keys = new Set<String>();
        
        if (cacheType == ORG_CACHE) {
            Cache.OrgPartition orgPartitionInstance = Cache.Org.getPartition(qualifiedPartition);
            keys = orgPartitionInstance.getKeys();
        } else {
            Cache.SessionPartition sessionPartitionInstance = Cache.Session.getPartition(qualifiedPartition);
            keys = sessionPartitionInstance.getKeys();
        }
        return keys;
    }
    
    /**
     * Gets dynamic SObject record from cache with type conversion
     */
    public SObject getDynamicRecord(String cacheType, String key, String partitionName, String sObjectTypeVal) {
        Object cachedVal = get(cacheType, key, partitionName);
        if (cachedVal == null){
            return null;
        }
        
        if (cachedVal instanceof SObject){
            return (SObject) cachedVal;
        }
        
        if (cachedVal instanceof String) {
            String jsonData = (String) cachedVal;
            Type sObjectType = Type.forName(sObjectTypeVal);
            return (SObject) JSON.deserialize(jsonData, sObjectType);
        }
        return null;
    }

    public void removeKeys(String cacheType, String partitionName) {
        try {
            CacheValidator.validatePartitionName(partitionName);
            Set<String> cachedKeys = PlatformCacheUtility.getKeys(cacheType, partitionName);
            if (!cachedKeys.isEmpty()) {
                for (String key : cachedKeys) {
                    PlatformCacheUtility.remove(cacheType, key, partitionName);
                }
            }
        } catch (Exception ex) {
            handleCacheException('REMOVEKEYS', partitionName, ex);
        }
    }
    
    private void handleCacheException(String operation, String key, Exception ex) {
        String errorMessage = String.format(CACHE_OPERATION_FAILED_FOR_KEY_AND_PARTITION_ERROR, 
            new List<String>{operation, key, ex.getMessage()});
        logError(errorMessage, ex);
    }
    
    private void logError(String message, Exception ex) {
        PlatformLog__c log = new PlatformLog__c(
            Error__c = message,
            InboundMessage__c = ex.getMessage(),
            StackTrace__c = ex.getStackTraceString()
        );
        
        Database.SaveResult result = Database.insert(log, false);
    }
}