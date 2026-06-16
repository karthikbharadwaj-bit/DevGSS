@isTest
private class Test_OrgLimitsSlackNotification {

    private static OrgLimitsSlackNotification.OrgLims limits;

    /**
     * It's not possible to call System.OrgLimits from Test environment, so as a workaround, we need to insert the limits by ourselves
    */
    private static void prepareDataForOrgLimits() {
        limits = new OrgLimitsSlackNotification.OrgLims();

        limits.elems.add(new OrgLimitsSlackNotification.OrgLim('SingleEmail', 4800, 5000));
        limits.elems.add(new OrgLimitsSlackNotification.OrgLim('PermissionSets', 932, 1000));
        limits.elems.add(new OrgLimitsSlackNotification.OrgLim('DailyAnalyticsDataflowJobExecutions', 59, 60));
        limits.elems.add(new OrgLimitsSlackNotification.OrgLim('DataStorageMB', 187, 200));
        limits.elems.add(new OrgLimitsSlackNotification.OrgLim('FileStorageMB', 195, 200));
    }

    /**
    @description: Call asynchronous callout and check if synchronous callout response is equal to expected value from HttpCalloutMock
    */
	@isTest static void verifyOrgLimitsNotificationPostsSlackMessageSuccesfully() {
        // Set mock callout class
        Test.setMock(HttpCalloutMock.class, new OrgLimitsSlackNotificationCalloutMock());
        prepareDataForOrgLimits();

        Test.startTest();
            // Call method to test.
            OrgLimitsSlackNotification.checkLimitsAndSendWebhook(90, limits);

            // This causes a fake response to be sent from the class that implements HttpCalloutMock
            HttpResponse response = OrgLimitsSlackNotification.SlackPostCallout('test');
        Test.stopTest();
        // Verify response received fake values
        final String SLACK_NOTIFICATION_NOT_SENT = 'HTTP request not succeeded';
        System.assertEquals(200, response.getStatusCode(), SLACK_NOTIFICATION_NOT_SENT);
    }
}