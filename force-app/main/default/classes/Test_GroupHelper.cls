@isTest
public class Test_GroupHelper {

    @isTest static void groupsQueriedPositive() {
        Group refundGroup = GroupHelper.groupDeveloperNameToGroup.get(GroupHelper.GROUP_SUPPORT_REFUND_APPROVAL_QUEUE);
        Group salesDeskGroup = GroupHelper.groupDeveloperNameToGroup.get(GroupHelper.GROUP_SALES_DESK_LEGAL_QUEUE);

        System.assert(refundGroup != null,
                assertGroupNotQueriedMessage(GroupHelper.GROUP_SUPPORT_REFUND_APPROVAL_QUEUE));
        System.assert(salesDeskGroup != null,
                assertGroupNotQueriedMessage(GroupHelper.GROUP_SALES_DESK_LEGAL_QUEUE));
        System.assertEquals(Limits.getQueries(), 1, ' Groups were queried more than once.');
    }

    private static String assertGroupNotQueriedMessage(String groupDeveloperName) {
        return 'Group with Developer name ' + groupDeveloperName + ' was not queried.' +
                ' Make sure that the group was not renamed/removed.';
    }

    @IsTest
    private static void testIsUserInQueue() {

        Test.startTest();
        System.assertEquals(false, GroupHelper.isUserInQueue(GroupHelper.GROUP_SUPPORT_REFUND_APPROVAL_QUEUE), 'Current user are not in queue');
        Test.stopTest();
    }

    @IsTest
    private static void testDefineGroupIdsBasedOnName() {

        Test.startTest();
        System.assertEquals(true, !GroupHelper.defineGroupIdsBasedOnName(new Set<String> {GroupHelper.GROUP_SUPPORT_REFUND_APPROVAL_QUEUE}).isEmpty(), 'Map must have values');
        Test.stopTest();
    }

    @IsTest
    private static void testGetGroupNameBasedOnUserKCSRole() {

        Test.startTest();
        System.assertEquals('KCS_Candidate', GroupHelper.getGroupNameBasedOnUserKCSRole('KCS Candidate'), 'KCS Candidate role must be in map');
        Test.stopTest();
    }

    @IsTest
    private static void testDefinePermissionSetIdBasedOnGroupName() {

        Test.startTest();
        System.assertEquals(true, !GroupHelper.definePermissionSetIdBasedOnGroupName().isEmpty(), 'Map must be empty');
        Test.stopTest();
    }
}