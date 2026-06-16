public inherited sharing class DealSupportSelector extends SObjectSelector {

    public DealSupportSelector() {
        super();
    }

    public DealSupportSelector(String relationshipName, SObjectType relationshipBase) {
        super(relationshipName, relationshipBase);
    }

    public DealSupportSelector(Boolean enforceCRUD, Boolean enforceFLS) {
        super(enforceCRUD, enforceFLS);
    }

    public override Schema.SObjectType getSObjectType()  {
        return Deal_Support__c.SObjectType;
    }

    public override List<Schema.SObjectField> getDefaultFieldList() {
        return new List<Schema.SObjectField> {
            Deal_Support__c.Id,
            Deal_Support__c.Name
        };
    }

    public QueryFactory selectDealSupports() {
        return newQueryFactory()
            .setFactoryName('selectDealSupports')
            .selectFields(getDefaultFieldList());
    }
}