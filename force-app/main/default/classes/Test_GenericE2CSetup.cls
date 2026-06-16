@isTest
public class Test_GenericE2CSetup{
    
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    public static void testCaseCreationCorrectFormat(){
        
        Account testAccount = new Account(name = 'Test Account', RC_User_Id__c = 'test');
        insert testAccount;

        String subject = '[Test#INC12345] Test eBonding case';
        system.debug(subject);
        String emailBody = '*Account UID: test\n*RC Partner Brand ID: test\n*Account Name:test\n*Contact Name: test\n*Case Severity: Level - 4 Medium\n*Partner Case Owner Name: Test\n*Partner Case ID:test\n*Partner Service ID:test\n*Partner Case Status:New\n';
        
        Messaging.InboundEmail email = new Messaging.InboundEmail() ;
       	Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        
        email.fromAddress = 'test@test.com';
        email.subject = subject;
        email.plainTextBody = emailBody;
        
        GenericE2Csetup genericSetup = new GenericE2Csetup();
        Test.startTest();
        genericSetup.handleInboundEmail(email, env);
        Test.stopTest();
    }
    
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    public static void testVersatelCaseCreationCorrectFormat(){
        
        Account testAccount = new Account(name = 'Test Account', RC_User_Id__c = 'test');
        insert testAccount;

        String subject = '1&1 Versatel TT-Nr.: 111111111111111 / Test';
        system.debug(subject);
        String emailBody = '*Account UID: test\n*RC Partner Brand ID: test\n*Account Name:test\n*Contact Name: test\n*Case Severity: Level - 4 Medium\n*Partner Case Owner Name: Test\n*Partner Case ID:test\n*Partner Service ID:test\n*Partner Case Status:New\n*How many users are impacted: test\n*When was issue discovered:test\n';
        
        emailBody += '*Were any changes implemented that could have caused this issue If yes what changed and when:test\n*What actions have been taken so far to restore service:test\n*Steps to recreate the issue: test\n*Comment: test';
        
        Messaging.InboundEmail email = new Messaging.InboundEmail() ;
       	Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        
        email.fromAddress = 'test@test.com';
        email.subject = subject;
        email.plainTextBody = emailBody;
        
        GenericE2Csetup genericSetup = new GenericE2Csetup();
        Test.startTest();
        genericSetup.handleInboundEmail(email, env);
        Test.stopTest();
    }
    
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    public static void testInvalidAddressException(){
        
        Account testAccount = new Account(name = 'Test Account', RC_User_Id__c = 'test');
        insert testAccount;

        String subject = '[Test#INC12345] Test eBonding case';
        system.debug(subject);
        String emailBody = '*Account UID: test\n*RC Partner Brand ID: test\n*Account Name:test\n*Contact Name: test\n*Case Severity: Level - 4 Medium\n*Partner Case Owner Name: Test\n*Partner Case ID:test\n*Partner Service ID:test\n*Partner Case Status:New\n';
        
        Messaging.InboundEmail email = new Messaging.InboundEmail() ;
       	Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        
        email.fromAddress = 'test123@test.com';
        email.subject = subject;
        email.plainTextBody = emailBody;
        
        GenericE2Csetup genericSetup = new GenericE2Csetup();
        Test.startTest();
        genericSetup.handleInboundEmail(email, env);
        Test.stopTest();
        
    }
    
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    public static void testInValidSubjectException(){
        
        Account testAccount = new Account(name = 'Test Account', RC_User_Id__c = 'test');
        insert testAccount;
        
        String fromAddress = 'test@test.com';
        String subject = '[Test1234#INC1234]';
        String emailBody = '*Account UID: test\n*RC Partner Brand ID: test\n*Account Name:test\n*Contact Name: test\n*Case Severity: Level - 4 Medium\n*Partner Case Owner Name: Test\n*Partner Case ID:test\n*Partner Service ID:test\n*Partner Case Status:New\n';
        
        Messaging.InboundEmail email = new Messaging.InboundEmail() ;
       	Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        
        email.fromAddress = fromAddress;
        email.subject = subject;
        email.plainTextBody = emailBody;
        
        GenericE2Csetup genericSetup = new GenericE2Csetup();
        Test.startTest();
        
        genericSetup.handleInboundEmail(email, env);
    
        Test.stopTest();
    }
    
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    public static void testKeyFieldSequenceMismatchException(){
        Account testAccount = new Account(name = 'Test Account', RC_User_Id__c = 'test');
        insert testAccount;

        String subject = '[Test#INC1234]';
        String emailBody = '*Account UID: test\n*RC Partner Brand ID: test\n*Contact Name: test\n*Case Severity: Level - 4 Medium\n*Partner Case Owner Name: Test\n*Partner Case ID:test\n*Partner Service ID:test\n*Partner Case Status:New\n';
        
        Messaging.InboundEmail email = new Messaging.InboundEmail() ;
       	Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        
        email.fromAddress = 'test@test.com';
        email.subject = subject;
        email.plainTextBody = emailBody;
        
        GenericE2Csetup genericSetup = new GenericE2Csetup();
        Test.startTest();
        genericSetup.handleInboundEmail(email, env);
        Test.stopTest();
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    public static void testPartnerCaseCommentCreation(){
        
        Account testAccount = new Account(name = 'Test Account', RC_User_Id__c = 'test');
        insert testAccount;
        
        Case newCase = new Case(Subject = '[Test#INC12345] Test eBonding case', AccountId = testAccount.Id, Brand_Identifier__c = 'test');
		insert newCase;

        String subject = '[Test#INC12345] Test eBonding case';
        system.debug(subject);
        String emailBody = '*Account UID: test\n*RC Partner Brand ID: test\n*Account Name:test\n*Contact Name: test\n*Case Severity: Level - 4 Medium\n*Partner Case Owner Name: Test\n*Partner Case ID:test\n*Partner Service ID:test\n*Partner Case Status:New\n';
        
        Messaging.InboundEmail email = new Messaging.InboundEmail() ;
       	Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        
        email.fromAddress = 'test@test.com';
        email.subject = subject;
        email.plainTextBody = emailBody;
        
        GenericE2Csetup genericSetup = new GenericE2Csetup();
        Test.startTest();
        genericSetup.handleInboundEmail(email, env);
        
        List<Case> caseList = [SELECT CaseNumber, subject FROM Case WHERE subject = :subject];

        subject = caseList[0].subject + ' RC Ticket:'+caseList[0].caseNumber+' Comment';
        emailBody = 'test comments from partner';
        
        email.fromAddress = 'test@test.com';
        email.subject = subject;
        email.plainTextBody = emailBody;

        genericSetup.handleInboundEmail(email, env); 
		Test.stopTest();
    }
    
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    public static void testRCTicketFormatMismatchException(){

        String subject = '[Test#INC1234] RC Ticket: 12345#12 Comment';
        String emailBody = 'test comments from partner';
        
        Messaging.InboundEmail email = new Messaging.InboundEmail() ;
       	Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        
        email.fromAddress = 'test@test.com';
        email.subject = subject;
        email.plainTextBody = emailBody;
        
        GenericE2Csetup genericSetup = new GenericE2Csetup();
        genericSetup.handleInboundEmail(email, env);        
        
    }
    
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    public static void testRCTicketNotFoundException(){

        String subject = '[Test#INC1234] RC Ticket: 12345612 Comment';
        String emailBody = 'test comments from partner';
        
        Messaging.InboundEmail email = new Messaging.InboundEmail() ;
       	Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        
        email.fromAddress = 'test@test.com';
        email.subject = subject;
        email.plainTextBody = emailBody;
        
        Test.startTest();
        GenericE2Csetup genericSetup = new GenericE2Csetup();
        genericSetup.handleInboundEmail(email, env);     
        Test.stopTest();
        
    }
    
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    public static void testNotCaseCommentException(){
        
        String subject = '[Test1234#INC1234] RC Ticket: 12345612 Comment';
        String emailBody = 'test comments from partner';
        
        Messaging.InboundEmail email = new Messaging.InboundEmail() ;
       	Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        
        email.fromAddress = 'test@test.com';
        email.subject = subject;
        email.plainTextBody = emailBody;
        
        Test.startTest();
        GenericE2Csetup genericSetup = new GenericE2Csetup();
        genericSetup.handleInboundEmail(email, env);   
        Test.stopTest();
        
    }
    
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    public static void testAccountUIDMismatchException(){
        
        Account testAccount = new Account(name = 'Test Account', RC_User_Id__c = 'test');
        insert testAccount;

        String subject = '[Test#INC12345] Test eBonding case';
        system.debug(subject);
        String emailBody = '*Account UID: test123\n*RC Partner Brand ID: test\n*Account Name:test\n*Contact Name: test\n*Case Severity: Level - 4 Medium\n*Partner Case Owner Name: Test\n*Partner Case ID:test\n*Partner Service ID:test\n*Partner Case Status:New\n';
        
        Messaging.InboundEmail email = new Messaging.InboundEmail() ;
       	Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        
        email.fromAddress = 'test@test.com';
        email.subject = subject;
        email.plainTextBody = emailBody;
        
        GenericE2Csetup genericSetup = new GenericE2Csetup();
        Test.startTest();
        genericSetup.handleInboundEmail(email, env);
        Test.stopTest();
    }
    
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    public static void testSendEmailNotificationToPartner(){
        
        Account testAccount = new Account(name = 'Test Account', RC_User_Id__c = 'test');
        insert testAccount;
        
        Case newCase = new Case(Subject = '[Test#INC12345] Test eBonding case', AccountId = testAccount.Id, Brand_Identifier__c = 'test',Most_Recent_Subject__c = '[Test#INC12345] Test eBonding case');
		insert newCase;

        String subject = '[Test#INC12345] Test eBonding case';
        system.debug(subject);
        String emailBody = '*Account UID: test\n*RC Partner Brand ID: test\n*Account Name:test\n*Contact Name: test\n*Case Severity: Level - 4 Medium\n*Partner Case Owner Name: Test\n*Partner Case ID:test\n*Partner Service ID:test\n*Partner Case Status:New\n';
        
        Messaging.InboundEmail email = new Messaging.InboundEmail() ;
       	Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        
        email.fromAddress = 'test@test.com';
        email.subject = subject;
        email.plainTextBody = emailBody;
        
        GenericE2Csetup genericSetup = new GenericE2Csetup();
        Test.startTest();
        genericSetup.handleInboundEmail(email, env);
        
        List<Case> caseList = [SELECT Id FROM Case WHERE subject = :subject];
        
        CaseComment newComment = new CaseComment();
        newComment.ParentId = caseList[0].Id;
        newComment.CommentBody = 'Test comments by RC agent';
        insert newComment;

    }

}