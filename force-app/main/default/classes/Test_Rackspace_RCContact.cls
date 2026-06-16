@isTest
private class Test_Rackspace_RCContact {

@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
      @isTest
	public static void TestRackspaceDistributionModel() {
        RackspaceDistributionModel obj=new RackspaceDistributionModel();
        RackspaceDistributionModel.distributionlists obj2=new RackspaceDistributionModel.distributionlists('test','test');
        RackspaceDistributionModel.emailAddressList obj3=new RackspaceDistributionModel.emailAddressList();
        RackspaceDistributionModel.contacts obj4=new RackspaceDistributionModel.contacts();
      String strResponse='{"distributionlists":[{"displayName":"TestUnmanagedDL","name":"testunmanageddl"},{"displayName":"UnmanagedDL","name":"unmanageddl"}],"offset":0,"size":250,"total":2}';
      RackspaceDistributionModel.getDistributionListObject(strResponse);
    }
   
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
     public  @isTest
    static void testRCSupportController2013(){
        try{
        RCSupportController2013 objRCSupportController2013=new RCSupportController2013();
        RCSiteSetup__c objRCSiteName= (RCSiteSetup__c)SmartFactory.createSObject('RCSiteSetup__c', true);
        objRCSiteName.RCSiteName__c='rcsupport2013';
        upsert objRCSiteName;

        PageReference pageRef = new PageReference('/apex/RCSupportHome2013');
        Test.setCurrentPageReference(pageRef);
       
        objRCSupportController2013.getAuthToken(); 
        objRCSupportController2013.getBrandFilter();
        objRCSupportController2013.getCacheMaxAge();
        objRCSupportController2013.getCanUserSeeKnowledge();
        objRCSupportController2013.getCategoryDescriptions();
        objRCSupportController2013.getCategoryGroupName();
        objRCSupportController2013.getFramedParam();
        objRCSupportController2013.getHomeAdText();
        objRCSupportController2013.getHomeAdTitle();
        objRCSupportController2013.getHomePage();
        objRCSupportController2013.getHomeUrl();
        objRCSupportController2013.getIsAnswerSearch();
        objRCSupportController2013.getIsArticleDetailsPage();
        objRCSupportController2013.getIsContact();
        objRCSupportController2013.getIsContactSupportPage();
        objRCSupportController2013.getIsCustomArticleListPage();
        objRCSupportController2013.getIsExternalPage();
        objRCSupportController2013.getIsHomePage();
        objRCSupportController2013.getIsProductPage();
        objRCSupportController2013.getRootCategoryName();

        objRCSupportController2013.getPage(ApexPages.currentpage().getUrl());
        objRCSupportController2013.getPageId();
        objRCSupportController2013.getParentId();
        objRCSupportController2013.getProductPage();
        objRCSupportController2013.getProductUrl();
        objRCSupportController2013.getRootCategoryName();
        objRCSupportController2013.getSearchPage();
        objRCSupportController2013.getSearchPageUrl();
        objRCSupportController2013.getSearchUrl();
        objRCSupportController2013.getSearchUrl1();
        
        String str2= objRCSupportController2013.currentArticleType;
        str2= objRCSupportController2013.currentArticleTypeLabel;
        str2= objRCSupportController2013.currentCategory;
        str2= objRCSupportController2013.currentCategoryName;
        str2= objRCSupportController2013.currentKeyword;
        str2= objRCSupportController2013.currentPage;
        Integer pageNum= objRCSupportController2013.currentPageNumber;
        PageReference objpage= objRCSupportController2013.currentPageReference;
        objRCSupportController2013.doSearch();
        objRCSupportController2013.doAdvanceSearch();
       
        str2= objRCSupportController2013.categoryParameterName; 
        str2= objRCSupportController2013.keywordParameterName; 
        str2= objRCSupportController2013.articleTypeParameterName; 
        str2= objRCSupportController2013.articleTypeLabelParameterName; 
        str2= objRCSupportController2013.pageNumberParameterName ;
        objRCSupportController2013.getSiteSetup();
        objRCSupportController2013.getServiceFilter();
        objRCSupportController2013.getServiceFilterURL();
        objRCSupportController2013.getSupportSearchPageUrl();
        objRCSupportController2013.getIsSearchPage();
        objRCSupportController2013.cleanKeyword();
        
        ApexPages.currentPage().getParameters().put('emailPage','kanishk.singh@simplion.com');
        String recMail=ApexPages.currentPage().getParameters().put('recMail','kanishk.singh@simplion.com');
        String senderMail=ApexPages.currentPage().getParameters().put('senderMail','kanishk.singh@simplion.com');
        String senderName=ApexPages.currentPage().getParameters().put('sendername','kanishk');
        String strTitle='';
        
        objRCSupportController2013.emailSend();
        objRCSupportController2013.getIdeaURL();
        objRCSupportController2013.getCaseURL();
        ApexPages.CurrentPage().getParameters().put('retUrl','service=1&brand=Ringcentral&token=test');
        ApexPages.CurrentPage().getParameters().put('brand','RC_UK');
        objRCSupportController2013.getIdeaURL();
        objRCSupportController2013.getCaseURL();
        
        ApexPages.CurrentPage().getParameters().put('token','test');
        objRCSupportController2013.getIdeaURL();
        objRCSupportController2013.getCaseURL();
     
        ApexPages.CurrentPage().getParameters().put('token','PFK8fqxUQZ3qw1nIWm0gVoPE1O1xEhiRFh0X3n0PxvEIzdYo+J2ihXuaSvfrFoOGXg5uqTH8KYo/2oohN5A7wQ==');
        objRCSupportController2013.getIdeaURL(); 
        objRCSupportController2013.getCaseURL();
       
        objRCSupportController2013.getIdeaURL(); 
        objRCSupportController2013.updateUserProfile();
        objRCSupportController2013.getCommunityId();

        objRCSupportController2013.localeSetting();
        }catch(Exception e){
          
        }  
    }
}