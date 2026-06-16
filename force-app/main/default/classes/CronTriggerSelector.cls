public with sharing class CronTriggerSelector extends SObjectSelector {

    public CronTriggerSelector() {
        super();
    }

    public CronTriggerSelector(Boolean enforceCRUD, Boolean enforceFLS) {
        super(enforceCRUD, enforceFLS);
    }

    public override List<Schema.SObjectField> getDefaultFieldList() {
        return new List<Schema.SObjectField> {
            CronTrigger.Id,
            CronTrigger.State
        };
    }

    public override Schema.SObjectType getSObjectType()  {
        return CronTrigger.SObjectType;
    }

    public QueryFactory selectCronTriggerByName(List<Object> bindings) {
		return newQueryFactory()
				.setFactoryName('selectCronTriggerByName')
                .withSelectorFieldsIncluded()
				.withoutSelectorOrderByIncluded()
                .setCondition('CronJobDetail.Name = :bind0')
                .setQueryBindings(bindings)
                .setQueryCaching(true);
    }
}