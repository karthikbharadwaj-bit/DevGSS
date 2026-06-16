@isTest
private class Test_classLead {

		@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    	@isTest
    static void Test_LeadSpinner() {
			Profile prof = [SELECT Id, Name FROM Profile WHERE Name LIKE '%SDR%'  LIMIT 1];
			User user1 = new User(alias = 'newUser1', email='newuser1@simplion.com.test',
			emailencodingkey='UTF-8', lastname='Testing1', 
			languagelocalekey='en_US', localesidkey='en_US', profileid = prof.Id,
			timezonesidkey='America/Los_Angeles', username= System.now().millisecond() + 'newuser1@simplion.com.test');
			insert user1;
	        
	        User user2 = new User(alias = 'newUser2', email='newuser2@simplion.com.test',
			emailencodingkey='UTF-8', lastname='Testing2', 
			languagelocalekey='en_US', localesidkey='en_US', profileid = prof.Id,
			timezonesidkey='America/Los_Angeles', username= System.now().millisecond() + 'newuser2@simplion.com.test');
			insert user2;
			
			User user3 = new User(alias = 'newUser3', email='newuser3@simplion.com.test',
			emailencodingkey='UTF-8', lastname='Testing3', 
			languagelocalekey='en_US', localesidkey='en_US', profileid = prof.Id,
			timezonesidkey='America/Los_Angeles', username= System.now().millisecond() + 'newuser3@simplion.com.test');
			insert user3;
			
			System.runAs(user1) {
	            // Test.startTest();
	            Campaign campObj1 = new Campaign(Name='TestCampaign',Protected_Campaign__c=true ,Lead_Creation_Score__c='300', IsActive=true, 
			AID__c='test0121' );
	        
	        insert campObj1;
		
	        Lead leadObj = new Lead(firstName='Singh', Title='VP', Country='UK', AID__c='test0121',Downgrade_Reason__c='Not a Decision Maker'
	         ,LeadSource='Inbound Call', lastname = 'Virendra', NumberOfEmployees__c='2-5',
	        company='Simplion', email='virendra.singh3@simplion.co.uk', phone='9910106803');
	        insert leadObj;
	        Test.startTest();
        	ApexPages.StandardController sc = new ApexPages.standardController(leadObj);
        	LeadSpinner ui = new LeadSpinner(sc);
			
			Lead leadObj1 = new Lead(firstName='Singh1', Title='VP', Country='UK', AID__c='test0122',Downgrade_Reason__c='Not a Decision Maker'
	         ,LeadSource='Inbound Call', lastname = 'Virendra1', NumberOfEmployees__c='2-5',
	        company='Simplion1', email='virendra.singh5@simplion.co.uk', phone='9910106804',ownerId = user1.Id);
	        insert leadObj1;
	        sc = new ApexPages.standardController(leadObj1);
        	ui = new LeadSpinner(sc);
        	
	        leadObj1.lead_folder__c = null;
			ui.resetFolder();
			ui.getSDRProfiles();
        	try {
				String folder = leadObj1.lead_folder__c.trim();
			} catch(Exception ex) {
				//ui.setException(ex.getMessage());//----->
			}
			
			leadObj = new Lead(firstName='Singh', Title='VP', Country='UK',Downgrade_Reason__c='Not a Decision Maker'
             ,LeadSource='Inbound Call', lastname = 'Virendra', NumberOfEmployees__c=' ',
            company='Simplion', email='virendra.singh4@simplion.co.uk', phone='9910106803');
            insert leadObj;
			ui.goToLead();
        	sc = new ApexPages.standardController(leadObj);
        	ui = new LeadSpinner(sc);
			
			leadObj = new Lead(Downgrade_Reason__c='Not a Decision Maker');
			sc = new ApexPages.standardController(leadObj);
        	ui = new LeadSpinner(sc);
        	Test.stopTest();
		}
    }
}