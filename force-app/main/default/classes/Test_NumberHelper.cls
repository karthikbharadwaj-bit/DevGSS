@isTest
private class Test_NumberHelper {
    final static Integer NUMBER_INT = 2;
    final static Decimal NUMBER_DEC = 1.5555;
    final static RoundingMode mode = RoundingMode.UP;

    @isTest
    private static void test_nullSafeNumber_null() {
        System.assertEquals(
            NumberHelper.getNumberNullSafe(null),
            0,
            'Null must return 0.'
        );
    }

    @isTest
    private static void test_nullSafeNumber_digit() {
        System.assertEquals(
            NumberHelper.getNumberNullSafe(NUMBER_INT),
            NUMBER_INT,
            'Initial value should be returned.'
        );
    }

    @isTest
    private static void test_toNumber_integer() {
        System.assertEquals(
            NumberHelper.toNumber(NUMBER_INT),
            Integer.valueOf(NUMBER_INT),
            'Integer value of initial string should be returned.'
        );
    }

    @isTest
    private static void test_toNumber_decimal() {
        System.assertEquals(
            NumberHelper.toNumber(NUMBER_DEC),
            NUMBER_DEC,
            'Decimal value of initial string should be returned.'
        );
    }

    @isTest
    private static void test_roundCurrency_null() {
        System.assertEquals(
            NumberHelper.roundCurrency(null),
            0,
            'Null must return 0.'
        );
    }

    @isTest
    private static void test_roundCurrency_digit() {
        System.assertEquals(
            NumberHelper.roundCurrency(NUMBER_DEC),
            NUMBER_DEC.setScale(NUMBER_INT),
            'Decimal value of initial string should be returned.'
        );
    }

    @isTest
    private static void test_roundCurrency_scale() {
        System.assertEquals(
            NumberHelper.roundCurrency(NUMBER_DEC, NUMBER_INT),
            NUMBER_DEC.setScale(NUMBER_INT),
            'Decimal value was scaled incorrectly.'
        );
    }

    @isTest
    private static void test_roundCurrency_round() {
        System.assertEquals(
            NumberHelper.roundCurrency(NUMBER_DEC, mode),
            NUMBER_DEC.setScale(NUMBER_INT, mode),
            'Decimal value was rounded incorrectly.'
        );
    }

    @isTest
    private static void test_roundCurrency_scaleAndRound() {
        System.assertEquals(
            NumberHelper.roundCurrency(NUMBER_DEC, NUMBER_INT, mode),
            NUMBER_DEC.setScale(NUMBER_INT, mode),
            'Decimal value was rounded and scaled incorrectly.'
        );
    }

    @isTest
    private static void testGetBoundedScale() {
        // within boundaries
        System.assertEquals(3, NumberHelper.getBoundedScale(1.234, 0, 5), 
            'Wrong bounded [0, 5] scale for 1.234 returned.');

        // below min scale
        System.assertEquals(2, NumberHelper.getBoundedScale(75.0000, 2, 3),
            'Wrong bounded [2, 3] scale for 75.0000 returned.');

        // below min scale
        System.assertEquals(2, NumberHelper.getBoundedScale(0.0000, 2, 3),
            'Wrong bounded [2, 3] scale for 0.0000 returned.');

        // above max scale
        System.assertEquals(2, NumberHelper.getBoundedScale(44.9999, 0, 2),
            'Wrong bounded [0, 2] scale for 44.9999 returned.');
    }
}