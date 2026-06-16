@isTest
private class TestSubBrandsMappingSelector {

    @isTest
    private static void testSelectSubBrandsMappingRecords(){
        new SObjectBuilder(SubBrandsMapping__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                SubBrandsMapping__c.Name => 'Test Name',
                SubBrandsMapping__c.Sub_Brand__c => 'SubBrand',
                SubBrandsMapping__c.Brand__c => 'RingCentral Inc.',
                SubBrandsMapping__c.Country__c => 'United States',
                SubBrandsMapping__c.PartnerID__c => '1'
            })
            .create();

        List<SubBrandsMapping__c> subBrandsMap = (List<SubBrandsMapping__c>) new SubBrandsMappingSelector()
            .selectSubBrandsMappingRecords()
            .executeQuery();

        System.assert(subBrandsMap.size() > 0, 'List size should be more than 0');
    }
}