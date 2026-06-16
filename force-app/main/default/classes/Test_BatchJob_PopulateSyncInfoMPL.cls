@IsTest
private class Test_BatchJob_PopulateSyncInfoMPL {
    private static final String OVERRIDE_QUERY_ASSERT_MSG = 'The overrideQuery property should be set to null when override query is not provided';
    private static final String STEP_NAMES_WERE_NOT_UPDATED_ASSERT_MSG = 'The "stepNames" parameter in SyncInfo__c field was saved incorrectly for ';

    private static final String EXPECTED_MPL_QUERY = 'SELECT Account.Billing_ID__c, Account.Offer_Type__c, Account.RC_User_ID__c, Enabled_LBO__c, Id, IsMultiProductTechnicalQuote__c, Opportunity.Id, Opportunity.SyncInfo__c, Opportunity.Type, OpportunityId, PackageNameOld__c FROM Quote WHERE IsPrimary__c = true AND Opportunity.IsClosed = true AND Opportunity.StageName = \'7. Closed Won\' AND Opportunity.CloseDate = LAST_N_DAYS:120';
    private static final String EXPECTED_OVERRIDDEN_QUERY = 'SELECT Id, Opportunity.SyncInfo__c FROM Quote';
    private static final String DUMMY_SYNC_INFO = 'DUMMY_SYNC_INFO';

    private static final String STEP_NAME_1 = 'STEP_NAME_1';
    private static final String STEP_NAME_2 = 'STEP_NAME_2';
    private static final String STEP_NAME_3 = 'STEP_NAME_3';
    private static final String SCENARIO_NAME = 'SCENARIO_NAME';
    private static final String PACKAGE_NAME_OLD = 'Old Package';

    private static final Date TODAY = Date.today();

    private static List<String> getStepNames(Opportunity opp) {
        return ((SWNSyncInfo) JSON.deserialize(opp.SyncInfo__c, SWNSyncInfo.class)).stepNames;
    }
    private static void assertQueryLocator(Database.QueryLocator ql, Boolean isOverridden) {
        Assert.isNotNull(ql, 'A QueryLocator must be returned');

        String expectedQuery = isOverridden ? EXPECTED_OVERRIDDEN_QUERY : EXPECTED_MPL_QUERY;
        String qry = ql.getQuery();
        Assert.areEqual(expectedQuery, qry, 'The query in the QueryLocator does not match the expected query');

        if (isOverridden) {
            return;
        }
        List<SObject> queriedRecords = Database.query(qry);
        Assert.areEqual(
            Quote.getSObjectType(),
            queriedRecords.getSObjectType(),
            'The queried records for MPL must be of type Quote'
        );
    }

    @isTest
    static void testConstructor() {
        Test.startTest();
            BatchJob_PopulateSyncInfoMPL normalBatch = new BatchJob_PopulateSyncInfoMPL();
            BatchJob_PopulateSyncInfoMPL overriddenBatch = new BatchJob_PopulateSyncInfoMPL(EXPECTED_OVERRIDDEN_QUERY);
        Test.stopTest();

        Assert.isNull(normalBatch.overrideQuery, OVERRIDE_QUERY_ASSERT_MSG);
        Assert.areEqual(EXPECTED_OVERRIDDEN_QUERY, overriddenBatch.overrideQuery, 'The overrideQuery property should be set to the provided query');
    }

    @isTest
    static void testExecuteMethod() {
        List<String> stepNames = new List<String> { STEP_NAME_1, SWNStep.REPRICE_SYNC, STEP_NAME_2, SWNStep.ORDER, SWNStep.DISCOUNT_SYNC, STEP_NAME_3, SWNStep.CONTRACT_SYNC };
        new SWNMockBuilders.ScenarioBuilder(SCENARIO_NAME)
            .addSteps(stepNames)
            .putSteps()
            .buildAndPut();
        String syncInfoWithStepNames = new SWNMockBuilders.SyncInfoBuilder(stepNames, SCENARIO_NAME)
            .build()
            .getAsJson();
        SWNSyncInfo syncInfoWithoutStepNamesButAllStepsAreCompleted = new SWNMockBuilders.SyncInfoBuilder(stepNames, SCENARIO_NAME)
            .build()
            .getSyncInfo();
        syncInfoWithoutStepNamesButAllStepsAreCompleted.stepNames = null;
        SWNSyncInfo syncInfoWithoutStepNames = new SWNMockBuilders.SyncInfoBuilder(new List<String>(), SCENARIO_NAME)
            .build()
            .getSyncInfo();
        syncInfoWithoutStepNames.stepNames = null;
        List<String> syncInfosToProvide = new List<String> {
            null,
            syncInfoWithStepNames,
            JSON.serialize(syncInfoWithoutStepNamesButAllStepsAreCompleted).remove('"stepNames":null,'),
            JSON.serialize(syncInfoWithoutStepNames).remove('"stepNames":null,')
        };
        List<String> oppNames = new List<String> {
            'null',
            'syncInfoWithStepNames',
            'syncInfoWithoutStepNamesButAllStepsAreCompleted',
            'syncInfoWithoutStepNames'
        };

        Triggers.switchOff();
        Account acc = (Account) new SobjectBuilder(Account.sObjectType).create().getRecord();
        List<Opportunity> opportunities = (List<Opportunity>) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.SyncInfo__c => ValueProviderBuilder.provideList(syncInfosToProvide),
                Opportunity.Name => ValueProviderBuilder.provideList(oppNames),
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_CLOSED_WON,
                Opportunity.CloseDate => TODAY,
                Opportunity.AccountId => acc.Id
            })
            .quantity(syncInfosToProvide.size())
            .create()
            .getRecords();
        List<Quote> quotes = (List<Quote>) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.Enabled_LBO__c => true,
                Quote.PackageNameOld__c => PACKAGE_NAME_OLD,
                Quote.IsMultiProductTechnicalQuote__c => true
            })
            .quantity(opportunities.size())
            .build()
            .getRecords();
        Triggers.switchOn();
        for (Integer i = 0; i < opportunities.size(); i++) {
            quotes[i].Opportunity = opportunities[i];
            quotes[i].OpportunityId = opportunities[i].Id;
        }

        Opportunity opportunityWithNoSyncInfo = opportunities[0];
        Opportunity opportunityWithStepNames = opportunities[1];
        Opportunity opportunityWithoutStepNamesButAllStepsAreCompleted = opportunities[2];
        Opportunity opportunityWithoutStepNames = opportunities[3];

        BatchJob_PopulateSyncInfoMPL batch = new BatchJob_PopulateSyncInfoMPL();
        Test.startTest();
            batch.execute(null, quotes);
        Test.stopTest();

        Map<Id, Opportunity> resultedOpps= new Map<Id, Opportunity>((List<Opportunity>) new OpportunitySelector()
            .newQueryFactory()
            .setFactoryName('resultedOpps')
            .selectFields(new Set<SObjectField> {
                Opportunity.Id,
                Opportunity.Name,
                Opportunity.SyncInfo__c
            })
            .setCondition('Id IN :bind0')
            .setQueryBindings(new Map<Id, Opportunity>(opportunities).keySet())
            .executeQuery());
        Assert.isNull(
            resultedOpps.get(opportunityWithNoSyncInfo.Id).SyncInfo__c,
            'The SyncInfo__c field should be null if the SyncInfo was null in the original record'
        );
        Assert.areEqual(
            opportunityWithStepNames.SyncInfo__c,
            resultedOpps.get(opportunityWithStepNames.Id).SyncInfo__c,
            'The SyncInfo__c field should be the same as the SyncInfo in the original record, if it already had step names in it'
        );
        Assert.areEqual(
            new List<String> {SWNStep.REPRICE_SYNC, SWNStep.DISCOUNT_SYNC, SWNStep.CONTRACT_SYNC},
            getStepNames(resultedOpps.get(opportunityWithoutStepNames.Id)),
            STEP_NAMES_WERE_NOT_UPDATED_ASSERT_MSG + opportunityWithoutStepNames.Name
        );
        Assert.areEqual(
            stepNames,
            getStepNames(resultedOpps.get(opportunityWithoutStepNamesButAllStepsAreCompleted.Id)),
            'The "stepNames" parameter in SyncInfo__c field should contain all completed steps in the preserved order'
        );
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testStart() {
        BatchJob_PopulateSyncInfoMPL batch = new BatchJob_PopulateSyncInfoMPL();
        BatchJob_PopulateSyncInfoMPL overriddenBatch = new BatchJob_PopulateSyncInfoMPL(EXPECTED_OVERRIDDEN_QUERY);
        Test.startTest();
            Database.QueryLocator normalQueryLocator = batch.start(null);
            Database.QueryLocator overriddenQueryLocator = overriddenBatch.start(null);
        Test.stopTest();

        assertQueryLocator(normalQueryLocator, false);
        assertQueryLocator(overriddenQueryLocator, true);
    }
}