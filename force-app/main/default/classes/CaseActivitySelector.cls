public inherited sharing class CaseActivitySelector extends SObjectSelector {
    
    public CaseActivitySelector() {
        super();
    }

    public CaseActivitySelector(Boolean enforceCRUD, Boolean enforceFLS) {
        super(enforceCRUD, enforceFLS);
    }

    public override Schema.SObjectType getSObjectType()  {
        return Case_Activity__c.SObjectType;
    }

    public override List<Schema.SObjectField> getDefaultFieldList() {
        return new List<Schema.SObjectField> {
            Case_Activity__c.Id,
            Case_Activity__c.Case__c,
            Case_Activity__c.RecordTypeId
        };
    }

    public List<Schema.SObjectField> getCloseAttemptFields() {
        return new List<Schema.SObjectField> {
            Case_Activity__c.Name,
            Case_Activity__c.Assigned_To__c,
            Case_Activity__c.Case__c,
            Case_Activity__c.Linked_Tag__c,
            Case_Activity__c.Attempt_Interval_Days__c,
            Case_Activity__c.Comments__c,
            Case_Activity__c.Contact_Channel__c,
            Case_Activity__c.Status__c
        };
    }

    public QueryFactory selectCloseAttemptsByCaseIdAndRecordType(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectCloseAttemptsByCaseIdAndRecordType')
            .selectFields(getCloseAttemptFields())
            .setCondition('Case__c IN :bind0 AND RecordTypeId = :bind1')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectCaseActivitiesByCaseAndAssignedToAndRecordTypeAndStatus(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectCaseActivitiesByCaseAndAssignedToAndRecordTypeAndStatus')
            .selectFields(getCloseAttemptFields())
            .setCondition('Case__c IN :bind0 AND Assigned_To__c IN :bind1 AND RecordTypeId = :bind2 AND Status__c = :bind3')
            .setQueryBindings(bindings);
    }
    
    public QueryFactory selectCaseActivitiesByCaseAndAssignedToAndStatus(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectCaseActivitiesByCaseAndAssignedToAndStatus')
            .selectFields(getCloseAttemptFields())
            .setCondition('Case__c IN :bind0 AND Assigned_To__c IN :bind1 AND Status__c = :bind2')
            .setQueryBindings(bindings);
    }
}