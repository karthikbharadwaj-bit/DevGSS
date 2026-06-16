@IsTest
private class Test_CacheValidator {
    
    // Test data constants
    private static final String VALID_KEY = 'test_key_123';
    private static final String VALID_PARTITION = 'test_partition';
    private static final String VALID_VALUE = 'test_value';
    
    @IsTest
    static void validateKey_withValidKey_passesValidation() {
        // Given
        String validKey = VALID_KEY;
        
        // When & Then
        try {
            CacheValidator.validateKey(validKey);
            Assert.isTrue(true, 'Valid key should pass validation');
        } catch (CacheValidator.CacheValidationException e) {
            Assert.fail('Valid key should not throw exception: ' + e.getMessage());
        }
    }
    
    @IsTest
    static void validateKey_withNullKey_throwsException() {
        // Given
        String nullKey = null;
        
        // When & Then
        try {
            CacheValidator.validateKey(nullKey);
            Assert.fail('Null key should throw CacheValidationException');
        } catch (CacheValidator.CacheValidationException e) {
            Assert.isTrue(e.getMessage().contains('Cache key cannot be null or empty'), 
                'Exception message should indicate null/empty key');
        }
    }
    
    @IsTest
    static void validateKey_withEmptyKey_throwsException() {
        // Given
        String emptyKey = '';
        
        // When & Then
        try {
            CacheValidator.validateKey(emptyKey);
            Assert.fail('Empty key should throw CacheValidationException');
        } catch (CacheValidator.CacheValidationException e) {
            Assert.isTrue(e.getMessage().contains('Cache key cannot be null or empty'), 
                'Exception message should indicate null/empty key');
        }
    }
    
    @IsTest
    static void validateKey_withBlankKey_throwsException() {
        // Given
        String blankKey = '   ';
        
        // When & Then
        try {
            CacheValidator.validateKey(blankKey);
            Assert.fail('Blank key should throw CacheValidationException');
        } catch (CacheValidator.CacheValidationException e) {
            Assert.isTrue(e.getMessage().contains('Cache key cannot be null or empty'), 
                'Exception message should indicate null/empty key');
        }
    }
    
    @IsTest
    static void validateKey_withLongKey_throwsException() {
        // Given
        String longKey = 'a'.repeat(251); // Exceeds MAX_KEY_LENGTH of 250
        
        // When & Then
        try {
            CacheValidator.validateKey(longKey);
            Assert.fail('Long key should throw CacheValidationException');
        } catch (CacheValidator.CacheValidationException e) {
            Assert.isTrue(e.getMessage().contains('Cache key length exceeds maximum allowed length'), 
                'Exception message should indicate key length exceeded');
        }
    }
    
    @IsTest
    static void validateKey_withKeyContainingDoubleDots_throwsException() {
        // Given
        String invalidKey = 'test..key';
        
        // When & Then
        try {
            CacheValidator.validateKey(invalidKey);
            Assert.fail('Key with double dots should throw CacheValidationException');
        } catch (CacheValidator.CacheValidationException e) {
            Assert.isTrue(e.getMessage().contains('Cache key contains invalid characters or patterns'), 
                'Exception message should indicate invalid characters');
        }
    }
    
    @IsTest
    static void validateKey_withKeyStartingWithDot_throwsException() {
        // Given
        String invalidKey = '.testkey';
        
        // When & Then
        try {
            CacheValidator.validateKey(invalidKey);
            Assert.fail('Key starting with dot should throw CacheValidationException');
        } catch (CacheValidator.CacheValidationException e) {
            Assert.isTrue(e.getMessage().contains('Cache key contains invalid characters or patterns'), 
                'Exception message should indicate invalid characters');
        }
    }
    
    @IsTest
    static void validateKey_withKeyEndingWithDot_throwsException() {
        // Given
        String invalidKey = 'testkey.';
        
        // When & Then
        try {
            CacheValidator.validateKey(invalidKey);
            Assert.fail('Key ending with dot should throw CacheValidationException');
        } catch (CacheValidator.CacheValidationException e) {
            Assert.isTrue(e.getMessage().contains('Cache key contains invalid characters or patterns'), 
                'Exception message should indicate invalid characters');
        }
    }
    
    @IsTest
    static void validateValue_withValidValue_passesValidation() {
        // Given
        String validValue = VALID_VALUE;
        
        // When & Then
        try {
            CacheValidator.validateValue(validValue);
            Assert.isTrue(true, 'Valid value should pass validation');
        } catch (CacheValidator.CacheValidationException e) {
            Assert.fail('Valid value should not throw exception: ' + e.getMessage());
        }
    }
    
    @IsTest
    static void validateValue_withNullValue_throwsException() {
        // Given
        Object nullValue = null;
        
        // When & Then
        try {
            CacheValidator.validateValue(nullValue);
            Assert.fail('Null value should throw CacheValidationException');
        } catch (CacheValidator.CacheValidationException e) {
            Assert.isTrue(e.getMessage().contains('Cache value cannot be null'), 
                'Exception message should indicate null value');
        }
    }
    
    @IsTest
    static void validateValue_withLargeValue_throwsException() {
        // Given
        String largeValue = 'x'.repeat(50001); // Exceeds MAX_VALUE_SIZE_BYTES of 100000 when serialized
        
        // When & Then
        try {
            CacheValidator.validateValue(largeValue);
            Assert.fail('Large value should throw CacheValidationException');
        } catch (CacheValidator.CacheValidationException e) {
            Assert.isTrue(e.getMessage().contains('Cache value size exceeds maximum allowed size'), 
                'Exception message should indicate value size exceeded');
        }
    }
    
    @IsTest
    static void validateValue_withComplexObject_passesValidation() {
        // Given
        Map<String, Object> complexObject = new Map<String, Object>{
            'name' => 'test',
            'value' => 123,
            'list' => new List<String>{'item1', 'item2'}
        };
        
        // When & Then
        try {
            CacheValidator.validateValue(complexObject);
            Assert.isTrue(true, 'Complex object should pass validation');
        } catch (CacheValidator.CacheValidationException e) {
            Assert.fail('Complex object should not throw exception: ' + e.getMessage());
        }
    }
    
    @IsTest
    static void validatePartitionName_withValidPartition_passesValidation() {
        // Given
        String validPartition = VALID_PARTITION;
        
        // When & Then
        try {
            CacheValidator.validatePartitionName(validPartition);
            Assert.isTrue(true, 'Valid partition should pass validation');
        } catch (CacheValidator.CacheValidationException e) {
            Assert.fail('Valid partition should not throw exception: ' + e.getMessage());
        }
    }
    
    @IsTest
    static void validatePartitionName_withEmptyPartition_passesValidation() {
        // Given
        String emptyPartition = '';
        
        // When & Then
        try {
            CacheValidator.validatePartitionName(emptyPartition);
            Assert.isTrue(true, 'Empty partition should pass validation');
        } catch (CacheValidator.CacheValidationException e) {
            Assert.fail('Empty partition should not throw exception: ' + e.getMessage());
        }
    }
    
    @IsTest
    static void validatePartitionName_withNullPartition_throwsException() {
        // Given
        String nullPartition = null;
        
        // When & Then
        try {
            CacheValidator.validatePartitionName(nullPartition);
            Assert.fail('Null partition should throw CacheValidationException');
        } catch (CacheValidator.CacheValidationException e) {
            Assert.isTrue(e.getMessage().contains('Cache partition cannot be null'), 
                'Exception message should indicate null partition');
        }
    }
    
    @IsTest
    static void validateLocalCacheLimit_withOrgCacheAndValidValue_passesValidation() {
        // Given
        String cacheType = CacheValidator.ORG_CACHE;
        String validValue = VALID_VALUE;
        
        // When & Then
        try {
            CacheValidator.validateLocalCacheLimit(cacheType, validValue);
            Assert.isTrue(true, 'Valid value for org cache should pass validation');
        } catch (CacheValidator.CacheValidationException e) {
            Assert.fail('Valid value for org cache should not throw exception: ' + e.getMessage());
        }
    }
    
    @IsTest
    static void validateLocalCacheLimit_withSessionCacheAndValidValue_passesValidation() {
        // Given
        String cacheType = CacheValidator.SESSION_CACHE;
        String validValue = VALID_VALUE;
        
        // When & Then
        try {
            CacheValidator.validateLocalCacheLimit(cacheType, validValue);
            Assert.isTrue(true, 'Valid value for session cache should pass validation');
        } catch (CacheValidator.CacheValidationException e) {
            Assert.fail('Valid value for session cache should not throw exception: ' + e.getMessage());
        }
    }
    
    @IsTest
    static void validateLocalCacheLimit_withOrgCacheAndLargeValue_throwsException() {
        // Given
        String cacheType = CacheValidator.ORG_CACHE;
        String largeValue = 'x'.repeat(500001); // Exceeds LOCAL_CACHE_LIMIT_ORG of 1000000 when serialized
        
        // When & Then
        try {
            CacheValidator.validateLocalCacheLimit(cacheType, largeValue);
            Assert.fail('Large value for org cache should throw CacheValidationException');
        } catch (CacheValidator.CacheValidationException e) {
            Assert.isTrue(e.getMessage().contains('exceeds local cache limit'), 
                'Exception message should indicate cache limit exceeded');
            Assert.isTrue(e.getMessage().contains('ORG_CACHE'), 
                'Exception message should mention cache type');
        }
    }
    
    @IsTest
    static void validateLocalCacheLimit_withSessionCacheAndLargeValue_throwsException() {
        // Given
        String cacheType = CacheValidator.SESSION_CACHE;
        String largeValue = 'x'.repeat(250001); // Exceeds LOCAL_CACHE_LIMIT_SESSION of 500000 when serialized
        
        // When & Then
        try {
            CacheValidator.validateLocalCacheLimit(cacheType, largeValue);
            Assert.fail('Large value for session cache should throw CacheValidationException');
        } catch (CacheValidator.CacheValidationException e) {
            Assert.isTrue(e.getMessage().contains('exceeds local cache limit'), 
                'Exception message should indicate cache limit exceeded');
            Assert.isTrue(e.getMessage().contains('SESSION_CACHE'), 
                'Exception message should mention cache type');
        }
    }
    
    @IsTest
    static void validateCollectionSize_withValidSize_passesValidation() {
        // Given
        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < 100; i++) {
            accounts.add(new Account(Name = 'Test Account ' + i));
        }
        
        // When & Then
        try {
            CacheValidator.validateCollectionSize(accounts);
            Assert.isTrue(true, 'Valid collection size should pass validation');
        } catch (CacheValidator.CacheValidationException e) {
            Assert.fail('Valid collection size should not throw exception: ' + e.getMessage());
        }
    }
    
    @IsTest
    static void validateCollectionSize_withNullCollection_passesValidation() {
        // Given
        List<Account> nullCollection = null;
        
        // When & Then
        try {
            CacheValidator.validateCollectionSize(nullCollection);
            Assert.isTrue(true, 'Null collection should pass validation');
        } catch (CacheValidator.CacheValidationException e) {
            Assert.fail('Null collection should not throw exception: ' + e.getMessage());
        }
    }
    
    @IsTest
    static void validateCollectionSize_withLargeCollection_throwsException() {
        // Given
        List<Account> largeCollection = new List<Account>();
        for (Integer i = 0; i < 1001; i++) { // Exceeds MAX_COLLECTION_SIZE of 1000
            largeCollection.add(new Account(Name = 'Test Account ' + i));
        }
        
        // When & Then
        try {
            CacheValidator.validateCollectionSize(largeCollection);
            Assert.fail('Large collection should throw CacheValidationException');
        } catch (CacheValidator.CacheValidationException e) {
            Assert.isTrue(e.getMessage().contains('Collection size'), 
                'Exception message should mention collection size');
            Assert.isTrue(e.getMessage().contains('exceeds recommended maximum'), 
                'Exception message should indicate size exceeded');
        }
    }
    
    @IsTest
    static void validateCollectionSize_withExactMaxSize_passesValidation() {
        // Given
        List<Account> maxSizeCollection = new List<Account>();
        for (Integer i = 0; i < 1000; i++) { // Exactly MAX_COLLECTION_SIZE
            maxSizeCollection.add(new Account(Name = 'Test Account ' + i));
        }
        
        // When & Then
        try {
            CacheValidator.validateCollectionSize(maxSizeCollection);
            Assert.isTrue(true, 'Collection at max size should pass validation');
        } catch (CacheValidator.CacheValidationException e) {
            Assert.fail('Collection at max size should not throw exception: ' + e.getMessage());
        }
    }
}