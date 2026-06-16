@isTest
private with sharing class Test_SupportCommunityNewCase {

    private static final String ARTICLE_TITLE_1 = 'First Article';
    private static final String ARTICLE_TITLE_2 = 'Second Article';
    private static final String ARTICLE_TITLE_3 = 'Third Article';
    private static final String ARTICLE_TITLE_4 = 'DataCategoryUnset';

    private static final String ARTICLE_URLNAME_1 = 'testUrl-One';
    private static final String ARTICLE_URLNAME_2 = 'testUrl-Two';
    private static final String ARTICLE_URLNAME_4 = 'testUrl-Four';
    private static final String PUBLISHEDEXTERNALLY = 'PublishedExternally';

    private static final String MAIN_LANGUAGE = 'en_US';
    private static final String SECONDARY_LANGUAGE = 'es';

    private static final String CASE_INFO_SUBJECT = 'test Subject';
    private static final String CASE_INFO_DESCRIPTION = 'test Description';
    private static final String CASE_INFO_SELECTED_PRODUCT = 'test product one';
    private static final String CASE_INFO_SELECTED_PRODUCT2 = 'test product two';
    private static final String CASE_INFO_SELECTED_PRODUCT3 = 'test product three';
    private static final String CASE_INFO_SEVERITY_LEVEL = 'Level 4 - Medium';
    private static final String CASE_INFO_ALTERNATE_EMAIL = 'test@alternate.re';
    private static final String CASE_INFO_CALLBACK_PHONE = '9999999999 ext.999';

    private static final String USER_USERNAME = 'RC_SupportCommunityNewCaseTestUser@nvx.zn';
    private static final String USER_EMAIL = 'testerino@rc.com';
    private static final String USER_FIRST_NAME = 'Toaster';
    private static final String USER_LAST_NAME = 'McToast';
    private static final String USER_LANGUAGE = 'en_US';

    private static final String CONTACT_FIRST_NAME = USER_FIRST_NAME;
    private static final String CONTACT_LAST_NAME = USER_LAST_NAME;
    private static final String CONTACT_EMAIL = USER_EMAIL;
    private static final String CONTACT_PHONE = '77777777';
    private static final Decimal CONTACT_PHONE_EXT = 777;

    private static final String CONTACT_FIRST_NAME_NEW = 'Toaster 2';
    private static final String CONTACT_LAST_NAME_NEW = 'McToast 2';
    private static final String CONTACT_EMAIL_NEW = 'new@ema.il';

    private static final String GUEST_USER_PROFILE_NAME = 'RC Guest User';

    private static final String ARTICLE_NAME = 'TestArticle';

    private static SCWrappers.CaseInfo getRequestCaseInfo() {

        Case caseObj = new Case();
        SCWrappers.CaseInfo requestCaseInfo = new SCWrappers.CaseInfo(caseObj);
        requestCaseInfo.subject = CASE_INFO_SUBJECT;
        requestCaseInfo.description = CASE_INFO_DESCRIPTION;
        requestCaseInfo.selectedProduct = CASE_INFO_SELECTED_PRODUCT;
        requestCaseInfo.selectedProduct2 = CASE_INFO_SELECTED_PRODUCT2;
        requestCaseInfo.selectedProduct3 = CASE_INFO_SELECTED_PRODUCT3;
        requestCaseInfo.severityLevel = CASE_INFO_SEVERITY_LEVEL;
        requestCaseInfo.alternateEmail = CASE_INFO_ALTERNATE_EMAIL;
        requestCaseInfo.callbackPhone = CASE_INFO_CALLBACK_PHONE;
        return requestCaseInfo;
    }

    private static SCWrappers.GdprInfo getRequestGdprInfo() {
        
        Case caseObj = new Case();
        SCWrappers.GdprInfo requestGdprInfo = new SCWrappers.GdprInfo(caseObj);
        requestGdprInfo.subject = CASE_INFO_SUBJECT;
        requestGdprInfo.description = CASE_INFO_DESCRIPTION;
        requestGdprInfo.selectedProduct = CASE_INFO_SELECTED_PRODUCT;
        requestGdprInfo.selectedProduct2 = CASE_INFO_SELECTED_PRODUCT2;
        requestGdprInfo.selectedProduct3 = CASE_INFO_SELECTED_PRODUCT3;
        requestGdprInfo.severityLevel = CASE_INFO_SEVERITY_LEVEL;
        requestGdprInfo.alternateEmail = CASE_INFO_ALTERNATE_EMAIL;
        requestGdprInfo.callbackPhone = CASE_INFO_CALLBACK_PHONE;
        requestGdprInfo.deleteRequest = true;
        requestGdprInfo.retainAnalytics = true;
        requestGdprInfo.retainGlip = true;
        requestGdprInfo.comments = '123';
        return requestGdprInfo;
    }

    private static User getTestUser() {
        return (User) new UserSelector()
            .selectUserByUsername(new List<Object>{new List<String>{USER_USERNAME}})
            .selectFields(new List<String>{'ContactId'})
            .executeQuery()
            .get(0);
    }

    private static List<Knowledge__kav> createArticles() {

        List<Knowledge__kav> articleList;

        PermissionSet adminPermSet = (PermissionSet) new PermissionSetSelector()
            .selectPermissionSetsByName(new List<Object>{new List<String>{'RC_Admin_User'}})
            .executeQuery()
            .get(0);
        new SObjectBuilder(PermissionSetAssignment.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    PermissionSetAssignment.AssigneeId => KCSDataFactory.expert.Id,
                    PermissionSetAssignment.PermissionSetId => adminPermSet.Id
                }
            )
            .create();

        System.runAs(KCSDataFactory.expert) {

            articleList = 
                (List<Knowledge__kav>) new SObjectBuilder(Knowledge__kav.SObjectType)
                    .setFields(
                        new Map<SObjectField, Object>{
                            Knowledge__kav.Title =>
                                ValueProviderBuilder.provideList(new List<String>{
                                    ARTICLE_TITLE_1, ARTICLE_TITLE_2, ARTICLE_TITLE_3, ARTICLE_TITLE_4 
                                }),
                            Knowledge__kav.ValidationStatus  =>
                                ValueProviderBuilder.provideList(new List<String>{
                                    PUBLISHEDEXTERNALLY, PUBLISHEDEXTERNALLY, PUBLISHEDEXTERNALLY, PUBLISHEDEXTERNALLY
                                }),
                            Knowledge__kav.UrlName =>
                                ValueProviderBuilder.provideList(new List<String>{
                                    ARTICLE_URLNAME_1, ARTICLE_URLNAME_2, ARTICLE_URLNAME_1, ARTICLE_URLNAME_4
                                }),
                            Knowledge__kav.Language =>
                                ValueProviderBuilder.provideList(new List<String>{
                                    MAIN_LANGUAGE, MAIN_LANGUAGE, SECONDARY_LANGUAGE, MAIN_LANGUAGE
                                }),
                            Knowledge__kav.IsVisibleInCsp => true
                        }
                    )
                    .quantity(4)
                    .create()
                    .getRecords();

            List<Knowledge__DataCategorySelection> categorySelectionList = 
                (List<Knowledge__DataCategorySelection>) new SObjectBuilder(Knowledge__DataCategorySelection.SObjectType)
                    .setFields(
                        new Map<SObjectField, Object>{
                            Knowledge__DataCategorySelection.DataCategoryGroupName => 'Brand',
                            Knowledge__DataCategorySelection.DataCategoryName => 'RC_US',
                            Knowledge__DataCategorySelection.ParentId =>
                                ValueProviderBuilder.provideList(new List<Id>{
                                    articleList[0].Id, articleList[1].Id, articleList[2].Id
                                })
                        }
                    )
                    .quantity(3)
                    .build()
                    .getRecords();

            categorySelectionList.addAll(
                (List<Knowledge__DataCategorySelection>) new SObjectBuilder(Knowledge__DataCategorySelection.SObjectType)
                    .setFields(
                        new Map<SObjectField, Object>{
                            Knowledge__DataCategorySelection.DataCategoryGroupName => 'RCProductVersion',
                            Knowledge__DataCategorySelection.DataCategoryName => 'RC2013',
                            Knowledge__DataCategorySelection.ParentId =>
                                ValueProviderBuilder.provideList(new List<Id>{
                                    articleList[0].Id, articleList[1].Id, articleList[2].Id
                                })
                        }
                    )
                    .quantity(3)
                    .build()
                    .getRecords()
            );
            insert categorySelectionList;

            Knowledge__kav article1 = (Knowledge__kav) new KnowledgeArticleSelector()
                .selectArticleById(new List<String>{articleList[0].Id})
                .executeQuery()
                .get(0);
            Knowledge__kav article3 = (Knowledge__kav) new KnowledgeArticleSelector()
                .selectArticleById(new List<String>{articleList[2].Id})
                .executeQuery()
                .get(0);

            KbManagement.PublishingService.publishArticle(article1.KnowledgeArticleId, true);
            KbManagement.PublishingService.publishArticle(article3.KnowledgeArticleId, true);
        }
        return articleList;
    }

    @testSetup
    static void setup() {
        
        KCSDataFactory.setup();
        Profile guestProfile = (Profile) new ProfileSelector()
            .selectProfileByName(new List<String>{GUEST_USER_PROFILE_NAME})
            .executeQuery()
            .get(0);

        Account portalAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(Account.SObjectType))
            .create()
            .getRecord();

        Contact portalContact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.FirstName => CONTACT_FIRST_NAME,
                    Contact.LastName => CONTACT_LAST_NAME,
                    Contact.Email => CONTACT_EMAIL,
                    Contact.Phone => CONTACT_PHONE,
                    Contact.Phone_Ext__c => CONTACT_PHONE_EXT,
                    Contact.AccountId => portalAccount.Id
                }
            )
            .create()
            .getRecord();

        new SObjectBuilder(User.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    User.ContactId => portalContact.Id,
                    User.LastName => USER_FIRST_NAME,
                    User.FirstName => USER_LAST_NAME,
                    User.CommunityNickname => USER_LAST_NAME,
                    User.Email => USER_EMAIL,
                    User.Username => USER_USERNAME,
                    User.LanguageLocaleKey => USER_LANGUAGE,
                    User.ProfileId => guestProfile.Id
                }
            )
            .create();

    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testGetAreaPicklistOptions() {

        Test.startTest();
        List<SCWrappers.AreaOption> result = 
            (List<SCWrappers.AreaOption>) SupportCommunityNewCase.getAreaPicklistOptions()
                .data.get(SupportCommunityNewCase.LABEL_AREA_OPTIONS);
        Test.stopTest();

        //System.assert(!result.isEmpty(), 'Picklist options not found');

        Map<String,List<String>> dependenciesLvl2 = SFDescribeHelper.getDependentOptions(
            SupportCommunityNewCase.CASE_APINAME,
            SupportCommunityNewCase.ASSISTANCE_FIELD_NAME_1,
            SupportCommunityNewCase.ASSISTANCE_FIELD_NAME_2
        );
        Map<String,List<String>> dependenciesLvl3 = SFDescribeHelper.getDependentOptions(
            SupportCommunityNewCase.CASE_APINAME,
            SupportCommunityNewCase.ASSISTANCE_FIELD_NAME_2,
            SupportCommunityNewCase.ASSISTANCE_FIELD_NAME_3
        );

        /*System.assertEquals(dependenciesLvl2.size(), result.size(), 'Picklist Lvl 1 size does not match');
        for (SCWrappers.AreaOption ao : result) {
            System.assert(dependenciesLvl2.containsKey(ao.label), 'Returned unexpected option');
            System.assertEquals(
                dependenciesLvl2.get(ao.label).size(),
                ao.subLevelOptions.size(),
                'Picklist Lvl 2 size does not match'
            );
            for (SCWrappers.AreaOption aoLvl2 : ao.subLevelOptions) {
                System.assert(dependenciesLvl3.containsKey(aoLvl2.label), 'Returned unexpected option');
                System.assertEquals(
                    dependenciesLvl3.get(aoLvl2.label).size(),
                    aoLvl2.subLevelOptions.size(),
                    'Picklist Lvl 3 size does not match'
                );
            }
        }*/
    }

    @isTest
    static void testGetContactInfo() {

        Test.startTest();
        SCWrappers.ContactInfo result;
        User u = getTestUser();
        System.runAs(u) {
            result = (SCWrappers.ContactInfo) (SupportCommunityNewCase.getContactInfo()
                .data.get(SupportCommunityNewCase.LABEL_CONTACT_INFO));
        }
        Test.stopTest();

        System.assert(result != null, 'Invalid response');
        System.assertEquals(u.ContactId, result.contactId, 'contactId does not match');
        System.assertEquals(CONTACT_FIRST_NAME, result.firstName, 'First Name does not match');
        System.assertEquals(CONTACT_LAST_NAME, result.lastName, 'Last Name does not match');
        System.assertEquals(CONTACT_EMAIL, result.email, 'Email does not match');
        System.assertEquals(CONTACT_PHONE, result.phone, 'Phone does not match');
        System.assertEquals(String.valueOf(CONTACT_PHONE_EXT), result.extension, 'Extension does not match');
    }

    @isTest
    static void testGetContactId() {

        String result;
        User u = getTestUser();
        System.runAs(u) {
            SCWrappers.ContactInfo request = new SCWrappers.ContactInfo(
                (User) new UserSelector()
                    .selectUserByIdForNewCase(new List<String>{UserInfo.getUserId()})
                    .executeQuery()
                    .get(0)
            );
            request.email = CONTACT_EMAIL_NEW;
            request.firstName = CONTACT_FIRST_NAME_NEW;
            request.lastName = CONTACT_LAST_NAME_NEW;
            Test.startTest();
            result = String.valueOf(SupportCommunityNewCase.getContactId(JSON.serialize(request))
                .data.get(SupportCommunityNewCase.LABEL_CONTACT_ID));
            Test.stopTest();
        }
        // System.assert(result != null, 'Invalid response');
        System.assertNotEquals(u.ContactId, result, 'new contact was not created');
    }

    @isTest
    static void testSearchArticles() {

        List<Knowledge__kav> articles = createArticles();
        SCWrappers.ArticleSearchRequest request = new SCWrappers.ArticleSearchRequest();
        request.titlePart = 'Article';
        request.langCode = MAIN_LANGUAGE;
        Test.startTest();
        List<SCWrappers.Article> result = 
            (List<SCWrappers.Article>) (SupportCommunityNewCase.searchArticles(JSON.serialize(request))
                .data.get(SupportCommunityNewCase.LABEL_ARTICLES));
        Test.stopTest();

        System.assert(!result.isEmpty(), 'Article not found');
        //Found one article, because 2nd is unpublished and 3rd is in another language
        System.assertEquals(1, result.size(), 'Found too much articles');
        System.assert(result[0].url.contains('testUrl'), 'UrlName does not match');
    }

    @isTest
    static void testSearchArticles_neg() {

        createArticles();
        SCWrappers.ArticleSearchRequest request = new SCWrappers.ArticleSearchRequest();
        Test.startTest();
        List<SCWrappers.Article> result = 
            (List<SCWrappers.Article>) (SupportCommunityNewCase.searchArticles(JSON.serialize(request))
                .data.get(SupportCommunityNewCase.LABEL_ARTICLES));
        Test.stopTest();

        System.assert(result == null, 'Invalid request returned a valid response');
    }

    @isTest
    static void testSearchArticles_neg_noArticles() {

        createArticles();
        SCWrappers.ArticleSearchRequest request = new SCWrappers.ArticleSearchRequest();
        request.titlePart = 'Article';
        request.langCode = SECONDARY_LANGUAGE;
        Test.startTest();
        List<SCWrappers.Article> result = 
            (List<SCWrappers.Article>) (SupportCommunityNewCase.searchArticles(JSON.serialize(request))
                .data.get(SupportCommunityNewCase.LABEL_ARTICLES));
        Test.stopTest();

        System.assert(result.isEmpty(), 'Articles found with incorrect language');
    }

    @isTest
    static void testSearchArticles_neg_dataCategoryUnset() {

        createArticles();
        SCWrappers.ArticleSearchRequest request = new SCWrappers.ArticleSearchRequest();
        request.titlePart = ARTICLE_TITLE_4;
        request.langCode = MAIN_LANGUAGE;
        Test.startTest();
        List<SCWrappers.Article> result = 
            (List<SCWrappers.Article>) (SupportCommunityNewCase.searchArticles(JSON.serialize(request))
                .data.get(SupportCommunityNewCase.LABEL_ARTICLES));
        Test.stopTest();

        System.assert(result.isEmpty(), 'Articles found without categories');
    }

    @isTest
    static void testCreateCase() {

        String caseId;
        SCWrappers.ContactInfo requestContactInfo;

        Test.startTest();
        System.runAs(getTestUser()) {

            requestContactInfo = new SCWrappers.ContactInfo(
                (User) new UserSelector()
                    .selectUserByIdForNewCase(new List<String>{UserInfo.getUserId()})
                    .executeQuery()
                    .get(0)
            );
            requestContactInfo.extension = '111';
            
            SCWrappers.CreateCaseRequest createCaseRequest = new SCWrappers.CreateCaseRequest();
            createCaseRequest.caseInfo = JSON.serialize(getRequestCaseInfo());
            createCaseRequest.contactId = requestContactInfo.contactId;
            createCaseRequest.isGdpr = false;

            caseId = (String) SupportCommunityNewCase.createCase(JSON.serialize(createCaseRequest))
                .data.get(SupportCommunityNewCase.LABEL_CREATED_CASE_ID);

        }
        Test.stopTest();

        Case newCase = (Case) new CaseSelector()
            .selectCasesForApproval(new List<Object>{new List<String>{caseId}})
            .selectFields(new List<Schema.SObjectField> {
                Case.Subject,
                Case.ContactId,
                Case.Description,
                Case.Case_Severity__c,
                Case.RecordTypeId,
                Case.Origin,
                Case.Product_Assistance__c,
                Case.Product_Assistance_Lvl2__c,
                Case.Product_Assistance_Lvl3__c,
                Case.Alternate_Email__c,
                Case.CallbackNumber__c
            })
            .executeQuery()
            .get(0);

        System.assertEquals(CASE_INFO_SUBJECT, newCase.Subject, 'Wrong subject');
        System.assertEquals(requestContactInfo.contactId, newCase.ContactId, 'Wrong contact id');
        System.assertEquals(OpportunityHelper.getOppRecordTypeMap('Support-Case'), newCase.RecordTypeId, 'Wrong record type');
        System.assertEquals('Web', newCase.Origin, 'Origin is not Web');
        System.assertEquals(CASE_INFO_SELECTED_PRODUCT, newCase.Product_Assistance__c, 'Wrong Area');
        System.assertEquals(CASE_INFO_SELECTED_PRODUCT2, newCase.Product_Assistance_Lvl2__c, 'Wrong Area 2');
        System.assertEquals(CASE_INFO_SELECTED_PRODUCT3, newCase.Product_Assistance_Lvl3__c, 'Wrong Area 3');
        System.assertEquals(CASE_INFO_ALTERNATE_EMAIL, newCase.Alternate_Email__c, 'Wrong Alt email');
        System.assertEquals(CASE_INFO_CALLBACK_PHONE, newCase.CallbackNumber__c, 'Wrong callback number');
        System.assertEquals(CASE_INFO_SEVERITY_LEVEL, newCase.Case_Severity__c, 'Wrong case severity');
        System.assertEquals(CASE_INFO_DESCRIPTION, newCase.Description, 'Wrong description');
    }

    @isTest
    static void testCreateCase_neg() {

        Object caseId;
        Test.startTest();
        System.runAs(getTestUser()) {

            SCWrappers.CreateCaseRequest createCaseRequest = new SCWrappers.CreateCaseRequest();
            createCaseRequest.caseInfo = JSON.serialize(getRequestCaseInfo());
            createCaseRequest.contactId = null;
            createCaseRequest.isGdpr = false;

            caseId = SupportCommunityNewCase.createCase(JSON.serialize(createCaseRequest))
                .data.get(SupportCommunityNewCase.LABEL_CREATED_CASE_ID);

        }
        Test.stopTest();

        System.assert(caseId == null, 'Invalid request returned a valid response');
    }

    @isTest
    static void testCreateCase_Gdpr() {

        String caseId;
        SCWrappers.ContactInfo requestContactInfo;

        Test.startTest();
        System.runAs(getTestUser()) {

            requestContactInfo = new SCWrappers.ContactInfo(
                (User) new UserSelector()
                    .selectUserByIdForNewCase(new List<String>{UserInfo.getUserId()})
                    .executeQuery()
                    .get(0)
            );
            requestContactInfo.email = 'new_test@ema.il';
            requestContactInfo.extension = '';
            
            SCWrappers.CreateCaseRequest createCaseRequest = new SCWrappers.CreateCaseRequest();
            createCaseRequest.caseInfo = JSON.serialize(getRequestGdprInfo());
            createCaseRequest.contactId = requestContactInfo.contactId;
            createCaseRequest.isGdpr = true;

            caseId = (String) SupportCommunityNewCase.createCase(JSON.serialize(createCaseRequest))
                .data.get(SupportCommunityNewCase.LABEL_CREATED_CASE_ID);

        }
        Test.stopTest();

        Case newCase = (Case) new CaseSelector()
            .selectCasesForApproval(new List<Object>{new List<String>{caseId}})
            .selectFields(new List<Schema.SObjectField> {
                Case.Subject,
                Case.ContactId,
                Case.Description,
                Case.Case_Severity__c,
                Case.RecordTypeId,
                Case.Origin,
                Case.Product_Assistance__c,
                Case.Product_Assistance_Lvl2__c,
                Case.Product_Assistance_Lvl3__c,
                Case.Alternate_Email__c,
                Case.CallbackNumber__c
            })
            .executeQuery()
            .get(0);

        System.assert(newCase.Subject.contains('DSR Request'), 'Wrong subject');
        System.assertEquals(requestContactInfo.contactId, newCase.ContactId, 'Wrong contact id');
        System.assertEquals(OpportunityHelper.getOppRecordTypeMap('DSR Request'), newCase.RecordTypeId, 'Wrong record type');
        System.assertEquals('Web', newCase.Origin, 'Origin is not Web');
        System.assertEquals(CASE_INFO_SELECTED_PRODUCT, newCase.Product_Assistance__c, 'Wrong Area');
        System.assertEquals(CASE_INFO_SELECTED_PRODUCT2, newCase.Product_Assistance_Lvl2__c, 'Wrong Area 2');
        System.assertEquals(CASE_INFO_SELECTED_PRODUCT3, newCase.Product_Assistance_Lvl3__c, 'Wrong Area 3');
        System.assertEquals(CASE_INFO_ALTERNATE_EMAIL, newCase.Alternate_Email__c, 'Wrong Alt email');
        System.assertEquals(CASE_INFO_CALLBACK_PHONE, newCase.CallbackNumber__c, 'Wrong callback number');
        System.assertEquals(SCWrappers.GDPR_DEFAULT_SEVERITY, newCase.Case_Severity__c, 'Wrong case severity');
        System.assert(newCase.Description.contains('Name of user requiring privacy action'), 'Wrong description');
    }

}