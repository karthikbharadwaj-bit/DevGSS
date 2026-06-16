@isTest
private class TestUpsellInsightsProductUsageData {

    @isTest
    private static void testGetUpsellInsightsProductUsagesShouldRetrieveUpsellInsightsSuccessfully(){
        Account testAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => 'testAcc'
                }
            )
            .create()
            .getRecord();
        Upsell_Insights_Product_Usage__c testUpsell = (Upsell_Insights_Product_Usage__c) new SObjectBuilder(Upsell_Insights_Product_Usage__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Upsell_Insights_Product_Usage__c.account__c => testAccount.Id,
                    Upsell_Insights_Product_Usage__c.year_mo__c => Date.today().addMonths(-1)
                }
            )
            .create()
            .getRecord();

        UpsellInsightsProductUsageData.IUpsellInsightsProductUsageData testDataInstance = 
            new UpsellInsightsProductUsageData();
        Test.startTest();
            List<Upsell_Insights_Product_Usage__c> insightsRetrieved = 
                testDataInstance.getUpsellInsightsProductUsages(testAccount.Id);
        Test.stopTest();

        System.assertEquals(1, insightsRetrieved.size(), 
            'Only one upsellInsight should be retrieved');
    }

    @isTest
    private static void testMocksShouldReturnExpectedResults() {
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

        List<Upsell_Insights_Product_Usage__c> insightsReturnedByGetUpsellInsightsProductUsages;
        
        Test.startTest();
            insightsReturnedByGetUpsellInsightsProductUsages = mockData.getUpsellInsightsProductUsages(null);
        Test.stopTest();

        System.assertEquals(1, insightsReturnedByGetUpsellInsightsProductUsages.size(), 
            'Insights should be returned correctly by the mock');
    }
}