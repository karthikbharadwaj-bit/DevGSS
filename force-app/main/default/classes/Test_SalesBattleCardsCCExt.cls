@isTest
private class Test_SalesBattleCardsCCExt {

    @isTest 
    private static void testBattleController() {
        SalesBattleCardsCCExt controller = new SalesBattleCardsCCExt(new ApexPages.StandardController(new ACE__c()));
        System.assertNotEquals(null,
                                controller.ccFeatureDoc,
                                'Feature Doc was not found.');
        System.assertNotEquals(null,
                                controller.ccAdvanceDoc,
                                'CC Advance Doc was not found.');
        System.assertNotEquals(null,
                                controller.smsDoc,
                                'Sms Doc was not found.');
    }
}