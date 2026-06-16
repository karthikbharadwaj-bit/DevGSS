@isTest
private class Test_StringHelper {
    private static final String TEST_STRING = 'This is a test string';

    @isTest
    static void testAsNumber() {
        Decimal testNumber = 120000.00;
        String strResult = String.valueOf(StringHelper.asNumber(testNumber, 3));

        System.assertEquals('120,000.000', strResult,
            'Bad convert number with precision to string');
    }

    @isTest
    static void testAsNumberNoParam() {
        Decimal testNumber = 120000.00;
        String strResult = String.valueOf(StringHelper.asNumber(testNumber, 2));

        System.assertEquals('120,000.00', strResult,
            'Bad convert number with precision to string');
    }

    @isTest
    static void testAsNumberNegParam() {
        Decimal testNumber = 120000.00;
        String strResult = String.valueOf(StringHelper.asNumber(testNumber, 0));

        System.assertEquals('120,000', strResult,
            'Bad convert number with precision to string');
    }

    @isTest
    static void testConvertListOfStringsToStringInvalidListOfStrings() {
        List<String> invalidListOfStrings = null;
        String validDelimeter = 'delimeter';
        Boolean isAddLastDelimeter = true;

        System.assertEquals(StringHelper.convertListOfStringsToString(invalidListOfStrings, validDelimeter, isAddLastDelimeter),
            '', 'If null List of Strings passed to the method - should return empty value');

        invalidListOfStrings = new List<String>();
        System.assertEquals(StringHelper.convertListOfStringsToString(invalidListOfStrings, validDelimeter, isAddLastDelimeter),
            '', 'If empty List of Strings passed to the method - should return empty value');
    }

    @isTest
    static void testConvertListOfStringsToStringInvalidDelimeter() {
        List<String> validListOfStrings = new List<String> {
            'str1',
            'str2'
        };

        String invalidDelimeter = null;
        Boolean isAddLastDelimeter = true;
        try {
            StringHelper.convertListOfStringsToString(validListOfStrings, invalidDelimeter, isAddLastDelimeter);
            System.assert(false, 'Expecting Parameter should not be null error');
        } catch (AquivaHelper.AquivaException e) {
            System.assertEquals(StringHelper.MESSAGE_PARAMETER_NULL, e.getMessage(),
                'Passing null delimeter should result in parameter not null exception');
        }
    }

    @isTest
    static void testConvertListOfStringsToStringInvalidIsAddLastDelimeter() {
        List<String> validListOfStrings = new List<String> {
            'str1',
            'str2'
        };

        String validDelimeter = 'delimeter';
        Boolean isAddLastDelimeter = null;
        try {
            StringHelper.convertListOfStringsToString(validListOfStrings, validDelimeter, isAddLastDelimeter);
            System.assert(false, 'Expecting Parameter should not be null error');
        } catch (AquivaHelper.AquivaException e) {
            System.assertEquals(StringHelper.MESSAGE_PARAMETER_NULL, e.getMessage(),
                'Passing null isAddLastDelimeter should result in parameter not null exception');
        }
    }

    @isTest
    static void testConvertListOfStringsToStringOneEntryInListOfString() {
        String entry1 = 'str1';
        List<String> validListOfStrings = new List<String> {
            entry1
        };

        String validDelimeter = 'delimeter';
        Boolean isAddLastDelimeter = false;

        System.assertEquals(
            StringHelper.convertListOfStringsToString(validListOfStrings, validDelimeter, isAddLastDelimeter),
            entry1, 'str1 should be without delimeter');

        isAddLastDelimeter = true;
        System.assertEquals(
            StringHelper.convertListOfStringsToString(validListOfStrings, validDelimeter, isAddLastDelimeter),
            entry1 + validDelimeter, 'str1 should be with delimeter');


        validDelimeter = '';
        isAddLastDelimeter = false;

        System.assertEquals(
            StringHelper.convertListOfStringsToString(validListOfStrings, validDelimeter, isAddLastDelimeter),
            entry1, 'str1 should be the same because of empty delimeter');

        isAddLastDelimeter = true;
        System.assertEquals(
            StringHelper.convertListOfStringsToString(validListOfStrings, validDelimeter, isAddLastDelimeter),
            entry1 + validDelimeter, 'str1 should be the same because of empty delimeter');


        validDelimeter = '1';
        isAddLastDelimeter = false;
        System.assertEquals(
            StringHelper.convertListOfStringsToString(validListOfStrings, validDelimeter, isAddLastDelimeter),
            entry1, 'str1 should be without delimeter');

        isAddLastDelimeter = true;
        System.assertEquals(
            StringHelper.convertListOfStringsToString(validListOfStrings, validDelimeter, isAddLastDelimeter),
            entry1 + validDelimeter, 'str1 should be with delimeter');
    }

    @isTest
    static void testConvertListOfStringsToStringTwoEntriesInListOfString() {
        String entry1 = 'str1';
        String entry2 = 'str2';
        List<String> validListOfStrings = new List<String> {
            entry1,
            entry2
        };

        String validDelimeter = 'delimeter';
        Boolean isAddLastDelimeter = false;

        System.assertEquals(
            StringHelper.convertListOfStringsToString(validListOfStrings, validDelimeter, isAddLastDelimeter),
            entry1 + validDelimeter + entry2, 'no ending delimeter should be');

        isAddLastDelimeter = true;
        System.assertEquals(
            StringHelper.convertListOfStringsToString(validListOfStrings, validDelimeter, isAddLastDelimeter),
            entry1 + validDelimeter + entry2 + validDelimeter, 'should be ending delimeter');


        validDelimeter = '';
        isAddLastDelimeter = false;

        System.assertEquals(
            StringHelper.convertListOfStringsToString(validListOfStrings, validDelimeter, isAddLastDelimeter),
            entry1 + entry2, 'should be the same because of empty delimeter');

        isAddLastDelimeter = true;
        System.assertEquals(
            StringHelper.convertListOfStringsToString(validListOfStrings, validDelimeter, isAddLastDelimeter),
            entry1 + entry2, 'should be the same because of empty delimeter');


        validDelimeter = '1';
        isAddLastDelimeter = false;
        System.assertEquals(
            StringHelper.convertListOfStringsToString(validListOfStrings, validDelimeter, isAddLastDelimeter),
            entry1 + validDelimeter + entry2, 'should be without ending delimeter');

        isAddLastDelimeter = true;
        System.assertEquals(
            StringHelper.convertListOfStringsToString(validListOfStrings, validDelimeter, isAddLastDelimeter),
            entry1 + validDelimeter + entry2 + validDelimeter, 'should be with ending delimeter');
    }

    @isTest
    static void testGetRandomString() {
        String testStr;

        try {
            testStr = StringHelper.getRandomString(null);
            System.assert(false, 'exception should be thrown, as parameter is invalid');
        } catch (Exception e) {
            System.assert(e.getMessage().containsIgnoreCase(StringHelper.MESSAGE_PARAMETER_NULL),
                'Should be a different error message');
        }

        testStr = StringHelper.getRandomString(1);
        System.assertEquals(1, testStr.length(), 'String length should be 1');
        System.assert(!String.isBlank(testStr), 'String should be not blank');

        testStr = StringHelper.getRandomString(10);
        System.assertEquals(10, testStr.length(), 'String length should be 10');
    }

    @isTest
    static void testSafeSubstringWithInboundSize() {
        Integer substringLength = TEST_STRING.length() - 1;
        String expectedString = TEST_STRING.substring(0, substringLength);
        System.assertEquals(expectedString, StringHelper.safeSubstring(TEST_STRING, substringLength),
            'Substring should be: ' + expectedString);
    }

    @isTest
    static void testSafeSubstringWithOutboundSize() {
        Integer substringLength = TEST_STRING.length() + 1;
        System.assertEquals(TEST_STRING, StringHelper.safeSubstring(TEST_STRING, substringLength),
            'Substring should be: ' + TEST_STRING);
    }

    @isTest
    static void testSafeSubstringWithNullString() {
        String str;
        Integer substringLength = 10;
        System.assertEquals(null, StringHelper.safeSubstring(str, substringLength),
            'Substring should be: null');
    }

    @isTest
    static void testConvertListOfStringsToString() {
        List<String> listStrings = new List<String> {
            'String 0',
            'String 1',
            'String 2'
        };
        String expectedString = 'String 0;String 1;String 2';
        System.assertEquals(expectedString, StringHelper.convertListOfStringsToString(listStrings),
            'Bad convert list of strings to string');
    }

    @isTest
    static void testConvertStringToSetOfStrings() {
        String str = '[\"String 0\", \"String 1\", \"String 0\"]';
        Set<String> expectedSetOfStrings = new Set<String> {
            'String 0',
            'String 1'
        };
        System.assertEquals(expectedSetOfStrings, StringHelper.convertStringToSetOfStrings(str),
            'Bad convert string to set of strings');
    }

    @isTest
    static void testConvertBlankStringToSetOfStrings() {
        String str = '';
        Set<String> expectedSetOfStrings = new Set<String> ();
        System.assertEquals(expectedSetOfStrings, StringHelper.convertStringToSetOfStrings(str),
            'Should be empty set of string');
    }

    @isTest
    static void testConvertIncorrectStringToSetOfStrings() {
        String str = 'Incorrect json string';
        try {
            Set<String> expectedSetOfStrings = StringHelper.convertStringToSetOfStrings(str);
        } catch (Exception e) {
            System.assert(e.getMessage().containsIgnoreCase('Cannot parse set of Strings. Error: '),
                'Should be a different error message');
        }
    }

    @isTest
    static void testValidateStrict() {
        String strToValidate;
        String exceptionMessage = 'This string is blank';
        try {
            StringHelper.validateStrict(strToValidate, exceptionMessage);
        } catch (Exception e) {
            System.assertEquals(exceptionMessage, e.getMessage(), 'Should be a different error message');
        }
    }

    @isTest
    static void testDefaultString() {
        String value = 'some test value';
        System.assertEquals(value, StringHelper.defaultString(value, 'test'), 'Original value should be returned.');
        System.assertEquals('null', StringHelper.defaultString(null, 'null'), 'Non-default value returned.');
        System.assertEquals('    ', StringHelper.defaultString(null, '    '), 'Non-default value returned.');
        System.assertEquals(null, StringHelper.defaultString(null, null), 'Non-default value returned.');
    }

    @isTest
    static void testSafeString() {
        Object obj;
        System.assertEquals('', StringHelper.safeString(obj), 'String should be empty');

        obj = TEST_STRING;
        System.assertEquals(TEST_STRING, StringHelper.safeString(obj),
            'String should be: ' + TEST_STRING);
    }

    @isTest
    static void testAsInteger() {
        String str;
        System.assertEquals(null, StringHelper.asInteger(str), 'Integer should be null');

        str = '100';
        System.assertEquals(100, StringHelper.asInteger(str), 'Integer should be 100');
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    private static void testSafeSplit() {
        assertSafeSplit(0, null);
        assertSafeSplit(1, '_');
        assertSafeSplit(2, 'asdf;qwer');
        assertSafeSplit(2, ';zxcv');
        assertSafeSplit(3, 'asdf;;qwer');
    }

    private static void assertSafeSplit(Integer expectedResultSize, String strToSplit){
        System.assertEquals(expectedResultSize, StringHelper.safeSplit(strToSplit, ';').size(),
            'Wrong split result for string: ' + strToSplit);
    }

    @isTest
    static void testSafeSplitStringByNewLine() {
        String str;
        List<String> expectedStringList = new List<String>();
        System.assertEquals(expectedStringList, StringHelper.safeSplitStringByNewLine(str),
            'Should be empty string list');
        System.assertEquals(0, StringHelper.safeSplitStringByNewLine(str).size(),
            'Should be string list with size = 0');

        str = 'test';
        expectedStringList.add('test');
        System.assertEquals(expectedStringList, StringHelper.safeSplitStringByNewLine(str),
            'Should not be different string list');
        System.assertEquals(1, StringHelper.safeSplitStringByNewLine(str).size(),
            'Should be string list with size = 1');

        str = 'test\n' +
            'test2';
        expectedStringList.add('test2');
        System.assertEquals(expectedStringList, StringHelper.safeSplitStringByNewLine(str),
            'Should not be different string list');
        System.assertEquals(2, StringHelper.safeSplitStringByNewLine(str).size(),
            'Should be string list with size = 2');
    }

    @isTest
    static void testConstructAddress() {
        String POSTAL_CODE = '777777';
        String CITY = 'Some City';
        String STATE = 'Some State';
        String COUNTRY = 'Some Country';

        new SObjectBuilder(Account.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(Account.SObjectType))
            .setFields(
                new Map<SObjectField, Object>{
                    Account.BillingPostalCode => POSTAL_CODE,
                    Account.BillingCity => CITY,
                    Account.BillingState => STATE,
                    Account.BillingCountry => COUNTRY})
            .create();

        Account acc = (Account) new AccountSelector()
            .selectAccounts()
            .selectField('BillingAddress')
            .executeQuery()
            .get(0);

        String actualAddress = StringHelper.constructAddress(acc.BillingAddress);
        String expectedAddress = POSTAL_CODE + ', ' + CITY + ', ' + STATE + ', ' + COUNTRY;
        System.assertEquals(expectedAddress, actualAddress, 'Address string was not constructed correctly');
        System.assertEquals('', StringHelper.constructAddress(null), 'Address string was not constructed correctly');
    }

    @isTest
    static void testGetSafeLengthString() {
        Integer arbitraryMaxLength = 20;
        String lessThanMaxLenString = StringHelper.getRandomString(arbitraryMaxLength - 1);
        String maxLenString = StringHelper.getRandomString(arbitraryMaxLength);
        String moreThanMaxLenString = StringHelper.getRandomString(arbitraryMaxLength + 1);
        Test.startTest();
            String resultForLessThanMaxLenString = StringHelper.getSafeLengthString(lessThanMaxLenString, arbitraryMaxLength);
            String resultForMaxLenString = StringHelper.getSafeLengthString(maxLenString, arbitraryMaxLength);
            String resultForMoreThanMaxLenString = StringHelper.getSafeLengthString(moreThanMaxLenString, arbitraryMaxLength);
        Test.stopTest();

        System.assertEquals(lessThanMaxLenString, resultForLessThanMaxLenString, 'An input that is less than max length should not change');
        System.assertEquals(maxLenString, resultForMaxLenString, 'An input that is the same length as max length should not change');
        System.assertNotEquals(moreThanMaxLenString, resultForMoreThanMaxLenString, 'An input that is more than max length should change');
        System.assertEquals(arbitraryMaxLength, resultForMaxLenString.length(), 'The result for an input that is more than max length should have the length of max length');
    }

    @isTest
    static void testSnakeCaseToStartCase() {
        String snakeCase = 'this_is_a_string';
        String startCase = 'This Is A String';
        System.assertEquals(startCase, StringHelper.snakeCaseToStartCase(snakeCase), 'String should be converted to start case');
    }
}