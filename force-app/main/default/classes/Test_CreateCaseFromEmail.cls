@isTest
public class Test_CreateCaseFromEmail {
    
    private static String ACCOUNT_UID = '12345';
    private static String TEST_CON_EMAIL = 'vendor-email-eb@verizon.com';
    
    @testSetup
    public static void testSetupMethod(){
        
        Account newAcc = new Account();
        newAcc.Name = 'Test Verizon Account';
        newAcc.RC_User_ID__c = ACCOUNT_UID;
        newAcc.RC_Brand__c = 'Verizon';
        
        insert newAcc;
        
        Account acc = [SELECT Id FROM Account WHERE RC_User_ID__c = :ACCOUNT_UID LIMIT 1];
        
        Contact newCon = new Contact();
        newCon.LastName = 'Test Verizon Contact';
        newCon.AccountId = acc.Id;
        newCon.Email = TEST_CON_EMAIL;
        
        insert newCon;
        
    }
	
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    public static void testCaseCreationAndCaseComment(){
        
         // Create a new email and envelope object
    	Messaging.InboundEmail email  = new Messaging.InboundEmail();
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        
        email.fromAddress = 'test@verizon.com';
        email.subject = '(9513083112014) - test verizon issue';
        email.htmlBody = '*Account UID:'+ACCOUNT_UID+'\n*Account Name:Test Verizon Account\n*Case Severity: Level 5 - Low\n*Verizon Agent Name: Test Agent'+
							  '\n*Ticket Category: API Integrations\n*Trouble Type: Conferencing issues\n*How many users are impacted:100'+
							  '\n*When was the issue discovered: 06-08-2021\n*Were any changes recently implemented that could have caused this issue If yes, what changed and when: test changes\ntest changes'+
                              '\n*What actions have been taken so far to restore service: test changes\n*Steps to recreate the issue (use Work Info as needed): test changes';
        
        createCaseFromEmail newEmail = new createCaseFromEmail();
        
        Test.startTest();
        Messaging.InboundEmailResult result = newEmail.handleInboundEmail(email, env);
        Case newCase = [SELECT Id,CaseNumber FROM Case WHERE Partner_Case_Number__c = '9513083112014' LIMIT 1];
        
        //case comment creation
        email.subject = '(9513083112014) - test verizon issue - Vendor Ticket:'+newCase.CaseNumber+' Verizon comment';
        email.plainTextBody = 'Verizon Test Comment';
        Messaging.InboundEmailResult resultCaseComment = newEmail.handleInboundEmail(email, env);
        Test.stopTest();
         
    }
    
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    public static void testETMSTicketNumberExceptionHandling(){
        
        Messaging.InboundEmail email  = new Messaging.InboundEmail();
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        
        //ETMS Ticket number greater than 13
        email.fromAddress = 'test@verizon.com';
        email.subject = '(9513083112014234) - test verizon issue';
        
        email.plainTextBody = '*Account UID:'+ACCOUNT_UID+'\n*Account Name:Test Verizon Account\n*Case Severity: Level 5 - Low\n*Verizon Agent Name: Test Agent'+
							  '\n*Ticket Category: API Integrations\n*Trouble Type: Conferencing issues\n*How many users are impacted:100'+
							  '\n*When was the issue discovered: 06-08-2021\n*Were any changes recently implemented that could have caused this issue If yes, what changed and when: test changes\ntest changes'+
                              '\n*What actions have been taken so far to restore service: test changes\n*Steps to recreate the issue (use Work Info as needed): test changes';
         
        createCaseFromEmail newEmail = new createCaseFromEmail();
        
        Test.startTest();
        Messaging.InboundEmailResult result = newEmail.handleInboundEmail(email, env);
        
        //No ETMS Ticket Number Present
        email.subject = 'No ETMS Ticket Number - test verizon issue';
        Messaging.InboundEmailResult resultNoTicketNumber = newEmail.handleInboundEmail(email, env);
        Test.stopTest();
        
    }
    
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    public static void testCaseMismatchException(){
        
        Messaging.InboundEmail email  = new Messaging.InboundEmail();
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        
        //Case already exists, trying to create a new case with already existing case
        email.fromAddress = 'test@verizon.com';
        email.subject = '(9513083112014) - test verizon issue';
        
        email.plainTextBody = '*Account UID:'+ACCOUNT_UID+'\n*Account Name:Test Verizon Account\n*Case Severity: Level 5 - Low\n*Verizon Agent Name: Test Agent'+
							  '\n*Ticket Category: API Integrations\n*Trouble Type: Conferencing issues\n*How many users are impacted:100'+
							  '\n*When was the issue discovered: 06-08-2021\n*Were any changes recently implemented that could have caused this issue If yes, what changed and when: test changes\ntest changes'+
                              '\n*What actions have been taken so far to restore service: test changes\n*Steps to recreate the issue (use Work Info as needed): test changes';
         
        createCaseFromEmail newEmail = new createCaseFromEmail();
        
        Test.startTest();
        Messaging.InboundEmailResult result = newEmail.handleInboundEmail(email, env);
        
        //No ETMS Ticket Number Present and no RC case number present
        email.subject = 'test verizon issue';
        Messaging.InboundEmailResult resultNoTicketNumber = newEmail.handleInboundEmail(email, env);
        
        //No Matching RC Case number included
        Case newCase = [SELECT Id,CaseNumber FROM Case WHERE Partner_Case_Number__c = '9513083112014' LIMIT 1];
        email.subject = '(2291803940826) - test verizon issue Vendor Ticket:'+newCase.CaseNumber+' Verizon Comment';
        Messaging.InboundEmailResult resultNoMatchingCase = newEmail.handleInboundEmail(email, env);
        Test.stopTest();
    }
    
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    public static void testEmailTemplateMismatch(){
        
        Messaging.InboundEmail email  = new Messaging.InboundEmail();
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        
        //Case already exists, trying to create a new case with already existing case
        email.fromAddress = 'test@verizon.com';
        email.subject = '(9513083112014) - test verizon issue';
        
        email.plainTextBody = '*Account UID:'+ACCOUNT_UID+'\n*Account Name:Test Verizon Account\n*Case Severity: Level 5 - Low\n*Verizon Agent Name: Test Agent'+
							  '\n*Ticket Category: API Integrations\n*Trouble Type: Conferencing issues\n*How many users are impacted:100'+
							  '\n*Were any changes recently implemented that could have caused this issue If yes, what changed and when: test changes\ntest changes'+
                              '\n*What actions have been taken so far to restore service: test changes\n*Steps to recreate the issue (use Work Info as needed): test changes';
        
        createCaseFromEmail newEmail = new createCaseFromEmail();
        
        Test.startTest();
        Messaging.InboundEmailResult result = newEmail.handleInboundEmail(email, env);
        
        email.htmlBody = '<p>Account UID:'+ACCOUNT_UID+'\n*Account Name:Test Verizon Account\n*Case Severity: Level 5 - Low\n*Verizon Agent Name: Test Agent'+
							  '\n*Email: verizon@support.com\n*Ticket Category: API Integrations\n*Trouble Type: Conferencing issues\n*How many users are impacted:100'+
							  '\n*When was the issue discovered: 06-08-2021\n*Were any changes recently implemented that could have caused this issue If yes, what changed and when: test changes\ntest changes'+
                              '\n*What actions have been taken so far to restore service: test changes\n*Steps to recreate the issue (use Work Info as needed): test changes</p>';
        
        Messaging.InboundEmailResult resultEmailMismatch = newEmail.handleInboundEmail(email, env);
        Test.stopTest();
    }
    
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    public static void testSubjectVerification(){
        
        Messaging.InboundEmail email  = new Messaging.InboundEmail();
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();

        email.fromAddress = 'test@verizon.com';
        email.subject = '(9513083112014) - test verizon issue Vendor Ticket: 1234';
        email.htmlBody = '<b>Verification Status:</b> denied';
        
       	createCaseFromEmail newCaseComment = new createCaseFromEmail();
        Messaging.InboundEmailResult caseCommentResult = newCaseComment.handleInboundEmail(email, env);   
        
        email.subject = '(9513083112014) - test verizon issue Vendor Ticket: 1234457#';
        
        createCaseFromEmail newComment = new createCaseFromEmail();
        Messaging.InboundEmailResult result = newCaseComment.handleInboundEmail(email, env);
    }
    
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    public static void testCaseResolutionDenied(){
                Messaging.InboundEmail email  = new Messaging.InboundEmail();
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        
        //Case already exists, trying to create a new case with already existing case
        email.fromAddress = 'test@verizon.com';
        email.subject = '(9513083112014) - test verizon issue';
        
        email.plainTextBody = '*Account UID:'+ACCOUNT_UID+'\n*Account Name:Test Verizon Account\n*Case Severity: Level 5 - Low\n*Verizon Agent Name: Test Agent'+
							  '\n*Ticket Category: API Integrations\n*Trouble Type: Conferencing issues\n*How many users are impacted:100'+
							  '\n*When was the issue discovered: 06-08-2021\n*Were any changes recently implemented that could have caused this issue If yes, what changed and when: test changes\ntest changes'+
                              '\n*What actions have been taken so far to restore service: test changes\n*Steps to recreate the issue (use Work Info as needed): test changes';
         
        createCaseFromEmail newEmail = new createCaseFromEmail();
        
        Test.startTest();
        Messaging.InboundEmailResult result = newEmail.handleInboundEmail(email, env);
        
        Case newCase = [SELECT Id,CaseNumber,status,Root_Cause__c FROM Case WHERE Partner_Case_Number__c = '9513083112014' LIMIT 1];
        newCase.Status = 'Waiting';
        newCase.Root_Cause__c = 'Test';
        update newCase;
        
        email.subject = '(9513083112014) - test verizon issue Vendor Ticket:'+newCase.CaseNumber+' Verizon Comment';
        email.plainTextBody = 'Verification Status: denied';
        Messaging.InboundEmailResult resultNoMatchingCase = newEmail.handleInboundEmail(email, env);
        Test.stopTest();
    }
}