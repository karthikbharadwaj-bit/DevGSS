/*
* Name         : PostCopyBrandsResetTest.cls
* Created By   : Fedor Golovanov (fgolovanov@aquivalabs.com)
* Created Date : 20/April/2017
* Description  : Test class for the PostCopyBrandsReset. Part of the Sandbox Post Copy framework.
* Dependencies : PostCopyBrandsReset.cls, PostCopyWorker.cls
*/

@isTest
private class PostCopyBrandsResetTest {

    private static PriceBook2 testPriceBook;

    //Create the custom settings with the apex classes that extends PostCopyWorker and let them run.
    private static void createTestData(){
        List<PostCopyTasks__c> postCopyTaskList = new List<PostCopyTasks__c>();

        postCopyTaskList.add(createPostCopyTask('Reset Brands', 'PostCopyBrandsReset', true, 1));

        insert postCopyTaskList;

        testPriceBook = new Pricebook2(Name = 'Test Price Book', Description ='Test Price Book Products', IsActive = true, Line_Range_Min__c = 5, BrandId__c = 1210);
        insert testPriceBook;
    }

    private static PostCopyTasks__c createPostCopyTask(String name, String developerName, Boolean isActive, Integer orderNumber){
        return new PostCopyTasks__c(
            Name = name,
            DeveloperName__c = developerName,
            Active__c = isActive,
            OrderNumber__c = orderNumber
        );
    }

    //Verify that the file with the brands exists in the static resources and brands were successfully inserted  
    @isTest static void testPostCopyBrandsResetInitials() {
        createTestData();
        PostCopyManager manager = new PostCopyManager();
        Test.testSandboxPostCopyScript(manager, UserInfo.getOrganizationId(), UserInfo.getOrganizationId(), 'box21');
        System.assertEquals([Select Id From StaticResource s where s.Name LIKE 'Brands'].size(), 1);
        Map<String, Schema.DescribeFieldResult> brandDescribe = PostCopyBrandsReset.generateMapDescribe(Schema.SObjectType.schedulerConfiguration__c.fields.getMap());
        System.assertEquals([Select count() From schedulerConfiguration__c], PostCopyBrandsReset.createNewBrands(brandDescribe).size());
    }
	
}