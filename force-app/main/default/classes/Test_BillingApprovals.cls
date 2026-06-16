@isTest
private class Test_BillingApprovals {

    @isTest
    private static void testApproveQuoteDiscountForRequiredStatus(){

        Triggers.switchOff();
        SObjectFactory factory = new SObjectFactory();

        Account acc = (Account) factory
            .create(
                Account.SObjectType
            );

        Opportunity opportunity = (Opportunity) factory
            .create(
                Opportunity.SObjectType,
                new Map<SObjectField, Object> {
                    Opportunity.AccountId => acc.Id,
                    Opportunity.CloseDate => System.today()
                }
            );

        schedulerConfiguration__c brand = (schedulerConfiguration__c) factory
            .create(
                schedulerConfiguration__c.SObjectType,
                new Map<SObjectField, Object> {
                    schedulerConfiguration__c.Brand_Id__c => ValueProviderBuilder.provideUniqueString()
                }
            );

        PriceBook2 pricebook = (PriceBook2) factory
            .create(
                PriceBook2.SObjectType,
                new Map<SObjectField, Object> {
                    PriceBook2.Service__c => Pricebook2Helper.SERVICE_OFFICE,
                    PriceBook2.Brand__c => brand.Id,
                    PriceBook2.IsActive => true,
                    PriceBook2.Line_Range_Min__c => 5,
                    PriceBook2.Tier_ID__c => ValueProviderBuilder.provideUniqueString()
                }
            );

        Quote quote = (Quote) factory
            .create(
                Quote.SObjectType,
                new Map<SObjectField, Object> {
                    Quote.OpportunityId => opportunity.Id,
                    Quote.Pricebook2Id => pricebook.Id,
                    Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                    Quote.Approved_Status__c => QuoteHelper.APPROVAL_STATUS_APPROVED
                }
            );

        Product2 product = (Product2) factory
            .create(
                Product2.SObjectType,
                new Map<SObjectField, Object> {
                    Product2.Charge_Term__c => Product2Helper.CHARGE_TERM_MONTHLY,
                    Product2.Feature__c => 17
                }
            );

        List<Entitlement__c> ent = (List<Entitlement__c>) factory
            .create(
                Entitlement__c.SObjectType,
                3,
                new Map<SObjectField, Object> {
                    Entitlement__c.Account__c => acc.Id,
                    Entitlement__c.ChargeTerm__c => Product2Helper.CHARGE_TERM_MONTHLY,
                    Entitlement__c.Product__c => product.Id,
                    Entitlement__c.Discount_Type__c => QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY,
                    Entitlement__c.Discount__c => 0,
                    Entitlement__c.Price__c => 10
                }
            );

        PricebookEntry standartPricebookEntry = (PricebookEntry) factory
            .create(
                PricebookEntry.SObjectType,
                new Map<SObjectField, Object> {
                    PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                    PricebookEntry.Product2Id => product.Id,
                    PricebookEntry.UnitPrice => 10,
                    PricebookEntry.IsActive => true,
                    PricebookEntry.UseStandardPrice => false
                }
            );

        PricebookEntry currentPricebookEntry = (PricebookEntry) factory
            .create(
                PricebookEntry.SObjectType,
                new Map<SObjectField, Object> {
                    PricebookEntry.Pricebook2Id => pricebook.Id,
                    PricebookEntry.Product2Id => product.Id,
                    PricebookEntry.UnitPrice => 10,
                    PricebookEntry.IsActive => true,
                    PricebookEntry.UseStandardPrice => false
                }
            );

        QuoteLineItem qli = (QuoteLineItem) factory
            .create(
                QuoteLineItem.SObjectType,
                new Map<SObjectField, Object> {
                    QuoteLineItem.Product2Id => product.Id,
                    QuoteLineItem.PricebookEntryId => currentPricebookEntry.Id,
                    QuoteLineItem.Entitlement__c => ent.get(0).Id,
                    QuoteLineItem.QuoteId => quote.Id,
                    QuoteLineItem.Quantity => 1,
                    QuoteLineItem.UnitPrice => 10,
                    QuoteLineItem.PackageInfo__c => '{}',
                    QuoteLineItem.Package_Info_QLI__c => '{}',
                    QuoteLineItem.Discount_number__c => 10
                }
            );

        Contract__c contract = (Contract__c) factory
            .create(
                Contract__c.SObjectType,
                new Map<SObjectField, Object> {
                    Contract__c.ExtID__c => ValueProviderBuilder.provideUniqueString()
                }
            );

        Contract_Discount__c discount = (Contract_Discount__c) factory
            .create(
                Contract_Discount__c.SObjectType,
                new Map<SObjectField, Object> {
                    Contract_Discount__c.Contract__c => contract.Id
                }
            );

        Triggers.switchOn();

        Test.startTest();
            Quote approvedQuote = BillingApprovals.approveDiscounts([
                    SELECT  Entitlement__r.Discount_Type__c, Product_Family__c, Package_Info_QLI__c,
                            PackageInfo__c, Discount_type__c, Discount_number__c,
                            Discount, Entitlement__r.Discount__c
                    FROM QuoteLineItem
                ],
                quote,
                new List<Contract_Discount__c> { discount },
                new Map<Id, QuoteLineItem>()
            );
        Test.stopTest();

        System.assertEquals(
            approvedQuote.Approved_Status__c,
            QuoteHelper.APPROVAL_STATUS_REQUIRED,
            'Quote Status was assigned incorrectly.'
        );
    }

    @isTest
private static void testApproveQuoteDiscountForApprovedStatus(){
        SObjectFactory factory = new SObjectFactory();

        Triggers.switchOff();

        Account acc = (Account) factory
            .create(
                Account.SObjectType
            );

        Opportunity opportunity = (Opportunity) factory
            .create(
                Opportunity.SObjectType,
                new Map<SObjectField, Object> {
                    Opportunity.AccountId => acc.Id,
                    Opportunity.CloseDate => System.today()
                }
            );

        schedulerConfiguration__c brand = (schedulerConfiguration__c) factory
            .create(
                schedulerConfiguration__c.SObjectType,
                new Map<SObjectField, Object> {
                    schedulerConfiguration__c.Brand_Id__c => ValueProviderBuilder.provideUniqueString()
                }
            );

        PriceBook2 pricebook = (PriceBook2) factory
            .create(
                PriceBook2.SObjectType,
                new Map<SObjectField, Object> {
                    PriceBook2.Service__c => Pricebook2Helper.SERVICE_OFFICE,
                    PriceBook2.Brand__c => brand.Id,
                    PriceBook2.IsActive => true,
                    PriceBook2.Line_Range_Min__c => 5,
                    PriceBook2.Tier_ID__c => ValueProviderBuilder.provideUniqueString()
                }
            );

        Quote quote = (Quote) factory
            .create(
                Quote.SObjectType,
                new Map<SObjectField, Object> {
                    Quote.OpportunityId => opportunity.Id,
                    Quote.Pricebook2Id => pricebook.Id,
                    Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                    Quote.Approved_Status__c => QuoteHelper.APPROVAL_STATUS_APPROVED
                }
            );

        Product2 product = (Product2) factory
            .create(
                Product2.SObjectType,
                new Map<SObjectField, Object> {
                    Product2.Charge_Term__c => Product2Helper.CHARGE_TERM_MONTHLY,
                    Product2.Feature__c => 17
                }
            );

        List<Entitlement__c> ent = (List<Entitlement__c>) factory
            .create(
                Entitlement__c.SObjectType,
                3,
                new Map<SObjectField, Object> {
                    Entitlement__c.Account__c => acc.Id,
                    Entitlement__c.ChargeTerm__c => Product2Helper.CHARGE_TERM_MONTHLY,
                    Entitlement__c.Product__c => product.Id,
                    Entitlement__c.Discount_Type__c => QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY,
                    Entitlement__c.Discount__c => 10,
                    Entitlement__c.Price__c => 10
                }
            );

        PricebookEntry standartPricebookEntry = (PricebookEntry) factory
            .create(
                PricebookEntry.SObjectType,
                new Map<SObjectField, Object> {
                    PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                    PricebookEntry.Product2Id => product.Id,
                    PricebookEntry.UnitPrice => 10,
                    PricebookEntry.IsActive => true,
                    PricebookEntry.UseStandardPrice => false
                }
            );

        PricebookEntry currentPricebookEntry = (PricebookEntry) factory
            .create(
                PricebookEntry.SObjectType,
                new Map<SObjectField, Object> {
                    PricebookEntry.Pricebook2Id => pricebook.Id,
                    PricebookEntry.Product2Id => product.Id,
                    PricebookEntry.UnitPrice => 10,
                    PricebookEntry.IsActive => true,
                    PricebookEntry.UseStandardPrice => false
                }
            );

        QuoteLineItem qli = (QuoteLineItem) factory
            .create(
                QuoteLineItem.SObjectType,
                new Map<SObjectField, Object> {
                    QuoteLineItem.Product2Id => product.Id,
                    QuoteLineItem.PricebookEntryId => currentPricebookEntry.Id,
                    QuoteLineItem.Entitlement__c => ent.get(0).Id,
                    QuoteLineItem.QuoteId => quote.Id,
                    QuoteLineItem.Quantity => 1,
                    QuoteLineItem.UnitPrice => 10,
                    QuoteLineItem.Package_Info_QLI__c => '{}',
                    QuoteLineItem.PackageInfo__c => TestDataGenerator.TEST_PACKAGE_INFO,
                    QuoteLineItem.Discount => 5,
                    QuoteLineItem.Discount_Type__c => QuoteLineItemHelper.DISCOUNT_TYPE_PERCENTAGE,
                    QuoteLineItem.ServiceName__c => QuoteLineItemHelper.SUBCATEGORY_PROSERV
                }
            );

        Contract__c contract = (Contract__c) factory
            .create(
                Contract__c.SObjectType,
                new Map<SObjectField, Object> {
                    Contract__c.ExtID__c => ValueProviderBuilder.provideUniqueString()
                }
            );

        Contract_Discount__c discount = (Contract_Discount__c) factory
            .create(
                Contract_Discount__c.SObjectType,
                new Map<SObjectField, Object> {
                    Contract_Discount__c.Contract__c => contract.Id
                }
            );

        Triggers.switchOn();

        Test.startTest();
            Quote requiredQuote = BillingApprovals.approveDiscounts(
                new List<QuoteLineItem> { qli },
                quote,
                new List<Contract_Discount__c> { discount },
                new Map<Id, QuoteLineItem> {qli.Id => qli}
            );
        Test.stopTest();

        System.assertEquals(
            requiredQuote.Approved_Status__c,
            QuoteHelper.APPROVAL_STATUS_APPROVED,
            'Quote Status was assigned incorrectly.'
        );
    }
}