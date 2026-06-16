public inherited sharing class RetentionTaskSelector extends SObjectSelector {

    public RetentionTaskSelector() {
        super();
    }

    public RetentionTaskSelector(String relationshipName, SObjectType relationshipBase) {
        super(relationshipName, relationshipBase);
    }

    public RetentionTaskSelector(Boolean enforceCRUD, Boolean enforceFLS) {
        super(enforceCRUD, enforceFLS);
    }

    public override Schema.SObjectType getSObjectType()  {
        return Retention_Task__c.SObjectType;
    }

    public override List<Schema.SObjectField> getDefaultFieldList() {
        return new List<Schema.SObjectField> {
            Retention_Task__c.Id
        };
    }

    public QueryFactory selectRetentionTasks() {
        return newQueryFactory()
            .setFactoryName('selectRetentionTasks')
            .selectFields(getDefaultFieldList());
    }
}