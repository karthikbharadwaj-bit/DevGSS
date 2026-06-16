public inherited sharing class SubBrandsMappingSelector extends SObjectSelector {

    public SubBrandsMappingSelector() {
        super();
    }

    public override Schema.SObjectType getSObjectType() {
        return SubBrandsMapping__c.SObjectType;
    }

    public override List<Schema.SObjectField> getDefaultFieldList() {
        return new List<Schema.SObjectField> {
            SubBrandsMapping__c.Brand__c,
            SubBrandsMapping__c.Country__c,
            SubBrandsMapping__c.PartnerID__c,
            SubBrandsMapping__c.Sub_brand__c,
            SubBrandsMapping__c.CreatedDate,
            SubBrandsMapping__c.LastModifiedDate
        };
    }

    public QueryFactory selectSubBrandsMappingRecords() {
        return newQueryFactory()
            .setFactoryName('selectSubBrandsMappingRecords')
            .selectFields(getDefaultFieldList());
    }
}