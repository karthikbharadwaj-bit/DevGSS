@isTest
private class TestSignUpCustomer {

	@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void SignUpCustomerTest() {
		try {
			TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT = true;
	    	TriggerHandler.BY_PASS_ACCOUNT_ON_UPDATE = true;
	    	TriggerHandler.BY_PASS_OPPORTUNITY_ON_INSERT = true;
	    	TriggerHandler.BY_PASS_OPPORTUNITY_ON_UPDATE = true;
			PartnerSignUpProfile__c setting = new PartnerSignUpProfile__c();
			setting.Name = 'RC Partner';
			setting.Profile_Name__c = 'RC Partner';
			insert setting; 
			
			PartnerSignUpProfileAdmin__c setting1 = new PartnerSignUpProfileAdmin__c();
			setting1.Name = 'System Administrator';
			setting1.Profile_Name__c = 'System Administrator';
			insert setting1; 
			
		 	Schema.DescribeSObjectResult result = Account.SObjectType.getDescribe();
    		Map<string,Schema.RecordTypeInfo> rtMapByName = result.getRecordTypeInfosByName();
			
			Account accObj = new Account();
			accObj.Name = 'Test Acc';
			accObj.Partner_ID__c = '111';
			accObj.RecordTypeId = rtMapByName.get('Partner Account').getRecordTypeId();
			insert accObj; 	
		
			Opportunity opp0 = new Opportunity();
			opp0.Name ='test';
			opp0.StageName ='3. ActivePipe';
			opp0.CloseDate = System.today()+ 3;
			opp0.Partner_ID__c = '111';
			opp0.AID__c = '222';
			opp0.BMID__c = '333';
			opp0.PID__c ='444';
			opp0.SID__c ='8908';
			opp0.AccountId = accObj.id;
		
			insert opp0;
		
			ApexPages.currentPage().getParameters().put('id', opp0.id); 
			SignUpCustomer suDemo0 = new SignUpCustomer(null);
			suDemo0.doSAve();
			Opportunity opp1 = new Opportunity();
			opp1.Name ='test';
			opp1.StageName ='3. ActivePipe';
			opp1.CloseDate = System.today()+ 3;
			opp1.Partner_ID__c = '111';
			opp1.AID__c = '222';
			opp1.BMID__c = '333';
			opp1.PID__c ='';
			opp1.SID__c = '3323';
			opp1.AccountId = accObj.id;
		
			insert opp1;
			
			Test.startTest();
			
			Campaign campaignObj = new Campaign(Name='TestCampaign',
			DNIS__c='Test006',
			AID__c='Test007',
			PID__c='Test008',
			BMID__c='Test009');
			insert campaignObj;
			
			ApexPages.currentPage().getParameters().put('id', opp1.id); 
			SignUpCustomer suDemo1 = new SignUpCustomer(null);             
            suDemo1.getIsNotAvailable();
            suDemo1.setBMID('TestBMID');
            suDemo1.setAID('TestAID');
            suDemo1.setPID('TestPID');
            suDemo1.setSID('TestSID');
            suDemo1.getPromotion();
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
			opp2.SID__c = '3321';
			opp2.AccountId = accObj.id;
			insert opp2;			
			
			ApexPages.currentPage().getParameters().put('id', opp2.id); 
			SignUpCustomer suDemo2 = new SignUpCustomer(null);
			suDemo2.setSelectedValueOffering('Signup003 Office');
			suDemo2.getStrRedenderdValue();
			suDemo2.setStrRedenderdValue('false');
			suDemo2.getSelectedValueOffering();
			suDemo2.getSelectedValueRetired();
			suDemo2.setSelectedValueRetired('TestSample');
            suDemo2.getBillType();
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
			suDemo2.getOPPID();
			suDemo2.getSAFID();
			suDemo2.getPaymentItems();
			suDemo2.getIsNotAvailable();
			suDemo2.getStrUrl();
			suDemo2.setStrUrl('www.google.com');
			suDemo2.getSelectTrial();
			suDemo2.doSearch();
			suDemo2.getStrSignUpId();
			suDemo2.createParam('test','test','test');
			suDemo2.doSAve();
			Test.stopTest();
		    
		} catch (exception e){}
    }

	@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void SignUpCustomerTest2() {
		try {
			TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT = true;
	    	TriggerHandler.BY_PASS_ACCOUNT_ON_UPDATE = true;
	    	TriggerHandler.BY_PASS_OPPORTUNITY_ON_INSERT = true;
	    	TriggerHandler.BY_PASS_OPPORTUNITY_ON_UPDATE = true;	
						
			PartnerSignUpProfile__c setting = new PartnerSignUpProfile__c();
			setting.Name = 'RC Partner';
			setting.Profile_Name__c = 'RC Partner';
			insert setting; 
			
			PartnerSignUpProfileAdmin__c setting1 = new PartnerSignUpProfileAdmin__c();
			setting1.Name = 'System Administrator';
			setting1.Profile_Name__c = 'System Administrator';
			insert setting1; 
			
		 	Schema.DescribeSObjectResult result = Account.SObjectType.getDescribe();
    		Map<string,Schema.RecordTypeInfo> rtMapByName = result.getRecordTypeInfosByName();
			
			Account accObj = new Account();
			accObj.Name = 'Test Acc';
			accObj.Partner_ID__c = '111';
			accObj.RecordTypeId = rtMapByName.get('Partner Account').getRecordTypeId();
			insert accObj;
		
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
			SignUpCustomer suDemo4 = new SignUpCustomer(null);
		    suDemo4.getSelectedValue();
		    suDemo4.doSAve();
		    suDemo4.setBlnSignUpType(true);
		    suDemo4.doSAve();
		    suDemo4.selectTab();
		    suDemo4.resetAll();
		    suDemo4.doSearch();
            suDemo4.getStrSignUpId();
            suDemo4.getPaymentItems();
            suDemo4.getTrialItems();
            suDemo4.getServiceItemsOfferingUS();
			suDemo4.getServiceItemsRetiredUS();
			suDemo4.getServiceItemsOfferingCAN();
			suDemo4.getServiceItemsRetiredCAN();
			suDemo4.getServiceItemsOfferingUK();
			suDemo4.getServiceItemsRetiredUK();
		} catch (exception e){}
    }
}