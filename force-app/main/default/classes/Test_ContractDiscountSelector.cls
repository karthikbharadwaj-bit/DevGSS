@isTest
private class Test_ContractDiscountSelector {

    @TestSetup
    private static void createTestData() {
        List<Contract__c> contracts = (List<Contract__c>) new SObjectBuilder(Contract__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Contract__c.ExtID__c => ValueProviderBuilder.provideUniqueString()
            })
            .quantity(3)
            .create()
            .getRecords();

        new SObjectBuilder(Contract_Discount__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Contract_Discount__c.Contract__c => ValueProviderBuilder.provideParents(contracts),
                Contract_Discount__c.ApplicableTo__c => ValueProviderBuilder.provideUniqueString(),
                Contract_Discount__c.Duration__c => Product2Helper.CHARGE_TERM_MONTHLY,
                Contract_Discount__c.Discount__c => 1
        })
        .quantity(5)
        .create()
        .getRecords();
    }

    @isTest
    private static void test_selectContractDiscounts() {
        Test.startTest();
            ContractDiscountSelector selector = new ContractDiscountSelector();
            List<Contract_Discount__c> testContractDiscWithParams = (List<Contract_Discount__c>) new ContractDiscountSelector(false, false).selectContractDiscounts().executeQuery();
            QueryFactory qualFactory = selector.selectContractDiscounts();
            List<Contract_Discount__c> testContractDisc = (List<Contract_Discount__c>) qualFactory.executeQuery();
        Test.stopTest();

        Map<Id, Contract_Discount__c> conDiscountById = new Map<Id, Contract_Discount__c>([
            SELECT Id
            FROM Contract_Discount__c
        ]);

        System.assertEquals(
            testContractDisc.size(),
            conDiscountById.keySet().size(),
            'Contract Discounts was retrieved incorrectly.'
        );

        System.assertEquals(
            testContractDiscWithParams.size(),
            conDiscountById.keySet().size(),
            'Contract Discounts was retrieved incorrectly.'
        );

        for (Contract_Discount__c conDisc : testContractDisc) {
            System.assertNotEquals(
                conDiscountById.get(conDisc.Id),
                null,
                'Incorrect Contract Discount was retrieved.'
            );
        }
    }
}