public inherited sharing class CustomAddressSelector extends SObjectSelector {

    public CustomAddressSelector() {
        super();
    }

    public CustomAddressSelector(Boolean enforceCRUD, Boolean enforceFLS) {
        super(enforceCRUD, enforceFLS);
    }

    public override Schema.SObjectType getSObjectType()  {
        return CustomAddress__c.SObjectType;
    }

    public override List<Schema.SObjectField> getDefaultFieldList() {
        return new List<Schema.SObjectField> {
            CustomAddress__c.Id,
            CustomAddress__c.Name,
            CustomAddress__c.AdditionalAddressLine__c,
            CustomAddress__c.AddressLine__c,
            CustomAddress__c.City__c,
            CustomAddress__c.Country__c,
            CustomAddress__c.State__c,
            CustomAddress__c.Street__c,
            CustomAddress__c.PostalCode__c
        };
    }

    public QueryFactory selectCustomAddress() {
        return newQueryFactory()
                .setFactoryName('selectCustomAddress');
    }

    public QueryFactory selectCustomAddresses(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectCustomAddresses')
            .selectFields(getDefaultFieldList())
            .setCondition('Country__c IN:bind0 AND City__c IN: bind1 AND PostalCode__c IN:bind2 AND AddressLine__c IN:bind3 AND State__c IN:bind4')
            .subselect(
                new CustomAddressAssignmentsSelector().selectCustomAddressAssignments()
            )
            .setQueryBindings(bindings);
    }

    public QueryFactory selectCustomAddressesNew(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectCustomAddresses')
            .selectFields(getDefaultFieldList())
            .setCondition('Country__c IN:bind0 AND City__c IN: bind1 AND PostalCode__c IN:bind2 AND AddressLine__c IN:bind3 AND State__c IN:bind4')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectCustomAddressesByIds(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectCustomAddressesByIds')
            .selectFields(getDefaultFieldList())
            .setCondition('Id IN :bind0')
            .setQueryBindings(bindings);
    }
}