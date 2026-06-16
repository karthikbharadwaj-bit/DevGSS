@isTest
public class Test_BatchJob_CloseIBSCases {

    @isTest
    private static void testPositiveScenario(){
        Case testCase = (Case) new SObjectBuilder(Case.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Case.RecordTypeId => CaseHelper.RT_ID_INTERNAL_BUSINESS_SERVICES,
                Case.Status => CaseHelper.CASE_STATUS_RESOLVED,
                Case.Description => 'Positive Test'
            })
            .create()
            .getRecord(); 
        
        List<sObject> casesToTest = new List<sObject>{testCase};

        Test.startTest();
            BatchJob_CloseIBSCases closeIBSCases = new BatchJob_CloseIBSCases();
            Database.executeBatch(closeIBSCases, 5); 
        Test.stopTest();

        Case caseToCheck = (Case) new CaseSelector()
            .selectCasesByIds(new Set<Id>{testCase.Id})
            .executeQuery()
            .get(0);
        
        Assert.areEqual(CaseHelper.CASE_STATUS_CLOSED_NO_RESPONSE, caseToCheck.Status, 'Case should be closed because change of Status to  \'Resolved\' happened more than 72hrs ago');
    }

    @isTest
    private static void testNegativeWrongTimeOfChange(){
        Case testCase = (Case) new SObjectBuilder(Case.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Case.RecordTypeId => CaseHelper.RT_ID_INTERNAL_BUSINESS_SERVICES,
                Case.Status => CaseHelper.CASE_STATUS_RESOLVED,
                Case.Description => 'Negative test'
            })
            .create()
            .getRecord(); 

        Test.startTest();
            BatchJob_CloseIBSCases closeIBSCases = new BatchJob_CloseIBSCases();
            Database.executeBatch(closeIBSCases, 5); 
        Test.stopTest();

        Case caseToCheck = (Case) new CaseSelector()
            .selectCasesByIds(new Set<Id>{testCase.Id})
            .executeQuery()
            .get(0);
        
        Assert.areEqual(CaseHelper.CASE_STATUS_RESOLVED, caseToCheck.Status, 'Case should not be closed because change of Status to  \'Resolved\' happened less than 72hrs ago');
    }

    @isTest
    private static void testNegativeWrongStatus(){
        Case testCase = (Case) new SObjectBuilder(Case.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Case.RecordTypeId => CaseHelper.RT_ID_INTERNAL_BUSINESS_SERVICES,
                Case.Status => CaseHelper.CASE_STATUS_NEW,
                Case.Description => 'Other Negative Test'
            })
            .create()
            .getRecord(); 

        Test.startTest();
            BatchJob_CloseIBSCases closeIBSCases = new BatchJob_CloseIBSCases();
            Database.executeBatch(closeIBSCases, 5); 
        Test.stopTest();

        Case caseToCheck = (Case) new CaseSelector()
            .selectCasesByIds(new Set<Id>{testCase.Id})
            .executeQuery()
            .get(0);
        
        Assert.areEqual(CaseHelper.CASE_STATUS_NEW, caseToCheck.Status,'Case should not be closed because Status is not \'Resolved\'');
    }

    @isTest
    private static void testNegativeNotIBSCase(){
        Case testCase = (Case) new SObjectBuilder(Case.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Case.RecordTypeId => CaseHelper.RT_ID_SUPPORT_FEEDBACK,
                Case.Status => CaseHelper.CASE_STATUS_NEW,
                Case.Description => 'Other Negative Test'
            })
            .create()
            .getRecord(); 

        Test.startTest();
            BatchJob_CloseIBSCases closeIBSCases = new BatchJob_CloseIBSCases();
            Database.executeBatch(closeIBSCases, 5); 
        Test.stopTest();

        Case caseToCheck = (Case) new CaseSelector()
            .selectCasesByIds(new Set<Id>{testCase.Id})
            .executeQuery()
            .get(0);
        
        Assert.areEqual(CaseHelper.CASE_STATUS_NEW, caseToCheck.Status,'Case should not be closed because it is not IBS case');
    }
}