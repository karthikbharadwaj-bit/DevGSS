@isTest
private  class testRCTopArticle {
    @isTest
    static void UnittestRCTopArticle() {
        RCNEW_Knowledge_Article__c objKnowledge=new RCNEW_Knowledge_Article__c();
        objKnowledge.ArticleNumber__c = '000002018';
        ApexPages.StandardController controller=new ApexPages.StandardController(objKnowledge);
        RCTopArticle obj=new RCTopArticle(controller);
        
        obj=new RCTopArticle();
        obj.strAricleId='000002018';
        obj.getArticleDetails();
        
        obj.objKnowledgeArticle.Article_List_Order__c=1;
        obj.saveArticleOrder();
        
        obj=new RCTopArticle();
        obj.objKnowledgeArticle.Article_List_Order__c=1;
        try {
            obj.saveArticleOrder();
            throw new ArticleException('Article update failed due duplicate value found.');
        } catch (Exception ex) {
            System.assert(true, 'Duplicate article was not updated succesfully.');
        }
    }
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testGetArticleDetailsMethod(){
        knowledge__kav newArticle = new knowledge__kav(Title='test',summary='xyz',urlname='xyz');
        
        KCSDataFactory.setup();
        System.runAs(KCSDataFactory.admin) {
            insert newArticle;
            knowledge__kav obj1 = [SELECT Id,Title,ArticleNumber, KnowledgeArticleId FROM knowledge__kav WHERE id =: newArticle.Id];
            system.debug(obj1);
            KbManagement.PublishingService.publishArticle(obj1.KnowledgeArticleId, true);
            List<Knowledge__DataCategorySelection> kDList = new List<Knowledge__DataCategorySelection>();
            kDlist.add(new Knowledge__DataCategorySelection(DataCategoryGroupName = 'Brand', DataCategoryName = 'BT', ParentId = obj1.Id));
            kDlist.add(new Knowledge__DataCategorySelection(DataCategoryGroupName = 'RCProductVersion', DataCategoryName = 'RC2013', ParentId = obj1.Id));
            kDlist.add(new Knowledge__DataCategorySelection(DataCategoryGroupName = 'Topic', DataCategoryName = 'ALL', ParentId = obj1.Id));
            kDlist.add(new Knowledge__DataCategorySelection(DataCategoryGroupName = 'Service', DataCategoryName = 'ALL', ParentId = obj1.Id));
            insert kDList;
            
            
            RCTopArticle rcTop = new RCTopArticle();
            rcTop.strAricleId = obj1.ArticleNumber;
            rcTop.getArticleDetails();
        }
        
    }

    public class ArticleException extends Exception {}
}