public inherited sharing class AccountContactRelationSelector extends SObjectSelector {

    public AccountContactRelationSelector() {
        super();
    }

    public AccountContactRelationSelector(Boolean enforceCRUD, Boolean enforceFLS) {
        super(enforceCRUD, enforceFLS);
    }

    public override Schema.SObjectType getSObjectType()  {
        return AccountContactRelation.SObjectType;
    }

    public override List<Schema.SObjectField> getDefaultFieldList() {
        return new List<Schema.SObjectField> {
            AccountContactRelation.Id,
            AccountContactRelation.Roles,
            AccountContactRelation.ContactId,
            AccountContactRelation.AccountId
        };
    }

    public List<String> getFieldListOnAccountLink() {
        return new List<String> {
            'Contact.FirstName',
            'Contact.LastName',
            'Contact.Email',
            'Contact.Phone',
            'isPrimary__c',
            'IsActive',
            'Roles',
            'isDirect'
        };
    }

    public QueryFactory selectAccountContactRelationsForAccountLink() {
        return newQueryFactory()
            .setFactoryName('selectAccountContactRolesForOpportunityClose')
            .selectFields(getFieldListOnAccountLink())
            .withoutSelectorOrderByIncluded()
            .withSelectFieldsSorted();
    }
}