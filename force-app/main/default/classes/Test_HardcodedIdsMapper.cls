@isTest
private class Test_HardcodedIdsMapper {
    private static final String FAKE_ID = 'FakeId';

    @isTest 
    private static void testgetMatchedObjectIdSigle() {
        Id adminId = [
            SELECT Id
            FROM Profile
            WHERE Name = 'System Administrator'
            LIMIT 1
        ].Id;
        Test.startTest();
            String objectId = HardcodedIdsMapper.getMatchedObjectId(String.valueOf(adminId));
            String fakeId = HardcodedIdsMapper.getMatchedObjectId(String.valueOf(FAKE_ID));
        Test.stopTest();

        System.assertNotEquals(null,
                                adminId,
                                'Hardcoded ID was assigned incorrectly.');
        System.assertNotEquals(null,
                                fakeId,
                                'Hardcoded ID was assigned incorrectly.');
    }

    @isTest 
    private static void testgetMatchedObjectIdMultiple() {
        Id adminId = [
            SELECT Id
            FROM Profile
            WHERE Name = 'System Administrator'
            LIMIT 1
        ].Id;
        Test.startTest();
            List<String> objectId = HardcodedIdsMapper.getMatchedObjectId(new List<String>{adminId});
            List<String> fakeId = HardcodedIdsMapper.getMatchedObjectId(new List<String>{FAKE_ID});
        Test.stopTest();

        System.assertNotEquals(0,
                                objectId.size(),
                                'Hardcoded ID was assigned incorrectly.');
        System.assertNotEquals(0,
                                fakeId.size(),
                                'Hardcoded ID was assigned incorrectly.');
    }
}