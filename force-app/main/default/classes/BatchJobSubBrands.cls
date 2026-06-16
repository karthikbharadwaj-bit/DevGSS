public class BatchJobSubBrands implements Schedulable{

    public void execute(SchedulableContext sc) {
        List<SubBrandsMapping__c> subBrandMappings = (List<SubBrandsMapping__c>) new SubBrandsMappingSelector()
            .selectSubBrandsMappingRecords()
            .executeQuery();

        Datetime oneDayAgo = Datetime.now().addDays(-1);
        Set<String> partnerIds = new Set<String>();
        for (SubBrandsMapping__c mapping : subBrandMappings) {
            Boolean isNeedToUpdate = mapping.CreatedDate >= oneDayAgo || mapping.LastModifiedDate >= oneDayAgo;
            if (String.isNotBlank(mapping.PartnerID__c) && isNeedToUpdate) {
                partnerIds.add(mapping.PartnerID__c);
            }
        }

        List<Account> selectedAccounts = (List<Account>) new AccountSelector()
            .selectPartnerAccountsForUpdateSubBrands(new List<Object>{partnerIds})
            .executeQuery();

        Map<String, Account> selectedAccountsMap = new Map<String, Account>();
        Map<String, Set<String>> existingSubBrandsMap = new Map<String, Set<String>>();

        for (Account account : selectedAccounts) {
            if (String.isNotBlank(account.Sub_Brands_Permitted_To_Sell__c)) {
                existingSubBrandsMap.put(account.Partner_ID__c, new Set<String>(account.Sub_Brands_Permitted_To_Sell__c.split(';')));
            }
            selectedAccountsMap.put(account.Partner_ID__c, account);
        }

        for (SubBrandsMapping__c mapping : subBrandMappings) {
            if (String.isBlank(mapping.PartnerID__c) || selectedAccountsMap.get(mapping.PartnerID__c) == null) {
                continue;
            }
            Set<String> existingSubBrands = existingSubBrandsMap.get(mapping.PartnerID__c);
            if (existingSubBrands == null) {
                existingSubBrands = new Set<String>();
            }
            existingSubBrands.add(mapping.Sub_Brand__c);

            String subBrandPermittedToSell = String.join(new List<String>(existingSubBrands), ';');
            existingSubBrandsMap.put(mapping.PartnerID__c, existingSubBrands);

            selectedAccountsMap.get(mapping.PartnerID__c).Sub_Brands_Permitted_To_Sell__c = subBrandPermittedToSell;
        }

        if (!selectedAccountsMap.values().isEmpty()) {

            try {
                Triggers.switchOff();
                update selectedAccountsMap.values();
                Triggers.switchOn();
            } catch (Exception e) {
                System.debug('Error updating  Sub Brands Permitted To Sell on Partner Accounts: ' + e.getMessage());
            }
        }
    }
}