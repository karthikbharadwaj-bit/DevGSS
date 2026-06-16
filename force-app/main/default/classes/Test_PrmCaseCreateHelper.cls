@IsTest
private class Test_PrmCaseCreateHelper {
    @IsTest
    static void testGetLayout() {
        Response resp = PrmCaseCreateHelper.getLayout();
        String layout = (String) resp.data.get('layout');
        System.assert(!String.isBlank(layout), 'Layout related serialized data should be returned');
    }

    @IsTest
    static void testCreateCases() {
        Account testAcc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => 'Test Account'
                }
            )
            .create()
            .getRecord();

        Opportunity testOpp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.AccountId => testAcc.Id,
                    Opportunity.Name => 'TestOpportunity',
                    Opportunity.Total_MRR__c => 100
                }
            )
            .create()
            .getRecord();

        Case testCase = (Case) new SObjectBuilder(Case.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Case.Status => CaseHelper.CASE_STATUS_NEW,
                    Case.AccountId => testAcc.Id,
                    Case.Opportunity_Reference__c => testOpp.Id,
                    Case.RecordTypeId => CaseHelper.RT_ID_DEAL_AND_ORDER_SUPPORT,
                    Case.Case_Category__c => 'Ignite Partner',
                    Case.Case_Subcategory__c => 'Generate a Contract'
                }
            )
            .build()
            .getRecord();
        Test.startTest();
            PrmCaseCreateHelper.createCases(JSON.serialize(new List<Case>{testCase}));
            Case reselectedCase = (Case) new ListOptional(new CaseSelector()
                .selectCasesDefault()
                .executeQuery()
            ).getFirst();
            Group ipaTeamQueue = (Group) new ListOptional(new GroupSelector()
                .selectQueueByName('IPA Team')
                .executeQuery()
            ).getFirst();
        Test.stopTest();
        System.assert(ipaTeamQueue != null, 'Was selected IPA Team queue');
        System.assert(reselectedCase != null, 'Case was reselected');
        System.assertEquals(reselectedCase.OwnerId, ipaTeamQueue.Id, 'IPA Team queue must be case owner');
    }
}