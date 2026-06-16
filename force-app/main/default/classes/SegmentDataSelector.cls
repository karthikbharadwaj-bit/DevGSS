public inherited sharing class SegmentDataSelector extends SObjectSelector {

    public SegmentDataSelector() {
        super();
    }

    public SegmentDataSelector(Boolean enforceCRUD, Boolean enforceFLS) {
        super(enforceCRUD, enforceFLS);
    }

    public override Schema.SObjectType getSObjectType()  {
        return Segment_Data__c.getSObjectType();
    }

    public override List<Schema.SObjectField> getDefaultFieldList() {
        return new List<Schema.SObjectField> {
            Segment_Data__c.Id,
            Segment_Data__c.Attribute_1__c,
            Segment_Data__c.Attribute_2__c,
            Segment_Data__c.Type__c,
            Segment_Data__c.Name
        };
    }

    public QueryFactory selectSegmentDataForSmartSearch(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectSegmentDataForSmartSearch')
            .withSelectorFieldsIncluded()
            .setCondition('Attribute_1__c = :bind0')
            .setQueryBindings(bindings);
    }
}