@IsTest
private class Test_AuraSFDescribeController {
    @IsTest
    static void testGetSelectField() {
        String sObjectName = 'Case';
        String recordTypeName = 'Support-Case';
        String fieldName = 'Status';

        Test.startTest();
        Response r = AuraSFDescribeController.getSelectField(sObjectName, recordTypeName, fieldName); 
        Test.stopTest();

        System.assertNotEquals(r, null);
    }
}