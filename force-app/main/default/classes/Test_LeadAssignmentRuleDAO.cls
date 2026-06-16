@isTest
private class Test_LeadAssignmentRuleDAO {

	@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void TestLeadAssignmentRuleDAO() {
		Profile prof = [SELECT Id, Name FROM Profile WHERE Name LIKE '%SDR%'  LIMIT 1];
		User user1 = new User(alias = 'newUser1', email='newuser1@simplion.com.test',
		emailencodingkey='UTF-8', lastname='Testing1', 
		languagelocalekey='en_US', localesidkey='en_US', profileid = prof.Id,
		timezonesidkey='America/Los_Angeles', username= System.now().millisecond() + 'newuser1@simplion.com.test');
		insert user1;
		
		Profile prof1 = [SELECT Id, Name FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
		User user2 = new User(alias = 'lar', firstname = 'LAR',lastname = 'System User',email='newuser2@simplion.com.test',
		emailencodingkey='UTF-8',
		languagelocalekey='en_US', localesidkey='en_US', profileid = prof1.Id,
		timezonesidkey='America/Los_Angeles', username= System.now().millisecond() + 'newuser2@simplion.com.test');
		insert user2;
		
		Campaign campObj1 = new Campaign(Name='TestCampaign',Protected_Campaign__c=true ,Lead_Creation_Score__c='300', IsActive=true,AID__c='test0121' );
		insert campObj1;
		        
        Test.startTest();
		
		List<Lead> lstLead = new List<Lead>();
		Lead  r = new Lead(FirstName = 'testabc',lastName ='testxyz',Leadsource ='Inbaound Call',Agent_Email_Address__c ='xyz',Phone='123654789',
						    Email='Test@Test.com',Downgrade_Reason__c ='Lost to Competition',Company = 'Test LTD',ownerId = user2.id);  
		lstLead.add(r);
		insert lstLead;
		Lead  r1 = new Lead(FirstName = 'testabc121',lastName ='testxyz121',Leadsource ='Inbaound Call',Agent_Email_Address__c ='xyz121',Phone='143654789',
						    Email='Test@Test.com',Downgrade_Reason__c ='Lost to Competition',Company = 'Test LTD',ownerId = user2.id); 
		insert r1;
        		
		Test.stopTest();
    }
}