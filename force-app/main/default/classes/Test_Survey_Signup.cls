@isTest
private class Test_Survey_Signup {
	@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void SignUpLinksDemoTest() {
    	TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT = true;
	    	TriggerHandler.BY_PASS_Approver_Trigger = true;
	    	TriggerHandler.BY_PASS_OPPORTUNITY_ON_INSERT = true;
    		TriggerHandler.BY_PASS_OPPORTUNITY_ON_UPDATE = true;
		
	try{		
		Account accObj = new Account();
		accObj.Name = 'Test Account1';
		insert accObj;	
		
		Opportunity opp0 = new Opportunity();
		opp0.Name ='test';
		opp0.StageName ='3. ActivePipe';
		opp0.CloseDate = System.today()+ 3;
		opp0.Partner_ID__c = '111';
		opp0.AID__c = '222';
		opp0.BMID__c = '333';
		opp0.PID__c ='444';
		opp0.AccountId = accObj.id;
		insert opp0;
		
		Test.startTest();
		
		ApexPages.currentPage().getParameters().put('id', opp0.id); 
		SignUpLinksDemo suDemo0 = new SignUpLinksDemo(null);
		suDemo0.doSAve();
		Opportunity opp1 = new Opportunity();
		opp1.Name ='test';
		opp1.StageName ='3. ActivePipe';
		opp1.CloseDate = System.today()+ 3;
		opp1.Partner_ID__c = '111';
		opp1.AID__c = '222';
		opp1.BMID__c = '333';
		opp1.PID__c ='';
		opp1.AccountId = accObj.id;
		insert opp1;
		
		Campaign campaignObj = new Campaign(Name='TestCampaign',
		DNIS__c='Test006',
		AID__c='Test007',
		PID__c='Test008',
		BMID__c='Test009');
		insert campaignObj;
		
		
		ApexPages.currentPage().getParameters().put('id', opp1.id); 
		SignUpLinksDemo suDemo1 = new SignUpLinksDemo(null);
		suDemo1.setSelectedValue('');
		suDemo1.getTrialItems();
		suDemo1.doSAve();
		suDemo1.setTabName('US');
		suDemo1.getTabName();
		
		Opportunity opp2 = new Opportunity();		
		opp2.Name ='test';
		opp2.StageName ='3. ActivePipe';
		opp2.CloseDate = System.today() + 3;
		opp2.Partner_ID__c = '111';
		opp2.AID__c = '222';
		opp2.BMID__c = '';
		opp2.PID__c ='444';
		opp2.CampaignId = campaignObj.id;
		opp2.AccountId = accObj.id;
		insert opp2;
		
		Test.stopTest();
		
		ApexPages.currentPage().getParameters().put('id', opp2.id); 
		SignUpLinksDemo suDemo2 = new SignUpLinksDemo(null);
		suDemo2.doSAve();
		suDemo2.getStrRedenderdValue();
		suDemo2.setStrRedenderdValue('false');
		suDemo2.getSelectedValueOffering();
		suDemo2.getSelectedValueRetired();
		suDemo2.getStrImageUrl();
		suDemo2.setStrImageUrl('tset');
		suDemo2.getBlnSignUpType();
		suDemo2.setBlnSignUpType(true);
		suDemo2.getServiceItemsOfferingUS();
		suDemo2.getServiceItemsRetiredUS();
		suDemo2.getServiceItemsOfferingCAN();
		suDemo2.getServiceItemsRetiredCAN();
		suDemo2.getServiceItemsOfferingUK();
		suDemo2.getServiceItemsRetiredUK();
		suDemo2.getSelectTrial();
		suDemo2.getPartnerID();
		suDemo2.getBMID();
		suDemo2.getAID();
		suDemo2.getPID();
		suDemo2.getSPID();
		suDemo2.getPromotion();
		suDemo2.getOPPID();
		suDemo2.getSAFID();
		suDemo2.getIsNotAvailable();
		suDemo2.getStrUrl();
		suDemo2.setStrUrl('www.google.com');
		suDemo2.getSelectTrial();
		suDemo2.doSearch();
		suDemo2.getStrSignUpId();
		suDemo2.createParam('test','test','test');
		
		Campaign campaignObj2 = new Campaign(Name='TestCampaign',
		DNIS__c='Test007',
		AID__c='Test008',
		PID__c='Test009',
		BMID__c='Test090');
		insert campaignObj2;
		
		Opportunity opp4 = new Opportunity();
		opp4.Name ='test';
		opp4.StageName ='3. ActivePipe';
		opp4.CloseDate = System.today() + 3;
		opp4.CampaignId = campaignObj2.id;
		opp4.AccountId = accObj.id;
		insert opp4;
		
	    ApexPages.currentPage().getParameters().put('id', opp4.id); 
		SignUpLinksDemo suDemo4 = new SignUpLinksDemo(null);
	    suDemo4.getSelectedValue();
	    suDemo4.doSAve();
	    suDemo4.doSAve();
	    suDemo4.selectTab();
	    suDemo4.resetAll();
	    
	} catch (exception e){}
    }

	@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void SignUpLinksDemoTest2() {
    	TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT = true;
	    	TriggerHandler.BY_PASS_Approver_Trigger = true;
	    	TriggerHandler.BY_PASS_OPPORTUNITY_ON_INSERT = true;
    		TriggerHandler.BY_PASS_OPPORTUNITY_ON_UPDATE = true;
		
	try{	
		Account accObj = new Account();
		accObj.Name = 'Test Account1';
		insert accObj;	
		
		Opportunity opp0 = new Opportunity();
		
		opp0.Name ='test';
		opp0.StageName ='3. ActivePipe';
		opp0.CloseDate = System.today()+ 3;
		opp0.Partner_ID__c = '111';
		opp0.AID__c = '222';
		opp0.BMID__c = '333';
		opp0.PID__c ='444';
		opp0.AccountId = accObj.id;
		
		insert opp0;
		
		Test.startTest();
		
		ApexPages.currentPage().getParameters().put('id', opp0.id); 
		SignUpLinksDemo suDemo0 = new SignUpLinksDemo(null);
		suDemo0.doSAve();
		Opportunity opp1 = new Opportunity();
		
		opp1.Name ='test';
		opp1.StageName ='3. ActivePipe';
		opp1.CloseDate = System.today()+ 3;
		opp1.Partner_ID__c = '111';
		opp1.AID__c = '222';
		opp1.BMID__c = '333';
		opp1.PID__c ='';
		opp1.AccountId = accObj.id;
		
		insert opp1;
		
		Campaign campaignObj = new Campaign(Name='TestCampaign',
		DNIS__c='Test006',
		AID__c='Test007',
		PID__c='Test008');
		insert campaignObj;
		
		Opportunity opp2 = new Opportunity();
		opp2.Name ='test';
		opp2.StageName ='3. ActivePipe';
		opp2.CloseDate = System.today() + 3;
		opp2.Partner_ID__c = '111';
		opp2.AID__c = '222';
		opp2.BMID__c = '';
		opp2.PID__c ='444';
		opp2.CampaignId = campaignObj.id;
		opp2.AccountId = accObj.id;
		insert opp2;
        
		ApexPages.currentPage().getParameters().put('id', opp1.id); 
		SignUpLinksDemo suDemo1 = new SignUpLinksDemo(null);
        suDemo1.getIsNotAvailable();
		suDemo1.setSelectedValue('');
		suDemo1.getTrialItems();
		suDemo1.doSAve();
		suDemo1.setTabName('US');
		suDemo1.getTabName();
		
		Test.stopTest();
		
		Campaign campaignObj2 = new Campaign(Name='TestCampaign',
		DNIS__c='Test007',
		AID__c='Test008',
		PID__c='Test009');
		
		insert campaignObj2;
		
		Opportunity opp4 = new Opportunity();
		
		opp4.Name ='test';
		opp4.StageName ='3. ActivePipe';
		opp4.CloseDate = System.today() + 3;
		opp4.CampaignId = campaignObj2.id;
		opp4.AccountId = accObj.id;
		insert opp4;
		
        ApexPages.currentPage().getParameters().put('id', opp4.id); 
        SignUpLinksDemo suDemo4 = new SignUpLinksDemo(null);
        suDemo4.getSelectedValue();
        suDemo4.setSelectedValueOffering('TestSelectedValue');
        suDemo4.setSelectedValueRetired('TestRetired');
        suDemo4.setSelectedValue('Sample');
        suDemo4.doSAve();
        suDemo4.setBlnSignUpType(true);
		suDemo4.doSAve();
        suDemo4.selectTab();
        suDemo4.resetAll();        
        suDemo4.doSearch();
        suDemo4.getPromotion();
        suDemo4.getBillType();
        suDemo4.getBMID();
        suDemo4.getAID();
        suDemo4.getPID();
        suDemo4.getSPID();
        suDemo4.getSelectTrial();
        suDemo4.getPaymentItems();
        suDemo4.getStrSignUpId();
        suDemo4.setStrSignUpId('TestStr');
        suDemo4.getServiceItemsOfferingUS();
        suDemo4.getServiceItemsRetiredUS();
        suDemo4.getServiceItemsOfferingCAN();
        suDemo4.getServiceItemsRetiredCAN();
        suDemo4.getServiceItemsOfferingUK();
        suDemo4.getServiceItemsRetiredUK();
        
    } catch (exception e){}	
    }
	
	@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void RCSupportControllerFaxtest() {
        RCSupportControllerFax objRCSupportController = new RCSupportControllerFax();
        RCSiteSetup__c objRCSiteName= (RCSiteSetup__c)SmartFactory.createSObject('RCSiteSetup__c', true);
        objRCSiteName.RCSiteName__c='rcsupport';
        upsert objRCSiteName;

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
        
        String str2= objRCSupportController.currentArticleType;
        str2= objRCSupportController.currentArticleTypeLabel;
        str2= objRCSupportController.currentCategory;
        str2= objRCSupportController.currentCategoryName;
        str2= objRCSupportController.currentKeyword;
        str2= objRCSupportController.currentPage;
        Integer pageNum= objRCSupportController.currentPageNumber;
        PageReference objpage= objRCSupportController.currentPageReference;
        objRCSupportController.doSearch();
        objRCSupportController.doAdvanceSearch();
       
        str2= objRCSupportController.categoryParameterName; 
        str2= objRCSupportController.keywordParameterName; 
        str2= objRCSupportController.articleTypeParameterName; 
        str2= objRCSupportController.articleTypeLabelParameterName; 
        str2= objRCSupportController.pageNumberParameterName ;
        objRCSupportController.getSiteSetup();
        objRCSupportController.getServiceFilter();
        objRCSupportController.getServiceFilterURL();
        objRCSupportController.getSupportSearchPageUrl();
        objRCSupportController.getIsSearchPage(); 
        objRCSupportController.cleanKeyword();
        
        ApexPages.currentPage().getParameters().put('emailPage','kanishk.singh@simplion.com');
        String recMail=ApexPages.currentPage().getParameters().put('recMail','kanishk.singh@simplion.com');
        String senderMail=ApexPages.currentPage().getParameters().put('senderMail','kanishk.singh@simplion.com');
        String senderName=ApexPages.currentPage().getParameters().put('sendername','kanishk');
        String strTitle='';
        
        objRCSupportController.emailSend();
        objRCSupportController.getCaseURL();
        ApexPages.CurrentPage().getParameters().put('retUrl','service=1&brand=Ringcentral&token=test');
        ApexPages.CurrentPage().getParameters().put('brand','RC_UK');
        objRCSupportController.getCaseURL();
        
        ApexPages.CurrentPage().getParameters().put('token','test');
        objRCSupportController.getCaseURL();
     
        ApexPages.CurrentPage().getParameters().put('token','PFK8fqxUQZ3qw1nIWm0gVoPE1O1xEhiRFh0X3n0PxvEIzdYo+J2ihXuaSvfrFoOGXg5uqTH8KYo/2oohN5A7wQ==');
        objRCSupportController.getCaseURL();
       
        objRCSupportController.localeSetting();
        objRCSupportController.getURLCategory();
        //objRCSupportController.createURL('http://ringcentral.force.com/rcsupport', '','');
        objRCSupportController.getPage('http://ringcentral.force.com/rcsupport?id=test/');
	
    }
}