public class EventSelector extends SObjectSelector {
    public EventSelector() {
        super();
    }
    public EventSelector(Boolean enforceCRUD, Boolean enforceFLS) {
        super(enforceCRUD, enforceFLS);
    }
    public override Schema.SObjectType getSObjectType()  {
        return Event.SObjectType;
    }

    public override List<Schema.SObjectField> getDefaultFieldList() {
        return new List<Schema.SObjectField> {
            Event.Id,
            Event.WhoId,
            Event.WhatId,
            Event.CreatedDate,
            Event.Type,
            Event.Appointment_Source__c
        };
    }

    public QueryFactory selectEventsByWhatIds(Set<Id> whatIds) {
        return newQueryFactory()
            .setFactoryName('selectEventsByWhatIds')
            .setCondition('WhatId IN :bind0')
            .setQueryBindings(new List<Object> {whatIds});
    }
}