@isTest
public class TestKnowledgeArticleController {
    
    private static final String PROFILE_NAME = 'Com Integration Profile';
    private static final String LANGUAGE_EN_US = 'en_US';
    
    // Utility method to create a User with a specific KCS role
    private static User createKCSUser(String firstName, String lastName, String email, String kcsRole) {
        return (User) new SObjectBuilder(User.SObjectType)
            .setField(User.FirstName, firstName)
            .setField(User.LastName, lastName)
            .setField(User.Email, email)
            .setField(User.Username, email + System.currentTimeMillis())
            .setField(User.Alias, email.substring(0, 5))
            .setField(User.TimeZoneSidKey, 'America/Los_Angeles')
            .setField(User.LocaleSidKey, LANGUAGE_EN_US)
            .setField(User.EmailEncodingKey, 'UTF-8')
            .setField(User.LanguageLocaleKey, LANGUAGE_EN_US)
            .setField(User.ProfileId, [SELECT Id FROM Profile WHERE Name = :PROFILE_NAME LIMIT 1].Id)
            .setField(User.KCS_Role__c, kcsRole)
            .create()
            .getRecord();
    }
    
    // Utility method to create a Knowledge Article
    private static Knowledge__kav createKnowledgeArticle(String title, String urlName, User user) {
        Knowledge__kav article = new Knowledge__kav();
        article.Title = title;
        article.UrlName = urlName;
        article.Language = LANGUAGE_EN_US;
        
        insert article; 
        return article;
    }
    
    // Utility method to create a ContentVersion
    private static ContentVersion createContentVersion(String title, String content, String path, String articleId) {
        ContentVersion cv = new ContentVersion();
        cv.Title = title;
        cv.VersionData = Blob.valueOf(content);
        cv.PathOnClient = path;
        if (articleId != null) {
            cv.Knowledge__c = articleId; 
        }
        
        insert cv; 
        return cv;
    }
    
    // Test case to verify the fetching of Knowledge Article and ContentVersion
    @isTest
    static void testGetKnowledgeArticleContentVersions() {
        User kcsCoachUser = createKCSUser('Test', 'KCSCoach', 'testkcscoach@example.com', 'KCS Coach');
        
        System.runAs(kcsCoachUser) {
            // Create a Knowledge Article and associated ContentVersion
            Knowledge__kav article = createKnowledgeArticle('Test Knowledge Article', 'Test-Url-1', kcsCoachUser);
            ContentVersion cv = createContentVersion(
                'Test Document',
                '<html><body>This is a test document.</body></html>',
                'TestDocument.html',
                article.Id
            );
            
            Test.startTest();
            KnowledgeArticleController.ContentVersionWrapper result = 
                KnowledgeArticleController.getKnowledgeArticleContentVersions(article.Id);
            Test.stopTest();
            
            System.assertNotEquals(null, result, 'Expected non-null result.');
            System.assertEquals('Test Document', result.title, 'Expected title to match ContentVersion Title.');
            
            // Decode the Base64 content to check for the HTML content
            String decodedContent = EncodingUtil.base64Decode(result.base64Content).toString();
            System.assert(decodedContent.contains('<body>This is a test document.</body>'),
                          'Expected decoded HTML content to contain specific text.');
        }
    }
    
    // Test case for fetching the file content based on ContentVersion Id
    @isTest
    static void testGetFileContent() {
        ContentVersion cv = createContentVersion(
            'Test Document',
            '<html><body>This is a test document.</body></html>',
            'TestDocument.html',
            null // No articleId needed in this case
        );
        
        System.assertNotEquals(null, cv.Id, 'ContentVersion should have a valid Id after insertion.');
        
        Test.startTest();
        String base64Content = KnowledgeArticleController.getFileContent(cv.Id); // Base64 encoded content
        Test.stopTest();
        
        // Decode the Base64 content to check for the HTML content
        String decodedContent = EncodingUtil.base64Decode(base64Content).toString();
        
        System.assertNotEquals(null, base64Content, 'Expected non-null Base64 content.');
        System.assert(decodedContent.contains('<body>This is a test document.</body>'),
                      'Expected decoded HTML content to contain specific text.');
    }
}