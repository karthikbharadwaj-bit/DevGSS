@isTest
private class Test_ContractSelector {
    //Account feilds defined 
    private static final String ACCOUNT_NAME = 'Test';
    private static final String ACCOUNT_BILLING_ID = '12345';

    //Contract fields defined
    private static final String CONTRACT_NAME = 'Test';
    private static final String CONTRACT_STATUS = 'Draft';

    //Assert messages defined
    private static final String ASSERT_MESSAGE = 'Contracts should be selected';
    private static final String ASSERT_EQUALS_MESSAGE = 'Wrong contract selected';

    @testSetup
    private static void createTestData(){
        Account testAcc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => ACCOUNT_NAME,
                    Account.Billing_ID__c => ACCOUNT_BILLING_ID
                }
            )
            .create()
            .getRecord();
        
        Contract testContract = (Contract) new SObjectBuilder(Contract.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contract.Name => CONTRACT_NAME,
                    Contract.AccountId => testAcc.Id,
                    Contract.Status => CONTRACT_STATUS,
                    Contract.End_Date__c => Date.newInstance(2022, 2, 17),
                    Contract.Original_Signed_Date__c => Date.newInstance(2022, 2, 17)
                }
            )
            .create()
            .getRecord();
        
        testContract.Status = DocuSignHelper.CONTRACT_STATUS_ACTIVE;
        update testContract;
    }
    
    @isTest
    private static void testSelectContracts(){
        List<Contract> contracts = (List<Contract>) new ContractSelector(true, true)
            .selectContracts()
            .executeQuery();

        System.assert(contracts.size() > 0, ASSERT_MESSAGE);
    }
    
    @isTest
    private static void testSelectContractsByAccountIds(){
        List<Contract> contracts = (List<Contract>) new ContractSelector(true, true)
            .selectContracts()
            .executeQuery();
            
        List<Contract> contractsByAccountIds = (List<Contract>) new ContractSelector()
            .selectContractsByAccountIds(new List<Object>{new Set<String>{DocuSignHelper.CONTRACT_STATUS_ACTIVE},
                										  new Set<Id>{contracts[0].AccountId}})
            .executeQuery();

        System.assert(contractsByAccountIds.size() > 0, ASSERT_MESSAGE);
        System.assertEquals(contracts[0].Id, contractsByAccountIds[0].Id, ASSERT_EQUALS_MESSAGE);
    }
    
    @isTest
    private static void testSelectActiveContracts(){
        List<Contract> activeContracts = (List<Contract>) new ContractSelector()
            .selectActiveContracts()
            .executeQuery();
		
        System.assert(activeContracts.size() > 0, ASSERT_MESSAGE);
    }
    
    @isTest
    private static void testSelectActiveContractsWithOriginalSignedDate(){
        List<Contract> activeContractsWithOriginalSignedDate = (List<Contract>) new ContractSelector()
            .selectActiveContractsWithOriginalSignedDate()
            .executeQuery();

        System.assert(activeContractsWithOriginalSignedDate.size() > 0, ASSERT_MESSAGE);
    }
        
    @isTest
    private static void testSelectContractsForContractManagementBatch(){
        List<Contract> contractsForContractManagementBatch = (List<Contract>) new ContractSelector()
            .selectContractsForContractManagementBatch()
            .executeQuery();

        System.assert(contractsForContractManagementBatch.size() > 0, ASSERT_MESSAGE);
    }

    @isTest
    private static void testSelectActiveContractsByAccountId(){
        List<Contract> contracts = (List<Contract>) new ContractSelector(true, true)
            .selectContracts()
            .executeQuery();

        List<Contract> activeContractsByAccountId = (List<Contract>) new ContractSelector()
            .selectActiveContractsByAccountId(new Set<Id>{contracts[0].AccountId})
            .executeQuery();

        System.assert(activeContractsByAccountId.size() > 0, ASSERT_MESSAGE);
        System.assertEquals(contracts[0].Id, activeContractsByAccountId[0].Id, ASSERT_EQUALS_MESSAGE);
    }
}