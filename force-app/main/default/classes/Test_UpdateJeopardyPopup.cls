@isTest public class Test_UpdateJeopardyPopup {

    @TestSetup static void createTestData() {
        Case testCase = new Case();
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
        System.runAs(creatorUser) {
            testCase = (Case) new SObjectBuilder(Case.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        Case.Status => 'Work in Progress',
                        Case.Jeopardy_Code__c => 'Hold Customer - Billing Issues',
                        Case.Jeopardy_Description__c => 'Transaction Limit',
                        Case.OwnerId => ownerUser.id
                    }
                )
                .create()
                .getRecord();
        }
        testCase = [SELECT Id, Jeopardy_Code__c, Jeopardy_Description__c, OwnerId, CreatedById, Owner.Email,
                            CaseNumber, CreatedBy.Name, Owner.Name
                    FROM Case
                    LIMIT 1];
        system.debug(testCase);
        jeopardyHelper.createNewJeopardyHistory(testCase, testCase.Jeopardy_Code__c, testCase.Jeopardy_Description__c, null);
        Jeopardy_History__c testJeopHist = [SELECT Jeopardy_Remark__c, Cases__c, CreatedDate
                                            FROM Jeopardy_History__c WHERE Cases__c =: testCase.id
                                            ORDER BY CreatedDate DESC][0];
        testJeopHist.Jeopardy_Remark__c = 'Test Remark';
        update testJeopHist;
    }

    @isTest static void updateOldJeopardy() {
        Case testCase = [SELECT Id, Jeopardy_Code__c, Jeopardy_Description__c FROM Case LIMIT 1];
        Jeopardy_History__c testJeopHist = [SELECT Jeopardy_Remark__c, Cases__c, CreatedDate
                                            FROM Jeopardy_History__c WHERE Cases__c =: testCase.id
                                            ORDER BY CreatedDate DESC];
        PageReference pageRef = Page.UpdateJeopardyPopup;
        pageRef.getParameters().put('id', String.valueOf(testCase.Id));
        Test.setCurrentPage(pageRef);

        Test.startTest();
        ApexPages.StandardController sc = new ApexPages.StandardController(testCase);
        UpdateJeopardyCtrl updateCtrl = new UpdateJeopardyCtrl(sc);
        updateCtrl.jeopardyHistory.Jeopardy_Remark__c = 'Other Remark';
        UpdateJeopardyCtrl.UITheme = 'Theme4d';
        updateCtrl.updateValidation();
        Test.stopTest();

        Jeopardy_History__c comparedJeopHist = [SELECT Jeopardy_Remark__c, Cases__c, CreatedDate
                                                FROM Jeopardy_History__c WHERE Cases__c =: testCase.id
                                                ORDER BY CreatedDate DESC];

        System.assertNotEquals(testJeopHist.Jeopardy_Remark__c, comparedJeopHist.Jeopardy_Remark__c,
                                'the remarks of old and new jeopardy history shouldnt be the same');
        System.assertEquals(comparedJeopHist.Jeopardy_Remark__c, 'Other Remark', 'Remark wasnt as expected');
    }
    
    @isTest static void updateNewJeopardy() {
        Case testCase = [   SELECT Id, Jeopardy_Code__c, Jeopardy_Description__c, OwnerId, CreatedById
                            FROM Case LIMIT 1];
        Case comparedCase = new Case();
        Jeopardy_History__c testJeopHist = [SELECT Jeopardy_Remark__c, Cases__c, CreatedDate
                                            FROM Jeopardy_History__c WHERE Cases__c =: testCase.id
                                            ORDER BY CreatedDate DESC];
        
        PageReference pageRef = Page.UpdateJeopardyPopup;
        pageRef.getParameters().put('id', String.valueOf(testCase.Id));
        Test.setCurrentPage(pageRef);

        Test.startTest();
        ApexPages.StandardController sc = new ApexPages.StandardController(testCase);
        UpdateJeopardyCtrl updateCtrl = new UpdateJeopardyCtrl(sc);
        updateCtrl.caseToUpdate.Jeopardy_Code__c = 'Pending Vendor';
        updateCtrl.caseToUpdate.Jeopardy_Description__c = 'Number Issuance';
        updateCtrl.jeopardyHistory.Jeopardy_Remark__c = 'Other Remark';
        comparedCase = updateCtrl.caseToUpdate;
        UpdateJeopardyCtrl.UITheme = 'Theme3';
        updateCtrl.updateValidation();
        Test.stopTest();

        System.assertNotEquals(comparedCase.Jeopardy_Code__c, testCase.Jeopardy_Code__c,
                              'Code shouldnt be the same in old and new Case');
        System.assertEquals(comparedCase.Jeopardy_Code__c, 'Pending Vendor', 'Code wasnt as expected');
    }
    
    @isTest static void showMessage() {
        String exceptionMsg;
        Case testCase = [SELECT Id, Jeopardy_Code__c, Jeopardy_Description__c FROM Case LIMIT 1];
        
        PageReference pageRef = Page.UpdateJeopardyPopup;
        pageRef.getParameters().put('id', String.valueOf(testCase.Id));
        Test.setCurrentPage(pageRef);

        Test.startTest();
        ApexPages.StandardController sc = new ApexPages.StandardController(testCase);
        UpdateJeopardyCtrl updateCtrl = new UpdateJeopardyCtrl(sc);
        updateCtrl.caseToUpdate.Jeopardy_Description__c = null;
        updateCtrl.caseToUpdate.Jeopardy_Code__c = null;
        UpdateJeopardyCtrl.UITheme = 'Theme3';
        updateCtrl.updateValidation();
        ApexPages.Message[] pageMessages = ApexPages.getMessages();
        for(ApexPages.Message msg : pageMessages) {
            if(msg.getSummary() == 'You must add a Jeopardy Description.') {
                exceptionMsg = msg.getSummary();
            }
        }
        Test.stopTest();

        System.assertNotEquals(exceptionMsg, null, 'There was no exception thrown');
        System.assertEquals(exceptionMsg, 'You must add a Jeopardy Description.', 'The expected error wasnt thrown.');
    }
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest static void testNavToRecforLightning() {
        Case testCase = [SELECT Id, Jeopardy_Code__c, Jeopardy_Description__c FROM Case LIMIT 1];
        PageReference pageRef = Page.UpdateJeopardyPopup;
        pageRef.getParameters().put('id', String.valueOf(testCase.Id));
        Test.setCurrentPage(pageRef);
        ApexPages.StandardController sc = new ApexPages.StandardController(testCase);
        Test.startTest();
    	UpdateJeopardyCtrl.UITheme = 'Theme4d';
        UpdateJeopardyCtrl uj = new UpdateJeopardyCtrl(sc);
        uj.navToRecforLightning();
        UpdateJeopardyCtrl.UITheme = 'Theme3';
        uj.navToRecforLightning();
        uj.wipeOffRemark();
        Test.stopTest();
    }    
}