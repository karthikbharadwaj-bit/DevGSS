@RestResource(urlMapping='/LookupService/*')
global with sharing class LookupService {

    global class Params {
        global String action {get;set;}
        global String method {get;set;}

        // Search Lookup params
        global String searchText {get;set;}
        global String recordId {get;set;}
        global Integer queryLimit {get;set;}
        global Map<String, String> params {get;set;}
        global Boolean isAccountBindingManager {get;set;}
    }

    @HttpPost
    global static void handleRequest() {
        String body = RestContext.request.requestBody.toString();
        LookupService.Params paramsData = (LookupService.Params) JSON.deserialize(body, LookupService.Params.class);
        System.debug(' *** paramsData: ' + paramsData);

        RestResponse res = RestContext.response;
        Response r = new Response();
        if (res == null) {
            res = new RestResponse();
            RestContext.response = res;
        }

        try {
            switch on paramsData.action {
                when 'getLookupSearch' {
                    r.setData('lookupResults', getLookupSearch(paramsData));
                }
            }
        } catch (Exception e) {
            Map<String, String> errMsg = new Map<String, String>();
            errMsg.put('error', e.getMessage());
            errMsg.put('stackTrace', e.getStackTraceString());
            res.responseBody = Blob.valueOf(JSON.serialize(errMsg));
        }
        res.responseBody = Blob.valueOf(JSON.serialize(r));
    }

    public static List<LookupController.LookupResult> getLookupSearch(LookupService.Params paramsData) {
        List<LookupController.LookupResult> result = new List<LookupController.LookupResult>();

        switch on paramsData.method {
            when 'getAreaCodes' {
                result = LookupController.getAreaCodes(
                    paramsData.searchText,
                    paramsData.recordId,
                    paramsData.queryLimit,
                    paramsData.params);
            }
            when 'getAccounts' {
                result = LookupController.getAccounts(
                    paramsData.searchText,
                    paramsData.recordId,
                    paramsData.queryLimit,
                    paramsData.params,
                    paramsData.isAccountBindingManager);
            }
            when 'getContacts' {
                result = LookupController.getContacts(
                    paramsData.searchText,
                    paramsData.recordId,
                    paramsData.queryLimit,
                    paramsData.params);
            }
            when 'getQuotes' {
                result = LookupController.getQuotes(
                    paramsData.searchText,
                    paramsData.recordId,
                    paramsData.queryLimit,
                    paramsData.params);
            }
            when 'getProducts' {
                result = LookupController.getProducts(
                    paramsData.searchText,
                    paramsData.recordId,
                    paramsData.queryLimit,
                    paramsData.params
                );
            }
            when 'getUsers' {
                result = LookupController.getUsers(
                    paramsData.searchText,
                    paramsData.recordId,
                    paramsData.queryLimit,
                    paramsData.params
                );
            }
            when 'getQueuesSObjects' {
                result = LookupController.getQueuesSObjects(
                    paramsData.searchText,
                    paramsData.recordId,
                    paramsData.queryLimit,
                    paramsData.params
                );
            }
        }

        return result;
    }
}