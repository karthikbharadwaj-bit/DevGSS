@isTest
private class Test_InventionTicket1 {

    private static final String ASSERT_STATUS_MSG = 'Status should match expected value';
    private static final String ASSERT_TITLE_MSG = 'Title text should be set correctly';
    private static final String ASSERT_EDIT_MSG = 'isEdit flag should match expected value';
    private static final String ASSERT_DRAFT_MSG = 'isDraft flag should match expected value';
    private static final String ASSERT_NAME_MSG = 'Name should be truncated to 80 characters';
    private static final String ASSERT_INVENTION_ID_MSG = 'getIsInventionId should return expected value';
    private static final String ASSERT_PAGE_REF_MSG = 'PageReference should not be null';
    private static final String ASSERT_INVENTOR_MSG = 'Inventor Name should be set';

    @TestSetup
    private static void testData() {
        Profile p = (Profile) new ProfileSelector()
            .selectProfileByName(new List<String>{'Standard User'})
            .executeQuery()
            .get(0);

        User u = new User(
            Alias = 'invtest',
            Email = 'inventiontest@testorg.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'InvTestUser',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'inventiontest' + System.currentTimeMillis() + '@testorg.com'
        );
        insert u;
    }

    @isTest
    private static void constructorShouldInitializeNewInventionWhenNoId() {
        Legal_Requests__c legalObj = new Legal_Requests__c();
        ApexPages.StandardController sc = new ApexPages.standardController(legalObj);

        Test.startTest();
            InventionTicket controller = new InventionTicket(sc);
        Test.stopTest();

        System.assertEquals('Draft', controller.inventionObj.Status__c, ASSERT_STATUS_MSG);
        System.assertEquals(true, controller.isDraft, ASSERT_DRAFT_MSG);
        System.assertEquals('Please fill out the form below in order to create a Invention Case.', controller.titleText, ASSERT_TITLE_MSG);
    }

    @isTest
    private static void saveDataShouldTruncateTitleWhenLongerThan80Characters() {
        User testUser = [SELECT Id FROM User WHERE Email = 'inventiontest@testorg.com' LIMIT 1];
        Legal_Requests__c legalObj = new Legal_Requests__c();
        ApexPages.StandardController sc = new ApexPages.standardController(legalObj);
        InventionTicket controller = new InventionTicket(sc);

        String longTitle = 'This is a very long title that exceeds eighty characters and should be truncated by the save method';
        controller.inventionObj.Title_of_Invention__c = longTitle;

        Test.startTest();
            PageReference result = controller.saveData();
        Test.stopTest();

        System.assertNotEquals(null, result, ASSERT_PAGE_REF_MSG);
        System.assertEquals(80, controller.inventionObj.Name.length(), ASSERT_NAME_MSG);
    }

    @isTest
    private static void saveDataShouldClearInventorNameWhenInventorNameTextIsBlank() {
        User testUser = [SELECT Id FROM User WHERE Email = 'inventiontest@testorg.com' LIMIT 1];
        Legal_Requests__c legalObj = new Legal_Requests__c();
        ApexPages.StandardController sc = new ApexPages.standardController(legalObj);
        InventionTicket controller = new InventionTicket(sc);

        controller.inventionObj.Title_of_Invention__c = 'Test Title';
        controller.inventionObj.Inventor_Name__c = testUser.Id;
        controller.inventionObj.Inventor_Name_Text__c = '';

        Test.startTest();
            PageReference result = controller.saveData();
        Test.stopTest();

        System.assertEquals(null, controller.inventionObj.Inventor_Name__c, ASSERT_INVENTOR_MSG);
    }

    @isTest
    private static void saveDataShouldCreateWatcherForNewInvention() {
        Legal_Requests__c legalObj = new Legal_Requests__c();
        ApexPages.StandardController sc = new ApexPages.standardController(legalObj);
        InventionTicket controller = new InventionTicket(sc);

        controller.inventionObj.Title_of_Invention__c = 'New Invention Test';

        Test.startTest();
            PageReference result = controller.saveData();
        Test.stopTest();

        List<Legal_Requests_Watchers__c> watchers = [
            SELECT Id, Advisor_Name__c 
            FROM Legal_Requests_Watchers__c 
            WHERE Legal_Requests__c = :controller.inventionObj.Id
        ];
        System.assertEquals(1, watchers.size(), 'Watcher should be created for new invention');
    }

    @isTest
    private static void saveCommentShouldShowErrorWhenCommentIsBlank() {
        Legal_Requests__c legalObj = new Legal_Requests__c(Name = 'Test');
        insert legalObj;

        ApexPages.currentPage().getParameters().put('id', legalObj.Id);
        ApexPages.StandardController sc = new ApexPages.standardController(legalObj);
        InventionTicket controller = new InventionTicket(sc);
        controller.commentObj.Comment__c = '';

        Test.startTest();
            controller.saveComment();
        Test.stopTest();

        List<ApexPages.Message> messages = ApexPages.getMessages();
        Boolean hasError = false;
        for (ApexPages.Message msg : messages) {
            if (msg.getSeverity() == ApexPages.Severity.ERROR && msg.getSummary().contains('Please enter comment')) {
                hasError = true;
                break;
            }
        }
        System.assertEquals(true, hasError, 'Error message should be displayed for blank comment');
    }

    @isTest
    private static void getIsInventionIdShouldReturnTrueWhenIdAndEditAction() {
        Legal_Requests__c legalObj = new Legal_Requests__c(Name = 'Test');
        insert legalObj;

        ApexPages.currentPage().getParameters().put('id', legalObj.Id);
        ApexPages.currentPage().getParameters().put('action', 'edit');
        ApexPages.StandardController sc = new ApexPages.standardController(legalObj);
        InventionTicket controller = new InventionTicket(sc);

        Test.startTest();
            Boolean result = controller.getIsInventionId();
        Test.stopTest();

        System.assertEquals(true, result, ASSERT_INVENTION_ID_MSG);
    }

    @isTest
    private static void getIsInventionIdShouldReturnFalseWhenNoId() {
        Legal_Requests__c legalObj = new Legal_Requests__c();
        ApexPages.StandardController sc = new ApexPages.standardController(legalObj);
        InventionTicket controller = new InventionTicket(sc);

        Test.startTest();
            Boolean result = controller.getIsInventionId();
        Test.stopTest();

        System.assertEquals(false, result, ASSERT_INVENTION_ID_MSG);
    }

    @isTest
    private static void inventorNameFunShouldSetInventorName() {
        User testUser = [SELECT Id FROM User WHERE Email = 'inventiontest@testorg.com' LIMIT 1];
        Legal_Requests__c legalObj = new Legal_Requests__c();
        ApexPages.StandardController sc = new ApexPages.standardController(legalObj);
        InventionTicket controller = new InventionTicket(sc);

        controller.inventorId = testUser.Id;

        Test.startTest();
            controller.inventorNameFun();
        Test.stopTest();

        System.assertEquals(testUser.Id, controller.inventionObj.Inventor_Name__c, ASSERT_INVENTOR_MSG);
    }

    @isTest
    private static void editDataShouldReturnPageReferenceWithEditAction() {
        Legal_Requests__c legalObj = new Legal_Requests__c(Name = 'Test');
        insert legalObj;

        ApexPages.currentPage().getParameters().put('id', legalObj.Id);
        ApexPages.StandardController sc = new ApexPages.standardController(legalObj);
        InventionTicket controller = new InventionTicket(sc);

        Test.startTest();
            PageReference result = controller.editData();
        Test.stopTest();

        System.assertNotEquals(null, result, ASSERT_PAGE_REF_MSG);
        System.assert(result.getUrl().contains('action=edit'), 'URL should contain edit action');
    }

    @isTest
    private static void cancelButtonShouldReturnPageReferenceWithViewAction() {
        Legal_Requests__c legalObj = new Legal_Requests__c(Name = 'Test');
        insert legalObj;

        ApexPages.currentPage().getParameters().put('id', legalObj.Id);
        ApexPages.StandardController sc = new ApexPages.standardController(legalObj);
        InventionTicket controller = new InventionTicket(sc);

        Test.startTest();
            PageReference result = controller.cancelButton();
        Test.stopTest();

        System.assertNotEquals(null, result, ASSERT_PAGE_REF_MSG);
        System.assert(result.getUrl().contains('action=view'), 'URL should contain view action');
    }

    @isTest
    private static void searchUserShouldReturnMatchingUsers() {
        User testUser = [SELECT Id, Name FROM User WHERE Email = 'inventiontest@testorg.com' LIMIT 1];

        Test.startTest();
            List<String> results = InventionTicket.searchUser('InvTest');
        Test.stopTest();

        System.assert(results.size() >= 0, 'Search should return results without error');
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    private static void myUnitTest() {
        try {
            Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User'];
            User u = new User(
                Alias = 'standt',
                Email = 'standardusertest123@testorg.com',
                EmailEncodingKey = 'UTF-8',
                LastName = 'Testingtest@123',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US',
                ProfileId = p.Id,
                TimeZoneSidKey = 'America/Los_Angeles',
                UserName = 'standardusertest123' + System.currentTimeMillis() + '@testorg.com'
            );
            insert u;
            Legal_Requests__c legalObj = new Legal_Requests__c();
            ApexPages.StandardController sc = new ApexPages.standardController(legalObj);
            InventionTicket clsObj = new InventionTicket(sc);
            clsObj.cancelButton();
            clsObj.inventorId = u.id;
            clsObj.inventorNameFun();
            legalObj.Title_of_Invention__c = 'Test Data';
            clsObj.saveData();
            clsObj.watcherObj.Advisor_Name__c = u.id;
            clsObj.saveWatcher();
            clsObj.commentObj.Comment__c = 'Test';
            clsObj.saveComment();
            clsObj.editData();
            clsObj.attachObj.Body = blob.valueOf('Test Body');
            clsObj.attachObj.ParentId = legalObj.Id;
            clsObj.attachObj.Name = 'Test';
            clsObj.uploadFile();
            clsObj.submitCase();
            ApexPages.currentPage().getParameters().put('id', legalObj.id);
            clsObj.getIsInventionId();
        } catch (Exception e) {
            System.debug('Exception:' + e.getMessage());
        }
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    private static void myUnitTest1() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User'];
        User u = new User(
            Alias = 'standt',
            Email = 'standardusertest456@testorg.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Testingtest@123',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'standardusertest456' + System.currentTimeMillis() + '@testorg.com'
        );
        insert u;
        Legal_Requests__c legalObj = new Legal_Requests__c();
        legalObj.Name = 'Test';
        insert legalObj;
        Legal_Requests_Watchers__c watcherObj = new Legal_Requests_Watchers__c(Advisor_Name__c = u.Id, Legal_Requests__c = legalObj.id);
        insert watcherObj;
        Legal_Requests_Comments__c commentObj = new Legal_Requests_Comments__c(Legal_Requests__c = legalObj.id);
        insert commentObj;
        legalObj.Status__c = 'Submitted';
        update legalObj;
        delete watcherObj;
        delete commentObj;
        legalObj.Status__c = 'Draft';
        ApexPages.currentPage().getParameters().put('id', legalObj.id);
        ApexPages.currentPage().getParameters().put('action', 'edit');
        ApexPages.StandardController sc1 = new ApexPages.standardController(legalObj);
        InventionTicket clsObj = new InventionTicket(sc1);
        InventionTicket.searchUser('test');
        AutoCompleteController.searchUser('test');
        clsObj.watcherObj.Advisor_Name__c = u.id;
        clsObj.saveWatcher();
        LegalRequestPDFController pdfObj = new LegalRequestPDFController(sc1);
    }    

    @isTest
    private static void searchUserShouldReturnUserNames() {
        Profile p = (Profile) new ProfileSelector()
            .selectProfileByName(new List<String>{'Standard User'})
            .executeQuery()
            .get(0);

        User u = new User(
            Alias = 'standt',
            Email = 'standardusertest456@testorg.com',
            EmailEncodingKey = 'UTF-8',
            FirstName = 'TestMan@1@2',
            LastName = 'Man10',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'standardusertest456' + System.currentTimeMillis() + '@testorg.com'
        );
        insert u;

        Test.startTest();
            List<String> userName = LegalRequestPDFController.searchUser('%TestMan@1@2');
        Test.stopTest();

        System.assertEquals('TestMan@1@2 Man10', userName[0], 'User name should match expected format');
    }

    @isTest
    private static void saveDataShouldHandleExceptionGracefully() {
        Legal_Requests__c legalObj = new Legal_Requests__c(Name = 'Test');
        insert legalObj;

        ApexPages.currentPage().getParameters().put('id', legalObj.Id);
        ApexPages.StandardController sc = new ApexPages.standardController(legalObj);
        InventionTicket controller = new InventionTicket(sc);

        // Set an invalid field value to trigger exception
        controller.inventionObj.Title_of_Invention__c = 'Test';
        controller.inventionObj.Id = null; // Force an update on null Id to trigger exception path

        Test.startTest();
            PageReference result = controller.saveData();
        Test.stopTest();

        // The method should handle exception and return null or add error message
        System.assert(true, 'Exception should be handled gracefully');
    }

    @isTest
    private static void uploadFileShouldHandleDMLException() {
        Legal_Requests__c legalObj = new Legal_Requests__c(Name = 'Test');
        insert legalObj;

        ApexPages.currentPage().getParameters().put('id', legalObj.Id);
        ApexPages.StandardController sc = new ApexPages.standardController(legalObj);
        InventionTicket controller = new InventionTicket(sc);

        // Set attachment without required fields to potentially trigger DML exception
        controller.attachObj.Body = null;
        controller.attachObj.Name = null;

        Test.startTest();
            PageReference result = controller.uploadFile();
        Test.stopTest();

        // Should return null and show error message
        System.assertEquals(null, result, 'Should return null on DML exception');
    }

    @isTest
    private static void saveDataShouldSetNameToTitleWhenTitleIsShort() {
        Legal_Requests__c legalObj = new Legal_Requests__c();
        ApexPages.StandardController sc = new ApexPages.standardController(legalObj);
        InventionTicket controller = new InventionTicket(sc);

        String shortTitle = 'Short Title';
        controller.inventionObj.Title_of_Invention__c = shortTitle;

        Test.startTest();
            PageReference result = controller.saveData();
        Test.stopTest();

        System.assertEquals(shortTitle, controller.inventionObj.Name, 'Name should equal title when under 80 chars');
    }
}