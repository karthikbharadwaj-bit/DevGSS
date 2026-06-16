@isTest
private class Test_AreaCodeHelper {

    public static final string TEST_TIME_ZONE_NAME = '(GMT-12:00) International Date Line West';
    public static final String TYPE_LOCAL = 'Local';
    public static final String TYPE_TOLL_FREE = 'Toll-Free';

    @isTest
    private static void testPreCreateAreaCodeMain() {
        new SObjectBuilder(RingCentralVariousSettings__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                RingCentralVariousSettings__c.CC_FSC_Approvers_Queues__c => 'TestQueue'
            })
            .create()
            .getRecord();
        List<Category_Codes__c> categoryCodes = new List<Category_Codes__c>();

        Map<String, String> m = new Map<String, String>{
            'FAX_AREA_CODES' => 'MLFN,MTFN',
            'LOCAL_AREA_CODES' => 'ALN,HDRF,HDR,HD,MLN,MLFN,SP,EP',
            'MAIN_AREA_CODES' => 'ALN,HDRF,HDR,HD,MLN,SP,EP,ATN,MTN',
            'TOLL_FREE_AREA_CODES' => 'ATN,MTN,MTFN',
            'AREA_CODES_AVAILABLE' => 'HDRF,HDR,HD,MLN,MTN,MLFN,MTFN,ALN,ATN,SP,EP',
            'REQUIRED_AREA_CODES' => 'ALN,ATN,HDRF,HD'
        };
        for (String codeName : m.KeySet()) {
            categoryCodes.add(
                new Category_Codes__c(
                    Name = codeName,
                    Codes__c = m.get(codeName)
                )
            );
        }
        insert categoryCodes;

        Area_Codes__c ac1 = (Area_Codes__c) new SObjectBuilder(Area_Codes__c.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Area_Codes__c.Name => 'Test Area Code 1',
                Area_Codes__c.State__c => 'NY',
                Area_Codes__c.Country__c => 'United States',
                Area_Codes__c.Type__c => TYPE_LOCAL
            })
            .create()
            .getRecord();

        Account acc = (Account) new SObjectBuilder(Account.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Name => 'Test acc',
                Account.Payment_Method__c => 'Invoice',
                Account.Tax_Exempt__c => false,
                Account.SignupType__c => 'Free',
                Account.Monthly_Credit_Limit__c => 0,
                Account.Sign_up_Purchase_Limit__c => 0,
                Account.Payment_Terms__c => '12',
                Account.Invoice_Terms__c => '12',
                Account.PID__c => 'test_p_id',
                Account.Timezone__c => TEST_TIME_ZONE_NAME,
                Account.BillingCity => 'TestCity',
                Account.BillingStreet => 'TestStreet',
                Account.BillingState => 'NY',
                Account.BillingPostalCode => '123890',
                Account.BillingCountry => 'US'
            })
            .create()
            .getRecord();

        Contact contact = (Contact) new SObjectBuilder(Contact.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Contact.AccountId => acc.Id,
                Contact.LastName => 'John',
                Contact.FirstName => 'Good',
                Contact.Email => 'jg@rc.test'
            })
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SOBjectBuilder(Opportunity.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.AccountId => acc.Id,
                Opportunity.BMID__c => 'test_bm_id',
                Opportunity.OID__c => 'test_o_id',
                Opportunity.Partner_ID__c => 'test_partner_id',
                Opportunity.Enable_Cost_Center_Management__c => false
            })
            .create()
            .getRecord();

        Quote qt = (Quote) new SOBjectBuilder(Quote.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Quote.Pricebook2Id => Test.getStandardPricebookId(),
                Quote.Name => 'Test quote',
                Quote.OpportunityId => opp.Id,
                Quote.CurrencyIsoCode => 'USD',
                Quote.Approved_Status__c => 'Approved',
                Quote.Status => 'Draft',
                Quote.isPrimary__c => true,
                Quote.Initial_Term_months__c => '12',
                Quote.Package_Info__c => NGBSTestDataGenerator.generateQuotePackageInfo(),
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.QuoteType__c => 'Quote',
                Quote.AreaCode__c => ac1.Id,
                Quote.FaxAreaCode__c => ac1.Id,
                Quote.Payment_Plan__c => 'Monthly'
            })
            .create()
            .getRecord();

        Product2 prod = (Product2) new SObjectBuilder(Product2.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Product2.Name => 'Test product',
                Product2.ExtID__c => 'LC_TEST_1',
                Product2.Sub_Category__c => Product2Helper.SUBCATEGORY_RINGCENTRAL,
                Product2.IsActive => true
            })
            .create()
            .getRecord();

        PricebookEntry pbe = (PricebookEntry) new SObjectBuilder(PricebookEntry.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                PricebookEntry.Product2Id => prod.Id,
                PricebookEntry.UnitPrice => 0,
                PricebookEntry.IsActive => true,
                PricebookEntry.UseStandardPrice => false,
                PricebookEntry.CurrencyIsoCode => 'USD'
            })
            .create()
            .getRecord();

        Entitlement__c ent = (Entitlement__c) new SObjectBuilder(Entitlement__c.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Entitlement__c.Account__c => acc.Id,
                Entitlement__c.Quote__c => qt.Id,
                Entitlement__c.Product__c => prod.Id,
                Entitlement__c.Quantity__c => 1,
                Entitlement__c.Price__c => 50,
                Entitlement__c.ChargeTerm__c => Product2Helper.CHARGE_TERM_MONTHLY,
                Entitlement__c.Discount__c => 10,
                Entitlement__c.Discount_Type__c => QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY,
                Entitlement__c.PackageCatalogId__c => '7',
                Entitlement__c.PackageVersion__c => '1',
                Entitlement__c.Active__c => true
            })
            .create()
            .getRecord();

        Test.startTest();

        QuoteLineItem qli = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                QuoteLineItem.Product2Id => prod.Id,
                QuoteLineItem.QuoteId => qt.Id,
                QuoteLineItem.PricebookEntryId => pbe.Id,
                QuoteLineItem.Entitlement__c => ent.Id,
                QuoteLineItem.Quantity => 1,
                QuoteLineItem.NewQuantity__c => 1,
                QuoteLineItem.Zero_Quantity__c => false,
                QuoteLineItem.UnitPrice => 50,
                QuoteLineItem.Discount_number__c => 1,
                QuoteLineItem.Discount_type__c => QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY,
                QuoteLineItem.Package_Info_QLI__c =>
                        '{"id":"7","version":"1","duration":"Monthly","categoryCode":"SP","lboxes":[{"elementID":"1","min":1,"max":15}], "categoryPath":"HD"}',
                QuoteLineItem.PackageInfo__c =>
                        '{"id":"7","version":"1","duration":"Monthly","categoryCode":"SP","lboxes":[{"elementID":"1","min":1,"max":15}], "categoryPath":"HD"}',
                QuoteLineItem.PackageCatalogId__c => '7',
                QuoteLineItem.PackageVersion__c => '1'
            })
            .create()
            .getRecord();

        Quote[] quotes = new QuoteSelector()
            .selectQuoteForSignUp(qt.Id)
            .executeQuery();

        Area_Code_Line_Item__c result;

        Test.stopTest();

        result = AreaCodeHelper.preCreateAreaCode(qli, quotes[0]);

        System.assertEquals(
            qt.AreaCode__c,
            result.Area_Code__c,
            'Area_Code__c on result Area Code Line Item populated incorrectly'
        );
        System.assertEquals(
            qli.Id,
            result.Quote_Line_Item__c,
            'Quote_Line_Item__c on result Area Code Line Item populated incorrectly'
        );
        System.assertEquals(
            1,
            result.Quantity__c,
            'Quantity__c on result Area Code Line Item populated incorrectly'
        );
    }

    @isTest
    private static void testPreCreateAreaCodeFax() {
        new SObjectBuilder(RingCentralVariousSettings__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                RingCentralVariousSettings__c.CC_FSC_Approvers_Queues__c => 'TestQueue'
            })
            .create()
            .getRecord();
        List<Category_Codes__c> categoryCodes = new List<Category_Codes__c>();

        Map<String, String> m = new Map<String, String>{
            'FAX_AREA_CODES' => 'MLFN,MTFN',
            'LOCAL_AREA_CODES' => 'ALN,HDRF,HDR,HD,MLN,SP,EP',
            'MAIN_AREA_CODES' => 'ALN,HDRF,HDR,HD,MLN,SP,EP,ATN,MTN',
            'TOLL_FREE_AREA_CODES' => 'ATN,MTN,MTFN,MLFN',
            'AREA_CODES_AVAILABLE' => 'HDRF,HDR,HD,MLN,MTN,MLFN,MTFN,ALN,ATN,SP,EP',
            'REQUIRED_AREA_CODES' => 'ALN,ATN,HDRF,HD'
        };
        for (String codeName : m.KeySet()) {
            categoryCodes.add(
                new Category_Codes__c(
                    Name = codeName,
                    Codes__c = m.get(codeName)
                )
            );
        }
        insert categoryCodes;

        Area_Codes__c ac1 = (Area_Codes__c) new SObjectBuilder(Area_Codes__c.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Area_Codes__c.Name => 'Test Area Code 1',
                Area_Codes__c.State__c => 'NY',
                Area_Codes__c.Country__c => 'United States',
                Area_Codes__c.Type__c => TYPE_TOLL_FREE
            })
            .create()
            .getRecord();

        Account acc = (Account) new SObjectBuilder(Account.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Name => 'Test acc',
                Account.Payment_Method__c => 'Invoice',
                Account.Tax_Exempt__c => false,
                Account.SignupType__c => 'Free',
                Account.Monthly_Credit_Limit__c => 0,
                Account.Sign_up_Purchase_Limit__c => 0,
                Account.Payment_Terms__c => '12',
                Account.Invoice_Terms__c => '12',
                Account.PID__c => 'test_p_id',
                Account.Timezone__c => TEST_TIME_ZONE_NAME,
                Account.BillingCity => 'TestCity',
                Account.BillingStreet => 'TestStreet',
                Account.BillingState => 'NY',
                Account.BillingPostalCode => '123890',
                Account.BillingCountry => 'US'
            })
            .create()
            .getRecord();

        Contact contact = (Contact) new SObjectBuilder(Contact.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Contact.AccountId => acc.Id,
                Contact.LastName => 'John',
                Contact.FirstName => 'Good',
                Contact.Email => 'jg@rc.test'
            })
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SOBjectBuilder(Opportunity.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.AccountId => acc.Id,
                Opportunity.BMID__c => 'test_bm_id',
                Opportunity.OID__c => 'test_o_id',
                Opportunity.Partner_ID__c => 'test_partner_id',
                Opportunity.Enable_Cost_Center_Management__c => false
            })
            .create()
            .getRecord();

        Quote qt = (Quote) new SOBjectBuilder(Quote.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Quote.Pricebook2Id => Test.getStandardPricebookId(),
                Quote.Name => 'Test quote',
                Quote.OpportunityId => opp.Id,
                Quote.CurrencyIsoCode => 'USD',
                Quote.Approved_Status__c => 'Approved',
                Quote.Status => 'Draft',
                Quote.isPrimary__c => true,
                Quote.Initial_Term_months__c => '12',
                Quote.Package_Info__c => NGBSTestDataGenerator.generateQuotePackageInfo(),
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.QuoteType__c => 'Quote',
                Quote.AreaCode__c => ac1.Id,
                Quote.FaxAreaCode__c => ac1.Id,
                Quote.Payment_Plan__c => 'Monthly'
            })
            .create()
            .getRecord();

        Product2 prod = (Product2) new SObjectBuilder(Product2.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Product2.Name => 'Test product',
                Product2.ExtID__c => 'LC_TEST_1',
                Product2.Sub_Category__c => Product2Helper.SUBCATEGORY_RINGCENTRAL,
                Product2.IsActive => true
            })
            .create()
            .getRecord();

        PricebookEntry pbe = (PricebookEntry) new SObjectBuilder(PricebookEntry.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                PricebookEntry.Product2Id => prod.Id,
                PricebookEntry.UnitPrice => 0,
                PricebookEntry.IsActive => true,
                PricebookEntry.UseStandardPrice => false,
                PricebookEntry.CurrencyIsoCode => 'USD'
            })
            .create()
            .getRecord();

        Entitlement__c ent = (Entitlement__c) new SObjectBuilder(Entitlement__c.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Entitlement__c.Account__c => acc.Id,
                Entitlement__c.Quote__c => qt.Id,
                Entitlement__c.Product__c => prod.Id,
                Entitlement__c.Quantity__c => 1,
                Entitlement__c.Price__c => 50,
                Entitlement__c.ChargeTerm__c => Product2Helper.CHARGE_TERM_MONTHLY,
                Entitlement__c.Discount__c => 10,
                Entitlement__c.Discount_Type__c => QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY,
                Entitlement__c.PackageCatalogId__c => '7',
                Entitlement__c.PackageVersion__c => '1',
                Entitlement__c.Active__c => true
            })
            .create()
            .getRecord();

        Test.startTest();

        QuoteLineItem qli = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                QuoteLineItem.Product2Id => prod.Id,
                QuoteLineItem.QuoteId => qt.Id,
                QuoteLineItem.PricebookEntryId => pbe.Id,
                QuoteLineItem.Entitlement__c => ent.Id,
                QuoteLineItem.Quantity => 1,
                QuoteLineItem.NewQuantity__c => 1,
                QuoteLineItem.Zero_Quantity__c => false,
                QuoteLineItem.UnitPrice => 50,
                QuoteLineItem.Discount_number__c => 1,
                QuoteLineItem.Discount_type__c => QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY,
                QuoteLineItem.PackageInfo__c =>
                        '{"id":"7","version":"1","duration":"Monthly","categoryCode":"MLFN","lboxes":[{"elementID":"1","min":1,"max":15}], "categoryPath":"HD"}',
                QuoteLineItem.PackageCatalogId__c => '7',
                QuoteLineItem.PackageVersion__c => '1'
            })
            .create()
            .getRecord();

        Quote[] quotes = new QuoteSelector()
            .selectQuoteForSignUp(qt.Id)
            .executeQuery();

        Area_Code_Line_Item__c result;

		Test.stopTest();

        result = AreaCodeHelper.preCreateAreaCode(qli, quotes[0]);

        System.assertEquals(
            qt.AreaCode__c,
            result.Area_Code__c,
            'Area_Code__c on result Area Code Line Item populated incorrectly'
        );
        System.assertEquals(
            qli.Id,
            result.Quote_Line_Item__c,
            'Quote_Line_Item__c on result Area Code Line Item populated incorrectly'
        );
        System.assertEquals(
            1,
            result.Quantity__c,
            'Quantity__c on result Area Code Line Item populated incorrectly'
        );
    }

    @isTest static void testNoCodesInserted() {

        Product2 testProduct = (Product2) new SObjectBuilder(Product2.SObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    Product2.Name => 'Test Product',
                    Product2.IsActive => true
                }
            )
        .create()
        .getRecord();

        PriceBookEntry testPrice = (PriceBookEntry) new SObjectBuilder(PriceBookEntry.SObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    PriceBookEntry.Pricebook2Id => Test.getStandardPriceBookId(),
                    PriceBookEntry.Product2Id => testProduct.Id,
                    PriceBookEntry.UnitPrice => 10000,
                    PriceBookEntry.IsActive => true,
                    PriceBookEntry.UseStandardPrice => false
                }
            )
            .create()
            .getRecord();

        Opportunity testOpportunity = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    Opportunity.Name => 'Test Opportunity',
                    Opportunity.StageName => '1. Qualify'
                }
            )
            .create()
            .getRecord();

        Quote testQuote = (Quote) new SObjectBuilder(Quote..SObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    Quote.Name => 'Quote Test',
                    Quote.OpportunityId => testOpportunity.Id,
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
                    QuoteLineItem.Quantity => 5,
                    QuoteLineItem.Package_Info_QLI__c =>
                            '{"id":"7","version":"1","duration":"Monthly","categoryCode":"MLFN","lboxes":[{"elementID":"1","min":1,"max":15}], "categoryPath":"HD"}',
                    QuoteLineItem.PackageInfo__c =>
                            '{"id":"7","version":"1","duration":"Monthly","categoryCode":"MLFN","lboxes":[{"elementID":"1","min":1,"max":15}], "categoryPath":"HD"}'
                }
            )
            .create()
            .getRecord();

        Test.startTest();
        Area_Code_Line_Item__c result = AreaCodeHelper.preCreateAreaCode(testQli, testQuote);
        Test.stopTest();

        System.assertEquals(
            null,
            result,
            'Area_Code__c on result Area Code Line Item populated incorrectly'
        );
    }
}