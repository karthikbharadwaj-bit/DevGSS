/**
 * Cache validation utility class
 * Follows Single Responsibility Principle - handles all validation logic
 */
public with sharing class CacheValidator {
    
    // Constants for validation
    private static final Integer MAX_KEY_LENGTH = 250;
    private static final Integer MAX_VALUE_SIZE_BYTES = 100000; // 100KB
    private static final Integer LOCAL_CACHE_LIMIT_SESSION = 500000; // 500KB
    private static final Integer LOCAL_CACHE_LIMIT_ORG = 1000000;    // 1MB
    private static final Integer MAX_COLLECTION_SIZE = 1000;
    
    // Cache Type Constants
    public static final String ORG_CACHE = 'ORG_CACHE';
    public static final String SESSION_CACHE = 'SESSION_CACHE';
    
    // Error message constants
    private static final String CACHE_KEY_CANNOT_BE_NULL_OR_EMPTY = 'Cache key cannot be null or empty';
    private static final String CACHE_KEY_LENGTH_EXCEEDS_MAXIMUM_ALLOWED_LENGTH = 'Cache key length exceeds maximum allowed length of {0}';
    private static final String CACHE_KEY_CONTAINS_INVALID_CHARACTERS_OR_PATTERNS = 'Cache key contains invalid characters or patterns';
    private static final String CACHE_VALUE_CANNOT_BE_NULL = 'Cache value cannot be null';
    private static final String CACHE_PARTITION_CANNOT_BE_NULL = 'Cache partition cannot be null';
    private static final String CACHE_VALUE_SIZE_EXCEEDS_MAXIMUM_ALLOWED_SIZE = 'Cache value size exceeds maximum allowed size of {0} bytes';
    
    // Custom Exception
    public class CacheValidationException extends Exception {}
    
    public static void validateKey(String key) {
        if (String.isBlank(key)) {
            throw new CacheValidationException(CACHE_KEY_CANNOT_BE_NULL_OR_EMPTY);
        }
        
        if (key.length() > MAX_KEY_LENGTH) {
            throw new CacheValidationException(String.format(CACHE_KEY_LENGTH_EXCEEDS_MAXIMUM_ALLOWED_LENGTH, 
                new List<String>{String.valueOf(MAX_KEY_LENGTH)}));
        }
        
        // Check for invalid characters
        if (key.contains('..') || key.startsWith('.') || key.endsWith('.')) {
            throw new CacheValidationException(CACHE_KEY_CONTAINS_INVALID_CHARACTERS_OR_PATTERNS);
        }
    }
    
    public static void validateValue(Object value) {
        if (value == null) {
            throw new CacheValidationException(CACHE_VALUE_CANNOT_BE_NULL);
        }
        
        Long estimatedSize = estimateValueSize(value);
        if (estimatedSize > MAX_VALUE_SIZE_BYTES) {
            throw new CacheValidationException(String.format(CACHE_VALUE_SIZE_EXCEEDS_MAXIMUM_ALLOWED_SIZE, 
                new List<String>{String.valueOf(MAX_VALUE_SIZE_BYTES)}));
        }
    }
    
    public static void validatePartitionName(String partition) {
        if (partition == null) {
            throw new CacheValidationException(CACHE_PARTITION_CANNOT_BE_NULL);
        }
    }
    
    public static void validateLocalCacheLimit(String cacheType, Object value) {
        Long estimatedSize = estimateValueSize(value);
        Integer cacheLimit = cacheType == ORG_CACHE ? LOCAL_CACHE_LIMIT_ORG : LOCAL_CACHE_LIMIT_SESSION;
        
        if (estimatedSize > cacheLimit) {
            throw new CacheValidationException('Value size (' + estimatedSize + ' bytes) exceeds local cache limit (' 
                + cacheLimit + ' bytes) for ' + cacheType);
        }
    }
    
    public static void validateCollectionSize(List<SObject> records) {
        if (records != null && records.size() > MAX_COLLECTION_SIZE) {
            throw new CacheValidationException('Collection size (' + records.size() + ') exceeds recommended maximum (' 
                + MAX_COLLECTION_SIZE + '). Consider breaking into smaller chunks.');
        }
    }
    
    private static Long estimateValueSize(Object value) {
        String serialized = JSON.serialize(value);
        return (Long) serialized.length() * 2;
    }
}