@isTest
public class Test_SupportPortalSitemapController {

    @testSetup static void setup() {
        KCSDataFactory.setup();
        knowledge__kav newArticle = new knowledge__kav(Title='test123451',summary='xyz123451',urlname='xyz12341');
        
        System.runAs(KCSDataFactory.admin) {
            insert newArticle;
            knowledge__kav obj1 = [SELECT Id,Title,KnowledgeArticleId FROM knowledge__kav WHERE id =: newArticle.Id];
            KbManagement.PublishingService.publishArticle(obj1.KnowledgeArticleId, true);
            List<Knowledge__DataCategorySelection> kDList = new List<Knowledge__DataCategorySelection>();
            kDlist.add(new Knowledge__DataCategorySelection(DataCategoryGroupName = 'RCProductVersion', DataCategoryName = 'ALL', ParentId = obj1.Id));
            insert kDList;
        }
        
        system.debug(newArticle);
        
    }
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    private static void testTestCase() {
        // Test data setup
        Test.setCurrentPage(new PageReference('/'));
        // Actual test
        Test.startTest();
        SupportPortalSitemapController testObject = new SupportPortalSitemapController();
        testObject.getUKPortal();
        testObject.getFAQList();
        string siturl = testObject.siteUrl;
        Test.stopTest();
    
        // Asserts
    }
}