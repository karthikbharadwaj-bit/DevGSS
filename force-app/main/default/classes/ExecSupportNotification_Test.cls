@isTest
private class ExecSupportNotification_Test {
	@testSetup  
    static void setup() {
        Triggers.switchOff(); 
        Profile p = [select id from profile where name='System Administrator'];

        User testManager = new User(alias = 'm111', email='m111@testorg.com',
                                 emailencodingkey='UTF-8', lastname='MTesting11', languagelocalekey='en_US',
                                 localesidkey='en_US', profileid = p.Id, country='United States',
                                 timezonesidkey='America/Los_Angeles', username='m111@testorg.com');
        insert testManager;

        User testUser = new User(alias = 'u111', email='u111@testorg.com',
                                 emailencodingkey='UTF-8', lastname='UTesting11', languagelocalekey='en_US',
                                 localesidkey='en_US', profileid = p.Id, country='United States',
                                 timezonesidkey='America/Los_Angeles', username='u111@testorg.com', managerId = testManager.Id);
        insert testUser;

        User testExec = new User(alias = 'e111', email='e111@testorg.com',
                                 emailencodingkey='UTF-8', lastname='ETesting11', languagelocalekey='en_US',
                                 localesidkey='en_US', profileid = p.Id, country='United States',
                                 timezonesidkey='America/Los_Angeles', username='e111@testorg.com');
        insert testExec;

        Opportunity o = new Opportunity();
        o.StageName = '1. Qualify';
        o.CloseDate = system.today();
        o.ForecastCategoryName = 'Commit';
        o.OwnerId = testUser.Id;
        o.RC_Executive_Alignment__c = testExec.Id;
        o.Name = 'TEST OPP';

        insert o;

        List<Case> casesForInsert = new List<Case>();

        Case c = new Case();
        c.Subject = 'TEST CASE';
        c.OwnerId = testUser.Id;
        c.Description = 'testing';
        c.Status ='New';
        c.Priority = 'Medium';
        c.Origin = 'Email';
        casesForInsert.add(c);

        Case c1 = new Case();
        c1.Subject = 'TEST CASE 1';
        c1.OwnerId = testUser.Id;
        c1.Description = 'testing';
        c1.Status ='New';
        c1.Priority = 'Medium';
        c1.Origin = 'Email';
        casesForInsert.add(c1);

        Case c2 = new Case();
        c2.Subject = 'TEST CASE 2';
        c2.OwnerId = testUser.Id;
        c2.Description = 'testing';
        c2.Status ='New';
        c2.Priority = 'Medium';
        c2.Origin = 'Email';
        casesForInsert.add(c2);

        Case c3 = new Case();
        c3.Subject = 'TEST CASE 3';
        c3.OwnerId = testUser.Id;
        c3.Description = 'testing';
        c3.Status ='New';
        c3.Priority = 'Medium';
        c3.Origin = 'Email';
        casesForInsert.add(c3);

        TriggerHandler.BY_PASS_CASE_ON_INSERT();
        insert casesForInsert;
        Triggers.switchOn();
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testExecNotif(){
        Opportunity o = [SELECT Id FROM Opportunity WHERE Name = 'TEST OPP' LIMIT 1];
        ExecSupportNotification.sendSupportNotification(new List<Id>{o.Id});
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testEmailMsgTracking(){
        Triggers.switchOff(); 
        Test.startTest();
        TriggerHandler.BY_PASS_CASE_ON_INSERT();

        Opportunity o = [SELECT Id FROM Opportunity WHERE Name = 'TEST OPP' LIMIT 1];
        Task t = new Task();
        t.Subject = 'Email: Executive Sponsorship Requested';
        t.Description = 'test';
        t.whatid = o.id;
        insert t;


        Case c = [SELECT Id FROM Case WHERE Subject = 'TEST CASE' LIMIT 1];
        EmailMessage newMsg = new EmailMessage();
        newMsg.ParentId = c.Id;
        //newMsg.RelatedToId = c.Id;
        newMsg.Subject = 'Executive Sponsorship Requested Notif';
        newMsg.MessageIdentifier = 'TESTTRDID000';
        newMsg.ThreadIdentifier = 'TESTTRDID000';
        newMSg.HtmlBody = '<a href="'+URL.getOrgDomainUrl().toExternalForm() + '/'+o.id+'">';
        newMsg.Incoming = true;
        insert newMsg;



        EmailMessageTriggerHandler.handleExecNotifTracking(new Set<Id>{newMsg.Id});
        Test.StopTest();

    }
    
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testEmailMsgTracking2(){
        Triggers.switchOff(); 
        Test.startTest();        
        Opportunity o = [SELECT Id FROM Opportunity WHERE Name = 'TEST OPP' LIMIT 1];

        Case c1 = [SELECT Id FROM Case WHERE Subject = 'TEST CASE 1' LIMIT 1];

        EmailMessage newMsg1 = new EmailMessage();
        newMsg1.ParentId = c1.Id;
        //newMsg1.RelatedToId = c1.Id;
        newMsg1.Subject = 'RE: Executive Sponsorship Requested Notif';
        newMsg1.MessageIdentifier = 'TESTMSGID200';
        newMsg1.ThreadIdentifier = 'TESTTRDID000';
        insert newMsg1;

        EmailMessageTriggerHandler.handleExecNotifTracking(new Set<Id>{newMsg1.Id});
        Test.stopTest();

    }
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testEmailMsgTracking3(){
        Triggers.switchOff(); 
        Test.startTest();
        Opportunity o = [SELECT Id FROM Opportunity WHERE Name = 'TEST OPP' LIMIT 1];

		Case c2 = [SELECT Id FROM Case WHERE Subject = 'TEST CASE 2' LIMIT 1];
        EmailMessage newMsg2 = new EmailMessage();
        newMsg2.ParentId = c2.Id;
        //newMsg2.RelatedToId = c2.Id;
        newMsg2.Subject = 'FOR DELETE - Executive Sponsorship Requested Notif';
        newMsg2.MessageIdentifier = 'TESTMSGID300';
        newMsg2.ThreadIdentifier = 'TESTTRDID100';
        insert newMsg2;

        Task t1 = new Task();
        t1.Subject = 'Email: Executive Sponsorship Requested';
        t1.Description = 'test';
        t1.whatid = o.id;
        insert t1;

        //Opportunity o = [SELECT Id FROM Opportunity WHERE Name = 'TEST OPP' LIMIT 1];
        Case c3 = [SELECT Id FROM Case WHERE Subject = 'TEST CASE 3' LIMIT 1];
        EmailMessage newMsg3 = new EmailMessage();
        newMsg3.ParentId = c3.Id;
        //newMsg3.RelatedToId = o.Id;
        newMsg3.Subject = 'Executive Sponsorship Requested Notif';
        newMsg3.MessageIdentifier = 'TESTMSGID300';
        newMsg3.ThreadIdentifier = 'TESTTRDID100';
        newMsg3.activityid = t1.id;
        insert newMsg3;

        Attachment att = new Attachment();
        att.ParentId = newMsg2.Id;
        att.Name='Unit Test Attachment';
        Blob bodyBlob=Blob.valueOf('Unit Test Attachment Body');
        att.body=bodyBlob;
        insert att;
        Test.stopTest();

        EmailMessageTriggerHandler.handleAttachmentsExecSupport(new Set<Id> {att.id});

    }
}