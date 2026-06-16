@isTest
private class Test_PostCopyUtil {

    @isTest
    private static void testExceptionsForSandboxWithoutPermissionSet() {

        Boolean isExpectedExceptionThrown = false;
        try {
            PostCopyUtil.isProduction = false;
            new PostCopyUtil.CustomSandboxContext();
        } catch (PostCopyUtil.CustomSandboxContextException ex) {
            System.assert(
                ex.getMessage().contains(PostCopyUtil.HAS_NO_PERMISSION_EXCEPTION_MESSAGE),
                'Exception should contain specific message'
            );
            isExpectedExceptionThrown = true;
        }
        System.assert(isExpectedExceptionThrown, 'Expected exception should be thrown');


        isExpectedExceptionThrown = false;
        try {
            PostCopyUtil.isProduction = false;
            new PostCopyUtil.CustomSandboxContext('some_box_name');
        } catch (PostCopyUtil.CustomSandboxContextException ex) {
            System.assert(
                ex.getMessage().contains(PostCopyUtil.HAS_NO_PERMISSION_EXCEPTION_MESSAGE),
                'Exception should contain specific message'
            );
            isExpectedExceptionThrown = true;
        }
        System.assert(isExpectedExceptionThrown, 'Expected exception should be thrown');
    }

    @isTest
    private static void testExceptionForProduction() {

        Boolean isExpectedExceptionThrown = false;
        try {
            PostCopyUtil.isProduction = true;
            new PostCopyUtil.CustomSandboxContext();
        } catch (PostCopyUtil.CustomSandboxContextException ex) {
            System.assert(
                ex.getMessage().contains(PostCopyUtil.PRODUCTION_EXCEPTION_MESSAGE),
                'Exception should contain specific message'
            );
            isExpectedExceptionThrown = true;
        }
        System.assert(isExpectedExceptionThrown, 'Expected exception should be thrown');
    }

    @isTest
    private static void testForSandboxWithPermissionSet() {

        Profile standardUserProfile = (Profile) new ProfileSelector()
            .selectProfileByName(new List<String>{'Standard User'})
            .executeQuery()
            .get(0);

        User testUser = (User) new SobjectBuilder(User.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    User.Username => 'test!user@gmail.com',
                    User.LastName => 'TestTest',
                    User.Email => 'test_user@gmail.com',
                    User.Alias => 'test',
                    User.TimeZoneSidKey => 'America/Los_Angeles',
                    User.LocaleSidKey => 'en_US',
                    User.EmailEncodingKey => 'UTF-8',
                    User.ProfileId => standardUserProfile.Id,
                    User.LanguageLocaleKey => 'en_US',
                    User.Hierarchy_Role__c => 'Sales Rep'
                })
            .create()
            .getRecord();

        SetupEntityAccess sea = (SetupEntityAccess) new SetupEntityAccessSelector()
            .selectSetupEntityAccessByCustomPermissionName(new List<Object>{CustomPermissionHelper.PERMISSION_RUN_POST_COPY_FRAMEWORK})
            .executeQuery()
            .get(0);

        Id runPostCopyPermissionSetId = sea.ParentId;

        new SobjectBuilder(PermissionSetAssignment.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    PermissionSetAssignment.AssigneeId => testUser.Id,
                    PermissionSetAssignment.PermissionSetId => runPostCopyPermissionSetId
                })
            .create();

        System.runAs(testUser) {

            Test.startTest();

                PostCopyUtil.isProduction = false;
                PostCopyUtil.CustomSandboxContext ctxt = new PostCopyUtil.CustomSandboxContext();

                System.assertNotEquals(null, ctxt, 'CustomSandboxContext instance should be created');
                System.assert(
                    String.isNotEmpty(ctxt.organizationId()),
                    'CustomSandboxContext should contain organizationId'
                );
                System.assert(
                    String.isNotEmpty(ctxt.sandboxId()),
                    'CustomSandboxContext should contain sandboxId'
                );
                System.assert(
                    String.isNotEmpty(ctxt.sandboxName()),
                    'CustomSandboxContext should contain sandboxName'
                );

            Test.stopTest();

        }
    }
}