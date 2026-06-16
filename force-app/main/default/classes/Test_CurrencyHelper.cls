@IsTest
private class Test_CurrencyHelper {
    @isTest
    static void testCurrencyISOCodesForPSInternational() {
        final Set<String> expectedISOCodes = new Set<String>{
            CurrencyHelper.CURRENCY_ISO_CODE_AUD,
            CurrencyHelper.CURRENCY_ISO_CODE_EUR,
            CurrencyHelper.CURRENCY_ISO_CODE_CHE,
            CurrencyHelper.CURRENCY_ISO_CODE_GBP,
            CurrencyHelper.CURRENCY_ISO_CODE_INR
        };

        Test.startTest();
            Assert.areEqual(
                expectedISOCodes,
                CurrencyHelper.CURRENCY_ISO_CODES_FOR_PS_INTERNATIONAL,
                'Unexpected ISO codes for PS International. This might break the functionality of the CaseTriggerHandler.ChangeOwnerForProfessionalServices'
            );
        Test.stopTest();
    }
}