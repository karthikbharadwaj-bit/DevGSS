public inherited sharing class LeadStatusSelector extends SObjectSelector {

    public LeadStatusSelector() {
        super();
    }

    public LeadStatusSelector(Boolean enforceCRUD, Boolean enforceFLS) {
        super(enforceCRUD, enforceFLS);
    }

    public override SObjectType getSObjectType() {
        return LeadStatus.SObjectType;
    }

    public override List<SObjectField> getDefaultFieldList() {
        return new List<Schema.SObjectField> {
            LeadStatus.Id,
            LeadStatus.IsConverted,
            LeadStatus.MasterLabel
        };
    }

    public QueryFactory selectLeadStatusForConvert() {
        return newQueryFactory()
            .setFactoryName('SelectLeadStatusForConvert')
            .withSelectorFieldsIncluded()
            .withoutSelectorOrderByIncluded()
            .withSelectFieldsSorted()
            .setCondition('IsConverted = true')
            .setLimit(1);
    }

}