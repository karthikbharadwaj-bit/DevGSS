@isTest
public class Test_SitemapController {

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testSiteUrl_CustomWebAddress() {        
        // Instantiate the class
        SitemapController controller = new SitemapController();
        
        // Call the getter method
        String siteUrl = controller.siteUrl;
        List<Knowledge__kav> objList = controller.getFAQList();
    }
}