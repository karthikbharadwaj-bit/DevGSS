/**
 * Cache key management utility
 * Follows Single Responsibility Principle - handles key generation and formatting
 */
public with sharing class CacheKeyManager {
    
    private static final Integer MAX_KEY_LENGTH = 250;
    private static final String LOCAL_PREFIX = 'local.';
    
    /**
     * Generates an optimal cache key from base key and parameters
     * Automatically handles key length limits with hashing
     */
    public static String generateOptimalKey(String baseKey, List<String> parameters) {
        String combinedKey = baseKey + '_' + String.join(parameters, '_');
        
        if (combinedKey.length() > MAX_KEY_LENGTH) {
            // Create hash for long keys to keep them under limit
            Blob keyBlob = Blob.valueOf(combinedKey);
            String hash = EncodingUtil.convertToHex(Crypto.generateDigest('MD5', keyBlob)).substring(0, 8);
            return baseKey + '_' + hash;
        }
        
        return combinedKey;
    }
    
    /**
     * Generates optimal key with single parameter
     */
    public static String generateOptimalKey(String baseKey, String parameter) {
        return generateOptimalKey(baseKey, new List<String>{parameter});
    }
    
    /**
     * Builds full cache key with partition prefix
     */
    public static String buildFullKey(String key, String partition) {
        return LOCAL_PREFIX + partition + '.' + key;
    }
    
    /**
     * Extracts the original key from a full cache key
     */
    public static String extractOriginalKey(String fullKey, String partition) {
        String prefix = LOCAL_PREFIX + partition + '.';
        if (fullKey.startsWith(prefix)) {
            return fullKey.substring(prefix.length());
        }
        return fullKey;
    }
    
    /**
     * Validates if a key is properly formatted
     */
    public static Boolean isValidKeyFormat(String key) {
        try {
            CacheValidator.validateKey(key);
            return true;
        } catch (Exception ex) {
            return false;
        }
    }
}