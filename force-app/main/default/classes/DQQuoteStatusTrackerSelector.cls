public inherited sharing class DQQuoteStatusTrackerSelector extends SObjectSelector {
    public DQQuoteStatusTrackerSelector() {
        super();
    }

    public DQQuoteStatusTrackerSelector(Boolean enforceCRUD, Boolean enforceFLS) {
        super(enforceCRUD, enforceFLS);
    }

    public override Schema.SObjectType getSObjectType()  {
        return DQ_Quote_Status_Tracker__c.SObjectType;
    }

    public override List<Schema.SObjectField> getDefaultFieldList() {
        return new List<Schema.SObjectField> {
            DQ_Quote_Status_Tracker__c.Id
        };
    }

    public QueryFactory selectAllFieldsForCloning(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectAllFieldsForCloning')
            .selectFields(AquivaHelper.getAllFieldsForObject('DQ_Quote_Status_Tracker__c'))
            .setCondition('Quote__c IN :bind0')
            .setQueryBindings(bindings);
    }
}