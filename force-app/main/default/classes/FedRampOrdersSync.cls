@RestResource(UrlMapping='/FedRampOrdersSync/*')
global with sharing class FedRampOrdersSync {

    @HttpPost
    global static void handleRequest() {
        Response resp = new Response();

        if (RestContext.response == null) {
            RestContext.response = new RestResponse();
        }

        String body = RestContext.request.requestBody.toString();
        try {
            List<OrderWrapper> orders = (List<OrderWrapper>) JSON.deserialize(body, List<OrderWrapper>.class);

            Map<String,Account> userIdToAccountMap = buildUserIdToAccountMap(orders);

            /* Insert Orders */
            List<Agent_Credit__c> acList = new List<Agent_Credit__c>();
            Map<Id,Order__c> fedRampOrderIdToCommercialRecord = new Map<Id,Order__c>();
            for (OrderWrapper ow : orders) {
                Id orderId = ow.order.Id;
                /* Need to clean Id field manually: https://trailblazer.salesforce.com/issues_view?id=a1p300000008X9vAAE */
                ow.order.Id = null;
                Order__c orderToCreate = ow.order.clone(false, true, false ,true);
                orderToCreate.Account__c = userIdToAccountMap.get(ow.order.Account__r.RC_User_ID__c).Id;

                fedRampOrderIdToCommercialRecord.put(orderId, orderToCreate);

                acList.addAll(ow.agentCredits);
            }

            if (!fedRampOrderIdToCommercialRecord.values().isEmpty()) {
                /* Insert Orders */
                Database.SaveResult[] ordersSaveResults = Database.insert(fedRampOrderIdToCommercialRecord.values(), false);
                logDataCreation('FedRampOrdersSync | orders insert', ordersSaveResults, fedRampOrderIdToCommercialRecord.values(), true);
            }

            /* Insert Agent Credits */
            List<Agent_Credit__c> acToInsertList = new List<Agent_Credit__c>();
            for (Agent_Credit__c ac : acList) {
                /* When order wasn't created - do not create Agent Credit */
                if (fedRampOrderIdToCommercialRecord.get(ac.Order__c).Id == null) {
                    continue;
                }
                /* Need to clean Id field manually: https://trailblazer.salesforce.com/issues_view?id=a1p300000008X9vAAE */
                ac.Id = null;
                Agent_Credit__c agToCreate = ac.clone(false, true, false ,true);

                Order__c correspOrder = fedRampOrderIdToCommercialRecord.get(agToCreate.Order__c);
                agToCreate.Order__c = correspOrder.Id;
                agToCreate.Account__c = correspOrder.Account__c;

                acToInsertList.add(agToCreate);
            }

            if (!acToInsertList.isEmpty()) {
                Database.SaveResult[] acSaveResults = Database.insert(acToInsertList, false);
                logDataCreation('FedRampOrdersSync | agent credit insert', acSaveResults, acToInsertList, false);
            }

        } catch(Exception ex) {
            System.debug('///FedRamp OrdersSync exception ' + ex);
            RestContext.response.responseBody = Blob.valueOf(
                JSON.serialize(getErrorResponse(ex))
            );
        }

        RestContext.response.responseBody = Blob.valueOf(JSON.serialize(resp));
    }

    public static void logDataCreation(String source, Database.SaveResult[] saveResults, SObject[] records, Boolean isOrder) {
        /* Only Orders and Agent Credits could be handled here */

        PlatformLog__c[] errorLogs = new List<PlatformLog__c>();
        for (Integer i = 0; i < saveResults.size(); ++i) {
            for (Database.Error error : saveResults[i].getErrors()) {
                String objectName = isOrder ? 'Order' : 'Agent Credit';
                String name = isOrder ? ((Order__c) records[i]).Name : ((Agent_Credit__c) records[i]).Name;
                String userId = isOrder
                    ? ((Order__c) records[i]).Account__r.RC_User_Id__c
                    : ((Agent_Credit__c) records[i]).Account__r.RC_User_Id__c;

                String errorText = 'Failed to create ' + objectName + ' record (' + name + ') for Account.RC_User_ID__c: ' +
                    userId + '. ' + error.getMessage();
                errorLogs.add(PlatformLog.buildLog(source, errorText, null, null, null));
            }
        }

        if (!errorLogs.isEmpty()) {
            PlatformLog.logResults(errorLogs);
        }
    }

    public static Map<String,Account> buildUserIdToAccountMap(List<OrderWrapper> orders) {
        Set<String> rcUserIdSet = new Set<String>();
        for (OrderWrapper ow : orders) {
            rcUserIdSet.add(ow.order.Account__r.RC_User_ID__c);
        }

        List<Account> accList = (List<Account>) new AccountSelector()
            .selectAccountsByUserIds(new List<Object>{rcUserIdSet})
            .executeQuery();

        Map<String,Account> userIdToAccountMap = new Map<String,Account>();
        for (Account acc : accList) {
            if (String.isBlank(acc.RC_User_Id__c)) {
                continue;
            }

            userIdToAccountMap.put(acc.RC_User_Id__c, acc);
        }
        return userIdToAccountMap;
    }

    @testVisible
    private static Map<String, String> getErrorResponse(Exception ex) {
        return new Map<String, String> {
            'error'      => ex.getMessage(),
            'stackTrace' => ex.getStackTraceString()
        };
    }

    public class OrderWrapper {
        public Order__c order;
        public List<Agent_Credit__c> agentCredits;
    }
}