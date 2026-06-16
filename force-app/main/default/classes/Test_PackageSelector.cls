@IsTest
private class Test_PackageSelector {
    private static void assertPackageSelector(QueryFactory factory, String selectorName, String expectedWhereClause, List<Object> bindings) {
        String query = factory.getQuery();
        Integer bindingSize = bindings.size();

        Assert.isNotNull(factory, getAssertMessageForSelector(selectorName, 'must return QuoteFactory'));
        Assert.isFalse(String.isBlank(query), getAssertMessageForSelector(selectorName, 'must compose a string query'));
        Assert.isTrue(query.contains(expectedWhereClause), getAssertMessageForSelector(selectorName, 'must have the right WHERE clause'));
        Assert.areEqual(
            bindingSize,
            factory.bindings.size(),
            getAssertMessageForSelector(selectorName, 'must have ' + String.valueOf(bindingSize) + ' input binding variables')
        );

        for (Integer i = 0; i < bindingSize; i++) {
            Assert.areEqual(
                bindings[i],
                factory.bindings[i],
                getAssertMessageForSelector(selectorName, 'must have the same value in its binding as the input')
            );
        }
    }

    private static void assertFactoryForSelectPackagesByEnterpriseAccountIds(QueryFactory factory, String selectorName, List<Object> bindings) {
        assertPackageSelector(
            factory,
            selectorName,
            'FROM Package__c WHERE Enterprise_Account_ID__c IN :bind0',
            bindings
        );
    }

    private static String getAssertMessageForSelector(String selectorName, String assertMessage) {
        return selectorName + ' ' + assertMessage;
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testSelectPackagesByAccountId() {
        Id dummyAccId = (Id) new ValueProvider.DummyIdProvider(Account.sObjectType).getValue();

        Test.startTest();
            QueryFactory factory = new PackageSelector()
                .SelectPackagesByAccountId(dummyAccId)
                .setQuery();
        Test.stopTest();

        assertPackageSelector(
            factory,
            'selectPackagesByAccountId',
            'FROM Package__c WHERE Account__c = :bind0',
            new List<Object> {dummyAccId}
        );
    }

    @isTest
    static void testSelectPackageForApproval() {
        Test.startTest();
            QueryFactory factory = new PackageSelector()
                .selectPackageForApproval()
                .setQuery();
        Test.stopTest();

        Assert.isNotNull(factory, 'The selector must return factory');
        Assert.isFalse(String.isBlank(factory.getQuery()), 'The selector must compose a string query');
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testSelectPackageByAccountBillingId() {
        String dummyBillingId = 'dummyBillingId';
        Test.startTest();
            QueryFactory factory = new PackageSelector()
                .selectPackageByAccountBillingId(dummyBillingId)
                .setQuery();
        Test.stopTest();

        assertPackageSelector(
            factory,
            'selectPackageByAccountBillingId',
            'FROM Package__c WHERE Account__r.Billing_ID__c = :bind0',
            new List<Object> {dummyBillingId}
        );
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testSelectPackagesByEnterpriseAccountIds() {
        List<Id> dummyIds = new List<Id> {(Id) new ValueProvider.DummyIdProvider(Account.sObjectType).getValue()};
        Test.startTest();
            QueryFactory factory = new PackageSelector()
                .selectPackagesByEnterpriseAccountIds(dummyIds)
                .setQuery();
        Test.stopTest();

        assertFactoryForSelectPackagesByEnterpriseAccountIds(
            factory,
            'selectPackagesByEnterpriseAccountIds',
            new List<Object> {dummyIds}
        );
    }

    @isTest
    static void testSelectPackagesByEnterpriseAccountIdsWithAccountTotals() {
        List<Id> dummyIds = new List<Id> {(Id) new ValueProvider.DummyIdProvider(Account.sObjectType).getValue()};
        Test.startTest();
            QueryFactory factory = new PackageSelector()
                .selectPackagesByEnterpriseAccountIdsWithAccountTotals(dummyIds)
                .setQuery();
        Test.stopTest();

        assertFactoryForSelectPackagesByEnterpriseAccountIds(
            factory,
            'selectPackagesByEnterpriseAccountIdsWithAccountTotals',
            new List<Object> {dummyIds}
        );
        Assert.isTrue(
            factory.getSelectedFields().containsAll(PackageSelector.FIELDS_ACCOUNT_AGGREGATED_TOTALS),
            'The selector must select fields for aggregated totals'
        );
    }

    @isTest
    static void testSelectPackagesByEnterpriseAccountIdsWithServiceFields() {
        List<Id> dummyIds = new List<Id> {(Id) new ValueProvider.DummyIdProvider(Account.sObjectType).getValue()};
        Test.startTest();
            QueryFactory factory = new PackageSelector()
                .selectPackagesByEnterpriseAccountIdsWithServiceFields(dummyIds)
                .setQuery();
        Test.stopTest();

        assertFactoryForSelectPackagesByEnterpriseAccountIds(
            factory,
            'selectPackagesByEnterpriseAccountIdsWithServiceFields',
            new List<Object> {dummyIds}
        );
        Assert.isTrue(
            factory.getSelectedFields().containsAll(PackageSelector.FIELDS_SERVICE_INFO),
            'The selector must select service info fields'
        );
        Assert.isTrue(
            factory.getSelectedFields().containsAll(PackageSelector.FIELDS_ACCOUNT_SERVICE_INFO),
            'The selector must select account service info fields'
        );
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testSelectPackagesById() {
        Id dummyPackageId = (Id) new ValueProvider.DummyIdProvider(Package__c.sObjectType).getValue();
        Test.startTest();
            QueryFactory factory = new PackageSelector()
                .selectPackagesById(new Set<Id> {dummyPackageId})
                .setQuery();
        Test.stopTest();

        assertPackageSelector(
            factory,
            'selectPackagesById',
            'FROM Package__c WHERE Id IN :bind0',
            new List<Object> {new List<Id> {dummyPackageId}}
        );
    }

    @isTest
    static void testSelectAllPackages() {
        Test.startTest();
            QueryFactory factory = new PackageSelector()
                .selectAllPackages()
                .setQuery();
        Test.stopTest();

        Assert.isNotNull(factory, 'The selector must return factory');
        Assert.isFalse(String.isBlank(factory.getQuery()), 'The selector must compose a string query');
        Assert.isTrue(
            factory.getSelectedFields().containsAll(PackageSelector.FIELDS_STANDARD),
            'The selector must return standard fields'
        );
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testSelectPackagesByIdForSyncAccountWsTest() {
        List<Id> dummyPackageIds = new List<Id> {
            (Id) new ValueProvider.DummyIdProvider(Package__c.sObjectType).getValue()
        };
        Test.startTest();
            QueryFactory factory = new PackageSelector()
                .selectPackagesByIdForSyncAccountWsTest(dummyPackageIds)
                .setQuery();
        Test.stopTest();

        assertPackageSelector(
            factory,
            'selectPackagesByIdForSyncAccountWsTest',
            'FROM Package__c WHERE Id IN :bind0',
            new List<Object> {dummyPackageIds}
        );
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testSelectPackagesForCasesById() {
        List<Id> dummyPackageIds = new List<Id> {
            (Id) new ValueProvider.DummyIdProvider(Package__c.sObjectType).getValue()
        };
        Test.startTest();
            QueryFactory factory = new PackageSelector()
                .selectPackagesForCasesById(dummyPackageIds)
                .setQuery();
        Test.stopTest();

        assertPackageSelector(
            factory,
            'selectPackagesForCasesById',
            'FROM Package__c WHERE Id IN :bind0',
            new List<Object> {dummyPackageIds}
        );
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testSelectPackagesForAccountUpdateByAccountIds() {
        List<Id> dummyAccountIds = new List<Id> {
            (Id) new ValueProvider.DummyIdProvider(Account.sObjectType).getValue()
        };
        Test.startTest();
            QueryFactory factory = new PackageSelector()
                .selectPackagesForAccountUpdateByAccountIds(dummyAccountIds)
                .setQuery();
        Test.stopTest();

        assertPackageSelector(
            factory,
            'selectPackagesForAccountUpdateByAccountIds',
            'FROM Package__c WHERE Account__c IN :bind0',
            new List<Object> {dummyAccountIds}
        );
    }

    @isTest
    static void testSelectPackagesByOpportunityIdAndServiceName() {
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Name => 'Test Account'
            })
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.Name => 'Test Opportunity',
                Opportunity.AccountId => acc.Id
            })
            .create()
            .getRecord();

        Package__c pack = (Package__c) new SObjectBuilder(Package__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Package__c.Service_Type__c => QuoteHelper.NGBS_PROFESSIONAL_SERVICES_PRODUCT,
                Package__c.Account__c => acc.Id,
                Package__c.Opportunity__c => opp.Id,
                Package__c.Account_Package_Id__c => '12345'
            })
            .create()
            .getRecord();
            
        Test.startTest();
            List<Package__c> existingPackages = (List<Package__c>) new PackageSelector()
                .selectPackagesByOpportunityIdAndServiceName(new Set<Id> {opp.Id}, QuoteHelper.NGBS_PROFESSIONAL_SERVICES_PRODUCT)
                .executeQuery();
        Test.stopTest();

        Assert.areEqual(1, existingPackages.size(), 'The selector must return one package');
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testSelectPackagesForDateFieldsUpdateByAccountIds() {
        List<Id> dummyAccountIds = new List<Id> {
            (Id) new ValueProvider.DummyIdProvider(Account.sObjectType).getValue()
        };
        Test.startTest();
            QueryFactory factory = new PackageSelector()
                .selectPackagesForDateFieldsUpdateByAccountIds(new List<Object> {dummyAccountIds})
                .setQuery();
        Test.stopTest();

        assertPackageSelector(
            factory,
            'selectPackagesForDateFieldsUpdateByAccountIds',
            'FROM Package__c WHERE Account__c IN :bind0',
            new List<Object> {dummyAccountIds}
        );
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testSelectPackagesForNewReferences() {
        List<Id> dummyAccountIds = new List<Id> {
            (Id) new ValueProvider.DummyIdProvider(Account.sObjectType).getValue()
        };
        Test.startTest();
            QueryFactory factory = new PackageSelector()
                .selectPackagesForNewReferences(new List<Object> {dummyAccountIds})
                .setQuery();
        Test.stopTest();

        assertPackageSelector(
            factory,
            'selectPackagesForNewReferences',
            'FROM Package__c WHERE Account__c IN :bind0',
            new List<Object> {dummyAccountIds}
        );
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testSelectPackagesForBatchUpdate() {
        List<Id> dummyAccountIds = new List<Id> {(Id) new ValueProvider.DummyIdProvider(Account.sObjectType).getValue()};

        Test.startTest();
            QueryFactory factory = new PackageSelector()
                .selectPackagesForBatchUpdate(dummyAccountIds)
                .setQuery();
        Test.stopTest();

        assertPackageSelector(
            factory,
            'selectPackagesForBatchUpdate',
            'FROM Package__c WHERE Account__c IN :bind0',
            new List<Object> {dummyAccountIds}
        );
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testSelectPkgsForMarketingAttributionUpdate() {
        Test.startTest();
            QueryFactory factory = new PackageSelector()
                .selectPkgsForMarketingAttributionUpdate()
                .setQuery();
        Test.stopTest();

        assertPackageSelector(
            factory,
            'selectPkgsForMarketingAttributionUpdate',
            'FROM Package__c WHERE IsUsedForAccountAttribution__c = true',
            new List<Object>()
        );
    }
}