public inherited sharing class ProcessInstanceWorkitemSelector extends SObjectSelector {
    public ProcessInstanceWorkitemSelector() {
        super();
    }

    public ProcessInstanceWorkitemSelector(Boolean enforceCRUD, Boolean enforceFLS) {
        super(enforceCRUD, enforceFLS);
    }

    public override Schema.SObjectType getSObjectType()  {
        return ProcessInstanceWorkitem.SObjectType;
    }

    public override List<Schema.SObjectField> getDefaultFieldList() {
        return new List<Schema.SObjectField> {
            ProcessInstanceWorkitem.Id
        };
    }

    public QueryFactory selectProcessInstanceWorkitems(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectProcessInstanceWorkitems')
            .setQueryBindings(bindings);
    }
}