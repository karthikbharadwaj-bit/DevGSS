public inherited sharing class DeviceSelector extends SObjectSelector {
    public DeviceSelector() {
        super();
    }

    public DeviceSelector(Boolean enforceCRUD, Boolean enforceFLS) {
        super(enforceCRUD, enforceFLS);
    }

    public override Schema.SObjectType getSObjectType()  {
        return Device__c.SObjectType;
    }
    
    public override List<Schema.SObjectField> getDefaultFieldList() {
        return new List<Schema.SObjectField> {
            Device__c.Id,
            Device__c.Case__c,
            Device__c.Local_Parent_Id__c,
            Device__c.Instance_ID__c,
            Device__c.Serial_Number__c,
            Device__c.Status__c,
            Device__c.Device_Type__c,
            Device__c.Partner_Parent_ID__c
        };
    }
    
    public QueryFactory selectDevicesByCase(List<Object> bindings) {
        return newQueryFactory()
                .setFactoryName('selectDeviceByCase')
                .withSelectorFieldsIncluded()
                .setCondition('Case__c = :bind0')
                .setQueryBindings(bindings);
    }
}