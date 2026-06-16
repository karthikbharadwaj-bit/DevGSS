@isTest
private with sharing class Test_PipelineInfoController {
    @testSetup
    static void setup() {
        Triggers.switchOff();
        Account testAccnt = (Account) new SObjectBuilder(Account.SObjectType)
            .setField(Account.Name, 'Test Account')
            .create()
            .getRecord();

        Product2 officeDLProduct = (Product2) new SObjectBuilder(Product2.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Product2.Name => 'DigitalLine',
                Product2.ExtID__c => Product2Helper.DL_UNL_ELEMENT_ID,
                Product2.IsActive => true
            })
            .create()
            .getRecord();

        Product2 goDLProduct = (Product2) new SObjectBuilder(Product2.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Product2.Name => 'GO DigitalLine',
                Product2.ExtID__c => Product2Helper.ELEMENT_ID_GLOBAL_OFFICE,
                Product2.IsActive => true
            })
            .create()
            .getRecord();

        Pricebook2 testPriceBook = (Pricebook2) new SObjectBuilder(Pricebook2.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Pricebook2.Name => 'Test Price Book',
                Pricebook2.CurrencyIsoCode => 'USD',
                Pricebook2.IsActive => true,
                Pricebook2.Line_Range_Min__c => 5,
                Pricebook2.Line_Range_Max__c => 10
            })
            .create()
            .getRecord();

        PricebookEntry officeDLProductStdPBE = (PricebookEntry) new SObjectBuilder(PricebookEntry.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                PricebookEntry.UnitPrice => 100,
                PricebookEntry.IsActive => true,
                PricebookEntry.UseStandardPrice => false,
                PricebookEntry.CurrencyIsoCode => 'USD',
                PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                PricebookEntry.Product2Id => officeDLProduct.Id
            })
            .create()
            .getRecord();

        PricebookEntry goDLProductStdPBE = (PricebookEntry) new SObjectBuilder(PricebookEntry.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                PricebookEntry.UnitPrice => 100,
                PricebookEntry.IsActive => true,
                PricebookEntry.UseStandardPrice => false,
                PricebookEntry.CurrencyIsoCode => 'USD',
                PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                PricebookEntry.Product2Id => goDLProduct.Id
            })
            .create()
            .getRecord();

        PricebookEntry officeDLProductPBE = (PricebookEntry) new SObjectBuilder(PricebookEntry.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                PricebookEntry.UnitPrice => 100,
                PricebookEntry.IsActive => true,
                PricebookEntry.UseStandardPrice => false,
                PricebookEntry.CurrencyIsoCode => 'USD',
                PricebookEntry.Pricebook2Id => testPriceBook.Id,
                PricebookEntry.Product2Id => officeDLProduct.Id
            })
            .create()
            .getRecord();

        PricebookEntry goDLProductPBE = (PricebookEntry) new SObjectBuilder(PricebookEntry.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                PricebookEntry.UnitPrice => 100,
                PricebookEntry.IsActive => true,
                PricebookEntry.UseStandardPrice => false,
                PricebookEntry.CurrencyIsoCode => 'USD',
                PricebookEntry.Pricebook2Id => testPriceBook.Id,
                PricebookEntry.Product2Id => goDLProduct.Id
            })
            .create()
            .getRecord();

        Opportunity testOpp = (Opportunity) new SObjectBuilder(Opportunity.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.AccountId => testAccnt.Id,
                Opportunity.Name => 'Test Opportunity',
                Opportunity.Type => OpportunityHelper.OPPORTUNITY_TYPE_EX_BUSINESS,
                Opportunity.Brand_Name__c => 'RingCentral',
                Opportunity.Tier_Name__c => 'Office',
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                Opportunity.CloseDate => System.today(),
                Opportunity.CurrencyIsoCode => 'USD'
            })
            .create()
            .getRecord();

        Quote testSalesQuote = (Quote) new SObjectBuilder(Quote.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Quote.Name => 'testSalesQuote',
                Quote.Auto_Renewal__c => true,
                Quote.isPrimary__c => true,
                Quote.OpportunityId => testOpp.Id,
                Quote.Pricebook2Id => testPriceBook.Id,
                Quote.RecordTypeId => QuoteHelper.RT_ID_SALES,
                Quote.CurrencyIsoCode => 'USD'
            })
            .create()
            .getRecord();

        QuoteLineItem officeQli = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                QuoteLineItem.QuoteId => testSalesQuote.Id,
                QuoteLineItem.Quantity => 12,
                QuoteLineItem.UnitPrice => officeDLProductPBE.UnitPrice,
                QuoteLineItem.PricebookEntryId => officeDLProductPBE.Id,
                QuoteLineItem.Product2Id => officeDLProduct.Id,
                QuoteLineItem.Delta_ARR__c => 10
            })
            .create()
            .getRecord();

        QuoteLineItem gOfficeQli = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                QuoteLineItem.QuoteId => testSalesQuote.Id,
                QuoteLineItem.Quantity => 4,
                QuoteLineItem.UnitPrice => goDLProductPBE.UnitPrice,
                QuoteLineItem.PricebookEntryId => goDLProductPBE.Id,
                QuoteLineItem.Product2Id => goDLProduct.Id,
                QuoteLineItem.Delta_ARR__c => 11
            })
            .create()
            .getRecord();
    }

    @isTest
    static void testPipelineInfoController() {
        Opportunity oppty = [SELECT Id, CurrencyIsoCode, StageName FROM Opportunity LIMIT 1];
        oppty.StageName = OpportunityHelper.STAGE_NAME_SOLUTION;
        Test.startTest();
        update oppty;
        Test.stopTest();
        PipelineInfoController.PipelineInfoWrapper wrapper = PipelineInfoController.getPipelineInfo(oppty.Id);

        System.assertEquals(oppty.StageName, wrapper.stageName, 'Oppty Stage shouldn\'t be changed after update');
        System.assertEquals(null, wrapper.quoteUsers.engageDigitalUsers, 'Method should return null when quote does not have this type of Users');
        System.assertEquals(12, (Integer)wrapper.recordFields.get('Forecasted_Users__c'), 'Forecasted users should be equal Users as on quote on Stage 3+');
        System.assertEquals(4, (Integer)wrapper.recordFields.get('Forecasted_Global_Office_Users__c'), 'Forecasted users should be equal Users as on quote on Stage 3+');
    }

    @isTest
    static void testPipelineQuoteAmounts(){
        Opportunity oppty = (Opportunity) new OpportunitySelector()
            .selectOpportunities()
            .selectFields(new List<String>{
                        'StageName'
                })
            .executeQuery()
            .get(0);

        oppty.StageName = OpportunityHelper.STAGE_NAME_SOLUTION;
        oppty.Forecast_Contact_Center_Users__c = 10;

        Test.startTest();
        update oppty;
        Test.stopTest();

        oppty = (Opportunity) new OpportunitySelector()
            .selectOpportunities()
            .selectFields(new List<String>{
                        'Source_For_Office_Pipeline__c', 'Estimated_12M_Contact_Center_Pipeline__c'
                })
            .executeQuery()
            .get(0);

        System.assertEquals(OpportunityPipelineHelper.SOURCE_QUOTE, oppty.Source_For_Office_Pipeline__c, 'Source should be in quote amounts when Stage 3+ and oppty contain quote with qlis');
        System.assertEquals(oppty.Estimated_12M_Contact_Center_Pipeline__c, 0, 'Estimated should be 0 when Stage 3+ and oppty contain quote without qlis');
    }
}