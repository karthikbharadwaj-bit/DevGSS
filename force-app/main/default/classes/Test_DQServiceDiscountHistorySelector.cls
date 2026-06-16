@isTest
private class Test_DQServiceDiscountHistorySelector {

    @isTest
    private static void testSelectDQServiceDiscountHistory() {
        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.AccountId => ValueProviderBuilder.provideGenericParent(Account.SObjectType),
                Opportunity.Name => ValueProviderBuilder.provideUniqueString('test opportunity')
            })
            .create()
            .getRecord();

        DQ_Deal_Qualification__c testDqRecord = (DQ_Deal_Qualification__c) new SObjectBuilder(DQ_Deal_Qualification__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                DQ_Deal_Qualification__c.Opportunity__c => opp.Id
            })
            .create()
            .getRecord();

        DQ_Deal_Qualification_History__c testDQHistory = (DQ_Deal_Qualification_History__c) new SObjectBuilder(DQ_Deal_Qualification_History__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    DQ_Deal_Qualification_History__c.Deal_Qualification__c => testDqRecord.Id,
                    DQ_Deal_Qualification_History__c.Status__c => 'Approved'
                }
            )
            .create()
            .getRecord();

        DQ_Service_Discount_History__c dqSerivceDiscountHistory = (DQ_Service_Discount_History__c) new SObjectBuilder(DQ_Service_Discount_History__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    DQ_Service_Discount_History__c.DQ_Deal_Qualification_History__c => testDQHistory.Id,
                    DQ_Service_Discount_History__c.Service__c => 'test service',
                    DQ_Service_Discount_History__c.Discretion__c => 10,
                    DQ_Service_Discount_History__c.WeightedDiscount__c => 5
                }
            )
            .create()
            .getRecord();

        Test.startTest();
            List<DQ_Service_Discount_History__c> dqServiceDiscountHistoryList = new DQServiceDiscountHistorySelector()
                .selectDQServiceDiscountHistory()
                .executeQuery();
        Test.stopTest();
        
        System.assertEquals(1,dqServiceDiscountHistoryList.size(),'Selector should return 1 DQ_Service_Discount_History record');
    }
}