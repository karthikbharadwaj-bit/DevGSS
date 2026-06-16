public class BatchJob_MarketingAttributionProcessing implements Database.Batchable<sObject> {

    public Database.QueryLocator start(Database.BatchableContext BC) {
        return selectAccounts()
            .executeQueryLocator();
    }

    public void execute(Database.BatchableContext BC, List<Account> scope) {
        Map<Id, Account> accIdToAccountMap = new Map<Id, Account>(scope);
        Map<Id, Account> accountsToUpdate = new Map<Id, Account>();

        List<Package__c> pkgs = (List<Package__c>) selectPackages(
            accIdToAccountMap.keySet(),
            PackageSelector.FIELDS_PACKAGE_UPDATE_MARKETING_ATTRIBUTION
        ).executeQuery();

        Map<Id, List<Package__c>> accIdToPackagesMap = new Map<Id, List<Package__c>>();
        for (Package__c pkg : pkgs) {
            if (!accIdToPackagesMap.containsKey(pkg.Account__c)) {
                accIdToPackagesMap.put(pkg.Account__c, new List<Package__c>());
            }
            accIdToPackagesMap.get(pkg.Account__c).add(pkg);
        }

        Map<Id, Package__c> accIdToPackageMap = PackageHelper.collectAccIdToPackageMap(accIdToPackagesMap);

        for (Id accId : accIdToPackageMap.keySet()) {
            Account accountToUpdate = accIdToAccountMap.get(accId);
            Package__c targetPackage = accIdToPackageMap.get(accId);

            AccountHelper.prepareAccountForUpdating(targetPackage, accountToUpdate, accountsToUpdate);
            targetPackage.IsUsedForAccountAttribution__c = true;
        }

        Triggers.switchOff();
        if (!accIdToPackageMap.isEmpty()) {
            update accIdToPackageMap.values();
        }

        if (!accountsToUpdate.isEmpty()) {
            update accountsToUpdate.values();
        }
        Triggers.switchOn();
    }
    
    public void finish(Database.BatchableContext BC) {}

    // These selectors are placed here because they are used only in this class and should not be exposed to other classes
    @TestVisible
    private QueryFactory selectAccounts() {
        return new QueryFactory(new AccountSelector())
            .setFactoryName('selectAccsForMarketingAttributionProcessingBatch')
            .withoutSelectorFieldsIncluded()
            .withoutSelectorOrderByIncluded()
            .withoutSelectFieldsSorted()
            .selectFields(AccountSelector.FIELDS_ACCOUNT_UPDATE_MARKETING_ATTRIBUTION)
            .setCondition('Id IN (' + selectPackages().setQuery().getQuery() +')');
    }

    @TestVisible
    private QueryFactory selectPackages() {
        return selectPackages(new Set<Id>(), new Set<SObjectField>()); 
    }

    private QueryFactory selectPackages(Set<Id> accIds, Set<SObjectField> fields) {
        return new QueryFactory(new PackageSelector())
            .setFactoryName('selectPkgsForMarketingAttributionUpdateByAccIds')
            .selectFields(fields)
            .selectField(Package__c.Account__c)
            .withoutSelectorFieldsIncluded()
            .withoutSelectorOrderByIncluded()
            .withoutSelectFieldsSorted()
            .setCondition(buildConditionForPackageSelector(!accIds.isEmpty()))
            .setQueryBindings(new List<Object> { accIds} );
    }

    private String buildConditionForPackageSelector(Boolean withAccountFilter) {
        // 2024-11-01T00:00:00Z - date of MPUB release
        String conditionString = 'LastModifiedDate >= 2024-11-01T00:00:00Z'
            + ' AND Package_Status__c NOT IN (\'\'Deleted\'\', \'\'Disabled\'\', \'\'Canceled\'\', \'\'Cancelled\'\')'
            + (withAccountFilter ? ' AND Account__c IN :bind0' : '')
            + ' AND ({0})';

        List<String> conditions = new List<String>();
        for (SObjectField field : PackageSelector.FIELDS_PACKAGE_REMEDIATION_MARKETING_ATTRIBUTION) {
            conditions.add(field.getDescribe().getName() + ' != null');
        }
        return String.format(conditionString, new List<String> { String.join(conditions, ' OR ')});
    }
}