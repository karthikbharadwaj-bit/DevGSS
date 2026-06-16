public with sharing class PartnerCommunicationSelector extends SObjectSelector {

    public PartnerCommunicationSelector() {
        super();
    }

    public PartnerCommunicationSelector(Boolean enforceCRUD, Boolean enforceFLS) {
        super(enforceCRUD, enforceFLS);
    }

    public override List<Schema.SObjectField> getDefaultFieldList() {
        return new List<Schema.SObjectField> {
            Partner_Communication__c.Id,
            Partner_Communication__c.Case_Comment_ID__c
        };
    }

    public override Schema.SObjectType getSObjectType()  {
        return Partner_Communication__c.SObjectType;
    }

    public QueryFactory selectPartnerCommunicationsByCaseCommentId(List<Object> bindings) {
		return newQueryFactory()
				.setFactoryName('selectPartnerCommunicationsByCaseCommentId')
                .withSelectorFieldsIncluded()
				.withoutSelectorOrderByIncluded()
                .setCondition('Case_Comment_ID__c in :bind0')
                .setQueryBindings(bindings);
    }
}