@isTest
private class Test_CaseJeopardyCtrl{

	@isTest	static void testCaseJeopardyCtrlConstructorPositive() {
        Case testCase = (Case) new SObjectBuilder(Case.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Case.Status => 'New',
                    Case.RecordTypeId => CaseHelper.RT_ID_IT_HELPDESK
                }
            )
            .create()
            .getRecord(); 
            
        Jeopardy_History__c testJeopardyHistory = (Jeopardy_History__c) new SObjectBuilder(Jeopardy_History__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Jeopardy_History__c.Jeopardy__c => 'testJeopardyCode',
                    Jeopardy_History__c.Cases__c => testCase.Id
                }
            )
            .create()
            .getRecord();         


        Test.startTest();
        CaseJeopardyCtrl testCJC = new CaseJeopardyCtrl();
        testCJC.caseId = testCase.Id;
        testCJC.jeopardyHistoryId = testJeopardyHistory.Id;
        Test.stopTest();

        System.assertEquals(testCJC.jeopardyCase.Owner.Name, testCase.Owner.Name,
            'Case should have the correct owner assigned');
        System.assertEquals(testCJC.jeopardyHistory.Jeopardy__c, testJeopardyHistory.Jeopardy__c,
            'Jeopardy code should match');
    }



}