public inherited sharing class EmployeeSelector extends SObjectSelector {

    public EmployeeSelector() {
        super();
    }

    public EmployeeSelector(Boolean enforceCRUD, Boolean enforceFLS) {
        super(enforceCRUD, enforceFLS);
    }

    public override Schema.SObjectType getSObjectType()  {
        return Employee__c.getSObjectType();
    }

    public override List<Schema.SObjectField> getDefaultFieldList() {
        return new List<Schema.SObjectField> {
            Employee__c.Id,
            Employee__c.User__c,
            Employee__c.Team__c,
            Employee__c.Division__c
        };
    }

    public QueryFactory selectEmployeeForDFR() {
        return newQueryFactory()
            .setFactoryName('selectEmployeeForDFR')
            .withSelectorFieldsIncluded()
            .withoutSelectorOrderByIncluded();
    }

    public QueryFactory selectEmployeeForDFR(List<Object> bindings) {
        return selectEmployeeForDFR()
            .setCondition('User__c IN :bind0')
            .setQueryBindings(bindings);
    }
}