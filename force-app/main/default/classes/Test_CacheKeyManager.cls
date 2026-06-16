@IsTest
private class Test_CacheKeyManager {
    
    @IsTest
    static void generateOptimalKey_withShortParams_returnsConcatenated() {
        // Given
        String baseKey = 'base';
        List<String> params = new List<String>{'p1','p2','p3'};

        // When
        String result = CacheKeyManager.generateOptimalKey(baseKey, params);

        // Then
        Assert.areEqual('base_p1_p2_p3', result, 'Should concatenate base and params with underscores');
    }

    @IsTest
    static void generateOptimalKey_withLongParams_returnsBasePlusHash() {
        // Given
        String baseKey = 'base';
        String longParam = '';
        for (Integer i = 0; i < 260; i++) {
            longParam += 'x';
        }
        List<String> params = new List<String>{longParam};

        // When
        String result = CacheKeyManager.generateOptimalKey(baseKey, params);

        // Then
        String combined = baseKey + '_' + String.join(params, '_');
        String expected = baseKey + '_' + EncodingUtil.convertToHex(Crypto.generateDigest('MD5', Blob.valueOf(combined))).substring(0, 8);
        Assert.areEqual(expected, result, 'Should hash long keys and return baseKey_hash8');
        Assert.isTrue(result.length() <= 250, 'Resulting key must honor max length');
    }

    @IsTest
    static void generateOptimalKey_singleParameter_matchesListVariant() {
        // Given
        String baseKey = 'myBase';
        String param = 'onlyOne';

        // When
        String resultSingle = CacheKeyManager.generateOptimalKey(baseKey, param);
        String resultList = CacheKeyManager.generateOptimalKey(baseKey, new List<String>{param});

        // Then
        Assert.areEqual(resultList, resultSingle, 'Single-parameter overload should delegate to list variant');
    }

    @IsTest
    static void buildFullKey_withValidInputs_returnsPrefixedKey() {
        // Given
        String key = 'k1';
        String partition = 'Default';

        // When
        String fullKey = CacheKeyManager.buildFullKey(key, partition);

        // Then
        Assert.areEqual('local.' + partition + '.' + key, fullKey, 'Should prefix with local.<partition>.');
    }

    @IsTest
    static void extractOriginalKey_withMatchingPartition_returnsOriginal() {
        // Given
        String key = 'originalKey';
        String partition = 'Default';
        String fullKey = 'local.' + partition + '.' + key;

        // When
        String extracted = CacheKeyManager.extractOriginalKey(fullKey, partition);

        // Then
        Assert.areEqual(key, extracted, 'Should remove local.<partition>. prefix');
    }

    @IsTest
    static void extractOriginalKey_withNonMatchingPartition_returnsUnchanged() {
        // Given
        String fullKey = 'local.someOtherPartition.keyABC';

        // When
        String extracted = CacheKeyManager.extractOriginalKey(fullKey, 'Default');

        // Then
        Assert.areEqual(fullKey, extracted, 'Should return input when prefix does not match');
    }

    @IsTest
    static void isValidKeyFormat_withValidKey_returnsTrue() {
        // Given
        String key = 'valid_key_123';

        // When
        Boolean ok = CacheKeyManager.isValidKeyFormat(key);

        // Then
        Assert.isTrue(ok, 'Expected valid key format to return true');
    }

    @IsTest
    static void isValidKeyFormat_withNullOrEmpty_returnsFalse() {
        // Given / When
        Boolean nullOk = CacheKeyManager.isValidKeyFormat(null);
        Boolean emptyOk = CacheKeyManager.isValidKeyFormat('');

        // Then
        Assert.isFalse(nullOk, 'Null key should be invalid');
        Assert.isFalse(emptyOk, 'Empty key should be invalid');
    }
}