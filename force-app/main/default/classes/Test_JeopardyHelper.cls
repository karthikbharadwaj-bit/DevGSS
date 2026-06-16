@isTest
private class Test_JeopardyHelper{

    @testSetup static void createTestData(){
        Case setupCase = new Case();
        User creator = (User) new SObjectBuilder (User.SObjectType)        
            .setFields(
                new Map<SObjectField, Object>{
                    User.LastName => 'TestTestCreator',
                    User.Username => 'TestCreator!user@gmail.com',
                    User.Email => 'TestCreator_user@gmail.com',
                    User.Alias => 'Test',
                    User.TimeZoneSidKey => 'America/Los_Angeles',
                    User.ManagerId => UserInfo.getUserId(),
                    User.LocaleSidKey => 'en_US',
                    User.EmailEncodingKey => 'UTF-8',
                    User.ProfileId => [SELECT Id, Name FROM Profile WHERE Name = 'System Administrator'].Id,
                    User.LanguageLocaleKey => 'en_US',
                    User.Hierarchy_Role__c => 'Sales Rep'
                }
            )
            .create()
            .getRecord(); 
        System.runAs(creator){
            setupCase = (Case) new SObjectBuilder(Case.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        Case.Status => 'New',
                        Case.RecordTypeId => CaseHelper.RT_ID_IT_HELPDESK
                    }
                )
                .create()
                .getRecord();
        }

        setupCase.Status = 'Work In Progress';
        setupCase.Jeopardy_Code__c = 'Pending Vendor';
        setupCase.Jeopardy_Description__c = 'Number Issuance';
        setupCase.RecordTypeId = [  SELECT Id
                                    FROM RecordType
                                    WHERE Name = 'System Operations'
                                    LIMIT 1].id;
        User owner = (User) new SObjectBuilder (User.SObjectType)        
            .setFields(
                new Map<SObjectField, Object>{
                    User.LastName => 'TestTestOwner',
                    User.Username => 'TestOwner!user@gmail.com',
                    User.Email => 'TestOwner_user@gmail.com',
                    User.Alias => 'Test',
                    User.TimeZoneSidKey => 'America/Los_Angeles',
                    User.ManagerId => UserInfo.getUserId(),
                    User.LocaleSidKey => 'en_US',
                    User.EmailEncodingKey => 'UTF-8',
                    User.ProfileId => [SELECT Id, Name FROM Profile WHERE Name = 'System Administrator'].Id,
                    User.LanguageLocaleKey => 'en_US',
                    User.Hierarchy_Role__c => 'Sales Rep'
                }
            )
            .create()
            .getRecord(); 
        setupCase.OwnerId = owner.id;
        update setupCase;
    }
    
    @isTest static void test_JH_startDate() {
        Case c = [  SELECT Id, Status, Jeopardy_Code__c, Jeopardy_Description__c, OwnerId, CreatedById,
                        Owner.Email, CaseNumber, CreatedBy.Name, Owner.Name
                    FROM Case
                    WHERE Status = 'Work In Progress'
                    LIMIT 1];

        Test.startTest();
        JeopardyHelper.createNewJeopardyHistory(c, c.Jeopardy_Code__c, c.Jeopardy_Description__c, null);
        Test.stopTest();
        
        List<Jeopardy_History__c> jhList = [SELECT Date_Start__c
                                            FROM Jeopardy_History__c
                                            WHERE Cases__c =: c.Id];
        System.assert(!jhList.isEmpty(), 'There should have been an inserted jeopardy history');
        Jeopardy_History__c jh = jhList[0];
        System.assertEquals(jh.Date_Start__c, Date.Today(), 'The start date of the' +
                                    'jeopardy history should be today');
	}

    @isTest static void test_JH_completedOrCancelled() {
        Case c = [  SELECT Id, Status, Jeopardy_Code__c, Jeopardy_Description__c, OwnerId, CreatedById
                    FROM Case
                    WHERE Status = 'Work In Progress'
                    LIMIT 1];
        c.Jeopardy_Code__c = 'Completed';
        
        Test.startTest();
        JeopardyHelper.createNewJeopardyHistory(c, c.Jeopardy_Code__c, c.Jeopardy_Description__c, null);
        Test.stopTest();
        
        Jeopardy_History__c completedJH = [ SELECT Sub_Jeopardy__c, Jeopardy__c, Date_Closed__c  
                                            FROM Jeopardy_History__c
                                            WHERE Cases__c =: c.Id
                                            LIMIT 1];
        System.assertEquals(completedJH.Sub_Jeopardy__c, null, 'Jeopardy Description of completed should be null');
        System.assertEquals(completedJH.Date_Closed__c, Date.today(), 'Completed jeopardy should have been closed');
    }
    
    @isTest static void test_JH_mails() {
        Case c = [  SELECT Id, Status, Jeopardy_Code__c, CreatedById, Jeopardy_Description__c, OwnerId, Owner.Email,
                        CaseNumber, CreatedBy.Name, Owner.Name
                    FROM Case
                    WHERE Status = 'Work In Progress'
                    LIMIT 1];
        Map<id, case> caseMap = new Map<Id, Case>();
        Test.startTest();
        JeopardyHelper.createNewJeopardyHistory(c, c.Jeopardy_Code__c, c.Jeopardy_Description__c, null);
        Test.stopTest();
        Jeopardy_History__c jh = [  SELECT Jeopardy1_4mail__c, Jeopardy5Email__c
                                    FROM Jeopardy_History__c
                                    LIMIT 1];
        System.assertEquals(jh.Jeopardy1_4mail__c, 'testcreator_user@gmail.com', 'Email should match manager email');
        System.assertEquals(jh.Jeopardy5Email__c, 'testowner_user@gmail.com', 'Email should match creator email');
    }

    @isTest
    private static void testUpdateDescriptionCodeForCompletedCase() {
        Case testCase = (Case) new SObjectBuilder(Case.SObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    Case.Jeopardy_Code__c => 'Completed',
                    Case.Jeopardy_Description__c => 'Test Description'
                }
            )
            .build()
            .getRecord();

        System.assertEquals(testCase.Jeopardy_Description__c, 'Test Description', 'Jeopardy Description should be defined');

        Test.startTest();
        JeopardyHelper.UpdateDescriptionCodeForCompletedCase(new Map<Id, Case> { testCase.Id => testCase });
        Test.stopTest();

        System.assertEquals(testCase.Jeopardy_Description__c, null, 'Jeopardy Description should be null');
    }

}