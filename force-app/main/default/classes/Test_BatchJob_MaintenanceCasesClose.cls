@isTest
private class Test_BatchJob_MaintenanceCasesClose {
    private static final Integer maintenanceCasesQuantity = 5;
    private static final Integer otherCasesQuantity = 5;

    @testSetup
    private static void testSetup() {
        List<Case> casesToInsert = new List<Case>();
        casesToInsert.addAll(createCases(maintenanceCasesQuantity, CaseHelper.RT_ID_MAINTENANCE_CASE));
        casesToInsert.addAll(createCases(otherCasesQuantity, CaseHelper.RT_ID_SUPPORT_CASE));
        insert casesToInsert;
    }

    @isTest
    private static void testBatchJob_MaintenanceCasesClose() {
        QueryFactory qf = new CaseSelector().selectCasesByStatus(new List<Object>{CaseHelper.CASE_STATUS_CLOSED});

        List<Case> closedCasesBefore = (List<Case>) qf.executeQuery();
        System.assert(closedCasesBefore.isEmpty(), 'Wrong test data was created');

        Test.startTest();
        Database.executeBatch(new BatchJob_MaintenanceCasesClose());
        Test.stopTest();

        List<Case> closedCasesAfter = (List<Case>) qf.executeQuery();
        System.assert(!closedCasesAfter.isEmpty(), 'There are no cases with \"Closed\" status');
        System.assertEquals(maintenanceCasesQuantity, closedCasesAfter.size(), 'Not all cases were processed');
    }

    private static List<Case> createCases(Integer quantity, String recordTypeId) {
        return (List<Case>) new SObjectBuilder(Case.SObjectType)
            .quantity(quantity)
            .setFields(new Map<SObjectField, Object> {
                Case.RecordTypeId => recordTypeId,
                Case.Status => CaseHelper.CASE_STATUS_NEW,
                Case.Subject => ValueProviderBuilder.provideUniqueString('TestSubject_'),
                Case.Date_Assigned__c => ValueProviderBuilder.provideUniqueDate(),
                Case.Date_Completed__c => Date.today(),
                Case.Initial__c => ValueProviderBuilder.provideUniqueString()})
            .build()
            .getRecords();
    }
}