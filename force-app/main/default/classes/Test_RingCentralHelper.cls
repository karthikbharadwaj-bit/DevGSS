@isTest
private class Test_RingCentralHelper {
    @isTest
    static void testBrandToCurrencyIsoCode() {
        System.assertEquals(
            RingCentralHelper.GBP,
            RingCentralHelper.brandToCurrencyIsoCode(RingCentralHelper.BRAND_BT));
        System.assertEquals(
            RingCentralHelper.GBP,
            RingCentralHelper.brandToCurrencyIsoCode(RingCentralHelper.BRAND_RINGCENTRAL_UK));
        System.assertEquals(
            RingCentralHelper.GBP,
            RingCentralHelper.brandToCurrencyIsoCode(RingCentralHelper.BRAND_BT_BUSINESS));
        System.assertEquals(
            RingCentralHelper.GBP,
            RingCentralHelper.brandToCurrencyIsoCode(RingCentralHelper.BRAND_VODAFONE));
        System.assertEquals(
            RingCentralHelper.AUD,
            RingCentralHelper.brandToCurrencyIsoCode(RingCentralHelper.BRAND_RINGCENTRAL_AU));
        System.assertEquals(
            RingCentralHelper.EUR,
            RingCentralHelper.brandToCurrencyIsoCode(RingCentralHelper.BRAND_RINGCENTRAL_EU));
        System.assertEquals(
            RingCentralHelper.CAD,
            RingCentralHelper.brandToCurrencyIsoCode(RingCentralHelper.BRAND_RINGCENTRAL_CANADA));

        System.assertEquals(
            RingCentralHelper.USD,
            RingCentralHelper.brandToCurrencyIsoCode(RingCentralHelper.BRAND_RINGCENTRAL));
        System.assertEquals(
            RingCentralHelper.USD,
            RingCentralHelper.brandToCurrencyIsoCode(' test '));
        System.assertEquals(
            RingCentralHelper.USD,
            RingCentralHelper.brandToCurrencyIsoCode(null));
    }

    @isTest
    static void testGetOrgCurrencyCodes() {
        System.assertEquals(false, RingCentralHelper.getOrgCurrencyCodes().isEmpty());
        System.assertEquals(true, RingCentralHelper.getOrgCurrencyCodes().contains(RingCentralHelper.USD));
        System.assertEquals(true, RingCentralHelper.getOrgCurrencyCodes().contains(RingCentralHelper.GBP));
        System.assertEquals(true, RingCentralHelper.getOrgCurrencyCodes().contains(RingCentralHelper.AUD));
        System.assertEquals(true, RingCentralHelper.getOrgCurrencyCodes().contains(RingCentralHelper.EUR));
        System.assertEquals(true, RingCentralHelper.getOrgCurrencyCodes().contains(RingCentralHelper.CAD));
    }
    
}