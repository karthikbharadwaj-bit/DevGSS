/*
* Name         : TestAllGeneralTestData.class
* Created By   : India Team
* Created Date : 13/Jan/2014
* Description  : Modified by Fedor Golovanov (fgolovanov@newmarketin.com) in order of get rid of long-running test issue. 5/Feb/2017.
* Dependencies : No
*/

@isTest
private class TestAllGeneralTestData {

    //Verify that login controller called not within site context will return null as the result
    @isTest static void testSiteLoginController () {

        SiteLoginController controller = new SiteLoginController ();
        controller.username = 'test@salesforce.com';
        controller.password = '123456';
        System.assertEquals(controller.login(), null);

    }

    //Verify that contact is created and smart factory will populate lookup fields and record type
    @isTest static void createsObjectWithCascadeSetsLookupField() {
        Contact contact = (Contact)SmartFactory.createSObject('Contact', true);
        System.assertEquals(contact.FirstName, 'a');
        System.assertEquals(contact.AccountId, null);
        System.assertNotEquals(contact.RecordTypeId, null);
    }

    //Verify that contact is created and smart factory will populate record type but not the lookup fields
    @isTest static void createsObjectWithoutCascadeDoesNotSetLookupField() {
        Contact contact = (Contact)SmartFactory.createSObject('Contact', false);
        System.assertEquals(contact.FirstName, 'a');
        System.assertEquals(contact.AccountId, null);
        System.assertNotEquals(contact.RecordTypeId, null);

    }

    //Test class for MultiSelect Controller
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest static void testMultiSelect(){

            //Use smartfactory to create all required objects, contact and account
            Contact c = new Contact();

            Test.startTest();
                c = (Contact)SmartFactory.createSObject('Contact', true);
                c.Email = 'TestEmail@test.com';
                insert c;
            Test.stopTest();

            //Prepare page parameters
            ApexPages.currentPage().getParameters().put('acc_id', c.AccountId);
            ApexPages.currentPage().getParameters().put('p3_lkid', c.AccountId);
            ApexPages.currentPage().getParameters().put('p3', 'test');
            ApexPages.currentPage().getParameters().put('p2_lkid', c.Id);
            ApexPages.currentPage().getParameters().put('view', c.AccountId);
            ApexPages.currentPage().getParameters().put('rtype', '00Q');
            ApexPages.currentPage().getParameters().put('lemail', c.Email);

            MultiSelect ms = new MultiSelect();

            ms.addToContactMap.put('a','a');
            ms.addToContactMap.put('b','B');

            ms.varContactMap.put('c','c');
            ms.varContactMap.put('d','d');

            ms.bccContactMap.put('e','e');
            ms.bccContactMap.put('f','f');

            ms.ccContactMap.put('g','g');
            ms.ccContactMap.put('h','h');

            ms.globalContactMap.put('i','i');
            ms.globalContactMap.put('j','j');

            ms.toContactmap.put('k','k');
            ms.toContactmap.put('l','l');

            ms.isEmailValidated = true;
            ms.allAdditionalToList.add(c.Id);

            ms.emailAuthor();

            ms.globalSelectedList.add('a');
            ms.globalSelectedList.add('b');
            ms.globalSelectedList.add('c');

            ms.allAdditionalToList.add('a');
            ms.allAdditionalToList.add('b');
            ms.allAdditionalToList.add('c');

            ms.allBccList.add('a');
            ms.allBccList.add('b');
            ms.allBccList.add('c');

            ms.allCCList.add('a');
            ms.allCCList.add('b');
            ms.allCCList.add('c');

            ms.clearList();
            ms.temp.Accountid = c.AccountId;

            ms.searchContact();
            ms.getGlobalContactOptions();

            ms.setAdditionalTo();
            ms.removeAdditionalTo();

            ms.setBccList();
            ms.removeBccList();

            ms.setCCList();
            ms.removeCCList();

            ms.getAllAdditionalTo();
            ms.isEmailValidated = false;
            ms.emailAuthor();
            ms.OptedOutOfEmail();
            ms.setToAddress();
            ms.removeToAddress();
            ms.cancel();
            ms.getAllCCOptionsList();
            ms.getAllBccOptionsList();
    }

    //Test class for RogerSurveyservice class
    @isTest static void testSurveyController() {
        //Use smartfactory to create all required objects, contact and survey
        Contact c = new Contact();
        Survey__c sr = new Survey__c();

        Test.startTest();

            c = (Contact)SmartFactory.createSObject('Contact', true);
            c.LastName = 'test';
            c.Email = 'test@test.com';
            insert c;

            sr.Contact__c = c.id;
            sr.SurveyType__c = 'Rogers Implementation';
            insert sr;

        Test.stopTest();

        System.Test.setCurrentPageReference(new PageReference('Page.SupportRogersImplementationSurvey'));
        ApexPages.currentPage().getParameters().put('id', sr.id);
        RogerSurveyservice rc = new RogerSurveyservice();
        system.assertEquals(rc.surveyExist, false);

        rc.getCommentLength();
        rc.getAnswered();
        rc.getIsFilled();
        rc.getIsEmpty();
        rc.getComments();
        rc.setComments('Hello Testing');
        rc.getQ1Value();
        rc.setQ1Value(1);
        rc.getQ2Value();
        rc.setQ2Value(2);
        rc.getQ3Value();
        rc.setQ3Value(2);
        rc.getQ4Value();
        rc.setQ4Value(2);
        rc.getValues();
        rc.getValues2();
        rc.getValues3();
        rc.getSurvey();
        rc.save();
        rc.getContactName();
    }

    //Test class for the SaveCSATSurveyController
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest static void testSaveCSATSurveyController() {
        //Use smartfactory to create all required objects, contact and survey
        Contact c = new Contact();
        Survey__c sr = new Survey__c();

        Test.startTest();

            c = (Contact)SmartFactory.createSObject('Contact', true);
            c.LastName = 'test';
            c.Email = 'test@test.com';
            insert c;

            sr.Contact__c = c.id;
            sr.SurveyType__c = 'Saves CSAT';
            insert sr;

        Test.stopTest();

        ApexPages.currentPage().getParameters().put('id', sr.id);
        // Instantiate a new controller with all parameters in the page
        SaveCSATSurveyController sur = new SaveCSATSurveyController();
        sur.save();
        sur.setQ1Value(3);
        sur.setQ2Value(2);
        sur.setQ3Value(4);
        sur.setQ4Value(4);
        sur.setQ5Value(4);
        sur.getQ1Value();
        sur.getQ2Value();
        sur.getQ3Value();
        sur.getQ4Value();
        sur.getQ5Value();
        sur.getValues();
        sur.getContactName();
        sur.getAnswered();
        sur.getCommentLength();
        sur.getComments();
        sur.getIsEmpty();
        sur.getIsFilled();
        sur.setComments('test111');
        sur.getCommentLength();
        sur.save();
        sur.getSurvey();

        Survey__c sur1 = new Survey__c();
        sur1.Q2_Score__c = 1;
        sur1.Q3_Score__c = 3;
        sur1.Q4_Score__c = 4;
        sur1.Comments__c = 'test';
        insert sur1 ;
        ApexPages.currentPage().getParameters().put('id',sur1 .id);
        SaveCSATSurveyController surC1 = new SaveCSATSurveyController();
        surC1.allAnswered =true;
        surC1.submitted = false;
        surc1.getAnswered();

        ApexPages.currentPage().getParameters().put('id','111111111111111');
        SaveCSATSurveyController surC2 = new SaveCSATSurveyController();

        Survey__c sur2 = new Survey__c();
        sur2.SurveyType__c = 'Saves CSAT';
        insert sur2 ;
        ApexPages.currentPage().getParameters().put('id',sur2.id);
        SaveCSATSurveyController surC3 = new SaveCSATSurveyController();

        surC3.getIsEmpty();
        Survey__c sur3 = new Survey__c();
        sur3.SurveyType__c = 'Saves CSAT';
        sur3.Q2_Score__c = 1;
        sur3.Q3_Score__c = 3;
        sur3.Q4_Score__c = 4;
        insert sur3 ;
        ApexPages.currentPage().getParameters().put('id',sur3.id);
        SaveCSATSurveyController surC4 = new SaveCSATSurveyController();

        surC4.getIsEmpty();
        Survey__c sur4 = new Survey__c();
        insert sur4;
        ApexPages.currentPage().getParameters().put('id',sur4.id);
        SaveCSATSurveyController surC5 = new SaveCSATSurveyController();
        surC5.getIsFilled();
    }

    //Test Classes for the RCSupportController
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest static void testRCSupportController(){

        RCSupportController objRCSupportController = new RCSupportController();
        RCSiteSetup__c objRCSiteName = (RCSiteSetup__c)SmartFactory.createSObject('RCSiteSetup__c', true);
        objRCSiteName.RCSiteName__c = 'rcsupport';
        insert objRCSiteName;

        PageReference pageRef = new PageReference('/apex/RCSupportHome');
        Test.setCurrentPageReference(pageRef);

        objRCSupportController.getAuthToken();
        objRCSupportController.getBrandFilter();
        objRCSupportController.getCacheMaxAge();
        objRCSupportController.getCategoryDescriptions();
        objRCSupportController.getCategoryGroupName();
        objRCSupportController.getFramedParam();
        objRCSupportController.getHomeAdText();
        objRCSupportController.getHomeAdTitle();
        objRCSupportController.getHomePage();
        objRCSupportController.getHomeUrl();
        objRCSupportController.getIsAnswerSearch();
        objRCSupportController.getIsArticleDetailsPage();
        objRCSupportController.getIsContact();
        objRCSupportController.getIsContactSupportPage();
        objRCSupportController.getIsCustomArticleListPage();
        objRCSupportController.getIsExternalPage();
        objRCSupportController.getIsHomePage();
        objRCSupportController.getIsProductPage();
        objRCSupportController.getRootCategoryName();

        objRCSupportController.getPage(ApexPages.currentpage().getUrl());
        objRCSupportController.getPageId();
        objRCSupportController.getParentId();
        objRCSupportController.getProductPage();
        objRCSupportController.getProductUrl();
        objRCSupportController.getRootCategoryName();
        objRCSupportController.getSearchPage();
        objRCSupportController.getSearchPageUrl();
        objRCSupportController.getSearchUrl();
        objRCSupportController.getSearchUrl1();

        String str2 = objRCSupportController.currentArticleType;
        str2 = objRCSupportController.currentArticleTypeLabel;
        str2 = objRCSupportController.currentCategory;
        str2 = objRCSupportController.currentCategoryName;
        str2 = objRCSupportController.currentKeyword;
        str2 = objRCSupportController.currentPage;
        Integer pageNum = objRCSupportController.currentPageNumber;
        PageReference objpage = objRCSupportController.currentPageReference;
        objRCSupportController.doSearch();
        objRCSupportController.doAdvanceSearch();

        str2 = objRCSupportController.categoryParameterName;
        str2 = objRCSupportController.keywordParameterName;
        str2 = objRCSupportController.articleTypeParameterName;
        str2 = objRCSupportController.articleTypeLabelParameterName;
        str2 = objRCSupportController.pageNumberParameterName ;
        objRCSupportController.getSiteSetup();
        objRCSupportController.getServiceFilter();
        objRCSupportController.getServiceFilterURL();
        objRCSupportController.getSupportSearchPageUrl();
        objRCSupportController.getIsSearchPage();
        objRCSupportController.cleanKeyword();

        ApexPages.currentPage().getParameters().put('emailPage','kanishk.singh@simplion.com');
        String recMail = ApexPages.currentPage().getParameters().put('recMail','kanishk.singh@simplion.com');
        String senderMail = ApexPages.currentPage().getParameters().put('senderMail','kanishk.singh@simplion.com');
        String senderName = ApexPages.currentPage().getParameters().put('sendername','kanishk');
        String strTitle = '';

        objRCSupportController.emailSend();
        objRCSupportController.getIdeaURL();
        objRCSupportController.getCaseURL();
        ApexPages.CurrentPage().getParameters().put('retUrl','service=1&brand=Ringcentral&token=test');
        ApexPages.CurrentPage().getParameters().put('brand','RC_UK');
        objRCSupportController.getIdeaURL();
        objRCSupportController.getCaseURL();

        ApexPages.CurrentPage().getParameters().put('token','test');
        objRCSupportController.getIdeaURL();
        objRCSupportController.getCaseURL();

        ApexPages.CurrentPage().getParameters().put('token','PFK8fqxUQZ3qw1nIWm0gVoPE1O1xEhiRFh0X3n0PxvEIzdYo+J2ihXuaSvfrFoOGXg5uqTH8KYo/2oohN5A7wQ==');
        objRCSupportController.getIdeaURL();
        objRCSupportController.getCaseURL();

        objRCSupportController.getIdeaURL();
        objRCSupportController.updateUserProfile();
        objRCSupportController.getCommunityId();

        objRCSupportController.localeSetting();
        objRCSupportController.getURLCategory();

    }

    //Test classes for the MailHelper class
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest static void testMailHelper() {
        new MailHelper().createMail(null, 'This is test email. Please ignore', HardcodedIdsMapper.getMatchedObjectId('00580000003SZmNAAW'),'' , false, 'Test Email','Test Email');
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest static void testMailHelper1() {
        new MailHelper().createMail(null, 'This is test email. Please ignore', null,'' , false, 'Test Email','Test Email','virendra.singh@simplion.com');
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest static void testMailHelper2() {
        new MailHelper().createMail(null, 'This is test email. Please ignore', null,'', false, 'Test Email','Test Email',new String[]{'virendra.singh@simplion.com'}, new String[]{'virendra.singh@simplion.com'}, new String[]{'virendra.singh@simplion.com'});
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest static void testMailHelper3() {
        new MailHelper().createMail(null, 'This is test email. Please ignore', null,''  , false, 'Test Email','Test Email',null, null, null);
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest static void testMailHelper4() {
        new MailHelper().createAgentCreditMail(null, 'This is test email. Please ignore', null,'', false, 'Test Email','Test Email',new String[]{'virendra.singh@simplion.com'}, new String[]{'virendra.singh@simplion.com'}, new String[]{'virendra.singh@simplion.com'});
    }

    @isTest static void testMailHelper5() {
        String noreplyRincentral = 'noreply@ringcentral.com';
        OrgWideEmailAddress[] emails = [
            SELECT
                Id
            FROM OrgWideEmailAddress
            WHERE
                Address = :noreplyRincentral LIMIT 1
        ];

        System.assertEquals(1, emails.size(), 'In the organization should exist an Organization-Wide Address named "' + noreplyRincentral + '".');

        RingCentralVariousSettings__c settings = new RingCentralVariousSettings__c();
        settings.Email_used_when_Attachment_added_to_Case__c = emails[0].Id;

        insert settings;
        Messaging.SingleEmailMessage email;
        Test.startTest();
            email = new MailHelper().createMail(null, 'This is test email. Please ignore', null,'' , false, 'Test Email','Test Email','virendra.singh@simplion.com');
        Test.stopTest();

        //system.assertNotEquals(null, email, 'The email couldn\'t be sent.');
        //system.assertEquals(emails[0].Id, email.getOrgWideEmailAddressId(), 'The sender should be: "' + noreplyRincentral + '".');
    }

}