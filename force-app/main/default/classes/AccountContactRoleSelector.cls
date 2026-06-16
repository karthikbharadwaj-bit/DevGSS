public inherited sharing class AccountContactRoleSelector extends SObjectSelector {

    public AccountContactRoleSelector() {
        super();
    }

    public AccountContactRoleSelector(Boolean enforceCRUD, Boolean enforceFLS) {
        super(enforceCRUD, enforceFLS);
    }

    public override Schema.SObjectType getSObjectType()  {
        return AccountContactRole.SObjectType;
    }

    public override List<Schema.SObjectField> getDefaultFieldList() {
        return new List<Schema.SObjectField> {
            AccountContactRole.Id,
            AccountContactRole.Role,
            AccountContactRole.IsPrimary,
            AccountContactRole.ContactId,
            AccountContactRole.AccountId
        };
    }

    public List<String> getFieldsForDocusign() {
        return new List<String> {
            'Contact.FirstName',
            'Contact.LastName',
            'Contact.Email'
        };
    }

    public List<String> getCloseFieldList() {
        return new List<String> {
            'Contact.FirstName',
            'Contact.LastName',
            'Contact.Email',
            'Contact.Phone'
        };
    }

    public List<String> getFieldsWithAccountAndContact() {
        return new List<String> {
            'AccountId',
            'Account.IsMultiProductTechnicalAccount__c',
            'ContactId',
            'CreatedDate',
            'IsPrimary',
            'Role',
            'Account.Name',
            'Contact.Email',
            'Contact.FirstName',
            'Contact.LastName',
            'Contact.Name',
            'Contact.Phone',
            'Contact.Title',
            'Contact.RCService_ContactStatus__c'   
        };
    }

    public QueryFactory selectAccountContactRoles() {
        return newQueryFactory()
                .setFactoryName('SelectAccountContactRoles')
                .withoutSelectorOrderByIncluded()
                .withSelectorFieldsIncluded();
    }

    public QueryFactory selectAccountContactRolesByAccountIds(List<Id> accountIds) {
        return newQueryFactory()
            .setFactoryName('SelectAccountContactRolesByAccountIds')
            .withSelectorFieldsIncluded()
            .withoutSelectorOrderByIncluded()
            .setCondition('AccountId IN :bind0')
            .addOrdering('CreatedDate', QueryFactory.SortOrder.DESCENDING)
            .setQueryBindings(new List<Object> { accountIds });
    }

    public QueryFactory selectAccountContactRolesByAccountIds(Set<Id> accountIds) {
        return selectAccountContactRolesByAccountIds(new List<Id>(accountIds));
    }

    public QueryFactory selectPrimaryOrSignatoryContactRoles(List<Id> accountIds) {
        return newQueryFactory()
            .setFactoryName('selectPrimaryOrSignatoryContactRoles')
            .withSelectorFieldsIncluded()
            .withoutSelectorOrderByIncluded()
            .setCondition('AccountId = :bind0 AND (Role = \'Signatory\' OR isPrimary = true)')
            .addOrdering('CreatedDate', QueryFactory.SortOrder.DESCENDING)
            .setQueryBindings(new List<Object> { accountIds });
    }

    public QueryFactory selectAccountContactRolesByAccountAndContactIds(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectAccountContactRolesByAccountAndContactIds')
            .withSelectorFieldsIncluded()
            .selectFields(getDefaultFieldList())
            .withoutSelectorOrderByIncluded()
            .setCondition('AccountId = :bind0 AND ContactId = :bind1')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectPrimaryAccountContactRolesByAccountIds(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectPrimaryAccountContactRolesByAccountIds')
            .withSelectorFieldsIncluded()
            .withoutSelectorOrderByIncluded()
            .selectFields(getFieldsWithAccountAndContact())
            .setCondition((bindings.size() > 0 ? 'AccountId = :bind0 AND ' : '') + 'isPrimary = true')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectPrimarySignatoryAccountContactRolesByAccountIds(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectPrimarySignatoryAccountContactRolesByAccountIds')
            .withSelectorFieldsIncluded()
            .withoutSelectorOrderByIncluded()
            .selectFields(getFieldsWithAccountAndContact())
            .setCondition((bindings.size() > 0 ? 'AccountId = :bind0 AND  ' : '') + ' Role = \'Signatory\'  AND isPrimary = true')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectSignatoryContactRolesByForAccount(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectSignatoryContactRolesByForAccount')
            .selectFields(getFieldsForDocusign())
            .withoutSelectorOrderByIncluded()
            .setCondition('AccountId = :bind0 AND Role = \'Signatory\'')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectPrimaryOrSignatoryContactRolesForLookup(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectPrimaryOrSignatoryContactRolesForLookup')
            .selectFields(getFieldsForDocusign())
            .withoutSelectorOrderByIncluded()
            .setCondition('AccountId = :bind0 AND (Role = \'Signatory\' OR isPrimary = true)')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectConversionContactsForLookup(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectConversionContactsForLookup')
            .selectFields(getFieldsForDocusign())
            .withoutSelectorOrderByIncluded()
            .setCondition('AccountId = :bind0')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectAccountPayableContactRolesByAccount(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectAccountPayableContactRolesByAccount')
            .selectFields(getFieldsForDocusign())
            .withoutSelectorOrderByIncluded()
            .setCondition('AccountId = :bind0 AND Role = \'Accounts Payable\' AND ContactId != :bind1')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectAccountContactRolesForOpportunityClose() {
        return newQueryFactory()
            .setFactoryName('selectAccountContactRolesForOpportunityClose')
            .selectFields(getCloseFieldList())
            .withoutSelectorOrderByIncluded()
            .withSelectFieldsSorted();
    }

    public QueryFactory selectAccountContactRolesByContactIds(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('SelectAccountContactRolesByContactIds')
            .withSelectorFieldsIncluded()
            .withoutSelectorOrderByIncluded()
            .setCondition('ContactId = :bind0')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectAccountContactRolesByIds(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectAccountContactRolesByIds')
            .withSelectorFieldsIncluded()
            .selectFields(getDefaultFieldList())
            .withoutSelectorOrderByIncluded()
            .setCondition('Id = :bind0')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectAccountContactRolesForAccountOrderedByCreatedDate(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectAccountContactRolesForAccountOrderedByCreatedDate')
            .withSelectorFieldsIncluded()
            .withoutSelectorOrderByIncluded()
            .selectFields(getFieldsWithAccountAndContact())
            .setCondition('AccountId = :bind0 AND Role != \'[None]\'')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectPrimaryAccountContactRoles() {
        return newQueryFactory()
            .setFactoryName('SelectPrimaryAccountContactRoles')
            .withoutSelectorOrderByIncluded()
            .withSelectorFieldsIncluded()
            .selectFields(getFieldsWithAccountAndContact())
            .setCondition('isPrimary = true');
    }

    public QueryFactory selectDeletedAccountContactRolesById(Set<Id> acrIds) {
        return selectDeletedAccountContactRolesById(new List<Id>(acrIds));
    }
    public QueryFactory selectDeletedAccountContactRolesById(List<Id> acrIds) {
        return newQueryFactory()
            .setFactoryName('selectDeletedAccountContactRolesById')
            .withSelectFieldsSorted()
            .withoutSelectorOrderByIncluded()
            .withAllRows()
            .setCondition('Id IN :bind0 AND IsDeleted = true')
            .setQueryBindings(new List<Object> { acrIds });
    }

    public QueryFactory selectAccountContactRolesById(Set<Id> acrIds) {
        return newQueryFactory()
            .setFactoryName('selectAccountContactRolesById')
            .withSelectFieldsSorted()
            .withoutSelectorOrderByIncluded()
            .selectFields(getFieldsWithAccountAndContact())
            .setCondition('Id IN :bind0 AND Role != \'[None]\' AND Role != \'\' AND Role != NULL')
            .setQueryBindings(new List<Object> { acrIds });
    }

    public QueryFactory selectAccountContactRolesByContactIds2(Set<Id> contactIds) {
        return newQueryFactory()
            .setFactoryName('selectAccountContactRolesByContactIds')
            .withSelectFieldsSorted()
            .withoutSelectorOrderByIncluded()
            .selectFields(getFieldsWithAccountAndContact())
            .setCondition('ContactId IN :bind0 AND Role != \'[None]\' AND Role != \'\' AND Role != NULL')
            .setQueryBindings(new List<Object> { contactIds });
    }

    public QueryFactory selectAccountContactRolesWithNonEmptyRoleByAccountIds(List<Id> accountIds) {
        return newQueryFactory()
            .setFactoryName('SelectAccountContactRolesByAccountIds')
            .withSelectorFieldsIncluded()
            .withoutSelectorOrderByIncluded()
            .setCondition('AccountId IN :bind0 AND Role NOT IN (\'' + AccountContactRoleHelper.CONTACT_ROLE_RC_NONE + '\', \'\', NULL)')
            .addOrdering(AccountContactRole.CreatedDate, QueryFactory.SortOrder.DESCENDING)
            .setQueryBindings(new List<Object> { accountIds });
    }

    public QueryFactory selectAccountContactRolesByRoleAndAccountId(Id accountId, String role) {
        return selectAccountContactRolesByRolesAndAccountIds(new Set<Id> {accountId}, new Set<String> {role});
    }

    public QueryFactory selectAccountContactRolesByRolesAndAccountIds(Set<Id> accountIds, Set<String> roles) {
        return newQueryFactory()
            .setFactoryName('selectAccountContactRolesByRolesAndAccountIds')
            .selectFields(getDefaultFieldList())
            .withoutSelectorOrderByIncluded()
            .setCondition('AccountId IN :bind0 AND Role IN :bind1')
            .addOrdering('CreatedDate', QueryFactory.SortOrder.DESCENDING)
            .setQueryBindings(new List<Object> {accountIds, roles});
    }

    public QueryFactory selectPrimaryAccountContactRolesByAccountIds(Set<Id> accountIds) {
        return newQueryFactory()
            .setFactoryName('selectPrimaryAccountContactRolesByAccountIds')
            .selectFields(getFieldsWithAccountAndContact())
            .setCondition('AccountId IN :bind0 AND IsPrimary = true')
            .addOrdering('Account.IsMultiProductTechnicalAccount__c', QueryFactory.SortOrder.ASCENDING)
            .setQueryBindings(new List<Object> {accountIds});
    }
}