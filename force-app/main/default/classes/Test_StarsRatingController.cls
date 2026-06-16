@isTest
private class Test_StarsRatingController {

    @TestSetup
    private static void prepareTestData(){

        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => 'Test account'
                }
            )
            .create()
            .getRecord();
        Upsell_Model__c upsell = new Upsell_Model__c();
        upsell.UpsellAccount__c = acc.Id;
        upsell.total_upsell_score__c = 1;
        upsell.cc_upsell_score__c = 2;
        upsell.tf_upsell_score__c = 3;
        upsell.dl_upsell_score__c = 4;
        upsell.LM_Upsell_Score__c = 5;
        upsell.cc_delta_bundle_mrr__c = 10;
        upsell.tf_current_overage__c = 20;
        upsell.tf_delta_bundle__c = 'Test Bundle';
        upsell.cc_delta_min_overage_charge__c = 30;
        upsell.cc_prop_bundle_total__c = 40;
        insert upsell;
    }

    private static List<Account> getAccounts(){
        List<Account> accounts = [SELECT Id FROM Account];
        return accounts;
    }

    @isTest 
    private static void testGetUpsell() {
        Account acc = [
                        SELECT Id 
                        FROM Account 
                        LIMIT 1
                        ];
        Upsell_Model__c upsell = [
                                    SELECT Id 
                                    FROM Upsell_Model__c
                                    WHERE UpsellAccount__c =: acc.Id
                                    LIMIT 1
                                    ];
        StarsRatingController controller = new StarsRatingController(new ApexPages.StandardController(acc));

        Test.startTest();
            Upsell_Model__c testUpsell = controller.getUpsellModel();
        Test.stopTest();

        System.assertEquals(upsell.Id,
                            testUpsell.Id,
                            'Upsell Model was selected incorrectly.');
    }

    @isTest 
    private static void testSetNumberFieldsValues() {
        Account acc = [
                        SELECT Id 
                        FROM Account 
                        LIMIT 1
                        ];
        Upsell_Model__c upsell = [
                                    SELECT Id, cc_upsell_score__c, total_upsell_score__c,
                                            tf_upsell_score__c, dl_upsell_score__c, 
                                            LM_Upsell_Score__c, LastModifiedDate
                                    FROM Upsell_Model__c
                                    WHERE UpsellAccount__c =: acc.Id
                                    LIMIT 1
                                    ];
        StarsRatingController controller = new StarsRatingController(new ApexPages.StandardController(acc));

        Test.startTest();
            controller.setFieldsValue(upsell);
        Test.stopTest();

        System.assertEquals(controller.numberFields,
                            String.valueOf(upsell.total_upsell_score__c + ';' +
                                            upsell.cc_upsell_score__c + ';' +
                                            upsell.tf_upsell_score__c + ';' +
                                            upsell.dl_upsell_score__c + ';' +
                                            upsell.LM_Upsell_Score__c),
                            'Upsell Model Scroes was assigned incorrectly.');
        System.assertEquals(controller.modifiedDate,
                            upsell.LastModifiedDate.format(),
                            'Upsell Model Last Modified Date was assigned incorrectly.');
    }

    @isTest 
    private static void testGetFieldsValues() {
        Account acc = [
                        SELECT Id 
                        FROM Account 
                        LIMIT 1
                        ];

        Test.startTest();
            Map<String, String> values = StarsRatingController.getFieldValues(String.valueOf(acc.Id));
        Test.stopTest();

        System.assertNotEquals(values,
                                null,
                                'Upsell Model field values was assigned incorrectly.');
        System.assertNotEquals(values.keySet().size(),
                                0,
                                'Upsell Model fields map was generated incorrectly.');
        System.assertEquals(values.values().contains(''),
                                true,
                                'Upsell Model fields map was generated incorrectly.');
    }

    @isTest 
    private static void testIsCurrency() {
        Test.startTest();
            Boolean testCurrency = StarsRatingController.isCurrency('cc_prop_bundle_total__c');
        Test.stopTest();

        System.assertEquals(testCurrency,
                            true,
                            'Currency field on Upsell Model was defined incorrectly.');
    }

    @isTest 
    private static void testGetUpsellInsightsProductUsagesShouldReturnUpsellInsightsCorrectly() {
        Upsell_Insights_Product_Usage__c insightToReturn = (Upsell_Insights_Product_Usage__c) new SObjectBuilder(Upsell_Insights_Product_Usage__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Upsell_Insights_Product_Usage__c.account__c => null
                }
            )
            .create()
            .getRecord();
        
        UpsellInsightsProductUsageData.UpsellInsightsProductUsageDataMock mockData = 
            new UpsellInsightsProductUsageData.UpsellInsightsProductUsageDataMock();
        mockData.insightsToReturn = new List<Upsell_Insights_Product_Usage__c>{insightToReturn};
        StarsRatingController.upsellInsightsProductUsageDataInstance = mockData;
        
        List<Upsell_Insights_Product_Usage__c> insightsReturnedByGetUpsellInsightsProductUsages;
        Test.startTest();
            insightsReturnedByGetUpsellInsightsProductUsages = StarsRatingController.getUpsellInsightsProductUsages(null);
        Test.stopTest();

        System.assertEquals(1, insightsReturnedByGetUpsellInsightsProductUsages.size(), 
            'Insights should be returned correctly by the controller');
    }
}