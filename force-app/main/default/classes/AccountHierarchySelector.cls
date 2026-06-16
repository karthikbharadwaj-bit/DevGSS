public inherited sharing class AccountHierarchySelector extends SObjectSelector {
    public AccountHierarchySelector() {
        super();
    }

    public override SObjectType getSObjectType() {
        return Account_Hierarchy__c.SObjectType;
    }

    public override List<SObjectField> getDefaultFieldList() {
        return new List<Schema.SObjectField> {
            Account_Hierarchy__c.Id,
            Account_Hierarchy__c.OwnerId,
            Account_Hierarchy__c.Name,
            Account_Hierarchy__c.Territory__c,
            Account_Hierarchy__c.AH_Territory_Name__c,
            Account_Hierarchy__c.AH_Owner__c,
            Account_Hierarchy__c.AH_Alternate_Owner__c
        };
    }

    public QueryFactory selectAccountHierarchyById(Id accountHierarchyId) {
        return newQueryFactory()
            .setFactoryName('selectAccountHierarchyById')
            .withSelectorFieldsIncluded()
            .selectFields(getDefaultFieldList())
            .setCondition('Id = :bind0')
            .setQueryBindings(new List<Object>{new Set<Id>{accountHierarchyId}});
    }

    public QueryFactory selectAccountHierarchyByIdInRange(Set<Id> accountHierarchyIds) {
        return newQueryFactory()
            .setFactoryName('selectAccountHierarchyByIdInRange')
            .withSelectorFieldsIncluded()
            .selectFields(getDefaultFieldList())
            .setCondition('Id IN :bind0')
            .setQueryBindings(new List<Object>{accountHierarchyIds});
    }

    public QueryFactory selectAccountHierarchyByName(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectAccountHierarchyByIdInRange')
            .withSelectorFieldsIncluded()
            .selectFields(getDefaultFieldList())
            .setCondition('Name IN :bind0')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectCompanyStatusByIds(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectCompanyStatusByIds')
            .withSelectorFieldsIncluded()
            .selectFields(new List<String>{'Id', 'Company_Status__c'})
            .setCondition('Id IN: bind0')
            .setQueryBindings(bindings);
    }
}