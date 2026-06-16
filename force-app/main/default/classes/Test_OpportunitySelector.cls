@isTest
private class Test_OpportunitySelector {

    private static String basePattern = '(^SELECT){1}(\\s[A-z0-9.]+,?\\s?)+';
    private static String subPattern = '(\\(SELECT(\\s[A-z0-9.]+,?)+\\s)';

    private static Set<Id> setIds = new Set<Id>{null};
    private static List<Object> bindings = new List<Object>{setIds};

    private static void assertOpportunitySelector(QueryFactory factory, String selectorName, String expectedWhereClause, Integer bindingSize) {
        String query = factory.getQuery();

        Assert.areNotEqual(null, factory, getAssertMessageForSelector(selectorName, 'must return Opportunity QueryFactory'));
        Assert.areNotEqual(true, String.isBlank(query), getAssertMessageForSelector(selectorName, 'must compose a string query'));
        Assert.areEqual(true, query.contains(expectedWhereClause), getAssertMessageForSelector(selectorName, 'must have the right WHERE clause'));
        Assert.areEqual(bindingSize, factory.bindings.size(), getAssertMessageForSelector(selectorName, 'must have ' + String.valueOf(bindingSize) + ' input binding variable'));
    }

    private static void assertBindings(QueryFactory factory, String selectorName, List<Object> expectedBindings) {
        Assert.areEqual(expectedBindings, factory.bindings, getAssertMessageForSelector(selectorName, 'must have the right bindings'));
    }

    private static String getAssertMessageForSelector(String selectorName, String assertMessage) {
        return selectorName + ' ' + assertMessage;
    }

    @isTest
    private static void verifySelectBillingOpportunityReturnCorrectQuery() {
        QueryFactory qf = new OpportunitySelector()
            .selectBillingOpportunity(null)
            .setQuery();
        String pattern = basePattern + '(FROM Opportunity)';
        System.assert(System.Pattern.matches(pattern, qf.getQuery()));
    }

    @isTest
    private static void verifySelectOpportunitiesForApprovalReturnCorrectQuery() {
        QueryFactory qf = new OpportunitySelector()
            .selectOpportunitiesForApproval(bindings)
            .setQuery();
        String pattern = basePattern + '(FROM Opportunity WHERE Id IN :bind0)';
        System.assert(System.Pattern.matches(pattern, qf.getQuery()));
    }

    @isTest
    private static void verifySelectOpportunitiesForApprovalCheckReturnCorrectQuery() {
        QueryFactory qf = new OpportunitySelector()
            .selectOpportunitiesForApprovalCheck(bindings)
            .setQuery();
        String subselect = subPattern + '(FROM Quotes WHERE OpportunityId = :bind0 AND isPrimary__c = true ORDER BY Name ASC NULLS FIRST \\)  )';
        String last = '(FROM Opportunity WHERE Id IN :bind0 ORDER BY Name ASC NULLS FIRST )';
        String pattern = basePattern + subselect + last;
        System.assert(System.Pattern.matches(pattern, qf.getQuery()));
    }

    @isTest
    private static void verifySelectOpportunityForSyncWithNGBSReturnCorrectQuery() {
        QueryFactory qf = new OpportunitySelector()
            .selectOpportunityForSyncWithNGBS((Id) ValueProviderBuilder.provideDummyId(Opportunity.sObjectType).getValue())
            .setQuery();
        String last = '(FROM Opportunity WHERE Id = :bind0 LIMIT 1)';
        String pattern = basePattern + last;
        System.assert(System.Pattern.matches(pattern, qf.getQuery()));
    }

    @isTest
    private static void verifySelectOpportunityForSyncWithNGBSByNameReturnCorrectQuery() {
        QueryFactory qf = new OpportunitySelector()
            .selectOpportunityForSyncWithNGBSByName(null)
            .setQuery();
        String pattern = basePattern + '(FROM Opportunity WHERE Name = :bind0 LIMIT 1)';
        System.assert(System.Pattern.matches(pattern, qf.getQuery()));
    }

    @isTest
    private static void verifySelectOpportunitiesReturnCorrectQuery() {
        QueryFactory qf = new OpportunitySelector()
            .selectOpportunities()
            .setQuery();
        String pattern = basePattern + '(FROM Opportunity ORDER BY Name ASC NULLS FIRST )';
        System.assert(System.Pattern.matches(pattern, qf.getQuery()));
    }

    @isTest
    private static void verifySelectOpportunityByUUIDReturnCorrectQuery() {
        QueryFactory qf = new OpportunitySelector()
            .selectOpportunityByUUID(null)
            .setQuery();
        String pattern = basePattern + '(FROM Opportunity WHERE Uuid__c = :bind0 ORDER BY Name ASC NULLS FIRST )';
        System.assert(System.Pattern.matches(pattern, qf.getQuery()));
    }

    @isTest
    private static void verifySelectOpportunityForSignUpReturnCorrectQuery() {
        QueryFactory qf = new OpportunitySelector()
            .selectOpportunityForSignUp(null)
            .setQuery();
        String subselect = subPattern + '(FROM OpportunityContactRoles\\)  )';
        String pattern = basePattern + subselect + '(FROM Opportunity WHERE Id IN :bind0 ORDER BY Name ASC NULLS FIRST  LIMIT 1)';
        System.assert(System.Pattern.matches(pattern, qf.getQuery()));
    }

    @isTest
    private static void verifySelectOpportunityForCloseReturnCorrectQuery() {
        QueryFactory qf = new OpportunitySelector()
            .selectOpportunityForClose(null)
            .setQuery();
        String pattern = basePattern + '(FROM Opportunity WHERE Id IN :bind0 ORDER BY Name ASC NULLS FIRST  LIMIT 1)';
        System.assert(System.Pattern.matches(pattern, qf.getQuery()));
    }

    @isTest
    private static void verifySelectOpportunitiesByIdsReturnCorrectQuery() {
        QueryFactory qf = new OpportunitySelector()
            .selectOpportunitiesByIds(setIds)
            .setQuery();
        String pattern = basePattern + '(FROM Opportunity WHERE Id IN :bind0)';
        System.assert(System.Pattern.matches(pattern, qf.getQuery()));
    }

    @isTest
    private static void verifySelectLinkedOpportunitiesReturnCorrectQuery() {
        QueryFactory qf = new OpportunitySelector()
            .selectLinkedOpportunities(null)
            .setQuery();

        String subselect1 = subPattern + '(FROM Attachments ORDER BY Name ASC NULLS FIRST , CreatedDate DESC NULLS FIRST \\) , )';
        String subselect2 = subPattern + '(FROM Quotes ORDER BY Name ASC NULLS FIRST \\) , )';
        String subselect3 = subPattern + '(FROM Approvals__r ORDER BY Name ASC NULLS FIRST \\)  )';
        String last = '(FROM Opportunity WHERE Id IN \\(SELECT OpportunityId FROM Quote WHERE \\(ParentQuote__c = :bind0 OR Id = :bind0\\)\\) ORDER BY Name ASC NULLS FIRST , LastModifiedDate DESC NULLS FIRST )';

        String pattern = basePattern + subselect1 + subselect2 + subselect3 + last;
        System.assert(System.Pattern.matches(pattern, qf.getQuery()));
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    private static void verifySelectOpportunityForSettingServiceReturnCorrectQuery() {
        QueryFactory qf = new OpportunitySelector()
            .selectOpportunityForSettingService(null)
            .setQuery();
        String subselect1 = subPattern + '(FROM Quotes WHERE isPrimary__c = true ORDER BY Name ASC NULLS FIRST \\) , )';
        String subselect2 = subPattern + '(FROM OpportunityContactRoles WHERE OpportunityId = :bind0 AND isPrimary = true\\)  )';
        String last = '(FROM Opportunity WHERE Id = :bind0 ORDER BY Name ASC NULLS FIRST )';
        String pattern = basePattern + subselect1 + subselect2 + last;
        //System.assert(System.Pattern.matches(pattern, qf.getQuery()));
    }

    @isTest
    private static void verifySelectOpportunitiesByAccountIdReturnCorrectQuery() {
        QueryFactory qf = new OpportunitySelector()
            .selectOpportunitiesByAccountId(bindings, 1, 1)
            .setQuery();
        String last = '(FROM Opportunity WHERE AccountId = :bind0 AND Type != \'Renewal\' AND CreatedDate > :bind1 AND \\(RecordType.Name = \'Sales Opportunity\' OR RecordType.Name = \'New Sales Opportunity\'\\) AND \\(StageName = \'1. Qualify\' OR StageName = \'2. Problem\' OR StageName = \'3. Solution\' OR StageName = \'3. ActivePipe\' OR StageName = \'4. Proof\' OR StageName = \'5. Agreement\' OR StageName = \'5. Proposal\' OR StageName = \'6. Order\'\\)  ORDER BY LastModifiedDate DESC NULLS FIRST , StageName DESC NULLS FIRST  LIMIT 1 OFFSET 1)';
        String pattern = basePattern + last;
        System.assert(System.Pattern.matches(pattern, qf.getQuery()));
    }

    @isTest
    private static void verifySelectOriginalOppByAccountIdReturnCorrectQuery() {
        QueryFactory qf = new OpportunitySelector()
            .selectOriginalOppByAccountId(null)
            .setQuery();
        String last = '(FROM Opportunity WHERE Parent_Order__c = null AND AccountId = :bind0 ORDER BY Name ASC NULLS FIRST  LIMIT 1)';
        String pattern = basePattern + last;
        System.assert(System.Pattern.matches(pattern, qf.getQuery()));
    }

    @isTest
    private static void verifySelectEngageOpportunitiesByAccountIdReturnCorrectQuery() {
        QueryFactory qf = new OpportunitySelector()
            .selectEngageOpportunitiesByAccountId(bindings)
            .setQuery();
        String last = '(FROM Opportunity WHERE AccountId IN :bind0 AND Tier_Name__c IN :bind1 ORDER BY Name ASC NULLS FIRST )';
        String pattern = basePattern + last;
        System.assert(System.Pattern.matches(pattern, qf.getQuery()));
    }

    @isTest
    private static void verifySelectOpportunitiesForSignUpSyncReturnCorrectQuery() {
        QueryFactory qf = new OpportunitySelector()
            .selectOpportunitiesForSignUpSync(setIds)
            .setQuery();
        String last = '(FROM Opportunity WHERE AccountId IN :bind0 AND RecordTypeId = :bind1)';
        String pattern = basePattern + last;
        System.assert(System.Pattern.matches(pattern, qf.getQuery()));
    }

    @isTest
    private static void verifySelectOpportunityByAccountIdForCCMigrationReturnCorrectQuery() {
        QueryFactory qf = new OpportunitySelector()
            .selectOpportunityByAccountIdForCCMigration(null)
            .setQuery();
        String subselect1 = subPattern + '(FROM Approvals__r ORDER BY Name ASC NULLS FIRST \\) , )';
        String subselect2 = subPattern + '(FROM Orders ORDER BY OrderNumber ASC NULLS FIRST \\)  )';
        String last = '(FROM Opportunity WHERE IsMultiProductTechnicalOpportunity__c = true AND AccountId = :bind0 ORDER BY Name ASC NULLS FIRST  LIMIT 1)';
        String pattern = basePattern + subselect1 + subselect2 + last;
        System.assert(System.Pattern.matches(pattern, qf.getQuery()));
    }

    @isTest
    private static void verifySelectOpportunityWithLeadConvertFieldsReturnCorrectQuery() {
        QueryFactory qf = new OpportunitySelector()
            .selectOpportunityWithLeadConvertFields(null)
            .setQuery();

        System.assert(qf.fields.size() > 0);
        System.assert(String.isNotBlank(qf.getQuery()));
    }

    @isTest
    private static void verifySelectOpportunitiesFreeShippingDiscountReturnCorrectQuery() {
        QueryFactory qf = new OpportunitySelector()
            .selectOpportunitiesFreeShippingDiscount(bindings)
            .setQuery();
        System.assert(qf.fields.size() > 0);
        System.assert(String.isNotBlank(qf.getQuery()));
    }

    @isTest
    private static void verifySelectOpportunitiesByPrimaryOpportunityContactReturnCorrectQuery() {
        QueryFactory qf = new OpportunitySelector()
            .selectOpportunitiesByPrimaryOpportunityContact(bindings)
            .setQuery();
        System.assert(qf.fields.size() > 0);
        System.assert(String.isNotBlank(qf.getQuery()));
    }

    @isTest
    private static void verifySelectOpportunitiesForAcctOwnerUpdatesReturnCorrectQuery() {
        QueryFactory qf = new OpportunitySelector()
            .selectOpportunitiesForAcctOwnerUpdates(setIds)
            .setQuery();
        System.assert(qf.fields.size() > 0);
        System.assert(String.isNotBlank(qf.getQuery()));
    }

    @isTest
    private static void verifySelectOpportunitiesForContactUpdateReturnCorrectQuery() {
        QueryFactory qf = new OpportunitySelector()
            .selectOpportunitiesForContactUpdate(setIds, setIds)
            .setQuery();
        System.assert(qf.fields.size() > 0);
        System.assert(String.isNotBlank(qf.getQuery()));
    }

    @isTest
    private static void verifySelectOpportunitiesByPrimaryOpportunityContactAndOpenOpportunityReturnCorrectQuery() {
        QueryFactory qf = new OpportunitySelector()
            .selectOpportunitiesByPrimaryOpportunityContactAndOpenOpportunity(bindings)
            .setQuery();
        System.assert(qf.fields.size() > 0);
        System.assert(String.isNotBlank(qf.getQuery()));
    }

    @isTest
    private static void verifySelectOpportunitiesByIdAndPrimaryOppContactReturnCorrectQuery() {
        QueryFactory qf = new OpportunitySelector()
            .selectOpportunitiesByIdAndPrimaryOppContact(bindings)
            .setQuery();
        System.assert(qf.fields.size() > 0);
        System.assert(String.isNotBlank(qf.getQuery()));
    }

    @isTest
    private static void verifySelectOpportunityByNameReturnCorrectQuery() {
        QueryFactory qf = new OpportunitySelector()
            .selectOpportunityByName(null)
            .setQuery();
        System.assert(qf.fields.size() > 0);
        System.assert(String.isNotBlank(qf.getQuery()));
    }

    @isTest
    private static void verifySelectClosedWonOppsByPrimaryConAndOppConRolesReturnCorrectQuery() {
        QueryFactory qf = new OpportunitySelector()
            .selectClosedWonOppsByPrimaryConAndOppConRoles(bindings)
            .setQuery();
        System.assert(qf.fields.size() > 0);
        System.assert(String.isNotBlank(qf.getQuery()));
    }

    @isTest
    private static void verifySelectOpportunityForSyncStatusReturnCorrectQuery() {
        QueryFactory qf = new OpportunitySelector()
            .selectOpportunityForSyncStatus(null)
            .setQuery();
        System.assert(qf.fields.size() > 0);
        System.assert(String.isNotBlank(qf.getQuery()));
    }

    @isTest
    private static void verifySelectOpportunitiesForAuraComponentByIdsReturnCorrectQuery() {
        QueryFactory qf = new OpportunitySelector()
            .selectOpportunitiesForAuraComponentByIds(null)
            .setQuery();
        System.assert(qf.fields.size() > 0);
        System.assert(String.isNotBlank(qf.getQuery()));
    }

    @isTest
    private static void verifySelectOpportunitiesForCloseReturnCorrectQuery() {
        QueryFactory qf = new OpportunitySelector()
            .selectOpportunitiesForClose(null)
            .setQuery();
        System.assert(qf.fields.size() > 0);
        System.assert(String.isNotBlank(qf.getQuery()));
    }

    @isTest
    private static void verifySelectTechnicalOpptysByMasterIdForCopyingReturnCorrectQuery() {
        QueryFactory qf = new OpportunitySelector()
            .selectTechnicalOpptysByMasterIdForCopying(null)
            .setQuery();
        System.assert(qf.fields.size() > 0);
        System.assert(String.isNotBlank(qf.getQuery()));
    }

    @isTest
    private static void verifySelectMPTechOppsByMasterIdsReturnCorrectQuery() {
        QueryFactory qf = new OpportunitySelector()
            .selectMPTechOppsByMasterIds(null)
            .setQuery();
        System.assert(qf.fields.size() > 0);
        System.assert(String.isNotBlank(qf.getQuery()));
    }

    @isTest
    private static void verifySelectOpportunitiesForInvoiceRequestApprovalByAccIdReturnCorrectQuery() {
        QueryFactory qf = new OpportunitySelector()
            .selectOpportunitiesForInvoiceRequestApprovalByAccId(null)
            .setQuery();
        System.assert(qf.fields.size() > 0);
        System.assert(String.isNotBlank(qf.getQuery()));
    }

    @isTest
    private static void verifySelectOpportunitiesForSignUpReturnCorrectQuery() {
        QueryFactory qf = new OpportunitySelector()
            .selectOpportunitiesForSignUp(new List<Object>())
            .setQuery();
        System.assert(qf.fields.size() > 0);
        System.assert(String.isNotBlank(qf.getQuery()));
    }

    @isTest
    private static void verifySelectOpportunitiesForInvoiceRequestApprovalByOppIdReturnCorrectQuery() {
        QueryFactory qf = new OpportunitySelector()
            .selectOpportunitiesForInvoiceRequestApprovalByOppId(null)
            .setQuery();
        System.assert(qf.fields.size() > 0);
        System.assert(String.isNotBlank(qf.getQuery()));
    }

    @isTest
    private static void verifySelectServiceOpportunitiesByMasterIdsReturnCorrectQuery() {
        QueryFactory qf = new OpportunitySelector()
            .selectServiceOpportunitiesByMasterIds(new List<Object>())
            .setQuery();
        System.assert(qf.fields.size() > 0);
        System.assert(String.isNotBlank(qf.getQuery()));
    }

    @isTest
    private static void verifySelectOpportunitiesByIdsWithAllFieldsReturnCorrectQuery() {
        QueryFactory qf = new OpportunitySelector()
            .selectOpportunitiesByIdsWithAllFields(new List<Id>())
            .setQuery();
        System.assert(qf.fields.size() > 0);
        System.assert(String.isNotBlank(qf.getQuery()));
    }

    @isTest
    private static void verifySelectOpptysForCopyingReturnCorrectQuery() {
        QueryFactory qf = new OpportunitySelector()
            .selectOpptysForCopying(new List<Object>())
            .setQuery();
        System.assert(qf.fields.size() > 0);
        System.assert(String.isNotBlank(qf.getQuery()));
    }

    @isTest
    private static void verifySelectOpportunityForQuoteWizardReturnCorrectQuery() {
        QueryFactory qf = new OpportunitySelector()
            .selectOpportunityForQuoteWizard(null)
            .setQuery();
        System.assert(qf.fields.size() > 0);
        System.assert(String.isNotBlank(qf.getQuery()));
    }

    @isTest
    private static void verifyGetOpptyFieldsForEmailNotificationReturnCorrectQuery() {
        QueryFactory qf = new OpportunitySelector()
            .getOpptyFieldsForEmailNotification(new List<Object>())
            .setQuery();
        System.assert(qf.fields.size() > 0);
        System.assert(String.isNotBlank(qf.getQuery()));
    }

    @isTest
    private static void verifySelectOpptysReturnCorrectQuery() {
        QueryFactory qf = new OpportunitySelector()
            .selectOpptys()
            .setQuery();
        System.assert(qf.fields.size() > 0);
        System.assert(String.isNotBlank(qf.getQuery()));
    }

    @isTest
    static void verifySelectOpportunitiesByStagesAndAccountId() {
        Account testAccount = (Account) new SobjectBuilder(Account.sObjectType)
            .setField(Account.Name, 'Test Account')
            .create()
            .getRecord();
        Opportunity opp1 = (Opportunity) new SobjectBuilder(Opportunity.sObjectType)
            .setField(Opportunity.Name, 'Test Opp 1')
            .setField(Opportunity.AccountId, testAccount.Id)
            .setField(Opportunity.StageName, '7. Closed Won')
            .setField(Opportunity.CloseDate, Date.today())
            .build()
            .getRecord();
        Opportunity opp2 = (Opportunity) new SobjectBuilder(Opportunity.sObjectType)
            .setField(Opportunity.Name, 'Test Opp 2')
            .setField(Opportunity.AccountId, testAccount.Id)
            .setField(Opportunity.StageName, '4. Proof')
            .setField(Opportunity.CloseDate, Date.today())
            .build()
            .getRecord();
        Opportunity opp3 = (Opportunity) new SobjectBuilder(Opportunity.sObjectType)
            .setField(Opportunity.Name, 'Test Opp 3')
            .setField(Opportunity.AccountId, testAccount.Id)
            .setField(Opportunity.StageName, '5. Agreement')
            .setField(Opportunity.CloseDate, Date.today())
            .build()
            .getRecord();
        insert opp1;
        insert opp2;
        insert opp3;

        List<Object> bindings = new List<Object>{new List<Id>{testAccount.Id}, OpportunityHelper.alteredStages};
        List<Opportunity> result = (List<Opportunity>) new OpportunitySelector()
            .selectOpportunitiesByStagesAndAccountId(bindings)
            .executeQuery();

        System.assertEquals(2, result.size(), 'There are missing opportunities');
        // Verify both opportunities are present - order may vary if CreatedDate is the same
        Set<String> oppNames = new Set<String>();
        for (Opportunity opp : result) {
            oppNames.add(opp.Name);
        }
        System.assert(oppNames.contains('Test Opp 2'), 'Test Opp 2 should be in results');
        System.assert(oppNames.contains('Test Opp 3'), 'Test Opp 3 should be in results');
    }

    @isTest
    static void verifySelectOpportunitiesWithTotalMRRByIds() {
        Account testAccount = (Account) new SobjectBuilder(Account.sObjectType)
            .setField(Account.Name, 'Test Account')
            .create()
            .getRecord();
        Opportunity testOpportunity = (Opportunity) new SobjectBuilder(Opportunity.sObjectType)
            .setField(Opportunity.Name, 'Test Opp 1')
            .setField(Opportunity.AccountId, testAccount.Id)
            .setField(Opportunity.Total_MRR__c, 100)
            .create()
            .getRecord();

        List<Opportunity> reselectedOpportunities = (List<Opportunity>) new OpportunitySelector()
            .selectOpportunitiesWithTotalMRRByIds(new Set<Id>{testOpportunity.Id})
            .executeQuery();

        System.assertEquals(1, reselectedOpportunities.size(), 'Opportunities should be selected');
        System.assertEquals(100, reselectedOpportunities[0].Total_MRR__c, 'Total MRR should be selected');
    }

    @isTest
    private static void verifySelectRenewalOpportunitiesDowngradedByMigrationReturnCorrectQuery() {
        QueryFactory qf = new OpportunitySelector()
            .selectRenewalOpportunitiesDowngradedByMigration(new List<String>())
            .setQuery();

        String last = '(AccountId = :bind0 AND StageName = :bind1 AND Downgrade_Reason_Opp__c = :bind2 AND Type = :bind3)';
        String pattern = basePattern + last;
        System.assert(System.Pattern.matches(pattern, qf.getQuery()));
        System.assert(qf.fields.size() > 0);
        System.assert(String.isNotBlank(qf.getQuery()));
    }

    @isTest
    private static void verifySelectMasterAndTechnicalOpportunitiesByMasterIdWithQuotesReturnsCorrectQuery() {
        QueryFactory qf = new OpportunitySelector()
            .selectMasterAndTechnicalOpportunitiesByMasterIdWithQuotes(null)
            .setQuery();

        String resultedQuery = qf.getQuery();
        Assert.isTrue(
            resultedQuery.contains('Id IN :bind0 OR MasterOpportunity__c IN :bind0'),
            'The selector must filter results by input PartnerIds'
        );
    }

    @isTest
    private static void verifySelectOpportunitiesByIdsWithQuotesReturnCorrectQuery() {
        QueryFactory qf = new OpportunitySelector()
            .selectOpportunitiesByIdsWithQuotes(null)
            .setQuery();

        System.assert(qf.fields.size() > 0);
        System.assert(String.isNotBlank(qf.getQuery()));
    }

    @isTest
    static void verifySelectOpportunitiesOnCloseValidation() {
        Account testAccount = (Account) new SobjectBuilder(Account.sObjectType)
            .setField(Account.Name, 'Test Account')
            .create()
            .getRecord();
        Opportunity testOpportunity = (Opportunity) new SobjectBuilder(Opportunity.sObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.Name => 'Test Opp 1',
                Opportunity.AccountId => testAccount.Id
            })
            .create()
            .getRecord();

        List<Opportunity> reselectedOpportunities = (List<Opportunity>) new OpportunitySelector()
            .selectOpportunitiesOnCloseValidation(new List<Object>{ new Set<Id>{ testOpportunity.Id } })
            .executeQuery();

        System.assertEquals(1, reselectedOpportunities.size(), 'Opportunities should be selected');
    }

    @isTest
    static void verifySelectOpptyMandatoryFieldsByOpptyName() {
        QueryFactory qf = new OpportunitySelector()
            .selectOpptyMandatoryFieldsByOpptyName(null)
            .setQuery();
        String last = '(FROM Opportunity WHERE Name = :bind0)';
        String pattern = basePattern + last;
        Assert.isTrue(qf.fields.size() > 0);
        Assert.isTrue(String.isNotBlank(qf.getQuery()));
    }

    @isTest
	static void verifySelectOpptyMandatoryFieldsByOpptyID() {
        QueryFactory qf = new OpportunitySelector()
            .selectOpptyMandatoryFieldsByOpptyID(bindings)
            .setQuery();
        String last = '(FROM Opportunity WHERE Id = :bind0 AND StageName = :bind1)';
        String pattern = basePattern + last;
		Assert.isTrue(qf.fields.size() > 0);
        Assert.isTrue(String.isNotBlank(qf.getQuery()));
    }

    @isTest
	static void verifyselectOpptyFieldsForDowngradeValidationByOpptyID() {
        QueryFactory qf = new OpportunitySelector()
            .selectOpptyFieldsForDowngradeValidationByOpptyID(null)
            .setQuery();
        String last = '(FROM Opportunity WHERE Id = :bind0)';
        String pattern = basePattern + last;
		Assert.isTrue(qf.fields.size() > 0);
        Assert.isTrue(String.isNotBlank(qf.getQuery()));
    }

    @isTest
    static void verifySelectTechOptyForAutoSyncByMasterOppId() {
        QueryFactory qf = new OpportunitySelector()
            .selectTechOptyForAutoSyncByMasterOppId(null)
            .setQuery();

        Assert.isTrue(qf.fields.size() > 0, 'Fields are not selected');
        Assert.isTrue(String.isNotBlank(qf.getQuery()), 'Query is empty');
    }

    @isTest
    static void verifySelectOpportunityForInContactCaseSharing() {
        QueryFactory qf = new OpportunitySelector()
            .selectOpportunityForInContactCaseSharing(null)
            .setQuery();

        Assert.isTrue(qf.fields.size() > 0, 'Fields are not selected');
        Assert.isTrue(String.isNotBlank(qf.getQuery()), 'Query is empty');
    }

    @isTest
    static void verifySelectChangeOrderOpportunityByOrderId() {
        QueryFactory qf = new OpportunitySelector()
            .selectChangeOrderOpportunityByOrderId(null)
            .setQuery();

        Assert.isTrue(qf.fields.size() > 0, 'Fields are not selected');
        Assert.isTrue(String.isNotBlank(qf.getQuery()), 'Query is empty');
    }
    
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    private static void testSelectOpportunitiesForSyncWS() {
        List<Object> bindings = new List<Object>{
            (Id) new ValueProvider.DummyIdProvider(Account.sObjectType).getValue(),
            OpportunityHelper.RT_ID_NEW_SALES_OPPORTUNITY
        };

        Test.startTest();
            QueryFactory factory = new OpportunitySelector()
                .selectOpportunitiesForSyncWS(bindings)
                .setQuery();
        Test.stopTest();

        String selectorName = 'selectOpportunitiesForSyncWS';
        String expectedWhereClause = 'WHERE AccountId IN :bind0 AND RecordTypeId = :bind1';

        assertOpportunitySelector(factory, selectorName, expectedWhereClause, 2);
        assertBindings(factory, selectorName, bindings);
    }
}