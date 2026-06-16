public inherited sharing class CompanyPersonSelector extends SObjectSelector {

    public CompanyPersonSelector() {
        super();
    }

    public CompanyPersonSelector(Boolean enforceCRUD, Boolean enforceFLS) {
        super(enforceCRUD, enforceFLS);
    }

    public override Schema.SObjectType getSObjectType()  {
        return Company_Persons__c.SObjectType;
    }

    public override List<Schema.SObjectField> getDefaultFieldList() {
        return new List<Schema.SObjectField> {
            Company_Persons__c.Id,
            Company_Persons__c.Lead__c,
            Company_Persons__c.Contact__c,
            Company_Persons__c.Name
        };
    }

    public QueryFactory selectCountCompanyPersonsForCompanyMatching(List<Object> bindings) {
        return newQueryFactory()
                .setFactoryName('selectCompanyPersonsForCompanyMatching')
                .withSelectorFieldsIncluded()
                .setCondition('Lead__c = :bind0')
                .setQueryBindings(bindings);               
    }

    public QueryFactory selectCountCompanyPersonsByLeadAndCompanyId(List<Object> bindings) {
        return newQueryFactory()
                .setFactoryName('selectCountCompanyPersonsByLeadAndCompanyId')
                .withSelectorFieldsIncluded()
                .setCondition('Company__c IN :bind1 AND Lead__c IN :bind0')
                .setQueryBindings(bindings);
    }

    public QueryFactory selectCountCompanyPersonsByAccountContactsAndCompanyId(List<Object> bindings) {
        return newQueryFactory()
                .setFactoryName('selectCountCompanyPersonsByAccountContactsAndCompanyId')
                .withSelectorFieldsIncluded()
                .setCondition('Company__c IN :bind0 AND Contact__c IN :bind1')
                .setQueryBindings(bindings);
    }
}