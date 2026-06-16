public inherited sharing class AsyncApexJobSelector extends SObjectSelector {

    public AsyncApexJobSelector() {
        super();
    }

    public AsyncApexJobSelector(Boolean enforceCRUD, Boolean enforceFLS) {
        super(enforceCRUD, enforceFLS);
    }

    public override Schema.SObjectType getSObjectType()  {
        return AsyncApexJob.SObjectType;
    }

    public override List<Schema.SObjectField> getDefaultFieldList() {
        return new List<Schema.SObjectField> {
            AsyncApexJob.Id,
            AsyncApexJob.ApexClassId,
            AsyncApexJob.JobType,
            AsyncApexJob.Status
        };
    }

    public QueryFactory selectBatchById(Id batchId) {
        return newQueryFactory()
            .setFactoryName('selectBatchById')
            .selectField('ApexClass.Name')
            .setCondition('Id = :bind0 AND JobType = \'BatchApex\'')
            .setQueryBindings(new List<Object>{batchId});
    }

}