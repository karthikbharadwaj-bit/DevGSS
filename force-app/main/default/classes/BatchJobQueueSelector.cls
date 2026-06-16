public inherited sharing class BatchJobQueueSelector extends SObjectSelector {

    public BatchJobQueueSelector() {
        super();
    }

    public BatchJobQueueSelector(Boolean enforceCRUD, Boolean enforceFLS) {
        super(enforceCRUD, enforceFLS);
    }

    public override SObjectType getSObjectType() {
        return BatchJobQueue__c.SObjectType;
    }

    public override List<SObjectField> getDefaultFieldList() {
        return new List<Schema.SObjectField> {
            BatchJobQueue__c.Id,
            BatchJobQueue__c.BatchJobName__c,
            BatchJobQueue__c.Status__c,
            BatchJobQueue__c.RecordIdsToBeProcessedInQueue__c
        };
    }

    public QueryFactory selectBatchJobQueueObjects() {
        return newQueryFactory()
            .setFactoryName('selectBatchJobQueueObjects')
            .withSelectorFieldsIncluded()
            .selectFields(getDefaultFieldList());
    }

    public List<Schema.SObjectField> getBatchJobQueueExceptionFieldList() {
        return new List<Schema.SObjectField> {
            BatchJobQueue__c.Id,
            BatchJobQueue__c.BatchJobName__c,
            BatchJobQueue__c.Status__c,
            BatchJobQueue__c.ExceptionMessage__c
        };
    }
    
    public QueryFactory selectBatchJobQueueExceptionById(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectBatchJobQueueExceptionById')
            .withSelectorFieldsIncluded()
            .selectFields(getBatchJobQueueExceptionFieldList())
            .setCondition('Id = :bind0')
            .setQueryBindings(bindings)
            .setLimit(1);
    }

    public QueryFactory selectBatchJobQueuesByBatchJobNameAndByStatus(String batchJobName, String status) {
        return newQueryFactory()
            .setFactoryName('selectBatchJobQueuesByBatchJobNameAndByStatus')
            .withSelectorFieldsIncluded()
            .selectFields(getDefaultFieldList())
            .setCondition('BatchJobName__c = :bind0 AND Status__c = :bind1')
            .setQueryBindings(new List<Object> {batchJobName, status});
    }
}