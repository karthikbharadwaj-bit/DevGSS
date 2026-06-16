/**
 * Bulk cache operations utility
 * Follows Single Responsibility Principle - handles bulk cache operations
 * Implements best practice of grouping cache requests
 */
public with sharing class BulkCacheOperations {
    
    private ICacheProvider cacheProvider;
    
    public BulkCacheOperations(ICacheProvider provider) {
        this.cacheProvider = provider;
    }
    
    /**
     * Gets multiple cache values in a single operation
     * Follows best practice of grouping cache requests
     */
    public Map<String, Object> getBulk(String cacheType, Set<String> keys, String partition) {
        Map<String, Object> results = new Map<String, Object>();
        if(!keys.isEmpty()){
            for (String key : keys) {
                Object value = cacheProvider.get(cacheType, key, partition);
                if (value != null) {
                    results.put(key, value);
                }
            }
        }
        return results;
    }
    
    /**
     * Puts multiple cache values with same TTL
     */
    public Boolean putBulk(String cacheType, Map<String, Object> keyValuePairs, String partition, Integer ttlSeconds) {
        Boolean allSuccessful = true;
        if(!keyValuePairs.isEmpty()){
            for (String key : keyValuePairs.keySet()) {
                if (!cacheProvider.put(cacheType, key, keyValuePairs.get(key), ttlSeconds, partition)) {
                    allSuccessful = false;
                }
            }
        }
        return allSuccessful;
    }
    
    /**
     * Puts multiple cache values without TTL
     */
    public Boolean putBulk(String cacheType, Map<String, Object> keyValuePairs, String partition) {
        return putBulk(cacheType, keyValuePairs, partition, null);
    }
    
    /**
     * Puts multiple cache values with individual TTLs
     */
    public Map<String, Boolean> putBulkWithTTLs(String cacheType, Map<String, Object> keyValuePairs, 
                                                Map<String, Integer> keyTTLMap, String partition) {
        Map<String, Boolean> results = new Map<String, Boolean>();
        if(!keyValuePairs.isEmpty()){
            for (String key : keyValuePairs.keySet()) {
                Integer ttl = keyTTLMap.get(key);
                Boolean success = cacheProvider.put(cacheType, key, keyValuePairs.get(key), ttl, partition);
                results.put(key, success);
            }
        }
        return results;
    }
    
    /**
     * Removes multiple cache entries
     */
    public Map<String, Boolean> removeBulk(String cacheType, Set<String> keys, String partition) {
        Map<String, Boolean> results = new Map<String, Boolean>();
        if(!keys.isEmpty()){
            for (String key : keys) {
                results.put(key, cacheProvider.remove(cacheType, key, partition));
            }
        }
        return results;
    }
    
    /**
     * Checks if multiple keys exist in cache
     */
    public Map<String, Boolean> containsBulk(String cacheType, Set<String> keys, String partition) {
        Map<String, Boolean> results = new Map<String, Boolean>();
        if(!keys.isEmpty()){
            for (String key : keys) {
                results.put(key, cacheProvider.contains(cacheType, key, partition));
            }
        }
        return results;
    }
    
    /**
     * Caches entire collection - follows best practice of caching larger items
     */
    public Boolean putCollection(String cacheType, String key, List<SObject> records, String partition, Integer ttlSeconds) {
        CacheValidator.validateCollectionSize(records);
        return cacheProvider.put(cacheType, key, records, ttlSeconds, partition);
    }
    
    /**
     * Caches collection without TTL
     */
    public Boolean putCollection(String cacheType, String key, List<SObject> records, String partition) {
        return putCollection(cacheType, key, records, partition, null);
    }
    
    /**
     * Gets cached collection
     */
    public List<SObject> getCollection(String cacheType, String key, String partition) {
        Object cachedVal = cacheProvider.get(cacheType, key, partition);
        if (cachedVal instanceof List<SObject>) {
            return (List<SObject>) cachedVal;
        }
        return null;
    }
    
    /**
     * Caches multiple collections efficiently
     */
    public Map<String, Boolean> putMultipleCollections(String cacheType, Map<String, List<SObject>> collections, 
                                                       String partition, Integer ttlSeconds) {
        Map<String, Boolean> results = new Map<String, Boolean>();
        if(!collections.isEmpty()){
            for (String key : collections.keySet()) {
                List<SObject> collection = collections.get(key);
                results.put(key, putCollection(cacheType, key, collection, partition, ttlSeconds));
            }
        }
        return results;
    }
    
    /**
     * Gets multiple collections
     */
    public Map<String, List<SObject>> getMultipleCollections(String cacheType, Set<String> keys, String partition) {
        Map<String, List<SObject>> results = new Map<String, List<SObject>>();
        if(!keys.isEmpty()){
            for (String key : keys) {
                List<SObject> collection = getCollection(cacheType, key, partition);
                if (collection != null) {
                    results.put(key, collection);
                }
            }
        }
        return results;
    }
    
    /**
     * Refreshes multiple cache entries using a builder
     */
    public Map<String, Object> refreshBulk(String cacheType, Set<String> keys, String partition, 
                                          ICacheBuilder builder, Integer ttlSeconds) {
        Map<String, Object> results = new Map<String, Object>();
        if(!keys.isEmpty()){
            for (String key : keys) {
                // Remove old value
                cacheProvider.remove(cacheType, key, partition);
                
                // Build new value
                Object newValue = builder.buildValue(key);
                if (newValue != null) {
                    cacheProvider.put(cacheType, key, newValue, ttlSeconds, partition);
                    results.put(key, newValue);
                }
            }
        }
        return results;
    }
}