@isTest
public with sharing class Test_PostCopyContractsInsert {
    @testSetup
    private static void createTestData() {
        new SObjectBuilder(PostCopyTasks__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
            PostCopyTasks__c.Name => 'Insert Contracts',
            PostCopyTasks__c.DeveloperName__c => 'PostCopyContractsInsert',
            PostCopyTasks__c.Active__c => true,
            PostCopyTasks__c.OrderNumber__c => 1
        }).create();
    }

    @isTest
    private static void testContractsInsertOnEmptyBox() {
        Test.startTest();
        Test.testSandboxPostCopyScript(
            new PostCopyManager(),
            UserInfo.getOrganizationId(),
            UserInfo.getOrganizationId(),
            UserInfo.getOrganizationName()
        );
        Test.stopTest();

        // actual values
        Map<Id, Contract__c> actualContracts = new Map<Id, Contract__c>(
            (List<Contract__c>) new BillingContractSelector()
                .selectContractsWithDiscounts()
                .executeQuery()
        );
        List<Contract_Discount__c> actualDiscounts = new QueryFactory(Contract_Discount__c.sObjectType)
            .selectField(Contract_Discount__c.Contract__c)
            .executeQuery();

        Set<String> actualContractsExtIds = new Set<String>();
        for (Contract__c c : actualContracts.values()) {
            actualContractsExtIds.add(c.ExtID__c);
        }

        // expected values
        Set<String> expectedContractExtIds = new Set<String>();
        Map<String, Integer> expectedContractToDiscountNumber = new Map<String, Integer>();

        for (PostCopyContractsInsert.ContractWithDiscounts contract : PostCopyContractsInsert.CONTRACTS) {
            expectedContractExtIds.add(contract.extId);
            expectedContractToDiscountNumber.put(contract.extId, contract.discounts.size());
        }

        System.assertEquals(expectedContractExtIds.size(), actualContracts.values().size(), 'All Contracts should be created');
        System.assert(actualContractsExtIds.containsAll(expectedContractExtIds), 'All Contracts should be created');

        for (Contract__c contract : actualContracts.values()) {
            Integer expectedNumberOfContracts = expectedContractToDiscountNumber.get(contract.ExtID__c);
            Integer actualNumberOfContracts = contract.Contract_Discounts__r.size();
            System.assertEquals(expectedNumberOfContracts, actualNumberOfContracts, 'Number of created discounts is wrong');
        }

        for (Contract_Discount__c c : actualDiscounts) {
            System.assertNotEquals(null, c.Contract__c, 'All created discounts should be linked with contracts');
            System.assert(actualContracts.keySet().contains(c.Contract__c),
                'All created discounts should be linked with contracts');
        }
    }

    @isTest
    private static void testContractsInsertOnBoxWithContracts() {
        List<String> createdContractExtIds = new List<String>{'Office_RO_EU', 'Test'};
        List<Contract__c> createdContracts = new SObjectBuilder(Contract__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Contract__c.Name => ValueProviderBuilder.provideList(new List<String>{'Office Contract', 'Test'}),
                Contract__c.ExtID__c => ValueProviderBuilder.provideList(createdContractExtIds),
                Contract__c.Active__c => ValueProviderBuilder.provideList(new List<Boolean>{true, false}),
                Contract__c.Available_in_packages__c => PostCopyContractsInsert.PACKAGES_OFFICE_RAINBOW,
                Contract__c.Billing_Countries__c => 'Belgium;Italy;Spain;Ireland',
                Contract__c.Business_Identities_Countries__c => 'France',
                Contract__c.CurrencyIsoCode => RingCentralHelper.EUR
            })
            .quantity(2)
            .create()
            .getRecords();

        new SObjectBuilder(Contract_Discount__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Contract_Discount__c.Name => 'DigitalLine Unlimited',
                Contract_Discount__c.Discount__c => 3,
                Contract_Discount__c.Duration__c => Product2Helper.CHARGE_TERM_MONTHLY,
                Contract_Discount__c.ApplicableTo__c => Product2Helper.DL_UNL_ELEMENT_ID,
                Contract_Discount__c.Contract__c => createdContracts[0].Id,
                Contract_Discount__c.CurrencyIsoCode => createdContracts[0].CurrencyIsoCode
            })
            .create()
            .getRecord();

        Test.startTest();
        Test.testSandboxPostCopyScript(
            new PostCopyManager(),
            UserInfo.getOrganizationId(),
            UserInfo.getOrganizationId(),
            UserInfo.getOrganizationName()
        );
        Test.stopTest();

        // actual values
        Map<Id, Contract__c> actualContracts = new Map<Id, Contract__c>(
            (List<Contract__c>) new BillingContractSelector()
                .selectContractsWithDiscounts()
                .executeQuery()
        );
        List<Contract_Discount__c> actualDiscounts = new QueryFactory(Contract_Discount__c.sObjectType)
            .selectField(Contract_Discount__c.Contract__c)
            .executeQuery();

        Set<String> actualContractExtIds = new Set<String>();
        for (Contract__c c : actualContracts.values()) {
            if ('Test'.equalsIgnoreCase(c.Name)) {
                System.assert(!c.Active__c, 'Created test contract should be inactive');
            }
            actualContractExtIds.add(c.ExtID__c);
        }

        // expected values
        Set<String> expectedContractExtIds = new Set<String>();
        Map<String, Integer> expectedContractToDiscountNumber = new Map<String, Integer>();

        for (PostCopyContractsInsert.ContractWithDiscounts contract : PostCopyContractsInsert.CONTRACTS) {
            expectedContractExtIds.add(contract.extId);
            expectedContractToDiscountNumber.put(contract.extId, contract.discounts.size());
        }

        System.assert(actualContractExtIds.containsAll(expectedContractExtIds), 'New Contracts should be added to the new ones');

        for (Contract__c contract : actualContracts.values()) {
            if ('Test'.equalsIgnoreCase(contract.Name)) {
                System.assertEquals(contract.Contract_Discounts__r.size(), 0, 'There should be no discounts for Test contract');
                continue;
            }
            if ('Office Contract'.equalsIgnoreCase(contract.Name) && 'Office_RO_EU'.equalsIgnoreCase(contract.ExtID__c)) {
                System.assertEquals(
                    contract.Contract_Discounts__r.size(),
                    PostCopyContractsInsert.DISCOUNTS_MAP_WITH_US_C.size(),
                    'There should be ' + PostCopyContractsInsert.DISCOUNTS_MAP_WITH_US_C.size() + ' discounts for Office contract'
                );
                continue;
            }
            Integer expectedNumberOfContracts = expectedContractToDiscountNumber.get(contract.ExtID__c);
            Integer actualNumberOfContracts = contract.Contract_Discounts__r.size();
            System.assertEquals(expectedNumberOfContracts, actualNumberOfContracts, 'Number of created discounts is wrong for ' + contract.Name);
        }

        for (Contract_Discount__c c : actualDiscounts) {
            System.assertNotEquals(null, c.Contract__c, 'All created discounts should be linked with contracts');
        }
    }
}