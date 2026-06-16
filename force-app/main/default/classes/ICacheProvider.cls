/**
 * Interface for cache provider operations
 * Follows Interface Segregation Principle - focused on core cache operations
 */
public interface ICacheProvider {
    Object get(String cacheType, String key, String partition);
    Boolean put(String cacheType, String key, Object value, Integer ttlSeconds, String partition);
    Boolean put(String cacheType, String key, Object value, String partition);
    Boolean remove(String cacheType, String key, String partition);
    Boolean contains(String cacheType, String key, String partition);
    Set<String> getKeys(String cacheType, String partition);
    SObject getDynamicRecord(String cacheType, String key, String partitionName, String sObjectTypeVal);
    void removeKeys(String cacheType, String partitionName);
}