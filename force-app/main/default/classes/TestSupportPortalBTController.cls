@isTest
private class TestSupportPortalBTController {

    @isTest
    static void myUnitTest() {
    	
    	PageReference pageRef1 = new PageReference('/apex/btcloduphone');
        Test.setCurrentPageReference(pageRef1);
        
        SupportPortalControllerNew objSupportPortalControllerNew=new SupportPortalControllerNew();
        RCSiteSetup__c objRCSiteName= (RCSiteSetup__c)SmartFactory.createSObject('RCSiteSetup__c', true);
        objRCSiteName.RCSiteName__c='btcloudphone';
        upsert objRCSiteName;
       
        objSupportPortalControllerNew.emailSend();
        ApexPages.currentPage().getParameters().put('ARTICLEID','1234');
        objSupportPortalControllerNew.redirectToDetailPage();
        
        ApexPages.currentPage().getParameters().put('brand','BT');
        ApexPages.currentPage().getParameters().put('token','z9F0QUf+yk2vnPp2Ckq81lAV4+FLcnzlnXjSzScnckPXM40gzFAWY3gyonmvCyoEU/pD2w1pHQ4wA4gXZg80xQ==');
        ApexPages.currentPage().getParameters().put('startURL','/apex/btcloduphone');
        objSupportPortalControllerNew.isTokenFound = true;
        objSupportPortalControllerNew.isValidTokenFound();
        objSupportPortalControllerNew.getAuthToken(); 
        objSupportPortalControllerNew.getBrandFilter();
        objSupportPortalControllerNew.getCacheMaxAge();
        objSupportPortalControllerNew.getCanUserSeeKnowledge();
        objSupportPortalControllerNew.getCategoryDescriptions();
        objSupportPortalControllerNew.getCategoryGroupName();
        objSupportPortalControllerNew.getFramedParam();
        objSupportPortalControllerNew.getHomeAdText();
        objSupportPortalControllerNew.getHomeAdTitle();
        objSupportPortalControllerNew.getHomePage();
        objSupportPortalControllerNew.getHomeUrl();
        objSupportPortalControllerNew.getIsAnswerSearch();
        objSupportPortalControllerNew.getIsArticleDetailsPage();
        objSupportPortalControllerNew.getIsContact();
        objSupportPortalControllerNew.getIsContactSupportPage();
        objSupportPortalControllerNew.getIsCustomArticleListPage();
        objSupportPortalControllerNew.getIsExternalPage();
        objSupportPortalControllerNew.getIsHomePage();
        objSupportPortalControllerNew.getIsProductPage();
        objSupportPortalControllerNew.getRootCategoryName();
        objSupportPortalControllerNew.getIsVideoLinkPage();
        objSupportPortalControllerNew.getPage(ApexPages.currentpage().getUrl());
        objSupportPortalControllerNew.getPageId();
        objSupportPortalControllerNew.getParentId();
        objSupportPortalControllerNew.getProductPage();
        objSupportPortalControllerNew.getProductUrl();
        objSupportPortalControllerNew.getRootCategoryName();
        objSupportPortalControllerNew.getSearchPage();
        objSupportPortalControllerNew.getValidToken();
        objSupportPortalControllerNew.getNextPageName();
        objSupportPortalControllerNew.login();
        objSupportPortalControllerNew.PageAuthorization();
        objSupportPortalControllerNew.getPageAuthorization();
        objSupportPortalControllerNew.validateLoginDetail();
        objSupportPortalControllerNew.openCase();
        objSupportPortalControllerNew.openCreateCase();
        objSupportPortalControllerNew.openMyCase();
        objSupportPortalControllerNew.getUKPortal();
        objSupportPortalControllerNew.getSearchPageUrl();
        objSupportPortalControllerNew.getSearchUrl();
        objSupportPortalControllerNew.getSearchUrl1();
        String str2= objSupportPortalControllerNew.currentArticleType;
        str2= objSupportPortalControllerNew.currentArticleTypeLabel;
        str2= objSupportPortalControllerNew.currentCategory;
        str2= objSupportPortalControllerNew.currentCategoryName;
        str2= objSupportPortalControllerNew.currentKeyword;
        String strCurrent=objSupportPortalControllerNew.currentKeywordSerach;
        str2= objSupportPortalControllerNew.currentPage;
        Integer pageNum= objSupportPortalControllerNew.currentPageNumber;
        PageReference objpage= objSupportPortalControllerNew.currentPageReference;
        objSupportPortalControllerNew.doSearch();
        objSupportPortalControllerNew.doAdvanceSearch();
       
        str2= objSupportPortalControllerNew.categoryParameterName; 
        str2= objSupportPortalControllerNew.keywordParameterName; 
        str2= objSupportPortalControllerNew.articleTypeParameterName; 
        str2= objSupportPortalControllerNew.articleTypeLabelParameterName; 
        str2= objSupportPortalControllerNew.pageNumberParameterName ;
        objSupportPortalControllerNew.getSiteSetup();
        objSupportPortalControllerNew.getServiceFilter();
        objSupportPortalControllerNew.getServiceFilterURL();
        objSupportPortalControllerNew.getSupportSearchPageUrl();
        objSupportPortalControllerNew.getIsSearchPage();
        objSupportPortalControllerNew.cleanKeyword();
        ApexPages.currentPage().getParameters().put('emailPage','rcindiateam@simplion.com');
        String recMail=ApexPages.currentPage().getParameters().put('recMail','rcindiateam@simplion.com');
        String senderMail=ApexPages.currentPage().getParameters().put('senderMail','rcindiateam@simplion.com');
        String senderName=ApexPages.currentPage().getParameters().put('sendername','rcindiateam');
        String strTitle='';
        
    		Test.startTest();
        
            KCSDataFactory.setup();

            System.runAs(KCSDataFactory.admin) {
                Knowledge__kav rcKnowlgKavObj = new Knowledge__kav();
                rcKnowlgKavObj.RC_Knowledge_Article_Details__c = 'These are hte detais test';
                rcKnowlgKavObj.RC_Knowledge_Article_Key_Words__c = 'phone,office,fax';
                rcKnowlgKavObj.RC_Knowledge_Article_Legacy_Article_ID__c = 'asjw2343';
                rcKnowlgKavObj.RC_Knowledge_Article_Ranking__c = '1';
                rcKnowlgKavObj.Summary = 'test summary';
                rcKnowlgKavObj.Title='123test'+system.now();
                rcKnowlgKavObj.UrlName = 'test-title';
                insert rcKnowlgKavObj;
                rcKnowlgKavObj = [ 
                    SELECT UrlName, KnowledgeArticleId, PublishStatus
                    FROM Knowledge__kav
                    WHERE Id = :rcKnowlgKavObj.Id
                ];
                System.assertEquals('test-title', rcKnowlgKavObj.UrlName);
                String articleId = string.valueof(rcKnowlgKavObj.KnowledgeArticleId);
                KbManagement.PublishingService.publishArticle(articleId, true);
                System.assertEquals('Draft', rcKnowlgKavObj.PublishStatus);
                List<Knowledge__DataCategorySelection> kDList = new List<Knowledge__DataCategorySelection>();
                kDlist.add(new Knowledge__DataCategorySelection(DataCategoryGroupName = 'Brand', DataCategoryName = 'BT', ParentId =rcKnowlgKavObj.Id));
                kDlist.add(new Knowledge__DataCategorySelection(DataCategoryGroupName = 'RCProductVersion', DataCategoryName = 'RC2013', ParentId = rcKnowlgKavObj.Id));
                kDlist.add(new Knowledge__DataCategorySelection(DataCategoryGroupName = 'Topic', DataCategoryName = 'Templates', ParentId = rcKnowlgKavObj.Id));
                insert kDList;
                String KnowledgeArticleId = rcKnowlgKavObj.KnowledgeArticleId;
                Integer len = (String.valueOf(rcKnowlgKavObj.KnowledgeArticleId)).length();
                Integer len2 = 0;
                if (KnowledgeArticleId.length() > 15) {
                    len2 = len - 15;
                }
                KnowledgeArticleId = KnowledgeArticleId.subString(0, len - len2);
                
                RC_Article_Rating__c rcArticleObj = new RC_Article_Rating__c();
                rcArticleObj.of_User_Rate_This_Article__c =1;
                rcArticleObj.Article_Id__c = KnowledgeArticleId;
                rcArticleObj.Article_Rating_Count__c =1;
                rcArticleObj.RC_Average_Rating__c =1;
                rcArticleObj.RCArticle_Title__c = 'test title';
                insert rcArticleObj;
                
                objSupportPortalControllerNew.getKnowledgeArticleVersionDetails();
                objSupportPortalControllerNew.getKnowledgeArticleDataCategory(new List<Id>{rcKnowlgKavObj.Id},'Brand' );
                objSupportPortalControllerNew.getParentChildCategory();
                objSupportPortalControllerNew.getIsKnowledgePage();
            }
            Test.stopTest();
        
    }
    
    
}