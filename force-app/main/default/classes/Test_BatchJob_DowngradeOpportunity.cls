@isTest
private class Test_BatchJob_DowngradeOpportunity {
    private static final String TEST_ACCOUNT_NAME = 'Test Account';
    private static final String TEST_OPPORTUNITY_NAME = 'Test Opportunity';
    private static final String TEST_QUOTE_NAME = 'Test Quote';
    private static final Integer TEST_OPPORTUNITY_AMOUNT = 10;

    @testSetup
    static void setup() {
        List<Account> testAccs = (List<Account>) new SobjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Name => ValueProviderBuilder.provideUniqueString(TEST_ACCOUNT_NAME)
            })
            .quantity(2)
            .create()
            .getRecords();

        new SobjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.Name => ValueProviderBuilder.provideUniqueString(TEST_OPPORTUNITY_NAME),
                Opportunity.AccountId => ValueProviderBuilder.provideParents(testAccs),
                Opportunity.RecordTypeId => OpportunityHelper.RT_ID_NEW_SALES_OPPORTUNITY,
                Opportunity.Type => OpportunityHelper.OPPORTUNITY_TYPE_EX_BUSINESS,
                Opportunity.StageName => ValueProviderBuilder.provideList(new List<String>(OpportunityHelper.STAGE_NAMES_OPEN)),
                Opportunity.CloseDate => Date.Today() + 10,
                Opportunity.CurrencyIsoCode => OpportunityHelper.CURRENCY_ISO_CODE_USD,
                Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL
            })
            .quantity(TEST_OPPORTUNITY_AMOUNT)
            .create();
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testDowngradeOpportunity() {
        List<Opportunity> testOppsToClose = selectTestOpportunities(TEST_OPPORTUNITY_AMOUNT - 1);
        Set<Id> testOppIdsToDowngrade = getSetIds(testOppsToClose);

        Test.startTest();
            Database.executeBatch(new BatchJob_DowngradeOpportunity(testOppIdsToDowngrade));
        Test.stopTest();

        assertOpportunities(selectTestOpportunities(TEST_OPPORTUNITY_AMOUNT), testOppIdsToDowngrade);
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testDowngradeOpportunityWithQuotes() {
        List<Opportunity> testOppsToDowngrade = selectTestOpportunities(TEST_OPPORTUNITY_AMOUNT);
        Set<Id> testOppIdsToDowngrade = getSetIds(testOppsToDowngrade);

        Set<Id> testOppIdsWithQuotes = testOppIdsToDowngrade.clone();
        testOppIdsWithQuotes.remove(testOppsToDowngrade[TEST_OPPORTUNITY_AMOUNT - 1].Id);
        new SObjectBuilder(Quote.sObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    Quote.Name => ValueProviderBuilder.provideUniqueString(TEST_QUOTE_NAME),
                    Quote.OpportunityId => ValueProviderBuilder.provideParents(testOppIdsWithQuotes),
                    Quote.RecordTypeId => QuoteHelper.RT_ID_SALES,
                    Quote.Pricebook2Id => Test.getStandardPricebookId(),
                    Quote.Status => ValueProviderBuilder.provideList(
                        new List<String> {
                            QuoteHelper.QUOTE_STATUS_DRAFT,
                            QuoteHelper.QUOTE_STATUS_TERMINATED,
                            QuoteHelper.QUOTE_STATUS_PRESENTED
                        }
                    )
                }
            )
            .quantity(TEST_OPPORTUNITY_AMOUNT)
            .create();

        Test.startTest();
            Database.executeBatch(new BatchJob_DowngradeOpportunity(testOppIdsToDowngrade));
        Test.stopTest();

        assertOpportunities(selectTestOpportunities(TEST_OPPORTUNITY_AMOUNT), testOppIdsToDowngrade);
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testWhenInputOpportunityIsAlreadyClosed() {
        List<Opportunity> testOppsToDowngrade = selectTestOpportunities(TEST_OPPORTUNITY_AMOUNT);
        Opportunity testClosedOpp = testOppsToDowngrade[0];
        testClosedOpp.StageName = OpportunityHelper.STAGE_NAME_CLOSED_WON;

        Triggers.switchOff();
        update testClosedOpp;
        Triggers.switchOn();

        Set<Id> inputIds = getSetIds(testOppsToDowngrade);
        Test.startTest();
            Database.executeBatch(new BatchJob_DowngradeOpportunity(inputIds));
        Test.stopTest();

        Set<Id> expectedToBeDowngradedIds = inputIds.clone();
        expectedToBeDowngradedIds.remove(testClosedOpp.Id);
        assertOpportunities(selectTestOpportunities(TEST_OPPORTUNITY_AMOUNT), inputIds, expectedToBeDowngradedIds);
    }

    private static List<Opportunity> selectTestOpportunities(Integer amountToSelect) {
        return (List<Opportunity>) new OpportunitySelector()
            .newQueryFactory()
            .selectField(Opportunity.Id)
            .selectField(Opportunity.StageName)
            .selectField(Opportunity.Downgrade_Reason_Opp__c)
            .setCondition('Name LIKE :bind0')
            .setQueryBindings(new List<Object> {'%' + TEST_OPPORTUNITY_NAME + '%'})
            .addOrdering(Opportunity.StageName, QueryFactory.SortOrder.ASCENDING)
            .setLimit(amountToSelect)
            .executeQuery();
    }

    private static Boolean isOppUntouchedByBatch(Opportunity testOpp) {
        return testOpp?.Downgrade_Reason_Opp__c != OpportunityHelper.DOWNGRADE_REASON_MIGRATING_THIS_ACCOUNT_FROM_LEGACY_CC;
    }

    private static void assertOpportunities(List<Opportunity> testOpportunities, Set<Id> inputIds) {
        assertOpportunities(testOpportunities, inputIds, inputIds);
    }

    private static void assertOpportunities(List<Opportunity> testOpportunities, Set<Id> inputIds, Set<Id> expectedToBeDowngradedIds) {
        for (Opportunity testOpp : testOpportunities) {
            if (inputIds.contains(testOpp.Id)) {
                assertInputtedOpportunity(testOpp, expectedToBeDowngradedIds);
            } else {
                assertUntouchedOpportunity(testOpp);
            }
        }
    }

    private static void assertInputtedOpportunity(Opportunity testOpportunity, Set<Id> expectedToBeDowngradedIds) {
        if (!expectedToBeDowngradedIds.contains(testOpportunity.Id)) {
            assertUntouchedOpportunity(testOpportunity);
            return;
        }

        Assert.areEqual(
            OpportunityHelper.STAGE_NAME_DOWNGRADED,
            testOpportunity.StageName,
            'The BatchJob_DowngradeOpportunity must downgrade all inputted opportunities'
        );
        Assert.areEqual(
            OpportunityHelper.DOWNGRADE_REASON_MIGRATING_THIS_ACCOUNT_FROM_LEGACY_CC,
            testOpportunity.Downgrade_Reason_Opp__c,
            'Opportunity has an incorrect downgrade reason'
        );
    }

    private static void assertUntouchedOpportunity(Opportunity testOpportunity) {
        Assert.isTrue(
            isOppUntouchedByBatch(testOpportunity),
            'The BatchJob_DowngradeOpportunity Downgraded wrong Opportunity!'
        );
    }

    private static Set<Id> getSetIds(List<SObject> records) {
        return new Map<Id, SObject>(records).keySet();
    }
}