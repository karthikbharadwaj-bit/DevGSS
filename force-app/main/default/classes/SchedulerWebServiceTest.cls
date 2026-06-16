/**************************************************************************************************
* Project Name..........: Implementation Scheduler.                                               *
* File..................: SchedulerWebServiceTest.cls                                             *
* Version...............: 1.0                                                                     *
* Created by............: Simplion Technologies                                                   *
* Created Date..........: 15-06-2013                                                              *
* Last Modified by......: Simplion Technologies                                                   *
* Last Modified Date....: 18-03-2014                                                              *
* Description...........: This is a Test class for SchedulerWebService.class                      *
**************************************************************************************************/

@IsTest
public class SchedulerWebServiceTest{
	
    /******************************************************************************
	* @Description : Controller class                                             *
	* @Params      : void                                                         *
	* @Return      : void                                                         * 
	******************************************************************************/
	public SchedulerWebServiceTest(){
		
		OrgWideEmailAddress oea = new OrgWideEmailAddress();
		oea = [SELECT Id FROM OrgWideEmailAddress LIMIT 1];
		
		BrandOrgwideEmail__c bow = new BrandOrgwideEmail__c();
		bow.Name = 'testAccount';
		bow.OrgWideEmailId__c = oea != null ? oea.Id:null;
		bow.Subject__c = 'testmail';
		insert bow;
		
	}

    /******************************************************************************
	* @Description : Method to test Buffer days.                                  *
	* @Params      : void                                                         *
	* @Return      : void                                                         * 
	******************************************************************************/
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void test_getBufferDays(){

        SchedulerWebService.getBufferDaysRequest Request = new SchedulerWebService.getBufferDaysRequest();
        SchedulerWebService.getBufferDaysResponse Response = new SchedulerWebService.getBufferDaysResponse();         

		// Instantiating class to setup test records.
		Test_Utils testRecordClass = new Test_Utils();
		
        // Creating Account
        schedulerConfiguration__c createBrand = new schedulerConfiguration__c();
        createBrand = testRecordClass.createSchedulerConfigurationRecords(new List<schedulerConfiguration__c>{new schedulerConfiguration__c()})[0];

		Test.startTest();
		
        // Testing for Brand Id null
        Request.BrandID = null;
        Request.NumberofUsers = 20;
        Response = SchedulerWebService.getBufferDays(Request);

        // Testing for Number of Users null
        Request.BrandID = 'test123';
        Request.NumberofUsers = null;
        Response = SchedulerWebService.getBufferDays(Request);

        // Testing for positive case
        Request.BrandID = 'test123';
        Request.NumberofUsers = 20;
        Response = SchedulerWebService.getBufferDays(Request);

        //Testing for Brand Id not available
        Request.BrandID = 'test1';
        Request.NumberofUsers = 2;
        Response = SchedulerWebService.getBufferDays(Request);     
        
        Test.stopTest();
    }

    /******************************************************************************
	* @Description : Method to test Fetch Event details.                          *
	* @Params      : void                                                         *
	* @Return      : void                                                         * 
	******************************************************************************/
    // Test Method 2: get Event Details ----Obtain details from existing event
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void test_getEventDetails(){

        SchedulerWebService.getEventDetailsRequest Request = new SchedulerWebService.getEventDetailsRequest();
        SchedulerWebService.getEventDetailsResponse Response = new SchedulerWebService.getEventDetailsResponse();

		// Instantiating class to setup test records.
		Test_Utils testRecordClass = new Test_Utils();
        
        /* Setting up test records */
        // Creating test User.
        User testUser1 = new User();                   
		testUser1 = testRecordClass.createUserRecord(new List<User>{new User()})[0];
        // Creating Brand
        schedulerConfiguration__c createBrand = new schedulerConfiguration__c();
        createBrand = testRecordClass.createSchedulerConfigurationRecords(new List<schedulerConfiguration__c>{new schedulerConfiguration__c()})[0];
        // Creating Resource
        Resource_Pool__c resPool = new Resource_Pool__c();
        resPool = testRecordClass.createResourcePoolRecords(new List<Resource_Pool__c>{new Resource_Pool__c()})[0];

        //Calling method to create new event.
        Event event = new Event();
        event = createEventRecord(createBrand.Brand_Id__c, resPool.Id);

		Test.startTest();
		
        //Testing for Event as null         
        Request.EventID = null;         
        Response = SchedulerWebService.getEventDetails(Request);
		
		Event ev = new Event(Customer_Email__c='ac@cc.com',CustomerId__c='12347' ,Subject='test implementation', StartDateTime=system.now().addDays(10),EndDateTime=system.now().addDays(10).addHours(1), Description='test',Preferred_Language__c='en_us',Time_Zone__c='America/LosAngeles',
                                        Appointment_Source__c='Internal Tool',Last_Name__c='test',First_Name__c='test',NumberofUser__c=5,Brand__c='7710',Implementation_Status__c='Scheduled',
                                        Type='Initial Implementation');
         TriggerHandler.BY_PASS_ACCOUNT_ON_BEFORE = true;
         TriggerHandler.BY_PASS_ACCOUNT_ON_AFTER = true;
         TriggerHandler.BY_PASS_IMPLEMENTATION_ON_BEFORE = true;
         TriggerHandler.BY_PASS_IMPLEMENTATION_ON_AFTER = true;
         insert ev;
         
         Request.EventID = ev.Id;  
         Response = SchedulerWebService.getEventDetails(Request);
        //Testing for positive case
        Request.EventID = event.id;         
        Response = SchedulerWebService.getEventDetails(Request);

        //Testing for wrong event Id
        Request.EventID = '00UQ0000003jtUZABC';
        Response = SchedulerWebService.getEventDetails(Request);

		Test.stopTest();
        eventSchedulerUtility.getiattachment('FirstName','LastName','cEmail@gmail.com', ev);
    }

    /******************************************************************************
	* @Description : Method to test Calendar Availability.                        *
	* @Params      : void                                                         *
	* @Return      : void                                                         * 
	******************************************************************************/
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void test_getAvailibility(){

        SchedulerWebService.getAvailibilityRequest Request = new SchedulerWebService.getAvailibilityRequest();
        SchedulerWebService.getAvailibilityResponse Response = new SchedulerWebService.getAvailibilityResponse();

		// Instantiating class to setup test records.
		Test_Utils testRecordClass = new Test_Utils();
        
        /* Setting up test records */
        // Creating test User.
        User testUser1 = new User();                   
		testUser1 = testRecordClass.createUserRecord(new List<User>{new User()})[0];
        // Creating Brand
        schedulerConfiguration__c createBrand = new schedulerConfiguration__c();
        createBrand = testRecordClass.createSchedulerConfigurationRecords(new List<schedulerConfiguration__c>{new schedulerConfiguration__c(Brand_Id__c='7710',Preferred_Language__c='en_US')})[0];
        // Creating Resource
        Resource_Pool__c resPool = new Resource_Pool__c();
        resPool = testRecordClass.createResourcePoolRecords(new List<Resource_Pool__c>{new Resource_Pool__c()})[0];
        resPool.Brand_Name__c = createBrand.Id;
        resPool.Dispatch_Admin__c = testUser1.Id;   
        update resPool;
        //Creating Advisor
        User testUser2 = new User();      
        testUser2 = testRecordClass.createUserRecord(new List<User>{new User()})[0];             
        
        Advisor__c advisor = new Advisor__c();
        advisor.Advisor_Name__c = testUser2.Id;
        advisor.Resource_Pool__c = resPool.Id;
        advisor.Preferred_Language__c = 'en_US';
        insert advisor; 
        
        //Creating Time Slots   
        List<Time__c> listTimeSlots = new List<Time__c>();
        //Monday    
        Time__c timeSlot1 = new Time__c();
        timeSlot1.Advisor_Name__c = advisor.id;
        listTimeSlots.add(timeSlot1);
        
        //Tuesday
        Time__c timeSlot2 = new Time__c();
        timeSlot2.Advisor_Name__c = advisor.id;
        listTimeSlots.add(timeSlot2);
        
        //Wednesday
        Time__c timeSlot3 = new Time__c();
        timeSlot3.Advisor_Name__c = advisor.id;
        listTimeSlots.add(timeSlot3);
         
        //Thursday
        Time__c timeSlot4 = new Time__c();
        timeSlot4.Advisor_Name__c = advisor.id;
        listTimeSlots.add(timeSlot4);
        
        //Friday
        Time__c timeSlot5 = new Time__c();
        timeSlot5.Advisor_Name__c = advisor.id;
        listTimeSlots.add(timeSlot5);
        
        //Saturday
        Time__c timeSlot6 = new Time__c();
        timeSlot6.Advisor_Name__c = advisor.id;
        listTimeSlots.add(timeSlot6);
        
        //Sunday
        Time__c timeSlot7 = new Time__c();
        timeSlot7.Advisor_Name__c = advisor.id;
        listTimeSlots.add(timeSlot7);
        
        
        listTimeSlots = testRecordClass.createTimeSlotRecords(listTimeSlots);

        //Calling method to create new event.
        Event event = new Event();
        event = createEventRecord(createBrand.Brand_Id__c, resPool.Id);

		Test.startTest();
		
        //Creating date - Date format : 06/20/2013      
        string strConvertedDate ;
        Datetime GMTDate = DateTime.Now();
        strConvertedDate = GMTDate.format('MM/dd/yyyy','English (United States)');
        strConvertedDate =strConvertedDate;
        
        //Testing for positive case with a valid advisor Id, and availability.
        Request.CustomerID = '1234';
        Request.BrandID= '7710'; 
        Request.NumberofUsers= 20; 
        Request.cdate = strConvertedDate;
        Request.appointmentLength = '60';
        Request.premiumSupport = false;
        Request.advisorId = testUser2.Id;
        Request.preferredLanguage='';
    	Request.timeZone = '';
        Response = SchedulerWebService.getAvailibility(Request);

        //Testing for positive case with a valid advisor Id, and availability.
        Request.CustomerID = '1234';
        Request.BrandID= '7710'; 
        Request.NumberofUsers= 20; 
        Request.cdate = strConvertedDate;
        Request.appointmentLength = '60';
        Request.premiumSupport = false;
        Request.advisorId = testUser2.Id;
        Request.preferredLanguage='en_US';
    	Request.timeZone = 'America/LosAngeles';
        Response = SchedulerWebService.getAvailibility(Request);
        
        //Testing for positive case with a valid advisor Id, and no availability.
        Request.CustomerID = '1234';
        Request.BrandID= 'test123'; 
        Request.NumberofUsers= 20; 
        Request.cdate = strConvertedDate;
        Request.appointmentLength = '60';
        Request.premiumSupport = false;
        Request.advisorId = testUser1.Id;
        Request.preferredLanguage='en_US';
    	Request.timeZone = 'America/LosAngeles';
        Response = SchedulerWebService.getAvailibility(Request);
        
        //Testing for positive case with blank advisor Id.
        Request.CustomerID = '1234';
        Request.BrandID= 'test123'; 
        Request.NumberofUsers= 20; 
        Request.cdate = strConvertedDate;
        Request.appointmentLength = '60';
        Request.premiumSupport = false;
        Request.advisorId = null;
        Request.preferredLanguage='en_US';
    	Request.timeZone = 'America/LosAngeles';
        Response = SchedulerWebService.getAvailibility(Request);

        // Testing for Brand Id null
        Request.CustomerID = '1234';
        Request.BrandID= null; 
        Request.NumberofUsers= 20; 
        Request.cdate = strConvertedDate;
        Request.appointmentLength = '60';
        Request.premiumSupport = false;   
        Request.preferredLanguage='en_US';
    	Request.timeZone = 'America/LosAngeles'; 
        Response = SchedulerWebService.getAvailibility(Request);

        //Testing for Number of Users null
        Request.CustomerID = '1234';
        Request.BrandID= 'test123'; 
        Request.NumberofUsers= null; 
        Request.cdate = strConvertedDate ; 
        Request.appointmentLength = '60';
        Request.premiumSupport = false;      
        Request.preferredLanguage='en_US';
    	Request.timeZone = 'America/LosAngeles';
        Response = SchedulerWebService.getAvailibility(Request);

        //Testing for Brand Id not existing       
        Request.CustomerID = '1234';
        Request.BrandID= 'test1'; 
        Request.NumberofUsers= 20; 
        Request.cdate = strConvertedDate;    
        Request.appointmentLength = '60';
        Request.premiumSupport = false;     
        Request.preferredLanguage='en_US';
    	Request.timeZone = 'America/LosAngeles'; 
        Response = SchedulerWebService.getAvailibility(Request);

        //Testing for no resource pool present
        Request.CustomerID = '1234';
        Request.BrandID= 'test123'; 
        Request.NumberofUsers= 15; 
        Request.cdate = strConvertedDate;        
        Request.appointmentLength = '60';
        Request.premiumSupport = false;  
        Request.preferredLanguage='en_US';
    	Request.timeZone = 'America/LosAngeles';
        Response = SchedulerWebService.getAvailibility(Request);

        //Testing for date null
        Request.CustomerID = '005XXXXXXXXXXXXXXX';
        Request.BrandID= 'test123'; 
        Request.NumberofUsers= 15; 
        Request.cdate = null;    
        Request.appointmentLength = '60';
        Request.premiumSupport = false;      
        Request.preferredLanguage='en_US';
    	Request.timeZone = 'America/LosAngeles';
        Response = SchedulerWebService.getAvailibility(Request);

        //Testing for customer id null
        Request.CustomerID = '1234';
        Request.BrandID = 'test123'; 
        Request.NumberofUsers = 15; 
        Request.cdate = strConvertedDate;
        Request.appointmentLength = null;
        Request.premiumSupport = false;        
        Request.preferredLanguage='en_US';
    	Request.timeZone = 'America/LosAngeles';  
        Response = SchedulerWebService.getAvailibility(Request);
        
        //Testing for appointment length null
        Request.CustomerID = null;
        Request.BrandID= 'test123'; 
        Request.NumberofUsers= 15; 
        Request.cdate = strConvertedDate;
        Request.appointmentLength = '60';
        Request.premiumSupport = false;        
        Request.preferredLanguage='en_US';
    	Request.timeZone = 'America/LosAngeles';  
        Response = SchedulerWebService.getAvailibility(Request);
        
        Test.stopTest();
    }

    /******************************************************************************
	* @Description : Method to test Create event and save the above parameters on *
	*				 that event; remove used resource from relevant               *
	*				 resource pool-Email event Contact a Confirmation.            *
	* @Params      : void                                                         *
	* @Return      : void                                                         * 
	******************************************************************************/
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void test_scheduleEventEqual(){
        SchedulerWebService.scheduleEventRequest Request = new SchedulerWebService.scheduleEventRequest();
        SchedulerWebService.scheduleEventResponse Response = new SchedulerWebService.scheduleEventResponse();
        string strConvertedDate ;
        string strDate;
        Datetime GMTDate = DateTime.Now();
        strDate = GMTDate.format('MM/dd/yyyy','English (United States)');
		
        EmailTemplate eTemp = new EmailTemplate();
        eTemp.Name = 'Test';
        eTemp.folderId = [SELECT AccessType ,Id , Name, NamespacePrefix,Type FROM Folder WHERE Name=:'Support OA Emails' LIMIT 1].id;
        eTemp.Subject = '#datetime# - Test Template';
        eTemp.Encoding = 'UTF-8';
        eTemp.TemplateType = 'Custom';
        eTemp.DeveloperName = 'Test';
        eTemp.IsActive = true;
        eTemp.HtmlValue = '#datetime#,#supportnumber#,#eventid#';
        eTemp.Body = '#datetime#,#supportnumber#,#eventid#';
        System.runAs(new User(Id = Userinfo.getUserId())) {
            insert eTemp;
        }


		// Instantiating class to setup test records.
		Test_Utils testRecordClass = new Test_Utils();
        
        /* Setting up test records */
        // Creating test User.
        User testUser1 = new User();                   
		testUser1 = testRecordClass.createUserRecord(new List<User>{new User()})[0];
        // Creating Brand
        schedulerConfiguration__c createBrand = new schedulerConfiguration__c();
        createBrand.Brand_Id__c = '1010';
        createBrand.Name = 'TestBrand';
        createBrand.Preferred_Language__c = 'en_US';
        createBrand.Confirmation_Email_Template_Name__c = eTemp.id;
        createBrand = testRecordClass.createSchedulerConfigurationRecords(new List<schedulerConfiguration__c>{createBrand})[0];
        
        // Creating Account Record.
		Account act = testRecordClass.createAccountRecord(new List<Account>{new Account(RC_USER_ID__c='12345', RC_Brand__c = 'TestBrand')})[0];
		
		testRecordClass.createImplementationRecords(new List<Implementation__c>{new Implementation__c(Implementation_Status_2__c = 'Completed', Account__c = act.Id)});
        // Creating Resource
        Resource_Pool__c resPool = new Resource_Pool__c();
        system.debug('#### Test Class createBrand - '+createBrand);
        resPool.Brand_Name__c = createBrand.Id;
        resPool.Dispatch_Admin__c = testUser1.Id;
        resPool.Preferred_Language__c = 'en_US';
        resPool = testRecordClass.createResourcePoolRecords(new List<Resource_Pool__c>{resPool})[0];
		
		//Creating Advisor
        User testUser2 = new User();      
        testUser2 = testRecordClass.createUserRecord(new List<User>{new User()})[0];             
        
        Advisor__c advisor = new Advisor__c();
        advisor.Advisor_Name__c = testUser2.Id;
        advisor.Resource_Pool__c = resPool.Id;
        advisor.Preferred_Language__c = 'en_US';
        insert advisor; 
        
        //Creating Time Slots    
        List<Time__c> listTimeSlots = new List<Time__c>();
        //Monday    
        Time__c timeSlot1 = new Time__c();
        timeSlot1.Advisor_Name__c = advisor.id;
        timeSlot1.Day__c = 'Monday';
        timeSlot1.Start_Time__c = '00:00';
        timeSlot1.End_Time__c ='23:59';
        timeSlot1.availableFor__c = 'Initial Implementation';
        listTimeSlots.add(timeSlot1);
          
        //Tuesday
        Time__c timeSlot2 = new Time__c();
        timeSlot2.Advisor_Name__c = advisor.id;
        timeSlot2.Day__c = 'Tuesday';
        timeSlot2.Start_Time__c = '00:00';
        timeSlot2.End_Time__c = '23:59';
        timeSlot2.availableFor__c = 'Initial Implementation';
        listTimeSlots.add(timeSlot2);
        
        //Wednesday
        Time__c timeSlot3 = new Time__c();
        timeSlot3.Advisor_Name__c = advisor.id;
        timeSlot3.Day__c = 'Wednesday';
        timeSlot3.Start_Time__c = '00:00';
        timeSlot3.End_Time__c = '23:59';
        timeSlot3.availableFor__c = 'Initial Implementation';
        listTimeSlots.add(timeSlot3);
         
        //Thursday
        Time__c timeSlot4 = new Time__c();
        timeSlot4.Advisor_Name__c = advisor.id;
        timeSlot4.Day__c = 'Thursday';
        timeSlot4.Start_Time__c = '00:00';
        timeSlot4.End_Time__c = '23:59';
        timeSlot4.availableFor__c = 'Initial Implementation';
        listTimeSlots.add(timeSlot4);
        
        //Friday
        Time__c timeSlot5 = new Time__c();
        timeSlot5.Advisor_Name__c = advisor.id;
        timeSlot5.Day__c = 'Friday';
        timeSlot5.Start_Time__c = '00:00';
        timeSlot5.End_Time__c = '23:59';
        timeSlot5.availableFor__c = 'Initial Implementation';
        listTimeSlots.add(timeSlot5);
        
        //Saturday
        Time__c timeSlot6 = new Time__c();
        timeSlot6.Advisor_Name__c = advisor.id;
        timeSlot6.Day__c = 'Saturday';
        timeSlot6.Start_Time__c = '00:00';
        timeSlot6.End_Time__c = '23:59';
        timeSlot6.availableFor__c = 'Initial Implementation';
        listTimeSlots.add(timeSlot6);
        
        //Sunday
        Time__c timeSlot7 = new Time__c();
        timeSlot7.Advisor_Name__c = advisor.id;
        timeSlot7.Day__c = 'Sunday';
        timeSlot7.Start_Time__c = '00:00';
        timeSlot7.End_Time__c = '23:59';
        timeSlot7.availableFor__c = 'Initial Implementation';
        listTimeSlots.add(timeSlot7);
          
        insert listTimeSlots;  
		system.debug('#### listTimeSlots - '+listTimeSlots);
		
		Test.startTest();
		
		Event ev = new Event(Customer_Email__c='ac@cc.com',CustomerId__c='12347' ,Subject='test implementation', StartDateTime=system.now().addDays(10),EndDateTime=system.now().addDays(10).addHours(1), Description='test',Preferred_Language__c='en_us',Time_Zone__c='America/LosAngeles',
                                        Appointment_Source__c='Internal Tool',Last_Name__c='test',First_Name__c='test',NumberofUser__c=5,Brand__c='7710',Implementation_Status__c='Scheduled',
                                        Type='Initial Implementation');
         TriggerHandler.BY_PASS_ACCOUNT_ON_BEFORE = true;
         TriggerHandler.BY_PASS_ACCOUNT_ON_AFTER = true;
         TriggerHandler.BY_PASS_IMPLEMENTATION_ON_BEFORE = true;
         TriggerHandler.BY_PASS_IMPLEMENTATION_ON_AFTER = true;
         insert ev;
         
        // Checking for positive case, with valid advisor Id.
        strConvertedDate = strDate+' '+'08:00 AM';
        Request.cdatetime = strConvertedDate ;
        Request.BrandID = '7710'; 
        Request.NumberofUsers = 20;
        Request.CustomerId = '12347';
        Request.firstName = 'test1';
        Request.lastname = 'test2';
        Request.Email = 'test@test.com';
        Request.Notes = 'This is a test event'; 
        Request.appointmentLength = '60';
        Request.premiumSupport = false;
        Request.advisorId = null;
        Request.preferredLanguage='en_US';
    	Request.timeZone = 'America/LosAngeles';
        Response = SchedulerWebService.scheduleEvent(Request); 
        
        
        
        
        Request.cdatetime = strDate+' '+'09:00 AM';
		Request.advisorId = testUser2.Id;
		Response = SchedulerWebService.scheduleEvent(Request); 
        
        Request.cdatetime = strDate+' '+'10:00 AM';
        Request.advisorId = testUser1.Id;
        Response = SchedulerWebService.scheduleEvent(Request); 
        
        Request.cdatetime = strDate+' '+'11:00 AM';
        Request.advisorId = testUser1.Id;
        Request.NumberofUsers = 10;
        Response = SchedulerWebService.scheduleEvent(Request); 
        
		system.debug('#### sucess_code - '+Response.sucess_code);
        system.debug('#### error_code - '+Response.error_code);    

        // Testing for available time slot already booked
        strConvertedDate =strDate+' '+'08:00 AM';
        Request.cdatetime=strConvertedDate ;
        Request.BrandID = '1010'; 
        Request.NumberofUsers= 20;
        Request.CustomerId= '1111';
        Request.firstName = 'test1';
        Request.lastname = 'test2';
        Request.Email = 'test@test.com';
        Request.Notes = 'This is a test event'; 
        Request.appointmentLength = '60';
        Request.premiumSupport = false;      
        Request.preferredLanguage='en_US';
    	Request.timeZone = 'America/LosAngeles';   
        Response = SchedulerWebService.scheduleEvent(Request);   
        
        system.debug('#### sucess_code - '+Response.sucess_code);
        system.debug('#### error_code - '+Response.error_code);    

        //for criteria '>' 
        resPool.clear();
        resPool.Brand_Name__c = createBrand.Id;
        resPool.Dispatch_Admin__c = testUser1.Id;
        resPool.Criteria__c = '>';
        resPool = testRecordClass.createResourcePoolRecords(new List<Resource_Pool__c>{resPool})[0];

        //Creating Advisor
        advisor.clear();
        advisor.Advisor_Name__c = testUser2.id;
        advisor.Resource_Pool__c = resPool.id;
        insert advisor;
        
        //Creating Time Slots
        List<Time__c> listTime3 = new List<Time__c>();
        //Monday    
        timeSlot1.clear();
        timeSlot1.Advisor_Name__c = advisor.id;
        timeSlot1.Day__c = 'Monday';
        timeSlot1.Start_Time__c = '05:00';
        timeSlot1.End_Time__c = '17:00';
        listTime3.add(timeSlot1);

        //Tuesday
        timeSlot2.clear();
        timeSlot2.Advisor_Name__c = advisor.id;
        timeSlot2.Day__c = 'Tuesday';
        timeSlot2.Start_Time__c = '05:00';
        timeSlot2.End_Time__c = '17:00';
        listTime3.add(timeSlot2);
        
        //Wednesday
        timeSlot3.clear();
        timeSlot3.Advisor_Name__c = advisor.id;
        timeSlot3.Day__c = 'Wednesday';
        timeSlot3.Start_Time__c = '05:00';
        timeSlot3.End_Time__c = '17:00';
        listTime3.add(timeSlot3);
         
        //Thursday
        timeSlot4.clear();
        timeSlot4.Advisor_Name__c = advisor.id;
        timeSlot4.Day__c = 'Thursday';
        timeSlot4.Start_Time__c = '05:00';
        timeSlot4.End_Time__c = '17:00';
        listTime3.add(timeSlot4);
        
        //Friday
        timeSlot5.clear();
        timeSlot5.Advisor_Name__c = advisor.id;
        timeSlot5.Day__c = 'Friday';
        timeSlot5.Start_Time__c = '05:00';
        timeSlot5.End_Time__c = '17:00';
        listTime3.add(timeSlot5);
		
        //Saturday
        timeSlot6.clear();
        timeSlot6.Advisor_Name__c = advisor.id;
        timeSlot6.Day__c = 'Saturday';
        timeSlot6.Start_Time__c = '05:00';
        timeSlot6.End_Time__c = '17:00';
        listTime3.add(timeSlot6);
        
        //Sunday
        timeSlot7.clear();
        timeSlot7.Advisor_Name__c = advisor.id;
        timeSlot7.Day__c = 'Sunday';
        timeSlot7.Start_Time__c = '05:00';
        timeSlot7.End_Time__c = '17:00';
        listTime3.add(timeSlot7);

       insert listTime3;// = testRecordClass.createTimeSlotRecords(listTime3); 
        
        strConvertedDate =strDate+' '+'10:00 AM';
        Request.cdatetime=strConvertedDate;
        Request.BrandID= '1010'; 
        Request.NumberofUsers= 25;
        Request.CustomerId= '1111';
        Request.firstName = 'test1';
        Request.lastname = 'test2';
        Request.Email = 'test@test.com';
        Request.Notes = 'This is a test event';    
        Request.appointmentLength = '60';
        Request.premiumSupport = false;  
        Request.preferredLanguage='en_US';
    	Request.timeZone = 'America/LosAngeles';    
        Response = SchedulerWebService.scheduleEvent(Request);         
        
        system.debug('#### sucess_code - '+Response.sucess_code);
        system.debug('#### error_code - '+Response.error_code); 

        //Testing for null date-time
        Request.cdatetime = null;
        Request.BrandID= '1010'; 
        Request.NumberofUsers= 20;
        Request.CustomerId= '1111';
        Request.firstName = 'test1';
        Request.lastname = 'test2';
        Request.Email = 'test@test.com';
        Request.Notes = 'This is a test event';
        Request.appointmentLength = '60';
        Request.premiumSupport = false;
        Request.preferredLanguage='en_US';
    	Request.timeZone = 'America/LosAngeles';
        Response = SchedulerWebService.scheduleEvent(Request);       
        
        system.debug('#### sucess_code - '+Response.sucess_code);
        system.debug('#### error_code - '+Response.error_code); 

        //Testing for null brand id
        Request.cdatetime = strConvertedDate ;
        Request.BrandID= null; 
        Request.NumberofUsers= 20;
        Request.CustomerId= '1111';
        Request.firstName = 'test1';
        Request.lastname = 'test2';
        Request.Email = 'test@test.com';
        Request.Notes = 'This is a test event';
        Request.appointmentLength = '60';
        Request.premiumSupport = false;
        Request.preferredLanguage='en_US';
    	Request.timeZone = 'America/LosAngeles';
        Response = SchedulerWebService.scheduleEvent(Request);  
        
        system.debug('#### sucess_code - '+Response.sucess_code);
        system.debug('#### error_code - '+Response.error_code);       

        // Testing for null first name  
        Request.cdatetime = strConvertedDate;
        Request.BrandID= '1010'; 
        Request.NumberofUsers= 20;
        Request.CustomerId= '1111';
        Request.firstName = null;
        Request.lastname = 'test2';
        Request.Email = 'test@test.com';
        Request.Notes = 'This is a test event';
        Request.appointmentLength = '60';
        Request.premiumSupport = false;
        Request.preferredLanguage='en_US';
    	Request.timeZone = 'America/LosAngeles';
        Response = SchedulerWebService.scheduleEvent(Request);       
        
        system.debug('#### sucess_code - '+Response.sucess_code);
        system.debug('#### error_code - '+Response.error_code);  

        // Testing for null last name
        Request.cdatetime = strConvertedDate ;
        Request.BrandID= '1010'; 
        Request.NumberofUsers= 20;
        Request.CustomerId= '1111';
        Request.firstName = 'test1';
        Request.lastname = null;
        Request.Email = 'test@test.com';
        Request.Notes = 'This is a test event';
        Request.appointmentLength = '60';
        Request.premiumSupport = false;
        Request.preferredLanguage='en_US';
    	Request.timeZone = 'America/LosAngeles';
        Response = SchedulerWebService.scheduleEvent(Request);         
        
        system.debug('#### sucess_code - '+Response.sucess_code);
        system.debug('#### error_code - '+Response.error_code); 

        //Testing for null email
        Request.cdatetime =strConvertedDate ;
        Request.BrandID= '1010'; 
        Request.NumberofUsers= 20;
        Request.CustomerId= '1111';
        Request.firstName = 'test1';
        Request.lastname = 'test2';
        Request.Email = null;
        Request.Notes = 'This is a test event';
        Request.appointmentLength = '60';
        Request.premiumSupport = false;
        Request.preferredLanguage='en_US';
    	Request.timeZone = 'America/LosAngeles';
        Response = SchedulerWebService.scheduleEvent(Request);  
        
        system.debug('#### sucess_code - '+Response.sucess_code);
        system.debug('#### error_code - '+Response.error_code);       

        //Testing for null notes
        Request.cdatetime = strConvertedDate ;
        Request.BrandID= '1010'; 
        Request.NumberofUsers= 20;
        Request.CustomerId= '1111';
        Request.firstName = 'test1';
        Request.lastname = 'test2';
        Request.Email = 'test@test.com';
        Request.Notes = null;
        Request.appointmentLength = '60';
        Request.premiumSupport = false;
        Request.preferredLanguage='en_US';
    	Request.timeZone = 'America/LosAngeles';
        Response = SchedulerWebService.scheduleEvent(Request);      
        
        system.debug('#### sucess_code - '+Response.sucess_code);
        system.debug('#### error_code - '+Response.error_code);    

        //Testing if number of users is null
        Request.cdatetime=strConvertedDate ;
        Request.BrandID= '1010'; 
        Request.NumberofUsers= null;
        Request.CustomerId= '1111';
        Request.firstName = 'test1';
        Request.lastname = 'test2';
        Request.Email = 'test@test.com';
        Request.Notes = 'This is a test event';      
        Request.appointmentLength = '60';
        Request.premiumSupport = false;  
        Request.preferredLanguage='en_US';
    	Request.timeZone = 'America/LosAngeles';  
        Response = SchedulerWebService.scheduleEvent(Request);    
        
        system.debug('#### sucess_code - '+Response.sucess_code);
        system.debug('#### error_code - '+Response.error_code);      

        //Testing if the customer id is null
        Request.cdatetime=strConvertedDate ;
        Request.BrandID= '1010'; 
        Request.NumberofUsers= 15;
        Request.CustomerId= null;
        Request.firstName = 'test1';
        Request.lastname = 'test2';
        Request.Email = 'test@test.com';
        Request.Notes = 'This is a test event';     
        Request.appointmentLength = '60';
        Request.premiumSupport = false;   
        Request.preferredLanguage='en_US';
    	Request.timeZone = 'America/LosAngeles';  
        Response = SchedulerWebService.scheduleEvent(Request);   
        
        system.debug('#### sucess_code - '+Response.sucess_code);
        system.debug('#### error_code - '+Response.error_code);       

        // Testing if appointment length is null
        Request.cdatetime=strConvertedDate ;
        Request.BrandID= '1010'; 
        Request.NumberofUsers= 20;
        Request.CustomerId= '1111';
        Request.firstName = 'test1';
        Request.lastname = 'test2';
        Request.Email = 'test@test.com';
        Request.Notes = 'This is a test event';  
        Request.appointmentLength = null;
        Request.premiumSupport = false; 
        Request.preferredLanguage='en_US';
    	Request.timeZone = 'America/LosAngeles';       
        Response = SchedulerWebService.scheduleEvent(Request);     
        
        system.debug('#### sucess_code - '+Response.sucess_code);
        system.debug('#### error_code - '+Response.error_code);     
        
        // Testing if Brand Id doesn't exists
        Request.cdatetime=strConvertedDate ;
        Request.BrandID= '1011'; 
        Request.NumberofUsers= 20;
        Request.CustomerId= '1111';
        Request.firstName = 'test1';
        Request.lastname = 'test2';
        Request.Email = 'test@test.com';
        Request.Notes = 'This is a test event';  
        Request.appointmentLength = '60';
        Request.premiumSupport = false;      
        Request.preferredLanguage='en_US';
    	Request.timeZone = 'America/LosAngeles';  
        Response = SchedulerWebService.scheduleEvent(Request);        
        
        system.debug('#### sucess_code - '+Response.sucess_code);
        system.debug('#### error_code - '+Response.error_code); 
        
        Test.stoptest();                            
    }
    
    
	/******************************************************************************
	* @Description : Method to test Create event and save the above parameters on *
	*				 that event; remove used resource from relevant               *
	*				 resource pool-Email event Contact a Confirmation.            *
	* @Params      : void                                                         *
	* @Return      : void                                                         * 
	******************************************************************************/
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void scheduleEventGreaterEqual(){
    	
    	SchedulerWebService.scheduleEventRequest Request = new SchedulerWebService.scheduleEventRequest();
        SchedulerWebService.scheduleEventResponse Response = new SchedulerWebService.scheduleEventResponse();
        string strConvertedDate ;
        string strDate;
        Datetime GMTDate = DateTime.Now();
        strDate = GMTDate.format('MM/dd/yyyy','English (United States)');
		
        EmailTemplate eTemp = new EmailTemplate();
        eTemp.Name = 'Test';
        eTemp.folderId = [SELECT AccessType ,Id , Name, NamespacePrefix,Type FROM Folder WHERE Name=:'Support OA Emails' LIMIT 1].id;
        eTemp.Subject = '#datetime# - Test Template';
        eTemp.Encoding = 'UTF-8';
        eTemp.TemplateType = 'Custom';
        eTemp.DeveloperName = 'Test';
        eTemp.IsActive = true;
        eTemp.HtmlValue = '#datetime#,#supportnumber#,#eventid#';
        eTemp.Body = '#datetime#,#supportnumber#,#eventid#';
        System.runAs(new User(Id = Userinfo.getUserId())) {
            insert eTemp;
        }


		// Instantiating class to setup test records.
		Test_Utils testRecordClass = new Test_Utils();
        
        /* Setting up test records */
        // Creating test User.
        User testUser1 = new User();                   
		testUser1 = testRecordClass.createUserRecord(new List<User>{new User()})[0];
        // Creating Brand
        schedulerConfiguration__c createBrand = new schedulerConfiguration__c();
        createBrand.Brand_Id__c = '1010';
        createBrand.Confirmation_Email_Template_Name__c = eTemp.id;
        createBrand = testRecordClass.createSchedulerConfigurationRecords(new List<schedulerConfiguration__c>{createBrand})[0];
    	
    	// Resource Pool for criteria '>=' 
        Resource_Pool__c resPool = new Resource_Pool__c();
        resPool.Brand_Name__c = createBrand.Id;
        resPool.Dispatch_Admin__c = testUser1.Id;
        resPool.Criteria__c = '>=';
        resPool = testRecordClass.createResourcePoolRecords(new List<Resource_Pool__c>{resPool})[0];

        //Creating Advisor
        Advisor__c advisor = new Advisor__c();
        advisor.Advisor_Name__c = testUser1.id;
        advisor.Resource_Pool__c = resPool.id;
        advisor.Preferred_Language__c = 'en_US';
        insert advisor; 
        
        //Creating Time Slots   
        List<Time__c> listTime2 = new List<Time__c>();
        //Monday    
        Time__c timeSlot1 = new Time__c();
        timeSlot1.Advisor_Name__c = advisor.id;
        timeSlot1.Day__c = 'Monday';
        timeSlot1.Start_Time__c = '05:00';
        timeSlot1.End_Time__c = '17:00';
        listTime2.add(timeSlot1);
          
        //Tuesday
        Time__c timeSlot2 = new Time__c();
        timeSlot2.Advisor_Name__c = advisor.id;
        timeSlot2.Day__c = 'Tuesday';
        timeSlot2.Start_Time__c = '05:00';
        timeSlot2.End_Time__c = '17:00';
        listTime2.add(timeSlot2);
        
        //Wednesday
        Time__c timeSlot3 = new Time__c();
        timeSlot3.Advisor_Name__c = advisor.id;
        timeSlot3.Day__c = 'Wednesday';
        timeSlot3.Start_Time__c = '05:00';
        timeSlot3.End_Time__c = '17:00';
        listTime2.add(timeSlot3);
         
        //Thursday
        Time__c timeSlot4 = new Time__c();
        timeSlot4.Advisor_Name__c = advisor.id;
        timeSlot4.Day__c = 'Thursday';
        timeSlot4.Start_Time__c = '05:00';
        timeSlot4.End_Time__c = '17:00';
        listTime2.add(timeSlot4);
        
        //Friday
        Time__c timeSlot5 = new Time__c();
        timeSlot5.Advisor_Name__c = advisor.id;
        timeSlot5.Day__c = 'Friday';
        timeSlot5.Start_Time__c = '05:00';
        timeSlot5.End_Time__c = '17:00';
        listTime2.add(timeSlot5);
        
        //Saturday
        Time__c timeSlot6 = new Time__c();
        timeSlot6.Advisor_Name__c = advisor.id;
        timeSlot6.Day__c = 'Saturday';
        timeSlot6.Start_Time__c = '05:00';
        timeSlot6.End_Time__c = '17:00';
        listTime2.add(timeSlot6);
        
        //Sunday
        Time__c timeSlot7 = new Time__c();
        timeSlot7.Advisor_Name__c = advisor.id;
        timeSlot7.Day__c = 'Sunday';
        timeSlot7.Start_Time__c = '05:00';
        timeSlot7.End_Time__c = '17:00';
        listTime2.add(timeSlot7);  
        
        insert listTime2;
        Test.startTest();
        
	        strConvertedDate =strDate+' '+'09:00 AM';
	        Request.cdatetime=strConvertedDate ;
	        Request.BrandID= '1010'; 
	        Request.NumberofUsers= 20;
	        Request.CustomerId= '1111';
	        Request.firstName = 'test1';
	        Request.lastname = 'test2';
	        Request.Email = 'test@test.com';
	        Request.Notes = 'This is a test event';  
	        Request.appointmentLength = '60';
	        Request.premiumSupport = false;  
	        Request.preferredLanguage='en_US';
    		Request.timeZone = 'America/LosAngeles';      
	        Response = SchedulerWebService.scheduleEvent(Request); 
	        
	        system.debug('#### sucess_code - '+Response.sucess_code);
	        system.debug('#### error_code - '+Response.error_code);
        
        Test.stopTest();
    }
    
    /******************************************************************************
	* @Description : Method to test Create event and save the above parameters on *
	*				 that event; remove used resource from relevant               *
	*				 resource pool-Email event Contact a Confirmation.            *
	* @Params      : void                                                         *
	* @Return      : void                                                         * 
	******************************************************************************/
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void scheduleEventLessEquals(){
    	
    	SchedulerWebService.scheduleEventRequest Request = new SchedulerWebService.scheduleEventRequest();
        SchedulerWebService.scheduleEventResponse Response = new SchedulerWebService.scheduleEventResponse();
        string strConvertedDate ;
        string strDate;
        Datetime GMTDate = DateTime.Now();
        strDate = GMTDate.format('MM/dd/yyyy','English (United States)');
		
        EmailTemplate eTemp = new EmailTemplate();
        eTemp.Name = 'Test';
        eTemp.folderId = [SELECT AccessType ,Id , Name, NamespacePrefix,Type FROM Folder WHERE Name=:'Support OA Emails' LIMIT 1].id;
        eTemp.Subject = '#datetime# - Test Template';
        eTemp.Encoding = 'UTF-8';
        eTemp.TemplateType = 'Custom';
        eTemp.DeveloperName = 'Test';
        eTemp.IsActive = true;
        eTemp.HtmlValue = '#datetime#,#supportnumber#,#eventid#';
        eTemp.Body = '#datetime#,#supportnumber#,#eventid#';
        System.runAs(new User(Id = Userinfo.getUserId())) {
            insert eTemp;
        }


		// Instantiating class to setup test records.
		Test_Utils testRecordClass = new Test_Utils();
        
        /* Setting up test records */
        // Creating test User.
        User testUser1 = new User();                   
		testUser1 = testRecordClass.createUserRecord(new List<User>{new User()})[0];
        // Creating Brand
        schedulerConfiguration__c createBrand = new schedulerConfiguration__c();
        createBrand.Brand_Id__c = '1010';
        createBrand.Confirmation_Email_Template_Name__c = eTemp.id;
        createBrand = testRecordClass.createSchedulerConfigurationRecords(new List<schedulerConfiguration__c>{createBrand})[0];
    	
		//Resource Pool for criteria '<=' 
        Resource_Pool__c resPool = new Resource_Pool__c();
        resPool.Brand_Name__c = createBrand.Id;
        resPool.Dispatch_Admin__c = testUser1.Id;
        resPool.Criteria__c = '<=';
        resPool = testRecordClass.createResourcePoolRecords(new List<Resource_Pool__c>{resPool})[0];

        //Creating Advisor
        Advisor__c advisor = new Advisor__c();
        advisor.Advisor_Name__c = testUser1.id;
        advisor.Resource_Pool__c = resPool.id;
        advisor.Preferred_Language__c = 'en_US';
        insert advisor;
        
        //Creating Time Slots   
        List<Time__c> listTime4 = new List<Time__c>();
        //Monday    
        Time__c timeSlot1 = new Time__c();
        timeSlot1.Advisor_Name__c = advisor.id;
        timeSlot1.Day__c = 'Monday';
        timeSlot1.Start_Time__c = '05:00';
        timeSlot1.End_Time__c = '17:00';
        listTime4.add(timeSlot1);
          
        //Tuesday
        Time__c timeSlot2 = new Time__c();
        timeSlot2.Advisor_Name__c = advisor.id;
        timeSlot2.Day__c = 'Tuesday';
        timeSlot2.Start_Time__c = '05:00';
        timeSlot2.End_Time__c = '17:00';
        listTime4.add(timeSlot2);
        
        //Wednesday
        Time__c timeSlot3 = new Time__c();
        timeSlot3.Advisor_Name__c = advisor.id;
        timeSlot3.Day__c = 'Wednesday';
        timeSlot3.Start_Time__c = '05:00';
        timeSlot3.End_Time__c = '17:00';
        listTime4.add(timeSlot3);
         
        //Thursday
        Time__c timeSlot4 = new Time__c();
        timeSlot4.Advisor_Name__c = advisor.id;
        timeSlot4.Day__c = 'Thursday';
        timeSlot4.Start_Time__c = '05:00';
        timeSlot4.End_Time__c = '17:00';
        listTime4.add(timeSlot4);
        
        //Friday
        Time__c timeSlot5 = new Time__c();
        timeSlot5.Advisor_Name__c = advisor.id;
        timeSlot5.Day__c = 'Friday';
        timeSlot5.Start_Time__c = '05:00';
        timeSlot5.End_Time__c = '17:00';
        listTime4.add(timeSlot5);
        
        //Saturday
        Time__c timeSlot6 = new Time__c();
        timeSlot6.Advisor_Name__c = advisor.id;
        timeSlot6.Day__c = 'Saturday';
        timeSlot6.Start_Time__c = '05:00';
        timeSlot6.End_Time__c = '17:00';
        listTime4.add(timeSlot6);
        
        //Sunday
        Time__c timeSlot7 = new Time__c();
        timeSlot7.Advisor_Name__c = advisor.id;
        timeSlot7.Day__c = 'Sunday';
        timeSlot7.Start_Time__c = '05:00';
        timeSlot7.End_Time__c = '17:00';
        listTime4.add(timeSlot7);
        
        //listTime4 = testRecordClass.createTimeSlotRecords(listTime4); 
        insert listTime4;
		Test.startTest();	     
	        strConvertedDate =strDate+' '+'01:00 PM';
	        Request.cdatetime=strConvertedDate ;
	        Request.BrandID= '1010'; 
	        Request.NumberofUsers= 20;
	        Request.CustomerId= '1111';
	        Request.firstName = 'test1';
	        Request.lastname = 'test2';
	        Request.Email = 'test@test.com';
	        Request.Notes = 'This is a test event';   
	        Request.appointmentLength = '60';
	        Request.premiumSupport = false;   
	        Request.preferredLanguage='en_US';
    		Request.timeZone = 'America/LosAngeles';    
	        Response = SchedulerWebService.scheduleEvent(Request);       
	        
	        system.debug('#### sucess_code - '+Response.sucess_code);
	        system.debug('#### error_code - '+Response.error_code);  
    	Test.stopTest();
    }
    
 	/******************************************************************************
	* @Description : Method to test Create event and save the above parameters on *
	*				 that event; remove used resource from relevant               *
	*				 resource pool-Email event Contact a Confirmation.            *
	* @Params      : void                                                         *
	* @Return      : void                                                         * 
	******************************************************************************/
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void scheduleEventLess(){   
    
    	SchedulerWebService.scheduleEventRequest Request = new SchedulerWebService.scheduleEventRequest();
        SchedulerWebService.scheduleEventResponse Response = new SchedulerWebService.scheduleEventResponse();
        string strConvertedDate ;
        string strDate;
        Datetime GMTDate = DateTime.Now();
        strDate = GMTDate.format('MM/dd/yyyy','English (United States)');
		
        EmailTemplate eTemp = new EmailTemplate();
        eTemp.Name = 'Test';
        eTemp.folderId = [SELECT AccessType ,Id , Name, NamespacePrefix,Type FROM Folder WHERE Name=:'Support OA Emails' LIMIT 1].id;
        eTemp.Subject = '#datetime# - Test Template';
        eTemp.Encoding = 'UTF-8';
        eTemp.TemplateType = 'Custom';
        eTemp.DeveloperName = 'Test';
        eTemp.IsActive = true;
        eTemp.HtmlValue = '#datetime#,#supportnumber#,#eventid#';
        eTemp.Body = '#datetime#,#supportnumber#,#eventid#';
        System.runAs(new User(Id = Userinfo.getUserId())) {
            insert eTemp;
        }


		// Instantiating class to setup test records.
		Test_Utils testRecordClass = new Test_Utils();
        
        /* Setting up test records */
        // Creating test User.
        User testUser1 = new User();                   
		testUser1 = testRecordClass.createUserRecord(new List<User>{new User()})[0];
        // Creating Brand
        schedulerConfiguration__c createBrand = new schedulerConfiguration__c();
        createBrand.Brand_Id__c = '1010';
        createBrand.Confirmation_Email_Template_Name__c = eTemp.id;
        createBrand.Preferred_Language__c = 'en_US';
        createBrand = testRecordClass.createSchedulerConfigurationRecords(new List<schedulerConfiguration__c>{createBrand})[0];
        
    	//Resource Pool for criteria '<' 
        Resource_Pool__c resPool = new Resource_Pool__c();
        resPool.Brand_Name__c = createBrand.Id;
        resPool.Dispatch_Admin__c = testUser1.Id;
        resPool.Preferred_Language__c = 'en_US';
        resPool.Criteria__c = '<';
        resPool = testRecordClass.createResourcePoolRecords(new List<Resource_Pool__c>{resPool})[0];

        //Creating Advisor
        Advisor__c advisor =  new Advisor__c();
        advisor.Advisor_Name__c = testUser1.id;
        advisor.Resource_Pool__c = resPool.id;
        advisor.Preferred_Language__c = 'en_US';
        insert advisor;
        
        //Creating Time Slots   
        List<Time__c> listTime5 = new List<Time__c>();
        //Monday    
        Time__c timeSlot1 = new Time__c();
        timeSlot1.Advisor_Name__c = advisor.id;
        timeSlot1.Day__c = 'Monday';
        timeSlot1.Start_Time__c = '05:00';
        timeSlot1.End_Time__c = '17:00';
        listTime5.add(timeSlot1);
          
        //Tuesday
        Time__c timeSlot2 = new Time__c();
        timeSlot2.Advisor_Name__c = advisor.id;
        timeSlot2.Day__c = 'Tuesday';
        timeSlot2.Start_Time__c = '05:00';
        timeSlot2.End_Time__c = '17:00';
        listTime5.add(timeSlot2);
        
        //Wednesday
        Time__c timeSlot3 = new Time__c();
        timeSlot3.Advisor_Name__c = advisor.id;
        timeSlot3.Day__c = 'Wednesday';
        timeSlot3.Start_Time__c = '05:00';
        timeSlot3.End_Time__c = '17:00';
        listTime5.add(timeSlot3);
        
        //Thursday
        Time__c timeSlot4 = new Time__c();
        timeSlot4.Advisor_Name__c = advisor.id;
        timeSlot4.Day__c = 'Thursday';
        timeSlot4.Start_Time__c = '05:00';
        timeSlot4.End_Time__c = '17:00';
        listTime5.add(timeSlot4);
        
        //Friday
        Time__c timeSlot5 = new Time__c();
        timeSlot5.Advisor_Name__c = advisor.id;
        timeSlot5.Day__c = 'Friday';
        timeSlot5.Start_Time__c = '05:00';
        timeSlot5.End_Time__c = '17:00';
        listTime5.add(timeSlot5);
        
        //Saturday
        Time__c timeSlot6 = new Time__c();
        timeSlot6.Advisor_Name__c = advisor.id;
        timeSlot6.Day__c = 'Saturday';
        timeSlot6.Start_Time__c = '05:00';
        timeSlot6.End_Time__c = '17:00';
        listTime5.add(timeSlot6);
        
        //Sunday
        Time__c timeSlot7 = new Time__c();
        timeSlot7.Advisor_Name__c = advisor.id;
        timeSlot7.Day__c = 'Sunday';
        timeSlot7.Start_Time__c = '05:00';
        timeSlot7.End_Time__c = '17:00';
        listTime5.add(timeSlot7);
        
        //listTime5 = testRecordClass.createTimeSlotRecords(listTime5);
        insert listTime5;
        Test.startTest();
	        // Testing for positive case
	        strConvertedDate =strDate+' '+'05:00 AM';
	        Request.cdatetime=strConvertedDate ;
	        Request.BrandID= '1010'; 
	        Request.NumberofUsers= 15;
	        Request.CustomerId= '1111';
	        Request.firstName = 'test1';
	        Request.lastname = 'test2';
	        Request.Email = 'test@test.com';
	        Request.Notes = 'This is a test event'; 
	        Request.appointmentLength = '60';
	        Request.premiumSupport = false;    
	        Request.preferredLanguage='en_US';
    		Request.timeZone = 'America/LosAngeles';     
	        Response = SchedulerWebService.scheduleEvent(Request);    
	        
	        system.debug('#### sucess_code - '+Response.sucess_code);
	        system.debug('#### error_code - '+Response.error_code); 
        
        Test.stopTest();
    }
    
    /******************************************************************************
	* @Description : Set event as cancelled.                                      *
	*                Add resource back in to relevant resource pool               *
	* @Params      : void                                                         *
	* @Return      : void                                                         * 
	******************************************************************************/
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void test_CancelEvents(){
        SchedulerWebService.cancelEventsRequest Request = new SchedulerWebService.cancelEventsRequest();
        SchedulerWebService.cancelEventsResponse Response = new SchedulerWebService.cancelEventsResponse();
        
        EmailTemplate eTemp = new EmailTemplate();
        eTemp.Name = 'Test';
        eTemp.folderId = [SELECT AccessType ,Id , Name, NamespacePrefix,  Type FROM Folder WHERE Name=:'Support OA Emails' LIMIT 1].id;
        eTemp.Subject = '#datetime# - Test Template';
        eTemp.Encoding = 'UTF-8';
        eTemp.TemplateType = 'Custom';
        eTemp.DeveloperName = 'Test';
        eTemp.IsActive = true;
        eTemp.HtmlValue = '#datetime#,#supportnumber#,#eventid#';
        eTemp.Body = '#datetime#,#supportnumber#,#eventid#';
        eTemp.IsActive = true;
        System.runAs(new User(Id = Userinfo.getUserId())) {
            insert eTemp;
        }
        
        /* Setting up test records */
        // Instantiating class to setup test records.
		Test_Utils testRecordClass = new Test_Utils();
		
        // Creating test User.
        User testUser1 = new User();                   
		testUser1 = testRecordClass.createUserRecord(new List<User>{new User()})[0];
        // Creating Brand
        schedulerConfiguration__c createBrand = new schedulerConfiguration__c();
        createBrand.Brand_Id__c='2222';
        createBrand.Cancellation_Email_Template_Customer__c= eTemp.id;
        createBrand.Cancellation_Email_Template_Internal__c= eTemp.id;
        createBrand.Confirmation_Email_Template_Name__c= eTemp.id; 
        createBrand.Reminder_E_mail_Template_Name__c= eTemp.id;
        createBrand.Rescheduling_Email_Template_Customer__c= eTemp.id;
        createBrand.Rescheduling_Email_Template_Internal__c= eTemp.id; 
        createBrand = testRecordClass.createSchedulerConfigurationRecords(new List<schedulerConfiguration__c>{createBrand})[0];
        // Creating Resource
        Resource_Pool__c resPool = new Resource_Pool__c();
        resPool.Brand_Name__c = createBrand.Id;
        resPool.Dispatch_Admin__c = testUser1.Id;
        resPool.No_of_User_DLs__c = 5;
        resPool = testRecordClass.createResourcePoolRecords(new List<Resource_Pool__c>{resPool})[0];

		//Creating Advisor
        User testUser2 = new User();      
        testUser2 = testRecordClass.createUserRecord(new List<User>{new User()})[0];             
        
        Advisor__c advisor = new Advisor__c();
        advisor.Advisor_Name__c = testUser2.Id;
        advisor.Resource_Pool__c = resPool.Id;
        advisor.Preferred_Language__c = 'en_US';
        insert advisor; 
        
        //Calling method to create new event.
        Event event = new Event();
        event = createEventRecord(createBrand.Brand_Id__c, resPool.Id);
        
        String eventId = event.Id;

		Test.startTest();
        //Testing positive case
        Request.EventId = event.Id;
        Request.premiumSupport =  false;
        Response = SchedulerWebService.cancelEvents(Request);   

        //Testing when event id is null
        Request.EventId = null;
        Response = SchedulerWebService.cancelEvents(Request);         

        //Trying to cancel the event again
        Request.EventId = event.id;
        Response = SchedulerWebService.cancelEvents(Request);   
        
        // Trying to cancel the event, that doesn't exist anymore.
        delete event;
        Request.EventId = eventId;
        Response = SchedulerWebService.cancelEvents(Request); 
        
		Test.stopTest();
    }

    /******************************************************************************
	* @Description : Cancel existing event.                                       *
	*                Create new event and save parameters to that event.          *
	*                Add resource back in to relevant resource pool.              *
	*                Remove used resource from relevant resource pool.            *
	* @Params      : void                                                         *
	* @Return      : void                                                         * 
	******************************************************************************/
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void test_resheduleEvents(){
        SchedulerWebService.resheduleEventsRequest Request = new SchedulerWebService.resheduleEventsRequest();
        SchedulerWebService.resheduleEventsResponse Response = new SchedulerWebService.resheduleEventsResponse();
        Test.startTest();
        /* Setting up test records */
        // Instantiating class to setup test records.
		Test_Utils testRecordClass = new Test_Utils();
		
        // Creating test User.
        User testUser1 = new User();                   
		testUser1 = testRecordClass.createUserRecord(new List<User>{new User()})[0];
        
        // creating email template
        EmailTemplate eTemp = new EmailTemplate();
        eTemp.Name = 'Test';
        eTemp.folderId = [SELECT AccessType ,Id , Name, NamespacePrefix,  Type FROM Folder WHERE Name=:'Support OA Emails' LIMIT 1].id;
        eTemp.Subject = '#datetime# - Test Template';
        eTemp.Encoding = 'UTF-8';
        eTemp.TemplateType = 'Custom';
        eTemp.DeveloperName = 'Test';
        eTemp.IsActive = true;
        eTemp.HtmlValue = '#datetime#,#supportnumber#,#eventid#';
        eTemp.Body = '#datetime#,#supportnumber#,#eventid#';
        eTemp.IsActive = true;
        System.runAs(new User(Id = Userinfo.getUserId())) {
            insert eTemp;
        }
        
        // Creating Brand
        schedulerConfiguration__c createBrand = new schedulerConfiguration__c();
        createBrand.Brand_Id__c = '2222';
        createBrand.Name = 'TestBrand';
        createBrand.Cancellation_Email_Template_Customer__c = eTemp.id;
        createBrand.Cancellation_Email_Template_Internal__c = eTemp.id;
        createBrand.Confirmation_Email_Template_Name__c = eTemp.id; 
        createBrand.Reminder_E_mail_Template_Name__c = eTemp.id;
        createBrand.Rescheduling_Email_Template_Customer__c = eTemp.id;
        createBrand.Rescheduling_Email_Template_Internal__c = eTemp.id; 
        createBrand.Preferred_Language__c = 'en_US';
        createBrand = testRecordClass.createSchedulerConfigurationRecords(new List<schedulerConfiguration__c>{createBrand})[0];
        
        // Creating Account Record.
        TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT();
			testRecordClass.createAccountRecord(new List<Account>{new Account(RC_Brand__c = 'TestBrand')});
		TriggerHandler.RESET_VARIABLES();
		
		// Creating Resource
        Resource_Pool__c resPool = new Resource_Pool__c();
        resPool.Brand_Name__c = createBrand.Id;
        resPool.Dispatch_Admin__c = testUser1.Id;
        resPool.No_of_User_DLs__c = 20;
        resPool.Preferred_Language__c = 'en_US';
        resPool = testRecordClass.createResourcePoolRecords(new List<Resource_Pool__c>{resPool})[0];

        //Creating Advisor
        User testUser2 = new User();      
        testUser2 = testRecordClass.createUserRecord(new List<User>{new User()})[0];             
        
        Advisor__c advisor = new Advisor__c();
        advisor.Advisor_Name__c = testUser2.Id;
        advisor.Resource_Pool__c = resPool.Id;
        advisor.Preferred_Language__c = 'en_US';
        insert advisor; 
        
        //Creating Time Slots   
        List<Time__c> listTime1 = new List<Time__c>();
        //Monday    
        Time__c timeSlot1 = new Time__c();
        timeSlot1.Advisor_Name__c = advisor.id;
        timeSlot1.Day__c = 'Monday';
        timeSlot1.Start_Time__c ='00:00';
        timeSlot1.End_Time__c = '23:59';
        timeSlot1.Advisor_Name__c = advisor.id;
        timeSlot1.availableFor__c = 'Initial Implementation';
        listTime1.add(timeSlot1);
          
        //Tuesday
        Time__c timeSlot2 = new Time__c();
        timeSlot2.Advisor_Name__c = advisor.id;
        timeSlot2.Day__c = 'Tuesday';
        timeSlot2.Start_Time__c ='00:00';
        timeSlot2.End_Time__c = '23:59';
        timeSlot2.availableFor__c = 'Initial Implementation';
        listTime1.add(timeSlot2);
        
        //Wednesday
        Time__c timeSlot3 = new Time__c();
        timeSlot3.Advisor_Name__c = advisor.id;
        timeSlot3.Day__c = 'Wednesday';
        timeSlot3.Start_Time__c = '00:00';
        timeSlot3.End_Time__c = '23:59';
        timeSlot3.availableFor__c = 'Initial Implementation';
        listTime1.add(timeSlot3);
         
        //Thursday
        Time__c timeSlot4 = new Time__c();
        timeSlot4.Advisor_Name__c = advisor.id;
        timeSlot4.Day__c = 'Thursday';
        timeSlot4.Start_Time__c ='00:00';
        timeSlot4.End_Time__c = '23:59';
        timeSlot4.availableFor__c = 'Initial Implementation';
        listTime1.add(timeSlot4);
        
        //Friday
        Time__c timeSlot5 = new Time__c();
        timeSlot5.Advisor_Name__c = advisor.id;
        timeSlot5.Day__c = 'Friday';
        timeSlot5.Start_Time__c ='00:00';
        timeSlot5.End_Time__c = '23:59';
        timeSlot5.availableFor__c = 'Initial Implementation';
        listTime1.add(timeSlot5);
        
        //Saturday
        Time__c timeSlot6 = new Time__c();
        timeSlot6.Advisor_Name__c = advisor.id;
        timeSlot6.Day__c = 'Saturday';
        timeSlot6.Start_Time__c ='00:00';
        timeSlot6.End_Time__c = '23:59';
        timeSlot6.availableFor__c = 'Initial Implementation';
        listTime1.add(timeSlot6);
        
        //Sunday
        Time__c timeSlot7 = new Time__c();
        timeSlot7.Advisor_Name__c = advisor.id;
        timeSlot7.Day__c = 'Sunday';
        timeSlot7.Start_Time__c ='00:00';
        timeSlot7.End_Time__c = '23:59';
        timeSlot7.availableFor__c = 'Initial Implementation';
        listTime1.add(timeSlot7);
        
        //listTime1 = testRecordClass.createTimeSlotRecords(listTime1);
		insert listTime1;
        //Calling method to create new event.
        Event event = new Event();
        event = createEventRecord(createBrand.Brand_Id__c, resPool.Id);
        
        //Generating date format
	    String strConvertedDate ;
	    String strDate;
	    Datetime GMTDate = DateTime.Now();
	    strDate = GMTDate.format('MM/dd/yyyy','English (United States)');
	    strConvertedDate = strDate +' '+'08:00 AM';
	
		//Testing for positive case
		
		
		Event ev = new Event( Customer_Email__c='ac@cc.com',CustomerId__c='12347' ,Subject='test implementation', StartDateTime=system.now().addDays(10),EndDateTime=system.now().addDays(10).addHours(1), Description='test',Preferred_Language__c='en_us',Time_Zone__c='America/LosAngeles',
                                        Appointment_Source__c='Internal Tool',Last_Name__c='test',First_Name__c='test',NumberofUser__c=5,Brand__c='7710',Implementation_Status__c='Scheduled',
                                        Type='Initial Implementation');
         TriggerHandler.BY_PASS_ACCOUNT_ON_BEFORE = true;
         TriggerHandler.BY_PASS_ACCOUNT_ON_AFTER = true;
         TriggerHandler.BY_PASS_IMPLEMENTATION_ON_BEFORE = true;
         TriggerHandler.BY_PASS_IMPLEMENTATION_ON_AFTER = true;
         insert ev;
         
	    Request.EventId = ev.Id;
	    Request.cdatetime = strConvertedDate ;
	    Request.BrandID = '7710';
	    Request.NumberofUsers = 20;
	    Request.CustomerId= '12347';
	    Request.firstName = 'test1';
	    Request.lastname = 'test2';
	    Request.Email = 'test@test.com';
	    Request.Notes = 'This is a test event';
	    Request.appointmentLength = '60';
	    Request.premiumSupport = false;
	    Request.preferredLanguage='en_US';
    	Request.timeZone = 'America/LosAngeles';
    	
	    Response = SchedulerWebService.resheduleEvents(Request);
        
        Request.BrandID = '2222';
        Response = SchedulerWebService.resheduleEvents(Request);
	    
	    Request.BrandID = '';
	    Response = SchedulerWebService.resheduleEvents(Request);
	    
	    Request.BrandID = '7710';
	    Request.NumberofUsers = null;
	    Response = SchedulerWebService.resheduleEvents(Request);
	    
	    Request.BrandID = '7710';
	    Request.NumberofUsers = 20;
	    Request.CustomerId= '';
	    Response = SchedulerWebService.resheduleEvents(Request);
	    
	    Request.BrandID = '7710';
	    Request.NumberofUsers = 20;
	    Request.CustomerId= '12347';
	    Request.firstName = '';
	    Response = SchedulerWebService.resheduleEvents(Request);
	    
	    Request.BrandID = '7710';
	    Request.NumberofUsers = 20;
	    Request.CustomerId= '12347';
	    Request.firstName = 'test1';
	    Request.lastname = '';
	    Response = SchedulerWebService.resheduleEvents(Request);
	    
	    Request.lastname = 'test2';
	    Request.Email = '';
	    Response = SchedulerWebService.resheduleEvents(Request);
	    
	    Request.Email = 'abd@cc.com';
	    Request.Notes = '';
	    Response = SchedulerWebService.resheduleEvents(Request);
	    
	    Request.Notes = 'abd@cc.com';
	    Request.appointmentLength = '';
	    Response = SchedulerWebService.resheduleEvents(Request);
	    
	    Request.appointmentLength = 'abd@cc.com';
	    Request.PreferredLanguage = '';
	    Response = SchedulerWebService.resheduleEvents(Request);
	    
	    Request.PreferredLanguage = 'en_US';
	    Request.TimeZone = '';
	    Response = SchedulerWebService.resheduleEvents(Request);
	    
        Test.stopTest();
    } 
	
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
	@isTest
    static void test_rescheduleEventNull(){
		
		SchedulerWebService.resheduleEventsRequest Request = new SchedulerWebService.resheduleEventsRequest();
        SchedulerWebService.resheduleEventsResponse Response = new SchedulerWebService.resheduleEventsResponse();
        
        /* Setting up test records */
        // Instantiating class to setup test records.
		Test_Utils testRecordClass = new Test_Utils();
		
        // Creating test User.
        User testUser1 = new User();                   
		testUser1 = testRecordClass.createUserRecord(new List<User>{new User()})[0];
        
        // creating email template
        EmailTemplate eTemp = new EmailTemplate();
        eTemp.Name = 'Test';
        eTemp.folderId = [SELECT AccessType ,Id , Name, NamespacePrefix,  Type FROM Folder WHERE Name=:'Support OA Emails' LIMIT 1].id;
        eTemp.Subject = '#datetime# - Test Template';
        eTemp.Encoding = 'UTF-8';
        eTemp.TemplateType = 'Custom';
        eTemp.DeveloperName = 'Test';
        eTemp.IsActive = true;
        eTemp.HtmlValue = '#datetime#,#supportnumber#,#eventid#';
        eTemp.Body = '#datetime#,#supportnumber#,#eventid#';
        eTemp.IsActive = true;
        System.runAs(new User(Id = Userinfo.getUserId())) {
            insert eTemp;
        }
        
        // Creating Brand
        schedulerConfiguration__c createBrand = new schedulerConfiguration__c();
        createBrand.Brand_Id__c = '2222';
        createBrand.Name = 'TestBrand';
        createBrand.Cancellation_Email_Template_Customer__c = eTemp.id;
        createBrand.Cancellation_Email_Template_Internal__c = eTemp.id;
        createBrand.Confirmation_Email_Template_Name__c = eTemp.id; 
        createBrand.Reminder_E_mail_Template_Name__c = eTemp.id;
        createBrand.Rescheduling_Email_Template_Customer__c = eTemp.id;
        createBrand.Rescheduling_Email_Template_Internal__c = eTemp.id; 
        createBrand = testRecordClass.createSchedulerConfigurationRecords(new List<schedulerConfiguration__c>{createBrand})[0];
        
        // Creating Account Record.
        TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT();
			testRecordClass.createAccountRecord(new List<Account>{new Account(RC_Brand__c = 'TestBrand')});
		TriggerHandler.RESET_VARIABLES();
		
		// Creating Resource
        Resource_Pool__c resPool = new Resource_Pool__c();
        resPool.Brand_Name__c = createBrand.Id;
        resPool.Dispatch_Admin__c = testUser1.Id;
        resPool.No_of_User_DLs__c = 20;
        resPool = testRecordClass.createResourcePoolRecords(new List<Resource_Pool__c>{resPool})[0];

        //Creating Advisor
        User testUser2 = new User();      
        testUser2 = testRecordClass.createUserRecord(new List<User>{new User()})[0];             
        
        Advisor__c advisor = new Advisor__c();
        advisor.Advisor_Name__c = testUser2.Id;
        advisor.Resource_Pool__c = resPool.Id;
        advisor.Preferred_Language__c = 'en_US';
        insert advisor; 
        
        //Creating Time Slots   
        List<Time__c> listTime1 = new List<Time__c>();
       //Monday    
        Time__c timeSlot1 = new Time__c();
        timeSlot1.Advisor_Name__c = advisor.id;
        timeSlot1.Day__c = 'Monday';
        timeSlot1.Start_Time__c = '05:00';
        timeSlot1.End_Time__c = '17:00';
        listTime1.add(timeSlot1);
          
        //Tuesday
        Time__c timeSlot2 = new Time__c();
        timeSlot2.Advisor_Name__c = advisor.id;
        timeSlot2.Day__c = 'Tuesday';
        timeSlot2.Start_Time__c = '05:00';
        timeSlot2.End_Time__c = '17:00';
        listTime1.add(timeSlot2);
        
        //Wednesday
        Time__c timeSlot3 = new Time__c();
        timeSlot3.Advisor_Name__c = advisor.id;
        timeSlot3.Day__c = 'Wednesday';
        timeSlot3.Start_Time__c = '05:00';
        timeSlot3.End_Time__c = '17:00';
        listTime1.add(timeSlot3);
         
        //Thursday
        Time__c timeSlot4 = new Time__c();
        timeSlot4.Advisor_Name__c = advisor.id;
        timeSlot4.Day__c = 'Thursday';
        timeSlot4.Start_Time__c = '05:00';
        timeSlot4.End_Time__c = '17:00';
        listTime1.add(timeSlot4);
        
        //Friday
        Time__c timeSlot5 = new Time__c();
        timeSlot5.Advisor_Name__c = advisor.id;
        timeSlot5.Day__c = 'Friday';
        timeSlot5.Start_Time__c = '05:00';
        timeSlot5.End_Time__c = '17:00';
        listTime1.add(timeSlot5);
        
        //Saturday
        Time__c timeSlot6 = new Time__c();
        timeSlot6.Advisor_Name__c = advisor.id;
        timeSlot6.Day__c = 'Saturday';
        timeSlot6.Start_Time__c = '05:00';
        timeSlot6.End_Time__c = '17:00';
        listTime1.add(timeSlot6);
        
        //Sunday
        Time__c timeSlot7 = new Time__c();
        timeSlot7.Advisor_Name__c = advisor.id;
        timeSlot7.Day__c = 'Sunday';
        timeSlot7.Start_Time__c = '05:00';
        timeSlot7.End_Time__c = '17:00';
        listTime1.add(timeSlot7);
        
        insert listTime1;// = testRecordClass.createTimeSlotRecords(listTime1);
        
		//Calling method to create new event.
        Event event = new Event();
        event = createEventRecord(createBrand.Brand_Id__c, resPool.Id);
        
        //Generating date format
	    String strConvertedDate ;
	    String strDate;
	    Datetime GMTDate = DateTime.Now();
	    strDate = GMTDate.format('MM/dd/yyyy','English (United States)');
	    strConvertedDate = strDate +' '+'08:00 AM';
	    
		//Testing for positive case
	    Request.EventId = event.Id;
	    Request.cdatetime = strConvertedDate ;
	    Request.BrandID = createBrand.Brand_Id__c; 
	    Request.NumberofUsers = 20;
	    Request.CustomerId= '12345';
	    Request.firstName = 'test1';
	    Request.lastname = 'test2';
	    Request.Email = 'test@test.com';
	    Request.Notes = 'This is a test event';
	    Request.appointmentLength = '60';
	    Request.premiumSupport = false;
	    Request.preferredLanguage='en_US';
    	Request.timeZone = 'America/LosAngeles';
	    Response = SchedulerWebService.resheduleEvents(Request);
	    
		//Testing for null date time
        Request.cdatetime = null;
        Response = SchedulerWebService.resheduleEvents(Request);
	
        //Testing for null event id
        Request.EventId = null;
        Response = SchedulerWebService.resheduleEvents(Request);
	
        //Testing for null brand id
        Request.BrandID= null ; 
        Response = SchedulerWebService.resheduleEvents(Request);
	
        //Testing for null number of users
        Request.NumberofUsers= null;
        Response = SchedulerWebService.resheduleEvents(Request);
	
        //Testing for null customer id
        Request.CustomerId= null ;
        Response = SchedulerWebService.resheduleEvents(Request);
	
        //Testing for null first name
        Request.firstName = null;
        Response = SchedulerWebService.resheduleEvents(Request);         
	
        //Testing for null last name
        Request.lastname = null;
        Response = SchedulerWebService.resheduleEvents(Request);         
	
        //Testing for null email
        Request.Email = null;
        Response = SchedulerWebService.resheduleEvents(Request);         
	
        //Testing for null notes
        Request.Notes = null;
        Response = SchedulerWebService.resheduleEvents(Request);         
	        
        //Testing for null appointment length
        Request.appointmentLength = null;
        Response = SchedulerWebService.resheduleEvents(Request);         
	}

    /******************************************************************************
	* @Description : Check to see if an Implementation is already scheduled,      *
	*                for the CustomerID (RCUserID)                                *
	* @Params      : void                                                         *
	* @Return      : void                                                         * 
	******************************************************************************/
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void test_isEventScheduled(){

        SchedulerWebService.isEventScheduledRequest Request = new SchedulerWebService.isEventScheduledRequest();
        SchedulerWebService.isEventScheduledResponse Response = new SchedulerWebService.isEventScheduledResponse();
        
        /* Setting up test records */
        // Instantiating class to setup test records.
		Test_Utils testRecordClass = new Test_Utils();
		
        // Creating test User.
        User testUser1 = new User();                   
		testUser1 = testRecordClass.createUserRecord(new List<User>{new User()})[0];
        
        // Creating Brand
        schedulerConfiguration__c createBrand = new schedulerConfiguration__c();
        createBrand.Brand_Id__c='2222';
        createBrand = testRecordClass.createSchedulerConfigurationRecords(new List<schedulerConfiguration__c>{createBrand})[0];
		// Creating Resource
        Resource_Pool__c resPool = new Resource_Pool__c();
        resPool.Brand_Name__c = createBrand.Id;
        resPool.Dispatch_Admin__c = testUser1.Id;
        resPool = testRecordClass.createResourcePoolRecords(new List<Resource_Pool__c>{resPool})[0];

        //Creating Advisor
        User testUser2 = new User();      
        testUser2 = testRecordClass.createUserRecord(new List<User>{new User()})[0];             
        
        Advisor__c advisor = new Advisor__c();
        advisor.Advisor_Name__c = testUser2.Id;
        advisor.Resource_Pool__c = resPool.Id;
        advisor.Preferred_Language__c = 'en_US';
        insert advisor; 

        //Calling method to create new event.
        Event event = new Event();
        event = createEventRecord(createBrand.Brand_Id__c, resPool.Id);
		
		Test.startTest();
		
	        //Testing for positive case with customer Id
	        Request.CustomerId= '1010';
	        Response = SchedulerWebService.isEventScheduled(Request);
	
	        //Testing is customer Id doesn't exists
	        Request.CustomerId= '1111' ;
	        Response = SchedulerWebService.isEventScheduled(Request);            
	
	        //Testing if customer is null
	        Request.CustomerId= null;
	        Response = SchedulerWebService.isEventScheduled(Request);
	        
	        // Testing for positive case with event Id.
	        Request.CustomerId= '1111' ;
			Request.eventId = event.Id;
			Response = SchedulerWebService.isEventScheduled(Request);
			
			// Testing for positive case with event Id no longer existing.
			delete event;
			Request.CustomerId= '1111' ;
			Request.eventId = event.Id;
			Response = SchedulerWebService.isEventScheduled(Request);
        
        Test.stopTest();
    } 
     
    private static Event createEventRecord(String brandName, Id resourcePoolId){
    	
    	Test_Utils testUtilsObject =  new Test_Utils();
        Event event = new Event();
        event.ownerId = system.Userinfo.getUserId();
        event.subject = 'test';  
        event.StartDateTime = Datetime.now();
        event.EndDateTime = Datetime.now().addHours(1);
        event.DurationInMinutes = 60;
        event.WhatId = resourcePoolId; 
        event.Brand__c = brandName;
        event.Customer_Email__c = 'test@test.com';
        event.CustomerId__c = '12347';
        event.Description = 'This is a test event';
        event.NumberofUser__c = 20;
        event.First_Name__c = 'Test1';
        event.Last_Name__c = 'Test2';
        event.Type = 'Initial Implementation';
        testUtilsObject.initialiseTriggerBypass();
        	insert event; 
        testUtilsObject.deInitialiseTriggerBypass();
    	
    	return event;
    } 
    
    @isTest
    static void testGetAccountDetails() {
        String RCUserId = 'testUserId';
        Account testAccount = new Account(RC_User_ID__c = RCUserId, Name = 'TestName');
        insert testAccount;
        
        Account result = EventSchedulerUtility.getAccountDetails(RCUserId);
        
        System.assertEquals(testAccount.Id, result.Id);
        
        delete testAccount;
    }
    
    @isTest
    static void testGetBrand() {
        String brandId = 'testBrandId';
        schedulerConfiguration__c testBrand = new schedulerConfiguration__c(Brand_Id__c = brandId);
        insert testBrand;
        
        schedulerConfiguration__c result = EventSchedulerUtility.getBrand(brandId);
        
        System.assertEquals(testBrand.Id, result.Id);
        
        delete testBrand;
    }
    
    @isTest
    static void testGetBrandsDetailsLanguage() {
        String brandId = 'testBrandId';
        String preferredLanguage = 'en_US';
        schedulerConfiguration__c testBrand = new schedulerConfiguration__c(Brand_Id__c = brandId, Preferred_Language__c = preferredLanguage);
        insert testBrand;

        schedulerConfiguration__c result = EventSchedulerUtility.getBrandsDetailsLanguage(brandId, preferredLanguage);
        
        System.assertEquals(testBrand.Id, result.Id);
        
        delete testBrand;
    }
    
    @isTest
    static void testGetBufferdays() {
        String brandId = 'testBrandId';
        schedulerConfiguration__c testBrand = new schedulerConfiguration__c(Brand_Id__c = brandId, Buffer_Days__c = 5);
        insert testBrand;
        
        Integer result = EventSchedulerUtility.getBufferdays(brandId);
        
        System.assertEquals(5, result);
        
        delete testBrand;
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
  	  static void testGetAccountDetails2() {
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        
        Account result = eventSchedulerUtility.getAccountDetails('RCUserId');
        
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testGetBufferdays2() {
        String brandId = 'ABC123';

        Integer bufferDays = eventSchedulerUtility.getBufferdays(brandId);
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testGetValidEmailTemplate() {
        String brandId = 'brandIdValue';
        String emailType = 'emailTypeValue';
        String preferredLanguage = 'preferredLanguageValue';
        
        Id emailTemplateId = eventSchedulerUtility.getValidEmailTemplate(brandId, emailType, preferredLanguage);
        
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @IsTest
    static void testGetResourcePoolResources() {
        eventSchedulerUtility.advisorRequestWrapper arwObject = new eventSchedulerUtility.advisorRequestWrapper();
        
        List<Id> result = eventSchedulerUtility.getResourcePoolResources(arwObject);
    }
    
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testGetOffsetValue() {
        String baseTimeZone = 'GMT';
        String timeZone = 'PST';

        Decimal expectedOffset = -8;

        Decimal actualOffset = eventSchedulerUtility.getOffsetValue(baseTimeZone, timeZone);
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
	static void testUpdateImplementationOwner_RCSF_Sync_Owner() {

    Profile p = [SELECT Id FROM Profile WHERE Name='Standard User'];
    User testUser = new User(
        ProfileId = p.Id,
        LastName = 'Sync',
        Alias = 'RS',
        Email = 'rcsf@sync.com',
        EmailEncodingKey = 'UTF-8',
        LanguageLocaleKey = 'en_US',
        LocaleSidKey = 'en_US',
        TimeZoneSidKey = 'America/Los_Angeles',
        UserName = 'rcsf.sync@testorg.com'
    );
    insert testUser;
    
    Account testCustomer = new Account(Name = 'Test Customer');
    insert testCustomer;
    Implementation__c testImplementation = new Implementation__c(
        Name = 'Test Implementation',
        Account__c = testCustomer.Id, 
        OwnerId = testUser.Id 
    );
    insert testImplementation;
    
    Id initialAdvisorId = UserInfo.getUserId();
    
    Test.startTest();
  
    eventSchedulerUtility.updateImplementationOwner(initialAdvisorId, testCustomer.Id);
    
    Test.stopTest();
    
	}
  
	@isTest
    static void testAllDayEvent() {

        Boolean isAllDayEvent = true;
        Datetime startDateTime = Datetime.newInstance(2024, 3, 15, 0, 0, 0);
        Datetime endDateTime = Datetime.newInstance(2024, 3, 16, 0, 0, 0);

        String result = eventSchedulerUtility.Schedule(isAllDayEvent, startDateTime, endDateTime);

        String expected = 'DTSTART;VALUE=DATE:20240315\r\n';
        expected += 'DTEND;VALUE=DATE:20240317\r\n';
        System.assertEquals(expected, result);
    }

    @isTest
    static void testGetOrgWideAddress() {
		OrgWideEmailAddress testOrgWideEmail = new OrgWideEmailAddress();
		testOrgWideEmail = [SELECT Id, DisplayName, Address FROM OrgWideEmailAddress LIMIT 1];
        
        OrgWideEmailAddress retrievedOrgWideEmail = eventSchedulerUtility.getOrgWideAddress(testOrgWideEmail.Id);
        
        System.assertEquals(testOrgWideEmail.Id, retrievedOrgWideEmail.Id);
        System.assertEquals(testOrgWideEmail.DisplayName, retrievedOrgWideEmail.DisplayName);
        System.assertEquals(testOrgWideEmail.Address, retrievedOrgWideEmail.Address);
    }

}// End of Test Class.