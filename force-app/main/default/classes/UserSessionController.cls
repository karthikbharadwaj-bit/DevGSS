public with sharing class UserSessionController {
    @TestVisible
    private static final String MOCK_USER_SESSION_ID = '123456789';

    public static String fetchUserSessionId() {
        String vfContent = !Test.isRunningTest()
            ? Page.UserSessionPage?.getContent().toString()
            : 'StartUserSessionId' + MOCK_USER_SESSION_ID + 'EndUserSessionId';

        Integer startPosition = vfContent?.indexOf('StartUserSessionId') + 'StartUserSessionId'.length();
        Integer endPosition = vfContent?.indexOf('EndUserSessionId');

        return vfContent?.substring(startPosition, endPosition);
    }
}