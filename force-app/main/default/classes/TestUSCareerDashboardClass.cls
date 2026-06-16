@isTest 
private class TestUSCareerDashboardClass {
    private static List<User> createUsers(User testUser) {
        List<User> users = new List<User>();
        User testUser1 = new User(alias = 'u1120', email='uscareerdashboard1@test.com',emailencodingkey='UTF-8', lastname='Career1',division='Agent', 
                     ProfileId=[SELECT Id FROM Profile WHERE Name='Sales Manager - Business Processing' LIMIT 1].Id, Department='Sales', ManagerId=testUser.Id,
                     languagelocalekey='en_US',localesidkey='en_US', country='United States',
                     timezonesidkey='America/Los_Angeles', username='uscareerdashboard1@test.com', IsActive=true);                   
        users.add(testUser1);
        User testUser2 = new User(alias = 'u1121', email='uscareerdashboard2@test.com',emailencodingkey='UTF-8', lastname='Career2',division='Agent', 
                     ProfileId=[SELECT Id FROM Profile WHERE Name='Sales Manager - Business Processing' LIMIT 1].Id, Department='Sales', ManagerId=testUser.Id,
                     languagelocalekey='en_US',localesidkey='en_US', country='United States',
                     timezonesidkey='America/Los_Angeles', username='uscareerdashboard2@test.com', IsActive=true);                   
        users.add(testUser2);
        User testUser3 = new User(alias = 'u1122', email='uscareerdashboard3@test.com',emailencodingkey='UTF-8', lastname='Career3',division='Agent', 
                     ProfileId=[SELECT Id FROM Profile WHERE Name='Sales Manager - Business Processing' LIMIT 1].Id, Department='Sales', ManagerId=testUser.Id,
                     languagelocalekey='en_US',localesidkey='en_US', country='United States',
                     timezonesidkey='America/Los_Angeles', username='uscareerdashboard3@test.com', IsActive=true);                   
        users.add(testUser3);
        return users;
    }
    
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void USCareerDashboardClass1() {
    	Test.startTest();
        User testUser = new User(alias = 'u11232', email='uscareerdashboard@test.com',emailencodingkey='UTF-8', lastname='Career',division='Manager', 
                     ProfileId=[SELECT Id FROM Profile WHERE Name='Sales Manager - Business Processing' LIMIT 1].Id, Department='Sales',
                     languagelocalekey='en_US',localesidkey='en_US', country='United States',
                     timezonesidkey='America/Los_Angeles', username='uscareerdashboard@test.com', IsActive=true);                   
        insert testUser;
        insert createUsers(testUser);
        
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
        
        System.runAs(testUser) {
            ApexPages.StandardController sc = new ApexPages.standardController(empObj); 
            USCareerDashboardClass signupObj = new USCareerDashboardClass(sc);
            List<SelectOption> v1 = signupObj.UserList2;
            signupObj.UserList2 = new List<SelectOption>();
            signupObj.checkops();
            signupObj.checkops2();
            signupObj.checkCert();
        	signupObj.checkLevelUp();
        	signupObj.getChartData();
        }
        Test.stopTest();
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void USCareerDashboardClass2() {
        Test.startTest();
        User testUser = new User(alias = 'u11232', email='uscareerdashboard@test.com',emailencodingkey='UTF-8', lastname='Career',division='Manager', 
                     ProfileId=[SELECT Id FROM Profile WHERE Name='Sales Manager - Business Processing' LIMIT 1].Id, Department='Sales',
                     languagelocalekey='en_US',localesidkey='en_US', country='United States',
                     timezonesidkey='America/Los_Angeles', username='uscareerdashboard@test.com', IsActive=true);                   
        insert testUser;
        insert createUsers(testUser);
        
        Employee__c empObj = new Employee__c();
        empObj.First_Name__c = 'Dashboard';
        empObj.Last_Name__c = 'Career';
        empObj.Email__c = 'uscareerdashboard@test.com';
        empObj.Location__c = 'Denver, US';
        empObj.Department__c = 'Sales';
        empObj.Division__c = 'Manager';
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
        
        System.runAs(testUser) {
            ApexPages.StandardController sc = new ApexPages.standardController(empObj); 
            USCareerDashboardClass signupObj = new USCareerDashboardClass(sc);
            List<SelectOption> v1 = signupObj.UserList2;
            signupObj.checkops();
            signupObj.checkops2();
            signupObj.checkCert();
        	signupObj.checkLevelUp();
        	signupObj.getChartData();
        }
        Test.stopTest();
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void USCareerDashboardClass3() {
        Test.startTest();
        User testUser = new User(alias = 'u11232', email='uscareerdashboard@test.com',emailencodingkey='UTF-8', lastname='Career',division='Manager', 
                     ProfileId=[SELECT Id FROM Profile WHERE Name='Sales Manager - Business Processing' LIMIT 1].Id, Department='Sales',
                     languagelocalekey='en_US',localesidkey='en_US', country='United States',
                     timezonesidkey='America/Los_Angeles', username='uscareerdashboard@test.com', IsActive=true);                   
        insert testUser;
        insert createUsers(testUser);
        
        Employee__c empObj = new Employee__c();
        empObj.First_Name__c = 'Dashboard';
        empObj.Last_Name__c = 'Career';
        empObj.Email__c = 'uscareerdashboard@test.com';
        empObj.Location__c = 'Denver, US';
        empObj.Department__c = 'Sales';
        empObj.Division__c = 'Coaching';
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
        
        System.runAs(testUser) {
        	try {
	            ApexPages.StandardController sc = new ApexPages.standardController(empObj); 
	            USCareerDashboardClass signupObj = new USCareerDashboardClass(sc);
	            List<SelectOption> v1 = signupObj.UserList2;
	            signupObj.checkops();
	            signupObj.checkops2();
                signupObj.checkCert();
        		signupObj.checkLevelUp();
        		signupObj.getChartData();
        	} catch(Exception ex) {}
        }
    	Test.stopTest();
    }

    @isTest
    static void testDataInitialization() {
        USCareerDashboardClass.ChartData chartData = new USCareerDashboardClass.ChartData('Test', 10.0, 20.0, 30.0, 40.0, 50.0, 60, 'Manager001');
        System.assertEquals('Test', chartData.name);
        System.assertEquals(0.00, chartData.data);
        System.assertEquals(0.00, chartData.data1);
        System.assertEquals(0.00, chartData.data2);
        System.assertEquals(0.00, chartData.data3);
        System.assertEquals(0.00, chartData.data4);
        System.assertEquals(0, chartData.data5);
        System.assertEquals(1000, chartData.lowRange);
        System.assertEquals(50000, chartData.highRange);
    }

    @isTest
	static void testGetChartData() {
        User testUser = new User(alias = 'u11232', email='uscareerdashboard@test.com',emailencodingkey='UTF-8', lastname='Career',division='Manager', 
                     ProfileId=[SELECT Id FROM Profile WHERE Name='Sales Manager - Business Processing' LIMIT 1].Id, Department='Sales',
                     languagelocalekey='en_US',localesidkey='en_US', country='United States',
                     timezonesidkey='America/Los_Angeles', username='uscareerdashboard@test.com', IsActive=true);                   
        insert testUser;
        insert createUsers(testUser);

        Coaching_Log__c testCoachingLog = new Coaching_Log__c(
            Account_Executive__c = testUser.Id,
            Coaching_Date__c = Date.today(),
            ASP1__c = 50.0,
            CLOSE_RATE__c = 75.0,
            UPSELL__c = 80.0,
            BOOKINGS_QUALITY_TARGET__c = 90.0, 
            NETBOOKINGS_MTD_TARGET__c = 95.0 
        );
        insert testCoachingLog;

        USCareerDashboardClass dashboard = new USCareerDashboardClass(new ApexPages.StandardController(testUser));

        dashboard.selectedVal = testUser.Id;

        List<USCareerDashboardClass.ChartData> chartDataList = dashboard.getChartData();
    	dashboard.checkops();
	    dashboard.checkops2();
        dashboard.checkCert();
        dashboard.checkLevelUp();

        System.assertNotEquals(0, chartDataList.size());

        USCareerDashboardClass.ChartData chartData = chartDataList[0];
        System.assertEquals(null, chartData.data); 
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testCheckLevelUp() {

        User testUser = new User(alias = 'u11232', email='uscareerdashboard@test.com',emailencodingkey='UTF-8', lastname='Career',division='Manager', 
                     ProfileId=[SELECT Id FROM Profile WHERE Name='Sales Manager - Business Processing' LIMIT 1].Id, Department='Sales',
                     languagelocalekey='en_US',localesidkey='en_US', country='United States',
                     timezonesidkey='America/Los_Angeles', username='uscareerdashboard@test.com', IsActive=true);                   
        insert testUser;
        insert createUsers(testUser);

        Employee__c emp = new Employee__c(
            First_Name__c = 'Test',
            Last_Name__c = 'Employee',
            agent_level__c = 'Level 1'
        );
        insert emp;

        Agent_Level_Criteria__c levelCriteria = new Agent_Level_Criteria__c(
            Name = 'Criteria1',
            Level_Up_Qualifications__c = 'Qualification1'
        );
        insert levelCriteria;

        Test.startTest();

     	    ApexPages.StandardController sc = new ApexPages.standardController(testUser); 
	        USCareerDashboardClass signupObj = new USCareerDashboardClass(sc);
	        signupObj.checkops();
	        signupObj.checkops2();
            signupObj.checkCert();
        	signupObj.checkLevelUp();
        	signupObj.getChartData();
        Test.stopTest();
    }
}