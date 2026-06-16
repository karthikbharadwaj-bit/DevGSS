@isTest
public class Test_BrandPartnerFieldPopulationHandler {

    @testSetup
    static void setup(){
        new SObjectBuilder(Account.sObjectType)
            .setField(Account.RC_Brand__c, ValueProviderBuilder.provideList(new List<Object>{
                RingCentralHelper.BRAND_AVAYA, RingCentralHelper.BRAND_RINGCENTRAL}))
            .quantity(2)
            .create();
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    private static void testFieldPopulationForAgentCredit() {
        testFieldPopulation(Agent_Credit__c.sObjectType);
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    private static void testFieldPopulationForApproval() {
        testFieldPopulation(Approval__c.sObjectType);
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    private static void testFieldPopulationForDemandFunnel() {
        testFieldPopulation(Demand_Funnel__c.sObjectType);
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    private static void testFieldPopulationForImplementation() {
        testFieldPopulation(Implementation__c.sObjectType);
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    private static void testFieldPopulationForOrder() {
        testFieldPopulation(Order__c.sObjectType);
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    private static void testFieldPopulationForPhase() {
        testFieldPopulation(Phase__c.sObjectType);
    }

    private static void testFieldPopulation(SObjectType soType) {

        System.assert(BrandPartnerFieldPopulationHandler.relatedSoTypes.contains(soType),
            'BrandPartnerFieldPopulationHandler do not handle ' + soType);

        Id avayaAccId;
        Id rcAccId;
        for (Account acc : (Account[]) new AccountSelector()
                                        .selectAccounts().selectField(Account.RC_Brand__c).executeQuery()
        ) {
            if (acc.RC_Brand__c == RingCentralHelper.BRAND_AVAYA) {
                avayaAccId = acc.Id;
            } else if (acc.RC_Brand__c == RingCentralHelper.BRAND_RINGCENTRAL) {
                rcAccId = acc.Id;
            }
        }

        List<SObject> newRecords = createRecords(soType, avayaAccId, rcAccId);

        List<SObject> recordsToAssert = BrandPartnerFieldPopulationHandler.getRelatedRecordsQuery(soType).executeQuery();
        System.assertEquals(3, recordsToAssert.size());
        assertBrandPartnerFieldValues(recordsToAssert);

        // TC_4 - update Demand_Funnel__c.Account__c Avaya -> Ringcentral
        newRecords[0].put('Account__c', rcAccId);
        // TC_5 - update Demand_Funnel__c.Account__c Ringcentral -> null
        newRecords[1].put('Account__c', null);
        // TC_6 - update Demand_Funnel__c.Account__c null -> Avaya
        newRecords[2].put('Account__c', avayaAccId);
        update newRecords;

        recordsToAssert = BrandPartnerFieldPopulationHandler.getRelatedRecordsQuery(soType).executeQuery();
        System.assertEquals(3, recordsToAssert.size());
        assertBrandPartnerFieldValues(recordsToAssert);
    }

    public static List<SObject> createRecords(SObjectType soType, Id avayaAccId, Id rcAccId) {
        // TC_1 - insert without populated Account__c
        // TC_2 - insert with Ringcentral in Account__c
        // TC_3 - insert with Avaya in Account__c
        return new SObjectBuilder(soType)
            .setField(soType.getDescribe().fields.getMap().get('Account__c'),
                new ValueProvider.ListProvider(new List<Object>{avayaAccId, rcAccId, null}))
            .quantity(3)
            .create()
            .getRecords();
    }

    public static void assertBrandPartnerFieldValues(List<SObject> records) {
        if (records.isEmpty()) {
            return;
        }
        String errorMessage = 'Incorrect Brand_Partner__c field population for ' + records[0].getSObjectType();
        for (SObject record : records) {
            if (record.get('Account__c') != null 
                && ((Account)record.getSObject('Account__r')).RC_Brand__c == RingCentralHelper.BRAND_AVAYA
            ) {
                System.assertEquals('Avaya', record.get('Brand_Partner__c'), errorMessage);
            } else {
                System.assertEquals('None', record.get('Brand_Partner__c'), errorMessage);
            }
        }
    }

}