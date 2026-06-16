@isTest
class Test_SWNMessageHelper {
    static final String STATUS = 'test status';
    static final String HEADER = 'test header';
    static final String MSG = 'test msg';
    static final String STACK_TRACE = 'test stackTrace';

    @isTest
    static void testInfoMessagesBuilder() {
        Test.startTest();
            SWNMessageHelper.InfoMessagesBuilder infoBuilder = new SWNMessageHelper.InfoMessagesBuilder();
        Test.stopTest();

        Assert.areEqual(Response.STATUS_INFO, infoBuilder.status, 'Status should be Info');
        Assert.areEqual(4, infoBuilder.messagesMap.size(), 'Messages map should contain 4 messages');
        Assert.isFalse(infoBuilder.messagesMap.get(SWNMessageHelper.LabelMessage.SUSPENDED_NGBS_STATUS) == null, 'SUSPENDED_NGBS_STATUS message should exist in messages map');
        Assert.isFalse(infoBuilder.messagesMap.get(SWNMessageHelper.LabelMessage.CONTRACTS_ALREADY_SYNCED) == null, 'CONTRACTS_ALREADY_SYNCED message should exist in messages map');
        Assert.isFalse(infoBuilder.messagesMap.get(SWNMessageHelper.LabelMessage.REPRICE_RESPONSE_EXCEEDS_HEAP) == null, 'REPRICE_RESPONSE_EXCEEDS_HEAP message should exist in messages map');
        
    }

    @isTest
    static void testSuccessMessagesBuilder() {
        Test.startTest();
            SWNMessageHelper.SuccessMessagesBuilder successBuilder = new SWNMessageHelper.SuccessMessagesBuilder();
        Test.stopTest();

        Assert.areEqual(Response.STATUS_SUCCESS, successBuilder.status, 'Status should be success');
        Assert.areEqual(15, successBuilder.messagesMap.size(), 'Messages map should contain 15 messages');
        Assert.isFalse(successBuilder.messagesMap.get(SWNMessageHelper.LabelMessage.SYNC_REPRICE_SUCCESS) == null, 'SYNC_REPRICE_SUCCESS message should exist in messages map');
        Assert.isFalse(successBuilder.messagesMap.get(SWNMessageHelper.LabelMessage.SYNC_CONTRACTS_SUCCESS) == null, 'SYNC_CONTRACTS_SUCCESS message should exist in messages map');
        Assert.isFalse(successBuilder.messagesMap.get(SWNMessageHelper.LabelMessage.REPRICE_IS_SKIPPED) == null, 'REPRICE_IS_SKIPPED message should exist in messages map');
    }

    @isTest
    static void testErrorMessagesBuilder() {
        Test.startTest();
            SWNMessageHelper.ErrorMessagesBuilder errorBuilder = new SWNMessageHelper.ErrorMessagesBuilder();
        Test.stopTest();

        Assert.areEqual(Response.STATUS_ERROR, errorBuilder.status, 'Status should be Error');
        Assert.areEqual(8, errorBuilder.messagesMap.size(), 'Messages map should contain 8 messages');
        Assert.isFalse(errorBuilder.messagesMap.get(SWNMessageHelper.LabelMessage.NO_PERMISSION_SYNC_WITH_NGBS_ERROR) == null, 'NO_PERMISSION_SYNC_WITH_NGBS_ERROR message should exist in messages map');
        Assert.isFalse(errorBuilder.messagesMap.get(SWNMessageHelper.LabelMessage.NO_PERMISSION_SYNC_RCCC_ERROR) == null, 'NO_PERMISSION_SYNC_RCCC_ERROR message should exist in messages map');
        Assert.isFalse(errorBuilder.messagesMap.get(SWNMessageHelper.LabelMessage.NO_PERMISSION_SYNC_RINGCX_ERROR) == null, 'NO_PERMISSION_SYNC_RINGCX_ERROR message should exist in messages map');
    }

    @isTest
    static void testSWNMessageConstructors() {
        Test.startTest();
            SWNMessageHelper.SWNMessage msg1 = new SWNMessageHelper.SWNMessage();
            SWNMessageHelper.SWNMessage msg2 = new SWNMessageHelper.SWNMessage(STATUS, HEADER, MSG);
            SWNMessageHelper.SWNMessage msg3 = new SWNMessageHelper.SWNMessage(STATUS, HEADER, MSG, STACK_TRACE);
        Test.stopTest();

        Assert.isTrue(String.isBlank(msg1.status), 'Status should be empty');
        Assert.isTrue(String.isBlank(msg1.header), 'Header should be empty');
        Assert.isTrue(String.isBlank(msg1.message), 'Msg should be empty');

        Assert.areEqual(STATUS, msg2.status, 'Status should be equal');
        Assert.areEqual(HEADER, msg2.header, 'Header should be equal');
        Assert.areEqual(MSG, msg2.message, 'Msg should be equal');

        Assert.areEqual(STATUS, msg3.status, 'Status should be equal');
        Assert.areEqual(HEADER, msg3.header, 'Header should be equal');
        Assert.areEqual(MSG, msg3.message, 'Msg should be equal');
        Assert.areEqual(STACK_TRACE, msg3.stackTrace, 'Stack Trace should be equal');
    }

    @isTest
    static void testCompositeResultConstructors() {
        Test.startTest();
            SWNMessageHelper.CompositeResult result1 = new SWNMessageHelper.CompositeResult();
            SWNMessageHelper.CompositeResult result2 = new SWNMessageHelper.CompositeResult(new SWNMessageHelper.SWNMessage(STATUS, HEADER, MSG));
        Test.stopTest();

        Assert.isTrue(String.isBlank(result1.baseMessage.status), 'Status should be empty');
        Assert.isTrue(String.isBlank(result1.baseMessage.header), 'Header should be empty');
        Assert.isTrue(String.isBlank(result1.baseMessage.message), 'Message should be empty');
        Assert.isTrue(result1.data.isEmpty(), 'There should be no additional data');

        Assert.areEqual(STATUS, result2.baseMessage.status, 'Status should be equal');
        Assert.areEqual(HEADER, result2.baseMessage.header, 'Header should be equal');
        Assert.areEqual(MSG, result2.baseMessage.message, 'Msg should be equal');
        Assert.isNotNull(result2.data, 'There should be additional data initialized');
    }

    @isTest
    static void testCompositeResultAddData() {
        final String key1 = 'Test key1';
        final String value1 = 'Test Value1';
        final String key2 = 'Test key2';
        final String value2 = 'Test Value2';
        final String key3 = 'Test key3';
        final String value3 = 'Test Value3';

        SWNMessageHelper.CompositeResult result = new SWNMessageHelper.CompositeResult(new SWNMessageHelper.SWNMessage(STATUS, HEADER, MSG));

        Test.startTest();
            result.addData(key1, value1);
            result.addData(key2, value2);
            result.addData(key3, value3);
        Test.stopTest();

        Assert.isFalse(result.data.isEmpty(), 'Additional data should be added');
        Assert.areEqual(value1, result.data.get(key1), 'Incorrect map value was received by key');
        Assert.areEqual(value2, result.data.get(key2), 'Incorrect map value was received by key');
        Assert.areEqual(value3, result.data.get(key3), 'Incorrect map value was received by key');
    }

    @isTest
    static void testGetSWNMessage() {
        SWNMessageHelper.InfoMessagesBuilder infoBuilder = new SWNMessageHelper.InfoMessagesBuilder();
        SWNMessageHelper.ErrorMessagesBuilder errorBuilder = new SWNMessageHelper.ErrorMessagesBuilder();
        SWNMessageHelper.SuccessMessagesBuilder successBuilder = new SWNMessageHelper.SuccessMessagesBuilder();

        Test.startTest();
            SWNMessageHelper.SWNMessage msg1 = infoBuilder.getSWNMessage(SWNMessageHelper.LabelMessage.SUSPENDED_NGBS_STATUS);
            SWNMessageHelper.SWNMessage msg2 = infoBuilder.getSWNMessage(SWNMessageHelper.LabelMessage.CONTRACTS_ALREADY_SYNCED);
            SWNMessageHelper.SWNMessage msg3 = errorBuilder.getSWNMessage(SWNMessageHelper.LabelMessage.NO_PERMISSION_SYNC_WITH_NGBS_ERROR);
            SWNMessageHelper.SWNMessage msg4 = errorBuilder.getSWNMessage(SWNMessageHelper.LabelMessage.NO_PERMISSION_SYNC_RCCC_ERROR);
            SWNMessageHelper.SWNMessage msg5 = successBuilder.getSWNMessage(SWNMessageHelper.LabelMessage.SYNC_CONTRACTS_SUCCESS);
            SWNMessageHelper.SWNMessage msg6 = successBuilder.getSWNMessage(SWNMessageHelper.LabelMessage.SYNC_DISCOUNTS_SUCCESS);
        Test.stopTest();

        Assert.areEqual(SWNMessageHelper.SUSPENDED_NGBS_STATUS_MSG, msg1.message, 'Message should be SUSPENDED_NGBS_STATUS');
        Assert.areEqual(SWNMessageHelper.CONTRACT_SYNCED_HEADER, msg2.header, 'Header should be CONTRACTS_ALREADY_SYNCED');
        Assert.areEqual(SWNMessageHelper.CONTRACT_SYNCED_MSG, msg2.message, 'Message should be CONTRACTS_ALREADY_SYNCED');
        Assert.areEqual(SWNMessageHelper.COMMON_PERMISSION_HEADER, msg3.header, 'Header should be NO_PERMISSION_SYNC_WITH_NGBS_ERROR');
        Assert.areEqual(SWNMessageHelper.COMMON_PERMISSION_MSG, msg3.message, 'Message should be NO_PERMISSION_SYNC_WITH_NGBS_ERROR');
        Assert.areEqual(SWNMessageHelper.COMMON_PERMISSION_HEADER + ' for Contact Center', msg4.header, 'Header should be NO_PERMISSION_SYNC_RCCC_ERROR');
        Assert.areEqual(SWNMessageHelper.COMMON_PERMISSION_MSG, msg4.message, 'Message should be NO_PERMISSION_SYNC_RCCC_ERROR');
        Assert.areEqual(SWNMessageHelper.SYNC_CONTRACT_HEADER, msg5.header, 'Header should be SYNC_CONTRACTS_SUCCESS');
        Assert.areEqual(SWNMessageHelper.SYNC_CONTRACT_MSG, msg5.message, 'Message should be SYNC_CONTRACTS_SUCCESS');
        Assert.areEqual(SWNMessageHelper.SYNC_DISCOUNT_HEADER, msg6.header, 'Header should be SYNC_DISCOUNTS_SUCCESS');
        Assert.areEqual(Label.Billing_success_message, msg6.message, 'Message should be SYNC_DISCOUNTS_SUCCESS');
    }

    @isTest
    static void testBuildSWNMessage() {
        SWNMessageHelper.InfoMessagesBuilder infoBuilder = new SWNMessageHelper.InfoMessagesBuilder();
        SWNMessageHelper.ErrorMessagesBuilder errorBuilder = new SWNMessageHelper.ErrorMessagesBuilder();
        SWNMessageHelper.SuccessMessagesBuilder successBuilder = new SWNMessageHelper.SuccessMessagesBuilder();

        Test.startTest();
            SWNMessageHelper.SWNMessage msg1 = infoBuilder.buildSWNMessage(HEADER, MSG, '');
            SWNMessageHelper.SWNMessage msg2 = errorBuilder.buildSWNMessage(HEADER, MSG, '');
            SWNMessageHelper.SWNMessage msg3 = successBuilder.buildSWNMessage(HEADER, MSG, '');
        Test.stopTest();
        
        Assert.areEqual(HEADER, msg1.header, 'Header is incorrect');
        Assert.areEqual(Response.STATUS_INFO, msg1.status, 'Status should be Info');
        Assert.areEqual(MSG, msg1.message, 'Message is incorrect');
        Assert.isTrue(String.isBlank(msg1.stackTrace), 'Stack trace should be empty');

        Assert.areEqual(HEADER, msg2.header, 'Header is incorrect');
        Assert.areEqual(Response.STATUS_ERROR, msg2.status, 'Status should be Error');
        Assert.areEqual(MSG, msg2.message, 'Message is incorrect');
        Assert.isTrue(String.isBlank(msg2.stackTrace), 'Stack trace should be empty');

        Assert.areEqual(HEADER, msg3.header, 'Header in incorect');
        Assert.areEqual(Response.STATUS_SUCCESS, msg3.status, 'Status shoud be Success');
        Assert.areEqual(MSG, msg3.message, 'Message is incorrect');
        Assert.isTrue(String.isBlank(msg3.stackTrace), 'Stack trace should be empty');
    }

    @isTest
    static void testBuildInfoMessage() {
        SWNMessageHelper.InfoMessagesBuilder infoBuilder = new SWNMessageHelper.InfoMessagesBuilder();

        Test.startTest();
            SWNMessageHelper.SWNMessage msg1 = infoBuilder.buildNothingToSyncInfoMsg();
            SWNMessageHelper.SWNMessage msg2 = infoBuilder.buildSuspendedNGBSStatusInfoMsg();
            SWNMessageHelper.SWNMessage msg3 = infoBuilder.buildContractAlreadySyncedInfoMsg();
            SWNMessageHelper.SWNMessage msg4 = infoBuilder.buildRepriceResponseExceedsHeapInfoMsg();
        Test.stopTest();

        Assert.areEqual(SWNMessageHelper.NOTHING_TO_SYNC_MSG, msg1.message, 'Incorrect info message');
        Assert.areEqual(SWNMessageHelper.SUSPENDED_NGBS_STATUS_MSG, msg2.message, 'Incorrect info message');
        Assert.areEqual(SWNMessageHelper.CONTRACT_SYNCED_MSG, msg3.message, 'Incorrect info message');
        Assert.areEqual(SWNMessageHelper.REPRICE_RESPONSE_EXCEEDS_HEAP_MSG, msg4.message, 'Incorrect info message');
    }

    @isTest
    static void testBuildSuccessMessage() {
        SWNMessageHelper.SuccessMessagesBuilder successBuilder = new SWNMessageHelper.SuccessMessagesBuilder();

        Test.startTest();
            SWNMessageHelper.SWNMessage msg1 = successBuilder.buildCancelContractSuccessMsg();
            SWNMessageHelper.SWNMessage msg2 = successBuilder.buildLicenseLimitsOverrideSuccessMsg();
            SWNMessageHelper.SWNMessage msg3 = successBuilder.buildChargeTermSyncedSuccessMsg();
            SWNMessageHelper.SWNMessage msg4 = successBuilder.buildUpgradeSyncSuccessMsg();
            SWNMessageHelper.SWNMessage msg5 = successBuilder.buildLicenseQuantitySyncedSuccessMsg();
            SWNMessageHelper.SWNMessage msg6 = successBuilder.buildAccountTerminationSuccessMsg();
            SWNMessageHelper.SWNMessage msg7 = successBuilder.buildPkgConsolidationSettingsSyncedSuccessMsg();
            SWNMessageHelper.SWNMessage msg8 = successBuilder.buildAccPackageLimitsSyncedSuccessMsg();
            SWNMessageHelper.SWNMessage msg9 = successBuilder.buildPaymentMethodSyncedSuccessMsg();
            SWNMessageHelper.SWNMessage msg10 = successBuilder.buildAccPaymentContactSyncedSuccessMsg();
            SWNMessageHelper.SWNMessage msg11 = successBuilder.buildSyncDiscountsSuccessMsg();
            SWNMessageHelper.SWNMessage msg12 = successBuilder.buildSyncContractsSuccessMsg();
            SWNMessageHelper.SWNMessage msg13 = successBuilder.buildSyncRepriceSuccessMsg();
            SWNMessageHelper.SWNMessage msg14 = successBuilder.buildRepriceIsSkippedSuccessMsg();
            SWNMessageHelper.SWNMessage msg15 = successBuilder.buildSyncSpendingLimitRetrieveSuccessMsg();
        Test.stopTest();

        Assert.areEqual(Label.Contract_Cancellation_succeeded, msg1.header, 'Incorrect success message');
        Assert.areEqual(Label.License_limits_override_succeeded, msg2.header, 'Incorrect success message');
        Assert.areEqual(SWNMessageHelper.CHARGE_TERM_SYNCED_MSG, msg3.message, 'Incorrect success message');
        Assert.areEqual(SWNMessageHelper.PKG_AND_LICENSES_QUANTITIES_SYNCED_MSG, msg4.message, 'Incorrect success message');
        Assert.areEqual(SWNMessageHelper.LICENSES_QUANTITIES_SYNCED_MSG, msg5.message, 'Incorrect success message');
        Assert.areEqual(Label.Account_Termination_succeeded, msg6.message, 'Incorrect success message');
        Assert.areEqual(SWNMessageHelper.PKG_CONSOLIDATION_SETTINGS_SYNCED_MSG, msg7.message, 'Incorrect success message');
        Assert.areEqual(SWNMessageHelper.ACC_PACKAGE_LIMITS_SYNCED_MSG, msg8.message, 'Incorrect success message');
        Assert.areEqual(SWNMessageHelper.PAYMENT_METHOD_SYNCED_MSG, msg9.message, 'Incorrect success message');
        Assert.areEqual(SWNMessageHelper.ACC_PAYMENT_CONTACT_SYNCED_MSG, msg10.message, 'Incorrect success message');
        Assert.areEqual(Label.Billing_success_message, msg11.message, 'Incorrect success message');
        Assert.areEqual(SWNMessageHelper.SYNC_CONTRACT_MSG, msg12.message, 'Incorrect success message');
        Assert.areEqual(SWNMessageHelper.SYNC_REPRICE_MSG, msg13.message, 'Incorrect success message');
        Assert.areEqual(SWNMessageHelper.REPRICE_SKIPPED_MSG, msg14.message, 'Incorrect success message');
        Assert.areEqual(SWNMessageHelper.SPENDING_LIMIT_RETRIEVED_MSG, msg15.message, 'Incorrect success message');
    }

    @isTest
    static void testBuildErrorMessage() {
        SWNMessageHelper.ErrorMessagesBuilder errorBuilder = new SWNMessageHelper.ErrorMessagesBuilder();

        Test.startTest();
            SWNMessageHelper.SWNMessage msg1 = errorBuilder.buildCancelContractIfNoPkgInfoErrorMsg();
            SWNMessageHelper.SWNMessage msg2 = errorBuilder.buildLimitOverrideIfPkgInfoExistsOnQuoteErrorMsg();
            SWNMessageHelper.SWNMessage msg3 = errorBuilder.buildLimitOverrideIfExistsLboxOnQliErrorMsg();
            SWNMessageHelper.SWNMessage msg4 = errorBuilder.buildOverrideLimitsForPOCErrorMsg();
            SWNMessageHelper.SWNMessage msg5 = errorBuilder.buildNoPermissionSyncWithNGBSErrorMsg();
            SWNMessageHelper.SWNMessage msg6 = errorBuilder.buildNoPermissionSyncRCCCErrorMsg();
            SWNMessageHelper.SWNMessage msg7 = errorBuilder.buildNoPermissionSyncRingCXErrorMsg();
            SWNMessageHelper.SWNMessage msg8 = errorBuilder.buildDirectDebitLimitExceededErrorMsg();
        Test.stopTest();

        Assert.areEqual(Label.Please_contact_your_manager, msg1.message, 'Incorrect error message');
        Assert.areEqual(Label.Please_contact_your_manager, msg2.message, 'Incorrect error message');
        Assert.areEqual(Label.Please_contact_your_manager, msg3.message, 'Incorrect error message');
        Assert.areEqual(Label.Please_contact_your_manager, msg4.message, 'Incorrect error message');
        Assert.areEqual(SWNMessageHelper.COMMON_PERMISSION_MSG, msg5.message, 'Incorrect error message');
        Assert.areEqual(SWNMessageHelper.COMMON_PERMISSION_HEADER + ' for Contact Center', msg6.header, 'Incorrect error header');
        Assert.areEqual(SWNMessageHelper.COMMON_PERMISSION_HEADER + ' for Engage', msg7.header, 'Incorrect error header');
        Assert.areEqual(Label.Approval_Direct_Debit_Limit_Error, msg8.message, 'Incorrect error message');
    }
}