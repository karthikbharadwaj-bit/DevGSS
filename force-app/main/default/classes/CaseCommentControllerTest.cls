@isTest
public class CaseCommentControllerTest {
    
    @TestSetup
    static void setupTestData() {
        Case c = (Case) new SObjectBuilder(Case.SObjectType)
            .quantity(1)
            .setFields(
                new Map<SObjectField, Object>{
                    Case.Subject => 'testCase',
                        Case.Status => 'New',
                        Case.Origin => 'Phone'
                        }
            )
            .create()
            .getRecord();
    }
    
    @isTest
    static void testConstructorWithValidCaseId() {
        Case testCase = [SELECT Id FROM Case LIMIT 1];
        
        Test.setCurrentPageReference(new PageReference('Page.CaseCommentPage'));
        ApexPages.currentPage().getParameters().put('Id', testCase.Id);
        
        ApexPages.StandardController stdController = new ApexPages.StandardController(testCase);
        
        Test.startTest();
        CaseCommentController controller = new CaseCommentController(stdController);
        Test.stopTest();
        
        Assert.areEqual(testCase.Id, controller.caseId, 'Case ID should be set from page parameter');
    }
    
    @isTest
    static void testConstructorWithNoCaseId() {
        Case testCase = [SELECT Id FROM Case LIMIT 1];
        
        Test.setCurrentPageReference(new PageReference('Page.CaseCommentPage'));
        
        ApexPages.StandardController stdController = new ApexPages.StandardController(testCase);
        
        Test.startTest();
        CaseCommentController controller = new CaseCommentController(stdController);
        Test.stopTest();
        
        Assert.areEqual(null, controller.caseId, 'Case ID should be null when not in page parameters');
    }
    
    @isTest
    static void testSaveCommentSuccess() {
        Case testCase = [SELECT Id FROM Case LIMIT 1];
        
        Test.setCurrentPageReference(new PageReference('Page.CaseCommentPage'));
        ApexPages.currentPage().getParameters().put('Id', testCase.Id);
        
        ApexPages.StandardController stdController = new ApexPages.StandardController(testCase);
        CaseCommentController controller = new CaseCommentController(stdController);
        
        controller.bodyText = 'This is a test comment';
        controller.isPublic = true;
        
        Test.startTest();
        PageReference result = controller.saveComment();
        Test.stopTest();
        
        List<CaseComment> comments = [SELECT Id, ParentId, CommentBody, IsPublished 
                                      FROM CaseComment 
                                      WHERE ParentId = :testCase.Id];
        
        Assert.areEqual(1, comments.size(), 'One comment should be created');
        Assert.areEqual(testCase.Id, comments[0].ParentId, 'Comment should be linked to correct case');
        Assert.areEqual('This is a test comment', comments[0].CommentBody, 'Comment body should match input');
    }
    
        
    @isTest
    static void testGetSpeechLanguageWithValidCountryMapping() {
        User testUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        testUser.Country__c = 'United States';
        update testUser;
        
        CountryLanguageMapping__c languageMapping = new CountryLanguageMapping__c(
            Name = 'US',
            Language__c = 'en-US'
        );
        insert languageMapping;
        
        Case testCase = [SELECT Id FROM Case LIMIT 1];
        Test.setCurrentPageReference(new PageReference('Page.CaseCommentPage'));
        ApexPages.currentPage().getParameters().put('Id', testCase.Id);
        
        ApexPages.StandardController stdController = new ApexPages.StandardController(testCase);
        
        Test.startTest();
        CaseCommentController controller = new CaseCommentController(stdController);
        Test.stopTest();
        
        Assert.areEqual('en-US', controller.speechLanguage, 'Should return mapped language for country');
    }
    
    @isTest
    static void testGetSpeechLanguageWithBlankCountry() {
        User testUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        testUser.Country__c = null;
        update testUser;
        
        Case testCase = [SELECT Id FROM Case LIMIT 1];
        Test.setCurrentPageReference(new PageReference('Page.CaseCommentPage'));
        ApexPages.currentPage().getParameters().put('Id', testCase.Id);
        
        ApexPages.StandardController stdController = new ApexPages.StandardController(testCase);
        
        Test.startTest();
        CaseCommentController controller = new CaseCommentController(stdController);
        Test.stopTest();
        
        Assert.areEqual('en-US', controller.speechLanguage, 'Should return default en-US for blank country');
    }
    
    @isTest
    static void testGetSpeechLanguageWithCountryButNoMapping() {
        User testUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        testUser.Country__c = 'Japan';
        update testUser;
        
        Case testCase = [SELECT Id FROM Case LIMIT 1];
        Test.setCurrentPageReference(new PageReference('Page.CaseCommentPage'));
        ApexPages.currentPage().getParameters().put('Id', testCase.Id);
        
        ApexPages.StandardController stdController = new ApexPages.StandardController(testCase);
        
        Test.startTest();
        CaseCommentController controller = new CaseCommentController(stdController);
        Test.stopTest();
        
        Assert.areEqual('en-US', controller.speechLanguage, 'Should return default en-US when no mapping found');
    }
}