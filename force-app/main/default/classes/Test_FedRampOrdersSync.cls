@isTest
private class Test_FedRampOrdersSync {
    @isTest
    static void testSuccesfulSync() {
        List<Account> accList = (List<Account>) new SObjectBuilder(Account.SObjectType)
            .quantity(2)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => ValueProviderBuilder.provideUniqueString('FedRamp Account'),
                    Account.RC_User_Id__c => ValueProviderBuilder.provideList(
                        new List<String>{'123', '456'}
                    )
                }
            )
            .create()
            .getRecords();

        List<Order__c> orderList = (List<Order__c>) new SObjectBuilder(Order__c.SObjectType)
            .quantity(4)
            .setFields(
                new Map<SObjectField, Object>{
                    Order__c.Name => ValueProviderBuilder.provideUniqueString('Test order'),
                    Order__c.Account__c => ValueProviderBuilder.provideList(
                        new List<Id>{accList[0].Id, accList[0].Id, accList[1].Id, accList[1].Id}
                    )
                }
            )
            .create()
            .getRecords();

        List<Agent_Credit__c> acList = (List<Agent_Credit__c>) new SObjectBuilder(Agent_Credit__c.SObjectType)
            .quantity(8)
            .setFields(
                new Map<SObjectField, Object>{
                    Agent_Credit__c.Name => ValueProviderBuilder.provideUniqueString('Test order'),
                    Agent_Credit__c.Account__c => ValueProviderBuilder.provideList(
                        new List<Id>{
                            accList[0].Id,
                            accList[0].Id,
                            accList[0].Id,
                            accList[0].Id,
                            accList[1].Id,
                            accList[1].Id,
                            accList[1].Id,
                            accList[1].Id
                        }
                    ),
                    Agent_Credit__c.Order__c => ValueProviderBuilder.provideList(
                        new List<Id>{
                            orderList[0].Id,
                            orderList[0].Id,
                            orderList[1].Id,
                            orderList[1].Id,
                            orderList[2].Id,
                            orderList[2].Id,
                            orderList[3].Id,
                            orderList[3].Id
                        }
                    )
                }
            )
            .create()
            .getRecords();
        /* Prepare request body */
        Set<Id> orderIdSet = new Set<Id>(new Map<Id, Order__c>(orderList).keySet());
        List<Order__c> selectedOrders = (List<Order__c>) new OrderCustomSelector()
            .selectOrdersForSFToSFSync(new List<Object>{orderIdSet})
            .executeQuery();

        List<FedRampOrdersSync.OrderWrapper> orders = new List<FedRampOrdersSync.OrderWrapper>();
        for (Order__c o : selectedOrders) {
            FedRampOrdersSync.OrderWrapper ow = new FedRampOrdersSync.OrderWrapper();
            ow.order = o;
            ow.agentCredits = o.Agent_Credits__r;
            orders.add(ow);
        }

        RestContext.request = new RestRequest();
        RestContext.request.requestBody = Blob.valueOf(JSON.serialize(orders));

        Test.startTest();
            FedRampOrdersSync.handleRequest();
        Test.stopTest();

        List<Order__c> reselectedOrders = (List<Order__c>) new OrderCustomSelector()
            .selectOrders()
            .executeQuery();

        System.assertEquals(8, reselectedOrders.size(), 'New order records should be created by FedRampOrderSync');
        for (Order__c o : reselectedOrders) {
            System.assertEquals(2, o.Agent_Credits__r.size(), 'New Agent Credit records should be created by FedRampOrderSync');
        }
    }

    @IsTest
    static void testLogDataCreation() {
        List<Account> accList = (List<Account>) new SObjectBuilder(Account.SObjectType)
            .quantity(2)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => ValueProviderBuilder.provideUniqueString('FedRamp Account'),
                    Account.RC_User_Id__c => ValueProviderBuilder.provideList(
                        new List<String>{'123', '456'}
                    )
                }
            )
            .create()
            .getRecords();

        List<Order__c> orderList = (List<Order__c>) new SObjectBuilder(Order__c.SObjectType)
            .quantity(4)
            .setFields(
                new Map<SObjectField, Object>{
                    Order__c.Name => ValueProviderBuilder.provideUniqueString('Test order'),
                    Order__c.Account__c => ValueProviderBuilder.provideList(
                        new List<Id>{accList[0].Id, accList[0].Id, accList[1].Id, accList[1].Id}
                    )
                }
            )
            .create()
            .getRecords();

        Set<Id> orderIdSet = new Set<Id>(new Map<Id, Order__c>(orderList).keySet());
        List<Order__c> selectedOrders = (List<Order__c>) new OrderCustomSelector()
            .selectOrdersForSFToSFSync(new List<Object>{orderIdSet})
            .executeQuery();


        Database.SaveResult[] saveResults = new List<Database.SaveResult>();
        for (Order__c o : selectedOrders) {
            Database.SaveResult saveResultError = (Database.SaveResult)JSON.deserialize(
                '{"success":false,"errors":[{"message":"Failed To insert Order","statusCode":"Error"}]}',
                Database.SaveResult.class
            );
            saveResults.add(saveResultError);
        }

        Test.startTest();
            FedRampOrdersSync.logDataCreation('FedRampOrdersSync | orders insert',saveResults, selectedOrders, true);
        Test.stopTest();

        List<PlatformLog__c> plList = [SELECT Id, Source__c, Error__c, StackTrace__c FROM PlatformLog__c];
        System.assertEquals(4, plList.size(), 'For every order platform log should be created');
    }
}