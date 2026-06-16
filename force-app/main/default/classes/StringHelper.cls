public class StringHelper {
    class StringHelperException extends Exception {}

    private static final String DEFAULT_DELIMETER = ';';
    private static final List<String> chars = new List<String> {
        'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j',
        'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't',
        'u', 'v', 'w', 'x', 'y', 'z', 'A', 'B', 'C', 'D',
        'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N',
        'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X',
        'Y', 'Z', '0', '1', '2', '3', '4', '5', '6', '7',
        '8', '9'
    };
    @TestVisible private static final String MESSAGE_PARAMETER_NULL = 'Parameter should not be null';
	/**
     *  @param valObj Object
     *  @param scale Integer
     *
     *  @return String
     *
     *  @description  Convert Decimal to Number format
     *  1000000.00 -> 1,000,000.00
     *  1000000.000 -> 1,000,000.000
     *  asNumber() -> 1,000,000.00
     *  asNumber(-1) -> 1,000,000
     */
    public static String asNumber(Decimal val, Integer scale) {

        String str = val.setScale(scale, RoundingMode.HALF_UP).format();

        Integer dec = str.lastindexOf('.');

        Integer decPlaces = dec == -1 ? 0 : str.length() - dec - 1;
        Integer decPlacesToAdd = scale - decPlaces;

        if (decPlacesToAdd > 0) {
            if (decPlaces <= 0) {
                str += '.';
            }

            for (Integer i = 0; i < decPlacesToAdd; ++i) {
                str += '0';
            }
        }

        return str;
    }

    public static String asNumber(Object valObj, Integer scale) {
        String valStr = String.valueOf(valObj);

        if (String.isBlank(valStr)) {
            return valStr;
        } else {
            return asNumber(Decimal.valueOf(valStr), scale);
        }
    }

    /**
     * Returns String representation of valObj number with scale bounded to min/max values.
     * Examples￼:
     *      asNumber(0.0167, 2, 3) == '0.017’
     *      asNumber(75.0, 2, 3) == '75.00’
     */
    public static String asNumber(Object valObj, Integer minScale, Integer maxScale) {
        String valStr = String.valueOf(valObj);

        if (String.isBlank(valStr)) {
            return valStr;
        } else {
            Decimal val = Decimal.valueOf(valStr);
            return asNumber(val, NumberHelper.getBoundedScale(val, minScale, maxScale));
        }
    }

    /**
     * @param strToValidate String
     * @param exceptionMessage String
     *
     * @return void
     *
     * @description verifies that given String is not Blank and throws an exception otherwise.
     */

    public static void validateStrict(String strToValidate, String exceptionMessage) {
        if (String.isBlank(strToValidate)) {
            throw new StringHelperException(exceptionMessage);
        }
    }

    public static String defaultString(Object value, String defaultValue) {
        return (value == null)
            ? defaultValue
            : String.valueOf(value);
    }

    /**
     * Returns empty string instead of null or whitespace
     * @param Object str
     *
     * @return
     */
    public static String safeString(Object str) {
        if(str == null) {
            return '';
        }

        String res = String.valueOf(str);
        return String.isNotBlank(res) ? res : '';
    }

    /**
     * Returns empty string instead of null or whitespace
     * @param String str
     *
     * @return
     */
    public static String safeString(String str) {
        return String.isNotBlank(str) ? str : '';
    }

    public static Integer asInteger(String value) {
        Integer result;
        if (value != null) {
            result = Integer.valueOf(value);
        }
        return result;
    }


    /**
     * @param stringAsSet String
     *
     * @return Set<String>
     *
     * @description transfers String representation of Set<String> and returns Set<String>
     */

    public static Set<String> convertStringToSetOfStrings(String stringAsSet) {
        Set<String> stringToReturn = new Set<String>();
        if (String.isBlank(stringAsSet)) {
            return stringToReturn;
        }
        try {
            stringToReturn = (Set<String>) JSON.deserialize(stringAsSet, Set<String>.class);
        } catch (Exception e) {
            System.debug(e.getMessage());
            throw new StringHelperException('Cannot parse set of Strings. Error: ' + e.getMessage());
        }
        return stringToReturn;
    }

    /**
     * @param setOfStrings List<String>
     *
     * @return String
     *
     * @description transfers List<String> to String, separated by ';'. Last entry has delimeter after it as well
     */
    public static String convertListOfStringsToString(List<String> setOfStrings) {
        return convertListOfStringsToString(setOfStrings, DEFAULT_DELIMETER, false);
    }

    /**
     * @param setOfStrings List<String>
     * @param delimeter String
     * @param isAddLastDelimeter Boolean
     *
     * @return String
     *
     * @description transfers List<String> to String, separated by passed delimeter. Last entry delimeter is controlled
     * by isAddLastDelimeter
     */
    public static String convertListOfStringsToString(
        List<String> strings,
        String delimeter,
        Boolean isAddLastDelimeter
    ) {
        String resultString = '';
        if (delimeter == null || isAddLastDelimeter == null) {
            AquivaHelper.throwAquivaException(MESSAGE_PARAMETER_NULL);
        }
        if (strings == null || strings.isEmpty()) {
            return resultString;
        }

        resultString = String.join(strings, delimeter);
        if (isAddLastDelimeter) {
            resultString += delimeter;
        }

        return resultString;
    }

    /**
     * @param length
     * @return String
     * @description generate random string (alphanumeric) with specified length.
    */
    public static String getRandomString (Integer length) {

        if (length == null) {
            throw new StringHelperException(MESSAGE_PARAMETER_NULL);
        }
        String res = '';
        Integer multiplier = chars.size() - 1;
        for (Integer i = 0; i < length; i++) {
            res += chars[Math.round(Math.random() * multiplier)];
        }

        return res;
    }

    /**
     * @param str String
     * @param substringLength Integer
     *
     * @return String
     *
     * @description get substring of string with size Max(length of string, passing parameter substringLength)
     */
    public static String safeSubstring(String str, Integer substringLength) {
        return (safeString(str).length() > substringLength) ? str.substring(0, substringLength) : str;
    }

    /**
     * @param str String
     *
     * @return List<String>
     *
     * @description get split string by new line. If string is blank - return new empty list of strings
     */
    public static List<String> safeSplitStringByNewLine(String str) {
        if (String.isBlank(str)) {
            return new List<String>();
        } else {
            return str.split('\n');
        }
    }

    public static List<String> safeSplit(String strToSplit, String regExp) {
        return (strToSplit == null)
            ? new List<String>()
            : strToSplit.split(regExp);
    }

    /*
     * Useful for Custom settings with long delimited strings
     */
    public static List<String> parseDelimitedString(String strToSplit) {
        return parseDelimitedString(strToSplit, ';|,');
    }

    /*
     * Useful for Custom settings with long delimited strings
     */
    public static List<String> parseDelimitedString(String strToSplit, String regExp) {
        List<String> result = new List<String>();
        if (strToSplit == null) {
            return result;
        }
        result = strToSplit.split(regExp);
        for (Integer i = 0; i < result.size(); i++) {
            result[i] = result[i].trim();
        }
        return result;
    }

    /**
    * @param address, which fields will be merged to construct the address string
    * @description merges address fields to one string, splitted by comma
    * */
    public static String constructAddress(Address address) {
        if (address == null) {
            return '';
        }

        List<String> fields = new List<String>();

        if (String.isNotBlank(address.postalCode)) {
            fields.add(address.postalCode);
        }

        if (String.isNotBlank(address.street)) {
            fields.add(address.street);
        }

        if (String.isNotBlank(address.city)) {
            fields.add(address.city);
        }

        if (String.isNotBlank(address.state)) {
            fields.add(address.state);
        }

        if (String.isNotBlank(address.country)) {
            fields.add(address.country);
        }

        return String.join(fields, ', ');
    }

    public static Set<String> convertSetToLowerCase(Set<String> valueSet){
        Set<String> newSet = new Set<String>();
        for(String str : valueSet){
            newSet.add(str?.toLowerCase());
        }
        return newSet;
    }
        
    public static String createObjectLink(Id objectId) {
        return URL.getOrgDomainUrl().toExternalForm() + '/' + objectId;
    }

    public static String getSafeLengthString(String str, Integer maxLength) {
        return str.length() > maxLength ? str.substring(0, maxLength) : str;
    }

    public static String snakeCaseToStartCase(String str) {
        if (String.isBlank(str)) {
            return str;
        }
        List<String> parts = new List<String>();
        for (String part : str.split('_')) {
            parts.add(part.capitalize());
        }
        return String.join(parts, ' ');
    }
}