@isTest
private class Test_ProfileSelector {
    //Profile names defined
	private static final String RC_ADMIN_USER = 'RC Admin User';
    private static final String RC_GUEST_USER = 'RC Guest User';

    //Assert messages defined
    private static final String ASSERT_MESSAGE = 'Profiles should be selected';
    private static final String ASSERT_EQUALS_MESSAGE = 'Wrong profile selected';

    @isTest
    private static void testSelectAllProfiles(){
        List<Profile> allProfiles = (List<Profile>) new ProfileSelector(true, true)
            .selectAllProfiles()
            .setLimit(10)
            .executeQuery();

        System.assert(allProfiles.size() == 10, ASSERT_MESSAGE);
    }

    @isTest
    private static void testSelectProfiles(){
        List<Profile> allProfiles = (List<Profile>) new ProfileSelector()
            .selectProfiles()
            .setLimit(10)
            .executeQuery();

        System.assert(allProfiles.size() == 10, ASSERT_MESSAGE);
    }


    @isTest
    private static void testSelectProfileByName(){
        List<Profile> profileByName = (List<Profile>) new ProfileSelector()
            .selectProfileByName(new List<Object>{new Set<String>{RC_ADMIN_USER}})
            .executeQuery();

        System.assert(profileByName.size() == 1, ASSERT_MESSAGE);
        System.assertEquals(RC_ADMIN_USER, profileByName[0].Name, ASSERT_EQUALS_MESSAGE);
    }

    @isTest
    static void testSelectProfileByName_SingleArgument() {
        Test.startTest();
            QueryFactory factory = new ProfileSelector()
                .selectProfileByName(RC_ADMIN_USER)
                .setQuery();
        Test.stopTest();

        Assert.areEqual(RC_ADMIN_USER, factory.bindings[0], 'Wrong input binding is used for the query');
    }

    @isTest
    private static void testSelectProfilesByNames(){
        List<Profile> profilesByNames = (List<Profile>) new ProfileSelector()
            .selectProfilesByNames(new List<Object>{new Set<String>{RC_ADMIN_USER}})
            .executeQuery();

        System.assert(profilesByNames.size() == 1, ASSERT_MESSAGE);
        System.assertEquals(RC_ADMIN_USER, profilesByNames[0].Name, ASSERT_EQUALS_MESSAGE);
    }

    @isTest
    private static void testSelectProfileById(){
        List<Profile> profilesByNames = (List<Profile>) new ProfileSelector()
            .selectProfileByName(new List<Object>{new Set<String>{RC_ADMIN_USER}})
            .executeQuery();

        List<Profile> profileById = (List<Profile>) new ProfileSelector()
            .selectProfileById(new List<Object>{new Set<Id>{profilesByNames[0].Id}})
            .executeQuery();

        System.assert(profilesByNames.size() == 1, ASSERT_MESSAGE);
        System.assertEquals(profilesByNames[0].Id, profileById[0].Id, ASSERT_EQUALS_MESSAGE);
    }
}