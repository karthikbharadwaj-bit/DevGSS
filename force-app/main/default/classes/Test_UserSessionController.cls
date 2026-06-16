@IsTest
public with sharing class Test_UserSessionController {
    @IsTest
    private static void testFetchingUserSessionId() {
        final String userSessionId = UserSessionController.fetchUserSessionId();
        System.assertEquals(UserSessionController.MOCK_USER_SESSION_ID, userSessionId);
    }
}