@IsTest
private class Test_CostCenterLineItemSelector {

    @IsTest
    private static void testSelectCostCentersLineItemsDataSelector() {
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

        Cost_Center_Line_Item__c ccenterLineItem = (Cost_Center_Line_Item__c) new SObjectBuilder(Cost_Center_Line_Item__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Cost_Center_Line_Item__c.Name => 'Test Contact Center Line Item',
                Cost_Center_Line_Item__c.CurrencyIsoCode => 'USD',
                Cost_Center_Line_Item__c.Cost_Center__c => contCenter.Id
            })
            .create()
            .getRecord();

        Test.startTest();
            Cost_Center_Line_Item__c selectedCCLineItem = (Cost_Center_Line_Item__c) new ListOptional(new CostCenterLineItemSelector()
                .selectCostCentersLineItemsData()
                .executeQuery()
            ).getFirst();
        Test.stopTest();
        System.assertNotEquals(null, selectedCCLineItem, 'Selector returned value');
        System.assertEquals(ccenterLineItem.Id, selectedCCLineItem.Id, 'Values are the same');
    }

    @IsTest
    private static void testSelectCostCentersLineItemsForCloseValidationSelector() {

        Product2 testProduct = (Product2) new SObjectBuilder(Product2.SObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    Product2.Name => 'Test Product',
                    Product2.IsActive => true,
                    Product2.ExtID__c => 'LC_DL_75'
                }
            )
            .create()
            .getRecord();

        PriceBookEntry testPrice = (PriceBookEntry) new SObjectBuilder(PriceBookEntry.SObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    PriceBookEntry.Pricebook2Id => Test.getStandardPriceBookId(),
                    PriceBookEntry.Product2Id => testProduct.Id,
                    PriceBookEntry.UnitPrice => 100,
                    PriceBookEntry.IsActive => true,
                    PriceBookEntry.UseStandardPrice => false
                }
            )
            .create()
            .getRecord();

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

        QuoteLineItem testQli = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    QuoteLineItem.QuoteId => testQuote.Id,
                    QuoteLineItem.Product2Id => testProduct.Id,
                    QuoteLineItem.PricebookEntryId => testPrice.Id,
                    QuoteLineItem.UnitPrice => testPrice.UnitPrice,
                    QuoteLineItem.Quantity => 5
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

        Cost_Center_Line_Item__c ccenterLineItem = (Cost_Center_Line_Item__c) new SObjectBuilder(Cost_Center_Line_Item__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Cost_Center_Line_Item__c.Name => 'Test Contact Center Line Item',
                Cost_Center_Line_Item__c.CurrencyIsoCode => 'USD',
                Cost_Center_Line_Item__c.Cost_Center__c => contCenter.Id,
                Cost_Center_Line_Item__c.Quote_Line_Item__c => testQli.Id,
                Cost_Center_Line_Item__c.Quantity__c => 5
            })
            .create()
            .getRecord();

        Test.startTest();
            Cost_Center_Line_Item__c selectedCCLineItem = (Cost_Center_Line_Item__c) new ListOptional(new CostCenterLineItemSelector()
                .selectCostCentersLineItemsForCloseValidation(new Set<Id>{testQli.Id})
                .executeQuery()
            ).getFirst();
        Test.stopTest();
        System.assertNotEquals(null, selectedCCLineItem, 'Selector returned value');
        System.assertEquals(ccenterLineItem.Id, selectedCCLineItem.Id, 'Values are the same');
    }

    @IsTest
    private static void testSelectAllFieldsForCloningSelector() {

        Product2 testProduct = (Product2) new SObjectBuilder(Product2.SObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    Product2.Name => 'Test Product',
                    Product2.IsActive => true,
                    Product2.ExtID__c => 'LC_DL_75'
                }
            )
            .create()
            .getRecord();

        PriceBookEntry testPrice = (PriceBookEntry) new SObjectBuilder(PriceBookEntry.SObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    PriceBookEntry.Pricebook2Id => Test.getStandardPriceBookId(),
                    PriceBookEntry.Product2Id => testProduct.Id,
                    PriceBookEntry.UnitPrice => 100,
                    PriceBookEntry.IsActive => true,
                    PriceBookEntry.UseStandardPrice => false
                }
            )
            .create()
            .getRecord();

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

        QuoteLineItem testQli = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    QuoteLineItem.QuoteId => testQuote.Id,
                    QuoteLineItem.Product2Id => testProduct.Id,
                    QuoteLineItem.PricebookEntryId => testPrice.Id,
                    QuoteLineItem.UnitPrice => testPrice.UnitPrice,
                    QuoteLineItem.Quantity => 5
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

        Cost_Center_Line_Item__c ccenterLineItem = (Cost_Center_Line_Item__c) new SObjectBuilder(Cost_Center_Line_Item__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Cost_Center_Line_Item__c.Name => 'Test Contact Center Line Item',
                Cost_Center_Line_Item__c.CurrencyIsoCode => 'USD',
                Cost_Center_Line_Item__c.Cost_Center__c => contCenter.Id,
                Cost_Center_Line_Item__c.Quote_Line_Item__c => testQli.Id,
                Cost_Center_Line_Item__c.Quantity__c => 5
            })
            .create()
            .getRecord();

        Test.startTest();
            Cost_Center_Line_Item__c selectedCCLineItem = (Cost_Center_Line_Item__c) new ListOptional(new CostCenterLineItemSelector()
                .selectAllFieldsForCloning(new Set<Id>{testQli.Id})
                .executeQuery()
            ).getFirst();
        Test.stopTest();
        System.assertNotEquals(null, selectedCCLineItem, 'Selector returned value');
        System.assertEquals(ccenterLineItem.Id, selectedCCLineItem.Id, 'Values are the same');
    }

    @IsTest
    private static void testSelectCostCentersLineItemsSelector() {
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

        Cost_Center_Line_Item__c ccenterLineItem = (Cost_Center_Line_Item__c) new SObjectBuilder(Cost_Center_Line_Item__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Cost_Center_Line_Item__c.Name => 'Test Contact Center Line Item',
                Cost_Center_Line_Item__c.CurrencyIsoCode => 'USD',
                Cost_Center_Line_Item__c.Cost_Center__c => contCenter.Id
            })
            .create()
            .getRecord();

        Test.startTest();
        Cost_Center_Line_Item__c selectedCCLineItem = (Cost_Center_Line_Item__c) new ListOptional(new CostCenterLineItemSelector()
            .selectCostCentersLineItems()
            .executeQuery()
        ).getFirst();
        Test.stopTest();
        System.assertNotEquals(null, selectedCCLineItem, 'Selector returned value');
        System.assertEquals(ccenterLineItem.Id, selectedCCLineItem.Id, 'Values are the same');
    }
}