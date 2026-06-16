@isTest
private class Test_CaseRouting {

    private static final String SUPPORT_TYPE = 'testSupportType';
    private static final String GROUP_NAME = 'testGroup';

    @isTest
    static void testExecute() {

        User testUser = (User) new SObjectBuilder(User.sObjectType).create().getRecord();

        Group testGroup = (Group) new SObjectBuilder(Group.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Group.Name => GROUP_NAME,
                Group.DeveloperName => GROUP_NAME,
                Group.Type => 'Regular'
            })
            .create()
            .getRecord();
        
        CaseRouting.routingBySupportTypeSettings = (List<CaseRoutingBySupportType__mdt>) new SObjectBuilder(CaseRoutingBySupportType__mdt.sObjectType)
            .setFields(new Map<SObjectField, Object> {
                CaseRoutingBySupportType__mdt.SupportType__c => ValueProviderBuilder.provideList(new List<String> {'unrelated_type', SUPPORT_TYPE}),
                CaseRoutingBySupportType__mdt.Owner__c => GROUP_NAME,
                CaseRoutingBySupportType__mdt.IsCaseCategoryOverride__c => true,
                CaseRoutingBySupportType__mdt.CaseRecordType__c => ValueProviderBuilder.provideList(new List<String> {CaseHelper.RT_NAME_FINANCE, CaseHelper.RT_NAME_PROFESSIONAL_SERVICES}),
                CaseRoutingBySupportType__mdt.ExecutionOrder__c => ValueProviderBuilder.provideList(new List<Integer> {1, 2})
            })
            .quantity(2)
            .build()
            .getRecords();

        System.runAs(testUser) {

            Account testAcc = (Account) new SObjectBuilder(Account.SObjectType)
                .setFields(new Map<SObjectField, Object> {
                    Account.Name => 'test account'
                })
                .create()
                .getRecord();
    
            Entitlement testEnt = (Entitlement) new SObjectBuilder(Entitlement.SObjectType)
                .setFields(new Map<SObjectField, Object> {
                    Entitlement.AccountId => testAcc.Id,
                    Entitlement.Name => 'Advanced Support',
                    Entitlement.Type => SUPPORT_TYPE,
                    Entitlement.StartDate => Date.today().addDays(-1)
                })
                .create()
                .getRecord();
    
            Test.startTest();
            Case testCase = new Case(AccountId = testAcc.Id);
            CaseRouting.execute(new List<Case>{ testCase }, new Map<String, Group>{ GROUP_NAME.toLowerCase() => testGroup });
            Test.stopTest();
    
            System.assertEquals(testGroup.Id, testCase.OwnerId, 'Case was not routed to the expected group');
            System.assertEquals(CaseHelper.RT_ID_PROFESSIONAL_SERVICES, testCase.RecordTypeId, 'Case was not routed to the expected record type');
            System.assertEquals(SUPPORT_TYPE, testCase.Case_Category__c, 'Case was not routed to the expected record type');
        }
    }
}