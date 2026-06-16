public with sharing class AccountContactRoleHelper {
    public static final String CONTACT_ROLE_SIGNATORY = 'Signatory';
    public static final String CONTACT_ROLE_ACCOUNT_PAYABLE = 'Accounts Payable';
    public static final String CONTACT_ROLE_RC_ADMIN_USER = 'RC Admin User';
    public static final String CONTACT_ROLE_RC_NONE = '[none]';
    public static final String CONTACT_ROLE_EVENTS_ADMIN_USER = 'RC Events Admin';

    @AuraEnabled(cacheable=true)
    public static AccountContactRole getPrimaryContactRoleByAccountId(String accountId) {
        for (AccountContactRole acRole : (List<AccountContactRole>) new AccountContactRoleSelector()
                .selectPrimarySignatoryAccountContactRolesByAccountIds(new List<Object>{accountId})
                .executeQuery()) {
            return acRole;
        }
        return null;
    }
}