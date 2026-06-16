@IsTest
public with sharing class Test_PostCopyEmployeesInsert {

    public static final String PROFILE_NAME = 'Sales Rep - Lightning';

    @TestSetup
    private static void createTestData() {
        List<PostCopyTasks__c> postCopyTaskList = new List<PostCopyTasks__c>();

        postCopyTaskList.add(getNewPostCopyTask('Post Copy Employees Insert', 'PostCopyEmployeesInsert', true, 7));
        insert postCopyTaskList;

        PostCopyEmployeesManagement__c employeesSetting = getNewPostCopyEmployeesManagementSetting();
        insert employeesSetting;
    }

    @IsTest
    private static void testCreateEmployeesRecords() {
        Set<String> profiles = new Set<String>();
        List<PostCopyEmployeesManagement__c> settings = PostCopyEmployeesManagement__c.getAll().values();

        for(PostCopyEmployeesManagement__c record : settings) {
            profiles.add(record.Profile_Name__c);
        }

        System.assertEquals([SELECT Name FROM Employee__c].size(), 0);

        Test.startTest();
        Test.testSandboxPostCopyScript(new PostCopyManager(), UserInfo.getOrganizationId(), UserInfo.getOrganizationId(), UserInfo.getOrganizationName());
        Test.stopTest();

        //Verify that the number of new Employee records matches the number of users with the required profile
        System.assertEquals([SELECT Name FROM Employee__c].size(), [SELECT Id, Profile.Name FROM User WHERE Profile.Name = :PROFILE_NAME].size());

    }

    private static PostCopyEmployeesManagement__c getNewPostCopyEmployeesManagementSetting(){
        return new PostCopyEmployeesManagement__c(
            Name = PROFILE_NAME,
            Profile_Name__c = PROFILE_NAME
        );
    }

    private static PostCopyTasks__c getNewPostCopyTask(String name, String developerName, Boolean isActive, Integer orderNumber){
        return new PostCopyTasks__c(
            Name = name,
            DeveloperName__c = developerName,
            Active__c = isActive,
            OrderNumber__c = orderNumber
        );
    }
}