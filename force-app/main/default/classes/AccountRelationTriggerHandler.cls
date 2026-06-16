public with sharing class AccountRelationTriggerHandler {

    public class AccountRelationBefore extends Triggers.TriggerHandlerBase {

        override public void handle() {

            if (Trigger.isInsert || Trigger.isUpdate) {

                Set<Id> accIds = new Set<Id>();
                Map<Id, List<AccountContactRole>> accountContactRolesMap = new Map<Id, List<AccountContactRole>>();
                List<AccountRelation__c> accountRelations = (List<AccountRelation__c>) Trigger.new;

                for (AccountRelation__c accountRelation : accountRelations) {
                    if (AccountHelper.RELATION_TYPE_ELA.equals(accountRelation.Relation_Type__c)) {
                        accIds.add(accountRelation.Parent_Account__c);
                        accIds.add(accountRelation.Child_Account__c);
                    }
                }

                List<AccountContactRole> contactRoles = (List<AccountContactRole>) new AccountContactRoleSelector()
                    .selectAccountContactRolesByAccountIds(accIds)
                    .executeQuery();

                for (AccountContactRole contactRole : contactRoles) {
                    if (accountContactRolesMap.get(contactRole.AccountId) == null) {
                        accountContactRolesMap.put(contactRole.AccountId, new List<AccountContactRole>{
                                contactRole
                        });
                    } else {
                        accountContactRolesMap.get(contactRole.AccountId).add(contactRole);
                    }
                }

                Map<Id, Account> accounts = new Map<Id, Account>((List<Account>) new AccountSelector()
                    .selectAccountsByIds(new List<Object>{accIds})
                    .selectFields(new List<String>{'ELA_Account_Type__c'})
                    .executeQuery());

                for (AccountRelation__c accountRelation : accountRelations) {
                    Id parentId = accountRelation.Parent_Account__c;
                    Id childId = accountRelation.Child_Account__c;

                    if (parentId.equals(childId)) {
                        accountRelation.addError('Parent and Child accounts cannot be the same');
                        break;
                    }

                    String parentElaType = accounts.get(parentId).ELA_Account_Type__c;
                    String childElaType = accounts.get(childId).ELA_Account_Type__c;

                    if (parentElaType == null || AccountHelper.ACCOUNT_TYPE_ELA_SERVICE.equals(parentElaType)) {
                        accountRelation.addError('Parent account must be \'ELA Billing\'');
                        break;
                    }

                    if (childElaType == null || AccountHelper.ACCOUNT_TYPE_ELA_BILLING.equals(childElaType)) {
                        accountRelation.addError('Child account must be \'ELA Service\'');
                        break;
                    }

                    Boolean isSameContact = false;

                    /* AccountContactRole */
                    isSameContact = checkAccountContactRole(
                            accountContactRolesMap.get(parentId), 
                            accountContactRolesMap.get(childId)
                    );
                    
                    if (!isSameContact) {
                        accountRelation.addError('Accounts don\'t have a common contact');
                    }
                } 
            }
        }
        
        public Boolean checkAccountContactRole(
                List<AccountContactRole> parentAccountContactRoles, 
                List<AccountContactRole> childAccountContactRoles) {
            if (parentAccountContactRoles != null && childAccountContactRoles != null) {
                for (AccountContactRole p : parentAccountContactRoles) {
                    for (AccountContactRole c : childAccountContactRoles) {
                        if (p.contactId.equals(c.contactId)) {
                            return true;
                        }
                    }
                }
            }
            return false;
        }
    }
}