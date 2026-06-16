/**************************************************************************************************
* Project Name..........: RingCentral - Self Serve Scheduling                                     *
* File..................: Test_ExtAppointment.cls                                                 *
* Version...............: 1.0                                                                     *
* Created by............: Simplion Technologies                                                   *
* Created Date..........: 24 June 2013                                                            *
* Last Modified by......: Simplion Technologies                                                   *
* Last Modified Date....:                                                                         *
* Description...........: Test class for extAppointment                                           *
**************************************************************************************************/
@isTest
private class extAppointmentTest {
    
    public static Test_Utils testUtilsObject = new Test_Utils();
    public static extAppointment eaObject;
    public static List<Account> accountList =  new List<Account>();
    public static List<Contact> contactList = new List<Contact>();
    public static List<schedulerConfiguration__c> scList = new List<schedulerConfiguration__c>();
    public static List<Implementation__c> implementationList =  new List<Implementation__c>();
    public static Advisor__c advisorRecord = new Advisor__c();
    
    private static void createImplementationSchedulerCustomSettingRecord(){
        Implementation_Scheduler__c isObject =  new Implementation_Scheduler__c();
        isObject.Name = 'Profiles';
        isObject.Values__c = 'System Administrator';
        
        insert isObject;
    }
    private static void createImplementationSchedulerCustomSettingRecord1(){
        Implementation_Scheduler__c isObjectt =  new Implementation_Scheduler__c();
        isObjectt.Name = 'Profiles';
        isObjectt.Values__c = 'Sales Agent';
        
        insert isObjectt;
    }
    
    private static  Advisor__c createAdvisorRecord(User userRecord, Resource_Pool__c resourcePoolRecord){
        Advisor__c advisor = new Advisor__c();
        advisor.Advisor_Name__c = userRecord.Id;
        advisor.Resource_Pool__c = resourcePoolRecord.Id;
        advisor.Preferred_Language__c = 'en_US';
        insert advisor;
        
        return advisor;
    }
    
    private static void createTestRecords(){
        
        /* Contact 3 the best, Account 3 the best */ 
        TimeZone__c tm0 = new TimeZone__c(Name='America/Los_Angeles', Label__c='America/Los_Angeles',Active__c=true);
        TimeZone__c tm1 = new TimeZone__c(Name='America/Denver', Label__c='America/Denver',Active__c=true);
        TimeZone__c tm2 = new TimeZone__c(Name='Europe/London', Label__c='Europe/London',Active__c=true);
        List<TimeZone__c> lt = new List<TimeZone__c>();
        lt.add(tm0);lt.add(tm1);lt.add(tm2);
        insert lt;
        Triggers.switchOff();
        TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT();
            accountList = testUtilsObject.createAccountRecord(new List<Account>{new Account(), 
                                                                                new Account(Number_of_DL_s__c = 0),
                                                                                new Account(RC_Brand__c = 'testAccount'),
                                                                                new Account()});
        TriggerHandler.RESET_VARIABLES();
        TriggerHandler.BY_PASS_CONTACT_ON_INSERT();
            contactList = testUtilsObject.createContactRecord(new List<Contact>{new Contact(), 
                                                                                new Contact(AccountId = accountList[0].Id), 
                                                                                new Contact(AccountId = accountList[1].Id),
                                                                                new Contact(AccountId = accountList[2].Id),
                                                                                new Contact(AccountId = accountList[3].Id,Preferred_Language__c='en_US')});
        TriggerHandler.RESET_VARIABLES();
        Triggers.switchOn();
        // Creating User Record.
        List<User> userList = testUtilsObject.createUserRecord(new List<User>{new User(), new User()});
        // Creating scheduler configuration record. 
        scList = testUtilsObject.createSchedulerConfigurationRecords(new List<schedulerConfiguration__c>{new schedulerConfiguration__c(Brand_Id__c='7710',Preferred_Language__c='en_US')}); 
        // Creating Implementation record.
        implementationList = testUtilsObject.createImplementationRecords(new List<Implementation__c>{new Implementation__c(Implementation_Status_2__c = 'Completed', Account__c = accountList[0].Id)});
        // Creating Resource Pool Record.
        List<Resource_Pool__c> resourcePoolList = testUtilsObject.createResourcePoolRecords(new List<Resource_Pool__c>{new Resource_Pool__c(No_of_User_DLs__c = accountList[2].Number_of_DL_s__c, Brand_Name__c = scList[0].Id, Dispatch_Admin__c = userList[1].Id)});
        // Calling method to create Advisor Record. 
        advisorRecord = createAdvisorRecord(userList[0], resourcePoolList[0]);  
       
        /* debug logs */
        system.debug('#### Account - '+accountList);
        system.debug('#### Contact - '+contactList);
        system.debug('#### Resource Pool - '+resourcePoolList);
        system.debug('#### User - '+userList);
        system.debug('#### Brand Configuration - '+scList);
        system.debug('#### Implementation - '+implementationList);
        system.debug('#### Advisor - '+advisorRecord);
    }
    
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')    
    @isTest
    static void testMethodConstructor() {
        
        // Creating custom setting record.
        createImplementationSchedulerCustomSettingRecord();
         
          createImplementationSchedulerCustomSettingRecord1();
        // Calling method to create test records.
        createTestRecords();
        Test.startTest();
            // Calling contructor without Contact Id.
            ApexPages.currentPage().getParameters().put('contactId',null);
            ApexPages.currentPage().getParameters().put('iType','0');
            eaObject =  new extAppointment();
            
            // Calling contructor with Contact Id and No Account linked to the Contact.
            ApexPages.currentPage().getParameters().put('iType','1');
            ApexPages.currentPage().getParameters().put('contactId',contactList[0].Id);
            eaObject =  new extAppointment();
            
            // Calling contructor with Contact Id and Account linked to the Contact.
            ApexPages.currentPage().getParameters().put('contactId',contactList[1].Id);
            eaObject =  new extAppointment();
            
            // Calling contructor with Contact Id and Account linked to the Contact, with blank RC Brand.
            ApexPages.currentPage().getParameters().put('contactId',contactList[2].Id);
            eaObject =  new extAppointment();
            
            // Calling contructor with Contact Id and Account linked to the Contact, with valid Brand Records.
            ApexPages.currentPage().getParameters().put('contactId',contactList[3].Id);
            eaObject =  new extAppointment();
            eventSchedulerUtility.getValidEmailTemplate('7710','Confirmation','en_us');
            // Calling contructor with Contact Id and Account linked to the Contact, with RC User Id as null to cover line 166-169.
            accountList[3].RC_User_ID__c =  null;
            TriggerHandler.BY_PASS_ACCOUNT_ON_UPDATE();
                update accountList[3];
            TriggerHandler.RESET_VARIABLES();
            ApexPages.currentPage().getParameters().put('contactId',contactList[4].Id);
            eaObject =  new extAppointment();
            eaObject.brandId = '7710';
            ApexPages.currentPage().getParameters().put('contactId',contactList[4].Id);
            eaObject.associatedContact = contactList[4].Id;
            eaObject.getPreferedLangMethod();
        Test.stopTest();
        // Calling method to reach the exception method.
        //extAppointment.toExecute = true;
        //eaObject =  new extAppointment();
    }
    
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testMethodConstructor1() {
        

        // Creating custom setting record.
        createImplementationSchedulerCustomSettingRecord();
         
          createImplementationSchedulerCustomSettingRecord1();
        // Calling method to create test records.
        createTestRecords();
        Test.startTest();
            // Calling contructor without Contact Id.
            eaObject =  new extAppointment();
            
            // Calling contructor with Contact Id and No Account linked to the Contact.
            ApexPages.currentPage().getParameters().put('contactId',contactList[0].Id);
            eaObject =  new extAppointment();
            
            // Calling contructor with Contact Id and Account linked to the Contact.
            ApexPages.currentPage().getParameters().put('contactId',contactList[1].Id);
            eaObject =  new extAppointment();
            
            // Calling contructor with Contact Id and Account linked to the Contact, with blank RC Brand.
            ApexPages.currentPage().getParameters().put('contactId',contactList[2].Id);
            eaObject =  new extAppointment();
            
            // Calling contructor with Contact Id and Account linked to the Contact, with valid Brand Records.
            ApexPages.currentPage().getParameters().put('contactId',contactList[3].Id);
            eaObject =  new extAppointment();
            
            // Calling contructor with Contact Id and Account linked to the Contact, with RC User Id as null to cover line 166-169.
            accountList[3].RC_User_ID__c =  null;
            TriggerHandler.BY_PASS_ACCOUNT_ON_UPDATE();
                update accountList[3];
            TriggerHandler.RESET_VARIABLES();
            ApexPages.currentPage().getParameters().put('contactId',contactList[4].Id);
            eaObject =  new extAppointment();
        Test.stopTest();
    }
    
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testMethodNoArguments() {
        eaObject =  new extAppointment();
        eaObject.getImplementationTypes();
        eaObject.close();   
        eaObject.ToSchedule();
        eaObject.ScheduleAppointment();
        eaObject.ReScheduleAppointment();
        eaObject.CancelAppointment();
        eaObject.HomePage();
        eaObject.objectInitializer();
        eaObject.checkMandatoryFields();
       
        //objextAppointment.isImplementationCompleted = true;
        //eaObject.getPreferedLangMethod();
    }
    
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testAppointmentLength(){
        
        // Calling method to create test records.
        createTestRecords();
        // Linking a contact.
        ApexPages.currentPage().getParameters().put('contactId',contactList[3].Id);
        
        extAppointment objextAppointment = new extAppointment();
        // Calling method with no date.
        objextAppointment.AppointmentLength();
        // Calling method with date specified.
        objextAppointment.stringobjDate='06/25/2030';
        objextAppointment.AppointmentLength();
        
        //Checking for saturday and sunday time
        objextAppointment.stringobjDate='06/23/2030';
        objextAppointment.AppointmentLength();
        
        //Checking for past date time
        objextAppointment.stringobjDate='06/23/2013';
        objextAppointment.AppointmentLength();
    }
    
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testAvailabletimeSlot(){
        
        // Calling method to create test records.
        createTestRecords();
        
        // fetchProfileCustomSetting();
        // Linking a contact.
        ApexPages.currentPage().getParameters().put('contactId',contactList[3].Id);
        System.currentPageReference().getParameters().put('rcUserId','12347');
        
        Test.startTest();
        extAppointment objextAppointment = new extAppointment();
        /* 1. Calling method without setting up the time slots. */
        objextAppointment.stringobjDate = '06/25/2030';
        objextAppointment.AppointmentLength();
        objextAppointment.AvailabletimeSlot();
        
        /* 2. Calling method, after setting up the time slots. */
        List<Time__c> timeList = testUtilsObject.createTimeSlotRecords(new List<Time__c>{new Time__c(Advisor_Name__c = advisorRecord.Id,Start_Time__c = '00:00',End_Time__c = '23:59'),
                                                                                         new Time__c(Advisor_Name__c = advisorRecord.Id,Start_Time__c = '00:00',End_Time__c = '23:59'),
                                                                                         new Time__c(Advisor_Name__c = advisorRecord.Id,Start_Time__c = '00:00',End_Time__c = '23:59'),
                                                                                         new Time__c(Advisor_Name__c = advisorRecord.Id,Start_Time__c = '00:00',End_Time__c = '23:59'),
                                                                                         new Time__c(Advisor_Name__c = advisorRecord.Id,Start_Time__c = '00:00',End_Time__c = '23:59')});
        objextAppointment.AvailabletimeSlot();
        
        /* 3. Calling method, after setting up the appointment length. */
        objextAppointment.appointmentLength = '60';
        objextAppointment.preferredLanguage='en_US';
        objextAppointment.timeZone = 'America/LosAngeles';
        objextAppointment.AvailabletimeSlot();
        
        /* 4. Calling method, for a day, on which time slot available, and a invalid Advisor */
        objextAppointment.selectedAdvisor = advisorRecord.Id;
        objextAppointment.AvailabletimeSlot();
        
        /* 5. Calling method, for a day, on which time slot available, and a valid Advisor */
        objextAppointment.selectedAdvisor = advisorRecord.Advisor_Name__c;
        objextAppointment.AvailabletimeSlot();
        objextAppointment.objectInitializer();
        
        /* 6. Calling method, for a day, on which no time slot available*/
        Time__c deleteTime = [SELECT Id FROM Time__c WHERE Day__c = 'Tuesday' LIMIT 1];
        delete deleteTime;
        objextAppointment.AvailabletimeSlot();
        Test.stopTest();
    }
    
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testOnSave(){
        
        // Calling method to create test records.
        createTestRecords();
        Test.startTest();
        // Linking a contact.
        ApexPages.currentPage().getParameters().put('contactId',contactList[3].Id);
        System.currentPageReference().getParameters().put('rcUserId','12347');

  List<Time__c> timeList = testUtilsObject.createTimeSlotRecords(new List<Time__c>{new Time__c(Advisor_Name__c = advisorRecord.Id,Start_Time__c = '00:00',End_Time__c = '23:59', availableFor__c = 'Initial Implementation', Day__c = 'Tuesday'),
            new Time__c(Advisor_Name__c = advisorRecord.Id,Start_Time__c = '00:00',End_Time__c = '23:59'),
            new Time__c(Advisor_Name__c = advisorRecord.Id,Start_Time__c = '00:00',End_Time__c = '23:59', availableFor__c = 'Initial Implementation', Day__c = 'Tuesday'),
            new Time__c(Advisor_Name__c = advisorRecord.Id,Start_Time__c = '00:00',End_Time__c = '23:59', availableFor__c = 'Initial Implementation', Day__c = 'Tuesday'),
            new Time__c(Advisor_Name__c = advisorRecord.Id,Start_Time__c = '00:00',End_Time__c = '23:59', availableFor__c = 'Initial Implementation', Day__c = 'Tuesday')});
        /* 1. Calling method, without any time slots configured. */
        extAppointment objextAppointment = new extAppointment();
        objextAppointment.stringobjDate = '06/25/2030'; 
        objextAppointment.appointmentLength = '60';
        objextAppointment.preferredLanguage='en_US';
        objextAppointment.timeZone = 'America/LosAngeles';
        objextAppointment.Times = '16:00';
        objextAppointment.AppointmentLength();
         objextAppointment.objectInitializer();
        objextAppointment.objectInitializer();
        objextAppointment.AvailabletimeSlot();
        
        objextAppointment.OnSave();
        objextAppointment.implementationType = 'Initial Implementation';
        objextAppointment.contactId = contactList[3].Id;
        objextAppointment.cancelEvent();
        
        Event ev = new Event(Customer_Email__c='ac@cc.com',CustomerId__c='12347' ,Subject='test implementation', StartDateTime=system.now().addDays(10),EndDateTime=system.now().addDays(10).addHours(1), Description='test',Preferred_Language__c='en_us',Time_Zone__c='America/LosAngeles',
                                        Appointment_Source__c='Internal Tool',Last_Name__c='test',First_Name__c='test',NumberofUser__c=5,Brand__c='7710',Implementation_Status__c='Scheduled',
                                        Type='Initial Implementation');
         TriggerHandler.BY_PASS_ACCOUNT_ON_BEFORE = true;
         TriggerHandler.BY_PASS_ACCOUNT_ON_AFTER = true;
         TriggerHandler.BY_PASS_IMPLEMENTATION_ON_BEFORE = true;
         TriggerHandler.BY_PASS_IMPLEMENTATION_ON_AFTER = true;
         insert ev;
        objextAppointment.eventList = eventSchedulerUtility.getEventList('12347');
        objextAppointment.cancelEvent();
        Test.stopTest();
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testUpdateAccount(){
        Account acc = new Account(Name='test acc');
        insert acc;
        extAppointment objextAppointment = new extAppointment();
        objextAppointment.stringobjDate = '06/25/2030'; 
        objextAppointment.appointmentLength = '60';
        objextAppointment.preferredLanguage='en_US';
        objextAppointment.timeZone = 'America/LosAngeles';
        objextAppointment.Times = '16:00';

        objextAppointment.updateAccount(acc.Id);
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testConvertTimeslot(){
        extAppointment objextAppointment = new extAppointment();
        List<String> timeSlots = new List<String>{'12:00', '16:45', '24:00', '09:32'};
        List<SelectOption> options = objextAppointment.convertTimeslot(timeSlots);
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testIsAdvisorAvailable(){
        extAppointment objextAppointment = new extAppointment();
        eventSchedulerUtility.timeZoneWrapper tzwObject = new eventSchedulerUtility.timeZoneWrapper(); 
        tzwObject.timeZone = 'America/LosAngeles';
        tzwObject.timeSlots = new List<String>{'12:00', '16:45', '24:00', '09:32'};

        Boolean result = objextAppointment.isAdvisorAvailable(tzwObject, '16:45', null);
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testReschedule(){
        
        /* 1. Calling method without any event available. */
        extAppointment objextAppointment = new extAppointment();
        objextAppointment.Reschedule(); 
        
        /* 2. Calling method with event availabe. */
        createTestRecords();
        Test.startTest();
            List<Time__c> timeList = testUtilsObject.createTimeSlotRecords(new List<Time__c>{new Time__c(Advisor_Name__c = advisorRecord.Id),
                                                                                            new Time__c(Advisor_Name__c = advisorRecord.Id),
                                                                                            new Time__c(Advisor_Name__c = advisorRecord.Id),
                                                                                            new Time__c(Advisor_Name__c = advisorRecord.Id),
                                                                                            new Time__c(Advisor_Name__c = advisorRecord.Id),
                                                                                            new Time__c(Advisor_Name__c = advisorRecord.Id),
                                                                                            new Time__c(Advisor_Name__c = advisorRecord.Id)});
            ApexPages.currentPage().getParameters().put('contactId',contactList[3].Id);
            System.currentPageReference().getParameters().put('rcUserId','12347');
            objextAppointment = new extAppointment();
            objextAppointment.stringobjDate = '06/25/2030'; 
            objextAppointment.appointmentLength = '60';
            objextAppointment.preferredLanguage='en_US';
            objextAppointment.timeZone = 'America/LosAngeles';
            objextAppointment.Times = '16:00';
            objextAppointment.AppointmentLength();
            objextAppointment.AvailabletimeSlot();
            objextAppointment.OnSave();
            objextAppointment = new extAppointment();
            objextAppointment.implementationType = 'Initial Implementation';
            objextAppointment.Reschedule(); 
        Test.stopTest();
    }
    
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testCancelEvent(){
        /* 1. Calling method without any event available. */
        extAppointment objextAppointment = new extAppointment();
        //objextAppointment.cancelEvent();
        
        /* 2. Calling method with event availabe. */
        createTestRecords();
        Test.startTest();
            List<Time__c> timeList = testUtilsObject.createTimeSlotRecords(new List<Time__c>{new Time__c(Advisor_Name__c = advisorRecord.Id),
                                                                                         new Time__c(Advisor_Name__c = advisorRecord.Id),
                                                                                         new Time__c(Advisor_Name__c = advisorRecord.Id),
                                                                                         new Time__c(Advisor_Name__c = advisorRecord.Id),
                                                                                         new Time__c(Advisor_Name__c = advisorRecord.Id),
                                                                                         new Time__c(Advisor_Name__c = advisorRecord.Id),
                                                                                         new Time__c(Advisor_Name__c = advisorRecord.Id)});
            ApexPages.currentPage().getParameters().put('contactId',contactList[3].Id);
            System.currentPageReference().getParameters().put('rcUserId','12347');
            objextAppointment = new extAppointment();
            objextAppointment.stringobjDate = '06/25/2030'; 
            objextAppointment.appointmentLength = '60';
            objextAppointment.preferredLanguage='en_US';
            objextAppointment.timeZone = 'America/LosAngeles';
            objextAppointment.Times = '16:00';
            objextAppointment.AppointmentLength();
            objextAppointment.AvailabletimeSlot();
            objextAppointment.OnSave();
            objextAppointment = new extAppointment();
            objextAppointment.implementationType = 'Initial Implementation';
        Test.stopTest();   
    }
    
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testCheckMandatoryFields(){  
        /* 1. Calling method. */
        extAppointment objextAppointment = new extAppointment(); 
        objextAppointment.checkMandatoryFields();
        
        /* 2. Calling method with event availabe. */
        createTestRecords();
        Test.startTest();
            List<Time__c> timeList = testUtilsObject.createTimeSlotRecords(new List<Time__c>{new Time__c(Advisor_Name__c = advisorRecord.Id),
                                                                                            new Time__c(Advisor_Name__c = advisorRecord.Id),
                                                                                            new Time__c(Advisor_Name__c = advisorRecord.Id),
                                                                                            new Time__c(Advisor_Name__c = advisorRecord.Id),
                                                                                            new Time__c(Advisor_Name__c = advisorRecord.Id),
                                                                                            new Time__c(Advisor_Name__c = advisorRecord.Id),
                                                                                            new Time__c(Advisor_Name__c = advisorRecord.Id)});
            ApexPages.currentPage().getParameters().put('contactId',contactList[3].Id);
            System.currentPageReference().getParameters().put('rcUserId','12347');
            objextAppointment = new extAppointment();
            
            objextAppointment.checkMandatoryFields();
            
            objextAppointment.stringobjDate = '06/25/2030'; 
            objextAppointment.appointmentLength = '60';
            objextAppointment.preferredLanguage='en_US';
            objextAppointment.timeZone = 'America/LosAngeles';
            objextAppointment.Times = '16:00';
            objextAppointment.AppointmentLength();
            objextAppointment.AvailabletimeSlot();
            objextAppointment.OnSave();
            objextAppointment = new extAppointment();
            objextAppointment.implementationType = 'Initial Implementation';
        Test.stopTest(); 
    }   
    
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testobjectInitializer(){  
        /* 1. Calling method. */
        extAppointment objextAppointment = new extAppointment(); 
        objextAppointment.objectInitializer();
        
        /* 2. Calling method with event availabe. */
        createTestRecords();
        List<Time__c> timeList = testUtilsObject.createTimeSlotRecords(new List<Time__c>{new Time__c(Advisor_Name__c = advisorRecord.Id),
                                                                                         new Time__c(Advisor_Name__c = advisorRecord.Id),
                                                                                         new Time__c(Advisor_Name__c = advisorRecord.Id),
                                                                                         new Time__c(Advisor_Name__c = advisorRecord.Id),
                                                                                         new Time__c(Advisor_Name__c = advisorRecord.Id),
                                                                                         new Time__c(Advisor_Name__c = advisorRecord.Id),
                                                                                         new Time__c(Advisor_Name__c = advisorRecord.Id)});
        ApexPages.currentPage().getParameters().put('contactId',contactList[3].Id);
        System.currentPageReference().getParameters().put('rcUserId','12347');
        objextAppointment = new extAppointment();
        
        objextAppointment.objectInitializer();
        objextAppointment.preferredLanguage='en_US';
        objextAppointment.timeZone = 'America/LosAngeles';
        objextAppointment.Times = '16:00';
        objextAppointment.AppointmentLength();
        objextAppointment.AvailabletimeSlot();
        objextAppointment.stringobjDate='06/25/2030';
        objextAppointment.appointmentLength ='60';
        objextAppointment.objDate = system.today();
        objextAppointment.OnSave();
        Test.startTest();
        objextAppointment = new extAppointment();
        objextAppointment.implementationType = 'Initial Implementation'; 
        //objextAppointment.cancelEvent(); 
        Test.stopTest();       
    }   

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testUpdateImplementation() {
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        Contact testContact = new Contact(FirstName = 'Test', LastName = 'Contact', AccountId = testAccount.Id);
        insert testContact;

        Implementation__c testImplementation = new Implementation__c(Account__c = testAccount.Id);
        insert testImplementation;

        extAppointment appointment = new extAppointment();
        appointment.implementationList = [SELECT Id, Contact__c FROM Implementation__c WHERE Id = :testImplementation.Id];

        appointment.updateImplementation(testContact.Id);

        Implementation__c updatedImplementation = [SELECT Contact__c FROM Implementation__c WHERE Id = :testImplementation.Id];
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testUpdateImplementationOwner() {
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        User testUser = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' LIMIT 1];

        Implementation__c testImplementation = new Implementation__c(Account__c = testAccount.Id, OwnerId = testUser.Id);
        insert testImplementation;

        extAppointment appointment = new extAppointment();
        appointment.implementationList = [SELECT Id, OwnerId, Owner.Name FROM Implementation__c WHERE Id = :testImplementation.Id];

        appointment.updateImplementationOwner(testUser.Id);

        Implementation__c updatedImplementation = [SELECT OwnerId FROM Implementation__c WHERE Id = :testImplementation.Id];
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testReschedule2() {
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        Contact testContact = new Contact(FirstName = 'Test', LastName = 'Contact', AccountId = testAccount.Id);
        insert testContact;

        Event testEvent = new Event(
            Subject = 'Test Event',
            StartDateTime = System.now(),
            EndDateTime = System.now().addHours(1),
            Implementation_Status__c = 'Scheduled',
            Type = 'Initial Implementation',
            OwnerId = UserInfo.getUserId()
        );
        insert testEvent;

        extAppointment appointmentController = new extAppointment();

        appointmentController.contactId = testContact.Id;
        appointmentController.customerId = 'TestCustomerId';
        appointmentController.implementationType = 'Initial Implementation';
        appointmentController.eventList = new List<Event>{testEvent};

        Test.startTest();
        PageReference resultPage = appointmentController.Reschedule();
        Test.stopTest();
    }


    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testGetImplementationTypes() {
        // Create a test contact
        Contact testContact = new Contact(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'testuser@example.com'
        );
        insert testContact;

        Account testAccount = new Account(
            Name = 'Test Account',
            RC_User_ID__c = '12345',
            Number_of_DL_s__c = 10
        );
        insert testAccount;

        testContact.AccountId = testAccount.Id;
        update testContact;

        List<Event> testEvents = new List<Event>();
        for (Integer i = 0; i < 3; i++) {
            Event testEvent = new Event(
                Subject = 'Test Event ' + i,
                StartDateTime = DateTime.now().addDays(i),
                EndDateTime = DateTime.now().addDays(i).addHours(1),
                Type = 'Implementation Type ' + i,
                WhatId = testAccount.Id
            );
            testEvents.add(testEvent);
        }
        insert testEvents;

        extAppointment appointmentController = new extAppointment();

        appointmentController.eventList = testEvents;

        List<SelectOption> implementationTypes = appointmentController.getImplementationTypes();
    }
}