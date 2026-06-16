@isTest
private class Test_ContractSFDCRestAPI {

    @isTest
    private static void verifyThatGetAccountContractSFDCReturnActiveContractFromAccount() {
        Account testAcc = (Account) new SObjectBuilder(Account.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Name => ValueProviderBuilder.provideUniqueString('Test Account')
            })
            .create()
            .getRecord();

        Contract testContract = (Contract) new SObjectBuilder(Contract.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Contract.Name => ValueProviderBuilder.provideUniqueString('Test Contract'),
                Contract.AccountId => testAcc.Id,
                Contract.Original_Signed_Date__c => System.today().addDays(-10),
                Contract.Source__c => 'Automation',
                Contract.Status => 'Draft',
                Contract.Initial_Term__c => 12,
                Contract.Original_Initial_Term__c => 12,
                Contract.Auto_Renewal__c => true,
                Contract.Original_Auto_Renewal__c => false,
                Contract.Start_Date__c => System.today().addDays(-10),
                Contract.Original_Start_Date__c => System.today().addDays(-10),
                Contract.End_Date__c => System.today(),
                Contract.Original_End_Date__c => System.today(),
                Contract.Renewal_Term__c => 24,
                Contract.Original_Renewal_Term__c => 24
            })
            .create()
            .getRecord();

        testContract.Status = 'Active';
        update testContract;

        RestContext.request = new RestRequest();
        RestContext.request.params.put('accountId', testAcc.Id);
        ContractSFDCRestAPI.getAccountContractSFDC();

        String body = RestContext.response.responseBody.toString();

        List<Contract> contracts = (List<Contract>) JSON.deserialize(body, List<Contract>.class);

        Contract resultContract = contracts[0];

        System.assertEquals(
            1,
            contracts.size(),
            'Result Contracts List should contain exactly 1 element'
        );
        System.assertEquals(
            testAcc.Id,
            resultContract.AccountId,
            'Field AccountId on active contract has incorrect value'
        );
        System.assertEquals(
            'Active',
            resultContract.Status,
            'Field Status on active contract has incorrect value'
        );
        System.assertEquals(
            12,
            resultContract.Initial_Term__c,
            'Field Initial_Term__c on active contract has incorrect value'
        );
        System.assertEquals(
            12,
            resultContract.Original_Initial_Term__c,
            'Field Original_Initial_Term__c on active contract has incorrect value'
        );
        System.assertEquals(
            24,
            resultContract.Renewal_Term__c,
            'Field Renewal_Term__c on active contract has incorrect value'
        );
        System.assertEquals(
            24,
            resultContract.Original_Renewal_Term__c,
            'Field Original_Renewal_Term__c on active contract has incorrect value'
        );
        System.assertEquals(
            true,
            resultContract.Auto_Renewal__c,
            'Field Auto_Renewal__c on active contract has incorrect value'
        );
        System.assertEquals(
            false,
            resultContract.Original_Auto_Renewal__c,
            'Field Auto_Renewal__c on active contract has incorrect value'
        );
    }
}