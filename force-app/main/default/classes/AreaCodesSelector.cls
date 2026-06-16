public inherited sharing class AreaCodesSelector extends SObjectSelector {
    public AreaCodesSelector() {
        super();
    }

    public AreaCodesSelector(Boolean enforceCRUD, Boolean enforceFLS) {
        super(enforceCRUD, enforceFLS);
    }

    public override Schema.SObjectType getSObjectType() {
        return Area_Codes__c.SObjectType;
    }

    public override List<Schema.SObjectField> getDefaultFieldList() {
        return new List<Schema.SObjectField> {
            Area_Codes__c.Id,
            Area_Codes__c.Area_Code__c,
            Area_Codes__c.City__c,
            Area_Codes__c.Country__c,
            Area_Codes__c.State__c,
            Area_Codes__c.Type__c
        };
    }

    public QueryFactory selectAreaCodes() {
        return newQueryFactory()
            .setFactoryName('selectAreaCodes')
            .selectFields(getDefaultFieldList());
    }

    public QueryFactory selectAreaCodesByIds(Object ids) {
        return newQueryFactory()
            .setFactoryName('selectAreaCodes')
            .selectFields(getDefaultFieldList())
            .setCondition('Id = :bind0')
            .setQueryBindings(new List<Object>{ ids });
    }

    public QueryFactory selectAreaCodesForMatchedSync(List<Object> bindings, List<Object> subSelectBindings) {
        return newQueryFactory()
            .setFactoryName('selectAreaCodesForMatchedSync')
            .selectFields(getDefaultFieldList())
            .subSelect(
                new AreaCodeLineItemSelector().selectAreaCodeLineItems(subSelectBindings)
            )
            .setCondition(
                'Country__c IN :bind0 ' +
                'AND (State__c IN :bind1 OR State__c = null) ' +
                'AND (City__c IN :bind2 OR City__c = null) ' +
                'AND Area_Code__c IN :bind3'
            )
            .setQueryBindings(bindings);
    }
}