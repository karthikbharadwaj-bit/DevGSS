public with sharing class BatchJob_ContractManagement implements Database.Batchable<sObject>, Schedulable  {
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return new ContractSelector().selectContractsForContractManagementBatch().executeQueryLocator();
    }

    public void execute(Database.BatchableContext bc, List<sObject> scope) {

        List<Contract> contractList = (List<Contract>) scope;

        List<Contract> updatedContracts = new List<Contract>();
        List<ContractVersion__c> contractVerions = new List<ContractVersion__c>();
        for (Contract con : contractList) {
            String accName = con.Account.Name;

            if (con.Auto_Renewal__c) {
                ContractData renewResult = renewContract(con, accName);
                updatedContracts.add(renewResult.updatedContract);
                contractVerions.addAll(renewResult.contractVersions);
            } else {
                ContractData expireResult = expireContract(con, accName);
                updatedContracts.add(expireResult.updatedContract);
                contractVerions.addAll(expireResult.contractVersions);
            }
        }

        update updatedContracts;

        upsert contractVerions;
    }

    public void execute(SchedulableContext schedulableContext) {
        Database.executeBatch(new BatchJob_ContractManagement());
    }

    public void finish(Database.BatchableContext bc) {}

    private class ContractData {
        public Contract updatedContract;
        public List<ContractVersion__c> contractVersions = new List<ContractVersion__c>();

        public ContractData(Contract con, ContractVersion__c version) {
            this.updatedContract = con;

            if (version != null) {
                this.contractVersions.add(version);
            }
        }

        public ContractData(Contract con, ContractVersion__c updatedVersion, ContractVersion__c newVersion) {
            this(con, updatedVersion);

            if (newVersion != null) {
                this.contractVersions.add(newVersion);
            }
        }
    }

    private ContractData renewContract(Contract con, String accountName) {

        ContractVersion__c lastContractVersion = !con.ContractVersions__r.isEmpty() ? con.ContractVersions__r.get(0) : null;

        Date endDate;
        Integer renewalTerm;

        if (lastContractVersion == null) {
            endDate = con.End_Date__c;
            renewalTerm = con.Renewal_Term__c.intValue();
        } else {
            endDate = lastContractVersion.EndDate__c;
            renewalTerm = lastContractVersion.RenewalTerm__c.intValue();

            lastContractVersion.Status__c = 'Renewed and Closed';
        }

        con.Start_Date__c = con.End_Date__c.addDays(1);
        con.End_Date__c = endDate.addMonths(renewalTerm);

        ContractVersion__c newContractVersion = renewContractVersion(con, lastContractVersion, accountName);

        return new ContractData(con, lastContractVersion, newContractVersion);
    }

    private ContractVersion__c renewContractVersion(Contract con, ContractVersion__c previousVersion, String accountName) {

        ContractVersion__c newContractVersion;

        if (con == null) {
            return newContractVersion;
        }

        if (previousVersion == null) {
            newContractVersion = buildContractVersion(con);
            newContractVersion.Status__c = 'Active';
        } else {
            newContractVersion = previousVersion.clone(false, true);
            newContractVersion.Status__c = 'Active';
            newContractVersion.StartDate__c = con.Start_Date__c;
            newContractVersion.EndDate__c = con.End_Date__c;
            newContractVersion.VersionNumber__c = previousVersion.VersionNumber__c + 1;
        }

        newContractVersion.Name = buildVersionName(accountName, newContractVersion.VersionNumber__c.intValue());

        return newContractVersion;
    }

    private ContractData expireContract(Contract con, String accountName) {

        con.Status = 'Expired';

        ContractVersion__c lastContractVersion = !con.ContractVersions__r.isEmpty() ? con.ContractVersions__r.get(0) : null;
        if (lastContractVersion == null) {
            lastContractVersion = buildContractVersion(con);
            lastContractVersion.Status__c = 'Expired';
            lastContractVersion.Name = buildVersionName(accountName, lastContractVersion.VersionNumber__c.intValue());
        } else {
            lastContractVersion.Status__c = 'Expired';
        }

        return new ContractData(con, lastContractVersion);
    }

    private ContractVersion__c buildContractVersion(Contract con) {
        ContractVersion__c version;

        if (con == null) {
            return version;
        }

        version = new ContractVersion__c(
            Contract__c = con.Id,
            AutoRenewal__c = con.Auto_Renewal__c,
            StartDate__c = con.Start_Date__c,
            EndDate__c = con.End_Date__c,
            RenewalTerm__c = con.Renewal_Term__c,
            InitialTerm__c = con.Initial_Term__c,
            VersionNumber__c = 1
        );

        return version;
    }

    private String buildVersionName(String accountName, Integer versionNumber) {
        if (String.isBlank(accountName)) {
            accountName = '';
        } else {
            accountName += ' ';
        }

        if (versionNumber == null) {
            versionNumber = 1;
        }

        return accountName + 'Version ' + versionNumber;
    }
}