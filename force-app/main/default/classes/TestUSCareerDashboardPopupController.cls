@isTest 
private class TestUSCareerDashboardPopupController {
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void USCareerDashboardPopupController() {
        Test.startTest();
        User testUser = new User(alias = 'u11232', email='uscareerdashboard@test.com',emailencodingkey='UTF-8', lastname='Career',division='Manager', 
                         ProfileId=[SELECT Id FROM Profile WHERE Name='System Administrator' LIMIT 1].Id, Department='Sales',
                         languagelocalekey='en_US',localesidkey='en_US', country='United States',
                         timezonesidkey='America/Los_Angeles', username='uscareerdashboard@test.com', IsActive=true);                   
        insert testUser;
        
        Employee__c empObj = new Employee__c();
        empObj.First_Name__c = 'Dashboard';
        empObj.Last_Name__c = 'Career';
        empObj.Email__c = 'uscareerdashboard@test.com';
        empObj.Location__c = 'Denver, US';
        empObj.Department__c = 'Sales';
        empObj.Division__c = 'NoCoaching';
        empObj.Team__c = 'Development Bay';
        empObj.SPID__c = '58';
        empObj.User__c = testUser.Id;
        empObj.Hire_Date__c= System.today(); 
        empObj.agent_level__c= 'Level 1'; 
        empObj.Industry_Certified_Legal__c= TRUE; 
        empObj.Industry_Certified_Healthcare__c= TRUE; 
        empObj.Industry_Certified_High_Technology__c= TRUE; 
        empObj.Industry_Certified_Government__c= TRUE; 
        empObj.Industry_Certified_Real_Estate__c= TRUE; 
        empObj.Industry_Certified_Construction__c= TRUE; 
        empObj.Learning_Certified_Negotiation__c= TRUE; 
        empObj.Learning_Certified_RC_Pitch_Deck__c = TRUE;
        insert  empObj;
        Coaching_Log__c cObj = new Coaching_Log__c();
        cObj.Account_Executive__c = testUser.id;
        cObj.Coaching_Date__c = System.today();
        cObj.ASP1__c = 22.00;
        cObj.CLOSE_RATE__c = 22;
        cObj.UPSELL__c = 22;
        cObj.Employee_ID__c =  empObj.Id;
        cObj.BOOKINGS_QUALITY_TARGET__c = 22.00; 
        cObj.NETBOOKINGS_MTD_TARGET__c = 22.00;
        
        insert cObj;
        Apexpages.currentPage().getParameters().put('tid', testUser.Id);
        USCareerDashboardPopupController obj = new USCareerDashboardPopupController();
        obj.query = '';
        Test.stopTest();
    }
}