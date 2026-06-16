public with sharing class AccountContactRoleChangeEventHandler {

    public class SyncWithTechnicalAccounts extends Triggers.TriggerHandlerBase {
        private final Set<Id> created = new Set<Id>();
        private final Set<Id> updated = new Set<Id>();
        private final Set<Id> deleted = new Set<Id>();

        private final Map<Id, Set<String>> changedFieldsByRecordId = new Map<Id, Set<String>>();

        override public void handle() {
            for (AccountContactRoleChangeEvent event: (List<AccountContactRoleChangeEvent>) Trigger.new) {
                EventBus.ChangeEventHeader header = event.ChangeEventHeader;
                List<Id> records = (List<Id>) header.getRecordIds();

                switch on (header.changeType) {
                    when 'CREATE' {
                        created.addAll(records);
                    }
                    when 'UPDATE' {
                        for (Id recordId: records) {
                            changedFieldsByRecordId.put(recordId, new Set<String>(header.changedFields));
                        }

                        updated.addAll(records);
                    }
                    when 'DELETE' {
                        deleted.addAll(records);
                    }
                }
            }

            if (!created.isEmpty()) {
                this.handleCreate();
            }

            if (!updated.isEmpty()) {
                this.handleUpdate();
            }

            if (!deleted.isEmpty()) {
                this.handleDelete();
            }
        }

        private void handleCreate() {
            System.debug('Account Contact Role Create Handler: ' + created);

            List<Account> accounts = new AccountSelector()
                .selectMPAccountsWithTechAccountsAndContactRolesByAcrIds(created)
                .executeQuery();

            List<AccountContactRole> recordsToInsert = new List<AccountContactRole>();
            for (Account acc: accounts) {
                for (AccountContactRole masterAcr: acc.AccountContactRoles) {
                    if (!created.contains(masterAcr.Id)) {
                        continue;
                    }

                    for (Account techAcc: acc.Master_Accounts__r) {
                        AccountContactRole newAccountContactRole = masterAcr.clone(false, false, false, false);
                        newAccountContactRole.AccountId = techAcc.Id;

                        recordsToInsert.add(newAccountContactRole);
                    }
                }
            }

            if (!recordsToInsert.isEmpty()) {
                System.debug(recordsToInsert);
                insert recordsToInsert;
            }
        }

        private void handleUpdate() {
            System.debug('Account Contact Role Update Handler: ' + updated);
            List<Account> accounts = new AccountSelector()
                .selectMPAccountsWithTechAccountsAndContactRolesByAcrIds(updated)
                .executeQuery();
            List<Account> techAccountsWithContactRoles = new AccountSelector()
                .selectMPTechAccountsWithContactRolesByAcrIds(updated)
                .executeQuery();
            Map<Id, List<Account>> techAccountsByMasterIds = (Map<Id, List<Account>>) AquivaHelper.groupByIdField(
                List<Account>.class,
                techAccountsWithContactRoles,
                'Master_Account__c'
            );

            List<AccountContactRole> recordsToDelete = new List<AccountContactRole>();
            List<AccountContactRole> recordsToCreate = new List<AccountContactRole>();
            for (Account acc: accounts) {
                if (!techAccountsByMasterIds.containsKey(acc.Id)) {
                    continue;
                }

                for (Account techAcc: techAccountsByMasterIds.get(acc.Id)) {
                    for (AccountContactRole techACR: techAcc.AccountContactRoles) {
                        recordsToDelete.add(new AccountContactRole(Id = techACR.Id));
                    }

                    for (AccountContactRole masterACR: acc.AccountContactRoles) {
                        AccountContactRole acrToCreate = masterACR.clone(false, false, false, false);
                        acrToCreate.AccountId = techAcc.Id;

                        recordsToCreate.add(acrToCreate);
                    }
                }
            }

            if (!recordsToDelete.isEmpty()) {
                System.debug('Delete: ');
                System.debug(recordsToDelete);
                delete recordsToDelete;
            }

            if (!recordsToCreate.isEmpty()) {
                System.debug('Create: ');
                System.debug(recordsToCreate);
                insert recordsToCreate;
            }
        }

        private void handleDelete() {
            System.debug('Account Contact Role Delete Handler: ' + deleted);
            List<AccountContactRole> deletedACRs = new AccountContactRoleSelector()
                .selectDeletedAccountContactRolesById(deleted)
                .executeQuery();
            Map<Id, List<AccountContactRole>> deletedACRsByAccountIds = (Map<Id, List<AccountContactRole>>) AquivaHelper.groupByIdField(
                List<AccountContactRole>.class,
                deletedACRs,
                'AccountId'
            );
            List<Account> accounts = new AccountSelector()
                .selectMPTechAccountsWithContactRolesByMasterAccountIds(deletedACRsByAccountIds.keySet())
                .executeQuery();
            List<AccountContactRole> recordsToDelete = new List<AccountContactRole>();
            for (Account acc: accounts) {
                for (AccountContactRole deletedACR: deletedACRsByAccountIds.get(acc.Master_Account__c)) {
                    for (AccountContactRole existingTechACR: acc.AccountContactRoles) {
                        if (deletedACR.ContactId != existingTechACR.ContactId || deletedACR.Role != existingTechACR.Role) {
                            continue;
                        }

                        recordsToDelete.add(new AccountContactRole(Id = existingTechACR.Id));
                    }
                }
            }

            if (!recordsToDelete.isEmpty()) {
                System.debug(recordsToDelete);
                delete recordsToDelete;
            }
        }
    }

    public class UpdateRelatedContact extends Triggers.TriggerHandlerBase {
        private final Set<Id> acrIds = new Set<Id>();
        override public void handle() {
            for (AccountContactRoleChangeEvent event: (List<AccountContactRoleChangeEvent>) Trigger.new) {
                EventBus.ChangeEventHeader header = event.ChangeEventHeader;
                List<Id> records = (List<Id>) header.getRecordIds();

                acrIds.addAll(records);
            }

            if (!acrIds.isEmpty()) {
                this.process();
            }
        }

        public void process() {
            List<AccountContactRole> acRoles = new AccountContactRoleSelector()
                .selectAccountContactRolesById(acrIds)
                .withAllRows()
                .executeQuery();
            Map<Id, List<AccountContactRole>> contactMap = new Map<Id, List<AccountContactRole>>();
            for (AccountContactRole acr : acRoles) {
                if (contactMap.containsKey(acr.ContactId)) {
                    contactMap.get(acr.ContactId).add(acr);
                } else {
                    contactMap.put(acr.ContactId, new List<AccountContactRole>{
                        acr
                    });
                }
            }
            List<AccountContactRole> acRoleList = new List<AccountContactRole>();
            Map<Id, Contact> contactUpdateMap = new Map<Id, Contact>();
            if (contactMap.size() > 0) {
                acRoleList = new AccountContactRoleSelector()
                    .selectAccountContactRolesByContactIds2(contactMap.keySet())
                    .executeQuery();
            }

            for (AccountContactRole acr : acRoleList) {
                for (AccountContactRole acr1 : contactMap.get(acr.ContactId)) {
                    if (acr1.ContactId == acr.ContactId && acr1.AccountId == acr.AccountId) {
                        if (contactUpdateMap.containsKey(acr.ContactId)) {
                            String Role = contactUpdateMap.get(acr.ContactId).Customer_Contact_Role__c + ',' + acr.Role;
                            contactUpdateMap.put(acr.ContactId, new Contact(Id = acr.ContactId, Customer_Contact_Role__c = Role));
                        } else {
                            contactUpdateMap.put(acr.ContactId, new Contact(Id = acr.ContactId, Customer_Contact_Role__c = acr.Role));
                        }

                        break;
                    }
                }
            }
            if (contactUpdateMap.size() > 0) {
                Triggers.switchOff();
                update contactUpdateMap.values();
                Triggers.switchOn();
            }
        }
    }
}