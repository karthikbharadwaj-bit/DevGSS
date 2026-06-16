@isTest
public class Test_PermissionSetSelector {

    public static final String TEST_PERMISSION_SET_NAME = 'Test Permission Set';

    @isTest
    private static void testSelectPermissionSetByIds() {
        PermissionSet testPs = (PermissionSet) new SobjectBuilder(PermissionSet.SObjectType)
            .setField(PermissionSet.Label, TEST_PERMISSION_SET_NAME)
            .setField(PermissionSet.Name, 'Test_Permission_Set')
            .create()
            .getRecord();

        Test.startTest();

            List<PermissionSet> testPss = (List<PermissionSet>) new PermissionSetSelector()
                .selectPermissionSetByIds(new List<Object>{new List<Id>{testPs.Id}})
                .executeQuery();

        Test.stopTest();

        System.assertEquals(1, testPss.size(), 'List of Permission Sets must returned');
        System.assertEquals(testPs.Label, testPss[0].Label, 'Label must match');
    }

    @isTest
    private static void testSelectPermissionSetByLabel() {
        PermissionSet testPs = (PermissionSet) new SobjectBuilder(PermissionSet.SObjectType)
            .setField(PermissionSet.Label, TEST_PERMISSION_SET_NAME)
            .setField(PermissionSet.Name, 'Test_Permission_Set')
            .create()
            .getRecord();

        Test.startTest();

            List<PermissionSet> testPss = (List<PermissionSet>) new PermissionSetSelector()
                .selectPermissionSetByLabel(new List<Object>{testPs.Label})
                .executeQuery();

        Test.stopTest();

        System.assertEquals(1, testPss.size(), 'List of Permission Sets must returned');
        System.assertEquals(testPs.Label, testPss[0].Label, 'Label must match');
    }

    @isTest
    private static void testSelectPermissionSetsByName() {
        PermissionSet testPs = (PermissionSet) new SobjectBuilder(PermissionSet.SObjectType)
            .setField(PermissionSet.Label, TEST_PERMISSION_SET_NAME)
            .setField(PermissionSet.Name, 'Test_Permission_Set')
            .create()
            .getRecord();

        Test.startTest();

        List<PermissionSet> testPss = (List<PermissionSet>) new PermissionSetSelector()
            .selectPermissionSetsByName(new List<Object>{new List<String>{testPs.Name}})
            .executeQuery();

        Test.stopTest();

        System.assertEquals(1, testPss.size(), 'List of Permission Sets must returned');
        System.assertEquals(testPs.Name, testPss[0].Name, 'Name must match');
    }

    @isTest
    private static void testSelectPermissionSetsByPSAssignment() {
        PermissionSet testPs = (PermissionSet) new SobjectBuilder(PermissionSet.SObjectType)
            .setField(PermissionSet.Label, TEST_PERMISSION_SET_NAME)
            .setField(PermissionSet.Name, 'Test_Permission_Set')
            .create()
            .getRecord();

        Test.startTest();

        List<PermissionSet> testPss = (List<PermissionSet>) new PermissionSetSelector()
            .selectPermissionSetsByPSAssignment(new List<Object>{new List<String>{ testPs.Id }})
            .executeQuery();

        Test.stopTest();

        System.assertEquals(1, testPss.size(), 'List of Permission Sets must returned');
        System.assertEquals(testPs.Id, testPss[0].Id, 'Id must match');
    }
}