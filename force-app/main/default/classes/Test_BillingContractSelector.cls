@isTest
private class Test_BillingContractSelector {
    //Contract fields defined 
    private static final String CONTRACT_NAME = 'Test';

    //Assert messages defined
    private static final String ASSERT_MESSAGE = 'Contract should be selected';
    private static final String ASSERT_EQUALS_MESSAGE = 'Wrong contract selected'; 

    @testSetup
    private static void createTestData(){
       
        Contract__c testContract = (Contract__c) new SObjectBuilder(Contract__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contract__c.Name => CONTRACT_NAME,
                    Contract__c.ExtID__c => ValueProviderBuilder.provideUniqueString()
                }
            )
            .create()
            .getRecord();
        
        Contract_Discount__c testContractDiscount = (Contract_Discount__c) new SObjectBuilder(Contract_Discount__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contract_Discount__c.Contract__c => testContract.Id
                }
            )
            .create()
            .getRecord();
    }
    
    @isTest
    private static void testSelectContractWithDiscounts(){
        List<Contract__c> contractWithDiscounts = (List<Contract__c>) new BillingContractSelector(true, true)
            .selectContractWithDiscounts()
            .executeQuery();

        System.assert(contractWithDiscounts.size() > 0, ASSERT_MESSAGE);
    }
    
    @isTest
    private static void testSelectContracts(){
        List<Contract__c> contracts = (List<Contract__c>) new BillingContractSelector()
            .selectContracts()
            .executeQuery();

        System.assert(contracts.size() > 0, ASSERT_MESSAGE);
    }
    
    @isTest
    private static void testSelectContractsWithDiscounts(){
        List<Contract__c> contractsWithDiscounts = (List<Contract__c>) new BillingContractSelector()
            .selectContractsWithDiscounts()
            .executeQuery();
        
        System.assert(contractsWithDiscounts.size() > 0, ASSERT_MESSAGE);
    }    
	
	@isTest
    private static void testSelectContractWithDiscountsById(){
        List<Contract__c> contractsWithDiscounts = (List<Contract__c>) new BillingContractSelector()
            .selectContractsWithDiscounts()
            .executeQuery();

        List<Contract__c> contractWithDiscountsById = (List<Contract__c>) new BillingContractSelector()
            .selectContractWithDiscountsById(contractsWithDiscounts[0].Id)
            .executeQuery();
        
        System.assert(contractsWithDiscounts.size() > 0, ASSERT_MESSAGE);
        System.assertEquals(contractsWithDiscounts[0].Id, contractWithDiscountsById[0].Id, ASSERT_EQUALS_MESSAGE);
    } 
    
}