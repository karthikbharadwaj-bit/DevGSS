@isTest
public class TestApprovalVfTemplateController {
    public static final String CONTENT = 'Quote Status: {!Status}';
    public static final String TEMPLATE_RESULT = 'Quote Status: Draft';

    @isTest
    private static void testApprovalTemplateController() {
        ApprovalVfTemplateController.controllerQuote = (Quote) new QuoteSelector()
                                        .selectQuotes()
                                        .selectField('QLI_details__c')
                                        .executeQuery()
                                        .get(0);
        Test.startTest();
            String totalChanges = ApprovalVfTemplateController.totalChanges;
            String changedDetails = ApprovalVfTemplateController.changedDetails;
            String approvalUrl = ApprovalVfTemplateController.approvalUrl;
        Test.stopTest();

        System.assertEquals(TEMPLATE_RESULT, totalChanges, 'Total Changes generation failed');
        System.assertEquals(TEMPLATE_RESULT, changedDetails, 'Changed Details generation failed');
        System.assertEquals(TEMPLATE_RESULT, ApprovalVfTemplateController.controllerQuote.QLI_details__c, 'Quote Details generation failed');
        System.assertEquals('', approvalUrl, 'Should be empty cecause no ProcessInstanceWorkitem objects were created');
    }

    @testSetup
    private static void createTestData() {
        Opportunity testOpp = (Opportunity) new SobjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.AccountId => ValueProviderBuilder.provideGenericParent(Account.SObjectType),
                Opportunity.Name => 'TestOpportunity',
                Opportunity.Brand_Name__c => 'RingCentral',
                Opportunity.Tier_Name__c => 'Office',
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                Opportunity.CurrencyIsoCode => 'USD'
            })
            .create()
            .getRecord();
        Quote quote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setField(Quote.OpportunityId, testOpp.Id)
            .setField(Quote.Pricebook2Id, Test.getStandardPricebookId())
            .setField(Quote.RecordTypeId, QuoteHelper.RT_ID_BILLING)
            .setField(Quote.Status, 'Draft')
            .create()
            .getRecord();

        Product2 product = (Product2) new SObjectBuilder(Product2.SObjectType)
            .setField(Product2.Name, 'E911')
            .setField(Product2.ExtID__c, 'LC_E911_52')
            .setField(Product2.IsActive, false)
            .create()
            .getRecord();

        List<PricebookEntry> pbes = new SObjectBuilder(PricebookEntry.SObjectType)
            .quantity(4)
            .setField(PricebookEntry.Pricebook2Id, quote.Pricebook2Id)
            .setField(PricebookEntry.Product2Id, product.Id)
            .setField(PricebookEntry.IsActive, true)
            .setField(
                PricebookEntry.CurrencyIsoCode, ValueProviderBuilder.provideList(QuoteLineItemService.currencyList))
            .create()
            .getRecords();

        SObjectBuilder template = new SObjectBuilder(RC_Quote_Template__c.SObjectType)
            .quantity(3)
            .setFields(new Map<SObjectField, Object> {
                RC_Quote_Template__c.Name => ValueProviderBuilder.provideList(
                    new List<String>{
                        QuoteHelper.TOTAL_CHANGES_TEMPLATE,
                        QuoteHelper.CHANGED_DETAILS_TEMPLATE,
                        QuoteHelper.QUOTE_DETAILS_TEMPLATE
                    })
            })
            .create();

        SObjectBuilder section = new SObjectBuilder(TemplateSections__c.SObjectType)
            .quantity(3)
            .setFields(new Map<SObjectField, Object> {
                TemplateSections__c.Content_1__c => CONTENT,
                TemplateSections__c.Name => ValueProviderBuilder.provideList(
                    new List<String>{
                        QuoteHelper.TOTAL_CHANGES_TEMPLATE,
                        QuoteHelper.CHANGED_DETAILS_TEMPLATE,
                        QuoteHelper.QUOTE_DETAILS_TEMPLATE
                    })
            })
            .create();

        SObjectBuilder junction = new SObjectBuilder(TemplateSectionJunction__c.SObjectType)
            .quantity(3)
            .setFields(new Map<SObjectField, Object> {
                TemplateSectionJunction__c.Position__c => 1.00,
                TemplateSectionJunction__c.RC_Quote_Template__c => ValueProviderBuilder.provideList(
                    new List<String>{
                        template.getRecords().get(0).Id,
                        template.getRecords().get(1).Id,
                        template.getRecords().get(2).Id
                    }),
                TemplateSectionJunction__c.Template_Section__c => ValueProviderBuilder.provideList(
                    new List<String>{
                        section.getRecords().get(0).Id,
                        section.getRecords().get(1).Id,
                        section.getRecords().get(2).Id
                    })
            })
            .create();

        List<RC_Quote_Template__c> rcTemplates = new RCQuoteTemplateSelector().selectRCQuoteTemplates().executeQuery();

        SObjectBuilder customSetting = new SObjectBuilder(RC_Quote_Templates__c.SObjectType)
            .quantity(3)
            .setFields(new Map<SObjectField, Object> {
                RC_Quote_Templates__c.Name => ValueProviderBuilder.provideList(
                    new List<String>{
                        QuoteHelper.TOTAL_CHANGES_TEMPLATE,
                        QuoteHelper.CHANGED_DETAILS_TEMPLATE,
                        QuoteHelper.QUOTE_DETAILS_TEMPLATE
                    }),
                RC_Quote_Templates__c.TemplateId__c => ValueProviderBuilder.provideList(
                    new List<String>{
                        rcTemplates.get(0).Id,
                        rcTemplates.get(1).Id,
                        rcTemplates.get(2).Id
                    })
            })
            .create();

        update new Quote(
            Id = quote.Id,
            QLI_details__c = TemplateEngine.createDoc(
                quote.Id,
                QuoteHelper.getTemplate(QuoteHelper.QUOTE_DETAILS_TEMPLATE)
            )
        );
    }
}