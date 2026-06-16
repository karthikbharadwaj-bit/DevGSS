public inherited sharing class AccountManagementSelector extends SObjectSelector {

    public AccountManagementSelector() {
        super();
    }

    public AccountManagementSelector(String relationshipName, SObjectType relationshipBase) {
        super(relationshipName, relationshipBase);
    }

    public AccountManagementSelector(Boolean enforceCRUD, Boolean enforceFLS) {
        super(enforceCRUD, enforceFLS);
    }

    public override Schema.SObjectType getSObjectType()  {
        return Account_Management__c.SObjectType;
    }

    public override List<Schema.SObjectField> getDefaultFieldList() {
        return new List<Schema.SObjectField> {
            Account_Management__c.Id,
            Account_Management__c.Name
        };
    }

    public QueryFactory selectAccountManagements() {
        return newQueryFactory()
            .setFactoryName('selectAccountManagements')
            .selectFields(getDefaultFieldList());
    }
}