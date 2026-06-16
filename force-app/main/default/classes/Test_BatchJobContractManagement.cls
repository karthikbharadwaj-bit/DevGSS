@isTest
private class Test_BatchJobContractManagement {

    private static Contract createTestContract(Boolean autoRenewal, Boolean createVersion) {

        Account testAcc = (Account) new SObjectBuilder(Account.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Name => ValueProviderBuilder.provideUniqueString('Test Account')
            })
            .create()
            .getRecord();

        Contract testContract = (Contract) new SObjectBuilder(Contract.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Contract.Name => ValueProviderBuilder.provideUniqueString('Test Contract'),
                Contract.AccountId => testAcc.Id,
                Contract.Original_Signed_Date__c => System.today().addDays(-10),
                Contract.Source__c => 'Automation',
                Contract.Status => 'Draft',
                Contract.Initial_Term__c => 1,
                Contract.Original_Initial_Term__c => 1,
                Contract.Auto_Renewal__c => autoRenewal,
                Contract.Original_Auto_Renewal__c => autoRenewal,
                Contract.Start_Date__c => System.today().addDays(-10),
                Contract.Original_Start_Date__c => System.today().addDays(-10),
                Contract.End_Date__c => System.today(),
                Contract.Original_End_Date__c => System.today(),
                Contract.Renewal_Term__c => 1,
                Contract.Original_Renewal_Term__c => 1
            })
            .create()
            .getRecord();

        testContract.Status = 'Active';
        update testContract;

        if (createVersion) {
            new SObjectBuilder(ContractVersion__c.sObjectType)
                .setFields(new Map<SObjectField, Object>{
                    ContractVersion__c.Name => ValueProviderBuilder.provideUniqueString('TestName'),
                    ContractVersion__c.Contract__c => testContract.Id,
                    ContractVersion__c.Status__c => 'Active',
                    ContractVersion__c.AutoRenewal__c => testContract.Auto_Renewal__c,
                    ContractVersion__c.StartDate__c => testContract.Start_Date__c,
                    ContractVersion__c.EndDate__c => testContract.End_Date__c,
                    ContractVersion__c.RenewalTerm__c => testContract.Renewal_Term__c,
                    ContractVersion__c.InitialTerm__c => testContract.Initial_Term__c,
                    ContractVersion__c.VersionNumber__c => 1
                })
                .create();
        }

        return testContract;
    }

    @isTest
    static void testScheduleBatch() {
        Test.startTest();

            String jobId = System.schedule('test schedule', '0 0 0 5 12 ? 2030', new BatchJob_ContractManagement());

            CronTrigger ct = [SELECT Id, NextFireTime FROM CronTrigger WHERE Id = :jobId];
            System.assertEquals(
                '2030-12-05 00:00:00',
                String.valueOf(ct.NextFireTime),
                'batch should be scheduled'
            );

        Test.stopTest();
    }

    @isTest
    static void renewContractWithoutVersion() {

        Boolean isAutoRenewalContract = true;
        Boolean createVersion = false;

        Contract testContract = createTestContract(isAutoRenewalContract, createVersion);

        Test.startTest();

            BatchJob_ContractManagement b = new BatchJob_ContractManagement();
            Database.executeBatch(b);

        Test.stopTest();

        List<Contract> reselectedContracts = (List<Contract>) new ContractSelector()
            .selectActiveContractsByAccountId(new Set<Id>{ testContract.AccountId })
            .executeQuery();

        Contract renewedContract = reselectedContracts.get(0);

        System.assertEquals(
            testContract.Renewal_Term__c,
            testContract.End_Date__c.monthsBetween(renewedContract.End_Date__c),
            'count of months in End_Date__c field between original and renewed Contract should be equal to Renewal_Term__c values'
        );

        System.assertEquals(
            testContract.End_Date__c.addDays(1),
            renewedContract.Start_Date__c,
            'Start_Date__c of renewed contract should be End_Date__c + 1 day'
        );

        System.assert(!renewedContract.ContractVersions__r.isEmpty(), 'a new ContractVersion__c should be created');

        ContractVersion__c createdContractVersion = renewedContract.ContractVersions__r.get(0);

        System.assertEquals(
            testContract.End_Date__c.addDays(1),
            createdContractVersion.StartDate__c,
            'StartDate__c for created ContractVersion__c should be Contract.End_date__c + 1 day'
        );

        System.assertEquals(
            testContract.End_Date__c.addMonths(testContract.Renewal_Term__c.intValue()),
            createdContractVersion.EndDate__c,
            'EndDate__c for created ContractVersion__c should be Contract.End_date__c + count of months in Contract.Renewal_Term__c'
        );

        System.assertEquals(
            testContract.Auto_Renewal__c,
            createdContractVersion.AutoRenewal__c,
            'AutoRenewal__c flag should be copied from Contract'
        );

        System.assertEquals(
            testContract.Renewal_Term__c,
            createdContractVersion.RenewalTerm__c,
            'RenewalTerm__c should be copied from Contract.Renewal_Term__c'
        );

        System.assertEquals(
            testContract.Initial_Term__c,
            createdContractVersion.InitialTerm__c,
            'InitialTerm__c should be copied from Contract.Initial_Term__c'
        );

        System.assertEquals(
            'Active',
            createdContractVersion.Status__c,
            'Status__c of created ContractVersion__c should be "Active", but got: "' + createdContractVersion.Status__c + '"'
        );

        System.assertEquals(
            1,
            createdContractVersion.VersionNumber__c,
            'ContractVersion__c.VersionNumber__c should be 1 for the first version, but got: ' + createdContractVersion.VersionNumber__c
        );
    }

    @isTest
    static void renewContractWithVersion() {

        Boolean isAutoRenewalContract = true;
        Boolean createVersion = true;

        Contract testContract = createTestContract(isAutoRenewalContract, createVersion);

        Test.startTest();

            BatchJob_ContractManagement b = new BatchJob_ContractManagement();
            Database.executeBatch(b);

        Test.stopTest();

        List<Contract> reselectedContracts = (List<Contract>) new ContractSelector()
            .selectActiveContractsByAccountId(new Set<Id>{ testContract.AccountId })
            .executeQuery();

        Contract renewedContract = reselectedContracts.get(0);

        System.assertEquals(
            testContract.Renewal_Term__c,
            testContract.End_Date__c.monthsBetween(renewedContract.End_Date__c),
            'count of months in End_Date__c field between original and renewed Contract should be equal to Renewal_Term__c values'
        );

        System.assertEquals(
            testContract.End_Date__c.addDays(1),
            renewedContract.Start_Date__c,
            'Start_Date__c of renewed contract should be End_Date__c + 1 day'
        );

        System.assertEquals(
            2,
            renewedContract.ContractVersions__r.size(),
            'a new ContractVersion__c should be created'
        );

        ContractVersion__c createdContractVersion = renewedContract.ContractVersions__r.get(0);
        ContractVersion__c closedContractVersion = renewedContract.ContractVersions__r.get(1);

        System.assertEquals(
            'Renewed and Closed',
            closedContractVersion.Status__c,
            'Status of previous ContractVersion__c should be "Renewed and Closed" but got: ' + closedContractVersion.Status__c
        );

        System.assertEquals(
            closedContractVersion.EndDate__c.addDays(1),
            createdContractVersion.StartDate__c,
            'StartDate__c for created ContractVersion__c should be End_date__c of previous ContractVersion__c + 1 day'
        );

        System.assertEquals(
            closedContractVersion.EndDate__c.addMonths(closedContractVersion.RenewalTerm__c.intValue()),
            createdContractVersion.EndDate__c,
            'EndDate__c for created ContractVersion__c should be End_date__c of previous ContractVersion__c + ContractVersion__c.Renewal_Term__c'
        );

        System.assertEquals(
            closedContractVersion.AutoRenewal__c,
            createdContractVersion.AutoRenewal__c,
            'AutoRenewal__c flag should be copied from previous ContractVersion__c'
        );

        System.assertEquals(
            closedContractVersion.RenewalTerm__c,
            createdContractVersion.RenewalTerm__c,
            'RenewalTerm__c should be copied from previous ContractVersion__c'
        );

        System.assertEquals(
            createdContractVersion.InitialTerm__c,
            createdContractVersion.InitialTerm__c,
            'InitialTerm__c should be copied from previous ContractVersion__c'
        );

        System.assertEquals(
            'Active',
            createdContractVersion.Status__c,
            'Status__c of created ContractVersion__c should be "Active", but got: "' + createdContractVersion.Status__c + '"'
        );

        System.assertEquals(
            2,
            createdContractVersion.VersionNumber__c,
            'ContractVersion__c.VersionNumber__c should be 2, but got: ' + createdContractVersion.VersionNumber__c
        );
    }

    @isTest
    static void expireContractWithoutVersion() {

        Boolean isAutoRenewalContract = false;
        Boolean createVersion = false;

        Contract testContract = createTestContract(isAutoRenewalContract, createVersion);

        Test.startTest();

            BatchJob_ContractManagement b = new BatchJob_ContractManagement();
            Database.executeBatch(b);

        Test.stopTest();

        List<Contract> reselectedContracts = (List<Contract>) new ContractSelector()
            .selectContractsByAccountIds(
                new List<Object>{
                    'Expired',
                    new Set<Id>{ testContract.AccountId }
                }
            )
            .selectFields(
                new List<Schema.SObjectField>{
                    Contract.Name,
                    Contract.Status
                }
            )
            .subselect(
                new ContractVersionSelector()
                    .selectContractVersions()
                    .addOrdering(ContractVersion__c.VersionNumber__c, QueryFactory.SortOrder.DESCENDING, true)
            )
            .executeQuery();

        Contract expiredContract = reselectedContracts.get(0);

        System.assertEquals(
            'Expired',
            expiredContract.Status,
            'Contract.Status should be "Expired", but got: "' + expiredContract.Status + '"'
        );

        System.assert(!expiredContract.ContractVersions__r.isEmpty(), 'a ContractVersion__c should be created');

        ContractVersion__c expiredVersion = expiredContract.ContractVersions__r.get(0);

        System.assertEquals(
            testContract.Auto_Renewal__c,
            expiredVersion.AutoRenewal__c,
            'AutoRenewal__c flag should be copied from Contract'
        );

        System.assertEquals(
            testContract.Renewal_Term__c,
            expiredVersion.RenewalTerm__c,
            'RenewalTerm__c should be copied from Contract.Renewal_Term__c'
        );

        System.assertEquals(
            testContract.Initial_Term__c,
            expiredVersion.InitialTerm__c,
            'InitialTerm__c should be copied from Contract.Initial_Term__c'
        );

        System.assertEquals(
            'Expired',
            expiredVersion.Status__c,
            'Status__c of created ContractVersion__c should be "Expired", but got: "' + expiredVersion.Status__c + '"'
        );

        System.assertEquals(
            1,
            expiredVersion.VersionNumber__c,
            'ContractVersion__c.VersionNumber__c should be 1 for the first version, but got: ' + expiredVersion.VersionNumber__c
        );
    }

    @isTest
    static void expireContractWithVersion() {

        Boolean isAutoRenewalContract = false;
        Boolean createVersion = true;

        Contract testContract = createTestContract(isAutoRenewalContract, createVersion);

        Test.startTest();

            BatchJob_ContractManagement b = new BatchJob_ContractManagement();
            Database.executeBatch(b);

        Test.stopTest();

        List<Contract> reselectedContracts = (List<Contract>) new ContractSelector()
            .selectContractsByAccountIds(
                new List<Object>{
                    'Expired',
                    new Set<Id>{ testContract.AccountId }
                }
            )
            .selectFields(
                new List<Schema.SObjectField>{
                    Contract.Name,
                    Contract.Status
                }
            )
            .subselect(
                new ContractVersionSelector()
                    .selectContractVersions()
                    .addOrdering(ContractVersion__c.VersionNumber__c, QueryFactory.SortOrder.DESCENDING, true)
            )
            .executeQuery();

        Contract expiredContract = reselectedContracts.get(0);

        System.assertEquals(
            'Expired',
            expiredContract.Status,
            'Contract.Status should be "Expired", but got: "' + expiredContract.Status + '"'
        );

        System.assertEquals(
            1,
            expiredContract.ContractVersions__r.size(),
            'Batch job should not create new ContractVersion__c in case of "Contract Expiration"'
        );

        ContractVersion__c expiredVersion = expiredContract.ContractVersions__r.get(0);

        System.assertEquals(
            'Expired',
            expiredVersion.Status__c,
            'Status__c of created ContractVersion__c should be "Expired", but got: "' + expiredVersion.Status__c + '"'
        );
    }
}