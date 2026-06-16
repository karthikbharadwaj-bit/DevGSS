@isTest
private class Test_ICBNotificationQueueable {
    class ICBNotificationQueueableException extends Exception {}

    static private final String TEST_OPPORTUNITY = 'Test Opportunity';
    @TestSetup
    static void makeData() {
        Triggers.switchOff();
        Opportunity oppty = (Opportunity) new SObjectBuilder(Opportunity.sObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.Name => TEST_OPPORTUNITY,
                Opportunity.CloseDate => System.today().addMonths(1),
                Opportunity.IsMultiProductTechnicalOpportunity__c => false
            })
            .create()
            .getRecord();

        Case testCase = (Case) new SObjectBuilder(Case.sObjectType)
            .setFields(new Map<SObjectField, Object> {
                Case.Opportunity_Reference__c => oppty.Id,
                Case.Provision_Date__c => System.today().addDays(1),
                Case.RecordTypeId=> CaseHelper.RT_ID_INCONTACT_ORDER,
                Case.Description => 'CASE_DESCRIPTION'
            })
            .create()
            .getRecord();
        Triggers.switchOn();
    }

    private static Opportunity selectOpty() {
        return (Opportunity) new ListOptional(new OpportunitySelector()
            .selectOpportunityByName(TEST_OPPORTUNITY)
            .withoutSelectorFieldsIncluded()
            .withoutSelectorOrderByIncluded()
            .selectFields(new List<Schema.SObjectField> {
                Opportunity.Id,
                Opportunity.IsMultiProductTechnicalOpportunity__c
            })
            .executeQuery()
        ).getFirst();
    }

    private static Case selectCase(Id opportuntyId) {
        return (Case) new ListOptional(new CaseSelector()
            .selectInContactCasesForOpportunities(new List<String> { opportuntyId })
            .withoutSelectorFieldsIncluded()
            .withoutSelectorOrderByIncluded()
            .selectFields(new List<Schema.SObjectField> {
                Case.Id,
                Case.Opportunity_Reference__c,
                Case.CaseNumber
            })
            .executeQuery()
        ).getFirst();
    }

    @isTest
    static void testICBNotificationQueueableConstructor() {
        Opportunity oppty = selectOpty();
        Case testCase = selectCase(oppty.Id);

        Test.startTest();
        ICBNotificationQueueable queueable = new ICBNotificationQueueable(oppty, testCase, new ICBNotificationQueueableException());
        Test.stopTest();

        Assert.areEqual(oppty.Id, queueable.targetOpty.Id, 'Opportunity should be set');
        Assert.areEqual(testCase.Id, queueable.icbCase.Id, 'Case should be set');
        Assert.areEqual(IcbHelper.SYNC_WITH_NGBS_ERROR, queueable.errorMessage, 'Error message should be set');
    }

    @isTest
    static void testSendNotifications() {
        Opportunity oppty = selectOpty();
        Case testCase = selectCase(oppty.Id);

        Test.startTest();
        System.enqueueJob(new ICBNotificationQueueable(oppty, testCase, new ICBNotificationQueueableException()));
        Test.stopTest();

        Assert.isNotNull(ChatterHelper.lastFeedItemInput, 'message should be posted to Chatter');
    }
}