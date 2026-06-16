/**
 * Created by Makhmud.Shafeev on 4/6/2022.
 */

public class ContractVersionController {
    List<ContractVersion__c> contractVersions;
    public Integer countTotalRecords { get; set; }
    public Integer offSetSize = 0;
    public Integer queryLimit = 10;
    public Id accountId { get; set; }

    private ApexPages.StandardController controller;

    public ContractVersionController(ApexPages.StandardController accountController) {
        this.controller = accountController;
        this.accountId = ApexPages.currentPage().getParameters().get('Id');
        this.countTotalRecords = getAllContractVersions().size();
    }

    public List<ContractVersion__c> getContractVersions() {
        contractVersions = new ContractVersionSelector()
                .selectContractVersionByAccountId(new Set<Id>{
                        accountId
                }, offSetSize, queryLimit)
                .executeQuery();
        return contractVersions;
    }

    public List<ContractVersion__c> getAllContractVersions() {
        List<ContractVersion__c> contractVersions = new ContractVersionSelector()
                .selectContractVersionByAccountId(new Set<Id>{
                        accountId
                })
                .executeQuery();
        return contractVersions;
    }

    //TODO The logic for obtaining the quantity must be universal
    public Map<String, Integer> quantityMap {
        get {
            Map<String, Integer> quantityMap = new Map<String, Integer>();
            for (List<Entitlement__c> entitlements : [
                    SELECT Id, Quantity__c, Account__c
                    FROM Entitlement__c
                    WHERE Quote__r.AccountId = :this.accountId AND Quote__r.isPrimary__c = TRUE AND Product__r.ProductCode = 'LC_DL-UNL_50'
            ]) {
                for (Entitlement__c entitlement : entitlements) {
                    quantityMap.put(entitlement.Account__c, Integer.valueOf(entitlement.Quantity__c));
                }
            }
            return quantityMap;
        }
        set {}
    }

    public Boolean getContainKey() {
        return quantityMap.containsKey(this.accountId);
    }

    public Boolean getprv() {
        if (offSetSize > 0) {
            return false;
        } else {
            return true;
        }
    }

    public Boolean getnxt() {
        if (offSetSize + queryLimit < countTotalRecords) {
            return false;
        } else {
            return true;
        }
    }

    public PageReference nextbtn() {
        offSetSize += queryLimit ;
        return null;
    }

    public PageReference prvbtn() {
        offSetSize -= queryLimit ;
        return null;
    }

    public PageReference fstbtn() {
        offSetSize = 0;
        return null;
    }

    public PageReference endbtn() {
        offSetSize = countTotalRecords - Math.mod(countTotalRecords, queryLimit);
        return null;
    }
}