@RestResource(urlMapping='/AccountContractSFDC/*')
global with sharing class ContractSFDCRestAPI {

    @HttpGet
    global static void getAccountContractSFDC() {

        String accountId = RestContext.request.params.get('accountId');
        RestResponse res = RestContext.response;
        if (res == null) {
            res = new RestResponse();
            RestContext.response = res;
        }

        ContractSelector contractSelector = new ContractSelector();

        List<Contract> activeContracts = (List<Contract>) contractSelector
            .selectActiveContractsByAccountId(new Set<Id>{accountId})
            .executeQuery();

        RestContext.response.responseBody = Blob.valueOf(JSON.serialize(activeContracts));
    }
}