@IsTest
public with sharing class Test_AutomatedProcessUserContext {

    @IsTest
    private static void testUpdatingUserProfileIdInAutomatedProcessUsersContext() {
        User notAdminUser = buildUserWithProfileId(getAnySalesProfile()?.Id);
        insert notAdminUser;

        User automatedProcessUser = (User) new ListOptional(
            new UserSelector()
                .selectUsersByProfileIds(new Set<id>{ProfileHelper.PROFILE_ID_AUTOMATED_PROCESS_USER})
                .executeQuery()
            )
            .getFirst();

        Test.startTest();
        System.runAs(automatedProcessUser) {
            notAdminUser.ProfileId = ProfileHelper.PROFILE_ID_SYSADMIN;
            update notAdminUser;
        }
        Test.stopTest();

        User adminUser = (User) new ListOptional(
            new UserSelector()
                .selectUsersByIds(new Set<id>{notAdminUser.Id})
                .executeQuery()
            )
            .getFirst();

        System.assertEquals(ProfileHelper.PROFILE_ID_SYSADMIN, adminUser.ProfileId,
            'Not Admin user should have System Administrator profile after update');
    }

    private static Profile getAnySalesProfile() {
        return (Profile) new ListOptional(
            new ProfileSelector()
                .selectAllProfiles()
                .setCondition('Name Like \'Sales%\'')
                .executeQuery())
            .getFirst();
    }

    private static User buildUserWithProfileId(final Id profileId) {
        return (User) new SObjectBuilder(User.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(User.SObjectType))
            .setField(User.ProfileId, profileId)
            .build()
            .getRecord();
    }
}