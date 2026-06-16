@isTest
private class TestAllGeneral {

    @SuppressWarnings('PMD.AvoidHardcodingId')
    @isTest
    static void testRCSupportArticleRating() {
        KCSDataFactory.setup();
        System.runAs(KCSDataFactory.admin) {
            RC_Article_Rating__c rcObj = new RC_Article_Rating__c();
            rcObj.Name = 'Test Article';
            rcObj.RC_Average_Rating__c = 5;
            rcObj.Article_Id__c = 'Test1';
            insert rcObj;
            Test.startTest();
            ApexPages.CurrentPage().getParameters().put('id', 'Test1');
            RCSupportArticleRating objRCSupportArticleRating = new RCSupportArticleRating();
            ApexPages.CurrentPage().getParameters().put('token', '');
            ApexPages.CurrentPage().getParameters().put('retURL', 'test');
            objRCSupportArticleRating.getAuthToken();
            ApexPages.CurrentPage().getParameters().put('token', 'test');
            objRCSupportArticleRating.getAuthToken();
            RCSupportArticleRating.articleCountSave2(2, 'kA280000000Gndo', '123.123.123.1', 'test', 'test');
            Integer articleCount = RCSupportArticleRating.articleCountSave2(2, 'kA280000000Gndo1', '123.123.123.1', 'test', 'test');
            String userName = RCSupportArticleRating.getUsersName(UserInfo.getUserId());

            knowledge__kav newArticle = new knowledge__kav(Title = 'test', summary = 'xyz', urlname = 'xyz');
            insert newArticle;
            knowledge__kav obj1 = [SELECT Id, Title, KnowledgeArticleId FROM knowledge__kav WHERE id = :newArticle.Id];
            KbManagement.PublishingService.publishArticle(obj1.KnowledgeArticleId, true);
            RC_Article_Rating__c rcArticleRating = new RC_Article_Rating__c();
            rcArticleRating.Name = 'Test Article';
            rcArticleRating.RC_Average_Rating__c = 5;
            rcArticleRating.Article_Id__c = obj1.KnowledgeArticleId;
            //insert rcObj;
            RCSupportArticleRating.setArticleDetails(rcArticleRating);

            Test.stopTest();

            System.assertEquals(articleCount, 2);
            System.assertEquals(userName, UserInfo.getName());
        }
    }

    @isTest
    static void testsyncAccountSharingRuleScheduler() {
        syncAccountSharingRuleScheduler obj = new syncAccountSharingRuleScheduler();
        obj.execute(null);

        System.assertNotEquals(obj, null);
    }

    @isTest
    static void Test_ForgotPasswordController() {
    	ForgotPasswordController controller = new ForgotPasswordController();
    	controller.username = 'test@salesforce.com';     	
    	System.assertEquals(controller.forgotPassword(),null); 
    }
    
    @isTest
    static void testCustomTabsController() {
        CustomTabsController obj = new CustomTabsController();

        System.assertNotEquals(obj, null);
    }

    @isTest
    static void testChangePasswordController() {
        ChangePasswordController controller = new ChangePasswordController();
        Test.startTest();
        controller.oldPassword = '123456';
        controller.newPassword = 'qwerty1';
        controller.verifyNewPassword = 'qwerty1';
        System.assertEquals(controller.changePassword(),null);
        Test.stopTest();
    }

}