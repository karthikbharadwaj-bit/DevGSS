@isTest
private class Test_CompleteJeopardyPopupCtrl {

    @testSetup static void createTestData(){
        User creatorUser = (User) new SObjectBuilder (User.SObjectType)        
            .setFields(
                new Map<SObjectField, Object>{
                    User.LastName => 'TestcreatorUser',
                    User.Username => 'creatorUser!user@gmail.com',
                    User.Email => 'creatorUser_user@gmail.com',
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
        User ownerUser = (User) new SObjectBuilder (User.SObjectType)        
            .setFields(
                new Map<SObjectField, Object>{
                    User.LastName => 'TestownerUser',
                    User.Username => 'ownerUser!user@gmail.com',
                    User.Email => 'ownerUser_user@gmail.com',
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

        Case testCase = (Case) new SObjectBuilder(Case.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Case.Status => 'Work in Progress',
                    Case.RecordTypeId => CaseHelper.RT_ID_IT_HELPDESK,
                    Case.Jeopardy_Code__c => 'Hold Customer - Billing Issues',
                    Case.Jeopardy_Description__c => 'Transaction Limit',
                    Case.OwnerId => ownerUser.id
                }
            )
            .create()
            .getRecord(); 
    }

    @isTest static void TestCompleteJeopardyPopupCtrlCompleted(){

        Case testCase = [   SELECT Jeopardy_Code__c, Jeopardy_Description__c, CreatedById, OwnerId, Case_Owner_Email__c,
                                    Owner.Name, CaseNumber, CreatedBy.Name, Owner.Email
                            FROM Case
                            LIMIT 1];

        ApexPages.StandardController sc = new ApexPages.StandardController(testCase);
        CompleteJeopardyPopupCtrl cjpe = new CompleteJeopardyPopupCtrl(sc);
        PageReference pageRef = Page.CompleteJeopardyPopup;
        pageRef.getParameters().put('id', String.valueOf(testCase.Id));
        Test.setCurrentPage(pageRef);

        Test.startTest();
        cjpe.caseId = testCase.id;
        cjpe.caseOfJeopardy = testCase;
        CompleteJeopardyPopupCtrl.UITheme = 'Theme4d';
        cjpe.ResolveComp();
        Test.stopTest();

        Case assertcase = [ SELECT Id, Jeopardy_Code__c, Jeopardy_Description__c
                            FROM Case
                            LIMIT 1];

        System.assertEquals(CompleteJeopardyPopupCtrl.JEOPARDYCODECOMPLETED, assertcase.Jeopardy_Code__c,
            'Jeopardy Code should be Completed');
    }

    @isTest static void TestCompleteJeopardyPopupCtrlCancelled(){

        Case testCase = [SELECT Jeopardy_Code__c, Jeopardy_Description__c, CreatedById, OwnerId, Case_Owner_Email__c,
                            Owner.Name, CaseNumber, CreatedBy.Name, Owner.Email
                        FROM Case
                        LIMIT 1];

        ApexPages.StandardController sc = new ApexPages.StandardController(testCase);
        CompleteJeopardyPopupCtrl cjpe = new CompleteJeopardyPopupCtrl(sc);
        PageReference pageRef = Page.CompleteJeopardyPopup;
        pageRef.getParameters().put('id', String.valueOf(testCase.Id));
        Test.setCurrentPage(pageRef);

        Test.startTest();
        cjpe.caseId = testCase.id;
        cjpe.caseOfJeopardy = testCase;
        CompleteJeopardyPopupCtrl.UITheme = 'Theme4d';
        cjpe.ResolveCanc();
        Test.stopTest();

        Case assertcase =   [ SELECT Id, Jeopardy_Code__c,
                                    Jeopardy_Description__c,OwnerId,  CreatedById
                            FROM Case
                            LIMIT 1];

        System.assertEquals(CompleteJeopardyPopupCtrl.JEOPARDYCODECANCELLED, assertcase.Jeopardy_Code__c,
            'Jeopardy Code should be Cancelled');
    }

}