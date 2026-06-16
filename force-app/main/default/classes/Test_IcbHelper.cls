@IsTest
private class Test_IcbHelper {
    private static final String TEST_OPPORTUNITY = 'Test Opportunity';
    @TestSetup
    static void createData() {
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
    @isTest
    static void testGetRequestFormLink() {
        ICB_Settings__c settings = (ICB_Settings__c) new SObjectBuilder(ICB_Settings__c.SObjectType)
            .setField(ICB_Settings__c.FormLink__c, 'https://test-form-link.com')
            .create()
            .getRecord();

        Test.startTest();
            Response res = IcbHelper.getRequestFormLink();
        Test.stopTest();

        Assert.isNotNull(res, 'Response must not be null');
        Assert.areEqual(settings.FormLink__c, res.getData('formLink'), 'Wrong link was returned');
    }

    @isTest
    static void testSelectICBCase() {
        Opportunity oppty = selectOpty();
        Case testCase = selectCase(oppty.Id);

        Test.startTest();
        Case newCase = IcbHelper.selectICBCase(oppty);
        Test.stopTest();

        Assert.areEqual(testCase.Id, newCase.Id, 'Case should be selected');
    }

    @isTest
    static void testSelectOpportunityForInContactCaseSharing() {
        Opportunity oppty = selectOpty();
        Test.startTest();
        Opportunity newOppty = IcbHelper.selectOpportunityForInContactCaseSharing(oppty.Id);
        Test.stopTest();

        Assert.areEqual(oppty.Id, newOppty.Id, 'Opportunity should be selected');
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
}