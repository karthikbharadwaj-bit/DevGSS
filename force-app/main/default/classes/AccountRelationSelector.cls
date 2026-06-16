public inherited sharing class AccountRelationSelector extends SObjectSelector {

    public AccountRelationSelector() {
        super();
    }

    public AccountRelationSelector(Boolean enforceCRUD, Boolean enforceFLS) {
        super(enforceCRUD, enforceFLS);
    }

    public override Schema.SObjectType getSObjectType()  {
        return AccountRelation__c.SObjectType;
    }

    public override List<Schema.SObjectField> getDefaultFieldList() {
        return new List<Schema.SObjectField> {
            AccountRelation__c.Child_Account__c,
            AccountRelation__c.Parent_Account__c,
            AccountRelation__c.Relation_Type__c
        };
    }

    public List<String> getOppSignUpFieldList() {
        return new List<String> {
            'Child_Account__c',
            'Child_Account__r.ELA_Account_Type__c',
            'Child_Account__r.RC_Account_Status__c',
            'Child_Account__r.Package_Status__c',
            'Child_Account__r.Billing_ID__c',
            'Parent_Account__c',
            'Parent_Account__r.ELA_Account_Type__c',
            'Parent_Account__r.RC_Account_Status__c',
            'Parent_Account__r.Package_Status__c',
            'Parent_Account__r.Billing_ID__c',
            'Relation_Type__c'
        };
    }

    public QueryFactory selectAccountRelations() {
        return newQueryFactory()
            .setFactoryName('selectAccountRelations')
            .selectFields(getDefaultFieldList());
    }

    public QueryFactory selectAccountRelationByParentId(Id parentAccountId) {
        return newQueryFactory()
            .setFactoryName('selectAccountRelationByParentId')
            .selectFields(getDefaultFieldList())
            .setCondition('Parent_Account__c = :bind0')
            .setQueryBindings(new List<Object>{new Set<Id> {parentAccountId}});
    }

    public QueryFactory selectAccountRelationByParentAndChildId(Id accountId) {
        return newQueryFactory()
            .setFactoryName('selectAccountRelationByParentAndChildId')
            .selectFields(getOppSignUpFieldList())
            .setCondition('Parent_Account__c = :bind0 OR Child_Account__c =: bind0')
            .setQueryBindings(new List<Object>{new Set<Id> {accountId}});
    }

    public QueryFactory selectAccountRelationsByParentAndChildIds(List<Object> binding) {
        return newQueryFactory()
            .setFactoryName('selectAccountRelationsByParentAndChildIds')
            .selectFields(getOppSignUpFieldList())
            .setCondition('Parent_Account__c IN :bind0 OR Child_Account__c IN: bind0')
            .setQueryBindings(binding);
    }
}