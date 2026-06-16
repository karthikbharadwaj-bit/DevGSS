/*
* Name         : PostCopyManagerTest.cls
* Created By   : Fedor Golovanov (fgolovanov@aquivalabs.com)
* Created Date : 20/April/2017
* Description  : Test class for the post copy framework.
* Dependencies : PostCopyWorker.cls, PostCopyManager.cls, PostCopyUtil.cls
*/

@isTest
private class PostCopyManagerTest {

	public class TestPostCopyWorker extends PostCopyWorker {
		public override String getClassName(){
			return 'PostCopyManagerTest.TestPostCopyWorker';
		}

		public override void run() {

		}
	}

	//Create the custom settings with the apex classes that extends PostCopyWorker and let them run.
	private static void createTestData(Boolean isValid) {
		delete [SELECT Id FROM PostCopyTasks__c];
		List<PostCopyTasks__c> postCopyTaskList = new List<PostCopyTasks__c>();

		postCopyTaskList.add(createPostCopyTask('Test Handler', 'PostCopyManagerTest.TestPostCopyWorker', true, 1, false));
        postCopyTaskList.add(createPostCopyTask('Test Handler Async', 'PostCopyManagerTest.TestPostCopyWorker', true, 1, true));

		if (!isValid) {
            postCopyTaskList.add(createPostCopyTask('Incorrect taks', 'PostCopyInvalidTask', true, 3, false));
        }

		insert postCopyTaskList;
	}

	private static PostCopyTasks__c createPostCopyTask(
        String name, String developerName, Boolean isActive, Integer orderNumber, Boolean isAsync
    ) {
		return new PostCopyTasks__c(
			Name = name,
			DeveloperName__c = developerName,
			Active__c = isActive,
			OrderNumber__c = orderNumber,
            IsAsync__c = isAsync
		);
	}

	//Verify that with the correct data post copy tasks works without any issues
	@isTest
    static void testPostCopyManagerValid() {

		createTestData(true);
		PostCopyManager manager = new PostCopyManager();
		Test.testSandboxPostCopyScript(manager, UserInfo.getOrganizationId(), UserInfo.getOrganizationId(), 'box21');
		System.assert(PostCopyUtil.OVERALL_SUCCESS);

	}

	//Verify that with the post copy tasks do not work if we have incorrect apex class to run in the custom settings.
	@isTest
    static void testPostCopyManagerInvalid() {

		createTestData(false);
		PostCopyManager manager = new PostCopyManager();
		Test.testSandboxPostCopyScript(manager, UserInfo.getOrganizationId(), UserInfo.getOrganizationId(), 'box21');
		System.assert(!PostCopyUtil.OVERALL_SUCCESS);

	}

}