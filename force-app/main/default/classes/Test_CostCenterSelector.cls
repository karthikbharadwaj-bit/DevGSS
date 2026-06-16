@IsTest
private class Test_CostCenterSelector {

    @IsTest
    private static void testSelectCostCentersDataSelector() {

        Opportunity testOpp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                Opportunity.CloseDate => System.today(),
                Opportunity.AccountId => ValueProviderBuilder.provideGenericParent(Account.SObjectType)
            })
            .create()
            .getRecord();

        Quote testQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    Quote.Name => 'Quote Test',
                    Quote.OpportunityId => testOpp.Id,
                    Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                    Quote.Pricebook2Id => Test.getStandardPriceBookId()
                }
            )
            .create()
            .getRecord();

        Cost_Center__c contCenter = (Cost_Center__c) new SObjectBuilder(Cost_Center__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Cost_Center__c.Name => 'Test Contact Center',
                Cost_Center__c.BillingId__c => '12345678',
                Cost_Center__c.CurrencyIsoCode => 'USD',
                Cost_Center__c.Quote__c => testQuote.Id
            })
            .create()
            .getRecord();

        Test.startTest();
            Cost_Center__c selectedCC = (Cost_Center__c) new ListOptional(new CostCenterSelector()
                .selectCostCentersData(new List<Object>{contCenter.Quote__c})
                .executeQuery()
            ).getFirst();
        Test.stopTest();
        System.assertNotEquals(null, selectedCC, 'Selector returned value');
        System.assertEquals(contCenter.Id, selectedCC.Id, 'Values are the same');
    }

    @IsTest
    private static void testSelectCostCentersByQuoteIdSelector() {

        Opportunity testOpp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                Opportunity.CloseDate => System.today(),
                Opportunity.AccountId => ValueProviderBuilder.provideGenericParent(Account.SObjectType)
            })
            .create()
            .getRecord();

        Quote testQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    Quote.Name => 'Quote Test',
                    Quote.OpportunityId => testOpp.Id,
                    Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                    Quote.Pricebook2Id => Test.getStandardPriceBookId()
                }
            )
            .create()
            .getRecord();

        Cost_Center__c contCenter = (Cost_Center__c) new SObjectBuilder(Cost_Center__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Cost_Center__c.Name => 'Test Contact Center',
                Cost_Center__c.BillingId__c => '12345678',
                Cost_Center__c.CurrencyIsoCode => 'USD',
                Cost_Center__c.Quote__c => testQuote.Id
            })
            .create()
            .getRecord();

        Test.startTest();
        Cost_Center__c selectedCC = (Cost_Center__c) new ListOptional(new CostCenterSelector()
            .selectCostCentersByQuoteId(new List<Object>{new List<Id> {contCenter.Quote__c}})
            .executeQuery()
        ).getFirst();
        Test.stopTest();
        System.assertNotEquals(null, selectedCC, 'Selector returned value');
        System.assertEquals(contCenter.Id, selectedCC.Id, 'Values are the same');
    }

    @IsTest
    private static void testSelectAllFieldsForCloningSelector() {

        Opportunity testOpp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                Opportunity.CloseDate => System.today(),
                Opportunity.AccountId => ValueProviderBuilder.provideGenericParent(Account.SObjectType)
            })
            .create()
            .getRecord();

        Quote testQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    Quote.Name => 'Quote Test',
                    Quote.OpportunityId => testOpp.Id,
                    Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                    Quote.Pricebook2Id => Test.getStandardPriceBookId()
                }
            )
            .create()
            .getRecord();

        Cost_Center__c contCenter = (Cost_Center__c) new SObjectBuilder(Cost_Center__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Cost_Center__c.Name => 'Test Contact Center',
                Cost_Center__c.BillingId__c => '12345678',
                Cost_Center__c.CurrencyIsoCode => 'USD',
                Cost_Center__c.Quote__c => testQuote.Id
            })
            .create()
            .getRecord();

        Test.startTest();
        Cost_Center__c selectedCC = (Cost_Center__c) new ListOptional(new CostCenterSelector()
            .selectAllFieldsForCloning(new List<Object>{new List<Id> {contCenter.Quote__c}})
            .executeQuery()
        ).getFirst();
        Test.stopTest();
        System.assertNotEquals(null, selectedCC, 'Selector returned value');
        System.assertEquals(contCenter.Id, selectedCC.Id, 'Values are the same');
    }
}