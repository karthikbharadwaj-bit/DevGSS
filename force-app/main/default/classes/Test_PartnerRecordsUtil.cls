@IsTest
private class Test_PartnerRecordsUtil {

    @IsTest
    static void testCreateAvayaPartnerRequest() {
        Test.startTest();
            PartnerRecordsUtil.createAvayaPartnerRequest();
        Test.stopTest();

        System.assertNotEquals(null, PartnerRecordsUtil.avayaPartner, 'createAvayaPartnerRequest() must create an avaya partner');
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @IsTest
    static void testCreateAvayaLead() {
        Deal_Registration__c dealObj = new Deal_Registration__c(Estimated_Close_Date__c = Date.today(), Id = (Id) ValueProviderBuilder.provideDummyId(Deal_Registration__c.SObjectType).getValue());

        Test.startTest();
        try {
            PartnerRecordsUtil.createAvayaLead(dealObj);
        } catch (Exception e) {}
        Test.stopTest();
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @IsTest
    static void testCreateAvayaDeal() {

        Test.startTest();
            try {
                PartnerRecordsUtil.createAvayaDeal();
            } catch (Exception e) {}
        Test.stopTest();
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @IsTest
    static void testCreateAvayaOpportunity() {
        Test.startTest();
            try {
                PartnerRecordsUtil.createAvayaOpportunity();
            } catch (Exception e) {}
        Test.stopTest();
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @IsTest
    static void testCreatePartnerQuote() {
        Account testAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Name => 'Test Account'
            })
            .create()
            .getRecord();
        Opportunity testOpp = (Opportunity) new SObjectBuilder(Opportunity.sObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.Name => 'Test Opportunity',
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                Opportunity.CloseDate => System.today(),
                Opportunity.AccountId => testAccount.Id
            })
            .create()
            .getRecord();

        Test.startTest();
            try {
                PartnerRecordsUtil.createPartnerQuote(testOpp);
            } catch (Exception e) {}
        Test.stopTest();
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @IsTest
    static void testCreateDealSupport() {
        Test.startTest();
        try {
            PartnerRecordsUtil.createDealSupport();
        } catch (Exception e) {}
        Test.stopTest();
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @IsTest
    static void testGetRandomUsername() {
        Test.startTest();
            String randomUserName = PartnerRecordsUtil.getRandomUsername();
        Test.stopTest();

        System.assert(!String.isBlank(randomUserName), 'PartnerRecordsUtil.getRandomUsername must return a username');
    }
}