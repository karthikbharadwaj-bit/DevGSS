@IsTest
private class Test_PartnerNetworkConnectionHelper {
    class SharingException extends Exception {}
    @IsTest
    static void testCreateLocalRecordIdToPnrcMap() {

        List<PartnerNetworkRecordConnection> pnrcList = new List<PartnerNetworkRecordConnection> {
            new PartnerNetworkRecordConnection()
        };
        Test.startTest();
        Map<Id, PartnerNetworkRecordConnection> result =
            PartnerNetworkConnectionHelper.createLocalRecordIdToPnrcMap(pnrcList);
        Test.stopTest();

        System.assertEquals(pnrcList.get(0), result.get(null));
    }

    @IsTest
    static void testGetLocalRecordIdToPnrcMap() {

        Case cs = (Case) new SObjectBuilder(Case.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Case.Status => 'New',
                    Case.RecordTypeId => CaseHelper.RT_ID_INCONTACT_ORDER,
                    Case.Contact_Email__c => 'test@test.tld',
                    Case.AccountId => ValueProviderBuilder.provideGenericParent(Account.SObjectType),
                    Case.Opportunity_Reference__c => ValueProviderBuilder.provideGenericParent(Opportunity.SObjectType)
                }
            )
            .create()
            .getRecord();

        List<Case> caseList = new List<Case> {cs};

        Test.startTest();
        Map<Id, PartnerNetworkRecordConnection> result = PartnerNetworkConnectionHelper.getLocalRecordIdToPnrcMap(caseList);
        PartnerNetworkRecordConnection result2 = PartnerNetworkConnectionHelper.selectPnrcByLocalRecordId(cs.Id);
        Test.stopTest();

        Assert.areEqual(0, result.values().size(), 'Should not be active network case');
        Assert.isNull(result2, 'Should not be active network case');
    }

    @isTest
    private static void testShareSObject() {
        Id testId = (Id) ValueProviderBuilder.provideDummyId(Case.SObjectType).getValue();

        Test.startTest();
        PartnerNetworkRecordConnection res = PartnerNetworkConnectionHelper.buildSObject(null, testId, 'test text');
        PartnerNetworkConnectionHelper.shareSObject(null, testId, 'test text', null);
        Test.stopTest();

        System.assertEquals(res.LocalRecordId, testId, 'LocalRecordId is not equal to test id');
    }

    @isTest
    private static void testHandleSharingError() {
        Triggers.switchOff();
        Opportunity oppty = (Opportunity) new SObjectBuilder(Opportunity.sObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.Name => 'TEST_OPPORTUNITY',
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

        Test.startTest();
        PartnerNetworkConnectionHelper.handleSharingError(oppty.Id, new SharingException());
        Test.stopTest();

        Assert.isNotNull(ChatterHelper.lastFeedItemInput, 'message should be posted to Chatter');
    }
}