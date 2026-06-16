@isTest
private class Test_PlatformLog {
    /*
     * Verify log creation, fields are populated as expected.
    */
    @isTest static void testPlatformLogCreationWhenExceptionThrown() {
        System.NullPointerException ex = new System.NullPointerException();
        PlatformLog.logException(Test_PlatformLog.class.getName(), ex);
        List<PlatformLog__c> errorLogs = [SELECT Id,
                                                 Error__c,
                                                 Source__c,
                                                 StackTrace__c,
                                                 InboundMessage__c,
                                                 OutboundMessage__c
                                            FROM PlatformLog__c];
        System.assertEquals(errorLogs.size(), 1);
        System.assertEquals(errorLogs[0].Error__c, ex.getMessage(), PlatformEventsUtil.PE_TEST_ERROR_NOT_EQUALS);
        System.assertEquals(errorLogs[0].Source__c, Test_PlatformLog.class.getName(), PlatformEventsUtil.PE_TEST_SOURCE_NOT_EQUALS);
        System.assertEquals(errorLogs[0].StackTrace__c, ex.getStackTraceString(), PlatformEventsUtil.PE_TEST_STACK_NOT_EQUALS);
        System.assertEquals(errorLogs[0].InboundMessage__c, null, PlatformEventsUtil.PE_TEST_INBOUND_NOT_EQUALS);
        System.assertEquals(errorLogs[0].OutboundMessage__c, null, PlatformEventsUtil.PE_TEST_OUTBOUND_NOT_EQUALS);
    }

    /*
     * Verify async log creation, fields are populated as expected.
    */
    @isTest static void testAsyncPlatformLogCreationWhenExceptionThrown() {
        System.NullPointerException ex = new System.NullPointerException();
        Test.startTest();
            PlatformLog.logException(Test_PlatformLog.class.getName(), ex, true);
        Test.stopTest();
        List<PlatformLog__c> errorLogs = [SELECT Id,
                                                 Error__c,
                                                 Source__c,
                                                 StackTrace__c,
                                                 InboundMessage__c,
                                                 OutboundMessage__c
                                            FROM PlatformLog__c];
        System.assertEquals(errorLogs.size(), 1);
        System.assertEquals(errorLogs[0].Error__c, ex.getMessage(), PlatformEventsUtil.PE_TEST_ERROR_NOT_EQUALS);
        System.assertEquals(errorLogs[0].Source__c, Test_PlatformLog.class.getName(), PlatformEventsUtil.PE_TEST_SOURCE_NOT_EQUALS);
        System.assertEquals(errorLogs[0].StackTrace__c, ex.getStackTraceString(), PlatformEventsUtil.PE_TEST_STACK_NOT_EQUALS);
        System.assertEquals(errorLogs[0].InboundMessage__c, null, PlatformEventsUtil.PE_TEST_INBOUND_NOT_EQUALS);
        System.assertEquals(errorLogs[0].OutboundMessage__c, null, PlatformEventsUtil.PE_TEST_OUTBOUND_NOT_EQUALS);
    }

    /*
     * Verify log creation, fields are populated as expected.
    */
    @isTest static void testPlatformLogCreationWhenExceptionThrownDuringIntegration() {
        System.NullPointerException ex = new System.NullPointerException();
        PlatformLog.logException(Test_PlatformLog.class.getName(), ex, 'Test Body', 'Exception thrown', false);
        List<PlatformLog__c> errorLogs = [SELECT Id,
                                                 Error__c,
                                                 Source__c,
                                                 StackTrace__c,
                                                 InboundMessage__c,
                                                 OutboundMessage__c
                                            FROM PlatformLog__c];
        System.assertEquals(errorLogs.size(), 1);
        System.assertEquals(errorLogs[0].Error__c, ex.getMessage(), PlatformEventsUtil.PE_TEST_ERROR_NOT_EQUALS);
        System.assertEquals(errorLogs[0].Source__c, Test_PlatformLog.class.getName(), PlatformEventsUtil.PE_TEST_SOURCE_NOT_EQUALS);
        System.assertEquals(errorLogs[0].StackTrace__c, ex.getStackTraceString(), PlatformEventsUtil.PE_TEST_STACK_NOT_EQUALS);
        System.assertEquals(errorLogs[0].InboundMessage__c, 'Test Body', PlatformEventsUtil.PE_TEST_INBOUND_NOT_EQUALS);
        System.assertEquals(errorLogs[0].OutboundMessage__c, 'Exception thrown', PlatformEventsUtil.PE_TEST_OUTBOUND_NOT_EQUALS);
    }

    /*
     * Verify log creation, fields are populated as expected.
    */
    @isTest static void testPlatformLogCreationWhenCustomExceptionThrown() {
        PlatformLog.PlatformLogException ex = new PlatformLog.PlatformLogException();
        PlatformLog.logException(Test_PlatformLog.class.getName(), ex);
        List<PlatformLog__c> errorLogs = [SELECT Id,
                                                 Error__c,
                                                 Source__c,
                                                 StackTrace__c,
                                                 InboundMessage__c,
                                                 OutboundMessage__c
                                            FROM PlatformLog__c];
        System.assertEquals(errorLogs.size(), 1);
        System.assertEquals(errorLogs[0].Error__c, ex.getMessage(), PlatformEventsUtil.PE_TEST_ERROR_NOT_EQUALS);
        System.assertEquals(errorLogs[0].Source__c, Test_PlatformLog.class.getName(), PlatformEventsUtil.PE_TEST_SOURCE_NOT_EQUALS);
        System.assertEquals(errorLogs[0].StackTrace__c, ex.getStackTraceString(), PlatformEventsUtil.PE_TEST_STACK_NOT_EQUALS);
        System.assertEquals(errorLogs[0].InboundMessage__c, null, PlatformEventsUtil.PE_TEST_INBOUND_NOT_EQUALS);
        System.assertEquals(errorLogs[0].OutboundMessage__c, null, PlatformEventsUtil.PE_TEST_OUTBOUND_NOT_EQUALS);
    }

    /*
     * Verify log creation, fields are populated as expected.
    */
    @isTest static void testPlatformLogCreationForSaveResult() {
        Account[] testAccs = new SObjectBuilder(Account.sObjectType)
            .setField(Account.Id, ValueProviderBuilder.provideDummyId(Account.sObjectType))
            .quantity(2)
            .build()
            .getRecords();

        String serializedSaveResult = '[' +
                '{"success":false,"errors":' +
                    '[{"statusCode":"REQUIRED_FIELD_MISSING","message":"Required fields are missing: [Name]","fields":["Name"]}]},' +
                '{"id":"0011k00000UlteVAAR","success":true,"errors":[]}' +
            ']';
        Database.SaveResult[] saveResults = (Database.SaveResult[]) JSON.deserialize(serializedSaveResult, List<Database.SaveResult>.class);

        System.assertEquals(2, saveResults.size(), 'Wrong number of SaveResults');
        System.assertEquals(1, saveResults[0].getErrors().size(), 'No errors on update Account with empty Name');

        PlatformLog.logErrors(Test_PlatformLog.class.getName(), saveResults, testAccs);

        List<PlatformLog__c> errorLogs = [SELECT Id,
                                                 Error__c,
                                                 Source__c,
                                                 StackTrace__c,
                                                 InboundMessage__c,
                                                 OutboundMessage__c
                                            FROM PlatformLog__c];
        System.assertEquals(errorLogs.size(), 1, 'Wrong number of PlatformLogs records');
        System.assert(String.isNotBlank(errorLogs[0].Error__c), PlatformEventsUtil.PE_TEST_ERROR_NOT_EQUALS);
        System.assert(errorLogs[0].Error__c.contains(testAccs[0].Id),
            'PlatformLog should contain id of failed record');
        System.assert(errorLogs[0].Error__c.contains(saveResults[0].getErrors()[0].getMessage()),
            'PlatformLog should contain error message of failed SaveResult');
        System.assertEquals(errorLogs[0].Source__c, Test_PlatformLog.class.getName(), PlatformEventsUtil.PE_TEST_SOURCE_NOT_EQUALS);
        System.assertEquals(errorLogs[0].StackTrace__c, null, PlatformEventsUtil.PE_TEST_STACK_NOT_EQUALS);
        System.assertEquals(errorLogs[0].InboundMessage__c, null, PlatformEventsUtil.PE_TEST_INBOUND_NOT_EQUALS);
        System.assertEquals(errorLogs[0].OutboundMessage__c, null, PlatformEventsUtil.PE_TEST_OUTBOUND_NOT_EQUALS);
    }

    /*
     * Verify that log could be retrieved and return corresponding fields.
    */
    @isTest static void testPlatformLogRetrieve() {
        System.NullPointerException ex = new System.NullPointerException();
        PlatformLog.logException(Test_PlatformLog.class.getName(), ex);
        List<PlatformLog__c> errorLogs = [SELECT Id FROM PlatformLog__c];
        PlatformLog__c errorLog = PlatformLog.retrieve(errorLogs[0].Id);
        System.assertEquals(errorLog.Error__c, ex.getMessage(), PlatformEventsUtil.PE_TEST_ERROR_NOT_EQUALS);
        System.assertEquals(errorLog.Source__c, Test_PlatformLog.class.getName(), PlatformEventsUtil.PE_TEST_SOURCE_NOT_EQUALS);
        System.assertEquals(errorLog.StackTrace__c, ex.getStackTraceString(), PlatformEventsUtil.PE_TEST_STACK_NOT_EQUALS);
        System.assertEquals(errorLog.InboundMessage__c, null, PlatformEventsUtil.PE_TEST_INBOUND_NOT_EQUALS);
        System.assertEquals(errorLog.OutboundMessage__c, null, PlatformEventsUtil.PE_TEST_OUTBOUND_NOT_EQUALS);
    }


    /*
     * Verify that log could be retrieved and return corresponding fields.
    */
    @isTest static void testMostRecentPlatformLogRetrieve() {
        //When no logs present most recent log should return null
        System.assertEquals(PlatformLog.getMostRecent(), null);

        //Create 2 logs, expect the second one to be returned as most recent
        System.NullPointerException ex = new System.NullPointerException();
        PlatformLog.logException(Test_PlatformLog.class.getName(), ex);
        PlatformLog.logException(Test_PlatformLog.class.getName(), ex);
        List<PlatformLog__c> errorLogs = [SELECT Id,
                                                 Error__c,
                                                 Source__c,
                                                 StackTrace__c,
                                                 InboundMessage__c,
                                                 OutboundMessage__c
                                            FROM PlatformLog__c
                                            ORDER BY CreatedDate DESC];
        System.assertEquals(errorLogs.size(), 2);
        PlatformLog__c errorLog = PlatformLog.getMostRecent();
        System.assertEquals(errorLog.Error__c, errorLogs[0].Error__c, PlatformEventsUtil.PE_TEST_ERROR_NOT_EQUALS);
        System.assertEquals(errorLog.Source__c, errorLogs[0].Source__c, PlatformEventsUtil.PE_TEST_SOURCE_NOT_EQUALS);
        System.assertEquals(errorLog.StackTrace__c, errorLogs[0].StackTrace__c, PlatformEventsUtil.PE_TEST_STACK_NOT_EQUALS);
        System.assertEquals(errorLog.InboundMessage__c, errorLogs[0].InboundMessage__c, PlatformEventsUtil.PE_TEST_INBOUND_NOT_EQUALS);
        System.assertEquals(errorLog.OutboundMessage__c, errorLogs[0].OutboundMessage__c, PlatformEventsUtil.PE_TEST_OUTBOUND_NOT_EQUALS);
    }

    /*
     * Verify that log creation could not raise DML limits issue. As they creation not bulkified.
    */
    @isTest static void testPlatformLogCreationDoesntThrowDMLLimits() {
        //Create more logs then DML limits allows.
        System.NullPointerException ex = new System.NullPointerException();
        for(Integer exThrown = 0; exThrown < (Limits.getLimitDMLStatements() + 1); exThrown++){
            PlatformLog.logException(Test_PlatformLog.class.getName(), ex);
        }
        System.assertEquals([SELECT COUNT() FROM PlatformLog__c], Limits.getLimitDMLStatements(), PlatformEventsUtil.PE_TEST_DML_LIMITS_NOT_EQUALS);
    }

    @IsTest
    private static void testLogExceptionsAsync() {
        System.NullPointerException ex = new System.NullPointerException();
        final Integer LOGS_NUMBER = 2;
        List<PlatformLog__c> logs = new List<PlatformLog__c>();
        for (Integer i = 0; i < LOGS_NUMBER; i++) {
            logs.add(new PlatformLog__c(
                Source__c = Test_PlatformLog.class.getName() + i,
                Error__c = ex.getMessage(),
                StackTrace__c = ex.getStackTraceString()
            ));
        }

        Test.startTest();
            PlatformLog.logExceptionsAsync(JSON.serialize(logs));
        Test.stopTest();

        List<PlatformLog__c> selectedLogs = [
            SELECT Id,
                Error__c,
                Source__c,
                StackTrace__c,
                InboundMessage__c,
                OutboundMessage__c
            FROM PlatformLog__c
            ORDER BY Source__c
        ];

        System.assertEquals(LOGS_NUMBER, selectedLogs.size(), LOGS_NUMBER + ' PlatformLog__c objects should be inserted');

        for (Integer i = 0; i < LOGS_NUMBER; i++) {
            System.assertEquals(logs[i].Source__c, selectedLogs[i].Source__c, 'Platform log should have correct source');
            System.assertEquals(selectedLogs[i].Error__c, logs[i].Error__c, 'Platform log should have correct error message');
        }
    }
}