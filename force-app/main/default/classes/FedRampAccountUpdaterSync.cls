@RestResource(urlMapping='/FedRampAccountUpdaterSync/*')
global class FedRampAccountUpdaterSync {

    @HttpPut
    global static void updateAccount() {

        RestResponse res = RestContext.response;
        if (res == null) {
            res = new RestResponse();
            RestContext.response = res;
        }
        List<Account> accountsToUpdate = buildAccountsFromRequest(RestContext.request.requestBody.toString());

        List<Database.UpsertResult> upsertResults = Database.upsert(accountsToUpdate, Account.RC_User_ID__c, false);

        Map<String, String> upsertResultsInfo = new Map<String, String>();
        for (Integer i = 0; i < upsertResults.size(); ++i) {
            String message = upsertResults.get(i).isSuccess()
                ? Response.STATUS_SUCCESS
                : upsertResults.get(i).getErrors().toString();
            if (res.statusCode == null && message != Response.STATUS_SUCCESS) {
                res.statusCode = 400;
            }
            upsertResultsInfo.put(accountsToUpdate.get(i).RC_User_ID__c, message);
        }
        res.responseBody = Blob.valueOf(JSON.serialize(upsertResultsInfo));
        if (res.statusCode == null) {
            res.statusCode = 200;
        }
    }

    private static List<Account> buildAccountsFromRequest(String data) {
        List<Account> accountsFromFedRamp =
            (List<Account>) JSON.deserialize(data, List<Account>.class);
        return accountsFromFedRamp;
    }
}